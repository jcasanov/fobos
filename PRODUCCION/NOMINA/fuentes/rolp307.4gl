--------------------------------------------------------------------------------
-- Titulo           : rolp307.4gl - Totales Nomina por Empleado
-- Elaboracion      : 02-Mar-2010
-- Autor            : NPC
-- Formato Ejecucion: fglrun rolp307 base modulo compania
-- Ultima Correccion: 
-- Motivo Correccion: 
--------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE rm_par		RECORD
				cod_depto	LIKE gent034.g34_cod_depto,
				g34_nombre	LIKE gent034.g34_nombre,
				fecha_ini	LIKE rolt032.n32_fecha_ini,
				fecha_fin	LIKE rolt032.n32_fecha_fin
			END RECORD
DEFINE rm_detalle	ARRAY[1000] OF RECORD
				n32_cod_trab	LIKE rolt032.n32_cod_trab,
				n30_nombres	LIKE rolt030.n30_nombres,
				val1		DECIMAL(14,2),
				val2		DECIMAL(14,2),
				val3		DECIMAL(14,2),
				n30_estado	LIKE rolt030.n30_estado
			END RECORD
DEFINE rm_meses		ARRAY[1000] OF RECORD
				anio		SMALLINT,
				mes		VARCHAR(10),
				val1		DECIMAL(14,2),
				val2		DECIMAL(14,2),
				val3		DECIMAL(14,2)
			END RECORD
DEFINE rm_g01		RECORD LIKE gent001.*
DEFINE rm_g02		RECORD LIKE gent002.*
DEFINE vm_fec_ini	LIKE rolt032.n32_fecha_ini
DEFINE vm_fec_fin	LIKE rolt032.n32_fecha_fin
DEFINE vm_num_det	SMALLINT
DEFINE vm_max_det	SMALLINT
DEFINE vm_num_mes	SMALLINT
DEFINE vm_max_mes	SMALLINT
DEFINE rm_orden 	ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1	SMALLINT
DEFINE vm_columna_2	SMALLINT
DEFINE vm_totales	SMALLINT



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/rolp307.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 3 THEN  -- Validar # parámetros correcto
	CALL fl_mostrar_mensaje('Número de paráametros incorrecto.','stop')
	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_proceso = 'rolp307'
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
CALL fl_lee_compania(vg_codcia) RETURNING rm_g01.*
IF rm_g01.g01_compania IS NULL THEN
	CALL fl_mostrar_mensaje('No existe compañía.','stop')
	EXIT PROGRAM
END IF
CALL fl_lee_localidad(vg_codcia, vg_codloc) RETURNING rm_g02.*
IF rm_g02.g02_compania IS NULL THEN
	CALL fl_mostrar_mensaje('No existe localidad.','stop')
	EXIT PROGRAM
END IF
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
OPEN WINDOW w_rolf307_1 AT row_ini, 2 WITH num_rows ROWS, num_cols COLUMNS
	ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE lin_menu,
		  MESSAGE LINE LAST, BORDER) 
IF vg_gui = 1 THEN
	OPEN FORM f_rolf307_1 FROM '../forms/rolf307_1'
ELSE
	OPEN FORM f_rolf307_1 FROM '../forms/rolf307_1c'
END IF
DISPLAY FORM f_rolf307_1
LET vm_totales = 1
CALL botones_pantalla(1)
INITIALIZE rm_par.* TO NULL
LET vm_max_det = 1000
LET vm_max_mes = 1000
LET vm_fec_ini = TODAY
LET vm_fec_fin = TODAY
SELECT NVL(MIN(n32_fecha_ini), TODAY)
	INTO vm_fec_ini
	FROM rolt032
	WHERE n32_compania    = vg_codcia
	  AND n32_cod_liqrol IN ("Q1", "Q2")
	  AND n32_estado     <> 'E'
SELECT NVL(MAX(n32_fecha_fin), TODAY)
	INTO vm_fec_fin
	FROM rolt032
	WHERE n32_compania    = vg_codcia
	  AND n32_cod_liqrol IN ("Q1", "Q2")
	  AND n32_estado     <> 'E'
LET rm_par.fecha_fin = vm_fec_fin
LET rm_par.fecha_ini = MDY(MONTH(vm_fec_fin), 01, YEAR(vm_fec_fin))
WHILE TRUE
	CALL borrar_detalle()
	CALL lee_parametros()
	IF int_flag THEN
		EXIT WHILE
	END IF
	CALL control_consulta()
END WHILE
LET int_flag = 0
CLOSE WINDOW w_rolf307_1
EXIT PROGRAM

END FUNCTION



FUNCTION botones_pantalla(flag)
DEFINE flag		SMALLINT

CASE flag
	WHEN 1
		DISPLAY 'Cod.'			TO tit_col1
		DISPLAY 'E m p l e a d o s'	TO tit_col2
	WHEN 2
		DISPLAY 'Anio'			TO tit_col1
		DISPLAY 'Meses'			TO tit_col2
END CASE
CASE vm_totales
	WHEN 1 
		DISPLAY 'Sueldo'		TO tit_col3
		DISPLAY 'Valor Extra'		TO tit_col4
		DISPLAY 'Total Ganado'		TO tit_col5
	WHEN 2 
		DISPLAY 'Ap. Personal'		TO tit_col3
		DISPLAY 'Ap. Patronal'		TO tit_col4
		DISPLAY 'Ap. IESS'		TO tit_col5
	WHEN 3 
		DISPLAY 'Total Ing.'		TO tit_col3
		DISPLAY 'Total Egr.'		TO tit_col4
		DISPLAY 'Total Neto'		TO tit_col5
END CASE
IF flag = 1 THEN
	DISPLAY 'E'			TO tit_col6
END IF

END FUNCTION



