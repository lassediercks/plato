# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
