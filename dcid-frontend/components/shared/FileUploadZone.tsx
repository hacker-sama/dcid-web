"use client";

import React, { useCallback, useState } from "react";
import { UploadCloud, X, File as FileIcon } from "lucide-react";
import { cn } from "@/lib/utils";

interface FileUploadZoneProps {
  onFilesSelected?: (files: globalThis.File[]) => void;
  onFileSelect?: (file: globalThis.File) => void;
  maxFileSizeMB?: number;
  acceptedTypes?: string[];
  maxFiles?: number;
  disabled?: boolean;
}

const DEFAULT_ACCEPTED_TYPES = ["application/pdf", "image/jpeg", "image/png"];

function formatFileSize(bytes: number) {
  if (bytes >= 1024 * 1024) {
    return `${(bytes / (1024 * 1024)).toFixed(1)} MB`;
  }
  return `${Math.round(bytes / 1024)} KB`;
}

export function FileUploadZone({
  onFilesSelected,
  onFileSelect,
  maxFileSizeMB = 10,
  acceptedTypes = DEFAULT_ACCEPTED_TYPES,
  maxFiles = 5,
  disabled = false,
}: FileUploadZoneProps) {
  const [isDragActive, setIsDragActive] = useState(false);
  const [selectedFiles, setSelectedFiles] = useState<File[]>([]);
  const [errors, setErrors] = useState<string[]>([]);

  const acceptedString = acceptedTypes.join(",");

  const validateFile = useCallback(
    (file: File) => {
      const fileErrors: string[] = [];

      if (file.size > maxFileSizeMB * 1024 * 1024) {
        fileErrors.push(`File ${file.name} vượt quá ${maxFileSizeMB}MB`);
      }

      const isAccepted = acceptedTypes.some((type) => {
        if (type.endsWith("/*")) {
          return file.type.startsWith(type.replace("/*", ""));
        }
        return file.type === type;
      });

      if (!isAccepted) {
        fileErrors.push(`File ${file.name} không đúng định dạng`);
      }

      return fileErrors;
    },
    [acceptedTypes, maxFileSizeMB]
  );

  const updateFiles = useCallback(
    (incoming: File[]) => {
      if (disabled) return;

      const newErrors: string[] = [];
      const validatedFiles: File[] = [];

      const availableSlots = Math.max(maxFiles - selectedFiles.length, 0);
      const filesToCheck = incoming.slice(0, availableSlots);

      if (incoming.length > availableSlots) {
        newErrors.push(`Chỉ được chọn tối đa ${maxFiles} file`);
      }

      filesToCheck.forEach((file) => {
        const fileErrors = validateFile(file);
        if (fileErrors.length === 0) {
          validatedFiles.push(file);
        } else {
          newErrors.push(...fileErrors);
        }
      });

      if (newErrors.length > 0) {
        setErrors(newErrors);
      } else {
        setErrors([]);
      }

      if (validatedFiles.length > 0) {
        const nextFiles = [...selectedFiles, ...validatedFiles];
        setSelectedFiles(nextFiles);
        onFilesSelected?.(nextFiles);
        if (validatedFiles.length === 1) {
          onFileSelect?.(validatedFiles[0]);
        }
      }
    },
    [disabled, maxFiles, selectedFiles, onFilesSelected, validateFile]
  );

  const handleDrag = useCallback((e: React.DragEvent<HTMLDivElement>) => {
    e.preventDefault();
    e.stopPropagation();

    if (disabled) return;
    if (e.type === "dragenter" || e.type === "dragover") {
      setIsDragActive(true);
    } else if (e.type === "dragleave") {
      setIsDragActive(false);
    }
  }, [disabled]);

  const handleDrop = useCallback(
    (e: React.DragEvent<HTMLDivElement>) => {
      e.preventDefault();
      e.stopPropagation();
      setIsDragActive(false);
      if (disabled) return;

      const files = Array.from(e.dataTransfer.files);
      if (files.length > 0) {
        updateFiles(files);
      }
    },
    [disabled, updateFiles]
  );

  const handleChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    if (disabled) return;
    const files = e.target.files ? Array.from(e.target.files) : [];
    if (files.length > 0) {
      updateFiles(files);
    }
    e.target.value = "";
  };

  const handleRemove = useCallback(
    (index: number) => {
      const nextFiles = selectedFiles.filter((_, idx) => idx !== index);
      setSelectedFiles(nextFiles);
      onFilesSelected?.(nextFiles);
    },
    [onFilesSelected, selectedFiles]
  );

  const hasErrors = errors.length > 0;

  return (
    <div className="w-full">
      <div
        className={cn(
          "relative flex flex-col items-center justify-center gap-3 rounded-xl border-2 border-dashed p-6 text-center transition-colors",
          disabled ? "cursor-not-allowed opacity-60" : "cursor-pointer",
          isDragActive ? "border-primary bg-primary/5" : "border-muted-foreground/40 bg-muted/50 hover:border-primary hover:bg-primary/5",
          hasErrors ? "border-destructive bg-destructive/10" : ""
        )}
        onDragEnter={handleDrag}
        onDragLeave={handleDrag}
        onDragOver={handleDrag}
        onDrop={handleDrop}
      >
        <input
          type="file"
          multiple
          accept={acceptedString}
          disabled={disabled}
          className="absolute inset-0 h-full w-full cursor-pointer opacity-0"
          onChange={handleChange}
        />
        <UploadCloud className="h-10 w-10 text-primary" />
        <div>
          <p className="text-sm font-semibold text-foreground">Kéo thả file hoặc nhấp để chọn</p>
          <p className="text-xs text-muted-foreground">
            Định dạng: {acceptedTypes.join(", ")} · Tối đa {maxFileSizeMB}MB · {maxFiles} file
          </p>
        </div>
      </div>

      {hasErrors && (
        <div className="mt-3 space-y-1 rounded-lg border border-destructive/30 bg-destructive/10 p-3 text-sm text-destructive">
          {errors.map((error, index) => (
            <p key={`${error}-${index}`}>{error}</p>
          ))}
        </div>
      )}

      {selectedFiles.length > 0 && (
        <div className="mt-4 space-y-3">
          {selectedFiles.map((file, index) => (
            <div key={`${file.name}-${file.size}-${index}`} className="flex items-center gap-3 rounded-2xl border border-border bg-background p-3">
              <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-muted">
                <FileIcon className="h-5 w-5 text-primary" />
              </div>
              <div className="min-w-0 flex-1">
                <p className="truncate text-sm font-medium text-foreground">{file.name}</p>
                <p className="text-xs text-muted-foreground">{formatFileSize(file.size)}</p>
              </div>
              <button
                type="button"
                aria-label={`Xóa ${file.name}`}
                onClick={() => handleRemove(index)}
                className="inline-flex h-9 w-9 items-center justify-center rounded-lg border border-border bg-transparent text-muted-foreground transition hover:bg-muted"
              >
                <X className="h-4 w-4" />
              </button>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
