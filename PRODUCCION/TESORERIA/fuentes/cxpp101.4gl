------------------------------------------------------------------------------
-- Titulo           : cxpp101.4gl - Mantenimiento de Proveedores 
-- Elaboracion      : 24-nov-2001
-- Autor            : NPC
-- Formato Ejecucion: fglrun cxpp101 base módulo cia loc [proveedor]
-- Ultima Correccion: 
-- Motivo Correccion: 
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_nuevoprog	VARCHAR(100)
DEFINE vm_nivel		LIKE ctbt001.b01_nivel
DEFINE rm_p01		RECORD LIKE cxpt001.*
DEFINE rm_p02		RECORD LIKE cxpt002.*
DEFINE rm_p05		RECORD LIKE cxpt005.*
DEFINE vm_num_rows	SMALLINT
DEFINE vm_row_current	SMALLINT
DEFINE vm_max_rows	SMALLINT
DEFINE vm_num_ret       SMALLINT
DEFINE vm_max_ret       SMALLINT
DEFINE vm_flag_ret      SMALLINT
DEFINE vm_flag_mant	CHAR(1)
DEFINE vm_r_rows	ARRAY [5000] OF INTEGER
DEFINE rm_ret		ARRAY [50] OF RECORD 
				p05_porcentaje	LIKE cxpt005.p05_porcentaje,
				p05_tipo_ret	LIKE cxpt005.p05_tipo_ret,
				tit_tipo_ret	VARCHAR(30),
				p05_codigo_sri	LIKE cxpt005.p05_codigo_sri,
				p05_fecha_ini_porc LIKE cxpt005.p05_fecha_ini_porc
			END RECORD
DEFINE rm_ret_aux	ARRAY [50] OF RECORD 
				p05_porcentaje	LIKE cxpt005.p05_porcentaje,
				p05_tipo_ret	LIKE cxpt005.p05_tipo_ret,
				tit_tipo_ret	VARCHAR(30),
				p05_codigo_sri	LIKE cxpt005.p05_codigo_sri,
				p05_fecha_ini_porc LIKE cxpt005.p05_fecha_ini_porc
			END RECORD

MAIN

DEFER QUIT 
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/cxpp101.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 AND num_args() <> 5 THEN   -- Validar # parámetros correcto
	CALL fgl_winmessage(vg_producto, 'Número de parámetros incorrecto', 'stop')
	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_codloc  = arg_val(4)
LET vg_proceso = 'cxpp101'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
--#CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL control_master()

END MAIN



FUNCTION control_master()
DEFINE i		SMALLINT

CALL fl_nivel_isolation()
LET vm_max_rows	= 5000
LET vm_max_ret	= 50
OPEN WINDOW wf AT 3,2 WITH 21 ROWS, 80 COLUMNS
    ATTRIBUTE(FORM LINE FIRST + 2, COMMENT LINE LAST, MENU LINE FIRST,BORDER,
	      MESSAGE LINE LAST - 1)
OPTIONS INPUT WRAP,
	ACCEPT KEY	F12
OPEN FORM f_cxp FROM "../forms/cxpf101_1"
DISPLAY FORM f_cxp
INITIALIZE rm_p01.*, rm_p02.*, rm_p05.* TO NULL
FOR i = 1 TO vm_max_ret
        INITIALIZE rm_ret[i].*, rm_ret_aux[i].* TO NULL
END FOR
SELECT MAX(b01_nivel) INTO vm_nivel FROM ctbt001
IF vm_nivel IS NULL THEN
	CALL fl_mostrar_mensaje('No existe ningun nivel de cuenta configurado en la compania.','stop')
	EXIT PROGRAM
END IF
LET vm_num_rows    = 0
LET vm_num_ret     = 0
LET vm_row_current = 0
LET vm_flag_ret    = 1
CALL muestra_contadores(vm_row_current, vm_num_rows)
MENU 'OPCIONES'
	BEFORE MENU
		HIDE OPTION 'Avanzar'
		HIDE OPTION 'Retroceder'
		HIDE OPTION 'Modificar'
		HIDE OPTION 'Retenciones'
		HIDE OPTION 'Grabar'
		HIDE OPTION 'Bloquear/Activar'
		IF num_args() = 5 THEN
			LET vm_flag_ret = 0
			HIDE OPTION 'Ingresar'
			HIDE OPTION 'Consultar'
			SHOW OPTION 'Retenciones'
			CALL control_consulta()
			IF vm_num_rows = 0 THEN
				EXIT PROGRAM
			END IF
		END IF
	COMMAND KEY('I') 'Ingresar' 'Ingresar nuevos registros. '
		CALL control_ingreso()
		IF vm_num_rows = 1 THEN
			SHOW OPTION 'Modificar'
			SHOW OPTION 'Retenciones'
			SHOW OPTION 'Grabar'
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
			SHOW OPTION 'Retenciones'
			SHOW OPTION 'Grabar'
			SHOW OPTION 'Bloquear/Activar'
			HIDE OPTION 'Avanzar'
			HIDE OPTION 'Retroceder'
			IF vm_num_rows = 0 THEN
				HIDE OPTION 'Modificar'
				HIDE OPTION 'Retenciones'
				HIDE OPTION 'Grabar'
				HIDE OPTION 'Bloquear/Activar'
			END IF
		ELSE
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Modificar'
			SHOW OPTION 'Retenciones'
			SHOW OPTION 'Grabar'
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
	COMMAND KEY('E') 'Retenciones'  'Retenciones de un proveedor. '
		CALL control_retenciones()
     	COMMAND KEY('G') 'Grabar' 'Graba el registro corriente. '
		BEGIN WORK
			CALL control_grabar()
		COMMIT WORK
     	COMMAND KEY('B') 'Bloquear/Activar' 'Bloquear o activar registro. '
		CALL bloquear_activar()
	COMMAND KEY('S') 'Salir' 'Salir del programa. '
		EXIT MENU
END MENU

END FUNCTION



FUNCTION control_ingreso()
DEFINE r_cia		RECORD LIKE cxpt000.*
DEFINE r_cta		RECORD LIKE ctbt010.*

CALL fl_retorna_usuario()
LET vm_flag_ret = 0
INITIALIZE rm_p01.*, rm_p02.*, rm_p05.*, r_cia.*, r_cta.* TO NULL
CLEAR p02_cupocred_ma, tit_codigo_pro, tit_nombre_pro, p01_estado,
	tit_estado_pro, tit_pais, tit_ciudad, tit_tipo_pro, tit_pro_mb,
	tit_pro_ma, tit_ant_mb, tit_ant_ma, p01_codprov
CALL fl_lee_compania_tesoreria(vg_codcia) RETURNING r_cia.*
IF r_cia.p00_estado = 'A' THEN
	LET rm_p02.p02_aux_prov_mb = r_cia.p00_aux_prov_mb
	CALL fl_lee_cuenta(vg_codcia,r_cia.p00_aux_prov_mb) RETURNING r_cta.*
	DISPLAY r_cta.b10_descripcion TO tit_pro_mb
	LET rm_p02.p02_aux_prov_ma = r_cia.p00_aux_prov_ma
	CALL fl_lee_cuenta(vg_codcia,r_cia.p00_aux_prov_ma) RETURNING r_cta.*
	DISPLAY r_cta.b10_descripcion TO tit_pro_ma
	LET rm_p02.p02_aux_ant_mb  = r_cia.p00_aux_ant_mb
	CALL fl_lee_cuenta(vg_codcia,r_cia.p00_aux_ant_mb) RETURNING r_cta.*
	DISPLAY r_cta.b10_descripcion TO tit_ant_mb
	LET rm_p02.p02_aux_ant_ma  = r_cia.p00_aux_ant_ma
	CALL fl_lee_cuenta(vg_codcia,r_cia.p00_aux_ant_ma) RETURNING r_cta.*
	DISPLAY r_cta.b10_descripcion TO tit_ant_ma
END IF

LET rm_p01.p01_personeria   = 'J'
LET rm_p01.p01_tipo_doc     = 'R'
LET rm_p01.p01_ret_fuente   = 'S'
LET rm_p01.p01_ret_impto    = 'S'
LET rm_p01.p01_cont_espe    = 'N'
LET rm_p01.p01_estado       = 'A'
LET rm_p02.p02_tip_cta_prov = 'N'
LET rm_p01.p01_usuario      = vg_usuario
LET rm_p01.p01_fecing       = CURRENT

