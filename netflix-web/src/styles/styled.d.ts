import 'styled-components';
import type { AppTheme } from './theme';

declare module 'styled-components' {
  // styled-components requires interface merging for DefaultTheme augmentation.
  // eslint-disable-next-line @typescript-eslint/no-empty-object-type
  export interface DefaultTheme extends AppTheme {}
}
