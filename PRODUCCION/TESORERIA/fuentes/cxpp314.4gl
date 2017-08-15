--------------------------------------------------------------------------------
-- Titulo           : cxpp314.4gl - Consulta Estado Cuenta Proveedores por Fecha
-- Elaboracion      : 28-Abr-2006
-- Autor            : NPC
-- Formato Ejecucion: fglrun cxpp314 base módulo compañía localidad
--			[moneda] [fecha_cart] [tipo_sal] [valor >= 0.01]
--			[incluir_sal] [proveedor o 0] [fecha_emi o 0]
--			[[fecha_vcto1]] [[fecha_vcto2]]
-- Ultima Correccion: 
-- Motivo Correccion: 
--------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_num_rows	SMALLINT
DEFINE vm_row_current	SMALLINT
DEFINE vm_max_rows	SMALLINT
DEFINE vm_max_doc       SMALLINT
DEFINE vm_num_doc	SMALLINT
DEFINE rm_p01		RECORD LIKE cxpt001.*
DEFINE rm_z60		RECORD LIKE cxct060.*
DEFINE rm_orden 	ARRAY[20] OF CHAR(4)
DEFINE vm_columna_1	SMALLINT
DEFINE vm_columna_2	SMALLINT
DEFINE rm_par  		RECORD
				moneda		LIKE gent013.g13_moneda,
				tit_mon		LIKE gent013.g13_nombre,
				codprov		LIKE cxpt001.p01_codprov,
				nomprov		LIKE cxpt001.p01_nomprov,
				incluir_sal	CHAR(1),
				fecha_emi	DATE,
				fecha_cart	DATE,
				fecha_vcto1	DATE,
				fecha_vcto2	DATE,
				tipo_saldo	CHAR(1),
				valor		DECIMAL(12,2)
			END RECORD
DEFINE rm_rows		ARRAY[32766] OF LIKE cxpt001.p01_codprov
DEFINE rm_dprov 	ARRAY[32766] OF RECORD
				p20_tipo_doc	LIKE cxpt020.p20_tipo_doc,
				num_doc		VARCHAR(18),
				p20_fecha_emi	LIKE cxpt020.p20_fecha_emi,
				p20_fecha_vcto	LIKE cxpt020.p20_fecha_vcto,
				tit_estado	VARCHAR(15),
				dias		INTEGER,
				saldo		DECIMAL(14,2)
			END RECORD
DEFINE rm_rowid 	ARRAY[32766] OF INTEGER
DEFINE vm_muestra_df	SMALLINT
DEFINE tot_sal		DECIMAL(14,2)
DEFINE vm_fecha_ini	DATE
DEFINE num_doc, num_fav	INTEGER
DEFINE rm_cont		ARRAY[32766] OF RECORD
				b13_tipo_comp	LIKE ctbt013.b13_tipo_comp,
				b13_num_comp	LIKE ctbt013.b13_num_comp,
				b13_fec_proceso	LIKE ctbt013.b13_fec_proceso,
				b13_glosa	LIKE ctbt013.b13_glosa,
				val_db		LIKE ctbt013.b13_valor_base,
				val_cr		LIKE ctbt013.b13_valor_base,
				val_db_cr	DECIMAL(14,2)
			END RECORD
DEFINE rm_tes		ARRAY[32766] OF RECORD
				p23_tipo_trn	LIKE cxpt023.p23_tipo_trn,
				p23_num_trn	LIKE cxpt023.p23_num_trn,
				p22_fecha_emi	LIKE cxpt022.p22_fecha_emi,
				p22_referencia	LIKE cxpt022.p22_referencia,
				val_deu		DECIMAL(14,2),
				val_fav		DECIMAL(14,2),
				val_d_f		DECIMAL(14,2)
			END RECORD
DEFINE rm_aux		ARRAY[32766] OF RECORD
				tipo		LIKE cxpt023.p23_tipo_favor,
				codprov		LIKE cxpt023.p23_codprov
			END RECORD
DEFINE vm_num_tes	INTEGER
DEFINE vm_num_con	INTEGER
DEFINE tot_favor 	DECIMAL(14,2)
DEFINE tot_xven  	DECIMAL(14,2)
DEFINE tot_vcdo  	DECIMAL(14,2)
DEFINE tot_saldo 	DECIMAL(14,2)
DEFINE vm_sal_inites 	DECIMAL(14,2)
DEFINE vm_imprimir	CHAR(1)
DEFINE vm_incluir_nc	CHAR(1)



MAIN

DEFER QUIT 
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/cxpp314.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 AND num_args() <> 11 AND num_args() <> 13 THEN
	-- Validar # parámetros correcto
	CALL fl_mostrar_mensaje('Número de parámetros incorrecto.','stop')
	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_codloc  = arg_val(4)
LET vg_proceso = 'cxpp314'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
--#CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL control_master()

END MAIN



FUNCTION control_master()
DEFINE r_g13		RECORD LIKE gent013.*
DEFINE lin_menu		SMALLINT
DEFINE row_ini  	SMALLINT
DEFINE num_rows 	SMALLINT
DEFINE num_cols 	SMALLINT

CALL fl_nivel_isolation()
CALL fl_lee_fecha_carga_cxc(vg_codcia, vg_codloc) RETURNING rm_z60.*
IF rm_z60.z60_compania IS NULL THEN
	CALL fl_mostrar_mensaje('No existe una fecha de carga para este módulo.', 'stop')
	EXIT PROGRAM
END IF
CREATE TEMP TABLE tempo_doc 
	(cladoc		CHAR(2),
	 numdoc		VARCHAR(21),
	 dividendo	SMALLINT,
	 codprov	INTEGER,
	 nomprov	VARCHAR(100),
	 fecha_emi	DATE,
	 fecha_vcto	DATE,
	 valor_doc	DECIMAL(12,2),
	 saldo_doc	DECIMAL(12,2),
	 numero_oc	INTEGER,
	 tipo_doc	CHAR(1),
	 estado_doc	VARCHAR(10),
	 dias_venc	INTEGER,
	 fecha_pago	DATE)
CREATE TEMP TABLE tmp_saldos
	(prov_s		INTEGER,
	 sfav		DECIMAL(12,2),
	 pven		DECIMAL(12,2),
	 venc		DECIMAL(12,2))
CREATE TEMP TABLE tmp_sal_ini 
	(cod_prov_s	INTEGER,
	 saldo_ini_tes	DECIMAL(14,2))
INITIALIZE rm_par.* TO NULL
LET vm_imprimir        = 'R'
LET vm_incluir_nc      = 'S'
LET vm_max_rows	       = 32766
LET vm_max_doc         = 32766
LET rm_par.moneda      = rg_gen.g00_moneda_base
CALL fl_lee_moneda(rm_par.moneda) RETURNING r_g13.*
LET rm_par.tit_mon     = r_g13.g13_nombre
LET rm_par.incluir_sal = 'N'
LET rm_par.tipo_saldo  = 'T'
LET rm_par.valor       = 0.01
LET rm_par.fecha_cart  = TODAY
LET vm_fecha_ini       = rm_z60.z60_fecha_carga
LET lin_menu           = 0
LET row_ini            = 3
LET num_rows           = 22
LET num_cols           = 80
IF vg_gui = 0 THEN
	LET lin_menu = 1
	LET row_ini  = 4
	LET num_rows = 20
	LET num_cols = 78
END IF
OPEN WINDOW w_cxpf314_2 AT row_ini, 2 WITH num_rows ROWS, num_cols COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE lin_menu,
		  BORDER, MESSAGE LINE LAST) 
IF vg_gui = 1 THEN
	OPEN FORM f_cxpf314_2 FROM "../forms/cxpf314_2"
ELSE
	OPEN FORM f_cxpf314_2 FROM "../forms/cxpf314_2c"
END IF
DISPLAY FORM f_cxpf314_2
LET vm_num_rows    = 0
LET vm_row_current = 0
LET vm_muestra_df  = 0
CALL muestra_contadores(vm_row_current, vm_num_rows)
CALL muestra_titulos_columnas()
MENU 'OPCIONES'
	BEFORE MENU
		HIDE OPTION 'Avanzar'
		HIDE OPTION 'Retroceder'
		HIDE OPTION 'Detalle'
		HIDE OPTION 'Movimientos'
		HIDE OPTION 'Doc. a Favor'
		HIDE OPTION 'Datos'
		HIDE OPTION 'Tesoreria vs. Cont.'
		HIDE OPTION 'Imprimir'
		IF num_args() <> 4 THEN
			HIDE OPTION 'Consultar'
			CALL llamada_de_otro_programa()
                        SHOW OPTION 'Movimientos'
			SHOW OPTION 'Doc. a Favor'
			SHOW OPTION 'Datos'
			SHOW OPTION 'Imprimir'
			IF vm_num_rows > 1 THEN
        	                SHOW OPTION 'Avanzar'
			END IF
			IF vm_num_doc > 0 THEN
        	        	SHOW OPTION 'Detalle'
	                ELSE
        	        	HIDE OPTION 'Detalle'
	                END IF
			IF rm_par.tipo_saldo = 'T' THEN
				SHOW OPTION 'Tesoreria vs. Cont.'
        	        ELSE
				HIDE OPTION 'Tesoreria vs. Cont.'
	                END IF
			IF vm_muestra_df THEN
				IF vm_num_rows > 0 THEN
					CALL mostrar_documentos_favor(vg_codcia,
							rm_rows[vm_row_current])
				END IF
			END IF
		END IF
	COMMAND KEY('C') 'Consultar'
		CALL control_consulta()
		CALL muestra_titulos_columnas()
		IF vm_num_rows <= 1 THEN
                	SHOW OPTION 'Movimientos'
			SHOW OPTION 'Doc. a Favor'
			SHOW OPTION 'Datos'
			SHOW OPTION 'Imprimir'
			HIDE OPTION 'Avanzar'
			HIDE OPTION 'Retroceder'
			IF vm_num_rows = 0 THEN
                		HIDE OPTION 'Movimientos'
				HIDE OPTION 'Doc. a Favor'
				HIDE OPTION 'Datos'
				HIDE OPTION 'Imprimir'
			END IF
		ELSE
			SHOW OPTION 'Avanzar'
                	SHOW OPTION 'Movimientos'
			SHOW OPTION 'Doc. a Favor'
			SHOW OPTION 'Datos'
			SHOW OPTION 'Imprimir'
		END IF
		IF vm_row_current <= 1 THEN
                        HIDE OPTION 'Retroceder'
                END IF
		IF vm_num_doc > 0 THEN
                	SHOW OPTION 'Detalle'
                ELSE
                	HIDE OPTION 'Detalle'
                END IF
		IF rm_par.tipo_saldo = 'T' AND vm_num_rows > 0 THEN
			SHOW OPTION 'Tesoreria vs. Cont.'
                ELSE
			HIDE OPTION 'Tesoreria vs. Cont.'
                END IF
		IF vm_muestra_df THEN
			IF vm_num_rows > 0 THEN
				CALL mostrar_documentos_favor(vg_codcia,
							rm_rows[vm_row_current])
			END IF
		END IF
	COMMAND KEY('A') 'Avanzar'
		CALL muestra_siguiente_registro()
		IF vm_row_current = vm_num_rows THEN
			HIDE OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
			NEXT OPTION 'Retroceder'
		ELSE
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
		END IF
		IF vm_num_doc > 0 THEN
                        SHOW OPTION 'Detalle'
                ELSE
                        HIDE OPTION 'Detalle'
                END IF
	COMMAND KEY('R') 'Retroceder'
		CALL muestra_anterior_registro()
		IF vm_row_current = 1 THEN
			HIDE OPTION 'Retroceder'
			SHOW OPTION 'Avanzar'
			NEXT OPTION 'Avanzar'
		ELSE
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
		END IF
		IF vm_num_doc > 0 THEN
                        SHOW OPTION 'Detalle'
                ELSE
                        HIDE OPTION 'Detalle'
                END IF
	COMMAND KEY('D') 'Detalle' 'Ir al detalle de documentos.'
		IF vm_num_doc > 0 THEN
			CALL ubicarse_en_detalle()
		END IF
	COMMAND KEY('M') 'Movimientos' 'Ver detalle de pagos.'
		IF vm_num_rows > 0 THEN
			CALL mostrar_movimientos_proveedor(vg_codcia,
				rm_rows[vm_row_current], rm_par.moneda)
		END IF
	COMMAND KEY('F') 'Doc. a Favor'
		IF vm_num_rows > 0 THEN
			CALL mostrar_documentos_favor(vg_codcia,
							rm_rows[vm_row_current])
		END IF
	COMMAND KEY('T') 'Datos'
		IF vm_row_current > 0 THEN
			CALL ver_datos_proveedor(rm_rows[vm_row_current])
		END IF
	COMMAND KEY('B') 'Tesoreria vs. Cont.' 
		IF vm_row_current > 0 THEN
			CALL tesoreria_vs_contabilidad(rm_rows[vm_row_current])
		END IF
	COMMAND KEY('I') 'Imprimir'
		CALL control_imprimir()
	COMMAND KEY('S') 'Salir'
		EXIT MENU
END MENU

END FUNCTION



FUNCTION llamada_de_otro_programa()
DEFINE r_p01		RECORD LIKE cxpt001.*

LET rm_par.moneda      = arg_val(5)
LET rm_par.fecha_cart  = arg_val(6)
LET rm_par.tipo_saldo  = arg_val(7)
LET rm_par.valor       = arg_val(8)
LET rm_par.incluir_sal = arg_val(9)
LET rm_par.codprov     = arg_val(10)
LET rm_par.fecha_emi   = NULL
IF arg_val(11) <> 0 THEN
	LET rm_par.fecha_emi   = arg_val(11)
END IF
IF num_args() > 11 THEN
	LET rm_par.fecha_vcto1 = arg_val(12)
	LET rm_par.fecha_vcto2 = arg_val(13)
END IF
IF rm_par.codprov = 0 THEN
	LET rm_par.codprov = NULL
END IF
IF rm_par.codprov IS NOT NULL THEN
	CALL fl_lee_proveedor(rm_par.codprov) RETURNING r_p01.*
	IF r_p01.p01_codprov IS NULL THEN
		CALL fl_mostrar_mensaje('No existe codigo de proveedor.','stop')
		EXIT PROGRAM
	END IF
	LET rm_par.nomprov = r_p01.p01_nomprov
END IF
IF rm_par.fecha_emi IS NOT NULL THEN
	IF rm_par.fecha_emi >= rm_par.fecha_cart THEN
		CALL fl_mostrar_mensaje('La fecha de emision debe ser menor que la fecha de cartera.', 'stop')
		EXIT PROGRAM
	END IF
END IF
IF rm_par.fecha_vcto1 IS NOT NULL THEN
	IF rm_par.fecha_vcto1 >= rm_par.fecha_vcto2 THEN
		CALL fl_mostrar_mensaje('La fecha de vencimiento inicial debe ser menor que la fecha de vencimiento final.', 'stop')
		EXIT PROGRAM
	END IF
END IF
IF rm_par.valor < 0 THEN
	CALL fl_mostrar_mensaje('El valor de los documentos debe ser mayor a cero.', 'stop')
	EXIT PROGRAM
END IF
CALL generar_consulta()

END FUNCTION



FUNCTION control_consulta()
DEFINE r_g13		RECORD LIKE gent013.*
DEFINE r_p01		RECORD LIKE cxpt001.*
DEFINE r_p02		RECORD LIKE cxpt002.*
DEFINE fec		DATE
DEFINE ini_col	 	SMALLINT
DEFINE num_rows 	SMALLINT
DEFINE num_cols 	SMALLINT

LET ini_col  = 5
LET num_rows = 15
LET num_cols = 73
IF vg_gui = 0 THEN
	LET ini_col  = 4
	LET num_rows = 14
	LET num_cols = 74
