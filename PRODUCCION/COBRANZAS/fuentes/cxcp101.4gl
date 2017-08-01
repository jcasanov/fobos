--------------------------------------------------------------------------------
-- Titulo           : cxcp101.4gl - Mantenimiento de Clientes 
-- Elaboracion      : 04-oct-2001
-- Autor            : NPC
-- Formato Ejecucion: fglrun cxcp101 base módulo compañía [localidad] [cliente]
-- Ultima Correccion: 
-- Motivo Correccion: 
--------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE rm_z01		RECORD LIKE cxct001.*
DEFINE rm_z02		RECORD LIKE cxct002.*
DEFINE rm_g05		RECORD LIKE gent005.*
DEFINE vm_num_rows	SMALLINT
DEFINE vm_row_current	SMALLINT
DEFINE vm_max_rows	SMALLINT
DEFINE vm_r_rows	ARRAY [20000] OF INTEGER
DEFINE vm_r_cli		ARRAY [20000] OF RECORD
				codloc		LIKE cxct002.z02_localidad,
				codcli		LIKE cxct002.z02_codcli
			END RECORD
DEFINE rm_detret	ARRAY [100] OF RECORD
				z08_porcentaje	LIKE cxct008.z08_porcentaje,
				z08_tipo_ret	LIKE cxct008.z08_tipo_ret,
				c02_nombre	LIKE ordt002.c02_nombre,
				z08_codigo_sri	LIKE cxct008.z08_codigo_sri,
			z08_fecha_ini_porc LIKE cxct008.z08_fecha_ini_porc,
				c03_concepto_ret LIKE ordt003.c03_concepto_ret,
				c03_tipo_fuente	LIKE ordt003.c03_tipo_fuente,
				z08_defecto	LIKE cxct008.z08_defecto,
				z08_flete	LIKE cxct008.z08_flete
			END RECORD
DEFINE rm_detz09	ARRAY [50] OF RECORD
				z09_codigo_pago	LIKE cxct009.z09_codigo_pago,
				j01_nombre	LIKE cajt001.j01_nombre,
				z09_cont_cred	LIKE cxct009.z09_cont_cred,
                                tit_cont_cred	VARCHAR(10),
				z09_aux_cont	LIKE cxct009.z09_aux_cont,
				b10_descripcion	LIKE ctbt010.b10_descripcion
			END RECORD
DEFINE vm_num_ret	SMALLINT
DEFINE vm_max_ret	SMALLINT
DEFINE vm_num_det	SMALLINT
DEFINE vm_max_det	SMALLINT
DEFINE vm_flag_mant	CHAR(1)



MAIN

DEFER QUIT 
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/cxcp101.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 AND num_args() <> 5 THEN   -- Validar # parámetros correcto
	CALL fl_mostrar_mensaje('Número de parametros incorrecto', 'stop')
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
CREATE TEMP TABLE tmp_z09
	(
		tipo_ret		CHAR(1),
		porc_ret		DECIMAL(5,2),
		codigo_sri		CHAR(6),
		fec_ini_por		DATE,
		cod_pago		CHAR(2),
		nom_pago		VARCHAR(20),
		cont_cred		CHAR(1),
		tit_cont_cred		VARCHAR(10),
		aux_cont		CHAR(12),
		nom_cuenta		VARCHAR(40)
	)
LET vm_max_rows	= 20000
LET vm_max_ret  = 100
LET vm_max_det  = 50
OPEN WINDOW wf AT 3,2 WITH 21 ROWS, 80 COLUMNS
    ATTRIBUTE(FORM LINE FIRST + 2, COMMENT LINE LAST, MENU LINE FIRST,BORDER,
	      MESSAGE LINE LAST - 1)
OPTIONS INPUT WRAP,
	ACCEPT KEY	F12
OPEN FORM f_cxc FROM "../forms/cxcf101_1"
DISPLAY FORM f_cxc
INITIALIZE rm_z01.*, rm_z02.* TO NULL

CALL fl_lee_usuario(vg_usuario) RETURNING rm_g05.*
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
		HIDE OPTION 'Retenciones'
		HIDE OPTION 'Grabar'
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
			SHOW OPTION 'Retenciones'
		END IF
	COMMAND KEY('I') 'Ingresar' 'Ingresar nuevos registros. '
		CALL control_ingreso()
		IF vm_num_rows = 1 THEN
			SHOW OPTION 'Modificar'
			SHOW OPTION 'Bloquear/Activar'
			SHOW OPTION 'Area de Negocio'
			SHOW OPTION 'Retenciones'
			SHOW OPTION 'Localidad'
		END IF
		IF vm_row_current > 1 THEN
			SHOW OPTION 'Retroceder'
		END IF
		IF vm_row_current = vm_num_rows THEN
			HIDE OPTION 'Avanzar'
		END IF
		IF vm_flag_mant = 'I' THEN
			SHOW OPTION 'Grabar'
		ELSE
			HIDE OPTION 'Grabar'
		END IF
       	COMMAND KEY('M') 'Modificar' 'Modificar registro corriente. '
		CALL control_modificacion()
		HIDE OPTION 'Grabar'
	COMMAND KEY('C') 'Consultar' 'Consultar un registro. '
		CALL control_consulta()
		IF vm_num_rows <= 1 THEN
			SHOW OPTION 'Modificar'
			SHOW OPTION 'Bloquear/Activar'
			SHOW OPTION 'Area de Negocio'
			SHOW OPTION 'Retenciones'
			SHOW OPTION 'Localidad'
			HIDE OPTION 'Avanzar'
			HIDE OPTION 'Retroceder'
			IF vm_num_rows = 0 THEN
				HIDE OPTION 'Modificar'
				HIDE OPTION 'Bloquear/Activar'
				HIDE OPTION 'Area de Negocio'
				HIDE OPTION 'Retenciones'
				HIDE OPTION 'Localidad'
			END IF
		ELSE
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Modificar'
			SHOW OPTION 'Bloquear/Activar'
			SHOW OPTION 'Area de Negocio'
			SHOW OPTION 'Retenciones'
			SHOW OPTION 'Localidad'
		END IF
		IF vm_row_current <= 1 THEN
                        HIDE OPTION 'Retroceder'
                END IF
		HIDE OPTION 'Grabar'
     	COMMAND KEY('N') 'Area de Negocio' 'Areas negocio de una Cia./Local. '
		LET flag = 'X'
		IF num_args() = 5 THEN
			LET flag = 'O'
		END IF
		CALL ver_areaneg(flag)
     	COMMAND KEY('L') 'Localidad' 'Activar Cliente para otra Localidad. '
		CALL control_localidad()
	COMMAND KEY('Y') 'Retenciones' 'Configuracion retenciones clientes. '
		IF num_args() <> 5 THEN
			CALL control_retenciones('I')
			IF vm_flag_mant = 'C' THEN
				SHOW OPTION 'Grabar'
			ELSE
				HIDE OPTION 'Grabar'
			END IF
		ELSE
			CALL control_retenciones('C')
		END IF
     	COMMAND KEY('G') 'Grabar' 'Graba el registro corriente. '
		BEGIN WORK
			CALL control_grabar()
		COMMIT WORK
		HIDE OPTION 'Grabar'
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
IF rm_g05.g05_tipo = 'UF' THEN
	LET rm_z02.z02_cheques = 'N'
END IF
--LET rm_z02.z02_credit_dias = r_z00.z00_credit_dias
LET rm_z02.z02_credit_dias  = 0
LET rm_z02.z02_cupcred_aprob  = 0
LET rm_z02.z02_cupcred_xaprob  = 0
LET rm_z02.z02_dcto_item_c  = 0
LET rm_z02.z02_dcto_item_r  = 0
LET rm_z02.z02_dcto_mano_c  = 0
LET rm_z02.z02_dcto_mano_r  = 0
LET rm_z02.z02_usuario      = vg_usuario
LET rm_z02.z02_fecing       = CURRENT

END FUNCTION



FUNCTION control_ingreso()
DEFINE r_g12		RECORD LIKE gent012.*
DEFINE r_g30		RECORD LIKE gent030.*
DEFINE num_aux		INTEGER

CLEAR FORM
CALL fl_retorna_usuario()
LET num_aux = 0 
INITIALIZE rm_z01.*, rm_z02.* TO NULL
CALL datos_defaults_z02()
LET rm_z01.z01_personeria  = 'N'
LET rm_z01.z01_tipo_doc_id = 'C'
LET rm_z01.z01_paga_impto  = 'S'
LET rm_z02.z02_contr_espe  = 'N'
LET rm_z02.z02_oblig_cont  = 'N'
LET rm_z01.z01_estado      = 'A'
LET rm_z01.z01_usuario     = vg_usuario
LET rm_z01.z01_fecing      = CURRENT
CALL muestra_estado()
LET vm_flag_mant = 'I'
IF rm_g05.g05_tipo = 'UF' THEN
	LET rm_z01.z01_tipo_clte = 1
	LET rm_z01.z01_pais      = 1
	CALL fl_lee_pais(rm_z01.z01_pais) RETURNING r_g30.*
	DISPLAY r_g30.g30_nombre TO tit_pais
	CALL fl_lee_subtipo_entidad('CL',rm_z01.z01_tipo_clte) RETURNING r_g12.*
	DISPLAY r_g12.g12_nombre TO tit_tipo_cli
END IF
CALL leer_datos()
IF int_flag THEN
	CALL muestra_reg_salir()
	RETURN
END IF
IF rm_z01.z01_codcli IS NULL THEN
	IF retorna_codcli() = 0 THEN
		LET rm_z01.z01_codcli = NULL
		CALL leer_datos()
		IF int_flag THEN
			CALL muestra_reg_salir()
			RETURN
		END IF
		IF rm_z01.z01_codcli IS NULL THEN
			IF retorna_codcli() = 0 THEN
				CALL muestra_reg_salir()
				RETURN
			END IF
		END IF
	END IF
END IF
BEGIN WORK
	CALL control_grabar()
COMMIT WORK

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
IF int_flag THEN
	ROLLBACK WORK
	CALL muestra_reg_salir()
	RETURN
END IF
CALL control_grabar()
COMMIT WORK
CALL muestra_reg()
CALL fl_mensaje_registro_modificado()
 
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
DEFINE query		VARCHAR(2000)
DEFINE expr_sql		VARCHAR(1000)
DEFINE expr_loc		VARCHAR(100)
DEFINE num_reg		INTEGER
DEFINE codloc		LIKE cxct002.z02_localidad
DEFINE codcli		LIKE cxct002.z02_codcli

LET vm_flag_mant = 'C'
CLEAR FORM
INITIALIZE codi_aux, codp_aux, codc_aux, codt1_aux, codzv_aux, codzc_aux,
	cod_aux, expr_loc TO NULL
IF num_args() = 4 THEN
	LET int_flag = 0
	CONSTRUCT BY NAME expr_sql ON z01_codcli, z01_estado, z01_nomcli,
	z01_personeria, z01_num_doc_id, z01_tipo_doc_id, z01_direccion1,
	z01_telefono1, z01_usuario,
	z01_tipo_clte, z01_direccion2, z01_telefono2, z01_fax1, z01_fax2,
	z01_casilla, z01_pais, z01_ciudad, z01_rep_legal, z01_paga_impto,
	z02_contr_espe, z02_oblig_cont, z02_email,
	z02_localidad, z02_contacto, z02_referencia, z02_credit_auto,
	z02_credit_dias, z02_cupcred_aprob, z02_cupcred_xaprob, 
	z02_dcto_item_c, z02_dcto_item_r,
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
                        CALL fl_ayuda_ciudad(codp_aux, 0)
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
                        CALL fl_ayuda_zona_cobro('T', 'T')
                                RETURNING codzc_aux, nomzc_aux
                        LET int_flag = 0
                        IF codzc_aux IS NOT NULL THEN
                                DISPLAY codzc_aux TO z02_zona_cobro
                                DISPLAY nomzc_aux TO tit_zona_cob
                        END IF
                END IF
		IF INFIELD(z02_aux_clte_mb) THEN
                        CALL fl_ayuda_cuenta_contable(vg_codcia, -1)
                                RETURNING cod_aux, nom_aux
                        LET int_flag = 0
                        IF cod_aux IS NOT NULL THEN
                                DISPLAY cod_aux TO z02_aux_clte_mb
                                DISPLAY nom_aux TO tit_cli_mb
                        END IF
                END IF
                IF INFIELD(z02_aux_clte_ma) THEN
                        CALL fl_ayuda_cuenta_contable(vg_codcia, -1)
                                RETURNING cod_aux, nom_aux
                        LET int_flag = 0
                        IF cod_aux IS NOT NULL THEN
                                DISPLAY cod_aux TO z02_aux_clte_ma
                                DISPLAY nom_aux TO tit_cli_ma
                        END IF
                END IF
		IF INFIELD(z02_aux_ant_mb) THEN
                        CALL fl_ayuda_cuenta_contable(vg_codcia, -1)
                                RETURNING cod_aux, nom_aux
                        LET int_flag = 0
                        IF cod_aux IS NOT NULL THEN
                                DISPLAY cod_aux TO z02_aux_ant_mb
                                DISPLAY nom_aux TO tit_ant_mb
                        END IF
                END IF
                IF INFIELD(z02_aux_ant_ma) THEN
                        CALL fl_ayuda_cuenta_contable(vg_codcia, -1)
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
DEFINE resul, tiene	SMALLINT
DEFINE r_z01		RECORD LIKE cxct001.*
DEFINE r_aux		RECORD LIKE cxct001.*
DEFINE r_aux2		RECORD LIKE cxct002.*
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

