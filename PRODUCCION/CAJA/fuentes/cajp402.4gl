------------------------------------------------------------------------------
-- Titulo           : cajp402.4gl - Valores Recaudados por Caja
-- Elaboracion      : 14-ene-2002
-- Autor            : JCM
-- Formato Ejecucion: fglrun cajp402 base módulo compañía localidad
-- Ultima Correccion: 
-- Motivo Correccion: 
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
CALL startlog('../logs/cajp402.err')
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
LET vg_proceso = 'cajp402'
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

CREATE TEMP TABLE temp_tipo
	(tipo		CHAR(2),
	valor		DECIMAL(12,2))

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
        OPEN FORM f_rep FROM '../forms/cajf402_1'
ELSE
        OPEN FORM f_rep FROM '../forms/cajf402_1c'
END IF
DISPLAY FORM f_rep

CALL control_reporte()

END FUNCTION



FUNCTION control_reporte()
DEFINE i,col		SMALLINT
DEFINE query		CHAR(3000)
DEFINE comando		VARCHAR(100)
DEFINE data_found	SMALLINT
DEFINE expr_caja	VARCHAR(100)
DEFINE expr_area	VARCHAR(100)
DEFINE num_sri		LIKE rept038.r38_num_sri

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

LET rm_par.fecha_ini = vg_fecha
LET rm_par.fecha_fin = vg_fecha

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
		LET expr_area = ' AND j10_areaneg = ', rm_par.areaneg
	END IF
	LET query = 'SELECT UNIQUE DATE(j10_fecha_pro), g03_nombre, ',
		          ' j10_estado, j10_tipo_fuente, j10_num_fuente, ',
		          ' j10_nomcli, j10_tipo_destino, j10_num_destino,',
                          ' j10_moneda, j10_valor, j11_codigo_pago, ',
		          ' j11_cod_bco_tarj, j11_num_ch_aut,j11_num_cta_tarj,',
		          ' j11_moneda, j11_valor ',
		      ' FROM cajt010, cajt011, OUTER gent003 ',
		      ' WHERE j10_compania    = ', vg_codcia, 
		        ' AND j10_localidad   = ', vg_codloc,
		        ' AND j10_tipo_fuente <> "', vm_egreso, '" ',
		        ' AND j10_estado NOT IN ("E", "*") ',
		        expr_area CLIPPED,
		        ' AND DATE(j10_fecha_pro) ',
		              ' BETWEEN "', rm_par.fecha_ini, '" AND "', 
		    		            rm_par.fecha_fin, '" ',
		        expr_caja CLIPPED, 
		        ' AND g03_compania    = j10_compania ', 
		        ' AND g03_areaneg     = j10_areaneg ',
		        ' AND j11_compania    = j10_compania ',
		        ' AND j11_localidad   = j10_localidad ',
		        ' AND j11_tipo_fuente = j10_tipo_fuente ',
		        ' AND j11_num_fuente  = j10_num_fuente ', 
		    'UNION ',
		    'SELECT UNIQUE DATE(j10_fecha_pro), g03_nombre, ',
		          ' j10_estado, j10_tipo_fuente, j10_num_fuente, ',
		          ' j10_referencia, j10_tipo_destino, j10_num_destino,',
                          ' j10_moneda, (j11_valor * (-1)), j11_codigo_pago, ',
		    	  ' j11_cod_bco_tarj, j11_num_ch_aut,j11_num_cta_tarj,',
		          ' j11_moneda, (j11_valor * (-1))',
		      ' FROM cajt010, cajt011, OUTER gent003 ',
                      ' WHERE j10_compania    = ', vg_codcia, 
		        ' AND j10_localidad   = ', vg_codloc,
		        ' AND j10_tipo_fuente = "', vm_egreso, '" ',
		        ' AND j10_estado      NOT IN ("E", "*") ',
		        expr_area CLIPPED,
		        ' AND DATE(j10_fecha_pro) ',
		              ' BETWEEN "', rm_par.fecha_ini, '" AND "', 
		                            rm_par.fecha_fin, '" ',
		        expr_caja CLIPPED, 
			' AND j10_banco       = 0 ',
		        ' AND g03_compania    = j10_compania ', 
		        ' AND g03_areaneg     = j10_areaneg ',
		        ' AND j11_compania    = j10_compania ',
		        ' AND j11_localidad   = j10_localidad ',
		        ' AND j11_num_egreso  = j10_num_fuente ',
		    'UNION ',
		    'SELECT UNIQUE DATE(j10_fecha_pro), g03_nombre, ',
		          ' j10_estado, j10_tipo_fuente, j10_num_fuente, ',
		          ' j10_referencia, j10_tipo_destino, j10_num_destino,',
                          ' j10_moneda, (j10_valor * (-1)), "', vm_efectivo,
			  '", -1, " ", " ", j10_moneda, (j10_valor * (-1))',
		      ' FROM cajt010, OUTER gent003 ',
                      ' WHERE j10_compania    = ', vg_codcia, 
		        ' AND j10_localidad   = ', vg_codloc,
		        ' AND j10_tipo_fuente = "', vm_egreso, '" ',
		        ' AND j10_estado      NOT IN ("E", "*") ',
		        expr_area CLIPPED,
		        ' AND DATE(j10_fecha_pro) ',
		              ' BETWEEN "', rm_par.fecha_ini, '" AND "', 
		                            rm_par.fecha_fin, '" ',
		        expr_caja CLIPPED, 
			' AND j10_banco       = 0 ',
		        ' AND g03_compania    = j10_compania ', 
		        ' AND g03_areaneg     = j10_areaneg ',
		        ' ORDER BY 1 '
	PREPARE deto FROM query
	DECLARE q_deto CURSOR FOR deto
	LET data_found = 0
	START REPORT rep_caja TO PIPE comando
	FOREACH q_deto INTO r_det.*
		IF r_det.j10_tipo_destino = 'PR' AND
		  (vg_codloc >= 3 AND vg_codloc <= 5)
		THEN
			--CONTINUE FOREACH
		END IF
		IF rm_par.j11_codigo_pago IS NOT NULL THEN
			IF r_det.j11_codigo_pago <> rm_par.j11_codigo_pago THEN
				CONTINUE FOREACH
			END IF
		END IF
		LET data_found = 1
		IF r_det.j11_cod_bco_tarj = -1 THEN
			INITIALIZE r_det.j11_cod_bco_tarj TO NULL
		END IF
		IF r_det.j10_tipo_destino = 'PR' OR
		   r_det.j10_tipo_destino = 'EC'
		THEN
			SELECT * FROM temp_tipo
				WHERE tipo = r_det.j10_tipo_destino
			IF STATUS = NOTFOUND THEN
				INSERT INTO temp_tipo
					VALUES (r_det.j10_tipo_destino,
						r_det.j11_valor)
			ELSE
				UPDATE temp_tipo
					SET valor = valor + r_det.j11_valor
					WHERE tipo = r_det.j10_tipo_destino
			END IF
		ELSE
			SELECT * FROM temp_tipo
				WHERE tipo = r_det.j11_codigo_pago
			IF STATUS = NOTFOUND THEN
				INSERT INTO temp_tipo
					VALUES (r_det.j11_codigo_pago,
						r_det.j11_valor)
			ELSE
				UPDATE temp_tipo
					SET valor = valor + r_det.j11_valor
					WHERE tipo = r_det.j11_codigo_pago
			END IF
		END IF
		LET num_sri = NULL
		IF r_det.j10_tipo_destino = 'FA' THEN
			DECLARE q_r38 CURSOR FOR
				SELECT UNIQUE r38_num_sri
					FROM rept038
					WHERE r38_compania    = vg_codcia    
					  AND r38_localidad   = vg_codloc 
					  AND r38_tipo_fuente =
							r_det.j10_tipo_fuente 
					  AND r38_cod_tran    =
							r_det.j10_tipo_destino 
					  AND r38_num_tran    =
							r_det.j10_num_destino
					ORDER BY r38_num_sri DESC
			OPEN q_r38
			FETCH q_r38 INTO num_sri
			CLOSE q_r38
			FREE q_r38
		END IF
		OUTPUT TO REPORT rep_caja(r_det.*, num_sri)
	END FOREACH
	FREE q_deto
	FINISH REPORT rep_caja
	
	IF NOT data_found THEN
		CALL fl_mensaje_consulta_sin_registros()
	END IF

	DELETE FROM temp_tipo
		
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
			CALL fl_ayuda_forma_pago(vg_codcia, 'T', 'T', 'T') 
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
			IF rm_par.fecha_ini > vg_fecha THEN
				--calL fgl_winmessage(vg_producto,'La fecha de inicio no puede ser mayor a la de hoy.','exclamation')
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
			IF rm_par.fecha_fin > vg_fecha THEN
				--CALL fgl_winmessage(vg_producto,'La fecha de término no puede ser mayor a la de hoy.','exclamation')
				CALL fl_mostrar_mensaje('La fecha de término no puede ser mayor a la de hoy.','exclamation')
				NEXT FIELD fecha_fin
			END IF
			IF rm_par.fecha_fin < '01-01-1990' THEN
				--CALL fgl_winmessage(vg_producto,'Debe ingresa fechas mayores a las del año 1989.','exclamation')	
				CALL fl_mostrar_mensaje('Debe ingresa fechas mayores a las del año 1989.','exclamation')	
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
		j11_num_ch_aut, j11_num_cta_tarj, j11_moneda, j11_valor,num_sri)

