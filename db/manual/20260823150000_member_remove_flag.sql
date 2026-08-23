-- ============================================================================
--  Member List — "remove" instead of "delete"
--  Matches migration db/migrate/20260823150000_add_status_to_mst_members_lists.rb
--
--  Run on PRODUCTION only if you are not running `rails db:migrate` there.
--  One table is affected: mst_members_lists. Nothing else changed.
--
--  Why: subscriptions, payments, attendance and WhatsApp logs all point at
--  mst_members_lists.id. Deleting the row turns those into "Unknown member".
--  A status flag hides the member from lists while every record still resolves.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- 0. Pre-check — expect 0. If it returns 4, this is already applied.
-- ---------------------------------------------------------------------------
SELECT COUNT(*) AS already_applied
FROM   information_schema.COLUMNS
WHERE  TABLE_SCHEMA = DATABASE()
AND    TABLE_NAME   = 'mst_members_lists'
AND    COLUMN_NAME IN ('mmbr_status', 'mmbr_removed_at', 'mmbr_removed_by', 'mmbr_remove_reason');


-- ---------------------------------------------------------------------------
-- 1. Add the columns (one ALTER = one table rebuild)
--
--    mmbr_status         'A' = on roll, 'R' = removed
--    mmbr_removed_at     when it happened
--    mmbr_removed_by     which staff login did it
--    mmbr_remove_reason  optional note typed in the remove dialog
--
--  Run the SET SESSION line in the SAME session/tab as the ALTER.
-- ---------------------------------------------------------------------------
-- REQUIRED FIRST. mst_members_lists is MyISAM, so this ALTER rebuilds the whole
-- table by copying every row, and MySQL re-validates each one on the way in.
-- Legacy rows hold '0000-00-00' dates (created_at, updated_at, mmbr_entry_date),
-- which today's strict sql_mode rejects — that is the
--   "Incorrect datetime value: '0000-00-00 00:00:00.000000'"
-- error. This relaxes only the zero-date checks, only for THIS session; the
-- server config is untouched and the existing dates are copied through as-is.
SET SESSION sql_mode = REPLACE(REPLACE(REPLACE(@@SESSION.sql_mode,
  'NO_ZERO_DATE', ''), 'NO_ZERO_IN_DATE', ''), 'STRICT_TRANS_TABLES', '');

ALTER TABLE `mst_members_lists`
  ADD COLUMN `mmbr_status`        varchar(1)   NOT NULL DEFAULT 'A',
  ADD COLUMN `mmbr_removed_at`    datetime     DEFAULT NULL,
  ADD COLUMN `mmbr_removed_by`    varchar(50)  DEFAULT NULL,
  ADD COLUMN `mmbr_remove_reason` varchar(250) DEFAULT NULL,
  ADD INDEX  `idx_members_compcode_status` (`mmbr_compcode`, `mmbr_status`);


-- ---------------------------------------------------------------------------
-- 2. Backfill — everyone currently in the system is on the roll
-- ---------------------------------------------------------------------------
UPDATE `mst_members_lists`
SET    `mmbr_status` = 'A'
WHERE  `mmbr_status` IS NULL OR `mmbr_status` = '';


-- ---------------------------------------------------------------------------
-- 3. Record the migration so a later `rails db:migrate` does not re-run it
-- ---------------------------------------------------------------------------
INSERT IGNORE INTO `schema_migrations` (`version`) VALUES ('20260823150000');


-- ---------------------------------------------------------------------------
-- 4. Verify — expect every member on 'A', none on 'R' yet
-- ---------------------------------------------------------------------------
SELECT `mmbr_status`, COUNT(*) AS members
FROM   `mst_members_lists`
GROUP  BY `mmbr_status`;
