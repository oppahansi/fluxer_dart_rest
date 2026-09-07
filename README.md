# fluxer_dart_rest

REST client for the [fluxer_dart](https://github.com/oppahansi/fluxer_dart) ecosystem.

Endpoint paths, the `Authorization: Bot <token>` header, and the
`X-RateLimit-*` response header names follow
[Fluxer's HTTP API reference](https://docs.fluxer.app/http-api/),
cross-checked against the deployment's own OpenAPI document
(`/v1/openapi.json`), which is served unauthenticated and is the
authoritative source where the two disagree.

They do disagree. The reference's messages page documents pin listing as
`GET /channels/{id}/pins` returning an array of messages; the route the
spec declares, and the one the server actually answers, is
`GET /channels/{id}/messages/pins` returning a `{items, has_more}`
envelope whose entries pair each message with its `pinned_at` time. Both
are modelled here from the spec. Treat the prose reference as the better
explanation of *why* a route behaves as it does, and the spec as the
description of *what* it accepts and returns.

Requests go to the versioned mount: every route is also reachable at the
origin root, but `/v1` is the form clients are expected to use, and
`RestClient` adds it.

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
  `MessageRestManager`, `GuildMemberRestManager`, `GuildBanRestManager`,
  `GuildEmojiRestManager`, `GuildStickerRestManager`,
  `GuildRoleRestManager`, `InviteRestManager`, `WebhookRestManager`) mirror
  Fluxer's own OpenAPI grouping — a Repository-pattern layer returning
  typed `fluxer_dart_core` models instead of raw JSON.
- `MessageBuilder` — Builder pattern for outgoing message payloads.

## What's here

The REST surface `fluxer_dart`'s `Bot` facade is built on: guild, channel,
message, member, ban, emoji, sticker, role, invite, and webhook resource
managers, gateway bot-info lookup, and reactive per-route rate limiting.
Hand-written rather than generated from the OpenAPI spec — evaluated and
decided against for now, see the roadmap in this ecosystem's planning
docs for why. Audit log endpoints aren't modeled yet.

## Fluxer version

Verified against Fluxer's REST API version `1.0.0` (the OpenAPI spec's
own `info.version` field, at `api.fluxer.app/openapi.json`), checked
against a self-hosted instance running image tag `v1` as of 2026-08-12.
Fluxer doesn't publish a versioning policy or changelog beyond that
`info.version` field, so nothing here is guaranteed to track future
platform changes automatically — re-check the live OpenAPI spec before
relying on identical behavior after Fluxer updates.

## Part of the fluxer_dart ecosystem

| Package | Purpose |
|---|---|
| [`fluxer_dart_utils`](https://github.com/oppahansi/fluxer_dart_utils) | generic building blocks |
| [`fluxer_dart_core`](https://github.com/oppahansi/fluxer_dart_core) | domain models |
| [`fluxer_dart_rest`](https://github.com/oppahansi/fluxer_dart_rest) | *(this package)* REST client |
| [`fluxer_dart_gateway`](https://github.com/oppahansi/fluxer_dart_gateway) | WebSocket gateway client |
| [`fluxer_dart_voice`](https://github.com/oppahansi/fluxer_dart_voice) | voice support |
| [`fluxer_dart`](https://github.com/oppahansi/fluxer_dart) | main framework — the `Bot` facade |
| [`fluxer_dart_bot`](https://github.com/oppahansi/fluxer_dart_bot) | example bot |

## Installation

Not yet published to pub.dev — depend on it via a git dependency, pinned
to a tagged release:

```yaml
dependencies:
  fluxer_dart_rest:
    git:
      url: https://github.com/oppahansi/fluxer_dart_rest.git
      ref: v0.1.0
```

See [CHANGELOG.md](CHANGELOG.md) for what's in each tagged release.

## License

MIT — see [LICENSE](LICENSE).
