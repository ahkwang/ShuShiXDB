--TRIGGER
-- Trigger for calculating the loyalty point
CREATE OR ALTER TRIGGER trg_UpdateLoyaltyPoints
ON HOADON
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    -- Update loyalty points for the customers based on the new or updated invoices
    UPDATE TT
    SET DiemTichLuy = DiemTichLuy + NewPoints.TotalPoints
    FROM THETHANHVIEN TT
    INNER JOIN (
        -- Calculate new points from inserted or updated invoices
        SELECT KH.MaKhachHang, 
               SUM(CAST((H.TongTien - H.TienGiamGia) / 100000 AS INT)) AS TotalPoints
        FROM INSERTED H
        INNER JOIN THONGTINPHIEUDATMON TP ON H.MaPhieu = TP.MaPhieu
        INNER JOIN KHACHHANG KH ON TP.MaKH = KH.MaKhachHang
        GROUP BY KH.MaKhachHang
    ) AS NewPoints ON TT.MaKhachHang = NewPoints.MaKhachHang;
END;
GO

-- Trigger dam bao moi khach hang khong co mot the thanh vien dang hoat dong
CREATE OR ALTER TRIGGER TRG_THETHANHVIEN_CHECK_ACTIVE
ON THETHANHVIEN
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    -- Kiem tra neu khach hang co hon 1 the thanh vien dang hoat dong
    IF EXISTS (
        SELECT MaKhachHang
        FROM THETHANHVIEN
        WHERE TinhTrangThe = N'Active'
        GROUP BY MaKhachHang
        HAVING COUNT(*) > 1
    )
    BEGIN
        RAISERROR ('Mot khach hang khong duoc co hon 1 the thanh vien dang hoat dong.', 16, 1);
        ROLLBACK TRANSACTION;
    END
END;
GO


-- Trigger dam bao nhan vien khong lam viec nhieu chi nhanh tai 1 thoi diem va tu dong cap nhat lich su lam viec neu co update (thay doi chi nhanh)
CREATE OR ALTER TRIGGER TRG_UPDATE_LICHSULAMVIEC
ON NHANVIEN
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (
        SELECT 1
        FROM inserted i
        JOIN deleted d ON i.MaNhanVien = d.MaNhanVien
        WHERE i.MaChiNhanh <> d.MaChiNhanh
    )
    BEGIN
        UPDATE LICHSULAMVIEC
        SET NgayKetThuc = GETDATE()
        FROM LICHSULAMVIEC l
        JOIN deleted d ON l.MaNhanVien = d.MaNhanVien AND l.MaChiNhanh = d.MaChiNhanh
        WHERE l.NgayKetThuc IS NULL;

        INSERT INTO LICHSULAMVIEC (MaNhanVien, MaChiNhanh, NgayBatDau, NgayKetThuc)
        SELECT i.MaNhanVien, i.MaChiNhanh, GETDATE(), NULL
        FROM inserted i
        JOIN deleted d ON i.MaNhanVien = d.MaNhanVien
        WHERE i.MaChiNhanh <> d.MaChiNhanh;
    END;
END;
GO

CREATE OR ALTER TRIGGER TRG_CHECK_TIME_OVERLAP
ON LICHSULAMVIEC
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (
        SELECT 1
        FROM inserted i
        JOIN LICHSULAMVIEC l
            ON i.MaNhanVien = l.MaNhanVien
            AND i.MaChiNhanh <> l.MaChiNhanh  
            AND (
                (i.NgayBatDau < ISNULL(l.NgayKetThuc, '9999-12-31') AND i.NgayKetThuc > l.NgayBatDau) OR 
                (i.NgayKetThuc IS NULL AND i.NgayBatDau < ISNULL(l.NgayKetThuc, '9999-12-31')) 
            )
    )
    BEGIN
        RAISERROR ('Moi nhan vien chi co the lam viec tai mot chi nhanh vao mot thoi diem.', 16, 1);
        ROLLBACK TRANSACTION;
    END
END;
GO

--Trigger dam bao dong bo thuc don giua cac chi nhanh cung khu vuc

CREATE OR ALTER TRIGGER TRG_SYNC_MENU_INSERT_UPDATE
ON CHINHANH_MON
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    -- Dong bo mon an trong cac chi nhanh cung khu vuc
    INSERT INTO CHINHANH_MON (MaChiNhanh, MaMon, CoPhucVu)
    SELECT CN2.MaChiNhanh, i.MaMon, 0 
    FROM inserted i
    JOIN CHINHANH CN1 ON i.MaChiNhanh = CN1.MaChiNhanh
    JOIN CHINHANH CN2 ON CN1.MaKhuVuc = CN2.MaKhuVuc
    WHERE CN1.MaChiNhanh <> CN2.MaChiNhanh
      AND NOT EXISTS (
          SELECT 1
          FROM CHINHANH_MON CM
          WHERE CM.MaChiNhanh = CN2.MaChiNhanh AND CM.MaMon = i.MaMon
      );
END;
GO

CREATE OR ALTER TRIGGER TRG_SYNC_MENU_DELETE
ON CHINHANH_MON
AFTER DELETE
AS
BEGIN
    SET NOCOUNT ON;

    DELETE CM
    FROM CHINHANH_MON CM
    JOIN deleted d ON CM.MaMon = d.MaMon
    JOIN CHINHANH CN1 ON d.MaChiNhanh = CN1.MaChiNhanh
    JOIN CHINHANH CN2 ON CM.MaChiNhanh = CN2.MaChiNhanh
    WHERE CN1.MaKhuVuc = CN2.MaKhuVuc 
      AND CN1.MaChiNhanh <> CN2.MaChiNhanh;
END;
GO
