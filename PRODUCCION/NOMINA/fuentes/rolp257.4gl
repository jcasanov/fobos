--------------------------------------------------------------------------------
-- Titulo           : rolp257.4gl - Generador Archivos IESS
-- Elaboracion      : 04-Mar-2009
-- Autor            : NPC
-- Formato Ejecucion: fglrun rolp257 base modulo compania localidad
-- Ultima Correccion: 
-- Motivo Correccion: 
--------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_num_rows	SMALLINT
DEFINE vm_row_current	SMALLINT
DEFINE vm_max_rows	SMALLINT
DEFINE vm_max_det	SMALLINT
DEFINE vm_num_det	SMALLINT
DEFINE vm_r_rows	ARRAY[6000] OF INTEGER
DEFINE rm_detalle	ARRAY[500] OF RECORD
				n27_cedula_trab	LIKE rolt027.n27_cedula_trab,
				n27_cod_trab	LIKE rolt027.n27_cod_trab,
				n30_nombres	LIKE rolt030.n30_nombres,
				n27_valor_ext	LIKE rolt027.n27_valor_ext,
				n27_valor_adi	LIKE rolt027.n27_valor_adi,
				n27_tipo_causa	LIKE rolt027.n27_tipo_causa
			END RECORD
DEFINE rm_aux_det	ARRAY[500] OF RECORD
				n27_estado	LIKE rolt027.n27_estado,
				n27_usua_elimin	LIKE rolt027.n27_usua_elimin,
				n27_fec_elimin	LIKE rolt027.n27_fec_elimin,
				n27_usua_modifi	LIKE rolt027.n27_usua_modifi,
				n27_fec_modifi	LIKE rolt027.n27_fec_modifi
			END RECORD
DEFINE rm_n26		RECORD LIKE rolt026.*
DEFINE total_valor_ext	DECIMAL(14,2)
DEFINE total_valor_adi	DECIMAL(14,2)
DEFINE vm_flag_mant	CHAR(1)



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/rolp257.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 THEN
	-- Validar # parametros correcto
	CALL fl_mostrar_mensaje('NÃºmero de parametros incorrecto.','stop')
	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_codloc  = arg_val(4)
LET vg_proceso = 'rolp257'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
--#CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()

END MAIN



FUNCTION funcion_master()
DEFINE lin_menu		SMALLINT
DEFINE row_ini  	SMALLINT
DEFINE num_rows 	SMALLINT
DEFINE num_cols 	SMALLINT

CALL fl_nivel_isolation()                                     
LET lin_menu = 0
LET row_ini  = 3
LET num_rows = 22
LET num_cols = 80
IF vg_gui = 0 THEN
	LET lin_menu = 1
	LET row_ini  = 4
	LET num_rows = 20
	LET num_cols = 78
END IF
OPEN WINDOW w_rolf257_1 AT row_ini, 2 WITH num_rows ROWS, num_cols COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE lin_menu,
		  MESSAGE LINE LAST, BORDER) 
IF vg_gui = 1 THEN
	OPEN FORM f_rolf257_1 FROM '../forms/rolf257_1'
ELSE
	OPEN FORM f_rolf257_1 FROM '../forms/rolf257_1c'
END IF
DISPLAY FORM f_rolf257_1
CALL mostrar_botones()
LET vm_max_rows	   = 6000
LET vm_max_det     = 500
LET vm_num_rows    = 0
LET vm_row_current = 0
LET vm_num_det     = 0
CALL muestra_contadores()
CALL muestra_contadores_det(0, vm_num_det)
MENU 'OPCIONES'                                                                 
	BEFORE MENU                                                             
		HIDE OPTION 'Avanzar'
		HIDE OPTION 'Retroceder'
		HIDE OPTION 'Modificar'
		HIDE OPTION 'Bajar Archivo'
		HIDE OPTION 'Cerrar Archivo'
		HIDE OPTION 'Eliminar Archivo'
		HIDE OPTION 'Detalle'
		HIDE OPTION 'Reabrir Archivo'
	COMMAND KEY('G') 'Generar' 'Genera el archivo de carga. '
		CALL control_generar()
		IF vm_num_rows = 1 THEN
			SHOW OPTION 'Modificar'
			IF rm_n26.n26_estado IS NOT NULL THEN
				IF rm_n26.n26_estado = 'E' THEN
					HIDE OPTION 'Eliminar Archivo'
					HIDE OPTION 'Bajar Archivo'
				ELSE
					SHOW OPTION 'Bajar Archivo'
					SHOW OPTION 'Eliminar Archivo'
				END IF
				IF rm_n26.n26_estado <> 'G' THEN
					HIDE OPTION 'Cerrar Archivo'
					HIDE OPTION 'Modificar'
				ELSE
					SHOW OPTION 'Cerrar Archivo'
					SHOW OPTION 'Modificar'
				END IF
			END IF
			SHOW OPTION 'Detalle'
		END IF
		IF rm_n26.n26_estado = 'C' THEN
			SHOW OPTION 'Reabrir Archivo'
		ELSE
			HIDE OPTION 'Reabrir Archivo'
		END IF
		IF vm_row_current > 1 THEN
			SHOW OPTION 'Retroceder'
		END IF
		IF vm_row_current = vm_num_rows THEN
			HIDE OPTION 'Avanzar'
		END IF
       	COMMAND KEY('M') 'Modificar' 'Modificar registro corriente. '
		CALL control_modificacion()
	COMMAND KEY('C') 'Consultar' 'Consultar un registro. '
		CALL control_consulta()
		IF vm_num_rows <= 1 THEN
			SHOW OPTION 'Modificar'
			SHOW OPTION 'Bajar Archivo'
			SHOW OPTION 'Detalle'
			IF rm_n26.n26_estado = 'C' THEN
				SHOW OPTION 'Reabrir Archivo'
			ELSE
				HIDE OPTION 'Reabrir Archivo'
			END IF
			IF rm_n26.n26_estado IS NOT NULL THEN
				IF rm_n26.n26_estado = 'E' THEN
					HIDE OPTION 'Eliminar Archivo'
					HIDE OPTION 'Bajar Archivo'
				ELSE
					IF rm_n26.n26_estado <> 'C' THEN
						SHOW OPTION 'Eliminar Archivo'
					END IF
					SHOW OPTION 'Bajar Archivo'
				END IF
				IF rm_n26.n26_estado <> 'G' THEN
					HIDE OPTION 'Cerrar Archivo'
					HIDE OPTION 'Modificar'
				ELSE
					SHOW OPTION 'Cerrar Archivo'
					SHOW OPTION 'Modificar'
				END IF
			END IF
			HIDE OPTION 'Avanzar'
			HIDE OPTION 'Retroceder'
			IF vm_num_rows = 0 THEN
				HIDE OPTION 'Modificar'
				HIDE OPTION 'Bajar Archivo'
				HIDE OPTION 'Eliminar Archivo'
				HIDE OPTION 'Bajar Archivo'
				HIDE OPTION 'Cerrar Archivo'
				HIDE OPTION 'Reabrir Archivo'
				HIDE OPTION 'Detalle'
			END IF
		ELSE
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Bajar Archivo'
			SHOW OPTION 'Modificar'
			IF rm_n26.n26_estado = 'C' THEN
				SHOW OPTION 'Reabrir Archivo'
			ELSE
				HIDE OPTION 'Reabrir Archivo'
			END IF
			IF rm_n26.n26_estado IS NOT NULL THEN
				IF rm_n26.n26_estado = 'E' THEN
					HIDE OPTION 'Eliminar Archivo'
					HIDE OPTION 'Bajar Archivo'
				ELSE
					IF rm_n26.n26_estado <> 'C' THEN
						SHOW OPTION 'Eliminar Archivo'
					END IF
					SHOW OPTION 'Bajar Archivo'
				END IF
				IF rm_n26.n26_estado <> 'G' THEN
					HIDE OPTION 'Cerrar Archivo'
					HIDE OPTION 'Modificar'
				ELSE
					SHOW OPTION 'Cerrar Archivo'
					SHOW OPTION 'Modificar'
				END IF
			END IF
			SHOW OPTION 'Detalle'
		END IF
		IF vm_row_current <= 1 THEN
                        HIDE OPTION 'Retroceder'
                END IF
       	COMMAND KEY('B') 'Bajar Archivo' 'Baja Archivo corriente. '
		CALL bajar_archivo()
       	COMMAND KEY('P') 'Cerrar Archivo' 'Cerrar Archivo registro corriente. '
		CALL control_cierre_reapertura('C')
		IF rm_n26.n26_estado <> 'G' THEN
			HIDE OPTION 'Eliminar Archivo'
			HIDE OPTION 'Cerrar Archivo'
			HIDE OPTION 'Modificar'
		ELSE
			SHOW OPTION 'Eliminar Archivo'
			SHOW OPTION 'Cerrar Archivo'
			SHOW OPTION 'Modificar'
		END IF
		IF rm_n26.n26_estado = 'C' THEN
			SHOW OPTION 'Reabrir Archivo'
		ELSE
			HIDE OPTION 'Reabrir Archivo'
		END IF
	COMMAND KEY('X') 'Reabrir Archivo' 'Reabrir el último archivo de carga cerrado.'
		CALL control_cierre_reapertura('R')
		IF rm_n26.n26_estado <> 'G' THEN
			HIDE OPTION 'Eliminar Archivo'
			HIDE OPTION 'Cerrar Archivo'
			HIDE OPTION 'Modificar'
		ELSE
			SHOW OPTION 'Eliminar Archivo'
			SHOW OPTION 'Cerrar Archivo'
			SHOW OPTION 'Modificar'
		END IF
		IF rm_n26.n26_estado = 'C' THEN
			SHOW OPTION 'Reabrir Archivo'
		ELSE
			HIDE OPTION 'Reabrir Archivo'
		END IF
       	COMMAND KEY('E') 'Eliminar Archivo' 'Eliminar Archivo corriente. '
		CALL control_eliminar()
		IF rm_n26.n26_estado = 'E' THEN
			HIDE OPTION 'Eliminar Archivo'
			HIDE OPTION 'Bajar Archivo'
			HIDE OPTION 'Cerrar Archivo'
			HIDE OPTION 'Modificar'
		ELSE
			SHOW OPTION 'Eliminar Archivo'
			SHOW OPTION 'Bajar Archivo'
			SHOW OPTION 'Cerrar Archivo'
			SHOW OPTION 'Modificar'
		END IF
		IF rm_n26.n26_estado <> 'G' THEN
			HIDE OPTION 'Eliminar Archivo'
			HIDE OPTION 'Cerrar Archivo'
			HIDE OPTION 'Modificar'
		ELSE
			SHOW OPTION 'Eliminar Archivo'
			SHOW OPTION 'Cerrar Archivo'
			SHOW OPTION 'Modificar'
		END IF
		IF rm_n26.n26_estado = 'C' THEN
			SHOW OPTION 'Reabrir Archivo'
		ELSE
			HIDE OPTION 'Reabrir Archivo'
		END IF
        COMMAND KEY('D') 'Detalle'   'Se ubica en el detalle.'
		IF vm_num_rows > 0 THEN
			CALL ubicarse_detalle()
		ELSE
			CALL fl_mensaje_consultar_primero()
		END IF	
	COMMAND KEY('A') 'Avanzar' 		'Ver siguiente registro.'
		CALL muestra_siguiente_registro()
		IF vm_row_current = vm_num_rows THEN
			HIDE OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
			NEXT OPTION 'Retroceder'
		ELSE
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
		END IF 
		IF rm_n26.n26_estado <> 'G' THEN
			HIDE OPTION 'Cerrar Archivo'
			HIDE OPTION 'Modificar'
		ELSE
			SHOW OPTION 'Cerrar Archivo'
			SHOW OPTION 'Modificar'
		END IF
		IF rm_n26.n26_estado = 'E' THEN
			HIDE OPTION 'Eliminar Archivo'
			HIDE OPTION 'Bajar Archivo'
		ELSE
			SHOW OPTION 'Eliminar Archivo'
			SHOW OPTION 'Bajar Archivo'
		END IF
		IF rm_n26.n26_estado = 'C' THEN
			SHOW OPTION 'Reabrir Archivo'
		ELSE
			HIDE OPTION 'Reabrir Archivo'
		END IF
	COMMAND KEY('R') 'Retroceder' 		'Ver anterior registro.'
		CALL muestra_anterior_registro()
		IF vm_row_current = 1 THEN
			HIDE OPTION 'Retroceder' 
			SHOW OPTION 'Avanzar'   
			NEXT OPTION 'Avanzar'  
		ELSE 
			SHOW OPTION 'Avanzar'  
			SHOW OPTION 'Retroceder'
		END IF
		IF rm_n26.n26_estado <> 'G' THEN
			HIDE OPTION 'Cerrar Archivo'
			HIDE OPTION 'Modificar'
		ELSE
			SHOW OPTION 'Cerrar Archivo'
			SHOW OPTION 'Modificar'
		END IF
		IF rm_n26.n26_estado = 'E' THEN
			HIDE OPTION 'Eliminar Archivo'
			HIDE OPTION 'Bajar Archivo'
		ELSE
			SHOW OPTION 'Eliminar Archivo'
			SHOW OPTION 'Bajar Archivo'
		END IF
		IF rm_n26.n26_estado = 'C' THEN
			SHOW OPTION 'Reabrir Archivo'
		ELSE
			HIDE OPTION 'Reabrir Archivo'
		END IF
	COMMAND KEY('S') 'Salir'    		'Salir del programa.'
		EXIT MENU
