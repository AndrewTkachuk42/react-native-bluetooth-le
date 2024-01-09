import React from 'react';

import { StyleSheet, ScrollView, Text, TouchableOpacity } from 'react-native';
import { type DeviceData } from '../../src/types/types';
import { strings } from './constants/strings';
import { useTextStyle } from './hooks/useTextStyle';

type DeviceProps = DeviceData & { isSelected: boolean; onPress: () => void };

const Device = ({ name, rssi, isSelected, onPress }: DeviceProps) => {
  const textStyle = useTextStyle();

  return (
    <TouchableOpacity
      onPress={onPress}
      style={[styles.device, isSelected && styles.selectedDevice]}
    >
      <Text style={textStyle}>{`${strings.NAME} ${
        name || strings.NO_NAME
      }`}</Text>
      <Text style={textStyle}>{`${strings.RSSI}: ${rssi}`}</Text>
    </TouchableOpacity>
  );
};

type DeviceListProps = {
  devices: DeviceData[];
  setSelected: (idx: number) => void;
  selected: number;
};

const DeviceList = ({ devices, selected, setSelected }: DeviceListProps) => (
  <ScrollView
    style={styles.deviceList}
    contentContainerStyle={styles.deviceListContentContainer}
  >
    {devices.map((data, index) => (
      <Device
        {...data}
        key={data.address}
        isSelected={index === selected}
        onPress={() => setSelected(index)}
      />
    ))}
  </ScrollView>
);

export default DeviceList;

const styles = StyleSheet.create({
  deviceList: {
    flex: 1,
    borderWidth: 1,
    borderColor: 'gray',
  },
  deviceListContentContainer: {
    flexGrow: 1,
  },
  device: {
    flexDirection: 'row',
    padding: 16,
    justifyContent: 'space-between',
  },
  selectedDevice: { backgroundColor: 'gray' },
});
