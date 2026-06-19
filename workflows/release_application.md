# Workflow: Release the Application

Led by the [Release Manager](../agents/release_manager.md) with the
[DevOps Expert](../agents/devops_expert.md). Checklist-driven and reproducible.

## Objective

Ship a tested build to TestFlight/App Store safely: correct versioning, signing, metadata,
phased rollout, and a ready rollback plan.

## Inputs

- Release scope/changelog, target version, store metadata, signing assets.

## Outputs

- A tagged, CI-built, signed build submitted with monitoring and a rollback plan.

## Step-by-Step Process

1. **Pre-flight** — main is green (lint/test/build pass); changelog assembled; version + build
   numbers bumped per [SemVer](../standards/git_standards.md).
2. **Tag + build in CI** ([DevOps](../agents/devops_expert.md)) — build from a clean tagged
   commit; never an ad-hoc local build.
3. **Sign** — Fastlane match; verify certs/profiles aren't near expiry.
4. **Validate** — regression + QA sign-off; crash-free baseline acceptable; privacy/data-use
   declarations accurate.
5. **TestFlight beta** — distribute; gather feedback; verify upload symbolicates (dSYMs).
6. **Submit + phased rollout** — release notes + metadata + screenshots; phased App Store
   rollout with monitoring.
7. **Monitor + decide** — watch crash-free rate and key metrics; advance or roll back.
8. **Review** against [`checklists/release_review.md`](../checklists/release_review.md).

## Validation Steps

- Build originates from a tagged CI run; version/build numbers correct and unique.
- Signing valid; dSYMs uploaded; crashes symbolicate.
- Privacy declarations match actual data use.
- Rollout monitored; rollback path verified.

## Failure Scenarios

- **Rejected build number** → bump and re-submit.
- **Expired cert/profile** → rotate via match; rebuild.
- **Crash spike during rollout** → halt rollout; roll back / expedite a hotfix.
- **Inaccurate privacy manifest** → correct before resubmission.

## AI Agent Instructions

- Never release from a local build; require a tagged CI artifact.
- Gate strictly on the release checklist; phase the rollout with monitoring.
- Ensure a rollback/hotfix plan exists before submitting.
- Keep version/build numbers and privacy declarations accurate.

## Acceptance Criteria

- [ ] Built from a tagged, green CI commit; versions bumped correctly.
- [ ] Signed; dSYMs uploaded; QA + regression signed off.
- [ ] Metadata + privacy declarations accurate.
- [ ] Phased rollout with monitoring + rollback plan.
- [ ] `checklists/release_review.md` passes.
