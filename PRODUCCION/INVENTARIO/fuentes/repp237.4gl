------------------------------------------------------------------------------
-- Titulo           : repp237.4gl - Proceso de Refacturación
-- Elaboracion      : 20-Sep-2004
-- Autor            : NPC
-- Formato Ejecucion: fglrun repp237 base modulo compania localidad
--			[ord_trabajo]
--			[cod_fact] [num_fact]
--			[cod_fact_ref] [num_fact_ref] [R]
-- Ultima Correccion: 
-- Motivo Correccion: 
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_rows		ARRAY[10000] OF INTEGER
DEFINE vm_row_current	SMALLINT
DEFINE vm_num_rows	SMALLINT
DEFINE vm_max_rows	SMALLINT
DEFINE vm_reprocesar	SMALLINT
DEFINE rm_r00	 	RECORD LIKE rept000.*
DEFINE rm_r88	 	RECORD LIKE rept088.*
DEFINE rm_t60	 	RECORD LIKE talt060.*



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/repp237.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 AND num_args() <> 5 AND num_args() <> 6 AND num_args() <> 7
THEN
-- Validar # parámetros correcto
	CALL fl_mostrar_mensaje('Número de parámetros incorrecto.','stop')
	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_codloc  = arg_val(4)
LET vg_proceso = 'repp237'
CALL fl_activar_base_datos(vg_base)
IF num_args() <> 4 THEN
	UPDATE gent054
		SET g54_estado = 'A'
		WHERE g54_modulo  = vg_modulo
		  AND g54_proceso = vg_proceso
		  AND g54_estado  = 'R'
END IF
CALL fl_seteos_defaults()
--#CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
IF num_args() <> 4 THEN
	UPDATE gent054
		SET g54_estado = 'R'
		WHERE g54_modulo  = vg_modulo
		  AND g54_proceso = vg_proceso
		  AND g54_estado  = 'A'
END IF
CALL funcion_master()

END MAIN



FUNCTION funcion_master()
DEFINE lin_menu		SMALLINT
DEFINE row_ini  	SMALLINT
DEFINE num_rows 	SMALLINT
DEFINE num_cols 	SMALLINT

CALL fl_nivel_isolation()
IF num_args() = 4 THEN
	CALL fl_chequeo_mes_proceso_rep(vg_codcia) RETURNING int_flag 
	IF int_flag THEN
		RETURN
	END IF
END IF
CALL fl_lee_compania_repuestos(vg_codcia) RETURNING rm_r00.*
LET vm_max_rows = 10000
IF num_args() = 7 THEN
	CALL ejecutar_refacturacion_automatica()
	EXIT PROGRAM
END IF
LET lin_menu    = 0
LET row_ini     = 3
LET num_rows    = 21
LET num_cols    = 80
IF vg_gui = 0 THEN
	LET lin_menu = 1
	LET row_ini  = 4
	LET num_rows = 20
	LET num_cols = 78
END IF                  
OPEN WINDOW w_237 AT row_ini, 2 WITH num_rows ROWS, num_cols COLUMNS            
	ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE lin_menu,   
		  BORDER, MESSAGE LINE LAST - 1)                                
IF vg_gui = 1 THEN
	OPEN FORM f_237 FROM '../forms/repf237_1'
ELSE
	OPEN FORM f_237 FROM '../forms/repf237_1c'
END IF
DISPLAY FORM f_237
INITIALIZE rm_r88.* TO NULL
LET vm_num_rows    = 0
LET vm_row_current = 0
LET vm_reprocesar  = 1
CALL muestra_contadores()
MENU 'OPCIONES'
	BEFORE MENU	
		HIDE OPTION 'Reprocesar'
		HIDE OPTION 'Factura Origen'
		HIDE OPTION 'Nueva Factura'
		HIDE OPTION 'Avanzar'
		HIDE OPTION 'Retroceder'
		IF num_args() = 5 OR num_args() = 6 THEN
			HIDE OPTION 'Ingresar'
			HIDE OPTION 'Consultar'
			SHOW OPTION 'Factura Origen'
			SHOW OPTION 'Nueva Factura'
			CASE num_args()
				WHEN 5
					LET rm_r88.r88_ord_trabajo = arg_val(5)
				WHEN 6
					LET rm_r88.r88_cod_fact = arg_val(5)
					LET rm_r88.r88_num_fact = arg_val(6)
			END CASE
                	CALL control_consulta()
			IF vm_num_rows > 1 THEN
				SHOW OPTION 'Avanzar'
			END IF
		END IF
	COMMAND KEY('I') 'Ingresar' 		'Ingresar nuevos registros.'
                CALL control_ingreso()
		IF vm_num_rows >= 1 THEN
			IF vm_reprocesar THEN
				SHOW OPTION 'Reprocesar'
			ELSE
				HIDE OPTION 'Reprocesar'
			END IF
			SHOW OPTION 'Factura Origen'
			IF rm_r88.r88_cod_fact_nue IS NOT NULL THEN
				SHOW OPTION 'Nueva Factura'
			END IF
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
			IF vm_num_rows = 1 THEN
				HIDE OPTION 'Avanzar'
				HIDE OPTION 'Retroceder'
			END IF
			IF vm_row_current = vm_num_rows THEN
				HIDE OPTION 'Avanzar'
			END IF
		END IF
        COMMAND KEY('C') 'Consultar'            'Consultar un registro.'
                CALL control_consulta()
                IF vm_num_rows <= 1 THEN
			HIDE OPTION 'Reprocesar'
			HIDE OPTION 'Factura Origen'
			HIDE OPTION 'Nueva Factura'
                        HIDE OPTION 'Avanzar'
                        HIDE OPTION 'Retroceder'
			IF vm_num_rows = 1 THEN
				IF vm_reprocesar THEN
					SHOW OPTION 'Reprocesar'
				ELSE
					HIDE OPTION 'Reprocesar'
				END IF
				SHOW OPTION 'Factura Origen'
				IF rm_r88.r88_cod_fact_nue IS NOT NULL THEN
					SHOW OPTION 'Nueva Factura'
				END IF 
			END IF 
                ELSE
			IF vm_reprocesar THEN
				SHOW OPTION 'Reprocesar'
			ELSE
				HIDE OPTION 'Reprocesar'
			END IF
			SHOW OPTION 'Factura Origen'
			IF rm_r88.r88_cod_fact_nue IS NOT NULL THEN
				SHOW OPTION 'Nueva Factura'
			END IF
                        SHOW OPTION 'Avanzar'
                END IF
	COMMAND KEY('P') 'Reprocesar'		'Solo si no hay Nueva Factura.'
		CALL ejecuta_proceso_refacturacion()
		IF vm_reprocesar THEN
			SHOW OPTION 'Reprocesar'
		ELSE
			HIDE OPTION 'Reprocesar'
			IF rm_r88.r88_cod_fact_nue IS NOT NULL THEN
				SHOW OPTION 'Nueva Factura'
				CALL fl_mostrar_mensaje('Proceso de Refacturación Terminado Ok.','info')
			END IF
		END IF
	COMMAND KEY('F') 'Factura Origen' 	'Ver Factura Original.'
		IF vm_num_rows > 0 THEN
			CALL control_ver_factura(rm_r88.r88_cod_fact,
							rm_r88.r88_num_fact)
		ELSE 
			CALL fl_mensaje_consultar_primero()
		END IF
	COMMAND KEY('N') 'Nueva Factura' 	'Ver Nueva Factura Generada.'
		IF vm_num_rows > 0 THEN
			CALL control_ver_factura(rm_r88.r88_cod_fact_nue,
							rm_r88.r88_num_fact_nue)
		ELSE 
			CALL fl_mensaje_consultar_primero()
		END IF
	COMMAND KEY('A') 'Avanzar' 		'Ver siguiente registro.'
		HIDE OPTION 'Reprocesar'
		HIDE OPTION 'Factura Origen'
		HIDE OPTION 'Nueva Factura'
		CALL siguiente_registro()
		IF vm_row_current = vm_num_rows THEN
			HIDE OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
			NEXT OPTION 'Retroceder'
		ELSE
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
		END IF
		IF vm_reprocesar THEN
			SHOW OPTION 'Reprocesar'
		ELSE
			HIDE OPTION 'Reprocesar'
		END IF
		SHOW OPTION 'Factura Origen'
		IF rm_r88.r88_cod_fact_nue IS NOT NULL THEN
			SHOW OPTION 'Nueva Factura'
		END IF
	COMMAND KEY('R') 'Retroceder' 		'Ver anterior registro.'
		HIDE OPTION 'Reprocesar'
		HIDE OPTION 'Factura Origen'
		HIDE OPTION 'Nueva Factura'
		CALL anterior_registro()
		IF vm_row_current = 1 THEN
			HIDE OPTION 'Retroceder'
			SHOW OPTION 'Avanzar'
			NEXT OPTION 'Avanzar'
		ELSE
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
		END IF
		IF vm_reprocesar THEN
			SHOW OPTION 'Reprocesar'
		ELSE
			HIDE OPTION 'Reprocesar'
		END IF
		SHOW OPTION 'Factura Origen'
		IF rm_r88.r88_cod_fact_nue IS NOT NULL THEN
			SHOW OPTION 'Nueva Factura'
		END IF
	COMMAND KEY('S') 'Salir'    		'Salir del programa.'
		EXIT MENU
