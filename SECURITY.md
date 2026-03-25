# Security Policy

## Supported Versions

This project is actively maintained on the default branch.
Security fixes are prioritized for the latest codebase.

## Reporting a Vulnerability

Please do **not** open public issues for security vulnerabilities.

Instead, report privately through one of these methods:

- GitHub private security advisory (preferred)
- Direct email to the maintainer (if published in profile/repo)

When reporting, include:

- Vulnerability type and impact
- Reproduction steps
- Affected files/modules
- Suggested mitigation (optional)

## Response Expectations

- Initial acknowledgement target: within 72 hours
- Triage and severity assessment: as soon as possible
- Fix timeline: based on severity and exploitability

## Secrets and Credentials

This repository must never contain:

- `.env` values with live keys
- service account credentials
- private signing keys/keystores
- production tokens

If accidental exposure happens:

1. Rotate credentials immediately.
2. Invalidate impacted tokens/keys.
3. Remove the exposed data from codebase and history.
4. Document remediation steps in a private incident note.

## Firebase and Cloud Security Baseline

- Enforce strict Firestore security rules.
- Require authentication for protected data paths.
- Validate ownership/roles in rules.
- Keep admin operations role-gated.
- Audit Remote Config and notification permissions regularly.

## Dependency Security

- Keep Flutter and package dependencies up to date.
- Review changelogs for security-related upgrades.
- Avoid adding unmaintained or unknown packages.