END MENU

END FUNCTION



FUNCTION control_generar()
DEFINE num_aux		INTEGER

CALL fl_retorna_usuario()
LET vm_flag_mant = 'I'
CALL borrar_pantalla()
CALL datos_defaults_cab()
IF NOT generacion_datos() THEN
	RETURN
END IF
CALL cargar_temporal()
CALL grabar_archivo() RETURNING num_aux
CALL bajar_archivo()
IF vm_num_rows = vm_max_rows THEN
	LET vm_num_rows = 1
ELSE
	LET vm_num_rows = vm_num_rows + 1
END IF
LET vm_row_current            = vm_num_rows
LET vm_r_rows[vm_row_current] = num_aux
CALL muestrar_reg()
DROP TABLE t1
DROP TABLE t2

END FUNCTION



FUNCTION control_modificacion()

CALL mostrar_registro(vm_r_rows[vm_row_current])
IF rm_n26.n26_estado <> 'G' THEN
	CALL fl_mostrar_mensaje('Solo puede modificar un archivo que este generado.', 'exclamation')
	RETURN
END IF
LET vm_flag_mant = 'M'
BEGIN WORK
WHENEVER ERROR CONTINUE
DECLARE q_up CURSOR FOR
	SELECT * FROM rolt026
		WHERE ROWID = vm_r_rows[vm_row_current]
	FOR UPDATE
OPEN q_up
FETCH q_up INTO rm_n26.*
IF STATUS = NOTFOUND THEN
	ROLLBACK WORK
	CALL fl_mostrar_mensaje('Este registro no existe. Ha ocurrido un error interno de la base de datos.', 'exclamation')
	WHENEVER ERROR STOP
	RETURN
END IF
IF STATUS < 0 THEN
	ROLLBACK WORK
	CALL fl_mensaje_bloqueo_otro_usuario()
	WHENEVER ERROR STOP
	RETURN
END IF
IF NOT generacion_datos() THEN
	ROLLBACK WORK
	WHENEVER ERROR STOP
	RETURN
END IF
WHENEVER ERROR CONTINUE
UPDATE rolt026 SET * = rm_n26.* WHERE CURRENT OF q_up
IF STATUS < 0 THEN
	ROLLBACK WORK
	WHENEVER ERROR STOP
	CALL fl_mostrar_mensaje('Ha ocurrido un error interno de la base de datos al intentar actualizar el registro. Consulte con el Administrador.', 'exclamation')
	RETURN
END IF
CALL grabar_detalle_archivo()
WHENEVER ERROR STOP
COMMIT WORK
CALL muestrar_reg()
DROP TABLE t1
DROP TABLE t2
CALL fl_mensaje_registro_modificado()

END FUNCTION



FUNCTION generacion_datos()
DEFINE flag		SMALLINT

CALL leer_cabecera()
IF int_flag THEN
	CALL mostrar_salir(0)
	RETURN 0
END IF
IF vm_flag_mant = 'I' THEN
	IF NOT generar_temporal() THEN
		CALL mostrar_salir(0)
		RETURN 0
	END IF
ELSE
	IF NOT genera_tabla_temp_si_existe_rolt026() THEN
		CALL mostrar_salir(1)
		RETURN 0
	END IF
END IF
LET flag = 1
IF vm_flag_mant <> 'I' THEN
	LET flag = 2
END IF
CALL cargar_detalle(flag)
IF vm_num_det = 0 THEN
	CALL fl_mostrar_mensaje('No existe valores extras para este periodo de carga.', 'info')
	LET vm_num_det = 1
END IF
CALL leer_detalle()
IF int_flag THEN
	CALL mostrar_salir(1)
	RETURN 0
END IF
RETURN 1

END FUNCTION



FUNCTION control_consulta()
DEFINE r_n22		RECORD LIKE rolt022.*
DEFINE query		CHAR(1800)
DEFINE expr_sql		CHAR(1200)
DEFINE num_reg		INTEGER

CLEAR FORM
CALL mostrar_botones()
LET int_flag = 0 
CONSTRUCT BY NAME expr_sql ON n26_codigo_arch, n26_nombre_arch, n26_ano_proceso,
	n26_mes_proceso, n26_estado, n26_ruc_patronal, n26_sucursal,
	n26_ano_carga, n26_mes_carga, n26_usuario, n26_fecing, n26_usua_cierre,
	n26_fec_cierre
	ON KEY(F2)
		IF INFIELD(n26_codigo_arch) THEN
			CALL fl_ayuda_tipo_arch_iess(vg_codcia)
				RETURNING r_n22.n22_codigo_arch,
						r_n22.n22_tipo_arch
                        IF r_n22.n22_codigo_arch IS NOT NULL THEN
				LET rm_n26.n26_codigo_arch =
							r_n22.n22_codigo_arch
				LET rm_n26.n26_tipo_arch   = r_n22.n22_tipo_arch
				CALL fl_lee_tipo_arch_iess(vg_codcia,
							rm_n26.n26_codigo_arch,
							rm_n26.n26_tipo_arch)
					RETURNING r_n22.*
				LET rm_n26.n26_nombre_arch =
							r_n22.n22_nombre_arch
				DISPLAY BY NAME rm_n26.n26_codigo_arch,
						r_n22.n22_descripcion,
						rm_n26.n26_tipo_arch,
						rm_n26.n26_nombre_arch
			END IF
		END IF
		LET int_flag = 0
	BEFORE CONSTRUCT
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
	AFTER FIELD n26_estado
		LET rm_n26.n26_estado = GET_FLDBUF(n26_estado)
		IF rm_n26.n26_estado IS NOT NULL THEN
			CALL muestra_estado()
		ELSE
			CLEAR n26_estado, tit_estado
		END IF
END CONSTRUCT
IF int_flag THEN
	CALL mostrar_salir(0)
	RETURN
END IF
LET query = 'SELECT *, ROWID FROM rolt026 ',
		' WHERE n26_compania = ', vg_codcia,
		'   AND ', expr_sql CLIPPED,
		' ORDER BY 2 DESC, 3 DESC ' CLIPPED
PREPARE cons FROM query	
DECLARE q_cons CURSOR FOR cons
LET vm_num_rows = 0
FOREACH q_cons INTO rm_n26.*, num_reg
	LET vm_num_rows = vm_num_rows + 1
        IF vm_num_rows > vm_max_rows THEN
		LET vm_num_rows = vm_num_rows - 1
                EXIT FOREACH
        END IF
	LET vm_r_rows[vm_num_rows] = num_reg
END FOREACH
IF vm_num_rows = 0 THEN
	LET int_flag = 0
	CALL fl_mensaje_consulta_sin_registros()
	CLEAR FORM
	LET vm_row_current = 0
	LET vm_num_det     = 0
	CALL mostrar_botones()
	CALL muestra_contadores()
	CALL muestra_contadores_det(0, vm_num_det)
	RETURN
END IF
LET vm_row_current = 1
CALL muestrar_reg()

END FUNCTION



FUNCTION control_cierre_reapertura(flag)
DEFINE flag		CHAR(1)
DEFINE mensaje		VARCHAR(200)
DEFINE resp		CHAR(6)
DEFINE fec_ult		DATETIME YEAR TO MONTH
DEFINE fec_car		DATETIME YEAR TO MONTH

CALL mostrar_registro(vm_r_rows[vm_row_current])
IF rm_n26.n26_estado <> 'G' AND flag = 'C' THEN
	CALL fl_mostrar_mensaje('Solo puede cerrar un archivo que esté generado.', 'exclamation')
	RETURN
END IF
IF rm_n26.n26_estado <> 'C' AND flag = 'R' THEN
	CALL fl_mostrar_mensaje('Solo puede reabrir un archivo que esté cerrado.', 'exclamation')
	RETURN
