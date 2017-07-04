------------------------------------------------------------------------------
-- Titulo           : cxcp101.4gl - Mantenimiento de Clientes 
-- Elaboracion      : 04-oct-2001
-- Autor            : NPC
-- Formato Ejecucion: fglrun cxcp101 base módulo compañía [localidad] [cliente]
-- Ultima Correccion: 
-- Motivo Correccion: 
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_demonios	VARCHAR(12)
DEFINE vm_nuevoprog	VARCHAR(400)
DEFINE vm_nivel		LIKE ctbt001.b01_nivel
DEFINE rm_z01		RECORD LIKE cxct001.*
DEFINE rm_z02		RECORD LIKE cxct002.*
DEFINE vm_num_rows	SMALLINT
DEFINE vm_row_current	SMALLINT
DEFINE vm_max_rows	SMALLINT
DEFINE vm_r_rows	ARRAY [1000] OF INTEGER
DEFINE vm_r_cli		ARRAY [1000] OF RECORD
				codloc		LIKE cxct002.z02_localidad,
				codcli		LIKE cxct002.z02_codcli
			END RECORD
DEFINE vm_flag_mant	CHAR(1)



MAIN

DEFER QUIT 
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/errores')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 AND num_args() <> 5 THEN   -- Validar # parámetros correcto
	CALL fgl_winmessage(vg_producto, 'Número de parámetros incorrecto', 'stop')
	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
IF arg_val(4) <> '0' THEN
	LET vg_codloc  = arg_val(4)
END IF
LET vg_proceso = 'cxcp101'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
--#CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL control_master()

END MAIN



FUNCTION control_master()
DEFINE flag		CHAR(1)

CALL fl_nivel_isolation()
LET vm_max_rows	= 1000
OPEN WINDOW wf AT 3,2 WITH 21 ROWS, 80 COLUMNS
    ATTRIBUTE(FORM LINE FIRST + 2, COMMENT LINE LAST, MENU LINE FIRST,BORDER,
	      MESSAGE LINE LAST - 2)
OPTIONS INPUT WRAP,
	ACCEPT KEY	F12
OPEN FORM f_cxc FROM "../forms/cxcf101_1"
DISPLAY FORM f_cxc
INITIALIZE rm_z01.*, rm_z02.* TO NULL
SELECT MAX(b01_nivel) INTO vm_nivel FROM ctbt001
IF vm_nivel IS NULL THEN
	CALL fl_mostrar_mensaje('No existe ningun nivel de cuenta configurado en la compania.','stop')
	EXIT PROGRAM
END IF
LET vm_num_rows    = 0
LET vm_row_current = 0
CALL muestra_contadores(vm_row_current, vm_num_rows)
MENU 'OPCIONES'
	BEFORE MENU
		HIDE OPTION 'Avanzar'
		HIDE OPTION 'Retroceder'
		HIDE OPTION 'Modificar'
		HIDE OPTION 'Bloquear/Activar'
		HIDE OPTION 'Area de Negocio'
		HIDE OPTION 'Localidad'
		IF num_args() = 5 THEN
			HIDE OPTION 'Ingresar'
			HIDE OPTION 'Consultar'
			CALL control_consulta()
			IF vm_num_rows = 0 THEN
				EXIT PROGRAM
			END IF
			IF vm_num_rows <= 1 THEN
				HIDE OPTION 'Avanzar'
				HIDE OPTION 'Retroceder'
			ELSE
				SHOW OPTION 'Avanzar'
			END IF
			IF vm_row_current <= 1 THEN
        	                HIDE OPTION 'Retroceder'
	                END IF
			SHOW OPTION 'Area de Negocio'
		END IF
	COMMAND KEY('I') 'Ingresar' 'Ingresar nuevos registros. '
		CALL control_ingreso()
		IF vm_num_rows = 1 THEN
			SHOW OPTION 'Modificar'
			SHOW OPTION 'Bloquear/Activar'
			SHOW OPTION 'Area de Negocio'
			SHOW OPTION 'Localidad'
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
			SHOW OPTION 'Area de Negocio'
			SHOW OPTION 'Localidad'
			HIDE OPTION 'Avanzar'
			HIDE OPTION 'Retroceder'
			IF vm_num_rows = 0 THEN
				HIDE OPTION 'Modificar'
				HIDE OPTION 'Bloquear/Activar'
				HIDE OPTION 'Area de Negocio'
				HIDE OPTION 'Localidad'
			END IF
		ELSE
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Modificar'
			SHOW OPTION 'Bloquear/Activar'
			SHOW OPTION 'Area de Negocio'
			SHOW OPTION 'Localidad'
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
     	COMMAND KEY('N') 'Area de Negocio' 'Areas negocio de una Cia./Local. '
		LET flag = 'X'
		IF num_args() = 5 THEN
			LET flag = 'O'
		END IF
		CALL ver_areaneg(flag)
     	COMMAND KEY('L') 'Localidad' 'Activar Cliente para otra Localidad. '
		CALL control_localidad()
	COMMAND KEY('S') 'Salir' 'Salir del programa. '
		EXIT MENU
END MENU

END FUNCTION



FUNCTION datos_defaults_z02()
DEFINE r_z00		RECORD LIKE cxct000.*
DEFINE r_b10		RECORD LIKE ctbt010.*

CALL fl_lee_compania_cobranzas(vg_codcia) RETURNING r_z00.*
IF r_z00.z00_estado = 'A' THEN
	LET rm_z02.z02_aux_clte_mb = r_z00.z00_aux_clte_mb
	CALL fl_lee_cuenta(vg_codcia,r_z00.z00_aux_clte_mb) RETURNING r_b10.*
	DISPLAY r_b10.b10_descripcion TO tit_cli_mb
	LET rm_z02.z02_aux_clte_ma = r_z00.z00_aux_clte_ma
	CALL fl_lee_cuenta(vg_codcia,r_z00.z00_aux_clte_ma) RETURNING r_b10.*
	DISPLAY r_b10.b10_descripcion TO tit_cli_ma
	LET rm_z02.z02_aux_ant_mb  = r_z00.z00_aux_ant_mb
	CALL fl_lee_cuenta(vg_codcia,r_z00.z00_aux_ant_mb) RETURNING r_b10.*
	DISPLAY r_b10.b10_descripcion TO tit_ant_mb
	LET rm_z02.z02_aux_ant_ma  = r_z00.z00_aux_ant_ma
	CALL fl_lee_cuenta(vg_codcia,r_z00.z00_aux_ant_ma) RETURNING r_b10.*
	DISPLAY r_b10.b10_descripcion TO tit_ant_ma
END IF
LET rm_z02.z02_compania     = vg_codcia
LET rm_z02.z02_localidad    = vg_codloc
--LET rm_z02.z02_credit_auto = r_z00.z00_credit_auto
LET rm_z02.z02_credit_auto  = 'N'
LET rm_z02.z02_cheques      = 'S'
--LET rm_z02.z02_credit_dias = r_z00.z00_credit_dias
LET rm_z02.z02_credit_dias  = 0
LET rm_z02.z02_cupocred_mb  = 0
LET rm_z02.z02_cupocred_ma  = 0
LET rm_z02.z02_dcto_item_c  = 0
LET rm_z02.z02_dcto_item_r  = 0
LET rm_z02.z02_dcto_mano_c  = 0
LET rm_z02.z02_dcto_mano_r  = 0
LET rm_z02.z02_usuario      = vg_usuario
LET rm_z02.z02_fecing       = CURRENT

END FUNCTION



FUNCTION control_ingreso()
DEFINE num_aux		INTEGER
DEFINE resul		SMALLINT

CLEAR FORM
CALL fl_retorna_usuario()
LET num_aux = 0 
INITIALIZE rm_z01.*, rm_z02.* TO NULL
CALL datos_defaults_z02()
LET rm_z01.z01_personeria  = 'N'
LET rm_z01.z01_tipo_doc_id = 'C'
LET rm_z01.z01_paga_impto  = 'S'
LET rm_z01.z01_estado      = 'A'
LET rm_z01.z01_usuario     = vg_usuario
LET rm_z01.z01_fecing      = CURRENT
CALL muestra_estado()
LET vm_flag_mant = 'I'
CALL leer_datos()
IF NOT int_flag THEN
	IF rm_z01.z01_codcli IS NULL THEN
		CALL retorna_codcli() RETURNING resul
		IF resul = 0 THEN
			LET rm_z01.z01_codcli = NULL
			CALL leer_datos()
			IF int_flag THEN
				CLEAR FORM
				CALL muestra_contadores(vm_row_current,
							vm_num_rows)
				IF vm_row_current > 0 THEN
					CALL mostrar_registro(
						vm_r_rows[vm_row_current],
						vm_r_cli[vm_row_current].*)
				ELSE
					CALL muestra_estado()
					CLEAR tit_est, tit_estado_cli
				END IF
				RETURN
			END IF
			IF rm_z01.z01_codcli IS NULL THEN
				CALL retorna_codcli() RETURNING resul
				IF resul = 0 THEN
					CLEAR FORM
					CALL muestra_contadores(vm_row_current,
								vm_num_rows)
					IF vm_row_current > 0 THEN
						CALL mostrar_registro(
						      vm_r_rows[vm_row_current],
						     vm_r_cli[vm_row_current].*)
					ELSE
						CALL muestra_estado()
						CLEAR tit_est, tit_estado_cli
					END IF
					RETURN
				END IF
			END IF
		END IF
	END IF
	LET rm_z02.z02_codcli = rm_z01.z01_codcli
	LET rm_z01.z01_fecing = CURRENT
	LET rm_z02.z02_fecing = rm_z01.z01_fecing
	BEGIN WORK
		INSERT INTO cxct001 VALUES (rm_z01.*)
		LET num_aux = SQLCA.SQLERRD[6] 
		INSERT INTO cxct002 VALUES (rm_z02.*)
	COMMIT WORK
	IF vm_num_rows = vm_max_rows THEN
		LET vm_num_rows = 1
	ELSE
		LET vm_num_rows = vm_num_rows + 1
	END IF
	LET vm_row_current                  = vm_num_rows
	LET vm_r_rows[vm_row_current]       = num_aux
	LET vm_r_cli[vm_row_current].codloc = rm_z02.z02_localidad
	LET vm_r_cli[vm_row_current].codcli = rm_z02.z02_codcli
	DISPLAY rm_z01.z01_codcli TO tit_codigo_cli
	DISPLAY rm_z01.z01_nomcli TO tit_nombre_cli
	DISPLAY BY NAME rm_z01.z01_codcli, rm_z01.z01_fecing
	CALL muestra_reg()
	CALL fl_mensaje_registro_ingresado()
