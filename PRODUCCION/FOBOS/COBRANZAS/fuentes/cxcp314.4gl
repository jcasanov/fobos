--------------------------------------------------------------------------------
-- Titulo           : cxcp314.4gl - Consulta Estado Cuenta Clientes por Fecha
-- Elaboracion      : 27-Oct-2005
-- Autor            : NPC
-- Formato Ejecucion: fglrun cxcp314 base módulo compañía localidad
--			[moneda] [fecha_cart] [tipo_sal] [valor >= 0.01]
--			[incluir_sal] [localidad o 0] [cliente o 0]
--			[[fecha_emi]]
-- Ultima Correccion: 
-- Motivo Correccion: 
--------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_num_rows	SMALLINT
DEFINE vm_row_current	SMALLINT
DEFINE vm_max_rows	SMALLINT
DEFINE vm_max_doc       SMALLINT
DEFINE vm_num_doc	SMALLINT
DEFINE rm_z01		RECORD LIKE cxct001.*
DEFINE rm_z60		RECORD LIKE cxct060.*
DEFINE rm_orden 	ARRAY[20] OF CHAR(4)
DEFINE vm_columna_1	SMALLINT
DEFINE vm_columna_2	SMALLINT
DEFINE rm_par  		RECORD
				moneda		LIKE gent013.g13_moneda,
				tit_mon		LIKE gent013.g13_nombre,
				localidad	LIKE gent002.g02_localidad,
				tit_localidad	LIKE gent002.g02_nombre,
				codcli		LIKE cxct001.z01_codcli,
				nomcli		LIKE cxct001.z01_nomcli,
				incluir_sal	CHAR(1),
				fecha_emi	DATE,
				fecha_cart	DATE,
				tipo_saldo	CHAR(1),
				valor		DECIMAL(12,2)
			END RECORD
DEFINE rm_rows		ARRAY[32766] OF LIKE cxct001.z01_codcli
DEFINE rm_dcli 		ARRAY[32766] OF RECORD
				tit_loc		LIKE gent002.g02_localidad,
				tit_area	LIKE cxct020.z20_areaneg,
				z20_tipo_doc	LIKE cxct020.z20_tipo_doc,
				num_doc		VARCHAR(15),
				z20_fecha_emi	LIKE cxct020.z20_fecha_emi,
				z20_fecha_vcto	LIKE cxct020.z20_fecha_vcto,
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
DEFINE rm_cob		ARRAY[32766] OF RECORD
				z23_tipo_trn	LIKE cxct023.z23_tipo_trn,
				z23_num_trn	LIKE cxct023.z23_num_trn,
				z22_fecha_emi	LIKE cxct022.z22_fecha_emi,
				z22_referencia	LIKE cxct022.z22_referencia,
				val_deu		DECIMAL(14,2),
				val_fav		DECIMAL(14,2),
				val_d_f		DECIMAL(14,2)
			END RECORD
DEFINE rm_aux		ARRAY[32766] OF RECORD
				loc		LIKE gent002.g02_localidad,
				tipo		LIKE cxct023.z23_tipo_favor,
				codcli		LIKE cxct023.z23_codcli,
				areaneg		LIKE cxct022.z22_areaneg
			END RECORD
DEFINE vm_num_cob	INTEGER
DEFINE vm_num_con	INTEGER
DEFINE tot_favor 	DECIMAL(14,2)
DEFINE tot_xven  	DECIMAL(14,2)
DEFINE tot_vcdo  	DECIMAL(14,2)
DEFINE tot_saldo 	DECIMAL(14,2)
DEFINE tot_postfec 	DECIMAL(14,2)
DEFINE vm_sal_inicob 	DECIMAL(14,2)
DEFINE vm_imprimir	CHAR(1)
DEFINE vm_incluir_nc	CHAR(1)



MAIN

DEFER QUIT 
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/cxcp314.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 AND num_args() <> 11 AND num_args() <> 12 THEN
	-- Validar # parámetros correcto
	CALL fl_mostrar_mensaje('Número de parámetros incorrecto.','stop')
	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_codloc  = arg_val(4)
LET vg_proceso = 'cxcp314'
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
	(localidad	SMALLINT,
	 area_n		SMALLINT,
	 cladoc		CHAR(2),
	 numdoc		VARCHAR(15),
	 dividendo	SMALLINT,
	 codcli		INTEGER,
	 nomcli		VARCHAR(100),
	 fecha_emi	DATE,
	 fecha_vcto	DATE,
	 valor_doc	DECIMAL(12,2),
	 saldo_doc	DECIMAL(12,2),
	 cod_tran	CHAR(2),
	 num_tran	INTEGER,
	 grupo_lin	CHAR(5),
	 tipo_doc	CHAR(1),
	 estado_doc	VARCHAR(10),
	 dias_venc	INTEGER,
	 fecha_cobro	DATE,
	 doc_sri	VARCHAR(16))
CREATE TEMP TABLE tmp_saldos
	(loc_s		SMALLINT,
	 cli_s		INTEGER,
	 sfav		DECIMAL(12,2),
	 pven		DECIMAL(12,2),
	 venc		DECIMAL(12,2))
CREATE TEMP TABLE tmp_sal_ini 
	(cod_cli_s	INTEGER,
	 saldo_ini_cob	DECIMAL(14,2))
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
OPEN WINDOW w_cxcf314_2 AT row_ini, 2 WITH num_rows ROWS, num_cols COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE lin_menu,
		  BORDER, MESSAGE LINE LAST) 
IF vg_gui = 1 THEN
	OPEN FORM f_cxcf314_2 FROM "../forms/cxcf314_2"
ELSE
	OPEN FORM f_cxcf314_2 FROM "../forms/cxcf314_2c"
