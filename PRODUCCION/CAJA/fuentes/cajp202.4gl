-------------------------------------------------------------------------------
-- Titulo               : cajp202.4gl -- CIERRE DE CAJA
-- Elaboración          : 20-DIC-2001
-- Autor                : GVA
-- Formato de Ejecución : fglrun  cajp202 base modulo compania localidad 
-- Ultima Correción     : 20-DIC-2001
-- Motivo Corrección    : 1
--------------------------------------------------------------------------------
                                                                                
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'
                                                                                
DEFINE rm_j04   	RECORD LIKE cajt004.*
DEFINE rm_j02   	RECORD LIKE cajt002.*
DEFINE vm_detalle	SMALLINT
DEFINE vm_size_arr	INTEGER
DEFINE r_detalle	ARRAY[100] OF RECORD
	g13_nombre	LIKE gent013.g13_nombre,
	efectivo 	LIKE cajt005.j05_ef_apertura,
	cheque		LIKE cajt005.j05_ch_apertura,
	total		LIKE cajt005.j05_ef_apertura
	END RECORD



MAIN
                                                                                
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/cajp202.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 THEN
     	--CALL FGL_WINMESSAGE(vg_producto,'Número de parámetros incorrecto','stop')
	CALL fl_mostrar_mensaje('Número de parámetros incorrecto.','stop')
     	EXIT PROGRAM
END IF
LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_codcia   = arg_val(3)
LET vg_codloc   = arg_val(4)
LET vg_proceso = 'cajp202'

CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()
--#CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)

CALL funcion_master()
                                                                                
END MAIN



FUNCTION funcion_master()
DEFINE flag		SMALLINT
DEFINE lin_menu		SMALLINT
DEFINE row_ini  	SMALLINT
DEFINE num_rows 	SMALLINT
DEFINE num_cols 	SMALLINT

CALL fl_nivel_isolation()

LET lin_menu = 0
LET row_ini  = 3
LET num_rows = 20
LET num_cols = 80
IF vg_gui = 0 THEN
	LET lin_menu = 1
	LET row_ini  = 4
	LET num_rows = 20
	LET num_cols = 78
END IF
OPEN WINDOW w_202 AT row_ini, 2 WITH num_rows ROWS, num_cols COLUMNS
    ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE lin_menu,BORDER,
	      MESSAGE LINE LAST - 1)
IF vg_gui = 1 THEN
        OPEN FORM f_200 FROM '../forms/cajf202_1'
ELSE
        OPEN FORM f_200 FROM '../forms/cajf202_1c'
END IF
DISPLAY FORM f_200

CALL control_DISPLAY_botones()

INITIALIZE rm_j04.*, rm_j02.* TO NULL

MENU 'OPCIONES'
	BEFORE MENU
		HIDE OPTION 'Ver Detalle'
		LET flag = control_validar_cierre()
		IF flag = 0 THEN
			HIDE OPTION 'Cerrar'
		END IF
		CALL retorna_arreglo()
		IF vm_detalle > vm_size_arr THEN
			SHOW OPTION 'Ver Detalle'
		END IF

	COMMAND KEY('V') 'Ver Detalle' 'Ver Detalle del cierre.'
		CALL control_DISPLAY_array_cajt005()

	COMMAND KEY('C') 'Cerrar' 	
		LET flag = control_cerrar()
		IF flag THEN
			EXIT PROGRAM
		END IF

	COMMAND KEY('S') 'Salir' 	
		EXIT MENU

END MENU

END FUNCTION



FUNCTION control_DISPLAY_botones()
	
	--#DISPLAY 'Moneda' 	 TO tit_col1
	--#DISPLAY 'Efectivo'	 TO tit_col2
	--#DISPLAY 'Cheque'  	 TO tit_col3
	--#DISPLAY 'Total'	 	 TO tit_col4

END FUNCTION



FUNCTION control_DISPLAY_array_cajt005()

