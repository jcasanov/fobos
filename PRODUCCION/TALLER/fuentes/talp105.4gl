-------------------------------------------------------------------------------
-- Titulo               : talp105.4gl -- Mantenimiento Tipos Ordenes de Trabajo
-- Elaboración          : 7-sep-2001
-- Autor                : GVA
-- Formato de Ejecución : fglrun  talp105.4gl base TA 1 
-- Ultima Correción     : 8-sep-2001
-- Motivo Corrección    : 2
--------------------------------------------------------------------------------
                                                                                
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'
                                                                                
DEFINE rm_tord   RECORD LIKE talt005.*
DEFINE rm_tord2  RECORD LIKE talt005.*
DEFINE rm_cli    RECORD LIKE  cxct001.*
DEFINE rm_conf   RECORD LIKE  gent000.*
DEFINE rm_cmon   RECORD LIKE  gent014.*
DEFINE vm_r_rows ARRAY[1000] OF INTEGER -- ARREGLO DE ROWID DE FILAS LEIDAS
DEFINE vm_row_current   SMALLINT        -- FILA CORRIENTE DEL ARREGLO
DEFINE vm_num_rows      SMALLINT        -- CANTIDAD DE FILAS LEIDAS
DEFINE vm_max_rows      SMALLINT        -- MAXIMO DE FILAS LEIDAS
DEFINE vm_demonios      VARCHAR(12)
DEFINE vm_flag_mant     CHAR(1)

MAIN
                                                                                
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/errores')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 3 THEN
     	--CALL fgl_winmessage(vg_producto,'Número de parámetros incorrecto','stop')
	CALL fl_mostrar_mensaje('Número de parámetros incorrecto.','stop')
     	EXIT PROGRAM
END IF
LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_codcia   = arg_val(3)
LET vg_proceso = 'talp105'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()
--#CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()
                                                                                
END MAIN



FUNCTION funcion_master()
DEFINE lin_menu		SMALLINT
DEFINE row_ini  	SMALLINT
DEFINE num_rows 	SMALLINT
DEFINE num_cols 	SMALLINT

CALL fl_nivel_isolation()
LET vm_max_rows = 1000
LET lin_menu = 0
LET row_ini  = 3
LET num_rows = 18
LET num_cols = 80
IF vg_gui = 0 THEN
	LET lin_menu = 1
	LET row_ini  = 4
	LET num_rows = 20
	LET num_cols = 78
END IF
OPEN WINDOW w_tord AT row_ini, 2 WITH num_rows ROWS, num_cols COLUMNS
    ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE lin_menu,BORDER,
	      MESSAGE LINE LAST - 1)
IF vg_gui = 1 THEN
	OPEN FORM f_tord FROM '../forms/talf105_1'
ELSE
	OPEN FORM f_tord FROM '../forms/talf105_1c'
END IF
DISPLAY FORM f_tord
INITIALIZE rm_tord.* TO NULL
LET vm_num_rows = 0
LET vm_row_current = 0
CALL muestra_contadores(vm_row_current, vm_num_rows)
MENU 'OPCIONES'
	BEFORE MENU
		HIDE OPTION 'Avanzar'
		HIDE OPTION 'Retroceder'
		HIDE OPTION 'Modificar'
	COMMAND KEY('I') 'Ingresar' 'Ingresar nuevos registros. '
		CALL control_ingreso()
		IF vm_num_rows = 1 THEN
			SHOW OPTION 'Modificar'
		END IF
		IF vm_row_current > 1 THEN
			SHOW OPTION 'Retroceder'
		END IF
		IF vm_row_current = vm_num_rows THEN
			HIDE OPTION 'Avanzar'
		END IF
        COMMAND KEY('M') 'Modificar' 'Modificar registro corriente. '
                IF vm_num_rows > 0 THEN
                        CALL control_modificacion()
                ELSE
			CALL fl_mensaje_consultar_primero()
		END IF
	COMMAND KEY('C') 'Consultar' 'Consultar un registro. '
		CALL control_consulta()
		IF vm_num_rows <= 1 THEN
			SHOW OPTION 'Modificar'
			HIDE OPTION 'Avanzar'
			HIDE OPTION 'Retroceder'
			IF vm_num_rows = 0 THEN
				HIDE OPTION 'Modificar'
			END IF
		ELSE
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Modificar'
		END IF
		IF vm_row_current <= 1 THEN
                        HIDE OPTION 'Retroceder'
                END IF
	COMMAND KEY('A') 'Avanzar' 'Ver siguiente registro'
		IF vm_row_current < vm_num_rows THEN
			LET vm_row_current = vm_row_current + 1 
		END IF	
		CALL lee_muestra_registro(vm_r_rows[vm_row_current])
		CALL muestra_contadores(vm_row_current, vm_num_rows)
		IF vm_row_current = vm_num_rows THEN
			HIDE OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
			NEXT OPTION 'Retroceder'
		ELSE
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
		END IF
	COMMAND KEY('R') 'Retroceder'  'Ver anterior registro. '
		IF vm_row_current > 1 THEN
			LET vm_row_current = vm_row_current - 1 
		END IF
		CALL lee_muestra_registro(vm_r_rows[vm_row_current])
		CALL muestra_contadores(vm_row_current, vm_num_rows)
		IF vm_row_current = 1 THEN
			HIDE OPTION 'Retroceder'
			SHOW OPTION 'Avanzar'
			NEXT OPTION 'Avanzar'
		ELSE
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
		END IF
	COMMAND KEY('S') 'Salir' 'Salir del programa. '
		EXIT MENU
