------------------------------------------------------------------------------
-- Titulo           : cajp405.4gl - Egresos de Caja
-- Elaboracion      : 14-ene-2002
-- Autor            : JCM
-- Formato Ejecucion: fglrun cajp402 base módulo compañía localidad
-- Ultima Correccion: 24-JUL-2002 
-- Motivo Correccion: Se adpata 402 para egresos de caja (RCA) 
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_egreso	LIKE cajt010.j10_tipo_fuente
DEFINE vm_cheque	LIKE cajt011.j11_codigo_pago
DEFINE vm_efectivo	LIKE cajt011.j11_codigo_pago

DEFINE rm_g01		RECORD LIKE gent001.*

DEFINE rm_par RECORD 
	fecha_ini	DATE,
	fecha_fin	DATE,
	codigo_caja	LIKE cajt002.j02_codigo_caja,
	n_caja		LIKE cajt002.j02_nombre_caja,
	areaneg		LIKE gent003.g03_areaneg,
	n_areaneg	LIKE gent003.g03_nombre
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
CALL startlog('../logs/cajp405.error')
CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4  THEN   		-- Validar # parámetros correcto
	CALL fgl_winmessage(vg_producto, 
		'Número de parámetros incorrecto.', 
		'stop')
	EXIT PROGRAM
END IF
LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_codcia   = arg_val(3)
LET vg_codloc   = arg_val(4)
LET vg_proceso = 'cajp405'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	

CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)

CALL funcion_master()

END MAIN



FUNCTION funcion_master()

CALL fl_nivel_isolation()

LET vm_top    = 1
LET vm_left   =	2
LET vm_right  =	90
LET vm_bottom =	4
LET vm_page   = 43

LET vm_egreso   = 'EC'
LET vm_cheque   = 'CH'
LET vm_efectivo = 'EF'

OPEN WINDOW w_mas AT 3,2 WITH 08 ROWS, 80 COLUMNS
 	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE 0, 
		BORDER, MESSAGE LINE LAST - 2)
OPTIONS INPUT WRAP,
	ACCEPT KEY	F12
OPEN FORM f_rep FROM "../forms/cajf402_1"
DISPLAY FORM f_rep

CALL control_reporte()

END FUNCTION



FUNCTION control_reporte()
DEFINE i,col		SMALLINT
DEFINE query		VARCHAR(2100)
DEFINE comando		VARCHAR(100)
DEFINE data_found	SMALLINT
DEFINE expr_caja	VARCHAR(100)
DEFINE expr_area	VARCHAR(100)

DEFINE r_det RECORD
	j10_fecha_pro		DATE,
	g03_nombre		LIKE gent003.g03_nombre,
	j10_estado		LIKE cajt010.j10_estado,
	j10_tipo_fuente		LIKE cajt010.j10_tipo_fuente,
	j10_num_fuente		LIKE cajt010.j10_num_fuente,
	cliente			VARCHAR(30),
	j10_tipo_destino	LIKE cajt010.j10_tipo_destino,
	j10_num_destino		LIKE cajt010.j10_num_destino,
	j10_moneda		LIKE cajt010.j10_moneda,
	j10_valor		LIKE cajt010.j10_valor,
	j11_codigo_pago		LIKE cajt011.j11_codigo_pago,
	j11_cod_bco_tarj	LIKE cajt011.j11_cod_bco_tarj,
	j11_num_ch_aut		LIKE cajt011.j11_num_ch_aut,
	j11_num_cta_tarj	LIKE cajt011.j11_num_cta_tarj,
	j11_moneda		LIKE cajt011.j11_moneda,
	j11_valor		LIKE cajt011.j11_valor
END RECORD

INITIALIZE rm_par.* TO NULL

