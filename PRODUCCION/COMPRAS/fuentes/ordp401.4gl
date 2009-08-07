------------------------------------------------------------------------------
-- Titulo           : ordp401.4gl - Listado detalle de ordenes de compra
-- Elaboracion      : 17-ene-2002
-- Autor            : JCM
-- Formato Ejecucion: fglrun ordp401 base módulo compañía localidad
-- Ultima Correccion: 
-- Motivo Correccion: 
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_demonios	VARCHAR(12)

DEFINE rm_g01		RECORD LIKE gent001.*

DEFINE rm_par RECORD 
	g13_moneda	LIKE gent013.g13_moneda,
	g13_nombre	LIKE gent013.g13_nombre,
	fecha_ini	DATE,
	fecha_fin	DATE,
	estado		CHAR,
	tipo_oc		LIKE ordt001.c01_tipo_orden,
	n_tipo_oc	LIKE ordt001.c01_nombre,
	dpto		LIKE gent034.g34_cod_depto,
	n_dpto		LIKE gent034.g34_nombre,
	codprov		LIKE cxpt001.p01_codprov,
	nomprov		LIKE cxpt001.p01_nomprov
END RECORD

DEFINE num_campos	SMALLINT
DEFINE rm_campos ARRAY[15] OF RECORD
	nombre		VARCHAR(20),
	posicion	SMALLINT
END RECORD

DEFINE num_ord		SMALLINT
DEFINE rm_ord    ARRAY[2] OF RECORD
	col		VARCHAR(20),
	chk_asc		CHAR,
	chk_desc	CHAR
END RECORD

DEFINE vm_page		SMALLINT	-- PAGE   LENGTH
DEFINE vm_top		SMALLINT	-- TOP    MARGIN
DEFINE vm_left		SMALLINT	-- LEFT   MARGIN
DEFINE vm_right		SMALLINT	-- RIGHT  MARGIN
DEFINE vm_bottom	SMALLINT	-- BOTTOM MARGIN



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/ordp401.error')
CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 THEN          -- Validar # parámetros correcto
	CALL fgl_winmessage(vg_producto, 
		'Número de parámetros incorrecto', 
		'stop')
	EXIT PROGRAM
END IF
LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_codcia   = arg_val(3)
LET vg_codloc   = arg_val(4)
LET vg_proceso = 'ordp401'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()

END MAIN



FUNCTION funcion_master()

DEFINE i		SMALLINT
DEFINE r_g13		RECORD LIKE gent013.*

CALL fl_nivel_isolation()

LET vm_top    = 1
LET vm_left   =	2
LET vm_right  =	90
LET vm_bottom =	4
LET vm_page   = 66

CALL campos_forma()

CALL fl_lee_moneda(rg_gen.g00_moneda_base) RETURNING r_g13.*
INITIALIZE rm_par.* TO NULL
LET rm_par.g13_moneda = r_g13.g13_moneda
LET rm_par.g13_nombre = r_g13.g13_nombre
LET rm_par.estado     = 'T'
LET rm_par.fecha_ini  = TODAY
LET rm_par.fecha_fin  = TODAY

LET num_ord = 2
LET rm_ord[1].col      = rm_campos[5].nombre
LET rm_ord[2].col      = rm_campos[2].nombre

OPEN WINDOW w_mas AT 3,2 WITH 14 ROWS, 80 COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE 0, 
		BORDER, MESSAGE LINE LAST - 2)
OPTIONS INPUT WRAP,
	ACCEPT KEY	F12
OPEN FORM f_rep FROM "../forms/ordf401_1"
DISPLAY FORM f_rep

FOR i = 1 TO num_ord
	LET rm_ord[i].chk_asc  = 'S'
	LET rm_ord[i].chk_desc = 'N'
	
	DISPLAY rm_ord[i].* TO rm_ord[i].*
END FOR

CALL control_reporte()

END FUNCTION