ELSE
	CLEAR FORM
	IF vm_row_current > 0 THEN
		CALL muestra_reg()
	ELSE
		CALL muestra_estado()
		CLEAR tit_est, tit_estado_cli
	END IF
END IF

END FUNCTION



FUNCTION control_modificacion()
	
IF vm_num_rows = 0 THEN
	CALL fl_mensaje_consultar_primero()
	RETURN
END IF
CALL mostrar_registro(vm_r_rows[vm_row_current], vm_r_cli[vm_row_current].*)
IF rm_z01.z01_estado = 'B' THEN
	CALL fl_mensaje_estado_bloqueado()
	RETURN
END IF
BEGIN WORK
WHENEVER ERROR CONTINUE
DECLARE q_up CURSOR FOR
	SELECT * FROM cxct001
		WHERE ROWID = vm_r_rows[vm_row_current]
	FOR UPDATE
OPEN q_up
FETCH q_up INTO rm_z01.*
IF STATUS < 0 THEN
	ROLLBACK WORK
	CALL fl_mensaje_bloqueo_otro_usuario()
	WHENEVER ERROR STOP
	RETURN
END IF
DECLARE q_up2 CURSOR FOR
	SELECT * FROM cxct002
		WHERE z02_compania  = rm_z02.z02_compania 
		  AND z02_localidad = vm_r_cli[vm_row_current].codloc
		  AND z02_codcli    = vm_r_cli[vm_row_current].codcli
	FOR UPDATE
OPEN q_up2
FETCH q_up2 INTO rm_z02.*
IF STATUS < 0 THEN
	ROLLBACK WORK
	CALL fl_mensaje_bloqueo_otro_usuario()
	WHENEVER ERROR STOP
	RETURN
END IF
IF rm_z02.z02_codcli IS NULL THEN
	--LET rm_z02.z02_credit_auto = 'S'
	LET rm_z02.z02_credit_auto = 'N'
	LET rm_z02.z02_cheques     = 'S'
	LET rm_z02.z02_usuario     = rm_z01.z01_usuario
	LET rm_z02.z02_fecing      = CURRENT
END IF
WHENEVER ERROR STOP
LET vm_flag_mant = 'M'
CALL leer_datos()
IF NOT int_flag THEN
	UPDATE cxct001 SET z01_nomcli      = rm_z01.z01_nomcli, 
			   z01_personeria  = rm_z01.z01_personeria,
			   z01_num_doc_id  = rm_z01.z01_num_doc_id,
			   z01_tipo_doc_id = rm_z01.z01_tipo_doc_id,
			   z01_direccion1  = rm_z01.z01_direccion1, 
			   z01_telefono1   = rm_z01.z01_telefono1, 
			   z01_tipo_clte   = rm_z01.z01_tipo_clte,
			   z01_direccion2  = rm_z01.z01_direccion2, 
			   z01_telefono2   = rm_z01.z01_telefono2,
			   z01_fax1        = rm_z01.z01_fax1,
			   z01_fax2        = rm_z01.z01_fax2,
			   z01_casilla     = rm_z01.z01_casilla,
			   z01_pais        = rm_z01.z01_pais,
			   z01_ciudad      = rm_z01.z01_ciudad,
			   z01_rep_legal   = rm_z01.z01_rep_legal,
			   z01_paga_impto  = rm_z01.z01_paga_impto
			WHERE CURRENT OF q_up
	IF rm_z02.z02_codcli IS NOT NULL THEN
		UPDATE cxct002 SET z02_contacto    = rm_z02.z02_contacto,
				   z02_referencia  = rm_z02.z02_referencia,
				   z02_credit_auto = rm_z02.z02_credit_auto,
				   z02_credit_dias = rm_z02.z02_credit_dias,
				   z02_cupocred_mb = rm_z02.z02_cupocred_mb,
				   z02_dcto_item_c = rm_z02.z02_dcto_item_c,
				   z02_dcto_item_r = rm_z02.z02_dcto_item_r,
				   z02_dcto_mano_c = rm_z02.z02_dcto_mano_c,
				   z02_dcto_mano_r = rm_z02.z02_dcto_mano_r,
				   z02_cheques     = rm_z02.z02_cheques,
				   z02_zona_venta  = rm_z02.z02_zona_venta,
				   z02_zona_cobro  = rm_z02.z02_zona_cobro,
				   z02_aux_clte_mb = rm_z02.z02_aux_clte_mb,
				   z02_aux_clte_ma = rm_z02.z02_aux_clte_ma,
				   z02_aux_ant_mb  = rm_z02.z02_aux_ant_mb,
				   z02_aux_ant_ma  = rm_z02.z02_aux_ant_ma
			WHERE CURRENT OF q_up2
	ELSE
		LET rm_z02.z02_compania  = vg_codcia
		LET rm_z02.z02_localidad = vg_codloc
		LET rm_z02.z02_codcli    = rm_z01.z01_codcli
		LET rm_z02.z02_fecing    = CURRENT
		INSERT INTO cxct002 VALUES (rm_z02.*)
	END IF
	COMMIT WORK
	CALL muestra_contadores(vm_row_current, vm_num_rows)
	CALL muestra_estado()
	CALL fl_mensaje_registro_modificado()
ELSE
	ROLLBACK WORK
	CLEAR FORM
	CALL muestra_contadores(vm_row_current, vm_num_rows)
	IF vm_row_current > 0 THEN
		CALL mostrar_registro(vm_r_rows[vm_row_current],
					vm_r_cli[vm_row_current].*)
	END IF
END IF
 
END FUNCTION



FUNCTION control_consulta()
DEFINE r_g02		RECORD LIKE gent002.*
DEFINE codi_aux         LIKE cxct001.z01_codcli
DEFINE nomi_aux         LIKE cxct001.z01_nomcli
DEFINE codp_aux         LIKE gent030.g30_pais
DEFINE nomp_aux         LIKE gent030.g30_nombre
DEFINE codc_aux         LIKE gent031.g31_ciudad
DEFINE nomc_aux         LIKE gent031.g31_nombre
DEFINE codt1_aux        LIKE gent012.g12_tiporeg
DEFINE codt2_aux        LIKE gent012.g12_subtipo
DEFINE nomt1_aux        LIKE gent012.g12_nombre
DEFINE nomt2_aux        LIKE gent011.g11_nombre
DEFINE codzv_aux        LIKE gent032.g32_zona_venta
DEFINE nomzv_aux        LIKE gent032.g32_nombre
DEFINE codzc_aux        LIKE cxct006.z06_zona_cobro
DEFINE nomzc_aux        LIKE cxct006.z06_nombre
DEFINE cod_aux          LIKE ctbt010.b10_cuenta
DEFINE nom_aux          LIKE ctbt010.b10_descripcion
DEFINE query		VARCHAR(1500)
DEFINE expr_sql		VARCHAR(800)
DEFINE expr_loc		VARCHAR(100)
DEFINE num_reg		INTEGER
DEFINE codloc		LIKE cxct002.z02_localidad
DEFINE codcli		LIKE cxct002.z02_codcli

CLEAR FORM
INITIALIZE codi_aux, codp_aux, codc_aux, codt1_aux, codzv_aux, codzc_aux,
	cod_aux, expr_loc TO NULL
