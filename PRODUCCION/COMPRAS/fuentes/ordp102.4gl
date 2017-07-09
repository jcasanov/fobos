--------------------------------------------------------------------------------
-- Titulo           : ordp102.4gl - Mantenimiento Porcentajes de Retenciones
-- Elaboracion      : 17-sep-2001
-- Autor            : NPC
-- Formato Ejecucion: fglrun ordp102 base módulo commpañía
-- Ultima Correccion: 
-- Motivo Correccion: 
--------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE rm_c02		RECORD LIKE ordt002.*
DEFINE rm_c03		RECORD LIKE ordt003.*
DEFINE rm_retsri	ARRAY [10000] OF RECORD
			c03_codigo_sri		LIKE ordt003.c03_codigo_sri,
			c03_concepto_ret	LIKE ordt003.c03_concepto_ret,
			c03_fecha_ini_porc	LIKE ordt003.c03_fecha_ini_porc,
			c03_fecha_fin_porc	LIKE ordt003.c03_fecha_fin_porc,
			c03_ingresa_proc	LIKE ordt003.c03_ingresa_proc,
			c03_estado		LIKE ordt003.c03_estado
			END RECORD
DEFINE rm_audi		ARRAY [10000] OF RECORD
			     c03_usuario_modifi LIKE ordt003.c03_usuario_modifi,
			     c03_fecha_modifi   LIKE ordt003.c03_fecha_modifi,
			     c03_usuario_elimin LIKE ordt003.c03_usuario_elimin,
			     c03_fecha_elimin   LIKE ordt003.c03_fecha_elimin
			END RECORD
DEFINE vm_num_rows	SMALLINT
DEFINE vm_row_current	SMALLINT
DEFINE vm_max_rows	SMALLINT
DEFINE vm_r_rows	ARRAY [50] OF INTEGER
DEFINE vm_num_det	INTEGER
DEFINE vm_max_det	INTEGER
DEFINE rm_detj91	ARRAY [50] OF RECORD
				j91_codigo_pago	LIKE cajt091.j91_codigo_pago,
				j01_nombre	LIKE cajt001.j01_nombre,
				j91_cont_cred	LIKE cajt091.j91_cont_cred,
                                tit_cont_cred	VARCHAR(10),
				j91_aux_cont	LIKE cajt091.j91_aux_cont,
				b10_descripcion	LIKE ctbt010.b10_descripcion
			END RECORD
DEFINE vm_num_ret	SMALLINT
DEFINE vm_max_ret	SMALLINT



MAIN

DEFER QUIT 
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/ordp102.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 3 THEN          -- Validar # parámetros correcto
	CALL fl_mostrar_mensaje('Número de parámetros incorrecto.','stop')
	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_proceso = 'ordp102'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
--#CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL control_master()

END MAIN



FUNCTION control_master()
DEFINE lin_menu		SMALLINT
DEFINE row_ini  	SMALLINT
DEFINE num_rows 	SMALLINT
DEFINE num_cols 	SMALLINT

CALL fl_nivel_isolation()
LET vm_max_rows = 50
LET vm_max_det  = 10000
LET vm_max_ret  = 50
LET lin_menu = 0
LET row_ini  = 3
LET num_rows = 21
LET num_cols = 80
IF vg_gui = 0 THEN
	LET lin_menu = 1
	LET row_ini  = 4
	LET num_rows = 20
	LET num_cols = 78
END IF
OPEN WINDOW wf AT row_ini, 2 WITH num_rows ROWS, num_cols COLUMNS
    ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE lin_menu,BORDER,
	      MESSAGE LINE LAST - 1)
IF vg_gui = 1 THEN
	OPEN FORM f_ord FROM "../forms/ordf102_1"
ELSE
	OPEN FORM f_ord FROM "../forms/ordf102_1c"
END IF
DISPLAY FORM f_ord
INITIALIZE rm_c02.* TO NULL
LET vm_num_rows    = 0
LET vm_row_current = 0
CALL muestra_contadores(vm_row_current, vm_num_rows)

MENU 'OPCIONES'
	BEFORE MENU
		HIDE OPTION 'Avanzar'
		HIDE OPTION 'Retroceder'
		HIDE OPTION 'Modificar'
		HIDE OPTION 'Códigos SRI'
		HIDE OPTION 'Tipos de Pago'
		HIDE OPTION 'Bloquear/Activar'
	COMMAND KEY('I') 'Ingresar' 'Ingresar nuevos registros. '
		IF vm_num_rows = vm_max_rows THEN
			CALL fl_mensaje_arreglo_lleno()
		ELSE
			CALL control_ingreso()
		END IF
		IF vm_num_rows = 1 THEN
			SHOW OPTION 'Modificar'
			SHOW OPTION 'Códigos SRI'
			SHOW OPTION 'Tipos de Pago'
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
			SHOW OPTION 'Códigos SRI'
			SHOW OPTION 'Tipos de Pago'
			SHOW OPTION 'Bloquear/Activar'
			HIDE OPTION 'Avanzar'
			HIDE OPTION 'Retroceder'
			IF vm_num_rows = 0 THEN
				HIDE OPTION 'Modificar'
				HIDE OPTION 'Códigos SRI'
				HIDE OPTION 'Tipos de Pago'
				HIDE OPTION 'Bloquear/Activar'
			END IF
		ELSE
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Modificar'
			SHOW OPTION 'Códigos SRI'
			SHOW OPTION 'Tipos de Pago'
			SHOW OPTION 'Bloquear/Activar'
		END IF
		IF vm_row_current <= 1 THEN
                        HIDE OPTION 'Retroceder'
                END IF
     	COMMAND KEY('N') 'Códigos SRI' 'Permite ingresar tipos de impuestos.'
		CALL control_codigos_sri()
     	COMMAND KEY('T') 'Tipos de Pago' 'Config. retenciones por tipo de pago.'
		CALL control_tipos_pago()
     	COMMAND KEY('B') 'Bloquear/Activar' 'Bloquear o activar registro. '
		CALL bloquear_activar()
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

