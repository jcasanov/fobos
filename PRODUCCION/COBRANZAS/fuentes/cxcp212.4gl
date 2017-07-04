--------------------------------------------------------------------------------
-- Titulo           : cxcp212.4gl - Eliminacion Retencion de Facturas Clientes
-- Elaboracion      : 07-Oct-2008
-- Autor            : NPC
-- Formato Ejecucion: fglrun cxcp212 base modulo compania localidad
-- Ultima Correccion: 
-- Motivo Correccion: 
--------------------------------------------------------------------------------

GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE rm_j14		RECORD LIKE cajt014.*
DEFINE vm_num_rows      SMALLINT
DEFINE vm_max_rows      SMALLINT
DEFINE rm_orden 	ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1	SMALLINT
DEFINE vm_columna_2	SMALLINT
DEFINE rm_par		RECORD
				codcaj		LIKE cajt010.j10_codigo_caja,
				nomcaj		LIKE cajt002.j02_nombre_caja,
				codcli		LIKE cxct001.z01_codcli,
				nomcli		LIKE cxct001.z01_nomcli,
				cont_cred	CHAR(1)
			END RECORD
DEFINE rm_detalle	ARRAY [20000] OF RECORD
				j14_localidad	LIKE cajt014.j14_localidad,
				j14_fecha_emi	LIKE cajt014.j14_fecha_emi,
				z01_nomcli	LIKE cxct001.z01_nomcli,
				j14_num_fact_sri LIKE cajt014.j14_num_fact_sri,
				j14_num_ret_sri	LIKE cajt014.j14_num_ret_sri,
				j14_valor_ret	LIKE cajt014.j14_valor_ret,
				j14_cont_cred	LIKE cajt014.j14_cont_cred
			END RECORD
DEFINE rm_adi		ARRAY [20000] OF RECORD
				j14_tipo_fuente	LIKE cajt014.j14_tipo_fuente,
				j14_num_fuente	LIKE cajt014.j14_num_fuente,
				j10_codcli	LIKE cajt010.j10_codcli,
				j14_cod_tran	LIKE cajt014.j14_cod_tran,
				j14_num_tran	LIKE cajt014.j14_num_tran,
				j10_areaneg	LIKE cajt010.j10_areaneg,
				j14_tipo_comp	LIKE cajt014.j14_tipo_comp,
				j14_num_comp	LIKE cajt014.j14_num_comp,
				j14_fec_emi_fact LIKE cajt014.j14_fec_emi_fact,
				z20_tipo_doc	LIKE cxct020.z20_tipo_doc,
				z20_num_doc	LIKE cxct020.z20_num_doc,
				z20_dividendo	LIKE cxct020.z20_dividendo,
				j10_moneda	LIKE cajt010.j10_moneda,
				j14_secuencia	LIKE cajt014.j14_secuencia,
				j14_codigo_pago	LIKE cajt014.j14_codigo_pago,
				j14_tipo_fue	LIKE cajt014.j14_tipo_fue
			END RECORD
DEFINE rm_detret	ARRAY [50] OF RECORD
				j14_codigo_pago	LIKE cajt014.j14_codigo_pago,
				j14_tipo_ret	LIKE cajt014.j14_tipo_ret,
				j14_porc_ret	LIKE cajt014.j14_porc_ret,
				j14_codigo_sri	LIKE cajt014.j14_codigo_sri,
				c03_concepto_ret LIKE ordt003.c03_concepto_ret,
				j14_base_imp	LIKE cajt014.j14_base_imp,
				j14_valor_ret	LIKE cajt014.j14_valor_ret
			END RECORD
DEFINE rm_adi_r		ARRAY [50] OF RECORD
				tipo_fuente	LIKE cajt010.j10_tipo_fuente,
				cod_tr		LIKE cajt010.j10_tipo_destino,
				num_tr		LIKE cajt010.j10_num_destino,
				num_sri		LIKE rept038.r38_num_sri,
				tipo_doc	LIKE rept038.r38_tipo_doc
			END RECORD
DEFINE tot_valor_ret	LIKE cajt014.j14_valor_ret
DEFINE vm_num_ret	SMALLINT
DEFINE vm_max_ret	SMALLINT
DEFINE tot_base_imp	DECIMAL(12,2)
DEFINE dias_tope	SMALLINT
DEFINE vm_elimino	SMALLINT



MAIN

DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/cxcp212.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 THEN
	CALL fl_mostrar_mensaje('Numero de parametros incorrecto.','stop')
     	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_codloc  = arg_val(4)
LET vg_proceso = 'cxcp212'
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
DEFINE resul	 	SMALLINT

CALL fl_nivel_isolation()
CALL fl_control_status_caja(vg_codcia, vg_codloc, 'S') RETURNING int_flag
IF int_flag <> 0 THEN
	RETURN
END IF	
CALL fl_chequeo_mes_proceso_cxc(vg_codcia) RETURNING int_flag 
IF int_flag THEN
	RETURN
END IF
LET vm_num_rows = 0
LET vm_max_rows = 20000
LET dias_tope   = 45
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
OPEN WINDOW w_cxcf212_1 AT row_ini, 02 WITH num_rows ROWS, num_cols COLUMNS
    ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE lin_menu,
		BORDER, MESSAGE LINE LAST)
IF vg_gui = 1 THEN
	OPEN FORM f_cxcf212_1 FROM '../forms/cxcf212_1'
ELSE
	OPEN FORM f_cxcf212_1 FROM '../forms/cxcf212_1c'
END IF
DISPLAY FORM f_cxcf212_1
--#DISPLAY "LC"			TO tit_col1
--#DISPLAY "Fecha Ret."		TO tit_col2
--#DISPLAY "Clientes"		TO tit_col3
--#DISPLAY "No. Fact. SRI"	TO tit_col4
--#DISPLAY "No. Ret. SRI"	TO tit_col5
--#DISPLAY "Valor Ret."		TO tit_col6
--#DISPLAY "T"			TO tit_col7
CALL muestra_contadores(0, vm_num_rows)
INITIALIZE rm_par.* TO NULL
LET rm_par.cont_cred = 'T'
LET vm_elimino       = 0
WHILE TRUE
	CALL borrar_detalle()
	IF NOT vm_elimino THEN
		CALL leer_parametros()
		IF int_flag THEN
			EXIT WHILE
		END IF
	END IF
	CALL control_consulta()
	DROP TABLE tmp_ret
END WHILE
LET int_flag = 0
CLOSE WINDOW w_cxcf212_1
EXIT PROGRAM

END FUNCTION



FUNCTION borrar_detalle()
DEFINE i		SMALLINT

FOR i = 1 TO vm_max_rows
	INITIALIZE rm_detalle[i].*, rm_adi[i].* TO NULL
END FOR
FOR i = 1 TO fgl_scr_size('rm_detalle')
	CLEAR rm_detalle[i].*
END FOR
CLEAR num_row, max_row, tot_valor_ret, tit_nomcli

END FUNCTION



FUNCTION leer_parametros()
DEFINE r_j02		RECORD LIKE cajt002.*
DEFINE r_z01		RECORD LIKE cxct001.*

LET int_flag = 0
INPUT BY NAME rm_par.*
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		LET int_flag = 1
		EXIT INPUT
	ON KEY(F2)
		IF INFIELD(codcaj) THEN
			CALL fl_ayuda_cajas(vg_codcia, vg_codloc)
				RETURNING r_j02.j02_codigo_caja,
					r_j02.j02_nombre_caja
			IF r_j02.j02_codigo_caja IS NOT NULL THEN
				LET rm_par.codcaj = r_j02.j02_codigo_caja
				LET rm_par.nomcaj = r_j02.j02_nombre_caja
				DISPLAY BY NAME rm_par.codcaj, rm_par.nomcaj
			END IF
		END IF
		IF INFIELD(codcli) THEN
			CALL fl_ayuda_cliente_localidad(vg_codcia, vg_codloc)
				RETURNING r_z01.z01_codcli, r_z01.z01_nomcli
			IF r_z01.z01_codcli IS NOT NULL THEN
				LET rm_par.codcli = r_z01.z01_codcli
				LET rm_par.nomcli = r_z01.z01_nomcli
				DISPLAY BY NAME rm_par.codcli,
						rm_par.nomcli
			END IF
		END IF
		LET int_flag = 0
	BEFORE INPUT
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
	AFTER FIELD codcaj
		IF rm_par.codcaj IS NOT NULL THEN
			CALL fl_lee_codigo_caja_caja(vg_codcia, vg_codloc,
							rm_par.codcaj)
				RETURNING r_j02.*
			IF r_j02.j02_compania IS NULL THEN
				CALL fl_mostrar_mensaje('Código de Caja no existe.','exclamation')
				NEXT FIELD codcaj
			END IF
			LET rm_par.nomcaj = r_j02.j02_nombre_caja
			DISPLAY BY NAME rm_par.nomcaj
		ELSE
			LET rm_par.nomcaj = NULL
			CLEAR nomcaj
		END IF
	AFTER FIELD codcli
		IF rm_par.codcli IS NOT NULL THEN
			CALL fl_lee_cliente_general(rm_par.codcli)
				RETURNING r_z01.*
			IF r_z01.z01_codcli IS NULL THEN
				CALL fl_mostrar_mensaje('No existe el código de este cliente en la Compañía.','exclamation')
				NEXT FIELD codcli
			END IF
			LET rm_par.nomcli = r_z01.z01_nomcli
			DISPLAY BY NAME rm_par.nomcli
		ELSE
			CLEAR nomcli
			LET rm_par.nomcli = NULL
		END IF
