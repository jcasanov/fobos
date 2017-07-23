------------------------------------------------------------------------------
-- Titulo           : cxcp100.4gl - Configuración Compañías para Ctas. x Cobrar
-- Elaboracion      : 03-oct-2001
-- Autor            : NPC
-- Formato Ejecucion: fglrun cxcp100 base módulo compañía
-- Ultima Correccion: 
-- Motivo Correccion: 
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE rm_cxc		RECORD LIKE cxct000.*
DEFINE rm_z61		RECORD LIKE cxct061.*
DEFINE vm_num_rows	SMALLINT
DEFINE vm_row_current	SMALLINT
DEFINE vm_max_rows	SMALLINT
DEFINE vm_r_rows	ARRAY [50] OF INTEGER



MAIN

DEFER QUIT 
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/cxcp100.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 3 THEN          -- Validar # parámetros correcto
	CALL fgl_winmessage(vg_producto, 'Número de parámetros incorrecto', 'stop')
	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_proceso = 'cxcp100'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
--#CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL control_master()

END MAIN



FUNCTION control_master()
DEFINE confir		CHAR(6)

CALL fl_nivel_isolation()
LET vm_max_rows	= 50
OPEN WINDOW wf AT 03, 02 WITH 22 ROWS, 80 COLUMNS
    ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE 0, BORDER,
	      MESSAGE LINE LAST - 1)
OPTIONS INPUT WRAP,
	ACCEPT KEY	F12
OPEN FORM f_cxc FROM "../forms/cxcf100_1"
DISPLAY FORM f_cxc
INITIALIZE rm_cxc.* TO NULL
LET vm_num_rows = 0
LET vm_row_current = 0
CALL muestra_contadores(vm_row_current, vm_num_rows)
MENU 'OPCIONES'
	BEFORE MENU
		HIDE OPTION 'Avanzar'
		HIDE OPTION 'Retroceder'
		HIDE OPTION 'Modificar'
		HIDE OPTION 'Bloquear/Activar'
	COMMAND KEY('I') 'Ingresar' 'Ingresar nuevos registros. '
		IF vm_num_rows = vm_max_rows THEN
			CALL fl_mensaje_arreglo_lleno()
		ELSE
			CALL control_ingreso()
		END IF
		IF vm_num_rows = 1 THEN
			SHOW OPTION 'Modificar'
			SHOW OPTION 'Bloquear/Activar'
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
			SHOW OPTION 'Bloquear/Activar'
			HIDE OPTION 'Avanzar'
			HIDE OPTION 'Retroceder'
			IF vm_num_rows = 0 THEN
				HIDE OPTION 'Modificar'
				HIDE OPTION 'Bloquear/Activar'
			END IF
		ELSE
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Modificar'
			SHOW OPTION 'Bloquear/Activar'
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
     	COMMAND KEY('B') 'Bloquear/Activar' 'Bloquear o activar registro. '
		CALL bloquear_activar()
	COMMAND KEY('S') 'Salir' 'Salir del programa. '
		EXIT MENU
END MENU

END FUNCTION



FUNCTION control_ingreso()
DEFINE num_aux		INTEGER

CALL fl_retorna_usuario()
INITIALIZE rm_cxc.*, rm_z61.* TO NULL
CLEAR tit_compania, tit_cli_mb, tit_cli_ma, tit_ant_mb, tit_ant_ma
LET rm_cxc.z00_credit_auto  = 'N'
LET rm_cxc.z00_bloq_vencido = 'N'
LET rm_cxc.z00_credit_dias  = 0
LET rm_cxc.z00_tasa_mora    = 0
LET rm_cxc.z00_cobra_mora   = 'S'
LET rm_cxc.z00_estado       = 'A'
LET rm_cxc.z00_mespro       = MONTH(TODAY)
LET rm_cxc.z00_anopro       = YEAR(TODAY)
CALL muestra_estado()
LET rm_z61.z61_num_pagos      = 1
LET rm_z61.z61_max_pagos      = 300
LET rm_z61.z61_intereses      = 0
LET rm_z61.z61_dia_entre_pago = 1
LET rm_z61.z61_max_entre_pago = 360
LET rm_z61.z61_credito_max    = 0
LET rm_z61.z61_credito_min    = 0
LET rm_z61.z61_usuario        = vg_usuario
CALL leer_datos('I')
IF NOT int_flag THEN
	BEGIN WORK
		INSERT INTO cxct000 VALUES (rm_cxc.*)
		LET num_aux              = SQLCA.SQLERRD[6]
		LET rm_z61.z61_compania  = rm_cxc.z00_compania
		LET rm_z61.z61_localidad = vg_codloc
		LET rm_z61.z61_fecing    = CURRENT
		INSERT INTO cxct061 VALUES (rm_z61.*)
	COMMIT WORK
	LET vm_num_rows               = vm_num_rows + 1
	LET vm_row_current            = vm_num_rows
	LET vm_r_rows[vm_row_current] = num_aux
	CALL mostrar_registro(vm_r_rows[vm_num_rows])	
	CALL muestra_contadores(vm_row_current, vm_num_rows)
	CALL fl_mensaje_registro_ingresado()
