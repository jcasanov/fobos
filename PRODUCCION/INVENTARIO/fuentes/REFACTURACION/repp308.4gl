--------------------------------------------------------------------------------
-- Titulo           : repp308.4gl - Consulta Comprobantes Facturas/Importaciones
-- Elaboracion      : 03-Sep-2001
-- Autor            : YEC
-- Formato Ejecucion: fglrun repp308.4gl base_datos modulo compañía localidad
-- Ultima Correccion: 08-Jul-2002
-- Motivo Correccion: Para llegar hasta la liquidacion de la importacion
--		      se le agregò un ON KEY (F5) en la funcion
--		      muestra_importacion(cod_tran, num_tran) (RCA)
--------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE r_ctrn		RECORD LIKE rept019.*
DEFINE r_dtrn		RECORD LIKE rept020.*
DEFINE r_item		RECORD LIKE rept010.*
DEFINE rm_vend		RECORD LIKE rept001.*
DEFINE rm_g05		RECORD LIKE gent005.*
DEFINE vm_size_arr_ant	INTEGER
DEFINE vm_size_arr_caj	INTEGER
DEFINE vm_size_arr_cre	INTEGER



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/repp308.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 6 AND num_args() <> 7 THEN
	CALL fl_mostrar_mensaje('Número de parámetros incorrecto.','stop')
	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_codloc  = arg_val(4)
LET vg_proceso = 'repp308'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
--#CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()

END MAIN



FUNCTION funcion_master()
DEFINE cod_tran		LIKE rept019.r19_cod_tran
DEFINE num_tran		LIKE rept019.r19_num_tran

INITIALIZE rm_vend.* TO NULL
CALL fl_lee_usuario(vg_usuario) RETURNING rm_g05.*
DECLARE qu_vd CURSOR FOR
	SELECT * FROM rept001
		WHERE r01_compania   = vg_codcia
		  AND r01_user_owner = rm_g05.g05_usuario
OPEN qu_vd 
FETCH qu_vd INTO rm_vend.*
CLOSE qu_vd 
FREE qu_vd 
DECLARE q_det CURSOR FOR
	SELECT * FROM rept020
	WHERE r20_compania  = vg_codcia
	  AND r20_localidad = vg_codloc
	  AND r20_cod_tran  = cod_tran
	  AND r20_num_tran  = num_tran
	ORDER BY r20_orden
--IF num_args() = 6 THEN
	LET cod_tran = arg_val(5)
	LET num_tran = arg_val(6)
	CASE cod_tran
		WHEN 'FA'
			CALL muestra_factura(cod_tran, num_tran)
		WHEN 'IM'
			CALL muestra_importacion(cod_tran, num_tran)
	END CASE
--END IF

END FUNCTION



FUNCTION muestra_factura(cod_tran, num_tran)
DEFINE cod_tran		LIKE rept019.r19_cod_tran
DEFINE num_tran		LIKE rept019.r19_num_tran
DEFINE tipo_dev		LIKE rept019.r19_tipo_dev
DEFINE num_dev		LIKE rept019.r19_num_dev
DEFINE r_bod		RECORD LIKE rept002.*
DEFINE r_ven		RECORD LIKE rept001.*
DEFINE r_item		RECORD LIKE rept010.*
DEFINE r_r23		RECORD LIKE rept023.*
DEFINE num_rows, i, j	SMALLINT
DEFINE num_lin		SMALLINT
DEFINE t_subtotal	DECIMAL(14,2)
DEFINE t_descuento	DECIMAL(12,2)
DEFINE t_impuesto	DECIMAL(12,2)
DEFINE t_neto		DECIMAL(14,2)
DEFINE comando		CHAR(150)
DEFINE r_trn		ARRAY[400] OF RECORD
				r20_cant_ven	LIKE rept020.r20_cant_ven,
				r20_bodega	LIKE rept020.r20_bodega,
				r20_item	LIKE rept020.r20_item,
				tit_item	VARCHAR(40),
				r20_descuento	LIKE rept020.r20_descuento,
				r20_precio	LIKE rept020.r20_precio,
				subtotal	DECIMAL(14,2)
			END RECORD
DEFINE lin_menu		SMALLINT
DEFINE row_ini  	SMALLINT
DEFINE num_rows2 	SMALLINT
DEFINE num_cols 	SMALLINT
DEFINE run_prog		CHAR(10)
DEFINE ver_trans 	SMALLINT

LET num_rows = 400
LET lin_menu = 0
LET row_ini  = 3
LET num_rows2 = 22
LET num_cols = 80
IF vg_gui = 0 THEN
	LET lin_menu = 1
	LET row_ini  = 4
	LET num_rows2 = 20
	LET num_cols = 78
END IF
OPEN WINDOW w_fact AT row_ini, 2 WITH num_rows2 ROWS, num_cols COLUMNS
	ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE lin_menu,
		  MESSAGE LINE LAST - 1, BORDER) 
IF vg_gui = 1 THEN
	OPEN FORM f_fact FROM '../forms/repf308_1'
ELSE
	OPEN FORM f_fact FROM '../forms/repf308_1c'
END IF
DISPLAY FORM f_fact
CALL fl_lee_cabecera_transaccion_rep(vg_codcia, vg_codloc, cod_tran, num_tran)
	RETURNING r_ctrn.*
IF r_ctrn.r19_compania IS NULL THEN
	CALL fl_mostrar_mensaje('Transacción no existe.','exclamation')
	RETURN
