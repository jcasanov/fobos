------------------------------------------------------------------------------
-- Titulo           : cxpp303.4gl - Consulta Acumulados Cartera
-- Elaboracion      : 22-Oct-2001
-- Autor            : YEC
-- Formato Ejecucion: fglrun cxpp303.4gl base_datos modulo compañía
-- Ultima Correccion: 
-- Motivo Correccion:
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_demonios	VARCHAR(12)
DEFINE rm_par RECORD
	moneda		LIKE gent013.g13_moneda,
	tit_mon		VARCHAR(30),
	localidad	LIKE gent002.g02_localidad,
	tit_local	VARCHAR(30),
	tipo_detalle	CHAR(1),
	ind_venc	CHAR(1),
	rango1_i 	SMALLINT,
	rango1_f  	SMALLINT,
	rango2_i  	SMALLINT,
	rango2_f  	SMALLINT,
	rango3_i  	SMALLINT,
	rango3_f  	SMALLINT,
	rango4_i  	SMALLINT
	END RECORD
DEFINE rm_det ARRAY[100] OF RECORD
	descripcion	VARCHAR(25),
	val_col1	DECIMAL(12,0),
	val_col2	DECIMAL(12,0),
	val_col3	DECIMAL(12,0),
	val_col4	DECIMAL(12,0),
	val_col5	DECIMAL(12,0),
	val_col6	DECIMAL(12,0),
	val_col7	DECIMAL(12,0)
	END RECORD
DEFINE rm_aux ARRAY[100] OF SMALLINT
DEFINE rm_orden ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1	SMALLINT
DEFINE vm_columna_2	SMALLINT
DEFINE vm_divisor	SMALLINT
DEFINE tot_col1		DECIMAL(14,0)
DEFINE tot_col2		DECIMAL(12,0)
DEFINE tot_col3		DECIMAL(12,0)
DEFINE tot_col4		DECIMAL(12,0)
DEFINE tot_col5		DECIMAL(12,0)
DEFINE tot_col6		DECIMAL(12,0)
DEFINE tot_col7		DECIMAL(12,0)
DEFINE rm_mon		RECORD LIKE gent013.*
DEFINE vm_max_rows	SMALLINT
DEFINE vm_num_rows	SMALLINT
DEFINE vm_num_doc	SMALLINT
DEFINE vm_max_doc	SMALLINT
DEFINE vm_num_res	SMALLINT
DEFINE rm_color ARRAY[10] OF VARCHAR(10)

MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/errores')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 3 THEN          -- Validar # parámetros correcto
	CALL fgl_winmessage(vg_producto, 'Número de parámetros incorrecto', 'stop')
	EXIT PROGRAM
END IF
LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_codcia   = arg_val(3)
LET vg_proceso = 'cxpp303'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
--#CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()

END MAIN



FUNCTION funcion_master()

INITIALIZE rm_par.* TO NULL
LET rm_par.moneda      = rg_gen.g00_moneda_base
CALL fl_lee_moneda(rm_par.moneda) RETURNING rm_mon.*
LET rm_par.tit_mon      = rm_mon.g13_nombre
LET rm_par.tipo_detalle = 'C'
LET rm_par.ind_venc     = 'V'
LET vm_divisor          = 1
LET rm_par.rango1_i     = 1
LET rm_par.rango1_f     = 30
LET rm_par.rango2_i     = 31
LET rm_par.rango2_f     = 60
LET rm_par.rango3_i     = 61
LET rm_par.rango3_f     = 90
LET rm_par.rango4_i     = 91
OPEN WINDOW w_imp AT 3,2 WITH 22 ROWS, 80 COLUMNS
	ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE 0,
		  BORDER, MESSAGE LINE LAST) 
OPEN FORM f_cons FROM '../forms/cxpf303_1'
DISPLAY FORM f_cons
DISPLAY BY NAME rm_par.moneda, rm_par.tit_mon, rm_par.tipo_detalle
LET vm_max_rows = 100
LET vm_max_doc  = 2000
CALL carga_colores()
CALL muestra_titulos()
CREATE TEMP TABLE tempo_doc 
	(localidad	SMALLINT,
	 moneda		CHAR(2),
	 cartera	SMALLINT,
	 tipo_prov	SMALLINT,
	 cladoc		CHAR(2),
	 numdoc		CHAR(13),
	 dividendo	SMALLINT,
	 codprov	INTEGER,
	 fecha		DATE,
	 valor 		DECIMAL(12,2))