END IF
DISPLAY FORM f_cxcf314_2
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
		HIDE OPTION 'Ch. Protestados'
		HIDE OPTION 'Ch. Postfechados'
		HIDE OPTION 'Cobranza vs. Cont.'
		HIDE OPTION 'Imprimir'
		IF num_args() <> 4 THEN
			HIDE OPTION 'Consultar'
			CALL llamada_de_otro_programa()
                        SHOW OPTION 'Movimientos'
			SHOW OPTION 'Doc. a Favor'
			SHOW OPTION 'Datos'
			SHOW OPTION 'Ch. Protestados'
			SHOW OPTION 'Ch. Postfechados'
			SHOW OPTION 'Imprimir'
			IF vm_num_rows > 1 THEN
        	                SHOW OPTION 'Avanzar'
			END IF
			IF vm_num_doc > 0 THEN
        	        	SHOW OPTION 'Detalle'
	                ELSE
        	        	HIDE OPTION 'Detalle'
	                END IF
			IF rm_par.localidad IS NULL AND rm_par.tipo_saldo = 'T'
			THEN
				SHOW OPTION 'Cobranza vs. Cont.'
        	        ELSE
				HIDE OPTION 'Cobranza vs. Cont.'
	                END IF
			IF vm_muestra_df THEN
				IF vm_num_rows > 0 THEN
					CALL mostrar_documentos_favor(vg_codcia,
							rm_par.localidad,
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
			SHOW OPTION 'Ch. Protestados'
			SHOW OPTION 'Ch. Postfechados'
			SHOW OPTION 'Datos'
			SHOW OPTION 'Imprimir'
			HIDE OPTION 'Avanzar'
			HIDE OPTION 'Retroceder'
			IF vm_num_rows = 0 THEN
                		HIDE OPTION 'Movimientos'
				HIDE OPTION 'Doc. a Favor'
				HIDE OPTION 'Ch. Protestados'
				HIDE OPTION 'Ch. Postfechados'
				HIDE OPTION 'Datos'
				HIDE OPTION 'Imprimir'
			END IF
		ELSE
			SHOW OPTION 'Avanzar'
                	SHOW OPTION 'Movimientos'
			SHOW OPTION 'Doc. a Favor'
			SHOW OPTION 'Ch. Protestados'
			SHOW OPTION 'Ch. Postfechados'
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
		IF rm_par.localidad IS NULL AND rm_par.tipo_saldo = 'T' AND
		   vm_num_rows > 0
		THEN
			SHOW OPTION 'Cobranza vs. Cont.'
                ELSE
			HIDE OPTION 'Cobranza vs. Cont.'
                END IF
		IF vm_muestra_df THEN
			IF vm_num_rows > 0 THEN
				CALL mostrar_documentos_favor(vg_codcia,
							rm_par.localidad,
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
			CALL mostrar_movimientos_cliente(vg_codcia,
				rm_par.localidad, rm_rows[vm_row_current],
				rm_par.moneda)
		END IF
	COMMAND KEY('F') 'Doc. a Favor'
		IF vm_num_rows > 0 THEN
			CALL mostrar_documentos_favor(vg_codcia,
							rm_par.localidad,
							rm_rows[vm_row_current])
		END IF
	COMMAND KEY('T') 'Datos'
		IF vm_row_current > 0 THEN
			CALL ver_datos_cliente(rm_rows[vm_row_current])
		END IF
	COMMAND KEY('P') 'Ch. Protestados'
		IF vm_row_current > 0 THEN
			CALL mostrar_cheque_protestados(vg_codcia,
				rm_par.localidad, rm_rows[vm_row_current],
				rm_par.moneda)
		END IF
	COMMAND KEY('X') 'Ch. Postfechados'
		IF vm_row_current > 0 THEN
			CALL mostrar_cheque_postfechados(vg_codcia,
				rm_par.localidad, rm_rows[vm_row_current],
				rm_par.moneda)
		END IF
	COMMAND KEY('B') 'Cobranza vs. Cont.' 
		IF vm_row_current > 0 THEN
			CALL cobranzas_vs_contabilidad(rm_rows[vm_row_current])
		END IF
	COMMAND KEY('I') 'Imprimir'
		CALL control_imprimir()
	COMMAND KEY('S') 'Salir'
		EXIT MENU
END MENU

END FUNCTION



FUNCTION llamada_de_otro_programa()
DEFINE r_g02		RECORD LIKE gent002.*
DEFINE r_z01		RECORD LIKE cxct001.*

LET rm_par.moneda      = arg_val(5)
LET rm_par.fecha_cart  = arg_val(6)
LET rm_par.tipo_saldo  = arg_val(7)
LET rm_par.valor       = arg_val(8)
LET rm_par.incluir_sal = arg_val(9)
LET rm_par.localidad   = arg_val(10)
LET rm_par.codcli      = arg_val(11)
IF num_args() > 11 THEN
	LET rm_par.fecha_emi = arg_val(12)
END IF
IF rm_par.localidad = 0 THEN
	LET rm_par.localidad = NULL
END IF
IF rm_par.codcli = 0 THEN
	LET rm_par.codcli = NULL
END IF
IF rm_par.localidad IS NOT NULL THEN
	CALL fl_lee_localidad(vg_codcia, rm_par.localidad) RETURNING r_g02.*
	IF r_g02.g02_compania IS NULL THEN
		CALL fl_mostrar_mensaje('No existe localidad.', 'stop')
		EXIT PROGRAM
	END IF
	LET rm_par.tit_localidad = r_g02.g02_nombre
END IF
IF rm_par.codcli IS NOT NULL THEN
	CALL fl_lee_cliente_general(rm_par.codcli) RETURNING r_z01.*
	IF r_z01.z01_codcli IS NULL THEN
		CALL fl_mostrar_mensaje('No existe codigo de cliente.', 'stop')
		EXIT PROGRAM
	END IF
	LET rm_par.nomcli = r_z01.z01_nomcli
END IF
IF rm_par.fecha_emi IS NOT NULL THEN
	IF rm_par.fecha_emi >= rm_par.fecha_cart THEN
		CALL fl_mostrar_mensaje('La fecha de emision debe ser menor que la fecha de cartera.', 'stop')
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
DEFINE r_g02		RECORD LIKE gent002.*
DEFINE r_g13		RECORD LIKE gent013.*
DEFINE r_z01		RECORD LIKE cxct001.*
DEFINE r_z02		RECORD LIKE cxct002.*
DEFINE fec		DATE
DEFINE ini_col	 	SMALLINT
DEFINE num_rows 	SMALLINT
DEFINE num_cols 	SMALLINT

LET ini_col  = 5
LET num_rows = 15
LET num_cols = 73
IF vg_gui = 0 THEN
	LET ini_col  = 4
	LET num_rows = 16
	LET num_cols = 74
END IF
OPEN WINDOW w_cxcf314_1 AT 06, ini_col WITH num_rows ROWS, num_cols COLUMNS
		ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_cxcf314_1 FROM "../forms/cxcf314_1"
ELSE
	OPEN FORM f_cxcf314_1 FROM "../forms/cxcf314_1c"
END IF
DISPLAY FORM f_cxcf314_1
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
		IF INFIELD(localidad) THEN
			CALL fl_ayuda_localidad(vg_codcia)
				RETURNING r_g02.g02_localidad, r_g02.g02_nombre
			IF r_g02.g02_localidad IS NOT NULL THEN
				LET rm_par.localidad     = r_g02.g02_localidad
				LET rm_par.tit_localidad = r_g02.g02_nombre
				DISPLAY BY NAME rm_par.localidad,
						rm_par.tit_localidad
			END IF
		END IF
		IF INFIELD(codcli) THEN
			IF rm_par.localidad IS NULL THEN
				CALL fl_ayuda_cliente_general()
					RETURNING r_z01.z01_codcli,
						  r_z01.z01_nomcli
			ELSE
				CALL fl_ayuda_cliente_localidad(vg_codcia,
							rm_par.localidad)
					RETURNING r_z01.z01_codcli,
						  r_z01.z01_nomcli
			END IF
			IF r_z01.z01_codcli IS NOT NULL THEN
				LET rm_par.codcli = r_z01.z01_codcli
				LET rm_par.nomcli = r_z01.z01_nomcli
				DISPLAY BY NAME rm_par.codcli, rm_par.nomcli
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
	AFTER FIELD localidad
		IF rm_par.localidad IS NOT NULL THEN
			CALL fl_lee_localidad(vg_codcia,
						rm_par.localidad)
				RETURNING r_g02.*
			IF r_g02.g02_compania IS NULL THEN
				CALL fl_mostrar_mensaje('Localidad no existe.','exclamation')
				NEXT FIELD localidad
			END IF
			IF r_g02.g02_estado = 'B' THEN
				CALL fl_mensaje_estado_bloqueado()
				NEXT FIELD localidad
			END IF
			LET rm_par.tit_localidad = r_g02.g02_nombre
			DISPLAY BY NAME rm_par.tit_localidad
		ELSE
			LET rm_par.tit_localidad = NULL
			DISPLAY BY NAME rm_par.tit_localidad
		END IF
	AFTER FIELD codcli
		IF rm_par.codcli IS NOT NULL THEN
			CALL fl_lee_cliente_general(rm_par.codcli)
				RETURNING r_z01.*
			IF r_z01.z01_codcli IS NULL THEN
				CALL fl_mostrar_mensaje('Cliente no existe.', 'exclamation')
				NEXT FIELD codcli
			END IF
			LET rm_par.nomcli = r_z01.z01_nomcli
			DISPLAY BY NAME rm_par.nomcli
			IF rm_par.localidad IS NULL THEN
				CONTINUE INPUT
			END IF
			CALL fl_lee_cliente_localidad(vg_codcia,
							rm_par.localidad,
							r_z01.z01_codcli)
				RETURNING r_z02.*
			IF r_z02.z02_compania IS NULL THEN
				CALL fl_mostrar_mensaje('Cliente no está activado para esta Localidad.', 'exclamation')
				NEXT FIELD codcli
			END IF
		ELSE
			LET rm_par.nomcli = NULL
			DISPLAY BY NAME rm_par.nomcli
		END IF
	AFTER FIELD fecha_cart
		IF rm_par.fecha_cart IS NULL THEN
			LET rm_par.fecha_cart = fec
			DISPLAY BY NAME rm_par.fecha_cart
		END IF
	AFTER FIELD fecha_emi
		IF rm_par.fecha_emi IS NOT NULL THEN
			IF rm_par.fecha_emi <= vm_fecha_ini THEN
				CALL fl_mostrar_mensaje('La Fecha Inicial no puede ser menor a la Fecha de Inicio de las COBRANZAS en el FOBOS.', 'exclamation')
				NEXT FIELD fecha_emi
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
END INPUT
CLOSE WINDOW w_cxcf314_1
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
DEFINE nom_cli		LIKE cxct001.z01_nomcli

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
	SELECT UNIQUE codcli, nomcli
		FROM tempo_doc
		ORDER BY 2
LET vm_num_rows = 1
FOREACH q_cons INTO rm_rows[vm_num_rows], nom_cli
	LET vm_num_rows = vm_num_rows + 1
        IF vm_num_rows > vm_max_rows THEN
                EXIT FOREACH
        END IF
END FOREACH
LET vm_num_rows = vm_num_rows - 1
IF vm_num_rows = 0 THEN
	LET int_flag = 0
	CALL fl_mensaje_consulta_sin_registros()
	CLEAR FORM
	LET vm_row_current = 0
	LET vm_num_doc     = 0
	IF num_args() <> 4 THEN
		EXIT PROGRAM
	END IF
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
	SELECT z20_codcli cod_cli_s, z20_saldo_cap saldo_ini_cob,
		z20_origen tipo_s
		FROM cxct020
		WHERE z20_compania = 17
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
		SELECT cod_cli_s, NVL(SUM(saldo_ini_cob), 0)
			FROM tmp_sal_ini2
			GROUP BY 1
	DROP TABLE tmp_sal_ini2
END IF

END FUNCTION



FUNCTION obtener_documentos_deudores()
DEFINE query		CHAR(6000)
DEFINE subquery2	CHAR(500)
DEFINE expr1, expr2	VARCHAR(100)
DEFINE expr3		VARCHAR(200)

ERROR "Procesando documentos deudores con saldos . . . espere por favor." ATTRIBUTE(NORMAL)
INITIALIZE expr1, expr2, expr3 TO NULL
IF rm_par.localidad IS NOT NULL THEN
	LET expr1 = '   AND z20_localidad  = ', rm_par.localidad
END IF
IF rm_par.codcli IS NOT NULL THEN
	LET expr2 = '   AND z20_codcli     = ', rm_par.codcli
END IF
CASE rm_par.tipo_saldo
	WHEN 'V'
		LET expr3 = '   AND z20_fecha_emi  <= "', rm_par.fecha_cart,'"',
			    '   AND z20_fecha_vcto  < "', rm_par.fecha_cart, '"'
	WHEN 'P'
		LET expr3 = '   AND z20_fecha_emi  <= "', rm_par.fecha_cart,'"',
			    '   AND z20_fecha_vcto >= "', rm_par.fecha_cart, '"'
	WHEN 'T'
		LET expr3 = '   AND z20_fecha_emi  <= "', rm_par.fecha_cart, '"'
END CASE
LET query = 'SELECT cxct020.*, z04_tipo ',
		' FROM cxct020, cxct004 ',
		' WHERE z20_compania   = ', vg_codcia,
			expr1 CLIPPED,
			expr2 CLIPPED,
		'   AND z20_moneda     = "', rm_par.moneda, '"',
			expr3 CLIPPED,
		'   AND z20_valor_cap + z20_valor_int >= ', rm_par.valor,
		'   AND z04_tipo_doc   = z20_tipo_doc ',
		' INTO TEMP tmp_z20 '
PREPARE cons_z20 FROM query
EXECUTE cons_z20
LET subquery2 = ' (SELECT NVL(SUM(z23_valor_cap + z23_valor_int), 0) ',
		' FROM cxct023 ',
		' WHERE z23_compania  = z20_compania ',
		'   AND z23_localidad = z20_localidad ',
		'   AND z23_codcli    = z20_codcli ',
		'   AND z23_tipo_doc  = z20_tipo_doc ',
		'   AND z23_num_doc   = z20_num_doc ',
		'   AND z23_div_doc   = z20_dividendo) '
LET query = 'INSERT INTO tempo_doc ',
		'SELECT z20_localidad, z20_areaneg, z20_tipo_doc, z20_num_doc,',
			' z20_dividendo, z20_codcli, z01_nomcli,',
			' z20_fecha_emi, z20_fecha_vcto,',
			' z20_valor_cap + z20_valor_int,',
			' NVL(', subquery1_sf(1) CLIPPED, ', ',
			' CASE WHEN z20_fecha_emi <= "', vm_fecha_ini, '"',
				' THEN z20_saldo_cap + z20_saldo_int - ',
					subquery2 CLIPPED,
				' ELSE z20_valor_cap + z20_valor_int',
			' END) saldo_mov, ',
			' z20_cod_tran, z20_num_tran, z20_linea, z04_tipo, ',
			' CASE WHEN z20_fecha_vcto < "', rm_par.fecha_cart, '"',
			' THEN "Vencido" ',
			' WHEN z20_fecha_vcto = "', rm_par.fecha_cart, '"',
			' THEN "Hoy Vence" ',
			' ELSE "Por Vencer" END, ',
			' z20_fecha_vcto - "', rm_par.fecha_cart, '", ',
				subquery1_sf(2) CLIPPED, ', z20_num_sri ',
		' FROM tmp_z20, gent002, cxct001 ',
		' WHERE g02_compania   = z20_compania ',
		'   AND g02_localidad  = z20_localidad ',
		'   AND z01_codcli     = z20_codcli '
PREPARE stmnt1 FROM query
EXECUTE stmnt1
DROP TABLE tmp_z20
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
		SELECT codcli, NVL(SUM(saldo_doc), 0), 'D'
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
UPDATE tempo_doc
	SET estado_doc = 'Cancelado',
	    dias_venc  = rm_par.fecha_cart - fecha_cobro
	WHERE saldo_doc = 0
	  AND localidad NOT IN (1, 2)
UPDATE tempo_doc
	SET estado_doc = 'Cancelado',
	    dias_venc  = NULL
	WHERE saldo_doc = 0
	  AND localidad IN (1, 2)
SELECT COUNT(*) INTO num_doc FROM tempo_doc 
ERROR ' '

END FUNCTION



FUNCTION subquery1_sf(flag)
DEFINE flag		SMALLINT
DEFINE subquery1	CHAR(1500)
DEFINE expr		VARCHAR(200)
DEFINE fecha		LIKE cxct022.z22_fecing

CASE flag
	WHEN 1
		LET expr = 'z23_valor_cap + z23_valor_int + z23_saldo_cap + ',
				'z23_saldo_int '
	WHEN 2
		LET expr = 'z22_fecha_emi '
END CASE
LET fecha = EXTEND(rm_par.fecha_cart, YEAR TO SECOND) + 23 UNITS HOUR +
		59 UNITS MINUTE + 59 UNITS SECOND
LET subquery1 = '(SELECT ', expr CLIPPED,
		' FROM cxct023, cxct022 ',
		' WHERE z23_compania  = z20_compania ',
		'   AND z23_localidad = z20_localidad ',
		'   AND z23_codcli    = z20_codcli ',
		'   AND z23_tipo_doc  = z20_tipo_doc ',
		'   AND z23_num_doc   = z20_num_doc ',
		'   AND z23_div_doc   = z20_dividendo ',
		'   AND z22_compania  = z23_compania ',
		'   AND z22_localidad = z23_localidad ',
		'   AND z22_codcli    = z23_codcli ',
		'   AND z22_tipo_trn  = z23_tipo_trn ',
		'   AND z22_num_trn   = z23_num_trn ',
		'   AND z22_fecing    = (SELECT MAX(z22_fecing) ',
					' FROM cxct023, cxct022 ',
					' WHERE z23_compania  = z20_compania ',
					'   AND z23_localidad = z20_localidad ',
					'   AND z23_codcli    = z20_codcli ',
					'   AND z23_tipo_doc  = z20_tipo_doc ',
					'   AND z23_num_doc   = z20_num_doc ',
					'   AND z23_div_doc   = z20_dividendo ',
					'   AND z22_compania  = z23_compania ',
					'   AND z22_localidad = z23_localidad ',
					'   AND z22_codcli    = z23_codcli ',
					'   AND z22_tipo_trn  = z23_tipo_trn ',
					'   AND z22_num_trn   = z23_num_trn ',
					'   AND z22_fecing   <= "', fecha, '"))'
RETURN subquery1 CLIPPED

END FUNCTION



FUNCTION obtener_documentos_a_favor()
DEFINE fecha		LIKE cxct022.z22_fecing
DEFINE query		CHAR(6000)
DEFINE subquery1	CHAR(1000)
DEFINE subquery2	CHAR(400)
DEFINE expr1, expr2	VARCHAR(100)
DEFINE expr3		VARCHAR(100)
DEFINE sal_ant		DECIMAL(14,2)

ERROR "Procesando documentos a favor con saldos . . . espere por favor." ATTRIBUTE(NORMAL)
INITIALIZE expr1, expr2 TO NULL
IF rm_par.localidad IS NOT NULL THEN
	LET expr1 = '   AND z21_localidad  = ', rm_par.localidad
END IF
IF rm_par.codcli IS NOT NULL THEN
	LET expr2 = '   AND z21_codcli     = ', rm_par.codcli
END IF
LET query = 'SELECT cxct021.*, z04_tipo ',
		' FROM cxct021, cxct004 ',
		' WHERE z21_compania   = ', vg_codcia,
			expr1 CLIPPED,
			expr2 CLIPPED,
		'   AND z21_moneda     = "', rm_par.moneda, '"',
		'   AND z21_valor     >= ', rm_par.valor,
		'   AND z21_fecha_emi <= "', rm_par.fecha_cart, '"',
		'   AND z04_tipo_doc   = z21_tipo_doc ',
		' INTO TEMP tmp_z21 '
PREPARE cons_z21 FROM query
EXECUTE cons_z21
LET fecha = EXTEND(rm_par.fecha_cart, YEAR TO SECOND) + 23 UNITS HOUR +
		59 UNITS MINUTE + 59 UNITS SECOND
LET subquery1 = '(SELECT SUM(z23_valor_cap + z23_valor_int) ',
		' FROM cxct023, cxct022 ',
		' WHERE z23_compania   = z21_compania ',
		'   AND z23_localidad  = z21_localidad ',
		'   AND z23_codcli     = z21_codcli ',
		'   AND z23_tipo_favor = z21_tipo_doc ',
		'   AND z23_doc_favor  = z21_num_doc ',
		'   AND z22_compania   = z23_compania ',
		'   AND z22_localidad  = z23_localidad ',
		'   AND z22_codcli     = z23_codcli ',
		'   AND z22_tipo_trn   = z23_tipo_trn ',
		'   AND z22_num_trn    = z23_num_trn ',
		'   AND z22_fecing     BETWEEN EXTEND(z21_fecha_emi, ',
						'YEAR TO SECOND)',
					 ' AND "', fecha, '")'
LET subquery2 = '(SELECT NVL(SUM(z23_valor_cap + z23_valor_int), 0) ',
		' FROM cxct023 ',
		' WHERE z23_compania   = z21_compania ',
		'   AND z23_localidad  = z21_localidad ',
		'   AND z23_codcli     = z21_codcli ',
		'   AND z23_tipo_favor = z21_tipo_doc ',
		'   AND z23_doc_favor  = z21_num_doc) '
LET query = 'INSERT INTO tempo_doc ',
		'SELECT z21_localidad, z21_areaneg, z21_tipo_doc, z21_num_doc,',
			' 0, z21_codcli, z01_nomcli, z21_fecha_emi,',
			' z21_fecha_emi, z21_valor * (-1), ',
			' NVL(CASE WHEN z21_fecha_emi > "', vm_fecha_ini, '"',
				' THEN z21_valor + ', subquery1 CLIPPED,
				' ELSE ', subquery2 CLIPPED, ' + z21_saldo - ',
					  subquery1 CLIPPED,
			' END, ',
			' CASE WHEN z21_fecha_emi <= "', vm_fecha_ini, '"',
				' THEN z21_saldo - ', subquery2 CLIPPED,
				' ELSE z21_valor',
			' END) * (-1) saldo_mov, ',
			' z21_cod_tran, z21_num_tran, z21_linea, z04_tipo, ',
			' "A Favor", 0, TODAY, z21_num_sri ',
		' FROM tmp_z21, gent002, cxct001 ',
		' WHERE g02_compania   = z21_compania ',
		'   AND g02_localidad  = z21_localidad ',
		'   AND z01_codcli     = z21_codcli '
PREPARE stmnt2 FROM query
EXECUTE stmnt2
DROP TABLE tmp_z21
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
		SELECT codcli, NVL(SUM(saldo_doc), 0) sal_f, 'F'
			FROM tempo_doc
			WHERE tipo_doc  = "F"
			  AND fecha_emi < rm_par.fecha_emi
			GROUP BY 1
	SELECT NVL(SUM(saldo_ini_cob), 0) INTO sal_ant
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
LET query = 'SELECT localidad loc1, codcli cli1, saldo_doc sald1 ',
		' FROM tempo_doc ',
		' WHERE tipo_doc    = "D" ',
		'   AND fecha_vcto >= "', rm_par.fecha_cart, '"',
		'   AND saldo_doc   > 0 ',
		' INTO TEMP t1 '
PREPARE cons_t1 FROM query
EXECUTE	cons_t1
LET query = 'SELECT localidad loc2, codcli cli2, saldo_doc sald2 ',
		' FROM tempo_doc ',
		' WHERE tipo_doc   = "D" ',
		'   AND fecha_vcto < "', rm_par.fecha_cart, '"',
		'   AND saldo_doc  > 0 ',
		' INTO TEMP t2 '
PREPARE cons_t2 FROM query
EXECUTE	cons_t2
LET query = 'SELECT localidad loc3, codcli cli3, saldo_doc * (-1) sald3 ',
		' FROM tempo_doc ',
		' WHERE tipo_doc  = "F" ',
		'   AND saldo_doc < 0 ',
		' INTO TEMP t3 '
PREPARE cons_t3 FROM query
EXECUTE	cons_t3
LET subquery = '(SELECT NVL(SUM(sald3), 0) ',
			' FROM t3 ',
			' WHERE cli3 = codcli ',
			'   AND loc3 = localidad), ',
		'(SELECT NVL(SUM(sald1), 0) ',
			' FROM t1 ',
			' WHERE cli1 = codcli ',
			'   AND loc1 = localidad), ',
		'(SELECT NVL(SUM(sald2), 0) ',
			' FROM t2 ',
			' WHERE cli2 = codcli ',
			'   AND loc2 = localidad) '
LET query = 'INSERT INTO tmp_saldos ',
		' SELECT localidad, codcli, ',
			subquery CLIPPED,
			' FROM tempo_doc ',
			' GROUP BY 1, 2'
PREPARE cons_saldo FROM query
EXECUTE cons_saldo
DROP TABLE t1
DROP TABLE t2
DROP TABLE t3
ERROR " "

END FUNCTION



FUNCTION muestra_titulos_columnas()

--#DISPLAY 'LC'			TO tit_col1
--#DISPLAY 'AN'			TO tit_col2
--#DISPLAY 'TP'			TO tit_col3
--#DISPLAY 'No. Documento'	TO tit_col4
--#DISPLAY 'Fecha Emi.'		TO tit_col5
--#DISPLAY 'Fecha Vcto'		TO tit_col6
--#DISPLAY 'Estado'		TO tit_col7
--#DISPLAY 'Días'		TO tit_col8
--#DISPLAY 'S a l d o'		TO tit_col9

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
DEFINE num_registro	LIKE cxct001.z01_codcli
DEFINE r_g02		RECORD LIKE gent002.*
DEFINE query		CHAR(1200)
DEFINE expr_loc		VARCHAR(100)
DEFINE expr_fec		VARCHAR(200)

ERROR 'Cargando documentos del cliente. . . espere por favor.' ATTRIBUTE(NORMAL)
IF vm_num_rows <= 0 THEN
	RETURN
END IF
SELECT * INTO rm_z01.* FROM cxct001 WHERE z01_codcli = num_registro
IF STATUS = NOTFOUND THEN
	CALL fl_mostrar_mensaje('No existe cliente: ' || num_registro, 'exclamation')
	RETURN
END IF
DISPLAY BY NAME	rm_z01.z01_codcli, rm_z01.z01_nomcli, rm_par.tit_mon,
		rm_z01.z01_direccion1, rm_z01.z01_telefono1,
		rm_z01.z01_telefono2, rm_z01.z01_fax1, rm_par.localidad,
		rm_par.fecha_emi, rm_par.fecha_cart
CASE rm_z01.z01_estado
	WHEN 'A'
		DISPLAY 'ACTIVO' TO tit_estcli
	WHEN 'B'
		DISPLAY 'BLOQUEADO' TO tit_estcli
END CASE
IF rm_par.localidad IS NOT NULL THEN
	CALL fl_lee_localidad(vg_codcia, rm_par.localidad) RETURNING r_g02.*
	LET rm_par.tit_localidad = r_g02.g02_nombre
ELSE
	LET rm_par.tit_localidad = NULL
END IF
DISPLAY BY NAME rm_par.tit_localidad
LET vm_sal_inicob = 0
IF rm_par.fecha_emi IS NOT NULL THEN
	SELECT NVL(saldo_ini_cob, 0) INTO vm_sal_inicob
		FROM tmp_sal_ini
		WHERE cod_cli_s = rm_z01.z01_codcli
END IF
LET expr_loc  = NULL
IF rm_par.localidad IS NOT NULL THEN
	LET expr_loc = '   AND loc_s = ', rm_par.localidad
END IF
LET query = 'SELECT NVL(SUM(sfav), 0) s_f, NVL(SUM(pven), 0) s_p, ',
		' NVL(SUM(venc), 0) s_v, NVL(SUM(pven + venc - sfav), 0) tot ',
		' FROM tmp_saldos ',
		' WHERE cli_s = ', rm_z01.z01_codcli,
		expr_loc CLIPPED,
		' INTO TEMP t_suma '
PREPARE suma FROM query
EXECUTE suma
SELECT * INTO tot_favor, tot_xven, tot_vcdo, tot_saldo FROM t_suma
DROP TABLE t_suma
LET expr_loc = NULL
IF rm_par.localidad IS NOT NULL THEN
	LET expr_loc = '   AND z26_localidad    = ', rm_par.localidad
END IF
LET expr_fec = '   AND z26_estado        = "A"',
		'   AND DATE(z26_fecing) <= "', rm_par.fecha_cart, '"'
IF rm_par.fecha_cart < TODAY THEN
	LET expr_fec = '   AND z26_fecha_cobro  >= "', rm_par.fecha_cart, '"',
			'   AND DATE(z26_fecing) <= "', rm_par.fecha_cart, '"'
END IF
LET query = 'SELECT NVL(SUM(z26_valor), 0) valor ',
		' FROM cxct026 ',
		' WHERE z26_compania      = ', vg_codcia,
		expr_loc CLIPPED,
		'   AND z26_codcli        = ', rm_z01.z01_codcli,
		expr_fec CLIPPED,
		' INTO TEMP t_suma '
PREPARE suma2 FROM query
EXECUTE suma2
SELECT * INTO tot_postfec FROM t_suma
DROP TABLE t_suma
LET tot_saldo = tot_saldo + vm_sal_inicob
DISPLAY BY NAME tot_favor, tot_xven, tot_vcdo, tot_saldo, tot_postfec,
		vm_sal_inicob
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
        INITIALIZE rm_dcli[i].* TO NULL
END FOR
FOR i = 1 TO fgl_scr_size('rm_dcli')
        CLEAR rm_dcli[i].*
END FOR
FOR i = 1 TO 20
	LET rm_orden[i] = '' 
END FOR
LET rm_orden[9]  = 'DESC'
LET rm_orden[1]  = 'ASC'
LET vm_columna_1 = 9
LET vm_columna_2 = 1
CALL cargar_arreglo_principal()
IF vm_num_doc > 0 THEN
        LET lim = vm_num_doc
	IF lim > fgl_scr_size('rm_dcli') THEN
        	LET lim = fgl_scr_size('rm_dcli')
	END IF
        FOR i = 1 TO lim
                DISPLAY rm_dcli[i].* TO rm_dcli[i].*
        END FOR
END IF
DISPLAY BY NAME tot_sal
CALL mostrar_contadores_det(0, vm_num_doc)

END FUNCTION



FUNCTION cargar_arreglo_principal()
DEFINE r_doc		RECORD
				localidad	LIKE cxct020.z20_localidad,
				area_n		LIKE cxct020.z20_areaneg,
				cladoc		LIKE cxct020.z20_tipo_doc,
				numdoc		LIKE cxct020.z20_num_doc,
				dividendo	LIKE cxct020.z20_dividendo,
				codcli		LIKE cxct020.z20_codcli,
				nomcli		LIKE cxct001.z01_nomcli,
				fecha_emi	LIKE cxct020.z20_fecha_emi,
				fecha_vcto	LIKE cxct020.z20_fecha_vcto,
				valor_doc	LIKE cxct020.z20_valor_cap,
				saldo_doc	LIKE cxct020.z20_saldo_cap,
				cod_tran	LIKE cxct020.z20_cod_tran,
				num_tran	LIKE cxct020.z20_num_tran,
				grupo_lin	LIKE cxct020.z20_linea,
				tipo_doc	LIKE cxct004.z04_tipo,
				estado_doc	VARCHAR(10),
				dias_venc	INTEGER,
				fecha_cobro	LIKE cxct022.z22_fecha_emi,
				doc_sri		LIKE cxct020.z20_num_sri
			END RECORD
DEFINE query		CHAR(1200)
DEFINE expr_loc		VARCHAR(100)
DEFINE numdoc   	VARCHAR(18)

LET expr_loc = NULL
IF rm_par.localidad IS NOT NULL THEN
	LET expr_loc = '   AND localidad = ', rm_par.localidad
END IF
LET query = 'SELECT *, ROWID FROM tempo_doc ',
        	' WHERE codcli    = ', rm_z01.z01_codcli,
		expr_loc CLIPPED,
	  	'   AND tipo_doc  = "D" ',
		' ORDER BY ', vm_columna_1, ' ', rm_orden[vm_columna_1],
			', ', vm_columna_2, ' ', rm_orden[vm_columna_2] 
PREPARE cxc20 FROM query
DECLARE q_doc CURSOR FOR cxc20
LET tot_sal    = 0
LET vm_num_doc = 1
FOREACH q_doc INTO r_doc.*, rm_rowid[vm_num_doc]
	LET numdoc = r_doc.numdoc CLIPPED, '-', r_doc.dividendo USING '<<&&'
	LET rm_dcli[vm_num_doc].tit_loc        = r_doc.localidad
	LET rm_dcli[vm_num_doc].tit_area       = r_doc.area_n
	LET rm_dcli[vm_num_doc].z20_tipo_doc   = r_doc.cladoc
	LET rm_dcli[vm_num_doc].num_doc	       = numdoc
	LET rm_dcli[vm_num_doc].z20_fecha_emi  = r_doc.fecha_emi
	LET rm_dcli[vm_num_doc].z20_fecha_vcto = r_doc.fecha_vcto
	LET rm_dcli[vm_num_doc].tit_estado     = r_doc.estado_doc
	LET rm_dcli[vm_num_doc].dias           = r_doc.dias_venc
	LET rm_dcli[vm_num_doc].saldo          = r_doc.saldo_doc
	LET vm_num_doc                         = vm_num_doc + 1
	LET tot_sal                            = tot_sal + r_doc.saldo_doc
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
DEFINE i, col		SMALLINT
DEFINE r_aux		RECORD
				local		LIKE cxct020.z20_localidad,
				area_n		LIKE cxct020.z20_areaneg,
				codcli		LIKE cxct020.z20_codcli,
				numdoc		LIKE cxct020.z20_num_doc,
				dividendo	LIKE cxct020.z20_dividendo,
				valor_doc	LIKE cxct020.z20_valor_cap,
				cod_tran	LIKE cxct020.z20_cod_tran,
				num_tran	LIKE cxct020.z20_num_tran
			END RECORD
DEFINE num_sri		LIKE rept038.r38_num_sri

WHILE TRUE
	LET int_flag = 0
	CALL set_count(vm_num_doc)
	DISPLAY ARRAY rm_dcli TO rm_dcli.*
		ON KEY(INTERRUPT)
			LET int_flag = 1
			EXIT DISPLAY
        	ON KEY(F1,CONTROL-W)
			CALL control_visor_teclas_caracter_1() 
		ON KEY(F5)
			LET i = arr_curr()
			SELECT localidad, area_n, cod_tran, num_tran
				INTO r_aux.local, r_aux.area_n, r_aux.cod_tran,
					r_aux.num_tran
				FROM tempo_doc 
				WHERE ROWID = rm_rowid[i]
			CALL ver_factura_devolucion(r_aux.area_n, r_aux.local,
							r_aux.cod_tran,
							r_aux.num_tran, 'D')
			LET int_flag = 0
		ON KEY(F6)
			LET i = arr_curr()
			SELECT codcli, numdoc, dividendo
				INTO r_aux.codcli, r_aux.numdoc, r_aux.dividendo
				FROM tempo_doc 
				WHERE ROWID = rm_rowid[i]
			CALL muestra_movimientos_documento_cxc(vg_codcia, 
				rm_dcli[i].tit_loc, r_aux.codcli,
				rm_dcli[i].z20_tipo_doc, r_aux.numdoc,
				r_aux.dividendo, rm_dcli[i].tit_area)
			LET int_flag = 0
		ON KEY(F7)
			LET i = arr_curr()
			SELECT codcli, numdoc, dividendo
				INTO r_aux.codcli, r_aux.numdoc, r_aux.dividendo
				FROM tempo_doc 
				WHERE ROWID = rm_rowid[i]
			CALL ver_documento(rm_dcli[i].tit_loc, r_aux.codcli,
					rm_dcli[i].z20_tipo_doc, r_aux.numdoc,
					r_aux.dividendo)
			LET int_flag = 0
		ON KEY(F8)
			IF rm_par.localidad IS NULL AND rm_par.tipo_saldo = 'T'
			THEN
				CALL cobranzas_vs_contabilidad(
							rm_z01.z01_codcli)
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
			LET col      = 3
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F18)
			LET col      = 4
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F19)
			LET col      = 8
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F20)
			LET col      = 9
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F21)
			LET col      = 16
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F22)
			LET col      = 17
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F23)
			LET col      = 11
			LET int_flag = 2
			EXIT DISPLAY
		--#BEFORE ROW
			--#LET i = arr_curr()
			--#SELECT cod_tran, num_tran, valor_doc, doc_sri
				--#INTO r_aux.cod_tran, r_aux.num_tran,
					--#r_aux.valor_doc, num_sri
				--#FROM tempo_doc 
				--#WHERE ROWID = rm_rowid[i]
			--#IF num_sri IS NULL THEN
			--#CALL obtener_num_sri(r_aux.cod_tran, r_aux.num_tran,
						--#rm_dcli[i].tit_loc,
						--#rm_dcli[i].tit_area)
				--#RETURNING num_sri
			--#END IF
			--#MESSAGE '    Valor Original: ', 
			        --#r_aux.valor_doc USING '#,###,###,##&.##',
				--#'    No. SRI ', num_sri
			--#CALL mostrar_contadores_det(i, vm_num_doc)
		--#BEFORE DISPLAY
			--#CALL dialog.keysetlabel("ACCEPT","")
			--#CALL dialog.keysetlabel("F1","")
			--#CALL dialog.keysetlabel("CONTROL-W","")
			--#IF rm_par.localidad IS NULL AND
				--#rm_par.tipo_saldo = 'T'
			--#THEN
				--#CALL dialog.keysetlabel("F8","Cobranza vs. Cont.")
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