IF num_args() = 4 THEN
	LET int_flag = 0
	CONSTRUCT BY NAME expr_sql ON z01_codcli, z01_nomcli, z01_personeria,
	z01_num_doc_id, z01_tipo_doc_id, z01_direccion1, z01_telefono1,
	z01_tipo_clte, z01_direccion2, z01_telefono2, z01_fax1, z01_fax2,
	z01_casilla, z01_pais, z01_ciudad, z01_rep_legal, z01_paga_impto,
	z02_localidad, z02_contacto, z02_referencia, z02_credit_auto,
	z02_credit_dias, z02_cupocred_mb, z02_dcto_item_c, z02_dcto_item_r,
	z02_dcto_mano_c, z02_dcto_mano_r, z02_cheques, z02_zona_venta,
	z02_zona_cobro, z02_aux_clte_mb, z02_aux_clte_ma, z02_aux_ant_mb,
	z02_aux_ant_ma
	ON KEY(F2)
		IF INFIELD(z01_codcli) THEN
                        CALL fl_ayuda_cliente_general()
                                RETURNING codi_aux, nomi_aux
                        LET int_flag = 0
                        IF codi_aux IS NOT NULL THEN
                                DISPLAY codi_aux TO z01_codcli
                                DISPLAY nomi_aux TO z01_nomcli
                        END IF
                END IF
		IF INFIELD(z01_pais) THEN
                        CALL fl_ayuda_pais()
                                RETURNING codp_aux, nomp_aux
                        LET int_flag = 0
                        IF codp_aux IS NOT NULL THEN
                                DISPLAY codp_aux TO z01_pais
                                DISPLAY nomp_aux TO tit_pais
                        END IF
                END IF
		IF INFIELD(z01_ciudad) THEN
                        CALL fl_ayuda_ciudad(codp_aux)
                                RETURNING codc_aux, nomc_aux
                        LET int_flag = 0
                        IF codc_aux IS NOT NULL THEN
                                DISPLAY codc_aux TO z01_ciudad
                                DISPLAY nomc_aux TO tit_ciudad
                        END IF
                END IF
		IF INFIELD(z01_tipo_clte) THEN
                        CALL fl_ayuda_subtipo_entidad('CL')
                                RETURNING codt1_aux, codt2_aux,
 					  nomt1_aux, nomt2_aux
                        LET int_flag = 0
                        IF codt1_aux IS NOT NULL THEN
                                DISPLAY codt2_aux TO z01_tipo_clte
                                DISPLAY nomt1_aux TO tit_tipo_cli
                        END IF
                END IF
		IF INFIELD(z02_localidad) THEN
			CALL fl_ayuda_localidad(vg_codcia)
				RETURNING r_g02.g02_localidad, r_g02.g02_nombre
                        LET int_flag = 0
			IF r_g02.g02_localidad IS NOT NULL THEN
				DISPLAY r_g02.g02_localidad TO z02_localidad
				DISPLAY r_g02.g02_nombre    TO tit_localidad
			END IF
                END IF
		IF INFIELD(z02_zona_venta) THEN
                        CALL fl_ayuda_zona_venta(vg_codcia)
                                RETURNING codzv_aux, nomzv_aux
                        LET int_flag = 0
                        IF codzv_aux IS NOT NULL THEN
                                DISPLAY codzv_aux TO z02_zona_venta
                                DISPLAY nomzv_aux TO tit_zona_vta
                        END IF
                END IF
		IF INFIELD(z02_zona_cobro) THEN
                        CALL fl_ayuda_zona_cobro()
                                RETURNING codzc_aux, nomzc_aux
                        LET int_flag = 0
                        IF codzc_aux IS NOT NULL THEN
                                DISPLAY codzc_aux TO z02_zona_cobro
                                DISPLAY nomzc_aux TO tit_zona_cob
                        END IF
                END IF
		IF INFIELD(z02_aux_clte_mb) THEN
                        CALL fl_ayuda_cuenta_contable(vg_codcia, vm_nivel)
                                RETURNING cod_aux, nom_aux
                        LET int_flag = 0
                        IF cod_aux IS NOT NULL THEN
                                DISPLAY cod_aux TO z02_aux_clte_mb
                                DISPLAY nom_aux TO tit_cli_mb
                        END IF
                END IF
                IF INFIELD(z02_aux_clte_ma) THEN
                        CALL fl_ayuda_cuenta_contable(vg_codcia, vm_nivel)
                                RETURNING cod_aux, nom_aux
                        LET int_flag = 0
                        IF cod_aux IS NOT NULL THEN
                                DISPLAY cod_aux TO z02_aux_clte_ma
                                DISPLAY nom_aux TO tit_cli_ma
                        END IF
                END IF
		IF INFIELD(z02_aux_ant_mb) THEN
                        CALL fl_ayuda_cuenta_contable(vg_codcia, vm_nivel)
                                RETURNING cod_aux, nom_aux
                        LET int_flag = 0
                        IF cod_aux IS NOT NULL THEN
                                DISPLAY cod_aux TO z02_aux_ant_mb
                                DISPLAY nom_aux TO tit_ant_mb
                        END IF
                END IF
                IF INFIELD(z02_aux_ant_ma) THEN
                        CALL fl_ayuda_cuenta_contable(vg_codcia, vm_nivel)
                                RETURNING cod_aux, nom_aux
                        LET int_flag = 0
                        IF cod_aux IS NOT NULL THEN
                                DISPLAY cod_aux TO z02_aux_ant_ma
                                DISPLAY nom_aux TO tit_ant_ma
                        END IF
                END IF
	END CONSTRUCT
	IF int_flag THEN
		IF vm_row_current > 0 THEN
			CALL muestra_reg()
		ELSE
			CLEAR FORM
		END IF
		RETURN
	END IF
ELSE
	LET expr_sql = 'z01_codcli = ', arg_val(5)
	IF arg_val(4) <> '0' THEN
		LET expr_loc = '   AND z02_localidad = ', vg_codloc
	END IF
END IF
LET query = 'SELECT cxct001.*, cxct001.ROWID, z02_localidad, z02_codcli ',
		' FROM cxct001, cxct002 ',
		' WHERE ', expr_sql CLIPPED,
		'   AND z02_compania  = ', vg_codcia,
		           expr_loc CLIPPED,
		'   AND z02_codcli    = z01_codcli ', 
		' ORDER BY 1 ' CLIPPED
PREPARE cons FROM query	
DECLARE q_cons CURSOR FOR cons
LET vm_num_rows = 0
FOREACH q_cons INTO rm_z01.*, num_reg, codloc, codcli
	LET vm_num_rows = vm_num_rows + 1
        IF vm_num_rows > vm_max_rows THEN
		LET vm_num_rows = vm_num_rows - 1
                EXIT FOREACH
        END IF
	LET vm_r_rows[vm_num_rows]       = num_reg
	LET vm_r_cli[vm_num_rows].codloc = codloc
	LET vm_r_cli[vm_num_rows].codcli = codcli
END FOREACH
IF vm_num_rows = 0 THEN
	LET int_flag = 0
	CALL fl_mensaje_consulta_sin_registros()
	IF num_args() = 5 THEN
		EXIT PROGRAM
	END IF
	CLEAR FORM
	LET vm_row_current = 0
	CALL muestra_contadores(vm_row_current, vm_num_rows)
	RETURN
END IF
LET vm_row_current = 1
CALL muestra_reg()

END FUNCTION



FUNCTION leer_datos()
DEFINE resp		CHAR(6)
DEFINE resul		SMALLINT
DEFINE r_z01            RECORD LIKE cxct001.*
DEFINE r_g02            RECORD LIKE gent002.*
DEFINE r_pai            RECORD LIKE gent030.*
DEFINE r_ciu            RECORD LIKE gent031.*
DEFINE r_car            RECORD LIKE gent012.*
DEFINE r_zon_vta	RECORD LIKE gent032.*
DEFINE r_zon_cob	RECORD LIKE cxct006.*
DEFINE r_mon		RECORD LIKE gent014.*
DEFINE codi_aux		LIKE cxct001.z01_codcli
DEFINE nomi_aux		LIKE cxct001.z01_nomcli
DEFINE codp_aux         LIKE gent030.g30_pais
DEFINE nomp_aux         LIKE gent030.g30_nombre
DEFINE codc_aux         LIKE gent031.g31_ciudad
DEFINE nomc_aux         LIKE gent031.g31_nombre
DEFINE codt1_aux        LIKE gent012.g12_tiporeg
DEFINE codt2_aux        LIKE gent012.g12_subtipo
DEFINE nomt1_aux        LIKE gent012.g12_nombre
DEFINE nomt2_aux        LIKE gent011.g11_nombre
DEFINE codzv_aux        LIKE gent032.g32_zona_venta
DEFINE nomzv_aux        LIKE gent032.g32_nombre
DEFINE codzc_aux        LIKE cxct006.z06_zona_cobro
DEFINE nomzc_aux        LIKE cxct006.z06_nombre
DEFINE cod_aux          LIKE ctbt010.b10_cuenta
DEFINE nom_aux          LIKE ctbt010.b10_descripcion

INITIALIZE r_pai.*, r_ciu.*, r_car.*, r_zon_vta.*, r_zon_cob.*,
	r_mon.*, codp_aux, codc_aux, codt1_aux, codzv_aux, codzc_aux,
	cod_aux TO NULL
DISPLAY rm_z01.z01_codcli TO tit_codigo_cli
DISPLAY rm_z01.z01_nomcli TO tit_nombre_cli
DISPLAY BY NAME rm_z01.z01_usuario, rm_z01.z01_fecing, rm_z02.z02_localidad,
		rm_z02.z02_credit_dias, rm_z02.z02_cupocred_mb,
		rm_z02.z02_cupocred_ma, rm_z02.z02_dcto_item_c,
		rm_z02.z02_dcto_item_r, rm_z02.z02_dcto_mano_c,
		rm_z02.z02_dcto_mano_r, rm_z02.z02_aux_clte_mb,
		rm_z02.z02_aux_clte_ma, rm_z02.z02_aux_ant_mb,
		rm_z02.z02_aux_ant_ma