END INPUT

END FUNCTION



FUNCTION control_consulta()
DEFINE i		SMALLINT

FOR i = 1 TO 10
	LET rm_orden[i] = '' 
END FOR
LET vm_columna_1 = 2
LET vm_columna_2 = 5
LET rm_orden[2]  = 'ASC'
LET rm_orden[5]  = 'DESC'
CALL preparar_query()
IF vm_num_rows = 0 THEN
	CALL fl_mensaje_consulta_sin_registros()
	LET vm_elimino = 0
	RETURN
END IF
WHILE TRUE
	CALL cargar_detalle()
	CALL mostrar_detalle()
	IF int_flag OR vm_elimino THEN
		EXIT WHILE
	END IF
END WHILE

END FUNCTION



FUNCTION preparar_query()
DEFINE loc1, loc2	LIKE cajt014.j14_localidad
DEFINE query		CHAR(6000)
DEFINE expr_tip		VARCHAR(100)

LET loc1 = vg_codloc
LET loc2 = vg_codloc
IF vg_codloc = 1 THEN
	LET loc1 = 2
END IF
IF vg_codloc = 3 THEN
	LET loc1 = 4
	LET loc2 = 5
END IF
LET expr_tip = NULL
IF rm_par.cont_cred <> 'T' THEN
	LET expr_tip = '   AND j14_cont_cred  = "', rm_par.cont_cred, '"'
END IF
LET query = 'SELECT cajt014.*, j14_cod_tran z20_tipo_doc,',
			' j14_num_tran z20_num_doc, 1 z20_dividendo ',
		' FROM cajt014 ',
		' WHERE j14_compania      = ', vg_codcia,
		'   AND j14_localidad    IN (', vg_codloc, ', ', loc1, ', ',
						loc2, ')',
		expr_tip CLIPPED,
		'   AND j14_tipo_fue      = "PR" ',
		'   AND j14_fec_emi_fact >= ',
			'EXTEND(DATE(TODAY - ', dias_tope + 1, ' UNITS DAY), ',
				'YEAR TO MONTH) ',
		'   AND EXISTS ',
			'(SELECT 1 FROM ', retorna_base_loc() CLIPPED,
				'rept019 a ',
			'WHERE a.r19_compania   = j14_compania ',
			'  AND a.r19_localidad  = j14_localidad ',
			'  AND a.r19_cod_tran   = j14_cod_tran ',
			'  AND a.r19_num_tran   = j14_num_tran ',
			'  AND a.r19_tot_bruto <= ',
				' (SELECT SUM(r19_tot_bruto) ',
				'FROM ', retorna_base_loc() CLIPPED,
					'rept019 b ',
				'WHERE b.r19_compania   = a.r19_compania',
				'  AND b.r19_localidad  = a.r19_localidad',
				'  AND b.r19_cod_tran  IN ("DF", "AF")',
				'  AND b.r19_tipo_dev   = a.r19_cod_tran ',
				'  AND b.r19_num_dev    = a.r19_num_tran)) ',
		' UNION ',
		' SELECT cajt014.*, j14_cod_tran z20_tipo_doc,',
			' j14_num_tran z20_num_doc, 1 z20_dividendo ',
		' FROM cajt014 ',
		' WHERE j14_compania      = ', vg_codcia,
		'   AND j14_localidad    IN (', vg_codloc, ', ', loc1, ', ',
						loc2, ')',
		expr_tip CLIPPED,
		'   AND j14_tipo_fue      = "OT" ',
		'   AND j14_fec_emi_fact >= ',
			'EXTEND(DATE(TODAY - ', dias_tope + 1, ' UNITS DAY), ',
				'YEAR TO MONTH) ',
		'   AND EXISTS ',
			'(SELECT 1 FROM talt023 ',
			'WHERE t23_compania    = j14_compania ',
			'  AND t23_localidad   = j14_localidad ',
			'  AND t23_num_factura = j14_num_tran ',
			'  AND EXISTS ',
				'(SELECT 1 FROM talt028 ',
				'WHERE t28_compania  = t23_compania ',
				'  AND t28_localidad = t23_localidad ',
				'  AND t28_factura   = t23_num_factura)) ',
		' INTO TEMP tmp_j14 '
PREPARE exec_j14 FROM query
EXECUTE exec_j14
UPDATE tmp_j14
	SET z20_tipo_doc  = NULL,
	    z20_num_doc   = NULL,
	    z20_dividendo = NULL
	WHERE j14_cont_cred = 'C'
CASE rm_par.cont_cred
	WHEN 'C' LET query = query_principal_contado()
	WHEN 'R' LET query = query_principal_credito()
	WHEN 'T' LET query = query_principal_contado(),
				' UNION ',
				query_principal_credito()
END CASE
LET query = query CLIPPED, ' INTO TEMP tmp_ret '
PREPARE exec_tmp FROM query
EXECUTE exec_tmp
DROP TABLE tmp_j14
CALL cargar_detalle()

END FUNCTION



FUNCTION query_principal_contado()
DEFINE query		CHAR(2000)
DEFINE base_loc		VARCHAR(10)

LET base_loc = NULL
LET query    = query_contado_credito('C', 'PR', 'OT', 'SC', base_loc)
IF vg_codloc = 1 OR vg_codloc = 3 THEN
	CASE vg_codloc
		WHEN 1 LET base_loc = 'acero_gc:'
		WHEN 3 LET base_loc = 'acero_qs:'
	END CASE
	LET query = query CLIPPED,
			' UNION ',
		query_contado_credito('C', 'PR', 'OT', 'SC', base_loc) CLIPPED
END IF
RETURN query CLIPPED

END FUNCTION



FUNCTION query_principal_credito()
DEFINE query		CHAR(2000)
DEFINE base_loc		VARCHAR(10)

LET base_loc = NULL
LET query    = query_contado_credito('R', 'SC', 'SC', 'SC', base_loc),
		' UNION ',
		query_contado_credito('R', 'PR', 'OT', 'SC', base_loc)
RETURN query CLIPPED

END FUNCTION



FUNCTION query_contado_credito(cont_cred, tf1, tf2, tf3, base_loc)
DEFINE cont_cred	LIKE cajt014.j14_cont_cred
DEFINE tf1, tf2, tf3	LIKE cajt014.j14_tipo_fuente
DEFINE base_loc		VARCHAR(10)
DEFINE query		CHAR(1000)
DEFINE expr_caj		VARCHAR(100)
DEFINE expr_cli		VARCHAR(100)

LET expr_cli = NULL
IF rm_par.codcli IS NOT NULL THEN
	LET expr_cli = '   AND j10_codcli       = ', rm_par.codcli
END IF
LET expr_caj = NULL
IF rm_par.codcaj IS NOT NULL THEN
	LET expr_caj = '   AND j10_codigo_caja  = ', rm_par.codcaj
END IF
LET query = 'SELECT j14_localidad, j14_fecha_emi, z01_nomcli,j14_num_fact_sri,',
			' j14_num_ret_sri, j14_valor_ret, j14_cont_cred,',
			' j14_tipo_fuente, j14_num_fuente, j10_codcli cod_c,',
			' j14_cod_tran, j14_num_tran, j10_areaneg areaneg,',
			' j14_tipo_comp, j14_num_comp, j14_fec_emi_fact,',
			' z20_tipo_doc, z20_num_doc, z20_dividendo,',
			' j10_moneda, j14_secuencia, j14_codigo_pago,',
			' j14_tipo_fue ',
		' FROM tmp_j14, ', base_loc CLIPPED, 'cajt011, ',
			base_loc CLIPPED, 'cajt010, cxct001 ',
		' WHERE j14_tipo_fuente IN ("', tf1, '", "', tf2, '", "', tf3,
						'") ',
		'   AND j14_cont_cred    = "', cont_cred, '"',
		'   AND j11_compania     = j14_compania ',
		'   AND j11_localidad    = j14_localidad ',
		'   AND j11_tipo_fuente  = j14_tipo_fuente ',
		'   AND j11_num_fuente   = j14_num_fuente ',
		'   AND j11_secuencia    = j14_secuencia ',
		'   AND j10_compania     = j11_compania ',
		'   AND j10_localidad    = j11_localidad ',
		'   AND j10_tipo_fuente  = j11_tipo_fuente ',
		'   AND j10_num_fuente   = j11_num_fuente ',
		'   AND j10_estado       = "P" ',
		expr_caj CLIPPED,
		expr_cli CLIPPED,
		'   AND z01_codcli       = j10_codcli '
RETURN query CLIPPED

END FUNCTION



FUNCTION cargar_detalle()
DEFINE query		CHAR(600)

LET query = 'SELECT * FROM tmp_ret ',
		' ORDER BY ', vm_columna_1, ' ', rm_orden[vm_columna_1], ', ',
			      vm_columna_2, ' ', rm_orden[vm_columna_2]
PREPARE tmp_d FROM query	
DECLARE q_ret CURSOR FOR tmp_d
LET vm_num_rows = 1
FOREACH q_ret INTO rm_detalle[vm_num_rows].*, rm_adi[vm_num_rows].*
	LET vm_num_rows = vm_num_rows + 1
	IF vm_num_rows > vm_max_rows THEN
		EXIT FOREACH
	END IF
END FOREACH
LET vm_num_rows = vm_num_rows - 1

