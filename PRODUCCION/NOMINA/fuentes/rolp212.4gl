--------------------------------------------------------------------------------
-- Titulo           : rolp212.4gl - Mantenimiento Novedades Roles de Usos
--			            Varios
-- Elaboracion      : 18-ago-2003
-- Autor            : JCM
-- Formato Ejecucion: fglrun rolp212 base módulo compañía
-- Ultima Correccion: 
-- Motivo Correccion: 
--------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_num_rows	INTEGER
DEFINE vm_row_current	INTEGER
DEFINE vm_max_rows	INTEGER
DEFINE vm_r_rows	ARRAY [1000] OF INTEGER
DEFINE vm_proceso	LIKE rolt005.n05_proceso
DEFINE vm_nivel		LIKE ctbt001.b01_nivel
DEFINE rm_b00		RECORD LIKE ctbt000.*
DEFINE rm_loc		RECORD LIKE gent002.*
DEFINE rm_n00		RECORD LIKE rolt000.*
DEFINE rm_n05		RECORD LIKE rolt005.*
DEFINE rm_par		RECORD
				n43_num_rol	LIKE rolt043.n43_num_rol,
				n43_estado	LIKE rolt043.n43_estado,
				n_estado	VARCHAR(15),
				n43_titulo	LIKE rolt043.n43_titulo,
				n43_moneda	LIKE rolt043.n43_moneda,
				n_moneda	LIKE gent013.g13_nombre,
				n43_tributa	LIKE rolt043.n43_tributa,
				n43_pago_efec	LIKE rolt043.n43_pago_efec,
				n43_incluir_ej	LIKE rolt043.n43_incluir_ej,
				n43_usuario	LIKE rolt043.n43_usuario,
				n43_fecing	LIKE rolt043.n43_fecing	
			END RECORD
DEFINE rm_scr		ARRAY[1000] OF RECORD 
				n44_cod_trab	LIKE rolt044.n44_cod_trab,
				n_trab		LIKE rolt030.n30_nombres,
				n44_valor	LIKE rolt044.n44_valor,
				n44_tipo_pago	LIKE rolt044.n44_tipo_pago,
				n_tipo_pago	VARCHAR(10)
			END RECORD
DEFINE rm_n44		ARRAY[1000] OF RECORD 
				n44_bco_empresa	LIKE rolt044.n44_bco_empresa,
				n44_cta_empresa	LIKE rolt044.n44_cta_empresa,
				n44_cta_trabaj	LIKE rolt044.n44_cta_trabaj
			END RECORD
DEFINE vm_filas_pant	INTEGER
DEFINE vm_numelm	INTEGER
DEFINE vm_maxelm	INTEGER



MAIN

DEFER QUIT 
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/rolp212.err')
CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 3 THEN          -- Validar # parámetros correcto
	CALL fgl_winmessage(vg_producto, 'Número de parámetros incorrecto', 'stop')
	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_proceso = 'rolp212'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
--#CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL control_master()

END MAIN



FUNCTION control_master()
DEFINE r_n01		RECORD LIKE rolt001.*

CALL fl_nivel_isolation()
CALL fl_lee_compania_contabilidad(vg_codcia) RETURNING rm_b00.*
IF rm_b00.b00_compania IS NULL THEN
	CALL fl_mostrar_mensaje('No existe ninguna compañía configurada en CONTABILIDAD.', 'stop')
	EXIT PROGRAM
END IF
SELECT MAX(b01_nivel) INTO vm_nivel FROM ctbt001
IF vm_nivel IS NULL THEN
	CALL fl_mostrar_mensaje('No existe ningun nivel de cuenta configurado en la compañía.','stop')
	EXIT PROGRAM
END IF
CALL fl_lee_localidad(vg_codcia, vg_codloc) RETURNING rm_loc.*
IF rm_loc.g02_compania IS NULL THEN
	DROP TABLE tmp_descuentos
	CALL fl_mostrar_mensaje('No existe localidad.','stop')
	EXIT PROGRAM
END IF
LET vm_max_rows	= 1000
LET vm_maxelm	= 1000
LET vm_proceso	= 'UV'
OPEN WINDOW w_rolf212_1 AT 3,2 WITH 22 ROWS, 80 COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE 0, BORDER,
			MESSAGE LINE LAST - 1)
OPEN FORM f_rolf212_1 FROM "../forms/rolf212_1"
DISPLAY FORM f_rolf212_1
LET vm_num_rows = 0
LET vm_row_current = 0
CALL muestra_contadores(vm_row_current, vm_num_rows)

INITIALIZE rm_n00.* TO NULL
CALL fl_lee_parametro_general_roles() RETURNING rm_n00.*
IF rm_n00.n00_moneda_pago IS NULL THEN
	CALL fl_mostrar_mensaje('No se han configurado parametros generales de roles.', 'stop')
	EXIT PROGRAM
END IF

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

CALL fl_retorna_proceso_roles_activo(vg_codcia) RETURNING rm_n05.*

LET vm_num_rows = 0

MENU 'OPCIONES'
	BEFORE MENU
		CALL mostrar_botones()
		HIDE OPTION 'Avanzar'
		HIDE OPTION 'Retroceder'
		HIDE OPTION 'Modificar'
		HIDE OPTION 'Eliminar'
		HIDE OPTION 'Cerrar'
		HIDE OPTION 'Imprimir'
		HIDE OPTION 'Archivo'
		HIDE OPTION 'Detalle'
		HIDE OPTION 'Contabilización'
		IF rm_n05.n05_proceso = vm_proceso THEN
			HIDE OPTION 'Ingresar'
		ELSE
			IF rm_n05.n05_proceso IS NOT NULL THEN
				HIDE OPTION 'Ingresar'
			END IF
			HIDE OPTION 'Modificar'
			HIDE OPTION 'Contabilización'
			HIDE OPTION 'Eliminar'
			HIDE OPTION 'Cerrar'
		END IF
	COMMAND KEY('I') 'Ingresar' 'Ingresar nuevos registros. '
		CALL control_ingreso()
		IF vm_num_rows = 1 THEN
			SHOW OPTION 'Modificar'
			SHOW OPTION 'Eliminar'
			SHOW OPTION 'Cerrar'
			IF rm_par.n43_estado = 'A' THEN
				HIDE OPTION 'Contabilización'
			ELSE
				SHOW OPTION 'Contabilización'
			END IF
		END IF
		IF vm_row_current > 1 THEN
			SHOW OPTION 'Retroceder'
		END IF
		IF vm_row_current = vm_num_rows THEN
			HIDE OPTION 'Avanzar'
		END IF
		IF rm_n05.n05_proceso IS NOT NULL THEN
			HIDE OPTION 'Ingresar'
			SHOW OPTION 'Modificar'
			SHOW OPTION 'Eliminar'
			SHOW OPTION 'Cerrar'
			IF rm_par.n43_estado = 'A' THEN
				HIDE OPTION 'Contabilización'
			ELSE
				SHOW OPTION 'Contabilización'
			END IF
		END IF
		IF vm_num_rows > 0 THEN
			SHOW OPTION 'Imprimir'
			SHOW OPTION 'Archivo'
			SHOW OPTION 'Detalle'
		END IF
       	COMMAND KEY('M') 'Modificar' 'Modificar registro corriente. '
		CALL control_modificacion()
	COMMAND KEY('C') 'Consultar' 'Consultar un registro. '
		CALL control_consulta()
		IF vm_num_rows <= 1 THEN
			HIDE OPTION 'Avanzar'
			HIDE OPTION 'Retroceder'
			IF vm_num_rows = 0 THEN
				HIDE OPTION 'Modificar'
				HIDE OPTION 'Eliminar'
				HIDE OPTION 'Cerrar'
				HIDE OPTION 'Detalle'
				HIDE OPTION 'Imprimir'
				HIDE OPTION 'Archivo'
				HIDE OPTION 'Contabilización'
			END IF
		ELSE
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Modificar'
			SHOW OPTION 'Eliminar'
			SHOW OPTION 'Cerrar'
			IF rm_par.n43_estado = 'A' THEN
				HIDE OPTION 'Contabilización'
			ELSE
				SHOW OPTION 'Contabilización'
			END IF
		END IF
		IF vm_row_current <= 1 THEN
                        HIDE OPTION 'Retroceder'
                END IF
		IF rm_par.n43_estado = 'A' THEN
			SHOW OPTION 'Modificar'
			SHOW OPTION 'Eliminar'
			SHOW OPTION 'Cerrar'
		ELSE
			HIDE OPTION 'Modificar'
			HIDE OPTION 'Eliminar'
			HIDE OPTION 'Cerrar'
		END IF
		IF vm_num_rows > 0 THEN
			SHOW OPTION 'Archivo'
			SHOW OPTION 'Imprimir'
			SHOW OPTION 'Detalle'
			IF rm_par.n43_estado = 'A' THEN
				HIDE OPTION 'Contabilización'
			ELSE
				SHOW OPTION 'Contabilización'
			END IF
		END IF
       	COMMAND KEY('E') 'Eliminar' 'Elimina registro corriente. '
		CALL control_eliminacion()
		IF rm_n05.n05_proceso IS NULL THEN
			SHOW OPTION 'Ingresar'
			HIDE OPTION 'Modificar'
			IF rm_par.n43_estado = 'A' THEN
				HIDE OPTION 'Contabilización'
			ELSE
				SHOW OPTION 'Contabilización'
			END IF
			HIDE OPTION 'Eliminar'
			HIDE OPTION 'Cerrar'
		END IF
		IF vm_num_rows > 0 THEN
			SHOW OPTION 'Imprimir'
			SHOW OPTION 'Archivo'
			SHOW OPTION 'Detalle'
		END IF
       	COMMAND KEY('U') 'Cerrar' 'Cierra el rol activo. '
		CALL control_cerrar()
		IF rm_n05.n05_proceso IS NULL THEN
			SHOW OPTION 'Ingresar'
			HIDE OPTION 'Modificar'
			HIDE OPTION 'Eliminar'
			HIDE OPTION 'Cerrar'
			IF rm_par.n43_estado = 'A' THEN
				HIDE OPTION 'Contabilización'
			ELSE
				SHOW OPTION 'Contabilización'
			END IF
		END IF
	COMMAND KEY('B') 'Contabilización' 'Contabiliza el registro actual. '
		CALL control_contabilizacion()
	COMMAND KEY('X') 'Archivo' 'Genera un archivo para el banco. '
		CALL control_archivo()
	COMMAND KEY('I') 'Imprimir' 'Imprime un registro. '
		CALL control_imprimir()
	COMMAND KEY('D') 'Detalle' 'Consulta el detalle del registro actual. '
		CALL control_detalle()
	COMMAND KEY('A') 'Avanzar' 'Ver siguiente registro. '
		CALL muestra_siguiente_registro()
		IF vm_row_current = vm_num_rows THEN
			HIDE OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
			NEXT OPTION 'Retroceder'
		ELSE
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
		END IF
		IF rm_par.n43_estado = 'A' THEN
			SHOW OPTION 'Modificar'
			SHOW OPTION 'Eliminar'
			SHOW OPTION 'Cerrar'
		ELSE
			HIDE OPTION 'Modificar'
			HIDE OPTION 'Eliminar'
			HIDE OPTION 'Cerrar'
		END IF
		IF vm_num_rows > 0 THEN
			SHOW OPTION 'Detalle'
		END IF
	COMMAND KEY('R') 'Retroceder'  'Ver anterior registro. '
		CALL muestra_anterior_registro()
		IF vm_row_current = 1 THEN
			HIDE OPTION 'Retroceder'
			SHOW OPTION 'Avanzar'
			NEXT OPTION 'Avanzar'
		ELSE
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
		END IF
		IF rm_par.n43_estado = 'A' THEN
			SHOW OPTION 'Modificar'
			SHOW OPTION 'Eliminar'
			SHOW OPTION 'Cerrar'
		ELSE
			HIDE OPTION 'Modificar'
			HIDE OPTION 'Eliminar'
			HIDE OPTION 'Cerrar'
		END IF
		IF vm_num_rows > 0 THEN
			SHOW OPTION 'Detalle'
		END IF
	COMMAND KEY('S') 'Salir' 'Salir del programa. '
		EXIT MENU