INITIALIZE r_pai.*, r_ciu.*, r_car.*, r_zon_vta.*, r_zon_cob.*, r_mon.*,
	codp_aux, codc_aux, codt1_aux, codzv_aux, codzc_aux, cod_aux TO NULL
DISPLAY rm_z01.z01_codcli TO tit_codigo_cli
DISPLAY rm_z01.z01_nomcli TO tit_nombre_cli
DISPLAY BY NAME rm_z01.z01_usuario, rm_z01.z01_fecing, rm_z02.z02_localidad,
		rm_z02.z02_credit_dias, rm_z02.z02_cupcred_aprob,
		rm_z02.z02_cupcred_xaprob, rm_z02.z02_dcto_item_c,
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
	rm_z01.z01_rep_legal, rm_z01.z01_paga_impto,
	rm_z02.z02_contr_espe, rm_z02.z02_oblig_cont, rm_z02.z02_email,
	rm_z02.z02_contacto,
	rm_z02.z02_referencia, rm_z02.z02_credit_auto, rm_z02.z02_credit_dias,
	rm_z02.z02_cupcred_aprob, rm_z02.z02_cupcred_xaprob, rm_z02.z02_dcto_item_c,
	rm_z02.z02_dcto_item_r,
	rm_z02.z02_dcto_mano_c, rm_z02.z02_dcto_mano_r, rm_z02.z02_cheques,
	rm_z02.z02_zona_venta, rm_z02.z02_zona_cobro, rm_z02.z02_aux_clte_mb,
	rm_z02.z02_aux_clte_ma, rm_z02.z02_aux_ant_mb, rm_z02.z02_aux_ant_ma
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
        	IF FIELD_TOUCHED(rm_z01.z01_codcli, rm_z01.z01_nomcli,
			rm_z01.z01_personeria, rm_z01.z01_num_doc_id,
			rm_z01.z01_tipo_doc_id, rm_z01.z01_direccion1,
			rm_z01.z01_telefono1, rm_z01.z01_tipo_clte,
			rm_z01.z01_direccion2, rm_z01.z01_telefono2,
			rm_z01.z01_fax1, rm_z01.z01_fax2, rm_z01.z01_casilla,
			rm_z01.z01_pais, rm_z01.z01_ciudad,rm_z01.z01_rep_legal,
			rm_z01.z01_paga_impto,
			rm_z02.z02_contr_espe, rm_z02.z02_oblig_cont,
			rm_z02.z02_email,
			rm_z02.z02_contacto,
			rm_z02.z02_referencia, rm_z02.z02_credit_auto,
			rm_z02.z02_credit_dias, rm_z02.z02_cupcred_aprob, rm_z02.z02_cupcred_xaprob,
			rm_z02.z02_dcto_item_c, rm_z02.z02_dcto_item_r,
			rm_z02.z02_dcto_mano_c, rm_z02.z02_dcto_mano_r,
			rm_z02.z02_cheques, rm_z02.z02_zona_venta,
			rm_z02.z02_zona_cobro, rm_z02.z02_aux_clte_mb,
			rm_z02.z02_aux_clte_ma, rm_z02.z02_aux_ant_mb,
			rm_z02.z02_aux_ant_ma)
        	THEN
               		LET int_flag = 0
			CALL fl_mensaje_abandonar_proceso() RETURNING resp
              		IF resp = 'Yes' THEN
				LET int_flag = 1
                       		CLEAR FORM
				EXIT INPUT
                	END IF
		ELSE
			EXIT INPUT
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
                        CALL fl_ayuda_ciudad(rm_z01.z01_pais, 0)
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
			--IF rm_g05.g05_tipo = 'UF' THEN
			IF rm_g05.g05_grupo <> 'AD' AND rm_g05.g05_grupo <> 'GE'
			   AND rm_g05.g05_grupo <> 'SI' AND vm_flag_mant = 'M'
			THEN
				CONTINUE INPUT
			END IF
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
			--IF rm_g05.g05_tipo = 'UF' THEN
			IF rm_g05.g05_grupo <> 'AD' AND rm_g05.g05_grupo <> 'GE'
			   AND rm_g05.g05_grupo <> 'SI' AND vm_flag_mant = 'M'
			THEN
				CONTINUE INPUT
			END IF
                        CALL fl_ayuda_zona_cobro('T', 'A')
                                RETURNING codzc_aux, nomzc_aux
                        LET int_flag = 0
                        IF codzc_aux IS NOT NULL THEN
				LET rm_z02.z02_zona_cobro = codzc_aux
                                DISPLAY BY NAME rm_z02.z02_zona_cobro
                                DISPLAY nomzc_aux TO tit_zona_cob
                        END IF
                END IF
		IF INFIELD(z02_aux_clte_mb) THEN
			IF rm_g05.g05_tipo = 'UF' THEN
				CONTINUE INPUT
			END IF
                        CALL fl_ayuda_cuenta_contable(vg_codcia, -1)
                                RETURNING cod_aux, nom_aux
                        LET int_flag = 0
                        IF cod_aux IS NOT NULL THEN
				LET rm_z02.z02_aux_clte_mb = cod_aux
                                DISPLAY BY NAME rm_z02.z02_aux_clte_mb
                                DISPLAY nom_aux TO tit_cli_mb
                        END IF
                END IF
                IF INFIELD(z02_aux_clte_ma) THEN
			IF rm_g05.g05_tipo = 'UF' THEN
				CONTINUE INPUT
			END IF
                        CALL fl_ayuda_cuenta_contable(vg_codcia, -1)
                                RETURNING cod_aux, nom_aux
                        LET int_flag = 0
                        IF cod_aux IS NOT NULL THEN
				LET rm_z02.z02_aux_clte_ma = cod_aux
                                DISPLAY BY NAME rm_z02.z02_aux_clte_ma
                                DISPLAY nom_aux TO tit_cli_ma
                        END IF
                END IF
		IF INFIELD(z02_aux_ant_mb) THEN
			IF rm_g05.g05_tipo = 'UF' THEN
				CONTINUE INPUT
			END IF
                        CALL fl_ayuda_cuenta_contable(vg_codcia, -1)
                                RETURNING cod_aux, nom_aux
                        LET int_flag = 0
                        IF cod_aux IS NOT NULL THEN
				LET rm_z02.z02_aux_ant_mb = cod_aux
                                DISPLAY BY NAME rm_z02.z02_aux_ant_mb
                                DISPLAY nom_aux TO tit_ant_mb
                        END IF
                END IF
                IF INFIELD(z02_aux_ant_ma) THEN
			IF rm_g05.g05_tipo = 'UF' THEN
				CONTINUE INPUT
			END IF
                        CALL fl_ayuda_cuenta_contable(vg_codcia, -1)
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
	BEFORE FIELD z01_personeria
		IF vm_flag_mant = 'M' THEN
			LET r_aux.z01_personeria = rm_z01.z01_personeria
		END IF
	BEFORE FIELD z01_tipo_doc_id
		IF rm_z01.z01_num_doc_id IS NULL THEN
			CALL fgl_winmessage(vg_producto,'Digite primero el número de identificación de documento','info')
			NEXT FIELD z01_num_doc_id
		END IF
		IF vm_flag_mant = 'M' THEN
			LET r_aux.z01_tipo_doc_id = rm_z01.z01_tipo_doc_id
		END IF
	BEFORE FIELD z01_num_doc_id
		IF vm_flag_mant = 'M' THEN
			LET r_aux.z01_num_doc_id = rm_z01.z01_num_doc_id
		END IF
	AFTER FIELD z01_personeria
		IF vm_flag_mant = 'M' THEN
			IF rm_g05.g05_tipo = 'UF' THEN
				LET rm_z01.z01_personeria = r_aux.z01_personeria
				DISPLAY BY NAME rm_z01.z01_personeria
				CONTINUE INPUT
			END IF
			--IF vg_usuario = 'FOBOS' THEN
			IF rm_g05.g05_tipo <> 'UF' AND rm_g05.g05_grupo = 'SI'
			THEN
				CONTINUE INPUT
			END IF
			CALL ver_movimiento_rept_cxc() RETURNING tiene
			IF NOT tiene AND rm_g05.g05_tipo = 'AG' THEN
				CONTINUE INPUT
			END IF
			IF FIELD_TOUCHED(z01_personeria) AND
			   rm_z01.z01_personeria <> r_aux.z01_personeria
			THEN
				CALL fl_mostrar_mensaje('Este cliente ya ha tenido movimiento, por lo tanto no puede modificar su identificación.', 'exclamation')
			END IF
			LET rm_z01.z01_personeria = r_aux.z01_personeria
			DISPLAY BY NAME rm_z01.z01_personeria
		END IF
	AFTER FIELD z01_tipo_doc_id
		IF vm_flag_mant = 'M' THEN
			IF rm_g05.g05_tipo = 'UF' THEN
				LET rm_z01.z01_tipo_doc_id=r_aux.z01_tipo_doc_id
				DISPLAY BY NAME rm_z01.z01_tipo_doc_id
				CONTINUE INPUT
			END IF
			--IF vg_usuario = 'FOBOS' THEN
			IF rm_g05.g05_tipo <> 'UF' AND rm_g05.g05_grupo = 'SI'
			THEN
				CONTINUE INPUT
			END IF
			CALL ver_movimiento_rept_cxc() RETURNING tiene
			IF NOT tiene AND rm_g05.g05_tipo = 'AG' THEN
				CONTINUE INPUT
			END IF
			IF FIELD_TOUCHED(z01_tipo_doc_id) AND
			   rm_z01.z01_tipo_doc_id <> r_aux.z01_tipo_doc_id
			THEN
				CALL fl_mostrar_mensaje('Este cliente ya ha tenido movimiento, por lo tanto no puede modificar su identificación.', 'exclamation')
			END IF
			LET rm_z01.z01_tipo_doc_id = r_aux.z01_tipo_doc_id
			DISPLAY BY NAME rm_z01.z01_tipo_doc_id
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
	AFTER FIELD z01_codcli
		IF rm_z01.z01_codcli IS NOT NULL THEN
			CALL fl_lee_cliente_general(rm_z01.z01_codcli)
				RETURNING r_z01.*
			IF r_z01.z01_codcli IS NOT NULL THEN
				CALL fl_mostrar_mensaje('Ya existe ese codigo de cliente. Pertenece al cliente: ' || r_z01.z01_codcli CLIPPED || ' ' || r_z01.z01_nomcli,'exclamation')
				NEXT FIELD z01_codcli
			END IF
		END IF
	BEFORE FIELD z01_nomcli
		IF vm_flag_mant = 'M' AND rm_g05.g05_tipo = 'UF' THEN
			LET r_aux.z01_nomcli = rm_z01.z01_nomcli
		END IF
	AFTER FIELD z01_nomcli
		IF vm_flag_mant = 'M' AND rm_g05.g05_tipo = 'UF' THEN
			LET rm_z01.z01_nomcli = r_aux.z01_nomcli
		END IF
		DISPLAY BY NAME rm_z01.z01_nomcli
		DISPLAY rm_z01.z01_nomcli TO tit_nombre_cli
	AFTER FIELD z01_num_doc_id
		IF vm_flag_mant = 'M' THEN
			IF rm_g05.g05_tipo = 'UF' THEN
				LET rm_z01.z01_num_doc_id = r_aux.z01_num_doc_id
				DISPLAY BY NAME rm_z01.z01_num_doc_id
				CONTINUE INPUT
			END IF
			--IF vg_usuario = 'FOBOS' THEN
			IF rm_g05.g05_tipo <> 'UF' AND rm_g05.g05_grupo = 'SI'
			THEN
				CONTINUE INPUT
			END IF
			LET tiene = 1
			IF rm_g05.g05_tipo = 'AG' THEN
				CALL ver_movimiento_rept_cxc() RETURNING tiene
			END IF
			IF tiene THEN
				IF FIELD_TOUCHED(z01_num_doc_id) AND
				   rm_z01.z01_num_doc_id <> r_aux.z01_num_doc_id
				THEN
					CALL fl_mostrar_mensaje('Este cliente ya ha tenido movimiento, por lo tanto no puede modificar su identificación.', 'exclamation')
				END IF
				LET rm_z01.z01_num_doc_id = r_aux.z01_num_doc_id
				DISPLAY BY NAME rm_z01.z01_num_doc_id
				CONTINUE INPUT
			END IF
		END IF
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
	BEFORE FIELD z01_paga_impto
		IF vm_flag_mant = 'M' AND rm_g05.g05_tipo = 'UF' THEN
			LET r_aux.z01_paga_impto = rm_z01.z01_paga_impto
		END IF
	AFTER FIELD z01_paga_impto
		IF rm_g05.g05_tipo = 'UF' THEN
			LET rm_z01.z01_paga_impto = 'S'
		END IF
		IF vm_flag_mant = 'M' AND rm_g05.g05_tipo = 'UF' THEN
			LET rm_z01.z01_paga_impto = r_aux.z01_paga_impto
		END IF
		DISPLAY BY NAME rm_z01.z01_paga_impto
	BEFORE FIELD z02_contr_espe
		IF vm_flag_mant = 'M' AND rm_g05.g05_tipo = 'UF' THEN
			LET r_aux2.z02_contr_espe = rm_z02.z02_contr_espe
		END IF
	AFTER FIELD z02_contr_espe
		IF rm_g05.g05_tipo = 'UF' THEN
			LET rm_z02.z02_contr_espe = 'S'
		END IF
		IF vm_flag_mant = 'M' AND rm_g05.g05_tipo = 'UF' THEN
			LET rm_z02.z02_contr_espe = r_aux2.z02_contr_espe
		END IF
		DISPLAY BY NAME rm_z02.z02_contr_espe
	BEFORE FIELD z02_oblig_cont
		IF vm_flag_mant = 'M' AND rm_g05.g05_tipo = 'UF' THEN
			LET r_aux2.z02_oblig_cont = rm_z02.z02_oblig_cont
		END IF
	AFTER FIELD z02_oblig_cont
		IF rm_g05.g05_tipo = 'UF' THEN
			LET rm_z02.z02_oblig_cont = 'S'
		END IF
		IF vm_flag_mant = 'M' AND rm_g05.g05_tipo = 'UF' THEN
			LET rm_z02.z02_oblig_cont = r_aux2.z02_oblig_cont
		END IF
		DISPLAY BY NAME rm_z02.z02_oblig_cont
	AFTER FIELD z01_tipo_clte
                IF rm_z01.z01_tipo_clte IS NOT NULL THEN
                        CALL fl_lee_subtipo_entidad('CL', rm_z01.z01_tipo_clte)
                                RETURNING r_car.*
                        IF r_car.g12_tiporeg IS NULL  THEN
                                CALL fgl_winmessage(vg_producto,'Cartera no existe','exclamation')
                                NEXT FIELD z01_tipo_clte
                        END IF
                        DISPLAY r_car.g12_nombre TO tit_tipo_cli
		ELSE
			CLEAR tit_tipo_cli
                END IF
	BEFORE FIELD z02_credit_auto
		IF vm_flag_mant = 'M' AND rm_g05.g05_tipo = 'UF' THEN
			LET r_aux2.z02_credit_auto = rm_z02.z02_credit_auto
		END IF
	AFTER FIELD z02_credit_auto
		IF rm_g05.g05_tipo = 'UF' THEN
			LET rm_z02.z02_credit_auto = 'N'
		END IF
		IF vm_flag_mant = 'M' AND rm_g05.g05_tipo = 'UF' THEN
			LET rm_z02.z02_credit_auto = r_aux2.z02_credit_auto
		END IF
		DISPLAY BY NAME rm_z02.z02_credit_auto
		CALL poner_credit_dias() RETURNING resul
	BEFORE FIELD z02_credit_dias
		IF vm_flag_mant = 'M' AND rm_g05.g05_tipo = 'UF' THEN
			LET r_aux2.z02_credit_dias = rm_z02.z02_credit_dias
		END IF
	AFTER FIELD z02_credit_dias
		IF rm_g05.g05_tipo = 'UF' THEN
			LET rm_z02.z02_credit_dias = 0
		END IF
		IF vm_flag_mant = 'M' AND rm_g05.g05_tipo = 'UF' THEN
			LET rm_z02.z02_credit_dias = r_aux2.z02_credit_dias
		END IF
		DISPLAY BY NAME rm_z02.z02_credit_dias
	BEFORE FIELD z02_cheques
		IF rm_g05.g05_tipo = 'UF' THEN
			LET r_aux2.z02_cheques = rm_z02.z02_cheques
		END IF
	AFTER FIELD z02_cheques
		IF rm_g05.g05_tipo = 'UF' THEN
			LET rm_z02.z02_cheques = r_aux2.z02_cheques
		END IF
		DISPLAY BY NAME rm_z02.z02_cheques
	BEFORE FIELD z02_zona_venta
		--IF vm_flag_mant = 'M' AND rm_g05.g05_tipo = 'UF' THEN
		IF rm_g05.g05_grupo <> 'AD' AND rm_g05.g05_grupo <> 'GE'
		   AND rm_g05.g05_grupo <> 'SI' AND vm_flag_mant = 'M'
		THEN
			LET r_aux2.z02_zona_venta = rm_z02.z02_zona_venta
		END IF
	AFTER FIELD z02_zona_venta
		--IF rm_g05.g05_tipo = 'UF' THEN
		IF rm_g05.g05_grupo <> 'AD' AND rm_g05.g05_grupo <> 'GE'
		   AND rm_g05.g05_grupo <> 'SI' AND vm_flag_mant = 'M'
		THEN
			LET rm_z02.z02_zona_venta = NULL
			IF vm_flag_mant = 'M' THEN
				LET rm_z02.z02_zona_venta =r_aux2.z02_zona_venta
			END IF
			DISPLAY BY NAME rm_z02.z02_zona_venta
			IF vm_flag_mant <> 'M' THEN
				CLEAR tit_zona_vta
			END IF
			CONTINUE INPUT
		END IF
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
	BEFORE FIELD z02_zona_cobro
		--IF vm_flag_mant = 'M' AND rm_g05.g05_tipo = 'UF' THEN
		IF rm_g05.g05_grupo <> 'AD' AND rm_g05.g05_grupo <> 'GE'
		   AND rm_g05.g05_grupo <> 'SI' AND vm_flag_mant = 'M'
		THEN
			LET r_aux2.z02_zona_cobro = rm_z02.z02_zona_cobro
		END IF
	AFTER FIELD z02_zona_cobro
		--IF rm_g05.g05_tipo = 'UF' THEN
		IF rm_g05.g05_grupo <> 'AD' AND rm_g05.g05_grupo <> 'GE'
		   AND rm_g05.g05_grupo <> 'SI' AND vm_flag_mant = 'M'
		THEN
			LET rm_z02.z02_zona_cobro = NULL
			IF vm_flag_mant = 'M' THEN
				LET rm_z02.z02_zona_cobro =r_aux2.z02_zona_cobro
			END IF
			DISPLAY BY NAME rm_z02.z02_zona_cobro
			IF vm_flag_mant <> 'M' THEN
				CLEAR tit_zona_cob
			END IF
			CONTINUE INPUT
		END IF
		IF rm_z02.z02_zona_cobro IS NOT NULL THEN
			CALL fl_lee_zona_cobro(rm_z02.z02_zona_cobro)
				RETURNING r_zon_cob.*
			IF r_zon_cob.z06_zona_cobro IS NULL THEN
				CALL fgl_winmessage(vg_producto,'Zona de venta no existe','exclamation')
				NEXT FIELD z02_zona_cobro
			END IF
			IF r_zon_cob.z06_estado = 'B' THEN
				CALL fl_mensaje_estado_bloqueado()
				NEXT FIELD z02_zona_cobro
			END IF
			DISPLAY r_zon_cob.z06_nombre TO tit_zona_cob
		ELSE
			CLEAR tit_zona_cob
		END IF
	BEFORE FIELD z02_cupcred_aprob
		IF vm_flag_mant = 'M' AND rm_g05.g05_tipo = 'UF' THEN
			LET r_aux2.z02_cupcred_aprob = rm_z02.z02_cupcred_aprob
		END IF
		CALL poner_credit_dias() RETURNING resul
	AFTER FIELD z02_cupcred_aprob
		IF rm_g05.g05_tipo = 'UF' THEN
			LET rm_z02.z02_cupcred_aprob = 0
			IF vm_flag_mant = 'M' THEN
				LET rm_z02.z02_cupcred_aprob =
							r_aux2.z02_cupcred_aprob
			END IF
			DISPLAY BY NAME rm_z02.z02_cupcred_aprob
			CONTINUE INPUT
		END IF
		IF rm_z02.z02_cupcred_aprob IS NOT NULL THEN
			IF rg_gen.g00_moneda_alt IS NOT NULL
			OR rg_gen.g00_moneda_alt <> ' ' THEN
			       CALL fl_lee_factor_moneda(rg_gen.g00_moneda_base,
				rg_gen.g00_moneda_alt)
					RETURNING r_mon.*
				CALL fl_retorna_precision_valor(
							rg_gen.g00_moneda_base,
                                                        rm_z02.z02_cupcred_aprob)
                                	RETURNING rm_z02.z02_cupcred_aprob
                                DISPLAY BY NAME rm_z02.z02_cupcred_aprob
				IF r_mon.g14_serial IS NOT NULL THEN
					LET rm_z02.z02_cupcred_xaprob = 
					rm_z02.z02_cupcred_aprob * r_mon.g14_tasa
					IF rm_z02.z02_cupcred_xaprob IS NULL 
					OR rm_z02.z02_cupcred_xaprob>9999999999.99
					THEN
						CALL fgl_winmessage(vg_producto,'El cupo de crédito en moneda base está demasiado grande', 'exclamation')
						NEXT FIELD z02_cupcred_aprob
					END IF
				END IF
				CALL fl_retorna_precision_valor(
							rg_gen.g00_moneda_base,
                                                        rm_z02.z02_cupcred_xaprob)
                                	RETURNING rm_z02.z02_cupcred_xaprob
				DISPLAY BY NAME rm_z02.z02_cupcred_xaprob
			END IF
		END IF
	BEFORE FIELD z02_aux_clte_mb
		IF vm_flag_mant = 'M' AND rm_g05.g05_tipo = 'UF' THEN
			LET r_aux2.z02_aux_clte_mb = rm_z02.z02_aux_clte_mb
		END IF
	AFTER FIELD z02_aux_clte_mb
		IF rm_g05.g05_tipo = 'UF' THEN
			LET rm_z02.z02_aux_clte_mb = NULL
			IF vm_flag_mant = 'M' THEN
				LET rm_z02.z02_aux_clte_mb =
							r_aux2.z02_aux_clte_mb
			END IF
			DISPLAY BY NAME rm_z02.z02_aux_clte_mb
			IF vm_flag_mant <> 'M' THEN
				CLEAR tit_cli_mb
			END IF
			CONTINUE INPUT
		END IF
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
	BEFORE FIELD z02_aux_clte_ma
		IF vm_flag_mant = 'M' AND rm_g05.g05_tipo = 'UF' THEN
			LET r_aux2.z02_aux_clte_ma = rm_z02.z02_aux_clte_ma
		END IF
	AFTER FIELD z02_aux_clte_ma
		IF rm_g05.g05_tipo = 'UF' THEN
			LET rm_z02.z02_aux_clte_ma = NULL
			IF vm_flag_mant = 'M' THEN
				LET rm_z02.z02_aux_clte_ma =
							r_aux2.z02_aux_clte_ma
			END IF
			DISPLAY BY NAME rm_z02.z02_aux_clte_ma
			IF vm_flag_mant <> 'M' THEN
				CLEAR tit_cli_ma
			END IF
			CONTINUE INPUT
		END IF
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
	BEFORE FIELD z02_aux_ant_mb
		IF vm_flag_mant = 'M' AND rm_g05.g05_tipo = 'UF' THEN
			LET r_aux2.z02_aux_ant_mb = rm_z02.z02_aux_ant_mb
		END IF
	AFTER FIELD z02_aux_ant_mb
		IF rm_g05.g05_tipo = 'UF' THEN
			LET rm_z02.z02_aux_ant_mb = NULL
			IF vm_flag_mant = 'M' THEN
				LET rm_z02.z02_aux_ant_mb =
							r_aux2.z02_aux_ant_mb
			END IF
			DISPLAY BY NAME rm_z02.z02_aux_ant_mb
			IF vm_flag_mant <> 'M' THEN
				CLEAR tit_ant_mb
			END IF
			CONTINUE INPUT
		END IF
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
	BEFORE FIELD z02_aux_ant_ma
		IF vm_flag_mant = 'M' AND rm_g05.g05_tipo = 'UF' THEN
			LET r_aux2.z02_aux_ant_ma = rm_z02.z02_aux_ant_ma
		END IF
	AFTER FIELD z02_aux_ant_ma
		IF rm_g05.g05_tipo = 'UF' THEN
			LET rm_z02.z02_aux_ant_ma = NULL
			IF vm_flag_mant = 'M' THEN
				LET rm_z02.z02_aux_ant_ma =
							r_aux2.z02_aux_ant_ma
			END IF
			DISPLAY BY NAME rm_z02.z02_aux_ant_ma
			IF vm_flag_mant <> 'M' THEN
				CLEAR tit_ant_ma
			END IF
			CONTINUE INPUT
		END IF
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
		IF rm_z02.z02_cupcred_xaprob <= rm_z02.z02_cupcred_aprob AND
		   rm_z02.z02_cupcred_xaprob <> 0
		THEN
			CALL fl_mostrar_mensaje('El credito por aprobar debe ser mayor al cupo de credito aprobado.', 'exclamation')
			NEXT FIELD z02_cupcred_xaprob
		END IF
