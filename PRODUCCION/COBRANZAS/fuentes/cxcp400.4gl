------------------------------------------------------------------------------
-- Titulo           : cxcp400.4gl - Listado de cartera por cobrar
-- Elaboracion      : 14-ene-2002
-- Autor            : JCM
-- Formato Ejecucion: fglrun cxcp400 base módulo compañía localidad
-- Ultima Correccion: 
-- Motivo Correccion: 
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE rm_g01		RECORD LIKE gent001.*

DEFINE rm_par RECORD 
	anho		SMALLINT,
	mes		SMALLINT,
	g13_moneda	LIKE gent013.g13_moneda,
	g13_nombre	LIKE gent013.g13_nombre,
	areaneg		LIKE gent003.g03_areaneg,
	n_areaneg	LIKE gent003.g03_nombre,
	zona_cobro	LIKE cxct006.z06_zona_cobro,
	n_zona_cobro	LIKE cxct006.z06_nombre,
	tipocli		LIKE gent012.g12_subtipo,
	n_tipocli	LIKE gent012.g12_nombre,
	tipocartera	LIKE gent012.g12_subtipo,
	n_tipocartera	LIKE gent012.g12_nombre,
	tipo_vcto	CHAR,
	dias_ini	SMALLINT,
	dias_fin	INTEGER
END RECORD

DEFINE num_campos	SMALLINT
DEFINE rm_campos ARRAY[15] OF RECORD
	nombre		VARCHAR(20),
	posicion	SMALLINT
END RECORD

DEFINE num_ord		SMALLINT
DEFINE rm_ord    ARRAY[3] OF RECORD
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
CALL startlog('../logs/cxcp400.error')
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
LET vg_proceso = 'cxcp400'
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
LET vm_right  =	132
LET vm_bottom =	2
LET vm_page   = 66

CALL campos_forma()

CALL fl_lee_moneda(rg_gen.g00_moneda_base) RETURNING r_g13.*
INITIALIZE rm_par.* TO NULL
LET rm_par.anho       = YEAR(TODAY)
LET rm_par.mes        = MONTH(TODAY)
LET rm_par.g13_moneda = r_g13.g13_moneda
LET rm_par.g13_nombre = r_g13.g13_nombre
LET rm_par.tipo_vcto  = 'T'

LET num_ord = 3
LET rm_ord[1].col      = rm_campos[1].nombre
LET rm_ord[2].col      = rm_campos[2].nombre
LET rm_ord[3].col      = rm_campos[5].nombre

OPEN WINDOW w_mas AT 3,2 WITH 14 ROWS, 80 COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE 0, 
		BORDER, MESSAGE LINE LAST - 2)
OPTIONS INPUT WRAP,
	ACCEPT KEY	F12
OPEN FORM f_rep FROM "../forms/cxcf400_1"
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
	areaneg		LIKE gent003.g03_areaneg,
	zona_cobro	LIKE cxct002.z02_zona_cobro,
	codcli		LIKE cxct001.z01_codcli,
	nomcli		LIKE cxct001.z01_nomcli,
	tipo_doc	LIKE cxct020.z20_tipo_doc,
	num_doc		LIKE cxct020.z20_num_doc,
	dividendo	LIKE cxct020.z20_dividendo,
	fecha_emi	LIKE cxct020.z20_fecha_emi,
	fecha_vcto	LIKE cxct020.z20_fecha_vcto,
	antiguedad	INTEGER,
	saldo		LIKE cxct020.z20_saldo_cap
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
	
	IF year(TODAY) <> rm_par.anho OR month(TODAY) <> rm_par.mes THEN
		LET query = prepare_query_cxct050()
	ELSE
		LET query = prepare_query_cxct020()
	END IF
	
	PREPARE deto FROM query
	DECLARE q_deto CURSOR FOR deto
	LET data_found = 0

	START REPORT rep_cartera TO PIPE comando
	FOREACH	q_deto INTO r_det.*
		LET data_found = 1
		OUTPUT TO REPORT rep_cartera(r_det.*)
	END FOREACH
	FINISH REPORT rep_cartera

	IF NOT data_found THEN
		CALL fl_mensaje_consulta_sin_registros()
	END IF
