------------------------------------------------------------------------------
-- Titulo           : cxcp106.4gl - Mantenimiento de Clientes por area negocio
-- Elaboracion      : 04-oct-2001
-- Autor            : NPC
-- Formato Ejecucion: fglrun cxcp106 base módulo compañía localidad [cliente]
-- Ultima Correccion: 
-- Motivo Correccion: 
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_demonios	VARCHAR(12)
DEFINE rm_cxc		RECORD LIKE cxct003.*
DEFINE rm_cli		RECORD LIKE cxct001.*
DEFINE vm_codcli	LIKE cxct001.z01_codcli
DEFINE vm_num_rows	SMALLINT
DEFINE vm_row_current	SMALLINT
DEFINE vm_max_rows	SMALLINT
DEFINE vm_r_rows	ARRAY [1000] OF INTEGER
DEFINE vm_flag		CHAR(1)

MAIN

DEFER QUIT 
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/errores')
CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 6 THEN          -- Validar # parámetros correcto
	CALL fgl_winmessage(vg_producto, 'Número de parámetros incorrecto', 'stop')
	EXIT PROGRAM
END IF
LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_codcia   = arg_val(3)
LET vg_codloc   = arg_val(4)
LET vm_codcli   = arg_val(5)
LET vm_flag     = arg_val(6)
LET vg_proceso = 'cxcp106'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL control_master()

END MAIN



FUNCTION control_master()
DEFINE r_cxc2_aux       RECORD LIKE cxct002.*

CALL fl_nivel_isolation()
LET vm_max_rows	= 1000
OPEN WINDOW wf AT 3,2 WITH 20 ROWS, 80 COLUMNS
    ATTRIBUTE(FORM LINE FIRST + 2, COMMENT LINE LAST, MENU LINE FIRST,BORDER,
	      MESSAGE LINE LAST - 2)
OPTIONS INPUT WRAP,
	ACCEPT KEY	F12
OPEN FORM f_cxc FROM "../forms/cxcf106_1"
DISPLAY FORM f_cxc
INITIALIZE r_cxc2_aux.* TO NULL
CALL fl_lee_cliente_localidad(vg_codcia,vg_codloc,vm_codcli)
	RETURNING r_cxc2_aux.*
IF r_cxc2_aux.z02_compania IS NULL THEN
	CALL fgl_winmessage(vg_producto,'Ingrese datos del cliente en la compañía.','info')
	EXIT PROGRAM
END IF
INITIALIZE rm_cxc.* TO NULL
LET vm_num_rows    = 0
LET vm_row_current = 0
CALL control_consulta('E')
CALL muestra_contadores(vm_row_current, vm_num_rows)
MENU 'OPCIONES'
	BEFORE MENU
		IF vm_row_current = 0 THEN
			HIDE OPTION 'Avanzar'
			HIDE OPTION 'Retroceder'
			HIDE OPTION 'Modificar'
			HIDE OPTION 'Consultar'
		ELSE
		   IF fl_control_permiso_opcion('Modificar') THEN			
			SHOW OPTION 'Modificar'
		   END IF 

		   IF fl_control_permiso_opcion('Consultar') THEN
			SHOW OPTION 'Consultar'
		   END IF
		
			IF vm_num_rows = 1 THEN
				HIDE OPTION 'Avanzar'
				HIDE OPTION 'Retroceder'
			ELSE
				SHOW OPTION 'Avanzar'
				IF vm_row_current > 1 THEN
					SHOW OPTION 'Retroceder'
				ELSE
					HIDE OPTION 'Retroceder'
				END IF
			END IF
		END IF
		IF vm_flag = 'O' THEN
			HIDE OPTION 'Ingresar'
			HIDE OPTION 'Modificar'
			HIDE OPTION 'Consultar'
		END IF
	COMMAND KEY('I') 'Ingresar' 'Ingresar nuevos registros. '
		CALL control_ingreso()
		IF vm_num_rows = 1 THEN
		   IF fl_control_permiso_opcion('Modificar') THEN			
			SHOW OPTION 'Modificar'
		   END IF 

		   IF fl_control_permiso_opcion('Consultar') THEN
			SHOW OPTION 'Consultar'
		   END IF
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
		CALL control_consulta('C')
		IF vm_num_rows <= 1 THEN
		   IF fl_control_permiso_opcion('Modificar') THEN			
			SHOW OPTION 'Modificar'
		   END IF 
		
			HIDE OPTION 'Avanzar'
			HIDE OPTION 'Retroceder'
			IF vm_num_rows = 0 THEN
				HIDE OPTION 'Modificar'
			END IF
		ELSE
			SHOW OPTION 'Avanzar'
		   IF fl_control_permiso_opcion('Modificar') THEN			
			SHOW OPTION 'Modificar'
		   END IF 
			
		END IF
		IF vm_row_current <= 1 THEN
                        HIDE OPTION 'Retroceder'
                END IF
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
	COMMAND KEY('S') 'Salir' 'Salir del programa. '
		EXIT MENU
