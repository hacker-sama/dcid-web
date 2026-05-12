import assert from "assert";
import { renderToStaticMarkup } from "react-dom/server";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { NotificationBell } from "./NotificationBell";

const client = new QueryClient();
const markup = renderToStaticMarkup(
  <QueryClientProvider client={client}>
    <NotificationBell />
  </QueryClientProvider>
);
assert.ok(markup.includes("Thông báo"), "NotificationBell should render the notification trigger");
