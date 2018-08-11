------------------------------------------------------------------------------
-- Titulo           : ordp300.4gl - Consulta de Ordenes de Compra
-- Elaboracion      : 10-dic-2001
-- Autor            : GVA
-- Formato Ejecucion: fglrun ordp300 base módulo compañía localidad
--                       [tipo_orden] [fecha_ini] [fecha_fin] [codprov]
-- Ultima Correccion: 1
-- Motivo Correccion: 1
------------------------------------------------------------------------------

GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE rm_c10		RECORD LIKE ordt010.*
DEFINE vm_max_det       SMALLINT
DEFINE vm_num_det       SMALLINT
DEFINE vm_scr_lin       SMALLINT
DEFINE vm_fecha_desde	DATE
DEFINE vm_fecha_hasta	DATE
DEFINE vm_total		DECIMAL(14,2)
DEFINE vm_numero_oc	LIKE ordt010.c10_numero_oc
DEFINE vm_proveedor	LIKE ordt010.c10_codprov
DEFINE vm_depto		LIKE ordt010.c10_cod_depto
DEFINE vm_tipo_orden	LIKE ordt010.c10_tipo_orden
DEFINE rm_orden 	ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1	SMALLINT
DEFINE vm_columna_2	SMALLINT
DEFINE r_detalle	ARRAY [1000] OF RECORD
				c10_numero_oc	LIKE ordt010.c10_numero_oc,
				c10_moneda	LIKE ordt010.c10_moneda,
				proveedor	LIKE cxpt001.p01_nomprov,
				fecha		DATE,
				c10_tot_compra	LIKE ordt010.c10_tot_compra
			END RECORD
DEFINE r_detalle_1	ARRAY [1000] OF RECORD
				codprov		LIKE ordt010.c10_codprov
			END RECORD



MAIN

DEFER QUIT 
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/ordp300.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()

IF num_args() <> 4 AND num_args() <> 8 THEN  -- Validar # parámetros correcto
	CALL fl_mostrar_mensaje('Número de parámetros incorrecto.','stop')
	EXIT PROGRAM
END IF

LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_codloc  = arg_val(4)
LET vg_proceso = 'ordp300'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
--#CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)

CALL funcion_master()

END MAIN



FUNCTION funcion_master()
DEFINE i 	SMALLINT
DEFINE lin_menu		SMALLINT
DEFINE row_ini  	SMALLINT
DEFINE num_rows 	SMALLINT
DEFINE num_cols 	SMALLINT

CALL fl_nivel_isolation()
CREATE TEMP TABLE tmp_consulta(
	numero_oc	INTEGER,
	moneda		CHAR(2),
	proveedor	VARCHAR(40),
	fecha		DATE,
	c10_tot_compra	DECIMAL(12,2),
	codprod		INTEGER)

LET vm_max_det  = 1000

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
OPEN WINDOW w_ordp300 AT row_ini, 2 WITH num_rows ROWS, num_cols COLUMNS
    ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE lin_menu,
		BORDER, MESSAGE LINE LAST)
IF vg_gui = 1 THEN
	OPEN FORM f_ordp300 FROM "../forms/ordf300_1"
ELSE
	OPEN FORM f_ordp300 FROM "../forms/ordf300_1c"
END IF
DISPLAY FORM f_ordp300

LET vm_num_det = 0

INITIALIZE rm_c10.*,     vm_fecha_desde, vm_numero_oc, vm_depto, 
	   vm_proveedor, vm_tipo_orden  TO NULL
WHILE TRUE
	IF vm_num_det = 0 THEN
		FOR i = 1 TO vm_max_det
			INITIALIZE r_detalle[i].* TO NULL
		END FOR
	ELSE
		FOR i = 1 TO vm_num_det
			INITIALIZE r_detalle[i].* TO NULL
		END FOR
	END IF
	CLEAR FORM 
	CALL control_DISPLAY_botones()
	--#DISPLAY "" AT 21, 4
	--#DISPLAY '0', ' de ', '0' AT 21, 4
	DELETE FROM tmp_consulta
	IF num_args() = 8 THEN
		LET vm_tipo_orden  = arg_val(5)
		IF vm_tipo_orden = 0 THEN
			LET vm_tipo_orden = NULL
		END IF
		LET vm_fecha_desde = arg_val(6)
		LET vm_fecha_hasta = arg_val(7)
		LET vm_proveedor   = arg_val(8)
		LET rm_c10.c10_estado = 'C'
		IF vg_gui = 0 THEN
			CALL muestra_estado(rm_c10.c10_estado)
		END IF
	END IF
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
		IF num_args() = 8 THEN
			EXIT PROGRAM
		END IF
		CONTINUE WHILE
	END IF
	CALL control_DISPLAY_array()
	DISPLAY BY NAME vm_tipo_orden, vm_proveedor, vm_depto
