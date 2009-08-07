------------------------------------------------------------------------------
-- Titulo           : repp308.4gl - Consulta Kardex de Documentos
-- Elaboracion      : 03-Sep-2001
-- Autor            : YEC
-- Formato Ejecucion: fglrun repp308.4gl base_datos modulo compañía localidad
-- Ultima Correccion: 08-Jul-2002
-- Motivo Correccion: Para llegar hasta la liquidacion de la importacion
--		      se le agregò un ON KEY (F5) en la funcion
--		      muestra_importacion(cod_tran, num_tran) (RCA)
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_demonios	VARCHAR(12)
DEFINE r_ctrn		RECORD LIKE rept019.*
DEFINE r_dtrn		RECORD LIKE rept020.*
DEFINE r_item		RECORD LIKE rept010.*

MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/repp308.error')
CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 AND num_args() <> 6 THEN
	CALL fgl_winmessage(vg_producto, 'Número de parámetros incorrecto', 'stop')
	EXIT PROGRAM
END IF
LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_codcia   = arg_val(3)
LET vg_codloc   = arg_val(4)
LET vg_proceso = 'repp308'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()

END MAIN



FUNCTION funcion_master()
DEFINE cod_tran		LIKE rept019.r19_cod_tran
DEFINE num_tran		LIKE rept019.r19_num_tran

DECLARE q_det CURSOR FOR SELECT * FROM rept020
	WHERE r20_compania = vg_codcia AND r20_localidad = vg_codloc AND
	      r20_cod_tran = cod_tran  AND r20_num_tran  = num_tran
	ORDER BY r20_orden
IF num_args() = 6 THEN
	LET cod_tran = arg_val(5)
	LET num_tran = arg_val(6)
	CASE cod_tran
		WHEN 'FA'
			CALL muestra_factura(cod_tran, num_tran)
		WHEN 'IM'
			CALL muestra_importacion(cod_tran, num_tran)
	END CASE
END IF

END FUNCTION



FUNCTION muestra_factura(cod_tran, num_tran)
DEFINE cod_tran		LIKE rept019.r19_cod_tran
DEFINE num_tran		LIKE rept019.r19_num_tran
DEFINE r_bod		RECORD LIKE rept002.*
DEFINE r_ven		RECORD LIKE rept001.*
DEFINE r_item		RECORD LIKE rept010.*
DEFINE r_dev		RECORD LIKE rept019.*
DEFINE num_rows, i	SMALLINT
DEFINE num_lin		SMALLINT
DEFINE t_subtotal	DECIMAL(14,2)
DEFINE t_descuento	DECIMAL(12,2)
DEFINE t_impuesto	DECIMAL(12,2)
DEFINE t_neto		DECIMAL(14,2)
DEFINE comando		CHAR(150)
DEFINE r_trn 	ARRAY[400] OF RECORD
		r20_cant_ven	LIKE rept020.r20_cant_ven,
		r20_item	LIKE rept020.r20_item,
		tit_item	VARCHAR(40),
		r20_descuento	LIKE rept020.r20_descuento,
		r20_precio	LIKE rept020.r20_precio,
		subtotal	DECIMAL(14,2)
	END RECORD

LET num_rows = 400
OPEN WINDOW w_fact AT 3,2 WITH 22 ROWS, 80 COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE FIRST,
		  BORDER, MESSAGE LINE LAST) 
OPEN FORM f_fact FROM '../forms/repf308_1'
DISPLAY FORM f_fact
CALL fl_lee_cabecera_transaccion_rep(vg_codcia, vg_codloc, cod_tran, num_tran)
	RETURNING r_ctrn.*
IF r_ctrn.r19_compania IS NULL THEN
	CALL fgl_winmessage(vg_producto, 'Transacción no existe', 'exclamation')
	RETURN
