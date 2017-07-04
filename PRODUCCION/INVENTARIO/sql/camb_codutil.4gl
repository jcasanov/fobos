DATABASE aceros


DEFINE codcia		LIKE gent001.g01_compania
DEFINE base_ori		CHAR(20)
DEFINE base_des		CHAR(20)
DEFINE serv_ori		CHAR(20)
DEFINE serv_des		CHAR(20)



MAIN

	IF num_args() <> 5 THEN
		DISPLAY 'PARAMETROS INCORRECTOS. FALTAN: '
		DISPLAY '   BASE_ORIGEN SERVIDOR_ORIGEN BASE_DESTINO SERVIDOR_DESTINO COMPAÑIA.'
		EXIT PROGRAM
	END IF
	LET base_ori = arg_val(1)
	LET serv_ori = arg_val(2)
	LET base_des = arg_val(3)
	LET serv_des = arg_val(4)
	LET codcia   = arg_val(5)
	CALL ejecuta_proceso()
	DISPLAY ' '
	DISPLAY 'Actualización Terminada OK.'

END MAIN



FUNCTION activar_base(b, s)
DEFINE b, s		CHAR(20)
DEFINE base, base1	CHAR(20)
DEFINE r_g51		RECORD LIKE gent051.*

LET base  = b
LET base1 = base CLIPPED, '@', s
CLOSE DATABASE
WHENEVER ERROR CONTINUE
DATABASE base1
IF STATUS < 0 THEN
	DISPLAY 'No se pudo abrir base de datos: ', base1
	EXIT PROGRAM
END IF
WHENEVER ERROR STOP
INITIALIZE r_g51.* TO NULL
SELECT * INTO r_g51.* FROM gent051 WHERE g51_basedatos = base
IF r_g51.g51_basedatos IS NULL THEN
	DISPLAY 'No existe base de datos: ', base
	EXIT PROGRAM
END IF

END FUNCTION



FUNCTION ejecuta_proceso()
DEFINE r_r10		RECORD LIKE rept010.*
DEFINE cod_util		LIKE rept010.r10_cod_util
DEFINE query		CHAR(1500)
DEFINE cuantos, i, j, l	INTEGER

SET ISOLATION TO DIRTY READ
DISPLAY 'Obteniendo los Items. Por favor espere ...'
CALL activar_base(base_des, serv_des)
LET query = 'SELECT * FROM rept010 ',
		' WHERE r10_compania  = ', codcia,
		'   AND r10_estado    = "A" ',
		'   AND r10_cod_util  = "RE000" ',
		'   AND r10_marca    IN ("F.P.S.", "KITO", "TECVAL", "MYERS", ',
				'"MARKPE", "PENTEK", "GRUNDF", "NIPEL", ',
				'"GORMAN", "SCHAEF", "FRANKL", "JOHNVA", ',
				'"ENERPA", "RIDGID", "INOXTE", "FECON", ',
				'"WELLMA", "MILWAU")',
		' INTO TEMP tmp_r10 '
PREPARE exec_r10 FROM query
EXECUTE exec_r10
DISPLAY ' '
SELECT COUNT(*) INTO cuantos FROM tmp_r10
IF cuantos = 0 THEN
	DISPLAY 'No hay ítems para actualizar.'
	DISPLAY ' '
	RETURN
END IF
DISPLAY 'Se van a actualizar un total de ', cuantos USING "<<<<<&", ' ítems.'
DISPLAY ' '
UNLOAD TO "ite_util1.unl" SELECT * FROM tmp_r10
DROP TABLE tmp_r10
CALL activar_base(base_ori, serv_ori)
SELECT * FROM rept010 WHERE r10_compania = 999 INTO TEMP tmp_r10
LOAD FROM "ite_util1.unl" INSERT INTO tmp_r10
LET query = 'SELECT a.r10_compania cia, a.r10_codigo item, a.r10_cod_util util',
		' FROM rept010 a, tmp_r10 b ',
		' WHERE a.r10_compania = b.r10_compania ',
		'   AND a.r10_codigo   = b.r10_codigo ',
		' INTO TEMP tmp_uti '
