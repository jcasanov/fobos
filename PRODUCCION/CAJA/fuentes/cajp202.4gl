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
CALL startlog('../logs/cajp202.error')
CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 THEN
     CALL fgl_winmessage(vg_producto,'Número de parámetros incorrecto','stop')
     EXIT PROGRAM
END IF
LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_codcia   = arg_val(3)
LET vg_codloc   = arg_val(4)
LET vg_proceso = 'cajp202'

CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()
CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)

CALL funcion_master()
                                                                                
END MAIN



FUNCTION funcion_master()
DEFINE flag	SMALLINT

CALL fl_nivel_isolation()

OPEN WINDOW w_202 AT 3,2 WITH 20 ROWS, 80 COLUMNS
    ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE 0, BORDER,
	      MESSAGE LINE LAST - 2)
OPEN FORM f_202 FROM '../forms/cajf202_1'
DISPLAY FORM f_202

CALL control_display_botones()

INITIALIZE rm_j04.*, rm_j02.* TO NULL

MENU 'OPCIONES'
	BEFORE MENU
		HIDE OPTION 'Ver Detalle'
		LET flag = control_validar_cierre()
		IF flag = 0 THEN
			HIDE OPTION 'Cerrar'
		END IF
		IF vm_detalle > FGL_SCR_SIZE('r_detalle') THEN
			SHOW OPTION 'Ver Detalle'
		END IF

	COMMAND KEY('V') 'Ver Detalle' 'Ver Detalle del cierre.'
		CALL control_display_array_cajt005()

	COMMAND KEY('C') 'Cerrar' 	
		LET flag = control_cerrar()
		IF flag THEN
			HIDE OPTION 'Cerrar'
		END IF

	COMMAND KEY('S') 'Salir' 	
		EXIT MENU

END MENU

END FUNCTION



FUNCTION control_display_botones()
	
	DISPLAY 'Moneda' 	 TO tit_col1
	DISPLAY 'Efectivo'	 TO tit_col2
	DISPLAY 'Cheque'  	 TO tit_col3
	DISPLAY 'Total'	 	 TO tit_col4

END FUNCTION



FUNCTION control_display_array_cajt005()

CALL set_count(vm_detalle)
DISPLAY ARRAY r_detalle TO r_detalle.* 
        BEFORE DISPLAY
                CALL dialog.keysetlabel('ACCEPT','')
        AFTER DISPLAY
                CONTINUE DISPLAY
        ON KEY(INTERRUPT)
                EXIT DISPLAY
END DISPLAY

END FUNCTION



FUNCTION control_validar_cierre()
DEFINE r_g13		RECORD LIKE gent013.*
DEFINE r_j05		RECORD LIKE cajt005.*
DEFINE i 		SMALLINT

CALL fl_retorna_caja(vg_codcia, vg_codloc, vg_usuario)
	RETURNING rm_j02.*

IF rm_j02.j02_usua_caja IS NULL THEN
	CALL fgl_winmessage(vg_producto,'El usuario no tiene asignada una caja.','exclamation')
	RETURN 0
END IF

FOR i = 1 TO FGL_SCR_SIZE('r_detalle')
	INITIALIZE r_detalle[i].* TO NULL
END FOR

SELECT * INTO rm_j04.* FROM cajt004
	WHERE j04_compania     = vg_codcia
	  AND j04_localidad    = vg_codloc
	  AND j04_codigo_caja  = rm_j02.j02_codigo_caja
	  AND j04_fecha_cierre IS NULL

IF rm_j04.j04_fecha_aper IS NULL THEN
	CALL fgl_winmessage(vg_producto,'La caja no ha sido aperturada.',
			    'exclamation')
	RETURN 0
	
END IF

IF rm_j04.j04_fecha_aper   IS NOT NULL AND 
   rm_j04.j04_fecha_cierre IS NOT NULL 
   THEN
	CALL fgl_winmessage(vg_producto,'La caja ha sido cerrada el '|| DATE(rm_j04.j04_fecha_cierre) || '.','exclamation')
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

