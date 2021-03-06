-------------------------------------------------------------------------------
-- Titulo               : cajp200.4gl -- Apertura de Caja
-- Elaboraci�n          : 20-nov-2001
-- Autor                : GVA
-- Formato de Ejecuci�n : fglrun  cajp200 base modulo compania 
-- Ultima Correci�n     : 20-nov-2001
-- Motivo Correcci�n    : 1
--------------------------------------------------------------------------------
                                                                                
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'
                                                                                
DEFINE rm_j04   	RECORD LIKE cajt004.*
DEFINE rm_j02   	RECORD LIKE cajt002.*
DEFINE vm_detalle	SMALLINT
DEFINE vm_size_arr	INTEGER

DEFINE r_detalle	ARRAY[100] OF RECORD
	g13_nombre		LIKE gent013.g13_nombre,
	j05_ef_apertura 	LIKE cajt005.j05_ef_apertura,
	j05_ch_apertura		LIKE cajt005.j05_ch_apertura,
	tot_apertura		DECIMAL(12,2)
	END RECORD

DEFINE r_detalle_1	ARRAY[100] OF RECORD
	j05_moneda		LIKE gent013.g13_moneda
	END RECORD



MAIN
                                                                                
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
--CALL startlog('../logs/errores')
CALL startlog('../logs/cajp200.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 THEN
     	--CALL FGL_WINMESSAGE(vg_producto,'N�mero de par�metros incorrecto','stop')
	CALL fl_mostrar_mensaje('N�mero de par�metros incorrecto.','stop')
     	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_codloc  = arg_val(4)
LET vg_proceso = 'cajp200'

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
OPEN WINDOW w_200 AT row_ini, 2 WITH num_rows ROWS, num_cols COLUMNS
    ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE lin_menu,BORDER,
	      MESSAGE LINE LAST - 1)
IF vg_gui = 1 THEN
	OPEN FORM f_200 FROM '../forms/cajf200_1'
ELSE
	OPEN FORM f_200 FROM '../forms/cajf200_1c'
END IF
DISPLAY FORM f_200
CALL control_DISPLAY_botones()

INITIALIZE rm_j04.*, rm_j02.* TO NULL

MENU 'OPCIONES'
	BEFORE MENU
		HIDE OPTION 'Ver Detalle'
		LET flag = control_validar_apertura()
		IF flag = 0 THEN
			HIDE OPTION 'Aperturar'
		END IF
		CALL retorna_arreglo()
		IF vm_detalle > vm_size_arr THEN
			SHOW OPTION 'Ver Detalle'
		END IF

	COMMAND KEY('V') 'Ver Detalle' 'Ver Detalle de la apertura.'
		CALL control_DISPLAY_array_cajt005()

	COMMAND KEY('P') 'Aperturar' 	
		LET flag = control_apertura()
		IF flag THEN
			HIDE OPTION 'Aperturar'
		END IF

	COMMAND KEY('S') 'Salir' 	
		EXIT MENU

END MENU

END FUNCTION



FUNCTION control_DISPLAY_botones()
	
	--#DISPLAY 'Moneda' 		 TO tit_col1
	--#DISPLAY 'Efectivo Apertura'	 TO tit_col2
	--#DISPLAY 'Cheque Apertura'  	 TO tit_col3
	--#DISPLAY 'Total'		  	 TO tit_col4

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



FUNCTION control_validar_apertura()
DEFINE r_g13		RECORD LIKE gent013.*
DEFINE r_j05		RECORD LIKE cajt005.*
DEFINE i 		SMALLINT

CALL fl_retorna_caja(vg_codcia, vg_codloc, vg_usuario)
	RETURNING rm_j02.*

IF rm_j02.j02_usua_caja IS NULL THEN
	--CALL FGL_WINMESSAGE(vg_producto,'El usuario '|| vg_usuario || ' no tiene asignada una caja.','exclamation')
	CALL fl_mostrar_mensaje('El usuario '|| vg_usuario || ' no tiene asignada una caja.','exclamation')
	RETURN 0
