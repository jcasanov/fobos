--------------------------------------------------------------------------------
-- Titulo           : talp400.4gl - Listado de Facturas de Taller
-- Elaboracion      : 13-MAR-2002
-- Autor            : GVA
-- Formato Ejecucion: fglrun talp400 base módulo compañía localidad
-- Ultima Correccion: 
-- Motivo Correccion: 
--------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE rm_t23		RECORD LIKE talt023.*
DEFINE rm_t04		RECORD LIKE talt004.*
DEFINE rm_g13		RECORD LIKE gent013.*
DEFINE rm_ord		ARRAY[3] OF RECORD
				col		VARCHAR(20),
				chk_asc		CHAR,
				chk_desc	CHAR
			END RECORD
DEFINE rm_campos	ARRAY[14] OF RECORD
				nombre		VARCHAR(20),
				posicion	SMALLINT
			END RECORD
DEFINE num_ord		SMALLINT
DEFINE num_campos	SMALLINT
DEFINE fecha_desde	DATE
DEFINE fecha_hasta	DATE
DEFINE todo_inv		CHAR(1)
DEFINE solo_tal		CHAR(1)



MAIN

DEFER QUIT 
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/talp400.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 THEN   -- Validar # parametros correcto
	CALL fl_mostrar_mensaje('Número de parametros incorrecto.','stop')
	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_proceso = 'talp400'
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
LET lin_menu = 0
LET row_ini  = 3
LET num_rows = 22
LET num_cols = 80
IF vg_gui = 0 THEN
	LET lin_menu = 1
	LET row_ini  = 4
	LET num_rows = 20
	LET num_cols = 78
END IF
OPEN WINDOW w_mas AT row_ini, 2 WITH num_rows ROWS, num_cols COLUMNS
    ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE lin_menu,BORDER,
	      MESSAGE LINE LAST - 1)
IF vg_gui = 1 THEN
	OPEN FORM f_rep FROM "../forms/talf400_1"
ELSE
	OPEN FORM f_rep FROM "../forms/talf400_1c"
END IF
DISPLAY FORM f_rep
CALL borrar_cabecera()
CALL control_reporte()

END FUNCTION



FUNCTION control_reporte()
DEFINE i		SMALLINT

LET fecha_desde       = MDY(MONTH(TODAY), 01, YEAR(TODAY))
LET fecha_hasta       = TODAY
LET rm_t23.t23_estado = "T"
LET todo_inv          = 'N'
LET solo_tal          = 'N'
IF vg_codloc = 3 THEN
	LET solo_tal  = 'S'
END IF
IF vg_gui = 0 THEN
	CALL muestra_estado_tit(rm_t23.t23_estado)
END IF
LET rm_t23.t23_cont_cred = "T"
IF vg_gui = 0 THEN
	CALL muestra_contcred(rm_t23.t23_cont_cred)
END IF
LET rm_t23.t23_moneda = rg_gen.g00_moneda_base
CALL fl_lee_moneda(rm_t23.t23_moneda) RETURNING rm_g13.*
DISPLAY rm_g13.g13_nombre TO nom_mon
DISPLAY BY NAME rm_t23.t23_estado
CALL campos_forma()
LET num_ord       = 3
LET rm_ord[1].col = rm_campos[1].nombre
LET rm_ord[2].col = rm_campos[4].nombre
LET rm_ord[3].col = rm_campos[6].nombre
FOR i = 1 TO num_ord
	LET rm_ord[i].chk_asc  = 'S'
	LET rm_ord[i].chk_desc = 'N'
	DISPLAY rm_ord[i].* TO rm_ord[i].*
END FOR
WHILE TRUE
	CALL lee_parametros()
	IF int_flag THEN
		EXIT WHILE
	END IF
	IF vg_gui = 1 THEN
		CALL ordenar_por()
		IF int_flag THEN
			EXIT WHILE
		END IF
	END IF
	CALL control_imprimir()
END WHILE

END FUNCTION



FUNCTION control_imprimir()
DEFINE r_report 	RECORD
				fecha		LIKE talt023.t23_fecing,
				orden		LIKE talt023.t23_orden,
				factura		LIKE talt023.t23_num_factura,
				cliente		LIKE talt023.t23_nom_cliente,
				mo		LIKE talt023.t23_val_mo_tal,
				valor_ext	DECIMAL(14,2),
				rep_alm		LIKE talt023.t23_val_rp_alm,
				viaticos	LIKE talt023.t23_val_otros1,
				tot_bruto	LIKE talt023.t23_tot_bruto,
				tot_dscto	LIKE talt023.t23_tot_dscto,
				subtotal	DECIMAL(14,2),
				tot_impto	LIKE talt023.t23_val_impto,
				tot_neto	LIKE talt023.t23_tot_neto,
				estad		LIKE talt023.t23_estado
			END RECORD
DEFINE comando 		VARCHAR(100)
DEFINE query		CHAR(1200)
DEFINE order_clause	VARCHAR(150)
DEFINE i, j		SMALLINT

CALL fl_control_reportes() RETURNING comando
IF int_flag THEN
	RETURN
END IF
SELECT DATE(t23_fec_factura) fecha_tran, t23_orden ord_t,
	t23_num_factura num_tran, t23_nom_cliente nomcli,t23_tot_bruto valor_mo,
	t23_tot_bruto valor_oc, t23_tot_bruto valor_fa, t23_val_otros1 valor_vi,
	t23_tot_bruto valor_br, t23_tot_dscto valor_de, t23_val_impto valor_im,
	t23_estado est, t23_cod_cliente codcli, t23_modelo modelo,
	t23_porc_impto porc
	FROM talt023
	WHERE t23_compania = 17
	INTO TEMP tmp_det
CASE rm_t23.t23_estado
	WHEN 'F' CALL preparar_tabla_de_trabajo(rm_t23.t23_estado, 1)
		 CALL preparar_tabla_de_trabajo('D', 2)
	WHEN 'D' CALL preparar_tabla_de_trabajo(rm_t23.t23_estado, 1)
	WHEN 'N' CALL preparar_tabla_de_trabajo('N', 1)
	WHEN 'T' CALL preparar_tabla_de_trabajo('F', 1)
		 CALL preparar_tabla_de_trabajo('D', 1)
	         CALL preparar_tabla_de_trabajo('N', 1)
		 CALL preparar_tabla_de_trabajo('D', 2)
