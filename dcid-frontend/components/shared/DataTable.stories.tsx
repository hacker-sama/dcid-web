import { DataTable, type Column } from "./DataTable";

interface ExampleRow {
  id: string;
  name: string;
  status: string;
}

const columns: Column<ExampleRow>[] = [
  { key: "id", header: "ID", width: "w-24", sortable: true },
  { key: "name", header: "Tên", sortable: true },
  { key: "status", header: "Trạng thái" },
];

const data: ExampleRow[] = [
  { id: "1", name: "Nguyễn Văn A", status: "Đang xử lý" },
  { id: "2", name: "Trần Thị B", status: "Đã duyệt" },
];

export default {
  title: "Shared/DataTable",
};

export const Default = () => <DataTable columns={columns} data={data} />;
