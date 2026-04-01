# Changelog

## [0.1.0] - 2026-03-31

### Added
- Ruby gem scaffold (`legionio-spec`) alongside the existing OpenAPI YAML specs
- `Legion::Spec::Vcr` module — VCR-style cassette system for deterministic LLM integration tests
- `Legion::Spec::Vcr::Cassette` — records and replays `Legion::LLM` interactions (`.chat`, `.ask`, `.embed`, `.chat_direct`)
- Three record modes: `:once` (default), `:always`, `:none`
- SHA256 request hashing for deterministic playback matching
- `Legion::Spec::Vcr::CassetteMissingError` and `CassettePlaybackError` error hierarchy
- 33 RSpec examples with 99% line coverage