END MENU

END FUNCTION



FUNCTION control_consulta()
DEFINE nomloc		LIKE gent002.g02_nombre
DEFINE expr_sql		CHAR(500)
DEFINE query		CHAR(600)

CLEAR FORM
LET int_flag = 0
CONSTRUCT BY NAME expr_sql ON t05_tipord, t05_nombre, t05_cli_default,
		 t05_valtope_mb, t05_valtope_ma, t05_factura, t05_prec_rpto,
		 t05_usuario, t05_fecing
        ON KEY(F1,CONTROL-W)
		CALL llamar_visor_teclas()
	ON KEY(F2)
		IF INFIELD(t05_tipord) THEN
		     CALL fl_ayuda_tipo_orden_trabajo(vg_codcia)
		     RETURNING rm_tord.t05_tipord, rm_tord.t05_nombre
		     IF rm_tord.t05_tipord IS NOT NULL THEN
			DISPLAY BY NAME rm_tord.t05_tipord, rm_tord.t05_nombre
		     END IF
		END IF
                IF INFIELD(t05_cli_default) THEN
                     CALL fl_ayuda_cliente_general()
                     RETURNING rm_cli.z01_codcli, rm_cli.z01_nomcli
                     IF rm_cli.z01_codcli IS NOT NULL THEN
			LET rm_tord.t05_cli_default = rm_cli.z01_codcli
                        DISPLAY BY NAME rm_tord.t05_cli_default
			DISPLAY  rm_cli.z01_nomcli TO nom_cli
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
		CALL lee_muestra_registro(vm_r_rows[vm_row_current])
	END IF
	CALL muestra_contadores(vm_row_current, vm_num_rows)
	RETURN
END IF
LET query = 'SELECT *, ROWID FROM talt005 WHERE ', expr_sql CLIPPED,
		' ORDER BY 1'
PREPARE cons FROM query
DECLARE q_tord CURSOR FOR cons
LET vm_num_rows = 1
FOREACH q_tord INTO rm_tord.*, vm_r_rows[vm_num_rows]
	LET vm_num_rows = vm_num_rows + 1
        IF vm_num_rows > 1000 THEN
                EXIT FOREACH
        END IF
END FOREACH
LET vm_num_rows = vm_num_rows - 1
IF vm_num_rows = 0 THEN
	CALL fl_mensaje_consulta_sin_registros()
	LET vm_row_current = 0
	CALL muestra_contadores(vm_row_current, vm_num_rows)
        CLEAR FORM
        RETURN
END IF
LET vm_row_current = 1
CALL lee_muestra_registro(vm_r_rows[vm_row_current])
CALL muestra_contadores(vm_row_current, vm_num_rows)

END FUNCTION



FUNCTION control_ingreso()

OPTIONS INPUT WRAP
CLEAR FORM
INITIALIZE rm_tord.* TO NULL
LET vm_flag_mant          = 'I'
LET rm_tord.t05_compania   = vg_codcia
LET rm_tord.t05_fecing     = CURRENT
LET rm_tord.t05_usuario    = vg_usuario
LET rm_tord.t05_prec_rpto  = 'P'
LET rm_tord.t05_factura    = 'N'
DISPLAY BY NAME rm_tord.t05_fecing, rm_tord.t05_usuario
CALL lee_datos()
IF NOT int_flag THEN
	INSERT INTO talt005 VALUES (rm_tord.*)
        IF vm_num_rows = vm_max_rows THEN
                LET vm_num_rows = 1
        ELSE
                LET vm_num_rows = vm_num_rows + 1
        END IF
	LET vm_r_rows[vm_num_rows] = SQLCA.SQLERRD[6] 
	LET vm_row_current = vm_num_rows
	CALL fl_mensaje_registro_ingresado()
