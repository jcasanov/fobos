--------------------------------------------------------------------------------
-- Titulo           : cxcp307.4gl - Consulta Análisis Detalle Cartera
-- Elaboracion      : 11-Oct-2001
-- Autor            : YEC
-- Formato Ejecucion: fglrun cxcp307.4gl base_datos modulo compañía localidad
-- Ultima Correccion: 
-- Motivo Correccion:
--------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE rm_orden		ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1	SMALLINT
DEFINE vm_columna_2	SMALLINT
DEFINE rm_mon		RECORD LIKE gent013.*
DEFINE vm_divisor	SMALLINT
DEFINE num_doc		SMALLINT
DEFINE num_cli		SMALLINT
DEFINE num_max_doc	SMALLINT
DEFINE num_max_cli	SMALLINT
DEFINE rm_par 		RECORD
				moneda          LIKE gent013.g13_moneda,
				tit_mon         LIKE gent013.g13_nombre,
				area_n          LIKE gent003.g03_areaneg,
				tit_area        LIKE gent003.g03_nombre,
				tipcli		LIKE gent012.g12_subtipo,
				tit_tipcli	LIKE gent012.g12_nombre,
				tipcar		LIKE gent012.g12_subtipo,
				tit_tipcar	LIKE gent012.g12_nombre,
				localidad	LIKE gent002.g02_localidad,
				ind_venc        CHAR(1),
				dias_i          SMALLINT,
				dias_f          SMALLINT,
				codcli		LIKE cxct001.z01_codcli
			END RECORD
DEFINE rm_doc		ARRAY[10000] OF RECORD
				tit_arean       CHAR(10),
				cladoc		LIKE cxct020.z20_tipo_doc,
				numdoc		CHAR(16),
				nomcli		LIKE cxct001.z01_nomcli,
				fecha		DATE,
				valor		DECIMAL(12,2)
			END RECORD
DEFINE tot_doc		DECIMAL(14,2)



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/cxcp307.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 AND num_args() <> 9 AND num_args() <> 10 THEN
	-- Validar # parámetros correcto
	CALL fgl_winmessage(vg_producto, 'Número de parámetros incorrecto', 'stop')
	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_codloc  = arg_val(4)
LET vg_proceso = 'cxcp307'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
--#CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()

END MAIN



FUNCTION funcion_master()
DEFINE r_g02		RECORD LIKE gent002.*
DEFINE r_an		RECORD LIKE gent003.*
DEFINE r_se		RECORD LIKE gent012.*
DEFINE i, cod_aux	SMALLINT
DEFINE flag_aux		CHAR(1)

LET num_max_doc = 10000
LET num_max_cli = 10000
OPEN WINDOW w_imp AT 3,2 WITH 22 ROWS, 80 COLUMNS
	ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE FIRST,
		  BORDER, MESSAGE LINE LAST) 
OPEN FORM f_par FROM "../forms/cxcf307_1"
DISPLAY FORM f_par
INITIALIZE rm_par.* TO NULL
LET rm_par.moneda   = rg_gen.g00_moneda_base
LET rm_par.ind_venc = 'T'
IF num_args() >= 9 THEN
	IF arg_val(9) = 'S' THEN
		LET rm_par.localidad = arg_val(4)
		CALL fl_lee_localidad(vg_codcia, rm_par.localidad)
			RETURNING r_g02.*
		DISPLAY r_g02.g02_nombre TO tit_localidad
	END IF
	LET rm_par.moneda = arg_val(5)
	LET cod_aux       = arg_val(6)
	LET flag_aux      = arg_val(7)
	CASE flag_aux
		WHEN 'A'
			LET rm_par.area_n = cod_aux
			CALL fl_lee_area_negocio(vg_codcia, rm_par.area_n)
				RETURNING r_an.*
			LET rm_par.tit_area = r_an.g03_nombre 
			DISPLAY r_an.g03_nombre TO tit_area
		WHEN 'C'
			LET rm_par.tipcli = cod_aux
			CALL fl_lee_subtipo_entidad('CL', rm_par.tipcli)
				RETURNING r_se.*
			LET rm_par.tit_tipcli = r_se.g12_nombre 
			DISPLAY BY NAME rm_par.tit_tipcli
		WHEN 'R'
			LET rm_par.tipcar = cod_aux
			CALL fl_lee_subtipo_entidad('CR', rm_par.tipcar)
				RETURNING r_se.*
			LET rm_par.tit_tipcar = r_se.g12_nombre 
			DISPLAY BY NAME rm_par.tit_tipcar
	END CASE
	LET rm_par.ind_venc  = arg_val(8)
	DISPLAY BY NAME rm_par.*
	IF num_args() = 10 THEN
		IF arg_val(10) = 'S' THEN
			LET rm_par.codcli = arg_val(6)
			LET rm_par.tipcli     = NULL
			LET rm_par.tit_tipcli = NULL
			DISPLAY BY NAME rm_par.codcli, rm_par.tipcli,
					rm_par.tit_tipcli
		END IF
	END IF
