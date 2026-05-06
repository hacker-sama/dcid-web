"use client";

import React from "react";
import Link from "next/link";
import { usePathname } from "next/navigation";
import { useSession, signOut } from "next-auth/react";
import { ROUTES } from "@/constants/routes";
import { NotificationBell } from "@/components/shared/NotificationBell";
import { useUnreadNotificationCount } from "@/hooks/useNotifications";
import { cn } from "@/lib/utils";
import {
  LayoutDashboard,
  FileText,
  FileSearch,
  Calendar,
  Bell,
  LogOut,
  Menu,
  Shield
} from "lucide-react";
import { Button } from "@/components/ui/button";
import { Sheet, SheetContent, SheetTrigger } from "@/components/ui/sheet";

const NAV_ITEMS = [
  { name: "Tổng quan", href: ROUTES.CITIZEN.DASHBOARD, icon: LayoutDashboard },
  { name: "Thủ tục hành chính", href: ROUTES.CITIZEN.PROCEDURES, icon: FileSearch },
  { name: "Hồ sơ của tôi", href: ROUTES.CITIZEN.APPLICATIONS, icon: FileText },
  { name: "Lịch hẹn", href: ROUTES.CITIZEN.APPOINTMENTS, icon: Calendar },
  { name: "Thông báo", href: ROUTES.CITIZEN.NOTIFICATIONS, icon: Bell },
];

export default function CitizenLayout({ children }: { children: React.ReactNode }) {
  const pathname = usePathname();
  const { data: session } = useSession();
  const { data: unreadCount } = useUnreadNotificationCount();

  const handleLogout = () => signOut({ callbackUrl: ROUTES.LOGIN });

  const NavLinks = () => (
    <nav className="space-y-1 mt-8">
      {NAV_ITEMS.map((item) => {
        const isActive = pathname.startsWith(item.href);
        return (
          <Link
            key={item.name}
            href={item.href}
            className={cn(
              "flex items-center gap-3 px-4 py-3 rounded-md transition-colors text-sm font-medium",
              isActive
                ? "bg-primary text-primary-foreground"
                : "text-muted-foreground hover:bg-muted hover:text-foreground"
            )}
          >
            <item.icon className="h-5 w-5" />
            {item.name}
          </Link>
        );
      })}
    </nav>
  );

  return (
    <div className="min-h-screen bg-muted/20 flex flex-col md:flex-row">
      {/* Sidebar for Desktop */}
      <aside className="hidden md:flex flex-col w-64 border-r bg-card h-screen sticky top-0">
        <div className="p-6 border-b">
          <Link href={ROUTES.CITIZEN.DASHBOARD} className="flex items-center gap-2 text-primary">
            <Shield className="h-8 w-8" />
            <span className="font-bold text-xl tracking-tight">DCID</span>
          </Link>
        </div>
        <div className="flex-1 overflow-y-auto px-4">
          <NavLinks />
        </div>
        <div className="p-4 border-t">
          <div className="flex items-center gap-3 px-4 py-3 mb-2 rounded-md bg-muted/50">
            <div className="h-8 w-8 rounded-full bg-primary/20 flex items-center justify-center text-primary font-bold">
              {session?.user?.name?.charAt(0) || "U"}
            </div>
            <div className="overflow-hidden">
              <p className="text-sm font-medium truncate">{session?.user?.name}</p>
              <p className="text-xs text-muted-foreground truncate">{session?.user?.email}</p>
            </div>
          </div>
          <Button variant="ghost" className="w-full justify-start text-danger hover:text-danger hover:bg-danger/10" onClick={handleLogout}>
            <LogOut className="h-4 w-4 mr-2" />
            Đăng xuất
          </Button>
        </div>
      </aside>

      {/* Main Content */}
      <main className="flex-1 flex flex-col min-h-0">
        {/* Mobile Header */}
        <header className="md:hidden flex items-center justify-between p-4 border-b bg-card sticky top-0 z-10">
          <div className="flex items-center gap-2">
            <Sheet>
              <SheetTrigger className="inline-flex h-9 w-9 shrink-0 items-center justify-center rounded-lg border border-transparent bg-transparent hover:bg-muted hover:text-foreground text-sm font-medium transition-colors">
                <Menu className="h-5 w-5" />
              </SheetTrigger>
              <SheetContent side="left" className="w-64 p-0">
                <div className="p-6 border-b">
                  <Link href={ROUTES.CITIZEN.DASHBOARD} className="flex items-center gap-2 text-primary">
                    <Shield className="h-8 w-8" />
                    <span className="font-bold text-xl tracking-tight">DCID</span>
                  </Link>
                </div>
                <div className="px-4">
                  <NavLinks />
                </div>
                <div className="absolute bottom-0 w-full p-4 border-t bg-card">
                  <Button variant="ghost" className="w-full justify-start text-danger" onClick={handleLogout}>
                    <LogOut className="h-4 w-4 mr-2" />
                    Đăng xuất
                  </Button>
                </div>
              </SheetContent>
            </Sheet>
            <Shield className="h-6 w-6 text-primary" />
          </div>
          <NotificationBell unreadCount={unreadCount} />
        </header>

        {/* Desktop Header */}
        <header className="hidden md:flex items-center justify-end p-4 bg-transparent">
          <NotificationBell unreadCount={unreadCount} />
        </header>

        <div className="flex-1 p-4 md:p-8 overflow-y-auto max-w-7xl mx-auto w-full">
          {children}
        </div>
      </main>
    </div>
  );
}