END WHILE

END FUNCTION



FUNCTION lee_parametros()
DEFINE i,j,l		SMALLINT

DEFINE dummy		LIKE gent011.g11_tiporeg

DEFINE r_g03		RECORD LIKE gent003.*
DEFINE r_g12		RECORD LIKE gent012.*
DEFINE r_g13		RECORD LIKE gent013.*
DEFINE r_z06		RECORD LIKE cxct006.*

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
		IF INFIELD(areaneg) THEN
			CALL fl_ayuda_areaneg(vg_codcia) 
					RETURNING r_g03.g03_areaneg,
					  	  r_g03.g03_nombre
			IF r_g03.g03_areaneg IS NOT NULL THEN
				LET rm_par.areaneg   = r_g03.g03_areaneg
				LET rm_par.n_areaneg = r_g03.g03_nombre
				DISPLAY BY NAME rm_par.*
			END IF 
		END IF
		IF INFIELD(zona_cobro) THEN
			CALL fl_ayuda_zona_cobro() 
					RETURNING r_z06.z06_zona_cobro,
						  r_z06.z06_nombre
			IF r_z06.z06_zona_cobro IS NOT NULL THEN
				LET rm_par.zona_cobro   = r_z06.z06_zona_cobro
				LET rm_par.n_zona_cobro = r_z06.z06_nombre
				DISPLAY BY NAME rm_par.*
			END IF
		END IF
		IF INFIELD(tipocli) THEN
			CALL fl_ayuda_subtipo_entidad('CL') 
					RETURNING r_g12.g12_tiporeg,
						  r_g12.g12_subtipo,
						  r_g12.g12_nombre,
						  dummy
			IF r_g12.g12_subtipo IS NOT NULL THEN
				LET rm_par.tipocli   = r_g12.g12_subtipo
				LET rm_par.n_tipocli = r_g12.g12_nombre
				DISPLAY BY NAME rm_par.*
			END IF
		END IF
		IF INFIELD(tipocartera) THEN
			CALL fl_ayuda_subtipo_entidad('CR') 
					RETURNING r_g12.g12_tiporeg,
						  r_g12.g12_subtipo,
						  r_g12.g12_nombre,
						  dummy
			IF r_g12.g12_subtipo IS NOT NULL THEN
				LET rm_par.tipocartera   = r_g12.g12_subtipo
				LET rm_par.n_tipocartera = r_g12.g12_nombre
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
	AFTER FIELD areaneg
		IF rm_par.areaneg IS NOT NULL THEN
			CALL fl_lee_area_negocio(vg_codcia, rm_par.areaneg) 
				RETURNING r_g03.*
			IF r_g03.g03_areaneg IS NULL THEN
				CALL fgl_winmessage(vg_producto, 
					'Area de negocio no existe.', 
					'exclamation')
				NEXT FIELD areaneg
			END IF
			LET rm_par.n_areaneg = r_g03.g03_nombre
			DISPLAY BY NAME rm_par.n_areaneg
		ELSE
			LET rm_par.n_areaneg = NULL
			CLEAR n_areaneg
		END IF
	AFTER FIELD zona_cobro
		IF rm_par.zona_cobro IS NOT NULL THEN
			CALL fl_lee_zona_cobro(rm_par.zona_cobro)
				RETURNING r_z06.*
			IF r_z06.z06_zona_cobro IS NULL THEN
				CALL fgl_winmessage(vg_producto, 
					'Zona de cobro no existe.', 
					'exclamation')
				NEXT FIELD zona_cobro
			END IF
			LET rm_par.n_zona_cobro = r_z06.z06_nombre
			DISPLAY BY NAME rm_par.n_zona_cobro
		ELSE
			LET rm_par.n_zona_cobro = NULL
			CLEAR n_zona_cobro
		END IF
	AFTER FIELD tipocli
		IF rm_par.tipocli IS NOT NULL THEN
			CALL fl_lee_subtipo_entidad('CL', rm_par.tipocli)
				RETURNING r_g12.*
			IF r_g12.g12_subtipo IS NULL THEN
				CALL fgl_winmessage(vg_producto, 
					'Tipo cliente no existe.', 
					'exclamation')
				NEXT FIELD tipocli
			END IF
			LET rm_par.n_tipocli = r_g12.g12_nombre
			DISPLAY BY NAME rm_par.n_tipocli
		ELSE
			LET rm_par.n_tipocli = NULL
			CLEAR n_tipocli
		END IF
	AFTER FIELD tipocartera
		IF rm_par.tipocartera IS NOT NULL THEN
			CALL fl_lee_subtipo_entidad('CR', rm_par.tipocartera)
				RETURNING r_g12.*
			IF r_g12.g12_subtipo IS NULL THEN
				CALL fgl_winmessage(vg_producto, 
					'Tipo cartera no existe.', 
					'exclamation')
				NEXT FIELD tipocartera
			END IF
			LET rm_par.n_tipocartera = r_g12.g12_nombre
			DISPLAY BY NAME rm_par.n_tipocartera
		ELSE
			LET rm_par.n_tipocartera = NULL
			CLEAR n_tipocartera
		END IF
	BEFORE FIELD dias_ini
		IF rm_par.tipo_vcto = 'T' THEN
			NEXT FIELD NEXT
		END IF
	BEFORE FIELD dias_fin
		IF rm_par.tipo_vcto = 'T' THEN
			IF fgl_lastkey() = fgl_keyval('up') THEN
				NEXT FIELD tipo_vcto
			ELSE
				NEXT FIELD NEXT
			END IF
		END IF
	AFTER INPUT
		IF rm_par.dias_ini IS NOT NULL AND rm_par.dias_fin IS NULL THEN
			CALL fgl_winmessage(vg_producto,
				'Si ingresa un rango de días debe ingresar ' ||
				'ambos valores.',
				'exclamation')
			CONTINUE INPUT
		END IF
		IF rm_par.dias_fin IS NOT NULL AND rm_par.dias_ini IS NULL THEN
			CALL fgl_winmessage(vg_producto,
				'Si ingresa un rango de días debe ingresar ' ||
				'ambos valores.',
				'exclamation')
			CONTINUE INPUT
		END IF
