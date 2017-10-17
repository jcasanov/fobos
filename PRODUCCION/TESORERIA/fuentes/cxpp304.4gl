--------------------------------------------------------------------------------
-- Titulo           : cxpp304.4gl - Consulta de Retenciones de proveedores
-- Elaboracion      : 19-dic-2001
-- Autor            : GVA
-- Formato Ejecucion: fglrun cxpp304 base módulo compañía localidad
-- Ultima Correccion:
-- Motivo Correccion:
--------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_max_det       SMALLINT
DEFINE vm_num_det       SMALLINT
DEFINE vm_scr_lin       SMALLINT
DEFINE vm_fecha_desde	DATE
DEFINE vm_fecha_hasta	DATE
DEFINE vm_numero_oc	LIKE ordt010.c10_numero_oc
DEFINE vm_proveedor	LIKE ordt010.c10_codprov
DEFINE vm_depto		LIKE ordt010.c10_cod_depto
DEFINE vm_tipo_orden	LIKE ordt010.c10_tipo_orden

DEFINE rm_orden 	ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1	SMALLINT
DEFINE vm_columna_2	SMALLINT

DEFINE r_detalle		ARRAY [1000] OF RECORD
							fecha			DATE,
							proveedor		LIKE cxpt001.p01_nomprov,
							num_ret_sri		LIKE cxpt029.p29_num_sri,
							num_ret			LIKE cxpt027.p27_num_ret,
							p27_total_ret	LIKE cxpt027.p27_total_ret,
							p27_estado		LIKE cxpt027.p27_estado
						END RECORD

DEFINE r_detalle_2	ARRAY [1000] OF RECORD
				p28_tipo_doc	LIKE cxpt028.p28_tipo_doc,
				p28_num_doc	LIKE cxpt028.p28_num_doc,
				tipo_ret	VARCHAR(10),
				p28_porcentaje	LIKE cxpt028.p28_porcentaje,
				p28_valor_base	LIKE cxpt028.p28_valor_base,
				p28_valor_ret	LIKE cxpt028.p28_valor_ret
			END RECORD

DEFINE r_detalle_1	ARRAY [1000] OF RECORD
				codprov		LIKE cxpt001.p01_codprov
			END RECORD

DEFINE vm_num_ret	LIKE cxpt027.p27_num_ret
DEFINE rm_p27		RECORD LIKE cxpt027.*
DEFINE rm_p28		RECORD LIKE cxpt028.*
DEFINE vm_filas_pant	SMALLINT
DEFINE vm_nomprov	LIKE cxpt001.p01_nomprov
DEFINE vm_numret	LIKE cxpt027.p27_num_ret
DEFINE vm_estado	LIKE cxpt027.p27_estado

DEFINE vg_proveedor	LIKE cxpt001.p01_codprov
DEFINE vg_num_ret	LIKE cxpt027.p27_num_ret
DEFINE tot_base		LIKE cxpt028.p28_valor_base
DEFINE tot_ret		LIKE cxpt028.p28_valor_ret



MAIN

DEFER QUIT 
DEFER INTERRUPT
CLEAR SCREEN

LET vg_proceso = arg_val(0)
CALL startlog('../logs/' || vg_proceso CLIPPED || '.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()

IF num_args() <> 4 AND num_args() <> 5 AND num_args() <> 6 THEN  
	CALL fl_mostrar_mensaje('Número de parametros incorrecto.','stop')
	EXIT PROGRAM
END IF

LET vg_base      = arg_val(1)
LET vg_modulo    = arg_val(2)
LET vg_codcia    = arg_val(3)
LET vg_codloc    = arg_val(4)
LET vg_proveedor = arg_val(5)
LET vg_num_ret   = arg_val(6)

CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
--#CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)

CREATE TEMP TABLE tmp_consulta(
	fecha		DATE,
	proveedor	VARCHAR(40),
	num_ret_sri	VARCHAR(21),
	num_ret		INTEGER,
	p27_total_ret	DECIMAL(11,2),
	estado		CHAR(1),
	codprov		INTEGER)

CREATE TEMP TABLE tmp_consulta_2(
	p28_tipo_doc	CHAR(2),
	p28_num_doc	VARCHAR(17),
	tipo_ret	VARCHAR(10),
	p28_porcentaje	DECIMAL(5,2),
	p28_valor_base	DECIMAL(12,2),
	p28_valor_ret	DECIMAL(11,2))

CALL funcion_master()

END MAIN



FUNCTION funcion_master()
DEFINE i		SMALLINT
DEFINE lin_menu		SMALLINT
DEFINE row_ini  	SMALLINT
DEFINE num_rows 	SMALLINT
DEFINE num_cols 	SMALLINT

CALL fl_nivel_isolation()

LET vm_max_det  = 1000

IF num_args() = 6 THEN
	CALL control_ver_retencion(vg_proveedor, vg_num_ret)
	RETURN
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
OPEN WINDOW w_cxpp304 AT row_ini, 2 WITH num_rows ROWS, num_cols COLUMNS
	ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE lin_menu,
		  BORDER, MESSAGE LINE LAST - 1) 