DEFINE j10_fecha_pro		DATE
DEFINE g03_nombre		LIKE gent003.g03_nombre
DEFINE siglas_area		VARCHAR(3)
DEFINE j10_estado		LIKE cajt010.j10_estado
DEFINE j10_tipo_fuente		LIKE cajt010.j10_tipo_fuente
DEFINE j10_num_fuente		LIKE cajt010.j10_num_fuente
DEFINE cliente			VARCHAR(20)
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
DEFINE num_sri			LIKE rept038.r38_num_sri

DEFINE usuario			VARCHAR(19,15)
DEFINE titulo			VARCHAR(80)
DEFINE modulo			VARCHAR(30)
DEFINE i,long			SMALLINT

DEFINE bco_tarj			SMALLINT
DEFINE n_bco_tarj		VARCHAR(20)
DEFINE r_g08			RECORD LIKE gent008.*
DEFINE r_g10			RECORD LIKE gent010.*
DEFINE ttipo			LIKE cajt011.j11_codigo_pago
DEFINE tvalor			LIKE cajt011.j11_valor
DEFINE cont_cred	LIKE cajt001.j01_cont_cred
DEFINE escape		SMALLINT
DEFINE act_comp, db_c	SMALLINT
DEFINE desact_comp, db	SMALLINT

