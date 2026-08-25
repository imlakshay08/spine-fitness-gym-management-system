-- ============================================================================
--  WhatsApp Inbox — render reactions the way WhatsApp does
--  Matches migration db/migrate/20260825100000_add_reaction_to_trn_whatsapp_inbox.rb
--
--  Run on PRODUCTION only if you are not running `rails db:migrate` there.
--  One table is affected: trn_whatsapp_inbox.
--
--  Why: a reaction arrives as its own webhook message carrying the id of the
--  message it belongs to. Without somewhere to keep that id the inbox showed
--  an empty "Reaction message" bubble instead of an emoji on the real message.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- 0. Pre-check — expect 0. If it returns 1, this is already applied.
-- ---------------------------------------------------------------------------
SELECT COUNT(*) AS already_applied
FROM   information_schema.COLUMNS
WHERE  TABLE_SCHEMA = DATABASE()
AND    TABLE_NAME   = 'trn_whatsapp_inbox'
AND    COLUMN_NAME  = 'wi_reaction_to';


-- ---------------------------------------------------------------------------
-- 1. Add the column
--
--    wi_reaction_to  wamid of the message this reaction is attached to
-- ---------------------------------------------------------------------------
-- Safety net: this ALTER rebuilds the table and re-validates every row, so any
-- legacy '0000-00-00' date would trip strict sql_mode. Relaxed for THIS session
-- only; server config and existing values are untouched.
SET SESSION sql_mode = REPLACE(REPLACE(REPLACE(@@SESSION.sql_mode,
  'NO_ZERO_DATE', ''), 'NO_ZERO_IN_DATE', ''), 'STRICT_TRANS_TABLES', '');

ALTER TABLE `trn_whatsapp_inbox`
  ADD COLUMN `wi_reaction_to` varchar(200) DEFAULT NULL,
  ADD INDEX  `idx_wa_inbox_reaction_to` (`wi_reaction_to`);


-- ---------------------------------------------------------------------------
-- 2. Record the migration so a later `rails db:migrate` does not re-run it
-- ---------------------------------------------------------------------------
INSERT IGNORE INTO `schema_migrations` (`version`) VALUES ('20260825100000');


-- ---------------------------------------------------------------------------
-- 3. Verify
-- ---------------------------------------------------------------------------
SHOW COLUMNS FROM `trn_whatsapp_inbox` LIKE 'wi\_reaction\_to';

-- Reactions already received before this change have no target recorded and
-- cannot be matched to a message, so the inbox hides them. New ones attach
-- correctly. This shows how many are in that state:
SELECT COUNT(*) AS orphan_reactions
FROM   `trn_whatsapp_inbox`
WHERE  `wi_message_type` = 'reaction' AND `wi_reaction_to` IS NULL;
