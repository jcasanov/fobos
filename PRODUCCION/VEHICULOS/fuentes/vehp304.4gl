------------------------------------------------------------------------------
-- Titulo           : vehp304.4gl - Consulta de transacciones
-- Elaboracion      : 30-nov-2001
-- Autor            : NPC
-- Formato Ejecucion: fglrun vehp304 base módulo compañía localidad
--                     tipo-transaccion número-transaccion
-- Ultima Correccion: 
-- Motivo Correccion: 
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_demonios	VARCHAR(12)
DEFINE vm_nuevoprog     VARCHAR(400)
DEFINE rm_veh		RECORD LIKE veht030.*
DEFINE rm_veh2		RECORD LIKE veht026.*
DEFINE vm_max_det       SMALLINT
DEFINE vm_max_ant       SMALLINT
DEFINE vm_max_ini       SMALLINT
DEFINE vm_max_cre       SMALLINT
DEFINE vm_num_det       SMALLINT
DEFINE vm_num_ant       SMALLINT
DEFINE vm_num_ini       SMALLINT
DEFINE vm_num_cre       SMALLINT
DEFINE vm_scr_lin       SMALLINT
DEFINE vm_flag_ant      SMALLINT
DEFINE vm_flag_ini      SMALLINT
DEFINE vm_flag_cre      SMALLINT
DEFINE vm_flag_for_pgo  SMALLINT
DEFINE vm_total_pre     DECIMAL(12,2)
DEFINE vm_total_des     DECIMAL(12,2)
DEFINE vm_subtotal      DECIMAL(12,2)
DEFINE vm_valor_iva     DECIMAL(12,2)
DEFINE vm_total_neto    DECIMAL(12,2)
DEFINE rm_orden 	ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1	SMALLINT
DEFINE vm_columna_2	SMALLINT
DEFINE vm_codigo_veh	ARRAY [100] OF LIKE veht031.v31_codigo_veh
DEFINE rm_det		ARRAY [100] OF RECORD
				v04_nombre	LIKE veht004.v04_nombre,
				v22_modelo	LIKE veht022.v22_modelo,
				v22_ano		LIKE veht022.v22_ano,
				v22_chasis	LIKE veht022.v22_chasis,
				v31_precio	LIKE veht031.v31_precio,
				v31_descuento	LIKE veht031.v31_descuento,
				v31_val_descto	LIKE veht031.v31_val_descto
			END RECORD
DEFINE rm_ant		ARRAY [100] OF RECORD
				v29_tipo_doc	LIKE veht029.v29_tipo_doc,
				v29_numdoc	LIKE veht029.v29_numdoc,
				v29_valor	LIKE veht029.v29_valor
			END RECORD
DEFINE rm_ini		ARRAY [100] OF RECORD
				tit_dividendo	LIKE veht028.v28_dividendo,
				tit_fecha_vcto	LIKE veht028.v28_fecha_vcto,
				tit_val_cap	LIKE veht028.v28_val_cap,
				tit_val_int	LIKE veht028.v28_val_int,
				tit_total_ini	DECIMAL(12,2)
			END RECORD
DEFINE rm_cred		ARRAY [100] OF RECORD
				v28_dividendo	LIKE veht028.v28_dividendo,
				v28_fecha_vcto	LIKE veht028.v28_fecha_vcto,
				v28_val_cap	LIKE veht028.v28_val_cap,
				v28_val_int	LIKE veht028.v28_val_int,
				v28_val_adi	LIKE veht028.v28_val_adi,
				tit_total_cre	DECIMAL(12,2)
			END RECORD

MAIN

DEFER QUIT 
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/errores')
CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 6 THEN          -- Validar # parámetros correcto
	CALL fgl_winmessage(vg_producto, 'Número de parámetros incorrecto.', 'stop')
	EXIT PROGRAM
END IF
LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_codcia   = arg_val(3)
LET vg_codloc   = arg_val(4)
LET vg_proceso = 'vehp304'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()

END MAIN



FUNCTION funcion_master()

CALL fl_nivel_isolation()
LET vm_max_det = 100
LET vm_max_ant = 100
LET vm_max_ini = 100
LET vm_max_cre = 100
OPEN WINDOW w_mas AT 3,2 WITH 22 ROWS, 80 COLUMNS
    ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE 0,BORDER,
	      MESSAGE LINE LAST - 2)
