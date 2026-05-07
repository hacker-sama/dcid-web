type WebSocketListener = (data: any) => void;

class WebSocketManager {
  private static instance: WebSocketManager;
  private socket: WebSocket | null = null;
  private listeners: Map<string, Set<WebSocketListener>> = new Map();
  private reconnectAttempts = 0;
  private maxReconnectAttempts = 5;
  private isConnecting = false;

  private constructor() {}

  public static getInstance(): WebSocketManager {
    if (!WebSocketManager.instance) {
      WebSocketManager.instance = new WebSocketManager();
    }
    return WebSocketManager.instance;
  }

  public connect(url: string, token: string) {
    if (this.socket?.readyState === WebSocket.OPEN || this.isConnecting) {
      return;
    }

    this.isConnecting = true;
    try {
      const wsUrl = `${url}?token=${token}`;
      this.socket = new WebSocket(wsUrl);

      this.socket.onopen = () => {
        this.isConnecting = false;
        this.reconnectAttempts = 0;
        console.log("[WebSocket] Connected");
      };

      this.socket.onmessage = (event) => {
        try {
          const data = JSON.parse(event.data);
          const topic = data.topic || "general";
          this.notifyListeners(topic, data.payload);
        } catch (error) {
          console.error("[WebSocket] Failed to parse message", error);
        }
      };

      this.socket.onclose = () => {
        this.isConnecting = false;
        this.socket = null;
        this.handleReconnect(url, token);
      };

      this.socket.onerror = (error) => {
        console.error("[WebSocket] Error", error);
      };
    } catch (error) {
      this.isConnecting = false;
      this.handleReconnect(url, token);
    }
  }

  private handleReconnect(url: string, token: string) {
    if (this.reconnectAttempts < this.maxReconnectAttempts) {
      this.reconnectAttempts++;
      const timeout = Math.min(1000 * Math.pow(2, this.reconnectAttempts), 10000);
      console.log(`[WebSocket] Reconnecting in ${timeout}ms... (Attempt ${this.reconnectAttempts})`);
      setTimeout(() => this.connect(url, token), timeout);
    }
  }

  public subscribe(topic: string, listener: WebSocketListener) {
    if (!this.listeners.has(topic)) {
      this.listeners.set(topic, new Set());
    }
    this.listeners.get(topic)!.add(listener);

    return () => {
      this.listeners.get(topic)?.delete(listener);
    };
  }

  private notifyListeners(topic: string, data: any) {
    this.listeners.get(topic)?.forEach((listener) => listener(data));
    // Also notify global/wildcard listeners
    this.listeners.get("*")?.forEach((listener) => listener({ topic, data }));
  }

  public disconnect() {
    if (this.socket) {
      this.socket.close();
      this.socket = null;
    }
  }
}

export const wsManager = WebSocketManager.getInstance();