END MENU

END FUNCTION



FUNCTION control_ingreso()
DEFINE r_cia		RECORD LIKE cxct000.*

CALL fl_retorna_usuario()
INITIALIZE rm_cxc.* TO NULL
CALL fl_lee_compania_cobranzas(vg_codcia) RETURNING r_cia.*
CLEAR z03_cupocred_ma, tit_area
LET rm_cxc.z03_compania     = vg_codcia
LET rm_cxc.z03_localidad    = vg_codloc
LET rm_cxc.z03_codcli       = vm_codcli
LET rm_cxc.z03_credit_auto  = r_cia.z00_credit_auto
LET rm_cxc.z03_credit_dias  = r_cia.z00_credit_dias
LET rm_cxc.z03_cupocred_mb  = 0
LET rm_cxc.z03_cupocred_ma  = 0
LET rm_cxc.z03_dcto_item_c  = 0
LET rm_cxc.z03_dcto_item_r  = 0
LET rm_cxc.z03_dcto_mano_c  = 0
LET rm_cxc.z03_dcto_mano_r  = 0
LET rm_cxc.z03_usuario      = vg_usuario
LET rm_cxc.z03_fecing       = CURRENT
CALL leer_datos('I')
IF NOT int_flag THEN
	LET rm_cxc.z03_fecing  = CURRENT
	INSERT INTO cxct003 VALUES (rm_cxc.*)
	IF vm_num_rows = vm_max_rows THEN
		LET vm_num_rows = 1
	ELSE
		LET vm_num_rows = vm_num_rows + 1
	END IF
	LET vm_row_current = vm_num_rows
	DISPLAY BY NAME rm_cxc.z03_fecing
	LET vm_r_rows[vm_row_current] = SQLCA.SQLERRD[6] 
	CALL muestra_contadores(vm_row_current, vm_num_rows)
	CALL mostrar_registro(vm_r_rows[vm_num_rows])	
	CALL fl_mensaje_registro_ingresado()
ELSE
	CLEAR FORM
	CALL mostrar_cliente()
	IF vm_row_current > 0 THEN
		CALL mostrar_registro(vm_r_rows[vm_row_current])
	END IF
END IF

END FUNCTION



FUNCTION control_modificacion()
	
IF vm_num_rows = 0 THEN
	CALL fl_mensaje_consultar_primero()
	RETURN
END IF
CALL mostrar_registro(vm_r_rows[vm_row_current])
BEGIN WORK
WHENEVER ERROR CONTINUE
DECLARE q_up CURSOR FOR SELECT * FROM cxct003
	WHERE ROWID = vm_r_rows[vm_row_current]
	FOR UPDATE
OPEN q_up
FETCH q_up INTO rm_cxc.*
IF STATUS < 0 THEN
	COMMIT WORK
	CALL fl_mensaje_bloqueo_otro_usuario()
	WHENEVER ERROR STOP
	RETURN
