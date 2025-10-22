
CREATE DATABASE QL_TuiXach;
GO

USE QL_TuiXach;
GO


-- 1. NguoiDung
CREATE TABLE NguoiDung (
    MaNguoiDung INT IDENTITY(1,1) PRIMARY KEY,
    HoTen NVARCHAR(100) NOT NULL,
    Email VARCHAR(100) NOT NULL UNIQUE,
    MatKhauHash NVARCHAR(255) NOT NULL,
    SoDienThoai VARCHAR(15) UNIQUE,
    VaiTro NVARCHAR(20) NOT NULL DEFAULT N'KhachHang' CHECK (VaiTro IN (N'KhachHang', N'QuanTriVien')),
    NgayTao DATETIME2 DEFAULT GETDATE()
);
GO

-- 2. ThuongHieu
CREATE TABLE ThuongHieu (
    MaThuongHieu INT IDENTITY(1,1) PRIMARY KEY,
    TenThuongHieu NVARCHAR(100) NOT NULL,
    Logo NVARCHAR(255),
    MoTa NVARCHAR(MAX)
);
GO

-- 3. DanhMuc
CREATE TABLE DanhMuc (
    MaDanhMuc INT IDENTITY(1,1) PRIMARY KEY,
    TenDanhMuc NVARCHAR(100) NOT NULL,
    MoTa NVARCHAR(MAX),
    MaDanhMucCha INT,
    AnhDaiDien NVARCHAR(255),
    FOREIGN KEY (MaDanhMucCha) REFERENCES DanhMuc(MaDanhMuc) ON DELETE NO ACTION ON UPDATE NO ACTION
);
GO

-- 4. SanPham
CREATE TABLE SanPham (
    MaSanPham INT IDENTITY(1,1) PRIMARY KEY,
    TenSanPham NVARCHAR(255) NOT NULL,
    MoTa NVARCHAR(MAX),
    MaDanhMuc INT,
    MaThuongHieu INT,
    ChatLieuChinh NVARCHAR(100) NULL,
    DipSuDung NVARCHAR(100) NULL,
    BoSuuTap NVARCHAR(100) NULL,
    NgayTao DATETIME2 DEFAULT GETDATE(),
    FOREIGN KEY (MaDanhMuc) REFERENCES DanhMuc(MaDanhMuc) ON DELETE NO ACTION ON UPDATE CASCADE,
    FOREIGN KEY (MaThuongHieu) REFERENCES ThuongHieu(MaThuongHieu) ON DELETE NO ACTION ON UPDATE CASCADE
);
GO

-- 5. BienTheSanPham
CREATE TABLE BienTheSanPham (
    MaBienThe INT IDENTITY(1,1) PRIMARY KEY,
    MaSanPham INT NOT NULL,
    SKU VARCHAR(100) NOT NULL UNIQUE,
    MauSac NVARCHAR(50),
    ChieuDaiCM DECIMAL(5, 1) NULL,
    ChieuRongCM DECIMAL(5, 1) NULL,
    ChieuCaoCM DECIMAL(5, 1) NULL,
    CanNangGram INT NULL,
    GiaBan DECIMAL(12, 2) NOT NULL,
    GiaGoc DECIMAL(12, 2),
    SoLuongTonKho INT NOT NULL DEFAULT 0,
    HinhAnh NVARCHAR(255),
    FOREIGN KEY (MaSanPham) REFERENCES SanPham(MaSanPham) ON DELETE CASCADE ON UPDATE CASCADE
);
GO

-- 6. DiaChi
CREATE TABLE DiaChi (
    MaDiaChi INT IDENTITY(1,1) PRIMARY KEY,
    MaNguoiDung INT NOT NULL,
    TenNguoiNhan NVARCHAR(100) NOT NULL,
    SoDienThoai VARCHAR(15) NOT NULL,
    SoNhaDuong NVARCHAR(255) NOT NULL,
    PhuongXa NVARCHAR(100) NOT NULL,
    QuanHuyen NVARCHAR(100) NOT NULL,
    TinhThanhPho NVARCHAR(100) NOT NULL,
    LaMacDinh BIT DEFAULT 0,
    FOREIGN KEY (MaNguoiDung) REFERENCES NguoiDung(MaNguoiDung) ON DELETE CASCADE ON UPDATE CASCADE
);
GO

