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
	n_areaneg	LIKE gent003.g03_nombre,
	j11_codigo_pago	LIKE cajt011.j11_codigo_pago,
	j01_nombre	LIKE cajt001.j01_nombre
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
IF num_args() <> 4  THEN   		-- Validar # parámetros correcto
	--CALL fgl_winmessage(vg_producto,'Número de parámetros incorrecto.','stop')
	CALL fl_mostrar_mensaje('Número de parámetros incorrecto.','stop')
	EXIT PROGRAM
END IF
LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_codcia   = arg_val(3)
LET vg_codloc   = arg_val(4)
LET vg_proceso = 'cajp405'
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

CALL fl_nivel_isolation()

LET vm_top    = 1
LET vm_left   =	2
LET vm_right  =	90
LET vm_bottom =	4
LET vm_page   = 43

LET vm_egreso   = 'EC'
LET vm_cheque   = 'CH'
LET vm_efectivo = 'EF'

LET lin_menu = 0
LET row_ini  = 3
LET num_rows = 11
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
        OPEN FORM f_rep FROM '../forms/cajf405_1'
ELSE
        OPEN FORM f_rep FROM '../forms/cajf405_1c'
END IF
DISPLAY FORM f_rep

CALL control_reporte()

END FUNCTION



FUNCTION control_reporte()
DEFINE i,col		SMALLINT
DEFINE query		CHAR(2100)
DEFINE comando		VARCHAR(100)
DEFINE data_found	SMALLINT
DEFINE expr_caja	CHAR(100)
DEFINE expr_area	CHAR(100)

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
		    	  ' j11_cod_bco_tarj, j11_num_ch_aut,j11_num_cta_tarj,',
		          ' j11_moneda, (j11_valor * (-1))',
		      ' FROM cajt010, cajt011, OUTER gent003 ',
                      ' WHERE j10_compania    = ', vg_codcia, 
		        ' AND j10_localidad   = ', vg_codloc,
		        ' AND j10_tipo_fuente = "', vm_egreso, '" ',
		        ' AND j10_estado      <> "E" ',
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
                          ' j10_moneda, (j10_valor * (-1)), "',vm_efectivo,'",',
		    	  ' -1, " ", " ", j10_moneda, (j10_valor * (-1))',
		      ' FROM cajt010, OUTER gent003 ',
                      ' WHERE j10_compania    = ', vg_codcia, 
		        ' AND j10_localidad   = ', vg_codloc,
		        ' AND j10_tipo_fuente = "', vm_egreso, '" ',
		        ' AND j10_estado      <> "E" ',
		        ' AND j10_valor       > 0 ',
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
	START REPORT rep_caja TO PIPE comando
	LET data_found = 0
	FOREACH q_deto INTO r_det.*
		IF rm_par.j11_codigo_pago IS NOT NULL THEN
			IF r_det.j11_codigo_pago <> rm_par.j11_codigo_pago THEN
				CONTINUE FOREACH
			END IF
		END IF
		LET data_found = 1
		IF r_det.j11_cod_bco_tarj = -1 THEN
			INITIALIZE r_det.j11_cod_bco_tarj TO NULL
		END IF
		OUTPUT TO REPORT rep_caja(r_det.*)
	END FOREACH
	FINISH REPORT rep_caja
	FREE q_deto
	IF NOT data_found THEN
		CALL fl_mensaje_consulta_sin_registros()
	END IF
END WHILE

END FUNCTION



FUNCTION lee_parametros()
DEFINE r_j01		RECORD LIKE cajt001.*
DEFINE r_j02		RECORD LIKE cajt002.*
DEFINE r_g03		RECORD LIKE gent003.*
DEFINE i,j,l,col	SMALLINT

