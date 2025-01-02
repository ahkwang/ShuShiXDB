CREATE DATABASE sushiX;
GO
USE sushiX;
GO

CREATE TABLE TAIKHOAN (
    MaTaiKhoan INT IDENTITY (1, 1) PRIMARY KEY,
    Username NVARCHAR (50) NOT NULL UNIQUE,
    Password NVARCHAR (256) NOT NULL,
    VaiTro NVARCHAR (20) NOT NULL CHECK (
        VaiTro IN (
            N'KhachHang',
            N'NhanVien',
            N'QuanLy'
        )
    ),
    MaKhachHang INT NULL,
    MaNhanVien INT NULL
);
GO

CREATE TABLE KHUVUC (
    MaKhuVuc INT IDENTITY (1, 1),
    TenKhuVuc NVARCHAR (100) NOT NULL
);
GO

CREATE TABLE CHINHANH (
    MaChiNhanh INT IDENTITY (1, 1),
    MaKhuVuc INT NOT NULL,
    QuanLyChiNhanh INT NULL,
    TenChiNhanh NVARCHAR (100) NOT NULL,
    DiaChi NVARCHAR (255) NOT NULL,
    ThoiGianMoCua TIME NOT NULL,
    ThoiGianDongCua TIME NOT NULL,
    SoDienThoaiChiNhanh NVARCHAR (20) NOT NULL,
    CoBaiDoXeMay BIT NOT NULL,
    CoBaiDoOto BIT NOT NULL
);
GO

CREATE TABLE BOPHAN (
    MaBoPhan INT IDENTITY (1, 1),
    TenBoPhan NVARCHAR (100) NOT NULL,
    Luong DECIMAL(15, 2) NOT NULL
);
GO

CREATE TABLE NHANVIEN (
    MaNhanVien INT IDENTITY (1, 1),
    HoTen NVARCHAR (100) NOT NULL,
    NgaySinh DATE NOT NULL,
    GioiTinh NVARCHAR (10) NOT NULL,
    MaBoPhan INT NOT NULL,
    MaChiNhanh INT NOT NULL
);
GO

CREATE TABLE LICHSULAMVIEC (
    MaNhanVien INT NOT NULL,
    MaChiNhanh INT NOT NULL,
    NgayBatDau DATE NOT NULL,
    NgayKetThuc DATE NULL
);
GO

CREATE TABLE KHACHHANG (
    MaKhachHang INT IDENTITY (1, 1),
    HoTen NVARCHAR (100) NOT NULL,
    SoDienThoai NVARCHAR (20) NOT NULL,
    Email NVARCHAR (100) NULL,
    SoCCCD NVARCHAR (50) NOT NULL,
    GioiTinh NVARCHAR (10) NOT NULL,
    KhachOnline BIT NOT NULL
);
GO

CREATE TABLE THETHANHVIEN (
    MaSoThe INT IDENTITY (1, 1),
    MaKhachHang INT NOT NULL,
    NgayLap DATE NOT NULL,
    LoaiThe NVARCHAR (20) NOT NULL,
    TinhTrangThe NVARCHAR (20) NOT NULL,
    DiemTichLuy INT NOT NULL
);
GO

CREATE TABLE LICHSUTRUYCAP (
    MaKhachHang INT NOT NULL,
    ThoiDiemTruyCap DATETIME NOT NULL,
    ThoiGianTruyCap INT NULL
);
GO

CREATE TABLE MUCTHUCDON (
    MaMucThucDon INT IDENTITY (1, 1),
    TenMucThucDon NVARCHAR (100) NOT NULL
);
GO

CREATE TABLE MONAN (
    MaMon INT IDENTITY (1, 1),
    MaMucThucDon INT NOT NULL,
    TenMon NVARCHAR (100) NOT NULL,
    GiaTien DECIMAL(15, 2) NOT NULL
);
GO

CREATE TABLE CHINHANH_MON (
    MaChiNhanh INT NOT NULL,
    MaMon INT NOT NULL,
    CoPhucVu BIT NOT NULL
);
GO

CREATE TABLE BAN (
    MaChiNhanh INT NOT NULL,
    STTBan INT NOT NULL,
    TrangThai NVARCHAR (50) NOT NULL
);
GO

CREATE TABLE DATBAN (
    MaDatBan INT IDENTITY (1, 1),
    MaKhachHang INT NOT NULL,
    MaChiNhanh INT NOT NULL,
    STTBan INT NOT NULL,
    NgayDat DATE NOT NULL,
    GioDen DATETIME NOT NULL,
    SoLuongKhach INT NOT NULL,
    GhiChu NVARCHAR (255) NULL
);
GO

