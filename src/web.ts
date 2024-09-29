import { WebPlugin } from '@capacitor/core';
import type { GoogleAuthPlugin, InitOptions, User } from './definitions';

const GAPI_SCRIPT_ID = 'gapi' as const;
const GAPI_SRC = 'https://apis.google.com/js/platform.js' as const;
const CLIENT_ID_NAME = 'google-signin-client_id' as const;

type InitializationErrorKind =
  | 'NoDocumentOrWindow'
  | 'DuplicateScript'
  | 'NoClientId'
  | 'MissingOptions';

export class InitializationError extends Error {
  constructor(kind: InitializationErrorKind) {
    super(
      `GoogleAuthPlugin error: ${
        {
          NoDocumentOrWindow: 'Missing html <document> element',
          DuplicateScript: `The script tag <script id="${GAPI_SCRIPT_ID}"> already exists`,
          NoClientId: 'Missing web client ID',
          MissingOptions:
            'The unthinkable happened and plugin options are missing',
        }[kind]
      }`,
    );
  }
}

type GoogleAuthWebOptions = {
  clientId: string;
  scopes: string[];
};

export class GoogleAuthWeb extends WebPlugin implements GoogleAuthPlugin {
  options?: GoogleAuthWebOptions;

  private static getMetaClientId(): string | null {
    const elements = document.getElementsByName(CLIENT_ID_NAME);
    if (!(elements[0] instanceof HTMLMetaElement)) {
      return null;
    }
    return elements[0].content;
  }

  async initialize(
    { web: webOptions }: InitOptions = { web: {} },
  ): Promise<void> {
    const clientId =
      webOptions?.clientId ?? GoogleAuthWeb.getMetaClientId() ?? null;
    if (!clientId) throw new InitializationError('NoClientId');

    this.options = {
      clientId,
      scopes: webOptions?.scopes ?? [],
    };

    await this.loadScript();
    await this.addUserChangeListener();
  }

  async loadScript(): Promise<void> {
    if (!(window instanceof Window) || !(document instanceof Document)) {
      throw new InitializationError('NoDocumentOrWindow');
    }

    const scriptId = 'gapi';
    const scriptEl = document.getElementById(scriptId);

    if (scriptEl) throw new InitializationError('DuplicateScript');

    const head = document.getElementsByTagName('head')[0];
    const script = document.createElement('script');

    script.type = 'text/javascript';
    script.defer = true;
    script.async = true;
    script.id = scriptId;

    await new Promise<void>((resolve, reject) => {
      script.onload = () => resolve();
      script.onerror = (_event, _source, _lineno, _colno, error) =>
        reject(error);
      script.src = GAPI_SRC;
      head.appendChild(script);
    });

    await this.initializeGapi();
  }

  async initializeGapi(): Promise<void> {
    await new Promise<void>((resolve, reject) => {
      gapi.load('auth2', () => {
        if (!this.options) {
          reject(new InitializationError('MissingOptions'));
          return;
        }

        // https://github.com/CodetrixStudio/CapacitorGoogleAuth/issues/202#issuecomment-1147393785
        const clientConfig: gapi.auth2.ClientConfig & { plugin_name: string } =
          {
            client_id: this.options.clientId,
            plugin_name: 'JakcharvatCapacitorGoogleAuth',
          };

        if (this.options.scopes?.length) {
          clientConfig.scope = this.options.scopes.join(' ');
        }

        gapi.auth2.init(clientConfig);
        resolve();
      });
    });
  }

  async signIn(): Promise<User> {
    if (!this.options) throw new InitializationError('MissingOptions');

    const googleUser = await gapi.auth2.getAuthInstance().signIn();
    return this.getUserFrom(googleUser);
  }

  async signOut(): Promise<void> {
    await gapi.auth2.getAuthInstance().signOut();
  }

  private async addUserChangeListener() {
    gapi.auth2.getAuthInstance().currentUser.listen(googleUser => {
      this.notifyListeners(
        'userChange',
        googleUser.isSignedIn() ? this.getUserFrom(googleUser) : null,
      );
    });
  }

  private getUserFrom(googleUser: gapi.auth2.GoogleUser) {
    const user = {} as User;
    const profile = googleUser.getBasicProfile();

    user.email = profile.getEmail();
    user.familyName = profile.getFamilyName();
    user.givenName = profile.getGivenName();
    user.id = profile.getId();
    user.imageUrl = profile.getImageUrl();
    user.name = profile.getName();

    const authResponse = googleUser.getAuthResponse(true);
    user.authentication = {
      accessToken: authResponse.access_token,
      idToken: authResponse.id_token,
      refreshToken: '',
    };

    return user;
  }
}
