import assert from "assert";
import { renderToStaticMarkup } from "react-dom/server";
import { PageHeader } from "./PageHeader";

const markup = renderToStaticMarkup(
  <PageHeader
    title="Trang ứng dụng"
    breadcrumb={[{ label: "Trang chủ", href: "/" }, { label: "Ứng dụng" }]}
  />
);
assert.ok(markup.includes("Trang ứng dụng"), "PageHeader should render title");
assert.ok(markup.includes("Trang chủ"), "PageHeader should render breadcrumb");
