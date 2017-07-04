------------------------------------------------------------------------------
-- Titulo           : talp214.4gl - Proceso de Refacturación del Taller
-- Elaboracion      : 30-Ene-2006
-- Autor            : NPC
-- Formato Ejecucion: fglrun talp214 base modulo compania localidad [num_fact]
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
DEFINE rm_r19	 	RECORD LIKE rept019.*
DEFINE rm_t00	 	RECORD LIKE talt000.*
DEFINE rm_t60	 	RECORD LIKE talt060.*



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/talp214.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 AND num_args() <> 5 THEN	-- Validar # parámetros correcto
	CALL fl_mostrar_mensaje('Número de parametros incorrecto.','stop')
	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_codloc  = arg_val(4)
LET vg_proceso = 'talp214'
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
	CALL fl_chequeo_mes_proceso_tal(vg_codcia) RETURNING int_flag
	IF int_flag THEN
		RETURN
	END IF
END IF
CALL fl_lee_compania_repuestos(vg_codcia) RETURNING rm_r00.*
CALL fl_lee_configuracion_taller(vg_codcia) RETURNING rm_t00.*
LET vm_max_rows = 10000
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
OPEN WINDOW w_talp214 AT row_ini, 2 WITH num_rows ROWS, num_cols COLUMNS
	ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE lin_menu,   
		  BORDER, MESSAGE LINE LAST - 1)                                
IF vg_gui = 1 THEN
	OPEN FORM f_talf214 FROM '../forms/talf214_1'
ELSE
	OPEN FORM f_talf214 FROM '../forms/talf214_1c'
END IF
DISPLAY FORM f_talf214
INITIALIZE rm_t60.* TO NULL
LET vm_num_rows    = 0
LET vm_row_current = 0
LET vm_reprocesar  = 1
CALL muestra_contadores()
MENU 'OPCIONES'
	BEFORE MENU	
		HIDE OPTION 'Reprocesar'
		HIDE OPTION 'Factura Origen'
		HIDE OPTION 'Nueva Factura'
		HIDE OPTION 'Ref. Inventario'
		HIDE OPTION 'Avanzar'
		HIDE OPTION 'Retroceder'
		IF num_args() = 5 THEN
			HIDE OPTION 'Ingresar'
			HIDE OPTION 'Consultar'
			SHOW OPTION 'Factura Origen'
			SHOW OPTION 'Nueva Factura'
			SHOW OPTION 'Ref. Inventario'
			LET rm_t60.t60_fac_ant = arg_val(5)
                	CALL control_consulta()
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
			IF rm_t60.t60_fac_nue IS NOT NULL THEN
				SHOW OPTION 'Nueva Factura'
			END IF
			SHOW OPTION 'Ref. Inventario'
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
			HIDE OPTION 'Ref. Inventario'
                        HIDE OPTION 'Avanzar'
                        HIDE OPTION 'Retroceder'
			IF vm_num_rows = 1 THEN
				IF vm_reprocesar THEN
					SHOW OPTION 'Reprocesar'
				ELSE
					HIDE OPTION 'Reprocesar'
				END IF
				SHOW OPTION 'Factura Origen'
				IF rm_t60.t60_fac_nue IS NOT NULL THEN
					SHOW OPTION 'Nueva Factura'
				END IF 
				SHOW OPTION 'Ref. Inventario'
			END IF 
                ELSE
			IF vm_reprocesar THEN
				SHOW OPTION 'Reprocesar'
			ELSE
				HIDE OPTION 'Reprocesar'
			END IF
			SHOW OPTION 'Factura Origen'
			IF rm_t60.t60_fac_nue IS NOT NULL THEN
				SHOW OPTION 'Nueva Factura'
			END IF
			SHOW OPTION 'Ref. Inventario'
                        SHOW OPTION 'Avanzar'
                END IF
	COMMAND KEY('P') 'Reprocesar'		'Solo si no hay Nueva Factura.'
		CALL ejecuta_proceso_refacturacion()
		IF vm_reprocesar THEN
			SHOW OPTION 'Reprocesar'
		ELSE
			HIDE OPTION 'Reprocesar'
			IF rm_t60.t60_fac_nue IS NOT NULL THEN
				SHOW OPTION 'Nueva Factura'
				CALL fl_mostrar_mensaje('Proceso de Refacturación Terminado Ok.','info')
			END IF
		END IF
	COMMAND KEY('F') 'Factura Origen' 	'Ver Factura Original.'
		IF vm_num_rows > 0 THEN
			CALL control_ver_factura(rm_t60.t60_fac_ant)
		ELSE 
			CALL fl_mensaje_consultar_primero()
		END IF
	COMMAND KEY('N') 'Nueva Factura' 	'Ver Nueva Factura Generada.'
		IF vm_num_rows > 0 THEN
			CALL control_ver_factura(rm_t60.t60_fac_nue)
		ELSE 
			CALL fl_mensaje_consultar_primero()
		END IF
	COMMAND KEY('M') 'Ref. Inventario' 	'Ver Refacturación Inventario.'
		CALL ver_refacturacion_inventario()
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
		IF rm_t60.t60_fac_nue IS NOT NULL THEN
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
		IF rm_t60.t60_fac_nue IS NOT NULL THEN
			SHOW OPTION 'Nueva Factura'
		END IF
	COMMAND KEY('S') 'Salir'    		'Salir del programa.'
		EXIT MENU
