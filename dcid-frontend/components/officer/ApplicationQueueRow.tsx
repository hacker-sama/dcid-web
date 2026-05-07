import React from "react";
import { TableCell, TableRow } from "@/components/ui/table";
import { ApplicationDTO } from "@/types/application";
import { StatusBadge } from "@/components/shared/StatusBadge";
import { formatDate } from "@/lib/utils";
import { Button } from "@/components/ui/button";
import { Eye } from "lucide-react";
import Link from "next/link";
import { ROUTES } from "@/constants/routes";

interface ApplicationQueueRowProps {
  application: ApplicationDTO;
}

export function ApplicationQueueRow({ application }: ApplicationQueueRowProps) {
  return (
    <TableRow className="hover:bg-muted/50 transition-colors">
      <TableCell className="font-medium">
        #{application.applicationCode}
      </TableCell>
      <TableCell>
        <div className="max-w-[200px] truncate" title={application.procedureName}>
          {application.procedureName}
        </div>
      </TableCell>
      <TableCell>{application.applicantName}</TableCell>
      <TableCell>{formatDate(application.submittedAt || application.createdAt)}</TableCell>
      <TableCell>
        <StatusBadge status={application.status} />
      </TableCell>
      <TableCell className="text-right">
        <Link href={ROUTES.OFFICER.APPLICATION_DETAIL(application.id)}>
          <Button variant="ghost" size="sm" type="button">
            <Eye className="w-4 h-4 mr-2" />
            Chi tiết
          </Button>
        </Link>
      </TableCell>
    </TableRow>
  );
}