FUNCTION mostrar_movimientos_cliente(codcia, codloc, codcli, moneda)
DEFINE codcia		LIKE gent001.g01_compania
DEFINE codloc		LIKE gent002.g02_localidad
DEFINE codcli		LIKE cxct001.z01_codcli
DEFINE moneda		LIKE gent013.g13_moneda
DEFINE r_z01		RECORD LIKE cxct001.*
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
				area		LIKE gent003.g03_areaneg,
				loc		LIKE gent002.g02_localidad,
				tipo		LIKE cxct023.z23_tipo_favor
			END RECORD
DEFINE r_movc		ARRAY[32766] OF RECORD
				z23_tipo_trn	LIKE cxct023.z23_tipo_trn,
				z23_num_trn	LIKE cxct023.z23_num_trn,
				z23_tipo_doc	LIKE cxct023.z23_tipo_doc,
				num_doc		VARCHAR(18),
				z22_fecha_elim	LIKE cxct022.z22_fecha_elim,
				z22_fecha_emi	LIKE cxct022.z22_fecha_emi,
				z22_moneda	LIKE cxct022.z22_moneda,
				val_pago	DECIMAL(14,2)
			END RECORD
DEFINE num_rows2 	SMALLINT
DEFINE num_cols 	SMALLINT
DEFINE expr_loc		VARCHAR(50)

