import React from "react";
import { PageHeader } from "@/components/shared/PageHeader";
import { EmptyState } from "@/components/shared/EmptyState";
import { Calendar } from "lucide-react";

export default function AppointmentsPage() {
  return (
    <div className="space-y-6">
      <PageHeader 
        title="Lịch hẹn" 
        breadcrumbs={[
          { label: "Tổng quan", href: "/citizen/dashboard" },
          { label: "Lịch hẹn" }
        ]}
      />
      <div className="bg-card border rounded-lg py-16">
        <EmptyState 
          icon={Calendar} 
          title="Work in progress" 
          description="Tính năng đặt lịch hẹn đang được phát triển. Vui lòng quay lại sau." 
        />
      </div>
    </div>
  );
}