END INPUT

END FUNCTION



FUNCTION prepare_query_cxct050()

DEFINE query	 	VARCHAR(1100)
DEFINE expr_area	VARCHAR(30)
DEFINE expr_zona	VARCHAR(30)
DEFINE expr_tipocli	VARCHAR(30)
DEFINE expr_tipocartera VARCHAR(30)
DEFINE expr_vcto	VARCHAR(30)
DEFINE expr_dias	VARCHAR(60)

LET expr_area = ' '
IF rm_par.areaneg IS NOT NULL THEN
	LET expr_area = ' AND z50_areaneg = ', rm_par.areaneg
END IF

LET expr_zona = ' '
IF rm_par.zona_cobro IS NOT NULL THEN
	LET expr_zona = ' AND z02_zona_cobro = ', rm_par.zona_cobro
END IF

LET expr_tipocli = ' '
IF rm_par.tipocli IS NOT NULL THEN
	LET expr_tipocli = ' AND z01_tipo_clte = ', rm_par.tipocli
END IF

LET expr_tipocartera = ' '
IF rm_par.tipocartera IS NOT NULL THEN
	LET expr_tipocartera = ' AND z50_cartera = ', rm_par.tipocartera
END IF

CASE rm_par.tipo_vcto 
	WHEN 'P'
		LET expr_vcto = ' AND z50_fecha_vcto >= TODAY '
		IF rm_par.dias_ini IS NOT NULL THEN
			LET expr_dias = ' AND (z50_fecha_vcto - TODAY) BETWEEN ',
					rm_par.dias_ini, ' AND ', rm_par.dias_fin
		END IF
	WHEN 'V'
		LET expr_vcto = ' AND z50_fecha_vcto < TODAY '
		IF rm_par.dias_ini IS NOT NULL THEN
			LET expr_dias = ' AND (TODAY - z50_fecha_vcto) BETWEEN ',
					rm_par.dias_ini, ' AND ', rm_par.dias_fin
		END IF
	OTHERWISE
		LET expr_vcto = ' '
		LET expr_dias = ' '
