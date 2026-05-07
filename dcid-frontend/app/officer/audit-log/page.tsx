import React from "react";
import { PageHeader } from "@/components/shared/PageHeader";
import { EmptyState } from "@/components/shared/EmptyState";
import { History } from "lucide-react";

export default function OfficerAuditLogPage() {
  return (
    <div className="space-y-6">
      <PageHeader 
        title="Nhật ký hệ thống" 
        breadcrumbs={[
          { label: "Tổng quan", href: "/officer/dashboard" },
          { label: "Nhật ký hệ thống" }
        ]}
      />
      <div className="bg-card border rounded-lg py-16">
        <EmptyState 
          icon={History} 
          title="Work in progress" 
          description="Tính năng theo dõi thao tác và vết hệ thống đang được phát triển." 
        />
      </div>
    </div>
  );
}
