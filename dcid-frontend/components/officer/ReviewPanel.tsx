"use client";

import React, { useState } from "react";
import { ApplicationStatus } from "@/types/application";
import { Button } from "@/components/ui/button";
import { Textarea } from "@/components/ui/textarea";
import { Label } from "@/components/ui/label";
import { ConfirmDialog } from "@/components/shared/ConfirmDialog";
import { Check, X, FileEdit } from "lucide-react";

interface ReviewPanelProps {
  currentStatus: ApplicationStatus;
  onUpdateStatus: (status: ApplicationStatus, note: string) => Promise<void>;
  isLoading: boolean;
}

export function ReviewPanel({ currentStatus, onUpdateStatus, isLoading }: ReviewPanelProps) {
  const [note, setNote] = useState("");
  const [dialogConfig, setDialogConfig] = useState<{
    open: boolean;
    status: ApplicationStatus | null;
    title: string;
    description: string;
  }>({
    open: false,
    status: null,
    title: "",
    description: "",
  });

  const handleActionClick = (status: ApplicationStatus) => {
    let title = "";
    let description = "";

    switch (status) {
      case ApplicationStatus.APPROVED:
        title = "Phê duyệt hồ sơ";
        description = "Bạn có chắc chắn muốn duyệt hồ sơ này? Hành động này không thể hoàn tác.";
        break;
      case ApplicationStatus.REJECTED:
        title = "Từ chối hồ sơ";
        description = "Bạn sắp từ chối hồ sơ này. Vui lòng đảm bảo đã ghi rõ lý do từ chối trong phần ghi chú.";
        break;
      case ApplicationStatus.PENDING_SUPPLEMENT:
        title = "Yêu cầu bổ sung";
        description = "Bạn sắp yêu cầu công dân bổ sung hồ sơ. Các yêu cầu chi tiết phải được ghi trong phần ghi chú.";
        break;
    }

    if ((status === ApplicationStatus.REJECTED || status === ApplicationStatus.PENDING_SUPPLEMENT) && !note.trim()) {
      alert("Vui lòng nhập ghi chú lý do trước khi thực hiện hành động này.");
      return;
    }

    setDialogConfig({ open: true, status, title, description });
  };

  const handleConfirm = async () => {
    if (dialogConfig.status) {
      await onUpdateStatus(dialogConfig.status, note);
      setNote("");
    }
  };

  if (currentStatus !== ApplicationStatus.SUBMITTED && currentStatus !== ApplicationStatus.IN_REVIEW) {
    return null; // Only show panel when actionable
  }

  return (
    <div className="bg-card border rounded-lg p-6 space-y-6">
      <div>
        <h3 className="text-lg font-semibold mb-2">Xử lý hồ sơ</h3>
        <p className="text-sm text-muted-foreground">Đánh giá và cập nhật trạng thái hồ sơ.</p>
      </div>

      <div className="space-y-2">
        <Label>Ghi chú xử lý / Lý do (Bắt buộc khi từ chối hoặc yêu cầu bổ sung)</Label>
        <Textarea 
          placeholder="Nhập nội dung phản hồi cho công dân..."
          value={note}
          onChange={(e) => setNote(e.target.value)}
          rows={4}
          disabled={isLoading}
        />
      </div>

      <div className="flex flex-wrap gap-3 pt-2">
        <Button 
          className="bg-success hover:bg-success/90" 
          disabled={isLoading}
          onClick={() => handleActionClick(ApplicationStatus.APPROVED)}
        >
          <Check className="w-4 h-4 mr-2" />
          Phê duyệt
        </Button>
        <Button 
          variant="outline" 
          className="text-warning border-warning hover:bg-warning/10"
          disabled={isLoading}
          onClick={() => handleActionClick(ApplicationStatus.PENDING_SUPPLEMENT)}
        >
          <FileEdit className="w-4 h-4 mr-2" />
          Yêu cầu bổ sung
        </Button>
        <Button 
          variant="destructive"
          disabled={isLoading}
          onClick={() => handleActionClick(ApplicationStatus.REJECTED)}
        >
          <X className="w-4 h-4 mr-2" />
          Từ chối
        </Button>
      </div>

      <ConfirmDialog 
        open={dialogConfig.open}
        onOpenChange={(open) => setDialogConfig(prev => ({ ...prev, open }))}
        title={dialogConfig.title}
        description={dialogConfig.description}
        onConfirm={handleConfirm}
        variant={dialogConfig.status === ApplicationStatus.REJECTED ? "destructive" : "default"}
      />
    </div>
  );
}
