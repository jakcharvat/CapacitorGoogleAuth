import { WebPlugin } from '@capacitor/core';

import type { GoogleAuthPlugin, InitOptions, User } from './definitions';

export class GoogleAuthWeb extends WebPlugin implements GoogleAuthPlugin {
  initialize(_options?: InitOptions): Promise<void> {
    throw this.unimplemented('Initialize is not yet available on the web');
  }
  signIn(): Promise<User> {
    throw this.unimplemented('Sign in is not yet available on the web');
  }
  signOut(): Promise<void> {
    throw this.unimplemented('Sign out is not yet available on the web');
  }
}