END INPUT

END FUNCTION



FUNCTION validar_cedruc(codcli, cedruc)
DEFINE codcli		LIKE cxct001.z01_codcli
DEFINE cedruc		LIKE cxct001.z01_num_doc_id
DEFINE r_z01		RECORD LIKE cxct001.*
DEFINE r_g10		RECORD LIKE gent010.*
DEFINE cont		INTEGER
DEFINE resul		SMALLINT

IF rm_z01.z01_tipo_doc_id = 'C' THEN
	IF LENGTH(cedruc) <> 10 THEN
		CALL fl_mostrar_mensaje('El tipo de documento no corresponde a este número de documento.', 'exclamation')
		RETURN 0
	END IF
END IF
IF rm_z01.z01_tipo_doc_id = 'R' THEN
	IF LENGTH(cedruc) <> 13 THEN
		CALL fl_mostrar_mensaje('El tipo de documento no corresponde a este número de documento.', 'exclamation')
		RETURN 0
	END IF
END IF
INITIALIZE r_g10.* TO NULL
DECLARE q_g10 CURSOR FOR SELECT * FROM gent010 WHERE g10_codcobr = codcli
OPEN q_g10
FETCH q_g10 INTO r_g10.*
CLOSE q_g10
FREE q_g10
IF r_g10.g10_codcobr IS NOT NULL THEN
	RETURN 1