END CASE

LET query = 'SELECT z50_areaneg, z02_zona_cobro, z50_codcli, z01_nomcli, ',
	          ' z50_tipo_doc, z50_num_doc, z50_dividendo, z50_fecha_emi, ',
	          ' z50_fecha_vcto, (z50_fecha_vcto - TODAY), ',
	          ' (z50_saldo_cap + z50_saldo_int) ',
	    	' FROM cxct050, cxct001, OUTER cxct002 ', 
	    	' WHERE z50_ano = ', rm_par.anho,
	    	  ' AND z50_mes = ', rm_par.mes,
	    	  ' AND z50_compania = ', vg_codcia,
	    	  ' AND z50_localidad = ', vg_codloc,
	    	  ' AND z50_moneda = "', rm_par.g13_moneda, '"', 
	    	  expr_area CLIPPED, 
	    	  expr_tipocartera CLIPPED,
	    	  expr_vcto CLIPPED,
	    	  expr_dias CLIPPED,
		  ' AND (z50_saldo_cap + z50_saldo_int) > 0 ', 
	    	  ' AND z01_codcli = z50_codcli ',
	    	  expr_tipocli CLIPPED,
	    	  ' AND z02_compania = z50_compania ',
	    	  ' AND z02_localidad = z50_localidad ', 
	    	  ' AND z02_codcli = z50_codcli ',
	    	  expr_zona CLIPPED
	    	  
RETURN full_query(query)

END FUNCTION



FUNCTION prepare_query_cxct020()

DEFINE query	 	VARCHAR(1000)
DEFINE expr_area	VARCHAR(30)
DEFINE expr_zona	VARCHAR(30)
DEFINE expr_tipocli	VARCHAR(30)
DEFINE expr_tipocartera VARCHAR(30)
DEFINE expr_vcto	VARCHAR(30)
DEFINE expr_dias	VARCHAR(60)

LET expr_area = ' '
IF rm_par.areaneg IS NOT NULL THEN
	LET expr_area = ' AND z20_areaneg = ', rm_par.areaneg
END IF

LET expr_zona = ' '
IF rm_par.zona_cobro IS NOT NULL THEN
	LET expr_zona = ' AND z02_zona_cobro = ', rm_par.zona_cobro
END IF

LET expr_tipocli = ' '
IF rm_par.tipocli IS NOT NULL THEN
	LET expr_tipocli = ' AND z01_tipo_clte = ', rm_par.tipocli
END IF

LET expr_tipocartera = ' '
IF rm_par.tipocartera IS NOT NULL THEN
	LET expr_tipocartera = ' AND z20_cartera = ', rm_par.tipocartera
END IF

CASE rm_par.tipo_vcto 
	WHEN 'P'
		LET expr_vcto = ' AND z20_fecha_vcto >= TODAY '
		IF rm_par.dias_ini IS NOT NULL THEN
			LET expr_dias = ' AND (z20_fecha_vcto - TODAY) BETWEEN ',
					rm_par.dias_ini, ' AND ', rm_par.dias_fin
		END IF
	WHEN 'V'
		LET expr_vcto = ' AND z20_fecha_vcto < TODAY '
		IF rm_par.dias_ini IS NOT NULL THEN
			LET expr_dias = ' AND (TODAY - z20_fecha_vcto) BETWEEN ',
					rm_par.dias_ini, ' AND ', rm_par.dias_fin
		END IF
	OTHERWISE
		LET expr_vcto = ' '
		LET expr_dias = ' '
END CASE

