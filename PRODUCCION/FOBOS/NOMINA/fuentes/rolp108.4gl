--------------------------------------------------------------------------------
-- Titulo           : rolp108.4gl - Mantenimiento de Trabajadores.
-- Elaboracion      : 02-nov-2001
-- Autor            : NPC
-- Formato Ejecucion: fglrun rolp108 base módulo compañía [trabajador]
-- Ultima Correccion: 
-- Motivo Correccion: 
--------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_nuevoprog	VARCHAR(100)
DEFINE rm_n30		RECORD LIKE rolt030.*
DEFINE rm_n31		RECORD LIKE rolt031.*
DEFINE vm_nivel		LIKE ctbt001.b01_nivel
DEFINE vm_r_rows	ARRAY [1000] OF INTEGER
DEFINE rm_car		ARRAY [50] OF RECORD
				n31_tipo_carga	LIKE rolt031.n31_tipo_carga,
				tit_carga	CHAR(8),
				n31_nombres	LIKE rolt031.n31_nombres,
				n31_fecha_nacim	LIKE rolt031.n31_fecha_nacim
			END RECORD
DEFINE rm_car_aux	ARRAY [50] OF RECORD
				n31_tipo_carga	LIKE rolt031.n31_tipo_carga,
				tit_carga	CHAR(8),
				n31_nombres	LIKE rolt031.n31_nombres,
				n31_fecha_nacim	LIKE rolt031.n31_fecha_nacim
			END RECORD
DEFINE vm_num_rows	INTEGER
DEFINE vm_row_current	INTEGER
DEFINE vm_max_rows	INTEGER
DEFINE vm_num_car	INTEGER
DEFINE vm_max_car	INTEGER
DEFINE vm_flag_carga	SMALLINT
DEFINE vm_flag_mant	CHAR(1)



MAIN

DEFER QUIT 
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/rolp108.err')
CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 3 AND num_args() <> 4 THEN   -- Validar # parámetros correcto
	CALL fl_mostrar_mensaje( 'Número de parámetros incorrecto.', 'stop')
	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_proceso = 'rolp108'
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
LET vm_max_rows	= 1000
LET vm_max_car	= 50
OPEN WINDOW wf AT 3,2 WITH 21 ROWS, 80 COLUMNS
    ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE LAST - 1,BORDER,
	      MESSAGE LINE LAST - 1)
OPTIONS INPUT WRAP,
	ACCEPT KEY	F12
OPEN FORM f_rol FROM "../forms/rolf108_1"
DISPLAY FORM f_rol
SELECT MAX(b01_nivel) INTO vm_nivel FROM ctbt001
IF vm_nivel IS NULL THEN
	CALL fl_mostrar_mensaje('No existe ningun nivel de cuenta configurado en la compañía.','stop')
	EXIT PROGRAM
END IF
INITIALIZE rm_n30.*, rm_n31.* TO NULL
FOR i = 1 TO vm_max_car
	INITIALIZE rm_car[i].*, rm_car_aux[i].* TO NULL
END FOR
LET vm_num_rows    = 0
LET vm_row_current = 0
LET vm_num_car     = 0
LET vm_flag_carga  = 1
CALL muestra_contadores(vm_row_current, vm_num_rows)
MENU 'OPCIONES'
	BEFORE MENU
		HIDE OPTION 'Avanzar'
		HIDE OPTION 'Retroceder'
		HIDE OPTION 'Modificar'
		HIDE OPTION 'Bloquear/Activar'
		HIDE OPTION 'Cargas'
		HIDE OPTION 'Grabar'
		IF num_args() = 4 THEN
			LET vm_flag_carga = 0
			HIDE OPTION 'Ingresar'
			HIDE OPTION 'Consultar'
			SHOW OPTION 'Cargas'
			CALL control_consulta()
			IF vm_num_rows = 0 THEN
				EXIT PROGRAM
			END IF
		END IF
	COMMAND KEY('I') 'Ingresar' 'Ingresar nuevos registros. '
		CALL control_ingreso()
		IF vm_num_rows = 1 THEN
			SHOW OPTION 'Modificar'
			SHOW OPTION 'Bloquear/Activar'
			SHOW OPTION 'Cargas'
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
			SHOW OPTION 'Cargas'
			HIDE OPTION 'Avanzar'
			HIDE OPTION 'Retroceder'
			IF vm_num_rows = 0 THEN
				HIDE OPTION 'Modificar'
				HIDE OPTION 'Bloquear/Activar'
				HIDE OPTION 'Cargas'
			END IF
		ELSE
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Modificar'
			SHOW OPTION 'Bloquear/Activar'
			SHOW OPTION 'Cargas'
		END IF
		IF vm_row_current <= 1 THEN
                        HIDE OPTION 'Retroceder'
                END IF
		HIDE OPTION 'Grabar'
     	COMMAND KEY('F') 'Cargas' 'Cargas familiares del Trabajador. '
		IF num_args() <> 4 THEN
			CALL control_cargas('I')
			IF vm_flag_mant = 'C' THEN
				SHOW OPTION 'Grabar'
			ELSE
				HIDE OPTION 'Grabar'
			END IF
		ELSE
			CALL control_cargas('C')
		END IF
     	COMMAND KEY('G') 'Grabar' 'Graba el registro corriente. '
		BEGIN WORK
			CALL control_grabar()
		COMMIT WORK
		HIDE OPTION 'Grabar'
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
DEFINE r_cia		RECORD LIKE rolt000.*
DEFINE r_mon		RECORD LIKE gent013.*

CALL fl_retorna_usuario()
LET vm_flag_carga = 0
INITIALIZE rm_n30.*, rm_n31.* TO NULL
CLEAR n30_cod_trab, n30_estado, tit_estado_tra, tit_pais, tit_ciudad,
	tit_departamento, tit_cargo, tit_mon_bas, tit_banco, n13_descripcion,
	n17_descripcion
CALL fl_lee_parametro_general_roles() RETURNING r_cia.*
CALL fl_lee_moneda(r_cia.n00_moneda_pago) RETURNING r_mon.*
LET rm_n30.n30_compania     = vg_codcia
LET rm_n30.n30_estado       = 'A'
LET rm_n30.n30_sexo         = 'M'
LET rm_n30.n30_tipo_doc_id  = 'C'
LET rm_n30.n30_est_civil    = 'S'
LET rm_n30.n30_fecha_ing    = TODAY
LET rm_n30.n30_tipo_rol     = 'Q'
LET rm_n30.n30_tipo_pago    = 'E'
LET rm_n30.n30_mon_sueldo   = r_cia.n00_moneda_pago
LET rm_n30.n30_factor_hora  = 0
LET rm_n30.n30_tipo_cta_tra = 'N'
LET rm_n30.n30_tipo_trab    = 'N'
LET rm_n30.n30_tipo_contr   = 'F'
LET rm_n30.n30_desc_seguro  = 'S'
LET rm_n30.n30_desc_impto   = 'N'
IF vg_codloc <> 3 THEN
	LET rm_n30.n30_fon_res_anio = 'S'
ELSE
	LET rm_n30.n30_fon_res_anio = 'N'
END IF
LET rm_n30.n30_usuario      = vg_usuario
LET rm_n30.n30_fecing       = CURRENT
LET rm_n31.n31_compania     = vg_codcia
LET rm_n31.n31_usuario      = rm_n30.n30_usuario
LET rm_n31.n31_fecing       = rm_n30.n30_fecing
CALL fl_lee_moneda(rm_n30.n30_mon_sueldo) RETURNING r_mon.*
IF r_mon.g13_moneda IS NULL THEN
        CALL fl_mostrar_mensaje('No existe ninguna moneda base.','stop')
        EXIT PROGRAM
END IF
DISPLAY r_mon.g13_nombre TO tit_mon_bas
CALL muestra_estado()
LET vm_flag_mant = 'I'
CALL leer_datos()
IF int_flag THEN
	CALL muestra_reg_salir()
	RETURN
END IF
IF vm_num_rows = vm_max_rows THEN
	LET vm_num_rows = 1
ELSE
	LET vm_num_rows = vm_num_rows + 1
END IF
LET vm_row_current = vm_num_rows
BEGIN WORK
	CALL control_grabar()
COMMIT WORK
CALL fl_mensaje_registro_ingresado()

END FUNCTION



FUNCTION control_modificacion()
DEFINE sueldo		LIKE rolt030.n30_sueldo_mes

IF vm_num_rows = 0 THEN
	CALL fl_mensaje_consultar_primero()
	RETURN
END IF
CALL mostrar_registro(vm_r_rows[vm_row_current])
IF rm_n30.n30_estado = 'I' THEN
	CALL fl_mensaje_estado_bloqueado()
	RETURN
END IF
BEGIN WORK
WHENEVER ERROR CONTINUE
DECLARE q_up CURSOR FOR
	SELECT * FROM rolt030
		WHERE ROWID = vm_r_rows[vm_row_current]
	FOR UPDATE
OPEN q_up
FETCH q_up INTO rm_n30.*
IF STATUS < 0 THEN
	ROLLBACK WORK
	CALL fl_mensaje_bloqueo_otro_usuario()
	WHENEVER ERROR STOP
	RETURN
END IF
DECLARE q_up2 CURSOR FOR
	SELECT * FROM rolt031
		WHERE n31_compania = rm_n31.n31_compania 
		  AND n31_cod_trab = rm_n30.n30_cod_trab
		FOR UPDATE
OPEN q_up2
FETCH q_up2 INTO rm_n31.*
IF STATUS < 0 THEN
	ROLLBACK WORK
	CALL fl_mensaje_bloqueo_otro_usuario()
	WHENEVER ERROR STOP
	RETURN