END IF
IF vm_num_rows > 0 THEN
	CALL lee_muestra_registro(vm_r_rows[vm_row_current])
END IF
CALL muestra_contadores(vm_row_current, vm_num_rows)

END FUNCTION



FUNCTION control_modificacion()

LET vm_flag_mant      = 'M'
BEGIN WORK
WHENEVER ERROR CONTINUE
DECLARE q_up CURSOR FOR SELECT * FROM talt005 WHERE ROWID = vm_r_rows[vm_row_current]
	FOR UPDATE
OPEN q_up
FETCH q_up INTO rm_tord.*
IF status < 0 THEN
	ROLLBACK WORK
	CALL fl_mensaje_bloqueo_otro_usuario()
	WHENEVER ERROR STOP
	RETURN
END IF
WHENEVER ERROR STOP
LET rm_tord2.t05_nombre = rm_tord.t05_nombre
CALL lee_datos()
IF NOT int_flag THEN
    	UPDATE talt005 SET * = rm_tord.*
		WHERE CURRENT OF q_up
	COMMIT WORK
	CALL fl_mensaje_registro_modificado()
ELSE
	ROLLBACK WORK
	CALL lee_muestra_registro(vm_r_rows[vm_row_current])
END IF
CLOSE q_up

END FUNCTION



FUNCTION lee_datos()
DEFINE           resp      CHAR(6)
DEFINE           codigo    LIKE talt005.t05_tipord
                                                                                
