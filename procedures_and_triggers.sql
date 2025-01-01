CREATE OR ALTER PROCEDURE sp_AuthenticateUser
    @Username NVARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        -- Truy xuất thông tin người dùng dựa trên Username
        SELECT 
            tk.MaTaiKhoan, -- ID của tài khoản
            tk.Username,   -- Tên đăng nhập
            tk.Password,   -- Mật khẩu (đã băm)
            tk.VaiTro,     -- Vai trò của người dùng
            nv.MaChiNhanh  -- Mã chi nhánh nếu tài khoản là Nhân viên
        FROM TAIKHOAN tk
        LEFT JOIN NHANVIEN nv ON tk.MaNhanVien = nv.MaNhanVien
        WHERE tk.Username = @Username;

        -- Nếu không tìm thấy tài khoản, thủ tục sẽ trả về tập kết quả rỗng
    END TRY
    BEGIN CATCH
        -- Bắt lỗi và ném lỗi ra ngoài
        THROW;
    END CATCH
END;
GO

--Tier Management
--This procedure adjusts membership levels (LoaiThe) based on annual spending. We can you server agent to make new job that automatically
--run the procedure to update membership tier every year from the date that membership was created
CREATE OR ALTER PROCEDURE sp_UpdateMembershipTiers
AS
BEGIN
    SET NOCOUNT ON;

    -- Step 1: Upgrade Membership to SILVER
    UPDATE TT
    SET LoaiThe = 'Silver', DiemTichLuy = 0 -- Reset points after upgrading
    FROM THETHANHVIEN TT
    WHERE TT.LoaiThe = 'Member'
      AND TT.DiemTichLuy >= 100; -- 100 points equivalent to 10M VND

    -- Step 2: Maintain or Downgrade SILVER
    UPDATE TT
    SET LoaiThe = CASE
        WHEN TT.DiemTichLuy >= 100 THEN 'Gold' -- Upgrade to Gold (100 points)
        WHEN TT.DiemTichLuy >= 50 THEN 'Silver' -- Maintain Silver (50 points)
        ELSE 'Member' -- Downgrade to Membership (< 50 points)
    END, DiemTichLuy = 0
    FROM THETHANHVIEN TT
    WHERE TT.LoaiThe = 'Silver';

    -- Step 3: Maintain or Downgrade GOLD
    UPDATE TT
    SET LoaiThe = CASE
        WHEN TT.DiemTichLuy >= 100 THEN 'Gold' -- Maintain Gold
        ELSE 'Silver' -- Downgrade to Silver (< 100 points)
    END, DiemTichLuy = 0
    FROM THETHANHVIEN TT
    WHERE TT.LoaiThe = 'Gold';

END;
GO

--Find food
CREATE OR ALTER PROCEDURE sp_FindFoodInformationFromRegionOrBranch
    @MaKhuVuc INT = NULL,       -- Region parameter
    @MaChiNhanh INT = NULL,     -- Branch parameter
    @MaMucThucDon INT = NULL    -- Menu parameter (added)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT m.MaMon, m.TenMon, m.GiaTien, cm.CoPhucVu, c.MaChiNhanh, c.TenChiNhanh, mt.TenMucThucDon
    FROM MONAN m
    INNER JOIN CHINHANH_MON cm ON m.MaMon = cm.MaMon
    INNER JOIN CHINHANH c ON cm.MaChiNhanh = c.MaChiNhanh
    LEFT JOIN MUCTHUCDON mt ON m.MaMucThucDon = mt.MaMucThucDon
    WHERE cm.CoPhucVu = 1
      AND (@MaChiNhanh IS NULL OR c.MaChiNhanh = @MaChiNhanh)
      AND (@MaKhuVuc IS NULL OR c.MaKhuVuc = @MaKhuVuc)
      AND (@MaMucThucDon IS NULL OR m.MaMucThucDon = @MaMucThucDon)
    ORDER BY m.TenMon, c.TenChiNhanh;
END;
GO