LET query = 'SELECT z20_areaneg, z02_zona_cobro, z20_codcli, z01_nomcli, ',
	          ' z20_tipo_doc, z20_num_doc, z20_dividendo, z20_fecha_emi, ',
	          ' z20_fecha_vcto, (z20_fecha_vcto - TODAY) antiguedad, ',
	          ' (z20_saldo_cap + z20_saldo_int) saldo ',
	    	' FROM cxct020, cxct001, OUTER cxct002 ', 
	    	' WHERE z20_compania = ', vg_codcia,
	    	  ' AND z20_localidad = ', vg_codloc,
	    	  ' AND z20_moneda = "', rm_par.g13_moneda, '"', 
	    	  expr_area CLIPPED, 
	    	  expr_tipocartera CLIPPED,
	    	  expr_vcto CLIPPED,
	    	  expr_dias CLIPPED,
		  ' AND (z20_saldo_cap + z20_saldo_int) > 0 ', 
	    	  ' AND z01_codcli = z20_codcli ',
	    	  expr_tipocli CLIPPED,
	    	  ' AND z02_compania = z20_compania ',
	    	  ' AND z02_localidad = z20_localidad ', 
	    	  ' AND z02_codcli = z20_codcli ',
	    	  expr_zona CLIPPED
	    	  
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



REPORT rep_cartera(areaneg, zona_cobro, codcli, nomcli, tipo_doc, num_doc,
		   dividendo, fecha_emi, fecha_vcto, antiguedad, saldo)

DEFINE areaneg		LIKE gent003.g03_areaneg
DEFINE zona_cobro	VARCHAR(10)
DEFINE codcli		LIKE cxct001.z01_codcli
DEFINE nomcli		LIKE cxct001.z01_nomcli
DEFINE tipo_doc		LIKE cxct020.z20_tipo_doc
DEFINE num_doc		LIKE cxct020.z20_num_doc
DEFINE dividendo	LIKE cxct020.z20_dividendo
DEFINE fecha_emi	LIKE cxct020.z20_fecha_emi
DEFINE fecha_vcto	LIKE cxct020.z20_fecha_vcto
DEFINE antiguedad	SMALLINT
DEFINE saldo		LIKE cxct020.z20_saldo_cap
DEFINE saldo_cli	LIKE cxct020.z20_saldo_cap

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

FIRST PAGE HEADER
	LET saldo_cli = 0
	print 'E'; print '&l26A';	-- Indica que voy a trabajar con hojas A4
	print '&k4S'	                -- Letra (12 cpi)
	LET modulo  = "Módulo: Cobranzas"
	LET long    = LENGTH(modulo)
	LET usuario = 'Usuario: ', vg_usuario
	CALL fl_justifica_titulo('D', usuario, 19) RETURNING usuario
	CALL fl_justifica_titulo('C', 'LISTADO DETALLE DE CARTERA POR COBRAR', 60)
		RETURNING titulo
	
	PRINT COLUMN 1, rm_g01.g01_razonsocial,
	      COLUMN 77, "Página: ", PAGENO USING "&&&"
	PRINT COLUMN 1, modulo CLIPPED,
	      COLUMN 30, fl_justifica_titulo('I', titulo CLIPPED, 60) CLIPPED,
	      COLUMN 77, UPSHIFT(vg_proceso)

	SKIP 1 LINES
	PRINT COLUMN 15, "** Año            : ", 
					fl_justifica_titulo('I', rm_par.anho, 4),
	      COLUMN 51, "** Mes: ", fl_justifica_titulo('I', 
	      				fl_retorna_nombre_mes(rm_par.mes), 10)
	PRINT COLUMN 15, "** Moneda         : ", rm_par.g13_nombre
	
	IF rm_par.tipo_vcto = 'P' THEN
			PRINT COLUMN 15, "** Tipo Vcto.     : Por Vencer"
	ELSE 
		IF rm_par.tipo_vcto = 'V' THEN
			PRINT COLUMN 15, "** Tipo Vcto.     : Vencido"
		ELSE
			PRINT COLUMN 15, "** Tipo Vcto.     : Todos"
		END IF
	END IF
	
	IF rm_par.areaneg IS NOT NULL THEN
		PRINT COLUMN 15, "** Area de Negocio: ", rm_par.n_areaneg
	END IF
	IF rm_par.zona_cobro IS NOT NULL THEN
		PRINT COLUMN 15, "** Zona de Cobro  : ", rm_par.n_zona_cobro
	END IF
	IF rm_par.tipocli IS NOT NULL THEN
		PRINT COLUMN 15, "** Tipo de Cliente: ", rm_par.n_tipocli
	END IF
	IF rm_par.tipocartera IS NOT NULL THEN
		PRINT COLUMN 15, "** Tipo de Cartera: ", rm_par.n_tipocartera
	END IF
	
	SKIP 1 LINES
	PRINT COLUMN 01, "Fecha de Impresión: ", TODAY USING "dd-mm-yyyy", 
	                 1 SPACES, TIME,
	      COLUMN 68, usuario
	
	print '&k2S'	                -- Letra condensada (16 cpi)
	
	PRINT COLUMN 1,   "Area",
	      COLUMN 7,   "Zona",
	      COLUMN 14,  "Cliente",
	      COLUMN 54,  "Documento",
	      COLUMN 80,  "Fecha Emi.",
	      COLUMN 92,  "Fecha Vcto.",
	      COLUMN 104, fl_justifica_titulo('D', "Días", 5),
	      COLUMN 111, fl_justifica_titulo('D', "Saldo", 16)

	PRINT COLUMN 1,   "------",
	      COLUMN 7,   "-------",
	      COLUMN 14,  "----------------------------------------",
	      COLUMN 54,  "--------------------------",
	      COLUMN 80,  "------------",
	      COLUMN 92,  "------------",
	      COLUMN 104, "-------",
	      COLUMN 111, "------------------"

