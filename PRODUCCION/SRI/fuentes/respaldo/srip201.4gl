--------------------------------------------------------------------------------
-- Titulo              : srip201.4gl -- Mantenimiento anexo de ventas
-- Elaboración         : 21-Sep-2006
-- Autor               : NPC
-- Formato de Ejecución: fglrun srip201 Base Modulo Compañía Localidad
-- Ultima Correción    : 
-- Motivo Corrección   : 
--------------------------------------------------------------------------------
                                                                                
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'
                                                                                
DEFINE rm_s00   	RECORD LIKE srit000.*
DEFINE rm_s21   	RECORD LIKE srit021.*
DEFINE rm_par		RECORD
				anio_ini	SMALLINT,
				mes_ini		SMALLINT,
				anio_fin	SMALLINT,
				mes_fin		SMALLINT
			END RECORD
DEFINE vm_r_rows	ARRAY[30000] OF INTEGER
DEFINE vm_row_current   SMALLINT        -- FILA CORRIENTE DEL ARREGLO
DEFINE vm_num_rows      SMALLINT        -- CANTIDAD DE FILAS LEIDAS
DEFINE vm_max_rows      SMALLINT        -- MAXIMO DE FILAS LEIDAS
DEFINE vm_flag_mant     CHAR(1)



MAIN

DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/srip201.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 THEN
	CALL fl_mostrar_mensaje('Número de parametros incorrecto.','stop')
     	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_codloc  = arg_val(4)
LET vg_proceso = 'srip201'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()
--#CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()
                                                                                
END MAIN



FUNCTION funcion_master()
DEFINE lin_menu		SMALLINT
DEFINE row_ini  	SMALLINT
DEFINE num_rows 	SMALLINT
DEFINE num_cols 	SMALLINT

CALL fl_nivel_isolation()
{
CALL fl_chequeo_mes_proceso_sri(vg_codcia) RETURNING int_flag
IF int_flag THEN
	RETURN
END IF
}
CALL fl_lee_configuracion_sri(vg_codcia) RETURNING rm_s00.*
IF rm_s00.s00_compania IS NULL THEN
	CALL fl_mostrar_mensaje('No existe configurada la compania de SRI.', 'stop')
	EXIT PROGRAM
END IF
LET vm_max_rows = 30000
LET lin_menu    = 0
LET row_ini     = 3
LET num_rows    = 22
LET num_cols    = 80
IF vg_gui = 0 THEN
	LET lin_menu = 1
	LET row_ini  = 4
	LET num_rows = 20
	LET num_cols = 78
END IF
OPEN WINDOW w_srif201_1 AT row_ini, 2 WITH num_rows ROWS, num_cols COLUMNS
    ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE lin_menu,
		MESSAGE LINE LAST, BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_srif201_1 FROM '../forms/srif201_1'
ELSE
	OPEN FORM f_srif201_1 FROM '../forms/srif201_1c'
