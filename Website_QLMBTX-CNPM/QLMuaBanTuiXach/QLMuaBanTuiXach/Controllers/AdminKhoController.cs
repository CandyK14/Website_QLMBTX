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
    public class AdminKhoController : Controller
    {
        private QL_TuiXachEntities db = new QL_TuiXachEntities();

        private bool IsAuthorized()
        {
            var vaiTro = Session["VaiTro"] as string;
            return vaiTro == "AD" || vaiTro == "QLK";
        }

        // GET: AdminKho/Index
        public ActionResult Index()
        {
            if (!IsAuthorized()) return RedirectToAction("Index", "Home");
            var phieuNhaps = db.PhieuNhap.Include(p => p.NhaCungCap).Include(p => p.NguoiDung).OrderByDescending(p => p.NgayNhap);
            return View(phieuNhaps.ToList());
        }

        // GET: AdminKho/Details
        public ActionResult Details(int? id)
        {
            if (!IsAuthorized()) return RedirectToAction("Index", "Home");
            if (id == null) return new HttpStatusCodeResult(HttpStatusCode.BadRequest);
            var phieuNhap = db.PhieuNhap.Include(p => p.NhaCungCap).Include(p => p.NguoiDung).Include(p => p.NguoiDung1)
                                        .Include(p => p.ChiTietPhieuNhap.Select(ct => ct.BienTheSanPham.SanPham))
                                        .FirstOrDefault(p => p.MaPhieuNhap == id);
            if (phieuNhap == null) return HttpNotFound();
            return View(phieuNhap);
        }

        // --- [QUAN TRỌNG] GET: AdminKho/Create ---
        public ActionResult Create()
        {
            if (!IsAuthorized()) return RedirectToAction("Index", "Home");

            ViewBag.MaNhaCungCap = new SelectList(db.NhaCungCap, "MaNhaCungCap", "TenNhaCungCap");

            // [LOGIC CHUẨN]: Lấy danh sách BIẾN THỂ để nhập kho [cite: 176]
            // Format hiển thị: "Tên SP - Màu (SKU) - Tồn: X" 
            var variants = db.BienTheSanPham
                             .Include(b => b.SanPham)
                             .Select(b => new
                             {
                                 MaBienThe = b.MaBienThe,
                                 // Chuỗi hiển thị giúp kho dễ chọn đúng hàng [cite: 184]
                                 TenHienThi = b.SanPham.TenSanPham + " - " + b.MauSac + " (SKU: " + b.SKU + ") - Tồn: " + b.SoLuongTonKho
                             })
                             .OrderBy(x => x.TenHienThi)
                             .ToList();

            ViewBag.ListSanPham = new SelectList(variants, "MaBienThe", "TenHienThi");

            return View();
        }

        // POST: AdminKho/Create
        [HttpPost]
        [ValidateAntiForgeryToken]
        public ActionResult Create(PhieuNhap phieuNhap, List<ChiTietPhieuNhap> chiTietNhap)
        {
            if (!IsAuthorized()) return RedirectToAction("Index", "Home");

            if (ModelState.IsValid)
            {
                // [LOGIC]: Lưu phiếu nhập ở trạng thái Chờ Duyệt
                phieuNhap.NgayNhap = DateTime.Now;
                phieuNhap.TrangThai = "ChoDuyet";

                var user = Session["TaiKhoan"] as NguoiDung;
                phieuNhap.MaNhanVienNhap = user.MaNguoiDung;

                // Tính tổng tiền
                if (chiTietNhap != null)
                {
                    phieuNhap.TongTien = chiTietNhap.Sum(x => x.SoLuong * x.GiaNhap);
                }

                db.PhieuNhap.Add(phieuNhap);
                db.SaveChanges();

                // [LOGIC]: Lưu từng dòng chi tiết (Biến thể) [cite: 187]
                if (chiTietNhap != null && chiTietNhap.Count > 0)
                {
                    foreach (var item in chiTietNhap)
                    {
                        if (item.MaBienThe != 0 && item.SoLuong > 0)
                        {
                            item.MaPhieuNhap = phieuNhap.MaPhieuNhap;
                            db.ChiTietPhieuNhap.Add(item);
                        }
                    }
                    db.SaveChanges();
                }

                return RedirectToAction("Index");
            }

            // Nếu lỗi thì load lại list
            ViewBag.MaNhaCungCap = new SelectList(db.NhaCungCap, "MaNhaCungCap", "TenNhaCungCap", phieuNhap.MaNhaCungCap);
            var variants = db.BienTheSanPham.Include(b => b.SanPham)
                             .Select(b => new { MaBienThe = b.MaBienThe, TenHienThi = b.SanPham.TenSanPham + " - " + b.MauSac + " (" + b.SKU + ")" }).ToList();
            ViewBag.ListSanPham = new SelectList(variants, "MaBienThe", "TenHienThi");

            return View(phieuNhap);
        }

        public ActionResult DuyetPhieu(int id)
        {
            if (!IsAuthorized()) return RedirectToAction("Index", "Home");
            var vaiTro = Session["VaiTro"] as string;
            if (vaiTro != "AD")
            {
                TempData["LoiKho"] = "Chỉ Admin mới được duyệt nhập kho.";
                return RedirectToAction("Details", new { id = id });
            }

            var phieu = db.PhieuNhap.Find(id);
            if (phieu != null && phieu.TrangThai == "ChoDuyet")
            {
                phieu.TrangThai = "DaDuyet";
                var user = Session["TaiKhoan"] as NguoiDung;
                phieu.MaAdminDuyet = user.MaNguoiDung;
                phieu.NgayDuyet = DateTime.Now;
                db.SaveChanges(); // Trigger sẽ tự cộng tồn kho
            }
            return RedirectToAction("Details", new { id = id });
        }

        // Hàm này giữ nguyên
        public ActionResult TonKhoThap()
        {
            if (!IsAuthorized()) return RedirectToAction("Index", "Home");
            var spSapHet = db.BienTheSanPham.Include(b => b.SanPham).Where(b => b.SoLuongTonKho < 10).OrderBy(b => b.SoLuongTonKho).ToList();
            return View(spSapHet);
        }

        // --- THÊM VÀO CUỐI FILE AdminKhoController.cs ---

        // GET: AdminKho/TaoYeuCau
        public ActionResult TaoYeuCau()
        {
            if (!IsAuthorized()) return RedirectToAction("Index", "Home");

            // Lấy danh sách sản phẩm đang có để QL Kho chọn (nếu là nhập thêm biến thể)
            ViewBag.ListSanPhamCu = new SelectList(db.SanPham, "TenSanPham", "TenSanPham");

            return View();
        }

        // POST: AdminKho/TaoYeuCau
        [HttpPost]
        [ValidateAntiForgeryToken]
        public ActionResult TaoYeuCau(string loaiYeuCau, string tenSanPhamMoi, string tenSanPhamCu,
                                      string thuongHieu, string danhMuc, // Dành cho SP mới
                                      string mauSac, string kichThuoc, decimal? giaNhap, int? soLuong, string ghiChu)
        {
            if (!IsAuthorized()) return RedirectToAction("Index", "Home");

            // 1. Xác định tên sản phẩm dựa trên loại yêu cầu
            string tenChinh = "";
            string moTaGop = "";

            if (loaiYeuCau == "Moi")
            {
                // TRƯỜNG HỢP 1: SẢN PHẨM MỚI HOÀN TOÀN
                if (string.IsNullOrEmpty(tenSanPhamMoi))
                {
                    ModelState.AddModelError("", "Vui lòng nhập tên cho sản phẩm mới.");
                    ViewBag.ListSanPhamCu = new SelectList(db.SanPham, "TenSanPham", "TenSanPham");
                    return View();
                }
                tenChinh = "[SP MỚI] " + tenSanPhamMoi; // Đánh dấu để QLSP dễ biết

                // Gộp thông tin dành cho SP mới
                moTaGop += $"=== THÔNG TIN SẢN PHẨM MỚI ===\n" +
                           $"- Thương hiệu: {thuongHieu ?? "Chưa rõ"}\n" +
                           $"- Danh mục: {danhMuc ?? "Chưa rõ"}\n";
            }
            else
            {
                // TRƯỜNG HỢP 2: THÊM BIẾN THỂ CHO SP CŨ
                if (string.IsNullOrEmpty(tenSanPhamCu))
                {
                    ModelState.AddModelError("", "Vui lòng chọn sản phẩm cũ.");
                    ViewBag.ListSanPhamCu = new SelectList(db.SanPham, "TenSanPham", "TenSanPham");
                    return View();
                }
                tenChinh = "[THÊM BIẾN THỂ] " + tenSanPhamCu;
                moTaGop += $"=== DỰA TRÊN SẢN PHẨM CŨ ===\n- Tên gốc: {tenSanPhamCu}\n";
            }

            // 2. Gộp thông tin chi tiết (Giống nhau cả 2 trường hợp)
            moTaGop += $"\n=== CHI TIẾT NHẬP ===\n" +
                       $"- Màu sắc: {mauSac ?? "Không rõ"}\n" +
                       $"- Kích thước: {kichThuoc ?? "Freesize"}\n" +
                       $"- Giá nhập dự kiến: {(giaNhap.HasValue ? giaNhap.Value.ToString("N0") : "0")} đ\n" +
                       $"- Số lượng cần nhập: {(soLuong.HasValue ? soLuong.ToString() : "0")}\n" +
                       $"- Ghi chú: {ghiChu}";

            // 3. Lưu vào Database
            var yeuCau = new YeuCauThemSanPham();
            yeuCau.TenSanPhamYeuCau = tenChinh;
            yeuCau.MoTaChiTiet = moTaGop;

            var user = Session["TaiKhoan"] as NguoiDung;
            yeuCau.MaNguoiYeuCau = user.MaNguoiDung;
            yeuCau.NgayYeuCau = DateTime.Now;
            yeuCau.TrangThai = "ChoXuLy";

            db.YeuCauThemSanPham.Add(yeuCau);
            db.SaveChanges();

            TempData["ThongBao"] = "Đã gửi yêu cầu thành công!";
            return RedirectToAction("Create");
        }
    }
}