END IF

CALL retorna_arreglo()

FOR i = 1 TO vm_size_arr
	INITIALIZE r_detalle[i].* TO NULL
END FOR

DECLARE q_cajt004 CURSOR FOR
	SELECT * FROM cajt004
		WHERE j04_compania    = vg_codcia
		  AND j04_localidad   = vg_codloc
		  AND j04_codigo_caja = rm_j02.j02_codigo_caja
	ORDER BY j04_fecha_aper DESC, j04_secuencia DESC

OPEN  q_cajt004
FETCH q_cajt004 INTO rm_j04.*
CLOSE q_cajt004
FREE  q_cajt004

IF rm_j04.j04_fecha_aper IS NULL THEN
	
	LET rm_j04.j04_fecha_aper = TODAY
	LET rm_j04.j04_usuario    = vg_usuario

	DISPLAY BY NAME rm_j02.j02_nombre_caja, rm_j04.j04_fecha_aper,
			rm_j04.j04_usuario

	CALL fl_lee_moneda(rg_gen.g00_moneda_base)
		RETURNING r_g13.*

	LET vm_detalle = 1
	FOR i = 1 TO vm_detalle 
		LET r_detalle_1[i].j05_moneda    = r_g13.g13_moneda

		LET r_detalle[i].g13_nombre      = r_g13.g13_nombre		
		LET r_detalle[i].j05_ef_apertura = 0		
		LET r_detalle[i].j05_ch_apertura = 0		
		LET r_detalle[i].tot_apertura    = 0		
		DISPLAY r_detalle[i].* TO r_detalle[i].*
	END FOR

	RETURN 1
END IF

IF rm_j04.j04_fecha_aper IS NOT NULL AND rm_j04.j04_fecha_cierre IS NULL THEN
	--CALL FGL_WINMESSAGE(vg_producto,'La caja ' || rm_j02.j02_nombre_caja ||' no ha sido cerrada en la fecha ' || rm_j04.j04_fecha_aper || '.','exclamation')
	CALL fl_mostrar_mensaje('La caja ' || rm_j02.j02_nombre_caja ||' no ha sido cerrada en la fecha ' || rm_j04.j04_fecha_aper || '.','exclamation')
	RETURN 0
END IF

IF rm_j04.j04_fecha_aper = TODAY AND
   rm_j04.j04_fecha_cierre IS NOT NULL 
   THEN
	--CALL FGL_WINMESSAGE(vg_producto,'La caja no puede ser aperturada m�s de una vez el mismo d�a. Si desea puede reaperturarla.','exclamation')
	CALL fl_mostrar_mensaje('La caja no puede ser aperturada m�s de una vez el mismo d�a. Si desea puede reaperturarla.','exclamation')
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

	LET r_detalle_1[i].j05_moneda    = r_g13.g13_moneda

	LET r_detalle[i].g13_nombre      = r_g13.g13_nombre
	LET r_detalle[i].j05_ef_apertura = r_j05.j05_ef_apertura +
					   r_j05.j05_ef_ing_dia -
					   r_j05.j05_ef_egr_dia
	LET r_detalle[i].j05_ch_apertura = r_j05.j05_ch_apertura +
					   r_j05.j05_ch_ing_dia -
					   r_j05.j05_ch_egr_dia
	LET r_detalle[i].tot_apertura    = r_detalle[i].j05_ef_apertura + 
					   r_detalle[i].j05_ch_apertura
	LET i = i + 1

END FOREACH

LET vm_detalle = i - 1

LET rm_j04.j04_fecha_aper = TODAY
DISPLAY BY NAME rm_j02.j02_nombre_caja, rm_j04.j04_fecha_aper,
		rm_j04.j04_usuario

FOR i = 1 TO vm_detalle
	DISPLAY r_detalle[i].* TO r_detalle[i].*
END FOR

RETURN 1

END FUNCTION