END IF
DISPLAY FORM f_srif201_1
INITIALIZE rm_s21.*, rm_par.* TO NULL
LET vm_num_rows    = 0
LET vm_row_current = 0
CALL muestra_contadores(vm_row_current, vm_num_rows)
MENU 'OPCIONES'
	BEFORE MENU
		HIDE OPTION 'Avanzar'
		HIDE OPTION 'Retroceder'
		HIDE OPTION 'Modificar'
		HIDE OPTION 'Procesar Anexo'
		HIDE OPTION 'Generar Anexo'
		HIDE OPTION 'Genera Anexo XML'
		HIDE OPTION 'Genera Anula XML'
	COMMAND KEY('I') 'Ingresar' 'Ingresar nuevos registros. '
		--CALL control_ingreso()
		CALL control_parametros()
		IF vm_num_rows = 1 THEN
			SHOW OPTION 'Modificar'
		END IF
		IF vm_row_current > 1 THEN
			SHOW OPTION 'Retroceder'
		END IF
		IF vm_row_current = vm_num_rows THEN
			HIDE OPTION 'Avanzar'
		END IF
		IF vm_num_rows <= 1 THEN
			SHOW OPTION 'Modificar'
			SHOW OPTION 'Procesar Anexo'
			SHOW OPTION 'Generar Anexo'
			SHOW OPTION 'Genera Anexo XML'
			SHOW OPTION 'Genera Anula XML'
			HIDE OPTION 'Avanzar'
			HIDE OPTION 'Retroceder'
			IF vm_num_rows = 0 THEN
				HIDE OPTION 'Modificar'
				HIDE OPTION 'Procesar Anexo'
				HIDE OPTION 'Generar Anexo'
				HIDE OPTION 'Genera Anexo XML'
				HIDE OPTION 'Genera Anula XML'
			END IF
		ELSE
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Modificar'
			SHOW OPTION 'Procesar Anexo'
			SHOW OPTION 'Generar Anexo'
			SHOW OPTION 'Genera Anexo XML'
			SHOW OPTION 'Genera Anula XML'
		END IF
		IF vm_row_current <= 1 THEN
                        HIDE OPTION 'Retroceder'
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
			SHOW OPTION 'Procesar Anexo'
			SHOW OPTION 'Generar Anexo'
			SHOW OPTION 'Genera Anexo XML'
			SHOW OPTION 'Genera Anula XML'
			HIDE OPTION 'Avanzar'
			HIDE OPTION 'Retroceder'
			IF vm_num_rows = 0 THEN
				HIDE OPTION 'Modificar'
				HIDE OPTION 'Procesar Anexo'
				HIDE OPTION 'Generar Anexo'
				HIDE OPTION 'Genera Anexo XML'
				HIDE OPTION 'Genera Anula XML'
			END IF
		ELSE
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Modificar'
			SHOW OPTION 'Procesar Anexo'
			SHOW OPTION 'Generar Anexo'
			SHOW OPTION 'Genera Anexo XML'
			SHOW OPTION 'Genera Anula XML'
		END IF
		IF vm_row_current <= 1 THEN
                        HIDE OPTION 'Retroceder'
                END IF
        COMMAND KEY('P') 'Procesar Anexo' 'Cierra, Reabre o Declara anexo transaccional ventas.'
		CALL control_cierre_reapertura('C')
        COMMAND KEY('G') 'Generar Anexo' 'Generar anexo transaccional ventas.'
		CALL control_generar(1)
        COMMAND KEY('X') 'Genera Anexo XML' 'Generar anexo transaccional ventas en XML.'
		CALL control_generar(2)
        COMMAND KEY('Y') 'Genera Anula XML' 'Generar anulados de ventas en XML.'
		CALL control_generar(3)
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
DEFINE expr_sql		CHAR(1200)
DEFINE query		CHAR(2000)
DEFINE r_g02		RECORD LIKE gent002.*
DEFINE r_z01		RECORD LIKE cxct001.*

CLEAR FORM
LET int_flag = 0
CONSTRUCT BY NAME expr_sql ON s21_estado, s21_localidad, s21_anio, s21_mes,
	s21_ident_cli, s21_num_doc_id, s21_tipo_comp, s21_fecha_reg_cont,
	s21_num_comp_emi, s21_fecha_emi_vta, s21_base_imp_tar_0,
	s21_iva_presuntivo, s21_bas_imp_gr_iva, s21_cod_porc_iva, s21_monto_iva,
	s21_base_imp_ice, s21_cod_porc_ice, s21_monto_ice, s21_monto_iva_bie,
	s21_cod_ret_ivabie, s21_mon_ret_ivabie, s21_monto_iva_ser,
	s21_cod_ret_ivaser, s21_mon_ret_ivaser, s21_ret_presuntivo,
	s21_concepto_ret, s21_base_imp_renta, s21_porc_ret_renta,
	s21_monto_ret_rent, s21_usuario
	ON KEY(F2)
		IF INFIELD(s21_localidad) THEN
			CALL fl_ayuda_localidad(vg_codcia)
				RETURNING r_g02.g02_localidad, r_g02.g02_nombre
			IF r_g02.g02_localidad IS NOT NULL THEN
				LET rm_s21.s21_localidad = r_g02.g02_localidad
				DISPLAY BY NAME rm_s21.s21_localidad
				DISPLAY r_g02.g02_nombre TO tit_localidad
			END IF
		END IF
		IF INFIELD(s21_num_doc_id) THEN
			CALL fl_ayuda_cliente_localidad(vg_codcia, vg_codloc)
				RETURNING r_z01.z01_codcli, r_z01.z01_nomcli
			IF r_z01.z01_codcli IS NOT NULL THEN
				CALL fl_lee_cliente_general(r_z01.z01_codcli)
					RETURNING r_z01.*
				LET rm_s21.s21_num_doc_id = r_z01.z01_num_doc_id
				DISPLAY BY NAME rm_s21.s21_num_doc_id
			END IF
		END IF
                LET int_flag = 0
	AFTER FIELD s21_fecha_emi_vta
		LET rm_s21.s21_fecha_emi_vta  = GET_FLDBUF(s21_fecha_emi_vta)
	AFTER FIELD s21_fecha_reg_cont
		LET rm_s21.s21_fecha_reg_cont = GET_FLDBUF(s21_fecha_reg_cont)
