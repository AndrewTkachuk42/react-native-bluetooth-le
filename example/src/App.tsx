import React, { useCallback, useEffect } from 'react';

import { StyleSheet, View, Button } from 'react-native';
import type { DeviceData } from '../../src/types/types';
import bluetoothManager from '../../src/services/bluetooth';

const bluetooth = bluetoothManager.getInstance();

const deviceAddress = 'A8:42:E3:74:0C:EE';
const service = '7A6F10E0-DC05-11EC-9D64-0242AC120002';
const characteristicToWrite = '2DF9DA8C-47C4-4E0C-99F2-D90DFD5A4BC3';
const characteristicToRead = '5E427456-FD7C-4956-BDE8-1C275A7A1D9B';
const characteristicToNotify = '7FE6343D-C796-45B9-BCC8-D4EFDD9868F6';

export default function App() {
  const startScan = useCallback(async () => {
    const onDeviceFound = (device: DeviceData) => console.log({ device });

    const res = await bluetooth.startScan(onDeviceFound, { duration: 1 });

    console.log('scan result: ', res);
  }, []);

  const stopScan = useCallback(async () => {
    const res = await bluetooth.stopScan();

    console.log('stop scan result: ', res);
  }, []);

  const connect = useCallback(async () => {
    const res = await bluetooth.connect(deviceAddress, { duration: 1 });
    console.log('connection response: ', res);
  }, []);

  const disconnect = useCallback(async () => {
    const res = await bluetooth.disconnect();
    console.log('disconnection response: ', res);
  }, []);

  const setup = useCallback(async () => {
    const res = await bluetooth.setup({ size: 512 });
    console.log('setup response: ', res);
  }, []);

  const writeString = useCallback(async () => {
    const res = await bluetooth.writeString(
      service,
      characteristicToWrite,
      JSON.stringify({ key: 'g7H2Mi96H02Hlnyd' })
    );
    const decoded = bluetooth.bytesToString(res.value);
    console.log('decoded: ', decoded);

    console.log('write response: ', res);
  }, []);

  const write = useCallback(async () => {
    const res = await bluetooth.write(
      service,
      characteristicToWrite,
      bluetooth.stringToBytes(JSON.stringify({ key: 'g7H2Mi96H02Hlnyd' }))
    );
    const decoded = bluetooth.bytesToString(res.value);
    console.log('decoded: ', decoded);

    console.log('write response: ', res);
  }, []);

  const read = useCallback(async () => {
    const res = await bluetooth.read(service, characteristicToRead);
    console.log('read response: ', res);
  }, []);

  const notify = useCallback(async () => {
    const res = await bluetooth.enableNotifications(
      service,
      characteristicToNotify,
      (event) => console.log('notification: ', event)
    );
    console.log('subscribe response: ', res);
  }, []);

  const stopNotifications = useCallback(async () => {
    const res = await bluetooth.disableNotifications(
      service,
      characteristicToNotify
    );
    console.log('unsubscribe response: ', res);
  }, []);

  const subscribeToAdapterState = useCallback(
    () =>
      bluetooth.subscribeToAdapterState((event) =>
        console.log('adapter: ', event)
      ),
    []
  );

  const unsubscribeFromAdapterState = useCallback(
    () => bluetooth.unsubscribeFromAdapterState(),
    []
  );

  useEffect(() => {
    bluetooth.init({ autoDecodeBytes: true });
    bluetooth.subscribeToConnectionState((event) =>
      console.log('state: ', event.connectionState)
    );
    bluetooth.subscribeToErrors((event) => console.log('error: ', event));

    return bluetooth.destroy;
  }, []);

  return (
    <View style={styles.container}>
      <Button title="scan" onPress={startScan} />
      <Button title="stopScan" onPress={stopScan} />
      <Button title="connect" onPress={connect} />
      <Button title="disconnect" onPress={disconnect} />
      <Button title="setup" onPress={setup} />
      <Button title="write string" onPress={writeString} />
      <Button title="write key" onPress={write} />
      <Button title="read" onPress={read} />
      <Button title="notify" onPress={notify} />
      <Button title="stop notifications" onPress={stopNotifications} />
      <Button title="subscribe to adapter" onPress={subscribeToAdapterState} />
      <Button
        title="unsubscribe from adapter"
        onPress={unsubscribeFromAdapterState}
      />
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    gap: 16,
  },
  box: {
    width: 60,
    height: 60,
    marginVertical: 20,
  },
});
