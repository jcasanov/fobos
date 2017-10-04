------------------------------------------------------------------------------
-- Titulo           : cxcp300.4gl - Consulta Documentos a Favor
-- Elaboracion      : 28-May-2002
-- Autor            : YEC
-- Formato Ejecucion: fglrun cxcp300.4gl base_datos modulo compañía localidad
--                    fglrun cxcp300.4gl base_datos modulo compañía localidad
--					 moneda fecha_ini fecha_fin
-- Ultima Correccion: 
-- Motivo Correccion:
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE rm_orden 	ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1	SMALLINT
DEFINE vm_columna_2	SMALLINT
DEFINE rm_mon		RECORD LIKE gent013.*
DEFINE num_doc		INTEGER
DEFINE num_max_doc	INTEGER
DEFINE rm_par 		RECORD
				moneda          LIKE gent013.g13_moneda,
				tit_mon         LIKE gent013.g13_nombre,
				tipo_doc	LIKE cxct021.z21_tipo_doc,
				tit_tipo	VARCHAR(30),
				area_n          LIKE gent003.g03_areaneg,
				tit_area        LIKE gent003.g03_nombre,
				fecha_ini	DATE,
				fecha_fin	DATE,
				flag_saldo	CHAR(1)
			END RECORD
DEFINE rm_ant 		ARRAY[30000] OF RECORD
				z21_fecha_emi   LIKE cxct021.z21_fecha_emi,
				z21_tipo_doc	LIKE cxct021.z21_tipo_doc,
				z21_num_doc	LIKE cxct021.z21_num_doc,
				nomcli		LIKE cxct001.z01_nomcli,
				z21_valor	LIKE cxct021.z21_valor,
				z21_saldo	LIKE cxct021.z21_saldo
			END RECORD
DEFINE rm_aux		ARRAY[30000] OF RECORD
				codcli		LIKE cxct021.z21_codcli,
				arean		LIKE cxct021.z21_areaneg
			END RECORD
DEFINE tot_valor	DECIMAL(14,2)
DEFINE tot_saldo	DECIMAL(14,2)



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/cxcp300.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 AND num_args() <> 7 THEN     -- Validar # parámetros correcto
	--CALL fgl_winmessage(vg_producto,'Número de parámetros incorrecto', 'stop')
	CALL fl_mostrar_mensaje('Número de parámetros incorrecto.', 'stop')
	EXIT PROGRAM
END IF
LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_codcia   = arg_val(3)
LET vg_codloc   = arg_val(4)
LET vg_proceso = 'cxcp300'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
--#CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()

END MAIN



FUNCTION funcion_master()
DEFINE r		RECORD LIKE gent000.*
DEFINE i		INTEGER
DEFINE lin_menu		SMALLINT
DEFINE row_ini  	SMALLINT
DEFINE num_rows 	SMALLINT
DEFINE num_cols 	SMALLINT

LET num_max_doc = 30000
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
OPEN WINDOW w_imp AT row_ini, 2 WITH num_rows ROWS, num_cols COLUMNS
	ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE lin_menu,
		  BORDER, MESSAGE LINE LAST - 1) 
IF vg_gui = 1 THEN
	OPEN FORM f_par FROM "../forms/cxcf300_1"
ELSE
	OPEN FORM f_par FROM "../forms/cxcf300_1c"
END IF
DISPLAY FORM f_par
DISPLAY BY NAME rm_par.*
CALL titulos_columnas()
WHILE TRUE
	CREATE TEMP TABLE tempo_fav 
		(z21_fecha_emi  DATE,
		 z21_tipo_doc	CHAR(2),
		 z21_num_doc	INTEGER,
		 nomcli		CHAR(40),
		 z21_valor	DECIMAL(14,2),
		 z21_saldo	DECIMAL(14,2),
		 z21_codcli	INTEGER,
		 z21_areaneg	SMALLINT)
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
DEFINE area_aux		LIKE gent003.g03_areaneg
DEFINE tit_area		LIKE gent003.g03_nombre
DEFINE cod_tipo		LIKE cxct021.z21_tipo_doc
DEFINE tit_tipo		VARCHAR(30)
DEFINE r_an		RECORD LIKE gent003.*
DEFINE r_mo		RECORD LIKE gent013.*
DEFINE r_tip		RECORD LIKE cxct004.*
DEFINE num		INTEGER

