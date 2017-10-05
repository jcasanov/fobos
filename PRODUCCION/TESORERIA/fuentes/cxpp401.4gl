------------------------------------------------------------------------------
-- Titulo           : cxpp401.4gl - Resumen cartera por pagar proveedores
-- Elaboracion      : 22-ene-2002
-- Autor            : JCM
-- Formato Ejecucion: fglrun cxpp401 base módulo compañía localidad
-- Ultima Correccion: 
-- Motivo Correccion: 
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_demonios	VARCHAR(12)
DEFINE rm_g01		RECORD LIKE gent001.*
DEFINE rm_par RECORD 
	g13_moneda	LIKE gent013.g13_moneda,
	g13_nombre	LIKE gent013.g13_nombre,
	tipoprov	LIKE gent012.g12_subtipo,
	n_tipoprov	LIKE gent012.g12_nombre,
	tipo_vcto	CHAR
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
CALL startlog('../logs/errores')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 THEN          -- Validar # parámetros correcto
	--#CALL fgl_winmessage(vg_producto,'Número de parámetros incorrecto.','stop')
	CALL fl_mostrar_mensaje('Número de parámetros incorrecto.','stop')
	EXIT PROGRAM
END IF
LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_codcia   = arg_val(3)
LET vg_codloc   = arg_val(4)
LET vg_proceso = 'cxpp401'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
--#CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()

END MAIN



FUNCTION funcion_master()
DEFINE r_g13		RECORD LIKE gent013.*
DEFINE lin_menu		SMALLINT
DEFINE row_ini  	SMALLINT
DEFINE num_rows 	SMALLINT
DEFINE num_cols 	SMALLINT

CALL fl_nivel_isolation()

LET vm_top    = 0
LET vm_left   =	2
LET vm_right  =	220
LET vm_bottom =	0
LET vm_page   = 45

CALL fl_lee_moneda(rg_gen.g00_moneda_base) RETURNING r_g13.*
INITIALIZE rm_par.* TO NULL
LET rm_par.g13_moneda = r_g13.g13_moneda
LET rm_par.g13_nombre = r_g13.g13_nombre
LET rm_par.tipo_vcto  = 'T'

LET lin_menu = 0
LET row_ini  = 3
LET num_rows = 9
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
	OPEN FORM f_rep FROM "../forms/cxpf401_1"
ELSE
	OPEN FORM f_rep FROM "../forms/cxpf401_1c"
END IF
DISPLAY FORM f_rep

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
	telf1		LIKE cxpt001.p01_telefono1,
	telf2		LIKE cxpt001.p01_telefono2,
	direccion	LIKE cxpt001.p01_direccion1,
	anticipos	LIKE cxpt030.p30_saldo_favor,
	saldo_vencido	LIKE cxpt030.p30_saldo_venc,
	saldoxvencer	LIKE cxpt030.p30_saldo_xvenc
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
	
	CALL fl_control_reportes() RETURNING comando
	IF int_flag THEN
		CONTINUE WHILE
	END IF
	CALL fl_lee_compania(vg_codcia) RETURNING rm_g01.*
	
	LET query = prepare_query_cxpt030()
	
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
INPUT BY NAME rm_par.g13_moneda, rm_par.tipo_vcto, rm_par.tipoprov
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
	AFTER FIELD tipo_vcto
		IF vg_gui = 0 THEN
			IF rm_par.tipo_vcto IS NOT NULL THEN
				CALL muestra_tipovcto(rm_par.tipo_vcto)
			ELSE
				CLEAR tit_tipo_vcto
			END IF
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
END INPUT

END FUNCTION



FUNCTION prepare_query_cxpt030()
DEFINE query	 	CHAR(1000)
DEFINE expr_tipoprov	VARCHAR(30)
DEFINE expr_vcto	VARCHAR(30)

LET expr_tipoprov = ' '
IF rm_par.tipoprov IS NOT NULL THEN
	LET expr_tipoprov = ' AND p01_tipo_prov = ', rm_par.tipoprov
END IF

CASE rm_par.tipo_vcto 
	WHEN 'P'
		LET expr_vcto = ' AND p30_saldo_xvenc > 0 '
	WHEN 'V'
		LET expr_vcto = ' AND p30_saldo_venc > 0 '
	OTHERWISE
		LET expr_vcto = ' '
END CASE

LET query = 'SELECT p30_codprov, p01_nomprov, p01_telefono1, p01_telefono2, ',
	          ' p01_direccion1, p30_saldo_favor, p30_saldo_venc, ',
	          ' p30_saldo_xvenc ',
	    	' FROM cxpt030, cxpt001 ', 
	    	' WHERE p30_compania = ', vg_codcia,
	    	  ' AND p30_localidad = ', vg_codloc,
	    	  ' AND p30_moneda = "', rm_par.g13_moneda, '"', 
	    	  expr_vcto CLIPPED,
	    	  ' AND p01_codprov = p30_codprov ',
	    	  expr_tipoprov CLIPPED,
	  	' ORDER BY 2'
	    	  
RETURN query

