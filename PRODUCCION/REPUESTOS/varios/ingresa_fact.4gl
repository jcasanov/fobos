
------------------------------------------------------------------------------
-- Titulo           : repp303.4gl - Consulta de Liquidacion de pedidos de items
-- Elaboracion      : 14-dic-2001
-- Autor            : GVA
-- Formato Ejecucion: fglrun repp303 base módulo compañía localidad
-- Ultima Correccion: 1
-- Motivo Correccion: 1
------------------------------------------------------------------------------

GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_demonios	VARCHAR(12)
DEFINE rm_p01		RECORD LIKE cxpt001.*
DEFINE vm_max_det       SMALLINT
DEFINE vm_num_det       SMALLINT
DEFINE vm_filas_pant    SMALLINT
DEFINE vm_cod_tran	LIKE rept019.r19_cod_tran

DEFINE rm_orden 	ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1	SMALLINT
DEFINE vm_columna_2	SMALLINT

DEFINE r_detalle	ARRAY [1000] OF RECORD
				r28_numliq	LIKE rept028.r28_numliq,
				r28_fecha_ing	LIKE rept028.r28_fecha_ing,
				p01_nomprov	LIKE cxpt001.p01_nomprov,
				r28_total_fob	LIKE rept028.r28_total_fob,
				total		LIKE rept028.r28_tot_cargos
			END RECORD

MAIN

DEFER QUIT 
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/errores')
CALL fgl_init4js()
CALL fl_marca_registrada_producto()

IF num_args() <> 4 THEN          -- Validar # parámetros correcto
	CALL fgl_winmessage(vg_producto, 'Número de parámetros incorrecto',
			    'stop')
	EXIT PROGRAM
END IF

LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_codcia   = arg_val(3)
LET vg_codloc   = arg_val(4)
LET vg_proceso = 'repp303'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)

CALL funcion_master()

END MAIN



FUNCTION funcion_master()
DEFINE i 	SMALLINT

CALL fl_nivel_isolation()

LET vm_max_det    = 1000
LET vm_filas_pant = fgl_scr_size('r_detalle')

OPEN WINDOW w_repp303 AT 3,2 WITH 22 ROWS, 80 COLUMNS
    ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE 0,BORDER,
	      MESSAGE LINE LAST - 2)
OPTIONS INPUT NO WRAP,
	ACCEPT KEY	F12
OPEN FORM f_repp303 FROM "../forms/repf303_1"
DISPLAY FORM f_repp303

LET vm_num_det = 0

WHILE TRUE
	FOR i = 1 TO vm_filas_pant
		INITIALIZE r_detalle[i].* TO NULL
		CLEAR r_detalle[i].*
	END FOR
	CLEAR FORM 
	DISPLAY "" AT 20, 4
	DISPLAY '0', " de ", '0' AT 20, 4
	CALL control_display_botones()

	CALL control_construct()
	IF int_flag = 1 THEN
		EXIT WHILE
	END IF
END WHILE

END FUNCTION



FUNCTION control_display_botones()

DISPLAY 'No'       		TO tit_col1
DISPLAY 'Fecha Cierre'		TO tit_col2
DISPLAY 'Proveedor'    		TO tit_col3
DISPLAY 'Costo FOB'   		TO tit_col4
DISPLAY 'Total'		     	TO tit_col5

END FUNCTION



FUNCTION control_construct()
DEFINE query         	VARCHAR(2000)
DEFINE i,j,col		SMALLINT
DEFINE command_run	VARCHAR(300)
DEFINE r		RECORD LIKE rept019.*

        LET int_flag = 0
LET vm_columna_1 = 1
LET vm_columna_2 = 2
LET rm_orden[vm_columna_1]  = 'ASC'
INITIALIZE col TO NULL