LET int_flag = 0
INPUT BY NAME rm_par.* WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		CLOSE FORM f_par
		RETURN
        ON KEY(F1,CONTROL-W)
		CALL llamar_visor_teclas()
	ON KEY(F2)
		IF INFIELD(area_n) THEN
			CALL fl_ayuda_areaneg(vg_codcia) 
				RETURNING area_aux, tit_area
			IF area_aux IS NOT NULL THEN
				LET rm_par.area_n   = area_aux
				LET rm_par.tit_area = tit_area
 				DISPLAY BY NAME rm_par.area_n, rm_par.tit_area
			END IF
		END IF
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
	BEFORE INPUT
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
	AFTER FIELD moneda
		IF rm_par.moneda IS NOT NULL THEN
			CALL fl_lee_moneda(rm_par.moneda)
				RETURNING r_mo.*
			IF r_mo.g13_moneda IS NULL THEN
				--CALL fgl_winmessage(vg_producto,'No existe moneda', 'exclamation')
				CALL fl_mostrar_mensaje('No existe moneda.', 'exclamation')
				NEXT FIELD moneda
			END IF
			LET rm_par.tit_mon = r_mo.g13_nombre 
			DISPLAY BY NAME rm_par.tit_mon
		ELSE
			LET rm_par.tit_mon = NULL
			DISPLAY BY NAME rm_par.tit_mon
		END IF
	AFTER FIELD area_n
		IF rm_par.area_n IS NOT NULL THEN
			CALL fl_lee_area_negocio(vg_codcia, rm_par.area_n)
				RETURNING r_an.*
			IF r_an.g03_compania IS NULL THEN
				--CALL fgl_winmessage(vg_producto,'No existe área de negocio', 'exclamation')
				CALL fl_mostrar_mensaje('No existe área de negocio', 'exclamation')
				NEXT FIELD area_n
			END IF
			LET rm_par.tit_area = r_an.g03_nombre
			DISPLAY BY NAME rm_par.tit_area
		ELSE
			LET rm_par.tit_area = NULL
			DISPLAY BY NAME rm_par.tit_area
		END IF
	AFTER FIELD tipo_doc 
		IF rm_par.tipo_doc IS NOT NULL THEN
			CALL fl_lee_tipo_doc(rm_par.tipo_doc)
				RETURNING r_tip.* 
			IF r_tip.z04_tipo_doc IS NULL THEN
				--CALL fgl_winmessage(vg_producto,'Tipo de documento no existe.','exclamation')
				CALL fl_mostrar_mensaje('Tipo de documento no existe.','exclamation')
				NEXT FIELD tipo_doc
			END IF
			IF r_tip.z04_tipo <> 'F' THEN
				--CALL fgl_winmessage(vg_producto,'Tipo de documento debe ser a favor.','exclamation')
				CALL fl_mostrar_mensaje('Tipo de documento debe ser a favor.','exclamation')
				NEXT FIELD tipo_doc
			END IF
			LET rm_par.tit_tipo = r_tip.z04_nombre
			DISPLAY BY NAME rm_par.*
		ELSE
			LET rm_par.tit_tipo = NULL
			CLEAR tipo_doc
		END IF
	AFTER INPUT 
		IF rm_par.fecha_ini > rm_par.fecha_fin THEN
			--CALL fgl_winmessage(vg_producto,'Rango incorrecto', 'exclamation')
			CALL fl_mostrar_mensaje('Rango incorrecto.','exclamation')
			NEXT FIELD fecha_ini
		END IF
		IF rm_par.fecha_ini IS NULL THEN
			LET rm_par.fecha_ini = MDY(1,1,2000)
			LET rm_par.fecha_fin = vg_fecha
		END IF
END INPUT

END FUNCTION



FUNCTION titulos_columnas()

--#DISPLAY 'Fecha'          TO tit_col1
--#DISPLAY 'T.'             TO tit_col2
--#DISPLAY 'Número'         TO tit_col3
--#DISPLAY 'C l i e n t e'  TO tit_col4
--#DISPLAY 'Valor Original' TO tit_col5
--#DISPLAY 'S a l d o'      TO tit_col6

END FUNCTION



FUNCTION genera_tabla_trabajo()
DEFINE r_z21		RECORD LIKE cxct021.*
DEFINE nomcli		VARCHAR(35)

