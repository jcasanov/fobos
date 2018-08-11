DATABASE aceros


DEFINE base, base1	CHAR(20)
DEFINE codcia		LIKE gent001.g01_compania
DEFINE anio		INTEGER
DEFINE mes		SMALLINT



MAIN

	IF num_args() <> 5 THEN
		DISPLAY 'PARAMETROS INCORRECTOS. SON: BASE SERVIDOR CIA ANIO MES.'
		EXIT PROGRAM
	END IF
	RUN 'clear'
	CALL alzar_base_ser(arg_val(1), arg_val(2))
	LET codcia = arg_val(3)
	LET anio   = arg_val(4)
	LET mes    = arg_val(5)
	CALL regenerar_diario_contable_retencion()
	DISPLAY 'Proceso Terminado OK.'

END MAIN



FUNCTION alzar_base_ser(b, s)
DEFINE b, s		CHAR(20)

LET base  = b
LET base1 = base CLIPPED
LET base  = base CLIPPED, '@', s
CALL activar_base()

END FUNCTION



FUNCTION activar_base()
DEFINE r_g51		RECORD LIKE gent051.*

CLOSE DATABASE
WHENEVER ERROR CONTINUE
DATABASE base
IF STATUS < 0 THEN
	DISPLAY 'No se pudo abrir base de datos: ', base
	EXIT PROGRAM
END IF
WHENEVER ERROR STOP
INITIALIZE r_g51.* TO NULL
SELECT * INTO r_g51.* FROM gent051
	WHERE g51_basedatos = base1
IF r_g51.g51_basedatos IS NULL THEN
	DISPLAY 'No existe base de datos: ', base1
	EXIT PROGRAM
END IF

END FUNCTION



FUNCTION regenerar_diario_contable_retencion()
DEFINE r_j14		RECORD LIKE cajt014.*
DEFINE r_b12_a		RECORD LIKE ctbt012.*
DEFINE r_b12_n		RECORD LIKE ctbt012.*
DEFINE r_z40		RECORD LIKE cxct040.*
DEFINE tp_nue		LIKE ctbt012.b12_tipo_comp
DEFINE num_nue		LIKE ctbt012.b12_num_comp
DEFINE fecha		DATE
DEFINE i		SMALLINT

CREATE TEMP TABLE tmp_dia
	(
		cia		INTEGER,
		tipo		CHAR(2),
		num		CHAR(8),
		tipo_n		CHAR(2),
		num_n		CHAR(8)
	)
LET fecha = MDY(mes, 01, anio)
DISPLAY 'Obteniendo diarios contables para cambio fecha proceso con fecha retencion...'
INSERT INTO tmp_dia
	(cia, tipo, num)
	SELECT UNIQUE b12_compania, b12_tipo_comp, b12_num_comp
		FROM cajt014, cajt010, cxct022, cxct040, ctbt012
		WHERE j14_compania    = codcia
		  AND j14_tipo_fuente = 'SC'
		  AND EXTEND(j14_fecha_emi, YEAR TO MONTH)   >= '2009-11'
		  AND EXTEND(j14_fecing, YEAR TO MONTH)      =
			EXTEND(fecha, YEAR TO MONTH)
		  AND j10_compania    = j14_compania
		  AND j10_localidad   = j14_localidad
		  AND j10_tipo_fuente = j14_tipo_fuente
		  AND j10_num_fuente  = j14_num_fuente
		  AND z22_compania    = j10_compania
		  AND z22_localidad   = j10_localidad
		  AND z22_codcli      = j10_codcli
		  AND z22_tipo_trn    = j10_tipo_destino
		  AND z22_num_trn     = j10_num_destino
		  AND z40_compania    = z22_compania
		  AND z40_localidad   = z22_localidad
		  AND z40_codcli      = z22_codcli
		  AND z40_tipo_doc    = z22_tipo_trn
		  AND z40_num_doc     = z22_num_trn
		  AND b12_compania    = z40_compania
		  AND b12_tipo_comp   = z40_tipo_comp
		  AND b12_num_comp    = z40_num_comp
		  AND EXTEND(b12_fec_proceso, YEAR TO MONTH) <>
			EXTEND(j14_fec_emi_fact, YEAR TO MONTH)
		  AND EXTEND(b12_fec_proceso, YEAR TO MONTH) <>
			EXTEND(j14_fecha_emi, YEAR TO MONTH)