END IF
OPEN WINDOW w_cxpf314_1 AT 06, ini_col WITH num_rows ROWS, num_cols COLUMNS
		ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_cxpf314_1 FROM "../forms/cxpf314_1"
ELSE
	OPEN FORM f_cxpf314_1 FROM "../forms/cxpf314_1c"
END IF
DISPLAY FORM f_cxpf314_1
IF vg_gui = 0 THEN
	CALL muestra_tiposaldo(rm_par.tipo_saldo)
END IF
LET int_flag = 0
INPUT BY NAME rm_par.*
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		LET int_flag = 1
		EXIT INPUT
       	ON KEY(F1,CONTROL-W)
		CALL llamar_visor_teclas()
	ON KEY(F2)
		IF INFIELD(moneda) THEN
			CALL fl_ayuda_monedas()
				RETURNING r_g13.g13_moneda, r_g13.g13_nombre,
					  r_g13.g13_decimales
			IF r_g13.g13_moneda IS NOT NULL THEN
				LET rm_par.moneda  = r_g13.g13_moneda
				LET rm_par.tit_mon = r_g13.g13_nombre
				DISPLAY BY NAME rm_par.moneda, rm_par.tit_mon
			END IF
		END IF
		IF INFIELD(codprov) THEN
			CALL fl_ayuda_proveedores_localidad(vg_codcia,vg_codloc)
					RETURNING r_p01.p01_codprov,
						  r_p01.p01_nomprov
			IF r_p01.p01_codprov IS NOT NULL THEN
				LET rm_par.codprov = r_p01.p01_codprov
				LET rm_par.nomprov = r_p01.p01_nomprov
				DISPLAY BY NAME rm_par.codprov, rm_par.nomprov
			END IF
		END IF
               	LET int_flag = 0
	BEFORE INPUT
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
	BEFORE FIELD fecha_cart
		LET fec = rm_par.fecha_cart
	AFTER FIELD moneda
		IF rm_par.moneda IS NOT NULL THEN
			CALL fl_lee_moneda(rm_par.moneda) RETURNING r_g13.*
			IF r_g13.g13_moneda IS NULL THEN
				CALL fgl_winmessage(vg_producto, 'No existe moneda.', 'exclamation')
				NEXT FIELD moneda
			END IF
			IF r_g13.g13_estado = 'B' THEN
				CALL fl_mensaje_estado_bloqueado()
				NEXT FIELD moneda
			END IF
		ELSE
			LET rm_par.moneda = rg_gen.g00_moneda_base
			CALL fl_lee_moneda(rm_par.moneda) RETURNING r_g13.*
		END IF
		LET rm_par.tit_mon = r_g13.g13_nombre 
		DISPLAY BY NAME rm_par.tit_mon
	AFTER FIELD codprov
		IF rm_par.codprov IS NOT NULL THEN
			CALL fl_lee_proveedor(rm_par.codprov)
				RETURNING r_p01.*
			IF r_p01.p01_codprov IS NULL THEN
				CALL fl_mostrar_mensaje('Proveedor no existe.', 'exclamation')
				NEXT FIELD codprov
			END IF
			LET rm_par.nomprov = r_p01.p01_nomprov
			DISPLAY BY NAME rm_par.nomprov
			CALL fl_lee_proveedor_localidad(vg_codcia, vg_codloc,
							r_p01.p01_codprov)
				RETURNING r_p02.*
			IF r_p02.p02_compania IS NULL THEN
				CALL fl_mostrar_mensaje('Proveedor no está activado para esta Localidad.', 'exclamation')
				NEXT FIELD codprov
			END IF
		ELSE
			LET rm_par.nomprov = NULL
			DISPLAY BY NAME rm_par.nomprov
		END IF
	AFTER FIELD fecha_cart
		IF rm_par.fecha_cart IS NULL THEN
			LET rm_par.fecha_cart = fec
			DISPLAY BY NAME rm_par.fecha_cart
		END IF
		IF rm_par.fecha_cart <= vm_fecha_ini THEN
			CALL fl_mostrar_mensaje('La Fecha de Cartera AL, no puede ser menor a la Fecha de Inicio de las TESORERIA en el FOBOS.', 'exclamation')
			NEXT FIELD fecha_cart
		END IF
	AFTER FIELD fecha_emi
		IF rm_par.fecha_emi IS NOT NULL THEN
			IF rm_par.fecha_emi <= vm_fecha_ini THEN
				CALL fl_mostrar_mensaje('La Fecha Inicial no puede ser menor a la Fecha de Inicio de las TESORERIA en el FOBOS.', 'exclamation')
				NEXT FIELD fecha_emi
			END IF
		END IF
	AFTER FIELD fecha_vcto1
		IF rm_par.fecha_vcto1 IS NOT NULL THEN
			IF rm_par.fecha_vcto1 <= vm_fecha_ini THEN
				CALL fl_mostrar_mensaje('La Fecha de Vencimiento Inicial no puede ser menor a la Fecha de Inicio de las TESORERIA en el FOBOS.', 'exclamation')
				NEXT FIELD fecha_vcto1
			END IF
		END IF
	AFTER FIELD fecha_vcto2
		IF rm_par.fecha_vcto2 IS NOT NULL THEN
			IF rm_par.fecha_vcto2 <= vm_fecha_ini THEN
				CALL fl_mostrar_mensaje('La Fecha de Vencimiento Final no puede ser menor a la Fecha de Inicio de las TESORERIA en el FOBOS.', 'exclamation')
				NEXT FIELD fecha_vcto2
			END IF
		END IF
	AFTER FIELD tipo_saldo
		IF vg_gui = 0 THEN
			IF rm_par.tipo_saldo IS NOT NULL THEN
			       CALL muestra_tiposaldo(rm_par.tipo_saldo)
			ELSE
				CLEAR tit_tipo_saldo
			END IF
		END IF
	AFTER FIELD valor
		IF rm_par.valor < 0 OR rm_par.valor IS NULL THEN
			LET rm_par.valor = 0.01
			DISPLAY BY NAME rm_par.valor
		END IF
	AFTER INPUT
		IF rm_par.fecha_emi IS NOT NULL THEN
			IF rm_par.fecha_emi > rm_par.fecha_cart THEN
				CALL fl_mostrar_mensaje('La Fecha Inicial no puede ser mayor que la Fecha Final.', 'exclamation')
				NEXT FIELD fecha_emi
			END IF
		END IF
		IF rm_par.fecha_vcto1 IS NULL AND rm_par.fecha_vcto2 IS NOT NULL
		THEN
			CALL fl_mostrar_mensaje('Digite fecha de vencimiento inicial.', 'exclamation')
			NEXT FIELD fecha_vcto1
		END IF
		IF rm_par.fecha_vcto1 IS NOT NULL AND rm_par.fecha_vcto2 IS NULL
		THEN
			CALL fl_mostrar_mensaje('Digite fecha de vencimiento final.', 'exclamation')
			NEXT FIELD fecha_vcto2
		END IF
		IF rm_par.fecha_vcto1 IS NOT NULL THEN
			IF rm_par.fecha_vcto1 >= rm_par.fecha_vcto2 THEN
				CALL fl_mostrar_mensaje('La fecha de vencimiento inicial debe ser menor que la fecha de vencimiento final.', 'exclamation')
				NEXT FIELD fecha_vcto1
			END IF
		END IF
		IF rm_par.fecha_emi IS NOT NULL THEN
			IF rm_par.fecha_emi >= rm_par.fecha_vcto1 THEN
				CALL fl_mostrar_mensaje('La fecha de emision debe ser menor que la fecha de vencimiento inicial.', 'exclamation')
				NEXT FIELD fecha_emi
			END IF
		END IF
		IF rm_par.fecha_vcto1 IS NULL AND rm_par.fecha_vcto2 IS NOT NULL
		THEN
			CALL fl_mostrar_mensaje('Digite fecha de vencimiento Inicial.', 'exclamation')
			NEXT FIELD fecha_vcto1
		END IF
		IF rm_par.fecha_vcto1 IS NOT NULL AND rm_par.fecha_vcto2 IS NULL
		THEN
			CALL fl_mostrar_mensaje('Digite fecha de vencimiento final.', 'exclamation')
			NEXT FIELD fecha_vcto2
		END IF
END INPUT
CLOSE WINDOW w_cxpf314_1
IF int_flag THEN
	LET int_flag = 0
	IF vm_row_current > 0 THEN
		CALL mostrar_registro(rm_rows[vm_row_current])
	ELSE
		CLEAR FORM
	END IF
	RETURN
END IF
CALL generar_consulta()

END FUNCTION



FUNCTION generar_consulta()
DEFINE nom_prov		LIKE cxpt001.p01_nomprov

CALL genera_tabla_trabajo_detalle()
IF num_doc = 0 AND num_fav = 0 THEN
	IF num_args() <> 4 THEN
		CALL fl_mensaje_consulta_sin_registros()
		EXIT PROGRAM
	END IF
	RETURN
END IF
CALL genera_tabla_saldos()
DECLARE q_cons CURSOR FOR
	SELECT UNIQUE codprov, nomprov
		FROM tempo_doc
		ORDER BY 2
LET vm_num_rows = 1
FOREACH q_cons INTO rm_rows[vm_num_rows], nom_prov
	LET vm_num_rows = vm_num_rows + 1
        IF vm_num_rows > vm_max_rows THEN
                EXIT FOREACH
        END IF
END FOREACH
LET vm_num_rows = vm_num_rows - 1
IF vm_num_rows = 0 THEN
	LET int_flag = 0
	CALL fl_mensaje_consulta_sin_registros()
	IF num_args() <> 4 THEN
		EXIT PROGRAM
	END IF
	CLEAR FORM
	LET vm_row_current = 0
	LET vm_num_doc     = 0
ELSE  
	LET vm_row_current = 1
	CALL mostrar_registro(rm_rows[vm_row_current])
END IF
CALL muestra_contadores(vm_row_current, vm_num_rows)

END FUNCTION



FUNCTION genera_tabla_trabajo_detalle()

DELETE FROM tempo_doc
ERROR 'Generando consulta . . . espere por favor.' ATTRIBUTE(NORMAL)
LET vm_muestra_df = 0
LET num_doc       = 0
LET num_fav       = 0
IF rm_par.fecha_emi IS NOT NULL THEN
	DELETE FROM tmp_sal_ini
	SELECT p20_codprov cod_prov_s, p20_saldo_cap saldo_ini_tes,
		p20_origen tipo_s
		FROM cxpt020
		WHERE p20_compania = 17
		INTO TEMP tmp_sal_ini2
END IF
CALL obtener_documentos_deudores()
IF num_doc = 0 AND num_args() = 4 THEN
	CALL fl_mostrar_mensaje('No se ha encontrado documentos deudores con saldo.', 'info')
END IF
CALL obtener_documentos_a_favor()
IF num_fav = 0 AND num_args() = 4 THEN
	CALL fl_mostrar_mensaje('No se ha encontrado documentos a favor con saldo.', 'info')
END IF
LET num_doc = num_doc + num_fav
IF rm_par.fecha_emi IS NOT NULL THEN
	INSERT INTO tmp_sal_ini
		SELECT cod_prov_s, NVL(SUM(saldo_ini_tes), 0)
			FROM tmp_sal_ini2
			GROUP BY 1
	DROP TABLE tmp_sal_ini2
END IF

END FUNCTION



FUNCTION obtener_documentos_deudores()
DEFINE query		CHAR(6000)
DEFINE subquery2	CHAR(500)
DEFINE expr1		VARCHAR(100)
DEFINE expr2		VARCHAR(200)

ERROR "Procesando documentos deudores con saldos . . . espere por favor." ATTRIBUTE(NORMAL)
INITIALIZE expr1, expr2 TO NULL
IF rm_par.codprov IS NOT NULL THEN
	LET expr1 = '   AND p20_codprov    = ', rm_par.codprov
END IF
CASE rm_par.tipo_saldo
	WHEN 'V'
		LET expr2 = '   AND p20_fecha_emi  <= "', rm_par.fecha_cart,'"',
			    '   AND p20_fecha_vcto  < "', rm_par.fecha_cart, '"'
	WHEN 'P'
		LET expr2 = '   AND p20_fecha_emi  <= "', rm_par.fecha_cart,'"',
			    '   AND p20_fecha_vcto >= "', rm_par.fecha_cart, '"'
	WHEN 'T'
		LET expr2 = '   AND p20_fecha_emi  <= "', rm_par.fecha_cart, '"'
END CASE
LET query = 'SELECT cxpt020.*, p04_tipo ',
		' FROM cxpt020, cxpt004 ',
		' WHERE p20_compania   = ', vg_codcia,
		'   AND p20_localidad  = ', vg_codloc,
			expr1 CLIPPED,
		'   AND p20_moneda     = "', rm_par.moneda, '"',
			expr2 CLIPPED,
		'   AND p20_valor_cap + p20_valor_int >= ', rm_par.valor,
		'   AND p04_tipo_doc   = p20_tipo_doc ',
		' INTO TEMP tmp_p20 '
PREPARE cons_p20 FROM query
EXECUTE cons_p20
LET subquery2 = ' (SELECT NVL(SUM(p23_valor_cap + p23_valor_int), 0) ',
		' FROM cxpt023 ',
		' WHERE p23_compania  = p20_compania ',
		'   AND p23_localidad = p20_localidad ',
		'   AND p23_codprov   = p20_codprov ',
		'   AND p23_tipo_doc  = p20_tipo_doc ',
		'   AND p23_num_doc   = p20_num_doc ',
		'   AND p23_div_doc   = p20_dividendo) '
LET query = 'INSERT INTO tempo_doc ',
		'SELECT p20_tipo_doc, p20_num_doc, p20_dividendo, p20_codprov,',
			' p01_nomprov, p20_fecha_emi, p20_fecha_vcto,',
			' p20_valor_cap + p20_valor_int,',
			' NVL(', subquery1_sf(1) CLIPPED, ', ',
			' CASE WHEN p20_fecha_emi <= "', vm_fecha_ini, '"',
				' THEN p20_saldo_cap + p20_saldo_int - ',
					subquery2 CLIPPED,
				' ELSE p20_valor_cap + p20_valor_int',
			' END) saldo_mov, ',
			' p20_numero_oc, p04_tipo, ',
			' CASE WHEN p20_fecha_vcto < "', rm_par.fecha_cart, '"',
			' THEN "Vencido" ',
			' WHEN p20_fecha_vcto = "', rm_par.fecha_cart, '"',
			' THEN "Hoy Vence" ',
			' ELSE "Por Vencer" END, ',
			' p20_fecha_vcto - "', rm_par.fecha_cart, '", ',
				subquery1_sf(2) CLIPPED,
		' FROM tmp_p20, cxpt001 ',
		' WHERE p01_codprov = p20_codprov '
PREPARE stmnt1 FROM query
EXECUTE stmnt1
DROP TABLE tmp_p20
LET expr1 = NULL
IF rm_par.incluir_sal = 'N' THEN
	LET expr1 = ' WHERE saldo_doc = 0 '
END IF
LET expr2 = NULL
IF rm_par.fecha_emi IS NOT NULL THEN
	LET expr2 = ' WHERE'
	IF expr1 IS NOT NULL THEN
		LET expr2 = '    OR'
	END IF
	LET expr2 = expr2 CLIPPED, ' fecha_emi  < "', rm_par.fecha_emi, '"'
	INSERT INTO tmp_sal_ini2
		SELECT codprov, NVL(SUM(saldo_doc), 0), 'D'
			FROM tempo_doc
			WHERE fecha_emi < rm_par.fecha_emi
			GROUP BY 1
END IF
IF expr1 IS NOT NULL OR expr2 IS NOT NULL THEN
	LET query = 'DELETE FROM tempo_doc ',
			expr1 CLIPPED,
			expr2 CLIPPED
	PREPARE borrar FROM query
	EXECUTE borrar