CREATE TEMP TABLE tempo_acum
	(codigo		SMALLINT,
	 descripcion	VARCHAR(20),
	 val_col1	DECIMAL(12,0),
 	 val_col2	DECIMAL(12,0),
	 val_col3	DECIMAL(12,0),
	 val_col4	DECIMAL(12,0),
	 val_col5	DECIMAL(12,0),
	 val_col6	DECIMAL(12,0),
	 val_col7	DECIMAL(12,0))
CALL genera_tabla_trabajo_detalle()
CALL control_consulta()
IF int_flag THEN
	EXIT PROGRAM
END IF
MENU "OPCIONES"
	COMMAND KEY("C") "Consultar"
		CALL control_consulta()
		IF int_flag THEN
			EXIT PROGRAM
		END IF
		IF vm_num_res = 0 THEN
			HIDE OPTION 'Detalle'
			HIDE OPTION 'Precisión'
			HIDE OPTION 'Rangos'
			HIDE OPTION 'Gráfico'
		ELSE
			SHOW OPTION 'Detalle'
			SHOW OPTION 'Precisión'
			SHOW OPTION 'Rangos'
			SHOW OPTION 'Gráfico'
		END IF
	COMMAND KEY("R") "Rangos"
		CALL lee_rangos_vencimientos()
		IF NOT int_flag THEN
			CALL muestra_titulos()
			CALL genera_tabla_trabajo_resumen()
			CALL carga_arreglo_trabajo()
		END IF
	COMMAND KEY("D") "Detalle"
		CALL muestra_detalle()
	COMMAND KEY("P") "Precisión"
		IF vm_divisor = 1 THEN
			LET vm_divisor = 10
		ELSE
			IF vm_divisor = 10 THEN
				LET vm_divisor = 100
			ELSE
				IF vm_divisor = 100 THEN
					LET vm_divisor = 1000
				ELSE
					IF vm_divisor = 1000 THEN
						LET vm_divisor = 1
					END IF
				END IF
			END IF
		END IF
		CALL muestra_titulos()
		CALL carga_arreglo_trabajo()
	COMMAND KEY('G') 'Gráfico'
		CALL muestra_grafico_barras()
	COMMAND KEY('S') 'Salir'
		EXIT MENU
END MENU

END FUNCTION



FUNCTION control_consulta()
DEFINE i		SMALLINT

FOR i = 1 TO 10
	LET rm_orden[i] = '' 
END FOR
LET rm_orden[4] = 'ASC'
LET vm_columna_1 = 8
LET vm_columna_2 = 1
LET rm_orden[8] = 'DESC'
CALL lee_parametros()
IF int_flag THEN
	RETURN
END IF
IF vm_num_doc > 0 THEN
	CALL genera_tabla_trabajo_resumen()
	CALL carga_arreglo_trabajo()
END IF

END FUNCTION



FUNCTION lee_parametros()
DEFINE resp		CHAR(3)
DEFINE loc_aux		LIKE gent002.g02_localidad
DEFINE mon_aux		LIKE gent013.g13_moneda
DEFINE num_dec		SMALLINT
DEFINE r_loc		RECORD LIKE gent002.*