END CONSTRUCT
IF int_flag THEN
	CLEAR FORM
	IF vm_num_rows > 0 THEN
		CALL lee_muestra_registro(vm_r_rows[vm_row_current])
	END IF
	CALL muestra_contadores(vm_row_current, vm_num_rows)
	RETURN
END IF
LET query = 'SELECT *, ROWID FROM srit021 ',
		' WHERE s21_compania  = ', vg_codcia,
		'   AND ', expr_sql CLIPPED,
		' ORDER BY s21_num_doc_id'
PREPARE cons FROM query
DECLARE q_uni CURSOR FOR cons
LET vm_num_rows = 1
FOREACH q_uni INTO rm_s21.*, vm_r_rows[vm_num_rows]
	LET vm_num_rows = vm_num_rows + 1
        IF vm_num_rows > vm_max_rows THEN
                EXIT FOREACH
        END IF
END FOREACH
LET vm_num_rows = vm_num_rows - 1
IF vm_num_rows = 0 THEN
	{--
	CALL control_generar(1)
	CALL control_generar(2)
	CALL control_generar(3)
	--}
	--CALL fl_mensaje_consulta_sin_registros()
	LET vm_row_current = 1
	CALL muestra_contadores(vm_row_current, vm_num_rows)
        CLEAR FORM
        RETURN
END IF
LET vm_row_current = 1
CALL muestra_contadores(vm_row_current, vm_num_rows)
CALL lee_muestra_registro(vm_r_rows[vm_row_current])

END FUNCTION



FUNCTION control_parametros()
DEFINE fec_i, fec_f	DATE
DEFINE fecha		DATE
DEFINE a, m		SMALLINT
DEFINE query		CHAR(800)

OPTIONS INPUT WRAP
CLEAR FORM
OPEN WINDOW w_srif201_2 AT 06, 18 WITH 04 ROWS, 45 COLUMNS
    ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE 0,
		MESSAGE LINE LAST, BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_srif201_2 FROM '../forms/srif201_2'
ELSE
	OPEN FORM f_srif201_2 FROM '../forms/srif201_2c'
END IF
DISPLAY FORM f_srif201_2
IF rm_par.anio_ini IS NULL THEN
	LET fecha = MDY(MONTH(TODAY), 01, YEAR(TODAY)) - 1 UNITS DAY
	LET rm_par.anio_ini = YEAR(fecha)
	LET rm_par.mes_ini  = MONTH(fecha)
	LET rm_par.anio_fin = YEAR(fecha)
	LET rm_par.mes_fin  = MONTH(fecha)
END IF
CALL lee_parametros()
IF int_flag THEN
	CLOSE WINDOW w_srif201_2
	LET int_flag = 0
	IF vm_num_rows > 0 THEN
		CALL lee_muestra_registro(vm_r_rows[vm_row_current])
	END IF
	CALL muestra_contadores(vm_row_current, vm_num_rows)
	RETURN
END IF
CLOSE WINDOW w_srif201_2
LET int_flag = 0
FOR a = rm_par.anio_ini TO rm_par.anio_fin
	FOR m = rm_par.mes_ini TO rm_par.mes_fin
		LET rm_s21.s21_fecha_emi_vta = MDY(m, 01, a) + 1 UNITS MONTH
						- 1 UNITS DAY
		CALL control_generar(1)
		CALL control_generar(2)
		CALL control_generar(3)
	END FOR
END FOR
LET fec_i = MDY(rm_par.mes_ini, 01, rm_par.anio_ini)
LET fec_f = MDY(rm_par.mes_fin, 01, rm_par.anio_fin) + 1 UNITS MONTH
		- 1 UNITS DAY
