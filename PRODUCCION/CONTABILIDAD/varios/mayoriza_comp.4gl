DATABASE diteca 
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'


MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN

LET vg_codcia = arg_val(1)


CALL funcion_master()

END MAIN



FUNCTION funcion_master()

CALL fl_mayoriza_comprobante(vg_codcia, 'DC', '08110004', 'D')
CALL fl_mayoriza_comprobante(vg_codcia, 'DC', '08110005', 'D')

END FUNCTION



