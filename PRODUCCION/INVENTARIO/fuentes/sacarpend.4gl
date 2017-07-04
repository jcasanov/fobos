DATABASE aceros


GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE codcia		LIKE gent001.g01_compania
DEFINE codloc		LIKE gent002.g02_localidad
DEFINE base		CHAR(20)
DEFINE tot_cant_fact	INTEGER



MAIN

	DEFER QUIT
	DEFER INTERRUPT
	CLEAR SCREEN
	--#CALL fgl_init4js()
	CALL fl_marca_registrada_producto()
	IF num_args() <> 2 THEN
		CALL fl_mostrar_mensaje('Número de parametros incorrecto. SON BASE y LOCALIDAD', 'stop')
		EXIT PROGRAM
	END IF
	LET base       = arg_val(1)
	LET codcia     = 1
	LET codloc     = arg_val(2)
	CALL fl_activar_base_datos(base)
	LET vg_usuario = 'FOBOS'
	CALL ejecuta_proceso()

END MAIN



FUNCTION ejecuta_proceso()
DEFINE comando		CHAR(100)
DEFINE resul		SMALLINT
DEFINE r_report		RECORD
				cod_tran	LIKE rept020.r20_cod_tran,
				num_tran	LIKE rept020.r20_num_tran,
				fecha_tran	DATE,
				num_ord_des	LIKE rept034.r34_num_ord_des,
				bodega		LIKE rept020.r20_bodega,
				item		LIKE rept020.r20_item,
				canti		DECIMAL(10,2)
			END RECORD

CALL fl_nivel_isolation()
CALL ejecuta_query() RETURNING resul
IF NOT resul THEN
	RETURN
END IF
LET vg_gui = 1
CALL fl_control_reportes() RETURNING comando
IF int_flag THEN
	RETURN
END IF
DECLARE q_t4 CURSOR FOR
	SELECT * FROM t4 ORDER BY r20_bodega, r20_num_tran DESC
START REPORT report_pendientes TO PIPE comando
LET tot_cant_fact = 0
FOREACH q_t4 INTO r_report.*
	OUTPUT TO REPORT report_pendientes(r_report.*)
END FOREACH
FINISH REPORT report_pendientes

END FUNCTION



FUNCTION ejecuta_query()
DEFINE cuantos		INTEGER
DEFINE cod_bod		LIKE rept002.r02_codigo

SELECT r20_cod_tran, r20_num_tran, DATE(r20_fecing) fecha, r20_bodega,
	r20_item, r20_cant_ven, r19_tipo_dev
	FROM rept020, rept019
	WHERE r20_compania  = 15
	  AND r20_localidad = 19
	  AND r20_cod_tran  = 'FA'
	  AND r19_compania  = r20_compania
	  AND r19_localidad = r20_localidad
	  AND r19_cod_tran  = r20_cod_tran
	  AND r19_num_tran  = r20_num_tran
	  AND (r19_tipo_dev IS NULL OR r19_tipo_dev = 'DF')
	INTO TEMP t1
DECLARE q_bd CURSOR FOR
	SELECT r02_codigo FROM rept002
		WHERE r02_compania  = codcia
		  AND r02_localidad = codloc
		  AND r02_estado    = 'A'
		  AND r02_area      = 'R'
		  AND r02_factura   = 'S'
		  AND r02_tipo	    = 'S'
FOREACH q_bd INTO cod_bod
	INSERT INTO t1
		SELECT r20_cod_tran, r20_num_tran, DATE(r20_fecing) fecha,
			r20_bodega, r20_item, r20_cant_ven, r19_tipo_dev
			FROM rept020, rept019
			WHERE r20_compania  = codcia
			  AND r20_localidad = codloc
			  AND r20_cod_tran  = 'FA'
			  AND r20_bodega    = cod_bod
			  AND r19_compania  = r20_compania
			  AND r19_localidad = r20_localidad
			  AND r19_cod_tran  = r20_cod_tran
			  AND r19_num_tran  = r20_num_tran
			  AND (r19_tipo_dev IS NULL OR r19_tipo_dev = 'DF')
END FOREACH
SELECT r20_cod_tran, r20_num_tran, fecha, r20_bodega, r20_item, r20_cant_ven,
	r19_tipo_dev, r34_num_ord_des
	FROM t1, rept034
	WHERE r34_compania  = codcia
	  AND r34_localidad = codloc
	  AND r34_cod_tran  = r20_cod_tran
	  AND r34_num_tran  = r20_num_tran
	  AND r34_bodega    = r20_bodega
	  AND r34_estado    IN ('A', 'P')
	INTO TEMP t2
DROP TABLE t1
SELECT COUNT(*) INTO cuantos FROM t2
IF cuantos = 0 THEN
	CALL fl_mostrar_mensaje('No existe nada pendiente.', 'exclamation')
	RETURN 0
