--------------------------------------------------------------------------------
-- Titulo           : cxpp204.4gl - Solicitud de pago a proveedores
--                                  por documentos
-- Elaboracion      : 21-nov-2001
-- Autor            : JCM
-- Formato Ejecucion: fglrun cxpp204 base modulo compania localidad [ord_pago]
--		Si (ord_pago <> 0) el programa se esta ejcutando en modo de
--			solo consulta
--		Si (ord_pago = 0) el programa se esta ejecutando en forma 
--			independiente
-- Ultima Correccion: 
-- Motivo Correccion: 
--------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_ord_pago	LIKE cxpt024.p24_orden_pago
DEFINE rm_orden         ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1     SMALLINT
DEFINE vm_columna_2     SMALLINT

-- CADA VEZ QUE SE REALIZE UNA CONSULTA SE GUARDARAN LOS ROWID DE CADA FILA 
-- RECUPERADA EN UNA TABLA LLAMADA r_rows QUE TENDRA 1000 ELEMENTOS
DEFINE vm_rows ARRAY[1000] OF INTEGER  	-- ARREGLO DE ROWID DE FILAS LEIDAS
DEFINE vm_row_current	SMALLINT	-- FILA CORRIENTE DEL ARREGLO
DEFINE vm_num_rows	SMALLINT	-- CANTIDAD DE FILAS LEIDAS

DEFINE vm_max_rows	SMALLINT
--
-- DEFINE RECORD(S) HERE
--
DEFINE rm_p24		RECORD LIKE cxpt024.*

DEFINE rm_docs ARRAY[1000] OF RECORD 
	proveedor	INTEGER,
	tipo_doc	CHAR(2),
	num_doc		CHAR(21),
	dividendo	SMALLINT,
	fecha_vcto	DATE,
	saldo		DECIMAL(12,2),
	valor_pagar	DECIMAL(12,2),
	check		CHAR(1)
END RECORD

DEFINE rm_detret ARRAY[1000] OF RECORD
	cant_ret    INTEGER,
	tot_ret		DECIMAL(12,2)
END RECORD

DEFINE vm_max_docs	SMALLINT 
DEFINE vm_ind_docs	SMALLINT
DEFINE rm_docs_f4 ARRAY[100] OF RECORD 	-- Arreglo que se usara en la
	tipo_doc	CHAR(2),		-- forma cxpf204_3
	num_doc		CHAR(21),
	dividendo	SMALLINT,
	fecha_vcto	DATE,
	saldo  		DECIMAL(12,2),
	valor_pagar	DECIMAL(12,2)
END RECORD

DEFINE vm_num_det	INTEGER
DEFINE vm_max_det	INTEGER



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
LET vg_proceso = arg_val(0)
CALL startlog('../logs/' || vg_proceso CLIPPED || '.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 AND num_args() <> 5 THEN	-- Validar # parámetros correcto
	CALL fl_mostrar_mensaje('Número de parámetros incorrecto.','stop')
	EXIT PROGRAM
END IF
LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_codcia   = arg_val(3)

CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	-- Asigna un valor por default a vg_codloc
				-- que luego puede ser reemplazado si se 
                                -- mantiene sin comentario la siguiente linea
LET vg_codloc   = arg_val(4)

LET vm_ord_pago = 0
IF num_args() = 5 THEN
	LET vm_ord_pago  = arg_val(5)
END IF

--#CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()

END MAIN



FUNCTION funcion_master()
DEFINE i		SMALLINT
DEFINE lin_menu		SMALLINT
DEFINE row_ini  	SMALLINT
DEFINE num_rows 	SMALLINT
DEFINE num_cols 	SMALLINT

CALL fl_nivel_isolation()
IF num_args() = 4 THEN
	CALL fl_chequeo_mes_proceso_cxp(vg_codcia) RETURNING int_flag 
	IF int_flag THEN
		RETURN
	END IF
END IF
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
OPEN WINDOW w_204 AT row_ini, 2 WITH num_rows ROWS, num_cols COLUMNS
	ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE lin_menu,
		  BORDER, MESSAGE LINE LAST - 1) 