CALL set_count(vm_detalle)
DISPLAY ARRAY r_detalle TO r_detalle.* 
        ON KEY(INTERRUPT)
                EXIT DISPLAY
        ON KEY(F1,CONTROL-W)
		CALL llamar_visor_teclas()
        --#BEFORE DISPLAY
                --#CALL dialog.keysetlabel('ACCEPT','')
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
        --#AFTER DISPLAY
                --#CONTINUE DISPLAY
END DISPLAY

END FUNCTION



FUNCTION control_validar_cierre()
DEFINE r_g13		RECORD LIKE gent013.*
DEFINE r_j05		RECORD LIKE cajt005.*
DEFINE i 		SMALLINT

CALL fl_retorna_caja(vg_codcia, vg_codloc, vg_usuario)
	RETURNING rm_j02.*

IF rm_j02.j02_usua_caja IS NULL THEN
	--CALL FGL_WINMESSAGE(vg_producto,'El usuario no tiene asignada una caja.','exclamation')
	CALL fl_mostrar_mensaje('El usuario no tiene asignada una caja.','exclamation')
	RETURN 0
END IF

CALL retorna_arreglo()
FOR i = 1 TO vm_size_arr
	INITIALIZE r_detalle[i].* TO NULL
END FOR

SELECT * INTO rm_j04.* FROM cajt004
	WHERE j04_compania     = vg_codcia
	  AND j04_localidad    = vg_codloc
	  AND j04_codigo_caja  = rm_j02.j02_codigo_caja
	  AND j04_fecha_cierre IS NULL

IF rm_j04.j04_fecha_aper IS NULL THEN
	CALL fl_mostrar_mensaje('La caja no ha sido aperturada.','exclamation')
	EXIT PROGRAM
END IF

IF rm_j04.j04_fecha_aper   IS NOT NULL AND 
   rm_j04.j04_fecha_cierre IS NOT NULL 
   THEN
	--CALL FGL_WINMESSAGE(vg_producto,'La caja ha sido cerrada el '|| DATE(rm_j04.j04_fecha_cierre) || '.','exclamation')
	CALL fl_mostrar_mensaje('La caja ha sido cerrada el '|| DATE(rm_j04.j04_fecha_cierre) || '.','exclamation')
	RETURN 0
END IF

DECLARE q_cajt005 CURSOR FOR
	SELECT cajt005.*, gent013.* FROM cajt005, gent013
		WHERE j05_compania    = vg_codcia
		  AND j05_localidad   = vg_codloc
		  AND j05_codigo_caja = rm_j02.j02_codigo_caja
		  AND j05_fecha_aper  = rm_j04.j04_fecha_aper
		  AND j05_secuencia   = rm_j04.j04_secuencia
		  AND j05_moneda      = g13_moneda

LET i = 1
FOREACH q_cajt005 INTO r_j05.*, r_g13.*

	LET r_detalle[i].g13_nombre = r_g13.g13_nombre
	LET r_detalle[i].efectivo   = r_j05.j05_ef_apertura +
				      r_j05.j05_ef_ing_dia  -
				      r_j05.j05_ef_egr_dia
	LET r_detalle[i].cheque     = r_j05.j05_ch_apertura +
				      r_j05.j05_ch_ing_dia  -
				      r_j05.j05_ch_egr_dia
	LET r_detalle[i].total      = r_detalle[i].efectivo + 
				      r_detalle[i].cheque
	LET i = i + 1

END FOREACH

LET vm_detalle = i - 1

LET rm_j04.j04_fecha_cierre = fl_current()
LET rm_j04.j04_usuario      = vg_usuario

DISPLAY BY NAME rm_j04.j04_fecha_cierre, rm_j04.j04_usuario,
		rm_j02.j02_nombre_caja

FOR i = 1 TO vm_detalle
	DISPLAY r_detalle[i].* TO r_detalle[i].*
END FOR

RETURN 1

END FUNCTION



FUNCTION control_cerrar()

BEGIN WORK

WHENEVER ERROR CONTINUE
	CALL borrar_fuentes_no_procesados()
	CALL evaluar_proformas_vta_perdida()
WHENEVER ERROR STOP