END FUNCTION



REPORT rep_cartera(codprov, nomprov, telf1, telf2, direccion, anticipos,
		   saldo_vencido, saldoxvencer)                        

DEFINE codprov		LIKE cxpt001.p01_codprov
DEFINE nomprov		LIKE cxpt001.p01_nomprov
DEFINE telf1		LIKE cxpt001.p01_telefono1
DEFINE telf2		LIKE cxpt001.p01_telefono2
DEFINE direccion	CHAR(40)
DEFINE anticipos	LIKE cxpt030.p30_saldo_favor
DEFINE saldo_vencido	LIKE cxpt030.p30_saldo_venc
DEFINE saldoxvencer	LIKE cxpt030.p30_saldo_xvenc
DEFINE telefono		VARCHAR(25,10)
DEFINE usuario		VARCHAR(19,15)
DEFINE titulo		VARCHAR(80)
DEFINE modulo		VARCHAR(40)
DEFINE i,long		SMALLINT

OUTPUT
	TOP    MARGIN	0
	LEFT   MARGIN	2
	RIGHT  MARGIN	220
	BOTTOM MARGIN	0
	PAGE   LENGTH	45

FORMAT
PAGE HEADER
	--#print 'E'; 
	--#print '&l26A';	-- Indica que voy a trabajar con hojas A4
	--#print '&l1O';		-- Modo landscape
	--#print '&k4S'	        -- Letra (12 cpi)

	LET modulo  = "Módulo: Tesorería"
	LET long    = LENGTH(modulo)
	LET usuario = 'Usuario: ', vg_usuario
	CALL fl_justifica_titulo('D', usuario, 19) RETURNING usuario
	CALL fl_justifica_titulo('C', 'RESUMEN CARTERA POR PAGAR PROVEEDORES', 
		60) RETURNING titulo
	
	PRINT COLUMN 1, rm_g01.g01_razonsocial,
	      COLUMN 115, "Página: ", PAGENO USING "&&&"
	PRINT COLUMN 1, modulo CLIPPED,
	      COLUMN 35, titulo CLIPPED,
	      COLUMN 115, UPSHIFT(vg_proceso)
      
	SKIP 1 LINES
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
	--#IF rm_par.tipoprov IS NOT NULL THEN
		PRINT COLUMN 15, "** Tipo de Proveedor: ", rm_par.n_tipoprov
	--#END IF
	
	SKIP 1 LINES
	PRINT COLUMN 01, "Fecha de Impresión: ", vg_fecha USING "dd-mm-yyyy", 
	                 1 SPACES, TIME,
	      COLUMN 106, usuario

	--#print '&k2S'	                -- Letra condensada (16 cpi)

	PRINT COLUMN 1,   "Proveedor",
	      COLUMN 48,  "Teléfono",
	      COLUMN 73,  "Dirección",
	      COLUMN 115, fl_justifica_titulo('D', "Anticipos", 16),
	      COLUMN 133, fl_justifica_titulo('D', "Saldo Vencido", 16),
	      COLUMN 152, fl_justifica_titulo('D', "Saldo X Vencer", 16),
	      COLUMN 170, fl_justifica_titulo('D', "Saldo X Cobrar", 17)

	PRINT COLUMN 1,   "-----------------------------------------------",
	      COLUMN 48,  "-------------------------",
	      COLUMN 73,  "-------------------------------------------",
	      COLUMN 115, "------------------",
	      COLUMN 133, "------------------",
	      COLUMN 152, "------------------",
	      COLUMN 170, "-------------------"

ON EVERY ROW
	IF telf1 IS NOT NULL THEN
		LET telefono = telf1
	END IF
	IF telf2 IS NOT NULL THEN
		LET telefono = telefono CLIPPED || ' - ' || telf2
	END IF

	PRINT COLUMN 1,   fl_justifica_titulo('D', codprov, 5), 
   			  ' ', nomprov CLIPPED,
	      COLUMN 48,  fl_justifica_titulo('I', telefono, 23),
	      COLUMN 73,  direccion,
	      COLUMN 115, anticipos     USING "#,###,###,##&.##",
	      COLUMN 133, saldo_vencido USING "#,###,###,##&.##",
	      COLUMN 152, saldoxvencer  USING "#,###,###,##&.##",
	      COLUMN 170, (saldo_vencido + saldoxvencer) 
				USING "##,###,###,##&.##"

ON LAST ROW
	NEED 2 LINES
	PRINT COLUMN 115, "-------------------",
	      COLUMN 133, "-------------------",
	      COLUMN 152, "-------------------",
	      COLUMN 170, "------------------"

	PRINT COLUMN 115, SUM(anticipos)     USING "#,###,###,##&.##",
	      COLUMN 133, SUM(saldo_vencido) USING "#,###,###,##&.##",
	      COLUMN 152, SUM(saldoxvencer)  USING "#,###,###,##&.##",
	      COLUMN 170, SUM(saldo_vencido + saldoxvencer) 
				USING "##,###,###,##&.##"
				--#, 'E'
END REPORT



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
