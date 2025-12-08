using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using QLMuaBanTuiXach.Models;
using System.Data.Entity; // Cần thêm dòng này để dùng .Include() ổn định

namespace QLMuaBanTuiXach.Controllers
{
    public class GioHangController : Controller
    {
        QL_TuiXachEntities db = new QL_TuiXachEntities();

        public ActionResult Index()
        {
            // 1. Nếu chưa đăng nhập thì bắt đăng nhập
            if (Session["TaiKhoan"] == null)
            {
                return RedirectToAction("DangNhap", "NguoiDung");
            }

            NguoiDung khach = (NguoiDung)Session["TaiKhoan"];

            // 2. Lấy danh sách sản phẩm trong giỏ của người dùng này
            var gioHang = db.GioHang
                            .Include("BienTheSanPham")
                            .Include("BienTheSanPham.SanPham")
                            .Where(g => g.MaNguoiDung == khach.MaNguoiDung)
                            .ToList();

            // 3. Trả về View kèm danh sách
            return View(gioHang);
        }

        [HttpPost]
        public ActionResult ThemVaoGio(int maBienThe, int soLuong, int maSanPham)
        {
            // 1. Kiểm tra đăng nhập
            if (Session["TaiKhoan"] == null)
            {
                // Lưu lại trang hiện tại để đăng nhập xong quay lại
                return RedirectToAction("DangNhap", "NguoiDung");
            }

            // === [MỚI] KIỂM TRA QUYỀN: CHẶN NHÂN VIÊN ===
            var vaiTro = Session["VaiTro"] as string;
            if (vaiTro != "KH")
            {
                // Nếu không phải Khách Hàng (là AD, NVBH, QL...) thì báo lỗi
                TempData["LoiDatHang"] = "Tài khoản quản trị/nhân viên không được phép mua hàng.";
                return RedirectToAction("Detail", "Home", new { id = maSanPham });
            }
            // =============================================

            NguoiDung khach = (NguoiDung)Session["TaiKhoan"];

            // 2. Xử lý thêm vào DB
            var item = db.GioHang.FirstOrDefault(g => g.MaNguoiDung == khach.MaNguoiDung && g.MaBienThe == maBienThe);

            if (item != null)
            {
                item.SoLuong += soLuong;
                item.NgayThem = DateTime.Now;
            }
            else
            {
                item = new GioHang();
                item.MaNguoiDung = khach.MaNguoiDung;
                item.MaBienThe = maBienThe;
                item.SoLuong = soLuong;
                item.NgayThem = DateTime.Now;
                db.GioHang.Add(item);
            }

            db.SaveChanges();

            // 3. Quay lại trang chi tiết sản phẩm vừa xem
            return RedirectToAction("Detail", "Home", new { id = maSanPham });
        }

        [HttpPost]
        public ActionResult CapNhatGioHang(int maBienThe, int soLuong)
        {
            if (Session["TaiKhoan"] == null)
            {
                return RedirectToAction("DangNhap", "NguoiDung");
            }

            NguoiDung khach = (NguoiDung)Session["TaiKhoan"];

            var item = db.GioHang.FirstOrDefault(g => g.MaNguoiDung == khach.MaNguoiDung && g.MaBienThe == maBienThe);

            if (item != null)
            {
                // Nếu số lượng <= 0 thì xóa luôn
                if (soLuong <= 0)
                {
                    db.GioHang.Remove(item);
                }
                else
                {
                    item.SoLuong = soLuong;
                }
                db.SaveChanges();
            }

            return RedirectToAction("Index");
        }


        [HttpPost]
        public ActionResult XoaKhoiGio(int maBienThe)
        {
            if (Session["TaiKhoan"] == null)
            {
                return RedirectToAction("DangNhap", "NguoiDung");
            }

            NguoiDung khach = (NguoiDung)Session["TaiKhoan"];

            var item = db.GioHang.FirstOrDefault(g => g.MaNguoiDung == khach.MaNguoiDung && g.MaBienThe == maBienThe);

            if (item != null)
            {
                db.GioHang.Remove(item);
                db.SaveChanges();
            }

            return RedirectToAction("Index");
        }