LET rm_j04.j04_fecha_cierre = CURRENT
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

-- CALL borrar_fuentes_no_procesadas()
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

IF STATUS < 0 THEN
	WHENEVER ERROR STOP
	ROLLBACK WORK
	CALL fgl_winmessage(vg_producto,'La caja esta siendo actualizada por otro usuario.','stop')
	EXIT PROGRAM
END IF
WHENEVER ERROR STOP

UPDATE cajt004 SET j04_fecha_cierre = CURRENT
	WHERE CURRENT OF q_cajt004

COMMIT WORK
		 
CALL fgl_winmessage(vg_producto,'La caja ha sido cerrada.','info')
RETURN 1

END FUNCTION



FUNCTION borrar_fuentes_no_procesadas()
DEFINE r_j10            RECORD LIKE cajt010.*
DEFINE r_j02            RECORD LIKE cajt002.*

SET LOCK MODE TO WAIT
DECLARE qu_uc CURSOR FOR SELECT * FROM cajt002
        WHERE j02_compania  = vg_codcia AND
              j02_localidad = vg_codloc AND
              j02_usua_caja = vg_usuario
OPEN qu_uc
FETCH qu_uc INTO r_j02.*
IF status = NOTFOUND THEN
        CALL fgl_winmessage(vg_producto, 'Usted no es usuario de Caja.','exclamation')
        ROLLBACK WORK
        EXIT PROGRAM
END IF
DECLARE qu_lt CURSOR FOR SELECT * FROM cajt010
        WHERE j10_compania  = vg_codcia AND
              j10_localidad = vg_codloc AND
              j10_estado    = 'A'       AND
              j10_tipo_destino IS NULL
FOREACH qu_lt INTO r_j10.*
        IF r_j02.j02_pre_ventas = 'S' AND r_j10.j10_tipo_fuente = 'PR' THEN
--                CALL borra_preventa(r_j10.j10_compania, r_j10.j10_localidad,
--                                    r_j10.j10_num_fuente)
        END IF
        IF r_j02.j02_solicitudes = 'S' AND r_j10.j10_tipo_fuente = 'SC' THEN
                CALL borra_solicitud(r_j10.j10_compania, r_j10.j10_localidad,
                                    r_j10.j10_num_fuente)
        END IF
END FOREACH
DECLARE gy_chicho CURSOR FOR SELECT r23_numprev FROM rept023
        WHERE r23_compania  = vg_codcia AND
              r23_localidad = vg_codloc AND
              r23_estado    <> 'F'      AND
              r23_cod_tran IS NULL
FOREACH gy_chicho INTO r_j10.j10_num_fuente
--        CALL borra_preventa(vg_codcia, vg_codloc, r_j10.j10_num_fuente)
END FOREACH
DECLARE qu_pichaloca CURSOR FOR SELECT z24_numero_sol FROM cxct024
        WHERE z24_compania   = vg_codcia AND
              z24_localidad  = vg_codloc AND
              z24_estado     <> 'P'
FOREACH qu_pichaloca INTO r_j10.j10_num_fuente
        CALL borra_solicitud(vg_codcia, vg_codloc, r_j10.j10_num_fuente)
END FOREACH
-- CALL borra_ordenes_pago(vg_codcia, vg_codloc)

END FUNCTION



FUNCTION borra_ordenes_pago(codcia, codloc)
DEFINE codcia           LIKE gent001.g01_compania
DEFINE codloc           LIKE gent002.g02_localidad
DEFINE r_p24            RECORD LIKE cxpt024.*

