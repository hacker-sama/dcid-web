export interface ProcedureTypeDTO {
  id: string;
  code: string;
  name: string;
  description: string;
  category: string;
  processingTimeDays: number;
  fee: number;
  formSchema: JsonSchema;
  requiredDocuments: RequiredDocumentDef[];
  active: boolean;
}

export interface JsonSchema {
  type: string;
  title: string;
  properties: Record<string, JsonSchemaField>;
  required?: string[];
}

export interface JsonSchemaField {
  type: string;
  title: string;
  description?: string;
  enum?: string[];
  format?: string;
  minimum?: number;
  maximum?: number;
  pattern?: string;
}

export interface RequiredDocumentDef {
  code: string;
  name: string;
  description?: string;
  required: boolean;
}