END FUNCTION



FUNCTION mostrar_detalle()
DEFINE r_j10		RECORD LIKE cajt010.*
DEFINE i, j, col	SMALLINT

LET vm_elimino = 0
CALL calcula_total()
LET int_flag = 0
CALL set_count(vm_num_rows)
DISPLAY ARRAY rm_detalle TO rm_detalle.*
       	ON KEY(INTERRUPT)   
		LET int_flag = 1
       	        EXIT DISPLAY  
	ON KEY(F5)
		LET i = arr_curr()
		IF control_eliminacion(i) THEN
			LET vm_elimino = 1
			LET int_flag  = 0
       	        	EXIT DISPLAY  
		END IF
	ON KEY(F6)
		LET i = arr_curr()
		CALL ver_forma_pago(i)
		LET int_flag = 0
	ON KEY(F7)
		LET i = arr_curr()
		IF rm_adi[i].z20_tipo_doc IS NULL THEN
			--#CONTINUE DISPLAY
		END IF
		CALL ver_documento(i)
		LET int_flag = 0
	ON KEY(F8)
		LET i = arr_curr()
		CALL fl_lee_cabecera_caja(vg_codcia,rm_detalle[i].j14_localidad,
						rm_adi[i].j14_tipo_fuente,
						rm_adi[i].j14_num_fuente)
			RETURNING r_j10.*
		IF r_j10.j10_tipo_destino <> 'FA' THEN
			CALL fl_ver_comprobantes_emitidos_caja(
						rm_adi[i].j14_tipo_fuente,
						rm_adi[i].j14_num_fuente,
						r_j10.j10_tipo_destino,
						r_j10.j10_num_destino,
						rm_adi[i].j10_codcli)
			LET int_flag = 0
		END IF
	ON KEY(F9)
		LET i = arr_curr()
		CALL control_retenciones(i)
		LET int_flag = 0
	ON KEY(F10)
		LET i = arr_curr()
		LET j = scr_line()
		IF rm_adi[i].z20_tipo_doc <> 'FA' THEN
			--#CONTINUE DISPLAY
		END IF
		CALL ver_factura(i)
		LET int_flag = 0
	ON KEY(F11)
		LET i = arr_curr()
		IF rm_adi[i].j14_tipo_comp IS NULL THEN
			--#CONTINUE DISPLAY
		END IF
		CALL ver_contabilizacion(i)
		LET int_flag = 0
	ON KEY(CONTROL-W)
		LET i = arr_curr()
		CALL control_imprimir()
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
	ON KEY(F20)
		LET col = 7
		EXIT DISPLAY
	--#BEFORE DISPLAY 
		--#CALL dialog.keysetlabel('ACCEPT', '')   
		--#CALL dialog.keysetlabel("F1","") 
		--#CALL dialog.keysetlabel("CONTROL-W","Imprimir") 
		--#CALL dialog.keysetlabel('RETURN', '')   
	--#BEFORE ROW 
		--#LET i = arr_curr()	
		--#LET j = scr_line()
		--#CALL muestra_etiquetas(i)
		--#IF rm_adi[i].z20_tipo_doc IS NULL THEN
			--#CALL dialog.keysetlabel("F7","") 
		--#ELSE
			--#CALL dialog.keysetlabel("F7","Documento") 
		--#END IF
		--#IF rm_adi[i].j14_tipo_comp IS NULL THEN
			--#CALL dialog.keysetlabel("F11","") 
		--#ELSE
			--#CALL dialog.keysetlabel("F11","Contabilizacion") 
		--#END IF
		--#CALL fl_lee_cabecera_caja(vg_codcia,
						--#rm_detalle[i].j14_localidad,
						--#rm_adi[i].j14_tipo_fuente,
						--#rm_adi[i].j14_num_fuente)
			--#RETURNING r_j10.*
		--#IF r_j10.j10_tipo_destino = 'FA' THEN
			--#CALL dialog.keysetlabel("F8","") 
		--#ELSE
			--#CALL dialog.keysetlabel("F8","Transaccion") 
		--#END IF
        --#AFTER DISPLAY  
                --#CONTINUE DISPLAY  
END DISPLAY
IF int_flag = 1 THEN
	RETURN
END IF
IF vm_elimino THEN
	RETURN
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

END FUNCTION



FUNCTION muestra_etiquetas(i)
DEFINE i		SMALLINT

CALL muestra_contadores(i, vm_num_rows)
DISPLAY rm_detalle[i].z01_nomcli TO tit_nomcli
MESSAGE '    Fuente: ', rm_adi[i].j14_tipo_fuente CLIPPED, '-',
	rm_adi[i].j14_num_fuente USING '<<<<<<&', '  Factura: ',
	rm_adi[i].j14_cod_tran CLIPPED, '-',
	rm_adi[i].j14_num_tran USING '<<<<<<&',
	'    Fecha Fact.: ', rm_adi[i].j14_fec_emi_fact USING 'dd-mm-yyyy'

END FUNCTION



FUNCTION calcula_total()
DEFINE i		SMALLINT

LET tot_valor_ret = 0
FOR i = 1 TO vm_num_rows
	LET tot_valor_ret = tot_valor_ret + rm_detalle[i].j14_valor_ret
END FOR
DISPLAY BY NAME tot_valor_ret

END FUNCTION



FUNCTION muestra_contadores(num_row, max_row)
DEFINE num_row, max_row	SMALLINT

DISPLAY BY NAME num_row, max_row

END FUNCTION



FUNCTION control_eliminacion(i)
DEFINE i		SMALLINT
DEFINE resp		CHAR(6)

LET int_flag = 0
CALL fl_hacer_pregunta('Esta seguro de ELIMINAR esta retencion ?', 'No')
	RETURNING resp
IF resp <> 'Yes' THEN
	RETURN 0
END IF
IF NOT eliminar_retencion(i) THEN
	RETURN 0
END IF
CALL fl_mostrar_mensaje('Retencion ha sido ELIMINADA. OK ', 'info') 
RETURN 1

END FUNCTION



FUNCTION eliminar_retencion(i)
DEFINE i		SMALLINT
DEFINE resul		SMALLINT
DEFINE r_b12		RECORD LIKE ctbt012.*
DEFINE r_z22		RECORD LIKE cxct022.*

BEGIN WORK
	IF NOT genera_documento_deudor(i) THEN
		WHENEVER ERROR STOP
		ROLLBACK WORK
		RETURN 0
	END IF
	CALL generar_aplicacion_documentos(i) RETURNING resul, r_z22.*
	IF NOT resul THEN
		WHENEVER ERROR STOP
		ROLLBACK WORK
		RETURN 0
	END IF
	CALL fl_genera_saldos_cliente(vg_codcia, vg_codloc, r_z22.z22_codcli)
	CALL genera_diario_contable(i, r_z22.*) RETURNING resul, r_b12.*
	IF NOT resul THEN
		WHENEVER ERROR STOP
		ROLLBACK WORK
		RETURN 0
	END IF
	IF NOT elimina_registro_j14(i) THEN
		WHENEVER ERROR STOP
		ROLLBACK WORK
		RETURN 0
	END IF
WHENEVER ERROR STOP
COMMIT WORK
IF r_b12.b12_compania IS NOT NULL THEN
	CALL fl_mayoriza_comprobante(r_b12.b12_compania, r_b12.b12_tipo_comp,
					r_b12.b12_num_comp, 'M')
END IF
RETURN 1

END FUNCTION



FUNCTION genera_documento_deudor(i)
DEFINE i		SMALLINT
DEFINE r_z20		RECORD LIKE cxct020.*
DEFINE resul		SMALLINT

WHENEVER ERROR CONTINUE
INITIALIZE r_z20.* TO NULL
LET r_z20.z20_compania   = vg_codcia
LET r_z20.z20_localidad  = vg_codloc
LET r_z20.z20_codcli     = rm_adi[i].j10_codcli
LET r_z20.z20_tipo_doc   = 'DI'
LET r_z20.z20_dividendo  = 1
CALL generar_secuencia_z20(r_z20.*) RETURNING resul, r_z20.z20_num_doc
IF NOT resul THEN
	RETURN 0
END IF
LET r_z20.z20_areaneg    = rm_adi[i].j10_areaneg
LET r_z20.z20_referencia = 'DOC.RT ', rm_detalle[i].j14_num_ret_sri CLIPPED,
				' P/FA-ELIMINACION'
LET r_z20.z20_fecha_emi  = TODAY
LET r_z20.z20_fecha_vcto = r_z20.z20_fecha_emi + 1 UNITS DAY
LET r_z20.z20_tasa_int   = 0 
LET r_z20.z20_tasa_mora  = 0
LET r_z20.z20_moneda     = rm_adi[i].j10_moneda
LET r_z20.z20_paridad    = 1
LET r_z20.z20_val_impto  = 0
LET r_z20.z20_valor_cap  = rm_detalle[i].j14_valor_ret
LET r_z20.z20_valor_int  = 0
LET r_z20.z20_saldo_cap  = r_z20.z20_valor_cap
LET r_z20.z20_saldo_int  = 0
LET r_z20.z20_cartera    = 1
LET r_z20.z20_linea      = obtener_grupo(r_z20.z20_areaneg)
LET r_z20.z20_subtipo    = 1
LET r_z20.z20_origen     = 'A'
LET r_z20.z20_cod_tran   = rm_adi[i].j14_cod_tran
LET r_z20.z20_num_tran   = rm_adi[i].j14_num_tran
LET r_z20.z20_num_sri    = rm_detalle[i].j14_num_ret_sri
LET r_z20.z20_usuario    = vg_usuario
LET r_z20.z20_fecing     = CURRENT
INSERT INTO cxct020 VALUES (r_z20.*)
RETURN 1

