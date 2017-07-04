--------------------------------------------------------------------------------
-- Titulo           : srip205.4gl - Generación Documentos Electrónicos XML
-- Elaboracion      : 23-ene-2015
-- Autor            : NPC
-- Formato Ejecucion: fglrun srip205 base modulo compañía localidad
-- Ultima Correccion: 
-- Motivo Correccion: 
--------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE rm_par		RECORD
				usuario		LIKE gent005.g05_usuario,
				nom_usua	LIKE gent005.g05_nombres,
				tipo_doc	LIKE cxct004.z04_tipo_doc,
				desc_tip	LIKE cxct004.z04_nombre,
				num_ini		DECIMAL(15,0),
				num_fin		DECIMAL(15,0),
				fecha_ini	DATE,
				fecha_fin	DATE
			END RECORD
DEFINE rm_detalle	ARRAY[20000] OF RECORD
				fecha		DATE,
				tipo		LIKE cxct004.z04_tipo_doc,
				numero		VARCHAR(21),
				referencia	VARCHAR(100),
				valor		DECIMAL(12,2)
			END RECORD
DEFINE rm_adi		ARRAY[20000] OF RECORD
				cod_tran	CHAR(2),
				num_tran	DECIMAL(15,0),
				tp_gen		CHAR(3),
				codigo		INTEGER
			END RECORD
DEFINE rm_g01		RECORD LIKE gent001.*
DEFINE rm_g05		RECORD LIKE gent005.*
DEFINE rm_orden 	ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1	SMALLINT
DEFINE vm_columna_2	SMALLINT
DEFINE vm_col_agr	SMALLINT
DEFINE vm_size_arr	INTEGER
DEFINE vm_max_rows	SMALLINT
DEFINE vm_num_rows	SMALLINT
DEFINE tot_grp		DECIMAL(14,2)
DEFINE total_gen	DECIMAL(14,2)
DEFINE vm_fec_ini	DATE



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/srip205.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 THEN          -- Validar # parámetros correcto
	CALL fl_mostrar_mensaje('Número de parámetros incorrecto.','stop')
	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_codloc  = arg_val(4)
LET vg_proceso = 'srip205'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
--#CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()

END MAIN



FUNCTION funcion_master()
DEFINE lin_menu		SMALLINT
DEFINE row_ini  	SMALLINT
DEFINE num_rows 	SMALLINT
DEFINE num_cols 	SMALLINT

CALL fl_lee_compania(vg_codcia) RETURNING rm_g01.*
IF rm_g01.g01_compania IS NULL THEN
	CALL fl_mostrar_mensaje('No existe esta compañía.', 'stop')
	EXIT PROGRAM
END IF
CALL fl_lee_usuario(vg_usuario) RETURNING rm_g05.*
IF rm_g05.g05_usuario IS NULL THEN
	CALL fl_mostrar_mensaje('Usuario no existe.', 'stop')
	EXIT PROGRAM
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
OPEN WINDOW w_srif205_1 AT row_ini, 02 WITH num_rows ROWS, num_cols COLUMNS
	ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE lin_menu,
		  BORDER, MESSAGE LINE LAST) 
IF vg_gui = 1 THEN
	OPEN FORM f_srif205_1 FROM '../forms/srif205_1'
ELSE
	OPEN FORM f_srif205_1 FROM '../forms/srif205_1c'
END IF
DISPLAY FORM f_srif205_1
LET vm_max_rows = 20000
--#DISPLAY 'Fecha'		TO tit_col1
--#DISPLAY 'TD'			TO tit_col2
--#DISPLAY 'Documento'		TO tit_col3
--#DISPLAY 'Cliente/Referencia'	TO tit_col4
--#DISPLAY 'Valor'		TO tit_col5
--#LET vm_size_arr = fgl_scr_size('rm_detalle')
IF vg_gui = 0 THEN
	LET vm_size_arr = 13
END IF
INITIALIZE rm_par.* TO NULL
IF rm_g05.g05_tipo <> "AG" THEN
	LET rm_par.usuario  = rm_g05.g05_usuario
	LET rm_par.nom_usua = rm_g05.g05_nombres
END IF
LET vm_fec_ini       = MDY(01, 01, 2015)
LET rm_par.fecha_ini = TODAY
LET rm_par.fecha_fin = TODAY
WHILE TRUE
	CALL inicializar_detalle()
	CALL lee_parametros()
	IF int_flag THEN
		EXIT WHILE
	END IF
	CALL muestra_consulta()
END WHILE
CLOSE WINDOW w_srif205_1
EXIT PROGRAM

END FUNCTION



FUNCTION lee_parametros()
DEFINE r_g05		RECORD LIKE gent005.*
DEFINE r_p04		RECORD LIKE cxpt004.*
DEFINE r_z04		RECORD LIKE cxct004.*
DEFINE fec_ini, fec_fin	DATE

