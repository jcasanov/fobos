--------------------------------------------------------------------------------
-- Titulo              : rolp350.4gl -- Consulta de Vacaciones
-- Elaboración         : 18-Ago-2007
-- Autor               : NPC
-- Formato de Ejecución: fglrun rolp350 Base Modulo Compañía
-- Ultima Correción    : 
-- Motivo Corrección   : 
--------------------------------------------------------------------------------

GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE rm_par		RECORD
				cod_depto	LIKE rolt030.n30_cod_depto,
				nom_depto	LIKE gent034.g34_nombre,
				estado		LIKE rolt039.n39_estado,
				cod_trab	LIKE rolt030.n30_cod_trab,
				nom_trab	LIKE rolt030.n30_nombres,
				fecha_ini	DATE,
				fecha_fin	DATE,
				tipo_fecha	CHAR(1),
				todas_vac	CHAR(1),
				tipo_vac	LIKE rolt039.n39_tipo,
				dias_pend	CHAR(1)
			END RECORD
DEFINE rm_detalle	ARRAY [2000] OF RECORD
				n39_cod_trab	LIKE rolt039.n39_cod_trab,
				n30_nombres	LIKE rolt030.n30_nombres,
				anio_v		LIKE rolt039.n39_ano_proceso,
				n39_dias_vac	LIKE rolt039.n39_dias_vac,
				n39_dias_adi	LIKE rolt039.n39_dias_adi,
				tot_dias	SMALLINT,
				n39_dias_goza	LIKE rolt039.n39_dias_goza,
				n39_tot_ganado	LIKE rolt039.n39_tot_ganado,
				n39_neto	LIKE rolt039.n39_neto
			END RECORD
DEFINE rm_adi		ARRAY [2000] OF RECORD
				n39_neto	LIKE rolt039.n39_neto,
				n39_descto_iess	LIKE rolt039.n39_descto_iess
			END RECORD
DEFINE rm_totales	RECORD
				tot_dias_vac	LIKE rolt039.n39_dias_vac,
				tot_dias_adi	LIKE rolt039.n39_dias_adi,
				tot_dias_v	INTEGER,
				tot_dias_goza	LIKE rolt039.n39_dias_goza,
				tot_ganado	LIKE rolt039.n39_tot_ganado,
				tot_neto	LIKE rolt039.n39_neto
			END RECORD
DEFINE rm_n90		RECORD LIKE rolt090.*
DEFINE vm_vac_goz	LIKE rolt039.n39_proceso
DEFINE vm_vac_pag	LIKE rolt039.n39_proceso
DEFINE vm_num_rows      SMALLINT        -- CANTIDAD DE FILAS LEIDAS
DEFINE vm_max_rows      SMALLINT        -- MAXIMO DE FILAS LEIDAS
DEFINE tot_valor_pag	DECIMAL(12,2)
DEFINE tot_valor_des	DECIMAL(12,2)
DEFINE rm_orden 	ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1	SMALLINT
DEFINE vm_columna_2	SMALLINT



MAIN

DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/rolp350.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 3 THEN
	CALL fl_mostrar_mensaje('Numero de parametros incorrecto.','stop')
     	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_proceso = 'rolp350'
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
DEFINE resul	 	SMALLINT
DEFINE r_n03		RECORD LIKE rolt003.*

CALL fl_nivel_isolation()
LET vm_vac_goz = 'VA'
CALL fl_lee_proceso_roles(vm_vac_goz) RETURNING r_n03.*
IF r_n03.n03_proceso IS NULL THEN
	CALL fl_mostrar_mensaje('No existe configurado el proceso VACACIONES en la tabla rolt003.', 'stop')
	EXIT PROGRAM
END IF
LET vm_vac_pag = 'VP'
CALL fl_lee_proceso_roles(vm_vac_pag) RETURNING r_n03.*
IF r_n03.n03_proceso IS NULL THEN
	CALL fl_mostrar_mensaje('No existe configurado el proceso VACACIONES PAGADAS en la tabla rolt003.', 'exclamation')
END IF
LET vm_num_rows = 0
LET vm_max_rows = 2000
LET lin_menu = 0
LET row_ini  = 3
LET num_rows = 22
LET num_cols = 80
IF vg_gui = 0 THEN
	LET lin_menu = 1
	LET row_ini  = 4
	LET num_rows = 20
	LET num_cols = 78
END IF
OPEN WINDOW w_rolf350_1 AT row_ini, 02 WITH num_rows ROWS, num_cols COLUMNS
    ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE lin_menu,
		BORDER, MESSAGE LINE LAST)
