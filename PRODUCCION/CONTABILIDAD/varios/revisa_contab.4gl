DATABASE diteca

GLOBALS "../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl"


MAIN

DEFER QUIT
DEFER INTERRUPT
CALL fgl_init4js()
CALL fl_marca_registrada_producto()

IF num_args() <> 3 THEN
	DISPLAY 'Numero de parametros incorrecto.'
	EXIT PROGRAM
END IF

LET vg_base   = arg_val(1)
LET vg_codcia = arg_val(2)
LET vg_codloc = arg_val(3)

CALL fl_activar_base_datos(vg_base)
CALL seteos_defaults()	

CALL contabiliza_repuestos()
CALL contabiliza_taller()

END MAIN



FUNCTION contabiliza_repuestos()

DEFINE r_r19		RECORD LIKE rept019.*

DECLARE q_rep CURSOR WITH HOLD FOR 
	SELECT * FROM rept019 WHERE r19_compania  = vg_codcia
	                        AND r19_localidad = vg_codloc
				AND YEAR(r19_fecing) > 2002
FOREACH q_rep INTO r_r19.*
	SELECT r40_compania FROM rept040
	 WHERE r40_compania  = r_r19.r19_compania 
	   AND r40_localidad = r_r19.r19_localidad
	   AND r40_cod_tran  = r_r19.r19_cod_tran 
	   AND r40_num_tran  = r_r19.r19_num_tran 
	 GROUP BY 1

	IF STATUS = NOTFOUND THEN
		DISPLAY "Contabilizando ", r_r19.r19_cod_tran CLIPPED, "-",
			                r_r19.r19_num_tran USING '&&&&&',
                        " ingresado en la fecha ", r_r19.r19_fecing   
		CALL fl_control_master_contab_repuestos(r_r19.r19_compania,
				r_r19.r19_localidad, r_r19.r19_cod_tran, 
                                r_r19.r19_num_tran)
	END IF
END FOREACH 

END FUNCTION



FUNCTION contabiliza_taller()

		CALL fl_control_master_contab_taller(vg_codcia,
				vg_codloc, 610, 'D')

END FUNCTION



FUNCTION seteos_defaults()
DEFINE resp		CHAR(6)
DEFINE r_usuario        RECORD LIKE gent005.*
DEFINE estado           CHAR(9)
DEFINE clave 	        LIKE gent005.g05_clave

SET ISOLATION TO DIRTY READ
CALL fl_lee_configuracion_facturacion() RETURNING rg_gen.*
CALL fl_marca_registrada_producto()
CALL fl_retorna_usuario()
CALL fl_separador()
IF vg_codcia = 0 OR vg_codcia IS NULL THEN
	LET vg_codcia = fl_retorna_compania_default()
END IF
CALL fl_lee_compania(vg_codcia) RETURNING rg_cia.*
IF vg_codloc = 0 OR vg_codloc IS NULL THEN
	LET vg_codloc = fl_retorna_agencia_default(vg_codcia)
END IF

END FUNCTION