FUNCTION borrar_detalle()
DEFINE i		SMALLINT

FOR i = 1 TO vm_max_det
	INITIALIZE rm_detalle[i].* TO NULL
END FOR
FOR i = 1 TO fgl_scr_size('rm_detalle')
	CLEAR rm_detalle[i].*
END FOR
CLEAR num_row, max_row, tot_val1, tot_val2, tot_val3, empleado

END FUNCTION



FUNCTION lee_parametros()
DEFINE r_g34		RECORD LIKE gent034.*
DEFINE fec_ini		LIKE rolt032.n32_fecha_ini
DEFINE fec_fin		LIKE rolt032.n32_fecha_fin

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
				LET rm_par.cod_depto  = r_g34.g34_cod_depto
				LET rm_par.g34_nombre = r_g34.g34_nombre
				DISPLAY BY NAME rm_par.cod_depto,
						rm_par.g34_nombre
			END IF
		END IF
		LET int_flag = 0
	BEFORE FIELD fecha_ini
		LET fec_ini = rm_par.fecha_ini
	BEFORE FIELD fecha_fin
		LET fec_fin = rm_par.fecha_fin
	AFTER FIELD fecha_ini
		IF rm_par.fecha_ini IS NULL THEN
			LET rm_par.fecha_ini = fec_ini
			DISPLAY BY NAME rm_par.fecha_ini
		END IF
		IF rm_par.fecha_ini < vm_fec_ini THEN
			CALL fl_mostrar_mensaje('La fecha inicial no puede ser menor que la fecha inicial de los roles.', 'exclamation')
			NEXT FIELD fecha_ini
		END IF
	AFTER FIELD fecha_fin
		IF rm_par.fecha_fin IS NULL THEN
			LET rm_par.fecha_fin = fec_fin
			DISPLAY BY NAME rm_par.fecha_fin
		END IF
		IF rm_par.fecha_fin > vm_fec_fin THEN
			CALL fl_mostrar_mensaje('La fecha final no puede ser mayor que la fecha final de los roles.', 'exclamation')
			NEXT FIELD fecha_fin
		END IF
	AFTER FIELD cod_depto
		IF rm_par.cod_depto IS NOT NULL THEN
			CALL fl_lee_departamento(vg_codcia, rm_par.cod_depto)
				RETURNING r_g34.*
			IF r_g34.g34_compania IS NULL THEN
				CALL fl_mostrar_mensaje('Departamento no existe.','exclamation')
				NEXT FIELD cod_depto
			END IF
			LET rm_par.g34_nombre = r_g34.g34_nombre
		ELSE
			LET rm_par.g34_nombre = NULL
		END IF
		DISPLAY BY NAME rm_par.g34_nombre
	AFTER INPUT
		IF rm_par.fecha_ini > rm_par.fecha_fin THEN
			CALL fl_mostrar_mensaje('La fecha inicial no puede ser mayor que la fecha inicial.', 'exclamation')
			CONTINUE INPUT
		END IF
END INPUT

END FUNCTION



FUNCTION control_consulta()
DEFINE col, i		SMALLINT

IF NOT generar_temporal() THEN
	RETURN
END IF
FOR i = 1 TO 10
	LET rm_orden[i] = '' 
END FOR
LET col           = 2
LET vm_columna_1  = col
LET vm_columna_2  = 6
LET rm_orden[col] = 'ASC'
WHILE TRUE
	CALL botones_pantalla(1)
	CALL cargar_detalle()
	IF mostrar_detalle() THEN
		EXIT WHILE
	END IF
END WHILE
DROP TABLE tmp_emp

END FUNCTION



FUNCTION generar_temporal()
DEFINE query		CHAR(7000)
DEFINE expr_dep		VARCHAR(100)

LET expr_dep = NULL
IF rm_par.cod_depto IS NOT NULL THEN
	LET expr_dep = '   AND a.n32_cod_depto   = ', rm_par.cod_depto
END IF
SELECT * FROM rolt033
	WHERE n33_compania    = vg_codcia
	  AND n33_cod_liqrol IN ("Q1", "Q2")
	  AND n33_fecha_ini  >= rm_par.fecha_ini
	  AND n33_fecha_fin  <= rm_par.fecha_fin
	  AND n33_cant_valor  = "V"
	  AND n33_valor       > 0
	INTO TEMP tmp_n33