IF vg_gui = 1 THEN
	OPEN FORM f_cxpp304 FROM "../forms/cxpf304_1"
ELSE
	OPEN FORM f_cxpp304 FROM "../forms/cxpf304_1c"
END IF
DISPLAY FORM f_cxpp304

LET vm_filas_pant = fgl_scr_size('r_detalle')

LET vm_num_det = 0

INITIALIZE rm_p27.*, rm_p28.*, vm_fecha_desde, vm_proveedor TO NULL
LET vm_fecha_desde    = vg_fecha
LET vm_fecha_hasta    = vg_fecha
WHILE TRUE
	IF vm_num_det = 0 THEN
		FOR i = 1 TO vm_filas_pant
			INITIALIZE r_detalle[i].* TO NULL
		END FOR
	ELSE
		FOR i = 1 TO vm_num_det
			INITIALIZE r_detalle[i].* TO NULL
		END FOR
	END IF
	CLEAR FORM 
	CALL control_DISPLAY_botones()
	DELETE FROM tmp_consulta

	CALL control_lee_cabecera()
	IF INT_FLAG THEN
		CONTINUE WHILE
	END IF
	CALL control_consulta()
	IF INT_FLAG THEN
		CONTINUE WHILE
	END IF

	IF vm_num_det = 0 THEN
		CALL fl_mostrar_mensaje('No se encontraron registros con el criterio indicado.','exclamation')
		CONTINUE WHILE
	END IF
	CALL control_DISPLAY_array()
END WHILE

END FUNCTION



FUNCTION control_DISPLAY_botones()

--#DISPLAY 'Fecha'     			TO tit_col1
--#DISPLAY 'Proveedor'			TO tit_col2
--#DISPLAY 'Num Ret SRI'   		TO tit_col3
--#DISPLAY 'NumRet'   			TO tit_col4
--#DISPLAY 'Total'			 	TO tit_col5
--#DISPLAY 'E'				 	TO tit_col6

END FUNCTION



FUNCTION control_DISPLAY_botones_2()

--#DISPLAY 'TP'       		TO tit_col1
--#DISPLAY 'No Documento'	TO tit_col2
--#DISPLAY 'Tipo RT'		TO tit_col3
--#DISPLAY '%'      		TO tit_col4
--#DISPLAY 'Valor Base'   	TO tit_col5
--#DISPLAY 'Valor Ret'	 	TO tit_col6

END FUNCTION