END CASE
LET order_clause = ' ORDER BY '
FOR i = 1 TO num_ord
	FOR j = 1 TO num_campos
		IF rm_ord[i].col = rm_campos[j].nombre THEN
			LET order_clause = order_clause, rm_campos[j].posicion
			IF rm_ord[i].chk_asc = 'S' THEN
				LET order_clause = order_clause, ' ASC'
			ELSE
				LET order_clause = order_clause, ' DESC'
			END IF
			IF i <> num_ord THEN
				LET order_clause = order_clause, ', '
			END IF
		END IF
	END FOR
END FOR
LET query = 'SELECT fecha_tran, ord_t, num_tran, nomcli, valor_mo + valor_de, ',
			'valor_oc, valor_fa, valor_vi, valor_br + valor_de, ',
			'valor_de, valor_br subtotal, valor_im, ',
			'(valor_br + valor_im) valor_tot, est ',
		' FROM tmp_det, OUTER talt004 ',
		' WHERE t04_compania = ', vg_codcia,
		'   AND t04_modelo   = modelo ',
		'   AND t04_linea    = "', rm_t04.t04_linea, '"',
		order_clause CLIPPED
PREPARE reporte FROM query
DECLARE q_reporte CURSOR FOR reporte
OPEN q_reporte
FETCH q_reporte
IF STATUS = NOTFOUND THEN
	CLOSE q_reporte
	FREE  q_reporte
	DROP TABLE tmp_det
	CALL fl_mensaje_consulta_sin_registros()
	RETURN
END IF
CLOSE q_reporte
START REPORT report_facturas_taller TO PIPE comando
FOREACH q_reporte INTO r_report.* 
	OUTPUT TO REPORT report_facturas_taller(r_report.*)
END FOREACH
FINISH REPORT report_facturas_taller
DROP TABLE tmp_det

END FUNCTION



FUNCTION lee_parametros()
DEFINE r_t01		RECORD LIKE talt001.*
DEFINE r_t04		RECORD LIKE talt004.*
DEFINE r_t05		RECORD LIKE talt005.*

OPTIONS INPUT NO WRAP
INITIALIZE r_t01.*, r_t04.*, r_t05.* TO NULL
LET int_flag = 0
INPUT BY NAME rm_t23.t23_moneda, rm_t04.t04_linea, rm_t23.t23_tipo_ot,
	fecha_desde, fecha_hasta, rm_t23.t23_estado, rm_t23.t23_cont_cred,
	solo_tal, todo_inv
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		LET int_flag = 1
		RETURN
        ON KEY(F1,CONTROL-W)
		CALL llamar_visor_teclas()
	ON KEY(F2)
		IF INFIELD(t23_moneda) THEN
			CALL fl_ayuda_monedas()
				RETURNING rm_g13.g13_moneda, rm_g13.g13_nombre, 
					  rm_g13.g13_decimales
			IF rm_g13.g13_moneda IS NOT NULL THEN
				LET rm_t23.t23_moneda = rm_g13.g13_moneda
				DISPLAY BY NAME rm_t23.t23_moneda
				DISPLAY rm_g13.g13_nombre TO nom_mon
			END IF
		END IF
		IF INFIELD(t04_linea) THEN
			CALL fl_ayuda_marcas_taller(vg_codcia)
				RETURNING r_t01.t01_linea, r_t01.t01_nombre
			IF r_t01.t01_linea IS NOT NULL THEN
				LET rm_t04.t04_linea = r_t01.t01_linea
				DISPLAY BY NAME rm_t04.t04_linea,
						r_t01.t01_nombre
			END IF
		END IF
		IF INFIELD(t23_tipo_ot) THEN
			CALL fl_ayuda_tipo_orden_trabajo(vg_codcia) 
				RETURNING r_t05.t05_tipord, r_t05.t05_nombre
			IF r_t05.t05_tipord IS NOT NULL THEN
				LET rm_t23.t23_tipo_ot = r_t05.t05_tipord
				DISPLAY BY NAME rm_t23.t23_tipo_ot
				DISPLAY r_t05.t05_nombre TO nom_tipo_ot  
			END IF
		END IF
		LET int_flag = 0
	BEFORE INPUT
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
	AFTER FIELD t23_moneda
		IF rm_t23.t23_moneda IS NOT NULL THEN
			CALL fl_lee_moneda(rm_t23.t23_moneda)
				RETURNING rm_g13.*
			IF rm_g13.g13_moneda IS NULL THEN
				CALL fl_mostrar_mensaje('No existe la moneda en la Compañía.','exclamation')
				CLEAR nom_mon
				NEXT FIELD t23_moneda
			ELSE
				LET rm_t23.t23_moneda = rm_g13.g13_moneda
				DISPLAY BY NAME rm_t23.t23_moneda
				DISPLAY rm_g13.g13_nombre TO nom_mon
			END IF
		ELSE
			CLEAR nom_mon
		END IF
	AFTER FIELD t04_linea
		IF rm_t04.t04_linea IS NOT NULL THEN
			CALL fl_lee_linea_taller(vg_codcia, rm_t04.t04_linea)
				RETURNING r_t01.*
			IF r_t01.t01_linea IS NULL THEN
				CALL fl_mostrar_mensaje('No existe esa Línea en la Compañía.','exclamation')
				NEXT FIELD t04_linea
			END IF
			DISPLAY BY NAME r_t01.t01_nombre
		ELSE
			CLEAR t01_nombre
		END IF
	AFTER FIELD t23_tipo_ot
		IF rm_t23.t23_tipo_ot IS NOT NULL THEN
			CALL fl_lee_tipo_orden_taller(vg_codcia, 
						      rm_t23.t23_tipo_ot)
				RETURNING r_t05.*
			IF r_t05.t05_tipord IS NULL THEN
				CALL fl_mostrar_mensaje('No existe el Tipo de Orden de Trabajo en la Compañía.','exclamation')
				NEXT FIELD t23_tipo_ot
			END IF
			DISPLAY r_t05.t05_nombre TO nom_tipo_ot
		ELSE
			CLEAR nom_tipo_ot
		END IF
	AFTER FIELD t23_estado
		IF vg_gui = 0 THEN
			CALL muestra_estado_tit(rm_t23.t23_estado)
		END IF
	AFTER FIELD t23_cont_cred
		IF vg_gui = 0 THEN
			CALL muestra_contcred(rm_t23.t23_cont_cred)
		END IF
	AFTER INPUT 
		IF fecha_desde > fecha_hasta THEN
			CALL fl_mostrar_mensaje('La fecha desde debe ser menor a la fecha hasta.','exclamation')
			NEXT FIELD fecha_desde
		END IF
		IF fecha_hasta > TODAY THEN
			CALL fl_mostrar_mensaje('La fecha hasta debe ser menor hoy día.','exclamation')
			NEXT FIELD fecha_hasta
		END IF
		IF fecha_desde IS NULL THEN
			NEXT FIELD fecha_desde
		END IF
		IF fecha_hasta IS NULL THEN
			NEXT FIELD fecha_hasta
		END IF
		{--
		IF rm_t23.t23_tipo_ot IS NULL THEN
			NEXT FIELD t04_linea
		END IF
		--}
