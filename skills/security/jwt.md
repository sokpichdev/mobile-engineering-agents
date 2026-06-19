# Skill: JWT (JSON Web Tokens)

## Overview

A JWT is a base64url-encoded, signed token with three parts: `header.payload.signature`.
It carries claims (e.g. `sub`, `exp`, `iss`, `aud`) and is signed (HMAC or RSA/EC). On the
client, treat the access token mostly as an **opaque bearer credential**: send it in the
`Authorization` header, read `exp` to schedule refresh, and **never make security decisions
based on unverified claims**. Cryptographic verification is the server's job; the client
verifies signatures only if it has a trustworthy public key and a real reason to.

## Use Cases

- Bearer authentication for API requests after OAuth2/login.
- Reading non-sensitive claims (display name, expiry) for UX.

## Best Practices

- Store tokens in **Keychain**; send as `Authorization: Bearer <token>`.
- Parse `exp` to **refresh before expiry** (with a safety skew, e.g. 60s).
- Keep **access tokens short-lived**; use refresh tokens for longevity.
- Treat the payload as **untrusted** on the client; don't gate security on it.
- **Clear tokens on logout** and on refresh-token failure.

## Anti-Patterns

- ❌ Storing JWTs in `UserDefaults` or logging them.
- ❌ Trusting unverified claims for authorization decisions client-side.
- ❌ Long-lived access tokens with no refresh.
- ❌ Putting sensitive PII in the (readable) payload.
- ❌ Implementing signature verification with hardcoded/wrong keys.

## Checklist

- [ ] Tokens stored in Keychain, never logged.
- [ ] `exp` parsed; refresh scheduled with skew.
- [ ] Access tokens short-lived; refresh flow present.
- [ ] No client-side security decision based on unverified claims.
- [ ] Tokens cleared on logout/refresh failure.

## Swift Examples

```swift
struct JWTClaims: Decodable { let sub: String; let exp: TimeInterval; let iss: String? }

enum JWT {
    /// Decodes claims for UX/expiry only — does NOT verify the signature.
    static func claims(from token: String) -> JWTClaims? {
        let segments = token.split(separator: ".")
        guard segments.count == 3,
              let payload = base64URLDecode(String(segments[1])) else { return nil }
        return try? JSONDecoder().decode(JWTClaims.self, from: payload)
    }

    static func isExpired(_ token: String, skew: TimeInterval = 60) -> Bool {
        guard let exp = claims(from: token)?.exp else { return true }
        return Date().timeIntervalSince1970 >= (exp - skew)
    }

    private static func base64URLDecode(_ s: String) -> Data? {
        var str = s.replacingOccurrences(of: "-", with: "+").replacingOccurrences(of: "_", with: "/")
        while str.count % 4 != 0 { str += "=" }
        return Data(base64Encoded: str)
    }
}
```

## Common Interview Questions

- What are the three parts of a JWT?
- Why shouldn't the client trust JWT claims for authorization?
- How do you decide when to refresh based on `exp`?
- Where should JWTs be stored on iOS, and why?
- HMAC vs RSA signing — implications for the client?

## AI Implementation Notes

- Decode claims only for expiry/UX; never authorize off unverified claims.
- Store via the Keychain skill; never log tokens.
- Schedule refresh using `exp` minus a skew; clear on logout.
- Related: [`oauth2.md`](oauth2.md), [`keychain.md`](keychain.md).