ELSE
	CLEAR FORM
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
IF rm_cxc.z00_estado = 'B' THEN
	CALL fl_mensaje_estado_bloqueado()
	RETURN
END IF
CALL mostrar_registro(vm_r_rows[vm_row_current])
BEGIN WORK
WHENEVER ERROR CONTINUE
DECLARE q_up CURSOR FOR SELECT * FROM cxct000
	WHERE ROWID = vm_r_rows[vm_row_current]
	FOR UPDATE
OPEN q_up
FETCH q_up INTO rm_cxc.*
IF STATUS < 0 THEN
	ROLLBACK WORK
	CALL fl_mensaje_bloqueo_otro_usuario()
	WHENEVER ERROR STOP
	RETURN
END IF
WHENEVER ERROR STOP
CALL leer_datos('M')
IF NOT int_flag THEN
	UPDATE cxct000 SET z00_credit_auto  = rm_cxc.z00_credit_auto, 
			   z00_credit_dias  = rm_cxc.z00_credit_dias, 
			   z00_bloq_vencido = rm_cxc.z00_bloq_vencido, 
			   z00_tasa_mora    = rm_cxc.z00_tasa_mora, 
			   z00_cobra_mora   = rm_cxc.z00_cobra_mora, 
			   z00_aux_clte_mb  = rm_cxc.z00_aux_clte_mb,
			   z00_aux_clte_ma  = rm_cxc.z00_aux_clte_ma,
			   z00_aux_ant_mb   = rm_cxc.z00_aux_ant_mb,
			   z00_aux_ant_ma   = rm_cxc.z00_aux_ant_ma
			WHERE CURRENT OF q_up
	UPDATE cxct061 SET * = rm_z61.*
		WHERE z61_compania  = rm_z61.z61_compania
		  AND z61_localidad = rm_z61.z61_localidad
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



FUNCTION control_consulta()
DEFINE codc_aux		LIKE cxct000.z00_compania
DEFINE nomc_aux		LIKE gent001.g01_razonsocial
DEFINE cod_aux		LIKE ctbt010.b10_cuenta
DEFINE nom_aux		LIKE ctbt010.b10_descripcion
DEFINE query		VARCHAR(400)
DEFINE expr_sql		VARCHAR(400)
DEFINE num_reg		INTEGER