IF vg_gui = 1 THEN
	OPEN FORM f_204 FROM '../forms/cxpf204_1'
ELSE
	OPEN FORM f_204 FROM '../forms/cxpf204_1c'
END IF
DISPLAY FORM f_204

LET vm_num_rows = 0
LET vm_row_current = 0
INITIALIZE rm_p24.* TO NULL

LET vm_max_det  = 10000
LET vm_max_rows = 1000
LET vm_max_docs = 100

IF vm_ord_pago <> 0 THEN
	CLOSE FORM f_204
	IF vg_gui = 1 THEN
		OPEN FORM f_204_3 FROM '../forms/cxpf204_3'
	ELSE
		OPEN FORM f_204_3 FROM '../forms/cxpf204_3c'
	END IF
	DISPLAY FORM f_204_3
	CALL setea_nombre_botones_f3()
	CALL execute_query()
	EXIT PROGRAM
ELSE
	CALL setea_nombre_botones_f1()
	-- Tabla temporal para la ordenación
	CREATE TEMP TABLE tmp_detalle(
		proveedor	INTEGER  NOT NULL,
		tipo_doc	CHAR(2)  NOT NULL,
		num_doc		CHAR(21) NOT NULL,
		dividendo	SMALLINT NOT NULL,
		fecha_vcto	DATE,
		saldo		DECIMAL(12,2),
		valor_pagar	DECIMAL(12,2),
		tmp_check	CHAR(1),
		cant_ret	INTEGER,
		tot_ret		DECIMAL(12,2)
	)
	CREATE UNIQUE INDEX tmp_pk1
		ON tmp_detalle(proveedor, tipo_doc, num_doc, dividendo)

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

LET rm_p24.p24_usuario    = vg_usuario
LET rm_p24.p24_fecing     = fl_current()

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
DEFINE query			CHAR(1000)

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
	    '          (p20_saldo_cap + p20_saldo_int), 0, "N",',
		'		   COUNT(p28_secuencia), NVL(SUM(p28_valor_ret), 0) ',
	    '	FROM cxpt020, OUTER (cxpt028, cxpt027)',
	    '	WHERE p20_compania  = ', vg_codcia,
	    '	  AND p20_localidad = ', vg_codloc,
	    expr_sql CLIPPED,
	    '     AND p20_moneda    = "', rm_p24.p24_moneda, '"',
	    '	  AND p20_saldo_cap + p20_saldo_int > 0 ',
		'	  AND p28_compania  = p20_compania ',
		'  	  AND p28_localidad = p20_localidad ', 
		'  	  AND p28_codprov   = p20_codprov ',
		'  	  AND p28_tipo_doc  = p20_tipo_doc ',
		'  	  AND p28_num_doc   = p20_num_doc ',
		'  	  AND p27_compania  = p28_compania ',
		'  	  AND p27_localidad = p28_localidad ',
		'  	  AND p27_num_ret   = p28_num_ret ',
		'  	  AND p27_estado    = "A"',
		'	GROUP BY p20_codprov, p20_tipo_doc, p20_num_doc, p20_dividendo, p20_fecha_vcto, p20_saldo_cap, p20_saldo_int '

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
DEFINE query            CHAR(500)

