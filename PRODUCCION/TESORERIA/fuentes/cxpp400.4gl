------------------------------------------------------------------------------
-- Titulo           : cxpp400.4gl - Listado de cartera por pagar
-- Elaboracion      : 16-ene-2002
-- Autor            : JCM
-- Formato Ejecucion: fglrun cxpp400 base módulo compañía localidad
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
	tipoprov	LIKE gent012.g12_subtipo,
	n_tipoprov	LIKE gent012.g12_nombre,
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
CALL startlog('../logs/cxpp400.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 THEN          -- Validar # parámetros correcto
	--CALL fgl_winmessage(vg_producto,'Número de parámetros incorrecto','stop')
	CALL fl_mostrar_mensaje('Número de parámetros incorrecto.','stop')
	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_codloc  = arg_val(4)
LET vg_proceso = 'cxpp400'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
--#CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()

END MAIN



FUNCTION funcion_master()
DEFINE i		SMALLINT
DEFINE r_g13		RECORD LIKE gent013.*
DEFINE lin_menu		SMALLINT
DEFINE row_ini  	SMALLINT
DEFINE num_rows 	SMALLINT
DEFINE num_cols 	SMALLINT

CALL fl_nivel_isolation()

LET vm_top    = 1
LET vm_left   =	2
LET vm_right  =	132
LET vm_bottom =	2
LET vm_page   = 66

CALL campos_forma()

CALL fl_lee_moneda(rg_gen.g00_moneda_base) RETURNING r_g13.*
INITIALIZE rm_par.* TO NULL
LET rm_par.anho       = YEAR(vg_fecha)
LET rm_par.mes        = MONTH(vg_fecha)
LET rm_par.g13_moneda = r_g13.g13_moneda
LET rm_par.g13_nombre = r_g13.g13_nombre
LET rm_par.tipo_vcto  = 'T'

LET num_ord = 2
LET rm_ord[1].col      = rm_campos[1].nombre
LET rm_ord[2].col      = rm_campos[2].nombre

LET lin_menu = 0
LET row_ini  = 3
LET num_rows = 14
LET num_cols = 80
IF vg_gui = 0 THEN
	LET lin_menu = 1
	LET row_ini  = 4
	LET num_rows = 20
	LET num_cols = 78
END IF
OPEN WINDOW w_mas AT row_ini, 2 WITH num_rows ROWS, num_cols COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE lin_menu,
		  MESSAGE LINE LAST - 1, BORDER) 
IF vg_gui = 1 THEN
	OPEN FORM f_rep FROM "../forms/cxpf400_1"
ELSE
	OPEN FORM f_rep FROM "../forms/cxpf400_1c"
END IF
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
DEFINE query		CHAR(1000)
DEFINE comando		VARCHAR(100)
DEFINE data_found	SMALLINT

DEFINE r_det		RECORD 
	codprov		LIKE cxpt001.p01_codprov,
	nomprov		LIKE cxpt001.p01_nomprov,
	numero_oc	LIKE ordt010.c10_numero_oc,
	tipo_doc	LIKE cxpt020.p20_tipo_doc,
	num_doc		LIKE cxpt020.p20_num_doc,
	dividendo	LIKE cxpt020.p20_dividendo,
	fecha_emi	LIKE cxpt020.p20_fecha_emi,
	fecha_vcto	LIKE cxpt020.p20_fecha_vcto,
	antiguedad	INTEGER,
	saldo		LIKE cxpt020.p20_saldo_cap
END RECORD

INITIALIZE r_det.* TO NULL 

DISPLAY BY NAME rm_par.*
IF vg_gui = 0 THEN
	CALL muestra_tipovcto(rm_par.tipo_vcto)
END IF
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
	
	IF year(vg_fecha) <> rm_par.anho OR month(vg_fecha) <> rm_par.mes THEN
		LET query = prepare_query_cxpt050()
	ELSE
		LET query = prepare_query_cxpt020()
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
DEFINE r_g12		RECORD LIKE gent012.*
DEFINE r_g13		RECORD LIKE gent013.*

