import React from "react";
import { ApplicationDTO } from "@/types/application";
import { Card, CardContent } from "@/components/ui/card";
import { StatusBadge } from "@/components/shared/StatusBadge";
import { formatDate } from "@/lib/utils";
import { ChevronRight, FileText, Calendar } from "lucide-react";
import Link from "next/link";
import { ROUTES } from "@/constants/routes";

interface ApplicationListItemProps {
  application: ApplicationDTO;
}

export function ApplicationListItem({ application }: ApplicationListItemProps) {
  return (
    <Link href={ROUTES.CITIZEN.APPLICATION_DETAIL(application.id)} className="block">
      <Card className="hover:border-primary/50 transition-colors cursor-pointer group">
        <CardContent className="p-4 sm:p-6 flex flex-col sm:flex-row sm:items-center justify-between gap-4">
          <div className="space-y-2 flex-1">
            <div className="flex items-center justify-between sm:justify-start gap-3">
              <span className="font-semibold text-primary">#{application.applicationCode}</span>
              <StatusBadge status={application.status} />
            </div>
            <h3 className="font-medium text-base line-clamp-1">
              {application.procedureName}
            </h3>
            <div className="flex flex-col sm:flex-row sm:items-center gap-2 sm:gap-6 text-sm text-muted-foreground">
              <div className="flex items-center gap-1.5">
                <FileText className="w-4 h-4" />
                <span>Nộp bởi: {application.applicantName}</span>
              </div>
              <div className="flex items-center gap-1.5">
                <Calendar className="w-4 h-4" />
                <span>Ngày nộp: {formatDate(application.submittedAt || application.createdAt)}</span>
              </div>
            </div>
          </div>
          
          <div className="hidden sm:flex items-center text-muted-foreground group-hover:text-primary transition-colors">
            <ChevronRight className="w-5 h-5" />
          </div>
        </CardContent>
      </Card>
    </Link>
  );
}