-- 7. MaKhuyenMai
CREATE TABLE MaKhuyenMai (
    MaKMID INT IDENTITY(1,1) PRIMARY KEY,
    MaCode VARCHAR(50) NOT NULL UNIQUE,
    LoaiGiamGia NVARCHAR(10) NOT NULL CHECK (LoaiGiamGia IN (N'PhanTram', N'SoTien')),
    GiaTriGiam DECIMAL(10, 2) NOT NULL,
    DonToiThieu DECIMAL(10, 2) DEFAULT 0.00,
    NgayHetHan DATE NOT NULL,
    GioiHanSuDung INT DEFAULT 100,
    SoLanDaDung INT DEFAULT 0
);
GO

-- 8. DonHang
CREATE TABLE DonHang (
    MaDonHang INT IDENTITY(1,1) PRIMARY KEY,
    MaNguoiDung INT,
    NgayDat DATETIME2 DEFAULT GETDATE(),
    MaDiaChiGiao INT,
    TrangThai NVARCHAR(20) NOT NULL DEFAULT N'ChoXuLy' CHECK (TrangThai IN (N'ChoXuLy', N'DangXuLy', N'DangGiao', N'DaGiao', N'DaHuy')),
    PhuongThucThanhToan NVARCHAR(50) DEFAULT N'COD',
    TrangThaiThanhToan NVARCHAR(20) DEFAULT N'ChuaThanhToan' CHECK (TrangThaiThanhToan IN (N'ChuaThanhToan', N'DaThanhToan')), -- SỬA: Tăng độ dài lên 20
    TongTienHang DECIMAL(14, 2) NOT NULL,
    PhiVanChuyen DECIMAL(10, 2) DEFAULT 0.00,
    SoTienGiamGia DECIMAL(14, 2) DEFAULT 0.00,
    TongThanhToan DECIMAL(14, 2) NOT NULL,
    MaKMID INT,
    GhiChu NVARCHAR(MAX),
    FOREIGN KEY (MaNguoiDung) REFERENCES NguoiDung(MaNguoiDung) ON DELETE SET NULL ON UPDATE CASCADE,
    FOREIGN KEY (MaDiaChiGiao) REFERENCES DiaChi(MaDiaChi) ON DELETE NO ACTION ON UPDATE NO ACTION,
    FOREIGN KEY (MaKMID) REFERENCES MaKhuyenMai(MaKMID) ON DELETE SET NULL ON UPDATE CASCADE
);
GO

-- 9. ChiTietDonHang
CREATE TABLE ChiTietDonHang (
    MaChiTietDonHang INT IDENTITY(1,1) PRIMARY KEY,
    MaDonHang INT NOT NULL,
    MaBienThe INT NOT NULL,
    SoLuong INT NOT NULL,
    GiaLucMua DECIMAL(12, 2) NOT NULL,
    FOREIGN KEY (MaDonHang) REFERENCES DonHang(MaDonHang) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (MaBienThe) REFERENCES BienTheSanPham(MaBienThe) ON DELETE NO ACTION ON UPDATE NO ACTION
);
GO

-- 10. GioHang
CREATE TABLE GioHang (
    MaMucGioHang INT IDENTITY(1,1) PRIMARY KEY,
    MaNguoiDung INT NOT NULL,
    MaBienThe INT NOT NULL,
    SoLuong INT NOT NULL DEFAULT 1,
    NgayThem DATETIME2 DEFAULT GETDATE(),
    FOREIGN KEY (MaNguoiDung) REFERENCES NguoiDung(MaNguoiDung) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (MaBienThe) REFERENCES BienTheSanPham(MaBienThe) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT UQ_NguoiDung_BienThe_GioHang UNIQUE (MaNguoiDung, MaBienThe)
);
GO