OPTIONS INPUT WRAP,
	ACCEPT KEY	F12
OPEN FORM f_veh FROM "../forms/vehf304_1"
DISPLAY FORM f_veh
LET vm_scr_lin = 0
CALL muestra_contadores_det(0)
CALL borrar_cabecera()
CALL borrar_detalle()
CALL control_consulta()

END FUNCTION



FUNCTION control_consulta()
DEFINE i,j,l,col	SMALLINT
DEFINE expr_gen		VARCHAR(1500)
DEFINE query		VARCHAR(600)

CALL cargar_cabecera()
FOR i = 1 TO vm_max_det
	INITIALIZE rm_det[i].*, vm_codigo_veh[i] TO NULL
END FOR
LET vm_num_det = 0
LET vm_num_ant = 0
LET vm_num_ini = 0
LET vm_num_cre = 0
LET expr_gen = 'SELECT v04_nombre, v22_modelo, v22_ano, v22_chasis, v31_precio,
	v31_descuento, v31_val_descto, v31_codigo_veh ',
	'FROM veht030, veht031, veht022, veht020, veht004 ',
		'WHERE v30_compania   = ',vg_codcia,
		'  AND v30_localidad  = ',vg_codloc,
		'  AND v30_cod_tran   = "', rm_veh.v30_cod_tran, '"',
		'  AND v30_num_tran   = ', rm_veh.v30_num_tran,
		'  AND v30_compania   = v31_compania ',
		'  AND v30_localidad  = v31_localidad ',
		'  AND v30_cod_tran   = v31_cod_tran ',
		'  AND v30_num_tran   = v31_num_tran ',
		'  AND v31_compania   = v22_compania ',
		'  AND v31_localidad  = v22_localidad ',
		'  AND v31_codigo_veh = v22_codigo_veh ',
		'  AND v22_compania   = v20_compania ',
		'  AND v22_modelo     = v20_modelo ',
		'  AND v20_compania   = v04_compania ',
		'  AND v20_tipo_veh   = v04_tipo_veh ',
	'INTO TEMP tmp_detalle_veh'
PREPARE q_gen FROM expr_gen
EXECUTE q_gen
SELECT COUNT(*) INTO vm_num_det FROM tmp_detalle_veh
IF vm_num_det = 0 THEN
	DROP TABLE tmp_detalle_veh
	CALL fl_mensaje_consulta_sin_registros()
	RETURN
END IF
FOR i = 1 TO 10
	LET rm_orden[i] = '' 
END FOR
LET rm_orden[1]  = 'ASC'
LET vm_columna_1 = 2
LET vm_columna_2 = 3
LET col          = 2
WHILE TRUE
	LET query = 'SELECT * FROM tmp_detalle_veh ',
			" ORDER BY ", vm_columna_1, ' ', rm_orden[vm_columna_1],
			        ', ', vm_columna_2, ' ', rm_orden[vm_columna_2]
	PREPARE deto FROM query
	DECLARE q_deto CURSOR FOR deto
	LET i = 1
	FOREACH q_deto INTO rm_det[i].*, vm_codigo_veh[i]
		LET i = i + 1
		IF i > vm_max_det THEN
			EXIT FOREACH
		END IF
	END FOREACH
	LET i = i - 1
	CALL sacar_total()
	CALL set_count(i)
	LET int_flag = 0
	DISPLAY ARRAY rm_det TO rm_det.*
		BEFORE DISPLAY
			CALL dialog.keysetlabel('ACCEPT','')
		BEFORE ROW
			LET j = arr_curr()
			LET l = scr_line()
			CALL muestra_contadores_det(j)
		AFTER DISPLAY 
			CONTINUE DISPLAY
		ON KEY(INTERRUPT)
			LET int_flag = 1
			EXIT DISPLAY
		ON KEY(F5)
			CALL forma_pago()
			LET int_flag = 0
		ON KEY(F6)
			CALL ver_liquidacion(i)
			LET int_flag = 0
		ON KEY(F15)
			LET col = 1
			EXIT DISPLAY
		ON KEY(F16)
			LET col = 2
			EXIT DISPLAY
		ON KEY(F17)
			LET col = 3
			EXIT DISPLAY
		ON KEY(F18)
			LET col = 4
			EXIT DISPLAY
		ON KEY(F19)
			LET col = 5
			EXIT DISPLAY
	END DISPLAY
	IF int_flag = 1 THEN
		EXIT WHILE
	END IF
	IF col <> vm_columna_1 THEN
		LET vm_columna_2           = vm_columna_1 
		LET rm_orden[vm_columna_2] = rm_orden[vm_columna_1]
		LET vm_columna_1           = col 
	END IF
	IF rm_orden[vm_columna_1] = 'ASC' THEN
		LET rm_orden[vm_columna_1] = 'DESC'
	ELSE
		LET rm_orden[vm_columna_1] = 'ASC'
	END IF