LET int_flag = 0
INITIALIZE codc_aux, cod_aux TO NULL
CLEAR FORM
CONSTRUCT BY NAME expr_sql ON z00_compania, z00_credit_auto, z00_bloq_vencido,
	z00_credit_dias, z61_num_pagos, z00_tasa_mora, z61_max_pagos,
	z00_cobra_mora, z61_intereses, z61_dia_entre_pago, z61_max_entre_pago,
	z00_aux_clte_mb, z00_aux_clte_ma, z00_aux_ant_mb, z00_aux_ant_ma
	ON KEY(F2)
		IF INFIELD(z00_compania) THEN
			CALL fl_ayuda_companias_cobranzas()
				RETURNING codc_aux, nomc_aux
			LET int_flag = 0
			IF codc_aux IS NOT NULL THEN
				DISPLAY codc_aux TO z00_compania 
				DISPLAY nomc_aux TO tit_compania
			END IF 
		END IF
		IF INFIELD(z00_aux_clte_mb) THEN
			CALL fl_ayuda_cuenta_contable(vg_codcia, -1)
				RETURNING cod_aux, nom_aux
			LET int_flag = 0
			IF cod_aux IS NOT NULL THEN
				DISPLAY cod_aux TO z00_aux_clte_mb 
				DISPLAY nom_aux TO tit_cli_mb
			END IF 
		END IF
		IF INFIELD(z00_aux_clte_ma) THEN
			CALL fl_ayuda_cuenta_contable(vg_codcia, -1)
				RETURNING cod_aux, nom_aux
			LET int_flag = 0
			IF cod_aux IS NOT NULL THEN
				DISPLAY cod_aux TO z00_aux_clte_ma 
				DISPLAY nom_aux TO tit_cli_ma
			END IF 
		END IF
		IF INFIELD(z00_aux_ant_mb) THEN
			CALL fl_ayuda_cuenta_contable(vg_codcia, -1)
				RETURNING cod_aux, nom_aux
			LET int_flag = 0
			IF cod_aux IS NOT NULL THEN
				DISPLAY cod_aux TO z00_aux_ant_mb
				DISPLAY nom_aux TO tit_ant_mb
			END IF 
		END IF
		IF INFIELD(z00_aux_ant_ma) THEN
			CALL fl_ayuda_cuenta_contable(vg_codcia, -1)
				RETURNING cod_aux, nom_aux
			LET int_flag = 0
			IF cod_aux IS NOT NULL THEN
				DISPLAY cod_aux TO z00_aux_ant_ma
				DISPLAY nom_aux TO tit_ant_ma
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
LET query = 'SELECT *, cxct000.ROWID ',
		' FROM cxct000, cxct061 ',
		' WHERE ', expr_sql,
		'   AND z61_compania  = z00_compania ',
		'   AND z61_localidad = ', vg_codloc,
		' ORDER BY 1'
PREPARE cons FROM query	
DECLARE q_cons CURSOR FOR cons
LET vm_num_rows = 0
FOREACH q_cons INTO rm_cxc.*, rm_z61.*, num_reg
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
ELSE  
	LET vm_row_current = 1
	CALL mostrar_registro(vm_r_rows[vm_row_current])
END IF
CALL muestra_contadores(vm_row_current, vm_num_rows)

END FUNCTION



FUNCTION leer_datos (flag_mant)
DEFINE flag_mant	CHAR(1)
DEFINE resp		CHAR(6)
DEFINE resul		SMALLINT
DEFINE r_cta		RECORD LIKE ctbt010.*
DEFINE r_cxc_aux	RECORD LIKE cxct000.*
DEFINE cod_cia_aux	LIKE gent001.g01_compania
DEFINE cod_aux		LIKE ctbt010.b10_cuenta
DEFINE nom_aux		LIKE ctbt010.b10_descripcion

INITIALIZE cod_cia_aux, cod_aux, nom_aux, r_cxc_aux.*, r_cta.* TO NULL
DISPLAY BY NAME rm_cxc.z00_credit_auto, rm_cxc.z00_bloq_vencido,
		rm_cxc.z00_credit_dias, rm_cxc.z00_tasa_mora,
		rm_cxc.z00_cobra_mora, rm_cxc.z00_mespro, rm_cxc.z00_anopro