END MENU

END FUNCTION



FUNCTION control_ingreso()
DEFINE r_mon		RECORD LIKE gent013.*
DEFINE r_n43		RECORD LIKE rolt043.*

CLEAR FORM
CALL mostrar_botones()
CALL fl_retorna_usuario()
INITIALIZE rm_par.*, r_mon.* TO NULL
CALL fl_lee_moneda(rm_n00.n00_moneda_pago) RETURNING r_mon.*
IF r_mon.g13_moneda IS NULL THEN
	CALL fgl_winmessage(vg_producto,'No existe ninguna moneda base','stop')
	EXIT PROGRAM
END IF
LET rm_par.n43_moneda     = rm_n00.n00_moneda_pago
LET rm_par.n_moneda       = r_mon.g13_nombre 
LET rm_par.n43_estado     = 'A'
LET rm_par.n_estado       = 'ACTIVO'
LET rm_par.n43_tributa    = 'S'
LET rm_par.n43_pago_efec  = 'N'
LET rm_par.n43_incluir_ej = 'N'
LET rm_par.n43_usuario    = vg_usuario
LET rm_par.n43_fecing     = CURRENT

CALL leer_datos()
IF int_flag THEN
	CLEAR FORM
	CALL mostrar_botones()
	IF vm_row_current > 0 THEN
		CALL mostrar_registro(vm_r_rows[vm_row_current])
	END IF
	RETURN	
END IF

CALL leer_valores('I')
IF int_flag THEN
	CLEAR FORM
	CALL mostrar_botones()
	IF vm_row_current > 0 THEN
		CALL mostrar_registro(vm_r_rows[vm_row_current])
	END IF
	RETURN
END IF

BEGIN WORK

SELECT * INTO rm_n05.*
	FROM rolt005
	WHERE n05_compania = vg_codcia
	  AND n05_proceso  = vm_proceso

IF STATUS = NOTFOUND THEN
	INITIALIZE rm_n05.* TO NULL
	LET rm_n05.n05_compania   = vg_codcia
	LET rm_n05.n05_proceso    = vm_proceso
	LET rm_n05.n05_activo     = 'S'
	LET rm_n05.n05_fecini_act = CURRENT
	LET rm_n05.n05_fecfin_act = CURRENT
	LET rm_n05.n05_fec_ultcie = CURRENT
	LET rm_n05.n05_fec_cierre = CURRENT
	LET rm_n05.n05_usuario    = vg_codcia
	LET rm_n05.n05_fecing     = CURRENT

	INSERT INTO rolt005 VALUES (rm_n05.*) 
ELSE
	LET rm_n05.n05_activo     = 'S'
	UPDATE rolt005 SET n05_activo = 'S'
		WHERE n05_compania    = vg_codcia
		  AND n05_proceso = vm_proceso
END IF 

SELECT NVL(MAX(n43_num_rol) + 1, 1)
	INTO rm_par.n43_num_rol 
	FROM rolt043
	WHERE n43_compania = vg_codcia
LET r_n43.n43_compania   = vg_codcia 
LET r_n43.n43_num_rol    = rm_par.n43_num_rol 
LET r_n43.n43_titulo     = rm_par.n43_titulo
LET r_n43.n43_estado     = rm_par.n43_estado
LET r_n43.n43_moneda     = rm_par.n43_moneda
LET r_n43.n43_paridad    = calcula_paridad(rm_par.n43_moneda, 
		  			 rm_n00.n00_moneda_pago)  
LET r_n43.n43_tributa    = rm_par.n43_tributa
LET r_n43.n43_pago_efec  = rm_par.n43_pago_efec
LET r_n43.n43_incluir_ej = rm_par.n43_incluir_ej
LET r_n43.n43_usuario    = rm_par.n43_usuario
LET r_n43.n43_fecing     = CURRENT

INSERT INTO rolt043 VALUES (r_n43.*)

IF vm_num_rows = vm_max_rows THEN
	LET vm_num_rows = 1
ELSE
	LET vm_num_rows = vm_num_rows + 1
END IF
LET vm_row_current = vm_num_rows
LET vm_r_rows[vm_row_current] = SQLCA.SQLERRD[6] 

CALL graba_detalle()

COMMIT WORK

INITIALIZE rm_n05.* TO NULL 
SELECT * INTO rm_n05.* FROM rolt005
	WHERE n05_compania = vg_codcia
	  AND n05_activo   = 'S' 

CALL mostrar_registro(vm_r_rows[vm_num_rows])	
CALL muestra_contadores(vm_row_current, vm_num_rows)
CALL fl_mensaje_registro_ingresado()

END FUNCTION



FUNCTION control_modificacion()
DEFINE r_n43		RECORD LIKE rolt043.*
DEFINE paridad 		LIKE rolt043.n43_paridad

IF vm_num_rows = 0 THEN
	CALL fl_mensaje_consultar_primero()
	RETURN
END IF
CALL mostrar_registro(vm_r_rows[vm_row_current])

IF rm_par.n43_estado = 'P' THEN
	CALL fl_mostrar_mensaje('Este rol ya ha sido procesado.', 'stop')
	RETURN
END IF

BEGIN WORK
WHENEVER ERROR CONTINUE
DECLARE q_up CURSOR FOR
	SELECT * FROM rolt043
		WHERE ROWID = vm_r_rows[vm_row_current]
	FOR UPDATE
OPEN q_up
FETCH q_up INTO r_n43.*
IF STATUS < 0 THEN
	ROLLBACK WORK
	WHENEVER ERROR STOP
	CALL fl_mensaje_bloqueo_otro_usuario()
	RETURN
END IF
WHENEVER ERROR STOP
CALL muestra_detalle('M')
CALL leer_datos()
IF int_flag THEN
	ROLLBACK WORK
	CLEAR FORM
	CALL mostrar_botones()
	IF vm_row_current > 0 THEN
		CALL mostrar_registro(vm_r_rows[vm_row_current])
	END IF
	RETURN
END IF
 
CALL leer_valores('M')
IF int_flag THEN
	ROLLBACK WORK
	CLEAR FORM
	CALL mostrar_botones()
	IF vm_row_current > 0 THEN
		CALL mostrar_registro(vm_r_rows[vm_row_current])
	END IF
	RETURN
END IF

LET paridad = calcula_paridad(rm_par.n43_moneda, rm_n00.n00_moneda_pago)
UPDATE rolt043
	SET n43_titulo     = rm_par.n43_titulo,
	    n43_moneda     = rm_par.n43_moneda,
	    n43_paridad    = paridad,
	    n43_tributa    = rm_par.n43_tributa,
	    n43_pago_efec  = rm_par.n43_pago_efec,
	    n43_incluir_ej = rm_par.n43_incluir_ej
	WHERE CURRENT OF q_up
CALL graba_detalle()
COMMIT WORK

CALL muestra_detalle('C')
CALL fl_mensaje_registro_modificado()

END FUNCTION



FUNCTION control_imprimir()
DEFINE comando 		VARCHAR(255)

	LET comando = 'fglrun rolp415 ', vg_base, ' ', vg_modulo,
                      ' ', vg_codcia, ' ', rm_par.n43_num_rol

	RUN comando
                     
END FUNCTION



FUNCTION control_eliminacion()
DEFINE r_n43		RECORD LIKE rolt043.*
DEFINE resp		VARCHAR(6)

IF vm_num_rows = 0 THEN
	CALL fl_mensaje_consultar_primero()
	RETURN
END IF
CALL mostrar_registro(vm_r_rows[vm_row_current])

IF rm_par.n43_estado = 'P' THEN
	CALL fl_mostrar_mensaje('Este rol ya ha sido procesado.', 'stop')
	RETURN
END IF

CALL fl_mensaje_seguro_ejecutar_proceso() RETURNING resp
IF resp = 'No' THEN
        LET int_flag = 0
        RETURN
END IF

BEGIN WORK

WHENEVER ERROR CONTINUE
DECLARE q_del CURSOR FOR SELECT * FROM rolt043
        WHERE ROWID = vm_r_rows[vm_row_current]
        FOR UPDATE
OPEN q_del
FETCH q_del INTO r_n43.*
IF STATUS < 0 THEN
        ROLLBACK WORK
        WHENEVER ERROR STOP
        CALL fl_mensaje_bloqueo_otro_usuario()
        RETURN
END IF
WHENEVER ERROR STOP

DELETE FROM rolt044 WHERE n44_compania = vg_codcia
		      AND n44_num_rol  = rm_par.n43_num_rol

DELETE FROM rolt043 WHERE CURRENT OF q_del
CLOSE q_del

UPDATE rolt005 SET n05_activo = 'N'
	WHERE n05_compania = vg_codcia
	  AND n05_proceso  = rm_n05.n05_proceso
	  AND n05_activo   = 'S'