END IF
WHENEVER ERROR STOP
IF rm_n30.n30_tipo_cta_tra IS NULL THEN
	LET rm_n30.n30_tipo_cta_tra = 'N'
END IF
LET sueldo       = rm_n30.n30_sueldo_mes
LET vm_flag_mant = 'M'
CALL leer_datos()
IF int_flag THEN
	ROLLBACK WORK
	CALL muestra_reg_salir()
	RETURN
END IF
LET rm_n31.n31_compania = vg_codcia
LET rm_n31.n31_cod_trab = rm_n30.n30_cod_trab
CALL control_grabar()
COMMIT WORK
--IF rm_n30.n30_sueldo_mes <> sueldo THEN
	CALL verificar_proceso_activo_nomina()
--END IF
CALL muestra_reg()
CALL fl_mensaje_registro_modificado()

END FUNCTION



FUNCTION control_consulta()
DEFINE codi_aux         LIKE rolt030.n30_cod_trab
DEFINE nomi_aux         LIKE rolt030.n30_nombres
DEFINE codp_aux         LIKE gent030.g30_pais
DEFINE nomp_aux         LIKE gent030.g30_nombre
DEFINE codc_aux         LIKE gent031.g31_ciudad
DEFINE nomc_aux         LIKE gent031.g31_nombre
DEFINE codd_aux         LIKE gent034.g34_cod_depto
DEFINE nomd_aux         LIKE gent034.g34_nombre
DEFINE codg_aux         LIKE gent035.g35_cod_cargo
DEFINE nomg_aux         LIKE gent035.g35_nombre
DEFINE mone_aux         LIKE gent013.g13_moneda
DEFINE nomm_aux         LIKE gent013.g13_nombre
DEFINE deci_aux         LIKE gent013.g13_decimales
DEFINE codb_aux         LIKE gent008.g08_banco
DEFINE nomb_aux         LIKE gent008.g08_nombre
DEFINE tipo_aux         LIKE gent009.g09_tipo_cta
DEFINE num_aux          LIKE gent009.g09_numero_cta
DEFINE r_n13		RECORD LIKE rolt013.*
DEFINE r_n17		RECORD LIKE rolt017.*
DEFINE query		VARCHAR(1200)
DEFINE expr_sql		VARCHAR(800)
DEFINE num_reg		INTEGER

LET vm_flag_mant  = 'C'
LET vm_flag_carga = 0
INITIALIZE codi_aux, codp_aux, codc_aux, codd_aux, codg_aux, mone_aux, codb_aux
	TO NULL
CLEAR FORM
LET int_flag = 0
IF num_args() = 3 THEN
	CONSTRUCT BY NAME expr_sql ON n30_cod_trab, n30_estado, n30_nombres,
	n30_domicilio, n30_telef_domic, n30_telef_fami, n30_num_doc_id,
	n30_tipo_doc_id, n30_lib_militar, n30_sexo, n30_pais_nac,n30_ciudad_nac,
	n30_fecha_nacim, n30_est_civil, n30_cod_depto, n30_cod_cargo,
	n30_fecha_ing, n30_fecha_reing, n30_fecha_sal, n30_tipo_rol,
	n30_tipo_pago, n30_bco_empresa, n30_cta_empresa, n30_tipo_cta_tra,
	n30_cta_trabaj, n30_mon_sueldo, n30_sueldo_mes, n30_factor_hora,
	n30_tipo_trab, n30_tipo_contr, n30_refer_fami, n30_cod_seguro,
	n30_carnet_seg, n30_desc_seguro, n30_sub_activ, n30_desc_impto,
	n30_sectorial, n30_fec_jub, n30_val_jub_pat,n30_fon_res_anio,n30_usuario
	ON KEY(F2)
		IF INFIELD(n30_cod_trab) THEN
                        CALL fl_ayuda_codigo_empleado(vg_codcia)
                                RETURNING codi_aux, nomi_aux
                        LET int_flag = 0
                        IF codi_aux IS NOT NULL THEN
                                DISPLAY codi_aux TO n30_cod_trab
                                DISPLAY nomi_aux TO n30_nombres
                        END IF
                END IF
		IF INFIELD(n30_pais_nac) THEN
                        CALL fl_ayuda_pais()
                                RETURNING codp_aux, nomp_aux
                        LET int_flag = 0
                        IF codp_aux IS NOT NULL THEN
                                DISPLAY codp_aux TO n30_pais_nac
                                DISPLAY nomp_aux TO tit_pais
                        END IF
                END IF
		IF INFIELD(n30_ciudad_nac) THEN
                        CALL fl_ayuda_ciudad(codp_aux)
                                RETURNING codc_aux, nomc_aux
                        LET int_flag = 0
                        IF codc_aux IS NOT NULL THEN
                                DISPLAY codc_aux TO n30_ciudad_nac
                                DISPLAY nomc_aux TO tit_ciudad
                        END IF
                END IF
		IF INFIELD(n30_cod_depto) THEN
                        CALL fl_ayuda_departamentos(vg_codcia)
                                RETURNING codd_aux, nomd_aux
                        LET int_flag = 0
                        IF codd_aux IS NOT NULL THEN
                                DISPLAY codd_aux TO n30_cod_depto
                                DISPLAY nomd_aux TO tit_departamento
                        END IF
                END IF
		IF INFIELD(n30_cod_cargo) THEN
                        CALL fl_ayuda_cargos(vg_codcia)
                                RETURNING codg_aux, nomg_aux
                        LET int_flag = 0
                        IF codg_aux IS NOT NULL THEN
                                DISPLAY codg_aux TO n30_cod_cargo
                                DISPLAY nomg_aux TO tit_cargo
                        END IF
                END IF
		IF INFIELD(n30_mon_sueldo) THEN
                	CALL fl_ayuda_monedas()
				RETURNING mone_aux, nomm_aux, deci_aux
                	LET int_flag = 0
                	IF mone_aux IS NOT NULL THEN
                        	DISPLAY mone_aux TO n30_mon_sueldo
                        	DISPLAY nomm_aux TO tit_mon_bas
                	END IF
		END IF
		IF INFIELD(n30_bco_empresa) THEN
                        CALL fl_ayuda_cuenta_banco(vg_codcia, 'T')
                                RETURNING codb_aux, nomb_aux, tipo_aux, num_aux
                        LET int_flag = 0
                        IF codb_aux IS NOT NULL THEN
                                DISPLAY codb_aux TO n30_bco_empresa
                                DISPLAY nomb_aux TO tit_banco
				DISPLAY num_aux TO n30_cta_empresa
                        END IF
                END IF
		IF INFIELD(n30_cod_seguro) THEN
			CALL fl_ayuda_seguros('A')
				RETURNING r_n13.n13_cod_seguro,
					  r_n13.n13_descripcion
			LET int_flag = 0
			IF r_n13.n13_cod_seguro IS NOT NULL THEN
				DISPLAY r_n13.n13_cod_seguro TO n30_cod_seguro
				DISPLAY BY NAME r_n13.n13_descripcion
			END IF
                END IF
		IF INFIELD(n30_sectorial) THEN
			CALL fl_ayuda_sectorial()
				RETURNING r_n17.n17_sectorial,
					  r_n17.n17_descripcion
			LET int_flag = 0
			IF r_n17.n17_sectorial IS NOT NULL THEN
				DISPLAY r_n17.n17_sectorial TO n30_sectorial
				DISPLAY BY NAME r_n17.n17_descripcion
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
	LET expr_sql = 'n30_cod_trab = ', arg_val(4)
END IF
LET query = 'SELECT *, ROWID FROM rolt030 ',
		' WHERE n30_compania = ', vg_codcia,
		'   AND ', expr_sql CLIPPED,
		' ORDER BY 4'
PREPARE cons FROM query	
DECLARE q_cons CURSOR FOR cons
LET vm_num_rows = 0
FOREACH q_cons INTO rm_n30.*, num_reg
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
	IF num_args() = 4 THEN
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



FUNCTION control_cargas(tipo_llamada)
DEFINE tipo_llamada	CHAR(1)
DEFINE l		SMALLINT

IF rm_n30.n30_estado = 'I' AND tipo_llamada = 'I' THEN
	CALL fl_mensaje_estado_bloqueado()
	RETURN
END IF
OPEN WINDOW w_car AT 07,24
        WITH FORM '../forms/rolf108_2'
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MESSAGE LINE LAST,
                   BORDER)
CALL mostrar_botones_cargas()
DISPLAY rm_n30.n30_cod_trab TO n31_cod_trab
DISPLAY rm_n30.n30_nombres TO tit_trabajador
CASE tipo_llamada
	WHEN 'I' CALL ingreso_cargas()
	WHEN 'C' CALL consulta_cargas()
END CASE
IF tipo_llamada <> 'I' THEN
	LET int_flag = 0
END IF
CLOSE WINDOW w_car
RETURN

END FUNCTION



FUNCTION ingreso_cargas()
DEFINE i		SMALLINT

CALL llenar_cargas()
CALL muestra_detalle_cargas()
CALL leer_cargas()
IF int_flag THEN
	LET vm_num_car = 0
END IF

END FUNCTION



FUNCTION consulta_cargas()
DEFINE i, j		SMALLINT

CALL llenar_cargas()
IF vm_num_car = 0 THEN
	CALL fl_mensaje_consulta_sin_registros()
	RETURN