END IF
IF rm_par.fecha_vcto1 IS NOT NULL THEN
	LET query = 'SELECT * FROM tempo_doc ',
			' WHERE fecha_vcto BETWEEN "', rm_par.fecha_vcto1,
					    '" AND "', rm_par.fecha_vcto2, '"',
			' INTO TEMP t1'
	PREPARE cons_vcto FROM query
	EXECUTE cons_vcto
	DELETE FROM tempo_doc WHERE 1 = 1
	INSERT INTO tempo_doc SELECT * FROM t1
	DROP TABLE t1
END IF
UPDATE tempo_doc
	SET estado_doc = 'Pagado',
	    dias_venc  = rm_par.fecha_cart - fecha_pago
	WHERE saldo_doc = 0
SELECT COUNT(*) INTO num_doc FROM tempo_doc 
ERROR ' '

END FUNCTION



FUNCTION subquery1_sf(flag)
DEFINE flag		SMALLINT
DEFINE subquery1	CHAR(3000)
DEFINE join_p22p23	CHAR(500)
DEFINE expr		VARCHAR(200)
DEFINE fecha		LIKE cxpt022.p22_fecing

CASE flag
	WHEN 1
		LET expr = 'p23_valor_cap + p23_valor_int + p23_saldo_cap + ',
				'p23_saldo_int '
	WHEN 2
		LET expr = 'p22_fecha_emi '
END CASE
LET fecha = EXTEND(rm_par.fecha_cart, YEAR TO SECOND) + 23 UNITS HOUR +
		59 UNITS MINUTE + 59 UNITS SECOND
LET join_p22p23 = ' FROM cxpt023, cxpt022 ',
			' WHERE p23_compania  = p20_compania ',
			'   AND p23_localidad = p20_localidad ',
			'   AND p23_codprov   = p20_codprov ',
			'   AND p23_tipo_doc  = p20_tipo_doc ',
			'   AND p23_num_doc   = p20_num_doc ',
			'   AND p23_div_doc   = p20_dividendo ',
			'   AND p22_compania  = p23_compania ',
			'   AND p22_localidad = p23_localidad ',
			'   AND p22_codprov   = p23_codprov ',
			'   AND p22_tipo_trn  = p23_tipo_trn ',
			'   AND p22_num_trn   = p23_num_trn '
LET subquery1 = '(SELECT ', expr CLIPPED,
		' FROM cxpt023, cxpt022 ',
		' WHERE p23_compania  = p20_compania ',
		'   AND p23_localidad = p20_localidad ',
		'   AND p23_codprov   = p20_codprov ',
		'   AND p23_tipo_doc  = p20_tipo_doc ',
		'   AND p23_num_doc   = p20_num_doc ',
		'   AND p23_div_doc   = p20_dividendo ',
		'   AND p23_orden     = (SELECT MAX(p23_orden) ',
					join_p22p23 CLIPPED,
					'   AND p22_fecing    = ',
					'(SELECT MAX(p22_fecing) ',
					join_p22p23 CLIPPED,
					'   AND p22_fecing   <= "', fecha,'"))',
		'   AND p22_compania  = p23_compania ',
		'   AND p22_localidad = p23_localidad ',
		'   AND p22_codprov   = p23_codprov ',
		'   AND p22_tipo_trn  = p23_tipo_trn ',
		'   AND p22_num_trn   = p23_num_trn ',
		'   AND p22_fecing    = (SELECT MAX(p22_fecing) ',
					join_p22p23 CLIPPED,
					'   AND p22_fecing   <= "', fecha, '"))'
RETURN subquery1 CLIPPED

END FUNCTION



FUNCTION obtener_documentos_a_favor()
DEFINE fecha		LIKE cxpt022.p22_fecing
DEFINE query		CHAR(6000)
DEFINE subquery1	CHAR(1000)
DEFINE subquery2	CHAR(400)
DEFINE expr1, expr2	VARCHAR(100)
DEFINE sal_ant		DECIMAL(14,2)

ERROR "Procesando documentos a favor con saldos . . . espere por favor." ATTRIBUTE(NORMAL)
INITIALIZE expr1 TO NULL
IF rm_par.codprov IS NOT NULL THEN
	LET expr1 = '   AND p21_codprov    = ', rm_par.codprov
END IF
LET query = 'SELECT cxpt021.*, p04_tipo ',
		' FROM cxpt021, cxpt004 ',
		' WHERE p21_compania   = ', vg_codcia,
		'   AND p21_localidad  = ', vg_codloc,
			expr1 CLIPPED,
		'   AND p21_moneda     = "', rm_par.moneda, '"',
		'   AND p21_valor     >= ', rm_par.valor,
		'   AND p21_fecha_emi <= "', rm_par.fecha_cart, '"',
		'   AND p04_tipo_doc   = p21_tipo_doc ',
		' INTO TEMP tmp_p21 '
PREPARE cons_p21 FROM query
EXECUTE cons_p21
LET fecha = EXTEND(rm_par.fecha_cart, YEAR TO SECOND) + 23 UNITS HOUR +
		59 UNITS MINUTE + 59 UNITS SECOND
LET subquery1 = '(SELECT SUM(p23_valor_cap + p23_valor_int) ',
		' FROM cxpt023, cxpt022 ',
		' WHERE p23_compania   = p21_compania ',
		'   AND p23_localidad  = p21_localidad ',
		'   AND p23_codprov    = p21_codprov ',
		'   AND p23_tipo_favor = p21_tipo_doc ',
		'   AND p23_doc_favor  = p21_num_doc ',
		'   AND p22_compania   = p23_compania ',
		'   AND p22_localidad  = p23_localidad ',
		'   AND p22_codprov    = p23_codprov ',
		'   AND p22_tipo_trn   = p23_tipo_trn ',
		'   AND p22_num_trn    = p23_num_trn ',
		'   AND p22_fecing     BETWEEN EXTEND(p21_fecha_emi, ',
						'YEAR TO SECOND)',
					 ' AND "', fecha, '")'
LET subquery2 = '(SELECT NVL(SUM(p23_valor_cap + p23_valor_int), 0) ',
		' FROM cxpt023 ',
		' WHERE p23_compania   = p21_compania ',
		'   AND p23_localidad  = p21_localidad ',
		'   AND p23_codprov    = p21_codprov ',
		'   AND p23_tipo_favor = p21_tipo_doc ',
		'   AND p23_doc_favor  = p21_num_doc) '
LET query = 'INSERT INTO tempo_doc ',
		'SELECT p21_tipo_doc, p21_num_doc, 0, p21_codprov,',
			' p01_nomprov, p21_fecha_emi, p21_fecha_emi,',
			' p21_valor * (-1), ',
			' NVL(CASE WHEN p21_fecha_emi > "', vm_fecha_ini, '"',
				' THEN p21_valor + ', subquery1 CLIPPED,
				' ELSE ', subquery2 CLIPPED, ' + p21_saldo - ',
					  subquery1 CLIPPED,
			' END, ',
			' CASE WHEN p21_fecha_emi <= "', vm_fecha_ini, '"',
				' THEN p21_saldo - ', subquery2 CLIPPED,
				' ELSE p21_valor',
			' END) * (-1) saldo_mov, ',
			' 0, p04_tipo, "A Favor", 0, TODAY ',
		' FROM tmp_p21, cxpt001 ',
		' WHERE p01_codprov = p21_codprov '
PREPARE stmnt2 FROM query
EXECUTE stmnt2
DROP TABLE tmp_p21
LET expr1 = NULL
IF rm_par.incluir_sal = 'N' THEN
	LET expr1 = '   AND saldo_doc = 0 '
END IF
LET expr2 = NULL
IF rm_par.fecha_emi IS NOT NULL THEN
	LET expr2 = '    OR'
	IF expr1 IS NULL THEN
		LET expr2 = '   AND'
	END IF
	LET expr2 = expr2 CLIPPED, ' fecha_emi < "', rm_par.fecha_emi, '"'
	INSERT INTO tmp_sal_ini2
		SELECT codprov, NVL(SUM(saldo_doc), 0) sal_f, 'F'
			FROM tempo_doc
			WHERE tipo_doc  = "F"
			  AND fecha_emi < rm_par.fecha_emi
			GROUP BY 1
	SELECT NVL(SUM(saldo_ini_tes), 0) INTO sal_ant
		FROM tmp_sal_ini2
		WHERE tipo_s = 'F'
END IF
IF expr1 IS NOT NULL OR expr2 IS NOT NULL THEN
	LET query = 'DELETE FROM tempo_doc ',
			' WHERE tipo_doc   = "F" ',
			expr1 CLIPPED,
			expr2 CLIPPED
	PREPARE borrar2 FROM query
	EXECUTE borrar2
END IF
SELECT COUNT(*) INTO num_fav FROM tempo_doc WHERE tipo_doc = 'F'
ERROR ' '

END FUNCTION



FUNCTION genera_tabla_saldos()
DEFINE query		CHAR(1200)
DEFINE subquery		CHAR(800)

DELETE FROM tmp_saldos
ERROR "Generando saldos . . . espere por favor." ATTRIBUTE(NORMAL)
LET query = 'SELECT codprov prov1, saldo_doc sald1 ',
		' FROM tempo_doc ',
		' WHERE tipo_doc    = "D" ',
		'   AND fecha_vcto >= "', rm_par.fecha_cart, '"',
		'   AND saldo_doc   > 0 ',
		' INTO TEMP t1 '
PREPARE cons_t1 FROM query
EXECUTE	cons_t1
LET query = 'SELECT codprov prov2, saldo_doc sald2 ',
		' FROM tempo_doc ',
		' WHERE tipo_doc   = "D" ',
		'   AND fecha_vcto < "', rm_par.fecha_cart, '"',
		'   AND saldo_doc  > 0 ',
		' INTO TEMP t2 '
PREPARE cons_t2 FROM query
EXECUTE	cons_t2
LET query = 'SELECT codprov prov3, saldo_doc * (-1) sald3 ',
		' FROM tempo_doc ',
		' WHERE tipo_doc  = "F" ',
		'   AND saldo_doc < 0 ',
		' INTO TEMP t3 '
PREPARE cons_t3 FROM query
EXECUTE	cons_t3
LET subquery = '(SELECT NVL(SUM(sald3), 0) ',
			' FROM t3 ',
			' WHERE prov3 = codprov), ',
		'(SELECT NVL(SUM(sald1), 0) ',
			' FROM t1 ',
			' WHERE prov1 = codprov), ',
		'(SELECT NVL(SUM(sald2), 0) ',
			' FROM t2 ',
			' WHERE prov2 = codprov) '
LET query = 'INSERT INTO tmp_saldos ',
		' SELECT codprov, ',
			subquery CLIPPED,
			' FROM tempo_doc '
			--' GROUP BY 1'
PREPARE cons_saldo FROM query
EXECUTE cons_saldo
DROP TABLE t1
DROP TABLE t2
DROP TABLE t3
ERROR " "

END FUNCTION



FUNCTION muestra_titulos_columnas()

--#DISPLAY 'TP'			TO tit_col1
--#DISPLAY 'No. Documento'	TO tit_col2
--#DISPLAY 'Fecha Emi.'		TO tit_col3
--#DISPLAY 'Fecha Vcto'		TO tit_col4
--#DISPLAY 'Estado'		TO tit_col5
--#DISPLAY 'Días'		TO tit_col6
--#DISPLAY 'S a l d o'		TO tit_col7

END FUNCTION



FUNCTION muestra_siguiente_registro()

IF vm_row_current < vm_num_rows THEN
	LET vm_row_current = vm_row_current + 1
END IF
CALL mostrar_registro(rm_rows[vm_row_current])
CALL muestra_contadores(vm_row_current, vm_num_rows)

END FUNCTION



FUNCTION muestra_anterior_registro()

IF vm_row_current > 1 THEN
	LET vm_row_current = vm_row_current - 1
END IF
CALL mostrar_registro(rm_rows[vm_row_current])
CALL muestra_contadores(vm_row_current, vm_num_rows)

END FUNCTION



FUNCTION muestra_contadores(num_cur, max_cur)
DEFINE num_cur, max_cur	SMALLINT

DISPLAY BY NAME num_cur, max_cur

END FUNCTION



FUNCTION mostrar_registro(num_registro)
DEFINE num_registro	LIKE cxpt001.p01_codprov
DEFINE query		CHAR(1200)

ERROR 'Cargando documentos del proveedor. . . espere por favor.' ATTRIBUTE(NORMAL)
IF vm_num_rows <= 0 THEN
	RETURN
END IF
SELECT * INTO rm_p01.* FROM cxpt001 WHERE p01_codprov = num_registro
IF STATUS = NOTFOUND THEN
	CALL fl_mostrar_mensaje('No existe proveedor: ' || num_registro, 'exclamation')
	RETURN
END IF
DISPLAY BY NAME	rm_p01.p01_codprov, rm_p01.p01_nomprov, rm_par.tit_mon,
		rm_p01.p01_direccion1, rm_p01.p01_telefono1,
		rm_p01.p01_telefono2, rm_p01.p01_fax1, rm_par.fecha_emi,
		rm_par.fecha_cart, rm_par.fecha_vcto1, rm_par.fecha_vcto2
CASE rm_p01.p01_estado
	WHEN 'A'
		DISPLAY 'ACTIVO'    TO tit_estprov
	WHEN 'B'
		DISPLAY 'BLOQUEADO' TO tit_estprov
END CASE
LET vm_sal_inites = 0
IF rm_par.fecha_emi IS NOT NULL THEN
	SELECT NVL(saldo_ini_tes, 0) INTO vm_sal_inites
		FROM tmp_sal_ini
		WHERE cod_prov_s = rm_p01.p01_codprov
END IF
LET query = 'SELECT NVL(SUM(sfav), 0) s_f, NVL(SUM(pven), 0) s_p, ',
		' NVL(SUM(venc), 0) s_v, NVL(SUM(pven + venc - sfav), 0) tot ',
		' FROM tmp_saldos ',
		' WHERE prov_s = ', rm_p01.p01_codprov,
		' INTO TEMP t_suma '
PREPARE suma FROM query
EXECUTE suma
SELECT * INTO tot_favor, tot_xven, tot_vcdo, tot_saldo FROM t_suma
DROP TABLE t_suma
LET tot_saldo = tot_saldo + vm_sal_inites
DISPLAY BY NAME tot_favor, tot_xven, tot_vcdo, tot_saldo, vm_sal_inites
IF tot_favor > 0 THEN
	IF tot_xven = 0 AND tot_vcdo = 0 THEN
		LET vm_muestra_df = 1
	ELSE
		LET vm_muestra_df = 0
	END IF
	IF rm_par.tipo_saldo = 'A' THEN
		LET vm_muestra_df = 1
	END IF
END IF
CALL carga_muestra_detalle()
ERROR ' ' ATTRIBUTE(NORMAL)

END FUNCTION



FUNCTION carga_muestra_detalle()
DEFINE i, lim		INTEGER

FOR i = 1 TO vm_max_doc
        INITIALIZE rm_dprov[i].* TO NULL
END FOR
FOR i = 1 TO fgl_scr_size('rm_dprov')
        CLEAR rm_dprov[i].*
END FOR
FOR i = 1 TO 20
	LET rm_orden[i] = '' 
END FOR
LET vm_columna_1 = 9
LET vm_columna_2 = 6
LET rm_orden[9]  = 'DESC'
LET rm_orden[6]  = 'DESC'
CALL cargar_arreglo_principal()
IF vm_num_doc > 0 THEN
        LET lim = vm_num_doc
	IF lim > fgl_scr_size('rm_dprov') THEN
        	LET lim = fgl_scr_size('rm_dprov')
	END IF
        FOR i = 1 TO lim
                DISPLAY rm_dprov[i].* TO rm_dprov[i].*
        END FOR
