------------------------------------------------------------------------------
-- Titulo           : vehp305.4gl - Consulta de modelos de vehículos
-- Elaboracion      : 04-div-2001
-- Autor            : NPC
-- Formato Ejecucion: fglrun vehp305 base módulo compañía localidad [modelo]
-- Ultima Correccion: 
-- Motivo Correccion: 
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_demonios	VARCHAR(12)
DEFINE vm_nuevoprog     VARCHAR(400)
DEFINE vm_max_det       SMALLINT
DEFINE vm_max_ped       SMALLINT
DEFINE vm_num_det       SMALLINT
DEFINE vm_num_ped       SMALLINT
DEFINE vm_scr_lin       SMALLINT
DEFINE vm_flag_ped      SMALLINT
DEFINE vm_total_sto	DECIMAL(6,0)
DEFINE vm_total_ped	DECIMAL(6,0)
DEFINE rm_orden 	ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1	SMALLINT
DEFINE vm_columna_2	SMALLINT
DEFINE vm_moneda	ARRAY [1000] OF LIKE gent013.g13_nombre
DEFINE rm_det		ARRAY [1000] OF RECORD
				v04_nombre	LIKE veht004.v04_nombre,
				v20_modelo	LIKE veht020.v20_modelo,
				v20_moneda	LIKE veht020.v20_moneda,
				v20_precio	LIKE veht020.v20_precio,
				v20_stock	LIKE veht020.v20_stock,
				v20_pedidos	LIKE veht020.v20_pedidos
			END RECORD
DEFINE rm_ped		ARRAY [200] OF RECORD
				v34_pedido	LIKE veht034.v34_pedido,
				p01_nomprov	LIKE cxpt001.p01_nomprov,
				v34_fec_llegada	LIKE veht034.v34_fec_llegada,
				v05_descri_base	LIKE veht005.v05_descri_base
			END RECORD

MAIN

DEFER QUIT 
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/errores')
CALL fgl_init4js()
CALL fl_marca_registrada_producto()
         -- Validar # parámetros correcto
IF num_args() <> 4 AND num_args() <> 5 AND num_args() <> 6 THEN
	CALL fgl_winmessage(vg_producto, 'Número de parámetros incorrecto', 'stop')
	EXIT PROGRAM
END IF
LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_codcia   = arg_val(3)
LET vg_codloc   = arg_val(4)
LET vg_proceso = 'vehp305'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()

END MAIN



FUNCTION funcion_master()

CALL fl_nivel_isolation()
LET vm_max_det = 1000
LET vm_max_ped = 200
IF num_args() = 6 THEN
	IF arg_val(6) <> 'P' THEN
		CALL fgl_winmessage(vg_producto,'Parámetro para pedido incorrecto.','stop')
		EXIT PROGRAM
	END IF
	LET rm_det[1].v20_modelo = arg_val(5)
	CALL control_pedidos(1)
	EXIT PROGRAM
END IF
OPEN WINDOW w_mas AT 3,2 WITH 22 ROWS, 80 COLUMNS
    ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE 0,BORDER,
	      MESSAGE LINE LAST - 2)
OPTIONS INPUT WRAP,
	ACCEPT KEY	F12
OPEN FORM f_veh FROM "../forms/vehf305_1"
DISPLAY FORM f_veh
CLEAR FORM
LET vm_scr_lin = 0
CALL borrar_detalle()
CALL muestra_contadores_det(0)
CALL mostrar_cabecera_forma()
CALL control_consulta()

END FUNCTION



FUNCTION control_consulta()
DEFINE i,j,l,col	SMALLINT
DEFINE query		VARCHAR(400)
DEFINE expr_sql		VARCHAR(100)

FOR i = 1 TO vm_max_det
	INITIALIZE rm_det[i].*, vm_moneda[i].* TO NULL
END FOR
INITIALIZE expr_sql TO NULL
IF num_args() = 5 THEN
	LET expr_sql = '  AND v20_modelo LIKE "', arg_val(5), '"'
END IF
LET vm_num_det = 0
LET int_flag   = 0
FOR i = 1 TO 10
	LET rm_orden[i] = '' 
