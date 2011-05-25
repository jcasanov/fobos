{*
 * Titulo           : ctbp310.4gl - Consulta de comprobantes descuadrados 
 * Elaboracion      : 19-may-2011
 * Autor            : MTP
 * Formato Ejecucion: fglrun ctbp310 base módulo compañía
 *}

GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE rm_ctb2          RECORD LIKE ctbt012.*
DEFINE rm_ctb3          RECORD LIKE ctbt013.*
DEFINE vm_fecha_ini     DATE
DEFINE vm_fecha_fin     DATE
DEFINE vm_max_det       SMALLINT
DEFINE vm_num_det       SMALLINT
DEFINE vm_scr_lin       SMALLINT
DEFINE rm_det           ARRAY [100] OF RECORD
                                b12_tipo_comp   LIKE ctbt012.b12_tipo_comp,
                                b12_num_comp	LIKE ctbt012.b12_num_comp,
								b12_glosa		LIKE ctbt012.b12_glosa,
                                b13_valor_base  DECIMAL(14,2),
                                b13_valor_aux   DECIMAL(14,2),
                                b12_origen      LIKE ctbt012.b12_origen
                        END RECORD

MAIN

DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/ctbp310.error')
CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 3 THEN   -- Validar # parámetros correcto
        CALL fgl_winmessage(vg_producto, 'Número de parámetros incorrecto.', 'stop')
        EXIT PROGRAM
END IF
LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_codcia   = arg_val(3)
LET vg_proceso = 'ctbp310'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()
CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()

END MAIN


FUNCTION funcion_master()

CALL fl_nivel_isolation()
LET vm_max_det = 100
OPEN WINDOW w_mas AT 3,2 WITH 22 ROWS, 80 COLUMNS
    ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE 0, BORDER,
              MESSAGE LINE LAST - 2)

OPTIONS INPUT WRAP,
        ACCEPT KEY      F12
OPEN FORM f_ctb FROM "../forms/ctbf310_1"
DISPLAY FORM f_ctb
LET vm_scr_lin = 0
CALL muestra_contadores_det(0)
CALL borrar_cabecera()
CALL borrar_detalle()
CALL mostrar_cabecera_forma()
CALL control_consulta()

END FUNCTION


FUNCTION control_consulta()
DEFINE i,j,l,col        SMALLINT
DEFINE query            VARCHAR(1000)
DEFINE query2           VARCHAR(1000)

LET vm_fecha_ini       = TODAY
LET vm_fecha_fin       = TODAY
DISPLAY BY NAME vm_fecha_ini, vm_fecha_fin

WHILE TRUE
	LET vm_num_det = 0
	CALL borrar_detalle()
	CALL muestra_contadores_det(0)
	CALL lee_parametros()
	IF int_flag THEN
		EXIT WHILE
	END IF

	BEGIN WORK;

	SELECT  b12_tipo_comp, b12_num_comp, b12_glosa,
        	(SELECT round(sum(b13_valor_base),2)  FROM ctbt013
			  WHERE b13_compania  = b12_compania
				AND b13_tipo_comp = b12_tipo_comp
				AND b13_num_comp  = b12_num_comp
				AND b13_valor_base > 0) AS debito,
	        (SELECT round(sum(b13_valor_base) * (-1),2 ) FROM ctbt013
			  WHERE b13_compania  = b12_compania
				AND b13_tipo_comp = b12_tipo_comp
				AND b13_num_comp  = b12_num_comp
				AND b13_valor_base < 0) AS credito, b12_origen
	  FROM ctbt012
	 WHERE b12_compania = vg_codcia
	   AND b12_estado = 'M'
	   AND b12_fec_proceso BETWEEN vm_fecha_ini AND  vm_fecha_fin
	  INTO TEMP tt_asientos;

	DELETE FROM tt_asientos WHERE debito = credito OR ((debito IS NULL) AND (credito IS NULL));

	LET query = 'SELECT *  FROM tt_asientos'
	PREPARE deto FROM query
	DECLARE q_deto CURSOR FOR deto

	LET vm_num_det = 1
	FOREACH q_deto INTO  rm_det[vm_num_det].*
		LET vm_num_det = vm_num_det + 1
		IF vm_num_det > vm_max_det THEN
			EXIT FOREACH
		END IF
	END FOREACH

	LET vm_num_det = vm_num_det - 1
	IF vm_num_det = 0 THEN
		CALL fl_mensaje_consulta_sin_registros()
		CONTINUE WHILE
	END IF
	
	CALL set_count(vm_num_det)
	WHILE TRUE
		LET int_flag = 0
		DISPLAY ARRAY rm_det TO rm_det.*
			BEFORE DISPLAY
				CALL dialog.keysetlabel('ACCEPT','')
			BEFORE ROW
				LET j = arr_curr()
				LET l = scr_line()
				CALL muestra_contadores_det(j)
			AFTER DISPLAY
				CONTINUE DISPLAY
			ON KEY(INTERRUPT)
				LET int_flag = 1
				EXIT DISPLAY
		END DISPLAY

		IF int_flag = 1 THEN
			EXIT WHILE
		END IF
	END WHILE
		
	ROLLBACK WORK;

