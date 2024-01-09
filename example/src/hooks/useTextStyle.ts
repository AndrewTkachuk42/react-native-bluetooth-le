import { useMemo } from 'react';
import { useColorScheme } from 'react-native';

export const useTextStyle = () => {
  const colorScheme = useColorScheme();

  const isDark = colorScheme === 'dark';

  const textStyle = useMemo(
    () => [isDark ? { color: 'white' } : { color: 'black' }],
    [isDark]
  );

  return textStyle;
};