END FOR
LET rm_orden[1]  = 'ASC'
LET vm_columna_1 = 1
LET vm_columna_2 = 2
LET col          = 1
WHILE TRUE
	LET query = 'SELECT v04_nombre, v20_modelo, v20_moneda, v20_precio, ',
			'v20_stock, v20_pedidos, g13_nombre ',
			'FROM veht020, veht004, gent013 ',
				'WHERE v20_compania  = ', vg_codcia,
				expr_sql CLIPPED,
				'  AND v20_compania  = v04_compania ',
				'  AND v20_tipo_veh  = v04_tipo_veh ',
				'  AND v20_moneda    = g13_moneda ',
			" ORDER BY ", vm_columna_1, ' ', rm_orden[vm_columna_1],
			        ', ', vm_columna_2, ' ', rm_orden[vm_columna_2]
	PREPARE deto FROM query
	DECLARE q_deto CURSOR FOR deto
	LET vm_num_det = 1
	FOREACH q_deto INTO rm_det[vm_num_det].*, vm_moneda[vm_num_det]
		LET vm_num_det = vm_num_det + 1
		IF vm_num_det > vm_max_det THEN
			EXIT FOREACH
		END IF
	END FOREACH
	LET vm_num_det = vm_num_det - 1
	IF vm_num_det = 0 THEN
		CALL fl_mensaje_consulta_sin_registros()
		RETURN
	END IF
	CALL sacar_total()
	CALL set_count(vm_num_det)
	LET int_flag = 0
	DISPLAY ARRAY rm_det TO rm_det.*
		BEFORE DISPLAY
			CALL dialog.keysetlabel('ACCEPT','')
		BEFORE ROW
			LET j = arr_curr()
			LET l = scr_line()
			CALL muestra_contadores_det(j)
			DISPLAY vm_moneda[j] TO tit_moneda
			IF rm_det[j].v20_pedidos = 0 THEN
				CALL dialog.keysetlabel('F7','')
			ELSE
				CALL dialog.keysetlabel('F7','Pedidos')
			END IF
		AFTER DISPLAY 
			CONTINUE DISPLAY
		ON KEY(INTERRUPT)
			LET int_flag = 1
			EXIT DISPLAY
		ON KEY(F5)
			CALL ver_modelos(j)
			LET int_flag = 0
		ON KEY(F6)
			CALL ver_vehiculos(j)
			LET int_flag = 0
		ON KEY(F7)
			IF rm_det[j].v20_pedidos > 0 THEN
				CALL control_pedidos(j)
				LET int_flag = 0
			END IF
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


 
FUNCTION control_pedidos(i)
DEFINE i		SMALLINT

OPEN WINDOW w_for AT 04, 02
        WITH FORM '../forms/vehf305_2'
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MESSAGE LINE LAST,
                   MENU LINE 0, BORDER)
CALL mostrar_botones_pedidos()
CALL cargar_pedido(i)
IF NOT vm_flag_ped THEN
	CALL mostrar_pedido()
END IF

END FUNCTION
 


FUNCTION cargar_pedido(i)
DEFINE i,j		SMALLINT

LET vm_flag_ped = 0
FOR j = 1 TO vm_max_ped
	INITIALIZE rm_ped[j].* TO NULL
END FOR
LET vm_num_ped = 0
LET int_flag   = 0
SELECT v34_pedido, p01_nomprov, v34_fec_llegada, v05_descri_base
	FROM veht035, veht005, veht034, cxpt001
	WHERE v35_compania  = vg_codcia
	  AND v35_localidad = vg_codloc
	  AND v35_modelo    = rm_det[i].v20_modelo
	  AND v35_estado    <> "P"
	  AND v35_compania  = v05_compania
	  AND v35_cod_color = v05_cod_color
	  AND v35_compania  = v34_compania
	  AND v35_localidad = v34_localidad
	  AND v35_pedido    = v34_pedido
	  AND v34_proveedor = p01_codprov
	INTO TEMP tmp_detalle_ped
SELECT COUNT(*) INTO vm_num_ped FROM tmp_detalle_ped
IF vm_num_ped = 0 THEN
	DROP TABLE tmp_detalle_ped
	CALL fl_mensaje_consulta_sin_registros()
	LET vm_flag_ped = 1
	RETURN
END IF

END FUNCTION



FUNCTION mostrar_pedido()
DEFINE i,j,l,col	SMALLINT
DEFINE query		VARCHAR(400)

FOR i = 1 TO 10
	LET rm_orden[i] = '' 
END FOR
LET rm_orden[1]  = 'ASC'
LET vm_columna_1 = 1
LET vm_columna_2 = 2
LET col          = 1
WHILE TRUE
	LET query = 'SELECT * FROM tmp_detalle_ped ',
			" ORDER BY ", vm_columna_1, ' ', rm_orden[vm_columna_1],
			        ', ', vm_columna_2, ' ', rm_orden[vm_columna_2]
	PREPARE deto2 FROM query
	DECLARE q_deto2 CURSOR FOR deto2
	LET i = 1
	FOREACH q_deto2 INTO rm_ped[i].*
		LET i = i + 1
		IF i > vm_max_ped THEN
			EXIT FOREACH
		END IF
	END FOREACH
	LET i = i - 1
	CALL set_count(i)
	LET int_flag = 0
	DISPLAY ARRAY rm_ped TO rm_ped.*
		BEFORE DISPLAY
			CALL dialog.keysetlabel('ACCEPT','')
		BEFORE ROW
			LET j = arr_curr()
			LET l = scr_line()
			CALL muestra_contadores_ped(j)
		AFTER DISPLAY 
			CONTINUE DISPLAY
		ON KEY(INTERRUPT)
			LET int_flag = 1
			EXIT DISPLAY
		ON KEY(F5)
			CALL ver_pedido(j)
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
DROP TABLE tmp_detalle_ped

