import { useQuery } from "@tanstack/react-query";
import apiClient from "@/lib/api-client";
import { QUERY_KEYS } from "@/constants/query-keys";
import { ApiResponse } from "@/types/api";
import { NotificationDTO } from "@/types/notification";

export function useNotifications() {
  return useQuery<NotificationDTO[]>({
    queryKey: QUERY_KEYS.NOTIFICATIONS.ALL,
    queryFn: async () => {
      try {
        const { data } = await apiClient.get<ApiResponse<NotificationDTO[]>>("/notifications");
        return data.data;
      } catch (error) {
        return [];
      }
    },
    refetchInterval: 30000,
  });
}

export function useUnreadNotificationCount() {
  return useQuery({
    queryKey: QUERY_KEYS.NOTIFICATIONS.UNREAD_COUNT,
    queryFn: async () => {
      try {
        const { data } = await apiClient.get<ApiResponse<number>>("/notifications/unread-count");
        return data.data;
      } catch (error) {
        return 0;
      }
    },
    refetchInterval: 30000,
  });
}