LET vm_columna_1 = 5
LET vm_columna_2 = 6
LET rm_orden[vm_columna_1]  = 'DESC'
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
        FOREACH q_deto INTO rm_docs[i].*, rm_detret[i].*
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
	INPUT ARRAY rm_docs WITHOUT DEFAULTS FROM ra_docs.*
		ON KEY(INTERRUPT)
			LET INT_FLAG = 0
			CALL fl_mensaje_abandonar_proceso() RETURNING resp
			IF resp = 'Yes' THEN
				LET INT_FLAG = 1
				EXIT INPUT
			END IF
        	ON KEY(F1,CONTROL-W)
			CALL control_visor_teclas_caracter_2() 
		AFTER FIELD valor_pagar
			IF rm_docs[i].valor_pagar IS NULL THEN
				LET rm_docs[i].valor_pagar = 0
			END IF
			IF rm_docs[i].valor_pagar > 0 THEN
				LET rm_docs[i].check = 'S'
				IF rm_docs[i].valor_pagar > rm_docs[i].saldo THEN
					CALL fl_mostrar_mensaje('Valor a pagar debe ser menor o igual al saldo del documento.','exclamation')
					LET rm_docs[i].valor_pagar = rm_docs[i].saldo
					DISPLAY rm_docs[i].* TO ra_docs[j].*
					NEXT FIELD valor_pagar
				END IF
				CALL chequea_retenciones_hechas(i)
				IF int_flag THEN
					LET int_flag = 0
					LET rm_docs[i].valor_pagar = 0
					LET rm_docs[i].check = 'N'
					DISPLAY rm_docs[i].* TO ra_docs[j].*
					NEXT FIELD valor_pagar
				END IF
			ELSE
				LET rm_docs[i].check = 'N'
			END IF
  			CALL graba_valores(i)
      		CALL calcula_totales()
			DISPLAY rm_docs[i].* TO ra_docs[j].*
     		LET int_flag = 0
		AFTER FIELD check
			IF rm_docs[i].check = 'S' THEN
				IF rm_docs[i].valor_pagar = 0 THEN
					LET rm_docs[i].valor_pagar = rm_docs[i].saldo
				END IF
				CALL chequea_retenciones_hechas(i)
				IF int_flag THEN
					LET int_flag = 0
					LET rm_docs[i].valor_pagar = 0
					LET rm_docs[i].check = 'N'
					DISPLAY rm_docs[i].* TO ra_docs[j].*
					NEXT FIELD valor_pagar
				END IF
			ELSE
				LET rm_docs[i].valor_pagar = 0 
			END IF
  			CALL graba_valores(i)
      		CALL calcula_totales()
			DISPLAY rm_docs[i].* TO ra_docs[j].*
			LET int_flag = 0
     	ON KEY(F5)
			LET i = arr_curr()
			LET j = scr_line()
     		CALL ver_estado_cuenta(i)
     		LET INT_FLAG = 0
      	ON KEY(F15)
			LET col = 1
			EXIT INPUT
		ON KEY(F16)
			LET col = 2
			EXIT INPUT
		ON KEY(F17)
			LET col = 3
			EXIT INPUT
		ON KEY(F18)
			LET col = 4
			EXIT INPUT
		ON KEY(F19)
			LET col = 5
			EXIT INPUT
		ON KEY(F20)
			LET col = 6
			EXIT INPUT
		ON KEY(F21)
			LET col = 7
			EXIT INPUT
		--#BEFORE INPUT
			--#CALL setea_nombre_botones_f1()
			--#CALL calcula_totales()
			--#CALL dialog.keysetlabel("F1","")
			--#CALL dialog.keysetlabel("CONTROL-W","")
		--#BEFORE ROW
			--#LET i = arr_curr()
			--#LET j = scr_line()
			--#CALL etiquetas_proveedor(rm_docs[i].proveedor,
						 --#rm_docs[i].fecha_vcto)
			DISPLAY BY NAME rm_detret[i].*
		--#AFTER INPUT
			--#LET salir = 1
	END INPUT
	IF vg_gui = 0 THEN
		LET salir = 1
	END IF
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



FUNCTION lee_muestra_registro(row)
DEFINE row 		INTEGER
DEFINE total		DECIMAL(14,2)


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
LET total = rm_p24.p24_total_int + rm_p24.p24_total_cap
DISPLAY total TO tot_val_pagar

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

IF vg_gui = 1 THEN
	DISPLAY "" AT 1,1
	DISPLAY vm_row_current, " de ", vm_num_rows AT 1, 67
END IF

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

IF fecha_vcto >= vg_fecha THEN
	DISPLAY 'Por vencer' TO n_estado_vcto
ELSE
	DISPLAY 'Vencido' TO n_estado_vcto
END IF
LET dias = fecha_vcto - vg_fecha
DISPLAY BY NAME dias

END FUNCTION



FUNCTION setea_nombre_botones_f1()

