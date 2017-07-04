DATABASE aceros


DEFINE vg_codcia	LIKE gent001.g01_compania
DEFINE vg_codloc	LIKE gent002.g02_localidad
DEFINE base_ori		CHAR(20)
DEFINE serv_ori		CHAR(20)


MAIN

	IF num_args() <> 4 THEN
		DISPLAY 'Parametros Incorrectos. SON: BASE SERVIDOR COMPANIA',
			' LOCALIDAD.'
		EXIT PROGRAM
	END IF
	LET base_ori  = arg_val(1)
	LET serv_ori  = arg_val(2)
	LET vg_codcia = arg_val(3)
	LET vg_codloc = arg_val(4)
	CALL activar_base(base_ori, serv_ori)
	BEGIN WORK
		CALL ejecuta_proceso()
	COMMIT WORK
	DISPLAY "Ajustes Generados OK"

END MAIN



FUNCTION activar_base(b, s)
DEFINE b, s		CHAR(20)
DEFINE base, base1	CHAR(20)
DEFINE r_g51		RECORD LIKE gent051.*

LET base  = b
LET base1 = base CLIPPED, '@', s
CLOSE DATABASE
WHENEVER ERROR CONTINUE
DATABASE base1
IF STATUS < 0 THEN
	DISPLAY 'No se pudo abrir base de datos: ', base1
	EXIT PROGRAM
END IF
WHENEVER ERROR STOP
INITIALIZE r_g51.* TO NULL
SELECT * INTO r_g51.* FROM gent051 WHERE g51_basedatos = base
IF r_g51.g51_basedatos IS NULL THEN
	DISPLAY 'No existe base de datos: ', base
	EXIT PROGRAM
END IF

END FUNCTION



FUNCTION ejecuta_proceso()
DEFINE r_z20		RECORD LIKE cxct020.*
DEFINE r_z22, r_z22_o	RECORD LIKE cxct022.*
DEFINE r_z23, r_z23_o	RECORD LIKE cxct023.*
DEFINE fecing		LIKE cxct022.z22_fecing
DEFINE valor		LIKE cxct020.z20_valor_cap
DEFINE saldo		LIKE cxct020.z20_saldo_cap
DEFINE i		SMALLINT

DISPLAY "Seleccionando AJ para revertirlos. Por favor espere ..."
DISPLAY " "
DECLARE q_z22 CURSOR FOR
	SELECT * FROM cxct022
		WHERE z22_compania  = 1
		  AND z22_localidad = 1
		  AND z22_tipo_trn  = "AJ"
		{--
		  AND z22_num_trn   IN (15166, 15167, 15168, 15169, 15170,
					15171, 15172, 15173, 15174, 15175,
					15177, 15179, 15180, 15181, 15182,15184)
		--}
		  AND z22_num_trn   = 15679
		ORDER BY z22_num_trn ASC
