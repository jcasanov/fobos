DATABASE aceros


DEFINE codcia		LIKE gent001.g01_compania
DEFINE codloc		LIKE gent002.g02_localidad
DEFINE servidor		CHAR(20)
DEFINE base, base1	CHAR(20)



MAIN

	IF num_args() <> 2 THEN
		DISPLAY 'Error de Parametros. Falta la Servidor_base Localidad.'
		EXIT PROGRAM
	END IF
	LET codcia   = 1
	LET servidor = arg_val(1)
	LET codloc   = arg_val(2)
	CASE codloc
		WHEN 1
			LET base1 = 'acero_gm'
		WHEN 2
			LET base1 = 'acero_gc'
		WHEN 3
			LET base1 = 'acero_qm'
		WHEN 4
			LET base1 = 'acero_qs'
	END CASE
	LET base = base1 CLIPPED, '@', servidor CLIPPED
	CALL activar_base()
	CALL validar_parametros()
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
SELECT * INTO r_g51.* FROM gent051 WHERE g51_basedatos = base1
IF r_g51.g51_basedatos IS NULL THEN
	DISPLAY 'No existe base de datos: ', base1
	EXIT PROGRAM
END IF

END FUNCTION



FUNCTION validar_parametros()
DEFINE r_g02		RECORD LIKE gent002.*

INITIALIZE r_g02.* TO NULL
SELECT * INTO r_g02.* FROM gent002
	WHERE g02_compania  = codcia
	  AND g02_localidad = codloc
IF r_g02.g02_compania IS NULL THEN
	DISPLAY 'No existe la Localidad ', codloc USING '<<&', '.'
	EXIT PROGRAM
END IF

END FUNCTION



FUNCTION ejecutar_proceso()

DISPLAY "Iniciando reproceso de actualización estado parcial OD, espere ..."
CALL actualizar_estado_de_parcial_despachado_bod_sinstock()
DISPLAY " "
DISPLAY "Reproceso Terminado OK"

END FUNCTION



FUNCTION actualizar_estado_de_parcial_despachado_bod_sinstock()
DEFINE r_r02		RECORD LIKE rept002.*
DEFINE r_r34		RECORD LIKE rept034.*
DEFINE r_r35		RECORD LIKE rept035.*
DEFINE bodega		LIKE rept002.r02_codigo
DEFINE item_dev		LIKE rept010.r10_codigo
DEFINE cont_item_ent	SMALLINT
DEFINE cont_item_dev	SMALLINT
DEFINE actualizar, i	SMALLINT

INITIALIZE r_r02.* TO NULL
SELECT * INTO r_r02.* FROM rept002
	WHERE r02_compania  = codcia
	  AND r02_localidad = codloc
	  AND r02_tipo      = 'S'
	  AND r02_factura   = 'S'
IF r_r02.r02_compania IS NULL THEN
	DISPLAY "No existe configurada la bodega sin stock."
	EXIT PROGRAM
END IF
DISPLAY " "
DISPLAY "Obteniendo OD parciales de bodega sin stock ..."
BEGIN WORK
DECLARE q_r34_est CURSOR FOR
	SELECT * FROM rept034
		WHERE r34_compania  = codcia
		  AND r34_localidad = codloc
		  AND r34_bodega    = r_r02.r02_codigo
		  AND r34_estado    = "P"
		ORDER BY r34_num_ord_des
OPEN q_r34_est
FETCH q_r34_est INTO r_r34.*
IF STATUS = NOTFOUND THEN
	CLOSE q_r34_est
	FREE q_r34_est
	ROLLBACK WORK
	DISPLAY " "
	DISPLAY "No existen OD parciales de bodega sin stock."
	EXIT PROGRAM
END IF
LET i = 0
DISPLAY " "
FOREACH q_r34_est INTO r_r34.*
	DISPLAY "Chequenado OD. ", r_r34.r34_num_ord_des USING "<<<<<&",
		" de la Factura ", r_r34.r34_num_tran USING "<<<<<&",
		". Por favor espere ..."
	LET actualizar = 0
	DECLARE q_r35_est CURSOR FOR
		SELECT * FROM rept035
			WHERE r35_compania                = r_r34.r34_compania
			  AND r35_localidad               = r_r34.r34_localidad
			  AND r35_bodega                  = r_r34.r34_bodega
			  AND r35_num_ord_des            = r_r34.r34_num_ord_des
			  AND r35_cant_des - r35_cant_ent > 0
	OPEN q_r35_est
	FETCH q_r35_est INTO r_r35.*
	IF STATUS = NOTFOUND THEN
		DISPLAY "  OD. ", r_r34.r34_num_ord_des USING "<<<<<&",
			" de la Factura ", r_r34.r34_num_tran USING "<<<<<&",
			" no tiene nada pendiente."
		LET actualizar = 1
	END IF
	LET cont_item_ent = 0
	LET cont_item_dev = 0
	FOREACH q_r35_est INTO r_r35.*
		LET cont_item_ent = cont_item_ent + 1
		INITIALIZE item_dev TO NULL
		SELECT UNIQUE r20_item INTO item_dev
			FROM rept019, rept020
			WHERE r19_compania  = codcia
			  AND r19_localidad = codloc
			  AND r19_tipo_dev  = r_r34.r34_cod_tran
			  AND r19_num_dev   = r_r34.r34_num_tran
			  AND r20_compania  = r19_compania
			  AND r20_localidad = r19_localidad
			  AND r20_cod_tran  = r19_cod_tran
			  AND r20_num_tran  = r19_num_tran
			  AND r20_bodega    = r_r35.r35_bodega
			  AND r20_item      = r_r35.r35_item
		IF item_dev IS NOT NULL THEN
			LET cont_item_dev = cont_item_dev + 1
		END IF
	END FOREACH
	IF cont_item_dev = cont_item_ent AND cont_item_ent <> 0 THEN
		LET actualizar = 1
	END IF
	IF NOT actualizar THEN
		DISPLAY "  OD. ", r_r34.r34_num_ord_des USING "<<<<<&",
			" de la Factura ", r_r34.r34_num_tran USING "<<<<<&",
			" no se actualizó  Ok."
		DISPLAY " "
		CONTINUE FOREACH
	END IF
	UPDATE rept034 SET r34_estado = "D"
		WHERE r34_compania    = r_r34.r34_compania
		  AND r34_localidad   = r_r34.r34_localidad
		  AND r34_bodega      = r_r34.r34_bodega
		  AND r34_num_ord_des = r_r34.r34_num_ord_des
	IF STATUS < 0 THEN
		ROLLBACK WORK
		DISPLAY "  ERROR: OD. ", r_r34.r34_num_ord_des USING "<<<<<&",
			" de la Factura ", r_r34.r34_num_tran USING "<<<<<&",
			" no se actualizó."
		DISPLAY " "
		DISPLAY "Reproceso no pudo Terminar Correctamente."
		EXIT PROGRAM
	END IF
	DISPLAY "  Se actualizó el estado de OD. ",
		r_r34.r34_num_ord_des USING "<<<<<&", " de la Factura ",
		r_r34.r34_num_tran USING "<<<<<&", " Ok."
	DISPLAY " "
	LET i = i + 1
END FOREACH
COMMIT WORK
IF i > 0 THEN
	DISPLAY "Se actualizaron ", i USING "<<<&", " Ordenes de Despacho  Ok."
ELSE
	DISPLAY "No se actualizó ninguna Orden de Despacho  Ok."
END IF

END FUNCTION
