-- ============================================================================
--  WhatsApp Inbox — store incoming media so photos, videos, documents and
--  stickers can actually be viewed
--  Matches migration db/migrate/20260828120000_add_media_to_trn_whatsapp_inbox.rb
--
--  Run on PRODUCTION only if you are not running `rails db:migrate` there.
--  One table is affected: trn_whatsapp_inbox.
--
--  Why: Meta's webhook sends a media ID, not a file and not a URL. The app has
--  to exchange that ID for a short-lived signed URL and fetch it with the
--  access token. None of it was being stored, so every image, video, document
--  and sticker showed up as an empty "... message" bubble.
-- ============================================================================

-- 0. Pre-check — expect 0. If it returns 3, this is already applied.
SELECT COUNT(*) AS already_applied
FROM   information_schema.COLUMNS
WHERE  TABLE_SCHEMA = DATABASE()
AND    TABLE_NAME   = 'trn_whatsapp_inbox'
AND    COLUMN_NAME IN ('wi_media_id', 'wi_media_mime', 'wi_media_name');


-- 1. Add the columns
--
--    wi_media_id    Meta's media id, exchanged for a signed URL on view
--    wi_media_mime  image/jpeg, video/mp4, application/pdf, image/webp ...
--    wi_media_name  original file name, for documents
--
-- Safety net: this ALTER rebuilds the table and re-validates every row, so any
-- legacy '0000-00-00' date would trip strict sql_mode. Relaxed for THIS session
-- only; server config and existing values are untouched.
SET SESSION sql_mode = REPLACE(REPLACE(REPLACE(@@SESSION.sql_mode,
  'NO_ZERO_DATE', ''), 'NO_ZERO_IN_DATE', ''), 'STRICT_TRANS_TABLES', '');

ALTER TABLE `trn_whatsapp_inbox`
  ADD COLUMN `wi_media_id`   varchar(200) DEFAULT NULL,
  ADD COLUMN `wi_media_mime` varchar(100) DEFAULT NULL,
  ADD COLUMN `wi_media_name` varchar(255) DEFAULT NULL;


-- 2. Record the migration so a later `rails db:migrate` does not re-run it
INSERT IGNORE INTO `schema_migrations` (`version`) VALUES ('20260828120000');


-- 3. Verify
SHOW COLUMNS FROM `trn_whatsapp_inbox` LIKE 'wi\_media\_%';