END IF
CALL fl_lee_bodega_rep(vg_codcia, r_ctrn.r19_bodega_ori) RETURNING r_bod.*
CALL fl_lee_vendedor_rep(vg_codcia, r_ctrn.r19_vendedor) RETURNING r_ven.*
DISPLAY r_bod.r02_nombre  TO tit_bod
DISPLAY r_ven.r01_nombres TO tit_vend
DISPLAY BY NAME r_ctrn.r19_num_tran, r_ctrn.r19_fecing,   r_ctrn.r19_bodega_ori,
		r_ctrn.r19_codcli,   r_ctrn.r19_nomcli,   r_ctrn.r19_dircli,
		r_ctrn.r19_tipo_dev, r_ctrn.r19_num_dev,
		r_ctrn.r19_telcli,   r_ctrn.r19_vendedor, r_ctrn.r19_porc_impto	
IF r_ctrn.r19_tipo_dev IS NOT NULL THEN
	CALL fl_lee_cabecera_transaccion_rep(vg_codcia, vg_codloc, 
		r_ctrn.r19_tipo_dev, r_ctrn.r19_num_dev)
		RETURNING r_dev.*
	DISPLAY r_dev.r19_fecing TO fec_dev
END IF
LET i = 0
FOREACH q_det INTO r_dtrn.*
	LET i = i + 1
	CALL fl_lee_item(vg_codcia, r_dtrn.r20_item) RETURNING r_item.*
	LET r_trn[i].r20_cant_ven  = r_dtrn.r20_cant_ven
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
DISPLAY BY NAME t_subtotal, t_descuento, t_impuesto, t_neto, r_ctrn.r19_flete
DISPLAY 'Can.'         TO tit_col1
DISPLAY 'Item'         TO tit_col2
DISPLAY 'Descripción'  TO tit_col3
DISPLAY '  % '         TO tit_col4
DISPLAY 'Precio Unit.' TO tit_col5
DISPLAY 'Subtotal'     TO tit_col6
CALL set_count(num_lin)
DISPLAY ARRAY r_trn TO r_trn.*
	BEFORE DISPLAY 
		CALL dialog.keysetlabel("ACCEPT","")
	AFTER DISPLAY 
		CONTINUE DISPLAY
	ON KEY(INTERRUPT)
		EXIT DISPLAY
	BEFORE ROW
		LET i = arr_curr()
		MESSAGE i, ' de ', num_lin
	ON KEY(F5)
		CALL control_mostrar_forma_pago(vg_codcia, vg_codloc, r_ctrn.r19_cod_tran, r_ctrn.r19_num_tran) 
	ON KEY(F6)
		LET comando = 'fglrun repp108 ', vg_base, ' RE ', 
			      vg_codcia, ' "',
			      r_trn[i].r20_item CLIPPED || '"'
		RUN comando
END DISPLAY

END FUNCTION



FUNCTION muestra_importacion(cod_tran, num_tran)
DEFINE cod_tran		LIKE rept019.r19_cod_tran
DEFINE num_tran		LIKE rept019.r19_num_tran
DEFINE r_item		RECORD LIKE rept010.*
DEFINE num_rows, i	SMALLINT
DEFINE num_lin		SMALLINT
DEFINE t_costo		DECIMAL(14,2)
DEFINE t_fob		DECIMAL(14,2)
DEFINE comando		CHAR(150)
DEFINE r_trn 	ARRAY[700] OF RECORD
		r20_item	LIKE rept020.r20_item,
		r10_nombre	LIKE rept010.r10_nombre,
		r20_cant_ven	LIKE rept020.r20_cant_ven,
		r20_fob		LIKE rept020.r20_fob,
		r20_costo	LIKE rept020.r20_costo,
		subtotal	DECIMAL(14,2)
	END RECORD

DEFINE r_p01		RECORD LIKE cxpt001.*
DEFINE r_r28		RECORD LIKE rept028.*

LET num_rows = 700
OPEN WINDOW w_imp AT 3,2 WITH 22 ROWS, 80 COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE FIRST,
		  BORDER, MESSAGE LINE LAST) 
