------------------------------------------------------------------------------
-- Titulo           : rolp251.4gl - Cierre mensual 
-- Elaboracion      : 29-nov-2003
-- Autor            : JCM
-- Formato Ejecucion: fglrun rolp251 base modulo compania
-- Ultima Correccion: 
-- Motivo Correccion: 
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE rm_n00		RECORD LIKE rolt000.*  
DEFINE rm_par RECORD 
	n01_ano_proceso		LIKE rolt001.n01_ano_proceso,
	n01_mes_proceso		LIKE rolt001.n01_mes_proceso,
	n_mes			VARCHAR(12)
END RECORD



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/rolp251.err')
CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 3 THEN
	CALL fgl_winmessage(vg_producto, 'Número de parámetros incorrecto', 
                            'stop')
	EXIT PROGRAM
END IF
LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_codcia   = arg_val(3)
LET vg_proceso  = 'rolp251'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	-- Asigna un valor por default a vg_codloc
				-- que luego puede ser reemplazado si se 
                                -- mantiene sin comentario la siguiente linea
CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()

END MAIN



FUNCTION funcion_master()

CALL fl_nivel_isolation()
OPTIONS
	INPUT WRAP,
	ACCEPT KEY F12
OPEN WINDOW w_251 AT 3,2 WITH 13 ROWS, 80 COLUMNS
	ATTRIBUTE(FORM LINE FIRST + 2, COMMENT LINE LAST, MENU LINE FIRST,
		  BORDER, MESSAGE LINE LAST - 2) 
OPEN FORM f_251 FROM '../forms/rolf251_1'
DISPLAY FORM f_251
CALL control_cierre_mes()

END FUNCTION



FUNCTION control_cierre_mes()
DEFINE r_n01		RECORD LIKE rolt001.*  
DEFINE r_n03		RECORD LIKE rolt003.*  
DEFINE r_n32		RECORD LIKE rolt032.*  
DEFINE mensaje		VARCHAR(250)
DEFINE num, dia		SMALLINT
DEFINE resp		CHAR(10)

CALL fl_lee_parametro_general_roles()  RETURNING rm_n00.*
IF rm_n00.n00_serial IS NULL THEN
	CALL fgl_winmessage(vg_producto,
		'No existe configuración general para este módulo.',
		'stop')
	EXIT PROGRAM
END IF
INITIALIZE rm_par.* TO NULL
CALL fl_lee_compania_roles(vg_codcia) RETURNING r_n01.*
IF r_n01.n01_compania IS NULL THEN
	CALL fgl_winmessage(vg_producto,
		'No existe configuración para esta compañía.',
		'stop')
	EXIT PROGRAM
END IF
IF r_n01.n01_estado <> 'A' THEN
	CALL fgl_winmessage(vg_producto,
		'Compañía no está activa.', 'stop')
	EXIT PROGRAM
END IF
LET rm_par.n01_ano_proceso = r_n01.n01_ano_proceso
LET rm_par.n01_mes_proceso = r_n01.n01_mes_proceso
LET rm_par.n_mes           = 
	fl_justifica_titulo('I', 
		fl_retorna_nombre_mes(rm_par.n01_mes_proceso), 12)
DISPLAY BY NAME rm_par.*

INITIALIZE r_n32.* TO NULL
DECLARE q_ultcie CURSOR FOR 
	SELECT * FROM rolt032
		WHERE n32_compania    = vg_codcia
		  AND n32_cod_liqrol  = 'Q2'
		  AND n32_ano_proceso = rm_par.n01_ano_proceso
		  AND n32_mes_proceso = rm_par.n01_mes_proceso
		  AND n32_estado      = 'C'
		  
OPEN  q_ultcie
FETCH q_ultcie INTO r_n32.*
IF STATUS = NOTFOUND THEN
	CALL fl_mostrar_mensaje('No se puede ejecutar el cierre ' || 
				'mensual porque no se ha procesado ' ||
				'la segunda quincena.', 'stop')
	EXIT PROGRAM
END IF
CLOSE q_ultcie
FREE  q_ultcie

IF NOT contabilizado_procesos_nomina() THEN
	EXIT PROGRAM
END IF
		  
CALL fl_hacer_pregunta('Confirma que desea ejecutar el cierre mensual ' ||
		       'para el mes de ' || rm_par.n_mes CLIPPED || '.', 
		       'No') RETURNING resp