END MENU

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
	CALL fl_mostrar_mensaje('El usuario ' || vg_usuario CLIPPED || ' no esta configurado como Vendedor/Bodeguero y no puede continuar con este proceso.', 'exclamation')
	RETURN
END IF
CLOSE q_vend
FREE q_vend
CLEAR FORM
INITIALIZE rm_t60.* TO NULL
LET rm_t60.t60_compania  = vg_codcia
LET rm_t60.t60_localidad = vg_codloc
LET rm_t60.t60_usuario   = vg_usuario
LET rm_t60.t60_fecing    = CURRENT
DISPLAY BY NAME rm_t60.t60_usuario, rm_t60.t60_fecing
CALL lee_datos()
IF NOT int_flag THEN
	LET rm_t60.t60_fecing = CURRENT
	BEGIN WORK
		IF NOT actualizar_codigo_cliente(rm_t60.t60_codcli_nue) THEN
			ROLLBACK WORK
			EXIT PROGRAM
		END IF
		INSERT INTO talt060 VALUES (rm_t60.*)
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
DEFINE r_t23		RECORD LIKE talt023.*
DEFINE r_t60		RECORD LIKE talt060.*
DEFINE r_z01		RECORD LIKE cxct001.*
DEFINE mensaje		VARCHAR(100)

