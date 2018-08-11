--------------------------------------------------------------------------------
-- Titulo           : cajp301.4gl - Consulta de los cierre de caja
-- Elaboracion      : 21-Feb-2005
-- Autor            : NPC
-- Formato Ejecucion: fglrun cajp301 base módulo compañía localidad
-- Ultima Correccion: 
-- Motivo Correccion: 
--------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE rm_j10		RECORD LIKE cajt010.*
DEFINE vm_max_det       SMALLINT
DEFINE vm_num_det       SMALLINT
DEFINE vm_fecha_ini	DATE
DEFINE vm_fecha_fin	DATE
DEFINE rm_cierre	ARRAY [10000] OF RECORD
				j04_localidad	LIKE cajt004.j04_localidad,
				j04_codigo_caja	LIKE cajt004.j04_codigo_caja,
				j04_fecha_aper	LIKE cajt004.j04_fecha_aper,
				j04_fecha_cierre LIKE cajt004.j04_fecha_cierre,
				j04_usuario	LIKE cajt004.j04_usuario,
				j05_ef_apertura	LIKE cajt005.j05_ef_apertura,
				j05_ch_apertura	LIKE cajt005.j05_ch_apertura
			END RECORD
DEFINE rm_orden 	ARRAY [10] OF CHAR(4)
DEFINE vm_columna_1	SMALLINT
DEFINE vm_columna_2	SMALLINT
DEFINE vm_size_arr	INTEGER
DEFINE vm_total_ef	DECIMAL(12,2)
DEFINE vm_total_ch	DECIMAL(12,2)



MAIN

DEFER QUIT 
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/cajp301.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 THEN   -- Validar # parámetros correcto
	CALL fl_mostrar_mensaje('Número de parámetros incorrecto.', 'stop')
	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_codloc  = arg_val(4)
LET vg_proceso = 'cajp301'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
--#CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()

END MAIN



FUNCTION funcion_master()
DEFINE lin_menu		SMALLINT
DEFINE row_ini  	SMALLINT
DEFINE num_rows 	SMALLINT
DEFINE num_cols 	SMALLINT

CALL fl_nivel_isolation()
LET vm_max_det = 10000
LET lin_menu   = 0
LET row_ini    = 3
LET num_rows   = 22
LET num_cols   = 80
IF vg_gui = 0 THEN
	LET lin_menu = 1
	LET row_ini  = 4
	LET num_rows = 20
	LET num_cols = 78
END IF
OPEN WINDOW w_mas AT row_ini, 2 WITH num_rows ROWS, num_cols COLUMNS
    ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE lin_menu,BORDER,
	      MESSAGE LINE LAST - 1)
IF vg_gui = 1 THEN
        OPEN FORM f_caj FROM '../forms/cajf301_1'
ELSE
        OPEN FORM f_caj FROM '../forms/cajf301_1c'
END IF
DISPLAY FORM f_caj
CALL muestra_contadores_det(0)
CALL borrar_cabecera()
CALL borrar_detalle()
CALL mostrar_cabecera_forma()
CALL control_consulta()

END FUNCTION



FUNCTION control_consulta()

LET vm_fecha_ini = NULL
SELECT NVL(MAX(DATE(j04_fecha_cierre)), vg_fecha) INTO vm_fecha_ini
	FROM cajt004
	WHERE j04_compania  = vg_codcia
	  AND j04_localidad = vg_codloc
LET vm_fecha_fin = vg_fecha
WHILE TRUE
	LET vm_num_det = 0
	CALL borrar_detalle()
	CALL muestra_contadores_det(0)
	CALL lee_parametros()
	IF int_flag THEN
		EXIT WHILE
	END IF
	CALL muestra_detalle()
	IF rm_j10.j10_codigo_caja IS NULL THEN
		CLEAR j10_codigo_caja, j02_nombre_caja
	END IF
END WHILE

END FUNCTION



FUNCTION lee_parametros()
DEFINE r_caj		RECORD LIKE cajt002.*
DEFINE cod_aux		LIKE cajt002.j02_codigo_caja
DEFINE nom_aux		LIKE cajt002.j02_nombre_caja
DEFINE fecha_ini	DATE
DEFINE fecha_fin	DATE
DEFINE expr_sql		CHAR(400)

