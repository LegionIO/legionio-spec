# legionio-spec: Interface Contract Repository

## Purpose

Single source of truth for all LegionIO interface contracts. External consumers
(legion-interlink, SDKs, third-party integrations) reference this repo to know
what endpoints exist, what payloads to send, and what responses to expect.

## Structure

- `api/openapi.yaml` — Root OpenAPI 3.1.0 spec
- `api/paths/*.yaml` — One file per route group
- `api/schemas/*.yaml` — Shared schema definitions
- `dist/openapi.json` — Bundled output (committed)
- `scripts/bundle.sh` — Bundles split YAML into dist/openapi.json

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
