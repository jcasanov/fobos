--------------------------------------------------------------------------------
-- Titulo           : rolp306.4gl - Consulta de Anticipos
-- Elaboracion      : 18-Feb-2010
-- Autor            : NPC
-- Formato Ejecucion: fglrun rolp306 base modulo compania
--			[fec_ini] [fec_fin] [codigo] [D/T]
-- Ultima Correccion: 
-- Motivo Correccion: 
--------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE rm_par		RECORD
				n30_cod_depto	LIKE rolt030.n30_cod_depto,
				g34_nombre	LIKE gent034.g34_nombre,
				n30_cod_trab	LIKE rolt030.n30_cod_trab,
				n30_nombres	LIKE rolt030.n30_nombres,
				fecha_ini	DATE,
				fecha_fin	DATE,
				saldo_ini	LIKE rolt045.n45_val_prest
			END RECORD
DEFINE rm_detalle	ARRAY[30000] OF RECORD
				n45_num_prest	LIKE rolt045.n45_num_prest,
				n32_cod_liqrol	LIKE rolt032.n32_cod_liqrol,
				n03_nombre_abr	LIKE rolt003.n03_nombre_abr,
				fecha		DATE,
				valor_deu	LIKE rolt045.n45_val_prest,
				valor_acr	LIKE rolt045.n45_val_prest,
				saldo_ant	LIKE rolt045.n45_val_prest
			END RECORD
DEFINE rm_adi		ARRAY[30000] OF RECORD
				cod_rubro	CHAR(2),
				nom_rubro	LIKE rolt006.n06_nombre
			END RECORD
DEFINE vm_max_det	SMALLINT
DEFINE vm_num_det	SMALLINT
DEFINE vm_cur_det	SMALLINT
DEFINE vm_fec_ini	DATE
DEFINE vm_fec_arr	DATE
DEFINE vm_fec_tope	DATE



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/rolp306.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 3 AND num_args() <> 7 THEN
	-- Validar # parámetros correcto
	CALL fl_mostrar_mensaje('Número de paráametros incorrecto.','stop')
	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_proceso = 'rolp306'
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
DEFINE r_n03		RECORD LIKE rolt003.*

CALL fl_nivel_isolation()
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
OPEN WINDOW w_rolf306_1 AT row_ini, 2 WITH num_rows ROWS, num_cols COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE lin_menu,
		  MESSAGE LINE LAST, BORDER) 
IF vg_gui = 1 THEN
	OPEN FORM f_rolf306_1 FROM '../forms/rolf306_1'
ELSE
	OPEN FORM f_rolf306_1 FROM '../forms/rolf306_1c'
END IF
DISPLAY FORM f_rolf306_1
LET vm_max_det = 30000
LET vm_num_det = 0
LET vm_cur_det = 0
CALL mostrar_botones()
CALL muestra_contadores()
INITIALIZE rm_par.* TO NULL
LET vm_fec_ini = MDY(08, 01, 2003)
IF num_args() <> 3 THEN
	CALL llamar_otro_prog()
	CLOSE WINDOW w_rolf306_1
	EXIT PROGRAM
END IF
CALL retorna_fec_tope()
IF vm_fec_tope > TODAY THEN
	LET rm_par.fecha_ini = MDY(MONTH(TODAY), 01, YEAR(TODAY))
ELSE
	LET rm_par.fecha_ini = MDY(MONTH(vm_fec_tope), 01, YEAR(vm_fec_tope))
END IF
LET rm_par.fecha_fin = vm_fec_tope
WHILE TRUE
	LET vm_fec_arr = vm_fec_ini
	CALL borrar_detalle()
	CALL leer_parametros()
	IF int_flag THEN
		EXIT WHILE
	END IF
	CALL control_consulta()
END WHILE
CLOSE WINDOW w_rolf306_1
EXIT PROGRAM

END FUNCTION



FUNCTION llamar_otro_prog()
DEFINE r_g34		RECORD LIKE gent034.*
DEFINE r_n30		RECORD LIKE rolt030.*

LET rm_par.fecha_ini = arg_val(4)
LET rm_par.fecha_fin = arg_val(5)
CASE arg_val(7)
	WHEN 'D'
		LET rm_par.n30_cod_depto = arg_val(6)
		CALL fl_lee_departamento(vg_codcia, rm_par.n30_cod_depto)
			RETURNING r_g34.*
		LET rm_par.g34_nombre = r_g34.g34_nombre
		DISPLAY BY NAME	rm_par.n30_cod_depto, rm_par.g34_nombre
	WHEN 'T'
		LET rm_par.n30_cod_trab = arg_val(6)
		CALL fl_lee_trabajador_roles(vg_codcia, rm_par.n30_cod_trab)
			RETURNING r_n30.*
		LET rm_par.n30_nombres = r_n30.n30_nombres
		DISPLAY BY NAME	rm_par.n30_cod_trab, rm_par.n30_nombres
END CASE
DISPLAY BY NAME rm_par.fecha_ini, rm_par.fecha_fin
CALL control_consulta()

END FUNCTION



FUNCTION leer_parametros()
DEFINE r_g34		RECORD LIKE gent034.*
DEFINE r_n30		RECORD LIKE rolt030.*
DEFINE fec_ini		LIKE rolt046.n46_fecha_ini
DEFINE fec_fin		LIKE rolt046.n46_fecha_fin

