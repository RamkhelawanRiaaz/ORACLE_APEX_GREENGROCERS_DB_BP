create or replace trigger odr_before_insert 
before insert 
on gcs_orders 
for each row 
 
begin  
    :new.odr_created_by := nvl( v('APP_USER'), user); 
    :new.odr_CREATED_DATE := TO_DATE(SYSDATE, 'DD-MM-YYYY'); 
end;
/