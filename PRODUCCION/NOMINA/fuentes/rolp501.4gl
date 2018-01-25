GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_cod_liqrol	LIKE rolt032.n32_cod_liqrol
DEFINE vm_fecha_ini	DATE
DEFINE vm_fecha_fin	DATE
DEFINE vm_tipo_comp	LIKE ctbt012.b12_tipo_comp
DEFINE vm_num_comp	LIKE ctbt012.b12_num_comp



MAIN

DEFER QUIT 
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/rolp501.err')
CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 3 THEN          -- Validar # parametros correcto
	CALL fl_mostrar_mensaje('Número de parametros incorrecto', 'stop')
	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_proceso = 'rolp501'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
--#CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL control_master()

END MAIN



FUNCTION control_master()
DEFINE lin_menu		SMALLINT
DEFINE row_ini  	SMALLINT
DEFINE num_rows 	SMALLINT
DEFINE num_cols 	SMALLINT

CALL fl_nivel_isolation()
LET lin_menu = 0
LET row_ini  = 3
LET num_rows = 8
LET num_cols = 80
IF vg_gui = 0 THEN
	LET lin_menu = 1
	LET row_ini  = 4
	LET num_rows = 20
	LET num_cols = 78
END IF
OPEN WINDOW w_rolf501_1 AT row_ini, 2 WITH num_rows ROWS, num_cols COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE lin_menu,
		BORDER, MESSAGE LINE LAST)
OPEN FORM f_rolf501_1 FROM '../forms/rolf501_1'
DISPLAY FORM f_rolf501_1
CREATE TEMP TABLE te_master
	(te_serial		SERIAL,
	 te_cuenta		CHAR(12),
	 te_glosa		CHAR(35),
	 te_tipo_mov		CHAR(1),
	 te_valor		DECIMAL(14,2))
CALL lee_confirmacion()
LET vm_tipo_comp  = 'DN'
CALL carga_temporales()
CALL proceso_ingresos()
CALL proceso_egresos()
BEGIN WORK
	CALL graba_comprobante_contable()
COMMIT WORK
DISPLAY BY NAME vm_tipo_comp, vm_num_comp
CALL fl_mayoriza_comprobante(vg_codcia, vm_tipo_comp, vm_num_comp, 'M')
CALL fl_mensaje_registro_ingresado()
DROP TABLE te_master
CLOSE WINDOW w_rolf501_1

END FUNCTION



FUNCTION lee_confirmacion()
DEFINE r_n53		RECORD LIKE rolt053.*
DEFINE r_n32		RECORD LIKE rolt032.*
DEFINE resp		CHAR(6)
DEFINE flag_run		SMALLINT
DEFINE query		CHAR(1600)

LET int_flag = 0
INITIALIZE r_n53.* TO NULL
SELECT * INTO r_n53.* FROM rolt053
	WHERE n53_compania = vg_codcia AND 
              n53_num_comp = (SELECT MAX(n53_num_comp) FROM rolt053
				WHERE n53_compania = vg_codcia)
DISPLAY BY NAME r_n53.n53_cod_liqrol, r_n53.n53_fecha_ini, r_n53.n53_fecha_fin,
		r_n53.n53_tipo_comp, r_n53.n53_num_comp
LET query = 'SELECT n32_cod_liqrol, n32_fecha_ini, n32_fecha_fin ',
		' FROM rolt032 ',
		' WHERE n32_compania     = ', vg_codcia,
		'   AND n32_estado       = "C" ',
		'   AND n32_ano_proceso >= 2004 ',
		' UNION ',
		' SELECT n36_proceso, n36_fecha_ini, n36_fecha_fin ',
			' FROM rolt036 ',
			' WHERE n36_compania     = ', vg_codcia,
			'   AND n36_estado       = "P" ',
			'   AND n36_ano_proceso >= 2007 ',
		' UNION ',
		' SELECT n03_proceso, MDY(n03_mes_ini, n03_dia_ini, n41_ano)',
			' fecha_ini, MDY(n03_mes_fin, n03_dia_fin, n41_ano)',
			' fecha_fin ',
			' FROM rolt090, rolt041, rolt003 ',
			' WHERE n90_compania     = ', vg_codcia,
			'   AND n41_compania     = n90_compania ',
			'   AND n41_ano         >= n90_anio_ini_ut - 1 ',
			'   AND n41_estado       = "P" ',
			'   AND n03_proceso      = "UT" ',
		' UNION ',
		' SELECT "FR", n38_fecha_ini, n38_fecha_fin ',
			' FROM rolt038 ',
			' WHERE n38_compania         = ', vg_codcia,
			'   AND n38_estado           = "P" ',
			'   AND YEAR(n38_fecha_fin) >= 2007 ',
			'   AND n38_pago_iess        = "S" ',
		' ORDER BY 2 '
PREPARE cons_ult FROM query
DECLARE q_ult CURSOR FOR cons_ult
LET flag_run = 0
FOREACH q_ult INTO vm_cod_liqrol, vm_fecha_ini, vm_fecha_fin
	IF vm_cod_liqrol = r_n53.n53_cod_liqrol AND
	   vm_fecha_ini <= r_n53.n53_fecha_ini
	THEN
		CONTINUE FOREACH
	END IF
	SELECT * FROM rolt053 
		WHERE n53_compania   = vg_codcia AND
		      n53_cod_liqrol = vm_cod_liqrol AND 
		      n53_fecha_ini  = vm_fecha_ini AND 
		      n53_fecha_fin  = vm_fecha_fin
	IF STATUS = NOTFOUND THEN
		LET flag_run = 1
		EXIT FOREACH
	END IF
END FOREACH
--OPEN q_ult
--FETCH q_ult INTO vm_cod_liqrol, vm_fecha_ini, vm_fecha_fin
--IF STATUS = NOTFOUND THEN
	--CALL fl_mostrar_mensaje('No hay ningun rol de pagos ya procesado.',
				--'exclamation')
	--EXIT PROGRAM