DECLARE k_fav CURSOR FOR 
	SELECT cxct021.*, z01_nomcli FROM cxct021, cxct001
		WHERE z21_compania  = vg_codcia AND 
		      --z21_localidad = vg_codloc AND
		      z21_fecha_emi BETWEEN rm_par.fecha_ini AND 
					    rm_par.fecha_fin AND
		      z21_moneda    = rm_par.moneda AND 
		      z21_codcli    = z01_codcli
LET num_doc = 0
FOREACH k_fav INTO r_z21.*, nomcli
	IF rm_par.flag_saldo = 'S' THEN
		IF r_z21.z21_saldo <= 0 THEN
			CONTINUE FOREACH
		END IF
	END IF
	IF rm_par.area_n IS NOT NULL THEN
		IF rm_par.area_n <> r_z21.z21_areaneg THEN
			CONTINUE FOREACH
		END IF
	END IF
	IF rm_par.tipo_doc IS NOT NULL THEN
		IF rm_par.tipo_doc <> r_z21.z21_tipo_doc THEN
			CONTINUE FOREACH
		END IF
	END IF
	LET num_doc = num_doc + 1
	INSERT INTO tempo_fav VALUES(r_z21.z21_fecha_emi, r_z21.z21_tipo_doc,
		r_z21.z21_num_doc, nomcli, r_z21.z21_valor, r_z21.z21_saldo,
		r_z21.z21_codcli, r_z21.z21_areaneg)
	IF num_doc = num_max_doc THEN
		EXIT FOREACH
	END IF
END FOREACH
IF num_doc = 0 THEN
	CALL fl_mensaje_consulta_sin_registros()
END IF

END FUNCTION



FUNCTION muestra_datos()
DEFINE query		CHAR(300)
DEFINE comando		CHAR(300)
DEFINE i, pos_arr	INTEGER
DEFINE run_prog		CHAR(10)

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
		LET tot_valor = tot_valor + rm_ant[i].z21_valor
		LET tot_saldo = tot_saldo + rm_ant[i].z21_saldo
		LET i = i + 1
	END FOREACH
	DISPLAY BY NAME tot_valor, tot_saldo
	CALL set_count(i - 1)
	DISPLAY ARRAY rm_ant TO rm_ant.*
		--#BEFORE DISPLAY
			--#CALL dialog.keysetlabel("ACCEPT","")
			--#CALL dialog.keysetlabel("F1","")
			--#CALL dialog.keysetlabel("CONTROL-W","")
		--#AFTER DISPLAY
			--#CONTINUE DISPLAY
		--#BEFORE ROW
			--#LET pos_arr = arr_curr()
			--#IF rm_ant[pos_arr].z21_tipo_doc <> 'PA' THEN
				--#CALL dialog.keysetlabel("F5","")
			--#ELSE
				--#CALL dialog.keysetlabel("F5","Pago Caja")
			--#END IF
		ON KEY(INTERRUPT)
			EXIT DISPLAY
        	ON KEY(F1,CONTROL-W)
			CALL control_visor_teclas_caracter_1() 
		ON KEY(F5)
			LET pos_arr = arr_curr()
			CALL fl_muestra_forma_pago_caja(vg_codcia, vg_codloc, rm_aux[pos_arr].arean, rm_aux[pos_arr].codcli, rm_ant[pos_arr].z21_tipo_doc, rm_ant[pos_arr].z21_num_doc) 
		ON KEY(F6)
			LET pos_arr = arr_curr()
			{- ESTO PARA LLAMAR AL PROGRAMA SEGÚN SEA EL AMBIENTE -}
			LET run_prog = 'fglrun '
			IF vg_gui = 0 THEN
				LET run_prog = 'fglgo '
			END IF
			{--- ---}
			LET comando = run_prog || 'cxcp201 ' || vg_base ||
				' ' || vg_modulo || ' ' || vg_codcia || ' ' || 
			      	vg_codloc || ' ' ||
			      	rm_aux[pos_arr].codcli || ' ' ||
			      	rm_ant[pos_arr].z21_tipo_doc || ' ' ||
			      	rm_ant[pos_arr].z21_num_doc
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
DISPLAY '<F5>      Pago Caja'                AT a,2
DISPLAY  'F5' AT a,3 ATTRIBUTE(REVERSE)
LET a = a + 1
DISPLAY '<F6>      Documento'                AT a,2
DISPLAY  'F6' AT a,3 ATTRIBUTE(REVERSE)
LET a = fgl_getkey()
CLOSE WINDOW w_tf

END FUNCTION
