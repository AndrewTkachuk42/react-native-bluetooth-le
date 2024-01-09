import { useCallback, useEffect, useState } from 'react';
import {
  AdapterState,
  type AdapterStateEvent,
  type AnyCallback,
} from '../types/types';
import type { Bluetooth } from '../services/bluetooth';

export const useAdapterState = (
  bluetooth: Bluetooth,
  onStateChange?: AnyCallback
) => {
  const [isEnabled, setIsEnabled] = useState(false);

  const isAdapterEnabled = useCallback(async () => {
    const result = await bluetooth.isEnabled();
    setIsEnabled(result.isEnabled);
  }, [bluetooth]);

  const onAdapterStateChange = useCallback(
    ({ adapterState }: AdapterStateEvent) => {
      setIsEnabled(adapterState === AdapterState.ON);
      onStateChange?.(adapterState);
    },
    [onStateChange]
  );

  useEffect(() => {
    isAdapterEnabled();
    const unsubscribe = bluetooth.subscribeToAdapterState(onAdapterStateChange);

    return unsubscribe;
  }, [onAdapterStateChange, isAdapterEnabled, bluetooth]);

  return {
    isEnabled,
  };
};
