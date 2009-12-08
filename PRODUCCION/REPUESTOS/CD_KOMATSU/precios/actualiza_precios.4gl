DATABASE diteca

MAIN
DEFINE r		RECORD LIKE migracion:te_new_precios.*
DEFINE i		INTEGER
DEFINE movim	INTEGER
DEFINE fob		LIKE rept010.r10_fob
DEFINE costo	LIKE rept010.r10_costo_mb
DEFINE pvp		LIKE rept010.r10_precio_mb
DEFINE r_r10	RECORD LIKE rept010.*

DEFINE linea		CHAR(5)
DEFINE modelo		VARCHAR(10)
DEFINE filtro		CHAR(10)
DEFINE act_pesos	CHAR(2)
DEFINE kk, qq		INTEGER

IF num_args() <> 2 THEN
	display 'Ingrese linea y si actualiza pesos.'
	display 'Uso: fglrun actualiza_precios linea {SI|NO}' 
	EXIT PROGRAM
END IF


LET linea = arg_val(1)
IF linea = 'KOMAT' THEN
	LET modelo = 'KOMATSU'
	INITIALIZE filtro TO NULL 
END IF
IF linea = 'BOMAG' THEN
	LET modelo = 'BOMAG'
	INITIALIZE filtro TO NULL 
END IF
IF linea = 'HENSL' THEN
	LET linea  = 'KOMAT'
	LET modelo = 'KOMATSU'
	LET filtro = 'HENSLEY'
END IF
IF linea = 'FLEET' THEN
	LET modelo = 'FLEETGUARD'
	INITIALIZE filtro TO NULL 
END IF
IF linea = 'SOUVE' THEN
	LET modelo = 'SOUVENIR'
	INITIALIZE filtro TO NULL 
END IF

LET act_pesos = ARG_VAL(2)
IF act_pesos IS NULL THEN
	LET act_pesos = 'NO'
END IF

--LOCK TABLE rept010 IN EXCLUSIVE MODE
--display 'preparando para actualizar precio fob...'
--UPDATE rept010 SET r10_fob = 0 WHERE r10_compania = 1
--				 AND r10_linea = linea  
--BEGIN WORK
DISPLAY "Actualizando FOB en Maestro ..."
DECLARE q1 CURSOR FOR SELECT * FROM migracion:te_new_precios
LET i = 0
LET kk = 0
LET qq = 0
FOREACH q1 INTO r.*
	LET i = i + 1
	LET fob = r.te_fob

	INITIALIZE r_r10.* TO NULL
	SELECT * INTO r_r10.* FROM rept010 WHERE r10_compania = 1 
		                                 AND r10_codigo = r.te_item
  	DISPLAY i USING '#####&', ' ', r.te_item, " ", r.te_fob, "   ",
				r_r10.r10_fob
	IF r_r10.r10_compania IS NOT NULL THEN
                --DISPLAY r.te_item, ' ', 'existe... Actualizando FOB ', r.te_fob
				LET kk = kk + 1
				IF filtro IS NOT NULL THEN
					LET r_r10.r10_filtro = filtro
				END IF

				IF act_pesos = 'SI' THEN
					LET r_r10.r10_peso = r.te_peso
				END IF

				-- Si el item es de la linea SOUVE solo se 
				-- debe actualizar el costo y continuar con
				-- el siguiente
				IF linea = 'SOUVE' THEN
					LET r_r10.r10_costult_mb = r_r10.r10_costo_mb 
					LET r_r10.r10_costo_mb = fob
				ELSE

					-- Si no tiene movimientos, se actualiza costo y pvp
					SELECT COUNT(*) INTO movim
					  FROM rept020
					 WHERE r20_compania  = 1 
					   AND r20_localidad = 1
					   AND r20_item      = r.te_item
					
					LET r_r10.r10_fob = fob
					IF movim = 0 THEN
						LET r_r10.r10_costult_mb = r_r10.r10_costo_mb 
						LET r_r10.r10_precio_ant = r_r10.r10_precio_mb
						LET r_r10.r10_fec_camprec = CURRENT
						LET r_r10.r10_costo_mb = fob * 1.17
						LET r_r10.r10_precio_mb = r_r10.r10_costo_mb * 1.67
					END IF
				END IF	

                UPDATE rept010 SET * = r_r10.* 
                 WHERE r10_compania = 1 
				   AND r10_codigo   = r.te_item
		CONTINUE FOREACH
	END IF
 
	LET qq = qq + 1 
	DISPLAY qq USING "&&&&", '  ', r.te_item, ' no existe... Creando registro '
	IF linea = 'SOUVE' THEN
		INSERT INTO rept010 VALUES 
			(1, r.te_item, r.te_nombre, 'A', 1, 
			0, 'UNIDAD', 1, 1, 'LAS DEMAS', modelo, 
			linea  , '99', 'S', 0, 
			'DO', 0, 0, r.te_fob, 0, 0, 0, 
			0, 0, NULL, 0, CURRENT, filtro, 'FOBOS', CURRENT, NULL)
	ELSE
		INSERT INTO rept010 VALUES 
			(1, r.te_item, r.te_nombre, 'A', 1, 
			0, 'UNIDAD', 1, 1, 'LAS DEMAS', modelo, 
			linea  , '99', 'S', r.te_fob, 
			'DO', ((r.te_fob * 1.17) * 1.67), 0, (r.te_fob * 1.17), 0, 0, 0, 
			0, 0, NULL, 0, CURRENT, filtro, 'FOBOS', CURRENT, NULL)
	END IF
 
END FOREACH
--COMMIT WORK
DISPLAY "Total registros procesados  : ", i  USING "#.###.###.##&"
DISPLAY "Total registros actualizados: ", kk USING "#.###.###.##&"
DISPLAY "Total registros insertados  : ", qq USING "#.###.###.##&"

END MAIN
