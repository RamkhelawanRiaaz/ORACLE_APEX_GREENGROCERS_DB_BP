create or replace trigger OIM_before_insert 
before insert 
on gcs_orders_items 
for each row 
 
begin  
    :new.oim_created_by := nvl( v('APP_USER'), user); 
end;
/