LET query = 'SELECT a.n32_ano_proceso AS anio, a.n32_mes_proceso AS mes, ',
		'n30_cod_trab, n30_nombres, ',
		'CASE WHEN NVL(SUM((SELECT SUM(n33_valor) ',
			'FROM tmp_n33 ',
			'WHERE n33_compania   = a.n32_compania ',
			'  AND n33_fecha_ini  = a.n32_fecha_ini ',
			'  AND n33_fecha_fin  = a.n32_fecha_fin ',
			'  AND n33_cod_trab   = a.n32_cod_trab ',
			'  AND n33_cod_rubro IN ',
				'(SELECT n06_cod_rubro ',
				'FROM rolt006 ',
				'WHERE n06_flag_ident IN ("VT", "VV", "OV", ',
						'"VE", "SX", "SY")))), 0) >= ',
			'NVL(SUM(a.n32_sueldo / ',
			'(SELECT COUNT(*) ',
				'FROM rolt032 b ',
				'WHERE b.n32_compania    = a.n32_compania ',
				'  AND b.n32_ano_proceso = a.n32_ano_proceso ',
				'  AND b.n32_mes_proceso = a.n32_mes_proceso ',
				'  AND b.n32_cod_trab    = a.n32_cod_trab)),0)',
		' THEN ',
			'NVL(SUM(a.n32_sueldo / ',
			'(SELECT COUNT(*) ',
				'FROM rolt032 b ',
				'WHERE b.n32_compania    = a.n32_compania ',
				'  AND b.n32_ano_proceso = a.n32_ano_proceso ',
				'  AND b.n32_mes_proceso = a.n32_mes_proceso ',
				'  AND b.n32_cod_trab    = a.n32_cod_trab)), ',
			'0)',
		' ELSE ',
			'NVL(SUM((SELECT SUM(n33_valor) ',
				'FROM tmp_n33 ',
				'WHERE n33_compania   = a.n32_compania ',
				'  AND n33_fecha_ini  = a.n32_fecha_ini ',
				'  AND n33_fecha_fin  = a.n32_fecha_fin ',
				'  AND n33_cod_trab   = a.n32_cod_trab ',
				'  AND n33_cod_rubro IN ',
					'(SELECT n06_cod_rubro ',
					'FROM rolt006 ',
					'WHERE n06_flag_ident IN ("VT", "VV", ',
						'"OV", "VE", "SX", "SY")))), 0)',
		' END AS val1, ',
		'(SUM(NVL((SELECT SUM(n33_valor) ',
			'FROM tmp_n33 ',
		  	'WHERE n33_compania    = a.n32_compania ',
			'  AND n33_cod_liqrol  = a.n32_cod_liqrol ',
			'  AND n33_fecha_ini   = a.n32_fecha_ini ',
			'  AND n33_fecha_fin   = a.n32_fecha_fin ',
			'  AND n33_cod_trab    = a.n32_cod_trab ',
			'  AND n33_cod_rubro  IN ',
				'(SELECT n08_rubro_base ',
				'FROM rolt008 ',
				'WHERE n08_cod_rubro = ',
					'(SELECT n06_cod_rubro ',
					'FROM rolt006 ',
					'WHERE n06_flag_ident = "AP"))), 0)) ',
		'- ',
		'CASE WHEN NVL(SUM((SELECT SUM(n33_valor) ',
			'FROM tmp_n33 ',
			'WHERE n33_compania   = a.n32_compania ',
			'  AND n33_fecha_ini  = a.n32_fecha_ini ',
			'  AND n33_fecha_fin  = a.n32_fecha_fin ',
			'  AND n33_cod_trab   = a.n32_cod_trab ',
			'  AND n33_cod_rubro IN ',
				'(SELECT n06_cod_rubro ',
				'FROM rolt006 ',
				'WHERE n06_flag_ident IN ("VT", "VV", "OV", ',
						'"VE", "SX", "SY")))), 0) >= ',
			'NVL(SUM(a.n32_sueldo / ',
			'(SELECT COUNT(*) ',
				'FROM rolt032 b ',
				'WHERE b.n32_compania    = a.n32_compania ',
				'  AND b.n32_ano_proceso = a.n32_ano_proceso ',
				'  AND b.n32_mes_proceso = a.n32_mes_proceso ',
				'  AND b.n32_cod_trab    = a.n32_cod_trab)),0)',
		' THEN ',
			'NVL(SUM(a.n32_sueldo / ',
			'(SELECT COUNT(*) ',
				'FROM rolt032 b ',
				'WHERE b.n32_compania    = a.n32_compania ',
				'  AND b.n32_ano_proceso = a.n32_ano_proceso ',
				'  AND b.n32_mes_proceso = a.n32_mes_proceso ',
				'  AND b.n32_cod_trab    = a.n32_cod_trab)), ',
			'0)',
		' ELSE ',
			'NVL(SUM((SELECT SUM(n33_valor) ',
				'FROM tmp_n33 ',
				'WHERE n33_compania   = a.n32_compania ',
				'  AND n33_fecha_ini  = a.n32_fecha_ini ',
				'  AND n33_fecha_fin  = a.n32_fecha_fin ',
				'  AND n33_cod_trab   = a.n32_cod_trab ',
				'  AND n33_cod_rubro IN ',
					'(SELECT n06_cod_rubro ',
					'FROM rolt006 ',
					'WHERE n06_flag_ident IN ("VT", "VV", ',
						'"OV", "VE", "SX", "SY")))), 0)',
		' END) AS val2, ',
		'SUM(NVL((SELECT SUM(n33_valor) ',
			'FROM tmp_n33 ',
		  	'WHERE n33_compania    = a.n32_compania ',
			'  AND n33_cod_liqrol  = a.n32_cod_liqrol ',
			'  AND n33_fecha_ini   = a.n32_fecha_ini ',
			'  AND n33_fecha_fin   = a.n32_fecha_fin ',
			'  AND n33_cod_trab    = a.n32_cod_trab ',
			'  AND n33_cod_rubro  IN ',
				'(SELECT n08_rubro_base ',
				'FROM rolt008 ',
				'WHERE n08_cod_rubro = ',
					'(SELECT n06_cod_rubro ',
					'FROM rolt006 ',
					'WHERE n06_flag_ident = "AP"))), 0)) ',
		'AS val3, ',
		'n30_estado, ',
		'SUM(NVL((SELECT SUM(n33_valor) ',
			'FROM tmp_n33 ',
		  	'WHERE n33_compania    = a.n32_compania ',
			'  AND n33_cod_liqrol  = a.n32_cod_liqrol ',
			'  AND n33_fecha_ini   = a.n32_fecha_ini ',
			'  AND n33_fecha_fin   = a.n32_fecha_fin ',
			'  AND n33_cod_trab    = a.n32_cod_trab ',
			'  AND n33_cod_rubro  IN ',
					'(SELECT n06_cod_rubro ',
					'FROM rolt006 ',
					'WHERE n06_flag_ident = "AP") ',
			'  AND n33_det_tot     = "DE"), 0)) ',
		'AS val4, ',
		'SUM(NVL((SELECT SUM(n33_valor) ',
			'FROM tmp_n33 ',
		  	'WHERE n33_compania    = a.n32_compania ',
			'  AND n33_cod_liqrol  = a.n32_cod_liqrol ',
			'  AND n33_fecha_ini   = a.n32_fecha_ini ',
			'  AND n33_fecha_fin   = a.n32_fecha_fin ',
			'  AND n33_cod_trab    = a.n32_cod_trab ',
			'  AND n33_cod_rubro  IN ',
				'(SELECT n08_rubro_base ',
				'FROM rolt008 ',
				'WHERE n08_cod_rubro = ',
					'(SELECT n06_cod_rubro ',
					'FROM rolt006 ',
					'WHERE n06_flag_ident = "AP"))), 0) ',
			' * (SELECT n13_porc_cia / 100 ',
				'FROM rolt013 ',
				'WHERE n13_cod_seguro = n30_cod_seguro)) ',
		'AS val5, ',
		'(SUM(NVL((SELECT SUM(n33_valor) ',
			'FROM tmp_n33 ',
		  	'WHERE n33_compania    = a.n32_compania ',
			'  AND n33_cod_liqrol  = a.n32_cod_liqrol ',
			'  AND n33_fecha_ini   = a.n32_fecha_ini ',
			'  AND n33_fecha_fin   = a.n32_fecha_fin ',
			'  AND n33_cod_trab    = a.n32_cod_trab ',
			'  AND n33_cod_rubro  IN ',
					'(SELECT n06_cod_rubro ',
					'FROM rolt006 ',
					'WHERE n06_flag_ident = "AP") ',
			'  AND n33_det_tot     = "DE"), 0)) ',
		'+ ',
		'SUM(NVL((SELECT SUM(n33_valor) ',
			'FROM tmp_n33 ',
		  	'WHERE n33_compania    = a.n32_compania ',
			'  AND n33_cod_liqrol  = a.n32_cod_liqrol ',
			'  AND n33_fecha_ini   = a.n32_fecha_ini ',
			'  AND n33_fecha_fin   = a.n32_fecha_fin ',
			'  AND n33_cod_trab    = a.n32_cod_trab ',
			'  AND n33_cod_rubro  IN ',
				'(SELECT n08_rubro_base ',
				'FROM rolt008 ',
				'WHERE n08_cod_rubro = ',
					'(SELECT n06_cod_rubro ',
					'FROM rolt006 ',
					'WHERE n06_flag_ident = "AP"))), 0) ',
			' * (SELECT n13_porc_cia / 100 ',
				'FROM rolt013 ',
				'WHERE n13_cod_seguro = n30_cod_seguro))) ',
		'AS val6, ',
		'NVL(SUM(n32_tot_ing), 0) val7, ',
		'NVL(SUM(n32_tot_egr), 0) val8, ',
		'NVL(SUM(n32_tot_neto), 0) val9 ',
		' FROM rolt032 a, rolt030 ',
		' WHERE a.n32_compania    = ', vg_codcia,
		'   AND a.n32_cod_liqrol IN ("Q1", "Q2") ',
		'   AND a.n32_fecha_ini  >= "', rm_par.fecha_ini, '"',
		'   AND a.n32_fecha_fin  <= "', rm_par.fecha_fin, '"',
		expr_dep CLIPPED,
		'   AND a.n32_estado     <> "E" ',
		'   AND n30_compania      = a.n32_compania ',
		'   AND n30_cod_trab      = a.n32_cod_trab ',
		' GROUP BY 1, 2, 3, 4, 8 ',
		' INTO TEMP tmp_emp'