FUNCTION control_reporte()
DEFINE i,col		SMALLINT
DEFINE query		VARCHAR(1000)
DEFINE comando		VARCHAR(100)
DEFINE data_found	SMALLINT

DEFINE r_det		RECORD 
	fecha_ing	DATE,
	estado		CHAR,
	tipo_oc		LIKE ordt001.c01_nombre,
	numero_oc	LIKE ordt010.c10_numero_oc,
	dpto		LIKE gent034.g34_nombre,
	nomprov		LIKE cxpt001.p01_nomprov,
	factura		LIKE ordt010.c10_factura,
	fecha_fact	DATE,
	valor_bruto	LIKE ordt010.c10_tot_compra,
	valor_dscto	LIKE ordt010.c10_tot_dscto,
	valor_impto	LIKE ordt010.c10_tot_impto,
	valor_neto	LIKE ordt010.c10_tot_compra
END RECORD

INITIALIZE r_det.* TO NULL 

WHILE TRUE
	CALL lee_parametros()
	IF int_flag THEN
		EXIT WHILE
	END IF
	
	CALL ordenar_por()
	IF int_flag THEN
		EXIT WHILE
	END IF

	CALL fl_control_reportes() RETURNING comando
	IF int_flag THEN
		CONTINUE WHILE
	END IF
	CALL fl_lee_compania(vg_codcia) RETURNING rm_g01.*
	
	LET query = prepare_query()
	
	PREPARE deto FROM query
	DECLARE q_deto CURSOR FOR deto
	LET data_found = 0

	START REPORT rep_orden_compra TO PIPE comando
	FOREACH	q_deto INTO r_det.*
		LET data_found = 1
		OUTPUT TO REPORT rep_orden_compra(r_det.*)
	END FOREACH
	FINISH REPORT rep_orden_compra

	IF NOT data_found THEN
		CALL fl_mensaje_consulta_sin_registros()
	END IF
END WHILE

END FUNCTION



FUNCTION lee_parametros()
DEFINE i,j,l		SMALLINT

DEFINE r_g13		RECORD LIKE gent013.*
DEFINE r_g34		RECORD LIKE gent034.*
DEFINE r_c01		RECORD LIKE ordt001.*
DEFINE r_p01		RECORD LIKE cxpt001.*