END IF
DISPLAY BY NAME tot_sal
CALL mostrar_contadores_det(0, vm_num_doc)

END FUNCTION



FUNCTION cargar_arreglo_principal()
DEFINE r_doc		RECORD
				cladoc		LIKE cxpt020.p20_tipo_doc,
				numdoc		LIKE cxpt020.p20_num_doc,
				dividendo	LIKE cxpt020.p20_dividendo,
				codprov		LIKE cxpt020.p20_codprov,
				nomprov		LIKE cxpt001.p01_nomprov,
				fecha_emi	LIKE cxpt020.p20_fecha_emi,
				fecha_vcto	LIKE cxpt020.p20_fecha_vcto,
				valor_doc	LIKE cxpt020.p20_valor_cap,
				saldo_doc	LIKE cxpt020.p20_saldo_cap,
				numero_oc	LIKE cxpt020.p20_numero_oc,
				tipo_doc	LIKE cxpt004.p04_tipo,
				estado_doc	VARCHAR(10),
				dias_venc	INTEGER,
				fecha_pago	LIKE cxpt022.p22_fecha_emi
			END RECORD
DEFINE query		CHAR(1200)
DEFINE numdoc   	VARCHAR(21)
DEFINE ini, lim		SMALLINT

LET query = 'SELECT *, ROWID FROM tempo_doc ',
        	' WHERE codprov   = ', rm_p01.p01_codprov,
	  	'   AND tipo_doc  = "D" ',
		' ORDER BY ', vm_columna_1, ' ', rm_orden[vm_columna_1],
			', ', vm_columna_2, ' ', rm_orden[vm_columna_2] 
PREPARE cxp20 FROM query
DECLARE q_doc CURSOR FOR cxp20
LET tot_sal    = 0
LET vm_num_doc = 1
FOREACH q_doc INTO r_doc.*, rm_rowid[vm_num_doc]
	LET ini    = 2
	LET lim    = LENGTH(r_doc.numdoc)
	IF lim = 1 THEN
		LET ini = 1
	END IF
	LET numdoc = r_doc.numdoc[ini, lim] CLIPPED, '-',
			r_doc.dividendo USING '<<&&'
	LET rm_dprov[vm_num_doc].p20_tipo_doc   = r_doc.cladoc
	LET rm_dprov[vm_num_doc].num_doc        = numdoc
	LET rm_dprov[vm_num_doc].p20_fecha_emi  = r_doc.fecha_emi
	LET rm_dprov[vm_num_doc].p20_fecha_vcto = r_doc.fecha_vcto
	LET rm_dprov[vm_num_doc].tit_estado     = r_doc.estado_doc
	LET rm_dprov[vm_num_doc].dias           = r_doc.dias_venc
	LET rm_dprov[vm_num_doc].saldo          = r_doc.saldo_doc
	LET vm_num_doc                          = vm_num_doc + 1
	LET tot_sal                             = tot_sal + r_doc.saldo_doc
        IF vm_num_doc > vm_max_doc THEN
                EXIT FOREACH
        END IF
END FOREACH
LET vm_num_doc = vm_num_doc - 1

END FUNCTION



FUNCTION mostrar_contadores_det(num_row, max_row)
DEFINE num_row, max_row	SMALLINT

DISPLAY BY NAME num_row, max_row

END FUNCTION



FUNCTION ubicarse_en_detalle()
DEFINE r_aux		RECORD
				codprov		LIKE cxpt020.p20_codprov,
				numdoc		LIKE cxpt020.p20_num_doc,
				dividendo	LIKE cxpt020.p20_dividendo,
				valor_doc	LIKE cxpt020.p20_valor_cap,
				numero_oc	LIKE cxpt020.p20_numero_oc,
				cod_tran	LIKE rept019.r19_cod_tran,
				num_tran	LIKE rept019.r19_num_tran,
				tipo_dev	LIKE rept019.r19_tipo_dev,
				num_dev		LIKE rept019.r19_num_dev
			END RECORD
DEFINE i, col		SMALLINT

WHILE TRUE
	LET int_flag = 0
	CALL set_count(vm_num_doc)
	DISPLAY ARRAY rm_dprov TO rm_dprov.*
		ON KEY(INTERRUPT)
			LET int_flag = 1
			EXIT DISPLAY
        	ON KEY(F1,CONTROL-W)
			CALL control_visor_teclas_caracter_1() 
		ON KEY(F5)
			LET i = arr_curr()
			SELECT numero_oc
				INTO r_aux.numero_oc
				FROM tempo_doc 
				WHERE ROWID = rm_rowid[i]
			IF r_aux.numero_oc IS NULL THEN
				CONTINUE DISPLAY
			END IF
			IF r_aux.numero_oc = 0 THEN
				CONTINUE DISPLAY
			END IF
			IF r_aux.cod_tran IS NULL THEN
				CALL ver_orden_compra(r_aux.numero_oc)
			ELSE
				IF r_aux.tipo_dev IS NULL THEN
					CALL fl_ver_transaccion_rep(vg_codcia,
							vg_codloc,
							r_aux.cod_tran,
							r_aux.num_tran)
				ELSE
					CALL fl_ver_transaccion_rep(vg_codcia,
							vg_codloc,
							r_aux.tipo_dev,
							r_aux.num_dev)
				END IF
			END IF
			LET int_flag = 0
		ON KEY(F6)
			LET i = arr_curr()
			SELECT codprov, numdoc, dividendo
				INTO r_aux.codprov, r_aux.numdoc,r_aux.dividendo
				FROM tempo_doc 
				WHERE ROWID = rm_rowid[i]
			CALL muestra_movimientos_documento_cxp(vg_codcia, 
				r_aux.codprov, rm_dprov[i].p20_tipo_doc,
				r_aux.numdoc, r_aux.dividendo)
			LET int_flag = 0
		ON KEY(F7)
			LET i = arr_curr()
			SELECT codprov, numdoc, dividendo
				INTO r_aux.codprov, r_aux.numdoc,r_aux.dividendo
				FROM tempo_doc 
				WHERE ROWID = rm_rowid[i]
			CALL ver_documento(r_aux.codprov,
					rm_dprov[i].p20_tipo_doc, r_aux.numdoc,
					r_aux.dividendo)
			LET int_flag = 0
		ON KEY(F8)
			IF rm_par.tipo_saldo = 'T' THEN
				CALL tesoreria_vs_contabilidad(
							rm_p01.p01_codprov)
				LET int_flag = 0
			END IF
		ON KEY(F9)
			CALL control_imprimir()
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
			LET col      = 6
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F18)
			LET col      = 7
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F19)
			LET col      = 12
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F20)
			LET col      = 13
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F21)
			LET col      = 9
			LET int_flag = 2
			EXIT DISPLAY
		--#BEFORE ROW
			--#LET i = arr_curr()
			--#SELECT valor_doc, numero_oc, numdoc
				--#INTO r_aux.valor_doc, r_aux.numero_oc,
					--#r_aux.numdoc
				--#FROM tempo_doc 
				--#WHERE ROWID = rm_rowid[i]
			--#MESSAGE '    Valor Original: ', 
			        --#r_aux.valor_doc USING '#,###,###,##&.##'
			--#CALL mostrar_contadores_det(i, vm_num_doc)
			--#INITIALIZE r_aux.cod_tran, r_aux.num_tran,
					--#r_aux.tipo_dev, r_aux.num_dev
				--#TO NULL
			--#SELECT r19_cod_tran, r19_num_tran, r19_tipo_dev,
				--#r19_num_dev
				--#INTO r_aux.cod_tran, r_aux.num_tran,
					--#r_aux.tipo_dev, r_aux.num_dev
				--#FROM rept019
				--#WHERE r19_compania   = vg_codcia
				  --#AND r19_localidad  = vg_codloc
				  --#AND r19_cod_tran   = 'CL'
				  --#AND r19_oc_interna = r_aux.numero_oc
				  --#AND r19_oc_externa = r_aux.numdoc
			--#IF r_aux.cod_tran IS NOT NULL THEN
				--#CALL dialog.keysetlabel("F5","Compra Local")
				--#IF r_aux.tipo_dev IS NOT NULL THEN
					--#CALL dialog.keysetlabel("F5","Dev. Compra Local")
				--#END IF
			--#ELSE
				--#IF r_aux.numero_oc IS NOT NULL AND
					--#r_aux.numero_oc > 0 THEN
					--#CALL dialog.keysetlabel("F5","Orden Compra")
				--#ELSE
					--#CALL dialog.keysetlabel("F5","")
				--#END IF
			--#END IF
		--#BEFORE DISPLAY
			--#CALL dialog.keysetlabel("ACCEPT","")
			--#CALL dialog.keysetlabel("F1","")
			--#CALL dialog.keysetlabel("CONTROL-W","")
			--#IF rm_par.tipo_saldo = 'T' THEN
				--#CALL dialog.keysetlabel("F8","Tesoreria vs. Cont.")
			--#ELSE
				--#CALL dialog.keysetlabel("F8","")
			--#END IF
		--#AFTER DISPLAY
			--#CONTINUE DISPLAY
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
	CALL cargar_arreglo_principal()
END WHILE

END FUNCTION



FUNCTION mostrar_movimientos_proveedor(codcia, codprov, moneda)
DEFINE codcia		LIKE gent001.g01_compania
DEFINE codprov		LIKE cxpt001.p01_codprov
DEFINE moneda		LIKE gent013.g13_moneda
DEFINE r_p01		RECORD LIKE cxpt001.*
DEFINE max_rows, i, col	SMALLINT
DEFINE r_orden		ARRAY[10] OF CHAR(4)
DEFINE columna_1	SMALLINT
DEFINE columna_2	SMALLINT
DEFINE num_rows		SMALLINT
DEFINE tot_pago		DECIMAL(14,2)
DEFINE query		CHAR(1200)
DEFINE dividendo	SMALLINT
DEFINE comando		VARCHAR(200)
DEFINE r_aux		ARRAY[32766] OF RECORD
				tipo		LIKE cxpt023.p23_tipo_favor
			END RECORD
DEFINE r_movc		ARRAY[32766] OF RECORD
				p23_tipo_trn	LIKE cxpt023.p23_tipo_trn,
				p23_num_trn	LIKE cxpt023.p23_num_trn,
				p23_tipo_doc	LIKE cxpt023.p23_tipo_doc,
				num_doc		VARCHAR(18),
				p22_fecha_elim	LIKE cxpt022.p22_fecha_elim,
				p22_fecha_emi	LIKE cxpt022.p22_fecha_emi,
				p22_moneda	LIKE cxpt022.p22_moneda,
				val_pago	DECIMAL(14,2)
			END RECORD
DEFINE num_rows2 	SMALLINT
DEFINE num_cols 	SMALLINT

LET max_rows  = 32766
LET num_rows2 = 18
LET num_cols  = 78
IF vg_gui = 0 THEN
	LET num_rows2 = 16
	LET num_cols  = 76
END IF
OPEN WINDOW w_dmprov AT 06, 02 WITH num_rows2 ROWS, num_cols COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MESSAGE LINE LAST, BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_cxpf305_3 FROM "../forms/cxpf314_3"
ELSE
	OPEN FORM f_cxpf305_3 FROM "../forms/cxpf314_3c"
END IF
DISPLAY FORM f_cxpf305_3
--#DISPLAY 'TP'                  TO tit_col1 
--#DISPLAY 'Número'              TO tit_col2 
--#DISPLAY 'TD'                  TO tit_col3 
--#DISPLAY 'Documento'           TO tit_col4
--#DISPLAY 'Fecha Elim'          TO tit_col5 
--#DISPLAY 'Fecha Pago'          TO tit_col6 
--#DISPLAY 'MO'                  TO tit_col7 
--#DISPLAY 'V a l o r'           TO tit_col8
CALL fl_lee_proveedor(codprov) RETURNING r_p01.*
IF r_p01.p01_codprov IS NULL THEN
	CALL fl_mostrar_mensaje('No existe proveedor: ' || codprov, 'exclamation')
	CLOSE WINDOW w_dmprov
	RETURN
END IF
DISPLAY BY NAME r_p01.p01_codprov, r_p01.p01_nomprov
FOR i = 1 TO 10
	LET r_orden[i] = '' 
END FOR
LET r_orden[6] = 'DESC'
LET columna_1  = 6
LET columna_2  = 1
WHILE TRUE
	LET query = 'SELECT p23_tipo_trn, p23_num_trn, p23_tipo_doc, ',
			' p23_num_doc, p22_fecha_elim, p22_fecha_emi, ',
			' p22_moneda, p23_valor_cap + p23_valor_int, ',
			' p23_div_doc, p23_tipo_favor ',
	        	' FROM cxpt023, cxpt022 ',
			' WHERE p23_compania   = ? ',
			'   AND p23_localidad  = ', vg_codloc,
		      	'   AND p23_codprov    = ? ',
			'   AND p22_compania   = p23_compania ',
			'   AND p22_localidad  = p23_localidad',
			'   AND p22_codprov    = p23_codprov ',
			'   AND p22_tipo_trn   = p23_tipo_trn ',
			'   AND p22_num_trn    = p23_num_trn ',
			'   AND p22_moneda     = ? ',
			'   AND p22_fecha_emi <= "', rm_par.fecha_cart, '" ',
			' ORDER BY ', columna_1, ' ', r_orden[columna_1],
				', ', columna_2, ' ', r_orden[columna_2]
	PREPARE dmprov FROM query
	DECLARE q_dmprov CURSOR FOR dmprov
	LET i        = 1
	LET tot_pago = 0
	OPEN q_dmprov USING codcia, codprov, moneda
	WHILE TRUE
		FETCH q_dmprov INTO r_movc[i].*, dividendo, r_aux[i].*
		IF STATUS = NOTFOUND THEN
			EXIT WHILE
		END IF
		LET r_movc[i].num_doc = r_movc[i].num_doc CLIPPED, 
				        '-', dividendo USING '<<&&'
		LET tot_pago          = tot_pago + r_movc[i].val_pago 
		LET i                 = i + 1
		IF i > max_rows THEN
			EXIT WHILE
		END IF
	END WHILE
	CLOSE q_dmprov
	FREE q_dmprov
	LET num_rows = i - 1
	IF num_rows = 0 THEN
		CALL fl_mostrar_mensaje('Proveedor no tiene movimientos.', 'exclamation')
		CLOSE WINDOW w_dmprov
		RETURN
	END IF
	DISPLAY BY NAME tot_pago
	LET int_flag = 0
	CALL set_count(num_rows)
	DISPLAY ARRAY r_movc TO r_movc.*
		ON KEY(INTERRUPT)
			LET int_flag = 1
			EXIT DISPLAY
        	ON KEY(F1,CONTROL-W)
			CALL control_visor_teclas_caracter_2() 
		ON KEY(F5)
			IF r_movc[i].p23_tipo_trn <> 'PG' THEN
				CONTINUE DISPLAY
			END IF
			LET i = arr_curr()
			CALL muestra_cheque_emitido(codcia, codprov,
							r_movc[i].p23_tipo_trn,
							r_movc[i].p23_num_trn) 
			LET int_flag = 0
		ON KEY(F6)
			LET i = arr_curr()
			CALL ver_documento_tran(codcia, codprov,
				r_movc[i].p23_tipo_trn, r_movc[i].p23_num_trn,
				r_aux[i].tipo)
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
		ON KEY(F20)
			LET col      = 6
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F21)
			LET col      = 7
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F22)
			LET col      = 8
			LET int_flag = 2
			EXIT DISPLAY
		--#BEFORE ROW
			--#LET i = arr_curr()
			--#CALL mostrar_contadores_det(i, num_rows)
			--#IF r_movc[i].p23_tipo_trn <> 'PG' THEN
				--#CALL dialog.keysetlabel("F5","")
			--#ELSE
				--#CALL dialog.keysetlabel("F5","Cheque")
			--#END IF
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
CLOSE WINDOW w_dmprov

