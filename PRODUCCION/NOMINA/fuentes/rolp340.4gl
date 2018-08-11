--------------------------------------------------------------------------------
-- Titulo           : rolp340.4gl - DISTRIBUCION DE INTERESES FONDO DE CESANTIA
-- Elaboracion      : 07-nov-2003
-- Autor            : JCM
-- Formato Ejecucion: fglrun rolp340 BD MODULO COMPANIA 
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
	n81_num_poliza		LIKE rolt081.n81_num_poliza,
	n81_estado		LIKE rolt081.n81_estado,
	n_estado		VARCHAR(15),
	n81_fec_vcto		LIKE rolt081.n81_fec_vcto,
	n81_fec_distri		LIKE rolt081.n81_fec_distri,
	cap_poliza		LIKE rolt081.n81_cap_trab,
	n81_porc_int		LIKE rolt081.n81_porc_int,
	n81_val_int		LIKE rolt081.n81_val_int,
	n81_val_dscto		LIKE rolt081.n81_val_dscto
END RECORD
DEFINE vm_cod_trab ARRAY[500]  	OF LIKE rolt030.n30_cod_trab
DEFINE rm_scr	ARRAY[500]	OF RECORD
	n30_nombres		LIKE rolt030.n30_nombres,
	capital			LIKE rolt081.n81_cap_trab,
	interes			LIKE rolt081.n81_cap_trab,
	dscto			LIKE rolt081.n81_cap_trab,
	subtotal		LIKE rolt081.n81_cap_trab
END RECORD
DEFINE vm_numelm		SMALLINT
DEFINE vm_maxelm		SMALLINT



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/rolp340.err')
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
LET vg_proceso = 'rolp340'
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
OPEN FORM f_rol FROM "../forms/rolf340_1"
DISPLAY FORM f_rol

LET vm_maxelm   = 500
LET vm_max_rows = 1000

LET vm_row_current = 0
LET vm_max_rows    = 0

MENU 'OPCIONES'
	BEFORE MENU
		CLEAR FORM
		CALL mostrar_botones()
		CALL muestra_contadores(vm_row_current, vm_num_rows)
		HIDE OPTION 'Avanzar'
		HIDE OPTION 'Retroceder'
		HIDE OPTION 'Detalle'
		HIDE OPTION 'Imprimir'
	COMMAND KEY ('C') 'Consultar' 'Consulta las polizas existentes.'
		CALL control_consulta()
		IF vm_num_rows > 0 THEN
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
			SHOW OPTION 'Imprimir'
			IF vm_row_current = 1 THEN
				SHOW OPTION 'Avanzar'
				HIDE OPTION 'Retroceder'
			END IF
			IF vm_row_current = vm_max_rows THEN
				HIDE OPTION 'Avanzar'
				SHOW OPTION 'Retroceder'
			END IF 
			IF vm_num_rows = 1 THEN
				HIDE OPTION 'Retroceder'
				HIDE OPTION 'Avanzar'
			END IF
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
	COMMAND KEY ('A') 'Avanzar' 'Muestra el siguiente registro.'
		CALL muestra_siguiente_registro()
		SHOW OPTION 'Avanzar'
		SHOW OPTION 'Retroceder'
		IF vm_row_current = 1 THEN
			SHOW OPTION 'Avanzar'
			HIDE OPTION 'Retroceder'
		END IF
		IF vm_row_current = vm_max_rows THEN
			HIDE OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
		END IF 
		IF vm_num_rows = 1 THEN
			HIDE OPTION 'Retroceder'
			HIDE OPTION 'Avanzar'
		END IF
		IF vm_numelm > 0 THEN
			SHOW OPTION 'Detalle'
		ELSE
			HIDE OPTION 'Detalle'
		END IF	
	COMMAND KEY ('R') 'Retroceder' 'Muestra el registro anterior.'
		CALL muestra_registro_anterior()
		SHOW OPTION 'Avanzar'
		SHOW OPTION 'Retroceder'
		IF vm_row_current = 1 THEN
			SHOW OPTION 'Avanzar'
			HIDE OPTION 'Retroceder'
		END IF
		IF vm_row_current = vm_max_rows THEN
			HIDE OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
		END IF 
		IF vm_num_rows = 1 THEN
			HIDE OPTION 'Retroceder'
			HIDE OPTION 'Avanzar'
		END IF
		IF vm_numelm > 0 THEN
			SHOW OPTION 'Detalle'
		ELSE
			HIDE OPTION 'Detalle'
		END IF	
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
DEFINE expr_sql		VARCHAR(500)
DEFINE i		SMALLINT

DEFINE r_n81		RECORD LIKE rolt081.*

CONSTRUCT BY NAME expr_sql ON n81_num_poliza, n81_estado, n81_fec_vcto,
			      n81_fec_distri 
	ON KEY(INTERRUPT)
        	IF field_touched(n81_num_poliza, n81_estado, n81_fec_vcto,
				 n81_fec_distri) 
		THEN
               		LET int_flag = 0
			CALL fl_mensaje_abandonar_proceso()
                		RETURNING resp
              		IF resp = 'Yes' THEN
				LET int_flag = 1
                       		EXIT CONSTRUCT
                	END IF
		ELSE
                       	EXIT CONSTRUCT
		END IF
	ON KEY(F2)
		IF INFIELD(n81_num_poliza) THEN
			CALL fl_ayuda_poliza_fondo_cen(vg_codcia, 'T')
				RETURNING rm_par.n81_num_poliza
				DISPLAY BY NAME rm_par.n81_num_poliza
		END IF
		LET int_flag = 0
END CONSTRUCT
IF int_flag THEN
	CALL mostrar_registro_actual()
	RETURN