PREPARE cons_emp FROM query
EXECUTE cons_emp
DROP TABLE tmp_n33
SELECT COUNT(UNIQUE n30_cod_trab) INTO vm_num_det FROM tmp_emp
IF vm_num_det = 0 THEN
	CALL fl_mensaje_consulta_sin_registros()
	DROP TABLE tmp_emp
	RETURN 0
END IF
RETURN 1

END FUNCTION



FUNCTION cargar_detalle()
DEFINE query		CHAR(300)
DEFINE cols		VARCHAR(40)
DEFINE i		SMALLINT

CASE vm_totales
	WHEN 1 LET cols = 'SUM(val1), SUM(val2), SUM(val3),'
	WHEN 2 LET cols = 'SUM(val4), SUM(val5), SUM(val6),'
	WHEN 3 LET cols = 'SUM(val7), SUM(val8), SUM(val9),'
END CASE
LET query = 'SELECT n30_cod_trab, n30_nombres, ', cols CLIPPED, ' n30_estado ',
		' FROM tmp_emp ',
		' GROUP BY 1, 2, 6 ',
		' ORDER BY ', vm_columna_1, ' ', rm_orden[vm_columna_1], ', ',
			      vm_columna_2, ' ', rm_orden[vm_columna_2]
PREPARE tmp FROM query	
DECLARE q_tmp CURSOR FOR tmp
LET i = 1
FOREACH q_tmp INTO rm_detalle[i].*
	LET i = i + 1
        IF i > vm_max_det THEN
                EXIT FOREACH
        END IF
END FOREACH
LET i = i - 1

END FUNCTION



FUNCTION mostrar_detalle()
DEFINE i, j, col	SMALLINT
DEFINE salir		SMALLINT