CLEAR FORM
IF num_args() = 4 THEN
	LET int_flag = 0
	CONSTRUCT BY NAME expr_sql ON t60_fac_ant, t60_fac_nue, t60_codcli_nue,
			t60_nomcli_nue, t60_motivo_refact, t60_ot_ant,
			t60_ot_nue, t60_usuario
	        ON KEY(F1,CONTROL-W)
			CALL llamar_visor_teclas()
		ON KEY(F2)
			IF INFIELD(t60_fac_ant) THEN
				CALL fl_ayuda_refacturacion_tal(vg_codcia,
								vg_codloc)
					RETURNING r_t60.t60_fac_ant,
						  r_t60.t60_fac_nue
			      	IF r_t60.t60_fac_ant IS NOT NULL THEN
					LET rm_t60.t60_fac_ant =
							r_t60.t60_fac_ant
					LET rm_t60.t60_fac_nue =
							r_t60.t60_fac_nue
					DISPLAY BY NAME rm_t60.t60_fac_ant,
							rm_t60.t60_fac_nue
			      	END IF
			END IF
			IF INFIELD(t60_fac_nue) THEN
				CALL fl_ayuda_refacturacion_tal(vg_codcia,
								vg_codloc)
					RETURNING r_t60.t60_fac_ant,
						  r_t60.t60_fac_nue
			      	IF r_t60.t60_fac_ant IS NOT NULL THEN
					LET rm_t60.t60_fac_ant =
							r_t60.t60_fac_ant
					LET rm_t60.t60_fac_nue =
							r_t60.t60_fac_nue
					DISPLAY BY NAME rm_t60.t60_fac_ant,
							rm_t60.t60_fac_nue
			      	END IF
			END IF
                	IF INFIELD(t60_codcli_nue) THEN
	                        CALL fl_ayuda_cliente_localidad(vg_codcia,
								vg_codloc)
        	                        RETURNING r_z01.z01_codcli,
						  r_z01.z01_nomcli
                	        IF r_z01.z01_codcli IS NOT NULL THEN
                        	        LET rm_t60.t60_codcli_nue =
								r_z01.z01_codcli
                                	LET rm_t60.t60_nomcli_nue =
								r_z01.z01_nomcli
	                                DISPLAY BY NAME rm_t60.t60_codcli_nue,
        	                                        rm_t60.t60_nomcli_nue
                	        END IF
	                END IF
			IF INFIELD(t60_ot_ant) THEN
				CALL fl_ayuda_orden_trabajo(vg_codcia,
								vg_codloc, 'D')
					RETURNING r_t23.t23_orden,
						  r_t23.t23_nom_cliente
				IF r_t23.t23_orden IS NOT NULL THEN
					LET rm_t60.t60_ot_ant = r_t23.t23_orden
					DISPLAY BY NAME rm_t60.t60_ot_ant
				END IF
			END IF
			IF INFIELD(t60_ot_nue) THEN
				CALL fl_ayuda_orden_trabajo(vg_codcia,
								vg_codloc, 'F')
					RETURNING r_t23.t23_orden,
						  r_t23.t23_nom_cliente
				IF r_t23.t23_orden IS NOT NULL THEN
					LET rm_t60.t60_ot_nue = r_t23.t23_orden
					DISPLAY BY NAME rm_t60.t60_ot_nue
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
	LET expr_sql = ' t60_fac_ant  = ', rm_t60.t60_fac_ant
END IF
LET query = 'SELECT *, ROWID FROM talt060 ',
		' WHERE t60_compania  =  ', vg_codcia,
		'   AND t60_localidad =  ', vg_codloc,
		'   AND ', expr_sql CLIPPED,
		' ORDER BY t60_fac_nue, t60_fac_ant ' 
PREPARE cons FROM query
DECLARE q_cons CURSOR FOR cons
LET vm_num_rows = 1
FOREACH q_cons INTO rm_t60.*, vm_rows[vm_num_rows]
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
DEFINE r_t23		RECORD LIKE talt023.*
DEFINE r_t60		RECORD LIKE talt060.*
DEFINE r_z01		RECORD LIKE cxct001.*
DEFINE num_fact		LIKE talt060.t60_fac_ant
DEFINE codcli_nue	LIKE talt060.t60_codcli_nue