--END IF
IF r_n53.n53_cod_liqrol = vm_cod_liqrol AND 
   r_n53.n53_fecha_ini  = vm_fecha_ini  AND 
   r_n53.n53_fecha_fin  = vm_fecha_fin  THEN
	CALL fl_mostrar_mensaje('No hay rol para contabilizar.', 'exclamation')
	DROP TABLE te_master
	CLOSE WINDOW w_rolf501_1
	EXIT PROGRAM
END IF
IF NOT flag_run THEN
	SELECT * FROM rolt053 
		WHERE n53_compania   = vg_codcia AND
		      n53_cod_liqrol = r_n53.n53_cod_liqrol AND 
		      n53_fecha_ini  = r_n53.n53_fecha_ini AND 
		      n53_fecha_fin  = r_n53.n53_fecha_fin
	IF STATUS <> NOTFOUND THEN
		CALL fl_mostrar_mensaje('No hay rol para contabilizar.', 'exclamation')
		DROP TABLE te_master
		CLOSE WINDOW w_rolf501_1
		EXIT PROGRAM
	END IF
END IF
DISPLAY BY NAME vm_cod_liqrol, vm_fecha_ini, vm_fecha_fin 
CALL fl_hacer_pregunta('Desea generar comprobante contable','No')
	RETURNING resp
IF resp <> 'Yes' THEN
	DROP TABLE te_master
	CLOSE WINDOW w_rolf501_1
	EXIT PROGRAM
END IF

END FUNCTION



FUNCTION proceso_ingresos()
--DEFINE cod_rubro	LIKE rolt006.n06_cod_rubro
DEFINE cod_rubro	INTEGER
DEFINE cod_depto	LIKE gent034.g34_cod_depto
DEFINE r_n03		RECORD LIKE rolt003.*
DEFINE r_n30		RECORD LIKE rolt030.*
DEFINE r_n50		RECORD LIKE rolt050.*
DEFINE r_n56		RECORD LIKE rolt056.*
DEFINE valor		DECIMAL(12,2)
DEFINE tipo_mov		CHAR(1)
DEFINE mensaje		VARCHAR(250)
DEFINE query		CHAR(1200)

LET query = 'SELECT n32_cod_depto, n33_cod_rubro, NVL(SUM(n33_valor), 0) ',
		' FROM temp_cabrol, temp_detrol ',
		' WHERE n32_compania   = ', vg_codcia,
		'   AND n32_cod_liqrol = "', vm_cod_liqrol, '"',
		'   AND n32_fecha_ini  = "', vm_fecha_ini, '"',
		'   AND n32_fecha_fin  = "', vm_fecha_fin, '"',
		'   AND n33_compania   = n32_compania ',
		'   AND n33_cod_liqrol = n32_cod_liqrol ',
		'   AND n33_fecha_ini  = n32_fecha_ini ',
		'   AND n33_fecha_fin  = n32_fecha_fin ',
		'   AND n33_cod_trab   = n32_cod_trab ',
		'   AND n33_det_tot    = "DI" ',
		'   AND n33_cant_valor = "V" ',
		' GROUP BY 1, 2 ',
		' HAVING SUM(n33_valor) <> 0 ',
		' ORDER BY 2 '
IF vm_cod_liqrol[1, 1] <> 'Q' THEN
	LET query = 'SELECT n32_cod_depto, n32_cod_trab, ',
				'NVL(SUM(n32_tot_neto), 0)',
			' FROM temp_cabrol ',
			' WHERE n32_compania   = ', vg_codcia,
			'   AND n32_cod_liqrol = "', vm_cod_liqrol, '"',
			'   AND n32_fecha_ini  = "', vm_fecha_ini, '"',
			'   AND n32_fecha_fin  = "', vm_fecha_fin, '"',
			' GROUP BY 1, 2 ',
			' HAVING SUM(n32_tot_neto) <> 0 ',
			' ORDER BY 2 '
END IF
PREPARE cons_ring FROM query
DECLARE q_ring CURSOR FOR cons_ring
FOREACH q_ring INTO cod_depto, cod_rubro, valor
	IF vm_cod_liqrol[1, 1] <> 'Q' THEN
		CALL lee_conf_adi_cont_rol(vg_codcia, vm_cod_liqrol, cod_depto,
						cod_rubro)
			RETURNING r_n56.*
		IF r_n56.n56_compania IS NULL THEN
			CALL fl_lee_proceso_roles(vm_cod_liqrol)
				RETURNING r_n03.*
			CALL fl_lee_trabajador_roles(vg_codcia, cod_rubro)
				RETURNING r_n30.*
			LET mensaje = 'No hay auxiliar contable asociado ',
				      'para el proceso: ',vm_cod_liqrol CLIPPED,
					' ',r_n03.n03_nombre CLIPPED,', en el ',
					'código de trabajador: ',
					cod_rubro USING "<<<<&", ' ',
					r_n30.n30_nombres CLIPPED, '.'
			CALL fl_mostrar_mensaje(mensaje, 'stop')
			DROP TABLE te_master
			CLOSE WINDOW w_rolf501_1
			EXIT PROGRAM
		END IF
		LET r_n50.n50_aux_cont = r_n56.n56_aux_val_vac
	ELSE
		SELECT * INTO r_n50.* FROM rolt050
			WHERE n50_compania  = vg_codcia
			  AND n50_cod_rubro = cod_rubro
			  AND n50_cod_depto = cod_depto
		IF STATUS = NOTFOUND THEN
			{--
			LET mensaje = 'No hay auxiliar contable asociado ',
				      'para el rubro de ingreso: ', 
				       cod_rubro USING '##&'
			CALL fl_mostrar_mensaje(mensaje, 'stop')
			CLOSE WINDOW w_rolf501_1
			EXIT PROGRAM
			--}
			CALL obtener_aux_cont_ing_por_trab(cod_depto, cod_rubro)
			CONTINUE FOREACH
		END IF
	END IF
	LET tipo_mov = 'D'
	IF valor < 0 THEN
		LET tipo_mov = 'H'
		LET valor = valor * -1
	END IF
	CALL inserta_tabla_master(r_n50.n50_aux_cont, '', tipo_mov, valor)
END FOREACH

END FUNCTION