COMMIT WORK

INITIALIZE rm_n05.* TO NULL
INITIALIZE rm_par.* TO NULL

CLEAR FORM
CALL mostrar_botones()

LET vm_num_rows = vm_num_rows - 1
LET vm_row_current = 1

CALL muestra_contadores(vm_row_current, vm_num_rows)

CALL fl_mensaje_registro_modificado()

END FUNCTION



FUNCTION control_cerrar()
DEFINE r_n43		RECORD LIKE rolt043.*
DEFINE resp		VARCHAR(6)

IF vm_num_rows = 0 THEN
	CALL fl_mensaje_consultar_primero()
	RETURN
END IF
CALL mostrar_registro(vm_r_rows[vm_row_current])

IF rm_par.n43_estado = 'P' THEN
	CALL fl_mostrar_mensaje('Este rol ya ha sido procesado.', 'stop')
	RETURN
END IF

CALL fl_mensaje_seguro_ejecutar_proceso() RETURNING resp
IF resp = 'No' THEN
        LET int_flag = 0
        RETURN
END IF

BEGIN WORK

WHENEVER ERROR CONTINUE
DECLARE q_cerr CURSOR FOR SELECT * FROM rolt043
        WHERE ROWID = vm_r_rows[vm_row_current]
        FOR UPDATE
OPEN q_cerr
FETCH q_cerr INTO r_n43.*
IF STATUS < 0 THEN
        ROLLBACK WORK
        WHENEVER ERROR STOP
        CALL fl_mensaje_bloqueo_otro_usuario()
        RETURN
END IF
WHENEVER ERROR STOP

UPDATE rolt043
	SET n43_estado = 'P'
	WHERE CURRENT OF q_cerr

UPDATE rolt005
	SET n05_activo = 'N'
	WHERE n05_compania = vg_codcia
	  AND n05_proceso  = rm_n05.n05_proceso
	  AND n05_activo   = 'S'

COMMIT WORK

INITIALIZE rm_n05.* TO NULL 
SELECT * INTO rm_n05.*
	FROM rolt005
	WHERE n05_compania = vg_codcia
	  AND n05_activo   = 'S' 

CALL mostrar_registro(vm_r_rows[vm_num_rows])	
CALL muestra_contadores(vm_row_current, vm_num_rows)
CALL fl_mensaje_registro_modificado()

END FUNCTION



FUNCTION control_consulta()
DEFINE mone_aux		LIKE gent013.g13_moneda
DEFINE nomm_aux		LIKE gent013.g13_nombre
DEFINE deci_aux		LIKE gent013.g13_decimales
DEFINE query		VARCHAR(400)
DEFINE expr_sql		VARCHAR(400)
DEFINE num_reg		INTEGER
DEFINE r_n43		RECORD LIKE rolt043.*

INITIALIZE rm_par.* TO NULL
LET int_flag = 0
CLEAR FORM
CALL mostrar_botones()
CONSTRUCT BY NAME expr_sql ON n43_num_rol, n43_estado, n43_titulo, n43_moneda,
				n43_tributa, n43_pago_efec, n43_incluir_ej,
				n43_usuario   
	ON KEY(INTERRUPT)
		LET int_flag = 1
		EXIT CONSTRUCT
	ON KEY(F2)
		IF INFIELD(n43_num_rol) THEN
			CALL fl_ayuda_roles_usos_varios(vg_codcia, 'T')
				RETURNING rm_par.n43_num_rol, rm_par.n43_titulo
			LET int_flag = 0
			IF rm_par.n43_num_rol IS NOT NULL THEN
				DISPLAY BY NAME rm_par.*
			END IF 
		END IF
		IF INFIELD(n43_moneda) THEN
			CALL fl_ayuda_monedas()
				RETURNING mone_aux, nomm_aux, deci_aux
			LET int_flag = 0
			IF mone_aux IS NOT NULL THEN
				LET rm_par.n43_moneda = mone_aux	
				LET rm_par.n_moneda   = nomm_aux	
				DISPLAY BY NAME rm_par.*
			END IF 
		END IF
END CONSTRUCT
IF int_flag THEN
	IF vm_row_current > 0 THEN
		CALL mostrar_registro(vm_r_rows[vm_row_current])
	ELSE
		CLEAR FORM
		INITIALIZE rm_par.* TO NULL
		CALL mostrar_botones()
	END IF
	RETURN
END IF
LET query = 'SELECT *, ROWID ',
		'FROM rolt043 ',
		'WHERE ', expr_sql CLIPPED,
		' ORDER BY 1, 2 DESC'
PREPARE cons FROM query	
DECLARE q_cons CURSOR FOR cons
LET vm_num_rows = 0
FOREACH q_cons INTO r_n43.*, num_reg
	LET vm_num_rows = vm_num_rows + 1
        IF vm_num_rows > vm_max_rows THEN
		LET vm_num_rows = vm_num_rows - 1
                EXIT FOREACH
        END IF
	LET vm_r_rows[vm_num_rows] = num_reg
END FOREACH
IF vm_num_rows = 0 THEN
	LET int_flag = 0
	INITIALIZE rm_par.* TO NULL
	CALL fl_mensaje_consulta_sin_registros()
	CLEAR FORM
	CALL mostrar_botones()
	LET vm_row_current = 0
ELSE  
	LET vm_row_current = 1
	CALL mostrar_registro(vm_r_rows[vm_row_current])
	CALL muestra_detalle('C')
	CALL muestra_contadores(vm_row_current, vm_num_rows)
END IF

END FUNCTION



FUNCTION leer_datos()
DEFINE resp		CHAR(6)
DEFINE r_mon		RECORD LIKE gent013.*
DEFINE mone_aux		LIKE gent013.g13_moneda
DEFINE nomm_aux		LIKE gent013.g13_nombre
DEFINE deci_aux		LIKE gent013.g13_decimales

LET int_flag = 0
INITIALIZE r_mon.* TO NULL
INPUT BY NAME rm_par.*
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
        	IF FIELD_TOUCHED(rm_par.n43_titulo, rm_par.n43_moneda,
				 rm_par.n43_tributa, rm_par.n43_pago_efec,
				 rm_par.n43_incluir_ej)
		THEN
               		LET int_flag = 0
			CALL fl_mensaje_abandonar_proceso() RETURNING resp
              		IF resp = 'Yes' THEN
				LET int_flag = 1
	                       	CLEAR FORM
				CALL mostrar_botones()
				EXIT INPUT
                	END IF
		ELSE
			EXIT INPUT
		END IF
	ON KEY(F2)
		IF INFIELD(n43_moneda) THEN
			CALL fl_ayuda_monedas()
				RETURNING mone_aux, nomm_aux, deci_aux
			LET int_flag = 0
			IF mone_aux IS NOT NULL THEN
				LET rm_par.n43_moneda = mone_aux
				LET rm_par.n_moneda   = nomm_aux
				DISPLAY BY NAME rm_par.*
			END IF 
		END IF
	AFTER FIELD n43_moneda
		IF rm_par.n43_moneda IS NOT NULL THEN
			CALL fl_lee_moneda(rm_par.n43_moneda)
				RETURNING r_mon.* 
			IF r_mon.g13_moneda IS NULL  THEN
				CALL fgl_winmessage(vg_producto,'Moneda no existe','exclamation')
				NEXT FIELD n43_moneda
			ELSE
				DISPLAY r_mon.g13_nombre TO n_moneda
			END IF
			IF r_mon.g13_estado = 'B' THEN
                                CALL fl_mensaje_estado_bloqueado()
				NEXT FIELD n43_moneda
			END IF
		ELSE
			LET rm_par.n43_moneda = rg_gen.g00_moneda_base
			DISPLAY BY NAME rm_par.n43_moneda
			CALL fl_lee_moneda(rm_par.n43_moneda)
				RETURNING r_mon.* 
			DISPLAY r_mon.g13_nombre TO n_moneda
		END IF
	AFTER INPUT
		IF rm_par.n43_tributa IS NULL THEN
			LET rm_par.n43_tributa = 'S'
			DISPLAY BY NAME rm_par.n43_tributa
		END IF
		IF rm_par.n43_pago_efec IS NULL THEN
			LET rm_par.n43_pago_efec = 'N'
			DISPLAY BY NAME rm_par.n43_pago_efec
		END IF
		IF rm_par.n43_incluir_ej IS NULL THEN
			LET rm_par.n43_incluir_ej = 'N'
			DISPLAY BY NAME rm_par.n43_incluir_ej
		END IF
END INPUT

END FUNCTION



FUNCTION muestra_detalle(opcion)
DEFINE opcion 		CHAR(1)
DEFINE i		SMALLINT

CALL carga_trabajadores(opcion)
LET int_flag = 0
CALL set_count(vm_numelm)
DISPLAY ARRAY rm_scr TO ra_scr.*
	ON KEY(INTERRUPT)
		LET int_flag = 1
		EXIT DISPLAY
	ON KEY(F5)
                LET i = arr_curr()
		CALL control_forma_pago(i)
		LET int_flag = 0
	BEFORE DISPLAY
                --#CALL dialog.keysetlabel('ACCEPT','')
                --#CALL dialog.keysetlabel('F5','Forma de Pago')
                LET vm_filas_pant = fgl_scr_size('ra_scr')
		DISPLAY calcula_totales() TO tot_valor
		EXIT DISPLAY
	BEFORE ROW
                LET i = arr_curr()
		DISPLAY i         TO num_row
		DISPLAY vm_numelm TO max_row
END DISPLAY
	
END FUNCTION



FUNCTION control_detalle()
DEFINE i		SMALLINT

IF vm_num_rows = 0 THEN
	CALL fl_mensaje_consultar_primero()
	RETURN
END IF
LET int_flag = 0
CALL set_count(vm_numelm)
DISPLAY ARRAY rm_scr TO ra_scr.*
	ON KEY(INTERRUPT)
		LET int_flag = 1
		EXIT DISPLAY
	ON KEY(F5)
                LET i = arr_curr()
		CALL control_forma_pago(i)
		LET int_flag = 0
	BEFORE DISPLAY
                --#CALL dialog.keysetlabel('ACCEPT','')
                --#CALL dialog.keysetlabel('F5','Forma de Pago')
		DISPLAY calcula_totales() TO tot_valor
	BEFORE ROW
                LET i = arr_curr()
		DISPLAY i         TO num_row
		DISPLAY vm_numelm TO max_row
END DISPLAY

END FUNCTION