END IF
CALL fl_lee_moneda(rm_par.moneda) RETURNING rm_mon.*
LET rm_par.tit_mon = rm_mon.g13_nombre
DISPLAY BY NAME rm_par.tit_mon
DISPLAY 'Area Neg.'     TO tit_col1
DISPLAY 'Tp'            TO tit_col2
DISPLAY 'Documento'     TO tit_col3
DISPLAY 'C l i e n t e' TO tit_col4
DISPLAY 'Fec.Vcto.'     TO tit_col5
DISPLAY 'S a l d o'     TO tit_col6
WHILE TRUE
	FOR i = 1 TO 10
		LET rm_orden[i] = '' 
	END FOR
	LET rm_orden[6] = 'DESC'
	LET vm_columna_1 = 6
	LET vm_columna_2 = 1
	IF num_args() = 4 THEN
		CALL lee_parametros() 
		IF int_flag THEN
			RETURN
		END IF
	END IF
	CREATE TEMP TABLE tempo_doc 
		(area_n		SMALLINT,
		 cladoc		CHAR(2),
		 numdoc		CHAR(15),
		 secuencia	SMALLINT,
		 codcli		INTEGER,
		 nomcli		CHAR(40),
		 fecha		DATE,
		 por_vencer	DECIMAL(12,2),
		 vencido	DECIMAL(12,2),
		 cod_tran	CHAR(2),
		 num_tran	INTEGER,
		 localidad	SMALLINT)
	CALL genera_tabla_temporal()
	IF num_doc > 0 THEN
		CALL muestra_detalle_documentos()
	END IF
	DROP TABLE tempo_doc
	IF num_args() >= 9 THEN
		EXIT WHILE
	END IF
END WHILE

END FUNCTION



FUNCTION lee_parametros()
DEFINE mon_aux		LIKE gent013.g13_moneda
DEFINE tit_mon		LIKE gent013.g13_nombre
DEFINE area_aux		LIKE gent003.g03_areaneg
DEFINE tit_area		LIKE gent003.g03_nombre
DEFINE r_an		RECORD LIKE gent003.*
DEFINE r_mo		RECORD LIKE gent013.*
DEFINE r_se		RECORD LIKE gent012.*
DEFINE r_g02		RECORD LIKE gent002.*
DEFINE r_z01		RECORD LIKE cxct001.*
DEFINE r_z02		RECORD LIKE cxct002.*
DEFINE num		SMALLINT
DEFINE tiporeg		LIKE gent012.g12_tiporeg
DEFINE subtipo		LIKE gent012.g12_subtipo
DEFINE nomtipo		LIKE gent012.g12_nombre
DEFINE nombre		LIKE gent011.g11_nombre

