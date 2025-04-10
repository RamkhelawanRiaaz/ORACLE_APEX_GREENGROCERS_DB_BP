create or replace trigger gcs_orders_items_bi_trg before
    insert on GCS_ORDERS_ITEMS
    for each row 
begin
    if inserting 
    then
        :new.oim_id := gcs_oim_seq_pk.nextval;
    end if;
end;
/