FUNCTION graba_detalle()
DEFINE i 		SMALLINT
DEFINE r_n30		RECORD LIKE rolt030.*
DEFINE r_n44		RECORD LIKE rolt044.*

DELETE FROM rolt044
	WHERE n44_compania = vg_codcia
	  AND n44_num_rol  = rm_par.n43_num_rol
FOR i = 1 TO vm_numelm
	IF rm_scr[i].n44_valor = 0 THEN
		CONTINUE FOR
	END IF
	CALL fl_lee_trabajador_roles(vg_codcia, rm_scr[i].n44_cod_trab)
		RETURNING r_n30.*
	INITIALIZE r_n44.* TO NULL
	LET r_n44.n44_compania    = vg_codcia
	LET r_n44.n44_num_rol     = rm_par.n43_num_rol
	LET r_n44.n44_cod_trab    = rm_scr[i].n44_cod_trab
	LET r_n44.n44_cod_depto   = r_n30.n30_cod_depto
	LET r_n44.n44_tipo_pago   = rm_scr[i].n44_tipo_pago
	LET r_n44.n44_bco_empresa = rm_n44[i].n44_bco_empresa
	LET r_n44.n44_cta_empresa = rm_n44[i].n44_cta_empresa
	LET r_n44.n44_cta_trabaj  = rm_n44[i].n44_cta_trabaj
	LET r_n44.n44_valor       = rm_scr[i].n44_valor 
	INSERT INTO rolt044 VALUES (r_n44.*)
END FOR

END FUNCTION



FUNCTION leer_valores(opcion)
DEFINE r_n30		RECORD LIKE rolt030.*
DEFINE opcion		CHAR(1)
DEFINE i, j		SMALLINT
DEFINE resp             VARCHAR(6)
DEFINE tot_valor	LIKE rolt044.n44_valor

CALL carga_trabajadores(opcion)
LET int_flag = 0
CALL set_count(vm_numelm)
INPUT ARRAY rm_scr WITHOUT DEFAULTS FROM ra_scr.*
	ON KEY(INTERRUPT)
		LET int_flag = 0
		CALL fl_mensaje_abandonar_proceso() RETURNING resp
		IF resp = 'Yes' THEN
			LET int_flag = 1
			EXIT INPUT
		END IF
	ON KEY(F5)
		IF rm_par.n43_pago_efec = 'S' THEN
			CONTINUE INPUT
		END IF
       	        LET i = arr_curr()
               	LET j = scr_line()
		CALL control_forma_pago(i)
		IF NOT int_flag THEN
			CALL muestra_tipo_pago(i)
			DISPLAY rm_scr[i].* TO ra_scr[j].*
		END IF
		LET int_flag = 0
        BEFORE INPUT
       	        --#CALL dialog.keysetlabel('INSERT','')
               	--#CALL dialog.keysetlabel('DELETE','')
		--#IF rm_par.n43_pago_efec = 'N' THEN
       	        	--#CALL dialog.keysetlabel('F5','Forma de Pago')
		--#ELSE
               		--#CALL dialog.keysetlabel('F5','')
		--#END IF
       	        LET vm_filas_pant = fgl_scr_size('ra_scr')
		DISPLAY calcula_totales() TO tot_valor
        BEFORE ROW
       	        LET i = arr_curr()
               	LET j = scr_line()
		DISPLAY i         TO num_row
		DISPLAY vm_numelm TO max_row
	BEFORE INSERT
		--#CANCEL INSERT
	BEFORE DELETE
		--#CANCEL DELETE
        AFTER FIELD n44_valor
       	        IF rm_scr[i].n44_valor IS NULL THEN
			NEXT FIELD n44_valor
		END IF
                IF rm_scr[i].n44_valor IS NOT NULL THEN
			IF rm_scr[i].n44_valor < 0 THEN
                               	NEXT FIELD n44_valor
                        END IF
       	        END IF
		DISPLAY calcula_totales() TO tot_valor
        AFTER FIELD n44_tipo_pago
		IF rm_scr[i].n44_tipo_pago IS NULL THEN
			NEXT FIELD n44_tipo_pago
		END IF
		CASE rm_scr[i].n44_tipo_pago
			WHEN 'E'
				LET rm_scr[i].n_tipo_pago = 'EFECTIVO'
			WHEN 'C'
				CALL fl_lee_trabajador_roles(vg_codcia,
						rm_scr[i].n44_cod_trab)
					RETURNING r_n30.*
				IF r_n30.n30_bco_empresa IS NULL OR
				   r_n30.n30_cta_empresa IS NULL   
				THEN
					CALL fl_mostrar_mensaje('Debe configurar el banco y la cuenta de donde se emitirá el cheque para este trabajador.', 'stop')
					NEXT FIELD n44_tipo_pago	
				END IF
				LET rm_scr[i].n_tipo_pago = 'CHEQUE'
			WHEN 'T'
				CALL fl_lee_trabajador_roles(vg_codcia,
						rm_scr[i].n44_cod_trab)
					RETURNING r_n30.*
				IF r_n30.n30_bco_empresa IS NULL OR
				   r_n30.n30_cta_empresa IS NULL   
				THEN
					CALL fl_mostrar_mensaje('Debe configurar el banco y la cuenta de donde se descontará el valor de la transferencia para este trabajador.', 'stop')
					NEXT FIELD n44_tipo_pago	
				END IF
				IF r_n30.n30_cta_trabaj IS NULL THEN
					CALL fl_mostrar_mensaje('Debe configurar la cuenta donde se acreditará el valor de la transferencia para este trabajador.', 'stop')
					NEXT FIELD n44_tipo_pago	
				END IF
				LET rm_scr[i].n_tipo_pago = 'TRANSFER.'
		END CASE
		DISPLAY rm_scr[i].* TO ra_scr[j].*
       	AFTER INPUT
		LET tot_valor = calcula_totales() 		
		DISPLAY BY NAME tot_valor
		IF tot_valor = 0 THEN
			CALL fl_mostrar_mensaje('No se puede grabar si no ingresa detalles.', 'stop')
			CONTINUE INPUT 
		END IF
END INPUT

END FUNCTION



FUNCTION carga_trabajadores(opcion)
DEFINE opcion		CHAR(1)
DEFINE query		VARCHAR(2000)
DEFINE tabla_rolt044	VARCHAR(50)
DEFINE join_rolt044	CHAR(400)
DEFINE campo_rolt044	CHAR(600)
DEFINE expr_est		VARCHAR(100)

LET expr_est = NULL
CASE opcion
	WHEN 'C'
		IF rm_par.n43_num_rol IS NULL THEN
			RETURN
		END IF
		LET campo_rolt044 = ' n44_valor, n44_tipo_pago, "", ',
					'n44_bco_empresa, n44_cta_empresa, ',
					'n44_cta_trabaj '
		LET tabla_rolt044 = ', rolt044 '
		LET join_rolt044  = ' AND n44_compania = n30_compania ',
                                    ' AND n44_num_rol  = ', rm_par.n43_num_rol,
            			    ' AND n44_cod_trab = n30_cod_trab'
	WHEN 'M'
		IF rm_par.n43_num_rol IS NULL THEN
			RETURN
		END IF
		LET campo_rolt044 = ' NVL(n44_valor, n03_valor), '
		IF rm_par.n43_pago_efec = 'N' THEN
			LET campo_rolt044 = campo_rolt044 CLIPPED, ' ',
				'NVL(n44_tipo_pago, n30_tipo_pago), "", ',
				'CASE WHEN NVL(n44_tipo_pago, n30_tipo_pago) = "E" ',
					'THEN n44_bco_empresa ',
					'ELSE NVL(n44_bco_empresa, ',
							'n30_bco_empresa) ',
				'END, ',
				'CASE WHEN NVL(n44_tipo_pago, n30_tipo_pago) = "E" ',
					'THEN n44_cta_empresa ',
					'ELSE NVL(n44_cta_empresa, ',
							'n30_cta_empresa) ',
				'END, ',
				'CASE WHEN NVL(n44_tipo_pago, n30_tipo_pago) = "E" ',
					'THEN n44_cta_trabaj ',
					'ELSE NVL(n44_cta_trabaj, ',
							'n30_cta_trabaj) ',
				'END '
		ELSE
			LET campo_rolt044 = campo_rolt044 CLIPPED, ' "E", "", ',
					' "", "", "" '
		END IF
		LET tabla_rolt044 = ', OUTER rolt044, rolt003 '
		LET join_rolt044  = ' AND n44_compania = n30_compania ',
                                    ' AND n44_num_rol  = ', rm_par.n43_num_rol,
            			    ' AND n44_cod_trab = n30_cod_trab'
		IF rm_par.n43_incluir_ej = 'N' THEN
			LET join_rolt044 = join_rolt044 CLIPPED,
					'   AND n30_tipo_trab   = "N" '
		END IF
		LET join_rolt044 = join_rolt044 CLIPPED,
					"  AND n03_proceso  = 'UV' "
		LET expr_est      = '	  AND n30_estado     = "A" '
	WHEN 'I'
		LET campo_rolt044 = ' n03_valor, '
		IF rm_par.n43_pago_efec = 'N' THEN
			LET campo_rolt044 = campo_rolt044 CLIPPED, ' ',
					'n30_tipo_pago, "", ',
					'n30_bco_empresa, n30_cta_empresa, ',
					'n30_cta_trabaj '
		ELSE
			LET campo_rolt044 = campo_rolt044 CLIPPED, ' "E", "", ',
					' "", "", "" '
		END IF
		LET tabla_rolt044 = ", rolt003 "
		LET join_rolt044  = " AND n03_proceso  = 'UV' "
		IF rm_par.n43_incluir_ej = 'N' THEN
			LET join_rolt044 = join_rolt044 CLIPPED,
					'   AND n30_tipo_trab   = "N" '
		END IF
		LET expr_est      = '	  AND n30_estado     = "A" '
END CASE

LET query = 'SELECT n30_cod_trab, n30_nombres, ', campo_rolt044 CLIPPED,
		' FROM rolt030 ',  tabla_rolt044 CLIPPED,
		' WHERE n30_compania    = ', vg_codcia,
		'   AND n30_fecha_ing  <= CURRENT ',
		expr_est CLIPPED,
		join_rolt044 CLIPPED,
		' ORDER BY n30_nombres '
