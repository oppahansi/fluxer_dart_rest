# Changelog

## 0.1.0 — Initial release

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
