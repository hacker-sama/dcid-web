import assert from "assert";
import { renderToStaticMarkup } from "react-dom/server";
import { DataTable, type Column } from "./DataTable";

interface ExampleRow {
  id: string;
  name: string;
  status: string;
}

const columns: Column<ExampleRow>[] = [
  { key: "id", header: "ID" },
  { key: "name", header: "Tên" },
  { key: "status", header: "Trạng thái" },
];

const data = [
  { id: "1", name: "Nguyễn Văn A", status: "Đã duyệt" },
];

const markup = renderToStaticMarkup(<DataTable columns={columns} data={data} />);
assert.ok(markup.includes("Nguyễn Văn A"), "DataTable should render row data");
assert.ok(markup.includes("Trạng thái"), "DataTable should render header text");