--Add new order
--This procedure creates a new order (THONGTINPHIEUDATMON) and adds an item to it (CHITIETPHIEUDATMON).
CREATE OR ALTER PROCEDURE sp_addOrder
    @NgayLap DATETIME,
    @MaChiNhanh INT,
    @STTBan INT,
    @MaNV INT,
    @MaKH INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @MaPhieu INT;

    BEGIN TRY
        -- Thêm thông tin phiếu đặt món và lấy MaPhieu vừa tạo
        INSERT INTO THONGTINPHIEUDATMON (NgayLap, MaChiNhanh, STTBan, MaNV, MaKH)
        OUTPUT Inserted.MaPhieu
        VALUES (@NgayLap, @MaChiNhanh, @STTBan, @MaNV, @MaKH);

        -- Trả về MaPhieu vừa tạo
        SELECT SCOPE_IDENTITY() AS MaPhieu;

    END TRY
    BEGIN CATCH
        -- Xử lý lỗi nếu có
        PRINT N'Lỗi: ' + ERROR_MESSAGE();
        THROW;
    END CATCH
END;
GO

CREATE OR ALTER PROCEDURE sp_addDishToOrder
    @MaPhieu INT,
    @MaMon INT,
    @SoLuong INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @LastSTT INT;

    BEGIN TRY
        -- Kiểm tra nếu phiếu đã được thanh toán
        IF EXISTS (SELECT 1 FROM HOADON WHERE MaPhieu = @MaPhieu)
        BEGIN
            RAISERROR('Phiếu này đã thanh toán, không thể thêm món mới.', 16, 1);
            RETURN;
        END

        -- Lấy STT lớn nhất hiện tại của phiếu
        SELECT @LastSTT = ISNULL(MAX(STT), 0)
        FROM CHITIETPHIEUDATMON
        WHERE MaPhieu = @MaPhieu;

        -- Tăng STT và thêm món mới
        INSERT INTO CHITIETPHIEUDATMON (MaPhieu, STT, MaMon, SoLuong)
        VALUES (@MaPhieu, @LastSTT + 1, @MaMon, @SoLuong);
    END TRY
    BEGIN CATCH
        PRINT N'Lỗi: ' + ERROR_MESSAGE();
        THROW;
    END CATCH
END;

GO

--Revenue Statistics for Branch
CREATE OR ALTER PROCEDURE sp_GetBranchRevenueStats
    @MaChiNhanh INT,         -- Branch ID
    @StartDate DATETIME,     -- Start date for the report
    @EndDate DATETIME,       -- End date for the report
    @GroupBy NVARCHAR(10)    -- Grouping level: 'DAY', 'MONTH', 'QUARTER', or 'YEAR'
AS
BEGIN
    SET NOCOUNT ON;

    -- Aggregate revenue based on the specified grouping level
    SELECT 
        CASE 
            WHEN @GroupBy = 'DAY' THEN CONVERT(VARCHAR(10), H.NgayLap, 120) -- yyyy-MM-dd
            WHEN @GroupBy = 'MONTH' THEN LEFT(CONVERT(VARCHAR(7), H.NgayLap, 120), 7) -- yyyy-MM
            WHEN @GroupBy = 'QUARTER' THEN CONCAT(YEAR(H.NgayLap), '-Q', DATEPART(QUARTER, H.NgayLap))
            WHEN @GroupBy = 'YEAR' THEN CAST(YEAR(H.NgayLap) AS NVARCHAR(4))
        END AS TimePeriod,
        SUM(H.TongTien - H.TienGiamGia) AS TotalRevenue,
        COUNT(H.MaHoaDon) AS TotalInvoices
    FROM HOADON H
    INNER JOIN THONGTINPHIEUDATMON T ON H.MaPhieu = T.MaPhieu
    WHERE T.MaChiNhanh = @MaChiNhanh
      AND H.NgayLap BETWEEN @StartDate AND @EndDate
    GROUP BY 
        CASE 
            WHEN @GroupBy = 'DAY' THEN CONVERT(VARCHAR(10), H.NgayLap, 120)
            WHEN @GroupBy = 'MONTH' THEN LEFT(CONVERT(VARCHAR(7), H.NgayLap, 120), 7)
            WHEN @GroupBy = 'QUARTER' THEN CONCAT(YEAR(H.NgayLap), '-Q', DATEPART(QUARTER, H.NgayLap))
            WHEN @GroupBy = 'YEAR' THEN CAST(YEAR(H.NgayLap) AS NVARCHAR(4))
        END
    ORDER BY TimePeriod;
