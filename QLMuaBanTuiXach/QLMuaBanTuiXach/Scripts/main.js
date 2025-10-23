document.addEventListener('DOMContentLoaded', function () {
    console.log("[DEBUG] DOM loaded");

    const userIconBtn = document.getElementById('user-icon-btn');

    if (userIconBtn) {
        console.log("[DEBUG] User icon button found, attaching click listener");

        userIconBtn.addEventListener('click', function () {
            console.log("------------------------------");
            console.log("[DEBUG] User icon clicked!");

      
            const authModal = document.getElementById('auth-modal-overlay');
            const userMenuOverlay = document.getElementById('user-menu-overlay');
            const adminMenuOverlay = document.getElementById('admin-menu-overlay'); 

            console.log("[DEBUG] Checking elements on click...");
            console.log("[DEBUG] authModal:", authModal ? 'Exists' : 'NULL');
            console.log("[DEBUG] userMenuOverlay:", userMenuOverlay ? 'Exists' : 'NULL');
            console.log("[DEBUG] adminMenuOverlay:", adminMenuOverlay ? 'Exists' : 'NULL'); 

            
            if (adminMenuOverlay) { 
                console.log("[DEBUG] CONDITION MET: Admin Menu Overlay found, opening...");
                adminMenuOverlay.style.display = 'block';
                const adminMenuSidebar = document.getElementById('admin-menu-sidebar');
                if (adminMenuSidebar) {
                    console.log("[DEBUG] Admin Menu Sidebar found, sliding...");
                    setTimeout(() => { adminMenuSidebar.style.right = '0'; }, 10);
                } else {
                    console.error("[ERROR] Admin Menu Sidebar NOT FOUND on click!");
                }
            } else if (userMenuOverlay) { 
                console.log("[DEBUG] CONDITION MET: User Menu Overlay found, opening...");
                userMenuOverlay.style.display = 'block';
                const userMenuSidebar = document.getElementById('user-menu-sidebar');
                if (userMenuSidebar) {
                    console.log("[DEBUG] User Menu Sidebar found, sliding...");
                    setTimeout(() => { userMenuSidebar.style.right = '0'; }, 10);
                } else {
                    console.error("[ERROR] User Menu Sidebar NOT FOUND on click!");
                }
            } else if (authModal) { 
                console.log("[DEBUG] CONDITION MET: No menus found, Auth Modal found, opening...");
                authModal.style.display = 'flex';
            } else {
                console.error("[ERROR] NEITHER Menu NOR Auth Modal found! Check Layout @if.");
            }
            console.log("------------------------------");
        });

    } else {
        console.error("[ERROR] User icon button (user-icon-btn) not found!");
    }


    const initialAuthModal = document.getElementById('auth-modal-overlay');
    if (initialAuthModal) {
        console.log("[DEBUG] Initial Auth Modal found, attaching close events.");
        const closeModalBtn = initialAuthModal.querySelector('.auth-modal-close');
        if (closeModalBtn) {
            closeModalBtn.addEventListener('click', function () {
                console.log("[DEBUG] Closing Auth Modal via X");
                initialAuthModal.style.display = 'none';
            });
        }
        initialAuthModal.addEventListener('click', function (event) {
            if (event.target === initialAuthModal) {
                console.log("[DEBUG] Closing Auth Modal via overlay click");
                initialAuthModal.style.display = 'none';
            }
        });
    } else {
        console.log("[DEBUG] Initial Auth Modal not found (normal if logged in).");
    }


    const initialUserMenuOverlay = document.getElementById('user-menu-overlay');
    if (initialUserMenuOverlay) {
        console.log("[DEBUG] Initial User Menu Overlay found, attaching close events.");
        const userMenuSidebar = document.getElementById('user-menu-sidebar');
        const userMenuCloseBtn = document.getElementById('user-menu-close');
        if (userMenuSidebar && userMenuCloseBtn) {
            function closeUserMenu() {
                console.log("[DEBUG] Closing User Menu...");
                userMenuSidebar.style.right = '-350px';
                setTimeout(() => {
                    initialUserMenuOverlay.style.display = 'none';
                }, 300);
            }
            userMenuCloseBtn.addEventListener('click', closeUserMenu);
            initialUserMenuOverlay.addEventListener('click', function (event) {
                if (event.target === initialUserMenuOverlay) {
                    closeUserMenu();
                }
            });
        } else {
            console.error("[ERROR] Could not find User Menu Sidebar or Close Button!");
        }
    } else {
        console.log("[DEBUG] Initial User Menu Overlay not found (normal if not user OR not logged in).");
    }

    const initialAdminMenuOverlay = document.getElementById('admin-menu-overlay');
    if (initialAdminMenuOverlay) {
        console.log("[DEBUG] Initial Admin Menu Overlay found, attaching close events.");
        const adminMenuSidebar = document.getElementById('admin-menu-sidebar');
        const adminMenuCloseBtn = document.getElementById('admin-menu-close'); 
        if (adminMenuSidebar && adminMenuCloseBtn) {
            function closeAdminMenu() {
                console.log("[DEBUG] Closing Admin Menu...");
                adminMenuSidebar.style.right = '-350px';
                setTimeout(() => {
                    initialAdminMenuOverlay.style.display = 'none'; 
                }, 300);
            }
            adminMenuCloseBtn.addEventListener('click', closeAdminMenu); 
            initialAdminMenuOverlay.addEventListener('click', function (event) {
                if (event.target === initialAdminMenuOverlay) { 
                    closeAdminMenu();
                }
            });
        } else {
            console.error("[ERROR] Could not find Admin Menu Sidebar or Close Button!");
        }
    } else {
        console.log("[DEBUG] Initial Admin Menu Overlay not found (normal if not admin OR not logged in).");
    }
    const loginLink1 = document.getElementById('login-link-from-register');
    const loginLink2 = document.getElementById('login-link-from-register-2');
    function openLoginModalFromRegister(e) {
        e.preventDefault();
        const currentAuthModal = document.getElementById('auth-modal-overlay');
        if (!currentAuthModal) {
            console.log("[DEBUG] Redirecting to Home to open login modal");
            window.location.href = '/Home/Index?login=true';
        } else {
            console.log("[DEBUG] Opening login modal from register link on same page");
            currentAuthModal.style.display = 'flex';
        }
    }
    if (loginLink1) loginLink1.addEventListener('click', openLoginModalFromRegister);
    if (loginLink2) loginLink2.addEventListener('click', openLoginModalFromRegister);

    // Tự động mở modal nếu có ?login=true trên URL
    const urlParams = new URLSearchParams(window.location.search);
    if (urlParams.has('login') && initialAuthModal) {
        console.log("[DEBUG] Opening Auth Modal due to ?login=true param");
        initialAuthModal.style.display = 'flex';
    }

});

