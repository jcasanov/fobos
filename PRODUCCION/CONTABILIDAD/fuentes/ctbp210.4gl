------------------------------------------------------------------------------
-- Titulo           : ctbp210.4gl - Contabiliza facturas no contabilizadas
-- Elaboracion      : 29-sep-2007
-- Autor            : JCM
-- Ultima Correccion: 
------------------------------------------------------------------------------
GLOBALS "../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl"

DEFINE r RECORD LIKE ctbt999.*
DEFINE fechcur LIKE ctbt999.b999_fechult

MAIN

DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/ctbp210.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()

IF num_args() <> 4 THEN
	DISPLAY 'Numero de parametros incorrecto.'
	EXIT PROGRAM
END IF

LET vg_base   = arg_val(1)
LET vg_modulo = arg_val(2)
LET vg_codcia = arg_val(3)
LET vg_codloc = arg_val(4)
LET vg_proceso = 'ctbp210'

CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	-- Asigna un valor por default a vg_codloc
--#CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)

CALL fl_nivel_isolation()
OPEN WINDOW wf AT 3,2 WITH 21 ROWS, 80 COLUMNS
    ATTRIBUTE(FORM LINE FIRST + 2, COMMENT LINE LAST, MENU LINE FIRST,BORDER,
	      MESSAGE LINE LAST - 2)
OPEN FORM f_ctb FROM "../forms/ctbf210_1"
DISPLAY FORM f_ctb

-- Debo saber cuando fue la ultima vez que se corrio este proceso.
-- Esto es importante porque hay facturas que se han contabilizado manualmente
-- y esas no las debo considerar (anteriores a este proceso), tampoco quiero
-- quiero tener que estar revisando una y otra vez todas las facturas que ya
-- se han contabilizado.
-- Para eso creamos una tabla en la que se guardara la fecha y hora de la 
-- ultima ejecucion de este programa y solo se revisaran las facturas que sean
-- iguales o superiores a esa fecha.

INITIALIZE r.b999_fechult TO NULL
SELECT b999_fechult INTO r.b999_fechult FROM ctbt999 
IF STATUS = NOTFOUND THEN
	DISPLAY 'No se encuentra registro de ultima ejecucion.'
	RETURN
END IF

DISPLAY BY NAME r.b999_fechult

-- Grabo la fecha y hora actual, que es con la que se actualizara el
-- registro. La actualizacion la haremos hasta el final
LET fechcur = CURRENT

CALL contabiliza_repuestos()
CALL contabiliza_taller()

UPDATE ctbt999 SET b999_fechult = fechcur

END MAIN



FUNCTION contabiliza_repuestos()

DEFINE r_r19		RECORD LIKE rept019.*

DECLARE q_rep CURSOR WITH HOLD FOR 
	SELECT * FROM rept019 WHERE r19_compania  = vg_codcia
	                        AND r19_localidad = vg_codloc
				AND r19_fecing >= EXTEND(r.b999_fechult, YEAR TO SECOND)
FOREACH q_rep INTO r_r19.*
	SELECT r40_compania FROM rept040
	 WHERE r40_compania  = r_r19.r19_compania 
	   AND r40_localidad = r_r19.r19_localidad
	   AND r40_cod_tran  = r_r19.r19_cod_tran 
	   AND r40_num_tran  = r_r19.r19_num_tran 
	 GROUP BY 1

	IF STATUS = NOTFOUND THEN
--		DISPLAY "Contabilizando ", r_r19.r19_cod_tran CLIPPED, "-",
--			                r_r19.r19_num_tran USING '&&&&&',
--                        " ingresado en la fecha ", r_r19.r19_fecing   
		CALL fl_control_master_contab_repuestos(r_r19.r19_compania,
				r_r19.r19_localidad, r_r19.r19_cod_tran, 
                                r_r19.r19_num_tran)
	END IF
END FOREACH 

END FUNCTION



FUNCTION contabiliza_taller()

DEFINE r_t23		RECORD LIKE talt023.*

DECLARE q_tal CURSOR WITH HOLD FOR 
	SELECT * FROM talt023 WHERE t23_compania  = vg_codcia
	                        AND t23_localidad = vg_codloc
				AND t23_fec_factura >= EXTEND(r.b999_fechult, YEAR TO SECOND)
FOREACH q_tal INTO r_t23.*
	SELECT t50_compania FROM talt050
	 WHERE t50_compania  = r_t23.t23_compania 
	   AND t50_localidad = r_t23.t23_localidad
	   AND t50_orden     = r_t23.t23_orden 
	   AND t50_factura   = r_t23.t23_num_factura 
	 GROUP BY 1

	IF STATUS = NOTFOUND THEN
		CALL fl_control_master_contab_taller(r_t23.t23_compania,
				r_t23.t23_localidad, r_t23.t23_orden, 'F')
	END IF
END FOREACH

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
