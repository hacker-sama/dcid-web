import React from "react";
import { Card, CardContent } from "@/components/ui/card";
import { LucideIcon } from "lucide-react";
import { cn } from "@/lib/utils";

interface KpiCardProps {
  title: string;
  value: string | number;
  icon: LucideIcon;
  trend?: number;
  trendLabel?: string;
  className?: string;
}

export function KpiCard({ title, value, icon: Icon, trend, trendLabel, className }: KpiCardProps) {
  return (
    <Card className={className}>
      <CardContent className="p-6">
        <div className="flex items-center justify-between space-y-0 pb-2">
          <p className="text-sm font-medium tracking-tight text-muted-foreground">
            {title}
          </p>
          <div className="p-2 bg-primary/10 rounded-full">
            <Icon className="h-4 w-4 text-primary" />
          </div>
        </div>
        <div className="flex flex-col gap-1">
          <div className="text-2xl font-bold">{value}</div>
          {trend !== undefined && (
            <p className="text-xs text-muted-foreground flex items-center gap-1">
              <span className={cn(
                "font-medium",
                trend > 0 ? "text-success" : trend < 0 ? "text-danger" : "text-muted-foreground"
              )}>
                {trend > 0 ? "+" : ""}{trend}%
              </span>
              <span>so với {trendLabel || "tháng trước"}</span>
            </p>
          )}
        </div>
      </CardContent>
    </Card>
  );
}