END FUNCTION



FUNCTION obtener_grupo(areaneg)
DEFINE areaneg		LIKE gent003.g03_areaneg
DEFINE r_g20		RECORD LIKE gent020.*

INITIALIZE r_g20.* TO NULL
DECLARE q_g20 CURSOR FOR
	SELECT * FROM gent020
		WHERE g20_compania = vg_codcia
		  AND g20_areaneg  = areaneg
OPEN q_g20
FETCH q_g20 INTO r_g20.*
CLOSE q_g20
FREE q_g20
RETURN r_g20.g20_grupo_linea

END FUNCTION



FUNCTION generar_secuencia_z20(r_z20)
DEFINE r_z20		RECORD LIKE cxct020.*
DEFINE num_doc		LIKE cxct020.z20_num_doc
DEFINE resul		INTEGER

LET num_doc = NULL
WHILE TRUE
	CALL fl_actualiza_control_secuencias(vg_codcia, vg_codloc, vg_modulo,
						'AA', r_z20.z20_tipo_doc)
		RETURNING num_doc
	IF num_doc <= 0 THEN
		LET resul = 0
		EXIT WHILE
	END IF
	CALL fl_lee_documento_deudor_cxc(vg_codcia, vg_codloc, r_z20.z20_codcli,
					r_z20.z20_tipo_doc, num_doc,
					r_z20.z20_dividendo)
		RETURNING r_z20.*
	IF r_z20.z20_compania IS NULL THEN
		LET resul = 1
		EXIT WHILE
	END IF
END WHILE
RETURN resul, num_doc

END FUNCTION



FUNCTION generar_aplicacion_documentos(i)
DEFINE i		SMALLINT
DEFINE r_j10		RECORD LIKE cajt010.*
DEFINE r_z20, r_z20_2	RECORD LIKE cxct020.*
DEFINE r_z21, r_z21_2	RECORD LIKE cxct021.*
DEFINE r_z22, r_z22_2	RECORD LIKE cxct022.*
DEFINE r_z23		RECORD LIKE cxct023.*
DEFINE r_r19		RECORD LIKE rept019.*
DEFINE cod_tran		LIKE rept019.r19_cod_tran
DEFINE num_tran		LIKE rept019.r19_num_tran
DEFINE mensaje		VARCHAR(200)
DEFINE resul		SMALLINT

INITIALIZE r_z21.*, r_z22.*, r_z23.* TO NULL
CALL fl_lee_cabecera_caja(vg_codcia, vg_codloc, rm_adi[i].j14_tipo_fuente,
			rm_adi[i].j14_num_fuente)
	RETURNING r_j10.*
LET cod_tran = rm_adi[i].j14_cod_tran
LET num_tran = rm_adi[i].j14_num_tran
IF r_j10.j10_areaneg = 1 THEN
	CALL fl_lee_cabecera_transaccion_rep(vg_codcia, vg_codloc,
				rm_adi[i].j14_cod_tran, rm_adi[i].j14_num_tran)
		RETURNING r_r19.*
	LET cod_tran = r_r19.r19_tipo_dev
	LET num_tran = r_r19.r19_num_dev
END IF
WHENEVER ERROR CONTINUE
DECLARE q_aplic CURSOR WITH HOLD FOR
	SELECT * FROM cxct021
		WHERE z21_compania  = r_j10.j10_compania
		  AND z21_localidad = r_j10.j10_localidad
		  AND z21_codcli    = r_j10.j10_codcli
		  AND z21_tipo_doc  = 'NC'
		  AND z21_areaneg   = rm_adi[i].j10_areaneg
		  AND z21_cod_tran  = cod_tran
		  AND z21_num_tran  = num_tran
	FOR UPDATE
OPEN q_aplic
FETCH q_aplic INTO r_z21.*
IF STATUS < 0 THEN
	WHENEVER ERROR STOP
	LET mensaje = 'El documento ', r_j10.j10_tipo_destino, '-',
			r_j10.j10_num_destino USING "<<<<<<<&",
			' esta bloqueado por otro usuario.'
	CALL fl_mostrar_mensaje(mensaje, 'exclamation')
	RETURN 0, r_z22.*
END IF
IF STATUS = NOTFOUND THEN
	WHENEVER ERROR STOP
	LET mensaje = 'El documento ', r_j10.j10_tipo_destino, '-',
			r_j10.j10_num_destino USING "<<<<<<<&",
			' ya no existe en la tabla cxct021.',
			' Llame al ADMINISTRADOR.'
	CALL fl_mostrar_mensaje(mensaje, 'exclamation')
	RETURN 0, r_z22.*
END IF
WHENEVER ERROR STOP
LET r_z22.z22_compania   = vg_codcia
LET r_z22.z22_localidad  = vg_codloc
LET r_z22.z22_codcli     = r_j10.j10_codcli
LET r_z22.z22_tipo_trn   = 'AJ'
CALL generar_secuencia_z22(r_z22.*) RETURNING resul, r_z22.z22_num_trn
IF NOT resul THEN
	RETURN 0, r_z22.*
END IF
LET r_z22.z22_areaneg    = r_j10.j10_areaneg
LET r_z22.z22_referencia = 'APLIC. COBRO: ',
				r_j10.j10_num_fuente USING '#####&',
				' EN ELIMINACION RET.'
LET r_z22.z22_fecha_emi  = TODAY
LET r_z22.z22_moneda     = r_j10.j10_moneda
LET r_z22.z22_paridad    = 1
LET r_z22.z22_tasa_mora  = 0
LET r_z22.z22_total_cap  = 0
LET r_z22.z22_total_int  = 0
LET r_z22.z22_total_mora = 0
LET r_z22.z22_subtipo    = 1
LET r_z22.z22_origen     = 'A'
LET r_z22.z22_usuario    = vg_usuario
LET r_z22.z22_fecing     = CURRENT
INSERT INTO cxct022 VALUES (r_z22.*)
LET r_z23.z23_compania   = r_z22.z22_compania
LET r_z23.z23_localidad  = r_z22.z22_localidad
LET r_z23.z23_codcli     = r_z22.z22_codcli
LET r_z23.z23_tipo_trn   = r_z22.z22_tipo_trn
LET r_z23.z23_num_trn    = r_z22.z22_num_trn
LET r_z23.z23_orden      = 1
LET r_z23.z23_areaneg    = r_z22.z22_areaneg
LET r_z23.z23_valor_cap  = 0
LET r_z23.z23_valor_int  = 0
LET r_z23.z23_valor_mora = 0
LET r_z23.z23_saldo_cap  = 0
LET r_z23.z23_saldo_int  = 0
DECLARE q_di_aplic CURSOR FOR
	SELECT * FROM cxct020
		WHERE z20_compania  = r_z22.z22_compania
		  AND z20_localidad = r_z22.z22_localidad
		  AND z20_codcli    = r_z22.z22_codcli
		  AND z20_tipo_doc  = 'DI'
		  AND z20_num_sri   = rm_detalle[i].j14_num_ret_sri
		  AND z20_saldo_cap > 0
LET resul = 1
FOREACH q_di_aplic INTO r_z20.*
	WHENEVER ERROR CONTINUE
	INITIALIZE r_z20_2.* TO NULL
	DECLARE q_proc CURSOR FOR
		SELECT * FROM cxct020
			WHERE z20_compania  = r_z20.z20_compania
			  AND z20_localidad = r_z20.z20_localidad
			  AND z20_codcli    = r_z20.z20_codcli
			  AND z20_tipo_doc  = r_z20.z20_tipo_doc
			  AND z20_num_doc   = r_z20.z20_num_doc
			  AND z20_dividendo = r_z20.z20_dividendo
		FOR UPDATE
	OPEN q_proc
	FETCH q_proc INTO r_z20_2.*
	IF STATUS < 0 THEN
		WHENEVER ERROR STOP
		LET mensaje = 'El documento ', r_z20_2.z20_tipo_doc CLIPPED,
				' ', r_z20_2.z20_num_doc CLIPPED, '-',
				r_z20_2.z20_dividendo CLIPPED USING '&&',
				' del cliente esta siendo modificado por otro ',
				'usuario.'
		CALL fl_mostrar_mensaje(mensaje, 'exclamation')
		LET resul = 0
		EXIT FOREACH
	END IF
	WHENEVER ERROR STOP
	IF r_z20_2.z20_saldo_cap = 0 THEN
		CONTINUE FOREACH
	END IF
	LET r_z23.z23_tipo_doc   = r_z20.z20_tipo_doc
	LET r_z23.z23_num_doc    = r_z20.z20_num_doc
	LET r_z23.z23_div_doc    = r_z20.z20_dividendo
	IF r_z21.z21_saldo >= rm_detalle[i].j14_valor_ret THEN
		LET r_z23.z23_tipo_favor = r_z21.z21_tipo_doc
		LET r_z23.z23_doc_favor  = r_z21.z21_num_doc
	END IF
	LET r_z23.z23_saldo_cap  = r_z20.z20_saldo_cap + r_z20.z20_saldo_int
	LET r_z23.z23_saldo_int  = r_z20.z20_saldo_int
	IF r_z20_2.z20_saldo_cap <> r_z23.z23_saldo_cap THEN
		CALL fl_mostrar_mensaje('No puede realizar el ajuste de documentos al cliente en este momento.', 'stop')
		LET resul = 0
		EXIT FOREACH
	END IF
	LET r_z23.z23_valor_cap  = r_z23.z23_saldo_cap * (-1)
	LET r_z23.z23_valor_int  = r_z23.z23_saldo_int * (-1)
	LET r_z22.z22_total_cap  = r_z22.z22_total_cap + r_z23.z23_valor_cap
	LET r_z22.z22_total_int  = r_z22.z22_total_int + r_z23.z23_valor_int
	INSERT INTO cxct023 VALUES(r_z23.*)
	LET r_z23.z23_orden      = r_z23.z23_orden + 1
	UPDATE cxct020
		SET z20_saldo_cap = z20_saldo_cap + r_z23.z23_valor_cap,
		    z20_saldo_int = z20_saldo_int + r_z23.z23_valor_int
		WHERE CURRENT OF q_proc
	CLOSE q_proc
	FREE q_proc