FUNCTION obtener_aux_cont_ing_por_trab(cod_depto, cod_rubro)
DEFINE cod_depto	LIKE gent034.g34_cod_depto
DEFINE cod_rubro	LIKE rolt006.n06_cod_rubro
DEFINE cod_trab		LIKE rolt030.n30_cod_trab
DEFINE cuenta		LIKE ctbt010.b10_cuenta
DEFINE tipo_mov		CHAR(1)
DEFINE valor		DECIMAL(12,2)

DECLARE q_ing2 CURSOR FOR
	SELECT n32_cod_trab, n33_valor
		FROM temp_cabrol, temp_detrol
		WHERE n32_compania   = vg_codcia
		  AND n32_cod_liqrol = vm_cod_liqrol
		  AND n32_fecha_ini  = vm_fecha_ini
		  AND n32_fecha_fin  = vm_fecha_fin
		  AND n32_cod_depto  = cod_depto
		  AND n32_compania   = n33_compania
		  AND n32_cod_liqrol = n33_cod_liqrol
		  AND n32_fecha_ini  = n33_fecha_ini
		  AND n32_fecha_fin  = n33_fecha_fin
		  AND n32_cod_trab   = n33_cod_trab
		  AND n33_cod_rubro  = cod_rubro
		  AND n33_det_tot    = "DI"
		  AND n33_cant_valor = "V"
		  AND n33_valor      <> 0
		ORDER BY 1
FOREACH q_ing2 INTO cod_trab, valor
	CALL retorna_cuenta_egr(cod_rubro, cod_trab) RETURNING cuenta
	LET tipo_mov = 'D'
	IF valor < 0 THEN
		LET tipo_mov = 'H'
		LET valor = valor * -1
	END IF
	CALL inserta_tabla_master(cuenta, '', tipo_mov, valor)
END FOREACH

END FUNCTION



FUNCTION proceso_egresos()
DEFINE cod_rubro	LIKE rolt006.n06_cod_rubro
DEFINE cod_depto	LIKE gent034.g34_cod_depto
DEFINE cod_trab		LIKE rolt030.n30_cod_trab
DEFINE cuenta, aux_cta	LIKE ctbt010.b10_cuenta
DEFINE r_g09		RECORD LIKE gent009.*
DEFINE r_n03		RECORD LIKE rolt003.*
DEFINE r_n06		RECORD LIKE rolt006.*
DEFINE r_n30		RECORD LIKE rolt030.*
DEFINE r_n52		RECORD LIKE rolt052.*
DEFINE r_n56		RECORD LIKE rolt056.*
DEFINE valor, tot_neto	DECIMAL(12,2)
DEFINE tipo_mov		CHAR(1)
DEFINE mensaje		VARCHAR(250)
DEFINE val_egr, val_pag	DECIMAL(12,2)
DEFINE val_pag2		DECIMAL(12,2)
DEFINE query		CHAR(1700)
DEFINE cuantos		INTEGER
DEFINE tipo_pago	CHAR(1)
DEFINE bco_empresa	LIKE gent009.g09_banco
DEFINE cta_empresa	LIKE gent009.g09_numero_cta

DECLARE q_regr CURSOR FOR
	SELECT n32_cod_depto, n32_cod_trab, n33_cod_rubro, n33_valor
		FROM temp_cabrol, temp_detrol
		WHERE n32_compania   = vg_codcia
		  AND n32_cod_liqrol = vm_cod_liqrol
		  AND n32_fecha_ini  = vm_fecha_ini
		  AND n32_fecha_fin  = vm_fecha_fin
		  AND n32_compania   = n33_compania
		  AND n32_cod_liqrol = n33_cod_liqrol
		  AND n32_fecha_ini  = n33_fecha_ini
		  AND n32_fecha_fin  = n33_fecha_fin
		  AND n32_cod_trab   = n33_cod_trab
		  AND n33_det_tot    = "DE"
		  AND n33_cant_valor = "V"
		  AND n33_valor      <> 0
		ORDER BY 3, 2
IF vm_cod_liqrol[1, 1] <> 'Q' THEN
	LET val_egr = 0
END IF
FOREACH q_regr INTO cod_depto, cod_trab, cod_rubro, valor
	CALL fl_lee_rubro_roles(cod_rubro) RETURNING r_n06.*
	IF vm_cod_liqrol[1, 1] <> 'Q' THEN
		CALL lee_conf_adi_cont_rol(vg_codcia, vm_cod_liqrol, cod_depto,
						cod_trab)
			RETURNING r_n56.*
		IF r_n56.n56_aux_otr_egr IS NULL AND vm_cod_liqrol <> 'FR' THEN
			CALL fl_lee_proceso_roles(vm_cod_liqrol)
				RETURNING r_n03.*
			CALL fl_lee_trabajador_roles(vg_codcia, cod_trab)
				RETURNING r_n30.*
			LET mensaje = 'No hay auxiliar contable asociado ',
				      'para el proceso: ',vm_cod_liqrol CLIPPED,
					' ',r_n03.n03_nombre CLIPPED,', en el ',
					'código de trabajador: ',
					cod_trab USING "<<<<&", ' ',
					r_n30.n30_nombres CLIPPED, '. Rubro: ',
					cod_rubro USING "#&&", ' ',
					r_n06.n06_nombre CLIPPED, '.'
			CALL fl_mostrar_mensaje(mensaje, 'stop')
			DROP TABLE te_master
			CLOSE WINDOW w_rolf501_1
			EXIT PROGRAM
		END IF
		IF r_n06.n06_flag_ident = 'AN' THEN
			LET cuenta = r_n56.n56_aux_otr_egr
		ELSE
			LET cuenta = r_n56.n56_aux_banco
			IF vm_cod_liqrol <> 'FR' THEN
				CALL retorna_cuenta_egr(cod_rubro, cod_trab)
					RETURNING cuenta
			END IF
		END IF
	ELSE
		CALL retorna_cuenta_egr(cod_rubro, cod_trab) RETURNING cuenta
	END IF
	IF r_n06.n06_flag_ident = 'AN' OR r_n06.n06_flag_ident = 'IR' THEN
		SELECT * INTO r_n52.*
			FROM rolt052
			WHERE n52_compania  = vg_codcia
			  AND n52_cod_rubro = cod_rubro
			  AND n52_cod_trab  = cod_trab  
		IF STATUS = NOTFOUND THEN
			CALL lee_conf_adi_cont_rol(vg_codcia,
						r_n06.n06_flag_ident,
						cod_depto, cod_trab)
				RETURNING r_n56.*
			IF r_n56.n56_compania IS NOT NULL THEN
				LET cuenta = r_n56.n56_aux_val_vac
			ELSE
				CALL retorna_cuenta_egr(cod_rubro, cod_trab)
					RETURNING cuenta
			END IF
		ELSE
			CALL retorna_cuenta_egr(cod_rubro, cod_trab)
				RETURNING cuenta
		END IF
	END IF
	LET tipo_mov = 'H'
	IF valor < 0 THEN
		LET tipo_mov = 'D'
		LET valor = valor * -1
	END IF
	CALL inserta_tabla_master(cuenta, '', tipo_mov, valor)
	IF vm_cod_liqrol[1, 1] <> 'Q' THEN
		LET val_egr = val_egr - valor
	END IF
