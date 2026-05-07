"use client";

import React, { useState } from "react";
import { PageHeader } from "@/components/shared/PageHeader";
import { useApplications } from "@/hooks/useApplications";
import { ApplicationStatus } from "@/types/application";
import { ApplicationQueueRow } from "@/components/officer/ApplicationQueueRow";
import { Table, TableBody, TableHead, TableHeader, TableRow, TableCell } from "@/components/ui/table";
import { Skeleton } from "@/components/ui/skeleton";
import { EmptyState } from "@/components/shared/EmptyState";
import { FileSearch } from "lucide-react";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { Input } from "@/components/ui/input";
import { useDebounce } from "use-debounce";

export default function OfficerApplicationsPage() {
  const [statusFilter, setStatusFilter] = useState<string>("ALL");
  const [searchTerm, setSearchTerm] = useState("");
  const [debouncedSearch] = useDebounce(searchTerm, 500);

  const filters: any = {};
  if (statusFilter !== "ALL") filters.status = statusFilter;
  if (debouncedSearch) filters.search = debouncedSearch;

  const { data: appsData, isLoading } = useApplications(filters);
  const applications = appsData?.content || [];

  return (
    <div className="space-y-6">
      <PageHeader 
        title="Hàng đợi hồ sơ" 
        breadcrumbs={[
          { label: "Tổng quan", href: "/officer/dashboard" },
          { label: "Hàng đợi hồ sơ" }
        ]}
      />

      <div className="flex flex-col sm:flex-row gap-4 bg-card p-4 rounded-lg border">
        <div className="flex-1">
          <Input 
            placeholder="Tìm theo mã hồ sơ, tên người nộp..." 
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            className="max-w-sm"
          />
        </div>
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
                   status === "SUBMITTED" ? "Chờ phân công" :
                   status === "IN_REVIEW" ? "Đang xử lý" :
                   status === "PENDING_SUPPLEMENT" ? "Chờ bổ sung" :
                   status === "APPROVED" ? "Đã duyệt" :
                   status === "REJECTED" ? "Từ chối" : "Đã rút"}
                </SelectItem>
              ))}
            </SelectContent>
          </Select>
        </div>
      </div>

      <div className="bg-card border rounded-lg overflow-hidden">
        <Table>
          <TableHeader>
            <TableRow>
              <TableHead className="w-[120px]">Mã hồ sơ</TableHead>
              <TableHead>Tên thủ tục</TableHead>
              <TableHead>Người nộp</TableHead>
              <TableHead className="w-[150px]">Ngày nộp</TableHead>
              <TableHead className="w-[150px]">Trạng thái</TableHead>
              <TableHead className="w-[100px] text-right">Thao tác</TableHead>
            </TableRow>
          </TableHeader>
          <TableBody>
            {isLoading ? (
              Array.from({ length: 5 }).map((_, i) => (
                <TableRow key={i}>
                  <TableCell colSpan={6}><Skeleton className="h-6 w-full" /></TableCell>
                </TableRow>
              ))
            ) : applications.length > 0 ? (
              applications.map((app) => (
                <ApplicationQueueRow key={app.id} application={app} />
              ))
            ) : (
              <TableRow>
                <TableCell colSpan={6} className="h-32 text-center">
                  <EmptyState 
                    icon={FileSearch} 
                    title="Không có dữ liệu" 
                    description="Không tìm thấy hồ sơ nào phù hợp với điều kiện lọc." 
                  />
                </TableCell>
              </TableRow>
            )}
          </TableBody>
        </Table>
      </div>
    </div>
  );
}