LET int_flag = 0
INPUT BY NAME rm_cxc.z00_compania, rm_cxc.z00_credit_auto,
	rm_cxc.z00_bloq_vencido, rm_cxc.z00_credit_dias, rm_z61.z61_num_pagos,
	rm_cxc.z00_tasa_mora, rm_z61.z61_max_pagos, rm_cxc.z00_cobra_mora,
	rm_z61.z61_intereses, rm_z61.z61_dia_entre_pago,
	rm_z61.z61_max_entre_pago,rm_cxc.z00_aux_clte_mb,rm_cxc.z00_aux_clte_ma,
	rm_cxc.z00_aux_ant_mb, rm_cxc.z00_aux_ant_ma
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
        	IF FIELD_TOUCHED(rm_cxc.z00_compania, rm_cxc.z00_credit_auto, 
			rm_cxc.z00_bloq_vencido, rm_cxc.z00_credit_dias, 
			rm_z61.z61_num_pagos, rm_cxc.z00_tasa_mora,
			rm_z61.z61_max_pagos, rm_cxc.z00_cobra_mora, 
			rm_z61.z61_intereses, rm_z61.z61_dia_entre_pago,
			rm_z61.z61_max_entre_pago, rm_cxc.z00_aux_clte_mb,
			rm_cxc.z00_aux_clte_ma, rm_cxc.z00_aux_ant_mb,
			rm_cxc.z00_aux_ant_ma)
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
		IF INFIELD(z00_compania) THEN
			CALL fl_ayuda_compania() RETURNING cod_cia_aux
			LET int_flag = 0
			IF cod_cia_aux IS NOT NULL THEN
				CALL fl_lee_compania(cod_cia_aux)
					RETURNING rg_cia.*
				LET rm_cxc.z00_compania = cod_cia_aux
				DISPLAY BY NAME rm_cxc.z00_compania 
				DISPLAY rg_cia.g01_razonsocial TO tit_compania
			END IF 
		END IF
		IF INFIELD(z00_aux_clte_mb) THEN
			CALL fl_ayuda_cuenta_contable(vg_codcia, -1)
				RETURNING cod_aux, nom_aux
			LET int_flag = 0
			IF cod_aux IS NOT NULL THEN
				LET rm_cxc.z00_aux_clte_mb = cod_aux
				DISPLAY BY NAME rm_cxc.z00_aux_clte_mb 
				DISPLAY nom_aux TO tit_cli_mb
			END IF 
		END IF
		IF INFIELD(z00_aux_clte_ma) THEN
			CALL fl_ayuda_cuenta_contable(vg_codcia, -1)
				RETURNING cod_aux, nom_aux
			LET int_flag = 0
			IF cod_aux IS NOT NULL THEN
				LET rm_cxc.z00_aux_clte_ma = cod_aux
				DISPLAY BY NAME rm_cxc.z00_aux_clte_ma 
				DISPLAY nom_aux TO tit_cli_ma
			END IF 
		END IF
		IF INFIELD(z00_aux_ant_mb) THEN
			CALL fl_ayuda_cuenta_contable(vg_codcia, -1)
				RETURNING cod_aux, nom_aux
			LET int_flag = 0
			IF cod_aux IS NOT NULL THEN
				LET rm_cxc.z00_aux_ant_mb = cod_aux
				DISPLAY BY NAME rm_cxc.z00_aux_ant_mb 
				DISPLAY nom_aux TO tit_ant_mb
			END IF 
		END IF
		IF INFIELD(z00_aux_ant_ma) THEN
			CALL fl_ayuda_cuenta_contable(vg_codcia, -1)
				RETURNING cod_aux, nom_aux
			LET int_flag = 0
			IF cod_aux IS NOT NULL THEN
				LET rm_cxc.z00_aux_ant_ma = cod_aux
				DISPLAY BY NAME rm_cxc.z00_aux_ant_ma 
				DISPLAY nom_aux TO tit_ant_ma
			END IF 
		END IF
	BEFORE FIELD z00_compania
		IF flag_mant = 'M' THEN
			NEXT FIELD NEXT
		END IF
	BEFORE FIELD z00_credit_auto
		IF rm_cxc.z00_compania IS NULL THEN
			CALL fgl_winmessage(vg_producto,'Ingrese la compañía primero','info')
			NEXT FIELD z00_compania
		END IF
	BEFORE FIELD z00_tasa_mora
		CALL poner_credit_dias() RETURNING resul
	AFTER FIELD z00_compania
		IF rm_cxc.z00_compania IS NOT NULL THEN
			CALL fl_lee_compania(rm_cxc.z00_compania)
		 		RETURNING rg_cia.*
			IF rg_cia.g01_compania IS NULL THEN
				CALL fgl_winmessage(vg_producto,'Compañía no existe','exclamation')
				NEXT FIELD z00_compania
			END IF
			DISPLAY rg_cia.g01_razonsocial TO tit_compania
			IF rg_cia.g01_estado = 'B' THEN
                                CALL fl_mensaje_estado_bloqueado()
                                NEXT FIELD z00_compania
                        END IF		 
			CALL fl_lee_compania_cobranzas(rm_cxc.z00_compania)
                        	RETURNING r_cxc_aux.*
			IF r_cxc_aux.z00_compania IS NOT NULL THEN
				CALL fgl_winmessage(vg_producto,'Compañía ya ha sido asignada a ctas. x cobrar','exclamation')
				NEXT FIELD z00_compania
			END IF
		ELSE
			CLEAR tit_compania
		END IF
	AFTER FIELD z00_credit_auto
		CALL poner_credit_dias() RETURNING resul
	AFTER FIELD z00_aux_clte_mb 
		IF rm_cxc.z00_aux_clte_mb IS NOT NULL THEN
			CALL fl_lee_cuenta(rm_cxc.z00_compania,
						rm_cxc.z00_aux_clte_mb)
				RETURNING r_cta.*
			IF r_cta.b10_cuenta IS NULL  THEN
				CALL fgl_winmessage(vg_producto,'Cuenta no existe para esta compañía','exclamation')
				NEXT FIELD z00_aux_clte_mb
			END IF
			DISPLAY r_cta.b10_descripcion TO tit_cli_mb
			IF rm_cxc.z00_aux_clte_mb = rm_cxc.z00_aux_ant_mb
			OR rm_cxc.z00_aux_clte_mb = rm_cxc.z00_aux_ant_ma THEN
				CALL fgl_winmessage(vg_producto,'La cuenta de cliente debe ser distinta del anticípo','info')
				NEXT FIELD z00_aux_clte_mb
			END IF
			IF r_cta.b10_estado = 'B' THEN
                                CALL fl_mensaje_estado_bloqueado()
                                NEXT FIELD z00_aux_clte_mb
                        END IF
			IF r_cta.b10_permite_mov = 'N' THEN
				CALL fl_mostrar_mensaje('Cuenta no permite movimiento.', 'exclamation')
				NEXT FIELD z00_aux_clte_mb
			END IF
		ELSE
			CLEAR tit_cli_mb
		END IF
	AFTER FIELD z00_aux_clte_ma 
		IF rm_cxc.z00_aux_clte_ma IS NOT NULL THEN
			CALL fl_lee_cuenta(rm_cxc.z00_compania,
						rm_cxc.z00_aux_clte_ma)
				RETURNING r_cta.*
			IF r_cta.b10_cuenta IS NULL  THEN
				CALL fgl_winmessage(vg_producto,'Cuenta no existe para esta compañía','exclamation')
				NEXT FIELD z00_aux_clte_ma
			END IF
			DISPLAY r_cta.b10_descripcion TO tit_cli_ma
			IF rm_cxc.z00_aux_clte_ma = rm_cxc.z00_aux_ant_mb
			OR rm_cxc.z00_aux_clte_ma = rm_cxc.z00_aux_ant_ma THEN
				CALL fgl_winmessage(vg_producto,'La cuenta de cliente debe ser distinta del anticípo','info')
				NEXT FIELD z00_aux_clte_ma
			END IF
			IF r_cta.b10_estado = 'B' THEN
                                CALL fl_mensaje_estado_bloqueado()
                                NEXT FIELD z00_aux_clte_ma
                        END IF
			IF r_cta.b10_permite_mov = 'N' THEN
				CALL fl_mostrar_mensaje('Cuenta no permite movimiento.', 'exclamation')
				NEXT FIELD z00_aux_clte_ma
			END IF
		ELSE
			CLEAR tit_cli_ma
		END IF
	AFTER FIELD z00_aux_ant_mb 
		IF rm_cxc.z00_aux_ant_mb IS NOT NULL THEN
			CALL fl_lee_cuenta(rm_cxc.z00_compania,
						rm_cxc.z00_aux_ant_mb)
				RETURNING r_cta.*
			IF r_cta.b10_cuenta IS NULL  THEN
				CALL fgl_winmessage(vg_producto,'Cuenta no existe para esta compañía','exclamation')
				NEXT FIELD z00_aux_ant_mb
			END IF
			DISPLAY r_cta.b10_descripcion TO tit_ant_mb
			IF rm_cxc.z00_aux_ant_mb = rm_cxc.z00_aux_clte_mb
			OR rm_cxc.z00_aux_ant_mb = rm_cxc.z00_aux_clte_ma THEN
				CALL fgl_winmessage(vg_producto,'La cuenta de anticípo debe ser distinta del cliente','info')
				NEXT FIELD z00_aux_ant_mb
			END IF
			IF r_cta.b10_estado = 'B' THEN
                                CALL fl_mensaje_estado_bloqueado()
                                NEXT FIELD z00_aux_ant_mb
                        END IF
			IF r_cta.b10_permite_mov = 'N' THEN
				CALL fl_mostrar_mensaje('Cuenta no permite movimiento.', 'exclamation')
				NEXT FIELD z00_aux_ant_mb
			END IF
		ELSE
			CLEAR tit_ant_mb
		END IF
	AFTER FIELD z00_aux_ant_ma 
		IF rm_cxc.z00_aux_ant_ma IS NOT NULL THEN
			CALL fl_lee_cuenta(rm_cxc.z00_compania,
						rm_cxc.z00_aux_ant_ma)
				RETURNING r_cta.*
			IF r_cta.b10_cuenta IS NULL  THEN
				CALL fgl_winmessage(vg_producto,'Cuenta no existe para esta compañía','exclamation')
				NEXT FIELD z00_aux_ant_ma
			END IF
			DISPLAY r_cta.b10_descripcion TO tit_ant_ma
			IF rm_cxc.z00_aux_ant_ma = rm_cxc.z00_aux_clte_mb
			OR rm_cxc.z00_aux_ant_ma = rm_cxc.z00_aux_clte_ma THEN
				CALL fgl_winmessage(vg_producto,'La cuenta de anticípo debe ser distinta del cliente','info')
				NEXT FIELD z00_aux_ant_ma
			END IF
			IF r_cta.b10_estado = 'B' THEN
                                CALL fl_mensaje_estado_bloqueado()
                                NEXT FIELD z00_aux_ant_ma
                        END IF
			IF r_cta.b10_permite_mov = 'N' THEN
				CALL fl_mostrar_mensaje('Cuenta no permite movimiento.', 'exclamation')
				NEXT FIELD z00_aux_ant_ma
			END IF
		ELSE
			CLEAR tit_ant_ma
		END IF
	AFTER INPUT
		CALL poner_credit_dias() RETURNING resul
		IF resul = 1 THEN
			CALL fgl_winmessage(vg_producto,'Crédito de días debe ser mayor a cero, si hay crédito automático','info')
			NEXT FIELD z00_credit_dias
		END IF
		IF rm_z61.z61_num_pagos > rm_z61.z61_max_pagos THEN
			CALL fl_mostrar_mensaje('El número de pagos no puede ser mayor al maximo de pagos.', 'exclamation')
			NEXT FIELD z61_num_pagos
		END IF
		IF rm_z61.z61_dia_entre_pago > rm_z61.z61_max_entre_pago THEN
			CALL fl_mostrar_mensaje('Los días entre pagos no puede ser mayor al maximo de días para los pagos.', 'exclamation')
			NEXT FIELD z61_dia_entre_pago
		END IF