END IF
SELECT COUNT(*) INTO cont
	FROM cxct001
	WHERE z01_num_doc_id = cedruc
	  AND z01_estado     = 'A'
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
IF cont <= 1 AND resul THEN
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
	CALL fl_mostrar_mensaje('Cuenta no existe para esta compañía.','exclamation')
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
IF r_b10.b10_permite_mov = 'N' THEN
	CALL fl_mostrar_mensaje('Cuenta no permite movimiento.', 'exclamation')
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
DEFINE r_z00		RECORD LIKE cxct000.*

CALL fl_lee_compania_cobranzas(vg_codcia) RETURNING r_z00.*
IF r_z00.z00_bloq_vencido = 'S' THEN
	IF vg_codloc = 1 AND vg_codloc = 3 OR vg_codloc = 4 OR vg_codloc = 7
	THEN
		RETURN 0
	END IF
END IF
IF rm_z02.z02_credit_auto = 'N' THEN
	--LET rm_z02.z02_credit_dias = 0
	--DISPLAY BY NAME rm_z02.z02_credit_dias
ELSE
	IF rm_z02.z02_credit_dias = 0 OR rm_z02.z02_credit_dias IS NULL THEN
		RETURN 1
	END IF
END IF
RETURN 0

END FUNCTION



FUNCTION ver_movimiento_rept_cxc()
DEFINE cuantos		INTEGER

SELECT COUNT(*) INTO cuantos
	FROM rept019
	WHERE r19_compania = vg_codcia
	  AND r19_codcli   = rm_z01.z01_codcli
IF cuantos > 0 THEN
	RETURN 1
END IF
SELECT COUNT(*) INTO cuantos
	FROM talt023
	WHERE t23_compania    = vg_codcia
	  AND t23_cod_cliente = rm_z01.z01_codcli
IF cuantos > 0 THEN
	RETURN 1
END IF
SELECT COUNT(*) INTO cuantos
	FROM cxct020
	WHERE z20_compania = vg_codcia
	  AND z20_codcli   = rm_z01.z01_codcli
IF cuantos > 0 THEN
	RETURN 1
END IF
SELECT COUNT(*) INTO cuantos
	FROM cxct021
	WHERE z21_compania = vg_codcia
	  AND z21_codcli   = rm_z01.z01_codcli
IF cuantos > 0 THEN
	RETURN 1
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
		rm_z01.z01_paga_impto,
		rm_z01.z01_usuario, rm_z01.z01_fecing
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
CALL poner_SI_NO_S_N(1)
DISPLAY BY NAME rm_z02.z02_localidad, rm_z02.z02_contacto,
		rm_z02.z02_contr_espe, rm_z02.z02_oblig_cont,
		rm_z02.z02_email,
		rm_z02.z02_referencia, rm_z02.z02_credit_auto,
		rm_z02.z02_credit_dias, rm_z02.z02_cupcred_aprob,
		rm_z02.z02_cupcred_xaprob, rm_z02.z02_dcto_item_c,
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
CALL cargar_retenciones()

END FUNCTION



FUNCTION muestra_reg()

CALL mostrar_registro(vm_r_rows[vm_row_current], vm_r_cli[vm_row_current].*)
CALL muestra_contadores(vm_row_current, vm_num_rows)
CALL muestra_estado()

END FUNCTION



FUNCTION muestra_reg_salir()

LET vm_flag_mant = 'C'
CLEAR FORM
IF vm_row_current > 0 THEN
	CALL muestra_reg()
ELSE
	CALL muestra_estado()
	CLEAR z01_estado, tit_estado_cli
END IF

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



FUNCTION control_grabar()
DEFINE correo		LIKE cxct002.z02_email
DEFINE num_aux		INTEGER
DEFINE i, lim		SMALLINT

IF vm_num_ret = 0 AND vm_flag_mant <> 'I' THEN
	IF (rm_z01.z01_paga_impto = 'S' OR rm_z02.z02_contr_espe = 'S') THEN
		CALL fl_mostrar_mensaje('Debe ingresar primero las retenciones del cliente.', 'exclamation')
		RETURN
	END IF
END IF
CALL poner_SI_NO_S_N(0)
LET rm_z02.z02_email = rm_z02.z02_email CLIPPED
LET lim              = LENGTH(rm_z02.z02_email) 
LET correo           = " "
FOR i = 1 TO lim
	IF rm_z02.z02_email[i, i] = "" OR rm_z02.z02_email[i, i] = "€" OR
	   rm_z02.z02_email[i, i] = " "
	THEN
		LET correo = correo CLIPPED, ""
	ELSE
		LET correo = correo CLIPPED, rm_z02.z02_email[i, i]
	END IF
END FOR
LET rm_z02.z02_email = correo CLIPPED
IF vm_flag_mant = 'I' THEN
	LET rm_z02.z02_codcli = rm_z01.z01_codcli
	LET rm_z01.z01_fecing = CURRENT
	LET rm_z02.z02_fecing = rm_z01.z01_fecing
	INSERT INTO cxct001 VALUES (rm_z01.*)
	LET num_aux = SQLCA.SQLERRD[6] 
	INSERT INTO cxct002 VALUES (rm_z02.*)
	DELETE FROM tmp_z09
	WHILE TRUE
		CALL control_retenciones('I')
		IF NOT int_flag THEN
			EXIT WHILE
		END IF
	END WHILE
	CALL grabar_retenciones()
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
	IF vm_flag_mant = 'M' THEN
		UPDATE cxct001
			SET z01_nomcli      = rm_z01.z01_nomcli, 
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
			UPDATE cxct002
				SET z02_contacto    = rm_z02.z02_contacto,
				    z02_referencia  = rm_z02.z02_referencia,
				    z02_credit_auto = rm_z02.z02_credit_auto,
				    z02_credit_dias = rm_z02.z02_credit_dias,
				    z02_cupcred_aprob = rm_z02.z02_cupcred_aprob,
				    z02_cupcred_xaprob = rm_z02.z02_cupcred_xaprob,
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
				    z02_aux_ant_ma  = rm_z02.z02_aux_ant_ma,
				    z02_contr_espe  = rm_z02.z02_contr_espe,
				    z02_oblig_cont  = rm_z02.z02_oblig_cont,
				    z02_email       = rm_z02.z02_email
				--WHERE CURRENT OF q_up2
				WHERE z02_compania = vg_codcia
				  AND z02_codcli   = rm_z01.z01_codcli
		ELSE
			LET rm_z02.z02_compania  = vg_codcia
			LET rm_z02.z02_localidad = vg_codloc
			LET rm_z02.z02_codcli    = rm_z01.z01_codcli
			LET rm_z02.z02_fecing    = CURRENT
			INSERT INTO cxct002 VALUES (rm_z02.*)
		END IF
		LET vm_flag_mant = 'C'
	ELSE
		IF vm_flag_mant = 'C' THEN
			CALL grabar_retenciones()
			CALL fl_mensaje_registro_modificado()
			LET vm_flag_mant = 'I'
		END IF
	END IF
END IF
DELETE FROM tmp_z09
CALL poner_SI_NO_S_N(1)
 
END FUNCTION



FUNCTION bloquear_activar()
DEFINE confir		CHAR(6)

IF rm_g05.g05_tipo = 'UF' THEN
	CALL fl_mostrar_mensaje('Usted es un usuario final, por lo tanto no puede bloquear/activar códigos de clientes.', 'exclamation')
	RETURN
END IF
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
DISPLAY BY NAME rm_z01.z01_estado

END FUNCTION



FUNCTION ver_areaneg(flag)
DEFINE flag		CHAR(1)
DEFINE nuevoprog	VARCHAR(400)

LET nuevoprog = 'cd ..', vg_separador, '..', vg_separador, 'COBRANZAS',
	vg_separador, 'fuentes', vg_separador, '; fglrun cxcp106 ' , vg_base,
	' ', vg_modulo, ' ', vg_codcia, ' ', vm_r_cli[vm_row_current].codloc,
	' ', rm_z01.z01_codcli, ' ', flag
RUN nuevoprog

END FUNCTION



FUNCTION control_localidad()

CLEAR z02_localidad, tit_localidad,
	z02_contacto, z02_referencia, z02_credit_auto, z02_credit_dias,
	z02_cupcred_aprob, z02_cupcred_xaprob, z02_dcto_item_c, z02_dcto_item_r,
	z02_dcto_mano_c, z02_dcto_mano_r, z02_cheques, z02_zona_venta,
	z02_zona_cobro, tit_zona_vta, tit_zona_cob, z02_aux_clte_mb,
	z02_aux_clte_ma, z02_aux_ant_mb, z02_aux_ant_ma, tit_cli_mb, tit_cli_ma,
	tit_ant_mb, tit_ant_ma
CALL datos_defaults_z02()
CALL leer_datos_z02()
IF NOT int_flag THEN
	CALL poner_SI_NO_S_N(0)
	LET rm_z02.z02_compania = vg_codcia
	LET rm_z02.z02_codcli   = rm_z01.z01_codcli
	LET rm_z02.z02_fecing   = CURRENT
	INSERT INTO cxct002 VALUES (rm_z02.*)
	LET vm_r_cli[vm_row_current].codloc = rm_z02.z02_localidad
	LET vm_r_cli[vm_row_current].codcli = rm_z02.z02_codcli
	CALL muestra_contadores(vm_row_current, vm_num_rows)
	CALL fl_mostrar_mensaje('Cliente activiado para localidad ' || rm_z02.z02_localidad, 'info')
	CALL poner_SI_NO_S_N(1)
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
DEFINE r_aux2		RECORD LIKE cxct002.*
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
DISPLAY BY NAME rm_z02.z02_credit_dias, rm_z02.z02_cupcred_aprob,
		rm_z02.z02_cupcred_xaprob, rm_z02.z02_dcto_item_c,
		rm_z02.z02_dcto_item_r, rm_z02.z02_dcto_mano_c,
		rm_z02.z02_dcto_mano_r, rm_z02.z02_aux_clte_mb,
		rm_z02.z02_aux_clte_ma, rm_z02.z02_aux_ant_mb,
		rm_z02.z02_aux_ant_ma
