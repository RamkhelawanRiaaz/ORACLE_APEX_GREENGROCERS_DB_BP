create or replace trigger products_before_insert 
before insert 
on gcs_products 
for each row 
 
begin  
    :new.pdt_created_by := nvl( v('APP_USER'), user); 
    :new.PDT_CREATED_DATE := sysdate; 
end;
/