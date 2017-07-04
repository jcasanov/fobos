------------------------------------------------------------------------------
-- Titulo           : cxpp305.4gl - Consulta Documentos a Favor
-- Elaboracion      : 30-May-2002
-- Autor            : YEC
-- Formato Ejecucion: fglrun cxpp305.4gl base_datos modulo compañía localidad
--                    fglrun cxpp305.4gl base_datos modulo compañía localidad
--					 moneda fecha_ini fecha_fin
-- Ultima Correccion: 
-- Motivo Correccion:
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE rm_orden ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1	SMALLINT
DEFINE vm_columna_2	SMALLINT
DEFINE rm_mon		RECORD LIKE gent013.*
DEFINE num_doc		SMALLINT
DEFINE num_max_doc	SMALLINT
DEFINE rm_par RECORD
		moneda          LIKE gent013.g13_moneda,
		tit_mon         LIKE gent013.g13_nombre,
		tipo_doc	LIKE cxpt021.p21_tipo_doc,
		tit_tipo	VARCHAR(30),
		fecha_ini	DATE,
		fecha_fin	DATE,
		flag_saldo	CHAR(1)
	END RECORD
DEFINE rm_ant ARRAY[1500] OF RECORD
		p21_fecha_emi   LIKE cxpt021.p21_fecha_emi,
		p21_tipo_doc	LIKE cxpt021.p21_tipo_doc,
		p21_num_doc	LIKE cxpt021.p21_num_doc,
		nomprov		LIKE cxpt001.p01_nomprov,
		p21_valor	LIKE cxpt021.p21_valor,
		p21_saldo	LIKE cxpt021.p21_saldo
	END RECORD
DEFINE rm_aux ARRAY[1500] OF RECORD
		codprov		LIKE cxpt021.p21_codprov
	END RECORD
DEFINE tot_valor	DECIMAL(14,2)
DEFINE tot_saldo	DECIMAL(14,2)

MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/errores')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 AND num_args() <> 7 THEN     -- Validar # parámetros correcto
	CALL fgl_winmessage(vg_producto, 'Número de parámetros incorrecto', 'stop')
	EXIT PROGRAM
END IF
LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_codcia   = arg_val(3)
LET vg_codloc   = arg_val(4)
LET vg_proceso = 'cxpp305'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
--#CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()

END MAIN



FUNCTION funcion_master()
DEFINE r		RECORD LIKE gent000.*
DEFINE i		SMALLINT

LET num_max_doc = 1500
INITIALIZE rm_par.* TO NULL
LET rm_par.flag_saldo  = 'S'
CALL fl_lee_configuracion_facturacion() RETURNING r.*
IF num_args() = 4 THEN
	LET rm_par.moneda    = r.g00_moneda_base
ELSE
	LET rm_par.moneda = arg_val(5)
	LET rm_par.fecha_ini = arg_val(6)
	LET rm_par.fecha_fin = arg_val(7)
END IF
CALL fl_lee_moneda(rm_par.moneda) RETURNING rm_mon.*
LET rm_par.tit_mon = rm_mon.g13_nombre
OPEN WINDOW w_imp AT 3,2 WITH 22 ROWS, 80 COLUMNS
	ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE FIRST,
		  BORDER, MESSAGE LINE LAST) 
OPEN FORM f_par FROM "../forms/cxpf305_1"
DISPLAY FORM f_par
DISPLAY BY NAME rm_par.*
CALL titulos_columnas()
WHILE TRUE
	CREATE TEMP TABLE tempo_fav 
		(p21_fecha_emi  DATE,
		 p21_tipo_doc	CHAR(2),
		 p21_num_doc	INTEGER,
		 nomprov	CHAR(40),
		 p21_valor	DECIMAL(14,2),
		 p21_saldo	DECIMAL(14,2),
		 p21_codprov	INTEGER)
	FOR i = 1 TO 10
		LET rm_orden[i] = '' 
	END FOR
	LET rm_orden[1] = 'ASC'
	LET vm_columna_1 = 1
	LET vm_columna_2 = 3
	IF num_args() = 4 THEN
		CALL lee_parametros() 
		IF int_flag THEN
			RETURN
		END IF
	END IF
	CALL genera_tabla_trabajo()
	IF num_doc > 0 THEN
		CALL muestra_datos()
	END IF
	DROP TABLE tempo_fav 
	IF num_args() <> 4 THEN
		EXIT WHILE
	END IF