LET int_flag = 0
INPUT BY NAME rm_z02.z02_localidad, rm_z02.z02_contacto, rm_z02.z02_referencia,
	rm_z02.z02_credit_auto, rm_z02.z02_credit_dias, rm_z02.z02_cupcred_aprob,
	rm_z02.z02_cupcred_xaprob,
	rm_z02.z02_dcto_item_c, rm_z02.z02_dcto_item_r, rm_z02.z02_dcto_mano_c,
	rm_z02.z02_dcto_mano_r, rm_z02.z02_cheques, rm_z02.z02_zona_venta,
	rm_z02.z02_zona_cobro, rm_z02.z02_aux_clte_mb, rm_z02.z02_aux_clte_ma,
	rm_z02.z02_aux_ant_mb, rm_z02.z02_aux_ant_ma
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
        	IF FIELD_TOUCHED(rm_z02.z02_localidad, rm_z02.z02_contacto,
			rm_z02.z02_referencia, rm_z02.z02_credit_auto,
			rm_z02.z02_credit_dias, rm_z02.z02_cupcred_aprob, rm_z02.z02_cupcred_xaprob,
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
				EXIT INPUT
                	END IF
		ELSE
			EXIT INPUT
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
			--IF rm_g05.g05_tipo = 'UF' THEN
			IF rm_g05.g05_grupo <> 'AD' AND rm_g05.g05_grupo <> 'GE'
			   AND rm_g05.g05_grupo <> 'SI' AND vm_flag_mant = 'M'
			THEN
				CONTINUE INPUT
			END IF
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
			--IF rm_g05.g05_tipo = 'UF' THEN
			IF rm_g05.g05_grupo <> 'AD' AND rm_g05.g05_grupo <> 'GE'
			   AND rm_g05.g05_grupo <> 'SI' AND vm_flag_mant = 'M'
			THEN
				CONTINUE INPUT
			END IF
                        CALL fl_ayuda_zona_cobro('T', 'A')
                                RETURNING codzc_aux, nomzc_aux
                        LET int_flag = 0
                        IF codzc_aux IS NOT NULL THEN
				LET rm_z02.z02_zona_cobro = codzc_aux
                                DISPLAY BY NAME rm_z02.z02_zona_cobro
                                DISPLAY nomzc_aux TO tit_zona_cob
                        END IF
                END IF
		IF INFIELD(z02_aux_clte_mb) THEN
			IF rm_g05.g05_tipo = 'UF' THEN
				CONTINUE INPUT
			END IF
                        CALL fl_ayuda_cuenta_contable(vg_codcia, -1)
                                RETURNING cod_aux, nom_aux
                        LET int_flag = 0
                        IF cod_aux IS NOT NULL THEN
				LET rm_z02.z02_aux_clte_mb = cod_aux
                                DISPLAY BY NAME rm_z02.z02_aux_clte_mb
                                DISPLAY nom_aux TO tit_cli_mb
                        END IF
                END IF
                IF INFIELD(z02_aux_clte_ma) THEN
			IF rm_g05.g05_tipo = 'UF' THEN
				CONTINUE INPUT
			END IF
                        CALL fl_ayuda_cuenta_contable(vg_codcia, -1)
                                RETURNING cod_aux, nom_aux
                        LET int_flag = 0
                        IF cod_aux IS NOT NULL THEN
				LET rm_z02.z02_aux_clte_ma = cod_aux
                                DISPLAY BY NAME rm_z02.z02_aux_clte_ma
                                DISPLAY nom_aux TO tit_cli_ma
                        END IF
                END IF
		IF INFIELD(z02_aux_ant_mb) THEN
			IF rm_g05.g05_tipo = 'UF' THEN
				CONTINUE INPUT
			END IF
                        CALL fl_ayuda_cuenta_contable(vg_codcia, -1)
                                RETURNING cod_aux, nom_aux
                        LET int_flag = 0
                        IF cod_aux IS NOT NULL THEN
				LET rm_z02.z02_aux_ant_mb = cod_aux
                                DISPLAY BY NAME rm_z02.z02_aux_ant_mb
                                DISPLAY nom_aux TO tit_ant_mb
                        END IF
                END IF
                IF INFIELD(z02_aux_ant_ma) THEN
			IF rm_g05.g05_tipo = 'UF' THEN
				CONTINUE INPUT
			END IF
                        CALL fl_ayuda_cuenta_contable(vg_codcia, -1)
                                RETURNING cod_aux, nom_aux
                        LET int_flag = 0
                        IF cod_aux IS NOT NULL THEN
				LET rm_z02.z02_aux_ant_ma = cod_aux
                                DISPLAY BY NAME rm_z02.z02_aux_ant_ma
                                DISPLAY nom_aux TO tit_ant_ma
                        END IF
                END IF
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
	BEFORE FIELD z02_credit_auto
		IF vm_flag_mant = 'M' AND rm_g05.g05_tipo = 'UF' THEN
			LET r_aux2.z02_credit_auto = rm_z02.z02_credit_auto
		END IF
	AFTER FIELD z02_credit_auto
		IF rm_g05.g05_tipo = 'UF' THEN
			LET rm_z02.z02_credit_auto = 'N'
		END IF
		IF vm_flag_mant = 'M' AND rm_g05.g05_tipo = 'UF' THEN
			LET rm_z02.z02_credit_auto = r_aux2.z02_credit_auto
		END IF
		DISPLAY BY NAME rm_z02.z02_credit_auto
		CALL poner_credit_dias() RETURNING resul
	BEFORE FIELD z02_credit_dias
		IF vm_flag_mant = 'M' AND rm_g05.g05_tipo = 'UF' THEN
			LET r_aux2.z02_credit_dias = rm_z02.z02_credit_dias
		END IF
	AFTER FIELD z02_credit_dias
		IF rm_g05.g05_tipo = 'UF' THEN
			LET rm_z02.z02_credit_dias = 0
		END IF
		IF vm_flag_mant = 'M' AND rm_g05.g05_tipo = 'UF' THEN
			LET rm_z02.z02_credit_dias = r_aux2.z02_credit_dias
		END IF
		DISPLAY BY NAME rm_z02.z02_credit_dias
	BEFORE FIELD z02_cheques
		IF rm_g05.g05_tipo = 'UF' THEN
			LET r_aux2.z02_cheques = rm_z02.z02_cheques
		END IF
	AFTER FIELD z02_cheques
		IF rm_g05.g05_tipo = 'UF' THEN
			LET rm_z02.z02_cheques = r_aux2.z02_cheques
		END IF
		DISPLAY BY NAME rm_z02.z02_cheques
	BEFORE FIELD z02_zona_venta
		--IF vm_flag_mant = 'M' AND rm_g05.g05_tipo = 'UF' THEN
		IF rm_g05.g05_grupo <> 'AD' AND rm_g05.g05_grupo <> 'GE'
		   AND rm_g05.g05_grupo <> 'SI' AND vm_flag_mant = 'M'
		THEN
			LET r_aux2.z02_zona_venta = rm_z02.z02_zona_venta
		END IF
	AFTER FIELD z02_zona_venta
		--IF rm_g05.g05_tipo = 'UF' THEN
		IF rm_g05.g05_grupo <> 'AD' AND rm_g05.g05_grupo <> 'GE'
		   AND rm_g05.g05_grupo <> 'SI' AND vm_flag_mant = 'M'
		THEN
			LET rm_z02.z02_zona_venta = NULL
			IF vm_flag_mant = 'M' THEN
				LET rm_z02.z02_zona_venta =r_aux2.z02_zona_venta
			END IF
			DISPLAY BY NAME rm_z02.z02_zona_venta
			IF vm_flag_mant <> 'M' THEN
				CLEAR tit_zona_vta
			END IF
			CONTINUE INPUT
		END IF
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
	BEFORE FIELD z02_zona_cobro
		--IF vm_flag_mant = 'M' AND rm_g05.g05_tipo = 'UF' THEN
		IF rm_g05.g05_grupo <> 'AD' AND rm_g05.g05_grupo <> 'GE'
		   AND rm_g05.g05_grupo <> 'SI' AND vm_flag_mant = 'M'
		THEN
			LET r_aux2.z02_zona_cobro = rm_z02.z02_zona_cobro
		END IF
	AFTER FIELD z02_zona_cobro
		--IF rm_g05.g05_tipo = 'UF' THEN
		IF rm_g05.g05_grupo <> 'AD' AND rm_g05.g05_grupo <> 'GE'
		   AND rm_g05.g05_grupo <> 'SI' AND vm_flag_mant = 'M'
		THEN
			LET rm_z02.z02_zona_cobro = NULL
			IF vm_flag_mant = 'M' THEN
				LET rm_z02.z02_zona_cobro =r_aux2.z02_zona_cobro
			END IF
			DISPLAY BY NAME rm_z02.z02_zona_cobro
			IF vm_flag_mant <> 'M' THEN
				CLEAR tit_zona_cob
			END IF
			CONTINUE INPUT
		END IF
		IF rm_z02.z02_zona_cobro IS NOT NULL THEN
			CALL fl_lee_zona_cobro(rm_z02.z02_zona_cobro)
				RETURNING r_z06.*
			IF r_z06.z06_zona_cobro IS NULL THEN
				CALL fgl_winmessage(vg_producto,'Zona de venta no existe','exclamation')
				NEXT FIELD z02_zona_cobro
			END IF
			IF r_z06.z06_estado = 'B' THEN
				CALL fl_mensaje_estado_bloqueado()
				NEXT FIELD z02_zona_cobro
			END IF
			DISPLAY r_z06.z06_nombre TO tit_zona_cob
		ELSE
			CLEAR tit_zona_cob
		END IF
	BEFORE FIELD z02_cupcred_aprob
		IF vm_flag_mant = 'M' AND rm_g05.g05_tipo = 'UF' THEN
			LET r_aux2.z02_cupcred_aprob = rm_z02.z02_cupcred_aprob
		END IF
		CALL poner_credit_dias() RETURNING resul
	AFTER FIELD z02_cupcred_aprob
		IF rm_g05.g05_tipo = 'UF' THEN
			LET rm_z02.z02_cupcred_aprob = 0
			IF vm_flag_mant = 'M' THEN
				LET rm_z02.z02_cupcred_aprob =
							r_aux2.z02_cupcred_aprob
			END IF
			DISPLAY BY NAME rm_z02.z02_cupcred_aprob
			CONTINUE INPUT
		END IF
		IF rm_z02.z02_cupcred_aprob IS NOT NULL THEN
			IF rg_gen.g00_moneda_alt IS NOT NULL
			OR rg_gen.g00_moneda_alt <> ' ' THEN
			       CALL fl_lee_factor_moneda(rg_gen.g00_moneda_base,
				rg_gen.g00_moneda_alt)
					RETURNING r_g14.*
				CALL fl_retorna_precision_valor(
							rg_gen.g00_moneda_base,
                                                        rm_z02.z02_cupcred_aprob)
                                	RETURNING rm_z02.z02_cupcred_aprob
                                DISPLAY BY NAME rm_z02.z02_cupcred_aprob
				IF r_g14.g14_serial IS NOT NULL THEN
					LET rm_z02.z02_cupcred_xaprob = 
					rm_z02.z02_cupcred_aprob * r_g14.g14_tasa
					IF rm_z02.z02_cupcred_xaprob IS NULL 
					OR rm_z02.z02_cupcred_xaprob>9999999999.99
					THEN
						CALL fgl_winmessage(vg_producto,'El cupo de crédito en moneda base está demasiado grande', 'exclamation')
						NEXT FIELD z02_cupcred_aprob
					END IF
				END IF
				CALL fl_retorna_precision_valor(
							rg_gen.g00_moneda_base,
                                                        rm_z02.z02_cupcred_xaprob)
                                	RETURNING rm_z02.z02_cupcred_xaprob
				DISPLAY BY NAME rm_z02.z02_cupcred_xaprob
			END IF
		END IF
	BEFORE FIELD z02_aux_clte_mb
		IF vm_flag_mant = 'M' AND rm_g05.g05_tipo = 'UF' THEN
			LET r_aux2.z02_aux_clte_mb = rm_z02.z02_aux_clte_mb
		END IF
	AFTER FIELD z02_aux_clte_mb
		IF rm_g05.g05_tipo = 'UF' THEN
			LET rm_z02.z02_aux_clte_mb = NULL
			IF vm_flag_mant = 'M' THEN
				LET rm_z02.z02_aux_clte_mb =
							r_aux2.z02_aux_clte_mb
			END IF
			DISPLAY BY NAME rm_z02.z02_aux_clte_mb
			IF vm_flag_mant <> 'M' THEN
				CLEAR tit_cli_mb
			END IF
			CONTINUE INPUT
		END IF
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
	BEFORE FIELD z02_aux_clte_ma
		IF vm_flag_mant = 'M' AND rm_g05.g05_tipo = 'UF' THEN
			LET r_aux2.z02_aux_clte_ma = rm_z02.z02_aux_clte_ma
		END IF
	AFTER FIELD z02_aux_clte_ma
		IF rm_g05.g05_tipo = 'UF' THEN
			LET rm_z02.z02_aux_clte_ma = NULL
			IF vm_flag_mant = 'M' THEN
				LET rm_z02.z02_aux_clte_ma =
							r_aux2.z02_aux_clte_ma
			END IF
			DISPLAY BY NAME rm_z02.z02_aux_clte_ma
			IF vm_flag_mant <> 'M' THEN
				CLEAR tit_cli_ma
			END IF
			CONTINUE INPUT
		END IF
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
	BEFORE FIELD z02_aux_ant_mb
		IF vm_flag_mant = 'M' AND rm_g05.g05_tipo = 'UF' THEN
			LET r_aux2.z02_aux_ant_mb = rm_z02.z02_aux_ant_mb
		END IF
	AFTER FIELD z02_aux_ant_mb
		IF rm_g05.g05_tipo = 'UF' THEN
			LET rm_z02.z02_aux_ant_mb = NULL
			IF vm_flag_mant = 'M' THEN
				LET rm_z02.z02_aux_ant_mb =
							r_aux2.z02_aux_ant_mb
			END IF
			DISPLAY BY NAME rm_z02.z02_aux_ant_mb
			IF vm_flag_mant <> 'M' THEN
				CLEAR tit_ant_mb
			END IF
			CONTINUE INPUT
		END IF
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
	BEFORE FIELD z02_aux_ant_ma
		IF vm_flag_mant = 'M' AND rm_g05.g05_tipo = 'UF' THEN
			LET r_aux2.z02_aux_ant_ma = rm_z02.z02_aux_ant_ma
		END IF
	AFTER FIELD z02_aux_ant_ma
		IF rm_g05.g05_tipo = 'UF' THEN
			LET rm_z02.z02_aux_ant_ma = NULL
			IF vm_flag_mant = 'M' THEN
				LET rm_z02.z02_aux_ant_ma =
							r_aux2.z02_aux_ant_ma
			END IF
			DISPLAY BY NAME rm_z02.z02_aux_ant_ma
			IF vm_flag_mant <> 'M' THEN
				CLEAR tit_ant_ma
			END IF
			CONTINUE INPUT
		END IF
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
		IF rm_z02.z02_cupcred_xaprob <= rm_z02.z02_cupcred_aprob AND
		   rm_z02.z02_cupcred_xaprob <> 0
		THEN
			CALL fl_mostrar_mensaje('El credito por aprobar debe ser mayor al cupo de credito aprobado.', 'exclamation')
			NEXT FIELD z02_cupcred_xaprob
		END IF
END INPUT

END FUNCTION



FUNCTION control_retenciones(tipo_llamada)
DEFINE tipo_llamada	CHAR(1)
DEFINE row_ini, col_ini	SMALLINT
DEFINE row_fin, col_fin	SMALLINT

LET row_ini = 07
LET row_fin = 16
LET col_ini = 02
LET col_fin = 78
IF vg_gui = 0 THEN
	LET row_ini = 05
	LET row_fin = 18
	LET col_ini = 04
	LET col_fin = 74
END IF
OPEN WINDOW w_cxcf101_2 AT row_ini, col_ini WITH row_fin ROWS, col_fin COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE 0, BORDER,
			MESSAGE LINE LAST) 
