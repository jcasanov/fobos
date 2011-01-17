------------------------------------------------------------------------------
-- Titulo           : cxcp101.4gl - Mantenimiento de Clientes 
-- Elaboracion      : 04-oct-2001
-- Autor            : NPC
-- Formato Ejecucion: fglrun cxcp101 base módulo compañía localidad [cliente]
-- Ultima Correccion: 
-- Motivo Correccion: 
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE rm_cxc		RECORD LIKE cxct001.*
DEFINE rm_cxc2		RECORD LIKE cxct002.*
DEFINE vm_num_rows	SMALLINT
DEFINE vm_row_current	SMALLINT
DEFINE vm_max_rows	SMALLINT
DEFINE vm_r_rows	ARRAY [1000] OF INTEGER


DEFINE r_ctas ARRAY [10] OF  RECORD 
	b100_localidad			LIKE ctbt100.b100_localidad,
	n_localidad				VARCHAR(30),
	b100_modulo				LIKE ctbt100.b100_modulo,
	b100_grupo_linea		LIKE ctbt100.b100_grupo_linea,
	b100_cxc_mb				LIKE ctbt100.b100_cxc_mb,
	b100_ant_mb				LIKE ctbt100.b100_ant_mb
END RECORD
DEFINE vm_max_ctas			SMALLINT
DEFINE vm_ind_ctas			SMALLINT



MAIN

DEFER QUIT 
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/cxcp101.error')
CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 AND num_args() <> 5 THEN   -- Validar # parámetros correcto
	CALL fgl_winmessage(vg_producto, 'Número de parámetros incorrecto', 'stop')
	EXIT PROGRAM
END IF
LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_codcia   = arg_val(3)
LET vg_codloc   = arg_val(4)
LET vg_proceso = 'cxcp101'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL control_master()

END MAIN



FUNCTION control_master()
DEFINE flag		CHAR(1)

CALL fl_nivel_isolation()
LET vm_max_rows	= 1000
LET vm_max_ctas = 10
OPEN WINDOW wf AT 3,2 WITH 21 ROWS, 80 COLUMNS
    ATTRIBUTE(FORM LINE FIRST + 2, COMMENT LINE LAST, MENU LINE FIRST,BORDER,
	      MESSAGE LINE LAST - 2)
OPTIONS INPUT WRAP,
	ACCEPT KEY	F12
OPEN FORM f_cxc FROM "../forms/cxcf101_1"
DISPLAY FORM f_cxc
INITIALIZE rm_cxc.*, rm_cxc2.* TO NULL
LET vm_num_rows    = 0
LET vm_row_current = 0
CALL muestra_contadores(vm_row_current, vm_num_rows)
MENU 'OPCIONES'
	BEFORE MENU
		HIDE OPTION 'Avanzar'
		HIDE OPTION 'Retroceder'
		HIDE OPTION 'Modificar'
		HIDE OPTION 'Contabilidad'
		HIDE OPTION 'Bloquear/Activar'
		HIDE OPTION 'Area de Negocio'
		IF num_args() = 5 THEN
			HIDE OPTION 'Ingresar'
			HIDE OPTION 'Consultar'
			CALL control_consulta()
			IF vm_num_rows = 0 THEN
				EXIT PROGRAM
			END IF
			SHOW OPTION 'Area de Negocio'
		END IF
	COMMAND KEY('I') 'Ingresar' 'Ingresar nuevos registros. '
		CALL control_ingreso()
		IF vm_num_rows = 1 THEN
		   IF fl_control_permiso_opcion('Modificar') THEN			
			SHOW OPTION 'Modificar'
		   END IF 
		   IF fl_control_permiso_opcion('Bloquear') THEN
			SHOW OPTION 'Bloquear/Activar'
		   END IF			
			
			SHOW OPTION 'Contabilidad'		
			SHOW OPTION 'Area de Negocio'
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
			
		   IF fl_control_permiso_opcion('Modificar') THEN			
			SHOW OPTION 'Modificar'
		   END IF 
		   IF fl_control_permiso_opcion('Bloquear') THEN
			SHOW OPTION 'Bloquear/Activar'
		   END IF
		
			SHOW OPTION 'Contabilidad'
			SHOW OPTION 'Area de Negocio'
			HIDE OPTION 'Avanzar'
			HIDE OPTION 'Retroceder'
			IF vm_num_rows = 0 THEN
				HIDE OPTION 'Modificar'
				HIDE OPTION 'Contabilidad'
				HIDE OPTION 'Bloquear/Activar'
				HIDE OPTION 'Area de Negocio'
			END IF
		ELSE
		   IF fl_control_permiso_opcion('Modificar') THEN			
			SHOW OPTION 'Modificar'
		   END IF 
		   IF fl_control_permiso_opcion('Bloquear') THEN
			SHOW OPTION 'Bloquear/Activar'
		   END IF
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Contabilidad'
			SHOW OPTION 'Area de Negocio'
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
	COMMAND KEY('T') 'Contabilidad' 'Agrega o modifica cuentas contables'
		CALL control_cuentas_contables()
	COMMAND KEY('N') 'Area de Negocio' 'Areas negocio de una Cia./Local. '
		LET flag = 'X'
		IF num_args() = 5 THEN
			LET flag = 'O'
		END IF
		CALL ver_areaneg(flag)
	COMMAND KEY('S') 'Salir' 'Salir del programa. '
		EXIT MENU
END MENU

END FUNCTION



FUNCTION control_ingreso()
DEFINE num_aux		INTEGER
DEFINE r_cia		RECORD LIKE cxct000.*
DEFINE r_cta		RECORD LIKE ctbt010.*

LET num_aux = 0 
CALL fl_retorna_usuario()
INITIALIZE rm_cxc.*, rm_cxc2.*, r_cia.*, r_cta.* TO NULL
CLEAR z02_cupocred_ma, tit_codigo_cli, tit_nombre_cli, tit_est, tit_estado_cli,
	tit_pais, tit_ciudad, tit_tipo_cli, tit_zona_vta, tit_zona_cob,
	tit_cli_mb, tit_cli_ma, tit_ant_mb, tit_ant_ma, z01_codcli
CALL fl_lee_compania_cobranzas(vg_codcia) RETURNING r_cia.*
IF r_cia.z00_estado = 'A' THEN
	LET rm_cxc2.z02_aux_clte_mb = r_cia.z00_aux_clte_mb
	CALL fl_lee_cuenta(vg_codcia,r_cia.z00_aux_clte_mb) RETURNING r_cta.*
	DISPLAY r_cta.b10_descripcion TO tit_cli_mb
	LET rm_cxc2.z02_aux_clte_ma = r_cia.z00_aux_clte_ma
	CALL fl_lee_cuenta(vg_codcia,r_cia.z00_aux_clte_ma) RETURNING r_cta.*
	DISPLAY r_cta.b10_descripcion TO tit_cli_ma
	LET rm_cxc2.z02_aux_ant_mb  = r_cia.z00_aux_ant_mb
	CALL fl_lee_cuenta(vg_codcia,r_cia.z00_aux_ant_mb) RETURNING r_cta.*
	DISPLAY r_cta.b10_descripcion TO tit_ant_mb
	LET rm_cxc2.z02_aux_ant_ma  = r_cia.z00_aux_ant_ma
	CALL fl_lee_cuenta(vg_codcia,r_cia.z00_aux_ant_ma) RETURNING r_cta.*
	DISPLAY r_cta.b10_descripcion TO tit_ant_ma
END IF