LET INT_FLAG   = 0
INPUT BY NAME rm_par.anho, rm_par.mes, rm_par.g13_moneda, rm_par.tipoprov,
	rm_par.tipo_vcto, rm_par.dias_ini, rm_par.dias_fin
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		LET INT_FLAG = 1 
		RETURN
        ON KEY(F1,CONTROL-W)
		CALL llamar_visor_teclas()
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
		IF INFIELD(tipoprov) THEN
			CALL fl_ayuda_subtipo_entidad('TP') 
					RETURNING r_g12.g12_tiporeg,
						  r_g12.g12_subtipo,
						  r_g12.g12_nombre,
						  dummy
			IF r_g12.g12_subtipo IS NOT NULL THEN
				LET rm_par.tipoprov   = r_g12.g12_subtipo
				LET rm_par.n_tipoprov = r_g12.g12_nombre
				DISPLAY BY NAME rm_par.*
			END IF
		END IF
		LET INT_FLAG = 0
	BEFORE INPUT
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
	AFTER FIELD g13_moneda
		IF rm_par.g13_moneda IS NOT NULL THEN
			CALL fl_lee_moneda(rm_par.g13_moneda) RETURNING r_g13.*
			IF r_g13.g13_moneda IS NULL THEN
				--CALL fgl_winmessage(vg_producto,'Moneda no existe.','exclamation')
				CALL fl_mostrar_mensaje('Moneda no existe.','exclamation')
				NEXT FIELD g13_moneda
			END IF
			LET rm_par.g13_nombre = r_g13.g13_nombre
			DISPLAY BY NAME rm_par.g13_nombre
		ELSE
			LET rm_par.g13_nombre = NULL
			CLEAR g13_nombre
		END IF
	AFTER FIELD tipoprov
		IF rm_par.tipoprov IS NOT NULL THEN
			CALL fl_lee_subtipo_entidad('TP', rm_par.tipoprov)
				RETURNING r_g12.*
			IF r_g12.g12_subtipo IS NULL THEN
				--CALL fgl_winmessage(vg_producto,'Tipo proveedor no existe.','exclamation')
				CALL fl_mostrar_mensaje('Tipo proveedor no existe.','exclamation')
				NEXT FIELD tipoprov
			END IF
			LET rm_par.n_tipoprov = r_g12.g12_nombre
			DISPLAY BY NAME rm_par.n_tipoprov
		ELSE
			LET rm_par.n_tipoprov = NULL
			CLEAR n_tipoprov
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
	AFTER FIELD tipo_vcto
		IF vg_gui = 0 THEN
			IF rm_par.tipo_vcto IS NOT NULL THEN
				CALL muestra_tipovcto(rm_par.tipo_vcto)
			ELSE
				CLEAR tit_tipo_vcto
			END IF
		END IF
	AFTER INPUT
		IF rm_par.dias_ini IS NOT NULL AND rm_par.dias_fin IS NULL THEN
			--CALL fgl_winmessage(vg_producto,'Si ingresa un rango de días debe ingresar ambos valores.','exclamation')
			CALL fl_mostrar_mensaje('Si ingresa un rango de días debe ingresar ambos valores.','exclamation')
			CONTINUE INPUT
		END IF
		IF rm_par.dias_fin IS NOT NULL AND rm_par.dias_ini IS NULL THEN
			--CALL fgl_winmessage(vg_producto,'Si ingresa un rango de días debe ingresar ambos valores.','exclamation')
			CALL fl_mostrar_mensaje('Si ingresa un rango de días debe ingresar ambos valores.','exclamation')
			CONTINUE INPUT
		END IF
END INPUT

END FUNCTION



FUNCTION prepare_query_cxpt050()
DEFINE query	 	CHAR(1100)
DEFINE expr_tipoprov	VARCHAR(30)
DEFINE expr_vcto	VARCHAR(30)
DEFINE expr_dias	VARCHAR(60)

LET expr_tipoprov = ' '
IF rm_par.tipoprov IS NOT NULL THEN
	LET expr_tipoprov = ' AND p01_tipo_prov = ', rm_par.tipoprov
END IF

CASE rm_par.tipo_vcto 
	WHEN 'P'
		LET expr_vcto = ' AND p50_fecha_vcto >= "', vg_fecha, '" '
		IF rm_par.dias_ini IS NOT NULL THEN
			LET expr_dias = ' AND (p50_fecha_vcto - "', vg_fecha, '") BETWEEN ',
					rm_par.dias_ini, ' AND ', rm_par.dias_fin
		END IF
	WHEN 'V'
		LET expr_vcto = ' AND p50_fecha_vcto < "', vg_fecha, '" '
		IF rm_par.dias_ini IS NOT NULL THEN
			LET expr_dias = ' AND ("', vg_fecha, '" - p50_fecha_vcto) BETWEEN ',
					rm_par.dias_ini, ' AND ', rm_par.dias_fin
		END IF
	OTHERWISE
		LET expr_vcto = ' '
		LET expr_dias = ' '