END FOREACH
WHENEVER ERROR CONTINUE
DECLARE q_up2 CURSOR FOR
	SELECT * FROM cxct022
		WHERE z22_compania  = r_z22.z22_compania
		  AND z22_localidad = r_z22.z22_localidad
		  AND z22_codcli    = r_z22.z22_codcli
		  AND z22_tipo_trn  = r_z22.z22_tipo_trn
		  AND z22_num_trn   = r_z22.z22_num_trn
	FOR UPDATE
OPEN q_up2
FETCH q_up2 INTO r_z22_2.*
IF STATUS < 0 THEN
	WHENEVER ERROR STOP
	LET mensaje = 'La transaccion ', r_z22_2.z22_tipo_trn CLIPPED,
			'-', r_z22_2.z22_num_trn USING "<<<<<<&",
			' esta siendo modificada por otro usuario.'
	CALL fl_mostrar_mensaje(mensaje, 'exclamation')
	RETURN 0, r_z22.*
END IF
WHENEVER ERROR STOP
UPDATE cxct022
	SET z22_total_cap = r_z22.z22_total_cap,
	    z22_total_int = r_z22.z22_total_int
	WHERE CURRENT OF q_up2
CLOSE q_up2
FREE q_up2
IF r_z21.z21_saldo >= rm_detalle[i].j14_valor_ret THEN
	WHENEVER ERROR CONTINUE
	DECLARE q_up3 CURSOR FOR
		SELECT * FROM cxct021
			WHERE z21_compania  = r_z21.z21_compania
			  AND z21_localidad = r_z21.z21_localidad
			  AND z21_codcli    = r_z21.z21_codcli
			  AND z21_tipo_doc  = r_z21.z21_tipo_doc
			  AND z21_num_doc   = r_z21.z21_num_doc
		FOR UPDATE
	OPEN q_up3
	FETCH q_up3 INTO r_z21_2.*
	IF STATUS < 0 THEN
		WHENEVER ERROR STOP
		LET mensaje = 'El documento ', r_z21_2.z21_tipo_doc CLIPPED,
				'-', r_z21_2.z21_num_doc USING "<<<<<<&",
				' esta siendo modificado por otro usuario.'
		CALL fl_mostrar_mensaje(mensaje, 'exclamation')
		RETURN 0, r_z22.*
	END IF
	WHENEVER ERROR STOP
	UPDATE cxct021
		SET z21_saldo = z21_saldo + r_z22.z22_total_cap
		WHERE CURRENT OF q_up3
	CLOSE q_up3
	FREE q_up3
END IF
RETURN resul, r_z22.*

END FUNCTION



FUNCTION generar_secuencia_z22(r_z22)
DEFINE r_z22		RECORD LIKE cxct022.*
DEFINE num_trn		LIKE cxct022.z22_num_trn
DEFINE resul		INTEGER

LET num_trn = NULL
WHILE TRUE
	CALL fl_actualiza_control_secuencias(vg_codcia, vg_codloc, vg_modulo,
						'AA', r_z22.z22_tipo_trn)
		RETURNING num_trn
	IF num_trn <= 0 THEN
		LET resul = 0
		EXIT WHILE
	END IF
	CALL fl_lee_transaccion_cxc(vg_codcia, vg_codloc, r_z22.z22_codcli,
					r_z22.z22_tipo_trn, num_trn)
		RETURNING r_z22.*
	IF r_z22.z22_compania IS NULL THEN
		LET resul = 1
		EXIT WHILE
	END IF
END WHILE
RETURN resul, num_trn

END FUNCTION



FUNCTION genera_diario_contable(i, r_z22)
DEFINE i		SMALLINT
DEFINE r_z22		RECORD LIKE cxct022.*
DEFINE r_ccomp		RECORD LIKE ctbt012.*
DEFINE r_b41		RECORD LIKE ctbt041.*
DEFINE r_b42		RECORD LIKE ctbt042.*
DEFINE r_j01		RECORD LIKE cajt001.*
DEFINE r_j14		RECORD LIKE cajt014.*
DEFINE r_j91		RECORD LIKE cajt091.*
DEFINE r_g03		RECORD LIKE gent003.*
DEFINE r_g20		RECORD LIKE gent020.*
DEFINE r_z09		RECORD LIKE cxct009.*
DEFINE aux_ret		LIKE cajt001.j01_aux_cont

INITIALIZE r_ccomp.* TO NULL
LET r_ccomp.b12_compania    = vg_codcia
LET r_ccomp.b12_tipo_comp   = 'DC'
LET r_ccomp.b12_fec_proceso = TODAY
CALL fl_numera_comprobante_contable(r_ccomp.b12_compania, r_ccomp.b12_tipo_comp,
		YEAR(r_ccomp.b12_fec_proceso), MONTH(r_ccomp.b12_fec_proceso))
	RETURNING r_ccomp.b12_num_comp
IF r_ccomp.b12_num_comp = '-1' THEN
	RETURN 0, r_ccomp.*
END IF
LET r_ccomp.b12_estado    = 'A'
LET r_ccomp.b12_subtipo   = 58
LET r_ccomp.b12_glosa     = 'COMPROBANTE: ', r_z22.z22_tipo_trn, '-',
				r_z22.z22_num_trn USING '<<<<<<&',
				' POR ELIMINACION RETENCION: ',
				rm_detalle[i].j14_num_ret_sri CLIPPED, ' ',
				'DEL CLIENTE: ', rm_adi[i].j10_codcli
				USING '<<<<<<&', ' ',
				rm_detalle[i].z01_nomcli[1, 45] CLIPPED
LET r_ccomp.b12_origen    = 'A'
LET r_ccomp.b12_moneda    = rm_adi[i].j10_moneda
LET r_ccomp.b12_paridad   = 1
LET r_ccomp.b12_modulo    = vg_modulo
LET r_ccomp.b12_usuario   = vg_usuario
LET r_ccomp.b12_fecing    = CURRENT
INSERT INTO ctbt012 VALUES (r_ccomp.*)
CALL fl_lee_area_negocio(vg_codcia, rm_adi[i].j10_areaneg) RETURNING r_g03.* 
CALL fl_lee_auxiliares_caja(vg_codcia, vg_codloc, r_g03.g03_modulo,
				obtener_grupo(rm_adi[i].j10_areaneg))
	RETURNING r_b41.*
IF NOT genera_detalle_diario(1, i, r_ccomp.*, r_b41.b41_cxc_mb, 'D') THEN
	INITIALIZE r_ccomp.* TO NULL
	RETURN 0, r_ccomp.*
END IF
-- FORMA DE CONTABILIZAR RETENCIONES DE CREDITO Y/O CONTADO
DECLARE q_j14 CURSOR FOR
	SELECT * FROM cajt014
		WHERE j14_compania    = vg_codcia
		  AND j14_localidad   = rm_detalle[i].j14_localidad
		  AND j14_tipo_fuente = rm_adi[i].j14_tipo_fuente
		  AND j14_num_fuente  = rm_adi[i].j14_num_fuente
		  AND j14_secuencia   = rm_adi[i].j14_secuencia
		  AND j14_codigo_pago = rm_adi[i].j14_codigo_pago
		ORDER BY j14_sec_ret
OPEN q_j14
FETCH q_j14 INTO r_j14.*
CLOSE q_j14
FREE q_j14
CALL fl_lee_auxiliares_generales(vg_codcia, vg_codloc) RETURNING r_b42.*
LET aux_ret = r_b42.b42_reten_cred
IF r_j14.j14_cont_cred = 'C' THEN
	LET aux_ret = r_b42.b42_retencion
END IF
CALL fl_lee_det_retencion_cli(r_j14.j14_compania, rm_adi[i].j10_codcli,
			r_j14.j14_tipo_ret, r_j14.j14_porc_ret,
			r_j14.j14_codigo_sri, r_j14.j14_fec_ini_porc,
			r_j14.j14_codigo_pago, r_j14.j14_cont_cred)
	RETURNING r_z09.*
IF r_z09.z09_aux_cont IS NOT NULL THEN
	LET aux_ret = r_z09.z09_aux_cont
