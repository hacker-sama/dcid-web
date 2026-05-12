import { ConfirmDialog } from "./ConfirmDialog";
import { useState } from "react";

export default {
  title: "Shared/ConfirmDialog",
};

export const Default = () => {
  const [open, setOpen] = useState(true);
  return (
    <ConfirmDialog
      open={open}
      onOpenChange={setOpen}
      title="Xác nhận hành động"
      description="Bạn có chắc chắn muốn tiếp tục?"
      onConfirm={() => undefined}
    />
  );
};
