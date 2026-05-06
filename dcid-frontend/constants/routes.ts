export const ROUTES = {
  HOME: "/",
  LOGIN: "/login",
  
  CITIZEN: {
    DASHBOARD: "/citizen/dashboard",
    PROCEDURES: "/citizen/procedures",
    PROCEDURE_DETAIL: (code: string) => `/citizen/procedures/${code}`,
    APPLICATIONS: "/citizen/applications",
    APPLICATION_NEW: (code: string) => `/citizen/applications/new/${code}`,
    APPLICATION_DETAIL: (id: string) => `/citizen/applications/${id}`,
    APPOINTMENTS: "/citizen/appointments",
    NOTIFICATIONS: "/citizen/notifications",
  },
  
  OFFICER: {
    DASHBOARD: "/officer/dashboard",
    APPLICATIONS: "/officer/applications",
    APPLICATION_DETAIL: (id: string) => `/officer/applications/${id}`,
    PROCEDURES: "/officer/procedures",
    USERS: "/officer/users",
    REPORTS: "/officer/reports",
    AUDIT_LOG: "/officer/audit-log",
  }
};