WHILE TRUE

 	LET query = 'SELECT r28_numliq, r19_fecing, p01_nomprov, ', 
			' r28_fob_fabrica, r28_total_fob ',
			'  FROM rept028, cxpt001, rept019 ',
			' WHERE r28_compania  = ',vg_codcia,
			'   AND r28_localidad = ',vg_codloc,
			'   AND r28_estado    = "P" ',
			'   AND r28_codprov   = p01_codprov ',
			'   AND r19_compania  = r28_compania ',
			'   AND r19_localidad = r28_localidad ',
			'   AND r19_cod_tran  = "IM" ',
			'   AND r19_numliq    = r28_numliq ',
			'   AND DATE(r19_fecing) BETWEEN MDY(2, 1, 2009) AND TODAY ',
			'   AND NOT EXISTS (SELECT 1 FROM cxpt020 ',
			'					 WHERE p20_compania  = r28_compania ',
			'					   AND p20_localidad = r28_localidad ',
			'					   AND p20_numliq    = r28_numliq) ',
    			' ORDER BY ', vm_columna_1, ' ', rm_orden[vm_columna_1],
                           ', ', vm_columna_2, ' ', rm_orden[vm_columna_2]

	PREPARE consulta FROM query
	DECLARE q_consulta CURSOR FOR consulta

	LET i = 1
	FOREACH q_consulta INTO r_detalle[i].*
		LET i = i + 1
		IF i > vm_max_det THEN
			EXIT FOREACH
		END IF
	END FOREACH

	LET vm_num_det = i - 1
	IF vm_num_det = 0 THEN
		LET INT_FLAG = 1
		RETURN
	END IF

	CALL set_count(vm_num_det)
	DISPLAY ARRAY r_detalle TO r_detalle.*

		BEFORE DISPLAY
			CALL dialog.keysetlabel('ACCEPT','')
			CALL dialog.keysetlabel('F5','Ing. Deuda')

		BEFORE ROW
			LET i = arr_curr()
			LET j = scr_line()
			CALL muestra_contadores_det(i)

		AFTER DISPLAY 
			CONTINUE DISPLAY

		ON KEY(INTERRUPT)
			LET int_flag = 1
			EXIT DISPLAY

		ON KEY(F5)
			CREATE TEMP TABLE tmp_fact (
				pedido			CHAR(10),
				factura			CHAR(15),
				fecha			DATE,
				valor			DECIMAL(11,2)
			)
			CALL ingresa_facturas_proveedor(r_detalle[i].r28_numliq)
			DROP TABLE tmp_fact
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

END FUNCTION



FUNCTION muestra_contadores_det(i)
DEFINE i           SMALLINT

DISPLAY "" AT 20, 4
DISPLAY i, " de ", vm_num_det AT 20,4

END FUNCTION



FUNCTION ingresa_facturas_proveedor(numliq)

DEFINE numliq		LIKE rept028.r28_numliq
DEFINE ind_ped		INTEGER
DEFINE i			INTEGER
DEFINE salir 		INTEGER
DEFINE grabar 		INTEGER
DEFINE resp			CHAR(6)
DEFINE val_fact		LIKE rept028.r28_total_fob

DEFINE r_pedidos	ARRAY [100] OF RECORD
	r16_pedido		LIKE rept016.r16_pedido,
	p01_nomprov		LIKE cxpt001.p01_nomprov,
	total_fob		LIKE rept017.r17_fob
END RECORD

DECLARE q_pedidos CURSOR FOR
	SELECT r117_pedido, p01_nomprov, SUM(r117_cantidad * r117_fob)
	  FROM rept117, cxpt001
	 WHERE r117_compania  = vg_codcia
	   AND r117_localidad = vg_codloc
	   AND r117_cod_tran  = 'IX'
	   AND r117_numliq    = numliq 
	   AND p01_codprov    = (SELECT r16_proveedor FROM rept016
							  WHERE r16_compania  = r117_compania
							    AND r16_localidad = r117_localidad
								AND r16_pedido    = r117_pedido)
	 GROUP BY 1, 2
	 ORDER BY 1

LET ind_ped = 1
FOREACH q_pedidos INTO r_pedidos[ind_ped].*
	LET ind_ped = ind_ped + 1
	IF ind_ped > 100 THEN
		EXIT FOREACH
	END IF
END FOREACH
LET ind_ped = ind_ped - 1

IF ind_ped = 0 THEN
	CALL fgl_winmessage(vg_producto, 'No existen pedidos asociados a esta liquidacion.', 'stop')
	EXIT PROGRAM
END IF

OPEN WINDOW w_ped AT 8,10 WITH 15 ROWS, 55 COLUMNS
    ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE 0,BORDER,
	      MESSAGE LINE LAST - 2)
OPTIONS INPUT NO WRAP,
	ACCEPT KEY	F12
OPEN FORM f_ped FROM "../forms/repf208_2"
DISPLAY FORM f_ped

DISPLAY 'Pedido' TO tit_col1
DISPLAY 'Proveedor' TO tit_col2
DISPLAY 'Total Fob' TO tit_col3
DISPLAY 'Factura' TO tit_col4
DISPLAY 'Fecha' TO tit_col5
DISPLAY 'Valor' TO tit_col6