LET int_flag = 0
DISPLAY BY NAME rm_par.tit_mon
INPUT BY NAME rm_par.moneda, rm_par.localidad, rm_par.tipo_detalle
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		IF NOT FIELD_TOUCHED(rm_par.localidad, rm_par.moneda,
				     rm_par.tipo_detalle) THEN
			RETURN
		END IF
		LET int_flag = 0
		CALL FGL_WINQUESTION(vg_producto, 
                                     'Desea salir de la consulta',
                                     'No', 'Yes|No|Cancel',
                                     'question', 1) RETURNING resp
		IF resp = 'Yes' THEN
			LET INT_FLAG = 1
			EXIT PROGRAM
		END IF
	ON KEY(F2)
		IF INFIELD(localidad) THEN
			CALL fl_ayuda_localidad(vg_codcia)
				RETURNING loc_aux, rm_par.tit_local
			IF loc_aux IS NOT NULL THEN
				LET rm_par.localidad = loc_aux
				DISPLAY BY NAME rm_par.localidad, rm_par.tit_local
			END IF
		END IF
		IF INFIELD(moneda) THEN
			CALL fl_ayuda_monedas() RETURNING mon_aux,rm_par.tit_mon,
							  num_dec
			IF mon_aux IS NOT NULL THEN
				LET rm_par.moneda = mon_aux
				DISPLAY BY NAME rm_par.moneda, rm_par.tit_mon
			END IF
		END IF
	AFTER FIELD localidad
		IF rm_par.localidad IS NOT NULL THEN
			CALL fl_lee_localidad(vg_codcia, rm_par.localidad) 
				RETURNING r_loc.*
			IF r_loc.g02_localidad IS NULL THEN
				CALL fgl_winmessage(vg_producto, 'Localidad no existe', 'exclamation')
				NEXT FIELD localidad
			END IF
			LET rm_par.tit_local = r_loc.g02_nombre
			DISPLAY BY NAME rm_par.tit_local
		ELSE
			LET rm_par.tit_local = NULL
			CLEAR tit_local
		END IF
	AFTER FIELD moneda
		IF rm_par.moneda IS NOT NULL THEN
			CALL fl_lee_moneda(rm_par.moneda) RETURNING rm_mon.*
			IF rm_mon.g13_moneda IS NULL THEN
				CALL fgl_winmessage(vg_producto, 'Moneda no existe', 'exclamation')
				NEXT FIELD moneda
			END IF
			LET rm_par.tit_mon = rm_mon.g13_nombre
			DISPLAY BY NAME rm_par.tit_mon
		ELSE
			LET rm_par.tit_mon = NULL
			CLEAR tit_mon
		END IF
END INPUT

END FUNCTION



FUNCTION lee_rangos_vencimientos()

OPEN WINDOW w_ran AT 6,25 WITH FORM "../forms/cxpf303_2" 
	ATTRIBUTE(BORDER, COMMENT LINE LAST, FORM LINE FIRST)
LET int_flag = 0
INPUT BY NAME rm_par.ind_venc, rm_par.rango1_i THRU rm_par.rango4_i
	WITHOUT DEFAULTS
CLOSE WINDOW w_ran

END FUNCTION



FUNCTION genera_tabla_trabajo_detalle()
DEFINE valor		DECIMAL(12,2)
DEFINE dias		SMALLINT
DEFINE tipo_prov	LIKE gent012.g12_subtipo
DEFINE r_doc		RECORD LIKE cxpt020.*

ERROR "Procesando documentos con saldos . . . espere por favor." ATTRIBUTE(NORMAL)
DECLARE q_doc CURSOR FOR 
	SELECT * FROM cxpt020 
		WHERE p20_compania = vg_codcia AND 
		      p20_saldo_cap + p20_saldo_int > 0
LET vm_num_doc = 0
FOREACH q_doc INTO r_doc.*
	LET valor  = r_doc.p20_saldo_cap + r_doc.p20_saldo_int
	LET tipo_prov = "*"
	SELECT p01_tipo_prov INTO tipo_prov FROM cxpt001
		WHERE p01_codprov = r_doc.p20_codprov
	INSERT INTO tempo_doc VALUES(r_doc.p20_localidad, r_doc.p20_moneda,
		r_doc.p20_cartera, tipo_prov, r_doc.p20_tipo_doc,
		r_doc.p20_num_doc, r_doc.p20_dividendo, r_doc.p20_codprov,
		r_doc.p20_fecha_vcto, valor)
	LET vm_num_doc = vm_num_doc + 1
	IF vm_num_doc > vm_max_doc THEN
		EXIT FOREACH
	END IF
