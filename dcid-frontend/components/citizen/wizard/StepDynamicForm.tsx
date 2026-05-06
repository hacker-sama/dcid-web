"use client";

import React, { useState } from "react";
import { JsonSchema } from "@/types/procedure";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Button } from "@/components/ui/button";
import { Checkbox } from "@/components/ui/checkbox";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";

interface StepDynamicFormProps {
  schema: JsonSchema;
  formData: Record<string, any>;
  onChange: (data: Record<string, any>) => void;
  onNext: () => void;
  onBack: () => void;
}

export function StepDynamicForm({ schema, formData, onChange, onNext, onBack }: StepDynamicFormProps) {
  const [errors, setErrors] = useState<Record<string, string>>({});

  const handleChange = (key: string, value: any) => {
    onChange({ ...formData, [key]: value });
    if (errors[key]) {
      const newErrors = { ...errors };
      delete newErrors[key];
      setErrors(newErrors);
    }
  };

  const validateAndNext = () => {
    const newErrors: Record<string, string> = {};
    if (schema.required) {
      schema.required.forEach((key) => {
        if (!formData[key]) {
          newErrors[key] = "Trường này là bắt buộc";
        }
      });
    }
    
    if (Object.keys(newErrors).length > 0) {
      setErrors(newErrors);
      return;
    }
    
    onNext();
  };

  return (
    <div className="p-6">
      <h3 className="text-lg font-semibold mb-4">{schema.title || "Chi tiết hồ sơ"}</h3>
      
      <div className="space-y-6">
        {Object.entries(schema.properties || {}).map(([key, field]) => {
          const isRequired = schema.required?.includes(key);
          
          return (
            <div key={key} className="space-y-2">
              <Label className="flex items-center gap-1">
                {field.title}
                {isRequired && <span className="text-danger">*</span>}
              </Label>
              
              {field.description && (
                <p className="text-xs text-muted-foreground mb-1">{field.description}</p>
              )}
              
              {field.type === "boolean" ? (
                <div className="flex items-center space-x-2">
                  <Checkbox 
                    id={key}
                    checked={!!formData[key]} 
                    onCheckedChange={(checked) => handleChange(key, checked)}
                  />
                  <Label htmlFor={key} className="text-sm font-normal">Xác nhận</Label>
                </div>
              ) : field.enum ? (
                <Select 
                  value={formData[key] || ""} 
                  onValueChange={(val) => handleChange(key, val)}
                >
                  <SelectTrigger className={errors[key] ? "border-danger" : ""}>
                    <SelectValue placeholder="Chọn một tùy chọn" />
                  </SelectTrigger>
                  <SelectContent>
                    {field.enum.map((opt) => (
                      <SelectItem key={opt} value={opt}>{opt}</SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              ) : (
                <Input 
                  type={field.format === "date" ? "date" : field.type === "number" ? "number" : "text"}
                  value={formData[key] || ""}
                  onChange={(e) => {
                    const val = field.type === "number" ? Number(e.target.value) : e.target.value;
                    handleChange(key, val);
                  }}
                  className={errors[key] ? "border-danger" : ""}
                />
              )}
              
              {errors[key] && (
                <p className="text-xs text-danger">{errors[key]}</p>
              )}
            </div>
          );
        })}
      </div>

      <div className="mt-8 flex justify-between">
        <Button variant="outline" onClick={onBack}>Quay lại</Button>
        <Button onClick={validateAndNext}>Tiếp tục</Button>
      </div>
    </div>
  );
}