END INPUT

END FUNCTION



FUNCTION poner_credit_dias()

IF rm_cxc.z00_credit_auto = 'N' THEN
	LET rm_cxc.z00_credit_dias = 0
	DISPLAY BY NAME rm_cxc.z00_credit_dias
ELSE
	IF rm_cxc.z00_credit_dias = 0 OR rm_cxc.z00_credit_dias IS NULL THEN
		RETURN 1
	END IF
END IF
RETURN 0

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



FUNCTION mostrar_registro(num_registro)
DEFINE r_cta		RECORD LIKE ctbt010.*
DEFINE num_registro	INTEGER

IF vm_num_rows <= 0 THEN
	RETURN
END IF
SELECT * INTO rm_cxc.*, rm_z61.*
	FROM cxct000, cxct061
	WHERE cxct000.ROWID = num_registro
	  AND z61_compania  = z00_compania
	  AND z61_localidad = vg_codloc
IF STATUS = NOTFOUND THEN
	CALL fgl_winmessage(vg_producto,'No existe registro con índice: ' || vm_row_current, 'exclamation')
	RETURN
END IF
DISPLAY BY NAME rm_cxc.z00_compania, rm_cxc.z00_credit_auto, 
		rm_cxc.z00_bloq_vencido, rm_cxc.z00_credit_dias, 
		rm_cxc.z00_tasa_mora, rm_cxc.z00_cobra_mora, 
		rm_cxc.z00_aux_clte_mb, rm_cxc.z00_aux_clte_ma,
		rm_cxc.z00_aux_ant_mb, rm_cxc.z00_aux_ant_ma,
		rm_cxc.z00_mespro, rm_cxc.z00_anopro, rm_z61.z61_num_pagos,
		rm_z61.z61_max_pagos, rm_z61.z61_intereses,
		rm_z61.z61_dia_entre_pago, rm_z61.z61_max_entre_pago
