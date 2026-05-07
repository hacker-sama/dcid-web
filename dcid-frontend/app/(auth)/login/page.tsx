"use client";

import { signIn } from "next-auth/react";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Shield } from "lucide-react";

export default function LoginPage() {
  const handleLogin = () => {
    signIn("keycloak", { callbackUrl: "/" });
  };

  return (
    <div className="min-h-screen flex items-center justify-center bg-muted/30 p-4">
      <Card className="w-full max-w-md shadow-lg border-primary/20">
        <CardHeader className="text-center pb-8 pt-10">
          <div className="mx-auto w-16 h-16 bg-primary/10 rounded-full flex items-center justify-center mb-6">
            <Shield className="w-8 h-8 text-primary" />
          </div>
          <CardTitle className="text-3xl font-bold tracking-tight text-primary">DCID Platform</CardTitle>
          <CardDescription className="text-base mt-2">
            Nền tảng Công dân số - Một cửa quốc gia
          </CardDescription>
        </CardHeader>
        <CardContent className="pb-10 px-8">
          <Button 
            className="w-full h-12 text-base font-semibold" 
            onClick={handleLogin}
          >
            Đăng nhập qua VNeID / Keycloak
          </Button>
          <p className="text-center text-sm text-muted-foreground mt-6">
            Bằng việc đăng nhập, bạn đồng ý với Điều khoản sử dụng và Chính sách bảo mật của chúng tôi.
          </p>
        </CardContent>
      </Card>
    </div>
  );
}
