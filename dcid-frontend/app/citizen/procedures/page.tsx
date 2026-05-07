"use client";

import React, { useState } from "react";
import { PageHeader } from "@/components/shared/PageHeader";
import { ProcedureCard } from "@/components/citizen/ProcedureCard";
import { useProcedures } from "@/hooks/useProcedures";
import { Input } from "@/components/ui/input";
import { Search } from "lucide-react";
import { LoadingList } from "@/components/shared/LoadingSkeleton";
import { EmptyState } from "@/components/shared/EmptyState";
import { useDebounce } from "use-debounce";

export default function ProceduresPage() {
  const [searchTerm, setSearchTerm] = useState("");
  const [debouncedSearch] = useDebounce(searchTerm, 500);

  const { data: proceduresData, isLoading } = useProcedures({ 
    search: debouncedSearch,
    size: 20 
  });

  const procedures = proceduresData?.content || [];

  return (
    <div className="space-y-6">
      <PageHeader 
        title="Thủ tục hành chính" 
        breadcrumbs={[
          { label: "Tổng quan", href: "/citizen/dashboard" },
          { label: "Thủ tục hành chính" }
        ]}
      />

      <div className="flex items-center space-x-2 bg-card border rounded-md px-3 py-2 max-w-md shadow-sm">
        <Search className="w-5 h-5 text-muted-foreground" />
        <Input 
          type="text" 
          placeholder="Tìm kiếm thủ tục..." 
          className="border-0 focus-visible:ring-0 shadow-none h-8 p-0"
          value={searchTerm}
          onChange={(e) => setSearchTerm(e.target.value)}
        />
      </div>

      {isLoading ? (
        <div className="grid gap-6 md:grid-cols-2 lg:grid-cols-3">
          {Array.from({ length: 6 }).map((_, i) => (
            <div key={i} className="h-48 bg-card border rounded-lg animate-pulse" />
          ))}
        </div>
      ) : procedures.length > 0 ? (
        <div className="grid gap-6 md:grid-cols-2 lg:grid-cols-3">
          {procedures.map((procedure) => (
            <ProcedureCard key={procedure.id} procedure={procedure} />
          ))}
        </div>
      ) : (
        <div className="bg-card border rounded-lg py-12">
          <EmptyState 
            icon={Search} 
            title="Không tìm thấy thủ tục" 
            description="Không có thủ tục nào phù hợp với từ khóa tìm kiếm của bạn. Vui lòng thử lại với từ khóa khác."
          />
        </div>
      )}
    </div>
  );
}