END WHILE

END FUNCTION



FUNCTION lee_parametros()
DEFINE mon_aux		LIKE gent013.g13_moneda
DEFINE tit_mon		LIKE gent013.g13_nombre
DEFINE cod_tipo		LIKE cxpt021.p21_tipo_doc
DEFINE tit_tipo		VARCHAR(30)
DEFINE r_an		RECORD LIKE gent003.*
DEFINE r_mo		RECORD LIKE gent013.*
DEFINE r_tip		RECORD LIKE cxpt004.*
DEFINE num		SMALLINT

LET int_flag = 0
INPUT BY NAME rm_par.* WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		CLOSE FORM f_par
		RETURN
	ON KEY(F2)
		IF INFIELD(moneda) THEN
			CALL fl_ayuda_monedas() RETURNING mon_aux, tit_mon, num
			IF mon_aux IS NOT NULL THEN
				LET rm_par.moneda  = mon_aux
				LET rm_par.tit_mon = tit_mon
				DISPLAY BY NAME rm_par.moneda, rm_par.tit_mon
			END IF
		END IF
		IF INFIELD(tipo_doc) THEN
			CALL fl_ayuda_tipo_documento_cobranzas('F')
				RETURNING cod_tipo, tit_tipo
			LET int_flag = 0
			IF cod_tipo IS NOT NULL THEN
				LET rm_par.tipo_doc = cod_tipo
				LET rm_par.tit_tipo = tit_tipo
				DISPLAY BY NAME rm_par.*
			END IF 
		END IF
		LET int_flag = 0
	AFTER FIELD moneda
		IF rm_par.moneda IS NOT NULL THEN
			CALL fl_lee_moneda(rm_par.moneda)
				RETURNING r_mo.*
			IF r_mo.g13_moneda IS NULL THEN
				CALL fgl_winmessage(vg_producto, 'No existe moneda', 'exclamation')
				NEXT FIELD moneda
			END IF
			LET rm_par.tit_mon = r_mo.g13_nombre 
			DISPLAY BY NAME rm_par.tit_mon
		ELSE
			LET rm_par.tit_mon = NULL
			DISPLAY BY NAME rm_par.tit_mon
		END IF
	AFTER FIELD tipo_doc 
		IF rm_par.tipo_doc IS NOT NULL THEN
			CALL fl_lee_tipo_doc_tesoreria(rm_par.tipo_doc)
				RETURNING r_tip.* 
			IF r_tip.p04_tipo_doc IS NULL THEN
				CALL fgl_winmessage(vg_producto,'Tipo de documento no existe.','exclamation')
				NEXT FIELD tipo_doc
			END IF
			IF r_tip.p04_tipo <> 'F' THEN
				CALL fgl_winmessage(vg_producto,'Tipo de documento debe ser a favor.','exclamation')
				NEXT FIELD tipo_doc
			END IF
			LET rm_par.tit_tipo = r_tip.p04_nombre
			DISPLAY BY NAME rm_par.*
		ELSE
			LET rm_par.tit_tipo = NULL
			CLEAR tipo_doc
		END IF
	AFTER INPUT 
		IF rm_par.fecha_ini > rm_par.fecha_fin THEN
			CALL fgl_winmessage(vg_producto, 'Rango incorrecto', 'exclamation')
			NEXT FIELD fecha_ini
		END IF
		IF rm_par.fecha_ini IS NULL THEN
			LET rm_par.fecha_ini = MDY(1,1,2000)
			LET rm_par.fecha_fin = TODAY
		END IF