PREPARE cons1 FROM query
DECLARE q_trab CURSOR FOR cons1
LET vm_numelm = 1
FOREACH q_trab INTO rm_scr[vm_numelm].*, rm_n44[vm_numelm].*
	IF rm_scr[vm_numelm].n44_valor IS NULL THEN
		LET rm_scr[vm_numelm].n44_valor = 0
	END IF
	CALL muestra_tipo_pago(vm_numelm)
        LET vm_numelm = vm_numelm + 1
        IF vm_numelm > vm_maxelm THEN
                CALL fl_mensaje_arreglo_incompleto()
                EXIT PROGRAM
        END IF
END FOREACH
LET vm_numelm = vm_numelm - 1

END FUNCTION



FUNCTION muestra_tipo_pago(pos)
DEFINE pos		SMALLINT

CASE rm_scr[pos].n44_tipo_pago
	WHEN 'E' LET rm_scr[pos].n_tipo_pago = 'EFECTIVO'
	WHEN 'C' LET rm_scr[pos].n_tipo_pago = 'CHEQUE'
	WHEN 'T' LET rm_scr[pos].n_tipo_pago = 'TRANSFER.'
END CASE

END FUNCTION



FUNCTION calcula_totales()
DEFINE i                INTEGER
DEFINE valor            LIKE rolt044.n44_valor
DEFINE tot_valor        LIKE rolt044.n44_valor
                                                                                
LET tot_valor = 0
FOR i = 1 TO vm_numelm
	LET valor = rm_scr[i].n44_valor
	IF valor IS NULL THEN
		LET valor = 0
	END IF
        LET tot_valor = tot_valor + valor
END FOR
RETURN tot_valor
                                                                                
END FUNCTION



FUNCTION muestra_siguiente_registro()

IF vm_row_current < vm_num_rows THEN
	LET vm_row_current = vm_row_current + 1
END IF
CALL mostrar_registro(vm_r_rows[vm_row_current])
CALL muestra_contadores(vm_row_current, vm_num_rows)

END FUNCTION



FUNCTION muestra_anterior_registro()

IF vm_row_current > 1 THEN
	LET vm_row_current = vm_row_current - 1
END IF
CALL mostrar_registro(vm_r_rows[vm_row_current])
CALL muestra_contadores(vm_row_current, vm_num_rows)

END FUNCTION



FUNCTION muestra_contadores(row_current, num_rows)
DEFINE row_current	SMALLINT
DEFINE num_rows		SMALLINT
                                                                                
DISPLAY "" AT 1,1
DISPLAY row_current, " de ", num_rows AT 1, 69
                                                                                
END FUNCTION



FUNCTION calcula_paridad(moneda_ori, moneda_dest)
                                                                                
DEFINE moneda_ori       LIKE gent013.g13_moneda
DEFINE moneda_dest      LIKE gent013.g13_moneda
DEFINE paridad          LIKE gent014.g14_tasa
                                                                                
DEFINE r_g14            RECORD LIKE gent014.*
                                                                                
IF moneda_ori = moneda_dest THEN
        LET paridad = 1
ELSE
        CALL fl_lee_factor_moneda(moneda_ori, moneda_dest)
                RETURNING r_g14.*
        IF r_g14.g14_serial IS NULL THEN
                CALL fgl_winmessage(vg_producto,
                                    'No existe factor de conversión ' ||
                                    'para esta moneda',
                                    'exclamation')
                INITIALIZE paridad TO NULL
        ELSE
                LET paridad = r_g14.g14_tasa
        END IF
END IF
RETURN paridad
                                                                                
END FUNCTION
                                                                                
                                                                                
                                                                                
FUNCTION mostrar_botones()
                                                                                
DISPLAY 'Código'                TO bt_cod_trab
DISPLAY 'Nombre Trabajador'     TO bt_nom_trab
DISPLAY 'Valor'                 TO bt_valor
DISPLAY 'Tipo Pago'             TO bt_tipo_pago
                                                                                
END FUNCTION
               


FUNCTION mostrar_registro(num_registro)
DEFINE r_mon		RECORD LIKE gent013.*
DEFINE num_registro	INTEGER

DEFINE r_n43		RECORD LIKE rolt043.*

IF vm_num_rows <= 0 THEN
	RETURN
END IF

SELECT * INTO r_n43.* FROM rolt043 WHERE ROWID = num_registro	
IF STATUS = NOTFOUND THEN
	CALL fgl_winmessage (vg_producto,'No existe registro con índice: ' || vm_row_current,'exclamation')
	RETURN
END IF
	
INITIALIZE rm_par.* TO NULL
LET rm_par.n43_num_rol    = r_n43.n43_num_rol
LET rm_par.n43_titulo     = r_n43.n43_titulo
LET rm_par.n43_estado     = r_n43.n43_estado
CASE rm_par.n43_estado  
	WHEN 'A' LET rm_par.n_estado = 'ACTIVO'
	WHEN 'P' LET rm_par.n_estado = 'PROCESADO'
END CASE
LET rm_par.n43_moneda     = r_n43.n43_moneda
CALL fl_lee_moneda(r_n43.n43_moneda) RETURNING r_mon.* 
LET rm_par.n_moneda       = r_mon.g13_nombre
LET rm_par.n43_tributa    = r_n43.n43_tributa
LET rm_par.n43_pago_efec  = r_n43.n43_pago_efec
LET rm_par.n43_incluir_ej = r_n43.n43_incluir_ej
LET rm_par.n43_usuario	  = r_n43.n43_usuario
LET rm_par.n43_fecing	  = r_n43.n43_fecing

DISPLAY BY NAME	rm_par.*

CALL muestra_detalle('C')

END FUNCTION



FUNCTION control_forma_pago(pos)
DEFINE pos		SMALLINT
DEFINE r_aux		RECORD 
				n44_bco_empresa	LIKE rolt044.n44_bco_empresa,
				n44_cta_empresa	LIKE rolt044.n44_cta_empresa,
				n44_cta_trabaj	LIKE rolt044.n44_cta_trabaj
			END RECORD
DEFINE r_b10		RECORD LIKE ctbt010.*
DEFINE r_g08		RECORD LIKE gent008.*
DEFINE r_g09		RECORD LIKE gent009.*
DEFINE r_n30		RECORD LIKE rolt030.*
DEFINE r_n44		RECORD LIKE rolt044.*
DEFINE r_n53		RECORD LIKE rolt053.*
DEFINE tipo_pago	LIKE rolt044.n44_tipo_pago
DEFINE lin_men		SMALLINT
DEFINE num_rows 	SMALLINT
DEFINE num_cols 	SMALLINT
DEFINE resul	 	SMALLINT
DEFINE escape	 	INTEGER
DEFINE resp		CHAR(6)

LET lin_men  = 0
LET num_rows = 10
LET num_cols = 71
IF vg_gui = 0 THEN
	LET lin_men  = 1
	LET num_rows = 11
	LET num_cols = 72
END IF
OPEN WINDOW w_rolf212_2 AT 09, 05 WITH num_rows ROWS, num_cols COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE lin_men, BORDER,
		  MESSAGE LINE LAST)
IF vg_gui = 1 THEN
	OPEN FORM f_rolf212_2 FROM '../forms/rolf212_2'
ELSE
	OPEN FORM f_rolf212_2 FROM '../forms/rolf212_2c'
END IF
DISPLAY FORM f_rolf212_2
CALL fl_lee_banco_general(rm_n44[pos].n44_bco_empresa) RETURNING r_g08.*
DISPLAY BY NAME r_g08.g08_nombre
CALL lee_rol_cont(vg_codcia, rm_par.n43_num_rol) RETURNING r_n53.*
IF r_n53.n53_compania IS NOT NULL THEN
	WHILE TRUE
		DISPLAY BY NAME rm_scr[pos].n44_tipo_pago,
				rm_n44[pos].n44_bco_empresa,
				rm_n44[pos].n44_cta_empresa,
				rm_n44[pos].n44_cta_trabaj
		MESSAGE 'Presione ESC para SALIR ...'
		LET escape = fgl_getkey()
		IF escape <> 0 AND escape <> 27 THEN
			CONTINUE WHILE
		END IF
		EXIT WHILE
	END WHILE
	LET int_flag = 0
	CLOSE WINDOW w_rolf212_2
	RETURN
END IF
CALL fl_lee_trabajador_roles(vg_codcia, rm_scr[pos].n44_cod_trab)
	RETURNING r_n30.*
IF (r_n30.n30_tipo_pago  <> 'E' AND r_n30.n30_bco_empresa  IS NOT NULL) AND
   (rm_scr[pos].n44_tipo_pago <> 'E' AND rm_n44[pos].n44_bco_empresa IS NULL)
THEN
	LET rm_scr[pos].n44_tipo_pago   = r_n30.n30_tipo_pago
	LET rm_n44[pos].n44_bco_empresa = r_n30.n30_bco_empresa
	LET rm_n44[pos].n44_cta_empresa = r_n30.n30_cta_empresa
	IF rm_scr[pos].n44_tipo_pago = 'T' THEN
		LET rm_n44[pos].n44_cta_trabaj  = r_n30.n30_cta_trabaj
	END IF
	CALL fl_lee_banco_general(rm_n44[pos].n44_bco_empresa) RETURNING r_g08.*
	DISPLAY BY NAME r_g08.g08_nombre
ELSE
	INITIALIZE r_n44.* TO NULL
	SELECT * INTO r_n44.*
		FROM rolt044
		WHERE n44_compania = vg_codcia
		  AND n44_num_rol  = rm_par.n43_num_rol
		  AND n44_cod_trab = r_n30.n30_cod_trab
	IF r_n44.n44_compania IS NOT NULL THEN
		LET rm_scr[pos].n44_tipo_pago   = r_n44.n44_tipo_pago
		LET rm_n44[pos].n44_bco_empresa = r_n44.n44_bco_empresa
		LET rm_n44[pos].n44_cta_empresa = r_n44.n44_cta_empresa
		LET rm_n44[pos].n44_cta_trabaj  = r_n44.n44_cta_trabaj
		CALL fl_lee_banco_general(rm_n44[pos].n44_bco_empresa)
			RETURNING r_g08.*
		DISPLAY BY NAME r_g08.g08_nombre
	END IF
