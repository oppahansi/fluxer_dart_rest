# Changelog

## 0.2.0 — 2026-08-12

### Added

- `HttpTransport` (Adapter over `package:http`) and `RestClient` — JSON
  decoding, retry on `429`/`5xx`, and a reactive `RateLimitBucketManager`
  populated from Fluxer's own `X-RateLimit-*` response headers rather
  than pre-configured guesses.
- Resource managers: `GuildRestManager`, `ChannelRestManager`,
  `MessageRestManager`, `GuildMemberRestManager`, `GuildBanRestManager`,
  `GuildEmojiRestManager`, `GuildStickerRestManager`,
  `GuildRoleRestManager`, `InviteRestManager`, `WebhookRestManager`,
  `UserRestManager`, `GatewayRestManager`.
- `MessageBuilder` and `EmbedBuilder` (Builder pattern for outgoing
  payloads), `ChannelCreateBuilder`/`ChannelUpdateBuilder`.
- `WebhookExecuteClient` — the separate, no-bot-auth token-based webhook
  execute path (`POST /webhooks/{id}/{token}`), confirmed against the
  live OpenAPI spec to carry no `security` requirement at all.

### Fixed

- `GuildMemberRestManager.list()` was silently returning only 1 member
  on any guild — Fluxer defaults that endpoint's `limit` to 1 when
  omitted, unlike every other list endpoint here. Now sends 100
  explicitly and accepts `limit`/`after` for pagination beyond that.

## 0.1.0

Initial scaffolding: `pubspec.yaml`, `analysis_options.yaml`, MIT
license, CI.