LET INT_FLAG   = 0
INPUT BY NAME rm_par.* WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		IF NOT FIELD_TOUCHED(rm_par.*) THEN
			EXIT PROGRAM
		END IF
		LET INT_FLAG = 1 
		RETURN
	ON KEY(F2)
		IF INFIELD(g13_moneda) THEN
			CALL fl_ayuda_monedas() RETURNING r_g13.g13_moneda, 
					  		  r_g13.g13_nombre,
					  		  r_g13.g13_decimales
			IF r_g13.g13_moneda IS NOT NULL THEN
				LET rm_par.g13_moneda = r_g13.g13_moneda
				LET rm_par.g13_nombre = r_g13.g13_nombre
				DISPLAY BY NAME rm_par.*
			END IF
		END IF
		IF INFIELD(tipo_oc) THEN
			CALL fl_ayuda_tipos_ordenes_compras() 
					RETURNING r_c01.c01_tipo_orden,
						  r_c01.c01_nombre
			IF r_c01.c01_tipo_orden IS NOT NULL THEN
				LET rm_par.tipo_oc    = r_c01.c01_tipo_orden
				LET rm_par.n_tipo_oc  = r_c01.c01_nombre
				DISPLAY BY NAME rm_par.*
			END IF
		END IF
		IF INFIELD(dpto) THEN
			CALL fl_ayuda_departamentos(vg_codcia) 
					RETURNING r_g34.g34_cod_depto,
						  r_g34.g34_nombre
			IF r_g34.g34_cod_depto IS NOT NULL THEN
				LET rm_par.dpto   = r_g34.g34_cod_depto
				LET rm_par.n_dpto = r_g34.g34_nombre
				DISPLAY BY NAME rm_par.*
			END IF
		END IF
		IF INFIELD(codprov) THEN
			CALL fl_ayuda_proveedores() RETURNING r_p01.p01_codprov,
						  	      r_p01.p01_nomprov
			IF r_p01.p01_codprov IS NOT NULL THEN
				LET rm_par.codprov = r_p01.p01_codprov
				LET rm_par.nomprov = r_p01.p01_nomprov
				DISPLAY BY NAME rm_par.*
			END IF
		END IF
		LET INT_FLAG = 0
	AFTER FIELD g13_moneda
		IF rm_par.g13_moneda IS NOT NULL THEN
			CALL fl_lee_moneda(rm_par.g13_moneda) RETURNING r_g13.*
			IF r_g13.g13_moneda IS NULL THEN
				CALL fgl_winmessage(vg_producto, 
					'Moneda no existe.', 
					'exclamation')
				NEXT FIELD g13_moneda
			END IF
			LET rm_par.g13_nombre = r_g13.g13_nombre
			DISPLAY BY NAME rm_par.g13_nombre
		ELSE
			LET rm_par.g13_nombre = NULL
			CLEAR g13_nombre
		END IF
	AFTER FIELD tipo_oc
		IF rm_par.tipo_oc IS NOT NULL THEN
			CALL fl_lee_tipo_orden_compra(rm_par.tipo_oc)
				RETURNING r_c01.*
			IF r_c01.c01_tipo_orden IS NULL THEN
				CALL fgl_winmessage(vg_producto, 
					'Tipo orden de compra no existe.', 
					'exclamation')
				NEXT FIELD tipo_oc
			END IF
			LET rm_par.n_tipo_oc = r_c01.c01_nombre
			DISPLAY BY NAME rm_par.n_tipo_oc
		ELSE
			LET rm_par.n_tipo_oc = NULL
			CLEAR n_tipo_oc
		END IF
	AFTER FIELD dpto
		IF rm_par.dpto IS NOT NULL THEN
			CALL fl_lee_departamento(vg_codcia, rm_par.dpto)
				RETURNING r_g34.*
			IF r_g34.g34_cod_depto IS NULL THEN
				CALL fgl_winmessage(vg_producto, 
					'Departamento no existe.', 
					'exclamation')
				NEXT FIELD dpto
			END IF
			LET rm_par.n_dpto = r_g34.g34_nombre
			DISPLAY BY NAME rm_par.n_dpto
		ELSE
			LET rm_par.n_dpto = NULL
			CLEAR n_dpto
		END IF
	AFTER FIELD codprov
		IF rm_par.codprov IS NOT NULL THEN
			CALL fl_lee_proveedor(rm_par.codprov) RETURNING r_p01.*
			IF r_p01.p01_codprov IS NULL THEN
				CALL fgl_winmessage(vg_producto, 
					'Proveedor no existe.', 
					'exclamation')
				NEXT FIELD codprov
			END IF
			LET rm_par.nomprov = r_p01.p01_nomprov
			DISPLAY BY NAME rm_par.nomprov
		ELSE
			LET rm_par.nomprov = NULL
			CLEAR nomprov
		END IF
	AFTER FIELD fecha_ini
		IF rm_par.fecha_ini IS NOT NULL THEN
			IF rm_par.fecha_ini > TODAY THEN
				CALL fgl_winmessage(vg_producto,'La fecha de inicio no puede ser mayor a la de hoy.','exclamation')
				NEXT FIELD fecha_ini
			END IF
			IF rm_par.fecha_ini < '01-01-1990' THEN
				CALL fgl_winmessage(vg_producto,'Debe ingresa fechas mayores a las del año 1989.','exclamation')	
				NEXT FIELD fecha_ini
			END IF
				
		ELSE 
			NEXT FIELD fecha_ini
		END IF
	AFTER FIELD fecha_fin
		IF rm_par.fecha_fin IS NOT NULL THEN
			IF rm_par.fecha_fin > TODAY THEN
				CALL fgl_winmessage(vg_producto,'La fecha de término no puede ser mayor a la de hoy.','exclamation')
				NEXT FIELD fecha_fin
			END IF
			IF rm_par.fecha_fin < '01-01-1990' THEN
				CALL fgl_winmessage(vg_producto,'Debe ingresa fechas mayores a las del año 1989.','exclamation')	
				NEXT FIELD fecha_fin
			END IF
		ELSE
			NEXT FIELD fecha_fin
		END IF
	AFTER INPUT
		IF rm_par.fecha_ini IS NULL OR rm_par.fecha_fin IS NULL THEN
			CONTINUE INPUT 
		END IF
		IF rm_par.fecha_ini > rm_par.fecha_fin THEN
			CALL fgl_winmessage(vg_producto,
				'La fecha inicial debe ser menor a la fecha ' ||
				'final.',
				'exclamation')
			CONTINUE INPUT
		END IF
