import { cn } from "@/lib/utils";

interface WebSocketIndicatorProps {
  isConnected: boolean;
  className?: string;
}

export function WebSocketIndicator({ isConnected, className }: WebSocketIndicatorProps) {
  return (
    <div
      className={cn("flex items-center gap-2", className)}
      title={isConnected ? "Đang kết nối realtime" : "Mất kết nối realtime"}
      aria-label={isConnected ? "Đang kết nối realtime" : "Mất kết nối realtime"}
    >
      <div className="relative flex h-2.5 w-2.5">
        {isConnected && (
          <span className="absolute inline-flex h-full w-full rounded-full bg-emerald-500 opacity-75 animate-ping" />
        )}
        <span
          className={cn(
            "relative inline-flex h-2.5 w-2.5 rounded-full",
            isConnected ? "bg-emerald-500" : "bg-slate-400"
          )}
        />
      </div>
      <span className="text-xs text-muted-foreground">
        {isConnected ? "Đang kết nối realtime" : "Mất kết nối realtime"}
      </span>
    </div>
  );
}