CALL fl_retorna_usuario()
INITIALIZE rm_c02.* TO NULL
LET rm_c02.c02_compania    = vg_codcia
LET rm_c02.c02_tipo_ret    = 'F'
IF vg_gui = 0 THEN
	CALL muestra_tiporet(rm_c02.c02_tipo_ret)
END IF
LET rm_c02.c02_tipo_fuente = 'B'
IF vg_gui = 0 THEN
	CALL muestra_tipofuente(rm_c02.c02_tipo_fuente)
END IF
LET rm_c02.c02_usuario     = vg_usuario
LET rm_c02.c02_fecing      = CURRENT
LET rm_c02.c02_estado      = 'A'
CLEAR tit_aux_con
CALL muestra_estado()
CALL leer_datos('I')
IF NOT int_flag THEN
	LET rm_c02.c02_fecing = CURRENT
	INSERT INTO ordt002 VALUES (rm_c02.*)
	IF vm_num_rows = vm_max_rows THEN
		LET vm_num_rows = 1
	ELSE
		LET vm_num_rows = vm_num_rows + 1
	END IF
	LET vm_row_current            = vm_num_rows
	LET vm_r_rows[vm_row_current] = SQLCA.SQLERRD[6] 
	CALL fl_mensaje_registro_ingresado()
END IF
CLEAR FORM
IF vm_row_current > 0 THEN
	CALL mostrar_registro(vm_r_rows[vm_row_current])
END IF
CALL muestra_contadores(vm_row_current, vm_num_rows)

END FUNCTION



FUNCTION control_modificacion()
	
IF vm_num_rows = 0 THEN
	CALL fl_mensaje_consultar_primero()
	RETURN
END IF
IF rm_c02.c02_estado = 'B' THEN
	CALL fl_mensaje_estado_bloqueado()
	RETURN
END IF
CALL mostrar_registro(vm_r_rows[vm_row_current])
BEGIN WORK
WHENEVER ERROR CONTINUE
DECLARE q_up CURSOR FOR
	SELECT * FROM ordt002
		WHERE ROWID = vm_r_rows[vm_row_current]
	FOR UPDATE
OPEN q_up
FETCH q_up INTO rm_c02.*
IF STATUS < 0 THEN
	ROLLBACK WORK
	CALL fl_mensaje_bloqueo_otro_usuario()
	WHENEVER ERROR STOP
	RETURN
END IF
WHENEVER ERROR STOP
CALL leer_datos('M')
IF NOT int_flag THEN
	UPDATE ordt002
		SET c02_nombre      = rm_c02.c02_nombre,
		    c02_tipo_fuente = rm_c02.c02_tipo_fuente,
		    c02_aux_cont    = rm_c02.c02_aux_cont
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
 
END FUNCTION



FUNCTION control_consulta()
DEFINE cod_aux		LIKE ctbt010.b10_cuenta
DEFINE nom_aux		LIKE ctbt010.b10_descripcion
DEFINE query		CHAR(400)
DEFINE expr_sql		CHAR(400)
DEFINE num_reg		INTEGER

INITIALIZE cod_aux TO NULL
CLEAR FORM
LET int_flag = 0
CONSTRUCT BY NAME expr_sql ON c02_estado, c02_tipo_ret, c02_porcentaje,
	c02_nombre, c02_tipo_fuente, c02_aux_cont, c02_usuario, c02_fecing  
        ON KEY(F1,CONTROL-W)
		CALL llamar_visor_teclas()
	ON KEY(F2)
		IF INFIELD(c02_aux_cont) THEN
			CALL fl_ayuda_cuenta_contable(vg_codcia, -1)
				RETURNING cod_aux, nom_aux
			LET int_flag = 0
			IF cod_aux IS NOT NULL THEN
				DISPLAY cod_aux TO c02_aux_cont 
				DISPLAY nom_aux TO tit_aux_con
			END IF 
		END IF
	AFTER FIELD c02_tipo_ret
		LET rm_c02.c02_tipo_ret = GET_FLDBUF(c02_tipo_ret)
		IF vg_gui = 0 THEN
			IF rm_c02.c02_tipo_ret IS NOT NULL THEN
				CALL muestra_tiporet(rm_c02.c02_tipo_ret)
			ELSE
				CLEAR tit_tipo_ret
			END IF
		END IF
	AFTER FIELD c02_tipo_fuente
		LET rm_c02.c02_tipo_fuente = GET_FLDBUF(c02_tipo_fuente)
		IF vg_gui = 0 THEN
			IF rm_c02.c02_tipo_fuente IS NOT NULL THEN
				CALL muestra_tipofuente(rm_c02.c02_tipo_fuente)
			ELSE
				CLEAR tit_tipo_fuente
			END IF
		END IF
	BEFORE CONSTRUCT
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
END CONSTRUCT
IF int_flag THEN
	IF vm_row_current > 0 THEN
		CALL mostrar_registro(vm_r_rows[vm_row_current])
	ELSE
		CLEAR FORM
	END IF
	RETURN
END IF
LET query = 'SELECT *, ROWID FROM ordt002 ',
		' WHERE c02_compania = ', vg_codcia,
		'   AND ', expr_sql CLIPPED,
		' ORDER BY 2, 3 '
PREPARE cons FROM query	
DECLARE q_cons CURSOR FOR cons
LET vm_num_rows = 0
FOREACH q_cons INTO rm_c02.*, num_reg
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
DEFINE r_cta		RECORD LIKE ctbt010.*
DEFINE r_ret_aux	RECORD LIKE ordt002.*
DEFINE cod_aux		LIKE ctbt010.b10_cuenta
DEFINE nom_aux		LIKE ctbt010.b10_descripcion

