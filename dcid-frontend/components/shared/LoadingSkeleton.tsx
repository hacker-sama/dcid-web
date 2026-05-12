import React from "react";
import { cn } from "@/lib/utils";

interface LoadingSkeletonProps {
  rows?: number;
  className?: string;
}

export function LoadingSkeleton({ rows = 3, className }: LoadingSkeletonProps) {
  return (
    <div className={cn("space-y-2", className)}>
      {Array.from({ length: rows }).map((_, index) => (
        <div
          key={index}
          className="h-5 w-full animate-pulse rounded-lg bg-gray-200 dark:bg-slate-700"
        />
      ))}
    </div>
  );
}

export function LoadingCard() {
  return (
    <div className="space-y-4 rounded-2xl border border-border bg-background p-4 shadow-sm">
      <div className="flex items-center justify-between gap-4">
        <div className="h-4 w-1/3 animate-pulse rounded-md bg-gray-200 dark:bg-slate-700" />
        <div className="h-8 w-8 animate-pulse rounded-full bg-gray-200 dark:bg-slate-700" />
      </div>
      <div className="space-y-2">
        <div className="h-4 w-2/3 animate-pulse rounded-md bg-gray-200 dark:bg-slate-700" />
        <div className="h-3 w-1/2 animate-pulse rounded-md bg-gray-200 dark:bg-slate-700" />
      </div>
    </div>
  );
}

export function LoadingList() {
  return (
    <div className="space-y-4">
      {Array.from({ length: 5 }).map((_, i) => (
        <div key={i} className="flex items-center gap-4 rounded-2xl border border-border bg-background p-4 shadow-sm">
          <div className="h-12 w-12 animate-pulse rounded-full bg-gray-200 dark:bg-slate-700" />
          <div className="flex-1 space-y-2">
            <div className="h-4 w-1/3 animate-pulse rounded-md bg-gray-200 dark:bg-slate-700" />
            <div className="h-3 w-1/4 animate-pulse rounded-md bg-gray-200 dark:bg-slate-700" />
          </div>
          <div className="h-8 w-20 animate-pulse rounded-lg bg-gray-200 dark:bg-slate-700" />
        </div>
      ))}
    </div>
  );
}

export function LoadingForm() {
  return (
    <div className="space-y-6">
      {Array.from({ length: 4 }).map((_, i) => (
        <div key={i} className="space-y-2">
          <div className="h-4 w-32 animate-pulse rounded-md bg-gray-200 dark:bg-slate-700" />
          <div className="h-10 w-full animate-pulse rounded-lg bg-gray-200 dark:bg-slate-700" />
        </div>
      ))}
    </div>
  );
}
