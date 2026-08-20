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
BEGIN
  rdsadmin.rdsadmin_util.grant_sys_object('V_$SYSMETRIC', UPPER('&monitor_user'), 'SELECT', FALSE);
  rdsadmin.rdsadmin_util.grant_sys_object('V_$CONTAINERS', UPPER('&monitor_user'), 'SELECT', FALSE);
  rdsadmin.rdsadmin_util.grant_sys_object('V_$SESSION', UPPER('&monitor_user'), 'SELECT', FALSE);
  rdsadmin.rdsadmin_util.grant_sys_object('V_$SESSION_EVENT', UPPER('&monitor_user'), 'SELECT', FALSE);
  rdsadmin.rdsadmin_util.grant_sys_object('V_$SYSSTAT', UPPER('&monitor_user'), 'SELECT', FALSE);
  rdsadmin.rdsadmin_util.grant_sys_object('V_$INSTANCE', UPPER('&monitor_user'), 'SELECT', FALSE);
  rdsadmin.rdsadmin_util.grant_sys_object('V_$DATABASE', UPPER('&monitor_user'), 'SELECT', FALSE);
  rdsadmin.rdsadmin_util.grant_sys_object('V_$SQL', UPPER('&monitor_user'), 'SELECT', FALSE);
  rdsadmin.rdsadmin_util.grant_sys_object('V_$SQL_PLAN', UPPER('&monitor_user'), 'SELECT', FALSE);
  rdsadmin.rdsadmin_util.grant_sys_object('V_$LOCK', UPPER('&monitor_user'), 'SELECT', FALSE);
END;
/
EXIT;