INITIALIZE r_ret_aux.*, cod_aux TO NULL
DISPLAY BY NAME	rm_c02.c02_porcentaje, rm_c02.c02_usuario, rm_c02.c02_fecing
LET int_flag = 0
INPUT BY NAME rm_c02.c02_tipo_ret, rm_c02.c02_porcentaje, rm_c02.c02_nombre,
	rm_c02.c02_tipo_fuente, rm_c02.c02_aux_cont
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
	        IF FIELD_TOUCHED(rm_c02.c02_tipo_ret, rm_c02.c02_porcentaje,
				 rm_c02.c02_nombre, rm_c02.c02_tipo_fuente,
				 rm_c02.c02_aux_cont)
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
        ON KEY(F1,CONTROL-W)
		CALL llamar_visor_teclas()
	ON KEY(F2)
		IF INFIELD(c02_aux_cont) THEN
			CALL fl_ayuda_cuenta_contable(vg_codcia, -1)
				RETURNING cod_aux, nom_aux
			LET int_flag = 0
			IF cod_aux IS NOT NULL THEN
				LET rm_c02.c02_aux_cont = cod_aux
				DISPLAY BY NAME rm_c02.c02_aux_cont 
				DISPLAY nom_aux TO tit_aux_con
			END IF
		END IF 
	BEFORE INPUT
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
	BEFORE FIELD c02_tipo_ret, c02_porcentaje
		IF flag_mant = 'M' THEN
			NEXT FIELD NEXT
		END IF
	AFTER FIELD c02_tipo_ret
		CALL fl_lee_tipo_retencion(vg_codcia, rm_c02.c02_tipo_ret,
						rm_c02.c02_porcentaje)
			RETURNING r_ret_aux.*
		LET int_flag = 0
		IF rm_c02.c02_tipo_ret = r_ret_aux.c02_tipo_ret OR
		   rm_c02.c02_porcentaje = r_ret_aux.c02_porcentaje
		THEN
			CALL fl_mostrar_mensaje('Porcentaje de retención ya ha sido asignado.','exclamation')
			NEXT FIELD c02_tipo_ret
		END IF
		IF vg_gui = 0 THEN
			IF rm_c02.c02_tipo_ret IS NOT NULL THEN
				CALL muestra_tiporet(rm_c02.c02_tipo_ret)
			ELSE
				CLEAR tit_tipo_ret
			END IF
		END IF
	AFTER FIELD c02_tipo_fuente
		IF vg_gui = 0 THEN
			IF rm_c02.c02_tipo_fuente IS NOT NULL THEN
				CALL muestra_tipofuente(rm_c02.c02_tipo_fuente)
			ELSE
				CLEAR tit_tipo_fuente
			END IF
		END IF
	AFTER FIELD c02_porcentaje
		CALL fl_lee_tipo_retencion(vg_codcia,rm_c02.c02_tipo_ret,
						rm_c02.c02_porcentaje)
			RETURNING r_ret_aux.*
		LET int_flag = 0
		IF rm_c02.c02_porcentaje = r_ret_aux.c02_porcentaje OR
		   rm_c02.c02_tipo_ret = r_ret_aux.c02_tipo_ret
		THEN
			CALL fl_mostrar_mensaje('Porcentaje de retención ya fue asignado.','exclamation')
			NEXT FIELD c02_porcentaje
		END IF
	AFTER FIELD c02_aux_cont 
		IF rm_c02.c02_aux_cont IS NOT NULL THEN
			CALL fl_lee_cuenta(vg_codcia,rm_c02.c02_aux_cont)
				RETURNING r_cta.*
			IF r_cta.b10_cuenta IS NULL  THEN
				CALL fl_mostrar_mensaje('Cuenta no existe.','exclamation')
				NEXT FIELD c02_aux_cont
			END IF
			DISPLAY r_cta.b10_descripcion TO tit_aux_con
			IF r_cta.b10_permite_mov = 'N' THEN
				CALL fl_mostrar_mensaje('Cuenta no permite movimiento.', 'exclamation')
				NEXT FIELD c02_aux_cont
			END IF
			IF r_cta.b10_estado = 'B' THEN
				CALL fl_mensaje_estado_bloqueado()
				NEXT FIELD c02_aux_cont
			END IF
		ELSE
			CLEAR tit_aux_con
		END IF
END INPUT

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
DEFINE row_current		SMALLINT
DEFINE num_rows			SMALLINT
DEFINE nrow                     SMALLINT
                                                                                
LET nrow = 19
IF vg_gui = 1 THEN
	LET nrow = 1
END IF
DISPLAY "" AT nrow, 1
DISPLAY row_current, " de ", num_rows AT nrow, 67

END FUNCTION



FUNCTION mostrar_registro(num_registro)
DEFINE r_cta		RECORD LIKE ctbt010.*
DEFINE num_registro	INTEGER

IF vm_num_rows <= 0 THEN
	RETURN
END IF
SELECT * INTO rm_c02.* FROM ordt002 WHERE ROWID = num_registro
IF STATUS = NOTFOUND THEN
	CALL fl_mostrar_mensaje('No existe registro con índice: ' || vm_row_current,'exclamation')
	RETURN
END IF
DISPLAY BY NAME rm_c02.c02_tipo_ret, rm_c02.c02_porcentaje, rm_c02.c02_nombre,
		rm_c02.c02_tipo_fuente, rm_c02.c02_aux_cont, rm_c02.c02_usuario,
		rm_c02.c02_fecing
CALL fl_lee_cuenta(vg_codcia, rm_c02.c02_aux_cont) RETURNING r_cta.*
DISPLAY r_cta.b10_descripcion TO tit_aux_con
CALL muestra_estado()
IF vg_gui = 0 THEN
	CALL muestra_tiporet(rm_c02.c02_tipo_ret)
	CALL muestra_tipofuente(rm_c02.c02_tipo_fuente)
END IF

END FUNCTION



FUNCTION bloquear_activar()
DEFINE confir		CHAR(6)

IF vm_num_rows = 0 THEN
	CALL fl_mensaje_consultar_primero()
	RETURN
END IF
LET int_flag = 0
BEGIN WORK
WHENEVER ERROR CONTINUE
DECLARE q_ba CURSOR FOR
	SELECT * FROM ordt002
		WHERE ROWID = vm_r_rows[vm_row_current]
	FOR UPDATE
OPEN q_ba
FETCH q_ba INTO rm_c02.*
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

IF rm_c02.c02_estado = 'A' THEN
	DISPLAY 'BLOQUEADO' TO tit_estado_ret
	LET estado = 'B'
ELSE 
	DISPLAY 'ACTIVO' TO tit_estado_ret
	LET estado = 'A'
