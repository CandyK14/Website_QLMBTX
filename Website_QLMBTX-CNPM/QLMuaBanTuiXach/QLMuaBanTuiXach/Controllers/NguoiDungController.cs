using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using QLMuaBanTuiXach.Models;
using System.Data.Entity;

namespace QLMuaBanTuiXach.Controllers
{
    public class NguoiDungController : Controller
    {
        QL_TuiXachEntities db = new QL_TuiXachEntities();

        // GET: /NguoiDung/DangKy
        public ActionResult DangKy()
        {
            return View();
        }

        // POST: /NguoiDung/DangKy
        [HttpPost]
        [ValidateAntiForgeryToken] // Nên thêm cái này để bảo mật form
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
            else if (db.NguoiDung.Any(n => n.Email == email)) // Lưu ý: NguoiDungs (số nhiều) do EF sinh ra
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
                // --- Tạo người dùng mới ---
                NguoiDung nd = new NguoiDung();
                nd.HoTen = hoTen;
                nd.Email = email;
                nd.SoDienThoai = soDienThoai;
                nd.MatKhauHash = matKhau; // Lưu mật khẩu thường (như bạn yêu cầu)
                nd.NgayTao = DateTime.Now;

                // =========================================================
                // SỬA LẠI QUAN TRỌNG: Gán Mã Vai Trò thay vì tên Vai Trò
                // Dựa theo file SQL, mã cho khách hàng là 'KH'
                // =========================================================
                nd.MaVaiTro = "KH";

                db.NguoiDung.Add(nd);
                db.SaveChanges();

                // Lưu thông báo vào TempData để hiển thị sau khi redirect
                TempData["DangKyThanhCong"] = "Tạo tài khoản thành công! Bạn có thể đăng nhập ngay bây giờ.";

                // Chuyển hướng về trang chủ
                return RedirectToAction("Index", "Home");
            }

            return View();
        }

        // GET: /NguoiDung/DangNhap
        public ActionResult DangNhap()
        {
            // Trả về view đăng nhập (nếu bạn dùng trang riêng)
            // Hoặc redirect về Home để mở modal (như logic cũ của bạn)
            return View();
        }

        // POST: /NguoiDung/DangNhap
        [HttpPost]
        public ActionResult DangNhap(FormCollection collection)
        {
            var email = collection["Email"];
            var matKhau = collection["MatKhau"];
            string thongBaoLoi = null;

            // Kiểm tra định dạng email cơ bản
            try
            {
                var addr = new System.Net.Mail.MailAddress(email);
                if (addr.Address != email) thongBaoLoi = "Email không chính xác.";
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
                // Tìm người dùng theo Email
                NguoiDung nd = db.NguoiDung.FirstOrDefault(n => n.Email == email);

                if (nd == null)
                {
                    thongBaoLoi = "Email không chính xác.";
                }
                else
                {
                    // Kiểm tra mật khẩu (so sánh trực tiếp)
                    if (nd.MatKhauHash == matKhau)
                    {
                        // Đăng nhập thành công
                        Session["TaiKhoan"] = nd;
                        Session["TenNguoiDung"] = nd.HoTen;

                        // SỬA LẠI: Lấy mã vai trò để phân quyền
                        // Lưu ý: Trong DB mới cột là MaVaiTro, không phải VaiTro
                        Session["VaiTro"] = nd.MaVaiTro;

                        // Chuyển hướng về trang chủ
                        return RedirectToAction("Index", "Home");
                    }
                    else
                    {
                        thongBaoLoi = "Email và mật khẩu không chính xác.";
                    }
                }
            }

            // Nếu có lỗi
            if (thongBaoLoi != null)
            {
                TempData["LoiDangNhap"] = thongBaoLoi;
                // Trả về View DangNhap để hiển thị lỗi (nếu dùng trang riêng)
                // Hoặc Redirect về Home với tham số login=true (nếu dùng modal)
                return RedirectToAction("Index", "Home", new { login = true });
            }

            return RedirectToAction("Index", "Home");
        }

        public ActionResult DangXuat()
        {
            Session.Clear();
            return RedirectToAction("Index", "Home");
        }

        // ... Các action ThongTinCaNhan giữ nguyên, chỉ cần đảm bảo db.NguoiDungs là đúng tên ...
        public ActionResult ThongTinCaNhan()
        {
            if (Session["TaiKhoan"] == null)
            {
                TempData["Loi"] = "Vui lòng đăng nhập để xem thông tin.";
                return RedirectToAction("Index", "Home", new { login = true });
            }

            NguoiDung currentUser = (NguoiDung)Session["TaiKhoan"];
            NguoiDung nguoiDungDB = db.NguoiDung.Find(currentUser.MaNguoiDung); // Sửa NguoiDung -> NguoiDungs

            if (nguoiDungDB == null)
            {
                Session.Clear();
                TempData["Loi"] = "Đã xảy ra lỗi, vui lòng đăng nhập lại.";
                return RedirectToAction("Index", "Home", new { login = true });
            }
            ViewBag.ActiveMenu = "ThongTin";
            return View(nguoiDungDB);
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public ActionResult ThongTinCaNhan(FormCollection collection)
        {
            if (Session["TaiKhoan"] == null)
            {
                return RedirectToAction("Index", "Home", new { login = true });
            }

            NguoiDung currentUser = (NguoiDung)Session["TaiKhoan"];
            NguoiDung nguoiDungToUpdate = db.NguoiDung.Find(currentUser.MaNguoiDung); // Sửa NguoiDung -> NguoiDungs

            if (nguoiDungToUpdate == null)
            {
                Session.Clear();
                TempData["Loi"] = "Đã xảy ra lỗi, vui lòng đăng nhập lại.";
                return RedirectToAction("Index", "Home", new { login = true });
            }

            var hoTenMoi = collection["HoTen"];
            var soDienThoaiMoi = collection["SoDienThoai"];
            if (string.IsNullOrEmpty(hoTenMoi))
            {
                ModelState.AddModelError("HoTen", "Họ tên không được để trống.");
            }
            if (ModelState.IsValid)
            {
                nguoiDungToUpdate.HoTen = hoTenMoi;
                nguoiDungToUpdate.SoDienThoai = soDienThoaiMoi;
                db.Entry(nguoiDungToUpdate).State = System.Data.Entity.EntityState.Modified;
                db.SaveChanges();
                Session["TaiKhoan"] = nguoiDungToUpdate;
                Session["TenNguoiDung"] = nguoiDungToUpdate.HoTen;

                TempData["CapNhatThanhCong"] = "Cập nhật thông tin thành công!";
                return RedirectToAction("ThongTinCaNhan");
            }
            return View(nguoiDungToUpdate);
        }

        protected override void Dispose(bool disposing)
        {
            if (disposing)
            {
                db.Dispose();
            }
            base.Dispose(disposing);
        }
    }
}