-- ============================================================
-- TRUST CENTER: Migrate LEGACY SERVICE users off password-only
-- Account: KA85352
-- ============================================================

-- STEP 1: Identify all affected users
SELECT name, login_name, disabled, has_rsa_public_key, has_password, last_success_login, type
FROM snowflake.account_usage.users
WHERE type = 'LEGACY_SERVICE'
  AND has_password = TRUE
  AND has_rsa_public_key = FALSE;

-- STEP 2: For EACH user found, run the following (replace <USER_NAME>)

-- Option A: Migrate to key-pair auth (recommended for service accounts)
-- First generate keys on app host:
--   openssl genrsa 2048 > snowflake_key.pem
--   openssl rsa -in snowflake_key.pem -pubout > snowflake_key.pub
ALTER USER "<USER_NAME>" SET RSA_PUBLIC_KEY = '<PUBLIC_KEY_CONTENTS>';

-- Option B: Migrate to OAuth (if app supports it)
-- Configure security integration, update app to use OAuth tokens

-- STEP 3: After confirming new auth works, remove the password
ALTER USER "<USER_NAME>" UNSET PASSWORD;

-- STEP 4: Disable any unused legacy service users
ALTER USER "<UNUSED_USER>" SET DISABLED = TRUE;

-- STEP 5: Real-time verification (no 2-hour latency)
SHOW USERS;

-- STEP 6: Re-check via account_usage (may take up to 2 hours to reflect)
SELECT name, login_name, disabled, has_rsa_public_key, has_password, type
FROM snowflake.account_usage.users
WHERE type = 'LEGACY_SERVICE'
  AND has_password = TRUE
  AND has_rsa_public_key = FALSE;
-- Zero rows = finding will clear on next Trust Center scan
