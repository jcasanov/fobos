--------------------------------------------------------------------------------
-- Titulo           : talp308.4gl - Consulta Comprobantes Facturas Taller
-- Elaboracion      : 22-Ago-2006
-- Autor            : NPC
-- Formato Ejecucion: fglrun talp308 base modulo compañía localidad
-- Ultima Correccion:
-- Motivo Correccion:
--------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE rm_cia		RECORD LIKE gent001.*
DEFINE rm_g05		RECORD LIKE gent005.*
DEFINE rm_r01		RECORD LIKE rept001.*
DEFINE rm_t23		RECORD LIKE talt023.*
DEFINE vm_size_arr_ant	INTEGER
DEFINE vm_size_arr_caj	INTEGER
DEFINE vm_size_arr_cre	INTEGER



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/talp308.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 5 AND num_args() <> 6 THEN
	CALL fl_mostrar_mensaje('Número de parametros incorrecto.','stop')
	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_codloc  = arg_val(4)
LET vg_proceso = 'talp308'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
--#CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()

END MAIN



FUNCTION funcion_master()
DEFINE r_t61		RECORD LIKE talt061.*
DEFINE num_fac		LIKE talt023.t23_num_factura

CALL fl_lee_compania(vg_codcia) RETURNING rm_cia.*
IF rm_cia.g01_compania IS NULL THEN
	CALL fl_mostrar_mensaje('No existe compañía.','stop')
	EXIT PROGRAM
END IF
IF vg_gui = 0 THEN
	CALL fl_mostrar_mensaje('Este programa no esta hecho para ambiente de texto. LLAME AL ADMINISTRADOR.', 'info')
	EXIT PROGRAM
END IF
LET num_fac = arg_val(5)
CALL fl_lee_factura_taller(vg_codcia, vg_codloc, num_fac) RETURNING rm_t23.*
IF rm_t23.t23_compania IS NULL THEN
	CALL fl_mostrar_mensaje('Factura no existe.','stop')
	EXIT PROGRAM
END IF
INITIALIZE rm_r01.*, r_t61.* TO NULL
DECLARE q_t61 CURSOR FOR
	SELECT * FROM talt061
		WHERE t61_compania   = vg_codcia
		  AND t61_cod_asesor = rm_t23.t23_cod_asesor
OPEN q_t61 
FETCH q_t61 INTO r_t61.*
CLOSE q_t61 
FREE q_t61 
CALL fl_lee_usuario(rm_t23.t23_usuario) RETURNING rm_g05.*
DECLARE qu_vd CURSOR FOR
	SELECT * FROM rept001
		WHERE r01_compania   = vg_codcia
		  --AND r01_user_owner = rm_g05.g05_usuario
		  AND r01_codigo     = r_t61.t61_cod_vendedor
OPEN qu_vd 
FETCH qu_vd INTO rm_r01.*
CLOSE qu_vd 
FREE qu_vd 
CALL muestra_factura(num_fac)

END FUNCTION



FUNCTION validar_codigo_vendedor_trn()
DEFINE r_j02		RECORD LIKE cajt002.*
DEFINE r_r01		RECORD LIKE rept001.*
DEFINE tiene_caja	SMALLINT

IF rm_g05.g05_tipo = 'UF' THEN
	IF rm_r01.r01_compania IS NULL THEN
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
	LET tiene_caja = 0
	CALL fl_retorna_caja(vg_codcia, vg_codloc, rm_r01.r01_user_owner)
		RETURNING r_j02.*
	IF r_j02.j02_compania IS NOT NULL THEN
		LET tiene_caja = 1
	END IF
	IF rm_r01.r01_tipo <> 'G' AND NOT tiene_caja THEN
		IF rm_r01.r01_codigo <> rm_r01.r01_codigo THEN
			IF rm_r01.r01_tipo <> 'J' THEN
				CALL fl_mostrar_mensaje('Usted no puede ver este comprobante que no tiene su codigo de vendedor.', 'stop')
				EXIT PROGRAM
			END IF
			CALL fl_lee_vendedor_rep(vg_codcia, rm_r01.r01_codigo)
				RETURNING r_r01.*
			IF r_r01.r01_tipo = 'G' OR r_r01.r01_tipo = 'J' AND
			   NOT tiene_caja
			THEN
				CALL fl_mostrar_mensaje('Usted no puede ver este comprobante que tiene codigo de jefe o gerente que no es el suyo.', 'stop')
				EXIT PROGRAM
			END IF
		END IF
	END IF
END IF

END FUNCTION



