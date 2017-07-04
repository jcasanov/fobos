--------------------------------------------------------------------------------
-- Titulo           : menp002c.4gl - MENU PRINCIPAL DE FHOBOS VENDEDORES
-- Elaboracion      : 11-Dic-2001
-- Autor            : NPC
-- Formato Ejecucion: fglgo menp002c base modulo
-- Ultima Correccion: 
-- Motivo Correccion: 
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_titprog 	VARCHAR(50)
DEFINE vm_rows 		ARRAY[1000] OF INTEGER  -- ARREGLO DE ROWID DE FILAS LEIDAS
DEFINE vm_row_current 	SMALLINT	-- FILA CORRIENTE DEL ARREGLO
DEFINE vm_num_rows 	SMALLINT	-- CANTIDAD DE FILAS LEIDAS
DEFINE ejecuta		CHAR(100)
--DEFINE fondo		CHAR(25)
DEFINE fondo_pp		CHAR(25)
DEFINE fondo_phobos 	CHAR(25)
DEFINE a		CHAR(25)



MAIN

DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/menp002c.err')
--#CALL fgl_init4js()
IF num_args() <> 2 THEN          -- Validar # parámetros correcto
     CALL fl_mostrar_mensaje('Número de parámetros incorrecto.','stop')
     EXIT PROGRAM
END IF
LET vg_base      = arg_val(1)
LET vg_modulo    = arg_val(2)
LET vg_proceso   = 'menp002c'
LET vm_titprog   = 'MENU PHOBOS - VENDEDORES'
LET fondo_pp     = 'phobos_biger'
LET fondo_phobos = 'phobos_titulo'
--LET fondo      = 'phobos_small'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()
CALL fl_validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()

END MAIN



FUNCTION funcion_master()

CALL menu_vendedores()
EXIT PROGRAM
                                                                                
END FUNCTION



FUNCTION menu_vendedores()
DEFINE r_menu_ven	ARRAY[7] OF RECORD
		                opcion  CHAR(40)
		        END RECORD
DEFINE a_c_2, s_c_2	SMALLINT

OPEN WINDOW w_menu_vendedores AT 4,2 WITH 20 ROWS, 78 COLUMNS
ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE FIRST,
	  BORDER, MESSAGE LINE LAST - 1) 
OPEN FORM f_menf200c FROM '../forms/menf200c'
DISPLAY FORM f_menf200c

LET r_menu_ven[1].opcion   = 'Proforma'
LET r_menu_ven[2].opcion   = 'Consulta Proforma'
LET r_menu_ven[3].opcion   = 'Consulta de Items'
LET r_menu_ven[4].opcion   = 'Consulta Items Pend.'
LET r_menu_ven[5].opcion   = 'Inventario Fisico'
LET r_menu_ven[6].opcion   = 'Cons. Inv. Fisico'
LET r_menu_ven[7].opcion   = 'SALIR'

CALL set_count(7)
WHILE TRUE
        LET int_flag = 0
        DISPLAY ARRAY r_menu_ven TO r_menu_ven.*
                ON KEY(INTERRUPT)
        		LET int_flag = 1
                        EXIT DISPLAY
                ON KEY(RETURN)
        		LET int_flag = 0
                        EXIT DISPLAY
        END DISPLAY
        IF int_flag = 1 THEN
                EXIT WHILE
        END IF
        IF int_flag = 0 THEN
                LET a_c_2 = arr_curr()
		IF a_c_2 = 7 THEN
			EXIT WHILE
		END IF
		CASE a_c_2
			WHEN 1
				IF NOT fl_control_acceso_proceso_men(vg_usuario,
						vg_codcia, 'RE', 'repp220')
				THEN
					EXIT CASE
				END IF
				LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglgo repp220 ', vg_base, ' ', 'RE', vg_codcia, vg_codloc
				RUN ejecuta
			WHEN 2
				IF NOT fl_control_acceso_proceso_men(vg_usuario,
						vg_codcia, 'RE', 'repp306')
				THEN
					EXIT CASE
				END IF
				LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglgo repp306 ', vg_base, ' ', 'RE', vg_codcia, vg_codloc
				RUN ejecuta
			WHEN 3
				IF NOT fl_control_acceso_proceso_men(vg_usuario,
						vg_codcia, 'RE', 'repp300')
				THEN
					EXIT CASE
				END IF
				LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglgo repp300 ', vg_base, ' ', 'RE', vg_codcia, vg_codloc
				RUN ejecuta
			WHEN 4
				IF NOT fl_control_acceso_proceso_men(vg_usuario,
						vg_codcia, 'RE', 'repp318')
				THEN
					EXIT CASE
				END IF
				LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglgo repp318 ', vg_base, ' ', 'RE', vg_codcia, vg_codloc
				RUN ejecuta
			WHEN 5
				IF NOT fl_control_acceso_proceso_men(vg_usuario,
						vg_codcia, 'RE', 'repp239')
				THEN
					EXIT CASE
				END IF
				LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglgo repp239 ', vg_base, ' ', 'RE', vg_codcia, ' ', vg_codloc
				RUN ejecuta
			WHEN 6
				IF NOT fl_control_acceso_proceso_men(vg_usuario,
						vg_codcia, 'RE', 'repp317')
				THEN
					EXIT CASE
				END IF
				LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglgo repp317 ', vg_base, ' ', 'RE', vg_codcia, ' ', vg_codloc
				RUN ejecuta
		END CASE

        END IF
END WHILE
CLOSE WINDOW w_menu_vendedores
                                                                                
END FUNCTION
