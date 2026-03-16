# Contributing to ZERPAI

Thanks for your interest in contributing to ZERPAI. We welcome issues and pull requests — please follow these guidelines to make collaboration smooth.

How to contribute

- Fork the repository and create a branch using a clear name: `feat/`, `fix/`, or `chore/` prefixes. Example: `feat/items-search`.
- Commit messages should be concise and descriptive. Use present tense (e.g., "Add item search filter").
- Open a pull request (PR) against the `dev` branch. Include a short description, motivation, and screenshots if UI changes.

Before opening a PR

- Run `flutter pub get` locally.
- Run `flutter analyze` and fix reported issues.
- Run `flutter test` and ensure tests pass.
- Format your code: `flutter format .`

Testing and CI

- The repository contains a GitHub Actions workflow that runs `flutter analyze` and `flutter test` on PRs and pushes to `dev` and `main`.

Code style

- Follow existing project structure under `lib/` — add new modules under `lib/modules/`.
- Keep UI logic in widgets and business logic in providers/services according to existing patterns.

License & Copyright

- This repository is proprietary. By contributing, you confirm that you have the right to submit the code and accept that contributions will be governed by the repository's license. See `LICENSE`.

Thank you for helping improve ZERPAI!
