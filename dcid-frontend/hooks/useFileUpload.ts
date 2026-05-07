import { useState } from "react";
import apiClient from "@/lib/api-client";
import { ApiResponse } from "@/types/api";

interface UploadResponse {
  fileUrl: string;
  fileName: string;
  fileSize: number;
}

export function useFileUpload() {
  const [isUploading, setIsUploading] = useState(false);
  const [progress, setProgress] = useState(0);
  const [error, setError] = useState<string | null>(null);

  const uploadFile = async (file: File | string, type: "document" | "signature" = "document"): Promise<UploadResponse | null> => {
    setIsUploading(true);
    setProgress(0);
    setError(null);

    try {
      const formData = new FormData();
      
      if (typeof file === "string") {
        // It's a base64 signature
        const res = await fetch(file);
        const blob = await res.blob();
        formData.append("file", blob, "signature.png");
      } else {
        formData.append("file", file);
      }
      
      formData.append("type", type);

      const { data } = await apiClient.post<ApiResponse<UploadResponse>>("/files/upload", formData, {
        headers: {
          "Content-Type": "multipart/form-data",
        },
        onUploadProgress: (progressEvent) => {
          const percentCompleted = Math.round((progressEvent.loaded * 100) / (progressEvent.total || 1));
          setProgress(percentCompleted);
        },
      });

      setIsUploading(false);
      return data.data;
    } catch (err: any) {
      setIsUploading(false);
      setError(err.response?.data?.message || "Lỗi tải file lên");
      return null;
    }
  };

  return {
    uploadFile,
    isUploading,
    progress,
    error,
  };
}
