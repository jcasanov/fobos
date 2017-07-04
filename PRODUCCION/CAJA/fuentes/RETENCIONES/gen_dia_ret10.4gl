DATABASE aceros


DEFINE base, base1	CHAR(20)
DEFINE codcia		LIKE gent001.g01_compania



MAIN

	IF num_args() <> 3 THEN
		DISPLAY 'PARAMETROS INCORRECTOS. SON: BASE SERVIDOR CIA.'
		EXIT PROGRAM
	END IF
	RUN 'clear'
	CALL alzar_base_ser(arg_val(1), arg_val(2))
	LET codcia = arg_val(3)
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
DEFINE r_j14		RECORD
				j14_compania	LIKE cajt014.j14_compania,
				j14_localidad	LIKE cajt014.j14_localidad,
				j14_tipo_fuente	LIKE cajt014.j14_tipo_fuente,
				j14_num_fuente	LIKE cajt014.j14_num_fuente,
				j14_secuencia	LIKE cajt014.j14_secuencia,
				j14_codigo_pago	LIKE cajt014.j14_codigo_pago,
				j14_num_ret_sri	LIKE cajt014.j14_num_ret_sri,
				j14_fecha_emi	LIKE cajt014.j14_fecha_emi,
				j14_cod_tran	LIKE cajt014.j14_cod_tran,
				j14_num_tran	LIKE cajt014.j14_num_tran,
				j14_fec_emi_fact LIKE cajt014.j14_fec_emi_fact
			END RECORD
DEFINE r_b12_a		RECORD LIKE ctbt012.*
DEFINE r_b12_n		RECORD LIKE ctbt012.*
DEFINE r_z40		RECORD LIKE cxct040.*
DEFINE tp_nue		LIKE ctbt012.b12_tipo_comp
DEFINE num_nue		LIKE ctbt012.b12_num_comp
DEFINE fec2		LIKE ctbt012.b12_fecing
DEFINE fecha		DATE
DEFINE i		SMALLINT

CREATE TEMP TABLE tmp_dia
	(
		cia		INTEGER,
		tipo		CHAR(2),
		num		CHAR(8),
		fec_ret		DATE,
		fecing		DATETIME YEAR TO SECOND
	)
DISPLAY 'Obteniendo diarios contables para cambio fecha proceso con fecha retencion...'
LOAD FROM "diario_ret.unl" INSERT INTO tmp_dia
SELECT cxct040.*, ctbt012.*, fec_ret, fecing
	FROM tmp_dia, cxct040, ctbt012
	WHERE cia           = codcia
	  AND z40_compania  = cia
	  AND z40_tipo_comp = tipo
	  AND z40_num_comp  = num
	  AND b12_compania  = z40_compania
	  AND b12_tipo_comp = z40_tipo_comp
	  AND b12_num_comp  = z40_num_comp
	INTO TEMP t1
DECLARE q_ret_dia CURSOR WITH HOLD FOR
	SELECT j14_compania, j14_localidad, j14_tipo_fuente, j14_num_fuente,
		j14_secuencia, j14_codigo_pago, j14_num_ret_sri, j14_fecha_emi,
		j14_cod_tran, j14_num_tran, j14_fec_emi_fact, t1.*
		FROM t1, cajt010, cajt014
		WHERE j10_compania     = z40_compania
		  AND j10_localidad    = z40_localidad
		  AND j10_tipo_destino = z40_tipo_doc
		  AND j10_num_destino  = z40_num_doc
		  AND j14_compania     = j10_compania
		  AND j14_localidad    = j10_localidad
		  AND j14_tipo_fuente  = j10_tipo_fuente
		  AND j14_num_fuente   = j10_num_fuente
		ORDER BY fecing, fec_ret
DISPLAY ' '
LET i = 0
DISPLAY 'Generando nuevos diarios contables...'
DISPLAY ' '
FOREACH q_ret_dia INTO r_j14.*, r_z40.*, r_b12_a.*, fecha, fec2
	BEGIN WORK
		CALL generando_nuevo_diaro(r_b12_a.*, fecha, fec2)
			RETURNING r_b12_n.*
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
DROP TABLE t1
DROP TABLE tmp_dia
DISPLAY ' '
DISPLAY ' Se cambiaron fecha un total de ', i USING "<<<&",
	' diarios contables OK.'
DISPLAY ' '

END FUNCTION



FUNCTION generando_nuevo_diaro(r_b12, fecha, fec2)
DEFINE r_b12		RECORD LIKE ctbt012.*
DEFINE fecha		LIKE cajt014.j14_fecha_emi
DEFINE fec2		LIKE ctbt012.b12_fecing
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
LET r_b12.b12_fecing      = fec2
INSERT INTO ctbt012 VALUES(r_b12.*)
FOREACH q_b13 INTO r_b13.*
	LET r_b13.b13_num_comp    = r_b12.b12_num_comp
	LET r_b13.b13_fec_proceso = r_b12.b12_fec_proceso
	INSERT INTO ctbt013 VALUES(r_b13.*)
END FOREACH
RETURN r_b12.*

END FUNCTION
