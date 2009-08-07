------------------------------------------------------------------------------
-- Titulo           : vehp306.4gl - Consulta de existencias vehículos
-- Elaboracion      : 05-dic-2001
-- Autor            : NPC
-- Formato Ejecucion: fglrun vehp306 base módulo compañía localidad [modelo]
-- Ultima Correccion: 
-- Motivo Correccion: 
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_demonios	VARCHAR(12)
DEFINE vm_nuevoprog     VARCHAR(400)
DEFINE rm_veh		RECORD LIKE veht022.*
DEFINE rm_veh2		RECORD LIKE veht020.*
DEFINE vm_max_det       SMALLINT
DEFINE vm_num_det       SMALLINT
DEFINE vm_scr_lin       SMALLINT
DEFINE vm_fecha_ini	DATE
DEFINE vm_fecha_ter	DATE
DEFINE vm_total         DECIMAL(12,2)
DEFINE rm_orden 	ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1	SMALLINT
DEFINE vm_columna_2	SMALLINT
DEFINE rm_det		ARRAY [1000] OF RECORD
				tit_estado	CHAR(11),
				tit_nuevo	CHAR(5),
				v22_codigo_veh	LIKE veht022.v22_codigo_veh,
				v22_modelo	LIKE veht022.v22_modelo,
				v05_descri_base	LIKE veht005.v05_descri_base,
				v22_bodega	LIKE veht022.v22_bodega,
				v22_moneda_prec	LIKE veht022.v22_moneda_prec,
				v22_precio	LIKE veht022.v22_precio
			END RECORD

MAIN

DEFER QUIT 
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/errores')
CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 AND num_args() <> 5 THEN   -- Validar # parámetros correcto
	CALL fgl_winmessage(vg_producto, 'Número de parámetros incorrecto', 'stop')
	EXIT PROGRAM
END IF
LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_codcia   = arg_val(3)
LET vg_codloc   = arg_val(4)
LET vg_proceso = 'vehp306'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()

END MAIN



FUNCTION funcion_master()

CALL fl_nivel_isolation()
LET vm_max_det = 1000
OPEN WINDOW w_mas AT 3,2 WITH 22 ROWS, 80 COLUMNS
    ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE 0, BORDER,
	      MESSAGE LINE LAST - 2)
OPTIONS INPUT WRAP,
	ACCEPT KEY	F12
OPEN FORM f_veh FROM "../forms/vehf306_1"
DISPLAY FORM f_veh
LET vm_scr_lin = 0
CALL muestra_contadores_det(0)
CALL borrar_cabecera()
CALL borrar_detalle()
CALL mostrar_cabecera_forma()
CALL control_consulta()

END FUNCTION



FUNCTION control_consulta()
DEFINE i,j,l,col	SMALLINT
DEFINE query		VARCHAR(800)
DEFINE expr_sql         VARCHAR(400)
DEFINE r_mod		RECORD LIKE veht020.*
DEFINE r_veh		RECORD LIKE veht022.*
DEFINE r_bod		RECORD LIKE veht002.*
DEFINE codt_aux		LIKE veht004.v04_tipo_veh
DEFINE nomt_aux		LIKE veht004.v04_nombre
DEFINE codm_aux		LIKE veht020.v20_modelo
DEFINE noml_aux		LIKE veht020.v20_linea
DEFINE codb_aux		LIKE veht002.v02_bodega
DEFINE nomb_aux		LIKE veht002.v02_nombre