END IF
IF flag = 'R' THEN
	INITIALIZE fec_ult, fec_car TO NULL
	SQL
		SELECT EXTEND(NVL(MAX(MDY(n26_mes_proceso, 01,n26_ano_proceso)),
				TODAY), YEAR TO MONTH),
			EXTEND(NVL(MAX(MDY(n26_mes_carga, 01, n26_ano_carga)),
				TODAY), YEAR TO MONTH)
			INTO $fec_ult, $fec_car
			FROM rolt026
			WHERE n26_compania = $vg_codcia
			  AND n26_estado   = 'C'
	END SQL
	IF fec_ult <> EXTEND(MDY(rm_n26.n26_mes_proceso, 01,
				rm_n26.n26_ano_proceso),
				YEAR TO MONTH) AND
	   fec_car <> EXTEND(MDY(rm_n26.n26_mes_carga, 01,
				rm_n26.n26_ano_carga),
				YEAR TO MONTH)
	THEN
		CALL fl_mostrar_mensaje('Solo puede reabrir el último archivo que esté cerrado.', 'exclamation')
		RETURN
	END IF
END IF
BEGIN WORK
WHENEVER ERROR CONTINUE
DECLARE q_cierre CURSOR FOR
	SELECT * FROM rolt026
		WHERE ROWID = vm_r_rows[vm_row_current]
	FOR UPDATE
OPEN q_cierre
FETCH q_cierre INTO rm_n26.*
IF STATUS = NOTFOUND THEN
	ROLLBACK WORK
	CALL fl_mostrar_mensaje('Este registro no existe. Ha ocurrido un error interno de la base de datos.', 'exclamation')
	WHENEVER ERROR STOP
	RETURN
END IF
IF STATUS < 0 THEN
	ROLLBACK WORK
	CALL fl_mensaje_bloqueo_otro_usuario()
	WHENEVER ERROR STOP
	RETURN
END IF
WHENEVER ERROR STOP
CASE flag
	WHEN 'C' LET mensaje = 'Esta seguro que desea cerrar este archivo ?'
	WHEN 'R' LET mensaje = 'Esta seguro que desea reabrir este archivo ?'
END CASE
LET int_flag = 0
CALL fl_hacer_pregunta(mensaje, 'Yes') RETURNING resp
IF resp <> 'Yes' THEN
	ROLLBACK WORK
	RETURN
END IF
CASE flag
	WHEN 'C' LET rm_n26.n26_estado = 'C'
	WHEN 'R' LET rm_n26.n26_estado = 'G'
END CASE
WHENEVER ERROR CONTINUE
CASE flag
	WHEN 'C'
		UPDATE rolt026
			SET n26_estado      = rm_n26.n26_estado,
			    n26_usua_cierre = vg_usuario,
			    n26_fec_cierre  = CURRENT
			WHERE CURRENT OF q_cierre
	WHEN 'R'
		UPDATE rolt026
			SET n26_estado      = rm_n26.n26_estado,
			    n26_usua_cierre = NULL,
			    n26_fec_cierre  = NULL
			WHERE CURRENT OF q_cierre
END CASE
IF STATUS < 0 THEN
	ROLLBACK WORK
	WHENEVER ERROR STOP
	CALL fl_mostrar_mensaje('Ha ocurrido un error interno de la base de datos al intentar actualizar el registro. Consulte con el Administrador.', 'exclamation')
	RETURN
END IF
WHENEVER ERROR STOP
COMMIT WORK
CALL muestrar_reg()
CASE flag
	WHEN 'C' LET mensaje = 'El archivo ha sido cerrado.'
	WHEN 'R' LET mensaje = 'El archivo ha sido reabierto.'
END CASE
CALL fl_mostrar_mensaje(mensaje, 'info')

END FUNCTION



FUNCTION control_eliminar()
DEFINE resp		CHAR(6)

CALL mostrar_registro(vm_r_rows[vm_row_current])
IF rm_n26.n26_estado <> 'G' THEN
	CALL fl_mostrar_mensaje('Solo puede eliminar un archivo que este generado.', 'exclamation')
	RETURN
END IF
BEGIN WORK
WHENEVER ERROR CONTINUE
DECLARE q_elimin CURSOR FOR
	SELECT * FROM rolt026
		WHERE ROWID = vm_r_rows[vm_row_current]
	FOR UPDATE
OPEN q_elimin
FETCH q_elimin INTO rm_n26.*
IF STATUS = NOTFOUND THEN
	ROLLBACK WORK
	CALL fl_mostrar_mensaje('Este registro no existe. Ha ocurrido un error interno de la base de datos.', 'exclamation')
	WHENEVER ERROR STOP
	RETURN
END IF
IF STATUS < 0 THEN
	ROLLBACK WORK
	CALL fl_mensaje_bloqueo_otro_usuario()
	WHENEVER ERROR STOP
	RETURN
END IF
WHENEVER ERROR STOP
LET int_flag = 0
CALL fl_hacer_pregunta('Esta seguro que desea eliminar este archivo ?', 'Yes')
	RETURNING resp
IF resp <> 'Yes' THEN
	ROLLBACK WORK
	RETURN
END IF
LET rm_n26.n26_estado = 'E'
WHENEVER ERROR CONTINUE
UPDATE rolt026
	SET n26_estado      = rm_n26.n26_estado,
	    n26_usua_elimin = vg_usuario,
	    n26_fec_elimin  = CURRENT
	WHERE CURRENT OF q_elimin
IF STATUS < 0 THEN
	ROLLBACK WORK
	WHENEVER ERROR STOP
	CALL fl_mostrar_mensaje('Ha ocurrido un error interno de la base de datos al intentar actualizar el registro (rolt026). Consulte con el Administrador.', 'exclamation')
	RETURN
END IF
UPDATE rolt027
	SET n27_estado      = rm_n26.n26_estado,
	    n27_usua_elimin = vg_usuario,
	    n27_fec_elimin  = CURRENT
	WHERE n27_compania    = rm_n26.n26_compania
	  AND n27_ano_proceso = rm_n26.n26_ano_proceso
	  AND n27_mes_proceso = rm_n26.n26_mes_proceso
	  AND n27_codigo_arch = rm_n26.n26_codigo_arch
	  AND n27_tipo_arch   = rm_n26.n26_tipo_arch
	  AND n27_secuencia   = rm_n26.n26_secuencia
	  AND n27_estado     <> 'E'
IF STATUS < 0 THEN
	ROLLBACK WORK
	WHENEVER ERROR STOP
	CALL fl_mostrar_mensaje('Ha ocurrido un error interno de la base de datos al intentar actualizar el registro (rolt027). Consulte con el Administrador.', 'exclamation')
	RETURN
END IF
WHENEVER ERROR STOP
COMMIT WORK
CALL muestrar_reg()
CALL fl_mostrar_mensaje('El archivo ha sido eliminado.', 'info')

END FUNCTION



FUNCTION generar_temporal()
DEFINE fecha_ini	DATE
DEFINE fecha_fin	DATE
DEFINE query		CHAR(5000)
{--
DEFINE cuantos		INTEGER
DEFINE fec_nov		DATE
DEFINE nombre		LIKE rolt030.n30_nombres
DEFINE num_doc_id	LIKE rolt030.n30_num_doc_id
DEFINE sueldo		LIKE rolt030.n30_sueldo_mes
DEFINE valor_ext	LIKE rolt032.n32_tot_gan
DEFINE r_n32		RECORD LIKE rolt032.*
--}

IF genera_tabla_temp_si_existe_rolt026() THEN
	RETURN 1
