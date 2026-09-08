---
platform: flutter
---

# Skill: OAuth2

## Overview

Mobile apps are **public clients**: they cannot keep a secret, so the only correct flow is
**Authorization Code with PKCE**, run in the system browser (ASWebAuthenticationSession on iOS,
Custom Tabs on Android) and returned via a registered redirect. `flutter_appauth` wraps the
platform AppAuth SDKs and gets PKCE, discovery, and browser handling right; a pure-Dart stack
(`oauth2` + `flutter_web_auth_2`) is the alternative when you need full control of the exchange.

## Use Cases

- Sign-in against an OIDC provider (Auth0, Okta, Cognito, Keycloak, Entra ID).
- Social sign-in that must return an id token your backend can verify.
- Silent renewal of an expired access token via a refresh token.
- Enterprise SSO where the IdP session must live in the system browser, not the app.

## Best Practices

- **Authorization Code + PKCE only.** No implicit flow, no password grant, no client secret in the
  app binary.
- **System browser, never an embedded WebView.** A WebView cannot share the IdP session, breaks
  SSO and password managers, and is rejected by most providers.
- Register the redirect properly: a custom scheme (`com.example.app:/oauthredirect`) or, better,
  an App Link / Universal Link over `https` so another app cannot claim it.
- **Validate `state`** on the callback to defeat CSRF, and validate the id token's signature,
  `iss`, `aud`, and `exp` — on the server if the token is used server-side.
- Access token in memory, **refresh token in secure storage**
  ([`secure_storage.md`](secure_storage.md)).
- **Single-flight refresh.** Concurrent 401s wait on one refresh; see
  [`../../networking/flutter/rest_api.md`](../../networking/flutter/rest_api.md). Without it,
  rotating refresh tokens will log users out at random.
- Handle rotation: if the provider rotates refresh tokens, persist the new one atomically, and
  treat a rejected refresh as "sign in again", not as a retryable error.
- Log out both sides: revoke at the provider (`end_session_endpoint`) and clear local storage.
  Clearing locally alone leaves a live server session.
- Never log tokens, authorization codes, or the code verifier.

## Anti-Patterns

- ❌ A client secret shipped in the app.
- ❌ Implicit flow or the resource-owner password grant.
- ❌ An embedded `WebView` for the authorization step.
- ❌ Refresh token in `shared_preferences`.
- ❌ Refreshing on every request instead of on 401/expiry.
- ❌ Skipping `state` validation.
- ❌ A refresh failure that silently retries forever instead of forcing re-auth.
- ❌ Logging out locally without revoking the provider session.

## Checklist

- [ ] Authorization Code + PKCE; no client secret in the app.
- [ ] Authorization happens in the system browser.
- [ ] Redirect URI is registered on both platforms and is not claimable by another app.
- [ ] `state` is validated; id token claims are validated.
- [ ] Refresh token is in secure storage; access token is in memory.
- [ ] Refresh is single-flight and cannot recurse.
- [ ] Rotated refresh tokens are persisted atomically.
- [ ] Logout revokes at the provider and clears local state.
- [ ] No tokens, codes, or verifiers in logs or crash reports.

## Dart Examples

```dart
// data/auth/appauth_authenticator.dart
class AppAuthAuthenticator implements Authenticator {
  AppAuthAuthenticator(this._appAuth, this._tokens, this._config);

  final FlutterAppAuth _appAuth;
  final TokenStore _tokens;
  final AuthConfig _config;

  @override
  Future<Session> signIn() async {
    final result = await _appAuth.authorizeAndExchangeCode(
      AuthorizationTokenRequest(
        _config.clientId,               // public client — no secret
        _config.redirectUri,            // registered on both platforms
        discoveryUrl: _config.discoveryUrl,
        scopes: const ['openid', 'profile', 'offline_access'],
        // PKCE is generated and verified by the AppAuth SDK.
      ),
    );

    final refresh = result.refreshToken;
    if (refresh != null) await _tokens.save(refreshToken: refresh);

    return Session(
      accessToken: result.accessToken!,        // kept in memory only
      expiresAt: result.accessTokenExpirationDateTime!,
    );
  }

  @override
  Future<void> signOut(String idToken) async {
    await _appAuth.endSession(
      EndSessionRequest(
        idTokenHint: idToken,
        postLogoutRedirectUrl: _config.postLogoutRedirectUri,
        discoveryUrl: _config.discoveryUrl,
      ),
    );
    await _tokens.clear();                      // both sides, always
  }
}
```

```dart
// Single-flight refresh: concurrent 401s share one network round trip.
Future<String>? _inFlight;

Future<String> refresh() =>
    _inFlight ??= _doRefresh().whenComplete(() => _inFlight = null);
```

```xml
<!-- android/app/src/main/AndroidManifest.xml -->
<activity android:name="net.openid.appauth.RedirectUriReceiverActivity"
          android:exported="true">
  <intent-filter>
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data android:scheme="com.example.app" android:path="/oauthredirect" />
  </intent-filter>
</activity>
```

## Common Interview Questions

- What does PKCE protect against that plain Authorization Code does not?
- Why is a mobile app a public client, and what follows from that?
- Why is an embedded WebView the wrong place to authenticate?
- Where does each token live, and why are access and refresh tokens treated differently?
- What breaks when refresh is not single-flight and the provider rotates refresh tokens?
- Why does logout need to reach the provider, not just clear local storage?

## AI Implementation Notes

- Never generate an implicit-flow or password-grant integration, and never a client secret in Dart.
- Never generate a `WebView`-based authorization step.
- Always route the refresh token through `TokenStore` into secure storage.
- Always generate single-flight refresh; a per-request refresh is a defect, not a style choice.
- iOS counterpart: [`../ios/oauth2.md`](../ios/oauth2.md).
- Related: [`secure_storage.md`](secure_storage.md),
  [`../../../architecture/authentication_architecture.md`](../../../architecture/authentication_architecture.md).