OUTPUT
	TOP MARGIN	1
	LEFT MARGIN	2
	RIGHT MARGIN	132
	BOTTOM MARGIN	4
	PAGE LENGTH	66

FORMAT

PAGE HEADER
	LET escape	= 27		# Iniciar sec. impresi¢n
	LET act_comp	= 15		# Activar Comprimido.
	LET desact_comp	= 18		# Cancelar Comprimido.
	LET modulo  = "Módulo: Caja"
	LET long    = LENGTH(modulo)
	LET usuario = 'Usuario: ', vg_usuario
	CALL fl_justifica_titulo('D', usuario, 19) RETURNING usuario
	CALL fl_justifica_titulo('C', 'VALORES RECAUDADOS POR CAJA', 80)
		RETURNING titulo
	
	SKIP 1 LINES
	print ASCII escape;
	print ASCII act_comp;
	PRINT COLUMN 003, rm_g01.g01_razonsocial,
	      COLUMN 124, "Pagina: ", PAGENO USING "&&&"
	PRINT COLUMN 001, modulo,
	      COLUMN 026, titulo,
	      COLUMN 124, UPSHIFT(vg_proceso)
      
	SKIP 1 LINES
	PRINT COLUMN 40, "** Caja           : ";
	IF rm_par.codigo_caja IS NOT NULL THEN
		PRINT rm_par.n_caja
	ELSE
		PRINT ''
	END IF
	PRINT COLUMN 40, "** Rango de Fechas: ", 
			rm_par.fecha_ini USING "dd-mm-yyyy", ' al ',
	      		rm_par.fecha_fin USING "dd-mm-yyyy"
	PRINT COLUMN 40, "** Area de Negocio: ";
	IF rm_par.areaneg IS NOT NULL THEN
		PRINT rm_par.n_areaneg
	ELSE
		PRINT ''
	END IF
	IF rm_par.j11_codigo_pago IS NOT NULL THEN
		PRINT COLUMN 40, "** Forma de Pago  : ", rm_par.j11_codigo_pago,
				" ", rm_par.j01_nombre
	ELSE
		PRINT ''
	END IF
	SKIP 1 LINES
	PRINT COLUMN 01, "Impresión: ", vg_fecha USING "dd-mm-yyyy", 
	                 1 SPACES, TIME,
	      COLUMN 113, usuario
	PRINT COLUMN 1, "------------------------------------------------------------------------------------------------------------------------------------"
	PRINT COLUMN 001, "Fecha Pro.",		-- (10)
	      COLUMN 012, "Cliente/Referencia", -- (20)
	      COLUMN 033, "Documento",		-- (10)
	      COLUMN 044, "Num. SRI",		-- (15)
	      COLUMN 060, "     Valor",		-- (10) ###,##&.##
	      COLUMN 071, "CP",
	      COLUMN 074, "Banco/Tarjeta",      -- (15)
	      COLUMN 090, "# Ch/Aut",		-- (15)
	      COLUMN 106, "# Cta/Tarj",		-- (16)
	      COLUMN 123, "Valor Pago"		-- (10)
	PRINT COLUMN 1, "------------------------------------------------------------------------------------------------------------------------------------"