END IF
ERROR 'Generando Archivo extras.txt, por favor espere ...'
LET fecha_ini = MDY(rm_n26.n26_mes_proceso, 01, rm_n26.n26_ano_proceso)
LET fecha_fin = fecha_ini + 1 UNITS MONTH - 1 UNITS DAY
{--
SELECT UNIQUE n32_cod_liqrol
	FROM rolt032
	WHERE n32_compania   = vg_codcia
	  AND n32_fecha_ini >= fecha_ini
	  AND n32_fecha_fin <= fecha_fin
	INTO TEMP caca
SELECT COUNT(*) INTO cuantos FROM caca
DROP TABLE caca
IF cuantos < 2 THEN
	CALL fl_mostrar_mensaje('Este mes no tiene aun las 2 quincenas ingresadas.', 'exclamation')
	RETURN 0
END IF
SELECT n33_cod_trab, n30_num_doc_id cedula, n30_nombres,
	NVL(SUM(n33_valor), 0) valor
	FROM rolt033, rolt030
	WHERE n33_compania    = vg_codcia
	  AND n33_cod_liqrol IN ('Q1', 'Q2')
	  AND n33_fecha_ini  >= fecha_ini
	  AND n33_fecha_fin  <= fecha_fin
	  AND n33_cod_rubro  IN
		(SELECT b.n08_rubro_base
			FROM rolt006 a, rolt008 b
				WHERE a.n06_estado     = 'A'
				  AND a.n06_flag_ident = 'AP'
				  AND b.n08_cod_rubro  = a.n06_cod_rubro
				  AND b.n08_rubro_base NOT IN
					(SELECT c.n06_cod_rubro
					FROM rolt006 c
					WHERE c.n06_flag_ident IN
					('VT', 'VV', 'VE', 'VM', 'OV', 'SX')))
	  AND n30_compania    = n33_compania
	  AND n30_cod_trab    = n33_cod_trab
	  AND n30_estado     <> 'J'
	GROUP BY 1, 2, 3
	HAVING NVL(SUM(n33_valor), 0) > 0
	INTO TEMP t1
DECLARE q_n32 CURSOR FOR
	SELECT n32_cod_trab, NVL(SUM(n32_tot_gan), 0)
		FROM rolt032
		WHERE n32_compania    = vg_codcia
		  AND n32_cod_liqrol IN ('Q1', 'Q2')
		  AND n32_fecha_ini  >= fecha_ini
		  AND n32_fecha_fin  <= fecha_fin
		GROUP BY 1
FOREACH q_n32 INTO r_n32.n32_cod_trab, r_n32.n32_tot_gan
	LET query = 'SELECT n30_nombres, n30_num_doc_id, ',
			-- OJO AGILITAR ESTE SUBQUERY
			'NVL((SELECT SUM(n33_valor) ',
			'FROM rolt033 ',
			'WHERE n33_compania   = ', vg_codcia,
			'  AND EXTEND(n33_fecha_fin, YEAR TO MONTH) = ',
				'EXTEND(MDY(', rm_n26.n26_mes_carga, ', 01, ',
						rm_n26.n26_ano_carga, '), ',
					' YEAR TO MONTH) ',
			'  AND n33_cod_trab   = n30_cod_trab',
			'  AND n33_cod_rubro IN ',
				'(SELECT n06_cod_rubro ',
					'FROM rolt006 ',
					'WHERE n06_flag_ident = "VT") ',
			'  AND n33_valor      > 0), 0) AS n30_sueldo_mes, ',
			--
		' NVL(CASE WHEN n30_fecha_reing IS NOT NULL ',
		'THEN CASE WHEN EXTEND(n30_fecha_reing, YEAR TO MONTH) = ',
			'EXTEND(MDY(', rm_n26.n26_mes_carga, ', 01, ',
					rm_n26.n26_ano_carga, '),',
				' YEAR TO MONTH) ',
			'THEN n30_fecha_reing ',
			'END ',
		'END, ',
		'NVL(CASE WHEN n30_fecha_ing IS NOT NULL ',
		'THEN CASE WHEN EXTEND(n30_fecha_ing, YEAR TO MONTH) = ',
			'EXTEND(MDY(', rm_n26.n26_mes_carga, ', 01, ',
					rm_n26.n26_ano_carga, '), ',
				'YEAR TO MONTH) ',
			'THEN n30_fecha_ing ',
			'END ',
		'END, ',
		'CASE WHEN n30_fecha_sal IS NOT NULL ',
		'THEN CASE WHEN EXTEND(n30_fecha_sal, YEAR TO MONTH) = ',
			'EXTEND(MDY(', rm_n26.n26_mes_carga, ', 01, ',
					rm_n26.n26_ano_carga, '), ',
				'YEAR TO MONTH) ',
			'THEN n30_fecha_sal ',
			'END ',
		'END ',
		')) AS fecha_nov ',
		' FROM rolt030 ',
		' WHERE n30_compania  = ', vg_codcia,
		'   AND n30_cod_trab  = ', r_n32.n32_cod_trab,
		'   AND n30_estado   <> "J" ',
		' INTO TEMP t4 '
	PREPARE exec_t4 FROM query
	EXECUTE exec_t4
	SELECT * INTO nombre, num_doc_id, sueldo, fec_nov FROM t4
	DROP TABLE t4
	IF fec_nov IS NOT NULL THEN
		CALL retorna_sueldo_parc(r_n32.n32_cod_trab) RETURNING sueldo
	END IF
	LET valor_ext = r_n32.n32_tot_gan - sueldo
	IF valor_ext > 0 THEN
		SELECT UNIQUE n33_cod_trab FROM t1
			WHERE n33_cod_trab = r_n32.n32_cod_trab
		IF STATUS = NOTFOUND THEN
			INSERT INTO t1
				VALUES(r_n32.n32_cod_trab, num_doc_id, nombre,
					valor_ext)
			ERROR 'Ins. en T1 Emp. ',
				r_n32.n32_cod_trab USING "<<<&&&",
				' VALOR_EXT = ', valor_ext USING "--,--&.##",
				' TOT_GAN = ', r_n32.n32_tot_gan
				USING "##,##&.##", ' SUELDO = ',
				sueldo using "##,##&.##"
			CONTINUE FOREACH
		END IF
		UPDATE t1 SET valor = valor_ext
			WHERE n33_cod_trab = r_n32.n32_cod_trab
		ERROR 'Act. en T1 Emp. ', r_n32.n32_cod_trab USING "<<<&&&",
			' VALOR_EXT = ', valor_ext USING "--,--&.##",
			' TOT_GAN = ', r_n32.n32_tot_gan USING "##,##&.##",
			' SUELDO = ', sueldo using "##,##&.##"
	ELSE
		ERROR 'Eli. en T1 Emp. ',
			r_n32.n32_cod_trab USING "<<<&&&",
			' VALOR_EXT = ', valor_ext USING "--,--&.##",
			' TOT_GAN = ', r_n32.n32_tot_gan USING "##,##&.##",
			' SUELDO = ', sueldo using "##,##&.##"
		DELETE FROM t1 WHERE n33_cod_trab = r_n32.n32_cod_trab
	END IF
END FOREACH
LET query = 'SELECT "', rm_n26.n26_ruc_patronal, '" ruc, "',
		rm_n26.n26_sucursal, '" sucursal, ', rm_n26.n26_ano_carga,
		' anio, LPAD(', rm_n26.n26_mes_carga, ', 2, 0) mes, "',
		rm_n26.n26_tipo_arch, '" tipo, cedula, LPAD(valor, 14, 0) ',
		'valor_ext, ',
		'(SELECT n23_tipo_causa ',
			'FROM rolt023 ',
			'WHERE n23_compania    = g02_compania ',
			'  AND n23_codigo_arch = ', rm_n26.n26_codigo_arch,
			'  AND n23_tipo_arch   = "', rm_n26.n26_tipo_arch, '"',
			'  AND n23_flag_ident  = "AP") causa ',
		' FROM t1, gent002 ',
		' WHERE g02_compania  = ', vg_codcia,
		'   AND g02_localidad = ', vg_codloc,
		' INTO TEMP t2'
--}
SELECT * FROM rolt033
	WHERE n33_compania    = vg_codcia
	  AND n33_cod_liqrol IN ("Q1", "Q2")
	  AND n33_fecha_ini  >= fecha_ini
	  AND n33_fecha_fin  <= fecha_fin
	  AND n33_det_tot     = "DI"
	  AND n33_cant_valor  = "V"
	  AND n33_valor       > 0
	INTO TEMP tmp_n33
LET query = 'SELECT "', rm_n26.n26_ruc_patronal, '" ruc, "',
		rm_n26.n26_sucursal, '" sucursal, ', rm_n26.n26_ano_proceso,
		' anio, LPAD(', rm_n26.n26_mes_proceso, ', 2, 0) mes, "',
		rm_n26.n26_tipo_arch, '" tipo, ',
		'CASE WHEN n30_cod_trab = 170 AND ', vg_codloc, ' = 1 ',
			'THEN n30_carnet_seg ',
			'ELSE n30_num_doc_id ',
		'END cedula, ',
		'(SUM(NVL((SELECT SUM(n33_valor) ',
			'FROM tmp_n33 ',
		  	'WHERE n33_compania    = a.n32_compania ',
			'  AND n33_cod_liqrol  = a.n32_cod_liqrol ',
			'  AND n33_fecha_ini   = a.n32_fecha_ini ',
			'  AND n33_fecha_fin   = a.n32_fecha_fin ',
			'  AND n33_cod_trab    = a.n32_cod_trab ',
			'  AND n33_cod_rubro  IN ',
				'(SELECT n08_rubro_base ',
				'FROM rolt008 ',
				'WHERE n08_cod_rubro = ',
					'(SELECT n06_cod_rubro ',
					'FROM rolt006 ',
					'WHERE n06_flag_ident = "AP"))), 0)) ',
		'- ',
		'CASE WHEN NVL(SUM((SELECT SUM(n33_valor) ',
			'FROM tmp_n33 ',
			'WHERE n33_compania   = a.n32_compania ',
			'  AND n33_fecha_ini  = a.n32_fecha_ini ',
			'  AND n33_fecha_fin  = a.n32_fecha_fin ',
			'  AND n33_cod_trab   = a.n32_cod_trab ',
			'  AND n33_cod_rubro  IN ',
				'(SELECT n06_cod_rubro ',
				'FROM rolt006 ',
				'WHERE n06_flag_ident IN ("VT", "VV", "OV", ',
						'"VE", "SX")))), 0) >= ',
			'NVL(SUM(a.n32_sueldo / ',
			'(SELECT COUNT(*) ',
				'FROM rolt032 b ',
				'WHERE b.n32_compania    = a.n32_compania ',
				'  AND b.n32_ano_proceso = a.n32_ano_proceso ',
				'  AND b.n32_mes_proceso = a.n32_mes_proceso ',
				'  AND b.n32_cod_trab    = a.n32_cod_trab)),0)',
		' THEN ',
			'NVL(SUM(a.n32_sueldo / ',
			'(SELECT COUNT(*) ',
				'FROM rolt032 b ',
				'WHERE b.n32_compania    = a.n32_compania ',
				'  AND b.n32_ano_proceso = a.n32_ano_proceso ',
				'  AND b.n32_mes_proceso = a.n32_mes_proceso ',
				'  AND b.n32_cod_trab    = a.n32_cod_trab)), ',
			'0)',
		' ELSE ',
			'NVL(SUM((SELECT SUM(n33_valor) ',
				'FROM tmp_n33 ',
				'WHERE n33_compania   = a.n32_compania ',
				'  AND n33_fecha_ini  = a.n32_fecha_ini ',
				'  AND n33_fecha_fin  = a.n32_fecha_fin ',
				'  AND n33_cod_trab   = a.n32_cod_trab ',
				'  AND n33_cod_rubro  IN ',
					'(SELECT n06_cod_rubro ',
					'FROM rolt006 ',
					'WHERE n06_flag_ident IN ("VT", "VV", ',
						'"OV", "VE", "SX")))), 0) ',
		' END) AS valor_ext, ',
		'(SELECT n23_tipo_causa ',
			'FROM rolt023 ',
			'WHERE n23_compania    = g02_compania ',
			'  AND n23_codigo_arch = ', rm_n26.n26_codigo_arch,
			'  AND n23_tipo_arch   = "', rm_n26.n26_tipo_arch, '"',
			'  AND n23_flag_ident  = "AP") causa, ',
		'n30_cod_trab, n30_nombres ',
		' FROM rolt032 a, rolt030, gent002 ',
		' WHERE a.n32_compania    = ', vg_codcia,
		'   AND a.n32_cod_liqrol IN ("Q1", "Q2") ',
		'   AND a.n32_fecha_ini  >= "', fecha_ini, '"',
		'   AND a.n32_fecha_fin  <= "', fecha_fin, '"',
		'   AND a.n32_estado     <> "E" ',
		'   AND n30_compania      = a.n32_compania ',
		'   AND n30_cod_trab      = a.n32_cod_trab ',
		'   AND g02_compania      = n30_compania ',
		'   AND g02_localidad     = ', vg_codloc,
		' GROUP BY 1, 2, 3, 4, 5, 6, 8, 9, 10 ',
		' INTO TEMP t1'
PREPARE cons_t1 FROM query
EXECUTE cons_t1
DROP TABLE tmp_n33
DELETE FROM t1 WHERE valor_ext <= 0
SELECT ruc, sucursal, anio, mes, tipo, cedula, valor_ext, causa
	FROM t1
	INTO TEMP t2
SELECT n30_cod_trab n33_cod_trab, cedula, n30_nombres, valor_ext valor
	FROM t1
	INTO TEMP t3
DROP TABLE t1
SELECT * FROM t3 INTO TEMP t1
DROP TABLE t3
ERROR '                                                                        '
RETURN 1

END FUNCTION



FUNCTION retorna_sueldo_parc(cod_trab)
DEFINE cod_trab		LIKE rolt032.n32_cod_trab
DEFINE sueldo_parc	LIKE rolt030.n30_sueldo_mes

