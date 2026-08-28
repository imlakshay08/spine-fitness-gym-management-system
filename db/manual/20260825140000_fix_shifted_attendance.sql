-- ============================================================================
--  Attendance — correct punch times stored with the device's local clock
--  Matches migration db/migrate/20260825140000_fix_shifted_attendance_punch_times.rb
--
--  Run on PRODUCTION only if you are not running `rails db:migrate` there.
--  One table is affected: trn_member_attendances (data only, no schema change).
--
--  THE BUG
--  Both ingest paths parsed the scanner's timestamp with the ambient
--  Time.zone, and several controller helpers were doing `Time.zone = "Kolkata"`.
--  That setter is thread-local and Puma reuses threads, so the same device
--  produced correct rows AND rows 5h30m ahead, depending on what had run on
--  that thread before. Evening sessions then appeared after midnight on the
--  next day's report, and the dashboard was intermittently wrong too.
--
--  HOW A BAD ROW IS IDENTIFIED
--  created_at is written by Rails in true UTC when the row is saved. A correct
--  punch is within minutes of it. A shifted punch sits 5h30m AHEAD of it —
--  impossible in reality, because a punch cannot happen hours after the row
--  recording it was already written. That makes the test safe and precise.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- 0. How many rows are affected, and what they currently look like
-- ---------------------------------------------------------------------------
SELECT COUNT(*) AS rows_to_fix
FROM   trn_member_attendances
WHERE  TIMESTAMPDIFF(MINUTE, created_at, att_punch_time) BETWEEN 60 AND 360;

-- The give-away: punches "at" times the gym is shut.
SELECT HOUR(CONVERT_TZ(att_punch_time,'+00:00','+05:30')) AS ist_hour_now, COUNT(*) AS n
FROM   trn_member_attendances
WHERE  TIMESTAMPDIFF(MINUTE, created_at, att_punch_time) BETWEEN 60 AND 360
GROUP  BY ist_hour_now ORDER BY ist_hour_now;


-- ---------------------------------------------------------------------------
-- 1. Correct them: pull back 5h30m and recompute the date
--
--    Take a backup of the table first if you want a way back:
--      CREATE TABLE trn_member_attendances_bak_20260825
--        AS SELECT * FROM trn_member_attendances;
-- ---------------------------------------------------------------------------
UPDATE trn_member_attendances
SET    att_punch_time = att_punch_time - INTERVAL 330 MINUTE,
       att_punch_date = DATE(att_punch_time - INTERVAL 330 MINUTE),
       updated_at     = NOW()
WHERE  TIMESTAMPDIFF(MINUTE, created_at, att_punch_time) BETWEEN 60 AND 360;


-- ---------------------------------------------------------------------------
-- 2. Record the migration so a later `rails db:migrate` does not re-run it
-- ---------------------------------------------------------------------------
INSERT IGNORE INTO `schema_migrations` (`version`) VALUES ('20260825140000');


-- ---------------------------------------------------------------------------
-- 3. Verify — expect a gym-shaped day: a morning peak, a quiet midday, an
--    evening peak, and NOTHING between about 11 PM and 5 AM.
-- ---------------------------------------------------------------------------
SELECT HOUR(CONVERT_TZ(att_punch_time,'+00:00','+05:30')) AS ist_hour,
       COUNT(*) AS visits,
       REPEAT('#', LEAST(60, COUNT(*))) AS shape
FROM   trn_member_attendances
WHERE  att_status = 'ALLOWED'
GROUP  BY ist_hour ORDER BY ist_hour;

-- Should return 0 once fixed.
SELECT COUNT(*) AS still_shifted
FROM   trn_member_attendances
WHERE  TIMESTAMPDIFF(MINUTE, created_at, att_punch_time) BETWEEN 60 AND 360;