IF vg_gui = 1 THEN
	OPEN FORM f_cxcf101_2 FROM '../forms/cxcf101_2'
ELSE
	OPEN FORM f_cxcf101_2 FROM '../forms/cxcf101_2c'
END IF
DISPLAY FORM f_cxcf101_2
LET vm_num_ret = 0
CALL borrar_retenciones()
--#DISPLAY '%'		 TO tit_col1
--#DISPLAY 'T'		 TO tit_col2
--#DISPLAY 'Nombre'	 TO tit_col3
--#DISPLAY 'Cod. SRI' 	 TO tit_col4
--#DISPLAY 'Fec.Ini.Por' TO tit_col5
--#DISPLAY 'Descripcion' TO tit_col6
--#DISPLAY 'T'		 TO tit_col7
--#DISPLAY 'D'		 TO tit_col8
--#DISPLAY 'F'		 TO tit_col9
DISPLAY BY NAME rm_z01.z01_codcli, rm_z01.z01_nomcli
CASE tipo_llamada
	WHEN 'I' CALL ingreso_retenciones()
	WHEN 'C' CALL consulta_retenciones()
END CASE
IF tipo_llamada <> 'I' THEN
	LET int_flag = 0
END IF
CLOSE WINDOW w_cxcf101_2
RETURN

END FUNCTION



FUNCTION ingreso_retenciones()
DEFINE i		SMALLINT

CALL cargar_retenciones()
CALL muestra_detalle_retenciones()
CALL lee_retenciones()
IF int_flag THEN
	LET vm_num_ret = 0
END IF

END FUNCTION



FUNCTION consulta_retenciones()
DEFINE i, j		SMALLINT

CALL cargar_retenciones()
IF vm_num_ret = 0 THEN
	CALL fl_mensaje_consulta_sin_registros()
	RETURN
END IF
CALL muestra_contadores_det(1, vm_num_ret)
CALL set_count(vm_num_ret)
DISPLAY ARRAY rm_detret TO rm_detret.*
	ON KEY(INTERRUPT)
		EXIT DISPLAY
	ON KEY(F5)
		LET i = arr_curr()
		CALL control_detalle_retenciones(i, 'C')
		LET int_flag = 0
	--#BEFORE DISPLAY
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
                --#CALL dialog.keysetlabel('ACCEPT', '')
		--#CALL dialog.keysetlabel('RETURN','')
	--#BEFORE ROW
		--#LET i = arr_curr()
		--#LET j = scr_line()
		--#CALL muestra_contadores_det(i, vm_num_ret)
		--#DISPLAY rm_detret[i].c03_concepto_ret TO descripcion_sri
        --#AFTER DISPLAY
                --#CONTINUE DISPLAY
END DISPLAY

END FUNCTION



FUNCTION borrar_retenciones()
DEFINE i		SMALLINT

FOR i = 1 TO fgl_scr_size('rm_detret')
	CLEAR rm_detret[i].*
END FOR
FOR i = 1 TO vm_max_ret
	INITIALIZE rm_detret[i].* TO NULL
END FOR
CLEAR num_row, max_row, z01_codcli, z01_nomcli, descripcion_sri

END FUNCTION



FUNCTION cargar_retenciones()

DECLARE q_ret3 CURSOR FOR
	SELECT z08_porcentaje, z08_tipo_ret, c02_nombre, z08_codigo_sri,
			z08_fecha_ini_porc, c03_concepto_ret, c03_tipo_fuente,
			z08_defecto, z08_flete
		FROM cxct008, ordt003, ordt002
		WHERE z08_compania    = vg_codcia
		  AND z08_codcli      = rm_z01.z01_codcli
		  AND c03_compania    = z08_compania
		  AND c03_tipo_ret    = z08_tipo_ret
		  AND c03_porcentaje  = z08_porcentaje
		  AND c03_codigo_sri  = z08_codigo_sri
		  AND c03_fecha_ini_porc = z08_fecha_ini_porc
		  AND c02_compania    = c03_compania
		  AND c02_tipo_ret    = c03_tipo_ret
		  AND c02_porcentaje  = c03_porcentaje
		ORDER BY z08_defecto DESC, z08_tipo_ret, z08_porcentaje,
			z08_codigo_sri, z08_fecha_ini_porc DESC
LET vm_num_ret = 1
FOREACH q_ret3 INTO rm_detret[vm_num_ret].*
	DELETE FROM tmp_z09
		WHERE tipo_ret    = rm_detret[vm_num_ret].z08_tipo_ret
		  AND porc_ret    = rm_detret[vm_num_ret].z08_porcentaje
		  AND codigo_sri  = rm_detret[vm_num_ret].z08_codigo_sri
		  AND fec_ini_por = rm_detret[vm_num_ret].z08_fecha_ini_porc
	CALL cargar_det_retenciones(vm_num_ret)
	LET vm_num_ret = vm_num_ret + 1
	IF vm_num_ret > vm_max_ret THEN
		EXIT FOREACH
	END IF
END FOREACH
LET vm_num_ret = vm_num_ret - 1

END FUNCTION



FUNCTION muestra_detalle_retenciones()
DEFINE i, lim		INTEGER

LET lim = vm_num_ret
IF lim > fgl_scr_size('rm_detret') THEN
	LET lim = fgl_scr_size('rm_detret')
END IF
FOR i = 1 TO lim
	DISPLAY rm_detret[i].* TO rm_detret[i].*
END FOR

END FUNCTION



FUNCTION lee_retenciones()
DEFINE salir		SMALLINT

LET salir = 0
WHILE NOT salir
	CALL lee_detalle_ret() RETURNING salir
	IF int_flag THEN
		EXIT WHILE
	END IF
END WHILE

END FUNCTION



FUNCTION lee_detalle_ret()
DEFINE r_c02		RECORD LIKE ordt002.*
DEFINE r_c03		RECORD LIKE ordt003.*
DEFINE r_s25		RECORD LIKE srit025.*
DEFINE resp		CHAR(6)
DEFINE i, j, l, k	SMALLINT
DEFINE salir		SMALLINT
DEFINE cont_f, cont_d1	SMALLINT
DEFINE cont_d2, cont_d3	SMALLINT
DEFINE max_row, resul	SMALLINT

IF vm_num_ret <= 0 THEN
	LET vm_num_ret = 1