FUNCTION muestra_factura(num_fac)
DEFINE num_fac		LIKE talt023.t23_num_factura
DEFINE num_dev		LIKE talt028.t28_num_dev
DEFINE r_z01		RECORD LIKE cxct001.*
DEFINE r_ven		RECORD LIKE rept001.*
DEFINE r_t23		RECORD LIKE talt023.*
DEFINE r_t24		RECORD LIKE talt024.*
DEFINE num_rows, i, j	SMALLINT
DEFINE num_lin		SMALLINT
DEFINE t_subtotal	DECIMAL(14,2)
DEFINE t_descuento	DECIMAL(12,2)
DEFINE t_impuesto	DECIMAL(12,2)
DEFINE t_neto		DECIMAL(14,2)
DEFINE r_trn		ARRAY[400] OF RECORD
				descripcion	VARCHAR(150),
				subtotal	DECIMAL(14,2)
			END RECORD
DEFINE lin_menu		SMALLINT
DEFINE row_ini  	SMALLINT
DEFINE num_rows2 	SMALLINT
DEFINE num_cols 	SMALLINT
DEFINE run_prog		CHAR(10)

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
	OPEN FORM f_fact FROM '../forms/talf308_1'
ELSE
	OPEN FORM f_fact FROM '../forms/talf308_1c'
END IF
DISPLAY FORM f_fact
CALL validar_codigo_vendedor_trn()
CALL fl_lee_vendedor_rep(vg_codcia, rm_r01.r01_codigo) RETURNING r_ven.*
SELECT * INTO r_t23.* FROM talt023
	WHERE t23_compania    = vg_codcia
	  AND t23_localidad   = vg_codloc
	  AND t23_num_factura = num_fac
CALL fl_lee_cliente_general(rm_t23.t23_cod_cliente) RETURNING r_z01.*
DISPLAY BY NAME rm_t23.t23_num_factura, rm_t23.t23_orden,rm_t23.t23_fec_factura,
		rm_t23.t23_cod_cliente, rm_t23.t23_nom_cliente,
		r_z01.z01_direccion1, rm_t23.t23_tel_cliente, rm_r01.r01_codigo,
		r_ven.r01_nombres, rm_t23.t23_porc_impto
LET r_trn[1].descripcion = "TOTAL OTROS REPUESTOS Y MATERIALES"
LET r_trn[1].subtotal	 = rm_t23.t23_val_mo_ext + rm_t23.t23_val_mo_cti +
				rm_t23.t23_val_rp_tal + rm_t23.t23_val_rp_ext +
				rm_t23.t23_val_rp_cti + rm_t23.t23_val_otros2
LET r_trn[2].descripcion = NULL
LET r_trn[2].subtotal	 = NULL
LET r_trn[3].descripcion = "TOTAL DE MANO DE OBRA"
LET r_trn[3].subtotal	 = rm_t23.t23_val_mo_tal
SELECT COUNT(*) INTO num_lin FROM talt024
	WHERE t24_compania  = vg_codcia
	  AND t24_localidad = vg_codloc
	  AND t24_orden     = rm_t23.t23_orden
DECLARE q_talt024 CURSOR FOR
	SELECT * FROM talt024
		WHERE t24_compania  = vg_codcia
		  AND t24_localidad = vg_codloc
		  AND t24_orden     = rm_t23.t23_orden
		ORDER BY t24_secuencia
LET r_trn[4].descripcion = NULL
LET r_trn[4].subtotal	 = NULL
LET i = 5
FOREACH q_talt024 INTO r_t24.*
	LET r_trn[i].descripcion = '  ', r_t24.t24_descripcion
	LET r_trn[i].subtotal	 = NULL
	LET i = i + 1
	IF i > num_rows THEN
		EXIT FOREACH
	END IF
END FOREACH
LET i = i - 1
LET j = 0
IF i > 5 OR r_trn[i].descripcion IS NOT NULL THEN
	LET r_trn[i + 1].descripcion = NULL
	LET r_trn[i + 1].subtotal    = NULL
	LET j = 1
END IF
LET r_trn[i + j + 1].descripcion = "TOTAL MATERIAL Y REPUESTOS ",
					rm_cia.g01_razonsocial CLIPPED
LET r_trn[i + j + 1].subtotal    = NULL
LET r_trn[i + j + 2].descripcion = "  (VER FACTURAS ADJUNTAS)"
LET r_trn[i + j + 2].subtotal    = NULL
LET num_lin     = i + j + 2
LET t_descuento = rm_t23.t23_tot_dscto
LET t_subtotal  = rm_t23.t23_tot_bruto - rm_t23.t23_tot_dscto
LET t_neto      = rm_t23.t23_tot_neto
#LET t_impuesto  = t_neto - (t_subtotal - t_descuento)
LET t_impuesto  = rm_t23.t23_val_impto
DISPLAY BY NAME rm_t23.t23_tot_bruto, t_descuento, t_subtotal, t_impuesto,t_neto
--#DISPLAY 'D e s c r i p c i ó n' TO tit_col1
--#DISPLAY 'Subtotal'              TO tit_col2
LET run_prog = 'fglrun '
IF vg_gui = 0 THEN
	LET run_prog  = 'fglgo '