LET int_flag = 0
INPUT BY NAME rm_t60.t60_fac_ant,rm_t60.t60_codcli_nue, rm_t60.t60_motivo_refact
	WITHOUT DEFAULTS
	ON KEY (INTERRUPT)
        	IF FIELD_TOUCHED(rm_t60.t60_fac_ant, rm_t60.t60_codcli_nue,
				 rm_t60.t60_motivo_refact)
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
		IF INFIELD(t60_fac_ant) THEN
			CALL fl_ayuda_facturas_tal(vg_codcia, vg_codloc, 'F')
				RETURNING r_t23.t23_num_factura,
					  r_t23.t23_nom_cliente
		      	IF r_t23.t23_num_factura IS NOT NULL THEN
				CALL fl_lee_factura_taller(vg_codcia, vg_codloc,
							r_t23.t23_num_factura)
					RETURNING r_t23.*
				LET rm_t60.t60_fac_ant = r_t23.t23_num_factura
				DISPLAY BY NAME rm_t60.t60_fac_ant,
						r_t23.t23_cod_cliente,
						r_t23.t23_nom_cliente
		      	END IF
		END IF
                IF INFIELD(t60_codcli_nue) THEN
                        CALL fl_ayuda_cliente_localidad(vg_codcia, vg_codloc)
                                RETURNING r_z01.z01_codcli, r_z01.z01_nomcli
                        IF r_z01.z01_codcli IS NOT NULL THEN
                                LET rm_t60.t60_codcli_nue = r_z01.z01_codcli
                                LET rm_t60.t60_nomcli_nue = r_z01.z01_nomcli
                                DISPLAY BY NAME rm_t60.t60_codcli_nue,
                                                rm_t60.t60_nomcli_nue
                        END IF
                END IF
		LET int_flag = 0
	ON KEY(F5)
		IF INFIELD(t60_fac_ant) THEN
			IF rm_t60.t60_fac_ant IS NOT NULL THEN
				CALL control_ver_factura(rm_t60.t60_fac_ant)
			END IF
		END IF
	BEFORE INPUT
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
	BEFORE FIELD t60_fac_ant
		LET num_fact = rm_t60.t60_fac_ant
        BEFORE FIELD t60_codcli_nue
		LET codcli_nue = rm_t60.t60_codcli_nue
	AFTER FIELD t60_fac_ant
		IF rm_t60.t60_fac_ant IS NULL THEN
			NEXT FIELD t60_fac_ant
		END IF
		IF rm_t60.t60_fac_ant IS NOT NULL THEN
			CALL fl_lee_factura_taller(vg_codcia, vg_codloc,
							rm_t60.t60_fac_ant)
				RETURNING r_t23.*
                	IF r_t23.t23_num_factura IS NULL THEN
				CALL fl_mostrar_mensaje('La Factura no existe en la Compañía.', 'exclamation')
                        	NEXT FIELD t60_fac_ant
			END IF
			IF NOT validar_caja() THEN
				LET int_flag = 1
				RETURN
			END IF
			IF TODAY > date(r_t23.t23_fec_factura) +
			   rm_t00.t00_dias_dev
			THEN
				CALL fl_mostrar_mensaje('Factura ha excedido el límite de tiempo permitido para realizar devoluciones.','exclamation')
                        	NEXT FIELD t60_fac_ant
        	        END IF
			IF r_t23.t23_estado = 'D' THEN
				CALL fl_mostrar_mensaje('La Factura no puede ser Refacturada porque ha sido parcial o totalmente Devuelta/Anulada.', 'exclamation')
				NEXT FIELD t60_fac_ant
			END IF
                	LET rm_t60.t60_ot_ant = r_t23.t23_orden
			DISPLAY BY NAME r_t23.t23_cod_cliente,
					r_t23.t23_nom_cliente,
					rm_t60.t60_ot_ant
			IF r_t23.t23_cont_cred = 'R' THEN
				SELECT NVL(SUM((z20_valor_cap + z20_valor_int) -
					(z20_saldo_cap + z20_saldo_int)), 0)
					INTO deuda
					FROM cxct020
					WHERE z20_compania  = r_t23.t23_compania
					  AND z20_localidad =r_t23.t23_localidad
					  AND z20_codcli    =
							r_t23.t23_cod_cliente
					  AND z20_areaneg   = 2
					  AND z20_num_tran  =
							r_t23.t23_num_factura
				IF deuda <> 0 THEN
					CALL fl_mostrar_mensaje('Esta factura no puede ser REFACTURADA, porque ha sido parcial o totalmente cancelada.', 'exclamation')
					NEXT FIELD t60_fac_ant
				END IF
			END IF
			IF num_fact IS NULL OR num_fact <> rm_t60.t60_fac_ant
			THEN
				CALL fl_hacer_pregunta('Desea Refacturar por cambio de RAZON SOCIAL ?', 'No')
					RETURNING resp
                		LET rm_t60.t60_codcli_nue = NULL
	                	LET rm_t60.t60_nomcli_nue = NULL
        	        	DISPLAY BY NAME rm_t60.t60_codcli_nue,
						rm_t60.t60_nomcli_nue
				LET cambiar_cli = 1
				LET rm_t60.t60_motivo_refact =
					"POR CAMBIO DE RAZON SOCIAL"
				IF resp <> 'Yes' THEN
					LET cambiar_cli = 0
					IF rm_t60.t60_motivo_refact IS NULL OR
					   rm_t60.t60_motivo_refact =
						"POR CAMBIO DE RAZON SOCIAL"
					THEN
						LET rm_t60.t60_motivo_refact =
							"REFACTURACION POR SRI"
					END IF
					DISPLAY BY NAME rm_t60.t60_motivo_refact
					NEXT FIELD t60_motivo_refact
				END IF
				DISPLAY BY NAME rm_t60.t60_motivo_refact
				IF FIELD_TOUCHED(rm_t60.t60_motivo_refact) THEN
					IF cambiar_cli THEN
						NEXT FIELD t60_codcli_nue
					END IF
				END IF
			END IF
		ELSE
			CLEAR t23_cod_cliente, t23_nom_cliente
		END IF
	AFTER FIELD t60_codcli_nue
		IF NOT cambiar_cli THEN
                	LET rm_t60.t60_codcli_nue = NULL
                	LET rm_t60.t60_nomcli_nue = NULL
                	DISPLAY BY NAME rm_t60.t60_codcli_nue,
					rm_t60.t60_nomcli_nue
			CONTINUE INPUT
		END IF
		IF rm_t60.t60_codcli_nue IS NULL THEN
                	LET rm_t60.t60_codcli_nue = codcli_nue
			CALL fl_lee_cliente_general(rm_t60.t60_codcli_nue)
				RETURNING r_z01.*
			LET rm_t60.t60_nomcli_nue = r_z01.z01_nomcli
                	DISPLAY BY NAME rm_t60.t60_codcli_nue,
					rm_t60.t60_nomcli_nue
		ELSE
			CALL fl_lee_cliente_general(rm_t60.t60_codcli_nue)
				RETURNING r_z01.*
			IF r_z01.z01_codcli IS NULL THEN
				CALL fl_mostrar_mensaje('Cliente no existe.', 'exclamation')
				NEXT FIELD t60_codcli_nue
			END IF
			IF r_z01.z01_estado = 'B' THEN
				CALL fl_mensaje_estado_bloqueado()
				NEXT FIELD t60_codcli_nue
			END IF
			IF rm_t60.t60_codcli_nue = rm_r00.r00_codcli_tal THEN
				CALL fl_mostrar_mensaje('El codigo del cliente para Refacturar no puede ser el Consumidor Final.', 'exclamation')
				NEXT FIELD t60_codcli_nue
			END IF
			LET rm_t60.t60_nomcli_nue = r_z01.z01_nomcli
        	       	DISPLAY BY NAME rm_t60.t60_codcli_nue,
					rm_t60.t60_nomcli_nue
			CALL validar_cedruc(r_z01.z01_codcli,
						r_z01.z01_num_doc_id,
						r_z01.z01_tipo_doc_id)
				RETURNING resul
			IF NOT resul THEN
				NEXT FIELD t60_codcli_nue
			END IF
                END IF
	AFTER INPUT
		CALL lee_registro_refact(rm_t60.t60_fac_ant) RETURNING r_t60.*
		IF r_t60.t60_compania IS NOT NULL THEN
			CALL fl_mostrar_mensaje('Esta Factura ya fue Refacturada.', 'exclamation')
			NEXT FIELD t60_fac_ant
		END IF
		IF rm_t60.t60_motivo_refact IS NULL THEN
			CALL fl_mostrar_mensaje('Debe ingresar motivo de la Refacturación.', 'exclamation')
			NEXT FIELD t60_motivo_refact
		END IF
		CALL fl_lee_factura_taller(vg_codcia, vg_codloc,
						rm_t60.t60_fac_ant)
			RETURNING r_t23.*
		IF r_t23.t23_cod_cliente = rm_r00.r00_codcli_tal THEN
			IF rm_t60.t60_codcli_nue IS NULL THEN
				CALL fl_mostrar_mensaje('El codigo cliente de la factura es el Consumidor Final. Haga una Refacturación por cambio de Razón Social.', 'exclamation')
				NEXT FIELD t60_codcli_nue
			END IF
		END IF
		IF cambiar_cli THEN
			IF rm_t60.t60_codcli_nue IS NULL THEN
				CALL fl_mostrar_mensaje('Debe ingresar el codigo de cliente para la Nueva Factura, ya que es una Refacturación por cambio de Razón Social.', 'exclamation')
				NEXT FIELD t60_codcli_nue
			END IF
		END IF
