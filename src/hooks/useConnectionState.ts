import { useCallback, useEffect, useState } from 'react';
import type { Bluetooth } from '../services/bluetooth';
import { ConnectionState, type StateEvent } from '../types/types';

export const useConnectionState = (bluetooth: Bluetooth) => {
  const [connectionState, setConnectionState] = useState(
    ConnectionState.DISCONNECTED
  );

  const onConnectionStateChange = useCallback(
    (event: StateEvent) => setConnectionState(event.connectionState),
    []
  );

  useEffect(() => {
    const unsubscribe = bluetooth.subscribeToConnectionState(
      onConnectionStateChange
    );

    return unsubscribe;
  }, [onConnectionStateChange, bluetooth]);

  return {
    isConnected: connectionState === ConnectionState.CONNECTED,
    connectionState,
  };
};