END WHILE
DROP TABLE tmp_detalle_veh

END FUNCTION



FUNCTION cargar_cabecera()
DEFINE tipo		CHAR(2)
DEFINE num		DECIMAL(15,0)
DEFINE r_ven            RECORD LIKE veht001.*
DEFINE r_mon            RECORD LIKE gent013.*
DEFINE r_veh            RECORD LIKE veht030.*
DEFINE r_bod            RECORD LIKE veht002.*

LET tipo = arg_val(5)
LET num  = arg_val(6)
CALL fl_lee_cabecera_transaccion_veh(vg_codcia, vg_codcia, tipo, num)
	RETURNING rm_veh.*
IF rm_veh.v30_compania IS NULL THEN
	CALL fl_mensaje_consulta_sin_registros()
	EXIT PROGRAM
END IF
LET int_flag = 0
DISPLAY BY NAME rm_veh.v30_cod_tran, rm_veh.v30_num_tran, rm_veh.v30_codcli,
		rm_veh.v30_nomcli, rm_veh.v30_vendedor, rm_veh.v30_moneda,
		rm_veh.v30_paridad, rm_veh.v30_bodega_ori,
		rm_veh.v30_cont_cred, rm_veh.v30_porc_impto,
		rm_veh.v30_tipo_dev, rm_veh.v30_num_dev, rm_veh.v30_usuario,
		rm_veh.v30_fecing
CALL fl_lee_vendedor_veh(vg_codcia, rm_veh.v30_vendedor) RETURNING r_ven.*
DISPLAY r_ven.v01_nombres TO tit_vendedor
CALL fl_lee_moneda(rm_veh.v30_moneda) RETURNING r_mon.*
DISPLAY r_mon.g13_nombre TO tit_mon_bas
CALL fl_lee_bodega_veh(vg_codcia, rm_veh.v30_bodega_ori) RETURNING r_bod.*
DISPLAY r_bod.v02_nombre TO tit_bodega
IF rm_veh.v30_porc_impto > 0 THEN
	DISPLAY 'S' TO tit_iva_che
ELSE
	DISPLAY 'N' TO tit_iva_che
END IF
IF rm_veh.v30_num_dev IS NOT NULL THEN
	CALL fl_lee_cabecera_transaccion_veh(vg_codcia, vg_codloc,
				rm_veh.v30_cod_tran, rm_veh.v30_num_tran)
		RETURNING r_veh.*
	IF r_veh.v30_compania IS NULL THEN
		CALL fgl_winmessage(vg_producto,'No existe la transacción procesada.','stop')
		EXIT PROGRAM
	END IF
	DISPLAY DATE(r_veh.v30_fecing) TO tit_fecha_dev
END IF

END FUNCTION



FUNCTION forma_pago()

OPEN WINDOW w_for AT 03, 02
        WITH FORM '../forms/vehf304_2'
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MESSAGE LINE LAST,
                   MENU LINE 0, BORDER)
CALL mostrar_botones_forma_pago()
CALL cargar_netos_forma_pago()
IF NOT vm_flag_for_pgo THEN
	CALL cargar_anticipos()
	CALL cargar_cuota_inicial()
	CALL cargar_credito()
	CALL muestra_contadores_ant(0)
	CALL muestra_contadores_ini(0)
	CALL muestra_contadores_cre(0)
	MENU 'OPCIONES'
		COMMAND KEY('A') 'Anticipos'
			CALL control_anticipos()
		COMMAND KEY('I') 'Cuota Inicial'
			CALL control_cuota_inicial()
		COMMAND KEY('C') 'Crédito'
			CALL control_credito()
		COMMAND KEY('S') 'Salir'
			IF NOT vm_flag_ant THEN
				DROP TABLE tmp_detalle_ant
			END IF
			IF NOT vm_flag_ini THEN
				DROP TABLE tmp_detalle_ini
			END IF
			IF NOT vm_flag_cre THEN
				DROP TABLE tmp_detalle_cre
			END IF
			EXIT MENU
	END MENU
