import React from "react";
import { useSession } from "next-auth/react";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Button } from "@/components/ui/button";

interface StepPersonalInfoProps {
  onNext: () => void;
}

export function StepPersonalInfo({ onNext }: StepPersonalInfoProps) {
  const { data: session } = useSession();
  const user = session?.user;

  return (
    <div className="p-6">
      <h3 className="text-lg font-semibold mb-4">Thông tin người nộp</h3>
      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        <div className="space-y-2">
          <Label>Họ và tên</Label>
          <Input value={user?.name || ""} disabled />
        </div>
        <div className="space-y-2">
          <Label>Email</Label>
          <Input value={user?.email || ""} disabled />
        </div>
        <div className="space-y-2">
          <Label>Số điện thoại</Label>
          <Input value="0987654321" disabled />
        </div>
        <div className="space-y-2">
          <Label>Số CMND/CCCD</Label>
          <Input value="012345678901" disabled />
        </div>
        <div className="space-y-2 md:col-span-2">
          <Label>Địa chỉ</Label>
          <Input value="123 Đường ABC, Phường XYZ, Quận 1, TP.HCM" disabled />
        </div>
      </div>
      <div className="mt-8 flex justify-end">
        <Button onClick={onNext}>Tiếp tục</Button>
      </div>
    </div>
  );
}
