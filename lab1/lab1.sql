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