DECLARE q_ret_dia CURSOR WITH HOLD FOR
	SELECT cajt014.*, cxct040.*, ctbt012.*
		FROM cajt014, cajt010, cxct022, cxct040, ctbt012
		WHERE j14_compania    = codcia
		  AND j14_tipo_fuente = 'SC'
		  AND EXTEND(j14_fecha_emi, YEAR TO MONTH)   >= '2009-11'
		  AND EXTEND(j14_fecing, YEAR TO MONTH)      =
			EXTEND(fecha, YEAR TO MONTH)
		  AND j10_compania    = j14_compania
		  AND j10_localidad   = j14_localidad
		  AND j10_tipo_fuente = j14_tipo_fuente
		  AND j10_num_fuente  = j14_num_fuente
		  AND z22_compania    = j10_compania
		  AND z22_localidad   = j10_localidad
		  AND z22_codcli      = j10_codcli
		  AND z22_tipo_trn    = j10_tipo_destino
		  AND z22_num_trn     = j10_num_destino
		  AND z40_compania    = z22_compania
		  AND z40_localidad   = z22_localidad
		  AND z40_codcli      = z22_codcli
		  AND z40_tipo_doc    = z22_tipo_trn
		  AND z40_num_doc     = z22_num_trn
		  AND b12_compania    = z40_compania
		  AND b12_tipo_comp   = z40_tipo_comp
		  AND b12_num_comp    = z40_num_comp
		  AND EXTEND(b12_fec_proceso, YEAR TO MONTH) <>
			EXTEND(j14_fec_emi_fact, YEAR TO MONTH)
		  AND EXTEND(b12_fec_proceso, YEAR TO MONTH) <>
			EXTEND(j14_fecha_emi, YEAR TO MONTH)
		ORDER BY j14_fec_emi_fact DESC, j14_fecha_emi
DISPLAY ' '
LET i = 0
DISPLAY 'Generando nuevos diarios contables...'
DISPLAY ' '
FOREACH q_ret_dia INTO r_j14.*, r_z40.*, r_b12_a.*
	INITIALIZE tp_nue, num_nue TO NULL
	SELECT tipo_n, num_n
		INTO tp_nue, num_nue
		FROM tmp_dia
		WHERE cia  = r_b12_a.b12_compania
		  AND tipo = r_b12_a.b12_tipo_comp
		  AND num  = r_b12_a.b12_num_comp
	IF tp_nue IS NOT NULL THEN
		BEGIN WORK
			UPDATE cajt014
				SET j14_tipo_comp = tp_nue,
				    j14_num_comp  = num_nue
				WHERE j14_compania    = r_j14.j14_compania
				  AND j14_localidad   = r_j14.j14_localidad
				  AND j14_tipo_fuente = r_j14.j14_tipo_fuente
				  AND j14_num_fuente  = r_j14.j14_num_fuente
				  AND j14_secuencia   = r_j14.j14_secuencia
				  AND j14_codigo_pago = r_j14.j14_codigo_pago
				  AND j14_num_ret_sri = r_j14.j14_num_ret_sri
				  AND j14_sec_ret     = r_j14.j14_sec_ret
		COMMIT WORK
		DISPLAY ' +', r_b12_n.b12_tipo_comp, '-', r_b12_n.b12_num_comp,
		' Ret: ', r_j14.j14_num_ret_sri CLIPPED,
		' Fec: ', r_j14.j14_fecha_emi USING "dd-mm-yyyy", ' ',
		r_j14.j14_cod_tran, '-', r_j14.j14_num_tran USING "<<<<<<&",
		' Fec: ', r_j14.j14_fec_emi_fact USING "dd-mm-yyyy"
		CONTINUE FOREACH
	END IF
	BEGIN WORK
		IF EXTEND(r_j14.j14_fec_emi_fact, YEAR TO MONTH) = '2009-10' OR
		  (EXTEND(r_j14.j14_fec_emi_fact, YEAR TO MONTH) <> 
		   EXTEND(r_j14.j14_fecha_emi, YEAR TO MONTH))
		THEN
			LET fecha = r_j14.j14_fecha_emi
		ELSE
			LET fecha = r_j14.j14_fec_emi_fact
		END IF
		CALL generando_nuevo_diaro(r_b12_a.*, fecha) RETURNING r_b12_n.*
		UPDATE tmp_dia
			SET tipo_n = r_b12_n.b12_tipo_comp,
			    num_n  = r_b12_n.b12_num_comp
			WHERE cia  = r_b12_a.b12_compania
			  AND tipo = r_b12_a.b12_tipo_comp
			  AND num  = r_b12_a.b12_num_comp
		UPDATE cajt014
			SET j14_tipo_comp = r_b12_n.b12_tipo_comp,
			    j14_num_comp  = r_b12_n.b12_num_comp
			WHERE j14_compania    = r_j14.j14_compania
			  AND j14_localidad   = r_j14.j14_localidad
			  AND j14_tipo_fuente = r_j14.j14_tipo_fuente
			  AND j14_num_fuente  = r_j14.j14_num_fuente
			  AND j14_secuencia   = r_j14.j14_secuencia
			  AND j14_codigo_pago = r_j14.j14_codigo_pago
			  AND j14_num_ret_sri = r_j14.j14_num_ret_sri
			  AND j14_sec_ret     = r_j14.j14_sec_ret
		UPDATE cxct040
			SET z40_tipo_comp = r_b12_n.b12_tipo_comp,
			    z40_num_comp  = r_b12_n.b12_num_comp
			WHERE z40_compania  = r_z40.z40_compania
			  AND z40_localidad = r_z40.z40_localidad
			  AND z40_codcli    = r_z40.z40_codcli
			  AND z40_tipo_doc  = r_z40.z40_tipo_doc
			  AND z40_num_doc   = r_z40.z40_num_doc
	COMMIT WORK
	DISPLAY '  ', r_b12_n.b12_tipo_comp, '-', r_b12_n.b12_num_comp,
		' Ret: ', r_j14.j14_num_ret_sri CLIPPED,
		' Fec: ', r_j14.j14_fecha_emi USING "dd-mm-yyyy", ' ',
		r_j14.j14_cod_tran, '-', r_j14.j14_num_tran USING "<<<<<<&",
		' Fec: ', r_j14.j14_fec_emi_fact USING "dd-mm-yyyy"
	CALL fl_mayoriza_comprobante(r_b12_n.b12_compania,r_b12_n.b12_tipo_comp,
					r_b12_n.b12_num_comp, 'M')
	CALL fl_mayoriza_comprobante(r_b12_a.b12_compania,r_b12_a.b12_tipo_comp,
					r_b12_a.b12_num_comp, 'D')
	BEGIN WORK
		SET LOCK MODE TO WAIT 5
		UPDATE ctbt012
			SET b12_estado     = 'E',
			    b12_fec_modifi = CURRENT
			WHERE b12_compania  = r_b12_a.b12_compania
			  AND b12_tipo_comp = r_b12_a.b12_tipo_comp
			  AND b12_num_comp  = r_b12_a.b12_num_comp
	COMMIT WORK
	LET i = i + 1