END INPUT

END FUNCTION



FUNCTION actualizar_codigo_cliente(cod_cliente)
DEFINE cod_cliente	LIKE talt023.t23_cod_cliente
DEFINE r_t23		RECORD LIKE talt023.*

WHENEVER ERROR CONTINUE
DECLARE q_cli CURSOR FOR
	SELECT * FROM talt023
	WHERE t23_compania    = vg_codcia
	  AND t23_localidad   = vg_codloc
	  AND t23_num_factura = rm_t60.t60_fac_ant
	FOR UPDATE
OPEN q_cli
FETCH q_cli INTO r_t23.*
IF STATUS < 0 THEN
	CALL fl_mensaje_bloqueo_otro_usuario()
	WHENEVER ERROR STOP
	RETURN 0
END IF
IF cod_cliente IS NOT NULL AND cod_cliente = rm_r00.r00_codcli_tal THEN
	UPDATE talt023 SET t23_cod_cliente = cod_cliente WHERE CURRENT OF q_cli
END IF
IF STATUS <> 0 THEN
	CALL fl_mostrar_mensaje('Ha ocurrido un error al intentar actualizar el código del cliente. Llame al ADMINISTRADOR.', 'exclamation')
	WHENEVER ERROR STOP
	RETURN 0
END IF
WHENEVER ERROR STOP
RETURN 1

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



