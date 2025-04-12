create or replace TRIGGER aut_users_password_check_before_insert_trg
BEFORE INSERT OR UPDATE ON AUT_USERS
FOR EACH ROW
BEGIN
  IF :NEW.USR_PASSWORD IS NOT NULL AND LENGTH(:NEW.USR_PASSWORD) < 6 THEN
    RAISE_APPLICATION_ERROR(-20002, 'Password must be at least 6 characters long.');
  END IF;
END;
/