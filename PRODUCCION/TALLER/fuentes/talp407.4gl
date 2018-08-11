--------------------------------------------------------------------------------
-- Titulo           : talp407.4gl - Listado de Gastos de Viaje por Mecánico     --
-- Elaboracion      : 12-ABR-2002					      --
-- Autor            : GVA						      --
-- Formato Ejecucion: fglrun talp407 base módulo compañía localidad	      --
-- Ultima Correccion: 							      --
-- Motivo Correccion: 							      --
--------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_demonios	VARCHAR(12)
DEFINE rm_t23		RECORD LIKE talt023.*
DEFINE rm_t03		RECORD LIKE talt003.*

DEFINE rm_g13		RECORD LIKE gent013.*

DEFINE vm_top		SMALLINT
DEFINE vm_left		SMALLINT
DEFINE vm_right		SMALLINT
DEFINE vm_bottom	SMALLINT
DEFINE vm_page		SMALLINT

DEFINE vm_fecha_ini	DATE
DEFINE vm_fecha_fin	DATE
DEFINE vm_moneda	LIKE gent013.g13_moneda

DEFINE expr_fecha	VARCHAR(250)



MAIN

DEFER QUIT 
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/errores')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 THEN   	-- Validar # parámetros correcto
	--CALL fgl_winmessage(vg_producto,'Número de parámetros incorrecto.','stop')
	CALL fl_mostrar_mensaje('Número de parámetros incorrecto.','stop')
	EXIT PROGRAM
END IF

LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_codcia   = arg_val(3)
LET vg_codloc   = arg_val(4)

LET vg_proceso = 'talp407'

CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
--#CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()

END MAIN



FUNCTION funcion_master()
DEFINE lin_menu		SMALLINT
DEFINE row_ini  	SMALLINT
DEFINE num_rows 	SMALLINT
DEFINE num_cols 	SMALLINT

CALL fl_nivel_isolation()
LET lin_menu = 0
LET row_ini  = 3
LET num_rows = 10
LET num_cols = 80
IF vg_gui = 0 THEN
	LET lin_menu = 1
	LET row_ini  = 4
	LET num_rows = 20
	LET num_cols = 78
END IF
OPEN WINDOW w_mas AT row_ini, 2 WITH num_rows ROWS, num_cols COLUMNS
    ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE lin_menu,BORDER,
	      MESSAGE LINE LAST - 1)
IF vg_gui = 1 THEN
	OPEN FORM f_rep FROM '../forms/talf407_1'
ELSE
	OPEN FORM f_rep FROM '../forms/talf407_1c'
END IF
DISPLAY FORM f_rep
CALL borrar_cabecera()
CALL control_reporte()

END FUNCTION



FUNCTION control_reporte()
DEFINE query		CHAR(600)
DEFINE comando 		VARCHAR(100)
DEFINE r_report 	RECORD
	orden		LIKE talt023.t23_orden,
	cliente		LIKE talt023.t23_nom_cliente,
	fecha		DATE,
	total_ot	LIKE talt023.t23_tot_neto,
	estado_ot	LIKE talt023.t23_estado
	END RECORD

LET vm_top    = 0
LET vm_left   = 20
LET vm_right  = 90
LET vm_bottom = 4
LET vm_page   = 66

LET vm_moneda = rg_gen.g00_moneda_base
CALL fl_lee_moneda(vm_moneda) RETURNING rm_g13.*
DISPLAY rm_g13.g13_nombre TO nom_moneda
LET vm_fecha_fin = TODAY

WHILE TRUE

	CALL lee_parametros()
	IF int_flag THEN
		EXIT WHILE
	END IF
	CALL fl_control_reportes() RETURNING comando
	IF int_flag THEN
		CONTINUE WHILE
	END IF

	LET query = 'SELECT t30_num_gasto, t30_num_ot, DATE(t23_fecing),',
			'   t23_tot_neto, t23_estado',
			'  FROM talt023 ',
			'WHERE t23_compania  =',vg_codcia,
			'  AND t23_localidad =',vg_codloc,
			'  AND t23_moneda = "',vm_moneda,'"',
			'  AND ',expr_fecha CLIPPED,
			' ORDER BY 3'

	PREPARE reporte FROM query
	DECLARE q_reporte CURSOR FOR reporte
	OPEN    q_reporte
	FETCH   q_reporte
	IF STATUS = NOTFOUND THEN
		CLOSE q_reporte
		FREE  q_reporte
		CALL fl_mensaje_consulta_sin_registros()
		CONTINUE WHILE
	END IF
{
	START REPORT report_ordenes_trabajo TO PIPE comando
	CLOSE q_reporte

	FOREACH q_reporte INTO r_report.* 
		OUTPUT TO REPORT report_ordenes_trabajo(r_report.*)
		IF int_flag THEN
			EXIT FOREACH
		END IF
	END FOREACH
	FINISH REPORT report_ordenes_trabajo
}
END WHILE 