OPTIONS INPUT WRAP
LET int_flag = 0 
INPUT BY NAME rm_tord.t05_tipord, rm_tord.t05_nombre, rm_tord.t05_cli_default,
	      rm_tord.t05_valtope_mb, rm_tord.t05_valtope_ma, 
	      rm_tord.t05_factura, rm_tord.t05_prec_rpto
              WITHOUT DEFAULTS
        ON KEY(INTERRUPT)
        	 IF field_touched(rm_tord.t05_tipord, rm_tord.t05_nombre,
			rm_tord.t05_valtope_mb, rm_tord.t05_valtope_ma,
			rm_tord.t05_cli_default)
                 THEN
                        LET int_flag = 0
			CALL fl_mensaje_abandonar_proceso()
                        	RETURNING resp
                        IF resp = 'Yes' THEN
                             LET int_flag = 1
			    IF vm_flag_mant = 'I' THEN
                                	CLEAR FORM
			    END IF
                            RETURN
                        END IF
                ELSE
			IF vm_flag_mant = 'I' THEN
                	        CLEAR FORM
			END IF
                        RETURN
                END IF       	
        ON KEY(F1,CONTROL-W)
		CALL llamar_visor_teclas()
	ON KEY(F2)
                IF INFIELD(t05_cli_default) THEN
                      CALL fl_ayuda_cliente_general()
                      RETURNING rm_tord2.t05_cli_default, rm_cli.z01_nomcli
                      IF rm_tord2.t05_cli_default IS NOT NULL THEN
			  LET rm_tord.t05_cli_default = rm_tord2.t05_cli_default
                          DISPLAY BY NAME rm_tord.t05_cli_default
                          DISPLAY rm_cli.z01_nomcli TO  nom_cli
                      END IF
                END IF
                LET int_flag = 0
	BEFORE INPUT
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
	BEFORE FIELD t05_tipord
		IF vm_flag_mant = 'M' THEN
			NEXT FIELD NEXT
		END IF
	AFTER FIELD t05_cli_default
               IF rm_tord.t05_cli_default IS NOT NULL THEN
		     CALL fl_lee_cliente_general(rm_tord.t05_cli_default)
		     RETURNING rm_cli.*
		     IF rm_cli.z01_codcli IS NULL THEN
			--CALL fgl_winmessage(vg_producto,'No existe el cliente ','exclamation')
			CALL fl_mostrar_mensaje('No existe el cliente.','exclamation')
		   	NEXT FIELD t05_cli_default
		     END IF
		     DISPLAY rm_cli.z01_nomcli TO nom_cli	
		ELSE
			CLEAR nom_cli
		END IF
	AFTER FIELD t05_valtope_mb
		IF rm_tord.t05_valtope_mb IS NOT NULL THEN
			CALL fl_lee_configuracion_facturacion()
                     		RETURNING rm_conf.*
                     	IF rm_conf.g00_serial IS NULL THEN
				--CALL fgl_winmessage(vg_producto,'No existe la configuración para la facturación ', 'stop')
				CALL fl_mostrar_mensaje('No existe la configuración para la facturación.', 'stop')
				NEXT FIELD t05_valtope_mb
                     	END IF
			IF rm_conf.g00_moneda_alt IS NULL
			OR rm_conf.g00_moneda_alt = ''
			THEN
				LET rm_tord.t05_valtope_ma = 0
				DISPLAY BY NAME rm_tord.t05_valtope_ma
				NEXT FIELD NEXT
			END IF
			CALL fl_lee_factor_moneda(rm_conf.g00_moneda_base,
						  rm_conf.g00_moneda_alt)
				RETURNING rm_cmon.*
			IF rm_cmon.g14_serial IS NULL THEN
				--CALL fgl_winmessage(vg_producto,'No existe la conversion entre monedas ', 'stop')
				CALL fl_mostrar_mensaje('No existe la conversion entre monedas.', 'stop')
				NEXT FIELD t05_valtope_mb
			END IF
			LET rm_tord.t05_valtope_ma = rm_tord.t05_valtope_mb *
						     rm_cmon.g14_tasa
			DISPLAY BY NAME rm_tord.t05_valtope_ma
		END IF
	AFTER INPUT
                 IF vm_flag_mant = 'I' THEN
	      	     CALL fl_lee_tipo_orden_taller(vg_codcia,rm_tord.t05_tipord)
			RETURNING rm_tord2.*
		     IF status <> NOTFOUND THEN
                        --CALL fgl_winmessage(vg_producto,'Ya existe el tipo de orden de trabajo ','exclamation')
			CALL fl_mostrar_mensaje('Ya existe el tipo de orden de trabajo.','exclamation')
                        NEXT FIELD t05_tipord
                     END IF
                END IF
		IF rm_tord2.t05_nombre <> rm_tord.t05_nombre 
		OR vm_flag_mant = 'I'
		THEN 
		     SELECT t05_tipord INTO codigo FROM talt005
	      	     WHERE t05_compania = vg_codcia
	      	     AND   t05_nombre   = rm_tord.t05_nombre
	      	     IF status <> NOTFOUND THEN
                        --CALL fgl_winmessage (vg_producto,'El nombre del tipo de orden ya ha sido asignada al registro de codigo  '|| codigo,'exclamation')
			CALL fl_mostrar_mensaje('El nombre del tipo de orden ya ha sido asignada al registro de codigo '|| codigo || '.','exclamation')
	                NEXT FIELD t05_nombre  
              	     END IF
             	END IF
END INPUT

END FUNCTION



FUNCTION lee_muestra_registro(num_row)
DEFINE num_row		INTEGER

IF vm_num_rows <= 0 THEN
	RETURN
END IF
SELECT * INTO rm_tord.* FROM talt005 WHERE ROWID = num_row
IF STATUS = NOTFOUND THEN
	ERROR 'No existe registro con rowid: ', num_row
END IF
DISPLAY BY NAME rm_tord.t05_tipord, rm_tord.t05_nombre, rm_tord.t05_factura, 
		rm_tord.t05_prec_rpto, rm_tord.t05_valtope_mb,
		rm_tord.t05_valtope_ma,	rm_tord.t05_cli_default,
		rm_tord.t05_usuario, rm_tord.t05_fecing
CALL fl_lee_cliente_general(rm_tord.t05_cli_default)
    RETURNING rm_cli.*
DISPLAY rm_cli.z01_nomcli TO nom_cli

END FUNCTION


                                                                                
FUNCTION muestra_contadores(row_current, num_rows)
DEFINE row_current              SMALLINT
DEFINE num_rows                 SMALLINT
DEFINE nrow                     SMALLINT
                                                                                
LET nrow = 17
IF vg_gui = 1 THEN
	LET nrow = 1
END IF
DISPLAY "" AT nrow, 1
DISPLAY row_current, " de ", num_rows AT nrow, 67
                                                                                
END FUNCTION



FUNCTION llamar_visor_teclas()
DEFINE a		CHAR(1)

IF vg_gui = 0 THEN
	CALL fl_visor_teclas_caracter() RETURNING int_flag 
	LET a = fgl_getkey()
	CLOSE WINDOW w_tf
	LET int_flag = 0
END IF

END FUNCTION