END IF
WHENEVER ERROR STOP
CALL leer_datos('M')
IF NOT int_flag THEN
	UPDATE cxct003 SET z03_credit_auto = rm_cxc.z03_credit_auto, 
			   z03_credit_dias = rm_cxc.z03_credit_dias,
			   z03_cupocred_mb = rm_cxc.z03_cupocred_mb,
			   z03_dcto_item_c = rm_cxc.z03_dcto_item_c, 
			   z03_dcto_item_r = rm_cxc.z03_dcto_item_r,
			   z03_dcto_mano_c = rm_cxc.z03_dcto_mano_c,
			   z03_dcto_mano_r = rm_cxc.z03_dcto_mano_r
			WHERE CURRENT OF q_up
	COMMIT WORK
	CALL fl_mensaje_registro_modificado()
ELSE
	ROLLBACK WORK
	CLEAR FORM
	IF vm_row_current > 0 THEN
		CALL mostrar_registro(vm_r_rows[vm_row_current])
	END IF
END IF
WHENEVER ERROR STOP
 
END FUNCTION



FUNCTION control_consulta(flag)
DEFINE flag		CHAR(1)
DEFINE cod_aux          LIKE gent003.g03_areaneg
DEFINE nom_aux          LIKE gent003.g03_nombre
DEFINE query		VARCHAR(800)
DEFINE expr_sql		VARCHAR(800)
DEFINE num_reg		INTEGER

CLEAR FORM
INITIALIZE cod_aux TO NULL
CALL mostrar_cliente()
LET int_flag = 0
IF flag = 'C' THEN
	CONSTRUCT BY NAME expr_sql ON z03_areaneg, z03_credit_auto,
		z03_credit_dias, z03_cupocred_mb, z03_dcto_item_c,
		z03_dcto_item_r, z03_dcto_mano_c, z03_dcto_mano_r
		ON KEY(F2)
			IF infield(z03_areaneg) THEN
                	        CALL fl_ayuda_areaneg(vg_codcia)
                        	        RETURNING cod_aux, nom_aux
	                        LET int_flag = 0
        	                IF cod_aux IS NOT NULL THEN
                	                DISPLAY cod_aux TO z03_areaneg
                        	        DISPLAY nom_aux TO tit_area
	                        END IF
        	        END IF
	END CONSTRUCT
	IF int_flag THEN
		IF vm_row_current > 0 THEN
			CALL muestra_contadores(vm_row_current, vm_num_rows)
			CALL mostrar_registro(vm_r_rows[vm_row_current])
		ELSE
			CLEAR FORM
		END IF
		RETURN
	END IF
	LET query = 'SELECT *, ROWID FROM cxct003 ' ||
			'WHERE z03_compania  = ' || vg_codcia ||
			'  AND z03_localidad = ' || vg_codloc ||
			'  AND z03_codcli    = ' || vm_codcli ||
			'  AND ' || expr_sql CLIPPED ||
			' ORDER BY 3'
ELSE
	LET query = 'SELECT *, ROWID FROM cxct003 ' ||
			'WHERE z03_compania  = ' || vg_codcia ||
			'  AND z03_localidad = ' || vg_codloc ||
			'  AND z03_codcli    = ' || vm_codcli ||
			' ORDER BY 3'
END IF
PREPARE cons FROM query	
DECLARE q_cons CURSOR FOR cons
LET vm_num_rows = 0
FOREACH q_cons INTO rm_cxc.*, num_reg
	LET vm_num_rows = vm_num_rows + 1
        IF vm_num_rows > vm_max_rows THEN
		LET vm_num_rows = vm_num_rows - 1
                EXIT FOREACH
        END IF
	LET vm_r_rows[vm_num_rows] = num_reg
END FOREACH
IF vm_num_rows = 0 THEN
	LET int_flag = 0
	IF flag = 'C' THEN
		CALL fl_mensaje_consulta_sin_registros()
		CLEAR FORM
	END IF
	LET vm_row_current = 0
	CALL muestra_contadores(vm_row_current, vm_num_rows)
ELSE  
	LET vm_row_current = 1
	CALL muestra_contadores(vm_row_current, vm_num_rows)
	CALL mostrar_registro(vm_r_rows[vm_row_current])
END IF

END FUNCTION