END IF
CALL muestra_contadores_det(1, num_lin)
CALL muestra_devanul() RETURNING num_dev 
CALL set_count(num_lin)
DISPLAY ARRAY r_trn TO r_trn.*
	ON KEY(INTERRUPT)
		EXIT DISPLAY
	ON KEY(F5)
		CALL control_mostrar_forma_pago(rm_t23.*)
		LET int_flag = 0
	ON KEY(F6)
		LET i = arr_curr()
		CALL fl_ver_orden_trabajo(rm_t23.t23_num_factura, 'F')
		LET int_flag = 0
	ON KEY(F7)
		CALL fl_muestra_mano_obra_orden_trabajo(vg_codcia, vg_codloc,
							rm_t23.t23_orden, 1)
		LET int_flag = 0
	ON KEY(F8)
		CALL fl_muestra_det_ord_compra_orden_trabajo(vg_codcia,
						vg_codloc, rm_t23.t23_orden,
						rm_t23.t23_estado)
		LET int_flag = 0
	ON KEY(F9)
		CALL fl_control_prof_trans(vg_codcia, vg_codloc,
						rm_t23.t23_orden)
		LET int_flag = 0
	ON KEY(F10)
		CALL fl_muestra_repuestos_orden_trabajo(vg_codcia, vg_codloc,
                                                          rm_t23.t23_orden, 'F')
		LET int_flag = 0
	ON KEY(F11)
		IF num_dev IS NOT NULL AND num_args() <> 6 THEN
			CALL ver_devolucion_anulacion_fact(num_dev)
		END IF
	ON KEY(CONTROL-V)
		CALL control_imprimir(rm_t23.t23_num_factura)
		LET int_flag = 0
	--#BEFORE ROW
		--#LET i = arr_curr()
		--#CALL muestra_contadores_det(i, num_lin)
		--#CALL muestra_devanul() RETURNING num_dev 
		--#IF num_dev IS NULL OR num_args() = 6 THEN
			--#CALL dialog.keysetlabel("F11","")
		--#ELSE
			--#CALL dialog.keysetlabel("F11","Anu/Dev OT")
		--#END IF
		--#CALL dialog.keysetlabel("CONTROL-V","Imprimir")
	--#BEFORE DISPLAY 
		--#CALL dialog.keysetlabel("ACCEPT","")
		--#CALL dialog.keysetlabel('RETURN','')
	--#AFTER DISPLAY 
		--#CONTINUE DISPLAY
END DISPLAY

END FUNCTION



FUNCTION muestra_contadores_det(num_row, max_row)
DEFINE num_row, max_row	SMALLINT

DISPLAY BY NAME num_row, max_row

END FUNCTION


 
FUNCTION control_mostrar_forma_pago(r_ord)
DEFINE r_ord		RECORD LIKE talt023.*
DEFINE r_fp		RECORD LIKE talt025.*
DEFINE r_mod		RECORD LIKE talt004.*
DEFINE r_lin		RECORD LIKE talt001.*
DEFINE r_z20		RECORD LIKE cxct020.*
DEFINE r_glin		RECORD LIKE gent020.*
DEFINE r_j01		RECORD LIKE cajt001.*
DEFINE r_cp		RECORD LIKE cajt010.*
DEFINE r_dp		RECORD LIKE cajt011.*
DEFINE linea 		LIKE rept020.r20_linea
DEFINE i, l		SMALLINT
DEFINE num_ant		SMALLINT
DEFINE num_caj		SMALLINT
DEFINE num_cred		SMALLINT
DEFINE val_caja		DECIMAL(12,2)
DEFINE r_ant		ARRAY[100] OF RECORD
				t27_tipo	LIKE talt027.t27_tipo,
				t27_numero	LIKE talt027.t27_numero,
				t27_valor	LIKE talt027.t27_valor
			END RECORD
DEFINE r_caj		ARRAY[100] OF RECORD
				j11_codigo_pago	LIKE cajt011.j11_codigo_pago,
				nombre_bt	VARCHAR(20),
				j11_num_ch_aut	LIKE cajt011.j11_num_ch_aut,
				j11_moneda	LIKE cajt011.j11_moneda,
				j11_valor	LIKE cajt011.j11_valor
			END RECORD
DEFINE r_cred		ARRAY[100] OF RECORD
				t26_dividendo	LIKE talt026.t26_dividendo,
				t26_fec_vcto	LIKE talt026.t26_fec_vcto,
				t26_valor_cap	LIKE talt026.t26_valor_cap,
				t26_valor_int	LIKE talt026.t26_valor_int,
				tot_div		DECIMAL(12,2)
			END RECORD
DEFINE lin_menu		SMALLINT
DEFINE row_ini  	SMALLINT
DEFINE num_rows 	SMALLINT
DEFINE num_cols 	SMALLINT