END FOREACH
DECLARE q_tneto CURSOR FOR 
	SELECT n32_tipo_pago, n32_bco_empresa, n32_cta_empresa, 
	       NVL(SUM(n32_tot_neto), 0)
		FROM temp_cabrol
		WHERE n32_compania   = vg_codcia      AND 
	              n32_cod_liqrol = vm_cod_liqrol  AND 
	              n32_fecha_ini  = vm_fecha_ini   AND
	              n32_fecha_fin  = vm_fecha_fin
		GROUP BY 1, 2, 3
		ORDER BY 1, 2, 3, 4
LET val_pag2 = NULL
LET aux_cta  = NULL
FOREACH q_tneto INTO tipo_pago, bco_empresa, cta_empresa, tot_neto
	IF vm_cod_liqrol = 'FR' THEN
		CONTINUE FOREACH
	END IF
	SELECT n54_aux_cont INTO cuenta
		FROM rolt054
		WHERE n54_compania = vg_codcia
	IF vm_cod_liqrol = 'UT' OR (vg_codloc = 1 AND vm_cod_liqrol[1, 1] = 'D')
	THEN
		DECLARE q_cta CURSOR FOR
			SELECT n56_aux_banco, COUNT(*)
				FROM rolt056
				WHERE n56_compania = vg_codcia
				  AND n56_proceso  = vm_cod_liqrol
				  AND n56_estado   = 'A'
				GROUP BY 1
				ORDER BY 2
		FOREACH q_cta INTO cuenta, cuantos
			IF aux_cta IS NULL THEN
				LET aux_cta = cuenta
				EXIT FOREACH
			END IF
		END FOREACH
	END IF
	IF STATUS = NOTFOUND THEN
		LET mensaje = 'No se ha definido el auxiliar ',
		      	'contable (rolt054), para pago de rol en efectivo.' 
		CALL fl_mostrar_mensaje(mensaje, 'stop')
		DROP TABLE te_master
		CLOSE WINDOW w_rolf501_1
		EXIT PROGRAM
	END IF
	IF tipo_pago = 'T' THEN
		CALL fl_lee_banco_compania(vg_codcia, bco_empresa, cta_empresa)
			RETURNING r_g09.*
		IF r_g09.g09_compania IS NULL THEN
			LET mensaje = 'No existe en gent009 la cuenta ',
				      'corriente: ',
 		      	               bco_empresa USING '##&', ' ',
				       cta_empresa
		        CALL fl_mostrar_mensaje(mensaje, 'stop')
			DROP TABLE te_master
			CLOSE WINDOW w_rolf501_1
		        EXIT PROGRAM
		END IF	
		LET cuenta = r_g09.g09_aux_cont
	END IF
	IF vm_cod_liqrol[1, 1] <> 'Q' THEN
		IF vg_codloc = 3 THEN
			IF tipo_pago = 'T' THEN
				LET tot_neto = tot_neto + val_egr
			END IF
		ELSE
			IF vm_cod_liqrol <> 'UT' AND
			  (vg_codloc = 3 OR vm_cod_liqrol[1, 1] <> 'D')
			THEN
				LET tot_neto = tot_neto + val_egr
			ELSE
				IF vg_codcia = 1 THEN
					--IF tipo_pago <> 'E' THEN  OJO ANTES
					IF tipo_pago = 'T' THEN
						LET tot_neto =tot_neto + val_egr
					END IF
				ELSE
					IF tipo_pago <> 'E' THEN
						LET tot_neto =tot_neto + val_egr
					END IF
				END IF
			END IF
		END IF
		IF tipo_pago <> 'T' AND vg_codloc = 3 THEN
			LET query = 'SELECT NVL(SUM(CASE WHEN n33_det_tot = ',
					'"DE" THEN n33_valor * (-1) ELSE ',
					'n33_valor END), 0) ',
					' FROM temp_cabrol, temp_detrol ',
					' WHERE n32_compania   = ', vg_codcia,
					'   AND n32_cod_liqrol = "',
							vm_cod_liqrol, '"',
					'   AND n32_fecha_ini  = "',
							vm_fecha_ini, '"',
					'   AND n32_fecha_fin  = "',
							vm_fecha_fin, '"',
	 				'   AND n32_tipo_pago  = "',
							tipo_pago, '"',
					'   AND n32_tot_neto   > 0 ',
					'   AND n33_compania   = n32_compania ',
					'   AND n33_cod_liqrol =n32_cod_liqrol',
					'   AND n33_fecha_ini  = n32_fecha_ini',
					'   AND n33_fecha_fin  = n32_fecha_fin',
					'   AND n33_cod_trab   = n32_cod_trab '
			PREPARE cons_det FROM query
			DECLARE q_det CURSOR FOR cons_det
			OPEN q_det
			FETCH q_det INTO val_pag
			CLOSE q_det
			FREE q_det
			LET val_pag2 = tot_neto
			IF val_pag >= 0 THEN
				LET tot_neto = tot_neto - val_pag
			ELSE
				LET tot_neto = tot_neto + val_pag
			END IF
			--CALL inserta_tabla_master(cuenta, '', 'D', tot_neto)
			LET val_pag = tot_neto
		ELSE
			IF val_pag2 IS NOT NULL OR vg_codloc = 3 THEN
				IF val_pag2 >= 0 THEN
					LET tot_neto = tot_neto - val_pag
							+ val_pag2
				ELSE
					LET tot_neto = tot_neto + val_pag
							- val_pag2
				END IF
			END IF
			LET val_pag2 = NULL
		END IF
	END IF
	CALL inserta_tabla_master(cuenta, '', 'H', tot_neto)
