"use client";

import React, { useCallback, useState } from "react";
import { UploadCloud, X, File, FileImage } from "lucide-react";
import { cn } from "@/lib/utils";

interface FileUploadZoneProps {
  onFileSelect: (file: File) => void;
  accept?: string;
  maxSizeMB?: number;
  disabled?: boolean;
}

export function FileUploadZone({ 
  onFileSelect, 
  accept = "image/*,application/pdf", 
  maxSizeMB = 10,
  disabled = false
}: FileUploadZoneProps) {
  const [isDragActive, setIsDragActive] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const handleDrag = useCallback((e: React.DragEvent) => {
    e.preventDefault();
    e.stopPropagation();
    if (e.type === "dragenter" || e.type === "dragover") {
      setIsDragActive(true);
    } else if (e.type === "dragleave") {
      setIsDragActive(false);
    }
  }, []);

  const validateFile = (file: File): boolean => {
    setError(null);
    if (file.size > maxSizeMB * 1024 * 1024) {
      setError(`Kích thước file không được vượt quá ${maxSizeMB}MB`);
      return false;
    }
    // Basic accept validation
    if (accept !== "*") {
      const acceptedTypes = accept.split(",").map(t => t.trim());
      const isAccepted = acceptedTypes.some(type => {
        if (type.endsWith("/*")) {
          return file.type.startsWith(type.replace("/*", ""));
        }
        return file.type === type || file.name.endsWith(type);
      });
      if (!isAccepted) {
        setError(`Định dạng file không được hỗ trợ`);
        return false;
      }
    }
    return true;
  };

  const handleDrop = useCallback((e: React.DragEvent) => {
    e.preventDefault();
    e.stopPropagation();
    setIsDragActive(false);
    if (disabled) return;

    if (e.dataTransfer.files && e.dataTransfer.files[0]) {
      const file = e.dataTransfer.files[0];
      if (validateFile(file)) {
        onFileSelect(file);
      }
    }
  }, [disabled, onFileSelect, maxSizeMB, accept]);

  const handleChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    e.preventDefault();
    if (e.target.files && e.target.files[0]) {
      const file = e.target.files[0];
      if (validateFile(file)) {
        onFileSelect(file);
      }
    }
  };

  return (
    <div className="w-full">
      <div 
        className={cn(
          "relative flex flex-col items-center justify-center p-6 border-2 border-dashed rounded-lg transition-colors",
          isDragActive ? "border-primary bg-primary/5" : "border-muted-foreground/25 bg-muted/50 hover:bg-muted",
          disabled ? "opacity-50 cursor-not-allowed" : "cursor-pointer",
          error && "border-danger text-danger bg-danger/5"
        )}
        onDragEnter={handleDrag}
        onDragLeave={handleDrag}
        onDragOver={handleDrag}
        onDrop={handleDrop}
      >
        <input 
          type="file" 
          accept={accept} 
          className="absolute inset-0 w-full h-full opacity-0 cursor-pointer disabled:cursor-not-allowed"
          onChange={handleChange}
          disabled={disabled}
        />
        
        <UploadCloud className="w-10 h-10 mb-3 text-muted-foreground" />
        <p className="mb-1 text-sm font-semibold">
          <span className="text-primary">Bấm để tải lên</span> hoặc kéo thả file vào đây
        </p>
        <p className="text-xs text-muted-foreground">
          PDF, PNG, JPG (Tối đa {maxSizeMB}MB)
        </p>
      </div>
      
      {error && (
        <p className="mt-2 text-sm text-danger">{error}</p>
      )}
    </div>
  );
}
