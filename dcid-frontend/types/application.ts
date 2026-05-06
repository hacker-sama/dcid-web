export enum ApplicationStatus {
  DRAFT = "DRAFT",
  SUBMITTED = "SUBMITTED",
  IN_REVIEW = "IN_REVIEW",
  PENDING_SUPPLEMENT = "PENDING_SUPPLEMENT",
  APPROVED = "APPROVED",
  REJECTED = "REJECTED",
  WITHDRAWN = "WITHDRAWN",
}

export interface ApplicationDTO {
  id: string;
  applicationCode: string;
  procedureCode: string;
  procedureName: string;
  applicantId: string;
  applicantName: string;
  status: ApplicationStatus;
  submittedAt?: string;
  createdAt: string;
  updatedAt: string;
}

export interface ApplicationDetailDTO extends ApplicationDTO {
  formData: Record<string, any>;
  documents: DocumentItemDTO[];
  statusHistory: StatusHistoryItem[];
  officerNote?: string;
}

export interface DocumentItemDTO {
  id: string;
  documentType: string;
  fileName: string;
  fileUrl: string;
  fileSize: number;
  uploadedAt: string;
}

export interface StatusHistoryItem {
  id: string;
  status: ApplicationStatus;
  changedBy: string;
  changedByName: string;
  note?: string;
  timestamp: string;
}

export interface CreateApplicationRequest {
  procedureCode: string;
  formData: Record<string, any>;
  documents: { documentType: string; fileUrl: string }[];
}
