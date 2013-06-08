--------------------------------------------------------------------------------
-- Titulo           : menp007.4gl - MENU PRINCIPAL DE FHOBOS CONTROL VARIOS
-- Elaboracion      : 13-Sep-2007
-- Autor            : NPC
-- Formato Ejecucion: fglrun menp007 base modulo
-- Ultima Correccion: 
-- Motivo Correccion: 
--------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_titprog	VARCHAR(50)
DEFINE vm_rows		ARRAY[1000] OF INTEGER
DEFINE vm_row_current	SMALLINT	-- FILA CORRIENTE DEL ARREGLO
DEFINE vm_num_rows	SMALLINT	-- CANTIDAD DE FILAS LEIDAS
DEFINE ejecuta		CHAR(100)
DEFINE fondo_pp		CHAR(25)
DEFINE fondo_phobos	CHAR(25)
DEFINE a		CHAR(25)



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/menp007.err')
--#CALL fgl_init4js()
IF num_args() <> 2 AND num_args() <> 3 THEN  -- Validar # parámetros correcto
	CALL fgl_winmessage(vg_producto, 'N£mero de parametros incorrecto.', 'stop')
	EXIT PROGRAM
END IF
LET vg_base      = arg_val(1)
LET vg_modulo    = arg_val(2)
LET vg_proceso   = 'menp007'
LET vm_titprog   = 'MENU PHOBOS - CONTROL VARIOS'
LET fondo_pp     = 'phobos_biger'
LET fondo_phobos = 'phobos_titulo'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
--#CALL fgl_settitle(vg_proceso || ' - ' || vm_titprog)
CALL fl_validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL primera_pantalla()

END MAIN



FUNCTION primera_pantalla()
DEFINE p		  SMALLINT

IF arg_val(3) = 'N' THEN
	CALL funcion_master()
	EXIT PROGRAM
END IF
WHILE TRUE
	OPEN WINDOW w_primera_pantalla AT 3,2 WITH 22 ROWS, 80 COLUMNS
		ATTRIBUTE(FORM LINE FIRST , COMMENT LINE LAST, MENU LINE FIRST,
			  BORDER, MESSAGE LINE LAST - 2) 
	OPEN FORM f_menf000 FROM '../forms/menf000'
	DISPLAY FORM f_menf000
	DISPLAY fondo_pp	  TO c000   ## Picture
	DISPLAY "Bienvenidos"  	  TO c100   ## Bot¢n
	LET p = fgl_getkey()
	CASE p
		WHEN 1 
			CLOSE WINDOW w_primera_pantalla
	  		CALL funcion_master()
	        WHEN 13
        	        CLOSE WINDOW w_primera_pantalla
                	CALL funcion_master()
		WHEN 0 
			CLOSE WINDOW w_primera_pantalla
	  		EXIT PROGRAM
		WHEN 2016 
			CALL primera_pantalla()
	END CASE
END WHILE

END FUNCTION



FUNCTION funcion_master()

IF tiene_acceso(vg_usuario, vg_codcia, 'OC') THEN
	CALL menu_varios()
END IF
EXIT PROGRAM

END FUNCTION



FUNCTION menu_varios()
DEFINE b		SMALLINT

