DROP TABLE Students;
DROP TABLE Groups;
DROP TABLE Students_Log;


-- 1
CREATE TABLE Students (
    id NUMBER PRIMARY KEY,
    name VARCHAR2(100) NOT NULL,
    group_id NUMBER NOT NULL
);

CREATE TABLE Groups (
    id NUMBER PRIMARY KEY,
    name VARCHAR2(100) NOT NULL,
    c_val NUMBER NOT NULL
);


--2

-- unigue id for students

CREATE OR REPLACE TRIGGER check_student_id_unique
BEFORE INSERT OR UPDATE OF id ON Students
FOR EACH ROW
DECLARE
    id_count NUMBER;
BEGIN
    SELECT COUNT(*)
    INTO id_count
    FROM Students
    WHERE id = :NEW.id;

    IF id_count > 0 THEN
        RAISE_APPLICATION_ERROR(-20001, 'ID must be unique in Students table');
    END IF;
END;
/

-- id generation for students
CREATE OR REPLACE TRIGGER generate_student_id
BEFORE INSERT ON Students
FOR EACH ROW
BEGIN
    IF :NEW.id IS NULL THEN
        SELECT COALESCE(MAX(id), 0) + 1
        INTO :NEW.id
        FROM Students;
    END IF;
END;
/

-- Unique ID for groups
CREATE OR REPLACE TRIGGER check_group_id_unique
BEFORE INSERT OR UPDATE OF id ON Groups
FOR EACH ROW
DECLARE
    id_count NUMBER;
BEGIN
    SELECT COUNT(*)
    INTO id_count
    FROM Groups
    WHERE id = :NEW.id;

    IF id_count > 0 THEN
        RAISE_APPLICATION_ERROR(-20001, 'ID must be unique in Groups table');
    END IF;
END;
/

-- ID generation for groups
CREATE OR REPLACE TRIGGER generate_group_id
BEFORE INSERT ON Groups
FOR EACH ROW
BEGIN
    IF :NEW.id IS NULL THEN
        SELECT COALESCE(MAX(id), 0) + 1
        INTO :NEW.id
        FROM Groups;
    END IF;
END;
/
    

-- unigue name for groups

CREATE OR REPLACE TRIGGER check_group_name_unique
BEFORE INSERT OR UPDATE OF name ON Groups
FOR EACH ROW
DECLARE
    name_count NUMBER;
BEGIN
    SELECT COUNT(*)
    INTO name_count
    FROM Groups
    WHERE name = :NEW.name;

    IF name_count > 0 THEN
        RAISE_APPLICATION_ERROR(-20002, 'Name must be unique in Groups table');
    END IF;
END;
/

--3

CREATE OR REPLACE TRIGGER fk_cascade_delete
BEFORE DELETE ON Groups
FOR EACH ROW
BEGIN
    DELETE FROM Students WHERE group_id = :OLD.id;
END;
/

--4

CREATE TABLE Students_Log (
    log_id NUMBER GENERATED ALWAYS AS IDENTITY,
    action VARCHAR2(50),
    student_id NUMBER,
    student_name VARCHAR2(100),
    group_id NUMBER,
    action_date TIMESTAMP,
    PRIMARY KEY (log_id)
);
/

CREATE OR REPLACE TRIGGER student_action_logging
AFTER INSERT OR UPDATE OR DELETE ON Students
FOR EACH ROW
BEGIN
    IF INSERTING THEN
        INSERT INTO Students_Log (action, student_id, student_name, group_id, action_date)
        VALUES ('INSERT', :NEW.id, :NEW.name, :NEW.group_id, SYSTIMESTAMP);
    ELSIF UPDATING THEN
        INSERT INTO Students_Log (action, student_id, student_name, group_id, action_date)
        VALUES ('UPDATE', :OLD.id, :OLD.name, :OLD.group_id, SYSTIMESTAMP);
    ELSIF DELETING THEN
        INSERT INTO Students_Log (action, student_id, student_name, group_id, action_date)
        VALUES ('DELETE', :OLD.id, :OLD.name, :OLD.group_id, SYSTIMESTAMP);
    END IF;
END;
/

--5

CREATE OR REPLACE PROCEDURE restore_students_info (
    restore_time TIMESTAMP,
    time_offset_minutes NUMBER DEFAULT NULL
) AS
    restored_time TIMESTAMP;
    student_exists NUMBER;
BEGIN
    IF time_offset_minutes IS NOT NULL THEN
        restored_time := restore_time + (time_offset_minutes / (24 * 60)); 
    ELSE
        restored_time := restore_time;
    END IF;

    FOR log_rec IN (
        SELECT *
        FROM Students_Log
        WHERE action_date <= restored_time
        ORDER BY action_date DESC
    ) LOOP
        SELECT COUNT(*)
        INTO student_exists
        FROM Students
        WHERE id = log_rec.student_id;

        IF student_exists = 0 AND log_rec.action = 'DELETE' THEN
            INSERT INTO Students (id, name, group_id)
            VALUES (log_rec.student_id, log_rec.student_name, log_rec.group_id);
        END IF;
    END LOOP;
END;
/


--6

CREATE OR REPLACE TRIGGER update_groups_c_val
FOR INSERT OR UPDATE OR DELETE ON Students 
COMPOUND TRIGGER
    total_students NUMBER;

    AFTER EACH ROW IS
    BEGIN
        IF INSERTING THEN
            total_students := 1;
        ELSIF UPDATING THEN
            IF :NEW.group_id = :OLD.group_id THEN
                total_students := 0;
            ELSE
                total_students := -1;
            END IF;
        ELSIF DELETING THEN
            total_students := -1;
        END IF;
    END AFTER EACH ROW;

    AFTER STATEMENT IS
    BEGIN
        FOR group_rec IN (
            SELECT group_id, COUNT(*) AS group_count
            FROM Students
            GROUP BY group_id
        ) LOOP
            UPDATE Groups
            SET c_val = group_rec.group_count
            WHERE id = group_rec.group_id;
        END LOOP;
    END AFTER STATEMENT;
END update_groups_c_val;
/