-- 11. DanhGia
CREATE TABLE DanhGia (
    MaDanhGia INT IDENTITY(1,1) PRIMARY KEY,
    MaSanPham INT NOT NULL,
    MaNguoiDung INT NOT NULL,
    Diem TINYINT NOT NULL CHECK (Diem >= 1 AND Diem <= 5),
    BinhLuan NVARCHAR(MAX),
    NgayDanhGia DATETIME2 DEFAULT GETDATE(),
    FOREIGN KEY (MaSanPham) REFERENCES SanPham(MaSanPham) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (MaNguoiDung) REFERENCES NguoiDung(MaNguoiDung) ON DELETE CASCADE ON UPDATE CASCADE
);
GO

-- 12. PhieuDoiTra
CREATE TABLE PhieuDoiTra (
    MaPhieuDoiTra INT IDENTITY(1,1) PRIMARY KEY,
    MaChiTietDonHang INT NOT NULL,
    MaNguoiDung INT NOT NULL,
    LoaiYeuCau NVARCHAR(10) NOT NULL CHECK (LoaiYeuCau IN (N'Doi', N'Tra')),
    LyDo NVARCHAR(MAX) NOT NULL,
    TrangThai NVARCHAR(20) NOT NULL DEFAULT N'ChoXuLy' CHECK (TrangThai IN (N'ChoXuLy', N'DaDuyet', N'TuChoi', N'DaHoanThanh')),
    NgayYeuCau DATETIME2 DEFAULT GETDATE(),
    GhiChuAdmin NVARCHAR(MAX) NULL,
    FOREIGN KEY (MaChiTietDonHang) REFERENCES ChiTietDonHang(MaChiTietDonHang) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (MaNguoiDung) REFERENCES NguoiDung(MaNguoiDung) ON DELETE NO ACTION ON UPDATE NO ACTION
);
GO



-- 1. Thêm NguoiDung
-- SỬA: Thay thế mật khẩu '123' bằng một chuỗi hash giả lập để đảm bảo an toàn.
INSERT INTO NguoiDung (HoTen, Email, MatKhauHash, SoDienThoai, VaiTro) VALUES
(N'Nguyễn Văn A', 'nguyenvana@gmail.com', N'$2a$10$abcdefghijklmnopqrstuv', '0901234567', N'KhachHang'),
(N'Trần Thị B', 'tranthib@gmail.com', N'$2a$10$bcdefghijklmnopqrstuvw', '0907654321', N'KhachHang'),
(N'Admin Quản Trị', 'admin@shop.com', N'$2a$10$cdefghijklmnopqrstuvwx', '0808080808', N'QuanTriVien'),
(N'Lê Minh Cường', 'leminhcuong@gmail.com', N'$2a$10$defghijklmnopqrstuvwxy', '0912345678', N'KhachHang'),
(N'Phạm Hồng Duyên', 'phamhongduyen@gmail.com', N'$2a$10$efghijklmnopqrstuvwxyz', '0987654321', N'KhachHang');
GO

-- 2. Thêm ThuongHieu
INSERT INTO ThuongHieu (TenThuongHieu, MoTa) VALUES
(N'Gucci', N'Thương hiệu thời trang cao cấp của Ý'),
(N'Chanel', N'Thương hiệu thời trang cao cấp của Pháp'),
(N'Juno', N'Thương hiệu túi xách tầm trung Việt Nam'),
(N'Vascara', N'Thương hiệu giày và túi xách Việt Nam'),
(N'Charles & Keith', N'Thương hiệu thời trang Singapore'),
(N'Coach', N'Thương hiệu thời trang cao cấp của Mỹ');
GO

-- 3. Thêm DanhMuc
INSERT INTO DanhMuc (TenDanhMuc, MoTa, MaDanhMucCha) VALUES
(N'Túi Đeo Chéo', N'Túi đeo chéo thời trang', NULL),
(N'Túi Tote', N'Túi xách bản lớn, phù hợp đi làm, dạo phố', NULL),
(N'Túi Cầm Tay (Clutch)', N'Túi nhỏ cầm tay, chuyên dự tiệc', NULL),
(N'Túi Đeo Vai', N'Túi đeo vai (Shoulder bag)', NULL),
(N'Túi Đeo Bụng', N'Túi đeo hông, đeo bụng (Belt bag)', NULL);
GO

