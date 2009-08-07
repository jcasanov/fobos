{*
 * Titulo           : cxpp204.4gl - Solicitud de pago a proveedores
 *                                  por documentos
 * Elaboracion      : 21-nov-2001
 * Autor            : JCM
 * Formato Ejecucion: fglrun cxpp204 base modulo compania localidad [ord_pago]
 *		Si (ord_pago <> 0) el programa se esta ejcutando en modo de
 *			solo consulta
 *		Si (ord_pago = 0) el programa se esta ejecutando en forma 
 *			independiente
 *}
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_ord_pago	LIKE cxpt024.p24_orden_pago

DEFINE rm_orden         ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1     SMALLINT
DEFINE vm_columna_2     SMALLINT

-- CADA VEZ QUE SE REALIZE UNA CONSULTA SE GUARDARAN LOS ROWID DE CADA FILA 
-- RECUPERADA EN UNA TABLA LLAMADA r_rows QUE TENDRA 1000 ELEMENTOS
DEFINE vm_rows ARRAY[30000] OF INTEGER 	-- ARREGLO DE ROWID DE FILAS LEIDAS
DEFINE vm_row_current	SMALLINT	-- FILA CORRIENTE DEL ARREGLO
DEFINE vm_num_rows	SMALLINT	-- CANTIDAD DE FILAS LEIDAS

DEFINE vm_max_rows	SMALLINT
--
-- DEFINE RECORD(S) HERE
--
DEFINE rm_p24		RECORD LIKE cxpt024.*

DEFINE rm_docs ARRAY[30000] OF RECORD 
	proveedor	INTEGER,
	tipo_doc	CHAR(2),
	num_doc		CHAR(15),
	dividendo	SMALLINT,
	fecha_vcto	DATE,
	saldo		DECIMAL(12,2),
	valor_pagar	DECIMAL(12,2),
	check		CHAR(1)
END RECORD

DEFINE vm_max_docs	SMALLINT 
DEFINE vm_ind_docs	SMALLINT
DEFINE rm_docs_f4 ARRAY[100] OF RECORD 	-- Arreglo que se usara en la
	tipo_doc	CHAR(2),		-- forma cxpf204_4
	num_doc		CHAR(15),
	dividendo	SMALLINT,
	fecha_vcto	DATE,
	saldo  		DECIMAL(12,2),
	valor_pagar	DECIMAL(12,2)
END RECORD

DEFINE ind_max_ret	SMALLINT
DEFINE ind_ret		SMALLINT
DEFINE r_ret ARRAY[50] OF RECORD
	check		CHAR(1),
	n_retencion	LIKE ordt002.c02_nombre,
	codigo_sri	LIKE cxpt005.p05_codigo_sri,
	tipo_ret	LIKE cxpt005.p05_tipo_ret, 
	val_base	LIKE rept019.r19_tot_bruto, 
	porc		LIKE cxpt005.p05_porcentaje, 
	subtotal 	LIKE rept019.r19_tot_neto
END RECORD



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/cxpp204.error')
CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 AND num_args() <> 5 THEN	-- Validar # par�metros correcto
	CALL fgl_winmessage(vg_producto, 'N�mero de par�metros incorrecto', 
                            'stop')
	EXIT PROGRAM
END IF
LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_codcia   = arg_val(3)
LET vg_proceso = 'cxpp204'

CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	-- Asigna un valor por default a vg_codloc
				-- que luego puede ser reemplazado si se 
                                -- mantiene sin comentario la siguiente linea
LET vg_codloc   = arg_val(4)

LET vm_ord_pago = 0
IF num_args() = 5 THEN
	LET vm_ord_pago  = arg_val(5)
END IF

CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()

END MAIN



FUNCTION funcion_master()

DEFINE i		SMALLINT

CALL fl_nivel_isolation()
CALL fl_chequeo_mes_proceso_cxp(vg_codcia) RETURNING int_flag 
IF int_flag THEN
	RETURN
END IF
OPTIONS
	INPUT WRAP,
	ACCEPT KEY F12
OPEN WINDOW w_204 AT 3,2 WITH 22 ROWS, 80 COLUMNS
	ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE 0,
		  BORDER, MESSAGE LINE LAST - 2) 
OPEN FORM f_204 FROM '../forms/cxpf204_1'
DISPLAY FORM f_204

LET vm_num_rows = 0
LET vm_row_current = 0
INITIALIZE rm_p24.* TO NULL

LET vm_max_rows = 30000
LET vm_max_docs = 100
LET ind_max_ret = 50

IF vm_ord_pago <> 0 THEN
	CLOSE FORM f_204
	OPEN FORM f_204_4 FROM '../forms/cxpf204_4'
	DISPLAY FORM f_204_4
	CALL setea_nombre_botones_f4()
	CALL execute_query()
	EXIT PROGRAM
ELSE
	CALL setea_nombre_botones_f1()
	-- Tabla temporal para la ordenaci�n
	CREATE TEMP TABLE tmp_detalle(
		proveedor	INTEGER  NOT NULL,
		tipo_doc	CHAR(2)  NOT NULL,
		num_doc		CHAR(15) NOT NULL,
		dividendo	SMALLINT NOT NULL,
		fecha_vcto	DATE,
		saldo		DECIMAL(12,2),
		valor_pagar	DECIMAL(12,2),
		tmp_check	CHAR(1),
		valor_bienes	DECIMAL(12,2),
		valor_servi	DECIMAL(12,2)
	)
	CREATE UNIQUE INDEX tmp_pk1
		ON tmp_detalle(proveedor, tipo_doc, num_doc, dividendo)

	CREATE TEMP TABLE tmp_retenciones(
		proveedor	INTEGER      NOT NULL,
		tipo_doc	CHAR(2)      NOT NULL,
		num_doc		CHAR(15)     NOT NULL,
		dividendo	SMALLINT     NOT NULL,
		codigo_sri	CHAR(3)		 NOT NULL,
		tipo_ret	CHAR(1)      NOT NULL,
		porc		DECIMAL(5,2) NOT NULL,
		val_base	DECIMAL(12,2),
		subtotal 	DECIMAL(12,2)
	)
	CREATE UNIQUE INDEX tmp_pk2
		ON tmp_retenciones(proveedor, tipo_doc, num_doc, dividendo, 
				   codigo_sri, tipo_ret, porc)

	FOR i = 1 TO 10
        	LET rm_orden[i] = 'ASC'
	END FOR
END IF	

MENU 'OPCIONES'
	COMMAND KEY('I') 'Ingresar' 		'Ingresar nuevos registros.'
		IF vm_num_rows = vm_max_rows THEN
			CALL fl_mensaje_arreglo_lleno()
		ELSE
			CALL control_ingreso()
		END IF
		CALL setea_nombre_botones_f1()
--	COMMAND KEY('C') 'Consultar' 		'Consultar un registro.'
--		CALL control_consulta()
--		IF vm_num_rows <= 1 THEN
--			SHOW OPTION 'Detalle'
--			IF vm_num_rows = 0 THEN
--				HIDE OPTION 'Detalle'
--			END IF
--		ELSE
--			SHOW OPTION 'Detalle'
--		END IF
--		CALL setea_nombre_botones_f1()
	COMMAND KEY('S') 'Salir'    		'Salir del programa.'
		EXIT MENU
END MENU


END FUNCTION


{
FUNCTION control_modificacion()

IF vm_num_rows = 0 THEN   
	CALL fl_mensaje_consultar_primero()
	RETURN
END IF

CALL lee_muestra_registro(vm_rows[vm_row_current])

WHENEVER ERROR CONTINUE
BEGIN WORK
DECLARE q_upd CURSOR FOR 
	SELECT * FROM cxpt022 WHERE ROWID = vm_rows[vm_row_current]
	FOR UPDATE
OPEN q_upd
FETCH q_upd INTO rm_v22.*
WHENEVER ERROR STOP
IF STATUS < 0 THEN
	CALL fl_mensaje_bloqueo_otro_usuario()
	ROLLBACK WORK
	RETURN
END IF  

CALL lee_datos('M')

IF INT_FLAG THEN
	ROLLBACK WORK
	CALL lee_muestra_registro(vm_rows[vm_row_current])
	CLOSE q_upd
	RETURN
END IF 

UPDATE cxpt022 SET * = rm_v22.* WHERE CURRENT OF q_upd
COMMIT WORK
CLOSE q_upd
CALL fl_mensaje_registro_modificado()

END FUNCTION
}


FUNCTION control_ingreso()

INITIALIZE rm_p24.* TO NULL
CLEAR FORM
CALL setea_nombre_botones_f1()

LET rm_p24.p24_compania   = vg_codcia
LET rm_p24.p24_localidad  = vg_codloc
LET rm_p24.p24_tipo       = 'P'
LET rm_p24.p24_estado     = 'A'
LET rm_p24.p24_tasa_mora  = 0
LET rm_p24.p24_total_mora = 0
LET rm_p24.p24_medio_pago = 'C'

LET rm_p24.p24_usuario    = vg_usuario
LET rm_p24.p24_fecing     = CURRENT

CALL lee_datos()
IF INT_FLAG THEN
	CLEAR FORM
	RETURN
END IF

