{*
 * Titulo           : menp000.4gl - MENU PRINCIPAL DE FHOBOS
 * Elaboracion      : 05-jun-2009
 * Autor            : JCM
 * Formato Ejecucion: fglrun menp000 base modulo [compania localidad]
 *}
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_titprog	VARCHAR(50)
DEFINE fondo_pp		CHAR(25)



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/menp000.error')
CALL fgl_init4js()
IF num_args() <> 2 AND num_args() <> 4 THEN          -- Validar # parámetros correcto
	CALL fgl_winmessage(vg_producto, 'Número de parámetros incorrecto', 'stop')
	EXIT PROGRAM
END IF
LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_proceso = 'menp000'
IF num_args() = 4 THEN
	LET vg_codcia   = arg_val(3)
	LET vg_codloc   = arg_val(4)
END IF
LET vm_titprog  = 'MENU PRINCIPAL - PHOBOS'
LET fondo_pp   	= 'phobos_biger'
--LET fondo   	= 'phobos_small'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
CALL fgl_settitle(vg_proceso || ' - ' || vm_titprog)
CALL validar_parametros()
IF vg_usuario = 'CONTADOR' THEN
	display 'USUARIO :', vg_usuario
	display 'COMPANIA ENTRO :', vg_codcia
	LET vg_codcia = 2
END IF
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
  		CALL iniciar_menu_usuario()
		EXIT PROGRAM
	WHEN 0 
		--CLOSE WINDOW w_menu_vehiculos
		CLOSE WINDOW w_primera_pantalla
  		EXIT PROGRAM
	WHEN 2016 
		CALL primera_pantalla()
END CASE
END WHILE
END FUNCTION



FUNCTION iniciar_menu_usuario()
DEFINE ejecuta		CHAR(100)
DEFINE r_g05		RECORD LIKE gent005.*

CALL fl_lee_usuario(vg_usuario) RETURNING r_g05.*
IF r_g05.g05_menu IS NULL THEN
	-- El usuario no tiene un menu definido, asi que se usara el menu general
	LET r_g05.g05_menu = 'menp001'
END IF 

LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'MENU', vg_separador, 'fuentes', vg_separador, '; fglrun ', r_g05.g05_menu, ' ' , vg_base, ' ', 'GE', vg_codcia, ' ', vg_codloc

RUN ejecuta

END FUNCTION



FUNCTION validar_parametros()

CALL fl_lee_modulo(vg_modulo) RETURNING rg_mod.*
IF rg_mod.g50_modulo IS NULL THEN
	CALL fgl_winmessage(vg_producto, 'No existe módulo: ' || vg_modulo, 
                            'stop')
	EXIT PROGRAM
END IF
CALL fl_lee_compania(vg_codcia) RETURNING rg_cia.*
IF rg_cia.g01_compania IS NULL THEN
	CALL fgl_winmessage(vg_producto, 'No existe compañía: '|| vg_codcia, 
                            'stop')
	EXIT PROGRAM
END IF
IF rg_cia.g01_estado <> 'A' THEN
	CALL fgl_winmessage(vg_producto, 'Compañía no está activa: ' || 
                            vg_codcia, 'stop')
	EXIT PROGRAM
END IF
IF vg_codloc IS NULL THEN
	LET vg_codloc   = fl_retorna_agencia_default(vg_codcia)
END IF
CALL fl_lee_localidad(vg_codcia, vg_codloc) RETURNING rg_loc.*
IF rg_loc.g02_localidad IS NULL THEN
	CALL fgl_winmessage(vg_producto, 'No existe localidad: ' || vg_codloc, 
                            'stop')
	EXIT PROGRAM
END IF
IF rg_loc.g02_estado <> 'A' THEN
	CALL fgl_winmessage(vg_producto, 'Localidad no está activa: ' || 
                            vg_codloc, 'stop')
	EXIT PROGRAM
END IF

END FUNCTION
 