CALL mostrar_totales()
LET salir    = 0
LET int_flag = 0
CALL set_count(vm_num_det)
DISPLAY ARRAY rm_detalle TO rm_detalle.*
	ON KEY(INTERRUPT)
		LET int_flag = 1
		LET salir    = 1
		EXIT DISPLAY
	ON KEY(F5)
		LET i = arr_curr()
		CALL mostrar_empleado(rm_detalle[i].n32_cod_trab)
		LET int_flag = 0
	ON KEY(F6)
		CASE vm_totales
			WHEN 1 LET vm_totales = 2
			WHEN 2 LET vm_totales = 3
			WHEN 3 LET vm_totales = 1
		END CASE
		LET salir = 1
		EXIT DISPLAY
	ON KEY(F7)
		LET i = arr_curr()
		CALL detalle_tot_gan(rm_detalle[i].n32_cod_trab)
		LET int_flag = 0
	ON KEY(F8)
		LET i = arr_curr()
		CALL total_ganado(rm_detalle[i].n32_cod_trab, 0, 0, 'TM')
		LET int_flag = 0
	ON KEY(F9)
		LET i = arr_curr()
		CALL total_ganado(0, 0, 0, 'TT')
		LET int_flag = 0
	ON KEY(F10)
		LET i = arr_curr()
		CALL planilla_iess()
		LET int_flag = 0
	ON KEY(F11)
		LET i = arr_curr()
		CALL imprimir_listado_emp()
		LET int_flag = 0
	ON KEY(F15)
		LET col      = 1
		LET int_flag = 2
		EXIT DISPLAY
	ON KEY(F16)
		LET col      = 2
		LET int_flag = 2
		EXIT DISPLAY
	ON KEY(F17)
		LET col      = 3
		LET int_flag = 2
		EXIT DISPLAY
	ON KEY(F18)
		LET col      = 4
		LET int_flag = 2
		EXIT DISPLAY
	ON KEY(F19)
		LET col      = 5
		LET int_flag = 2
		EXIT DISPLAY
	ON KEY(F20)
		LET col      = 6
		LET int_flag = 2
		EXIT DISPLAY
	--#BEFORE DISPLAY
		--#CALL dialog.keysetlabel('ACCEPT', '')
		--#CALL dialog.keysetlabel('RETURN', '')
	--#BEFORE ROW
		--#LET i = arr_curr()
		--#LET j = scr_line()
		--#CASE vm_totales
			--#WHEN 1
				--#CALL dialog.keysetlabel('F6', 'Aportes')
				--#CALL dialog.keysetlabel('F7', 'Detalle Tot. Gan.')
			--#WHEN 2
				--#CALL dialog.keysetlabel('F6', 'Totales')
				--#CALL dialog.keysetlabel('F7', 'Detalle Ap.')
			--#WHEN 3
				--#CALL dialog.keysetlabel('F6', 'Valores Gan.')
				--#CALL dialog.keysetlabel('F7', 'Detalle Totales')
		--#END CASE
		--#CALL muestra_contadores_detalle(i, vm_num_det)
		--#DISPLAY rm_detalle[i].n30_nombres TO empleado
	--#AFTER DISPLAY
		--#CONTINUE DISPLAY
END DISPLAY
IF int_flag = 1 AND salir THEN
	RETURN salir
END IF
IF int_flag = 2 THEN
	IF col > 0 AND col <> vm_columna_1 THEN
		LET vm_columna_2           = vm_columna_1
		LET rm_orden[vm_columna_2] = rm_orden[vm_columna_1]
		LET vm_columna_1           = col
	END IF
	IF rm_orden[vm_columna_1] = 'ASC' THEN
		LET rm_orden[vm_columna_1] = 'DESC'
	ELSE
		LET rm_orden[vm_columna_1] = 'ASC'
	END IF
END IF
IF int_flag <> 1 THEN
	LET salir = 0
END IF
RETURN salir

END FUNCTION



FUNCTION muestra_contadores_detalle(num_row, max_row)
DEFINE num_row, max_row	SMALLINT

DISPLAY BY NAME num_row, max_row

END FUNCTION



FUNCTION mostrar_totales()
DEFINE tot_val1		DECIMAL(14,2)
DEFINE tot_val2		DECIMAL(14,2)
DEFINE tot_val3		DECIMAL(14,2)
DEFINE i		SMALLINT

LET tot_val1 = 0
LET tot_val2 = 0
LET tot_val3 = 0
FOR i = 1 TO vm_num_det
	LET tot_val1 = tot_val1 + rm_detalle[i].val1
	LET tot_val2 = tot_val2 + rm_detalle[i].val2
	LET tot_val3 = tot_val3 + rm_detalle[i].val3
END FOR
DISPLAY BY NAME tot_val1, tot_val2, tot_val3

END FUNCTION
 


FUNCTION mostrar_empleado(cod_trab)
DEFINE cod_trab		LIKE rolt030.n30_cod_trab
DEFINE param		VARCHAR(60)

LET param = ' ', cod_trab
CALL ejecuta_comando('NOMINA', vg_modulo, 'rolp108 ', param)

END FUNCTION
 


FUNCTION detalle_tot_gan(cod_trab)
DEFINE cod_trab		LIKE rolt030.n30_cod_trab
DEFINE r_det		RECORD
				anio		SMALLINT,
				mes		SMALLINT,
				val1		DECIMAL(14,2),
				val2		DECIMAL(14,2),
				val3		DECIMAL(14,2)
			END RECORD
DEFINE mes_a		ARRAY[1000] OF SMALLINT
DEFINE lin_menu		SMALLINT
DEFINE row_ini, i	SMALLINT
DEFINE num_rows		SMALLINT
DEFINE num_cols		SMALLINT
DEFINE tot_val1		DECIMAL(14,2)
DEFINE tot_val2		DECIMAL(14,2)
DEFINE tot_val3		DECIMAL(14,2)
DEFINE query		CHAR(300)
DEFINE cols		VARCHAR(40)
DEFINE r_n30		RECORD LIKE rolt030.*

LET lin_menu = 0
LET row_ini  = 05
LET num_rows = 19
LET num_cols = 61
IF vg_gui = 0 THEN
	LET lin_menu = 1
	LET row_ini  = 4
	LET num_rows = 20
	LET num_cols = 65
