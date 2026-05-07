import Link from "next/link";
import { ShieldX } from "lucide-react";
import { Button } from "@/components/ui/button";

export const metadata = {
  title: "403 - Không có quyền truy cập | DCID",
  description: "Bạn không có quyền truy cập vào trang này.",
};

export default function ForbiddenPage() {
  return (
    <div className="min-h-screen flex flex-col items-center justify-center bg-muted/30 p-4 text-center">
      <div className="mx-auto w-20 h-20 bg-danger/10 rounded-full flex items-center justify-center mb-6">
        <ShieldX className="w-10 h-10 text-danger" />
      </div>
      <h1 className="text-4xl font-bold text-danger mb-2">403</h1>
      <p className="text-xl font-semibold mb-2">Không có quyền truy cập</p>
      <p className="text-muted-foreground mb-8 max-w-md">
        Tài khoản của bạn không có quyền truy cập vào trang này. Vui lòng đăng nhập với tài khoản phù hợp hoặc liên hệ quản trị viên.
      </p>
      <div className="flex gap-4">
        <Link href="/login">
          <Button variant="default">Đăng nhập lại</Button>
        </Link>
        <Link href="/">
          <Button variant="outline">Về trang chủ</Button>
        </Link>
      </div>
    </div>
  );
}