END IF
LET rm_c02.c02_estado = estado
DISPLAY BY NAME rm_c02.c02_estado
UPDATE ordt002 SET c02_estado = estado WHERE CURRENT OF q_ba

END FUNCTION



FUNCTION muestra_estado()

IF rm_c02.c02_estado = 'A' THEN
	DISPLAY 'ACTIVO' TO tit_estado_ret
ELSE
	DISPLAY 'BLOQUEADO' TO tit_estado_ret
END IF
DISPLAY BY NAME rm_c02.c02_estado

END FUNCTION



FUNCTION muestra_tiporet(tiporet)
DEFINE tiporet		CHAR(1)

CASE tiporet
	WHEN 'F'
		DISPLAY 'FUENTE' TO tit_tipo_ret
	WHEN 'I'
		DISPLAY 'IVA' TO tit_tipo_ret
	OTHERWISE
		CLEAR c02_tipo_ret, tit_tipo_ret
END CASE

END FUNCTION



FUNCTION muestra_tipofuente(tipofuente)
DEFINE tipofuente		CHAR(1)

CASE tipofuente
	WHEN 'B'
		DISPLAY 'BIENES' TO tit_tipo_fuente
	WHEN 'S'
		DISPLAY 'SERVICIOS' TO tit_tipo_fuente
	WHEN 'T'
		DISPLAY 'T O D O S' TO tit_tipo_fuente
	OTHERWISE
		CLEAR c02_tipo_fuente, tit_tipo_fuente
END CASE

END FUNCTION



FUNCTION control_codigos_sri()
DEFINE r_c03		RECORD LIKE ordt003.*
DEFINE codigo		LIKE ordt003.c03_codigo_sri
DEFINE nombre		LIKE ordt003.c03_concepto_ret
DEFINE ini_rows 	SMALLINT
DEFINE num_rows 	SMALLINT
DEFINE num_cols 	SMALLINT
DEFINE insertar 	SMALLINT
DEFINE i, j, k, l 	SMALLINT
DEFINE resp		CHAR(6)
DEFINE mensaje		VARCHAR(250)

IF rm_c02.c02_estado = 'B' THEN
	CALL fl_mensaje_estado_bloqueado()
	RETURN
END IF
LET ini_rows = 04
LET num_rows = 20
LET num_cols = 79
IF vg_gui = 0 THEN
	LET ini_rows = 05
	LET num_rows = 18
	LET num_cols = 78
END IF
OPEN WINDOW w_ordf102_2 AT ini_rows, 02 WITH num_rows ROWS, num_cols COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MESSAGE LINE LAST, BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_ordf102_2 FROM "../forms/ordf102_2"
ELSE
	OPEN FORM f_ordf102_2 FROM "../forms/ordf102_2c"
END IF
DISPLAY FORM f_ordf102_2
--#DISPLAY 'Código'		TO tit_col1 
--#DISPLAY 'Concepto'		TO tit_col2 
--#DISPLAY 'Fecha Ini.'		TO tit_col3 
--#DISPLAY 'Fecha Fin.'		TO tit_col4 
--#DISPLAY 'I'			TO tit_col5 
--#DISPLAY 'E'			TO tit_col6 
OPTIONS INSERT KEY F30,
	DELETE KEY F31
CLEAR c03_tipo_ret, c02_nombre, c03_porcentaje, c03_usuario_modifi,
	c03_fecha_modifi, c03_usuario_elimin, c03_fecha_elimin
FOR i = 1 TO fgl_scr_size('rm_retsri')
	CLEAR rm_retsri[i].*
END FOR
FOR i = 1 TO vm_max_det
	INITIALIZE rm_retsri[i].*, rm_audi[i].* TO NULL
END FOR
INITIALIZE rm_c03.* TO NULL
LET insertar = 1
BEGIN WORK
DECLARE q_c03 CURSOR WITH HOLD FOR
	SELECT * FROM ordt003
		WHERE c03_compania   = rm_c02.c02_compania
		  AND c03_tipo_ret   = rm_c02.c02_tipo_ret
		  AND c03_porcentaje = rm_c02.c02_porcentaje
OPEN q_c03
FETCH q_c03 INTO rm_c03.*
IF STATUS = NOTFOUND THEN
	LET rm_c03.c03_compania   = rm_c02.c02_compania
	LET rm_c03.c03_tipo_ret   = rm_c02.c02_tipo_ret
	LET rm_c03.c03_porcentaje = rm_c02.c02_porcentaje
	LET rm_c03.c03_usuario    = rm_c02.c02_usuario
	LET rm_c03.c03_fecing     = CURRENT
	LET insertar              = 0
END IF
WHENEVER ERROR STOP
LET vm_num_det = 1
FOREACH q_c03 INTO rm_c03.*
	LET rm_retsri[vm_num_det].c03_codigo_sri     = rm_c03.c03_codigo_sri
	LET rm_retsri[vm_num_det].c03_concepto_ret   = rm_c03.c03_concepto_ret
	LET rm_retsri[vm_num_det].c03_fecha_ini_porc = rm_c03.c03_fecha_ini_porc
	LET rm_retsri[vm_num_det].c03_fecha_fin_porc = rm_c03.c03_fecha_fin_porc
	LET rm_retsri[vm_num_det].c03_ingresa_proc   = rm_c03.c03_ingresa_proc
	LET rm_retsri[vm_num_det].c03_estado         = rm_c03.c03_estado
	LET rm_audi[vm_num_det].c03_usuario_modifi   = rm_c03.c03_usuario_modifi
	LET rm_audi[vm_num_det].c03_fecha_modifi     = rm_c03.c03_fecha_modifi
	LET rm_audi[vm_num_det].c03_usuario_elimin   = rm_c03.c03_usuario_elimin
	LET rm_audi[vm_num_det].c03_fecha_elimin     = rm_c03.c03_fecha_elimin
	LET vm_num_det = vm_num_det + 1
	IF vm_num_det > vm_max_det THEN
		CALL fl_mensaje_arreglo_incompleto()
		EXIT PROGRAM
	END IF
END FOREACH
LET vm_num_det = vm_num_det - 1
IF vm_num_det = 0 THEN
	LET vm_num_det = 1