IF vg_gui = 1 THEN
	OPEN FORM f_rolf350_1 FROM '../forms/rolf350_1'
ELSE
	OPEN FORM f_rolf350_1 FROM '../forms/rolf350_1c'
END IF
DISPLAY FORM f_rolf350_1
DISPLAY "Cod."		TO tit_col1
DISPLAY "Empleados"	TO tit_col2
DISPLAY "A.V."		TO tit_col3
DISPLAY "DV."		TO tit_col4
DISPLAY "DA."		TO tit_col5
DISPLAY "TDV"		TO tit_col6
DISPLAY "DG."		TO tit_col7
DISPLAY "Total Ganado"	TO tit_col8
DISPLAY "Total Vacac."	TO tit_col9
CALL fl_lee_conf_adic_rol(vg_codcia) RETURNING rm_n90.*
IF rm_n90.n90_compania IS NULL THEN
	CALL fl_mostrar_mensaje('No existe configuracion adicional de nomina en la tabla rolt090.', 'stop')
	CLOSE WINDOW w_rolf350_1
	EXIT PROGRAM
END IF
CALL muestra_contadores(0, vm_num_rows)
INITIALIZE rm_par.* TO NULL
LET rm_par.fecha_ini  = MDY(MONTH(TODAY), 01, YEAR(TODAY))
LET rm_par.fecha_fin  = TODAY
LET rm_par.estado     = 'P'
LET rm_par.tipo_fecha = 'C'
LET rm_par.tipo_vac   = 'G'
LET rm_par.dias_pend  = 'N'
LET rm_par.todas_vac  = 'N'
WHILE TRUE
	CALL borrar_detalle()
	CALL leer_parametros()
	IF int_flag THEN
		EXIT WHILE
	END IF
	CALL control_consulta()
	DROP TABLE tmp_vac
END WHILE
LET int_flag = 0
CLOSE WINDOW w_rolf350_1
EXIT PROGRAM

END FUNCTION



FUNCTION borrar_detalle()
DEFINE i		SMALLINT

FOR i = 1 TO vm_max_rows
	INITIALIZE rm_detalle[i].*, rm_adi[i].* TO NULL
END FOR
FOR i = 1 TO fgl_scr_size('rm_detalle')
	CLEAR rm_detalle[i].*
END FOR
CLEAR num_row, max_row, tot_dias_vac, tot_dias_adi, tot_dias_v, tot_dias_goza,
	tot_ganado, tot_neto, nom_empl

END FUNCTION



FUNCTION leer_parametros()
DEFINE r_g34		RECORD LIKE gent034.*
DEFINE r_n30		RECORD LIKE rolt030.*
DEFINE fec_ini, fec_fin	DATE