END IF
LET tipo_pago = rm_scr[pos].n44_tipo_pago
LET r_aux.*   = rm_n44[pos].*
LET int_flag  = 0
INPUT BY NAME rm_scr[pos].n44_tipo_pago, rm_n44[pos].n44_bco_empresa,
	rm_n44[pos].n44_cta_empresa, rm_n44[pos].n44_cta_trabaj
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		IF FIELD_TOUCHED(rm_scr[pos].n44_tipo_pago,
				 rm_n44[pos].n44_bco_empresa,
				 rm_n44[pos].n44_cta_empresa,
				 rm_n44[pos].n44_cta_trabaj)
		THEN
			LET int_flag = 0
			CALL fl_mensaje_abandonar_proceso() RETURNING resp
			IF resp = 'Yes' THEN
				LET rm_scr[pos].n44_tipo_pago   = tipo_pago
				LET rm_n44[pos].n44_bco_empresa =
							r_aux.n44_bco_empresa
				LET rm_n44[pos].n44_cta_empresa =
							r_aux.n44_cta_empresa
				LET rm_n44[pos].n44_cta_trabaj  =
							r_aux.n44_cta_trabaj
				LET int_flag = 1
				EXIT INPUT
			END IF
		ELSE
			EXIT INPUT
		END IF
	ON KEY(F2)
		IF INFIELD(n44_bco_empresa) THEN
                        CALL fl_ayuda_cuenta_banco(vg_codcia, 'A')
                                RETURNING r_g08.g08_banco, r_g08.g08_nombre,
					r_g09.g09_tipo_cta, r_g09.g09_numero_cta
                        IF r_g08.g08_banco IS NOT NULL THEN
				LET rm_n44[pos].n44_bco_empresa = r_g08.g08_banco
				LET rm_n44[pos].n44_cta_empresa =r_g09.g09_numero_cta
				IF rm_scr[pos].n44_tipo_pago = 'T' THEN
					LET rm_n44[pos].n44_cta_trabaj =
							r_n30.n30_cta_trabaj
				END IF
                                DISPLAY BY NAME rm_n44[pos].n44_bco_empresa,
						r_g08.g08_nombre,
						rm_n44[pos].n44_cta_empresa,
						rm_n44[pos].n44_cta_trabaj
                        END IF
                END IF
		IF INFIELD(n44_cta_trabaj) THEN
			CALL fl_ayuda_cuenta_contable(vg_codcia, vm_nivel)
				RETURNING r_b10.b10_cuenta,r_b10.b10_descripcion
			IF r_b10.b10_cuenta IS NOT NULL THEN
				LET rm_n44[pos].n44_cta_trabaj = r_b10.b10_cuenta
				DISPLAY BY NAME rm_n44[pos].n44_cta_trabaj
			END IF
		END IF
		LET int_flag = 0
	AFTER FIELD n44_tipo_pago
		IF rm_scr[pos].n44_tipo_pago = 'E' THEN
			INITIALIZE rm_n44[pos].* TO NULL
			DISPLAY BY NAME rm_n44[pos].*
			CLEAR g08_nombre
		END IF
	AFTER FIELD n44_bco_empresa
                IF rm_n44[pos].n44_bco_empresa IS NOT NULL THEN
                        CALL fl_lee_banco_general(rm_n44[pos].n44_bco_empresa)
                                RETURNING r_g08.*
			IF r_g08.g08_banco IS NULL THEN
				CALL fl_mostrar_mensaje('Banco no existe.','exclamation')
				NEXT FIELD n44_bco_empresa
			END IF
			DISPLAY BY NAME r_g08.g08_nombre
		ELSE
			CLEAR n44_bco_empresa, g08_nombre, n44_cta_empresa
                END IF
	AFTER FIELD n44_cta_empresa
                IF rm_n44[pos].n44_cta_empresa IS NOT NULL THEN
                        CALL fl_lee_banco_compania(vg_codcia,
						rm_n44[pos].n44_bco_empresa,
						rm_n44[pos].n44_cta_empresa)
                                RETURNING r_g09.*
			IF r_g09.g09_banco IS NULL THEN
				CALL fl_mostrar_mensaje('Banco o Cuenta Corriente no existe en la compañía.','exclamation')
				NEXT FIELD n44_bco_empresa
			END IF
			LET rm_n44[pos].n44_cta_empresa = r_g09.g09_numero_cta
			DISPLAY BY NAME rm_n44[pos].n44_cta_empresa
                        CALL fl_lee_banco_general(rm_n44[pos].n44_bco_empresa)
                                RETURNING r_g08.*
			DISPLAY BY NAME r_g08.g08_nombre
			IF r_g09.g09_estado = 'B' THEN
				CALL fl_mensaje_estado_bloqueado()
				NEXT FIELD n44_bco_empresa
			END IF
			CALL fl_lee_cuenta(r_g09.g09_compania,
						r_g09.g09_aux_cont)
				RETURNING r_b10.*
			IF r_b10.b10_compania IS NULL THEN
				CALL fl_mostrar_mensaje('No se puede escoger una cuenta corriente que no tiene auxiliar contable.', 'exclamation')
				NEXT FIELD n44_bco_empresa
			END IF
			IF r_b10.b10_estado <> 'A' THEN
				CALL fl_mostrar_mensaje('El auxiliar contable de esta cuenta bancaria esta con estado bloqueado.', 'exclamation')
				NEXT FIELD n44_bco_empresa
			END IF
			IF rm_scr[pos].n44_tipo_pago = 'T' THEN
				LET rm_n44[pos].n44_cta_trabaj =
						r_n30.n30_cta_trabaj
				DISPLAY BY NAME rm_n44[pos].n44_cta_trabaj
			END IF
		ELSE
			CLEAR n44_cta_empresa
		END IF
	AFTER FIELD n44_cta_trabaj
		IF rm_scr[pos].n44_tipo_pago <> 'T' THEN
			LET rm_n44[pos].n44_cta_trabaj = NULL
			DISPLAY BY NAME rm_n44[pos].n44_cta_trabaj
			CONTINUE INPUT
		END IF
		IF rm_n44[pos].n44_cta_trabaj IS NOT NULL THEN
			IF NOT validar_cuenta(rm_n44[pos].n44_cta_trabaj) THEN
				--NEXT FIELD n44_cta_trabaj
			END IF
		ELSE
			CLEAR n44_cta_trabaj
		END IF
	AFTER INPUT
		IF rm_scr[pos].n44_tipo_pago <> 'E' THEN
			IF rm_n44[pos].n44_bco_empresa IS NULL OR
			   rm_n44[pos].n44_cta_empresa IS NULL
			THEN
				CALL fl_mostrar_mensaje('Empleado con tipo de pago Cheque o Transferencia, debe ingresar el Banco y la Cuenta Corriente.', 'exclamation')
				NEXT FIELD n44_bco_empresa
			END IF
		ELSE
			IF rm_n44[pos].n44_bco_empresa IS NULL OR
			   rm_n44[pos].n44_cta_empresa IS NULL
			THEN
				INITIALIZE rm_n44[pos].n44_bco_empresa,
					rm_n44[pos].n44_cta_empresa TO NULL
				CLEAR n44_bco_empresa, n44_cta_empresa,
					g08_nombre
			END IF
		END IF
		IF rm_n44[pos].n44_cta_trabaj IS NULL THEN
			IF rm_scr[pos].n44_tipo_pago = 'T' THEN
				CALL fl_mostrar_mensaje('Empleado con tipo de Pago Transferencia, debe ingresar el Número de Cuenta Contable.', 'exclamation')
				NEXT FIELD n44_cta_trabaj
			END IF
		END IF
		IF rm_scr[pos].n44_tipo_pago = 'T' THEN
			IF rm_n44[pos].n44_cta_trabaj IS NOT NULL THEN
				IF NOT validar_cuenta(rm_n44[pos].n44_cta_trabaj)
				THEN
					--NEXT FIELD n44_cta_trabaj
				END IF
			END IF
		END IF
END INPUT
LET int_flag = 0
CLOSE WINDOW w_rolf212_2
RETURN

END FUNCTION



FUNCTION validar_cuenta(aux_cont)
DEFINE aux_cont		LIKE ctbt010.b10_cuenta
DEFINE r_cta            RECORD LIKE ctbt010.*

CALL fl_lee_cuenta(vg_codcia, aux_cont) RETURNING r_cta.*
IF r_cta.b10_cuenta IS NULL THEN
	CALL fl_mostrar_mensaje('Cuenta no existe para esta compañía.','exclamation')
	RETURN 0
END IF
IF r_cta.b10_estado = 'B' THEN
	CALL fl_mensaje_estado_bloqueado()
	RETURN 0
END IF
IF r_cta.b10_nivel <> vm_nivel THEN
	CALL fl_mostrar_mensaje('Nivel de cuenta debe ser solo del último.', 'exclamation')
	RETURN 0
END IF
RETURN 1

END FUNCTION



FUNCTION control_contabilizacion()
DEFINE r_b12		RECORD LIKE ctbt012.*
DEFINE r_n53		RECORD LIKE rolt053.*
DEFINE resp		CHAR(6)

CALL mostrar_registro(vm_r_rows[vm_row_current])
CALL lee_rol_cont(vg_codcia, rm_par.n43_num_rol) RETURNING r_n53.*
IF YEAR(rm_par.n43_fecing) < 2010 AND r_n53.n53_compania IS NULL THEN
	CALL fl_mostrar_mensaje('Solo los roles de uso varios del año 2010 en adelante tienen la opción de contabilización.', 'exclamation')
	RETURN
END IF
IF r_n53.n53_compania IS NOT NULL THEN
	CALL ver_contabilizacion(r_n53.n53_tipo_comp, r_n53.n53_num_comp)
	RETURN
END IF
IF rm_par.n43_estado <> 'P' THEN
	CALL fl_mostrar_mensaje('Solo puede contabilizar un rol cuando esté Procesado.', 'exclamation')
	RETURN
END IF
LET int_flag = 0
CALL fl_hacer_pregunta('Desea generar Contabilización de este rol de uso varios ?', 'No')
	RETURNING resp
IF resp <> 'Yes' THEN
	RETURN
END IF
BEGIN WORK
	WHENEVER ERROR CONTINUE
	CALL generar_contabilizacion() RETURNING r_b12.*
	IF r_b12.b12_compania IS NULL THEN
		WHENEVER ERROR STOP
		ROLLBACK WORK
		RETURN
	END IF
	WHENEVER ERROR STOP
COMMIT WORK
IF r_b12.b12_compania IS NOT NULL AND rm_b00.b00_mayo_online = 'S' THEN
	CALL fl_mayoriza_comprobante(r_b12.b12_compania, r_b12.b12_tipo_comp,
					r_b12.b12_num_comp, 'M')
END IF
CALL fl_hacer_pregunta('Desea ver contabilización generada ?', 'Yes')
	RETURNING resp
IF resp = 'Yes' THEN
	CALL ver_contabilizacion(r_b12.b12_tipo_comp, r_b12.b12_num_comp)