--#DISPLAY 'Prov'          TO bt_proveedor
--#DISPLAY 'Tp'            TO bt_tipo_doc
--#DISPLAY 'Número'        TO bt_num_doc
--#DISPLAY '#'             TO bt_dividendo
--#DISPLAY 'Fecha Vcto'    TO bt_fecha
--#DISPLAY 'Saldo'         TO bt_saldo
--#DISPLAY 'Valor a Pagar' TO bt_valor

END FUNCTION



FUNCTION criterios()
DEFINE tipo_vcto	CHAR(1)
DEFINE tipo_pago	CHAR(1)
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
DEFINE r_b10		RECORD LIKE ctbt010.*

INITIALIZE banco     TO NULL
INITIALIZE proveedor TO NULL
INITIALIZE r_g08.*   TO NULL
INITIALIZE r_g09.*   TO NULL
INITIALIZE r_g13.*   TO NULL
INITIALIZE r_p01.*   TO NULL

INITIALIZE condicion TO NULL

LET tipo_vcto = 'V'		-- Default value: 'V' (Vencidos)
LET tipo_pago = 'C'

OPEN WINDOW w_204_2 AT 7, 9 WITH 11 ROWS, 64 COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_204_2 FROM '../forms/cxpf204_2'
ELSE
	OPEN FORM f_204_2 FROM '../forms/cxpf204_2c'
END IF
DISPLAY FORM f_204_2

IF vg_gui = 0 THEN
	CALL muestra_tipovcto(tipo_vcto)
	CALL muestra_tipopago(tipo_pago)