LET rm_p02.p02_compania     = vg_codcia
LET rm_p02.p02_localidad    = vg_codloc
LET rm_p02.p02_int_ext      = 'E'
LET rm_p02.p02_credit_dias  = 0
LET rm_p02.p02_cupocred_mb  = 0
LET rm_p02.p02_cupocred_ma  = 0
LET rm_p02.p02_descuento    = 0
LET rm_p02.p02_recargo      = 0
LET rm_p02.p02_dias_demora  = 0
LET rm_p02.p02_dias_seguri  = 0
LET rm_p02.p02_usuario      = rm_p01.p01_usuario
LET rm_p02.p02_fecing       = rm_p01.p01_fecing

CALL muestra_estado()
LET vm_flag_mant = 'I'
CALL leer_datos()
IF NOT int_flag THEN
	IF vm_num_rows = vm_max_rows THEN
		LET vm_num_rows = 1
	ELSE
		LET vm_num_rows = vm_num_rows + 1
	END IF
	LET vm_row_current = vm_num_rows
ELSE
	CLEAR FORM
	IF vm_row_current > 0 THEN
		CALL mostrar_registro(vm_r_rows[vm_row_current])
	ELSE
		CALL muestra_estado()
		CLEAR p01_estado, tit_estado_pro
	END IF
END IF

END FUNCTION



FUNCTION control_modificacion()

IF vm_num_rows = 0 THEN
	CALL fl_mensaje_consultar_primero()
	RETURN
END IF
IF rm_p01.p01_estado = 'B' THEN
	CALL fl_mensaje_estado_bloqueado()
	RETURN
END IF
CALL mostrar_registro(vm_r_rows[vm_row_current])
BEGIN WORK
WHENEVER ERROR CONTINUE
DECLARE q_up CURSOR FOR
	SELECT * FROM cxpt001
		WHERE ROWID = vm_r_rows[vm_row_current]
	FOR UPDATE
OPEN q_up
FETCH q_up INTO rm_p01.*
IF STATUS < 0 THEN
	ROLLBACK WORK
	CALL fl_mensaje_bloqueo_otro_usuario()
	WHENEVER ERROR STOP
	RETURN
END IF
DECLARE q_up2 CURSOR FOR
	SELECT * FROM cxpt002
		WHERE p02_compania  = rm_p02.p02_compania 
	   	  AND p02_localidad = rm_p02.p02_localidad
		  AND p02_codprov   = rm_p01.p01_codprov
	FOR UPDATE
OPEN q_up2
FETCH q_up2 INTO rm_p02.*
IF STATUS < 0 THEN
	ROLLBACK WORK
	CALL fl_mensaje_bloqueo_otro_usuario()
	WHENEVER ERROR STOP
	RETURN
END IF
IF rm_p02.p02_codprov IS NULL THEN
	LET rm_p02.p02_int_ext = 'I'
	LET rm_p02.p02_usuario = rm_p01.p01_usuario
	LET rm_p02.p02_fecing  = CURRENT
END IF
WHENEVER ERROR STOP
CALL leer_datos()
IF NOT int_flag THEN
	LET vm_flag_mant        = 'M'
	LET rm_p05.p05_compania = vg_codcia
	LET rm_p05.p05_codprov  = rm_p01.p01_codprov
	CALL control_grabar()
	COMMIT WORK
	CALL muestra_contadores(vm_row_current, vm_num_rows)
	CALL muestra_estado()
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
DEFINE codi_aux         LIKE cxpt001.p01_codprov
DEFINE nomi_aux         LIKE cxpt001.p01_nomprov
DEFINE codp_aux         LIKE gent030.g30_pais
DEFINE nomp_aux         LIKE gent030.g30_nombre
DEFINE codc_aux         LIKE gent031.g31_ciudad
DEFINE nomc_aux         LIKE gent031.g31_nombre
DEFINE codt1_aux        LIKE gent012.g12_tiporeg
DEFINE codt2_aux        LIKE gent012.g12_subtipo
DEFINE nomt1_aux        LIKE gent012.g12_nombre
DEFINE nomt2_aux        LIKE gent011.g11_nombre
DEFINE cod_aux          LIKE ctbt010.b10_cuenta
DEFINE nom_aux          LIKE ctbt010.b10_descripcion
DEFINE r_g08		RECORD LIKE gent008.*
DEFINE query		VARCHAR(1500)
DEFINE expr_sql		VARCHAR(800)
DEFINE num_reg		INTEGER

CLEAR FORM
INITIALIZE codi_aux, codp_aux, codc_aux, codt1_aux, cod_aux TO NULL
LET vm_flag_ret = 0
LET int_flag    = 0
IF num_args() = 4 THEN
	CONSTRUCT BY NAME expr_sql ON p01_codprov, p01_estado, p01_nomprov,
	p01_personeria,	p01_num_doc, p01_tipo_doc, p01_num_aut, p01_serie_comp,
	p01_direccion1, p01_telefono1, p01_usuario, p01_tipo_prov,
	p01_direccion2, p01_telefono2, p01_fax1, p01_casilla, p01_fax2,
	p02_banco_prov, p02_cod_bco_tra, p02_cta_prov, p02_tip_cta_prov,
	p01_pais, p01_ciudad, p01_rep_legal, p01_ret_fuente, p01_ret_impto,
	p01_cont_espe, p02_contacto, p02_referencia, p02_credit_dias, p02_email,
	p02_cupocred_mb, p02_descuento, p02_recargo, p02_dias_demora,
	p02_dias_seguri, p02_int_ext, p02_aux_prov_mb, p02_aux_prov_ma,
	p02_aux_ant_mb, p02_aux_ant_ma
	ON KEY(F2)
		IF INFIELD(p01_codprov) THEN
                        CALL fl_ayuda_proveedores()
                                RETURNING codi_aux, nomi_aux
                        LET int_flag = 0
                        IF codi_aux IS NOT NULL THEN
                                DISPLAY codi_aux TO p01_codprov
                                DISPLAY nomi_aux TO p01_nomprov
                        END IF
                END IF
		IF INFIELD(p01_pais) THEN
                        CALL fl_ayuda_pais()
                                RETURNING codp_aux, nomp_aux
                        LET int_flag = 0
                        IF codp_aux IS NOT NULL THEN
                                DISPLAY codp_aux TO p01_pais
                                DISPLAY nomp_aux TO tit_pais
                        END IF
                END IF
		IF INFIELD(p01_ciudad) THEN
                        CALL fl_ayuda_ciudad(codp_aux, 0)
                                RETURNING codc_aux, nomc_aux
                        LET int_flag = 0
                        IF codc_aux IS NOT NULL THEN
                                DISPLAY codc_aux TO p01_ciudad
                                DISPLAY nomc_aux TO tit_ciudad
                        END IF
                END IF
		IF INFIELD(p01_tipo_prov) THEN
                        CALL fl_ayuda_subtipo_entidad('TP')
                                RETURNING codt1_aux, codt2_aux,
 					  nomt1_aux, nomt2_aux
                        LET int_flag = 0
                        IF codt1_aux IS NOT NULL THEN
                                DISPLAY codt2_aux TO p01_tipo_prov
                                DISPLAY nomt1_aux TO tit_tipo_pro
                        END IF
                END IF
		IF INFIELD(p02_banco_prov) THEN
			CALL fl_ayuda_bancos()
				RETURNING r_g08.g08_banco, r_g08.g08_nombre
                        LET int_flag = 0
			IF r_g08.g08_banco IS NOT NULL THEN
				DISPLAY r_g08.g08_banco TO p02_banco_prov
				DISPLAY BY NAME r_g08.g08_nombre
			END IF
		END IF
		IF INFIELD(p02_aux_prov_mb) THEN
                        CALL fl_ayuda_cuenta_contable(vg_codcia,vm_nivel)
                                RETURNING cod_aux, nom_aux
                        LET int_flag = 0
                        IF cod_aux IS NOT NULL THEN
                                DISPLAY cod_aux TO p02_aux_prov_mb
                                DISPLAY nom_aux TO tit_pro_mb
                        END IF
                END IF
                IF INFIELD(p02_aux_prov_ma) THEN
                        CALL fl_ayuda_cuenta_contable(vg_codcia,vm_nivel)
                                RETURNING cod_aux, nom_aux
                        LET int_flag = 0
                        IF cod_aux IS NOT NULL THEN
                                DISPLAY cod_aux TO p02_aux_prov_ma
                                DISPLAY nom_aux TO tit_pro_ma
                        END IF
                END IF
		IF INFIELD(p02_aux_ant_mb) THEN
                        CALL fl_ayuda_cuenta_contable(vg_codcia,vm_nivel)
                                RETURNING cod_aux, nom_aux
                        LET int_flag = 0
                        IF cod_aux IS NOT NULL THEN
                                DISPLAY cod_aux TO p02_aux_ant_mb
                                DISPLAY nom_aux TO tit_ant_mb
                        END IF
                END IF
                IF INFIELD(p02_aux_ant_ma) THEN
                        CALL fl_ayuda_cuenta_contable(vg_codcia,vm_nivel)
                                RETURNING cod_aux, nom_aux
                        LET int_flag = 0
                        IF cod_aux IS NOT NULL THEN
                                DISPLAY cod_aux TO p02_aux_ant_ma
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
	LET expr_sql = 'p01_codprov = ', arg_val(5)