WHENEVER ERROR CONTINUE
DECLARE q_cajt004 CURSOR FOR
	SELECT * FROM cajt004
		WHERE j04_compania    = vg_codcia
		  AND j04_localidad   = vg_codloc
		  AND j04_codigo_caja = rm_j02.j02_codigo_caja
		  AND j04_fecha_aper  = rm_j04.j04_fecha_aper
		  AND j04_secuencia   = rm_j04.j04_secuencia
	FOR UPDATE

OPEN q_cajt004
FETCH q_cajt004

WHENEVER ERROR STOP
IF STATUS < 0 THEN
	ROLLBACK WORK
	CALL fl_mostrar_mensaje('La caja esta siendo actualizada por otro usuario.','stop')
	EXIT PROGRAM
END IF

UPDATE cajt004
	SET j04_fecha_cierre = fl_current()
	WHERE CURRENT OF q_cajt004

COMMIT WORK
		 
CALL fl_mostrar_mensaje('La caja ha sido cerrada.','info')
RETURN 1

END FUNCTION



FUNCTION retorna_arreglo()
--#LET vm_size_arr = fgl_scr_size('r_detalle')
IF vg_gui = 0 THEN
        LET vm_size_arr = 8
END IF
                                                                                
END FUNCTION



FUNCTION llamar_visor_teclas()
DEFINE a		CHAR(1)

IF vg_gui = 0 THEN
	CALL fl_visor_teclas_caracter() RETURNING int_flag 
	LET a = fgl_getkey()
	CLOSE WINDOW w_tf
	LET int_flag = 0
END IF

END FUNCTION



FUNCTION borrar_fuentes_no_procesados()
DEFINE r_j02		RECORD LIKE cajt002.*
DEFINE cuantos		INTEGER

SET LOCK MODE TO WAIT
INITIALIZE r_j02.* TO NULL
DECLARE qu_uc CURSOR FOR
	SELECT * FROM cajt002
		WHERE j02_compania  = vg_codcia
		  AND j02_localidad = vg_codloc
		  AND j02_usua_caja = vg_usuario
OPEN qu_uc 
FETCH qu_uc INTO r_j02.*
CLOSE qu_uc 
FREE qu_uc 
IF r_j02.j02_compania IS NULL THEN
	ROLLBACK WORK
	CALL fl_mostrar_mensaje('Usted no es usuario de Caja.','exclamation')
	EXIT PROGRAM
END IF
SELECT COUNT(*) INTO cuantos
	FROM cajt004
	WHERE j04_compania     = vg_codcia
	  AND j04_localidad    = vg_codloc
	  AND j04_fecha_cierre = vg_fecha
IF cuantos > 1 THEN
	RETURN
END IF
SELECT j10_compania cia, j10_localidad loc, j10_tipo_fuente tipo_f,
	j10_num_fuente num_f
	FROM cajt010
	WHERE j10_compania      = vg_codcia
	  AND j10_localidad     = vg_codloc
	  AND j10_estado       IN ('A', 'P')
	  --AND j10_estado        = 'A'
	  AND j10_tipo_destino IS NULL
	  AND DATE(j10_fecing) <= vg_fecha
	INTO TEMP tmp_j10
IF r_j02.j02_pre_ventas = 'S' THEN
	CALL borra_preventa()
END IF
IF r_j02.j02_solicitudes = 'S' THEN
	CALL borra_solicitud()
END IF
DELETE FROM cajt011 
	WHERE EXISTS
		(SELECT * FROM tmp_j10
			WHERE tmp_j10.cia    = cajt011.j11_compania
		  	  AND tmp_j10.loc    = cajt011.j11_localidad
			  AND tmp_j10.tipo_f = cajt011.j11_tipo_fuente
		          AND tmp_j10.num_f  = cajt011.j11_num_fuente)
DELETE FROM cajt010 
	WHERE EXISTS
		(SELECT * FROM tmp_j10
			WHERE tmp_j10.cia    = cajt010.j10_compania
		  	  AND tmp_j10.loc    = cajt010.j10_localidad
			  AND tmp_j10.tipo_f = cajt010.j10_tipo_fuente
		          AND tmp_j10.num_f  = cajt010.j10_num_fuente)
