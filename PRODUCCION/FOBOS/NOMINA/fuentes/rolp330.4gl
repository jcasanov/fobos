------------------------------------------------------------------------------
-- Titulo           : rolp330.4gl - Consulta de Trabajadores Afiliados
--			            al Club
-- Elaboracion      : 17-sep-2003
-- Autor            : JCM
-- Formato Ejecucion: fglrun rolp330 base módulo compañía
-- Ultima Correccion: 
-- Motivo Correccion: 
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE rm_n00		RECORD LIKE rolt000.*

DEFINE vm_filas_pant	INTEGER
DEFINE vm_numelm	INTEGER
DEFINE vm_maxelm	INTEGER
DEFINE rm_scr ARRAY[1000] OF RECORD 
	n61_cod_trab		LIKE rolt061.n61_cod_trab,
	n_trab			LIKE rolt030.n30_nombres,
	n61_fec_ing_club	LIKE rolt061.n61_fec_ing_club,
	n61_cuota		LIKE rolt061.n61_cuota
END RECORD	



MAIN

DEFER QUIT 
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/errores')
CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 3 THEN          -- Validar # parámetros correcto
	CALL fgl_winmessage(vg_producto, 'Número de parámetros incorrecto', 'stop')
	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_proceso = 'rolp330'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
--#CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL control_master()

END MAIN



FUNCTION control_master()

DEFINE salir		INTEGER
DEFINE r_n01		RECORD LIKE rolt001.*

CALL fl_nivel_isolation()
LET vm_maxelm	= 1000

OPEN WINDOW wf AT 3,2 WITH 22 ROWS, 80 COLUMNS
    ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE FIRST,BORDER,
	      MESSAGE LINE LAST - 2)
OPTIONS INPUT WRAP,
	ACCEPT KEY	F12
OPEN FORM f_rol FROM "../forms/rolf330_1"
DISPLAY FORM f_rol

INITIALIZE rm_n00.* TO NULL
CALL fl_lee_parametro_general_roles() RETURNING rm_n00.*
IF rm_n00.n00_moneda_pago IS NULL THEN
	CALL fl_mostrar_mensaje('No se han configurado parametros generales de roles.', 'stop')
	EXIT PROGRAM
END IF

CALL fl_lee_compania_roles(vg_codcia) RETURNING r_n01.*
IF r_n01.n01_compania IS NULL THEN
        CALL fgl_winmessage(vg_producto,
                'No existe configuración para esta compañía.',
                'stop')
        EXIT PROGRAM
END IF
IF r_n01.n01_estado <> 'A' THEN
        CALL fgl_winmessage(vg_producto,
                'Compañía no está activa.', 'stop')
        EXIT PROGRAM
END IF

CALL mostrar_botones()
LET salir = control_proceso_master()

END FUNCTION



FUNCTION carga_trabajadores()
DEFINE tot_cuota	LIKE rolt061.n61_cuota
DEFINE num_trab		SMALLINT

DECLARE q_trab CURSOR FOR 
	SELECT n30_cod_trab, n30_nombres, n61_fec_ing_club, n61_cuota
        	--FROM rolt030, OUTER rolt061 
        	FROM rolt030, rolt061 
            	WHERE n30_compania      = vg_codcia
            	  AND n30_estado        = "A" 
                  AND n30_fecha_ing    <= CURRENT 
	          AND n61_compania      = n30_compania
		  AND n61_cod_trab      = n30_cod_trab
		  AND n61_fec_sal_club IS NULL
             	ORDER BY n30_nombres  
                                                                                
LET tot_cuota = 0
LET num_trab  = 0
LET vm_numelm = 1
FOREACH q_trab INTO rm_scr[vm_numelm].*
	IF rm_scr[vm_numelm].n61_cuota IS NULL THEN
		LET rm_scr[vm_numelm].n61_cuota = 0
	END IF
	LET tot_cuota = tot_cuota + rm_scr[vm_numelm].n61_cuota 
	LET num_trab = num_trab + 1
        LET vm_numelm = vm_numelm + 1
        IF vm_numelm > vm_maxelm THEN
                CALL fl_mensaje_arreglo_incompleto()
                EXIT PROGRAM
        END IF
END FOREACH
FREE q_trab

LET vm_numelm = vm_numelm - 1
DISPLAY BY NAME tot_cuota, num_trab

END FUNCTION



FUNCTION mostrar_botones()
                                                                                
DISPLAY 'Cod.'                  TO bt_cod_trab
DISPLAY 'Nombre Trabajador'     TO bt_n_trab
DISPLAY 'Fecha Afi.'            TO bt_fecha
DISPLAY 'Cuota'                 TO bt_cuota
                                                                                
END FUNCTION
               


FUNCTION control_proceso_master()
	
CALL carga_trabajadores()

CALL set_count(vm_numelm)
DISPLAY ARRAY rm_scr TO ra_scr.*
IF int_flag THEN
	LET int_flag = 0
	RETURN 1
END IF
	
RETURN 0

END FUNCTION
