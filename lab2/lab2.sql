DROP TABLE Students;
DROP TABLE Groups;

--1
CREATE TABLE Students(
    id NUMBER,
    name VARCHAR2 NOT NULL,
    group_id NUMBER NOT NULL,
    PRIMARY KEY (id)
);
/

CREATE TABLE Groups(
    id NUMBER,
    name VARCHAR2 NOT NULL,
    c_val NUMBER NOT NULL,
    PRIMARY KEY (id)
);
/

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
