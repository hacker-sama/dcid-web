export const QUERY_KEYS = {
  APPLICATIONS: {
    ALL: ["applications"] as const,
    LIST: (filters: any) => ["applications", "list", filters] as const,
    DETAIL: (id: string) => ["applications", "detail", id] as const,
  },
  PROCEDURES: {
    ALL: ["procedures"] as const,
    LIST: (filters: any) => ["procedures", "list", filters] as const,
    DETAIL: (code: string) => ["procedures", "detail", code] as const,
  },
  NOTIFICATIONS: {
    ALL: ["notifications"] as const,
    UNREAD_COUNT: ["notifications", "unread_count"] as const,
  },
  DASHBOARD: {
    CITIZEN_STATS: ["dashboard", "citizen", "stats"] as const,
    OFFICER_STATS: ["dashboard", "officer", "stats"] as const,
    OFFICER_CHART: ["dashboard", "officer", "chart"] as const,
  },
  USERS: {
    PROFILE: ["users", "profile"] as const,
  }
};
