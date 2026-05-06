import React from "react";
import { cn } from "@/lib/utils";

interface WebSocketIndicatorProps {
  isConnected: boolean;
  className?: string;
}

export function WebSocketIndicator({ isConnected, className }: WebSocketIndicatorProps) {
  return (
    <div className={cn("flex items-center gap-2", className)} title={isConnected ? "Đã kết nối trực tiếp" : "Đang kết nối lại..."}>
      <div className="relative flex h-3 w-3">
        {isConnected && (
          <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-success opacity-75"></span>
        )}
        <span className={cn(
          "relative inline-flex rounded-full h-3 w-3",
          isConnected ? "bg-success" : "bg-warning"
        )}></span>
      </div>
      <span className="text-xs text-muted-foreground hidden sm:inline-block">
        {isConnected ? "Trực tiếp" : "Mất kết nối"}
      </span>
    </div>
  );
}
