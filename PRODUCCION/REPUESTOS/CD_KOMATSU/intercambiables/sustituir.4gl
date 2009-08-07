DATABASE diteca
MAIN
DEFINE r		RECORD LIKE migracion:te_rept014.*
DEFINE i		INTEGER

SET LOCK MODE TO WAIT

DISPLAY "Actualizando sustitutos..."
DECLARE q1 CURSOR FOR SELECT * FROM migracion:te_rept014 order by 1, 2
LET i = 0
FOREACH q1 INTO r.*
	LET i = i + 1
	SELECT * FROM rept014 WHERE r14_compania = 1 
		                AND r14_item_ant = r.te_item    
				AND r14_item_nue = r.te_item_nue

	IF status <> NOTFOUND THEN
		update rept010 set r10_estado = 'S' 
			WHERE r10_compania = 1
		  	  and r10_codigo = r.te_item 
		CONTINUE FOREACH
	END IF

	select * from rept010 where r10_compania = 1
				and r10_codigo = r.te_item
	if status = NOTFOUND THEN
		display 'Item a sustituir: ', r.te_item, ' no existe.'
		continue foreach
	end if

	select * from rept010 where r10_compania = 1
				and r10_codigo = r.te_item_nue
	if status = NOTFOUND THEN
		display 'Item sustituto: ', r.te_item_nue, ' no existe.'
		continue foreach
	end if
 
	display 'insertando regla de sustitucion: ', r.te_item, ' por ', r.te_item_nue
	INSERT INTO rept014 VALUES 
		(1, r.te_item, r.te_item_nue, 'FOBOS', CURRENT) 

	update rept010 set r10_estado = 'S' 
		WHERE r10_compania = 1
		  and r10_codigo = r.te_item 
 
END FOREACH

END MAIN
