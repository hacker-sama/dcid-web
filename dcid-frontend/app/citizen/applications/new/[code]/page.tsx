"use client";

import React, { useState } from "react";
import { useRouter } from "next/navigation";
import { PageHeader } from "@/components/shared/PageHeader";
import { WizardLayout } from "@/components/citizen/wizard/WizardLayout";
import { StepPersonalInfo } from "@/components/citizen/wizard/StepPersonalInfo";
import { StepDynamicForm } from "@/components/citizen/wizard/StepDynamicForm";
import { StepDocuments } from "@/components/citizen/wizard/StepDocuments";
import { StepSignature } from "@/components/citizen/wizard/StepSignature";
import { StepConfirm } from "@/components/citizen/wizard/StepConfirm";
import { useProcedure } from "@/hooks/useProcedures";
import { useCreateApplication } from "@/hooks/useApplications";
import { useFileUpload } from "@/hooks/useFileUpload";
import { Skeleton } from "@/components/ui/skeleton";
import { ROUTES } from "@/constants/routes";
import { toast } from "sonner";

const STEPS = [
  { id: "personal_info", title: "Thông tin cá nhân" },
  { id: "form_data", title: "Chi tiết hồ sơ" },
  { id: "documents", title: "Tài liệu đính kèm" },
  { id: "signature", title: "Ký xác nhận" },
  { id: "confirm", title: "Hoàn tất" },
];

export default function NewApplicationPage({ params }: { params: { code: string } }) {
  const router = useRouter();
  const { data: procedure, isLoading: isProcedureLoading } = useProcedure(params.code);
  const { mutateAsync: createApplication } = useCreateApplication();
  const { uploadFile } = useFileUpload();

  const [currentStep, setCurrentStep] = useState(0);
  const [formData, setFormData] = useState<Record<string, any>>({});
  const [documents, setDocuments] = useState<Record<string, File>>({});
  const [signatureUrl, setSignatureUrl] = useState<string | null>(null);
  const [isSubmitting, setIsSubmitting] = useState(false);

  if (isProcedureLoading) {
    return (
      <div className="space-y-6">
        <Skeleton className="h-10 w-1/3" />
        <Skeleton className="h-[500px] w-full" />
      </div>
    );
  }

  if (!procedure) {
    return <div className="text-center py-12 text-danger">Không tìm thấy thủ tục</div>;
  }

  const handleNext = () => setCurrentStep(prev => Math.min(prev + 1, STEPS.length - 1));
  const handleBack = () => setCurrentStep(prev => Math.max(prev - 1, 0));

  const handleSubmit = async () => {
    setIsSubmitting(true);
    try {
      // 1. Upload signature
      let uploadedSignatureUrl = "";
      if (signatureUrl) {
        const sigRes = await uploadFile(signatureUrl, "signature");
        if (sigRes) uploadedSignatureUrl = sigRes.fileUrl;
      }

      // 2. Upload documents
      const uploadedDocs: { documentType: string; fileUrl: string }[] = [];
      for (const [code, file] of Object.entries(documents)) {
        const docRes = await uploadFile(file, "document");
        if (docRes) {
          uploadedDocs.push({
            documentType: code,
            fileUrl: docRes.fileUrl,
          });
        }
      }

      // Add signature as a document if uploaded
      if (uploadedSignatureUrl) {
        uploadedDocs.push({
          documentType: "SIGNATURE",
          fileUrl: uploadedSignatureUrl,
        });
      }

      // 3. Create application
      const result = await createApplication({
        procedureCode: params.code,
        formData,
        documents: uploadedDocs,
      });

      toast.success("Nộp hồ sơ thành công!");
      router.push(ROUTES.CITIZEN.APPLICATION_DETAIL(result.id));
    } catch (error: any) {
      toast.error(error?.response?.data?.message || "Có lỗi xảy ra khi nộp hồ sơ");
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <div className="space-y-6">
      <PageHeader 
        title="Nộp hồ sơ mới" 
        breadcrumbs={[
          { label: "Tổng quan", href: ROUTES.CITIZEN.DASHBOARD },
          { label: "Thủ tục hành chính", href: ROUTES.CITIZEN.PROCEDURES },
          { label: procedure.name, href: ROUTES.CITIZEN.PROCEDURE_DETAIL(procedure.code) },
          { label: "Nộp hồ sơ" }
        ]}
      />

      <WizardLayout steps={STEPS} currentStep={currentStep} title={procedure.name}>
        {currentStep === 0 && <StepPersonalInfo onNext={handleNext} />}
        {currentStep === 1 && (
          <StepDynamicForm 
            schema={procedure.formSchema} 
            formData={formData} 
            onChange={setFormData} 
            onNext={handleNext} 
            onBack={handleBack} 
          />
        )}
        {currentStep === 2 && (
          <StepDocuments 
            requiredDocs={procedure.requiredDocuments || []} 
            documents={documents} 
            onChange={setDocuments} 
            onNext={handleNext} 
            onBack={handleBack} 
          />
        )}
        {currentStep === 3 && (
          <StepSignature 
            signatureUrl={signatureUrl} 
            onChange={setSignatureUrl} 
            onNext={handleNext} 
            onBack={handleBack} 
          />
        )}
        {currentStep === 4 && (
          <StepConfirm 
            isSubmitting={isSubmitting} 
            onConfirm={handleSubmit} 
            onBack={handleBack} 
          />
        )}
      </WizardLayout>
    </div>
  );
}
