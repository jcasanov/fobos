{*
 * Titulo           : repp233.4gl - Despacho de proformas no facturadas
 * Elaboracion      : 12-nov-2009
 * Autor            : JCM
 * Formato Ejecucion: fglrun repp233 base modulo compañía localidad
 *}

GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_cod_fact		LIKE rept019.r19_cod_tran
DEFINE vm_cod_desp		LIKE rept019.r19_cod_tran
DEFINE vm_subt_tran		LIKE rept019.r19_cod_subtipo


DEFINE vm_max_rows		INTEGER

DEFINE rm_orden ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1	SMALLINT
DEFINE vm_columna_2	SMALLINT

DEFINE rm_prof ARRAY[1000] OF RECORD
	numprof			LIKE rept021.r21_numprof,
	numprev			LIKE rept023.r23_numprev,
	nomcli			LIKE rept021.r21_nomcli,
	fecing			LIKE rept021.r21_fecing
END RECORD

DEFINE r_detalle ARRAY[1000] OF RECORD
	r20_item		LIKE rept020.r20_item,
	r10_nombre		LIKE rept010.r10_nombre,
	r11_ubicacion	LIKE rept011.r11_ubicacion,
	r20_cant_ped	LIKE rept020.r20_cant_ped,
	r11_stock_act	LIKE rept011.r11_stock_act,
	r20_cant_ven	LIKE rept020.r20_cant_ven
END RECORD



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/repp233.error')
CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 THEN          -- Validar # parámetros correcto
	CALL fgl_winmessage(vg_producto, 
		'Número de parámetros incorrecto', 
		'stop')
	EXIT PROGRAM
END IF
LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_codcia   = arg_val(3)
LET vg_codloc   = arg_val(4)
LET vg_proceso = 'repp233'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()

END MAIN



FUNCTION funcion_master()
DEFINE r		RECORD LIKE gent000.*
DEFINE r_rep	RECORD LIKE rept000.*
DEFINE i		SMALLINT

OPEN WINDOW repw233_1 AT 3,2 WITH 22 ROWS, 80 COLUMNS
	ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE FIRST,
		  BORDER, MESSAGE LINE LAST) 
OPEN FORM repf233_1 FROM '../forms/repf233_1'
DISPLAY FORM repf233_1
LET vm_max_rows = 1000
LET vm_cod_fact = 'FA'
LET vm_cod_desp = 'NE'
LET vm_subt_tran = 3 -- Subtipo de transaccion:
                     --  Despacho en base a una proforma

DISPLAY 'Prof'			 TO tit_col1
DISPLAY 'Prev'			 TO tit_col2
DISPLAY 'Cliente'        TO tit_col3
DISPLAY 'Fecha aprob.'   TO tit_col4

FOR i = 1 TO fgl_scr_size('rm_prof')
	CLEAR rm_prof[i].*
END FOR
CALL muestra_consulta()

END FUNCTION



FUNCTION muestra_consulta()
DEFINE i			SMALLINT
DEFINE query		VARCHAR(1000)
DEFINE num_rows		INTEGER

FOR i = 1 TO 10
	LET rm_orden[i] = '' 