END IF
CALL validar_codigo_vendedor_trn()
CALL fl_lee_bodega_rep(vg_codcia, r_ctrn.r19_bodega_ori) RETURNING r_bod.*
CALL fl_lee_vendedor_rep(vg_codcia, r_ctrn.r19_vendedor) RETURNING r_ven.*
SELECT * INTO r_r23.* FROM rept023
	WHERE r23_compania  = vg_codcia
	  AND r23_localidad = vg_codloc
	  AND r23_cod_tran  = cod_tran
	  AND r23_num_tran  = num_tran
--DISPLAY r_bod.r02_nombre  TO tit_bod
DISPLAY r_ven.r01_nombres TO tit_vend
DISPLAY BY NAME r_ctrn.r19_num_tran, r_ctrn.r19_fecing, --r_ctrn.r19_bodega_ori,
		r_ctrn.r19_codcli,   r_ctrn.r19_nomcli,   r_ctrn.r19_dircli,
		r_ctrn.r19_telcli,   r_ctrn.r19_vendedor, r_ctrn.r19_porc_impto,
		r_r23.r23_numprev,   r_r23.r23_numprof
LET i = 0
FOREACH q_det INTO r_dtrn.*
	LET i = i + 1
	CALL fl_lee_item(vg_codcia, r_dtrn.r20_item) RETURNING r_item.*
	LET r_trn[i].r20_cant_ven  = r_dtrn.r20_cant_ven
	LET r_trn[i].r20_bodega	   = r_dtrn.r20_bodega
	LET r_trn[i].r20_item	   = r_dtrn.r20_item
	LET r_trn[i].tit_item	   = r_item.r10_nombre
	LET r_trn[i].r20_descuento = r_dtrn.r20_descuento
	LET r_trn[i].r20_precio	   = r_dtrn.r20_precio
	LET r_trn[i].subtotal	   = r_dtrn.r20_cant_ven * r_dtrn.r20_precio
	IF i = num_rows THEN
		EXIT FOREACH
	END IF
END FOREACH	
LET num_lin = i
LET t_subtotal  = r_ctrn.r19_tot_bruto
LET t_descuento = r_ctrn.r19_tot_dscto
LET t_neto      = r_ctrn.r19_tot_neto - r_ctrn.r19_flete
LET t_impuesto  = t_neto - (t_subtotal - t_descuento)
LET t_neto      = r_ctrn.r19_tot_neto
DISPLAY BY NAME t_subtotal, t_descuento, t_impuesto, t_neto, r_ctrn.r19_flete
--#DISPLAY 'Cantidad'     TO tit_col1
--#DISPLAY 'Bd'           TO tit_col2
--#DISPLAY 'Item'         TO tit_col3
--#DISPLAY 'Descripción'  TO tit_col4
--#DISPLAY '  % '         TO tit_col5
--#DISPLAY 'Precio Unit.' TO tit_col6
--#DISPLAY 'Subtotal'     TO tit_col7
{-- ESTO PARA LLAMAR AL PROGRAMA SEGÚN SEA EL AMBIENTE --}
LET run_prog = 'fglrun '
IF vg_gui = 0 THEN
	LET run_prog  = 'fglgo '
	LET ver_trans = 1
	IF num_args() = 7 THEN
		IF arg_val(7) = "T" THEN
			LET ver_trans = 0
		END IF
	END IF
END IF
{--- ---}
CALL muestra_etiquetas(r_trn[1].r20_item, 1, num_lin, "F")
CALL muestra_devanul(r_trn[1].r20_item)	RETURNING tipo_dev, num_dev 
CALL set_count(num_lin)
DISPLAY ARRAY r_trn TO r_trn.*
	ON KEY(INTERRUPT)
		EXIT DISPLAY
       	ON KEY(F1,CONTROL-W)
		CALL control_visor_teclas_caracter_1() 
	ON KEY(F5)
		CALL control_mostrar_forma_pago(vg_codcia, vg_codloc,
				r_ctrn.r19_cod_tran, r_ctrn.r19_num_tran) 
	ON KEY(F6)
		LET i = arr_curr()
		LET comando = run_prog, 'repp108 ', vg_base, ' RE ', 
			      vg_codcia, ' ', vg_codloc, ' "',
			      r_trn[i].r20_item CLIPPED, '"'
		RUN comando
	ON KEY(F7)
		LET comando = run_prog, 'repp231 ', vg_base, ' RE ', vg_codcia,
				' ', vg_codloc, ' "', cod_tran, '" ',
				num_tran 
		RUN comando
	ON KEY(F8)
		LET i = arr_curr()
		LET comando = run_prog, 'repp209 ', vg_base, ' RE ', 
			      vg_codcia, ' ', vg_codloc, ' ', r_r23.r23_numprev
		RUN comando
	ON KEY(F9)
		IF tipo_dev IS NOT NULL AND num_args() <> 7 THEN
			--CALL fl_ver_transaccion_rep(vg_codcia, vg_codloc,
			--				tipo_dev, num_dev)
			CALL ver_devolucion_anulacion_fact(tipo_dev, num_dev)
		END IF
	ON KEY(F10)
		IF ver_trans THEN
			CALL ver_transferencia(cod_tran, num_tran)
			LET int_flag = 0
		END IF
	ON KEY(RETURN)
		LET i = arr_curr()	
		LET j = scr_line()
		CALL muestra_etiquetas(r_trn[i].r20_item, i, num_lin, "F")
		CALL muestra_devanul(r_trn[i].r20_item)
			RETURNING tipo_dev, num_dev 
	--#BEFORE ROW
		--#LET i = arr_curr()
		--#CALL muestra_etiquetas(r_trn[i].r20_item, i, num_lin, "F")
		--#CALL muestra_devanul(r_trn[i].r20_item)
			--#RETURNING tipo_dev, num_dev 
		--#IF tipo_dev IS NULL OR num_args() = 7 THEN
			--#CALL dialog.keysetlabel("F9","")
		--#ELSE
			--#CALL dialog.keysetlabel("F9","Devolución/Anula.")
		--#END IF
	--#BEFORE DISPLAY 
		--#CALL dialog.keysetlabel("ACCEPT","")
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
		--#CALL dialog.keysetlabel('RETURN','')
		--#LET ver_trans = 1
		--#IF num_args() = 7 THEN
			--#IF arg_val(7) = "T" THEN
				--#LET ver_trans = 0
			--#END IF
		--#END IF
		--#IF ver_trans THEN
			--#CALL dialog.keysetlabel("F10","Transferencia")
		--#ELSE
			--#CALL dialog.keysetlabel("F10","")
		--#END IF
	--#AFTER DISPLAY 
		--#CONTINUE DISPLAY
