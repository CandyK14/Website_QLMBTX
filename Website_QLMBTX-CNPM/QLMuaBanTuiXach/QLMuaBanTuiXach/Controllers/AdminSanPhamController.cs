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

        // --- 1. SỬA HÀM KIỂM TRA QUYỀN ---
        // Cho phép Admin (AD) và Quản Lý Sản Phẩm (QLSP)
        // Thêm QLK (Quản Lý Kho) nếu bạn muốn họ Xem được danh sách (nhưng nên chặn sửa/xóa ở View)
        private bool IsAuthorized()
        {
            var nguoiDung = Session["TaiKhoan"] as NguoiDung;
            var vaiTro = Session["VaiTro"] as string;

            return nguoiDung != null && (vaiTro == "AD" || vaiTro == "QLSP" || vaiTro == "QLK");
        }

        // Hàm riêng để chặn QLK (Kho) thực hiện sửa/xóa/thêm (Chỉ cho xem Index/Details)
        private bool CanEdit()
        {
            var vaiTro = Session["VaiTro"] as string;
            return vaiTro == "AD" || vaiTro == "QLSP";
        }

        public ActionResult Index()
        {
            if (!IsAuthorized()) return RedirectToAction("Index", "Home");

            // A. Lấy danh sách sản phẩm như bình thường (Code cũ)
            var sanPhams = db.SanPham.Include(s => s.DanhMuc).Include(s => s.ThuongHieu).Include(s => s.BienTheSanPham);

            // B. [MỚI] Lấy danh sách Ticket từ Kho (Dùng Entity Framework)
            // Lấy các yêu cầu có trạng thái 'ChoXuLy', mới nhất lên đầu
            var listYeuCau = db.YeuCauThemSanPham
                               .Where(y => y.TrangThai == "ChoXuLy")
                               .OrderByDescending(y => y.NgayYeuCau)
                               .ToList();

            // Gửi qua ViewBag
            ViewBag.ListYeuCau = listYeuCau;

            return View(sanPhams.ToList());
        }

        public ActionResult Details(int? id)
        {
            if (!IsAuthorized()) return RedirectToAction("Index", "Home");
            if (id == null) return new HttpStatusCodeResult(HttpStatusCode.BadRequest);

            SanPham sanPham = db.SanPham
                                .Include(s => s.DanhMuc)
                                .Include(s => s.ThuongHieu)
                                .Include(s => s.BienTheSanPham)
                                .FirstOrDefault(s => s.MaSanPham == id);
            if (sanPham == null) return HttpNotFound();
            return View(sanPham);
        }

        public ActionResult Create(string tenGoiY = "", string moTaGoiY = "")
        {
            if (!CanEdit()) return RedirectToAction("Index");

            var sanPham = new SanPham();

            // Biến để lưu ID nếu tìm thấy
            int? selectedBrandId = null;
            int? selectedCategoryId = null;

            if (!string.IsNullOrEmpty(tenGoiY))
            {
                sanPham.TenSanPham = tenGoiY.Replace("[SP MỚI] ", "").Replace("[THÊM BIẾN THỂ] ", "").Trim();

                if (!string.IsNullOrEmpty(moTaGoiY))
                {
                    sanPham.MoTa = moTaGoiY;
                    var lines = moTaGoiY.Split('\n');

                    // --- 1. XỬ LÝ THƯƠNG HIỆU ---
                    var dongHieu = lines.FirstOrDefault(x => x.Contains("Thương hiệu:"));
                    if (dongHieu != null)
                    {
                        string tenHieu = dongHieu.Split(':')[1].Trim();
                        var hieuDB = db.ThuongHieu.FirstOrDefault(t => t.TenThuongHieu.Contains(tenHieu));

                        if (hieuDB != null)
                        {
                            selectedBrandId = hieuDB.MaThuongHieu; // Có rồi thì chọn luôn
                        }
                        else
                        {
                            // Chưa có -> Lưu tên lại để báo ra View
                            ViewBag.CanTaoThuongHieu = tenHieu;
                        }
                    }

                    // --- 2. XỬ LÝ DANH MỤC ---
                    var dongDanhMuc = lines.FirstOrDefault(x => x.Contains("Danh mục:"));
                    if (dongDanhMuc != null)
                    {
                        string tenDM = dongDanhMuc.Split(':')[1].Trim();
                        var dmDB = db.DanhMuc.FirstOrDefault(d => d.TenDanhMuc.Contains(tenDM));

                        if (dmDB != null)
                        {
                            selectedCategoryId = dmDB.MaDanhMuc;
                        }
                        else
                        {
                            // Chưa có -> Lưu tên lại để báo ra View
                            ViewBag.CanTaoDanhMuc = tenDM;
                        }
                    }

                    // --- 3. CÁC THÔNG TIN KHÁC (GIỮ NGUYÊN) ---
                    var dongMau = lines.FirstOrDefault(x => x.Contains("Màu sắc:"));
                    if (dongMau != null) ViewBag.AutoMau = dongMau.Split(':')[1].Trim();

                    var dongGia = lines.FirstOrDefault(x => x.Contains("Giá nhập"));
                    if (dongGia != null) ViewBag.AutoGia = new string(dongGia.Where(char.IsDigit).ToArray());

                    var dongSL = lines.FirstOrDefault(x => x.Contains("Số lượng"));
                    if (dongSL != null) ViewBag.AutoSL = new string(dongSL.Where(char.IsDigit).ToArray());
                }
            }

            ViewBag.MaDanhMuc = new SelectList(db.DanhMuc, "MaDanhMuc", "TenDanhMuc", selectedCategoryId);
            ViewBag.MaThuongHieu = new SelectList(db.ThuongHieu, "MaThuongHieu", "TenThuongHieu", selectedBrandId);

            return View(sanPham);
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public ActionResult Create(SanPham sanPham, FormCollection collection, HttpPostedFileBase HinhAnhUpload)
        {
            if (!CanEdit()) return RedirectToAction("Index");

            // --- GIỮ NGUYÊN LOGIC THÊM BIẾN THỂ CŨ CỦA BẠN ---
            string sku = collection["BienTheSanPham.SKU"];
            string mauSac = collection["BienTheSanPham.MauSac"];
            decimal giaBan;
            int soLuongTonKho;
            decimal? chieuDai = null; decimal? chieuRong = null; decimal? chieuCao = null; int? canNang = null;

            bool isValidBienThe = true;
            if (string.IsNullOrWhiteSpace(sku)) { ModelState.AddModelError("BienTheSanPham.SKU", "SKU là bắt buộc."); isValidBienThe = false; }
            else if (db.BienTheSanPham.Any(b => b.SKU == sku)) { ModelState.AddModelError("BienTheSanPham.SKU", "SKU này đã tồn tại."); isValidBienThe = false; }

            if (!Decimal.TryParse(collection["BienTheSanPham.GiaBan"], out giaBan) || giaBan < 0) { ModelState.AddModelError("BienTheSanPham.GiaBan", "Giá bán không hợp lệ."); isValidBienThe = false; }
            if (!Int32.TryParse(collection["BienTheSanPham.SoLuongTonKho"], out soLuongTonKho) || soLuongTonKho < 0) { ModelState.AddModelError("BienTheSanPham.SoLuongTonKho", "Số lượng tồn kho không hợp lệ."); isValidBienThe = false; }

            if (HinhAnhUpload == null || HinhAnhUpload.ContentLength == 0) { ModelState.AddModelError("HinhAnhUpload", "Vui lòng chọn hình ảnh cho biến thể."); isValidBienThe = false; }

            // Parse kích thước (giữ nguyên logic cũ)
            decimal d; if (Decimal.TryParse(collection["BienTheSanPham.ChieuDaiCM"], out d) && d >= 0) chieuDai = d;
            decimal r; if (Decimal.TryParse(collection["BienTheSanPham.ChieuRongCM"], out r) && r >= 0) chieuRong = r;
            decimal c; if (Decimal.TryParse(collection["BienTheSanPham.ChieuCaoCM"], out c) && c >= 0) chieuCao = c;
            int w; if (Int32.TryParse(collection["BienTheSanPham.CanNangGram"], out w) && w >= 0) canNang = w;

            if (ModelState.IsValid && isValidBienThe)
            {
                // Lưu ảnh
                string tenFileAnh = "";
                if (HinhAnhUpload != null && HinhAnhUpload.ContentLength > 0)
                {
                    var fileName = Path.GetFileName(HinhAnhUpload.FileName);
                    tenFileAnh = sku + Path.GetExtension(fileName);
                    var path = Path.Combine(Server.MapPath("~/Content/HinhAnh/SanPham"), tenFileAnh);
                    string directoryPath = Server.MapPath("~/Content/HinhAnh/SanPham");
                    if (!Directory.Exists(directoryPath)) Directory.CreateDirectory(directoryPath);
                    HinhAnhUpload.SaveAs(path);
                }

                // Lưu Sản Phẩm Cha
                sanPham.NgayTao = DateTime.Now;
                db.SanPham.Add(sanPham);
                db.SaveChanges();

                // Lưu Biến Thể Đầu Tiên
                BienTheSanPham bienThe = new BienTheSanPham();
                bienThe.MaSanPham = sanPham.MaSanPham;
                bienThe.SKU = sku;
                bienThe.MauSac = mauSac;
                bienThe.GiaBan = giaBan;
                bienThe.SoLuongTonKho = soLuongTonKho;
                bienThe.ChieuDaiCM = chieuDai; bienThe.ChieuRongCM = chieuRong; bienThe.ChieuCaoCM = chieuCao; bienThe.CanNangGram = canNang;
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
            if (!CanEdit()) return RedirectToAction("Index"); // Chặn QLK
            if (id == null) return new HttpStatusCodeResult(HttpStatusCode.BadRequest);
            SanPham sanPham = db.SanPham.Include(sp => sp.BienTheSanPham).FirstOrDefault(sp => sp.MaSanPham == id);
            if (sanPham == null) return HttpNotFound();
            ViewBag.MaDanhMuc = new SelectList(db.DanhMuc, "MaDanhMuc", "TenDanhMuc", sanPham.MaDanhMuc);
            ViewBag.MaThuongHieu = new SelectList(db.ThuongHieu, "MaThuongHieu", "TenThuongHieu", sanPham.MaThuongHieu);
            return View(sanPham);
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public ActionResult Edit([Bind(Include = "MaSanPham,TenSanPham,MoTa,MaDanhMuc,MaThuongHieu,ChatLieuChinh,DipSuDung,BoSuuTap,NgayTao")] SanPham sanPham)
        {
            if (!CanEdit()) return RedirectToAction("Index");

            if (ModelState.IsValid)
            {
                var existingSanPham = db.SanPham.AsNoTracking().FirstOrDefault(s => s.MaSanPham == sanPham.MaSanPham);
                if (existingSanPham != null)
                {
                    sanPham.NgayTao = existingSanPham.NgayTao;
                }
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
            if (!CanEdit()) return RedirectToAction("Index");
            if (id == null) return new HttpStatusCodeResult(HttpStatusCode.BadRequest);
            SanPham sanPham = db.SanPham.Find(id);
            if (sanPham == null) return HttpNotFound();
            return View(sanPham);
        }

        [HttpPost, ActionName("Delete")]
        [ValidateAntiForgeryToken]
        public ActionResult DeleteConfirmed(int id)
        {
            if (!CanEdit()) return RedirectToAction("Index");
            SanPham sanPham = db.SanPham.Find(id);
            db.SanPham.Remove(sanPham);
            db.SaveChanges();
            return RedirectToAction("Index");
        }


        //  --- QUẢN LÝ BIẾN THỂ (Giữ nguyên logic, chỉ sửa quyền) ---

        public ActionResult ThemBienThe(int? maSanPham)
        {
            if (!CanEdit()) return RedirectToAction("Index");
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
            if (!CanEdit()) return RedirectToAction("Index");

            // Logic thêm biến thể giữ nguyên...
            SanPham sanPhamGoc = db.SanPham.Find(bienThe.MaSanPham);
            if (sanPhamGoc != null) ViewBag.TenSanPhamGoc = sanPhamGoc.TenSanPham;

            if (db.BienTheSanPham.Any(b => b.SKU == bienThe.SKU)) ModelState.AddModelError("SKU", "SKU này đã tồn tại.");

            if (ModelState.IsValid)
            {
                if (HinhAnhUpload != null && HinhAnhUpload.ContentLength > 0)
                {
                    var fileName = Path.GetFileName(HinhAnhUpload.FileName);
                    var tenFileAnh = bienThe.SKU + Path.GetExtension(fileName);
                    var path = Path.Combine(Server.MapPath("~/Content/HinhAnh/SanPham"), tenFileAnh);
                    HinhAnhUpload.SaveAs(path);
                    bienThe.HinhAnh = "/Content/HinhAnh/SanPham/" + tenFileAnh;
                }
                db.BienTheSanPham.Add(bienThe);
                db.SaveChanges();
                return RedirectToAction("Edit", new { id = bienThe.MaSanPham });
            }
            return View(bienThe);
        }

        public ActionResult SuaBienThe(int? id)
        {
            if (!CanEdit()) return RedirectToAction("Index");
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
            if (!CanEdit()) return RedirectToAction("Index");

            if (db.BienTheSanPham.Any(b => b.SKU == bienThe.SKU && b.MaBienThe != bienThe.MaBienThe))
                ModelState.AddModelError("SKU", "SKU này đã tồn tại ở biến thể khác.");

            if (ModelState.IsValid)
            {
                if (HinhAnhUpload != null && HinhAnhUpload.ContentLength > 0)
                {
                    var fileName = Path.GetFileName(HinhAnhUpload.FileName);
                    string tenFileAnh = bienThe.SKU + Path.GetExtension(fileName);
                    var path = Path.Combine(Server.MapPath("~/Content/HinhAnh/SanPham"), tenFileAnh);
                    HinhAnhUpload.SaveAs(path);
                    bienThe.HinhAnh = "/Content/HinhAnh/SanPham/" + tenFileAnh;
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
            if (!CanEdit()) return RedirectToAction("Index");
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
            if (!CanEdit()) return RedirectToAction("Index");
            BienTheSanPham bienThe = db.BienTheSanPham.Find(id);
            if (bienThe == null) return HttpNotFound();
            int maSanPhamGoc = bienThe.MaSanPham;
            db.BienTheSanPham.Remove(bienThe);
            db.SaveChanges();
            return RedirectToAction("Edit", new { id = maSanPhamGoc });
        }

        public ActionResult HoanThanhYeuCau(int id)
        {
            // Kiểm tra quyền (AD hoặc QLSP)
            var vaiTro = Session["VaiTro"] as string;
            if (vaiTro != "AD" && vaiTro != "QLSP") return RedirectToAction("Index");

            var yeuCau = db.YeuCauThemSanPham.Find(id);
            if (yeuCau != null)
            {
                yeuCau.TrangThai = "DaXuLy"; // Đổi trạng thái
                db.SaveChanges();
                TempData["ThongBao"] = "Đã xác nhận xử lý xong yêu cầu #" + id;
            }

            return RedirectToAction("Index");
        }

        public ActionResult TuChoiYeuCau(int id)
        {
            // Kiểm tra quyền
            var vaiTro = Session["VaiTro"] as string;
            if (vaiTro != "AD" && vaiTro != "QLSP") return RedirectToAction("Index");

            var yeuCau = db.YeuCauThemSanPham.Find(id);
            if (yeuCau != null)
            {
                yeuCau.TrangThai = "TuChoi"; // Đổi trạng thái sang Từ Chối
                db.SaveChanges();

                TempData["ThongBao"] = "Đã từ chối yêu cầu #" + id;
            }

            return RedirectToAction("Index");
        }
    }
}