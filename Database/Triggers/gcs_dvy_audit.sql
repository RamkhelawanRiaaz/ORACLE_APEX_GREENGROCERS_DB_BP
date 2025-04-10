create or replace TRIGGER GCS_DVY_AUDIT 
AFTER INSERT OR UPDATE OR DELETE 
ON gcs_delivery 
FOR EACH ROW 
DECLARE 
    v_old_values CLOB; 
    v_new_values CLOB; 
    v_operation  VARCHAR2(10); 
     
BEGIN 
    IF DELETING OR UPDATING THEN 
        v_old_values := 'Id = ' || :OLD.dvy_id ||chr(10)||  
                        'Date = ' || :OLD.dvy_date || chr(10) || 
                        'Route = '|| :OLD.dvy_route || chr(10) || 
                        'User = '|| :OLD.usr_id || chr(10) || 
                        'Status = '|| :OLD.sts_id || chr(10) || 
                        'Order = '|| :OLD.odr_id; 
    END IF; 
 
    IF INSERTING OR UPDATING THEN 
        v_new_values := 'Id = ' || :NEW.dvy_id ||chr(10)||  
                        'Date = ' || :NEW.dvy_date || chr(10) || 
                        'Route = '|| :NEW.dvy_route || chr(10) || 
                        'User = '|| :NEW.usr_id || chr(10) || 
                        'Status = '|| :NEW.sts_id || chr(10) || 
                        'Order = '|| :NEW.odr_id; 
    END IF; 
 
    v_operation := CASE  
                       WHEN INSERTING THEN 'INSERT' 
                       WHEN UPDATING THEN 'UPDATE' 
                       WHEN DELETING THEN 'DELETE' 
                   END; 
 
    INSERT INTO gcs_auditlog (alg_table_name, alg_operation, alg_changed_by, alg_old_values, alg_new_values) 
    VALUES ('GCS_DELIVERY', v_operation, nvl( v('APP_USER'), user), v_old_values, v_new_values); 
END;
/