OPTIONS INPUT NO WRAP
LET int_flag = 0
INPUT BY NAME rm_par.*
	WITHOUT DEFAULTS
        ON KEY(INTERRUPT)
		LET int_flag = 1
		EXIT INPUT
	ON KEY(F2)
		IF INFIELD(usuario) AND rm_g05.g05_tipo <> 'UF' THEN
			CALL fl_ayuda_usuarios("A")
				RETURNING r_g05.g05_usuario, r_g05.g05_nombres
			IF r_g05.g05_usuario IS NOT NULL THEN
				LET rm_par.usuario  = r_g05.g05_usuario
				LET rm_par.nom_usua = r_g05.g05_nombres
				DISPLAY BY NAME rm_par.usuario, rm_par.nom_usua
			END IF
		END IF
		IF INFIELD(tipo_doc) THEN
			CALL fl_ayuda_tipo_documento_cobranzas('0')
				RETURNING r_z04.z04_tipo_doc, r_z04.z04_nombre
			IF r_z04.z04_tipo_doc IS NOT NULL THEN
				LET rm_par.tipo_doc = r_z04.z04_tipo_doc
				LET rm_par.desc_tip = r_z04.z04_nombre
				DISPLAY BY NAME rm_par.tipo_doc, rm_par.desc_tip
			END IF
		END IF
		LET int_flag = 0
	BEFORE FIELD usuario
		IF rm_g05.g05_tipo = "UF" THEN
			LET r_g05.g05_usuario = rm_g05.g05_usuario
			LET r_g05.g05_nombres = rm_g05.g05_nombres
		ELSE
			LET r_g05.g05_usuario = rm_par.usuario
			LET r_g05.g05_nombres = rm_par.nom_usua
		END IF
	BEFORE FIELD fecha_ini
		LET fec_ini = rm_par.fecha_ini
	BEFORE FIELD fecha_fin
		LET fec_fin = rm_par.fecha_fin
	AFTER FIELD usuario
		IF rm_par.usuario IS NULL AND rm_g05.g05_tipo <> "AG" THEN
			LET rm_par.usuario  = r_g05.g05_usuario
			LET rm_par.nom_usua = r_g05.g05_nombres
			DISPLAY BY NAME rm_par.usuario, rm_par.nom_usua
		END IF
		IF rm_g05.g05_tipo = "UF" THEN
			CONTINUE INPUT
		END IF
		IF rm_par.usuario IS NOT NULL THEN
			CALL fl_lee_usuario(rm_par.usuario) RETURNING r_g05.*
			IF r_g05.g05_usuario IS NULL THEN
				CALL fl_mostrar_mensaje('No existe este usuario.', 'exclamation')
				LET rm_par.nom_usua = NULL
				DISPLAY BY NAME rm_par.nom_usua
				NEXT FIELD usuario
			END IF
			IF r_g05.g05_estado = "B" THEN
				CALL fl_mostrar_mensaje('Usuario esta BLOQUEADO.', 'exclamation')
				NEXT FIELD usuario
			END IF
			LET rm_par.nom_usua = r_g05.g05_nombres
		ELSE
			LET rm_par.nom_usua = NULL
		END IF
		DISPLAY BY NAME rm_par.nom_usua
	AFTER FIELD tipo_doc
		IF rm_par.tipo_doc IS NOT NULL THEN
			IF rm_par.tipo_doc <> 'RT' THEN
				CALL fl_lee_tipo_doc(rm_par.tipo_doc)
					RETURNING r_z04.*
				IF r_z04.z04_tipo_doc IS NULL THEN
					CALL fl_mostrar_mensaje('No existe este Tipo de Documento.', 'exclamation')
					NEXT FIELD tipo_doc
				END IF
				IF r_z04.z04_estado = 'B' THEN
        	                        CALL fl_mensaje_estado_bloqueado()
					NEXT FIELD tipo_doc
				END IF
				LET rm_par.desc_tip = r_z04.z04_nombre
			ELSE
				CALL fl_lee_tipo_doc_tesoreria(rm_par.tipo_doc)
					RETURNING r_p04.*
				IF r_p04.p04_tipo_doc IS NULL THEN
					CALL fl_mostrar_mensaje('No existe este Tipo de Documento Retención.', 'exclamation')
					NEXT FIELD tipo_doc
				END IF
				IF r_p04.p04_estado = 'B' THEN
        	                        CALL fl_mensaje_estado_bloqueado()
					NEXT FIELD tipo_doc
				END IF
				LET rm_par.desc_tip = r_p04.p04_nombre
			END IF
		ELSE
			LET rm_par.desc_tip = NULL
		END IF
		DISPLAY BY NAME rm_par.desc_tip
	AFTER FIELD fecha_ini
		IF rm_par.fecha_ini IS NULL THEN
			LET fec_ini = rm_par.fecha_ini
			DISPLAY BY NAME rm_par.fecha_ini
		END IF
		IF rm_par.fecha_ini < vm_fec_ini THEN
			CALL fl_mostrar_mensaje('La Fecha Inicial no puede ser menor a la fecha de inicio de los documentos electrónicos.', 'info')
			LET rm_par.fecha_ini = vm_fec_ini
			DISPLAY BY NAME rm_par.fecha_ini
		END IF
		IF rm_par.fecha_ini > TODAY THEN
			CALL fl_mostrar_mensaje('La Fecha Inicial no puede ser mayor a la fecha de hoy.', 'exclamation')
			NEXT FIELD fecha_ini
		END IF
	AFTER FIELD fecha_fin
		IF rm_par.fecha_fin IS NULL THEN
			LET fec_fin = rm_par.fecha_fin
			DISPLAY BY NAME rm_par.fecha_fin
		END IF
		IF rm_par.fecha_fin > TODAY THEN
			CALL fl_mostrar_mensaje('La Fecha Final no puede ser mayor a la fecha de hoy.', 'exclamation')
			NEXT FIELD fecha_fin
		END IF
	AFTER INPUT
		IF rm_par.num_ini IS NOT NULL AND rm_par.num_fin IS NOT NULL
		THEN
			IF rm_par.num_ini > rm_par.num_fin THEN
				CALL fl_mostrar_mensaje('El No. del Documento Inicial no puede ser mayor al No. del Documento Final.', 'exclamation')
				NEXT FIELD num_ini
			END IF
		END IF
		IF rm_par.fecha_ini > rm_par.fecha_fin THEN
			CALL fl_mostrar_mensaje('La Fecha Inicial no puede ser mayor a la Fecha Final.', 'exclamation')
			NEXT FIELD fecha_ini
		END IF
END INPUT

END FUNCTION



FUNCTION muestra_consulta()
DEFINE num_row, col	SMALLINT
DEFINE query		CHAR(400)
DEFINE expr_sql		VARCHAR(150)
DEFINE mensaje		VARCHAR(200)
DEFINE correo		LIKE cxct002.z02_email

IF NOT preparar_query() THEN
	DROP TABLE tmp_det
	CALL fl_mensaje_consulta_sin_registros()
	RETURN
END IF
LET int_flag = 0
CONSTRUCT BY NAME expr_sql ON referencia
	ON KEY(INTERRUPT)
		LET int_flag = 1
		EXIT CONSTRUCT