LET int_flag = 0
INPUT BY NAME rm_par.* WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		CLOSE FORM f_par
		RETURN
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
		IF INFIELD(tipcli) THEN
			CALL fl_ayuda_subtipo_entidad('CL') 
				RETURNING tiporeg, subtipo, nomtipo, nombre
			IF nomtipo IS NOT NULL THEN
				LET rm_par.tipcli     = subtipo
				LET rm_par.tit_tipcli = nomtipo
				DISPLAY BY NAME rm_par.tipcli, rm_par.tit_tipcli
			END IF
		END IF
		IF INFIELD(tipcar) THEN
			CALL fl_ayuda_subtipo_entidad('CR') 
				RETURNING tiporeg, subtipo, nomtipo, nombre
			IF nomtipo IS NOT NULL THEN
				LET rm_par.tipcar     = subtipo
				LET rm_par.tit_tipcar = nomtipo
				DISPLAY BY NAME rm_par.tipcar, rm_par.tit_tipcar
			END IF
		END IF
		IF INFIELD(localidad) THEN
			CALL fl_ayuda_localidad(vg_codcia)
				RETURNING r_g02.g02_localidad, r_g02.g02_nombre
			IF r_g02.g02_localidad IS NOT NULL THEN
				LET rm_par.localidad = r_g02.g02_localidad
				DISPLAY BY NAME rm_par.localidad
				DISPLAY r_g02.g02_nombre TO tit_localidad
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
				DISPLAY BY NAME rm_par.codcli
			END IF
		END IF
		LET int_flag = 0
	AFTER FIELD area_n
		IF rm_par.area_n IS NOT NULL THEN
			CALL fl_lee_area_negocio(vg_codcia, rm_par.area_n)
				RETURNING r_an.*
			IF r_an.g03_compania IS NULL THEN
				CALL fgl_winmessage(vg_producto, 'No existe área de negocio', 'exclamation')
				NEXT FIELD area_n
			END IF
			LET rm_par.tit_area = r_an.g03_nombre
			DISPLAY BY NAME rm_par.tit_area
		ELSE
			LET rm_par.tit_area = NULL
			DISPLAY BY NAME rm_par.tit_area
		END IF
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
	AFTER FIELD tipcli
		IF rm_par.tipcli IS NOT NULL THEN
			CALL fl_lee_subtipo_entidad('CL', rm_par.tipcli)
				RETURNING r_se.*
			IF r_se.g12_tiporeg IS NULL THEN
				CALL fgl_winmessage(vg_producto, 'No existe tipo cliente', 'exclamation')
				NEXT FIELD tipcli
			END IF
			LET rm_par.tit_tipcli = r_se.g12_nombre 
			DISPLAY BY NAME rm_par.tit_tipcli
		ELSE
			LET rm_par.tit_tipcli = NULL
			DISPLAY BY NAME rm_par.tit_tipcli
		END IF
	AFTER FIELD tipcar
		IF rm_par.tipcar IS NOT NULL THEN
			CALL fl_lee_subtipo_entidad('CR', rm_par.tipcar)
				RETURNING r_se.*
			IF r_se.g12_tiporeg IS NULL THEN
				CALL fgl_winmessage(vg_producto, 'No existe tipo cartera', 'exclamation')
				NEXT FIELD tipcar
			END IF
			LET rm_par.tit_tipcar = r_se.g12_nombre 
			DISPLAY BY NAME rm_par.tit_tipcar
		ELSE
			LET rm_par.tit_tipcar = NULL
			DISPLAY BY NAME rm_par.tit_tipcar
		END IF
	AFTER FIELD localidad
		IF rm_par.localidad IS NOT NULL THEN
			CALL fl_lee_localidad(vg_codcia, rm_par.localidad)
				RETURNING r_g02.*
			IF r_g02.g02_compania IS NULL THEN
				CALL fl_mostrar_mensaje('Localidad no existe.','exclamation')
				NEXT FIELD localidad
			END IF
			IF r_g02.g02_estado = 'B' THEN
				CALL fl_mensaje_estado_bloqueado()
				NEXT FIELD localidad
			END IF
			DISPLAY r_g02.g02_nombre TO tit_localidad
		ELSE
			CLEAR tit_localidad
		END IF
	AFTER FIELD codcli
		IF rm_par.codcli IS NOT NULL THEN
			CALL fl_lee_cliente_general(rm_par.codcli)
				RETURNING r_z01.*
			IF r_z01.z01_codcli IS NULL THEN
				CALL fl_mostrar_mensaje('Cliente no existe.', 'exclamation')
				NEXT FIELD codcli
			END IF
			IF rm_par.localidad IS NULL THEN
				CONTINUE INPUT
			END IF
			CALL fl_lee_cliente_localidad(vg_codcia,
							rm_par.localidad,
							r_z01.z01_codcli)
				RETURNING r_z02.*
			IF r_z02.z02_compania IS NULL THEN
				CALL fl_mostrar_mensaje('Cliente no está activado para la Localidad.', 'exclamation')
				NEXT FIELD codcli
			END IF
		END IF
	AFTER INPUT 
		IF (rm_par.dias_i IS NOT NULL AND rm_par.dias_f IS NULL) OR
		   (rm_par.dias_i IS NULL AND rm_par.dias_f IS NOT NULL) THEN
			CALL fgl_winmessage(vg_producto, 'Complete rango', 'exclamation')
			NEXT FIELD dias_i
		END IF
		IF rm_par.dias_i > rm_par.dias_f THEN
			CALL fgl_winmessage(vg_producto, 'Rango incorrecto', 'exclamation')
			NEXT FIELD dias_i
		END IF
		IF rm_par.codcli IS NOT NULL THEN
			LET rm_par.tipcli     = NULL
			LET rm_par.tit_tipcli = NULL
			DISPLAY BY NAME rm_par.tipcli, rm_par.tit_tipcli
		END IF
