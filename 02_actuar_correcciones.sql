-- =====================================================================
-- FASE "ACTUAR" (PHVA) - Correcciones de confidencialidad
-- Curso: Administración de Bases de Datos - UNA - II Ciclo 2026
-- Motor: Oracle Database 21c XE (21.3.0.0.0), PDB XEPDB1, usuario SYSTEM
--
-- ATENCIÓN: a diferencia del script 01, ESTE SÍ MODIFICA LA BASE.
-- CÓMO EJECUTARLO
--   * Ejecuta UN BLOQUE A LA VEZ: selecciona solo ese bloque y presiona F5.
--   * Cada bloque trae: ANTES -> CAMBIO -> DESPUÉS -> ROLLBACK (comentado).
--   * Guarda captura del ANTES y del DESPUÉS: son la evidencia.
--   * Si algo da error ORA-xxxxx, anótalo antes de seguir.
-- =====================================================================


-- ---------------------------------------------------------------------
-- BLOQUE 0 (solo lectura) | A8.3 | ¿De quién son las 12 políticas VPD?
-- ---------------------------------------------------------------------
SELECT object_owner, object_name, policy_name, enable
FROM   dba_policies
ORDER  BY object_owner, object_name;


-- ---------------------------------------------------------------------
-- BLOQUE 1 | A5.16 | Bloquear la cuenta PDBADMIN (abierta y nunca usada)
-- ---------------------------------------------------------------------
-- ANTES
SELECT username, account_status, last_login FROM dba_users WHERE username = 'PDBADMIN';
-- CAMBIO
ALTER USER PDBADMIN ACCOUNT LOCK;
-- DESPUÉS
SELECT username, account_status, last_login FROM dba_users WHERE username = 'PDBADMIN';
-- ROLLBACK:  ALTER USER PDBADMIN ACCOUNT UNLOCK;


-- ---------------------------------------------------------------------
-- BLOQUE 2 | A5.17 / A8.5 | Política de contraseñas fuerte (perfil ORA_CIS_PROFILE)
-- No se toca el perfil DEFAULT ni al usuario AUDITORIA: se prueba con un usuario nuevo.
-- Al ejecutar, SQL Developer pedirá la contraseña (&clave_prueba): usa una que tenga
-- al menos 8 caracteres, con letras y números. NO la guardes en el repositorio.
-- ---------------------------------------------------------------------
-- CAMBIO
CREATE USER USR_PRUEBA_ISO IDENTIFIED BY "&clave_prueba" PROFILE ORA_CIS_PROFILE;
GRANT CREATE SESSION TO USR_PRUEBA_ISO;
-- PRUEBA: una contraseña débil debe ser RECHAZADA (resultado esperado: ORA-28003)
ALTER USER USR_PRUEBA_ISO IDENTIFIED BY abc;
-- DESPUÉS
SELECT username, profile, account_status FROM dba_users WHERE username = 'USR_PRUEBA_ISO';
-- ROLLBACK:  DROP USER USR_PRUEBA_ISO CASCADE;


-- ---------------------------------------------------------------------
-- BLOQUE 3 | A8.12 | Quitar EXECUTE a PUBLIC sobre paquetes de salida de datos
-- Verifica antes que ningún otro proyecto use estos paquetes.
-- NOTA: el otorgante de estos privilegios es SYS (COMMON = NO). Ejecutado
-- desde SYSTEM, el REVOKE falla con ORA-01927; para aplicarlo hay que
-- conectarse como SYS (AS SYSDBA) al PDB XEPDB1. En la ejecución documentada
-- esta corrección NO se aplicó.
-- ---------------------------------------------------------------------
-- DIAGNÓSTICO: ¿quién es el otorgante?
SELECT grantee, table_name, privilege, grantor, common
FROM   dba_tab_privs
WHERE  grantee = 'PUBLIC'
AND    table_name IN ('UTL_HTTP','UTL_TCP','UTL_SMTP','UTL_FILE');
-- ¿Con qué usuario estoy conectado?
SELECT SYS_CONTEXT('USERENV','SESSION_USER') AS usuario FROM dual;
-- ANTES
SELECT grantee, table_name AS paquete, privilege
FROM   dba_tab_privs
WHERE  grantee = 'PUBLIC' AND privilege = 'EXECUTE'
AND    table_name IN ('UTL_FILE','UTL_HTTP','UTL_TCP','UTL_SMTP','DBMS_DATAPUMP')
ORDER  BY table_name;
-- CAMBIO
REVOKE EXECUTE ON SYS.UTL_HTTP FROM PUBLIC;
REVOKE EXECUTE ON SYS.UTL_TCP  FROM PUBLIC;
REVOKE EXECUTE ON SYS.UTL_SMTP FROM PUBLIC;
REVOKE EXECUTE ON SYS.UTL_FILE FROM PUBLIC;
-- DESPUÉS (DBMS_DATAPUMP queda a propósito: decisión a documentar en el informe)
SELECT grantee, table_name AS paquete, privilege
FROM   dba_tab_privs
WHERE  grantee = 'PUBLIC' AND privilege = 'EXECUTE'
AND    table_name IN ('UTL_FILE','UTL_HTTP','UTL_TCP','UTL_SMTP','DBMS_DATAPUMP')
ORDER  BY table_name;
-- ROLLBACK:
--   GRANT EXECUTE ON SYS.UTL_HTTP TO PUBLIC;
--   GRANT EXECUTE ON SYS.UTL_TCP  TO PUBLIC;
--   GRANT EXECUTE ON SYS.UTL_SMTP TO PUBLIC;
--   GRANT EXECUTE ON SYS.UTL_FILE TO PUBLIC;


-- ---------------------------------------------------------------------
-- BLOQUE 4 | A8.15 | Política de auditoría propia sobre administración de usuarios
-- (ejecutar DESPUÉS del bloque 2, porque usa USR_PRUEBA_ISO)
-- Si da ORA-01031 (privilegios insuficientes), conéctate con un usuario con
-- el privilegio AUDIT SYSTEM.
-- ---------------------------------------------------------------------
-- CAMBIO
CREATE AUDIT POLICY POL_ISO_ADMIN_USUARIOS
  PRIVILEGES CREATE USER, ALTER USER, DROP USER, GRANT ANY PRIVILEGE, GRANT ANY ROLE;
AUDIT POLICY POL_ISO_ADMIN_USUARIOS;
-- PRUEBA: generar un evento auditable
ALTER USER USR_PRUEBA_ISO ACCOUNT LOCK;
ALTER USER USR_PRUEBA_ISO ACCOUNT UNLOCK;
-- DESPUÉS (puede tardar unos segundos en aparecer; si sale vacío, repetir)
SELECT event_timestamp, dbusername, action_name, object_name, return_code
FROM   unified_audit_trail
WHERE  unified_audit_policies LIKE '%POL_ISO_ADMIN_USUARIOS%'
ORDER  BY event_timestamp DESC
FETCH FIRST 10 ROWS ONLY;
-- ROLLBACK:
--   NOAUDIT POLICY POL_ISO_ADMIN_USUARIOS;
--   DROP AUDIT POLICY POL_ISO_ADMIN_USUARIOS;


-- ---------------------------------------------------------------------
-- LIMPIEZA FINAL (al terminar todas las pruebas)
-- ---------------------------------------------------------------------
-- DROP USER USR_PRUEBA_ISO CASCADE;
