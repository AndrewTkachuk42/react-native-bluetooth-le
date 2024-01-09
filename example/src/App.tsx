import React, { useCallback, useEffect } from 'react';

import { StyleSheet, View, Button } from 'react-native';
import type { DeviceData } from '../../src/types/types';
import bluetoothManager from '../../src/services/bluetooth';
import { IS_ANDROID } from '../../src/constants/constants';

const bluetooth = bluetoothManager.getInstance();

const deviceAddress = IS_ANDROID
  ? 'A8:42:E3:74:0C:EE'
  : 'C216C9BC-016D-82B4-E36A-394A4EDB6DAD'; // Android uses mac address, ios - uuid
const service = '7A6F10E0-DC05-11EC-9D64-0242AC120002';
const characteristicToWrite = '2DF9DA8C-47C4-4E0C-99F2-D90DFD5A4BC3';
const characteristicToRead = '5E427456-FD7C-4956-BDE8-1C275A7A1D9B';
const characteristicToNotify = '7FE6343D-C796-45B9-BCC8-D4EFDD9868F6';

export default function App() {
  const startScan = useCallback(async () => {
    const onDeviceFound = (device: DeviceData) => console.log({ device });

    const res = await bluetooth.startScan(onDeviceFound, {
      duration: 1,
      name: 'll_0000033',
    });

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

  const discoverServices = useCallback(async () => {
    const res = await bluetooth.discoverServices({
      services: {
        [service]: [
          characteristicToWrite,
          characteristicToRead,
          characteristicToNotify,
        ],
      },
      duration: 1,
    });
    console.log('setup response: ', res);
  }, []);

  const setMtu = useCallback(async () => {
    const res = await bluetooth.requestMtu(512);
    console.log('mtu response: ', res);
  }, []);

  const writeString = useCallback(async () => {
    const res = await bluetooth.writeString(
      service,
      characteristicToWrite,
      JSON.stringify({ key: 'g7H2Mi96H02Hlnyd' })
    );

    console.log('write response: ', res);
  }, []);

  const write = useCallback(async () => {
    const res = await bluetooth.write(
      service,
      characteristicToWrite,
      bluetooth.stringToBytes(JSON.stringify({ key: 'g7H2Mi96H02Hlnyd' }))
    );

    console.log('write response: ', res);
  }, []);

  const read = useCallback(async () => {
    const res = await bluetooth.read(service, characteristicToRead);

    const decoded = bluetooth.bytesToString(res.value);
    console.log('decoded: ', decoded);
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
    bluetooth.init({ autoDecodeBytes: true, timeoutDuration: 5 });
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
      <Button title="setMtu" onPress={setMtu} />
      <Button title="discoverServices" onPress={discoverServices} />
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

// const android = {
//   devices: [
//     { address: '51:65:3F:98:69:21', name: null, rssi: '-83' },
//     { address: '4D:88:4A:E9:0C:8F', name: null, rssi: '-67' },
//     { address: '7D:7D:8F:09:1E:D0', name: null, rssi: '-85' },
//     { address: '0E:60:13:67:3D:60', name: null, rssi: '-74' },
//     { address: '4D:0D:B1:81:BE:88', name: null, rssi: '-93' },
//     { address: '40:B6:E7:25:6B:B7', name: 'HUAWEI WATCH FIT-BB7', rssi: '-89' },
//     { address: '4A:B3:A6:B1:C3:9D', name: null, rssi: '-82' },
//     { address: '44:82:94:42:5F:AD', name: null, rssi: '-39' },
//     { address: 'E2:66:A4:B7:6A:4F', name: null, rssi: '-91' },
//     { address: '78:BD:BC:96:C4:17', name: null, rssi: '-89' },
//     { address: '25:F6:69:64:6F:18', name: null, rssi: '-80' },
//     { address: '54:44:A3:5C:88:07', name: null, rssi: '-75' },
//     { address: '03:5D:75:4A:83:DD', name: null, rssi: '-89' },
//   ],
//   error: null,
// };

// const ios = {
//   devices: [
//     { address: '11962BD6-C68D-AF14-81AD-46B62CE9D618', name: null, rssi: -80 },
//     {
//       address: '134A8925-BF3C-9E02-5FAB-62D007A83B00',
//       name: '[TV] Samsung Q70BA 85 TV',
//       rssi: -84,
//     },
//     { address: '57ACECB3-0E99-C776-35D3-8E50BBDFE855', name: null, rssi: -90 },
//     { address: 'C2B9F4E6-3399-C71A-14E3-9DB653E6DA25', name: null, rssi: -85 },
//     {
//       address: 'A03F2D42-C117-A7C8-31E0-8583F2AC97C7',
//       name: 'iPhone',
//       rssi: -99,
//     },
//     { address: '289482B7-C417-4F56-B2AC-A5738AE00C26', name: null, rssi: -95 },
//     { address: 'CBC65F2B-2575-1CD1-3DDF-EE640841D564', name: null, rssi: -98 },
//     { address: '524109F3-7F00-5A6A-5CEA-31B62D1C81E2', name: null, rssi: -77 },
//     { address: 'ED837057-D25F-1A4C-F1CB-6BCE02331106', name: null, rssi: -64 },
//     {
//       address: '1C2354CB-8573-3193-C952-D7A65FD69342',
//       name: 'HUAWEI WATCH FIT-BB7',
//       rssi: -98,
//     },
//     { address: 'C1D21270-EDBD-B185-00B8-7C89E51C2766', name: null, rssi: -100 },
//   ],
//   error: null,
// };
