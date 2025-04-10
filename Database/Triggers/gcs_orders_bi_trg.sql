create or replace trigger gcs_orders_bi_trg before
    insert on GCS_ORDERS
    for each row 
begin
    if inserting 
    then
        :new.odr_id := gcs_odr_seq_pk.nextval;
    end if;
end;
/