DROP TABLE tmp_j10
SELECT p24_compania cia, p24_localidad loc, p24_orden_pago ord_pag
	FROM cxpt024
	WHERE p24_compania      = vg_codcia
	  AND p24_localidad     = vg_codloc
	  AND p24_estado        = 'A'
	  AND DATE(p24_fecing) <= vg_fecha
	INTO TEMP tmp_p24
SELECT COUNT(*) INTO cuantos FROM tmp_p24
IF cuantos = 0 THEN
	DROP TABLE tmp_p24
	RETURN
END IF
DELETE FROM cxpt026
	WHERE EXISTS
		(SELECT * FROM tmp_p24
			WHERE tmp_p24.cia     = cxpt026.p26_compania
		  	  AND tmp_p24.loc     = cxpt026.p26_localidad
		          AND tmp_p24.ord_pag = cxpt026.p26_orden_pago)
DELETE FROM cxpt025
	WHERE EXISTS
		(SELECT * FROM tmp_p24
			WHERE tmp_p24.cia     = cxpt025.p25_compania
		  	  AND tmp_p24.loc     = cxpt025.p25_localidad
		          AND tmp_p24.ord_pag = cxpt025.p25_orden_pago)
DELETE FROM cxpt024
	WHERE EXISTS
		(SELECT * FROM tmp_p24
			WHERE tmp_p24.cia     = cxpt024.p24_compania
		  	  AND tmp_p24.loc     = cxpt024.p24_localidad
		          AND tmp_p24.ord_pag = cxpt024.p24_orden_pago)
DROP TABLE tmp_p24

END FUNCTION



FUNCTION borra_preventa()
DEFINE cuantos		INTEGER

SELECT r23_compania cia, r23_localidad loc, r23_numprev num_p
	FROM rept023
	WHERE r23_compania      = vg_codcia
	  AND r23_localidad     = vg_codloc
	  AND r23_estado       <> "F"
	  AND r23_cod_tran     IS NULL
	  AND DATE(r23_fecing)  < vg_fecha
	INTO TEMP tmp_r23
SELECT COUNT(*) INTO cuantos FROM tmp_r23
IF cuantos = 0 THEN
	DROP TABLE tmp_r23
	RETURN
END IF
DELETE FROM rept027
	WHERE EXISTS
		(SELECT * FROM tmp_r23
			WHERE tmp_r23.cia   = rept027.r27_compania
		  	  AND tmp_r23.loc   = rept027.r27_localidad
		          AND tmp_r23.num_p = rept027.r27_numprev)
DELETE FROM rept026
	WHERE EXISTS
		(SELECT * FROM tmp_r23
			WHERE tmp_r23.cia   = rept026.r26_compania
		  	  AND tmp_r23.loc   = rept026.r26_localidad
		          AND tmp_r23.num_p = rept026.r26_numprev)
DELETE FROM rept025
	WHERE EXISTS
		(SELECT * FROM tmp_r23
			WHERE tmp_r23.cia   = rept025.r25_compania
		  	  AND tmp_r23.loc   = rept025.r25_localidad
		          AND tmp_r23.num_p = rept025.r25_numprev)
DELETE FROM rept024
	WHERE EXISTS
		(SELECT * FROM tmp_r23
			WHERE tmp_r23.cia   = rept024.r24_compania
		  	  AND tmp_r23.loc   = rept024.r24_localidad
		          AND tmp_r23.num_p = rept024.r24_numprev)
DELETE FROM rept023 
	WHERE EXISTS
		(SELECT * FROM tmp_r23
			WHERE tmp_r23.cia   = rept023.r23_compania
		  	  AND tmp_r23.loc   = rept023.r23_localidad
		          AND tmp_r23.num_p = rept023.r23_numprev)
UPDATE rept088
	SET r88_numprev_nue = NULL
	WHERE r88_compania     = vg_codcia
	  AND r88_localidad    = vg_codloc
	  AND r88_numprev_nue IN (SELECT num_p FROM tmp_r23)