CALL fl_lee_tipo_vehiculo(r_ord.t23_compania, r_ord.t23_modelo)
	RETURNING r_mod.*
CALL fl_lee_linea_taller(r_ord.t23_compania, r_mod.t04_linea) RETURNING r_lin.*
CALL fl_lee_grupo_linea(r_ord.t23_compania, r_lin.t01_grupo_linea)
	RETURNING r_glin.*
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
	OPEN FORM f_tal_2 FROM "../forms/talf204_2"
ELSE
	OPEN FORM f_tal_2 FROM "../forms/talf204_2c"
END IF
DISPLAY FORM f_tal_2
DISPLAY BY NAME r_ord.t23_num_factura
--#DISPLAY 'TP.'		TO tit_ant1
--#DISPLAY 'Número'		TO tit_ant2
--#DISPLAY 'Valor'  		TO tit_ant3
--#DISPLAY 'TP.'                TO tit_caj1
--#DISPLAY 'Banco/Tarjeta'      TO tit_caj2 
--#DISPLAY 'No. Cheque/Tarjeta' TO tit_caj3
--#DISPLAY 'Mo.'                TO tit_caj4 
--#DISPLAY 'V a l o r'          TO tit_caj5
--#DISPLAY 'No.'                TO tit_cred1
--#DISPLAY 'Fec.Vcto.'          TO tit_cred2
--#DISPLAY 'Valor Capital'      TO tit_cred3
--#DISPLAY 'Valor Interés'      TO tit_cred4
--#DISPLAY 'Valor Total'        TO tit_cred5
INITIALIZE r_fp.* TO NULL
LET r_fp.t25_valor_ant  = 0
LET r_fp.t25_valor_cred = 0
LET num_ant             = 0
LET num_caj             = 0
LET num_cred            = 0
SELECT * INTO r_fp.* FROM talt025
	WHERE t25_compania  = r_ord.t23_compania AND 
	      t25_localidad = r_ord.t23_localidad AND 
	      t25_orden     = r_ord.t23_orden
LET val_caja = r_ord.t23_tot_neto - r_fp.t25_valor_ant - r_fp.t25_valor_cred
DISPLAY BY NAME r_fp.t25_valor_ant, r_fp.t25_valor_cred, r_ord.t23_tot_neto,
		val_caja