END FOR
LET vm_columna_1 = 3
LET vm_columna_2 = 2
LET rm_orden[vm_columna_1] = 'ASC'
LET rm_orden[vm_columna_2] = 'ASC'
WHILE TRUE
	LET query = 'SELECT r102_numprof, r23_numprev, r23_nomcli, r23_fecing ',
				'  FROM rept023, rept102 ',
				' WHERE r23_compania   = ', vg_codcia, 
				'   AND r23_localidad  = ', vg_codloc, 
				'   AND r23_codcli     IS NOT NULL ',  
				'   AND r23_cont_cred  = "R" ',  
				'   AND r23_estado     = "P" ',  
				'   AND r102_compania  = r23_compania ',
				'   AND r102_localidad = r23_localidad ',
				'   AND r102_numprev   = r23_numprev ',
				' ORDER BY ', vm_columna_1, ' ', rm_orden[vm_columna_1], ',', 
							  vm_columna_2, ' ', rm_orden[vm_columna_2] 
	PREPARE crep FROM query
	DECLARE q_crep CURSOR FOR crep 
	LET i = 1
	FOREACH q_crep INTO rm_prof[i].*
		LET i = i + 1
		IF i > vm_max_rows THEN
			EXIT FOREACH
		END IF
	END FOREACH
	FREE q_crep
	LET num_rows = i - 1
	IF num_rows = 0 THEN
		CALL fl_mensaje_consulta_sin_registros()
		LET int_flag = 1
		EXIT PROGRAM
	END IF
	CALL set_count(num_rows)
	DISPLAY ARRAY rm_prof TO rm_prof.*
		BEFORE ROW
			LET i = arr_curr()
			MESSAGE i, ' de ', num_rows
		BEFORE DISPLAY
			CALL dialog.keysetlabel("ACCEPT","")
			CALL dialog.keysetlabel("F5","Despachar")
		AFTER DISPLAY
			CONTINUE DISPLAY
		ON KEY(INTERRUPT)
			EXIT DISPLAY
		ON KEY(F5)
			CALL despachar_preventa(rm_prof[i].numprof, rm_prof[i].numprev)
			LET int_flag = 0
		ON KEY(F15)
			LET i = 1
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F16)
			LET i = 2
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F17)
			LET i = 3
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F18)
			LET i = 4
			LET int_flag = 2
			EXIT DISPLAY
	END DISPLAY
	IF int_flag = 1 THEN
		EXIT WHILE
	END IF
	IF i <> vm_columna_1 THEN
		LET vm_columna_2           = vm_columna_1 
		LET rm_orden[vm_columna_2] = rm_orden[vm_columna_1]
		LET vm_columna_1 = i 
	END IF
	IF rm_orden[vm_columna_1] = 'ASC' THEN
		LET rm_orden[vm_columna_1] = 'DESC'
	ELSE
		LET rm_orden[vm_columna_1] = 'ASC'
	END IF
END WHILE
ERROR ' ' ATTRIBUTE(NORMAL)
                                                                                
END FUNCTION



FUNCTION despachar_preventa(numprof, numprev)
DEFINE numprof		LIKE rept021.r21_numprof
DEFINE numprev		LIKE rept023.r23_numprev
DEFINE resp			CHAR(6)
DEFINE r_r19		RECORD LIKE rept019.*
DEFINE r_r23		RECORD LIKE rept023.*
DEFINE r_g21		RECORD LIKE gent021.*

DEFINE numelm		INTEGER

OPEN WINDOW repw233_2 AT 3,2 WITH 22 ROWS, 80 COLUMNS
	ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE FIRST,
		  BORDER, MESSAGE LINE LAST) 
OPEN FORM repf233_2 FROM '../forms/repf233_2'
DISPLAY FORM repf233_2

CREATE TEMP TABLE tmp_det (
	r20_item		CHAR(15),
	r10_nombre		VARCHAR(35),
	r11_ubicacion	CHAR(10),
	r20_cant_ped	SMALLINT,
	r11_stock_act	SMALLINT,
	r20_cant_ven	SMALLINT
)

CALL fl_lee_preventa_rep(vg_codcia, vg_codloc, numprev) RETURNING r_r23.*

DISPLAY 'Codigo' 		TO tit_col1
DISPLAY 'Descripcion' 	TO tit_col2
DISPLAY 'Ped' 			TO tit_col3
DISPLAY 'Stock' 		TO tit_col4
DISPLAY 'Desp' 			TO tit_col5