END IF
LET salir    = 0
LET int_flag = 0
CALL set_count(vm_num_ret)
INPUT ARRAY rm_detret WITHOUT DEFAULTS FROM rm_detret.*
	ON KEY(INTERRUPT)
		LET int_flag = 0
		CALL fl_mensaje_abandonar_proceso() RETURNING resp
		IF resp = 'Yes' THEN
			LET int_flag = 1
			EXIT INPUT
		END IF
	ON KEY(F2)
		IF INFIELD(z08_porcentaje) THEN
			CALL fl_ayuda_retenciones(vg_codcia, NULL, 'A')
				RETURNING r_c02.c02_tipo_ret,
					  r_c02.c02_porcentaje, r_c02.c02_nombre
			IF r_c02.c02_tipo_ret IS NOT NULL THEN
				LET rm_detret[i].z08_tipo_ret =
							r_c02.c02_tipo_ret
				LET rm_detret[i].z08_porcentaje =
							r_c02.c02_porcentaje
				LET rm_detret[i].c02_nombre = r_c02.c02_nombre
				DISPLAY rm_detret[i].* TO rm_detret[j].*
			END IF
		END IF
		IF INFIELD(z08_codigo_sri) THEN
			CALL fl_ayuda_codigos_sri(vg_codcia,
					rm_detret[i].z08_tipo_ret,
					rm_detret[i].z08_porcentaje, 'A',
					rm_z01.z01_codcli, 'C')
				RETURNING r_c03.c03_codigo_sri,
					  r_c03.c03_concepto_ret,
					  r_c03.c03_fecha_ini_porc
			IF r_c03.c03_codigo_sri IS NOT NULL THEN
				CALL fl_lee_codigos_sri(vg_codcia,
						rm_detret[i].z08_tipo_ret,
						rm_detret[i].z08_porcentaje,
						r_c03.c03_codigo_sri,
						r_c03.c03_fecha_ini_porc)
					RETURNING r_c03.*
				LET rm_detret[i].z08_codigo_sri =
							r_c03.c03_codigo_sri
				LET rm_detret[i].z08_fecha_ini_porc =
							r_c03.c03_fecha_ini_porc
				LET rm_detret[i].c03_concepto_ret =
							r_c03.c03_concepto_ret
				LET rm_detret[i].c03_tipo_fuente =
							r_c03.c03_tipo_fuente
				DISPLAY rm_detret[i].* TO rm_detret[j].*
				DISPLAY rm_detret[i].c03_concepto_ret TO
					descripcion_sri
			END IF
		END IF
		LET int_flag = 0
	ON KEY(F5)
		LET i = arr_curr()
		CALL control_detalle_retenciones(i, 'I')
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
		DISPLAY rm_detret[i].c03_concepto_ret TO descripcion_sri
		CALL muestra_contadores_det(i, max_row)
	BEFORE DELETE
		LET i = arr_curr()
		DELETE FROM tmp_z09
			WHERE tipo_ret    = rm_detret[i].z08_tipo_ret
			  AND porc_ret    = rm_detret[i].z08_porcentaje
			  AND codigo_sri  = rm_detret[i].z08_codigo_sri
			  AND fec_ini_por = rm_detret[i].z08_fecha_ini_porc
	BEFORE FIELD z08_porcentaje
		IF rm_detret[i].z08_porcentaje IS NOT NULL THEN
			IF rm_detret[i].z08_tipo_ret IS NULL THEN
				NEXT FIELD z08_tipo_ret
			END IF
		END IF
	BEFORE FIELD z08_codigo_sri
		IF rm_detret[i].z08_codigo_sri IS NULL THEN
			CALL fl_lee_codigo_sri_def(vg_codcia,
						rm_detret[i].z08_tipo_ret,
						rm_detret[i].z08_porcentaje,'C')
				RETURNING r_s25.*
			CALL fl_lee_codigos_sri(r_s25.s25_compania,
						r_s25.s25_tipo_ret,
						r_s25.s25_porcentaje,
						r_s25.s25_codigo_sri,
						r_s25.s25_fecha_ini_porc)
				RETURNING r_c03.*
			LET cont_d1 = 0
			LET cont_d2 = 0
			LET cont_d3 = 0
			FOR l = 1 TO vm_num_ret
				IF rm_detret[l].z08_defecto     = 'S' AND
				   rm_detret[l].c03_tipo_fuente = 'B'
				THEN
					LET cont_d1 = cont_d1 + 1
				END IF
				IF rm_detret[l].z08_defecto     = 'S' AND
				   rm_detret[l].c03_tipo_fuente = 'S'
				THEN
					LET cont_d2 = cont_d2 + 1
				END IF
				IF rm_detret[l].z08_defecto     = 'S' AND
				   rm_detret[l].c03_tipo_fuente = 'T'
				THEN
					LET cont_d3 = cont_d3 + 1
				END IF
			END FOR
			LET cont_f = 0
			FOR l = 1 TO arr_count()
				IF rm_detret[l].z08_flete = 'S' THEN
					LET cont_f = cont_f + 1
				END IF
			END FOR
			IF cont_d1 = 0 OR cont_d2 = 0 OR cont_d3 = 0 THEN
				LET rm_detret[i].z08_defecto = 'S'
			END IF
			IF cont_f = 0 THEN
				LET rm_detret[i].z08_flete = 'S'
			END IF
			LET rm_detret[i].z08_codigo_sri  = r_c03.c03_codigo_sri
			LET rm_detret[i].z08_fecha_ini_porc =
							r_c03.c03_fecha_ini_porc
			LET rm_detret[i].c03_concepto_ret=r_c03.c03_concepto_ret
			LET rm_detret[i].c03_tipo_fuente = r_c03.c03_tipo_fuente
			DISPLAY rm_detret[i].* TO rm_detret[j].*
			DISPLAY rm_detret[i].c03_concepto_ret TO descripcion_sri
		END IF
	AFTER FIELD z08_tipo_ret
		IF rm_detret[i].z08_tipo_ret IS NOT NULL THEN
			IF rm_detret[i].z08_porcentaje IS NULL THEN
				NEXT FIELD z08_porcentaje
			END IF
		END IF
		IF NOT validar_tipo_ret(i, j) THEN
			NEXT FIELD z08_porcentaje
		END IF
	AFTER FIELD z08_porcentaje, z08_tipo_ret
		IF rm_detret[i].z08_porcentaje IS NULL THEN
			CONTINUE INPUT
		END IF
		IF rm_detret[i].z08_tipo_ret IS NULL THEN
			CONTINUE INPUT
		END IF
		IF NOT validar_tipo_ret(i, j) THEN
			NEXT FIELD z08_porcentaje
		END IF
	AFTER FIELD z08_codigo_sri
		IF rm_detret[i].z08_codigo_sri IS NOT NULL THEN
			CALL fl_lee_codigos_sri(vg_codcia,
						rm_detret[i].z08_tipo_ret,
						rm_detret[i].z08_porcentaje,
						rm_detret[i].z08_codigo_sri,
						rm_detret[i].z08_fecha_ini_porc)
				RETURNING r_c03.*
			IF r_c03.c03_compania IS NULL THEN
				CALL fl_mostrar_mensaje('No existe configurado este codigo del SRI.', 'exclamation')
				NEXT FIELD z08_codigo_sri
			END IF
			IF r_c03.c03_estado <> 'A' THEN
				CALL fl_mostrar_mensaje('El codigo del SRI esta bloqueado.', 'exclamation')
				NEXT FIELD z08_codigo_sri
			END IF
			LET rm_detret[i].c03_concepto_ret =
							r_c03.c03_concepto_ret
			LET rm_detret[i].c03_tipo_fuente = r_c03.c03_tipo_fuente
			DISPLAY rm_detret[i].c03_concepto_ret TO descripcion_sri
		ELSE
			LET rm_detret[i].c03_concepto_ret = NULL
		END IF
		DISPLAY rm_detret[i].c03_concepto_ret TO
			rm_detret[j].c03_concepto_ret
		DISPLAY rm_detret[i].c03_tipo_fuente TO
			rm_detret[j].c03_tipo_fuente
	AFTER DELETE
		LET max_row = max_row - 1
		IF max_row <= 0 THEN
			LET max_row = 1
		END IF
	AFTER INPUT
		LET vm_num_ret = arr_count()
		FOR l = 1 TO vm_num_ret - 1
			FOR k = l + 1 TO vm_num_ret
				IF (rm_detret[l].z08_tipo_ret =
				    rm_detret[k].z08_tipo_ret) AND
				   (rm_detret[l].z08_porcentaje =
				    rm_detret[k].z08_porcentaje) AND
				   (rm_detret[l].z08_codigo_sri =
				    rm_detret[k].z08_codigo_sri) AND
				   (rm_detret[l].z08_fecha_ini_porc =
				    rm_detret[k].z08_fecha_ini_porc)
				THEN
					CALL fl_mostrar_mensaje('Existen un mismo tipo de porcentaje y codigo del SRI mas de una vez en el detalle.', 'exclamation')
					CONTINUE INPUT
				END IF
			END FOR
		END FOR
		LET cont_d1 = 0
		LET cont_d2 = 0
		LET cont_d3 = 0
		FOR l = 1 TO vm_num_ret
			IF rm_detret[l].z08_defecto     = 'S' AND
			   rm_detret[l].c03_tipo_fuente = 'B'
			THEN
				LET cont_d1 = cont_d1 + 1
			END IF
			IF rm_detret[l].z08_defecto     = 'S' AND
			   rm_detret[l].c03_tipo_fuente = 'S'
			THEN
				LET cont_d2 = cont_d2 + 1
			END IF
			IF rm_detret[l].z08_defecto     = 'S' AND
			   rm_detret[l].c03_tipo_fuente = 'T'
			THEN
				LET cont_d3 = cont_d3 + 1
			END IF
		END FOR
		LET cont_f = 0
		FOR l = 1 TO vm_num_ret
			IF rm_detret[l].z08_flete = 'S' THEN
				LET cont_f = cont_f + 1
			END IF
		END FOR
		IF (rm_z01.z01_paga_impto = 'S' OR rm_z02.z02_contr_espe = 'S') THEN
			IF cont_d1 = 0 OR cont_f = 0 THEN
				CALL fl_mostrar_mensaje('Debe al menos marcar un tipo de porcentaje como defecto o flete.', 'exclamation')
				CONTINUE INPUT
			END IF
		END IF
		IF cont_f > 1 THEN
			CALL fl_mostrar_mensaje('Solamente un tipo de porcentaje puede ser chequedo como tipo flete.', 'exclamation')
			CONTINUE INPUT
		END IF
		IF cont_d1 > 1 THEN
			CALL fl_mostrar_mensaje('Solamente un tipo de porcentaje puede poner por defecto para el tipo de retención Bienes.', 'exclamation')
			CONTINUE INPUT
		END IF
		IF cont_d2 > 1 THEN
			CALL fl_mostrar_mensaje('Solamente un tipo de porcentaje puede poner por defecto para el tipo de retención Servicios.', 'exclamation')
			CONTINUE INPUT
		END IF
		IF cont_d3 > 1 THEN
			CALL fl_mostrar_mensaje('Solamente un tipo de porcentaje puede poner por defecto para el tipo de retención Bienes/Servicios.', 'exclamation')
			CONTINUE INPUT
		END IF
		LET resul = 0
		FOR l = 1 TO vm_num_ret
			IF rm_detret[l].z08_codigo_sri IS NULL OR
			   rm_detret[l].z08_fecha_ini_porc IS NULL
			THEN
				LET resul = 1
				EXIT FOR
			END IF
		END FOR
		IF resul THEN
			CONTINUE INPUT
		END IF
		LET salir = 1
END INPUT
IF NOT int_flag THEN
	LET vm_flag_mant = 'C'
END IF
RETURN salir

END FUNCTION



FUNCTION validar_tipo_ret(i, j)
DEFINE i, j		SMALLINT
DEFINE r_c02		RECORD LIKE ordt002.*
DEFINE resul		SMALLINT

LET resul = 1
CALL fl_lee_tipo_retencion(vg_codcia, rm_detret[i].z08_tipo_ret,
				rm_detret[i].z08_porcentaje)
	RETURNING r_c02.*
IF r_c02.c02_compania IS NULL THEN
	CALL fl_mostrar_mensaje('No existe configurado este porcentaje de retencion.', 'exclamation')
	LET resul = 0
END IF
IF r_c02.c02_estado <> 'A' THEN
	CALL fl_mostrar_mensaje('El porcentaje de retencion esta bloqueado.', 'exclamation')
	LET resul = 0
END IF
LET rm_detret[i].z08_tipo_ret   = r_c02.c02_tipo_ret
LET rm_detret[i].z08_porcentaje = r_c02.c02_porcentaje
LET rm_detret[i].c02_nombre     = r_c02.c02_nombre
DISPLAY rm_detret[i].* TO rm_detret[j].*
RETURN resul

END FUNCTION



FUNCTION muestra_contadores_det(num_row, max_row)
DEFINE num_row, max_row	SMALLINT

DISPLAY BY NAME num_row, max_row

END FUNCTION



FUNCTION control_detalle_retenciones(posi, tipo_llamada)
DEFINE posi		SMALLINT
DEFINE tipo_llamada	CHAR(1)
DEFINE row_ini, col_ini	SMALLINT
DEFINE row_fin, col_fin	SMALLINT

LET row_ini = 06
LET row_fin = 17
LET col_ini = 04
LET col_fin = 74
IF vg_gui = 0 THEN
	LET row_ini = 05
	LET row_fin = 18
	LET col_ini = 04
	LET col_fin = 74
END IF
OPEN WINDOW w_cxcf101_3 AT row_ini, col_ini WITH row_fin ROWS, col_fin COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE 0, BORDER,
			MESSAGE LINE LAST) 
IF vg_gui = 1 THEN
	OPEN FORM f_cxcf101_3 FROM '../forms/cxcf101_3'
ELSE
	OPEN FORM f_cxcf101_3 FROM '../forms/cxcf101_3c'
END IF
DISPLAY FORM f_cxcf101_3
LET vm_num_det = 0
CALL borrar_det_retenciones()
--#DISPLAY 'Tipo'	   TO tit_col1
--#DISPLAY 'Forma Pago'	   TO tit_col2
--#DISPLAY 'Tipo Pago' 	   TO tit_col3
--#DISPLAY 'Cuenta'	   TO tit_col4
--#DISPLAY 'Nombre Cuenta' TO tit_col5
DISPLAY BY NAME rm_z01.z01_codcli, rm_z01.z01_nomcli,
		rm_detret[posi].z08_porcentaje, rm_detret[posi].z08_tipo_ret,
		rm_detret[posi].c02_nombre, rm_detret[posi].z08_codigo_sri,
		rm_detret[posi].z08_fecha_ini_porc,
		rm_detret[posi].c03_concepto_ret
CASE rm_detret[posi].c03_tipo_fuente
	WHEN 'B' DISPLAY "BIENES"    TO tipo_fuente
	WHEN 'S' DISPLAY "SERVICIOS" TO tipo_fuente
	WHEN 'T' DISPLAY "T O D O S" TO tipo_fuente
END CASE
CASE tipo_llamada
	WHEN 'I' CALL ingreso_det_retenciones(posi)
	WHEN 'C' CALL consulta_det_retenciones(posi)
END CASE
LET int_flag = 0
CLOSE WINDOW w_cxcf101_3
RETURN

END FUNCTION



FUNCTION ingreso_det_retenciones(posi)
DEFINE posi, i		SMALLINT

CALL cargar_det_retenciones(posi)
CALL muestra_detalle_det_retenciones()
CALL lee_det_retenciones()
IF int_flag THEN
	IF registros_retenciones(posi) = 0 THEN
		LET vm_num_det = 0
	END IF
ELSE
	DELETE FROM tmp_z09
		WHERE tipo_ret    = rm_detret[posi].z08_tipo_ret
		  AND porc_ret    = rm_detret[posi].z08_porcentaje
		  AND codigo_sri  = rm_detret[posi].z08_codigo_sri
		  AND fec_ini_por = rm_detret[posi].z08_fecha_ini_porc
	FOR i = 1 TO vm_num_det
		INSERT INTO tmp_z09
			VALUES(rm_detret[posi].z08_tipo_ret,
				rm_detret[posi].z08_porcentaje,
				rm_detret[posi].z08_codigo_sri,
				rm_detret[posi].z08_fecha_ini_porc,
				rm_detz09[i].*)
	END FOR
END IF

END FUNCTION



FUNCTION consulta_det_retenciones(posi)
DEFINE posi		SMALLINT
DEFINE i, j		SMALLINT

CALL cargar_det_retenciones(posi)
IF vm_num_det = 0 THEN
	CALL fl_mensaje_consulta_sin_registros()
	RETURN
END IF
CALL muestra_contadores_det(1, vm_num_det)
CALL set_count(vm_num_det)
DISPLAY ARRAY rm_detz09 TO rm_detz09.*
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
		--#CALL muestra_contadores_det(i, vm_num_det)
        --#AFTER DISPLAY
                --#CONTINUE DISPLAY
END DISPLAY

END FUNCTION



FUNCTION borrar_det_retenciones()
DEFINE i		SMALLINT

FOR i = 1 TO fgl_scr_size('rm_detz09')
	CLEAR rm_detz09[i].*
END FOR
FOR i = 1 TO vm_max_det
	INITIALIZE rm_detz09[i].* TO NULL
END FOR
CLEAR num_row, max_row, z01_codcli, z01_nomcli, z08_porcentaje, z08_tipo_ret,
	c02_nombre, z08_codigo_sri, z08_fecha_ini_porc, c03_concepto_ret

END FUNCTION



FUNCTION cargar_det_retenciones(posi)
DEFINE posi		SMALLINT
DEFINE query		CHAR(1000)
DEFINE r_z09		RECORD LIKE cxct009.*
DEFINE insertar		SMALLINT

