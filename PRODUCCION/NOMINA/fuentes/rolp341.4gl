--------------------------------------------------------------------------------
-- Titulo           : rolp341.4gl - CONSULTA DE ACUMULADOS DE FONDO DE CESANTIA
-- Elaboracion      : 19-nov-2003
-- Autor            : JCM
-- Formato Ejecucion: fglrun rolp341 BD MODULO COMPANIA 
-- Ultima Correccion:
-- Motivo Correccion: 
--------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_num_rows	SMALLINT
DEFINE vm_max_rows	SMALLINT
DEFINE vm_row_current	SMALLINT
DEFINE vm_r_rows	ARRAY[1000] OF INTEGER

DEFINE rm_cia		RECORD LIKE rolt001.*
DEFINE rm_par	RECORD 
	n80_ano		LIKE rolt080.n80_ano,
	n80_mes		LIKE rolt080.n80_mes,
	nom_mes		VARCHAR(13)	
END RECORD
DEFINE vm_cod_trab ARRAY[500]  	OF LIKE rolt030.n30_cod_trab
DEFINE rm_scr	ARRAY[500]	OF RECORD
	n30_nombres		LIKE rolt030.n30_nombres,
	capital			LIKE rolt081.n81_cap_trab,
	interes			LIKE rolt081.n81_cap_trab,
	retiro			LIKE rolt081.n81_cap_trab,
	subtotal		LIKE rolt081.n81_cap_trab
END RECORD
DEFINE vm_numelm		SMALLINT
DEFINE vm_maxelm		SMALLINT



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/rolp341.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 3 THEN     -- Validar # parámetros correcto
	--CALL fgl_winmessage(vg_producto,'Número de parámetros incorrecto.','stop')
	CALL fl_mostrar_mensaje('Número de parámetros incorrecto.','stop')
	EXIT PROGRAM
END IF
LET vg_base      = arg_val(1)
LET vg_modulo    = arg_val(2)
LET vg_codcia    = arg_val(3)
LET vg_proceso = 'rolp341'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()
--#CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()

END MAIN



FUNCTION funcion_master()

CALL fl_nivel_isolation()

OPEN WINDOW wf AT 3,2 WITH 22 ROWS, 80 COLUMNS
    ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE LAST ,BORDER,
     		MESSAGE LINE LAST - 1)
OPTIONS INPUT WRAP,
	ACCEPT KEY	F12
OPEN FORM f_rol FROM "../forms/rolf341_1"
DISPLAY FORM f_rol

LET vm_maxelm   = 500
LET vm_max_rows = 1000

LET vm_row_current = 0
LET vm_max_rows    = 0

MENU 'OPCIONES'
	BEFORE MENU
		CLEAR FORM
		CALL mostrar_botones()
		HIDE OPTION 'Detalle'
		HIDE OPTION 'Imprimir'
	COMMAND KEY ('C') 'Consultar' 'Consulta las polizas existentes.'
		CALL control_consulta()
		IF vm_num_rows > 0 THEN
			SHOW OPTION 'Imprimir'
			IF vm_numelm > 0 THEN
				SHOW OPTION 'Detalle'
			ELSE
				HIDE OPTION 'Detalle'
			END IF	
		END IF
	COMMAND KEY ('D') 'Detalle' 'Permite navegar en el detalle.'
		CALL control_detalle('In')
	COMMAND KEY ('I') 'Imprimir' 'Imprime el listado de intereses distribuidos.'
		CALL control_imprimir()
	COMMAND KEY ('S') 'Salir' 'Regresa al menu principal.'
		EXIT MENU
END MENU

CLOSE WINDOW wf

END FUNCTION



FUNCTION control_consulta()
DEFINE r_n81		RECORD LIKE rolt081.*

CALL fl_lee_compania_roles(vg_codcia) RETURNING rm_cia.*
IF rm_cia.n01_compania IS NULL THEN
	--CALL fgl_winmessage(vg_producto,'No existe compañía.','stop')
	CALL fl_mostrar_mensaje('No existe compañía.','stop')
	EXIT PROGRAM
END IF

CLEAR FORM
CALL mostrar_botones()

INITIALIZE rm_par.* TO NULL
CALL ingresar_valores()
IF int_flag = 1 THEN
	LET int_flag = 0
	RETURN 
END IF
RETURN 

END FUNCTION



FUNCTION ingresar_valores()
DEFINE resp		CHAR(6)
DEFINE query		VARCHAR(1000)
DEFINE i		SMALLINT

DEFINE r_n80		RECORD LIKE rolt080.*

