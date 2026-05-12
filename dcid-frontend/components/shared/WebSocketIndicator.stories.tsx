import { WebSocketIndicator } from "./WebSocketIndicator";

export default {
  title: "Shared/WebSocketIndicator",
};

export const Connected = () => <WebSocketIndicator isConnected={true} />;
export const Disconnected = () => <WebSocketIndicator isConnected={false} />;