LET int_flag = 0
INPUT BY NAME rm_par.*
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		LET int_flag = 1
		EXIT INPUT
	ON KEY(F2)
		IF INFIELD(cod_depto) THEN
			CALL fl_ayuda_departamentos(vg_codcia)
				RETURNING r_g34.g34_cod_depto, r_g34.g34_nombre
			IF r_g34.g34_cod_depto IS NOT NULL THEN
				LET rm_par.cod_depto = r_g34.g34_cod_depto
				LET rm_par.nom_depto = r_g34.g34_nombre
				DISPLAY BY NAME rm_par.cod_depto,
						rm_par.nom_depto
			END IF
		END IF
		IF INFIELD(cod_trab) THEN
			CALL fl_ayuda_codigo_empleado(vg_codcia)
				RETURNING r_n30.n30_cod_trab, r_n30.n30_nombres
			IF r_n30.n30_cod_trab IS NOT NULL THEN
				LET rm_par.cod_trab = r_n30.n30_cod_trab
				LET rm_par.nom_trab = r_n30.n30_nombres
				DISPLAY BY NAME rm_par.cod_trab,
						rm_par.nom_trab
			END IF
		END IF
		LET int_flag = 0
	BEFORE INPUT
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
	BEFORE FIELD fecha_ini
		LET fec_ini = rm_par.fecha_ini
	BEFORE FIELD fecha_fin
		LET fec_fin = rm_par.fecha_fin
	AFTER FIELD cod_depto
		IF rm_par.cod_depto IS NOT NULL THEN
			CALL fl_lee_departamento(vg_codcia, rm_par.cod_depto)
				RETURNING r_g34.*
			IF r_g34.g34_compania IS NULL THEN
				CALL fl_mostrar_mensaje('Departamento no existe.','exclamation')
				NEXT FIELD cod_depto
			END IF
			LET rm_par.nom_depto = r_g34.g34_nombre
			DISPLAY BY NAME rm_par.nom_depto
		ELSE
			CLEAR nom_depto
			LET rm_par.nom_depto = NULL
		END IF
	AFTER FIELD cod_trab
		IF rm_par.cod_trab IS NOT NULL THEN
			CALL fl_lee_trabajador_roles(vg_codcia, rm_par.cod_trab)
				RETURNING r_n30.*
			IF r_n30.n30_compania IS NULL THEN
				CALL fl_mostrar_mensaje('No existe el código de este empleado en la Compañía.','exclamation')
				NEXT FIELD cod_trab
			END IF
			LET rm_par.nom_trab = r_n30.n30_nombres
			DISPLAY BY NAME rm_par.nom_trab
		ELSE
			CLEAR nom_trab
			LET rm_par.nom_trab = NULL
		END IF
	AFTER FIELD fecha_ini
		IF rm_par.fecha_ini IS NULL THEN
			LET rm_par.fecha_ini = fec_ini
			DISPLAY BY NAME rm_par.fecha_ini
		END IF
		IF rm_par.fecha_ini > TODAY THEN
			CALL fl_mostrar_mensaje('La fecha inicial no puede ser mayor a la fecha de hoy.', 'exclamation')
			NEXT FIELD fecha_ini
		END IF
	AFTER FIELD fecha_fin
		IF rm_par.fecha_fin IS NULL THEN
			LET rm_par.fecha_fin = fec_fin
			DISPLAY BY NAME rm_par.fecha_fin
		END IF
		IF rm_par.fecha_fin > TODAY THEN
			CALL fl_mostrar_mensaje('La fecha final no puede ser mayor a la fecha de hoy.', 'exclamation')
			NEXT FIELD fecha_fin
		END IF
	AFTER INPUT
		IF rm_par.fecha_ini > rm_par.fecha_fin THEN
			CALL fl_mostrar_mensaje('La fecha inicial no puede ser mayor a la fecha final.', 'exclamation')
			NEXT FIELD fecha_ini
		END IF
END INPUT

END FUNCTION



FUNCTION control_consulta()
DEFINE query		CHAR(1500)
DEFINE i		SMALLINT

FOR i = 1 TO 10
	LET rm_orden[i] = '' 
END FOR
LET vm_columna_1 = 2
LET vm_columna_2 = 3
LET rm_orden[2]  = 'ASC'
LET rm_orden[3]  = 'DESC'
CALL preparar_query()
IF vm_num_rows = 0 THEN
	CALL fl_mensaje_consulta_sin_registros()
	RETURN
END IF
WHILE TRUE
	CALL cargar_detalle()
	CALL mostrar_detalle()
	IF int_flag THEN
		EXIT WHILE
	END IF
END WHILE

END FUNCTION



FUNCTION preparar_query()
DEFINE query		CHAR(1500)
DEFINE expr_dep		VARCHAR(100)
DEFINE expr_proc	VARCHAR(100)
DEFINE expr_trab	VARCHAR(100)
DEFINE expr_tip		VARCHAR(100)
DEFINE expr_est		VARCHAR(100)
DEFINE expr_fec		VARCHAR(200)

LET expr_dep = NULL
IF rm_par.cod_depto IS NOT NULL THEN
	LET expr_dep = '   AND n39_cod_depto    = ', rm_par.cod_depto
END IF
LET expr_trab = NULL
IF rm_par.cod_trab IS NOT NULL THEN
	LET expr_trab = '   AND n39_cod_trab      = ', rm_par.cod_trab
END IF
CASE rm_par.tipo_fecha
	WHEN 'V'
		LET expr_fec = '   AND n39_periodo_fin  BETWEEN "',
					rm_par.fecha_ini, '" AND "',
					rm_par.fecha_fin, '"'
	WHEN 'C'
		LET expr_fec = '   AND DATE(n39_fecing) BETWEEN "',
					rm_par.fecha_ini, '" AND "',
					rm_par.fecha_fin, '"'
END CASE
LET expr_tip = '   AND n39_tipo         = "', rm_par.tipo_vac, '"'
CASE rm_par.tipo_vac
	WHEN 'G' LET expr_proc = '   AND n39_proceso      = "', vm_vac_goz, '"'
	WHEN 'P' LET expr_proc = '   AND n39_proceso      = "', vm_vac_pag, '"'
