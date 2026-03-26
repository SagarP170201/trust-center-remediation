-- ============================================================
-- TRUST CENTER: Migrate LEGACY SERVICE users off password-only
-- Scanner: SECURITY_ESSENTIALS_STRONG_AUTH_LEGACY_SERVICE_USERS_READINESS
-- Account: KA85352 (includes SPCS service users)
-- ============================================================

-- ============================================================
-- STEP 1: Identify ALL legacy service users (account_usage has ~2hr latency)
-- ============================================================
SELECT
    name,
    login_name,
    disabled,
    has_rsa_public_key,
    has_password,
    last_success_login,
    type,
    comment
FROM snowflake.account_usage.users
WHERE type = 'LEGACY_SERVICE';

-- ============================================================
-- STEP 2: Identify regular legacy service users (NOT SPCS)
--         These need key-pair authentication migration
-- ============================================================
SELECT
    name,
    login_name,
    disabled,
    has_rsa_public_key,
    has_password,
    last_success_login,
    comment
FROM snowflake.account_usage.users
WHERE type = 'LEGACY_SERVICE'
  AND has_password = TRUE
  AND has_rsa_public_key = FALSE
  AND name NOT LIKE 'SVC_%_ENDPOINT_%';

-- ============================================================
-- STEP 3: Identify SPCS service users
--         These need safe auth migration BEFORE type conversion
-- ============================================================
SELECT
    name,
    login_name,
    disabled,
    has_rsa_public_key,
    has_password,
    last_success_login,
    comment
FROM snowflake.account_usage.users
WHERE type = 'LEGACY_SERVICE'
  AND name LIKE 'SVC_%_ENDPOINT_%';

-- ============================================================
-- STEP 4: For REGULAR service accounts — migrate to key-pair auth
--         Generate RSA key pair first:
--           openssl genrsa 2048 | openssl pkcs8 -topk8 -inform PEM -out rsa_key.p8 -nocrypt
--           openssl rsa -in rsa_key.p8 -pubout -out rsa_key.pub
--         Then set the public key (strip BEGIN/END lines and newlines):
-- ============================================================
-- ALTER USER "<USER_NAME>" SET RSA_PUBLIC_KEY = '<PUBLIC_KEY_CONTENTS>';

-- After confirming key-pair auth works in the application:
-- ALTER USER "<USER_NAME>" UNSET PASSWORD;

-- ============================================================
-- STEP 5: For SPCS users — safe migration (DO NOT just SET TYPE = SERVICE)
--         WARNING: SPCS users are currently LEGACY_SERVICE + password-only.
--         Flipping to TYPE = SERVICE without removing the password first
--         will hard-block SPCS logins immediately.
--
--         Safe order:
--         5a) Add key-pair / OAuth / WIF to the SPCS user
--         5b) Update SPCS config to use the new auth method
--         5c) Validate SPCS is working WITHOUT passwords
--         5d) Remove the password
--         5e) (Optional) Convert type to SERVICE after password is gone
-- ============================================================
-- 5a) Add key-pair auth to SPCS user:
-- ALTER USER "<SPCS_USER_NAME>" SET RSA_PUBLIC_KEY = '<PUBLIC_KEY_CONTENTS>';

-- 5b) Update SPCS service/endpoint config to use key-pair auth
--     (this is done outside Snowflake — in your SPCS deployment config)

-- 5c) Validate SPCS is working with the new auth method

-- 5d) Remove password after validation:
-- ALTER USER "<SPCS_USER_NAME>" UNSET PASSWORD;

-- 5e) (Optional) Convert to modern SERVICE type:
-- ALTER USER "<SPCS_USER_NAME>" SET TYPE = SERVICE;

-- ============================================================
-- STEP 6: Disable any unused legacy service users
-- ============================================================
-- ALTER USER "<UNUSED_USER>" SET DISABLED = TRUE;

-- ============================================================
-- STEP 7: Real-time verification (SHOW USERS has no latency)
--         Check that legacy service users now show updated type/auth
-- ============================================================
SHOW USERS;

-- ============================================================
-- STEP 8: Final check via account_usage (~2hr latency)
--         Zero rows = Trust Center finding cleared
-- ============================================================
SELECT
    name,
    login_name,
    disabled,
    has_rsa_public_key,
    has_password,
    type
FROM snowflake.account_usage.users
WHERE type = 'LEGACY_SERVICE'
  AND has_password = TRUE
  AND has_rsa_public_key = FALSE;
