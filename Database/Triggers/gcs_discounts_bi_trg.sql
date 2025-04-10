create or replace trigger gcs_discounts_bi_trg before
    insert on GCS_DISCOUNTS
    for each row 
begin
    if inserting 
    then
        :new.dct_id := gcs_dct_seq_pk.nextval;
    end if;
end;
/