CALL fl_lee_localidad(vg_codcia, rm_z02.z02_localidad) RETURNING r_g02.*
DISPLAY r_g02.g02_nombre TO tit_localidad
LET int_flag = 0
INPUT BY NAME rm_z01.z01_codcli, rm_z01.z01_nomcli, rm_z01.z01_personeria,
	rm_z01.z01_num_doc_id, rm_z01.z01_tipo_doc_id, rm_z01.z01_direccion1,
	rm_z01.z01_telefono1, rm_z01.z01_tipo_clte, rm_z01.z01_direccion2,
	rm_z01.z01_telefono2, rm_z01.z01_fax1, rm_z01.z01_fax2,
	rm_z01.z01_casilla, rm_z01.z01_pais, rm_z01.z01_ciudad,
	rm_z01.z01_rep_legal, rm_z01.z01_paga_impto, rm_z02.z02_contacto,
	rm_z02.z02_referencia, rm_z02.z02_credit_auto,
	rm_z02.z02_credit_dias, rm_z02.z02_cupocred_mb,
	rm_z02.z02_dcto_item_c, rm_z02.z02_dcto_item_r,
	rm_z02.z02_dcto_mano_c, rm_z02.z02_dcto_mano_r, rm_z02.z02_cheques,
	rm_z02.z02_zona_venta, rm_z02.z02_zona_cobro, rm_z02.z02_aux_clte_mb,
	rm_z02.z02_aux_clte_ma, rm_z02.z02_aux_ant_mb, rm_z02.z02_aux_ant_ma
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
        	IF field_touched(rm_z01.z01_codcli, rm_z01.z01_nomcli,
			rm_z01.z01_personeria, rm_z01.z01_num_doc_id,
			rm_z01.z01_tipo_doc_id, rm_z01.z01_direccion1,
			rm_z01.z01_telefono1, rm_z01.z01_tipo_clte,
			rm_z01.z01_direccion2, rm_z01.z01_telefono2,
			rm_z01.z01_fax1, rm_z01.z01_fax2, rm_z01.z01_casilla,
			rm_z01.z01_pais, rm_z01.z01_ciudad,
			rm_z01.z01_rep_legal, rm_z01.z01_paga_impto,
			rm_z02.z02_contacto, rm_z02.z02_referencia,
			rm_z02.z02_credit_auto, rm_z02.z02_credit_dias,
			rm_z02.z02_cupocred_mb, rm_z02.z02_dcto_item_c,
			rm_z02.z02_dcto_item_r, rm_z02.z02_dcto_mano_c,
			rm_z02.z02_dcto_mano_r, rm_z02.z02_cheques,
			rm_z02.z02_zona_venta, rm_z02.z02_zona_cobro,
			rm_z02.z02_aux_clte_mb, rm_z02.z02_aux_clte_ma,
			rm_z02.z02_aux_ant_mb, rm_z02.z02_aux_ant_ma)
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
		IF INFIELD(z01_codcli) THEN
                        CALL fl_ayuda_cliente_general()
                                RETURNING codi_aux, nomi_aux
                        LET int_flag = 0
                        IF codi_aux IS NOT NULL THEN
				LET rm_z01.z01_codcli = codi_aux
                                DISPLAY codi_aux TO z01_codcli
                                DISPLAY nomi_aux TO z01_nomcli
                        END IF
                END IF
		IF INFIELD(z01_pais) THEN
                        CALL fl_ayuda_pais()
                                RETURNING codp_aux, nomp_aux
                        LET int_flag = 0
                        IF codp_aux IS NOT NULL THEN
				LET rm_z01.z01_pais = codp_aux
                                DISPLAY BY NAME rm_z01.z01_pais
                                DISPLAY nomp_aux TO tit_pais
                        END IF
                END IF
		IF INFIELD(z01_ciudad) THEN
                        CALL fl_ayuda_ciudad(rm_z01.z01_pais)
                                RETURNING codc_aux, nomc_aux
                        LET int_flag = 0
                        IF codc_aux IS NOT NULL THEN
				LET rm_z01.z01_ciudad = codc_aux
                                DISPLAY BY NAME rm_z01.z01_ciudad
                                DISPLAY nomc_aux TO tit_ciudad
                        END IF
                END IF
		IF INFIELD(z01_tipo_clte) THEN
                        CALL fl_ayuda_subtipo_entidad('CL')
                                RETURNING codt1_aux, codt2_aux,
					  nomt1_aux, nomt2_aux
                        LET int_flag = 0
                        IF codt1_aux IS NOT NULL THEN
				LET rm_z01.z01_tipo_clte = codt2_aux
                                DISPLAY BY NAME rm_z01.z01_tipo_clte
                                DISPLAY nomt1_aux TO tit_tipo_cli
                        END IF
                END IF
		IF INFIELD(z02_zona_venta) THEN
                        CALL fl_ayuda_zona_venta(vg_codcia)
                                RETURNING codzv_aux, nomzv_aux
                        LET int_flag = 0
                        IF codzv_aux IS NOT NULL THEN
				LET rm_z02.z02_zona_venta = codzv_aux
                                DISPLAY BY NAME rm_z02.z02_zona_venta
                                DISPLAY nomzv_aux TO tit_zona_vta
                        END IF
                END IF
		IF INFIELD(z02_zona_cobro) THEN
                        CALL fl_ayuda_zona_cobro()
                                RETURNING codzc_aux, nomzc_aux
                        LET int_flag = 0
                        IF codzc_aux IS NOT NULL THEN
				LET rm_z02.z02_zona_cobro = codzc_aux
                                DISPLAY BY NAME rm_z02.z02_zona_cobro
                                DISPLAY nomzc_aux TO tit_zona_cob
                        END IF
                END IF
		IF INFIELD(z02_aux_clte_mb) THEN
                        CALL fl_ayuda_cuenta_contable(vg_codcia, vm_nivel)
                                RETURNING cod_aux, nom_aux
                        LET int_flag = 0
                        IF cod_aux IS NOT NULL THEN
				LET rm_z02.z02_aux_clte_mb = cod_aux
                                DISPLAY BY NAME rm_z02.z02_aux_clte_mb
                                DISPLAY nom_aux TO tit_cli_mb
                        END IF
                END IF
                IF INFIELD(z02_aux_clte_ma) THEN
                        CALL fl_ayuda_cuenta_contable(vg_codcia, vm_nivel)
                                RETURNING cod_aux, nom_aux
                        LET int_flag = 0
                        IF cod_aux IS NOT NULL THEN
				LET rm_z02.z02_aux_clte_ma = cod_aux
                                DISPLAY BY NAME rm_z02.z02_aux_clte_ma
                                DISPLAY nom_aux TO tit_cli_ma
                        END IF
                END IF
		IF INFIELD(z02_aux_ant_mb) THEN
                        CALL fl_ayuda_cuenta_contable(vg_codcia, vm_nivel)
                                RETURNING cod_aux, nom_aux
                        LET int_flag = 0
                        IF cod_aux IS NOT NULL THEN
				LET rm_z02.z02_aux_ant_mb = cod_aux
                                DISPLAY BY NAME rm_z02.z02_aux_ant_mb
                                DISPLAY nom_aux TO tit_ant_mb
                        END IF
                END IF
                IF INFIELD(z02_aux_ant_ma) THEN
                        CALL fl_ayuda_cuenta_contable(vg_codcia, vm_nivel)
                                RETURNING cod_aux, nom_aux
                        LET int_flag = 0
                        IF cod_aux IS NOT NULL THEN
				LET rm_z02.z02_aux_ant_ma = cod_aux
                                DISPLAY BY NAME rm_z02.z02_aux_ant_ma
                                DISPLAY nom_aux TO tit_ant_ma
                        END IF
                END IF
	BEFORE FIELD z01_codcli
		IF vm_flag_mant = 'M' THEN
			NEXT FIELD NEXT
		END IF
	BEFORE FIELD z01_tipo_doc_id
		IF rm_z01.z01_num_doc_id IS NULL THEN
			CALL fgl_winmessage(vg_producto,'Digite primero el número de identificación de documento','info')
			NEXT FIELD z01_num_doc_id
		END IF
	BEFORE FIELD z01_direccion1
		IF rm_z01.z01_personeria = 'N' THEN
			IF rm_z01.z01_tipo_doc_id = 'R' THEN
				CALL fgl_winmessage(vg_producto,'Una persona natural no puede tener asignado Ruc','exclamation')
				NEXT FIELD z01_tipo_doc_id
			END IF
		ELSE
			IF rm_z01.z01_tipo_doc_id <> 'R' THEN
				CALL fgl_winmessage(vg_producto,'Una persona jurídica no puede tener asignado Cédula o Pasaporte','exclamation')
				NEXT FIELD z01_tipo_doc_id
			END IF
		END IF
	BEFORE FIELD z01_ciudad
		IF rm_z01.z01_pais IS NULL THEN
			CALL fgl_winmessage(vg_producto,'Ingrese el país primero','info')
			NEXT FIELD z01_pais
		END IF
	BEFORE FIELD z02_cupocred_mb
		CALL poner_credit_dias() RETURNING resul
	AFTER FIELD z01_codcli
		IF rm_z01.z01_codcli IS NOT NULL THEN
			CALL fl_lee_cliente_general(rm_z01.z01_codcli)
				RETURNING r_z01.*
			IF r_z01.z01_codcli IS NOT NULL THEN
				CALL fl_mostrar_mensaje('Ya existe ese codigo de cliente. Pertenece al cliente: ' || r_z01.z01_codcli CLIPPED || ' ' || r_z01.z01_nomcli,'exclamation')
				NEXT FIELD z01_codcli
			END IF
		END IF
	AFTER FIELD z01_nomcli
		DISPLAY rm_z01.z01_nomcli TO tit_nombre_cli
	AFTER FIELD z01_num_doc_id
		IF rm_z01.z01_num_doc_id IS NOT NULL THEN
			IF rm_z01.z01_personeria = 'N' THEN
				LET rm_z01.z01_tipo_doc_id = 'C'
			ELSE
				LET rm_z01.z01_tipo_doc_id = 'R'
			END IF
			DISPLAY BY NAME rm_z01.z01_tipo_doc_id
			CALL validar_cedruc(rm_z01.z01_codcli,
						rm_z01.z01_num_doc_id)
				RETURNING resul
			IF NOT resul THEN
				--NEXT FIELD z01_num_doc_id
			END IF
		END IF
	AFTER FIELD z01_pais
                IF rm_z01.z01_pais IS NOT NULL THEN
                        CALL fl_lee_pais(rm_z01.z01_pais)
                                RETURNING r_pai.*
                        IF r_pai.g30_pais IS NULL  THEN
                                CALL fgl_winmessage(vg_producto,'Este país no existe','exclamation')
                                NEXT FIELD z01_pais
                        END IF
                        DISPLAY r_pai.g30_nombre TO tit_pais
                ELSE
                        CLEAR tit_pais
                END IF
	AFTER FIELD z01_ciudad
                IF rm_z01.z01_ciudad IS NOT NULL THEN
                        CALL fl_lee_ciudad(rm_z01.z01_ciudad)
                                RETURNING r_ciu.*
                        IF r_ciu.g31_ciudad IS NULL  THEN
                                CALL fgl_winmessage(vg_producto,'Está ciudad no existe','exclamation')
                                NEXT FIELD z01_ciudad
                        END IF
                        DISPLAY r_ciu.g31_nombre TO tit_ciudad
			IF r_ciu.g31_pais <> r_pai.g30_pais THEN
				CALL fgl_winmessage(vg_producto,'Esta ciudad no pertenece a ese país','exclamation')
				NEXT FIELD z01_ciudad
			END IF
                ELSE
                        CLEAR tit_ciudad
                END IF
	AFTER FIELD z01_tipo_clte
                IF rm_z01.z01_tipo_clte IS NOT NULL THEN
                        CALL fl_lee_subtipo_entidad('CL',rm_z01.z01_tipo_clte)
                                RETURNING r_car.*
                        IF r_car.g12_tiporeg IS NULL  THEN
                                CALL fgl_winmessage(vg_producto,'Cartera no existe','exclamation')
                                NEXT FIELD z01_tipo_clte
                        END IF
                        DISPLAY r_car.g12_nombre TO tit_tipo_cli
		ELSE
			CLEAR tit_tipo_cli
                END IF
	AFTER FIELD z02_credit_auto
		CALL poner_credit_dias() RETURNING resul
	AFTER FIELD z02_zona_venta
		IF rm_z02.z02_zona_venta IS NOT NULL THEN
			CALL fl_lee_zona_venta(vg_codcia,rm_z02.z02_zona_venta)
				RETURNING r_zon_vta.*
			IF r_zon_vta.g32_zona_venta IS NULL THEN
				CALL fgl_winmessage(vg_producto,'Zona de venta no existe','exclamation')
				NEXT FIELD z02_zona_venta
			END IF
			DISPLAY r_zon_vta.g32_nombre TO tit_zona_vta
		ELSE
			CLEAR tit_zona_vta
		END IF
	AFTER FIELD z02_zona_cobro
		IF rm_z02.z02_zona_cobro IS NOT NULL THEN
			CALL fl_lee_zona_cobro(rm_z02.z02_zona_cobro)
				RETURNING r_zon_cob.*
			IF r_zon_cob.z06_zona_cobro IS NULL THEN
				CALL fgl_winmessage(vg_producto,'Zona de venta no existe','exclamation')
				NEXT FIELD z02_zona_cobro
			END IF
			DISPLAY r_zon_cob.z06_nombre TO tit_zona_cob
		ELSE
			CLEAR tit_zona_cob
		END IF
	AFTER FIELD z02_cupocred_mb
		IF rm_z02.z02_cupocred_mb IS NOT NULL THEN
			IF rg_gen.g00_moneda_alt IS NOT NULL
			OR rg_gen.g00_moneda_alt <> ' ' THEN
			       CALL fl_lee_factor_moneda(rg_gen.g00_moneda_base,
				rg_gen.g00_moneda_alt)
					RETURNING r_mon.*
				CALL fl_retorna_precision_valor(
							rg_gen.g00_moneda_base,
                                                        rm_z02.z02_cupocred_mb)
                                	RETURNING rm_z02.z02_cupocred_mb
                                DISPLAY BY NAME rm_z02.z02_cupocred_mb
				IF r_mon.g14_serial IS NOT NULL THEN
					LET rm_z02.z02_cupocred_ma = 
					rm_z02.z02_cupocred_mb * r_mon.g14_tasa
					IF rm_z02.z02_cupocred_ma IS NULL 
					OR rm_z02.z02_cupocred_ma>9999999999.99
					THEN
						CALL fgl_winmessage(vg_producto,'El cupo de crédito en moneda base está demasiado grande', 'exclamation')
						NEXT FIELD z02_cupocred_mb
					END IF
				END IF
				CALL fl_retorna_precision_valor(
							rg_gen.g00_moneda_base,
                                                        rm_z02.z02_cupocred_ma)
                                	RETURNING rm_z02.z02_cupocred_ma
				DISPLAY BY NAME rm_z02.z02_cupocred_ma
			END IF
		END IF
	AFTER FIELD z02_aux_clte_mb
                IF rm_z02.z02_aux_clte_mb IS NOT NULL THEN
			CALL validar_cuenta(rm_z02.z02_aux_clte_mb, 1)
				RETURNING resul
			IF resul = 1 THEN
				NEXT FIELD z02_aux_clte_mb
			END IF
			{--
			CALL cuenta_distintas(rm_z02.z02_aux_clte_mb,
						rm_z02.z02_aux_ant_mb,
						rm_z02.z02_aux_ant_ma)
				RETURNING resul
			IF resul = 1 THEN
				NEXT FIELD z02_aux_clte_mb
			END IF
			--}
		ELSE
			CLEAR tit_cli_mb
                END IF
	AFTER FIELD z02_aux_clte_ma
                IF rm_z02.z02_aux_clte_ma IS NOT NULL THEN
			CALL validar_cuenta(rm_z02.z02_aux_clte_ma, 2)
				RETURNING resul
			IF resul = 1 THEN
				NEXT FIELD z02_aux_clte_ma
			END IF
			{--
			CALL cuenta_distintas(rm_z02.z02_aux_clte_ma,
						rm_z02.z02_aux_ant_mb,
						rm_z02.z02_aux_ant_ma)
				RETURNING resul
			IF resul = 1 THEN
				NEXT FIELD z02_aux_clte_ma
			END IF
			--}
		ELSE
			CLEAR tit_cli_ma
                END IF
	AFTER FIELD z02_aux_ant_mb
                IF rm_z02.z02_aux_ant_mb IS NOT NULL THEN
			CALL validar_cuenta(rm_z02.z02_aux_ant_mb, 3)
				RETURNING resul
			IF resul = 1 THEN
				NEXT FIELD z02_aux_ant_mb
			END IF
			{--
			CALL cuenta_distintas(rm_z02.z02_aux_ant_mb,
						rm_z02.z02_aux_clte_mb,
						rm_z02.z02_aux_clte_ma)
				RETURNING resul
			IF resul = 1 THEN
				NEXT FIELD z02_aux_ant_mb
			END IF
			--}
		ELSE
			CLEAR  tit_ant_mb
                END IF
	AFTER FIELD z02_aux_ant_ma
                IF rm_z02.z02_aux_ant_ma IS NOT NULL THEN
			CALL validar_cuenta(rm_z02.z02_aux_ant_ma, 4)
				RETURNING resul
			IF resul = 1 THEN
				NEXT FIELD z02_aux_ant_ma
			END IF
			{--
			CALL cuenta_distintas(rm_z02.z02_aux_ant_ma,
						rm_z02.z02_aux_clte_mb,
						rm_z02.z02_aux_clte_ma)
				RETURNING resul
			IF resul = 1 THEN
				NEXT FIELD z02_aux_ant_ma
			END IF
			--}
		ELSE
			CLEAR  tit_ant_ma
                END IF
	AFTER INPUT
		CALL poner_credit_dias() RETURNING resul
		IF resul = 1 THEN
			CALL fgl_winmessage(vg_producto,'Crédito de días debe ser mayor a cero, si hay crédito automático','info')
			NEXT FIELD z02_credit_dias
		END IF
		IF vm_flag_mant = 'I' THEN
			IF rm_z01.z01_codcli IS NOT NULL THEN
				CALL fl_lee_cliente_general(rm_z01.z01_codcli)
					RETURNING r_z01.*
				IF r_z01.z01_codcli IS NOT NULL THEN
					CALL fl_mostrar_mensaje('Ya existe ese codigo de cliente. Pertenece al cliente: ' || r_z01.z01_codcli CLIPPED || ' ' || r_z01.z01_nomcli,'exclamation')
					NEXT FIELD z01_codcli
				END IF
				IF r_z01.z01_codcli <= 0 THEN
					CALL fl_mostrar_mensaje('El codigo de cliente debe ser mayor a cero.','exclamation')
					NEXT FIELD z01_codcli
				END IF
			END IF
		END IF
		IF rm_z01.z01_num_doc_id IS NOT NULL THEN
			CALL validar_cedruc(rm_z01.z01_codcli,
						rm_z01.z01_num_doc_id)
				RETURNING resul
			IF NOT resul THEN
				NEXT FIELD z01_num_doc_id
			END IF
		END IF