LET int_flag = 0
INPUT BY NAME rm_par.*
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		LET int_flag = 1
		EXIT INPUT
	ON KEY(F2)
		IF INFIELD(n30_cod_trab) THEN
			CALL fl_ayuda_codigo_empleado(vg_codcia)
				RETURNING r_n30.n30_cod_trab, r_n30.n30_nombres
			IF r_n30.n30_cod_trab IS NOT NULL THEN
				LET rm_par.n30_cod_trab = r_n30.n30_cod_trab
				LET rm_par.n30_nombres  = r_n30.n30_nombres
				DISPLAY BY NAME rm_par.n30_cod_trab,
						rm_par.n30_nombres
			END IF
		END IF
		IF INFIELD(n30_cod_depto) THEN
			CALL fl_ayuda_departamentos(vg_codcia)
				RETURNING r_g34.g34_cod_depto, r_g34.g34_nombre
			IF r_g34.g34_cod_depto IS NOT NULL THEN
				LET rm_par.n30_cod_depto = r_g34.g34_cod_depto
				LET rm_par.g34_nombre    = r_g34.g34_nombre
				DISPLAY BY NAME rm_par.n30_cod_depto,
						rm_par.g34_nombre
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
	AFTER FIELD n30_cod_depto
		IF rm_par.n30_cod_depto IS NOT NULL THEN
			CALL fl_lee_departamento(vg_codcia,rm_par.n30_cod_depto)
				RETURNING r_g34.*
			IF r_g34.g34_compania IS NULL THEN
				CALL fl_mostrar_mensaje('Departamento no existe.','exclamation')
				NEXT FIELD n30_cod_depto
			END IF
			LET rm_par.g34_nombre = r_g34.g34_nombre
		ELSE
			LET rm_par.g34_nombre = NULL
		END IF
		DISPLAY BY NAME rm_par.g34_nombre
	AFTER FIELD n30_cod_trab
		IF rm_par.n30_cod_trab IS NOT NULL THEN
			CALL fl_lee_trabajador_roles(vg_codcia,
							rm_par.n30_cod_trab)
                        	RETURNING r_n30.*
			IF r_n30.n30_compania IS NULL THEN
				CALL fl_mostrar_mensaje('No existe el código de este empleado en la Compañía.','exclamation')
				NEXT FIELD n30_cod_trab
			END IF
			LET rm_par.n30_nombres = r_n30.n30_nombres
			CALL obtener_fec_arr_trab(r_n30.n30_cod_trab)
			CALL obtener_fecha_tope(rm_par.n30_cod_trab)
		ELSE
			LET rm_par.n30_nombres = NULL
			LET vm_fec_arr         = vm_fec_ini
			CALL retorna_fec_tope()
		END IF
		IF rm_par.fecha_fin > vm_fec_tope THEN
			LET rm_par.fecha_fin = vm_fec_tope
			DISPLAY BY NAME rm_par.fecha_fin
		END IF
		IF rm_par.fecha_ini < vm_fec_arr THEN
			LET rm_par.fecha_ini = vm_fec_arr
			DISPLAY BY NAME rm_par.fecha_ini
		END IF
		DISPLAY BY NAME rm_par.n30_nombres
	AFTER FIELD fecha_ini
		IF rm_par.fecha_ini IS NULL THEN
			LET rm_par.fecha_ini = fec_ini
			DISPLAY BY NAME rm_par.fecha_ini
		END IF
		IF rm_par.fecha_ini > vm_fec_tope THEN
			CALL fl_mostrar_mensaje('La fecha inicial debe ser menor o igual a la fecha maxima de anticipos.', 'exclamation')
			LET rm_par.fecha_ini = vm_fec_tope
			DISPLAY BY NAME rm_par.fecha_ini
			NEXT FIELD fecha_ini
		END IF
	AFTER FIELD fecha_fin
		IF rm_par.fecha_fin IS NULL THEN
			LET rm_par.fecha_fin = fec_fin
			DISPLAY BY NAME rm_par.fecha_fin
		END IF
		IF rm_par.fecha_fin > vm_fec_tope THEN
			CALL fl_mostrar_mensaje('La fecha final debe ser menor o igual a la fecha maxima de anticipos.', 'exclamation')
			LET rm_par.fecha_fin = vm_fec_tope
			DISPLAY BY NAME rm_par.fecha_fin
			NEXT FIELD fecha_fin
		END IF
	AFTER INPUT
		IF rm_par.n30_cod_depto IS NULL AND
		   rm_par.n30_cod_trab IS NULL
		THEN
			CALL fl_mostrar_mensaje('Al menos de poner un departamento o un empleado.', 'exclamation')
			CONTINUE INPUT
		END IF
		CALL obtener_fec_arr_trab(rm_par.n30_cod_trab)
		IF rm_par.fecha_ini < vm_fec_arr THEN
			CALL fl_mostrar_mensaje('La fecha inicial debe ser mayor o igual a la fecha de inicio del MODULO ANTICIPOS.', 'exclamation')
			LET rm_par.fecha_ini = vm_fec_arr
			DISPLAY BY NAME rm_par.fecha_ini
			NEXT FIELD fecha_ini
		END IF
		IF rm_par.fecha_fin < vm_fec_arr THEN
			CALL fl_mostrar_mensaje('La fecha final debe ser mayor o igual a la fecha de inicio del MODULO ANTICIPOS.', 'exclamation')
			LET rm_par.fecha_fin = vm_fec_arr
			DISPLAY BY NAME rm_par.fecha_fin
			NEXT FIELD fecha_fin
		END IF
		IF rm_par.fecha_fin < rm_par.fecha_ini THEN
			CALL fl_mostrar_mensaje('La fecha final debe ser menor que la fecha inicial.', 'exclamation')
			NEXT FIELD fecha_fin
		END IF
END INPUT

END FUNCTION



FUNCTION control_consulta()

IF NOT cargar_datos_det() THEN
	RETURN
END IF
CALL mostrar_detalle()

END FUNCTION



FUNCTION cargar_datos_det()
DEFINE r_det		RECORD
				n45_num_prest	LIKE rolt045.n45_num_prest,
				n32_cod_liqrol	LIKE rolt032.n32_cod_liqrol,
				n03_nombre_abr	LIKE rolt003.n03_nombre_abr,
				fecha		DATE,
				valor_deu	LIKE rolt045.n45_val_prest,
				valor_acr	LIKE rolt045.n45_val_prest
			END RECORD
DEFINE query		CHAR(17000)
DEFINE expr_trab	VARCHAR(100)
DEFINE expr_depto	VARCHAR(100)

LET expr_depto = NULL
IF rm_par.n30_cod_depto IS NOT NULL THEN
	LET expr_depto = '   AND n30_cod_depto      = ', rm_par.n30_cod_depto
END IF
LET expr_trab = NULL
IF rm_par.n30_cod_trab IS NOT NULL THEN
	LET expr_trab = '   AND n30_cod_trab       = ', rm_par.n30_cod_trab