END IF
DISPLAY BY NAME rm_c03.c03_tipo_ret, rm_c02.c02_nombre, rm_c03.c03_porcentaje
CALL set_count(vm_num_det)
LET int_flag = 0
INPUT ARRAY rm_retsri WITHOUT DEFAULTS FROM rm_retsri.*
	ON KEY(INTERRUPT)
		LET int_flag = 0
		CALL fl_mensaje_abandonar_proceso() RETURNING resp
		IF resp = 'Yes' THEN
			LET int_flag = 1
			EXIT INPUT
		END IF
	ON KEY(F1,CONTROL-W)
		CALL control_visor_teclas_caracter_1() 
	ON KEY(F5)
		LET i = arr_curr()
		LET j = scr_line()
		IF NOT insertar AND rm_retsri[i].c03_estado = 'A' THEN
			LET rm_retsri[i].c03_estado = 'E'
			DISPLAY rm_retsri[i].c03_estado TO
				rm_retsri[j].c03_estado
			LET rm_audi[i].c03_usuario_elimin = vg_usuario
			LET rm_audi[i].c03_fecha_elimin   = CURRENT
			DISPLAY BY NAME rm_audi[i].*
		END IF
	BEFORE INPUT
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
		--#CALL dialog.keysetlabel("INSERT","")
		--#CALL dialog.keysetlabel("DELETE","")
	BEFORE ROW
		LET i          = arr_curr()
		LET j          = scr_line()
		LET vm_num_det = arr_count()
		IF i > vm_num_det THEN
			LET vm_num_det = vm_num_det + 1
		END IF
		DISPLAY i          TO num_row
		DISPLAY vm_num_det TO max_row
		DISPLAY BY NAME rm_audi[i].*
		LET codigo = rm_retsri[i].c03_codigo_sri
		LET nombre = rm_retsri[i].c03_concepto_ret
		IF rm_retsri[i].c03_ingresa_proc IS NULL THEN
			LET rm_retsri[i].c03_ingresa_proc = 'N'
			DISPLAY rm_retsri[i].c03_ingresa_proc TO
				rm_retsri[j].c03_ingresa_proc
		END IF
		IF NOT insertar THEN
			--#CALL dialog.keysetlabel("F5","Eliminar")
		ELSE
			--#CALL dialog.keysetlabel("F5","")
		END IF
	AFTER FIELD c03_codigo_sri, c03_concepto_ret
		IF rm_retsri[i].c03_estado IS NULL THEN
			LET rm_retsri[i].c03_estado = 'A'
			DISPLAY rm_retsri[i].c03_estado TO
				rm_retsri[j].c03_estado
		END IF
		IF NOT insertar AND nombre <> rm_retsri[i].c03_concepto_ret
		THEN
			LET rm_audi[i].c03_usuario_modifi = vg_usuario
			LET rm_audi[i].c03_fecha_modifi   = CURRENT
			DISPLAY BY NAME rm_audi[i].*
		END IF
		IF NOT insertar AND codigo <> rm_retsri[i].c03_codigo_sri THEN
			LET rm_retsri[i].c03_codigo_sri = codigo
			DISPLAY rm_retsri[i].c03_codigo_sri TO
				rm_retsri[j].c03_codigo_sri
		END IF
	AFTER INSERT
		LET insertar = 0
	AFTER INPUT
		LET vm_num_det = arr_count()
		IF rm_retsri[vm_num_det].c03_fecha_ini_porc IS NULL THEN
			NEXT FIELD c03_fecha_ini_porc
		END IF
		FOR i = 1 TO vm_num_det
			IF rm_retsri[i].c03_codigo_sri IS NULL THEN
				CALL fl_mostrar_mensaje('Digite el código del SRI.', 'exclamation')
				CONTINUE INPUT
			END IF
			IF rm_retsri[i].c03_concepto_ret IS NULL THEN
				CALL fl_mostrar_mensaje('Digite la descripción para el código del SRI.', 'exclamation')
				CONTINUE INPUT
			END IF
		END FOR
		FOR k = 1 TO vm_num_det - 1
			FOR l = k + 1 TO vm_num_det
				IF rm_retsri[k].c03_codigo_sri =
				   rm_retsri[l].c03_codigo_sri 
				THEN
					LET mensaje = 'El código esta repetido en la fila ', l USING "<<<<&", '. Favor de corregirlo.'
					CALL fl_mostrar_mensaje(mensaje, 'exclamation')
					CONTINUE INPUT
				END IF
				IF rm_retsri[k].c03_concepto_ret =
				   rm_retsri[l].c03_concepto_ret 
				THEN
					LET mensaje = 'La descripción esta repetida en la fila ', l USING "<<<<&", '. Favor de corregirla.'
					CALL fl_mostrar_mensaje(mensaje, 'exclamation')
					CONTINUE INPUT
				END IF
			END FOR
		END FOR
END INPUT
IF int_flag THEN
	ROLLBACK WORK
	CLOSE WINDOW w_ordf102_2
	LET int_flag = 0
	RETURN