END IF
LET query = 'SELECT cxpt001.*, cxpt001.ROWID FROM cxpt001, cxpt002 ' || 
		' WHERE p02_compania  = ' || vg_codcia  ||
		'   AND p02_localidad = ' || vg_codloc  ||
		'   AND p02_codprov   =   p01_codprov ' ||
		'   AND ' || expr_sql CLIPPED || ' ORDER BY 1'
PREPARE cons FROM query	
DECLARE q_cons CURSOR FOR cons
LET vm_num_rows = 0
FOREACH q_cons INTO rm_p01.*, num_reg
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



FUNCTION control_retenciones()
DEFINE l		SMALLINT

IF rm_p01.p01_estado = 'B' THEN
	CALL fl_mensaje_estado_bloqueado()
	RETURN
END IF
IF rm_p01.p01_ret_impto = 'N' AND rm_p01.p01_ret_fuente = 'N'
AND rm_p01.p01_cont_espe = 'N' THEN
	CALL fgl_winmessage(vg_producto,'El proveedor no está configurado para retener impuestos.','exclamation')
	RETURN
END IF
OPEN WINDOW w_ret AT 06, 22
        WITH FORM '../forms/cxpf101_2'
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MESSAGE LINE LAST,
                   BORDER)
CALL mostrar_botones_retencion()
DISPLAY rm_p01.p01_codprov TO p05_codprov
DISPLAY rm_p01.p01_nomprov TO tit_proveedor
IF vm_flag_ret = 0 THEN
	CALL cargar_retencion()
	IF num_args() = 5 THEN
		IF vm_num_ret = 0 THEN
			CALL fl_mensaje_consulta_sin_registros()
		ELSE
			CALL muestra_detalle_ret()
		END IF
		CLOSE WINDOW w_ret
		RETURN
	END IF
	LET vm_flag_ret = 1
END IF
LET int_flag = 0
CALL leer_retencion()
LET vm_flag_mant = 'C'
CLOSE WINDOW w_ret
IF int_flag THEN
	RETURN
END IF

END FUNCTION



FUNCTION cargar_retencion()
DEFINE r_cxp3		RECORD LIKE cxpt005.*

DECLARE q_ret CURSOR FOR
	SELECT * FROM cxpt005
		WHERE p05_compania = vg_codcia
		  AND p05_codprov  = rm_p01.p01_codprov
	        ORDER BY 4
LET vm_num_ret = 1
FOREACH q_ret INTO r_cxp3.*
	LET rm_ret[vm_num_ret].p05_porcentaje = r_cxp3.p05_porcentaje
	LET rm_ret[vm_num_ret].p05_tipo_ret   = r_cxp3.p05_tipo_ret
	CALL descripcion_retencion(r_cxp3.p05_tipo_ret,
					r_cxp3.p05_porcentaje)
		RETURNING rm_ret[vm_num_ret].tit_tipo_ret
	LET rm_ret[vm_num_ret].p05_codigo_sri     = r_cxp3.p05_codigo_sri
	LET rm_ret[vm_num_ret].p05_fecha_ini_porc = r_cxp3.p05_fecha_ini_porc
	LET rm_ret_aux[vm_num_ret].* = rm_ret[vm_num_ret].*
	LET vm_num_ret = vm_num_ret + 1
        IF vm_num_ret > vm_max_ret THEN
        	EXIT FOREACH
        END IF
END FOREACH
LET vm_num_ret = vm_num_ret - 1

END FUNCTION



FUNCTION descripcion_retencion(tipo, porc)
DEFINE tipo		LIKE cxpt005.p05_tipo_ret
DEFINE porc		LIKE cxpt005.p05_porcentaje
DEFINE r_ord		RECORD LIKE ordt002.*

CALL fl_lee_tipo_retencion(vg_codcia, tipo, porc) RETURNING r_ord.*
RETURN r_ord.c02_nombre

END FUNCTION



FUNCTION leer_datos()
DEFINE resp		CHAR(6)
DEFINE resul		SMALLINT
DEFINE r_pai            RECORD LIKE gent030.*
DEFINE r_ciu            RECORD LIKE gent031.*
DEFINE r_car            RECORD LIKE gent012.*
DEFINE r_mon		RECORD LIKE gent014.*
DEFINE r_g08		RECORD LIKE gent008.*
DEFINE codp_aux         LIKE gent030.g30_pais
DEFINE nomp_aux         LIKE gent030.g30_nombre
DEFINE codc_aux         LIKE gent031.g31_ciudad
DEFINE nomc_aux         LIKE gent031.g31_nombre
DEFINE codt1_aux        LIKE gent012.g12_tiporeg
DEFINE codt2_aux        LIKE gent012.g12_subtipo
DEFINE nomt1_aux        LIKE gent012.g12_nombre
DEFINE nomt2_aux        LIKE gent011.g11_nombre
DEFINE cod_aux          LIKE ctbt010.b10_cuenta
DEFINE nom_aux          LIKE ctbt010.b10_descripcion

INITIALIZE r_pai.*, r_ciu.*, r_car.*, r_mon.*, codp_aux, codc_aux, 
	codt1_aux, cod_aux TO NULL
DISPLAY rm_p01.p01_codprov TO tit_codigo_pro
DISPLAY rm_p01.p01_nomprov TO tit_nombre_pro
IF rm_p02.p02_tip_cta_prov IS NULL THEN
	LET rm_p02.p02_tip_cta_prov = 'N'
END IF
DISPLAY BY NAME rm_p01.p01_usuario, rm_p01.p01_fecing, rm_p02.p02_credit_dias,
		rm_p02.p02_email, rm_p02.p02_cupocred_mb,
		rm_p02.p02_cupocred_ma, rm_p02.p02_descuento,
		rm_p02.p02_recargo, rm_p02.p02_tip_cta_prov,
		rm_p02.p02_dias_demora, rm_p02.p02_dias_seguri,
	 	rm_p02.p02_aux_prov_mb, rm_p02.p02_aux_prov_ma,
	 	rm_p02.p02_aux_ant_mb,	rm_p02.p02_aux_ant_ma
