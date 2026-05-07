"use client";

import React from "react";
import { PageHeader } from "@/components/shared/PageHeader";
import { useApplication, useUpdateApplicationStatus } from "@/hooks/useApplications";
import { useApplicationStatus as useWebSocketStatus } from "@/hooks/useApplicationStatus";
import { StatusBadge } from "@/components/shared/StatusBadge";
import { ApplicationTimeline } from "@/components/shared/ApplicationTimeline";
import { WebSocketIndicator } from "@/components/shared/WebSocketIndicator";
import { ReviewPanel } from "@/components/officer/ReviewPanel";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Skeleton } from "@/components/ui/skeleton";
import { ROUTES } from "@/constants/routes";
import { formatDate } from "@/lib/utils";
import { FileText, Download, User } from "lucide-react";
import { Button } from "@/components/ui/button";
import { ApplicationStatus } from "@/types/application";
import { toast } from "sonner";

export default function OfficerApplicationDetailPage({ params }: { params: { id: string } }) {
  const { data: application, isLoading } = useApplication(params.id);
  const { isConnected } = useWebSocketStatus(params.id);
  const { mutateAsync: updateStatus, isPending } = useUpdateApplicationStatus();

  const handleUpdateStatus = async (status: ApplicationStatus, note: string) => {
    try {
      await updateStatus({ id: params.id, status, note });
      toast.success("Cập nhật trạng thái thành công");
    } catch (error: any) {
      toast.error(error?.response?.data?.message || "Có lỗi xảy ra khi cập nhật trạng thái");
    }
  };

  if (isLoading) {
    return (
      <div className="space-y-6">
        <Skeleton className="h-10 w-1/3" />
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
          <div className="lg:col-span-2 space-y-6">
            <Skeleton className="h-[300px] w-full" />
            <Skeleton className="h-[200px] w-full" />
          </div>
          <Skeleton className="h-[400px] w-full" />
        </div>
      </div>
    );
  }

  if (!application) {
    return <div className="text-center py-12 text-danger">Không tìm thấy hồ sơ</div>;
  }

  return (
    <div className="space-y-6">
      <PageHeader 
        title={`Xử lý hồ sơ #${application.applicationCode}`} 
        breadcrumbs={[
          { label: "Tổng quan", href: ROUTES.OFFICER.DASHBOARD },
          { label: "Hàng đợi hồ sơ", href: ROUTES.OFFICER.APPLICATIONS },
          { label: "Xử lý hồ sơ" }
        ]}
      >
        <WebSocketIndicator isConnected={isConnected} />
      </PageHeader>

      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 bg-card p-4 rounded-lg border">
        <div className="flex items-start gap-4">
          <div className="p-3 bg-primary/10 rounded-full shrink-0">
            <User className="w-6 h-6 text-primary" />
          </div>
          <div>
            <h2 className="text-lg font-semibold">{application.applicantName}</h2>
            <p className="text-sm text-muted-foreground">
              Nộp lúc: {formatDate(application.submittedAt || application.createdAt)}
            </p>
          </div>
        </div>
        <StatusBadge status={application.status} className="w-fit text-sm px-3 py-1" />
      </div>

      <div className="grid grid-cols-1 xl:grid-cols-3 gap-6">
        {/* Left Column - Application Data */}
        <div className="xl:col-span-2 space-y-6">
          <Card>
            <CardHeader>
              <CardTitle className="text-base flex items-center justify-between">
                <span>Thông tin hồ sơ: {application.procedureName}</span>
              </CardTitle>
            </CardHeader>
            <CardContent>
              <div className="grid grid-cols-1 md:grid-cols-2 gap-x-6 gap-y-4">
                {Object.entries(application.formData || {}).map(([key, value]) => (
                  <div key={key} className="space-y-1 border-b pb-2">
                    <p className="text-sm text-muted-foreground capitalize">{key.replace(/([A-Z])/g, ' $1').trim()}</p>
                    <p className="font-medium">{value !== null && value !== undefined ? value.toString() : "N/A"}</p>
                  </div>
                ))}
                {(!application.formData || Object.keys(application.formData).length === 0) && (
                  <p className="text-muted-foreground text-sm">Không có dữ liệu khai báo.</p>
                )}
              </div>
            </CardContent>
          </Card>

          <Card>
            <CardHeader>
              <CardTitle className="text-base">Tài liệu đính kèm</CardTitle>
            </CardHeader>
            <CardContent>
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                {application.documents?.map((doc) => (
                  <div key={doc.id} className="flex items-center justify-between p-3 border rounded-md bg-muted/20 hover:bg-muted/50 transition-colors">
                    <div className="flex items-center gap-3 overflow-hidden">
                      <div className="p-2 bg-primary/10 text-primary rounded-md shrink-0">
                        <FileText className="w-4 h-4" />
                      </div>
                      <div className="truncate">
                        <p className="text-sm font-medium truncate flex items-center gap-2">
                          {doc.documentType}
                          {doc.documentType === "SIGNATURE" && <Badge variant="outline" className="text-[10px] h-4 px-1">Chữ ký</Badge>}
                        </p>
                        <p className="text-xs text-muted-foreground">
                          {doc.fileName || "document.pdf"} • {(doc.fileSize / 1024 / 1024).toFixed(2)} MB
                        </p>
                      </div>
                    </div>
                    <a href={doc.fileUrl} target="_blank" rel="noopener noreferrer">
                      <Button variant="ghost" size="icon" type="button">
                        <Download className="w-4 h-4 text-muted-foreground" />
                      </Button>
                    </a>
                  </div>
                ))}
                {(!application.documents || application.documents.length === 0) && (
                  <p className="text-muted-foreground text-sm col-span-2">Không có tài liệu đính kèm.</p>
                )}
              </div>
            </CardContent>
          </Card>
        </div>

        {/* Right Column - Action & History */}
        <div className="space-y-6">
          <ReviewPanel 
            currentStatus={application.status} 
            onUpdateStatus={handleUpdateStatus} 
            isLoading={isPending} 
          />

          <Card>
            <CardHeader>
              <CardTitle className="text-base">Tiến độ xử lý</CardTitle>
            </CardHeader>
            <CardContent>
              <ApplicationTimeline history={application.statusHistory || []} />
            </CardContent>
          </Card>
        </div>
      </div>
    </div>
  );
}