END IF
CLOSE WINDOW w_for
IF int_flag THEN
	RETURN
END IF

END FUNCTION



FUNCTION control_anticipos()
DEFINE i,j,l,col	SMALLINT
DEFINE query		VARCHAR(400)

IF vm_num_ant = 0 THEN
	CALL fgl_winmessage(vg_producto,'Factura no tiene anticípos.','exclamation')
	RETURN
END IF
FOR i = 1 TO 10
	LET rm_orden[i] = '' 
END FOR
LET rm_orden[1]  = 'ASC'
LET vm_columna_1 = 1
LET vm_columna_2 = 2
LET col          = 1
WHILE TRUE
	LET query = 'SELECT * FROM tmp_detalle_ant ',
			" ORDER BY ", vm_columna_1, ' ', rm_orden[vm_columna_1],
			        ', ', vm_columna_2, ' ', rm_orden[vm_columna_2]
	PREPARE deto2 FROM query
	DECLARE q_deto2 CURSOR FOR deto2
	LET i = 1
	FOREACH q_deto2 INTO rm_ant[i].*
		LET i = i + 1
		IF i > vm_max_ant THEN
			EXIT FOREACH
		END IF
	END FOREACH
	LET i = i - 1
	CALL set_count(i)
	LET int_flag = 0
	DISPLAY ARRAY rm_ant TO rm_ant.*
		BEFORE DISPLAY
			CALL dialog.keysetlabel('ACCEPT','')
		BEFORE ROW
			LET j = arr_curr()
			LET l = scr_line()
			CALL muestra_contadores_ant(j)
		AFTER DISPLAY 
			CONTINUE DISPLAY
		ON KEY(INTERRUPT)
			LET int_flag = 1
			EXIT DISPLAY
		ON KEY(F5)
			CALL documento_favor(j)
			LET int_flag = 0
		ON KEY(F15)
			LET col = 1
			EXIT DISPLAY
		ON KEY(F16)
			LET col = 2
			EXIT DISPLAY
		ON KEY(F17)
			LET col = 3
			EXIT DISPLAY
	END DISPLAY
	IF int_flag = 1 THEN
		CALL muestra_contadores_ant(0)
		EXIT WHILE
	END IF
	IF col <> vm_columna_1 THEN
		LET vm_columna_2           = vm_columna_1 
		LET rm_orden[vm_columna_2] = rm_orden[vm_columna_1]
		LET vm_columna_1           = col 
	END IF
	IF rm_orden[vm_columna_1] = 'ASC' THEN
		LET rm_orden[vm_columna_1] = 'DESC'
	ELSE
		LET rm_orden[vm_columna_1] = 'ASC'
	END IF
END WHILE

END FUNCTION



FUNCTION control_cuota_inicial()
DEFINE i,j,l,col	SMALLINT
DEFINE query		VARCHAR(400)

IF vm_num_ini = 0 THEN
	CALL fgl_winmessage(vg_producto,'Factura no tiene cuota inicial.','exclamation')
	RETURN
END IF
FOR i = 1 TO 10
	LET rm_orden[i] = '' 
END FOR
LET rm_orden[1]  = 'ASC'
LET vm_columna_1 = 2
LET vm_columna_2 = 3
LET col          = 2
WHILE TRUE
	LET query = 'SELECT * FROM tmp_detalle_ini ',
			" ORDER BY ", vm_columna_1, ' ', rm_orden[vm_columna_1],
			        ', ', vm_columna_2, ' ', rm_orden[vm_columna_2]
	PREPARE deto3 FROM query
	DECLARE q_deto3 CURSOR FOR deto3
	LET i = 1
	FOREACH q_deto3 INTO rm_ini[i].*
		LET i = i + 1
		IF i > vm_max_ini THEN
			EXIT FOREACH
		END IF
	END FOREACH
	LET i = i - 1
	CALL set_count(i)
	LET int_flag = 0
	DISPLAY ARRAY rm_ini TO rm_ini.*
		BEFORE DISPLAY
			CALL dialog.keysetlabel('ACCEPT','')
		BEFORE ROW
			LET j = arr_curr()
			LET l = scr_line()
			CALL muestra_contadores_ini(j)
		AFTER DISPLAY 
			CONTINUE DISPLAY
		ON KEY(INTERRUPT)
			LET int_flag = 1
			EXIT DISPLAY
		ON KEY(F15)
			LET col = 1
			EXIT DISPLAY
		ON KEY(F16)
			LET col = 2
			EXIT DISPLAY
		ON KEY(F17)
			LET col = 3
			EXIT DISPLAY
		ON KEY(F18)
			LET col = 4
			EXIT DISPLAY
		ON KEY(F19)
			LET col = 5
			EXIT DISPLAY
	END DISPLAY
	IF int_flag = 1 THEN
		CALL muestra_contadores_ini(0)
		EXIT WHILE
	END IF
	IF col <> vm_columna_1 THEN
		LET vm_columna_2           = vm_columna_1 
		LET rm_orden[vm_columna_2] = rm_orden[vm_columna_1]
		LET vm_columna_1           = col 
	END IF
	IF rm_orden[vm_columna_1] = 'ASC' THEN
		LET rm_orden[vm_columna_1] = 'DESC'
	ELSE
		LET rm_orden[vm_columna_1] = 'ASC'
	END IF
