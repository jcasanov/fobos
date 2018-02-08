--------------------------------------------------------------------------------
-- Titulo           : cxpp208.4gl - Cierre mensual      
-- Elaboracion      : 09-mar-2002
-- Autor            : JCM
-- Formato Ejecucion: fglrun cxpp208 base módulo compañía localidad
-- Ultima Correccion: 21-may-2002 
-- Motivo Correccion: Se adicionaron campos p00_mespro y p00_anopro
--------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE rm_p00		RECORD LIKE cxpt000.*



MAIN

DEFER QUIT 
DEFER INTERRUPT
CLEAR SCREEN
LET vg_proceso = arg_val(0)
CALL startlog('../logs/' || vg_proceso CLIPPED || '.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 THEN          -- Validar # parámetros correcto
	CALL fl_mostrar_mensaje('Número de parámetros incorrecto', 'stop')
	EXIT PROGRAM
END IF
LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_codcia   = arg_val(3)
LET vg_codloc   = arg_val(4)
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
--#CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()

END MAIN



FUNCTION funcion_master()

DEFINE anho, mes	SMALLINT

CALL fl_nivel_isolation()
OPEN WINDOW w_mas AT 3,2 WITH 8 ROWS, 80 COLUMNS
    ATTRIBUTE(FORM LINE FIRST + 2, COMMENT LINE LAST, MENU LINE FIRST,BORDER,
	      MESSAGE LINE LAST - 2)
OPTIONS INPUT WRAP,
	ACCEPT KEY	F12
OPEN FORM f_cxp FROM "../forms/cxpf208_1"
DISPLAY FORM f_cxp

CALL fl_lee_compania_tesoreria(vg_codcia) RETURNING rm_p00.* 
IF rm_p00.p00_compania IS NULL THEN
	CALL fgl_winmessage(vg_producto, 
		'No existe configuración para esta compañía.', 
		'exclamation')
	EXIT PROGRAM
END IF

CALL leer_datos() RETURNING anho, mes
MENU 'OPCIONES'
	COMMAND KEY('C') 'Cerrar'	'Proceso de cierre mensual.'
		CALL control_ingreso()
	COMMAND KEY('S') 'Salir'	'Salir del programa.'
		EXIT MENU
END MENU

END FUNCTION



FUNCTION control_ingreso()

DEFINE resp		VARCHAR(6)
DEFINE anho, mes	SMALLINT

INITIALIZE anho, mes TO NULL

CALL leer_datos() RETURNING anho, mes
CALL fl_mensaje_seguro_ejecutar_proceso() RETURNING resp
IF resp = 'Yes' THEN
	IF NOT validar_mes(anho, mes) THEN
		RETURN
	END IF
	CALL proceso_cerrar_mes(anho, mes)
	CALL fgl_winmessage(vg_producto,
		'Proceso realizado Ok.',
		'info')
	CALL fl_verificar_dias_validez_sri(vg_codcia, vg_codloc, 'RT')
END IF

END FUNCTION



FUNCTION leer_datos()
DEFINE resp		CHAR(6)
DEFINE mes 		SMALLINT
DEFINE tit_mes		VARCHAR(12)
DEFINE anho		SMALLINT

IF rm_p00.p00_mespro IS NULL THEN
	LET anho = YEAR(vg_fecha)
	LET mes  = MONTH(vg_fecha)
ELSE
	LET anho = rm_p00.p00_anopro
	LET mes  = rm_p00.p00_mespro
END IF

CALL fl_retorna_nombre_mes(mes) RETURNING tit_mes
DISPLAY BY NAME anho, mes, tit_mes

RETURN anho, mes

END FUNCTION



FUNCTION validar_mes(anho, mes)

DEFINE mes,anho		SMALLINT

DEFINE dia, mes2, anho2	SMALLINT
DEFINE fecha		DATE

IF anho < YEAR(vg_fecha) THEN
	RETURN 1
ELSE
	IF mes < MONTH(vg_fecha) THEN
		RETURN 1
	END IF
END IF

IF mes = 12 THEN
	LET mes2  = 1
	LET anho2 = anho + 1
ELSE
	LET mes2  = mes + 1
	LET anho2 = anho
END IF

LET fecha = mdy(mes2, 1, anho2)
LET fecha = fecha - 1

IF vg_fecha < fecha THEN
	CALL fgl_winmessage(vg_producto,
		'Aún no se puede cerrar el mes.',
		'exclamation')
	RETURN 0
END IF

RETURN 1

END FUNCTION



FUNCTION proceso_cerrar_mes(anho, mes)

DEFINE anho		LIKE cxpt050.p50_ano
DEFINE mes		LIKE cxpt050.p50_mes
DEFINE query		VARCHAR(255)

BEGIN WORK

INITIALIZE rm_p00.* TO NULL

SET LOCK MODE TO WAIT 5
WHENEVER ERROR CONTINUE
DECLARE q_cxpt000 CURSOR FOR
	SELECT * FROM cxpt000 WHERE p00_compania = vg_codcia
	FOR UPDATE
OPEN  q_cxpt000
FETCH q_cxpt000 INTO rm_p00.*
WHENEVER ERROR STOP
IF STATUS < 0 THEN
	SET LOCK MODE TO NOT WAIT
	ROLLBACK WORK
	CALL fl_mensaje_bloqueo_otro_usuario()
	RETURN
END IF
SET LOCK MODE TO NOT WAIT
		
DELETE FROM cxpt050 WHERE p50_ano       = anho 
	  	      AND p50_mes       = mes 
	              AND p50_compania  = vg_codcia
	              AND p50_localidad = vg_codloc

DELETE FROM cxpt051 WHERE p51_ano       = anho 
	  	      AND p51_mes       = mes 
	              AND p51_compania  = vg_codcia
	              AND p51_localidad = vg_codloc

{XXX La tabla cxpt051 se le incluyó los mismos campos que fueron incluidos
	 en la tabla cxpt021 el 02/01/2018; estos campos son:
		- p51_val_impto
		- p51_cod_tran
		- p51_num_tran
		- p51_num_sri
		- p51_num_aut
		- p51_fec_emi_nc
		- p51_fec_emi_aut
 XXX}

LET query = 'INSERT INTO cxpt051 ',
		' SELECT ', anho, ', ', mes, ', * FROM cxpt021 ',
		' 	WHERE p21_compania  = ', vg_codcia,
		'	  AND p21_localidad = ', vg_codloc,
	  	'	  AND p21_saldo > 0 '

PREPARE stmnt1 FROM query
EXECUTE stmnt1

LET query = 'INSERT INTO cxpt050 ',
		' SELECT ', anho, ', ', mes, ', * FROM cxpt020 ',
		' 	WHERE p20_compania  = ', vg_codcia,
		'	  AND p20_localidad = ', vg_codloc,
	 	'	  AND p20_saldo_cap + p20_saldo_int > 0 '

PREPARE stmnt2 FROM query
EXECUTE stmnt2

IF mes = 12 THEN
	LET mes  = 1
	LET anho = anho + 1
ELSE
	LET mes  = mes + 1
END IF

UPDATE cxpt000 SET p00_mespro = mes, p00_anopro = anho 
	WHERE CURRENT OF q_cxpt000 

COMMIT WORK

END FUNCTION