SELECT NVL(SUM(n33_valor), 0)
	INTO sueldo_parc
	FROM rolt032, rolt033
	WHERE n32_compania     = vg_codcia
	  AND n32_cod_liqrol  IN ("Q1", "Q2")
	  AND n32_ano_proceso  = rm_n26.n26_ano_carga
	  AND n32_mes_proceso  = rm_n26.n26_mes_carga
	  AND n32_cod_trab     = cod_trab
	  AND n32_estado      <> "E"
	  AND n33_compania     = n32_compania
	  AND n33_cod_liqrol   = n32_cod_liqrol
	  AND n33_fecha_ini    = n32_fecha_ini
	  AND n33_fecha_fin    = n32_fecha_fin
	  AND n33_cod_trab     = n32_cod_trab
	  AND n33_cod_rubro   IN (SELECT n08_rubro_base
				FROM rolt008
				WHERE n08_cod_rubro  =
					(SELECT n06_cod_rubro
					FROM rolt006
					WHERE n06_flag_ident = "AP")
				  AND n08_rubro_base IN
					(SELECT n06_cod_rubro
					FROM rolt006
					WHERE n06_flag_ident IN ("VT", "VE",
							"VM", "VV", "SX")))
	  AND n33_valor       > 0
RETURN sueldo_parc

END FUNCTION



FUNCTION genera_tabla_temp_si_existe_rolt026()
DEFINE r_n26		RECORD LIKE rolt026.*

INITIALIZE r_n26.* TO NULL
SELECT a.* INTO r_n26.*
	FROM rolt026 a
	WHERE a.n26_compania    = vg_codcia
	  AND a.n26_codigo_arch = rm_n26.n26_codigo_arch
	  AND a.n26_tipo_arch   = rm_n26.n26_tipo_arch
	  AND a.n26_secuencia   =
		(SELECT NVL(MAX(b.n26_secuencia), 0)
			FROM rolt026 b
			WHERE b.n26_compania    = a.n26_compania
			  AND b.n26_ano_proceso = a.n26_ano_proceso
			  AND b.n26_mes_proceso = a.n26_mes_proceso
			  AND b.n26_codigo_arch = a.n26_codigo_arch
			  AND b.n26_tipo_arch   = a.n26_tipo_arch)
	  AND a.n26_ano_carga   = rm_n26.n26_ano_carga
	  AND a.n26_mes_carga   = rm_n26.n26_mes_carga
	  AND a.n26_estado     <> 'E'
IF r_n26.n26_compania IS NOT NULL THEN
	LET rm_n26.* = r_n26.*
	CALL fl_mostrar_mensaje('Ya se han generado novedades de este tipo de archivo para este mes de carga.', 'exclamation')
	SELECT n27_cod_trab n33_cod_trab, n27_cedula_trab cedula, n30_nombres,
		n27_valor_net valor
		FROM rolt027, rolt030
		WHERE n27_compania    = r_n26.n26_compania
		  AND n27_ano_proceso = r_n26.n26_ano_proceso
		  AND n27_mes_proceso = r_n26.n26_mes_proceso
		  AND n27_codigo_arch = r_n26.n26_codigo_arch
		  AND n27_tipo_arch   = r_n26.n26_tipo_arch
		  AND n27_secuencia   = r_n26.n26_secuencia
		  AND n27_estado     <> 'E'
		  AND n30_compania    = n27_compania
		  AND n30_cod_trab    = n27_cod_trab
		INTO TEMP t1
	SELECT n26_ruc_patronal ruc, n26_sucursal sucursal, n26_ano_carga anio,
		n26_mes_carga mes, n26_tipo_arch tipo, n27_cedula_trab cedula,
		n27_valor_net valor_ext, n27_tipo_causa causa
		FROM rolt026, rolt027
		WHERE n26_compania    = r_n26.n26_compania
		  AND n26_ano_proceso = r_n26.n26_ano_proceso
		  AND n26_mes_proceso = r_n26.n26_mes_proceso
		  AND n26_codigo_arch = r_n26.n26_codigo_arch
		  AND n26_tipo_arch   = r_n26.n26_tipo_arch
		  AND n26_secuencia   = r_n26.n26_secuencia
		  AND n26_estado     <> 'E'
		  AND n27_compania    = n26_compania
		  AND n27_ano_proceso = n26_ano_proceso
		  AND n27_mes_proceso = n26_mes_proceso
		  AND n27_codigo_arch = n26_codigo_arch
		  AND n27_tipo_arch   = n26_tipo_arch
		  AND n27_secuencia   = n26_secuencia
		INTO TEMP t2
	RETURN 1
END IF
RETURN 0

END FUNCTION



FUNCTION bajar_archivo()
DEFINE r_n26		RECORD LIKE rolt026.*
DEFINE mensaje		VARCHAR(250)

INITIALIZE r_n26.* TO NULL
SELECT * INTO r_n26.*
	FROM rolt026
	WHERE n26_compania    = vg_codcia
	  AND n26_ano_proceso = rm_n26.n26_ano_proceso
	  AND n26_mes_proceso = rm_n26.n26_mes_proceso
	  AND n26_codigo_arch = rm_n26.n26_codigo_arch
	  AND n26_tipo_arch   = rm_n26.n26_tipo_arch
	  AND n26_secuencia   = rm_n26.n26_secuencia
IF r_n26.n26_compania IS NOT NULL THEN
	UNLOAD TO "extras.txt" DELIMITER ";"
	SELECT n26_ruc_patronal ruc, n26_sucursal sucursal, n26_ano_carga anio,
		LPAD(n26_mes_carga, 2, 0) mes, n26_tipo_arch tipo,
		n27_cedula_trab cedula, LPAD(n27_valor_net, 14, 0) valor_ext,
		n27_tipo_causa causa
		FROM rolt026, rolt027
		WHERE n26_compania     = r_n26.n26_compania
		  AND n26_ano_proceso  = r_n26.n26_ano_proceso
		  AND n26_mes_proceso  = r_n26.n26_mes_proceso
		  AND n26_codigo_arch  = r_n26.n26_codigo_arch
		  AND n26_tipo_arch    = r_n26.n26_tipo_arch
		  AND n26_secuencia    = r_n26.n26_secuencia
		  AND n26_estado      <> 'E'
		  AND n27_compania     = n26_compania
		  AND n27_ano_proceso  = n26_ano_proceso
		  AND n27_mes_proceso  = n26_mes_proceso
		  AND n27_codigo_arch  = n26_codigo_arch
		  AND n27_tipo_arch    = n26_tipo_arch
		  AND n27_secuencia    = n26_secuencia
		  AND n27_estado      <> 'E'
		  AND n27_valor_net    > 0
ELSE
	UNLOAD TO "extras.txt" DELIMITER ";" SELECT * FROM t2
END IF
--SQL UNLOAD TO $rm_n26.n26_nombre_arch DELIMITER ";" SELECT * FROM t2 END SQL
RUN 'sed -e "1,$ s/;$//g" extras.txt > extras2.txt'
RUN 'mv extras2.txt extras.txt'
RUN 'unix2dos extras.txt'
RUN 'mv extras.txt $HOME/tmp/extras.txt'
LET mensaje = FGL_GETENV("HOME"), '/tmp/extras.txt'
CALL fl_mostrar_mensaje('Archivo Generado en: ' || mensaje, 'info')
--CALL fl_mostrar_mensaje('Archivo con valores extras por trabajador, para el IESS, generado OK.', 'info')

END FUNCTION



FUNCTION datos_defaults_cab()
DEFINE r_g02		RECORD LIKE gent002.*
DEFINE fecha		LIKE rolt032.n32_fecha_fin
DEFINE fec_ult		DATETIME YEAR TO MONTH
DEFINE fec_car		DATETIME YEAR TO MONTH

LET rm_n26.n26_compania     = vg_codcia
LET rm_n26.n26_ano_proceso  = YEAR(TODAY)
LET rm_n26.n26_mes_proceso  = MONTH(TODAY)
INITIALIZE fec_ult, fec_car TO NULL
SQL
	SELECT EXTEND(NVL(MAX(MDY(n26_mes_proceso, 01, n26_ano_proceso)
			+ 1 UNITS MONTH), TODAY), YEAR TO MONTH),
		EXTEND(NVL(MAX(MDY(n26_mes_carga, 01, n26_ano_carga)
			+ 1 UNITS MONTH), TODAY), YEAR TO MONTH)
		INTO $fec_ult, $fec_car
		FROM rolt026
		WHERE n26_compania = $vg_codcia
		  AND n26_estado   = 'C'
END SQL
IF fec_ult IS NOT NULL THEN
	LET rm_n26.n26_ano_proceso = YEAR(fec_ult)
	LET rm_n26.n26_mes_proceso = MONTH(fec_ult)
END IF
LET rm_n26.n26_estado       = 'G'
CALL fl_lee_localidad(rm_n26.n26_compania, vg_codloc) RETURNING r_g02.*
LET rm_n26.n26_ruc_patronal = r_g02.g02_numruc
LET rm_n26.n26_sucursal     = r_g02.g02_serie_cia USING "&&&#"
SELECT NVL(MAX(n32_fecha_fin), TODAY)
	INTO fecha
	FROM rolt032
	WHERE n32_compania    = rm_n26.n26_compania
	  AND n32_cod_liqrol IN ("Q1", "Q2")
	  AND n32_estado     = "C"
LET rm_n26.n26_ano_carga    = YEAR(fecha)
LET rm_n26.n26_mes_carga    = MONTH(fecha)
IF fec_car IS NOT NULL THEN
	LET rm_n26.n26_ano_carga = YEAR(fec_car)
	LET rm_n26.n26_mes_carga = MONTH(fec_car)
END IF
LET rm_n26.n26_total_ext    = 0
LET rm_n26.n26_total_adi    = 0
LET rm_n26.n26_total_net    = 0
LET rm_n26.n26_usuario      = vg_usuario
LET rm_n26.n26_fecing       = CURRENT
DISPLAY BY NAME rm_n26.n26_ano_proceso, rm_n26.n26_mes_proceso,
		rm_n26.n26_estado, rm_n26.n26_ruc_patronal, rm_n26.n26_sucursal,
		rm_n26.n26_ano_carga, rm_n26.n26_mes_carga, rm_n26.n26_usuario,
		rm_n26.n26_fecing
CALL muestra_estado()

END FUNCTION



FUNCTION leer_cabecera()
DEFINE r_n22		RECORD LIKE rolt022.*
DEFINE codigo		LIKE rolt026.n26_codigo_arch
DEFINE anio		LIKE rolt026.n26_ano_proceso
DEFINE mes		LIKE rolt026.n26_mes_proceso
DEFINE resp		CHAR(6)