END;


GO

--System-Wide Revenue Statistics
CREATE OR ALTER PROCEDURE sp_GetSystemRevenueStats
    @StartDate DATETIME,     
    @EndDate DATETIME,       
    @GroupBy NVARCHAR(10)    
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        CASE 
            WHEN @GroupBy = 'DAY' THEN CONVERT(VARCHAR(10), H.NgayLap, 120) -- yyyy-MM-dd
            WHEN @GroupBy = 'MONTH' THEN LEFT(CONVERT(VARCHAR(7), H.NgayLap, 120), 7) -- yyyy-MM
            WHEN @GroupBy = 'QUARTER' THEN CONCAT(YEAR(H.NgayLap), '-Q', DATEPART(QUARTER, H.NgayLap))
            WHEN @GroupBy = 'YEAR' THEN CAST(YEAR(H.NgayLap) AS NVARCHAR(4))
        END AS TimePeriod,
        SUM(H.TongTien - H.TienGiamGia) AS TotalRevenue,
        COUNT(H.MaHoaDon) AS TotalInvoices
    FROM HOADON H
    INNER JOIN THONGTINPHIEUDATMON T ON H.MaPhieu = T.MaPhieu
    WHERE H.NgayLap BETWEEN @StartDate AND @EndDate
    GROUP BY 
        CASE 
            WHEN @GroupBy = 'DAY' THEN CONVERT(VARCHAR(10), H.NgayLap, 120)
            WHEN @GroupBy = 'MONTH' THEN LEFT(CONVERT(VARCHAR(7), H.NgayLap, 120), 7)
            WHEN @GroupBy = 'QUARTER' THEN CONCAT(YEAR(H.NgayLap), '-Q', DATEPART(QUARTER, H.NgayLap))
            WHEN @GroupBy = 'YEAR' THEN CAST(YEAR(H.NgayLap) AS NVARCHAR(4))
        END
    ORDER BY TimePeriod;
END;
GO



--Dish Revenue Statistics

CREATE OR ALTER PROCEDURE sp_GetDishRevenueStats
    @StartDate DATETIME, -- Start date for the analysis
    @EndDate DATETIME    -- End date for the analysis
AS
BEGIN
    SET NOCOUNT ON;

    -- Aggregate revenue for each dish
    SELECT 
        MA.MaMon AS DishID,
        MA.TenMon AS DishName,
        SUM(CT.SoLuong) AS TotalQuantitySold,               -- Total quantity of the dish sold
        SUM(CT.SoLuong * MA.GiaTien) AS TotalRevenue        -- Total revenue generated by the dish
    FROM CHITIETPHIEUDATMON CT
    INNER JOIN MONAN MA ON CT.MaMon = MA.MaMon
    INNER JOIN THONGTINPHIEUDATMON TP ON CT.MaPhieu = TP.MaPhieu
    WHERE TP.NgayLap BETWEEN @StartDate AND @EndDate       -- Filter by date range
    GROUP BY MA.MaMon, MA.TenMon
    ORDER BY TotalRevenue DESC;                            -- Sort by revenue in descending order
END;
GO



--Transferring an Employee Between Branches
--This procedure updates the branch (MaChiNhanh) and adds an entry to the LICHSULAMVIEC table to track employment history.