IF r_fp.t25_orden IS NOT NULL THEN
	DECLARE q_dpa CURSOR FOR 
		SELECT t27_tipo, t27_numero, t27_valor
			FROM talt027
			WHERE t27_compania  = r_ord.t23_compania AND 
		              t27_localidad = r_ord.t23_localidad AND
		              t27_orden     = r_fp.t25_orden  
	LET num_ant = 1
	FOREACH q_dpa INTO r_ant[num_ant].*
		LET num_ant = num_ant + 1
	END FOREACH
	FREE q_dpa
	LET num_ant = num_ant - 1
	DECLARE q_dcr CURSOR FOR
		SELECT t26_dividendo, t26_fec_vcto, t26_valor_cap,
		       t26_valor_int, t26_valor_cap + t26_valor_int
			FROM talt026
			WHERE t26_compania  = r_ord.t23_compania AND 
			      t26_localidad = r_ord.t23_localidad AND 
		              t26_orden     = r_fp.t25_orden  
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
		WHERE j10_compania     = r_ord.t23_compania AND 
              	      j10_localidad    = r_ord.t23_localidad AND
      	      	      j10_areaneg      = r_glin.g20_areaneg AND
      	      	      j10_tipo_destino = 'FA' AND 
              	      j10_num_destino  = r_ord.t23_num_factura AND
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
	LET r_caj[num_caj].j11_codigo_pago = r_dp.j11_codigo_pago
	LET r_caj[num_caj].j11_num_ch_aut  = r_dp.j11_num_ch_aut
	LET r_caj[num_caj].j11_moneda	   = r_dp.j11_moneda
	LET r_caj[num_caj].j11_valor       = r_dp.j11_valor
 	IF r_dp.j11_codigo_pago[1, 1] = 'T' THEN
		SELECT g10_nombre
			INTO r_caj[num_caj].nombre_bt 
			FROM gent010
			WHERE g10_tarjeta = r_dp.j11_cod_bco_tarj
	ELSE
		IF r_dp.j11_codigo_pago = 'CH' THEN
			SELECT g08_nombre
				INTO r_caj[num_caj].nombre_bt 
				FROM gent008
				WHERE g08_banco = r_dp.j11_cod_bco_tarj
		ELSE
			CALL fl_lee_tipo_pago_caja(vg_codcia,
							r_dp.j11_codigo_pago,
							r_ord.t23_cont_cred)
				RETURNING r_j01.*
			LET r_caj[num_caj].nombre_bt = r_j01.j01_nombre
		END IF
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
			ON KEY(RETURN)
				LET i = arr_curr()
				CALL muestra_contadores_fp(i, num_ant, 0,
							num_caj, 0, num_cred)
			ON KEY(F5)
				LET i = arr_curr()
				CALL ver_documento_fav(r_ant[i].*)
			--#BEFORE ROW
				--#LET i = arr_curr()
				--#CALL muestra_contadores_fp(i, num_ant, 0,
							--#num_caj, 0, num_cred)
			--#BEFORE DISPLAY
				--#CALL dialog.keysetlabel("ACCEPT","")
				--#CALL dialog.keysetlabel("F5","Documento")
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
			ON KEY(RETURN)
				LET i = arr_curr()
				CALL muestra_contadores_fp(0, num_ant, i,
							num_caj, 0, num_cred)
			ON KEY(F5)
				CALL ver_forma_pago()
			--#BEFORE ROW
				--#LET i = arr_curr()
				--#CALL muestra_contadores_fp(0, num_ant, i,
							--#num_caj, 0, num_cred)
			--#BEFORE DISPLAY
				--#CALL dialog.keysetlabel("ACCEPT","")
				--#CALL dialog.keysetlabel("F5","Forma Pago")
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
			ON KEY(RETURN)
				LET i = arr_curr()
				CALL muestra_contadores_fp(0, num_ant, 0,
							num_caj, i, num_cred)
			ON KEY(F5)
				LET i = arr_curr()
				INITIALIZE r_z20.* TO NULL
				SELECT * INTO r_z20.*
					FROM cxct020
					WHERE z20_compania =rm_t23.t23_compania
					  AND z20_localidad=rm_t23.t23_localidad
					  AND z20_codcli =rm_t23.t23_cod_cliente
					  AND z20_tipo_doc = 'FA'
					  AND z20_areaneg  = 2
					  AND z20_num_tran =
							rm_t23.t23_num_factura
					  AND z20_dividendo=
							r_cred[i].t26_dividendo
				CALL ver_documento_deu(r_z20.*)
			ON KEY(F6)
				LET i = arr_curr()
				INITIALIZE r_z20.* TO NULL
				SELECT * INTO r_z20.*
					FROM cxct020
					WHERE z20_compania = rm_t23.t23_compania
					  AND z20_localidad=rm_t23.t23_localidad
					  AND z20_codcli =rm_t23.t23_cod_cliente
					  AND z20_tipo_doc = 'FA'
					  AND z20_areaneg  = 2
					  AND z20_num_tran =
							rm_t23.t23_num_factura
					  AND z20_dividendo=
							r_cred[i].t26_dividendo
				CALL muestra_movimientos_documento_cxc(
					r_z20.z20_compania, r_z20.z20_localidad,
					r_z20.z20_codcli, r_z20.z20_tipo_doc,
					r_z20.z20_num_doc, r_z20.z20_dividendo,
					r_z20.z20_areaneg)
				LET int_flag = 0
			--#BEFORE ROW
				--#LET i = arr_curr()
				--#CALL muestra_contadores_fp(0, num_ant, 0,
							--#num_caj, i, num_cred)
			--#BEFORE DISPLAY
				--#CALL dialog.keysetlabel("ACCEPT","")
				--#CALL dialog.keysetlabel("F1","")
				--#CALL dialog.keysetlabel("F5","Documento")
				--#CALL dialog.keysetlabel("F6","Movimientos")
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



FUNCTION muestra_contadores_fp(num_ant, max_ant, num_caj, max_caj, num_cre,
				max_cre)
DEFINE num_ant, max_ant	SMALLINT
DEFINE num_caj, max_caj	SMALLINT
DEFINE num_cre, max_cre	SMALLINT

DISPLAY BY NAME num_ant, max_ant, num_caj, max_caj, num_cre, max_cre

END FUNCTION	



FUNCTION muestra_devanul()
DEFINE r_dev		RECORD LIKE talt028.*

INITIALIZE r_dev.* TO NULL
DECLARE q_dev CURSOR FOR
	SELECT * FROM talt028
		WHERE t28_compania  = vg_codcia
		  AND t28_localidad = vg_codloc
		  AND t28_factura   = rm_t23.t23_num_factura
OPEN q_dev
FETCH q_dev INTO r_dev.*
IF r_dev.t28_compania IS NULL THEN
	CLEAR t28_num_dev, t28_fec_anula
	RETURN r_dev.t28_num_dev
END IF
DISPLAY BY NAME r_dev.t28_num_dev, r_dev.t28_fec_anula
RETURN r_dev.t28_num_dev

END FUNCTION



FUNCTION ver_documento_fav(r_ant)
DEFINE r_ant		RECORD
				t27_tipo	LIKE talt027.t27_tipo,
				t27_numero	LIKE talt027.t27_numero,
				t27_valor	LIKE talt027.t27_valor
			END RECORD