LET int_flag = 0
INPUT BY NAME rm_p01.p01_nomprov, rm_p01.p01_personeria, rm_p01.p01_num_doc,
	rm_p01.p01_tipo_doc, rm_p01.p01_num_aut, rm_p01.p01_serie_comp,
	rm_p01.p01_direccion1, rm_p01.p01_telefono1, rm_p01.p01_tipo_prov,
	rm_p01.p01_direccion2, rm_p01.p01_telefono2, rm_p01.p01_fax1,
	rm_p01.p01_casilla, rm_p01.p01_fax2, rm_p02.p02_banco_prov,
	rm_p02.p02_cod_bco_tra, rm_p02.p02_cta_prov, rm_p02.p02_tip_cta_prov,
	rm_p01.p01_pais, rm_p01.p01_ciudad, rm_p01.p01_rep_legal,
	rm_p01.p01_ret_fuente, rm_p01.p01_ret_impto, rm_p01.p01_cont_espe,
	rm_p02.p02_contacto, rm_p02.p02_referencia, rm_p02.p02_credit_dias,
	rm_p02.p02_email, rm_p02.p02_cupocred_mb, rm_p02.p02_descuento,
	rm_p02.p02_recargo, rm_p02.p02_dias_demora, rm_p02.p02_dias_seguri,
	rm_p02.p02_int_ext, rm_p02.p02_aux_prov_mb, rm_p02.p02_aux_prov_ma,
	rm_p02.p02_aux_ant_mb, rm_p02.p02_aux_ant_ma
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
        	IF FIELD_TOUCHED(rm_p01.p01_nomprov, rm_p01.p01_personeria,
			rm_p01.p01_num_doc, rm_p01.p01_tipo_doc,
			rm_p01.p01_num_aut, rm_p01.p01_serie_comp,
			rm_p01.p01_direccion1, rm_p01.p01_telefono1,
			rm_p01.p01_tipo_prov, rm_p01.p01_direccion2,
			rm_p01.p01_telefono2, rm_p01.p01_fax1,
			rm_p01.p01_casilla, rm_p01.p01_fax2,
			rm_p02.p02_banco_prov, rm_p02.p02_cod_bco_tra,
			rm_p02.p02_cta_prov, rm_p02.p02_tip_cta_prov,
			rm_p01.p01_pais,rm_p01.p01_ciudad, rm_p01.p01_rep_legal,
			rm_p01.p01_ret_fuente, rm_p01.p01_ret_impto,
			rm_p01.p01_cont_espe, rm_p02.p02_contacto,
			rm_p02.p02_referencia, rm_p02.p02_credit_dias,
			rm_p02.p02_email, rm_p02.p02_cupocred_mb,
			rm_p02.p02_descuento, rm_p02.p02_recargo,
			rm_p02.p02_dias_demora, rm_p02.p02_dias_seguri,
			rm_p02.p02_int_ext, rm_p02.p02_aux_prov_mb,
			rm_p02.p02_aux_prov_ma, rm_p02.p02_aux_ant_mb,
			rm_p02.p02_aux_ant_ma)
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
		IF INFIELD(p01_pais) THEN
                        CALL fl_ayuda_pais()
                                RETURNING codp_aux, nomp_aux
                        LET int_flag = 0
                        IF codp_aux IS NOT NULL THEN
				LET rm_p01.p01_pais = codp_aux
                                DISPLAY BY NAME rm_p01.p01_pais
                                DISPLAY nomp_aux TO tit_pais
                        END IF
                END IF
		IF INFIELD(p01_ciudad) THEN
                        CALL fl_ayuda_ciudad(rm_p01.p01_pais, 0)
                                RETURNING codc_aux, nomc_aux
                        LET int_flag = 0
                        IF codc_aux IS NOT NULL THEN
				LET rm_p01.p01_ciudad = codc_aux
                                DISPLAY BY NAME rm_p01.p01_ciudad
                                DISPLAY nomc_aux TO tit_ciudad
                        END IF
                END IF
		IF INFIELD(p01_tipo_prov) THEN
                        CALL fl_ayuda_subtipo_entidad('TP')
                                RETURNING codt1_aux, codt2_aux,
					  nomt1_aux, nomt2_aux
                        LET int_flag = 0
                        IF codt1_aux IS NOT NULL THEN
				LET rm_p01.p01_tipo_prov = codt2_aux
                                DISPLAY BY NAME rm_p01.p01_tipo_prov
                                DISPLAY nomt1_aux TO tit_tipo_pro
                        END IF
                END IF
		IF INFIELD(p02_banco_prov) THEN
			CALL fl_ayuda_bancos()
				RETURNING r_g08.g08_banco, r_g08.g08_nombre
                        LET int_flag = 0
			IF r_g08.g08_banco IS NOT NULL THEN
				LET rm_p02.p02_banco_prov = r_g08.g08_banco
				CALL retorna_cod_bco_tra()
				DISPLAY BY NAME rm_p02.p02_banco_prov,
						r_g08.g08_nombre,
						rm_p02.p02_cod_bco_tra
			END IF
		END IF
		IF INFIELD(p02_aux_prov_mb) THEN
                        CALL fl_ayuda_cuenta_contable(vg_codcia,vm_nivel)
                                RETURNING cod_aux, nom_aux
                        LET int_flag = 0
                        IF cod_aux IS NOT NULL THEN
				LET rm_p02.p02_aux_prov_mb = cod_aux
                                DISPLAY BY NAME rm_p02.p02_aux_prov_mb
                                DISPLAY nom_aux TO tit_pro_mb
                        END IF
                END IF
                IF INFIELD(p02_aux_prov_ma) THEN
                        CALL fl_ayuda_cuenta_contable(vg_codcia,vm_nivel)
                                RETURNING cod_aux, nom_aux
                        LET int_flag = 0
                        IF cod_aux IS NOT NULL THEN
				LET rm_p02.p02_aux_prov_ma = cod_aux
                                DISPLAY BY NAME rm_p02.p02_aux_prov_ma
                                DISPLAY nom_aux TO tit_pro_ma
                        END IF
                END IF
		IF INFIELD(p02_aux_ant_mb) THEN
                        CALL fl_ayuda_cuenta_contable(vg_codcia,vm_nivel)
                                RETURNING cod_aux, nom_aux
                        LET int_flag = 0
                        IF cod_aux IS NOT NULL THEN
				LET rm_p02.p02_aux_ant_mb = cod_aux
                                DISPLAY BY NAME rm_p02.p02_aux_ant_mb
                                DISPLAY nom_aux TO tit_ant_mb
                        END IF
                END IF
                IF INFIELD(p02_aux_ant_ma) THEN
                        CALL fl_ayuda_cuenta_contable(vg_codcia,vm_nivel)
                                RETURNING cod_aux, nom_aux
                        LET int_flag = 0
                        IF cod_aux IS NOT NULL THEN
				LET rm_p02.p02_aux_ant_ma = cod_aux
                                DISPLAY BY NAME rm_p02.p02_aux_ant_ma
                                DISPLAY nom_aux TO tit_ant_ma
                        END IF
                END IF
	BEFORE FIELD p01_tipo_doc
		IF rm_p01.p01_num_doc IS NULL THEN
			CALL fgl_winmessage(vg_producto,'Digite primero el número de identificación de documento.','info')
			NEXT FIELD p01_num_doc
		END IF
	BEFORE FIELD p01_direccion1
		IF rm_p01.p01_personeria = 'N' THEN
			IF rm_p01.p01_tipo_doc = 'R' THEN
				CALL fgl_winmessage(vg_producto,'Una persona natural no puede tener asignado Ruc.','exclamation')
				NEXT FIELD p01_tipo_doc
			END IF
		ELSE
			IF rm_p01.p01_tipo_doc <> 'R' THEN
				CALL fgl_winmessage(vg_producto,'Una persona jurídica no puede tener asignado Cédula o Pasaporte.','exclamation')
				NEXT FIELD p01_tipo_doc
			END IF
		END IF
	BEFORE FIELD p01_ciudad
		IF rm_p01.p01_pais IS NULL THEN
			CALL fgl_winmessage(vg_producto,'Ingrese el país primero.','info')
			NEXT FIELD p01_pais
		END IF
	AFTER FIELD p01_nomprov
		DISPLAY rm_p01.p01_nomprov TO tit_nombre_pro
	AFTER FIELD p01_num_doc
		IF rm_p01.p01_num_doc IS NOT NULL THEN
			IF rm_p01.p01_personeria = 'N' THEN
				LET rm_p01.p01_tipo_doc = 'C'
			ELSE
				LET rm_p01.p01_tipo_doc = 'R'
			END IF
			DISPLAY BY NAME rm_p01.p01_tipo_doc
			CALL validar_cedruc(rm_p01.p01_codprov,
						rm_p01.p01_num_doc)
				RETURNING resul
			IF NOT resul THEN
				--NEXT FIELD p01_num_doc
			END IF
		END IF
	AFTER FIELD p01_pais
                IF rm_p01.p01_pais IS NOT NULL THEN
                        CALL fl_lee_pais(rm_p01.p01_pais)
                                RETURNING r_pai.*
                        IF r_pai.g30_pais IS NULL  THEN
                                CALL fgl_winmessage(vg_producto,'Este país no existe','exclamation')
                                NEXT FIELD p01_pais
                        END IF
                        DISPLAY r_pai.g30_nombre TO tit_pais
                ELSE
                        CLEAR tit_pais
                END IF
	AFTER FIELD p01_ciudad
                IF rm_p01.p01_ciudad IS NOT NULL THEN
                        CALL fl_lee_ciudad(rm_p01.p01_ciudad)
                                RETURNING r_ciu.*
                        IF r_ciu.g31_ciudad IS NULL  THEN
                                CALL fgl_winmessage(vg_producto,'Está ciudad no existe','exclamation')
                                NEXT FIELD p01_ciudad
                        END IF
                        DISPLAY r_ciu.g31_nombre TO tit_ciudad
			IF r_ciu.g31_pais <> r_pai.g30_pais THEN
				CALL fgl_winmessage(vg_producto,'Esta ciudad no pertenece a ese país','exclamation')
				NEXT FIELD p01_ciudad
			END IF
                ELSE
                        CLEAR tit_ciudad
                END IF
	AFTER FIELD p01_tipo_prov
                IF rm_p01.p01_tipo_prov IS NOT NULL THEN
                        CALL fl_lee_subtipo_entidad('TP',rm_p01.p01_tipo_prov)
                                RETURNING r_car.*
                        IF r_car.g12_tiporeg IS NULL  THEN
                                CALL fgl_winmessage(vg_producto,'Cartera no existe','exclamation')
                                NEXT FIELD p01_tipo_prov
                        END IF
                        DISPLAY r_car.g12_nombre TO tit_tipo_pro
		ELSE
			CLEAR tit_tipo_pro
                END IF
	AFTER FIELD p02_banco_prov
		IF rm_p02.p02_banco_prov IS NOT NULL THEN
			CALL fl_lee_banco_general(rm_p02.p02_banco_prov)
				RETURNING r_g08.*
			IF r_g08.g08_banco IS NULL THEN	
				CALL fl_mostrar_mensaje('Banco no esta configurado en la compañía.', 'exclamation')
				NEXT FIELD p02_banco_prov
			END IF
			CALL retorna_cod_bco_tra()
			DISPLAY BY NAME r_g08.g08_nombre,
					rm_p02.p02_cod_bco_tra
		ELSE
			CLEAR g08_nombre, p02_cod_bco_tra
			LET rm_p02.p02_cod_bco_tra = NULL
		END IF
	AFTER FIELD p02_cta_prov
		IF rm_p02.p02_cta_prov IS NOT NULL THEN
			IF LENGTH(rm_p02.p02_cta_prov) <> 10 AND
			   LENGTH(rm_p02.p02_cta_prov) <> 11
			THEN
				CALL fl_mostrar_mensaje('Numero de cuenta no tiene completo el numero de digitos. Rellene con CEROS.', 'exclamation')
				NEXT FIELD p02_cta_prov
			END IF
			IF NOT fl_valida_numeros(rm_p02.p02_cta_prov) THEN
				NEXT FIELD p02_cta_prov
			END IF
		END IF
	AFTER FIELD p02_email
		IF rm_p02.p02_email IS NOT NULL THEN
			IF NOT fl_validar_email(rm_p02.p02_email) THEN
				NEXT FIELD p02_email
			END IF
		ELSE
			CLEAR p02_email
		END IF
	AFTER FIELD p02_cupocred_mb
		IF rm_p02.p02_cupocred_mb IS NOT NULL THEN
			IF rg_gen.g00_moneda_alt IS NOT NULL
			OR rg_gen.g00_moneda_alt <> ' ' THEN
			       CALL fl_lee_factor_moneda(rg_gen.g00_moneda_base,
				rg_gen.g00_moneda_alt)
					RETURNING r_mon.*
				CALL fl_retorna_precision_valor(
							rg_gen.g00_moneda_base,
                                                        rm_p02.p02_cupocred_mb)
                                	RETURNING rm_p02.p02_cupocred_mb
                                DISPLAY BY NAME rm_p02.p02_cupocred_mb
				IF r_mon.g14_serial IS NOT NULL THEN
					LET rm_p02.p02_cupocred_ma = 
					rm_p02.p02_cupocred_mb * r_mon.g14_tasa
					IF rm_p02.p02_cupocred_ma IS NULL 
					OR rm_p02.p02_cupocred_ma>9999999999.99
					THEN
						CALL fgl_winmessage(vg_producto,'El cupo de crédito en moneda base está demasiado grande', 'exclamation')
						NEXT FIELD p02_cupocred_mb
					END IF
				END IF
				CALL fl_retorna_precision_valor(
							rg_gen.g00_moneda_base,
                                                        rm_p02.p02_cupocred_ma)
                                	RETURNING rm_p02.p02_cupocred_ma
				DISPLAY BY NAME rm_p02.p02_cupocred_ma
			END IF
		END IF
	AFTER FIELD p02_aux_prov_mb
                IF rm_p02.p02_aux_prov_mb IS NOT NULL THEN
			CALL validar_cuenta(rm_p02.p02_aux_prov_mb, 1)
				RETURNING resul
			IF resul = 1 THEN
				NEXT FIELD p02_aux_prov_mb
			END IF
		ELSE
			CLEAR tit_pro_mb
                END IF
	AFTER FIELD p02_aux_prov_ma
                IF rm_p02.p02_aux_prov_ma IS NOT NULL THEN
			CALL validar_cuenta(rm_p02.p02_aux_prov_ma, 2)
				RETURNING resul
			IF resul = 1 THEN
				NEXT FIELD p02_aux_prov_ma
			END IF
		ELSE
			CLEAR tit_pro_ma
                END IF
	AFTER FIELD p02_aux_ant_mb
                IF rm_p02.p02_aux_ant_mb IS NOT NULL THEN
			CALL validar_cuenta(rm_p02.p02_aux_ant_mb, 3)
				RETURNING resul
			IF resul = 1 THEN
				NEXT FIELD p02_aux_ant_mb
			END IF
		ELSE
			CLEAR  tit_ant_mb
                END IF
	AFTER FIELD p02_aux_ant_ma
                IF rm_p02.p02_aux_ant_ma IS NOT NULL THEN
			CALL validar_cuenta(rm_p02.p02_aux_ant_ma, 4)
				RETURNING resul
			IF resul = 1 THEN
				NEXT FIELD p02_aux_ant_ma
			END IF
		ELSE
			CLEAR  tit_ant_ma
                END IF
	AFTER INPUT
		IF rm_p02.p02_banco_prov IS NOT NULL THEN
			IF rm_p02.p02_tip_cta_prov = 'N' THEN
				CALL fl_mostrar_mensaje('Seleccione el tipo de cuenta proveedor.', 'exclamation')
				CONTINUE INPUT
			END IF
			IF rm_p02.p02_cta_prov IS NULL THEN
				CALL fl_mostrar_mensaje('Digite el número de cuenta del proveedor.', 'exclamation')
				CONTINUE INPUT
			END IF
		END IF
		IF rm_p02.p02_tip_cta_prov = 'N' THEN
			LET rm_p02.p02_tip_cta_prov = NULL
			LET rm_p02.p02_cod_bco_tra  = NULL
		END IF
		IF rm_p01.p01_ret_fuente = 'N' AND rm_p01.p01_ret_impto = 'N'
		AND rm_p01.p01_cont_espe = 'N' THEN
			CALL fl_mostrar_mensaje('No puede dejar sin retenciones al proveedor. Por favor cheque retencion fuente, retencion impuesto o si contribuyente especial.','exclamation')
			NEXT FIELD p01_ret_fuente
		END IF
		IF rm_p01.p01_num_doc IS NOT NULL AND rm_p02.p02_int_ext = 'I'
		THEN
			CALL validar_cedruc(rm_p01.p01_codprov,
						rm_p01.p01_num_doc)
				RETURNING resul
			IF NOT resul THEN
				NEXT FIELD p01_num_doc
			END IF
		END IF
