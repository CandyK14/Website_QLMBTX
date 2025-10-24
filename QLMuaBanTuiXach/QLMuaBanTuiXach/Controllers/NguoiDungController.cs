using System;
using System.Collections.Generic;
using System.Data.SqlClient;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using QLMuaBanTuiXach.Models; 
using System.Data.Entity;     

namespace QLMuaBanTuiXach.Controllers 
{
    public class NguoiDungController : Controller
    {
        
        QL_TuiXachEntities1 db = new QL_TuiXachEntities1();

        
        public ActionResult DangKy()
        {
            return View();
        }

        
        [HttpPost]
        public ActionResult DangKy(FormCollection collection)
        {
            
            var hoTen = collection["HoTen"];
            var email = collection["Email"];
            var soDienThoai = collection["SoDienThoai"];
            var matKhau = collection["MatKhau"];
            var matKhauNhapLai = collection["MatKhauNhapLai"];

            
            if (string.IsNullOrEmpty(hoTen))
            {
                ViewData["Loi_HoTen"] = "Họ tên không được để trống";
            }
            else if (string.IsNullOrEmpty(email))
            {
                ViewData["Loi_Email"] = "Email không được để trống";
            }
            
            else if (db.NguoiDung.Any(n => n.Email == email))
            {
                ViewBag.ThongBaoLoi = "Địa chỉ email này đã được sử dụng.";
            }
            else if (string.IsNullOrEmpty(matKhau))
            {
                ViewData["Loi_MatKhau"] = "Vui lòng nhập mật khẩu";
            }
            else if (matKhau != matKhauNhapLai)
            {
                ViewData["Loi_NhapLai"] = "Mật khẩu nhập lại không khớp";
            }
            else
            {
                

                NguoiDung nd = new NguoiDung();
                nd.HoTen = hoTen;
                nd.Email = email;
                nd.SoDienThoai = soDienThoai;
                nd.MatKhauHash = matKhau; 
                nd.NgayTao = DateTime.Now;                                                       
                db.NguoiDung.Add(nd);      
                db.SaveChanges();        

                ViewBag.ThongBaoThanhCong = "Tạo tài khoản thành công! Bạn có thể đăng nhập ngay bây giờ.";

                return RedirectToAction("Index", "Home");
            }

         
            return View();
        }

       
        protected override void Dispose(bool disposing)
        {
            if (disposing)
            {
                db.Dispose();
            }
            base.Dispose(disposing);
        }
        public ActionResult DangNhap()
        {
            return RedirectToAction("Index", "Home", new { login = true });
        }
        [HttpPost]
        public ActionResult DangNhap(FormCollection collection)
        {
            var email = collection["Email"];
            var matKhau = collection["MatKhau"];
            string thongBaoLoi = null; 
            try
            {
                var addr = new System.Net.Mail.MailAddress(email);
                if (addr.Address != email)
                {
                    thongBaoLoi = "Email không chính xác.";
                }
            }
            catch
            {
                thongBaoLoi = "Email không chính xác.";
            }
            if (string.IsNullOrEmpty(email) && thongBaoLoi == null) 
            {
                thongBaoLoi = "Vui lòng nhập địa chỉ email.";
            }
            else if (string.IsNullOrEmpty(matKhau))
            {
                thongBaoLoi = "Vui lòng nhập mật khẩu.";
            }
            if (thongBaoLoi == null)
            {
                NguoiDung nd = db.NguoiDung.FirstOrDefault(n => n.Email == email);

                if (nd == null)
                {
                    thongBaoLoi = "Email không chính xác.";
                }
                else
                {
                    if (nd.MatKhauHash == matKhau)
                    {
                        Session["TaiKhoan"] = nd;
                        Session["TenNguoiDung"] = nd.HoTen;
                        Session["VaiTro"] = nd.VaiTro;
                        return RedirectToAction("Index", "Home");
                    }
                    else
                    {
                        thongBaoLoi = "Email và mật khẩu không chính xác.";
                    }
                }
            }
            if (thongBaoLoi != null)
            {
                TempData["LoiDangNhap"] = thongBaoLoi; 
                return RedirectToAction("Index", "Home", new { login = true });
            }

            return RedirectToAction("Index", "Home");
        }
        public ActionResult DangXuat()
        {
            Session.Clear();
            return RedirectToAction("Index", "Home");
        }
    }
}