LET int_flag = 0 
INPUT BY NAME rm_n26.n26_codigo_arch, rm_n26.n26_nombre_arch,
	rm_n26.n26_ano_proceso, rm_n26.n26_mes_proceso
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		IF FIELD_TOUCHED(rm_n26.n26_codigo_arch, rm_n26.n26_nombre_arch,
				 rm_n26.n26_ano_proceso, rm_n26.n26_mes_proceso)
		THEN
			LET int_flag = 0
			CALL fl_mensaje_abandonar_proceso() RETURNING resp
			IF resp = 'Yes' THEN
				LET int_flag = 1
				EXIT INPUT
			END IF
		ELSE
			EXIT INPUT
		END IF
	ON KEY(F2)
		IF INFIELD(n26_codigo_arch) THEN
			CALL fl_ayuda_tipo_arch_iess(vg_codcia)
				RETURNING r_n22.n22_codigo_arch,
						r_n22.n22_tipo_arch
                        IF r_n22.n22_codigo_arch IS NOT NULL THEN
				LET rm_n26.n26_codigo_arch =
							r_n22.n22_codigo_arch
				LET rm_n26.n26_tipo_arch   = r_n22.n22_tipo_arch
				CALL fl_lee_tipo_arch_iess(vg_codcia,
							rm_n26.n26_codigo_arch,
							rm_n26.n26_tipo_arch)
					RETURNING r_n22.*
				LET rm_n26.n26_nombre_arch =
							r_n22.n22_nombre_arch
				DISPLAY BY NAME rm_n26.n26_codigo_arch,
						r_n22.n22_descripcion,
						rm_n26.n26_tipo_arch,
						rm_n26.n26_nombre_arch
			END IF
		END IF
		LET int_flag = 0
	BEFORE FIELD n26_codigo_arch
		LET codigo = rm_n26.n26_codigo_arch
	BEFORE FIELD n26_ano_proceso
		LET anio = rm_n26.n26_ano_proceso
	BEFORE FIELD n26_mes_proceso
		LET mes = rm_n26.n26_mes_proceso
	AFTER FIELD n26_codigo_arch
		IF vm_flag_mant <> 'I' THEN
			LET rm_n26.n26_codigo_arch = codigo
			CALL fl_lee_tipo_arch_iess(vg_codcia,
							rm_n26.n26_codigo_arch,
							rm_n26.n26_tipo_arch)
				RETURNING r_n22.*
			DISPLAY BY NAME rm_n26.n26_codigo_arch,
					r_n22.n22_descripcion
			CONTINUE INPUT
		END IF
		IF rm_n26.n26_codigo_arch IS NOT NULL THEN
			DECLARE q_n22 CURSOR FOR
				SELECT UNIQUE n22_tipo_arch
					FROM rolt022
					WHERE n22_compania    = vg_codcia
					  AND n22_codigo_arch =
							rm_n26.n26_codigo_arch
					ORDER BY 1
			OPEN q_n22
			FETCH q_n22 INTO rm_n26.n26_tipo_arch
			CLOSE q_n22
			FREE q_n22
			CALL fl_lee_tipo_arch_iess(vg_codcia,
							rm_n26.n26_codigo_arch,
							rm_n26.n26_tipo_arch)
				RETURNING r_n22.*
			IF r_n22.n22_codigo_arch IS NULL THEN
				CALL fl_mostrar_mensaje('Codigo de archivo no existe.', 'exclamation')
				NEXT FIELD n26_codigo_arch
			END IF
			LET rm_n26.n26_tipo_arch   = r_n22.n22_tipo_arch
			LET rm_n26.n26_nombre_arch = r_n22.n22_nombre_arch
			DISPLAY BY NAME r_n22.n22_descripcion,
					rm_n26.n26_tipo_arch,
					rm_n26.n26_nombre_arch
		ELSE
			LET rm_n26.n26_tipo_arch   = NULL
			LET rm_n26.n26_nombre_arch = NULL
			CLEAR n26_codigo_arch, n22_descripcion, n26_tipo_arch,
				n26_nombre_arch
		END IF
	AFTER FIELD n26_ano_proceso, n26_mes_proceso
		IF vm_flag_mant <> 'I' THEN
			LET rm_n26.n26_ano_proceso = anio
			LET rm_n26.n26_mes_proceso = mes
			DISPLAY BY NAME rm_n26.n26_ano_proceso,
					rm_n26.n26_mes_proceso
			CONTINUE INPUT
		END IF
		IF rm_n26.n26_ano_proceso IS NULL THEN
			LET rm_n26.n26_ano_proceso = anio
		END IF
		IF rm_n26.n26_mes_proceso IS NULL THEN
			LET rm_n26.n26_mes_proceso = mes
		END IF
		IF EXTEND(MDY(rm_n26.n26_mes_proceso, 01,
			rm_n26.n26_ano_proceso), YEAR TO MONTH) >
			EXTEND(TODAY, YEAR TO MONTH)
		THEN
			LET rm_n26.n26_ano_proceso = YEAR(TODAY)
			LET rm_n26.n26_mes_proceso = MONTH(TODAY)
		END IF
		IF EXTEND(MDY(rm_n26.n26_mes_proceso, 01,
			rm_n26.n26_ano_proceso), YEAR TO MONTH) <
			EXTEND(MDY(rm_n26.n26_mes_carga, 01,
			rm_n26.n26_ano_carga), YEAR TO MONTH)
		THEN
			LET rm_n26.n26_ano_proceso = rm_n26.n26_ano_carga
			LET rm_n26.n26_mes_proceso = rm_n26.n26_mes_carga
		END IF
		DISPLAY BY NAME rm_n26.n26_ano_proceso, rm_n26.n26_mes_proceso
END INPUT

END FUNCTION



FUNCTION leer_detalle()
DEFINE r_n30		RECORD LIKE rolt030.*
DEFINE cod_trab		LIKE rolt027.n27_cod_trab
DEFINE val_ext		LIKE rolt027.n27_valor_ext
DEFINE val_adi		LIKE rolt027.n27_valor_adi
DEFINE i, j, max_row	SMALLINT
DEFINE aux_num		SMALLINT
DEFINE resp		CHAR(6)

--OPTIONS	DELETE KEY F31
LET aux_num = vm_num_det
CALL mostrar_total()
LET int_flag = 0
CALL set_count(vm_num_det)
INPUT ARRAY rm_detalle WITHOUT DEFAULTS FROM rm_detalle.*
	ON KEY(INTERRUPT)
		LET int_flag = 0
		CALL fl_mensaje_abandonar_proceso() RETURNING resp
		IF resp = 'Yes' THEN
			LET int_flag   = 1
			LET vm_num_det = aux_num
			EXIT INPUT
		END IF
	ON KEY(F2)
		IF INFIELD(n27_cod_trab) THEN
			CALL fl_ayuda_codigo_empleado(vg_codcia)
				RETURNING r_n30.n30_cod_trab, r_n30.n30_nombres
			IF r_n30.n30_cod_trab IS NOT NULL THEN
				CALL mostrar_linea_detalle(r_n30.n30_cod_trab,
								i, j)
			END IF
		END IF
		LET int_flag = 0
	ON KEY(F5)
		LET i = arr_curr()
		LET j = scr_line()
		LET rm_aux_det[i].n27_estado      = 'E'
		LET rm_aux_det[i].n27_usua_elimin = vg_usuario
		LET rm_aux_det[i].n27_fec_elimin  = CURRENT
	BEFORE INPUT
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
       		--CALL dialog.keysetlabel('DELETE','')
	BEFORE INSERT
		INITIALIZE rm_detalle[i].*, rm_aux_det[i].* TO NULL
		LET rm_aux_det[i].n27_estado      = 'M'
		LET rm_aux_det[i].n27_usua_modifi = vg_usuario
		LET rm_aux_det[i].n27_fec_modifi  = CURRENT
		LET max_row = arr_count()
		IF i > max_row THEN
			LET max_row = max_row + 1
		END IF
		LET vm_num_det = max_row
	BEFORE ROW
		LET i = arr_curr()
		LET j = scr_line()
		LET max_row = arr_count()
		IF i > max_row THEN
			LET max_row = max_row + 1
		END IF
		CALL muestra_contadores_det(i, max_row)
		LET cod_trab = rm_detalle[i].n27_cod_trab
		LET val_ext  = rm_detalle[i].n27_valor_ext
		LET val_adi  = rm_detalle[i].n27_valor_adi
	AFTER FIELD n27_cod_trab
		IF NOT FIELD_TOUCHED(rm_detalle[i].n27_cod_trab) THEN
			CONTINUE INPUT
		END IF
		IF rm_aux_det[i].n27_estado = 'E' THEN
			CALL fl_mostrar_mensaje('Registro esta eliminado.', 'exclamation')
			CALL mostrar_linea_detalle(cod_trab, i, j)
			CALL mostrar_total()
			CONTINUE INPUT
		END IF
		IF rm_detalle[i].n27_cod_trab IS NULL THEN
			CALL mostrar_linea_detalle(cod_trab, i, j)
		END IF
		CALL fl_lee_trabajador_roles(vg_codcia,
						rm_detalle[i].n27_cod_trab)
                       	RETURNING r_n30.*
		IF r_n30.n30_compania IS NULL THEN
			CALL fl_mostrar_mensaje('No existe el codigo de este empleado en la Compania.','exclamation')
			NEXT FIELD n27_cod_trab
		END IF
		IF r_n30.n30_estado = 'I' THEN
			CALL fl_mensaje_estado_bloqueado()
			--NEXT FIELD n27_cod_trab
		END IF
		IF r_n30.n30_estado = 'J' THEN
			CALL fl_mostrar_mensaje('No puede escojer un empleado que este jubilado.', 'exclamation')
			NEXT FIELD n27_cod_trab
		END IF
		CALL mostrar_linea_detalle(r_n30.n30_cod_trab, i, j)
		CALL mostrar_total()
		LET rm_aux_det[i].n27_estado      = 'M'
		LET rm_aux_det[i].n27_usua_modifi = vg_usuario
		LET rm_aux_det[i].n27_fec_modifi  = CURRENT
	AFTER FIELD n27_valor_adi
		IF NOT FIELD_TOUCHED(rm_detalle[i].n27_valor_adi) THEN
			CONTINUE INPUT
		END IF
		IF rm_aux_det[i].n27_estado = 'E' THEN
			CALL fl_mostrar_mensaje('Registro esta eliminado.', 'exclamation')
			CALL mostrar_linea_detalle(cod_trab, i, j)
			LET rm_detalle[i].n27_valor_ext = val_ext
			DISPLAY rm_detalle[i].n27_valor_ext TO
				rm_detalle[j].n27_valor_ext
			LET rm_detalle[i].n27_valor_adi = val_adi
			DISPLAY rm_detalle[i].n27_valor_adi TO
				rm_detalle[j].n27_valor_adi
			CALL mostrar_total()
			CONTINUE INPUT
		END IF
		IF rm_detalle[i].n27_valor_adi IS NULL THEN
			LET rm_detalle[i].n27_valor_adi = val_adi
			DISPLAY rm_detalle[i].n27_valor_adi TO
				rm_detalle[j].n27_valor_adi
		END IF
		IF rm_detalle[i].n27_valor_adi < 0 THEN
			CALL fl_mostrar_mensaje('El valor adicional del trabajador no puede ser menor a CERO.', 'exclamation')
			NEXT FIELD n27_valor_adi
		END IF
		LET rm_aux_det[i].n27_estado      = 'M'
		LET rm_aux_det[i].n27_usua_modifi = vg_usuario
		LET rm_aux_det[i].n27_fec_modifi  = CURRENT
		CALL mostrar_total()
	AFTER INPUT
		IF empleados_repetidos() THEN
			CONTINUE INPUT
		END IF
		CALL mostrar_total()
		IF rm_detalle[1].n27_cod_trab IS NULL THEN
			CALL fl_mostrar_mensaje('Al menos debe digitar un empleado.', 'exclamation')
			CONTINUE INPUT
		END IF