END WHILE

END FUNCTION



FUNCTION control_DISPLAY_botones()

--#DISPLAY 'No OC'     	TO tit_col1
--#DISPLAY 'Moneda'	TO tit_col2
--#DISPLAY 'Proveedor'	TO tit_col3
--#DISPLAY 'Fecha'     	TO tit_col4
--#DISPLAY 'Total OC'  	TO tit_col5

END FUNCTION



FUNCTION control_lee_cabecera()
DEFINE i,j,col		SMALLINT
DEFINE r_g34		RECORD LIKE gent034.*
DEFINE r_c10		RECORD LIKE ordt010.*
DEFINE r_c01		RECORD LIKE ordt001.*
DEFINE r_p01		RECORD LIKE cxpt001.*


IF vm_num_det = 0 AND num_args() <> 8 THEN
	LET rm_c10.c10_estado = 'P'
	LET vm_fecha_hasta    = vg_fecha
END IF
DISPLAY BY NAME rm_c10.c10_estado, vm_numero_oc, 
		vm_proveedor,      vm_depto,
		vm_tipo_orden, vm_fecha_desde, vm_fecha_hasta
IF vg_gui = 0 THEN
	CALL muestra_estado(rm_c10.c10_estado)
END IF
CALL fl_lee_proveedor(vm_proveedor)
	RETURNING r_p01.*
CALL fl_lee_departamento(vg_codcia, vm_depto)
	RETURNING r_g34.*
CALL fl_lee_tipo_orden_compra(vm_tipo_orden)
	RETURNING r_c01.*
DISPLAY r_p01.p01_nomprov TO nom_proveedor
DISPLAY r_g34.g34_nombre  TO nom_depto
DISPLAY r_c01.c01_nombre  TO nom_tipo

LET INT_FLAG   = 0
IF num_args() = 8 THEN
	RETURN
