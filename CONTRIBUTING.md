# Contributing

## Branching strategy

- `main` — always releasable. Only merged into via reviewed PRs from `develop` (or a `fix/` branch for hotfixes).
- `develop` — integration branch. All feature and fix work merges here first.
- `feature/<name>` — new functionality, branched off `develop` (e.g. `feature/app-time-limits`).
- `fix/<name>` — bug fixes, branched off `develop` (or off `main` for urgent hotfixes, then back-merged into `develop`).

## Commit messages

This project uses [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>: <short summary>
```

Types:

- `feat:` — a new feature
- `fix:` — a bug fix
- `chore:` — tooling, dependencies, or other non-code-behavior changes
- `docs:` — documentation only
- `refactor:` — code change that neither fixes a bug nor adds a feature
- `test:` — adding or correcting tests

Example: `feat: add per-app daily time limit notifications`

## Versioning

`pubspec.yaml`'s `version` field follows semantic versioning plus a build number:

```
MAJOR.MINOR.PATCH+BUILD
```

- **MAJOR** — incompatible or breaking changes.
- **MINOR** — new functionality, backward-compatible.
- **PATCH** — backward-compatible bug fixes.
- **BUILD** — incremented on every build (maps to Android `versionCode` / iOS `CFBundleVersion`).

## Before opening a PR

- `dart format --output=none --set-exit-if-changed .` passes.
- `flutter analyze --fatal-infos` passes.
- `flutter test --coverage` passes.
- New Android permissions are called out explicitly in the PR description.