IF vm_num_rows = 0 THEN
	CLEAR FORM
	RETURN
END IF

CALL ingresa_detalles()
IF INT_FLAG THEN
	CLEAR FORM
	RETURN
END IF

CALL graba_autorizacion()
IF INT_FLAG THEN
	CLEAR FORM
	RETURN
END IF

CALL fl_mensaje_registro_ingresado()
CLEAR FORM

END FUNCTION



FUNCTION lee_datos()

DEFINE expr_sql			VARCHAR(255)
DEFINE query			VARCHAR(600)

DISPLAY BY NAME rm_p24.p24_usuario, rm_p24.p24_fecing

LET expr_sql = criterios()
IF expr_sql IS NULL OR INT_FLAG THEN
	CLEAR FORM
	RETURN
END IF

LET rm_p24.p24_paridad = calcula_paridad(rm_p24.p24_moneda, 
					 rg_gen.g00_moneda_base)

DISPLAY BY NAME rm_p24.p24_moneda, rm_p24.p24_banco,
		rm_p24.p24_numero_cta
CALL muestra_etiquetas()

DELETE FROM tmp_detalle

LET query = 'INSERT INTO tmp_detalle ',
	    '	SELECT p20_codprov, p20_tipo_doc, p20_num_doc, ',
	    '	       p20_dividendo, p20_fecha_vcto, ',
	    '          (p20_saldo_cap + p20_saldo_int), 0, "N", 0, 0 ',
	    '	FROM cxpt020 ',
	    '	WHERE p20_compania  = ', vg_codcia,
	    '	  AND p20_localidad = ', vg_codloc,
	    expr_sql CLIPPED,
	    '     AND p20_moneda    = "', rm_p24.p24_moneda, '"',
	    '	  AND p20_saldo_cap + p20_saldo_int > 0 '

PREPARE statement1 FROM query
EXECUTE statement1

SELECT COUNT(*) INTO vm_num_rows FROM tmp_detalle

IF vm_num_rows = 0 THEN 
	CALL fl_mensaje_consulta_sin_registros()
	LET vm_num_rows = 0
	LET vm_row_current = 0
	CLEAR FORM
	RETURN
END IF
LET vm_row_current = 1

END FUNCTION



FUNCTION ingresa_detalles()

DEFINE flag		CHAR(1)
DEFINE resp 		CHAR(6)
DEFINE i    		SMALLINT
DEFINE j    		SMALLINT
DEFINE k    		SMALLINT
DEFINE salir		SMALLINT
DEFINE c		CHAR(1)

DEFINE col              SMALLINT
DEFINE query            VARCHAR(500)

LET vm_columna_1 = 5
LET vm_columna_2 = 6
LET rm_orden[vm_columna_1]  = 'ASC'
LET rm_orden[vm_columna_2]  = 'DESC'
INITIALIZE col TO NULL

LET salir = 0
WHILE NOT salir
        LET query = 'SELECT * FROM tmp_detalle ',
                    'ORDER BY ', vm_columna_1, ' ', rm_orden[vm_columna_1],
                           ', ', vm_columna_2, ' ', rm_orden[vm_columna_2]

        PREPARE deto FROM query
        DECLARE q_deto CURSOR FOR deto 
        LET i = 1
        FOREACH q_deto INTO rm_docs[i].*
                LET i = i + 1
                IF i > vm_max_rows THEN
                	CALL fl_mensaje_arreglo_incompleto()
                	LET INT_FLAG = 1
                	RETURN
                END IF
        END FOREACH

	LET i = 1
	LET j = 1
	LET INT_FLAG = 0
	CALL set_count(vm_num_rows)
	DISPLAY ARRAY rm_docs TO ra_docs.*
		ON KEY(INTERRUPT)
			LET INT_FLAG = 0
			CALL fl_mensaje_abandonar_proceso() RETURNING resp
			IF resp = 'Yes' THEN
				LET INT_FLAG = 1
				EXIT DISPLAY
			END IF
		ON KEY(F5)
			LET rm_docs[i].valor_pagar = pagar(i)
			LET INT_FLAG = 0

			IF rm_docs[i].valor_pagar = 0 THEN
				LET rm_docs[i].check = 'N'
				CALL elimina_retenciones(i)
			ELSE
				LET rm_docs[i].check = 'S'
			END IF

			DISPLAY rm_docs[i].* TO ra_docs[j].*
  			CALL graba_valores(i)
      			CALL calcula_totales()
     			LET INT_FLAG = 0
      		ON KEY(F6)
     			CALL muestra_totales()
     			LET INT_FLAG = 0
     		ON KEY(F7)
     			CALL ver_estado_cuenta(arr_curr())
     			LET INT_FLAG = 0
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
                ON KEY(F21)
                        LET col = 7
			EXIT DISPLAY
		BEFORE DISPLAY
			CALL setea_nombre_botones_f1()
			CALL calcula_totales()
		BEFORE ROW
			LET i = arr_curr()
			LET j = scr_line()
			CALL etiquetas_proveedor(rm_docs[i].proveedor,
						 rm_docs[i].fecha_vcto)
		AFTER DISPLAY
			LET salir = 1
	END DISPLAY
	IF INT_FLAG THEN
		RETURN
	END IF

	IF col IS NOT NULL AND NOT salir THEN
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
		INITIALIZE col TO NULL
	END IF

END WHILE

END FUNCTION



FUNCTION graba_valores(i)

DEFINE i 		SMALLINT

UPDATE tmp_detalle SET 
	tmp_check   = rm_docs[i].check,
	valor_pagar = rm_docs[i].valor_pagar
	WHERE proveedor = rm_docs[i].proveedor
	  AND tipo_doc  = rm_docs[i].tipo_doc
	  AND num_doc   = rm_docs[i].num_doc
	  AND dividendo = rm_docs[i].dividendo                 

END FUNCTION



FUNCTION elimina_retenciones(i)

DEFINE i		SMALLINT

DELETE FROM tmp_retenciones
	WHERE proveedor = rm_docs[i].proveedor
	  AND tipo_doc  = rm_docs[i].tipo_doc
	  AND num_doc   = rm_docs[i].num_doc
	  AND dividendo = rm_docs[i].dividendo
		  
END FUNCTION



FUNCTION pagar(i)

DEFINE i		SMALLINT
DEFINE j		SMALLINT
DEFINE resp		CHAR(6)
DEFINE retenciones	SMALLINT
DEFINE salir		SMALLINT
DEFINE filas_pant	SMALLINT

DEFINE val_bienes	DECIMAL(12,2)
DEFINE val_servi	DECIMAL(12,2)
DEFINE val_impto	DECIMAL(12,2)
DEFINE val_neto		DECIMAL(12,2)
DEFINE val_pagar	DECIMAL(12,2)
DEFINE tot_ret  	DECIMAL(12,2)
DEFINE val_cheque	DECIMAL(12,2)

DEFINE r_c01		RECORD LIKE ordt001.*
DEFINE r_c02		RECORD LIKE ordt002.*
DEFINE r_c10		RECORD LIKE ordt010.*
DEFINE r_p01		RECORD LIKE cxpt001.*
DEFINE r_p05		RECORD LIKE cxpt005.*
DEFINE r_p20		RECORD LIKE cxpt020.*

DEFINE r_reten		RECORD
	proveedor	INTEGER,
	tipo_doc	CHAR(2),
	num_doc		CHAR(15),
	dividendo	SMALLINT,
	codigo_sri	CHAR(3),
	tipo_ret	CHAR(1), 
	porc		DECIMAL(5,2),
	val_base	DECIMAL(12,2),
	subtotal 	DECIMAL(12,2)
END RECORD

CALL fl_lee_proveedor(rm_docs[i].proveedor)	RETURNING r_p01.*

CALL fl_mensaje_proveedor_documentos_favor(vg_codcia, vg_codloc,
										  rm_docs[i].proveedor)

OPEN WINDOW w_204_3 AT 4,9 WITH 21 ROWS, 70 COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, BORDER)
OPEN FORM f_204_3 FROM '../forms/cxpf204_3'
DISPLAY FORM f_204_3

CALL setea_nombre_botones_f3()

DISPLAY r_p01.p01_codprov 	TO cod_proveedor
DISPLAY r_p01.p01_nomprov	TO n_proveedor
DISPLAY BY NAME rm_docs[i].tipo_doc, rm_docs[i].num_doc, rm_docs[i].dividendo

CALL fl_lee_documento_deudor_cxp(vg_codcia, vg_codloc, rm_docs[i].proveedor,
				 rm_docs[i].tipo_doc, rm_docs[i].num_doc,
				 rm_docs[i].dividendo) RETURNING r_p20.*

LET val_impto  = r_p20.p20_valor_impto
LET val_neto   = r_p20.p20_valor_fact

DISPLAY BY NAME val_impto, val_neto

LET tot_ret    = 0

LET ind_ret = 0