END IF
	INPUT BY NAME vm_numero_oc, rm_c10.c10_estado, vm_fecha_desde, 
		      vm_fecha_hasta, vm_proveedor, vm_depto,
		      vm_tipo_orden
		      WITHOUT DEFAULTS

	ON KEY(INTERRUPT)
		IF NOT FIELD_TOUCHED(vm_numero_oc,   vm_fecha_desde, 
				     vm_fecha_hasta, c10_estado, vm_proveedor,
				     vm_depto,       vm_tipo_orden)
		   THEN
			EXIT PROGRAM
		END IF
		LET INT_FLAG = 1 
		RETURN

        ON KEY(F1,CONTROL-W)
		CALL llamar_visor_teclas()

	ON KEY(F2)
		IF INFIELD(vm_numero_oc) THEN
			CALL fl_ayuda_ordenes_compra(vg_codcia, vg_codloc,
						     0, 0,rm_c10.c10_estado,
						     '00','T')
				RETURNING r_c10.c10_numero_oc
			IF r_c10.c10_numero_oc IS NOT NULL THEN
				LET vm_numero_oc      = r_c10.c10_numero_oc
				DISPLAY BY NAME vm_numero_oc 
			END IF
		END IF

		IF INFIELD(vm_depto) THEN
			CALL fl_ayuda_departamentos(vg_codcia)
			     	RETURNING r_g34.g34_cod_depto, 
					  r_g34.g34_nombre
			IF r_g34.g34_cod_depto IS NOT NULL THEN
			    	LET vm_depto = r_g34.g34_cod_depto
			    	DISPLAY BY NAME vm_depto
			        DISPLAY  r_g34.g34_nombre TO nom_depto
			END IF
		END IF

		IF INFIELD(vm_proveedor) THEN
			CALL fl_ayuda_proveedores()
				RETURNING r_p01.p01_codprov, 
					  r_p01.p01_nomprov
			IF r_p01.p01_codprov IS NOT NULL THEN
				LET vm_proveedor = r_p01.p01_codprov
				DISPLAY BY NAME vm_proveedor
				DISPLAY r_p01.p01_nomprov TO nom_proveedor
			END IF
		END IF

		IF INFIELD(vm_tipo_orden) THEN
			CALL fl_ayuda_tipos_ordenes_compras('T')
				RETURNING r_c01.c01_tipo_orden,
					  r_c01.c01_nombre
			IF r_c01.c01_tipo_orden IS NOT NULL THEN
				LET vm_tipo_orden = r_c01.c01_tipo_orden
				DISPLAY BY NAME vm_tipo_orden
				DISPLAY r_c01.c01_nombre TO nom_tipo
			END IF 
		END IF
		LET INT_FLAG = 0

	BEFORE INPUT
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
	AFTER FIELD vm_numero_oc
		IF vm_numero_oc IS NOT NULL THEN
			CALL fl_lee_orden_compra(vg_codcia, vg_codloc, 
						 vm_numero_oc)
				RETURNING r_c10.*
			IF r_c10.c10_numero_oc IS NULL THEN
				CALL fl_mostrar_mensaje('No existe la Orden de Compra en la Compañía.','exclamation')
			END IF
			LET rm_c10.c10_estado = r_c10.c10_estado
			IF vg_gui = 0 THEN
				CALL muestra_estado(rm_c10.c10_estado)
			END IF
		END IF

	AFTER FIELD c10_estado 
		IF vg_gui = 0 THEN
			IF rm_c10.c10_estado IS NOT NULL THEN
				CALL muestra_estado(rm_c10.c10_estado)
			ELSE
				CLEAR tit_estado
			END IF
		END IF
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

	AFTER FIELD vm_depto
		IF vm_depto IS NOT NULL THEN
			CALL fl_lee_departamento(vg_codcia, 
						 vm_depto)
				RETURNING r_g34.*
			IF r_g34.g34_cod_depto IS NULL THEN
				CALL fl_mostrar_mensaje('No existe el departamento en la Compañía.','exclamation')
				CLEAR nom_depto
				NEXT FIELD vm_depto
			END IF
			DISPLAY r_g34.g34_nombre TO nom_depto
		ELSE	
			CLEAR nom_depto
		END IF

	AFTER FIELD vm_tipo_orden
		IF vm_tipo_orden IS NOT NULL THEN
			CALL fl_lee_tipo_orden_compra(vm_tipo_orden)
				RETURNING r_c01.*
			IF r_c01.c01_tipo_orden IS NULL THEN
				CALL fl_mostrar_mensaje('No existe el tipo de orden en la Compañía.','exclamation')
				CLEAR nom_tipo
				NEXT FIELD vm_tipo_orden
			END IF
			DISPLAY r_c01.c01_nombre TO nom_tipo
		ELSE 
			CLEAR nom_tipo
		END IF

	AFTER INPUT
		IF vm_numero_oc IS NOT NULL THEN
			CALL control_ver_oc(vm_numero_oc)
			CONTINUE INPUT 
		END IF

		IF rm_c10.c10_estado = 'C' THEN
			IF vm_fecha_desde IS NULL THEN
				CALL fl_mostrar_mensaje('Debe ingresar la fecha de inicio.','exclamation') 
				NEXT FIELD vm_fecha_desde
			END IF
			IF vm_fecha_hasta IS NULL THEN
				CALL fl_mostrar_mensaje('Debe ingresar la fecha final.','exclamation') 
				NEXT FIELD vm_fecha_hasta
			END IF
		END IF
		IF vg_gui = 0 THEN
			CALL muestra_estado(rm_c10.c10_estado)
		END IF

		IF vm_fecha_desde IS NULL AND vm_fecha_hasta IS NULL THEN
			EXIT INPUT
		END IF

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



FUNCTION control_ver_oc(oc)
DEFINE oc		LIKE ordt010.c10_numero_oc
DEFINE command_run  	VARCHAR(150)
DEFINE run_prog		CHAR(10)

{-- ESTO PARA LLAMAR AL PROGRAMA SEGÚN SEA EL AMBIENTE --}
LET run_prog = 'fglrun '
IF vg_gui = 0 THEN
	LET run_prog = 'fglgo '
END IF
{--- ---}
	LET command_run = run_prog || 'ordp200 ' || vg_base || ' '
			    || vg_modulo || ' ' || vg_codcia 
			    || ' ' || vg_codloc || ' ' || oc
	RUN command_run

END FUNCTION