END WHILE

END FUNCTION



FUNCTION control_credito()
DEFINE i,j,l,col	SMALLINT
DEFINE query		VARCHAR(400)

IF vm_num_cre = 0 THEN
	CALL fgl_winmessage(vg_producto,'Factura no tiene crédito.','exclamation')
	RETURN
END IF
FOR i = 1 TO 10
	LET rm_orden[i] = '' 
END FOR
LET rm_orden[1]  = 'ASC'
LET vm_columna_1 = 2
LET vm_columna_2 = 3
LET col          = 2
WHILE TRUE
	LET query = 'SELECT * FROM tmp_detalle_cre ',
			" ORDER BY ", vm_columna_1, ' ', rm_orden[vm_columna_1],
			        ', ', vm_columna_2, ' ', rm_orden[vm_columna_2]
	PREPARE deto4 FROM query
	DECLARE q_deto4 CURSOR FOR deto4
	LET i = 1
	FOREACH q_deto4 INTO rm_cred[i].*
		LET i = i + 1
		IF i > vm_max_cre THEN
			EXIT FOREACH
		END IF
	END FOREACH
	LET i = i - 1
	CALL set_count(i)
	LET int_flag = 0
	DISPLAY ARRAY rm_cred TO rm_cred.*
		BEFORE DISPLAY
			CALL dialog.keysetlabel('ACCEPT','')
		BEFORE ROW
			LET j = arr_curr()
			LET l = scr_line()
			CALL muestra_contadores_cre(j)
		AFTER DISPLAY 
			CONTINUE DISPLAY
		ON KEY(INTERRUPT)
			LET int_flag = 1
			EXIT DISPLAY
		ON KEY(F6)
			CALL documento_deudor(j)
			LET int_flag = 0
		ON KEY(F15)
			LET col = 1
			EXIT DISPLAY
		ON KEY(F16)
			LET col = 2
			EXIT DISPLAY
		ON KEY(F17)
			LET col = 3
			EXIT DISPLAY
		ON KEY(F18)
			LET col = 4
			EXIT DISPLAY
		ON KEY(F19)
			LET col = 5
			EXIT DISPLAY
		ON KEY(F20)
			LET col = 6
			EXIT DISPLAY
	END DISPLAY
	IF int_flag = 1 THEN
		CALL muestra_contadores_cre(0)
		EXIT WHILE
	END IF
	IF col <> vm_columna_1 THEN
		LET vm_columna_2           = vm_columna_1 
		LET rm_orden[vm_columna_2] = rm_orden[vm_columna_1]
		LET vm_columna_1           = col 
	END IF
	IF rm_orden[vm_columna_1] = 'ASC' THEN
		LET rm_orden[vm_columna_1] = 'DESC'
	ELSE
		LET rm_orden[vm_columna_1] = 'ASC'
	END IF
END WHILE

END FUNCTION



FUNCTION cargar_netos_forma_pago()
DEFINE caja		DECIMAL(12,2)

LET vm_flag_for_pgo = 0
DISPLAY rm_veh.v30_cod_tran TO tit_cod_tran
DISPLAY rm_veh.v30_num_tran TO tit_num_tran
SELECT * INTO rm_veh2.* FROM veht026
	WHERE v26_compania  = vg_codcia
	  AND v26_localidad = vg_codloc
	  AND v26_cod_tran  = rm_veh.v30_cod_tran
	  AND v26_num_tran  = rm_veh.v30_num_tran
