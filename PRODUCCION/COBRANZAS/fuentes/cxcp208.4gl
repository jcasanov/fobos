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
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 THEN          -- Validar # parámetros correcto
	--CALL fgl_winmessage(vg_producto,'Número de parámetros incorrecto', 'stop')
	CALL fl_mostrar_mensaje('Número de parámetros incorrecto.', 'stop')
	EXIT PROGRAM
END IF
LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_codcia   = arg_val(3)
LET vg_codloc   = arg_val(4)
LET vg_proceso = 'cxcp208'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
--#CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()

END MAIN



FUNCTION funcion_master()
DEFINE anho, mes        SMALLINT
DEFINE lin_menu		SMALLINT
DEFINE row_ini  	SMALLINT
DEFINE num_rows 	SMALLINT
DEFINE num_cols 	SMALLINT

CALL fl_nivel_isolation()
LET lin_menu = 0
LET row_ini  = 3
LET num_rows = 8
LET num_cols = 80
IF vg_gui = 0 THEN
	LET lin_menu = 1
	LET row_ini  = 4
	LET num_rows = 20
	LET num_cols = 78
END IF
OPEN WINDOW w_mas AT row_ini, 2 WITH num_rows ROWS, num_cols COLUMNS
	ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE lin_menu,
		  BORDER, MESSAGE LINE LAST - 1) 
IF vg_gui = 1 THEN
	OPEN FORM f_cxc FROM "../forms/cxcf208_1"
ELSE
	OPEN FORM f_cxc FROM "../forms/cxcf208_1c"
END IF
DISPLAY FORM f_cxc

CALL fl_lee_compania_cobranzas(vg_codcia) RETURNING rm_z00.*
IF rm_z00.z00_compania IS NULL THEN
        --CALL fgl_winmessage(vg_producto,'No existe configuración para esta compañía.','stop')
	CALL fl_mostrar_mensaje('No existe configuración para esta compañía.','stop')
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
	--CALL fgl_winmessage(vg_producto,'Proceso realizado Ok.','info')
	CALL fl_mostrar_mensaje('Proceso realizado Ok.','info')
END IF

END FUNCTION



FUNCTION leer_datos()
DEFINE resp		CHAR(6)
DEFINE mes 		SMALLINT
DEFINE tit_mes		VARCHAR(12)
DEFINE anho		SMALLINT

IF rm_z00.z00_mespro IS NULL THEN
        LET anho = YEAR(vg_fecha)
        LET mes  = MONTH(vg_fecha)
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
        --CALL fgl_winmessage(vg_producto,'Aún no se puede cerrar el mes.','exclamation')
	CALL fl_mostrar_mensaje('Aún no se puede cerrar el mes.','exclamation')
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
