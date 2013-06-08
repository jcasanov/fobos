--------------------------------------------------------------------------------
-- Titulo           : menp003c.4gl - MENU PRINCIPAL DE FHOBOS BODEGUEROS
-- Elaboracion      : 11-Dic-2001
-- Autor            : NPC
-- Formato Ejecucion: fglgo menp003c base modulo
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
CALL startlog('../logs/menp003c.err')
--#CALL fgl_init4js()
IF num_args() <> 2 THEN          -- Validar # parámetros correcto
     CALL fl_mostrar_mensaje('Número de parámetros incorrecto.','stop')
     EXIT PROGRAM
END IF
LET vg_base      = arg_val(1)
LET vg_modulo    = arg_val(2)
LET vg_proceso   = 'menp003c'
LET vm_titprog   = 'MENU PHOBOS - BODEGUEROS'
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

CALL menu_bodegueros()
EXIT PROGRAM
                                                                                
END FUNCTION



FUNCTION menu_bodegueros()
DEFINE r_menu_bod	ARRAY[15] OF RECORD
		                opcion  CHAR(40)
			END RECORD
DEFINE a_c_2, s_c_2	SMALLINT

OPEN WINDOW w_menu_bodegueros AT 4,2 WITH 20 ROWS, 78 COLUMNS
ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE FIRST,
	  BORDER, MESSAGE LINE LAST - 1) 
OPEN FORM f_menf201c FROM '../forms/menf201c'
DISPLAY FORM f_menf201c

LET r_menu_bod[1].opcion   = 'Generar Nota Entrega'
LET r_menu_bod[2].opcion   = 'Consulta Orden Desp.'
LET r_menu_bod[3].opcion   = 'Consulta Items'
LET r_menu_bod[4].opcion   = 'Consulta Items Pend.'
LET r_menu_bod[5].opcion   = 'Recepción Mercadería'
LET r_menu_bod[6].opcion   = 'Transferencia'
LET r_menu_bod[7].opcion   = 'Kardex de Items'
LET r_menu_bod[8].opcion   = 'Transmisión Transf.'
LET r_menu_bod[9].opcion   = 'Inventario Físico'
LET r_menu_bod[10].opcion  = 'Consulta Inv. Físico'
LET r_menu_bod[11].opcion  = 'Traspaso a La Prensa'
LET r_menu_bod[12].opcion  = 'Guías de Remisión'
LET r_menu_bod[13].opcion  = 'Corrección GR SRI'
LET r_menu_bod[14].opcion  = 'Cons. Transferencia'
LET r_menu_bod[15].opcion  = 'SALIR'

CALL set_count(15)
WHILE TRUE
        LET int_flag = 0
        DISPLAY ARRAY r_menu_bod TO r_menu_bod.*
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
		IF a_c_2 = 15 THEN
			EXIT WHILE
		END IF
		CASE a_c_2
			WHEN 1
				IF NOT fl_control_acceso_proceso_men(vg_usuario,
						vg_codcia, 'RE', 'repp231')
				THEN
					EXIT CASE
				END IF
				LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglgo repp231 ', vg_base, ' ', 'RE', vg_codcia, vg_codloc
				RUN ejecuta
			WHEN 2
				IF NOT fl_control_acceso_proceso_men(vg_usuario,
						vg_codcia, 'RE', 'repp313')
				THEN
					EXIT CASE
				END IF
				LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglgo repp313 ', vg_base, ' ', 'RE', vg_codcia, vg_codloc
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
						vg_codcia, 'RE', 'repp214')
				THEN
					EXIT CASE
				END IF
				LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglgo repp214 ', vg_base, ' ', 'RE', vg_codcia, vg_codloc
				RUN ejecuta
			WHEN 6
				IF NOT fl_control_acceso_proceso_men(vg_usuario,
						vg_codcia, 'RE', 'repp216')
				THEN
					EXIT CASE
				END IF
				LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglgo repp216 ', vg_base, ' ', 'RE', vg_codcia, vg_codloc
				RUN ejecuta
			WHEN 7
				IF NOT fl_control_acceso_proceso_men(vg_usuario,
						vg_codcia, 'RE', 'repp307')
				THEN
					EXIT CASE
				END IF
				LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglgo repp307 ', vg_base, ' ', 'RE', vg_codcia, vg_codloc
				RUN ejecuta
			WHEN 8
				IF NOT fl_control_acceso_proceso_men(vg_usuario,
						vg_codcia, 'RE', 'repp666')
				THEN
					EXIT CASE
				END IF
				LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglgo repp666 ', vg_base, ' ', 'RE ', vg_codcia, ' ', vg_codloc
				RUN ejecuta
			WHEN 9
				IF NOT fl_control_acceso_proceso_men(vg_usuario,
						vg_codcia, 'RE', 'repp239')
				THEN
					EXIT CASE
				END IF
				LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglgo repp239 ', vg_base, ' ', 'RE', vg_codcia, ' ', vg_codloc
				RUN ejecuta
			WHEN 10
				IF NOT fl_control_acceso_proceso_men(vg_usuario,
						vg_codcia, 'RE', 'repp317')
				THEN
					EXIT CASE
				END IF
				LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglgo repp317 ', vg_base, ' ', 'RE', vg_codcia, ' ', vg_codloc
				RUN ejecuta
			WHEN 11
				IF NOT fl_control_acceso_proceso_men(vg_usuario,
						vg_codcia, 'RE', 'repp667')
				THEN
					EXIT CASE
				END IF
				LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglgo repp667 ', vg_base, ' ', 'RE', vg_codcia, ' ', vg_codloc
				RUN ejecuta
			WHEN 12
				IF NOT fl_control_acceso_proceso_men(vg_usuario,
						vg_codcia, 'RE', 'repp241')
				THEN
					EXIT CASE
				END IF
				LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglrun repp241 ', vg_base, ' ', 'RE', vg_codcia, ' ', vg_codloc
				RUN ejecuta
			WHEN 13
				IF NOT fl_control_acceso_proceso_men(vg_usuario,
						vg_codcia, 'RE', 'repp243')
				THEN
					EXIT CASE
				END IF
				LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglrun repp243 ', vg_base, ' ', 'RE', vg_codcia, ' ', vg_codloc
				RUN ejecuta
			WHEN 14
				IF NOT fl_control_acceso_proceso_men(vg_usuario,
						vg_codcia, 'RE', 'repp319')
				THEN
					EXIT CASE
				END IF
				LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglrun repp319 ', vg_base, ' ', 'RE', vg_codcia, ' ', vg_codloc
				RUN ejecuta
		END CASE

        END IF
END WHILE
CLOSE WINDOW w_menu_bodegueros

END FUNCTION
