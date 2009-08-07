{*
 * -- Titulo           : repp224.4gl - Proceso clasificacion ABC
 * -- Elaboracion      : 27-jun-2008
 * -- Autor            : JCM
 * -- Formato Ejecucion: fglrun repp224 base_datos modulo compañía 
 *}

GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_param		LIKE rept104.r104_codigo



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/repp224.error')
CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 3 THEN          -- Validar # parámetros correcto
	CALL fgl_winmessage(vg_producto, 'Número de parámetros incorrecto', 'stop')
	EXIT PROGRAM
END IF
LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_codcia   = arg_val(3)
LET vg_proceso = 'repp224'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()

END MAIN



FUNCTION funcion_master()
DEFINE i		SMALLINT
DEFINE resp		CHAR(6)

LET vm_param = 'ABC'

OPEN WINDOW repw224_1 AT 3,2 WITH 22 ROWS, 80 COLUMNS
	ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE FIRST,
		  BORDER, MESSAGE LINE LAST) 
OPEN FORM f_repf224_1 FROM '../forms/repf224_1'
DISPLAY FORM f_repf224_1

MENU 'OPCIONES'
	COMMAND KEY('C') 'Calcular'
		CALL fgl_winquestion(vg_producto,'Está seguro que desea realizar elste proceso?','No','Yes|No|Cancel','question',1)
			RETURNING resp
		IF resp = 'Yes' THEN
			CALL calcular_clasificacion()
		END IF 
	COMMAND KEY('S') 'Salir'
		EXIT MENU
END MENU

CLOSE WINDOW repw224_1

END FUNCTION



FUNCTION calcular_clasificacion()
DEFINE query 	VARCHAR(1000)

WHENEVER ERROR CONTINUE
DROP TABLE temp_item
WHENEVER ERROR STOP

LET query = 'SELECT r10_codigo, ',
			'		CASE NVL(r105_valor, r104_valor_default) ',
				'		WHEN 0 THEN "E" ',
				'		WHEN 1 THEN "A" ',
				'		WHEN 2 THEN "B" ',
				'		WHEN 3 THEN "C" ',
				'		ELSE NULL ',	
			'		END as te_valact, "C" as te_valnue',
		    '  FROM rept010, rept011, rept104, OUTER rept105 ', 
		    ' WHERE r10_compania   = ', vg_codcia, 
			'	AND r11_compania   = r10_compania ',
			'	AND r11_item       = r10_codigo ',
			'   AND r104_compania  = r10_compania ',
  			'   AND r104_codigo    = "', vm_param CLIPPED, '"',
			'   AND r105_compania  = r104_compania ',
			'   AND r105_parametro = r104_codigo ',
			'   AND r105_item      = r10_codigo ',
			'   AND r105_fecha_fin IS NULL ',
			' GROUP BY 1, 2 ',
			'  INTO TEMP temp_item '

PREPARE cit1 FROM query
EXECUTE cit1

DELETE FROM temp_item WHERE te_valact = 'E'
UPDATE temp_item SET te_valnue = NULL

CALL control_clasificacion()
CALL actualiza_parametro()

END FUNCTION



FUNCTION control_clasificacion()
DEFINE item			LIKE rept010.r10_codigo
DEFINE fecha		DATE
DEFINE fecha_ini	DATETIME YEAR TO SECOND
DEFINE fecha_fin	DATETIME YEAR TO SECOND

DEFINE query		VARCHAR(1000)