END IF

LET query = 'SELECT *, ROWID FROM rolt081 ',
		' WHERE n81_compania = ', vg_codcia,
		'   AND ', expr_sql,
		' ORDER BY n81_compania ASC, n81_fec_vcto DESC '

PREPARE cons FROM query
DECLARE q_poliza CURSOR FOR cons

LET i = 1
FOREACH q_poliza INTO r_n81.*, vm_r_rows[i]
	LET i = i + 1
	IF i > vm_max_rows THEN
		EXIT FOREACH
	END IF
END FOREACH
LET i = i - 1
IF i = 0 THEN
	CALL fl_mensaje_consulta_sin_registros()
ELSE
	LET vm_num_rows = i
	LET vm_row_current = 1
END IF

CALL mostrar_registro_actual()

END FUNCTION



FUNCTION mostrar_botones()
	
DISPLAY 'Nombre Trabajador'	TO bt_nomtrab
DISPLAY 'Capital'		TO bt_capital
DISPLAY 'Interes'		TO bt_interes
DISPLAY 'Dscto.'		TO bt_dscto
DISPLAY 'Total'			TO bt_subtotal

END FUNCTION



FUNCTION muestra_contadores(row_current, num_rows)
DEFINE row_current	SMALLINT
DEFINE num_rows		SMALLINT
                                                                                
DISPLAY "" AT 1,1
DISPLAY row_current, " de ", num_rows AT 1, 69
                                                                                
END FUNCTION



FUNCTION mostrar_registro_actual()
DEFINE r_n81		RECORD LIKE rolt081.*

CLEAR FORM 
CALL mostrar_botones()
CALL muestra_contadores(vm_row_current, vm_num_rows)

IF vm_row_current = 0 OR vm_num_rows = 0 THEN
	RETURN
END IF

INITIALIZE r_n81.* TO NULL
SELECT * INTO r_n81.* FROM rolt081 WHERE ROWID = vm_r_rows[vm_row_current] 

LET rm_par.n81_num_poliza = r_n81.n81_num_poliza
LET rm_par.n81_estado     = r_n81.n81_estado
LET rm_par.n81_fec_vcto   = r_n81.n81_fec_vcto  
LET rm_par.n81_fec_distri = r_n81.n81_fec_distri  
LET rm_par.cap_poliza     = r_n81.n81_cap_trab + r_n81.n81_cap_patr +
		  	    r_n81.n81_cap_int  - r_n81.n81_cap_dscto
LET rm_par.n81_porc_int   = r_n81.n81_porc_int
LET rm_par.n81_val_int    = r_n81.n81_val_int
LET rm_par.n81_val_dscto  = r_n81.n81_val_dscto

CASE rm_par.n81_estado 
	WHEN 'A' 
		LET rm_par.n_estado = 'ACTIVO'
	WHEN 'P' 
		LET rm_par.n_estado = 'PROCESADO'
END CASE

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
DEFINE r_n83		RECORD LIKE rolt083.*
DEFINE tot_capital	LIKE rolt083.n83_cap_trab
DEFINE tot_interes	LIKE rolt083.n83_cap_trab
DEFINE tot_dscto	LIKE rolt083.n83_cap_trab
DEFINE total		LIKE rolt083.n83_cap_trab
	
IF rm_par.n81_estado = 'A' THEN
	CALL fl_mostrar_mensaje('Esta poliza esta activa y no tiene distribucion de intereses.', 'stop')
	RETURN
END IF

DECLARE q_int CURSOR FOR
	SELECT rolt083.*, n30_nombres 
		FROM rolt083, rolt030 
		WHERE n83_compania   = vg_codcia
		  AND n83_num_poliza = rm_par.n81_num_poliza
		  AND n30_compania   = n83_compania
		  AND n30_cod_trab   = n83_cod_trab
		ORDER BY n30_nombres

LET tot_capital = 0
LET tot_interes = 0
LET tot_dscto   = 0
LET total       = 0
LET vm_numelm = 1
FOREACH q_int INTO r_n83.*, rm_scr[vm_numelm].n30_nombres 
	LET rm_scr[vm_numelm].capital  = r_n83.n83_cap_trab +
				  	 r_n83.n83_cap_patr +
					 r_n83.n83_cap_int +
					 r_n83.n83_cap_dscto
	LET rm_scr[vm_numelm].interes  = r_n83.n83_val_int
	LET rm_scr[vm_numelm].dscto    = r_n83.n83_val_dscto
	LET rm_scr[vm_numelm].subtotal = rm_scr[vm_numelm].capital +
					 rm_scr[vm_numelm].interes +
					 rm_scr[vm_numelm].dscto 

	LET tot_capital = tot_capital + rm_scr[vm_numelm].capital
	LET tot_interes = tot_interes + rm_scr[vm_numelm].interes
	LET tot_dscto = tot_dscto + rm_scr[vm_numelm].dscto
	LET total = total + rm_scr[vm_numelm].subtotal

	LET vm_numelm = vm_numelm + 1 
	IF vm_numelm > vm_maxelm THEN
		CALL fl_mensaje_arreglo_incompleto()
		EXIT PROGRAM
	END IF
END FOREACH
LET vm_numelm = vm_numelm - 1

IF vm_numelm = 0 THEN
	RETURN
END IF

DISPLAY BY NAME tot_capital, tot_interes, tot_dscto, total

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

LET comando = 'fglrun rolp441 ', vg_base, ' ', vg_modulo, ' ', vg_codcia, ' ',
	      YEAR(rm_par.n81_fec_vcto), ' ', MONTH(rm_par.n81_fec_vcto) 

RUN comando

END FUNCTION
