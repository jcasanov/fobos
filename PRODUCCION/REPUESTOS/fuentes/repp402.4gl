-----------------------------------------------------------------------------
-- Titulo           : repp402.4gl - Resumen de Ventas a clientes por mes 
-- Elaboracion      : 31-mar-2005
-- Autor            : JCM
-- Formato Ejecucion: fglrun repp402 base módulo compañía localidad [vendedor] 
-- Ultima Correccion: 
-- Motivo Correccion: 
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_tipo_fact	CHAR(2)

DEFINE rm_par		RECORD 
	anio		SMALLINT,
	codvend		LIKE rept001.r01_codigo, 
	nomvend		LIKE rept001.r01_nombres
END RECORD



MAIN

DEFER QUIT 
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/repp402.error')
CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 AND num_args() <> 5 THEN   -- Validar # parámetros correcto
	CALL fgl_winmessage(vg_producto, 'Número de parámetros incorrecto.', 'stop')
	EXIT PROGRAM
END IF
LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_codcia   = arg_val(3)
LET vg_codloc   = arg_val(4)
LET vg_proceso = 'repp402'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)

CALL funcion_master()

END MAIN



FUNCTION funcion_master()

CALL fl_nivel_isolation()
OPEN WINDOW w_mas AT 3,2 WITH 6 ROWS, 80 COLUMNS
    ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE 0, BORDER,
	      MESSAGE LINE LAST - 2)
OPTIONS INPUT WRAP,
	ACCEPT KEY	F12
OPEN FORM f_rep FROM "../forms/repf402_1"
DISPLAY FORM f_rep

LET vm_tipo_fact = 'FA'
CALL control_reporte()

END FUNCTION



FUNCTION control_reporte()
DEFINE query		VARCHAR(1000)
DEFINE expr_vend	VARCHAR(100)

DEFINE codcli		LIKE rept019.r19_codcli
DEFINE nomcli		LIKE rept019.r19_nomcli

DEFINE comando		VARCHAR(100)

WHILE TRUE
	CALL lee_parametros()
	IF int_flag THEN
		EXIT WHILE
	END IF
	CALL fl_control_reportes() RETURNING comando
	IF int_flag THEN
		CONTINUE WHILE
	END IF

	LET expr_vend = ' '
	IF rm_par.codvend IS NOT NULL THEN
		LET expr_vend = ' AND r19_vendedor = ', rm_par.codvend
	END IF

	{*
     	 * Creo esta tabla para usarla luego en el ON EVERY ROW del REPORT
	 *}
	LET query = 'SELECT r01_iniciales, r19_codcli, r19_nomcli, MONTH(r19_fecing) mes ',
			'FROM rept019, rept001 ',
			'WHERE r19_compania     = ', vg_codcia,
			'  AND r19_localidad    = ', vg_codloc,
			'  AND r19_cod_tran     = "', vm_tipo_fact, '"',
			expr_vend CLIPPED,
			'  AND YEAR(r19_fecing) = ', rm_par.anio,
			'  AND r01_compania     = r19_compania ',
			'  AND r01_codigo       = r19_vendedor ',
			' INTO TEMP te_ventas '
	PREPARE deto FROM query
	EXECUTE deto

	{*
 	 * Este es el cursor que uso para ejecutar el REPORT
	 *}
	DECLARE q_vtas CURSOR FOR 
		SELECT r19_codcli, r19_nomcli FROM te_ventas
		 GROUP BY r19_codcli, r19_nomcli
		 ORDER BY r19_nomcli
	OPEN  q_vtas 
	FETCH q_vtas 
	IF STATUS = NOTFOUND THEN
		DROP TABLE te_ventas
		CALL fl_mensaje_consulta_sin_registros()
		CONTINUE WHILE
	END IF
	CLOSE q_vtas
	START REPORT rep_vtas TO PIPE comando
	FOREACH q_vtas INTO codcli, nomcli 
		OUTPUT TO REPORT rep_vtas(codcli, nomcli)
	END FOREACH
	FINISH REPORT rep_vtas
	DROP TABLE te_ventas

	IF num_args() = 5 THEN
		EXIT WHILE
	END IF
END WHILE

END FUNCTION



FUNCTION lee_parametros()

DEFINE r_r01		RECORD LIKE rept001.*

INITIALIZE rm_par.* TO NULL
LET rm_par.anio = YEAR(TODAY)

IF num_args() = 5 THEN
	CALL fl_lee_vendedor_rep(vg_codcia, arg_val(5)) RETURNING r_r01.*
	LET rm_par.codvend = r_r01.r01_codigo
	LET rm_par.nomvend = r_r01.r01_nombres
	DISPLAY BY NAME rm_par.*
	RETURN
END IF