INITIALIZE r_r19.* TO NULL
LET r_r19.r19_compania    = vg_codcia
LET r_r19.r19_localidad   = vg_codloc
LET r_r19.r19_cod_tran    = vm_cod_desp 
LET r_r19.r19_cod_subtipo = vm_subt_tran
LET r_r19.r19_cont_cred   = 'C'
LET r_r19.r19_codcli      = r_r23.r23_codcli
LET r_r19.r19_nomcli      = r_r23.r23_nomcli
LET r_r19.r19_dircli      = r_r23.r23_dircli
LET r_r19.r19_telcli      = r_r23.r23_telcli
LET r_r19.r19_cedruc      = r_r23.r23_cedruc
LET r_r19.r19_vendedor    = r_r23.r23_vendedor
LET r_r19.r19_descuento   = 0.0
LET r_r19.r19_porc_impto  = 0.0
LET r_r19.r19_moneda      = rg_gen.g00_moneda_base
LET r_r19.r19_paridad     = 1
LET r_r19.r19_precision   = rg_gen.g00_decimal_mb
LET r_r19.r19_tot_costo   = 0.0
LET r_r19.r19_tot_bruto   = 0.0
LET r_r19.r19_tot_dscto   = 0.0
LET r_r19.r19_tot_neto    = 0.0
LET r_r19.r19_flete       = 0.0
LET r_r19.r19_usuario     = vg_usuario
LET r_r19.r19_fecing      = CURRENT

CALL fl_lee_cod_transaccion(r_r19.r19_cod_tran) RETURNING r_g21.*
LET r_r19.r19_tipo_tran  = r_g21.g21_tipo
LET r_r19.r19_calc_costo = r_g21.g21_calc_costo

DISPLAY numprof, r_r23.r23_numprev, r_r23.r23_nomcli, r_r23.r23_fecing 
	 TO numprof, numprev, nomcli, fecing

CALL ingresar_bodega(r_r19.*) RETURNING r_r19.r19_bodega_ori
IF r_r19.r19_bodega_ori IS NULL THEN
	CLOSE WINDOW repw233_2
	DROP TABLE tmp_det
	RETURN
END IF

CALL cargar_items_pendientes(numprof, numprev, r_r19.r19_bodega_ori) 
	RETURNING numelm
IF numelm = 0 THEN
	CALL fgl_winmessage(vg_producto, 'No queda nada pendiente de despacho.', 
						'exclamation')
	CLOSE WINDOW repw233_2
	DROP TABLE tmp_det
	RETURN
END IF

LET int_flag = 0
CALL ingresar_detalle(numelm) RETURNING numelm
IF numelm IS NULL THEN
	CLOSE WINDOW repw233_2
	DROP TABLE tmp_det
	RETURN
END IF

BEGIN WORK

LET r_r19.r19_bodega_dest = r_r19.r19_bodega_ori
LET r_r19.r19_num_tran = nextValInSequence(vg_modulo, r_r19.r19_cod_tran)
IF r_r19.r19_num_tran = -1 THEN
	CLOSE WINDOW repw233_2
	DROP TABLE tmp_det
	RETURN
END IF

INSERT INTO rept019 VALUES (r_r19.*)

CALL grabar_detalle(r_r23.*, r_r19.*, numelm)

COMMIT WORK

CALL fl_control_master_contab_repuestos(vg_codcia, vg_codloc, 
		r_r19.r19_cod_tran, r_r19.r19_num_tran)
CALL imprimir(r_r19.r19_cod_tran, r_r19.r19_num_tran)

DROP TABLE tmp_det

CALL fgl_winmessage(vg_producto, 'Proceso completado OK', 'exclamation')

CLOSE WINDOW repw233_2

END FUNCTION



FUNCTION imprimir(cod_tran, num_tran)
DEFINE cod_tran		LIKE rept019.r19_cod_tran
DEFINE num_tran		LIKE rept019.r19_num_tran

DEFINE comando		CHAR(255)