END MENU

END FUNCTION



FUNCTION ejecutar_refacturacion_automatica()
DEFINE r_z01		RECORD LIKE cxct001.*
DEFINE r_r01		RECORD LIKE rept001.*
DEFINE r_r19		RECORD LIKE rept019.*
DEFINE r_r21		RECORD LIKE rept021.*
DEFINE r_r23		RECORD LIKE rept023.*
DEFINE r_r88		RECORD LIKE rept088.*
DEFINE r_t23		RECORD LIKE talt023.*
DEFINE resul		SMALLINT
DEFINE mensaje		VARCHAR(250)

DECLARE q_vend_a CURSOR FOR
	SELECT * FROM rept001
		WHERE r01_compania   = vg_codcia
		  AND r01_user_owner = vg_usuario
OPEN q_vend_a
FETCH q_vend_a INTO r_r01.*
IF STATUS = NOTFOUND THEN
	CLOSE q_vend_a
	FREE q_vend_a
	CALL fl_mostrar_mensaje('El usuario ' || vg_usuario CLIPPED || ' no esta configurado como Vendedor/Bodeguero y no puede continuar con este proceso.','exclamation')
	RETURN
END IF
CLOSE q_vend_a
FREE q_vend_a
INITIALIZE rm_r88.* TO NULL
LET rm_r88.r88_compania  = vg_codcia
LET rm_r88.r88_localidad = vg_codloc
LET rm_r88.r88_cod_fact  = arg_val(5)
LET rm_r88.r88_num_fact  = arg_val(6)
LET rm_r88.r88_usuario   = vg_usuario
CALL lee_registro_refact(rm_r88.r88_cod_fact, rm_r88.r88_num_fact)
	RETURNING r_r88.*
CALL fl_lee_cabecera_transaccion_rep(vg_codcia, vg_codloc, rm_r88.r88_cod_fact,
					rm_r88.r88_num_fact)
	RETURNING r_r19.*
IF r_r19.r19_compania IS NULL THEN
	LET mensaje = 'La Factura ', rm_r88.r88_num_fact USING "<<<<<<&",
			' no existe en la Compañía.'
	CALL fl_mostrar_mensaje(mensaje, 'stop')
	EXIT PROGRAM
END IF
IF NOT validar_caja() THEN
	LET int_flag = 1
	EXIT PROGRAM
END IF
IF DATE(r_r19.r19_fecing) + rm_r00.r00_dias_dev < TODAY THEN
	LET mensaje = 'La Factura ', rm_r88.r88_num_fact USING "<<<<<<&",
			' no puede ser Refacturada porque supero el plazo',
			' para su devolución.'
	CALL fl_mostrar_mensaje(mensaje, 'stop')
	EXIT PROGRAM
END IF
IF r_r19.r19_tipo_dev IS NOT NULL AND rm_r88.r88_cod_fact_nue IS NOT NULL THEN
	LET mensaje = 'La Factura ', rm_r88.r88_num_fact USING "<<<<<<&",
			' no puede ser Refacturada porque ha sido parcial',
			' o totalmente Devuelta/Anulada.'
	CALL fl_mostrar_mensaje(mensaje, 'stop')
	EXIT PROGRAM
END IF
IF r_r19.r19_ord_trabajo IS NULL THEN
	LET mensaje = 'La Factura ', rm_r88.r88_num_fact USING "<<<<<<&",
			' no puede ser Refacturada porque no pertenece a una',
			' Orden de Trabajo. Hagalo por Inventario.'
	CALL fl_mostrar_mensaje(mensaje, 'stop')
	EXIT PROGRAM
END IF
LET rm_r88.r88_ord_trabajo = r_r19.r19_ord_trabajo
INITIALIZE rm_t60.* TO NULL
SELECT * INTO rm_t60.*
	FROM talt060
	WHERE t60_compania  = rm_r88.r88_compania
	  AND t60_localidad = rm_r88.r88_localidad
	  AND t60_ot_ant    = rm_r88.r88_ord_trabajo
CALL fl_lee_orden_trabajo(rm_t60.t60_compania, rm_t60.t60_localidad,
				rm_t60.t60_ot_ant)
	RETURNING r_t23.*
IF r_t23.t23_estado = 'E' THEN
	LET mensaje = 'La Factura ', rm_r88.r88_num_fact USING "<<<<<<&",
			' pertenece a la Orden de Trabajo ',
			r_t23.t23_orden USING "<<<<<<<&",
			' que esta Eliminada.'
	CALL fl_mostrar_mensaje(mensaje, 'stop')
	EXIT PROGRAM
END IF
IF r_t23.t23_num_factura IS NULL THEN
	LET mensaje = 'La Factura ', rm_r88.r88_num_fact USING "<<<<<<&",
			' pertenece a la Orden de Trabajo ',
			r_t23.t23_orden USING "<<<<<<<&",
			' que no tiene número de factura.'
	CALL fl_mostrar_mensaje(mensaje, 'stop')
	EXIT PROGRAM
END IF
LET rm_r88.r88_motivo_refact = rm_t60.t60_motivo_refact
LET rm_r88.r88_codcli_nue    = rm_t60.t60_codcli_nue
LET rm_r88.r88_nomcli_nue    = rm_t60.t60_nomcli_nue
CALL fl_lee_cliente_general(rm_r88.r88_codcli_nue) RETURNING r_z01.*
IF r_z01.z01_codcli IS NOT NULL THEN
	IF r_z01.z01_estado = 'B' THEN
		CALL fl_mensaje_estado_bloqueado()
		EXIT PROGRAM
	END IF
	CALL validar_cedruc(r_z01.z01_codcli, r_z01.z01_num_doc_id,
				r_z01.z01_tipo_doc_id)
		RETURNING resul
	IF NOT resul THEN
		EXIT PROGRAM
	END IF
END IF
CALL lee_registro_refact(rm_r88.r88_cod_fact, rm_r88.r88_num_fact)
	RETURNING r_r88.*
IF r_r88.r88_compania IS NOT NULL AND rm_r88.r88_cod_fact_nue IS NOT NULL THEN
	LET mensaje = 'La Factura ', r_r88.r88_num_fact USING "<<<<<<&",
			' ya fue Refacturada.'
	CALL fl_mostrar_mensaje(mensaje, 'stop')
	EXIT PROGRAM
END IF
IF rm_r88.r88_motivo_refact IS NULL THEN
	CALL fl_mostrar_mensaje('Debe ingresar motivo de la Refacturación.', 'stop')
	EXIT PROGRAM
END IF
CALL fl_lee_cabecera_transaccion_rep(vg_codcia, vg_codloc, rm_r88.r88_cod_fact,
					rm_r88.r88_num_fact)
	RETURNING r_r19.*