DECLARE q_p24 CURSOR FOR
        SELECT * FROM cxpt024
                WHERE p24_compania     = codcia
                  AND p24_localidad    = codloc
                  AND p24_estado       = 'A'
                  AND DATE(p24_fecing) < TODAY
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
DEFINE codcia           LIKE rept023.r23_compania
DEFINE codloc           LIKE rept023.r23_localidad
DEFINE numprev          LIKE rept023.r23_numprev
DEFINE r_r23            RECORD LIKE rept023.*
DEFINE r_r21            RECORD LIKE rept021.*

CALL fl_lee_preventa_rep(codcia, codloc, numprev)
        RETURNING r_r23.*
IF r_r23.r23_compania IS NULL OR r_r23.r23_estado = 'F' OR
   r_r23.r23_cod_tran IS NOT NULL THEN
        RETURN
END IF

{*
 * Si la proforma no ha expirado no borre la preventa
 *}
CALL fl_lee_proforma_desde_preventa(codcia, codloc, numprev) RETURNING r_r21.*
IF DATE(r_r21.r21_fecing) + r_r21.r21_dias_prof >= TODAY THEN
	RETURN
END IF

DELETE FROM rept102
		WHERE r102_compania   = codcia
		  AND r102_localidad  = codloc
		  AND r102_numprof    = r_r21.r21_numprof
		  AND r102_numprev    = numprev
DELETE FROM cajt010
        WHERE j10_compania    = codcia  
          AND j10_localidad   = codloc 
          AND j10_tipo_fuente = 'PR'
          AND j10_num_fuente  = numprev
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

END FUNCTION



FUNCTION borra_solicitud(codcia, codloc, numsol)
DEFINE codcia           LIKE cxct024.z24_compania
DEFINE codloc           LIKE cxct024.z24_localidad
DEFINE numsol           LIKE cxct024.z24_numero_sol

DELETE FROM cajt010
        WHERE j10_compania    = codcia AND 
              j10_localidad   = codloc AND 
              j10_tipo_fuente = 'SC'   AND 
              j10_num_fuente  = numsol
DELETE FROM cxct101
        WHERE z101_compania   = codcia AND
              z101_localidad  = codloc AND
              z101_numero_sol = numsol
DELETE FROM cxct025
        WHERE z25_compania   = codcia AND
              z25_localidad  = codloc AND
              z25_numero_sol = numsol
DELETE FROM cxct024
        WHERE z24_compania   = codcia AND
              z24_localidad  = codloc AND
              z24_numero_sol = numsol

END FUNCTION



FUNCTION validar_parametros()
                                                                                
CALL fl_lee_modulo(vg_modulo) RETURNING rg_mod.*
IF rg_mod.g50_modulo IS NULL THEN
        CALL fgl_winmessage(vg_producto, 'No existe módulo: ' || vg_modulo,
 			    'stop')
        EXIT PROGRAM
END IF
CALL fl_lee_compania(vg_codcia) RETURNING rg_cia.*
IF rg_cia.g01_compania IS NULL THEN
        CALL fgl_winmessage(vg_producto, 'No existe compañía: '|| vg_codcia,
			    'stop')
        EXIT PROGRAM
END IF
IF rg_cia.g01_estado <> 'A' THEN
     CALL fgl_winmessage(vg_producto, 'Compañía no está activa: ' 
			 || vg_codcia, 'stop')
     EXIT PROGRAM
END IF
IF vg_codloc IS NULL THEN
        LET vg_codloc   = fl_retorna_agencia_default(vg_codcia)
END IF
CALL fl_lee_localidad(vg_codcia, vg_codloc) RETURNING rg_loc.*
IF rg_loc.g02_localidad IS NULL THEN
        CALL fgl_winmessage(vg_producto, 'No existe localidad: ' || vg_codloc,
			    'stop')
        EXIT PROGRAM
END IF
IF rg_loc.g02_estado <> 'A' THEN
      CALL fgl_winmessage(vg_producto, 'Localidad no está activa: '|| vg_codloc, 			  'stop')
      EXIT PROGRAM
END IF
                                                                                
END FUNCTION

