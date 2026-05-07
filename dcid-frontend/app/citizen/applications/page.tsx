"use client";

import React, { useState } from "react";
import { PageHeader } from "@/components/shared/PageHeader";
import { DataTable } from "@/components/shared/DataTable";
import { useApplications } from "@/hooks/useApplications";
import { ApplicationDTO, ApplicationStatus } from "@/types/application";
import { StatusBadge } from "@/components/shared/StatusBadge";
import { formatDate } from "@/lib/utils";
import { useRouter } from "next/navigation";
import { ROUTES } from "@/constants/routes";
import { 
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue, 
} from "@/components/ui/select";

export default function ApplicationsPage() {
  const router = useRouter();
  const [statusFilter, setStatusFilter] = useState<string>("ALL");
  
  const filters = statusFilter !== "ALL" ? { status: statusFilter } : {};
  const { data: appsData, isLoading } = useApplications(filters);

  const columns: import("@/components/shared/DataTable").ColumnDef<ApplicationDTO>[] = [
    {
      header: "Mã hồ sơ",
      accessorKey: "applicationCode",
      className: "font-medium text-primary",
    },
    {
      header: "Tên thủ tục",
      accessorKey: "procedureName",
      className: "max-w-[200px] sm:max-w-[300px]",
      cell: (item: ApplicationDTO) => (
        <div className="truncate" title={item.procedureName}>{item.procedureName}</div>
      ),
    },
    {
      header: "Ngày nộp",
      accessorKey: "submittedAt",
      cell: (item: ApplicationDTO) => formatDate(item.submittedAt || item.createdAt, "dd/MM/yyyy"),
    },
    {
      header: "Trạng thái",
      accessorKey: "status",
      cell: (item: ApplicationDTO) => <StatusBadge status={item.status} />,
    },
  ];

  return (
    <div className="space-y-6">
      <PageHeader 
        title="Hồ sơ của tôi" 
        breadcrumbs={[
          { label: "Tổng quan", href: "/citizen/dashboard" },
          { label: "Hồ sơ của tôi" }
        ]}
      />

      <div className="flex flex-col sm:flex-row gap-4 mb-6">
        <div className="w-full sm:w-64">
          <Select value={statusFilter} onValueChange={(val) => setStatusFilter(val || "ALL")}>
            <SelectTrigger>
              <SelectValue placeholder="Lọc theo trạng thái" />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="ALL">Tất cả trạng thái</SelectItem>
              {Object.keys(ApplicationStatus).map((status) => (
                <SelectItem key={status} value={status}>
                  {status === "DRAFT" ? "Nháp" :
                   status === "SUBMITTED" ? "Đã nộp" :
                   status === "IN_REVIEW" ? "Đang xử lý" :
                   status === "PENDING_SUPPLEMENT" ? "Yêu cầu bổ sung" :
                   status === "APPROVED" ? "Đã duyệt" :
                   status === "REJECTED" ? "Từ chối" : "Đã rút"}
                </SelectItem>
              ))}
            </SelectContent>
          </Select>
        </div>
      </div>

      <DataTable 
        columns={columns} 
        data={appsData?.content || []} 
        isLoading={isLoading} 
        onRowClick={(item) => router.push(ROUTES.CITIZEN.APPLICATION_DETAIL(item.id))}
        emptyTitle="Chưa có hồ sơ nào"
        emptyDescription={statusFilter === "ALL" ? "Bạn chưa tạo hoặc nộp hồ sơ nào." : "Không có hồ sơ nào phù hợp với bộ lọc."}
      />
    </div>
  );
}