IF rm_docs[i].valor_pagar = 0 THEN
	LET val_bienes = val_neto - val_impto
	LET val_servi  = 0
	IF r_p20.p20_numero_oc IS NOT NULL THEN
		CALL fl_lee_orden_compra(vg_codcia, vg_codloc, 
			r_p20.p20_numero_oc) RETURNING r_c10.*
		CALL fl_lee_tipo_orden_compra(r_c10.c10_tipo_orden) 
			RETURNING r_c01.*
	
		IF r_c01.c01_bien_serv = 'S' THEN
			LET val_servi  = val_neto - val_impto
			LET val_bienes = 0
		END IF
	END IF
	
	INPUT BY NAME val_bienes, val_servi, val_impto, val_neto 
		WITHOUT DEFAULTS
		ON KEY (INTERRUPT)
			IF NOT FIELD_TOUCHED(val_bienes, val_servi) THEN
				EXIT INPUT
			END IF

			LET INT_FLAG = 0
			CALL fl_mensaje_abandonar_proceso() RETURNING resp
			IF resp = 'Yes' THEN
				LET INT_FLAG = 1
				EXIT INPUT
			END IF
		AFTER FIELD val_bienes
			IF val_bienes IS NULL THEN
				LET val_bienes = 0
			END IF
			IF val_bienes > val_neto THEN
				CALL fgl_winmessage(vg_producto,
					'Debe ingresar un valor menor ' ||
					'valor neto.',
					'exclamation')
				NEXT FIELD val_bienes
			END IF
			LET val_servi = val_neto - val_impto - val_bienes
			DISPLAY BY NAME val_bienes, val_servi
		AFTER FIELD val_servi
			IF val_servi IS NULL THEN
				LET val_servi = 0
			END IF
			IF val_servi > val_neto THEN
				CALL fgl_winmessage(vg_producto,
					'Debe ingresar un valor menor ' ||
					'valor neto.',
					'exclamation')
				NEXT FIELD val_servi
			END IF			
			LET val_bienes = val_neto - val_impto - val_servi
			DISPLAY BY NAME val_bienes, val_servi
		AFTER INPUT
			IF (val_bienes + val_servi) <> (val_neto - val_impto) 
			THEN
				CALL fgl_winmessage(vg_producto,
					'Total neto menos iva debe ser ' ||
					'igual al valor bienes mas valor ' ||
					'servicios.',
					'exclamation')
				CONTINUE INPUT
			END IF
	END INPUT
	IF INT_FLAG THEN
		CLOSE WINDOW w_204_3
		RETURN rm_docs[i].valor_pagar
	END IF

	LET val_pagar  = rm_docs[i].saldo
	LET val_cheque = val_pagar
ELSE
	SELECT valor_bienes, valor_servi INTO val_bienes, val_servi
		FROM tmp_detalle
		WHERE proveedor = rm_docs[i].proveedor
	  	AND tipo_doc    = rm_docs[i].tipo_doc
	  	AND num_doc     = rm_docs[i].num_doc
	  	AND dividendo   = rm_docs[i].dividendo

	DISPLAY BY NAME val_bienes, val_servi	  

	LET val_pagar = rm_docs[i].valor_pagar
	
	-- Verifica si se han hecho retenciones sobre este documento,
	-- y si se han hecho si no se han eliminado
	SELECT COUNT(p28_secuencia) INTO j
		FROM cxpt028, cxpt027
		WHERE p28_compania  = vg_codcia
	  	  AND p28_localidad = vg_codloc
	  	  AND p28_codprov   = rm_docs[i].proveedor
	  	  AND p28_tipo_doc  = rm_docs[i].tipo_doc
	  	  AND p28_num_doc   = rm_docs[i].num_doc
	  	  AND p27_compania  = p28_compania
	  	  AND p27_localidad = p28_localidad
	  	  AND p27_num_ret   = p28_num_ret
	  	  AND p27_estado    = 'A'
	  
	SELECT COUNT(*) INTO retenciones
		FROM tmp_retenciones
		WHERE proveedor =  rm_docs[i].proveedor
	  	  AND tipo_doc  =  rm_docs[i].tipo_doc
	  	  AND num_doc   =  rm_docs[i].num_doc
	  	  AND dividendo <> rm_docs[i].dividendo
	  
	LET retenciones = retenciones + j

	IF retenciones = 0 THEN
		DECLARE q_ret2 CURSOR FOR
			SELECT * FROM ordt002, OUTER tmp_retenciones
				WHERE c02_compania = vg_codcia
	  	  		  AND proveedor    = rm_docs[i].proveedor
	  	  	  	  AND tipo_doc     = rm_docs[i].tipo_doc
	  	  		  AND num_doc      = rm_docs[i].num_doc
	  	  		  AND dividendo    = rm_docs[i].dividendo
				  AND codigo_sri   = c02_codigo_sri
	  	  		  AND tipo_ret     = c02_tipo_ret
	  	  		  AND porc         = c02_porcentaje

		LET filas_pant = fgl_scr_size('ra_ret')
		FOR j = 1 TO filas_pant
			CLEAR ra_ret[j].*
		END FOR

		LET j = 1
		FOREACH q_ret2 INTO r_c02.*, r_reten.*
			IF r_c02.c02_tipo_ret = 'F' 
			AND r_p01.p01_ret_fuente = 'N' 
			THEN
				CONTINUE FOREACH
			END IF
			IF r_c02.c02_tipo_ret = 'I' 
			AND r_p01.p01_ret_impto = 'N' 
			THEN
				CONTINUE FOREACH
			END IF
			LET r_ret[j].check    = 'N'
			LET r_ret[j].n_retencion = r_c02.c02_nombre
			LET r_ret[j].codigo_sri  = r_c02.c02_codigo_sri
			LET r_ret[j].tipo_ret    = r_c02.c02_tipo_ret
			LET r_ret[j].porc        = r_c02.c02_porcentaje
			LET r_ret[j].val_base    = 0
			LET r_ret[j].subtotal    = 0
			IF r_reten.subtotal IS NOT NULL THEN
				LET r_ret[j].check    = 'S'
				LET r_ret[j].val_base = r_reten.val_base
				LET r_ret[j].subtotal = r_reten.subtotal
				LET tot_ret = tot_ret + r_reten.subtotal
			END IF
			IF j <= filas_pant THEN
				DISPLAY r_ret[j].* TO ra_ret[j].*
			END IF
	
			LET j = j + 1
			IF j > ind_max_ret THEN
				EXIT FOREACH
			END IF
		END FOREACH
		LET ind_ret = j - 1	
	END IF
	LET val_cheque = val_pagar - tot_ret
END IF

LET salir = 0

WHILE NOT salir

LET INT_FLAG = 0

OPTIONS INPUT NO WRAP
INPUT BY NAME val_pagar, tot_ret, val_cheque WITHOUT DEFAULTS
	ON KEY (INTERRUPT)
		IF NOT FIELD_TOUCHED(val_pagar) THEN
			EXIT INPUT
		END IF

		LET INT_FLAG = 0
		CALL fl_mensaje_abandonar_proceso() RETURNING resp
		IF resp = 'Yes' THEN
			LET INT_FLAG = 1
			EXIT INPUT
		END IF
	AFTER FIELD val_pagar
		IF val_pagar IS NULL THEN
			LET val_pagar = 0
			DISPLAY BY NAME val_pagar
		END IF
		IF val_pagar > rm_docs[i].saldo THEN
			CALL fgl_winmessage(vg_producto,
				'Valor a pagar debe ser menor o ' ||
				'igual al saldo del documento.',
				'exclamation')
			LET val_pagar = rm_docs[i].saldo
			NEXT FIELD val_pagar
		END IF
		LET val_cheque = val_pagar - tot_ret
		DISPLAY BY NAME val_cheque
	AFTER INPUT 
		LET salir = 1
END INPUT
IF INT_FLAG THEN
	CLOSE WINDOW w_204_3
	RETURN rm_docs[i].valor_pagar
END IF

IF val_pagar = 0 THEN
	CALL fgl_winquestion(vg_producto,
		'Si deja en cero el valor a pagar no se grabar� esta ' ||
		'autorizaci�n.', 'Cancel', 'Ok|Cancel', 'question', 1)
		RETURNING resp
	IF resp = 'Ok' THEN
		CLOSE WINDOW w_204_3
		RETURN 0
	ELSE
		LET salir = 0
		CONTINUE WHILE
	END IF
END IF