CREATE OR ALTER PROCEDURE sp_TransferEmployee
    @MaNhanVien INT,     -- Employee ID
    @NewBranchID INT,    -- New Branch ID
    @TransferDate DATE   -- Date of Transfer
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRANSACTION;

    -- Step 1: Add the current branch to employment history with an end date
    UPDATE LICHSULAMVIEC
    SET NgayKetThuc = @TransferDate
    WHERE MaNhanVien = @MaNhanVien AND NgayKetThuc IS NULL;

    -- Step 2: Update the employee's current branch
    UPDATE NHANVIEN
    SET MaChiNhanh = @NewBranchID
    WHERE MaNhanVien = @MaNhanVien;

    -- Step 3: Add a new entry to employment history for the new branch
    INSERT INTO LICHSULAMVIEC (MaNhanVien, MaChiNhanh, NgayBatDau)
    VALUES (@MaNhanVien, @NewBranchID, @TransferDate);

    COMMIT TRANSACTION;
END;
GO



--Adding a New Employee
--This procedure inserts a new record into the NHANVIEN table.
CREATE OR ALTER PROCEDURE sp_AddEmployee
    @HoTen NVARCHAR(100), 
    @NgaySinh DATE,
    @GioiTinh NVARCHAR(10),
    @MaBoPhan INT,
    @MaChiNhanh INT
AS
BEGIN
    SET NOCOUNT ON;

    -- Insert the new employee record
    INSERT INTO NHANVIEN (HoTen, NgaySinh, GioiTinh, MaBoPhan, MaChiNhanh)
    VALUES (@HoTen, @NgaySinh, @GioiTinh, @MaBoPhan, @MaChiNhanh);

    -- Add the new employee to the employment history
    INSERT INTO LICHSULAMVIEC (MaNhanVien, MaChiNhanh, NgayBatDau)
    VALUES (SCOPE_IDENTITY(), @MaChiNhanh, GETDATE());
END;
GO


--Updating Employee Details
--This procedure updates an employee’s personal details such as name, gender, or department.
CREATE OR ALTER PROCEDURE sp_UpdateEmployee
    @MaNhanVien INT,
    @HoTen NVARCHAR(100),
    @NgaySinh DATE,
    @GioiTinh NVARCHAR(10),
    @MaBoPhan INT
AS
BEGIN
    SET NOCOUNT ON;

    -- Update employee details
    UPDATE NHANVIEN
    SET HoTen = @HoTen,
        NgaySinh = @NgaySinh,
        GioiTinh = @GioiTinh,
        MaBoPhan = @MaBoPhan
    WHERE MaNhanVien = @MaNhanVien;
END;
GO


--Deleting an Employee
CREATE OR ALTER PROCEDURE sp_DeleteEmployee
    @MaNhanVien INT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRANSACTION;

    BEGIN TRY
        -- Cập nhật ngày kết thúc trong lịch sử làm việc
        DELETE FROM LICHSULAMVIEC WHERE MaNhanVien = @MaNhanVien;

        -- Xóa tài khoản liên kết với nhân viên (nếu có)
        DELETE FROM TAIKHOAN
        WHERE MaNhanVien = @MaNhanVien;

        -- Xóa nhân viên
        DELETE FROM NHANVIEN
        WHERE MaNhanVien = @MaNhanVien;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;

        -- Hiển thị lỗi
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR (@ErrorMessage, 16, 1);
    END CATCH
END;
GO