END CONSTRUCT
IF int_flag THEN
	DROP TABLE tmp_det
	RETURN
END IF
LET vm_col_agr = 0
FOR num_row = 1 TO 10
	LET rm_orden[num_row] = '' 
END FOR
LET col                    = 1
LET vm_columna_1           = col
LET vm_columna_2           = 3
LET rm_orden[vm_columna_1] = 'ASC'
LET rm_orden[vm_columna_2] = 'ASC'
WHILE TRUE
	LET query = 'SELECT * FROM tmp_det ',
			' WHERE ', expr_sql CLIPPED,
			' ORDER BY ', vm_columna_1, ' ', rm_orden[vm_columna_1],
				', ', vm_columna_2, ' ', rm_orden[vm_columna_2] 
	PREPARE crep FROM query
	DECLARE q_crep CURSOR FOR crep 
	LET num_row   = 1
	LET total_gen = 0
	FOREACH q_crep INTO rm_detalle[num_row].*, rm_adi[num_row].*
		LET total_gen = total_gen + rm_detalle[num_row].valor
		LET num_row   = num_row + 1
		IF num_row > vm_max_rows THEN
			EXIT FOREACH
		END IF
	END FOREACH
	LET vm_num_rows = num_row - 1
	IF vm_num_rows = 0 THEN
		CALL fl_mensaje_consulta_sin_registros()
		EXIT WHILE
	END IF
	DISPLAY BY NAME total_gen
	LET int_flag = 0
	CALL set_count(vm_num_rows)
	DISPLAY ARRAY rm_detalle TO rm_detalle.*
		ON KEY(INTERRUPT)
			LET int_flag = 1
			EXIT DISPLAY
		ON KEY(F5)
			LET num_row = arr_curr()
			CALL control_ver_documento(num_row)
			LET int_flag = 0
		ON KEY(F6)
			IF correo IS NULL THEN	
				IF rm_detalle[num_row].tipo <> "RT" THEN
					LET mensaje = 'Cliente'
				ELSE
					LET mensaje = 'Proveedor'
				END IF
				LET mensaje = mensaje CLIPPED, ' no tiene ',
						'registrado el correo ',
						'electrónico para esta ',
						'localidad.'
				CALL fl_mostrar_mensaje(mensaje, 'exclamation')
			ELSE
				LET num_row = arr_curr()
				CALL generar_doc_elec(num_row, 'U')
				LET int_flag = 0
			END IF
		ON KEY(F7)
			CALL gen_todos_xml()
			LET int_flag = 0
		ON KEY(F8)
			CALL control_imprimir()
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
		BEFORE ROW
			LET num_row = arr_curr()
			CALL muestra_contadores_det(num_row, vm_num_rows)
			CALL retornar_correo(num_row) RETURNING correo
			DISPLAY BY NAME correo
		BEFORE DISPLAY
			CALL dialog.keysetlabel("ACCEPT","")
			CALL dialog.keysetlabel("RETURN","")
		AFTER DISPLAY
			CONTINUE DISPLAY
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
	IF col = 2 THEN
		LET vm_col_agr = col
	ELSE
		LET vm_col_agr = 0
	END IF
END WHILE
DROP TABLE tmp_det

END FUNCTION



FUNCTION preparar_query()
DEFINE query		CHAR(10000)
DEFINE expr_usua	VARCHAR(100)
DEFINE expr_usua2	VARCHAR(400)
DEFINE expr_num		VARCHAR(150)
DEFINE expr_num2	VARCHAR(150)
DEFINE cuantos		INTEGER
DEFINE resul		SMALLINT

IF rm_par.tipo_doc IS NULL OR rm_par.tipo_doc = "FA" THEN
	LET expr_usua  = NULL
	LET expr_usua2 = NULL
	IF rm_par.usuario IS NOT NULL THEN
		LET expr_usua  = '  AND r19_usuario = "',
					rm_par.usuario CLIPPED, '" '
		LET expr_usua2 = '  AND EXISTS ',
					'(SELECT 1 FROM cajt010 ',
					'WHERE j10_compania    = t23_compania ',
					'  AND j10_localidad   = t23_localidad',
					'  AND j10_tipo_fuente = "OT" ',
					'  AND j10_num_fuente  = t23_orden ',
					'  AND j10_estado      = "P" ',
					'  AND j10_usuario     = "',
						rm_par.usuario CLIPPED, '")'
	END IF
	LET expr_num = NULL
	IF rm_par.num_ini IS NOT NULL AND rm_par.num_fin IS NULL THEN
		LET expr_num = '  AND r19_num_tran     >= ', rm_par.num_ini
	END IF
	IF rm_par.num_ini IS NULL AND rm_par.num_fin IS NOT NULL THEN
		LET expr_num = '  AND r19_num_tran     <= ', rm_par.num_fin
	END IF
	IF rm_par.num_ini IS NOT NULL AND rm_par.num_fin IS NOT NULL THEN
		LET expr_num = '  AND r19_num_tran     BETWEEN ',rm_par.num_ini,
							 ' AND ',rm_par.num_fin
	END IF
	LET expr_num2 = NULL
	IF rm_par.num_ini IS NOT NULL AND rm_par.num_fin IS NULL THEN
		LET expr_num2 = '  AND t23_num_factura  >= ', rm_par.num_ini
	END IF
	IF rm_par.num_ini IS NULL AND rm_par.num_fin IS NOT NULL THEN
		LET expr_num2 = '  AND t23_num_factura  <= ', rm_par.num_fin
	END IF
	IF rm_par.num_ini IS NOT NULL AND rm_par.num_fin IS NOT NULL THEN
		LET expr_num2 = '  AND t23_num_factura  BETWEEN ',
					rm_par.num_ini, ' AND ', rm_par.num_fin
	END IF
	LET query = 'SELECT DATE(r19_fecing) AS fecha, ',
			'r19_cod_tran AS tipo_doc, ',
			'LPAD(g02_serie_cia, 3, 0) || "-" || ',
			'LPAD(g02_serie_loc, 3, 0) || "-" || ',
			'LPAD(r19_num_tran, 9, 0) AS numero, ',
			'r19_nomcli AS referencia, ',
			'r19_tot_neto AS valor, ',
			'r19_cod_tran AS cod_tran, ',
			'r19_num_tran AS num_tran, ',
			'"FAI" AS tp_gen, ',
			'r19_codcli AS codigo ',
		'FROM rept019, gent002 ',
		'WHERE r19_compania     = ', vg_codcia,
		'  AND r19_localidad    = ', vg_codloc,
		'  AND r19_cod_tran     = "FA" ',
		expr_num CLIPPED,
		'  AND DATE(r19_fecing) BETWEEN DATE("', rm_par.fecha_ini,'") ',
					  ' AND DATE("', rm_par.fecha_fin,'") ',
		'  AND g02_compania     = r19_compania ',
		'  AND g02_localidad    = r19_localidad ',
		expr_usua CLIPPED,
		' UNION ALL ',
		'SELECT DATE(t23_fec_factura) AS fecha, ',
			'"FA" AS tipo_doc, ',
			'LPAD(g02_serie_cia, 3, 0) || "-" || ',
			'LPAD(g02_serie_loc, 3, 0) || "-" || ',
			'LPAD(t23_num_factura, 9, 0) AS numero, ',
			't23_nom_cliente AS referencia, ',
			't23_tot_neto AS valor, ',
			'"F" AS cod_tran, ',
			't23_num_factura AS num_tran, ',
			'"FAT" AS tp_gen, ',
			't23_cod_cliente AS codigo ',
			'FROM talt023, gent002 ',
			'WHERE t23_compania          = ', vg_codcia,
			'  AND t23_localidad         = ', vg_codloc,
			'  AND t23_estado            = "F" ',
			expr_num2 CLIPPED,
			'  AND DATE(t23_fec_factura) BETWEEN DATE("',
							 rm_par.fecha_ini,'") ',
					  ' AND DATE("', rm_par.fecha_fin,'") ',
			'  AND g02_compania          = t23_compania ',
			'  AND g02_localidad         = t23_localidad ',
			expr_usua2 CLIPPED
