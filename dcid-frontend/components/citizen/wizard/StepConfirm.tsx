"use client";

import React, { useState } from "react";
import { Button } from "@/components/ui/button";
import { Checkbox } from "@/components/ui/checkbox";
import { Label } from "@/components/ui/label";
import { AlertTriangle, FileText, Upload } from "lucide-react";

interface StepConfirmProps {
  isSubmitting: boolean;
  onConfirm: () => void;
  onBack: () => void;
}

export function StepConfirm({ isSubmitting, onConfirm, onBack }: StepConfirmProps) {
  const [agreed, setAgreed] = useState(false);

  return (
    <div className="p-6">
      <div className="flex flex-col items-center justify-center text-center space-y-4 mb-8">
        <div className="w-16 h-16 bg-primary/10 text-primary rounded-full flex items-center justify-center mb-2">
          <Upload className="w-8 h-8" />
        </div>
        <h3 className="text-2xl font-bold">Xác nhận nộp hồ sơ</h3>
        <p className="text-muted-foreground max-w-md">
          Bạn đã hoàn thành việc điền thông tin và tải lên các tài liệu cần thiết. Vui lòng kiểm tra lại cam kết trước khi gửi hồ sơ.
        </p>
      </div>

      <div className="bg-amber-50 dark:bg-amber-950/30 border border-amber-200 dark:border-amber-900 rounded-lg p-4 mb-8">
        <h4 className="font-semibold text-amber-800 dark:text-amber-500 flex items-center gap-2 mb-2">
          <AlertTriangle className="w-5 h-5" />
          Lưu ý quan trọng
        </h4>
        <ul className="list-disc pl-5 space-y-1 text-sm text-amber-700 dark:text-amber-600/80">
          <li>Công dân chịu trách nhiệm trước pháp luật về tính chính xác, trung thực của các thông tin đã khai báo.</li>
          <li>Tài liệu đính kèm phải rõ nét, đầy đủ thông tin và hợp lệ theo quy định của pháp luật.</li>
          <li>Sau khi nộp, hồ sơ sẽ được chuyển đến cơ quan có thẩm quyền để xử lý. Bạn có thể theo dõi tiến độ tại mục "Hồ sơ của tôi".</li>
        </ul>
      </div>

      <div className="flex items-start space-x-3 mb-8 p-4 border rounded-lg bg-muted/30">
        <Checkbox 
          id="agree" 
          checked={agreed} 
          onCheckedChange={(checked) => setAgreed(!!checked)}
          className="mt-1"
        />
        <div className="space-y-1 leading-none">
          <Label htmlFor="agree" className="text-sm font-medium leading-relaxed">
            Tôi xin cam đoan những lời khai trên là đúng sự thật và chịu hoàn toàn trách nhiệm trước pháp luật. 
            Tôi đồng ý cho phép cơ quan nhà nước sử dụng dữ liệu cá nhân của tôi để giải quyết thủ tục này.
          </Label>
        </div>
      </div>

      <div className="mt-8 flex justify-between">
        <Button variant="outline" onClick={onBack} disabled={isSubmitting}>Quay lại</Button>
        <Button 
          onClick={onConfirm} 
          disabled={!agreed || isSubmitting}
          className="min-w-[150px]"
        >
          {isSubmitting ? "Đang xử lý..." : "Nộp hồ sơ"}
        </Button>
      </div>
    </div>
  );
}