END IF
LET INT_FLAG = 0
INPUT BY NAME banco, r_g09.g09_numero_cta, proveedor, tipo_vcto, tipo_pago
	WITHOUT DEFAULTS
	ON KEY (INTERRUPT)
		IF NOT FIELD_TOUCHED(banco, r_g09.g09_numero_cta, proveedor,
					tipo_vcto, tipo_pago)
		THEN
			EXIT INPUT
		END IF

		LET INT_FLAG = 0
		CALL fl_mensaje_abandonar_proceso() RETURNING resp
		IF resp = 'Yes' THEN
			LET INT_FLAG = 1
			EXIT INPUT
		END IF
        ON KEY(F1,CONTROL-W)
		CALL llamar_visor_teclas()
	ON KEY(F2)
		IF tipo_pago <> 'E' THEN
			IF INFIELD(banco) THEN
				CALL fl_ayuda_bancos()
					RETURNING r_g08.g08_banco,
						  r_g08.g08_nombre
				IF r_g08.g08_banco IS NOT NULL THEN
					LET banco = r_g08.g08_banco
					DISPLAY BY NAME banco, r_g08.g08_nombre
				END IF
			END IF
			IF INFIELD(g09_numero_cta) THEN
				CALL fl_ayuda_cuenta_banco(vg_codcia, 'A') 
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
	BEFORE INPUT
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
	AFTER FIELD banco
		IF tipo_pago = 'E' THEN
			CALL muestra_datos_pago_efectivo()
				RETURNING banco, r_g09.*, r_g13.*
			CONTINUE INPUT
		END IF
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
				--CALL fgl_winmessage(vg_producto,'Banco no existe.','exclamation')
				CALL fl_mostrar_mensaje('Banco no existe.','exclamation')
				NEXT FIELD banco
			ELSE
				DISPLAY BY NAME r_g08.g08_nombre
			END IF 
		END IF
	AFTER FIELD g09_numero_cta
		IF tipo_pago = 'E' THEN
			CALL muestra_datos_pago_efectivo()
				RETURNING banco, r_g09.*, r_g13.*
			CONTINUE INPUT
		END IF
		IF r_g09.g09_numero_cta IS NULL THEN
			INITIALIZE r_g13.* TO NULL
			DISPLAY BY NAME r_g13.g13_moneda, r_g13.g13_nombre
			CONTINUE INPUT
		END IF
		IF banco IS NULL THEN
			CALL fl_mostrar_mensaje('Debe ingresar un banco primero.','exclamation')
			INITIALIZE r_g09.g09_numero_cta TO NULL
			DISPLAY BY NAME r_g09.g09_numero_cta
			NEXT FIELD banco
		END IF
		LET nro_cta = r_g09.g09_numero_cta
		CALL fl_lee_banco_compania(vg_codcia, banco,
						r_g09.g09_numero_cta)
			RETURNING r_g09.*
		IF r_g09.g09_numero_cta IS NULL THEN
			CALL fl_mostrar_mensaje('No existe cuenta en este banco.','exclamation')
			LET r_g09.g09_numero_cta = nro_cta
			NEXT FIELD g09_numero_cta
		END IF
		IF r_g09.g09_estado = 'B' THEN
			CALL fl_mostrar_mensaje('La cuenta esta bloqueada.','exclamation')
			NEXT FIELD g09_numero_cta
		END IF
		CALL fl_lee_moneda(r_g09.g09_moneda) RETURNING r_g13.*
		DISPLAY BY NAME r_g13.g13_moneda, r_g13.g13_nombre
		CALL fl_lee_cuenta(r_g09.g09_compania, r_g09.g09_aux_cont)
			RETURNING r_b10.*
		IF r_b10.b10_compania IS NULL THEN
			CALL fl_mostrar_mensaje('No se puede escoger una cuenta corriente que no tiene auxiliar contable.', 'exclamation')
			NEXT FIELD g09_numero_cta
		END IF
		IF r_b10.b10_estado <> 'A' THEN
			CALL fl_mostrar_mensaje('El auxiliar contable de esta cuenta bancaria esta con estado bloqueado.', 'exclamation')
			NEXT FIELD g09_numero_cta
		END IF
	AFTER FIELD proveedor
		IF proveedor IS NULL THEN
			INITIALIZE r_p01.p01_nomprov TO NULL
			LET tipo_vcto = 'V'
			DISPLAY BY NAME r_p01.p01_nomprov, tipo_vcto
			IF vg_gui = 0 THEN
				CALL muestra_tipovcto(tipo_vcto)
			END IF
			CONTINUE INPUT
		END IF
		CALL fl_lee_proveedor(proveedor) RETURNING r_p01.*
		IF r_p01.p01_codprov IS NULL THEN
			--CALL fgl_winmessage(vg_producto,'Proveedor no existe.','exclamation')
			CALL fl_mostrar_mensaje('Proveedor no existe.','exclamation')
			DISPLAY BY NAME r_p01.p01_nomprov
			NEXT FIELD proveedor
		END IF
		IF r_p01.p01_estado = 'B' THEN
			CALL fl_mensaje_estado_bloqueado() 
			DISPLAY BY NAME r_p01.p01_nomprov
			NEXT FIELD proveedor
		END IF
		DISPLAY BY NAME r_p01.p01_nomprov
	AFTER FIELD tipo_vcto
		IF tipo_vcto = 'T' AND proveedor IS NULL THEN
			CALL fl_mostrar_mensaje('Si no especifica proveedor solo podrá ver los documentos vencidos o por vencer, pero no ambos a la vez.','exclamation')
			LET tipo_vcto = 'V'
			DISPLAY BY NAME tipo_vcto
			NEXT FIELD tipo_vcto
		END IF
		IF vg_gui = 0 THEN
			IF tipo_vcto IS NOT NULL THEN
				CALL muestra_tipovcto(tipo_vcto)
			ELSE
				CLEAR tit_tipo_vcto
			END IF
		END IF
	AFTER FIELD tipo_pago
		IF vg_gui = 0 THEN
			IF tipo_pago IS NOT NULL THEN
				CALL muestra_tipopago(tipo_pago)
			ELSE
				CLEAR tit_tipo_pago
			END IF
		END IF
		IF tipo_pago = 'E' THEN
			LET banco = 0
			CALL fl_lee_banco_general(banco) RETURNING r_g08.*
			IF r_g08.g08_banco IS NULL THEN
				CALL fl_mostrar_mensaje('No existe el banco para PAGO EFECTIVO. Por favor llame al ADMINISTRADOR.', 'exclamation')
				LET banco     = NULL
				LET tipo_pago = 'C'
				DISPLAY BY NAME banco, tipo_pago
				CONTINUE INPUT
			END IF
			CALL muestra_datos_pago_efectivo()
				RETURNING banco, r_g09.*, r_g13.*
		END IF
	AFTER INPUT
		IF tipo_pago = 'E' THEN
			CALL muestra_datos_pago_efectivo()
				RETURNING banco, r_g09.*, r_g13.*
		END IF