END INPUT

END FUNCTION



FUNCTION genera_tabla_temporal()
DEFINE pven, venc	DECIMAL(12,2)
DEFINE expr1, expr2	CHAR(60)
DEFINE query		CHAR(200)
DEFINE dias		SMALLINT
DEFINE nomcli		CHAR(40)
DEFINE r_doc		RECORD LIKE cxct020.*
DEFINE r_cli		RECORD LIKE cxct001.*
DEFINE expr_loc		VARCHAR(50)
DEFINE expr_cli		VARCHAR(50)

ERROR "Generando consulta . . . espere por favor." ATTRIBUTE(NORMAL)
LET expr1 = ' 1 = 1 '
LET expr2 = ' 1 = 1 '
IF rm_par.area_n IS NOT NULL THEN
	LET expr1 = ' z20_areaneg = ', rm_par.area_n
END IF
IF rm_par.moneda IS NOT NULL THEN
	LET expr2 = " z20_moneda = '", rm_par.moneda, "' "
END IF
LET expr_loc = ' '
IF rm_par.localidad IS NOT NULL THEN
	LET expr_loc = '   AND z20_localidad = ', rm_par.localidad
END IF
LET expr_cli = ' '
IF rm_par.codcli IS NOT NULL THEN
	LET expr_cli = '   AND z20_codcli    = ', rm_par.codcli
END IF
LET query = "SELECT * FROM cxct020 WHERE ", 
		expr1 CLIPPED, " AND ",
		expr2 CLIPPED, " AND ",
		"z20_compania = ", vg_codcia,
		expr_loc CLIPPED,
		expr_cli CLIPPED,
		" AND z20_saldo_cap + z20_saldo_int > 0"