IF r_r19.r19_codcli = rm_r00.r00_codcli_tal THEN
	IF rm_r88.r88_codcli_nue IS NULL THEN
		CALL fl_mostrar_mensaje('El codigo cliente de la factura es el Consumidor Final. Haga una Refacturación por cambio de Razón Social.', 'stop')
		EXIT PROGRAM
	END IF
END IF
INITIALIZE r_r23.* TO NULL
SELECT * INTO r_r23.* FROM rept023
	WHERE r23_compania  = vg_codcia
	  AND r23_localidad = vg_codloc
	  AND r23_cod_tran  = rm_r88.r88_cod_fact
	  AND r23_num_tran  = rm_r88.r88_num_fact
IF r_r23.r23_compania IS NULL THEN
	LET mensaje = 'No existe ninguna Pre-Venta asociada a la Factura ',
			rm_r88.r88_num_fact USING "<<<<<<&", '.'
	CALL fl_mostrar_mensaje(mensaje, 'stop')
	EXIT PROGRAM
END IF
LET rm_r88.r88_numprev = r_r23.r23_numprev
CALL fl_lee_proforma_rep(r_r23.r23_compania, r_r23.r23_localidad,
				r_r23.r23_numprof)
	RETURNING r_r21.*
IF r_r21.r21_compania IS NULL THEN
	LET mensaje = 'No existe ninguna Proforma asociada a la Factura ',
			rm_r88.r88_num_fact USING "<<<<<<&", '.'
	CALL fl_mostrar_mensaje(mensaje, 'stop')
	EXIT PROGRAM
END IF
LET rm_r88.r88_numprof = r_r21.r21_numprof
LET rm_r88.r88_fecing  = CURRENT
BEGIN WORK
	IF r_r88.r88_cod_fact IS NULL THEN
		INSERT INTO rept088 VALUES (rm_r88.*)
	END IF
COMMIT WORK
CALL ejecuta_proceso_refacturacion()
IF NOT vm_reprocesar THEN
	LET mensaje = 'Refacturación de Factura ',
			rm_r88.r88_num_fact USING "<<<<<<&", ' Ok.'
	CALL fl_mostrar_mensaje(mensaje, 'info')
END IF

END FUNCTION



FUNCTION control_ingreso()
DEFINE num_aux		INTEGER
DEFINE r_r01		RECORD LIKE rept001.*

DECLARE q_vend CURSOR FOR
	SELECT * FROM rept001
		WHERE r01_compania   = vg_codcia
		  AND r01_user_owner = vg_usuario
OPEN q_vend
FETCH q_vend INTO r_r01.*
IF STATUS = NOTFOUND THEN
	CLOSE q_vend
	FREE q_vend
	CALL fl_mostrar_mensaje('El usuario ' || vg_usuario CLIPPED || ' no esta configurado como Vendedor/Bodeguero y no puede continuar con este proceso.','exclamation')
	RETURN
END IF
CLOSE q_vend
FREE q_vend
CLEAR FORM
INITIALIZE rm_r88.* TO NULL
LET rm_r88.r88_compania  = vg_codcia
LET rm_r88.r88_localidad = vg_codloc
LET rm_r88.r88_cod_fact  = "FA"
LET rm_r88.r88_usuario   = vg_usuario
LET rm_r88.r88_fecing    = CURRENT
DISPLAY BY NAME rm_r88.r88_cod_fact, rm_r88.r88_usuario, rm_r88.r88_fecing
CALL lee_datos()
IF NOT int_flag THEN
	LET rm_r88.r88_fecing = CURRENT
	BEGIN WORK
		INSERT INTO rept088 VALUES (rm_r88.*)
		LET num_aux = SQLCA.SQLERRD[6]
	COMMIT WORK
	CALL ejecuta_proceso_refacturacion()
	IF vm_num_rows = vm_max_rows THEN
		LET vm_num_rows  = 1
	ELSE
		LET vm_num_rows  = vm_num_rows + 1
	END IF
	LET vm_rows[vm_num_rows] = num_aux
	LET vm_row_current       = vm_num_rows
	CALL lee_muestra_registro(vm_rows[vm_row_current])
	IF NOT vm_reprocesar THEN
		CALL fl_mostrar_mensaje('Proceso de Refacturación Terminado Ok.','info')
	END IF
	RETURN
END IF
CLEAR FORM
IF vm_num_rows > 0 THEN
	CALL lee_muestra_registro(vm_rows[vm_row_current])
END IF

END FUNCTION



FUNCTION control_consulta()
DEFINE expr_sql		CHAR(800)
DEFINE query		CHAR(1500)
DEFINE r_z01		RECORD LIKE cxct001.*
DEFINE r_r88		RECORD LIKE rept088.*
DEFINE r_t23		RECORD LIKE talt023.*
DEFINE mensaje		VARCHAR(100)

CLEAR FORM
LET rm_r88.r88_cod_fact = "FA"
IF num_args() = 4 THEN
	DISPLAY BY NAME rm_r88.r88_cod_fact
	LET int_flag = 0
	CONSTRUCT BY NAME expr_sql ON r88_num_fact, r88_num_fact_nue,
			r88_codcli_nue, r88_nomcli_nue, r88_motivo_refact,
			r88_ord_trabajo, r88_usuario
	        ON KEY(F1,CONTROL-W)
			CALL llamar_visor_teclas()
		ON KEY(F2)
			IF INFIELD(r88_num_fact) THEN
				CALL fl_ayuda_refacturacion_rep(vg_codcia,
								vg_codloc)
					RETURNING r_r88.r88_cod_fact, 
						  r_r88.r88_num_fact,
						  r_r88.r88_num_fact_nue
			      	IF r_r88.r88_num_fact IS NOT NULL THEN
					LET rm_r88.r88_cod_fact =
							r_r88.r88_cod_fact
					LET rm_r88.r88_num_fact =
							r_r88.r88_num_fact
					LET rm_r88.r88_num_fact_nue =
							r_r88.r88_num_fact_nue
					DISPLAY BY NAME rm_r88.r88_cod_fact, 
							rm_r88.r88_num_fact,
							rm_r88.r88_num_fact_nue
			      	END IF
			END IF
			IF INFIELD(r88_num_fact_nue) THEN
				CALL fl_ayuda_refacturacion_rep(vg_codcia,
								vg_codloc)
					RETURNING r_r88.r88_cod_fact, 
						  r_r88.r88_num_fact,
						  r_r88.r88_num_fact_nue
			      	IF r_r88.r88_num_fact IS NOT NULL THEN
					LET rm_r88.r88_cod_fact =
							r_r88.r88_cod_fact
					LET rm_r88.r88_num_fact =
							r_r88.r88_num_fact
					LET rm_r88.r88_num_fact_nue =
							r_r88.r88_num_fact_nue
					DISPLAY BY NAME rm_r88.r88_cod_fact, 
							rm_r88.r88_num_fact,
							rm_r88.r88_num_fact_nue
			      	END IF
			END IF
                	IF INFIELD(r88_codcli_nue) THEN
	                        CALL fl_ayuda_cliente_localidad(vg_codcia,
								vg_codloc)
        	                        RETURNING r_z01.z01_codcli,
						  r_z01.z01_nomcli
                	        IF r_z01.z01_codcli IS NOT NULL THEN
                        	        LET rm_r88.r88_codcli_nue =
								r_z01.z01_codcli
                                	LET rm_r88.r88_nomcli_nue =
								r_z01.z01_nomcli
	                                DISPLAY BY NAME rm_r88.r88_codcli_nue,
        	                                        rm_r88.r88_nomcli_nue
                	        END IF
	                END IF
			IF INFIELD(r88_ord_trabajo) THEN
				CALL fl_ayuda_orden_trabajo(vg_codcia,
								vg_codloc, 'D')
					RETURNING r_t23.t23_orden,
						  r_t23.t23_nom_cliente
				IF r_t23.t23_orden IS NOT NULL THEN
					LET rm_r88.r88_ord_trabajo =
								r_t23.t23_orden
					DISPLAY BY NAME rm_r88.r88_ord_trabajo
				END IF
			END IF
			LET int_flag = 0
		BEFORE CONSTRUCT
			--#CALL dialog.keysetlabel("F1","")
			--#CALL dialog.keysetlabel("CONTROL-W","")
	END CONSTRUCT
	IF int_flag THEN
		CLEAR FORM
		IF vm_num_rows > 0 THEN
			CALL lee_muestra_registro(vm_rows[vm_row_current])
		END IF
		RETURN
	END IF
