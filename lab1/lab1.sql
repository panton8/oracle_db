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
    WHILE v_counter <= 10000 LOOP
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
CREATE OR REPLACE FUNCTION generate_insert_command(p_id NUMBER) RETURN VARCHAR2 AS
    v_val NUMBER;
    v_insert_command VARCHAR2(80);
BEGIN
    SELECT val INTO v_val FROM MyTable WHERE id = p_id;
    v_insert_command := 'INSERT INTO MyTable (id, val) VALUES (' || p_id || ', ' || v_val || ');';    
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
    p_monthly_salary NUMBER,
    p_annual_bonus_percentage NUMBER
) RETURN NUMBER AS
    v_annual_bonus_percentage NUMBER;
    v_total_compensation NUMBER;
BEGIN
    IF p_monthly_salary <= 0 THEN
        RAISE_APPLICATION_ERROR(-20001, 'Monthly salary must be a positive number');
    END IF;
    
    IF p_annual_bonus_percentage < 0 THEN
        RAISE_APPLICATION_ERROR(-20002, 'The percentage of annual bonuses cannot be negative');
    END IF;
    
    v_annual_bonus_percentage := p_annual_bonus_percentage / 100;
    
    v_total_compensation := (1 + v_annual_bonus_percentage) * 12 * p_monthly_salary;
    
    RETURN v_total_compensation;
EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20003, 'An error occurred:' || SQLERRM);
END calculate_total_compensation;
/
