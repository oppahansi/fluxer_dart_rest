# Changelog

## 0.5.0

- `GuildRestManager.listChannels` and `updateChannelPositions`, with
  `ChannelPositionUpdate`. The list excludes threads; a reorder is
  answered by one or more `CHANNEL_UPDATE_BULK` dispatches.
- `GuildRoleRestManager.update` with `GuildRoleUpdateBuilder`,
  `updatePositions`, `updateHoistPositions` and `resetHoistPositions`.
- `GuildMemberRestManager.getCurrent` and `updateCurrent` with
  `CurrentMemberUpdateBuilder`: this bot's own nickname and guild
  profile. A setter given `null` sends an explicit `null`, which clears
  the field.
- Fixed: `GuildStickerRestManager.create` sent `tags` as a string; the
  API takes an array, so any call passing tags was rejected with a 400.
  `tags` is now a `List<String>`. **Breaking** for callers passing it.

## 0.4.0

- `ThreadRestManager`: `startFromMessage`, `start`, `createPost` for a
  forum or media channel, `update` with the new `ThreadUpdateBuilder`,
  `delete`, `listActive`, the three archive listings, and thread
  membership (`join`, `leave`, `addMember`, `removeMember`, `getMember`,
  `listMembers`).
- `ChannelRestManager.createTag`, `updateTag` and `deleteTag` for forum
  tags. Each returns the updated forum channel.
- `ChannelCreateBuilder` creates a forum or media channel when given
  `ChannelType.guildForum` or `guildMedia`; nothing else changed there.
- Sending, listing, pinning and reacting in a thread need nothing new:
  the existing `MessageRestManager` calls take the thread's id as the
  channel id.
- Not covered: thread search, forum post data, and `thread_id` on webhook
  execution.

## 0.3.0

- `ChannelRestManager.follow` and `followerStats` — following an
  announcement channel creates a channel follower webhook in the target
  channel, named by `FollowedChannel.webhookId`, and deleting that
  webhook stops following.
- `MessageRestManager.crosspost` and `crosspostSource` for publishing a
  message to following channels and reading where a copy came from.
- `AttachmentRestManager.refreshUrls` re-signs stored attachment URLs,
  whose signatures expire.
- `GuildEmojiRestManager.source` and `GuildStickerRestManager.source`
  name the guild an expression belongs to.
- `RestClient.requestJson` takes a `captchaToken`, sent as
  `X-Captcha-Token`. Adding a recipient to a group DM is now captcha
  gated even for a bot token, so `ChannelRestManager.addRecipient` takes
  one; solving the ALTCHA proof-of-work challenge is the caller's job.
- Fixed a broken doc reference on `InstanceRestManager`.

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