INITIALIZE cod_aux, expr_sql TO NULL
LET int_flag = 0
INPUT BY NAME rm_j10.j10_codigo_caja, vm_fecha_ini, vm_fecha_fin
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		LET int_flag = 1
		--#RETURN
		EXIT INPUT
        ON KEY(F1,CONTROL-W)
		CALL llamar_visor_teclas()
	ON KEY(F2)
		IF INFIELD(j10_codigo_caja) THEN
			CALL fl_ayuda_cajas(vg_codcia, vg_codloc)
				RETURNING cod_aux, nom_aux
			OPTIONS INPUT NO WRAP
			LET int_flag = 0
			IF cod_aux IS NOT NULL THEN
				LET rm_j10.j10_codigo_caja = cod_aux
				DISPLAY BY NAME rm_j10.j10_codigo_caja 
				DISPLAY nom_aux TO j02_nombre_caja
			END IF 
		END IF
	BEFORE INPUT
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
	BEFORE FIELD vm_fecha_ini
		LET fecha_ini = vm_fecha_ini
	BEFORE FIELD vm_fecha_fin
		LET fecha_fin = vm_fecha_fin
	AFTER FIELD j10_codigo_caja
		IF rm_j10.j10_codigo_caja IS NOT NULL THEN
			CALL fl_lee_codigo_caja_caja(vg_codcia, vg_codloc,
							rm_j10.j10_codigo_caja)
                        	RETURNING r_caj.*
			IF r_caj.j02_compania IS NULL THEN
				CALL fl_mostrar_mensaje('Código de Caja no existe.', 'exclamation')
				NEXT FIELD j10_codigo_caja
			END IF
			DISPLAY BY NAME r_caj.j02_nombre_caja
		ELSE
			CLEAR j02_nombre_caja
		END IF
	AFTER FIELD vm_fecha_ini 
		IF vm_fecha_ini IS NOT NULL THEN
			IF vm_fecha_ini > vg_fecha THEN
				CALL fl_mostrar_mensaje('La Fecha Inicial no puede ser mayor a la fecha de hoy.', 'exclamation')
				NEXT FIELD vm_fecha_ini
			END IF
		ELSE
			LET vm_fecha_ini = fecha_ini
			DISPLAY BY NAME vm_fecha_ini
		END IF
	AFTER FIELD vm_fecha_fin 
		IF vm_fecha_fin IS NOT NULL THEN
			IF vm_fecha_fin > vg_fecha THEN
				CALL fl_mostrar_mensaje('La Fecha Final no puede ser mayor a la Fecha de hoy.', 'exclamation')
				NEXT FIELD vm_fecha_fin
			END IF
		ELSE
			LET vm_fecha_fin = fecha_fin
			DISPLAY BY NAME vm_fecha_fin
		END IF
	AFTER INPUT
		IF vm_fecha_ini > vm_fecha_fin THEN
			CALL fl_mostrar_mensaje('La Fecha Inicial debe ser menor o igual a la Fecha Final.','exclamation')
			NEXT FIELD vm_fecha_ini
		END IF
END INPUT

END FUNCTION



FUNCTION muestra_detalle()
DEFINE i, j, col	SMALLINT
DEFINE query		CHAR(1200)
DEFINE expr_sql         CHAR(100)

INITIALIZE expr_sql TO NULL
IF rm_j10.j10_codigo_caja IS NOT NULL THEN
	LET expr_sql = '  AND j04_codigo_caja = ', rm_j10.j10_codigo_caja
END IF
FOR i = 1 TO 10
	LET rm_orden[i] = '' 
