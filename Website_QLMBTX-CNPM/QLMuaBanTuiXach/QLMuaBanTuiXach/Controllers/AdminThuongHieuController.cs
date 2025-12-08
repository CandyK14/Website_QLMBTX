using System;
using System.Collections.Generic;
using System.Data;
using System.Data.Entity;
using System.Linq;
using System.Net;
using System.Web;
using System.Web.Mvc;
using QLMuaBanTuiXach.Models;
using System.IO;

namespace QLMuaBanTuiXach.Controllers
{
    public class AdminThuongHieuController : Controller
    {
        private QL_TuiXachEntities db = new QL_TuiXachEntities();

        // Kiểm tra quyền: Chỉ AD và QLSP
        private bool IsAuthorized()
        {
            var vaiTro = Session["VaiTro"] as string;
            return vaiTro == "AD" || vaiTro == "QLSP";
        }

        // GET: AdminThuongHieu
        public ActionResult Index()
        {
            if (!IsAuthorized()) return RedirectToAction("Index", "Home");
            return View(db.ThuongHieu.ToList());
        }

        // GET: AdminThuongHieu/Create
        public ActionResult Create()
        {
            if (!IsAuthorized()) return RedirectToAction("Index");
            return View();
        }

        // POST: AdminThuongHieu/Create
        [HttpPost]
        [ValidateAntiForgeryToken]
        public ActionResult Create([Bind(Include = "TenThuongHieu,MoTa")] ThuongHieu thuongHieu, HttpPostedFileBase LogoUpload)
        {
            if (!IsAuthorized()) return RedirectToAction("Index");

            if (ModelState.IsValid)
            {
                // Kiểm tra trùng tên
                if (db.ThuongHieu.Any(x => x.TenThuongHieu == thuongHieu.TenThuongHieu))
                {
                    ModelState.AddModelError("TenThuongHieu", "Tên thương hiệu này đã tồn tại.");
                    return View(thuongHieu);
                }

                // Xử lý upload Logo
                if (LogoUpload != null && LogoUpload.ContentLength > 0)
                {
                    var fileName = Path.GetFileName(LogoUpload.FileName);
                    var path = Path.Combine(Server.MapPath("~/Content/HinhAnh/ThuongHieu"), fileName);

                    // Tạo thư mục nếu chưa có
                    string dir = Server.MapPath("~/Content/HinhAnh/ThuongHieu");
                    if (!Directory.Exists(dir)) Directory.CreateDirectory(dir);

                    LogoUpload.SaveAs(path);
                    thuongHieu.Logo = "/Content/HinhAnh/ThuongHieu/" + fileName;
                }

                db.ThuongHieu.Add(thuongHieu);
                db.SaveChanges();
                TempData["ThongBao"] = "Thêm thương hiệu thành công!";
                return RedirectToAction("Index");
            }

            return View(thuongHieu);
        }

        // GET: AdminThuongHieu/Edit/5
        public ActionResult Edit(int? id)
        {
            if (!IsAuthorized()) return RedirectToAction("Index");
            if (id == null) return new HttpStatusCodeResult(HttpStatusCode.BadRequest);
            ThuongHieu thuongHieu = db.ThuongHieu.Find(id);
            if (thuongHieu == null) return HttpNotFound();
            return View(thuongHieu);
        }

        // POST: AdminThuongHieu/Edit/5
        [HttpPost]
        [ValidateAntiForgeryToken]
        public ActionResult Edit([Bind(Include = "MaThuongHieu,TenThuongHieu,MoTa,Logo")] ThuongHieu thuongHieu, HttpPostedFileBase LogoUpload)
        {
            if (!IsAuthorized()) return RedirectToAction("Index");

            if (ModelState.IsValid)
            {
                // Upload logo mới nếu có
                if (LogoUpload != null && LogoUpload.ContentLength > 0)
                {
                    var fileName = Path.GetFileName(LogoUpload.FileName);
                    var path = Path.Combine(Server.MapPath("~/Content/HinhAnh/ThuongHieu"), fileName);
                    LogoUpload.SaveAs(path);
                    thuongHieu.Logo = "/Content/HinhAnh/ThuongHieu/" + fileName;
                }

                db.Entry(thuongHieu).State = System.Data.Entity.EntityState.Modified;
                db.SaveChanges();
                TempData["ThongBao"] = "Cập nhật thành công!";
                return RedirectToAction("Index");
            }
            return View(thuongHieu);
        }

        // GET: AdminThuongHieu/Delete/5
        public ActionResult Delete(int? id)
        {
            if (!IsAuthorized()) return RedirectToAction("Index");
            if (id == null) return new HttpStatusCodeResult(HttpStatusCode.BadRequest);
            ThuongHieu thuongHieu = db.ThuongHieu.Find(id);
            if (thuongHieu == null) return HttpNotFound();
            return View(thuongHieu);
        }

        // POST: AdminThuongHieu/Delete/5
        [HttpPost, ActionName("Delete")]
        [ValidateAntiForgeryToken]
        public ActionResult DeleteConfirmed(int id)
        {
            if (!IsAuthorized()) return RedirectToAction("Index");
            ThuongHieu thuongHieu = db.ThuongHieu.Find(id);

            // Kiểm tra xem thương hiệu có đang được dùng không
            if (db.SanPham.Any(sp => sp.MaThuongHieu == id))
            {
                TempData["Loi"] = "Không thể xóa thương hiệu này vì đang có sản phẩm sử dụng.";
                return RedirectToAction("Index");
            }

            db.ThuongHieu.Remove(thuongHieu);
            db.SaveChanges();
            TempData["ThongBao"] = "Đã xóa thương hiệu.";
            return RedirectToAction("Index");
        }
    }
}