END CASE

LET query = 'SELECT p50_codprov, p01_nomprov, p50_numero_oc, ',
	          ' p50_tipo_doc, p50_num_doc, p50_dividendo, p50_fecha_emi, ',
	          ' p50_fecha_vcto, (p50_fecha_vcto - "', vg_fecha, '"), ',
	          ' (p50_saldo_cap + p50_saldo_int) ',
	    	' FROM cxpt050, cxpt001 ', 
	    	' WHERE p50_ano = ', rm_par.anho,
	    	  ' AND p50_mes = ', rm_par.mes,
	    	  ' AND p50_compania = ', vg_codcia,
	    	  ' AND p50_localidad = ', vg_codloc,
	    	  ' AND p50_moneda = "', rm_par.g13_moneda, '"', 
	    	  expr_vcto CLIPPED,
	    	  expr_dias CLIPPED,
	    	  ' AND p01_codprov = p50_codprov ',
	    	  expr_tipoprov CLIPPED
	    	  
RETURN full_query(query)

END FUNCTION



FUNCTION prepare_query_cxpt020()
DEFINE query	 	CHAR(1000)
DEFINE expr_tipoprov	VARCHAR(30)
DEFINE expr_vcto	VARCHAR(30)
DEFINE expr_dias	VARCHAR(60)

LET expr_tipoprov = ' '
IF rm_par.tipoprov IS NOT NULL THEN
	LET expr_tipoprov = ' AND p01_tipo_prov = ', rm_par.tipoprov
END IF

CASE rm_par.tipo_vcto 
	WHEN 'P'
		LET expr_vcto = ' AND p20_fecha_vcto >= "', vg_fecha, '" '
		IF rm_par.dias_ini IS NOT NULL THEN
			LET expr_dias = ' AND (p20_fecha_vcto - "', vg_fecha, '") BETWEEN ',
					rm_par.dias_ini, ' AND ', rm_par.dias_fin
		END IF
	WHEN 'V'
		LET expr_vcto = ' AND p20_fecha_vcto < "', vg_fecha, '" '
		IF rm_par.dias_ini IS NOT NULL THEN
			LET expr_dias = ' AND ("', vg_fecha, '" - p20_fecha_vcto) BETWEEN ',
					rm_par.dias_ini, ' AND ', rm_par.dias_fin
		END IF
	OTHERWISE
		LET expr_vcto = ' '
		LET expr_dias = ' '
END CASE

LET query = 'SELECT p20_codprov, p01_nomprov, p20_numero_oc, ',
	          ' p20_tipo_doc, p20_num_doc, p20_dividendo, p20_fecha_emi, ',
	          ' p20_fecha_vcto, (p20_fecha_vcto - "', vg_fecha, '") antiguedad, ',
	          ' (p20_saldo_cap + p20_saldo_int) saldo ',
	    	' FROM cxpt020, cxpt001 ', 
	    	' WHERE p20_compania = ', vg_codcia,
	    	  ' AND p20_localidad = ', vg_codloc,
	    	  ' AND p20_moneda = "', rm_par.g13_moneda, '"', 
	    	  expr_vcto CLIPPED,
	    	  expr_dias CLIPPED,
	    	  ' AND p01_codprov = p20_codprov ',
	    	  expr_tipoprov CLIPPED
	    	  
RETURN full_query(query)

END FUNCTION



FUNCTION full_query(query)
DEFINE query		CHAR(1000)
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

LET query = query CLIPPED || order_clause CLIPPED

RETURN query

END FUNCTION



REPORT rep_cartera(codprov, nomprov, numero_oc, tipo_doc, num_doc,
		   dividendo, fecha_emi, fecha_vcto, antiguedad, saldo)

