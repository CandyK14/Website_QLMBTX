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
    public class AdminSanPhamController : Controller
    {
        private QL_TuiXachEntities db = new QL_TuiXachEntities();

        private bool IsAdmin()
        {
            var nguoiDung = Session["TaiKhoan"] as NguoiDung;
            var vaiTro = Session["VaiTro"] as string;
            return nguoiDung != null && vaiTro == "QuanTriVien";
        }

        public ActionResult Index()
        {
            if (!IsAdmin())
            {
                return RedirectToAction("Index", "Home");
            }
            var sanPhams = db.SanPham.Include(s => s.DanhMuc).Include(s => s.ThuongHieu);
            return View(sanPhams.ToList());
        }

        public ActionResult Details(int? id)
        {
            if (!IsAdmin()) return RedirectToAction("Index", "Home");
            if (id == null)
            {
                return new HttpStatusCodeResult(HttpStatusCode.BadRequest);
            }
            SanPham sanPham = db.SanPham
                                .Include(s => s.DanhMuc)
                                .Include(s => s.ThuongHieu)
                                .Include(s => s.BienTheSanPham)
                                .FirstOrDefault(s => s.MaSanPham == id);
            if (sanPham == null)
            {
                return HttpNotFound();
            }
            return View(sanPham);
        }

        public ActionResult Create()
        {
            if (!IsAdmin()) return RedirectToAction("Index", "Home");
            ViewBag.MaDanhMuc = new SelectList(db.DanhMuc, "MaDanhMuc", "TenDanhMuc");
            ViewBag.MaThuongHieu = new SelectList(db.ThuongHieu, "MaThuongHieu", "TenThuongHieu");
            return View();
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public ActionResult Create([Bind(Include = "MaSanPham,TenSanPham,MoTa,MaDanhMuc,MaThuongHieu,ChatLieuChinh,DipSuDung,BoSuuTap")] SanPham sanPham)
        {
            if (!IsAdmin()) return RedirectToAction("Index", "Home");
            if (ModelState.IsValid)
            {
                sanPham.NgayTao = DateTime.Now;
                db.SanPham.Add(sanPham);
                db.SaveChanges();
                return RedirectToAction("Index");
            }

            ViewBag.MaDanhMuc = new SelectList(db.DanhMuc, "MaDanhMuc", "TenDanhMuc", sanPham.MaDanhMuc);
            ViewBag.MaThuongHieu = new SelectList(db.ThuongHieu, "MaThuongHieu", "TenThuongHieu", sanPham.MaThuongHieu);
            return View(sanPham);
        }

        public ActionResult Edit(int? id)
        {
            if (!IsAdmin()) return RedirectToAction("Index", "Home");
            if (id == null) return new HttpStatusCodeResult(HttpStatusCode.BadRequest);
            SanPham sanPham = db.SanPham.Find(id);
            if (sanPham == null) return HttpNotFound();

            ViewBag.MaDanhMuc = new SelectList(db.DanhMuc, "MaDanhMuc", "TenDanhMuc", sanPham.MaDanhMuc);
            ViewBag.MaThuongHieu = new SelectList(db.ThuongHieu, "MaThuongHieu", "TenThuongHieu", sanPham.MaThuongHieu);
            return View(sanPham);
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public ActionResult Edit([Bind(Include = "MaSanPham,TenSanPham,MoTa,MaDanhMuc,MaThuongHieu,ChatLieuChinh,DipSuDung,BoSuuTap,NgayTao")] SanPham sanPham)
        {
            if (!IsAdmin()) return RedirectToAction("Index", "Home");
            if (ModelState.IsValid)
            {
                db.Entry(sanPham).State = System.Data.Entity.EntityState.Modified;
                db.SaveChanges();
                return RedirectToAction("Index");
            }
            ViewBag.MaDanhMuc = new SelectList(db.DanhMuc, "MaDanhMuc", "TenDanhMuc", sanPham.MaDanhMuc);
            ViewBag.MaThuongHieu = new SelectList(db.ThuongHieu, "MaThuongHieu", "TenThuongHieu", sanPham.MaThuongHieu);
            return View(sanPham);
        }

        public ActionResult Delete(int? id)
        {
            if (!IsAdmin()) return RedirectToAction("Index", "Home");
            if (id == null) return new HttpStatusCodeResult(HttpStatusCode.BadRequest);
            SanPham sanPham = db.SanPham.Find(id);
            if (sanPham == null) return HttpNotFound();
            return View(sanPham);
        }

        [HttpPost, ActionName("Delete")]
        [ValidateAntiForgeryToken]
        public ActionResult DeleteConfirmed(int id)
        {
            if (!IsAdmin()) return RedirectToAction("Index", "Home");
            SanPham sanPham = db.SanPham.Find(id);
            db.SanPham.Remove(sanPham);
            db.SaveChanges();
            return RedirectToAction("Index");
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

