import { useQuery } from "@tanstack/react-query";
import apiClient from "@/lib/api-client";
import { QUERY_KEYS } from "@/constants/query-keys";
import { ProcedureTypeDTO } from "@/types/procedure";
import { ApiResponse, PagedResponse } from "@/types/api";

export function useProcedures(filters: any = {}) {
  return useQuery({
    queryKey: QUERY_KEYS.PROCEDURES.LIST(filters),
    queryFn: async () => {
      const { data } = await apiClient.get<ApiResponse<PagedResponse<ProcedureTypeDTO>>>("/procedures", {
        params: filters,
      });
      return data.data;
    },
  });
}

export function useProcedure(code: string) {
  return useQuery({
    queryKey: QUERY_KEYS.PROCEDURES.DETAIL(code),
    queryFn: async () => {
      if (!code) return null;
      const { data } = await apiClient.get<ApiResponse<ProcedureTypeDTO>>(`/procedures/${code}`);
      return data.data;
    },
    enabled: !!code,
  });
}