-- 4. Thêm SanPham
INSERT INTO SanPham (TenSanPham, MoTa, MaDanhMuc, MaThuongHieu, ChatLieuChinh, DipSuDung, BoSuuTap) VALUES
(N'Túi Đeo Chéo Vascara Basic Khóa Tròn', N'Thiết kế basic, điểm nhấn khóa kim loại tròn.', 1, 4, N'Da tổng hợp (PU)', N'Dạo phố', N'Basic Collection'),
(N'Túi Đeo Chéo Juno Phối Nắp Gập', N'Thiết kế nắp gập thanh lịch, phối màu tương phản.', 1, 3, N'Da tổng hợp (PU)', N'Đi làm, Dạo phố', N'Urban'),
(N'Túi Tote Da Thật Gucci Marmont', N'Dòng túi cao cấp Gucci Marmont, da thật 100%.', 2, 1, N'Da thật (Calfskin)', N'Dự tiệc, Đi làm', N'GG Marmont'),
(N'Túi Cầm Tay Charles & Keith Đính Đá', N'Clutch dự tiệc sang trọng, bề mặt đính đá lấp lánh.', 3, 5, N'Vải Satin & Đá', N'Dự tiệc', N'Evening'),
(N'Túi Đeo Vai Coach Dáng Bán Nguyệt', N'Kiểu dáng hobo bán nguyệt, da Pebble mềm.', 4, 6, N'Da thật (Pebble)', N'Đi làm, Dạo phố', N'Hobo'),
(N'Túi Đeo Bụng Coach Logo Signature', N'Túi đeo hông da thật, logo Coach dập nổi.', 5, 6, N'Da thật & Canvas', N'Du lịch, Dạo phố', N'Signature'),
(N'Túi Cầm Tay Chanel Classic', N'Clutch da cừu, khóa logo CC kinh điển.', 3, 2, N'Da thật (Lambskin)', N'Dự tiệc', N'Classic Flap'),
(N'Túi Tote Vải Bố Vascara Eco', N'Túi tote vải bố, thân thiện môi trường, quai da.', 2, 4, N'Vải bố (Canvas)', N'Dạo phố, Đi học', N'Eco-Friendly'),
(N'Túi Đeo Vai Juno Kẹp Nách', N'Dáng túi kẹp nách baguette, phong cách Y2K.', 4, 3, N'Da tổng hợp (PU)', N'Dạo phố', N'Y2K Revival'),
(N'Túi Tote Charles & Keith Cỡ Lớn', N'Túi tote công sở, đựng vừa laptop 14 inch.', 2, 5, N'Da tổng hợp (PU)', N'Đi làm', N'Workwear');
GO

