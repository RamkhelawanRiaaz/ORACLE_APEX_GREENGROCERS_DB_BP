create or replace trigger products_before_update 
before update 
on gcs_products 
for each row 
 
begin  
    :new.pdt_modified_date := TO_DATE(SYSDATE, 'DD-MM-YYYY'); 
end;
/