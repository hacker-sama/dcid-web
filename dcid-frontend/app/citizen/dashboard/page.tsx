"use client";

import React from "react";
import { PageHeader } from "@/components/shared/PageHeader";
import { StatCard } from "@/components/citizen/StatCard";
import { ApplicationListItem } from "@/components/citizen/ApplicationListItem";
import { useApplications } from "@/hooks/useApplications";
import { FileText, CheckCircle2, Clock, AlertCircle } from "lucide-react";
import { Button } from "@/components/ui/button";
import Link from "next/link";
import { ROUTES } from "@/constants/routes";
import { ApplicationStatus } from "@/types/application";
import { LoadingList } from "@/components/shared/LoadingSkeleton";
import { EmptyState } from "@/components/shared/EmptyState";

export default function CitizenDashboardPage() {
  const { data: appsData, isLoading } = useApplications({ size: 5, sort: "createdAt,desc" });
  
  // In a real app, these stats would come from an API
  const stats = [
    { title: "Hồ sơ đã nộp", value: 12, icon: FileText, colorClass: "text-primary" },
    { title: "Đang xử lý", value: 3, icon: Clock, colorClass: "text-warning" },
    { title: "Cần bổ sung", value: 1, icon: AlertCircle, colorClass: "text-danger" },
    { title: "Đã hoàn thành", value: 8, icon: CheckCircle2, colorClass: "text-success" },
  ];

  const recentApps = appsData?.content || [];

  return (
    <div className="space-y-8">
      <PageHeader title="Tổng quan" />

      <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
        {stats.map((stat) => (
          <StatCard key={stat.title} {...stat} />
        ))}
      </div>

      <div className="space-y-4">
        <div className="flex items-center justify-between">
          <h2 className="text-xl font-bold">Hồ sơ gần đây</h2>
          <Link href={ROUTES.CITIZEN.APPLICATIONS}>
            <Button variant="link" type="button">Xem tất cả</Button>
          </Link>
        </div>

        {isLoading ? (
          <LoadingList />
        ) : recentApps.length > 0 ? (
          <div className="space-y-4">
            {recentApps.map((app) => (
              <ApplicationListItem key={app.id} application={app} />
            ))}
          </div>
        ) : (
          <div className="bg-card border rounded-lg">
            <EmptyState 
              icon={FileText} 
              title="Chưa có hồ sơ nào" 
              description="Bạn chưa nộp hồ sơ thủ tục hành chính nào. Bấm vào nút bên dưới để bắt đầu."
              action={
                <Link href={ROUTES.CITIZEN.PROCEDURES}>
                  <Button type="button">Nộp hồ sơ mới</Button>
                </Link>
              }
            />
          </div>
        )}
      </div>
    </div>
  );
}