END IF
LET query = 'SELECT a.n45_num_prest num_prest, ',
			'CASE WHEN a.n45_estado <> "T" ',
				'THEN a.n45_estado ',
				'ELSE ',
				'CASE WHEN NVL((SELECT 1 FROM rolt045 b ',
					'WHERE b.n45_compania = a.n45_compania',
					' AND b.n45_num_prest=a.n45_prest_tran',
					' AND DATE(b.n45_fecing) <= "',
						rm_par.fecha_fin, '"), 0) = 0 ',
				'THEN ',
					'CASE WHEN a.n45_sal_prest_ant > 0 ',
						'THEN "R" ',
						'ELSE "A" ',
					'END ',
				'ELSE "T" ',
				'END ',
			'END cod_p, ',
			'CASE WHEN a.n45_estado = "A" THEN "ACTIVO" ',
			'     WHEN a.n45_estado = "P" THEN "PROCESADO" ',
			'     WHEN a.n45_estado = "R" THEN "REDISTRIBUIDO" ',
			'     WHEN a.n45_estado = "T" THEN ',
				'CASE WHEN NVL((SELECT 1 FROM rolt045 b ',
					'WHERE b.n45_compania = a.n45_compania',
					' AND b.n45_num_prest=a.n45_prest_tran',
					' AND DATE(b.n45_fecing) <= "',
						rm_par.fecha_fin, '"), 0) = 0 ',
				'THEN ',
					'CASE WHEN a.n45_sal_prest_ant > 0 ',
						'THEN "REDISTRIBUIDO" ',
						'ELSE "ACTIVO" ',
					'END ',
				'ELSE "TRANSFERIDO" ',
				'END ',
			'END nom_p, ',
			'DATE(a.n45_fecing) fecha, ',
			'CASE WHEN a.n45_estado <> "T" ',
				'THEN (a.n45_val_prest + a.n45_valor_int + ',
					'a.n45_sal_prest_ant) ',
				'ELSE ',
				'(a.n45_val_prest + a.n45_valor_int + ',
					'a.n45_sal_prest_ant) - ',
				'NVL((SELECT b.n45_sal_prest_ant ',
				'FROM rolt045 b ',
				'WHERE b.n45_compania  = a.n45_compania ',
				'  AND b.n45_num_prest = a.n45_prest_tran ',
				'  AND DATE(b.n45_fecing) <= "',
						rm_par.fecha_fin, '"), 0) ',
			'END val_d, ',
			'0.00 val_a, LPAD(a.n45_cod_rubro, 2, 0) rubro, ',
			'(SELECT n06_nombre ',
				'FROM rolt006 ',
				'WHERE n06_cod_rubro = a.n45_cod_rubro) nom_r ',
		' FROM rolt030, rolt045 a ',
		' WHERE n30_compania        = ', vg_codcia,
		expr_trab CLIPPED,
		expr_depto CLIPPED,
		'   AND a.n45_compania      = n30_compania ',
		'   AND a.n45_cod_trab      = n30_cod_trab ',
		'   AND a.n45_estado       IN ("A", "R", "P", "T") ',
		'   AND DATE(a.n45_fecing) BETWEEN "', rm_par.fecha_ini, '"',
					     ' AND "', rm_par.fecha_fin, '" ',
		'UNION ALL ',
		'SELECT n33_num_prest num_prest, n33_cod_liqrol cod_p, ',
			'(SELECT n03_nombre_abr ',
				'FROM rolt003 ',
				'WHERE n03_proceso = n33_cod_liqrol) nom_p, ',
			'DATE(n32_fecing) fecha, 0.00 val_d, n33_valor val_p, ',
			'LPAD(n33_cod_rubro, 2, 0) rubro, ',
			'(SELECT n06_nombre ',
				'FROM rolt006 ',
				'WHERE n06_cod_rubro = n33_cod_rubro) nom_r ',
		' FROM rolt030, rolt033, rolt032 ',
		' WHERE n30_compania      = ', vg_codcia,
		expr_trab CLIPPED,
		expr_depto CLIPPED,
		'   AND n33_compania      = n30_compania ',
		'   AND n33_cod_liqrol   IN ("Q1", "Q2") ',
		'   AND n33_cod_trab      = n30_cod_trab ',
		'   AND n33_cod_rubro    IN ',
			'(SELECT UNIQUE n06_cod_rubro ',
			'FROM rolt006 ',
			'WHERE n06_flag_ident IN ',
				'(SELECT UNIQUE n18_flag_ident ',
				'FROM rolt018 ',
				'WHERE n18_cod_rubro = n06_cod_rubro)) ',
		'   AND n33_valor         > 0 ',
		'   AND n33_det_tot       = "DE" ',
		'   AND n33_cant_valor    = "V" ',
		'   AND n32_compania      = n33_compania ',
		'   AND n32_cod_liqrol    = n33_cod_liqrol ',
		'   AND n32_fecha_ini     = n33_fecha_ini ',
		'   AND n32_fecha_fin     = n33_fecha_fin ',
		'   AND n32_cod_trab      = n33_cod_trab ',
		'   AND DATE(n32_fecing) BETWEEN "', rm_par.fecha_ini, '"',
					   ' AND "', rm_par.fecha_fin, '" ',
		'UNION ALL ',
		'SELECT n37_num_prest num_prest, n37_proceso cod_p, ',
			'(SELECT n03_nombre_abr ',
				'FROM rolt003 ',
				'WHERE n03_proceso = n37_proceso) nom_p, ',
			'DATE(n36_fecing) fecha, 0.00 val_d, n37_valor val_p, ',
			'LPAD(n37_cod_rubro, 2, 0) rubro, ',
			'(SELECT n06_nombre ',
				'FROM rolt006 ',
				'WHERE n06_cod_rubro = n37_cod_rubro) nom_r ',
		' FROM rolt030, rolt037, rolt036 ',
		' WHERE n30_compania      = ', vg_codcia,
		expr_trab CLIPPED,
		expr_depto CLIPPED,
		'   AND n37_compania      = n30_compania ',
		'   AND n37_proceso      IN ("DT", "DC") ',
		'   AND n37_cod_trab      = n30_cod_trab ',
		'   AND n37_cod_rubro    IN ',
			'(SELECT UNIQUE n06_cod_rubro ',
			'FROM rolt006 ',
			'WHERE n06_flag_ident IN ',
				'(SELECT UNIQUE n18_flag_ident ',
				'FROM rolt018 ',
				'WHERE n18_cod_rubro = n06_cod_rubro)) ',
		'   AND n37_valor         > 0 ',
		'   AND n36_compania      = n37_compania ',
		'   AND n36_proceso       = n37_proceso ',
		'   AND n36_fecha_ini     = n37_fecha_ini ',
		'   AND n36_fecha_fin     = n37_fecha_fin ',
		'   AND n36_cod_trab      = n37_cod_trab ',
		'   AND DATE(n36_fecing) BETWEEN "', rm_par.fecha_ini, '"',
					   ' AND "', rm_par.fecha_fin, '" ',
		'UNION ALL ',
		'SELECT n40_num_prest num_prest, n40_proceso cod_p, ',
			'(SELECT n03_nombre_abr ',
				'FROM rolt003 ',
				'WHERE n03_proceso = n40_proceso) nom_p, ',
			'DATE(n39_fecing) fecha, 0.00 val_d, n40_valor val_p, ',
			'LPAD(n40_cod_rubro, 2, 0) rubro, ',
			'(SELECT n06_nombre ',
				'FROM rolt006 ',
				'WHERE n06_cod_rubro = n40_cod_rubro) nom_r ',
		' FROM rolt030, rolt040, rolt039 ',
		' WHERE n30_compania      = ', vg_codcia,
		expr_trab CLIPPED,
		expr_depto CLIPPED,
		'   AND n40_compania      = n30_compania ',
		'   AND n40_proceso      IN ("VA", "VP") ',
		'   AND n40_cod_trab      = n30_cod_trab ',
		'   AND n40_cod_rubro    IN ',
			'(SELECT UNIQUE n06_cod_rubro ',
			'FROM rolt006 ',
			'WHERE n06_flag_ident IN ',
				'(SELECT UNIQUE n18_flag_ident ',
				'FROM rolt018 ',
				'WHERE n18_cod_rubro = n06_cod_rubro)) ',
		'   AND n40_valor         > 0 ',
		'   AND n40_det_tot       = "DE" ',
		'   AND n39_compania      = n40_compania ',
		'   AND n39_proceso       = n40_proceso ',
		'   AND n39_periodo_ini   = n40_periodo_ini ',
		'   AND n39_periodo_fin   = n40_periodo_fin ',
		'   AND n39_cod_trab      = n40_cod_trab ',
		'   AND DATE(n39_fecing) BETWEEN "', rm_par.fecha_ini, '"',
					   ' AND "', rm_par.fecha_fin, '" ',
		'UNION ALL ',
		'SELECT n49_num_prest num_prest, n49_proceso cod_p, ',
			'(SELECT n03_nombre_abr ',
				'FROM rolt003 ',
				'WHERE n03_proceso = n49_proceso) nom_p, ',
			'DATE(n41_fecing) fecha, 0.00 val_d, n49_valor val_p, ',
			'LPAD(n49_cod_rubro, 2, 0) rubro, ',
			'(SELECT n06_nombre ',
				'FROM rolt006 ',
				'WHERE n06_cod_rubro = n49_cod_rubro) nom_r ',
		' FROM rolt030, rolt049, rolt042, rolt041 ',
		' WHERE n30_compania      = ', vg_codcia,
		expr_trab CLIPPED,
		expr_depto CLIPPED,
		'   AND n49_compania      = n30_compania ',
		'   AND n49_proceso       = "UT" ',
		'   AND n49_cod_trab      = n30_cod_trab ',
		'   AND n49_cod_rubro    IN ',
			'(SELECT UNIQUE n06_cod_rubro ',
			'FROM rolt006 ',
			'WHERE n06_flag_ident IN ',
				'(SELECT UNIQUE n18_flag_ident ',
				'FROM rolt018 ',
				'WHERE n18_cod_rubro = n06_cod_rubro)) ',
		'   AND n49_valor         > 0 ',
		'   AND n49_det_tot       = "DE" ',
		'   AND n42_compania      = n49_compania ',
		'   AND n42_proceso       = n49_proceso ',
		'   AND n42_cod_trab      = n49_cod_trab ',
		'   AND n42_fecha_ini     = n49_fecha_ini ',
		'   AND n42_fecha_fin     = n49_fecha_fin ',
		'   AND n41_compania      = n42_compania ',
		'   AND n41_proceso       = n42_proceso ',
		'   AND n41_fecha_ini     = n42_fecha_ini ',
		'   AND n41_fecha_fin     = n42_fecha_fin ',
		'   AND DATE(n41_fecing) BETWEEN "', rm_par.fecha_ini, '"',
					   ' AND "', rm_par.fecha_fin, '" ',
		'UNION ALL ',
		'SELECT n92_num_prest num_prest, n91_proceso cod_p, ',
			'(SELECT n03_nombre_abr ',
				'FROM rolt003 ',
				'WHERE n03_proceso = n91_proceso) nom_p, ',
			'DATE(n91_fecing) fecha, 0.00 val_d, ',
			'ABS(n92_valor_pago) val_p, n92_cod_liqrol rubro, ',
			'(SELECT n03_nombre ',
				'FROM rolt003 ',
				'WHERE n03_proceso = n92_cod_liqrol) nom_r ',
		' FROM rolt030, rolt091, rolt092 ',
		' WHERE n30_compania      = ', vg_codcia,
		expr_trab CLIPPED,
		expr_depto CLIPPED,
		'   AND n91_compania      = n30_compania ',
		'   AND n91_proceso       = "CA" ',
		'   AND n91_cod_trab      = n30_cod_trab ',
		'   AND DATE(n91_fecing) BETWEEN "', rm_par.fecha_ini, '"',
					   ' AND "', rm_par.fecha_fin, '"',
		'   AND n92_compania      = n91_compania ',
		'   AND n92_proceso       = n91_proceso ',
		'   AND n92_cod_trab      = n91_cod_trab ',
		'   AND n92_num_ant       = n91_num_ant ',
		'   AND n92_valor_pago   <> 0 ',
		' ORDER BY 4, 5 DESC '