END FOREACH
ERROR ' '
IF vm_num_doc = 0 THEN
	CALL fl_mensaje_consulta_sin_registros()
	EXIT PROGRAM
END IF

END FUNCTION



FUNCTION muestra_titulos()
DEFINE label		CHAR(7)

IF vm_divisor = 1 THEN
	DISPLAY "Valores expresados en unidades" TO tit_precision
END IF 
IF vm_divisor = 10 THEN
	DISPLAY "Valores expresados en decenas" TO tit_precision
END IF 
IF vm_divisor = 100 THEN
	DISPLAY "Valores expresados en centenas" TO tit_precision
END IF 
IF vm_divisor = 1000 THEN
	DISPLAY "Valores expresados en miles" TO tit_precision
END IF 
DISPLAY 'Descripción' TO tit_col1
IF rm_par.ind_venc = "V" THEN
	DISPLAY "-- Rango de días vencidos --" TO tit_edad
	DISPLAY 'P.Vencer' TO tit_col2
	DISPLAY 'Vencido'  TO tit_col3
ELSE
	DISPLAY "-- Rango de días por vencer --" TO tit_edad
	DISPLAY 'Vencido'  TO tit_col2
	DISPLAY 'P.Vencer' TO tit_col3
END IF
LET label = rm_par.rango1_i USING "##&", "-",  rm_par.rango1_f USING "##&"
DISPLAY label TO tit_col4
LET label = rm_par.rango2_i USING "##&", "-",  rm_par.rango2_f USING "##&"
DISPLAY label TO tit_col5
LET label = rm_par.rango3_i USING "##&", "-",  rm_par.rango3_f USING "##&"
DISPLAY label TO tit_col6
LET label = ' >= ', rm_par.rango4_i USING "##&"
DISPLAY label TO tit_col7
DISPLAY 'Total' TO tit_col8

END FUNCTION



FUNCTION genera_tabla_trabajo_resumen()
DEFINE query		CHAR(300)
DEFINE campo		CHAR(20)
DEFINE i		SMALLINT
DEFINE tipo		SMALLINT
DEFINE dias		SMALLINT
DEFINE codloc		SMALLINT
DEFINE descri		CHAR(20)
DEFINE fecha		DATE
DEFINE valor		DECIMAL(12,2)
DEFINE val1, val2	DECIMAL(12,2)
DEFINE val3, val4	DECIMAL(12,2)
DEFINE val5, val6, val7	DECIMAL(12,2)
DEFINE tit_mon		CHAR(20)
DEFINE tit_cons		CHAR(40)
DEFINE r_se		RECORD LIKE gent012.*

ERROR "Generando resumen . . . espere por favor." ATTRIBUTE(NORMAL)
DELETE FROM tempo_acum
CASE rm_par.tipo_detalle 
	WHEN "R"
		LET campo = " cartera "
	WHEN "C"
		LET campo = " tipo_prov "
END CASE
LET query = "SELECT ", campo, ", fecha, valor, localidad FROM tempo_doc ",
		"WHERE moneda = '", rm_par.moneda, "'"