PREPARE doc FROM query
DECLARE q_doc CURSOR FOR doc
LET num_doc = 0
FOREACH q_doc INTO r_doc.*
	{--
	IF arg_val(9) = 'S' THEN
		IF r_doc.z20_localidad <> vg_codloc THEN
			CONTINUE FOREACH
		END IF
	END IF
	--}
	IF r_doc.z20_fecha_vcto >= vg_fecha THEN
		LET pven = r_doc.z20_saldo_cap + r_doc.z20_saldo_int
		LET venc = 0
	ELSE
		LET venc = r_doc.z20_saldo_cap + r_doc.z20_saldo_int
		LET pven = 0
	END IF
	IF rm_par.ind_venc = 'V' THEN
		IF r_doc.z20_fecha_vcto >= vg_fecha THEN
			CONTINUE FOREACH
		END IF
		IF rm_par.dias_i IS NULL THEN
			LET rm_par.dias_i = 1
			LET rm_par.dias_f = 9999
		END IF
		LET dias = vg_fecha - r_doc.z20_fecha_vcto
		IF dias < rm_par.dias_i OR dias > rm_par.dias_f THEN
			CONTINUE FOREACH
		END IF
	END IF		
	IF rm_par.ind_venc = 'P' THEN
		IF r_doc.z20_fecha_vcto < vg_fecha THEN
			CONTINUE FOREACH
		END IF
		IF rm_par.dias_i IS NULL THEN
			LET rm_par.dias_i = 0
			LET rm_par.dias_f = 9999
		END IF
		LET dias = r_doc.z20_fecha_vcto - vg_fecha
		IF dias < rm_par.dias_i OR dias > rm_par.dias_f THEN
			CONTINUE FOREACH
		END IF
	END IF		
	IF rm_par.tipcar IS NOT NULL AND rm_par.tipcar <> r_doc.z20_cartera THEN
		CONTINUE FOREACH
	END IF
	CALL fl_lee_cliente_general(r_doc.z20_codcli)
		RETURNING r_cli.*
	IF rm_par.tipcli IS NOT NULL AND rm_par.tipcli <> r_cli.z01_tipo_clte
	THEN
		CONTINUE FOREACH
	END IF
	INSERT INTO tempo_doc VALUES(r_doc.z20_areaneg, r_doc.z20_tipo_doc,
		r_doc.z20_num_doc, r_doc.z20_dividendo, r_doc.z20_codcli, 
		r_cli.z01_nomcli, r_doc.z20_fecha_vcto, pven, venc,
		r_doc.z20_cod_tran, r_doc.z20_num_tran, r_doc.z20_localidad)
	LET num_doc = num_doc + 1
	IF num_doc > num_max_doc THEN
		EXIT FOREACH
	END IF
END FOREACH
ERROR ' '
IF num_doc = 0 THEN
	CALL fl_mensaje_consulta_sin_registros()
END IF

END FUNCTION



FUNCTION muestra_detalle_documentos()
DEFINE orden		CHAR(40)
DEFINE query		CHAR(300)
DEFINE i, dias		SMALLINT
DEFINE comando          CHAR(100)
DEFINE r_an		RECORD LIKE gent003.*
DEFINE tit_venc		CHAR(20)
DEFINE r_aux		ARRAY[10000] OF RECORD
				area_n		LIKE cxct020.z20_areaneg,
				codcli		LIKE cxct001.z01_codcli,
				numdoc		LIKE cxct020.z20_num_doc,
				dividendo	LIKE cxct020.z20_dividendo,
				cod_tran	LIKE cxct020.z20_cod_tran,
				num_tran	LIKE cxct020.z20_num_tran,
				localidad	LIKE cxct020.z20_localidad
			END RECORD
DEFINE codloc		LIKE gent002.g02_localidad