END INPUT

END FUNCTION



FUNCTION validar_cedruc(codprov, cedruc)
DEFINE codprov		LIKE cxpt001.p01_codprov
DEFINE cedruc		LIKE cxpt001.p01_num_doc
DEFINE r_p01		RECORD LIKE cxpt001.*
DEFINE cont		INTEGER
DEFINE resul		SMALLINT

IF rm_p01.p01_tipo_doc = 'C' THEN
	IF LENGTH(cedruc) <> 10 THEN
		CALL fl_mostrar_mensaje('El tipo de documento no corresponde a este número de documento.', 'exclamation')
		RETURN 0
	END IF
END IF
IF rm_p01.p01_tipo_doc = 'R' THEN
	IF LENGTH(cedruc) <> 13 THEN
		CALL fl_mostrar_mensaje('El tipo de documento no corresponde a este número de documento.', 'exclamation')
		RETURN 0
	END IF
END IF
SELECT COUNT(*) INTO cont FROM cxpt001 WHERE p01_num_doc = cedruc
CASE cont
	WHEN 0
		LET resul = 1
	WHEN 1
		INITIALIZE r_p01.* TO NULL
		DECLARE q_cedruc CURSOR FOR
			SELECT * FROM cxpt001 WHERE p01_num_doc = cedruc
		OPEN q_cedruc
		FETCH q_cedruc INTO r_p01.*
		CLOSE q_cedruc
		FREE q_cedruc
		LET resul = 1
		IF r_p01.p01_codprov <> codprov OR codprov IS NULL THEN
			CALL fl_mostrar_mensaje('Este número de identificación ya existe.','exclamation')
			LET resul = 0
		END IF
	OTHERWISE
		CALL fl_mostrar_mensaje('Este número de identificación ya existe varias veces.','exclamation')
		LET resul = 0