END INPUT
IF solo_tal = 'S' THEN
	LET todo_inv = 'N'
END IF
DISPLAY BY NAME todo_inv

END FUNCTION



FUNCTION ordenar_por()
DEFINE i, j		SMALLINT
DEFINE asc_ant,desc_ant	CHAR
DEFINE campo, col_ant	VARCHAR(20)

CALL set_count(num_ord)
LET int_flag = 0
INPUT ARRAY rm_ord WITHOUT DEFAULTS FROM rm_ord.* 
        ON KEY(INTERRUPT)
		LET int_flag = 1
		EXIT INPUT
        ON KEY(F1,CONTROL-W)
		CALL llamar_visor_teclas()
	ON KEY(F2) 
		IF INFIELD(col) THEN
			CALL ayuda_campos() RETURNING campo
			IF campo IS NOT NULL THEN
				LET rm_ord[i].col = campo
				DISPLAY rm_ord[i].col TO rm_ord[i].col
			END IF
		END IF
		LET int_flag = 0
	BEFORE INPUT
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
	BEFORE ROW
		LET i = arr_curr()
	AFTER FIELD col
		IF rm_ord[i].col IS NULL THEN
			CALL fl_mostrar_mensaje('Debe elegir una columna.','exclamation')
			NEXT FIELD col	
		END IF
		INITIALIZE campo TO NULL
		FOR j = 1 TO num_campos
			IF rm_ord[i].col = rm_campos[j].nombre THEN
				LET campo = 'OK'
				EXIT FOR
			END IF
		END FOR
		IF campo IS NULL THEN
			CALL fl_mostrar_mensaje('Campo no existe.','exclamation')
			NEXT FIELD col
		END IF
		DISPLAY rm_ord[i].col TO rm_ord[i].col
	BEFORE FIELD chk_asc
		LET asc_ant = rm_ord[i].chk_asc
	AFTER FIELD chk_asc
		IF rm_ord[i].chk_asc <> asc_ant THEN
			IF rm_ord[i].chk_asc = 'S' THEN
				LET rm_ord[i].chk_desc = 'N'
			ELSE
				LET rm_ord[i].chk_desc = 'S'
			END IF
			DISPLAY rm_ord[i].* TO rm_ord[i].*
		END IF
	BEFORE FIELD chk_desc
		LET desc_ant = rm_ord[i].chk_desc
	AFTER FIELD chk_desc
		IF rm_ord[i].chk_desc <> desc_ant THEN
			IF rm_ord[i].chk_desc = 'S' THEN
				LET rm_ord[i].chk_asc = 'N'
			ELSE
				LET rm_ord[i].chk_asc = 'S'
			END IF
			DISPLAY rm_ord[i].* TO rm_ord[i].*
		END IF
	AFTER INPUT
		FOR i = 1 TO num_ord 
			FOR j = 1 TO num_ord  
				IF j <> i AND rm_ord[j].col = rm_ord[i].col THEN
					CALL fl_mostrar_mensaje('No puede ordenar dos veces sobre el mismo campo.','exclamation')
					CONTINUE INPUT
				END IF
			END FOR
		END FOR
END INPUT

END FUNCTION



FUNCTION campos_forma()

LET rm_campos[01].nombre   = 'FECHA TRANSACCION'
LET rm_campos[01].posicion = 1
LET rm_campos[02].nombre   = 'ORDEN DE TRABAJO'
LET rm_campos[02].posicion = 2
LET rm_campos[03].nombre   = 'TIPO TRANSACCION'
LET rm_campos[03].posicion = 14
LET rm_campos[04].nombre   = 'NUMERO TRANSACCION'
LET rm_campos[04].posicion = 3
LET rm_campos[05].nombre   = 'CLIENTES'
LET rm_campos[05].posicion = 4
LET rm_campos[06].nombre   = 'MANO OBRA INTERNA'
LET rm_campos[06].posicion = 5
LET rm_campos[07].nombre   = 'VALOR ORDEN COMPRA'
LET rm_campos[07].posicion = 6
LET rm_campos[08].nombre   = 'VALOR INVENTARIO'
LET rm_campos[08].posicion = 7
LET rm_campos[09].nombre   = 'VIATICOS'
LET rm_campos[09].posicion = 8
LET rm_campos[10].nombre   = 'TOTAL BRUTO'
LET rm_campos[10].posicion = 9
LET rm_campos[11].nombre   = 'TOTAL DESCUENTO'
LET rm_campos[11].posicion = 10
LET rm_campos[12].nombre   = 'SUBTOTAL'
LET rm_campos[12].posicion = 11
LET rm_campos[13].nombre   = 'TOTAL IMPUESTO'
LET rm_campos[13].posicion = 12
LET rm_campos[14].nombre   = 'TOTAL NETO'
LET rm_campos[14].posicion = 13
LET num_campos             = 14

END FUNCTION



FUNCTION ayuda_campos()
DEFINE rh_campos	ARRAY[14] OF VARCHAR(20)
DEFINE i, j             SMALLINT
DEFINE filas_max        SMALLINT        ## No. elementos del arreglo
DEFINE filas_pant       SMALLINT        ## No. elementos de cada pantalla

FOR i = 1 TO num_campos 
	LET rh_campos[i] = rm_campos[i].nombre
END FOR
LET filas_max = 100
OPEN WINDOW w_talf400_2 AT 10, 15 WITH 10 ROWS, 25 COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST -1, MESSAGE LINE LAST,
			BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_talf400_2 FROM '../forms/talf400_2'
ELSE
	OPEN FORM f_talf400_2 FROM '../forms/talf400_2c'