LET rm_cxc.z01_personeria   = 'N'
LET rm_cxc.z01_tipo_doc_id  = 'C'
LET rm_cxc.z01_paga_impto   = 'S'
LET rm_cxc.z01_estado       = 'A'
LET rm_cxc.z01_usuario      = vg_usuario
LET rm_cxc.z01_fecing       = CURRENT

LET rm_cxc2.z02_compania    = vg_codcia
LET rm_cxc2.z02_localidad   = vg_codloc
LET rm_cxc2.z02_credit_auto = r_cia.z00_credit_auto
LET rm_cxc2.z02_cheques     = 'S'
LET rm_cxc2.z02_credit_dias = r_cia.z00_credit_dias
LET rm_cxc2.z02_cupocred_mb = 0
LET rm_cxc2.z02_cupocred_ma = 0
LET rm_cxc2.z02_dcto_item_c = 0
LET rm_cxc2.z02_dcto_item_r = 0
LET rm_cxc2.z02_dcto_mano_c = 0
LET rm_cxc2.z02_dcto_mano_r = 0
LET rm_cxc2.z02_usuario     = rm_cxc.z01_usuario
LET rm_cxc2.z02_fecing      = rm_cxc.z01_fecing

CALL muestra_estado()
CALL leer_datos()
IF NOT int_flag THEN
	LET rm_cxc.z01_fecing  = CURRENT
	LET rm_cxc2.z02_fecing = rm_cxc.z01_fecing
	SELECT MAX(z01_codcli) INTO rm_cxc.z01_codcli FROM cxct001
	IF rm_cxc.z01_codcli IS NOT NULL THEN
		LET rm_cxc.z01_codcli = rm_cxc.z01_codcli + 1
	ELSE
		LET rm_cxc.z01_codcli = 1
	END IF
	LET rm_cxc2.z02_codcli = rm_cxc.z01_codcli
	BEGIN WORK
		INSERT INTO cxct001 VALUES (rm_cxc.*)
		LET num_aux = SQLCA.SQLERRD[6] 
		INSERT INTO cxct002 VALUES (rm_cxc2.*)
	COMMIT WORK
	IF vm_num_rows = vm_max_rows THEN
		LET vm_num_rows = 1
	ELSE
		LET vm_num_rows = vm_num_rows + 1
	END IF
	LET vm_row_current = vm_num_rows
	LET vm_r_rows[vm_row_current] = num_aux
	DISPLAY rm_cxc.z01_codcli TO tit_codigo_cli
	DISPLAY rm_cxc.z01_nomcli TO tit_nombre_cli
	DISPLAY BY NAME rm_cxc.z01_codcli, rm_cxc.z01_fecing
	CALL muestra_contadores(vm_row_current, vm_num_rows)
	CALL mostrar_registro(vm_r_rows[vm_num_rows])	
	CALL fl_mensaje_registro_ingresado()
ELSE
	CLEAR FORM
	IF vm_row_current > 0 THEN
		CALL mostrar_registro(vm_r_rows[vm_row_current])
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
IF rm_cxc.z01_estado = 'B' THEN
	CALL fl_mensaje_estado_bloqueado()
	RETURN
END IF
CALL mostrar_registro(vm_r_rows[vm_row_current])
BEGIN WORK
WHENEVER ERROR CONTINUE
DECLARE q_up CURSOR FOR SELECT * FROM cxct001
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
DECLARE q_up2 CURSOR FOR SELECT * FROM cxct002
	WHERE z02_compania  = rm_cxc2.z02_compania 
	  AND z02_localidad = rm_cxc2.z02_localidad
	  AND z02_codcli    = rm_cxc.z01_codcli
	FOR UPDATE
OPEN q_up2
FETCH q_up2 INTO rm_cxc2.*
IF STATUS < 0 THEN
	COMMIT WORK
	CALL fl_mensaje_bloqueo_otro_usuario()
	WHENEVER ERROR STOP
	RETURN
END IF
IF rm_cxc2.z02_codcli IS NULL THEN
	LET rm_cxc2.z02_credit_auto = 'S'
	LET rm_cxc2.z02_cheques     = 'S'
	LET rm_cxc2.z02_usuario     = rm_cxc.z01_usuario
	LET rm_cxc2.z02_fecing      = CURRENT
END IF
WHENEVER ERROR STOP
CALL leer_datos()
IF NOT int_flag THEN
	UPDATE cxct001 SET z01_nomcli      = rm_cxc.z01_nomcli, 
			   z01_personeria  = rm_cxc.z01_personeria,
			   z01_num_doc_id  = rm_cxc.z01_num_doc_id,
			   z01_tipo_doc_id = rm_cxc.z01_tipo_doc_id,
			   z01_direccion1  = rm_cxc.z01_direccion1, 
			   z01_telefono1   = rm_cxc.z01_telefono1, 
			   z01_tipo_clte   = rm_cxc.z01_tipo_clte,
			   z01_direccion2  = rm_cxc.z01_direccion2, 
			   z01_telefono2   = rm_cxc.z01_telefono2,
			   z01_fax1        = rm_cxc.z01_fax1,
			   z01_fax2        = rm_cxc.z01_fax2,
			   z01_casilla     = rm_cxc.z01_casilla,
			   z01_pais        = rm_cxc.z01_pais,
			   z01_ciudad      = rm_cxc.z01_ciudad,
			   z01_rep_legal   = rm_cxc.z01_rep_legal,
			   z01_paga_impto  = rm_cxc.z01_paga_impto
			WHERE CURRENT OF q_up
	IF rm_cxc2.z02_codcli IS NOT NULL THEN
		UPDATE cxct002 SET z02_contacto    = rm_cxc2.z02_contacto,
				   z02_referencia  = rm_cxc2.z02_referencia,
				   z02_credit_auto = rm_cxc2.z02_credit_auto,
				   z02_credit_dias = rm_cxc2.z02_credit_dias,
				   z02_cupocred_mb = rm_cxc2.z02_cupocred_mb,
				   z02_dcto_item_c = rm_cxc2.z02_dcto_item_c,
				   z02_dcto_item_r = rm_cxc2.z02_dcto_item_r,
				   z02_dcto_mano_c = rm_cxc2.z02_dcto_mano_c,
				   z02_dcto_mano_r = rm_cxc2.z02_dcto_mano_r,
				   z02_cheques     = rm_cxc2.z02_cheques,
				   z02_zona_venta  = rm_cxc2.z02_zona_venta,
				   z02_zona_cobro  = rm_cxc2.z02_zona_cobro,
				   z02_aux_clte_mb = rm_cxc2.z02_aux_clte_mb,
				   z02_aux_clte_ma = rm_cxc2.z02_aux_clte_ma,
				   z02_aux_ant_mb  = rm_cxc2.z02_aux_ant_mb,
				   z02_aux_ant_ma  = rm_cxc2.z02_aux_ant_ma
			WHERE CURRENT OF q_up2
	ELSE
		LET rm_cxc2.z02_compania  = vg_codcia
		LET rm_cxc2.z02_localidad = vg_codloc
		LET rm_cxc2.z02_codcli    = rm_cxc.z01_codcli
		INSERT INTO cxct002 VALUES (rm_cxc2.*)
	END IF
	COMMIT WORK
	CALL muestra_contadores(vm_row_current, vm_num_rows)
	CALL fl_mensaje_registro_modificado()
ELSE
	COMMIT WORK
	CLEAR FORM
	IF vm_row_current > 0 THEN
		CALL mostrar_registro(vm_r_rows[vm_row_current])
	END IF
END IF
WHENEVER ERROR STOP
 
END FUNCTION



FUNCTION control_consulta()
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
DEFINE num_reg		INTEGER