INITIALIZE codt_aux, codm_aux, codb_aux TO NULL
LET int_flag = 0
WHILE TRUE
	LET vm_num_det = 0
	CALL borrar_detalle()
	CALL muestra_contadores_det(0)
	IF num_args() = 4 THEN
		LET rm_veh.v22_estado = 'A'
		LET rm_veh.v22_nuevo  = 'S'
		CONSTRUCT BY NAME expr_sql ON v22_codigo_veh, v22_estado,
			v22_chasis, v20_tipo_veh, v22_nuevo, v22_modelo,
			v22_bodega
			ON KEY(INTERRUPT)
				EXIT WHILE
			ON KEY(F2)
				IF INFIELD(v22_codigo_veh) THEN
					CALL fl_ayuda_serie_veh(vg_codcia,
							vg_codloc, codb_aux)
						RETURNING rm_veh.v22_codigo_veh,
							rm_veh.v22_chasis,
							rm_veh.v22_modelo,
							rm_veh.v22_cod_color,
							rm_veh.v22_estado
					LET int_flag = 0
					IF rm_veh.v22_codigo_veh IS NOT NULL
					THEN
						DISPLAY BY NAME
							rm_veh.v22_codigo_veh,
							rm_veh.v22_chasis,
							rm_veh.v22_modelo,
							rm_veh.v22_estado
					       CALL fl_lee_modelo_veh(vg_codcia,
							      rm_veh.v22_modelo)
							RETURNING r_mod.*
						DISPLAY BY NAME
							r_mod.v20_modelo_ext
						CALL muestra_estado()
					END IF
				END IF
				IF INFIELD(v20_tipo_veh) THEN
					CALL fl_ayuda_tipos_veh(vg_codcia)
						RETURNING codt_aux, nomt_aux
					LET int_flag = 0
					IF codt_aux IS NOT NULL THEN
						DISPLAY codt_aux TO v20_tipo_veh
						DISPLAY nomt_aux TO v04_nombre
					END IF
				END IF
				IF INFIELD(v22_modelo) THEN
					CALL fl_ayuda_modelos_veh(vg_codcia)
						RETURNING codm_aux, noml_aux
					LET int_flag = 0
					IF codm_aux IS NOT NULL THEN
						DISPLAY	codm_aux TO v22_modelo
					       CALL fl_lee_modelo_veh(vg_codcia,
								codm_aux)
							RETURNING r_mod.*
						DISPLAY BY NAME
							r_mod.v20_modelo_ext
					END IF
				END IF
				IF INFIELD(v22_bodega) THEN
					CALL fl_ayuda_bodegas_veh(vg_codcia)
						RETURNING codb_aux, nomb_aux
					LET int_flag = 0
					IF codb_aux IS NOT NULL THEN
						DISPLAY codb_aux TO v22_bodega
						DISPLAY nomb_aux TO v02_nombre
					END IF
				END IF
			BEFORE CONSTRUCT
				DISPLAY BY NAME rm_veh.v22_codigo_veh,
						rm_veh.v22_estado,
						rm_veh.v22_chasis,
						rm_veh.v22_nuevo,
						rm_veh2.v20_tipo_veh,
						rm_veh.v22_modelo,
						rm_veh.v22_bodega
				CALL muestra_estado()
			AFTER FIELD v22_estado
				IF GET_FLDBUF(v22_estado) IS NULL THEN
					LET rm_veh.v22_estado = 'A'
				ELSE
					IF GET_FLDBUF(v22_estado) <> 'A'
					AND GET_FLDBUF(v22_estado) <> 'P'
					AND GET_FLDBUF(v22_estado) <> 'C'
					AND GET_FLDBUF(v22_estado) <> 'R' THEN
						CALL fgl_winmessage(vg_producto,'El estado debe ser activo, pedido, chequeo o reservado.','info')
						NEXT FIELD v22_estado
					END IF
					LET rm_veh.v22_estado =
							GET_FLDBUF(v22_estado)
				END IF
				CALL muestra_estado()
			AFTER CONSTRUCT
				LET rm_veh.v22_codigo_veh = 
						GET_FLDBUF(v22_codigo_veh)
				LET rm_veh.v22_estado = GET_FLDBUF(v22_estado)
				LET rm_veh.v22_chasis = GET_FLDBUF(v22_chasis)
				LET rm_veh.v22_nuevo  = GET_FLDBUF(v22_nuevo)
				LET rm_veh2.v20_tipo_veh =
						GET_FLDBUF(v20_tipo_veh)
				LET rm_veh.v22_modelo = GET_FLDBUF(v22_modelo)
				LET rm_veh.v22_bodega = GET_FLDBUF(v22_bodega)
		END CONSTRUCT
	ELSE
		LET expr_sql = 'v22_modelo = "', arg_val(5), '"',
				' AND v22_estado IN ("A","P","R")'
		LET codm_aux = arg_val(5)
		CALL fl_lee_modelo_veh(vg_codcia, codm_aux) RETURNING r_mod.*
		DISPLAY codm_aux TO v22_modelo
		DISPLAY BY NAME r_mod.v20_modelo_ext
	END IF
	FOR i = 1 TO 10
		LET rm_orden[i] = '' 
	END FOR
	LET rm_orden[1]  = 'ASC'
	LET vm_columna_1 = 4
	LET vm_columna_2 = 5
	LET col          = 4
	WHILE TRUE
		LET query = 'SELECT v22_estado, v22_nuevo, v22_codigo_veh, ',
				'v22_modelo, v05_descri_base, v22_bodega, ',
				'v22_moneda_prec, v22_precio ',
				'FROM veht022, veht020, veht005, veht002, ',
					'gent013 ',
					'WHERE v22_compania    = ', vg_codcia,
					'  AND v22_localidad   = ', vg_codloc,
					'  AND v22_compania    = v20_compania ',
					'  AND v22_modelo      = v20_modelo ',
					'  AND v22_compania    = v05_compania ',
					'  AND v22_cod_color  = v05_cod_color ',
					'  AND v22_compania    = v02_compania ',
					'  AND v22_bodega      = v02_bodega ',
					'  AND v22_moneda_prec = g13_moneda ',
					'  AND ', expr_sql CLIPPED, 
				" ORDER BY ", vm_columna_1, ' ',
					rm_orden[vm_columna_1],
			        	', ', vm_columna_2, ' ',
					rm_orden[vm_columna_2]
		PREPARE deto FROM query
		DECLARE q_deto CURSOR FOR deto
		LET vm_num_det = 1
		FOREACH q_deto INTO rm_det[vm_num_det].*
			IF rm_det[vm_num_det].tit_estado = 'A' THEN
				LET rm_det[vm_num_det].tit_estado = 'ACTIVO'
			END IF
			IF rm_det[vm_num_det].tit_estado = 'P' THEN
				LET rm_det[vm_num_det].tit_estado = 'EN PEDIDO'
			END IF
			IF rm_det[vm_num_det].tit_estado = 'C' THEN
				LET rm_det[vm_num_det].tit_estado = 'PREPARAC.'
			END IF
			IF rm_det[vm_num_det].tit_estado = 'R' THEN
				LET rm_det[vm_num_det].tit_estado = 'RESERVADO'
			END IF
			IF rm_det[vm_num_det].tit_nuevo = 'S' THEN
				LET rm_det[vm_num_det].tit_nuevo = 'NUEVO'
			END IF
			IF rm_det[vm_num_det].tit_nuevo = 'N' THEN
				LET rm_det[vm_num_det].tit_nuevo = 'USADO'
			END IF
			LET vm_num_det = vm_num_det + 1
			IF vm_num_det > vm_max_det THEN
				EXIT FOREACH
			END IF
		END FOREACH
		LET vm_num_det = vm_num_det - 1
		IF vm_num_det = 0 THEN
			CALL fl_mensaje_consulta_sin_registros()
			IF num_args() = 5 THEN
				EXIT PROGRAM
			END IF
			EXIT WHILE
		END IF
		CALL sacar_total()
		CALL set_count(vm_num_det)
		LET int_flag = 0
		DISPLAY ARRAY rm_det TO rm_det.*
			BEFORE DISPLAY
				CALL dialog.keysetlabel('ACCEPT','')
			BEFORE ROW
				LET j = arr_curr()
				LET l = scr_line()
				CALL muestra_contadores_det(j)
				CALL fl_lee_cod_vehiculo_veh(vg_codcia,
						vg_codloc,
						rm_det[j].v22_codigo_veh)
					RETURNING r_veh.*
				CALL fl_lee_bodega_veh(vg_codcia,
						rm_det[j].v22_bodega)
					RETURNING r_bod.*
				DISPLAY r_veh.v22_chasis TO tit_chasis
				DISPLAY r_bod.v02_nombre TO tit_bodega
				IF rm_det[j].tit_estado <> 'RESERVADO' THEN
					CALL dialog.keysetlabel('F7','')
				ELSE
					CALL dialog.keysetlabel('F7','Reservación')
				END IF
			AFTER DISPLAY 
				CONTINUE DISPLAY
			ON KEY(INTERRUPT)
				LET int_flag = 1
				EXIT DISPLAY
			ON KEY(F5)
				CALL ver_serie_vehiculo(j)
				LET int_flag = 0
			ON KEY(F6)
				CALL ver_liquidacion(j)
				LET int_flag = 0
			ON KEY(F7)
				IF rm_det[j].tit_estado = 'RESERVADO' THEN
					CALL ver_reservacion(j)
					LET int_flag = 0
				END IF
			ON KEY(F15)
				LET col = 1
				EXIT DISPLAY
			ON KEY(F16)
				LET col = 2
				EXIT DISPLAY
			ON KEY(F17)
				LET col = 3
				EXIT DISPLAY
			ON KEY(F18)
				LET col = 4
				EXIT DISPLAY
			ON KEY(F19)
				LET col = 5
				EXIT DISPLAY
			ON KEY(F20)
				LET col = 6
				EXIT DISPLAY
			ON KEY(F21)
				LET col = 7
				EXIT DISPLAY
			ON KEY(F22)
				LET col = 8
				EXIT DISPLAY
		END DISPLAY
		IF int_flag = 1 THEN
			IF num_args() = 5 THEN
				EXIT PROGRAM
			END IF
			EXIT WHILE
		END IF
		IF col <> vm_columna_1 THEN
			LET vm_columna_2           = vm_columna_1 
			LET rm_orden[vm_columna_2] = rm_orden[vm_columna_1]
			LET vm_columna_1           = col 
		END IF
		IF rm_orden[vm_columna_1] = 'ASC' THEN
			LET rm_orden[vm_columna_1] = 'DESC'
		ELSE
			LET rm_orden[vm_columna_1] = 'ASC'
		END IF
	END WHILE
