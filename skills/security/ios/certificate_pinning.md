---
platform: ios
---

# Skill: Certificate Pinning

## Overview

Certificate pinning is the variant of TLS pinning where the app validates the server's
**certificate** (or its hash) against an embedded copy, rather than the public key. It's
conceptually simpler but **more brittle**: when the certificate is renewed (even with the
same key), the pin breaks unless you also pin the new cert. For most apps, prefer
**public-key (SPKI) pinning** (see [`ssl_pinning.md`](ssl_pinning.md)); use certificate
pinning only when you control the cert lifecycle tightly or pin to an intermediate/root CA.

## Use Cases

- Environments with strict, controlled certificate issuance.
- Pinning to a private/intermediate CA you operate.
- Short-term hardening where key pinning isn't feasible.

## Best Practices

- Pin the **certificate hash**, and include the **next certificate** ahead of rotation.
- Consider pinning an **intermediate CA** cert (more stable than the leaf) if appropriate.
- Bundle pinned certs in the app and compare after default trust evaluation passes.
- Maintain a **rotation calendar** aligned to certificate expiry; ship updates before expiry.
- Provide an **emergency override** (remote config) to avoid bricking the app.

## Anti-Patterns

- ❌ Pinning a single leaf cert with no successor → guaranteed outage at renewal.
- ❌ Skipping default trust evaluation.
- ❌ No expiry/rotation tracking.
- ❌ Comparing certificate *subjects/strings* instead of cryptographic hashes.
- ❌ Choosing cert pinning when key pinning would be more robust.

## Checklist

- [ ] Certificate hash pinned; successor cert included.
- [ ] Default trust evaluation performed first.
- [ ] Rotation calendar tied to expiry; update shipped early.
- [ ] Emergency override available.
- [ ] Considered (and justified not using) public-key pinning.

## Swift Examples

```swift
final class CertPinningDelegate: NSObject, URLSessionDelegate {
    private let pinnedCertHashes: Set<Data>   // SHA-256 of DER-encoded certs (current + next)

    init(pinnedCertHashes: Set<Data>) { self.pinnedCertHashes = pinnedCertHashes }

    func urlSession(_ session: URLSession,
                    didReceive challenge: URLAuthenticationChallenge) async
        -> (URLSession.AuthChallengeDisposition, URLCredential?) {

        guard let trust = challenge.protectionSpace.serverTrust,
              SecTrustEvaluateWithError(trust, nil),
              let chain = SecTrustCopyCertificateChain(trust) as? [SecCertificate],
              let leaf = chain.first else {
            return (.cancelAuthenticationChallenge, nil)
        }
        let der = SecCertificateCopyData(leaf) as Data
        let hash = Data(SHA256.hash(data: der))
        return pinnedCertHashes.contains(hash)
            ? (.useCredential, URLCredential(trust: trust))
            : (.cancelAuthenticationChallenge, nil)
    }
}
```

## Common Interview Questions

- Certificate vs public-key pinning — trade-offs?
- Why is certificate pinning more brittle?
- How do you rotate pinned certificates without an outage?
- When would you pin an intermediate CA instead of the leaf?
- Why hash the DER rather than compare cert fields?

## AI Implementation Notes

- Recommend public-key pinning by default; use cert pinning only with justification.
- Always include the successor certificate and a rotation/override plan.
- Compare cryptographic hashes of DER data, never string fields.
- Related: [`ssl_pinning.md`](ssl_pinning.md),
  [`../../../checklists/security_review.md`](../../../checklists/security_review.md).