END DISPLAY

END FUNCTION



FUNCTION muestra_devanul(item)
DEFINE item		LIKE rept020.r20_item
DEFINE r_dev		RECORD LIKE rept019.*
DEFINE r_r20		RECORD LIKE rept020.*
DEFINE salir		SMALLINT

INITIALIZE r_dev.*, r_r20.* TO NULL
IF r_ctrn.r19_tipo_dev IS NULL THEN
	CLEAR r19_tipo_dev, r19_num_dev, fec_dev
	RETURN r_r20.r20_cod_tran, r_r20.r20_num_tran
END IF
DECLARE q_dev CURSOR FOR
	SELECT * FROM rept019
		WHERE r19_compania  = vg_codcia
		  AND r19_localidad = vg_codloc
		  AND r19_cod_tran  IN ('DF', 'AF')
		  AND r19_tipo_dev  = r_ctrn.r19_cod_tran
		  AND r19_num_dev   = r_ctrn.r19_num_tran
OPEN q_dev
FOREACH q_dev INTO r_dev.*
	DECLARE q_dev_det CURSOR FOR
		SELECT * FROM rept020
			WHERE r20_compania  = vg_codcia
			  AND r20_localidad = vg_codloc
			  AND r20_cod_tran  = r_dev.r19_cod_tran
			  AND r20_num_tran  = r_dev.r19_num_tran
	OPEN q_dev_det
	LET salir = 0
	FOREACH q_dev_det INTO r_r20.*
		IF item = r_r20.r20_item THEN
			LET salir = 1
			EXIT FOREACH
		END IF
	END FOREACH
	IF salir THEN
		EXIT FOREACH
	END IF
	LET r_r20.r20_cod_tran = NULL
	LET r_r20.r20_num_tran = NULL
	LET r_dev.r19_fecing   = NULL
END FOREACH
DISPLAY r_r20.r20_cod_tran TO r19_tipo_dev
DISPLAY r_r20.r20_num_tran TO r19_num_dev
DISPLAY r_dev.r19_fecing   TO fec_dev
RETURN r_r20.r20_cod_tran, r_r20.r20_num_tran

END FUNCTION



FUNCTION muestra_importacion(cod_tran, num_tran)
DEFINE cod_tran		LIKE rept019.r19_cod_tran
DEFINE num_tran		LIKE rept019.r19_num_tran
DEFINE r_item		RECORD LIKE rept010.*
DEFINE num_rows, i, j	SMALLINT
DEFINE num_lin		SMALLINT
DEFINE t_costo		DECIMAL(14,4)
DEFINE t_fob		DECIMAL(14,4)
DEFINE comando		CHAR(150)
DEFINE r_trn	 	ARRAY[1000] OF RECORD
				r20_item	LIKE rept020.r20_item,
				r10_nombre	LIKE rept010.r10_nombre,
				r20_cant_ven	LIKE rept020.r20_cant_ven,
				r20_fob		LIKE rept020.r20_fob,
				r20_costo	LIKE rept020.r20_costo,
				subtotal	DECIMAL(14,4)
			END RECORD
DEFINE r_p01		RECORD LIKE cxpt001.*
DEFINE r_r28		RECORD LIKE rept028.*
DEFINE lin_menu		SMALLINT
DEFINE row_ini  	SMALLINT
DEFINE num_rows2 	SMALLINT
DEFINE num_cols 	SMALLINT
DEFINE run_prog		CHAR(10)
DEFINE r_r10		RECORD LIKE rept010.*

LET num_rows = 1000
LET lin_menu = 0
LET row_ini  = 3
LET num_rows2 = 22
LET num_cols = 80
IF vg_gui = 0 THEN
	LET lin_menu = 1
	LET row_ini  = 4
	LET num_rows2 = 20
	LET num_cols = 78
END IF
OPEN WINDOW w_imp AT row_ini, 2 WITH num_rows2 ROWS, num_cols COLUMNS
	ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE lin_menu,
		  MESSAGE LINE LAST - 1, BORDER) 
IF vg_gui = 1 THEN
	OPEN FORM f_imp FROM '../forms/repf308_3'
ELSE
	OPEN FORM f_imp FROM '../forms/repf308_3c'
END IF
DISPLAY FORM f_imp
CALL fl_lee_cabecera_transaccion_rep(vg_codcia, vg_codloc, cod_tran, num_tran)
	RETURNING r_ctrn.*
IF r_ctrn.r19_compania IS NULL THEN
	CALL fl_mostrar_mensaje('Transacción no existe.','exclamation')
	RETURN
END IF

CALL validar_codigo_vendedor_trn()

-- OjO 
-- 	Debe mostrarse el nombre del proveedor, no el del cliente
CALL fl_lee_liquidacion_rep(vg_codcia, vg_codloc, r_ctrn.r19_numliq)
	RETURNING r_r28.*