DEFINE codprov		LIKE cxpt001.p01_codprov
DEFINE nomprov		LIKE cxpt001.p01_nomprov
DEFINE numero_oc	LIKE ordt010.c10_numero_oc
DEFINE tipo_doc		LIKE cxpt020.p20_tipo_doc
DEFINE num_doc		LIKE cxpt020.p20_num_doc
DEFINE dividendo	LIKE cxpt020.p20_dividendo
DEFINE fecha_emi	LIKE cxpt020.p20_fecha_emi
DEFINE fecha_vcto	LIKE cxpt020.p20_fecha_vcto
DEFINE antiguedad	SMALLINT
DEFINE saldo		LIKE cxpt020.p20_saldo_cap
DEFINE usuario		VARCHAR(19,15)
DEFINE titulo		VARCHAR(80)
DEFINE modulo		VARCHAR(40)
DEFINE i,long		SMALLINT

OUTPUT
	TOP    MARGIN	1
	LEFT   MARGIN	2
	RIGHT  MARGIN	132
	BOTTOM MARGIN	2
	PAGE   LENGTH	66

FORMAT
PAGE HEADER
	--#print 'E'; --#print '&l26A';	-- Indica que voy a trabajar con hojas A4
	--#print '&k4S'	                -- Letra (12 cpi)
	LET modulo  = "Módulo: Tesorería"
	LET long    = LENGTH(modulo)
	LET usuario = 'Usuario: ', vg_usuario
	CALL fl_justifica_titulo('D', usuario, 19) RETURNING usuario
	CALL fl_justifica_titulo('C', 'LISTADO DETALLE DE CARTERA POR PAGAR', 60)
		RETURNING titulo
	
	PRINT COLUMN 1, rm_g01.g01_razonsocial,
	      COLUMN 77, "Página: ", PAGENO USING "&&&"
	PRINT COLUMN 1, modulo CLIPPED,
	      COLUMN 30, fl_justifica_titulo('I', titulo CLIPPED, 60) CLIPPED,
	      COLUMN 77, UPSHIFT(vg_proceso)
      
	SKIP 1 LINES
	PRINT COLUMN 15, "** Año              : ", 
                         fl_justifica_titulo('I', rm_par.anho, 4),
	      COLUMN 51, "** Mes: ", fl_justifica_titulo('I', 
	      		 	fl_retorna_nombre_mes(rm_par.mes), 10)
	PRINT COLUMN 15, "** Moneda           : ", rm_par.g13_nombre
	
	IF rm_par.tipo_vcto = 'P' THEN
			PRINT COLUMN 15, "** Tipo Vcto.       : Por Vencer"
	ELSE 
		IF rm_par.tipo_vcto = 'V' THEN
			PRINT COLUMN 15, "** Tipo Vcto.       : Vencido"
		ELSE
			PRINT COLUMN 15, "** Tipo Vcto.       : Todos"
		END IF
	END IF
	
	--#IF rm_par.tipoprov IS NOT NULL THEN
		PRINT COLUMN 15, "** Tipo de Proveedor: ", rm_par.n_tipoprov
	--#END IF
	
	SKIP 1 LINES
	PRINT COLUMN 01, "Fecha de Impresión: ", vg_fecha USING "dd-mm-yyyy", 
	                 1 SPACES, TIME,
	      COLUMN 68, usuario

	--#print '&k2S'	                -- Letra condensada (16 cpi)
	
	PRINT COLUMN 1,   "Proveedor",
	      COLUMN 44,  "Ord. C.",
	      COLUMN 52,  "Documento",
	      COLUMN 76,  "Fecha Emi.",
	      COLUMN 88,  "Fecha Vcto.",
	      COLUMN 100, fl_justifica_titulo('D', "Días", 10),
	      COLUMN 112, fl_justifica_titulo('D', "Saldo", 16)

	PRINT COLUMN 1,   "-------------------------------------------",
	      COLUMN 44,  "--------",
	      COLUMN 52,  "------------------------",
	      COLUMN 76,  "------------",
	      COLUMN 88,  "------------",
	      COLUMN 100, "------------",
	      COLUMN 112, "----------------"

ON EVERY ROW
	PRINT COLUMN 1,   fl_justifica_titulo('D', codprov, 6) CLIPPED,
			  ' ', fl_justifica_titulo('I', nomprov, 35) CLIPPED,
	      COLUMN 44,  fl_justifica_titulo('D', numero_oc, 6) CLIPPED,
	      COLUMN 52,  tipo_doc, '-', 
	      		  fl_justifica_titulo('I', num_doc, 15) CLIPPED, '-', 
	      		  fl_justifica_titulo('I', dividendo, 3) USING "&&&",
	      COLUMN 76,  fecha_emi USING "dd-mm-yyyy",
	      COLUMN 88,  fecha_vcto USING "dd-mm-yyyy",
	      COLUMN 100, antiguedad USING "--,---,--&",
	      COLUMN 112, saldo USING "#,###,###,##&.##"

