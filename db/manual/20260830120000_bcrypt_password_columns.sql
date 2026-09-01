-- ============================================================================
--  Passwords — add bcrypt storage alongside the legacy MD5 column
--  Matches migration db/migrate/20260830120000_add_bcrypt_columns_to_users.rb
--
--  Run on PRODUCTION only if you are not running `rails db:migrate` there.
--  One table is affected: users. No existing data is read or rewritten.
--
--  Why: users.userpassword holds an unsalted MD5 hash. MD5 is not a password
--  hash — a leaked dump is reversed by looking each value up in a precomputed
--  table, not by cracking it. bcrypt is added ALONGSIDE it, and each account
--  is silently re-stored as bcrypt the next time its owner logs in. Nobody is
--  asked to reset a password and nobody is logged out.
--
--  Safe to run BEFORE deploying the code: the two columns just sit unused.
--  Safe to deploy the code BEFORE running this: every password path checks
--  whether the columns exist and falls back to the old MD5 behaviour if not.
--  So the order genuinely does not matter — but run it, or nothing upgrades.
-- ============================================================================

-- 0. Pre-check — expect 0. If it returns 2, this is already applied; stop here.
SELECT COUNT(*) AS already_applied
FROM   information_schema.COLUMNS
WHERE  TABLE_SCHEMA = DATABASE()
AND    TABLE_NAME   = 'users'
AND    COLUMN_NAME IN ('password_digest', 'using_bcrypt');


-- 1. Add the columns
--
--    password_digest  the bcrypt hash. 60 chars in practice; 100 for headroom.
--                     NULL until that user next logs in.
--    using_bcrypt     which column to trust for this row. 0 = still on MD5.
--
-- Safety net: this ALTER rebuilds the table and re-validates every row, so a
-- legacy '0000-00-00' in users.userdate would trip strict sql_mode. Relaxed
-- for THIS session only; server config and existing values are untouched.
SET SESSION sql_mode = REPLACE(REPLACE(REPLACE(@@SESSION.sql_mode,
  'NO_ZERO_DATE', ''), 'NO_ZERO_IN_DATE', ''), 'STRICT_TRANS_TABLES', '');

ALTER TABLE `users`
  ADD COLUMN `password_digest` varchar(100) DEFAULT NULL,
  ADD COLUMN `using_bcrypt`    tinyint(1)   NOT NULL DEFAULT 0;


-- 2. Record the migration so a later `rails db:migrate` does not re-run it
INSERT IGNORE INTO `schema_migrations` (`version`) VALUES ('20260830120000');


-- 3. Verify — expect two rows
SHOW COLUMNS FROM `users` WHERE Field IN ('password_digest', 'using_bcrypt');


-- ============================================================================
--  AFTER DEPLOYING: watch the rollout
-- ============================================================================
--
-- Run this now and then. Each row flips to using_bcrypt = 1 the first time
-- that person logs in. No action needed — it is automatic.
--
--   SELECT username,
--          using_bcrypt,
--          LEFT(password_digest, 7) AS digest_prefix,   -- expect '$2a$12$'
--          CHAR_LENGTH(userpassword) AS legacy_len      -- expect 0 once done
--   FROM   users;
--
-- Log in yourself right after deploying and confirm your own row flips. That
-- is the single check that proves the whole thing works.
--
-- ============================================================================
--  MUCH LATER: retiring the MD5 column
-- ============================================================================
--
-- Only when this returns 0 — meaning every account has logged in at least
-- once since the deploy:
--
--   SELECT COUNT(*) AS still_on_md5 FROM users WHERE using_bcrypt = 0;
--
-- ...is it safe to drop the legacy column. Until then it is the rollback path,
-- so leave it alone. This is months away, not days:
--
--   ALTER TABLE `users` DROP COLUMN `userpassword`;
--
-- (Dropping it also requires a small code change — ask before running it.)
