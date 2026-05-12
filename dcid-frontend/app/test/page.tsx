"use client";

import { useState } from "react";
import { PageHeader } from "@/components/shared/PageHeader";
import { StatusBadge } from "@/components/shared/StatusBadge";
import { ApplicationTimeline } from "@/components/shared/ApplicationTimeline";
import { FileUploadZone } from "@/components/shared/FileUploadZone";
import { DataTable, type Column } from "@/components/shared/DataTable";
import { LoadingSkeleton } from "@/components/shared/LoadingSkeleton";
import { EmptyState } from "@/components/shared/EmptyState";
import { ConfirmDialog } from "@/components/shared/ConfirmDialog";
import { NotificationBell } from "@/components/shared/NotificationBell";
import { WebSocketIndicator } from "@/components/shared/WebSocketIndicator";
import { ApplicationStatus } from "@/types/application";

interface ExampleRow {
  id: string;
  name: string;
  status: string;
}

const badgeStatuses: ApplicationStatus[] = [
  ApplicationStatus.DRAFT,
  ApplicationStatus.SUBMITTED,
  ApplicationStatus.IN_REVIEW,
  ApplicationStatus.PENDING_SUPPLEMENT,
  ApplicationStatus.APPROVED,
  ApplicationStatus.REJECTED,
  ApplicationStatus.WITHDRAWN,
];

const timelineItems = [
  {
    id: "1",
    fromStatus: ApplicationStatus.DRAFT,
    toStatus: ApplicationStatus.SUBMITTED,
    changedBy: "Nguyễn Văn A",
    note: "Khởi tạo hồ sơ và gửi đi.",
    changedAt: new Date().toISOString(),
  },
  {
    id: "2",
    fromStatus: ApplicationStatus.SUBMITTED,
    toStatus: ApplicationStatus.IN_REVIEW,
    changedBy: "Hệ thống",
    note: null,
    changedAt: new Date(Date.now() - 1000 * 60 * 60).toISOString(),
  },
];

const columns: Column<ExampleRow>[] = [
  { key: "id", header: "Mã", width: "w-24", sortable: true },
  { key: "name", header: "Tên người dùng", sortable: true },
  { key: "status", header: "Trạng thái", sortable: true },
];

const rows: ExampleRow[] = [
  { id: "001", name: "Nguyễn Văn A", status: "Đang xử lý" },
  { id: "002", name: "Trần Thị B", status: "Đã duyệt" },
];

export default function TestPage() {
  const [dialogOpen, setDialogOpen] = useState(false);
  const [selectedFiles, setSelectedFiles] = useState<File[]>([]);
  const [connected, setConnected] = useState(true);

  return (
    <main className="min-h-screen bg-slate-50 p-6 text-slate-900">
      <div className="mx-auto max-w-6xl space-y-10">
        <PageHeader
          title="Component Test Page"
          breadcrumb={[
            { label: "Trang chủ", href: "/" },
            { label: "Test component" },
          ]}
          actions={
            <button
              type="button"
              onClick={() => setDialogOpen(true)}
              className="rounded-full bg-primary px-4 py-2 text-white"
            >
              Mở ConfirmDialog
            </button>
          }
        />

        <div className="grid gap-6 sm:grid-cols-2">
          <section className="rounded-3xl border border-border bg-white p-6 shadow-sm">
            <h2 className="mb-4 text-xl font-semibold">StatusBadge</h2>
            <div className="flex flex-wrap gap-3">
              {badgeStatuses.map((status) => (
                <StatusBadge key={status} status={status} />
              ))}
            </div>
          </section>

          <section className="rounded-3xl border border-border bg-white p-6 shadow-sm">
            <h2 className="mb-4 text-xl font-semibold">WebSocketIndicator</h2>
            <div className="flex items-center gap-4">
              <WebSocketIndicator isConnected={connected} />
              <button
                onClick={() => setConnected((prev) => !prev)}
                className="rounded-full bg-secondary px-4 py-2 text-secondary-foreground"
              >
                Đổi trạng thái
              </button>
            </div>
          </section>
        </div>

        <section className="rounded-3xl border border-border bg-white p-6 shadow-sm">
          <h2 className="mb-4 text-xl font-semibold">ApplicationTimeline</h2>
          <ApplicationTimeline items={timelineItems} />
        </section>

        <section className="rounded-3xl border border-border bg-white p-6 shadow-sm">
          <h2 className="mb-4 text-xl font-semibold">FileUploadZone</h2>
          <FileUploadZone
            onFilesSelected={(files) => setSelectedFiles(files)}
            maxFileSizeMB={2}
            acceptedTypes={["application/pdf", "image/png", "image/jpeg"]}
            maxFiles={3}
          />
          <div className="mt-4 text-sm text-muted-foreground">
            {selectedFiles.length > 0 ? (
              <p>{selectedFiles.length} file đã chọn</p>
            ) : (
              <p>Chưa có file nào được chọn</p>
            )}
          </div>
        </section>

        <section className="rounded-3xl border border-border bg-white p-6 shadow-sm">
          <h2 className="mb-4 text-xl font-semibold">DataTable</h2>
          <DataTable
            columns={columns}
            data={rows}
            onRowClick={(row) => alert(`Clicked ${row.name}`)}
          />
        </section>

        <section className="rounded-3xl border border-border bg-white p-6 shadow-sm">
          <h2 className="mb-4 text-xl font-semibold">LoadingSkeleton</h2>
          <LoadingSkeleton rows={4} />
        </section>

        <section className="rounded-3xl border border-border bg-white p-6 shadow-sm">
          <h2 className="mb-4 text-xl font-semibold">EmptyState</h2>
          <EmptyState
            message="Không tìm thấy nội dung"
            description="Hãy thử thay đổi bộ lọc hoặc tải lại trang." 
            action={{ label: "Tải lại", onClick: () => window.location.reload() }}
          />
        </section>

        <section className="rounded-3xl border border-border bg-white p-6 shadow-sm">
          <h2 className="mb-4 text-xl font-semibold">NotificationBell</h2>
          <NotificationBell />
        </section>
      </div>

      <ConfirmDialog
        open={dialogOpen}
        onOpenChange={setDialogOpen}
        title="Xác nhận hành động"
        description="Bạn có chắc chắn muốn kiểm tra dialog này?"
        onConfirm={() => {
          setDialogOpen(false);
          alert("Đã xác nhận");
        }}
      />
    </main>
  );
}