LET int_flag = 0
INPUT BY NAME rm_par.* WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		LET int_flag = 1
		RETURN
	ON KEY(F2)
		IF INFIELD(codvend) THEN
			CALL fl_ayuda_vendedores(vg_codcia)
				RETURNING r_r01.r01_codigo, 
					  r_r01.r01_nombres
			IF r_r01.r01_codigo IS NOT NULL THEN
			    	LET rm_par.codvend = r_r01.r01_codigo
			    	LET rm_par.nomvend = r_r01.r01_nombres
			    	DISPLAY BY NAME rm_par.*
			END IF
		END IF
	AFTER FIELD anio
		IF rm_par.anio > YEAR(TODAY) THEN
			CALL fgl_winmessage(vg_producto, 'No puede pedir anos superiores al ano actual.', 'exclamation') 
			NEXT FIELD anio
		END IF
	AFTER FIELD codvend
		IF rm_par.codvend IS NOT NULL THEN
			CALL fl_lee_vendedor_rep(vg_codcia, rm_par.codvend)
				RETURNING r_r01.*
			IF r_r01.r01_codigo IS NULL THEN
				CALL fgl_winmessage(vg_producto,'Vendedor no existe.','exclamation')
				NEXT FIELD codvend
			END IF 
			LET rm_par.codvend = r_r01.r01_codigo
			LET rm_par.nomvend = r_r01.r01_nombres
			DISPLAY BY NAME rm_par.*
		ELSE
			CLEAR nomvend
		END IF		 
END INPUT

END FUNCTION



REPORT rep_vtas(codcli, nomcli)

DEFINE codcli		LIKE rept019.r19_codcli
DEFINE nomcli		LIKE rept019.r19_nomcli
DEFINE vend		LIKE rept001.r01_iniciales
DEFINE tmp_vend		LIKE rept001.r01_iniciales
DEFINE fact_vend	SMALLINT
DEFINE tmp_fact		SMALLINT
DEFINE num_fact 	ARRAY[12] OF SMALLINT

DEFINE usuario		VARCHAR(19,15)
DEFINE titulo		VARCHAR(80)
DEFINE modulo		VARCHAR(40)
DEFINE i,long		SMALLINT
DEFINE fecha		DATE

OUTPUT
	TOP MARGIN	1
	LEFT MARGIN	2
	RIGHT MARGIN	90
	BOTTOM MARGIN	4
	PAGE LENGTH	66
FORMAT
PAGE HEADER
	print 'E'; print '&l26A';	-- Indica que voy a trabajar con hojas A4
	print '&k2S'	                -- Letra (12 cpi)
	LET modulo  = "Módulo: Repuestos"
	LET long    = LENGTH(modulo)
	LET usuario = 'Usuario: ', vg_usuario
	CALL fl_justifica_titulo('D', usuario, 19) RETURNING usuario
	CALL fl_justifica_titulo('I', 'RESUMEN DE VENTAS MENSUALES POR CLIENTE', 80)
		RETURNING titulo
	PRINT COLUMN 1, rg_cia.g01_razonsocial,
  	      COLUMN 97, "Página: ", PAGENO USING "&&&"
	PRINT COLUMN 1, modulo CLIPPED,
	      COLUMN 52, titulo CLIPPED,
	      COLUMN 100, "REPP402" 

	PRINT COLUMN 48, "** Ano           : ", rm_par.anio USING "&&&&"
	IF rm_par.codvend IS NOT NULL THEN
		PRINT COLUMN 48, "** Vendedor      : ", rm_par.nomvend
	ELSE
		PRINT COLUMN 48, "** Vendedor      : T O D O S"
	END IF

	PRINT COLUMN 01, "Fecha  : ", TODAY USING "dd-mm-yyyy", 1 SPACES, TIME,
	      COLUMN 90, usuario
	SKIP 1 LINES

	PRINT COLUMN 1,   "Cliente",
	      COLUMN 43,  "Vend.",
	      COLUMN 50,  "Ene",
	      COLUMN 55,  "Feb",
	      COLUMN 60,  "Mar",
	      COLUMN 65,  "Abr",
	      COLUMN 70,  "May",
	      COLUMN 75,  "Jun",
	      COLUMN 80,  "Jul",
	      COLUMN 85,  "Ago",
	      COLUMN 90,  "Sep",
	      COLUMN 95,  "Oct",
	      COLUMN 100, "Nov",
	      COLUMN 105, "Dic"
	PRINT "---------------------------------------------------------------------------------------------------------------"

ON EVERY ROW
	FOR i = 1 TO 12
		LET num_fact[i] = 0		
		LET fact_vend   = 0		
	
		DECLARE q_vtas_mes CURSOR FOR
		SELECT r01_iniciales, COUNT(*) FROM te_ventas
		 WHERE r19_codcli = codcli
		   AND mes        = i
		 GROUP BY r01_iniciales

		FOREACH q_vtas_mes INTO tmp_vend, tmp_fact		
			IF tmp_fact > fact_vend THEN
				LET vend = tmp_vend
				LET fact_vend = tmp_fact
			END IF	
			LET num_fact[i] = num_fact[i] + tmp_fact
		END FOREACH
	END FOR

	PRINT COLUMN 1,   nomcli,
	      COLUMN 43,  vend,
	      COLUMN 50,  num_fact[1]  USING '##&',
	      COLUMN 55,  num_fact[2]  USING '##&',
	      COLUMN 60,  num_fact[3]  USING '##&',
	      COLUMN 65,  num_fact[4]  USING '##&',
	      COLUMN 70,  num_fact[5]  USING '##&',
	      COLUMN 75,  num_fact[6]  USING '##&',
	      COLUMN 80,  num_fact[7]  USING '##&',
	      COLUMN 85,  num_fact[8]  USING '##&',
	      COLUMN 90,  num_fact[9]  USING '##&',
	      COLUMN 95,  num_fact[10] USING '##&',
	      COLUMN 100, num_fact[11] USING '##&',
	      COLUMN 105, num_fact[12] USING '##&'
	
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