PAGE HEADER
	print 'E'; print '&l26A';	-- Indica que voy a trabajar con hojas A4
	print '&k4S'	                -- Letra (12 cpi)
	LET modulo  = "Módulo: Cobranzas"
	LET long    = LENGTH(modulo)
	LET usuario = 'Usuario: ', vg_usuario
	CALL fl_justifica_titulo('D', usuario, 19) RETURNING usuario
	CALL fl_justifica_titulo('C', 'LISTADO DETALLE DE CARTERA POR COBRAR', 60)
		RETURNING titulo
	
	PRINT COLUMN 1, rm_g01.g01_razonsocial,
	      COLUMN 77, "Página: ", PAGENO USING "&&&"
	PRINT COLUMN 1, modulo CLIPPED,
	      COLUMN 30, fl_justifica_titulo('I', titulo CLIPPED, 60) CLIPPED,
	      COLUMN 77, UPSHIFT(vg_proceso)

	SKIP 1 LINES
	PRINT COLUMN 15, "** Año            : ", 
					fl_justifica_titulo('I', rm_par.anho, 4),
	      COLUMN 51, "** Mes: ", fl_justifica_titulo('I', 
	      				fl_retorna_nombre_mes(rm_par.mes), 10)
	PRINT COLUMN 15, "** Moneda         : ", rm_par.g13_nombre
	
	IF rm_par.tipo_vcto = 'P' THEN
			PRINT COLUMN 15, "** Tipo Vcto.     : Por Vencer"
	ELSE 
		IF rm_par.tipo_vcto = 'V' THEN
			PRINT COLUMN 15, "** Tipo Vcto.     : Vencido"
		ELSE
			PRINT COLUMN 15, "** Tipo Vcto.     : Todos"
		END IF
	END IF
	
	IF rm_par.areaneg IS NOT NULL THEN
		PRINT COLUMN 15, "** Area de Negocio: ", rm_par.n_areaneg
	END IF
	IF rm_par.zona_cobro IS NOT NULL THEN
		PRINT COLUMN 15, "** Zona de Cobro  : ", rm_par.n_zona_cobro
	END IF
	IF rm_par.tipocli IS NOT NULL THEN
		PRINT COLUMN 15, "** Tipo de Cliente: ", rm_par.n_tipocli
	END IF
	IF rm_par.tipocartera IS NOT NULL THEN
		PRINT COLUMN 15, "** Tipo de Cartera: ", rm_par.n_tipocartera
	END IF
	
	SKIP 1 LINES
	PRINT COLUMN 01, "Fecha de Impresión: ", TODAY USING "dd-mm-yyyy", 
	                 1 SPACES, TIME,
	      COLUMN 68, usuario
	
	print '&k2S'	                -- Letra condensada (16 cpi)
	
	PRINT COLUMN 1,   "Area",
	      COLUMN 7,   "Zona",
	      COLUMN 14,  "Cliente",
	      COLUMN 54,  "Documento",
	      COLUMN 80,  "Fecha Emi.",
	      COLUMN 92,  "Fecha Vcto.",
	      COLUMN 104, fl_justifica_titulo('D', "Días", 5),
	      COLUMN 111, fl_justifica_titulo('D', "Saldo", 16)

	PRINT COLUMN 1,   "------",
	      COLUMN 7,   "-------",
	      COLUMN 14,  "----------------------------------------",
	      COLUMN 54,  "--------------------------",
	      COLUMN 80,  "------------",
	      COLUMN 92,  "------------",
	      COLUMN 104, "-------",
	      COLUMN 111, "------------------"