END WHILE

END FUNCTION


FUNCTION lee_parametros()
DEFINE deci_aux         LIKE gent013.g13_decimales
DEFINE r_mon            RECORD LIKE gent013.*
DEFINE fecha_fin        DATE

LET int_flag = 0
INPUT BY NAME vm_fecha_ini, vm_fecha_fin
        WITHOUT DEFAULTS
        ON KEY(INTERRUPT)
                LET int_flag = 1
                RETURN
        ON KEY(F2)
        BEFORE FIELD vm_fecha_fin
                LET fecha_fin = vm_fecha_fin
        AFTER FIELD vm_fecha_ini
                IF vm_fecha_ini IS NOT NULL THEN
                        IF vm_fecha_ini > TODAY THEN
                                CALL fgl_winmessage(vg_producto,'La fecha de inicio no puede ser mayor a la de hoy.','exclamation')
                                NEXT FIELD vm_fecha_ini
                        END IF
                END IF
	AFTER FIELD vm_fecha_fin
                IF vm_fecha_fin IS NOT NULL THEN
                        IF vm_fecha_fin > TODAY THEN
                                CALL fgl_winmessage(vg_producto,'La fecha de término no puede ser mayor a la de hoy.','exclamation')
                                NEXT FIELD vm_fecha_fin
                        END IF
                ELSE
                        LET vm_fecha_fin = fecha_fin
                        DISPLAY BY NAME vm_fecha_fin
                END IF
        AFTER INPUT
                IF vm_fecha_fin < vm_fecha_ini THEN
                        CALL fgl_winmessage(vg_producto,'La fecha final debe ser mayor a la fecha de inicial.','exclamation')
                        NEXT FIELD vm_fecha_fin
                END IF
END INPUT
END FUNCTION



FUNCTION borrar_cabecera()

CLEAR vm_fecha_ini, vm_fecha_fin
INITIALIZE rm_ctb2.* TO NULL

END FUNCTION



FUNCTION borrar_detalle()
DEFINE i                SMALLINT

CALL muestra_contadores_det(0)
LET vm_scr_lin = fgl_scr_size('rm_det')
FOR i = 1 TO vm_scr_lin
        INITIALIZE rm_det[i].* TO NULL
        CLEAR rm_det[i].*
END FOR

END FUNCTION



FUNCTION muestra_contadores_det(cor)
DEFINE cor                 SMALLINT

DISPLAY "" AT 4, 66
DISPLAY cor, " de ", vm_num_det AT 4, 70

END FUNCTION



FUNCTION mostrar_cabecera_forma()

DISPLAY 'TC' 		TO tit_col1
DISPLAY 'No.'		TO tit_col2
DISPLAY 'Glosa'		TO tit_col3
DISPLAY 'Debitos'   TO tit_col4
DISPLAY 'Creditos'  TO tit_col5
DISPLAY 'O'	 		TO tit_col6

END FUNCTION



FUNCTION validar_parametros()

CALL fl_lee_modulo(vg_modulo) RETURNING rg_mod.*
IF rg_mod.g50_modulo IS NULL THEN
        CALL fgl_winmessage(vg_producto, 'No existe módulo: ' || vg_modulo, 'stop')
        EXIT PROGRAM
END IF
CALL fl_lee_compania(vg_codcia) RETURNING rg_cia.*
IF rg_cia.g01_compania IS NULL THEn
        CALL fgl_winmessage(vg_producto, 'No existe compañía: '|| vg_codcia, 'stop')
        EXIT PROGRAM
END IF
IF rg_cia.g01_estado <> 'A' THEN
        CALL fgl_winmessage(vg_producto, 'Compañía no está activa: ' || vg_codcia, 'stop')
        EXIT PROGRAM
END IF
IF vg_codloc IS NULL THEN
        LET vg_codloc   = fl_retorna_agencia_default(vg_codcia)
END IF
CALL fl_lee_localidad(vg_codcia, vg_codloc) RETURNING rg_loc.*
IF rg_loc.g02_localidad IS NULL THEN
        CALL fgl_winmessage(vg_producto, 'No existe localidad: ' || vg_codloc, 'stop')
        EXIT PROGRAM
END IF
IF rg_loc.g02_estado <> 'A' THEN
        CALL fgl_winmessage(vg_producto, 'Localidad no está activa: '|| vg_codloc, 'stop')
        EXIT PROGRAM
END IF

END FUNCTION