IF ind_ret = 0 THEN
	-- Verifica si se han hecho retenciones sobre este documento,
	-- y si se han hecho si no se han eliminado
	SELECT COUNT(p28_secuencia) INTO j
		FROM cxpt028, cxpt027
		WHERE p28_compania  = vg_codcia
	  	  AND p28_localidad = vg_codloc
	   	  AND p28_codprov   = rm_docs[i].proveedor
	  	  AND p28_tipo_doc  = rm_docs[i].tipo_doc
	  	  AND p28_num_doc   = rm_docs[i].num_doc
	  	  AND p27_compania  = p28_compania
	  	  AND p27_localidad = p28_localidad
	  	  AND p27_num_ret   = p28_num_ret
	  	  AND p27_estado    = 'A'
	  
	SELECT COUNT(*) INTO retenciones
		FROM tmp_retenciones
		WHERE proveedor = rm_docs[i].proveedor
	  	  AND tipo_doc  = rm_docs[i].tipo_doc
	  	  AND num_doc   = rm_docs[i].num_doc
	  
	LET retenciones = retenciones + j

	IF retenciones = 0 THEN
		DECLARE q_ret CURSOR FOR
			SELECT * FROM ordt002, OUTER cxpt005
				WHERE c02_compania   = vg_codcia
			  	  AND p05_compania   = c02_compania
			  	  AND p05_codprov    = rm_docs[i].proveedor
				  AND p05_codigo_sri = c02_codigo_sri
		  		  AND p05_tipo_ret   = c02_tipo_ret
			  	  AND p05_porcentaje = c02_porcentaje 

		LET j = 1
		FOREACH q_ret INTO r_c02.*, r_p05.*
			IF r_c02.c02_tipo_ret = 'F' 
			AND r_p01.p01_ret_fuente = 'N' 
			THEN
				CONTINUE FOREACH
			END IF
			IF r_c02.c02_tipo_ret = 'I' 
			AND r_p01.p01_ret_impto = 'N' 
			THEN
				CONTINUE FOREACH
			END IF
			LET r_ret[j].n_retencion = r_c02.c02_nombre
			LET r_ret[j].codigo_sri  = r_c02.c02_codigo_sri
			LET r_ret[j].tipo_ret    = r_c02.c02_tipo_ret
			LET r_ret[j].porc        = r_c02.c02_porcentaje
			LET r_ret[j].val_base    = 0
			LET r_ret[j].subtotal    = 0 
			LET r_ret[j].check    = 'N'
			IF r_p05.p05_tipo_ret IS NOT NULL THEN
				LET r_ret[j].check = 'S'
				IF r_p05.p05_tipo_ret = 'I' THEN
					LET r_ret[j].val_base = val_impto
				ELSE
					CASE r_c02.c02_tipo_fuente
						WHEN 'B'
						LET r_ret[j].val_base = 
							val_bienes
						WHEN 'S'
						LET r_ret[j].val_base = 
							val_servi
						WHEN 'T'
						LET r_ret[j].val_base = 
							val_servi + val_bienes
					END CASE
				END IF
				LET r_ret[j].subtotal = 
					(r_ret[j].val_base * 
					(r_p05.p05_porcentaje / 100))
				LET tot_ret = tot_ret + r_ret[j].subtotal
				LET val_cheque = val_cheque - r_ret[j].subtotal
			END IF
			LET j = j + 1
			IF j > ind_max_ret THEN
				EXIT FOREACH
			END IF
		END FOREACH
		LET j = j - 1

		LET ind_ret = j

		DISPLAY BY NAME tot_ret, val_cheque
	ELSE
		IF ind_ret = 0 THEN
			CALL fgl_winmessage(vg_producto,
				'Ya se hizo la retenci�n sobre este ' ||
				'documento.',
				'exclamation')
			LET salir = 1
		END IF
	END IF
END IF

IF ind_ret > 0 THEN
	CALL muestra_retenciones(val_bienes, val_servi, val_impto, val_neto,
		val_pagar, tot_ret, val_cheque) RETURNING tot_ret, val_cheque
	IF INT_FLAG =1 THEN
		CLOSE WINDOW w_204_3
		RETURN rm_docs[i].valor_pagar
	END IF
	IF INT_FLAG = 2 THEN
		CONTINUE WHILE
	END IF
	
	CALL elimina_retenciones(i)
		  
	LET salir = 1
	FOR j = 1 TO ind_ret
		IF r_ret[j].check = 'S'  THEN 
			INSERT INTO tmp_retenciones 
				VALUES(rm_docs[i].proveedor, 
				       rm_docs[i].tipo_doc,
			               rm_docs[i].num_doc,   
			               rm_docs[i].dividendo,
						   r_ret[j].codigo_sri,
			       	       r_ret[j].tipo_ret,    
			       	       r_ret[j].porc,
			       	       r_ret[j].val_base,    
			       	       r_ret[j].subtotal)
		END IF
	END FOR
	
	LET INT_FLAG = INT_FLAG
	
	UPDATE tmp_detalle SET
		valor_bienes = val_bienes,
		valor_servi  = val_servi
		WHERE proveedor = rm_docs[i].proveedor
		  AND tipo_doc  = rm_docs[i].tipo_doc
		  AND num_doc   = rm_docs[i].num_doc
		  AND dividendo = rm_docs[i].dividendo
END IF

END WHILE

CLOSE WINDOW w_204_3

RETURN val_pagar

END FUNCTION



FUNCTION muestra_retenciones(val_bienes, val_servi, val_impto, val_neto, 
			     val_pagar, tot_ret, val_cheque)

DEFINE resp		CHAR(6)
DEFINE c		CHAR(1)
DEFINE salir		SMALLINT
DEFINE i		SMALLINT
DEFINE j		SMALLINT

DEFINE iva 		SMALLINT

DEFINE val_bienes	DECIMAL(12,2)
DEFINE val_servi	DECIMAL(12,2)
DEFINE val_impto	DECIMAL(12,2)
DEFINE val_neto		DECIMAL(12,2)
DEFINE val_pagar	DECIMAL(12,2)
DEFINE tot_ret  	DECIMAL(12,2)
DEFINE val_cheque	DECIMAL(12,2)

DEFINE r_c02		RECORD LIKE ordt002.*
DEFINE r_c10		RECORD LIKE ordt010.*
DEFINE r_p01		RECORD LIKE cxpt001.*

OPTIONS 
	INPUT WRAP,
	INSERT KEY F40,
	DELETE KEY F41

LET salir = 0
WHILE NOT salir
LET i = 1
LET j = 1
CALL set_count(ind_ret)
INPUT ARRAY r_ret WITHOUT DEFAULTS FROM ra_ret.*
	ON KEY(INTERRUPT)
		LET INT_FLAG = 0
		CALL fl_mensaje_abandonar_proceso() RETURNING resp
		IF resp = 'Yes' THEN
			LET INT_FLAG = 1
			EXIT INPUT
		END IF
	ON KEY(F5)
		LET INT_FLAG = 2
		EXIT INPUT
	BEFORE INPUT
		CALL dialog.keysetlabel('INSERT', '')
		CALL dialog.keysetlabel('DELETE', '')
		CALL setea_nombre_botones_f3()
	BEFORE ROW
		LET i = arr_curr()
		LET j = scr_line()
	BEFORE INSERT
		EXIT INPUT
	BEFORE DELETE
		EXIT INPUT
	BEFORE FIELD check
		LET c = r_ret[i].check
	AFTER  FIELD check
		IF c <> r_ret[i].check THEN
			IF r_ret[i].check = 'S' THEN
				CALL fl_lee_tipo_retencion(vg_codcia, r_ret[i].codigo_sri, 
					r_ret[i].tipo_ret, r_ret[i].porc)
					RETURNING r_c02.*
				IF r_ret[i].tipo_ret = 'I' THEN
					LET r_ret[i].val_base = val_impto
				ELSE
					CASE r_c02.c02_tipo_fuente
					WHEN 'B'
						LET r_ret[i].val_base = 
							val_bienes
					WHEN 'S'
						LET r_ret[i].val_base = 
							val_servi
					WHEN 'T'
						LET r_ret[i].val_base = 
							val_servi + val_bienes
					END CASE
				END IF
				LET r_ret[i].subtotal = 
					(r_ret[i].val_base * 
					(r_ret[i].porc / 100))	
				LET val_cheque = val_cheque - r_ret[i].subtotal
				LET tot_ret = tot_ret + r_ret[i].subtotal
			END IF
			IF r_ret[i].check = 'N' THEN
				LET val_cheque = 
					val_cheque + r_ret[i].subtotal
				LET tot_ret = tot_ret - r_ret[i].subtotal
				LET r_ret[i].val_base = 0
				LET r_ret[i].subtotal = 0
			END IF
			DISPLAY r_ret[i].* TO ra_ret[j].*
			DISPLAY BY NAME val_cheque, tot_ret
			NEXT FIELD ra_ret[j-1].check
		END IF
	AFTER INPUT 
		IF tot_ret > val_neto THEN
			CALL fgl_winmessage(vg_producto,
				'El valor de las retenciones no debe ser ' ||
				'mayor al valor neto.',
				'exclamation')
			CONTINUE INPUT
		END IF
		LET iva = 0
		FOR i = 1 TO ind_ret 
			IF r_ret[i].check = 'S' AND r_ret[i].tipo_ret = 'I'
			THEN
				LET iva = iva + r_ret[i].porc
			END IF
		END FOR
		IF iva > 100 THEN
			CALL fgl_winmessage(vg_producto, 
				'Las retenciones sobre el iva no pueden ' ||
				'exceder al 100% del iva.',
				'exclamation')
			CONTINUE INPUT
		END IF
		LET salir = 1
END INPUT
IF INT_FLAG = 2 THEN
	RETURN tot_ret, val_cheque
END IF
IF INT_FLAG = 1 THEN
	RETURN 0, 0
END IF

END WHILE

RETURN tot_ret, val_cheque

END FUNCTION



FUNCTION lee_muestra_registro(row)
DEFINE row 		INTEGER


IF vm_num_rows <= 0 THEN
	RETURN
END IF

SELECT * INTO rm_p24.* FROM cxpt024 WHERE ROWID = row
IF STATUS = NOTFOUND THEN
	ERROR 'No existe registro con rowid', row