LET query = 'SELECT *, ROWID FROM srit021 ',
		' WHERE s21_compania      = ', vg_codcia,
		'   AND s21_fecha_emi_vta BETWEEN "', fec_i,
					   '" AND "', fec_f, '"',
		' ORDER BY s21_num_doc_id'
PREPARE cons2 FROM query
DECLARE q_uni2 CURSOR FOR cons2
LET vm_num_rows = 1
FOREACH q_uni2 INTO rm_s21.*, vm_r_rows[vm_num_rows]
	LET vm_num_rows = vm_num_rows + 1
        IF vm_num_rows > vm_max_rows THEN
                EXIT FOREACH
        END IF
END FOREACH
LET vm_num_rows = vm_num_rows - 1
IF vm_num_rows = 0 THEN
	CALL fl_mensaje_consulta_sin_registros()
	LET vm_row_current = 1
	CALL muestra_contadores(vm_row_current, vm_num_rows)
        CLEAR FORM
        RETURN
END IF
LET vm_row_current = 1
CALL muestra_contadores(vm_row_current, vm_num_rows)
CALL lee_muestra_registro(vm_r_rows[vm_row_current])
CALL fl_mostrar_mensaje('Archivo Regenerado OK.', 'info')

END FUNCTION



FUNCTION control_ingreso()
DEFINE r_g02		RECORD LIKE gent002.*

OPTIONS INPUT WRAP
CLEAR FORM
INITIALIZE rm_s21.* TO NULL
LET vm_flag_mant         = 'I'
LET rm_s21.s21_compania  = vg_codcia
LET rm_s21.s21_localidad = vg_codloc
LET rm_s21.s21_estado    = 'P'
LET rm_s21.s21_fecing    = CURRENT
LET rm_s21.s21_usuario   = vg_usuario
DISPLAY BY NAME rm_s21.s21_fecing, rm_s21.s21_usuario
CALL muestra_estado()
CALL fl_lee_localidad(vg_codcia, vg_codloc) RETURNING r_g02.*
DISPLAY r_g02.g02_nombre TO tit_localidad
CALL lee_datos()
IF NOT int_flag THEN
        INSERT INTO srit021 VALUES (rm_s21.*)
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

IF rm_s21.s21_estado <> 'G' AND rm_s21.s21_estado <> 'P' THEN
	CALL fl_mostrar_mensaje('El Anexo no esta EN PROCESO o GENERADO, no puede ser modificado.', 'exclamation')
	RETURN
END IF
LET vm_flag_mant = 'M'
BEGIN WORK
WHENEVER ERROR CONTINUE
DECLARE q_up CURSOR FOR SELECT * FROM srit021
	WHERE ROWID = vm_r_rows[vm_row_current]
	FOR UPDATE
OPEN q_up
FETCH q_up INTO rm_s21.*
IF STATUS < 0 THEN
	ROLLBACK WORK
	CALL fl_mensaje_bloqueo_otro_usuario()
	WHENEVER ERROR STOP
	RETURN
END IF
WHENEVER ERROR STOP
CALL lee_datos()
IF int_flag THEN
	ROLLBACK WORK
	CALL lee_muestra_registro(vm_r_rows[vm_row_current])
	RETURN
END IF
LET rm_s21.s21_estado        = 'P'
LET rm_s21.s21_usuario_modif = vg_usuario
LET rm_s21.s21_fec_modif     = CURRENT
UPDATE srit021 SET * = rm_s21.* WHERE CURRENT OF q_up
COMMIT WORK
CALL lee_muestra_registro(vm_r_rows[vm_row_current])
CALL fl_mensaje_registro_modificado()

END FUNCTION



FUNCTION lee_datos()
DEFINE resp      	CHAR(6)
DEFINE resul		SMALLINT
DEFINE r_s21		RECORD LIKE srit021.*
                                                                                