END WHILE

END FUNCTION



FUNCTION sacar_total()
DEFINE i		SMALLINT

LET vm_total = 0
FOR i = 1 TO vm_num_det
	LET vm_total = vm_total + rm_det[i].v22_precio
END FOR
DISPLAY vm_total TO tit_total

END FUNCTION



FUNCTION borrar_cabecera()

CLEAR v22_codigo_veh, v22_chasis, v20_tipo_veh, v04_nombre, v22_modelo,
	v20_modelo_ext, v22_bodega, v02_nombre
INITIALIZE rm_veh.*, rm_veh2.* TO NULL

END FUNCTION



FUNCTION borrar_detalle()
DEFINE i  		SMALLINT

CALL muestra_contadores_det(0)
LET vm_scr_lin = fgl_scr_size('rm_det')
FOR i = 1 TO vm_scr_lin
        INITIALIZE rm_det[i].* TO NULL
        CLEAR rm_det[i].*
END FOR
CLEAR tit_total, tit_bodega, tit_chasis

END FUNCTION



FUNCTION muestra_contadores_det(cor)
DEFINE cor	           SMALLINT

DISPLAY "" AT 6, 62
DISPLAY cor, " de ", vm_num_det AT 6, 66

END FUNCTION


 
FUNCTION muestra_estado()