END IF
OPEN WINDOW w_rolf307_2 AT row_ini, 10 WITH num_rows ROWS, num_cols COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE lin_menu,
		  MESSAGE LINE LAST, BORDER) 
IF vg_gui = 1 THEN
	OPEN FORM f_rolf307_2 FROM '../forms/rolf307_2'
ELSE
	OPEN FORM f_rolf307_2 FROM '../forms/rolf307_2c'
END IF
DISPLAY FORM f_rolf307_2
CALL botones_pantalla(2)
CALL fl_lee_trabajador_roles(vg_codcia, cod_trab) RETURNING r_n30.*
DISPLAY BY NAME	cod_trab, rm_par.fecha_ini, rm_par.fecha_fin
DISPLAY r_n30.n30_nombres TO nom_trab
CASE vm_totales
	WHEN 1 LET cols = 'SUM(val1), SUM(val2), SUM(val3)'
	WHEN 2 LET cols = 'SUM(val4), SUM(val5), SUM(val6)'
	WHEN 3 LET cols = 'SUM(val7), SUM(val8), SUM(val9)'
END CASE
LET query = 'SELECT anio, mes, ', cols CLIPPED,
		' FROM tmp_emp ',
		' WHERE n30_cod_trab = ', cod_trab,
		' GROUP BY 1, 2 ',
		' ORDER BY 1, 2 '
PREPARE tmp2 FROM query	
DECLARE q_tmp2 CURSOR FOR tmp2
LET vm_num_mes = 1
FOREACH q_tmp2 INTO r_det.*
	LET rm_meses[vm_num_mes].anio = r_det.anio
	LET rm_meses[vm_num_mes].mes  = UPSHIFT(fl_justifica_titulo('I',
					fl_retorna_nombre_mes(r_det.mes), 10))
	LET rm_meses[vm_num_mes].val1 = r_det.val1
	LET rm_meses[vm_num_mes].val2 = r_det.val2
	LET rm_meses[vm_num_mes].val3 = r_det.val3
	LET mes_a[vm_num_mes]          = r_det.mes
	LET vm_num_mes = vm_num_mes + 1
        IF vm_num_mes > vm_max_mes THEN
                EXIT FOREACH
        END IF
END FOREACH
LET vm_num_mes = vm_num_mes - 1
CALL mostrar_totales()
LET tot_val1 = 0
LET tot_val2 = 0
LET tot_val3 = 0
FOR i = 1 TO vm_num_mes
	LET tot_val1 = tot_val1 + rm_meses[i].val1
	LET tot_val2 = tot_val2 + rm_meses[i].val2
	LET tot_val3 = tot_val3 + rm_meses[i].val3
END FOR
DISPLAY BY NAME tot_val1, tot_val2, tot_val3
LET int_flag = 0
CALL set_count(vm_num_mes)
DISPLAY ARRAY rm_meses TO rm_meses.*
	ON KEY(INTERRUPT)
		LET int_flag = 1
		EXIT DISPLAY
	ON KEY(F5)
		LET i = arr_curr()
		CALL mostrar_empleado(cod_trab)
		LET int_flag = 0
	ON KEY(F6)
		CALL total_ganado(cod_trab, 0, 0, 'TR')
		LET int_flag = 0
	ON KEY(F7)
		LET i = arr_curr()
		CALL total_ganado(cod_trab, rm_meses[i].anio, mes_a[i], 'RM')
		LET int_flag = 0
	ON KEY(F8)
		CALL imprimir_listado_mes(cod_trab)
		LET int_flag = 0
	--#BEFORE DISPLAY
		--#CALL dialog.keysetlabel('ACCEPT', '')
		--#CALL dialog.keysetlabel('RETURN', '')
	--#BEFORE ROW
		--#LET i = arr_curr()
		--#CALL muestra_contadores_detalle(i, vm_num_mes)
	--#AFTER DISPLAY
		--#CONTINUE DISPLAY
END DISPLAY
LET int_flag = 0
CLOSE WINDOW w_rolf307_2
RETURN

END FUNCTION



FUNCTION total_ganado(cod_trab, anio, mes, tipo)
DEFINE cod_trab		LIKE rolt030.n30_cod_trab
DEFINE anio, mes	SMALLINT
DEFINE tipo		CHAR(2)
DEFINE fec_ini, fec_fin	DATE
DEFINE param		VARCHAR(60)

LET fec_ini = rm_par.fecha_ini
LET fec_fin = rm_par.fecha_fin
IF anio > 0 THEN
	LET fec_ini = MDY(mes, 01, anio)
	LET fec_fin = fec_ini + 1 UNITS MONTH - 1 UNITS DAY
	IF fec_fin > rm_par.fecha_fin THEN
		LET fec_fin = rm_par.fecha_fin
	END IF
END IF
LET param = ' "', fec_ini, '" "', fec_fin, '"'
IF rm_par.cod_depto IS NOT NULL AND tipo = 'TT' THEN
	LET param = param CLIPPED, ' "D" ', rm_par.cod_depto
ELSE
	IF cod_trab = 0 THEN
		LET param = param CLIPPED, ' "X" 0 '
	ELSE
		LET param = param CLIPPED, ' "T" ', cod_trab
	END IF
END IF
LET param = param CLIPPED, ' "', tipo, '"'
CALL ejecuta_comando('NOMINA', vg_modulo, 'rolp302 ', param)

END FUNCTION
 


FUNCTION planilla_iess()
DEFINE cod_trab		LIKE rolt030.n30_cod_trab
DEFINE param		VARCHAR(60)

LET param = ' "', rm_par.fecha_ini, '" "', rm_par.fecha_fin, '" "N"'
CALL ejecuta_comando('NOMINA', vg_modulo, 'rolp408 ', param)

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