FUNCTION control_lee_cabecera()
DEFINE i,j,col		SMALLINT
DEFINE r_p01		RECORD LIKE cxpt001.*
DEFINE fec_ini		DATE
DEFINE fec_fin		DATE

	DISPLAY BY NAME vm_proveedor, vm_fecha_desde, vm_fecha_hasta

	CALL fl_lee_proveedor(vm_proveedor)
		RETURNING r_p01.*
	DISPLAY r_p01.p01_nomprov TO nom_proveedor

	LET INT_FLAG   = 0
	INPUT BY NAME vm_proveedor, vm_fecha_desde, vm_fecha_hasta  
		      WITHOUT DEFAULTS

	ON KEY(INTERRUPT)
		IF num_args() = 5 THEN
			EXIT PROGRAM
		END IF	
		IF NOT FIELD_TOUCHED(vm_fecha_desde, vm_fecha_hasta, 
				     vm_proveedor)
		   THEN
			EXIT PROGRAM
		END IF
		LET INT_FLAG = 1 
		RETURN

        ON KEY(F1,CONTROL-W)
		CALL llamar_visor_teclas()

	ON KEY(F2)
		IF INFIELD(vm_proveedor) THEN
			CALL fl_ayuda_proveedores_localidad(vg_codcia,vg_codloc)
				RETURNING r_p01.p01_codprov, 
					  r_p01.p01_nomprov
			IF r_p01.p01_codprov IS NOT NULL THEN
				LET vm_proveedor = r_p01.p01_codprov
				DISPLAY BY NAME vm_proveedor
				DISPLAY r_p01.p01_nomprov TO nom_proveedor
			END IF
		END IF
		LET INT_FLAG = 0

	BEFORE INPUT
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")

	BEFORE FIELD vm_fecha_desde 
		LET fec_ini = vm_fecha_desde 
	BEFORE FIELD vm_fecha_hasta 
		LET fec_fin = vm_fecha_hasta 
	AFTER FIELD vm_fecha_hasta 
		IF vm_fecha_hasta IS NOT NULL THEN
			IF vm_fecha_hasta < vm_fecha_desde THEN
				CALL fl_mostrar_mensaje('La fecha final no debe ser mayor a la de fecha de inicio.','exclamation')
				NEXT FIELD vm_fecha_hasta
			END IF
			IF vm_fecha_hasta > vg_fecha THEN
				CALL fl_mostrar_mensaje('La fecha final no puede ser mayor a la de hoy.','exclamation')
				NEXT FIELD vm_fecha_hasta
			END IF
			IF vm_fecha_desde < '01-01-1900' THEN
				CALL fl_mostrar_mensaje('Debe ingresa fechas mayores a las del año 1900.','exclamation')
				NEXT FIELD vm_fecha_hasta
			END IF
		ELSE
			LET vm_fecha_hasta = fec_fin
			DISPLAY BY NAME vm_fecha_hasta
		END IF

	AFTER FIELD vm_fecha_desde 
		IF vm_fecha_desde IS NOT NULL THEN
			IF vm_fecha_desde > vm_fecha_hasta THEN
				CALL fl_mostrar_mensaje('La fecha de inicio debe ser menor a la fecha final.','exclamation')
				NEXT FIELD vm_fecha_desde
			END IF
			IF vm_fecha_hasta < '01-01-1900' THEN
				CALL fl_mostrar_mensaje('Debe ingresa fechas mayores a las del año 1889.','exclamation')
				NEXT FIELD vm_fecha_desde
			END IF
		ELSE
			LET vm_fecha_desde = fec_ini
			DISPLAY BY NAME vm_fecha_desde
		END IF

	BEFORE FIELD vm_proveedor
		IF num_args() = 5 THEN
			LET vm_proveedor = vg_proveedor
			CALL fl_lee_proveedor(vm_proveedor)
				RETURNING r_p01.*
			DISPLAY BY NAME vm_proveedor
			DISPLAY r_p01.p01_nomprov TO nom_proveedor
			NEXT FIELD NEXT
		END IF
	
	AFTER FIELD vm_proveedor
		IF vm_proveedor IS NOT NULL THEN
			CALL fl_lee_proveedor(vm_proveedor)
				RETURNING r_p01.*
			IF r_p01.p01_codprov IS NULL THEN
				CALL fl_mostrar_mensaje('No existe el proveedor en la Compañía.','exclamation')
				CLEAR nom_proveedor
				NEXT FIELD vm_proveedor
			END IF
			DISPLAY r_p01.p01_nomprov TO nom_proveedor
		ELSE	
			CLEAR nom_proveedor
		END IF

	AFTER INPUT
		IF vm_fecha_desde IS NULL AND vm_fecha_hasta IS NOT NULL THEN
			CALL fl_mostrar_mensaje('Debe ingresar la fecha de inicio.','exclamation') 
			NEXT FIELD vm_fecha_desde
		END IF
		IF vm_fecha_hasta IS NULL AND vm_fecha_desde IS NOT NULL THEN
			CALL fl_mostrar_mensaje('Debe ingresar la fecha de inicio.','exclamation') 
			NEXT FIELD vm_fecha_hasta
		END IF

END INPUT

END FUNCTION



FUNCTION control_consulta()
DEFINE query         	CHAR(800)
DEFINE i		SMALLINT
DEFINE r_p01		RECORD LIKE cxpt001.*
DEFINE r_p27		RECORD LIKE cxpt027.*
DEFINE r_p28		RECORD LIKE cxpt028.*
DEFINE r_p29		RECORD LIKE cxpt029.*
DEFINE expr_fecha	VARCHAR(150)
DEFINE expr_prov	VARCHAR(50)

INITIALIZE query TO NULL
LET expr_fecha      = ' 1 = 1 '
LET expr_prov       = ' 1 = 1 '

IF vm_fecha_desde IS NOT NULL THEN 
	LET expr_fecha = ' DATE(p27_fecing) BETWEEN "', vm_fecha_desde,'"',
			 ' AND "', vm_fecha_hasta,'"'
END IF
IF vm_proveedor IS NOT NULL THEN 
	LET expr_prov = ' p27_codprov = ',vm_proveedor	
END IF