ON EVERY ROW
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
	NEED 3 LINES
	PRINT COLUMN 001, j10_fecha_pro USING "dd-mm-yyyy",
	      COLUMN 012, cliente[1,20],
	      COLUMN 033, j10_tipo_destino, '-', 
	      		  fl_justifica_titulo('I', j10_num_destino, 7) CLIPPED,
	      COLUMN 044, num_sri[1,15], 
	      COLUMN 060, j10_valor USING "---,--&.##",
	      COLUMN 071, j11_codigo_pago,
	      COLUMN 074, n_bco_tarj[1,15],
	      COLUMN 090, j11_num_ch_aut[1,15],
	      COLUMN 106, j11_num_cta_tarj[1,25],
	      COLUMN 123, j11_valor USING "---,--&.##"

ON LAST ROW
	PRINT COLUMN 120, "-------------"	
	PRINT COLUMN 120, SUM(j11_valor) USING "--,---,--&.##"
	NEED 4 LINES
	SKIP 1 LINES
	DECLARE q_tipo CURSOR FOR SELECT * FROM temp_tipo
	FOREACH q_tipo INTO ttipo, tvalor
		PRINT COLUMN 42, 'Valor Total Tipo ==>  ', ttipo, ' ',
				tvalor USING "--,---,--&.##"
	END FOREACH
	print ASCII escape;
	print ASCII desact_comp 
	CLOSE q_tipo
	FREE q_tipo

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
	WHEN 'CP' LET ret_val = 1 
	WHEN 'DP' LET ret_val = 1 
	WHEN 'CD' LET ret_val = 1 
	
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
DEFINE a		CHAR(1)

IF vg_gui = 0 THEN
	CALL fl_visor_teclas_caracter() RETURNING int_flag 
	LET a = fgl_getkey()
	CLOSE WINDOW w_tf
	LET int_flag = 0
END IF

END FUNCTION