END CASE
IF cont <= 1 THEN
	IF rm_p01.p01_tipo_doc = 'C' OR rm_p01.p01_tipo_doc = 'R' THEN
		CALL fl_validar_cedruc_dig_ver(cedruc) RETURNING resul
	END IF
END IF
RETURN resul

END FUNCTION



FUNCTION validar_cuenta(aux_cont, flag)
DEFINE aux_cont		LIKE ctbt010.b10_cuenta
DEFINE flag		SMALLINT
DEFINE r_cta            RECORD LIKE ctbt010.*

CALL fl_lee_cuenta(vg_codcia, aux_cont) RETURNING r_cta.*
IF r_cta.b10_cuenta IS NULL  THEN
	CALL fgl_winmessage(vg_producto,'Cuenta no existe para esta compañía.','exclamation')
	RETURN 1
END IF
CASE flag
	WHEN 1
		DISPLAY r_cta.b10_descripcion TO tit_pro_mb
	WHEN 2
		DISPLAY r_cta.b10_descripcion TO tit_pro_ma
	WHEN 3
		DISPLAY r_cta.b10_descripcion TO tit_ant_mb
	WHEN 4
		DISPLAY r_cta.b10_descripcion TO tit_ant_ma
END CASE
{--
IF auxt_cont = rm_p02.p02_aux_ant_mb
   OR auxt_cont = rm_p02.p02_aux_ant_ma THEN
	CALL fgl_winmessage(vg_producto,'La cuenta de proveedor debe ser distinta del anticípo','exclamation')
	RETURN 1
END IF
--}
IF r_cta.b10_estado = 'B' THEN
	CALL fl_mensaje_estado_bloqueado()
	RETURN 1
END IF
IF r_cta.b10_nivel <> vm_nivel THEN
	CALL fgl_winmessage(vg_producto,'Nivel de cuenta debe ser solo del ultimo.','exclamation')
	RETURN 1
END IF
RETURN 0

END FUNCTION



FUNCTION leer_retencion()
DEFINE resp             CHAR(6)
DEFINE i,j,l,k		SMALLINT
DEFINE r_ord		RECORD LIKE ordt002.*
DEFINE r_c03		RECORD LIKE ordt003.*
DEFINE tipo		LIKE ordt002.c02_tipo_ret
DEFINE porc		LIKE ordt002.c02_porcentaje
DEFINE nom		LIKE ordt002.c02_nombre
DEFINE cod_pago		LIKE cajt091.j91_codigo_pago
DEFINE codprov		LIKE cxpt001.p01_codprov

OPTIONS INPUT WRAP
INITIALIZE r_ord.* TO NULL
LET i        = 1
LET int_flag = 0
CALL set_count(vm_num_ret)
INPUT ARRAY rm_ret WITHOUT DEFAULTS FROM rm_ret.*
	ON KEY(INTERRUPT)
       		LET int_flag = 0
               	CALL fl_mensaje_abandonar_proceso()
	               	RETURNING resp
       		IF resp = 'Yes' THEN
       			LET int_flag = 1
			FOR k = 1 TO vm_num_ret
				LET rm_ret[k].* = rm_ret_aux[k].*
			END FOR
			EXIT INPUT
       	       	END IF	
	ON KEY(F2)
		IF INFIELD(rm_ret[i].p05_porcentaje) THEN
			LET cod_pago = NULL
			CALL fl_ayuda_retenciones(vg_codcia, cod_pago, 'A')
				RETURNING tipo, porc, nom
			IF tipo IS NOT NULL THEN
				LET rm_ret[i].p05_tipo_ret   = tipo
				LET rm_ret[i].p05_porcentaje = porc
				LET rm_ret[i].tit_tipo_ret   = nom
				DISPLAY rm_ret[i].* TO rm_ret[j].*
			END IF
		END IF
		IF INFIELD(rm_ret[i].p05_codigo_sri) THEN
			LET codprov = rm_p01.p01_codprov
			IF rm_p01.p01_codprov IS NULL THEN
				LET codprov = 1
			END IF
			CALL fl_ayuda_codigos_sri(vg_codcia,
					rm_ret[i].p05_tipo_ret,
					rm_ret[i].p05_porcentaje, 'A',
					codprov, 'P')
				RETURNING r_c03.c03_codigo_sri,
					  r_c03.c03_concepto_ret,
					  r_c03.c03_fecha_ini_porc
			IF r_c03.c03_codigo_sri IS NOT NULL THEN
				LET rm_ret[i].p05_codigo_sri =
							r_c03.c03_codigo_sri
				LET rm_ret[i].p05_fecha_ini_porc =
							r_c03.c03_fecha_ini_porc
				DISPLAY rm_ret[i].p05_codigo_sri TO
					rm_ret[j].p05_codigo_sri
				DISPLAY rm_ret[i].p05_fecha_ini_porc TO
					rm_ret[j].p05_fecha_ini_porc
				DISPLAY BY NAME r_c03.c03_concepto_ret
			END IF
		END IF
		LET int_flag = 0
	BEFORE ROW
       		LET i = arr_curr()
       		LET j = scr_line()
		CALL fl_lee_codigos_sri(vg_codcia, rm_ret[i].p05_tipo_ret,
					rm_ret[i].p05_porcentaje,
					rm_ret[i].p05_codigo_sri,
					rm_ret[i].p05_fecha_ini_porc)
			RETURNING r_c03.*
		DISPLAY BY NAME r_c03.c03_concepto_ret
		DISPLAY i TO num_rows
		DISPLAY vm_num_ret TO max_rows
	AFTER FIELD p05_tipo_ret
		IF rm_ret[i].p05_tipo_ret IS NOT NULL THEN
			IF rm_ret[i].p05_porcentaje IS NULL THEN
				NEXT FIELD p05_porcentaje
			END IF
		END IF
	BEFORE FIELD p05_porcentaje
		IF rm_ret[i].p05_porcentaje IS NOT NULL THEN
			IF rm_ret[i].p05_tipo_ret IS NULL THEN
				NEXT FIELD p05_tipo_ret
			END IF
		END IF
	AFTER FIELD p05_porcentaje, p05_tipo_ret
		IF rm_ret[i].p05_porcentaje IS NULL THEN
			CONTINUE INPUT
		END IF
		IF rm_ret[i].p05_tipo_ret IS NULL THEN
			CONTINUE INPUT
		END IF
		CALL descripcion_retencion(rm_ret[i].p05_tipo_ret,
					rm_ret[i].p05_porcentaje)
			RETURNING rm_ret[i].tit_tipo_ret
		DISPLAY rm_ret[i].tit_tipo_ret TO rm_ret[j].tit_tipo_ret
		CALL fl_lee_tipo_retencion(vg_codcia, rm_ret[i].p05_tipo_ret,
				rm_ret[i].p05_porcentaje)
			RETURNING r_ord.*
		IF r_ord.c02_compania IS NULL THEN
			CALL fgl_winmessage(vg_producto,'No existe ese porcentaje de retención.','exclamation')
			INITIALIZE rm_ret[i].* TO NULL
			DISPLAY rm_ret[i].* TO rm_ret[j].*
			NEXT FIELD p05_porcentaje
		END IF
		IF rm_p01.p01_ret_fuente = 'N'
		AND rm_ret[i].p05_tipo_ret = 'F' THEN
			CALL fgl_winmessage(vg_producto,'El proveedor no esta configurado para retención en la fuente.','exclamation')
			INITIALIZE rm_ret[i].* TO NULL
			DISPLAY rm_ret[i].* TO rm_ret[j].*
			NEXT FIELD p05_porcentaje
		END IF
		IF rm_p01.p01_ret_impto = 'N'
		AND rm_ret[i].p05_tipo_ret = 'I' THEN
			CALL fgl_winmessage(vg_producto,'El proveedor no esta configurado para retención del impuesto.','exclamation')
			INITIALIZE rm_ret[i].* TO NULL
			DISPLAY rm_ret[i].* TO rm_ret[j].*
			NEXT FIELD p05_porcentaje
		END IF
	AFTER FIELD p05_codigo_sri
		IF rm_ret[i].p05_codigo_sri IS NOT NULL THEN
			CALL fl_lee_codigos_sri(vg_codcia,
						rm_ret[i].p05_tipo_ret,
						rm_ret[i].p05_porcentaje,
						rm_ret[i].p05_codigo_sri,
						rm_ret[i].p05_fecha_ini_porc)
				RETURNING r_c03.*
			IF r_c03.c03_compania IS NULL THEN
				CALL fl_mostrar_mensaje('No existe configurado este codigo del SRI.', 'exclamation')
				NEXT FIELD p05_codigo_sri
			END IF
			IF r_c03.c03_estado <> 'A' THEN
				CALL fl_mostrar_mensaje('El codigo del SRI esta bloqueado.', 'exclamation')
				NEXT FIELD p05_codigo_sri
			END IF
			DISPLAY BY NAME r_c03.c03_concepto_ret
		ELSE
			CLEAR c03_concepto_ret
		END IF
	AFTER INPUT
		LET vm_num_ret = arr_count()
		FOR l = 1 TO vm_num_ret - 1
			FOR k = l + 1 TO vm_num_ret
				IF (rm_ret[l].p05_tipo_ret =
				    rm_ret[k].p05_tipo_ret) AND
				   (rm_ret[l].p05_porcentaje =
				    rm_ret[k].p05_porcentaje) AND
				   (rm_ret[l].p05_codigo_sri =
				    rm_ret[k].p05_codigo_sri) AND
				   (rm_ret[l].p05_fecha_ini_porc =
				    rm_ret[k].p05_fecha_ini_porc)
				THEN
					CALL fl_mostrar_mensaje('Existen un mismo tipo de porcentaje y codigo del SRI mas de una vez en el detalle.', 'exclamation')
					CONTINUE INPUT
				END IF
			END FOR
		END FOR
		FOR k = 1 TO vm_num_ret
			LET rm_ret_aux[k].* = rm_ret[k].*
		END FOR
