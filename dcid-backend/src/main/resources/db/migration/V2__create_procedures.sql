-- V2__create_procedures.sql

CREATE TABLE procedure_types (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code VARCHAR(100) NOT NULL UNIQUE,
    name VARCHAR(500) NOT NULL,
    description TEXT,
    json_schema TEXT NOT NULL,
    estimated_days INTEGER NOT NULL DEFAULT 7,
    fee NUMERIC(15,2) NOT NULL DEFAULT 0,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

CREATE TRIGGER trg_procedure_types_updated_at
BEFORE UPDATE ON procedure_types
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

INSERT INTO procedure_types (code, name, description, json_schema, estimated_days, fee)
VALUES (
  'HK_DANG_KY_THUONG_TRU',
  'Đăng ký thường trú',
  'Thủ tục đăng ký thường trú tại địa phương',
  '{
    "fields": [
      {"key": "ho_ten", "label": "Họ và tên", "type": "string", "required": true},
      {"key": "ngay_sinh", "label": "Ngày sinh", "type": "string", "format": "date", "required": true},
      {"key": "so_cccd", "label": "Số CCCD", "type": "string", "required": true},
      {"key": "dia_chi_cu", "label": "Địa chỉ cũ", "type": "string", "required": true},
      {"key": "dia_chi_moi", "label": "Địa chỉ mới", "type": "string", "required": true},
      {"key": "ly_do", "label": "Lý do chuyển", "type": "string", "required": false}
    ]
  }',
  15, 0
);

INSERT INTO procedure_types (code, name, description, json_schema, estimated_days, fee)
VALUES (
  'XD_CAP_GIAY_PHEP_XAY_DUNG',
  'Cấp giấy phép xây dựng nhà ở riêng lẻ',
  'Thủ tục cấp phép xây dựng nhà ở riêng lẻ tại đô thị',
  '{
    "fields": [
      {"key": "chu_dau_tu", "label": "Chủ đầu tư", "type": "string", "required": true},
      {"key": "dia_chi_cong_trinh", "label": "Địa chỉ công trình", "type": "string", "required": true},
      {"key": "dien_tich_dat", "label": "Diện tích đất (m²)", "type": "number", "required": true},
      {"key": "so_tang", "label": "Số tầng", "type": "number", "required": true},
      {"key": "loai_cong_trinh", "label": "Loại công trình", "type": "string", "enum": ["Nhà ở", "Nhà kho", "Công trình khác"], "required": true}
    ]
  }',
  30, 150000
);