IF STATUS = NOTFOUND THEN
	CALL fgl_winmessage(vg_producto,'No hay datos en la preventa.','exclamation')
	LET vm_flag_for_pgo = 1
	RETURN
END IF
LET caja = 0
IF rm_veh2.v26_int_cuotaif IS NULL AND rm_veh2.v26_num_cuotaif IS NULL THEN
	{
	IF rm_veh2.v26_tot_pa_nc > rm_veh2.v26_cuotai_fin THEN
		LET rm_veh2.v26_cuotai_fin = rm_veh2.v26_tot_pa_nc
						- rm_veh2.v26_cuotai_fin
	ELSE
		LET rm_veh2.v26_cuotai_fin = rm_veh2.v26_cuotai_fin
						- rm_veh2.v26_tot_pa_nc
	END IF
	LET caja = rm_veh2.v26_tot_neto - rm_veh2.v26_sdo_credito
			- rm_veh2.v26_tot_pa_nc
	LET caja = 0
ELSE
	LET caja = rm_veh2.v26_tot_neto - (rm_veh2.v26_sdo_credito
			+ rm_veh2.v26_cuotai_fin) - rm_veh2.v26_tot_pa_nc
	}
END IF
DISPLAY BY NAME rm_veh2.v26_cuotai_fin, rm_veh2.v26_sdo_credito,
		rm_veh2.v26_tot_pa_nc, rm_veh2.v26_tot_neto
DISPLAY caja TO tit_val_caja

END FUNCTION



FUNCTION cargar_anticipos()
DEFINE i		SMALLINT

LET vm_flag_ant = 0
SELECT v29_tipo_doc, v29_numdoc, v29_valor FROM veht026, veht029
	WHERE v26_compania  = vg_codcia
	  AND v26_localidad = vg_codloc
	  AND v26_cod_tran  = rm_veh.v30_cod_tran
	  AND v26_num_tran  = rm_veh.v30_num_tran
	  AND v26_compania  = v29_compania
	  AND v26_localidad = v29_localidad
	  AND v26_numprev   = v29_numprev
	INTO TEMP tmp_detalle_ant
SELECT COUNT(*) INTO vm_num_ant FROM tmp_detalle_ant
IF vm_num_ant = 0 THEN
	DROP TABLE tmp_detalle_ant
	LET vm_flag_ant = 1
	RETURN
END IF
LET i = 1
DECLARE q_ant CURSOR FOR SELECT * FROM tmp_detalle_ant
FOREACH q_ant INTO rm_ant[i].*
	LET i = i + 1
	IF i > vm_max_ant THEN
		EXIT FOREACH
	END IF
END FOREACH
FOR i = fgl_scr_size('rm_ant') TO 1 STEP -1
	IF i <= vm_num_ant THEN
		DISPLAY rm_ant[i].* TO rm_ant[i].*
	END IF
END FOR

END FUNCTION



FUNCTION cargar_cuota_inicial()
DEFINE i		SMALLINT
	
LET vm_flag_ini = 0
SELECT v28_dividendo, v28_fecha_vcto, v28_val_cap, v28_val_int,
	v28_val_cap + v28_val_int total
	FROM veht026, veht028
	WHERE v26_compania  = vg_codcia
	  AND v26_localidad = vg_codloc
	  AND v26_cod_tran  = rm_veh.v30_cod_tran
	  AND v26_num_tran  = rm_veh.v30_num_tran
	  AND v28_compania  = v26_compania
	  AND v28_localidad = v26_localidad
	  AND v28_numprev   = v26_numprev
	  AND v28_tipo      = "I"
	INTO TEMP tmp_detalle_ini
SELECT COUNT(*) INTO vm_num_ini FROM tmp_detalle_ini
IF vm_num_ini = 0 THEN
	DROP TABLE tmp_detalle_ini
	LET vm_flag_ini = 1
	RETURN
END IF
LET i = 1
DECLARE q_ini CURSOR FOR SELECT * FROM tmp_detalle_ini
FOREACH q_ini INTO rm_ini[i].*
	LET i = i + 1
	IF i > vm_max_ini THEN
		EXIT FOREACH
	END IF
END FOREACH
FOR i = fgl_scr_size('rm_ini') TO 1 STEP -1
	IF i <= vm_num_ini THEN
		DISPLAY rm_ini[i].* TO rm_ini[i].*
	END IF