--Add Online Reservation
CREATE OR ALTER PROCEDURE sp_AddReservation
    @MaKhachHang INT,        -- Customer ID
    @MaChiNhanh INT,         -- Branch ID
    @STTBan INT,             -- Table Number
    @NgayDat DATE,           -- Reservation Date
    @GioDen DATETIME,        -- Reservation Time
    @SoLuongKhach INT,       -- Number of Guests
    @GhiChu NVARCHAR(255) = NULL -- Notes (optional)
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        -- Step 1: Validate that the branch exists
        IF NOT EXISTS (SELECT 1 FROM CHINHANH WHERE MaChiNhanh = @MaChiNhanh)
        BEGIN
            RAISERROR ('Branch does not exist.', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END

        -- Step 2: Validate that the table belongs to the branch
        IF NOT EXISTS (SELECT 1 FROM BAN WHERE MaChiNhanh = @MaChiNhanh AND STTBan = @STTBan)
        BEGIN
            RAISERROR ('Table does not exist at the specified branch.', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END

        -- Step 3: Check table status in BAN
        DECLARE @TrangThaiBan NVARCHAR(50);
        SELECT @TrangThaiBan = TrangThai FROM BAN WHERE MaChiNhanh = @MaChiNhanh AND STTBan = @STTBan;

        IF @TrangThaiBan = N'đang phục vụ'
        BEGIN
            -- Validate if the requested reservation time is more than 2 hours from now
            IF @GioDen <= DATEADD(HOUR, 2, GETDATE())
            BEGIN
                RAISERROR ('Cannot reserve a table currently in use within the next 2 hours.', 16, 1);
                ROLLBACK TRANSACTION;
                RETURN;
            END 
        END 

        -- Step 4: Validate overlapping reservations in DATBAN (unchanged)
        IF EXISTS (
            SELECT 1 
            FROM DATBAN 
            WHERE MaChiNhanh = @MaChiNhanh 
              AND STTBan = @STTBan 
              AND NgayDat = @NgayDat
              AND (
                    (@GioDen >= GioDen AND @GioDen < DATEADD(HOUR, 2, GioDen)) OR -- Overlaps with an existing reservation
                    (GioDen >= @GioDen AND GioDen < DATEADD(HOUR, 2, @GioDen))
              )
        )
        BEGIN
            RAISERROR ('The table is already reserved for the specified time.', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END

        -- Step 5: Insert the reservation into the DATBAN table (unchanged)
        INSERT INTO DATBAN (MaKhachHang, MaChiNhanh, STTBan, NgayDat, GioDen, SoLuongKhach, GhiChu)
        VALUES (@MaKhachHang, @MaChiNhanh, @STTBan, @NgayDat, @GioDen, @SoLuongKhach, @GhiChu);

        -- Update table status to 'đã đặt' (unchanged)
        UPDATE BAN
        SET TrangThai = N'đã đặt'
        WHERE MaChiNhanh = @MaChiNhanh AND STTBan = @STTBan;

        -- Commit the transaction (unchanged)
        COMMIT TRANSACTION;

        PRINT 'Reservation added successfully.';
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;

        -- Handle errors (unchanged)
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR (@ErrorMessage, 16, 1);
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE sp_CreateInvoice
    @MaChiNhanh INT,
    @STTBan INT,
    @TienGiamGia DECIMAL(15,2) = 0,
    @MaHoaDon INT OUTPUT -- OUTPUT parameter để trả về MaHoaDon
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @MaPhieu INT, @TongTien DECIMAL(15,2);

    BEGIN TRY
        -- 1. Lấy MaPhieu từ THONGTINPHIEUDATMON
        SELECT TOP 1 @MaPhieu = MaPhieu
        FROM THONGTINPHIEUDATMON
        WHERE MaChiNhanh = @MaChiNhanh AND STTBan = @STTBan
        ORDER BY NgayLap DESC;

        IF @MaPhieu IS NULL
        BEGIN
            RAISERROR('Không tìm thấy phiếu đặt món cho bàn này.', 16, 1);
            RETURN;
        END

        -- 2. Tính tổng tiền từ CHITIETPHIEUDATMON và MONAN
        SELECT @TongTien = SUM(ctpm.SoLuong * m.GiaTien)
        FROM CHITIETPHIEUDATMON ctpm
        JOIN MONAN m ON ctpm.MaMon = m.MaMon
        WHERE ctpm.MaPhieu = @MaPhieu;

        IF @TongTien IS NULL
            SET @TongTien = 0;

        -- 3. Trừ tiền giảm giá và tính tiền cuối cùng
        DECLARE @ThanhTien DECIMAL(15,2);
        SET @ThanhTien = @TongTien - @TienGiamGia;

        -- 4. Tạo hóa đơn
        INSERT INTO HOADON (NgayLap, TongTien, TienGiamGia, MaPhieu)
        VALUES (GETDATE(), @ThanhTien, @TienGiamGia, @MaPhieu);

        -- Lấy MaHoaDon của hóa đơn vừa tạo
        SET @MaHoaDon = SCOPE_IDENTITY();

        -- 5. Cập nhật trạng thái bàn thành 'Trống'
        UPDATE BAN
        SET TrangThai = N'Trống'
        WHERE MaChiNhanh = @MaChiNhanh AND STTBan = @STTBan;

    END TRY
    BEGIN CATCH
        PRINT N'Lỗi: ' + ERROR_MESSAGE();
        THROW;
    END CATCH
END;
GO

--To calculate the number of arrivals
CREATE OR ALTER PROCEDURE sp_GetCustomerStatsFromInvoice
    @StartDate DATETIME,         -- Start date for the report
    @EndDate DATETIME,           -- End date for the report
    @GroupBy NVARCHAR(10)        -- Grouping level: 'DAY', 'MONTH', or 'YEAR'
AS
BEGIN
    SET NOCOUNT ON;

    -- Calculate the number of customers served
    SELECT 
        CASE 
            WHEN @GroupBy = 'DAY' THEN CONVERT(VARCHAR(10), H.NgayLap, 120) -- yyyy-MM-dd
            WHEN @GroupBy = 'MONTH' THEN LEFT(CONVERT(VARCHAR(7), H.NgayLap, 120), 7) -- yyyy-MM
            WHEN @GroupBy = 'YEAR' THEN CAST(YEAR(H.NgayLap) AS NVARCHAR(4)) -- yyyy
        END AS TimePeriod,
        COUNT(DISTINCT H.MaHoaDon) AS TotalInvoices,  -- Total invoices
        COUNT(DISTINCT TP.MaKH) AS TotalUniqueCustomers, -- Unique customers who placed orders
        COUNT(H.MaHoaDon) AS TotalCustomerVisits -- Total visits (each invoice is counted as a visit)
    FROM HOADON H
    LEFT JOIN THONGTINPHIEUDATMON TP ON H.MaPhieu = TP.MaPhieu
    WHERE H.NgayLap BETWEEN @StartDate AND @EndDate
    GROUP BY 
        CASE 
            WHEN @GroupBy = 'DAY' THEN CONVERT(VARCHAR(10), H.NgayLap, 120)
            WHEN @GroupBy = 'MONTH' THEN LEFT(CONVERT(VARCHAR(7), H.NgayLap, 120), 7)
            WHEN @GroupBy = 'YEAR' THEN CAST(YEAR(H.NgayLap) AS NVARCHAR(4))
        END
    ORDER BY TimePeriod;
END;
GO

--procedure to retrieve the top 5 customers with the highest total invoice amounts per branch for a given month.
CREATE OR ALTER PROCEDURE sp_GetTop5CustomersByBranch
    @MaChiNhanh INT,       -- Branch ID
    @Year INT,             -- Year to filter
    @Month INT             -- Month to filter
AS
BEGIN
    SET NOCOUNT ON;

    -- Retrieve the top 5 customers with the highest total spending for the branch
    SELECT TOP 5
        KH.MaKhachHang,                             -- Customer ID
        KH.HoTen AS TenKhachHang,                   -- Customer Name
        SUM(H.TongTien - H.TienGiamGia) AS TotalSpending -- Total invoice amount after discount
    FROM HOADON H
    INNER JOIN THONGTINPHIEUDATMON TP ON H.MaPhieu = TP.MaPhieu
    INNER JOIN KHACHHANG KH ON TP.MaKH = KH.MaKhachHang
    WHERE TP.MaChiNhanh = @MaChiNhanh              -- Filter by branch
      AND YEAR(H.NgayLap) = @Year                  -- Filter by year
      AND MONTH(H.NgayLap) = @Month                -- Filter by month
    GROUP BY KH.MaKhachHang, KH.HoTen              -- Group by customer ID and name
    ORDER BY TotalSpending DESC;                   -- Sort by total spending in descending order
END;
GO

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
