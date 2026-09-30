WHENEVER SQLERROR CONTINUE
DECLARE
  user_count NUMBER;
BEGIN
  SELECT COUNT(*) INTO user_count FROM dba_users WHERE username = UPPER('&monitor_user');
  IF user_count = 0 THEN
    EXECUTE IMMEDIATE 'CREATE USER &monitor_user IDENTIFIED BY "&monitor_password"';
  END IF;
END;
/
WHENEVER SQLERROR EXIT SQL.SQLCODE

GRANT CONNECT TO &monitor_user;
GRANT CREATE SESSION TO &monitor_user;
BEGIN
  rdsadmin.rdsadmin_util.grant_sys_object('V_$SYSMETRIC', UPPER('&monitor_user'), 'SELECT', FALSE);
  rdsadmin.rdsadmin_util.grant_sys_object('V_$CON_SYSMETRIC', UPPER('&monitor_user'), 'SELECT', FALSE);
  rdsadmin.rdsadmin_util.grant_sys_object('V_$CONTAINERS', UPPER('&monitor_user'), 'SELECT', FALSE);
  rdsadmin.rdsadmin_util.grant_sys_object('V_$SESSION', UPPER('&monitor_user'), 'SELECT', FALSE);
  rdsadmin.rdsadmin_util.grant_sys_object('V_$SESSION_EVENT', UPPER('&monitor_user'), 'SELECT', FALSE);
  rdsadmin.rdsadmin_util.grant_sys_object('V_$SYSSTAT', UPPER('&monitor_user'), 'SELECT', FALSE);
  rdsadmin.rdsadmin_util.grant_sys_object('V_$CON_SYSSTAT', UPPER('&monitor_user'), 'SELECT', FALSE);
  rdsadmin.rdsadmin_util.grant_sys_object('V_$OSSTAT', UPPER('&monitor_user'), 'SELECT', FALSE);
  rdsadmin.rdsadmin_util.grant_sys_object('V_$SGAINFO', UPPER('&monitor_user'), 'SELECT', FALSE);
  rdsadmin.rdsadmin_util.grant_sys_object('V_$SQL', UPPER('&monitor_user'), 'SELECT', FALSE);
  rdsadmin.rdsadmin_util.grant_sys_object('V_$SQLSTATS', UPPER('&monitor_user'), 'SELECT', FALSE);
  rdsadmin.rdsadmin_util.grant_sys_object('V_$SQL_PLAN', UPPER('&monitor_user'), 'SELECT', FALSE);
  rdsadmin.rdsadmin_util.grant_sys_object('V_$PARAMETER', UPPER('&monitor_user'), 'SELECT', FALSE);
  rdsadmin.rdsadmin_util.grant_sys_object('V_$ROWCACHE', UPPER('&monitor_user'), 'SELECT', FALSE);
  rdsadmin.rdsadmin_util.grant_sys_object('V_$RESOURCE_LIMIT', UPPER('&monitor_user'), 'SELECT', FALSE);
  rdsadmin.rdsadmin_util.grant_sys_object('V_$LOCK', UPPER('&monitor_user'), 'SELECT', FALSE);
  rdsadmin.rdsadmin_util.grant_sys_object('V_$DATABASE', UPPER('&monitor_user'), 'SELECT', FALSE);
  rdsadmin.rdsadmin_util.grant_sys_object('V_$INSTANCE', UPPER('&monitor_user'), 'SELECT', FALSE);
  rdsadmin.rdsadmin_util.grant_sys_object('V_$DATAFILE', UPPER('&monitor_user'), 'SELECT', FALSE);
  rdsadmin.rdsadmin_util.grant_sys_object('V_$PDBS', UPPER('&monitor_user'), 'SELECT', FALSE);
  rdsadmin.rdsadmin_util.grant_sys_object('DBA_DATA_FILES', UPPER('&monitor_user'), 'SELECT', FALSE);
  rdsadmin.rdsadmin_util.grant_sys_object('DBA_FREE_SPACE', UPPER('&monitor_user'), 'SELECT', FALSE);
  rdsadmin.rdsadmin_util.grant_sys_object('DBA_RECYCLEBIN', UPPER('&monitor_user'), 'SELECT', FALSE);
  rdsadmin.rdsadmin_util.grant_sys_object('DBA_TABLESPACES', UPPER('&monitor_user'), 'SELECT', FALSE);
  rdsadmin.rdsadmin_util.grant_sys_object('DBA_TABLESPACE_USAGE_METRICS', UPPER('&monitor_user'), 'SELECT', FALSE);
  rdsadmin.rdsadmin_util.grant_sys_object('DBA_PROCEDURES', UPPER('&monitor_user'), 'SELECT', FALSE);
  rdsadmin.rdsadmin_util.grant_sys_object('DBA_OBJECTS', UPPER('&monitor_user'), 'SELECT', FALSE);
  rdsadmin.rdsadmin_util.grant_sys_object('CDB_TABLESPACE_USAGE_METRICS', UPPER('&monitor_user'), 'SELECT', FALSE);
  rdsadmin.rdsadmin_util.grant_sys_object('CDB_TABLESPACES', UPPER('&monitor_user'), 'SELECT', FALSE);
  rdsadmin.rdsadmin_util.grant_sys_object('CDB_SERVICES', UPPER('&monitor_user'), 'SELECT', FALSE);
END;
/
EXIT;
