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
    public class AdminDanhMucController : Controller
    {
        private QL_TuiXachEntities db = new QL_TuiXachEntities();

        private bool IsAuthorized()
        {
            var vaiTro = Session["VaiTro"] as string;
            return vaiTro == "AD" || vaiTro == "QLSP";
        }

        public ActionResult Index()
        {
            if (!IsAuthorized()) return RedirectToAction("Index", "Home");
            // Load cả danh mục cha để hiển thị tên
            return View(db.DanhMuc.ToList());
        }

        public ActionResult Create()
        {
            if (!IsAuthorized()) return RedirectToAction("Index");
            // Dropdown chọn danh mục cha (chỉ lấy danh mục gốc cấp 1 để làm cha)
            ViewBag.MaDanhMucCha = new SelectList(db.DanhMuc.Where(d => d.MaDanhMucCha == null), "MaDanhMuc", "TenDanhMuc");
            return View();
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public ActionResult Create([Bind(Include = "TenDanhMuc,MoTa,MaDanhMucCha")] DanhMuc danhMuc)
        {
            if (!IsAuthorized()) return RedirectToAction("Index");

            if (ModelState.IsValid)
            {
                db.DanhMuc.Add(danhMuc);
                db.SaveChanges();
                TempData["ThongBao"] = "Thêm danh mục thành công!";
                return RedirectToAction("Index");
            }

            ViewBag.MaDanhMucCha = new SelectList(db.DanhMuc.Where(d => d.MaDanhMucCha == null), "MaDanhMuc", "TenDanhMuc", danhMuc.MaDanhMucCha);
            return View(danhMuc);
        }

        public ActionResult Edit(int? id)
        {
            if (!IsAuthorized()) return RedirectToAction("Index");
            if (id == null) return new HttpStatusCodeResult(HttpStatusCode.BadRequest);
            DanhMuc danhMuc = db.DanhMuc.Find(id);
            if (danhMuc == null) return HttpNotFound();

            // Loại bỏ chính nó khỏi dropdown cha (để tránh lỗi vòng lặp cha-con)
            var listCha = db.DanhMuc.Where(d => d.MaDanhMucCha == null && d.MaDanhMuc != id).ToList();
            ViewBag.MaDanhMucCha = new SelectList(listCha, "MaDanhMuc", "TenDanhMuc", danhMuc.MaDanhMucCha);
            return View(danhMuc);
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public ActionResult Edit([Bind(Include = "MaDanhMuc,TenDanhMuc,MoTa,MaDanhMucCha,AnhDaiDien")] DanhMuc danhMuc)
        {
            if (!IsAuthorized()) return RedirectToAction("Index");

            if (ModelState.IsValid)
            {
                db.Entry(danhMuc).State = System.Data.Entity.EntityState.Modified;
                db.SaveChanges();
                TempData["ThongBao"] = "Cập nhật thành công!";
                return RedirectToAction("Index");
            }

            var listCha = db.DanhMuc.Where(d => d.MaDanhMucCha == null && d.MaDanhMuc != danhMuc.MaDanhMuc).ToList();
            ViewBag.MaDanhMucCha = new SelectList(listCha, "MaDanhMuc", "TenDanhMuc", danhMuc.MaDanhMucCha);
            return View(danhMuc);
        }

        // Action Xóa tương tự như Thương Hiệu (Cần check xem có SP hoặc Danh mục con không)
        public ActionResult Delete(int? id)
        {
            if (!IsAuthorized()) return RedirectToAction("Index");
            var dm = db.DanhMuc.Find(id);
            return View(dm);
        }

        [HttpPost, ActionName("Delete")]
        [ValidateAntiForgeryToken]
        public ActionResult DeleteConfirmed(int id)
        {
            if (!IsAuthorized()) return RedirectToAction("Index");

            // Check ràng buộc
            bool coSanPham = db.SanPham.Any(sp => sp.MaDanhMuc == id);
            bool coCon = db.DanhMuc.Any(d => d.MaDanhMucCha == id);

            if (coSanPham || coCon)
            {
                TempData["Loi"] = "Không thể xóa danh mục này vì đang chứa sản phẩm hoặc danh mục con.";
                return RedirectToAction("Index");
            }

            DanhMuc danhMuc = db.DanhMuc.Find(id);
            db.DanhMuc.Remove(danhMuc);
            db.SaveChanges();
            TempData["ThongBao"] = "Đã xóa danh mục.";
            return RedirectToAction("Index");
        }
    }
}