FUNCTION lee_registro_refact(num_fact)
DEFINE num_fact		LIKE talt060.t60_fac_ant
DEFINE r_t60		RECORD LIKE talt060.*

INITIALIZE r_t60.* TO NULL
SELECT * INTO r_t60.* FROM talt060
	WHERE t60_compania  = vg_codcia
	  AND t60_localidad = vg_codloc
	  AND t60_fac_ant   = num_fact
RETURN r_t60.*

END FUNCTION



FUNCTION lee_registro_refact_inv(cod_fact, num_fact)
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
DEFINE r_r88		RECORD LIKE rept088.*
DEFINE r_t23		RECORD LIKE talt023.*
DEFINE r_t25		RECORD LIKE talt025.*

LET vm_reprocesar = 1
CALL lee_registro_refact(rm_t60.t60_fac_ant) RETURNING rm_t60.*
IF rm_t60.t60_num_dev IS NULL THEN
	CALL llamada_de_procesos(1, "TALLER", vg_modulo, "talp211 ")
	CALL lee_registro_refact(rm_t60.t60_fac_ant) RETURNING rm_t60.*
END IF
IF rm_t60.t60_num_dev IS NULL THEN
	RETURN
END IF
DECLARE q_r19 CURSOR WITH HOLD FOR
	SELECT * FROM rept019
		WHERE r19_compania    = rm_t60.t60_compania
		  AND r19_localidad   = rm_t60.t60_localidad
		  AND r19_cod_tran    = 'FA'
		  --AND r19_tipo_dev    IS NULL
		  AND r19_ord_trabajo = rm_t60.t60_ot_ant
		ORDER BY r19_num_tran
FOREACH q_r19 INTO rm_r19.*
	CALL lee_registro_refact_inv(rm_r19.r19_cod_tran, rm_r19.r19_num_tran)
		RETURNING r_r88.*
	IF r_r88.r88_cod_fact_nue IS NULL THEN
		CALL llamada_de_procesos(2, "REPUESTOS", "RE", "repp237 ")
	END IF
	CALL lee_registro_refact_inv(rm_r19.r19_cod_tran, rm_r19.r19_num_tran)
		RETURNING r_r88.*
	IF r_r88.r88_cod_fact_nue IS NULL THEN
		RETURN
	END IF