END INPUT

END FUNCTION



FUNCTION titulos_columnas()

DISPLAY 'Fecha'          TO tit_col1
DISPLAY 'T.'             TO tit_col2
DISPLAY 'Número'         TO tit_col3
DISPLAY 'C l i e n t e'  TO tit_col4
DISPLAY 'Valor Original' TO tit_col5
DISPLAY 'S a l d o'      TO tit_col6

END FUNCTION



FUNCTION genera_tabla_trabajo()
DEFINE r_p21		RECORD LIKE cxpt021.*
DEFINE nomprov		VARCHAR(35)

DECLARE k_fav CURSOR FOR 
	SELECT cxpt021.*, p01_nomprov FROM cxpt021, cxpt001
		WHERE p21_compania  = vg_codcia AND 
		      p21_localidad = vg_codloc AND
		      p21_fecha_emi BETWEEN rm_par.fecha_ini AND 
					    rm_par.fecha_fin AND
		      p21_moneda    = rm_par.moneda AND 
		      p21_codprov    = p01_codprov
LET num_doc = 0
FOREACH k_fav INTO r_p21.*, nomprov
	IF rm_par.flag_saldo = 'S' THEN
		IF r_p21.p21_saldo <= 0 THEN
			CONTINUE FOREACH
		END IF
	END IF
	IF rm_par.tipo_doc IS NOT NULL THEN
		IF rm_par.tipo_doc <> r_p21.p21_tipo_doc THEN
			CONTINUE FOREACH
		END IF
	END IF
	LET num_doc = num_doc + 1
	INSERT INTO tempo_fav VALUES(r_p21.p21_fecha_emi, r_p21.p21_tipo_doc,
		r_p21.p21_num_doc, nomprov, r_p21.p21_valor, r_p21.p21_saldo,
		r_p21.p21_codprov)
	IF num_doc = num_max_doc THEN
		EXIT FOREACH
	END IF
END FOREACH
IF num_doc = 0 THEN
	CALL fl_mensaje_consulta_sin_registros()
END IF

END FUNCTION



FUNCTION muestra_datos()
DEFINE query		VARCHAR(300)
DEFINE comando		VARCHAR(300)
DEFINE i, pos_arr	SMALLINT

WHILE TRUE
	LET int_flag = 0
	DECLARE jk_tp CURSOR FOR SELECT * FROM tempo_fav
	LET query = 'SELECT * FROM tempo_fav ',
			' ORDER BY ',
			vm_columna_1, ' ', rm_orden[vm_columna_1], ',', 
			vm_columna_2, ' ', rm_orden[vm_columna_2] 
	PREPARE ytp FROM query
	DECLARE jk_ytp CURSOR FOR ytp
	LET i = 1
	LET tot_valor = 0
	LET tot_saldo = 0
	FOREACH jk_ytp INTO rm_ant[i].*, rm_aux[i].*
		LET tot_valor = tot_valor + rm_ant[i].p21_valor
		LET tot_saldo = tot_saldo + rm_ant[i].p21_saldo
		LET i = i + 1
	END FOREACH
	DISPLAY BY NAME tot_valor, tot_saldo
	CALL set_count(i - 1)
	DISPLAY ARRAY rm_ant TO rm_ant.*
		BEFORE DISPLAY
			--#CALL dialog.keysetlabel("ACCEPT","")
		AFTER DISPLAY
			CONTINUE DISPLAY
		BEFORE ROW
			LET pos_arr = arr_curr()
			IF rm_ant[pos_arr].p21_tipo_doc <> 'PA' THEN
				--#CALL dialog.keysetlabel("F5","")
			ELSE
				--#CALL dialog.keysetlabel("F5","Cheque")
			END IF
		ON KEY(INTERRUPT)
			EXIT DISPLAY
		ON KEY(F5)
			CALL muestra_cheque_emitido(vg_codcia, vg_codloc, 
				rm_aux[pos_arr].codprov,
				rm_ant[pos_arr].p21_tipo_doc, 
				rm_ant[pos_arr].p21_num_doc) 
		ON KEY(F6)
			LET comando = 'fglrun cxpp201 ' || vg_base || ' ' ||
			      vg_modulo || ' ' ||
			      vg_codcia || ' ' || 
			      vg_codloc || ' ' ||
			      rm_aux[pos_arr].codprov || ' ' ||
			      rm_ant[pos_arr].p21_tipo_doc || ' ' ||
			      rm_ant[pos_arr].p21_num_doc
			RUN comando
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
		ON KEY(F19)
			LET i = 5
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F20)
			LET i = 6
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
	
