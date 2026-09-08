---
platform: flutter
---

# Skill: SSL Pinning

## Overview

Pinning constrains which certificate chain your app will accept, so a device that trusts an
attacker-installed CA still cannot read your traffic. Pin the **SPKI (public key) hash**, not the
leaf certificate: the key usually survives certificate renewal, so a routine renewal does not brick
every installed app. Pinning is defense in depth on top of normal TLS validation — never a
replacement for it, and never a substitute for server-side authorization.

## Use Cases

- Apps handling payments, health data, or credentials on untrusted networks.
- Regulatory requirements (PCI, HIPAA-adjacent, banking supervision).
- Raising the cost of casual traffic interception with a proxy and a user-installed CA.

## Use It With Care

Pinning is the security control most likely to cause a self-inflicted outage. Before enabling it:

- **Ship at least two pins** — the current key and a backup key held offline for the next rotation.
  With one pin, a compromised or rotated key means every installed app loses connectivity.
- **Have a remote kill switch or a forced-update path** so a bad pin can be recovered without a
  store review cycle.
- **Know the expiry.** Track the pinned key's rotation date alongside the certificate's.
- On a rooted or jailbroken device, pinning is bypassable (Frida, objection). It raises cost; it
  does not stop a determined attacker with device access.

## Best Practices

- **Pin the SPKI SHA-256 hash**, not the whole certificate.
- Pin the leaf or intermediate deliberately: intermediate pinning survives leaf renewal but trusts
  more; leaf pinning is tighter but rotates more often. Document which you chose.
- Implement in `dio` by supplying an HTTP client adapter whose `badCertificateCallback` compares the
  SPKI hash — and keep the platform's own chain validation running, do not `return true`.
- Native-layer pinning (Android `network_security_config.xml`, iOS ATS) does **not** cover Dart's
  `HttpClient` traffic. State explicitly which layer you are pinning, and pin at the Dart layer for
  `dio`/`http` traffic.
- **Fail closed and report.** A pin mismatch is a security event: refuse the connection and emit
  telemetry so you learn about a bad rotation from monitoring, not from the app store reviews.
- Exclude non-API hosts (image CDNs, analytics) from pinning unless you also control their rotation.
- Do not pin in debug/dev flavors, so proxy-based debugging stays possible.

## Anti-Patterns

- ❌ `badCertificateCallback: (cert, host, port) => true` — that disables TLS validation entirely.
- ❌ A single pin with no backup.
- ❌ Pinning the leaf certificate with no rotation plan.
- ❌ Hardcoding a pin with no way to update it short of an app release.
- ❌ Failing open ("if pinning throws, continue") — that is worse than not pinning.
- ❌ Assuming the native config also covers Dart HTTP traffic.
- ❌ Treating pinning as a reason to weaken server-side authorization.

## Checklist

- [ ] SPKI hashes are pinned, not full certificates.
- [ ] At least one backup pin ships alongside the primary.
- [ ] The rotation date is tracked and owned by someone.
- [ ] Standard chain validation still runs; the callback only adds a check.
- [ ] Pin mismatch fails closed and emits telemetry.
- [ ] Pinning is scoped to the hosts you control.
- [ ] Debug/dev flavors are exempt.
- [ ] A kill switch or forced-update path exists for a bad pin.

## Dart Examples

```dart
// data/network/pinning.dart
const _pinnedSpkiSha256 = <String>{
  'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=', // current key
  'BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB=', // backup key, held offline
};

void applyPinning(Dio dio, {required bool enabled, required String apiHost}) {
  if (!enabled) return; // never pin in debug/dev flavors

  dio.httpClientAdapter = IOHttpClientAdapter(
    createHttpClient: () => HttpClient()
      ..badCertificateCallback = (cert, host, port) {
        // Reached only when the platform chain check already failed, or for the
        // hosts we additionally constrain. Never `return true`.
        if (host != apiHost) return false;
        return _pinnedSpkiSha256.contains(_spkiSha256(cert));
      },
  );
}

String _spkiSha256(X509Certificate cert) =>
    base64.encode(sha256.convert(_subjectPublicKeyInfo(cert.der)).bytes);
```

```bash
# Extract the SPKI pin for a host (do this for the current AND the backup key)
openssl s_client -servername api.example.com -connect api.example.com:443 </dev/null \
  | openssl x509 -pubkey -noout \
  | openssl pkey -pubin -outform der \
  | openssl dgst -sha256 -binary \
  | openssl enc -base64
```

```xml
<!-- android/app/src/main/res/xml/network_security_config.xml
     Covers native/OkHttp traffic. It does NOT cover Dart's HttpClient. -->
<network-security-config>
  <domain-config>
    <domain includeSubdomains="true">api.example.com</domain>
    <pin-set expiration="2027-01-01">
      <pin digest="SHA-256">AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=</pin>
      <pin digest="SHA-256">BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB=</pin>
    </pin-set>
  </domain-config>
</network-security-config>
```

## Common Interview Questions

- Why pin the public key rather than the certificate?
- What is the failure mode of shipping a single pin?
- Does an Android `network_security_config` pin protect `dio` traffic? Why not?
- Why must a pin mismatch fail closed, and what should it emit?
- What does pinning *not* protect against on a rooted device?
- How would you recover from shipping a wrong pin to production?

## AI Implementation Notes

- Never generate `badCertificateCallback` that returns `true` unconditionally — that is a Critical
  finding, not a shortcut.
- Always generate two pins and a comment naming the rotation owner and date.
- Always scope pinning to the API host and exempt debug flavors.
- Verify the current `dio` adapter API before writing code (`IOHttpClientAdapter` in dio 5 replaced
  the earlier `DefaultHttpClientAdapter`).
- iOS counterparts: [`../ios/ssl_pinning.md`](../ios/ssl_pinning.md),
  [`../ios/certificate_pinning.md`](../ios/certificate_pinning.md).
- Related: [`../../networking/flutter/rest_api.md`](../../networking/flutter/rest_api.md),
  [`../../../standards/security_standards.md`](../../../standards/security_standards.md).