PREPARE det FROM query
DECLARE q_det CURSOR FOR det
LET vm_num_det = 1
CALL obtener_saldo_inicial()
FOREACH q_det INTO r_det.*, rm_adi[vm_num_det].*
	LET rm_detalle[vm_num_det].n45_num_prest  = r_det.n45_num_prest
	LET rm_detalle[vm_num_det].n32_cod_liqrol = r_det.n32_cod_liqrol
	LET rm_detalle[vm_num_det].n03_nombre_abr = r_det.n03_nombre_abr
	LET rm_detalle[vm_num_det].fecha          = r_det.fecha
	LET rm_detalle[vm_num_det].valor_deu      = r_det.valor_deu
	LET rm_detalle[vm_num_det].valor_acr      = r_det.valor_acr
	IF vm_num_det = 1 THEN
		LET rm_detalle[vm_num_det].saldo_ant = rm_par.saldo_ini +
					(r_det.valor_deu - r_det.valor_acr)
	ELSE
		LET rm_detalle[vm_num_det].saldo_ant =
					rm_detalle[vm_num_det - 1].saldo_ant +
					(r_det.valor_deu - r_det.valor_acr)
	END IF
	LET vm_num_det = vm_num_det + 1
        IF vm_num_det > vm_max_det THEN
                EXIT FOREACH
        END IF
END FOREACH
LET vm_num_det = vm_num_det - 1
IF vm_num_det = 0 THEN
	CALL fl_mensaje_consulta_sin_registros()
	RETURN 0
END IF
RETURN 1

END FUNCTION



FUNCTION obtener_saldo_inicial()
DEFINE query		CHAR(15000)
DEFINE expr_trab	VARCHAR(100)
DEFINE expr_depto	VARCHAR(100)

