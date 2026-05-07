"use client";

import React, { useRef, useState, useEffect } from "react";
import { Button } from "@/components/ui/button";
import { Eraser } from "lucide-react";

interface StepSignatureProps {
  signatureUrl: string | null;
  onChange: (url: string | null) => void;
  onNext: () => void;
  onBack: () => void;
}

export function StepSignature({ signatureUrl, onChange, onNext, onBack }: StepSignatureProps) {
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const [isDrawing, setIsDrawing] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [hasSignature, setHasSignature] = useState(!!signatureUrl);

  useEffect(() => {
    if (signatureUrl && canvasRef.current) {
      const ctx = canvasRef.current.getContext("2d");
      const img = new Image();
      img.onload = () => {
        if (ctx && canvasRef.current) {
          ctx.clearRect(0, 0, canvasRef.current.width, canvasRef.current.height);
          ctx.drawImage(img, 0, 0);
        }
      };
      img.src = signatureUrl;
    }
  }, [signatureUrl]);

  const startDrawing = (e: React.MouseEvent<HTMLCanvasElement> | React.TouchEvent<HTMLCanvasElement>) => {
    const canvas = canvasRef.current;
    if (!canvas) return;

    const rect = canvas.getBoundingClientRect();
    let clientX, clientY;

    if ("touches" in e) {
      clientX = e.touches[0].clientX;
      clientY = e.touches[0].clientY;
    } else {
      clientX = e.clientX;
      clientY = e.clientY;
    }

    const x = clientX - rect.left;
    const y = clientY - rect.top;

    const ctx = canvas.getContext("2d");
    if (ctx) {
      ctx.beginPath();
      ctx.moveTo(x, y);
      setIsDrawing(true);
      setError(null);
    }
  };

  const draw = (e: React.MouseEvent<HTMLCanvasElement> | React.TouchEvent<HTMLCanvasElement>) => {
    if (!isDrawing || !canvasRef.current) return;

    const rect = canvasRef.current.getBoundingClientRect();
    let clientX, clientY;

    if ("touches" in e) {
      clientX = e.touches[0].clientX;
      clientY = e.touches[0].clientY;
      e.preventDefault(); // prevent scrolling
    } else {
      clientX = e.clientX;
      clientY = e.clientY;
    }

    const x = clientX - rect.left;
    const y = clientY - rect.top;

    const ctx = canvasRef.current.getContext("2d");
    if (ctx) {
      ctx.lineTo(x, y);
      ctx.stroke();
      setHasSignature(true);
    }
  };

  const stopDrawing = () => {
    setIsDrawing(false);
    if (canvasRef.current && hasSignature) {
      onChange(canvasRef.current.toDataURL("image/png"));
    }
  };

  const clearSignature = () => {
    const canvas = canvasRef.current;
    if (canvas) {
      const ctx = canvas.getContext("2d");
      if (ctx) {
        ctx.clearRect(0, 0, canvas.width, canvas.height);
        onChange(null);
        setHasSignature(false);
      }
    }
  };

  const validateAndNext = () => {
    if (!hasSignature) {
      setError("Vui lòng ký tên xác nhận");
      return;
    }
    onNext();
  };

  return (
    <div className="p-6">
      <h3 className="text-lg font-semibold mb-4">Ký xác nhận</h3>
      <p className="text-sm text-muted-foreground mb-6">
        Vui lòng ký tên vào khung dưới đây để xác nhận tính chính xác của các thông tin và tài liệu đã cung cấp.
      </p>

      <div className="flex flex-col items-center">
        <div className="border-2 border-dashed border-primary/50 rounded-lg overflow-hidden bg-white shadow-sm relative">
          <canvas
            ref={canvasRef}
            width={400}
            height={200}
            className="touch-none cursor-crosshair bg-transparent"
            onMouseDown={startDrawing}
            onMouseMove={draw}
            onMouseUp={stopDrawing}
            onMouseLeave={stopDrawing}
            onTouchStart={startDrawing}
            onTouchMove={draw}
            onTouchEnd={stopDrawing}
          />
          {!hasSignature && (
            <div className="absolute inset-0 pointer-events-none flex items-center justify-center text-muted-foreground/30">
              <span className="text-2xl font-medium rotate-[-10deg]">Ký tên tại đây</span>
            </div>
          )}
        </div>
        
        {error && <p className="text-danger text-sm mt-2">{error}</p>}

        <Button 
          variant="outline" 
          size="sm" 
          onClick={clearSignature} 
          className="mt-4"
          type="button"
        >
          <Eraser className="w-4 h-4 mr-2" />
          Ký lại
        </Button>
      </div>

      <div className="mt-8 flex justify-between">
        <Button variant="outline" onClick={onBack}>Quay lại</Button>
        <Button onClick={validateAndNext}>Tiếp tục</Button>
      </div>
    </div>
  );
}