DROP TABLE tmp_r23

END FUNCTION



FUNCTION borra_solicitud()

DELETE FROM cxct025 
	WHERE EXISTS
		(SELECT * FROM tmp_j10
			WHERE tmp_j10.cia    = cxct025.z25_compania
		  	  AND tmp_j10.loc    = cxct025.z25_localidad
			  AND tmp_j10.tipo_f = "SC"
		          AND tmp_j10.num_f  = cxct025.z25_numero_sol)
DELETE FROM cxct024 
	WHERE EXISTS
		(SELECT * FROM tmp_j10
			WHERE tmp_j10.cia    = cxct024.z24_compania
		  	  AND tmp_j10.loc    = cxct024.z24_localidad
			  AND tmp_j10.tipo_f = "SC"
		          AND tmp_j10.num_f  = cxct024.z24_numero_sol)

END FUNCTION



FUNCTION evaluar_proformas_vta_perdida()
DEFINE cuantos		INTEGER
DEFINE mensaje		VARCHAR(200)

SELECT r21_compania AS cia,
	r21_localidad AS loc,
	r21_numprof AS numprof,
	r21_dias_prof AS dias_f,
	r21_fecing AS fecing
	FROM rept021
	WHERE r21_compania      = vg_codcia
	  AND r21_localidad     = vg_codloc
	  AND r21_cod_tran     IS NULL
	  AND r21_num_presup   IS NULL
	  AND r21_num_ot       IS NULL
	  AND DATE(r21_fecing) BETWEEN vg_fecha -
		(SELECT r00_expi_prof * 2
			FROM rept000
			WHERE r00_compania = r21_compania) UNITS DAY
				   AND vg_fecha -
		(SELECT r00_expi_prof + 1
			FROM rept000
			WHERE r00_compania = r21_compania) UNITS DAY
	  AND YEAR(r21_fecing) >= 2014
	INTO TEMP t1
SELECT COUNT(*) INTO cuantos FROM t1
IF cuantos = 0 THEN
	DROP TABLE t1
	RETURN
END IF
SELECT r02_codigo AS bod
	FROM rept002
	WHERE r02_compania   = vg_codcia
	  AND r02_localidad  = vg_codloc
	  AND r02_estado     = "A"
	  AND r02_area       = "R"
	  AND r02_tipo_ident = "P"
	INTO TEMP tmp_bod
SELECT COUNT(*) INTO cuantos FROM tmp_bod
IF cuantos = 0 THEN
	RETURN
END IF
SELECT t1.*, r22_item AS item
	FROM t1, rept022
	WHERE r22_compania  = cia
	  AND r22_localidad = loc
	  AND r22_numprof   = numprof
	  AND r22_bodega    NOT IN (SELECT bod FROM tmp_bod)
	INTO TEMP tmp_prof
DROP TABLE t1
SELECT COUNT(*) INTO cuantos FROM tmp_prof
IF cuantos = 0 THEN
	RETURN
END IF
SELECT 1 AS cia, (SELECT bod FROM tmp_bod) AS bod, item, "S/N" AS ubic,
	0.00 AS sto_ant, 0.00 AS sto_act, 0.00 AS ing_d, 0.00 AS egr_d
	FROM tmp_prof
	GROUP BY 1, 2, 3, 4, 5, 6, 7, 8
	INTO TEMP t1
SELECT * FROM t1
	WHERE NOT EXISTS
		(SELECT 1 FROM rept011
			WHERE r11_compania = cia
			  AND r11_bodega   = bod
			  AND r11_item     = item)
	INTO TEMP tmp_ite
DROP TABLE t1
SELECT COUNT(*) INTO cuantos FROM tmp_ite
IF cuantos > 0 THEN
	LET mensaje = "Se van a insertar ", cuantos USING "<<<<<<#",
			" ítems con stock CERO en el maestro de existencias",
			" para la bodega de VENTAS PERDIDAS."
	INSERT INTO rept011
		(r11_compania, r11_bodega, r11_item, r11_ubicacion,
		 r11_stock_ant, r11_stock_act, r11_ing_dia, r11_egr_dia)
		SELECT * FROM tmp_ite
	CALL fl_mostrar_mensaje(mensaje CLIPPED, "info")