LET expr_depto = NULL
IF rm_par.n30_cod_depto IS NOT NULL THEN
	LET expr_depto = '   AND n30_cod_depto      = ', rm_par.n30_cod_depto
END IF
LET expr_trab = NULL
IF rm_par.n30_cod_trab IS NOT NULL THEN
	LET expr_trab = '   AND n30_cod_trab       = ', rm_par.n30_cod_trab
END IF
LET query = 'SELECT SUM(CASE WHEN a.n45_estado <> "T" ',
				'THEN (a.n45_val_prest + a.n45_valor_int + ',
					'a.n45_sal_prest_ant) ',
				'ELSE ',
				'(a.n45_val_prest + a.n45_valor_int + ',
					'a.n45_sal_prest_ant) - ',
				'NVL((SELECT b.n45_sal_prest_ant ',
				'FROM rolt045 b ',
				'WHERE b.n45_compania  = a.n45_compania ',
				'  AND b.n45_num_prest = a.n45_prest_tran ',
				'  AND DATE(b.n45_fecing) <= "',
						rm_par.fecha_fin, '"), 0) ',
			'END) val_d, 0.00 val_p ',
		' FROM rolt030, rolt045 a ',
		' WHERE n30_compania        = ', vg_codcia,
		expr_trab CLIPPED,
		expr_depto CLIPPED,
		'   AND a.n45_compania      = n30_compania ',
		'   AND a.n45_cod_trab      = n30_cod_trab ',
		'   AND a.n45_estado       IN ("A", "R", "P", "T") ',
		'   AND DATE(a.n45_fecing) >= "', vm_fec_arr, '"',
		'   AND DATE(a.n45_fecing)  < "', rm_par.fecha_ini, '"',
		' GROUP BY 2 ',
		'UNION ALL ',
		'SELECT 0.00 val_d, SUM(n33_valor) val_p ',
		' FROM rolt030, rolt033, rolt032 ',
		' WHERE n30_compania      = ', vg_codcia,
		expr_trab CLIPPED,
		expr_depto CLIPPED,
		'   AND n33_compania      = n30_compania ',
		'   AND n33_cod_liqrol   IN ("Q1", "Q2") ',
		'   AND n33_cod_trab      = n30_cod_trab ',
		'   AND n33_cod_rubro    IN ',
			'(SELECT UNIQUE n06_cod_rubro ',
			'FROM rolt006 ',
			'WHERE n06_flag_ident IN ',
				'(SELECT UNIQUE n18_flag_ident ',
				'FROM rolt018 ',
				'WHERE n18_cod_rubro = n06_cod_rubro)) ',
		'   AND n33_valor         > 0 ',
		'   AND n33_det_tot       = "DE" ',
		'   AND n33_cant_valor    = "V" ',
		'   AND n32_compania      = n33_compania ',
		'   AND n32_cod_liqrol    = n33_cod_liqrol ',
		'   AND n32_fecha_ini     = n33_fecha_ini ',
		'   AND n32_fecha_fin     = n33_fecha_fin ',
		'   AND n32_cod_trab      = n33_cod_trab ',
		'   AND DATE(n32_fecing) >= "', vm_fec_arr, '"',
		'   AND DATE(n32_fecing)  < "', rm_par.fecha_ini, '"',
		' GROUP BY 1 ',
		'UNION ALL ',
		'SELECT 0.00 val_d, SUM(n37_valor) val_p ',
		' FROM rolt030, rolt037, rolt036 ',
		' WHERE n30_compania      = ', vg_codcia,
		expr_trab CLIPPED,
		expr_depto CLIPPED,
		'   AND n37_compania      = n30_compania ',
		'   AND n37_proceso      IN ("DT", "DC") ',
		'   AND n37_cod_trab      = n30_cod_trab ',
		'   AND n37_cod_rubro    IN ',
			'(SELECT UNIQUE n06_cod_rubro ',
			'FROM rolt006 ',
			'WHERE n06_flag_ident IN ',
				'(SELECT UNIQUE n18_flag_ident ',
				'FROM rolt018 ',
				'WHERE n18_cod_rubro = n06_cod_rubro)) ',
		'   AND n37_valor         > 0 ',
		'   AND n36_compania      = n37_compania ',
		'   AND n36_proceso       = n37_proceso ',
		'   AND n36_fecha_ini     = n37_fecha_ini ',
		'   AND n36_fecha_fin     = n37_fecha_fin ',
		'   AND n36_cod_trab      = n37_cod_trab ',
		'   AND DATE(n36_fecing) >= "', vm_fec_arr, '"',
		'   AND DATE(n36_fecing)  < "', rm_par.fecha_ini, '"',
		' GROUP BY 1 ',
		'UNION ALL ',
		'SELECT 0.00 val_d, SUM(n40_valor) val_p ',
		' FROM rolt030, rolt040, rolt039 ',
		' WHERE n30_compania      = ', vg_codcia,
		expr_trab CLIPPED,
		expr_depto CLIPPED,
		'   AND n40_compania      = n30_compania ',
		'   AND n40_proceso      IN ("VA", "VP") ',
		'   AND n40_cod_trab      = n30_cod_trab ',
		'   AND n40_cod_rubro    IN ',
			'(SELECT UNIQUE n06_cod_rubro ',
			'FROM rolt006 ',
			'WHERE n06_flag_ident IN ',
				'(SELECT UNIQUE n18_flag_ident ',
				'FROM rolt018 ',
				'WHERE n18_cod_rubro = n06_cod_rubro)) ',
		'   AND n40_valor         > 0 ',
		'   AND n40_det_tot       = "DE" ',
		'   AND n39_compania      = n40_compania ',
		'   AND n39_proceso       = n40_proceso ',
		'   AND n39_periodo_ini   = n40_periodo_ini ',
		'   AND n39_periodo_fin   = n40_periodo_fin ',
		'   AND n39_cod_trab      = n40_cod_trab ',
		'   AND DATE(n39_fecing) >= "', vm_fec_arr, '"',
		'   AND DATE(n39_fecing)  < "', rm_par.fecha_ini, '"',
		' GROUP BY 1 ',
		'UNION ALL ',
		'SELECT 0.00 val_d, SUM(n49_valor) val_p ',
		' FROM rolt030, rolt049, rolt042, rolt041 ',
		' WHERE n30_compania      = ', vg_codcia,
		expr_trab CLIPPED,
		expr_depto CLIPPED,
		'   AND n49_compania      = n30_compania ',
		'   AND n49_proceso       = "UT" ',
		'   AND n49_cod_trab      = n30_cod_trab ',
		'   AND n49_cod_rubro    IN ',
			'(SELECT UNIQUE n06_cod_rubro ',
			'FROM rolt006 ',
			'WHERE n06_flag_ident IN ',
				'(SELECT UNIQUE n18_flag_ident ',
				'FROM rolt018 ',
				'WHERE n18_cod_rubro = n06_cod_rubro)) ',
		'   AND n49_valor         > 0 ',
		'   AND n49_det_tot       = "DE" ',
		'   AND n42_compania      = n49_compania ',
		'   AND n42_proceso       = n49_proceso ',
		'   AND n42_cod_trab      = n49_cod_trab ',
		'   AND n42_fecha_ini     = n49_fecha_ini ',
		'   AND n42_fecha_fin     = n49_fecha_fin ',
		'   AND n41_compania      = n42_compania ',
		'   AND n41_proceso       = n42_proceso ',
		'   AND n41_fecha_ini     = n42_fecha_ini ',
		'   AND n41_fecha_fin     = n42_fecha_fin ',
		'   AND DATE(n41_fecing) >= "', vm_fec_arr, '"',
		'   AND DATE(n41_fecing)  < "', rm_par.fecha_ini, '"',
		' GROUP BY 1 ',
		'UNION ALL ',
		'SELECT 0.00 val_d, SUM(ABS(n92_valor_pago)) val_p ',
		' FROM rolt030, rolt091, rolt092 ',
		' WHERE n30_compania      = ', vg_codcia,
		expr_trab CLIPPED,
		expr_depto CLIPPED,
		'   AND n91_compania      = n30_compania ',
		'   AND n91_proceso       = "CA" ',
		'   AND n91_cod_trab      = n30_cod_trab ',
		'   AND DATE(n91_fecing) >= "', vm_fec_arr, '"',
		'   AND DATE(n91_fecing)  < "', rm_par.fecha_ini, '"',
		'   AND n92_compania      = n91_compania ',
		'   AND n92_proceso       = n91_proceso ',
		'   AND n92_cod_trab      = n91_cod_trab ',
		'   AND n92_num_ant       = n91_num_ant ',
		'   AND n92_valor_pago   <> 0 ',
		' GROUP BY 1 ',
		' INTO TEMP t1 '