IF r_r28.r28_numliq IS NULL THEN
	--CALL fgl_winmessage(vg_producto,'Liquidación no existe.','exclamation')
	CALL fl_mostrar_mensaje('Liquidación no existe.','exclamation')
	RETURN
END IF
CALL fl_lee_proveedor(r_r28.r28_codprov) RETURNING r_p01.*
IF r_p01.p01_codprov IS NULL THEN
	--CALL fgl_winmessage(vg_producto,'Proveedor no existe.','exclamation')
	CALL fl_mostrar_mensaje('Proveedor no existe.','exclamation')
	RETURN
END IF

DISPLAY BY NAME r_ctrn.r19_cod_tran, r_ctrn.r19_num_tran, r_ctrn.r19_fecing, 
		r_p01.p01_nomprov,   r_ctrn.r19_numliq,   r_ctrn.r19_referencia,
		r_ctrn.r19_fact_costo, r_ctrn.r19_fact_venta, r_ctrn.r19_moneda
LET i = 0
LET t_fob = 0
FOREACH q_det INTO r_dtrn.*
	LET i = i + 1
	CALL fl_lee_item(vg_codcia, r_dtrn.r20_item) RETURNING r_item.*
	LET r_trn[i].r20_cant_ven  = r_dtrn.r20_cant_ven
	LET r_trn[i].r20_item	   = r_dtrn.r20_item
	LET r_trn[i].r10_nombre	   = r_item.r10_nombre
	LET r_trn[i].r20_fob       = r_dtrn.r20_fob
	LET r_trn[i].r20_costo	   = r_dtrn.r20_costo
	LET r_trn[i].subtotal	   = r_dtrn.r20_cant_ven * r_dtrn.r20_costo
	LET t_fob = t_fob + (r_dtrn.r20_cant_ven * r_dtrn.r20_fob)
	IF i = num_rows THEN
		EXIT FOREACH
	END IF
END FOREACH	
LET num_lin = i
LET t_costo  = r_ctrn.r19_tot_costo
DISPLAY BY NAME t_costo, t_fob
--#DISPLAY 'Item'        TO tit_col1
--#DISPLAY 'Descripción' TO tit_col2
--#DISPLAY 'Cantidad'    TO tit_col3
--#DISPLAY 'Fob Unit.'   TO tit_col4
--#DISPLAY 'Costo Unit'  TO tit_col5
--#DISPLAY 'Costo Tot.'  TO tit_col6
{-- ESTO PARA LLAMAR AL PROGRAMA SEGÚN SEA EL AMBIENTE --}
LET run_prog = '; fglrun '
IF vg_gui = 0 THEN
	LET run_prog = '; fglgo '
END IF
{--- ---}
CALL muestra_etiquetas(r_trn[1].r20_item, 1, num_lin, "I")
CALL set_count(num_lin)
DISPLAY ARRAY r_trn TO r_trn.*
	ON KEY(INTERRUPT)
		EXIT DISPLAY
       	ON KEY(F1,CONTROL-W)
		CALL control_visor_teclas_caracter_2() 
	ON KEY(F5)
--OJO Para llegar hasta la liquidacion de la importacion
		LET comando = 'cd ..', vg_separador, '..',
			   vg_separador, 
	    		  'REPUESTOS', vg_separador, 'fuentes', 
			   vg_separador, run_prog, 'repp207 ', vg_base,
			  ' ', vg_modulo, ' ', vg_codcia, ' ',vg_codloc,				  ' ', r_ctrn.r19_numliq
		RUN comando
		LET int_flag = 0
	ON KEY(RETURN)
		LET i = arr_curr()	
		LET j = scr_line()
		CALL muestra_etiquetas(r_trn[i].r20_item, i, num_lin, "I")
	--#BEFORE ROW
		--#LET i = arr_curr()
		--#CALL muestra_etiquetas(r_trn[i].r20_item, i, num_lin, "I")
	--#BEFORE DISPLAY 
		--#CALL dialog.keysetlabel("ACCEPT","")
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
	--#AFTER DISPLAY 
		--#CONTINUE DISPLAY
END DISPLAY

END FUNCTION



FUNCTION control_mostrar_forma_pago(codcia, codloc, cod_tran, num_tran)
DEFINE codcia		LIKE gent001.g01_compania 
DEFINE codloc		LIKE gent002.g02_compania 
DEFINE cod_tran		LIKE rept019.r19_cod_tran
DEFINE num_tran		LIKE rept019.r19_num_tran
DEFINE r_fp		RECORD LIKE rept025.*
DEFINE r_ctrn		RECORD LIKE rept019.*
DEFINE r_lin		RECORD LIKE rept003.*
DEFINE r_glin		RECORD LIKE gent020.*
DEFINE r_cp		RECORD LIKE cajt010.*
DEFINE r_dp		RECORD LIKE cajt011.*
DEFINE linea 		LIKE rept020.r20_linea
DEFINE i, l		SMALLINT
DEFINE num_ant		SMALLINT
DEFINE num_caj		SMALLINT
DEFINE num_cred		SMALLINT
DEFINE val_caja		DECIMAL(12,2)
DEFINE r_ant		ARRAY[100] OF RECORD
				r27_tipo	LIKE rept027.r27_tipo,
				r27_numero	LIKE rept027.r27_numero,
				r27_valor	LIKE rept027.r27_valor
			END RECORD
DEFINE r_caj		ARRAY[100] OF RECORD
				j11_codigo_pago	LIKE cajt011.j11_codigo_pago,
				nombre_bt	VARCHAR(20),
				j11_num_ch_aut	LIKE cajt011.j11_num_ch_aut,
				j11_moneda	LIKE cajt011.j11_moneda,
				j11_valor	LIKE cajt011.j11_valor
			END RECORD