END FUNCTION



FUNCTION mostrar_documentos_favor(codcia, codprov)
DEFINE codcia		LIKE gent001.g01_compania
DEFINE codprov		LIKE cxpt001.p01_codprov
DEFINE r_p01		RECORD LIKE cxpt001.*
DEFINE max_rows, i, col	SMALLINT
DEFINE r_orden 		ARRAY[10] OF CHAR(4)
DEFINE columna_1	SMALLINT
DEFINE columna_2	SMALLINT
DEFINE num_rows		SMALLINT
DEFINE tot_valor	DECIMAL(14,2)
DEFINE tot_saldo	DECIMAL(14,2)
DEFINE query		CHAR(1200)
DEFINE r_dda		ARRAY[2000] OF RECORD
				p21_tipo_doc	LIKE cxpt021.p21_tipo_doc,
				p21_num_doc	LIKE cxpt021.p21_num_doc,
				p21_fecha_emi	LIKE cxpt021.p21_fecha_emi,
				p21_valor	LIKE cxpt021.p21_valor,
				p21_saldo	LIKE cxpt021.p21_saldo
			END RECORD
DEFINE num_rows2 	SMALLINT
DEFINE num_cols 	SMALLINT

LET max_rows  = 2000
LET num_rows2 = 16
LET num_cols  = 65
IF vg_gui = 0 THEN
	LET num_rows2 = 15
	LET num_cols  = 66
END IF
OPEN WINDOW w_dda AT 06, 08 WITH num_rows2 ROWS, num_cols COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MESSAGE LINE LAST, BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_cxpf314_4 FROM "../forms/cxpf314_4"
ELSE
	OPEN FORM f_cxpf314_4 FROM "../forms/cxpf314_4c"
END IF
DISPLAY FORM f_cxpf314_4
--#DISPLAY 'Tipo'                TO tit_col1 
--#DISPLAY 'Número'              TO tit_col2 
--#DISPLAY 'Fecha Emi.'          TO tit_col3 
--#DISPLAY 'V a l o r'           TO tit_col4
--#DISPLAY 'S a l d o'           TO tit_col5
CALL fl_lee_proveedor(codprov) RETURNING r_p01.*
IF r_p01.p01_codprov IS NULL THEN
	CALL fl_mostrar_mensaje('No existe proveedor: ' || codprov, 'exclamation')
	CLOSE WINDOW w_dda
	RETURN
END IF
DISPLAY BY NAME r_p01.p01_codprov, r_p01.p01_nomprov
FOR i = 1 TO 10
	LET r_orden[i] = '' 
END FOR
LET r_orden[3] = 'DESC'
LET columna_1  = 3
LET columna_2  = 2
WHILE TRUE
	LET query = 'SELECT cladoc, numdoc, fecha_emi, valor_doc, saldo_doc ',
	        	' FROM tempo_doc ',
			' WHERE codprov   = ? ',
			'   AND tipo_doc  = "F" ',
			' ORDER BY ', columna_1, ' ', r_orden[columna_1],
				', ', columna_2, ' ', r_orden[columna_2]
	PREPARE dda FROM query
	DECLARE q_dda CURSOR FOR dda
	LET i         = 1
	LET tot_valor = 0
	LET tot_saldo = 0
	OPEN q_dda USING codprov
	WHILE TRUE
		FETCH q_dda INTO r_dda[i].*
		IF STATUS = NOTFOUND THEN
			EXIT WHILE
		END IF
		LET tot_valor = tot_valor + r_dda[i].p21_valor 
		LET tot_saldo = tot_saldo + r_dda[i].p21_saldo 
		LET i         = i + 1
		IF i > max_rows THEN
			EXIT WHILE
		END IF
	END WHILE
	CLOSE q_dda
	FREE q_dda
	LET num_rows = i - 1
	IF num_rows = 0 THEN
		CALL fl_mostrar_mensaje('Proveedor no tiene documentos a favor.','exclamation')
		CLOSE WINDOW w_dda
		RETURN
	END IF
	DISPLAY BY NAME tot_valor, tot_saldo
	LET int_flag = 0
	CALL set_count(num_rows)
	DISPLAY ARRAY r_dda TO r_dda.*
		ON KEY(INTERRUPT)
			LET int_flag = 1
			EXIT DISPLAY
        	ON KEY(F1,CONTROL-W)
			CALL control_visor_teclas_caracter_4() 
		ON KEY(F5)
			IF r_dda[i].p21_tipo_doc <> 'PA' THEN
				CONTINUE DISPLAY
			END IF
			LET i = arr_curr()
			CALL muestra_cheque_emitido(codcia, codprov,
							r_dda[i].p21_tipo_doc,
							r_dda[i].p21_num_doc) 
			LET int_flag = 0
		ON KEY(F6)
			LET i = arr_curr()
			CALL ver_documento(codprov, r_dda[i].p21_tipo_doc,
						r_dda[i].p21_num_doc, 0)
			LET int_flag = 0
		ON KEY(F7)
			LET i = arr_curr()
			CALL muestra_movimientos_documento_cxp(codcia,
					codprov, r_dda[i].p21_tipo_doc,
					r_dda[i].p21_num_doc, 0)
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
			--#IF r_dda[i].p21_tipo_doc <> 'PA' THEN
				--#CALL dialog.keysetlabel("F5","")
			--#ELSE
				--#CALL dialog.keysetlabel("F5","Cheque")
			--#END IF
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
CLOSE WINDOW w_dda

END FUNCTION



FUNCTION muestra_movimientos_documento_cxp(codcia, codprov, tipo_doc, num_doc,
						dividendo)
DEFINE codcia		LIKE gent001.g01_compania
DEFINE codprov		LIKE cxpt001.p01_codprov
DEFINE tipo_doc		LIKE cxpt020.p20_tipo_doc
DEFINE num_doc		LIKE cxpt020.p20_num_doc
DEFINE dividendo	LIKE cxpt020.p20_dividendo
DEFINE r_prov		RECORD LIKE cxpt001.*
DEFINE max_rows, i, col	SMALLINT
DEFINE r_orden 		ARRAY[10] OF CHAR(4)
DEFINE columna_1	SMALLINT
DEFINE columna_2	SMALLINT
DEFINE num_rows		SMALLINT
DEFINE tot_pago		DECIMAL(14,2)
DEFINE query		CHAR(1200)
DEFINE expr_sql		VARCHAR(400)
DEFINE r_aux		ARRAY[100] OF RECORD
				tipo		LIKE cxpt023.p23_tipo_favor
			END RECORD
DEFINE r_pdoc		ARRAY[100] OF RECORD
				p23_tipo_trn	LIKE cxpt023.p23_tipo_trn,
				p23_num_trn	LIKE cxpt023.p23_num_trn,
				p22_fecha_emi	LIKE cxpt022.p22_fecha_emi,
				p22_referencia	LIKE cxpt022.p22_referencia,
				val_pago	DECIMAL(14,2)
			END RECORD
DEFINE num_rows2 	SMALLINT
DEFINE num_cols 	SMALLINT
DEFINE expr_fec		VARCHAR(100)
DEFINE fecha1, fecha2	LIKE cxpt022.p22_fecing

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
	OPEN FORM f_movdoc FROM "../forms/cxpf314_5"
ELSE
	OPEN FORM f_movdoc FROM "../forms/cxpf314_6"
END IF
DISPLAY FORM f_movdoc
--#DISPLAY 'TP'                  TO tit_col1 
--#DISPLAY 'Número'              TO tit_col2 
--#DISPLAY 'Fecha Pago'          TO tit_col3
--#DISPLAY 'R e f e r e n c i a' TO tit_col4 
--#DISPLAY 'V a l o r'           TO tit_col5
CALL fl_lee_proveedor(codprov) RETURNING r_prov.*
IF r_prov.p01_codprov IS NULL THEN
	CALL fl_mostrar_mensaje('No existe proveedor: ' || codprov, 'exclamation')
	CLOSE WINDOW w_mdoc
	RETURN
END IF
DISPLAY BY NAME r_prov.p01_codprov, r_prov.p01_nomprov
IF dividendo <> 0 THEN
	CLEAR p23_tipo_doc, p23_num_doc, p23_div_doc
	DISPLAY tipo_doc, num_doc, dividendo
	     TO p23_tipo_doc, p23_num_doc, p23_div_doc
ELSE
	CLEAR p23_tipo_favor, p23_doc_favor
	DISPLAY tipo_doc, num_doc TO p23_tipo_favor, p23_doc_favor
END IF
FOR i = 1 TO 10
	LET r_orden[i] = '' 
END FOR
LET r_orden[3] = 'DESC'
LET columna_1  = 3
LET columna_2  = 1
LET fecha2   = EXTEND(rm_par.fecha_cart, YEAR TO SECOND) + 23 UNITS HOUR +
		59 UNITS MINUTE + 59 UNITS SECOND
LET expr_fec = '   AND p22_fecing    <= "', fecha2, '"'
IF rm_par.fecha_emi IS NOT NULL THEN
	LET fecha1   = EXTEND(rm_par.fecha_emi, YEAR TO SECOND)
	LET expr_fec = '   AND p22_fecing    BETWEEN "', fecha1,
					      '" AND "', fecha2, '"'
END IF
LET expr_sql = '   AND p23_tipo_doc   = ? ',
		'   AND p23_num_doc    = ? ',
		'   AND p23_div_doc    = ? '
IF dividendo = 0 THEN
	LET expr_sql = '   AND p23_tipo_favor = ? ',
			'   AND p23_doc_favor  = ? '
END IF
WHILE TRUE
	LET query = 'SELECT p23_tipo_trn, p23_num_trn, p22_fecha_emi, ',
			'   p22_referencia, p23_valor_cap + p23_valor_int, ',
			'   p23_tipo_favor ',
	        	' FROM cxpt023, cxpt022 ',
			' WHERE p23_compania   = ? ', 
			'   AND p23_localidad  = ', vg_codloc,
		        '   AND p23_codprov    = ? ',
			expr_sql CLIPPED,
			'   AND p22_compania   = p23_compania ',
			'   AND p22_localidad  = p23_localidad ',
			'   AND p22_codprov    = p23_codprov ',
			'   AND p22_tipo_trn   = p23_tipo_trn  ',
			'   AND p22_num_trn    = p23_num_trn ',
			expr_fec CLIPPED,
			' ORDER BY ', columna_1, ' ', r_orden[columna_1],
				', ', columna_2, ' ', r_orden[columna_2]
	PREPARE dpgc FROM query
	DECLARE q_dpgc CURSOR FOR dpgc
	LET i        = 1
	LET tot_pago = 0
	IF dividendo <> 0 THEN
		OPEN q_dpgc USING codcia, codprov, tipo_doc, num_doc, dividendo
	ELSE
		OPEN q_dpgc USING codcia, codprov, tipo_doc, num_doc
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
			CALL muestra_cheque_emitido(codcia, codprov,
							r_pdoc[i].p23_tipo_trn,
							r_pdoc[i].p23_num_trn) 
			LET int_flag = 0
		ON KEY(F6)
			LET i = arr_curr()
			CALL ver_documento_tran(codcia, codprov,
				r_pdoc[i].p23_tipo_trn, r_pdoc[i].p23_num_trn,
				r_aux[i].*)
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



FUNCTION muestra_tiposaldo(tiposaldo)
DEFINE tiposaldo	CHAR(1)

CASE tiposaldo
	WHEN 'A'
		DISPLAY 'A FAVOR' TO tit_tipo_saldo
	WHEN 'P'
		DISPLAY 'POR VENCER' TO tit_tipo_saldo
	WHEN 'V'
		DISPLAY 'VENCIDOS' TO tit_tipo_saldo
	WHEN 'T'
		DISPLAY 'T O D O S' TO tit_tipo_saldo
	OTHERWISE
		CLEAR tipo_saldo, tit_tipo_saldo
END CASE

END FUNCTION



FUNCTION tesoreria_vs_contabilidad(cod_prov)
DEFINE cod_prov		LIKE cxpt001.p01_codprov
DEFINE r_p00		RECORD LIKE cxpt000.*
DEFINE r_p01		RECORD LIKE cxpt001.*
DEFINE fecha1, fecha2	LIKE cxpt022.p22_fecing
DEFINE max_rows, i, col	INTEGER
DEFINE lim, cuantos	INTEGER
DEFINE tot_val_deu	DECIMAL(14,2)
DEFINE tot_val_fav	DECIMAL(14,2)
DEFINE tot_val_db	DECIMAL(14,2)
DEFINE tot_val_cr	DECIMAL(14,2)
DEFINE sal_ini_tes	DECIMAL(14,2)
DEFINE sal_ini_con	DECIMAL(14,2)
DEFINE saldo_cont	DECIMAL(14,2)
DEFINE saldo_tes	DECIMAL(14,2)
DEFINE v_saldo_cont	DECIMAL(14,2)
DEFINE v_saldo_tes	DECIMAL(14,2)
DEFINE val_des		DECIMAL(14,2)
DEFINE query		CHAR(1200)
DEFINE expr_fec		VARCHAR(200)
DEFINE expr_prov1	VARCHAR(100)
DEFINE expr_prov2	VARCHAR(100)
DEFINE num_rows2 	SMALLINT
DEFINE num_cols 	SMALLINT
DEFINE fecha_ini	DATE
DEFINE fecha_fin	DATE
DEFINE fecha_antes	DATE
DEFINE sig_tes, sig_con	SMALLINT
DEFINE p1, p2, p3, p4	INTEGER

LET num_rows2 = 22
LET num_cols  = 80
IF vg_gui = 0 THEN
	LET num_rows2 = 20
	LET num_cols  = 77
END IF
OPEN WINDOW w_tes_cont AT 03, 02 WITH num_rows2 ROWS, num_cols COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MESSAGE LINE LAST, BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_cxpf314_7 FROM "../forms/cxpf314_7"
ELSE
	OPEN FORM f_cxpf314_7 FROM "../forms/cxpf314_7c"
END IF
DISPLAY FORM f_cxpf314_7
--#DISPLAY 'TP'		TO tit_col1 
--#DISPLAY 'Número'	TO tit_col2 
--#DISPLAY 'Fecha Pago'	TO tit_col3
--#DISPLAY 'Referencia'	TO tit_col4
--#DISPLAY 'Deudor'	TO tit_col5
--#DISPLAY 'Acreedor'	TO tit_col6
--#DISPLAY 'Saldo Tes.'	TO tit_col7
--#DISPLAY 'TP'		TO tit_col8 
--#DISPLAY 'Número'	TO tit_col9 
--#DISPLAY 'Fecha'	TO tit_col10
--#DISPLAY 'G l o s a'	TO tit_col11 
--#DISPLAY 'Débito'	TO tit_col12
--#DISPLAY 'Crédito'	TO tit_col13
--#DISPLAY 'Saldo Con.'	TO tit_col14
CALL fl_lee_proveedor(cod_prov) RETURNING r_p01.*
IF r_p01.p01_codprov IS NULL THEN
	CALL fl_mostrar_mensaje('No existe proveedor: ' || cod_prov, 'exclamation')
	CLOSE WINDOW w_tes_cont
	RETURN
END IF
CALL fl_lee_compania_tesoreria(vg_codcia) RETURNING r_p00.*
LET fecha_ini = rm_par.fecha_emi
LET fecha_fin = rm_par.fecha_cart
IF fecha_ini IS NULL THEN
	LET fecha_ini = vm_fecha_ini + 1 UNITS DAY
END IF
LET fecha_antes = fecha_ini - 1 UNITS DAY
SELECT UNIQUE p02_aux_prov_mb cuenta FROM cxpt002 INTO TEMP tmp_cta
SELECT * FROM tmp_cta WHERE cuenta = r_p00.p00_aux_prov_mb
IF STATUS = NOTFOUND THEN
	INSERT INTO tmp_cta VALUES (r_p00.p00_aux_prov_mb)
