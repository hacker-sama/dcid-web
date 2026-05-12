import { PageHeader } from "./PageHeader";

export default {
  title: "Shared/PageHeader",
};

export const Default = () => (
  <PageHeader
    title="Trang ứng dụng"
    breadcrumb={[
      { label: "Trang chủ", href: "/" },
      { label: "Ứng dụng" },
    ]}
    actions={<button className="rounded-md bg-primary px-3 py-2 text-white">Hành động</button>}
  />
);