ELSE
	LET expr_sql = ' r88_num_fact  = ', rm_r88.r88_num_fact
	IF num_args() = 5 THEN
		LET expr_sql = ' r88_ord_trabajo = ', rm_r88.r88_ord_trabajo
	END IF
END IF
LET query = 'SELECT *, ROWID FROM rept088 ',
		' WHERE r88_compania  =  ', vg_codcia,
		'   AND r88_localidad =  ', vg_codloc,
		'   AND r88_cod_fact  = "', rm_r88.r88_cod_fact, '"',
		'   AND ', expr_sql CLIPPED,
		' ORDER BY r88_num_fact_nue, r88_num_fact ' 
PREPARE cons FROM query
DECLARE q_cons CURSOR FOR cons
LET vm_num_rows = 1
FOREACH q_cons INTO rm_r88.*, vm_rows[vm_num_rows]
	LET vm_num_rows = vm_num_rows + 1
        IF vm_num_rows > vm_max_rows THEN
		EXIT FOREACH
	END IF	
END FOREACH 
LET vm_num_rows = vm_num_rows - 1
IF vm_num_rows = 0 THEN 
	CALL fl_mensaje_consulta_sin_registros()
	IF num_args() <> 4 THEN
		EXIT PROGRAM
	END IF
	LET vm_num_rows    = 0
	LET vm_row_current = 0
	CALL muestra_contadores()
	CLEAR FORM
	RETURN
END IF
LET vm_row_current = 1
CALL lee_muestra_registro(vm_rows[vm_row_current])

END FUNCTION



FUNCTION lee_datos()
DEFINE resp 		CHAR(6)
DEFINE resul		SMALLINT
DEFINE cambiar_cli	SMALLINT
DEFINE deuda		DECIMAL(14,2)
DEFINE r_r19		RECORD LIKE rept019.*
DEFINE r_r21		RECORD LIKE rept021.*
DEFINE r_r23		RECORD LIKE rept023.*
DEFINE r_r88		RECORD LIKE rept088.*
DEFINE r_z01		RECORD LIKE cxct001.*
DEFINE num_fact		LIKE rept088.r88_num_fact
DEFINE codcli_nue	LIKE rept088.r88_codcli_nue

