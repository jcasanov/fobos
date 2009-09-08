BEGIN WORK;

SELECT g05_usuario, 1 compania, g54_modulo, g54_proceso, 'FOBOS' usuario, 
       CURRENT fecha_ing
  FROM gent054, gent005
 WHERE g05_estado = 'A' AND g54_estado = 'A'
   AND NOT EXISTS (SELECT 1 FROM gent055 WHERE g55_user     = g05_usuario
					   AND g55_compania = 1
					   AND g55_modulo   = g54_modulo
					   AND g55_proceso  = g54_proceso)
   AND EXISTS (SELECT 1 FROM gent052 WHERE g52_modulo   = g54_modulo
                                       AND g52_usuario  = g05_usuario
                                       AND g52_estado   = 'A')
   AND EXISTS (SELECT 1 FROM gent053 WHERE g53_modulo   = g54_modulo
                                       AND g53_usuario  = g05_usuario
                                       AND g53_compania = 1)
 INTO TEMP tmp_gent055;

DELETE FROM gent055;
INSERT INTO gent055 SELECT * FROM tmp_gent055;
DELETE FROM gent055 WHERE g55_user = 'FOBOS';

COMMIT WORK;