LET int_flag = 0 
INPUT BY NAME rm_s21.s21_localidad, rm_s21.s21_anio, rm_s21.s21_mes,
	rm_s21.s21_ident_cli, rm_s21.s21_num_doc_id, rm_s21.s21_tipo_comp,
	rm_s21.s21_fecha_reg_cont, rm_s21.s21_num_comp_emi,
	rm_s21.s21_fecha_emi_vta, rm_s21.s21_base_imp_tar_0,
	rm_s21.s21_iva_presuntivo, rm_s21.s21_bas_imp_gr_iva,
	rm_s21.s21_cod_porc_iva, rm_s21.s21_monto_iva, rm_s21.s21_base_imp_ice,
	rm_s21.s21_cod_porc_ice, rm_s21.s21_monto_ice, rm_s21.s21_monto_iva_bie,
	rm_s21.s21_cod_ret_ivabie, rm_s21.s21_mon_ret_ivabie,
	rm_s21.s21_monto_iva_ser, rm_s21.s21_cod_ret_ivaser,
	rm_s21.s21_mon_ret_ivaser, rm_s21.s21_ret_presuntivo,
	rm_s21.s21_concepto_ret, rm_s21.s21_base_imp_renta,
	rm_s21.s21_porc_ret_renta, rm_s21.s21_monto_ret_rent
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		IF FIELD_TOUCHED(rm_s21.s21_localidad, rm_s21.s21_anio,
				 rm_s21.s21_mes, rm_s21.s21_ident_cli,
				 rm_s21.s21_num_doc_id, rm_s21.s21_tipo_comp,
				 rm_s21.s21_fecha_reg_cont,
				 rm_s21.s21_num_comp_emi,
				 rm_s21.s21_fecha_emi_vta,
				 rm_s21.s21_base_imp_tar_0,
				 rm_s21.s21_iva_presuntivo,
				 rm_s21.s21_bas_imp_gr_iva,
				 rm_s21.s21_cod_porc_iva, rm_s21.s21_monto_iva,
				 rm_s21.s21_base_imp_ice,
				 rm_s21.s21_cod_porc_ice, rm_s21.s21_monto_ice,
				 rm_s21.s21_monto_iva_bie,
				 rm_s21.s21_cod_ret_ivabie,
				 rm_s21.s21_mon_ret_ivabie,
				 rm_s21.s21_monto_iva_ser,
				 rm_s21.s21_cod_ret_ivaser,
				 rm_s21.s21_mon_ret_ivaser,
				 rm_s21.s21_ret_presuntivo,
				 rm_s21.s21_concepto_ret,
				 rm_s21.s21_base_imp_renta,
				 rm_s21.s21_porc_ret_renta,
				 rm_s21.s21_monto_ret_rent)
		THEN
			LET int_flag = 0
			CALL fl_mensaje_abandonar_proceso() RETURNING resp
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
	AFTER FIELD s21_num_doc_id
		IF rm_s21.s21_ident_cli = '06' THEN
			CONTINUE INPUT
		END IF
		IF rm_s21.s21_num_doc_id IS NOT NULL THEN
			IF rm_s21.s21_num_doc_id <> '9999999999999' THEN
				CALL fl_validar_cedruc_dig_ver(
							rm_s21.s21_num_doc_id)
					RETURNING resul
				IF NOT resul THEN
					NEXT FIELD s21_num_doc_id
				END IF
			END IF
		END IF
END INPUT

END FUNCTION



FUNCTION lee_parametros()
DEFINE resp      	CHAR(6)
DEFINE ano_i, ano_f	SMALLINT
DEFINE mes_i, mes_f	SMALLINT
DEFINE fec_ini, fec_fin	DATE