END INPUT
IF INT_FLAG THEN
	CLOSE WINDOW w_204_2
	RETURN condicion
END IF

LET rm_p24.p24_moneda     = r_g13.g13_moneda
LET rm_p24.p24_banco      = banco
LET rm_p24.p24_numero_cta = r_g09.g09_numero_cta

IF tipo_pago = "T" THEN
	LET rm_p24.p24_subtipo = 1
END IF

IF proveedor IS NOT NULL THEN
	LET rm_p24.p24_codprov = proveedor
	LET condicion = ' AND p20_codprov = ' || proveedor
END IF
CASE tipo_vcto
	WHEN 'V'
		IF condicion IS NOT NULL THEN
			LET condicion = 
				condicion || ' AND p20_fecha_vcto < "', vg_fecha, '"'
		ELSE
			LET condicion = ' AND p20_fecha_vcto < "', vg_fecha, '"' 
		END IF
	WHEN 'P'
		IF condicion IS NOT NULL THEN
			LET condicion = 
				condicion || ' AND p20_fecha_vcto >= "', vg_fecha, '"'
		ELSE
			LET condicion = ' AND p20_fecha_vcto >= "', vg_fecha, '"'
		END IF
END CASE

CLOSE WINDOW w_204_2

RETURN condicion

END FUNCTION



FUNCTION muestra_datos_pago_efectivo()
DEFINE banco 		LIKE gent008.g08_banco
DEFINE r_g08		RECORD LIKE gent008.*
DEFINE r_g09		RECORD LIKE gent009.*
DEFINE r_g13		RECORD LIKE gent013.*

LET banco = 0
CALL fl_lee_banco_general(banco) RETURNING r_g08.*
INITIALIZE r_g09.* TO NULL
DECLARE q_g09 CURSOR FOR
	SELECT * FROM gent009
		WHERE g09_compania = vg_codcia
		  AND g09_banco    = banco
OPEN q_g09
FETCH q_g09 INTO r_g09.*
CLOSE q_g09
FREE q_g09
CALL fl_lee_moneda(r_g09.g09_moneda) RETURNING r_g13.*
LET banco = r_g09.g09_banco
DISPLAY BY NAME banco, r_g08.g08_nombre, r_g09.g09_numero_cta, r_g13.g13_moneda,
		r_g13.g13_nombre
RETURN banco, r_g09.*, r_g13.*

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
		--CALL fgl_winmessage(vg_producto,'No existe factor de conversión para esta moneda.','exclamation')
		CALL fl_mostrar_mensaje('No existe factor de conversión para esta moneda.','exclamation')
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
-- estos campos serán actualizados al grabar el detalle de la autorizacion
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
DEFINE query		CHAR(400)
DEFINE r_p20		RECORD LIKE cxpt020.*
DEFINE r_p25		RECORD LIKE cxpt025.*

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
LET r_p25.p25_valor_ret = 0
	  
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
	p24_total_che = p24_total_che + rm_docs[1].valor_pagar 
	WHERE p24_compania   = vg_codcia
	  AND p24_localidad  = vg_codloc
	  AND p24_orden_pago = rm_p24.p24_orden_pago

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
	--CALL fgl_winmessage(vg_producto,'No existe orden de pago.','exclamation')
	CALL fl_mostrar_mensaje('No existe orden de pago.','exclamation')
	EXIT PROGRAM
END IF
CALL lee_muestra_registro(vm_rows[vm_row_current])

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
       	ON KEY(F1,CONTROL-W)
		CALL control_visor_teclas_caracter_3() 
	ON KEY(F5)
		CALL ver_estado_cuenta(0)
		LET INT_FLAG = 0
	--#BEFORE ROW
		--#LET i = arr_curr()
		--#LET j = scr_line()
	--#BEFORE DISPLAY
		--#CALL dialog.keysetlabel('ACCEPT', '')
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
		--#CALL setea_nombre_botones_f3()
	--#AFTER DISPLAY
		--#CONTINUE DISPLAY
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



