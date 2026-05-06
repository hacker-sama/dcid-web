export interface ApiResponse<T> {
  success: boolean;
  data: T;
  message?: string;
  timestamp: string;
}

export interface PagedResponse<T> {
  content: T[];
  totalElements: number;
  totalPages: number;
  size: number;
  number: number;
  first: boolean;
  last: boolean;
}

export interface ErrorResponse {
  success: false;
  message: string;
  errors?: FieldError[];
  timestamp: string;
  status: number;
}

export interface FieldError {
  field: string;
  message: string;
}

export interface PageParams {
  page?: number;
  size?: number;
  sort?: string;
}