LET INT_FLAG   = 0
INPUT BY NAME rm_par.* WITHOUT DEFAULTS

	ON KEY(INTERRUPT)
		IF NOT FIELD_TOUCHED(codigo_caja, areaneg, fecha_ini, fecha_fin,
					j11_codigo_pago)
		THEN
			EXIT PROGRAM
		END IF
		LET INT_FLAG = 1 
		RETURN

        ON KEY(F1,CONTROL-W)
		CALL llamar_visor_teclas()
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
		IF INFIELD(j11_codigo_pago) THEN
			CALL fl_ayuda_forma_pago(vg_codcia, 'T', 'T', 'N') 
				RETURNING r_j01.j01_codigo_pago,
					  r_j01.j01_nombre,
					  r_j01.j01_cont_cred
			IF r_j01.j01_codigo_pago IS NOT NULL THEN
				LET rm_par.j11_codigo_pago =
							r_j01.j01_codigo_pago
				LET rm_par.j01_nombre      = r_j01.j01_nombre
				DISPLAY BY NAME rm_par.j11_codigo_pago,
						  r_j01.j01_nombre
			END IF
		END IF
		LET INT_FLAG = 0

	BEFORE INPUT
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
	AFTER FIELD codigo_caja
		IF rm_par.codigo_caja IS NOT NULL THEN
			CALL fl_lee_codigo_caja_caja(vg_codcia, vg_codloc,
				rm_par.codigo_caja) RETURNING r_j02.* 
			IF r_j02.j02_codigo_caja IS NULL THEN
				--CALL fgl_winmessage(vg_producto,'Código caja no existe.','exclamation')
				CALL fl_mostrar_mensaje('Código caja no existe.','exclamation')
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
				--CALL fgl_winmessage(vg_producto,'Area de negocio no existe.','exclamation')
				CALL fl_mostrar_mensaje('Area de negocio no existe.','exclamation')
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
				--CALL fgl_winmessage(vg_producto,'La fecha de inicio no puede ser mayor a la de hoy.','exclamation')
				CALL fl_mostrar_mensaje('La fecha de inicio no puede ser mayor a la de hoy.','exclamation')
				NEXT FIELD fecha_ini
			END IF
			IF rm_par.fecha_ini < '01-01-1990' THEN
				--CALL fgl_winmessage(vg_producto,'Debe ingresa fechas mayores a las del año 1989.','exclamation')	
				CALL fl_mostrar_mensaje('Debe ingresa fechas mayores a las del año 1989.','exclamation')	
				NEXT FIELD fecha_ini
			END IF
				
		ELSE 
			NEXT FIELD fecha_ini
		END IF

	AFTER FIELD fecha_fin
		IF rm_par.fecha_fin IS NOT NULL THEN
			IF rm_par.fecha_fin > TODAY THEN
				--CALL fgl_winmessage(vg_producto,'La fecha de término no puede ser mayor a la de hoy.','exclamation')
				CALL fl_mostrar_mensaje('La fecha de término no puede ser mayor a la de hoy.','exclamation')
				NEXT FIELD fecha_fin
			END IF
			IF rm_par.fecha_fin < '01-01-1990' THEN
				--CALL fgl_winmessage(vg_producto,'Debe ingresa fechas mayores a las del año 1989.','exclamation')	
				NEXT FIELD fecha_fin
			END IF
		ELSE
			NEXT FIELD fecha_fin
		END IF

	AFTER FIELD j11_codigo_pago
		IF rm_par.j11_codigo_pago IS NOT NULL THEN
			CALL fl_lee_tipo_pago_caja(vg_codcia,
							rm_par.j11_codigo_pago,
							r_j01.j01_cont_cred)
				RETURNING r_j01.*		
			IF r_j01.j01_codigo_pago IS NULL THEN
				CALL fl_mostrar_mensaje('Forma de Pago no existe.','exclamation')
				NEXT FIELD j11_codigo_pago
			END IF
			LET rm_par.j01_nombre = r_j01.j01_nombre
			DISPLAY BY NAME r_j01.j01_nombre
		ELSE
			CLEAR j01_nombre
		END IF

	AFTER INPUT
		IF rm_par.fecha_ini > rm_par.fecha_fin THEN
			--CALL fgl_winmessage(vg_producto,'La fecha inicial debe ser menor a la fecha final.','exclamation')
			CALL fl_mostrar_mensaje('La fecha inicial debe ser menor a la fecha final.','exclamation')
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
DEFINE j11_cont_cred		LIKE cajt011.j11_cont_cred
DEFINE usuario			VARCHAR(19,10)
DEFINE titulo			VARCHAR(80)
DEFINE modulo			VARCHAR(40)
DEFINE i,long			SMALLINT
DEFINE bco_tarj			SMALLINT
DEFINE n_bco_tarj		VARCHAR(20)
DEFINE r_g08			RECORD LIKE gent008.*
DEFINE r_g10			RECORD LIKE gent010.*
DEFINE escape			SMALLINT
DEFINE act_comp, db_c		SMALLINT
DEFINE desact_comp, db		SMALLINT
DEFINE act_10cpi		SMALLINT
DEFINE act_12cpi		SMALLINT

OUTPUT
	TOP MARGIN	1
	LEFT MARGIN	0
	RIGHT MARGIN	160
	BOTTOM MARGIN	4
	PAGE LENGTH	66

FORMAT