DISPLAY BY NAME rm_veh.v22_estado
IF rm_veh.v22_estado = 'A' THEN
	DISPLAY 'ACTIVO' TO tit_estado_veh
END IF
IF rm_veh.v22_estado = 'P' THEN
	DISPLAY 'PREPARACION' TO tit_estado_veh
END IF
IF rm_veh.v22_estado = 'R' THEN
	DISPLAY 'RESERVADO' TO tit_estado_veh
END IF
IF rm_veh.v22_estado = 'C' THEN
	DISPLAY 'EN CHEQUEO' TO tit_estado_veh
END IF

END FUNCTION



FUNCTION mostrar_cabecera_forma()

DISPLAY 'Estado' TO tit_col1
DISPLAY 'N/U'    TO tit_col2
DISPLAY 'C. Veh' TO tit_col3
DISPLAY 'Modelo' TO tit_col4
DISPLAY 'Color'  TO tit_col5
DISPLAY 'BV'     TO tit_col6
DISPLAY 'Mo'     TO tit_col7
DISPLAY 'Precio' TO tit_col8

END FUNCTION



FUNCTION ver_serie_vehiculo(i)
DEFINE i		SMALLINT

LET vm_nuevoprog = 'cd ..', vg_separador, '..', vg_separador, 'VEHICULOS',
	vg_separador, 'fuentes', vg_separador, '; fglrun vehp108 ', vg_base,
	' ', vg_modulo, ' ', vg_codcia, ' ', vg_codloc, ' ',
	rm_det[i].v22_codigo_veh
