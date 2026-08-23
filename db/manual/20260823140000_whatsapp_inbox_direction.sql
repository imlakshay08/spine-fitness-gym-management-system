-- ============================================================================
--  WhatsApp Inbox — outgoing messages get their own rows
--  Matches migration db/migrate/20260823140000_add_direction_to_trn_whatsapp_inbox.rb
--
--  Run this on PRODUCTION only if you are not running `rails db:migrate` there.
--  One table is affected: trn_whatsapp_inbox. Nothing else changed.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- 0. Pre-check — should return 0. If it returns 4, the change is already in
--    place (you ran db:migrate) and you can stop here.
-- ---------------------------------------------------------------------------
SELECT COUNT(*) AS already_applied
FROM   information_schema.COLUMNS
WHERE  TABLE_SCHEMA = DATABASE()
AND    TABLE_NAME   = 'trn_whatsapp_inbox'
AND    COLUMN_NAME IN ('wi_direction', 'wi_status', 'wi_seen_at', 'wi_error');


-- ---------------------------------------------------------------------------
-- 1. Add the columns (one ALTER = one table rebuild)
--
--    wi_direction  IN  = member -> gym,  OUT = gym -> member
--    wi_status     SENT / DELIVERED / READ / FAILED for outgoing rows
--    wi_seen_at    when staff opened the thread (drives the unread badge)
--    wi_error      Meta's rejection reason on a failed send
-- ---------------------------------------------------------------------------
ALTER TABLE `trn_whatsapp_inbox`
  ADD COLUMN `wi_direction` varchar(3)   NOT NULL DEFAULT 'IN' AFTER `updated_at`,
  ADD COLUMN `wi_status`    varchar(20)  DEFAULT NULL          AFTER `wi_direction`,
  ADD COLUMN `wi_seen_at`   datetime     DEFAULT NULL          AFTER `wi_status`,
  ADD COLUMN `wi_error`     varchar(250) DEFAULT NULL          AFTER `wi_seen_at`;


-- ---------------------------------------------------------------------------
-- 2. Backfill
--    Every existing row is a message the member sent in.
-- ---------------------------------------------------------------------------
UPDATE `trn_whatsapp_inbox`
SET    `wi_direction` = 'IN'
WHERE  `wi_direction` IS NULL OR `wi_direction` = '';

--    Anything already answered counts as read, so historic threads don't all
--    light up as unread the first time the new inbox loads.
UPDATE `trn_whatsapp_inbox`
SET    `wi_seen_at` = `wi_replied_at`
WHERE  `wi_replied` = 1
AND    `wi_seen_at` IS NULL;


-- ---------------------------------------------------------------------------
-- 3. Record the migration so a later `rails db:migrate` does not re-run it
-- ---------------------------------------------------------------------------
INSERT IGNORE INTO `schema_migrations` (`version`) VALUES ('20260823140000');


-- ---------------------------------------------------------------------------
-- 4. Verify — expect the four new columns, and unread_threads to look sane
-- ---------------------------------------------------------------------------
SHOW COLUMNS FROM `trn_whatsapp_inbox`
LIKE 'wi\_%';

SELECT `wi_direction`,
       COUNT(*)                                       AS rows_total,
       SUM(`wi_seen_at` IS NULL)                      AS unseen
FROM   `trn_whatsapp_inbox`
GROUP  BY `wi_direction`;