DEFINE vtas_item	DECIMAL(15,2)
DEFINE vtas_totales	DECIMAL(15,2)
DEFINE porc			DECIMAL(5,2)
DEFINE porc_total	DECIMAL(5,2)
DEFINE clasif		CHAR(1)


	LET fecha = MDY(MONTH(TODAY), 1, YEAR(TODAY)) 
	LET fecha_fin = EXTEND(fecha, YEAR TO SECOND) - 1 UNITS SECOND
	LET fecha_ini = EXTEND(fecha, YEAR TO SECOND) - 1 UNITS YEAR
	
	WHENEVER ERROR CONTINUE
	DROP TABLE tt_vtas
	WHENEVER ERROR STOP

	LET query = 'SELECT r20_item, r20_cod_tran, (r20_precio * r20_cant_ven) as valvta',
	  			' FROM rept020 ',
				'WHERE r20_compania  = ', vg_codcia CLIPPED,
	   			'  AND r20_localidad = ', vg_codloc CLIPPED,
	   			'  AND r20_cod_tran IN ("FA", "DF", "AF") ',
	   			'  AND r20_fecing BETWEEN "', fecha_ini CLIPPED, '" ',
									' AND "', fecha_fin CLIPPED, '" ',
				' INTO TEMP tt_vtas '

	PREPARE stmt2 FROM query
	EXECUTE stmt2

	UPDATE tt_vtas SET valvta = valvta * (-1) WHERE r20_cod_tran IN ('DF', 'AF')

	SELECT NVL(SUM(valvta), 0) INTO vtas_totales FROM tt_vtas
	IF vtas_totales = 0 THEN
		CALL fgl_winmessage(vg_producto, 'No han habido ventas en el periodo.',
										 'exclamation')
		RETURN
	END IF
 
	LET query = 'SELECT r10_codigo, SUM(valvta), ',
							     ' (SUM(valvta)*100)/', vtas_totales,
				'  FROM tt_vtas, temp_item ',
				' WHERE r20_item = r10_codigo ',
				' GROUP BY r10_codigo ',
				'HAVING SUM(valvta) > 0 ',
				' ORDER BY 3 DESC ' 

	PREPARE stmt3 FROM query
	DECLARE q_clasif CURSOR FOR stmt3

	LET porc_total = 0
	FOREACH q_clasif INTO item, vtas_item, porc
		DISPLAY BY NAME item
		IF porc_total <= 50 THEN
			LET clasif = 'A'
		END IF
		IF porc_total <= 90 THEN
			LET clasif = 'B'
		END IF
		IF porc_total > 90 THEN
			EXIT FOREACH
		END IF
		LET porc_total = porc_total + porc
		UPDATE temp_item SET te_valnue = clasif 
		 WHERE r10_codigo = item 
	END FOREACH 

END FUNCTION



FUNCTION actualiza_parametro()
DEFINE query		VARCHAR(1000)

BEGIN WORK

	UPDATE rept105 SET r105_fecha_fin = TODAY
	 WHERE r105_compania = vg_codcia
	   AND r105_parametro = vm_param 
	   AND r105_item IN (SELECT r10_codigo FROM temp_item WHERE te_valnue IS NOT NULL AND te_valact <> te_valnue)
	   AND r105_fecha_fin IS NULL

	LET query = 'INSERT INTO rept105(r105_compania, r105_parametro, r105_item, ', 
								'	 r105_fecha_ini, r105_secuencia, r105_valor, ',
 								'	 r105_origen, r105_usuario) ',
				'SELECT ', vg_codcia CLIPPED, ', "',  vm_param CLIPPED, '",  ',
						' r10_codigo, TODAY, ',
						' NVL((SELECT MAX(r105_secuencia) FROM rept105 ',
							' 	 WHERE r105_compania = ', vg_codcia CLIPPED,
								'  AND r105_parametro = "', vm_param CLIPPED, '"',
								'  AND r105_item = r10_codigo ',
								'  AND r105_fecha_ini = TODAY), 0) + 1, ',
						' CASE te_valnue WHEN "A" THEN 1 ',
										'WHEN "B" THEN 2 ',
										'WHEN "C" THEN 3 ',
										'WHEN "E" THEN 0 ',
						'  END, "M", "', vg_usuario CLIPPED, '"',
	 			'  FROM temp_item ',
				' WHERE te_valnue IS NOT NULL AND te_valnue <> te_valact '

	PREPARE stmt1 FROM query
	EXECUTE stmt1

COMMIT WORK

CALL fgl_winmessage(vg_producto, 'Proceso realizado Ok.', 'info')

END FUNCTION



FUNCTION validar_parametros()

CALL fl_lee_modulo(vg_modulo) RETURNING rg_mod.*
IF rg_mod.g50_modulo IS NULL THEN
	CALL fgl_winmessage(vg_producto, 'No existe módulo: ' || vg_modulo, 'stop')
	EXIT PROGRAM
END IF
CALL fl_lee_compania(vg_codcia) RETURNING rg_cia.*
IF rg_cia.g01_compania IS NULL THEN
	CALL fgl_winmessage(vg_producto, 'No existe compañía: '|| vg_codcia, 'stop')
	EXIT PROGRAM
END IF
IF rg_cia.g01_estado <> 'A' THEN
	CALL fgl_winmessage(vg_producto, 'Compañía no está activa: ' || vg_codcia, 'stop')
	EXIT PROGRAM
END IF
IF vg_codloc IS NULL THEN
	LET vg_codloc   = fl_retorna_agencia_default(vg_codcia)
END IF
CALL fl_lee_localidad(vg_codcia, vg_codloc) RETURNING rg_loc.*
IF rg_loc.g02_localidad IS NULL THEN
	CALL fgl_winmessage(vg_producto, 'No existe localidad: ' || vg_codloc, 'stop')
	EXIT PROGRAM
END IF
IF rg_loc.g02_estado <> 'A' THEN
	CALL fgl_winmessage(vg_producto, 'Localidad no está activa: '|| vg_codloc, 'stop')
	EXIT PROGRAM
END IF

END FUNCTION
