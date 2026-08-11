# fluxer_rest

REST client for the [fluxer.dart](https://github.com/oppahansi/fluxer.dart) ecosystem.

Endpoint paths, the `Authorization: Bot <token>` header, and the
`X-RateLimit-*` response header names were all verified against Fluxer's
own OpenAPI spec (`api.fluxer.app/openapi.json`) and reference client
source, since Fluxer's prose REST docs are still unwritten placeholders.

## Design

- `HttpTransport` — the only place this package talks to the network
  (Adapter pattern over `package:http`), so `RestClient` and everything
  built on it is unit-testable with a mocked transport instead of live
  HTTP calls.
- `RateLimitBucketManager` — tracks a token bucket per route, populated
  *reactively* from `X-RateLimit-Limit`/`X-RateLimit-Remaining`/
  `X-RateLimit-Reset` response headers rather than pre-configured with
  guessed capacities. Fluxer doesn't publish per-route limits anywhere;
  the only honest source of truth is the API's own responses.
- Resource-oriented managers (`GuildRestManager`, `ChannelRestManager`,
  `MessageRestManager`) mirror Fluxer's own OpenAPI grouping — a
  Repository-pattern layer returning typed `fluxer_core` models instead of
  raw JSON.
- `MessageBuilder` — Builder pattern for outgoing message payloads.

## What's here (v0.1 — M1 slice)

Enough REST surface for the "hello gateway" vertical slice:
`GuildRestManager.get`, `ChannelRestManager.get`,
`MessageRestManager.send`. Broader coverage (roles, members, emojis,
webhooks, ...) lands in M2, alongside a checkpoint on whether to generate
this layer from the OpenAPI spec instead of hand-writing it — see the
roadmap in this ecosystem's planning docs.

## Part of the fluxer.dart ecosystem

| Package | Purpose |
|---|---|
| [`fluxer_utils`](https://github.com/oppahansi/fluxer_utils) | generic building blocks |
| [`fluxer_core`](https://github.com/oppahansi/fluxer_core) | domain models |
| [`fluxer_rest`](https://github.com/oppahansi/fluxer_rest) | *(this package)* REST client |
| [`fluxer_gateway`](https://github.com/oppahansi/fluxer_gateway) | WebSocket gateway client |
| [`fluxer.dart`](https://github.com/oppahansi/fluxer.dart) | main framework — the `Bot` facade |
| [`fluxer.dart-bot`](https://github.com/oppahansi/fluxer.dart-bot) | example bot |

## Installation

Not yet published to pub.dev. During development, depend on it via a path or
git dependency:

```yaml
dependencies:
  fluxer_rest:
    git:
      url: https://github.com/oppahansi/fluxer_rest.git
```

## License

MIT — see [LICENSE](LICENSE).
