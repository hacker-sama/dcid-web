import assert from "assert";
import { renderToStaticMarkup } from "react-dom/server";
import { StatusBadge } from "./StatusBadge";
import { ApplicationStatus } from "@/types/application";

const markup = renderToStaticMarkup(<StatusBadge status={ApplicationStatus.SUBMITTED} />);
assert.ok(markup.includes("Đã nộp"), "StatusBadge should render Vietnamese label");
assert.ok(markup.includes("bg-[#E8EFF9]"), "StatusBadge should include expected background color class");
