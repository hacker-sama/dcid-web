---
name: dcid-web-layout-density
description: Bắt buộc dùng skill này bất cứ khi nào viết, sửa, hoặc review một màn hình Flutter trong dự án dcid-app (Smart KCN Docs) có target build web (kiosk/admin), đặc biệt các màn của vai QA_ADMIN/ADMIN (danh sách tài liệu, quản lý version, audit log, dashboard). Cũng trigger khi user phàn nàn UI Flutter web "phình to", "trông như app mobile phóng to", "không đẹp bằng React", "quá nhiều khoảng trắng", hoặc khi tạo mới bất kỳ list/table/toolbar/FAB nào sẽ hiển thị trên breakpoint desktop. Áp dụng cả khi user không nói rõ "responsive" — nếu file đang sửa nằm trong lib/features/ và render trên web target, hãy tự kiểm tra theo skill này trước khi coi task là hoàn thành.
---

# dcid-app — Flutter Web Layout & Density

Dự án `dcid-app` là Flutter-only, build ra 2 target (Android + Web) từ 1 codebase (xem
`ARCHITECTURE.md` §0, §1). Widget mặc định của Flutter (Material) được tune cho ngón tay trên
điện thoại — bê nguyên sang web mà không chỉnh sẽ luôn cho ra UI "phình to, rỗng, giống app mobile
kéo giãn". Đây không phải bug hiếm gặp, đây là hành vi mặc định — nên **mọi màn hình có target web
phải đi qua checklist ở cuối skill này trước khi coi là xong.**

## 1. Nguyên tắc bắt buộc (áp dụng cho MỌI màn hình web)

### 1.1. Không bao giờ để content stretch full viewport width

Mỗi màn hình/route ở breakpoint ≥ `medium` (840dp) phải bọc nội dung chính trong constraint bề
rộng. Không tự chế lại — dùng widget dùng chung này (tạo ở `lib/core/constrained_content.dart` nếu
chưa có):

```dart
class ConstrainedContent extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  const ConstrainedContent({super.key, required this.child, this.maxWidth = 1000});

  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: child,
        ),
      );
}
```

Giá trị `maxWidth` theo loại nội dung — không dùng một số cho mọi màn:

| Loại màn hình | maxWidth khuyến nghị |
|---|---|
| Form (login, tạo/sửa document, upload) | 560–720 |
| List/detail dạng đọc (SOP, hướng dẫn) | 720–840 |
| **Bảng dữ liệu admin (documents, audit log, versions)** | 1200–1400, hoặc không giới hạn nếu bảng cần nhiều cột và có horizontal scroll riêng |

### 1.2. `VisualDensity.adaptivePlatformDensity` là bắt buộc trong `ThemeData`

```dart
ThemeData(
  visualDensity: VisualDensity.adaptivePlatformDensity,
  useMaterial3: true,
)
```

Nếu một widget cụ thể vẫn trông to sau khi bật density (VD: `ListTile`, `DataTable` mặc định), set
`dense: true` hoặc override `ListTileTheme`/`DataTableThemeData` riêng, không tăng padding thủ công
kiểu vá lỗi từng chỗ.

### 1.3. Breakpoints dùng chung — không tự chế số khác

Đã thống nhất ở lần trước, giữ nguyên hằng số này trong `lib/core/responsive.dart`:

```dart
class Breakpoints {
  static const double compact = 600;   // phone
  static const double medium = 840;    // tablet dọc
  static const double expanded = 1200; // desktop/web thường
  static const double large = 1600;    // ultra-wide / kiosk màn lớn
}
```

Rẽ nhánh layout bằng `LayoutBuilder` (constraints của parent), **không** dùng
`MediaQuery.of(context).size` khi widget có thể nằm lồng trong `Row`/split-view — sẽ sai kích thước.

## 2. Quy tắc chọn widget theo vai trò & mật độ dữ liệu (quan trọng nhất, hay bị bỏ qua)

Đây là lỗi lớn nhất quan sát được trong thực tế: dùng `ListView`/`ListTile` cho màn admin thay vì
bảng, dẫn tới mất cột trạng thái quan trọng và trông giống list mobile kéo dài.

| Vai trò | Loại màn | Widget bắt buộc |
|---|---|---|
| OPERATOR, ENGINEER (mobile, ≤ `compact`) | Tra cứu SOP, Search/Ask, Snap & Ask | `ListView`/`ListTile` — đúng, giữ nguyên |
| QA_ADMIN, ADMIN (web, ≥ `expanded`) | Danh sách/quản lý tài liệu, version, audit log, user management | **`data_table_2` hoặc `pluto_grid`** (đã chọn sẵn trong `ARCHITECTURE.md` §0, §9) — KHÔNG dùng `ListView`/`ListTile` |
| Bất kỳ vai nào ở breakpoint `medium` (tablet ngang) | Danh sách vừa phải, không cần hết cột | `ListTile` được, nhưng phải `dense: true` + `ConstrainedContent` |