WHILE TRUE
	OPEN WINDOW w_menu_control_varios AT 3,2 WITH 22 ROWS, 80 COLUMNS
		ATTRIBUTE(FORM LINE FIRST , COMMENT LINE LAST, MENU LINE FIRST,
			  BORDER, MESSAGE LINE LAST - 2) 
	OPEN FORM f_menf164 FROM '../forms/menf164'
	DISPLAY FORM f_menf164
	DISPLAY "boton_transaciones"    TO a      ## Picture 
	DISPLAY "Ingreso O. Compras"   	TO c100   ## Botón 1 ordp200
	DISPLAY "Consulta O. Compras"   TO c200   ## Botón 2 ordp300
	DISPLAY "Impresión O. Compras"	TO c300   ## Botón 3 ordp400
	DISPLAY "Días de Vacaciones"	TO c400   ## Botón 4 rolp254
	DISPLAY "Datos para el Rol"  	TO c500   ## Botón 5 rolp256
	LET b = fgl_getkey()
	CASE b
		WHEN 1
			IF NOT fl_control_acceso_proceso_men(vg_usuario,
						vg_codcia, 'OC', 'ordp200')
			THEN
				EXIT CASE
			END IF
			LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'COMPRAS', vg_separador, 'fuentes', vg_separador, '; fglrun ordp200 ', vg_base, ' ', 'OC', vg_codcia, vg_codloc
			RUN ejecuta
		WHEN 2
			IF NOT fl_control_acceso_proceso_men(vg_usuario,
						vg_codcia, 'OC', 'ordp300')
			THEN
				EXIT CASE
			END IF
			LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'COMPRAS', vg_separador, 'fuentes', vg_separador, '; fglrun ordp300 ', vg_base, ' ', 'OC', vg_codcia, vg_codloc
			RUN ejecuta
		WHEN 3
			IF NOT fl_control_acceso_proceso_men(vg_usuario,
						vg_codcia, 'OC', 'ordp400')
			THEN
				EXIT CASE
			END IF
			LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'COMPRAS', vg_separador, 'fuentes', vg_separador, '; fglrun ordp400 ', vg_base, ' ', 'OC', vg_codcia, vg_codloc
			RUN ejecuta
		WHEN 4
			IF NOT fl_control_acceso_proceso_men(vg_usuario,
						vg_codcia, 'RO', 'rolp254')
			THEN
				EXIT CASE
			END IF
			LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'NOMINA', vg_separador, 'fuentes', vg_separador, '; fglrun rolp254 ', vg_base, ' ', 'RO', vg_codcia
			RUN ejecuta
		WHEN 5
			IF NOT fl_control_acceso_proceso_men(vg_usuario,
						vg_codcia, 'RO', 'rolp256')
			THEN
				EXIT CASE
			END IF
			LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'NOMINA', vg_separador, 'fuentes', vg_separador, '; fglrun rolp256 ', vg_base, ' ', 'RO', vg_codcia
			RUN ejecuta
		WHEN 0
			EXIT WHILE
	END CASE
END WHILE

END FUNCTION
 


FUNCTION tiene_acceso(v_usuario, v_codcia, v_modulo) 
DEFINE v_usuario	LIKE gent005.g05_usuario
DEFINE v_codcia		LIKE gent001.g01_compania
DEFINE v_modulo		LIKE gent050.g50_modulo
DEFINE r_g50		RECORD LIKE gent050.*

CALL fl_lee_modulo(v_modulo) RETURNING r_g50.*
IF r_g50.g50_modulo IS NULL THEN
	CALL fgl_winmessage(vg_producto, 'MODULO: ' || v_modulo CLIPPED 
				          || ' NO EXISTE ', 'stop')
	RETURN 0
END IF
SELECT * FROM gent052 
	WHERE g52_modulo  = v_modulo  AND 
	      g52_usuario = v_usuario AND
	      g52_estado = 'A'
IF status = NOTFOUND THEN
	CALL fgl_winmessage(vg_producto, 'USUARIO NO TIENE ACCESO AL MODULO: '
					 || r_g50.g50_nombre CLIPPED 
					 || '. PEDIR AYUDA AL ADMINISTRADOR ',
					 'stop')
	RETURN 0
END IF
SELECT * FROM gent053 
	WHERE g53_modulo   = v_modulo  AND 
	      g53_usuario  = v_usuario AND
	      g53_compania = v_codcia 
IF status = NOTFOUND THEN
	CALL fgl_winmessage(vg_producto,'USUARIO NO TIENE ACCESO A LA COMPAÑIA:'
				|| ' ' || rg_cia.g01_abreviacion CLIPPED 
				|| '. PEDIR AYUDA AL ADMINISTRADOR ',
				'stop')
	RETURN 0
END IF
RETURN 1

END FUNCTION
