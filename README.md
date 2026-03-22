# legionio-spec

Interface contract specs for LegionIO — OpenAPI, AMQP, DB, MCP.

## Phase 1: REST API (current)

Complete OpenAPI 3.1.0 spec for the LegionIO daemon REST API (port 4567).

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
├── paths/                # One YAML file per route group
└── schemas/              # Shared schema definitions
dist/
└── openapi.json          # Bundled output (committed)
```

### For Consumers

Use `dist/openapi.json` as a git submodule, npm dependency, or direct download.

## Future Phases

- Phase 2: AMQP message schemas (`amqp/`)
- Phase 3: Database schemas (`db/`)
- Phase 4: MCP tool schemas (`mcp/`)

## License

Apache-2.0