FUNCTION control_ver_proveedor(codprov)
DEFINE codprov		LIKE ordt010.c10_codprov
DEFINE command_run  	VARCHAR(200)
DEFINE run_prog		CHAR(10)

{-- ESTO PARA LLAMAR AL PROGRAMA SEGÚN SEA EL AMBIENTE --}
LET run_prog = '; fglrun '
IF vg_gui = 0 THEN
	LET run_prog = '; fglgo '
END IF
{--- ---}
LET command_run = 'cd ..', vg_separador|| '..'|| vg_separador|| 
    		  'TESORERIA'|| vg_separador|| 'fuentes'|| 
		   vg_separador || run_prog || 'cxpp101 '|| vg_base||
		  ' '|| 'TE'|| ' '|| vg_codcia|| ' '|| vg_codloc|| ' '|| codprov

RUN command_run

END FUNCTION



FUNCTION control_consulta()
DEFINE query         	CHAR(500)
DEFINE i		SMALLINT
DEFINE r_c10		RECORD LIKE ordt010.*
DEFINE r_p01		RECORD LIKE cxpt001.*
DEFINE expr_fecha	VARCHAR(150)
DEFINE expr_prov	VARCHAR(50)
DEFINE expr_tipo_orden	VARCHAR(50)
DEFINE expr_depto	VARCHAR(50)

INITIALIZE query TO NULL
LET expr_fecha      = ' 1 = 1 '
LET expr_prov       = ' 1 = 1 '
LET expr_tipo_orden = ' 1 = 1 '
LET expr_depto      = ' 1 = 1 '

IF vm_fecha_desde IS NOT NULL THEN 
	LET expr_fecha = ' DATE(c10_fecing) BETWEEN "', vm_fecha_desde,'"',
			 ' AND "', vm_fecha_hasta,'"'
END IF
IF num_args() = 8 THEN
	LET rm_c10.c10_estado = 'C'
	LET expr_fecha = ' DATE(c10_fecha_fact) BETWEEN "', vm_fecha_desde,'"',
			 ' AND "', vm_fecha_hasta,'"'
END IF

IF vm_proveedor IS NOT NULL THEN 
	LET expr_prov = ' c10_codprov = ',vm_proveedor	
END IF

IF vm_depto IS NOT NULL THEN 
	LET expr_depto = ' c10_cod_depto = ',vm_depto	
END IF

IF vm_tipo_orden IS NOT NULL THEN 
	LET expr_tipo_orden = ' c10_tipo_orden = ',vm_tipo_orden	
END IF

LET query = 'SELECT ordt010.*, cxpt001.* FROM ordt010, cxpt001',
		' WHERE c10_compania   = ',vg_codcia,
		'   AND c10_localidad  = ',vg_codloc,
		'   AND c10_estado     = "',rm_c10.c10_estado,'"',
		'   AND c10_codprov    = p01_codprov' CLIPPED,
		'   AND ',expr_tipo_orden CLIPPED,
		'   AND ',expr_prov CLIPPED,
		'   AND ',expr_depto CLIPPED,
		'   AND ',expr_fecha CLIPPED 
PREPARE consulta FROM query
DECLARE q_consulta CURSOR FOR consulta

LET i = 1
FOREACH q_consulta INTO r_c10.*, r_p01.*

	LET r_detalle[i].c10_numero_oc  = r_c10.c10_numero_oc
	LET r_detalle[i].c10_moneda     = r_c10.c10_moneda
	LET r_detalle[i].proveedor      = r_p01.p01_nomprov
	LET r_detalle[i].fecha          = DATE(r_c10.c10_fecing)
	LET r_detalle[i].c10_tot_compra = r_c10.c10_tot_compra
	LET r_detalle_1[i].codprov	= r_p01.p01_codprov

	INSERT INTO tmp_consulta VALUES(r_detalle[i].*,r_c10.c10_codprov)
		
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
DEFINE r_r19		RECORD LIKE rept019.*
DEFINE cuantos		SMALLINT
DEFINE tipo_comp	LIKE ctbt012.b12_tipo_comp
DEFINE num_comp		LIKE ctbt012.b12_num_comp

FOR i = 1 TO 10
	LET rm_orden[i] = '' 
