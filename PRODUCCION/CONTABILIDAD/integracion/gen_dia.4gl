GLOBALS "globales.4gl"

DEFINE vm_mes, vm_ano   SMALLINT
DEFINE mes, anio        SMALLINT
DEFINE tit_mes		CHAR(11)



MAIN
                                                                                
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/gen_dia.err')
LET vg_base     = 'acero_gm'
LET vg_modulo   = 'RE'
LET vg_codcia   = 1
LET vg_codloc   = 1
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
CALL fl_lee_configuracion_facturacion() RETURNING rg_gen.*
OPEN WINDOW w_mas AT 4, 2 WITH 20 ROWS, 78 COLUMNS
    ATTRIBUTE(FORM LINE FIRST + 2, COMMENT LINE LAST, MENU LINE FIRST,BORDER,
	      MESSAGE LINE LAST - 2)
OPTIONS INPUT WRAP,
	ACCEPT KEY	F12
OPEN FORM f_ctb FROM "f_gen_dia"
DISPLAY FORM f_ctb
LET vm_ano = YEAR(TODAY)
LET vm_mes = MONTH(TODAY)
CALL fl_retorna_nombre_mes(vm_mes) RETURNING tit_mes
DISPLAY BY NAME tit_mes
CALL leer_ano_mes()
CALL contabilizacion_inv()
CALL contabilizacion_pagos()
LET vg_codloc   = 2
CALL contabilizacion_pagos()
--CALL contabilizacion_taller()
                                                                                
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
CALL contabilizacion_inv()
CALL contabilizacion_pagos()
LET vg_codloc   = 2
CALL contabilizacion_pagos()

END FUNCTION



FUNCTION contabilizacion_inv()
DEFINE r		RECORD LIKE rept019.*
DEFINE r_r40		RECORD LIKE rept040.*
DEFINE i		SMALLINT
DEFINE a		CHAR(5)

SET ISOLATION TO DIRTY READ
DECLARE q1 CURSOR WITH HOLD FOR SELECT * FROM rept019
	WHERE r19_compania = vg_codcia AND r19_localidad = vg_codloc
	      AND YEAR(r19_fecing) = vm_ano AND
	      MONTH(r19_fecing) = vm_mes AND
	      r19_cod_tran IN ('FA','DF','AF','CL','DC','IM','RQ','DR','AC','TR')
	ORDER by r19_fecing
LET i = 0
FOREACH q1 INTO r.*
	DECLARE qr CURSOR WITH HOLD FOR
		SELECT * FROM rept040
		WHERE r40_compania  = r.r19_compania  AND 
		      r40_localidad = r.r19_localidad AND
                      r40_cod_tran  = r.r19_cod_tran  AND  
                      r40_num_tran  = r.r19_num_tran  
	OPEN qr
	FETCH qr INTO r_r40.*
	IF status <> NOTFOUND THEN
		CONTINUE FOREACH
	END IF		
	{- NO PUEDE CONBILIZAR ESTAS 2 TRANSACCIONES PORQUE TIENEN MONEDA BV -}
	IF r.r19_cod_tran = 'CL' AND r.r19_num_tran = 1269 THEN
		CONTINUE FOREACH
	END IF
	IF r.r19_cod_tran = 'DC' AND r.r19_num_tran = 14 THEN
		CONTINUE FOREACH
	END IF
	{-- --}
	LET i = i + 1
	DISPLAY '*** ', r.r19_cod_tran, ' ', r.r19_num_tran
	CALL fl_control_master_contab_repuestos(r.r19_compania, r.r19_localidad,
             r.r19_cod_tran, r.r19_num_tran)
END FOREACH
DISPLAY 'Comprobante(s) contable(s) inventario generado(s): ', i USING '##&'
IF num_args() <> 2 THEN
	SLEEP 2
END IF

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



FUNCTION contabilizacion_pagos()
DEFINE r		RECORD LIKE cajt010.*
DEFINE r_z40		RECORD LIKE cxct040.*
DEFINE num		INTEGER
DEFINE i		SMALLINT
DEFINE a		SMALLINT

SET ISOLATION TO DIRTY READ
DECLARE q2 CURSOR WITH HOLD FOR SELECT * FROM cajt010
	WHERE j10_compania = vg_codcia AND j10_localidad = vg_codloc AND 
	      j10_tipo_destino IN ('PG','PA') AND 
	      YEAR(j10_fecha_pro) = vm_ano AND 
	      MONTH(j10_fecha_pro) = vm_mes
	ORDER BY j10_fecha_pro
LET i = 0
FOREACH q2 INTO r.*
	LET num = r.j10_num_destino
	DECLARE q_pg CURSOR WITH HOLD FOR
		SELECT * FROM cxct040
		WHERE z40_compania  = r.j10_compania  AND 
		      z40_localidad = r.j10_localidad AND
                      z40_codcli    = r.j10_codcli    AND  
                      z40_tipo_doc  = r.j10_tipo_destino AND
                      z40_num_doc   = num  
	OPEN q_pg
	FETCH q_pg INTO r_z40.*
	IF status <> NOTFOUND THEN
		CONTINUE FOREACH
	END IF		
	LET i = i + 1
	DISPLAY r.j10_tipo_destino, ' ', r.j10_num_destino
	CALL fl_control_master_contab_ingresos_caja(vg_codcia, vg_codloc, 
		r.j10_tipo_fuente, r.j10_num_fuente)
END FOREACH
DISPLAY 'Comprobante(s) contable(s) PG/PA generado(s): ', i USING '##&'
IF num_args() <> 2 THEN
	LET a = fgl_getkey()
END IF

END FUNCTION



FUNCTION contabilizacion_taller()
DEFINE orden		LIKE talt023.t23_orden
DEFINE fecha		LIKE talt023.t23_fec_factura
DEFINE i		SMALLINT

SET ISOLATION TO DIRTY READ
DECLARE q_tal CURSOR WITH HOLD FOR SELECT t23_orden, t23_fec_factura 
	FROM talt023
	WHERE t23_compania  = vg_codcia AND 
	      t23_localidad = vg_codloc AND
	      t23_estado IN ('F','D')   AND
	      t23_num_factura >= 37     AND  
	      t23_num_factura <= 39
	ORDER BY 2
FOREACH q_tal INTO orden, fecha
	DISPLAY orden, ' F'
	CALL fl_control_master_contab_taller(vg_codcia, vg_codloc, orden, 'F')
END FOREACH
{
DECLARE q_dev CURSOR WITH HOLD FOR SELECT t28_ot_ant, t28_fec_anula FROM talt028
	WHERE t28_compania  = vg_codcia AND 
	      t28_localidad = vg_codloc
	ORDER BY 2
LET i = 1
FOREACH q_dev INTO orden, fecha
	DISPLAY orden, ' D'
	CALL fl_control_master_contab_taller(vg_codcia, vg_codloc, orden, 'D')
END FOREACH
}
	
END FUNCTION