END CASE
IF rm_par.todas_vac = 'S' THEN
	LET expr_tip  = NULL
	LET expr_proc = '   AND n39_proceso     IN ("', vm_vac_goz, '", ',
						'"', vm_vac_pag, '")'
END IF
LET expr_est = NULL
IF rm_par.dias_pend = 'S' AND rm_par.todas_vac = 'N' THEN
	LET expr_est = '   AND n30_estado       = "A" '
END IF
LET query = 'SELECT n39_cod_trab, n30_nombres, n39_ano_proceso anio_vac, ',
		'n39_dias_vac d_v, CASE WHEN n39_gozar_adic = "N" THEN 0 ',
		'ELSE n39_dias_adi END d_a, (n39_dias_vac + ',
		'CASE WHEN n39_gozar_adic = "N" THEN 0 ELSE n39_dias_adi END)',
		' tot_dias, n39_dias_goza d_g, n39_tot_ganado tot_gan, ',
		'(n39_valor_vaca + CASE WHEN ("', rm_par.tipo_vac, '" = "G" ',
		'AND n39_gozar_adic = "S") OR "', rm_par.todas_vac, '" = "S"',
			' THEN n39_valor_adic ELSE 0 END) ',
		'val_vac, n39_neto tot_net, n39_descto_iess ap_vac,',
		' n39_perfin_real p_fin',
		' FROM rolt039, rolt030 ',
		' WHERE n39_compania     = ', vg_codcia,
		expr_proc CLIPPED,
		expr_trab CLIPPED,
		'   AND n39_estado       = "', rm_par.estado, '"',
		expr_dep CLIPPED,
		expr_fec CLIPPED,
		expr_tip CLIPPED,
		'   AND n30_compania     = n39_compania ',
		'   AND n30_cod_trab     = n39_cod_trab ',
		expr_est CLIPPED,
		' INTO TEMP tmp_vac '
PREPARE exec_tmp FROM query
EXECUTE exec_tmp
CALL cargar_detalle()

END FUNCTION



FUNCTION cargar_detalle()
DEFINE r_detalle	RECORD
				n39_cod_trab	LIKE rolt039.n39_cod_trab,
				n30_nombres	LIKE rolt030.n30_nombres,
				anio_v		LIKE rolt039.n39_ano_proceso,
				n39_dias_vac	LIKE rolt039.n39_dias_vac,
				n39_dias_adi	LIKE rolt039.n39_dias_adi,
				tot_dias	SMALLINT,
				n39_dias_goza	LIKE rolt039.n39_dias_goza,
				n39_tot_ganado	LIKE rolt039.n39_tot_ganado,
				n39_neto	LIKE rolt039.n39_neto
			END RECORD
DEFINE r_adi		RECORD
				n39_neto	LIKE rolt039.n39_neto,
				n39_descto_iess	LIKE rolt039.n39_descto_iess
			END RECORD
DEFINE query		CHAR(600)
DEFINE registro		VARCHAR(255)
DEFINE fecha		DATE
DEFINE tiempo_max	INTEGER

LET query = 'SELECT n39_cod_trab, n30_nombres, anio_vac, d_v, d_a, tot_dias, ',
		'd_g, tot_gan, val_vac, tot_net, ap_vac, p_fin ',
		' FROM tmp_vac ',
		' ORDER BY ', vm_columna_1, ' ', rm_orden[vm_columna_1], ', ',
			      vm_columna_2, ' ', rm_orden[vm_columna_2]