END INPUT

END FUNCTION



FUNCTION control_grabar()
DEFINE correo		LIKE cxpt002.p02_email
DEFINE num_aux		INTEGER
DEFINE i, lim		SMALLINT

IF vm_num_ret = 0 AND vm_flag_mant <> 'M' THEN
	CALL fgl_winmessage(vg_producto,'Debe ingresar primero las retenciones del proveedor.','exclamation')
	RETURN
END IF
LET rm_p02.p02_email = rm_p02.p02_email CLIPPED
LET lim              = LENGTH(rm_p02.p02_email) 
LET correo           = " "
FOR i = 1 TO lim
	IF rm_p02.p02_email[i, i] = "" OR rm_p02.p02_email[i, i] = "€" OR
	   rm_p02.p02_email[i, i] = " "
	THEN
		LET correo = correo CLIPPED, ""
	ELSE
		LET correo = correo CLIPPED, rm_p02.p02_email[i, i]
	END IF
END FOR
LET rm_p02.p02_email = correo CLIPPED
IF rm_p01.p01_codprov IS NULL THEN
	LET num_aux            = 0 
	LET rm_p01.p01_fecing  = CURRENT
	LET rm_p02.p02_fecing = rm_p01.p01_fecing
	SELECT MAX(p01_codprov) INTO rm_p01.p01_codprov FROM cxpt001
	IF rm_p01.p01_codprov IS NOT NULL THEN
		LET rm_p01.p01_codprov = rm_p01.p01_codprov + 1
	ELSE
		LET rm_p01.p01_codprov = 1
	END IF
	LET rm_p02.p02_codprov = rm_p01.p01_codprov
	INSERT INTO cxpt001 VALUES (rm_p01.*)
	LET num_aux = SQLCA.SQLERRD[6] 
	INSERT INTO cxpt002 VALUES (rm_p02.*)
	CALL grabar_retencion(rm_p02.p02_codprov)
	IF vm_num_rows = vm_max_rows THEN
		LET vm_num_rows = 1
	ELSE
		LET vm_num_rows = vm_num_rows + 1
	END IF
	LET vm_row_current = vm_num_rows
	LET vm_r_rows[vm_row_current] = num_aux
	DISPLAY rm_p01.p01_codprov TO tit_codigo_pro
	DISPLAY rm_p01.p01_nomprov TO tit_nombre_pro
	DISPLAY BY NAME rm_p01.p01_codprov, rm_p01.p01_fecing
	CALL mostrar_registro(vm_r_rows[vm_num_rows])	
	CALL muestra_contadores(vm_row_current, vm_num_rows)
	CALL fl_mensaje_registro_ingresado()
ELSE
	IF vm_flag_mant = 'M' THEN
		UPDATE cxpt001 SET p01_nomprov      = rm_p01.p01_nomprov, 
				   p01_personeria   = rm_p01.p01_personeria,
				   p01_num_doc      = rm_p01.p01_num_doc,
				   p01_tipo_doc     = rm_p01.p01_tipo_doc,
				   p01_num_aut      = rm_p01.p01_num_aut,
				   p01_serie_comp   = rm_p01.p01_serie_comp,
				   p01_direccion1   = rm_p01.p01_direccion1, 
				   p01_telefono1    = rm_p01.p01_telefono1, 
				   p01_tipo_prov    = rm_p01.p01_tipo_prov,
				   p01_direccion2   = rm_p01.p01_direccion2, 
				   p01_telefono2    = rm_p01.p01_telefono2,
				   p01_fax1         = rm_p01.p01_fax1,
				   p01_fax2         = rm_p01.p01_fax2,
				   p01_casilla      = rm_p01.p01_casilla,
				   p01_pais         = rm_p01.p01_pais,
				   p01_ciudad       = rm_p01.p01_ciudad,
				   p01_rep_legal    = rm_p01.p01_rep_legal,
				   p01_ret_fuente   = rm_p01.p01_ret_fuente,
				   p01_ret_impto    = rm_p01.p01_ret_impto,
				   p01_cont_espe    = rm_p01.p01_cont_espe
			WHERE CURRENT OF q_up
		IF rm_p02.p02_codprov IS NOT NULL THEN
			UPDATE cxpt002 SET
				p02_contacto     = rm_p02.p02_contacto,
				p02_referencia   = rm_p02.p02_referencia,
				p02_credit_dias  = rm_p02.p02_credit_dias,
				p02_cupocred_mb  = rm_p02.p02_cupocred_mb,
				p02_descuento    = rm_p02.p02_descuento,
				p02_recargo      = rm_p02.p02_recargo,
				p02_dias_demora  = rm_p02.p02_dias_demora,
			  	p02_dias_seguri  = rm_p02.p02_dias_seguri,
				p02_int_ext      = rm_p02.p02_int_ext,
				p02_aux_prov_mb  = rm_p02.p02_aux_prov_mb,
				p02_aux_prov_ma  = rm_p02.p02_aux_prov_ma,
				p02_aux_ant_mb   = rm_p02.p02_aux_ant_mb,
				p02_aux_ant_ma   = rm_p02.p02_aux_ant_ma,
				p02_banco_prov   = rm_p02.p02_banco_prov,
				p02_cod_bco_tra  = rm_p02.p02_cod_bco_tra,
				p02_tip_cta_prov = rm_p02.p02_tip_cta_prov,
				p02_cta_prov     = rm_p02.p02_cta_prov,
				p02_email        = rm_p02.p02_email
			      WHERE CURRENT OF q_up2
		ELSE
			LET rm_p02.p02_compania  = vg_codcia
			LET rm_p02.p02_localidad = vg_codloc
			LET rm_p02.p02_codprov   = rm_p01.p01_codprov
			INSERT INTO cxpt002 VALUES (rm_p02.*)
		END IF
		CALL grabar_retencion(rm_p01.p01_codprov)
		LET vm_flag_mant = 'I'
	END IF
	IF vm_flag_mant = 'C' THEN
		CALL grabar_retencion(rm_p01.p01_codprov)
		CALL fl_mensaje_registro_modificado()
		LET vm_flag_mant = 'I'
	END IF
END IF

END FUNCTION



FUNCTION grabar_retencion(codprov)
DEFINE i		SMALLINT
DEFINE codprov		LIKE cxpt001.p01_codprov

DELETE FROM cxpt005 WHERE p05_compania = vg_codcia
		      AND p05_codprov  = codprov
LET rm_p05.p05_compania = vg_codcia
LET rm_p05.p05_codprov  = rm_p01.p01_codprov
FOR i = 1 TO vm_num_ret
        INSERT INTO cxpt005
		VALUES (rm_p05.p05_compania, rm_p05.p05_codprov,
			rm_ret[i].p05_tipo_ret, rm_ret[i].p05_porcentaje,
			rm_ret[i].p05_codigo_sri, rm_ret[i].p05_fecha_ini_porc)
END FOR

END FUNCTION



FUNCTION muestra_siguiente_registro()

