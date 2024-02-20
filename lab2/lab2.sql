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
