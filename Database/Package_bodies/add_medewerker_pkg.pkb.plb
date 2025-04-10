create or replace PACKAGE BODY add_medewerker_pkg AS
    PROCEDURE add_mederwerker(
        P_usr_username  VARCHAR2,
        P_usr_password VARCHAR2,
        P_usr_email    VARCHAR2,
        P_usr_street_name VARCHAR2,
        P_usr_house_number VARCHAR2,
        P_usr_deleted   VARCHAR2
    ) AS
        v_usr_id        NUMBER;
        v_role_id       NUMBER;
        v_count         NUMBER;
        v_full_address  VARCHAR2(500);
        v_latitude      NUMBER;
        v_longitude     NUMBER;
        v_response     CLOB;
        v_json         APEX_JSON.T_VALUES;
    BEGIN

        SELECT COUNT(*) INTO v_count FROM aut_users WHERE usr_username = P_usr_username;
        IF v_count > 0 THEN
            RAISE_APPLICATION_ERROR(-20001, 'Username already exists. Please choose another.');
        END IF;

        SELECT COUNT(*) INTO v_count FROM aut_users WHERE usr_password = P_usr_password;
        IF v_count > 0 THEN
            RAISE_APPLICATION_ERROR(-20002, 'Password already exists. Please choose another.');
        END IF;

     
        v_full_address := P_usr_street_name || ', Paramaribo, Suriname';
        DBMS_OUTPUT.PUT_LINE('Volledig adres: ' || v_full_address);


        BEGIN

            v_response := APEX_WEB_SERVICE.MAKE_REST_REQUEST(
                p_url         => 'https://nominatim.openstreetmap.org/search?format=json&q=' || REPLACE(v_full_address, ' ', '+') || '&limit=1&countrycodes=SR',
                p_http_method => 'GET'
            );

            DBMS_OUTPUT.PUT_LINE('API-respons: ' || v_response);
            APEX_JSON.PARSE(p_source => v_response, p_values => v_json);
            DBMS_OUTPUT.PUT_LINE('Aantal resultaten: ' || APEX_JSON.GET_COUNT(p_path => '.', p_values => v_json));


            IF APEX_JSON.GET_COUNT(p_path => '.', p_values => v_json) > 0 THEN
                v_latitude  := TO_NUMBER(APEX_JSON.GET_VARCHAR2(p_path => '[0].lat', p_values => v_json));
                v_longitude := TO_NUMBER(APEX_JSON.GET_VARCHAR2(p_path => '[0].lon', p_values => v_json));
            ELSE
                -- Als er geen resultaten zijn, gebruik dan standaardwaarden 
                v_latitude  := 5.8520;  
                v_longitude := -55.2038; 
                DBMS_OUTPUT.PUT_LINE('Geen resultaten gevonden voor het opgegeven adres. Standaardwaarden gebruikt.');
            END IF;
            DBMS_OUTPUT.PUT_LINE('Latitude: ' || v_latitude || ', Longitude: ' || v_longitude);

        EXCEPTION
            WHEN OTHERS THEN
                -- Als er geen resultaten zijn, gebruik dan standaardwaarden 
                v_latitude  := 5.8520;
                v_longitude := -55.2038;
                DBMS_OUTPUT.PUT_LINE('Fout bij geocoding: ' || SQLERRM || '. Standaardwaarden gebruikt.');
        END;

        -- Voeg de nieuwe medewerker toe met longitude en latitude
        INSERT INTO aut_users (
            usr_username, usr_password, usr_email, usr_street_name, usr_house_number, usr_deleted, usr_latitude, usr_longitude
        ) VALUES (
            P_usr_username, P_usr_password, P_usr_email, P_usr_street_name, P_usr_house_number, P_usr_deleted, v_latitude, v_longitude
        ) RETURNING usr_id INTO v_usr_id;


        SELECT rle_id INTO v_role_id FROM aut_roles WHERE UPPER(rle_name) = UPPER('Medewerker');

        INSERT INTO AUT_USR_RLE (
            ure_usr_id, ure_rle_id, ure_valid_from, ure_valid_until
        ) VALUES (
            v_usr_id, v_role_id, SYSDATE, NULL
        );

        COMMIT;
    EXCEPTION
        WHEN DUP_VAL_ON_INDEX THEN
            RAISE_APPLICATION_ERROR(-20003, 'Duplicate entry found. Username or email already exists.');
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(-20099, 'An error occurred: ' || SQLERRM);
    END add_mederwerker; 
END add_medewerker_pkg;
/