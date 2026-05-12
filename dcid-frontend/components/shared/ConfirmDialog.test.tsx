import assert from "assert";
import { renderToStaticMarkup } from "react-dom/server";
import { ConfirmDialog } from "./ConfirmDialog";

const markup = renderToStaticMarkup(
  <ConfirmDialog
    open={true}
    onOpenChange={() => undefined}
    title="Xác nhận"
    description="Bạn có muốn tiếp tục?"
    onConfirm={() => undefined}
  />
);
assert.ok(markup.includes("Xác nhận"), "ConfirmDialog should render title");
assert.ok(markup.includes("Bạn có muốn tiếp tục?"), "ConfirmDialog should render description");