DEFINE r_cred		ARRAY[100] OF RECORD
				r26_dividendo	LIKE rept026.r26_dividendo,
				r26_fec_vcto	LIKE rept026.r26_fec_vcto,
				r26_valor_cap	LIKE rept026.r26_valor_cap,
				r26_valor_int	LIKE rept026.r26_valor_int,
				tot_div		DECIMAL(12,2)
			END RECORD
DEFINE lin_menu		SMALLINT
DEFINE row_ini  	SMALLINT
DEFINE num_rows 	SMALLINT
DEFINE num_cols 	SMALLINT

CALL fl_lee_cabecera_transaccion_rep(codcia, codloc, cod_tran, num_tran)
	RETURNING r_ctrn.*
IF r_ctrn.r19_compania IS NULL THEN
	--CALL fgl_winmessage(vg_producto,'Transacción no existe.','exclamation')
	CALL fl_mostrar_mensaje('Transacción no existe.','exclamation')
	RETURN
END IF
DECLARE q_dfg CURSOR FOR SELECT r20_linea FROM rept020
	WHERE r20_compania  = codcia AND
	      r20_localidad = codloc AND
	      r20_cod_tran  = cod_tran AND
	      r20_num_tran  = num_tran
OPEN q_dfg
FETCH q_dfg INTO linea
CLOSE q_dfg
FREE q_dfg
CALL fl_lee_linea_rep(codcia, linea) RETURNING r_lin.*
CALL fl_lee_grupo_linea(codcia, r_lin.r03_grupo_linea) RETURNING r_glin.*
LET lin_menu = 0
LET row_ini  = 2
LET num_rows = 22
LET num_cols = 80
IF vg_gui = 0 THEN
	LET lin_menu = 1
	LET row_ini  = 4
	LET num_rows = 20
	LET num_cols = 78
END IF
OPEN WINDOW w_fp AT row_ini, 2 WITH num_rows ROWS, num_cols COLUMNS
	ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE lin_menu,
		  MESSAGE LINE LAST - 1, BORDER) 
IF vg_gui = 1 THEN
	OPEN FORM f_rep_fp FROM "../forms/repf308_2"
ELSE
	OPEN FORM f_rep_fp FROM "../forms/repf308_2c"
END IF
DISPLAY FORM f_rep_fp
DISPLAY BY NAME cod_tran, num_tran
--#DISPLAY 'TP.'    TO tit_ant1
--#DISPLAY 'Número' TO tit_ant2
--#DISPLAY 'Valor'  TO tit_ant3
--#DISPLAY 'TP.'                 TO tit_caj1
--#DISPLAY 'Banco/Tarjeta'       TO tit_caj2 
--#DISPLAY 'No. Cheque/Tarjeta'  TO tit_caj3
--#DISPLAY 'Mo.'                 TO tit_caj4 
--#DISPLAY 'V a l o r'           TO tit_caj5
--#DISPLAY 'No.'                 TO tit_cred1
--#DISPLAY 'Fec.Vcto.'           TO tit_cred2
--#DISPLAY 'Valor Capital'       TO tit_cred3
--#DISPLAY 'Valor Interés'       TO tit_cred4
--#DISPLAY 'Valor Total'         TO tit_cred5
INITIALIZE r_fp.* TO NULL
LET r_fp.r25_valor_ant  = 0
LET r_fp.r25_valor_cred = 0
LET num_ant             = 0
LET num_caj             = 0
LET num_cred            = 0
IF r_ctrn.r19_cont_cred = 'R' THEN
	LET r_fp.r25_valor_cred = r_ctrn.r19_tot_neto
END IF
SELECT * INTO r_fp.* FROM rept025
	WHERE r25_compania  = codcia AND 
	      r25_localidad = codloc AND 
	      r25_cod_tran  = cod_tran AND
	      r25_num_tran  = num_tran
LET val_caja = r_ctrn.r19_tot_neto - r_fp.r25_valor_ant - r_fp.r25_valor_cred
DISPLAY BY NAME r_fp.r25_valor_ant, r_fp.r25_valor_cred, r_ctrn.r19_tot_neto,
		val_caja
IF r_fp.r25_numprev IS NOT NULL THEN
	DECLARE q_dpa CURSOR FOR 
		SELECT r27_tipo, r27_numero, r27_valor
			FROM rept027
			WHERE r27_compania  = codcia AND 
		              r27_localidad = codloc AND
		              r27_numprev   = r_fp.r25_numprev
	LET num_ant = 1
	FOREACH q_dpa INTO r_ant[num_ant].*
		LET num_ant = num_ant + 1
		IF num_ant > 100 THEN
			EXIT FOREACH
		END IF
	END FOREACH
	FREE q_dpa
	LET num_ant = num_ant - 1
	DECLARE q_dcr CURSOR FOR
		SELECT r26_dividendo, r26_fec_vcto, r26_valor_cap,
		       r26_valor_int, r26_valor_cap + r26_valor_int
			FROM rept026
			WHERE r26_compania  = codcia AND 
			      r26_localidad = codloc AND 
		              r26_numprev   = r_fp.r25_numprev
			ORDER BY 1
	LET num_cred = 1
	FOREACH q_dcr INTO r_cred[num_cred].*
		LET num_cred = num_cred + 1
		IF num_cred > 100 THEN
			EXIT FOREACH
		END IF
	END FOREACH
	FREE q_dcr
	LET num_cred = num_cred - 1