PREPARE cons FROM query
DECLARE q_cons CURSOR FOR cons
LET i = 0
FOREACH q_cons INTO tipo, fecha, valor, codloc
	IF rm_par.localidad IS NOT NULL AND codloc <> rm_par.localidad THEN
		CONTINUE FOREACH
	END IF
	LET descri = "NO EXISTE"
	CASE rm_par.tipo_detalle 
		WHEN 'C'
			CALL fl_lee_subtipo_entidad('CL', tipo)
				RETURNING r_se.*
			LET descri = r_se.g12_nombre
		WHEN 'R'
			CALL fl_lee_subtipo_entidad('CR', tipo)
				RETURNING r_se.*
			LET descri = r_se.g12_nombre
	END CASE
	LET val1  = 0
	LET val2  = 0
	LET val3  = 0
	LET val4  = 0
	LET val5  = 0
	LET val6  = 0
	LET val7  = 0
	IF rm_par.ind_venc = "V" THEN
		IF fecha >= TODAY THEN
			LET val1 = valor
		END IF
		LET dias = TODAY - fecha
	END IF
	IF rm_par.ind_venc = "P" THEN
		IF fecha < TODAY THEN
			LET val1 = valor
		END IF
		LET dias = fecha - TODAY
	END IF
	IF val1 = 0 THEN
		IF dias >= rm_par.rango1_i AND 
			dias <= rm_par.rango1_f THEN
			LET val3 = valor
		ELSE
			IF dias >= rm_par.rango2_i AND 
				dias <= rm_par.rango2_f THEN
				LET val4 = valor
			ELSE
				IF dias >= rm_par.rango3_i AND 
					dias <= rm_par.rango3_f THEN
					LET val5 = valor
				ELSE	
					IF dias >= rm_par.rango4_i THEN
						LET val6 = valor
					ELSE
						CONTINUE FOREACH
					END IF
				END IF
			END IF
		END IF
	END IF
	LET val2 = val3 + val4 + val5 + val6
	LET val7 = val1 + val2
	SELECT * FROM tempo_acum WHERE codigo = tipo
	IF status = NOTFOUND THEN
		INSERT INTO tempo_acum VALUES (tipo, descri, val1, val2, val3, 
					       val4, val5, val6, val7)
	ELSE
		UPDATE tempo_acum SET val_col1  = val_col1  + val1,
				      val_col2  = val_col2  + val2,
				      val_col3  = val_col3  + val3,
				      val_col4  = val_col4  + val4,
				      val_col5  = val_col5  + val5,
				      val_col6  = val_col6  + val6,
				      val_col7  = val_col7  + val7
			WHERE codigo = tipo
	END IF
	LET i = i + 1
END FOREACH
LET vm_num_res = i
ERROR " "
IF vm_num_res = 0 THEN
	LET int_flag = 1
	CALL fgl_winmessage(vg_producto, "No se encontraron documentos con el criterio indicado", 'exclamation')
END IF

END FUNCTION



FUNCTION carga_arreglo_trabajo()
DEFINE query		CHAR(300)
DEFINE tipo		SMALLINT
DEFINE i		SMALLINT

SELECT * FROM tempo_acum INTO TEMP tempo_acum1
UPDATE tempo_acum1 SET val_col1 = val_col1 / vm_divisor,
 	               val_col2 = val_col2 / vm_divisor,
	               val_col3 = val_col3 / vm_divisor,
	               val_col4 = val_col4 / vm_divisor,
	               val_col5 = val_col5 / vm_divisor,
	               val_col6 = val_col6 / vm_divisor,
	               val_col7 = val_col7 / vm_divisor
UPDATE tempo_acum1 SET val_col2 = val_col3 + val_col4 + val_col5 + val_col6
UPDATE tempo_acum1 SET val_col7 = val_col1 + val_col2
LET query = 'SELECT descripcion, val_col1, val_col2, val_col3, val_col4, ',
		' val_col5, val_col6, val_col7, codigo FROM tempo_acum1 ',
		' ORDER BY ',
		vm_columna_1, ' ', rm_orden[vm_columna_1], ',', 
		vm_columna_2, ' ', rm_orden[vm_columna_2] 
PREPARE fin FROM query
DECLARE q_fin CURSOR FOR fin
LET tot_col1  = 0
LET tot_col2  = 0
LET tot_col3  = 0
LET tot_col4  = 0
LET tot_col5  = 0
LET tot_col6  = 0
LET tot_col7  = 0
LET i = 1
FOREACH q_fin INTO rm_det[i].*, rm_aux[i]
	LET tot_col1 = tot_col1 + rm_det[i].val_col1 
	LET tot_col2 = tot_col2 + rm_det[i].val_col2 
	LET tot_col3 = tot_col3 + rm_det[i].val_col3 
	LET tot_col4 = tot_col4 + rm_det[i].val_col4 
	LET tot_col5 = tot_col5 + rm_det[i].val_col5 
	LET tot_col6 = tot_col6 + rm_det[i].val_col6 
	LET tot_col7 = tot_col7 + rm_det[i].val_col7 
	LET i = i + 1
