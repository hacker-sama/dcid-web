import assert from "assert";
import { renderToStaticMarkup } from "react-dom/server";
import { FileUploadZone } from "./FileUploadZone";

const markup = renderToStaticMarkup(<FileUploadZone onFilesSelected={() => undefined} />);
assert.ok(markup.includes("Kéo thả file hoặc nhấp để chọn"), "FileUploadZone should render the drop zone text");
assert.ok(markup.includes("Định dạng:"), "FileUploadZone should render accepted types information");