LET comando = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', 
	vg_separador, 'fuentes', vg_separador, '; fglrun repp422 ', vg_base, 
	' ', 'RE', vg_codcia, ' ', vg_codloc, ' ', cod_tran, ' ',
	num_tran
	
RUN comando	

END FUNCTION



FUNCTION ingresar_bodega(r_r19)
DEFINE r_r19 		RECORD LIKE rept019.*
DEFINE r_r02		RECORD LIKE rept002.*
DEFINE resp			CHAR(6)

INPUT BY NAME r_r19.r19_cod_tran, r_r19.r19_num_tran, r_r19.r19_bodega_ori 
	WITHOUT DEFAULTS
	ON KEY (INTERRUPT)
		IF NOT FIELD_TOUCHED(r19_bodega_ori) THEN
			RETURN NULL
		END IF
		LET INT_FLAG = 0
		CALL fl_mensaje_abandonar_proceso() RETURNING resp
		IF resp = 'Yes' THEN
			LET int_flag = 1
			EXIT INPUT
		END IF
	ON KEY(F2)
		IF INFIELD(r19_bodega_ori) THEN
		     CALL fl_ayuda_bodegas_rep(vg_codcia, vg_codloc, 'T')
		     	RETURNING r_r02.r02_codigo, r_r02.r02_nombre
		     IF r_r02.r02_codigo IS NOT NULL THEN
			    LET r_r19.r19_bodega_ori = r_r02.r02_codigo
			    DISPLAY BY NAME r_r19.r19_bodega_ori
			    DISPLAY r_r02.r02_nombre TO n_bodega
		     END IF
		END IF
		LET int_flag = 0
	AFTER FIELD r19_bodega_ori
		IF r_r19.r19_bodega_ori IS NOT NULL THEN
			CALL fl_lee_bodega_rep(vg_codcia, r_r19.r19_bodega_ori)
				RETURNING r_r02.*
			IF r_r02.r02_codigo IS NULL THEN
				CALL fgl_winmessage(vg_producto, 'Bodega no existe.',
						    		'exclamation')
				CLEAR n_bodega
				NEXT FIELD r19_bodega_ori
			END IF 
			IF r_r02.r02_estado = 'B' THEN
				CALL fgl_winmessage(vg_producto, 'Bodega está bloqueada.',
									'exclamation')
				NEXT FIELD r19_bodega_ori
			END IF
			IF r_r02.r02_localidad <> vg_codloc THEN
				CALL fgl_winmessage(vg_producto, 'Bodega no es de esta ' ||
												 'localidad.',
									'exclamation')
				NEXT FIELD r19_bodega_ori
			END IF
			IF r_r02.r02_factura <> 'S' THEN
				CALL fgl_winmessage(vg_producto, 'Bodega no factura.',
									'exclamation')
				NEXT FIELD r19_bodega_ori
			END IF
			DISPLAY r_r02.r02_nombre TO n_bodega
		ELSE
			CLEAR n_bodega
		END IF
END INPUT
IF int_flag THEN
	LET int_flag = 0 	
	RETURN NULL
END IF

RETURN r_r19.r19_bodega_ori

END FUNCTION



FUNCTION cargar_items_pendientes(numprof, numprev, bodega)
DEFINE numprof				LIKE rept021.r21_numprof
DEFINE numprev				LIKE rept023.r23_numprev
DEFINE bodega				LIKE rept019.r19_bodega_ori

DEFINE i					INTEGER

DEFINE entregado			INTEGER
DEFINE r_desp RECORD
	r20_item		LIKE rept020.r20_item,
	r10_nombre		LIKE rept010.r10_nombre,
	r11_ubicacion	LIKE rept011.r11_ubicacion,
	r20_cant_ped	LIKE rept020.r20_cant_ped,
	r11_stock_act	LIKE rept011.r11_stock_act,
	r20_cant_ven	LIKE rept020.r20_cant_ven
END RECORD