LET max_rows  = 32766
LET num_rows2 = 18
LET num_cols  = 78
IF vg_gui = 0 THEN
	LET num_rows2 = 16
	LET num_cols  = 76
END IF
OPEN WINDOW w_dmcli AT 06, 02 WITH num_rows2 ROWS, num_cols COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MESSAGE LINE LAST, BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_cxcf305_3 FROM "../forms/cxcf314_3"
ELSE
	OPEN FORM f_cxcf305_3 FROM "../forms/cxcf314_3c"
END IF
DISPLAY FORM f_cxcf305_3
--#DISPLAY 'TP'                  TO tit_col1 
--#DISPLAY 'Número'              TO tit_col2 
--#DISPLAY 'TD'                  TO tit_col3 
--#DISPLAY 'Documento'           TO tit_col4
--#DISPLAY 'Fecha Elim'          TO tit_col5 
--#DISPLAY 'Fecha Pago'          TO tit_col6 
--#DISPLAY 'MO'                  TO tit_col7 
--#DISPLAY 'V a l o r'           TO tit_col8
CALL fl_lee_cliente_general(codcli) RETURNING r_z01.*
IF r_z01.z01_codcli IS NULL THEN
	CALL fl_mostrar_mensaje('No existe cliente: ' || codcli, 'exclamation')
	CLOSE WINDOW w_dmcli
	RETURN
END IF
DISPLAY BY NAME r_z01.z01_codcli, r_z01.z01_nomcli
FOR i = 1 TO 10
	LET r_orden[i] = '' 
END FOR
LET r_orden[6] = 'DESC'
LET columna_1  = 6
LET columna_2  = 1
LET expr_loc   = NULL
IF codloc IS NOT NULL THEN
	LET expr_loc = '   AND z23_localidad  = ', codloc
END IF
WHILE TRUE
	LET query = 'SELECT z23_tipo_trn, z23_num_trn, z23_tipo_doc, ',
			' z23_num_doc, z22_fecha_elim, z22_fecha_emi, ',
			' z22_moneda, z23_valor_cap + z23_valor_int, ',
			' z23_div_doc, z22_areaneg, z23_localidad, ',
			' z23_tipo_favor ',
	        	' FROM cxct023, cxct022 ',
			' WHERE z23_compania   = ? ',
			expr_loc CLIPPED,
		      	'   AND z23_codcli     = ? ',
			'   AND z22_compania   = z23_compania ',
			'   AND z22_localidad  = z23_localidad',
			'   AND z22_codcli     = z23_codcli ',
			'   AND z22_tipo_trn   = z23_tipo_trn ',
			'   AND z22_num_trn    = z23_num_trn ',
			'   AND z22_moneda     = ? ',
			'   AND z22_fecha_emi <= "', rm_par.fecha_cart, '" ',
			' ORDER BY ', columna_1, ' ', r_orden[columna_1],
				', ', columna_2, ' ', r_orden[columna_2]
	PREPARE dmcli FROM query
	DECLARE q_dmcli CURSOR FOR dmcli
	LET i        = 1
	LET tot_pago = 0
	OPEN q_dmcli USING codcia, codcli, moneda
	WHILE TRUE
		FETCH q_dmcli INTO r_movc[i].*, dividendo, r_aux[i].*
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
	CLOSE q_dmcli
	FREE q_dmcli
	LET num_rows = i - 1
	IF num_rows = 0 THEN
		CALL fl_mostrar_mensaje('Cliente no tiene movimientos.', 'exclamation')
		CLOSE WINDOW w_dmcli
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
			IF r_movc[i].z23_tipo_trn <> 'PG' THEN
				CONTINUE DISPLAY
			END IF
			LET i = arr_curr()
			CALL fl_muestra_forma_pago_caja(codcia, r_aux[i].loc,
							r_aux[i].area, codcli,
							r_movc[i].z23_tipo_trn,
							r_movc[i].z23_num_trn) 
			LET int_flag = 0
		ON KEY(F6)
			LET i = arr_curr()
			CALL ver_documento_tran(codcia, codcli,
				r_movc[i].z23_tipo_trn, r_movc[i].z23_num_trn,
				r_aux[i].loc, r_aux[i].tipo)
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
			--#IF r_movc[i].z23_tipo_trn <> 'PG' THEN
				--#CALL dialog.keysetlabel("F5","")
			--#ELSE
				--#CALL dialog.keysetlabel("F5","Pago Caja")
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
CLOSE WINDOW w_dmcli

END FUNCTION



FUNCTION mostrar_documentos_favor(codcia, codloc, codcli)
DEFINE codcia		LIKE gent001.g01_compania
DEFINE codloc		LIKE gent002.g02_localidad
DEFINE codcli		LIKE cxct001.z01_codcli
DEFINE r_z01		RECORD LIKE cxct001.*
DEFINE max_rows, i, col	SMALLINT
DEFINE r_orden 		ARRAY[10] OF CHAR(4)
DEFINE columna_1	SMALLINT
DEFINE columna_2	SMALLINT
DEFINE num_rows		SMALLINT
DEFINE tot_valor	DECIMAL(14,2)
DEFINE tot_saldo	DECIMAL(14,2)
DEFINE query		CHAR(1200)
DEFINE r_aux		ARRAY[2000] OF RECORD
				area		LIKE gent003.g03_areaneg,
				cod_tran	LIKE cxct021.z21_cod_tran,
				num_tran	LIKE cxct021.z21_num_tran
			END RECORD
DEFINE r_dda		ARRAY[2000] OF RECORD
				z21_localidad	LIKE cxct021.z21_localidad,
				z21_tipo_doc	LIKE cxct021.z21_tipo_doc,
				z21_num_doc	LIKE cxct021.z21_num_doc,
				z21_fecha_emi	LIKE cxct021.z21_fecha_emi,
				z21_valor	LIKE cxct021.z21_valor,
				z21_saldo	LIKE cxct021.z21_saldo
			END RECORD
DEFINE num_rows2 	SMALLINT
DEFINE num_cols 	SMALLINT
DEFINE expr_loc		VARCHAR(50)

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
	OPEN FORM f_cxcf314_4 FROM "../forms/cxcf314_4"
ELSE
	OPEN FORM f_cxcf314_4 FROM "../forms/cxcf314_4c"
END IF
DISPLAY FORM f_cxcf314_4
--#DISPLAY 'LC'                  TO tit_col1 
--#DISPLAY 'Tipo'                TO tit_col2 
--#DISPLAY 'Número'              TO tit_col3 
--#DISPLAY 'Fecha Emi.'          TO tit_col4 
--#DISPLAY 'V a l o r'           TO tit_col5
--#DISPLAY 'S a l d o'           TO tit_col6
CALL fl_lee_cliente_general(codcli) RETURNING r_z01.*
IF r_z01.z01_codcli IS NULL THEN
	CALL fl_mostrar_mensaje('No existe cliente: ' || codcli, 'exclamation')
	CLOSE WINDOW w_dda
	RETURN
END IF
DISPLAY BY NAME r_z01.z01_codcli, r_z01.z01_nomcli
FOR i = 1 TO 10
	LET r_orden[i] = '' 
END FOR
LET r_orden[4] = 'DESC'
LET columna_1  = 4
LET columna_2  = 3
LET expr_loc   = ' '
IF codloc IS NOT NULL THEN
	LET expr_loc = '   AND localidad = ', codloc
END IF
WHILE TRUE
	LET query = 'SELECT localidad, cladoc, numdoc, fecha_emi, valor_doc,',
			' saldo_doc, area_n, cod_tran, num_tran ',
	        	' FROM tempo_doc ',
			' WHERE codcli    = ? ',
			expr_loc CLIPPED,
			'   AND tipo_doc  = "F" ',
			' ORDER BY ', columna_1, ' ', r_orden[columna_1],
				', ', columna_2, ' ', r_orden[columna_2]
	PREPARE dda FROM query
	DECLARE q_dda CURSOR FOR dda
	LET i         = 1
	LET tot_valor = 0
	LET tot_saldo = 0
	OPEN q_dda USING codcli
	WHILE TRUE
		FETCH q_dda INTO r_dda[i].*, r_aux[i].*
		IF STATUS = NOTFOUND THEN
			EXIT WHILE
		END IF
		LET tot_valor = tot_valor + r_dda[i].z21_valor 
		LET tot_saldo = tot_saldo + r_dda[i].z21_saldo 
		LET i         = i + 1
		IF i > max_rows THEN
			EXIT WHILE
		END IF
	END WHILE
	CLOSE q_dda
	FREE q_dda
	LET num_rows = i - 1
	IF num_rows = 0 THEN
		CALL fl_mostrar_mensaje('Cliente no tiene documentos a favor.','exclamation')
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
			IF r_dda[i].z21_tipo_doc <> 'PA' THEN
				CONTINUE DISPLAY
			END IF
			LET i = arr_curr()
			CALL fl_muestra_forma_pago_caja(codcia,
							r_dda[i].z21_localidad,
							r_aux[i].area, codcli,
							r_dda[i].z21_tipo_doc,
							r_dda[i].z21_num_doc) 
			LET int_flag = 0
		ON KEY(F6)
			LET i = arr_curr()
			CALL ver_documento(r_dda[i].z21_localidad, codcli,
						r_dda[i].z21_tipo_doc,
						r_dda[i].z21_num_doc, 0)
			LET int_flag = 0
		ON KEY(F7)
			LET i = arr_curr()
			CALL muestra_movimientos_documento_cxc(codcia,
					r_dda[i].z21_localidad, codcli,
					r_dda[i].z21_tipo_doc,
					r_dda[i].z21_num_doc, 0, r_aux[i].area)
			LET int_flag = 0
		ON KEY(F8)
			IF r_dda[i].z21_tipo_doc <> 'NC' THEN
				CONTINUE DISPLAY
			END IF
			LET i = arr_curr()
			SELECT a.area_n
				INTO r_aux.area
				FROM tempo_doc a
				WHERE a.codcli   = codcli
				  AND a.cladoc   = r_dda[i].z21_tipo_doc
				  AND a.numdoc   = r_dda[i].z21_num_doc
				  AND a.tipo_doc = 'F'
			CALL ver_factura_devolucion(r_aux.area,
							r_dda[i].z21_localidad,
							r_aux[i].cod_tran,
							r_aux[i].num_tran, 'F')
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
		--#BEFORE ROW
			--#LET i = arr_curr()
			--#CALL mostrar_contadores_det(i, num_rows)
			--#IF r_dda[i].z21_tipo_doc <> 'PA' THEN
				--#CALL dialog.keysetlabel("F5","")
			--#ELSE
				--#CALL dialog.keysetlabel("F5","Pago Caja")
			--#END IF
			--#IF r_dda[i].z21_tipo_doc <> 'NC' THEN
				--#CALL dialog.keysetlabel("F8","")
			--#ELSE
			       --#CALL dialog.keysetlabel("F8","Ver Devolución")
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
DEFINE expr_sql		VARCHAR(400)
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
	OPEN FORM f_movdoc FROM "../forms/cxcf314_5"