END IF
FOR i = 1 TO vm_num_det
	LET insertar = 1
	INITIALIZE r_c03.* TO NULL
	WHENEVER ERROR CONTINUE
	DECLARE q_c03_2 CURSOR FOR
		SELECT * FROM ordt003
			WHERE c03_compania   = rm_c03.c03_compania
			  AND c03_tipo_ret   = rm_c03.c03_tipo_ret
			  AND c03_porcentaje = rm_c03.c03_porcentaje
			  AND c03_codigo_sri = rm_retsri[i].c03_codigo_sri
		FOR UPDATE
	OPEN q_c03_2
	FETCH q_c03_2 INTO r_c03.*
	IF STATUS < 0 THEN
		ROLLBACK WORK
		CALL fl_mostrar_mensaje('El código ' || rm_retsri[i].c03_codigo_sri CLIPPED || ' esta siendo modificado por otro usuario.', 'stop')
		WHENEVER ERROR STOP
		LET int_flag = 1
		EXIT FOR
	END IF
	IF STATUS <> NOTFOUND THEN
		LET insertar = 0
	END IF
	WHENEVER ERROR STOP
	IF insertar THEN
		INSERT INTO ordt003
			VALUES(rm_c03.c03_compania, rm_c03.c03_tipo_ret,
				rm_c03.c03_porcentaje,
				rm_retsri[i].c03_codigo_sri,
				rm_retsri[i].c03_estado,
				rm_retsri[i].c03_concepto_ret,
				rm_retsri[i].c03_fecha_ini_porc,
				rm_retsri[i].c03_fecha_fin_porc,
				rm_retsri[i].c03_ingresa_proc, NULL, NULL, NULL,
				NULL, rm_c03.c03_usuario, rm_c03.c03_fecing)
		CLOSE q_c03_2
		CONTINUE FOR
	END IF
	UPDATE ordt003
		SET c03_estado         = rm_retsri[i].c03_estado,
		    c03_concepto_ret   = rm_retsri[i].c03_concepto_ret,
		    c03_fecha_ini_porc = rm_retsri[i].c03_fecha_ini_porc,
		    c03_fecha_fin_porc = rm_retsri[i].c03_fecha_fin_porc,
		    c03_ingresa_proc   = rm_retsri[i].c03_ingresa_proc
		WHERE CURRENT OF q_c03_2
	IF rm_audi[i].c03_usuario_modifi IS NOT NULL THEN
		UPDATE ordt003
			SET c03_usuario_modifi = rm_audi[i].c03_usuario_modifi,
			    c03_fecha_modifi   = rm_audi[i].c03_fecha_modifi
			WHERE CURRENT OF q_c03_2
	END IF
	IF rm_audi[i].c03_usuario_elimin IS NOT NULL THEN
		UPDATE ordt003
			SET c03_usuario_elimin = rm_audi[i].c03_usuario_elimin,
			    c03_fecha_elimin   = rm_audi[i].c03_fecha_elimin
			WHERE CURRENT OF q_c03_2
	END IF
	IF STATUS < 0 THEN
		ROLLBACK WORK
		CALL fl_mostrar_mensaje('El código ' || rm_retsri[i].c03_codigo_sri CLIPPED || ' no se pudo actualizar. Por favor llame al ADMINISTRADOR.', 'stop')
		WHENEVER ERROR STOP
		LET int_flag = 1
		EXIT FOR
	END IF
END FOR
IF NOT int_flag THEN
	COMMIT WORK
	CALL fl_mostrar_mensaje('Procesados Códigos del SRI.', 'info')
END IF
LET int_flag = 0
CLOSE WINDOW w_ordf102_2
RETURN

END FUNCTION



FUNCTION muestra_contadores_det(num_row, max_row)
DEFINE num_row, max_row	SMALLINT

DISPLAY BY NAME num_row, max_row

END FUNCTION



FUNCTION control_tipos_pago()
DEFINE row_ini, col_ini	SMALLINT
DEFINE row_fin, col_fin	SMALLINT

LET row_ini = 08
LET row_fin = 13
LET col_ini = 04
LET col_fin = 74
IF vg_gui = 0 THEN
	LET row_ini = 07
	LET row_fin = 14
	LET col_ini = 04
	LET col_fin = 74
END IF
OPEN WINDOW w_ordf102_3 AT row_ini, col_ini WITH row_fin ROWS, col_fin COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE 0, BORDER,
			MESSAGE LINE LAST) 
IF vg_gui = 1 THEN
	OPEN FORM f_ordf102_3 FROM '../forms/ordf102_3'
ELSE
	OPEN FORM f_ordf102_3 FROM '../forms/ordf102_3c'
END IF
DISPLAY FORM f_ordf102_3
LET vm_num_ret = 0
CALL borrar_tipos_pago()
--#DISPLAY 'Tipo'	   TO tit_col1
--#DISPLAY 'Forma Pago'	   TO tit_col2
--#DISPLAY 'Tipo Pago' 	   TO tit_col3
--#DISPLAY 'Cuenta'	   TO tit_col4
--#DISPLAY 'Nombre Cuenta' TO tit_col5
DISPLAY BY NAME rm_c02.c02_porcentaje, rm_c02.c02_tipo_ret, rm_c02.c02_nombre
BEGIN WORK
	CALL ingreso_tipos_pago()
	IF NOT int_flag THEN
		CALL grabar_tipos_pago()
	END IF
IF int_flag THEN
	ROLLBACK WORK
ELSE
	COMMIT WORK
	CALL fl_mostrar_mensaje('Procesados Tipos de Pago para Clientes.', 'info')
END IF
LET int_flag = 0
CLOSE WINDOW w_ordf102_3
RETURN

END FUNCTION



FUNCTION ingreso_tipos_pago()

CALL cargar_tipos_pago()
CALL muestra_detalle_tipos_pago()
CALL lee_tipos_pago()
IF int_flag THEN
	LET vm_num_ret = 0
END IF

END FUNCTION



FUNCTION consulta_tipos_pago()
DEFINE i, j		SMALLINT

CALL cargar_tipos_pago()
IF vm_num_ret = 0 THEN
	CALL fl_mensaje_consulta_sin_registros()
	RETURN
END IF
CALL muestra_contadores_det(1, vm_num_ret)
CALL set_count(vm_num_ret)
DISPLAY ARRAY rm_detj91 TO rm_detj91.*
	ON KEY(INTERRUPT)
		EXIT DISPLAY
	--#BEFORE DISPLAY
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
                --#CALL dialog.keysetlabel('ACCEPT', '')
		--#CALL dialog.keysetlabel('RETURN','')
	--#BEFORE ROW
		--#LET i = arr_curr()
		--#LET j = scr_line()
		--#CALL muestra_contadores_det(i, vm_num_ret)
        --#AFTER DISPLAY
                --#CONTINUE DISPLAY
END DISPLAY

END FUNCTION



FUNCTION borrar_tipos_pago()
DEFINE i		SMALLINT

FOR i = 1 TO fgl_scr_size('rm_detj91')
	CLEAR rm_detj91[i].*
END FOR
FOR i = 1 TO vm_max_ret
	INITIALIZE rm_detj91[i].* TO NULL
END FOR
CLEAR num_row, max_row, c02_porcentaje, c02_tipo_ret, c02_nombre

