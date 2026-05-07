import React from "react";
import { PageHeader } from "@/components/shared/PageHeader";
import { EmptyState } from "@/components/shared/EmptyState";
import { Users } from "lucide-react";

export default function OfficerUsersPage() {
  return (
    <div className="space-y-6">
      <PageHeader 
        title="Quản lý người dùng" 
        breadcrumbs={[
          { label: "Tổng quan", href: "/officer/dashboard" },
          { label: "Quản lý người dùng" }
        ]}
      />
      <div className="bg-card border rounded-lg py-16">
        <EmptyState 
          icon={Users} 
          title="Work in progress" 
          description="Tính năng phân quyền và quản lý tài khoản người dùng đang được phát triển." 
        />
      </div>
    </div>
  );
}
