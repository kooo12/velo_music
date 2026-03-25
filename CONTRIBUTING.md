# Contributing to Velo

Thanks for your interest in contributing to `velo`.

## Development Setup

1. Fork the repository.
2. Clone your fork.
3. Install dependencies:

```bash
flutter pub get
```

4. Create local environment file:
- Add a `.env` file in project root.
- Never commit secrets or credentials.

5. Run the app:

```bash
flutter run
```

## Branch & Commit Guidelines

- Create a feature branch from `main`.
- Use clear branch names:
  - `feature/<short-name>`
  - `fix/<short-name>`
  - `chore/<short-name>`
- Keep commits focused and atomic.
- Prefer descriptive commit messages explaining the "why".

## Code Style

- Follow Flutter and Dart style conventions.
- Keep files modular and feature-oriented.
- Reuse existing patterns in `lib/core/` and `lib/features/`.
- Avoid large unrelated refactors in the same PR.

## Pull Request Checklist

Before opening a PR, ensure:

- `flutter analyze` passes.
- `flutter test` passes.
- New logic has tests where practical.
- UI changes include screenshots or short screen recordings when possible.
- No secrets are included (`.env`, Firebase private keys, service credentials).
- Documentation is updated when behavior changes.

## What to Include in PR Description

- Problem statement.
- Proposed solution.
- Scope of changes.
- Testing notes.
- Any known limitations.

## Security & Sensitive Files

- Do not commit secrets.
- Do not post production credentials in issues/PR comments.
- Review `SECURITY.md` for vulnerability reporting and security expectations.

## Code of Collaboration

- Be respectful and constructive in reviews.
- Assume positive intent.
- Focus discussions on technical outcomes and user value.
