GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'


MAIN
DEFINE r		RECORD LIKE veht030.*
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/errores')
CALL fgl_init4js()
CALL fl_marca_registrada_producto()
LET vg_base     = 'diteca'
LET vg_codcia   = 1
LET vg_codloc   = 1
LET vg_modulo   = 'VE'
CALL fl_seteos_defaults()	
CALL fl_activar_base_datos(vg_base)
{
DECLARE q1 CURSOR WITH HOLD FOR SELECT * FROM veht030
	WHERE v30_compania  = vg_codcia AND 
	      v30_localidad = vg_codloc AND 
	      v30_cod_tran  = 'FA'      AND
	      v30_num_tran <= 90020
FOREACH q1 INTO r.*
	CALL fl_control_master_contab_vehiculos(vg_codcia, vg_codloc, 
		r.v30_cod_tran, r.v30_num_tran)
END FOREACH
}
CALL fl_control_master_contab_vehiculos(vg_codcia, vg_codloc, 'FA', 90021)
CALL fl_control_master_contab_vehiculos(vg_codcia, vg_codloc, 'FA', 90022)

END MAIN