END IF
DISPLAY FORM f_talf400_2
LET filas_pant = fgl_scr_size("rh_campos")
CALL set_count(num_campos)
LET int_flag = 0
DISPLAY ARRAY rh_campos TO rh_campos.*
        ON KEY(INTERRUPT)
		LET int_flag = 1
                EXIT DISPLAY
        ON KEY(RETURN)
		LET int_flag = 0
		--#LET j = arr_curr()
                EXIT DISPLAY
        ON KEY(F1,CONTROL-W)
		CALL llamar_visor_teclas()
	--#BEFORE DISPLAY
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
	--#BEFORE ROW
		--#LET j = arr_curr()
		--#MESSAGE  j, ' de ', num_campos
END DISPLAY
CLOSE WINDOW w_talf400_2
IF int_flag THEN
        INITIALIZE rh_campos[1] TO NULL
        RETURN rh_campos[1]
END IF
LET i = arr_curr()
RETURN rh_campos[i]

END FUNCTION



FUNCTION preparar_tabla_de_trabajo(flag, tr_ant)
DEFINE flag		CHAR(1)
DEFINE tr_ant		SMALLINT
DEFINE factor		CHAR(8)
DEFINE expr_out		CHAR(5)
DEFINE expr_fec1	VARCHAR(200)
DEFINE expr_fec2	VARCHAR(200)
DEFINE expr_est		VARCHAR(100)
DEFINE expr_tip_tal	VARCHAR(100)
DEFINE expr_vta_tal	VARCHAR(100)
DEFINE query		CHAR(9000)

IF flag = 'F' OR tr_ant = 2 THEN
	LET expr_fec1 = "   AND DATE(t23_fec_factura) BETWEEN '",
			fecha_desde, "' AND '", fecha_hasta, "'"
	LET expr_fec2 = NULL
	LET expr_out  = 'OUTER'
END IF
IF (flag = 'D' OR flag = 'N') AND tr_ant = 1 THEN
	LET expr_fec1 = NULL
	LET expr_fec2 = "   AND DATE(t28_fec_anula) BETWEEN '",
				fecha_desde, "' AND '",
				fecha_hasta, "'"
	LET expr_out  = NULL
END IF
CASE tr_ant
	WHEN 0
		LET factor = NULL
	WHEN 1
		LET factor = ' * (-1) '
	WHEN 2
		LET factor = NULL
END CASE
LET expr_tip_tal = NULL
IF rm_t23.t23_tipo_ot IS NOT NULL THEN
	LET expr_tip_tal = "   AND t23_tipo_ot   = '", rm_t23.t23_tipo_ot, "'"
END IF
LET expr_vta_tal = NULL
IF rm_t23.t23_cont_cred <> 'T' THEN
	LET expr_vta_tal = "   AND t23_cont_cred = '", rm_t23.t23_cont_cred, "'"
END IF
LET expr_est = "   AND t23_estado    = '", flag, "'"
IF rm_t23.t23_estado = 'N' THEN
	LET expr_est = "   AND t23_estado    = 'D'"