FUNCTION imprimir_listado_emp()
DEFINE comando		VARCHAR(100)
DEFINE i		SMALLINT

CALL fl_control_reportes() RETURNING comando
IF int_flag THEN
	RETURN
END IF
START REPORT report_empleados TO PIPE comando
FOR i = 1 TO vm_num_det
	OUTPUT TO REPORT report_empleados(i)
END FOR
FINISH REPORT report_empleados

END FUNCTION



REPORT report_empleados(i)
DEFINE i		SMALLINT
DEFINE r_g01		RECORD LIKE gent001.*
DEFINE r_g50		RECORD LIKE gent050.*
DEFINE r_g54		RECORD LIKE gent054.*
DEFINE usuario		VARCHAR(19,15)
DEFINE modulo		VARCHAR(40)
DEFINE escape		SMALLINT
DEFINE act_comp		SMALLINT
DEFINE desact_comp	SMALLINT
DEFINE act_10cpi	SMALLINT
DEFINE act_neg, des_neg	SMALLINT

OUTPUT
	TOP MARGIN	1
	LEFT MARGIN	0
	RIGHT MARGIN	80
	BOTTOM MARGIN	4
	PAGE LENGTH	66

FORMAT

PAGE HEADER
	LET escape	= 27		# Iniciar sec. impresión
	LET act_comp	= 15		# Activar Comprimido.
	LET desact_comp	= 18		# Cancelar Comprimido.
	LET act_neg	= 71		# Activar negrita.
	LET des_neg	= 72		# Desactivar negrita.
	LET act_10cpi	= 80		# Comprimido 10 CPI.
	CALL fl_lee_modulo(vg_modulo) RETURNING r_g50.*
	LET modulo      = "MODULO: ", r_g50.g50_nombre[1, 12] CLIPPED
	LET usuario     = "USUARIO: ", vg_usuario
	CALL fl_justifica_titulo('D', usuario, 19) RETURNING usuario
	CALL fl_lee_compania(vg_codcia) RETURNING r_g01.*
	CALL fl_lee_proceso(vg_modulo, vg_proceso) RETURNING r_g54.*
	print ASCII escape;
	print ASCII act_neg;
	print ASCII escape;
	print ASCII act_10cpi;
	PRINT COLUMN 005, r_g01.g01_razonsocial,
  	      COLUMN 074, "PAGINA: ", PAGENO USING "&&&"
	SKIP 1 LINES
	PRINT COLUMN 001, modulo CLIPPED,
	      COLUMN 026, r_g54.g54_nombre[1, 30] CLIPPED,
	      COLUMN 074, UPSHIFT(vg_proceso) CLIPPED
	SKIP 1 LINES
	IF rm_par.cod_depto IS NOT NULL THEN
		PRINT COLUMN 016, "** DEPTO. ACTUAL: ",
			rm_par.cod_depto USING "<<&&", ' ', 
			rm_par.g34_nombre CLIPPED
	END IF
	PRINT COLUMN 016, "** PERIODO      : ",
		rm_par.fecha_ini USING "dd-mm-yyyy", '  -  ',
		rm_par.fecha_fin USING "dd-mm-yyyy"
	SKIP 1 LINES
	PRINT COLUMN 001, "FECHA IMPRESION: ", TODAY USING "dd-mm-yyyy",
 		1 SPACES, TIME,
	      COLUMN 062, usuario
	PRINT "--------------------------------------------------------------------------------"
	PRINT COLUMN 001, "CODIG",
	      COLUMN 012, "E M P L E A D O S";
	IF vm_totales = 1 THEN
		PRINT COLUMN 038, '       SUELDO',
		      COLUMN 052, '  VALOR EXTRA',
		      COLUMN 066, ' TOTAL GANADO';
	ELSE
		IF vm_totales = 2 THEN
			PRINT COLUMN 038, ' AP. PERSONAL',
			      COLUMN 052, ' AP. PATRONAL',
			      COLUMN 066, '  APORTE IESS';
		ELSE
			PRINT COLUMN 038, 'TOTAL INGRESO',
			      COLUMN 052, ' TOTAL EGRESO',
			      COLUMN 066, '   TOTAL NETO';
		END IF
	END IF
	PRINT COLUMN 080, "E"
	PRINT "--------------------------------------------------------------------------------";
	print ASCII escape;
	print ASCII des_neg

ON EVERY ROW
	NEED 3 LINES
	PRINT COLUMN 001, rm_detalle[i].n32_cod_trab		USING "##&&&",
	      COLUMN 007, rm_detalle[i].n30_nombres[1, 30]	CLIPPED,
	      COLUMN 038, rm_detalle[i].val1		USING "##,###,##&.##",
	      COLUMN 052, rm_detalle[i].val2		USING "##,###,##&.##",
	      COLUMN 066, rm_detalle[i].val3		USING "##,###,##&.##",
	      COLUMN 080, rm_detalle[i].n30_estado		CLIPPED
	
ON LAST ROW
	NEED 2 LINES
	print ASCII escape;
	print ASCII act_neg;
	PRINT COLUMN 040, "-------------",
	      COLUMN 054, "-------------",
	      COLUMN 068, "-------------"
	PRINT COLUMN 001, "No. EMPLEADOS ", vm_num_det USING "<<<&",
	      COLUMN 026, "TOTALES ==> ",
	      COLUMN 038, SUM(rm_detalle[i].val1)	USING "##,###,##&.##",
	      COLUMN 052, SUM(rm_detalle[i].val2)	USING "##,###,##&.##",
	      COLUMN 066, SUM(rm_detalle[i].val3)	USING "##,###,##&.##";
	print ASCII escape;
	print ASCII des_neg

END REPORT



FUNCTION imprimir_listado_mes(cod_trab)
DEFINE cod_trab		LIKE rolt030.n30_cod_trab
DEFINE comando		VARCHAR(100)
DEFINE i		SMALLINT

