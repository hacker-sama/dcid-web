import React from "react";
import { Card, CardContent, CardFooter, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { ProcedureTypeDTO } from "@/types/procedure";
import { Clock, FileText, ArrowRight } from "lucide-react";
import Link from "next/link";
import { formatCurrency } from "@/lib/utils";
import { ROUTES } from "@/constants/routes";

interface ProcedureCardProps {
  procedure: ProcedureTypeDTO;
}

export function ProcedureCard({ procedure }: ProcedureCardProps) {
  return (
    <Card className="flex flex-col h-full hover:shadow-md transition-shadow">
      <CardHeader>
        <div className="flex justify-between items-start mb-2">
          <Badge variant="secondary" className="bg-primary-tint text-primary hover:bg-primary-tint">
            {procedure.category}
          </Badge>
          {!procedure.active && (
            <Badge variant="destructive">Tạm ngưng</Badge>
          )}
        </div>
        <CardTitle className="text-lg line-clamp-2 leading-tight">
          {procedure.name}
        </CardTitle>
      </CardHeader>
      <CardContent className="flex-grow">
        <p className="text-sm text-muted-foreground line-clamp-3 mb-4">
          {procedure.description}
        </p>
        <div className="space-y-2 text-sm">
          <div className="flex items-center text-muted-foreground">
            <Clock className="w-4 h-4 mr-2" />
            <span>Thời gian: {procedure.processingTimeDays} ngày làm việc</span>
          </div>
          <div className="flex items-center text-muted-foreground">
            <FileText className="w-4 h-4 mr-2" />
            <span>Lệ phí: {procedure.fee === 0 ? "Miễn phí" : formatCurrency(procedure.fee)}</span>
          </div>
        </div>
      </CardContent>
      <CardFooter>
        <Link href={ROUTES.CITIZEN.PROCEDURE_DETAIL(procedure.code)} className="w-full">
          <Button className="w-full group" disabled={!procedure.active} type="button">
            Xem chi tiết
            <ArrowRight className="w-4 h-4 ml-2 group-hover:translate-x-1 transition-transform" />
          </Button>
        </Link>
      </CardFooter>
    </Card>
  );
}