PREPARE exec_t1 FROM query
EXECUTE exec_t1
LET rm_par.saldo_ini = 0
SELECT NVL(SUM(NVL(val_d, 0) - NVL(val_p, 0)), 0)
	INTO rm_par.saldo_ini
	FROM t1
DROP TABLE t1
DISPLAY BY NAME rm_par.saldo_ini

END FUNCTION



FUNCTION obtener_fec_arr_trab(cod_trab)
DEFINE cod_trab		LIKE rolt030.n30_cod_trab

SQL
	SELECT NVL(MIN(DATE(n45_fecing)), MDY(08, 01, 2003))
		INTO $vm_fec_arr
		FROM rolt045
		WHERE n45_compania  = $vg_codcia
		  AND n45_cod_trab  = $cod_trab
		  AND n45_estado   <> "E"
END SQL

END FUNCTION



FUNCTION obtener_fecha_tope(cod_trab)
DEFINE cod_trab		LIKE rolt030.n30_cod_trab
DEFINE query		CHAR(15000)

LET query = 'SELECT NVL(MAX(DATE(a.n45_fecing)), TODAY) fec_top ',
		' FROM rolt030, rolt045 a ',
		' WHERE n30_compania        = ', vg_codcia,
		'   AND n30_cod_trab        = ', cod_trab,
		'   AND a.n45_compania      = n30_compania ',
		'   AND a.n45_cod_trab      = n30_cod_trab ',
		'   AND a.n45_estado       IN ("A", "R", "P", "T") ',
		'   AND DATE(a.n45_fecing) >= "', vm_fec_arr, '"',
		'UNION ALL ',
		'SELECT NVL(MAX(DATE(n32_fecing)), TODAY) fec_top ',
		' FROM rolt030, rolt033, rolt032 ',
		' WHERE n30_compania      = ', vg_codcia,
		'   AND n30_cod_trab      = ', cod_trab,
		'   AND n33_compania      = n30_compania ',
		'   AND n33_cod_liqrol   IN ("Q1", "Q2") ',
		'   AND n33_cod_trab      = n30_cod_trab ',
		'   AND n33_cod_rubro    IN ',
			'(SELECT UNIQUE n06_cod_rubro ',
			'FROM rolt006 ',
			'WHERE n06_flag_ident IN ',
				'(SELECT UNIQUE n18_flag_ident ',
				'FROM rolt018 ',
				'WHERE n18_cod_rubro = n06_cod_rubro)) ',
		'   AND n33_valor         > 0 ',
		'   AND n33_det_tot       = "DE" ',
		'   AND n33_cant_valor    = "V" ',
		'   AND n32_compania      = n33_compania ',
		'   AND n32_cod_liqrol    = n33_cod_liqrol ',
		'   AND n32_fecha_ini     = n33_fecha_ini ',
		'   AND n32_fecha_fin     = n33_fecha_fin ',
		'   AND n32_cod_trab      = n33_cod_trab ',
		'   AND DATE(n32_fecing) >= "', vm_fec_arr, '"',
		'UNION ALL ',
		'SELECT NVL(MAX(DATE(n36_fecing)), TODAY) fec_top ',
		' FROM rolt030, rolt037, rolt036 ',
		' WHERE n30_compania      = ', vg_codcia,
		'   AND n30_cod_trab      = ', cod_trab,
		'   AND n37_compania      = n30_compania ',
		'   AND n37_proceso      IN ("DT", "DC") ',
		'   AND n37_cod_trab      = n30_cod_trab ',
		'   AND n37_cod_rubro    IN ',
			'(SELECT UNIQUE n06_cod_rubro ',
			'FROM rolt006 ',
			'WHERE n06_flag_ident IN ',
				'(SELECT UNIQUE n18_flag_ident ',
				'FROM rolt018 ',
				'WHERE n18_cod_rubro = n06_cod_rubro)) ',
		'   AND n37_valor         > 0 ',
		'   AND n36_compania      = n37_compania ',
		'   AND n36_proceso       = n37_proceso ',
		'   AND n36_fecha_ini     = n37_fecha_ini ',
		'   AND n36_fecha_fin     = n37_fecha_fin ',
		'   AND n36_cod_trab      = n37_cod_trab ',
		'   AND DATE(n36_fecing) >= "', vm_fec_arr, '"',
		'UNION ALL ',
		'SELECT NVL(MAX(DATE(n39_fecing)), TODAY) fec_top ',
		' FROM rolt030, rolt040, rolt039 ',
		' WHERE n30_compania      = ', vg_codcia,
		'   AND n30_cod_trab      = ', cod_trab,
		'   AND n40_compania      = n30_compania ',
		'   AND n40_proceso      IN ("VA", "VP") ',
		'   AND n40_cod_trab      = n30_cod_trab ',
		'   AND n40_cod_rubro    IN ',
			'(SELECT UNIQUE n06_cod_rubro ',
			'FROM rolt006 ',
			'WHERE n06_flag_ident IN ',
				'(SELECT UNIQUE n18_flag_ident ',
				'FROM rolt018 ',
				'WHERE n18_cod_rubro = n06_cod_rubro)) ',
		'   AND n40_valor         > 0 ',
		'   AND n40_det_tot       = "DE" ',
		'   AND n39_compania      = n40_compania ',
		'   AND n39_proceso       = n40_proceso ',
		'   AND n39_periodo_ini   = n40_periodo_ini ',
		'   AND n39_periodo_fin   = n40_periodo_fin ',
		'   AND n39_cod_trab      = n40_cod_trab ',
		'   AND DATE(n39_fecing) >= "', vm_fec_arr, '"',
		'UNION ALL ',
		'SELECT NVL(MAX(DATE(n41_fecing)), TODAY) fec_top ',
		' FROM rolt030, rolt049, rolt042, rolt041 ',
		' WHERE n30_compania      = ', vg_codcia,
		'   AND n30_cod_trab      = ', cod_trab,
		'   AND n49_compania      = n30_compania ',
		'   AND n49_proceso       = "UT" ',
		'   AND n49_cod_trab      = n30_cod_trab ',
		'   AND n49_cod_rubro    IN ',
			'(SELECT UNIQUE n06_cod_rubro ',
			'FROM rolt006 ',
			'WHERE n06_flag_ident IN ',
				'(SELECT UNIQUE n18_flag_ident ',
				'FROM rolt018 ',
				'WHERE n18_cod_rubro = n06_cod_rubro)) ',
		'   AND n49_valor         > 0 ',
		'   AND n49_det_tot       = "DE" ',
		'   AND n42_compania      = n49_compania ',
		'   AND n42_proceso       = n49_proceso ',
		'   AND n42_cod_trab      = n49_cod_trab ',
		'   AND n42_fecha_ini     = n49_fecha_ini ',
		'   AND n42_fecha_fin     = n49_fecha_fin ',
		'   AND n41_compania      = n42_compania ',
		'   AND n41_proceso       = n42_proceso ',
		'   AND n41_fecha_ini     = n42_fecha_ini ',
		'   AND n41_fecha_fin     = n42_fecha_fin ',
		'   AND DATE(n41_fecing) >= "', vm_fec_arr, '"',
		'UNION ALL ',
		'SELECT NVL(MAX(DATE(n91_fecing)), TODAY) fec_top ',
		' FROM rolt030, rolt091, rolt092 ',
		' WHERE n30_compania      = ', vg_codcia,
		'   AND n30_cod_trab      = ', cod_trab,
		'   AND n91_compania      = n30_compania ',
		'   AND n91_proceso       = "CA" ',
		'   AND n91_cod_trab      = n30_cod_trab ',
		'   AND DATE(n91_fecing) >= "', vm_fec_arr, '"',
		'   AND n92_compania      = n91_compania ',
		'   AND n92_proceso       = n91_proceso ',
		'   AND n92_cod_trab      = n91_cod_trab ',
		'   AND n92_num_ant       = n91_num_ant ',
		'   AND n92_valor_pago   <> 0 ',
		' INTO TEMP t1 '