-- 5. Thêm BienTheSanPham
-- SỬA: Thêm lại đường dẫn thư mục /img/ cho thống nhất
INSERT INTO BienTheSanPham (MaSanPham, SKU, MauSac, ChieuDaiCM, ChieuRongCM, ChieuCaoCM, CanNangGram, GiaBan, GiaGoc, SoLuongTonKho, HinhAnh) VALUES
(1, 'VAS-DC-BLK', N'Đen', 22.0, 8.0, 15.0, 450, 550000.00, 650000.00, 50, '/img/1_den.jpg'),
(1, 'VAS-DC-WHT', N'Trắng', 22.0, 8.0, 15.0, 450, 550000.00, 650000.00, 30, '/img/1_trang.jpg'),
(1, 'VAS-DC-BEI', N'Be', 22.0, 8.0, 15.0, 450, 550000.00, NULL, 40, '/img/1_be.jpg'),
(2, 'JUN-DC-GRY', N'Xám Phối Trắng', 24.0, 9.0, 16.0, 500, 690000.00, NULL, 25, '/img/2_xam.jpg'),
(2, 'JUN-DC-NAV', N'Xanh Navy Phối Be', 24.0, 9.0, 16.0, 500, 690000.00, 790000.00, 15, '/img/2_navy.jpg'),
(2, 'JUN-DC-BRN', N'Nâu Phối Kem', 24.0, 9.0, 16.0, 500, 690000.00, NULL, 20, '/img/2_nau.jpg'),
(3, 'GUC-TOTE-BLK', N'Đen', 38.0, 12.0, 28.0, 950, 45000000.00, NULL, 5, '/img/3_den.jpg'),
(4, 'CK-CLU-SLV', N'Bạc', 19.0, 5.0, 10.0, 400, 1850000.00, 2150000.00, 10, '/img/4_bac.jpg'),
(4, 'CK-CLU-GLD', N'Vàng Đồng', 19.0, 5.0, 10.0, 400, 1850000.00, NULL, 8, '/img/4_vang.jpg'),
(5, 'COA-HOBO-BLK', N'Đen', 26.0, 9.0, 18.0, 600, 7500000.00, NULL, 7, '/img/5_den.jpg'),
(5, 'COA-HOBO-WHT', N'Trắng Kem', 26.0, 9.0, 18.0, 600, 7500000.00, 8200000.00, 5, '/img/5_trang.jpg'),
(6, 'COA-BELT-BRN', N'Nâu Signature', 31.0, 11.0, 16.0, 550, 3500000.00, 4200000.00, 10, '/img/6_nau.jpg'),
(6, 'COA-BELT-BLK', N'Đen Trơn', 31.0, 11.0, 16.0, 550, 3500000.00, NULL, 8, '/img/6_den.jpg'),
(7, 'CHA-CLU-BLK', N'Đen', 25.0, 6.0, 14.0, 700, 89000000.00, NULL, 2, '/img/7_den.jpg'),
(7, 'CHA-CLU-RED', N'Đỏ', 25.0, 6.0, 14.0, 700, 89000000.00, NULL, 1, '/img/7_do.jpg'),
(8, 'VAS-TOTE-NAT', N'Màu Tự Nhiên', 40.0, 10.0, 35.0, 400, 299000.00, NULL, 100, '/img/8_nat.jpg'),
(8, 'VAS-TOTE-BLK', N'Đen', 40.0, 10.0, 35.0, 400, 299000.00, NULL, 70, '/img/8_den.jpg'),
(9, 'JUN-KN-BLK', N'Đen', 25.0, 7.0, 14.0, 350, 520000.00, NULL, 50, '/img/9_den.jpg'),
(9, 'JUN-KN-PNK', N'Hồng Pastel', 25.0, 7.0, 14.0, 350, 520000.00, NULL, 30, '/img/9_hong.jpg'),
(9, 'JUN-KN-BLU', N'Xanh Baby', 25.0, 7.0, 14.0, 350, 520000.00, 590000.00, 0, '/img/9_xanh.jpg'),
(10, 'CK-TOTE-BLK', N'Đen', 35.0, 12.0, 28.0, 850, 2150000.00, NULL, 20, '/img/10_den.jpg'),
(10, 'CK-TOTE-BRN', N'Nâu Đậm', 35.0, 12.0, 28.0, 850, 2150000.00, 2300000.00, 15, '/img/10_nau.jpg');
GO

-- 6. Thêm DiaChi
INSERT INTO DiaChi (MaNguoiDung, TenNguoiNhan, SoDienThoai, SoNhaDuong, PhuongXa, QuanHuyen, TinhThanhPho, LaMacDinh) VALUES
(1, N'Nguyễn Văn A', '0901234567', N'123 Đường ABC', N'Phường 10', N'Quận 3', N'TP. Hồ Chí Minh', 1),
(1, N'Văn Phòng A', '0901234567', N'456 Đường XYZ', N'Phường Bến Nghé', N'Quận 1', N'TP. Hồ Chí Minh', 0),
(2, N'Trần Thị B', '0907654321', N'789 Đường LMN', N'Phường Hàng Bột', N'Quận Đống Đa', N'Hà Nội', 1),
(4, N'Lê Minh Cường', '0912345678', N'111 Hẻm 22', N'Phường An Khánh', N'Quận Ninh Kiều', N'Cần Thơ', 1),
(5, N'Phạm Hồng Duyên', '0987654321', N'333 Chung cư K', N'Phường Mân Thái', N'Quận Sơn Trà', N'Đà Nẵng', 1);
GO