LET int_flag = 0
INPUT BY NAME rm_r88.r88_num_fact, rm_r88.r88_codcli_nue,
	rm_r88.r88_motivo_refact
	WITHOUT DEFAULTS
	ON KEY (INTERRUPT)
        	IF FIELD_TOUCHED(rm_r88.r88_num_fact, rm_r88.r88_codcli_nue,
				 rm_r88.r88_motivo_refact)
		THEN
			LET int_flag = 0
			CALL fl_mensaje_abandonar_proceso() RETURNING resp
			IF resp = 'Yes' THEN
				LET int_flag = 1
				RETURN
			END IF
		ELSE
			RETURN
		END IF
        ON KEY(F1,CONTROL-W)
		CALL control_visor_teclas_caracter_1() 
	ON KEY(F2)
		IF INFIELD(r88_num_fact) THEN
			CALL fl_ayuda_transaccion_rep(vg_codcia, vg_codloc,
						      rm_r88.r88_cod_fact)
				RETURNING r_r19.r19_cod_tran, 
					  r_r19.r19_num_tran,
					  r_r19.r19_nomcli
		      	IF r_r19.r19_num_tran IS NOT NULL THEN
				CALL fl_lee_cabecera_transaccion_rep(vg_codcia,
							vg_codloc,
							rm_r88.r88_cod_fact,
							r_r19.r19_num_tran)
					RETURNING r_r19.*
				LET rm_r88.r88_cod_fact = r_r19.r19_cod_tran
				LET rm_r88.r88_num_fact = r_r19.r19_num_tran
				DISPLAY BY NAME rm_r88.r88_num_fact,
						r_r19.r19_codcli,
						r_r19.r19_nomcli
		      	END IF
		END IF
                IF INFIELD(r88_codcli_nue) THEN
                        CALL fl_ayuda_cliente_localidad(vg_codcia, vg_codloc)
                                RETURNING r_z01.z01_codcli, r_z01.z01_nomcli
                        IF r_z01.z01_codcli IS NOT NULL THEN
                                LET rm_r88.r88_codcli_nue = r_z01.z01_codcli
                                LET rm_r88.r88_nomcli_nue = r_z01.z01_nomcli
                                DISPLAY BY NAME rm_r88.r88_codcli_nue,
                                                rm_r88.r88_nomcli_nue
                        END IF
                END IF
		LET int_flag = 0
	ON KEY(F5)
		IF INFIELD(r88_num_fact) THEN
			IF rm_r88.r88_num_fact IS NOT NULL THEN
				CALL control_ver_factura(rm_r88.r88_cod_fact,
							rm_r88.r88_num_fact)
			END IF
		END IF
	BEFORE INPUT
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
	BEFORE FIELD r88_num_fact
		LET num_fact = rm_r88.r88_num_fact
        BEFORE FIELD r88_codcli_nue
		LET codcli_nue = rm_r88.r88_codcli_nue
	AFTER FIELD r88_num_fact
		IF rm_r88.r88_num_fact IS NULL THEN
			NEXT FIELD r88_num_fact
		END IF
		IF rm_r88.r88_num_fact IS NOT NULL THEN
			CALL fl_lee_cabecera_transaccion_rep(vg_codcia,
						vg_codloc, rm_r88.r88_cod_fact,
						rm_r88.r88_num_fact)
				RETURNING r_r19.*
                	IF r_r19.r19_num_tran IS NULL THEN
				CALL fl_mostrar_mensaje('La Factura no existe en la Compañía.', 'exclamation')
                        	NEXT FIELD r88_num_fact
			END IF
			{--
			IF tiene_cruce() THEN
				CALL fl_mostrar_mensaje('La Factura no puede ser refacturada, porque existe un problema tecnico con el CRUCE AUTOMATICO DE STOCK. Por favor llame al Administrador para mayor informacion.', 'exclamation')
				NEXT FIELD r88_num_fact
			END IF
			--}
			IF NOT factura_sin_stock() THEN
				CALL fl_mostrar_mensaje('No se puede REFACTURAR esta Factura debido a que tiene en su detalle algun item con la Bodega SIN STOCK.', 'exclamation')
				NEXT FIELD r88_num_fact
			END IF
			IF NOT validar_caja() THEN
				LET int_flag = 1
				RETURN
			END IF
			IF DATE(r_r19.r19_fecing) + rm_r00.r00_dias_dev < TODAY
			THEN
				CALL fl_mostrar_mensaje('La Factura no puede ser Refacturada porque supero el plazo para su devolución.', 'exclamation')
				NEXT FIELD r88_num_fact
			END IF
			IF r_r19.r19_tipo_dev IS NOT NULL THEN
				CALL fl_mostrar_mensaje('La Factura no puede ser Refacturada porque ha sido parcial o totalmente Devuelta/Anulada.', 'exclamation')
				NEXT FIELD r88_num_fact
			END IF
			IF r_r19.r19_ord_trabajo IS NOT NULL THEN
				CALL fl_mostrar_mensaje('La Factura no puede ser Refacturada porque pertenece a una Orden de Trabajo.', 'exclamation')
				NEXT FIELD r88_num_fact
			END IF
			CALL fl_lee_cliente_general(r_r19.r19_codcli)
				RETURNING r_z01.*
			IF r_z01.z01_paga_impto = 'S' AND
			   r_r19.r19_porc_impto = 0
			THEN
				CALL fl_mostrar_mensaje('No puede Refacturar esta factura, porque no tiene IVA y el cliente esta configurado para calcular pago de impuestos.', 'exclamation')
				CONTINUE INPUT
			END IF
			DISPLAY BY NAME	r_r19.r19_codcli, r_r19.r19_nomcli
			IF r_r19.r19_cont_cred = 'R' THEN
				SELECT NVL(SUM((z20_valor_cap + z20_valor_int) -
					(z20_saldo_cap + z20_saldo_int)), 0)
					INTO deuda
					FROM cxct020
					WHERE z20_compania  = r_r19.r19_compania
					  AND z20_localidad =r_r19.r19_localidad
					  AND z20_codcli    = r_r19.r19_codcli
					  AND z20_tipo_doc  = r_r19.r19_cod_tran
					  AND z20_cod_tran  = r_r19.r19_cod_tran
					  AND z20_num_tran  = r_r19.r19_num_tran
				IF deuda <> 0 THEN
					CALL fl_mostrar_mensaje('Esta factura no puede ser REFACTURADA, porque ha sido parcial o totalmente cancelada.', 'exclamation')
					NEXT FIELD r88_num_fact
				END IF
			END IF
			IF num_fact IS NULL OR num_fact <> rm_r88.r88_num_fact
			THEN
				CALL fl_hacer_pregunta('Desea Refacturar por cambio de RAZON SOCIAL ?', 'No')
					RETURNING resp
                		LET rm_r88.r88_codcli_nue = NULL
	                	LET rm_r88.r88_nomcli_nue = NULL
        	        	DISPLAY BY NAME rm_r88.r88_codcli_nue,
						rm_r88.r88_nomcli_nue
				LET cambiar_cli = 1
				LET rm_r88.r88_motivo_refact =
					"POR CAMBIO DE RAZON SOCIAL"
				IF resp <> 'Yes' THEN
					LET cambiar_cli = 0
					IF rm_r88.r88_motivo_refact IS NULL OR
					   rm_r88.r88_motivo_refact =
						"POR CAMBIO DE RAZON SOCIAL"
					THEN
						LET rm_r88.r88_motivo_refact =
							"REFACTURACION POR SRI"
					END IF
					DISPLAY BY NAME rm_r88.r88_motivo_refact
					NEXT FIELD r88_motivo_refact
				END IF
				DISPLAY BY NAME rm_r88.r88_motivo_refact
				IF FIELD_TOUCHED(rm_r88.r88_motivo_refact) THEN
					IF cambiar_cli THEN
						NEXT FIELD r88_codcli_nue
					END IF
				END IF
			END IF
		ELSE
			CLEAR r19_codcli, r19_nomcli
		END IF
	AFTER FIELD r88_codcli_nue
		IF NOT cambiar_cli THEN
                	LET rm_r88.r88_codcli_nue = NULL
                	LET rm_r88.r88_nomcli_nue = NULL
                	DISPLAY BY NAME rm_r88.r88_codcli_nue,
					rm_r88.r88_nomcli_nue
			CONTINUE INPUT
		END IF
		IF rm_r88.r88_codcli_nue IS NULL THEN
                	LET rm_r88.r88_codcli_nue = codcli_nue
			CALL fl_lee_cliente_general(rm_r88.r88_codcli_nue)
				RETURNING r_z01.*
			LET rm_r88.r88_nomcli_nue = r_z01.z01_nomcli
                	DISPLAY BY NAME rm_r88.r88_codcli_nue,
					rm_r88.r88_nomcli_nue
		ELSE
			CALL fl_lee_cliente_general(rm_r88.r88_codcli_nue)
				RETURNING r_z01.*
			IF r_z01.z01_codcli IS NULL THEN
				CALL fl_mostrar_mensaje('Cliente no existe.', 'exclamation')
				NEXT FIELD r88_codcli_nue
			END IF
			IF r_z01.z01_estado = 'B' THEN
				CALL fl_mensaje_estado_bloqueado()
				NEXT FIELD r88_codcli_nue
			END IF
			IF rm_r88.r88_codcli_nue = rm_r00.r00_codcli_tal THEN
				CALL fl_mostrar_mensaje('El codigo del cliente para Refacturar no puede ser el Consumidor Final.', 'exclamation')
				NEXT FIELD r88_codcli_nue
			END IF
			LET rm_r88.r88_nomcli_nue = r_z01.z01_nomcli
        	       	DISPLAY BY NAME rm_r88.r88_codcli_nue,
					rm_r88.r88_nomcli_nue
			CALL validar_cedruc(r_z01.z01_codcli,
						r_z01.z01_num_doc_id,
						r_z01.z01_tipo_doc_id)
				RETURNING resul
			IF NOT resul THEN
				NEXT FIELD r88_codcli_nue
			END IF
                END IF
		IF r_z01.z01_paga_impto = 'S' AND r_r19.r19_porc_impto = 0 THEN
			CALL fl_mostrar_mensaje('No puede Refacturar esta factura, porque no tiene IVA y el cliente esta configurado para calcular pago de impuestos.', 'exclamation')
			CONTINUE INPUT
		END IF
	AFTER INPUT
		CALL lee_registro_refact(rm_r88.r88_cod_fact,
					 rm_r88.r88_num_fact)
			RETURNING r_r88.*
		IF r_r88.r88_compania IS NOT NULL THEN
			CALL fl_mostrar_mensaje('Esta Factura ya fue Refacturada.', 'exclamation')
			NEXT FIELD r88_num_fact
		END IF
		IF rm_r88.r88_motivo_refact IS NULL THEN
			CALL fl_mostrar_mensaje('Debe ingresar motivo de la Refacturación.', 'exclamation')
			NEXT FIELD r88_motivo_refact
		END IF
		CALL fl_lee_cabecera_transaccion_rep(vg_codcia,
						vg_codloc, rm_r88.r88_cod_fact,
						rm_r88.r88_num_fact)
			RETURNING r_r19.*
		IF r_r19.r19_codcli = rm_r00.r00_codcli_tal THEN
			IF rm_r88.r88_codcli_nue IS NULL THEN
				CALL fl_mostrar_mensaje('El codigo cliente de la factura es el Consumidor Final. Haga una Refacturación por cambio de Razón Social.', 'exclamation')
				NEXT FIELD r88_codcli_nue
			END IF
		END IF
		IF cambiar_cli THEN
			IF rm_r88.r88_codcli_nue IS NULL THEN
				CALL fl_mostrar_mensaje('Debe ingresar el codigo de cliente para la Nueva Factura, ya que es una Refacturación por cambio de Razón Social.', 'exclamation')
				NEXT FIELD r88_codcli_nue
			END IF
		END IF
		IF NOT sujeto_de_credito(rm_r88.r88_codcli_nue)	THEN
			CONTINUE INPUT
		END IF
		IF control_saldos_vencidos(vg_codcia, rm_r88.r88_codcli_nue, 0)
		THEN
			CONTINUE INPUT
		END IF
		INITIALIZE r_r23.* TO NULL
		SELECT * INTO r_r23.* FROM rept023
			WHERE r23_compania  = vg_codcia
			  AND r23_localidad = vg_codloc
			  AND r23_cod_tran  = rm_r88.r88_cod_fact
			  AND r23_num_tran  = rm_r88.r88_num_fact
		IF r_r23.r23_compania IS NULL THEN
			CALL fl_mostrar_mensaje('No existe ninguna Pre-Venta asociada a esta Factura.', 'stop')
			EXIT PROGRAM
		END IF
		LET rm_r88.r88_numprev = r_r23.r23_numprev
		CALL fl_lee_proforma_rep(r_r23.r23_compania,
					 r_r23.r23_localidad, r_r23.r23_numprof)
			RETURNING r_r21.*
		IF r_r21.r21_compania IS NULL THEN
			CALL fl_mostrar_mensaje('No existe ninguna Proforma asociada a esta Factura.', 'stop')
			EXIT PROGRAM
		END IF
		LET rm_r88.r88_numprof = r_r21.r21_numprof
END INPUT

END FUNCTION



FUNCTION validar_cedruc(codcli, cedruc, tipo_doc_id)
DEFINE codcli		LIKE cxct001.z01_codcli
DEFINE cedruc		LIKE cxct001.z01_num_doc_id
DEFINE tipo_doc_id	LIKE cxct001.z01_tipo_doc_id
DEFINE r_z01		RECORD LIKE cxct001.*
DEFINE cont		INTEGER
DEFINE resul		SMALLINT

