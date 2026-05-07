import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import apiClient from "@/lib/api-client";
import { QUERY_KEYS } from "@/constants/query-keys";
import { ApplicationDTO, ApplicationDetailDTO, CreateApplicationRequest, ApplicationStatus } from "@/types/application";
import { ApiResponse, PagedResponse } from "@/types/api";

export function useApplications(filters: any = {}) {
  return useQuery({
    queryKey: QUERY_KEYS.APPLICATIONS.LIST(filters),
    queryFn: async () => {
      const { data } = await apiClient.get<ApiResponse<PagedResponse<ApplicationDTO>>>("/applications", {
        params: filters,
      });
      return data.data;
    },
  });
}

export function useApplication(id: string) {
  return useQuery({
    queryKey: QUERY_KEYS.APPLICATIONS.DETAIL(id),
    queryFn: async () => {
      if (!id) return null;
      const { data } = await apiClient.get<ApiResponse<ApplicationDetailDTO>>(`/applications/${id}`);
      return data.data;
    },
    enabled: !!id,
  });
}

export function useCreateApplication() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async (request: CreateApplicationRequest) => {
      const { data } = await apiClient.post<ApiResponse<ApplicationDetailDTO>>("/applications", request);
      return data.data;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: QUERY_KEYS.APPLICATIONS.ALL });
    },
  });
}

export function useUpdateApplicationStatus() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async ({ id, status, note }: { id: string; status: ApplicationStatus; note?: string }) => {
      const { data } = await apiClient.patch<ApiResponse<ApplicationDetailDTO>>(`/applications/${id}/status`, {
        status,
        note,
      });
      return data.data;
    },
    onSuccess: (data) => {
      queryClient.invalidateQueries({ queryKey: QUERY_KEYS.APPLICATIONS.DETAIL(data.id) });
      queryClient.invalidateQueries({ queryKey: QUERY_KEYS.APPLICATIONS.ALL });
    },
  });
}
