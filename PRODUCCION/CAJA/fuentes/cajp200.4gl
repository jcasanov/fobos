-------------------------------------------------------------------------------
-- Titulo               : cajp200.4gl -- Apertura de Caja
-- Elaboración          : 20-nov-2001
-- Autor                : GVA
-- Formato de Ejecución : fglrun  cajp200 base modulo compania 
-- Ultima Correción     : 20-nov-2001
-- Motivo Corrección    : 1
--------------------------------------------------------------------------------
                                                                                
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'
                                                                                
DEFINE rm_j04   	RECORD LIKE cajt004.*
DEFINE rm_j02   	RECORD LIKE cajt002.*
DEFINE vm_detalle	SMALLINT

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
CALL startlog('../logs/cajp200.error')
CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 THEN
     CALL FGL_WINMESSAGE(vg_producto,'Número de parámetros incorrecto','stop')
     EXIT PROGRAM
END IF
LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_codcia   = arg_val(3)
LET vg_codloc   = arg_val(4)
LET vg_proceso = 'cajp200'

CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()
CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)

CALL funcion_master()
                                                                                
END MAIN



FUNCTION funcion_master()
DEFINE flag	SMALLINT

CALL fl_nivel_isolation()

OPEN WINDOW w_200 AT 3,2 WITH 20 ROWS, 80 COLUMNS
    ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE 0, BORDER,
	      MESSAGE LINE LAST - 2)
OPEN FORM f_200 FROM '../forms/cajf200_1'
DISPLAY FORM f_200

CALL control_display_botones()

INITIALIZE rm_j04.*, rm_j02.* TO NULL

MENU 'OPCIONES'
	BEFORE MENU
		HIDE OPTION 'Ver Detalle'
		LET flag = control_validar_apertura()
		IF flag = 0 THEN
			HIDE OPTION 'Aperturar'
		END IF
		IF vm_detalle > FGL_SCR_SIZE('r_detalle') THEN
			SHOW OPTION 'Ver Detalle'
		END IF

	COMMAND KEY('V') 'Ver Detalle' 'Ver Detalle de la apertura.'
		CALL control_display_array_cajt005()

	COMMAND KEY('P') 'Aperturar' 	
		LET flag = control_apertura()
		IF flag THEN
			HIDE OPTION 'Aperturar'
		END IF

	COMMAND KEY('S') 'Salir' 	
		EXIT MENU

END MENU

END FUNCTION



FUNCTION control_display_botones()
	
	DISPLAY 'Moneda' 		 TO tit_col1
	DISPLAY 'Efectivo Apertura'	 TO tit_col2
	DISPLAY 'Cheque Apertura'  	 TO tit_col3
	DISPLAY 'Total'		  	 TO tit_col4

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



FUNCTION control_validar_apertura()
DEFINE r_g13		RECORD LIKE gent013.*
DEFINE r_j05		RECORD LIKE cajt005.*
DEFINE i 		SMALLINT

CALL fl_retorna_caja(vg_codcia, vg_codloc, vg_usuario)
	RETURNING rm_j02.*

IF rm_j02.j02_usua_caja IS NULL THEN
	CALL FGL_WINMESSAGE(vg_producto,'El usuario '|| vg_usuario || ' no tiene asignada una caja.','exclamation')
	RETURN 0
END IF

FOR i = 1 TO FGL_SCR_SIZE('r_detalle')
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
	CALL FGL_WINMESSAGE(vg_producto,'La caja ' || rm_j02.j02_nombre_caja ||
' no ha sido cerrada en la fecha '|| rm_j04.j04_fecha_aper || '.', 'exclamation')
	RETURN 0
END IF

IF rm_j04.j04_fecha_aper = TODAY AND
   rm_j04.j04_fecha_cierre IS NOT NULL 
   THEN
	CALL FGL_WINMESSAGE(vg_producto,'La caja no puede ser aperturada más de una vez el mismo día. Si desea puede reaperturarla.','exclamation')
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
CALL fl_recalcula_saldos_clientes(vg_codcia, vg_codloc)
CALL fl_recalcula_saldos_proveedores(vg_codcia, vg_codloc)
CALL fgl_winmessage(vg_producto,'La caja ha sido aperturada.','info')
RETURN 1

END FUNCTION



FUNCTION validar_parametros()
                                                                                
CALL fl_lee_modulo(vg_modulo) RETURNING rg_mod.*
IF rg_mod.g50_modulo IS NULL THEN
        CALL FGL_WINMESSAGE(vg_producto, 'No existe módulo: ' || vg_modulo,
 			    'stop')
        EXIT PROGRAM
END IF
CALL fl_lee_compania(vg_codcia) RETURNING rg_cia.*
IF rg_cia.g01_compania IS NULL THEN
        CALL FGL_WINMESSAGE(vg_producto, 'No existe compañía: '|| vg_codcia,
			    'stop')
        EXIT PROGRAM
END IF
IF rg_cia.g01_estado <> 'A' THEN
     CALL FGL_WINMESSAGE(vg_producto, 'Compañía no está activa: ' 
			 || vg_codcia, 'stop')
     EXIT PROGRAM
END IF
IF vg_codloc IS NULL THEN
        LET vg_codloc   = fl_retorna_agencia_default(vg_codcia)
END IF
CALL fl_lee_localidad(vg_codcia, vg_codloc) RETURNING rg_loc.*
IF rg_loc.g02_localidad IS NULL THEN
        CALL FGL_WINMESSAGE(vg_producto, 'No existe localidad: ' || vg_codloc,
			    'stop')
        EXIT PROGRAM
END IF
IF rg_loc.g02_estado <> 'A' THEN
      CALL FGL_WINMESSAGE(vg_producto, 'Localidad no está activa: '|| vg_codloc, 			  'stop')
      EXIT PROGRAM
END IF
                                                                                
END FUNCTION

