"use client"

import React, { useMemo, useState } from "react";
import { ChevronDown, ChevronUp } from "lucide-react";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import { EmptyState } from "./EmptyState";
import { LoadingSkeleton } from "./LoadingSkeleton";
import { cn } from "@/lib/utils";

export interface Column<T> {
  key?: keyof T;
  accessorKey?: keyof T;
  header: string;
  width?: string;
  className?: string;
  render?: (value: any, row: T) => React.ReactNode;
  cell?: (row: T) => React.ReactNode;
  sortable?: boolean;
}

export type ColumnDef<T> = Column<T>;

interface DataTableProps<T> {
  columns: Column<T>[];
  data: T[];
  isLoading?: boolean;
  emptyMessage?: string;
  emptyTitle?: string;
  emptyDescription?: string;
  onRowClick?: (row: T) => void;
}

type SortDirection = "asc" | "desc" | null;

export function DataTable<T extends object>({
  columns,
  data,
  isLoading = false,
  emptyMessage = "Không có dữ liệu",
  emptyTitle,
  emptyDescription,
  onRowClick,
}: DataTableProps<T>) {
  const [sortConfig, setSortConfig] = useState<{
    key: keyof T;
    direction: SortDirection;
  } | null>(null);

  const sortedData = useMemo(() => {
    if (!sortConfig || !sortConfig.key) return data;

    const sorted = [...data].sort((a, b) => {
      const first = a[sortConfig.key];
      const second = b[sortConfig.key];
      if (first == null && second == null) return 0;
      if (first == null) return -1;
      if (second == null) return 1;

      const firstValue = typeof first === "string" ? first : String(first);
      const secondValue = typeof second === "string" ? second : String(second);

      return firstValue.localeCompare(secondValue, "vi", { numeric: true });
    });

    return sortConfig.direction === "desc" ? sorted.reverse() : sorted;
  }, [data, sortConfig]);

  const handleSort = (column: Column<T>) => {
    if (!column.sortable) return;

    const sortKey = column.accessorKey ?? column.key;
    if (!sortKey) return;

    setSortConfig((current) => {
      if (!current || current.key !== sortKey) {
        return { key: sortKey, direction: "asc" };
      }

      if (current.direction === "asc") {
        return { key: sortKey, direction: "desc" };
      }

      return null;
    });
  };

  if (isLoading) {
    return <LoadingSkeleton rows={5} />;
  }

  if (!data || data.length === 0) {
    return <EmptyState message={emptyMessage ?? emptyTitle} description={emptyDescription} />;
  }

  return (
    <div className="rounded-3xl border border-border bg-background shadow-sm">
      <Table>
        <TableHeader>
          <TableRow>
            {columns.map((column) => {
              const isActive = sortConfig?.key === column.key;
              return (
                <TableHead
                  key={String(column.key)}
                  className={cn(
                    column.width,
                    "sticky top-0 bg-background text-left font-semibold",
                    column.sortable ? "cursor-pointer select-none" : "",
                    onRowClick ? "group/data-table" : ""
                  )}
                  onClick={() => handleSort(column)}
                >
                  <div className="flex items-center gap-2">
                    <span>{column.header}</span>
                    {column.sortable ? (
                      <span className="flex items-center gap-1 text-muted-foreground">
                        <ChevronUp className={cn("h-3 w-3", isActive && sortConfig?.direction === "asc" ? "text-foreground" : "opacity-40")} />
                        <ChevronDown className={cn("h-3 w-3", isActive && sortConfig?.direction === "desc" ? "text-foreground" : "opacity-40")} />
                      </span>
                    ) : null}
                  </div>
                </TableHead>
              );
            })}
          </TableRow>
        </TableHeader>
        <TableBody>
          {sortedData.map((row, rowIndex) => (
            <TableRow
              key={rowIndex}
              className={onRowClick ? "cursor-pointer hover:bg-muted/50 transition-colors" : undefined}
              onClick={() => onRowClick?.(row)}
            >
              {columns.map((column) => (
                <TableCell key={String(column.key)} className={cn(column.width, column.className)}>
                  {(() => {
                const cellKey = column.accessorKey ?? column.key;
                const cellValue = cellKey ? row[cellKey] : undefined;
                if (column.render) {
                  return column.render(cellValue as any, row);
                }
                if (column.cell) {
                  return column.cell(row);
                }
                return String(cellValue ?? "");
              })()}
                </TableCell>
              ))}
            </TableRow>
          ))}
        </TableBody>
      </Table>
    </div>
  );
}