END INPUT
IF int_flag THEN
	RETURN
END IF
LET vm_num_det = arr_count()

END FUNCTION



FUNCTION empleados_repetidos()
DEFINE i, j, resul	SMALLINT
DEFINE mensaje		VARCHAR(120)

LET resul = 0
FOR i = 1 TO vm_num_det - 1
	FOR j = i + 1 TO vm_num_det
		IF rm_detalle[i].n27_cedula_trab = rm_detalle[j].n27_cedula_trab
		THEN
			LET mensaje = 'El empleado: ',
					rm_detalle[i].n27_cod_trab
					USING "<<<<<&", ' ',
					rm_detalle[i].n30_nombres CLIPPED, ' ',
					'esta repetido'
			CALL fl_mostrar_mensaje(mensaje, 'exclamation')
			LET resul = 1
			EXIT FOR
		END IF
	END FOR
	IF resul THEN
		EXIT FOR
	END IF
END FOR
RETURN resul

END FUNCTION



FUNCTION cargar_temporal()
DEFINE mes		CHAR(2)
DEFINE i		SMALLINT
DEFINE valor_net	LIKE rolt027.n27_valor_net

DELETE FROM t2 WHERE 1 = 1
LET mes = rm_n26.n26_mes_carga USING "&&"
FOR i = 1 TO vm_num_det
	LET valor_net = rm_detalle[i].n27_valor_ext +
			rm_detalle[i].n27_valor_adi
	INSERT INTO t2
		VALUES (rm_n26.n26_ruc_patronal, rm_n26.n26_sucursal,
			rm_n26.n26_ano_carga, mes, rm_n26.n26_tipo_arch,
			rm_detalle[i].n27_cedula_trab, valor_net,
			rm_detalle[i].n27_tipo_causa)
END FOR

END FUNCTION



FUNCTION grabar_archivo()
DEFINE num_aux		INTEGER

BEGIN WORK
	SELECT rolt026.ROWID
		INTO num_aux
		FROM rolt026
		WHERE n26_compania    = rm_n26.n26_compania
		  AND n26_ano_proceso = rm_n26.n26_ano_proceso
		  AND n26_mes_proceso = rm_n26.n26_mes_proceso
		  AND n26_codigo_arch = rm_n26.n26_codigo_arch
		  AND n26_tipo_arch   = rm_n26.n26_tipo_arch
		  AND n26_secuencia   = rm_n26.n26_secuencia
	IF STATUS = NOTFOUND THEN
		LET rm_n26.n26_fecing = CURRENT
		SELECT NVL(MAX(n26_secuencia), 0) + 1
			INTO rm_n26.n26_secuencia
			FROM rolt026
			WHERE n26_compania    = rm_n26.n26_compania
			  AND n26_ano_proceso = rm_n26.n26_ano_proceso
			  AND n26_mes_proceso = rm_n26.n26_mes_proceso
			  AND n26_codigo_arch = rm_n26.n26_codigo_arch
			  AND n26_tipo_arch   = rm_n26.n26_tipo_arch
		WHENEVER ERROR CONTINUE
		INSERT INTO rolt026 VALUES(rm_n26.*)
		IF STATUS <> 0 THEN
			ROLLBACK WORK
			WHENEVER ERROR STOP
			CALL fl_mostrar_mensaje('Ha ocurrido un ERROR al querer grabar el archivo en la tabla rolt026. POR FAVOR LLAME AL ADMINISTRADOR', 'stop')
			EXIT PROGRAM
		END IF
		LET num_aux = SQLCA.SQLERRD[6] 
		WHENEVER ERROR STOP
	END IF
	CALL grabar_detalle_archivo()
COMMIT WORK
RETURN num_aux

END FUNCTION



FUNCTION grabar_detalle_archivo()
DEFINE r_n27		RECORD LIKE rolt027.*
DEFINE tot1		LIKE rolt026.n26_total_ext
DEFINE tot2		LIKE rolt026.n26_total_adi
DEFINE tot3		LIKE rolt026.n26_total_net
DEFINE i		SMALLINT

WHENEVER ERROR CONTINUE
DELETE FROM rolt027
	WHERE n27_compania    = rm_n26.n26_compania
	  AND n27_ano_proceso = rm_n26.n26_ano_proceso
	  AND n27_mes_proceso = rm_n26.n26_mes_proceso
	  AND n27_codigo_arch = rm_n26.n26_codigo_arch
	  AND n27_tipo_arch   = rm_n26.n26_tipo_arch
	  AND n27_secuencia   = rm_n26.n26_secuencia
IF STATUS <> 0 THEN
	ROLLBACK WORK
	WHENEVER ERROR STOP
	CALL fl_mostrar_mensaje('Ha ocurrido un ERROR al querer borrar el detalle del archivo en la tabla rolt027. POR FAVOR LLAME AL ADMINISTRADOR', 'stop')
	EXIT PROGRAM
END IF
WHENEVER ERROR STOP
FOR i = 1 TO vm_num_det
	INITIALIZE r_n27.* TO NULL
	LET r_n27.n27_compania    = rm_n26.n26_compania
	LET r_n27.n27_ano_proceso = rm_n26.n26_ano_proceso
	LET r_n27.n27_mes_proceso = rm_n26.n26_mes_proceso
	LET r_n27.n27_codigo_arch = rm_n26.n26_codigo_arch
	LET r_n27.n27_tipo_arch   = rm_n26.n26_tipo_arch
	LET r_n27.n27_secuencia   = rm_n26.n26_secuencia
	LET r_n27.n27_cod_trab    = rm_detalle[i].n27_cod_trab
	LET r_n27.n27_estado      = 'G'
	IF rm_aux_det[i].n27_estado IS NOT NULL THEN
		LET r_n27.n27_estado = rm_aux_det[i].n27_estado
	END IF
	LET r_n27.n27_cedula_trab = rm_detalle[i].n27_cedula_trab
	LET r_n27.n27_valor_ext   = rm_detalle[i].n27_valor_ext
	LET r_n27.n27_valor_adi   = rm_detalle[i].n27_valor_adi
	LET r_n27.n27_valor_net   = r_n27.n27_valor_ext + r_n27.n27_valor_adi
	LET r_n27.n27_tipo_causa  = rm_detalle[i].n27_tipo_causa
	LET r_n27.n27_sec_cau     = 1
	LET r_n27.n27_tipo_per    = 'X'
	LET r_n27.n27_usua_elimin = rm_aux_det[i].n27_usua_elimin
	LET r_n27.n27_fec_elimin  = rm_aux_det[i].n27_fec_elimin
	LET r_n27.n27_usua_modifi = rm_aux_det[i].n27_usua_modifi
	LET r_n27.n27_fec_modifi  = rm_aux_det[i].n27_fec_modifi
	WHENEVER ERROR CONTINUE
	INSERT INTO rolt027 VALUES(r_n27.*)
	IF STATUS <> 0 THEN
		ROLLBACK WORK
		WHENEVER ERROR STOP
		CALL fl_mostrar_mensaje('Ha ocurrido un ERROR al querer grabar el archivo en la tabla rolt027. POR FAVOR LLAME AL ADMINISTRADOR', 'stop')
		EXIT PROGRAM
	END IF
	WHENEVER ERROR STOP
END FOR
WHENEVER ERROR CONTINUE
SELECT NVL(SUM(n27_valor_ext), 0), NVL(SUM(n27_valor_adi), 0),
	NVL(SUM(n27_valor_net), 0)
	INTO tot1, tot2, tot3
	FROM rolt027
	WHERE n27_compania    = rm_n26.n26_compania
	  AND n27_ano_proceso = rm_n26.n26_ano_proceso
	  AND n27_mes_proceso = rm_n26.n26_mes_proceso
	  AND n27_codigo_arch = rm_n26.n26_codigo_arch
	  AND n27_tipo_arch   = rm_n26.n26_tipo_arch
	  AND n27_secuencia   = rm_n26.n26_secuencia
UPDATE rolt026
	SET n26_total_ext = tot1,
	    n26_total_adi = tot2,
	    n26_total_net = tot3
	WHERE n26_compania    = rm_n26.n26_compania
	  AND n26_ano_proceso = rm_n26.n26_ano_proceso
	  AND n26_mes_proceso = rm_n26.n26_mes_proceso
	  AND n26_codigo_arch = rm_n26.n26_codigo_arch
	  AND n26_tipo_arch   = rm_n26.n26_tipo_arch
	  AND n26_secuencia   = rm_n26.n26_secuencia
WHENEVER ERROR STOP

END FUNCTION



FUNCTION cargar_detalle(flag)
DEFINE flag		SMALLINT
DEFINE query		CHAR(1500)
DEFINE secu		LIKE rolt026.n26_secuencia

