create or replace PACKAGE BODY add_klant_pkg AS

    -- Constants
    c_earth_radius CONSTANT NUMBER := 6371;
    c_pi CONSTANT NUMBER := 3.141592653589793;
    c_default_lat CONSTANT NUMBER := 5.8520;
    c_default_lon CONSTANT NUMBER := -55.2038;
    c_shop_lat CONSTANT NUMBER := 5.828267;
    c_shop_lon CONSTANT NUMBER := -55.218394;
    c_locationiq_key CONSTANT VARCHAR2(100) := 'pk.510229fe5f99fabf3bd6c8c4e8751262';
    c_delivery_price NUMBER := 40;

    -- Functie: URL encoden
    FUNCTION url_encode(p_text IN VARCHAR2) RETURN VARCHAR2 IS
    BEGIN
        RETURN UTL_URL.ESCAPE(p_text, TRUE);
    END url_encode;

    -- Functie: Afstand berekenen tussen twee coordinaten
FUNCTION calculate_distance(
    p_lat1 NUMBER,
    p_lon1 NUMBER,
    p_lat2 NUMBER,
    p_lon2 NUMBER
) RETURN NUMBER IS
    v_x NUMBER;
    v_y NUMBER;
BEGIN
    -- Afstand berekenen
    v_x := (p_lon2 - p_lon1) * c_pi / 180 * COS((p_lat1 + p_lat2) / 2 * c_pi / 180);
    v_y := (p_lat2 - p_lat1) * c_pi / 180;
    RETURN ROUND(SQRT(v_x * v_x + v_y * v_y) * c_earth_radius * c_delivery_price, 2);
END calculate_distance;


    -- Procedure: Geocode via LocationIQ XML
    PROCEDURE locationiq_geocode(
        p_street_name IN VARCHAR2,
        p_latitude OUT NUMBER,
        p_longitude OUT NUMBER
    ) IS
        v_encoded_address VARCHAR2(500);
        v_response CLOB;
        v_xml XMLTYPE;
    BEGIN
        v_encoded_address := url_encode(p_street_name);

        -- API-aanroep
        v_response := APEX_WEB_SERVICE.MAKE_REST_REQUEST(
            p_url => 'https://us1.locationiq.com/v1/search?format=xml&q=' || v_encoded_address || '&countrycodes=SR&key=' || c_locationiq_key,
            p_http_method => 'GET'
        );

        DBMS_OUTPUT.PUT_LINE('API Response: ' || SUBSTR(v_response, 1, 300));

        -- XML parsen
        v_xml := XMLTYPE(v_response);

        -- Latitude en longitude uitlezen
        SELECT
            EXTRACTVALUE(v_xml, '//place/@lat'),
            EXTRACTVALUE(v_xml, '//place/@lon')
        INTO p_latitude, p_longitude
        FROM DUAL;

        DBMS_OUTPUT.PUT_LINE('Geocode coords: ' || p_latitude || ', ' || p_longitude);

    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Geocoding error: ' || SQLERRM);
            p_latitude := c_default_lat;
            p_longitude := c_default_lon;
    END locationiq_geocode;

    -- Procedure: Klant toevoegen
    PROCEDURE add_klant(
        P_usr_username      VARCHAR2,
        P_usr_password      VARCHAR2,
        P_usr_email         VARCHAR2,
        P_usr_street_name   VARCHAR2,
        P_usr_house_number  VARCHAR2,
        P_usr_deleted       VARCHAR2
    ) AS
        v_usr_id        NUMBER;
        v_role_id       NUMBER;
        v_user_exists   NUMBER;
        v_latitude      NUMBER;
        v_longitude     NUMBER;
        v_distance      NUMBER;
    BEGIN
        -- Bestaat gebruiker al?
        SELECT COUNT(*) INTO v_user_exists FROM aut_users
        WHERE usr_username = P_usr_username OR usr_password = P_usr_password;

        IF v_user_exists > 0 THEN
            RAISE_APPLICATION_ERROR(-20001, 'Username or password already exists');
        END IF;

        -- Geocode ophalen
        locationiq_geocode(P_usr_street_name, v_latitude, v_longitude);

        -- Afstand berekenen tot shop
        v_distance := calculate_distance(
            v_latitude, v_longitude,
            c_shop_lat, c_shop_lon
        );

        -- Gebruiker invoegen
        INSERT INTO aut_users (
            usr_username, usr_password, usr_email, usr_street_name,
            usr_house_number, usr_deleted, usr_latitude, usr_longitude, usr_distance
        ) VALUES (
            P_usr_username, P_usr_password, P_usr_email, P_usr_street_name,
            P_usr_house_number, P_usr_deleted, v_latitude, v_longitude, v_distance
        )
        RETURNING usr_id INTO v_usr_id;

        -- Rol koppelen
        SELECT rle_id INTO v_role_id
        FROM aut_roles
        WHERE UPPER(rle_name) = 'KLANT';

        INSERT INTO aut_usr_rle (
            ure_usr_id, ure_rle_id, ure_valid_from, ure_valid_until
        ) VALUES (
            v_usr_id, v_role_id, SYSDATE, NULL
        );

        COMMIT;

    EXCEPTION
        WHEN DUP_VAL_ON_INDEX THEN
            RAISE_APPLICATION_ERROR(-20002, 'Duplicate username/email');
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(-20099, 'Unexpected error: ' || SQLERRM);
    END add_klant;

END add_klant_pkg;
/