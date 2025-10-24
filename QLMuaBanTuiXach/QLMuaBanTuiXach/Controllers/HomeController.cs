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
        QL_TuiXachEntities1 db = new QL_TuiXachEntities1();
        public ActionResult Index(string searchString)
        {
            var dsSP = db.SanPham
                         .Include(sp => sp.ThuongHieu)
                         .Include(sp => sp.BienTheSanPham); 

            
            if (!String.IsNullOrEmpty(searchString))
            {
                dsSP = dsSP.Where(sp =>
                    sp.TenSanPham.Contains(searchString) ||
                    sp.ThuongHieu.TenThuongHieu.Contains(searchString)
                );

                ViewBag.CurrentSearch = searchString;
            }

            dsSP = dsSP.Where(sp => sp.BienTheSanPham.Any()); 

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
    }
}