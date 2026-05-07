import React from "react";
import { Bell } from "lucide-react";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuLabel,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import { Button } from "@/components/ui/button";

interface NotificationBellProps {
  unreadCount?: number;
}

export function NotificationBell({ unreadCount = 0 }: NotificationBellProps) {
  return (
    <DropdownMenu>
      <DropdownMenuTrigger className="relative inline-flex h-9 w-9 shrink-0 items-center justify-center rounded-lg border border-transparent bg-transparent hover:bg-muted hover:text-foreground text-sm font-medium transition-colors">
        <Bell className="h-5 w-5" />
        {unreadCount > 0 && (
          <span className="absolute top-1 right-1 flex h-4 w-4 items-center justify-center rounded-full bg-danger text-[10px] text-white">
            {unreadCount > 99 ? "99+" : unreadCount}
          </span>
        )}
      </DropdownMenuTrigger>
      <DropdownMenuContent align="end" className="w-80">
        <DropdownMenuLabel>Thông báo ({unreadCount} chưa đọc)</DropdownMenuLabel>
        <DropdownMenuSeparator />
        <div className="max-h-[300px] overflow-y-auto">
          {/* Mocks */}
          <DropdownMenuItem className="flex flex-col items-start p-3 cursor-pointer">
            <span className="font-medium text-sm">Hồ sơ đã được duyệt</span>
            <span className="text-xs text-muted-foreground mt-1">Hồ sơ Cấp lại CMND của bạn đã được duyệt.</span>
            <span className="text-[10px] text-muted-foreground mt-2">10 phút trước</span>
          </DropdownMenuItem>
          <DropdownMenuSeparator />
          <DropdownMenuItem className="flex flex-col items-start p-3 cursor-pointer">
            <span className="font-medium text-sm">Nhắc nhở lịch hẹn</span>
            <span className="text-xs text-muted-foreground mt-1">Bạn có lịch hẹn vào ngày mai lúc 09:00.</span>
            <span className="text-[10px] text-muted-foreground mt-2">2 giờ trước</span>
          </DropdownMenuItem>
        </div>
        <DropdownMenuSeparator />
        <DropdownMenuItem className="justify-center text-primary text-sm font-medium cursor-pointer">
          Xem tất cả
        </DropdownMenuItem>
      </DropdownMenuContent>
    </DropdownMenu>
  );
}