PREPARE exec_fec FROM query
EXECUTE exec_fec
SQL
	SELECT NVL(MAX(fec_top), TODAY)
		INTO $vm_fec_tope
		FROM t1
END SQL
DROP TABLE t1

END FUNCTION



FUNCTION mostrar_detalle()
DEFINE j, col		SMALLINT

CALL mostrar_totales()
LET int_flag = 0
CALL set_count(vm_num_det)
DISPLAY ARRAY rm_detalle TO rm_detalle.*
       	ON KEY(INTERRUPT)   
		LET int_flag = 1
       	        EXIT DISPLAY  
	ON KEY(F5)
		LET vm_cur_det = arr_curr()
		IF rm_detalle[vm_cur_det].n45_num_prest IS NOT NULL THEN
			CALL ver_anticipo()
			LET int_flag = 0
		END IF
	ON KEY(F6)
		CALL imprimir_movimientos()
		LET int_flag = 0
	--#BEFORE DISPLAY 
		--#CALL dialog.keysetlabel('ACCEPT', '')
		--#CALL dialog.keysetlabel('F6', 'Imprimir')
		--#LET vm_cur_det = arr_curr()
	--#BEFORE ROW 
		--#LET vm_cur_det = arr_curr()
		--#LET j = scr_line()
		--#IF rm_detalle[vm_cur_det].n45_num_prest IS NULL THEN
			--#CALL dialog.keysetlabel('F5', '')
		--#ELSE
			--#CALL dialog.keysetlabel('F5', 'Anticipo')
		--#END IF
		--#CALL muestra_contadores()
		--#DISPLAY BY NAME rm_adi[vm_cur_det].*
        --#AFTER DISPLAY  
                --#CONTINUE DISPLAY  
END DISPLAY

END FUNCTION



FUNCTION mostrar_totales()
DEFINE total_deu	DECIMAL(14,2)
DEFINE total_acr	DECIMAL(14,2)
DEFINE i		SMALLINT

LET total_deu   = 0
LET total_acr = 0
FOR i = 1 TO vm_num_det
	LET total_deu = total_deu + rm_detalle[i].valor_deu
	LET total_acr = total_acr + rm_detalle[i].valor_acr
END FOR
DISPLAY BY NAME total_deu, total_acr

END FUNCTION



FUNCTION mostrar_botones()

DISPLAY 'Ant.'			TO tit_col1
DISPLAY 'CP'			TO tit_col2
DISPLAY 'Descripcion'		TO tit_col3
DISPLAY 'Fecha'			TO tit_col4
DISPLAY 'Valor'			TO tit_col5
DISPLAY 'Pago'			TO tit_col6
DISPLAY 'Saldo'			TO tit_col7

END FUNCTION



FUNCTION muestra_contadores()

DISPLAY BY NAME vm_cur_det, vm_num_det

END FUNCTION



FUNCTION borrar_detalle()
DEFINE i		SMALLINT

