create or replace PACKAGE add_medewerker_pkg AS
    PROCEDURE add_mederwerker(
        P_usr_username VARCHAR2,
        P_usr_password VARCHAR2,
        P_usr_email VARCHAR2,
        P_usr_street_name VARCHAR2,
        P_usr_house_number VARCHAR2,
        P_usr_deleted VARCHAR2
    );
END add_medewerker_pkg;
/