END FOREACH
LET vm_num_rows = i - 1
DISPLAY BY NAME tot_col1, tot_col2, tot_col3, tot_col4, tot_col5, tot_col6,
		tot_col7
FOR i = 1 TO fgl_scr_size ('rm_det')
	CLEAR rm_det[i].*
	IF i <= vm_num_rows THEN
		DISPLAY rm_det[i].* TO rm_det[i].*
	END IF
END FOR
DROP TABLE tempo_acum1
			      
END FUNCTION



FUNCTION muestra_detalle()
DEFINE i		SMALLINT
DEFINE comando		VARCHAR(100)
DEFINE loc		LIKE gent002.g02_localidad
DEFINE flag		CHAR(1)

CALL set_count(vm_num_rows)
WHILE TRUE
	LET int_flag = 0
	DISPLAY ARRAY rm_det TO rm_det.*
		BEFORE DISPLAY
			--#CALL dialog.keysetlabel("ACCEPT","")
			--#CALL dialog.keysetlabel("F6","Gráfico")
		AFTER DISPLAY
			CONTINUE DISPLAY
		ON KEY(INTERRUPT)
			EXIT DISPLAY
		ON KEY(F5)
			LET i = arr_curr()
			LET flag = 'N'
			LET loc = vg_codloc
			IF rm_par.localidad IS NOT NULL THEN
				LET loc = rm_par.localidad
				LET flag = 'S'
			END IF
			LET comando = 'fglrun cxpp302 ', vg_base, ' ', 
			vg_modulo, ' ', vg_codcia, ' ', loc, ' ',
			rm_par.moneda, ' ', 
			rm_aux[i], ' ', rm_par.tipo_detalle, ' ', 
			'T ', flag
			RUN comando
		ON KEY(F6)
			CALL muestra_grafico_barras()
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
		ON KEY(F21)
			LET i = 7
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F22)
			LET i = 8
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
	CALL carga_arreglo_trabajo()
END WHILE
                                                                                
END FUNCTION



FUNCTION muestra_grafico_barras()
DEFINE inicio_x		SMALLINT
DEFINE inicio_y		SMALLINT
DEFINE maximo_x		SMALLINT
DEFINE maximo_y		SMALLINT
DEFINE factor_y		DECIMAL(16,6)
DEFINE max_barras	SMALLINT
DEFINE ancho_barra	SMALLINT
DEFINE num_barras	SMALLINT

DEFINE inicio2_x	SMALLINT
DEFINE inicio2_y	SMALLINT

DEFINE max_elementos	SMALLINT
DEFINE max_valor	DECIMAL(14,2)
DEFINE filas_procesadas	SMALLINT

DEFINE codigo		SMALLINT
DEFINE descri		VARCHAR(35)
DEFINE valor		DECIMAL(14,2)
DEFINE key_n		SMALLINT
DEFINE key_c		CHAR(3)
DEFINE key_f30		SMALLINT
DEFINE cant_val		CHAR(1)
DEFINE query		VARCHAR(200)
DEFINE i, indice	SMALLINT
DEFINE tecla		CHAR(1)
DEFINE titulo, tit_pos	CHAR(75)
DEFINE label          	CHAR(10)
DEFINE tit_val		CHAR(16)
DEFINE campos		CHAR(45)
DEFINE campo		CHAR(13)
DEFINE ind_venc		CHAR(1)
DEFINE flag		CHAR(1)
DEFINE loc		SMALLINT
DEFINE comando		VARCHAR(100)
DEFINE r_obj ARRAY[8] OF RECORD
	codigo		SMALLINT,
	descripcion	CHAR(20),
	valor		DECIMAL(12,0),
	id_obj_rec1	SMALLINT,
	id_obj_rec2	SMALLINT
	END RECORD

CALL carga_colores()
LET max_barras = 8
LET inicio_x   = 50
LET inicio_y   = 80
LET maximo_x   = 500
LET maximo_y   = 750
LET inicio2_x  = 910

IF rm_par.ind_venc = 'V' THEN
	LET campos = 'val_col1 te_por_vencer, val_col2 te_vencido'
ELSE
	LET campos = 'val_col2 te_por_vencer, val_col1 te_vencido'