END IF
IF rm_par.tipo_doc IS NULL OR rm_par.tipo_doc = "NC" THEN
	IF rm_par.tipo_doc = "NC" THEN
		LET query = ' '
	ELSE
		LET query = query CLIPPED, ' UNION ALL '
	END IF
	LET expr_usua = NULL
	IF rm_par.usuario IS NOT NULL THEN
		LET expr_usua = '  AND z21_usuario = "',
					rm_par.usuario CLIPPED, '" '
	END IF
	LET expr_num = NULL
	IF rm_par.num_ini IS NOT NULL AND rm_par.num_fin IS NULL THEN
		LET expr_num = '  AND z21_num_doc      >= ', rm_par.num_ini
	END IF
	IF rm_par.num_ini IS NULL AND rm_par.num_fin IS NOT NULL THEN
		LET expr_num = '  AND z21_num_doc      <= ', rm_par.num_fin
	END IF
	IF rm_par.num_ini IS NOT NULL AND rm_par.num_fin IS NOT NULL THEN
		LET expr_num = '  AND z21_num_doc      BETWEEN ',rm_par.num_ini,
							 ' AND ',rm_par.num_fin
	END IF
	LET query = query CLIPPED,
		' SELECT z21_fecha_emi AS fecha, ',
			'z21_tipo_doc AS tipo_doc, ',
			'LPAD(g02_serie_cia, 3, 0) || "-" || ',
			'LPAD(g02_serie_loc, 3, 0) || "-" || ',
			'LPAD(z21_num_doc, 9, 0) AS numero, ',
			'z01_nomcli AS referencia, ',
			'(z21_valor * (-1)) AS valor, ',
			'CASE WHEN z21_areaneg = 1 ',
				'THEN z21_cod_tran ',
				'ELSE "D" ',
			'END AS cod_tran, ',
			'CASE WHEN z21_areaneg = 1 ',
				'THEN z21_num_tran ',
				'ELSE (SELECT t28_num_dev ',
					'FROM talt028 ',
					'WHERE t28_compania  = z21_compania ',
					'  AND t28_localidad = z21_localidad ',
					'  AND t28_factura   = z21_num_tran) ',
			'END AS num_tran, ',
			'CASE WHEN z21_areaneg = 1 ',
				'THEN "NCI" ',
				'ELSE "NCT" ',
			'END AS tp_gen, ',
			'z21_codcli AS codigo ',
			'FROM cxct021, cxct001, gent002 ',
			'WHERE z21_compania  = ', vg_codcia,
			'  AND z21_localidad = ', vg_codloc,
			'  AND z21_tipo_doc  = "NC" ',
			expr_num CLIPPED,
			'  AND z21_origen    = "A" ',
			'  AND z21_fecha_emi BETWEEN DATE("',
							 rm_par.fecha_ini,'") ',
					  ' AND DATE("', rm_par.fecha_fin,'") ',
			'  AND z01_codcli    = z21_codcli ',
			'  AND g02_compania  = z21_compania ',
			'  AND g02_localidad = z21_localidad ',
			expr_usua CLIPPED,
		' UNION ALL ',
		'SELECT z21_fecha_emi AS fecha, ',
			'z21_tipo_doc AS tipo_doc, ',
			'LPAD(g02_serie_cia, 3, 0) || "-" || ',
			'LPAD(g02_serie_loc, 3, 0) || "-" || ',
			'LPAD(z21_num_doc, 9, 0) AS numero, ',
			'z01_nomcli AS referencia, ',
			'(z21_valor * (-1)) AS valor, ',
			'z21_tipo_doc AS cod_tran, ',
			'z21_num_doc AS num_tran, ',
			'"NCC" AS tp_gen, ',
			'z21_codcli AS codigo ',
			'FROM cxct021, cxct001, gent002 ',
			'WHERE z21_compania  = ', vg_codcia,
			'  AND z21_localidad = ', vg_codloc,
			'  AND z21_tipo_doc  = "NC" ',
			expr_num CLIPPED,
			'  AND z21_origen    = "M" ',
			'  AND z21_fecha_emi BETWEEN DATE("',
							 rm_par.fecha_ini,'") ',
					  ' AND DATE("', rm_par.fecha_fin,'") ',
			'  AND z01_codcli    = z21_codcli ',
			'  AND g02_compania  = z21_compania ',
			'  AND g02_localidad = z21_localidad ',
			expr_usua CLIPPED
