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
