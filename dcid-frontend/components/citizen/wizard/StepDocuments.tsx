"use client";

import React, { useState } from "react";
import { RequiredDocumentDef } from "@/types/procedure";
import { FileUploadZone } from "@/components/shared/FileUploadZone";
import { Button } from "@/components/ui/button";
import { FileText, X, CheckCircle2 } from "lucide-react";

interface StepDocumentsProps {
  requiredDocs: RequiredDocumentDef[];
  documents: Record<string, File>;
  onChange: (docs: Record<string, File>) => void;
  onNext: () => void;
  onBack: () => void;
}

export function StepDocuments({ requiredDocs, documents, onChange, onNext, onBack }: StepDocumentsProps) {
  const [errors, setErrors] = useState<Record<string, string>>({});

  const handleFileSelect = (code: string, file: File) => {
    onChange({ ...documents, [code]: file });
    if (errors[code]) {
      const newErrors = { ...errors };
      delete newErrors[code];
      setErrors(newErrors);
    }
  };

  const removeFile = (code: string) => {
    const newDocs = { ...documents };
    delete newDocs[code];
    onChange(newDocs);
  };

  const validateAndNext = () => {
    const newErrors: Record<string, string> = {};
    requiredDocs.forEach((doc) => {
      if (doc.required && !documents[doc.code]) {
        newErrors[doc.code] = "Vui lòng tải lên tài liệu này";
      }
    });

    if (Object.keys(newErrors).length > 0) {
      setErrors(newErrors);
      return;
    }

    onNext();
  };

  return (
    <div className="p-6">
      <h3 className="text-lg font-semibold mb-4">Tài liệu đính kèm</h3>
      
      <div className="space-y-6">
        {requiredDocs.map((doc) => (
          <div key={doc.code} className="border rounded-lg p-4 bg-muted/20">
            <div className="flex justify-between mb-3">
              <div>
                <h4 className="font-medium text-sm flex items-center gap-2">
                  {doc.name}
                  {doc.required && <span className="text-danger">*</span>}
                  {documents[doc.code] && <CheckCircle2 className="w-4 h-4 text-success" />}
                </h4>
                {doc.description && (
                  <p className="text-xs text-muted-foreground mt-1">{doc.description}</p>
                )}
              </div>
            </div>
            
            {documents[doc.code] ? (
              <div className="flex items-center justify-between p-3 bg-background border rounded-md">
                <div className="flex items-center gap-3 overflow-hidden">
                  <div className="p-2 bg-primary/10 text-primary rounded-md">
                    <FileText className="w-4 h-4" />
                  </div>
                  <div className="truncate">
                    <p className="text-sm font-medium truncate">{documents[doc.code].name}</p>
                    <p className="text-xs text-muted-foreground">
                      {(documents[doc.code].size / 1024 / 1024).toFixed(2)} MB
                    </p>
                  </div>
                </div>
                <Button variant="ghost" size="icon" onClick={() => removeFile(doc.code)} className="text-muted-foreground hover:text-danger shrink-0">
                  <X className="w-4 h-4" />
                </Button>
              </div>
            ) : (
              <div className="mt-2">
                <FileUploadZone 
                  onFileSelect={(file) => handleFileSelect(doc.code, file)}
                />
                {errors[doc.code] && (
                  <p className="text-xs text-danger mt-2">{errors[doc.code]}</p>
                )}
              </div>
            )}
          </div>
        ))}
      </div>

      <div className="mt-8 flex justify-between">
        <Button variant="outline" onClick={onBack}>Quay lại</Button>
        <Button onClick={validateAndNext}>Tiếp tục</Button>
      </div>
    </div>
  );
}