LET rm_par.fecha_ini = TODAY
LET rm_par.fecha_fin = TODAY

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
	
	LET expr_caja = ' '
	IF rm_par.codigo_caja IS NOT NULL THEN
		LET expr_CAJA = ' AND j10_codigo_caja = ', rm_par.codigo_caja
	END IF
	LET expr_area = ' '
	IF rm_par.areaneg IS NOT NULL THEN
		LET expr_caja = ' AND j10_areaneg = ', rm_par.areaneg
	END IF
 
	LET query = 'SELECT DATE(j10_fecha_pro), g03_nombre, ',
		          ' j10_estado, j10_tipo_fuente, j10_num_fuente, ',
		          ' j10_referencia, j10_tipo_destino, j10_num_destino,',
                          ' j10_moneda, (j11_valor * (-1)), j11_codigo_pago, ',
		    	  ' j11_cod_bco_tarj, j11_num_ch_aut, j11_num_cta_tarj,',
		          ' j11_moneda, (j11_valor * (-1))',
		      ' FROM cajt010, cajt011, OUTER gent003 ',
                      ' WHERE j10_compania    = ', vg_codcia, 
		        ' AND j10_localidad   = ', vg_codloc,
		        ' AND j10_tipo_fuente = "', vm_egreso, '" ',
		        ' AND j10_estado <> "E" ',
		        expr_area CLIPPED,
		        ' AND DATE(j10_fecha_pro) ',
		              ' BETWEEN "', rm_par.fecha_ini, '" AND "', 
		                            rm_par.fecha_fin, '" ',
		        expr_caja CLIPPED, 
		        ' AND g03_compania    = j10_compania ', 
		        ' AND g03_areaneg     = j10_areaneg ',
		        ' AND j11_compania    = j10_compania ',
		        ' AND j11_localidad   = j10_localidad ',
		        ' AND j11_num_egreso  = j10_num_fuente ',
		    'UNION ALL ',
		    'SELECT DATE(j10_fecha_pro), g03_nombre, ',
		          ' j10_estado, j10_tipo_fuente, j10_num_fuente, ',
		          ' j10_referencia, j10_tipo_destino, j10_num_destino,',
                          ' j10_moneda, (j10_valor * (-1)), "', vm_efectivo, '", ',
		    	  ' -1, " ", " ", j10_moneda, (j10_valor * (-1))',
		      ' FROM cajt010, OUTER gent003 ',
                      ' WHERE j10_compania    = ', vg_codcia, 
		        ' AND j10_localidad   = ', vg_codloc,
		        ' AND j10_tipo_fuente = "', vm_egreso, '" ',
		        ' AND j10_estado <> "E" ',
		        expr_area CLIPPED,
		        ' AND DATE(j10_fecha_pro) ',
		              ' BETWEEN "', rm_par.fecha_ini, '" AND "', 
		                            rm_par.fecha_fin, '" ',
		        expr_caja CLIPPED, 
		        ' AND g03_compania    = j10_compania ', 
		        ' AND g03_areaneg     = j10_areaneg ', 
		        ' ORDER BY 1 ' 
	PREPARE deto FROM query
	DECLARE q_deto CURSOR FOR deto
	LET data_found = 0
	
	START REPORT rep_caja TO PIPE comando
	FOREACH q_deto INTO r_det.*
		LET data_found = 1
		IF r_det.j11_cod_bco_tarj = -1 THEN
			INITIALIZE r_det.j11_cod_bco_tarj TO NULL
		END IF
		OUTPUT TO REPORT rep_caja(r_det.*)
	END FOREACH
	FREE q_deto
	FINISH REPORT rep_caja
	
	IF NOT data_found THEN
		CALL fl_mensaje_consulta_sin_registros()
	END IF
		
END WHILE

END FUNCTION



FUNCTION lee_parametros()

DEFINE r_j02		RECORD LIKE cajt002.*
DEFINE r_g03		RECORD LIKE gent003.*
DEFINE i,j,l,col	SMALLINT