SELECT COUNT(*) INTO cont FROM cxct001 WHERE z01_num_doc_id = cedruc
CASE cont
	WHEN 0
		LET resul = 1
	WHEN 1
		INITIALIZE r_z01.* TO NULL
		DECLARE q_cedruc CURSOR FOR
			SELECT * FROM cxct001 WHERE z01_num_doc_id = cedruc
		OPEN q_cedruc
		FETCH q_cedruc INTO r_z01.*
		CLOSE q_cedruc
		FREE q_cedruc
		LET resul = 1
		IF r_z01.z01_codcli <> codcli OR codcli IS NULL THEN
			CALL fl_mostrar_mensaje('Este número de identificación ya existe.','exclamation')
			LET resul = 0
		END IF
	OTHERWISE
		CALL fl_mostrar_mensaje('Este número de identificación ya existe varias veces.','exclamation')
		LET resul = 0
END CASE
IF cont <= 1 THEN
	IF tipo_doc_id = 'C' OR tipo_doc_id = 'R' THEN
		CALL fl_validar_cedruc_dig_ver(cedruc) RETURNING resul
	END IF
END IF
RETURN resul

END FUNCTION



FUNCTION lee_registro_refact(cod_fact, num_fact)
DEFINE cod_fact		LIKE rept088.r88_cod_fact
DEFINE num_fact		LIKE rept088.r88_num_fact
DEFINE r_r88		RECORD LIKE rept088.*

INITIALIZE r_r88.* TO NULL
SELECT * INTO r_r88.* FROM rept088
	WHERE r88_compania  = vg_codcia
	  AND r88_localidad = vg_codloc
	  AND r88_cod_fact  = cod_fact
	  AND r88_num_fact  = num_fact
RETURN r_r88.*

END FUNCTION



FUNCTION ejecuta_proceso_refacturacion()

LET vm_reprocesar = 1
CALL lee_registro_refact(rm_r88.r88_cod_fact, rm_r88.r88_num_fact)
	RETURNING rm_r88.*
IF rm_r88.r88_cod_dev IS NULL THEN
	CALL llamada_de_procesos(1, "REPUESTOS", vg_modulo, "repp217 ")
END IF
IF rm_r88.r88_cod_dev IS NULL THEN
	RETURN
END IF
IF rm_r88.r88_numprof_nue IS NULL OR rm_r88.r88_numprev_nue IS NULL THEN
	IF num_args() <> 7 THEN
		CALL llamada_de_procesos(2, "REPUESTOS", vg_modulo, "repp220 ")
	ELSE
		CALL llamada_de_procesos(2, "TALLER", "TA", "talp213 ")
	END IF
END IF
IF rm_r88.r88_numprof_nue IS NULL THEN
	RETURN
END IF
IF rm_r88.r88_numprev_nue IS NOT NULL THEN
	CALL llamada_de_procesos(3, "REPUESTOS", vg_modulo, "repp223 ")
	CALL llamada_de_procesos(4, "REPUESTOS", vg_modulo, "repp210 ")
END IF
IF rm_r88.r88_numprev_nue IS NULL THEN
	RETURN
END IF
IF rm_r88.r88_num_fact_nue IS NULL THEN
	IF rm_r88.r88_numprev_nue IS NOT NULL THEN
		CALL llamada_de_procesos(5, "CAJA", "CG", "cajp203 ")
	END IF
END IF
IF rm_r88.r88_num_fact_nue IS NULL THEN
	RETURN
END IF
CALL tiene_pendiente_nota_entrega() RETURNING vm_reprocesar
IF vm_reprocesar THEN
	CALL llamada_de_procesos(6, "REPUESTOS", vg_modulo, "repp231 ")
END IF
IF num_args() <> 7 THEN
	DISPLAY BY NAME rm_r88.r88_cod_fact_nue, rm_r88.r88_num_fact_nue
END IF

END FUNCTION



FUNCTION llamada_de_procesos(flag, modulo, mod, prog)
DEFINE flag		SMALLINT
DEFINE modulo		VARCHAR(15)
DEFINE mod		LIKE gent050.g50_modulo
DEFINE prog		VARCHAR(10)
DEFINE param		VARCHAR(60)
DEFINE r_r23		RECORD LIKE rept023.*
DEFINE r_r25		RECORD LIKE rept025.*
DEFINE cont		SMALLINT
DEFINE mensaje		VARCHAR(250)
DEFINE mensproc		VARCHAR(40)
DEFINE evento		DECIMAL(15,0)

CASE flag
	WHEN 1
		LET param    = '"', rm_r88.r88_cod_fact, '" ',
				 rm_r88.r88_num_fact CLIPPED, ' "A" '
		LET mensproc = "Devolución/Anulación."
	WHEN 2
		LET param    = rm_r88.r88_numprof, ' "A" '
		LET mensproc = "Proforma"
	WHEN 3
		LET param    = rm_r88.r88_numprev_nue
		LET mensproc = "Aprobación Pre-Venta."
	WHEN 4
		LET param    = rm_r88.r88_numprev_nue, ' "A" '
		LET mensproc = "Aprobación Crédito."
	WHEN 5
		LET param    = '"PR" ', rm_r88.r88_numprev_nue, ' "A" '
		LET mensproc = "Forma de Pago en Caja."
	WHEN 6
		LET param    = '"', rm_r88.r88_cod_fact_nue, '" ',
				rm_r88.r88_num_fact_nue CLIPPED, ' "A" '
		LET mensproc = "Nota de Entrega."
END CASE
LET cont = 0
WHILE TRUE
	LET mensaje = "Generando ", mensproc CLIPPED, " Por favor espere ..."
	ERROR mensaje
	CALL ejecuta_comando(modulo, mod, prog, param)
	ERROR '                                                                   '
	CALL lee_registro_refact(rm_r88.r88_cod_fact, rm_r88.r88_num_fact)
		RETURNING rm_r88.*
	LET evento = NULL
	CASE flag
		WHEN 1
			LET evento = rm_r88.r88_num_dev
		WHEN 2
			LET evento = rm_r88.r88_numprof_nue
		WHEN 3
			CALL fl_lee_preventa_rep(rm_r88.r88_compania,
						 rm_r88.r88_localidad,
						 rm_r88.r88_numprev_nue)
				RETURNING r_r23.*
			IF r_r23.r23_estado <> 'A' THEN
				LET evento = rm_r88.r88_numprev_nue
			END IF
		WHEN 4
			CALL fl_lee_cabecera_credito_rep(rm_r88.r88_compania,
							 rm_r88.r88_localidad,
							 rm_r88.r88_numprev_nue)
				RETURNING r_r25.*
			IF r_r25.r25_compania IS NOT NULL THEN
				LET evento = rm_r88.r88_numprev_nue
			END IF
		WHEN 5
			LET evento = rm_r88.r88_num_fact_nue
		WHEN 6
			CALL tiene_pendiente_nota_entrega()
				RETURNING vm_reprocesar
			IF NOT vm_reprocesar THEN
				LET evento = rm_r88.r88_num_fact_nue
			END IF
	END CASE
	IF evento IS NOT NULL THEN
		EXIT WHILE
	END IF
	LET cont    = cont + 1
	LET mensaje = "No se genera todavía la ", mensproc CLIPPED,
			" Por favor espere ..."
	ERROR mensaje
	IF cont > 2 THEN
		LET mensaje = "No se pudo Generar la ", mensproc CLIPPED,
				" Por Favor Intente con el botón REPROCESAR."
		CALL fl_mostrar_mensaje(mensaje, 'stop')
		EXIT WHILE
	END IF
END WHILE
CALL lee_registro_refact(rm_r88.r88_cod_fact, rm_r88.r88_num_fact)
	RETURNING rm_r88.*

END FUNCTION