LET i      = 0
LET fecing = DATE(MDY(12, 31, 2011))
LET fecing = fecing + 15 UNITS HOUR + 54 UNITS MINUTE
FOREACH q_z22 INTO r_z22_o.*
	INITIALIZE r_z22.*, r_z23.* TO NULL
	LET r_z22.* = r_z22_o.*
	CALL actualiza_control_secuencias(r_z22.z22_compania,
					r_z22.z22_localidad, 'CO', 'AA',
					r_z22.z22_tipo_trn)
		RETURNING r_z22.z22_num_trn
	IF r_z22.z22_num_trn <= 0 THEN
		DISPLAY "    ERROR: ", r_z22_o.z22_tipo_trn, "-",
			r_z22_o.z22_num_trn USING "<<<<<<&"
		ROLLBACK WORK
		EXIT PROGRAM
	END IF
	LET r_z22.z22_referencia = "REVERSADO: ", r_z22_o.z22_tipo_trn, "-",
					r_z22_o.z22_num_trn USING "<<<<<<&"
	DISPLAY "  REVERSANDO: ", r_z22_o.z22_tipo_trn, "-",
		r_z22_o.z22_num_trn USING "<<<<<<&", "  CLIENTE: ",
		r_z22_o.z22_codcli USING "<<<<&"
	LET r_z22.z22_fecha_emi = DATE(MDY(12, 31, 2011))
	LET r_z22.z22_total_cap = r_z22.z22_total_cap * (-1)
	LET r_z22.z22_total_int = r_z22.z22_total_int * (-1)
	LET r_z22.z22_fecing    = fecing
	LET fecing              = fecing + 1 UNITS SECOND
	INSERT INTO cxct022 VALUES (r_z22.*)
	DECLARE q_z23 CURSOR FOR
		SELECT * INTO r_z23.*
			FROM cxct023
			WHERE z23_compania  = r_z22_o.z22_compania
			  AND z23_localidad = r_z22_o.z22_localidad
			  AND z23_codcli    = r_z22_o.z22_codcli
			  AND z23_tipo_trn  = r_z22_o.z22_tipo_trn
			  AND z23_num_trn   = r_z22_o.z22_num_trn
			ORDER BY z23_orden ASC
	FOREACH q_z23 INTO r_z23_o.*
		LET r_z23.z23_compania   = r_z22.z22_compania
		LET r_z23.z23_localidad  = r_z22.z22_localidad
		LET r_z23.z23_codcli     = r_z22.z22_codcli
		LET r_z23.z23_tipo_trn   = r_z22.z22_tipo_trn
		LET r_z23.z23_num_trn    = r_z22.z22_num_trn
		LET r_z23.z23_orden      = r_z23_o.z23_orden
		LET r_z23.z23_areaneg    = r_z23_o.z23_areaneg
		LET r_z23.z23_tipo_doc   = r_z23_o.z23_tipo_doc
		LET r_z23.z23_num_doc    = r_z23_o.z23_num_doc
		LET r_z23.z23_div_doc    = r_z23_o.z23_div_doc
		LET r_z23.z23_tipo_favor = r_z23_o.z23_tipo_favor
		LET r_z23.z23_doc_favor  = r_z23_o.z23_doc_favor
		LET r_z23.z23_valor_cap  = r_z23_o.z23_valor_cap * (-1)
		LET r_z23.z23_valor_int  = r_z23_o.z23_valor_int * (-1)
		LET r_z23.z23_valor_mora = r_z23_o.z23_valor_mora
		WHENEVER ERROR CONTINUE
		DECLARE q_up CURSOR FOR
			SELECT * FROM cxct020
				WHERE z20_compania  = r_z23_o.z23_compania
				  AND z20_localidad = r_z23_o.z23_localidad
				  AND z20_codcli    = r_z23_o.z23_codcli
				  AND z20_tipo_doc  = r_z23.z23_tipo_doc
				  AND z20_num_doc   = r_z23.z23_num_doc
				  AND z20_dividendo = r_z23.z23_div_doc
			FOR UPDATE
		OPEN q_up
		FETCH q_up INTO r_z20.*
		IF STATUS = NOTFOUND THEN
			ROLLBACK WORK
			DISPLAY '    ERROR: ', r_z23.z23_tipo_doc, ' ',
				r_z23.z23_num_doc CLIPPED, ' ',
				r_z23.z23_div_doc USING "<<&&",
				'. Documento no encontrado.'
			WHENEVER ERROR STOP
			EXIT PROGRAM
		END IF
		IF STATUS < 0 THEN
			ROLLBACK WORK
			DISPLAY '    ERROR: ', r_z23.z23_tipo_doc, ' ',
				r_z23.z23_num_doc CLIPPED, ' ',
				r_z23.z23_div_doc USING "<<&&",
				'. Documento bloqueado.'
			WHENEVER ERROR STOP
			EXIT PROGRAM
		END IF
		LET valor = (r_z23.z23_valor_cap + r_z23.z23_valor_int)
		LET saldo = (r_z20.z20_saldo_cap + r_z20.z20_saldo_int)
		IF (saldo > 0) AND (valor > saldo) THEN
			ROLLBACK WORK
			DISPLAY '    ERROR: ', r_z23.z23_tipo_doc, ' ',
				r_z23.z23_num_doc CLIPPED, ' ',
				r_z23.z23_div_doc USING "<<&&",
			'. El Ajuste tiene un valor ', valor
			USING "---,---,--&.&&",
			' que el saldo ', saldo USING "---,---,--&.&&"
			WHENEVER ERROR STOP
			EXIT PROGRAM
		END IF
		WHENEVER ERROR STOP
		LET r_z23.z23_valor_int = r_z20.z20_saldo_int
		IF r_z23.z23_valor_cap < 0 THEN
			LET r_z23.z23_valor_int = r_z23.z23_valor_int * (-1)
		END IF
		LET r_z23.z23_valor_cap = r_z20.z20_saldo_int
                			+ r_z23.z23_valor_cap
		LET r_z22.z22_total_cap = r_z22.z22_total_cap
					+ r_z23.z23_valor_cap
		LET r_z22.z22_total_int = r_z22.z22_total_int
					+ r_z23.z23_valor_int
		WHENEVER ERROR CONTINUE
		SET LOCK MODE TO WAIT 1
		INSERT INTO cxct023
			VALUES(r_z23.z23_compania, r_z23.z23_localidad,
				r_z23.z23_codcli, r_z23.z23_tipo_trn,
				r_z23.z23_num_trn, r_z23.z23_orden,
				r_z23.z23_areaneg, r_z23.z23_tipo_doc,
				r_z23.z23_num_doc, r_z23.z23_div_doc,
				r_z23.z23_tipo_favor, r_z23.z23_doc_favor,
				r_z23.z23_valor_cap, r_z23.z23_valor_int,
				r_z23.z23_valor_mora, r_z20.z20_saldo_cap,
				r_z20.z20_saldo_int)
		IF STATUS <> 0 THEN
			DISPLAY '    ERROR: ', r_z23.z23_tipo_doc, ' ',
				r_z23.z23_num_doc CLIPPED, ' ',
				r_z23.z23_div_doc USING "<<&&",
				'. El Ajuste no pudo realizarse. '
			ROLLBACK WORK
			WHENEVER ERROR STOP
			EXIT PROGRAM
		END IF
		WHENEVER ERROR CONTINUE
		SET LOCK MODE TO WAIT 1
		UPDATE cxct020
			SET z20_saldo_cap = z20_saldo_cap
				+ r_z23.z23_valor_cap,
			    z20_saldo_int = z20_saldo_int
				+ r_z23.z23_valor_int
			WHERE CURRENT OF q_up
		IF STATUS <> 0 THEN
			DISPLAY '    ERROR: ', r_z23.z23_tipo_doc, ' ',
				r_z23.z23_num_doc CLIPPED, ' ',
				r_z23.z23_div_doc USING "<<&&",
				'. No pudo actualizarse el saldo. '
			ROLLBACK WORK
			WHENEVER ERROR STOP
			EXIT PROGRAM
		END IF
		WHENEVER ERROR STOP
		DISPLAY '  PROCESADO: ', r_z23.z23_tipo_doc, ' ',
			r_z23.z23_num_doc CLIPPED, ' ',
			r_z23.z23_div_doc USING "<<&&"
		CLOSE q_up
		FREE q_up
	END FOREACH
	WHENEVER ERROR CONTINUE
	DECLARE q_up2 CURSOR FOR
		SELECT * FROM cxct022
			WHERE z22_compania  = r_z22.z22_compania
			  AND z22_localidad = r_z22.z22_localidad
			  AND z22_codcli    = r_z22.z22_codcli
			  AND z22_tipo_trn  = r_z22.z22_tipo_trn
			  AND z22_num_trn   = r_z22.z22_num_trn
		FOR UPDATE
	OPEN q_up2
	FETCH q_up2 INTO r_z22.*
	IF STATUS < 0 THEN
		ROLLBACK WORK
		DISPLAY "    ERROR: ", r_z22.z22_tipo_trn, "-",
			r_z22.z22_num_trn USING "<<<<<<&",
			'. No se puede actualizar los totales.'
		WHENEVER ERROR STOP
		EXIT PROGRAM
	END IF
	WHENEVER ERROR STOP
	UPDATE cxct022
		SET z22_total_cap = r_z22.z22_total_cap,
		    z22_total_int = r_z22.z22_total_int
		WHERE CURRENT OF q_up2
	CLOSE q_up2
	FREE q_up2
	DISPLAY "  REGENERADO: ", r_z22.z22_tipo_trn, "-",
		r_z22.z22_num_trn USING "<<<<<<&", "  OK"
	DISPLAY " "
	LET i = i + 1