LET INT_FLAG   = 0
INPUT BY NAME rm_par.* WITHOUT DEFAULTS

	ON KEY(INTERRUPT)
		IF NOT FIELD_TOUCHED(codigo_caja, areaneg, fecha_ini, fecha_fin)
		THEN
			EXIT PROGRAM
		END IF
		LET INT_FLAG = 1 
		RETURN

	ON KEY(F2)
		IF INFIELD(codigo_caja) THEN
			CALL fl_ayuda_cajas(vg_codcia, vg_codloc) 
					RETURNING r_j02.j02_codigo_caja,
					  	  r_j02.j02_nombre_caja
			IF r_j02.j02_codigo_caja IS NOT NULL THEN
				LET rm_par.codigo_caja = r_j02.j02_codigo_caja
				LET rm_par.n_caja      = r_j02.j02_nombre_caja
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
		LET INT_FLAG = 0

	AFTER FIELD codigo_caja
		IF rm_par.codigo_caja IS NOT NULL THEN
			CALL fl_lee_codigo_caja_caja(vg_codcia, vg_codloc,
				rm_par.codigo_caja) RETURNING r_j02.* 
			IF r_j02.j02_codigo_caja IS NULL THEN
				CALL fgl_winmessage(vg_producto,
						    'Código caja no existe.',
						    'exclamation')
				CLEAR n_caja
				NEXT FIELD codigo_caja
			END IF
			LET rm_par.n_caja = r_j02.j02_nombre_caja
			DISPLAY BY NAME rm_par.n_caja
		ELSE
			CLEAR n_caja
			LET rm_par.n_caja = NULL
		END IF
		
	AFTER FIELD areaneg
		IF rm_par.areaneg IS NOT NULL THEN
			CALL fl_lee_area_negocio(vg_codcia, rm_par.areaneg) 
				RETURNING r_g03.* 
			IF r_g03.g03_areaneg IS NULL THEN
				CALL fgl_winmessage(vg_producto,
						    'Area de negocio no existe.',
						    'exclamation')
				CLEAR n_areaneg
				NEXT FIELD areaneg
			END IF
			LET rm_par.n_areaneg = r_g03.g03_nombre
			DISPLAY BY NAME rm_par.n_areaneg
		ELSE
			CLEAR n_areaneg
			LET rm_par.n_areaneg = NULL
		END IF

	AFTER FIELD fecha_ini
		IF rm_par.fecha_ini IS NOT NULL THEN
			IF rm_par.fecha_ini > TODAY THEN
				CALL fgl_winmessage(vg_producto,
					'La fecha de inicio no puede ser ' ||
					'mayor a la de hoy.',
					'exclamation')
				NEXT FIELD fecha_ini
			END IF
			IF rm_par.fecha_ini < '01-01-1990' THEN
				CALL fgl_winmessage(vg_producto,
					'Debe ingresa fechas mayores a las ' ||
					'del año 1989.',
					'exclamation')	
				NEXT FIELD fecha_ini
			END IF
				
		ELSE 
			NEXT FIELD fecha_ini
		END IF

	AFTER FIELD fecha_fin
		IF rm_par.fecha_fin IS NOT NULL THEN
			IF rm_par.fecha_fin > TODAY THEN
				CALL fgl_winmessage(vg_producto,
					'La fecha de término no puede ser ' || 
					'mayor a la de hoy.',
					'exclamation')
				NEXT FIELD fecha_fin
			END IF
			IF rm_par.fecha_fin < '01-01-1990' THEN
				CALL fgl_winmessage(vg_producto,
					'Debe ingresa fechas mayores a las ' ||
					'del año 1989.',
					'exclamation')	
				NEXT FIELD fecha_fin
			END IF
		ELSE
			NEXT FIELD fecha_fin
		END IF

	AFTER INPUT
		IF rm_par.fecha_ini > rm_par.fecha_fin THEN
			CALL fgl_winmessage(vg_producto,
				'La fecha inicial debe ser menor a la fecha ' ||
				'final.',
				'exclamation')
			CONTINUE INPUT
		END IF
END INPUT

END FUNCTION



REPORT rep_caja(j10_fecha_pro,  g03_nombre, j10_estado, j10_tipo_fuente,
		j10_num_fuente, cliente, j10_tipo_destino, j10_num_destino,
		j10_moneda, j10_valor, j11_codigo_pago, j11_cod_bco_tarj,
		j11_num_ch_aut, j11_num_cta_tarj, j11_moneda, j11_valor)