END FUNCTION



FUNCTION cargar_tipos_pago()
DEFINE query		CHAR(1000)
DEFINE r_j91		RECORD LIKE cajt091.*

LET query = 'SELECT j91_tipo_ret, j91_porcentaje, j91_codigo_pago, j01_nombre,',
			' j91_cont_cred,',
			' CASE WHEN j91_cont_cred = "C"',
				' THEN "CONTADO" ',
				' ELSE "CREDITO" ',
			' END tit_cont_cred, j91_aux_cont, b10_descripcion',
		' FROM cajt091, cajt001, OUTER ctbt010',
		' WHERE j91_compania    = ', vg_codcia,
		'   AND j91_tipo_ret    = "', rm_c02.c02_tipo_ret, '"',
		'   AND j91_porcentaje  = ', rm_c02.c02_porcentaje,
		'   AND j01_compania    = j91_compania ',
		'   AND j01_codigo_pago = j91_codigo_pago ',
		'   AND j01_cont_cred   = j91_cont_cred ',
		'   AND b10_compania    = j91_compania ',
		'   AND b10_cuenta      = j91_aux_cont ',
		' ORDER BY j91_cont_cred, j91_codigo_pago '
PREPARE cons_ret4 FROM query
DECLARE q_ret4 CURSOR FOR cons_ret4
LET vm_num_ret = 1
FOREACH q_ret4 INTO r_j91.j91_tipo_ret, r_j91.j91_porcentaje,
			rm_detj91[vm_num_ret].*
	LET vm_num_ret = vm_num_ret + 1
	IF vm_num_ret > vm_max_ret THEN
		EXIT FOREACH
	END IF
END FOREACH
LET vm_num_ret = vm_num_ret - 1

END FUNCTION



FUNCTION muestra_detalle_tipos_pago()
DEFINE i, lim		INTEGER

LET lim = vm_num_ret
IF lim > fgl_scr_size('rm_detj91') THEN
	LET lim = fgl_scr_size('rm_detj91')
END IF
FOR i = 1 TO lim
	DISPLAY rm_detj91[i].* TO rm_detj91[i].*
END FOR

END FUNCTION



FUNCTION lee_tipos_pago()
DEFINE salir		SMALLINT

LET salir = 0
WHILE NOT salir
	CALL lee_detalle_det_ret() RETURNING salir
	IF int_flag THEN
		EXIT WHILE
	END IF
END WHILE

END FUNCTION



FUNCTION lee_detalle_det_ret()
DEFINE r_j01		RECORD LIKE cajt001.*
DEFINE r_b10		RECORD LIKE ctbt010.*
DEFINE cont_cred	LIKE cajt001.j01_cont_cred
DEFINE resp		CHAR(6)
DEFINE i, j, l, k	SMALLINT
DEFINE salir, max_row	SMALLINT

IF vm_num_ret <= 0 THEN
	LET vm_num_ret = 1
END IF
LET salir    = 0
LET int_flag = 0
CALL set_count(vm_num_ret)
INPUT ARRAY rm_detj91 WITHOUT DEFAULTS FROM rm_detj91.*
	ON KEY(INTERRUPT)
		LET int_flag = 0
		CALL fl_mensaje_abandonar_proceso() RETURNING resp
		IF resp = 'Yes' THEN
			LET int_flag = 1
			EXIT INPUT
		END IF
	ON KEY(F2)
		IF INFIELD(j91_codigo_pago) THEN
			CALL fl_ayuda_forma_pago(vg_codcia, 'T', 'A') 
				RETURNING r_j01.j01_codigo_pago,
					  r_j01.j01_nombre,
					  r_j01.j01_cont_cred
			IF r_j01.j01_codigo_pago IS NOT NULL THEN
				LET rm_detj91[i].j91_codigo_pago =
							r_j01.j01_codigo_pago
				LET rm_detj91[i].j91_cont_cred =
							r_j01.j01_cont_cred
				LET rm_detj91[i].j01_nombre = r_j01.j01_nombre
				CALL ret_cont_cred(rm_detj91[i].j91_cont_cred)
					RETURNING rm_detj91[i].tit_cont_cred
				DISPLAY rm_detj91[i].* TO rm_detj91[j].*
			END IF
		END IF
		IF INFIELD(j91_aux_cont) THEN
			CALL fl_ayuda_cuenta_contable(vg_codcia, -1)
				RETURNING r_b10.b10_cuenta,r_b10.b10_descripcion
			IF r_b10.b10_cuenta IS NOT NULL THEN
				LET rm_detj91[i].j91_aux_cont = r_b10.b10_cuenta
				LET rm_detj91[i].b10_descripcion =
							r_b10.b10_descripcion
				DISPLAY rm_detj91[i].* TO rm_detj91[j].*
			END IF
		END IF
		LET int_flag = 0
	BEFORE INPUT
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
	BEFORE ROW
		LET i = arr_curr()
		LET j = scr_line()
		LET max_row = arr_count()
		IF i > max_row THEN
			LET max_row = max_row + 1
		END IF
		CALL muestra_contadores_det(i, max_row)
	BEFORE FIELD j91_cont_cred
		LET cont_cred = rm_detj91[i].j91_cont_cred
	AFTER FIELD j91_codigo_pago
		IF rm_detj91[i].j91_cont_cred IS NULL THEN
			CONTINUE INPUT
		END IF
		IF rm_detj91[i].j91_codigo_pago IS NOT NULL THEN
			CALL fl_lee_tipo_pago_caja(vg_codcia,
						rm_detj91[i].j91_codigo_pago,
						rm_detj91[i].j91_cont_cred)
				RETURNING r_j01.*
			IF r_j01.j01_codigo_pago IS NULL THEN
				CALL fl_mostrar_mensaje('Codigo de pago no existe.', 'exclamation')
				NEXT FIELD j91_codigo_pago
			END IF
			IF r_j01.j01_estado <> 'A' THEN
				CALL fl_mensaje_estado_bloqueado()
				NEXT FIELD j91_codigo_pago
			END IF
			LET rm_detj91[i].j01_nombre = r_j01.j01_nombre
			CALL ret_cont_cred(rm_detj91[i].j91_cont_cred)
				RETURNING rm_detj91[i].tit_cont_cred
		ELSE
			LET rm_detj91[i].j01_nombre    = NULL
			LET rm_detj91[i].tit_cont_cred = NULL
		END IF
		DISPLAY rm_detj91[i].* TO rm_detj91[j].*
	AFTER FIELD j91_cont_cred
		IF rm_detj91[i].j91_codigo_pago IS NULL THEN
			CONTINUE INPUT
		END IF
		IF rm_detj91[i].j91_cont_cred IS NULL THEN
			LET rm_detj91[i].j91_cont_cred = cont_cred
		END IF
		CALL fl_lee_tipo_pago_caja(vg_codcia,
						rm_detj91[i].j91_codigo_pago,
						rm_detj91[i].j91_cont_cred)
			RETURNING r_j01.*
		LET rm_detj91[i].j01_nombre = r_j01.j01_nombre
		CALL ret_cont_cred(rm_detj91[i].j91_cont_cred)
			RETURNING rm_detj91[i].tit_cont_cred
		DISPLAY rm_detj91[i].* TO rm_detj91[j].*
	AFTER FIELD j91_aux_cont
                IF rm_detj91[i].j91_aux_cont IS NOT NULL THEN
			IF validar_cuenta(rm_detj91[i].j91_aux_cont) = 1 THEN
				NEXT FIELD j91_aux_cont
			END IF
			CALL fl_lee_cuenta(vg_codcia, rm_detj91[i].j91_aux_cont)
				RETURNING r_b10.*
			LET rm_detj91[i].b10_descripcion = r_b10.b10_descripcion
		ELSE
			LET rm_detj91[i].b10_descripcion = NULL
                END IF
		DISPLAY rm_detj91[i].b10_descripcion TO
			rm_detj91[j].b10_descripcion
	AFTER DELETE
		LET max_row = max_row - 1
		IF max_row <= 0 THEN
			LET max_row = 1
		END IF
	AFTER INPUT
		LET vm_num_ret = arr_count()
		FOR l = 1 TO vm_num_ret - 1
			FOR k = l + 1 TO vm_num_ret
				IF (rm_detj91[l].j91_codigo_pago =
				    rm_detj91[k].j91_codigo_pago) AND
				   (rm_detj91[l].j91_cont_cred =
				    rm_detj91[k].j91_cont_cred)
				THEN
					CALL fl_mostrar_mensaje('Existen un mismo tipo de porcentaje y tipo de pago mas de una vez en el detalle.', 'exclamation')
					CONTINUE INPUT
				END IF
			END FOR
		END FOR
		FOR l = 1 TO vm_num_ret
			CALL fl_lee_tipo_pago_caja(vg_codcia,
						rm_detj91[l].j91_codigo_pago,
						rm_detj91[l].j91_cont_cred)
				RETURNING r_j01.*
			IF r_j01.j01_retencion = 'N' THEN
				CALL fl_mostrar_mensaje('Existe un codigo de pago que no es del tipo retencion.', 'exclamation')
				CONTINUE INPUT
			END IF
		END FOR
		LET salir = 1
