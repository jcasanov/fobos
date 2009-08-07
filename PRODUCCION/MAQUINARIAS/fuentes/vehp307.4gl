------------------------------------------------------------------------------
-- Titulo           : vehp307.4gl - Consulta de reservaciones de vehículos
-- Elaboracion      : 20-div-2001
-- Autor            : NPC
-- Formato Ejecucion: fglrun vehp307 base módulo compañía localidad
--			[reservación]
-- Ultima Correccion: 
-- Motivo Correccion: 
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_demonios	VARCHAR(12)
DEFINE vm_nuevoprog     VARCHAR(400)
DEFINE vm_max_res       SMALLINT
DEFINE vm_num_res       SMALLINT
DEFINE vm_scr_lin       SMALLINT
DEFINE vm_flag_ped      SMALLINT
DEFINE rm_orden 	ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1	SMALLINT
DEFINE vm_columna_2	SMALLINT
DEFINE rm_det		ARRAY [1000] OF RECORD
				v33_fecing	DATE,
				v33_num_reserv	LIKE veht033.v33_num_reserv,
				v22_modelo	LIKE veht022.v22_modelo,
				z01_nomcli	LIKE cxct001.z01_nomcli,
				v01_iniciales	LIKE veht001.v01_iniciales,
				v33_moneda_doc	LIKE veht033.v33_moneda_doc,
				v33_val_doc	LIKE veht033.v33_val_doc
			END RECORD

MAIN

DEFER QUIT 
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/errores')
CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 AND num_args() <> 5 THEN  -- Validar # parámetros correcto
	CALL fgl_winmessage(vg_producto, 'Número de parámetros incorrecto.', 'stop')
	EXIT PROGRAM
END IF
LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_codcia   = arg_val(3)
LET vg_codloc   = arg_val(4)
LET vg_proceso = 'vehp307'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()

END MAIN



FUNCTION funcion_master()

CALL fl_nivel_isolation()
LET vm_max_res = 1000
OPEN WINDOW w_mas AT 3,2 WITH 22 ROWS, 80 COLUMNS
    ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE 0,BORDER,
	      MESSAGE LINE LAST - 2)
OPTIONS INPUT WRAP,
	ACCEPT KEY	F12
OPEN FORM f_veh FROM "../forms/vehf307_1"
DISPLAY FORM f_veh
CLEAR FORM
LET vm_scr_lin = 0
CALL borrar_detalle()
CALL muestra_contadores_det(0)
CALL mostrar_cabecera_forma()
CALL control_consulta()

END FUNCTION



FUNCTION control_consulta()
DEFINE i,j,l,col	SMALLINT
DEFINE query		VARCHAR(600)
DEFINE expr_sql		VARCHAR(100)

FOR i = 1 TO vm_max_res
	INITIALIZE rm_det[i].* TO NULL
END FOR
INITIALIZE expr_sql TO NULL
IF num_args() = 5 THEN
	LET expr_sql = '  AND v33_num_reserv LIKE "', arg_val(5), '"'
END IF
LET vm_num_res = 0
LET int_flag   = 0
FOR i = 1 TO 10
	LET rm_orden[i] = '' 
END FOR
LET rm_orden[1]  = 'ASC'
LET vm_columna_1 = 1
LET vm_columna_2 = 2
LET col          = 1
WHILE TRUE
	LET query = 'SELECT DATE(v33_fecing), v33_num_reserv, v22_modelo, ',
			'z01_nomcli, v01_iniciales, v33_moneda_doc, ',
			'v33_val_doc ',
			'FROM veht033, veht022, cxct001, veht001 ',
			'WHERE v33_compania   = ', vg_codcia,
	 		'  AND v33_localidad  = ', vg_codloc,
			expr_sql CLIPPED,
			'  AND v22_compania   = v33_compania ',
			'  AND v22_localidad  = v33_localidad ',
			'  AND v22_codigo_veh = v33_codigo_veh ',
			'  AND v22_estado     <> "F" ',
			'  AND v33_codcli     = z01_codcli ',
			'  AND v33_compania   = v01_compania ',
			'  AND v33_vendedor   = v01_vendedor ',
			" ORDER BY ", vm_columna_1, ' ', rm_orden[vm_columna_1],
			 	', ', vm_columna_2, ' ', rm_orden[vm_columna_2]
	PREPARE deto FROM query
	DECLARE q_deto CURSOR FOR deto
	LET vm_num_res = 1
	FOREACH q_deto INTO rm_det[vm_num_res].*
		LET vm_num_res = vm_num_res + 1
		IF vm_num_res > vm_max_res THEN
			EXIT FOREACH
		END IF
	END FOREACH
	LET vm_num_res = vm_num_res - 1
	IF vm_num_res = 0 THEN
		CALL fl_mensaje_consulta_sin_registros()
		RETURN
	END IF
	CALL set_count(vm_num_res)
	LET int_flag = 0
	DISPLAY ARRAY rm_det TO rm_det.*
		BEFORE DISPLAY
			CALL dialog.keysetlabel('ACCEPT','')
		BEFORE ROW
			LET j = arr_curr()
			LET l = scr_line()
			CALL muestra_contadores_det(j)
		AFTER DISPLAY 
			CONTINUE DISPLAY
		ON KEY(INTERRUPT)
			LET int_flag = 1
			EXIT DISPLAY
		ON KEY(F5)
			CALL ver_reservacion(j)
			LET int_flag = 0
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
	END DISPLAY
	IF int_flag = 1 THEN
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

END FUNCTION


 
FUNCTION borrar_detalle()
DEFINE i  		SMALLINT

CALL muestra_contadores_det(0)
LET vm_scr_lin = fgl_scr_size('rm_det')
FOR i = 1 TO vm_scr_lin
        INITIALIZE rm_det[i].* TO NULL
        CLEAR rm_det[i].*
END FOR

END FUNCTION



FUNCTION muestra_contadores_det(cor)
DEFINE cor	           SMALLINT

DISPLAY "" AT 22, 4
DISPLAY cor, " de ", vm_num_res AT 22, 8

END FUNCTION



FUNCTION ver_reservacion(i)
DEFINE i		SMALLINT

LET vm_nuevoprog = 'cd ..', vg_separador, '..', vg_separador, 'VEHICULOS',
	vg_separador, 'fuentes', vg_separador, '; fglrun vehp209 ', vg_base,
	' ', vg_modulo, ' ', vg_codcia, ' ', vg_codloc, ' ', 
	rm_det[i].v33_num_reserv
RUN vm_nuevoprog

END FUNCTION



FUNCTION mostrar_cabecera_forma()

DISPLAY 'Fecha'   TO tit_col1
DISPLAY '#'       TO tit_col2
DISPLAY 'Modelo'  TO tit_col3
DISPLAY 'Cliente' TO tit_col4
DISPLAY 'Sig.'    TO tit_col5
DISPLAY 'Mo'      TO tit_col6
DISPLAY 'Valor'   TO tit_col7

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