LET int_flag = 0 
INPUT BY NAME rm_par.*
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		IF FIELD_TOUCHED(rm_par.*) THEN
			LET int_flag = 0
			CALL fl_mensaje_abandonar_proceso() RETURNING resp
			IF resp = 'Yes' THEN
				LET int_flag = 1
				RETURN
			END IF
		ELSE
			RETURN
		END IF
	BEFORE FIELD anio_ini
		LET ano_i = rm_par.anio_ini
	BEFORE FIELD mes_ini
		LET mes_i = rm_par.mes_ini
	BEFORE FIELD anio_fin
		LET ano_f = rm_par.anio_fin
	BEFORE FIELD mes_fin
		LET mes_f = rm_par.mes_fin
	AFTER FIELD anio_ini
		IF rm_par.anio_ini IS NULL THEN
			LET rm_par.anio_ini = ano_i
			DISPLAY BY NAME rm_par.anio_ini
		END IF
	AFTER FIELD mes_ini
		IF rm_par.mes_ini IS NULL THEN
			LET rm_par.mes_ini = mes_i
			DISPLAY BY NAME rm_par.mes_ini
		END IF
	AFTER FIELD anio_fin
		IF rm_par.anio_fin IS NULL THEN
			LET rm_par.anio_fin = ano_f
			DISPLAY BY NAME rm_par.anio_fin
		END IF
	AFTER FIELD mes_fin
		IF rm_par.mes_fin IS NULL THEN
			LET rm_par.mes_fin = mes_f
			DISPLAY BY NAME rm_par.mes_fin
		END IF
	AFTER INPUT
		LET fec_ini = MDY(rm_par.mes_ini, 01, rm_par.anio_ini)
		LET fec_fin = MDY(rm_par.mes_fin, 01, rm_par.anio_fin)
				+ 1 UNITS MONTH - 1 UNITS DAY
		IF fec_ini > fec_fin THEN
			CALL fl_mostrar_mensaje('El período inicial no puede ser mayor al período final.', 'exclamation')
			CONTINUE INPUT
		END IF
END INPUT

END FUNCTION



FUNCTION lee_muestra_registro(num_row)
DEFINE num_row		INTEGER
DEFINE r_g02		RECORD LIKE gent002.*

IF vm_num_rows <= 0 THEN
	RETURN
END IF
SELECT * INTO rm_s21.* FROM srit021 WHERE ROWID = num_row
IF STATUS = NOTFOUND THEN
	CALL fl_mostrar_mensaje('No existe registro con índice: ' || num_row, 'exclamation')
	RETURN
END IF
DISPLAY BY NAME rm_s21.s21_estado, rm_s21.s21_localidad, rm_s21.s21_anio,
	rm_s21.s21_mes, rm_s21.s21_ident_cli, rm_s21.s21_num_doc_id,
	rm_s21.s21_tipo_comp,rm_s21.s21_fecha_reg_cont, rm_s21.s21_num_comp_emi,
	rm_s21.s21_fecha_emi_vta, rm_s21.s21_base_imp_tar_0,
	rm_s21.s21_iva_presuntivo, rm_s21.s21_bas_imp_gr_iva,
	rm_s21.s21_cod_porc_iva, rm_s21.s21_monto_iva, rm_s21.s21_base_imp_ice,
	rm_s21.s21_cod_porc_ice, rm_s21.s21_monto_ice, rm_s21.s21_monto_iva_bie,
	rm_s21.s21_cod_ret_ivabie, rm_s21.s21_mon_ret_ivabie,
	rm_s21.s21_monto_iva_ser, rm_s21.s21_cod_ret_ivaser,
	rm_s21.s21_mon_ret_ivaser, rm_s21.s21_ret_presuntivo,
	rm_s21.s21_concepto_ret, rm_s21.s21_base_imp_renta,
	rm_s21.s21_porc_ret_renta, rm_s21.s21_monto_ret_rent,
	rm_s21.s21_usuario, rm_s21.s21_fecing
CALL muestra_estado()
CALL fl_lee_localidad(vg_codcia, rm_s21.s21_localidad) RETURNING r_g02.*
DISPLAY r_g02.g02_nombre TO tit_localidad

END FUNCTION



FUNCTION control_generar(flag)
DEFINE flag		SMALLINT
DEFINE resp		VARCHAR(6)
DEFINE query		CHAR(6000)
DEFINE comando		VARCHAR(400)
DEFINE archivo		VARCHAR(60)
DEFINE fecha		DATE
DEFINE long, posi	SMALLINT

LET int_flag = 0
CASE flag
	WHEN 1
		--CALL fl_hacer_pregunta('Se va a generar nuevamente el anexo transaccional de ventas. Si ha hecho alguna modificación, la perdera. Desea continuar ?', 'no')			RETURNING resp
		LET archivo = NULL
	WHEN 2
		--CALL fl_hacer_pregunta('Desea generar el archivo en XML de ventas ?', 'Yes')			RETURNING resp
		LET archivo = ' "X" > anexo_ventas_',
				MONTH(rm_s21.s21_fecha_emi_vta) USING "&&", '-',
				YEAR(rm_s21.s21_fecha_emi_vta) USING "&&&&",
				'_', vg_codloc USING "&&",
				'.xml ' 
		LET posi    = 8
	WHEN 3
		--CALL fl_hacer_pregunta('Desea generar el archivo en XML de anulados ?', 'Yes')			RETURNING resp
		LET archivo = ' "X" "Y" > anulados_',
				MONTH(rm_s21.s21_fecha_emi_vta) USING "&&", '-',
				YEAR(rm_s21.s21_fecha_emi_vta) USING "&&&&",
				'_', vg_codloc USING "&&",
				'.xml ' 
		LET posi    = 12
