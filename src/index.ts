import { registerPlugin } from '@capacitor/core';

import type { GoogleAuthPlugin } from './definitions';

const GoogleAuth: GoogleAuthPlugin = registerPlugin<GoogleAuthPlugin>(
  'GoogleAuth',
  {
    web: () => import('./web').then(m => new m.GoogleAuthWeb()),
  },
);

export * from './definitions';
export { GoogleAuth };
