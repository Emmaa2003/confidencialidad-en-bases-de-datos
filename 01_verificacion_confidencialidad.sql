-- =====================================================================
-- Verificación de controles ISO/IEC 27001:2022 - Confidencialidad (DBA)
-- Curso: Administración de Bases de Datos - UNA - II Ciclo 2026
-- Motor: Oracle Database 21c Express Edition (21.3.0.0.0), PDB XEPDB1
--
-- CÓMO EJECUTARLO
--   1. Conectarse como SYSTEM al servicio XEPDB1.
--   2. Abrir este archivo en SQL Developer y ejecutar con F5 (script).
--   3. Todas las consultas son de SOLO LECTURA: no modifican nada.
--   4. Guardar la pestaña "Salida del Script" como evidencia.
-- Si una consulta falla con ORA-xxxxx, anotar el código y continuar.
-- =====================================================================

PROMPT ===== P-01 | A5.16 | Ciclo de vida de usuarios (no Oracle) =====
SELECT username, account_status, created, lock_date, expiry_date,
       last_login, profile, authentication_type
FROM   dba_users
WHERE  oracle_maintained = 'N'
ORDER  BY created;

PROMPT ===== P-02 | A5.17 | Cuentas con contraseña por defecto =====
SELECT * FROM dba_users_with_defpwd;

PROMPT ===== P-03 | A5.17 / A8.5 | Política de contraseñas por perfil =====
SELECT profile, resource_name, limit
FROM   dba_profiles
WHERE  resource_type = 'PASSWORD'
ORDER  BY profile, resource_name;

PROMPT ===== P-04 | A8.5 | Versiones de verificador de contraseña =====
SELECT username, password_versions, authentication_type, account_status
FROM   dba_users
WHERE  oracle_maintained = 'N'
ORDER  BY username;

PROMPT ===== P-05 | A8.2 | Usuarios con el rol DBA =====
SELECT grantee, granted_role, admin_option
FROM   dba_role_privs
WHERE  granted_role = 'DBA'
ORDER  BY grantee;

PROMPT ===== P-06 | A8.2 | Usuarios con SYSDBA / SYSOPER (archivo de contraseñas) =====
SELECT * FROM v$pwfile_users;

PROMPT ===== P-07 | A8.2 | Privilegios ANY y administrativos en usuarios no Oracle =====
SELECT grantee, privilege, admin_option
FROM   dba_sys_privs
WHERE  grantee IN (SELECT username FROM dba_users WHERE oracle_maintained = 'N')
AND   (privilege LIKE '%ANY%'
       OR privilege IN ('ALTER SYSTEM','ALTER USER','CREATE USER','DROP USER'))
ORDER  BY grantee, privilege;

PROMPT ===== P-08 | A5.18 | Roles otorgados con ADMIN OPTION a usuarios no Oracle =====
SELECT grantee, granted_role
FROM   dba_role_privs
WHERE  admin_option = 'YES'
AND    grantee IN (SELECT username FROM dba_users WHERE oracle_maintained = 'N')
ORDER  BY grantee, granted_role;

PROMPT ===== P-09 | A8.3 | Políticas VPD / control de acceso fino =====
SELECT object_owner, object_name, policy_name, enable
FROM   dba_policies
ORDER  BY object_owner, object_name;

PROMPT ===== P-10 | A8.11 | Políticas de Data Redaction =====
SELECT object_owner, object_name, policy_name, enable
FROM   redaction_policies
ORDER  BY object_owner, object_name;

PROMPT ===== P-11 | A8.12 | EXECUTE a PUBLIC sobre paquetes de salida de datos =====
SELECT grantee, table_name AS paquete, privilege
FROM   dba_tab_privs
WHERE  grantee = 'PUBLIC'
AND    privilege = 'EXECUTE'
AND    table_name IN ('UTL_FILE','UTL_HTTP','UTL_TCP','UTL_SMTP',
                      'DBMS_DATAPUMP','DBMS_FILE_TRANSFER')
ORDER  BY table_name;

PROMPT ===== P-11b | A8.12 | Directorios definidos (destinos de exportación) =====
SELECT owner, directory_name, directory_path
FROM   dba_directories
ORDER  BY directory_name;