END IF
IF rm_par.tipo_doc IS NULL OR rm_par.tipo_doc = "RT" THEN
	IF rm_par.tipo_doc = "RT" THEN
		LET query = ' '
	ELSE
		LET query = query CLIPPED, ' UNION ALL '
	END IF
	LET expr_usua = NULL
	IF rm_par.usuario IS NOT NULL THEN
		LET expr_usua = '  AND p27_usuario = "',
					rm_par.usuario CLIPPED, '" '
	END IF
	LET expr_num = NULL
	IF rm_par.num_ini IS NOT NULL AND rm_par.num_fin IS NULL THEN
		LET expr_num = '  AND p27_num_ret      >= ', rm_par.num_ini
	END IF
	IF rm_par.num_ini IS NULL AND rm_par.num_fin IS NOT NULL THEN
		LET expr_num = '  AND p27_num_ret      <= ', rm_par.num_fin
	END IF
	IF rm_par.num_ini IS NOT NULL AND rm_par.num_fin IS NOT NULL THEN
		LET expr_num = '  AND p27_num_ret      BETWEEN ',rm_par.num_ini,
							 ' AND ',rm_par.num_fin
	END IF
	LET query = query CLIPPED,
		' SELECT DATE(p27_fecing) AS fecha, ',
			'"RT" AS tipo_doc, ',
			'LPAD(g02_serie_cia, 3, 0) || "-" || ',
			'LPAD(g02_serie_loc, 3, 0) || "-" || ',
			'LPAD(p27_num_ret, 9, 0) AS numero, ',
			'p01_nomprov AS referencia, ',
			'p27_total_ret AS valor, ',
			'"CR" AS cod_tran, ',
			'p27_num_ret AS num_tran, ',
			'"RTP" AS tp_gen, ',
			'p27_codprov AS codigo ',
			'FROM cxpt027, cxpt001, gent002 ',
			'WHERE p27_compania     = ', vg_codcia,
			'  AND p27_localidad    = ', vg_codloc,
			expr_num CLIPPED,
			'  AND p27_estado       = "A" ',
			'  AND DATE(p27_fecing) BETWEEN DATE("',
							 rm_par.fecha_ini,'") ',
					  ' AND DATE("', rm_par.fecha_fin,'") ',
			'  AND p01_codprov      = p27_codprov ',
			'  AND g02_compania     = p27_compania ',
			'  AND g02_localidad    = p27_localidad ',
			expr_usua CLIPPED
END IF
IF rm_par.tipo_doc IS NULL OR rm_par.tipo_doc = "GR" THEN
	IF rm_par.tipo_doc = "GR" THEN
		LET query = ' '
	ELSE
		LET query = query CLIPPED, ' UNION ALL '
	END IF
	LET expr_usua = NULL
	IF rm_par.usuario IS NOT NULL THEN
		LET expr_usua = '  AND r95_usuario = "',
					rm_par.usuario CLIPPED, '" '
	END IF
	LET expr_num = NULL
	IF rm_par.num_ini IS NOT NULL AND rm_par.num_fin IS NULL THEN
		LET expr_num = '  AND r95_guia_remision >= ', rm_par.num_ini
	END IF
	IF rm_par.num_ini IS NULL AND rm_par.num_fin IS NOT NULL THEN
		LET expr_num = '  AND r95_guia_remision <= ', rm_par.num_fin
	END IF
	IF rm_par.num_ini IS NOT NULL AND rm_par.num_fin IS NOT NULL THEN
		LET expr_num = '  AND r95_guia_remision BETWEEN ',
					rm_par.num_ini, ' AND ', rm_par.num_fin
	END IF
	LET query = query CLIPPED,
		' SELECT DATE(r95_fecing) AS fecha, ',
			'"GR" AS tipo_doc, ',
			'LPAD(g02_serie_cia, 3, 0) || "-" || ',
			'LPAD(g02_serie_loc, 3, 0) || "-" || ',
			'LPAD(r95_guia_remision, 9, 0) AS numero, ',
			'NVL(r95_proc_orden, r95_persona_dest) AS referencia, ',
			'0.00 AS valor, ',
			'"GR" AS cod_tran, ',
			'r95_guia_remision AS num_tran, ',
			'"GRI" AS tp_gen, ',
			'0 AS codigo ',
			'FROM rept095, gent002 ',
			'WHERE r95_compania     = ', vg_codcia,
			'  AND r95_localidad    = ', vg_codloc,
			expr_num CLIPPED,
			'  AND r95_estado       = "C" ',
			'  AND DATE(r95_fecing) BETWEEN DATE("',
							 rm_par.fecha_ini,'") ',
					  ' AND DATE("', rm_par.fecha_fin,'") ',
			'  AND g02_compania     = r95_compania ',
			'  AND g02_localidad    = r95_localidad ',
			expr_usua CLIPPED