END IF

DISPLAY BY NAME rm_p24.p24_orden_pago,
		rm_p24.p24_banco,
		rm_p24.p24_numero_cta,
		rm_p24.p24_codprov,
		rm_p24.p24_estado,
		rm_p24.p24_moneda,
		rm_p24.p24_paridad,
		rm_p24.p24_referencia,
		rm_p24.p24_numero_che,
		rm_p24.p24_total_che,
		rm_p24.p24_usuario,
		rm_p24.p24_fecing
DISPLAY (rm_p24.p24_total_int + rm_p24.p24_total_cap) TO tot_val_pagar

CALL muestra_etiquetas_f4()
CALL muestra_contadores_f4()
CALL muestra_detalle_f4()

END FUNCTION


{
FUNCTION siguiente_registro()

IF vm_num_rows = 0 THEN
	RETURN
END IF

IF vm_row_current < vm_num_rows THEN
	LET vm_row_current = vm_row_current + 1
END IF
CALL lee_muestra_registro(vm_rows[vm_row_current])

END FUNCTION



FUNCTION anterior_registro()

IF vm_num_rows = 0 THEN
	RETURN
END IF

IF vm_row_current > 1 THEN
	LET vm_row_current = vm_row_current - 1
END IF
CALL lee_muestra_registro(vm_rows[vm_row_current])

END FUNCTION
}


FUNCTION muestra_etiquetas_f4()

DEFINE r_p01		RECORD LIKE cxpt001.*
DEFINE r_g13		RECORD LIKE gent013.*
DEFINE r_g08		RECORD LIKE gent008.*

DEFINE nom_estado		CHAR(9)

CASE rm_p24.p24_estado
	WHEN 'A' LET nom_estado = 'ACTIVO'
	WHEN 'P' LET nom_estado = 'PROCESADO'
END CASE

CALL fl_lee_banco_general(rm_p24.p24_banco) 	RETURNING r_g08.*
CALL fl_lee_proveedor(rm_p24.p24_codprov) RETURNING r_p01.*
CALL fl_lee_moneda(rm_p24.p24_moneda) RETURNING r_g13.*

DISPLAY nom_estado        TO n_estado
DISPLAY r_p01.p01_nomprov TO n_proveedor
DISPLAY r_g13.g13_nombre  TO n_moneda
DISPLAY r_g08.g08_nombre  TO n_banco 

END FUNCTION



FUNCTION muestra_contadores_f4()

DISPLAY "" AT 1,1
DISPLAY vm_row_current, " de ", vm_num_rows AT 1, 68 

END FUNCTION



FUNCTION setea_nombre_botones_f3()

DISPLAY 'Descripci�n' TO bt_nom_ret
DISPLAY 'Cod'		  TO bt_codigo_sri
DISPLAY 'Tipo R.'     TO bt_tipo_ret
DISPLAY 'Valor Base'  TO bt_base 
DISPLAY '%'           TO bt_porc
DISPLAY 'Subtotal'    TO bt_valor

END FUNCTION



FUNCTION muestra_etiquetas()

DEFINE r_g08		RECORD LIKE gent008.*
DEFINE r_g13		RECORD LIKE gent013.*

CALL fl_lee_moneda(rm_p24.p24_moneda)       RETURNING r_g13.*
CALL fl_lee_banco_general(rm_p24.p24_banco) RETURNING r_g08.*

DISPLAY r_g08.g08_nombre	TO 	n_banco
DISPLAY r_g13.g13_nombre	TO	n_moneda

END FUNCTION



FUNCTION etiquetas_proveedor(proveedor, fecha_vcto)

DEFINE dias		SMALLINT
DEFINE proveedor	LIKE cxpt001.p01_codprov
DEFINE fecha_vcto	LIKE cxpt020.p20_fecha_vcto

DEFINE r_p01		RECORD LIKE cxpt001.*

CALL fl_lee_proveedor(proveedor) 	     RETURNING r_p01.*

DISPLAY r_p01.p01_nomprov 	TO 	n_proveedor

IF fecha_vcto >= TODAY THEN
	DISPLAY 'Por vencer' TO n_estado_vcto
ELSE
	DISPLAY 'Vencido' TO n_estado_vcto
END IF
LET dias = fecha_vcto - TODAY
DISPLAY BY NAME dias

END FUNCTION



FUNCTION setea_nombre_botones_f1()

DISPLAY 'Prov'          TO bt_proveedor
DISPLAY 'Tp'            TO bt_tipo_doc
DISPLAY 'N�mero'        TO bt_num_doc
DISPLAY '#'             TO bt_dividendo
DISPLAY 'Fecha Vcto'    TO bt_fecha
DISPLAY 'Saldo'         TO bt_saldo
DISPLAY 'Valor a Pagar' TO bt_valor

END FUNCTION



FUNCTION criterios()

DEFINE tipo_vcto	CHAR(1)
DEFINE resp		CHAR(6)
DEFINE condicion	VARCHAR(255)

DEFINE banco 		LIKE gent008.g08_banco
DEFINE dummy		LIKE gent008.g08_nombre
DEFINE nro_cta		LIKE gent009.g09_numero_cta
DEFINE proveedor	LIKE cxpt001.p01_codprov

DEFINE r_g08		RECORD LIKE gent008.*
DEFINE r_g09		RECORD LIKE gent009.*
DEFINE r_g13		RECORD LIKE gent013.*
DEFINE r_p01		RECORD LIKE cxpt001.*

INITIALIZE banco     TO NULL
INITIALIZE proveedor TO NULL
INITIALIZE r_g08.*   TO NULL
INITIALIZE r_g09.*   TO NULL
INITIALIZE r_g13.*   TO NULL
INITIALIZE r_p01.*   TO NULL

INITIALIZE condicion TO NULL

LET tipo_vcto = 'V'		-- Default value: 'V' (Vencidos)

OPEN WINDOW w_204_2 AT 7,9 WITH 11 ROWS, 64 COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, BORDER)
OPEN FORM f_204_2 FROM '../forms/cxpf204_2'
DISPLAY FORM f_204_2

LET INT_FLAG = 0
INPUT BY NAME banco, r_g09.g09_numero_cta, proveedor, tipo_vcto 
	      WITHOUT DEFAULTS
	ON KEY (INTERRUPT)
		IF NOT FIELD_TOUCHED(banco, g09_numero_cta, p01_codprov) THEN
			EXIT INPUT
		END IF

		LET INT_FLAG = 0
		CALL fl_mensaje_abandonar_proceso() RETURNING resp
		IF resp = 'Yes' THEN
			LET INT_FLAG = 1
			EXIT INPUT
		END IF
	ON KEY(F2)
		IF INFIELD(banco) THEN
			CALL fl_ayuda_bancos() RETURNING r_g08.g08_banco,
							 r_g08.g08_nombre
			IF r_g08.g08_banco IS NOT NULL THEN
				LET banco = r_g08.g08_banco
				DISPLAY BY NAME banco, r_g08.g08_nombre
			END IF
		END IF
		IF INFIELD(g09_numero_cta) THEN
			CALL fl_ayuda_cuenta_banco(vg_codcia) 
				RETURNING r_g09.g09_banco, dummy, 
				          r_g09.g09_tipo_cta, 
				          r_g09.g09_numero_cta 
			IF r_g09.g09_numero_cta IS NOT NULL THEN
				LET banco = r_g09.g09_banco
				LET r_g08.g08_nombre = dummy
				DISPLAY BY NAME banco, r_g08.g08_nombre,
					        r_g09.g09_numero_cta
			END IF	
		END IF
		IF INFIELD(proveedor) THEN
			CALL fl_ayuda_proveedores() RETURNING r_p01.p01_codprov,
							      r_p01.p01_nomprov
			IF r_p01.p01_codprov IS NOT NULL THEN
				LET proveedor = r_p01.p01_codprov
				DISPLAY BY NAME proveedor, r_p01.p01_nomprov
			END IF
		END IF
		LET INT_FLAG = 0
	AFTER FIELD banco
		IF banco IS NULL THEN
			INITIALIZE r_g08.* TO NULL
			INITIALIZE r_g09.* TO NULL
			INITIALIZE r_g13.* TO NULL
			DISPLAY BY NAME r_g08.g08_nombre, r_g09.g09_numero_cta,
					r_g13.g13_moneda, r_g13.g13_nombre
		ELSE
			CALL fl_lee_banco_general(banco) 
				RETURNING r_g08.*
			IF r_g08.g08_banco IS NULL THEN	
				INITIALIZE r_g08.g08_nombre TO NULL
				DISPLAY BY NAME r_g08.g08_nombre
				CALL fgl_winmessage(vg_producto,
					            'Banco no existe.',
						    'exclamation')
				NEXT FIELD banco
			ELSE
				DISPLAY BY NAME r_g08.g08_nombre
			END IF 
		END IF
	AFTER FIELD g09_numero_cta
		IF r_g09.g09_numero_cta IS NULL THEN
			INITIALIZE r_g13.* TO NULL
			DISPLAY BY NAME r_g13.g13_moneda, r_g13.g13_nombre
			CONTINUE INPUT
		ELSE
			IF banco IS NULL THEN
				CALL fgl_winmessage(vg_producto,
					'Debe ingresar un banco primero.',
					'exclamation')
				INITIALIZE r_g09.g09_numero_cta TO NULL
				DISPLAY BY NAME r_g09.g09_numero_cta
				NEXT FIELD banco
			END IF
			LET nro_cta = r_g09.g09_numero_cta
			CALL fl_lee_banco_compania(vg_codcia, banco,
				r_g09.g09_numero_cta) RETURNING r_g09.*
			IF r_g09.g09_numero_cta IS NULL THEN
				CALL fgl_winmessage(vg_producto,
					'No existe cuenta en este banco.',
					'exclamation')
				LET r_g09.g09_numero_cta = nro_cta
				NEXT FIELD g09_numero_cta
			END IF
			IF r_g09.g09_estado = 'B' THEN
				CALL fgl_winmessage(vg_producto,
					'La cuenta est� bloqueada.',
					'exclamation')
				NEXT FIELD g09_numero_cta
			END IF
			CALL fl_lee_moneda(r_g09.g09_moneda) RETURNING r_g13.*
			DISPLAY BY NAME r_g13.g13_moneda, r_g13.g13_nombre
		END IF
	AFTER FIELD proveedor
		IF proveedor IS NULL THEN
			INITIALIZE r_p01.p01_nomprov TO NULL
			LET tipo_vcto = 'V'
			DISPLAY BY NAME r_p01.p01_nomprov, tipo_vcto
			CONTINUE INPUT
		END IF
		CALL fl_lee_proveedor(proveedor) RETURNING r_p01.*
		IF r_p01.p01_codprov IS NULL THEN
			CALL fgl_winmessage(vg_producto,
				'Proveedor no existe.',
				'exclamation')
			DISPLAY BY NAME r_p01.p01_nomprov
			NEXT FIELD proveedor
		END IF
		IF r_p01.p01_estado = 'B' THEN
			CALL fgl_winmessage(vg_producto,
				'Proveedor est� bloqueado.',
				'exclamation')
			DISPLAY BY NAME r_p01.p01_nomprov
			NEXT FIELD proveedor
		END IF
		DISPLAY BY NAME r_p01.p01_nomprov
	AFTER FIELD tipo_vcto
		IF tipo_vcto = 'T' AND proveedor IS NULL THEN
			CALL fgl_winmessage(vg_producto,
				'Si no especifica proveedor solo podr� ' || 
				'ver los documentos vencidos o por vencer ' ||
				'pero no ambos a la vez.',
				'exclamation')
			LET tipo_vcto = 'V'
			DISPLAY BY NAME tipo_vcto
			NEXT FIELD tipo_vcto
		END IF