CLEAR FORM
INITIALIZE codi_aux, codp_aux, codc_aux, codt1_aux, codzv_aux, codzc_aux,
	cod_aux TO NULL
LET int_flag = 0
IF num_args() = 4 THEN
	CONSTRUCT BY NAME expr_sql ON z01_codcli, z01_nomcli, z01_personeria,
	z01_num_doc_id, z01_tipo_doc_id, z01_direccion1, z01_telefono1,
	z01_tipo_clte, z01_direccion2, z01_telefono2, z01_fax1, z01_fax2,
	z01_casilla, z01_pais, z01_ciudad, z01_rep_legal, z01_paga_impto,
	z02_contacto, z02_referencia, z02_credit_auto, z02_credit_dias,
	z02_cupocred_mb, z02_dcto_item_c, z02_dcto_item_r, z02_dcto_mano_c,
	z02_dcto_mano_r, z02_cheques, z02_zona_venta, z02_zona_cobro,
	z02_aux_clte_mb, z02_aux_clte_ma, z02_aux_ant_mb, z02_aux_ant_ma
	ON KEY(F2)
		IF infield(z01_codcli) THEN
                        CALL fl_ayuda_cliente_general()
                                RETURNING codi_aux, nomi_aux
                        LET int_flag = 0
                        IF codi_aux IS NOT NULL THEN
                                DISPLAY codi_aux TO z01_codcli
                                DISPLAY nomi_aux TO z01_nomcli
                        END IF
                END IF
		IF infield(z01_pais) THEN
                        CALL fl_ayuda_pais()
                                RETURNING codp_aux, nomp_aux
                        LET int_flag = 0
                        IF codp_aux IS NOT NULL THEN
                                DISPLAY codp_aux TO z01_pais
                                DISPLAY nomp_aux TO tit_pais
                        END IF
                END IF
		IF infield(z01_ciudad) THEN
                        CALL fl_ayuda_ciudad(codp_aux)
                                RETURNING codc_aux, nomc_aux
                        LET int_flag = 0
                        IF codc_aux IS NOT NULL THEN
                                DISPLAY codc_aux TO z01_ciudad
                                DISPLAY nomc_aux TO tit_ciudad
                        END IF
                END IF
		IF infield(z01_tipo_clte) THEN
                        CALL fl_ayuda_subtipo_entidad('CL')
                                RETURNING codt1_aux, codt2_aux,
 					  nomt1_aux, nomt2_aux
                        LET int_flag = 0
                        IF codt1_aux IS NOT NULL THEN
                                DISPLAY codt2_aux TO z01_tipo_clte
                                DISPLAY nomt1_aux TO tit_tipo_cli
                        END IF
                END IF
		IF infield(z02_zona_venta) THEN
                        CALL fl_ayuda_zona_venta(vg_codcia)
                                RETURNING codzv_aux, nomzv_aux
                        LET int_flag = 0
                        IF codzv_aux IS NOT NULL THEN
                                DISPLAY codzv_aux TO z02_zona_venta
                                DISPLAY nomzv_aux TO tit_zona_vta
                        END IF
                END IF
		IF infield(z02_zona_cobro) THEN
                        CALL fl_ayuda_zona_cobro()
                                RETURNING codzc_aux, nomzc_aux
                        LET int_flag = 0
                        IF codzc_aux IS NOT NULL THEN
                                DISPLAY codzc_aux TO z02_zona_cobro
                                DISPLAY nomzc_aux TO tit_zona_cob
                        END IF
                END IF
		IF infield(z02_aux_clte_mb) THEN
                        CALL fl_ayuda_cuenta_contable(vg_codcia,6)
                                RETURNING cod_aux, nom_aux
                        LET int_flag = 0
                        IF cod_aux IS NOT NULL THEN
                                DISPLAY cod_aux TO z02_aux_clte_mb
                                DISPLAY nom_aux TO tit_cli_mb
                        END IF
                END IF
                IF infield(z02_aux_clte_ma) THEN
                        CALL fl_ayuda_cuenta_contable(vg_codcia,6)
                                RETURNING cod_aux, nom_aux
                        LET int_flag = 0
                        IF cod_aux IS NOT NULL THEN
                                DISPLAY cod_aux TO z02_aux_clte_ma
                                DISPLAY nom_aux TO tit_cli_ma
                        END IF
                END IF
		IF infield(z02_aux_ant_mb) THEN
                        CALL fl_ayuda_cuenta_contable(vg_codcia,6)
                                RETURNING cod_aux, nom_aux
                        LET int_flag = 0
                        IF cod_aux IS NOT NULL THEN
                                DISPLAY cod_aux TO z02_aux_ant_mb
                                DISPLAY nom_aux TO tit_ant_mb
                        END IF
                END IF
                IF infield(z02_aux_ant_ma) THEN
                        CALL fl_ayuda_cuenta_contable(vg_codcia,6)
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
			CALL muestra_contadores(vm_row_current, vm_num_rows)
			CALL mostrar_registro(vm_r_rows[vm_row_current])
		ELSE
			CLEAR FORM
		END IF
		RETURN
	END IF
ELSE
	LET expr_sql = 'z01_codcli = ', arg_val(5)
END IF
LET query = 'SELECT cxct001.*, cxct001.ROWID FROM cxct001, cxct002 ' ||
		' WHERE z02_compania  = ' || vg_codcia ||
		'   AND z02_localidad = ' || vg_codloc ||
		'   AND z02_codcli    =   z01_codcli ' || 
		'   AND ' || expr_sql CLIPPED || ' ORDER BY 1'
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
	CALL fl_mensaje_consulta_sin_registros()
	CLEAR FORM
	LET vm_row_current = 0
	CALL muestra_contadores(vm_row_current, vm_num_rows)
ELSE  
	LET vm_row_current = 1
	CALL muestra_contadores(vm_row_current, vm_num_rows)
	CALL mostrar_registro(vm_r_rows[vm_row_current])
END IF

END FUNCTION



FUNCTION leer_datos ()
DEFINE resp		CHAR(6)
DEFINE resul		SMALLINT
DEFINE r_pai            RECORD LIKE gent030.*
DEFINE r_ciu            RECORD LIKE gent031.*
DEFINE r_car            RECORD LIKE gent012.*
DEFINE r_cta            RECORD LIKE ctbt010.*
DEFINE r_zon_vta	RECORD LIKE gent032.*
DEFINE r_zon_cob	RECORD LIKE cxct006.*
DEFINE r_mon		RECORD LIKE gent014.*
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

INITIALIZE r_pai.*, r_ciu.*, r_car.*, r_cta.*, r_zon_vta.*, r_zon_cob.*,
	r_mon.*, codp_aux, codc_aux, codt1_aux, codzv_aux, codzc_aux,
	cod_aux TO NULL
DISPLAY rm_cxc.z01_codcli TO tit_codigo_cli
DISPLAY rm_cxc.z01_nomcli TO tit_nombre_cli
DISPLAY BY NAME rm_cxc.z01_usuario, rm_cxc.z01_fecing, rm_cxc2.z02_credit_dias,
		rm_cxc2.z02_cupocred_mb, rm_cxc2.z02_cupocred_ma,
		rm_cxc2.z02_dcto_item_c, rm_cxc2.z02_dcto_item_r,
		rm_cxc2.z02_dcto_mano_c, rm_cxc2.z02_dcto_mano_r,
	 	rm_cxc2.z02_aux_clte_mb, rm_cxc2.z02_aux_clte_ma,
	 	rm_cxc2.z02_aux_ant_mb,	rm_cxc2.z02_aux_ant_ma