END IF
{--
INSERT INTO tmp_cta SELECT UNIQUE p02_aux_ant_mb FROM cxpt002
SELECT * FROM tmp_cta WHERE cuenta = r_p00.p00_aux_ant_mb
IF STATUS = NOTFOUND THEN
	INSERT INTO tmp_cta VALUES (r_p00.p00_aux_ant_mb)
END IF
--}
DISPLAY BY NAME r_p01.p01_codprov, r_p01.p01_nomprov
LET expr_prov1 = '   AND p23_codprov     = ', r_p01.p01_codprov
LET expr_prov2 = '   AND b13_codprov     = ', r_p01.p01_codprov
DISPLAY BY NAME fecha_ini, fecha_fin, rm_par.moneda, rm_par.tit_mon
LET fecha2   = EXTEND(rm_par.fecha_cart, YEAR TO SECOND) + 23 UNITS HOUR +
		59 UNITS MINUTE + 59 UNITS SECOND
LET expr_fec = '   AND p22_fecing    <= "', fecha2, '"'
IF rm_par.fecha_emi IS NOT NULL THEN
	LET fecha1   = EXTEND(rm_par.fecha_emi, YEAR TO SECOND)
	LET expr_fec = '   AND p22_fecing    BETWEEN "', fecha1,
					      '" AND "', fecha2, '"'
END IF
ERROR "Procesando Movimientos en Tesoreria . . . espere por favor." ATTRIBUTE(NORMAL)
LET query = 'SELECT p23_tipo_trn, p23_num_trn, p22_fecha_emi, p22_referencia, ',
			' CASE WHEN p23_valor_cap + p23_valor_int > 0 ',
				' THEN p23_valor_cap + p23_valor_int ',
				' ELSE 0 ',
			' END valor_d, ',
			' CASE WHEN p23_valor_cap + p23_valor_int < 0 ',
				' THEN p23_valor_cap + p23_valor_int ',
				' ELSE 0 ',
			' END valor_f, ',
			' p23_valor_cap + p23_valor_int valor_m, ',
			' p23_tipo_favor, p23_codprov ',
	       	' FROM cxpt023, cxpt022 ',
		' WHERE p23_compania   = ', vg_codcia,
		'   AND p23_localidad  = ', vg_codloc,
		expr_prov1 CLIPPED,
		'   AND p22_compania   = p23_compania ',
		'   AND p22_localidad  = p23_localidad ',
		'   AND p22_codprov    = p23_codprov ',
		'   AND p22_tipo_trn   = p23_tipo_trn  ',
		'   AND p22_num_trn    = p23_num_trn ',
		expr_fec CLIPPED,
		' INTO TEMP tmp_mov_tes '
PREPARE exec_p23 FROM query
EXECUTE exec_p23
SELECT COUNT(*) INTO vm_num_tes FROM tmp_mov_tes
LET sal_ini_tes = vm_sal_inites
LET saldo_tes   = tot_sal - tot_favor
IF rm_par.codprov IS NULL THEN
	SELECT NVL(SUM(saldo_doc), 0) INTO saldo_tes
		FROM tempo_doc
		WHERE codprov = r_p01.p01_codprov
	LET saldo_tes = saldo_tes + sal_ini_tes
END IF
LET sig_tes = 0
IF vm_num_tes > 0 THEN
	DISPLAY BY NAME saldo_tes, sal_ini_tes
	LET query = 'SELECT * FROM tmp_mov_tes ORDER BY 3 DESC, 1'
	PREPARE mov_tes2 FROM query
	DECLARE q_mov_tes2 CURSOR FOR mov_tes2
	LET i           = 1
	LET tot_val_deu = 0
	LET tot_val_fav = 0
	FOREACH q_mov_tes2 INTO rm_tes[i].*, rm_aux[i].*
		LET tot_val_deu = tot_val_deu + rm_tes[i].val_deu 
		LET tot_val_fav = tot_val_fav + rm_tes[i].val_fav 
		LET i           = i + 1
		IF i > vm_max_doc THEN
			EXIT FOREACH
		END IF
	END FOREACH
	LET sal_ini_tes = (saldo_tes * (-1) + tot_val_deu + tot_val_fav) * (-1)
	DISPLAY BY NAME sal_ini_tes, tot_val_deu, tot_val_fav
	LET lim = vm_num_tes
	IF lim > fgl_scr_size('rm_tes') THEN
		LET lim = fgl_scr_size('rm_tes')
	END IF
	FOR i = 1 TO lim
		DISPLAY rm_tes[i].* TO rm_tes[i].*
	END FOR
	DISPLAY rm_tes[1].p22_referencia TO tit_referencia
	LET sig_tes = 1
END IF
ERROR "Procesando Movimientos en Contabilidad . . . espere por favor." ATTRIBUTE(NORMAL)
LET query = 'SELECT * FROM ctbt013 ',
		' WHERE b13_compania    = ', vg_codcia,
		'   AND b13_fec_proceso BETWEEN "', vm_fecha_ini,
					 '" AND "', fecha_fin, '"',
		'   AND b13_cuenta     IN (SELECT UNIQUE cuenta FROM tmp_cta) ',
		expr_prov2 CLIPPED,
		' INTO TEMP tmp_b13'
PREPARE exec_b13 FROM query
EXECUTE exec_b13
DROP TABLE tmp_cta
LET query = 'SELECT NVL(SUM(b13_valor_base), 0) saldo_ini ',
		' FROM ctbt012, tmp_b13 ',
		' WHERE b12_compania    = ', vg_codcia,
		'   AND b12_estado      = "M" ',
		'   AND b12_moneda      = "', rm_par.moneda, '"',
		'   AND b13_compania    = b12_compania ',
		'   AND b13_tipo_comp   = b12_tipo_comp ',
		'   AND b13_num_comp    = b12_num_comp ',
		'   AND b13_fec_proceso <= "', fecha_antes, '"',
		' INTO TEMP t_sum'
PREPARE cons_sum2 FROM query
EXECUTE cons_sum2
SELECT * INTO sal_ini_con FROM t_sum
DISPLAY BY NAME sal_ini_con
DROP TABLE t_sum
LET query = 'SELECT b13_tipo_comp, b13_num_comp, b13_fec_proceso, ',
			' b13_glosa, NVL(CASE WHEN b13_valor_base >= 0 THEN ',
			' b13_valor_base END, 0) val_db, ',
			' NVL(CASE WHEN b13_valor_base < 0 THEN ',
			' b13_valor_base END, 0)  val_cr, ',
			' b13_valor_base val_db_cr ',
		' FROM ctbt012, tmp_b13 ',
		' WHERE b12_compania    = ', vg_codcia,
		'   AND b12_estado      = "M" ',
		'   AND b12_moneda      = "', rm_par.moneda, '"',
		'   AND b13_compania    = b12_compania ',
		'   AND b13_tipo_comp   = b12_tipo_comp ',
		'   AND b13_num_comp    = b12_num_comp ',
		'   AND b13_fec_proceso > "', fecha_antes, '"',
		' INTO TEMP tmp_mov_con '
PREPARE exec_b13_1 FROM query
EXECUTE exec_b13_1
SELECT COUNT(*) INTO vm_num_con FROM tmp_mov_con
DROP TABLE tmp_b13
IF vm_num_tes = 0 AND vm_num_con = 0 THEN
	DROP TABLE tmp_mov_tes
	DROP TABLE tmp_mov_con
	CALL fl_mensaje_consulta_sin_registros()
	CLOSE WINDOW w_tes_cont
	RETURN
END IF
IF vm_num_tes > vm_max_doc THEN
	LET vm_num_tes = vm_max_doc
END IF
IF vm_num_con > vm_max_doc THEN
	LET vm_num_con = vm_max_doc
END IF
IF vm_num_tes = vm_max_doc OR vm_num_con > vm_max_doc THEN
	CALL fl_mostrar_mensaje('Solo se mostraran un maximo de ' || vm_max_doc || ' líneas de detalle ya que la aplicación solo soporta esta cantidad.', 'info')
END IF
LET sig_con = 0
IF vm_num_con > 0 THEN
	LET query = 'SELECT * FROM tmp_mov_con ORDER BY 3 DESC, 4'
	PREPARE mov_con2 FROM query
	DECLARE q_mov_con2 CURSOR FOR mov_con2
	LET i          = 1
	LET tot_val_db = 0
	LET tot_val_cr = 0
	FOREACH q_mov_con2 INTO rm_cont[i].*
		LET tot_val_db = tot_val_db + rm_cont[i].val_db 
		LET tot_val_cr = tot_val_cr + rm_cont[i].val_cr 
		LET i          = i + 1
		IF i > vm_max_doc THEN
			EXIT FOREACH
		END IF
	END FOREACH
	IF vm_num_con = vm_max_doc THEN
		SELECT NVL(SUM(val_db), 1), NVL(SUM(val_cr), 0)
			INTO tot_val_db, tot_val_cr
			FROM tmp_mov_con
			WHERE b13_fec_proceso > fecha_antes
	END IF
	LET saldo_cont   = sal_ini_con + tot_val_db + tot_val_cr
	LET v_saldo_cont = saldo_cont
	IF v_saldo_cont < 0 THEN
		LET v_saldo_cont = v_saldo_cont * (-1)
	END IF
	LET v_saldo_tes = saldo_tes
	IF v_saldo_tes < 0 THEN
		LET v_saldo_tes = v_saldo_tes * (-1)
	END IF
	IF saldo_cont > saldo_tes THEN
		LET val_des = v_saldo_cont - v_saldo_tes
	ELSE
		LET val_des = v_saldo_tes - v_saldo_cont
	END IF
	DISPLAY BY NAME tot_val_db, tot_val_cr, saldo_cont, val_des
	LET lim = vm_num_con
	IF lim > fgl_scr_size('rm_cont') THEN
		LET lim = fgl_scr_size('rm_cont')
	END IF
	FOR i = 1 TO lim
		DISPLAY rm_cont[i].* TO rm_cont[i].*
	END FOR
	IF sig_tes = 0 THEN
		LET sig_con = 1
	END IF
	DISPLAY rm_cont[1].b13_glosa TO tit_glosa
END IF
ERROR ' '
CALL mostrar_contadores_tes_con(0, vm_num_tes, 0, vm_num_con)
LET p1 = 1
LET p2 = 1
LET p3 = 1
LET p4 = 1
WHILE TRUE
	IF sig_tes = 1 THEN
		CALL detalle_tesoreria(p1,p2) RETURNING sig_con, p1, p2
	END IF
	IF sig_con = 1 THEN
		CALL detalle_contabilidad(p3, p4) RETURNING sig_tes, p3, p4
	END IF
	IF sig_tes = 0 THEN
		EXIT WHILE
	END IF
	IF sig_con = 0 THEN
		EXIT WHILE
	END IF
END WHILE
DROP TABLE tmp_mov_tes
DROP TABLE tmp_mov_con
CLOSE WINDOW w_tes_cont

END FUNCTION



FUNCTION detalle_tesoreria(pos_pan, pos_arr)
DEFINE pos_pan, pos_arr	INTEGER
DEFINE query		VARCHAR(200)
DEFINE i, col		INTEGER
DEFINE r_orden 		ARRAY[10] OF CHAR(4)
DEFINE columna_1	SMALLINT
DEFINE columna_2	SMALLINT
DEFINE sig_tes		SMALLINT

FOR i = 1 TO 10
	LET r_orden[i] = '' 
END FOR
LET r_orden[3] = 'DESC'
LET columna_1  = 3
LET columna_2  = 1
WHILE TRUE
	LET int_flag = 0
	CALL set_count(vm_num_tes)
	DISPLAY ARRAY rm_tes TO rm_tes.*
		ON KEY(INTERRUPT)
			LET int_flag = 1
			LET sig_tes  = 0
			EXIT DISPLAY
		ON KEY(F5)
			IF vm_num_con = 0 THEN
				CONTINUE DISPLAY
			END IF
			LET int_flag = 1
			LET sig_tes  = 1
			LET pos_pan  = scr_line()
			LET pos_arr  = arr_curr()
			EXIT DISPLAY
		ON KEY(F6)
			LET i = arr_curr()
			CALL muestra_cheque_emitido(vg_codcia,rm_aux[i].codprov,
							rm_tes[i].p23_tipo_trn,
							rm_tes[i].p23_num_trn) 
			LET int_flag = 0
		ON KEY(F7)
			LET i = arr_curr()
			CALL ver_documento_tran(vg_codcia, rm_aux[i].codprov,
				rm_tes[i].p23_tipo_trn, rm_tes[i].p23_num_trn,
				rm_aux[i].tipo)
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
		ON KEY(F20)
			LET col      = 6
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F21)
			LET col      = 7
			LET int_flag = 2
			EXIT DISPLAY
		--#BEFORE ROW
			--#LET i = arr_curr()
			--#CALL mostrar_contadores_tes_con(i, vm_num_tes,
							--#0, vm_num_con)
			--#DISPLAY rm_tes[i].p22_referencia TO tit_referencia
		--#BEFORE DISPLAY
			--#CALL dialog.setcurrline(pos_pan, pos_arr)
			--#CALL mostrar_contadores_tes_con(pos_arr, vm_num_tes,
							--#0, vm_num_con)
			--#DISPLAY rm_tes[pos_arr].p22_referencia TO
				--#tit_referencia
			--#CALL dialog.keysetlabel("ACCEPT","")
			--#CALL dialog.keysetlabel("F1","")
			--#CALL dialog.keysetlabel("F5","Detalle Contabi.")
			--#IF vm_num_con = 0 THEN
				--#CALL dialog.keysetlabel("F5","")
			--#END IF
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
	LET query = 'SELECT * FROM tmp_mov_tes ',
			' ORDER BY ', columna_1, ' ', r_orden[columna_1],
				', ', columna_2, ' ', r_orden[columna_2]
	PREPARE mov_tes3 FROM query
	DECLARE q_mov_tes3 CURSOR FOR mov_tes3
	LET i = 1
	FOREACH q_mov_tes3 INTO rm_tes[i].*, rm_aux[i].*
		LET i = i + 1
		IF i > vm_max_doc THEN
			EXIT FOREACH
		END IF
	END FOREACH
END WHILE
CALL mostrar_contadores_tes_con(0, vm_num_tes, 0, vm_num_con)
RETURN sig_tes, pos_pan, pos_arr

END FUNCTION



FUNCTION detalle_contabilidad(pos_pan, pos_arr)
DEFINE pos_pan, pos_arr	INTEGER
DEFINE query		VARCHAR(200)
DEFINE i, col		INTEGER
DEFINE r_orden 		ARRAY[10] OF CHAR(4)
DEFINE columna_1	SMALLINT
DEFINE columna_2	SMALLINT
DEFINE sig_con		SMALLINT

FOR i = 1 TO 10
	LET r_orden[i] = '' 
