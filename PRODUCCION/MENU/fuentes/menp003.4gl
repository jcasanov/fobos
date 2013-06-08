------------------------------------------------------------------------------
-- Titulo           : menp003.4gl - MENU PRINCIPAL DE FHOBOS BODEGUEROS
-- Elaboracion      : 13-Dic-2002
-- Autor            : NPC
-- Formato Ejecucion: fglrun menp003 base modulo
-- Ultima Correccion: 
-- Motivo Correccion: 
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_titprog	VARCHAR(50)
DEFINE vm_rows 		ARRAY[1000] OF INTEGER 	-- ARREGLO DE ROWID FILAS LEIDAS
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
CALL startlog('../logs/menp003.err')
--#CALL fgl_init4js()
IF num_args() <> 2 AND num_args() <> 3 THEN  -- Validar # parámetros correcto
	CALL fgl_winmessage(vg_producto, 'N£mero de parametros incorrecto.', 'stop')
	EXIT PROGRAM
END IF
LET vg_base      = arg_val(1)
LET vg_modulo    = arg_val(2)
LET vg_proceso   = 'menp003'
LET vm_titprog   = 'MENU PHOBOS - BODEGUEROS'
LET fondo_pp   	 = 'phobos_biger'
LET fondo_phobos = 'phobos_titulo'
--LET fondo   	 = 'phobos_small'
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
	WHEN 0 
		CLOSE WINDOW w_primera_pantalla
  		EXIT PROGRAM
	WHEN 2016 
		CALL primera_pantalla()
END CASE
END WHILE
END FUNCTION



FUNCTION funcion_master()

IF tiene_acceso(vg_usuario, vg_codcia, 'RE') THEN
	CALL menu_inventario_bod()
END IF
EXIT PROGRAM

END FUNCTION



FUNCTION menu_inventario_bod()
DEFINE c100 		char(30)
DEFINE c200 		char(30)
DEFINE c300 		char(30)
DEFINE c400 		char(30)
DEFINE c500 		char(30)
DEFINE c600 		char(30)
DEFINE c700 		char(30)
DEFINE c800 		char(30)
DEFINE c900 		char(30)
DEFINE c1000 		char(30)
DEFINE b		SMALLINT

WHILE TRUE
OPEN WINDOW w_menu_bodegueros AT 3,2 WITH 22 ROWS, 80 COLUMNS
	ATTRIBUTE(FORM LINE FIRST , COMMENT LINE LAST, MENU LINE FIRST,
		  BORDER, MESSAGE LINE LAST - 2) 
OPEN FORM f_menf200 FROM '../forms/menf201'
DISPLAY FORM f_menf200
DISPLAY "boton_bodegueros"      TO a      ## Picture 
DISPLAY "Generar Nota Entrega"  TO c100   ## Botón
DISPLAY "Consulta Orden Desp."  TO c200   ## Botón
DISPLAY "Consulta Items"        TO c300   ## Botón
DISPLAY "Consulta Items Pend."  TO c400   ## Botón
DISPLAY "Recepción Mercadería"  TO c500   ## Botón
DISPLAY "Transferencia"         TO c600   ## Botón
DISPLAY "Kardex de Items"       TO c700   ## Botón
DISPLAY "Transmisión Transf."   TO c800   ## Botón
DISPLAY "Inventario Físico"     TO c900   ## Botón
DISPLAY "Consulta Inv. Físico"  TO c1000  ## Botón
DISPLAY "Traspaso a La Prensa"  TO c1100  ## Botón
DISPLAY "Guías de Remisión"     TO c1200  ## Botón
DISPLAY "Corrección GR SRI"     TO c1300  ## Botón
DISPLAY "Cons. Transferencia"   TO c1400   ## Botón

LET b = fgl_getkey()

CASE b
	WHEN 1 
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'RE', 'repp231')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglrun repp231 ', vg_base, ' ', 'RE', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 2
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'RE', 'repp313')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglrun repp313 ', vg_base, ' ', 'RE', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 3
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'RE', 'repp300')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglrun repp300 ', vg_base, ' ', 'RE', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 4
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'RE', 'repp318')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglrun repp318 ', vg_base, ' ', 'RE', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 5
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'RE', 'repp214')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglrun repp214 ', vg_base, ' ', 'RE', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 6
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'RE', 'repp216')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglrun repp216 ', vg_base, ' ', 'RE', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 7
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'RE', 'repp307')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglrun repp307 ', vg_base, ' ', 'RE', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 8
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'RE', 'repp666')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglrun repp666 ', vg_base, ' ', 'RE ', vg_codcia, ' ', vg_codloc
		RUN ejecuta
	WHEN 9
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'RE', 'repp239')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglrun repp239 ', vg_base, ' ', 'RE', vg_codcia, ' ', vg_codloc
		RUN ejecuta
	WHEN 10
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'RE', 'repp317')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglrun repp317 ', vg_base, ' ', 'RE', vg_codcia, ' ', vg_codloc
		RUN ejecuta
	WHEN 11
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'RE', 'repp667')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglrun repp667 ', vg_base, ' ', 'RE', vg_codcia, ' ', vg_codloc
		RUN ejecuta
	WHEN 12
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'RE', 'repp241')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglrun repp241 ', vg_base, ' ', 'RE', vg_codcia, ' ', vg_codloc
		RUN ejecuta
	WHEN 13
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'RE', 'repp243')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglrun repp243 ', vg_base, ' ', 'RE', vg_codcia, ' ', vg_codloc
		RUN ejecuta
	WHEN 14
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'RE', 'repp319')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglrun repp319 ', vg_base, ' ', 'RE', vg_codcia, ' ', vg_codloc
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