END FOREACH
DECLARE q_ty CURSOR FOR SELECT te_tipo_mov, SUM(te_valor) FROM te_master 
	GROUP BY 1
LET tot_neto = 0
FOREACH q_ty INTO tipo_mov, valor
	IF tipo_mov = 'H' THEN
		LET valor = valor * -1
	END IF
	LET tot_neto = tot_neto - valor
END FOREACH
IF tot_neto <> 0 THEN
	LET mensaje = 'No son iguales el total Db y Cr del comprobante ',
		      'contable a generarse. Revise el rol de pago respectivo.',
			' ', tot_neto USING "--,---,--&.##"
	CALL fl_mostrar_mensaje(mensaje, 'stop')
	DROP TABLE te_master
	CLOSE WINDOW w_rolf501_1
	EXIT PROGRAM
END IF
IF valor = 0 THEN
	LET mensaje = 'Los totales Db y Cr son 0. ',
		      'Revise el rol de pago respectivo.'
	CALL fl_mostrar_mensaje(mensaje, 'stop')
	DROP TABLE te_master
	CLOSE WINDOW w_rolf501_1
	EXIT PROGRAM
END IF

END FUNCTION



FUNCTION inserta_tabla_master(cuenta, glosa, tipo_mov, valor)
DEFINE cuenta		LIKE ctbt010.b10_cuenta
DEFINE glosa		LIKE ctbt013.b13_glosa
DEFINE valor		DECIMAL(12,2)
DEFINE tipo_mov		CHAR(1)

SELECT * FROM te_master WHERE te_cuenta = cuenta AND te_tipo_mov = tipo_mov
IF STATUS = NOTFOUND THEN
	INSERT INTO te_master VALUES
		(0, cuenta, glosa, tipo_mov, valor)
ELSE
	UPDATE te_master
		SET te_valor = te_valor + valor
		WHERE te_cuenta = cuenta AND te_tipo_mov = tipo_mov
END IF

END FUNCTION



FUNCTION graba_comprobante_contable()
DEFINE r  RECORD 
	 te_serial		SERIAL,
	 te_cuenta		CHAR(12),
	 te_glosa		CHAR(35),
	 te_tipo_mov		CHAR(1),
	 te_valor		DECIMAL(14,2)
	END RECORD
DEFINE r_ccomp		RECORD LIKE ctbt012.*
DEFINE r_dcomp		RECORD LIKE ctbt013.*
DEFINE r_n03		RECORD LIKE rolt003.*
DEFINE i		SMALLINT

INITIALIZE r_ccomp.* TO NULL
{--
IF vg_codloc <> 3 THEN
	IF vm_cod_liqrol <> 'UT' THEN
		LET r_ccomp.b12_num_comp =
				fl_numera_comprobante_contable(vg_codcia,
					vm_tipo_comp, YEAR(vm_fecha_fin),
					MONTH(vm_fecha_fin))
	ELSE
		LET r_ccomp.b12_num_comp =
				fl_numera_comprobante_contable(vg_codcia,
					vm_tipo_comp, YEAR(TODAY), MONTH(TODAY))
	END IF
ELSE
--}
	IF vm_cod_liqrol = 'Q1' OR vm_cod_liqrol = 'Q2' THEN
		LET r_ccomp.b12_num_comp =
				fl_numera_comprobante_contable(vg_codcia,
					vm_tipo_comp, YEAR(vm_fecha_fin),
					MONTH(vm_fecha_fin))
	ELSE
		LET r_ccomp.b12_num_comp =
				fl_numera_comprobante_contable(vg_codcia,
					vm_tipo_comp, YEAR(TODAY), MONTH(TODAY))
	END IF
--END IF
IF r_ccomp.b12_num_comp = '-1' THEN
	DROP TABLE te_master
	ROLLBACK WORK
	CLOSE WINDOW w_rolf501_1
	EXIT PROGRAM
END IF
CALL fl_lee_proceso_roles(vm_cod_liqrol) RETURNING r_n03.*
LET vm_num_comp			= r_ccomp.b12_num_comp
LET r_ccomp.b12_compania 	= vg_codcia
LET r_ccomp.b12_tipo_comp 	= vm_tipo_comp
LET r_ccomp.b12_estado 		= 'A'
LET r_ccomp.b12_subtipo 	= NULL
LET r_ccomp.b12_fec_proceso 	= vm_fecha_fin
{--
IF vg_codloc <> 3 THEN
	IF vm_cod_liqrol = 'UT' THEN
		LET r_ccomp.b12_fec_proceso = TODAY
	END IF
ELSE
--}
	IF vm_cod_liqrol <> 'Q1' AND vm_cod_liqrol <> 'Q2' THEN
		LET r_ccomp.b12_fec_proceso = TODAY
	END IF
--END IF
LET r_ccomp.b12_glosa		= 'ROL DE PAGO: ', vm_cod_liqrol, ' ',
					r_n03.n03_nombre CLIPPED, ' ',
					vm_fecha_ini USING 'dd-mm-yyyy', ' - ',
					vm_fecha_fin USING 'dd-mm-yyyy'
LET r_ccomp.b12_origen 		= 'A'
LET r_ccomp.b12_moneda 		= rg_gen.g00_moneda_base
LET r_ccomp.b12_paridad 	= 1
LET r_ccomp.b12_modulo	 	= vg_modulo
LET r_ccomp.b12_usuario 	= vg_usuario
LET r_ccomp.b12_fecing 		= CURRENT
INSERT INTO ctbt012 VALUES (r_ccomp.*)
DECLARE q_mast CURSOR FOR SELECT * FROM te_master
	ORDER BY te_serial