CALL fl_lee_compania(rm_cxc.z00_compania) RETURNING rg_cia.*
DISPLAY rg_cia.g01_razonsocial TO tit_compania
CALL fl_lee_cuenta(rm_cxc.z00_compania,rm_cxc.z00_aux_clte_mb) RETURNING r_cta.*
DISPLAY r_cta.b10_descripcion TO tit_cli_mb
CALL fl_lee_cuenta(rm_cxc.z00_compania,rm_cxc.z00_aux_clte_ma) RETURNING r_cta.*
DISPLAY r_cta.b10_descripcion TO tit_cli_ma
CALL fl_lee_cuenta(rm_cxc.z00_compania,rm_cxc.z00_aux_ant_mb) RETURNING r_cta.*
DISPLAY r_cta.b10_descripcion TO tit_ant_mb
CALL fl_lee_cuenta(rm_cxc.z00_compania,rm_cxc.z00_aux_ant_ma) RETURNING r_cta.*
DISPLAY r_cta.b10_descripcion TO tit_ant_ma
CALL muestra_estado()

END FUNCTION



FUNCTION bloquear_activar()
DEFINE confir	CHAR(6)

IF vm_num_rows = 0 THEN
	CALL fl_mensaje_consultar_primero()
	RETURN
END IF
LET int_flag = 0
BEGIN WORK
WHENEVER ERROR CONTINUE
DECLARE q_ba CURSOR FOR SELECT * FROM cxct000
	WHERE ROWID = vm_r_rows[vm_row_current]
	FOR UPDATE
