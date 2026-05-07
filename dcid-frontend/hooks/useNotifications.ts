import { useQuery } from "@tanstack/react-query";
import apiClient from "@/lib/api-client";
import { QUERY_KEYS } from "@/constants/query-keys";
import { ApiResponse } from "@/types/api";

export function useUnreadNotificationCount() {
  return useQuery({
    queryKey: QUERY_KEYS.NOTIFICATIONS.UNREAD_COUNT,
    queryFn: async () => {
      // Mocking for now as the endpoint might not exist
      try {
        const { data } = await apiClient.get<ApiResponse<number>>("/notifications/unread-count");
        return data.data;
      } catch (error) {
        return 0; // fallback mock
      }
    },
    refetchInterval: 30000, // Poll every 30s
  });
}