PREPARE tmp_d FROM query	
DECLARE q_vac CURSOR FOR tmp_d
LET vm_num_rows = 1
FOREACH q_vac INTO r_detalle.*, r_adi.*, fecha
	IF rm_par.dias_pend = 'S' AND rm_par.todas_vac = 'N' THEN
		IF r_detalle.n39_dias_goza >= r_detalle.tot_dias THEN
			CONTINUE FOREACH
		END IF
		LET query = 'SELECT TRUNC((NVL(',
				'(SELECT MAX(n39_perfin_real) ',
				'FROM rolt039 ',
				'WHERE n39_compania = ', vg_codcia,
				'  AND n39_proceso  IN ("', vm_vac_goz, '", "',
							vm_vac_pag, '") ',
				'  AND n39_cod_trab = ', r_detalle.n39_cod_trab,
				'  AND n39_estado   = "P"), TODAY) - DATE("',
				fecha, '")) / ', rm_n90.n90_dias_anio,
				') + 1 val_t ',
				' FROM dual ',
				' INTO TEMP t1 '
		PREPARE exec_t1 FROM query
		EXECUTE exec_t1
		SELECT val_t INTO tiempo_max FROM t1
		DROP TABLE t1
		IF tiempo_max > rm_n90.n90_tiem_max_vac THEN
			CONTINUE FOREACH
		END IF
	END IF
	{--
	LET registro = r_detalle.n39_cod_trab USING "<<<<&", '|',
			r_detalle.n30_nombres CLIPPED, '|',
			r_detalle.anio_v USING "&&&&", '|',
			r_detalle.n39_dias_vac USING "<#", '|',
			r_detalle.n39_dias_adi USING "<#", '|',
			r_detalle.tot_dias USING "<#", '|',
			r_detalle.n39_dias_goza USING '<#', '|',
			r_detalle.n39_tot_ganado USING "<<<<<<&.##", '|',
			r_detalle.n39_neto USING "<<<<<<&.##", '|',
			r_adi.n39_neto USING "<<<<<<&.##", '|',
			r_adi.n39_descto_iess USING "<<<<<<&.##"
	DISPLAY registro CLIPPED
	--}
	LET rm_detalle[vm_num_rows].* = r_detalle.*
	LET rm_adi[vm_num_rows].*     = r_adi.*
	LET vm_num_rows = vm_num_rows + 1
	IF vm_num_rows > vm_max_rows THEN
		EXIT FOREACH
	END IF
END FOREACH
LET vm_num_rows = vm_num_rows - 1

END FUNCTION



FUNCTION mostrar_detalle()
DEFINE i, j, col	SMALLINT

CALL calcula_total()
LET int_flag = 0
CALL set_count(vm_num_rows)
DISPLAY ARRAY rm_detalle TO rm_detalle.*
       	ON KEY(INTERRUPT)   
		LET int_flag = 1
       	        EXIT DISPLAY  
	ON KEY(F5)
		LET i = arr_curr()
		CALL ver_comprobante_vacaciones(i, 'C')
		LET int_flag = 0
	ON KEY(F6)
		LET i = arr_curr()
		CALL ver_contabilizacion(i)
		LET int_flag = 0
	ON KEY(F7)
		LET i = arr_curr()
		CALL ver_comprobante_vacaciones(i, 'L')
		LET int_flag = 0
	ON KEY(F8)
		LET i = arr_curr()
		CALL ver_comprobante_vacaciones(i, 'G')
		LET int_flag = 0
	ON KEY(F9)
		LET i = arr_curr()
		CALL ver_tot_gan_liq(i)
		LET int_flag = 0
	ON KEY(F10)
		LET i = arr_curr()
		CALL control_imprimir()
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
	ON KEY(F22)
		LET col = 8
		EXIT DISPLAY
	ON KEY(F23)
		LET col = 9
		EXIT DISPLAY
	--#BEFORE DISPLAY 
		--#CALL dialog.keysetlabel('ACCEPT', '')   
		--#CALL dialog.keysetlabel("F1","") 
		--#CALL dialog.keysetlabel("CONTROL-W","") 
		--#CALL dialog.keysetlabel('RETURN', '')   
	--#BEFORE ROW 
		--#LET i = arr_curr()	
		--#LET j = scr_line()
		--#CALL muestra_etiquetas(i)
        --#AFTER DISPLAY  
                --#CONTINUE DISPLAY  
END DISPLAY
IF int_flag = 1 THEN
	RETURN
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

END FUNCTION



FUNCTION muestra_etiquetas(i)
DEFINE i		SMALLINT

CALL muestra_contadores(i, vm_num_rows)
DISPLAY rm_detalle[i].n30_nombres TO nom_empl
MESSAGE '    Valor Cobrado: ', rm_adi[i].n39_neto USING '#,###,##&.##',
	'    IESS Vacaciones: ', rm_adi[i].n39_descto_iess USING '###,##&.##'

END FUNCTION



FUNCTION calcula_total()
DEFINE i		SMALLINT

