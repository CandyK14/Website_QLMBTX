using System;
using System.Collections.Generic;
using System.Data;
using System.Data.Entity;
using System.Linq;
using System.Net;
using System.Web;
using System.Web.Mvc;
using QLMuaBanTuiXach.Models;

namespace QLMuaBanTuiXach.Controllers
{
    public class AdminDonHangController : Controller
    {
        private QL_TuiXachEntities db = new QL_TuiXachEntities();

        // --- Hàm kiểm tra quyền: Chỉ AD và QLDH mới được vào ---
        private bool IsAuthorized()
        {
            var nguoiDung = Session["TaiKhoan"] as NguoiDung;
            var vaiTro = Session["VaiTro"] as string;

            // Cho phép Admin Tổng (AD) và Quản Lý Đơn Hàng (QLDH)
            return nguoiDung != null && (vaiTro == "AD" || vaiTro == "QLDH");
        }

        // GET: AdminDonHang
        // --- Danh sách đơn hàng ---
        public ActionResult Index()
        {
            if (!IsAuthorized()) return RedirectToAction("Index", "Home");

            // Lấy danh sách đơn hàng, sắp xếp mới nhất lên đầu
            var donHangs = db.DonHang.Include(d => d.NguoiDung).Include(d => d.DiaChi)
                                      .OrderByDescending(d => d.NgayDat);
            return View(donHangs.ToList());
        }

        // GET: AdminDonHang/Details/5
        // --- Xem chi tiết đơn hàng ---
        public ActionResult Details(int? id)
        {
            if (!IsAuthorized()) return RedirectToAction("Index", "Home");
            if (id == null) return new HttpStatusCodeResult(HttpStatusCode.BadRequest);

            // Lấy đơn hàng và bao gồm cả Chi tiết đơn hàng -> Biến thể -> Sản phẩm
            DonHang donHang = db.DonHang
                                .Include(d => d.NguoiDung)
                                .Include(d => d.DiaChi)
                                .Include(d => d.ChiTietDonHang.Select(ct => ct.BienTheSanPham.SanPham)) // Load sâu để lấy tên SP
                                .FirstOrDefault(d => d.MaDonHang == id);

            if (donHang == null) return HttpNotFound();

            return View(donHang);
        }

        // GET: AdminDonHang/Edit/5
        // --- Cập nhật trạng thái đơn hàng ---
        public ActionResult Edit(int? id)
        {
            if (!IsAuthorized()) return RedirectToAction("Index", "Home");
            if (id == null) return new HttpStatusCodeResult(HttpStatusCode.BadRequest);

            DonHang donHang = db.DonHang.Find(id);
            if (donHang == null) return HttpNotFound();

            // Chỉ cho phép sửa một số thông tin
            return View(donHang);
        }

        // POST: AdminDonHang/Edit/5
        // POST: AdminDonHang/Edit/5
        [HttpPost]
        [ValidateAntiForgeryToken]
        public ActionResult Edit([Bind(Include = "MaDonHang,TrangThai,TrangThaiThanhToan,GhiChu")] DonHang donHang)
        {
            if (!IsAuthorized()) return RedirectToAction("Index", "Home");

            if (ModelState.IsValid)
            {
                // 1. Lấy đơn hàng gốc từ DB (Lúc này EF đã bắt đầu theo dõi dbDonHang)
                var dbDonHang = db.DonHang.Find(donHang.MaDonHang);

                if (dbDonHang != null)
                {
                    // 2. Cập nhật các trường cần thiết
                    dbDonHang.TrangThai = donHang.TrangThai;
                    dbDonHang.TrangThaiThanhToan = donHang.TrangThaiThanhToan;
                    dbDonHang.GhiChu = donHang.GhiChu;

                    // Cập nhật người duyệt
                    var currentUser = Session["TaiKhoan"] as NguoiDung;
                    if (currentUser != null)
                    {
                        dbDonHang.MaQLDonHangDuyet = currentUser.MaNguoiDung;
                    }

                    // 3. XÓA DÒNG db.Entry(...).Modified ĐI
                    // Chỉ cần gọi SaveChanges, EF tự biết cái gì thay đổi để update
                    db.SaveChanges();
                }
                return RedirectToAction("Index");
            }
            return View(donHang);
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