END IF
LET query = 'SELECT codigo te_codigo, descripcion te_descripcion, ' ||
		campos || ', val_col7 te_total ' ||
		' FROM tempo_acum ' ||
		' INTO TEMP temp_barra'
PREPARE in_bar FROM query
EXECUTE in_bar
LET ind_venc = rm_par.ind_venc
WHILE TRUE
	CASE ind_venc
		WHEN 'V'
			LET label = 'VENCIDA'
			LET campo = 'te_vencido'
		WHEN 'P'
			LET label = 'POR VENCER'
			LET campo = 'te_por_vencer'
		OTHERWISE
			LET label = 'TOTAL'
			LET campo = 'te_total'
	END CASE
	LET titulo = 'CARTERA ' || label CLIPPED || ' POR '
	CASE rm_par.tipo_detalle
		WHEN 'C'
			LET titulo = titulo CLIPPED || ' TIPO DE PROVEEDOR'
		WHEN 'R'
			LET titulo = titulo CLIPPED || ' TIPO DE CARTERA'
	END CASE
	LET query = 'SELECT COUNT(*), MAX(' || campo || ')' ||
			' FROM temp_barra '
	PREPARE maxi FROM query
	DECLARE q_maxi CURSOR FOR maxi
	OPEN q_maxi
	FETCH q_maxi INTO max_elementos, max_valor	
	CLOSE q_maxi
	FREE q_maxi
	IF max_elementos IS NULL THEN
		DROP TABLE temp_barra
		RETURN
	END IF
	LET query = 'SELECT te_codigo, te_descripcion, ' || campo ||
			' FROM temp_barra ' || ' ORDER BY 3 DESC'
	PREPARE bar FROM query
	DECLARE q_bar SCROLL CURSOR FOR bar
	CALL drawinit()
	OPEN WINDOW w_gr1 AT 3,2 WITH FORM "../forms/cxpf303_3"
		ATTRIBUTE(BORDER, FORM LINE FIRST, COMMENT LINE LAST)
	CALL drawselect('c001')
	CALL drawanchor('w')
	CALL DrawFillColor("blue")
	LET i = drawline(inicio_y, inicio_x, 0, maximo_x)
	LET i = drawline(inicio_y, inicio_x, maximo_y, 0)
