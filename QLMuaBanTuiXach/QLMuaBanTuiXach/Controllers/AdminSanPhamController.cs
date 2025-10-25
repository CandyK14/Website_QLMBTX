using System;
using System.Collections.Generic;
using System.Data;
using System.Linq;
using System.Net;
using System.Web;
using System.Web.Mvc;
using QLMuaBanTuiXach.Models;
using System.IO;
using System.Data.Entity;

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
            if (!IsAdmin()) return RedirectToAction("Index", "Home");
            var sanPhams = db.SanPham.Include(s => s.DanhMuc).Include(s => s.ThuongHieu).Include(s => s.BienTheSanPham);
            return View(sanPhams.ToList());
        }

        public ActionResult Details(int? id)
        {
            if (!IsAdmin()) return RedirectToAction("Index", "Home");
            if (id == null) return new HttpStatusCodeResult(HttpStatusCode.BadRequest);
            SanPham sanPham = db.SanPham
                                .Include(s => s.DanhMuc)
                                .Include(s => s.ThuongHieu)
                                .Include(s => s.BienTheSanPham)
                                .FirstOrDefault(s => s.MaSanPham == id);
            if (sanPham == null) return HttpNotFound();
            return View(sanPham);
        }

        public ActionResult Create()
        {
            if (!IsAdmin()) return RedirectToAction("Index", "Home");
            ViewBag.MaDanhMuc = new SelectList(db.DanhMuc, "MaDanhMuc", "TenDanhMuc");
            ViewBag.MaThuongHieu = new SelectList(db.ThuongHieu, "MaThuongHieu", "TenThuongHieu");
            return View(new SanPham());
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public ActionResult Create(SanPham sanPham, FormCollection collection, HttpPostedFileBase HinhAnhUpload)
        {
            if (!IsAdmin()) return RedirectToAction("Index", "Home");

            string sku = collection["BienTheSanPham.SKU"];
            string mauSac = collection["BienTheSanPham.MauSac"];
            decimal giaBan;
            int soLuongTonKho;
            decimal? chieuDai = null;
            decimal? chieuRong = null;
            decimal? chieuCao = null;
            int? canNang = null;

            bool isValidBienThe = true;
            if (string.IsNullOrWhiteSpace(sku))
            {
                ModelState.AddModelError("BienTheSanPham.SKU", "SKU là bắt buộc.");
                isValidBienThe = false;
            }
            else if (db.BienTheSanPham.Any(b => b.SKU == sku))
            {
                ModelState.AddModelError("BienTheSanPham.SKU", "SKU này đã tồn tại.");
                isValidBienThe = false;
            }

            if (!Decimal.TryParse(collection["BienTheSanPham.GiaBan"], out giaBan) || giaBan < 0)
            {
                ModelState.AddModelError("BienTheSanPham.GiaBan", "Giá bán không hợp lệ.");
                isValidBienThe = false;
            }
            if (!Int32.TryParse(collection["BienTheSanPham.SoLuongTonKho"], out soLuongTonKho) || soLuongTonKho < 0)
            {
                ModelState.AddModelError("BienTheSanPham.SoLuongTonKho", "Số lượng tồn kho không hợp lệ.");
                isValidBienThe = false;
            }
            if (HinhAnhUpload == null || HinhAnhUpload.ContentLength == 0)
            {
                ModelState.AddModelError("HinhAnhUpload", "Vui lòng chọn hình ảnh cho biến thể.");
                isValidBienThe = false;
            }

            if (!string.IsNullOrWhiteSpace(collection["BienTheSanPham.ChieuDaiCM"]))
            {
                decimal dai;
                if (Decimal.TryParse(collection["BienTheSanPham.ChieuDaiCM"], out dai) && dai >= 0) chieuDai = dai;
                else ModelState.AddModelError("BienTheSanPham.ChieuDaiCM", "Chiều dài không hợp lệ.");
            }
            if (!string.IsNullOrWhiteSpace(collection["BienTheSanPham.ChieuRongCM"]))
            {
                decimal rong;
                if (Decimal.TryParse(collection["BienTheSanPham.ChieuRongCM"], out rong) && rong >= 0) chieuRong = rong;
                else ModelState.AddModelError("BienTheSanPham.ChieuRongCM", "Chiều rộng không hợp lệ.");
            }
            if (!string.IsNullOrWhiteSpace(collection["BienTheSanPham.ChieuCaoCM"]))
            {
                decimal cao;
                if (Decimal.TryParse(collection["BienTheSanPham.ChieuCaoCM"], out cao) && cao >= 0) chieuCao = cao;
                else ModelState.AddModelError("BienTheSanPham.ChieuCaoCM", "Chiều cao không hợp lệ.");
            }
            if (!string.IsNullOrWhiteSpace(collection["BienTheSanPham.CanNangGram"]))
            {
                int nang;
                if (Int32.TryParse(collection["BienTheSanPham.CanNangGram"], out nang) && nang >= 0) canNang = nang;
                else ModelState.AddModelError("BienTheSanPham.CanNangGram", "Cân nặng không hợp lệ.");
            }

            if (ModelState.ContainsKey("BienTheSanPham.ChieuDaiCM") || ModelState.ContainsKey("BienTheSanPham.ChieuRongCM") ||
                ModelState.ContainsKey("BienTheSanPham.ChieuCaoCM") || ModelState.ContainsKey("BienTheSanPham.CanNangGram"))
            {
                isValidBienThe = false;
            }

            if (ModelState.IsValid && isValidBienThe)
            {
                string tenFileAnh = "";
                if (HinhAnhUpload != null && HinhAnhUpload.ContentLength > 0)
                {
                    var fileName = Path.GetFileName(HinhAnhUpload.FileName);
                    tenFileAnh = sku + Path.GetExtension(fileName);
                    var path = Path.Combine(Server.MapPath("~/Content/HinhAnh/SanPham"), tenFileAnh);

                    string directoryPath = Server.MapPath("~/Content/HinhAnh/SanPham");
                    if (!Directory.Exists(directoryPath)) Directory.CreateDirectory(directoryPath);

                    try { HinhAnhUpload.SaveAs(path); }
                    catch (Exception ex)
                    {
                        ModelState.AddModelError("HinhAnhUpload", "Lỗi khi lưu hình ảnh: " + ex.Message);
                        ViewBag.MaDanhMuc = new SelectList(db.DanhMuc, "MaDanhMuc", "TenDanhMuc", sanPham.MaDanhMuc);
                        ViewBag.MaThuongHieu = new SelectList(db.ThuongHieu, "MaThuongHieu", "TenThuongHieu", sanPham.MaThuongHieu);
                        return View(sanPham);
                    }
                }

                sanPham.NgayTao = DateTime.Now;
                db.SanPham.Add(sanPham);
                db.SaveChanges();

                BienTheSanPham bienThe = new BienTheSanPham();
                bienThe.MaSanPham = sanPham.MaSanPham;
                bienThe.SKU = sku;
                bienThe.MauSac = mauSac;
                bienThe.GiaBan = giaBan;
                bienThe.SoLuongTonKho = soLuongTonKho;
                bienThe.ChieuDaiCM = chieuDai;
                bienThe.ChieuRongCM = chieuRong;
                bienThe.ChieuCaoCM = chieuCao;
                bienThe.CanNangGram = canNang;
                bienThe.HinhAnh = "/Content/HinhAnh/SanPham/" + tenFileAnh;

                db.BienTheSanPham.Add(bienThe);
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
            SanPham sanPham = db.SanPham.Include(sp => sp.BienTheSanPham).FirstOrDefault(sp => sp.MaSanPham == id);
            if (sanPham == null) return HttpNotFound();
            ViewBag.MaDanhMuc = new SelectList(db.DanhMuc, "MaDanhMuc", "TenDanhMuc", sanPham.MaDanhMuc);
            ViewBag.MaThuongHieu = new SelectList(db.ThuongHieu, "MaThuongHieu", "TenThuongHieu", sanPham.MaThuongHieu);
            return View(sanPham);
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public ActionResult Edit([Bind(Include = "MaSanPham,TenSanPham,MoTa,MaDanhMuc,MaThuongHieu,ChatLieuChinh,DipSuDung,BoSuuTap,NgayTao,GiaThamKhao")] SanPham sanPham) // Added GiaThamKhao if exists
        {
            if (!IsAdmin()) return RedirectToAction("Index", "Home");

            if (ModelState.IsValid)
            {
                var existingSanPham = db.SanPham.AsNoTracking().FirstOrDefault(s => s.MaSanPham == sanPham.MaSanPham);
                if (existingSanPham != null)
                {
                    sanPham.NgayTao = existingSanPham.NgayTao;
                }
                // *** SỬA LỖI Ở ĐÂY: Chỉ rõ namespace ***
                db.Entry(sanPham).State = System.Data.Entity.EntityState.Modified;
                db.SaveChanges();
                return RedirectToAction("Edit", new { id = sanPham.MaSanPham });
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


        // =============================================
        // ACTIONS MỚI CHO QUẢN LÝ BIẾN THỂ SẢN PHẨM
        // =============================================

        public ActionResult ThemBienThe(int? maSanPham)
        {
            if (!IsAdmin()) return RedirectToAction("Index", "Home");
            if (maSanPham == null) return new HttpStatusCodeResult(HttpStatusCode.BadRequest);

            SanPham sanPham = db.SanPham.Find(maSanPham.Value);
            if (sanPham == null) return HttpNotFound("Không tìm thấy sản phẩm gốc.");

            var bienThe = new BienTheSanPham { MaSanPham = maSanPham.Value };

            ViewBag.TenSanPhamGoc = sanPham.TenSanPham;

            return View(bienThe);
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public ActionResult ThemBienThe([Bind(Include = "MaSanPham,SKU,MauSac,ChieuDaiCM,ChieuRongCM,ChieuCaoCM,CanNangGram,GiaBan,GiaGoc,SoLuongTonKho")] BienTheSanPham bienThe, HttpPostedFileBase HinhAnhUpload)
        {
            if (!IsAdmin()) return RedirectToAction("Index", "Home");

            SanPham sanPhamGoc = db.SanPham.Find(bienThe.MaSanPham);
            if (sanPhamGoc != null) ViewBag.TenSanPhamGoc = sanPhamGoc.TenSanPham;
            else return HttpNotFound("Sản phẩm gốc không tồn tại.");

            if (db.BienTheSanPham.Any(b => b.SKU == bienThe.SKU))
            {
                ModelState.AddModelError("SKU", "SKU này đã tồn tại.");
            }
            if (HinhAnhUpload == null || HinhAnhUpload.ContentLength == 0)
            {

            }

            if (ModelState.IsValid)
            {
                string tenFileAnh = "";
                if (HinhAnhUpload != null && HinhAnhUpload.ContentLength > 0)
                {
                    var fileName = Path.GetFileName(HinhAnhUpload.FileName);
                    tenFileAnh = bienThe.SKU + Path.GetExtension(fileName);
                    var path = Path.Combine(Server.MapPath("~/Content/HinhAnh/SanPham"), tenFileAnh);
                    string directoryPath = Server.MapPath("~/Content/HinhAnh/SanPham");
                    if (!Directory.Exists(directoryPath)) Directory.CreateDirectory(directoryPath);
                    try { HinhAnhUpload.SaveAs(path); bienThe.HinhAnh = "/Content/HinhAnh/SanPham/" + tenFileAnh; }
                    catch (Exception ex)
                    {
                        ModelState.AddModelError("HinhAnhUpload", "Lỗi lưu ảnh: " + ex.Message);
                        return View(bienThe);
                    }
                }

                db.BienTheSanPham.Add(bienThe);
                db.SaveChanges();
                return RedirectToAction("Edit", new { id = bienThe.MaSanPham });
            }

            return View(bienThe);
        }


        public ActionResult SuaBienThe(int? id)
        {
            if (!IsAdmin()) return RedirectToAction("Index", "Home");
            if (id == null) return new HttpStatusCodeResult(HttpStatusCode.BadRequest);

            BienTheSanPham bienThe = db.BienTheSanPham.Include(b => b.SanPham).FirstOrDefault(b => b.MaBienThe == id);
            if (bienThe == null) return HttpNotFound();

            ViewBag.TenSanPhamGoc = bienThe.SanPham?.TenSanPham ?? "N/A";

            return View(bienThe);
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public ActionResult SuaBienThe([Bind(Include = "MaBienThe,MaSanPham,SKU,MauSac,ChieuDaiCM,ChieuRongCM,ChieuCaoCM,CanNangGram,GiaBan,GiaGoc,SoLuongTonKho,HinhAnh")] BienTheSanPham bienThe, HttpPostedFileBase HinhAnhUpload)
        {
            if (!IsAdmin()) return RedirectToAction("Index", "Home");

            if (db.BienTheSanPham.Any(b => b.SKU == bienThe.SKU && b.MaBienThe != bienThe.MaBienThe))
            {
                ModelState.AddModelError("SKU", "SKU này đã tồn tại ở biến thể khác.");
            }

            if (ModelState.IsValid)
            {
                if (HinhAnhUpload != null && HinhAnhUpload.ContentLength > 0)
                {
                    var fileName = Path.GetFileName(HinhAnhUpload.FileName);
                    string tenFileAnh = bienThe.SKU + Path.GetExtension(fileName);
                    var path = Path.Combine(Server.MapPath("~/Content/HinhAnh/SanPham"), tenFileAnh);
                    string directoryPath = Server.MapPath("~/Content/HinhAnh/SanPham");
                    if (!Directory.Exists(directoryPath)) Directory.CreateDirectory(directoryPath);
                    try { HinhAnhUpload.SaveAs(path); bienThe.HinhAnh = "/Content/HinhAnh/SanPham/" + tenFileAnh; }
                    catch (Exception ex)
                    {
                        ModelState.AddModelError("HinhAnhUpload", "Lỗi lưu ảnh: " + ex.Message);
                        SanPham sanPhamGoc = db.SanPham.Find(bienThe.MaSanPham);
                        if (sanPhamGoc != null) ViewBag.TenSanPhamGoc = sanPhamGoc.TenSanPham;
                        return View(bienThe);
                    }
                }
                db.Entry(bienThe).State = System.Data.Entity.EntityState.Modified;
                db.SaveChanges();
                return RedirectToAction("Edit", new { id = bienThe.MaSanPham });
            }
            SanPham spGoc = db.SanPham.Find(bienThe.MaSanPham);
            if (spGoc != null) ViewBag.TenSanPhamGoc = spGoc.TenSanPham;
            return View(bienThe);
        }


        public ActionResult XoaBienThe(int? id)
        {
            if (!IsAdmin()) return RedirectToAction("Index", "Home");
            if (id == null) return new HttpStatusCodeResult(HttpStatusCode.BadRequest);

            BienTheSanPham bienThe = db.BienTheSanPham.Include(b => b.SanPham).FirstOrDefault(b => b.MaBienThe == id);
            if (bienThe == null) return HttpNotFound();

            ViewBag.TenSanPhamGoc = bienThe.SanPham?.TenSanPham ?? "N/A";

            return View(bienThe);
        }

        [HttpPost] 
        [ValidateAntiForgeryToken]
        public ActionResult XoaBienTheConfirmed(int id) 
        {
            if (!IsAdmin()) return RedirectToAction("Index", "Home");
            BienTheSanPham bienThe = db.BienTheSanPham.Find(id);
            if (bienThe == null) return HttpNotFound();
            int maSanPhamGoc = bienThe.MaSanPham;
            db.BienTheSanPham.Remove(bienThe);
            db.SaveChanges();
            return RedirectToAction("Edit", new { id = maSanPhamGoc });
        }
    }
}