LET insertar = 0
IF registros_retenciones(posi) = 0 THEN
	LET query = 'SELECT z09_tipo_ret, z09_porcentaje, z09_codigo_sri,',
			'z09_fecha_ini_porc, z09_codigo_pago, j01_nombre,',
			' z09_cont_cred,',
			' CASE WHEN z09_cont_cred = "C"',
				' THEN "CONTADO" ',
				' ELSE "CREDITO" ',
			' END tit_cont_cred, z09_aux_cont, b10_descripcion',
			' FROM cxct009, cajt001, OUTER ctbt010',
			' WHERE z09_compania    = ', vg_codcia,
			'   AND z09_codcli      = ', rm_z01.z01_codcli,
			'   AND z09_tipo_ret    = "',
					rm_detret[posi].z08_tipo_ret, '"',
			'   AND z09_porcentaje  = ',
					rm_detret[posi].z08_porcentaje,
			'   AND z09_codigo_sri  = "',
					rm_detret[posi].z08_codigo_sri,'"',
			'   AND z09_fecha_ini_porc = "',
					rm_detret[posi].z08_fecha_ini_porc,'"',
			'   AND j01_compania    = z09_compania ',
			'   AND j01_codigo_pago = z09_codigo_pago ',
			'   AND j01_cont_cred   = z09_cont_cred ',
			'   AND b10_compania    = z09_compania ',
			'   AND b10_cuenta      = z09_aux_cont ',
			' ORDER BY z09_cont_cred, z09_codigo_pago '
	LET insertar = 1
ELSE
	LET query = 'SELECT tipo_ret, porc_ret, codigo_sri, fec_ini_por,',
			' cod_pago, nom_pago, cont_cred, tit_cont_cred,',
			' aux_cont, nom_cuenta',
			' FROM tmp_z09 ',
			' WHERE tipo_ret   = "', rm_detret[posi].z08_tipo_ret,
						'"',
			'   AND porc_ret   = ', rm_detret[posi].z08_porcentaje,
			'   AND codigo_sri = "', rm_detret[posi].z08_codigo_sri,
						'"',
			'   AND fec_ini_por = "',
					rm_detret[posi].z08_fecha_ini_porc, '"'
END IF
PREPARE cons_ret4 FROM query
DECLARE q_ret4 CURSOR FOR cons_ret4
LET vm_num_det = 1
FOREACH q_ret4 INTO r_z09.z09_tipo_ret, r_z09.z09_porcentaje,
			r_z09.z09_codigo_sri, r_z09.z09_fecha_ini_porc,
			rm_detz09[vm_num_det].*
	IF insertar THEN
		INSERT INTO tmp_z09
			VALUES(r_z09.z09_tipo_ret, r_z09.z09_porcentaje,
				r_z09.z09_codigo_sri, r_z09.z09_fecha_ini_porc,
				rm_detz09[vm_num_det].*)
	END IF
	LET vm_num_det = vm_num_det + 1
	IF vm_num_det > vm_max_det THEN
		EXIT FOREACH
	END IF
END FOREACH
LET vm_num_det = vm_num_det - 1

END FUNCTION



FUNCTION muestra_detalle_det_retenciones()
DEFINE i, lim		INTEGER

LET lim = vm_num_det
IF lim > fgl_scr_size('rm_detz09') THEN
	LET lim = fgl_scr_size('rm_detz09')
END IF
FOR i = 1 TO lim
	DISPLAY rm_detz09[i].* TO rm_detz09[i].*
END FOR

END FUNCTION



FUNCTION lee_det_retenciones()
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

IF vm_num_det <= 0 THEN
	LET vm_num_det = 1
END IF
LET salir    = 0
LET int_flag = 0
CALL set_count(vm_num_det)
INPUT ARRAY rm_detz09 WITHOUT DEFAULTS FROM rm_detz09.*
	ON KEY(INTERRUPT)
		LET int_flag = 0
		CALL fl_mensaje_abandonar_proceso() RETURNING resp
		IF resp = 'Yes' THEN
			LET int_flag = 1
			EXIT INPUT
		END IF
	ON KEY(F2)
		IF INFIELD(z09_codigo_pago) THEN
			CALL fl_ayuda_forma_pago(vg_codcia, 'T', 'A', 'S') 
				RETURNING r_j01.j01_codigo_pago,
					  r_j01.j01_nombre,
					  r_j01.j01_cont_cred
			IF r_j01.j01_codigo_pago IS NOT NULL THEN
				LET rm_detz09[i].z09_codigo_pago =
							r_j01.j01_codigo_pago
				LET rm_detz09[i].z09_cont_cred =
							r_j01.j01_cont_cred
				LET rm_detz09[i].j01_nombre = r_j01.j01_nombre
				CALL ret_cont_cred(rm_detz09[i].z09_cont_cred)
					RETURNING rm_detz09[i].tit_cont_cred
				DISPLAY rm_detz09[i].* TO rm_detz09[j].*
			END IF
		END IF
		IF INFIELD(z09_aux_cont) THEN
			CALL fl_ayuda_cuenta_contable(vg_codcia, -1)
				RETURNING r_b10.b10_cuenta,r_b10.b10_descripcion
			IF r_b10.b10_cuenta IS NOT NULL THEN
				LET rm_detz09[i].z09_aux_cont = r_b10.b10_cuenta
				LET rm_detz09[i].b10_descripcion =
							r_b10.b10_descripcion
				DISPLAY rm_detz09[i].* TO rm_detz09[j].*
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
	BEFORE FIELD z09_cont_cred
		LET cont_cred = rm_detz09[i].z09_cont_cred
	AFTER FIELD z09_codigo_pago
		IF rm_detz09[i].z09_cont_cred IS NULL THEN
			CONTINUE INPUT
		END IF
		IF rm_detz09[i].z09_codigo_pago IS NOT NULL THEN
			CALL fl_lee_tipo_pago_caja(vg_codcia,
						rm_detz09[i].z09_codigo_pago,
						rm_detz09[i].z09_cont_cred)
				RETURNING r_j01.*
			IF r_j01.j01_codigo_pago IS NULL THEN
				CALL fl_mostrar_mensaje('Codigo de pago no existe.', 'exclamation')
				NEXT FIELD z09_codigo_pago
			END IF
			IF r_j01.j01_estado <> 'A' THEN
				CALL fl_mensaje_estado_bloqueado()
				NEXT FIELD z09_codigo_pago
			END IF
			LET rm_detz09[i].j01_nombre = r_j01.j01_nombre
			CALL ret_cont_cred(rm_detz09[i].z09_cont_cred)
				RETURNING rm_detz09[i].tit_cont_cred
			IF NOT fl_determinar_si_es_retencion(vg_codcia,
						rm_detz09[i].z09_codigo_pago,
						rm_detz09[i].z09_cont_cred)
			THEN
				CALL fl_mostrar_mensaje('Este codigo de pago no es de tipo retencion.', 'exclamation')
				CONTINUE INPUT
			END IF
		ELSE
			LET rm_detz09[i].j01_nombre    = NULL
			LET rm_detz09[i].tit_cont_cred = NULL
		END IF
		DISPLAY rm_detz09[i].* TO rm_detz09[j].*
	AFTER FIELD z09_cont_cred
		IF rm_detz09[i].z09_codigo_pago IS NULL THEN
			CONTINUE INPUT
		END IF
		IF rm_detz09[i].z09_cont_cred IS NULL THEN
			LET rm_detz09[i].z09_cont_cred = cont_cred
		END IF
		CALL fl_lee_tipo_pago_caja(vg_codcia,
						rm_detz09[i].z09_codigo_pago,
						rm_detz09[i].z09_cont_cred)
			RETURNING r_j01.*
		LET rm_detz09[i].j01_nombre = r_j01.j01_nombre
		CALL ret_cont_cred(rm_detz09[i].z09_cont_cred)
			RETURNING rm_detz09[i].tit_cont_cred
		DISPLAY rm_detz09[i].* TO rm_detz09[j].*
	AFTER FIELD z09_aux_cont
                IF rm_detz09[i].z09_aux_cont IS NOT NULL THEN
			IF validar_cuenta(rm_detz09[i].z09_aux_cont, 5) = 1 THEN
				NEXT FIELD z09_aux_cont
			END IF
			CALL fl_lee_cuenta(vg_codcia, rm_detz09[i].z09_aux_cont)
				RETURNING r_b10.*
			LET rm_detz09[i].b10_descripcion = r_b10.b10_descripcion
		ELSE
			LET rm_detz09[i].b10_descripcion = NULL
                END IF
		DISPLAY rm_detz09[i].b10_descripcion TO
			rm_detz09[j].b10_descripcion
	AFTER DELETE
		LET max_row = max_row - 1
		IF max_row <= 0 THEN
			LET max_row = 1
		END IF
	AFTER INPUT
		LET vm_num_det = arr_count()
		FOR l = 1 TO vm_num_det - 1
			FOR k = l + 1 TO vm_num_det
				IF (rm_detz09[l].z09_codigo_pago =
				    rm_detz09[k].z09_codigo_pago) AND
				   (rm_detz09[l].z09_cont_cred =
				    rm_detz09[k].z09_cont_cred)
				THEN
					CALL fl_mostrar_mensaje('Existen un mismo tipo de porcentaje y tipo de pago mas de una vez en el detalle.', 'exclamation')
					CONTINUE INPUT
				END IF
			END FOR
		END FOR
		FOR l = 1 TO vm_num_det
			IF NOT fl_determinar_si_es_retencion(vg_codcia,
						rm_detz09[l].z09_codigo_pago,
						rm_detz09[l].z09_cont_cred)
			THEN
				CALL fl_mostrar_mensaje('Existe un codigo de pago que no es del tipo retencion.', 'exclamation')
				CONTINUE INPUT
			END IF
		END FOR
		LET salir = 1
END INPUT
RETURN salir

END FUNCTION



FUNCTION grabar_retenciones()
DEFINE query		CHAR(800)
DEFINE i		SMALLINT

DELETE FROM cxct009
	WHERE z09_compania = vg_codcia
	  AND z09_codcli   = rm_z01.z01_codcli
DELETE FROM cxct008
	WHERE z08_compania = vg_codcia
	  AND z08_codcli   = rm_z01.z01_codcli
FOR i = 1 TO vm_num_ret
	IF rm_detret[i].z08_defecto IS NULL THEN
		LET rm_detret[i].z08_defecto = 'N'
	END IF
	IF rm_detret[i].z08_flete IS NULL THEN
		LET rm_detret[i].z08_flete = 'N'
	END IF
	INSERT INTO cxct008
		VALUES(vg_codcia, rm_z01.z01_codcli, rm_detret[i].z08_tipo_ret,
			rm_detret[i].z08_porcentaje,rm_detret[i].z08_codigo_sri,
			rm_detret[i].z08_fecha_ini_porc,
			rm_detret[i].z08_defecto, rm_detret[i].z08_flete,
			vg_usuario, CURRENT)
	LET query = 'INSERT INTO cxct009 ',
			'SELECT ', vg_codcia, ', ', rm_z01.z01_codcli, ', ',
				'tipo_ret, porc_ret, codigo_sri, fec_ini_por, ',
				'cod_pago, cont_cred, aux_cont, "', vg_usuario,
				'", CURRENT ',
			' FROM tmp_z09 ',
			' WHERE tipo_ret   = "', rm_detret[i].z08_tipo_ret, '"',
			'   AND porc_ret   = ',	rm_detret[i].z08_porcentaje,
			'   AND codigo_sri = ',	rm_detret[i].z08_codigo_sri,
			'   AND fec_ini_por = "',
					rm_detret[i].z08_fecha_ini_porc, '"'
	PREPARE exec_z09 FROM query
	EXECUTE exec_z09
END FOR
 
END FUNCTION



FUNCTION registros_retenciones(posi)
DEFINE posi		SMALLINT
DEFINE cuantos		INTEGER

SELECT COUNT(*) INTO cuantos
	FROM tmp_z09
	WHERE tipo_ret    = rm_detret[posi].z08_tipo_ret
	  AND porc_ret    = rm_detret[posi].z08_porcentaje
	  AND codigo_sri  = rm_detret[posi].z08_codigo_sri
	  AND fec_ini_por = rm_detret[posi].z08_fecha_ini_porc
RETURN cuantos

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



FUNCTION poner_SI_NO_S_N(flag)
DEFINE flag		SMALLINT

CASE flag
	WHEN 0  IF rm_z02.z02_contr_espe = "S" THEN
			LET rm_z02.z02_contr_espe = "SI"
		END IF
		IF rm_z02.z02_oblig_cont = "S" THEN
			LET rm_z02.z02_oblig_cont = "SI"
		END IF
		IF rm_z02.z02_contr_espe = "N" THEN
			LET rm_z02.z02_contr_espe = "NO"
		END IF
		IF rm_z02.z02_oblig_cont = "N" THEN
			LET rm_z02.z02_oblig_cont = "NO"
		END IF
	WHEN 1  IF rm_z02.z02_contr_espe = "SI" THEN
			LET rm_z02.z02_contr_espe = "S"
		END IF
		IF rm_z02.z02_oblig_cont = "SI" THEN
			LET rm_z02.z02_oblig_cont = "S"
		END IF
		IF rm_z02.z02_contr_espe = "NO" THEN
			LET rm_z02.z02_contr_espe = "N"
		END IF
		IF rm_z02.z02_oblig_cont = "NO" THEN
			LET rm_z02.z02_oblig_cont = "N"
		END IF
END CASE

END FUNCTION