-- 7. Thêm MaKhuyenMai
INSERT INTO MaKhuyenMai (MaCode, LoaiGiamGia, GiaTriGiam, DonToiThieu, NgayHetHan, GioiHanSuDung) VALUES
(N'CHAOBANMOI', N'SoTien', 50000.00, 300000.00, '2026-12-31', 1000),
(N'FREESHIP', N'SoTien', 30000.00, 200000.00, '2026-11-30', 500),
(N'SALE10', N'PhanTram', 10.00, 1000000.00, '2026-10-31', 200);
GO

-- 8. Thêm DonHang
INSERT INTO DonHang (MaNguoiDung, MaDiaChiGiao, TrangThai, PhuongThucThanhToan, TrangThaiThanhToan, TongTienHang, PhiVanChuyen, SoTienGiamGia, TongThanhToan, MaKMID, GhiChu) VALUES
(2, 3, N'DaGiao', N'COD', N'DaThanhToan', 690000.00, 30000.00, 50000.00, 670000.00, 1, N''),
(1, 1, N'DangGiao', N'VNPAY', N'DaThanhToan', 2700000.00, 0.00, 270000.00, 2430000.00, 3, N'Giao nhanh'),
(4, 4, N'ChoXuLy', N'COD', N'ChuaThanhToan', 1118000.00, 35000.00, 0, 1153000.00, NULL, N'Xin gọi trước'),
(5, 5, N'DaGiao', N'COD', N'DaThanhToan', 1850000.00, 30000.00, 0, 1880000.00, NULL, N'Hàng dự tiệc, giao gấp'),
(1, 2, N'DaGiao', N'VNPAY', N'DaThanhToan', 134000000.00, 0.00, 13400000.00, 120600000.00, 3, N'Hàng VIP');
GO

-- 9. Thêm ChiTietDonHang
INSERT INTO ChiTietDonHang (MaDonHang, MaBienThe, SoLuong, GiaLucMua) VALUES
(1, 4, 1, 690000.00),
(2, 2, 1, 550000.00),
(2, 21, 1, 2150000.00),
(3, 17, 2, 299000.00),
(3, 18, 1, 520000.00),
(4, 8, 1, 1850000.00),
(5, 7, 1, 45000000.00),
(5, 15, 1, 89000000.00);
GO

-- 10. Thêm GioHang
INSERT INTO GioHang (MaNguoiDung, MaBienThe, SoLuong) VALUES
(4, 1, 1),
(5, 10, 1);
GO

-- 11. Thêm DanhGia
INSERT INTO DanhGia (MaSanPham, MaNguoiDung, Diem, BinhLuan) VALUES
(2, 2, 5, N'Túi đẹp, y hình, màu xám phối trắng rất sang.'),
(1, 1, 4, N'Túi Vascara xinh, nhưng quai đeo hơi mảnh.'),
(10, 1, 5, N'Đựng vừa laptop, da cứng cáp, rất hợp đi làm.'),
(4, 5, 5, N'Clutch lấp lánh, nổi bật nhất bữa tiệc!'),
(3, 1, 5, N'Đẳng cấp, da thật mềm mịn.'),
(7, 1, 5, N'Kinh điển là mãi mãi. Rất hài lòng.');
GO

-- 12. Thêm PhieuDoiTra
INSERT INTO PhieuDoiTra (MaChiTietDonHang, MaNguoiDung, LoaiYeuCau, LyDo, TrangThai) VALUES
(1, 2, N'Doi', N'Túi bị sứt chỉ ở nắp gập, yêu cầu đổi mẫu mới cùng màu.', N'ChoXuLy');
GO