END INPUT

END FUNCTION



FUNCTION validar_cedruc(codcli, cedruc)
DEFINE codcli		LIKE cxct001.z01_codcli
DEFINE cedruc		LIKE cxct001.z01_num_doc_id
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
	IF rm_z01.z01_tipo_doc_id = 'C' OR rm_z01.z01_tipo_doc_id = 'R' THEN
		CALL fl_validar_cedruc_dig_ver(cedruc) RETURNING resul
	END IF
END IF
RETURN resul

END FUNCTION



FUNCTION validar_cuenta(aux_cont, flag)
DEFINE aux_cont		LIKE ctbt010.b10_cuenta
DEFINE flag		SMALLINT
DEFINE r_b10            RECORD LIKE ctbt010.*

CALL fl_lee_cuenta(vg_codcia, aux_cont) RETURNING r_b10.*
IF r_b10.b10_cuenta IS NULL  THEN
	CALL fgl_winmessage(vg_producto,'Cuenta no existe para esta compañía.','exclamation')
	RETURN 1
END IF
CASE flag
	WHEN 1
		DISPLAY r_b10.b10_descripcion TO tit_cli_mb
	WHEN 2
		DISPLAY r_b10.b10_descripcion TO tit_cli_ma
	WHEN 3
		DISPLAY r_b10.b10_descripcion TO tit_ant_mb
	WHEN 4
		DISPLAY r_b10.b10_descripcion TO tit_ant_ma