CREATE TABLE THONGTINPHIEUDATMON (
    MaPhieu INT IDENTITY (1, 1),
    NgayLap DATETIME NOT NULL,
    MaChiNhanh INT NOT NULL,
    STTBan INT NOT NULL,
    MaNV INT,
    MaKH INT NULL
);
GO

CREATE TABLE CHITIETPHIEUDATMON (
    MaPhieu INT NOT NULL,
    STT INT NOT NULL,
    MaMon INT NOT NULL,
    SoLuong INT NOT NULL
);
GO

CREATE TABLE HOADON (
    MaHoaDon INT IDENTITY (1, 1),
    NgayLap DATETIME NOT NULL,
    TongTien DECIMAL(15, 2) NOT NULL,
    TienGiamGia DECIMAL(15, 2) NOT NULL,
    MaPhieu INT
);
GO

CREATE TABLE DANHGIA (
    MaHoaDon INT NOT NULL,
    DiemPhucVu INT,
    DiemViTri INT,
    DiemChatLuongMonAn INT,
    DiemGiaCa INT,
    DiemKhongGian INT,
    BinhLuan NVARCHAR (MAX) NULL
);
GO

-- Giả sử đang ở trong cơ sở dữ liệu SushiXDB
-- 1. KHUVUC
BULK
INSERT
    KHUVUC
FROM 'D:\ShuShiXDB\data\KHUVUC.csv'
WITH (
        FIRSTROW = 2,
        FIELDTERMINATOR = ',',
        ROWTERMINATOR = '\n',
        CODEPAGE = '65001',
        FORMAT = 'CSV'
    );

-- 2. BOPHAN
BULK
INSERT
    BOPHAN
FROM 'D:\ShuShiXDB\data\BOPHAN.csv'
WITH (
        FIRSTROW = 2,
        FIELDTERMINATOR = ',',
        ROWTERMINATOR = '\n',
        CODEPAGE = '65001',
        FORMAT = 'CSV'
    );

-- 3. MUCTHUCDON
BULK
INSERT
    MUCTHUCDON
FROM 'D:\ShuShiXDB\data\MUCTHUCDON.csv'
WITH (
        FIRSTROW = 2,
        FIELDTERMINATOR = ',',
        ROWTERMINATOR = '\n',
        CODEPAGE = '65001',
        FORMAT = 'CSV'
    );

-- 4. CHINHANH
BULK
INSERT
    CHINHANH
FROM 'D:\ShuShiXDB\data\CHINHANH.csv'
WITH (
        FIRSTROW = 2,
        FIELDTERMINATOR = ',',
        ROWTERMINATOR = '\n',
        CODEPAGE = '65001',
        FORMAT = 'CSV'
    );

-- 5. NHANVIEN
BULK
INSERT
    NHANVIEN
FROM 'D:\ShuShiXDB\data\NHANVIEN.csv'
WITH (
        FIRSTROW = 2,
        FIELDTERMINATOR = ',',
        ROWTERMINATOR = '\n',
        CODEPAGE = '65001',
        FORMAT = 'CSV'
    );

-- 6. LICHSULAMVIEC
BULK
INSERT
    LICHSULAMVIEC
FROM 'D:\ShuShiXDB\data\LICHSULAMVIEC.csv'
WITH (
        FIRSTROW = 2,
        FIELDTERMINATOR = ',',
        ROWTERMINATOR = '\n',
        CODEPAGE = '65001',
        FORMAT = 'CSV'
    );

-- 7. KHACHHANG
BULK
INSERT
    KHACHHANG
FROM 'D:\ShuShiXDB\data\KHACHHANG.csv'
WITH (
        FIRSTROW = 2,
        FIELDTERMINATOR = ',',
        ROWTERMINATOR = '\n',
        CODEPAGE = '65001',
        FORMAT = 'CSV'
    );

-- 8. MONAN
BULK
INSERT
    MONAN
FROM 'D:\ShuShiXDB\data\MONAN.csv'
WITH (
        FIRSTROW = 2,
        FIELDTERMINATOR = ',',
        ROWTERMINATOR = '\n',
        CODEPAGE = '65001',
        FORMAT = 'CSV'
    );

-- 9. THETHANHVIEN
BULK
INSERT
    THETHANHVIEN
FROM 'D:\ShuShiXDB\data\THETHANHVIEN.csv'
WITH (
        FIRSTROW = 2,
        FIELDTERMINATOR = ',',
        ROWTERMINATOR = '\n',
        CODEPAGE = '65001',
        FORMAT = 'CSV'
    );