LET int_flag = 0
INPUT BY NAME rm_cxc.z01_nomcli, rm_cxc.z01_personeria, rm_cxc.z01_num_doc_id,
	rm_cxc.z01_tipo_doc_id, rm_cxc.z01_direccion1, rm_cxc.z01_telefono1,
	rm_cxc.z01_tipo_clte, rm_cxc.z01_direccion2, rm_cxc.z01_telefono2,
	rm_cxc.z01_fax1, rm_cxc.z01_fax2, rm_cxc.z01_casilla, rm_cxc.z01_pais,
	rm_cxc.z01_ciudad, rm_cxc.z01_rep_legal, rm_cxc.z01_paga_impto,
	rm_cxc2.z02_contacto, rm_cxc2.z02_referencia, rm_cxc2.z02_credit_auto,
	rm_cxc2.z02_credit_dias, rm_cxc2.z02_cupocred_mb,
	rm_cxc2.z02_dcto_item_c, rm_cxc2.z02_dcto_item_r,
	rm_cxc2.z02_dcto_mano_c, rm_cxc2.z02_dcto_mano_r, rm_cxc2.z02_cheques,
	rm_cxc2.z02_zona_venta, rm_cxc2.z02_zona_cobro, rm_cxc2.z02_aux_clte_mb,
	rm_cxc2.z02_aux_clte_ma, rm_cxc2.z02_aux_ant_mb, rm_cxc2.z02_aux_ant_ma
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
        	IF field_touched(rm_cxc.z01_nomcli, rm_cxc.z01_personeria,
			rm_cxc.z01_num_doc_id, rm_cxc.z01_tipo_doc_id,
			rm_cxc.z01_direccion1, rm_cxc.z01_telefono1,
			rm_cxc.z01_tipo_clte, rm_cxc.z01_direccion2,
			rm_cxc.z01_telefono2, rm_cxc.z01_fax1, rm_cxc.z01_fax2,
			rm_cxc.z01_casilla, rm_cxc.z01_pais, rm_cxc.z01_ciudad,
			rm_cxc.z01_rep_legal, rm_cxc.z01_paga_impto,
			rm_cxc2.z02_contacto, rm_cxc2.z02_referencia,
			rm_cxc2.z02_credit_auto, rm_cxc2.z02_credit_dias,
			rm_cxc2.z02_cupocred_mb, rm_cxc2.z02_dcto_item_c,
			rm_cxc2.z02_dcto_item_r, rm_cxc2.z02_dcto_mano_c,
			rm_cxc2.z02_dcto_mano_r, rm_cxc2.z02_cheques,
			rm_cxc2.z02_zona_venta, rm_cxc2.z02_zona_cobro,
			rm_cxc2.z02_aux_clte_mb, rm_cxc2.z02_aux_clte_ma,
			rm_cxc2.z02_aux_ant_mb, rm_cxc2.z02_aux_ant_ma)
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
		IF infield(z01_pais) THEN
                        CALL fl_ayuda_pais()
                                RETURNING codp_aux, nomp_aux
                        LET int_flag = 0
                        IF codp_aux IS NOT NULL THEN
				LET rm_cxc.z01_pais = codp_aux
                                DISPLAY BY NAME rm_cxc.z01_pais
                                DISPLAY nomp_aux TO tit_pais
                        END IF
                END IF
		IF infield(z01_ciudad) THEN
                        CALL fl_ayuda_ciudad(rm_cxc.z01_pais)
                                RETURNING codc_aux, nomc_aux
                        LET int_flag = 0
                        IF codc_aux IS NOT NULL THEN
				LET rm_cxc.z01_ciudad = codc_aux
                                DISPLAY BY NAME rm_cxc.z01_ciudad
                                DISPLAY nomc_aux TO tit_ciudad
                        END IF
                END IF
		IF infield(z01_tipo_clte) THEN
                        CALL fl_ayuda_subtipo_entidad('CL')
                                RETURNING codt1_aux, codt2_aux,
					  nomt1_aux, nomt2_aux
                        LET int_flag = 0
                        IF codt1_aux IS NOT NULL THEN
				LET rm_cxc.z01_tipo_clte = codt2_aux
                                DISPLAY BY NAME rm_cxc.z01_tipo_clte
                                DISPLAY nomt1_aux TO tit_tipo_cli
                        END IF
                END IF
		IF infield(z02_zona_venta) THEN
                        CALL fl_ayuda_zona_venta(vg_codcia)
                                RETURNING codzv_aux, nomzv_aux
                        LET int_flag = 0
                        IF codzv_aux IS NOT NULL THEN
				LET rm_cxc2.z02_zona_venta = codzv_aux
                                DISPLAY BY NAME rm_cxc2.z02_zona_venta
                                DISPLAY nomzv_aux TO tit_zona_vta
                        END IF
                END IF
		IF infield(z02_zona_cobro) THEN
                        CALL fl_ayuda_zona_cobro()
                                RETURNING codzc_aux, nomzc_aux
                        LET int_flag = 0
                        IF codzc_aux IS NOT NULL THEN
				LET rm_cxc2.z02_zona_cobro = codzc_aux
                                DISPLAY BY NAME rm_cxc2.z02_zona_cobro
                                DISPLAY nomzc_aux TO tit_zona_cob
                        END IF
                END IF
		IF infield(z02_aux_clte_mb) THEN
                        CALL fl_ayuda_cuenta_contable(vg_codcia,6)
                                RETURNING cod_aux, nom_aux
                        LET int_flag = 0
                        IF cod_aux IS NOT NULL THEN
				LET rm_cxc2.z02_aux_clte_mb = cod_aux
                                DISPLAY BY NAME rm_cxc2.z02_aux_clte_mb
                                DISPLAY nom_aux TO tit_cli_mb
                        END IF
                END IF
                IF infield(z02_aux_clte_ma) THEN
                        CALL fl_ayuda_cuenta_contable(vg_codcia,6)
                                RETURNING cod_aux, nom_aux
                        LET int_flag = 0
                        IF cod_aux IS NOT NULL THEN
				LET rm_cxc2.z02_aux_clte_ma = cod_aux
                                DISPLAY BY NAME rm_cxc2.z02_aux_clte_ma
                                DISPLAY nom_aux TO tit_cli_ma
                        END IF
                END IF
		IF infield(z02_aux_ant_mb) THEN
                        CALL fl_ayuda_cuenta_contable(vg_codcia,6)
                                RETURNING cod_aux, nom_aux
                        LET int_flag = 0
                        IF cod_aux IS NOT NULL THEN
				LET rm_cxc2.z02_aux_ant_mb = cod_aux
                                DISPLAY BY NAME rm_cxc2.z02_aux_ant_mb
                                DISPLAY nom_aux TO tit_ant_mb
                        END IF
                END IF
                IF infield(z02_aux_ant_ma) THEN
                        CALL fl_ayuda_cuenta_contable(vg_codcia,6)
                                RETURNING cod_aux, nom_aux
                        LET int_flag = 0
                        IF cod_aux IS NOT NULL THEN
				LET rm_cxc2.z02_aux_ant_ma = cod_aux
                                DISPLAY BY NAME rm_cxc2.z02_aux_ant_ma
                                DISPLAY nom_aux TO tit_ant_ma
                        END IF
                END IF
	BEFORE FIELD z01_tipo_doc_id
		IF rm_cxc.z01_num_doc_id IS NULL THEN
			CALL fgl_winmessage(vg_producto,'Digite primero el número de identificación de documento','info')
			NEXT FIELD z01_num_doc_id
		END IF
	BEFORE FIELD z01_direccion1
		IF rm_cxc.z01_personeria = 'N' THEN
			IF rm_cxc.z01_tipo_doc_id = 'R' THEN
				CALL fgl_winmessage(vg_producto,'Una persona natural no puede tener asignado Ruc','exclamation')
				NEXT FIELD z01_tipo_doc_id
			END IF
		ELSE
			IF rm_cxc.z01_tipo_doc_id <> 'R' THEN
				CALL fgl_winmessage(vg_producto,'Una persona jurídica no puede tener asignado Cédula o Pasaporte','exclamation')
				NEXT FIELD z01_tipo_doc_id
			END IF
		END IF
	BEFORE FIELD z01_ciudad
		IF rm_cxc.z01_pais IS NULL THEN
			CALL fgl_winmessage(vg_producto,'Ingrese el país primero','info')
			NEXT FIELD z01_pais
		END IF
	BEFORE FIELD z02_cupocred_mb
		CALL poner_credit_dias() RETURNING resul
	AFTER FIELD z01_nomcli
		DISPLAY rm_cxc.z01_nomcli TO tit_nombre_cli
	AFTER FIELD z01_num_doc_id
		IF rm_cxc.z01_num_doc_id IS NOT NULL THEN
			IF rm_cxc.z01_personeria = 'N' THEN
				LET rm_cxc.z01_tipo_doc_id = 'C'
			ELSE
				LET rm_cxc.z01_tipo_doc_id = 'R'
			END IF
			DISPLAY BY NAME rm_cxc.z01_tipo_doc_id
		END IF
	AFTER FIELD z01_pais
                IF rm_cxc.z01_pais IS NOT NULL THEN
                        CALL fl_lee_pais(rm_cxc.z01_pais)
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
                IF rm_cxc.z01_ciudad IS NOT NULL THEN
                        CALL fl_lee_ciudad(rm_cxc.z01_ciudad)
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
                IF rm_cxc.z01_tipo_clte IS NOT NULL THEN
                        CALL fl_lee_subtipo_entidad('CL',rm_cxc.z01_tipo_clte)
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
		IF rm_cxc2.z02_zona_venta IS NOT NULL THEN
			CALL fl_lee_zona_venta(vg_codcia,rm_cxc2.z02_zona_venta)
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
		IF rm_cxc2.z02_zona_cobro IS NOT NULL THEN
			CALL fl_lee_zona_cobro(rm_cxc2.z02_zona_cobro)
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
		IF rm_cxc2.z02_cupocred_mb IS NOT NULL THEN
			IF rg_gen.g00_moneda_alt IS NOT NULL
			OR rg_gen.g00_moneda_alt <> ' ' THEN
			       CALL fl_lee_factor_moneda(rg_gen.g00_moneda_base,
				rg_gen.g00_moneda_alt)
					RETURNING r_mon.*
				CALL fl_retorna_precision_valor(
							rg_gen.g00_moneda_base,
                                                        rm_cxc2.z02_cupocred_mb)
                                	RETURNING rm_cxc2.z02_cupocred_mb
                                DISPLAY BY NAME rm_cxc2.z02_cupocred_mb
				IF r_mon.g14_serial IS NOT NULL THEN
					LET rm_cxc2.z02_cupocred_ma = 
					rm_cxc2.z02_cupocred_mb * r_mon.g14_tasa
					IF rm_cxc2.z02_cupocred_ma IS NULL 
					OR rm_cxc2.z02_cupocred_ma>9999999999.99
					THEN
						CALL fgl_winmessage(vg_producto,'El cupo de crédito en moneda base está demasiado grande', 'exclamation')
						NEXT FIELD z02_cupocred_mb
					END IF
				END IF
				CALL fl_retorna_precision_valor(
							rg_gen.g00_moneda_base,
                                                        rm_cxc2.z02_cupocred_ma)
                                	RETURNING rm_cxc2.z02_cupocred_ma
				DISPLAY BY NAME rm_cxc2.z02_cupocred_ma
			END IF
		END IF
	AFTER FIELD z02_aux_clte_mb
                IF rm_cxc2.z02_aux_clte_mb IS NOT NULL THEN
                        CALL fl_lee_cuenta(vg_codcia,rm_cxc2.z02_aux_clte_mb)
                                RETURNING r_cta.*
                        IF r_cta.b10_cuenta IS NULL  THEN
                                CALL fgl_winmessage(vg_producto,'Cuenta no exist
e para esta compañía','exclamation')
                                NEXT FIELD z02_aux_clte_mb
                        END IF
                        DISPLAY r_cta.b10_descripcion TO tit_cli_mb
                        IF rm_cxc2.z02_aux_clte_mb = rm_cxc2.z02_aux_ant_mb
                        OR rm_cxc2.z02_aux_clte_mb = rm_cxc2.z02_aux_ant_ma THEN
                                CALL fgl_winmessage(vg_producto,'La cuenta de cl
iente debe ser distinta del anticípo','info')
                                NEXT FIELD z02_aux_clte_mb
                        END IF
                        IF r_cta.b10_estado = 'B' THEN
                                CALL fl_mensaje_estado_bloqueado()
                                NEXT FIELD z02_aux_clte_mb
                        END IF
			IF r_cta.b10_nivel <> 6 THEN
                                CALL fgl_winmessage(vg_producto,'Nivel de cuenta
 debe ser solo 6','info')
                                NEXT FIELD z02_aux_clte_mb
                        END IF
		ELSE
			CLEAR tit_cli_mb
                END IF
	AFTER FIELD z02_aux_clte_ma
                IF rm_cxc2.z02_aux_clte_ma IS NOT NULL THEN
                        CALL fl_lee_cuenta(vg_codcia,rm_cxc2.z02_aux_clte_ma)
                                RETURNING r_cta.*
                        IF r_cta.b10_cuenta IS NULL  THEN
                                CALL fgl_winmessage(vg_producto,'Cuenta no exist
e para esta compañía','exclamation')
                                NEXT FIELD z02_aux_clte_ma
                        END IF
                        DISPLAY r_cta.b10_descripcion TO tit_cli_ma
                        IF rm_cxc2.z02_aux_clte_ma = rm_cxc2.z02_aux_ant_mb
                        OR rm_cxc2.z02_aux_clte_ma = rm_cxc2.z02_aux_ant_ma THEN
                                CALL fgl_winmessage(vg_producto,'La cuenta de cl
iente debe ser distinta del anticípo','info')
                                NEXT FIELD z02_aux_clte_ma
                        END IF
                        IF r_cta.b10_estado = 'B' THEN
                                CALL fl_mensaje_estado_bloqueado()
                                NEXT FIELD z02_aux_clte_ma
                        END IF
			IF r_cta.b10_nivel <> 6 THEN
                                CALL fgl_winmessage(vg_producto,'Nivel de cuenta
 debe ser solo 6','info')
                                NEXT FIELD z02_aux_clte_ma
                        END IF
		ELSE
			CLEAR tit_cli_ma
                END IF
	AFTER FIELD z02_aux_ant_mb
                IF rm_cxc2.z02_aux_ant_mb IS NOT NULL THEN
                        CALL fl_lee_cuenta(vg_codcia,rm_cxc2.z02_aux_ant_mb)
                                RETURNING r_cta.*
                        IF r_cta.b10_cuenta IS NULL  THEN
                                CALL fgl_winmessage(vg_producto,'Cuenta no exist
e para esta compañía','exclamation')
                                NEXT FIELD z02_aux_ant_mb
                        END IF
                        DISPLAY r_cta.b10_descripcion TO tit_ant_mb
                        IF rm_cxc2.z02_aux_ant_mb = rm_cxc2.z02_aux_clte_mb
                        OR rm_cxc2.z02_aux_ant_mb = rm_cxc2.z02_aux_clte_ma THEN
                                CALL fgl_winmessage(vg_producto,'La cuenta de an
ticípo debe ser distinta del cliente','info')
                                NEXT FIELD z02_aux_ant_mb
                        END IF
                        IF r_cta.b10_estado = 'B' THEN
                                CALL fl_mensaje_estado_bloqueado()
                                NEXT FIELD z02_aux_ant_mb
                        END IF
			IF r_cta.b10_nivel <> 6 THEN
                                CALL fgl_winmessage(vg_producto,'Nivel de cuenta
 debe ser solo 6','info')
                                NEXT FIELD z02_aux_ant_mb
                        END IF
		ELSE
			CLEAR  tit_ant_mb
                END IF
	AFTER FIELD z02_aux_ant_ma
                IF rm_cxc2.z02_aux_ant_ma IS NOT NULL THEN
                        CALL fl_lee_cuenta(vg_codcia,rm_cxc2.z02_aux_ant_ma)
                                RETURNING r_cta.*
                        IF r_cta.b10_cuenta IS NULL  THEN
                                CALL fgl_winmessage(vg_producto,'Cuenta no exist
e para esta compañía','exclamation')
                                NEXT FIELD z02_aux_ant_ma
                        END IF
                        DISPLAY r_cta.b10_descripcion TO tit_ant_ma
                        IF rm_cxc2.z02_aux_ant_ma = rm_cxc2.z02_aux_clte_mb
                        OR rm_cxc2.z02_aux_ant_ma = rm_cxc2.z02_aux_clte_ma THEN
                                CALL fgl_winmessage(vg_producto,'La cuenta de an
ticípo debe ser distinta del cliente','info')
                                NEXT FIELD z02_aux_ant_ma
                        END IF
                        IF r_cta.b10_estado = 'B' THEN
                                CALL fl_mensaje_estado_bloqueado()
                                NEXT FIELD z02_aux_ant_ma
                        END IF
			IF r_cta.b10_nivel <> 6 THEN
                                CALL fgl_winmessage(vg_producto,'Nivel de cuenta
 debe ser solo 6','info')
                                NEXT FIELD z02_aux_ant_ma
                        END IF
		ELSE
			CLEAR  tit_ant_ma
                END IF
	AFTER INPUT
		IF fl_validar_cedruc_dig_ver(rm_cxc.z01_tipo_doc_id, rm_cxc.z01_num_doc_id) = 0
		THEN
			NEXT FIELD z01_num_doc_id
		END IF
		CALL poner_credit_dias() RETURNING resul
		IF resul = 1 THEN
			CALL fgl_winmessage(vg_producto,'Crédito de días debe ser mayor a cero, si hay crédito automático','info')
			NEXT FIELD z02_credit_dias
		END IF
END INPUT

END FUNCTION



FUNCTION poner_credit_dias()
IF rm_cxc2.z02_credit_auto = 'N' THEN
	LET rm_cxc2.z02_credit_dias = 0
	DISPLAY BY NAME rm_cxc2.z02_credit_dias
ELSE
	IF rm_cxc2.z02_credit_dias = 0 OR rm_cxc2.z02_credit_dias IS NULL THEN
		RETURN 1
	END IF
END IF
RETURN 0

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
                                                                                
DISPLAY "        " TO tit_estado_cli
CLEAR tit_estado_cli
DISPLAY row_current TO vm_row_current3
DISPLAY num_rows    TO vm_num_rows3
DISPLAY row_current TO vm_row_current2
DISPLAY num_rows    TO vm_num_rows2
DISPLAY row_current TO vm_row_current1
DISPLAY num_rows    TO vm_num_rows1
                                                                                
END FUNCTION



FUNCTION mostrar_registro(num_registro)
DEFINE r_pai            RECORD LIKE gent030.*
DEFINE r_ciu            RECORD LIKE gent031.*
DEFINE r_car            RECORD LIKE gent012.*
DEFINE r_cta            RECORD LIKE ctbt010.*
DEFINE r_zon_vta	RECORD LIKE gent032.*
DEFINE r_zon_cob	RECORD LIKE cxct006.*
DEFINE num_registro	INTEGER

IF vm_num_rows > 0 THEN
	SELECT * INTO rm_cxc.* FROM cxct001 WHERE ROWID = num_registro	
	IF STATUS = NOTFOUND THEN
		CALL fgl_winmessage (vg_producto,'No existe registro con índice: ' || vm_row_current,'exclamation')
		RETURN
	END IF
	DISPLAY BY NAME rm_cxc.z01_codcli, rm_cxc.z01_nomcli,
			rm_cxc.z01_personeria, rm_cxc.z01_num_doc_id,
			rm_cxc.z01_tipo_doc_id, rm_cxc.z01_direccion1, 
			rm_cxc.z01_telefono1, rm_cxc.z01_tipo_clte,
			rm_cxc.z01_direccion2, rm_cxc.z01_telefono2,
			rm_cxc.z01_fax1, rm_cxc.z01_fax2, rm_cxc.z01_casilla,
			rm_cxc.z01_pais, rm_cxc.z01_ciudad,rm_cxc.z01_rep_legal,
			rm_cxc.z01_paga_impto, rm_cxc.z01_usuario,
			rm_cxc.z01_fecing
	CALL fl_lee_pais(rm_cxc.z01_pais) RETURNING r_pai.*
	DISPLAY r_pai.g30_nombre TO tit_pais
	CALL fl_lee_ciudad(rm_cxc.z01_ciudad) RETURNING r_ciu.*
	DISPLAY r_ciu.g31_nombre TO tit_ciudad
	CALL fl_lee_subtipo_entidad('CL',rm_cxc.z01_tipo_clte) RETURNING r_car.*
        DISPLAY r_car.g12_nombre TO tit_tipo_cli
	SELECT * INTO rm_cxc2.* FROM cxct002
		WHERE z02_compania  = vg_codcia
		  AND z02_localidad = vg_codloc
		  AND z02_codcli    = rm_cxc.z01_codcli
	IF STATUS = NOTFOUND THEN
		CALL muestra_estado()
		RETURN
	END IF
	DISPLAY rm_cxc.z01_codcli TO tit_codigo_cli
	DISPLAY rm_cxc.z01_nomcli TO tit_nombre_cli
	DISPLAY BY NAME rm_cxc2.z02_contacto, rm_cxc2.z02_referencia,
			rm_cxc2.z02_credit_auto, rm_cxc2.z02_credit_dias,
			rm_cxc2.z02_cupocred_mb, rm_cxc2.z02_cupocred_ma,
			rm_cxc2.z02_dcto_item_c, rm_cxc2.z02_dcto_item_r,
			rm_cxc2.z02_dcto_mano_c, rm_cxc2.z02_dcto_mano_r,
			rm_cxc2.z02_cheques, rm_cxc2.z02_zona_venta,
			rm_cxc2.z02_zona_cobro,	rm_cxc2.z02_aux_clte_mb,
			rm_cxc2.z02_aux_clte_ma, rm_cxc2.z02_aux_ant_mb,
			rm_cxc2.z02_aux_ant_ma
	CALL fl_lee_zona_venta(vg_codcia,rm_cxc2.z02_zona_venta)
		RETURNING r_zon_vta.*
	DISPLAY r_zon_vta.g32_nombre TO tit_zona_vta
	CALL fl_lee_zona_cobro(rm_cxc2.z02_zona_cobro) RETURNING r_zon_cob.*
	DISPLAY r_zon_cob.z06_nombre TO tit_zona_cob
	CALL fl_lee_cuenta(vg_codcia,rm_cxc2.z02_aux_clte_mb)
                RETURNING r_cta.*
        DISPLAY r_cta.b10_descripcion TO tit_cli_mb
        CALL fl_lee_cuenta(vg_codcia,rm_cxc2.z02_aux_clte_ma)
                RETURNING r_cta.*
        DISPLAY r_cta.b10_descripcion TO tit_cli_ma
        CALL fl_lee_cuenta(vg_codcia,rm_cxc2.z02_aux_ant_mb)
                RETURNING r_cta.*
        DISPLAY r_cta.b10_descripcion TO tit_ant_mb
        CALL fl_lee_cuenta(vg_codcia,rm_cxc2.z02_aux_ant_ma)
                RETURNING r_cta.*
        DISPLAY r_cta.b10_descripcion TO tit_ant_ma
	CALL muestra_estado()
ELSE
	RETURN
END IF

END FUNCTION



FUNCTION bloquear_activar()
DEFINE confir	CHAR(6)

IF vm_num_rows = 0 THEN
	CALL fl_mensaje_consultar_primero()
	RETURN
END IF
LET int_flag = 0
WHENEVER ERROR CONTINUE
BEGIN WORK
DECLARE q_ba CURSOR FOR SELECT * FROM cxct001
	WHERE ROWID = vm_r_rows[vm_row_current]
	FOR UPDATE
OPEN q_ba
FETCH q_ba INTO rm_cxc.*
IF STATUS < 0 THEN
	COMMIT WORK
	CALL fl_mensaje_bloqueo_otro_usuario()
	WHENEVER ERROR STOP
	RETURN
END IF	
CALL fl_mensaje_seguro_ejecutar_proceso()
	RETURNING confir
IF confir = 'Yes' THEN
	LET int_flag = 1
	CALL bloquea_activa_registro()
END IF
COMMIT WORK
WHENEVER ERROR STOP

END FUNCTION



FUNCTION bloquea_activa_registro()
DEFINE estado	CHAR(1)

IF rm_cxc.z01_estado = 'A' THEN
	DISPLAY 'BLOQUEADO' TO tit_estado_cli
	LET estado = 'B'
ELSE 
	DISPLAY 'ACTIVO' TO tit_estado_cli
	LET estado = 'A'
END IF
DISPLAY estado TO tit_est
UPDATE cxct001 SET z01_estado = estado WHERE CURRENT OF q_ba
LET rm_cxc.z01_estado = estado

END FUNCTION



FUNCTION muestra_estado()
IF rm_cxc.z01_estado = 'A' THEN
	DISPLAY 'ACTIVO' TO tit_estado_cli
ELSE
	DISPLAY 'BLOQUEADO' TO tit_estado_cli
END IF
DISPLAY rm_cxc.z01_estado TO tit_est

END FUNCTION



FUNCTION ver_areaneg(flag)
DEFINE flag		CHAR(1)
DEFINE nuevoprog	VARCHAR(400)

LET nuevoprog = 'cd ..', vg_separador, '..', vg_separador, 'COBRANZAS',
	vg_separador, 'fuentes', vg_separador, '; fglrun cxcp106 ' , vg_base,
	' ', vg_modulo, ' ', vg_codcia, ' ', vg_codloc, ' ', rm_cxc.z01_codcli,
	' ', flag
RUN nuevoprog

END FUNCTION



FUNCTION control_cuentas_contables()

OPEN WINDOW wf_2 AT 6,12 WITH 14 ROWS, 58 COLUMNS
    ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE FIRST,BORDER,
	      MESSAGE LINE LAST - 2)
OPTIONS INPUT WRAP,
	ACCEPT KEY	F12
OPEN FORM f_cxc_2 FROM "../forms/cxcf101_2"
DISPLAY FORM f_cxc_2

CALL control_consultar_ctas_contables()

MENU 'OPCIONES'
	COMMAND KEY('M') 'Modificar' 'Modificar cuentas contables asignadas al cliente. '
		CALL control_modificar_ctas_contables()
	COMMAND KEY('S') 'Salir' 'Salir del programa. '
		EXIT MENU
END MENU

CLOSE WINDOW wf_2

END FUNCTION



FUNCTION control_modificar_ctas_contables()

CALL ingresar_cuentas_contables() 
IF int_flag = 1 THEN
	LET int_flag = 0
	CALL control_consultar_ctas_contables()
	RETURN
END IF


END FUNCTION



FUNCTION ingresar_cuentas_contables()
DEFINE resp			CHAR(6)
DEFINE r_g02		RECORD LIKE gent002.*
DEFINE r_g20		RECORD LIKE gent020.*
DEFINE r_b10		RECORD LIKE ctbt010.*

DEFINE i, j			SMALLINT
DEFINE last_lvl		SMALLINT

SELECT MAX(b01_nivel) INTO last_lvl FROM ctbt001 

CALL set_count(vm_ind_ctas)
INPUT ARRAY r_ctas WITHOUT DEFAULTS FROM r_ctas.* 
	ON KEY(INTERRUPT)
		LET int_flag = 0
		CALL fl_mensaje_abandonar_proceso() RETURNING resp
		IF resp = 'Yes' THEN
			LET int_flag = 1
            CLEAR FORM
			RETURN
		END IF
	ON KEY(F2)
		IF INFIELD(b100_localidad) THEN
			CALL fl_ayuda_localidad(vg_codcia) RETURNING r_g02.g02_localidad,
														 r_g02.g02_nombre
			IF r_g02.g02_localidad IS NOT NULL THEN
				LET r_ctas[i].b100_localidad = r_g02.g02_localidad
				LET r_ctas[i].n_localidad    = r_g02.g02_nombre
				DISPLAY r_ctas[i].* TO r_ctas[j].*
			END IF
		END IF
		IF INFIELD(b100_grupo_linea) THEN
			CALL fl_ayuda_grupo_lineas(vg_codcia) 
					RETURNING r_g20.g20_grupo_linea, r_g20.g20_nombre
			IF r_g20.g20_grupo_linea IS NOT NULL THEN
				LET r_ctas[i].b100_grupo_linea = r_g20.g20_grupo_linea
				DISPLAY r_ctas[i].* TO r_ctas[j].*
			END IF
		END IF
		IF INFIELD(b100_cxc_mb) THEN
			CALL fl_ayuda_cuenta_contable(vg_codcia, last_lvl) 
					RETURNING r_b10.b10_cuenta, r_b10.b10_descripcion
			IF r_b10.b10_cuenta IS NOT NULL THEN
				LET r_ctas[i].b100_cxc_mb = r_b10.b10_cuenta
				DISPLAY r_b10.b10_descripcion TO n_cxc
				DISPLAY r_ctas[i].* TO r_ctas[j].*
			END IF
		END IF
		IF INFIELD(b100_ant_mb) THEN
			CALL fl_ayuda_cuenta_contable(vg_codcia, last_lvl) 
					RETURNING r_b10.b10_cuenta, r_b10.b10_descripcion
			IF r_b10.b10_cuenta IS NOT NULL THEN
				LET r_ctas[i].b100_ant_mb = r_b10.b10_cuenta
				DISPLAY r_b10.b10_descripcion TO n_ant
				DISPLAY r_ctas[i].* TO r_ctas[j].*
			END IF
		END IF
	BEFORE ROW
		LET i = arr_curr();
		LET j = scr_line();
		CALL fl_lee_cuenta(vg_codcia, r_ctas[i].b100_cxc_mb) RETURNING r_b10.* 
		DISPLAY r_b10.b10_descripcion TO n_cxc
	AFTER FIELD b100_localidad
		INITIALIZE r_ctas[i].n_localidad TO NULL
		IF r_ctas[i].b100_localidad IS NOT NULL THEN
			CALL fl_lee_localidad(vg_codcia, r_ctas[i].b100_localidad)
					RETURNING r_g02.*
			IF r_g02.g02_compania IS NULL THEN
				CALL fgl_winmessage(vg_producto, 'La localidad no existe.', 'info')
				NEXT FIELD b100_localidad
			END IF
			IF r_g02.g02_estado = 'B' THEN
				CALL fgl_winmessage(vg_producto, 'La localidad esta bloqueada.', 'info')
				NEXT FIELD b100_localidad
			END IF
			LET r_ctas[i].n_localidad = r_g02.g02_nombre
			DISPLAY r_ctas[i].* TO r_ctas[j].*
		END IF
	AFTER FIELD b100_modulo
		IF r_ctas[i].b100_modulo IS NULL THEN
			NEXT FIELD b100_modulo
		END IF
		IF r_ctas[i].b100_modulo <> 'RE' AND r_ctas[i].b100_modulo <> 'TA' THEN
			NEXT FIELD b100_modulo
		END IF
		DISPLAY r_ctas[i].* TO r_ctas[j].*
	AFTER FIELD b100_grupo_linea
		SELECT * FROM gent020
		 WHERE g20_compania = vg_codcia
		   AND g20_grupo_linea = r_ctas[i].b100_grupo_linea
           AND g20_areaneg IN (SELECT g03_areaneg FROM gent003
								WHERE g03_compania = vg_codcia
								  AND g03_modulo = r_ctas[i].b100_modulo)
		IF STATUS = NOTFOUND THEN
			CALL fgl_winmessage(vg_producto, 'Grupo de linea no esta relacionado al modulo', 'info')
			NEXT FIELD b100_grupo_linea
		END IF
	AFTER FIELD b100_cxc_mb
		DISPLAY '' TO n_cxc
		IF r_ctas[i].b100_cxc_mb IS NOT NULL THEN
			CALL fl_lee_cuenta(vg_codcia, r_ctas[i].b100_cxc_mb) RETURNING r_b10.* 
			IF r_b10.b10_compania IS NULL THEN
				CALL fgl_winmessage(vg_producto, 'La cuenta no existe.', 'info')
				NEXT FIELD b100_cxc_mb
			END IF
			IF r_b10.b10_estado = 'B' THEN
				CALL fgl_winmessage(vg_producto, 'La cuenta esta bloqueada.', 'info')
				NEXT FIELD b100_cxc_mb
			END IF
			IF r_b10.b10_nivel <> last_lvl THEN
				CALL fgl_winmessage(vg_producto, 'La cuenta debe ser del nivel de detalle.', 'info')
				NEXT FIELD b100_cxc_mb
			END IF
			DISPLAY r_b10.b10_descripcion TO n_cxc
		END IF
	AFTER FIELD b100_ant_mb
		DISPLAY '' TO n_ant
		IF r_ctas[i].b100_ant_mb IS NOT NULL THEN
			CALL fl_lee_cuenta(vg_codcia, r_ctas[i].b100_ant_mb) RETURNING r_b10.* 
			IF r_b10.b10_compania IS NULL THEN
				CALL fgl_winmessage(vg_producto, 'La cuenta no existe.', 'info')
				NEXT FIELD b100_ant_mb
			END IF
			IF r_b10.b10_estado = 'B' THEN
				CALL fgl_winmessage(vg_producto, 'La cuenta esta bloqueada.', 'info')
				NEXT FIELD b100_ant_mb
			END IF
			IF r_b10.b10_nivel <> last_lvl THEN
				CALL fgl_winmessage(vg_producto, 'La cuenta debe ser del nivel de detalle.', 'info')
				NEXT FIELD b100_ant_mb
			END IF
			DISPLAY r_b10.b10_descripcion TO n_ant
		END IF
	AFTER INPUT
		LET vm_ind_ctas = arr_count()
		IF NOT grabar_cuentas_contables() THEN
				CALL fgl_winmessage(vg_producto, 'Ocurrio un error al grabar corrija y vuelva a intentar.', 'info')
			CONTINUE INPUT
		END IF
END INPUT

END FUNCTION



FUNCTION grabar_cuentas_contables()

DEFINE i 			SMALLINT
DEFINE r_b100		RECORD LIKE ctbt100.*

BEGIN WORK

DELETE FROM ctbt100 WHERE b100_compania  = vg_codcia
					  AND b100_codcli    = rm_cxc.z01_codcli

FOR i = 1 TO vm_ind_ctas
	INITIALIZE r_b100.* TO NULL
	SELECT * INTO r_b100.* FROM ctbt100
	 WHERE b100_compania    = vg_codcia
	   AND b100_localidad   = r_ctas[i].b100_localidad
	   AND b100_modulo      = r_ctas[i].b100_modulo   
	   AND b100_grupo_linea = r_ctas[i].b100_grupo_linea   
	   AND b100_codcli      = rm_cxc.z01_codcli        
	IF r_b100.b100_compania IS NOT NULL THEN
		ROLLBACK WORK
		RETURN 0
	END IF
	INITIALIZE r_b100.* TO NULL
	LET r_b100.b100_compania    = vg_codcia
	LET r_b100.b100_localidad   = r_ctas[i].b100_localidad
	LET r_b100.b100_modulo      = r_ctas[i].b100_modulo   
	LET r_b100.b100_grupo_linea = r_ctas[i].b100_grupo_linea   
	LET r_b100.b100_codcli      = rm_cxc.z01_codcli        
	LET r_b100.b100_cxc_mb      = r_ctas[i].b100_cxc_mb        
	LET r_b100.b100_ant_mb      = r_ctas[i].b100_ant_mb        
	INSERT INTO ctbt100 VALUES(r_b100.*) 
END FOR 

COMMIT WORK

RETURN 1

END FUNCTION



FUNCTION control_consultar_ctas_contables()
DEFINE r_b10		RECORD LIKE ctbt010.*

DECLARE q_ctas CURSOR FOR 
	SELECT b100_localidad, g02_nombre, b100_modulo, b100_grupo_linea, b100_cxc_mb,
           b100_ant_mb
	  FROM ctbt100, gent002
	 WHERE b100_compania = vg_codcia
	   AND b100_codcli   = rm_cxc.z01_codcli           
	   AND g02_compania  = b100_compania
	   AND g02_localidad = b100_localidad

LET vm_ind_ctas = 1
FOREACH q_ctas INTO r_ctas[vm_ind_ctas].*
	LET vm_ind_ctas = vm_ind_ctas + 1
	IF vm_ind_ctas > vm_max_ctas THEN
		EXIT FOREACH
	END IF
END FOREACH

LET vm_ind_ctas = vm_ind_ctas - 1

IF vm_ind_ctas = 0 THEN
	RETURN
END IF

CALL set_count(vm_ind_ctas)
DISPLAY ARRAY r_ctas TO r_ctas.*
	BEFORE DISPLAY
		CALL fl_lee_cuenta(vg_codcia, r_ctas[1].b100_cxc_mb) RETURNING r_b10.* 
		DISPLAY r_b10.b10_descripcion TO n_cxc
		CALL fl_lee_cuenta(vg_codcia, r_ctas[1].b100_ant_mb) RETURNING r_b10.* 
		DISPLAY r_b10.b10_descripcion TO n_ant
		EXIT DISPLAY
END DISPLAY

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
