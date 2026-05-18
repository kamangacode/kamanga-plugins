# Changelog

All notable changes to this project will be documented in this file.

Entries are generated automatically by `/promote` and committed to staging before the promotion PR.

## [Unreleased]

### Breaking
- dev-core: `/dev` `requirements` step now BLOCKS on F-lite / F-full when `stack.yml.requirements.enabled: true` and no REQ artifact references the issue (and no skip marker is set). Previously this case was silently skipped (#5). Opt-out: leave `requirements.enabled` unset or set it to `false` — same behavior as today. Opt-in skip per issue: run `/req --issue N` and pick "skip", which writes `.claude/req-skipped/{N}.md`.

## [v0.2.0] - 2026-03-09

### Added
- feat(dev-core): add Fumadocs scaffold — ADR 007 + /init Phase 7 extension (#44)
- feat(init): add Fumadocs scaffold — Phase 7b + 9b (#38)
- feat(doctor): add docs structure checks and repair offer (#45)

## [v0.1.0] - 2026-03-06

### Fixed
- fix(doctor): detect missing `contents: read` in job-level CI permissions for private repos (#30)

### Documentation
- docs(image-prompt-generator): update README to document structured intake, face reference, and auto-save features; fix stale Phase 2.75 reference in SKILL.md