FUNCTION leer_datos (flag_mant)
DEFINE flag_mant	CHAR(1)
DEFINE resp		CHAR(6)
DEFINE resul		SMALLINT
DEFINE r_cxc_aux	RECORD LIKE cxct003.*
DEFINE r_are            RECORD LIKE gent003.*
DEFINE r_mon            RECORD LIKE gent014.*
DEFINE cod_aux          LIKE gent003.g03_areaneg
DEFINE nom_aux          LIKE gent003.g03_nombre

LET int_flag = 0
INITIALIZE r_cxc_aux.*, r_are.*, r_mon.*, cod_aux TO NULL
CALL mostrar_cliente()
DISPLAY BY NAME rm_cxc.z03_cupocred_mb, rm_cxc.z03_cupocred_ma,
		rm_cxc.z03_usuario, rm_cxc.z03_credit_dias, rm_cxc.z03_fecing,
		rm_cxc.z03_dcto_item_c, rm_cxc.z03_dcto_item_r,
                rm_cxc.z03_dcto_mano_c, rm_cxc.z03_dcto_mano_r
INPUT BY NAME rm_cxc.z03_areaneg, rm_cxc.z03_credit_auto, 
	rm_cxc.z03_credit_dias, rm_cxc.z03_cupocred_mb,	rm_cxc.z03_dcto_item_c,
	rm_cxc.z03_dcto_item_r, rm_cxc.z03_dcto_mano_c,	rm_cxc.z03_dcto_mano_r
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
        	IF field_touched(rm_cxc.z03_areaneg, rm_cxc.z03_credit_auto,
			rm_cxc.z03_credit_dias, rm_cxc.z03_cupocred_mb,
			rm_cxc.z03_dcto_item_c, rm_cxc.z03_dcto_item_r,
			rm_cxc.z03_dcto_mano_c, rm_cxc.z03_dcto_mano_r)
        	THEN
               		LET int_flag = 0
			CALL fl_mensaje_abandonar_proceso()
                		RETURNING resp
              		IF resp = 'Yes' THEN
				LET int_flag = 1
                       		CLEAR FORM
                       		RETURN
                	END IF
		ELSE
			RETURN
		END IF
	ON KEY(F2)
		IF infield(z03_areaneg) THEN
                        CALL fl_ayuda_areaneg(vg_codcia)
                                RETURNING cod_aux, nom_aux
                        LET int_flag = 0
                        IF cod_aux IS NOT NULL THEN
				LET rm_cxc.z03_areaneg = cod_aux
                                DISPLAY BY NAME rm_cxc.z03_areaneg
                                DISPLAY nom_aux TO tit_area
                        END IF
                END IF
	BEFORE FIELD z03_areaneg
		IF flag_mant = 'M' THEN
			NEXT FIELD NEXT
		END IF
	BEFORE FIELD z03_cupocred_mb
		CALL poner_credit_dias() RETURNING resul
	AFTER FIELD z03_areaneg
                IF rm_cxc.z03_areaneg IS NOT NULL THEN
                        CALL fl_lee_cliente_areaneg(vg_codcia,vg_codloc,
						rm_cxc.z03_areaneg,vm_codcli)
                                RETURNING r_cxc_aux.*
			CALL fl_lee_area_negocio(vg_codcia,rm_cxc.z03_areaneg)
				RETURNING r_are.*
                       	DISPLAY r_are.g03_nombre TO tit_area
                        IF r_cxc_aux.z03_areaneg IS NOT NULL THEN
         			CALL fgl_winmessage(vg_producto,'Area de Negocio ya existe.','exclamation')
                                NEXT FIELD z03_areaneg
                        END IF
                ELSE
                        CLEAR tit_area
                END IF
	AFTER FIELD z03_credit_auto
		CALL poner_credit_dias() RETURNING resul
	AFTER FIELD z03_cupocred_mb
                IF rm_cxc.z03_cupocred_mb IS NOT NULL THEN
                        IF rg_gen.g00_moneda_alt IS NOT NULL
                        OR rg_gen.g00_moneda_alt <> ' ' THEN
                               CALL fl_lee_factor_moneda(rg_gen.g00_moneda_base,
                                rg_gen.g00_moneda_alt)
                                        RETURNING r_mon.*
                                IF r_mon.g14_serial IS NOT NULL THEN
                                        LET rm_cxc.z03_cupocred_ma =
                                        rm_cxc.z03_cupocred_mb * r_mon.g14_tasa
                                        IF rm_cxc.z03_cupocred_ma IS NULL
                                        OR rm_cxc.z03_cupocred_ma>9999999999.99
                                        THEN
                                                CALL fgl_winmessage(vg_producto,
'El cupo de crédito en moneda base está demasiado grande.', 'exclamation')
                                                NEXT FIELD z03_cupocred_mb
                                        END IF
                                END IF
                                DISPLAY BY NAME rm_cxc.z03_cupocred_ma
                        END IF
                END IF
	AFTER INPUT
		CALL poner_credit_dias() RETURNING resul
		IF resul = 1 THEN
			CALL fgl_winmessage(vg_producto,'Crédito de días debe ser mayor a cero, si hay crédito automático.','info')
			NEXT FIELD z03_credit_dias
		END IF
