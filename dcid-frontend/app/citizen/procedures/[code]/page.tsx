"use client";

import React from "react";
import { PageHeader } from "@/components/shared/PageHeader";
import { useProcedure } from "@/hooks/useProcedures";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Clock, FileText, CheckCircle2, ArrowRight } from "lucide-react";
import Link from "next/link";
import { ROUTES } from "@/constants/routes";
import { formatCurrency } from "@/lib/utils";
import { Skeleton } from "@/components/ui/skeleton";

export default function ProcedureDetailPage({ params }: { params: { code: string } }) {
  const { data: procedure, isLoading } = useProcedure(params.code);

  if (isLoading) {
    return (
      <div className="space-y-6">
        <Skeleton className="h-10 w-1/3" />
        <Skeleton className="h-[400px] w-full" />
      </div>
    );
  }

  if (!procedure) {
    return (
      <div className="text-center py-12">
        <h2 className="text-2xl font-bold text-danger">Không tìm thấy thủ tục</h2>
      </div>
    );
  }

  return (
    <div className="space-y-6 max-w-4xl">
      <PageHeader 
        title={procedure.name} 
        breadcrumbs={[
          { label: "Tổng quan", href: ROUTES.CITIZEN.DASHBOARD },
          { label: "Thủ tục hành chính", href: ROUTES.CITIZEN.PROCEDURES },
          { label: "Chi tiết" }
        ]}
      />

      <div className="flex items-center gap-3 mb-6">
        <Badge variant="secondary" className="bg-primary-tint text-primary">
          {procedure.category}
        </Badge>
        <span className="text-sm font-medium text-muted-foreground border-l pl-3">
          Mã thủ tục: {procedure.code}
        </span>
      </div>

      <Card>
        <CardHeader>
          <CardTitle>Thông tin chung</CardTitle>
        </CardHeader>
        <CardContent className="space-y-6">
          <p className="text-muted-foreground leading-relaxed">
            {procedure.description}
          </p>
          
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div className="flex items-center p-4 border rounded-lg bg-muted/20">
              <Clock className="w-8 h-8 text-primary/70 mr-4" />
              <div>
                <p className="text-sm text-muted-foreground">Thời gian giải quyết</p>
                <p className="font-semibold">{procedure.processingTimeDays} ngày làm việc</p>
              </div>
            </div>
            <div className="flex items-center p-4 border rounded-lg bg-muted/20">
              <FileText className="w-8 h-8 text-primary/70 mr-4" />
              <div>
                <p className="text-sm text-muted-foreground">Lệ phí</p>
                <p className="font-semibold">{procedure.fee === 0 ? "Miễn phí" : formatCurrency(procedure.fee)}</p>
              </div>
            </div>
          </div>
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <CardTitle>Thành phần hồ sơ</CardTitle>
        </CardHeader>
        <CardContent>
          <ul className="space-y-4">
            {procedure.requiredDocuments?.map((doc, index) => (
              <li key={index} className="flex items-start gap-3">
                <CheckCircle2 className="w-5 h-5 text-success shrink-0 mt-0.5" />
                <div>
                  <p className="font-medium">
                    {doc.name}
                    {doc.required && <span className="text-danger ml-1">*</span>}
                  </p>
                  {doc.description && <p className="text-sm text-muted-foreground mt-1">{doc.description}</p>}
                </div>
              </li>
            ))}
            {(!procedure.requiredDocuments || procedure.requiredDocuments.length === 0) && (
              <p className="text-muted-foreground text-sm italic">Không yêu cầu tài liệu đính kèm đặc biệt.</p>
            )}
          </ul>
        </CardContent>
      </Card>

      <div className="flex justify-end pt-4">
        <Link href={ROUTES.CITIZEN.APPLICATION_NEW(procedure.code)}>
          <Button size="lg" disabled={!procedure.active} type="button">
            Nộp hồ sơ trực tuyến
            <ArrowRight className="w-4 h-4 ml-2" />
          </Button>
        </Link>
      </div>
    </div>
  );
}