DEFINE param		VARCHAR(100)

LET param = rm_t23.t23_cod_cliente, ' "', r_ant.t27_tipo, '" ', r_ant.t27_numero
CALL fl_ejecuta_comando('COBRANZAS', 'CO', 'cxcp201', param, 1)

END FUNCTION



FUNCTION ver_forma_pago()
DEFINE param		VARCHAR(100)

LET param = ' "OT" ', rm_t23.t23_orden
CALL fl_ejecuta_comando('CAJA', 'CG', 'cajp203', param, 1)

END FUNCTION



FUNCTION ver_documento_deu(r_z20)
DEFINE r_z20		RECORD LIKE cxct020.*
DEFINE param		VARCHAR(100)

LET param = r_z20.z20_codcli, ' "', r_z20.z20_tipo_doc, '" ', r_z20.z20_num_doc,
		' ', r_z20.z20_dividendo
CALL fl_ejecuta_comando('COBRANZAS', 'CO', 'cxcp200', param, 1)

END FUNCTION



FUNCTION ver_devolucion_anulacion_fact(num_dev)
DEFINE num_dev		LIKE talt028.t28_num_dev
DEFINE param		VARCHAR(100)

LET param = num_dev, ' "F" '
CALL fl_ejecuta_comando('TALLER', vg_modulo, 'talp211', param, 1)

END FUNCTION



FUNCTION muestra_movimientos_documento_cxc(codcia, codloc, codcli, tipo_doc,
						num_doc, dividendo, areaneg)
DEFINE codcia		LIKE gent001.g01_compania
DEFINE codloc		LIKE gent002.g02_localidad
DEFINE codcli		LIKE cxct001.z01_codcli
DEFINE tipo_doc		LIKE cxct020.z20_tipo_doc
DEFINE num_doc		LIKE cxct020.z20_num_doc
DEFINE dividendo	LIKE cxct020.z20_dividendo
DEFINE areaneg		LIKE cxct020.z20_areaneg
DEFINE r_cli		RECORD LIKE cxct001.*
DEFINE max_rows, i, col	SMALLINT
DEFINE r_orden 		ARRAY[10] OF CHAR(4)
DEFINE columna_1	SMALLINT
DEFINE columna_2	SMALLINT
DEFINE num_rows		SMALLINT
DEFINE tot_pago		DECIMAL(14,2)
DEFINE query		CHAR(1200)
DEFINE expr_sql		CHAR(400)
DEFINE r_aux		ARRAY[100] OF RECORD
				loc		LIKE gent002.g02_localidad,
				tipo		LIKE cxct023.z23_tipo_favor
			END RECORD
DEFINE r_pdoc		ARRAY[100] OF RECORD
				z23_tipo_trn	LIKE cxct023.z23_tipo_trn,
				z23_num_trn	LIKE cxct023.z23_num_trn,
				z22_fecha_emi	LIKE cxct022.z22_fecha_emi,
				z22_referencia	LIKE cxct022.z22_referencia,
				val_pago	DECIMAL(14,2)
			END RECORD
DEFINE num_rows2 	SMALLINT
DEFINE num_cols 	SMALLINT
DEFINE expr_loc		VARCHAR(50)
DEFINE expr_fec		VARCHAR(100)
DEFINE fecha1, fecha2	LIKE cxct022.z22_fecing

LET max_rows  = 100
LET num_rows2 = 16
LET num_cols  = 76
IF vg_gui = 0 THEN
	LET num_rows2 = 15
	LET num_cols  = 77
END IF
OPEN WINDOW w_mdoc AT 06, 03 WITH num_rows2 ROWS, num_cols COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MESSAGE LINE LAST, BORDER)
IF dividendo > 0 THEN
	OPEN FORM f_movdoc FROM "../../COBRANZAS/forms/cxcf314_5"
ELSE
	OPEN FORM f_movdoc FROM "../../COBRANZAS/forms/cxcf314_6"
END IF
DISPLAY FORM f_movdoc
--#DISPLAY 'TP'                  TO tit_col1 
--#DISPLAY 'Número'              TO tit_col2 
--#DISPLAY 'Fecha Pago'          TO tit_col3
--#DISPLAY 'R e f e r e n c i a' TO tit_col4 
--#DISPLAY 'V a l o r'           TO tit_col5
CALL fl_lee_cliente_general(codcli) RETURNING r_cli.*
IF r_cli.z01_codcli IS NULL THEN
	CALL fl_mostrar_mensaje('No existe cliente: ' || codcli, 'exclamation')
	CLOSE WINDOW w_mdoc
	RETURN
END IF
DISPLAY BY NAME r_cli.z01_codcli, r_cli.z01_nomcli
IF dividendo <> 0 THEN
	CLEAR z23_tipo_doc, z23_num_doc, z23_div_doc
	DISPLAY tipo_doc, num_doc, dividendo
	     TO z23_tipo_doc, z23_num_doc, z23_div_doc