LET i = 0
FOREACH q_mast INTO r.*
	INITIALIZE r_dcomp.* TO NULL
	LET i = i + 1
    	LET r_dcomp.b13_compania 	= r_ccomp.b12_compania
    	LET r_dcomp.b13_tipo_comp 	= r_ccomp.b12_tipo_comp
    	LET r_dcomp.b13_num_comp 	= r_ccomp.b12_num_comp
    	LET r_dcomp.b13_secuencia 	= i
    	LET r_dcomp.b13_cuenta 		= r.te_cuenta
    	LET r_dcomp.b13_glosa 		= 'ROL DE PAGO: ', vm_cod_liqrol, ' ', 
					r_n03.n03_nombre CLIPPED, ' ',
					vm_fecha_ini USING 'dd-mm-yyyy', ' - ',
					vm_fecha_fin USING 'dd-mm-yyyy'
					{--
				           MONTH(vm_fecha_ini) USING '&&',  '/',
				           YEAR(vm_fecha_ini) USING '&&&&',
					   ' - ',
				           MONTH(vm_fecha_fin) USING '&&',  '/',
				           YEAR(vm_fecha_fin) USING '&&&&'
					--}
	IF r.te_tipo_mov = 'H' THEN
		LET r.te_valor = r.te_valor * -1
	END IF
    	LET r_dcomp.b13_valor_base 	= r.te_valor
    	LET r_dcomp.b13_valor_aux 	= 0
    	LET r_dcomp.b13_fec_proceso 	= r_ccomp.b12_fec_proceso
    	LET r_dcomp.b13_num_concil 	= NULL
	INSERT INTO ctbt013 VALUES(r_dcomp.*)
END FOREACH
INSERT INTO rolt053
	VALUES (vg_codcia, vm_cod_liqrol, vm_fecha_ini, vm_fecha_fin,
		vm_tipo_comp, vm_num_comp)

END FUNCTION



FUNCTION carga_temporales()
DEFINE r_n33		RECORD
				n33_compania	LIKE rolt033.n33_compania,
				n33_cod_liqrol	LIKE rolt033.n33_cod_liqrol,
				n33_fecha_ini	LIKE rolt033.n33_fecha_ini,
				n33_fecha_fin	LIKE rolt033.n33_fecha_fin,
				n33_cod_trab	LIKE rolt033.n33_cod_trab,
				n33_cod_rubro	LIKE rolt033.n33_cod_rubro,
				n33_det_tot	LIKE rolt033.n33_det_tot,
				n33_cant_valor	LIKE rolt033.n33_cant_valor,
				n33_valor	LIKE rolt033.n33_valor
			END RECORD
DEFINE r_n47		RECORD LIKE rolt047.*
DEFINE mensaje		VARCHAR(160)
DEFINE query		CHAR(2600)
DEFINE valor, tot_neto	DECIMAL(12,2)
DEFINE det_tot		CHAR(2)

LET query = 'SELECT n32_compania, n32_cod_liqrol, n32_fecha_ini, ',
			'n32_fecha_fin, n32_cod_depto, n32_cod_trab, ',
			'n32_tipo_pago, n32_bco_empresa, n32_cta_empresa, ',
			'n32_tot_neto ',
		' FROM rolt032 ',
		' WHERE n32_compania   = ', vg_codcia,
		'   AND n32_cod_liqrol = "', vm_cod_liqrol, '"',
		'   AND n32_fecha_ini  = "', vm_fecha_ini, '"',
		'   AND n32_fecha_fin  = "', vm_fecha_fin, '"',
		' UNION ',
		' SELECT n36_compania n32_compania,n36_proceso n32_cod_liqrol,',
			' n36_fecha_ini n32_fecha_ini, n36_fecha_fin ',
			'n32_fecha_fin, n36_cod_depto n32_cod_depto, ',
			'n36_cod_trab n32_cod_trab, n36_tipo_pago ',
			'n32_tipo_pago, n36_bco_empresa	n32_bco_empresa, ',
			'n36_cta_empresa n32_cta_empresa, n36_valor_bruto ',
			'n32_tot_neto ',
			' FROM rolt036 ',
			' WHERE n36_compania   = ', vg_codcia,
			'   AND n36_proceso    = "', vm_cod_liqrol, '"',
			'   AND n36_fecha_ini  = "', vm_fecha_ini, '"',
			'   AND n36_fecha_fin  = "', vm_fecha_fin, '"',
		' UNION ',
		' SELECT n41_compania n32_compania, "', vm_cod_liqrol, '" ',
			'n32_cod_liqrol, DATE("', vm_fecha_ini, '") ',
			'n32_fecha_ini, DATE("', vm_fecha_fin, '") ',
			'n32_fecha_fin, n42_cod_depto n32_cod_depto, ',
			'n42_cod_trab n32_cod_trab, n42_tipo_pago ',
			'n32_tipo_pago, n42_bco_empresa	n32_bco_empresa, ',
			'n42_cta_empresa n32_cta_empresa, (n42_val_trabaj +',
			'n42_val_cargas) n32_tot_neto ',
			' FROM rolt041, rolt042 ',
			' WHERE n41_compania  = ', vg_codcia,
			'   AND n41_ano       = ', YEAR(vm_fecha_fin),
			'   AND n42_compania  = n41_compania ',
			'   AND n42_proceso   = "', vm_cod_liqrol, '"',
			'   AND n42_fecha_ini = "', vm_fecha_ini, '"',
			'   AND n42_fecha_fin = "', vm_fecha_fin, '"',
			'   AND n42_ano       = n41_ano ',
		' UNION ',
		' SELECT n38_compania n32_compania, "FR" n32_cod_liqrol,',
			' n38_fecha_ini n32_fecha_ini, n38_fecha_fin ',
			'n32_fecha_fin, n30_cod_depto n32_cod_depto, ',
			'n38_cod_trab n32_cod_trab, n30_tipo_pago ',
			'n32_tipo_pago, n30_bco_empresa	n32_bco_empresa, ',
			'n30_cta_empresa n32_cta_empresa, n38_valor_fondo ',
			'n32_tot_neto ',
			' FROM rolt038, rolt030 ',
			' WHERE n38_compania   = ', vg_codcia,
			'   AND n38_fecha_ini  = "', vm_fecha_ini, '"',
			'   AND n38_fecha_fin  = "', vm_fecha_fin, '"',
			'   AND n38_pago_iess  = "S" ',
			'   AND n30_compania   = n38_compania ',
			'   AND n30_cod_trab   = n38_cod_trab ',
		' INTO TEMP temp_cabrol '