LET query = 'SELECT cxpt027.*, p29_num_sri, cxpt001.* ',
		' FROM cxpt027, cxpt029, cxpt001',
		' WHERE p27_compania   = ', vg_codcia ,
		'   AND p27_localidad  = ', vg_codloc ,
		'   AND ', expr_prov CLIPPED ,
		'   AND ', expr_fecha CLIPPED , 
		'   AND p29_compania   = p27_compania ',
		'   AND p29_localidad  = p27_localidad ',
		'   AND p29_num_ret    = p27_num_ret ',
		'   AND p27_codprov    = p01_codprov'
		
PREPARE consulta FROM query

DECLARE q_consulta CURSOR FOR consulta

LET i = 1
FOREACH q_consulta INTO r_p27.*, r_p29.p29_num_sri, r_p01.*

	LET r_detalle[i].fecha         = DATE(r_p27.p27_fecing)
	LET r_detalle[i].proveedor     = r_p01.p01_nomprov
	LET r_detalle[i].num_ret_sri   = r_p29.p29_num_sri
	LET r_detalle[i].num_ret       = r_p27.p27_num_ret
	LET r_detalle[i].p27_total_ret = r_p27.p27_total_ret
	LET r_detalle[i].p27_estado    = r_p27.p27_estado

	LET r_detalle_1[i].codprov     = r_p01.p01_codprov

	INSERT INTO tmp_consulta VALUES(r_detalle[i].*,r_detalle_1[i].*)
		
	LET i = i + 1
	IF i > vm_max_det THEN
		EXIT FOREACH
	END IF

END FOREACH

LET vm_num_det = i - 1

END FUNCTION



FUNCTION control_DISPLAY_array()
DEFINE query 		CHAR(300)
DEFINE i,j,m,col 	SMALLINT

FOR i = 1 TO 10
	LET rm_orden[i] = '' 
END FOR
LET rm_orden[1]  = 'ASC'
LET vm_columna_1 = 1
LET vm_columna_2 = 2
LET col          = 1
WHILE TRUE

	LET query = 'SELECT * FROM tmp_consulta ',
			' ORDER BY ', vm_columna_1, ' ', rm_orden[vm_columna_1],
			        ', ', vm_columna_2, ' ', rm_orden[vm_columna_2]
	PREPARE consulta_2 FROM query
	DECLARE q_consulta_2 CURSOR FOR consulta_2

	LET m = 1
	FOREACH q_consulta_2 INTO r_detalle[m].*, r_detalle_1[m].*
		LET m = m + 1
		IF m > vm_max_det THEN
			EXIT FOREACH
		END IF
	END FOREACH

	CALL set_count(vm_num_det)
	LET int_flag = 0
	DISPLAY ARRAY r_detalle TO r_detalle.*

		--#BEFORE DISPLAY
			--#CALL dialog.keysetlabel('ACCEPT','')
			--#CALL dialog.keysetlabel("F1","")
			--#CALL dialog.keysetlabel("CONTROL-W","")

		--#BEFORE ROW
			--#LET i = arr_curr()
			--#LET j = scr_line()
			--#CALL muestra_contadores_det(i, vm_num_det)

		--#AFTER DISPLAY 
			--#CONTINUE DISPLAY

		ON KEY(INTERRUPT)
			LET INT_FLAG = 1
			EXIT DISPLAY

        	ON KEY(F1,CONTROL-W)
			CALL control_visor_teclas_caracter_1() 

		ON KEY(F5)
			LET i = arr_curr()
			LET j = scr_line()
			CALL control_ver_retencion(r_detalle_1[i].codprov,
						   r_detalle[i].num_ret)
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

END WHILE

END FUNCTION



FUNCTION control_ver_retencion(codprov, numret)
DEFINE codprov		LIKE cxpt001.p01_codprov
DEFINE numret		LIKE cxpt027.p27_num_ret
DEFINE r_p01		RECORD LIKE cxpt001.*
DEFINE r_p28		RECORD LIKE cxpt028.*
DEFINE r_p29		RECORD LIKE cxpt029.*
DEFINE r_g00		RECORD LIKE gent000.*
DEFINE num_det 		SMALLINT
DEFINE query 		CHAR(400)
DEFINE i,j,m,col 	SMALLINT
DEFINE lin_menu		SMALLINT
DEFINE row_ini  	SMALLINT
DEFINE col_ini  	SMALLINT
DEFINE num_rows 	SMALLINT
DEFINE num_cols 	SMALLINT

LET lin_menu = 0
LET row_ini  = 4
LET col_ini  = 3
LET num_rows = 19
LET num_cols = 76
IF vg_gui = 0 THEN
	LET lin_menu = 1
	LET row_ini  = 5
	LET col_ini  = 4
	LET num_rows = 18
	LET num_cols = 75