END FOR
LET r_orden[3] = 'DESC'
LET columna_1  = 3
LET columna_2  = 4
WHILE TRUE
	LET int_flag = 0
	CALL set_count(vm_num_con)
	DISPLAY ARRAY rm_cont TO rm_cont.*
		ON KEY(INTERRUPT)
			LET int_flag = 1
			LET sig_con  = 0
			EXIT DISPLAY
		ON KEY(F5)
			IF vm_num_tes = 0 THEN
				CONTINUE DISPLAY
			END IF
			LET int_flag = 1
			LET sig_con  = 1
			LET pos_pan  = scr_line()
			LET pos_arr  = arr_curr()
			EXIT DISPLAY
		ON KEY(F8)
			LET i = arr_curr()
			CALL ver_diario_contable(rm_cont[i].b13_tipo_comp,
						rm_cont[i].b13_num_comp)
			LET int_flag = 0
		ON KEY(F22)
			LET col      = 1
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F23)
			LET col      = 2
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F24)
			LET col      = 3
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F25)
			LET col      = 4
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F26)
			LET col      = 5
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F27)
			LET col      = 6
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F28)
			LET col      = 7
			LET int_flag = 2
			EXIT DISPLAY
		--#BEFORE ROW
			--#LET i = arr_curr()
			--#CALL mostrar_contadores_tes_con(0, vm_num_tes,
							--#i, vm_num_con)
			--#DISPLAY rm_cont[i].b13_glosa TO tit_glosa
		--#BEFORE DISPLAY
			--#CALL dialog.setcurrline(pos_pan, pos_arr)
			--#CALL mostrar_contadores_tes_con(0, vm_num_tes,
							--#pos_arr, vm_num_con)
			--#DISPLAY rm_cont[pos_arr].b13_glosa TO tit_glosa
			--#CALL dialog.keysetlabel("ACCEPT","")
			--#CALL dialog.keysetlabel("F1","")
			--#CALL dialog.keysetlabel("F5","Detalle Tesoreria")
			--#IF vm_num_tes = 0 THEN
				--#CALL dialog.keysetlabel("F5","")
			--#END IF
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
	LET query = 'SELECT * FROM tmp_mov_con ',
			' ORDER BY ', columna_1, ' ', r_orden[columna_1],
				', ', columna_2, ' ', r_orden[columna_2]
	PREPARE mov_con3 FROM query
	DECLARE q_mov_con3 CURSOR FOR mov_con3
	LET i = 1
	FOREACH q_mov_con3 INTO rm_cont[i].*
		LET i = i + 1
		IF i > vm_max_doc THEN
			EXIT FOREACH
		END IF
	END FOREACH
END WHILE
CALL mostrar_contadores_tes_con(0, vm_num_tes, 0, vm_num_con)
RETURN sig_con, pos_pan, pos_arr

END FUNCTION



FUNCTION mostrar_contadores_tes_con(num_row_tes, max_row_tes, num_row_con,
					max_row_con)
DEFINE num_row_tes	INTEGER
DEFINE max_row_tes	INTEGER
DEFINE num_row_con	INTEGER
DEFINE max_row_con	INTEGER

DISPLAY BY NAME num_row_tes, max_row_tes, num_row_con, max_row_con

END FUNCTION



FUNCTION ver_orden_compra(numero_oc)
DEFINE numero_oc	LIKE cxpt020.p20_numero_oc
DEFINE comando          VARCHAR(200)

LET comando = 'cd ..', vg_separador, '..', vg_separador, 'COMPRAS',
		vg_separador, 'fuentes', vg_separador, '; fglrun ordp200 ',
		vg_base, ' OC ', vg_codcia, ' ', vg_codloc, ' ', numero_oc
RUN comando

END FUNCTION



FUNCTION ver_datos_proveedor(codprov)
DEFINE codprov		LIKE cxpt001.p01_codprov
DEFINE codloc		LIKE gent002.g02_localidad
DEFINE comando          VARCHAR(200)

LET comando = 'fglrun cxpp101 ', vg_base, ' ', vg_modulo, ' ', vg_codcia, ' ',
		vg_codloc, ' ', codprov
RUN comando

END FUNCTION



FUNCTION ver_documento(codprov, tipodoc, numdoc, dividendo)
DEFINE codprov		LIKE cxpt001.p01_codprov
DEFINE tipodoc		LIKE cxpt020.p20_tipo_doc
DEFINE numdoc		LIKE cxpt020.p20_num_doc
DEFINE dividendo	LIKE cxpt020.p20_dividendo
DEFINE prog		VARCHAR(10)
DEFINE expr		VARCHAR(40)
DEFINE comando          VARCHAR(200)

LET prog = 'cxpp200 '
LET expr = dividendo, ' ', rm_par.fecha_cart
IF dividendo = 0 THEN
	LET prog = 'cxpp201 '
	LET expr = ' ', rm_par.fecha_cart
END IF
LET comando = 'fglrun ', prog CLIPPED, ' ', vg_base, ' ', vg_modulo, ' ',
		vg_codcia, ' ',	vg_codloc, ' ', codprov, ' ', tipodoc, ' ',
		numdoc, ' ', expr CLIPPED
RUN comando

END FUNCTION



FUNCTION ver_documento_tran(codcia, codprov, tipo_trn, num_trn, tipo)
DEFINE codcia		LIKE cxpt022.p22_compania
DEFINE codprov		LIKE cxpt022.p22_codprov
DEFINE tipo_trn		LIKE cxpt022.p22_tipo_trn
DEFINE num_trn		LIKE cxpt022.p22_num_trn
DEFINE tipo		LIKE cxpt023.p23_tipo_favor
DEFINE comando		VARCHAR(200)
DEFINE run_prog		CHAR(10)
DEFINE prog		CHAR(10)

LET run_prog = 'fglrun '
IF vg_gui = 0 THEN
	LET run_prog = 'fglgo '
END IF
LET prog = 'cxpp202 '
IF tipo IS NOT NULL THEN
	LET prog = 'cxpp203 '
END IF
LET comando = run_prog, prog, vg_base, ' ', vg_modulo, ' ', codcia, ' ',
		vg_codloc, ' ', codprov, ' ', tipo_trn, ' ', num_trn
RUN comando

END FUNCTION



FUNCTION ver_diario_contable(tipo_comp, num_comp)
DEFINE tipo_comp	LIKE ctbt013.b13_tipo_comp
DEFINE num_comp		LIKE ctbt013.b13_num_comp
DEFINE comando		VARCHAR(200)
DEFINE run_prog		CHAR(10)

LET run_prog = 'fglrun '
IF vg_gui = 0 THEN
	LET run_prog = 'fglgo '
END IF
LET comando = 'cd ..', vg_separador, '..', vg_separador, 'CONTABILIDAD',
		vg_separador, 'fuentes', vg_separador, '; ', run_prog,
		'ctbp201 ', vg_base, ' "CB" ', vg_codcia, ' ', tipo_comp, ' ',
		num_comp
RUN comando

END FUNCTION



FUNCTION muestra_cheque_emitido(codcia, codprov, tipo_trn, num_trn)
DEFINE codcia		LIKE cxpt024.p24_compania
DEFINE codprov		LIKE cxpt001.p01_codprov
DEFINE tipo_trn		LIKE cxpt022.p22_tipo_trn
DEFINE num_trn		LIKE cxpt022.p22_num_trn
DEFINE r_p24		RECORD LIKE cxpt024.*
DEFINE r_ban		RECORD LIKE gent008.*
DEFINE r_td		RECORD LIKE cxpt004.*
DEFINE r_fav		RECORD LIKE cxpt021.*
DEFINE r_trn		RECORD LIKE cxpt022.*
DEFINE orden_pago	INTEGER

CALL fl_lee_tipo_doc_tesoreria(tipo_trn) RETURNING r_td.*
IF r_td.p04_tipo IS NULL THEN
	RETURN
END IF
LET orden_pago = NULL
IF r_td.p04_tipo = 'F' THEN
	CALL fl_lee_documento_favor_cxp(codcia, vg_codloc, codprov, tipo_trn, 
					num_trn)
		RETURNING r_fav.*
	LET orden_pago = r_fav.p21_orden_pago
ELSE
	CALL fl_lee_transaccion_cxp(codcia, vg_codloc, codprov, tipo_trn, 
					num_trn)
		RETURNING r_trn.*
	LET orden_pago = r_trn.p22_orden_pago
END IF
CALL fl_lee_orden_pago_cxp(codcia, vg_codloc, orden_pago) RETURNING r_p24.*
IF r_p24.p24_orden_pago IS NULL THEN
	RETURN
END IF
OPEN WINDOW w_pch AT 07, 18 WITH 08 ROWS, 49 COLUMNS
	ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, BORDER, MENU LINE 0)
OPEN FORM f_cxpf315_6 FROM "../forms/cxpf315_6"
DISPLAY FORM f_cxpf315_6
IF STATUS = NOTFOUND THEN
	CALL fl_mostrar_mensaje('No existe registro en órdenes de pago.','exclamation')
	CLOSE WINDOW w_pch
	RETURN
END IF
CALL fl_lee_banco_general(r_p24.p24_banco) RETURNING r_ban.*
DISPLAY r_ban.g08_nombre TO banco
DISPLAY BY NAME r_p24.p24_numero_cta, r_p24.p24_numero_che,
		r_p24.p24_tip_contable, r_p24.p24_num_contable
LET int_flag = 0
MENU 'OPCIONES'
	COMMAND KEY('C') 'Diario Contable' 
		CALL ver_diario_contable(r_p24.p24_tip_contable,
					 r_p24.p24_num_contable)
	COMMAND KEY('S') 'Salir'
		EXIT MENU
END MENU
LET int_flag = 0
CLOSE WINDOW w_pch

END FUNCTION



FUNCTION control_imprimir()
DEFINE r_report		RECORD
				tipo_doc	LIKE cxpt020.p20_tipo_doc,
				num_doc		LIKE cxpt020.p20_num_doc,
				dividendo	LIKE cxpt020.p20_dividendo,
				fecha_emi	LIKE cxpt020.p20_fecha_emi,
				fecha_vcto	LIKE cxpt020.p20_fecha_vcto,
				fecha_pago	LIKE cxpt020.p20_fecha_vcto,
				val_ori		LIKE cxpt020.p20_valor_cap,
				saldo		LIKE cxpt020.p20_saldo_cap
			END RECORD
DEFINE r_rep_nc		RECORD
				p21_referencia	LIKE cxpt021.p21_referencia,
				p21_tipo_doc	LIKE cxpt021.p21_tipo_doc,
				p21_num_doc	LIKE cxpt021.p21_num_doc,
				p21_fecha_emi	LIKE cxpt021.p21_fecha_emi,
				p21_valor	LIKE cxpt021.p21_valor,
				p21_saldo	LIKE cxpt021.p21_saldo
			END RECORD
DEFINE aux_i, aux_n	CHAR(1)
DEFINE i, data_found	INTEGER
DEFINE comando		VARCHAR(100)

OPEN WINDOW w_imp AT 07, 25 WITH FORM "../forms/cxpf314_8" 
	ATTRIBUTE(BORDER, COMMENT LINE LAST, FORM LINE FIRST)
LET aux_n    = vm_incluir_nc
LET aux_i    = vm_imprimir
LET int_flag = 0
INPUT BY NAME vm_incluir_nc, vm_imprimir
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		LET int_flag      = 1
		LET vm_incluir_nc = aux_n
		LET vm_imprimir   = aux_i
		EXIT INPUT
END INPUT
CLOSE WINDOW w_imp
IF int_flag THEN
	RETURN
END IF
CALL fl_control_reportes() RETURNING comando
IF int_flag THEN
	LET vm_incluir_nc = aux_n
	LET vm_imprimir   = aux_i
	RETURN
END IF
START REPORT report_estado_cta_proveedor TO PIPE comando
LET data_found = 0
FOR i = 1 TO vm_num_doc
	LET r_report.tipo_doc   = rm_dprov[i].p20_tipo_doc
	SELECT numdoc, dividendo, fecha_pago, valor_doc
		INTO r_report.num_doc, r_report.dividendo, r_report.fecha_pago,
			r_report.val_ori
		FROM tempo_doc 
		WHERE ROWID = rm_rowid[i]
	LET r_report.fecha_emi  = rm_dprov[i].p20_fecha_emi
	LET r_report.fecha_vcto = rm_dprov[i].p20_fecha_vcto
	LET r_report.saldo      = rm_dprov[i].saldo
	LET data_found          = 1
	OUTPUT TO REPORT report_estado_cta_proveedor(r_report.*)
END FOR
FINISH REPORT report_estado_cta_proveedor
IF NOT data_found THEN
	CALL fl_mostrar_mensaje('No se ha encontrado documentos deudores con saldo.', 'info')
END IF
IF vm_incluir_nc = 'N' THEN
	RETURN
END IF
DECLARE q_imp_nc CURSOR FOR
	SELECT p21_referencia, cladoc, numdoc, fecha_emi, valor_doc, saldo_doc
		FROM tempo_doc, cxpt021
		WHERE tipo_doc      = 'F'
		  AND codprov       = rm_p01.p01_codprov
		  AND p21_compania  = vg_codcia
		  AND p21_localidad = vg_codloc
		  AND p21_codprov   = codprov
		  AND p21_tipo_doc  = cladoc
		  AND p21_num_doc   = numdoc
		ORDER BY fecha_emi DESC, numdoc ASC
START REPORT imprimir_doc_a_favor TO PIPE comando
LET data_found = 0
FOREACH q_imp_nc INTO r_rep_nc.*
	OUTPUT TO REPORT imprimir_doc_a_favor(r_rep_nc.*)
	LET data_found = 1
END FOREACH
FINISH REPORT imprimir_doc_a_favor
IF NOT data_found THEN
	CALL fl_mostrar_mensaje('No se ha encontrado documentos a favor con saldo.', 'info')
END IF

END FUNCTION



REPORT report_estado_cta_proveedor(r_report)
DEFINE r_report		RECORD
				tipo_doc	LIKE cxpt020.p20_tipo_doc,
				num_doc		LIKE cxpt020.p20_num_doc,
				dividendo	LIKE cxpt020.p20_dividendo,
				fecha_emi	LIKE cxpt020.p20_fecha_emi,
				fecha_vcto	LIKE cxpt020.p20_fecha_vcto,
				fecha_pago	LIKE cxpt020.p20_fecha_vcto,
				val_ori		LIKE cxpt020.p20_valor_cap,
				saldo		LIKE cxpt020.p20_saldo_cap
			END RECORD
DEFINE r_g01		RECORD LIKE gent001.*
DEFINE r_g50		RECORD LIKE gent050.*
DEFINE num_trn 		VARCHAR(15)
DEFINE expr_sql 	CHAR(1200)
DEFINE expr_doc		VARCHAR(100)
DEFINE usuario		VARCHAR(19,15)
DEFINE titulo		VARCHAR(80)
DEFINE modulo		VARCHAR(40)
DEFINE long		SMALLINT
DEFINE escape		SMALLINT
DEFINE act_comp		SMALLINT
DEFINE desact_comp	SMALLINT

OUTPUT
	TOP    MARGIN	1
	LEFT   MARGIN	0
	RIGHT  MARGIN	132
	BOTTOM MARGIN	4
	PAGE   LENGTH	66

FORMAT

