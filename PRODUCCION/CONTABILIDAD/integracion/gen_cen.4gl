GLOBALS "globales.4gl"

DEFINE vm_mes, vm_ano   SMALLINT
DEFINE mes, anio        SMALLINT
DEFINE tit_mes		CHAR(11)



MAIN
                                                                                
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/gen_cen.err')
LET vg_base     = 'acero_gm'
LET vg_modulo   = 'RE'
LET vg_codcia   = 1
LET vg_codloc   = 2
LET vg_usuario  = 'FOBOS'
CALL fl_activar_base_datos(vg_base)
IF num_args() <> 0 AND num_args() <> 2 THEN
	DISPLAY 'Número de Parametros Incorrectos. Son: AÑO y MES o Nada'
	EXIT PROGRAM
END IF
IF num_args() = 2 THEN
	CALL llamada_con_parametros()
	EXIT PROGRAM
END IF
OPEN WINDOW w_mas AT 4, 2 WITH 20 ROWS, 78 COLUMNS
    ATTRIBUTE(FORM LINE FIRST + 2, COMMENT LINE LAST, MENU LINE FIRST,BORDER,
	      MESSAGE LINE LAST - 2)
OPTIONS INPUT WRAP,
	ACCEPT KEY	F12
OPEN FORM f_ctb FROM "f_gen_cen"
DISPLAY FORM f_ctb
CALL fl_lee_configuracion_facturacion() RETURNING rg_gen.*
LET vm_ano = YEAR(TODAY)
LET vm_mes = MONTH(TODAY)
CALL fl_retorna_nombre_mes(vm_mes) RETURNING tit_mes
DISPLAY BY NAME tit_mes
UPDATE acero_gc:rept019 SET r19_bodega_ori = '70' 
	WHERE r19_cod_tran IN ('FA','DF','AF')
CALL leer_ano_mes()
CALL contabilizacion_inv()

END MAIN



FUNCTION llamada_con_parametros()
DEFINE fecha		DATE

CALL fl_lee_configuracion_facturacion() RETURNING rg_gen.*
LET vm_ano = arg_val(1)
LET vm_mes = arg_val(2)
IF DAY(TODAY) = 1 THEN
	LET fecha  = TODAY - 1 UNITS DAY
	LET vm_ano = YEAR(fecha)
	LET vm_mes = MONTH(fecha)
END IF
UPDATE acero_gc:rept019 SET r19_bodega_ori = '70' 
	WHERE r19_cod_tran IN ('FA','DF','AF')
CALL contabilizacion_inv()

END FUNCTION



FUNCTION leer_ano_mes()
DEFINE fecha		DATE

LET int_flag = 0
OPTIONS INPUT NO WRAP
INPUT BY NAME vm_ano, vm_mes WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		LET int_flag = 1
		EXIT PROGRAM
	BEFORE FIELD vm_ano
		LET anio = vm_ano
	BEFORE FIELD vm_mes
		LET mes = vm_mes
	AFTER FIELD vm_ano
		IF vm_ano IS NOT NULL THEN
			IF vm_ano > year(TODAY) THEN
				MESSAGE 'Año de proceso está incorrecto.'
				NEXT FIELD vm_ano
			END IF
		ELSE
			LET vm_ano = anio
			DISPLAY BY NAME vm_ano
		END IF
	AFTER FIELD vm_mes
		IF vm_mes IS NOT NULL THEN
			CALL fl_retorna_nombre_mes(vm_mes) RETURNING tit_mes
			DISPLAY BY NAME tit_mes
			LET fecha = mdy(vm_mes, day(TODAY), vm_ano)
			IF fecha > TODAY THEN
				MESSAGE 'Mes está incorrecto.'
				NEXT FIELD vm_mes
			END IF
		ELSE
			LET vm_mes = mes
			DISPLAY BY NAME vm_mes
			CALL fl_retorna_nombre_mes(vm_mes) RETURNING tit_mes
			DISPLAY BY NAME tit_mes
		END IF
END INPUT

END FUNCTION



FUNCTION contabilizacion_inv()
DEFINE r		RECORD LIKE rept019.*
DEFINE r_r40		RECORD LIKE rept040.*
DEFINE i		SMALLINT
DEFINE a		SMALLINT

SET ISOLATION TO DIRTY READ
DECLARE q1 CURSOR WITH HOLD FOR SELECT * FROM acero_gc:rept019
	WHERE r19_compania = vg_codcia AND r19_localidad = vg_codloc AND 
	      r19_cod_tran IN ('FA','DF','AF') AND YEAR(r19_fecing) = vm_ano AND
	      MONTH(r19_fecing) = vm_mes
	ORDER by r19_fecing
LET i = 0
FOREACH q1 INTO r.*
	DECLARE q2 CURSOR WITH HOLD FOR
		SELECT * FROM rept040
		WHERE r40_compania  = r.r19_compania  AND 
		      r40_localidad = r.r19_localidad AND
                      r40_cod_tran  = r.r19_cod_tran  AND  
                      r40_num_tran  = r.r19_num_tran  
	OPEN q2
	FETCH q2 INTO r_r40.*
	IF status <> NOTFOUND THEN
		CONTINUE FOREACH
	END IF		
	LET i = i + 1
	DISPLAY r.r19_cod_tran, ' ', r.r19_num_tran, ' ', r.r19_localidad
	CALL fl_control_master_contab_repuestos(r.r19_compania, r.r19_localidad,
             r.r19_cod_tran, r.r19_num_tran)
END FOREACH
DISPLAY 'Comprobante(s) contable(s) generado(s): ', i USING '##&'
IF num_args() <> 2 THEN
	LET a = fgl_getkey()
END IF

END FUNCTION