END IF
OPEN WINDOW w_cxpp304_2 AT row_ini, col_ini WITH num_rows ROWS, num_cols COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE lin_menu,
		  BORDER, MESSAGE LINE LAST - 1) 
IF vg_gui = 1 THEN
	OPEN FORM f_cxpp304_2 FROM "../forms/cxpf304_2"
ELSE
	OPEN FORM f_cxpp304_2 FROM "../forms/cxpf304_2c"
END IF
DISPLAY FORM f_cxpp304_2

CLEAR FORM
CALL control_DISPLAY_botones_2()

DECLARE q_cxpt028 CURSOR FOR 
	SELECT * FROM cxpt028 
		WHERE p28_compania  = vg_codcia
		  AND p28_localidad = vg_codloc  
		  AND p28_num_ret   = numret  

LET m = 1

DELETE FROM tmp_consulta_2

LET tot_base = 0
LET tot_ret  = 0

FOREACH q_cxpt028 INTO r_p28.*
	LET r_detalle_2[m].p28_tipo_doc   = r_p28.p28_tipo_doc
	LET r_detalle_2[m].p28_num_doc    = r_p28.p28_num_doc
	LET r_detalle_2[m].p28_porcentaje = r_p28.p28_porcentaje
	LET r_detalle_2[m].p28_valor_base = r_p28.p28_valor_base
	LET r_detalle_2[m].p28_valor_ret  = r_p28.p28_valor_ret

	LET tot_base = tot_base + r_detalle_2[m].p28_valor_base
	LET tot_ret  = tot_ret  + r_detalle_2[m].p28_valor_ret

	CASE r_p28.p28_tipo_ret
		WHEN 'F'
			LET r_detalle_2[m].tipo_ret = 'FUENTE'
		WHEN 'I'
			LET r_detalle_2[m].tipo_ret = rg_gen.g00_label_impto
	END CASE

	INSERT INTO tmp_consulta_2 VALUES(r_detalle_2[m].*)

	LET m = m + 1
	IF m > vm_max_det THEN
		EXIT FOREACH
	END IF
END FOREACH

LET num_det = m - 1

IF num_det = 0 THEN
	CALL fl_mostrar_mensaje('No existen detalle de retenciones para esta retención.','exclamation')
	CLOSE WINDOW w_cxpp304_2
	RETURN
END IF

CALL fl_lee_proveedor(codprov)
	RETURNING r_p01.*
CALL fl_lee_retencion_cxp(vg_codcia, vg_codloc, numret)
	RETURNING rm_p27.*
DISPLAY rm_p27.p27_num_ret TO vm_numret
DISPLAY r_p01.p01_nomprov  TO vm_nomprov
DISPLAY rm_p27.p27_estado  TO vm_estado
CALL mostrar_etiqueta_estado()
INITIALIZE r_p29.* TO NULL
DECLARE q_cxpt029 CURSOR FOR 
	SELECT * FROM cxpt029 
		WHERE p29_compania  = vg_codcia
		  AND p29_localidad = vg_codloc  
		  AND p29_num_ret   = numret  
OPEN q_cxpt029
FETCH q_cxpt029 INTO r_p29.*
DISPLAY BY NAME rm_p27.p27_fecing, tot_base, tot_ret, r_p29.p29_num_sri
FOR i = 1 TO 10
	LET rm_orden[i] = '' 