DECLARE q_desp CURSOR FOR
	SELECT r24_item, r10_nombre, NVL(r11_ubicacion, 'SN'), r24_cant_ven, 
		   NVL(r11_stock_act, 0), 0
	  FROM rept024, rept010, OUTER rept011
	 WHERE r24_compania  = vg_codcia
	   AND r24_localidad = vg_codloc
	   AND r24_numprev   = numprev
	   AND r10_compania   = r24_compania
	   AND r10_codigo     = r24_item
	   AND r11_compania   = r10_compania
	   AND r11_bodega     = bodega
	   AND r11_item       = r10_codigo
	 ORDER BY 3

LET i = 1
FOREACH q_desp INTO r_desp.*
	INITIALIZE entregado TO NULL
	SELECT SUM(r20_cant_ent) INTO entregado 
	  FROM rept118, rept020
	 WHERE r118_compania  = vg_codcia
	   AND r118_localidad = vg_codloc
	   AND r118_numprev   = numprev
       AND r118_cod_fact  IS NULL
       AND r118_item_desp = r_desp.r20_item
	   AND r20_compania   = r118_compania
	   AND r20_localidad  = r118_localidad
	   AND r20_cod_tran   = r118_cod_desp
	   AND r20_num_tran   = r118_num_desp
	   AND r20_item       = r118_item_desp

	IF entregado IS NULL THEN
		LET entregado = 0
	END IF

	IF r_desp.r20_cant_ped <= entregado THEN
		CONTINUE FOREACH
	END IF
	LET r_detalle[i].* = r_desp.*
	LET r_detalle[i].r20_cant_ped = r_detalle[i].r20_cant_ped - entregado
	LET i = i + 1
	IF i > vm_max_rows THEN
		EXIT FOREACH
	END IF
END FOREACH
LET i = i - 1

RETURN i

END FUNCTION



FUNCTION ingresar_detalle(numelm)
DEFINE numelm			INTEGER
DEFINE i				INTEGER
DEFINE j				INTEGER
DEFINE resp				CHAR(6)

CALL set_count(numelm)
INPUT ARRAY r_detalle WITHOUT DEFAULTS FROM r_detalle.*
	ATTRIBUTES (INSERT ROW=FALSE, DELETE ROW=FALSE)
	BEFORE INSERT
		CANCEL INSERT
	BEFORE ROW
		LET i = arr_curr()    # POSICION CORRIENTE EN EL ARRAY
		LET j = scr_line()    # POSICION CORRIENTE EN LA PANTALLA
		DISPLAY '' AT 10,1
		DISPLAY i, ' de ', arr_count() AT 20, 1 
	ON KEY(INTERRUPT)
		LET INT_FLAG = 0
		CALL fl_mensaje_abandonar_proceso() RETURNING resp
		IF resp = 'Yes' THEN
			LET int_flag = 1
			EXIT INPUT
		END IF
	ON KEY(F5)
		CALL fl_sustituido_por(vg_codcia, r_detalle[i].r20_item)
--		CALL proceso_sustitucion(r_detalle[i].r20_item, j, i, num_elm) 
--			RETURNING num_elm
		LET int_flag = 0
	AFTER FIELD r20_cant_ven
		IF r_detalle[i].r20_cant_ven > r_detalle[i].r11_stock_act THEN
			CALL fgl_winmessage(vg_producto, 'No hay stock suficiente.',
								'exclamation')
			NEXT FIELD r20_cant_ven
		END IF
		IF r_detalle[i].r20_cant_ven > r_detalle[i].r20_cant_ped THEN
			CALL fgl_winmessage(vg_producto, 
								'No puede entregar mas de lo facturado.',
								'exclamation')
			NEXT FIELD r20_cant_ven
		END IF
	AFTER INPUT
		LET numelm = arr_count()
END INPUT
IF int_flag THEN
	LET int_flag = 0
	RETURN NULL
END IF

RETURN numelm

END FUNCTION