END FUNCTION


 
FUNCTION sacar_total()
DEFINE i		SMALLINT

LET vm_total_sto = 0
LET vm_total_ped = 0
FOR i = 1 TO vm_num_det
	LET vm_total_sto = vm_total_sto + rm_det[i].v20_stock
	LET vm_total_ped = vm_total_ped + rm_det[i].v20_pedidos
END FOR
DISPLAY vm_total_sto TO tit_total_sto
DISPLAY vm_total_ped TO tit_total_ped

END FUNCTION



FUNCTION borrar_detalle()
DEFINE i  		SMALLINT

CALL muestra_contadores_det(0)
LET vm_scr_lin = fgl_scr_size('rm_det')
FOR i = 1 TO vm_scr_lin
        INITIALIZE rm_det[i].*, vm_moneda[i] TO NULL
        CLEAR rm_det[i].*
END FOR
CLEAR tit_total_sto, tit_total_ped, tit_moneda

END FUNCTION



FUNCTION muestra_contadores_det(cor)
DEFINE cor	           SMALLINT

DISPLAY "" AT 22, 4
DISPLAY cor, " de ", vm_num_det AT 22, 8

END FUNCTION



FUNCTION muestra_contadores_ped(cor)
DEFINE cor	           SMALLINT

DISPLAY "" AT 16, 4
DISPLAY cor, " de ", vm_num_ped AT 16, 8

END FUNCTION



FUNCTION ver_modelos(i)
DEFINE i		SMALLINT

LET vm_nuevoprog = 'cd ..', vg_separador, '..', vg_separador, 'VEHICULOS',
	vg_separador, 'fuentes', vg_separador, '; fglrun vehp107 ', vg_base,
	' ', vg_modulo, ' ', vg_codcia, ' ',
	'"', rm_det[i].v20_modelo CLIPPED, '"'
RUN vm_nuevoprog

END FUNCTION



FUNCTION ver_vehiculos(i)
DEFINE i		SMALLINT

LET vm_nuevoprog = 'cd ..', vg_separador, '..', vg_separador, 'VEHICULOS',
	vg_separador, 'fuentes', vg_separador, '; fglrun vehp306 ', vg_base,
	' ', vg_modulo, ' ', vg_codcia, ' ', vg_codloc, ' ', 
	'"', rm_det[i].v20_modelo CLIPPED, '"'
RUN vm_nuevoprog

END FUNCTION



FUNCTION ver_pedido(i)
DEFINE i		SMALLINT

LET vm_nuevoprog = 'cd ..', vg_separador, '..', vg_separador, 'VEHICULOS',
	vg_separador, 'fuentes', vg_separador, '; fglrun vehp210 ', vg_base,
	' ', vg_modulo, ' ', vg_codcia, ' ', vg_codloc, ' ', '"',
	rm_ped[i].v34_pedido CLIPPED, '"'
RUN vm_nuevoprog

END FUNCTION



FUNCTION mostrar_cabecera_forma()

DISPLAY 'Tipo Vehículo' TO tit_col1
DISPLAY 'Modelo'        TO tit_col2
DISPLAY 'Mo'            TO tit_col3
DISPLAY 'Precio'        TO tit_col4
DISPLAY 'Stock'         TO tit_col5
DISPLAY 'Pedido'        TO tit_col6

END FUNCTION



FUNCTION mostrar_botones_pedidos()

DISPLAY 'Pedido'    TO tit_col7
DISPLAY 'Proveedor' TO tit_col8
DISPLAY 'Fec. Lle.' TO tit_col9
DISPLAY 'Color'     TO tit_col10

END FUNCTION



FUNCTION validar_parametros()

CALL fl_lee_modulo(vg_modulo) RETURNING rg_mod.*
IF rg_mod.g50_modulo IS NULL THEN
	CALL fgl_winmessage(vg_producto, 'No existe módulo: ' || vg_modulo, 'stop')
	EXIT PROGRAM
END IF
CALL fl_lee_compania(vg_codcia) RETURNING rg_cia.*
IF rg_cia.g01_compania IS NULL THEn
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