END FOR
LET rm_orden[1]  = 'ASC'
LET vm_columna_1 = 1
LET vm_columna_2 = 2
LET col          = 1
WHILE TRUE

	LET query = 'SELECT * FROM tmp_consulta_2 ',
			' ORDER BY ', vm_columna_1, ' ', rm_orden[vm_columna_1],
			        ', ', vm_columna_2, ' ', rm_orden[vm_columna_2]
	PREPARE consulta_3 FROM query
	DECLARE q_consulta_3 CURSOR FOR consulta_3

	LET m = 1
	FOREACH q_consulta_3 INTO r_detalle_2[m].*
		LET m = m + 1
		IF m > vm_max_det THEN
			EXIT FOREACH
		END IF
	END FOREACH

	CALL set_count(num_det)
	LET INT_FLAG = 0
	DISPLAY ARRAY r_detalle_2 TO r_detalle_2.*

		--#BEFORE DISPLAY
			--#CALL dialog.keysetlabel('ACCEPT','')
			--#CALL dialog.keysetlabel("F1","")
			--#CALL dialog.keysetlabel("CONTROL-W","")
			--#IF num_args() = 4 THEN
				--#CALL dialog.keysetlabel("F6","Eliminar")
			--#ELSE
				--#CALL dialog.keysetlabel("F6","")
			--#END IF

		--#BEFORE ROW
			--#LET i = arr_curr()
			--#LET j = scr_line()
			--#CALL muestra_contadores_det(i, num_det)

		--#AFTER DISPLAY 
			--#CONTINUE DISPLAY

		ON KEY(INTERRUPT)
			LET INT_FLAG = 1
			EXIT DISPLAY

        	ON KEY(F1,CONTROL-W)
			CALL control_visor_teclas_caracter_2() 

		ON KEY(F5)
			CALL imprimir_retenciones(numret)
			LET int_flag = 0

		ON KEY(F6)
			IF num_args() = 4 THEN
				IF NOT control_eliminar(rm_p27.p27_compania,
				        rm_p27.p27_localidad,rm_p27.p27_num_ret)
				THEN
					--#CONTINUE DISPLAY
				END IF
				CALL mostrar_etiqueta_estado()
				CALL fl_mostrar_mensaje('Registro Eliminado OK.', 'info')
				LET int_flag = 0
			END IF

		ON KEY(F7)
			CALL ver_contabilizacion()
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

		ON KEY(F20)
			LET col = 6
			EXIT DISPLAY

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

END WHILE

CLOSE WINDOW w_cxpp304_2

END FUNCTION



FUNCTION mostrar_etiqueta_estado()

DISPLAY rm_p27.p27_estado TO vm_estado
CASE rm_p27.p27_estado 
	WHEN 'A'
		DISPLAY 'ACTIVA'    TO tit_estado
	WHEN 'E'
		DISPLAY 'ELIMINADA' TO tit_estado
END CASE

END FUNCTION



FUNCTION muestra_contadores_det(num_rows, max_rows)
DEFINE num_rows		SMALLINT
DEFINE max_rows		SMALLINT

DISPLAY BY NAME num_rows, max_rows

END FUNCTION



FUNCTION imprimir_retenciones(num_ret)
DEFINE num_ret		LIKE cxpt027.p27_num_ret
DEFINE comando		VARCHAR(255)
DEFINE run_prog		CHAR(10)

LET run_prog = '; fglrun '
IF vg_gui = 0 THEN
	LET run_prog = '; fglgo '
END IF
LET comando = 'cd ..' || vg_separador || '..' || vg_separador || 
	      'TESORERIA' || vg_separador || 'fuentes' || vg_separador ||
	      run_prog || 'cxpp405 ' || vg_base || ' TE ' || 
	      vg_codcia || ' ' || vg_codloc || ' ' || num_ret

RUN comando

END FUNCTION


FUNCTION control_eliminar(codcia, codloc, num_ret)
DEFINE codcia		LIKE cxpt027.p27_compania
DEFINE codloc		LIKE cxpt027.p27_localidad
DEFINE num_ret		LIKE cxpt027.p27_num_ret
DEFINE r_b00		RECORD LIKE ctbt000.*
DEFINE r_b12		RECORD LIKE ctbt012.*
DEFINE r_p20		RECORD LIKE cxpt020.*
DEFINE r_p22		RECORD LIKE cxpt022.*
DEFINE r_p23		RECORD LIKE cxpt023.*
DEFINE r_p28		RECORD LIKE cxpt028.*
DEFINE mensaje		VARCHAR(200)
DEFINE resp		CHAR(6)

DEFINE fecha_actual DATETIME YEAR TO SECOND

BEGIN WORK
WHENEVER ERROR CONTINUE
DECLARE q_lret CURSOR FOR 
	SELECT * FROM cxpt027
		WHERE p27_compania  = codcia AND 
		      p27_localidad = codloc AND 
    	              p27_num_ret   = num_ret
	FOR UPDATE
OPEN q_lret 
FETCH q_lret INTO rm_p27.*
IF status = NOTFOUND THEN
	WHENEVER ERROR STOP
	ROLLBACK WORK
	CALL fl_mostrar_mensaje('Retención no existe.','stop')
	RETURN 0
END IF
IF status < 0 THEN
	WHENEVER ERROR STOP
	ROLLBACK WORK
	CALL fl_mensaje_bloqueo_otro_usuario()
	RETURN 0
END IF
IF rm_p27.p27_estado = 'E' THEN
	WHENEVER ERROR STOP
	ROLLBACK WORK
	CALL fl_mostrar_mensaje('Retención ya esta eliminada.','stop')
	RETURN 0
