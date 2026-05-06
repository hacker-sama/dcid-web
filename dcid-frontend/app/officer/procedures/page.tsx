import React from "react";
import { PageHeader } from "@/components/shared/PageHeader";
import { EmptyState } from "@/components/shared/EmptyState";
import { FileSearch } from "lucide-react";

export default function OfficerProceduresPage() {
  return (
    <div className="space-y-6">
      <PageHeader 
        title="Quản lý thủ tục" 
        breadcrumbs={[
          { label: "Tổng quan", href: "/officer/dashboard" },
          { label: "Quản lý thủ tục" }
        ]}
      />
      <div className="bg-card border rounded-lg py-16">
        <EmptyState 
          icon={FileSearch} 
          title="Work in progress" 
          description="Tính năng quản lý danh mục thủ tục hành chính đang được phát triển." 
        />
      </div>
    </div>
  );
}