LET vm_flag_ret = 0
IF vm_row_current < vm_num_rows THEN
	LET vm_row_current = vm_row_current + 1
END IF
CALL muestra_contadores(vm_row_current, vm_num_rows)
CALL mostrar_registro(vm_r_rows[vm_row_current])

END FUNCTION



FUNCTION muestra_anterior_registro()

LET vm_flag_ret = 0
IF vm_row_current > 1 THEN
	LET vm_row_current = vm_row_current - 1
END IF
CALL muestra_contadores(vm_row_current, vm_num_rows)
CALL mostrar_registro(vm_r_rows[vm_row_current])

END FUNCTION



FUNCTION muestra_contadores(row_current, num_rows)
DEFINE row_current	SMALLINT
DEFINE num_rows		SMALLINT
                                                                                
DISPLAY "        " TO tit_estado_pro
CLEAR tit_estado_pro
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
DEFINE r_g08		RECORD LIKE gent008.*
DEFINE num_registro	INTEGER

IF vm_num_rows > 0 THEN
	SELECT * INTO rm_p01.* FROM cxpt001 WHERE ROWID = num_registro	
	IF STATUS = NOTFOUND THEN
		CALL fgl_winmessage (vg_producto,'No existe registro con índice: ' || vm_row_current,'exclamation')
		RETURN
	END IF
	DISPLAY BY NAME rm_p01.p01_codprov, rm_p01.p01_nomprov,
			rm_p01.p01_personeria, rm_p01.p01_num_doc,
			rm_p01.p01_tipo_doc, rm_p01.p01_direccion1, 
			rm_p01.p01_num_aut, rm_p01.p01_serie_comp,
			rm_p01.p01_telefono1, rm_p01.p01_tipo_prov,
			rm_p01.p01_direccion2, rm_p01.p01_telefono2,
			rm_p01.p01_fax1, rm_p01.p01_fax2, rm_p01.p01_casilla,
			rm_p01.p01_pais, rm_p01.p01_ciudad,
			rm_p01.p01_rep_legal, rm_p01.p01_ret_fuente,
			rm_p01.p01_ret_impto, rm_p01.p01_cont_espe,
			rm_p01.p01_usuario, rm_p01.p01_fecing
	CALL fl_lee_pais(rm_p01.p01_pais) RETURNING r_pai.*
	DISPLAY r_pai.g30_nombre TO tit_pais
	CALL fl_lee_ciudad(rm_p01.p01_ciudad) RETURNING r_ciu.*
	DISPLAY r_ciu.g31_nombre TO tit_ciudad
	CALL fl_lee_subtipo_entidad('TP',rm_p01.p01_tipo_prov) RETURNING r_car.*
        DISPLAY r_car.g12_nombre TO tit_tipo_pro
	SELECT * INTO rm_p02.* FROM cxpt002
		WHERE p02_compania  = vg_codcia
		  AND p02_localidad = vg_codloc
		  AND p02_codprov   = rm_p01.p01_codprov
	IF STATUS = NOTFOUND THEN
		CALL muestra_estado()
		RETURN
	END IF
	DISPLAY rm_p01.p01_codprov TO tit_codigo_pro
	DISPLAY rm_p01.p01_nomprov TO tit_nombre_pro
	DISPLAY BY NAME rm_p02.p02_contacto, rm_p02.p02_referencia,
			rm_p02.p02_credit_dias, rm_p02.p02_email,
			rm_p02.p02_cupocred_mb, rm_p02.p02_cupocred_ma,
			rm_p02.p02_descuento, rm_p02.p02_recargo,
			rm_p02.p02_dias_demora, rm_p02.p02_dias_seguri,
			rm_p02.p02_int_ext, rm_p02.p02_aux_prov_mb,
			rm_p02.p02_aux_prov_ma, rm_p02.p02_aux_ant_mb,
			rm_p02.p02_aux_ant_ma, rm_p02.p02_banco_prov,
			rm_p02.p02_tip_cta_prov, rm_p02.p02_cta_prov,
			rm_p02.p02_cod_bco_tra
	CALL fl_lee_cuenta(vg_codcia,rm_p02.p02_aux_prov_mb)
                RETURNING r_cta.*
        DISPLAY r_cta.b10_descripcion TO tit_pro_mb
        CALL fl_lee_cuenta(vg_codcia,rm_p02.p02_aux_prov_ma)
                RETURNING r_cta.*
        DISPLAY r_cta.b10_descripcion TO tit_pro_ma
        CALL fl_lee_cuenta(vg_codcia,rm_p02.p02_aux_ant_mb)
                RETURNING r_cta.*
        DISPLAY r_cta.b10_descripcion TO tit_ant_mb
        CALL fl_lee_cuenta(vg_codcia,rm_p02.p02_aux_ant_ma)
                RETURNING r_cta.*
        DISPLAY r_cta.b10_descripcion TO tit_ant_ma
	CALL fl_lee_banco_general(rm_p02.p02_banco_prov) RETURNING r_g08.*
	DISPLAY BY NAME r_g08.g08_nombre
	IF rm_p02.p02_tip_cta_prov IS NULL THEN
		LET rm_p02.p02_tip_cta_prov = 'N'
		DISPLAY BY NAME rm_p02.p02_tip_cta_prov
	END IF
	CALL muestra_estado()
	CALL cargar_retencion()
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
BEGIN WORK
WHENEVER ERROR CONTINUE
DECLARE q_ba CURSOR FOR SELECT * FROM cxpt001
	WHERE ROWID = vm_r_rows[vm_row_current]
	FOR UPDATE
OPEN q_ba
FETCH q_ba INTO rm_p01.*
IF STATUS < 0 THEN
	ROLLBACK WORK
	CALL fl_mensaje_bloqueo_otro_usuario()
	WHENEVER ERROR STOP
	RETURN
END IF	
WHENEVER ERROR STOP
CALL fl_mensaje_seguro_ejecutar_proceso()
	RETURNING confir
IF confir = 'Yes' THEN
	LET int_flag = 1
	CALL bloquea_activa_registro()
END IF
COMMIT WORK

END FUNCTION



FUNCTION bloquea_activa_registro()
DEFINE estado	CHAR(1)

IF rm_p01.p01_estado = 'A' THEN
	DISPLAY 'BLOQUEADO' TO tit_estado_pro
	LET estado = 'B'
ELSE 
	DISPLAY 'ACTIVO' TO tit_estado_pro
	LET estado = 'A'
END IF
DISPLAY estado TO p01_estado
UPDATE cxpt001 SET p01_estado = estado WHERE CURRENT OF q_ba
LET rm_p01.p01_estado = estado

END FUNCTION



FUNCTION muestra_estado()

IF rm_p01.p01_estado = 'A' THEN
	DISPLAY 'ACTIVO' TO tit_estado_pro
ELSE
	DISPLAY 'BLOQUEADO' TO tit_estado_pro
END IF
DISPLAY BY NAME rm_p01.p01_estado

END FUNCTION



FUNCTION mostrar_botones_retencion()

DISPLAY 'Porc.'       TO tit_col1
DISPLAY 'T'           TO tit_col2
DISPLAY 'Descripción' TO tit_col3
DISPLAY 'SRI'         TO tit_col4
DISPLAY 'Fecha Ini.'  TO tit_col5

END FUNCTION



FUNCTION muestra_detalle_ret()
DEFINE i,j		SMALLINT

CALL set_count(vm_num_ret)
DISPLAY ARRAY rm_ret TO rm_ret.*
	BEFORE ROW
		LET i = arr_curr()
		LET j = scr_line()
	BEFORE DISPLAY
		--#CALL dialog.keysetlabel("ACCEPT","")
	AFTER DISPLAY
		CONTINUE DISPLAY
	ON KEY(INTERRUPT)
		EXIT DISPLAY
END DISPLAY

END FUNCTION



FUNCTION retorna_cod_bco_tra()
DEFINE cod_bco		LIKE cxpt002.p02_cod_bco_tra

LET cod_bco = NULL
SELECT p06_cod_bco_tra
	INTO cod_bco
	FROM cxpt006
	WHERE p06_compania = rm_p02.p02_compania
	  AND p06_banco    = rm_p02.p02_banco_prov
LET rm_p02.p02_cod_bco_tra = cod_bco

END FUNCTION



FUNCTION fl_validar_email(email)
DEFINE email		VARCHAR(100)

{
--IF email[1, 1] < '0' OR email[1, 1] > '9' THEN
LET lim = LENGTH(email)
FOR i = 1 TO lim
	--IF 
END FOR
}
RETURN 1

END FUNCTION