END CASE
IF r_b10.b10_estado = 'B' THEN
	CALL fl_mensaje_estado_bloqueado()
	RETURN 1
END IF
IF r_b10.b10_nivel <> vm_nivel THEN
	CALL fgl_winmessage(vg_producto,'Nivel de cuenta debe ser solo del ultimo.','exclamation')
	RETURN 1
END IF
RETURN 0

END FUNCTION



FUNCTION cuenta_distintas(aux_cont, c1, c2)
DEFINE aux_cont		LIKE ctbt010.b10_cuenta
DEFINE c1		LIKE ctbt010.b10_cuenta
DEFINE c2		LIKE ctbt010.b10_cuenta

IF aux_cont = c1 OR aux_cont = c2 THEN
	CALL fgl_winmessage(vg_producto,'Las cuentas de clientes deben ser distintas de las cuentas de anticípo.','exclamation')
	RETURN 1
END IF
RETURN 0

END FUNCTION



FUNCTION poner_credit_dias()

IF rm_z02.z02_credit_auto = 'N' THEN
	LET rm_z02.z02_credit_dias = 0
	DISPLAY BY NAME rm_z02.z02_credit_dias
ELSE
	IF rm_z02.z02_credit_dias = 0 OR rm_z02.z02_credit_dias IS NULL THEN
		RETURN 1
	END IF
END IF
RETURN 0

END FUNCTION



FUNCTION muestra_siguiente_registro()

IF vm_row_current < vm_num_rows THEN
	LET vm_row_current = vm_row_current + 1
END IF
CALL muestra_reg()

END FUNCTION



FUNCTION muestra_anterior_registro()

IF vm_row_current > 1 THEN
	LET vm_row_current = vm_row_current - 1
END IF
CALL muestra_reg()

END FUNCTION



FUNCTION muestra_contadores(row_current, num_rows)
DEFINE row_current	SMALLINT
DEFINE num_rows		SMALLINT
                                                                                
DISPLAY "        " TO tit_estado_cli
CLEAR tit_estado_cli
DISPLAY row_current TO vm_row_current3
DISPLAY num_rows    TO vm_num_rows3
DISPLAY row_current TO vm_row_current2
DISPLAY num_rows    TO vm_num_rows2
DISPLAY row_current TO vm_row_current1
DISPLAY num_rows    TO vm_num_rows1
                                                                                
END FUNCTION



FUNCTION mostrar_registro(num_registro, codloc, codcli)
DEFINE num_registro	INTEGER
DEFINE codloc		LIKE cxct002.z02_localidad
DEFINE codcli		LIKE cxct002.z02_codcli
DEFINE r_g02            RECORD LIKE gent002.*
DEFINE r_pai            RECORD LIKE gent030.*
DEFINE r_ciu            RECORD LIKE gent031.*
DEFINE r_car            RECORD LIKE gent012.*
DEFINE r_b10            RECORD LIKE ctbt010.*
DEFINE r_zon_vta	RECORD LIKE gent032.*
DEFINE r_zon_cob	RECORD LIKE cxct006.*

IF vm_num_rows <= 0 THEN
	RETURN
END IF
SELECT * INTO rm_z01.* FROM cxct001 WHERE ROWID = num_registro	
IF STATUS = NOTFOUND THEN
	CALL fgl_winmessage (vg_producto,'No existe registro con índice: ' || vm_row_current,'exclamation')
	RETURN
END IF
DISPLAY BY NAME rm_z01.z01_codcli, rm_z01.z01_nomcli,
		rm_z01.z01_personeria, rm_z01.z01_num_doc_id,
		rm_z01.z01_tipo_doc_id, rm_z01.z01_direccion1, 
		rm_z01.z01_telefono1, rm_z01.z01_tipo_clte,
		rm_z01.z01_direccion2, rm_z01.z01_telefono2,
		rm_z01.z01_fax1, rm_z01.z01_fax2, rm_z01.z01_casilla,
		rm_z01.z01_pais, rm_z01.z01_ciudad,rm_z01.z01_rep_legal,
		rm_z01.z01_paga_impto, rm_z01.z01_usuario,
		rm_z01.z01_fecing
CALL fl_lee_pais(rm_z01.z01_pais) RETURNING r_pai.*
DISPLAY r_pai.g30_nombre TO tit_pais
CALL fl_lee_ciudad(rm_z01.z01_ciudad) RETURNING r_ciu.*
DISPLAY r_ciu.g31_nombre TO tit_ciudad
CALL fl_lee_subtipo_entidad('CL',rm_z01.z01_tipo_clte) RETURNING r_car.*
DISPLAY r_car.g12_nombre TO tit_tipo_cli
SELECT * INTO rm_z02.* FROM cxct002
	WHERE z02_compania  = vg_codcia
	  AND z02_localidad = codloc
	  AND z02_codcli    = codcli
IF STATUS = NOTFOUND THEN
	CALL muestra_estado()
	RETURN
END IF
DISPLAY rm_z01.z01_codcli TO tit_codigo_cli
DISPLAY rm_z01.z01_nomcli TO tit_nombre_cli
DISPLAY BY NAME rm_z02.z02_localidad, rm_z02.z02_contacto,
		rm_z02.z02_referencia, rm_z02.z02_credit_auto,
		rm_z02.z02_credit_dias, rm_z02.z02_cupocred_mb,
		rm_z02.z02_cupocred_ma, rm_z02.z02_dcto_item_c,
		rm_z02.z02_dcto_item_r, rm_z02.z02_dcto_mano_c,
		rm_z02.z02_dcto_mano_r, rm_z02.z02_cheques,
		rm_z02.z02_zona_venta, rm_z02.z02_zona_cobro,
		rm_z02.z02_aux_clte_mb, rm_z02.z02_aux_clte_ma,
		rm_z02.z02_aux_ant_mb, rm_z02.z02_aux_ant_ma
CALL fl_lee_localidad(vg_codcia, rm_z02.z02_localidad) RETURNING r_g02.*
DISPLAY r_g02.g02_nombre TO tit_localidad
CALL fl_lee_zona_venta(vg_codcia, rm_z02.z02_zona_venta) RETURNING r_zon_vta.*
DISPLAY r_zon_vta.g32_nombre TO tit_zona_vta
CALL fl_lee_zona_cobro(rm_z02.z02_zona_cobro) RETURNING r_zon_cob.*
DISPLAY r_zon_cob.z06_nombre TO tit_zona_cob
CALL fl_lee_cuenta(vg_codcia, rm_z02.z02_aux_clte_mb) RETURNING r_b10.*
DISPLAY r_b10.b10_descripcion TO tit_cli_mb
CALL fl_lee_cuenta(vg_codcia, rm_z02.z02_aux_clte_ma) RETURNING r_b10.*
DISPLAY r_b10.b10_descripcion TO tit_cli_ma
CALL fl_lee_cuenta(vg_codcia, rm_z02.z02_aux_ant_mb) RETURNING r_b10.*
DISPLAY r_b10.b10_descripcion TO tit_ant_mb
CALL fl_lee_cuenta(vg_codcia, rm_z02.z02_aux_ant_ma) RETURNING r_b10.*
DISPLAY r_b10.b10_descripcion TO tit_ant_ma
CALL muestra_estado()

END FUNCTION



FUNCTION muestra_reg()

CALL mostrar_registro(vm_r_rows[vm_row_current], vm_r_cli[vm_row_current].*)
CALL muestra_contadores(vm_row_current, vm_num_rows)
CALL muestra_estado()