PAGE HEADER
	CALL fl_lee_modulo(vg_modulo) RETURNING r_g50.*
	LET modulo      = 'MODULO: ', r_g50.g50_nombre[1, 19] CLIPPED
	LET long        = LENGTH(modulo)
	LET escape	= 27		# Iniciar sec. impresi¢n
	LET act_comp	= 15		# Activar Comprimido.
	LET desact_comp	= 18		# Cancelar Comprimido.
	LET usuario     = 'USUARIO : ', vg_usuario
	CALL fl_justifica_titulo('D', usuario, 19) RETURNING usuario
	CALL fl_justifica_titulo('C', 'ESTADO DE CUENTAS DE PROVEEDORES', 80)
		RETURNING titulo
	CALL fl_lee_compania(vg_codcia) RETURNING r_g01.*
	print ASCII escape;
	print ASCII act_comp
	PRINT COLUMN 001, r_g01.g01_razonsocial,
	      COLUMN 122, "PAGINA: ", PAGENO USING "&&&"
	PRINT COLUMN 001, modulo CLIPPED,
	      COLUMN 040, titulo,
	      COLUMN 126, UPSHIFT(vg_proceso) CLIPPED
	SKIP 1 LINES
	IF rm_par.fecha_vcto1 IS NULL THEN
		SKIP 1 LINES
	END IF
	IF rm_par.fecha_emi IS NOT NULL THEN
		PRINT COLUMN 001, "DESDE         : ",
			rm_par.fecha_emi USING "dd-mm-yyyy", "  HASTA EL ",
			rm_par.fecha_cart USING "dd-mm-yyyy"
	ELSE
		PRINT COLUMN 001, "     HASTA EL : ",
			rm_par.fecha_cart USING "dd-mm-yyyy"
	END IF
	IF rm_par.fecha_vcto1 IS NOT NULL THEN
		PRINT COLUMN 001, "** RANGO VENCIMIENTOS: ",
			rm_par.fecha_vcto1 USING 'dd-mm-yyyy', ' - ',
			rm_par.fecha_vcto2 USING 'dd-mm-yyyy'
	END IF
	PRINT COLUMN 099, "TOTAL A FAVOR   : ", tot_favor
					USING "-,---,---,--&.##"
	PRINT COLUMN 001, "CODIGO        : ", rm_p01.p01_codprov USING "<<<<&&",
	      COLUMN 099, "TOTAL POR VENCER: ", tot_xven
						USING "-,---,---,--&.##"
	PRINT COLUMN 001, "NOMBRE        : ", rm_p01.p01_nomprov[1, 80] CLIPPED,
	      COLUMN 099, "TOTAL VENCIDO   : ", tot_vcdo
						USING "-,---,---,--&.##"
	PRINT COLUMN 001, "MONEDA        : ", rm_par.tit_mon,
	      COLUMN 099, "S A L D O       : ", tot_saldo
						USING "-,---,---,--&.##"
	SKIP 1 LINES
	PRINT COLUMN 001, "FECHA DE IMPRESION: ", TODAY USING "dd-mm-yyyy", 
	                 1 SPACES, TIME,
	      COLUMN 114, usuario
	PRINT "------------------------------------------------------------------------------------------------------------------------------------"
	PRINT COLUMN 001, "DOCUMENTO",
	      COLUMN 067, "FECHA EMI.",
	      COLUMN 078, "FECHA VCTO",
	      COLUMN 089, "FECHA PAGO",
	      COLUMN 100, "  VALOR ORIGINAL",
	      COLUMN 117, " SALDO DOCUMENTO"
	PRINT "------------------------------------------------------------------------------------------------------------------------------------"

ON EVERY ROW
	NEED 3 LINES
	IF vm_imprimir = 'R' THEN
		LET r_report.fecha_pago = NULL
	END IF
	PRINT COLUMN 001, r_report.tipo_doc, "-", r_report.num_doc CLIPPED, "-",
	      		  r_report.dividendo	USING "<<&&",
	      COLUMN 067, r_report.fecha_emi	USING "dd-mm-yyyy",
	      COLUMN 078, r_report.fecha_vcto	USING "dd-mm-yyyy",
	      COLUMN 089, r_report.fecha_pago	USING "dd-mm-yyyy",
	      COLUMN 100, r_report.val_ori	USING "-,---,---,--&.##",
	      COLUMN 117, r_report.saldo	USING "-,---,---,--&.##"
	IF vm_imprimir = 'D' THEN
		LET expr_doc = "   AND p23_tipo_doc = '", r_report.tipo_doc,"'",
				"   AND p23_num_doc  = '", r_report.num_doc, "'"
		CALL query_mov(expr_doc, 0) RETURNING expr_sql
		PREPARE det FROM expr_sql
		DECLARE q_det CURSOR FOR det 
		FOREACH	q_det INTO r_report.tipo_doc, num_trn,
				r_report.fecha_emi, r_report.fecha_pago,
				r_report.val_ori
			PRINT COLUMN 028, r_report.tipo_doc, "-",
				num_trn CLIPPED,
	      		      COLUMN 067, r_report.fecha_emi
					USING "dd-mm-yyyy",
	      		      COLUMN 089, r_report.fecha_pago
					USING "dd-mm-yyyy",
	      		      COLUMN 100, r_report.val_ori
					USING "-,---,---,--&.##"
		END FOREACH
		SKIP 1 LINES
	END IF

ON LAST ROW
	PRINT COLUMN 117, "----------------"
	PRINT COLUMN 102, "S A L D O  ==> ",
	      COLUMN 117, SUM(r_report.saldo) - tot_favor
			USING "-,---,---,--&.##";
	print ASCII escape;
	print ASCII desact_comp 

END REPORT



REPORT imprimir_doc_a_favor(r_rep_nc)
DEFINE r_rep_nc		RECORD
				p21_referencia	LIKE cxpt021.p21_referencia,
				p21_tipo_doc	LIKE cxpt021.p21_tipo_doc,
				p21_num_doc	LIKE cxpt021.p21_num_doc,
				p21_fecha_emi	LIKE cxpt021.p21_fecha_emi,
				p21_valor	LIKE cxpt021.p21_valor,
				p21_saldo	LIKE cxpt021.p21_saldo
			END RECORD
DEFINE r_g01		RECORD LIKE gent001.*
DEFINE r_g50		RECORD LIKE gent050.*
DEFINE r_p20		RECORD LIKE cxpt020.*
DEFINE fecha_pago	LIKE cxpt022.p22_fecha_emi
DEFINE expr_sql 	CHAR(1200)
DEFINE expr_doc		VARCHAR(100)
DEFINE num_trn 		VARCHAR(15)
DEFINE usuario		VARCHAR(19,15)
DEFINE titulo		VARCHAR(80)
DEFINE modulo		VARCHAR(40)
DEFINE long		SMALLINT
DEFINE escape		SMALLINT
DEFINE act_comp		SMALLINT
DEFINE desact_comp	SMALLINT

OUTPUT
	TOP    MARGIN	1
	LEFT   MARGIN	0
	RIGHT  MARGIN	132
	BOTTOM MARGIN	4
	PAGE   LENGTH	66

FORMAT

PAGE HEADER
	CALL fl_lee_modulo(vg_modulo) RETURNING r_g50.*
	LET modulo      = 'MODULO: ', r_g50.g50_nombre[1, 19] CLIPPED
	LET long        = LENGTH(modulo)
	LET escape	= 27		# Iniciar sec. impresi¢n
	LET act_comp	= 15		# Activar Comprimido.
	LET desact_comp	= 18		# Cancelar Comprimido.
	LET usuario     = 'USUARIO : ', vg_usuario
	CALL fl_justifica_titulo('D', usuario, 19) RETURNING usuario
	CASE vm_imprimir
		WHEN 'R'
			CALL fl_justifica_titulo('C',
						"RESUMEN VALORES A FAVOR", 80)
				RETURNING titulo
		WHEN 'D'
			CALL fl_justifica_titulo('C',
						"DETALLE VALORES A FAVOR", 80)
				RETURNING titulo
	END CASE
	CALL fl_lee_compania(vg_codcia) RETURNING r_g01.*
	print ASCII escape;
	print ASCII act_comp
	PRINT COLUMN 001, r_g01.g01_razonsocial,
	      COLUMN 122, "PAGINA: ", PAGENO USING "&&&"
	PRINT COLUMN 001, modulo CLIPPED,
	      COLUMN 040, titulo,
	      COLUMN 126, UPSHIFT(vg_proceso) CLIPPED
	PRINT COLUMN 069, "-----------------------"
	SKIP 1 LINES
	IF rm_par.fecha_emi IS NOT NULL THEN
		PRINT COLUMN 001, "DESDE         : ",
			rm_par.fecha_emi USING "dd-mm-yyyy", "  HASTA EL ",
			rm_par.fecha_cart USING "dd-mm-yyyy"
	ELSE
		PRINT COLUMN 001, "     HASTA EL : ",
			rm_par.fecha_cart USING "dd-mm-yyyy"
	END IF
	PRINT COLUMN 001, "CODIGO        : ", rm_p01.p01_codprov USING "<<<<&&"
	PRINT COLUMN 001, "NOMBRE        : ", rm_p01.p01_nomprov[1, 80] CLIPPED
	PRINT COLUMN 001, "MONEDA        : ", rm_par.tit_mon,
		      COLUMN 102, "TOTAL A FAVOR: ", tot_favor
						USING "-,---,---,--&.##"
	SKIP 1 LINES
	PRINT COLUMN 001, "FECHA DE IMPRESION: ", TODAY USING "dd-mm-yyyy", 
	                 1 SPACES, TIME,
	      COLUMN 114, usuario
	PRINT "------------------------------------------------------------------------------------------------------------------------------------"
	PRINT COLUMN 009, "R E F E R E N C I A",
	      COLUMN 053, "DOCUMENTO",
	      COLUMN 089, "FECHA EMI.",
	      COLUMN 100, "  VALOR ORIGINAL",
	      COLUMN 117, " SALDO DOCUMENTO"
	PRINT "------------------------------------------------------------------------------------------------------------------------------------"

ON EVERY ROW
	NEED 3 LINES
	PRINT COLUMN 001, r_rep_nc.p21_referencia CLIPPED,
	      COLUMN 053, r_rep_nc.p21_tipo_doc, "-",
			  r_rep_nc.p21_num_doc USING "<<<<<<<<<&",
	      COLUMN 089, r_rep_nc.p21_fecha_emi  USING "dd-mm-yyyy",
	      COLUMN 100, r_rep_nc.p21_valor      USING "-,---,---,--&.##",
	      COLUMN 117, r_rep_nc.p21_saldo      USING "-,---,---,--&.##"
	IF vm_imprimir = 'D' THEN
		LET expr_doc = "   AND p23_tipo_favor = '",
					r_rep_nc.p21_tipo_doc, "'",
				"   AND p23_doc_favor = ",
					r_rep_nc.p21_num_doc
		CALL query_mov(expr_doc, 1) RETURNING expr_sql
		PREPARE det2 FROM expr_sql
		DECLARE q_det2 CURSOR FOR det2
		FOREACH	q_det2 INTO r_rep_nc.p21_tipo_doc, num_trn,
				r_p20.p20_tipo_doc, r_p20.p20_num_doc,
				r_p20.p20_dividendo, r_rep_nc.p21_fecha_emi,
				fecha_pago, r_rep_nc.p21_valor
			PRINT COLUMN 003, "APLIC.: ",
				r_p20.p20_tipo_doc, "-",
				r_p20.p20_num_doc CLIPPED, "-",
				r_p20.p20_dividendo USING "&&",
			      COLUMN 028, r_rep_nc.p21_tipo_doc, "-",
				num_trn CLIPPED,
	      		      COLUMN 067, r_rep_nc.p21_fecha_emi
					USING "dd-mm-yyyy",
      			      COLUMN 089, fecha_pago
					USING "dd-mm-yyyy",
	      		      COLUMN 100, r_rep_nc.p21_valor
					USING "#,###,###,##&.##"
		END FOREACH
		SKIP 1 LINES
	END IF

ON LAST ROW
	PRINT COLUMN 117, "----------------"
	PRINT COLUMN 096, "S A L D O  (N/C) ==> ",
	      COLUMN 117, SUM(r_rep_nc.p21_saldo) USING "-,---,---,--&.##";
	print ASCII escape;
	print ASCII desact_comp 

END REPORT



FUNCTION query_mov(expr_doc, flag)
DEFINE expr_doc		VARCHAR(100)
DEFINE flag		SMALLINT
DEFINE doc_deu		VARCHAR(50)
DEFINE expr_sql 	CHAR(1200)

LET doc_deu = NULL
IF flag THEN
	LET doc_deu = "p23_tipo_doc, p23_num_doc, p23_div_doc, "
END IF
LET expr_sql = "SELECT p23_tipo_trn, p23_num_trn, ", doc_deu CLIPPED,
			" p22_fecha_emi, p22_fecing, p23_valor_cap ",
			" FROM cxpt023, cxpt022 ",
			" WHERE p23_compania   = ", vg_codcia,
			"   AND p23_localidad  = ", vg_codloc,
			"   AND p23_codprov    = ", rm_p01.p01_codprov,
			expr_doc CLIPPED,
			"   AND p22_compania   = p23_compania ",
			"   AND p22_localidad  = p23_localidad ",
			"   AND p22_codprov    = p23_codprov ",
			"   AND p22_tipo_trn   = p23_tipo_trn ",
			"   AND p22_num_trn    = p23_num_trn ",
			"   AND p22_fecha_emi <= '", rm_par.fecha_cart, "'",
			" ORDER BY 1, 2, 3, 4"
RETURN expr_sql CLIPPED

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
DISPLAY '<F5>      Orden Compra'             AT a,2
DISPLAY  'F5' AT a,3 ATTRIBUTE(REVERSE)
LET a = a + 1
DISPLAY '<F6>      Movimientos'              AT a,2
DISPLAY  'F6' AT a,3 ATTRIBUTE(REVERSE)
LET a = a + 1
DISPLAY '<F7>      Documento'                AT a,2
DISPLAY  'F7' AT a,3 ATTRIBUTE(REVERSE)
LET a = a + 1
DISPLAY '<F8>      Imprimir Est. Cta.'       AT a,2
DISPLAY  'F8' AT a,3 ATTRIBUTE(REVERSE)
LET a = fgl_getkey()
CLOSE WINDOW w_tf

END FUNCTION



FUNCTION control_visor_teclas_caracter_2() 
DEFINE a, fila		INTEGER

CALL fl_visor_teclas_caracter() RETURNING fila
LET a = fila + 2
DISPLAY 'Teclas exclusivas de este proceso:' AT a,2 ATTRIBUTE(REVERSE)	
LET a = a + 1
DISPLAY '<F5>      Cheque'                   AT a,2
DISPLAY  'F5' AT a,3 ATTRIBUTE(REVERSE)
LET a = a + 1
DISPLAY '<F6>      Documento'                AT a,2
DISPLAY  'F6' AT a,3 ATTRIBUTE(REVERSE)
LET a = fgl_getkey()
CLOSE WINDOW w_tf

END FUNCTION



FUNCTION control_visor_teclas_caracter_3() 
DEFINE a, fila		INTEGER

CALL fl_visor_teclas_caracter() RETURNING fila
LET a = fila + 2
DISPLAY 'Teclas exclusivas de este proceso:' AT a,2 ATTRIBUTE(REVERSE)	
LET a = a + 1
DISPLAY '<F5>      Documento'                AT a,2
DISPLAY  'F5' AT a,3 ATTRIBUTE(REVERSE)
LET a = fgl_getkey()
CLOSE WINDOW w_tf

END FUNCTION



FUNCTION control_visor_teclas_caracter_4() 
DEFINE a, fila		INTEGER

CALL fl_visor_teclas_caracter() RETURNING fila
LET a = fila + 2
DISPLAY 'Teclas exclusivas de este proceso:' AT a,2 ATTRIBUTE(REVERSE)	
LET a = a + 1
DISPLAY '<F5>      Cheque'                   AT a,2
DISPLAY  'F5' AT a,3 ATTRIBUTE(REVERSE)
LET a = a + 1
DISPLAY '<F6>      Documento'                AT a,2
DISPLAY  'F6' AT a,3 ATTRIBUTE(REVERSE)
LET a = a + 1
DISPLAY '<F7>      Movimientos'              AT a,2
DISPLAY  'F7' AT a,3 ATTRIBUTE(REVERSE)
LET a = fgl_getkey()
CLOSE WINDOW w_tf

END FUNCTION



FUNCTION control_visor_teclas_caracter_5() 
DEFINE a, fila		INTEGER

CALL fl_visor_teclas_caracter() RETURNING fila
LET a = fila + 2
DISPLAY 'Teclas exclusivas de este proceso:' AT a,2 ATTRIBUTE(REVERSE)	
LET a = a + 1
DISPLAY '<F5>      Cheque'                   AT a,2
DISPLAY  'F5' AT a,3 ATTRIBUTE(REVERSE)
LET a = fgl_getkey()
CLOSE WINDOW w_tf

END FUNCTION
