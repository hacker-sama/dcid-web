import assert from "assert";
import { renderToStaticMarkup } from "react-dom/server";
import { EmptyState } from "./EmptyState";

const markup = renderToStaticMarkup(
  <EmptyState message="Chưa có dữ liệu" description="Mô tả" action={{ label: "Tải lại", onClick: () => undefined }} />
);
assert.ok(markup.includes("Chưa có dữ liệu"), "EmptyState should render the message");
assert.ok(markup.includes("Tải lại"), "EmptyState should render the action label");