END FOR
LET rm_orden[1]  = 'ASC'
LET vm_columna_1 = 2
LET vm_columna_2 = 3
LET col          = 2
WHILE TRUE

	LET query = 'SELECT * FROM tmp_consulta ',
			' ORDER BY ', vm_columna_1, ' ', rm_orden[vm_columna_1],
			        ', ', vm_columna_2, ' ', rm_orden[vm_columna_2]
	PREPARE consulta_2 FROM query
	DECLARE q_consulta_2 CURSOR FOR consulta_2

	LET m = 1
	FOREACH q_consulta_2 INTO r_detalle[m].*, r_detalle_1[m].codprov
		LET m = m + 1
		IF m > vm_num_det THEN
			EXIT FOREACH
		END IF
	END FOREACH

	CALL sacar_total()

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
			--#CALL muestra_contadores_det(i)
			--#LET tipo_comp = NULL
			--#LET num_comp  = NULL
			--#DECLARE q_levis CURSOR FOR 
				--#SELECT c40_tipo_comp, c40_num_comp 
				--#FROM ordt040 
				--#WHERE c40_compania  = vg_codcia	
				 --# AND c40_localidad = vg_codloc
				  --#AND c40_numero_oc = r_detalle[i].c10_numero_oc
			--#OPEN q_levis 
			--#FETCH q_levis INTO tipo_comp, num_comp
			--#IF tipo_comp IS NOT NULL THEN
				--#CALL dialog.keysetlabel('F5', 
					--#'Contabilización')
			--#ELSE
				--#CALL dialog.keysetlabel('F5', '')
			--#END IF

		--#AFTER DISPLAY 
			--#CONTINUE DISPLAY

		ON KEY(INTERRUPT)
			LET INT_FLAG = 1
			EXIT DISPLAY
        	ON KEY(F1,CONTROL-W)
			CALL control_visor_teclas_caracter_1() 
		ON KEY(F5)
			IF tipo_comp IS NOT NULL THEN
				CALL contabilizacion(tipo_comp, num_comp)
			END IF
			LET int_flag = 0

		ON KEY(F6)
			LET i = arr_curr()
			LET j = scr_line()
			CALL control_ver_oc(r_detalle[i].c10_numero_oc)
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
	END DISPLAY
	IF int_flag = 1 THEN
		IF num_args() = 8 THEN
			EXIT PROGRAM
		END IF
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



FUNCTION contabilizacion(tipo_comp, num_comp)
DEFINE comando 		VARCHAR(255)
DEFINE tipo_comp	LIKE ctbt012.b12_tipo_comp
DEFINE num_comp		LIKE ctbt012.b12_num_comp
DEFINE run_prog		CHAR(10)

{-- ESTO PARA LLAMAR AL PROGRAMA SEGÚN SEA EL AMBIENTE --}
LET run_prog = '; fglrun '
IF vg_gui = 0 THEN
	LET run_prog = '; fglgo '
END IF
{--- ---}
LET comando = 'cd ..', vg_separador, '..', vg_separador,
	      'CONTABILIDAD', vg_separador, 'fuentes', 
	      vg_separador, run_prog, 'ctbp201 ', vg_base, ' ',
	      'CB ', vg_codcia, ' ', tipo_comp, ' ', num_comp

RUN comando

END FUNCTION



FUNCTION muestra_contadores_det(i)
DEFINE i           SMALLINT

IF vg_gui = 1 THEN
	DISPLAY "" AT 21, 4
	DISPLAY i, " de ", vm_num_det AT 21,4
END IF

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
DISPLAY '<F5>      Contabilización'          AT a,2
DISPLAY  'F5' AT a,3 ATTRIBUTE(REVERSE)
LET a = a + 1
DISPLAY '<F6>      Orden de Compra'          AT a,2
DISPLAY  'F6' AT a,3 ATTRIBUTE(REVERSE)
LET a = fgl_getkey()
CLOSE WINDOW w_tf

END FUNCTION



FUNCTION muestra_estado(estado)
DEFINE estado		CHAR(1)

CASE estado
	WHEN 'A'
		DISPLAY 'ACTIVAS' TO tit_estado
	WHEN 'P'
		DISPLAY 'APROBADAS' TO tit_estado
	WHEN 'C'
		DISPLAY 'CERRADAS' TO tit_estado
	OTHERWISE
		CLEAR c10_estado, tit_estado
END CASE

END FUNCTION



FUNCTION sacar_total()
DEFINE i		SMALLINT

LET vm_total = 0
FOR i = 1 TO vm_num_det
	LET vm_total = vm_total + r_detalle[i].c10_tot_compra
END FOR
DISPLAY BY NAME vm_total

END FUNCTION