PROMPT ===== P-12 | A8.15 | Modo y políticas de auditoría =====
SELECT name, value FROM v$parameter WHERE name = 'audit_trail';
SELECT * FROM audit_unified_enabled_policies;

PROMPT ===== P-13 | A5.33 | Quién puede leer o administrar el audit trail =====
SELECT grantee, granted_role
FROM   dba_role_privs
WHERE  granted_role IN ('AUDIT_ADMIN','AUDIT_VIEWER')
ORDER  BY granted_role, grantee;

SELECT grantee, owner, table_name, privilege
FROM   dba_tab_privs
WHERE  owner = 'AUDSYS' OR table_name = 'AUD$'
ORDER  BY grantee;

PROMPT ===== P-14 | A8.24 | Cifrado en reposo (TDE) =====
SELECT * FROM v$encryption_wallet;
SELECT tablespace_name, encrypted FROM dba_tablespaces ORDER BY 1;
SELECT owner, table_name, column_name, encryption_alg FROM dba_encrypted_columns;

PROMPT ===== P-15 | A8.13 | Respaldos: modo de log, cifrado RMAN, últimos jobs =====
SELECT log_mode FROM v$database;
SELECT * FROM v$rman_encryption_algorithms;
SELECT session_key, input_type, status, start_time, end_time
FROM   v$rman_backup_job_details
ORDER  BY start_time DESC
FETCH FIRST 10 ROWS ONLY;

PROMPT ===== P-16 | A8.8 | Parches aplicados =====
SELECT patch_id, action, status, action_time, description
FROM   dba_registry_sqlpatch
ORDER  BY action_time;

PROMPT ===== P-17 | A8.20 | Cifrado de red en la sesión actual =====
SELECT network_service_banner
FROM   v$session_connect_info
WHERE  sid = TO_NUMBER(SYS_CONTEXT('USERENV','SID'))
ORDER  BY 1;

-- =====================================================================
-- RESÚMENES EN UNA SOLA TABLA (útiles cuando SQL Developer reparte los
-- resultados en varias pestañas)
-- =====================================================================

PROMPT ===== Resumen 1 | P-12, P-15, P-11 =====
SELECT 'audit_trail' AS dato, value AS resultado FROM v$parameter WHERE name = 'audit_trail'
UNION ALL
SELECT 'log_mode', log_mode FROM v$database
UNION ALL
SELECT 'politica de auditoria activa: ' || policy_name, 'activa' FROM audit_unified_enabled_policies
UNION ALL
SELECT 'EXECUTE a PUBLIC: ' || table_name, privilege FROM dba_tab_privs
WHERE grantee = 'PUBLIC' AND privilege = 'EXECUTE'
AND table_name IN ('UTL_FILE','UTL_HTTP','UTL_TCP','UTL_SMTP','DBMS_DATAPUMP','DBMS_FILE_TRANSFER');

PROMPT ===== Resumen 2 | P-09, P-10, P-16, P-04, P-17 =====
SELECT 'politicas VPD' AS dato, TO_CHAR(COUNT(*)) AS resultado FROM dba_policies
UNION ALL
SELECT 'politicas Redaction', TO_CHAR(COUNT(*)) FROM redaction_policies
UNION ALL
SELECT 'parches aplicados', TO_CHAR(COUNT(*)) FROM dba_registry_sqlpatch
UNION ALL
SELECT 'verificador ' || username, password_versions FROM dba_users WHERE oracle_maintained = 'N'
UNION ALL
SELECT 'red: ' || network_service_banner, 'sesion actual' FROM v$session_connect_info
WHERE sid = TO_NUMBER(SYS_CONTEXT('USERENV','SID'));

-- =====================================================================
-- Verificaciones MANUALES (fuera de SQL), para anotar como evidencia:
--   * lsnrctl status                       -> escucha en qué dirección/puerto
--   * sqlnet.ora y listener.ora            -> TLS, SQLNET.ENCRYPTION_*, ALLOWED_LOGON_VERSION_SERVER
--                                             (en esta instalación están en
--                                              ...\homes\OraDB21Home1\network\admin)
--   * rman target / ; SHOW ALL;            -> CONFIGURE ENCRYPTION FOR DATABASE
-- =====================================================================