END IF
IF rm_par.tipo_doc IS NULL OR rm_par.tipo_doc = "ND" THEN
	IF rm_par.tipo_doc = "ND" THEN
		LET query = ' '
	ELSE
		LET query = query CLIPPED, ' UNION ALL '
	END IF
	LET expr_usua = NULL
	IF rm_par.usuario IS NOT NULL THEN
		LET expr_usua = '  AND z20_usuario = "',
					rm_par.usuario CLIPPED, '" '
	END IF
	LET expr_num = NULL
	IF rm_par.num_ini IS NOT NULL AND rm_par.num_fin IS NULL THEN
		LET expr_num = '  AND CAST(z20_num_doc AS INTEGER) >= ',
				rm_par.num_ini
	END IF
	IF rm_par.num_ini IS NULL AND rm_par.num_fin IS NOT NULL THEN
		LET expr_num = '  AND CAST(z20_num_doc AS INTEGER) <= ',
				rm_par.num_fin
	END IF
	IF rm_par.num_ini IS NOT NULL AND rm_par.num_fin IS NOT NULL THEN
		LET expr_num = '  AND CAST(z20_num_doc AS INTEGER) BETWEEN ',
					rm_par.num_ini, ' AND ', rm_par.num_fin
	END IF
	LET query = query CLIPPED,
		' SELECT z20_fecha_emi AS fecha, ',
			'z20_tipo_doc AS tipo_doc, ',
			'LPAD(g02_serie_cia, 3, 0) || "-" || ',
			'LPAD(g02_serie_loc, 3, 0) || "-" || ',
			'LPAD(CAST(z20_num_doc AS INTEGER), 9, 0) AS numero, ',
			'z01_nomcli AS referencia, ',
			'z20_valor_cap AS valor, ',
			'z20_tipo_doc AS cod_tran, ',
			'CAST(z20_num_doc AS DECIMAL) AS num_tran, ',
			'"NDC" AS tp_gen, ',
			'z20_codcli AS codigo ',
			'FROM cxct020, cxct001, gent002 ',
			'WHERE z20_compania  = ', vg_codcia,
			'  AND z20_localidad = ', vg_codloc,
			'  AND z20_tipo_doc  = "ND" ',
			expr_num CLIPPED,
			'  AND z20_dividendo = 1 ',
			'  AND z20_fecha_emi BETWEEN DATE("',
							 rm_par.fecha_ini,'") ',
					  ' AND DATE("', rm_par.fecha_fin,'") ',
			'  AND z01_codcli    = z20_codcli ',
			'  AND g02_compania  = z20_compania ',
			'  AND g02_localidad = z20_localidad ',
			expr_usua CLIPPED
END IF
LET query = query CLIPPED, ' INTO TEMP tmp_det'
PREPARE exec_tmp FROM query
EXECUTE exec_tmp
SELECT COUNT(*) INTO cuantos FROM tmp_det
LET resul = 1
IF cuantos = 0 THEN
	LET resul = 0
END IF
RETURN resul

END FUNCTION



FUNCTION control_ver_documento(num_row)
DEFINE num_row		SMALLINT
DEFINE modulo		VARCHAR(15)
DEFINE mod		LIKE gent050.g50_modulo
DEFINE prog		VARCHAR(10)
DEFINE param		VARCHAR(100)

IF rm_adi[num_row].tp_gen = "FAI" OR rm_adi[num_row].tp_gen = "NCI" THEN
	CALL fl_ver_transaccion_rep(vg_codcia, vg_codloc,
					rm_adi[num_row].cod_tran,
					rm_adi[num_row].num_tran)
	RETURN
END IF
IF rm_adi[num_row].tp_gen = "FAT" OR rm_adi[num_row].tp_gen = "NCT" THEN
	CALL fl_ver_factura_dev_tal(rm_adi[num_row].num_tran,
					rm_adi[num_row].cod_tran)
	RETURN
END IF
CASE rm_adi[num_row].tp_gen
	WHEN "RTP"
		LET modulo = 'TESORERIA'
		LET mod    = 'TE'
		LET prog   = 'cxpp304'
		LET param  = ' ', rm_adi[num_row].codigo, ' ',
				rm_adi[num_row].num_tran
	WHEN "GRI"
		LET modulo = 'REPUESTOS'
		LET mod    = 'RE'
		LET prog   = 'repp241'
		LET param  = ' ', rm_adi[num_row].num_tran
	WHEN "NDC"
		LET modulo = 'COBRANZAS'
		LET mod    = 'CO'
		LET prog   = 'cxcp200'
		LET param  = ' ', rm_adi[num_row].codigo, ' ',
				rm_adi[num_row].cod_tran, ' ',
				rm_adi[num_row].num_tran, 1
	WHEN "NCC"
		LET modulo = 'COBRANZAS'
		LET mod    = 'CO'
		LET prog   = 'cxcp201'
		LET param  = ' ', rm_adi[num_row].codigo, ' ',
				rm_adi[num_row].cod_tran, ' ',
				rm_adi[num_row].num_tran
END CASE
CALL fl_ejecuta_comando(modulo, mod, prog, param, 1)

END FUNCTION



FUNCTION generar_doc_elec(num_row, flag)
DEFINE num_row		INTEGER
DEFINE flag		CHAR(1)
DEFINE comando		VARCHAR(250)
DEFINE servid		VARCHAR(10)
DEFINE mensaje		VARCHAR(250)
DEFINE r_z04		RECORD LIKE cxct004.*
DEFINE r_p04		RECORD LIKE cxpt004.*

LET servid  = FGL_GETENV("INFORMIXSERVER")
CASE servid
	WHEN "ACGYE01"
		LET servid = "idsgye01"
	WHEN "ACUIO01"
		LET servid = "idsuio01"
	WHEN "ACUIO02"
		LET servid = "idsuio02"
END CASE
LET comando = "umask 0002; fglgo gen_tra_ele ", vg_base CLIPPED, " ",
		servid CLIPPED, " ", vg_codcia, " ", vg_codloc, " ",
		rm_adi[num_row].cod_tran, " ", rm_adi[num_row].num_tran, " ",
		rm_adi[num_row].tp_gen
IF rm_adi[num_row].tp_gen = "NDC" OR rm_adi[num_row].tp_gen = "NCC" THEN
	LET comando = comando CLIPPED, " ", rm_adi[num_row].codigo
END IF
RUN comando
LET mensaje = 'Archivo XML de '
IF rm_detalle[num_row].tipo <> "RT" THEN
	CALL fl_lee_tipo_doc(rm_detalle[num_row].tipo) RETURNING r_z04.*
	LET mensaje = mensaje CLIPPED, ' ', r_z04.z04_nombre CLIPPED
ELSE
	CALL fl_lee_tipo_doc_tesoreria(rm_detalle[num_row].tipo)
		RETURNING r_p04.*
	LET mensaje = mensaje CLIPPED, ' ', r_p04.p04_nombre CLIPPED