INPUT BY NAME rm_par.*
	ON KEY(INTERRUPT)
        	IF field_touched(n80_ano, n80_mes) THEN
               		LET int_flag = 0
			CALL fl_mensaje_abandonar_proceso()
                		RETURNING resp
              		IF resp = 'Yes' THEN
				LET int_flag = 1
                       		EXIT INPUT
                	END IF
		ELSE
                       	EXIT INPUT
		END IF
	ON KEY(F2)
		IF INFIELD(n80_mes) THEN
			CALL fl_ayuda_mostrar_meses()
				RETURNING rm_par.n80_mes, rm_par.nom_mes
			DISPLAY BY NAME rm_par.*
		END IF
		LET int_flag = 0
	AFTER FIELD n80_mes
		IF rm_par.n80_mes IS NULL THEN
			CONTINUE INPUT
		END IF
		LET rm_par.nom_mes = fl_retorna_nombre_mes(rm_par.n80_mes)
		DISPLAY BY NAME rm_par.*
END INPUT
IF int_flag THEN
	CALL mostrar_registro_actual()
	RETURN
END IF

CALL mostrar_registro_actual()

END FUNCTION



FUNCTION mostrar_botones()
	
DISPLAY 'Nombre Trabajador'	TO bt_nomtrab
DISPLAY 'Capital'		TO bt_capital
DISPLAY 'Interes'		TO bt_interes
DISPLAY 'Retiro'		TO bt_dscto
DISPLAY 'Total'			TO bt_subtotal

END FUNCTION



FUNCTION mostrar_registro_actual()
CLEAR FORM 
CALL mostrar_botones()

DISPLAY BY NAME rm_par.*
CALL mostrar_detalle()

END FUNCTION



FUNCTION muestra_siguiente_registro()

IF vm_row_current < vm_num_rows THEN
	LET vm_row_current = vm_row_current + 1
END IF
CALL mostrar_registro_actual()

END FUNCTION



FUNCTION muestra_registro_anterior()

IF vm_row_current > 1 THEN
	LET vm_row_current = vm_row_current - 1
END IF
CALL mostrar_registro_actual()

END FUNCTION



FUNCTION mostrar_detalle()
DEFINE r_n80		RECORD LIKE rolt080.*
DEFINE tot_capital	LIKE rolt080.n80_sac_trab
DEFINE tot_interes	LIKE rolt080.n80_sac_int
DEFINE tot_retiro	LIKE rolt080.n80_sac_trab
DEFINE total		LIKE rolt080.n80_sac_trab
	
DECLARE q_int CURSOR FOR
	SELECT rolt080.*, n30_nombres 
		FROM rolt080, rolt030 
		WHERE n80_compania = vg_codcia
		  AND n80_ano      = rm_par.n80_ano
		  AND n80_mes      = rm_par.n80_mes
		  AND n30_compania = n80_compania
		  AND n30_cod_trab = n80_cod_trab
		ORDER BY n30_nombres

LET tot_capital = 0
LET tot_interes = 0
LET tot_retiro   = 0
LET total       = 0
LET vm_numelm = 1
FOREACH q_int INTO r_n80.*, rm_scr[vm_numelm].n30_nombres 
	LET rm_scr[vm_numelm].capital  = r_n80.n80_sac_trab +
				  	 r_n80.n80_sac_patr 
	LET rm_scr[vm_numelm].interes  = r_n80.n80_sac_int + r_n80.n80_sac_dscto
	LET rm_scr[vm_numelm].retiro   = r_n80.n80_val_retiro
	LET rm_scr[vm_numelm].subtotal = rm_scr[vm_numelm].capital +
					 rm_scr[vm_numelm].interes +
					 rm_scr[vm_numelm].retiro

	LET tot_capital = tot_capital + rm_scr[vm_numelm].capital
	LET tot_interes = tot_interes + rm_scr[vm_numelm].interes
	LET tot_retiro  = tot_retiro + rm_scr[vm_numelm].retiro
	LET total = total + rm_scr[vm_numelm].subtotal

	LET vm_numelm = vm_numelm + 1 
	IF vm_numelm > vm_maxelm THEN
		CALL fl_mensaje_arreglo_incompleto()
		EXIT PROGRAM
	END IF
END FOREACH
LET vm_numelm = vm_numelm - 1
LET vm_num_rows = vm_numelm

IF vm_numelm = 0 THEN
	RETURN
END IF

DISPLAY BY NAME tot_capital, tot_interes, tot_retiro, total

CALL control_detalle('Out')

END FUNCTION



FUNCTION control_detalle(ArrayInOut)
DEFINE ArrayInOut		CHAR(3)

CALL set_count(vm_numelm)
DISPLAY ARRAY rm_scr TO ra_scr.*
	BEFORE DISPLAY
		IF ArrayInOut = 'Out' THEN
			EXIT DISPLAY
		END IF
	ON KEY (INTERRUPT)
		LET int_flag = 0
		EXIT DISPLAY
END DISPLAY

END FUNCTION



FUNCTION control_imprimir()
DEFINE comando VARCHAR(500)

LET comando = 'fglrun rolp440 ', vg_base, ' ', vg_modulo, ' ', vg_codcia, ' ',
	      rm_par.n80_ano, ' ', rm_par.n80_mes 

RUN comando

END FUNCTION