END IF
LET query = "INSERT INTO tmp_det ",
		"SELECT CASE WHEN t23_estado = 'D' AND ", tr_ant, " = 1 ",
			" THEN (SELECT DATE(t28_fec_anula) ",
				"FROM talt028 ",
				"WHERE t28_compania  = t23_compania ",
				"  AND t28_localidad = t23_localidad ",
				"  AND t28_factura   = t23_num_factura)",
			" ELSE DATE(t23_fec_factura) ",
			" END, ",
			" CASE WHEN t23_estado = 'D' ",
			" THEN (SELECT t28_ot_ant FROM talt028 ",
				"WHERE t28_compania  = t23_compania ",
				"  AND t28_localidad = t23_localidad ",
				"  AND t28_factura   = t23_num_factura)",
			" ELSE t23_orden ",
			" END, ",
			" CASE WHEN t23_estado = 'D' AND ", tr_ant, " = 1 ",
			" THEN (SELECT t28_num_dev FROM talt028 ",
				"WHERE t28_compania  = t23_compania ",
				"  AND t28_localidad = t23_localidad ",
				"  AND t28_factura   = t23_num_factura)",
			" ELSE t23_num_factura ",
			" END, ",
			" t23_nom_cliente, ",
		" CASE WHEN t23_estado = 'F' ",
			" THEN (t23_val_mo_tal - t23_vde_mo_tal) ",
			" ELSE (t23_val_mo_tal - t23_vde_mo_tal) ",
							factor CLIPPED,
		" END, ",
		" CASE WHEN t23_estado = 'F' THEN ",
			"(SELECT NVL(SUM(ROUND((c11_precio - c11_val_descto)",
			" * (1 + c10_recargo / 100), 2)), 0) ",
			" FROM ordt010, ordt011 ",
			" WHERE c10_compania    = t23_compania ",
			"   AND c10_localidad   = t23_localidad ",
			"   AND c10_ord_trabajo = t23_orden ",
			"   AND c10_estado      = 'C' ",
			"   AND c11_compania    = c10_compania ",
			"   AND c11_localidad   = c10_localidad ",
			"   AND c11_numero_oc   = c10_numero_oc ",
			"   AND c11_tipo        = 'S') + ",
			"(SELECT NVL(SUM(ROUND(((c11_cant_ped * c11_precio)",
			" - c11_val_descto) * (1 + c10_recargo / 100), 2))",
			", 0) ",
			" FROM ordt010, ordt011 ",
			" WHERE c10_compania    = t23_compania ",
			"   AND c10_localidad   = t23_localidad ",
			"   AND c10_ord_trabajo = t23_orden ",
			"   AND c10_estado      = 'C' ",
			"   AND c11_compania    = c10_compania ",
			"   AND c11_localidad   = c10_localidad ",
			"   AND c11_numero_oc   = c10_numero_oc ",
			"   AND c11_tipo        = 'B') + ",
			" CASE WHEN (SELECT COUNT(*) FROM ordt010 ",
				" WHERE c10_compania    = t23_compania ",
				"   AND c10_localidad   = t23_localidad ",
				"   AND c10_ord_trabajo = t23_orden ",
				"   AND c10_estado      = 'C') = 0 ",
			" THEN (t23_val_rp_tal + t23_val_rp_ext + ",
			       "t23_val_rp_cti + t23_val_otros2) ",
			" ELSE 0.00 ",
			" END ",
		" ELSE (t23_val_mo_ext + t23_val_mo_cti + ",
			"t23_val_rp_tal + t23_val_rp_ext + ",
			"t23_val_rp_cti + t23_val_otros2) ", factor CLIPPED,
		" END tot_oc, ",
		retorna_expr_inv(tr_ant, 1) CLIPPED, ", ",
		" CASE WHEN t23_estado = 'F' ",
			" THEN t23_val_otros1 ",
			" ELSE t23_val_otros1 ", factor CLIPPED,
		" END, ",
		" CASE WHEN t23_estado = 'F' ",
			" THEN (t23_val_mo_tal - t23_vde_mo_tal) ",
			" ELSE (t23_val_mo_tal - t23_vde_mo_tal) ",
							factor CLIPPED,
		" END + ",
		" CASE WHEN t23_estado = 'F' THEN ",
			"(SELECT NVL(SUM(ROUND((c11_precio - c11_val_descto)",
			" * (1 + c10_recargo / 100), 2)), 0) ",
			" FROM ordt010, ordt011 ",
			" WHERE c10_compania    = t23_compania ",
			"   AND c10_localidad   = t23_localidad ",
			"   AND c10_ord_trabajo = t23_orden ",
			"   AND c10_estado      = 'C' ",
			"   AND c11_compania    = c10_compania ",
			"   AND c11_localidad   = c10_localidad ",
			"   AND c11_numero_oc   = c10_numero_oc ",
			"   AND c11_tipo        = 'S') + ",
			"(SELECT NVL(SUM(ROUND(((c11_cant_ped * c11_precio)",
			" - c11_val_descto) * (1 + c10_recargo / 100), 2)),0) ",
			" FROM ordt010, ordt011 ",
			" WHERE c10_compania    = t23_compania ",
			"   AND c10_localidad   = t23_localidad ",
			"   AND c10_ord_trabajo = t23_orden ",
			"   AND c10_estado      = 'C' ",
			"   AND c11_compania    = c10_compania ",
			"   AND c11_localidad   = c10_localidad ",
			"   AND c11_numero_oc   = c10_numero_oc ",
			"   AND c11_tipo        = 'B') + ",
			" CASE WHEN (SELECT COUNT(*) FROM ordt010 ",
				" WHERE c10_compania    = t23_compania ",
				"   AND c10_localidad   = t23_localidad ",
				"   AND c10_ord_trabajo = t23_orden ",
				"   AND c10_estado      = 'C') = 0 ",
			" THEN (t23_val_rp_tal + t23_val_rp_ext + ",
			       "t23_val_rp_cti + t23_val_otros2) ",
			" ELSE 0.00 ",
			" END ",
		" ELSE (t23_val_mo_ext + t23_val_mo_cti + ",
			"t23_val_rp_tal + t23_val_rp_ext + ",
			"t23_val_rp_cti + t23_val_otros2) ", factor CLIPPED,
		" END + ",
		retorna_expr_inv(tr_ant, 1) CLIPPED, " + ",
		" CASE WHEN t23_estado = 'F' ",
			" THEN t23_val_otros1 ",
			" ELSE t23_val_otros1 ", factor CLIPPED,
		" END, ",
		" CASE WHEN t23_estado = 'F' ",
			" THEN t23_vde_mo_tal ",
			" ELSE t23_vde_mo_tal ", factor CLIPPED,
		" END + ",
		retorna_expr_inv(tr_ant, 1) CLIPPED, ", ",
		" CASE WHEN t23_estado = 'F' ",
			" THEN t23_val_impto ",
			" ELSE t23_val_impto ", factor CLIPPED,
		" END + ",
		retorna_expr_inv(tr_ant, 2) CLIPPED, ", ",
		" CASE WHEN ", tr_ant, " = 1 THEN t23_estado ELSE 'F' END, ",
		" t23_cod_cliente, t23_modelo, t23_porc_impto ",
		" FROM talt023, ", expr_out, " talt028 ",
		" WHERE t23_compania  = ", vg_codcia,
		"   AND t23_localidad = ", vg_codloc,
		expr_est CLIPPED,
		expr_tip_tal CLIPPED,
		expr_vta_tal CLIPPED,
		expr_fec1 CLIPPED,
		"   AND t28_compania  = t23_compania ",
		"   AND t28_localidad = t23_localidad ",
		"   AND t28_factura   = t23_num_factura ",
		expr_fec2 CLIPPED,
		" GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15 "
PREPARE cons_tmp FROM query
EXECUTE cons_tmp
IF tr_ant = 2 THEN
	LET query = 'DELETE FROM tmp_det ',
			' WHERE fecha_tran < "', fecha_desde, '"',
			'    OR fecha_tran > "', fecha_hasta, '"'
	PREPARE cons_del FROM query
	EXECUTE cons_del
	RETURN
END IF
LET query = 'SELECT num_tran num_anu, z21_tipo_doc ',
		' FROM tmp_det, talt028, OUTER cxct021 ',
		' WHERE est           = "D" ',
		'   AND t28_compania  = ', vg_codcia,
		'   AND t28_localidad = ', vg_codloc,
		'   AND t28_num_dev   = num_tran ',
		'   AND z21_compania  = t28_compania ',
		'   AND z21_localidad = t28_localidad ',
		'   AND z21_tipo_doc  = "NC" ',
		'   AND z21_areaneg   = 2 ',
		'   AND z21_cod_tran  = "FA" ',
		'   AND z21_num_tran  = t28_factura ',
		' INTO TEMP t2 '
PREPARE cons_t2 FROM query 
EXECUTE cons_t2
CASE flag
	WHEN 'N' SELECT * FROM t2 WHERE z21_tipo_doc IS NULL INTO TEMP t3
		 DELETE FROM t2 WHERE z21_tipo_doc IS NULL
	WHEN 'D' DELETE FROM t2 WHERE z21_tipo_doc IS NOT NULL
END CASE
IF rm_t23.t23_estado <> 'T' THEN
	DELETE FROM tmp_det
		WHERE est      = "D"
		  AND num_tran = (SELECT num_anu FROM t2
					WHERE num_anu = num_tran)
END IF
DROP TABLE t2
IF flag = 'N' THEN
	UPDATE tmp_det SET est = flag WHERE est = "D"
		  AND num_tran = (SELECT num_anu FROM t3
					WHERE num_anu = num_tran)
	DROP TABLE t3
END IF

END FUNCTION



FUNCTION retorna_expr_inv(tr_ant, columna)
DEFINE tr_ant		SMALLINT
DEFINE columna		SMALLINT
DEFINE col		VARCHAR(100)
DEFINE factor		CHAR(8)
DEFINE expr_vta_inv	VARCHAR(100)
DEFINE expr_fec_inv	VARCHAR(200)
DEFINE expr_dev_inv	VARCHAR(200)
DEFINE query		CHAR(2000)