OPEN q_ba
FETCH q_ba INTO rm_cxc.*
IF STATUS < 0 THEN
	ROLLBACK WORK
	CALL fl_mensaje_bloqueo_otro_usuario()
	WHENEVER ERROR STOP
	RETURN
END IF	
WHENEVER ERROR STOP
CALL fl_mensaje_seguro_ejecutar_proceso() RETURNING confir
IF confir <> 'Yes' THEN
	ROLLBACK WORK
	RETURN
END IF
LET int_flag = 1
CALL bloquea_activa_registro()
COMMIT WORK

END FUNCTION



FUNCTION bloquea_activa_registro()
DEFINE estado	CHAR(1)

IF rm_cxc.z00_estado = 'A' THEN
	DISPLAY 'BLOQUEADO' TO tit_estado_cob
	LET estado = 'B'
ELSE 
	DISPLAY 'ACTIVO' TO tit_estado_cob
	LET estado = 'A'
END IF
DISPLAY estado TO tit_est
UPDATE cxct000 SET z00_estado = estado WHERE CURRENT OF q_ba
LET rm_cxc.z00_estado = estado

END FUNCTION



FUNCTION muestra_estado()

IF rm_cxc.z00_estado = 'A' THEN
	DISPLAY 'ACTIVO' TO tit_estado_cob
ELSE
	DISPLAY 'BLOQUEADO' TO tit_estado_cob
END IF
DISPLAY rm_cxc.z00_estado TO tit_est

END FUNCTION