OPEN FORM f_imp FROM '../forms/repf308_3'
DISPLAY FORM f_imp
CALL fl_lee_cabecera_transaccion_rep(vg_codcia, vg_codloc, cod_tran, num_tran)
	RETURNING r_ctrn.*
IF r_ctrn.r19_compania IS NULL THEN
	CALL fgl_winmessage(vg_producto, 'Transacción no existe', 'exclamation')
	RETURN
END IF

-- OjO 
-- 	Debe mostrarse el nombre del proveedor, no el del cliente
CALL fl_lee_liquidacion_rep(vg_codcia, vg_codloc, r_ctrn.r19_numliq)
	RETURNING r_r28.*
IF r_r28.r28_numliq IS NULL THEN
	CALL fgl_winmessage(vg_producto, 'Liquidación no existe', 'exclamation')
	RETURN
END IF
CALL fl_lee_proveedor(r_r28.r28_codprov) RETURNING r_p01.*
IF r_p01.p01_codprov IS NULL THEN
	CALL fgl_winmessage(vg_producto, 'Proveedor no existe', 'exclamation')
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
DISPLAY 'Item'        TO tit_col1
DISPLAY 'Descripción' TO tit_col2
DISPLAY 'Can.'        TO tit_col3
DISPLAY 'Fob Unit.'   TO tit_col4
DISPLAY 'Costo Unit'  TO tit_col5
DISPLAY 'Costo Tot.'  TO tit_col6
CALL set_count(num_lin)
DISPLAY ARRAY r_trn TO r_trn.*
	BEFORE DISPLAY 
		CALL dialog.keysetlabel("ACCEPT","")
	AFTER DISPLAY 
		CONTINUE DISPLAY
	ON KEY(INTERRUPT)
		EXIT DISPLAY
	ON KEY(F5)
--OJO Para llegar hasta la liquidacion de la importacion
		LET comando = 'cd ..', vg_separador, '..',
			   vg_separador, 
	    		  'REPUESTOS', vg_separador, 'fuentes', 
			   vg_separador, '; fglrun repp207 ', vg_base,
			  ' ', vg_modulo, ' ', vg_codcia, ' ',vg_codloc,				  ' ', r_ctrn.r19_numliq
		RUN comando
		LET int_flag = 0
	BEFORE ROW
		LET i = arr_curr()
		MESSAGE i, ' de ', num_lin
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
DEFINE i		SMALLINT
DEFINE num_ant		SMALLINT
DEFINE num_caj		SMALLINT
DEFINE num_cred		SMALLINT
DEFINE val_caja		DECIMAL(12,2)
DEFINE r_ant  ARRAY[100] OF RECORD
		r27_tipo	LIKE rept027.r27_tipo,
		r27_numero	LIKE rept027.r27_numero,
		r27_valor	LIKE rept027.r27_valor
	END RECORD
DEFINE r_caj  ARRAY[100] OF RECORD
		j11_codigo_pago	LIKE cajt011.j11_codigo_pago,
		nombre_bt	VARCHAR(20),
		j11_num_ch_aut	LIKE cajt011.j11_num_ch_aut,
		j11_moneda	LIKE cajt011.j11_moneda,
		j11_valor	LIKE cajt011.j11_valor
	END RECORD
DEFINE r_cred  ARRAY[100] OF RECORD
		r26_dividendo	LIKE rept026.r26_dividendo,
		r26_fec_vcto	LIKE rept026.r26_fec_vcto,
		r26_valor_cap	LIKE rept026.r26_valor_cap,
		r26_valor_int	LIKE rept026.r26_valor_int,
		tot_div		DECIMAL(12,2)
	END RECORD

CALL fl_lee_cabecera_transaccion_rep(codcia, codloc, cod_tran, num_tran)
	RETURNING r_ctrn.*