END IF
DECLARE q_caj CURSOR FOR
	SELECT cajt010.*, cajt011.* FROM cajt010, cajt011
		WHERE j10_compania     = codcia AND 
              	      j10_localidad    = codloc AND
      	      	      j10_areaneg      = r_glin.g20_areaneg AND
      	      	      j10_tipo_destino = cod_tran AND 
              	      j10_num_destino  = num_tran AND
      	      	      j10_compania     = j11_compania AND
      	              j10_localidad    = j11_localidad AND
      	              j10_tipo_fuente  = j11_tipo_fuente AND 
     	              j10_num_fuente   = j11_num_fuente
LET num_caj = 0
OPEN q_caj
WHILE TRUE
	FETCH q_caj INTO r_cp.*, r_dp.*
	IF status = NOTFOUND THEN
		EXIT WHILE
	END IF
	LET num_caj = num_caj + 1
	LET r_caj[num_caj].j11_codigo_pago  = r_dp.j11_codigo_pago
	LET r_caj[num_caj].j11_num_ch_aut   = r_dp.j11_num_ch_aut
	LET r_caj[num_caj].j11_moneda	    = r_dp.j11_moneda
	LET r_caj[num_caj].j11_valor	    = r_dp.j11_valor
	IF r_dp.j11_codigo_pago = 'CH' THEN
		SELECT g08_nombre INTO r_caj[num_caj].nombre_bt 
			FROM gent008
			WHERE g08_banco = r_dp.j11_cod_bco_tarj
	END IF
 	IF r_dp.j11_codigo_pago = 'TJ' THEN
		SELECT g10_nombre INTO r_caj[num_caj].nombre_bt 
			FROM gent010
			WHERE g10_tarjeta = r_dp.j11_cod_bco_tarj
	END IF
	IF num_caj > 100 THEN
		EXIT WHILE
	END IF
END WHILE
CLOSE q_caj
FREE q_caj
--#LET vm_size_arr_ant = fgl_scr_size('r_ant')
IF vg_gui = 0 THEN
	LET vm_size_arr_ant = 3
END IF
FOR i = 1 TO vm_size_arr_ant
	IF i <= num_ant THEN
		DISPLAY r_ant[i].* TO r_ant[i].*
	END IF
END FOR	
--#LET vm_size_arr_caj = fgl_scr_size('r_caj')
IF vg_gui = 0 THEN
	LET vm_size_arr_caj = 3
END IF
FOR i = 1 TO vm_size_arr_caj 
	IF i <= num_caj THEN
		DISPLAY r_caj[i].* TO r_caj[i].*
	END IF
END FOR	
--#LET vm_size_arr_cre = fgl_scr_size('r_cred')
IF vg_gui = 0 THEN
	LET vm_size_arr_cre = 3
END IF
FOR i = 1 TO vm_size_arr_cre
	IF i <= num_cred THEN
		DISPLAY r_cred[i].* TO r_cred[i].*
	END IF
END FOR	
CALL muestra_contadores_fp(0, num_ant, 0, num_caj, 0, num_cred)
LET l = 0
IF vg_gui = 0 THEN
	LET l = 1
END IF
MENU 'OPCIONES'
	BEFORE MENU
		IF num_ant = 0 THEN
			HIDE OPTION 'Anticipos'
		END IF
		IF num_caj = 0 THEN
			HIDE OPTION 'Caja'
		END IF
		IF num_cred = 0 THEN
			HIDE OPTION 'Crédito'
		END IF
	COMMAND 'Anticipos'
		IF num_ant = 0 THEN
			CONTINUE MENU
		END IF
		CALL muestra_contadores_fp(l, num_ant, 0, num_caj, 0, num_cred)
		CALL set_count(num_ant)
		DISPLAY ARRAY r_ant TO r_ant.*
			ON KEY(INTERRUPT)
				EXIT DISPLAY
       			ON KEY(F1,CONTROL-W)
				CALL control_visor_teclas_caracter_3() 
			ON KEY(RETURN)
				LET i = arr_curr()
				CALL muestra_contadores_fp(i, num_ant, 0,
							num_caj, 0, num_cred)
			ON KEY(F5)
				LET i = arr_curr()
				CALL ver_documento(r_ant[i].*)
			--#BEFORE ROW
				--#LET i = arr_curr()
				--#CALL muestra_contadores_fp(i, num_ant, 0,
							--#num_caj, 0, num_cred)
			--#BEFORE DISPLAY
				--#CALL dialog.keysetlabel("ACCEPT","")
				--#CALL dialog.keysetlabel("F1","")
				--#CALL dialog.keysetlabel("F5","Documento")
				--#CALL dialog.keysetlabel("CONTROL-W","")
			--#AFTER DISPLAY
				--#CONTINUE DISPLAY
		END DISPLAY
		CALL muestra_contadores_fp(0, num_ant, 0, num_caj, 0, num_cred)
	COMMAND 'Caja'
		IF num_caj = 0 THEN
			CONTINUE MENU
		END IF
		CALL muestra_contadores_fp(0, num_ant, l, num_caj, 0, num_cred)
		CALL set_count(num_caj)
		DISPLAY ARRAY r_caj TO r_caj.*
			ON KEY(INTERRUPT)
				EXIT DISPLAY
		        ON KEY(F1,CONTROL-W)
				CALL llamar_visor_teclas()
			ON KEY(RETURN)
				LET i = arr_curr()
				CALL muestra_contadores_fp(0, num_ant, i,
							num_caj, 0, num_cred)
			--#BEFORE ROW
				--#LET i = arr_curr()
				--#CALL muestra_contadores_fp(0, num_ant, i,
							--#num_caj, 0, num_cred)
			--#BEFORE DISPLAY
				--#CALL dialog.keysetlabel("ACCEPT","")
				--#CALL dialog.keysetlabel("F1","")
				--#CALL dialog.keysetlabel("F5","")
				--#CALL dialog.keysetlabel("CONTROL-W","")
			--#AFTER DISPLAY
				--#CONTINUE DISPLAY
		END DISPLAY
		CALL muestra_contadores_fp(0, num_ant, 0, num_caj, 0, num_cred)
	COMMAND 'Crédito'
		IF num_cred = 0 THEN
			CONTINUE MENU
		END IF
		CALL muestra_contadores_fp(0, num_ant, 0, num_caj, l, num_cred)
		CALL set_count(num_cred)
		DISPLAY ARRAY r_cred TO r_cred.*
			ON KEY(INTERRUPT)
				EXIT DISPLAY
		        ON KEY(F1,CONTROL-W)
				CALL llamar_visor_teclas()
			ON KEY(RETURN)
				LET i = arr_curr()
				CALL muestra_contadores_fp(0, num_ant, 0,
							num_caj, i, num_cred)
			--#BEFORE ROW
				--#LET i = arr_curr()
				--#CALL muestra_contadores_fp(0, num_ant, 0,
							--#num_caj, i, num_cred)
			--#BEFORE DISPLAY
				--#CALL dialog.keysetlabel("ACCEPT","")
				--#CALL dialog.keysetlabel("F1","")
				--#CALL dialog.keysetlabel("F5","")
				--#CALL dialog.keysetlabel("CONTROL-W","")
			--#AFTER DISPLAY
				--#CONTINUE DISPLAY
		END DISPLAY
		CALL muestra_contadores_fp(0, num_ant, 0, num_caj, 0, num_cred)
	COMMAND 'Salir'
		EXIT MENU