END FOREACH
IF rm_t60.t60_ot_nue IS NOT NULL THEN
	CALL fl_lee_orden_trabajo(rm_t60.t60_compania, rm_t60.t60_localidad,
					rm_t60.t60_ot_nue)
		RETURNING r_t23.*
	IF r_t23.t23_estado = 'A' THEN
		CALL llamada_de_procesos(3, "TALLER", vg_modulo, "talp206 ")
	END IF
	CALL fl_lee_cabecera_credito_taller(rm_t60.t60_compania,
					rm_t60.t60_localidad, rm_t60.t60_ot_nue)
		RETURNING r_t25.*
	IF r_t25.t25_compania IS NULL THEN
		CALL llamada_de_procesos(4, "TALLER", vg_modulo, "talp208 ")
	END IF
	CALL lee_registro_refact(rm_t60.t60_fac_ant) RETURNING rm_t60.*
END IF
IF rm_t60.t60_ot_nue IS NULL THEN
	RETURN
END IF
IF rm_t60.t60_fac_nue IS NULL THEN
	IF rm_t60.t60_ot_nue IS NOT NULL THEN
		CALL llamada_de_procesos(5, "CAJA", "CG", "cajp203 ")
		CALL lee_registro_refact(rm_t60.t60_fac_ant) RETURNING rm_t60.*
	END IF
END IF
IF rm_t60.t60_fac_nue IS NULL THEN
	RETURN
END IF
DISPLAY BY NAME rm_t60.t60_fac_nue
LET vm_reprocesar = 0

END FUNCTION



FUNCTION llamada_de_procesos(flag, modulo, mod, prog)
DEFINE flag		SMALLINT
DEFINE modulo		VARCHAR(15)
DEFINE mod		LIKE gent050.g50_modulo
DEFINE prog		VARCHAR(10)
DEFINE param		VARCHAR(60)
DEFINE r_t23		RECORD LIKE talt023.*
DEFINE r_t25		RECORD LIKE talt025.*
DEFINE cont		SMALLINT
DEFINE mensaje		VARCHAR(250)
DEFINE mensproc		VARCHAR(40)
DEFINE evento		DECIMAL(15,0)

CASE flag
	WHEN 1
		LET param    = rm_t60.t60_fac_ant CLIPPED, ' "A" '
		LET mensproc = "Devolución/Anulación."
	WHEN 2
		LET param    = ' "', rm_r19.r19_cod_tran, '" ',
				rm_r19.r19_num_tran, ' "R" '
		LET mensproc = "Refacturación Inventario."
	WHEN 3
		LET param    = rm_t60.t60_ot_nue
		LET mensproc = "Cierre Orden de Trabajo."
	WHEN 4
		LET param    = rm_t60.t60_ot_nue, ' "A" '
		LET mensproc = "Aprobación Crédito O. Trabajo."
	WHEN 5
		LET param    = '"OT" ', rm_t60.t60_ot_nue, ' "A" '
		LET mensproc = "Forma de Pago en Caja."
END CASE
LET cont = 0
WHILE TRUE
	LET mensaje = "Generando ", mensproc CLIPPED, " Por favor espere ..."
	ERROR mensaje
	CALL ejecuta_comando(modulo, mod, prog, param)
	ERROR '                                                                                '
	CALL lee_registro_refact(rm_t60.t60_fac_ant) RETURNING rm_t60.*
	LET evento = NULL
	CASE flag
		WHEN 1
			LET evento = rm_t60.t60_num_dev
		WHEN 2
			LET evento = rm_r19.r19_num_tran
		WHEN 3
			CALL fl_lee_orden_trabajo(rm_t60.t60_compania,
						 rm_t60.t60_localidad,
						 rm_t60.t60_ot_nue)
				RETURNING r_t23.*
			IF r_t23.t23_estado <> 'A' THEN
				LET evento = rm_t60.t60_ot_nue
			END IF
		WHEN 4
			CALL fl_lee_cabecera_credito_taller(rm_t60.t60_compania,
							 rm_t60.t60_localidad,
							 rm_t60.t60_ot_nue)
				RETURNING r_t25.*
			IF r_t25.t25_compania IS NOT NULL THEN
				LET evento = rm_t60.t60_ot_nue
			END IF
		WHEN 5
			LET evento = rm_t60.t60_fac_nue
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
CALL lee_registro_refact(rm_t60.t60_fac_ant) RETURNING rm_t60.*

