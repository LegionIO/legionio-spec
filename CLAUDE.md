# legionio-spec: Interface Contract Repository

**Level 3 Documentation**
- **Parent**: `/Users/miverso2/rubymine/legion/CLAUDE.md`
- **GitHub**: https://github.com/LegionIO/legionio-spec

## Purpose

Single source of truth for all LegionIO interface contracts. External consumers (SDKs, third-party integrations) reference this repo to know what endpoints exist, what payloads to send, and what responses to expect.

## Repository Layout

```
legionio-spec/
├── api/
│   ├── openapi.yaml          # Root OpenAPI 3.1.0 spec
│   ├── paths/                # One YAML file per route group (30+ files)
│   └── schemas/              # Shared schema definitions (20+ files)
├── amqp/                     # Phase 2: AMQP message schemas (planned)
├── db/                       # Phase 3: Database schemas (planned)
├── mcp/                      # Phase 4: MCP tool schemas (planned)
├── dist/
│   └── openapi.json          # Bundled output (committed, use this for consumers)
└── scripts/
    ├── bundle.sh             # Bundles split YAML into dist/openapi.json
    └── coverage.sh           # Coverage report: paths vs spec vs implementation
```

## Commands

```bash
npm install                                      # install redocly
npx @redocly/cli lint api/openapi.yaml           # lint the spec
./scripts/bundle.sh                              # bundle to dist/openapi.json
```

## Adding a New Route

1. Find or create the path file in `api/paths/`
2. Add the route with operationId, tags, request/response schemas
3. Reference shared schemas from `api/schemas/` via $ref
4. Add path refs to `api/openapi.yaml` root
5. Run `npx @redocly/cli lint api/openapi.yaml` — must pass
6. Run `./scripts/bundle.sh` — commit updated `dist/openapi.json`

## Conventions

- OpenAPI 3.1.0, YAML format
- Every response uses the `{ data, meta }` wrapper (or `{ error, meta }` for errors)
- Every request body gets a named schema in `schemas/`
- operationId is camelCase: `listTasks`, `getWorker`, `createSchedule`
- Tags match route groups: Health, Tasks, Workers, LLM, etc.

## Coverage

The spec covers the LegionIO REST API (port 4567). Implemented path groups include:
`acp`, `audit`, `auth`, `capacity`, `catalog`, `chains`, `coldstart`, `events`, `extensions`,
`gaia`, `governance`, `graphql`, `health`, `hooks`, `lex`, `llm`, `marketplace`, `metrics`,
`nodes`, `org-chart`, plus all shared schema types.

## Roadmap

- Phase 2: AMQP message schemas (`amqp/`) — envelope, routing keys, all message types
- Phase 3: Database schemas (`db/`) — table definitions, migration contracts
- Phase 4: MCP tool schemas (`mcp/`) — tool input/output definitions for all 58 tools

---

**Maintained By**: Matthew Iverson (@Esity)