IF r_ctrn.r19_compania IS NULL THEN
	CALL fgl_winmessage(vg_producto, 'Transacción no existe', 'exclamation')
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
CALL fl_lee_grupo_linea(codcia, r_lin.r03_grupo_linea)
	RETURNING r_glin.*
OPEN WINDOW w_fp AT 2,5 WITH FORM "../forms/repf308_2"
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, BORDER, MESSAGE LINE LAST,
		  MENU LINE 0)
DISPLAY BY NAME cod_tran, num_tran
DISPLAY 'TP.'    TO tit_ant1
DISPLAY 'Número' TO tit_ant2
DISPLAY 'Valor'  TO tit_ant3
DISPLAY 'TP.'                 TO tit_caj1
DISPLAY 'Banco/Tarjeta'       TO tit_caj2 
DISPLAY 'No. Cheque/Tarjeta'  TO tit_caj3
DISPLAY 'Mo.'                 TO tit_caj4 
DISPLAY 'V a l o r'           TO tit_caj5
DISPLAY 'No.'                 TO tit_cred1
DISPLAY 'Fec.Vcto.'           TO tit_cred2
DISPLAY 'Valor Capital'       TO tit_cred3
DISPLAY 'Valor Interés'       TO tit_cred4
DISPLAY 'Valor Total'         TO tit_cred5
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
	LET r_caj[num_caj].j11_valor	     = r_dp.j11_valor
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
END WHILE
CLOSE q_caj
FREE q_caj
FOR i = 1 TO fgl_scr_size('r_ant')
	IF i <= num_ant THEN
		DISPLAY r_ant[i].* TO r_ant[i].*
	END IF
END FOR	
FOR i = 1 TO fgl_scr_size('r_caj')
	IF i <= num_caj THEN
		DISPLAY r_caj[i].* TO r_caj[i].*
	END IF
END FOR	
FOR i = 1 TO fgl_scr_size('r_cred')
	IF i <= num_cred THEN
		DISPLAY r_cred[i].* TO r_cred[i].*
	END IF
END FOR	
MENU ''
	BEFORE MENU
		IF num_ant <= fgl_scr_size('r_ant') THEN
			HIDE OPTION 'Anticipos'
		END IF
		IF num_cred <= fgl_scr_size('r_cred') THEN
			HIDE OPTION 'Crédito'
		END IF
		IF num_caj <= fgl_scr_size('r_caj') THEN
			HIDE OPTION 'Caja'
		END IF
	COMMAND 'Anticipos'
		IF num_ant > fgl_scr_size('r_ant') THEN
			CALL set_count(num_ant)
			DISPLAY ARRAY r_ant TO r_ant.*
				BEFORE DISPLAY
					CALL dialog.keysetlabel("ACCEPT","")
				AFTER DISPLAY
					CONTINUE DISPLAY
				ON KEY(INTERRUPT)
					EXIT DISPLAY
			END DISPLAY
		END IF
	COMMAND 'Crédito'
		IF num_cred > fgl_scr_size('r_cred') THEN
			CALL set_count(num_cred)
			DISPLAY ARRAY r_cred TO r_cred.*
				BEFORE DISPLAY
					CALL dialog.keysetlabel("ACCEPT","")
				AFTER DISPLAY
					CONTINUE DISPLAY
				ON KEY(INTERRUPT)
					EXIT DISPLAY
			END DISPLAY
		END IF
	COMMAND 'Caja'
		IF num_caj > fgl_scr_size('r_caj') THEN
			CALL set_count(num_caj)
			DISPLAY ARRAY r_caj TO r_caj.*
				BEFORE DISPLAY
					CALL dialog.keysetlabel("ACCEPT","")
				AFTER DISPLAY
					CONTINUE DISPLAY
				ON KEY(INTERRUPT)
					EXIT DISPLAY
			END DISPLAY
		END IF
	COMMAND 'Salir'
		EXIT MENU
END MENU
CLOSE WINDOW w_fp

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