END IF
CALL fl_mostrar_mensaje('Contabilización Generada Ok.', 'info')

END FUNCTION



FUNCTION generar_contabilizacion()
DEFINE r_b12		RECORD LIKE ctbt012.*
DEFINE r_g13		RECORD LIKE gent013.*
DEFINE r_g14		RECORD LIKE gent014.*
DEFINE r_n03		RECORD LIKE rolt003.*
DEFINE r_n30		RECORD LIKE rolt030.*
DEFINE r_n53		RECORD LIKE rolt053.*
DEFINE glosa_det	LIKE ctbt012.b12_glosa
DEFINE sec		LIKE ctbt013.b13_secuencia
DEFINE val_rol		LIKE rolt044.n44_valor
DEFINE aux_cont		LIKE ctbt010.b10_cuenta
DEFINE tip		LIKE rolt044.n44_tipo_pago
DEFINE query		CHAR(3000)
DEFINE campo		VARCHAR(20)
DEFINE valor_cuad	DECIMAL(14,2)
DEFINE tot_valor	DECIMAL(14,2)
DEFINE mensaje		VARCHAR(250)

IF NOT validacion_contable(TODAY) THEN
	RETURN r_b12.*
END IF
INITIALIZE r_b12.*, r_n53.* TO NULL
CALL fl_lee_proceso_roles(vm_proceso) RETURNING r_n03.*
LET r_b12.b12_compania 	  = vg_codcia
LET r_b12.b12_tipo_comp   = "DN"
LET r_b12.b12_num_comp    = fl_numera_comprobante_contable(vg_codcia,
				r_b12.b12_tipo_comp, YEAR(rm_par.n43_fecing),
				MONTH(rm_par.n43_fecing)) 
IF r_b12.b12_num_comp <= 0 THEN
	INITIALIZE r_b12.* TO NULL
	RETURN r_b12.*
END IF
LET r_b12.b12_estado 	  = 'A'
LET r_b12.b12_glosa       = 'ROL DE PAGO: ', vm_proceso, ' ',
				r_n03.n03_nombre CLIPPED, ' # ',
				rm_par.n43_num_rol USING "<<<&&&", ' ',
				DATE(rm_par.n43_fecing) USING "dd-mm-yyyy", ' ',
				rm_par.n43_titulo CLIPPED, '.'
LET r_b12.b12_origen      = 'A'
CALL fl_lee_moneda(rm_par.n43_moneda) RETURNING r_g13.*
IF r_g13.g13_moneda = rg_gen.g00_moneda_base THEN
	LET r_g14.g14_tasa = 1
ELSE
	CALL fl_lee_factor_moneda(r_g13.g13_moneda, rg_gen.g00_moneda_base)
		RETURNING r_g14.*
	IF r_g14.g14_serial IS NULL THEN
		CALL fl_mostrar_mensaje('La paridad para esta moneda no existe.', 'stop')
		INITIALIZE r_b12.* TO NULL
		RETURN r_b12.*
	END IF
END IF
LET r_b12.b12_moneda      = r_g13.g13_moneda
LET r_b12.b12_paridad     = r_g14.g14_tasa
LET r_b12.b12_fec_proceso = DATE(rm_par.n43_fecing)
LET r_b12.b12_modulo      = vg_modulo
LET r_b12.b12_usuario     = vg_usuario
LET r_b12.b12_fecing      = CURRENT
INSERT INTO ctbt012 VALUES (r_b12.*) 
LET campo = 'n56_aux_val_vac'
IF rm_par.n43_tributa = 'N' THEN
	LET campo = 'n56_aux_val_adi'
END IF
LET query = 'SELECT n30_nombres, ', campo CLIPPED,
		' aux_emp, n44_tipo_pago tipo, ',
		'CASE WHEN n44_tipo_pago = "E" ',
			'THEN n56_aux_banco ',
			'ELSE (SELECT g09_aux_cont ',
				'FROM gent009 ',
				'WHERE g09_compania   = n44_compania ',
				'  AND g09_banco      = n44_bco_empresa ',
				'  AND g09_numero_cta = n44_cta_empresa) ',
		'END cta_bco, ',
		'n03_nombre_abr || " # " || LPAD(n43_num_rol, 2, 0) || " " ||',
		' n30_nombres[1, 20] || " FECHA: " || "',
		DATE(rm_par.n43_fecing) USING "dd-mm-yyyy", '" glosa, ',
		'n44_valor valor ',
		'FROM rolt043, rolt044, rolt056, rolt003, rolt030 ',
		'WHERE n43_compania  = ', vg_codcia,
		'  AND n43_num_rol   = ', rm_par.n43_num_rol,
		'  AND n44_compania  = n43_compania ',
		'  AND n44_num_rol   = n43_num_rol ',
		'  AND n56_compania  = n44_compania ',
		'  AND n56_proceso   = "', vm_proceso, '"',
		'  AND n56_cod_depto = n44_cod_depto ',
		'  AND n56_cod_trab  = n44_cod_trab ',
		'  AND n56_estado    = "A" ',
		'  AND n03_proceso   = n56_proceso ',
		'  AND n30_compania  = n56_compania ',
		'  AND n30_cod_trab  = n56_cod_trab ',
		'INTO TEMP tmp_ctb '
PREPARE exec_ctb FROM query
EXECUTE exec_ctb
DECLARE q_ctb CURSOR FOR
	SELECT n30_nombres, aux_emp, glosa, valor
		FROM tmp_ctb
		ORDER BY n30_nombres
LET sec = 1
FOREACH q_ctb INTO r_n30.n30_nombres, aux_cont, glosa_det, val_rol
	CALL generar_detalle_contable(r_b12.*, aux_cont, val_rol, glosa_det,
					'D', sec)
	LET sec = sec + 1
END FOREACH
LET sec = sec - 1
IF sec = 0 THEN
	CALL fl_mostrar_mensaje('No se ha generado la contabilizacion debido a que no existen auxliares contables. POR FAVOR LLAME AL ADMINISTRADOR.', 'stop')
	DROP TABLE tmp_ctb
	INITIALIZE r_b12.* TO NULL
	RETURN r_b12.*
END IF
DECLARE q_ctb2 CURSOR FOR
	SELECT tipo, cta_bco, NVL(SUM(valor), 0) valor
		FROM tmp_ctb
		GROUP BY 1, 2
		ORDER BY 1, 2
FOREACH q_ctb2 INTO tip, aux_cont, val_rol
	LET sec = sec + 1
	CASE tip
		WHEN 'E' LET glosa_det = 'ROL DE PAGO: ', vm_proceso, ' ',
				r_n03.n03_nombre CLIPPED, ' # ',
				rm_par.n43_num_rol USING "<<<&&&", ' ',
				DATE(rm_par.n43_fecing) USING "dd-mm-yyyy",
				' PAGADO EN EFECTIVO'
		WHEN 'T' LET glosa_det = 'ROL DE PAGO: ', vm_proceso, ' ',
				r_n03.n03_nombre CLIPPED, ' # ',
				rm_par.n43_num_rol USING "<<<&&&", ' ',
				DATE(rm_par.n43_fecing) USING "dd-mm-yyyy",
				' TRANSFERIDO A CTA.'
	END CASE
	CALL generar_detalle_contable(r_b12.*, aux_cont, val_rol, glosa_det,
					'H', sec)
END FOREACH
SELECT NVL(SUM(b13_valor_base), 0)
	INTO valor_cuad
	FROM ctbt013
	WHERE b13_compania  = vg_codcia
	  AND b13_tipo_comp = r_b12.b12_tipo_comp
	  AND b13_num_comp  = r_b12.b12_num_comp
IF valor_cuad <> 0 THEN
	CALL fl_mostrar_mensaje('Se ha generado un error en la contabilizacion. POR FAVOR LLAME AL ADMINISTRADOR.', 'stop')
	DROP TABLE tmp_ctb
	INITIALIZE r_b12.* TO NULL
	RETURN r_b12.*
END IF
SELECT NVL(SUM(b13_valor_base), 0)
	INTO valor_cuad
	FROM ctbt013
	WHERE b13_compania    = vg_codcia
	  AND b13_tipo_comp   = r_b12.b12_tipo_comp
	  AND b13_num_comp    = r_b12.b12_num_comp
	  AND b13_valor_base >= 0
LET tot_valor = calcula_totales()
IF valor_cuad <> tot_valor THEN
	LET mensaje = 'El total contable es ', valor_cuad USING "###,##&.##",
			' y es diferente a', tot_valor USING "###,##&.##",
			' que es el total del rol de usos varios. ',
			'POR FAVOR LLAME AL ADMINISTRADOR.'
	CALL fl_mostrar_mensaje(mensaje, 'stop')
	DROP TABLE tmp_ctb
	INITIALIZE r_b12.* TO NULL
	RETURN r_b12.*
END IF
INITIALIZE r_n53.* TO NULL
LET r_n53.n53_compania   = vg_codcia
LET r_n53.n53_cod_liqrol = vm_proceso
LET r_n53.n53_fecha_ini  = DATE(rm_par.n43_fecing)
LET r_n53.n53_fecha_fin  = DATE(rm_par.n43_fecing)
LET r_n53.n53_tipo_comp  = r_b12.b12_tipo_comp
LET r_n53.n53_num_comp   = r_b12.b12_num_comp
INSERT INTO rolt053 VALUES(r_n53.*)
DROP TABLE tmp_ctb
RETURN r_b12.*

END FUNCTION



FUNCTION validacion_contable(fecha)
DEFINE fecha		DATE
DEFINE resp 		VARCHAR(6)

IF YEAR(fecha) < YEAR(rm_b00.b00_fecha_cm) OR
  (YEAR(fecha) = YEAR(rm_b00.b00_fecha_cm) AND
   MONTH(fecha) <= MONTH(rm_b00.b00_fecha_cm))
THEN
	CALL fl_mostrar_mensaje('El Mes en Contabilidad esta cerrado. Reapertúrelo para que se pueda generar la contabilización del Anticipo.', 'stop')
	RETURN 0
END IF
IF fecha_bloqueada(vg_codcia, MONTH(fecha), YEAR(fecha)) THEN
	CALL fl_mostrar_mensaje('No puede generar contabilización del Anticipo de un mes bloqueado en CONTABILIDAD.', 'stop')
	RETURN 0
END IF
RETURN 1

END FUNCTION



FUNCTION fecha_bloqueada(codcia, mes, ano)
DEFINE codcia 		LIKE ctbt006.b06_compania
DEFINE mes, ano		SMALLINT
DEFINE r_b06		RECORD LIKE ctbt006.*

