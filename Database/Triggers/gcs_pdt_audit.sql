create or replace TRIGGER GCS_PDT_AUDIT 
AFTER INSERT OR UPDATE OR DELETE 
ON gcs_products 
FOR EACH ROW 
DECLARE 
    v_old_values CLOB; 
    v_new_values CLOB; 
    v_operation  VARCHAR2(10); 
    v_user_id number;
BEGIN 

    IF DELETING OR UPDATING THEN 
        v_old_values := 'Id = ' || :OLD.pdt_id ||chr(10)|| 'name = ' || :OLD.pdt_name; 
    END IF; 
 

    IF INSERTING OR UPDATING THEN 
        v_new_values := 'Id = ' || :NEW.pdt_id ||chr(10)|| 'name = ' || :NEW.pdt_name; 
    END IF; 
 
    v_operation := CASE  
                       WHEN INSERTING THEN 'INSERT' 
                       WHEN UPDATING THEN 'UPDATE' 
                       WHEN DELETING THEN 'DELETE' 
                   END; 


    INSERT INTO gcs_auditlog (alg_table_name, alg_operation, alg_changed_by, alg_old_values, alg_new_values) 
    VALUES ('GCS_PRODUCTS', v_operation, nvl( v('APP_USER'), user), v_old_values, v_new_values); 
END;
/