END INPUT
IF INT_FLAG THEN
	CLOSE WINDOW w_204_2
	RETURN condicion
END IF

LET rm_p24.p24_moneda     = r_g13.g13_moneda
LET rm_p24.p24_banco      = banco
LET rm_p24.p24_numero_cta = r_g09.g09_numero_cta

IF proveedor IS NOT NULL THEN
	LET rm_p24.p24_codprov = proveedor
	LET condicion = ' AND p20_codprov = ' || proveedor
END IF
CASE tipo_vcto
	WHEN 'V'
		IF condicion IS NOT NULL THEN
			LET condicion = 
				condicion || ' AND p20_fecha_vcto < TODAY'
		ELSE
			LET condicion = ' AND p20_fecha_vcto < TODAY'
		END IF
	WHEN 'P'
		IF condicion IS NOT NULL THEN
			LET condicion = 
				condicion || ' AND p20_fecha_vcto >= TODAY'
		ELSE
			LET condicion = ' AND p20_fecha_vcto >= TODAY'
		END IF
END CASE

CLOSE WINDOW w_204_2

RETURN condicion

END FUNCTION



FUNCTION calcula_paridad(moneda_ori, moneda_dest)

DEFINE moneda_ori	LIKE veht036.v36_moneda
DEFINE moneda_dest	LIKE veht036.v36_moneda
DEFINE paridad		LIKE veht036.v36_paridad_mb

DEFINE r_g14		RECORD LIKE gent014.*

IF moneda_ori = moneda_dest THEN
	LET paridad = 1 
ELSE
	CALL fl_lee_factor_moneda(moneda_ori, moneda_dest) 
		RETURNING r_g14.*
	IF r_g14.g14_serial IS NULL THEN
		CALL fgl_winmessage(vg_producto, 
				    'No existe factor de conversi�n ' ||
				    'para esta moneda.',
				    'exclamation')
		INITIALIZE paridad TO NULL
	ELSE
		LET paridad = r_g14.g14_tasa 
	END IF
END IF

RETURN paridad

END FUNCTION



FUNCTION graba_autorizacion()

DEFINE i		SMALLINT
DEFINE proveedor	LIKE cxpt024.p24_codprov

SELECT COUNT(*) INTO i
	FROM tmp_detalle 
	WHERE valor_pagar > 0
	  AND tmp_check = 'S'
	
IF i = 0 THEN
	LET INT_FLAG = 1
	RETURN
END IF	

DECLARE q_cab CURSOR FOR
	SELECT * FROM tmp_detalle 
		WHERE valor_pagar > 0
		  AND tmp_check = 'S'
		ORDER BY proveedor

BEGIN WORK

INITIALIZE proveedor TO NULL
FOREACH q_cab INTO rm_docs[1].*
	IF rm_docs[1].proveedor <> proveedor OR proveedor IS NULL THEN
		LET proveedor = rm_docs[1].proveedor
		CALL graba_cabecera_autorizacion()
	END IF
	CALL graba_detalle_autorizacion()
END FOREACH

COMMIT WORK
	
END FUNCTION



FUNCTION graba_cabecera_autorizacion()

LET rm_p24.p24_codprov = rm_docs[1].proveedor

-- OjO
-- estos campos ser�n actualizados al grabar el detalle de la autorizacion
LET rm_p24.p24_total_int = 0
LET rm_p24.p24_total_cap = 0
LET rm_p24.p24_total_ret = 0
LET rm_p24.p24_total_che = 0

SELECT MAX(p24_orden_pago) INTO rm_p24.p24_orden_pago
	FROM cxpt024
	WHERE p24_compania  = vg_codcia
	  AND p24_localidad = vg_codloc
IF rm_p24.p24_orden_pago IS NULL THEN
	LET rm_p24.p24_orden_pago = 1
ELSE
	LET rm_p24.p24_orden_pago = rm_p24.p24_orden_pago + 1
END IF
IF rm_p24.p24_referencia IS NULL THEN
	LET rm_p24.p24_referencia = 'ORDEN DE PAGO # ' || 
				    rm_p24.p24_orden_pago
END IF
INSERT INTO cxpt024 VALUES(rm_p24.*)

END FUNCTION



FUNCTION graba_detalle_autorizacion()

DEFINE query		VARCHAR(255)

DEFINE r_p20		RECORD LIKE cxpt020.*
DEFINE r_p25		RECORD LIKE cxpt025.*
DEFINE r_p26		RECORD LIKE cxpt026.*

INITIALIZE r_p25.* TO NULL

LET r_p25.p25_compania   = vg_codcia
LET r_p25.p25_localidad  = vg_codloc
LET r_p25.p25_orden_pago = rm_p24.p24_orden_pago
LET r_p25.p25_codprov	 = rm_p24.p24_codprov

SELECT MAX(p25_secuencia) INTO r_p25.p25_secuencia
	FROM cxpt025
	WHERE p25_compania   = vg_codcia
	  AND p25_localidad  = vg_codloc
	  AND p25_orden_pago = rm_p24.p24_orden_pago
IF r_p25.p25_secuencia IS NULL THEN
	LET r_p25.p25_secuencia = 1
ELSE
	LET r_p25.p25_secuencia = r_p25.p25_secuencia + 1
END IF

LET r_p25.p25_tipo_doc   = rm_docs[1].tipo_doc
LET r_p25.p25_num_doc    = rm_docs[1].num_doc
LET r_p25.p25_dividendo  = rm_docs[1].dividendo

LET r_p25.p25_valor_mora = 0

SELECT SUM(subtotal) INTO r_p25.p25_valor_ret
	FROM tmp_retenciones
	WHERE proveedor = r_p25.p25_codprov
	  AND tipo_doc  = rm_docs[1].tipo_doc
	  AND num_doc   = rm_docs[1].num_doc
	  AND dividendo = rm_docs[1].dividendo
IF r_p25.p25_valor_ret IS NULL THEN
	LET r_p25.p25_valor_ret = 0
END IF
	  
CALL fl_lee_documento_deudor_cxp(vg_codcia, vg_codloc, rm_docs[1].proveedor,
				 rm_docs[1].tipo_doc, rm_docs[1].num_doc,
				 rm_docs[1].dividendo) RETURNING r_p20.*

IF rm_docs[1].valor_pagar <= r_p20.p20_saldo_int THEN
	LET r_p25.p25_valor_int = rm_docs[1].valor_pagar
	LET r_p25.p25_valor_cap = 0
ELSE
	LET r_p25.p25_valor_int = r_p20.p20_saldo_int
	LET r_p25.p25_valor_cap = rm_docs[1].valor_pagar - r_p20.p20_saldo_int
