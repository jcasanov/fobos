-------------------------------------------------------------------------------
-- Titulo           : genp000.4gl -- Programa de enlace al menú de cada usuario
-- Elaboracion      : 21-may-2002
-- Autor            : YEC
-- Formato Ejecucion: fglrun genp000 base_datos
--------------------------------------------------------------------------------

GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'


MAIN

DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/errores')
CALL fgl_init4js()
IF num_args() <> 1 THEN  
	CALL fgl_winmessage(vg_producto, 'Número de parámetros incorrecto', 
                            'stop')
	EXIT PROGRAM
END IF
LET vg_base     = arg_val(1)
CALL fl_activar_base_datos(vg_base)
CALL control_master()

END MAIN



FUNCTION control_master()
DEFINE comando		VARCHAR(100)
DEFINE r_g05		RECORD LIKE gent005.*

CALL fl_nivel_isolation()
CALL fl_marca_registrada_producto()
CALL fl_retorna_usuario()
CALL fl_lee_usuario(vg_usuario) RETURNING r_g05.*
IF r_g05.g05_usuario IS NULL THEN
	CALL fgl_winmessage(vg_producto, 'Usuario no está configurado en el sistema', 'stop')
	EXIT PROGRAM
END IF
IF r_g05.g05_menu IS NULL THEN
	CALL fgl_winmessage(vg_producto, 'Usuario no tiene asignado un menú de aceso al sistema', 'stop')
	EXIT PROGRAM
END IF
LET comando = 'cd ../../MENU/fuentes; fglrun ', r_g05.g05_menu, 
	      ' ', vg_base, ' GE'
RUN comando

END FUNCTION 
