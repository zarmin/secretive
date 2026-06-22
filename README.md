# Secretive [![Test](https://github.com/maxgoedjen/secretive/actions/workflows/test.yml/badge.svg?branch=main)](https://github.com/maxgoedjen/secretive/actions/workflows/test.yml) ![Release](https://github.com/maxgoedjen/secretive/workflows/Release/badge.svg)


Secretive is an app for protecting and managing SSH keys with the Secure Enclave.
<picture>
  <source media="(prefers-color-scheme: dark)" srcset="/.github/readme/app-dark.png">
  <source media="(prefers-color-scheme: light)" srcset="/.github/readme/app-light.png">
  <img src="/.github/readme/app-dark.png" alt="Screenshot of Secretive" width="600">
</picture>


## About This Fork

This is a personal fork of [maxgoedjen/secretive](https://github.com/maxgoedjen/secretive) with the following changes:

### Serialized Signing Prompts

When multiple SSH connections request signatures at the same time (for example an ansible run against many hosts), signing requests are serialized so only one Touch ID prompt is shown at a time instead of a pile of overlapping prompts. Adapted from upstream PR [#780](https://github.com/maxgoedjen/secretive/pull/780).

### Authentication Reuse Window (per key)

After a successful signing authentication, the authenticated context can be reused for a short window, so a parallel SSH fan-out (e.g. ansible against many hosts) asks for Touch ID once instead of once per host. This is configurable **per key** in the create and edit sheets — **Off** (authenticate on every signature), 5, 10, or 30 seconds. It defaults to **Off**, preserving strict per-signature authentication; opt in only for the keys where you need it.

### Update Checking Disabled

The built-in updater is not built or used: the app never contacts GitHub's releases API.

### Buildable with Personal Signing

XPC service identifiers and the code signing team ID are resolved at runtime instead of being hardcoded, so the app works when built from source with your own bundle identifiers and development team (upstream's agent hangs in this configuration). This fork uses the `com.zarmin.Secretive.*` bundle identifiers.

### Smaller Changes

- Notifications about key access are grouped per secret.
- The "Public Key" section in the secret detail view (removed upstream in the certificate UI refactor) is restored.

Everything else matches upstream Secretive, documented below.

## Why?

### Safer Storage

The most common setup for SSH keys is just keeping them on disk, guarded by proper permissions. This is fine in most cases, but it's not super hard for malicious users or malware to copy your private key. If you protect your keys with the Secure Enclave, it's impossible to export them, by design.

### Access Control

If your Mac has a Secure Enclave, it also has support for strong access controls like Touch ID, or authentication with Apple Watch. You can configure your keys so that they require Touch ID (or Watch) authentication before they're accessed.

<img src="/.github/readme/touchid.png" alt="Screenshot of Secretive authenticating with Touch ID" width="400">

### Notifications

Secretive also notifies you whenever your keys are accessed, so you're never caught off guard.

<img src="/.github/readme/notification.png" alt="Screenshot of Secretive notifying the user" width="600">

### Support for Smart Cards Too!

For Macs without Secure Enclaves, you can configure a Smart Card (such as a YubiKey) and use it for signing as well.

## Getting Started

### Installation

#### Direct Download

You can download the latest release over on the [Releases Page](https://github.com/maxgoedjen/secretive/releases)

#### Using Homebrew

    brew install secretive

### FAQ

There's a [FAQ here](FAQ.md).

### Auditable Build Process

Builds are produced by GitHub Actions with an auditable build and release generation process. Starting with Secretive 3.0, builds are attested using [GitHub Artifact Attestation](https://docs.github.com/en/actions/concepts/security/artifact-attestations). Attestations are viewable in the build log for a build, and also on the [main attestation page](https://github.com/maxgoedjen/secretive/attestations).

### A Note Around Code Signing and Keychains

While Secretive uses the Secure Enclave to protect keys, it still relies on Keychain APIs to store and access them. Keychain restricts reads of keys to the app (and specifically, the bundle ID) that created them. If you build Secretive from source, make sure you are consistent in which bundle ID you use so that the Keychain is able to locate your keys.

### Backups and Transfers to New Machines

Because secrets in the Secure Enclave are not exportable, they are not able to be backed up, and you will not be able to transfer them to a new machine. If you get a new Mac, just create a new set of secrets specific to that Mac.

## Security

Secretive's security policy is detailed in [SECURITY.md](SECURITY.md). To report security issues, please use [GitHub's private reporting feature.](https://docs.github.com/en/code-security/security-advisories/guidance-on-reporting-and-writing-information-about-vulnerabilities/privately-reporting-a-security-vulnerability#privately-reporting-a-security-vulnerability)

## Acknowledgements

### sekey
Secretive was inspired by the [sekey project](https://github.com/sekey/sekey).

### Localization
Secretive is localized to many languages by a generous team of volunteers. To learn more, see [LOCALIZING.md](LOCALIZING.md). Secretive's localization workflow is generously provided by [Crowdin](https://crowdin.com).