END IF

INSERT INTO cxpt025 VALUES(r_p25.*)
	
UPDATE cxpt024 SET
	p24_total_int = p24_total_int + r_p25.p25_valor_int,
	p24_total_cap = p24_total_cap + r_p25.p25_valor_cap,
	p24_total_ret = p24_total_ret + r_p25.p25_valor_ret,
	p24_total_che = 
		p24_total_che + (rm_docs[1].valor_pagar - r_p25.p25_valor_ret)
	WHERE p24_compania   = vg_codcia
	  AND p24_localidad  = vg_codloc
	  AND p24_orden_pago = rm_p24.p24_orden_pago

LET query = 'INSERT INTO cxpt026 ',
	    '	SELECT ', vg_codcia, ', ', vg_codloc, ', ', 
	    		r_p25.p25_orden_pago, ', ', r_p25.p25_secuencia, ', ',
	    '		codigo_sri, tipo_ret, porc, val_base, subtotal',
	    '		FROM tmp_retenciones ',
	    '		WHERE proveedor = ', r_p25.p25_codprov,
	    '		  AND tipo_doc  = "', rm_docs[1].tipo_doc, '"',
	    '		  AND num_doc   = "', rm_docs[1].num_doc, '"',
	    '		  AND dividendo = ', rm_docs[1].dividendo
	    
PREPARE statement2 FROM query
EXECUTE statement2

{
LET r_p26.p26_compania   = vg_codcia
LET r_p26.p26_localidad  = vg_codloc
LET r_p26.p26_orden_pago = r_p25.p25_orden_pago
LET r_p26.p26_secuencia  = r_p25.p25_secuencia

DECLARE q_retenciones CURSOR FOR 
	SELECT tipo_ret, porc, val_base, subtotal
		FROM tmp_retenciones
		WHERE proveedor = r_p25.p25_codprov
	  	  AND tipo_doc  = rm_docs[1].tipo_doc
	  	  AND num_doc   = rm_docs[1].num_doc
	  	  AND dividendo = rm_docs[1].dividendo

FOREACH q_retenciones INTO r_p26.p26_tipo_ret,   r_p26.p26_porcentaje,
			   r_p26.p26_valor_base, r_p26.p26_valor_ret
	INSERT INTO cxpt026 VALUES(r_p26.*)
END FOREACH
}	  
END FUNCTION



FUNCTION calcula_totales()

DEFINE total_saldo		LIKE cxpt024.p24_total_cap
DEFINE total_pagar		LIKE cxpt024.p24_total_cap

SELECT SUM(saldo), SUM(valor_pagar)
	INTO total_saldo, total_pagar
	FROM tmp_detalle
IF total_saldo IS NULL THEN
	LET total_saldo = 0
END IF
IF total_pagar IS NULL THEN
	LET total_pagar = 0
END IF

DISPLAY BY NAME total_saldo, total_pagar

END FUNCTION



FUNCTION execute_query()

LET vm_num_rows = 1
LET vm_row_current = 1

SELECT ROWID INTO vm_rows[vm_num_rows]
	FROM cxpt024
	WHERE p24_compania   = vg_codcia
	  AND p24_localidad  = vg_codloc
	  AND p24_orden_pago = vm_ord_pago
	  AND p24_tipo       = 'P'
IF STATUS = NOTFOUND THEN
	CALL fgl_winmessage(vg_producto, 
		'No existe orden de pago.', 
		'exclamation')
	EXIT PROGRAM
ELSE
	CALL lee_muestra_registro(vm_rows[vm_row_current])
END IF

END FUNCTION



FUNCTION muestra_detalle_f4()

DEFINE i		SMALLINT
DEFINE j		SMALLINT

LET i = lee_detalle_f4()
IF i = 0 THEN
	CALL fl_mensaje_consulta_sin_registros()
	RETURN
END IF

LET vm_ind_docs = i

IF vm_ind_docs > 0 THEN
	CALL set_count(vm_ind_docs)
END IF
DISPLAY ARRAY rm_docs_f4 TO ra_docs.*
	ON KEY(INTERRUPT)
		EXIT DISPLAY
	ON KEY(F5)
		CALL muestra_retenciones_f4(i)
		LET INT_FLAG = 0
	ON KEY(F6)
		CALL ver_estado_cuenta(0)
		LET INT_FLAG = 0
	BEFORE ROW
		LET i = arr_curr()
		LET j = scr_line()
	BEFORE DISPLAY
		CALL dialog.keysetlabel('ACCEPT', '')
		CALL setea_nombre_botones_f4()
	AFTER DISPLAY
		CONTINUE DISPLAY
END DISPLAY

END FUNCTION



FUNCTION lee_detalle_f4()

DEFINE i		SMALLINT
DEFINE total_saldo	LIKE cxpt020.p20_saldo_cap

DECLARE q_docs CURSOR FOR
	SELECT p25_tipo_doc, p25_num_doc, p25_dividendo, p20_fecha_vcto,
	       (p20_saldo_cap + p20_saldo_int), 
	       (p25_valor_cap + p25_valor_int)
		FROM cxpt025, cxpt020
		WHERE p25_compania   = vg_codcia
		  AND p25_localidad  = vg_codloc
		  AND p25_orden_pago = rm_p24.p24_orden_pago
		  AND p20_compania   = p25_compania 
		  AND p20_localidad  = p25_localidad
		  AND p20_codprov    = p25_codprov
		  AND p20_tipo_doc   = p25_tipo_doc
		  AND p20_num_doc    = p25_num_doc
		  AND p20_dividendo  = p25_dividendo

LET total_saldo = 0		  
LET i = 1
FOREACH q_docs INTO rm_docs_f4[i].*
	LET total_saldo = total_saldo + rm_docs_f4[i].saldo
	LET i = i + 1
	IF i > vm_max_docs THEN
		EXIT FOREACH
	END IF
END FOREACH

DISPLAY total_saldo TO p24_total_cap

LET i = i - 1

RETURN i

END FUNCTION



FUNCTION muestra_retenciones_f4(i)

DEFINE i		SMALLINT
DEFINE j		SMALLINT
DEFINE salir		SMALLINT
DEFINE resp		CHAR(6)

DEFINE val_bienes	DECIMAL(12,2)
DEFINE val_servi	DECIMAL(12,2)
DEFINE val_impto	DECIMAL(12,2)
DEFINE val_neto		DECIMAL(12,2)
DEFINE val_pagar	DECIMAL(12,2)
DEFINE tot_ret  	DECIMAL(12,2)
DEFINE val_cheque	DECIMAL(12,2)

DEFINE r_c01		RECORD LIKE ordt001.*
DEFINE r_c10		RECORD LIKE ordt010.*
DEFINE r_p01		RECORD LIKE cxpt001.*
DEFINE r_p05		RECORD LIKE cxpt005.*
DEFINE r_p20		RECORD LIKE cxpt020.*
DEFINE r_p26		RECORD LIKE cxpt026.*

CALL fl_lee_proveedor(rm_docs[i].proveedor)	RETURNING r_p01.*

OPEN WINDOW w_204_3 AT 4,9 WITH 21 ROWS, 70 COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, BORDER)
OPEN FORM f_204_3 FROM '../forms/cxpf204_3'
DISPLAY FORM f_204_3

CALL setea_nombre_botones_f3()

DISPLAY r_p01.p01_codprov 	TO cod_proveedor
DISPLAY r_p01.p01_nomprov	TO n_proveedor
DISPLAY BY NAME rm_docs_f4[i].tipo_doc, rm_docs_f4[i].num_doc, 
		rm_docs_f4[i].dividendo

CALL fl_lee_documento_deudor_cxp(vg_codcia, vg_codloc, rm_p24.p24_codprov,
				 rm_docs_f4[i].tipo_doc, rm_docs_f4[i].num_doc,
				 rm_docs_f4[i].dividendo) RETURNING r_p20.*

LET val_impto  = r_p20.p20_valor_impto
LET val_neto   = r_p20.p20_valor_fact

LET tot_ret    = 0
LET ind_ret    = 0

LET val_bienes  = val_neto - val_impto
LET val_servi = 0
IF r_p20.p20_numero_oc IS NOT NULL THEN
	CALL fl_lee_orden_compra(vg_codcia, vg_codloc, r_p20.p20_numero_oc) 
		RETURNING r_c10.*
	CALL fl_lee_tipo_orden_compra(r_c10.c10_tipo_orden) RETURNING r_c01.*
	
	IF r_c01.c01_bien_serv = 'S' THEN
		LET val_servi  = val_neto - val_impto
		LET val_bienes = 0
	END IF
END IF
	
LET val_pagar  = rm_docs_f4[i].valor_pagar