LET rm_totales.tot_dias_vac  = 0
LET rm_totales.tot_dias_adi  = 0
LET rm_totales.tot_dias_v    = 0
LET rm_totales.tot_dias_goza = 0
LET rm_totales.tot_ganado    = 0
LET rm_totales.tot_neto      = 0
FOR i = 1 TO vm_num_rows
	LET rm_totales.tot_dias_vac  = rm_totales.tot_dias_vac +
					rm_detalle[i].n39_dias_vac
	LET rm_totales.tot_dias_adi  = rm_totales.tot_dias_adi +
					rm_detalle[i].n39_dias_adi
	LET rm_totales.tot_dias_v    = rm_totales.tot_dias_v   +
					rm_detalle[i].tot_dias
	IF rm_detalle[i].n39_dias_goza IS NOT NULL THEN
		LET rm_totales.tot_dias_goza = rm_totales.tot_dias_goza +
						rm_detalle[i].n39_dias_goza
	END IF
	LET rm_totales.tot_ganado    = rm_totales.tot_ganado   +
					rm_detalle[i].n39_tot_ganado
	LET rm_totales.tot_neto      = rm_totales.tot_neto     +
					rm_detalle[i].n39_neto
END FOR
DISPLAY BY NAME rm_totales.*

END FUNCTION



FUNCTION muestra_contadores(num_row, max_row)
DEFINE num_row, max_row	SMALLINT

DISPLAY BY NAME num_row, max_row

END FUNCTION


 
FUNCTION registro_vacaciones(i)
DEFINE i		SMALLINT
DEFINE r_n39		RECORD LIKE rolt039.*

INITIALIZE r_n39.* TO NULL
DECLARE q_n39 CURSOR FOR
	SELECT * FROM rolt039
		WHERE n39_compania     = vg_codcia
		  AND n39_proceso     IN (vm_vac_goz, vm_vac_pag)
		  AND n39_cod_trab     = rm_detalle[i].n39_cod_trab
		  AND n39_ano_proceso  = rm_detalle[i].anio_v
		ORDER BY n39_periodo_fin DESC
OPEN q_n39
FETCH q_n39 INTO r_n39.*
CLOSE q_n39
FREE q_n39
RETURN r_n39.*

END FUNCTION


 
FUNCTION ver_comprobante_vacaciones(i, flag)
DEFINE i		SMALLINT
DEFINE flag		CHAR(1)
DEFINE param		VARCHAR(60)
DEFINE r_n39		RECORD LIKE rolt039.*

CALL registro_vacaciones(i) RETURNING r_n39.*
LET param = ' "', rm_par.estado, '" "', r_n39.n39_proceso, '" ',
		rm_detalle[i].n39_cod_trab
IF flag <> 'L' THEN
	LET param = param CLIPPED, ' "', r_n39.n39_periodo_ini, '" "',
			r_n39.n39_periodo_fin, '"'
	IF flag = 'G' THEN
		LET param = param CLIPPED, ' "G"'
	END IF
END IF
CALL ejecuta_comando('NOMINA', vg_modulo, 'rolp252 ', param)

END FUNCTION



FUNCTION ver_contabilizacion(i)
DEFINE i		SMALLINT
DEFINE r_n39		RECORD LIKE rolt039.*
DEFINE r_n57		RECORD LIKE rolt057.*
DEFINE param		VARCHAR(60)

CALL registro_vacaciones(i) RETURNING r_n39.*
INITIALIZE r_n57.* TO NULL
SELECT * INTO r_n57.*
	FROM rolt057
	WHERE n57_compania    = vg_codcia
	  AND n57_proceso     = r_n39.n39_proceso
	  AND n57_cod_trab    = r_n39.n39_cod_trab
	  AND n57_periodo_ini = r_n39.n39_periodo_ini
	  AND n57_periodo_fin = r_n39.n39_periodo_fin
IF r_n57.n57_compania IS NULL THEN
	RETURN
END IF
LET param = ' "', r_n57.n57_tipo_comp, '" ', r_n57.n57_num_comp
CALL ejecuta_comando('CONTABILIDAD', 'CB', 'ctbp201 ', param)

END FUNCTION



FUNCTION ejecuta_comando(modulo, mod, prog, param)
DEFINE modulo		VARCHAR(15)
DEFINE mod		LIKE gent050.g50_modulo
DEFINE prog		VARCHAR(10)
DEFINE param		VARCHAR(60)
DEFINE comando          VARCHAR(250)
DEFINE run_prog		VARCHAR(10)

LET run_prog = '; fglrun '
IF vg_gui = 0 THEN
	LET run_prog = '; fglgo '
END IF
LET comando = 'cd ..', vg_separador, '..', vg_separador, modulo, vg_separador,
		'fuentes', vg_separador, run_prog, prog, vg_base, ' ', mod, ' ',
		vg_codcia, ' ', param
RUN comando