ELSE
	CALL fl_lee_det_tipo_ret_caja(vg_codcia, r_j14.j14_codigo_pago,
				r_j14.j14_cont_cred, r_j14.j14_tipo_ret,
				r_j14.j14_porc_ret)
		RETURNING r_j91.*
	IF r_j91.j91_aux_cont IS NOT NULL THEN
		LET aux_ret = r_j91.j91_aux_cont
	ELSE
		CALL fl_lee_tipo_pago_caja(vg_codcia, r_j14.j14_codigo_pago,
						r_j14.j14_cont_cred)
			RETURNING r_j01.*
		IF r_j01.j01_aux_cont IS NOT NULL THEN
			LET aux_ret = r_j01.j01_aux_cont
		END IF
	END IF
END IF
IF NOT genera_detalle_diario(2, i, r_ccomp.*, aux_ret, 'H') THEN
	INITIALIZE r_ccomp.* TO NULL
	RETURN 0, r_ccomp.*
END IF
--
INSERT INTO cxct040
	VALUES (vg_codcia, rm_detalle[i].j14_localidad, rm_adi[i].j10_codcli,
		r_z22.z22_tipo_trn, r_z22.z22_num_trn, r_ccomp.b12_tipo_comp,
		r_ccomp.b12_num_comp)
RETURN 1, r_ccomp.*

END FUNCTION



FUNCTION genera_detalle_diario(sec, i, r_ccomp, cuenta, tipo_mov)
DEFINE sec, i		SMALLINT
DEFINE r_ccomp		RECORD LIKE ctbt012.*
DEFINE cuenta		LIKE ctbt013.b13_cuenta
DEFINE tipo_mov		CHAR(1)
DEFINE r_dcomp		RECORD LIKE ctbt013.*

WHENEVER ERROR CONTINUE
INITIALIZE r_dcomp.* TO NULL
LET r_dcomp.b13_compania    = r_ccomp.b12_compania
LET r_dcomp.b13_tipo_comp   = r_ccomp.b12_tipo_comp
LET r_dcomp.b13_num_comp    = r_ccomp.b12_num_comp
LET r_dcomp.b13_secuencia   = sec
LET r_dcomp.b13_cuenta      = cuenta
LET r_dcomp.b13_glosa       = 'ELIM. RET. CLIENTE: ', rm_adi[i].j10_codcli
				USING '<<<<<<&', ' ',
				rm_detalle[i].z01_nomcli[1, 45] CLIPPED, ' ',
				'DOC. ', rm_adi[i].j14_cod_tran CLIPPED, '-',
				rm_adi[i].j14_num_tran USING "<<<<<<<&"
IF tipo_mov = 'D' THEN
	LET r_dcomp.b13_valor_base  = rm_detalle[i].j14_valor_ret
ELSE
	LET r_dcomp.b13_valor_base  = rm_detalle[i].j14_valor_ret * (-1)
END IF
LET r_dcomp.b13_valor_aux   = 0
LET r_dcomp.b13_fec_proceso = r_ccomp.b12_fec_proceso
LET r_dcomp.b13_num_concil  = 0
LET r_dcomp.b13_codcli      = rm_adi[i].j10_codcli
INSERT INTO ctbt013 VALUES(r_dcomp.*)
IF STATUS <> 0 THEN
	RETURN 0
END IF
RETURN 1

END FUNCTION



FUNCTION elimina_registro_j14(i)
DEFINE i		SMALLINT
DEFINE mensaje		VARCHAR(200)

WHENEVER ERROR CONTINUE
DELETE FROM cajt014
	WHERE j14_compania     = vg_codcia
	  AND j14_localidad    = rm_detalle[i].j14_localidad
	  AND j14_tipo_fuente  = rm_adi[i].j14_tipo_fuente
	  AND j14_num_fuente   = rm_adi[i].j14_num_fuente
	  AND j14_secuencia    = rm_adi[i].j14_secuencia
	  AND j14_codigo_pago  = rm_adi[i].j14_codigo_pago
	  AND j14_num_ret_sri  = rm_detalle[i].j14_num_ret_sri
	  AND j14_tipo_fue     = rm_adi[i].j14_tipo_fue
	  AND j14_cod_tran     = rm_adi[i].j14_cod_tran
	  AND j14_num_tran     = rm_adi[i].j14_num_tran
IF STATUS < 0 THEN
	WHENEVER ERROR STOP
	LET mensaje = 'La retencion ', rm_detalle[i].j14_num_ret_sri CLIPPED,
			' esta siendo modificada por otro usuario.'
	CALL fl_mostrar_mensaje(mensaje, 'exclamation')
	RETURN 0
END IF
IF STATUS = NOTFOUND THEN
	WHENEVER ERROR STOP
	LET mensaje = 'La retencion ', rm_detalle[i].j14_num_ret_sri CLIPPED,
			' ya no existe como comprobante.',
			' Llame al ADMINISTRADOR.'
	CALL fl_mostrar_mensaje(mensaje, 'exclamation')
	RETURN 0
END IF
WHENEVER ERROR STOP
RETURN 1

END FUNCTION



FUNCTION ver_forma_pago(i)
DEFINE i		SMALLINT
DEFINE param		VARCHAR(60)

LET param = ' ', rm_detalle[i].j14_localidad, ' "', rm_adi[i].j14_tipo_fuente,
		'" ', rm_adi[i].j14_num_fuente
CALL ejecuta_comando('CAJA', 'CG', 'cajp203 ', param)

END FUNCTION



FUNCTION ver_documento(i)
DEFINE i		SMALLINT
DEFINE param		VARCHAR(60)

LET param = ' ', rm_detalle[i].j14_localidad, ' ', rm_adi[i].j10_codcli, ' "',
		rm_adi[i].z20_tipo_doc, '" ', rm_adi[i].z20_num_doc, ' ',
		rm_adi[i].z20_dividendo
CALL ejecuta_comando('COBRANZAS', vg_modulo, 'cxcp200 ', param)

END FUNCTION



FUNCTION control_retenciones(i)
DEFINE i		SMALLINT
DEFINE r_r19		RECORD LIKE rept019.*
DEFINE r_r23		RECORD LIKE rept023.*
DEFINE r_t23		RECORD LIKE talt023.*
DEFINE j10_tipo_destino	LIKE cajt010.j10_tipo_destino
DEFINE j10_num_destino	LIKE cajt010.j10_num_destino
DEFINE row_ini, col_ini	SMALLINT
DEFINE row_fin, col_fin	SMALLINT
DEFINE valor_bruto	DECIMAL(14,2)
DEFINE valor_impto	DECIMAL(14,2)
DEFINE subtotal		DECIMAL(14,2)
DEFINE flete		DECIMAL(14,2)
DEFINE valor_fact	DECIMAL(14,2)

LET row_ini = 04
LET row_fin = 20
LET col_ini = 02
LET col_fin = 78
IF vg_gui = 0 THEN
	LET row_ini = 05
	LET row_fin = 18
	LET col_ini = 03
	LET col_fin = 77
END IF
OPEN WINDOW w_cxcf211_2 AT row_ini, col_ini WITH row_fin ROWS, col_fin COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE 0, BORDER,
			MESSAGE LINE LAST) 
IF vg_gui = 1 THEN
	OPEN FORM f_cxcf211_2 FROM '../forms/cxcf211_2'
ELSE
	OPEN FORM f_cxcf211_2 FROM '../forms/cxcf211_2c'
END IF
DISPLAY FORM f_cxcf211_2
LET vm_num_ret = 0
LET vm_max_ret = 50
CALL borrar_retenciones()
--#DISPLAY 'TP'		 TO tit_col1
--#DISPLAY 'T'		 TO tit_col2
--#DISPLAY '%'		 TO tit_col3
--#DISPLAY 'Cod. SRI' 	 TO tit_col4
--#DISPLAY 'Descripcion' TO tit_col5
--#DISPLAY 'Base Imp.'	 TO tit_col6
--#DISPLAY 'Valor Ret.'	 TO tit_col7
DISPLAY rm_detalle[i].j14_num_fact_sri TO num_sri
LET j10_tipo_destino = rm_adi[i].j14_cod_tran
LET j10_num_destino  = rm_adi[i].j14_num_tran
CASE rm_adi[i].j10_areaneg
	WHEN 1
		CALL fl_lee_cabecera_transaccion_rep(vg_codcia,
				rm_detalle[i].j14_localidad,
				rm_adi[i].j14_cod_tran, rm_adi[i].j14_num_tran)
			RETURNING r_r19.*
		IF r_r19.r19_compania IS NULL THEN
			CALL lee_cabecera_transaccion_loc(vg_codcia,
						rm_detalle[i].j14_localidad,
						rm_adi[i].j14_cod_tran,
						rm_adi[i].j14_num_tran)
				RETURNING r_r19.*
		END IF
		LET valor_bruto = r_r19.r19_tot_bruto - r_r19.r19_tot_dscto
		LET valor_impto = r_r19.r19_tot_neto  - r_r19.r19_tot_bruto +
					r_r19.r19_tot_dscto - r_r19.r19_flete
		LET subtotal    = valor_bruto + valor_impto
		LET flete       = r_r19.r19_flete
		LET valor_fact  = subtotal + flete
	WHEN 2
		CALL fl_lee_factura_taller(vg_codcia,
						rm_detalle[i].j14_localidad,
						rm_adi[i].j14_num_tran)
			RETURNING r_t23.*
		LET valor_bruto = r_t23.t23_tot_bruto - r_t23.t23_tot_dscto
		LET valor_impto = r_t23.t23_val_impto
		LET subtotal    = valor_bruto + valor_impto
		LET flete       = NULL
		LET valor_fact  = subtotal