END MENU
CLOSE WINDOW w_fp

END FUNCTION



FUNCTION validar_codigo_vendedor_trn()
DEFINE r_j02		RECORD LIKE cajt002.*
DEFINE r_r01		RECORD LIKE rept001.*

IF rm_g05.g05_tipo = 'UF' THEN
	IF rm_vend.r01_compania IS NULL THEN
		INITIALIZE r_j02.* TO NULL
		DECLARE q_j02 CURSOR FOR
			SELECT * FROM cajt002
				WHERE j02_compania  = vg_codcia
				  AND j02_localidad = vg_codloc
				  AND j02_usua_caja = rm_g05.g05_usuario
		OPEN q_j02
		FETCH q_j02 INTO r_j02.*
		CLOSE q_j02
		FREE q_j02
		IF r_j02.j02_compania IS NULL THEN
			CALL fl_mostrar_mensaje('Usted no es un usuario de caja.', 'stop')
			EXIT PROGRAM
		END IF
		RETURN
	END IF
	IF rm_vend.r01_tipo <> 'G' THEN
		IF rm_vend.r01_codigo <> r_ctrn.r19_vendedor THEN
			IF rm_vend.r01_tipo <> 'J' THEN
				CALL fl_mostrar_mensaje('Usted no puede ver este comprobante que no tiene su codigo de vendedor.', 'stop')
				EXIT PROGRAM
			END IF
			CALL fl_lee_vendedor_rep(vg_codcia, r_ctrn.r19_vendedor)
				RETURNING r_r01.*
			IF r_r01.r01_tipo = 'G' OR r_r01.r01_tipo = 'J' THEN
				CALL fl_mostrar_mensaje('Usted no puede ver este comprobante que tiene codigo de jefe o gerente que no es el suyo.', 'stop')
				EXIT PROGRAM
			END IF
		END IF
	END IF
END IF

END FUNCTION



FUNCTION muestra_contadores_fp(num_ant, max_ant, num_caj, max_caj, num_cre,
				max_cre)
DEFINE num_ant, max_ant	SMALLINT
DEFINE num_caj, max_caj	SMALLINT
DEFINE num_cre, max_cre	SMALLINT

DISPLAY BY NAME num_ant, max_ant, num_caj, max_caj, num_cre, max_cre

END FUNCTION	



FUNCTION muestra_descripciones(item, linea, sub_linea, cod_grupo, cod_clase,
				flag)
DEFINE item		LIKE rept010.r10_codigo
DEFINE linea		LIKE rept010.r10_linea
DEFINE sub_linea	LIKE rept010.r10_sub_linea
DEFINE cod_grupo	LIKE rept010.r10_cod_grupo
DEFINE cod_clase	LIKE rept010.r10_cod_clase
DEFINE flag		CHAR(1)
DEFINE r_r03		RECORD LIKE rept003.*
DEFINE r_r70		RECORD LIKE rept070.*
DEFINE r_r71		RECORD LIKE rept071.*
DEFINE r_r72		RECORD LIKE rept072.*

IF flag = 'I' THEN
	CALL fl_lee_linea_rep(vg_codcia, linea) RETURNING r_r03.*
	CALL fl_lee_sublinea_rep(vg_codcia, linea, sub_linea)
		RETURNING r_r70.*
	CALL fl_lee_grupo_rep(vg_codcia, linea, sub_linea, cod_grupo)
		RETURNING r_r71.*
	DISPLAY r_r03.r03_nombre     TO descrip_1
	DISPLAY r_r70.r70_desc_sub   TO descrip_2
	DISPLAY r_r71.r71_desc_grupo TO descrip_3
END IF
CALL fl_lee_clase_rep(vg_codcia, linea, sub_linea, cod_grupo, cod_clase)
	RETURNING r_r72.*
DISPLAY r_r72.r72_desc_clase TO descrip_4

END FUNCTION



FUNCTION muestra_contadores_det(num_row, max_row)
DEFINE num_row, max_row	SMALLINT

DISPLAY BY NAME num_row, max_row

END FUNCTION



