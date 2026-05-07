import React from "react";
import { PageHeader } from "@/components/shared/PageHeader";
import { EmptyState } from "@/components/shared/EmptyState";
import { BarChart } from "lucide-react";

export default function OfficerReportsPage() {
  return (
    <div className="space-y-6">
      <PageHeader 
        title="Báo cáo thống kê" 
        breadcrumbs={[
          { label: "Tổng quan", href: "/officer/dashboard" },
          { label: "Báo cáo thống kê" }
        ]}
      />
      <div className="bg-card border rounded-lg py-16">
        <EmptyState 
          icon={BarChart} 
          title="Work in progress" 
          description="Tính năng xuất báo cáo và biểu đồ chuyên sâu đang được phát triển." 
        />
      </div>
    </div>
  );
}