END INPUT

END FUNCTION



FUNCTION prepare_query()

DEFINE query	 	VARCHAR(1100)
DEFINE expr_estado	VARCHAR(30)
DEFINE expr_tipo_oc	VARCHAR(30)
DEFINE expr_dpto	VARCHAR(30)
DEFINE expr_codprov	VARCHAR(30)

LET expr_estado = ' '
IF rm_par.estado <> 'T' THEN
	LET expr_estado = ' AND c10_estado = "' || rm_par.estado || '"'
END IF

LET expr_tipo_oc = ' '
IF rm_par.tipo_oc IS NOT NULL THEN
	LET expr_tipo_oc = ' AND c10_tipo_orden = ', rm_par.tipo_oc
END IF

LET expr_dpto = ' '
IF rm_par.dpto IS NOT NULL THEN
	LET expr_dpto = ' AND c10_cod_depto = ', rm_par.dpto
END IF

LET expr_codprov = ' '
IF rm_par.codprov IS NOT NULL THEN
	LET expr_codprov = ' AND c10_codprov = ', rm_par.codprov
END IF

LET query = 'SELECT DATE(c10_fecing), c10_estado, c01_nombre, c10_numero_oc, ',
	    	  ' g34_nombre, p01_nomprov, c10_factura, c10_fecha_fact, ', 
	    	  ' (c10_tot_repto + c10_tot_mano), c10_tot_dscto, ', 
	    	  ' c10_tot_impto, c10_tot_compra ',
	      ' FROM ordt010, ordt001, gent034, cxpt001 ',
	      ' WHERE c10_compania   = ', vg_codcia, 
	        ' AND c10_localidad  = ', vg_codloc,
	        expr_tipo_oc CLIPPED,
	        expr_dpto    CLIPPED,
	        expr_estado  CLIPPED,
	        expr_codprov CLIPPED,
	        ' AND c10_moneda     = "', rm_par.g13_moneda, '"',
	        ' AND DATE(c10_fecing) BETWEEN "', rm_par.fecha_ini, '"',
	                                 ' AND "', rm_par.fecha_fin, '"',
	        ' AND c01_tipo_orden = c10_tipo_orden ',
	        ' AND g34_compania   = c10_compania ',
	        ' AND g34_cod_depto  = c10_cod_depto ',
	        ' AND p01_codprov    = c10_codprov '
	    	  
RETURN full_query(query)

END FUNCTION



FUNCTION full_query(query)

DEFINE query		VARCHAR(1000)
DEFINE order_clause	VARCHAR(150)

DEFINE i		SMALLINT
DEFINE j		SMALLINT

LET order_clause = ' ORDER BY '