END IF
DROP TABLE tmp_ite
UPDATE rept022
	SET r22_bodega = (SELECT bod FROM tmp_bod)
	WHERE r22_compania   = vg_codcia
	  AND r22_localidad  = vg_codloc
	  AND r22_numprof   IN
		(SELECT UNIQUE numprof
			FROM tmp_prof
			WHERE cia = r22_compania
			  AND loc = r22_localidad)
DROP TABLE tmp_bod
SELECT COUNT(UNIQUE numprof) INTO cuantos FROM tmp_prof
IF cuantos IS NULL THEN
	LET cuantos = 0
END IF
DROP TABLE tmp_prof
IF cuantos > 0 THEN
	LET mensaje = "Se actualizaron ", cuantos USING "<<<<<<#",
			" proformas como VENTAS PERDIDAS."
	CALL fl_mostrar_mensaje(mensaje CLIPPED, "info")
END IF

END FUNCTION



{--
FUNCTION borrar_fuentes_no_procesados()
DEFINE r_j10		RECORD LIKE cajt010.*
DEFINE r_j02		RECORD LIKE cajt002.*

SET LOCK MODE TO WAIT
DECLARE qu_uc CURSOR FOR SELECT * FROM cajt002
	WHERE j02_compania  = vg_codcia AND 
	      j02_localidad = vg_codloc AND 
	      j02_usua_caja = vg_usuario
OPEN qu_uc 
FETCH qu_uc INTO r_j02.*
IF status = NOTFOUND THEN
	CALL fl_mostrar_mensaje('Usted no es usuario de Caja.','exclamation')
	ROLLBACK WORK
	EXIT PROGRAM
END IF
DECLARE qu_lt CURSOR FOR
	SELECT * FROM cajt010
		WHERE j10_compania     = vg_codcia
		  AND j10_localidad    = vg_codloc
		  AND j10_estado       = 'A'
		  AND j10_tipo_destino IS NULL
		  AND DATE(j10_fecing) < vg_fecha
FOREACH qu_lt INTO r_j10.*
	--
	IF DATE(r_j10.j10_fecing) >= vg_fecha THEN
		CONTINUE FOREACH
	END IF
	--
	IF r_j02.j02_pre_ventas = 'S' AND r_j10.j10_tipo_fuente = 'PR' THEN
		CALL borra_preventa(r_j10.j10_compania, r_j10.j10_localidad,
				    r_j10.j10_num_fuente)
	END IF
	IF r_j02.j02_solicitudes = 'S' AND r_j10.j10_tipo_fuente = 'SC' THEN
		CALL borra_solicitud(r_j10.j10_compania, r_j10.j10_localidad,
				    r_j10.j10_num_fuente)
	END IF
	DELETE FROM cajt011 
		WHERE j11_compania    = r_j10.j10_compania 
		  AND j11_localidad   = r_j10.j10_localidad 
		  AND j11_tipo_fuente =	r_j10.j10_tipo_fuente 
		  AND j11_num_fuente  =	r_j10.j10_num_fuente 
	DELETE FROM cajt010 
		WHERE j10_compania    = r_j10.j10_compania  AND 
		      j10_localidad   = r_j10.j10_localidad AND 
		      j10_tipo_fuente = r_j10.j10_tipo_fuente AND
		      j10_num_fuente  = r_j10.j10_num_fuente
END FOREACH
DECLARE gy_chicho CURSOR FOR
	SELECT r23_numprev
		FROM rept023
		WHERE r23_compania      = vg_codcia
		  AND r23_localidad     = vg_codloc
		  AND r23_estado       <> 'F'
		  AND r23_cod_tran     IS NULL
		  AND DATE(r23_fecing) <= vg_fecha
FOREACH gy_chicho INTO r_j10.j10_num_fuente
	CALL borra_preventa(vg_codcia, vg_codloc, r_j10.j10_num_fuente)
END FOREACH
DECLARE qu_pichaloca CURSOR FOR
	SELECT z24_numero_sol
		FROM cxct024
		WHERE z24_compania      = vg_codcia
		  AND z24_localidad     = vg_codloc
		  AND z24_estado       <> 'P'
		  AND DATE(z24_fecing) <= vg_fecha
FOREACH qu_pichaloca INTO r_j10.j10_num_fuente
	CALL borra_solicitud(vg_codcia, vg_codloc, r_j10.j10_num_fuente)
END FOREACH
CALL borra_ordenes_pago(vg_codcia, vg_codloc)

END FUNCTION



FUNCTION borra_ordenes_pago(codcia, codloc)
DEFINE codcia		LIKE gent001.g01_compania
DEFINE codloc		LIKE gent002.g02_localidad
DEFINE r_p24		RECORD LIKE cxpt024.*

DECLARE q_p24 CURSOR FOR
	SELECT * FROM cxpt024
		WHERE p24_compania      = codcia
		  AND p24_localidad     = codloc
		  AND p24_estado        = 'A'
		  AND DATE(p24_fecing) <= vg_fecha
OPEN q_p24
FOREACH q_p24 INTO r_p24.*
	DELETE FROM cxpt026
		WHERE p26_compania   = codcia
		  AND p26_localidad  = codloc
		  AND p26_orden_pago = r_p24.p24_orden_pago
	DELETE FROM cxpt025
		WHERE p25_compania   = codcia
		  AND p25_localidad  = codloc
		  AND p25_orden_pago = r_p24.p24_orden_pago
	DELETE FROM cxpt024
		WHERE p24_compania   = codcia
		  AND p24_localidad  = codloc
		  AND p24_orden_pago = r_p24.p24_orden_pago
END FOREACH

END FUNCTION



FUNCTION borra_preventa(codcia, codloc, numprev)
DEFINE codcia		LIKE rept023.r23_compania
DEFINE codloc		LIKE rept023.r23_localidad
DEFINE numprev		LIKE rept023.r23_numprev
DEFINE r_r23		RECORD LIKE rept023.*

CALL fl_lee_preventa_rep(codcia, codloc, numprev) RETURNING r_r23.*
IF r_r23.r23_compania IS NULL OR r_r23.r23_estado = 'F' OR
   r_r23.r23_cod_tran IS NOT NULL THEN
	RETURN
END IF
DELETE FROM rept027
	WHERE r27_compania  = codcia
  	  AND r27_localidad = codloc
          AND r27_numprev   = numprev
DELETE FROM rept026
	WHERE r26_compania  = codcia
  	  AND r26_localidad = codloc
  	  AND r26_numprev   = numprev
DELETE FROM rept025
	WHERE r25_compania  = codcia
  	  AND r25_localidad = codloc
  	  AND r25_numprev   = numprev
DELETE FROM rept024
	WHERE r24_compania  = codcia
  	  AND r24_localidad = codloc
  	  AND r24_numprev   = numprev
DELETE FROM rept023 
	WHERE r23_compania  = codcia
  	  AND r23_localidad = codloc
  	  AND r23_numprev   = numprev
UPDATE rept088 SET r88_numprev_nue = NULL
	WHERE r88_compania    = vg_codcia
	  AND r88_localidad   = vg_codloc
	  AND r88_numprev_nue = numprev

END FUNCTION



FUNCTION borra_solicitud(codcia, codloc, numsol)
DEFINE codcia		LIKE cxct024.z24_compania
DEFINE codloc		LIKE cxct024.z24_localidad
DEFINE numsol		LIKE cxct024.z24_numero_sol

DELETE FROM cxct025 
	WHERE z25_compania   = codcia AND 
	      z25_localidad  = codloc AND
	      z25_numero_sol = numsol
DELETE FROM cxct024 
	WHERE z24_compania   = codcia AND 
	      z24_localidad  = codloc AND
	      z24_numero_sol = numsol

END FUNCTION
--}
