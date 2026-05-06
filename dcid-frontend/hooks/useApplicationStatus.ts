import { useEffect, useState } from "react";
import { wsManager } from "@/lib/websocket";
import { useSession } from "next-auth/react";
import { useQueryClient } from "@tanstack/react-query";
import { QUERY_KEYS } from "@/constants/query-keys";

export function useApplicationStatus(applicationId: string) {
  const { data: session } = useSession();
  const queryClient = useQueryClient();
  const [isConnected, setIsConnected] = useState(false);
  const [lastEvent, setLastEvent] = useState<any>(null);

  useEffect(() => {
    if (!session?.accessToken || !applicationId) return;

    // Connect to WebSocket
    const wsUrl = process.env.NEXT_PUBLIC_WS_URL || "ws://localhost:8080/ws";
    wsManager.connect(wsUrl, session.accessToken);
    setIsConnected(true);

    // Subscribe to specific application topic
    const topic = `/topic/applications/${applicationId}`;
    
    const unsubscribe = wsManager.subscribe(topic, (data) => {
      setLastEvent(data);
      
      // Invalidate queries to refresh data
      queryClient.invalidateQueries({
        queryKey: QUERY_KEYS.APPLICATIONS.DETAIL(applicationId)
      });
      queryClient.invalidateQueries({
        queryKey: QUERY_KEYS.APPLICATIONS.ALL
      });
    });

    return () => {
      unsubscribe();
      // Optional: disconnect if this is the only subscriber, but usually 
      // we keep it alive or let a higher level component manage connection.
    };
  }, [applicationId, session?.accessToken, queryClient]);

  return { isConnected, lastEvent };
}