FUNCTION tiene_pendiente_nota_entrega()
DEFINE resul		SMALLINT
DEFINE r_r34		RECORD LIKE rept034.*
DEFINE r_r35		RECORD LIKE rept035.*
DEFINE cant_pend_item	LIKE rept035.r35_cant_des
DEFINE cant_ord_old	LIKE rept035.r35_cant_des
DEFINE cant_ent_par	LIKE rept035.r35_cant_ent

DECLARE q_vernot CURSOR FOR
	SELECT * FROM rept034
		WHERE r34_compania  = rm_r88.r88_compania
		  AND r34_localidad = rm_r88.r88_localidad
		  AND r34_cod_tran  = rm_r88.r88_cod_fact
		  AND r34_num_tran  = rm_r88.r88_num_fact
		  AND r34_estado    NOT IN ("A", "E")
OPEN q_vernot
FETCH q_vernot
IF STATUS = NOTFOUND THEN
	CLOSE q_vernot
	FREE q_vernot
	RETURN 0
END IF
CLOSE q_vernot
FREE q_vernot
INITIALIZE r_r34.* TO NULL
DECLARE q_notent CURSOR FOR
	SELECT r34_bodega, r35_item, NVL(SUM(r35_cant_des - r35_cant_ent), 0)
		FROM rept034, rept035
		WHERE r34_compania     = rm_r88.r88_compania
		  AND r34_localidad    = rm_r88.r88_localidad
		  AND r34_cod_tran     = rm_r88.r88_cod_fact_nue
		  AND r34_num_tran     = rm_r88.r88_num_fact_nue
		  AND r34_estado       NOT IN ("D", "E")
		  AND r35_compania     = r34_compania
		  AND r35_localidad    = r34_localidad
		  AND r35_bodega       = r34_bodega
		  AND r35_num_ord_des  = r34_num_ord_des
		GROUP BY 1, 2
LET resul = 0
FOREACH q_notent INTO r_r34.r34_bodega, r_r35.r35_item, cant_pend_item
	CALL obtener_diferencia_od_old_sin_ne(r_r34.r34_bodega,r_r35.r35_item,1)
		RETURNING cant_ent_par
	IF cant_ent_par = 0 THEN
		CALL obtener_diferencia_od_old_sin_ne(r_r34.r34_bodega,
							r_r35.r35_item, 2)
			RETURNING cant_ord_old
		IF cant_ord_old = 0 THEN
			CONTINUE FOREACH
		END IF
	END IF
	IF cant_pend_item = cant_ent_par THEN
		CONTINUE FOREACH
	END IF
	LET resul = 1
	EXIT FOREACH
END FOREACH
RETURN resul

END FUNCTION



FUNCTION obtener_diferencia_od_old_sin_ne(bodega, item, flag)
DEFINE bodega		LIKE rept034.r34_bodega
DEFINE item		LIKE rept010.r10_codigo
DEFINE flag		SMALLINT
DEFINE cant_ent_par	LIKE rept035.r35_cant_ent
DEFINE query		CHAR(800)
DEFINE expr_var		VARCHAR(20)

LET expr_var = NULL
IF flag = 1 THEN
	LET expr_var = ' - r35_cant_ent'
END IF
LET query = 'SELECT NVL(SUM(r35_cant_des', expr_var CLIPPED, '), 0) ',
		'FROM rept034, rept035 ',
		'WHERE r34_compania    = ', rm_r88.r88_compania,
		'  AND r34_localidad   = ', rm_r88.r88_localidad,
		'  AND r34_bodega      = "', bodega, '"',
		'  AND r34_cod_tran    = "', rm_r88.r88_cod_fact, '"',
		'  AND r34_num_tran    = ', rm_r88.r88_num_fact,
		'  AND r34_estado      IN ("P", "D") ',
		'  AND r35_compania    = r34_compania ',
		'  AND r35_localidad   = r34_localidad ',
		'  AND r35_bodega      = r34_bodega ',
		'  AND r35_num_ord_des = r34_num_ord_des ',
		'  AND r35_item        = "', item CLIPPED, '"'
PREPARE cons_dif FROM query
DECLARE q_cons_dif CURSOR FOR cons_dif
OPEN q_cons_dif
FETCH q_cons_dif INTO cant_ent_par
CLOSE q_cons_dif
FREE q_cons_dif
RETURN cant_ent_par

END FUNCTION



FUNCTION lee_muestra_registro(row)
DEFINE row 		INTEGER
DEFINE r_r19		RECORD LIKE rept019.*

IF vm_num_rows <= 0 THEN
	RETURN
END IF
SELECT * INTO rm_r88.* FROM rept088 WHERE ROWID = row
IF STATUS = NOTFOUND THEN
	ERROR 'No existe registro con rowid', row
END IF
DISPLAY BY NAME rm_r88.r88_cod_fact, rm_r88.r88_num_fact,
		rm_r88.r88_cod_fact_nue, rm_r88.r88_num_fact_nue,
		rm_r88.r88_codcli_nue, rm_r88.r88_nomcli_nue,
		rm_r88.r88_motivo_refact, rm_r88.r88_ord_trabajo,
		rm_r88.r88_usuario, rm_r88.r88_fecing
CALL fl_lee_cabecera_transaccion_rep(vg_codcia, vg_codloc, rm_r88.r88_cod_fact,
					rm_r88.r88_num_fact)
	RETURNING r_r19.*
DISPLAY BY NAME r_r19.r19_codcli, r_r19.r19_nomcli
CALL muestra_contadores()
IF rm_r88.r88_num_fact_nue IS NOT NULL THEN
	CALL tiene_pendiente_nota_entrega() RETURNING vm_reprocesar
ELSE
	LET vm_reprocesar = 1
END IF

END FUNCTION



FUNCTION muestra_contadores()

DISPLAY BY NAME vm_row_current, vm_num_rows

END FUNCTION



FUNCTION siguiente_registro()

IF vm_row_current < vm_num_rows THEN
	LET vm_row_current = vm_row_current + 1
END IF
CALL lee_muestra_registro(vm_rows[vm_row_current])
CALL muestra_contadores()

END FUNCTION



FUNCTION anterior_registro()

IF vm_row_current > 1 THEN
	LET vm_row_current = vm_row_current - 1
END IF
CALL lee_muestra_registro(vm_rows[vm_row_current])
CALL muestra_contadores()

END FUNCTION



FUNCTION tiene_cruce()
DEFINE r_r41		RECORD LIKE rept041.*

INITIALIZE r_r41.* TO NULL
DECLARE q_tiene CURSOR FOR
	SELECT UNIQUE b.*
		FROM rept019 c, rept041 b
		WHERE c.r19_compania    = vg_codcia
		  AND c.r19_localidad   = vg_codloc
		  AND c.r19_cod_tran    = "TR"
		  AND c.r19_tipo_dev    = rm_r88.r88_cod_fact
		  AND c.r19_num_dev     = rm_r88.r88_num_fact
		  AND b.r41_compania    = c.r19_compania
		  AND b.r41_localidad   = c.r19_localidad
		  AND b.r41_cod_tr      = c.r19_cod_tran
		  AND b.r41_num_tr      = c.r19_num_tran
OPEN q_tiene
FETCH q_tiene INTO r_r41.*
CLOSE q_tiene
FREE q_tiene
IF r_r41.r41_compania IS NOT NULL THEN
	RETURN 1
END IF
RETURN 0

END FUNCTION



FUNCTION factura_sin_stock()
DEFINE cuantos, resul	INTEGER

SELECT COUNT(*)
	INTO cuantos
	FROM rept020
	WHERE r20_compania  = vg_codcia
	  AND r20_localidad = vG_codloc
	  AND r20_cod_tran  = rm_r88.r88_cod_fact
	  AND r20_num_tran  = rm_r88.r88_num_fact
	  AND r20_bodega    =
		(SELECT r02_codigo
			FROM rept002
			WHERE r02_compania  = r20_compania
			  AND r02_localidad = r20_localidad
			  AND r02_tipo      = "S")
LET resul = 1
IF cuantos > 0 THEN
	LET resul = 0
END IF
RETURN resul

END FUNCTION