END IF
IF rm_p27.p27_tip_contable = 'EG' THEN
	WHENEVER ERROR STOP
	ROLLBACK WORK
	LET mensaje = 'LAS RETENCIONES GENERADAS AUTOMATICAMENTE VIA ORDENES ',
		      'DE PAGO A PROVEEDORES NO PUEDEN SER ELIMINADAS DESDE ',
		      'ESTE PROCESO. HAGALO ELIMINANDO EL COMPROBANTE ',
		      'CONTABLE RESPECTIVO.'
	CALL fl_mostrar_mensaje(mensaje, 'stop')
	RETURN 0
END IF
CALL fl_hacer_pregunta('Seguro de eliminar esta retención','No')
	RETURNING resp 
IF resp <> 'Yes' THEN
	ROLLBACK WORK
	RETURN 0
END IF
WHENEVER ERROR STOP
INITIALIZE r_p22.* TO NULL
LET r_p22.p22_compania   = rm_p27.p27_compania 
LET r_p22.p22_localidad  = rm_p27.p27_localidad
LET r_p22.p22_codprov    = rm_p27.p27_codprov
LET r_p22.p22_tipo_trn   = 'AJ'    
LET r_p22.p22_num_trn    = fl_actualiza_control_secuencias(rm_p27.p27_compania,
				rm_p27.p27_localidad, 'TE', 'AA', 'AJ')
LET r_p22.p22_referencia = 'ELIM. RETENCION: ', rm_p27.p27_num_ret
			    USING '<<<<<&'
LET r_p22.p22_fecha_emi  = vg_fecha
LET r_p22.p22_moneda     = rm_p27.p27_moneda 
LET r_p22.p22_paridad    = rm_p27.p27_paridad
LET r_p22.p22_tasa_mora  = 0
LET r_p22.p22_total_cap  = 0    
LET r_p22.p22_total_int  = 0  
LET r_p22.p22_total_mora = 0 
LET r_p22.p22_origen     = 'A' 
LET r_p22.p22_usuario    = vg_usuario    
LET r_p22.p22_fecing     = fl_current()
INSERT INTO cxpt022 VALUES(r_p22.*)
DECLARE q_dret CURSOR FOR 
	SELECT * FROM cxpt028
                WHERE p28_compania   = rm_p27.p27_compania
                  AND p28_localidad  = rm_p27.p27_localidad
                  AND p28_num_ret    = rm_p27.p27_num_ret
                ORDER BY p28_secuencia
FOREACH q_dret INTO r_p28.*
	LET r_p22.p22_total_cap = r_p22.p22_total_cap + r_p28.p28_valor_ret
	CALL fl_lee_documento_deudor_cxp(r_p28.p28_compania, 
					 r_p28.p28_localidad,
					 r_p28.p28_codprov,
					 r_p28.p28_tipo_doc, 
					 r_p28.p28_num_doc,
					 r_p28.p28_dividendo) RETURNING r_p20.*
	INITIALIZE r_p23.* TO NULL
	LET r_p23.p23_compania   = r_p22.p22_compania  
	LET r_p23.p23_localidad  = r_p22.p22_localidad     
	LET r_p23.p23_codprov    = r_p22.p22_codprov     
	LET r_p23.p23_tipo_trn   = r_p22.p22_tipo_trn    
	LET r_p23.p23_num_trn    = r_p22.p22_num_trn   
	LET r_p23.p23_orden      = r_p28.p28_secuencia
	LET r_p23.p23_tipo_doc   = r_p28.p28_tipo_doc
	LET r_p23.p23_num_doc    = r_p28.p28_num_doc
	LET r_p23.p23_div_doc    = r_p28.p28_dividendo
	LET r_p23.p23_valor_cap  = r_p28.p28_valor_ret
	LET r_p23.p23_valor_int  = 0
	LET r_p23.p23_valor_mora = 0 
	LET r_p23.p23_saldo_cap  = r_p20.p20_saldo_cap 
	LET r_p23.p23_saldo_int  = r_p20.p20_saldo_int
	INSERT INTO cxpt023 VALUES (r_p23.*)
	SET LOCK MODE TO NOT WAIT
	UPDATE cxpt020 SET p20_saldo_cap = p20_saldo_cap + r_p28.p28_valor_ret
		WHERE p20_compania  = r_p28.p28_compania
		  AND p20_localidad = r_p28.p28_localidad
		  AND p20_codprov   = r_p28.p28_codprov
		  AND p20_tipo_doc  = r_p28.p28_tipo_doc
		  AND p20_num_doc   = r_p28.p28_num_doc
		  AND p20_dividendo = r_p28.p28_dividendo