END CASE
DISPLAY rm_adi[i].j10_codcli     TO j10_codcli
DISPLAY rm_detalle[i].z01_nomcli TO j10_nomcli
DISPLAY BY NAME valor_bruto, valor_impto, subtotal, flete, valor_fact,
		j10_tipo_destino, j10_num_destino
CALL consulta_retenciones(i)
LET int_flag = 0
CLOSE WINDOW w_cxcf211_2
RETURN

END FUNCTION



FUNCTION borrar_retenciones()
DEFINE i		SMALLINT

INITIALIZE rm_j14.* TO NULL
FOR i = 1 TO fgl_scr_size('rm_detret')
	CLEAR rm_detret[i].*
END FOR
FOR i = 1 TO vm_max_ret
	INITIALIZE rm_detret[i].* TO NULL
END FOR
CLEAR j14_num_ret_sri, j14_autorizacion, j14_fecha_emi, num_row, max_row,
	tot_base_imp, tot_valor_ret, j10_codcli, j10_nomcli, valor_bruto,
	valor_impto, subtotal, flete, --j10_tipo_fuente, j10_num_fuente,
	j10_tipo_destino, j10_num_destino, num_sri, concepto_ret

END FUNCTION



FUNCTION consulta_retenciones(posi)
DEFINE posi		SMALLINT
DEFINE sec		LIKE cajt014.j14_sec_ret
DEFINE num_sri		LIKE rept038.r38_num_sri
DEFINE query		CHAR(2000)
DEFINE i, j		SMALLINT

LET query = 'SELECT j14_num_ret_sri, j14_autorizacion, j14_fecha_emi, ',
			'r38_num_sri, j14_codigo_pago, j14_tipo_ret, ',
			'j14_porc_ret, j14_codigo_sri, c03_concepto_ret, ',
			'j14_base_imp, j14_valor_ret, j14_sec_ret ',
		' FROM cajt014, ', retorna_base_loc() CLIPPED, 'rept038, ',
			'ordt003 ',
		' WHERE j14_compania    = ', vg_codcia,
		'   AND j14_localidad   = ', rm_detalle[posi].j14_localidad,
		'   AND j14_tipo_fuente = "', rm_adi[posi].j14_tipo_fuente, '"',
		'   AND j14_num_fuente  = ', rm_adi[posi].j14_num_fuente,
		'   AND j14_num_ret_sri = "', rm_detalle[posi].j14_num_ret_sri,
					 '"',
		'   AND j14_cod_tran    = "', rm_adi[posi].j14_cod_tran, '"',
		'   AND j14_num_tran    = ', rm_adi[posi].j14_num_tran,
		'   AND r38_compania    = j14_compania ',
		'   AND r38_localidad   = j14_localidad ',
		'   AND r38_tipo_doc    = j14_tipo_doc ',
		'   AND r38_tipo_fuente = j14_tipo_fue ',
		'   AND r38_cod_tran    = j14_cod_tran ',
		'   AND r38_num_tran    = j14_num_tran ',
		'   AND c03_compania    = j14_compania ',
		'   AND c03_tipo_ret    = j14_tipo_ret ',
		'   AND c03_porcentaje  = j14_porc_ret ',
		'   AND c03_codigo_sri  = j14_codigo_sri ',
		'   AND c03_fecha_ini_porc = j14_fec_ini_porc ',
		' ORDER BY j14_sec_ret '
PREPARE cons_ret3 FROM query
DECLARE q_ret3 CURSOR FOR cons_ret3
LET vm_num_ret = 1
FOREACH q_ret3 INTO rm_j14.j14_num_ret_sri, rm_j14.j14_autorizacion,
		rm_j14.j14_fecha_emi, num_sri, rm_detret[vm_num_ret].*, sec
	LET vm_num_ret = vm_num_ret + 1
	IF vm_num_ret > vm_max_ret THEN
		EXIT FOREACH
	END IF
END FOREACH
LET vm_num_ret = vm_num_ret - 1
IF vm_num_ret = 0 THEN
	RETURN
END IF
DISPLAY BY NAME rm_j14.j14_num_ret_sri, rm_j14.j14_autorizacion,
		rm_j14.j14_fecha_emi, num_sri
CALL calcular_tot_retencion(vm_num_ret)
CALL muestra_contadores_det(1, vm_num_ret)
CALL set_count(vm_num_ret)
DISPLAY ARRAY rm_detret TO rm_detret.*
	ON KEY(INTERRUPT)
		EXIT DISPLAY
	ON KEY(RETURN)
		LET i = arr_curr()
        	LET j = scr_line()
		CALL muestra_contadores_det(i, vm_num_ret)
	--#BEFORE DISPLAY
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
                --#CALL dialog.keysetlabel('ACCEPT', '')
		--#CALL dialog.keysetlabel('RETURN','')
	--#BEFORE ROW
		--#LET i = arr_curr()
		--#LET j = scr_line()
		--#CALL muestra_contadores_det(i, vm_num_ret)
		--#DISPLAY rm_detret[i].c03_concepto_ret TO concepto_ret
        --#AFTER DISPLAY
                --#CONTINUE DISPLAY
END DISPLAY
CALL muestra_contadores_det(0, vm_num_ret)

END FUNCTION



FUNCTION calcular_tot_retencion(lim)
DEFINE i, lim		SMALLINT

LET tot_base_imp  = 0
LET tot_valor_ret = 0
FOR i = 1 TO lim
	LET tot_base_imp  = tot_base_imp  + rm_detret[i].j14_base_imp
	LET tot_valor_ret = tot_valor_ret + rm_detret[i].j14_valor_ret
END FOR
DISPLAY BY NAME tot_base_imp, tot_valor_ret

END FUNCTION



FUNCTION muestra_contadores_det(num_row, max_row)
DEFINE num_row, max_row	SMALLINT

DISPLAY BY NAME num_row, max_row

END FUNCTION



FUNCTION lee_cabecera_transaccion_loc(codcia, codloc, cod_tran, num_tran)
DEFINE codcia		LIKE rept019.r19_compania
DEFINE codloc		LIKE rept019.r19_localidad
DEFINE cod_tran		LIKE rept019.r19_cod_tran
DEFINE num_tran		LIKE rept019.r19_num_tran
DEFINE r_r19		RECORD LIKE rept019.*
DEFINE query		CHAR(400)

INITIALIZE r_r19.* TO NULL
IF NOT (codloc = 2 OR codloc = 4) THEN
	RETURN r_r19.*
END IF
LET query = 'SELECT * FROM ', retorna_base_loc() CLIPPED, 'rept019 ',
		' WHERE r19_compania  = ', codcia,
		'   AND r19_localidad = ', codloc,
		'   AND r19_cod_tran  = "', cod_tran, '"',
		'   AND r19_num_tran  = ', num_tran
PREPARE cons_f_loc FROM query
DECLARE q_cons_f_loc CURSOR FOR cons_f_loc
OPEN q_cons_f_loc
FETCH q_cons_f_loc INTO r_r19.*
CLOSE q_cons_f_loc
FREE q_cons_f_loc
RETURN r_r19.*

END FUNCTION



FUNCTION lee_cabecera_preventa_loc(codcia, codloc, cod_tran, num_tran)
DEFINE codcia		LIKE rept023.r23_compania
DEFINE codloc		LIKE rept023.r23_localidad
DEFINE cod_tran		LIKE rept023.r23_cod_tran
DEFINE num_tran		LIKE rept023.r23_num_tran
DEFINE r_r23		RECORD LIKE rept023.*
DEFINE query		CHAR(400)

INITIALIZE r_r23.* TO NULL
IF NOT (codloc = 2 OR codloc = 4) THEN
	SELECT * INTO r_r23.*
		FROM rept023
		WHERE r23_compania  = codcia
		  AND r23_localidad = codloc
		  AND r23_cod_tran  = cod_tran
		  AND r23_num_tran  = num_tran
	RETURN r_r23.*
END IF
LET query = 'SELECT * FROM ', retorna_base_loc() CLIPPED, 'rept023 ',
		' WHERE r23_compania  = ', codcia,
		'   AND r23_localidad = ', codloc,
		'   AND r23_cod_tran  = "', cod_tran, '"',
		'   AND r23_num_tran  = ', num_tran
PREPARE cons_p_loc FROM query
DECLARE q_cons_p_loc CURSOR FOR cons_p_loc
OPEN q_cons_p_loc
FETCH q_cons_p_loc INTO r_r23.*
CLOSE q_cons_p_loc
FREE q_cons_p_loc
RETURN r_r23.*

END FUNCTION



FUNCTION retorna_ret_fac(i)
DEFINE i		SMALLINT
DEFINE tipo_f		LIKE cajt010.j10_tipo_fuente
DEFINE cod_tr		LIKE cajt010.j10_tipo_destino
DEFINE num_tr		LIKE cajt010.j10_num_destino

CASE rm_adi[i].j10_areaneg
	WHEN 1 LET tipo_f = 'PR'
	WHEN 2 LET tipo_f = 'OT'
END CASE
LET cod_tr = rm_adi[i].j14_cod_tran
LET num_tr = rm_adi[i].j14_num_tran
RETURN tipo_f, cod_tr, num_tr

END FUNCTION



FUNCTION retorna_num_fue(i)
DEFINE i		SMALLINT
DEFINE r_r19		RECORD LIKE rept019.*
DEFINE r_r23		RECORD LIKE rept023.*
DEFINE r_t23		RECORD LIKE talt023.*
DEFINE num_f		LIKE cajt010.j10_num_fuente