END IF
CALL set_count(vm_num_car)
DISPLAY ARRAY rm_car TO rm_car.*
	ON KEY(INTERRUPT)
		EXIT DISPLAY
	--#BEFORE DISPLAY
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
                --#CALL dialog.keysetlabel('ACCEPT', '')
		--#CALL dialog.keysetlabel('RETURN','')
	BEFORE ROW
		LET i = arr_curr()
		LET j = scr_line()
	AFTER DISPLAY
		CONTINUE DISPLAY
END DISPLAY
                                                                                
END FUNCTION



FUNCTION llenar_cargas()
DEFINE r_rol2		RECORD LIKE rolt031.*

DECLARE q_car CURSOR FOR
	SELECT * FROM rolt031
		WHERE n31_compania = vg_codcia
		  AND n31_cod_trab = rm_n30.n30_cod_trab
                ORDER BY 5
LET vm_num_car = 1
FOREACH q_car INTO r_rol2.*
	LET rm_car[vm_num_car].n31_tipo_carga  = r_rol2.n31_tipo_carga
	CALL descripcion_cargas(r_rol2.n31_tipo_carga)
		RETURNING rm_car[vm_num_car].tit_carga
	LET rm_car[vm_num_car].n31_nombres     = r_rol2.n31_nombres
	LET rm_car[vm_num_car].n31_fecha_nacim = r_rol2.n31_fecha_nacim
	LET rm_car_aux[vm_num_car].*           = rm_car[vm_num_car].*
	LET vm_num_car = vm_num_car + 1
        IF vm_num_car > vm_max_car THEN
		EXIT FOREACH
        END IF
END FOREACH
LET vm_num_car = vm_num_car - 1

END FUNCTION



FUNCTION muestra_detalle_cargas()
DEFINE i, lim		INTEGER

LET lim = vm_num_car
IF lim > fgl_scr_size('rm_car') THEN
	LET lim = fgl_scr_size('rm_car')
END IF
FOR i = 1 TO lim
	DISPLAY rm_car[i].* TO rm_car[i].*
END FOR

END FUNCTION



FUNCTION leer_cargas()
DEFINE resp             CHAR(6)
DEFINE i,j,k		SMALLINT

OPTIONS INPUT WRAP
LET i = 1
LET int_flag = 0
CALL set_count(vm_num_car)
INPUT ARRAY rm_car WITHOUT DEFAULTS FROM rm_car.*
	ON KEY(INTERRUPT)
       		LET int_flag = 0
               	CALL fl_mensaje_abandonar_proceso() RETURNING resp
       		IF resp = 'Yes' THEN
       			LET int_flag = 1
			FOR k = 1 TO vm_num_car
				LET rm_car[k].* = rm_car_aux[k].*
			END FOR
			EXIT INPUT
       	       	END IF	
	BEFORE ROW
       		LET i = arr_curr()
       		LET j = scr_line()
	AFTER FIELD n31_tipo_carga
		IF rm_car[i].n31_tipo_carga IS NOT NULL THEN
			CALL descripcion_cargas(rm_car[i].n31_tipo_carga)
				RETURNING rm_car[i].tit_carga
			DISPLAY rm_car[i].tit_carga TO rm_car[j].tit_carga
		END IF
	AFTER FIELD n31_fecha_nacim
		IF rm_car[i].n31_fecha_nacim IS NOT NULL THEN
			IF rm_car[i].n31_fecha_nacim >= TODAY THEN
				CALL fl_mostrar_mensaje('Esta fecha de nacimiento es incorrecta','exclamation')
				NEXT FIELD n31_fecha_nacim
			END IF
		END IF
	AFTER INPUT
		LET vm_num_car = arr_count()
		FOR k = 1 TO vm_num_car
			LET rm_car_aux[k].* = rm_car[k].*
		END FOR
END INPUT
IF NOT int_flag THEN
	LET vm_flag_mant = 'C'
ELSE
	LET vm_flag_mant = 'X'
END IF

END FUNCTION



FUNCTION descripcion_cargas(tipo)
DEFINE tipo		LIKE rolt031.n31_tipo_carga

IF tipo = 'H' THEN
	RETURN 'HIJO(A)'
ELSE
	RETURN 'CONYUGUE'
END IF

END FUNCTION



FUNCTION leer_datos()
DEFINE resp		CHAR(6)
DEFINE resul		SMALLINT
DEFINE r_pai		RECORD LIKE gent030.*
DEFINE r_ciu		RECORD LIKE gent031.*
DEFINE r_dep		RECORD LIKE gent034.*
DEFINE r_car		RECORD LIKE gent035.*
DEFINE r_mon		RECORD LIKE gent013.*
DEFINE r_g08		RECORD LIKE gent008.*
DEFINE r_g09		RECORD LIKE gent009.*
DEFINE r_n13		RECORD LIKE rolt013.*
DEFINE r_n17		RECORD LIKE rolt017.*
DEFINE r_b10		RECORD LIKE ctbt010.*
DEFINE codp_aux         LIKE gent030.g30_pais
DEFINE nomp_aux         LIKE gent030.g30_nombre
DEFINE codc_aux         LIKE gent031.g31_ciudad
DEFINE nomc_aux         LIKE gent031.g31_nombre
DEFINE codd_aux         LIKE gent034.g34_cod_depto
DEFINE nomd_aux         LIKE gent034.g34_nombre
DEFINE codg_aux         LIKE gent035.g35_cod_cargo
DEFINE nomg_aux         LIKE gent035.g35_nombre
DEFINE mone_aux         LIKE gent013.g13_moneda
DEFINE nomm_aux         LIKE gent013.g13_nombre
DEFINE deci_aux         LIKE gent013.g13_decimales
DEFINE codb_aux         LIKE gent008.g08_banco
DEFINE nomb_aux         LIKE gent008.g08_nombre
DEFINE tipo_aux         LIKE gent009.g09_tipo_cta
DEFINE num_aux          LIKE gent009.g09_numero_cta
DEFINE fec_ing		LIKE rolt030.n30_fecha_ing
DEFINE mensaje		VARCHAR(100)
DEFINE valor		VARCHAR(15)

OPTIONS INPUT WRAP
INITIALIZE codp_aux, codc_aux, codd_aux, codg_aux, mone_aux, codb_aux TO NULL
DISPLAY BY NAME rm_n30.n30_usuario, rm_n30.n30_fecing, rm_n30.n30_sexo,
		rm_n30.n30_tipo_doc_id, rm_n30.n30_est_civil,
		rm_n30.n30_fecha_ing, rm_n30.n30_tipo_rol, rm_n30.n30_tipo_pago,
		rm_n30.n30_mon_sueldo, rm_n30.n30_tipo_cta_tra,
		rm_n30.n30_factor_hora,	rm_n30.n30_tipo_trab,
		rm_n30.n30_tipo_contr, rm_n30.n30_desc_seguro,
		rm_n30.n30_desc_impto, rm_n30.n30_fon_res_anio