CALL fl_control_reportes() RETURNING comando
IF int_flag THEN
	RETURN
END IF
START REPORT report_mes TO PIPE comando
FOR i = 1 TO vm_num_mes
	OUTPUT TO REPORT report_mes(cod_trab, i)
END FOR
FINISH REPORT report_mes

END FUNCTION



REPORT report_mes(cod_trab, i)
DEFINE cod_trab		LIKE rolt030.n30_cod_trab
DEFINE i		SMALLINT
DEFINE r_g01		RECORD LIKE gent001.*
DEFINE r_g50		RECORD LIKE gent050.*
DEFINE r_g54		RECORD LIKE gent054.*
DEFINE r_n30		RECORD LIKE rolt030.*
DEFINE usuario		VARCHAR(19,15)
DEFINE modulo		VARCHAR(40)
DEFINE escape		SMALLINT
DEFINE act_comp		SMALLINT
DEFINE desact_comp	SMALLINT
DEFINE act_10cpi	SMALLINT
DEFINE act_neg, des_neg	SMALLINT

OUTPUT
	TOP MARGIN	1
	LEFT MARGIN	0
	RIGHT MARGIN	80
	BOTTOM MARGIN	4
	PAGE LENGTH	66

FORMAT

PAGE HEADER
	LET escape	= 27		# Iniciar sec. impresión
	LET act_comp	= 15		# Activar Comprimido.
	LET desact_comp	= 18		# Cancelar Comprimido.
	LET act_neg	= 71		# Activar negrita.
	LET des_neg	= 72		# Desactivar negrita.
	LET act_10cpi	= 80		# Comprimido 10 CPI.
	CALL fl_lee_modulo(vg_modulo) RETURNING r_g50.*
	LET modulo      = r_g50.g50_nombre[1, 12] CLIPPED
	LET usuario     = "USUARIO: ", vg_usuario
	CALL fl_justifica_titulo('D', usuario, 19) RETURNING usuario
	CALL fl_lee_compania(vg_codcia) RETURNING r_g01.*
	CALL fl_lee_proceso(vg_modulo, vg_proceso) RETURNING r_g54.*
	CALL fl_lee_trabajador_roles(vg_codcia, cod_trab) RETURNING r_n30.*
	print ASCII escape;
	print ASCII act_neg;
	print ASCII escape;
	print ASCII act_10cpi;
	PRINT COLUMN 005, r_g01.g01_razonsocial,
  	      COLUMN 055, "PAGINA: ", PAGENO USING "&&&"
	SKIP 1 LINES
	PRINT COLUMN 001, modulo CLIPPED,
	      COLUMN 014, r_g54.g54_nombre[1, 27] CLIPPED, ' POR MES',
	      COLUMN 055, UPSHIFT(vg_proceso) CLIPPED
	SKIP 1 LINES
	IF rm_par.cod_depto IS NOT NULL THEN
		PRINT COLUMN 002, "** DEPTO. ACTUAL: ",
			rm_par.cod_depto USING "<<&&", ' ', 
			rm_par.g34_nombre CLIPPED
	END IF
	PRINT COLUMN 002, "** EMPLEADO     : ", cod_trab USING "##&&&", ' ',
		r_n30.n30_nombres[1, 35] CLIPPED
	PRINT COLUMN 002, "** PERIODO      : ",
		rm_par.fecha_ini USING "dd-mm-yyyy", '  -  ',
		rm_par.fecha_fin USING "dd-mm-yyyy"
	SKIP 1 LINES
	PRINT COLUMN 001, "FECHA IMPRESION: ", TODAY USING "dd-mm-yyyy",
 		1 SPACES, TIME,
	      COLUMN 043, usuario
	PRINT "-------------------------------------------------------------"
	PRINT COLUMN 001, "ANIO",
	      COLUMN 007, "M E S E S";
	IF vm_totales = 1 THEN
		PRINT COLUMN 019, '       SUELDO',
		      COLUMN 034, '  VALOR EXTRA',
		      COLUMN 049, ' TOTAL GANADO'
	ELSE
		IF vm_totales = 2 THEN
			PRINT COLUMN 038, ' AP. PERSONAL',
			      COLUMN 052, ' AP. PATRONAL',
			      COLUMN 066, '  APORTE IESS'
		ELSE
			PRINT COLUMN 019, 'TOTAL INGRESO',
			      COLUMN 034, ' TOTAL EGRESO',
			      COLUMN 049, '   TOTAL NETO'
		END IF
	END IF
	PRINT "-------------------------------------------------------------";
	print ASCII escape;
	print ASCII des_neg

ON EVERY ROW
	NEED 3 LINES
	PRINT COLUMN 001, rm_meses[i].anio		USING "&&&&",
	      COLUMN 007, rm_meses[i].mes		CLIPPED,
	      COLUMN 019, rm_meses[i].val1		USING "##,###,##&.##",
	      COLUMN 034, rm_meses[i].val2		USING "##,###,##&.##",
	      COLUMN 049, rm_meses[i].val3		USING "##,###,##&.##"
	
ON LAST ROW
	NEED 2 LINES
	print ASCII escape;
	print ASCII act_neg;
	PRINT COLUMN 021, "-------------",
	      COLUMN 036, "-------------",
	      COLUMN 051, "-------------"
	PRINT COLUMN 007, "TOTALES ==> ",
	      COLUMN 019, SUM(rm_meses[i].val1)	USING "##,###,##&.##",
	      COLUMN 034, SUM(rm_meses[i].val2)	USING "##,###,##&.##",
	      COLUMN 049, SUM(rm_meses[i].val3)	USING "##,###,##&.##";
	print ASCII escape;
	print ASCII des_neg

END REPORT