PAGE HEADER
	--print 'E'; 
	--print '&l26A';	-- Indica que voy a trabajar con hojas A4
	--print '&l1O';		-- Modo landscape
	--print '&k2S'	        -- Letra (16 cpi)
	LET escape	= 27		# Iniciar sec. impresi¢n
	LET act_comp	= 15		# Activar Comprimido.
	LET desact_comp	= 18		# Cancelar Comprimido.
	LET act_10cpi	= 80		# Comprimido 10 CPI.
	LET act_12cpi	= 77		# Comprimido 12 CPI.
	LET modulo  = "Módulo: Caja"
	LET long    = LENGTH(modulo)
	LET usuario = 'Usuario: ', vg_usuario
	CALL fl_justifica_titulo('D', usuario, 19) RETURNING usuario
	CALL fl_justifica_titulo('C', 'LISTADO DE EGRESOS DE CAJA', 80)
		RETURNING titulo
	SKIP 1 LINES
	print ASCII escape;
	print ASCII act_comp;
	print ASCII escape;
	print ASCII act_12cpi;
	PRINT COLUMN 005, rm_g01.g01_razonsocial,
	      COLUMN 154, "Página: ", PAGENO USING "&&&"
	PRINT COLUMN 001, modulo,
	      COLUMN 037, titulo,
	      COLUMN 154, UPSHIFT(vg_proceso)
	SKIP 1 LINES
	PRINT COLUMN 40, "** Fecha Inicial  : ", 
			rm_par.fecha_ini USING "dd-mm-yyyy",
	      COLUMN 100, "** Fecha Final    : ", 
	      		rm_par.fecha_fin USING "dd-mm-yyyy"
	--#IF rm_par.codigo_caja IS NOT NULL THEN
		PRINT COLUMN 40, "** Caja           : ", rm_par.n_caja
	--#END IF
	--#IF rm_par.areaneg IS NOT NULL THEN
		PRINT COLUMN 40, "** Area de Negocio: ", rm_par.n_areaneg
	--#END IF
	--#IF rm_par.j11_codigo_pago IS NOT NULL THEN
		PRINT COLUMN 40, "** Forma de Pago  : ", rm_par.j11_codigo_pago,
				" ", rm_par.j01_nombre
	--#END IF
	SKIP 1 LINES
	PRINT COLUMN 01, "Fecha de Impresión: ", TODAY USING "dd-mm-yyyy", 
	                 1 SPACES, TIME,
	      COLUMN 142, usuario
	SKIP 1 LINES
	PRINT COLUMN 001, "Fecha Pro.",
	      COLUMN 012, "Ar.",
	      COLUMN 016, "E",
	      COLUMN 018, "Tipo Origen",
	      COLUMN 030, "Cliente/Referencia",
	      --COLUMN 046, "Tipo Destino",
	      COLUMN 065, "MD",
	      COLUMN 068, "   Valor Doc.",
	      COLUMN 082, "CP",
	      COLUMN 085, "Nombre Bco/Tarj",
	      COLUMN 106, "# Ch/Aut",
	      COLUMN 122, "# Cta/Tarj",
	      COLUMN 148, " Valor Egreso"
	PRINT COLUMN 001, "----------------------------------------------------------------------------------------------------------------------------------------------------------------"

ON EVERY ROW
	NEED 3 LINES
	LET bco_tarj = banco_tarjeta(j11_codigo_pago)
	IF bco_tarj = 1 THEN
		CALL fl_lee_banco_general(j11_cod_bco_tarj) RETURNING r_g08.*
		LET n_bco_tarj = r_g08.g08_nombre
	ELSE
		IF bco_tarj = 2 THEN
			LET cont_cred = 'C'
			IF j10_tipo_fuente = 'SC' THEN
				LET cont_cred = 'R'
			END IF
			CALL fl_lee_tarjeta_credito(vg_codcia, j11_cod_bco_tarj,
						j11_codigo_pago, cont_cred) 
				RETURNING r_g10.*
			LET n_bco_tarj = r_g10.g10_nombre
		ELSE
			LET n_bco_tarj = ' '
		END IF
	END IF
	FOR i = 1 TO 3
		LET siglas_area[i] = g03_nombre[i]
	END FOR
	PRINT COLUMN 001, j10_fecha_pro USING "dd-mm-yyyy",
	      COLUMN 012, siglas_area,
	      COLUMN 016, j10_estado,
	      COLUMN 018, j10_tipo_fuente, '-', j10_num_fuente USING "<<<<<<<&",
	      COLUMN 030, cliente,
	      --COLUMN 046, j10_tipo_destino, '-', j10_num_destino,
	      COLUMN 065, j10_moneda,
	      COLUMN 068, j10_valor USING "--,---,--&.##",
	      COLUMN 082, j11_codigo_pago,
	      COLUMN 085, n_bco_tarj,
	      COLUMN 106, j11_num_ch_aut,
	      COLUMN 122, j11_num_cta_tarj,
	      COLUMN 148, j11_valor USING "--,---,--&.##"

ON LAST ROW
	NEED 2 LINES
	PRINT COLUMN 068, "-------------",
	      COLUMN 148, "-------------"	
	PRINT COLUMN 068, SUM(j10_valor) USING "--,---,--&.##",
	      COLUMN 148, SUM(j11_valor) USING "--,---,--&.##"
	print ASCII escape;
	print ASCII desact_comp;
	print ASCII escape;
	print ASCII act_10cpi

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



FUNCTION llamar_visor_teclas()
DEFINE a		SMALLINT

IF vg_gui = 0 THEN
	CALL fl_visor_teclas_caracter() RETURNING int_flag 
	LET a = fgl_getkey()
	CLOSE WINDOW w_tf
	LET int_flag = 0
END IF

END FUNCTION
