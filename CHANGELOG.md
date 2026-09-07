# Changelog

## 0.2.0

- **Breaking:** requests now go to the versioned mount. `RestClient`
  prepends `RestClient.apiVersion` (`v1`) to every path, and
  `WebhookExecuteClient` does the same. Managers still name routes
  unversioned, so only code driving `HttpTransport` directly is affected.
- `X-Audit-Log-Reason` support: `RestClient.requestJson` takes an
  `auditLogReason`, threaded through message delete, bulk delete, pin,
  unpin, kick, role delete, sticker delete, emoji update, guild update
  and webhook update.
- `MessageRestManager` gained `fetch`, `pins`, `pin`, `unpin`,
  `triggerTyping`, `removeOwnReaction`, `removeAllReactions`,
  `removeEmojiReactions`, `listReactionUsers` and `bulkDeleteMine`, and
  `list` now takes `before`/`after`/`around` cursors.
- `MessageBuilder` gained `allowedMentions`, `flag`, `sticker`,
  `attachment`, `tts` and `nonce`.
- `AttachmentRestManager` and `AttachmentUploader` implement the
  three-step upload flow: plan the upload, transfer the bytes to the
  presigned storage URL, then claim the result on a message. `uploadFile`
  does the first two steps for the common case.
- `InstanceRestManager` reads a deployment's `/.well-known/fluxer`
  document, which is what lets one binary target any self-hosted
  instance rather than hardcoding origins.
- `UserRestManager` gained `fetchCurrent`, `fetch`, `guilds`,
  `leaveGuild` and `privateChannels`.
- `GuildRestManager` gained `update`, `webhooks`, `vanityUrl` and
  `searchMembers`.
- `ChannelRestManager` gained `slowmodeWait`, `addRecipient` and
  `removeRecipient`; `GuildEmojiRestManager` and `WebhookRestManager`
  gained `update`.

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