END INPUT
RETURN salir

END FUNCTION



FUNCTION grabar_tipos_pago()
DEFINE i		SMALLINT

WHENEVER ERROR CONTINUE
DELETE FROM cajt091
	WHERE j91_compania   = vg_codcia
	  AND j91_tipo_ret   = rm_c02.c02_tipo_ret
	  AND j91_porcentaje = rm_c02.c02_porcentaje
IF STATUS <> 0 THEN
	CALL fl_mostrar_mensaje('Ha ocurrido un error al momento de grabar los tipos de pago. LLAME AL ADMINISTRADOR.', 'exclamation')
	WHENEVER ERROR STOP
	LET int_flag = 1
	RETURN
END IF
WHENEVER ERROR STOP
FOR i = 1 TO vm_num_ret
	INSERT INTO cajt091
		VALUES(vg_codcia, rm_detj91[i].j91_codigo_pago,
			rm_detj91[i].j91_cont_cred, rm_c02.c02_tipo_ret,
			rm_c02.c02_porcentaje, rm_detj91[i].j91_aux_cont,
			vg_usuario, CURRENT)
END FOR
 
END FUNCTION



FUNCTION ret_cont_cred(cont_cred)
DEFINE cont_cred	LIKE cajt001.j01_cont_cred
DEFINE tit_cont_cred	VARCHAR(10)

LET tit_cont_cred = NULL
CASE cont_cred
	WHEN 'C' LET tit_cont_cred = 'CONTADO'
	WHEN 'R' LET tit_cont_cred = 'CREDITO'
END CASE
RETURN tit_cont_cred

END FUNCTION



FUNCTION validar_cuenta(aux_cont)
DEFINE aux_cont		LIKE ctbt010.b10_cuenta
DEFINE r_b10            RECORD LIKE ctbt010.*

CALL fl_lee_cuenta(vg_codcia, aux_cont) RETURNING r_b10.*
IF r_b10.b10_cuenta IS NULL  THEN
	CALL fl_mostrar_mensaje('Cuenta no existe para esta compañía.','exclamation')
	RETURN 1
END IF
IF r_b10.b10_estado = 'B' THEN
	CALL fl_mensaje_estado_bloqueado()
	RETURN 1
END IF
IF r_b10.b10_permite_mov = 'N' THEN
	CALL fl_mostrar_mensaje('Cuenta no permite movimiento.', 'exclamation')
	RETURN 1
END IF
RETURN 0

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



FUNCTION control_visor_teclas_caracter_1() 
DEFINE a, fila		INTEGER

CALL fl_visor_teclas_caracter() RETURNING fila
LET a = fila + 2
DISPLAY 'Teclas exclusivas de este proceso:' AT a,2 ATTRIBUTE(REVERSE)	
LET a = a + 1
DISPLAY '<F5>      Eliminar Código'          AT a,2
DISPLAY  'F5' AT a,3 ATTRIBUTE(REVERSE)
LET a = fgl_getkey()
CLOSE WINDOW w_tf

END FUNCTION