Nếu đang viết một màn cho QA_ADMIN/ADMIN và thấy mình sắp dùng `ListView.builder` + `ListTile`, đó
là tín hiệu sai widget — dừng lại, dùng `DataTable2` với cột tối thiểu: Tên tài liệu · Loại/Category
· Version + trạng thái (chip màu theo ACTIVE/SUPERSEDED/OBSOLETE) · Ngày cập nhật · Hành động
(icon-only, không text button để tiết kiệm chiều rộng cột).

Bộ khung tối thiểu cho bảng admin:

```dart
DataTable2(
  columnSpacing: 24,
  horizontalMargin: 16,
  minWidth: 900,
  columns: const [
    DataColumn2(label: Text('Tên tài liệu'), size: ColumnSize.L),
    DataColumn2(label: Text('Loại')),
    DataColumn2(label: Text('Trạng thái')),
    DataColumn2(label: Text('Cập nhật')),
    DataColumn2(label: Text(''), size: ColumnSize.S), // hành động
  ],
  rows: documents.map((d) => DataRow2(cells: [
    DataCell(Text(d.name)),
    DataCell(Chip(label: Text(d.category), visualDensity: VisualDensity.compact)),
    DataCell(_StatusChip(status: d.status)),
    DataCell(Text(d.updatedAt)),
    DataCell(IconButton(icon: const Icon(Icons.more_vert), onPressed: () {})),
  ])).toList(),
)
```

## 3. Vị trí action buttons — không dùng FAB nổi cho màn admin dày dữ liệu

`FloatingActionButton` (pill nổi góc dưới phải) là pattern mobile. Trên màn web có toolbar/header,
đặt hành động chính (VD: "Tải tài liệu") vào **thanh công cụ trên đầu bảng**, cùng hàng với ô tìm
kiếm/filter — không thả nổi đè lên nội dung khi scroll.

```dart
Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    Expanded(child: TextField(decoration: const InputDecoration(hintText: 'Tìm tài liệu...'))),
    const SizedBox(width: 12),
    FilledButton.icon(
      icon: const Icon(Icons.upload_file),
      label: const Text('Tải tài liệu'),
      onPressed: () {},
    ),
  ],
)
```

Chỉ giữ `FloatingActionButton` cho breakpoint `compact` (mobile) nếu action đó cũng cần trên
điện thoại (thường không áp dụng cho các màn QA_ADMIN/ADMIN vì bảng vai trò §3 trong
`ARCHITECTURE.md` đã ghi rõ các màn này chỉ có trên web).

## 4. Navigation rail — đảm bảo đúng 1 mục active

Nếu tự build rail (không dùng `flutter_adaptive_scaffold`), `selectedIndex` phải là single source of
truth và mọi destination lấy trạng thái highlight từ đúng index đó — không set màu nền cứng theo
từng icon riêng lẻ, dễ dẫn tới 2 mục cùng "trông như đang chọn". Ưu tiên `NavigationRail` chuẩn của
Flutter thay vì tự vẽ từng icon + label:

```dart
NavigationRail(
  selectedIndex: selectedIndex,
  onDestinationSelected: onSelect,
  extended: width >= Breakpoints.large,
  destinations: const [
    NavigationRailDestination(icon: Icon(Icons.search), label: Text('Tra cứu')),
    NavigationRailDestination(icon: Icon(Icons.camera_alt_outlined), label: Text('Snap & Ask')),
    NavigationRailDestination(icon: Icon(Icons.folder_outlined), label: Text('Tài liệu')),
    NavigationRailDestination(icon: Icon(Icons.admin_panel_settings_outlined), label: Text('Quản trị')),
  ],
)
```

## 5. Pre-submit checklist — chạy trước khi báo task xong

Với bất kỳ file nào trong `lib/features/**` render trên web target, tự trả lời từng dòng trước khi
kết thúc turn:

- [ ] Nội dung chính có bọc trong `ConstrainedContent` (hoặc lý do rõ ràng vì sao không cần, VD:
      bảng cần full-width)?
- [ ] `ThemeData` áp dụng `VisualDensity.adaptivePlatformDensity`?
- [ ] Nếu màn thuộc QA_ADMIN/ADMIN và hiển thị danh sách bản ghi (>1 thuộc tính/row): đang dùng
      `data_table_2`/`pluto_grid`, không phải `ListView`/`ListTile`?
- [ ] Action chính của trang nằm trong toolbar/header, không phải FAB nổi (trừ khi màn đó cũng chạy
      trên `compact` breakpoint và cần FAB thật sự)?
- [ ] Rẽ nhánh layout dùng `LayoutBuilder` + hằng số trong `Breakpoints`, không hardcode số khác?
- [ ] Không import `dart:io`/`Platform` ở `core/`/`data/`/bất kỳ file nào dùng chung cho web (theo
      `ARCHITECTURE.md` §0.1, §9 — sẽ vỡ `flutter build web`)?

Nếu bất kỳ mục nào chưa đạt, sửa trước khi trả lời "đã xong" cho user.