END FUNCTION



FUNCTION retorna_codcli()
DEFINE resul		SMALLINT
DEFINE resp		CHAR(6)

LET resul = 1
SELECT MAX(z01_codcli) INTO rm_z01.z01_codcli FROM cxct001
IF rm_z01.z01_codcli IS NOT NULL THEN
	LET rm_z01.z01_codcli = rm_z01.z01_codcli + 1
ELSE
	LET rm_z01.z01_codcli = 1
END IF
CALL fl_hacer_pregunta('Atención se genrara el código ' || rm_z01.z01_codcli CLIPPED || '. Desea crearlo?','Yes')
	RETURNING resp
IF resp = 'No' THEN
	LET resul = 0
END IF
RETURN resul

END FUNCTION



FUNCTION bloquear_activar()
DEFINE confir		CHAR(6)

IF vm_num_rows = 0 THEN
	CALL fl_mensaje_consultar_primero()
	RETURN
END IF
LET int_flag = 0
CALL mostrar_registro(vm_r_rows[vm_row_current], vm_r_cli[vm_row_current].*)
BEGIN WORK
WHENEVER ERROR CONTINUE
DECLARE q_ba CURSOR FOR
	SELECT * FROM cxct001 WHERE ROWID = vm_r_rows[vm_row_current]
	FOR UPDATE
OPEN q_ba
FETCH q_ba INTO rm_z01.*
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
CALL fl_mostrar_mensaje('Se cambió el estado del Cliente Ok.', 'info')

END FUNCTION



FUNCTION bloquea_activa_registro()
DEFINE estado		LIKE cxct001.z01_estado

IF rm_z01.z01_estado = 'A' THEN
	LET estado = 'B'
END IF
IF rm_z01.z01_estado = 'B' THEN
	LET estado = 'A'
END IF
LET rm_z01.z01_estado = estado
UPDATE cxct001 SET z01_estado = estado WHERE CURRENT OF q_ba
CALL muestra_estado()

END FUNCTION



FUNCTION muestra_estado()

IF rm_z01.z01_estado = 'A' THEN
	DISPLAY 'ACTIVO' TO tit_estado_cli
END IF
IF rm_z01.z01_estado = 'B' THEN
	DISPLAY 'BLOQUEADO' TO tit_estado_cli
END IF
DISPLAY rm_z01.z01_estado TO tit_est

END FUNCTION



FUNCTION ver_areaneg(flag)
DEFINE flag		CHAR(1)

LET vm_nuevoprog = 'cd ..', vg_separador, '..', vg_separador, 'COBRANZAS',
	vg_separador, 'fuentes', vg_separador, '; fglrun cxcp106 ' , vg_base,
	' ', vg_modulo, ' ', vg_codcia, ' ', vm_r_cli[vm_row_current].codloc,
	' ', rm_z01.z01_codcli, ' ', flag
RUN vm_nuevoprog

END FUNCTION



FUNCTION control_localidad()

CLEAR z02_localidad, tit_localidad,
	z02_contacto, z02_referencia, z02_credit_auto, z02_credit_dias,
	z02_cupocred_mb, z02_cupocred_ma, z02_dcto_item_c, z02_dcto_item_r,
	z02_dcto_mano_c, z02_dcto_mano_r, z02_cheques, z02_zona_venta,
	z02_zona_cobro, tit_zona_vta, tit_zona_cob, z02_aux_clte_mb,
	z02_aux_clte_ma, z02_aux_ant_mb, z02_aux_ant_ma, tit_cli_mb, tit_cli_ma,
	tit_ant_mb, tit_ant_ma
CALL datos_defaults_z02()
CALL leer_datos_z02()
IF NOT int_flag THEN
	LET rm_z02.z02_compania = vg_codcia
	LET rm_z02.z02_codcli   = rm_z01.z01_codcli
	LET rm_z02.z02_fecing   = CURRENT
	INSERT INTO cxct002 VALUES (rm_z02.*)
	LET vm_r_cli[vm_row_current].codloc = rm_z02.z02_localidad
	LET vm_r_cli[vm_row_current].codcli = rm_z02.z02_codcli
	CALL muestra_contadores(vm_row_current, vm_num_rows)
	CALL fl_mostrar_mensaje('Cliente activiado para localidad ' || rm_z02.z02_localidad, 'info')
ELSE
	CLEAR FORM
	IF vm_row_current > 0 THEN
		CALL mostrar_registro(vm_r_rows[vm_row_current],
					vm_r_cli[vm_row_current].*)
	END IF
	CALL muestra_contadores(vm_row_current, vm_num_rows)
END IF
CALL muestra_estado()

END FUNCTION



FUNCTION leer_datos_z02()
DEFINE resp		CHAR(6)
DEFINE resul		SMALLINT
DEFINE r_z02            RECORD LIKE cxct002.*
DEFINE r_g02            RECORD LIKE gent002.*
DEFINE r_g32		RECORD LIKE gent032.*
DEFINE r_z06		RECORD LIKE cxct006.*
DEFINE r_g14		RECORD LIKE gent014.*
DEFINE codzv_aux        LIKE gent032.g32_zona_venta
DEFINE nomzv_aux        LIKE gent032.g32_nombre
DEFINE codzc_aux        LIKE cxct006.z06_zona_cobro
DEFINE nomzc_aux        LIKE cxct006.z06_nombre
DEFINE cod_aux          LIKE ctbt010.b10_cuenta
DEFINE nom_aux          LIKE ctbt010.b10_descripcion

INITIALIZE rm_z02.z02_localidad, r_g32.*, r_z06.*, r_g14.*, codzv_aux,
	codzc_aux, cod_aux TO NULL
DISPLAY BY NAME rm_z02.z02_credit_dias, rm_z02.z02_cupocred_mb,
		rm_z02.z02_cupocred_ma, rm_z02.z02_dcto_item_c,
		rm_z02.z02_dcto_item_r, rm_z02.z02_dcto_mano_c,
		rm_z02.z02_dcto_mano_r, rm_z02.z02_aux_clte_mb,
		rm_z02.z02_aux_clte_ma, rm_z02.z02_aux_ant_mb,
		rm_z02.z02_aux_ant_ma