ON LAST ROW
	NEED 2 LINES
	PRINT COLUMN 112, "------------------"
	PRINT COLUMN 112, SUM(saldo) USING "#,###,###,##&.##"
			--#, 'E' 

END REPORT



FUNCTION ordenar_por()
DEFINE i		SMALLINT
DEFINE j		SMALLINT
DEFINE asc_ant		CHAR
DEFINE desc_ant		CHAR
DEFINE campo		VARCHAR(20)
DEFINE col_ant		VARCHAR(20)

OPTIONS 
	INSERT KEY F57,
	DELETE KEY F58

CALL set_count(num_ord)
INPUT ARRAY rm_ord WITHOUT DEFAULTS FROM rm_ord.* 
        ON KEY(F1,CONTROL-W)
		CALL llamar_visor_teclas()
	ON KEY(F2) 
		IF INFIELD(col) THEN
			CALL ayuda_campos() RETURNING campo
			IF campo IS NOT NULL THEN
				LET rm_ord[i].col = campo
				DISPLAY rm_ord[i].col TO rm_ord[i].col
			END IF
		END IF
	BEFORE INPUT
		--#CALL dialog.keysetlabel('INSERT', '')
		--#CALL dialog.keysetlabel('DELETE', '')
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
	BEFORE ROW
		LET i = arr_curr()
	AFTER FIELD col
		IF rm_ord[i].col IS NULL THEN
			--CALL fgl_winmessage(vg_producto,'Debe elegir una columna.','exclamation')
			CALL fl_mostrar_mensaje('Debe elegir una columna.','exclamation')
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
			--CALL fgl_winmessage(vg_producto,'Campo no existe.','exclamation')
			CALL fl_mostrar_mensaje('Campo no existe.','exclamation')
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
					--CALL fgl_winmessage(vg_producto,'No puede ordenar dos veces sobre el mismo campo.','exclamation')
					CALL fl_mostrar_mensaje('No puede ordenar dos veces sobre el mismo campo.','exclamation')
					CONTINUE INPUT
				END IF
			END FOR
		END FOR
END INPUT

END FUNCTION



FUNCTION campos_forma()

LET rm_campos[1].nombre = 'NOMBRE PROVEEDOR'
LET rm_campos[1].posicion = 2
LET rm_campos[2].nombre = 'FECHA DE EMISIÓN'
LET rm_campos[2].posicion = 7
LET rm_campos[3].nombre = 'FECHA DE VENCIMIENTO'
LET rm_campos[3].posicion = 8

LET num_campos = 3

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
OPEN WINDOW wh AT 06, 15 WITH 08 ROWS, 25 COLUMNS
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST -1, MESSAGE LINE LAST,
                   BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_400_2 FROM '../forms/cxpf400_2'
ELSE
	OPEN FORM f_400_2 FROM '../forms/cxpf400_2c'
END IF
DISPLAY FORM f_400_2
LET filas_pant = fgl_scr_size("rh_campos")

CALL set_count(num_campos)
LET int_flag = 0
DISPLAY ARRAY rh_campos TO rh_campos.*
        ON KEY(RETURN)
                EXIT DISPLAY
        ON KEY(F1,CONTROL-W)
		CALL llamar_visor_teclas()
	--#BEFORE DISPLAY
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
	--#BEFORE ROW
		--#LET j = arr_curr()
		--#MESSAGE  j, ' de ', num_campos
END DISPLAY
CLOSE WINDOW wh
IF int_flag THEN
        INITIALIZE rh_campos[1] TO NULL
        RETURN rh_campos[1]
END IF
LET  i = arr_curr()
RETURN rh_campos[i]

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



FUNCTION muestra_tipovcto(tipovcto)
DEFINE tipovcto		CHAR(1)

CASE tipovcto
	WHEN 'P'
		DISPLAY 'POR VENCER' TO tit_tipo_vcto
	WHEN 'V'
		DISPLAY 'VENCIDOS' TO tit_tipo_vcto
	WHEN 'T'
		DISPLAY 'T O D O S' TO tit_tipo_vcto
	OTHERWISE
		CLEAR tipo_vcto, tit_tipo_vcto
END CASE

END FUNCTION
