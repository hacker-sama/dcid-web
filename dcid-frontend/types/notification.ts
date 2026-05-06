export interface NotificationDTO {
  id: string;
  userId: string;
  title: string;
  message: string;
  type: NotificationType;
  read: boolean;
  actionUrl?: string;
  createdAt: string;
}

export enum NotificationType {
  SYSTEM = "SYSTEM",
  APPLICATION_UPDATE = "APPLICATION_UPDATE",
  APPOINTMENT_REMINDER = "APPOINTMENT_REMINDER",
}