LET int_flag = 0
INPUT BY NAME rm_z02.z02_localidad, rm_z02.z02_contacto, rm_z02.z02_referencia,
	rm_z02.z02_credit_auto, rm_z02.z02_credit_dias, rm_z02.z02_cupocred_mb,
	rm_z02.z02_dcto_item_c, rm_z02.z02_dcto_item_r, rm_z02.z02_dcto_mano_c,
	rm_z02.z02_dcto_mano_r, rm_z02.z02_cheques, rm_z02.z02_zona_venta,
	rm_z02.z02_zona_cobro, rm_z02.z02_aux_clte_mb, rm_z02.z02_aux_clte_ma,
	rm_z02.z02_aux_ant_mb, rm_z02.z02_aux_ant_ma
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
        	IF field_touched(rm_z02.z02_localidad, rm_z02.z02_contacto,
			rm_z02.z02_referencia, rm_z02.z02_credit_auto,
			rm_z02.z02_credit_dias, rm_z02.z02_cupocred_mb,
			rm_z02.z02_dcto_item_c, rm_z02.z02_dcto_item_r,
			rm_z02.z02_dcto_mano_c, rm_z02.z02_dcto_mano_r,
			rm_z02.z02_cheques, rm_z02.z02_zona_venta,
			rm_z02.z02_zona_cobro, rm_z02.z02_aux_clte_mb,
			rm_z02.z02_aux_clte_ma, rm_z02.z02_aux_ant_mb,
			rm_z02.z02_aux_ant_ma)
        	THEN
               		LET int_flag = 0
			CALL fl_mensaje_abandonar_proceso()
                		RETURNING resp
              		IF resp = 'Yes' THEN
				LET rm_z02.z02_localidad = vg_codloc
				LET int_flag = 1
                       		CLEAR FORM
                       		RETURN
                	END IF
		ELSE
			RETURN
		END IF
	ON KEY(F2)
		IF INFIELD(z02_localidad) THEN
			CALL fl_ayuda_localidad(vg_codcia)
				RETURNING r_g02.g02_localidad, r_g02.g02_nombre
                        LET int_flag = 0
			IF r_g02.g02_localidad IS NOT NULL THEN
				LET rm_z02.z02_localidad = r_g02.g02_localidad
				DISPLAY r_g02.g02_localidad TO z02_localidad
				DISPLAY r_g02.g02_nombre    TO tit_localidad
			END IF
                END IF
		IF INFIELD(z02_zona_venta) THEN
                        CALL fl_ayuda_zona_venta(vg_codcia)
                                RETURNING codzv_aux, nomzv_aux
                        LET int_flag = 0
                        IF codzv_aux IS NOT NULL THEN
				LET rm_z02.z02_zona_venta = codzv_aux
                                DISPLAY BY NAME rm_z02.z02_zona_venta
                                DISPLAY nomzv_aux TO tit_zona_vta
                        END IF
                END IF
		IF INFIELD(z02_zona_cobro) THEN
                        CALL fl_ayuda_zona_cobro()
                                RETURNING codzc_aux, nomzc_aux
                        LET int_flag = 0
                        IF codzc_aux IS NOT NULL THEN
				LET rm_z02.z02_zona_cobro = codzc_aux
                                DISPLAY BY NAME rm_z02.z02_zona_cobro
                                DISPLAY nomzc_aux TO tit_zona_cob
                        END IF
                END IF
		IF INFIELD(z02_aux_clte_mb) THEN
                        CALL fl_ayuda_cuenta_contable(vg_codcia, vm_nivel)
                                RETURNING cod_aux, nom_aux
                        LET int_flag = 0
                        IF cod_aux IS NOT NULL THEN
				LET rm_z02.z02_aux_clte_mb = cod_aux
                                DISPLAY BY NAME rm_z02.z02_aux_clte_mb
                                DISPLAY nom_aux TO tit_cli_mb
                        END IF
                END IF
                IF INFIELD(z02_aux_clte_ma) THEN
                        CALL fl_ayuda_cuenta_contable(vg_codcia, vm_nivel)
                                RETURNING cod_aux, nom_aux
                        LET int_flag = 0
                        IF cod_aux IS NOT NULL THEN
				LET rm_z02.z02_aux_clte_ma = cod_aux
                                DISPLAY BY NAME rm_z02.z02_aux_clte_ma
                                DISPLAY nom_aux TO tit_cli_ma
                        END IF
                END IF
		IF INFIELD(z02_aux_ant_mb) THEN
                        CALL fl_ayuda_cuenta_contable(vg_codcia, vm_nivel)
                                RETURNING cod_aux, nom_aux
                        LET int_flag = 0
                        IF cod_aux IS NOT NULL THEN
				LET rm_z02.z02_aux_ant_mb = cod_aux
                                DISPLAY BY NAME rm_z02.z02_aux_ant_mb
                                DISPLAY nom_aux TO tit_ant_mb
                        END IF
                END IF
                IF INFIELD(z02_aux_ant_ma) THEN
                        CALL fl_ayuda_cuenta_contable(vg_codcia, vm_nivel)
                                RETURNING cod_aux, nom_aux
                        LET int_flag = 0
                        IF cod_aux IS NOT NULL THEN
				LET rm_z02.z02_aux_ant_ma = cod_aux
                                DISPLAY BY NAME rm_z02.z02_aux_ant_ma
                                DISPLAY nom_aux TO tit_ant_ma
                        END IF
                END IF
	BEFORE FIELD z02_cupocred_mb
		CALL poner_credit_dias() RETURNING resul
	AFTER FIELD z02_localidad
		IF rm_z02.z02_localidad IS NOT NULL THEN
			CALL fl_lee_cliente_localidad(vg_codcia,
					rm_z02.z02_localidad, rm_z01.z01_codcli)
				RETURNING r_z02.*
			IF r_z02.z02_localidad IS NOT NULL THEN
				CALL fl_mostrar_mensaje('El Cliente ' || rm_z01.z01_codcli || ' ya esta activado para esta localidad.','exclamation')
				NEXT FIELD z02_localidad
			END IF
			CALL fl_lee_localidad(vg_codcia, rm_z02.z02_localidad)
				RETURNING r_g02.*
			IF r_g02.g02_localidad IS NULL THEN
				CALL fl_mostrar_mensaje('No existe esta localidad.','exclamation')
				NEXT FIELD z02_localidad
			END IF
			IF r_g02.g02_estado = 'B' THEN
				CALL fl_mensaje_estado_bloqueado()
				NEXT FIELD z02_localidad
			END IF
			DISPLAY r_g02.g02_nombre TO tit_localidad
		ELSE
			CLEAR tit_localidad
		END IF
	AFTER FIELD z02_credit_auto
		CALL poner_credit_dias() RETURNING resul
	AFTER FIELD z02_zona_venta
		IF rm_z02.z02_zona_venta IS NOT NULL THEN
			CALL fl_lee_zona_venta(vg_codcia,rm_z02.z02_zona_venta)
				RETURNING r_g32.*
			IF r_g32.g32_zona_venta IS NULL THEN
				CALL fgl_winmessage(vg_producto,'Zona de venta no existe','exclamation')
				NEXT FIELD z02_zona_venta
			END IF
			DISPLAY r_g32.g32_nombre TO tit_zona_vta
		ELSE
			CLEAR tit_zona_vta
		END IF
	AFTER FIELD z02_zona_cobro
		IF rm_z02.z02_zona_cobro IS NOT NULL THEN
			CALL fl_lee_zona_cobro(rm_z02.z02_zona_cobro)
				RETURNING r_z06.*
			IF r_z06.z06_zona_cobro IS NULL THEN
				CALL fgl_winmessage(vg_producto,'Zona de venta no existe','exclamation')
				NEXT FIELD z02_zona_cobro
			END IF
			DISPLAY r_z06.z06_nombre TO tit_zona_cob
		ELSE
			CLEAR tit_zona_cob
		END IF
	AFTER FIELD z02_cupocred_mb
		IF rm_z02.z02_cupocred_mb IS NOT NULL THEN
			IF rg_gen.g00_moneda_alt IS NOT NULL
			OR rg_gen.g00_moneda_alt <> ' ' THEN
			       CALL fl_lee_factor_moneda(rg_gen.g00_moneda_base,
				rg_gen.g00_moneda_alt)
					RETURNING r_g14.*
				CALL fl_retorna_precision_valor(
							rg_gen.g00_moneda_base,
                                                        rm_z02.z02_cupocred_mb)
                                	RETURNING rm_z02.z02_cupocred_mb
                                DISPLAY BY NAME rm_z02.z02_cupocred_mb
				IF r_g14.g14_serial IS NOT NULL THEN
					LET rm_z02.z02_cupocred_ma = 
					rm_z02.z02_cupocred_mb * r_g14.g14_tasa
					IF rm_z02.z02_cupocred_ma IS NULL 
					OR rm_z02.z02_cupocred_ma>9999999999.99
					THEN
						CALL fgl_winmessage(vg_producto,'El cupo de crédito en moneda base está demasiado grande', 'exclamation')
						NEXT FIELD z02_cupocred_mb
					END IF
				END IF
				CALL fl_retorna_precision_valor(
							rg_gen.g00_moneda_base,
                                                        rm_z02.z02_cupocred_ma)
                                	RETURNING rm_z02.z02_cupocred_ma
				DISPLAY BY NAME rm_z02.z02_cupocred_ma
			END IF
		END IF
	AFTER FIELD z02_aux_clte_mb
                IF rm_z02.z02_aux_clte_mb IS NOT NULL THEN
			CALL validar_cuenta(rm_z02.z02_aux_clte_mb, 1)
				RETURNING resul
			IF resul = 1 THEN
				NEXT FIELD z02_aux_clte_mb
			END IF
			{--
			CALL cuenta_distintas(rm_z02.z02_aux_clte_mb,
						rm_z02.z02_aux_ant_mb,
						rm_z02.z02_aux_ant_ma)
				RETURNING resul
			IF resul = 1 THEN
				NEXT FIELD z02_aux_clte_mb
			END IF
			--}
		ELSE
			CLEAR tit_cli_mb
                END IF
	AFTER FIELD z02_aux_clte_ma
                IF rm_z02.z02_aux_clte_ma IS NOT NULL THEN
			CALL validar_cuenta(rm_z02.z02_aux_clte_ma, 2)
				RETURNING resul
			IF resul = 1 THEN
				NEXT FIELD z02_aux_clte_ma
			END IF
			{--
			CALL cuenta_distintas(rm_z02.z02_aux_clte_ma,
						rm_z02.z02_aux_ant_mb,
						rm_z02.z02_aux_ant_ma)
				RETURNING resul
			IF resul = 1 THEN
				NEXT FIELD z02_aux_clte_ma
			END IF
			--}
		ELSE
			CLEAR tit_cli_ma
                END IF
	AFTER FIELD z02_aux_ant_mb
                IF rm_z02.z02_aux_ant_mb IS NOT NULL THEN
			CALL validar_cuenta(rm_z02.z02_aux_ant_mb, 3)
				RETURNING resul
			IF resul = 1 THEN
				NEXT FIELD z02_aux_ant_mb
			END IF
			{--
			CALL cuenta_distintas(rm_z02.z02_aux_ant_mb,
						rm_z02.z02_aux_clte_mb,
						rm_z02.z02_aux_clte_ma)
				RETURNING resul
			IF resul = 1 THEN
				NEXT FIELD z02_aux_ant_mb
			END IF
			--}
		ELSE
			CLEAR  tit_ant_mb
                END IF
	AFTER FIELD z02_aux_ant_ma
                IF rm_z02.z02_aux_ant_ma IS NOT NULL THEN
			CALL validar_cuenta(rm_z02.z02_aux_ant_ma, 4)
				RETURNING resul
			IF resul = 1 THEN
				NEXT FIELD z02_aux_ant_ma
			END IF
			{--
			CALL cuenta_distintas(rm_z02.z02_aux_ant_ma,
						rm_z02.z02_aux_clte_mb,
						rm_z02.z02_aux_clte_ma)
				RETURNING resul
			IF resul = 1 THEN
				NEXT FIELD z02_aux_ant_ma
			END IF
			--}
		ELSE
			CLEAR  tit_ant_ma
                END IF
	AFTER INPUT
		CALL poner_credit_dias() RETURNING resul
		IF resul = 1 THEN
			CALL fgl_winmessage(vg_producto,'Crédito de días debe ser mayor a cero, si hay crédito automático','info')
			NEXT FIELD z02_credit_dias
		END IF
END INPUT

END FUNCTION