FOR i = 1 TO vm_max_det
	INITIALIZE rm_detalle[i].*, rm_adi[i].* TO NULL
END FOR
FOR i = 1 TO fgl_scr_size('rm_detalle')
	CLEAR rm_detalle[i].*
END FOR
CLEAR total_deu, total_acr

END FUNCTION


FUNCTION ver_anticipo()
DEFINE param		VARCHAR(60)

LET param = ' ', rm_detalle[vm_cur_det].n45_num_prest
CALL ejecuta_comando('NOMINA', vg_modulo, 'rolp214 ', param)

END FUNCTION



FUNCTION imprimir_movimientos()
DEFINE comando		VARCHAR(100)
DEFINE i		SMALLINT
DEFINE flag		CHAR(1)
DEFINE resp		CHAR(6)

CALL fl_control_reportes() RETURNING comando
IF int_flag THEN
	RETURN
END IF
LET flag     = 'S'
LET int_flag = 0
CALL fl_hacer_pregunta('Desea imprimir Saldos ?', 'No') RETURNING resp
IF resp <> 'Yes' THEN
	LET int_flag = 0
	LET flag     = 'N'
END IF
START REPORT report_movimientos TO PIPE comando
FOR i = 1 TO vm_num_det
	OUTPUT TO REPORT report_movimientos(i, flag)
END FOR
FINISH REPORT report_movimientos

END FUNCTION



REPORT report_movimientos(i, flag)
DEFINE i		SMALLINT
DEFINE flag		CHAR(1)
DEFINE r_g01		RECORD LIKE gent001.*
DEFINE r_g50		RECORD LIKE gent050.*
DEFINE r_g54		RECORD LIKE gent054.*
DEFINE fecha		DATE
DEFINE usuario		VARCHAR(19,15)
DEFINE modulo		VARCHAR(40)
DEFINE lim, col		SMALLINT
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
	LET lim = LENGTH(r_g54.g54_nombre)
	LET col = ((80 - lim) / 2) + 1
	print ASCII escape;
	print ASCII act_neg;
	print ASCII escape;
	print ASCII act_10cpi;
	PRINT COLUMN 005, r_g01.g01_razonsocial,
  	      COLUMN 074, "PAGINA: ", PAGENO USING "&&&"
	SKIP 1 LINES
	PRINT COLUMN 001, modulo CLIPPED,
	      COLUMN col, r_g54.g54_nombre[1, lim] CLIPPED,
	      COLUMN 074, UPSHIFT(vg_proceso) CLIPPED
	SKIP 1 LINES
	IF rm_par.n30_cod_depto IS NOT NULL THEN
		PRINT COLUMN 006, "** DEPTO. ACTUAL: ",
			rm_par.n30_cod_depto USING "<<&&", ' ', 
			rm_par.g34_nombre CLIPPED
	END IF
	PRINT COLUMN 006, "** EMPLEADO     : ",
			rm_par.n30_cod_trab USING "<<&&&", ' ', 
			rm_par.n30_nombres CLIPPED
	PRINT COLUMN 006, "** PERIODO      : ",
		rm_par.fecha_ini USING "dd-mm-yyyy", '  -  ',
		rm_par.fecha_fin USING "dd-mm-yyyy"
	SKIP 1 LINES
	PRINT COLUMN 001, "FECHA IMPRESION: ", TODAY USING "dd-mm-yyyy",
 		1 SPACES, TIME,
	      COLUMN 062, usuario
	PRINT "--------------------------------------------------------------------------------"
	PRINT COLUMN 001, "ANTIC",
	      COLUMN 008, "CP",
	      COLUMN 012, "DESCRIPCION",
	      COLUMN 029, "FECHA",
	      COLUMN 041, "       VALOR",
	      COLUMN 055, "        PAGO";
	IF flag = 'S' THEN
		PRINT COLUMN 069, "       SALDO"
	ELSE
		PRINT COLUMN 069, " "
	END IF
	PRINT "--------------------------------------------------------------------------------";
	print ASCII escape;
	print ASCII des_neg

ON EVERY ROW
	IF i = 1 AND flag = 'S' THEN
		LET fecha = rm_detalle[i].fecha - 1 UNITS DAY
		PRINT COLUMN 036, 'SALDO ANTERIOR AL ',
			fecha USING "dd-mm-yyyy", ' ==> ',
		      COLUMN 069, rm_par.saldo_ini	USING "-,---,--&.##"
		SKIP 1 LINES
	END IF
	IF flag = 'S' THEN
		NEED 4 LINES
	ELSE
		NEED 3 LINES
	END IF
	PRINT COLUMN 001, rm_detalle[i].n45_num_prest	USING "<<&&&",
	      COLUMN 008, rm_detalle[i].n32_cod_liqrol,
	      COLUMN 012, rm_detalle[i].n03_nombre_abr,
	      COLUMN 029, rm_detalle[i].fecha		USING "dd-mm-yyyy",
	      COLUMN 041, rm_detalle[i].valor_deu	USING "#,###,##&.##",
	      COLUMN 055, rm_detalle[i].valor_acr	USING "#,###,##&.##";
	IF flag = 'S' THEN
		PRINT COLUMN 069, rm_detalle[i].saldo_ant USING "-,---,--&.##"
	ELSE
		PRINT COLUMN 069, " "
	END IF
	
ON LAST ROW
	IF flag = 'S' THEN
		NEED 3 LINES
	ELSE
		NEED 2 LINES
	END IF
	print ASCII escape;
	print ASCII act_neg;
	PRINT COLUMN 043, "------------",
	      COLUMN 057, "------------"
	PRINT COLUMN 029, "TOTALES ==> ",
	      COLUMN 041, SUM(rm_detalle[i].valor_deu)	USING "#,###,##&.##",
	      COLUMN 055, SUM(rm_detalle[i].valor_acr)	USING "#,###,##&.##";
	print ASCII escape;
	print ASCII des_neg

END REPORT


 
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
LET comando = 'cd ..', vg_separador, '..', vg_separador, modulo,
		vg_separador, 'fuentes', vg_separador, run_prog, prog,
		vg_base, ' ', mod, ' ', vg_codcia, ' ', param
RUN comando

END FUNCTION



FUNCTION retorna_fec_tope()

SQL
	SELECT NVL(MAX(DATE(n45_fecha)), TODAY)
		INTO $vm_fec_tope
		FROM rolt045
		WHERE n45_compania  = $vg_codcia
		  AND n45_estado   <> 'E'
END SQL
IF vm_fec_tope < TODAY THEN
	LET vm_fec_tope = TODAY
END IF

END FUNCTION
