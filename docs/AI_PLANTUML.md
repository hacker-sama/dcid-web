# Sơ Đồ PlantUML (`.puml`) — AI Processing DCID: Digital Cognitive InDustrial System

Dưới đây là toàn bộ mã nguồn chuẩn **PlantUML** cho các sơ đồ luồng xử lý AI của dự án (đã tương thích 100% mọi phiên bản PlantUML, không cần khai báo theme ngoài). Bạn có thể copy trực tiếp vào [PlantText / PlantUML Web](https://www.planttext.com/) hoặc extension PlantUML trong VS Code để vẽ/xuất ảnh `.png`/`.svg`.

---

## 1. Sơ Đồ Khối Cơ Bản (`ai_processing.puml`)

Copy đoạn code bên dưới (hoặc mở file `docs/ai_processing.puml`):

```plantuml
@startuml ai_block_diagram
skinparam backgroundColor #0F172A
skinparam defaultFontColor #F8FAFC
skinparam ArrowColor #38BDF8
skinparam packageBorderColor #38BDF8
skinparam packageFontColor #38BDF8
skinparam rectangle {
    BackgroundColor #1E293B
    BorderColor #38BDF8
    FontColor #F8FAFC
}

package "1. Đầu Vào (Nhà Xưởng)" as Input {
    rectangle "🖼️ Hình Ảnh / Bản Vẽ Kỹ Thuật" as Img
    rectangle "❓ Câu Hỏi / Yêu Cầu Của Kỹ Sư" as Q
}

package "2. Bóc Tách Hình Ảnh" as OCR_Layer {
    rectangle "👁️ AI OCR: PaddleOCR + PyMuPDF\n(Bóc Tách Chữ, Số, Kích Thước, Bbox)" as OCR
}

package "3. AI Model Local (Suy Luận & Trả Lời)" as LLM_Layer {
    rectangle "🧠 LM Studio: Qwen 1.5B Local\n(Suy Luận Kỹ Thuật & Cầm Tay Chỉ Việc)" as LLM
}

package "4. Đầu Ra" as Output {
    rectangle "💡 Hướng Dẫn Thao Tác Chi Tiết\n(Tường Minh + Trích Dẫn Trang)" as Ans
}

package "Tầng Bộ Nhớ Lịch Sử (Bổ Trợ)" as Storage {
    rectangle "🧬 e5-small Embedding" as EMB
    rectangle "🗄️ ChromaDB Vector Store" as Chroma
}

Img --> OCR : 1. Đưa hình ảnh vào bóc tách
OCR ===> LLM : 2. Gửi dữ liệu thông số OCR
Q ===> LLM : 3. Câu hỏi tra cứu
LLM ===> Ans : 4. Trả lời chuyên sâu

OCR ..> EMB : Lưu trữ lâu dài
EMB ..> Chroma
Chroma ..> LLM : Tra cứu lại tài liệu cũ
@enduml
```

---

## 2. Sơ Đồ Tuần Tự (`ai_sequence.puml`)

Copy đoạn code bên dưới (hoặc mở file `docs/ai_sequence.puml`):

```plantuml
@startuml ai_sequence_diagram
skinparam backgroundColor #0F172A
skinparam defaultFontColor #F8FAFC
skinparam ArrowColor #38BDF8
skinparam ActorFontColor #F8FAFC
skinparam ParticipantBackgroundColor #1E293B
skinparam ParticipantBorderColor #38BDF8
skinparam ParticipantFontColor #F8FAFC
skinparam NoteBackgroundColor #1E293B
skinparam NoteBorderColor #38BDF8
skinparam NoteFontColor #F8FAFC
skinparam GroupHeaderFontColor #38BDF8
skinparam GroupBorderColor #38BDF8

autonumber

actor "Kỹ Sư / Xưởng" as User
participant "Flutter App (:3000)" as App
participant "Spring Boot BE (:8080)" as BE
participant "dcid-ai-ocr (:8001)" as OCR
participant "LM Studio (:1234)" as LLM
participant "ChromaDB\n(Bộ nhớ bổ trợ)" as DB

note over User, LLM : LUỒNG CỐT LÕI: BÓC TÁCH HÌNH ẢNH -> AI LOCAL SUY LUẬN TRẢ LỜI

User -> App : Gửi hình ảnh bản vẽ / tài liệu + Câu hỏi ("Giải thích thông số bản vẽ này")
App -> BE : Truyền ảnh và câu hỏi

group BƯỚC 1: BÓC TÁCH HÌNH ẢNH QUA OCR
    BE -> OCR : POST /ocr/extract (Hình ảnh / PDF bản vẽ)
    note right of OCR
        PyMuPDF dựng ảnh RGB 200 DPI
        PaddleOCR bóc tách ký tự, số, dung sai
    end note
    OCR --> BE : Trả về văn bản thông số bóc tách (PageOcr Text + Bounding Box)
end

group BƯỚC 2: GỬI DỮ LIỆU OCR VỀ AI MODEL LOCAL ĐỂ SUY LUẬN
    BE -> LLM : Gửi Prompt (Chỉ thị + Dữ liệu OCR bóc tách được + Câu hỏi kỹ sư)
    note right of LLM
        AI Model Local (deepseek-r1-distill-qwen-1.5b)
        suy luận ý nghĩa kỹ thuật, chuẩn hóa lỗi OCR rớt dấu
    end note
    LLM --> BE : Trả về câu trả lời suy luận chi tiết kèm các bước thao tác
end

BE --> App : Trả kết quả hướng dẫn cho kỹ sư
App --> User : Hiển thị câu trả lời cầm tay chỉ việc ngay trên màn hình

note over BE, DB : BƯỚC BỔ TRỢ: LƯU TRỮ VÀO CHROMADB ĐỂ TRA CỨU SAU NÀY
BE -> DB : Nhúng và lưu vector các đoạn OCR bản vẽ vào ChromaDB để tái sử dụng

@enduml
```