END FOREACH
DISPLAY "Se regeneraron un total de ", i USING "<<<&", " ajuste OK"

END FUNCTION



FUNCTION actualiza_control_secuencias(cod_cia, cod_loc, modulo, bodega, tipo)
DEFINE cod_cia		LIKE gent015.g15_compania
DEFINE cod_loc		LIKE gent015.g15_localidad
DEFINE modulo		LIKE gent015.g15_modulo
DEFINE bodega		LIKE gent015.g15_bodega
DEFINE tipo		LIKE gent015.g15_tipo
DEFINE r		RECORD LIKE gent015.* 
DEFINE mensaje		VARCHAR(60)

WHENEVER ERROR CONTINUE
SET LOCK MODE TO WAIT 5
DECLARE q_csec CURSOR FOR
	SELECT * FROM gent015
	WHERE g15_compania  = cod_cia AND 
	      g15_localidad = cod_loc AND 
	      g15_modulo    = modulo  AND 
	      g15_bodega    = bodega  AND 
	      g15_tipo      = tipo
	FOR UPDATE 
OPEN q_csec
FETCH q_csec INTO r.*
IF status = NOTFOUND THEN
	LET mensaje = 'No existe control secuencia en gent015: ',
		       cod_cia USING '##', ' ', cod_loc USING '##', ' ', 
		       modulo, ' ', bodega, ' ', tipo
	DISPLAY mensaje CLIPPED
	LET r.g15_numero = 0
ELSE
	IF status < 0 THEN
		DISPLAY 'Secuencia está bloqueada por otro proceso.'
		LET r.g15_numero = -1
	ELSE
		LET r.g15_numero = r.g15_numero + 1
		UPDATE gent015 SET g15_numero = r.g15_numero
			WHERE CURRENT OF q_csec
		IF status < 0 THEN
			DISPLAY 'No se actualizó control secuencia.'
			LET r.g15_numero = -1
		END IF
	END IF
END IF
WHENEVER ERROR STOP
SET LOCK MODE TO NOT WAIT
RETURN r.g15_numero

END FUNCTION
