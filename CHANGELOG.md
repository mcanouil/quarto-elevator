# Changelog

## Unreleased

## 1.5.1 (2026-08-01)

### Documentation

- docs: Add a documentation website under `docs/`, built on the `atelier` project type and published to <https://m.canouil.dev/quarto-elevator/>.
- docs: Trim `README.md` to a landing page pointing at the website, and `example.qmd` to a short starting point to copy.
- docs: Add the Pages workflow, which renders `docs/` on pull requests and deploys it from the release tag.
- docs: Add the Quarto Extensions Updates workflow, scanning `docs` for the website's own dependencies.
- docs: Record that a page carries one working button, since each shortcode wires the first one it finds.

## 1.5.0 (2026-05-31)

### Bug Fixes

- fix: JavaScript-escape anchor IDs and audio paths so values containing `"`, `\`, `<`, or newlines no longer break the generated init script.
- fix: Warn (once per render) when the bundled default `ding.mp3` cannot be located alongside the extension.
- fix: HTML-escape the button text so markup in the `text` argument is rendered as plain text rather than dropped or interpreted.

### New Features

- feat: Add `volume` attribute that clamps to the range [0.0, 1.0] and warns on out-of-range or non-numeric input.
- feat: Add `loop-audio` attribute that genuinely disables looping (works around Elevator.js's `setAttribute('loop', 'false')` no-op).
- feat: Add built-in named sounds. `audio=ding` and `end=ding` resolve to the bundled `ding.mp3`.
- feat: Add `shortcut` attribute to trigger the elevator from anywhere outside form fields via a keyboard key.
- feat: Add document-level disable via `extensions.elevator.enabled: false` in YAML metadata.

### Documentation

- docs: Document new attributes (`volume`, `loop-audio`, `shortcut`), built-in sounds, and global disable in `README.md`, `example.qmd`, `_schema.yml`, and `_snippets.json`.

### Refactoring

- refactor: Add `escape_js_string` helper to the shared `_modules/string.lua` module.
- refactor: Sync `_modules/` doc-style metadata with the canonical module headers and ship `_modules/logging.lua` alongside `string.lua` and `html.lua`.

## 1.4.0 (2026-03-23)

### Refactoring

- refactor: Replace monolithic `utils.lua` with focused modules (`string.lua`, `logging.lua`, `metadata.lua`, `pandoc-helpers.lua`, `html.lua`, `paths.lua`, `colour.lua`).

## 1.3.0 (2026-02-21)

### New Features

- feat: Add extension-provided code snippets (#23).
- feat: Add _schema.yml for configuration validation and IDE support (#19).

## 1.2.1 (2026-02-11)

### Bug Fixes

- fix: Update copyright year.
- fix: Use british english spelling.

## 1.2.0 (2025-10-29)

### Bug Fixes

- fix: Handle native back-to-top button (#14).

## 1.1.0 (2025-10-25)

### New Features

- feat: Add author information and improve metadata in example.qmd.
- feat: Refactor and enhance using module with improved logging and HTML dependency management (#12).

## 1.0.2 (2025-04-05)

### Bug Fixes

- fix: Add output-file option.

## 1.0.1 (2025-04-05)

### New Features

- feat: Add CITATION file for project citation.

### Bug Fixes

- fix: Switch to deploy from GitHub Actions (#7).

### Documentation

- docs: Update quarto command.
- docs: Add explicitly source, author, and license.

## 1.0.0 (2022-12-27)

### Bug Fixes

- fix: Update/Release for Quarto v1.2 (#2).
- fix: Phrasing.

## 0.1.1 (2022-09-12)

### Bug Fixes

- fix: Audio file to root for example.

## 0.1.0 (2022-09-12)

