DATABASE diteca

MAIN
DEFINE r		RECORD LIKE migracion:te_new_precios.*
DEFINE i		INTEGER
DEFINE fob		LIKE rept010.r10_fob

DEFINE linea		CHAR(5)
DEFINE modelo		VARCHAR(10)

IF num_args() <> 1 THEN
	display 'Ingrese linea.'
	EXIT PROGRAM
END IF

LET linea = arg_val(1)
IF linea = 'KOMAT' THEN
	LET modelo = 'KOMATSU'
END IF
IF linea = 'BOMAG' THEN
	LET modelo = 'BOMAG'
END IF

SET LOCK MODE TO WAIT
display 'preparando para actualizar precio fob...'
UPDATE rept010 SET r10_fob = 0 WHERE r10_compania = 1
				 AND r10_linea = linea  
--BEGIN WORK
DISPLAY "Actualizando FOB en Maestro ..."
DECLARE q1 CURSOR FOR SELECT * FROM migracion:te_new_precios
LET i = 0
FOREACH q1 INTO r.*
	LET i = i + 1
	LET fob = r.te_fob
	SELECT * FROM rept010 WHERE r10_compania = 1 
		                AND r10_codigo = r.te_item
--	DISPLAY i USING '#####&', ' ', r.te_item
	IF status <> NOTFOUND THEN
                DISPLAY r.te_item, ' ', 'existe... Actualizando FOB ', r.te_fob
                update rept010 set r10_fob = fob
                WHERE   r10_compania = 1 AND
                        r10_codigo   = r.te_item
		CONTINUE FOREACH
	END IF
 
	DISPLAY r.te_item, ' no existe... Creando registro '
	INSERT INTO rept010 VALUES 
		(1, r.te_item, r.te_nombre, 'A', 1, 
		0, 'UNIDAD', 1, 1, 'LAS DEMAS', modelo, 
		linea  , '99', 'S', r.te_fob, 
		'DO', 0, 0, 0, 0, 0, 0, 0, 0,
		NULL, 0, NULL, NULL, 'FOBOS', CURRENT, NULL)
 
END FOREACH
--COMMIT WORK

END MAIN
