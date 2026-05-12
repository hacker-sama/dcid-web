import assert from "assert";
import { renderToStaticMarkup } from "react-dom/server";
import { LoadingSkeleton } from "./LoadingSkeleton";

const markup = renderToStaticMarkup(<LoadingSkeleton rows={4} />);
assert.ok(markup.match(/animate-pulse/g)?.length === 4, "LoadingSkeleton should render the correct number of rows");