LET int_flag = 0
INPUT BY NAME rm_n30.n30_nombres, rm_n30.n30_domicilio, rm_n30.n30_telef_domic, 
	rm_n30.n30_telef_fami, rm_n30.n30_num_doc_id, rm_n30.n30_tipo_doc_id,
	rm_n30.n30_lib_militar, rm_n30.n30_sexo, rm_n30.n30_pais_nac,
	rm_n30.n30_ciudad_nac, rm_n30.n30_fecha_nacim, rm_n30.n30_est_civil,
	rm_n30.n30_cod_depto, rm_n30.n30_cod_cargo, rm_n30.n30_fecha_ing,
	rm_n30.n30_tipo_rol, rm_n30.n30_tipo_pago, rm_n30.n30_bco_empresa,
	rm_n30.n30_cta_empresa, rm_n30.n30_tipo_cta_tra, rm_n30.n30_cta_trabaj,
	rm_n30.n30_mon_sueldo, rm_n30.n30_sueldo_mes, rm_n30.n30_factor_hora,
	rm_n30.n30_tipo_trab, rm_n30.n30_tipo_contr, rm_n30.n30_refer_fami,
	rm_n30.n30_cod_seguro, rm_n30.n30_carnet_seg, rm_n30.n30_desc_seguro,
	rm_n30.n30_sub_activ, rm_n30.n30_desc_impto, rm_n30.n30_sectorial,
	rm_n30.n30_fec_jub, rm_n30.n30_val_jub_pat, rm_n30.n30_fon_res_anio
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
        	IF FIELD_TOUCHED(rm_n30.n30_nombres, rm_n30.n30_domicilio,
			rm_n30.n30_telef_domic, rm_n30.n30_telef_fami,
			rm_n30.n30_num_doc_id, rm_n30.n30_tipo_doc_id,
			rm_n30.n30_lib_militar,
			rm_n30.n30_sexo, rm_n30.n30_pais_nac,
			rm_n30.n30_ciudad_nac, rm_n30.n30_fecha_nacim,
			rm_n30.n30_est_civil, rm_n30.n30_cod_depto,
			rm_n30.n30_cod_cargo, rm_n30.n30_fecha_ing,
			rm_n30.n30_tipo_rol, rm_n30.n30_tipo_pago,
			rm_n30.n30_bco_empresa, rm_n30.n30_cta_empresa,
			rm_n30.n30_tipo_cta_tra, rm_n30.n30_cta_trabaj,
			rm_n30.n30_mon_sueldo, rm_n30.n30_sueldo_mes,
			rm_n30.n30_factor_hora, rm_n30.n30_tipo_trab,
			rm_n30.n30_cod_seguro, rm_n30.n30_tipo_contr,
			rm_n30.n30_refer_fami, rm_n30.n30_carnet_seg,
			rm_n30.n30_desc_seguro,	rm_n30.n30_sub_activ,
			rm_n30.n30_desc_impto, rm_n30.n30_sectorial,
			rm_n30.n30_fec_jub, rm_n30.n30_val_jub_pat,
			rm_n30.n30_fon_res_anio)
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
		IF INFIELD(n30_pais_nac) THEN
                        CALL fl_ayuda_pais()
                                RETURNING codp_aux, nomp_aux
                        LET int_flag = 0
                        IF codp_aux IS NOT NULL THEN
				LET rm_n30.n30_pais_nac = codp_aux
                                DISPLAY BY NAME rm_n30.n30_pais_nac
                                DISPLAY nomp_aux TO tit_pais
                        END IF
                END IF
		IF INFIELD(n30_ciudad_nac) THEN
                        CALL fl_ayuda_ciudad(rm_n30.n30_pais_nac)
                                RETURNING codc_aux, nomc_aux
                        LET int_flag = 0
                        IF codc_aux IS NOT NULL THEN
				LET rm_n30.n30_ciudad_nac = codc_aux
                                DISPLAY BY NAME rm_n30.n30_ciudad_nac
                                DISPLAY nomc_aux TO tit_ciudad
                        END IF
                END IF
		IF INFIELD(n30_cod_depto) THEN
                        CALL fl_ayuda_departamentos(vg_codcia)
                                RETURNING codd_aux, nomd_aux
                        LET int_flag = 0
                        IF codd_aux IS NOT NULL THEN
				LET rm_n30.n30_cod_depto = codd_aux
                                DISPLAY BY NAME rm_n30.n30_cod_depto
                                DISPLAY nomd_aux TO tit_departamento
                        END IF
                END IF
		IF INFIELD(n30_cod_cargo) THEN
                        CALL fl_ayuda_cargos(vg_codcia)
                                RETURNING codg_aux, nomg_aux
                        LET int_flag = 0
                        IF codg_aux IS NOT NULL THEN
				LET rm_n30.n30_cod_cargo = codg_aux
                                DISPLAY BY NAME rm_n30.n30_cod_cargo
                                DISPLAY nomg_aux TO tit_cargo
                        END IF
                END IF
		IF INFIELD(n30_mon_sueldo) THEN
                	CALL fl_ayuda_monedas()
				RETURNING mone_aux, nomm_aux, deci_aux
                	LET int_flag = 0
                	IF mone_aux IS NOT NULL THEN
				LET rm_n30.n30_mon_sueldo = mone_aux
                        	DISPLAY BY NAME rm_n30.n30_mon_sueldo
                        	DISPLAY nomm_aux TO tit_mon_bas
                	END IF
		END IF
		IF INFIELD(n30_bco_empresa) THEN
                        CALL fl_ayuda_cuenta_banco(vg_codcia, 'A')
                                RETURNING codb_aux, nomb_aux, tipo_aux, num_aux
                        LET int_flag = 0
                        IF codb_aux IS NOT NULL THEN
				LET rm_n30.n30_bco_empresa = codb_aux
				LET rm_n30.n30_cta_empresa = num_aux
                                DISPLAY BY NAME rm_n30.n30_bco_empresa
                                DISPLAY nomb_aux TO tit_banco
				DISPLAY BY NAME rm_n30.n30_cta_empresa
                        END IF
                END IF
		IF INFIELD(n30_cod_seguro) THEN
			CALL fl_ayuda_seguros('A')
				RETURNING r_n13.n13_cod_seguro,
					  r_n13.n13_descripcion
			LET int_flag = 0
			IF r_n13.n13_cod_seguro IS NOT NULL THEN
				LET rm_n30.n30_cod_seguro = r_n13.n13_cod_seguro
				DISPLAY r_n13.n13_cod_seguro TO n30_cod_seguro
				DISPLAY BY NAME r_n13.n13_descripcion
				LET rm_n30.n30_desc_seguro = 'S'
				DISPLAY BY NAME rm_n30.n30_desc_seguro
			END IF
                END IF
		IF INFIELD(n30_sectorial) THEN
			CALL fl_ayuda_sectorial()
				RETURNING r_n17.n17_sectorial,
					  r_n17.n17_descripcion
			LET int_flag = 0
			IF r_n17.n17_sectorial IS NOT NULL THEN
				LET rm_n30.n30_sectorial = r_n17.n17_sectorial
				DISPLAY r_n17.n17_sectorial TO n30_sectorial
				DISPLAY BY NAME r_n17.n17_descripcion
			END IF
                END IF
	BEFORE FIELD n30_ciudad_nac
		IF rm_n30.n30_pais_nac IS NULL THEN
			CALL fl_mostrar_mensaje('Ingrese el país primero','info')
			NEXT FIELD n30_pais_nac
		END IF
	BEFORE FIELD n30_fecha_ing
		LET fec_ing = rm_n30.n30_fecha_ing
	AFTER FIELD n30_num_doc_id
		IF rm_n30.n30_num_doc_id IS NOT NULL THEN
			CALL validar_cedruc(rm_n30.n30_cod_trab,
						rm_n30.n30_num_doc_id)
				RETURNING resul
			IF NOT resul THEN
				--NEXT FIELD n30_num_doc_id
			END IF
		END IF
	AFTER FIELD n30_lib_militar
		IF rm_n30.n30_lib_militar IS NOT NULL THEN
			CALL validar_lib_militar(rm_n30.n30_cod_trab,
						rm_n30.n30_lib_militar)
				RETURNING resul
			IF resul THEN
				--NEXT FIELD n30_lib_militar
			END IF
		END IF
	AFTER FIELD n30_pais_nac
                IF rm_n30.n30_pais_nac IS NOT NULL THEN
                        CALL fl_lee_pais(rm_n30.n30_pais_nac)
                                RETURNING r_pai.*
                        IF r_pai.g30_pais IS NULL  THEN
                                CALL fl_mostrar_mensaje('Este país no existe','exclamation')
                                NEXT FIELD n30_pais_nac
                        END IF
                        DISPLAY r_pai.g30_nombre TO tit_pais
                ELSE
                        CLEAR tit_pais
                END IF
	AFTER FIELD n30_ciudad_nac
                IF rm_n30.n30_ciudad_nac IS NOT NULL THEN
                        CALL fl_lee_ciudad(rm_n30.n30_ciudad_nac)
                                RETURNING r_ciu.*
                        IF r_ciu.g31_ciudad IS NULL  THEN
                                CALL fl_mostrar_mensaje('Está ciudad no existe','exclamation')
                                NEXT FIELD n30_ciudad_nac
                        END IF
                        DISPLAY r_ciu.g31_nombre TO tit_ciudad
			IF r_ciu.g31_pais <> r_pai.g30_pais THEN
				CALL fl_mostrar_mensaje('Esta ciudad no pertenece a ese país','exclamation')
				NEXT FIELD n30_ciudad_nac
			END IF
                ELSE
                        CLEAR tit_ciudad
                END IF
	AFTER FIELD n30_fecha_nacim
		IF rm_n30.n30_fecha_nacim IS NOT NULL THEN
			IF rm_n30.n30_fecha_nacim >= TODAY THEN
				CALL fl_mostrar_mensaje('Esta fecha de nacimiento es incorrecta.','exclamation')
				NEXT FIELD n30_fecha_nacim
			END IF
		END IF
	AFTER FIELD n30_cod_depto
                IF rm_n30.n30_cod_depto IS NOT NULL THEN
                        CALL fl_lee_departamento(vg_codcia,rm_n30.n30_cod_depto)
                                RETURNING r_dep.*
                        IF r_dep.g34_compania IS NULL  THEN
                                CALL fl_mostrar_mensaje('Departamento no existe','exclamation')
                                NEXT FIELD n30_cod_depto
                        END IF
                        DISPLAY r_dep.g34_nombre TO tit_departamento
		ELSE
			CLEAR tit_departamento
                END IF
	AFTER FIELD n30_cod_cargo
                IF rm_n30.n30_cod_cargo IS NOT NULL THEN
                        CALL fl_lee_cargo(vg_codcia,rm_n30.n30_cod_cargo)
                                RETURNING r_car.*
                        IF r_car.g35_compania IS NULL  THEN
                                CALL fl_mostrar_mensaje('Cargo no existe','exclamation')
                                NEXT FIELD n30_cod_cargo
                        END IF
                        DISPLAY r_car.g35_nombre TO tit_cargo
		ELSE
			CLEAR tit_cargo
                END IF
	AFTER FIELD n30_mon_sueldo
                IF rm_n30.n30_mon_sueldo IS NOT NULL THEN
                        CALL fl_lee_moneda(rm_n30.n30_mon_sueldo)
                                RETURNING r_mon.*
                        IF r_mon.g13_moneda IS NULL  THEN
                                CALL fl_mostrar_mensaje('Moneda no exist
e','exclamation')
                                NEXT FIELD n30_mon_sueldo
                        END IF
                        DISPLAY r_mon.g13_nombre TO tit_mon_bas
                        IF r_mon.g13_estado = 'B' THEN
                                CALL fl_mensaje_estado_bloqueado()
                                NEXT FIELD n30_mon_sueldo
                        END IF
                ELSE
                        LET rm_n30.n30_mon_sueldo = rg_gen.g00_moneda_base
                        DISPLAY BY NAME rm_n30.n30_mon_sueldo
                        CALL fl_lee_moneda(rm_n30.n30_mon_sueldo)
				RETURNING r_mon.*
                        DISPLAY r_mon.g13_nombre TO tit_mon_bas
                END IF
	AFTER FIELD n30_sueldo_mes
		IF rm_n30.n30_sueldo_mes IS NOT NULL THEN
			IF rm_n30.n30_sueldo_mes > 0 THEN
				CALL fl_retorna_precision_valor(
							rm_n30.n30_mon_sueldo,
							rm_n30.n30_sueldo_mes)
					RETURNING rm_n30.n30_sueldo_mes
				DISPLAY BY NAME rm_n30.n30_sueldo_mes
				LET rm_n30.n30_factor_hora =
					rm_n30.n30_sueldo_mes / 240
				CALL fl_retorna_precision_valor(
							rm_n30.n30_mon_sueldo,
							rm_n30.n30_factor_hora)
					RETURNING rm_n30.n30_factor_hora
			ELSE
				LET rm_n30.n30_factor_hora = 0
			END IF
			DISPLAY BY NAME rm_n30.n30_factor_hora
		END IF
	AFTER FIELD n30_fecha_ing
		IF rm_n30.n30_fecha_ing IS NULL THEN
			LET rm_n30.n30_fecha_ing = fec_ing
			DISPLAY BY NAME rm_n30.n30_fecha_ing
		END IF
	AFTER FIELD n30_bco_empresa
                IF rm_n30.n30_bco_empresa IS NOT NULL THEN
                        CALL fl_lee_banco_general(rm_n30.n30_bco_empresa)
                                RETURNING r_g08.*
			IF r_g08.g08_banco IS NULL THEN
				CALL fl_mostrar_mensaje('Banco no existe','exclamation')
				NEXT FIELD n30_bco_empresa
			END IF
			DISPLAY r_g08.g08_nombre TO tit_banco
		ELSE
			CLEAR n30_bco_empresa, tit_banco, n30_cta_empresa
                END IF
	AFTER FIELD n30_cta_empresa
                IF rm_n30.n30_cta_empresa IS NOT NULL THEN
                        CALL fl_lee_banco_compania(vg_codcia,
							rm_n30.n30_bco_empresa,
							rm_n30.n30_cta_empresa)
                                RETURNING r_g09.*
			IF r_g09.g09_banco IS NULL THEN
				CALL fl_mostrar_mensaje('Banco o Cuenta Corriente no existe en la compañía','exclamation')
				NEXT FIELD n30_bco_empresa
			END IF
			LET rm_n30.n30_cta_empresa = r_g09.g09_numero_cta
			DISPLAY BY NAME rm_n30.n30_cta_empresa
                        CALL fl_lee_banco_general(rm_n30.n30_bco_empresa)
                                RETURNING r_g08.*
			DISPLAY r_g08.g08_nombre TO tit_banco
			IF r_g09.g09_estado = 'B' THEN
				CALL fl_mensaje_estado_bloqueado()
				NEXT FIELD n30_bco_empresa
			END IF
			CALL fl_lee_cuenta(r_g09.g09_compania,
						r_g09.g09_aux_cont)
				RETURNING r_b10.*
			IF r_b10.b10_compania IS NULL THEN
				CALL fl_mostrar_mensaje('No se puede escoger una cuenta corriente que no tiene auxiliar contable.', 'exclamation')
				NEXT FIELD n30_bco_empresa
			END IF
			IF r_b10.b10_estado <> 'A' THEN
				CALL fl_mostrar_mensaje('El auxiliar contable de esta cuenta bancaria esta con estado bloqueado.', 'exclamation')
				NEXT FIELD n30_bco_empresa
			END IF
		ELSE
			CLEAR n30_cta_empresa
		END IF
	AFTER FIELD n30_cta_trabaj
		IF rm_n30.n30_tipo_pago <> 'T' THEN
			LET rm_n30.n30_cta_trabaj = NULL
			DISPLAY BY NAME rm_n30.n30_cta_trabaj
			CONTINUE INPUT
		END IF
		IF rm_n30.n30_cta_trabaj IS NOT NULL THEN
			CALL validar_cuenta(rm_n30.n30_cta_trabaj)
				RETURNING resul
			IF resul = 1 THEN
				--NEXT FIELD n30_cta_trabaj
			END IF
		ELSE
			CLEAR n30_cta_trabaj
		END IF
	AFTER FIELD n30_tipo_cta_tra
		IF rm_n30.n30_cta_trabaj IS NOT NULL THEN
			IF rm_n30.n30_tipo_cta_tra <> 'N' THEN
				CALL fgl_winmessage (vg_producto,'Empleado con tipo de cuenta de ahorros o corriente. Ingrese el número de cuenta trabajador.','exclamation')
				--NEXT FIELD n30_cta_trabaj
			END IF
		END IF
	AFTER FIELD n30_cod_seguro
		IF rm_n30.n30_cod_seguro IS NOT NULL THEN
			CALL fl_lee_seguros(rm_n30.n30_cod_seguro)
				RETURNING r_n13.*
			IF r_n13.n13_cod_seguro IS NULL THEN
				CALL fl_mostrar_mensaje('No existe este código de seguro.', 'exclamation')
				NEXT FIELD n30_cod_seguro
			END IF
			DISPLAY BY NAME r_n13.n13_descripcion
			IF r_n13.n13_estado = 'B' THEN
				CALL fl_mensaje_estado_bloqueado()
				NEXT FIELD n30_cod_seguro
			END IF
			LET rm_n30.n30_desc_seguro = 'S'
			DISPLAY BY NAME rm_n30.n30_desc_seguro
		ELSE
			CLEAR n13_descripcion
		END IF
	AFTER FIELD n30_sectorial
		IF rm_n30.n30_sectorial IS NOT NULL THEN
			CALL fl_lee_cod_sectorial(rm_n30.n30_sectorial)
				RETURNING r_n17.*
			IF r_n17.n17_sectorial IS NULL THEN
				CALL fl_mostrar_mensaje('No existe este código sectorial.', 'exclamation')
				NEXT FIELD n30_sectorial
			END IF
			DISPLAY BY NAME r_n17.n17_descripcion
		ELSE
			CLEAR n17_descripcion
		END IF
	AFTER FIELD n30_fec_jub
		IF rm_n30.n30_fec_jub IS NOT NULL THEN
			IF rm_n30.n30_fec_jub >= TODAY THEN
				CALL fl_mostrar_mensaje('La fecha de jubilación es incorrecta.','exclamation')
				NEXT FIELD n30_fec_jub
			END IF
		END IF
	AFTER INPUT
		IF rm_n30.n30_tipo_pago <> 'E' THEN
			IF rm_n30.n30_bco_empresa IS NULL OR
			   rm_n30.n30_cta_empresa IS NULL
			THEN
				CALL fl_mostrar_mensaje('Empleado con tipo de pago Cheque o Transferencia, debe ingresar el Banco y la Cuenta Corriente.', 'exclamation')
				NEXT FIELD n30_bco_empresa
			END IF
		ELSE
			IF rm_n30.n30_bco_empresa IS NULL OR
			   rm_n30.n30_cta_empresa IS NULL
			THEN
				INITIALIZE rm_n30.n30_bco_empresa,
					rm_n30.n30_cta_empresa TO NULL
				CLEAR n30_bco_empresa, n30_cta_empresa,
					tit_banco
			END IF
		END IF
		IF rm_n30.n30_cta_trabaj IS NULL THEN
			IF rm_n30.n30_tipo_cta_tra <> 'N' THEN
				CALL fgl_winmessage (vg_producto,'Empleado con tipo de cuenta de ahorros o corriente. Ingrese el número de cuenta trabajador.','exclamation')
				NEXT FIELD n30_cta_trabaj
			END IF
			IF rm_n30.n30_tipo_pago = 'T' THEN
				CALL fl_mostrar_mensaje('Empleado con tipo de Pago Transferencia, debe ingresar el Número de Cuenta Contable.', 'exclamation')
				--NEXT FIELD n30_cta_trabaj
			END IF
		END IF
		IF rm_n30.n30_tipo_cta_tra = 'N' THEN
			INITIALIZE rm_n30.n30_tipo_cta_tra,
					rm_n30.n30_cta_trabaj TO NULL
			CLEAR n30_cta_trabaj
		END IF
		IF rm_n30.n30_cod_seguro IS NULL THEN
			IF rm_n30.n30_desc_seguro = 'S' THEN
				CALL fl_mostrar_mensaje('Este empleado tiene marcado que se le descuente el seguro. Ingrese el código del seguro.', 'exclamation')
				NEXT FIELD n30_cod_seguro
			END IF
		ELSE
			IF rm_n30.n30_carnet_seg IS NULL THEN
				CALL fl_mostrar_mensaje('Ingrese el número del seguro.', 'exclamation')
				NEXT FIELD n30_carnet_seg
			END IF
			LET rm_n30.n30_desc_seguro = 'S'
			DISPLAY BY NAME rm_n30.n30_desc_seguro
		END IF
		IF rm_n30.n30_carnet_seg IS NOT NULL THEN
			IF rm_n30.n30_cod_seguro IS NULL THEN
				LET rm_n30.n30_carnet_seg = NULL
				DISPLAY BY NAME rm_n30.n30_carnet_seg
			END IF
		END IF
		IF rm_n30.n30_sexo = 'F' THEN
			IF rm_n30.n30_lib_militar IS NOT NULL THEN
				CALL validar_lib_militar(rm_n30.n30_cod_trab,
							rm_n30.n30_lib_militar)
					RETURNING resul
				IF resul THEN
					NEXT FIELD n30_lib_militar
				END IF
			END IF
		END IF
		IF rm_n30.n30_fec_jub IS NOT NULL THEN
			IF rm_n30.n30_val_jub_pat IS NULL THEN
				CALL fl_mostrar_mensaje('Si digito fecha de jubilación, debe ingresar el valor de la jubilicación patronal para este empleado.', 'exclamation')
				NEXT FIELD n30_val_jub_pat
			END IF
			LET rm_n30.n30_estado = 'J'
			CALL muestra_estado()
		END IF
		IF rm_n30.n30_val_jub_pat IS NOT NULL THEN
			IF rm_n30.n30_fec_jub IS NULL THEN
				CALL fl_mostrar_mensaje('Si digito el valor de jubilación patronal, debe ingresar la fecha de jubilicación para este empleado.', 'exclamation')
				NEXT FIELD n30_fec_jub
			END IF
		END IF
		IF rm_n30.n30_estado <> 'J' THEN
			CALL validar_cedruc(rm_n30.n30_cod_trab,
						rm_n30.n30_num_doc_id)
				RETURNING resul
			IF NOT resul THEN
				--NEXT FIELD n30_num_doc_id
			END IF
			CALL validar_lib_militar(rm_n30.n30_cod_trab,
						rm_n30.n30_lib_militar)
				RETURNING resul
			IF resul THEN
				--NEXT FIELD n30_lib_militar
			END IF
		END IF
		IF rm_n30.n30_sectorial IS NOT NULL THEN
			CALL fl_lee_cod_sectorial(rm_n30.n30_sectorial)
				RETURNING r_n17.*
			IF r_n17.n17_valor > rm_n30.n30_sueldo_mes THEN
                        	CALL fl_lee_moneda(rm_n30.n30_mon_sueldo)
                                	RETURNING r_mon.*
				LET valor = r_n17.n17_valor
						USING "##,###,##&.##"
				LET mensaje = 'El sueldo del empleado debe ',
						'ser mayor o igual a ',
						r_mon.g13_simbolo, ' ',
						fl_justifica_titulo('I', valor,
						15), ' que es el ',
						'valor del sectorial.'
				CALL fl_mostrar_mensaje(mensaje, 'exclamation')
				--NEXT FIELD n30_sueldo_mes
			END IF
		END IF
END INPUT

END FUNCTION



FUNCTION validar_cuenta(aux_cont)
DEFINE aux_cont		LIKE ctbt010.b10_cuenta
DEFINE r_cta            RECORD LIKE ctbt010.*

CALL fl_lee_cuenta(vg_codcia, aux_cont) RETURNING r_cta.*
IF r_cta.b10_cuenta IS NULL  THEN
	CALL fl_mostrar_mensaje('Cuenta no existe para esta compañía.','exclamation')
	RETURN 1
END IF
IF r_cta.b10_estado = 'B' THEN
	CALL fl_mensaje_estado_bloqueado()
	RETURN 1
END IF
IF r_cta.b10_nivel <> vm_nivel THEN
	CALL fl_mostrar_mensaje('Nivel de cuenta debe ser solo del último.', 'exclamation')
	RETURN 1
END IF
RETURN 0

END FUNCTION



FUNCTION validar_cedruc(cod_trab, cedruc)
DEFINE cod_trab		LIKE rolt030.n30_cod_trab
DEFINE cedruc		LIKE rolt030.n30_num_doc_id
DEFINE r_n30		RECORD LIKE rolt030.*
DEFINE cont		INTEGER
DEFINE resul		SMALLINT

SELECT COUNT(*) INTO cont FROM rolt030 WHERE n30_num_doc_id = cedruc
CASE cont
	WHEN 0
		LET resul = 1
	WHEN 1
		INITIALIZE r_n30.* TO NULL
		DECLARE q_cedruc CURSOR FOR
			SELECT * FROM rolt030 WHERE n30_num_doc_id = cedruc
		OPEN q_cedruc
		FETCH q_cedruc INTO r_n30.*
		CLOSE q_cedruc
		FREE q_cedruc
		LET resul = 1
		IF r_n30.n30_cod_trab <> cod_trab OR cod_trab IS NULL THEN
			CALL fl_mostrar_mensaje('Este número de identificación ya esta asignado al empleado ' || r_n30.n30_nombres CLIPPED || '.','exclamation')
			LET resul = 0
		END IF
	OTHERWISE
		CALL fl_mostrar_mensaje('Este número de identificación ya existe varias veces.','exclamation')
		LET resul = 0
END CASE
IF cont <= 1 THEN
	--IF rm_n30.n30_tipo_doc_id = 'C' THEN
		CALL fl_validar_cedruc_dig_ver(cedruc) RETURNING resul
	--END IF
END IF
RETURN resul

END FUNCTION



FUNCTION validar_lib_militar(cod_trab, libmil)
DEFINE cod_trab		LIKE rolt030.n30_cod_trab
DEFINE libmil		LIKE rolt030.n30_lib_militar
DEFINE r_n30		RECORD LIKE rolt030.*
DEFINE cont		INTEGER
DEFINE resul		SMALLINT

SELECT COUNT(*) INTO cont FROM rolt030 WHERE n30_lib_militar = libmil
CASE cont
	WHEN 0
		LET resul = 0
	WHEN 1
		INITIALIZE r_n30.* TO NULL
		DECLARE q_libmil CURSOR FOR
			SELECT * FROM rolt030 WHERE n30_lib_militar = libmil
		OPEN q_libmil
		FETCH q_libmil INTO r_n30.*
		CLOSE q_libmil
		FREE q_libmil
		LET resul = 0
		IF r_n30.n30_cod_trab <> cod_trab OR cod_trab IS NULL THEN
			CALL fl_mostrar_mensaje('Este número de libreta militar ya esta asignado al empleado ' || r_n30.n30_nombres CLIPPED || '.', 'exclamation')
			LET resul = 1
			LET resul = 1
		END IF
	OTHERWISE
		CALL fl_mostrar_mensaje('Este número de libreta militar ya existe varias veces.','exclamation')
		LET resul = 1
END CASE
IF rm_n30.n30_sexo = 'F' AND libmil IS NOT NULL THEN
	CALL fl_mostrar_mensaje('Un empleado de sexo femenino no tiene libreta militar.', 'exclamation')
	LET resul = 1
END IF
RETURN resul

END FUNCTION



FUNCTION control_grabar()
DEFINE num_aux		INTEGER

IF vm_flag_mant = 'I' THEN
	LET num_aux           = 0 
	LET rm_n30.n30_fecing = CURRENT
	LET rm_n31.n31_fecing = rm_n30.n30_fecing
	SELECT NVL(MAX(n30_cod_trab), 0) + 1
		INTO rm_n30.n30_cod_trab
		FROM rolt030
		WHERE n30_compania = rm_n30.n30_compania
	LET rm_n31.n31_cod_trab = rm_n30.n30_cod_trab
	LET rm_n30.n30_fecing   = CURRENT
	WHILE TRUE
		WHENEVER ERROR CONTINUE
		INSERT INTO rolt030 VALUES (rm_n30.*)
		IF STATUS = 0 THEN
			LET num_aux = SQLCA.SQLERRD[6] 
			WHENEVER ERROR STOP
			EXIT WHILE
		END IF
		WHENEVER ERROR STOP
		SELECT NVL(MAX(n30_cod_trab), 0) + 1
			INTO rm_n30.n30_cod_trab
			FROM rolt030
			WHERE n30_compania = rm_n30.n30_compania
		LET rm_n31.n31_cod_trab = rm_n30.n30_cod_trab
	END WHILE
	CALL control_cargas('I')
	IF NOT int_flag THEN
		CALL grabar_cargas()
	END IF
	--CALL generar_aux_cont_empleado()
	CALL graba_modulo_club(rm_n30.*)
	CALL verificar_proceso_activo_nomina()
	LET vm_r_rows[vm_row_current] = num_aux
	DISPLAY BY NAME rm_n30.n30_cod_trab, rm_n30.n30_fecing
	CALL muestra_reg()
ELSE
	IF vm_flag_mant = 'M' THEN
		UPDATE rolt030 SET * = rm_n30.* WHERE CURRENT OF q_up
		LET vm_flag_mant = 'C'
	ELSE
		IF vm_flag_mant = 'C' THEN
			CALL grabar_cargas()
			CALL fl_mensaje_registro_modificado()
			LET vm_flag_mant = 'I'
		END IF
	END IF
END IF

END FUNCTION



FUNCTION grabar_cargas()
DEFINE i		SMALLINT

IF vm_num_car IS NULL THEN
	RETURN
END IF
DELETE FROM rolt031
	WHERE n31_compania = vg_codcia
	  AND n31_cod_trab = rm_n31.n31_cod_trab
IF vm_num_car <= 0 THEN
	RETURN
END IF
FOR i = 1 TO vm_num_car
	LET rm_n31.n31_secuencia = i
	LET rm_n31.n31_fecing    = CURRENT
        INSERT INTO rolt031
		VALUES (rm_n31.n31_compania, rm_n31.n31_cod_trab,
			rm_n31.n31_secuencia, rm_car[i].n31_tipo_carga,
			rm_car[i].n31_nombres, rm_car[i].n31_fecha_nacim,
			rm_n31.n31_usuario, rm_n31.n31_fecing)
END FOR

END FUNCTION



FUNCTION muestra_siguiente_registro()

LET vm_flag_carga  = 0
IF vm_row_current < vm_num_rows THEN
	LET vm_row_current = vm_row_current + 1
END IF
CALL muestra_reg()

END FUNCTION



FUNCTION muestra_anterior_registro()

LET vm_flag_carga  = 0
IF vm_row_current > 1 THEN
	LET vm_row_current = vm_row_current - 1
END IF
CALL muestra_reg()

END FUNCTION



FUNCTION muestra_contadores(row_current, num_rows)
DEFINE row_current	SMALLINT
DEFINE num_rows		SMALLINT
                                                                                
DISPLAY "        " TO tit_estado_tra
CLEAR tit_estado_tra
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
DEFINE r_dep		RECORD LIKE gent034.*
DEFINE r_car		RECORD LIKE gent035.*
DEFINE r_mon		RECORD LIKE gent013.*
DEFINE r_g08		RECORD LIKE gent008.*
DEFINE r_n13		RECORD LIKE rolt013.*
DEFINE r_n17		RECORD LIKE rolt017.*
DEFINE num_registro	INTEGER

IF vm_num_rows <= 0 THEN
	RETURN
END IF
SELECT * INTO rm_n30.* FROM rolt030 WHERE ROWID = num_registro	
IF STATUS = NOTFOUND THEN
	CALL fgl_winmessage (vg_producto,'No existe registro con índice: ' || vm_row_current,'exclamation')
	RETURN
END IF
IF rm_n30.n30_tipo_cta_tra IS NULL THEN
	LET rm_n30.n30_tipo_cta_tra = 'N'
END IF
DISPLAY BY NAME rm_n30.n30_cod_trab, rm_n30.n30_nombres,
		rm_n30.n30_domicilio, rm_n30.n30_telef_domic,
		rm_n30.n30_telef_fami, rm_n30.n30_num_doc_id,
		rm_n30.n30_tipo_doc_id, rm_n30.n30_sexo,
		rm_n30.n30_pais_nac, rm_n30.n30_ciudad_nac,
		rm_n30.n30_fecha_nacim,	rm_n30.n30_est_civil,
		rm_n30.n30_cod_depto, rm_n30.n30_cod_cargo,
		rm_n30.n30_fecha_ing, rm_n30.n30_fecha_reing,
		rm_n30.n30_fecha_sal, rm_n30.n30_tipo_rol,
		rm_n30.n30_tipo_pago, rm_n30.n30_mon_sueldo,
		rm_n30.n30_sueldo_mes, rm_n30.n30_factor_hora,
		rm_n30.n30_tipo_trab, rm_n30.n30_tipo_contr,
		rm_n30.n30_refer_fami, rm_n30.n30_carnet_seg,
		rm_n30.n30_desc_seguro, rm_n30.n30_sub_activ,
		rm_n30.n30_desc_impto, rm_n30.n30_bco_empresa,
		rm_n30.n30_cta_empresa,	rm_n30.n30_tipo_cta_tra,
		rm_n30.n30_cta_trabaj, rm_n30.n30_cod_seguro,
		rm_n30.n30_sectorial, rm_n30.n30_lib_militar,
		rm_n30.n30_fec_jub, rm_n30.n30_val_jub_pat,
		rm_n30.n30_fon_res_anio, rm_n30.n30_usuario, rm_n30.n30_fecing
CALL fl_lee_pais(rm_n30.n30_pais_nac) RETURNING r_pai.*
DISPLAY r_pai.g30_nombre TO tit_pais
CALL fl_lee_ciudad(rm_n30.n30_ciudad_nac) RETURNING r_ciu.*
DISPLAY r_ciu.g31_nombre TO tit_ciudad
CALL fl_lee_departamento(vg_codcia,rm_n30.n30_cod_depto) RETURNING r_dep.*
DISPLAY r_dep.g34_nombre TO tit_departamento
CALL fl_lee_cargo(vg_codcia,rm_n30.n30_cod_cargo) RETURNING r_car.*
DISPLAY r_car.g35_nombre TO tit_cargo
CALL fl_lee_moneda(rm_n30.n30_mon_sueldo) RETURNING r_mon.*
DISPLAY r_mon.g13_nombre TO tit_mon_bas
CALL fl_lee_banco_general(rm_n30.n30_bco_empresa) RETURNING r_g08.*
DISPLAY r_g08.g08_nombre TO tit_banco
CALL fl_lee_seguros(rm_n30.n30_cod_seguro) RETURNING r_n13.*
DISPLAY BY NAME r_n13.n13_descripcion
CALL fl_lee_cod_sectorial(rm_n30.n30_sectorial) RETURNING r_n17.*
DISPLAY BY NAME r_n17.n17_descripcion
CALL muestra_estado()
LET rm_n31.n31_compania = vg_codcia
LET rm_n31.n31_cod_trab = rm_n30.n30_cod_trab
LET rm_n31.n31_usuario  = rm_n30.n30_usuario
LET rm_n31.n31_fecing   = CURRENT

END FUNCTION



FUNCTION muestra_reg()

CALL mostrar_registro(vm_r_rows[vm_row_current])
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
	CLEAR n30_estado, tit_estado_tra
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
	SELECT * FROM rolt030
		WHERE ROWID = vm_r_rows[vm_row_current]
	FOR UPDATE
OPEN q_ba
FETCH q_ba INTO rm_n30.*
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
IF int_flag THEN
	ROLLBACK WORK
	CALL muestra_reg()
	RETURN
END IF
UPDATE rolt030
	SET n30_estado      = rm_n30.n30_estado,
	    n30_fecha_reing = rm_n30.n30_fecha_reing,
	    n30_fecha_sal   = rm_n30.n30_fecha_sal
	WHERE CURRENT OF q_ba
IF rm_n30.n30_estado = 'A' THEN
	UPDATE rolt061
		SET n61_fec_ing_club = rm_n30.n30_fecha_reing,
		    n61_fec_sal_club = NULL
	        WHERE n61_compania = vg_codcia
	          AND n61_cod_trab = rm_n30.n30_cod_trab
	CALL bloquear_conf_adic_cont('A')
ELSE
	UPDATE rolt061 SET n61_fec_sal_club = rm_n30.n30_fecha_sal
	        WHERE n61_compania = vg_codcia
	          AND n61_cod_trab = rm_n30.n30_cod_trab
	CALL bloquear_conf_adic_cont('B')
END IF
COMMIT WORK
CALL fl_mostrar_mensaje('Se cambió el estado del Empleado Ok.', 'info')
CLEAR n30_estado, tit_estado_tra
CALL muestra_estado()

END FUNCTION



FUNCTION bloquea_activa_registro()
DEFINE resp		CHAR(6)
DEFINE estado		LIKE rolt030.n30_estado
DEFINE salida		LIKE rolt030.n30_fecha_sal
DEFINE reing		LIKE rolt030.n30_fecha_reing
DEFINE fec_tope		LIKE rolt030.n30_fecha_ing

CALL obtener_fecha_tope(rm_n30.n30_cod_trab) RETURNING fec_tope
LET salida = rm_n30.n30_fecha_sal
IF rm_n30.n30_estado = 'A' OR rm_n30.n30_estado = 'J' THEN
	DISPLAY 'INACTIVO' TO tit_estado_tra
	LET estado = 'I'
	--LET salida = TODAY
	LET salida = fec_tope
	INITIALIZE reing TO NULL
END IF
IF rm_n30.n30_estado = 'I' THEN
	DISPLAY 'ACTIVO' TO tit_estado_tra
	LET estado = 'A'
	--INITIALIZE salida TO NULL
	--LET reing  = TODAY
	LET reing  = fec_tope
END IF
DISPLAY salida TO n30_fecha_sal
DISPLAY reing  TO n30_fecha_reing
DISPLAY estado TO n30_estado
LET rm_n30.n30_estado      = estado
LET rm_n30.n30_fecha_sal   = salida
LET rm_n30.n30_fecha_reing = reing
OPTIONS INPUT NO WRAP
LET int_flag = 0
INPUT BY NAME rm_n30.n30_fecha_reing, rm_n30.n30_fecha_sal
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
        	IF FIELD_TOUCHED(rm_n30.n30_fecha_reing, rm_n30.n30_fecha_sal)
		THEN
               		LET int_flag = 0
			CALL fl_mensaje_abandonar_proceso() RETURNING resp
              		IF resp = 'Yes' THEN
				LET int_flag = 1
				EXIT INPUT
                	END IF
		ELSE
			EXIT INPUT
		END IF
	BEFORE FIELD n30_fecha_reing
		IF rm_n30.n30_fecha_reing IS NULL THEN
			NEXT FIELD NEXT
		END IF
	BEFORE FIELD n30_fecha_sal
		IF rm_n30.n30_fecha_sal IS NULL THEN
			NEXT FIELD NEXT
		END IF
	AFTER FIELD n30_fecha_reing
		IF rm_n30.n30_fecha_reing IS NOT NULL THEN
			IF rm_n30.n30_fecha_reing < rm_n30.n30_fecha_ing THEN
				CALL fl_mostrar_mensaje('La fecha de reingreso debe ser mayor a la fecha de ingreso.','exclamation')
				NEXT FIELD n30_fecha_reing
			END IF
		END IF
	AFTER FIELD n30_fecha_sal
		IF rm_n30.n30_fecha_sal IS NOT NULL THEN
			IF rm_n30.n30_fecha_sal < rm_n30.n30_fecha_ing THEN
				CALL fl_mostrar_mensaje('La fecha de salida debe ser mayor a la fecha de ingreso.','exclamation')
				NEXT FIELD n30_fecha_sal
			END IF
		END IF
	AFTER INPUT
		IF rm_n30.n30_fecha_reing IS NOT NULL THEN
			IF rm_n30.n30_fecha_reing > fec_tope THEN
				CALL fl_mostrar_mensaje('La fecha de reingreso no puede ser mayor a la fecha ultima de nomina.','exclamation')
				NEXT FIELD n30_fecha_reing
			END IF
		END IF
		IF rm_n30.n30_fecha_sal IS NOT NULL THEN
			IF rm_n30.n30_fecha_sal > fec_tope THEN
				CALL fl_mostrar_mensaje('La fecha de salida no puede ser mayor a la fecha ultima de nomina.','exclamation')
				NEXT FIELD n30_fecha_sal
			END IF
		END IF
END INPUT

END FUNCTION



FUNCTION bloquear_conf_adic_cont(estado)
DEFINE estado		LIKE rolt056.n56_estado
DEFINE r_n56		RECORD LIKE rolt056.*

WHENEVER ERROR CONTINUE
DECLARE q_conf CURSOR FOR
	SELECT * FROM rolt056
		WHERE n56_compania  = rm_n30.n30_compania
		  AND n56_cod_depto = rm_n30.n30_cod_depto
		  AND n56_cod_trab  = rm_n30.n30_cod_trab
	FOR UPDATE
OPEN q_conf
FETCH q_conf INTO r_n56.*
IF STATUS < 0 THEN
	ROLLBACK WORK
	CALL fl_mensaje_bloqueo_otro_usuario()
	WHENEVER ERROR STOP
	RETURN
END IF	
WHENEVER ERROR STOP
UPDATE rolt056
	SET n56_estado = estado
	WHERE n56_compania   = rm_n30.n30_compania
	  AND n56_proceso   <> "UT"
	  AND n56_cod_depto  = rm_n30.n30_cod_depto
	  AND n56_cod_trab   = rm_n30.n30_cod_trab

END FUNCTION



FUNCTION muestra_estado()

IF rm_n30.n30_estado = 'A' THEN
	DISPLAY 'ACTIVO' TO tit_estado_tra
END IF
IF rm_n30.n30_estado = 'I' THEN
	DISPLAY 'INACTIVO' TO tit_estado_tra
END IF
IF rm_n30.n30_estado = 'J' THEN
	DISPLAY 'JUBILADO' TO tit_estado_tra
END IF
DISPLAY BY NAME rm_n30.n30_estado

END FUNCTION



FUNCTION mostrar_botones_cargas()

DISPLAY 'Tipo Carga' TO tit_col1
DISPLAY 'Nombres'    TO tit_col2
DISPLAY 'Fecha Nac.' TO tit_col3

END FUNCTION



FUNCTION generar_aux_cont_empleado()

SELECT a.* FROM rolt056 a
	WHERE a.n56_compania   = rm_n30.n30_compania
	  AND a.n56_cod_depto  = rm_n30.n30_cod_depto
	  AND a.n56_cod_trab   =
		(SELECT MAX(UNIQUE b.n56_cod_trab)
			FROM rolt056 b
			WHERE b.n56_compania  = a.n56_compania
			  AND b.n56_cod_depto = rm_n30.n30_cod_depto
	  		  AND b.n56_estado    = 'A')
	  AND a.n56_estado    = 'A'
	INTO TEMP tmp_n56
SELECT * FROM rolt052
	WHERE n52_compania = rm_n30.n30_compania
	  AND n52_cod_trab = (SELECT UNIQUE n56_cod_trab FROM tmp_n56)
	INTO TEMP tmp_n52
DROP TABLE tmp_n52
DROP TABLE tmp_n56

END FUNCTION



FUNCTION graba_modulo_club(r_n30)
DEFINE r_n30		RECORD LIKE rolt030.*

DEFINE r_n60		RECORD LIKE rolt060.*
DEFINE r_n61		RECORD LIKE rolt061.*

CALL fl_lee_parametros_club_roles(vg_codcia) RETURNING r_n60.*
IF r_n60.n60_compania IS NULL THEN
	RETURN
END IF

INITIALIZE r_n61.* TO NULL
LET r_n61.n61_compania     = r_n60.n60_compania
LET r_n61.n61_cod_trab     = r_n30.n30_cod_trab
LET r_n61.n61_fec_ing_club = r_n30.n30_fecha_ing
LET r_n61.n61_cuota        = r_n60.n60_val_aporte
LET r_n61.n61_usuario      = vg_usuario
LET r_n61.n61_fecing       = CURRENT
INSERT INTO rolt061 VALUES(r_n61.*)

END FUNCTION



FUNCTION verificar_proceso_activo_nomina()
DEFINE r_n05		RECORD LIKE rolt005.*

INITIALIZE r_n05.* TO NULL
SELECT * INTO r_n05.* FROM rolt005 
	WHERE n05_compania = vg_codcia
	  AND n05_activo   = 'S'
IF r_n05.n05_compania IS NULL THEN
	RETURN
END IF
IF r_n05.n05_proceso[1] = 'M' OR r_n05.n05_proceso[1] = 'Q' OR
   r_n05.n05_proceso[1] = 'S' OR r_n05.n05_proceso[1] = 'D'
THEN
	IF mensaje_continuar_nomina_activa() THEN
		CALL regenerar_novedades(rm_n30.*, r_n05.*)
	END IF
END IF

END FUNCTION



FUNCTION mensaje_continuar_nomina_activa()
DEFINE resp		CHAR(6)

CALL fl_hacer_pregunta('Existe un Proceso de Pago de Nómina Activo. Desea continuar para generar novedades de este Empleado ?.', 'Yes')
	RETURNING resp
IF resp <> 'Yes' THEN
	RETURN 0
END IF
RETURN 1

END FUNCTION



FUNCTION obtener_fecha_tope(cod_trab)
DEFINE cod_trab		LIKE rolt030.n30_cod_trab
DEFINE query		CHAR(15000)
DEFINE fec_tope		LIKE rolt030.n30_fecha_ing

LET query = 'SELECT NVL(MAX(n32_fecha_fin), TODAY) fec_top ',
		' FROM rolt032 ',
		' WHERE n32_compania      = ', vg_codcia,
		'   AND n32_cod_liqrol   IN ("Q1", "Q2") ',
		'   AND n32_cod_trab      = ', cod_trab,
		'UNION ALL ',
		'SELECT NVL(MAX(n36_fecha_fin), TODAY) fec_top ',
		' FROM rolt036 ',
		' WHERE n36_compania      = ', vg_codcia,
		'   AND n36_proceso      IN ("DT", "DC") ',
		'   AND n36_cod_trab      = ', cod_trab,
		'UNION ALL ',
		'SELECT NVL(MAX(n39_periodo_fin), TODAY) fec_top ',
		' FROM rolt039 ',
		' WHERE n39_compania      = ', vg_codcia,
		'   AND n39_proceso      IN ("VA", "VP") ',
		'   AND n39_cod_trab      = ', cod_trab,
		'UNION ALL ',
		'SELECT NVL(MAX(n42_fecha_fin), TODAY) fec_top ',
		' FROM rolt042 ',
		' WHERE n42_compania      = ', vg_codcia,
		'   AND n42_proceso       = "UT" ',
		'   AND n42_cod_trab      = ', cod_trab,
		' INTO TEMP t1 '
PREPARE exec_fec FROM query
EXECUTE exec_fec
SQL
	SELECT NVL(MAX(fec_top), TODAY)
		INTO $fec_tope
		FROM t1
END SQL
DROP TABLE t1
RETURN fec_tope

END FUNCTION



FUNCTION regenerar_novedades(r_n30, r_n05)
DEFINE r_n30		RECORD LIKE rolt030.*
DEFINE r_n05		RECORD LIKE rolt005.*
DEFINE param		VARCHAR(60)
DEFINE prog		VARCHAR(10)
DEFINE mensaje		VARCHAR(200)
DEFINE resul		SMALLINT

LET mensaje = 'Se va a regenerar novedad de ', r_n05.n05_proceso, ' ',
		r_n05.n05_fecini_act USING "dd-mm-yyyy", ' - ',
		r_n05.n05_fecfin_act USING "dd-mm-yyyy", ' para el trabajador ',
		r_n30.n30_cod_trab USING "&&&&", ' ', r_n30.n30_nombres CLIPPED
CALL fl_mostrar_mensaje(mensaje, 'info')
CASE r_n05.n05_proceso
	WHEN 'Q1' LET prog  = 'rolp200 '
	WHEN 'Q2' LET prog  = 'rolp200 '
	WHEN 'DT' LET prog  = 'rolp207 '
	WHEN 'DC' LET prog  = 'rolp221 '
END CASE
LET param = ' ', r_n05.n05_proceso[1,1], ' ', r_n30.n30_cod_trab, ' ',
		r_n05.n05_proceso, ' ', r_n05.n05_fecini_act, ' ',
		r_n05.n05_fecfin_act
IF r_n05.n05_proceso = 'DT' OR r_n05.n05_proceso = 'DC' THEN
	LET param = ' ', r_n05.n05_fecini_act, ' ', r_n05.n05_fecfin_act, ' ',
			r_n30.n30_cod_trab, ' G'
END IF
CALL ejecuta_comando('NOMINA', vg_modulo, prog, param)

END FUNCTION



FUNCTION ejecuta_comando(modulo, mod, prog, param)
DEFINE modulo		VARCHAR(15)
DEFINE mod		LIKE gent050.g50_modulo
DEFINE prog		VARCHAR(10)
DEFINE param		VARCHAR(60)
DEFINE comando          VARCHAR(250)
DEFINE run_prog		VARCHAR(10)

LET run_prog = '; fglrun '
IF vg_gui = 0 THEN
	LET run_prog = '; fglgo '
END IF
LET comando = 'cd ..', vg_separador, '..', vg_separador, modulo,
		vg_separador, 'fuentes', vg_separador, run_prog, prog,
		vg_base, ' ', mod, ' ', vg_codcia, ' ', param
RUN comando

END FUNCTION