END FOREACH
DROP TABLE tmp_dia
DISPLAY ' '
DISPLAY ' Se cambiaron fecha un total de ', i USING "<<<&",
	' diarios contables OK.'
DISPLAY ' '

END FUNCTION



FUNCTION generando_nuevo_diaro(r_b12, fecha)
DEFINE r_b12		RECORD LIKE ctbt012.*
DEFINE fecha		LIKE cajt014.j14_fecha_emi
DEFINE r_b13		RECORD LIKE ctbt013.*
DEFINE tipo_comp	LIKE ctbt012.b12_tipo_comp
DEFINE num_comp		LIKE ctbt012.b12_num_comp

LET tipo_comp = r_b12.b12_tipo_comp
LET num_comp  = r_b12.b12_num_comp
DECLARE q_b13 CURSOR WITH HOLD FOR
	SELECT * FROM ctbt013
		WHERE b13_compania  = r_b12.b12_compania
		  AND b13_tipo_comp = tipo_comp
		  AND b13_num_comp  = num_comp
		ORDER BY b13_secuencia
LET r_b12.b12_num_comp    = fl_numera_comprobante_contable(r_b12.b12_compania,
				r_b12.b12_tipo_comp, YEAR(fecha), MONTH(fecha))
LET r_b12.b12_fec_proceso = fecha
LET r_b12.b12_estado      = 'A'
INSERT INTO ctbt012 VALUES(r_b12.*)
FOREACH q_b13 INTO r_b13.*
	LET r_b13.b13_num_comp    = r_b12.b12_num_comp
	LET r_b13.b13_fec_proceso = r_b12.b12_fec_proceso
	INSERT INTO ctbt013 VALUES(r_b13.*)
END FOREACH
RETURN r_b12.*

END FUNCTION