END IF
LET mensaje = mensaje CLIPPED, ' No. ', rm_detalle[num_row].numero CLIPPED, '.'
IF flag = "U" THEN
	LET mensaje = mensaje CLIPPED,
			' Generado en: ', '/acero/fobos/tmp/',
			rm_detalle[num_row].tipo, '_ELEC/'
END IF
CASE flag
	WHEN "U" CALL fl_mostrar_mensaje(mensaje CLIPPED, 'info')
	WHEN "T" ERROR mensaje CLIPPED ATTRIBUTE(NORMAL)
END CASE

END FUNCTION



FUNCTION gen_todos_xml()
DEFINE mensaje		VARCHAR(200)
DEFINE num_row, cont	SMALLINT
DEFINE resp		CHAR(6)

LET int_flag = 0
CALL fl_hacer_pregunta('Desea generar TODOS LOS ARCHIVOS XML de esta consulta ?', 'No')
	RETURNING resp
IF resp <> 'Yes' THEN
	RETURN
END IF
LET cont = 0
FOR num_row = 1 TO vm_num_rows
	IF retornar_correo(num_row) IS NULL THEN	
		LET mensaje = 'El Doc. ', rm_detalle[num_row].tipo, ' ',
				rm_detalle[num_row].numero CLIPPED
		IF rm_detalle[num_row].tipo <> "RT" THEN
			LET mensaje = mensaje CLIPPED, ' del Cliente'
		ELSE
			LET mensaje = mensaje CLIPPED, ' del Proveedor'
		END IF
		LET mensaje = mensaje CLIPPED, ' no tiene registrado el ',
				'correo electrónico.'
		CALL fl_mostrar_mensaje(mensaje, 'exclamation')
		CONTINUE FOR
	END IF
	CALL generar_doc_elec(num_row, 'T')
	LET cont = cont + 1
END FOR
LET mensaje = 'Se generaron un total de ', cont USING "<<<<&",
		' archivos XML.'
CALL fl_mostrar_mensaje(mensaje, 'info')

END FUNCTION



FUNCTION control_imprimir()
DEFINE tipo_d		LIKE cxct004.z04_tipo_doc
DEFINE comando		VARCHAR(100)
DEFINE num_row		SMALLINT

CALL fl_control_reportes() RETURNING comando
IF int_flag THEN
	RETURN
END IF
START REPORT reporte_archivo_xml TO PIPE comando
FOR num_row = 1 TO vm_num_rows
	LET tipo_d = rm_detalle[num_row].tipo
	OUTPUT TO REPORT reporte_archivo_xml(num_row, tipo_d)
END FOR
FINISH REPORT reporte_archivo_xml

END FUNCTION



REPORT reporte_archivo_xml(num_row, tipo_d)
DEFINE num_row		SMALLINT
DEFINE tipo_d		LIKE cxct004.z04_tipo_doc
DEFINE r_g50		RECORD LIKE gent050.*
DEFINE r_p04		RECORD LIKE cxpt004.*
DEFINE r_z04		RECORD LIKE cxct004.*
DEFINE nombre		LIKE cxct004.z04_nombre
DEFINE usuario		VARCHAR(19,15)
DEFINE modulo		VARCHAR(40)
DEFINE escape		SMALLINT
DEFINE act_comp		SMALLINT
DEFINE desact_comp	SMALLINT
DEFINE act_10cpi	SMALLINT
DEFINE act_neg, des_neg	SMALLINT

OUTPUT
	TOP MARGIN	1
	LEFT MARGIN	0
	RIGHT MARGIN	80
	BOTTOM MARGIN	4
	PAGE LENGTH	66

FORMAT

PAGE HEADER
	LET escape	= 27		# Iniciar sec. impresión
	LET act_comp	= 15		# Activar Comprimido.
	LET desact_comp	= 18		# Cancelar Comprimido.
	LET act_neg	= 71		# Activar negrita.
	LET des_neg	= 72		# Desactivar negrita.
	LET act_10cpi	= 80		# Comprimido 10 CPI.
	CALL fl_lee_modulo(vg_modulo) RETURNING r_g50.*
	LET modulo      = "MODULO: ", r_g50.g50_nombre[1, 19] CLIPPED
	LET usuario     = "USUARIO: ", vg_usuario
	CALL fl_justifica_titulo('D', usuario, 19) RETURNING usuario
	print ASCII escape;
	print ASCII desact_comp;
	print ASCII escape;
	print ASCII act_10cpi;
	PRINT COLUMN 005, rm_g01.g01_razonsocial,
  	      COLUMN 074, "PAGINA: ", PAGENO USING "&&&"
	PRINT COLUMN 001, modulo CLIPPED,
	      COLUMN 024, "DETALLE DOCUMENTOS ELECTRONICOS",
	      COLUMN 074, UPSHIFT(vg_proceso) CLIPPED
	SKIP 1 LINES
	PRINT COLUMN 015, "** RANGO FECHAS  : ",
	      COLUMN 035, rm_par.fecha_ini USING "dd-mm-yyyy", "  -  ",
	      COLUMN 050, rm_par.fecha_fin USING "dd-mm-yyyy"
	IF rm_par.usuario IS NOT NULL THEN
		PRINT COLUMN 015, "** USUARIO       : ",
		      COLUMN 035, rm_par.usuario CLIPPED
	END IF
	IF rm_par.tipo_doc IS NOT NULL THEN
		PRINT COLUMN 015, "** TIPO DOCUMENTO: ",
		      COLUMN 035, rm_par.tipo_doc,
		      COLUMN 038, rm_par.desc_tip CLIPPED
	END IF
	SKIP 1 LINES
	PRINT COLUMN 001, "FECHA IMPRESION: ", TODAY USING "dd-mm-yyyy",
 		1 SPACES, TIME,
	      COLUMN 062, usuario
	PRINT "--------------------------------------------------------------------------------"
	PRINT COLUMN 001, "FECHA",
	      COLUMN 012, "TD",
	      COLUMN 015, "NUMERO DOCUMENTO",
	      COLUMN 034, "CLIENTE/REFERENCIA",
	      COLUMN 068, "        VALOR"
	PRINT "--------------------------------------------------------------------------------"