END CASE
LET resp = 'Yes'
IF resp <> 'Yes' THEN
	RETURN
END IF
LET fecha = MDY(MONTH(rm_s21.s21_fecha_emi_vta), 01,
		YEAR(rm_s21.s21_fecha_emi_vta))
LET comando = 'cd ..', vg_separador, '..', vg_separador, 'SRI', vg_separador,
		'fuentes', vg_separador, '; umask 0002; fglrun srip200 ',
		vg_base, ' "', vg_modulo, '" ', vg_codcia, ' ', vg_codloc, ' "',
		fecha, '" "', rm_s21.s21_fecha_emi_vta, '" ', archivo CLIPPED
RUN comando
IF flag = 1 THEN
	IF vm_num_rows > 0 THEN
		CALL lee_muestra_registro(vm_r_rows[vm_row_current])
		CALL muestra_contadores(vm_row_current, vm_num_rows)
	END IF
	RETURN
END IF
LET long    = LENGTH(archivo)
LET archivo = 'unix2dos ', archivo[posi, long] CLIPPED
RUN archivo
LET posi    = 10
LET long    = LENGTH(archivo)
LET archivo = 'mv ', archivo[posi, long] CLIPPED, ' $HOME/tmp/'
RUN archivo
LET query = 'SELECT s21_ident_cli, s21_num_doc_id,',
		' CASE WHEN s21_num_doc_id <> "9999999999999" THEN ',
			' (SELECT TRIM(a.z01_nomcli) FROM cxct001 a ',
			' WHERE a.z01_codcli = (SELECT MAX(b.z01_codcli) ',
						'FROM cxct001 b ',
						'WHERE TRIM(b.z01_num_doc_id)=',
							'TRIM(s21_num_doc_id) ',
						'  AND z01_estado = "A")) ',
			' ELSE "CONSUMIDOR FINAL" ',
		' END nomcliente, ',
		' s21_tipo_comp, s21_fecha_reg_cont, s21_num_comp_emi, ',
		' s21_fecha_emi_vta, s21_base_imp_tar_0, s21_iva_presuntivo, ',
		' s21_bas_imp_gr_iva, s21_cod_porc_iva, s21_monto_iva, ',
		' s21_base_imp_ice, s21_cod_porc_ice, s21_monto_ice, ',
		' s21_monto_iva_bie, s21_cod_ret_ivabie, s21_mon_ret_ivabie, ',
		' s21_monto_iva_ser, s21_cod_ret_ivaser, s21_mon_ret_ivaser, ',
		' s21_ret_presuntivo, s21_concepto_ret, s21_base_imp_renta, ',
		' s21_porc_ret_renta, s21_monto_ret_rent ',
		' FROM srit021 ',
		' WHERE s21_compania  = ', vg_codcia,
		'   AND s21_localidad = ', vg_codloc,
		'   AND s21_anio      = ', YEAR(rm_s21.s21_fecha_emi_vta),
		'   AND s21_mes       = ', MONTH(rm_s21.s21_fecha_emi_vta),
		' INTO TEMP t1 '
PREPARE exec_t1_final FROM query
EXECUTE exec_t1_final
UNLOAD TO 'anexo_ventas.unl' SELECT * FROM t1
DROP TABLE t1
LET archivo = 'anexo_ventas_', MONTH(rm_s21.s21_fecha_emi_vta) USING "&&",
		'-', YEAR(rm_s21.s21_fecha_emi_vta) USING "&&&&", '_',
		vg_codloc USING "&&", '.unl ' 
LET comando = 'mv anexo_ventas.unl $HOME/tmp/', archivo CLIPPED
RUN comando
--CALL fl_mostrar_mensaje('Archivo Regenerado OK.', 'info')

END FUNCTION


                                                                                
FUNCTION muestra_contadores(numrow, maxrow)
DEFINE numrow, maxrow	SMALLINT

