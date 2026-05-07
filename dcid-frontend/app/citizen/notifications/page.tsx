import React from "react";
import { PageHeader } from "@/components/shared/PageHeader";
import { EmptyState } from "@/components/shared/EmptyState";
import { Bell } from "lucide-react";

export default function NotificationsPage() {
  return (
    <div className="space-y-6">
      <PageHeader 
        title="Thông báo" 
        breadcrumbs={[
          { label: "Tổng quan", href: "/citizen/dashboard" },
          { label: "Thông báo" }
        ]}
      />
      <div className="bg-card border rounded-lg py-16">
        <EmptyState 
          icon={Bell} 
          title="Work in progress" 
          description="Tính năng quản lý thông báo đang được phát triển. Vui lòng quay lại sau." 
        />
      </div>
    </div>
  );
}