IF solo_tal = 'S' THEN
	LET query = ' 0.00 '
	RETURN query CLIPPED
END IF
CASE tr_ant
	WHEN 0
		LET factor = NULL
	WHEN 1
		LET factor = ' * (-1) '
	WHEN 2
		LET factor = NULL
END CASE
LET expr_vta_inv = NULL
IF rm_t23.t23_cont_cred <> 'T' THEN
	LET expr_vta_inv = "   AND r19_cont_cred    = '", rm_t23.t23_cont_cred,
				"'"
END IF
LET expr_fec_inv = NULL
LET expr_dev_inv = NULL
IF todo_inv = 'N' THEN
	LET expr_fec_inv = '   AND EXTEND(r19_fecing, YEAR TO MONTH) >= ',
				'EXTEND(t23_fec_factura, YEAR TO MONTH) ',
			   '   AND EXTEND(r19_fecing, YEAR TO MONTH) <= ',
				'EXTEND(t23_fec_factura, YEAR TO MONTH) '
	LET expr_dev_inv = '   AND EXTEND(r19_fecing, YEAR TO MONTH) >= ',
				'EXTEND(t28_fec_anula, YEAR TO MONTH) ',
			   '   AND EXTEND(r19_fecing, YEAR TO MONTH) <= ',
				'EXTEND(t28_fec_anula, YEAR TO MONTH) '
END IF
CASE columna
	WHEN 1 LET col = 'r19_tot_bruto'
	WHEN 2 LET col = 'r19_tot_neto - r19_tot_bruto + r19_tot_dscto',
				' - r19_flete'
END CASE
LET query = " CASE WHEN t23_estado = 'F' THEN ",
		" (SELECT NVL(SUM(", col CLIPPED, "), 0) ",
			" FROM rept019 ",
			" WHERE r19_compania     = t23_compania ",
			"   AND r19_localidad    = t23_localidad ",
			"   AND r19_cod_tran     = 'FA' ",
			expr_vta_inv CLIPPED,
			"   AND r19_ord_trabajo  = t23_orden ",
			expr_fec_inv CLIPPED, ") ",
		"      WHEN t23_estado = 'D' THEN ",
			" (SELECT NVL(SUM(", col CLIPPED, "), 0) ",
							factor CLIPPED,
			" FROM rept019 ",
			" WHERE r19_compania     = t23_compania ",
			"   AND r19_localidad    = t23_localidad ",
			"   AND r19_cod_tran    IN ('DF', 'AF') ",
			expr_vta_inv CLIPPED,
			"   AND r19_ord_trabajo  = t23_orden ",
			expr_dev_inv CLIPPED, ") ",
		"      ELSE 0 ",
		" END "
RETURN query CLIPPED

END FUNCTION



REPORT report_facturas_taller(r_report)
DEFINE r_report 	RECORD
				fecha		LIKE talt023.t23_fecing,
				orden		LIKE talt023.t23_orden,
				factura		LIKE talt023.t23_num_factura,
				cliente		LIKE talt023.t23_nom_cliente,
				mo		LIKE talt023.t23_val_mo_tal,
				valor_ext	DECIMAL(14,2),
				rep_alm		LIKE talt023.t23_val_rp_alm,
				viaticos	LIKE talt023.t23_val_otros1,
				tot_bruto	LIKE talt023.t23_tot_bruto,
				tot_dscto	LIKE talt023.t23_tot_dscto,
				subtotal	DECIMAL(14,2),
				tot_impto	LIKE talt023.t23_val_impto,
				tot_neto	LIKE talt023.t23_tot_neto,
				estad		LIKE talt023.t23_estado
			END RECORD
DEFINE r_tot		RECORD
				estad		LIKE talt023.t23_estado,
				cuantos		INTEGER,
				mo		LIKE talt023.t23_val_mo_tal,
				valor_ext	DECIMAL(14,2),
				rep_alm		LIKE talt023.t23_val_rp_alm,
				viaticos	LIKE talt023.t23_val_otros1,
				tot_bruto	LIKE talt023.t23_tot_bruto,
				tot_dscto	LIKE talt023.t23_tot_dscto,
				subtotal	DECIMAL(14,2),
				tot_impto	LIKE talt023.t23_val_impto,
				tot_neto	LIKE talt023.t23_tot_neto
			END RECORD
DEFINE query		CHAR(600)
DEFINE usuario		VARCHAR(19,15)
DEFINE titulo		VARCHAR(80)
DEFINE modulo		VARCHAR(40)
DEFINE long		SMALLINT
DEFINE r_t01		RECORD LIKE talt001.*
DEFINE r_t05		RECORD LIKE talt005.*
DEFINE r_r38		RECORD LIKE rept038.*
DEFINE r_t28		RECORD LIKE talt028.*
DEFINE r_g50		RECORD LIKE gent050.*
DEFINE porce		LIKE talt023.t23_porc_impto
DEFINE total1, total2	LIKE talt023.t23_tot_neto
DEFINE nom_estado	VARCHAR(15)
DEFINE num_sri		VARCHAR(16)
DEFINE tipo		CHAR(1)
DEFINE escape		SMALLINT
DEFINE act_comp, db_c	SMALLINT
DEFINE desact_comp, db	SMALLINT
DEFINE act_10cpi	SMALLINT
DEFINE act_12cpi	SMALLINT

OUTPUT
	TOP MARGIN	1
	LEFT MARGIN	0
	RIGHT MARGIN	160
	BOTTOM MARGIN	4
	PAGE LENGTH	66
FORMAT