FUNCTION grabar_detalle(r_r23, r_r19, numelm)
DEFINE r_r23		RECORD LIKE rept023.*
DEFINE r_r19		RECORD LIKE rept019.*
DEFINE numelm		INTEGER

DEFINE r_r10		RECORD LIKE rept010.*
DEFINE r_r20		RECORD LIKE rept020.*
DEFINE r_r118		RECORD LIKE rept118.*
DEFINE i			INTEGER

INITIALIZE r_r20.*, r_r118.* TO NULL

LET r_r20.r20_compania  = r_r19.r19_compania
LET r_r20.r20_localidad = r_r19.r19_localidad
LET r_r20.r20_cod_tran  = r_r19.r19_cod_tran
LET r_r20.r20_num_tran  = r_r19.r19_num_tran
LET r_r20.r20_orden     = 0

FOR i = 1 TO numelm
	IF r_detalle[i].r20_item IS NULL THEN
		CONTINUE FOR
	END IF
	IF r_detalle[i].r11_stock_act = 0 THEN
		CONTINUE FOR
	END IF
	IF r_detalle[i].r20_cant_ven = 0 THEN
		CONTINUE FOR
	END IF

	CALL fl_lee_item(vg_codcia, r_detalle[i].r20_item) RETURNING r_r10.*
	IF r_r10.r10_codigo IS NULL THEN
		CONTINUE FOR
	END IF

	LET r_r20.r20_item       = r_r10.r10_codigo
	LET r_r20.r20_orden      = r_r20.r20_orden + 1 
	LET r_r20.r20_cant_ped   = r_detalle[i].r20_cant_ped
	LET r_r20.r20_cant_ven   = r_detalle[i].r20_cant_ven
	LET r_r20.r20_cant_dev   = 0 
	LET r_r20.r20_cant_ent   = r_detalle[i].r20_cant_ven
	LET r_r20.r20_descuento  = 0
	LET r_r20.r20_val_descto = 0
	LET r_r20.r20_precio     = r_r10.r10_costo_mb
	LET r_r20.r20_val_impto  = 0
	LET r_r20.r20_costo      = r_r10.r10_costo_mb
	LET r_r20.r20_fob        = r_r10.r10_fob 
	LET r_r20.r20_linea      = r_r10.r10_linea
	LET r_r20.r20_rotacion   = r_r10.r10_rotacion
	LET r_r20.r20_ubicacion  = r_detalle[i].r11_ubicacion
	LET r_r20.r20_costant_mb = r_r10.r10_costult_mb
	LET r_r20.r20_costant_ma = r_r10.r10_costult_ma
	LET r_r20.r20_costnue_mb = r_r10.r10_costo_mb
	LET r_r20.r20_costnue_ma = r_r10.r10_costo_ma
	
	SELECT NVL(SUM(r11_stock_act), 0) 
	  INTO r_r20.r20_stock_ant 
	  FROM rept011
	 WHERE r11_compania = r_r20.r20_compania
	   AND r11_item     = r_r20.r20_item

	LET r_r20.r20_stock_bd   = r_detalle[i].r11_stock_act
	LET r_r20.r20_fecing     = r_r19.r19_fecing

	{*
	 * Se graba el detalle del despacho
	 *}
	INSERT INTO rept020 VALUES (r_r20.*)

	{*
	 * Esto es para indicar que preventa se despacho con que Nota de Entrega.
	 *}
	LET r_r118.r118_compania  = r_r20.r20_compania
	LET r_r118.r118_localidad = r_r20.r20_localidad
	LET r_r118.r118_cod_desp  = r_r20.r20_cod_tran
	LET r_r118.r118_num_desp  = r_r20.r20_num_tran
	LET r_r118.r118_item_desp = r_r20.r20_item
	LET r_r118.r118_numprev   = r_r23.r23_numprev
	LET r_r118.r118_item_fact = r_r20.r20_item

	INSERT INTO rept118 VALUES (r_r118.*)

	{*
	 * Actualizo la existencia del item despachado
	 *}
	UPDATE rept011 SET r11_stock_act = r11_stock_act - r_r20.r20_cant_ven
	 WHERE r11_compania = r_r19.r19_compania
	   AND r11_bodega   = r_r19.r19_bodega_ori
	   AND r11_item     = r_r20.r20_item

	CALL fl_proceso_despues_insertar_linea_tr_rep(vg_codcia, vg_codloc, 
							r_r20.r20_cod_tran, r_r20.r20_num_tran, 
							r_r20.r20_item)
