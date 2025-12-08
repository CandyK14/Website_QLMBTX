using QLMuaBanTuiXach.Models;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using System.Data.Entity;
namespace QLMuaBanTuiXach.Controllers
{
    public class DonHangController : Controller
    {
        QL_TuiXachEntities db  = new QL_TuiXachEntities();
        // 1. DANH SÁCH ĐƠN HÀNG
        public ActionResult Index()
        {
            if (Session["TaiKhoan"] == null)
            {
                return RedirectToAction("DangNhap", "NguoiDung");
            }

            NguoiDung khach = (NguoiDung)Session["TaiKhoan"];

            // Lấy tất cả đơn hàng của người dùng này, sắp xếp mới nhất lên đầu
            var dsDonHang = db.DonHang
                              .Where(d => d.MaNguoiDung == khach.MaNguoiDung)
                              .OrderByDescending(d => d.NgayDat)
                              .ToList();

            return View(dsDonHang);
        }

        // 2. CHI TIẾT 1 ĐƠN HÀNG
        public ActionResult ChiTiet(int id)
        {
            if (Session["TaiKhoan"] == null) return RedirectToAction("DangNhap", "NguoiDung");

            NguoiDung khach = (NguoiDung)Session["TaiKhoan"];

            // Tìm đơn hàng theo ID và phải đúng là của khách hàng đang đăng nhập
            var donHang = db.DonHang
                            .Include(d => d.ChiTietDonHang) // Lấy chi tiết đơn
                            .Include("ChiTietDonHang.BienTheSanPham") // Lấy thông tin biến thể
                            .Include("ChiTietDonHang.BienTheSanPham.SanPham") // Lấy tên sản phẩm gốc
                            .FirstOrDefault(d => d.MaDonHang == id && d.MaNguoiDung == khach.MaNguoiDung);

            if (donHang == null)
            {
                return HttpNotFound();
            }

            return View(donHang);
        }
    }
}