-- 10. LICHSUTRUYCAP
BULK
INSERT
    LICHSUTRUYCAP
FROM 'D:\ShuShiXDB\data\LICHSUTRUYCAP.csv'
WITH (
        FIRSTROW = 2,
        FIELDTERMINATOR = ',',
        ROWTERMINATOR = '\n',
        CODEPAGE = '65001',
        FORMAT = 'CSV'
    );

-- 11. BAN
BULK
INSERT
    BAN
FROM 'D:\ShuShiXDB\data\BAN.csv'
WITH (
        FIRSTROW = 2,
        FIELDTERMINATOR = ',',
        ROWTERMINATOR = '\n',
        CODEPAGE = '65001',
        FORMAT = 'CSV'
    );

-- 12. CHINHANH_MON
BULK
INSERT
    CHINHANH_MON
FROM 'D:\ShuShiXDB\data\CHINHANH_MON.csv'
WITH (
        FIRSTROW = 2,
        FIELDTERMINATOR = ',',
        ROWTERMINATOR = '\n',
        CODEPAGE = '65001',
        FORMAT = 'CSV'
    );

-- 13. DATBAN
BULK
INSERT
    DATBAN
FROM 'D:\ShuShiXDB\data\DATBAN.csv'
WITH (
        FIRSTROW = 2,
        FIELDTERMINATOR = ',',
        ROWTERMINATOR = '\n',
        CODEPAGE = '65001',
        FORMAT = 'CSV'
    );

-- 14. THONGTINPHIEUDATMON
BULK
INSERT
    THONGTINPHIEUDATMON
FROM 'D:\ShuShiXDB\data\THONGTINPHIEUDATMON.csv'
WITH (
        FIRSTROW = 2,
        FIELDTERMINATOR = ',',
        ROWTERMINATOR = '\n',
        CODEPAGE = '65001',
        FORMAT = 'CSV'
    );

-- 15. CHITIETPHIEUDATMON
BULK
INSERT
    CHITIETPHIEUDATMON
FROM 'D:\ShuShiXDB\data\CHITIETPHIEUDATMON.csv'
WITH (
        FIRSTROW = 2,
        FIELDTERMINATOR = ',',
        ROWTERMINATOR = '\n',
        CODEPAGE = '65001',
        FORMAT = 'CSV'
    );

-- 16. HOADON
BULK
INSERT
    HOADON
FROM 'D:\ShuShiXDB\data\HOADON.csv'
WITH (
        FIRSTROW = 2,
        FIELDTERMINATOR = ',',
        ROWTERMINATOR = '\n',
        CODEPAGE = '65001',
        FORMAT = 'CSV'
    );

-- 17. DANHGIA
BULK
INSERT
    DANHGIA
FROM 'D:\ShuShiXDB\data\DANHGIA.csv'
WITH (
        FIRSTROW = 2,
        FIELDTERMINATOR = ',',
        ROWTERMINATOR = '\n',
        CODEPAGE = '65001',
        FORMAT = 'CSV'
    );

-- 18. TAIKHOAN
BULK
INSERT
    TAIKHOAN
FROM 'D:\ShuShiXDB\data\TAIKHOAN.csv'
WITH (
        FIRSTROW = 2,
        FIELDTERMINATOR = ',',
        ROWTERMINATOR = '\n',
        CODEPAGE = '65001',
        FORMAT = 'CSV'
    );

UPDATE BAN 
SET TrangThai = N'Trống'
UPDATE LICHSULAMVIEC
SET
    MaChiNhanh = nv.MaChiNhanh
FROM
    LICHSULAMVIEC lslv
    INNER JOIN NHANVIEN nv ON lslv.MaNhanVien = nv.MaNhanVien
WHERE
    lslv.NgayKetThuc IS NULL;

WITH
    DuplicateRecords AS (
        SELECT *, ROW_NUMBER() OVER (
                PARTITION BY
                    MaKhachHang
                ORDER BY MaSoThe DESC
            ) as RowNum
        FROM THETHANHVIEN
    )
DELETE FROM DuplicateRecords
WHERE
    RowNum > 1;
WITH
    DuplicateRecords AS (
        SELECT *, ROW_NUMBER() OVER (
                PARTITION BY
                    MaNhanVien
                ORDER BY NgayBatDau DESC
            ) as RowNum
        FROM LICHSULAMVIEC
    )
DELETE FROM DuplicateRecords
WHERE
    RowNum > 1;

--ADD CONSTRAINTS