END FUNCTION



FUNCTION ver_tot_gan_liq(i)
DEFINE i		SMALLINT
DEFINE r_n39		RECORD LIKE rolt039.*

CALL registro_vacaciones(i) RETURNING r_n39.*
CALL fl_valor_ganado_liquidacion(vg_codcia, r_n39.n39_proceso,
				r_n39.n39_cod_trab, r_n39.n39_perini_real,
				r_n39.n39_perfin_real)

END FUNCTION



FUNCTION control_imprimir()
DEFINE comando		VARCHAR(100)
DEFINE i		SMALLINT

CALL fl_control_reportes() RETURNING comando
IF int_flag THEN
	RETURN
END IF
START REPORT reporte_vacaciones TO PIPE comando
FOR i = 1 TO vm_num_rows
	OUTPUT TO REPORT reporte_vacaciones(i)
END FOR
FINISH REPORT reporte_vacaciones

END FUNCTION



REPORT reporte_vacaciones(i)
DEFINE i, j		SMALLINT
DEFINE r_g01		RECORD LIKE gent001.*
DEFINE r_g02		RECORD LIKE gent002.*
DEFINE r_g50		RECORD LIKE gent050.*
DEFINE titulo		VARCHAR(80)
DEFINE modulo		VARCHAR(32)
DEFINE usuario		VARCHAR(19)
DEFINE escape		SMALLINT
DEFINE act_10cpi	SMALLINT
DEFINE act_12cpi	SMALLINT
DEFINE act_dob1		SMALLINT
DEFINE act_dob2		SMALLINT
DEFINE des_dob		SMALLINT

OUTPUT
	TOP MARGIN	1
	LEFT MARGIN	0
	RIGHT MARGIN	96
	BOTTOM MARGIN	4
	PAGE LENGTH	66

FORMAT

PAGE HEADER
	LET escape	= 27		# Iniciar sec. impresi¢n
	LET act_10cpi	= 80		# Comprimido 10 CPI.
	LET act_12cpi	= 77		# Comprimido 12 CPI.
	LET act_dob1	= 87		# Activar Doble Ancho (inicio)
	LET act_dob2	= 49		# Activar Doble Ancho (final)
	LET des_dob	= 48		# Desactivar Doble Ancho
	CALL fl_justifica_titulo('C', "LISTADO DE VACACIONES", 42)
		RETURNING titulo
	print ASCII escape;
	print ASCII act_12cpi;
	PRINT COLUMN 012, ASCII escape, ASCII act_dob1, ASCII act_dob2,
	      COLUMN 016, titulo CLIPPED,
		ASCII escape, ASCII act_dob1, ASCII des_dob,
		ASCII escape, ASCII act_12cpi
	SKIP 1 LINES
	CALL fl_justifica_titulo('D', 'USUARIO: ' || vg_usuario, 19)
		RETURNING usuario
	CALL fl_lee_compania(vg_codcia) RETURNING r_g01.*
	CALL fl_lee_modulo(vg_modulo) RETURNING r_g50.*
	LET modulo      = 'MODULO: ', r_g50.g50_nombre[1, 19] CLIPPED
	PRINT COLUMN 001, r_g01.g01_razonsocial CLIPPED,
	      COLUMN 089, 'PAG. ', PAGENO USING "&&&"
	PRINT COLUMN 001, modulo CLIPPED,
	      COLUMN 090, UPSHIFT(vg_proceso) CLIPPED
	SKIP 1 LINES
	IF rm_par.cod_trab IS NOT NULL THEN
		PRINT COLUMN 028, '** DEPARTAMENTO : ',
			rm_par.cod_depto USING "<<<&&&", ' ',
			rm_par.nom_depto CLIPPED
	END IF
	IF rm_par.cod_trab IS NOT NULL THEN
		PRINT COLUMN 028, '** EMPLEADO     : ',
			rm_par.cod_trab USING "<<<&&&", ' ',
			rm_par.nom_trab CLIPPED
	END IF
	PRINT COLUMN 028, '** ESTADO       : ', rm_par.estado, ' ',
		retorna_estado(rm_par.estado) CLIPPED
	PRINT COLUMN 028, '** TIPO FECHA   : ', rm_par.tipo_fecha, ' ',
		retorna_tipo_fec(rm_par.tipo_fecha) CLIPPED
	IF rm_par.todas_vac = 'N' THEN
		PRINT COLUMN 028, '** TIPO VACACION: ', rm_par.tipo_vac, ' ',
			retorna_tipo(rm_par.tipo_vac) CLIPPED
	ELSE
		PRINT COLUMN 028, '** TIPO VACACION: T O D A S'
	END IF
	PRINT COLUMN 028, '** PERIODO      : ',
		rm_par.fecha_ini USING "dd-mm-yyyy", '  -  ',
		rm_par.fecha_fin USING "dd-mm-yyyy"
	SKIP 1 LINES
	PRINT COLUMN 001, 'FECHA IMPRESION  : ', DATE(TODAY) USING "dd-mm-yyyy",
		1 SPACES, TIME,
	      COLUMN 078, usuario
	PRINT COLUMN 001, '------------------------------------------------------------------------------------------------'
	PRINT COLUMN 001, 'COD.',
	      COLUMN 017, 'E M P L E A D O S',
	      COLUMN 045, 'ANIO',
	      COLUMN 050, 'D.V.',
	      COLUMN 055, 'D.A.',
	      COLUMN 060, 'T.D.',
	      COLUMN 065, 'D.G.',
	      COLUMN 070, ' TOTAL GANADO',
	      COLUMN 084, '   VALOR VAC.'
	PRINT COLUMN 001, '------------------------------------------------------------------------------------------------'