END FOR

END FUNCTION



FUNCTION nextValInSequence(modulo, tipo_tran)

DEFINE modulo		LIKE gent050.g50_modulo
DEFINE tipo_tran 	LIKE rept019.r19_cod_tran

DEFINE resp		CHAR(6)
DEFINE retVal 		INTEGER

LET retVal = -1
WHILE retVal = -1

LET retVal = fl_actualiza_control_secuencias(vg_codcia, vg_codloc, modulo,
		'AA', tipo_tran)
IF retVal = 0 THEN
	EXIT PROGRAM
END IF
IF retVal <> -1 THEN
	 EXIT WHILE
END IF

CALL fgl_winquestion(vg_producto, 
	'La tabla de secuencias de transacciones ' ||
        'está siendo accesada por otro usuario, espere unos  ' ||
        'segundos y vuelva a intentar', 
	'No', 'Yes|No|Cancel', 'question', 1) RETURNING resp 
IF resp <> 'Yes' THEN
	EXIT WHILE	
END IF

END WHILE

RETURN retVal

END FUNCTION


{
FUNCTION proceso_sustitucion(item, arr_scr_curr, arr_prog_curr, arr_prog_max)

DEFINE r22_cantidad	LIKE rept022.r22_cantidad
DEFINE item			LIKE rept010.r10_codigo
DEFINE item_ant		LIKE rept010.r10_codigo
DEFINE stock 		LIKE rept011.r11_stock_act
DEFINE cant  		SMALLINT
DEFINE porc_descto	LIKE rept022.r22_porc_descto
DEFINE arr_scr_curr	SMALLINT
DEFINE arr_prog_curr	SMALLINT
DEFINE arr_prog_max	SMALLINT
DEFINE i		SMALLINT
DEFINE j		SMALLINT

DEFINE r_r10		RECORD LIKE rept010.*
DEFINE r_r14		RECORD LIKE rept014.*


FOR i = 1 TO arr_prog_max
	INSERT INTO tmp_det
		VALUES (r_detalle[]
END FOR

SELECT COUNT(*) INTO cant FROM rept014 
	WHERE r14_compania = vg_codcia
	  AND r14_item_ant = item             

FOR i = arr_prog_max TO (arr_prog_curr + 1) STEP -1
	LET r_detalle[i+(cant-1)].*   = r_detalle[i].*    
END FOR

DECLARE q_sust CURSOR FOR 
	SELECT * FROM rept014 
		WHERE r14_compania = vg_codcia 
		  AND r14_item_ant = item

LET r22_cantidad = r_detalle[arr_prog_curr].r20_cant_ped
LET item_ant = item

OPEN q_sust
FOR i = 0 TO (cant - 1)
	LET j = arr_prog_curr + i
	INITIALIZE r_r14.* TO NULL
	FETCH q_sust INTO r_r14.*
	INITIALIZE r_detalle[j].* TO NULL
	LET r_detalle[j].r22_cantidad = r22_cantidad * r_r14.r14_cantidad 
	LET r_detalle_1[j].r22_item_ant = item_ant

	CALL fl_lee_item(vg_codcia, r_r14.r14_item_nue) RETURNING r_r10.*
	
END FOR
CLOSE q_sust
FREE  q_sust

LET i = i - 1

RETURN (arr_prog_max + i)

END FUNCTION
}


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