PAGE HEADER
	LET escape	= 27		# Iniciar sec. impresi¢n
	LET act_comp	= 15		# Activar Comprimido.
	LET desact_comp	= 18		# Cancelar Comprimido.
	LET act_10cpi	= 80		# Comprimido 10 CPI.
	LET act_12cpi	= 77		# Comprimido 12 CPI.
	CALL fl_lee_modulo(vg_modulo) RETURNING r_g50.*
	LET modulo     = "MODULO: ", r_g50.g50_nombre[1, 19] CLIPPED
	LET long       = LENGTH(modulo)
	LET usuario    = 'USUARIO: ', vg_usuario
	LET nom_estado = muestra_estado(rm_t23.t23_estado)
	LET tipo       = rm_t23.t23_cont_cred
	IF tipo = 'T' THEN
		LET tipo = NULL
	END IF
	CALL fl_justifica_titulo('D', usuario, 19) RETURNING usuario
	CALL fl_justifica_titulo('I','LISTADO DE ORDENES DE TRABAJO',80)
		RETURNING titulo
	CALL fl_lee_linea_taller(vg_codcia, rm_t04.t04_linea)
		RETURNING r_t01.*
	CALL fl_lee_tipo_orden_taller(vg_codcia, rm_t23.t23_tipo_ot)
		RETURNING r_t05.*
	print ASCII escape;
	print ASCII act_comp;
	print ASCII escape;
	print ASCII act_12cpi;
	PRINT COLUMN 005, rg_cia.g01_razonsocial,
	      COLUMN 154, 'PAGINA: ', PAGENO USING '&&&'
	PRINT COLUMN 001, modulo CLIPPED,
	      COLUMN 070, titulo CLIPPED,
	      COLUMN 154, UPSHIFT(vg_proceso) CLIPPED
	SKIP 1 LINES
	PRINT COLUMN 067, '** MONEDA        : ', rm_t23.t23_moneda, ' ',
					 	 rm_g13.g13_nombre
	PRINT COLUMN 067, '** LINEA         : ';
	IF rm_t04.t04_linea IS NOT NULL THEN
		PRINT rm_t04.t04_linea, ' ', r_t01.t01_nombre
	ELSE
		PRINT 'T O D A S'
	END IF
	IF rm_t23.t23_tipo_ot IS NOT NULL THEN
		PRINT COLUMN 067, '** TIPO DE ORDEN : ', rm_t23.t23_tipo_ot,' ',
							 r_t05.t05_nombre
	ELSE
		PRINT 'T O D O S  L O S  T I P O S'
	END IF
	PRINT COLUMN 067, '** ESTADO        : ', rm_t23.t23_estado, ' ',
						 nom_estado;
	IF solo_tal = 'S' THEN
		PRINT COLUMN 138, 'SOLO VALORES DEL TALLER'
	ELSE
		PRINT ' '
	END IF
	PRINT COLUMN 067, '** FECHA INICIAL : ', fecha_desde USING 'dd-mm-yyyy'
	PRINT COLUMN 067, '** FECHA FINAL   : ', fecha_hasta USING 'dd-mm-yyyy'
	PRINT COLUMN 067, '** TIPO          : ';
	IF rm_t23.t23_cont_cred = 'R' THEN
		PRINT tipo, ' CREDITO'
	ELSE
		IF rm_t23.t23_cont_cred = 'C' THEN
			PRINT tipo, ' CONTADO'
		ELSE
			--#IF rm_t23.t23_cont_cred = 'T' THEN
				PRINT 'T O D A S'
			--#END IF
		END IF
	END IF
	PRINT COLUMN 001, 'FECHA IMPRESION: ', TODAY USING 'dd-mm-yyyy',
		1 SPACES, TIME,
	      COLUMN 142, usuario
	PRINT COLUMN 001, '----------------------------------------------------------------------------------------------------------------------------------------------------------------'
	PRINT COLUMN 001, 'FECHA TRA.',
	      COLUMN 012, 'ORDEN',
	      COLUMN 018, 'T',
	      COLUMN 020, 'No.TRA.',
	      COLUMN 028, 'NUMERO SRI',
	      COLUMN 044, 'C L I E N T E S',
	      COLUMN 061, ' M.O.INT.',
	      COLUMN 071, ' REP. EXT.',
	      COLUMN 082, ' REP. ALM.',
	      COLUMN 093, ' VIATICOS',
	      COLUMN 103, ' TOTAL BRUTO',
	      COLUMN 116, 'TOTAL DSCT',
	      COLUMN 127, '  SUBTOTAL',
	      COLUMN 138, 'TOTAL IMPT',
	      COLUMN 149, '  TOTAL NETO'
	PRINT COLUMN 001, '----------------------------------------------------------------------------------------------------------------------------------------------------------------'

ON EVERY ROW
	NEED 3 LINES
	CASE r_report.estad
		WHEN 'F'
			SELECT * INTO r_r38.*
				FROM rept038
				WHERE r38_compania    = vg_codcia
				  AND r38_localidad   = vg_codloc
				  AND r38_tipo_fuente = 'OT'
				  AND r38_cod_tran    = 'FA'
				  AND r38_num_tran    = r_report.factura
			LET num_sri = r_r38.r38_num_sri
		WHEN 'D'
			SELECT * INTO r_t28.*
				FROM talt028
				WHERE t28_compania    = vg_codcia
				  AND t28_localidad   = vg_codloc
				  AND t28_num_dev     = r_report.factura
			LET num_sri = r_t28.t28_factura
		WHEN 'N'
			SELECT * INTO r_t28.*
				FROM talt028
				WHERE t28_compania    = vg_codcia
				  AND t28_localidad   = vg_codloc
				  AND t28_num_dev     = r_report.factura
			LET num_sri = r_t28.t28_factura
	END CASE
	PRINT COLUMN 001, DATE(r_report.fecha)	USING 'dd-mm-yyyy',
	      COLUMN 012, r_report.orden  	USING '<<&&&',
	      COLUMN 018, r_report.estad,
	      COLUMN 020, r_report.factura	USING '<<<<<<&',
	      COLUMN 028, num_sri[1, 15]	CLIPPED,
	      COLUMN 044, r_report.cliente[1,16],
	      COLUMN 061, r_report.mo 	 	USING '--,--&.##',
	      COLUMN 071, r_report.valor_ext	USING '---,--&.##',
	      COLUMN 082, r_report.rep_alm	USING '---,--&.##',
	      COLUMN 093, r_report.viaticos	USING '--,--&.##',
	      COLUMN 103, r_report.tot_bruto	USING '-,---,--&.##',
	      COLUMN 116, r_report.tot_dscto	USING '---,--&.##',
	      COLUMN 127, r_report.subtotal	USING '---,--&.##',
	      COLUMN 138, r_report.tot_impto	USING '---,--&.##',
	      COLUMN 149, r_report.tot_neto	USING '-,---,--&.##'