END FOREACH
UPDATE cxpt022 SET * = r_p22.* 
	WHERE p22_compania  = r_p22.p22_compania
	  AND p22_localidad = r_p22.p22_localidad
	  AND p22_codprov   = r_p22.p22_codprov
	  AND p22_tipo_trn  = r_p22.p22_tipo_trn
	  AND p22_num_trn   = r_p22.p22_num_trn
CALL fl_genera_saldos_proveedor(vg_codcia, vg_codloc, rm_p27.p27_codprov)
LET rm_p27.p27_estado    = 'E'
LET rm_p27.p27_fecha_eli = fl_current()
UPDATE cxpt027 SET p27_estado    = rm_p27.p27_estado,
		   p27_fecha_eli = rm_p27.p27_fecha_eli
	WHERE CURRENT OF q_lret
IF rm_p27.p27_tip_contable IS NOT NULL THEN
	CALL fl_lee_compania_contabilidad(codcia) RETURNING r_b00.*
	CALL fl_lee_comprobante_contable(codcia, rm_p27.p27_tip_contable, 	
				rm_p27.p27_num_contable)
		RETURNING r_b12.*
	IF (YEAR(r_b00.b00_fecha_cm) = YEAR(r_b12.b12_fec_proceso) AND
	   MONTH(r_b00.b00_fecha_cm) >= MONTH(r_b12.b12_fec_proceso)) OR
	    YEAR(r_b00.b00_fecha_cm) > YEAR(r_b12.b12_fec_proceso) THEN
		COMMIT WORK
		RETURN 1
	ELSE	
		LET fecha_actual = fl_current()
		IF r_b12.b12_estado = 'M' THEN
			COMMIT WORK
			CALL fl_mayoriza_comprobante(vg_codcia, 
				r_b12.b12_tipo_comp, r_b12.b12_num_comp, 'D')
			BEGIN WORK
			UPDATE ctbt012 SET b12_estado = 'E',
		   		           b12_fec_modifi = fecha_actual
	 	            WHERE b12_compania  = rm_p27.p27_compania     AND
	 		          b12_tipo_comp = rm_p27.p27_tip_contable AND
	 		          b12_num_comp  = rm_p27.p27_num_contable
			COMMIT WORK
			RETURN 1
		END IF
		IF r_b12.b12_estado <> 'E' THEN
			UPDATE ctbt012 SET b12_estado = 'E',
		   		           b12_fec_modifi = fecha_actual
	 	            WHERE b12_compania  = rm_p27.p27_compania     AND
	 		          b12_tipo_comp = rm_p27.p27_tip_contable AND
	 		          b12_num_comp  = rm_p27.p27_num_contable
		END IF
	END IF
END IF
COMMIT WORK
RETURN 1

END FUNCTION	



FUNCTION ver_contabilizacion()
DEFINE comando		VARCHAR(255)
DEFINE run_prog		VARCHAR(10)

IF rm_p27.p27_tip_contable IS NULL THEN
	RETURN
END IF
LET run_prog = '; fglrun '
IF vg_gui = 0 THEN
	LET run_prog = '; fglgo '
END IF
LET comando = 'cd ..', vg_separador, '..', vg_separador, 'CONTABILIDAD',
	vg_separador, 'fuentes', run_prog, ' ctbp201 ', vg_base,
	' CB ',vg_codcia, ' ', 
        rm_p27.p27_tip_contable, ' ', rm_p27.p27_num_contable
RUN comando

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
DISPLAY '<F5>      Documento'                AT a,2
DISPLAY  'F5' AT a,3 ATTRIBUTE(REVERSE)
LET a = fgl_getkey()
CLOSE WINDOW w_tf

END FUNCTION



FUNCTION control_visor_teclas_caracter_2() 
DEFINE a, fila		INTEGER

CALL fl_visor_teclas_caracter() RETURNING fila
LET a = fila + 2
DISPLAY 'Teclas exclusivas de este proceso:' AT a,2 ATTRIBUTE(REVERSE)	
LET a = a + 1
DISPLAY '<F5>      Imprimir Retención'       AT a,2
DISPLAY  'F5' AT a,3 ATTRIBUTE(REVERSE)
LET a = a + 1
DISPLAY '<F6>      Eliminar Retención'       AT a,2
DISPLAY  'F6' AT a,3 ATTRIBUTE(REVERSE)
LET a = a + 1
DISPLAY '<F7>      Contabilización'          AT a,2
DISPLAY  'F7' AT a,3 ATTRIBUTE(REVERSE)
LET a = fgl_getkey()
CLOSE WINDOW w_tf

END FUNCTION
