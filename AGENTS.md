# AGENTS.md

Guidance for agents working in this repository.

## Repository Purpose

This is a public Ruby template for small applications, services, and libraries.
Keep changes template-friendly: portable, minimal, and useful to downstream
projects without assuming any contributor's local machine.

The important project surfaces are:

- `lib/` contains the example Ruby application code.
- `spec/` contains RSpec unit and acceptance tests.
- `script/` contains the "Scripts to Rule Them All" entrypoints.
- `vendor/cache/` contains the committed RubyGems cache used for hermetic
  bootstrap, test, lint, build, and CI paths.
- `.bundle/config` keeps Bundler frozen and pointed at repo-local paths.
- `.github/workflows/` contains SHA-pinned CI workflows.

## Operating Principles

- Prefer the smallest change that solves the requested problem.
- Do not introduce dependencies unless they carry their weight.
- Preserve hermetic behavior: normal local and CI paths must use the committed
  lockfile and `vendor/cache/`, not resolve from RubyGems at runtime.
- Keep public-repo changes free of secrets, host-specific paths, personal local
  settings, and generated machine state.
- Keep scripts as the stable interface. Update scripts and docs together when
  behavior changes.

## Dependency Model

Ruby dependencies are intentionally vendored:

- `Gemfile.lock` must include checksums.
- `.bundle/config` must keep the bundle frozen.
- `vendor/cache/*.gem` must exactly match the lockfile.
- `vendor/gems/` is an ignored local install target and should not be committed.
- Use `script/vendor` for intentional networked dependency refreshes.

The default dependency set should stay lean. This template should normally need
only RSpec for tests and RuboCop for linting. Prefer Ruby's standard library for
coverage, subprocesses, parsing, fixtures, and small helpers.

## Scripts

Use these entrypoints instead of ad hoc commands:

- `script/bootstrap` installs vendored gems locally with `bundle install --local`.
- `script/test` validates Bundler supply-chain state, workflow security, and the
  RSpec suite.
- `script/lint` runs RuboCop with the repo config.
- `script/build` is the project build hook.
- `script/acceptance` runs the Docker-backed acceptance test.
- `script/tarball` builds and checks the deploy tarball demo.
- `script/vendor` refreshes the vendored gem cache and lockfile checksums.

Scripts should source `script/env` for shared paths, Ruby version, Bundler
environment, colors, and production-mode behavior. New shell scripts should use
`#!/usr/bin/env bash`, `set -euo pipefail`, paths relative to the script
location, and idempotent cleanup where practical.

## Testing And Coverage

Tests are powered by RSpec. Coverage is powered by Ruby stdlib `Coverage`, not
SimpleCov or generated HTML reports.

Use the normal RSpec DSL in specs: prefer `describe RubyTemplate do` over
`RSpec.describe RubyTemplate do`.

Keep `lib/**/*.rb` at 100% line coverage. If new executable files are added
under `lib/`, add focused specs rather than weakening the coverage gate.

## Linting

RuboCop is intentionally core-only in this template. Keep `.rubocop.yml`
portable and avoid organization-specific inherited configs unless the dependency
is intentionally restored and vendored.

Use double quotes for strings unless single quotes are required by the code.
Prefer clear names and straightforward control flow over clever Ruby.

## CI And GitHub

- Keep workflow `permissions:` scoped to the minimum needed.
- Keep third-party `uses:` references pinned to full commit SHAs.
- Keep `actions/checkout` configured with `persist-credentials: false`.
- Keep `ruby/setup-ruby` configured with `bundler: none` and
  `bundler-cache: false`; Bundler should use the repo vendored cache.
- The sealed `build`, `lint`, and `test` workflows should run
  `step-security/harden-runner` first with blocked egress.

## Pull Requests

For PRs in this public template:

- Keep the branch focused.
- Commit lockfile and `vendor/cache/` changes together.
- Mention dependency tree changes when they are part of the diff.
- Avoid noisy validation transcripts in the PR body; CI is the source of truth.