DISPLAY BY NAME numrow, maxrow

END FUNCTION



FUNCTION muestra_estado()

CASE rm_s21.s21_estado
	WHEN 'G' DISPLAY 'GENERADO'   TO tit_estado
	WHEN 'P' DISPLAY 'EN PROCESO' TO tit_estado
	WHEN 'C' DISPLAY 'CERRADO'    TO tit_estado
	WHEN 'D' DISPLAY 'DECLARADO'  TO tit_estado
END CASE
DISPLAY BY NAME rm_s21.s21_estado

END FUNCTION



FUNCTION control_cierre_reapertura(tipo)
DEFINE tipo		CHAR(1)
DEFINE resp		CHAR(6)
DEFINE palabra		VARCHAR(15)
DEFINE frase		VARCHAR(25)
DEFINE mensaje		VARCHAR(150)
DEFINE r_s21		RECORD LIKE srit021.*
DEFINE estado		LIKE srit021.s21_estado

IF rm_s21.s21_estado = 'D' THEN
	CALL fl_mostrar_mensaje('El Anexo ha sido DECLARADO y ya no puede ser procesado.', 'exclamation')
	RETURN
END IF
BEGIN WORK
WHENEVER ERROR CONTINUE
	DECLARE q_procesar CURSOR FOR
		SELECT * FROM srit021
			WHERE s21_compania  = rm_s21.s21_compania
			  AND s21_localidad = rm_s21.s21_localidad
			  AND s21_anio      = rm_s21.s21_anio
			  AND s21_mes       = rm_s21.s21_mes
		FOR UPDATE
	OPEN q_procesar
	FETCH q_procesar INTO r_s21.*
	IF STATUS < 0 THEN
		ROLLBACK WORK
		CALL fl_mensaje_bloqueo_otro_usuario()
		WHENEVER ERROR STOP
		RETURN
	END IF
	WHENEVER ERROR STOP
	LET frase = ' el anexo de ventas ?'
	IF rm_s21.s21_estado = 'C' THEN
		LET palabra  = 'REAPERTURAR'
		LET mensaje  = 'Desea ', palabra CLIPPED, frase CLIPPED
		LET int_flag = 0
		CALL fl_hacer_pregunta(mensaje, 'No') RETURNING resp
		IF resp = 'Yes' THEN
			LET estado = 'P'
		ELSE
			LET palabra  = 'DECLARAR'
			LET mensaje  = 'Desea ', palabra CLIPPED, frase CLIPPED
			LET int_flag = 0
			CALL fl_hacer_pregunta(mensaje, 'Yes') RETURNING resp
			IF resp <> 'Yes' THEN
				ROLLBACK WORK
				CALL lee_muestra_registro(vm_r_rows[vm_row_current])
				RETURN
			END IF
			LET estado = 'D'
		END IF
	ELSE
		LET estado  = 'C'
		LET palabra = 'CERRAR'
	END IF
	LET mensaje = 'Esta seguro de ', palabra CLIPPED, frase CLIPPED
	LET int_flag = 0
	CALL fl_hacer_pregunta(mensaje, 'Yes') RETURNING resp
	IF resp <> 'Yes' THEN
		ROLLBACK WORK
		CALL lee_muestra_registro(vm_r_rows[vm_row_current])
		RETURN
	END IF
	LET rm_s21.s21_estado = estado
	CALL muestra_estado()
	CASE rm_s21.s21_estado
		WHEN 'C' LET palabra  = 'CERRADO'
		WHEN 'P' LET palabra  = 'REAPERTURADO'
		WHEN 'D' LET palabra  = 'DECLARADO'
	END CASE
	LET mensaje = 'El anexo de ventas ha sido ', palabra CLIPPED, '. OK'
	UPDATE srit021
		SET s21_estado = rm_s21.s21_estado
		WHERE s21_compania  = rm_s21.s21_compania
		  AND s21_localidad = rm_s21.s21_localidad
		  AND s21_anio      = rm_s21.s21_anio
		  AND s21_mes       = rm_s21.s21_mes
COMMIT WORK
CALL lee_muestra_registro(vm_r_rows[vm_row_current])
CALL fl_mostrar_mensaje(mensaje, 'info')

END FUNCTION