BEFORE GROUP OF tipo_d
	IF rm_par.tipo_doc IS NULL AND vm_col_agr = 2 THEN
		NEED 7 LINES
		LET tot_grp = 0
		IF tipo_d <> "RT" THEN
			CALL fl_lee_tipo_doc(tipo_d) RETURNING r_z04.*
			LET nombre = r_z04.z04_nombre
		ELSE
			CALL fl_lee_tipo_doc_tesoreria(tipo_d) RETURNING r_p04.*
			LET nombre = r_p04.p04_nombre
		END IF
		PRINT COLUMN 001, "AGRUPADO POR: ", tipo_d CLIPPED,
				" ", nombre CLIPPED
	END IF

ON EVERY ROW
	IF rm_par.tipo_doc IS NULL AND vm_col_agr = 2 THEN
		NEED 3 LINES
	ELSE
		NEED 6 LINES
	END IF
	LET tot_grp = tot_grp + rm_detalle[num_row].valor
	PRINT COLUMN 001, rm_detalle[num_row].fecha	USING "dd-mm-yyyy",
	      COLUMN 012, rm_detalle[num_row].tipo	CLIPPED,
	      COLUMN 015, rm_detalle[num_row].numero,
	      COLUMN 034, rm_detalle[num_row].referencia[1, 33] CLIPPED,
	      COLUMN 068, rm_detalle[num_row].valor	USING "--,---,--&.##"
	
AFTER GROUP OF tipo_d
	IF rm_par.tipo_doc IS NULL AND vm_col_agr = 2 THEN
		NEED 5 LINES
		PRINT COLUMN 068, "-------------"
		PRINT COLUMN 057, "TOTAL ==>  ", tot_grp USING "--,---,--&.##"
		SKIP 1 LINES
	END IF

ON LAST ROW
	NEED 2 LINES
	PRINT COLUMN 068, "-------------"
	PRINT COLUMN 049, "TOTAL GENERAL ==>  ", total_gen USING "--,---,--&.##"
	print ASCII escape;
	print ASCII act_comp

END REPORT



FUNCTION retornar_correo(num_row)
DEFINE num_row		SMALLINT
DEFINE r_z02		RECORD LIKE cxct002.*
DEFINE r_p02		RECORD LIKE cxpt002.*

IF rm_adi[num_row].tp_gen <> "RTP" AND rm_adi[num_row].tp_gen <> "GRI" THEN
	CALL fl_lee_cliente_localidad(vg_codcia, vg_codloc,
					rm_adi[num_row].codigo)
		RETURNING r_z02.*
	RETURN r_z02.z02_email
END IF
IF rm_adi[num_row].tp_gen = "RTP" THEN
	CALL fl_lee_proveedor_localidad(vg_codcia, vg_codloc,
					rm_adi[num_row].codigo)
		RETURNING r_p02.*
	RETURN r_p02.p02_email
END IF
IF rm_adi[num_row].tp_gen = "GRI" THEN
	RETURN correo_guia_remision(num_row)
END IF

END FUNCTION



FUNCTION correo_guia_remision(num_row)
DEFINE num_row		SMALLINT
DEFINE correo		LIKE cxct002.z02_email

DECLARE q_cor_guia CURSOR FOR
	SELECT z02_email
		FROM rept096, rept036, rept034, rept019, cxct002
		WHERE r96_compania      = vg_codcia
		  AND r96_localidad     = vg_codloc
		  AND r96_guia_remision = rm_adi[num_row].num_tran
		  AND r36_compania      = r96_compania
		  AND r36_localidad     = r96_localidad
		  AND r36_bodega        = r96_bodega
		  AND r36_num_entrega   = r96_num_entrega
		  AND r34_compania      = r36_compania
		  AND r34_localidad     = r36_localidad
		  AND r34_bodega        = r36_bodega
		  AND r34_num_ord_des   = r36_num_ord_des
		  AND r19_compania      = r34_compania
		  AND r19_localidad     = r34_localidad
		  AND r19_cod_tran      = r34_cod_tran
		  AND r19_num_tran      = r34_num_tran
		  AND z02_compania      = r19_compania
		  AND z02_localidad     = r19_localidad
		  AND z02_codcli        = r19_codcli
LET correo = NULL
OPEN q_cor_guia
FETCH q_cor_guia INTO correo
CLOSE q_cor_guia
FREE q_cor_guia
IF correo IS NOT NULL THEN
	RETURN correo
END IF
DECLARE q_cor_guia2 CURSOR FOR
	SELECT z02_email
		FROM rept097, rept019, cxct002
		WHERE r97_compania      = vg_codcia
		  AND r97_localidad     = vg_codloc
		  AND r97_guia_remision = rm_adi[num_row].num_tran
		  AND r19_compania      = r97_compania
		  AND r19_localidad     = r97_localidad
		  AND r19_cod_tran      = r97_cod_tran
		  AND r19_num_tran      = r97_num_tran
		  AND z02_compania      = r19_compania
		  AND z02_localidad     = r19_localidad
		  AND z02_codcli        = r19_codcli
LET correo = NULL
OPEN q_cor_guia2
FETCH q_cor_guia2 INTO correo
CLOSE q_cor_guia2
FREE q_cor_guia2
RETURN correo

END FUNCTION



FUNCTION muestra_contadores_det(num_row, max_row)
DEFINE num_row, max_row	SMALLINT

DISPLAY BY NAME num_row, max_row

END FUNCTION



FUNCTION inicializar_detalle()
DEFINE i		SMALLINT

LET vm_num_rows = 0
FOR i = 1 TO vm_size_arr 
	CLEAR rm_detalle[i].*
END FOR
CLEAR correo, total_gen, num_row, max_row
FOR i = 1 TO vm_max_rows
	INITIALIZE rm_detalle[i].*, rm_adi[i].* TO NULL
END FOR

END FUNCTION