FUNCTION setea_nombre_botones_f3()

--#DISPLAY 'Tp'            TO bt_tipo_doc
--#DISPLAY 'Número Doc.'   TO bt_nro_doc  
--#DISPLAY '#'	           TO bt_dividendo 
--#DISPLAY 'Fecha Vcto.'   TO bt_fecha_vcto
--#DISPLAY 'Saldo Capital' TO bt_capital
--#DISPLAY 'Valor a Pagar' TO bt_valor 

END FUNCTION



FUNCTION ver_estado_cuenta(i)
DEFINE i		SMALLINT
DEFINE comando		CHAR(255)
DEFINE run_prog		CHAR(10)

IF i = 0 THEN
	LET i = 1
	LET rm_docs[i].proveedor = rm_p24.p24_codprov
END IF

{-- ESTO PARA LLAMAR AL PROGRAMA SEGÚN SEA EL AMBIENTE --}
LET run_prog = '; fglrun '
IF vg_gui = 0 THEN
	LET run_prog = '; fglgo '
END IF
{--- ---}
LET comando = 'cd ..', vg_separador, '..', vg_separador, 'TESORERIA',
		vg_separador, 'fuentes', vg_separador, run_prog, 'cxpp314 ',
		vg_base, ' ', vg_modulo, ' ', vg_codcia, ' ', vg_codloc, ' ',
		rm_p24.p24_moneda, ' ', vg_fecha, ' "T" 0.01 "N" ',
		rm_docs[i].proveedor, ' 0 '
RUN comando	

END FUNCTION



FUNCTION muestra_tipovcto(tipovcto)
DEFINE tipovcto		CHAR(1)

CASE tipovcto
	WHEN 'V'
		DISPLAY 'VENCIDOS' TO tit_tipo_vcto
	WHEN 'P'
		DISPLAY 'POR VENCER' TO tit_tipo_vcto
	WHEN 'T'
		DISPLAY 'T O D O S' TO tit_tipo_vcto
	OTHERWISE
		CLEAR tipo_vcto, tit_tipo_vcto
END CASE

END FUNCTION



FUNCTION muestra_tipopago(tipopago)
DEFINE tipopago		CHAR(1)

CASE tipopago
	WHEN 'E'
		DISPLAY 'EFECTIVO' TO tit_tipo_pago
	WHEN 'C'
		DISPLAY 'CHEQUE'   TO tit_tipo_pago
	WHEN 'T'
		DISPLAY 'TRANSFERENCIA' TO tit_tipo_pago
	OTHERWISE
		CLEAR tipo_pago, tit_tipo_pago
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



FUNCTION control_visor_teclas_caracter_2() 
DEFINE a, fila		INTEGER

CALL fl_visor_teclas_caracter() RETURNING fila
LET a = fila + 2
DISPLAY 'Teclas exclusivas de este proceso:' AT a,2 ATTRIBUTE(REVERSE)	
LET a = a + 1
DISPLAY '<F5>      Estado Cuenta'            AT a,2
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
DISPLAY '<F5>      Estado Cuenta'            AT a,2
DISPLAY  'F5' AT a,3 ATTRIBUTE(REVERSE)
LET a = fgl_getkey()
CLOSE WINDOW w_tf

END FUNCTION



FUNCTION chequea_retenciones_hechas(i)
DEFINE num_ret_prev INTEGER
DEFINE resp			CHAR(6)
DEFINE i			INTEGER


	SELECT COUNT(*)INTO num_ret_prev
		FROM cxpt005
		WHERE p05_compania  = vg_codcia
	  	  AND p05_codprov   = rm_docs[i].proveedor

	IF num_ret_prev <> rm_detret[i].cant_ret THEN
		CALL fl_hacer_pregunta('Se han realizado ' || rm_detret[i].cant_ret || ' retenciones por un valor de ' || rm_detret[i].tot_ret || 
                               ', se esperaban ' || num_ret_prev || ' retenciones. Desea continuar?', 'No')
			RETURNING resp
		IF resp = 'No' THEN
			LET int_flag = 1
		END IF
	END IF
	RETURN

END FUNCTION