LET salir = 0
LET grabar = 0
WHILE NOT salir

	CALL set_count(ind_ped)
	DISPLAY ARRAY r_pedidos TO r_pedidos.* 
		BEFORE DISPLAY
			CALL dialog.keysetlabel('ACCEPT','')
			CALL dialog.keysetlabel('F5','Facturas')
			CALL dialog.keysetlabel('F6','Grabar')
		BEFORE ROW 
			LET i = arr_curr() 
		ON KEY(INTERRUPT)
			LET int_flag = 0
            CALL fl_mensaje_abandonar_proceso()	RETURNING resp
			IF resp = 'No' THEN
				CONTINUE DISPLAY
			END IF
			LET salir = 1
			LET grabar = 0
			EXIT DISPLAY
		ON KEY(F5)
			EXIT DISPLAY
		ON KEY(F6)
			-- Verificamos que los valores de las factures cuadren con los KP
			FOR i = 1 TO ind_ped
				SELECT NVL(SUM(valor), 0) INTO val_fact
				  FROM tmp_fact
				 WHERE pedido = r_pedidos[i].r16_pedido

				IF val_fact <> r_pedidos[i].total_fob THEN
					CALL fgl_winmessage(vg_producto, 'Debe ingresar todas las facturas del pedido ' || r_pedidos[i].r16_pedido CLIPPED, 'exclamation')
					LET i = arr_curr()
					CONTINUE WHILE
				END IF
			END FOR
			LET grabar = 1
			LET salir = 1
			EXIT DISPLAY
	END DISPLAY

	IF salir THEN
		EXIT WHILE
	END IF

	CALL ingresar_facturas(r_pedidos[i].r16_pedido)

END WHILE

IF grabar THEN
	FOR i = 1 TO ind_ped
		CALL grabar(numliq, r_pedidos[i].*)
	END FOR
END IF

CLOSE WINDOW w_ped

END FUNCTION



FUNCTION grabar(numliq, r16_pedido, p01_nomprov, total_fob)
DEFINE numliq			LIKE rept028.r28_numliq
DEFINE r16_pedido		LIKE rept016.r16_pedido
DEFINE p01_nomprov		LIKE cxpt001.p01_nomprov
DEFINE total_fob		LIKE rept017.r17_fob

DEFINE pedido			LIKE rept016.r16_pedido

DEFINE r_r28			RECORD LIKE rept028.*
DEFINE r_p20			RECORD LIKE cxpt020.*

CALL fl_lee_liquidacion_rep(vg_codcia, vg_codloc, numliq) RETURNING r_r28.*

INITIALIZE r_p20.* TO NULL
LET r_p20.p20_compania    = vg_codcia
LET r_p20.p20_localidad   = vg_codloc
LET r_p20.p20_codprov     = r_r28.r28_codprov
LET r_p20.p20_tipo_doc    = 'FA'
LET r_p20.p20_dividendo   = 1
LET r_p20.p20_tasa_int    = 0
LET r_p20.p20_tasa_mora   = 0
LET r_p20.p20_moneda      = r_r28.r28_moneda
LET r_p20.p20_paridad     = 1 
LET r_p20.p20_valor_int   = 0
LET r_p20.p20_saldo_int   = 0
LET r_p20.p20_porc_impto  = 0
LET r_p20.p20_valor_impto = 0
LET r_p20.p20_cartera     = 6 -- cartera de proveedores
LET r_p20.p20_numliq      = numliq
LET r_p20.p20_origen      = 'A'
LET r_p20.p20_cod_depto   = 2
LET r_p20.p20_usuario     = vg_usuario
LET r_p20.p20_fecing	  = TODAY

DECLARE q_grabar CURSOR FOR SELECT * FROM tmp_fact 

FOREACH q_grabar INTO pedido, r_p20.p20_num_doc, r_p20.p20_fecha_emi, 
					  r_p20.p20_valor_cap

	IF pedido = r16_pedido THEN 
		LET r_p20.p20_referencia = 'Pedido: ', pedido
		LET r_p20.p20_fecha_vcto = r_p20.p20_fecha_emi + 60 UNITS DAY
		LET r_p20.p20_saldo_cap  = r_p20.p20_valor_cap
		LET r_p20.p20_valor_fact = r_p20.p20_valor_cap

		INSERT INTO cxpt020 VALUES (r_p20.*)
	END IF
END FOREACH

END FUNCTION



FUNCTION ingresar_facturas(r16_pedido)
DEFINE r16_pedido		LIKE rept016.r16_pedido
DEFINE ind_fact			INTEGER
DEFINE i				INTEGER

DEFINE r_detfact	ARRAY [100] OF RECORD
	num_fact			CHAR(15),
	fec_fact			DATE,
	val_fact			DECIMAL(11,2)
END RECORD

LET int_flag = 0

DECLARE q_fact CURSOR FOR 
	SELECT factura, fecha, valor FROM tmp_fact 
 	 WHERE pedido = r16_pedido

LET ind_fact = 1
FOREACH q_fact USING r16_pedido INTO r_detfact[ind_fact].*
	LET ind_fact = ind_fact + 1
	IF ind_fact > 100 THEN
		EXIT FOREACH
	END IF
END FOREACH	
LET ind_fact = ind_fact - 1

CALL set_count(ind_fact)
INPUT ARRAY r_detfact WITHOUT DEFAULTS FROM r_detfact.*
	AFTER INPUT
		DELETE FROM tmp_fact WHERE pedido = r16_pedido
		FOR ind_fact = 1 TO arr_count()
			INSERT INTO tmp_fact VALUES (r16_pedido, r_detfact[ind_fact].*)
		END FOR
END INPUT
IF int_flag THEN
	LET int_flag = 0
END IF

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
