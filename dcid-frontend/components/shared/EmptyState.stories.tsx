import { EmptyState } from "./EmptyState";

export default {
  title: "Shared/EmptyState",
};

export const Default = () => (
  <EmptyState
    message="Chưa có dữ liệu"
    description="Hệ thống đang chờ dữ liệu mới từ bạn."
    action={{ label: "Tải lại", onClick: () => undefined }}
  />
);
