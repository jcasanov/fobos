GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE rm_ctb		RECORD LIKE ctbt000.*
DEFINE vm_mes		SMALLINT
DEFINE b00_mespro	SMALLINT
DEFINE vm_anio		SMALLINT
DEFINE tit_mes		CHAR(11)
DEFINE r_ctb		RECORD LIKE ctbt000.*

MAIN

DEFER QUIT 
DEFER INTERRUPT
--CLEAR SCREEN
--CALL fl_marca_registrada_producto()
IF num_args() <> 4 THEN          -- Validar # parámetros correcto
--	CALL fgl_winmessage(vg_producto, 'Número de parámetros incorrecto', 'stop')
	EXIT PROGRAM
END IF
LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_codcia   = arg_val(3)
LET vg_codloc   = arg_val(4)
LET vg_proceso = 'ctbp204'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
CALL funcion_master()

END MAIN



FUNCTION funcion_master()

CALL fl_nivel_isolation()
CALL control_ingreso()

END FUNCTION



FUNCTION control_ingreso()
DEFINE mayorizado	SMALLINT

CALL fl_retorna_usuario()
LET mayorizado = fl_mayorizacion_mes(vg_codcia, 'DO', YEAR(TODAY), MONTH(TODAY))

END FUNCTION