END FUNCTION



FUNCTION muestra_cheque_emitido(codcia, codloc, codprov, tipo_trn, num_trn)
DEFINE codcia		LIKE cxpt024.p24_compania
DEFINE codloc		LIKE cxpt024.p24_localidad
DEFINE codprov		LIKE cxpt001.p01_codprov
DEFINE tipo_trn		LIKE cxpt022.p22_tipo_trn
DEFINE num_trn		LIKE cxpt022.p22_num_trn
DEFINE c		CHAR(1)
DEFINE r		RECORD LIKE cxpt024.*
DEFINE r_ban		RECORD LIKE gent008.*
DEFINE r_td		RECORD LIKE cxpt004.*
DEFINE r_fav		RECORD LIKE cxpt021.*
DEFINE r_trn		RECORD LIKE cxpt022.*
DEFINE comando		VARCHAR(200)
DEFINE orden_pago	INTEGER

CALL fl_lee_tipo_doc_tesoreria(tipo_trn) RETURNING r_td.*
IF r_td.p04_tipo IS NULL THEN
	RETURN
END IF
LET orden_pago = NULL
IF r_td.p04_tipo = 'F' THEN
	CALL fl_lee_documento_favor_cxp(codcia, codloc, codprov, tipo_trn, 
					num_trn)
		RETURNING r_fav.*
	LET orden_pago = r_fav.p21_orden_pago
ELSE
	CALL fl_lee_transaccion_cxp(codcia, codloc, codprov, tipo_trn, 
					num_trn)
		RETURNING r_trn.*
	LET orden_pago = r_trn.p22_orden_pago
END IF
CALL fl_lee_orden_pago_cxp(codcia, codloc, orden_pago)
	RETURNING r.*
IF r.p24_orden_pago IS NULL THEN
	RETURN
END IF
OPEN WINDOW w_pch AT 7,20 WITH FORM "../forms/cxpf300_6"
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, BORDER, MENU LINE 0)
IF status = NOTFOUND THEN
	CALL fgl_winmessage(vg_producto, 'No existe registro en órdenes de pago', 'exclamation')
	CLOSE WINDOW w_pch
	RETURN
END IF
CALL fl_lee_banco_general(r.p24_banco) RETURNING r_ban.*
DISPLAY r_ban.g08_nombre TO banco
DISPLAY BY NAME r.p24_numero_cta, r.p24_numero_che, r.p24_tip_contable, 
		r.p24_num_contable
LET int_flag = 0
MENU 'OPCIONES'
	COMMAND KEY('C') 'Contabilización' 
		LET comando = 'cd ..', vg_separador, '..', vg_separador,
			       'CONTABILIDAD', vg_separador, 'fuentes; ',
			       'fglrun ctbp201 ', vg_base, ' CB ',
				vg_codcia, ' ', r.p24_tip_contable, ' ',
				r.p24_num_contable
		RUN comando
	COMMAND KEY('S') 'Salir'
		EXIT MENU
END MENU
LET int_flag = 0
CLOSE WINDOW w_pch

END FUNCTION



FUNCTION no_validar_parametros()

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
