BEGIN WORK;

ALTER TABLE gent055 ADD g55_opciones CHAR(15) BEFORE g55_usuario;
UPDATE gent055 SET g55_opciones = 'SSSSSSSSSSSSSSS' WHERE 1 = 1;
ALTER TABLE gent055 MODIFY g55_opciones CHAR(15) NOT NULL;

COMMIT WORK;