ELSE
	CLEAR z23_tipo_favor, z23_doc_favor
	DISPLAY tipo_doc, num_doc TO z23_tipo_favor, z23_doc_favor
END IF
FOR i = 1 TO 10
	LET r_orden[i] = '' 
END FOR
LET r_orden[3] = 'DESC'
LET columna_1  = 3
LET columna_2  = 1
LET expr_loc   = ' '
IF codloc IS NOT NULL THEN
	LET expr_loc = '   AND z23_localidad = ', codloc
END IF
LET fecha2   = EXTEND(TODAY, YEAR TO SECOND) + 23 UNITS HOUR +
		59 UNITS MINUTE + 59 UNITS SECOND
LET expr_fec = '   AND z22_fecing    <= "', fecha2, '"'
LET expr_sql = '   AND z23_tipo_doc   = ? ',
		'   AND z23_num_doc    = ? ',
		'   AND z23_div_doc    = ? '
IF dividendo = 0 THEN
	LET expr_sql = '   AND z23_tipo_favor = ? ',
			'   AND z23_doc_favor  = ? '
END IF
WHILE TRUE
	LET query = 'SELECT z23_tipo_trn, z23_num_trn, z22_fecha_emi, ',
			'   z22_referencia, z23_valor_cap + z23_valor_int, ',
			'   z23_localidad, z23_tipo_favor ',
	        	' FROM cxct023, cxct022 ',
			' WHERE z23_compania   = ? ', 
			expr_loc CLIPPED,
		        '   AND z23_codcli     = ? ',
			expr_sql CLIPPED,
			'   AND z22_compania   = z23_compania ',
			'   AND z22_localidad  = z23_localidad ',
			'   AND z22_codcli     = z23_codcli ',
			'   AND z22_tipo_trn   = z23_tipo_trn  ',
			'   AND z22_num_trn    = z23_num_trn ',
			expr_fec CLIPPED,
			' ORDER BY ', columna_1, ' ', r_orden[columna_1],
				', ', columna_2, ' ', r_orden[columna_2]
	PREPARE dpgc FROM query
	DECLARE q_dpgc CURSOR FOR dpgc
	LET i        = 1
	LET tot_pago = 0
	IF dividendo <> 0 THEN
		OPEN q_dpgc USING codcia, codcli, tipo_doc, num_doc, dividendo
	ELSE
		OPEN q_dpgc USING codcia, codcli, tipo_doc, num_doc
	END IF
	WHILE TRUE
		FETCH q_dpgc INTO r_pdoc[i].*, r_aux[i].*
		IF STATUS = NOTFOUND THEN
			EXIT WHILE
		END IF
		LET tot_pago = tot_pago + r_pdoc[i].val_pago 
		LET i = i + 1
		IF i > max_rows THEN
			EXIT WHILE
		END IF
	END WHILE
	CLOSE q_dpgc
	FREE q_dpgc
	LET num_rows = i - 1
	IF num_rows = 0 THEN
		CALL fl_mostrar_mensaje('Documento no tiene movimientos.','exclamation')
		CLOSE WINDOW w_mdoc
		RETURN
	END IF
	LET int_flag = 0
	CALL set_count(num_rows)
	DISPLAY BY NAME tot_pago
	DISPLAY ARRAY r_pdoc TO r_pdoc.*
		ON KEY(INTERRUPT)
			EXIT DISPLAY
		ON KEY(F5)
			LET i = arr_curr()
			CALL fl_muestra_forma_pago_caja(codcia, r_aux[i].loc,
							areaneg, codcli,
							r_pdoc[i].z23_tipo_trn,
							r_pdoc[i].z23_num_trn) 
			LET int_flag = 0
		ON KEY(F6)
			LET i = arr_curr()
			CALL ver_documento_tran(codcli, r_pdoc[i].z23_tipo_trn,
					r_pdoc[i].z23_num_trn, r_aux[i].*)
			LET int_flag = 0
		ON KEY(F15)
			LET col      = 1
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F16)
			LET col      = 2
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F17)
			LET col      = 3
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F18)
			LET col      = 4
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F19)
			LET col      = 5
			LET int_flag = 2
			EXIT DISPLAY
		--#BEFORE ROW
			--#LET i = arr_curr()
			--#CALL mostrar_contadores_det(i, num_rows)
		--#BEFORE DISPLAY
			--#CALL dialog.keysetlabel("ACCEPT","")
			--#CALL dialog.keysetlabel("F1","")
			--#CALL dialog.keysetlabel("CONTROL-W","")
		--#AFTER DISPLAY
			--#CONTINUE DISPLAY
	END DISPLAY
	IF int_flag = 1 THEN
		EXIT WHILE
	END IF
	IF col <> columna_1 THEN
		LET columna_2          = columna_1 
		LET r_orden[columna_2] = r_orden[columna_1]
		LET columna_1          = col 
	END IF
	IF r_orden[columna_1] = 'ASC' THEN
		LET r_orden[columna_1] = 'DESC'
	ELSE
		LET r_orden[columna_1] = 'ASC'
	END IF