INITIALIZE r_b06.* TO NULL 
SELECT * INTO r_b06.*
	FROM ctbt006
	WHERE b06_compania = codcia
	  AND b06_ano      = ano
	  AND b06_mes      = mes
IF r_b06.b06_mes IS NOT NULL THEN
	CALL fl_mostrar_mensaje('Mes contable esta bloqueado.','stop')
	RETURN 1
END IF
RETURN 0

END FUNCTION



FUNCTION generar_detalle_contable(r_b12, cuenta, valor, glosa, tipo, sec)
DEFINE r_b12		RECORD LIKE ctbt012.*
DEFINE cuenta		LIKE ctbt010.b10_cuenta
DEFINE valor		LIKE ctbt013.b13_valor_base
DEFINE glosa		LIKE ctbt012.b12_glosa
DEFINE tipo		CHAR(1)
DEFINE sec		LIKE ctbt013.b13_secuencia
DEFINE r_b13		RECORD LIKE ctbt013.*

INITIALIZE r_b13.* TO NULL
LET r_b13.b13_compania    = r_b12.b12_compania
LET r_b13.b13_tipo_comp   = r_b12.b12_tipo_comp
LET r_b13.b13_num_comp    = r_b12.b12_num_comp
LET r_b13.b13_secuencia   = sec
LET r_b13.b13_cuenta      = cuenta
LET r_b13.b13_glosa       = glosa CLIPPED
LET r_b13.b13_valor_base  = 0
LET r_b13.b13_valor_aux   = 0
CASE tipo
	WHEN 'D'
		LET r_b13.b13_valor_base = valor
	WHEN 'H'
		LET r_b13.b13_valor_base = valor * (-1)
END CASE
LET r_b13.b13_fec_proceso = r_b12.b12_fec_proceso
INSERT INTO ctbt013 VALUES (r_b13.*)

END FUNCTION



FUNCTION lee_rol_cont(codcia, num_rol)
DEFINE codcia		LIKE rolt053.n53_compania
DEFINE num_rol		LIKE rolt043.n43_num_rol
DEFINE r_n53		RECORD LIKE rolt053.*

INITIALIZE r_n53.* TO NULL
SELECT rolt053.* INTO r_n53.*
	FROM rolt043, rolt053
	WHERE n43_compania   = codcia
	  AND n43_num_rol    = num_rol
	  AND n53_compania   = n43_compania
	  AND n53_cod_liqrol = vm_proceso
	  AND n53_fecha_ini  = DATE(n43_fecing)
	  AND n53_fecha_fin  = DATE(n43_fecing)
RETURN r_n53.*

END FUNCTION



FUNCTION ver_contabilizacion(tipo_comp, num_comp)
DEFINE tipo_comp	LIKE ctbt012.b12_tipo_comp
DEFINE num_comp		LIKE ctbt012.b12_num_comp
DEFINE param		VARCHAR(60)

LET param = ' "', tipo_comp, '" "', num_comp, '"'
CALL fl_ejecuta_comando('CONTABILIDAD', 'CB', 'ctbp201 ', param, 0)

END FUNCTION



FUNCTION control_archivo()
DEFINE query 		CHAR(6000)
DEFINE archivo		VARCHAR(100)
DEFINE mensaje		VARCHAR(200)
DEFINE nom_mes		VARCHAR(10)
DEFINE r_g31		RECORD LIKE gent031.*

CREATE TEMP TABLE tmp_rol_ban
	(
		tipo_pago		CHAR(2),
		cuenta_empresa		CHAR(10),
		secuencia		SERIAL,
		comp_pago		CHAR(5),
		cod_trab		CHAR(6),
		moneda			CHAR(3),
		valor			VARCHAR(13),
		forma_pago		CHAR(3),
		codi_banco		CHAR(4),
		tipo_cuenta		CHAR(3),
		cuenta_empleado		CHAR(11),
		tipo_doc_id		CHAR(1),
		num_doc_id		VARCHAR(13,0),
		--num_doc_id		DECIMAL(13,0),
		empleado		VARCHAR(40),
		direccion		VARCHAR(40),
		ciudad			VARCHAR(20),
		telefono		VARCHAR(10),
		local_cobro		VARCHAR(10),
		referencia		VARCHAR(30),
		referencia_adic		VARCHAR(30)
	)

LET query = 'SELECT "PA" AS tip_pag, g09_numero_cta AS cuenta_empr,',
			' 0 AS secu, "" AS comp_p,n44_cod_trab AS cod_emp, ',
			'g13_simbolo AS mone,TRUNC(n44_valor * 100, 0) AS',
			' neto_rec, "CTA" AS for_pag, "0040" AS cod_ban,',
			' CASE WHEN n30_tipo_cta_tra = "A"',
				' THEN "AHO"',
				' ELSE "CTE"',
			' END AS tipo_c, n44_cta_trabaj AS cuenta_empl,',
			' n30_tipo_doc_id AS tipo_id,',
			' CASE WHEN n44_cod_trab = 24 AND ', vg_codloc, ' = 1 ',
				' THEN "0920503067"',
				' ELSE n30_num_doc_id',
			' END AS cedula,',
			' CASE WHEN n44_cod_trab = 24 AND ', vg_codloc, ' = 1 ',
				' THEN "CHILA RUA EMILIANO FRANCISCO"',
				' ELSE n30_nombres',
			' END AS empleados, n30_domicilio AS direc,',
			' g31_nombre AS ciudad_emp, n30_telef_domic AS fono,',
			' "" AS loc_cob, n03_nombre AS refer1,',
			' CASE',
				' WHEN MONTH(n43_fecing) = 01 THEN "ENERO"',
				' WHEN MONTH(n43_fecing) = 02 THEN "FEBRERO"',
				' WHEN MONTH(n43_fecing) = 03 THEN "MARZO"',
				' WHEN MONTH(n43_fecing) = 04 THEN "ABRIL"',
				' WHEN MONTH(n43_fecing) = 05 THEN "MAYO"',
				' WHEN MONTH(n43_fecing) = 06 THEN "JUNIO"',
				' WHEN MONTH(n43_fecing) = 07 THEN "JULIO"',
				' WHEN MONTH(n43_fecing) = 08 THEN "AGOSTO"',
				' WHEN MONTH(n43_fecing) = 09 THEN "SEPTIEMBRE"',
				' WHEN MONTH(n43_fecing) = 10 THEN "OCTUBRE"',
				' WHEN MONTH(n43_fecing) = 11 THEN "NOVIEMBRE"',
				' WHEN MONTH(n43_fecing) = 12 THEN "DICIEMBRE"',
			' END || "-" || LPAD(YEAR(n43_fecing), 4, 0) AS refer2',
		' FROM rolt043, rolt044, rolt030, gent009, gent013, gent031,',
			' rolt003 ',
		' WHERE n43_compania = ', vg_codcia,
		'   AND n43_num_rol  = ', rm_par.n43_num_rol,
		'   AND n43_estado   = "P"',
		'   AND n44_compania = n43_compania ',
		'   AND n44_num_rol  = n43_num_rol ',
		'   AND n44_valor    > 0 ',
  		'   AND n30_compania = n44_compania ',
		'   AND n30_cod_trab = n44_cod_trab ',
		'   AND g09_compania = n44_compania ',
		'   AND g09_banco    = n44_bco_empresa ',
		'   AND n03_proceso  = "', vm_proceso, '"',
		'   AND g13_moneda   = n43_moneda ',
		'   AND g31_ciudad   = n30_ciudad_nac ',
		' ORDER BY 14 ',
		' INTO TEMP t1 '
PREPARE exec_dat FROM query
EXECUTE exec_dat
LET query = 'INSERT INTO tmp_rol_ban ',
		'(tipo_pago, cuenta_empresa, secuencia, comp_pago, cod_trab,',
		' moneda, valor, forma_pago, codi_banco, tipo_cuenta,',
		' cuenta_empleado, tipo_doc_id, num_doc_id, empleado,',
		' direccion, ciudad, telefono, local_cobro, referencia,',
		' referencia_adic) ',
		' SELECT * FROM t1 '
PREPARE exec_tmp FROM query
EXECUTE exec_tmp
DROP TABLE t1
LET query = 'SELECT tipo_pago, cuenta_empresa, secuencia, comp_pago, cod_trab,',
		' "USD" moneda, LPAD(valor, 13, 0) valor, forma_pago,',
		' codi_banco, tipo_cuenta,',
		' LPAD(cuenta_empleado, 11, 0) cta_emp, tipo_doc_id,',
		' LPAD(num_doc_id, 13, 0) num_doc_id,',
		' REPLACE(empleado, "ñ", "N") empleado,',
		--' REPLACE(direccion, "ñ", "N") direccion,',
		--' ciudad, telefono, local_cobro, referencia, referencia_adic',
		' "" direccion, "" ciudad, "" telefono, "" local_cobro,',
		' "ROL DE PAGO" referencia, referencia_adic',
		' FROM tmp_rol_ban ',
		' INTO TEMP t1 '
PREPARE exec_t1 FROM query
EXECUTE exec_t1
DROP TABLE tmp_rol_ban
UNLOAD TO "../../../tmp/rol_pag.txt" DELIMITER "	"
	SELECT * FROM t1
		ORDER BY secuencia
{--
LET archivo = "rol_pag_", rm_par.n44_fecha_fin USING "mmm", "_",
		rm_par.n44_fecha_fin USING "yyyy", ".txt"
--}
--LET archivo = "acreditacion_quincena.txt"
LET nom_mes = UPSHIFT(fl_justifica_titulo('I',
			fl_retorna_nombre_mes(MONTH(rm_par.n43_fecing)), 11))
LET archivo = "ACRE_", rm_loc.g02_nombre[1, 3] CLIPPED, "_",
		vm_proceso, nom_mes[1, 3] CLIPPED,
		YEAR(rm_par.n43_fecing) USING "####", "_"
CALL fl_lee_ciudad(rm_loc.g02_ciudad) RETURNING r_g31.*
LET archivo = archivo CLIPPED, r_g31.g31_siglas CLIPPED, ".txt"
LET mensaje = 'Archivo ', archivo CLIPPED, ' Generado ', FGL_GETENV("HOME"),
		'/tmp/  OK'
LET archivo = "mv ../../../tmp/rol_pag.txt $HOME/tmp/", archivo CLIPPED
RUN archivo
DROP TABLE t1
CALL fl_mostrar_mensaje(mensaje, 'info')

END FUNCTION 