END FOR
LET col           = 4
LET rm_orden[col] = 'DESC'
LET vm_columna_1  = col
LET vm_columna_2  = 2
WHILE TRUE
	LET query = 'SELECT j04_localidad, j04_codigo_caja, j04_fecha_aper,',
			' j04_fecha_cierre, j04_usuario, j05_ef_apertura,',
			' j05_ch_apertura ',
			' FROM cajt004, cajt005 ',
			' WHERE j04_compania    = ', vg_codcia,
			'   AND j04_localidad   = ', vg_codloc,
			expr_sql CLIPPED, 
			'   AND DATE(j04_fecha_cierre) ',
				'BETWEEN "', vm_fecha_ini,
				  '" AND "', vm_fecha_fin, '"',
			'   AND j05_compania     = j04_compania ',
			'   AND j05_localidad   = j04_localidad ',
			'   AND j05_codigo_caja = j04_codigo_caja ',
			'   AND j05_fecha_aper  = j04_fecha_aper ',
			'   AND j05_secuencia   = j04_secuencia ',
			' ORDER BY ', vm_columna_1, ' ', rm_orden[vm_columna_1],
			       	', ', vm_columna_2, ' ', rm_orden[vm_columna_2]
	PREPARE deto FROM query
	DECLARE q_deto CURSOR FOR deto
	LET vm_num_det = 1
	FOREACH q_deto INTO rm_cierre[vm_num_det].*
		LET vm_num_det = vm_num_det + 1
		IF vm_num_det > vm_max_det THEN
			EXIT FOREACH
		END IF
	END FOREACH
	LET vm_num_det = vm_num_det - 1
	IF vm_num_det = 0 THEN
		CALL fl_mensaje_consulta_sin_registros()
		EXIT WHILE
	END IF
	CALL sacar_total()
	IF vg_gui = 0 THEN
		CALL muestra_datos_det(1)
	END IF
	CALL set_count(vm_num_det)
	LET int_flag = 0
	DISPLAY ARRAY rm_cierre TO rm_cierre.*
		ON KEY(INTERRUPT)
			LET int_flag = 1
			EXIT DISPLAY
       		ON KEY(F1,CONTROL-W)
			CALL llamar_visor_teclas()
       		ON KEY(RETURN)
			LET i = arr_curr()
			LET j = scr_line()
			CALL muestra_datos_det(i)
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
		--#BEFORE DISPLAY
			--#CALL dialog.keysetlabel('ACCEPT','')
			--#CALL dialog.keysetlabel("F1","")
			--#CALL dialog.keysetlabel("CONTROL-W","")
		--#BEFORE ROW
			--#LET i = arr_curr()
			--#LET j = scr_line()
			--#CALL muestra_contadores_det(i)
			--#CALL muestra_datos_det(i)
		--#AFTER DISPLAY 
			--#CONTINUE DISPLAY
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



FUNCTION borrar_cabecera()

CLEAR vm_fecha_ini, vm_fecha_fin, j10_codigo_caja, j02_nombre_caja
INITIALIZE rm_j10.*, vm_fecha_ini, vm_fecha_fin TO NULL

END FUNCTION



FUNCTION borrar_detalle()
DEFINE i		SMALLINT

CALL muestra_contadores_det(0)
CALL retorna_arreglo()
FOR i = 1 TO vm_size_arr
        INITIALIZE rm_cierre[i].* TO NULL
        CLEAR rm_cierre[i].*
END FOR
CLEAR vm_total_ef, vm_total_ch

END FUNCTION



FUNCTION muestra_contadores_det(cor)
DEFINE cor		SMALLINT

DISPLAY cor        TO num_row
DISPLAY vm_num_det TO max_row

END FUNCTION


 
FUNCTION mostrar_cabecera_forma()

--#DISPLAY 'LC'			TO tit_col1
--#DISPLAY 'C.Caj'		TO tit_col2
--#DISPLAY 'Fecha Ap.'		TO tit_col3
--#DISPLAY 'Fecha Cierre'	TO tit_col4
--#DISPLAY 'Usuario'		TO tit_col5
--#DISPLAY 'Valor EF Ap.'	TO tit_col6
--#DISPLAY 'Valor CH Ap.'	TO tit_col7

END FUNCTION



FUNCTION retorna_arreglo()

--#LET vm_size_arr = fgl_scr_size('rm_cierre')
IF vg_gui = 0 THEN
        LET vm_size_arr = 10
END IF

END FUNCTION



FUNCTION sacar_total()
DEFINE i		SMALLINT

LET vm_total_ef = 0
LET vm_total_ch = 0
FOR i = 1 TO vm_num_det
	LET vm_total_ef = vm_total_ef + rm_cierre[i].j05_ef_apertura
	LET vm_total_ch = vm_total_ch + rm_cierre[i].j05_ch_apertura
END FOR
DISPLAY BY NAME vm_total_ef, vm_total_ch

END FUNCTION



FUNCTION muestra_datos_det(i)
DEFINE i		SMALLINT
DEFINE r_j02		RECORD LIKE cajt002.*

CALL muestra_contadores_det(i)
IF rm_j10.j10_codigo_caja IS NULL THEN
	CALL fl_lee_codigo_caja_caja(vg_codcia,	vg_codloc,
					rm_cierre[i].j04_codigo_caja)
		RETURNING r_j02.*
	DISPLAY rm_cierre[i].j04_codigo_caja TO j10_codigo_caja
	DISPLAY BY NAME r_j02.j02_nombre_caja
END IF

END FUNCTION



FUNCTION llamar_visor_teclas()
DEFINE a		CHAR(1)

IF vg_gui = 0 THEN
	CALL fl_visor_teclas_caracter() RETURNING int_flag 
	LET a = fgl_getkey()
	CLOSE WINDOW w_tf
	LET int_flag = 0
END IF

END FUNCTION
