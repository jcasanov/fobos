--------------------------------------------------------------------------------
-- Titulo           : menp005.4gl - MENU PRINCIPAL DE PHOBOS - MODULO CLUB
-- Elaboracion      : 30-sep-2003
-- Autor            : JCM
-- Formato Ejecucion: fglrun menp005 base modulo
-- Ultima Correccion: 30-sep-2003
-- Motivo Correccion: 
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_titprog	VARCHAR(50)
DEFINE vm_rows		ARRAY[1000] OF INTEGER 	-- ARREGLO DE ROWID DE FILAS
DEFINE vm_row_current	SMALLINT		-- FILA CORRIENTE DEL ARREGLO
DEFINE vm_num_rows	SMALLINT		-- CANTIDAD DE FILAS LEIDAS
DEFINE ejecuta		CHAR(100)
--DEFINE fondo		CHAR(25)
DEFINE fondo_pp		CHAR(25)
DEFINE fondo_phobos	CHAR(25)
DEFINE a		CHAR(25)



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/menp005.err')
--#CALL fgl_init4js()
IF num_args() <> 2 THEN          -- Validar # parámetros correcto
	CALL fgl_winmessage(vg_producto, 'Número de parámetros incorrecto', 'stop')
	EXIT PROGRAM
END IF
LET vg_base      = arg_val(1)
LET vg_modulo    = arg_val(2)
LET vg_proceso   = 'menp005'
LET vm_titprog   = 'MENU PRINCIPAL - MODULO CLUB'
LET fondo_pp   	 = 'phobos_biger'
LET fondo_phobos = 'phobos_titulo'
--LET fondo    	   = 'phobos_small'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
--#CALL fgl_settitle(vg_proceso || ' - ' || vm_titprog)
CALL fl_validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL primera_pantalla()

END MAIN



FUNCTION primera_pantalla()
DEFINE p		  SMALLINT

WHILE TRUE
OPEN WINDOW w_primera_pantalla AT 3,2 WITH 22 ROWS, 80 COLUMNS
	ATTRIBUTE(FORM LINE FIRST , COMMENT LINE LAST, MENU LINE FIRST,
		  BORDER, MESSAGE LINE LAST - 2) 
OPEN FORM f_menf000 FROM '../forms/menf000'
DISPLAY FORM f_menf000
DISPLAY fondo_pp	  TO c000   ## Picture
DISPLAY "Bienvenidos"  	  TO c100   ## Botón

LET p = fgl_getkey()

CASE p
	WHEN 1 
		CLOSE WINDOW w_primera_pantalla
  		CALL funcion_master()
	WHEN 0 
		--CLOSE WINDOW w_menu_vehiculos
		CLOSE WINDOW w_primera_pantalla
  		EXIT PROGRAM
	WHEN 2016 
		CALL primera_pantalla()
END CASE
END WHILE

END FUNCTION



FUNCTION funcion_master()

DEFINE cod_cia		LIKE gent002.g02_compania
DEFINE cod_local	LIKE gent002.g02_localidad
DEFINE a		SMALLINT


	IF tiene_acceso(vg_usuario, vg_codcia, 'RO') THEN
		CALL menu_club()
	END IF
	EXIT PROGRAM

END FUNCTION


------------------------ C L U B ---------------------------

FUNCTION menu_club()

DEFINE c100 		char(30)
DEFINE c200 		char(30)
DEFINE c300 		char(30)
DEFINE c400 		char(30)
DEFINE c500 		char(30)
DEFINE c600 		char(30)
DEFINE b		SMALLINT

WHILE TRUE
OPEN WINDOW w_menu_club AT 3,2 WITH 22 ROWS, 80 COLUMNS
	ATTRIBUTE(FORM LINE FIRST , COMMENT LINE LAST, MENU LINE FIRST,
		  BORDER, MESSAGE LINE LAST - 2) 
OPEN FORM f_menf157 FROM '../forms/menf157'
DISPLAY FORM f_menf157
--DISPLAY fondo		  TO c000   ## Picture
DISPLAY "boton_club"      TO a      ## Picture 
DISPLAY "Parámetros Club"	TO c100   ## Botón 1 rolp130
DISPLAY "Casas Comerciales" 	TO c200   ## Botón 2 rolp131
DISPLAY "Mant. Planilla Club"	TO c300   ## Botón 3 rolp230
DISPLAY "Mant. Prestamos Club" 	TO c400   ## Botón 4 rolp231
DISPLAY "Trabajadores Afilia."	TO c500   ## Botón 5 rolp330
DISPLAY "Planilla del Club"	TO c600   ## Botón 6 rolp430
DISPLAY "Consulta de Prestamos" TO c700   ## Botón 7 rolp331
DISPLAY "Estado de Cuenta"	TO c800   ## Botón 8 rolp332
DISPLAY "Ing./Egr. Banco"	TO c900   ## Botón 8 rolp232

LET b = fgl_getkey()

CASE b
	WHEN 1
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'RO', 'rolp130')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'NOMINA', vg_separador, 'fuentes', vg_separador, '; fglrun rolp130 ', vg_base, ' ', 'RO', ' ', vg_codcia
		RUN ejecuta
	WHEN 2
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'RO', 'rolp131')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'NOMINA', vg_separador, 'fuentes', vg_separador, '; fglrun rolp131 ', vg_base, ' ', 'RO', ' ', vg_codcia
		RUN ejecuta
	WHEN 3
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'RO', 'rolp230')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'NOMINA', vg_separador, 'fuentes', vg_separador, '; fglrun rolp230 ', vg_base, ' ', 'RO', vg_codcia
		RUN ejecuta
	WHEN 4
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'RO', 'rolp231')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'NOMINA', vg_separador, 'fuentes', vg_separador, '; fglrun rolp231 ', vg_base, ' ', 'RO', vg_codcia
		RUN ejecuta
	WHEN 5
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'RO', 'rolp330')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'NOMINA', vg_separador, 'fuentes', vg_separador, '; fglrun rolp330 ', vg_base, ' ', 'RO', vg_codcia
		RUN ejecuta
	WHEN 6
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'RO', 'rolp430')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'NOMINA', vg_separador, 'fuentes', vg_separador, '; fglrun rolp430 ', vg_base, ' ', 'RO', vg_codcia
		RUN ejecuta
	WHEN 7
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'RO', 'rolp331')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'NOMINA', vg_separador, 'fuentes', vg_separador, '; fglrun rolp331 ', vg_base, ' ', 'RO', vg_codcia
		RUN ejecuta
	WHEN 8
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'RO', 'rolp332')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'NOMINA', vg_separador, 'fuentes', vg_separador, '; fglrun rolp332 ', vg_base, ' ', 'RO', vg_codcia
		RUN ejecuta
	WHEN 9
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'RO', 'rolp232')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'NOMINA', vg_separador, 'fuentes', vg_separador, '; fglrun rolp232 ', vg_base, ' ', 'RO', vg_codcia
		RUN ejecuta
	WHEN 0
		EXIT WHILE
END CASE
END WHILE
END FUNCTION


------------------------- FUNCIONES VARIAS --------------------------

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
