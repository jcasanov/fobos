DATABASE aceros



DEFINE base		CHAR(20)
DEFINE codcia		LIKE gent001.g01_compania
DEFINE codloc		LIKE gent002.g02_localidad



MAIN

	IF num_args() <> 2 THEN
		DISPLAY 'Parametros Incorrectos. Son: BASE y LOCALIDAD.'
		EXIT PROGRAM
	END IF
	LET base   = arg_val(1)
	LET codcia = 1
	LET codloc = arg_val(2)
	CALL activar_base()
	CALL ejecutar_proceso()

END MAIN



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
	WHERE g51_basedatos = base
IF r_g51.g51_basedatos IS NULL THEN
	DISPLAY 'No existe base de datos: ', base
	EXIT PROGRAM
END IF

END FUNCTION



FUNCTION ejecutar_proceso()
DEFINE r_r19		RECORD LIKE rept019.*
DEFINE orden		LIKE talt023.t23_orden
DEFINE i, j		SMALLINT

CALL cargar_datos()
BEGIN WORK
DECLARE q_mostrar CURSOR FOR SELECT * FROM tmp_trans ORDER BY 1, 2
LET i = 0
LET j = 0
FOREACH q_mostrar INTO r_r19.r19_compania, r_r19.r19_localidad,
			r_r19.r19_cod_tran, r_r19.r19_num_tran,
			r_r19.r19_ord_trabajo, orden, r_r19.r19_referencia
	DISPLAY 'Trans. ',  r_r19.r19_cod_tran, '-',
		r_r19.r19_num_tran USING "<<<<<<<<<&", '  O.T. Nueva ',
		r_r19.r19_ord_trabajo USING "<<<<<<<<<&", '  O.T. Dev. ',
		orden USING "<<<<<<<<<&"
	LET i = i + 1
	IF r_r19.r19_ord_trabajo = orden THEN
		CONTINUE FOREACH
	END IF
	UPDATE rept019 SET r19_ord_trabajo = orden
		WHERE r19_compania  = r_r19.r19_compania
		  AND r19_localidad = r_r19.r19_localidad
		  AND r19_cod_tran  = r_r19.r19_cod_tran
		  AND r19_num_tran  = r_r19.r19_num_tran
	DISPLAY '   Actualizando Trans. ',  r_r19.r19_cod_tran, '-',
		r_r19.r19_num_tran USING "<<<<<<<<<&", '  O.T. Nueva ',
		r_r19.r19_ord_trabajo USING "<<<<<<<<<&", '  con O.T. Dev. ',
		orden USING "<<<<<<<<<&"
	LET j = j + 1
END FOREACH
DROP TABLE tmp_trans
COMMIT WORK
DISPLAY ' '
DISPLAY 'Total de Transacciones   ', i USING "<<<&"
DISPLAY 'Total de Actualizaciones ', j USING "<<<&"
DISPLAY ' '
DISPLAY 'Proceso Terminado OK.'

END FUNCTION



FUNCTION cargar_datos()
DEFINE orden		LIKE talt023.t23_orden
DEFINE orden_n		LIKE talt023.t23_orden
DEFINE referencia	LIKE rept019.r19_referencia
DEFINE orden_t		VARCHAR(15)
DEFINE cuantas		INTEGER
DEFINE pos_ini, pos_fin	SMALLINT

SELECT * FROM talt023
	WHERE t23_compania  = codcia
	  AND t23_localidad = codloc
	  AND t23_estado    = 'D'
	INTO TEMP tmp_orden
DELETE FROM tmp_orden
	WHERE t23_compania  = codcia
	  AND t23_localidad = codloc
	  AND t23_orden     NOT IN (SELECT r21_num_ot FROM rept021
					WHERE r21_compania  = t23_compania
					  AND r21_localidad = t23_localidad
					  AND r21_num_ot    IS NOT NULL)
SELECT COUNT(*) INTO cuantas FROM tmp_orden
DISPLAY ' '
DISPLAY 'Hay en total: ', cuantas USING "<<<<&", ' Ordenes de Trabajo.'
DISPLAY ' '
DISPLAY 'Obteniendo las transacciones perdidas ... Por favor espere. '
DISPLAY ' '
DISPLAY 'Facturas --> '
SELECT r19_compania, r19_localidad, r19_cod_tran, r19_num_tran, r19_ord_trabajo,
	t23_orden, r19_referencia
	FROM tmp_orden, rept021, rept019
	WHERE t23_compania  = codcia
	  AND t23_localidad = codloc
	  AND r21_compania  = t23_compania
	  AND r21_localidad = t23_localidad
	  AND r21_num_ot    = t23_orden
	  AND r19_compania  = r21_compania
	  AND r19_localidad = r21_localidad
	  AND r19_cod_tran  = r21_cod_tran
	  AND r19_num_tran  = r21_num_tran
	INTO TEMP tmp_trans
DROP TABLE tmp_orden
DISPLAY ' '
DISPLAY 'Devolución/Anulación --> '
INSERT INTO tmp_trans
	SELECT b.r19_compania, b.r19_localidad, b.r19_cod_tran, b.r19_num_tran,
		b.r19_ord_trabajo, a.t23_orden, b.r19_referencia
		FROM tmp_trans a, rept019 b
		WHERE a.r19_compania  = codcia
		  AND a.r19_localidad = codloc
		  AND a.r19_cod_tran  = 'FA'
		  AND b.r19_compania  = a.r19_compania
		  AND b.r19_localidad = a.r19_localidad
		  AND b.r19_tipo_dev  = a.r19_cod_tran
		  AND b.r19_num_dev   = a.r19_num_tran
DISPLAY ' '
DISPLAY 'Transferencias --> '
INSERT INTO tmp_trans
	SELECT r19_compania, r19_localidad, r19_cod_tran, r19_num_tran,
		r19_ord_trabajo, t28_ot_ant, r19_referencia
		FROM rept019, talt028
		WHERE r19_compania    = codcia 
		  AND r19_localidad   = codloc 
		  AND r19_cod_tran    = 'TR'
		  AND r19_ord_trabajo IS NOT NULL
		  AND t28_compania    = r19_compania
		  AND t28_localidad   = r19_localidad
		  AND t28_ot_nue      = r19_ord_trabajo
DECLARE q_caca CURSOR FOR
	SELECT t23_orden, r19_referencia
		FROM tmp_trans
		WHERE r19_cod_tran = 'TR'
FOREACH q_caca INTO orden, referencia
	LET orden_t = orden
	LET pos_fin = LENGTH(orden_t)
	IF referencia[1, 6] = "O.T.: " THEN
		LET pos_ini = 7
	END IF
	IF referencia[1, 26] = "MATERIAL SOBRANTE DE O.T. " THEN
		LET pos_ini = 27
	END IF
	LET pos_fin = pos_ini + pos_fin - 1
	LET orden_n = referencia[pos_ini, pos_fin]
	IF orden <> orden_n THEN
		UPDATE tmp_trans SET t23_orden = orden_n
			WHERE r19_cod_tran   = 'TR'
			  AND r19_referencia = referencia
			  AND t23_orden      = orden
	END IF
END FOREACH
DISPLAY ' '
DISPLAY ' '

END FUNCTION
