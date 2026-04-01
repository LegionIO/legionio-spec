# legionio-spec

Interface contract specs for LegionIO — OpenAPI, AMQP, DB, MCP.

## Phase 1: REST API (current)

Complete OpenAPI 3.1.0 spec for the LegionIO daemon REST API (port 4567). Covers 30+ route groups and 20+ shared schema types.

### Quick Start

```bash
npm install
npx @redocly/cli lint api/openapi.yaml
./scripts/bundle.sh
```

### Structure

```
api/
├── openapi.yaml          # Root spec
├── paths/                # One YAML file per route group (30+ files)
└── schemas/              # Shared schema definitions (20+ files)
dist/
└── openapi.json          # Bundled output (committed)
scripts/
├── bundle.sh             # Bundle split YAML into dist/openapi.json
└── coverage.sh           # Coverage report
```

### For Consumers

Use `dist/openapi.json` directly. Reference as a git submodule or download from the GitHub releases page.

Every response follows the `{ data, meta }` envelope. Every error follows `{ error: { code, message }, meta }`.

## Future Phases

- Phase 2: AMQP message schemas (`amqp/`)
- Phase 3: Database schemas (`db/`)
- Phase 4: MCP tool schemas (`mcp/`) — all 58 tools

## License

Apache-2.0
