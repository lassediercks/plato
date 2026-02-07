# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.0.20](https://github.com/lassediercks/plato/compare/v0.0.19...v0.0.20) (2026-02-07)


### Features

* introduce doctests, prepare for next ver ([87a7373](https://github.com/lassediercks/plato/commit/87a7373a455364b91367f3fc708a6ff6097f3c73))
* remove demo ([6816433](https://github.com/lassediercks/plato/commit/681643330028cd0e91fb8ff18caee243c83888fb))
* work back from umbrella to single purposed repo ([41d4af1](https://github.com/lassediercks/plato/commit/41d4af1cd8fbeb3fc5fbc54a0941e89d50ca8ed2))


### Bug Fixes

* image path resolution ([3bbd7f9](https://github.com/lassediercks/plato/commit/3bbd7f9db007bfe93e2c2e5a2eb7ea9cd87e98c4))

## [0.0.7] - 2026-02-05

### Changed
- Restructured project as umbrella app with separate library and demo
- Moved all configuration to app-specific directories
- Comprehensive test suite with 142 tests covering all core functionality
- Updated documentation with detailed examples and API reference

### Added
- Test infrastructure with Docker Compose support
- TESTING.md with comprehensive testing documentation
- Proper test coverage for all models and API functions
- DataCase and test helpers for easier test writing

### Fixed
- Docker configuration for proper networking
- Port binding for Docker deployments (0.0.0.0 instead of 127.0.0.1)
- Timestamp handling in tests
- Content update operations now properly merge field values
- Database constraints now handled gracefully with proper error messages

## [0.0.6] - Previous Version

### Added
- Initial schema-driven CMS functionality
- Admin UI for content management
- Schema builder DSL for code-defined schemas
- View helpers for template integration

## [0.0.5] - Earlier Version

### Added
- Basic content management features
- Reference field support
- Unique schema validation

[0.0.7]: https://github.com/lassediercks/plato/compare/v0.0.6...v0.0.7
[0.0.6]: https://github.com/lassediercks/plato/compare/v0.0.5...v0.0.6
[0.0.5]: https://github.com/lassediercks/plato/releases/tag/v0.0.5
