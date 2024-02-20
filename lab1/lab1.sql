DROP TABLE MyTable;

--1
CREATE TABLE MyTable(
    id NUMBER,
    val NUMBER NOT NULL,
    PRIMARY KEY (id)
);
/

--2
DECLARE
    v_counter NUMBER := 1;
BEGIN
    WHILE v_counter <= 10 LOOP
        INSERT INTO MyTable (id, val)
        VALUES (v_counter, FLOOR(DBMS_RANDOM.VALUE(1, 10000)));
        v_counter := v_counter + 1;
    END LOOP;
END;
/

--3
CREATE OR REPLACE FUNCTION check_even_odd_count RETURN VARCHAR2 AS
    v_even_count NUMBER := 0;
    v_odd_count NUMBER := 0;
BEGIN
    SELECT 
        COUNT(CASE WHEN MOD(val, 2) = 0 THEN 1 END),
        COUNT(CASE WHEN MOD(val, 2) != 0 THEN 1 END)
    INTO 
        v_even_count,
        v_odd_count
    FROM 
        MyTable;

    IF v_even_count > v_odd_count THEN
        RETURN 'TRUE';
    ELSIF v_even_count < v_odd_count THEN
        RETURN 'FALSE';
    ELSE
        RETURN 'EQUAL';
    END IF;
END;
/

--4
CREATE OR REPLACE FUNCTION generate_insert_command RETURN VARCHAR2 AS
    v_id NUMBER := FLOOR(DBMS_RANDOM.VALUE(1, 10000));
    v_val NUMBER := FLOOR(DBMS_RANDOM.VALUE(1, 10000));
    v_insert_command VARCHAR2(80);
BEGIN
    v_insert_command := 'INSERT INTO MyTable (id, val) VALUES (' || v_id || ', ' || v_val || ');';    
    DBMS_OUTPUT.PUT_LINE(v_insert_command);
    RETURN v_insert_command;
END;
/

--5
CREATE OR REPLACE PROCEDURE insert_into_mytable(
    p_val NUMBER
) AS
    v_new_id NUMBER;
BEGIN
    SELECT COALESCE(MAX(id), 0) + 1 INTO v_new_id FROM MyTable;
    INSERT INTO MyTable (id, val) VALUES (v_new_id, p_val);
    COMMIT;
END insert_into_mytable;
/

CREATE OR REPLACE PROCEDURE update_mytable(
    p_id NUMBER,
    p_new_val NUMBER
) AS
BEGIN
    UPDATE MyTable SET val = p_new_val WHERE id = p_id;
    COMMIT;
END update_mytable;
/

CREATE OR REPLACE PROCEDURE delete_from_mytable(
    p_id NUMBER
) AS
BEGIN
    DELETE FROM MyTable WHERE id = p_id;
    COMMIT;
END delete_from_mytable;
/

--6
CREATE OR REPLACE FUNCTION calculate_total_compensation(
    p_monthly_salary IN VARCHAR2,
    p_annual_bonus_percentage IN VARCHAR2
) RETURN NUMBER AS
    v_annual_bonus_percentage NUMBER;
    v_total_compensation NUMBER;
    
    e_negative_value EXCEPTION;
    e_null           EXCEPTION;
BEGIN
    IF (p_monthly_salary IS NULL OR p_annual_bonus_percentage IS NULL) THEN
        RAISE_APPLICATION_ERROR(-20001, 'Both values must not be null');
    END IF;
    
    BEGIN
        v_annual_bonus_percentage := TO_NUMBER(p_annual_bonus_percentage);
        v_total_compensation := TO_NUMBER(p_monthly_salary);
    EXCEPTION
        WHEN VALUE_ERROR THEN
            RAISE_APPLICATION_ERROR(-20002, 'Both values must be numbers');
    END;
    
    IF v_total_compensation <= 0 THEN
        RAISE_APPLICATION_ERROR(-20003, 'Monthly salary must be a positive number');
    END IF;
    
    IF v_annual_bonus_percentage < 0 THEN
        RAISE_APPLICATION_ERROR(-20004, 'The percentage of annual bonuses cannot be negative');
    END IF;
    
    v_annual_bonus_percentage := v_annual_bonus_percentage / 100;
    
    v_total_compensation := (1 + v_annual_bonus_percentage) * 12 * v_total_compensation;
    
    RETURN v_total_compensation;
EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20005, 'An error occurred: ' || SQLERRM);
END calculate_total_compensation;
/

# additional task
CREATE OR REPLACE PROCEDURE inserting_check(
    p_id NUMBER, p_val NUMBER
) AS
    v_count NUMBER;
    v_insert_command VARCHAR2(80);
BEGIN
    SELECT COUNT(*) 
    INTO v_count 
    FROM MyTable
    WHERE id = p_id;
    
    IF v_count > 0 THEN
        DBMS_OUTPUT.PUT_LINE('ERROR');
    ELSE
        v_insert_command := 'INSERT INTO MyTable (id, val) VALUES (' || p_id || ', ' || p_val || ');';    
        DBMS_OUTPUT.PUT_LINE(v_insert_command);
    END IF;
END;
/