FUNCTION control_apertura()
DEFINE i 		SMALLINT
DEFINE r_j05		RECORD LIKE cajt005.*

BEGIN WORK
WHENEVER ERROR CONTINUE
	CALL borrar_fuentes_no_procesados()
WHENEVER ERROR STOP
LET rm_j04.j04_secuencia   = 1
LET rm_j04.j04_compania    = vg_codcia
LET rm_j04.j04_localidad   = vg_codloc
LET rm_j04.j04_codigo_caja = rm_j02.j02_codigo_caja
LET rm_j04.j04_usuario     = vg_usuario
LET rm_j04.j04_fecha_aper  = TODAY 
LET rm_j04.j04_fecing      = CURRENT 
INITIALIZE rm_j04.j04_fecha_cierre TO NULL

INSERT INTO cajt004 VALUES(rm_j04.*)

LET r_j05.j05_compania    = vg_codcia
LET r_j05.j05_localidad   = vg_codloc
LET r_j05.j05_codigo_caja = rm_j02.j02_codigo_caja
LET r_j05.j05_fecha_aper  = rm_j04.j04_fecha_aper
LET r_j05.j05_secuencia   = 1
LET r_j05.j05_ef_ing_dia  = 0
LET r_j05.j05_ch_ing_dia  = 0
LET r_j05.j05_ef_egr_dia  = 0
LET r_j05.j05_ch_egr_dia  = 0

FOR i = 1 TO vm_detalle

	LET r_j05.j05_moneda      = r_detalle_1[i].j05_moneda
	LET r_j05.j05_ef_apertura = r_detalle[i].j05_ef_apertura
	LET r_j05.j05_ch_apertura = r_detalle[i].j05_ch_apertura

	INSERT INTO cajt005 VALUES (r_j05.*)

END FOR
COMMIT WORK
--CALL fl_recalcula_saldos_clientes(vg_codcia, vg_codloc)
--CALL fl_recalcula_saldos_proveedores(vg_codcia, vg_codloc)
CALL fl_mostrar_mensaje('La caja ha sido aperturada.','info')
CALL fl_verificar_dias_validez_sri(vg_codcia, vg_codloc, 'FA')
--CALL fl_verificar_dias_validez_sri(vg_codcia, vg_codloc, 'NV')
RETURN 1

END FUNCTION



FUNCTION retorna_arreglo()

--#LET vm_size_arr = fgl_scr_size('r_detalle')
IF vg_gui = 0 THEN
        LET vm_size_arr = 8
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
	WHERE j04_compania   = vg_codcia
	  AND j04_localidad  = vg_codloc
	  AND j04_fecha_aper = TODAY
IF cuantos > 1 THEN
	RETURN
END IF
SELECT j10_compania cia, j10_localidad loc, j10_tipo_fuente tipo_f,
	j10_num_fuente num_f
	FROM cajt010
	WHERE j10_compania     = vg_codcia
	  AND j10_localidad    = vg_codloc
	  AND j10_estado       = 'A'
	  AND j10_tipo_destino IS NULL
	  AND DATE(j10_fecing) < TODAY
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
	WHERE p24_compania     = vg_codcia
	  AND p24_localidad    = vg_codloc
	  AND p24_estado       = 'A'
	  AND DATE(p24_fecing) < TODAY
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
	FROM tmp_j10, rept023
	WHERE tipo_f            = "PR"
	  AND r23_compania      = cia
	  AND r23_localidad     = loc
	  AND r23_numprev       = num_f
	  AND r23_estado       <> "F"
	  AND r23_cod_tran     IS NULL
	  AND DATE(r23_fecing) < TODAY
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



FUNCTION llamar_visor_teclas()
DEFINE a		SMALLINT

IF vg_gui = 0 THEN
	CALL fl_visor_teclas_caracter() RETURNING int_flag 
	LET a = fgl_getkey()
	CLOSE WINDOW w_tf
	LET int_flag = 0
END IF

END FUNCTION