END IF
SELECT UNIQUE r35_num_ord_des, r20_bodega bodega, r20_item item,
	SUM(r35_cant_des - r35_cant_ent) cantidad
	FROM t2, rept035
	WHERE r35_compania    = codcia
	  AND r35_localidad   = codloc
	  AND r35_bodega      = r20_bodega
	  AND r35_item        = r20_item
	  AND r35_num_ord_des = r34_num_ord_des
	GROUP BY 1, 2, 3
	HAVING SUM(r35_cant_des - r35_cant_ent) > 0
	INTO TEMP t3
SELECT UNIQUE r20_cod_tran, r20_num_tran, fecha, r35_num_ord_des, r20_bodega,
	r20_item, cantidad cant_fin
	FROM t2, t3
	WHERE r20_bodega      = bodega
	  AND r20_item        = item
	  AND r35_num_ord_des = r34_num_ord_des
	INTO TEMP t4
DROP TABLE t2
DROP TABLE t3
SELECT COUNT(*) INTO cuantos FROM t4
IF cuantos = 0 THEN
	CALL fl_mostrar_mensaje('No existe nada pendiente ni a nivel de Item.', 'exclamation')
	RETURN 0
END IF
RETURN 1

END FUNCTION



REPORT report_pendientes(r_report)
DEFINE r_report		RECORD
				cod_tran	LIKE rept020.r20_cod_tran,
				num_tran	LIKE rept020.r20_num_tran,
				fecha_tran	DATE,
				num_ord_des	LIKE rept034.r34_num_ord_des,
				bodega		LIKE rept020.r20_bodega,
				item		LIKE rept020.r20_item,
				canti		DECIMAL(10,2)
			END RECORD
DEFINE modulo		VARCHAR(40)
DEFINE factura		VARCHAR(15)
DEFINE cant_fact	INTEGER
DEFINE r_g01		RECORD LIKE gent001.*
DEFINE r_r02		RECORD LIKE rept002.*

OUTPUT
	TOP MARGIN	1
	LEFT MARGIN	0
	RIGHT MARGIN	80
	BOTTOM MARGIN	4
	PAGE LENGTH	66

FORMAT

PAGE HEADER
	CALL fl_lee_compania(codcia) RETURNING r_g01.*
	LET modulo  = "MODULO: INVENTARIO"
	PRINT COLUMN 001, r_g01.g01_razonsocial,
  	      COLUMN 070, "PAGINA: ", PAGENO USING "&&&"
	PRINT COLUMN 001, modulo CLIPPED,
	      COLUMN 032, 'DETALLE DE ITEMS PENDIENTES'
	SKIP 1 LINES
	PRINT COLUMN 022, "** FECHA INICIAL : ", MDY(01, 01, 2003)
							USING "dd-mm-yyyy"
	PRINT COLUMN 022, "** FECHA FINAL   : ", TODAY
							USING "dd-mm-yyyy"
	SKIP 1 LINES
	PRINT COLUMN 001, "FECHA IMPRESION: ", TODAY USING "dd-mm-yyyy",
 		1 SPACES, TIME
	PRINT "--------------------------------------------------------------------------------"
	PRINT COLUMN 004, "F A C T U R A S",
	      COLUMN 023, "FECHA",
	      COLUMN 035, "ORDEN DES.",
	      COLUMN 054, "ITEMS",
	      COLUMN 072, " CANTIDAD"
	PRINT "--------------------------------------------------------------------------------"

BEFORE GROUP OF r_report.bodega
	LET cant_fact = 0
	CALL fl_lee_bodega_rep(codcia, r_report.bodega) RETURNING r_r02.*
	NEED 8 LINES
	PRINT COLUMN 001, r_report.bodega,
	      COLUMN 004, r_r02.r02_nombre
	SKIP 1 LINES

ON EVERY ROW
	NEED 6 LINES
	LET factura = r_report.num_tran
	CALL fl_justifica_titulo('I', factura, 15) RETURNING factura
	PRINT COLUMN 004, r_report.cod_tran, '-',
	      COLUMN 007, factura,
	      COLUMN 023, r_report.fecha_tran	USING "dd-mm-yyyy",
	      COLUMN 035, r_report.num_ord_des	USING "<<<<<<<<<&",
	      COLUMN 054, r_report.item,
	      COLUMN 072, r_report.canti	USING "--,--&.##"
	
AFTER GROUP OF r_report.bodega
	NEED 5 LINES
	SKIP 1 LINES
	SELECT UNIQUE r20_num_tran FROM t4
		WHERE r20_bodega = r_report.bodega INTO TEMP caca
	SELECT COUNT(*) INTO cant_fact FROM caca
	DROP TABLE caca
	PRINT COLUMN 003, "TOTAL FACTURA BODEGA ", r_report.bodega, " ==> ",
	      cant_fact USING "<<<<<<&"
	LET tot_cant_fact = tot_cant_fact + cant_fact
	SKIP 1 LINES

ON LAST ROW
	NEED 2 LINES
	SKIP 1 LINES
	PRINT COLUMN 003, "TOTAL FACTURAS          ==> ",
		tot_cant_fact USING "<<<<<<&"

END REPORT