RUN vm_nuevoprog

END FUNCTION



FUNCTION ver_liquidacion(i)
DEFINE i		SMALLINT
DEFINE r_exi		RECORD LIKE veht022.*

CALL fl_lee_cod_vehiculo_veh(vg_codcia, vg_codloc, rm_det[i].v22_codigo_veh)
	RETURNING r_exi.*
IF r_exi.v22_numero_liq IS NULL THEN
	CALL fgl_winmessage(vg_producto,'Factura no tiene número de liquidación.','exclamation')
	RETURN
END IF
LET vm_nuevoprog = 'cd ..', vg_separador, '..', vg_separador, 'VEHICULOS',
	vg_separador, 'fuentes', vg_separador, '; fglrun vehp212 ', vg_base,
	' ', vg_modulo, ' ', vg_codcia, ' ', vg_codloc, ' ',
	r_exi.v22_numero_liq
RUN vm_nuevoprog

END FUNCTION



FUNCTION ver_reservacion(i)
DEFINE i		SMALLINT
DEFINE r_res		RECORD LIKE veht033.*

INITIALIZE r_res.* TO NULL
SELECT * INTO r_res.* FROM veht033
	WHERE v33_compania   = vg_codcia
	  AND v33_localidad  = vg_codloc
	  AND v33_codigo_veh = rm_det[i].v22_codigo_veh
LET vm_nuevoprog = 'cd ..', vg_separador, '..', vg_separador, 'VEHICULOS',
	vg_separador, 'fuentes', vg_separador, '; fglrun vehp209 ', vg_base,
	' ', vg_modulo, ' ', vg_codcia, ' ', vg_codloc, ' ',
	r_res.v33_num_reserv
RUN vm_nuevoprog

END FUNCTION



FUNCTION validar_parametros()

CALL fl_lee_modulo(vg_modulo) RETURNING rg_mod.*
IF rg_mod.g50_modulo IS NULL THEN
	CALL fgl_winmessage(vg_producto, 'No existe módulo: ' || vg_modulo, 'stop')
	EXIT PROGRAM
END IF
CALL fl_lee_compania(vg_codcia) RETURNING rg_cia.*
IF rg_cia.g01_compania IS NULL THEn
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