FUNCTION validar_caja()
DEFINE r_j02		RECORD LIKE cajt002.*
DEFINE r_j04		RECORD LIKE cajt004.*
DEFINE r_j90		RECORD LIKE cajt090.*
DEFINE r_r19		RECORD LIKE rept019.*
DEFINE salir		SMALLINT
DEFINE mensaje		VARCHAR(200)

CALL fl_lee_cabecera_transaccion_rep(vg_codcia, vg_codloc, rm_r88.r88_cod_fact,
					rm_r88.r88_num_fact)
	RETURNING r_r19.*
CALL fl_retorna_caja(vg_codcia, vg_codloc, r_r19.r19_usuario) RETURNING r_j02.*
IF r_j02.j02_codigo_caja IS NULL THEN
	LET mensaje = 'No hay una caja asignada al usuario ',
			r_r19.r19_usuario CLIPPED, '.'
	CALL fl_mostrar_mensaje(mensaje, 'exclamation')
	RETURN 0
END IF
INITIALIZE r_j04.*, r_j90.* TO NULL
SELECT * INTO r_j90.*
	FROM cajt090
	WHERE j90_localidad   = r_j02.j02_localidad
	  AND j90_codigo_caja = r_j02.j02_codigo_caja
IF STATUS = NOTFOUND THEN
	INSERT INTO cajt090
		VALUES(r_j02.j02_localidad, r_j02.j02_codigo_caja,
			r_j02.j02_usua_caja)
END IF
DECLARE q_j90 CURSOR FOR
	SELECT * FROM cajt090 WHERE j90_localidad = r_j02.j02_localidad
LET salir = 0
FOREACH q_j90 INTO r_j90.*
	SELECT * INTO r_j04.* FROM cajt004
		WHERE j04_compania    = vg_codcia
		  AND j04_localidad   = vg_codloc
		  AND j04_codigo_caja = r_j90.j90_codigo_caja
		  AND j04_fecha_aper  = TODAY
		  AND j04_secuencia   = (SELECT MAX(j04_secuencia) 
	  			FROM cajt004
  				WHERE j04_compania    = vg_codcia
  				  AND j04_localidad   = vg_codloc
  				  AND j04_codigo_caja = r_j90.j90_codigo_caja
  				  AND j04_fecha_aper  = TODAY)
	IF STATUS <> NOTFOUND THEN 
		LET salir = 1
		EXIT FOREACH
	END IF
END FOREACH
IF NOT salir THEN
	CALL fl_mostrar_mensaje('La caja del usuario ' || r_r19.r19_usuario CLIPPED || ' no esta aperturada.', 'exclamation')
END IF
RETURN salir

END FUNCTION



FUNCTION control_ver_factura(cod_tran, num_tran)
DEFINE cod_tran 	LIKE rept088.r88_cod_fact
DEFINE num_tran 	LIKE rept088.r88_num_fact
DEFINE r_r19		RECORD LIKE rept019.*
DEFINE param		VARCHAR(60)

CALL fl_lee_cabecera_transaccion_rep(vg_codcia, vg_codloc, cod_tran, num_tran)
	RETURNING r_r19.*
IF r_r19.r19_num_tran IS NULL THEN
	CALL fl_mostrar_mensaje('La factura no existe en la Compañía.', 'exclamation')
	RETURN
END IF
LET param = '"', cod_tran, '" ', num_tran CLIPPED
CALL ejecuta_comando('REPUESTOS', vg_modulo, 'repp308 ', param)

END FUNCTION



FUNCTION ejecuta_comando(modulo, mod, prog, param)
DEFINE modulo		VARCHAR(15)
DEFINE mod		LIKE gent050.g50_modulo
DEFINE prog		VARCHAR(10)
DEFINE param		VARCHAR(60)
DEFINE comando          VARCHAR(250)
DEFINE run_prog		VARCHAR(10)

{-- ESTO PARA LLAMAR AL PROGRAMA SEGÚN SEA EL AMBIENTE --}
LET run_prog = '; fglrun '
IF vg_gui = 0 THEN
	LET run_prog = '; fglgo '
END IF
{--- ---}
LET comando = 'cd ..', vg_separador, '..', vg_separador, modulo,
		vg_separador, 'fuentes', vg_separador, run_prog, prog,
		vg_base, ' ', mod, ' ', vg_codcia, ' ', vg_codloc, ' ', param
RUN comando

END FUNCTION



FUNCTION sujeto_de_credito(codcli)
DEFINE codcli		LIKE cxct001.z01_codcli
DEFINE r_z02		RECORD LIKE cxct002.*
DEFINE flag_error	SMALLINT

LET flag_error = 1
IF vg_codloc = 3 OR vg_codloc = 4 THEN
	CALL fl_lee_cliente_localidad(vg_codcia, vg_codloc, codcli)
		RETURNING r_z02.*
	IF r_z02.z02_credit_dias = 0 THEN
		CALL fl_mostrar_mensaje('El nuevo cliente no es sujeto de crédito. Por favor LLAME al JEFE DE COBRANZAS.', 'exclamation')
		LET flag_error = 0
	END IF
END IF
RETURN flag_error

END FUNCTION



FUNCTION control_saldos_vencidos(codcia, codcli, flag_mens)
DEFINE codcia		LIKE gent001.g01_compania
DEFINE codcli		LIKE cxct001.z01_codcli
DEFINE moneda		LIKE gent013.g13_moneda
DEFINE valor		DECIMAL(14,2)
DEFINE r_g13		RECORD LIKE gent013.*
DEFINE r_z00		RECORD LIKE cxct000.*
DEFINE r_z02		RECORD LIKE cxct002.*
DEFINE mensaje		VARCHAR(180)
DEFINE flag_error 	SMALLINT
DEFINE flag_mens 	SMALLINT
DEFINE icono		CHAR(20)
DEFINE mens		CHAR(20)

LET icono = 'exclamation'
LET mens  = 'Lo siento, esta'
IF flag_mens THEN
	LET icono = 'info'
	LET mens  = 'Esta'
END IF
CALL fl_retorna_saldo_vencido(codcia, codcli) RETURNING moneda, valor
LET flag_error = 0
IF valor > 0 THEN
	CALL fl_lee_moneda(moneda) RETURNING r_g13.*
	LET mensaje = 'El cliente tiene un saldo vencido ' ||
		      'de  ' || valor || 
		      '  en la moneda ' ||
                      r_g13.g13_nombre ||
		      '.'
	CALL fl_mostrar_mensaje(mensaje, icono)
	CALL fl_lee_compania_cobranzas(codcia) RETURNING r_z00.* 
	IF r_z00.z00_bloq_vencido = 'S' THEN
		CALL fl_mostrar_mensaje(mens CLIPPED || ' activo el bloqueo de proformar y facturar a clientes con saldos vencidos. El cliente debera cancelar sus deudas.', icono)
		LET flag_error = 1
		IF vg_codloc = 3 OR vg_codloc = 4 OR vg_codloc = 5 THEN
			CALL fl_lee_cliente_localidad(vg_codcia, vg_codloc,
							codcli)
				RETURNING r_z02.*
			IF r_z02.z02_credit_dias > 0 THEN
				LET flag_error = 0
			END IF
		END IF
	END IF
END IF
RETURN flag_error

END FUNCTION



FUNCTION llamar_visor_teclas()
DEFINE a		SMALLINT

IF vg_gui = 0 THEN
	CALL fl_visor_teclas_caracter() RETURNING int_flag 
	LET a = fgl_getkey()
	CLOSE WINDOW w_tf
	LET int_flag = 0
END IF

END FUNCTION



FUNCTION control_visor_teclas_caracter_1() 
DEFINE a, fila		INTEGER

CALL fl_visor_teclas_caracter() RETURNING fila
LET a = fila + 2
DISPLAY 'Teclas exclusivas de este proceso:' AT a,2 ATTRIBUTE(REVERSE)	
LET a = a + 1
DISPLAY '<F5>      Factura Origen'  AT a,2
DISPLAY  'F5' AT a,3 ATTRIBUTE(REVERSE)
LET a = fgl_getkey()
CLOSE WINDOW w_tf

END FUNCTION