PREPARE exec_cab FROM query
EXECUTE exec_cab
LET query = 'SELECT n33_compania, n33_cod_liqrol, n33_fecha_ini, ',
			'n33_fecha_fin, n33_cod_trab, n33_cod_rubro, ',
			'n33_det_tot, n33_cant_valor, n33_valor ',
		' FROM rolt033 ',
		' WHERE n33_compania   = ', vg_codcia,
		'   AND n33_cod_liqrol = "', vm_cod_liqrol, '"',
		'   AND n33_fecha_ini  = "', vm_fecha_ini, '"',
		'   AND n33_fecha_fin  = "', vm_fecha_fin, '"',
		'   AND n33_cant_valor = "V" ',
		'   AND n33_det_tot    IN ("DI", "DE") ',
		'   AND n33_valor      <> 0 ',
		' UNION ',
		' SELECT n37_compania n33_compania, n37_proceso ',
			'n33_cod_liqrol, n37_fecha_ini n33_fecha_ini, ',
			'n37_fecha_fin n33_fecha_fin, n37_cod_trab ',
			'n33_cod_trab, n37_cod_rubro n33_cod_rubro, ',
			'n37_det_tot n33_det_tot, "V" n33_cant_valor, ',
			'n37_valor n33_valor ',
			' FROM rolt037 ',
			' WHERE n37_compania   = ', vg_codcia,
			'   AND n37_proceso    = "', vm_cod_liqrol, '"',
			'   AND n37_fecha_ini  = "', vm_fecha_ini, '"',
			'   AND n37_fecha_fin  = "', vm_fecha_fin, '"',
			'   AND n37_det_tot    IN ("DI", "DE") ',
			'   AND n37_valor      <> 0 ',
		' UNION ',
		' SELECT n49_compania n33_compania, n49_proceso ',
			'n33_cod_liqrol, n49_fecha_ini n33_fecha_ini, ',
			'n49_fecha_fin n33_fecha_fin, n49_cod_trab ',
			'n33_cod_trab, n49_cod_rubro n33_cod_rubro, ',
			'n49_det_tot n33_det_tot, "V" n33_cant_valor, ',
			'n49_valor n33_valor ',
			' FROM rolt049 ',
			' WHERE n49_compania   = ', vg_codcia,
			'   AND n49_proceso    = "', vm_cod_liqrol, '"',
			'   AND n49_fecha_ini  = "', vm_fecha_ini, '"',
			'   AND n49_fecha_fin  = "', vm_fecha_fin, '"',
			'   AND n49_det_tot    IN ("DI", "DE") ',
			'   AND n49_valor      <> 0 ',
		{--
		' SELECT n41_compania n33_compania, "', vm_cod_liqrol, '" ',
			'n33_cod_liqrol, DATE("', vm_fecha_ini, '") ',
			'n33_fecha_ini, DATE("', vm_fecha_fin, '") ',
			'n33_fecha_fin, n42_cod_trab n33_cod_trab, ',
			'(SELECT n06_cod_rubro FROM rolt006 ',
				'WHERE n06_flag_ident = "AN") n33_cod_rubro, ',
			'"DE" n33_det_tot, "V" n33_cant_valor, ',
			'n42_descuentos n33_valor ',
			' FROM rolt041, rolt042 ',
			' WHERE n41_compania = ', vg_codcia,
			'   AND n41_ano      = ', YEAR(vm_fecha_fin),
			'   AND n42_compania = n41_compania ',
			'   AND n42_ano      = n41_ano ',
		--}
		' UNION ',
		' SELECT n38_compania n33_compania, "FR" n33_cod_liqrol,',
			' n38_fecha_ini n33_fecha_ini, n38_fecha_fin ',
			'n33_fecha_fin, n38_cod_trab n33_cod_trab, ',
			'00 n33_cod_rubro, "DE" n33_det_tot, "V" ',
			'n33_cant_valor, n38_valor_fondo n33_valor ',
			' FROM rolt038 ',
			' WHERE n38_compania   = ', vg_codcia,
			'   AND n38_fecha_ini  = "', vm_fecha_ini, '"',
			'   AND n38_fecha_fin  = "', vm_fecha_fin, '"',
			'   AND n38_pago_iess  = "S" ',
		' INTO TEMP temp_detrol '
PREPARE exec_det FROM query
EXECUTE exec_det
DECLARE q_excep CURSOR FOR 
	SELECT * FROM temp_detrol, rolt006
		WHERE n33_cod_rubro   = n06_cod_rubro     -- VACACIONES 
		  AND n06_flag_ident  = 'VV'
		--WHERE n33_cod_rubro = 8 AND        -- VACACIONES QUITO
		  AND n33_valor      <> 0
