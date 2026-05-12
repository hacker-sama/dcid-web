import assert from "assert";
import { renderToStaticMarkup } from "react-dom/server";
import { WebSocketIndicator } from "./WebSocketIndicator";

const connectedMarkup = renderToStaticMarkup(<WebSocketIndicator isConnected={true} />);
assert.ok(connectedMarkup.includes("Đang kết nối realtime"), "WebSocketIndicator should render connected tooltip text");

const disconnectedMarkup = renderToStaticMarkup(<WebSocketIndicator isConnected={false} />);
assert.ok(disconnectedMarkup.includes("Mất kết nối realtime"), "WebSocketIndicator should render disconnected tooltip text");