FOR i = 1 TO num_ord
	FOR j = 1 TO num_campos
		IF rm_ord[i].col = rm_campos[j].nombre THEN
			LET order_clause = order_clause || rm_campos[j].posicion
			IF rm_ord[i].chk_asc = 'S' THEN
				LET order_clause = order_clause || ' ASC'
			ELSE
				LET order_clause = order_clause || ' DESC'
			END IF
			IF i <> num_ord THEN
				LET order_clause = order_clause || ', '
			END IF
		END IF
	END FOR
END FOR

LET query = query || order_clause CLIPPED

RETURN query

END FUNCTION



REPORT rep_orden_compra(fecha_ing, estado, tipo_oc, numero_oc, dpto, nomprov,
			factura, fecha_fact, valor_bruto, valor_dscto, 
			valor_impto, valor_neto)

DEFINE fecha_ing	DATE
DEFINE estado		CHAR
DEFINE tipo_oc		LIKE ordt001.c01_nombre
DEFINE numero_oc	LIKE ordt010.c10_numero_oc
DEFINE dpto		LIKE gent034.g34_nombre
DEFINE nomprov		LIKE cxpt001.p01_nomprov
DEFINE factura		LIKE ordt010.c10_factura
DEFINE fecha_fact	DATE
DEFINE valor_bruto	LIKE ordt010.c10_tot_compra
DEFINE valor_dscto	LIKE ordt010.c10_tot_dscto
DEFINE valor_impto	LIKE ordt010.c10_tot_impto
DEFINE valor_neto	LIKE ordt010.c10_tot_compra

DEFINE usuario		VARCHAR(19,15)
DEFINE titulo		VARCHAR(80)
DEFINE modulo		VARCHAR(40)
DEFINE i,long		SMALLINT

OUTPUT
	TOP    MARGIN	vm_top
	LEFT   MARGIN	vm_left
	RIGHT  MARGIN	vm_right
	BOTTOM MARGIN	vm_bottom
	PAGE   LENGTH	vm_page
FORMAT
PAGE HEADER
	LET modulo  = "Módulo: Compras"
	LET long    = LENGTH(modulo)
	LET usuario = 'Usuario: ', vg_usuario
	CALL fl_justifica_titulo('D', usuario, 19) RETURNING usuario
	CALL fl_justifica_titulo('C', 'LISTADO DETALLE DE ORDENES DE COMPRA', 60)
		RETURNING titulo
	
	PRINT COLUMN 1, rm_g01.g01_razonsocial,
	      COLUMN 182, "Página: ", PAGENO USING "&&&"
	PRINT COLUMN 1, modulo CLIPPED,
	      COLUMN 70, titulo CLIPPED,
	      COLUMN 182, UPSHIFT(vg_proceso)
      
	SKIP 1 LINES
	IF rm_par.estado = 'T' THEN
		PRINT COLUMN 40, "** Estado              : Todos"
	END IF
	IF rm_par.estado = 'A' THEN
		PRINT COLUMN 40, "** Estado              : Activas"
	END IF
	IF rm_par.estado = 'P' THEN
		PRINT COLUMN 40, "** Estado              : Aprobadas"
	END IF
	IF rm_par.estado = 'C' THEN
		PRINT COLUMN 40, "** Estado              : Cerradas"
	END IF

	PRINT COLUMN 40, "** Moneda              : ", rm_par.g13_nombre
	PRINT COLUMN 40, "** Fecha Inicial       : ", 
			rm_par.fecha_ini USING "dd-mm-yyyy",
	      COLUMN 100, "** Fecha Final         : ", 
	      		rm_par.fecha_fin USING "dd-mm-yyyy"
	IF rm_par.tipo_oc IS NOT NULL THEN
		PRINT COLUMN 40, "** Tipo Orden de Compra: ", rm_par.n_tipo_oc
	END IF
	IF rm_par.dpto IS NOT NULL THEN
		PRINT COLUMN 40, "** Departamento        : ", rm_par.n_dpto
	END IF
	IF rm_par.codprov IS NOT NULL THEN
		PRINT COLUMN 40, "** Proveedor           : ", rm_par.nomprov
	END IF

	SKIP 1 LINES
	PRINT COLUMN 01, "Fecha de Impresión: ", TODAY USING "dd-mm-yyyy", 
	                 1 SPACES, TIME,
	      COLUMN 173, usuario
	SKIP 1 LINES
	
	PRINT COLUMN 1,   "Fecha Ing.",
	      COLUMN 13,  "Est",
	      COLUMN 18,  "Tipo O. C.",
	      COLUMN 35,  fl_justifica_titulo('D', "# O.C.", 6),
	      COLUMN 43,  "Departamento",
	      COLUMN 60,  "Proveedor",
	      COLUMN 92,  "Factura",
	      COLUMN 109, "Fecha Fact.",
	      COLUMN 122, fl_justifica_titulo('D', "Valor Bruto",  16),
	      COLUMN 140, fl_justifica_titulo('D', "Valor Dscto.", 16),
	      COLUMN 158, fl_justifica_titulo('D', "Valor Impto.", 16),
	      COLUMN 176, fl_justifica_titulo('D', "Valor Neto",   16)

	PRINT COLUMN 1,   "------------",
	      COLUMN 13,  "-----",
	      COLUMN 18,  "-----------------",
	      COLUMN 35,  "--------",
	      COLUMN 43,  "-----------------",
	      COLUMN 60,  "--------------------------------",
	      COLUMN 92,  "-----------------",
	      COLUMN 109, "-------------",
	      COLUMN 122, "------------------",
	      COLUMN 140, "------------------",
	      COLUMN 158, "------------------",
	      COLUMN 176, "------------------"