WHILE TRUE
	LET query = "SELECT area_n, cladoc, numdoc, ", 
			" nomcli, fecha, por_vencer + vencido, area_n,",
			" codcli, numdoc, secuencia, cod_tran, num_tran, ",
			" localidad ",
			" FROM tempo_doc ",
			" ORDER BY ", vm_columna_1, ' ', rm_orden[vm_columna_1],
			        ', ', vm_columna_2, ' ', rm_orden[vm_columna_2]
	PREPARE cond FROM query
	DECLARE q_cond CURSOR FOR cond
	LET i = 1
	LET tot_doc = 0
	FOREACH q_cond INTO rm_doc[i].*, r_aux[i].* 
		CALL fl_lee_area_negocio(vg_codcia, rm_doc[i].tit_arean)
			RETURNING r_an.*
		LET rm_doc[i].tit_arean = r_an.g03_abreviacion
		LET rm_doc[i].numdoc    = rm_doc[i].numdoc CLIPPED, '-',
					 r_aux[i].dividendo USING '&&'
		LET tot_doc = tot_doc + rm_doc[i].valor
		LET i = i + 1
	END FOREACH
	DISPLAY BY NAME tot_doc
	CALL muestrar_contadores_det(0, num_doc)
	CALL set_count(num_doc)
	LET int_flag = 0
	DISPLAY ARRAY rm_doc TO rm_doc.*
		ON KEY(INTERRUPT)
			EXIT DISPLAY
		ON KEY(F5)
			LET i = arr_curr()
			IF r_aux[i].cod_tran IS NULL THEN
				CONTINUE DISPLAY
			END IF	
			CALL fl_lee_area_negocio(vg_codcia, r_aux[i].area_n)
				RETURNING r_an.*
			IF r_an.g03_modulo = 'RE' THEN
				CALL fl_ver_transaccion_rep(vg_codcia,
							r_aux[i].localidad,
							r_aux[i].cod_tran,
							r_aux[i].num_tran)
				LET int_flag = 0
			END IF
			IF r_an.g03_modulo = 'TA' THEN
				LET comando = 'cd ..' || vg_separador || '..' ||
				      vg_separador || '..' ||
				      vg_separador || 'PRODUCCION' ||
				      vg_separador || 'TALLER' || 
				      vg_separador || 'fuentes; ' ||
				      'fglrun talp204 ' || vg_base || 
				      ' TA ' || 
			       	      vg_codcia || ' ' ||
			       	      r_aux[i].localidad || ' ' || 
				      r_aux[i].num_tran || ' F'
				RUN comando
			END IF
			IF r_an.g03_modulo = 'VE' THEN
				LET comando = 'cd ..' || vg_separador || '..' ||
				      vg_separador || 'VEHICULOS' || 
				      vg_separador || 'fuentes; ' ||
				      'fglrun vehp304 ' || vg_base || 
				      ' VE ' || 
			       	      vg_codcia || ' ' ||
			       	      r_aux[i].localidad || ' ' || 
				      r_aux[i].cod_tran || ' ' ||
			       	      r_aux[i].num_tran
				RUN comando
			END IF
		ON KEY(F6)
			LET i = arr_curr()
			LET codloc = 0
			IF rm_par.localidad IS NOT NULL THEN
				LET codloc = rm_par.localidad
			END IF
			LET comando = 'fglrun cxcp305 ' || vg_base || 
			      ' CO ' || 
			      vg_codcia || ' ' || 
			      codloc || ' ' ||
			      r_aux[i].codcli || ' ' ||
		       	      rm_par.moneda
			RUN comando
		ON KEY(F7)
			LET i = arr_curr()
			LET comando = 'fglrun cxcp200 ' || vg_base || ' ' ||
			      vg_modulo || ' ' || 
			      vg_codcia || ' ' || 
			      r_aux[i].localidad || ' ' ||
			      r_aux[i].codcli || ' ' ||
			      rm_doc[i].cladoc || ' ' ||
			      r_aux[i].numdoc || ' ' ||
			      r_aux[i].dividendo
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
		BEFORE DISPLAY 
			--#CALL dialog.keysetlabel("ACCEPT","")
		AFTER DISPLAY 
			CONTINUE DISPLAY
		BEFORE ROW
			LET i = arr_curr()
			IF rm_doc[i].fecha < vg_fecha THEN
				LET dias = vg_fecha - rm_doc[i].fecha
				LET tit_venc = 'Vencido ', dias USING "###&",
					       ' días'
			ELSE
				LET dias = rm_doc[i].fecha - vg_fecha
				LET tit_venc = 'Por Vencer ', dias USING "###&",
					       ' días'
			END IF
			DISPLAY BY NAME tit_venc
			CALL muestrar_contadores_det(i, num_doc)
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
CALL muestrar_contadores_det(0, num_doc)
	
END FUNCTION



FUNCTION muestrar_contadores_det(num_row, max_row)
DEFINE num_row, max_row	SMALLINT

DISPLAY BY NAME num_row, max_row

END FUNCTION
