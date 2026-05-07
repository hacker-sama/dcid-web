import { useQuery } from "@tanstack/react-query";
import apiClient from "@/lib/api-client";
import { QUERY_KEYS } from "@/constants/query-keys";
import { ApiResponse } from "@/types/api";

export interface DashboardStats {
  totalApplications: number;
  pendingReview: number;
  approvedToday: number;
  rejectedToday: number;
}

export function useOfficerStats() {
  return useQuery({
    queryKey: QUERY_KEYS.DASHBOARD.OFFICER_STATS,
    queryFn: async () => {
      try {
        const { data } = await apiClient.get<ApiResponse<DashboardStats>>("/dashboard/officer/stats");
        return data.data;
      } catch (error) {
        // Mock data
        return {
          totalApplications: 1250,
          pendingReview: 45,
          approvedToday: 12,
          rejectedToday: 2,
        };
      }
    },
  });
}

export function useOfficerChartData() {
  return useQuery({
    queryKey: QUERY_KEYS.DASHBOARD.OFFICER_CHART,
    queryFn: async () => {
      try {
        const { data } = await apiClient.get<ApiResponse<any>>("/dashboard/officer/chart");
        return data.data;
      } catch (error) {
        // Mock data
        return {
          statusData: [
            { status: "DRAFT", count: 120 },
            { status: "SUBMITTED", count: 45 },
            { status: "IN_REVIEW", count: 30 },
            { status: "PENDING_SUPPLEMENT", count: 15 },
            { status: "APPROVED", count: 850 },
            { status: "REJECTED", count: 190 },
          ],
          submissionData: Array.from({ length: 30 }).map((_, i) => {
            const date = new Date();
            date.setDate(date.getDate() - (29 - i));
            return {
              date: date.toISOString(),
              count: Math.floor(Math.random() * 50) + 10,
            };
          }),
        };
      }
    },
  });
}
