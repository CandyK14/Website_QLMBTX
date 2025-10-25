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
    public class HomeController : Controller
    {
        QL_TuiXachEntities db = new QL_TuiXachEntities();
        public ActionResult Index(string searchString)
        {
            var dsSP = db.SanPham
                         .Include(sp => sp.ThuongHieu)
                         .Include(sp => sp.BienTheSanPham)
                         .Where(sp => sp.BienTheSanPham.Any());


            if (!String.IsNullOrEmpty(searchString))
            {
                dsSP = dsSP.Where(sp =>
                    sp.TenSanPham.Contains(searchString) ||
                    sp.ThuongHieu.TenThuongHieu.Contains(searchString)
                );

                ViewBag.CurrentSearch = searchString;
            }



            // 6. Lấy dữ liệu cho các ô lọc (dropdown) và gửi ra View
            ViewBag.Brands = db.ThuongHieu.ToList();
            ViewBag.Colors = db.BienTheSanPham.Select(bt => bt.MauSac).Where(m => m != null).Distinct().ToList();
            ViewBag.Materials = db.SanPham.Select(sp => sp.ChatLieuChinh).Where(m => m != null).Distinct().ToList();
            ViewBag.Occasions = db.SanPham.Select(sp => sp.DipSuDung).Where(m => m != null).Distinct().ToList();
            ViewBag.Collections = db.SanPham.Select(sp => sp.BoSuuTap).Where(m => m != null).Distinct().ToList();



            return View(dsSP.ToList());
        }

        public ActionResult Detail(int id)
        {
            
            var sanPham = db.SanPham
                            .Include(sp => sp.ThuongHieu)
                            .Include(sp => sp.DanhMuc)
                            .Include(sp => sp.BienTheSanPham) 
                            .FirstOrDefault(sp => sp.MaSanPham == id);

            if (sanPham == null)
            {
                return HttpNotFound();
            }

            return View(sanPham);
        }

        [HttpGet]
        public ActionResult Filter(
        int? brand,
        string color,
        string material,
        string occasion,
        string collection,
        decimal? minPrice, decimal? maxPrice,
        decimal? minLength, decimal? maxLength,
        decimal? minWidth, decimal? maxWidth,
        decimal? minHeight, decimal? maxHeight,
        int? minWeight, int? maxWeight
)
        {
            // 1. Bắt đầu câu truy vấn (giống hệt Index)
            var dsSP = db.SanPham
                         .Include(sp => sp.ThuongHieu)
                         .Include(sp => sp.BienTheSanPham)
                         .Where(sp => sp.BienTheSanPham.Any());

            

            // 3. Áp dụng TẤT CẢ CÁC BỘ LỌC (nếu có)
            if (brand.HasValue && brand.Value != 0)
            {
                dsSP = dsSP.Where(sp => sp.MaThuongHieu == brand.Value);
            }
            if (!String.IsNullOrEmpty(color))
            {
                dsSP = dsSP.Where(sp => sp.BienTheSanPham.Any(bt => bt.MauSac == color));
            }
            // (Đã xóa code lặp lại)
            if (minPrice.HasValue)
            {
                dsSP = dsSP.Where(sp => sp.BienTheSanPham.Any(bt => bt.GiaBan >= minPrice.Value));
            }
            if (maxPrice.HasValue)
            {
                dsSP = dsSP.Where(sp => sp.BienTheSanPham.Any(bt => bt.GiaBan <= maxPrice.Value));
            }
            if (!String.IsNullOrEmpty(material))
            {
                dsSP = dsSP.Where(sp => sp.ChatLieuChinh == material);
            }
            if (!String.IsNullOrEmpty(occasion))
            {
                dsSP = dsSP.Where(sp => sp.DipSuDung == occasion);
            }
            if (!String.IsNullOrEmpty(collection))
            {
                dsSP = dsSP.Where(sp => sp.BoSuuTap == collection);
            }

            // SỬA LẠI: Dùng .HasValue và .Value cho Kích thước
            if (minLength.HasValue) { dsSP = dsSP.Where(sp => sp.BienTheSanPham.Any(bt => bt.ChieuDaiCM >= minLength.Value)); }
            if (maxLength.HasValue) { dsSP = dsSP.Where(sp => sp.BienTheSanPham.Any(bt => bt.ChieuDaiCM <= maxLength.Value)); }
            if (minWidth.HasValue) { dsSP = dsSP.Where(sp => sp.BienTheSanPham.Any(bt => bt.ChieuRongCM >= minWidth.Value)); }
            if (maxWidth.HasValue) { dsSP = dsSP.Where(sp => sp.BienTheSanPham.Any(bt => bt.ChieuRongCM <= maxWidth.Value)); }
            if (minHeight.HasValue) { dsSP = dsSP.Where(sp => sp.BienTheSanPham.Any(bt => bt.ChieuCaoCM >= minHeight.Value)); }
            if (maxHeight.HasValue) { dsSP = dsSP.Where(sp => sp.BienTheSanPham.Any(bt => bt.ChieuCaoCM <= maxHeight.Value)); }

            // SỬA LẠI: Dùng .HasValue và .Value cho Cân nặng
            if (minWeight.HasValue) { dsSP = dsSP.Where(sp => sp.BienTheSanPham.Any(bt => bt.CanNangGram >= minWeight.Value)); }
            if (maxWeight.HasValue) { dsSP = dsSP.Where(sp => sp.BienTheSanPham.Any(bt => bt.CanNangGram <= maxWeight.Value)); }


            // 4. Lấy dữ liệu cho các ô lọc (dropdown)
            ViewBag.Brands = db.ThuongHieu.ToList();
            ViewBag.Colors = db.BienTheSanPham.Select(bt => bt.MauSac).Where(m => m != null).Distinct().ToList();
            ViewBag.Materials = db.SanPham.Select(sp => sp.ChatLieuChinh).Where(m => m != null).Distinct().ToList();
            ViewBag.Occasions = db.SanPham.Select(sp => sp.DipSuDung).Where(m => m != null).Distinct().ToList();
            ViewBag.Collections = db.SanPham.Select(sp => sp.BoSuuTap).Where(m => m != null).Distinct().ToList();

            // 5. Gửi các lựa chọn cũ ra View (để giữ lại trên form)
            ViewBag.CurrentBrand = brand;
            ViewBag.CurrentColor = color;
            ViewBag.CurrentMaterial = material;
            ViewBag.CurrentOccasion = occasion;
            ViewBag.CurrentCollection = collection;
            ViewBag.CurrentMinPrice = minPrice;
            ViewBag.CurrentMaxPrice = maxPrice;
            ViewBag.CurrentMinLength = minLength;
            ViewBag.CurrentMaxLength = maxLength;
            ViewBag.CurrentMinWidth = minWidth;
            ViewBag.CurrentMaxWidth = maxWidth;
            ViewBag.CurrentMinHeight = minHeight;
            ViewBag.CurrentMaxHeight = maxHeight;
            ViewBag.CurrentMinWeight = minWeight;
            ViewBag.CurrentMaxWeight = maxWeight;

            return View("Index", dsSP.ToList());
        }
    }
}