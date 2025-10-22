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
        public ActionResult Index()
        {
            List<SanPham> dsSP = db.SanPham
                                   .Include(sp => sp.ThuongHieu)
                                   .Include(sp => sp.BienTheSanPham)
                                   .Where(sp => sp.BienTheSanPham.Any())
                                   .ToList();
            return View(dsSP);
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