IF resp = 'Yes' THEN
	BEGIN WORK

	WHENEVER ERROR CONTINUE
	DECLARE q_rolt001 CURSOR FOR
		SELECT * FROM rolt001 WHERE n01_compania = vg_codcia
		FOR UPDATE
	
	OPEN q_rolt001
	FETCH q_rolt001 INTO r_n01.*
	IF STATUS < 0 THEN
		WHENEVER ERROR STOP
		CALL fl_mostrar_mensaje('Registro bloqueado por otro ' ||
					'usuario, asegúrese que ningún ' ||
					'usuario este accesando al módulo ' ||
					'e intente otra vez.', 'stop')
		EXIT PROGRAM
	END IF
	WHENEVER ERROR STOP
	
	LET rm_par.n01_mes_proceso = rm_par.n01_mes_proceso + 1
	IF rm_par.n01_mes_proceso = 13 THEN
		LET rm_par.n01_mes_proceso = 1
		LET rm_par.n01_ano_proceso = rm_par.n01_ano_proceso + 1
	END IF
	UPDATE rolt001 SET n01_mes_proceso = rm_par.n01_mes_proceso,
			   n01_ano_proceso = rm_par.n01_ano_proceso
		WHERE CURRENT OF q_rolt001

	WHENEVER ERROR CONTINUE
	DECLARE q_fon CURSOR FOR
		SELECT * FROM rolt003
			WHERE n03_proceso = 'FR'
		FOR UPDATE
	OPEN q_fon
	FETCH q_fon INTO r_n03.*
	IF STATUS < 0 THEN
		ROLLBACK WORK
		CALL fl_mostrar_mensaje('No se puede actualizar la configuracion del proceso Fondo de Reserva. Esta bloqueado por otro usuario.', 'stop')
		WHENEVER ERROR STOP
		EXIT PROGRAM
	END IF
	IF STATUS = NOTFOUND THEN
		ROLLBACK WORK
		CALL fl_mostrar_mensaje('No se puede actualizar la configuracion del proceso Fondo de Reserva. No existe el proceso. Llame al ADMINISTRADOR.', 'stop')
		WHENEVER ERROR STOP
		EXIT PROGRAM
	END IF

	LET dia = DAY(MDY(r_n01.n01_mes_proceso, 01, r_n01.n01_ano_proceso)
			+ 1 UNITS MONTH - 1 UNITS DAY)

	UPDATE rolt003
		SET n03_mes_ini = r_n01.n01_mes_proceso,
		    n03_dia_fin = dia,
		    n03_mes_fin = r_n01.n01_mes_proceso
		WHERE CURRENT OF q_fon
	
	COMMIT WORK

	CALL fl_mostrar_mensaje('Proceso Terminado Ok.', 'info')
END IF

END FUNCTION



FUNCTION contabilizado_procesos_nomina()
DEFINE resul		SMALLINT

CALL verificar_proceso_nomina('Q1', 'n32') RETURNING resul
IF resul THEN
	CALL verificar_proceso_nomina('Q2', 'n32') RETURNING resul
	IF resul THEN
		CALL verificar_proceso_nomina('DC', 'n36') RETURNING resul
		IF resul THEN
			CALL verificar_proceso_nomina('DT', 'n36')
				RETURNING resul
			IF resul THEN
				CALL verificar_proceso_nomina('FR', 'n38')
					RETURNING resul
				IF resul THEN
					CALL verificar_proceso_nomina('UT','n41')
						RETURNING resul
				END IF
			END IF
		END IF
	END IF
END IF
RETURN resul

END FUNCTION



FUNCTION verificar_proceso_nomina(proceso, pre)
DEFINE proceso		LIKE rolt003.n03_proceso
DEFINE pre		CHAR(3)
DEFINE r_rol		RECORD
				cia		LIKE rolt053.n53_compania,
				proc		LIKE rolt053.n53_cod_liqrol,
				fec_ini		LIKE rolt053.n53_fecha_ini,
				fec_fin		LIKE rolt053.n53_fecha_fin
			END RECORD
DEFINE r_n03		RECORD LIKE rolt003.*
DEFINE query		CHAR(800)
DEFINE mensaje		VARCHAR(200)
DEFINE expr_p		VARCHAR(20)
DEFINE resul		SMALLINT

IF proceso[1, 1] = 'Q' THEN
	LET expr_p = 'n32_cod_liqrol, '
END IF
IF proceso[1, 1] = 'D' OR proceso[1, 1] = 'U' THEN
	LET expr_p = pre, '_proceso, '
END IF
IF proceso[1, 1] = 'F' THEN
	LET expr_p = '"', proceso, '" proceso, '
END IF
LET query = 'SELECT ', pre, '_compania, ', expr_p CLIPPED, ' ',
			pre, '_fecha_ini, ', pre, '_fecha_fin ',
		' FROM rolt0', pre[2, 3],
		' WHERE ', pre, '_compania         = ', vg_codcia, 
		'   AND YEAR(', pre, '_fecha_fin)  = ', rm_par.n01_ano_proceso,
		'   AND MONTH(', pre, '_fecha_fin) = ', rm_par.n01_mes_proceso
PREPARE cons_pro FROM query
DECLARE q_proceso CURSOR FOR cons_pro
LET resul = 1
FOREACH q_proceso INTO r_rol.*
	SELECT * FROM rolt053
		WHERE n53_compania   = r_rol.cia
		  AND n53_cod_liqrol = r_rol.proc
		  AND n53_fecha_ini  = r_rol.fec_ini
		  AND n53_fecha_fin  = r_rol.fec_fin
	IF STATUS = NOTFOUND THEN
		CALL fl_lee_proceso_roles(r_rol.proc) RETURNING r_n03.*
		LET mensaje = 'El proceso ', r_n03.n03_proceso, ' ',
				r_n03.n03_nombre CLIPPED,
				' no esta contabilizado. Contabilice este ',
				'proceso primero antes de CERRAR EL MES.'
		CALL fl_mostrar_mensaje(mensaje, 'exclamation')
		LET resul = 0
		EXIT FOREACH
	END IF
END FOREACH
RETURN resul

END FUNCTION