DEFINE j10_fecha_pro		DATE
DEFINE g03_nombre		LIKE gent003.g03_nombre
DEFINE siglas_area		VARCHAR(3)
DEFINE j10_estado		LIKE cajt010.j10_estado
DEFINE j10_tipo_fuente		LIKE cajt010.j10_tipo_fuente
DEFINE j10_num_fuente		LIKE cajt010.j10_num_fuente
DEFINE cliente			VARCHAR(30)
DEFINE j10_tipo_destino		LIKE cajt010.j10_tipo_destino
DEFINE j10_num_destino		LIKE cajt010.j10_num_destino
DEFINE j10_moneda		LIKE cajt010.j10_moneda
DEFINE j10_valor		LIKE cajt010.j10_valor
DEFINE j11_codigo_pago		LIKE cajt011.j11_codigo_pago
DEFINE j11_cod_bco_tarj		LIKE cajt011.j11_cod_bco_tarj
DEFINE j11_num_ch_aut		LIKE cajt011.j11_num_ch_aut
DEFINE j11_num_cta_tarj		LIKE cajt011.j11_num_cta_tarj
DEFINE j11_moneda		LIKE cajt011.j11_moneda
DEFINE j11_valor		LIKE cajt011.j11_valor

DEFINE usuario			VARCHAR(19,15)
DEFINE titulo			VARCHAR(80)
DEFINE modulo			VARCHAR(40)
DEFINE i,long			SMALLINT

DEFINE bco_tarj			SMALLINT
DEFINE n_bco_tarj		VARCHAR(20)
DEFINE r_g08			RECORD LIKE gent008.*
DEFINE r_g10			RECORD LIKE gent010.*

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
	print '&k2S'	        -- Letra (16 cpi)
	LET modulo  = "Módulo: Caja"
	LET long    = LENGTH(modulo)
	LET usuario = 'Usuario: ', vg_usuario
	CALL fl_justifica_titulo('D', usuario, 19) RETURNING usuario
	CALL fl_justifica_titulo('C', 'VALORES RECAUDADOS POR CAJA', 60)
		RETURNING titulo
	
	PRINT COLUMN 1, rm_g01.g01_razonsocial,
	      COLUMN 150, "Página: ", PAGENO USING "&&&"
	PRINT COLUMN 1, modulo CLIPPED,
	      COLUMN 75, titulo CLIPPED,
	      COLUMN 150, UPSHIFT(vg_proceso)
      
	SKIP 1 LINES
	PRINT COLUMN 40, "** Fecha Inicial  : ", 
			rm_par.fecha_ini USING "dd-mm-yyyy",
	      COLUMN 100, "** Fecha Final    : ", 
	      		rm_par.fecha_fin USING "dd-mm-yyyy"

	IF rm_par.codigo_caja IS NOT NULL THEN
		PRINT COLUMN 40, "** Caja           : ", rm_par.n_caja
	END IF
	IF rm_par.areaneg IS NOT NULL THEN
		PRINT COLUMN 40, "** Area de Negocio: ", rm_par.n_areaneg
	END IF

	SKIP 1 LINES
	PRINT COLUMN 01, "Fecha de Impresión: ", TODAY USING "dd-mm-yyyy", 
	                 1 SPACES, TIME,
	      COLUMN 151, usuario
	SKIP 1 LINES
	
	PRINT COLUMN 1,   "Fecha Pro.",
	      COLUMN 13,  "Area",
	      COLUMN 18,  "Est",
	      COLUMN 23,  "Tipo Origen",
	      COLUMN 35,  "Cliente/Referencia",
	      COLUMN 67,  "Tipo Destino",
	      COLUMN 88,  "MD",
	      COLUMN 92,  fl_justifica_titulo('D', "Valor Doc.", 16),
	      COLUMN 110, "CP",
	      COLUMN 114, "Nombre Bco/Tarj",
	      COLUMN 136, "# Ch/Aut",
	      COLUMN 153, "# Cta/Tarj",
	      COLUMN 169, fl_justifica_titulo('D', "Valor Egreso", 16)

	PRINT COLUMN 1,   "------------",
	      COLUMN 13,  "-----",
	      COLUMN 18,  "-----",
	      COLUMN 23,  "------------",
	      COLUMN 35,  "--------------------------------",
	      COLUMN 67,  "---------------------",
	      COLUMN 88,  "----",
	      COLUMN 92,  "------------------",
	      COLUMN 110, "----",
	      COLUMN 114, "----------------------",
	      COLUMN 136, "-----------------",
	      COLUMN 153, "---------------------------",
	      COLUMN 169, "----------------"