        [HttpGet]
        public ActionResult ThanhToan()
        {
            if (Session["TaiKhoan"] == null)
            {
                return RedirectToAction("DangNhap", "NguoiDung");
            }

            // === [MỚI] KIỂM TRA QUYỀN: CHẶN NHÂN VIÊN ===
            var vaiTro = Session["VaiTro"] as string;
            if (vaiTro != "KH")
            {
                TempData["LoiGioHang"] = "Nhân viên không được phép thanh toán.";
                return RedirectToAction("Index");
            }
            // =============================================

            NguoiDung khach = (NguoiDung)Session["TaiKhoan"];

            // Lấy giỏ hàng để hiển thị lại lần cuối
            var gioHang = db.GioHang.Include("BienTheSanPham").Include("BienTheSanPham.SanPham")
                            .Where(g => g.MaNguoiDung == khach.MaNguoiDung).ToList();

            if (gioHang.Count == 0)
            {
                return RedirectToAction("Index");
            }

            // Tính toán tổng tiền
            ViewBag.TongTienHang = gioHang.Sum(i => i.SoLuong * i.BienTheSanPham.GiaBan);
            ViewBag.PhiVanChuyen = 30000; // Mặc định phí ship 30k 

            // Lấy thông tin người dùng để điền sẵn vào form cho tiện
            ViewBag.NguoiDung = khach;

            return View(gioHang);
        }

        // 2. XỬ LÝ KHI BẤM NÚT "ĐẶT HÀNG"
        [HttpPost]
        public ActionResult DatHang(string tenNguoiNhan, string soDienThoai, string diaChi, string phuongXa, string quanHuyen, string tinhThanh, string ghiChu)
        {
            if (Session["TaiKhoan"] == null) return RedirectToAction("DangNhap", "NguoiDung");

            // === [MỚI] CHẶN LUÔN Ở POST CHO AN TOÀN ===
            var vaiTro = Session["VaiTro"] as string;
            if (vaiTro != "KH") return RedirectToAction("Index");
            // ==========================================

            NguoiDung khach = (NguoiDung)Session["TaiKhoan"];
            var gioHang = db.GioHang.Include("BienTheSanPham").Where(g => g.MaNguoiDung == khach.MaNguoiDung).ToList();

            if (gioHang.Count == 0) return RedirectToAction("Index");

            // A. TẠO ĐỊA CHỈ GIAO HÀNG MỚI
            DiaChi dc = new DiaChi();
            dc.MaNguoiDung = khach.MaNguoiDung;
            dc.TenNguoiNhan = tenNguoiNhan;
            dc.SoDienThoai = soDienThoai;
            dc.SoNhaDuong = diaChi;
            dc.PhuongXa = phuongXa;
            dc.QuanHuyen = quanHuyen;
            dc.TinhThanhPho = tinhThanh;
            dc.LaMacDinh = false;
            db.DiaChi.Add(dc);
            db.SaveChanges(); // Lưu để lấy được MaDiaChi

            // B. TẠO ĐƠN HÀNG (DONHANG)
            DonHang dh = new DonHang();
            dh.MaNguoiDung = khach.MaNguoiDung;
            dh.NgayDat = DateTime.Now;
            dh.MaDiaChiGiao = dc.MaDiaChi; // Link với địa chỉ vừa tạo
            dh.TrangThai = "ChoXuLy";
            dh.PhuongThucThanhToan = "COD";
            dh.TrangThaiThanhToan = "ChuaThanhToan";

            decimal tongTienHang = gioHang.Sum(i => i.SoLuong * i.BienTheSanPham.GiaBan);
            dh.TongTienHang = tongTienHang;
            dh.PhiVanChuyen = 30000;
            dh.SoTienGiamGia = 0;
            dh.TongThanhToan = dh.TongTienHang + (dh.PhiVanChuyen ?? 0) - (dh.SoTienGiamGia ?? 0);
            dh.GhiChu = ghiChu;

            db.DonHang.Add(dh);
            db.SaveChanges(); // Lưu để lấy MaDonHang

            // C. TẠO CHI TIẾT ĐƠN HÀNG & TRỪ KHO
            foreach (var item in gioHang)
            {
                ChiTietDonHang ct = new ChiTietDonHang();
                ct.MaDonHang = dh.MaDonHang;
                ct.MaBienThe = item.MaBienThe;
                ct.SoLuong = item.SoLuong;
                ct.GiaLucMua = item.BienTheSanPham.GiaBan;
                db.ChiTietDonHang.Add(ct);

                // Trừ tồn kho
                var bienThe = db.BienTheSanPham.Find(item.MaBienThe);
                if (bienThe != null)
                {
                    bienThe.SoLuongTonKho -= item.SoLuong;
                }
            }

            // D. XÓA GIỎ HÀNG
            db.GioHang.RemoveRange(gioHang);

            db.SaveChanges();

            // Chuyển đến trang thông báo thành công
            return RedirectToAction("DatHangThanhCong", new { id = dh.MaDonHang });
        }

        // 3. TRANG THÔNG BÁO THÀNH CÔNG
        public ActionResult DatHangThanhCong(int id)
        {
            return View(id);
        }
    }
}