END FUNCTION



FUNCTION lee_parametros()
DEFINE r_t03		RECORD LIKE talt003.*

INITIALIZE r_t03.* TO NULL

OPTIONS INPUT WRAP
LET int_flag = 0
INPUT BY NAME rm_t03.t03_mecanico, vm_fecha_ini, vm_fecha_fin, vm_moneda  
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		LET int_flag = 1
		RETURN
        ON KEY(F1,CONTROL-W)
		CALL llamar_visor_teclas()
	ON KEY(F2)
		IF INFIELD(t03_mecanico) THEN
			CALL fl_ayuda_mecanicos(vg_codcia, 'T')
				RETURNING r_t03.t03_mecanico, r_t03.t03_nombres
			IF r_t03.t03_mecanico IS NOT NULL THEN
				LET rm_t03.t03_mecanico = r_t03.t03_mecanico
				DISPLAY BY NAME rm_t03.t03_mecanico
				DISPLAY r_t03.t03_nombres TO nom_mecanico
			END IF
		END IF
		IF INFIELD(vm_moneda) THEN
        		CALL fl_ayuda_monedas()
	               		RETURNING rm_g13.g13_moneda, rm_g13.g13_nombre,
					  rm_g13.g13_decimales
			IF rm_g13.g13_moneda IS NOT NULL THEN
				LET vm_moneda = rm_g13.g13_moneda
				DISPLAY BY NAME vm_moneda
				DISPLAY rm_g13.g13_nombre TO nom_moneda
			END IF
		END IF
		LET int_flag = 0
	BEFORE INPUT
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
	AFTER FIELD t03_mecanico
		IF rm_t03.t03_mecanico IS NOT NULL THEN
			CALL fl_lee_mecanico(vg_codcia, rm_t03.t03_mecanico)	
				RETURNING r_t03.*
			IF r_t03.t03_mecanico IS NULL THEN
				CLEAR nom_mecanico
				--CALL fgl_winmessage(vg_producto,'No existe Mecánico en la Compañía.','exclamation')
				CALL fl_mostrar_mensaje('No existe Mecánico en la Compañía.','exclamation')
				NEXT FIELD t03_mecanico
			ELSE
				LET rm_t03.* = r_t03.*
				DISPLAY r_t03.t03_nombres TO nom_mecanico
			END IF
		ELSE
			CLEAR nom_mecanico
		END IF
	AFTER FIELD vm_moneda
		IF vm_moneda IS NOT NULL THEN
			CALL fl_lee_moneda(vm_moneda)
				RETURNING rm_g13.*
			IF rm_g13.g13_moneda IS NULL THEN
				--CALL fgl_winmessage(vg_producto,'No existe la moneda en la Compañía.','exclamation')
				CALL fl_mostrar_mensaje('No existe la moneda en la Compañía.','exclamation')
				CLEAR nom_moneda
				NEXT FIELD vm_moneda
			ELSE
				LET vm_moneda = rm_g13.g13_moneda
				DISPLAY BY NAME vm_moneda
				DISPLAY rm_g13.g13_nombre TO nom_moneda
			END IF
		ELSE
			CLEAR nom_moneda
		END IF
	AFTER INPUT 
		IF vm_fecha_ini IS NULL THEN
			NEXT FIELD vm_fecha_ini
		END IF
		IF vm_fecha_fin IS NULL THEN
			NEXT FIELD vm_fecha_fin
		END IF
		IF vm_moneda IS NULL THEN
			NEXT FIELD vm_moneda
		END IF
		IF vm_fecha_fin < vm_fecha_ini THEN
			--CALL fgl_winmessage(vg_producto,'La fecha final debe ser menor a la fecha inicial.','exclamation')
			CALL fl_mostrar_mensaje('La fecha final debe ser menor a la fecha inicial.','exclamation')
			NEXT FIELD vm_fecha_fin
		END IF
		LET expr_fecha = 'DATE(t23_fecing) BETWEEN "',vm_fecha_ini,'"', ' AND ', '"',vm_fecha_fin,'"'
END INPUT

END FUNCTION



FUNCTION borrar_cabecera()

CLEAR FORM
INITIALIZE rm_t03.*, vm_fecha_ini, vm_fecha_fin TO NULL

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