ON EVERY ROW
	
	LET bco_tarj = banco_tarjeta(j11_codigo_pago)
	IF bco_tarj = 1 THEN
		CALL fl_lee_banco_general(j11_cod_bco_tarj) RETURNING r_g08.*
		LET n_bco_tarj = r_g08.g08_nombre
	ELSE
		IF bco_tarj = 2 THEN
			CALL fl_lee_tarjeta_credito(j11_cod_bco_tarj) 
				RETURNING r_g10.*
			LET n_bco_tarj = r_g10.g10_nombre
		ELSE
			LET n_bco_tarj = ' '
		END IF
	END IF

	FOR i = 1 TO 3
		LET siglas_area[i] = g03_nombre[i]
	END FOR

	PRINT COLUMN 1,   j10_fecha_pro USING "dd-mm-yyyy",
	      COLUMN 13,  siglas_area,
	      COLUMN 18,  j10_estado,
	      COLUMN 23,  j10_tipo_fuente, '-', 
	      		  fl_justifica_titulo('I', j10_num_fuente, 6) CLIPPED,
	      COLUMN 35,  cliente CLIPPED,
	      COLUMN 67,  j10_tipo_destino, '-', 
	      		  fl_justifica_titulo('I', j10_num_destino, 15) CLIPPED,
	      COLUMN 88,  j10_moneda,
	      COLUMN 92,  j10_valor USING "-,---,---,--&.##",
	      COLUMN 110, j11_codigo_pago,
	      COLUMN 114, n_bco_tarj CLIPPED,
	      COLUMN 136, fl_justifica_titulo('I', j11_num_ch_aut,   15) CLIPPED,
	      COLUMN 153, fl_justifica_titulo('I', j11_num_cta_tarj, 25) CLIPPED,
	      COLUMN 169, j11_valor USING "-,---,---,--&.##"

ON LAST ROW
	NEED 2 LINES
	PRINT COLUMN 92,  "------------------",
	      COLUMN 169, "------------------"	
	      
	PRINT COLUMN 92,  SUM(j10_valor) USING "-,---,---,--&.##",
	      COLUMN 169, SUM(j11_valor) USING "-,---,---,--&.##"

END REPORT



FUNCTION banco_tarjeta(forma_pago)

DEFINE forma_pago	LIKE cajt011.j11_codigo_pago
DEFINE ret_val		SMALLINT

-- En el CASE se le asignara:

-- 1 (UNO) a la variable ret_val si el codigo está relacionado a un
-- banco 
-- 2 (DOS) a la variable ret_val si el codigo está relacionado a una
-- tarjeta de crédito 
-- 3 (TRES) a la variable ret_val si el codigo requiere que se ingrese 
-- un numero pero no un banco ni tarjeta

CASE forma_pago
	WHEN vm_cheque LET ret_val = 1 
	WHEN 'DP' LET ret_val = 1 
	WHEN 'CD' LET ret_val = 1 
	WHEN 'DA' LET ret_val = 1 
	
	WHEN 'TJ' LET ret_val = 2

	WHEN 'RT' LET ret_val = 3
	
	OTHERWISE  
		-- Estas formas de pago no necesitan informacion del
		-- banco o tarjeta de crédito:
		-- 'EF', 'OC', 'OT', 'RT'
		INITIALIZE ret_val TO NULL
END CASE 

RETURN ret_val

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
