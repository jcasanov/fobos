------------------------------------------------------------------------------
-- Titulo           : cxcp402.4gl - Listado de clientes
-- Elaboracion      : 06-jun-2005
-- Autor            : JCM
-- Formato Ejecucion: fglrun cxcp402 base módulo compañía localidad
-- Ultima Correccion: 
-- Motivo Correccion: 
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE rm_g01		RECORD LIKE gent001.*

DEFINE rm_par RECORD 
	g13_moneda	LIKE gent013.g13_moneda,
	g13_nombre	LIKE gent013.g13_nombre,
	areaneg		LIKE gent003.g03_areaneg,
	n_areaneg	LIKE gent003.g03_nombre,
	tipocli		LIKE gent012.g12_subtipo,
	n_tipocli	LIKE gent012.g12_nombre 
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
CALL startlog('../logs/cxcp402.error')
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
LET vg_proceso = 'cxcp402'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()

END MAIN



FUNCTION funcion_master()

DEFINE r_g13		RECORD LIKE gent013.*

CALL fl_nivel_isolation()

LET vm_top    = 0
LET vm_left   =	2
LET vm_right  =	220
LET vm_bottom =	0
LET vm_page   = 43

CALL fl_lee_moneda(rg_gen.g00_moneda_base) RETURNING r_g13.*
INITIALIZE rm_par.* TO NULL
LET rm_par.g13_moneda = r_g13.g13_moneda
LET rm_par.g13_nombre = r_g13.g13_nombre

OPEN WINDOW w_mas AT 3,2 WITH 6 ROWS, 80 COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE 0, 
		BORDER, MESSAGE LINE LAST - 2)
OPTIONS INPUT WRAP,
	ACCEPT KEY	F12
OPEN FORM f_rep FROM "../forms/cxcf402_1"
DISPLAY FORM f_rep

CALL control_reporte()

END FUNCTION



FUNCTION control_reporte()
DEFINE i,col		SMALLINT
DEFINE query		VARCHAR(1000)
DEFINE comando		VARCHAR(100)
DEFINE data_found	SMALLINT

DEFINE r_det		RECORD 
	codcli		LIKE cxct001.z01_codcli,
	nomcli		LIKE cxct001.z01_nomcli,
	telf1		LIKE cxct001.z01_telefono1,
	telf2		LIKE cxct001.z01_telefono2,
	direccion1	LIKE cxct001.z01_direccion1,
	direccion2	LIKE cxct001.z01_direccion2,
	fax1		LIKE cxct001.z01_fax1,
	fax2		LIKE cxct001.z01_fax2,
	casilla		LIKE cxct001.z01_casilla,
	ciudad		LIKE gent031.g31_nombre,
	tipo_doc	LIKE cxct001.z01_tipo_doc_id,
	num_doc		LIKE cxct001.z01_num_doc_id
END RECORD

INITIALIZE r_det.* TO NULL 

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
	
	LET query = prepare_query_cxct030()
	
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
END INPUT

END FUNCTION



FUNCTION prepare_query_cxct030()

DEFINE query	 	VARCHAR(1000)
DEFINE expr_area	VARCHAR(30)
DEFINE expr_tipocli	VARCHAR(30)
DEFINE expr_vcto	VARCHAR(30)

LET expr_area = ' '
IF rm_par.areaneg IS NOT NULL THEN
	LET expr_area = ' AND z30_areaneg = ', rm_par.areaneg
END IF

LET expr_tipocli = ' '
IF rm_par.tipocli IS NOT NULL THEN
	LET expr_tipocli = ' AND z01_tipo_clte = ', rm_par.tipocli
END IF

CASE rm_par.tipo_vcto 
	WHEN 'P'
		LET expr_vcto = ' AND z30_saldo_xvenc > 0 '
	WHEN 'V'
		LET expr_vcto = ' AND z30_saldo_venc > 0 '
	OTHERWISE
		LET expr_vcto = ' '
END CASE

LET query = 'SELECT z30_codcli, z01_nomcli, z01_telefono1, z01_telefono2, ',
	          ' z01_direccion1, z30_saldo_favor, z30_saldo_venc, ',
	          ' z30_saldo_xvenc ',
	    	' FROM cxct030, cxct001 ', 
	    	' WHERE z30_compania = ', vg_codcia,
	    	  ' AND z30_localidad = ', vg_codloc,
	    	  expr_area CLIPPED, 
	    	  ' AND z30_moneda = "', rm_par.g13_moneda, '"', 
	    	  expr_vcto CLIPPED,
	    	  ' AND z01_codcli = z30_codcli ',
	    	  expr_tipocli CLIPPED,
	  	' ORDER BY 2'
	    	  
RETURN query

END FUNCTION



REPORT rep_cartera(codcli, nomcli, telf1, telf2, direccion, anticipos,
		   saldo_vencido, saldoxvencer)                        

DEFINE codcli		LIKE cxct001.z01_codcli
DEFINE nomcli		LIKE cxct001.z01_nomcli
DEFINE telf1		LIKE cxct001.z01_telefono1
DEFINE telf2		LIKE cxct001.z01_telefono2
DEFINE direccion	LIKE cxct001.z01_direccion1
DEFINE anticipos	LIKE cxct030.z30_saldo_favor
DEFINE saldo_vencido	LIKE cxct030.z30_saldo_venc
DEFINE saldoxvencer	LIKE cxct030.z30_saldo_xvenc

DEFINE telefono		VARCHAR(25,10)

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
	print 'E'; 
	print '&l26A';	-- Indica que voy a trabajar con hojas A4
	print '&l1O';		-- Modo landscape
	print '&k4S'	        -- Letra (12 cpi)

	LET modulo  = "Módulo: Cobranzas"
	LET long    = LENGTH(modulo)
	LET usuario = 'Usuario: ', vg_usuario
	CALL fl_justifica_titulo('D', usuario, 19) RETURNING usuario
	CALL fl_justifica_titulo('C', 'RESUMEN CARTERA POR COBRAR CLIENTES', 60)
		RETURNING titulo
	
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
	IF rm_par.areaneg IS NOT NULL THEN
		PRINT COLUMN 15, "** Area de Negocio: ", rm_par.n_areaneg
	END IF
	IF rm_par.tipocli IS NOT NULL THEN
		PRINT COLUMN 15, "** Tipo de Cliente: ", rm_par.n_tipocli
	END IF
	
	SKIP 1 LINES
	PRINT COLUMN 01, "Fecha de Impresión: ", TODAY USING "dd-mm-yyyy", 
	                 1 SPACES, TIME,
	      COLUMN 106, usuario
	
	print '&k2S'	                -- Letra condensada (16 cpi)

	PRINT COLUMN 1,   "Cliente",
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

	PRINT COLUMN 1,   fl_justifica_titulo('D', codcli, 5), 
   			  ' ', nomcli CLIPPED,
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
				USING "##,###,###,##&.##", 'E'
END REPORT



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