ON EVERY ROW
	NEED 3 LINES
	PRINT COLUMN 001, rm_detalle[i].n39_cod_trab	USING "<<&&&",
	      COLUMN 007, rm_detalle[i].n30_nombres[1, 37] CLIPPED,
	      COLUMN 045, rm_detalle[i].anio_v		USING "&&&&",
	      COLUMN 050, rm_detalle[i].n39_dias_vac	USING "####",
	      COLUMN 055, rm_detalle[i].n39_dias_adi	USING "####",
	      COLUMN 060, rm_detalle[i].tot_dias	USING "####",
	      COLUMN 065, rm_detalle[i].n39_dias_goza	USING "####",
	      COLUMN 070, rm_detalle[i].n39_tot_ganado	USING "--,---,--&.##",
	      COLUMN 084, rm_detalle[i].n39_neto	USING "--,---,--&.##"

ON LAST ROW
	NEED 2 LINES
	PRINT COLUMN 050, '----',
	      COLUMN 055, '----',
	      COLUMN 060, '----';
	IF rm_totales.tot_dias_goza <> 0 THEN
		PRINT COLUMN 065, '----';
	ELSE
		PRINT COLUMN 065, '    ';
	END IF
	PRINT COLUMN 070, '-------------',
	      COLUMN 084, '-------------'
	PRINT COLUMN 037, 'TOTALES ==>',
	      COLUMN 050, SUM(rm_detalle[i].n39_dias_vac)	USING "####",
	      COLUMN 055, SUM(rm_detalle[i].n39_dias_adi)	USING "####",
	      COLUMN 060, SUM(rm_detalle[i].tot_dias)		USING "####",
	      COLUMN 065, SUM(rm_detalle[i].n39_dias_goza)	USING "####",
	      COLUMN 070, SUM(rm_detalle[i].n39_tot_ganado)
							USING "--,---,--&.##",
	      COLUMN 084, SUM(rm_detalle[i].n39_neto)	USING "--,---,--&.##";
	print ASCII escape;
	print ASCII act_10cpi

END REPORT



FUNCTION retorna_estado(estado)
DEFINE estado		LIKE rolt039.n39_estado
DEFINE nom_estado	VARCHAR(15)

CASE estado
	WHEN 'A' LET nom_estado = 'ACTIVAS'
	WHEN 'P' LET nom_estado = 'PROCESADAS'
END CASE
RETURN nom_estado

END FUNCTION



FUNCTION retorna_tipo_fec(tipo_fec)
DEFINE tipo_fec		CHAR(1)
DEFINE nom_tipo_fec	VARCHAR(15)

CASE tipo_fec
	WHEN 'V' LET nom_tipo_fec = 'VACACION'
	WHEN 'C' LET nom_tipo_fec = 'PROCESO'
END CASE
RETURN nom_tipo_fec

END FUNCTION



FUNCTION retorna_tipo(tipo_vac)
DEFINE tipo_vac		CHAR(1)
DEFINE nom_tipo_vac	VARCHAR(15)

CASE tipo_vac
	WHEN 'G' LET nom_tipo_vac = 'GOZADAS'
	WHEN 'P' LET nom_tipo_vac = 'PAGADAS'
END CASE
RETURN nom_tipo_vac

END FUNCTION