AFTER GROUP OF codcli
	PRINT COLUMN 111, "------------------"
	PRINT COLUMN 10,  ' TOTAL (', nomcli CLIPPED, ')',
	      COLUMN 111, saldo_cli USING "#,###,###,##&.##"
	SKIP 1 LINES

	LET saldo_cli = 0

ON EVERY ROW
	NEED 2 LINES
	
	IF zona_cobro IS NULL THEN
		LET zona_cobro = '  '
	END IF

	PRINT COLUMN 1,   fl_justifica_titulo('D', areaneg, 3),
	      COLUMN 7,   fl_justifica_titulo('D', zona_cobro, 5) CLIPPED,
	      COLUMN 14,  fl_justifica_titulo('D', codcli, 6) CLIPPED, 
	      		  ' ', nomcli,
	      COLUMN 54,  tipo_doc, '-', 
	      		  fl_justifica_titulo('I', num_doc, 15) CLIPPED, '-', 
	      		  fl_justifica_titulo('I', dividendo, 3) USING "&&&",
	      COLUMN 80,  fecha_emi USING "dd-mm-yyyy",
	      COLUMN 92,  fecha_vcto USING "dd-mm-yyyy",
	      COLUMN 104, antiguedad USING "-,--&",
	      COLUMN 111, saldo USING "#,###,###,##&.##"

	LET saldo_cli = saldo_cli + saldo

ON LAST ROW
	NEED 2 LINES
	PRINT COLUMN 111, "------------------"
	PRINT COLUMN 111, SUM(saldo) USING "#,###,###,##&.##", 'E' 

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
	AFTER INPUT
		FOR i = 1 TO num_ord 
			FOR j = 1 TO num_ord  
				IF j <> i AND rm_ord[j].col = rm_ord[i].col THEN
					CALL fgl_winmessage(vg_producto,
						'No puede ordenar dos veces ' ||
						'sobre el mismo campo.',
						'exclamation')
					CONTINUE INPUT
				END IF
			END FOR
		END FOR
END INPUT

END FUNCTION



FUNCTION campos_forma()

LET rm_campos[1].nombre = 'AREA DE NEGOCIO'
LET rm_campos[1].posicion = 1
LET rm_campos[2].nombre = 'NOMBRE CLIENTE'
LET rm_campos[2].posicion = 4
LET rm_campos[3].nombre = 'ZONA DE COBRO'
LET rm_campos[3].posicion = 2
LET rm_campos[4].nombre = 'FECHA DE EMISIÓN'
LET rm_campos[4].posicion = 8
LET rm_campos[5].nombre = 'FECHA DE VENCIMIENTO'
LET rm_campos[5].posicion = 9

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
OPEN WINDOW wh AT 06,15 WITH FORM '../forms/cxcf400_2'
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