--
	LET factor_y         = maximo_y / max_valor 
	LET filas_procesadas = 0
	OPEN q_bar
	WHILE TRUE
		LET i = drawtext(960,10,titulo CLIPPED)
		LET num_barras = max_elementos - filas_procesadas
		IF num_barras >= max_barras THEN
			LET num_barras = max_barras
		END IF
		LET ancho_barra = maximo_x / num_barras 
		LET indice = 0
		LET inicio2_y  = maximo_y + 70 
		WHILE indice < num_barras 
			FETCH q_bar INTO codigo, descri, valor
			IF status = NOTFOUND THEN
				EXIT WHILE
			END IF
			LET r_obj[indice + 1].codigo      = codigo
			LET r_obj[indice + 1].descripcion = descri
			LET r_obj[indice + 1].valor       = valor
        		CALL DrawFillColor(rm_color[indice+1])
			LET r_obj[indice + 1].id_obj_rec1 =
				drawrectangle(inicio_y, inicio_x + (ancho_barra * 
				      	indice), factor_y * valor, ancho_barra)
			LET r_obj[indice + 1].id_obj_rec2 =
				drawrectangle(inicio2_y, inicio2_x, 25, 75)
			LET descri = fl_justifica_titulo('D', descri[1,35], 35)
			LET i = drawtext(inicio2_y + 53, inicio2_x - 385, descri)
			LET tit_val = valor USING "#,###,###,##&.##"
			LET i = drawtext(inicio2_y + 15, inicio2_x - 215, tit_val)
			LET indice = indice + 1
			LET filas_procesadas = filas_procesadas + 1
			LET inicio2_y = inicio2_y - 110
		END WHILE
		LET tit_pos = filas_procesadas, ' de ', max_elementos
		LET i = drawtext(900,05, tit_pos)
		LET i = drawtext(30,10,'Haga click sobre un item para ver detalles')
		FOR i = 1 TO indice
			LET key_n = i + 30
			LET key_c = 'F', key_n
			CALL drawbuttonleft(r_obj[i].id_obj_rec1, key_c)
			CALL drawbuttonleft(r_obj[i].id_obj_rec2, key_c)
		END FOR
		LET key_f30 = FGL_KEYVAL("F30")
		LET int_flag = 0
		IF filas_procesadas >= max_elementos THEN
			--#CALL fgl_keysetlabel("F3","")
		ELSE
			--#CALL fgl_keysetlabel("F3","Avanzar")
		END IF
		IF filas_procesadas <= max_barras THEN
			--#CALL fgl_keysetlabel("F4","")
		ELSE
			--#CALL fgl_keysetlabel("F4","Retroceder")
		END IF
		INPUT BY NAME tecla
			BEFORE INPUT
				IF filas_procesadas <= max_barras THEN
					--#CALL dialog.keysetlabel("F5","Vencimientos")
				ELSE
					--#CALL dialog.keysetlabel("F5","")
				END IF
				--#CALL dialog.keysetlabel("ACCEPT","")
				--#CALL dialog.keysetlabel("F31","")
				--#CALL dialog.keysetlabel("F32","")
				--#CALL dialog.keysetlabel("F33","")
				--#CALL dialog.keysetlabel("F34","")
				--#CALL dialog.keysetlabel("F35","")
				--#CALL dialog.keysetlabel("F36","")
				--#CALL dialog.keysetlabel("F37","")
				--#CALL dialog.keysetlabel("F38","")
			ON KEY(F5)
				IF filas_procesadas <= max_barras THEN
					IF ind_venc = 'P' THEN
						LET ind_venc = 'V'
					ELSE
						IF ind_venc = 'V' THEN
							LET ind_venc = 'T'
						ELSE
							LET ind_venc = 'P'
						END IF
					END IF
					LET int_flag = 2
					EXIT INPUT
				END IF
			ON KEY(F3)
				IF filas_procesadas < max_elementos THEN
					CALL drawclear()
					EXIT INPUT
				END IF
			ON KEY(F4)
				IF filas_procesadas > max_barras THEN
					LET filas_procesadas = filas_procesadas
						- (indice + max_barras)
					IF filas_procesadas = 0 THEN
						CLOSE q_bar
						OPEN q_bar
					ELSE
						FOR i = 1 TO indice + max_barras 
							FETCH PREVIOUS q_bar 
						END FOR
					END IF
					CALL drawclear()
					EXIT INPUT
				END IF
			ON KEY(F31,F32,F33,F34,F35,F36,F37,F38)
				LET i = FGL_LASTKEY() - key_f30
				LET flag = 'N'
				LET loc = vg_codloc
				IF rm_par.localidad IS NOT NULL THEN
					LET loc = rm_par.localidad
					LET flag = 'S'
				END IF
				LET comando = 'fglrun cxpp302 ', vg_base, ' ', 
				vg_modulo, ' ', vg_codcia, ' ', loc, ' ',
				rm_par.moneda, ' ', 
				r_obj[i].codigo, ' ', rm_par.tipo_detalle, ' ', 
				ind_venc, ' ', flag
				RUN comando
			AFTER FIELD tecla
				NEXT FIELD tecla	
		END INPUT
		IF int_flag THEN
			CLOSE q_bar
			EXIT WHILE
		END IF
	END WHILE
	IF int_flag = 1 THEN
		EXIT WHILE
	END IF
END WHILE
FREE q_bar
CLOSE WINDOW w_gr1
DROP TABLE temp_barra
	
END FUNCTION



FUNCTION carga_colores()

LET rm_color[01] = 'cyan'
LET rm_color[02] = 'yellow'
LET rm_color[03] = 'green'
LET rm_color[04] = 'red'
LET rm_color[05] = 'snow'
LET rm_color[06] = 'magenta'
LET rm_color[07] = 'pink'
LET rm_color[08] = 'chocolate'
LET rm_color[09] = 'tomato'
LET rm_color[10] = 'blue'

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
