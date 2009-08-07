------------------------------------------------------------------------------
-- Titulo           : cxcp208.4gl - Cierre Mensual      
-- Elaboracion      : 09-mar-2002
-- Autor            : JCM
-- Formato Ejecucion: fglrun cxcp208 base módulo compañía localidad
-- Ultima Correccion: 
-- Motivo Correccion: 
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE rm_z00		RECORD LIKE cxct000.*



MAIN

DEFER QUIT 
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/errores')
CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 THEN          -- Validar # parámetros correcto
	CALL fgl_winmessage(vg_producto, 'Número de parámetros incorrecto', 'stop')
	EXIT PROGRAM
END IF
LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_codcia   = arg_val(3)
LET vg_codloc   = arg_val(4)
LET vg_proceso = 'cxcp208'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()

END MAIN



FUNCTION funcion_master()
DEFINE anho, mes        SMALLINT

CALL fl_nivel_isolation()
OPEN WINDOW w_mas AT 3,2 WITH 8 ROWS, 80 COLUMNS
    ATTRIBUTE(FORM LINE FIRST + 2, COMMENT LINE LAST, MENU LINE FIRST,BORDER,
	      MESSAGE LINE LAST - 2)
OPTIONS INPUT WRAP,
	ACCEPT KEY	F12
OPEN FORM f_cxc FROM "../forms/cxcf208_1"
DISPLAY FORM f_cxc

CALL fl_lee_compania_cobranzas(vg_codcia) RETURNING rm_z00.*
IF rm_z00.z00_compania IS NULL THEN
        CALL fgl_winmessage(vg_producto,
                'No existe configuración para esta compañía.',
                'exclamation')
        EXIT PROGRAM
END IF
                                                                                
CALL leer_datos() RETURNING anho, mes
MENU 'OPCIONES'
        COMMAND KEY('C') 'Cerrar'       'Proceso de cierre mensual.'
                CALL control_ingreso()
        COMMAND KEY('S') 'Salir'        'Salir del programa.'
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
		'exclamation')
END IF

END FUNCTION



FUNCTION leer_datos()
DEFINE resp		CHAR(6)
DEFINE mes 		SMALLINT
DEFINE tit_mes		VARCHAR(12)
DEFINE anho		SMALLINT

IF rm_z00.z00_mespro IS NULL THEN
        LET anho = YEAR(TODAY)
        LET mes  = MONTH(TODAY)
ELSE
        LET anho = rm_z00.z00_anopro
        LET mes  = rm_z00.z00_mespro
END IF
                                                                                
CALL fl_retorna_nombre_mes(mes) RETURNING tit_mes
DISPLAY BY NAME anho, mes, tit_mes
                                                                                
RETURN anho, mes

END FUNCTION



FUNCTION validar_mes(anho, mes)

DEFINE mes,anho		SMALLINT

DEFINE dia, mes2, anho2	SMALLINT
DEFINE fecha		DATE

IF anho < YEAR(TODAY) THEN
        RETURN 1
ELSE
        IF mes < MONTH(TODAY) THEN
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
                                                                                
IF TODAY < fecha THEN
        CALL fgl_winmessage(vg_producto,
                'Aún no se puede cerrar el mes.',
                'exclamation')
        RETURN 0
END IF

RETURN 1

END FUNCTION



FUNCTION proceso_cerrar_mes(anho, mes)

DEFINE anho		LIKE cxct050.z50_ano
DEFINE mes		LIKE cxct050.z50_mes
DEFINE query		VARCHAR(255)

BEGIN WORK

INITIALIZE rm_z00.* TO NULL
                                                                                
SET LOCK MODE TO WAIT 5
WHENEVER ERROR CONTINUE
DECLARE q_cxct000 CURSOR FOR
        SELECT * FROM cxct000 WHERE z00_compania = vg_codcia
        FOR UPDATE
OPEN  q_cxct000
FETCH q_cxct000 INTO rm_z00.*
WHENEVER ERROR STOP
IF STATUS < 0 THEN
        SET LOCK MODE TO NOT WAIT
        ROLLBACK WORK
        CALL fl_mensaje_bloqueo_otro_usuario()
        RETURN
END IF
SET LOCK MODE TO NOT WAIT

DELETE FROM cxct050 WHERE z50_ano       = anho 
	  	      AND z50_mes       = mes 
	              AND z50_compania  = vg_codcia
	              AND z50_localidad = vg_codloc

DELETE FROM cxct051 WHERE z51_ano       = anho 
	  	      AND z51_mes       = mes 
	              AND z51_compania  = vg_codcia
	              AND z51_localidad = vg_codloc

LET query = 'INSERT INTO cxct051 ',
		' SELECT ', anho, ', ', mes, ', * FROM cxct021 ',
		' 	WHERE z21_compania  = ', vg_codcia,
		'	  AND z21_localidad = ', vg_codloc,
	  	'	  AND z21_saldo > 0 '

PREPARE stmnt1 FROM query
EXECUTE stmnt1

LET query = 'INSERT INTO cxct050 ',
		' SELECT ', anho, ', ', mes, ', * FROM cxct020 ',
		' 	WHERE z20_compania  = ', vg_codcia,
		'	  AND z20_localidad = ', vg_codloc,
	 	'	  AND z20_saldo_cap + z20_saldo_int > 0 '

PREPARE stmnt2 FROM query
EXECUTE stmnt2

IF mes = 12 THEN
        LET mes  = 1
        LET anho = anho + 1
ELSE
        LET mes  = mes + 1
END IF
                                                                                
UPDATE cxct000 SET z00_mespro = mes, z00_anopro = anho
        WHERE CURRENT OF q_cxct000
          
COMMIT WORK

END FUNCTION



FUNCTION validar_parametros()

CALL fl_lee_modulo(vg_modulo) RETURNING rg_mod.*
IF rg_mod.g50_modulo IS NULL THEN
	CALL fgl_winmessage(vg_producto, 'No existe módulo: ' || vg_modulo, 'stop')
	EXIT PROGRAM
END IF
CALL fl_lee_compania(vg_codcia) RETURNING rg_cia.*
IF rg_cia.g01_compania IS NULL THEN
	CALL fgl_winmessage(vg_producto, 'No existe compañía: '|| vg_codcia, 'stop')
	EXIT PROGRAM
END IF
IF rg_cia.g01_estado <> 'A' THEN
	CALL fgl_winmessage(vg_producto, 'Compañía no está activa: ' || vg_codcia, 'stop')
	EXIT PROGRAM
END IF
IF vg_codloc IS NULL THEN
	LET vg_codloc   = fl_retorna_agencia_default(vg_codcia)
END IF
CALL fl_lee_localidad(vg_codcia, vg_codloc) RETURNING rg_loc.*
IF rg_loc.g02_localidad IS NULL THEN
	CALL fgl_winmessage(vg_producto, 'No existe localidad: ' || vg_codloc, 'stop')
	EXIT PROGRAM
END IF
IF rg_loc.g02_estado <> 'A' THEN
	CALL fgl_winmessage(vg_producto, 'Localidad no está activa: '|| vg_codloc, 'stop')
	EXIT PROGRAM
END IF

END FUNCTION