ELSE
	OPEN FORM f_movdoc FROM "../forms/cxcf314_6"
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
LET fecha2   = EXTEND(rm_par.fecha_cart, YEAR TO SECOND) + 23 UNITS HOUR +
		59 UNITS MINUTE + 59 UNITS SECOND
LET expr_fec = '   AND z22_fecing    <= "', fecha2, '"'
IF rm_par.fecha_emi IS NOT NULL THEN
	LET fecha1   = EXTEND(rm_par.fecha_emi, YEAR TO SECOND)
	LET expr_fec = '   AND z22_fecing    BETWEEN "', fecha1,
					      '" AND "', fecha2, '"'
END IF
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
			CALL ver_documento_tran(codcia, codcli,
				r_pdoc[i].z23_tipo_trn, r_pdoc[i].z23_num_trn,
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



FUNCTION mostrar_cheque_protestados(codcia, codloc, codcli, moneda)
DEFINE codcia		LIKE gent001.g01_compania
DEFINE codloc		LIKE gent002.g02_localidad
DEFINE codcli		LIKE cxct001.z01_codcli
DEFINE moneda		LIKE gent013.g13_moneda
DEFINE v_num_chpr	SMALLINT
DEFINE v_max_chpr	SMALLINT
DEFINE total		DECIMAL(12,2)
DEFINE i, col		SMALLINT
DEFINE r_orden 		ARRAY[10] OF CHAR(4)
DEFINE v_columna_1	SMALLINT
DEFINE v_columna_2	SMALLINT
DEFINE query		CHAR(1200)
DEFINE expr_sql         CHAR(600)
DEFINE r_mon		RECORD LIKE gent013.*
DEFINE r_z01		RECORD LIKE cxct001.*
DEFINE r_loc		ARRAY[1000] OF LIKE gent002.g02_localidad
DEFINE r_chpr		ARRAY[1000] OF RECORD
				j12_fecing	DATE,
				g08_nombre	LIKE gent008.g08_nombre,
				j12_num_cheque	LIKE cajt012.j12_num_cheque,
				j12_valor	LIKE cajt012.j12_valor
			END RECORD
DEFINE r_ch_pr		ARRAY[1000] OF RECORD
				j12_banco	LIKE cajt012.j12_banco,
				j12_num_cta	LIKE cajt012.j12_num_cta,
				j12_num_cheque	LIKE cajt012.j12_num_cheque,
				j12_secuencia	LIKE cajt012.j12_secuencia
			END RECORD
DEFINE num_rows 	SMALLINT
DEFINE num_cols 	SMALLINT
DEFINE expr_loc		VARCHAR(50)

LET v_max_chpr = 1000
LET num_rows   = 17
LET num_cols   = 63
IF vg_gui = 0 THEN
	LET num_rows = 18
	LET num_cols = 64
END IF
OPEN WINDOW w_chpr AT 06, 15 WITH num_rows ROWS, num_cols COLUMNS
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MESSAGE LINE LAST,
                   MENU LINE 0, BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_cxcf314_7 FROM '../forms/cxcf314_7'
ELSE
	OPEN FORM f_cxcf314_7 FROM '../forms/cxcf314_7c'
END IF
DISPLAY FORM f_cxcf314_7
CALL mostrar_botones_chques()
CALL fl_lee_cliente_general(codcli) RETURNING r_z01.*
CALL fl_lee_moneda(moneda) RETURNING r_mon.*
DISPLAY codcli           TO j12_codcli
DISPLAY r_z01.z01_nomcli TO tit_nombre_cli
DISPLAY moneda           TO j12_moneda
DISPLAY r_mon.g13_nombre TO tit_moneda
FOR i = 1 TO 10
	LET r_orden[i] = '' 
END FOR
LET r_orden[1]  = 'ASC'
LET v_columna_1 = 1
LET v_columna_2 = 2
LET col         = 1
LET expr_loc    = NULL
IF codloc IS NOT NULL THEN
	LET expr_loc = '   AND j12_localidad = ', codloc
END IF
WHILE TRUE
	LET query = 'SELECT DATE(j12_fecing), g08_nombre, j12_num_cheque, ',
			'j12_valor, j12_banco, j12_num_cta, j12_num_cheque, ',
			'j12_secuencia, j12_localidad ',
			'FROM cajt012, cxct001, gent008 ',
			'WHERE j12_compania  = ', codcia,
			expr_loc CLIPPED,
			'  AND j12_codcli    = ', codcli,
			'  AND j12_moneda    = "', moneda, '"',
			'  AND DATE(j12_fecing) <= "', rm_par.fecha_cart, '"',
			'  AND j12_codcli    = z01_codcli ',
			'  AND j12_banco     = g08_banco ',
			' ORDER BY ', v_columna_1, ' ', r_orden[v_columna_1],
			       	', ', v_columna_2, ' ', r_orden[v_columna_2]
	PREPARE deto FROM query
	DECLARE q_deto CURSOR FOR deto
	LET v_num_chpr = 1
	LET total      = 0
	FOREACH q_deto INTO r_chpr[v_num_chpr].*, r_ch_pr[v_num_chpr].*,
				r_loc[v_num_chpr]
		LET total      = total + r_chpr[v_num_chpr].j12_valor
		LET v_num_chpr = v_num_chpr + 1
		IF v_num_chpr > v_max_chpr THEN
			EXIT FOREACH
		END IF
	END FOREACH
	LET v_num_chpr = v_num_chpr - 1
	IF v_num_chpr = 0 THEN
		CALL fl_mensaje_consulta_sin_registros()
		EXIT WHILE
	END IF
	LET int_flag = 0
	CALL set_count(v_num_chpr)
	DISPLAY ARRAY r_chpr TO r_chpr.*
		ON KEY(INTERRUPT)
			LET int_flag = 1
			EXIT DISPLAY
        	ON KEY(F1,CONTROL-W)
			CALL control_visor_teclas_caracter_5() 
		ON KEY(F5)
			LET i = arr_curr()
			CALL ver_cheque_pr(r_loc[i], r_ch_pr[i].*)
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
		--#BEFORE DISPLAY
			--#CALL dialog.keysetlabel('ACCEPT','')
			--#CALL dialog.keysetlabel("F1","")
			--#CALL dialog.keysetlabel("CONTROL-W","")
		--#BEFORE ROW
			--#LET i = arr_curr()
			--#CALL mostrar_contadores_det(i, vm_num_doc)
			--#DISPLAY total TO tit_total
		--#AFTER DISPLAY 
			--#CONTINUE DISPLAY
	END DISPLAY
	IF int_flag = 1 THEN
		EXIT WHILE
	END IF
	IF col <> v_columna_1 THEN
		LET v_columna_2          = v_columna_1 
		LET r_orden[v_columna_2] = r_orden[v_columna_1]
		LET v_columna_1          = col 
	END IF
	IF r_orden[v_columna_1] = 'ASC' THEN
		LET r_orden[v_columna_1] = 'DESC'
	ELSE
		LET r_orden[v_columna_1] = 'ASC'
	END IF
END WHILE
CLOSE WINDOW w_chpr

END FUNCTION



FUNCTION mostrar_cheque_postfechados(codcia, codloc, codcli, moneda)
DEFINE codcia		LIKE gent001.g01_compania
DEFINE codloc		LIKE gent002.g02_localidad
DEFINE codcli		LIKE cxct001.z01_codcli
DEFINE moneda		LIKE gent013.g13_moneda
DEFINE v_num_chpf	SMALLINT
DEFINE v_max_chpf	SMALLINT
DEFINE total		DECIMAL(12,2)
DEFINE i, col		SMALLINT
DEFINE r_orden 		ARRAY[10] OF CHAR(4)
DEFINE v_columna_1	SMALLINT
DEFINE v_columna_2	SMALLINT
DEFINE query		CHAR(1200)
DEFINE expr_sql         CHAR(600)
DEFINE r_mon		RECORD LIKE gent013.*
DEFINE r_z01		RECORD LIKE cxct001.*
DEFINE r_loc		ARRAY[1000] OF LIKE gent002.g02_localidad
DEFINE r_chpf		ARRAY[1000] OF RECORD
				z26_fecha_cobro	LIKE cxct026.z26_fecha_cobro,
				g08_nombre	LIKE gent008.g08_nombre,
				z26_num_cheque	LIKE cxct026.z26_num_cheque,
				z26_valor	LIKE cxct026.z26_valor
			END RECORD
DEFINE r_ch_pf		ARRAY[1000] OF RECORD
				z26_codcli	LIKE cxct026.z26_codcli,
				z26_banco	LIKE cxct026.z26_banco,
				z26_num_cta	LIKE cxct026.z26_num_cta,
				z26_num_cheque	LIKE cxct026.z26_num_cheque
			END RECORD
DEFINE num_rows 	SMALLINT
DEFINE num_cols 	SMALLINT
DEFINE expr_loc		VARCHAR(100)
DEFINE expr_fec		VARCHAR(200)

LET v_max_chpf = 1000
LET num_rows   = 17
LET num_cols   = 63
IF vg_gui = 0 THEN
	LET num_rows = 18
	LET num_cols = 64
END IF
OPEN WINDOW w_chpf AT 06, 15 WITH num_rows ROWS, num_cols COLUMNS
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MESSAGE LINE LAST,
                   MENU LINE 0, BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_cxcf314_8 FROM '../forms/cxcf314_8'
ELSE
	OPEN FORM f_cxcf314_8 FROM '../forms/cxcf314_8c'
END IF
DISPLAY FORM f_cxcf314_8
CALL mostrar_botones_chques()
CALL fl_lee_cliente_general(codcli) RETURNING r_z01.*
CALL fl_lee_moneda(moneda) RETURNING r_mon.*
DISPLAY codcli           TO z26_codcli
DISPLAY r_z01.z01_nomcli TO tit_nombre_cli
DISPLAY moneda           TO z20_moneda
DISPLAY r_mon.g13_nombre TO tit_moneda
FOR i = 1 TO 10
	LET r_orden[i] = '' 
END FOR
LET r_orden[1]  = 'ASC'
LET v_columna_1 = 1
LET v_columna_2 = 2
LET col         = 1
LET expr_loc    = NULL
IF codloc IS NOT NULL THEN
	LET expr_loc = '   AND z26_localidad     = ', codloc
END IF
LET expr_fec = '   AND z26_estado        = "A"',
		'   AND DATE(z26_fecing) <= "', rm_par.fecha_cart, '"'
IF rm_par.fecha_cart < TODAY THEN
	LET expr_fec = '   AND z26_fecha_cobro  >= "', rm_par.fecha_cart, '"',
			'   AND DATE(z26_fecing) <= "', rm_par.fecha_cart, '"'
END IF
WHILE TRUE
	LET query = 'SELECT z26_fecha_cobro, g08_nombre, z26_num_cheque, ',
			'z26_valor, z26_codcli, z26_banco, z26_num_cta, ',
			'z26_num_cheque, z26_localidad ',
			' FROM cxct026, cxct001, gent008 ',
			' WHERE z26_compania      = ', codcia,
			expr_loc CLIPPED,
			'   AND z26_codcli        = ', codcli,
			expr_fec CLIPPED,
			'   AND z26_codcli        = z01_codcli ',
			'   AND z26_banco         = g08_banco ',
			' ORDER BY ', v_columna_1, ' ', r_orden[v_columna_1],
			       	', ', v_columna_2, ' ', r_orden[v_columna_2]
	PREPARE deto2 FROM query
	DECLARE q_deto2 CURSOR FOR deto2
	LET v_num_chpf = 1
	LET total      = 0
	FOREACH q_deto2 INTO r_chpf[v_num_chpf].*, r_ch_pf[v_num_chpf].*,
				r_loc[v_num_chpf]
		LET total      = total + r_chpf[v_num_chpf].z26_valor
		LET v_num_chpf = v_num_chpf + 1
		IF v_num_chpf > v_max_chpf THEN
			EXIT FOREACH
		END IF
	END FOREACH
	LET v_num_chpf = v_num_chpf - 1
	IF v_num_chpf = 0 THEN
		CALL fl_mensaje_consulta_sin_registros()
		EXIT WHILE
	END IF
	LET int_flag = 0
	CALL set_count(v_num_chpf)
	DISPLAY ARRAY r_chpf TO r_chpf.*
		ON KEY(INTERRUPT)
			LET int_flag = 1
			EXIT DISPLAY
        	ON KEY(F1,CONTROL-W)
			CALL control_visor_teclas_caracter_5() 
		ON KEY(F5)
			LET i = arr_curr()
			CALL ver_cheque_pf(r_loc[i], r_ch_pf[i].*)
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
		--#BEFORE DISPLAY
			--#CALL dialog.keysetlabel('ACCEPT','')
			--#CALL dialog.keysetlabel("F1","")
			--#CALL dialog.keysetlabel("CONTROL-W","")
		--#BEFORE ROW
			--#LET i = arr_curr()
			--#CALL mostrar_contadores_det(i, vm_num_doc)
			--#DISPLAY total TO tit_total
		--#AFTER DISPLAY 
			--#CONTINUE DISPLAY
	END DISPLAY
	IF int_flag = 1 THEN
		EXIT WHILE
	END IF
	IF col <> v_columna_1 THEN
		LET v_columna_2          = v_columna_1 
		LET r_orden[v_columna_2] = rm_orden[v_columna_1]
		LET v_columna_1          = col 
	END IF
	IF r_orden[v_columna_1] = 'ASC' THEN
		LET r_orden[v_columna_1] = 'DESC'
	ELSE
		LET r_orden[v_columna_1] = 'ASC'
	END IF
END WHILE
CLOSE WINDOW w_chpf

END FUNCTION



FUNCTION mostrar_botones_chques()

--#DISPLAY 'Fecha'        TO tit_col1
--#DISPLAY 'Banco'        TO tit_col2
--#DISPLAY 'No. Cheque'   TO tit_col3
--#DISPLAY 'Valor Cheque' TO tit_col4

END FUNCTION



FUNCTION obtener_num_sri(cod_tran, num_tran, tit_loc, areaneg)
DEFINE cod_tran		LIKE cxct021.z21_cod_tran
DEFINE num_tran		LIKE cxct021.z21_num_tran
DEFINE tit_loc		LIKE gent002.g02_localidad
DEFINE areaneg		LIKE cxct020.z20_areaneg
DEFINE r_r38		RECORD LIKE rept038.*
DEFINE tipo_fuente	LIKE rept038.r38_tipo_fuente
DEFINE query		CHAR(600)
DEFINE base_suc		VARCHAR(10)

INITIALIZE r_r38.* TO NULL
IF cod_tran IS NULL THEN
	RETURN r_r38.r38_num_sri
END IF
LET tipo_fuente = NULL
LET base_suc    = NULL
IF areaneg = 1 THEN
	LET tipo_fuente = 'PR'
END IF
IF areaneg = 2 THEN
	LET tipo_fuente = 'OT'
END IF
IF tit_loc = 2 THEN
	LET base_suc = 'acero_gc:'
END IF
IF tit_loc = 4 THEN
	LET base_suc = 'acero_qs:'
END IF
LET query = 'SELECT * FROM ', base_suc CLIPPED, 'rept038',
		' WHERE r38_compania    = ', vg_codcia,
		'   AND r38_localidad   = ', tit_loc,
		'   AND r38_tipo_doc   IN ("FA", "NV") ',
		'   AND r38_tipo_fuente = "', tipo_fuente, '"',
		'   AND r38_cod_tran    = "', cod_tran, '"',
		'   AND r38_num_tran    = ', num_tran
PREPARE cons_r38 FROM query
DECLARE q_r38 CURSOR FOR cons_r38
OPEN q_r38
FETCH q_r38 INTO r_r38.*
CLOSE q_r38
FREE q_r38
RETURN r_r38.r38_num_sri

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



FUNCTION cobranzas_vs_contabilidad(cod_cli)
DEFINE cod_cli		LIKE cxct001.z01_codcli
DEFINE r_z01		RECORD LIKE cxct001.*
DEFINE r_b41		RECORD LIKE ctbt041.*
DEFINE fecha1, fecha2	LIKE cxct022.z22_fecing
DEFINE max_rows, i, col	INTEGER
DEFINE lim, cuantos	INTEGER
DEFINE tot_val_deu	DECIMAL(14,2)
DEFINE tot_val_fav	DECIMAL(14,2)
DEFINE tot_val_db	DECIMAL(14,2)
DEFINE tot_val_cr	DECIMAL(14,2)
DEFINE sal_ini_cob	DECIMAL(14,2)
DEFINE sal_ini_con	DECIMAL(14,2)
DEFINE saldo_cont	DECIMAL(14,2)
DEFINE saldo_cob	DECIMAL(14,2)
DEFINE v_saldo_cont	DECIMAL(14,2)
DEFINE v_saldo_cob	DECIMAL(14,2)
DEFINE val_des		DECIMAL(14,2)
DEFINE query		CHAR(1200)
DEFINE expr_fec		VARCHAR(200)
DEFINE expr_cli1	VARCHAR(100)
DEFINE expr_cli2	VARCHAR(100)
DEFINE num_rows2 	SMALLINT
DEFINE num_cols 	SMALLINT
DEFINE fecha_ini	DATE
DEFINE fecha_fin	DATE
DEFINE fecha_antes	DATE
DEFINE sig_cob, sig_con	SMALLINT
DEFINE p1, p2, p3, p4	INTEGER

LET num_rows2 = 22
LET num_cols  = 80
IF vg_gui = 0 THEN
	LET num_rows2 = 20
	LET num_cols  = 77
END IF
OPEN WINDOW w_cob_cont AT 03, 02 WITH num_rows2 ROWS, num_cols COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MESSAGE LINE LAST, BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_cxcf314_9 FROM "../forms/cxcf314_9"
ELSE
	OPEN FORM f_cxcf314_9 FROM "../forms/cxcf314_9c"
END IF
DISPLAY FORM f_cxcf314_9
--#DISPLAY 'TP'		TO tit_col1 
--#DISPLAY 'Número'	TO tit_col2 
--#DISPLAY 'Fecha Pago'	TO tit_col3
--#DISPLAY 'Referencia'	TO tit_col4
--#DISPLAY 'Deudor'	TO tit_col5
--#DISPLAY 'Acreedor'	TO tit_col6
--#DISPLAY 'Saldo Cob.'	TO tit_col7
--#DISPLAY 'TP'		TO tit_col8 
--#DISPLAY 'Número'	TO tit_col9 
--#DISPLAY 'Fecha'	TO tit_col10
--#DISPLAY 'G l o s a'	TO tit_col11 
--#DISPLAY 'Débito'	TO tit_col12
--#DISPLAY 'Crédito'	TO tit_col13
--#DISPLAY 'Saldo Con.'	TO tit_col14
CALL fl_lee_cliente_general(cod_cli) RETURNING r_z01.*
IF r_z01.z01_codcli IS NULL THEN
	CALL fl_mostrar_mensaje('No existe cliente: ' || cod_cli, 'exclamation')
	CLOSE WINDOW w_cob_cont
	RETURN
END IF
SELECT UNIQUE ctbt041.*
	FROM tempo_doc, gent003, ctbt041
	WHERE codcli          = cod_cli
	  AND g03_compania    = vg_codcia
	  AND g03_areaneg     = area_n
	  AND b41_compania    = g03_compania
	  AND b41_localidad   = localidad
	  AND b41_modulo      = g03_modulo
	  AND b41_grupo_linea = grupo_lin
	INTO TEMP tmp_b41
SELECT COUNT(*) INTO cuantos FROM tmp_b41
IF cuantos = 0 THEN
	DROP TABLE tmp_b41
	CALL fl_mostrar_mensaje('No existe auxiliar contable para el módulo de Cobranzas.', 'exclamation')
	CLOSE WINDOW w_cob_cont
	RETURN
END IF
LET fecha_ini = rm_par.fecha_emi
LET fecha_fin = rm_par.fecha_cart
IF fecha_ini IS NULL THEN
	LET fecha_ini = vm_fecha_ini + 1 UNITS DAY
END IF
LET fecha_antes = fecha_ini - 1 UNITS DAY
SELECT UNIQUE z02_aux_clte_mb cuenta FROM cxct002 INTO TEMP tmp_cta
DECLARE q_b41 CURSOR FOR SELECT * FROM tmp_b41
INITIALIZE r_b41.* TO NULL
FOREACH q_b41 INTO r_b41.*
	SELECT * FROM tmp_cta WHERE cuenta = r_b41.b41_cxc_mb
	IF STATUS = NOTFOUND THEN
		INSERT INTO tmp_cta VALUES (r_b41.b41_cxc_mb)
	END IF
END FOREACH
DROP TABLE tmp_b41
DISPLAY BY NAME r_z01.z01_codcli, r_z01.z01_nomcli
LET expr_cli1 = '   AND z23_codcli     = ', r_z01.z01_codcli
LET expr_cli2 = '   AND b13_codcli      = ', r_z01.z01_codcli
DISPLAY BY NAME fecha_ini, fecha_fin, rm_par.moneda, rm_par.tit_mon
LET fecha2   = EXTEND(rm_par.fecha_cart, YEAR TO SECOND) + 23 UNITS HOUR +
		59 UNITS MINUTE + 59 UNITS SECOND
LET expr_fec = '   AND z22_fecing    <= "', fecha2, '"'
IF rm_par.fecha_emi IS NOT NULL THEN
	LET fecha1   = EXTEND(rm_par.fecha_emi, YEAR TO SECOND)
	LET expr_fec = '   AND z22_fecing    BETWEEN "', fecha1,
					      '" AND "', fecha2, '"'
END IF
ERROR "Procesando Movimientos en Cobranzas . . . espere por favor." ATTRIBUTE(NORMAL)
LET query = 'SELECT z23_tipo_trn, z23_num_trn, z22_fecha_emi, z22_referencia, ',
			' CASE WHEN z23_valor_cap + z23_valor_int > 0 ',
				' THEN z23_valor_cap + z23_valor_int ',
				' ELSE 0 ',
			' END valor_d, ',
			' CASE WHEN z23_valor_cap + z23_valor_int < 0 ',
				' THEN z23_valor_cap + z23_valor_int ',
				' ELSE 0 ',
			' END valor_f, ',
			' z23_valor_cap + z23_valor_int valor_m, ',
			' z23_localidad, z23_tipo_favor, z23_codcli, ',
			' z22_areaneg ',
	       	' FROM cxct023, cxct022 ',
		' WHERE z23_compania   = ', vg_codcia,
		expr_cli1 CLIPPED,
		'   AND z22_compania   = z23_compania ',
		'   AND z22_localidad  = z23_localidad ',
		'   AND z22_codcli     = z23_codcli ',
		'   AND z22_tipo_trn   = z23_tipo_trn  ',
		'   AND z22_num_trn    = z23_num_trn ',
		expr_fec CLIPPED,
		' INTO TEMP tmp_mov_cob '
PREPARE exec_z23 FROM query
EXECUTE exec_z23
SELECT COUNT(*) INTO vm_num_cob FROM tmp_mov_cob
LET sal_ini_cob = vm_sal_inicob
LET saldo_cob   = tot_sal - tot_favor
IF rm_par.codcli IS NULL THEN
	SELECT NVL(SUM(saldo_doc), 0) INTO saldo_cob
		FROM tempo_doc
		WHERE codcli = r_z01.z01_codcli
	LET saldo_cob = saldo_cob + sal_ini_cob
END IF
LET sig_cob = 0
IF vm_num_cob > 0 THEN
	DISPLAY BY NAME saldo_cob, sal_ini_cob
	LET query = 'SELECT * FROM tmp_mov_cob ORDER BY 3 DESC, 1'
	PREPARE mov_cob2 FROM query
	DECLARE q_mov_cob2 CURSOR FOR mov_cob2
	LET i           = 1
	LET tot_val_deu = 0
	LET tot_val_fav = 0
	FOREACH q_mov_cob2 INTO rm_cob[i].*, rm_aux[i].*
		LET tot_val_deu = tot_val_deu + rm_cob[i].val_deu 
		LET tot_val_fav = tot_val_fav + rm_cob[i].val_fav 
		LET i           = i + 1
		IF i > vm_max_doc THEN
			EXIT FOREACH
		END IF
	END FOREACH
	LET sal_ini_cob = (saldo_cob * (-1) + tot_val_deu + tot_val_fav) * (-1)
	DISPLAY BY NAME sal_ini_cob, tot_val_deu, tot_val_fav
	LET lim = vm_num_cob
	IF lim > fgl_scr_size('rm_cob') THEN
		LET lim = fgl_scr_size('rm_cob')
	END IF
	FOR i = 1 TO lim
		DISPLAY rm_cob[i].* TO rm_cob[i].*
	END FOR
	DISPLAY rm_cob[1].z22_referencia TO tit_referencia
	LET sig_cob = 1
END IF
ERROR "Procesando Movimientos en Contabilidad . . . espere por favor." ATTRIBUTE(NORMAL)
LET query = 'SELECT * FROM ctbt013 ',
		' WHERE b13_compania    = ', vg_codcia,
		'   AND b13_fec_proceso BETWEEN "', vm_fecha_ini,
					 '" AND "', fecha_fin, '"',
		'   AND b13_cuenta     IN (SELECT UNIQUE cuenta FROM tmp_cta) ',
		expr_cli2 CLIPPED,
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
IF vm_num_cob = 0 AND vm_num_con = 0 THEN
	DROP TABLE tmp_mov_cob
	DROP TABLE tmp_mov_con
	CALL fl_mensaje_consulta_sin_registros()
	CLOSE WINDOW w_cob_cont
	RETURN
END IF
IF vm_num_cob > vm_max_doc THEN
	LET vm_num_cob = vm_max_doc
END IF
IF vm_num_con > vm_max_doc THEN
	LET vm_num_con = vm_max_doc
END IF
IF vm_num_cob = vm_max_doc OR vm_num_con > vm_max_doc THEN
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
	LET v_saldo_cob = saldo_cob
	IF v_saldo_cob < 0 THEN
		LET v_saldo_cob = v_saldo_cob * (-1)
	END IF
	IF saldo_cont > saldo_cob THEN
		LET val_des = v_saldo_cont - v_saldo_cob
	ELSE
		LET val_des = v_saldo_cob - v_saldo_cont
	END IF
	DISPLAY BY NAME tot_val_db, tot_val_cr, saldo_cont, val_des
	LET lim = vm_num_con
	IF lim > fgl_scr_size('rm_cont') THEN
		LET lim = fgl_scr_size('rm_cont')
	END IF
	FOR i = 1 TO lim
		DISPLAY rm_cont[i].* TO rm_cont[i].*
	END FOR
	IF sig_cob = 0 THEN
		LET sig_con = 1
	END IF
	DISPLAY rm_cont[1].b13_glosa TO tit_glosa
END IF
ERROR ' '
CALL mostrar_contadores_cob_con(0, vm_num_cob, 0, vm_num_con)
LET p1 = 1
LET p2 = 1
LET p3 = 1
LET p4 = 1
WHILE TRUE
	IF sig_cob = 1 THEN
		CALL detalle_cobranzas(p1,p2) RETURNING sig_con, p1, p2
	END IF
	IF sig_con = 1 THEN
		CALL detalle_contabilidad(p3, p4) RETURNING sig_cob, p3, p4
	END IF
	IF sig_cob = 0 THEN
		EXIT WHILE
	END IF
	IF sig_con = 0 THEN
		EXIT WHILE
	END IF
END WHILE
DROP TABLE tmp_mov_cob
DROP TABLE tmp_mov_con
CLOSE WINDOW w_cob_cont

END FUNCTION



FUNCTION detalle_cobranzas(pos_pan, pos_arr)
DEFINE pos_pan, pos_arr	INTEGER
DEFINE query		VARCHAR(200)
DEFINE i, col		INTEGER
DEFINE r_orden 		ARRAY[10] OF CHAR(4)
DEFINE columna_1	SMALLINT
DEFINE columna_2	SMALLINT
DEFINE sig_cob		SMALLINT

FOR i = 1 TO 10
	LET r_orden[i] = '' 
END FOR
LET r_orden[3] = 'DESC'
LET columna_1  = 3
LET columna_2  = 1
WHILE TRUE
	LET int_flag = 0
	CALL set_count(vm_num_cob)
	DISPLAY ARRAY rm_cob TO rm_cob.*
		ON KEY(INTERRUPT)
			LET int_flag = 1
			LET sig_cob  = 0
			EXIT DISPLAY
		ON KEY(F5)
			IF vm_num_con = 0 THEN
				CONTINUE DISPLAY
			END IF
			LET int_flag = 1
			LET sig_cob  = 1
			LET pos_pan  = scr_line()
			LET pos_arr  = arr_curr()
			EXIT DISPLAY
		ON KEY(F6)
			LET i = arr_curr()
			CALL fl_muestra_forma_pago_caja(vg_codcia,rm_aux[i].loc,
						rm_aux[i].areaneg,
						rm_aux[i].codcli,
						rm_cob[i].z23_tipo_trn,
						rm_cob[i].z23_num_trn) 
			LET int_flag = 0
		ON KEY(F7)
			LET i = arr_curr()
			CALL ver_documento_tran(vg_codcia, rm_aux[i].codcli,
				rm_cob[i].z23_tipo_trn, rm_cob[i].z23_num_trn,
				rm_aux[i].loc, rm_aux[i].tipo)
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
			--#CALL mostrar_contadores_cob_con(i, vm_num_cob,
							--#0, vm_num_con)
			--#DISPLAY rm_cob[i].z22_referencia TO tit_referencia
		--#BEFORE DISPLAY
			--#CALL dialog.setcurrline(pos_pan, pos_arr)
			--#CALL mostrar_contadores_cob_con(pos_arr, vm_num_cob,
							--#0, vm_num_con)
			--#DISPLAY rm_cob[pos_arr].z22_referencia TO
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
	LET query = 'SELECT * FROM tmp_mov_cob ',
			' ORDER BY ', columna_1, ' ', r_orden[columna_1],
				', ', columna_2, ' ', r_orden[columna_2]
	PREPARE mov_cob3 FROM query
	DECLARE q_mov_cob3 CURSOR FOR mov_cob3
	LET i = 1
	FOREACH q_mov_cob3 INTO rm_cob[i].*, rm_aux[i].*
		LET i = i + 1
		IF i > vm_max_doc THEN
			EXIT FOREACH
		END IF
	END FOREACH
END WHILE
CALL mostrar_contadores_cob_con(0, vm_num_cob, 0, vm_num_con)
RETURN sig_cob, pos_pan, pos_arr

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
			IF vm_num_cob = 0 THEN
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
			--#CALL mostrar_contadores_cob_con(0, vm_num_cob,
							--#i, vm_num_con)
			--#DISPLAY rm_cont[i].b13_glosa TO tit_glosa
		--#BEFORE DISPLAY
			--#CALL dialog.setcurrline(pos_pan, pos_arr)
			--#CALL mostrar_contadores_cob_con(0, vm_num_cob,
							--#pos_arr, vm_num_con)
			--#DISPLAY rm_cont[pos_arr].b13_glosa TO tit_glosa
			--#CALL dialog.keysetlabel("ACCEPT","")
			--#CALL dialog.keysetlabel("F1","")
			--#CALL dialog.keysetlabel("F5","Detalle Cobranza")
			--#IF vm_num_cob = 0 THEN
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
CALL mostrar_contadores_cob_con(0, vm_num_cob, 0, vm_num_con)
RETURN sig_con, pos_pan, pos_arr

END FUNCTION



FUNCTION mostrar_contadores_cob_con(num_row_cob, max_row_cob, num_row_con,
					max_row_con)
DEFINE num_row_cob	INTEGER
DEFINE max_row_cob	INTEGER
DEFINE num_row_con	INTEGER
DEFINE max_row_con	INTEGER

DISPLAY BY NAME num_row_cob, max_row_cob, num_row_con, max_row_con

END FUNCTION



FUNCTION ver_factura_devolucion(area_n, local, cod_tran, num_tran, tipo)
DEFINE area_n		LIKE cxct020.z20_areaneg
DEFINE local		LIKE cxct020.z20_localidad
DEFINE cod_tran		LIKE cxct020.z20_cod_tran
DEFINE num_tran		LIKE cxct020.z20_num_tran
DEFINE tipo		LIKE cxct004.z04_tipo
DEFINE r_g03		RECORD LIKE gent003.*
DEFINE r_t28		RECORD LIKE talt028.*
DEFINE prog		VARCHAR(10)
DEFINE expr		VARCHAR(40)
DEFINE comando          VARCHAR(200)

CALL fl_lee_area_negocio(vg_codcia, area_n) RETURNING r_g03.*
CASE r_g03.g03_modulo
	WHEN 'RE'
		CALL fl_ver_transaccion_rep(vg_codcia, local,cod_tran, num_tran)
	WHEN 'TA'
		LET prog = 'talp308 '
		LET expr = num_tran
		IF tipo = 'F' THEN
			SELECT * INTO r_t28.*
				FROM talt028
				WHERE t28_compania  = vg_codcia
				  AND t28_localidad = local
				  AND t28_factura   = num_tran
			LET prog = 'talp211 '
			LET expr = r_t28.t28_num_dev
		END IF
		LET comando = 'cd ..', vg_separador, '..', vg_separador, '..',
				vg_separador, 'PRODUCCION', vg_separador,
				'TALLER', vg_separador, 'fuentes; ', 'fglrun ',
				prog CLIPPED, ' ', vg_base, ' TA ', vg_codcia,
				' ', local, ' ', expr CLIPPED
		RUN comando
	WHEN 'VE'
		LET comando = 'cd ..', vg_separador, '..', vg_separador,
				'VEHICULOS', vg_separador, 'fuentes; ',
				'fglrun vehp304 ', vg_base, ' VE ', vg_codcia,
				' ', local, ' ', cod_tran, ' ', num_tran
		RUN comando
END CASE

END FUNCTION



FUNCTION ver_datos_cliente(codcli)
DEFINE codcli		LIKE cxct001.z01_codcli
DEFINE codloc		LIKE gent002.g02_localidad
DEFINE comando          VARCHAR(200)

LET codloc = 0
IF rm_par.localidad IS NOT NULL THEN
	LET codloc = rm_par.localidad
END IF
LET comando = 'fglrun cxcp101 ', vg_base, ' ', vg_modulo, ' ', vg_codcia, ' ',
		codloc, ' ', codcli
RUN comando

END FUNCTION



FUNCTION ver_cheque_pr(r_aux)
DEFINE r_aux		RECORD
				loc		LIKE cajt012.j12_localidad,
				j12_banco	LIKE cajt012.j12_banco,
				j12_num_cta	LIKE cajt012.j12_num_cta,
				j12_num_cheque	LIKE cajt012.j12_num_cheque,
				j12_secuencia	LIKE cajt012.j12_secuencia
			END RECORD
DEFINE comando          VARCHAR(200)

LET comando = 'fglrun cxcp207 ', vg_base, ' ', vg_modulo, ' ', vg_codcia, ' ',
		r_aux.loc, ' ', r_aux.j12_banco, ' "', r_aux.j12_num_cta, '"',
		' "', r_aux.j12_num_cheque, '" ', r_aux.j12_secuencia
RUN comando

END FUNCTION



FUNCTION ver_cheque_pf(r_aux)
DEFINE r_aux		RECORD
				loc		LIKE cxct026.z26_localidad,
				z26_codcli	LIKE cxct026.z26_codcli,
				z26_banco	LIKE cxct026.z26_banco,
				z26_num_cta	LIKE cxct026.z26_num_cta,
				z26_num_cheque	LIKE cxct026.z26_num_cheque
			END RECORD
DEFINE comando          VARCHAR(200)

LET comando = 'fglrun cxcp206 ', vg_base, ' ', vg_modulo, ' ', vg_codcia, ' ',
		r_aux.loc, ' ', r_aux.z26_codcli, ' ', r_aux.z26_banco, ' "',
		r_aux.z26_num_cta, '" "', r_aux.z26_num_cheque, '"'
RUN comando

END FUNCTION



FUNCTION ver_documento(locali, codcli, tipodoc, numdoc, dividendo)
DEFINE locali		LIKE cxct020.z20_localidad
DEFINE codcli		LIKE cxct001.z01_codcli
DEFINE tipodoc		LIKE cxct020.z20_tipo_doc
DEFINE numdoc		LIKE cxct020.z20_num_doc
DEFINE dividendo	LIKE cxct020.z20_dividendo
DEFINE prog		VARCHAR(10)
DEFINE expr		VARCHAR(40)
DEFINE comando          VARCHAR(200)

LET prog = 'cxcp200 '
LET expr = dividendo, ' ', rm_par.fecha_cart
IF dividendo = 0 THEN
	LET prog = 'cxcp201 '
	LET expr = ' ', rm_par.fecha_cart
END IF
LET comando = 'fglrun ', prog CLIPPED, ' ', vg_base, ' ', vg_modulo, ' ',
		vg_codcia, ' ',	locali, ' ', codcli, ' ', tipodoc, ' ', numdoc,
		' ', expr CLIPPED
RUN comando

END FUNCTION



FUNCTION ver_documento_tran(codcia, codcli, tipo_trn, num_trn, loc, tipo)
DEFINE codcia		LIKE cxct022.z22_compania
DEFINE codcli		LIKE cxct022.z22_codcli
DEFINE tipo_trn		LIKE cxct022.z22_tipo_trn
DEFINE num_trn		LIKE cxct022.z22_num_trn
DEFINE loc		LIKE cxct022.z22_localidad
DEFINE tipo		LIKE cxct023.z23_tipo_favor
DEFINE comando		VARCHAR(200)
DEFINE run_prog		CHAR(10)
DEFINE prog		CHAR(10)

LET run_prog = 'fglrun '
IF vg_gui = 0 THEN
	LET run_prog = 'fglgo '
END IF
LET prog = 'cxcp202 '
IF tipo IS NOT NULL THEN
	LET prog = 'cxcp203 '
END IF
LET comando = run_prog, prog, vg_base, ' ', vg_modulo, ' ', codcia, ' ', loc,
		' ', codcli, ' ', tipo_trn, ' ', num_trn
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



FUNCTION control_imprimir()
DEFINE r_report		RECORD
				tit_local	LIKE cxct020.z20_localidad,
				tit_loc		LIKE gent002.g02_nombre,
				areaneg 	LIKE gent003.g03_nombre,
				tipo_doc	LIKE cxct020.z20_tipo_doc,
				num_doc		LIKE cxct020.z20_num_doc,
				dividendo	LIKE cxct020.z20_dividendo,
				num_sri		LIKE cxct020.z20_num_sri,
				fecha_emi	LIKE cxct020.z20_fecha_emi,
				fecha_vcto	LIKE cxct020.z20_fecha_vcto,
				fecha_pago	LIKE cxct020.z20_fecha_vcto,
				val_ori		LIKE cxct020.z20_valor_cap,
				saldo		LIKE cxct020.z20_saldo_cap
			END RECORD
DEFINE r_rep_nc		RECORD
				z21_localidad	LIKE cxct021.z21_localidad,
				g03_nombre	LIKE gent003.g03_nombre,
				z21_referencia	LIKE cxct021.z21_referencia,
				z21_tipo_doc	LIKE cxct021.z21_tipo_doc,
				z21_num_doc	LIKE cxct021.z21_num_doc,
				z21_num_sri	LIKE cxct021.z21_num_sri,
				z21_fecha_emi	LIKE cxct021.z21_fecha_emi,
				z21_valor	LIKE cxct021.z21_valor,
				z21_saldo	LIKE cxct021.z21_saldo
			END RECORD
DEFINE r_aux		RECORD
				cod_tran	LIKE cxct020.z20_cod_tran,
				num_tran	LIKE cxct020.z20_num_tran
			END RECORD
DEFINE r_g02		RECORD LIKE gent002.*
DEFINE r_g03		RECORD LIKE gent003.*
DEFINE aux_i, aux_n	CHAR(1)
DEFINE i, data_found	INTEGER
DEFINE comando		VARCHAR(100)

OPEN WINDOW w_imp AT 07, 25 WITH FORM "../forms/cxcf314_10" 
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
START REPORT report_estado_cta_cliente TO PIPE comando
LET data_found = 0
FOR i = 1 TO vm_num_doc
	LET r_report.tit_local  = rm_dcli[i].tit_loc
	CALL fl_lee_localidad(vg_codcia, r_report.tit_local) RETURNING r_g02.*
	LET r_report.tit_loc    = r_g02.g02_nombre
	CALL fl_lee_area_negocio(vg_codcia, rm_dcli[i].tit_area)
		RETURNING r_g03.*
	LET r_report.areaneg    = r_g03.g03_nombre
	LET r_report.tipo_doc   = rm_dcli[i].z20_tipo_doc
	SELECT numdoc, dividendo, fecha_cobro, valor_doc, doc_sri, cod_tran,
			num_tran
		INTO r_report.num_doc, r_report.dividendo, r_report.fecha_pago,
			r_report.val_ori, r_report.num_sri, r_aux.*
		FROM tempo_doc 
		WHERE ROWID = rm_rowid[i]
	IF r_report.num_sri IS NULL THEN
		CALL obtener_num_sri(r_aux.cod_tran, r_aux.num_tran,
					r_report.tit_local, r_g03.g03_areaneg)
			RETURNING r_report.num_sri
	END IF
	LET r_report.fecha_emi  = rm_dcli[i].z20_fecha_emi
	LET r_report.fecha_vcto = rm_dcli[i].z20_fecha_vcto
	LET r_report.saldo      = rm_dcli[i].saldo
	LET data_found          = 1
	OUTPUT TO REPORT report_estado_cta_cliente(r_report.*)
END FOR
FINISH REPORT report_estado_cta_cliente
IF NOT data_found THEN
	CALL fl_mostrar_mensaje('No se ha encontrado documentos deudores con saldo.', 'info')
END IF
IF vm_incluir_nc = 'N' THEN
	RETURN
END IF
DECLARE q_imp_nc CURSOR FOR
	SELECT localidad, g03_nombre, z21_referencia, cladoc, numdoc, doc_sri,
			fecha_emi, valor_doc, saldo_doc
		FROM tempo_doc, cxct021, gent003
		WHERE tipo_doc      = 'F'
		  AND codcli        = rm_z01.z01_codcli
		  AND z21_compania  = vg_codcia
		  AND z21_localidad = localidad
		  AND z21_codcli    = codcli
		  AND z21_tipo_doc  = cladoc
		  AND z21_num_doc   = numdoc
		  AND g03_compania  = z21_compania
		  AND g03_areaneg   = z21_areaneg
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



REPORT report_estado_cta_cliente(r_report)
DEFINE r_report		RECORD
				tit_local	LIKE cxct020.z20_localidad,
				tit_loc		LIKE gent002.g02_nombre,
				areaneg 	LIKE gent003.g03_nombre,
				tipo_doc	LIKE cxct020.z20_tipo_doc,
				num_doc		LIKE cxct020.z20_num_doc,
				dividendo	LIKE cxct020.z20_dividendo,
				num_sri		LIKE cxct020.z20_num_sri,
				fecha_emi	LIKE cxct020.z20_fecha_emi,
				fecha_vcto	LIKE cxct020.z20_fecha_vcto,
				fecha_pago	LIKE cxct020.z20_fecha_vcto,
				val_ori		LIKE cxct020.z20_valor_cap,
				saldo		LIKE cxct020.z20_saldo_cap
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
	CALL fl_justifica_titulo('C', 'ESTADO DE CUENTAS DE CLIENTES', 80)
		RETURNING titulo
	CALL fl_lee_compania(vg_codcia) RETURNING r_g01.*
	print ASCII escape;
	print ASCII act_comp
	PRINT COLUMN 001, r_g01.g01_razonsocial,
	      COLUMN 122, "PAGINA: ", PAGENO USING "&&&"
	PRINT COLUMN 001, modulo CLIPPED,
	      COLUMN 040, titulo,
	      COLUMN 126, UPSHIFT(vg_proceso) CLIPPED
	SKIP 2 LINES
	IF rm_par.fecha_emi IS NOT NULL THEN
		PRINT COLUMN 001, "DESDE         : ",
			rm_par.fecha_emi USING "dd-mm-yyyy", "  HASTA EL ",
			rm_par.fecha_cart USING "dd-mm-yyyy"
	ELSE
		PRINT COLUMN 001, "     HASTA EL : ",
			rm_par.fecha_cart USING "dd-mm-yyyy"
	END IF
	IF rm_par.localidad IS NOT NULL THEN
		PRINT COLUMN 001, "LOCALIDAD     : ",
			rm_par.localidad USING "&&", " ", rm_par.tit_localidad,
		      COLUMN 099, "TOTAL A FAVOR   : ", tot_favor
						USING "-,---,---,--&.##"
	ELSE
		PRINT COLUMN 001, "LOCALIDAD     : T O D A S", 
		      COLUMN 099, "TOTAL A FAVOR   : ", tot_favor
						USING "-,---,---,--&.##"
	END IF
	PRINT COLUMN 001, "CODIGO        : ", rm_z01.z01_codcli USING "<<<<&&",
	      COLUMN 099, "TOTAL POR VENCER: ", tot_xven
						USING "-,---,---,--&.##"
	PRINT COLUMN 001, "NOMBRE        : ", rm_z01.z01_nomcli[1, 80] CLIPPED,
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
	PRINT COLUMN 001, "LOCALIDAD",
	      COLUMN 017, "AREA NEG.",
	      COLUMN 028, "DOCUMENTO",
	      COLUMN 050, "NUMERO SRI",
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
	PRINT COLUMN 001, r_report.tit_loc[1, 15] CLIPPED,
	      COLUMN 017, r_report.areaneg[1, 10] CLIPPED,
	      COLUMN 028, r_report.tipo_doc, "-", r_report.num_doc CLIPPED, "-",
	      		  r_report.dividendo	USING "<<&&",
	      COLUMN 050, r_report.num_sri	CLIPPED,
	      COLUMN 067, r_report.fecha_emi	USING "dd-mm-yyyy",
	      COLUMN 078, r_report.fecha_vcto	USING "dd-mm-yyyy",
	      COLUMN 089, r_report.fecha_pago	USING "dd-mm-yyyy",
	      COLUMN 100, r_report.val_ori	USING "-,---,---,--&.##",
	      COLUMN 117, r_report.saldo	USING "-,---,---,--&.##"
	IF vm_imprimir = 'D' THEN
		LET expr_doc = "   AND z23_tipo_doc = '", r_report.tipo_doc,"'",
				"   AND z23_num_doc  = '", r_report.num_doc, "'"
		CALL query_mov(r_report.tit_local, expr_doc, 0)
			RETURNING expr_sql
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
				z21_localidad	LIKE cxct021.z21_localidad,
				g03_nombre	LIKE gent003.g03_nombre,
				z21_referencia	LIKE cxct021.z21_referencia,
				z21_tipo_doc	LIKE cxct021.z21_tipo_doc,
				z21_num_doc	LIKE cxct021.z21_num_doc,
				z21_num_sri	LIKE cxct021.z21_num_sri,
				z21_fecha_emi	LIKE cxct021.z21_fecha_emi,
				z21_valor	LIKE cxct021.z21_valor,
				z21_saldo	LIKE cxct021.z21_saldo
			END RECORD
DEFINE r_g01		RECORD LIKE gent001.*
DEFINE r_g50		RECORD LIKE gent050.*
DEFINE r_z20		RECORD LIKE cxct020.*
DEFINE fecha_pago	LIKE cxct022.z22_fecha_emi
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
	IF rm_par.localidad IS NOT NULL THEN
		PRINT COLUMN 001, "LOCALIDAD     : ",
			rm_par.localidad USING "&&", " ", rm_par.tit_localidad
	ELSE
		PRINT COLUMN 001, "LOCALIDAD     : T O D A S" 
	END IF
	PRINT COLUMN 001, "CODIGO        : ", rm_z01.z01_codcli USING "<<<<&&"
	PRINT COLUMN 001, "NOMBRE        : ", rm_z01.z01_nomcli[1, 80] CLIPPED
	PRINT COLUMN 001, "MONEDA        : ", rm_par.tit_mon,
		      COLUMN 102, "TOTAL A FAVOR: ", tot_favor
						USING "-,---,---,--&.##"
	SKIP 1 LINES
	PRINT COLUMN 001, "FECHA DE IMPRESION: ", TODAY USING "dd-mm-yyyy", 
	                 1 SPACES, TIME,
	      COLUMN 114, usuario
	PRINT "------------------------------------------------------------------------------------------------------------------------------------"
	PRINT COLUMN 009, "R E F E R E N C I A",
	      COLUMN 037, "AREA NEGOCIO",
	      COLUMN 053, "DOCUMENTO",
	      COLUMN 072, "NUMERO SRI",
	      COLUMN 089, "FECHA EMI.",
	      COLUMN 100, "  VALOR ORIGINAL",
	      COLUMN 117, " SALDO DOCUMENTO"
	PRINT "------------------------------------------------------------------------------------------------------------------------------------"

ON EVERY ROW
	NEED 3 LINES
	PRINT COLUMN 001, r_rep_nc.z21_referencia CLIPPED,
	      COLUMN 037, r_rep_nc.g03_nombre     CLIPPED,
	      COLUMN 053, r_rep_nc.z21_tipo_doc, "-",
				r_rep_nc.z21_num_doc USING "<<<<<<<<<&",
	      COLUMN 072, r_rep_nc.z21_num_sri    CLIPPED,
	      COLUMN 089, r_rep_nc.z21_fecha_emi  USING "dd-mm-yyyy",
	      COLUMN 100, r_rep_nc.z21_valor      USING "-,---,---,--&.##",
	      COLUMN 117, r_rep_nc.z21_saldo      USING "-,---,---,--&.##"
	IF vm_imprimir = 'D' THEN
		LET expr_doc = "   AND z23_tipo_favor = '",
					r_rep_nc.z21_tipo_doc, "'",
				"   AND z23_doc_favor = ",
					r_rep_nc.z21_num_doc
		CALL query_mov(r_rep_nc.z21_localidad, expr_doc, 1)
			RETURNING expr_sql
		PREPARE det2 FROM expr_sql
		DECLARE q_det2 CURSOR FOR det2
		FOREACH	q_det2 INTO r_rep_nc.z21_tipo_doc, num_trn,
				r_z20.z20_tipo_doc, r_z20.z20_num_doc,
				r_z20.z20_dividendo, r_rep_nc.z21_fecha_emi,
				fecha_pago, r_rep_nc.z21_valor
			PRINT COLUMN 003, "APLIC.: ",
				r_z20.z20_tipo_doc, "-",
				r_z20.z20_num_doc CLIPPED, "-",
				r_z20.z20_dividendo USING "&&",
			      COLUMN 028, r_rep_nc.z21_tipo_doc, "-",
				num_trn CLIPPED,
	      		      COLUMN 067, r_rep_nc.z21_fecha_emi
					USING "dd-mm-yyyy",
      			      COLUMN 089, fecha_pago
					USING "dd-mm-yyyy",
	      		      COLUMN 100, r_rep_nc.z21_valor
					USING "#,###,###,##&.##"
		END FOREACH
		SKIP 1 LINES
	END IF

ON LAST ROW
	PRINT COLUMN 117, "----------------"
	PRINT COLUMN 096, "S A L D O  (N/C) ==> ",
	      COLUMN 117, SUM(r_rep_nc.z21_saldo) USING "-,---,---,--&.##";
	print ASCII escape;
	print ASCII desact_comp 

END REPORT



FUNCTION query_mov(loc, expr_doc, flag)
DEFINE loc		LIKE gent002.g02_localidad
DEFINE expr_doc		VARCHAR(100)
DEFINE flag		SMALLINT
DEFINE doc_deu		VARCHAR(50)
DEFINE expr_loc		VARCHAR(50)
DEFINE expr_sql 	CHAR(1200)

LET doc_deu = NULL
IF flag THEN
	LET doc_deu = "z23_tipo_doc, z23_num_doc, z23_div_doc, "
END IF
LET expr_loc = NULL
IF loc IS NOT NULL THEN
	LET expr_loc = "   AND z23_localidad  = ", loc
END IF
LET expr_sql = "SELECT z23_tipo_trn, z23_num_trn, ", doc_deu CLIPPED,
			" z22_fecha_emi, z22_fecing, z23_valor_cap ",
			" FROM cxct023, cxct022 ",
			" WHERE z23_compania   = ", vg_codcia,
			expr_loc CLIPPED,
			"   AND z23_codcli     = ", rm_z01.z01_codcli,
			expr_doc CLIPPED,
			"   AND z22_compania   = z23_compania ",
			"   AND z22_localidad  = z23_localidad ",
			"   AND z22_codcli     = z23_codcli ",
			"   AND z22_tipo_trn   = z23_tipo_trn ",
			"   AND z22_num_trn    = z23_num_trn ",
			"   AND z22_fecha_emi <= '", rm_par.fecha_cart, "'",
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
DISPLAY '<F5>      Ver Factura'              AT a,2
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
DISPLAY '<F5>      Pago Caja'                AT a,2
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
DISPLAY '<F5>      Pago Caja'                AT a,2
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