CASE flag
	WHEN 1
		LET query = 'SELECT cedula, n30_cod_trab, n30_nombres, ',
					'valor_ext, '
				IF rm_n26.n26_compania IS NOT NULL THEN
				LET secu = rm_n26.n26_secuencia
				IF rm_n26.n26_secuencia IS NULL THEN
					LET secu = 1
				END IF
				LET query = query CLIPPED, ' ',
				'NVL((SELECT n27_valor_adi ',
					'FROM rolt027 ',
				'WHERE n27_compania    = ',rm_n26.n26_compania,
				'  AND n27_ano_proceso = ',
							rm_n26.n26_ano_proceso,
				'  AND n27_mes_proceso = ',
							rm_n26.n26_mes_proceso,
				'  AND n27_codigo_arch = ',
							rm_n26.n26_codigo_arch,
				'  AND n27_tipo_arch   = "',
						rm_n26.n26_tipo_arch, '"',
				'  AND n27_secuencia   = ', secu,
				'  AND n27_cod_trab    = n30_cod_trab ',
				'  AND n27_estado     <> "E"), 0), '
				ELSE
				LET query = query CLIPPED, ' 0.00, '
				END IF
				LET query = query CLIPPED, ' ',
				'causa, "X", "", "", "", "" ',
				' FROM rolt030, t2 ',
				' WHERE  n30_compania    = ', vg_codcia,
				'   AND (n30_num_doc_id  = cedula ',
				'    OR  n30_carnet_seg  = cedula) ',
				'   AND  n30_estado     <> "J"',
				' ORDER BY 3'
	WHEN 2
		LET query = 'SELECT n27_cedula_trab, n27_cod_trab, ',
					'n30_nombres, n27_valor_ext, ',
					'n27_valor_adi, n27_tipo_causa, ',
					'n27_estado, n27_usua_elimin, ',
					'n27_fec_elimin, n27_usua_modifi, ',
					'n27_fec_modifi ',
				' FROM rolt027, rolt030 ',
				' WHERE n27_compania    = ',rm_n26.n26_compania,
				'   AND n27_ano_proceso = ',
							rm_n26.n26_ano_proceso,
				'   AND n27_mes_proceso = ',
							rm_n26.n26_mes_proceso,
				'   AND n27_codigo_arch = ',
							rm_n26.n26_codigo_arch,
				'   AND n27_tipo_arch   = "',
						rm_n26.n26_tipo_arch, '"',
				'   AND n27_secuencia   = ',
						rm_n26.n26_secuencia,
				'   AND n30_compania    = n27_compania ',
				'   AND n30_cod_trab    = n27_cod_trab ',
				' ORDER BY 3'
END CASE
PREPARE cons_det FROM query
DECLARE q_det CURSOR FOR cons_det
LET vm_num_det = 1
FOREACH q_det INTO rm_detalle[vm_num_det].*, rm_aux_det[vm_num_det].*
	IF rm_aux_det[vm_num_det].n27_estado = "X" THEN
		INITIALIZE rm_aux_det[vm_num_det].* TO NULL
	END IF
	LET vm_num_det = vm_num_det + 1
	IF vm_num_det > vm_max_det THEN
		EXIT FOREACH
	END IF
END FOREACH
LET vm_num_det = vm_num_det - 1

END FUNCTION



FUNCTION mostrar_detalle()
DEFINE i, lim		SMALLINT

CALL borrar_detalle()
LET lim = vm_num_det
IF lim > fgl_scr_size('rm_detalle') THEN
	LET lim = fgl_scr_size('rm_detalle')
END IF
FOR i = 1 TO lim
	DISPLAY rm_detalle[i].* TO rm_detalle[i].*
END FOR
CALL mostrar_total()

END FUNCTION



FUNCTION mostrar_total()
DEFINE i		SMALLINT

LET total_valor_ext = 0
LET total_valor_adi = 0
FOR i = 1 TO vm_num_det
	LET total_valor_ext = total_valor_ext + rm_detalle[i].n27_valor_ext
	LET total_valor_adi = total_valor_adi + rm_detalle[i].n27_valor_adi
END FOR
DISPLAY BY NAME total_valor_ext, total_valor_adi

END FUNCTION



FUNCTION ubicarse_detalle()
DEFINE i, j		SMALLINT

CALL set_count(vm_num_det)
LET int_flag = 0
DISPLAY ARRAY rm_detalle TO rm_detalle.*
       	ON KEY(INTERRUPT)   
		LET int_flag = 1
       	        EXIT DISPLAY  
	--#BEFORE DISPLAY 
		--#CALL dialog.keysetlabel('ACCEPT', '')   
		--#CALL dialog.keysetlabel("F1","") 
		--#CALL dialog.keysetlabel("CONTROL-W","") 
		--#CALL dialog.keysetlabel("RETURN","") 
	--#BEFORE ROW 
		--#LET i = arr_curr()	
		--#LET j = scr_line()
		--#CALL muestra_contadores_det(i, vm_num_det)
        --#AFTER DISPLAY  
                --#CONTINUE DISPLAY  
END DISPLAY
CALL muestra_contadores_det(0, vm_num_det)
IF int_flag THEN
	IF vm_num_det > fgl_scr_size('rm_detalle') THEN
		CALL mostrar_detalle()
	END IF
END IF

END FUNCTION



FUNCTION mostrar_botones()

DISPLAY 'Cedula Emp.'		TO tit_col1
DISPLAY 'Codigo'		TO tit_col2
DISPLAY 'E m p l e a d o s'	TO tit_col3
DISPLAY 'Valor Ext.'		TO tit_col4
DISPLAY 'Valor Adi.'		TO tit_col5
DISPLAY 'T'			TO tit_col6

END FUNCTION



FUNCTION muestra_contadores()

DISPLAY BY NAME vm_row_current, vm_num_rows

END FUNCTION



FUNCTION muestra_contadores_det(num_row, max_row)
DEFINE num_row, max_row	SMALLINT

DISPLAY BY NAME num_row, max_row

END FUNCTION 



FUNCTION muestra_siguiente_registro()

IF vm_row_current < vm_num_rows THEN
	LET vm_row_current = vm_row_current + 1
END IF
CALL muestrar_reg()

END FUNCTION



FUNCTION muestra_anterior_registro()

IF vm_row_current > 1 THEN
	LET vm_row_current = vm_row_current - 1
END IF
CALL muestrar_reg()

END FUNCTION



FUNCTION mostrar_salir(flag)
DEFINE flag		SMALLINT

CLEAR FORM
CALL mostrar_botones()
INITIALIZE rm_n26.* TO NULL
IF vm_row_current > 0 THEN
	CALL muestrar_reg()
END IF
IF flag THEN
	DROP TABLE t1
	DROP TABLE t2
END IF

END FUNCTION



FUNCTION muestrar_reg()

CALL mostrar_registro(vm_r_rows[vm_row_current])
CALL muestra_contadores()
CALL muestra_contadores_det(0, vm_num_det)

END FUNCTION



FUNCTION mostrar_registro(num_registro)
DEFINE num_registro	INTEGER
DEFINE r_n22		RECORD LIKE rolt022.*

IF vm_num_rows <= 0 THEN
	RETURN
END IF
DECLARE q_cons1 CURSOR FOR SELECT * FROM rolt026 WHERE ROWID = num_registro
OPEN q_cons1
FETCH q_cons1 INTO rm_n26.*
IF STATUS = NOTFOUND THEN
	CLOSE q_cons1
	FREE q_cons1
	CALL fl_mostrar_mensaje('No existe registro con Ã­ndice: ' || vm_row_current,'exclamation')
	RETURN
END IF
CLOSE q_cons1
FREE q_cons1
DISPLAY BY NAME rm_n26.n26_codigo_arch, rm_n26.n26_nombre_arch,
		rm_n26.n26_ano_proceso, rm_n26.n26_mes_proceso,
		rm_n26.n26_estado, rm_n26.n26_ruc_patronal, rm_n26.n26_sucursal,
		rm_n26.n26_ano_carga, rm_n26.n26_mes_carga, rm_n26.n26_usuario,
		rm_n26.n26_fecing, rm_n26.n26_usua_cierre, rm_n26.n26_fec_cierre
CALL fl_lee_tipo_arch_iess(vg_codcia, rm_n26.n26_codigo_arch,
				rm_n26.n26_tipo_arch)
	RETURNING r_n22.*
DISPLAY BY NAME r_n22.n22_descripcion
CALL muestra_estado()
CALL cargar_detalle(2)
CALL mostrar_detalle()

END FUNCTION



FUNCTION borrar_pantalla()

CALL borrar_cabecera()
CALL limpiar_detalle()
CALL borrar_detalle()

END FUNCTION



FUNCTION borrar_cabecera()

INITIALIZE rm_n26.* TO NULL
CLEAR n26_codigo_arch, n22_descripcion, n26_tipo_arch, n26_nombre_arch,
	n26_ano_proceso, n26_mes_proceso, n26_estado, tit_estado, n26_ano_carga,
	n26_mes_carga, n26_ruc_patronal, n26_sucursal, num_row, max_row,
	vm_row_current, vm_num_rows

END FUNCTION



FUNCTION limpiar_detalle()
DEFINE i		SMALLINT

FOR i = 1 TO vm_max_det
	INITIALIZE rm_detalle[i].*, rm_aux_det[i].* TO NULL
END FOR

END FUNCTION



FUNCTION borrar_detalle()
DEFINE i		SMALLINT

FOR i = 1 TO fgl_scr_size('rm_detalle')
	CLEAR rm_detalle[i].*
END FOR
CLEAR total_valor_ext, total_valor_adi

END FUNCTION



FUNCTION muestra_estado()

DISPLAY BY NAME rm_n26.n26_estado
CASE rm_n26.n26_estado
	WHEN 'G'
		DISPLAY 'GENERADO'  TO tit_estado
	WHEN 'C'
		DISPLAY 'CERRADO'   TO tit_estado
	WHEN 'E'
		DISPLAY 'ELIMINADO' TO tit_estado
	OTHERWISE
		CLEAR n26_estado, tit_estado
END CASE

END FUNCTION



FUNCTION retorna_causa()
DEFINE causa		LIKE rolt023.n23_tipo_causa

DECLARE q_causa CURSOR FOR
	SELECT NVL(n23_tipo_causa, "O")
		FROM rolt023
		WHERE n23_compania    = vg_codcia
		  AND n23_codigo_arch = rm_n26.n26_codigo_arch
		  AND n23_tipo_arch   = rm_n26.n26_tipo_arch
		  AND n23_flag_ident  = "AP"
OPEN q_causa
FETCH q_causa INTO causa
CLOSE q_causa
FREE q_causa
RETURN causa

END FUNCTION



FUNCTION mostrar_linea_detalle(cod_trab, i, j)
DEFINE cod_trab		LIKE rolt030.n30_cod_trab
DEFINE i, j		SMALLINT
DEFINE r_n30		RECORD LIKE rolt030.*

CALL fl_lee_trabajador_roles(vg_codcia, cod_trab) RETURNING r_n30.*
LET rm_detalle[i].n27_cedula_trab = r_n30.n30_num_doc_id
LET rm_detalle[i].n27_cod_trab    = r_n30.n30_cod_trab
LET rm_detalle[i].n30_nombres     = r_n30.n30_nombres
SELECT NVL(valor, 0)
	INTO rm_detalle[i].n27_valor_ext
	FROM t1
	WHERE n33_cod_trab = rm_detalle[i].n27_cod_trab
IF rm_detalle[i].n27_valor_ext IS NULL THEN
	LET rm_detalle[i].n27_valor_ext = 0
END IF
LET rm_detalle[i].n27_valor_adi   = 0
CALL retorna_causa() RETURNING rm_detalle[i].n27_tipo_causa
DISPLAY rm_detalle[i].* TO rm_detalle[j].*

END FUNCTION
