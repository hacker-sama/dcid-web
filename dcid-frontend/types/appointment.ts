export interface AppointmentDTO {
  id: string;
  applicantId: string;
  applicantName: string;
  applicationId?: string;
  officeId: string;
  officeName: string;
  appointmentDate: string;
  timeSlot: string;
  status: AppointmentStatus;
  purpose: string;
  notes?: string;
  createdAt: string;
}

export enum AppointmentStatus {
  SCHEDULED = "SCHEDULED",
  COMPLETED = "COMPLETED",
  CANCELLED = "CANCELLED",
  NO_SHOW = "NO_SHOW",
}
