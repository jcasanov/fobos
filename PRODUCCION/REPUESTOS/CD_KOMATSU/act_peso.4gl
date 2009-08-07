DATABASE diteca

MAIN
DEFINE r		RECORD LIKE migracion:t_bomag.*
DEFINE i		INTEGER

display 'preparando para actualizar precio fob...'
DECLARE q1 CURSOR FOR SELECT * FROM migracion:t_bomag
LET i = 0
FOREACH q1 INTO r.*
	LET i = i + 1
	SELECT * FROM rept010 WHERE r10_compania = 1 
		                AND r10_codigo = r.codigo
--	DISPLAY i USING '#####&', ' ', r.codigo
	IF status <> NOTFOUND THEN
                DISPLAY r.codigo, ' ', 'existe... Actualizando  '
                update rept010 set r10_peso = r.peso
                WHERE   r10_compania = 1 AND
                        r10_codigo   = r.codigo
		CONTINUE FOREACH
	END IF
 
	DISPLAY r.codigo, ' no existe...  '
 
END FOREACH
--COMMIT WORK

END MAIN
