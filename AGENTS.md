# AGENTS.md

Guidance for agents working in this public Ruby template repository.

## Repository Purpose

Keep this template portable, minimal, and useful for small Ruby applications, services, and libraries. Do not add host-specific paths, personal configuration, secrets, or generated machine state.

The main project surfaces are `lib/` for application code, `spec/` for unit and acceptance tests, `script/` for stable developer and CI entrypoints, `vendor/cache/` for committed gems, and `.github/workflows/` for CI.

## Working Principles

- Prefer the smallest complete change and avoid speculative abstractions.
- Start with Ruby's standard library and add a dependency only when it clearly earns its maintenance and trust cost.
- Keep `script/*` as the shared interface used by developers, CI, builds, and releases.
- Preserve offline bootstrap, test, lint, and build paths by using the lockfile and committed dependency cache.
- Update documentation and tests with behavior changes.

## Versions And Dependencies

- `.ruby-version` is the source of truth for the exact Ruby version.
- Keep direct gems exact-version pinned, `Gemfile.lock` checksummed, and every matching `.gem` committed under `vendor/cache/`.
- Keep `.bundle/config` frozen and pointed at `vendor/gems/` and `vendor/cache/`.
- Use `script/vendor` only for intentional networked dependency refreshes, then commit the lockfile and cache changes together.
- Pin Git dependencies to full 40-character commit SHAs.
- Pin every Docker base image to the exact Ruby version and a full `sha256` manifest digest.

## Scripts

- `script/bootstrap` installs only from the vendored gem cache.
- `script/test` validates dependency bytes, immutable workflow and Docker references, and the RSpec suite.
- `script/lint` runs the repository's RuboCop configuration.
- `script/build` is the project build hook.
- `script/acceptance` exercises the containerized application boundary.
- `script/tarball` builds the deployment tarball example.
- `script/vendor` is the explicit dependency update path.

Shell scripts should use `#!/usr/bin/env bash`, `set -euo pipefail`, repository-relative paths, scoped cleanup, and `script/env` for shared environment setup.

## Testing

- Keep `lib/**/*.rb` at 100% line, branch, and method coverage using Ruby's standard library `Coverage` API.
- Add focused tests for behavior changes and regression tests for bug fixes.
- Keep unit tests deterministic and independent of live network services.
- Keep acceptance tests behind `script/acceptance` and run them locally and in CI when consumer-facing behavior changes.
- Do not weaken coverage or security checks to make a change pass.

## CI And GitHub

- Keep every external `uses:` reference pinned to a full commit SHA.
- Run a full-SHA-pinned `GrantBirki/fence` action as the first step in each workflow job.
- Keep workflow permissions minimal and set `persist-credentials: false` on checkout.
- Configure `ruby/setup-ruby` with `bundler: none` and `bundler-cache: false` so Bundler uses the committed cache.
- Keep `script/**` excluded from GitHub language statistics through `.gitattributes`.

## Pull Requests

Keep changes focused, review the complete dependency graph when it changes, and rely on CI rather than adding validation transcripts to the PR body.