CASE rm_adi[i].j10_areaneg
	WHEN 1
		CALL fl_lee_cabecera_transaccion_rep(vg_codcia,
				rm_detalle[i].j14_localidad,
				rm_adi[i].j14_cod_tran, rm_adi[i].j14_num_tran)
			RETURNING r_r19.*
		IF r_r19.r19_compania IS NULL THEN
			CALL lee_cabecera_transaccion_loc(vg_codcia,
						rm_detalle[i].j14_localidad,
						rm_adi[i].j14_cod_tran,
						rm_adi[i].j14_num_tran)
				RETURNING r_r19.*
		END IF
		CALL lee_cabecera_preventa_loc(r_r19.r19_compania,
						r_r19.r19_localidad,
						r_r19.r19_cod_tran,
						r_r19.r19_num_tran)
			RETURNING r_r23.*
		LET num_f = r_r23.r23_numprev
	WHEN 2
		CALL fl_lee_factura_taller(vg_codcia,
					rm_detalle[i].j14_localidad,
					rm_adi[i].j14_num_tran)
			RETURNING r_t23.*
		LET num_f = r_t23.t23_orden
END CASE
RETURN num_f

END FUNCTION



FUNCTION retorna_base_loc()
DEFINE base_loc		VARCHAR(10)

LET base_loc = NULL
IF NOT (vg_codloc = 2 OR vg_codloc = 4) THEN
	RETURN base_loc CLIPPED
END IF
SELECT g56_base_datos INTO base_loc
	FROM gent056
	WHERE g56_compania  = vg_codcia
	  AND g56_localidad = vg_codloc
IF base_loc IS NOT NULL THEN
	LET base_loc = base_loc CLIPPED, ':'
END IF
RETURN base_loc CLIPPED

END FUNCTION


 
FUNCTION ver_factura(i)
DEFINE i		SMALLINT
DEFINE tipo_f		LIKE cajt010.j10_tipo_fuente
DEFINE cod_tr		LIKE cajt010.j10_tipo_destino
DEFINE num_tr		LIKE cajt010.j10_num_destino
DEFINE num_f		LIKE cajt010.j10_num_fuente

IF vg_codloc = 2 OR vg_codloc = 4 THEN
	CALL fl_ver_transaccion_rep(vg_codcia,vg_codloc, rm_adi[i].j14_cod_tran,
					rm_adi[i].j14_num_tran)
ELSE
	CALL retorna_num_fue(i) RETURNING num_f
	CALL retorna_ret_fac(i)	RETURNING tipo_f, cod_tr, num_tr
	CALL fl_ver_comprobantes_emitidos_caja(tipo_f, num_f,
				rm_adi[i].j14_cod_tran, rm_adi[i].j14_num_tran,
				rm_par.codcli)
END IF

END FUNCTION


 
FUNCTION ver_contabilizacion(i)
DEFINE i		SMALLINT
DEFINE param		VARCHAR(60)

LET param = ' "', rm_adi[i].j14_tipo_comp, '" ', rm_adi[i].j14_num_comp
CALL ejecuta_comando('CONTABILIDAD', 'CB', 'ctbp201 ', param)

END FUNCTION



FUNCTION control_imprimir()
DEFINE comando		VARCHAR(100)
DEFINE i		SMALLINT

CALL fl_control_reportes() RETURNING comando
IF int_flag THEN
	RETURN
END IF
START REPORT reporte_retenciones TO PIPE comando
FOR i = 1 TO vm_num_rows
	OUTPUT TO REPORT reporte_retenciones(i)
END FOR
FINISH REPORT reporte_retenciones

END FUNCTION



REPORT reporte_retenciones(i)
DEFINE i, j		SMALLINT
DEFINE r_g01		RECORD LIKE gent001.*
DEFINE r_g02		RECORD LIKE gent002.*
DEFINE r_g50		RECORD LIKE gent050.*
DEFINE titulo		VARCHAR(80)
DEFINE modulo		VARCHAR(32)
DEFINE usuario		VARCHAR(19)
DEFINE escape		SMALLINT
DEFINE act_10cpi	SMALLINT
DEFINE act_12cpi	SMALLINT
DEFINE act_dob1		SMALLINT
DEFINE act_dob2		SMALLINT
DEFINE des_dob		SMALLINT

OUTPUT
	TOP MARGIN	1
	LEFT MARGIN	0
	RIGHT MARGIN	96
	BOTTOM MARGIN	4
	PAGE LENGTH	66

FORMAT

PAGE HEADER
	LET escape	= 27		# Iniciar sec. impresi¢n
	LET act_10cpi	= 80		# Comprimido 10 CPI.
	LET act_12cpi	= 77		# Comprimido 12 CPI.
	LET act_dob1	= 87		# Activar Doble Ancho (inicio)
	LET act_dob2	= 49		# Activar Doble Ancho (final)
	LET des_dob	= 48		# Desactivar Doble Ancho
	CALL fl_justifica_titulo('C', "LISTADO RETENCIONES CLIENTES", 39)
		RETURNING titulo
	print ASCII escape;
	print ASCII act_12cpi;
	PRINT COLUMN 012, ASCII escape, ASCII act_dob1, ASCII act_dob2,
	      COLUMN 016, titulo CLIPPED,
		ASCII escape, ASCII act_dob1, ASCII des_dob,
		ASCII escape, ASCII act_12cpi
	SKIP 1 LINES
	CALL fl_justifica_titulo('D', 'USUARIO: ' || vg_usuario, 19)
		RETURNING usuario
	CALL fl_lee_compania(vg_codcia) RETURNING r_g01.*
	CALL fl_lee_modulo(vg_modulo) RETURNING r_g50.*
	LET modulo      = 'MODULO: ', r_g50.g50_nombre[1, 19] CLIPPED
	PRINT COLUMN 001, r_g01.g01_razonsocial CLIPPED,
	      COLUMN 089, 'PAG. ', PAGENO USING "&&&"
	PRINT COLUMN 001, modulo CLIPPED,
	      COLUMN 090, UPSHIFT(vg_proceso) CLIPPED
	SKIP 1 LINES
	IF rm_par.codcaj IS NOT NULL THEN
		PRINT COLUMN 028, '** CODIGO CAJA  : ',
			rm_par.codcaj USING "<&&", ' ',
			rm_par.nomcaj CLIPPED
	ELSE
		PRINT COLUMN 028, ' '
	END IF
	IF rm_par.codcli IS NOT NULL THEN
		PRINT COLUMN 028, '** CLIENTE      : ',
			rm_par.codcli USING "<<<&&&", ' ',
			rm_par.nomcli CLIPPED
	ELSE
		PRINT COLUMN 028, ' '
	END IF
	PRINT COLUMN 028, '** TIPO         : ', rm_par.cont_cred, ' ',
		retorna_cont_cred(rm_par.cont_cred) CLIPPED
	SKIP 1 LINES
	PRINT COLUMN 001, 'FECHA IMPRESION  : ', DATE(TODAY) USING "dd-mm-yyyy",
		1 SPACES, TIME,
	      COLUMN 078, usuario
	PRINT COLUMN 001, '------------------------------------------------------------------------------------------------'
	PRINT COLUMN 001, 'LC',
	      COLUMN 004, 'FECHA RET.',
	      COLUMN 024, 'C L I E N T E S',
	      COLUMN 051, 'NO. FACT. SRI',
	      COLUMN 067, 'NO. RET. SRI',
	      COLUMN 083, '  VALOR RET.',
	      COLUMN 096, 'T'
	PRINT COLUMN 001, '------------------------------------------------------------------------------------------------'

ON EVERY ROW
	NEED 3 LINES
	PRINT COLUMN 001, rm_detalle[i].j14_localidad	  USING "&&",
	      COLUMN 004, rm_detalle[i].j14_fecha_emi	  USING "dd-mm-yyyy",
	      COLUMN 015, rm_detalle[i].z01_nomcli[1, 34] CLIPPED,
	      COLUMN 051, rm_detalle[i].j14_num_fact_sri  CLIPPED,
	      COLUMN 067, rm_detalle[i].j14_num_ret_sri   CLIPPED,
	      COLUMN 083, rm_detalle[i].j14_valor_ret	  USING "-,---,--&.##",
	      COLUMN 096, rm_detalle[i].j14_cont_cred

ON LAST ROW
	NEED 2 LINES
	PRINT COLUMN 083, '------------'
	PRINT COLUMN 073, 'TOTAL ==>',
	      COLUMN 083, SUM(rm_detalle[i].j14_valor_ret) USING "-,---,--&.##";
	print ASCII escape;
	print ASCII act_10cpi

END REPORT



FUNCTION retorna_cont_cred(cont_cred)
DEFINE cont_cred	CHAR(1)
DEFINE nom_cr		VARCHAR(15)

CASE cont_cred
	WHEN 'C' LET nom_cr = 'CONTADO'
	WHEN 'R' LET nom_cr = 'CREDITO'
	WHEN 'T' LET nom_cr = 'T O D A S'
END CASE
RETURN nom_cr

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
LET comando = 'cd ..', vg_separador, '..', vg_separador, modulo, vg_separador,
		'fuentes', vg_separador, run_prog, prog, vg_base, ' ', mod, ' ',
		vg_codcia, ' ', param
RUN comando

END FUNCTION
