"use client";

import Link from "next/link";
import { Bell, Inbox } from "lucide-react";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuLabel,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import { ROUTES } from "@/constants/routes";
import { EmptyState } from "./EmptyState";
import { useNotifications } from "@/hooks/useNotifications";
import { formatDate } from "@/lib/utils";

interface NotificationBellProps {
  unreadCount?: number;
}

export function NotificationBell({ unreadCount: externalUnreadCount }: NotificationBellProps) {
  const { data: notifications = [], isLoading, isError } = useNotifications();
  const unreadCount = externalUnreadCount ?? notifications.filter((notification) => !notification.read).length;
  const latestNotifications = notifications
    .slice()
    .sort((a, b) => new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime())
    .slice(0, 5);

  return (
    <DropdownMenu>
      <DropdownMenuTrigger className="relative inline-flex h-9 w-9 shrink-0 items-center justify-center rounded-lg border border-transparent bg-transparent hover:bg-muted hover:text-foreground text-sm font-medium transition-colors">
        <Bell className="h-5 w-5" />
        {unreadCount > 0 && (
          <span className="absolute right-0 top-0 flex h-4 min-w-[1rem] items-center justify-center rounded-full bg-destructive px-1 text-[10px] font-semibold text-white">
            {unreadCount > 99 ? "99+" : unreadCount}
          </span>
        )}
      </DropdownMenuTrigger>
      <DropdownMenuContent align="end" className="w-96 p-0">
        <div className="rounded-t-xl bg-background p-4">
          <div className="flex items-center gap-2 text-sm font-semibold text-foreground">
            <Inbox className="h-4 w-4 text-primary" />
            Thông báo
          </div>
          <p className="mt-1 text-xs text-muted-foreground">
            {unreadCount} thông báo chưa đọc
          </p>
        </div>
        <DropdownMenuSeparator />
        <div className="max-h-80 overflow-y-auto bg-background">
          {isLoading ? (
            <div className="p-4 text-sm text-muted-foreground">Đang tải thông báo...</div>
          ) : isError ? (
            <div className="p-4 text-sm text-destructive">Không thể tải thông báo.</div>
          ) : latestNotifications.length === 0 ? (
            <div className="p-6">
              <EmptyState message="Không có thông báo mới" description="Bạn sẽ nhận được thông báo khi có cập nhật." />
            </div>
          ) : (
            latestNotifications.map((notification) => (
              <DropdownMenuItem
                key={notification.id}
                className="flex flex-col gap-1 px-4 py-3 text-left"
              >
                <div className="flex items-center justify-between gap-3">
                  <p className={notification.read ? "text-sm text-muted-foreground" : "text-sm font-semibold text-foreground"}>
                    {notification.title}
                  </p>
                  <time className="text-[11px] text-muted-foreground">
                    {formatDate(notification.createdAt, "HH:mm, dd/MM/yyyy")}
                  </time>
                </div>
                <p className="line-clamp-1 text-sm text-muted-foreground">{notification.message}</p>
              </DropdownMenuItem>
            ))
          )}
        </div>
        <DropdownMenuSeparator />
        <div className="rounded-b-xl bg-background p-3 text-center">
          <Link href={ROUTES.CITIZEN.NOTIFICATIONS} className="text-sm font-semibold text-primary hover:text-primary/80">
            Xem tất cả
          </Link>
        </div>
      </DropdownMenuContent>
    </DropdownMenu>
  );
}
