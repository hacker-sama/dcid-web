"use client";

import React from "react";
import { PageHeader } from "@/components/shared/PageHeader";
import { KpiCard } from "@/components/officer/KpiCard";
import { StatusBarChart } from "@/components/officer/charts/StatusBarChart";
import { SubmissionLineChart } from "@/components/officer/charts/SubmissionLineChart";
import { useOfficerStats, useOfficerChartData } from "@/hooks/useOfficerDashboard";
import { FileText, Clock, CheckCircle2, AlertTriangle } from "lucide-react";
import { Skeleton } from "@/components/ui/skeleton";

export default function OfficerDashboardPage() {
  const { data: stats, isLoading: isStatsLoading } = useOfficerStats();
  const { data: chartData, isLoading: isChartLoading } = useOfficerChartData();

  return (
    <div className="space-y-6">
      <PageHeader title="Tổng quan KPI" />

      {isStatsLoading ? (
        <div className="grid gap-4 md:grid-cols-2 xl:grid-cols-4">
          {Array.from({ length: 4 }).map((_, i) => (
            <Skeleton key={i} className="h-[120px] rounded-xl" />
          ))}
        </div>
      ) : stats ? (
        <div className="grid gap-4 md:grid-cols-2 xl:grid-cols-4">
          <KpiCard 
            title="Tổng hồ sơ" 
            value={stats.totalApplications} 
            icon={FileText} 
            trend={12.5} 
          />
          <KpiCard 
            title="Đang chờ xử lý" 
            value={stats.pendingReview} 
            icon={Clock} 
            trend={-5.2} 
            className="border-warning/50 bg-warning/5"
          />
          <KpiCard 
            title="Đã duyệt (Hôm nay)" 
            value={stats.approvedToday} 
            icon={CheckCircle2} 
            trend={8.1} 
            trendLabel="so với hôm qua"
            className="border-success/50 bg-success/5"
          />
          <KpiCard 
            title="Bị từ chối (Hôm nay)" 
            value={stats.rejectedToday} 
            icon={AlertTriangle} 
            trend={-2.4} 
            trendLabel="so với hôm qua"
            className="border-danger/50 bg-danger/5"
          />
        </div>
      ) : null}

      <div className="grid gap-6 grid-cols-1 lg:grid-cols-3">
        {isChartLoading ? (
          <>
            <Skeleton className="col-span-1 lg:col-span-2 h-[400px] rounded-xl" />
            <Skeleton className="col-span-1 h-[400px] rounded-xl" />
          </>
        ) : chartData ? (
          <>
            <SubmissionLineChart data={chartData.submissionData} />
            <StatusBarChart data={chartData.statusData} />
          </>
        ) : null}
      </div>
    </div>
  );
}