FOREACH q_excep INTO r_n33.*
	SELECT n33_valor INTO valor FROM temp_detrol, rolt006
		WHERE n33_cod_trab  = r_n33.n33_cod_trab AND 
		      n33_cod_rubro = n06_cod_rubro	-- DESCTOS VACACACIONES.
		  AND n06_flag_ident = 'XV'
	IF STATUS = NOTFOUND OR valor = 0 THEN
		LET mensaje = 'El empleado: ', 
			      r_n33.n33_cod_trab USING '##&', 
			      ' tiene vacaciones pero no otros ',
			      ' descuentos. Revise el rol.'
		CALL fl_mostrar_mensaje(mensaje, 'stop')
		DROP TABLE te_master
		CLOSE WINDOW w_rolf501_1
		EXIT PROGRAM
	END IF
	{--	OJO HASTA SEGUNDA ORDEN
	INITIALIZE r_n47.* TO NULL
	DECLARE q_n47 CURSOR FOR
		SELECT * FROM rolt047
			WHERE n47_compania          = vg_codcia
			  AND n47_cod_liqrol        = r_n33.n33_cod_liqrol
			  AND n47_fecha_ini         = r_n33.n33_fecha_ini
			  AND n47_fecha_fin         = r_n33.n33_fecha_fin
			  AND n47_cod_trab          = r_n33.n33_cod_trab
			  AND YEAR(n47_periodo_fin) < 2009
	OPEN q_n47
	FETCH q_n47 INTO r_n47.*
	CLOSE q_n47
	FREE q_n47
	IF r_n47.n47_compania IS NULL THEN
		UPDATE temp_detrol
			SET n33_valor = n33_valor - (r_n33.n33_valor - valor)
			WHERE n33_cod_trab  = r_n33.n33_cod_trab
			--  AND n33_cod_rubro = 55         -- APORTE IESS
			  AND EXISTS (SELECT * FROM rolt006
					WHERE n06_cod_rubro  = n33_cod_rubro
					  AND n06_flag_ident = 'AP')
		UPDATE temp_detrol
			SET n33_valor = 0
			WHERE n33_cod_trab  = r_n33.n33_cod_trab
			--  AND n33_cod_rubro IN (12,61)
			  AND EXISTS (SELECT * FROM rolt006
					WHERE n06_cod_rubro  = n33_cod_rubro
					  AND n06_flag_ident IN ('VV', 'XV'))
	END IF
	--}
	LET valor = 0
	DECLARE q_veri CURSOR FOR SELECT n33_det_tot, SUM(n33_valor)
		FROM temp_detrol
		WHERE n33_cod_trab = r_n33.n33_cod_trab
		GROUP BY 1
	FOREACH q_veri INTO det_tot, r_n33.n33_valor
		IF det_tot = 'DE' THEN
			LET r_n33.n33_valor = r_n33.n33_valor * -1
		END IF
		LET valor = valor + r_n33.n33_valor
	END FOREACH
	LET tot_neto = 0
	SELECT n32_tot_neto INTO tot_neto
		FROM temp_cabrol
		WHERE n32_cod_trab = r_n33.n33_cod_trab	
	IF tot_neto <> valor THEN
		LET mensaje = 'Al empleado: ', 
			      r_n33.n33_cod_trab USING '##&', 
			      ' no le cuadra el total neto de cabecera ',
			      ' con el calculado del detalle, luego. ',
			      ' de encerar vacaciones. Revise el rol.'
		CALL fl_mostrar_mensaje(mensaje, 'stop')
		DROP TABLE te_master
		CLOSE WINDOW w_rolf501_1
		EXIT PROGRAM
	END IF
END FOREACH

END FUNCTION



FUNCTION lee_conf_adi_cont_rol(codcia, liq, depto, cod_trab)
DEFINE codcia		LIKE rolt056.n56_compania
DEFINE liq		LIKE rolt056.n56_proceso
DEFINE depto		LIKE rolt056.n56_cod_depto
DEFINE cod_trab		LIKE rolt056.n56_cod_trab
DEFINE r_n56		RECORD LIKE rolt056.*

INITIALIZE r_n56.* TO NULL
SELECT * INTO r_n56.*
	FROM rolt056
	WHERE n56_compania  = codcia
	  AND n56_proceso   = liq
	  AND n56_cod_depto = depto
	  AND n56_cod_trab  = cod_trab
	  AND n56_estado    = "A"
RETURN r_n56.*

END FUNCTION



FUNCTION retorna_cuenta_egr(cod_rubro, cod_trab)
DEFINE cod_rubro	LIKE rolt006.n06_cod_rubro
DEFINE cod_trab		LIKE rolt056.n56_cod_trab
DEFINE r_n06		RECORD LIKE rolt006.*
DEFINE r_n30		RECORD LIKE rolt030.*
DEFINE r_n51		RECORD LIKE rolt051.*
DEFINE r_n52		RECORD LIKE rolt052.*
DEFINE cuenta		LIKE ctbt010.b10_cuenta
DEFINE mensaje		VARCHAR(250)

SELECT * INTO r_n52.*
	FROM rolt052
	WHERE n52_compania  = vg_codcia
	  AND n52_cod_rubro = cod_rubro
	  AND n52_cod_trab  = cod_trab  
IF STATUS = NOTFOUND THEN
	CALL fl_lee_rubro_roles(cod_rubro) RETURNING r_n06.*
	IF r_n06.n06_det_tot = 'DI' THEN
		CALL fl_lee_trabajador_roles(vg_codcia, cod_trab)
			RETURNING r_n30.*
		LET mensaje = 'No hay auxiliar contable asociado para el ',
				'código de trabajador: ',
				cod_trab USING "<<<<&", ' ',
				r_n30.n30_nombres CLIPPED, '. Rubro Ingreso: ',
				cod_rubro USING "#&&", ' ',
				r_n06.n06_nombre CLIPPED, '.'
		CALL fl_mostrar_mensaje(mensaje, 'stop')
		DROP TABLE te_master
		CLOSE WINDOW w_rolf501_1
		EXIT PROGRAM
	END IF
	SELECT * INTO r_n51.* FROM rolt051
		WHERE n51_compania  = vg_codcia
		  AND n51_cod_rubro = cod_rubro
	IF STATUS = NOTFOUND THEN
		LET mensaje = 'No hay auxiliar contable asociado para el rubro',
				' de descuento: ', cod_rubro USING '##&'
		CALL fl_mostrar_mensaje(mensaje, 'stop')
		DROP TABLE te_master
		CLOSE WINDOW w_rolf501_1
		EXIT PROGRAM
	END IF
	LET cuenta = r_n51.n51_aux_cont
ELSE
	LET cuenta = r_n52.n52_aux_cont
END IF
RETURN cuenta

END FUNCTION