END WHILE
CLOSE WINDOW w_mdoc

END FUNCTION



FUNCTION mostrar_contadores_det(num_row, max_row)
DEFINE num_row, max_row	SMALLINT

DISPLAY BY NAME num_row, max_row

END FUNCTION



FUNCTION ver_documento_tran(codcli, tipo_trn, num_trn, loc, tipo)
DEFINE codcli		LIKE cxct022.z22_codcli
DEFINE tipo_trn		LIKE cxct022.z22_tipo_trn
DEFINE num_trn		LIKE cxct022.z22_num_trn
DEFINE loc		LIKE cxct022.z22_localidad
DEFINE tipo		LIKE cxct023.z23_tipo_favor
DEFINE prog		CHAR(10)
DEFINE param		VARCHAR(100)

LET prog = 'cxcp202 '
IF tipo IS NOT NULL THEN
	LET prog = 'cxcp203 '
END IF
LET param = codcli, ' ', tipo_trn, ' ', num_trn
CALL fl_ejecuta_comando('COBRANZAS', 'CO', prog, param, 1)

END FUNCTION



FUNCTION control_imprimir(num_fac)
DEFINE num_fac		LIKE talt023.t23_num_factura
DEFINE r_t28		RECORD LIKE talt028.*
DEFINE impresion	CHAR(1)
DEFINE row_max		SMALLINT
DEFINE col_max		SMALLINT
DEFINE param		VARCHAR(100)

LET row_max = 12
LET col_max = 42
IF vg_gui = 0 THEN
	LET row_max = 11
	LET col_max = 43
END IF
OPEN WINDOW w_308_2 AT 07, 20 WITH row_max ROWS, col_max COLUMNS
    ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE 0, BORDER,
	      MESSAGE LINE LAST - 2)
IF vg_gui = 1 THEN
	OPEN FORM f_308_2 FROM '../forms/talf308_2'
ELSE
	OPEN FORM f_308_2 FROM '../forms/talf308_2c'
END IF
DISPLAY FORM f_308_2
LET impresion = 'F'
DISPLAY BY NAME num_fac, impresion
WHILE TRUE
	LET int_flag = 0
	INPUT BY NAME impresion
		WITHOUT DEFAULTS
		ON KEY(INTERRUPT)
			LET int_flag = 1
			EXIT INPUT
	END INPUT
	IF int_flag THEN
		EXIT WHILE
	END IF
	CASE impresion
		WHEN 'F'
			LET param = rm_t23.t23_num_factura
			CALL fl_ejecuta_comando('TALLER', vg_modulo, 'talp403',
						param, 1)
		WHEN 'A'
			LET param = rm_t23.t23_orden
			CALL fl_ejecuta_comando('TALLER', vg_modulo, 'talp408',
						param, 1)
		WHEN 'D'
			INITIALIZE r_t28.* TO NULL
			SELECT * INTO r_t28.*
				FROM talt028
				WHERE t28_compania  = rm_t23.t23_compania
				  AND t28_localidad = rm_t23.t23_localidad
				  AND t28_ot_ant    = rm_t23.t23_orden
			IF r_t28.t28_compania IS NULL THEN
				CALL fl_mostrar_mensaje('Esta Factura no esta Anulada/Devuelta.', 'exclamation')
				CONTINUE WHILE
			END IF
			LET param = ' ', r_t28.t28_num_dev
			CALL fl_ejecuta_comando('TALLER', vg_modulo, 'talp413 ',
						param, 1)
		WHEN 'T'
			LET param = rm_t23.t23_num_factura
			CALL fl_ejecuta_comando('TALLER', vg_modulo, 'talp403',
						param, 1)
			LET param = rm_t23.t23_orden
			CALL fl_ejecuta_comando('TALLER', vg_modulo, 'talp408',
						param, 1)
			INITIALIZE r_t28.* TO NULL
			SELECT * INTO r_t28.*
				FROM talt028
				WHERE t28_compania  = rm_t23.t23_compania
				  AND t28_localidad = rm_t23.t23_localidad
				  AND t28_ot_ant    = rm_t23.t23_orden
			IF r_t28.t28_compania IS NULL THEN
				CONTINUE WHILE
			END IF
			LET param = ' ', r_t28.t28_num_dev
			CALL fl_ejecuta_comando('TALLER', vg_modulo, 'talp413 ',
						param, 1)
	END CASE
END WHILE
CLOSE WINDOW w_308_2
LET int_flag = 0
RETURN

END FUNCTION