ON EVERY ROW

	PRINT COLUMN 1,   fecha_ing USING "dd-mm-yyyy",
	      COLUMN 13,  estado,
	      COLUMN 18,  tipo_oc CLIPPED,
	      COLUMN 35,  fl_justifica_titulo('D', numero_oc, 6),
	      COLUMN 43,  dpto CLIPPED,
	      COLUMN 60,  nomprov CLIPPED,
	      COLUMN 92,  factura CLIPPED,
	      COLUMN 109, fecha_fact USING "dd-mm-yyyy",
	      COLUMN 122, valor_bruto USING "#,###,###,##&.##",
	      COLUMN 140, valor_dscto USING "#,###,###,##&.##",
	      COLUMN 158, valor_impto USING "#,###,###,##&.##",
	      COLUMN 176, valor_neto USING "#,###,###,##&.##"

ON LAST ROW
	NEED 2 LINES
	PRINT COLUMN 122, "------------------",
	      COLUMN 140, "------------------",
	      COLUMN 158, "------------------",
	      COLUMN 176, "------------------"	
	      
	PRINT COLUMN 122, SUM(valor_bruto) USING "#,###,###,##&.##",
	      COLUMN 140, SUM(valor_dscto) USING "#,###,###,##&.##",
	      COLUMN 158, SUM(valor_impto) USING "#,###,###,##&.##",
	      COLUMN 176, SUM(valor_neto)  USING "#,###,###,##&.##"

END REPORT



FUNCTION ordenar_por()

DEFINE i		SMALLINT
DEFINE j		SMALLINT
DEFINE asc_ant		CHAR
DEFINE desc_ant		CHAR

DEFINE campo		VARCHAR(20)
DEFINE col_ant		VARCHAR(20)