END FOR

END FUNCTION



FUNCTION cargar_credito()
DEFINE i		SMALLINT

LET vm_flag_cre = 0
SELECT v28_dividendo, v28_fecha_vcto, v28_val_cap, v28_val_int, v28_val_adi,
	v28_val_cap + v28_val_int + v28_val_adi total
	FROM veht026, veht028
	WHERE v26_compania  = vg_codcia
	  AND v26_localidad = vg_codloc
	  AND v26_cod_tran  = rm_veh.v30_cod_tran
	  AND v26_num_tran  = rm_veh.v30_num_tran
	  AND v28_compania  = v26_compania
	  AND v28_localidad = v26_localidad
	  AND v28_numprev   = v26_numprev
	  AND v28_tipo      = "V"
	INTO TEMP tmp_detalle_cre
SELECT COUNT(*) INTO vm_num_cre FROM tmp_detalle_cre
IF vm_num_cre = 0 THEN
	DROP TABLE tmp_detalle_cre
	LET vm_flag_cre = 1
	RETURN
END IF
LET i = 1
DECLARE q_cre CURSOR FOR SELECT * FROM tmp_detalle_cre
FOREACH q_cre INTO rm_cred[i].*
	LET i = i + 1
	IF i > vm_max_cre THEN
		EXIT FOREACH
	END IF
END FOREACH
FOR i = fgl_scr_size('rm_cred') TO 1 STEP -1
	IF i <= vm_num_cre THEN
		DISPLAY rm_cred[i].* TO rm_cred[i].*
	END IF
END FOR

END FUNCTION



FUNCTION sacar_total()
DEFINE i		SMALLINT

LET vm_total_pre  = 0
LET vm_total_des  = 0
LET vm_subtotal   = 0
LET vm_valor_iva  = 0
LET vm_total_neto = 0
FOR i = 1 TO vm_num_det
	LET vm_total_pre = vm_total_pre + rm_det[i].v31_precio
	LET vm_total_des = vm_total_des + rm_det[i].v31_val_descto
	LET vm_subtotal  = vm_subtotal  + rm_det[i].v31_precio
					- rm_det[i].v31_val_descto
END FOR
LET vm_valor_iva  = vm_subtotal * (rm_veh.v30_porc_impto / 100)
LET vm_total_neto = vm_subtotal + vm_valor_iva
DISPLAY vm_total_pre  TO tit_total_pre
DISPLAY vm_total_des  TO tit_total_des
DISPLAY vm_subtotal   TO tit_subtotal
DISPLAY vm_valor_iva  TO tit_valor_iva
DISPLAY vm_total_neto TO tit_total_neto

END FUNCTION



FUNCTION borrar_cabecera()

CLEAR FORM
INITIALIZE rm_veh.*, rm_veh2.* TO NULL

END FUNCTION



FUNCTION borrar_detalle()
DEFINE i  		SMALLINT

CALL muestra_contadores_det(0)
LET vm_scr_lin = fgl_scr_size('rm_det')
FOR i = 1 TO vm_scr_lin
        INITIALIZE rm_det[i].*, vm_codigo_veh[i] TO NULL
        CLEAR rm_det[i].*
END FOR
CLEAR tit_total_pre, tit_total_des, tit_valor_iva, tit_total_neto, tit_subtotal

END FUNCTION



FUNCTION muestra_contadores_det(cor)
DEFINE cor	           SMALLINT

DISPLAY "" AT 21, 4
DISPLAY cor, " de ", vm_num_det AT 21, 8

END FUNCTION



FUNCTION muestra_contadores_ant(cor)
DEFINE cor	           SMALLINT

DISPLAY cor        TO vm_num_current1
DISPLAY vm_num_ant TO vm_num_rows1

END FUNCTION



FUNCTION muestra_contadores_ini(cor)
DEFINE cor	           SMALLINT

DISPLAY cor        TO vm_num_current2
DISPLAY vm_num_ini TO vm_num_rows2

END FUNCTION



FUNCTION muestra_contadores_cre(cor)
DEFINE cor	           SMALLINT

DISPLAY cor        TO vm_num_current3
DISPLAY vm_num_cre TO vm_num_rows3

END FUNCTION



FUNCTION ver_liquidacion(i)
DEFINE i		SMALLINT
DEFINE r_exi		RECORD LIKE veht022.*