ON LAST ROW
	NEED 2 LINES
	PRINT COLUMN 061, '---------',
	      COLUMN 071, '----------',
	      COLUMN 082, '----------',
	      COLUMN 093, '---------',
	      COLUMN 103, '------------',
	      COLUMN 116, '----------',
	      COLUMN 127, '----------',
	      COLUMN 138, '----------',
	      COLUMN 149, '------------'
	PRINT COLUMN 048, 'TOTALES ==>  ',
	      COLUMN 061, SUM(r_report.mo) 	 	USING '--,--&.##',
	      COLUMN 071, SUM(r_report.valor_ext)	USING '---,--&.##',
	      COLUMN 082, SUM(r_report.rep_alm)		USING '---,--&.##',
	      COLUMN 093, SUM(r_report.viaticos)	USING '--,--&.##',
	      COLUMN 103, SUM(r_report.tot_bruto)	USING '-,---,--&.##',
	      COLUMN 116, SUM(r_report.tot_dscto)	USING '---,--&.##',
	      COLUMN 127, SUM(r_report.subtotal)	USING '---,--&.##',
	      COLUMN 138, SUM(r_report.tot_impto)	USING '---,--&.##',
	      COLUMN 149, SUM(r_report.tot_neto)	USING '-,---,--&.##'
	NEED 13 LINES
	SKIP 2 LINES
	PRINT COLUMN 027, 'RESUMEN POR TIPO TRANSACCION'
	PRINT COLUMN 027, '============================'
	SKIP 1 LINES
	LET query = 'SELECT est, COUNT(*), NVL(SUM(valor_mo), 0), ',
			'NVL(SUM(valor_oc), 0), NVL(SUM(valor_fa), 0), ',
			'NVL(SUM(valor_vi), 0), NVL(SUM(valor_br), 0), ',
			'NVL(SUM(valor_de), 0), NVL(SUM(valor_br - valor_de), ',
			' 0), NVL(SUM(valor_im), 0), NVL(SUM(valor_br - ',
			'valor_de + valor_im), 0) ',
			' FROM tmp_det, OUTER talt004 ',
			' WHERE t04_compania = ', vg_codcia,
			'   AND t04_modelo   = modelo ',
			'   AND t04_linea    = "', rm_t04.t04_linea, '"',
			' GROUP BY 1',
			' ORDER BY 1'
	PREPARE cons_tot FROM query
	DECLARE q_cons_tot CURSOR FOR cons_tot
	FOREACH q_cons_tot INTO r_tot.*
		PRINT COLUMN 031, 'TOTALES DE ',
			muestra_estado(r_tot.estad) CLIPPED,
		      COLUMN 052, ' (', r_tot.cuantos USING "<<<&&", ')',
		      COLUMN 061, r_tot.mo 	 	USING '--,--&.##',
		      COLUMN 071, r_tot.valor_ext	USING '---,--&.##',
		      COLUMN 082, r_tot.rep_alm		USING '---,--&.##',
		      COLUMN 093, r_tot.viaticos	USING '--,--&.##',
		      COLUMN 103, r_tot.tot_bruto	USING '-,---,--&.##',
		      COLUMN 116, r_tot.tot_dscto	USING '---,--&.##',
		      COLUMN 127, r_tot.subtotal	USING '---,--&.##',
		      COLUMN 138, r_tot.tot_impto	USING '---,--&.##',
		      COLUMN 149, r_tot.tot_neto	USING '-,---,--&.##'
	END FOREACH
	SKIP 1 LINES
	LET query = 'SELECT porc, NVL(SUM(valor_mo + valor_oc), 0), ',
				'NVL(SUM(valor_fa), 0) ',
			' FROM tmp_det, OUTER talt004 ',
			' WHERE t04_compania = ', vg_codcia,
			'   AND t04_modelo   = modelo ',
			'   AND t04_linea    = "', rm_t04.t04_linea, '"',
			' GROUP BY 1',
			' ORDER BY 1 DESC'
	PREPARE cons_tot2 FROM query
	DECLARE q_cons_tot2 CURSOR FOR cons_tot2
	FOREACH q_cons_tot2 INTO porce, total1, total2
		PRINT COLUMN 031, 'TOTAL TALLER  (IMP ',
		      porce USING "#&.##", '%)',
		      COLUMN 060, total1		USING '---,--&.##';
		IF solo_tal = 'N' THEN
			PRINT COLUMN 121, 'TOTAL INVENT. (IMP ',
				porce USING "#&.##", '%)',
			      COLUMN 151, total2	USING '---,--&.##'
		ELSE
			PRINT COLUMN 121, ' '
		END IF
	END FOREACH
	PRINT COLUMN 060, '----------';
	IF solo_tal = 'N' THEN
		PRINT COLUMN 151, '----------'
	ELSE
		PRINT COLUMN 151, ' '
	END IF
	PRINT COLUMN 031, 'TOTAL TALLER',
	      COLUMN 060, SUM(r_report.mo) + SUM(r_report.valor_ext)
		USING '---,--&.##';
	IF solo_tal = 'N' THEN
		PRINT COLUMN 121, 'TOTAL INVENTARIO',
		      COLUMN 151, SUM(r_report.rep_alm)	USING '---,--&.##';
	ELSE
		PRINT ' ';
	END IF
	print ASCII escape;
	print ASCII desact_comp;
	print ASCII escape;
	print ASCII act_10cpi

END REPORT



FUNCTION borrar_cabecera()

CLEAR FORM
INITIALIZE rm_t23.* TO NULL

END FUNCTION



FUNCTION muestra_estado(estado)
DEFINE estado		LIKE talt023.t23_estado

CASE estado
	WHEN 'A' RETURN 'ACTIVAS'
	WHEN 'C' RETURN 'CERRADAS'
	WHEN 'F' RETURN 'FACTURADAS'
	WHEN 'D' RETURN 'DEVUELTAS'
	WHEN 'N' RETURN 'ANULADAS'
	WHEN 'T' RETURN 'VENTAS'
END CASE

END FUNCTION



FUNCTION muestra_estado_tit(estado)
DEFINE estado		LIKE talt023.t23_estado

CASE estado
	WHEN 'A' DISPLAY 'ACTIVAS'    TO tit_estado
	WHEN 'C' DISPLAY 'CERRADAS'   TO tit_estado
	WHEN 'F' DISPLAY 'FACTURADAS' TO tit_estado
	WHEN 'D' DISPLAY 'DEVUELTAS'  TO tit_estado
	WHEN 'N' DISPLAY 'ANULADAS'   TO tit_estado
	WHEN 'T' DISPLAY 'VENTAS'     TO tit_estado
END CASE

END FUNCTION



FUNCTION muestra_contcred(contcred)
DEFINE contcred		LIKE talt023.t23_cont_cred

CASE contcred
	WHEN 'C' DISPLAY 'CONTADO' TO tit_cont_cred
	WHEN 'R' DISPLAY 'CREDITO' TO tit_cont_cred
	WHEN 'T' DISPLAY 'TODAS'   TO tit_cont_cred
END CASE

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
