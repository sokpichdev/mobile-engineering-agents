# Skill: SSL/TLS Pinning

## Overview

SSL/TLS pinning hardens transport security by validating the server's certificate or public
key against a value embedded in the app, in addition to the normal trust-chain check. This
defends against man-in-the-middle attacks using rogue or compromised CAs. **Public-key
pinning** is preferred over certificate pinning because the key survives certificate renewal.
Always ship a **backup pin** and a **rotation plan** to avoid bricking the app when certs
change. (See [`certificate_pinning.md`](certificate_pinning.md) for the cert-pinning variant.)

## Use Cases

- Banking, healthcare, and other high-sensitivity apps.
- Any API where MITM would expose credentials or PII.

## Best Practices

- **Pin the public key (SPKI hash)**, not the leaf certificate, so renewals don't break.
- Ship **at least one backup pin** (next cert's key) for seamless rotation.
- Implement in `URLSessionDelegate`'s `didReceive challenge`; **still validate the chain**
  first, then compare the pin.
- Pin **only your own sensitive hosts**; don't pin third-party/analytics domains you don't control.
- Have a **kill-switch / remote config** to relax pins in an emergency.

## Anti-Patterns

- ❌ Pinning the leaf cert with no backup → app breaks on renewal.
- ❌ Disabling chain validation and *only* comparing the pin.
- ❌ Hardcoding a single pin with no rotation plan.
- ❌ Pinning domains you don't operate.
- ❌ Logging certificate data.

## Checklist

- [ ] Public-key (SPKI) pinning preferred.
- [ ] Backup pin shipped; rotation plan documented.
- [ ] Default chain validation still performed.
- [ ] Only first-party sensitive hosts pinned.
- [ ] Emergency relaxation path exists.

## Swift Examples

```swift
final class PinningDelegate: NSObject, URLSessionDelegate {
    /// SPKI SHA-256 hashes (base64). Include a backup for rotation.
    private let pinnedKeys: Set<String>

    init(pinnedKeys: Set<String>) { self.pinnedKeys = pinnedKeys }

    func urlSession(_ session: URLSession,
                    didReceive challenge: URLAuthenticationChallenge) async
        -> (URLSession.AuthChallengeDisposition, URLCredential?) {

        guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
              let trust = challenge.protectionSpace.serverTrust else {
            return (.performDefaultHandling, nil)
        }
        // 1) Default trust evaluation (chain validity) must pass first.
        guard SecTrustEvaluateWithError(trust, nil),
              let chain = SecTrustCopyCertificateChain(trust) as? [SecCertificate] else {
            return (.cancelAuthenticationChallenge, nil)
        }
        // 2) Compare the leaf's public-key hash to our pins.
        if let leaf = chain.first, pinnedKeys.contains(spkiSHA256Base64(of: leaf)) {
            return (.useCredential, URLCredential(trust: trust))
        }
        return (.cancelAuthenticationChallenge, nil)
    }
}
```

## Common Interview Questions

- Public-key vs certificate pinning — why prefer the former?
- Why ship a backup pin?
- Why still validate the chain when pinning?
- How do you rotate pins without breaking old app versions?
- What's the risk of pinning third-party hosts?

## AI Implementation Notes

- Default to SPKI public-key pinning with a backup pin and a documented rotation plan.
- Always evaluate the default trust chain before comparing pins.
- Only pin first-party sensitive hosts; add an emergency relax path.
- Related: [`certificate_pinning.md`](certificate_pinning.md),
  [`../../standards/security_standards.md`](../../standards/security_standards.md).
