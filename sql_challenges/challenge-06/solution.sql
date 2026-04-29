CREATE OR REPLACE TRIGGER trg_pet_log_insert
BEFORE INSERT ON pet_care_log
FOR EACH ROW
BEGIN
    :NEW.update_date := SYSDATE;
    :NEW.updated_by_user := USER;

EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20001, 'Error al insertar en el registro de pet_care_log');
END;
/

CREATE OR REPLACE TRIGGER trg_pet_log_update
BEFORE UPDATE ON pet_care_log
FOR EACH ROW
BEGIN
    IF USER != :OLD.updated_by_user THEN
        RAISE_APPLICATION_ERROR(-20002, 'Solo puedes actualizar registros creados por ti');
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20003, 'Error al actualizar el registro de pet_care_log');
END;
/

CREATE OR REPLACE TRIGGER trg_pet_log_delete
BEFORE DELETE ON pet_care_log
FOR EACH ROW
BEGIN
    IF USER != 'JOEMANAGER' THEN
        RAISE_APPLICATION_ERROR(-20004, 'Solo el gerente puede eliminar registros');
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20005, 'Error al eliminar el registro de pet_care_log');
END;
/