CALL set_count(num_ord)
INPUT ARRAY rm_ord WITHOUT DEFAULTS FROM rm_ord.* 
	ON KEY(F2) 
		IF INFIELD(col) THEN
			CALL ayuda_campos() RETURNING campo
			IF campo IS NOT NULL THEN
				LET rm_ord[i].col = campo
				DISPLAY rm_ord[i].col TO rm_ord[i].col
			END IF
		END IF
	BEFORE ROW
		LET i = arr_curr()
	AFTER FIELD col
		IF rm_ord[i].col IS NULL THEN
			CALL fgl_winmessage(vg_producto,
				'Debe elegir una columna.',
				'exclamation')
			NEXT FIELD col	
		END IF
		LET campo = rm_ord[i].col
		FOR j = 1 TO num_ord
			IF j <> i AND rm_ord[j].col = campo THEN
				CALL fgl_winmessage(vg_producto,
					'No puede ordenar dos veces sobre el ' ||
					'mismo campo.',
					'exclamation')
				NEXT FIELD col
			END IF
		END FOR
		INITIALIZE campo TO NULL
		FOR j = 1 TO num_campos
			IF rm_ord[i].col = rm_campos[j].nombre THEN
				LET campo = 'OK'
				EXIT FOR
			END IF
		END FOR
		IF campo IS NULL THEN
			CALL fgl_winmessage(vg_producto,
				'Campo no existe.',
				'exclamation')
			NEXT FIELD col
		END IF
		DISPLAY rm_ord[i].col TO rm_ord[i].col
	BEFORE FIELD chk_asc
		LET asc_ant = rm_ord[i].chk_asc
	AFTER FIELD chk_asc
		IF rm_ord[i].chk_asc <> asc_ant THEN
			IF rm_ord[i].chk_asc = 'S' THEN
				LET rm_ord[i].chk_desc = 'N'
			ELSE
				LET rm_ord[i].chk_desc = 'S'
			END IF
			DISPLAY rm_ord[i].* TO rm_ord[i].*
		END IF
	BEFORE FIELD chk_desc
		LET desc_ant = rm_ord[i].chk_desc
	AFTER FIELD chk_desc
		IF rm_ord[i].chk_desc <> desc_ant THEN
			IF rm_ord[i].chk_desc = 'S' THEN
				LET rm_ord[i].chk_asc = 'N'
			ELSE
				LET rm_ord[i].chk_asc = 'S'
			END IF
			DISPLAY rm_ord[i].* TO rm_ord[i].*
		END IF
END INPUT

END FUNCTION



FUNCTION campos_forma()

LET rm_campos[1].nombre = 'NOMBRE PROVEEDOR'
LET rm_campos[1].posicion = 6
LET rm_campos[2].nombre = 'FECHA DE INGRESO'
LET rm_campos[2].posicion = 1
LET rm_campos[3].nombre = 'FECHA DE FACTURA'
LET rm_campos[3].posicion = 8
LET rm_campos[4].nombre = 'NUMERO O.C.'
LET rm_campos[4].posicion = 4
LET rm_campos[5].nombre = 'DEPARTAMENTO'
LET rm_campos[5].posicion = 5

LET num_campos = 5

END FUNCTION



FUNCTION ayuda_campos()

DEFINE rh_campos	ARRAY[11] OF VARCHAR(20)
DEFINE i                SMALLINT
DEFINE filas_max        SMALLINT        ## No. elementos del arreglo
DEFINE filas_pant       SMALLINT        ## No. elementos de cada pantalla
DEFINE j	SMALLINT

FOR i = 1 TO num_campos 
	LET rh_campos[i] = rm_campos[i].nombre
END FOR

LET filas_max  = 100
OPEN WINDOW wh AT 06,15 WITH FORM '../forms/ordf401_2'
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST -1, MESSAGE LINE LAST,
                   BORDER)
LET filas_pant = fgl_scr_size("rh_campos")

CALL set_count(num_campos)
LET int_flag = 0
DISPLAY ARRAY rh_campos TO rh_campos.*
        ON KEY(RETURN)
                EXIT DISPLAY
	BEFORE ROW
		LET j = arr_curr()
		MESSAGE  j, ' de ', num_campos
END DISPLAY
CLOSE WINDOW wh
IF int_flag THEN
        INITIALIZE rh_campos[1] TO NULL
        RETURN rh_campos[1]
END IF
LET  i = arr_curr()
RETURN rh_campos[i]

END FUNCTION



FUNCTION validar_parametros()

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