DECLARE q_ret3 CURSOR FOR
	SELECT cxpt026.*, c02_nombre FROM cxpt026, cxpt025, ordt002
		WHERE p25_compania   = vg_codcia
		  AND p25_localidad  = vg_codloc
		  AND p25_orden_pago = rm_p24.p24_orden_pago
		  AND p25_codprov    = rm_p24.p24_codprov
		  AND p25_tipo_doc   = rm_docs_f4[i].tipo_doc
		  AND p25_num_doc    = rm_docs_f4[i].num_doc
  	  	  AND p26_compania   = p25_compania
		  AND p26_localidad  = p25_localidad
		  AND p26_orden_pago = p25_orden_pago
		  AND p26_secuencia  = p25_secuencia
		  AND c02_compania   = p26_compania
		  AND c02_codigo_sri = p26_codigo_sri
		  AND c02_tipo_ret   = p26_tipo_ret
		  AND c02_porcentaje = p26_porcentaje

LET j = 1
FOREACH q_ret3 INTO r_p26.*, r_ret[j].n_retencion
	LET r_ret[j].check    = 'N'
	LET r_ret[j].tipo_ret = r_p26.p26_tipo_ret
	LET r_ret[j].porc     = r_p26.p26_porcentaje
	LET r_ret[j].val_base = r_p26.p26_valor_base
	LET r_ret[j].subtotal = r_p26.p26_valor_ret
	LET tot_ret = tot_ret + r_p26.p26_valor_ret
	LET j = j + 1
	IF j > ind_max_ret THEN
		EXIT FOREACH
	END IF
END FOREACH
FREE q_ret3

LET ind_ret = j - 1	

LET val_cheque = val_pagar - tot_ret

DISPLAY BY NAME val_impto, val_neto, val_bienes, val_servi, val_pagar, 
		tot_ret, val_cheque
	
OPTIONS
	INSERT KEY F40,
	DELETE KEY F41
	
LET salir = 0
WHILE NOT salir
	IF ind_ret > 0 THEN
		CALL set_count(ind_ret)
	ELSE
		CALL fgl_winmessage(vg_producto,
			'No hay datos que mostrar.',
			'exclamation')
		RETURN
	END IF
	INPUT ARRAY r_ret WITHOUT DEFAULTS FROM ra_ret.*
		ON KEY(INTERRUPT)
			LET salir = 1
			EXIT INPUT
		BEFORE ROW
			LET i = arr_curr()
			LET j = scr_line()
		BEFORE INPUT
			CALL dialog.keysetlabel('INSERT', '')
			CALL dialog.keysetlabel('DELETE', '')
			CALL dialog.keysetlabel('ACCEPT', '')
		BEFORE INSERT
			EXIT INPUT
		BEFORE DELETE
			EXIT INPUT
		AFTER FIELD check
			LET r_ret[i].check = 'N'
			DISPLAY r_ret[i].* TO ra_ret[j].*
			IF fgl_lastkey() <> fgl_keyval('down') 
			AND fgl_lastkey() <> fgl_keyval('up')
			THEN
				NEXT FIELD ra_ret[j-1].check
			END IF
		AFTER INPUT
			CONTINUE INPUT
	END INPUT
END WHILE

CLOSE WINDOW w_204_3

END FUNCTION



FUNCTION setea_nombre_botones_f4()

DISPLAY 'Tp'            TO bt_tipo_doc
DISPLAY 'N�mero Doc.'   TO bt_nro_doc  
DISPLAY '#'	        TO bt_dividendo 
DISPLAY 'Fecha Vcto.'   TO bt_fecha_vcto
DISPLAY 'Saldo Capital' TO bt_capital
DISPLAY 'Valor a Pagar' TO bt_valor 

END FUNCTION



FUNCTION muestra_totales()

DEFINE i		SMALLINT
DEFINE max_arr		SMALLINT

DEFINE r_totales ARRAY[255] OF RECORD
	codprov		LIKE cxpt024.p24_codprov,
	val_ret_f	LIKE cxpt024.p24_total_ret,
	val_ret_i	LIKE cxpt024.p24_total_ret,
	val_che 	LIKE cxpt024.p24_total_che
END RECORD

DEFINE tot_ret_f	DECIMAL(12,2)
DEFINE tot_ret_i	DECIMAL(12,2)
DEFINE tot_che		DECIMAL(12,2)

DEFINE r_p01		RECORD LIKE cxpt001.*

LET max_arr = 255

OPEN WINDOW w_204_5 AT 7,16 WITH 16 ROWS, 62 COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, BORDER)
OPEN FORM f_204_5 FROM '../forms/cxpf204_5'
DISPLAY FORM f_204_5

-- Etiquetas botones
DISPLAY 'Prov.'		TO 	bt_proveedor
DISPLAY 'Ret. Fuente'	TO 	bt_val_ret_f
DISPLAY 'Ret. Iva'	TO 	bt_val_ret_i
DISPLAY 'Valor Cheque'	TO 	bt_val_che

DECLARE q_prov CURSOR FOR
	SELECT proveedor FROM tmp_detalle 
		WHERE tmp_check = 'S'
		GROUP BY proveedor
		ORDER BY proveedor

LET tot_ret_f = 0
LET tot_ret_i = 0
LET tot_che   = 0
LET i = 1
FOREACH q_prov INTO r_totales[i].codprov
	SELECT SUM(subtotal) INTO r_totales[i].val_ret_f
		FROM tmp_retenciones
		WHERE proveedor = r_totales[i].codprov
		  AND tipo_ret  = 'F'
	IF r_totales[i].val_ret_f IS NULL THEN
		LET r_totales[i].val_ret_f = 0
	END IF

	SELECT SUM(subtotal) INTO r_totales[i].val_ret_i
		FROM tmp_retenciones
		WHERE proveedor = r_totales[i].codprov
		  AND tipo_ret  = 'I'
	IF r_totales[i].val_ret_i IS NULL THEN
		LET r_totales[i].val_ret_i = 0
	END IF
		  
	SELECT SUM(valor_pagar) INTO r_totales[i].val_che
		FROM tmp_detalle
		WHERE proveedor = r_totales[i].codprov
	IF r_totales[i].val_che IS NULL THEN
		LET r_totales[i].val_che = 0
	END IF
		
	LET r_totales[i].val_che = r_totales[i].val_che - 
				   r_totales[i].val_ret_f - 
				   r_totales[i].val_ret_i

	LET tot_ret_f = tot_ret_f + r_totales[i].val_ret_f
	LET tot_ret_i = tot_ret_i + r_totales[i].val_ret_i
	LET tot_che   = tot_che   + r_totales[i].val_che
				   
	LET i = i + 1
	IF i > max_arr THEN
		EXIT FOREACH
	END IF
END FOREACH
LET i = i - 1

IF i = 0 THEN
	CALL fgl_winmessage(vg_producto,
		'No hay datos que mostrar.',
		'exclamation')
	CLOSE WINDOW w_204_5
	RETURN
END IF

DISPLAY BY NAME tot_ret_f, tot_ret_i, tot_che

CALL set_count(i)
DISPLAY ARRAY r_totales TO ra_totales.*
	BEFORE ROW
		LET i = arr_curr()
		CALL fl_lee_proveedor(r_totales[i].codprov) RETURNING r_p01.*
		DISPLAY r_p01.p01_nomprov	TO 	nomprov
END DISPLAY

CLOSE WINDOW w_204_5

END FUNCTION



FUNCTION ver_estado_cuenta(i)

DEFINE i		SMALLINT
DEFINE comando		CHAR(255)

IF i = 0 THEN
	LET i = 1
	LET rm_docs[i].proveedor = rm_p24.p24_codprov
END IF

LET comando = 'cd ..', vg_separador, '..', vg_separador, 'TESORERIA', 
	vg_separador, 'fuentes', vg_separador, '; fglrun cxpp300 ', vg_base, 
	' ', 'TE', vg_codcia, ' ', vg_codloc, ' ', rm_docs[i].proveedor, 
	' ', rm_p24.p24_moneda
	
RUN comando	

END FUNCTION



FUNCTION validar_parametros()

CALL fl_lee_modulo(vg_modulo) RETURNING rg_mod.*
IF rg_mod.g50_modulo IS NULL THEN
	CALL fgl_winmessage(vg_producto, 'No existe m�dulo: ' || vg_modulo, 
                            'stop')
	EXIT PROGRAM
END IF
CALL fl_lee_compania(vg_codcia) RETURNING rg_cia.*
IF rg_cia.g01_compania IS NULL THEN
	CALL fgl_winmessage(vg_producto, 'No existe compa��a: '|| vg_codcia, 
                            'stop')
	EXIT PROGRAM
END IF
IF rg_cia.g01_estado <> 'A' THEN
	CALL fgl_winmessage(vg_producto, 'Compa��a no est� activa: ' || 
                            vg_codcia, 'stop')
	EXIT PROGRAM
END IF
IF vg_codloc IS NULL THEN
	LET vg_codloc   = fl_retorna_agencia_default(vg_codcia)
END IF
CALL fl_lee_localidad(vg_codcia, vg_codloc) RETURNING rg_loc.*
IF rg_loc.g02_localidad IS NULL THEN
	CALL fgl_winmessage(vg_producto, 'No existe localidad: ' || vg_codloc, 
                            'stop')
	EXIT PROGRAM
END IF
IF rg_loc.g02_estado <> 'A' THEN
	CALL fgl_winmessage(vg_producto, 'Localidad no est� activa: ' || 
                            vg_codloc, 'stop')
	EXIT PROGRAM
END IF

END FUNCTION