FUNCTION muestra_etiquetas(item, i, numlin, flag)
DEFINE item		LIKE rept010.r10_codigo
DEFINE i, numlin	SMALLINT
DEFINE flag		CHAR(1)
DEFINE r_item		RECORD LIKE rept010.*

CALL muestra_contadores_det(i, numlin)
CALL fl_lee_item(vg_codcia, item) RETURNING r_item.*
CALL muestra_descripciones(item, r_item.r10_linea, r_item.r10_sub_linea,
			r_item.r10_cod_grupo, r_item.r10_cod_clase, flag)
DISPLAY r_item.r10_nombre TO nom_item 

END FUNCTION



FUNCTION ver_documento(r_ant)
DEFINE r_ant		RECORD
				r27_tipo	LIKE rept027.r27_tipo,
				r27_numero	LIKE rept027.r27_numero,
				r27_valor	LIKE rept027.r27_valor
			END RECORD
DEFINE comando		CHAR(400)
DEFINE run_prog		CHAR(10)

{-- ESTO PARA LLAMAR AL PROGRAMA SEGÚN SEA EL AMBIENTE --}
LET run_prog = '; fglrun '
IF vg_gui = 0 THEN
	LET run_prog = '; fglgo '
END IF
{--- ---}
LET comando = 'cd ..', vg_separador, '..', vg_separador, 'COBRANZAS',
		vg_separador, 'fuentes', vg_separador, run_prog, 'cxcp201 ',
		vg_base, ' "CO" ', vg_codcia, ' ', vg_codloc, ' ',
		r_ctrn.r19_codcli, ' "', r_ant.r27_tipo, '" ', r_ant.r27_numero
RUN comando

END FUNCTION



FUNCTION ver_devolucion_anulacion_fact(tipo_dev, num_dev)
DEFINE tipo_dev		LIKE rept019.r19_tipo_dev
DEFINE num_dev		LIKE rept019.r19_num_dev
DEFINE comando		CHAR(400)
DEFINE run_prog		CHAR(10)

{-- ESTO PARA LLAMAR AL PROGRAMA SEGÚN SEA EL AMBIENTE --}
LET run_prog = '; fglrun '
IF vg_gui = 0 THEN
	LET run_prog = '; fglgo '
END IF
{--- ---}
LET comando = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS',
		vg_separador, 'fuentes', vg_separador, run_prog, 'repp217 ',
		vg_base, ' "', vg_modulo, '" ', vg_codcia, ' ', vg_codloc,
		' "', tipo_dev, '" ', num_dev, ' "X" "F"'
RUN comando

END FUNCTION



FUNCTION ver_transferencia(cod_tran, num_tran)
DEFINE cod_tran		LIKE rept019.r19_cod_tran
DEFINE num_tran		LIKE rept019.r19_num_tran
DEFINE comando		CHAR(400)
DEFINE run_prog		CHAR(10)

{-- ESTO PARA LLAMAR AL PROGRAMA SEGÚN SEA EL AMBIENTE --}
LET run_prog = '; fglrun '
IF vg_gui = 0 THEN
	LET run_prog = '; fglgo '
END IF
{--- ---}
LET comando = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS',
		vg_separador, 'fuentes', vg_separador, run_prog, 'repp216 ',
		vg_base, ' "', vg_modulo, '" ', vg_codcia, ' ', vg_codloc,
		' "', cod_tran, '" ', num_tran, ' "F"'
RUN comando

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
DISPLAY '<F5>      Forma de Pago'            AT a,2
DISPLAY  'F5' AT a,3 ATTRIBUTE(REVERSE)
LET a = a + 1
DISPLAY '<F6>      Ver Item'                 AT a,2
DISPLAY  'F6' AT a,3 ATTRIBUTE(REVERSE)
LET a = a + 1
DISPLAY '<F7>      Orden de Despacho'        AT a,2
DISPLAY  'F7' AT a,3 ATTRIBUTE(REVERSE)
LET a = a + 1
DISPLAY '<F8>      Pre-Venta'                AT a,2
DISPLAY  'F8' AT a,3 ATTRIBUTE(REVERSE)
LET a = a + 1
DISPLAY '<F9>      Devolución/Anulación'     AT a,2
DISPLAY  'F9' AT a,3 ATTRIBUTE(REVERSE)
LET a = a + 1
DISPLAY '<F10>     Transferencia'            AT a,2
DISPLAY  'F10' AT a,3 ATTRIBUTE(REVERSE)
LET a = fgl_getkey()
CLOSE WINDOW w_tf

END FUNCTION



FUNCTION control_visor_teclas_caracter_2() 
DEFINE a, fila		INTEGER

CALL fl_visor_teclas_caracter() RETURNING fila
LET a = fila + 2
DISPLAY 'Teclas exclusivas de este proceso:' AT a,2 ATTRIBUTE(REVERSE)	
LET a = a + 1
DISPLAY '<F5>      Liquidación'              AT a,2
DISPLAY  'F5' AT a,3 ATTRIBUTE(REVERSE)
LET a = fgl_getkey()
CLOSE WINDOW w_tf

END FUNCTION



FUNCTION control_visor_teclas_caracter_3() 
DEFINE a, fila		INTEGER

CALL fl_visor_teclas_caracter() RETURNING fila
LET a = fila + 2
DISPLAY 'Teclas exclusivas de este proceso:' AT a,2 ATTRIBUTE(REVERSE)	
LET a = a + 1
DISPLAY '<F5>      Ver Documento'            AT a,2
DISPLAY  'F5' AT a,3 ATTRIBUTE(REVERSE)
LET a = fgl_getkey()
CLOSE WINDOW w_tf

END FUNCTION