PREPARE exec_uti FROM query
EXECUTE exec_uti
UNLOAD TO "ite_util2.unl" SELECT * FROM tmp_uti
DROP TABLE tmp_uti
CALL activar_base(base_des, serv_des)
SELECT * FROM rept010 WHERE r10_compania = 999 INTO TEMP tmp_r10
LOAD FROM "ite_util1.unl" INSERT INTO tmp_r10
SELECT r10_compania cia, r10_codigo item, r10_cod_util util FROM rept010
	WHERE r10_compania = 999
	INTO TEMP tmp_uti
LOAD FROM "ite_util2.unl" INSERT INTO tmp_uti
DISPLAY 'Procesando códigos de utilidad en los ítems. Por favor espere ...'
DECLARE q_r10 CURSOR WITH HOLD FOR SELECT * FROM tmp_r10
LET i = 0
LET j = 0
LET l = 0
FOREACH q_r10 INTO r_r10.*
	LET cod_util = NULL
	LET query = 'SELECT UNIQUE r10_cod_util FROM rept010 ',
			' WHERE r10_compania   = ', r_r10.r10_compania,
			'   AND r10_cod_util  <> "', r_r10.r10_cod_util, '"',
			'   AND r10_linea      = "', r_r10.r10_linea, '"',
			'   AND r10_sub_linea  = "', r_r10.r10_sub_linea, '"',
			'   AND r10_cod_grupo  = "', r_r10.r10_cod_grupo, '"',
			'   AND r10_cod_clase  = "', r_r10.r10_cod_clase, '"',
			'   AND r10_marca      = "', r_r10.r10_marca, '"'
	PREPARE cons_uti FROM query
	DECLARE q_uti CURSOR FOR cons_uti
	OPEN q_uti
	FETCH q_uti INTO cod_util
	CLOSE q_uti
	FREE q_uti
	IF cod_util IS NULL THEN
		SELECT util INTO cod_util
			FROM tmp_uti
			WHERE cia  = r_r10.r10_compania
			  AND item = r_r10.r10_codigo
		DISPLAY '  ITEM: ', r_r10.r10_codigo CLIPPED, ' código de ',
			'utilidad en: ', base_ori CLIPPED, '@', serv_ori CLIPPED
		LET j = j + 1
	ELSE
		LET i = i + 1
		DISPLAY '  ITEM: ', r_r10.r10_codigo CLIPPED, ' código de ',
			'utilidad en: ', base_des CLIPPED, '@', serv_des CLIPPED
	END IF
	IF cod_util IS NULL THEN
		DISPLAY '   ERROR EN EL ITEM: ', r_r10.r10_codigo CLIPPED,
			' no tiene código de utilidad para actualizar.'
		LET l = l + 1
		CONTINUE FOREACH
	END IF
	LET query = 'UPDATE rept010 ',
			' SET r10_cod_util = "', cod_util, '"',
			' WHERE r10_compania = ', r_r10.r10_compania,
			'   AND r10_codigo   = ', r_r10.r10_codigo
	BEGIN WORK
	WHENEVER ERROR CONTINUE
		PREPARE exec_up FROM query
		EXECUTE exec_up
		IF STATUS < 0 THEN
			ROLLBACK WORK
			DISPLAY '  El ítem esta bloqueado.'
			DISPLAY ' Proceso no pudo terminar correctamente.'
			WHENEVER ERROR STOP
			EXIT PROGRAM
		END IF
		IF STATUS = NOTFOUND THEN
			ROLLBACK WORK
			DISPLAY '  El ítem no existe.'
			DISPLAY ' Proceso no pudo terminar correctamente.'
			WHENEVER ERROR STOP
			EXIT PROGRAM
		END IF
	WHENEVER ERROR STOP
	COMMIT WORK
	DISPLAY 'Item ', r_r10.r10_codigo CLIPPED, ' actualizado.'
END FOREACH
DISPLAY ' '
DISPLAY 'Se actualizaron ', i USING "<<<<&", ' ítems desde: ', 
	base_des CLIPPED, '@',serv_des CLIPPED, '. OK'
DISPLAY 'Se actualizaron ', j USING "<<<<&", ' ítems desde: ', 
	base_ori CLIPPED, '@',serv_ori CLIPPED, '. OK'
DISPLAY ' '
DISPLAY 'No se actualizaron ', l USING "<<<<&", ' ítems.' 
DISPLAY ' '
LET cuantos = i + j
DISPLAY 'Se actualizaron un total de ', cuantos USING "<<<<&", ' ítems. OK '
DISPLAY ' '
DROP TABLE tmp_r10
DROP TABLE tmp_uti

END FUNCTION
