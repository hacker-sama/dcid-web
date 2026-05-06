import React from "react";
import { Card, CardContent } from "@/components/ui/card";
import { LucideIcon } from "lucide-react";
import { cn } from "@/lib/utils";

interface StatCardProps {
  title: string;
  value: string | number;
  icon: LucideIcon;
  description?: string;
  trend?: "up" | "down" | "neutral";
  trendValue?: string;
  colorClass?: string;
}

export function StatCard({ 
  title, 
  value, 
  icon: Icon, 
  description, 
  trend, 
  trendValue,
  colorClass = "text-primary" 
}: StatCardProps) {
  return (
    <Card>
      <CardContent className="p-6">
        <div className="flex items-center justify-between space-y-0 pb-2">
          <p className="text-sm font-medium tracking-tight text-muted-foreground">
            {title}
          </p>
          <Icon className={cn("h-4 w-4", colorClass)} />
        </div>
        <div className="flex flex-col gap-1">
          <div className="text-2xl font-bold">{value}</div>
          {(description || trendValue) && (
            <p className="text-xs text-muted-foreground flex items-center gap-1">
              {trendValue && (
                <span className={cn(
                  "font-medium",
                  trend === "up" ? "text-success" : trend === "down" ? "text-danger" : "text-muted-foreground"
                )}>
                  {trendValue}
                </span>
              )}
              {description}
            </p>
          )}
        </div>
      </CardContent>
    </Card>
  );
}