END INPUT

END FUNCTION



FUNCTION muestra_siguiente_registro()

IF vm_row_current < vm_num_rows THEN
	LET vm_row_current = vm_row_current + 1
END IF
CALL muestra_contadores(vm_row_current, vm_num_rows)
CALL mostrar_registro(vm_r_rows[vm_row_current])

END FUNCTION



FUNCTION muestra_anterior_registro()

IF vm_row_current > 1 THEN
	LET vm_row_current = vm_row_current - 1
END IF
CALL muestra_contadores(vm_row_current, vm_num_rows)
CALL mostrar_registro(vm_r_rows[vm_row_current])

END FUNCTION



FUNCTION muestra_contadores(row_current, num_rows)
DEFINE row_current	SMALLINT
DEFINE num_rows		SMALLINT
                                                                                
DISPLAY "" AT 1,1
DISPLAY row_current, " de ", num_rows AT 1, 68
                                                                                
END FUNCTION



FUNCTION mostrar_registro(num_registro)
DEFINE r_are            RECORD LIKE gent003.*
DEFINE num_registro	INTEGER

CALL mostrar_cliente()
IF vm_num_rows > 0 THEN
	SELECT * INTO rm_cxc.* FROM cxct003 WHERE ROWID = num_registro	
	IF STATUS = NOTFOUND THEN
		CALL fgl_winmessage (vg_producto,'No existe registro con índice: ' || vm_row_current,'exclamation')
		RETURN
	END IF
	DISPLAY BY NAME rm_cxc.z03_areaneg, rm_cxc.z03_credit_auto,
			rm_cxc.z03_credit_dias, rm_cxc.z03_cupocred_mb,
			rm_cxc.z03_cupocred_ma,	rm_cxc.z03_dcto_item_c,
			rm_cxc.z03_dcto_item_r, rm_cxc.z03_dcto_mano_c,
			rm_cxc.z03_dcto_mano_r, rm_cxc.z03_usuario,
			rm_cxc.z03_fecing
	CALL fl_lee_area_negocio(vg_codcia,rm_cxc.z03_areaneg) RETURNING r_are.*
        DISPLAY r_are.g03_nombre TO tit_area
ELSE
	RETURN
END IF

END FUNCTION



FUNCTION mostrar_cliente()

INITIALIZE rm_cli.* TO NULL
CALL fl_lee_cliente_general(vm_codcli) RETURNING rm_cli.*
DISPLAY vm_codcli TO tit_codcli
DISPLAY rm_cli.z01_nomcli TO tit_nomcli

END FUNCTION



FUNCTION poner_credit_dias()
IF rm_cxc.z03_credit_auto = 'N' THEN
	LET rm_cxc.z03_credit_dias = 0
	DISPLAY BY NAME rm_cxc.z03_credit_dias
ELSE
	IF rm_cxc.z03_credit_dias = 0 OR rm_cxc.z03_credit_dias IS NULL THEN
		RETURN 1
	END IF
END IF
RETURN 0

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