END FUNCTION



FUNCTION lee_muestra_registro(row)
DEFINE row 		INTEGER
DEFINE r_t23		RECORD LIKE talt023.*

IF vm_num_rows <= 0 THEN
	RETURN
END IF
SELECT * INTO rm_t60.* FROM talt060 WHERE ROWID = row
IF STATUS = NOTFOUND THEN
	ERROR 'No existe registro con rowid', row
END IF
DISPLAY BY NAME rm_t60.t60_fac_ant, rm_t60.t60_fac_nue, rm_t60.t60_codcli_nue,
		rm_t60.t60_nomcli_nue, rm_t60.t60_motivo_refact,
		rm_t60.t60_ot_ant, rm_t60.t60_ot_nue, rm_t60.t60_usuario,
		rm_t60.t60_fecing
CALL fl_lee_factura_taller(vg_codcia, vg_codloc, rm_t60.t60_fac_ant)
	RETURNING r_t23.*
DISPLAY BY NAME r_t23.t23_cod_cliente, r_t23.t23_nom_cliente
CALL muestra_contadores()
LET vm_reprocesar = 1
IF rm_t60.t60_fac_nue IS NOT NULL THEN
	LET vm_reprocesar = 0
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



FUNCTION validar_caja()
DEFINE r_j02		RECORD LIKE cajt002.*
DEFINE r_j04		RECORD LIKE cajt004.*
DEFINE r_j10		RECORD LIKE cajt010.*
DEFINE r_j90		RECORD LIKE cajt090.*
DEFINE r_t23		RECORD LIKE talt023.*
DEFINE salir		SMALLINT
DEFINE mensaje		VARCHAR(200)

CALL fl_lee_factura_taller(vg_codcia, vg_codloc, rm_t60.t60_fac_ant)
	RETURNING r_t23.*
CALL fl_lee_cabecera_caja(vg_codcia, vg_codloc, 'OT', r_t23.t23_orden)
	RETURNING r_j10.*
CALL fl_retorna_caja(vg_codcia, vg_codloc, r_j10.j10_usuario) RETURNING r_j02.*
IF r_j02.j02_codigo_caja IS NULL THEN
	LET mensaje = 'No hay una caja asignada al usuario ',
			r_j10.j10_usuario CLIPPED, '.'
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
	CALL fl_mostrar_mensaje('La caja del usuario ' || r_j10.j10_usuario CLIPPED || ' no esta aperturada.', 'exclamation')
END IF
RETURN salir

END FUNCTION



FUNCTION control_ver_factura(num_tran)
DEFINE num_tran 	LIKE talt060.t60_fac_ant
DEFINE r_t23		RECORD LIKE talt023.*
DEFINE param		VARCHAR(60)

CALL fl_lee_factura_taller(vg_codcia, vg_codloc, num_tran) RETURNING r_t23.*
IF r_t23.t23_num_factura IS NULL THEN
	CALL fl_mostrar_mensaje('La factura no existe en la Compañía.', 'exclamation')
	RETURN
END IF
LET param = num_tran
CALL ejecuta_comando('TALLER', vg_modulo, 'talp308 ', param)

END FUNCTION



FUNCTION ver_refacturacion_inventario()
DEFINE param		VARCHAR(60)

IF rm_t60.t60_ot_nue IS NULL THEN
	CALL fl_mostrar_mensaje('No se ha generado todavía la nueva Orden de Trabajo.', 'exclamation')
	RETURN
END IF
LET param = ' ', rm_t60.t60_ot_ant
CALL ejecuta_comando('REPUESTOS', 'RE', 'repp237 ', param)

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