CALL fl_lee_cod_vehiculo_veh(vg_codcia, vg_codloc, vm_codigo_veh[i])
	RETURNING r_exi.*
IF r_exi.v22_numero_liq IS NULL THEN
	CALL fgl_winmessage(vg_producto,'Factura no tiene número de liquidación.','exclamation')
	RETURN
END IF
LET vm_nuevoprog = 'cd ..', vg_separador, '..', vg_separador, 'VEHICULOS',
	vg_separador, 'fuentes', vg_separador, '; fglrun vehp212 ', vg_base,
	' ', vg_modulo, ' ', vg_codcia, ' ', vg_codloc, ' ',
	r_exi.v22_numero_liq
RUN vm_nuevoprog

END FUNCTION



FUNCTION documento_favor(i)
DEFINE i		SMALLINT

LET vm_nuevoprog = 'cd ..', vg_separador, '..', vg_separador, 'COBRANZAS',
	vg_separador, 'fuentes', vg_separador, '; fglrun cxcp201 ', vg_base,
	' ', 'CO', ' ', vg_codcia, ' ', vg_codloc, ' ', rm_veh.v30_codcli,
	' ', rm_ant[i].v29_tipo_doc, ' ', rm_ant[i].v29_numdoc 
RUN vm_nuevoprog

END FUNCTION



FUNCTION documento_deudor(i)
DEFINE i		SMALLINT
DEFINE codcli		LIKE cxct001.z01_codcli
DEFINE tipo		LIKE cxct020.z20_tipo_doc
DEFINE num		LIKE cxct020.z20_num_doc
DEFINE r_pla		RECORD LIKE veht006.*

LET codcli = rm_veh.v30_codcli
IF rm_veh2.v26_codigo_plan IS NOT NULL THEN
	CALL fl_lee_plan_financiamiento(vg_codcia, rm_veh2.v26_codigo_plan)
		RETURNING r_pla.*
	IF r_pla.v06_codigo_cobr IS NOT NULL THEN
		LET codcli = r_pla.v06_codigo_cobr
	END IF
END IF
SELECT z20_tipo_doc, z20_num_doc INTO tipo, num FROM cxct020
	WHERE z20_compania  = vg_codcia
	  AND z20_localidad = vg_codloc
	  AND z20_codcli    = codcli
	  AND z20_cod_tran  = rm_veh.v30_cod_tran
	  AND z20_num_tran  = rm_veh.v30_num_tran
	  AND z20_dividendo = rm_cred[i].v28_dividendo 
LET vm_nuevoprog = 'cd ..', vg_separador, '..', vg_separador, 'COBRANZAS',
	vg_separador, 'fuentes', vg_separador, '; fglrun cxcp200 ', vg_base,
	' ', 'CO', ' ', vg_codcia, ' ', vg_codloc, ' ', codcli,
	' ', tipo, ' ', num, ' ', rm_cred[i].v28_dividendo 
RUN vm_nuevoprog

END FUNCTION



FUNCTION mostrar_botones_forma_pago()

DISPLAY 'TD.'          TO tit_ant1
DISPLAY 'No. Doc.'     TO tit_ant2
DISPLAY 'Valor Antic.' TO tit_ant3

DISPLAY 'Div'          TO tit_ini1
DISPLAY 'Fec. Vcto.'   TO tit_ini2
DISPLAY 'Valor Cap.'   TO tit_ini3
DISPLAY 'Valor Int.'   TO tit_ini4
DISPLAY 'Total'        TO tit_ini5

DISPLAY 'Div'          TO tit_cred1
DISPLAY 'Fec. Vcto.'   TO tit_cred2
DISPLAY 'Valor Cap.'   TO tit_cred3
DISPLAY 'Valor Int.'   TO tit_cred4
DISPLAY 'Valor Adi.'   TO tit_cred5
DISPLAY 'Total'        TO tit_cred6

END FUNCTION



FUNCTION validar_parametros()

CALL fl_lee_modulo(vg_modulo) RETURNING rg_mod.*
IF rg_mod.g50_modulo IS NULL THEN
	CALL fgl_winmessage(vg_producto, 'No existe módulo: ' || vg_modulo, 'stop')
	EXIT PROGRAM
END IF
CALL fl_lee_compania(vg_codcia) RETURNING rg_cia.*
IF rg_cia.g01_compania IS NULL THEn
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
