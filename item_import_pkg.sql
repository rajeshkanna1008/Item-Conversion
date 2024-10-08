CREATE OR REPLACE PACKAGE item_import_pkg
IS 
    PROCEDURE prc_item_import(errbuf OUT VARCHAR2, retcode OUT NUMBER); 
END item_import_pkg; 
/

CREATE OR REPLACE PACKAGE BODY item_import_pkg 
IS 
    g_user_id    fnd_user.user_id%TYPE; 
    g_login_id   NUMBER (15) := 0; 

    PROCEDURE prc_item_import(errbuf OUT VARCHAR2, retcode OUT NUMBER) 
    IS 
        CURSOR c1 
        IS 
            SELECT a.ROWID row_id, a.* 
            FROM item_staging_tbl a 
            WHERE a.process_flag = 'N'; 

        e_flag              CHAR (1); 
        e_msg               VARCHAR2 (2000); 
        l_count             NUMBER := 0; 
        n_organization_id   NUMBER; 
        xx_org              VARCHAR2(10); 
        n_segment1          VARCHAR2(100); 
        lv_template_name    varchar2(100); 
        n_request_id        number ; 
    BEGIN 
        DBMS_OUTPUT.put_line ('ENTER THE LOOP'); 
        FOR i IN c1 
        LOOP 
            e_flag := 'Y'; 
            l_count := l_count + 1; 
            e_msg := NULL; 
            DBMS_OUTPUT.put_line ('1. ' || i.organization_code); 

            -- Validate Organization Code
            BEGIN 
                SELECT organization_id 
                INTO n_organization_id 
                FROM mtl_parameters 
                WHERE organization_code = i.organization_code; 

                SELECT organization_code 
                INTO xx_org 
                FROM mtl_parameters 
                WHERE organization_id = 
                                    (SELECT master_organization_id 
                                    FROM mtl_parameters 
                                    WHERE organization_code = i.organization_code); 

                DBMS_OUTPUT.put_line ('THE CODE ORG CODE IS ' || xx_org); 
            EXCEPTION 
                WHEN NO_DATA_FOUND THEN 
                    e_flag := 'E'; 
                    e_msg := 'Organization code is invalid'; 
                WHEN OTHERS THEN 
                    e_flag := 'E'; 
                    e_msg := 'Error occurred while validating organization code'; 
            END; 

            -- Validate Item Code
            IF i.segment1 IS NOT NULL THEN 
                BEGIN 
                    SELECT 1 
                    INTO n_segment1 
                    FROM mtl_system_items_b msib 
                    WHERE segment1 = i.segment1 
                    AND organization_id = n_organization_id; 

                    IF SQL%FOUND THEN 
                        e_msg := 'Item code already exists'; 
                        DBMS_OUTPUT.put_line ('N_SEGMENT1: ' || l_count); 
                    END IF; 
                EXCEPTION 
                    WHEN NO_DATA_FOUND THEN 
                        NULL; -- Item code is valid 
                    WHEN OTHERS THEN 
                        e_flag := 'E'; 
                        e_msg := 'Error occurred while validating item code'; 
                END; 
            END IF; 

            -- Validate Template Name
            IF i.template_name IS NOT NULL THEN 
                BEGIN 
                    SELECT template_name 
                    INTO lv_template_name 
                    FROM mtl_item_templates 
                    WHERE template_name = i.template_name; 

                    IF SQL%NOTFOUND THEN 
                        e_msg := e_msg || ', Template name does not exist'; 
                        DBMS_OUTPUT.put_line ('n_template: ' || l_count); 
                    END IF; 
                EXCEPTION 
                    WHEN NO_DATA_FOUND THEN 
                        NULL; -- Template name is valid 
                    WHEN OTHERS THEN 
                        e_flag := 'E'; 
                        e_msg := 'Error occurred while validating template name'; 
                END; 
            END IF; 

            -- Insert data into mtl_system_items_interface table
            IF e_flag = 'Y' THEN 
                INSERT INTO mtl_system_items_interface (segment1, 
														description, 
														template_name, 
														organization_code, 
														organization_id, 
														transaction_type, 
														process_flag, 
														creation_date, 
														created_by, 
														last_update_date, 
														last_updated_by) 
                VALUES (i.segment1, 
						i.description, 
						i.template_name, 
						i.organization_code, 
						(SELECT organization_id FROM mtl_parameters WHERE organization_code = i.organization_code), 
						'CREATE', 
						1, 
						SYSDATE, 
						fnd_global.user_id, 
						SYSDATE, 
						fnd_global.user_id); 

                IF SQL%ROWCOUNT <> 0 THEN 
                    UPDATE item_staging_tbl 
                    SET process_flag = 'S' 
                    WHERE ROWID = i.row_id; 

                    COMMIT; 
                END IF; 
            ELSE 
                UPDATE item_staging_tbl 
                SET process_flag = 'E' 
                WHERE ROWID = i.row_id; 
            END IF; 
        END LOOP; 

 /*        -- Submit concurrent request
        n_request_id := fnd_request.submit_request ('INV', 
                                                    'INCOIN', 
                                                    'To submit item import from backend', 
                                                    NULL, 
                                                    FALSE, 
                                                    fnd_profile.VALUE ('MFG_ORGANIZATION_ID'), 
                                                    1, 
                                                    1, 
                                                    1, 
                                                    1, 
                                                    NULL, 
                                                    1); 
 */
        COMMIT; 
    EXCEPTION 
        WHEN OTHERS THEN 
            -- Rollback transaction in case of error
            ROLLBACK; 
            errbuf := SQLERRM; 
            retcode := SQLCODE; 
    END; 
END item_import_pkg; 
/


812 Husbands St, Paducah, KY 42003, USA
	