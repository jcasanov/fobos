--------------------------------------------------------------------------------
-- Titulo           : rolp410.4gl - Impresión de recibos de pago de decimos
-- Elaboracion      : 05-sep-2003
-- Autor            : JCM
-- Formato Ejecucion: fglrun rolp410 base módulo compañía 
-- 			[año] [liqrol] [[agrupado]] [[depto]] [[cod_trab]]
-- Ultima Correccion: 
-- Motivo Correccion:
--------------------------------------------------------------------------------

GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE rm_n36		RECORD LIKE rolt036.*
DEFINE rm_cia		RECORD LIKE gent001.*
DEFINE rm_loc		RECORD LIKE gent002.*
DEFINE n1, n2, fin_arch	INTEGER
DEFINE num_liq, tot_liq	INTEGER
DEFINE fecha_ini	DATE
DEFINE fecha_fin	DATE
DEFINE tit_mes		VARCHAR(10)
DEFINE tot_sueldo	DECIMAL(14,2)
DEFINE tot_descontar	DECIMAL(14,2)
DEFINE vm_agrupado	CHAR(1)
DEFINE vm_lineas_impr	SMALLINT



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/errores')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 3 AND num_args() <> 6 AND num_args() <> 7 AND num_args() <> 8 
THEN
	-- Validar # parametros correcto
	CALL fl_mostrar_mensaje('Numero de parametros incorrecto.','stop')
	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_proceso = 'rolp410'
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
DEFINE comando		CHAR(100)

CREATE TEMP TABLE temp_ing_rub(
		cod_trab		INTEGER,
		cod_rub			CHAR(3),
		nombre			VARCHAR(15,10),
		valor			DECIMAL(12,2),
		orden			INTEGER,
		depto			SMALLINT
	)
CREATE TEMP TABLE temp_des_rub(
		cod_trab		INTEGER,
		cod_rub			CHAR(3),
		nombre			VARCHAR(15,10),
		valor			DECIMAL(12,2),
		orden			INTEGER,
		det_tot			CHAR(2)
	)
CALL fl_nivel_isolation()
CALL fl_lee_compania(vg_codcia) RETURNING rm_cia.*
IF rm_cia.g01_compania IS NULL THEN
	CALL fl_mostrar_mensaje('No existe compañía.','stop')
	EXIT PROGRAM
END IF
CALL fl_lee_localidad(vg_codcia, vg_codloc) RETURNING rm_loc.*
IF rm_loc.g02_compania IS NULL THEN
	CALL fl_mostrar_mensaje('No existe localidad.','stop')
	EXIT PROGRAM
END IF
IF rm_loc.g02_localidad = 1 OR rm_loc.g02_localidad = 6 THEN
	LET vm_lineas_impr = 33
END IF
IF rm_loc.g02_localidad = 3 OR rm_loc.g02_localidad = 7 THEN
	LET vm_lineas_impr = 44
END IF
IF num_args() <> 3 THEN
	CALL control_reporte_llamada()
	EXIT PROGRAM
END IF
LET lin_menu = 0
LET row_ini  = 3
LET num_rows = 12
LET num_cols = 80
IF vg_gui = 0 THEN
	LET lin_menu = 1
	LET row_ini  = 4
	LET num_rows = 20
	LET num_cols = 78
END IF
OPEN WINDOW w_rol AT row_ini, 2 WITH num_rows ROWS, num_cols COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE lin_menu,
		  MESSAGE LINE LAST - 1, BORDER) 
IF vg_gui = 1 THEN
	OPEN FORM f_rol FROM "../forms/rolf410_1"
ELSE
--	OPEN FORM f_rol FROM "../forms/rolf410_1c"
	CALL fl_mostrar_mensaje('Este programa no se puede correr en modo caracter.',
			'stop')
	EXIT PROGRAM
END IF
DISPLAY FORM f_rol
INITIALIZE rm_n36.* TO NULL
LET vm_agrupado            = 'S'
LET rm_n36.n36_ano_proceso = YEAR(TODAY)
WHILE TRUE
	CALL lee_parametros()
	IF int_flag THEN
		EXIT WHILE
	END IF
	CALL fl_control_reportes() RETURNING comando
	IF int_flag THEN
		CONTINUE WHILE
	END IF
	CALL preparar_tablas()
	IF int_flag THEN
		CONTINUE WHILE
	END IF
	CALL control_reporte(comando)
	CLEAR g34_nombre, n30_nombres
	DELETE FROM temp_ing_rub
	DELETE FROM temp_des_rub
END WHILE
DROP TABLE temp_ing_rub
DROP TABLE temp_des_rub

END FUNCTION



FUNCTION control_reporte_llamada()
DEFINE comando		CHAR(100)

INITIALIZE rm_n36.* TO NULL
LET rm_n36.n36_ano_proceso = arg_val(4)
LET rm_n36.n36_proceso     = arg_val(5)
LET vm_agrupado            = arg_val(6)
IF num_args() = 7 THEN
	LET rm_n36.n36_cod_depto = arg_val(7)
END IF
IF num_args() = 8 THEN
	LET rm_n36.n36_cod_depto = arg_val(7)
	LET rm_n36.n36_cod_trab  = arg_val(8)
END IF
CALL fl_control_reportes() RETURNING comando
IF int_flag THEN
	RETURN
END IF
CALL preparar_tablas()
IF int_flag THEN
	RETURN
END IF
CALL control_reporte(comando)
DROP TABLE temp_ing_rub
DROP TABLE temp_des_rub

END FUNCTION



FUNCTION lee_parametros()
DEFINE anio		LIKE rolt036.n36_ano_proceso
DEFINE r_g34		RECORD LIKE gent034.*
DEFINE r_n03		RECORD LIKE rolt003.*
DEFINE r_n30		RECORD LIKE rolt030.*

LET int_flag = 0
INPUT BY NAME rm_n36.n36_ano_proceso, 
	rm_n36.n36_proceso, rm_n36.n36_cod_depto, rm_n36.n36_cod_trab,
	vm_agrupado
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		LET int_flag = 1
		RETURN
	ON KEY(F2)
		IF INFIELD(n36_cod_depto) THEN
                        CALL fl_ayuda_departamentos(vg_codcia)
                                RETURNING r_g34.g34_cod_depto, r_g34.g34_nombre
                        IF r_g34.g34_cod_depto IS NOT NULL THEN
				LET rm_n36.n36_cod_depto = r_g34.g34_cod_depto
                                DISPLAY BY NAME rm_n36.n36_cod_depto,
						r_g34.g34_nombre
                        END IF
                END IF
		IF INFIELD(n36_cod_trab) THEN
                        CALL fl_ayuda_codigo_empleado(vg_codcia)
                                RETURNING r_n30.n30_cod_trab, r_n30.n30_nombres
                        IF r_n30.n30_cod_trab IS NOT NULL THEN
                                LET rm_n36.n36_cod_trab = r_n30.n30_cod_trab
                                DISPLAY BY NAME rm_n36.n36_cod_trab,
						r_n30.n30_nombres
                        END IF
                END IF
		LET int_flag = 0
	BEFORE FIELD n36_ano_proceso
		LET anio = rm_n36.n36_ano_proceso
	AFTER FIELD n36_ano_proceso
		IF rm_n36.n36_ano_proceso IS NOT NULL THEN
			IF rm_n36.n36_ano_proceso > YEAR(TODAY) THEN
				CALL fl_mostrar_mensaje('El año no puede ser mayor al año vigente.', 'exclamation')
				NEXT FIELD n36_ano_proceso
			END IF
		ELSE
			LET rm_n36.n36_ano_proceso = anio
			DISPLAY BY NAME rm_n36.n36_ano_proceso
		END IF
	AFTER FIELD n36_proceso
		IF rm_n36.n36_proceso IS NOT NULL THEN
   			CALL fl_lee_proceso_roles(rm_n36.n36_proceso)
                        	RETURNING r_n03.*
			IF r_n03.n03_proceso IS NULL THEN
				CALL fgl_winmessage(vg_producto,'No existe el código de liquidación en la Compañía.','exclamation')
				NEXT FIELD n36_proceso
			ELSE
				IF r_n03.n03_proceso <> 'DT' AND
				   r_n03.n03_proceso <> 'DC'
				THEN
					CALL fl_mostrar_mensaje('Debe escojer DC o DT.',
							'exclamation')
					NEXT FIELD n36_proceso
				END IF
			END IF
			DISPLAY BY NAME r_n03.n03_nombre
		ELSE
			CLEAR n03_nombre
		END IF
	AFTER FIELD n36_cod_depto
                IF rm_n36.n36_cod_depto IS NOT NULL THEN
                        CALL fl_lee_departamento(vg_codcia,rm_n36.n36_cod_depto)
                                RETURNING r_g34.*
                        IF r_g34.g34_compania IS NULL  THEN
                                CALL fgl_winmessage(vg_producto, 'Departamento no existe.','exclamation')
                                NEXT FIELD n36_cod_depto
                        END IF
                        DISPLAY BY NAME r_g34.g34_nombre
		ELSE
			CLEAR g34_nombre
                END IF
	AFTER FIELD n36_cod_trab
		IF rm_n36.n36_cod_trab IS NOT NULL THEN
			CALL fl_lee_trabajador_roles(vg_codcia,
							rm_n36.n36_cod_trab)
                        	RETURNING r_n30.*
			IF r_n30.n30_compania IS NULL THEN
				CALL fgl_winmessage(vg_producto,'No existe el código de este empleado en la Compañía.','exclamation')
				NEXT FIELD n36_cod_trab
			END IF
			DISPLAY BY NAME r_n30.n30_nombres
		ELSE
			CLEAR n30_nombres
		END IF
END INPUT

END FUNCTION


   
FUNCTION preparar_tablas()
DEFINE r_n03		RECORD LIKE rolt003.*
DEFINE r_n06		RECORD LIKE rolt006.*
DEFINE r_n36		RECORD LIKE rolt036.*
DEFINE r_n37		RECORD LIKE rolt037.*
DEFINE query		CHAR(1200)
DEFINE tot_egr		DECIMAL(12,2)
DEFINE expr_depto	VARCHAR(100)
DEFINE expr_trab	VARCHAR(100)

CALL fl_lee_proceso_roles(rm_n36.n36_proceso) RETURNING r_n03.*

IF r_n03.n03_mes_ini > r_n03.n03_mes_fin THEN
	LET rm_n36.n36_fecha_ini = mdy(r_n03.n03_mes_ini, r_n03.n03_dia_ini,
				       rm_n36.n36_ano_proceso - 1)
ELSE
	LET rm_n36.n36_fecha_ini = mdy(r_n03.n03_mes_ini, r_n03.n03_dia_ini,
				       rm_n36.n36_ano_proceso)
END IF
LET rm_n36.n36_fecha_fin = mdy(r_n03.n03_mes_fin, r_n03.n03_dia_fin,
			       rm_n36.n36_ano_proceso)

LET fecha_ini = rm_n36.n36_fecha_ini
LET fecha_fin = rm_n36.n36_fecha_fin

LET expr_depto = NULL
IF rm_n36.n36_cod_depto IS NOT NULL THEN
	LET expr_depto = '   AND n36_cod_depto   = ', rm_n36.n36_cod_depto
END IF
LET expr_trab = NULL
IF rm_n36.n36_cod_trab IS NOT NULL THEN
	LET expr_trab = '   AND n36_cod_trab   = ', rm_n36.n36_cod_trab
END IF
LET query = 'SELECT * FROM rolt036 ',
		' WHERE n36_compania   = ', vg_codcia,
		'   AND n36_proceso    = "', rm_n36.n36_proceso, '"',
		'   AND n36_fecha_ini  = "', fecha_ini, '"',
		'   AND n36_fecha_fin  = "', fecha_fin, '"',
		'   AND n36_estado     <> "E"',
		expr_depto CLIPPED,
		expr_trab CLIPPED
--		' ORDER BY n36_orden'
PREPARE cons FROM query
DECLARE q_rolt036 CURSOR FOR cons
OPEN q_rolt036
FETCH q_rolt036 INTO r_n36.*
IF STATUS = NOTFOUND THEN
	CLOSE q_rolt036
	FREE q_rolt036
	LET int_flag = 1
	CALL fl_mensaje_consulta_sin_registros()
	RETURN
END IF
FOREACH q_rolt036 INTO r_n36.*
	DECLARE q_n37 CURSOR FOR
		SELECT * FROM rolt037
			WHERE n37_compania   = r_n36.n36_compania
			  AND n37_proceso    = r_n36.n36_proceso   
			  AND n37_fecha_ini  = r_n36.n36_fecha_ini
			  AND n37_fecha_fin  = r_n36.n36_fecha_fin
			  AND n37_cod_trab   = r_n36.n36_cod_trab
			  AND n37_num_prest  IS NULL
		UNION
		SELECT n37_compania,  n37_proceso, n37_fecha_ini,
  		       n37_fecha_fin, n37_cod_trab, n37_cod_rubro, 
 		       n37_num_prest, n37_orden, n37_det_tot, n37_imprime_0,
		       NVL(SUM(n37_valor), 0)
			FROM rolt037
			WHERE n37_compania   = r_n36.n36_compania
			  AND n37_proceso    = r_n36.n36_proceso   
			  AND n37_fecha_ini  = r_n36.n36_fecha_ini
			  AND n37_fecha_fin  = r_n36.n36_fecha_fin
			  AND n37_cod_trab   = r_n36.n36_cod_trab
			  AND n37_num_prest  IS NOT NULL
			GROUP BY n37_compania,  n37_proceso,  n37_fecha_ini,
  		       		 n37_fecha_fin, n37_cod_trab, n37_cod_rubro, 
 		       		 n37_num_prest, n37_orden,    n37_det_tot, 
				 n37_imprime_0
	
	LET tot_egr = 0
	FOREACH q_n37 INTO r_n37.*
		IF r_n37.n37_imprime_0 = 'N' THEN
			IF r_n37.n37_valor = 0 THEN
				CONTINUE FOREACH
			END IF
		END IF
		CALL fl_lee_rubro_roles(r_n37.n37_cod_rubro) RETURNING r_n06.*
		IF r_n37.n37_det_tot = 'DE' OR r_n37.n37_det_tot = 'TE' OR
		   r_n37.n37_det_tot = 'TI' OR r_n37.n37_det_tot = 'TN' THEN
			INSERT INTO temp_des_rub
				VALUES(r_n36.n36_cod_trab, r_n37.n37_cod_rubro,
					r_n06.n06_nombre_abr,
					r_n37.n37_valor,
					r_n37.n37_orden, r_n37.n37_det_tot)
			LET tot_egr = tot_egr + r_n37.n37_valor
		END IF
	END FOREACH

	INSERT INTO temp_ing_rub
			VALUES(r_n36.n36_cod_trab, 1, "Valor Bruto",
				r_n36.n36_valor_bruto, 1,
				r_n36.n36_cod_depto)
	INSERT INTO temp_des_rub
			VALUES(r_n36.n36_cod_trab, r_n37.n37_cod_rubro,
				"TOTAL INGRESOS", r_n36.n36_valor_bruto,
				r_n37.n37_orden, 'TI')
	INSERT INTO temp_des_rub
			VALUES(r_n36.n36_cod_trab, r_n37.n37_cod_rubro,
				"TOTAL DESCUENTOS", tot_egr,
				r_n37.n37_orden, 'TE')
	INSERT INTO temp_des_rub
			VALUES(r_n36.n36_cod_trab, r_n37.n37_cod_rubro,
				"TOTAL A RECIBIR", r_n36.n36_valor_neto,
				r_n37.n37_orden, 'TN')
END FOREACH


SELECT COUNT(*) INTO n1 FROM temp_ing_rub
SELECT COUNT(*) INTO n2 FROM temp_des_rub WHERE det_tot = 'DE'
IF n1 = 0 AND n2 = 0 THEN
	LET int_flag = 1
	CALL fl_mensaje_consulta_sin_registros()
	RETURN
END IF

END FUNCTION



FUNCTION control_reporte(comando)
DEFINE comando		CHAR(100)
DEFINE cod_traba	LIKE rolt036.n36_cod_trab
DEFINE sueldo		LIKE rolt036.n36_valor_neto
DEFINE proceso		LIKE rolt036.n36_proceso
DEFINE r_ing		RECORD
				cod_trab	LIKE rolt036.n36_cod_trab,
				cod_rub		LIKE rolt037.n37_cod_rubro,
				nombre		LIKE rolt006.n06_nombre_abr,
				valor		LIKE rolt036.n36_valor_bruto,
				orden		LIKE rolt033.n33_orden,
				depto		LIKE rolt036.n36_cod_depto
			END RECORD
DEFINE r_des		RECORD
				cod_trab	LIKE rolt037.n37_cod_trab,
				cod_rub		LIKE rolt037.n37_cod_rubro,
				nombre		LIKE rolt006.n06_nombre_abr,
				valor		LIKE rolt037.n37_valor,
				orden		LIKE rolt037.n37_orden,
				det_tot		LIKE rolt037.n37_det_tot
			END RECORD
DEFINE nom		LIKE rolt030.n30_nombres
DEFINE dep		LIKE gent034.g34_nombre
DEFINE expr_orden	CHAR(50)
DEFINE query		CHAR(400)
DEFINE tl1, tl2		INTEGER

LET expr_orden = ' ORDER BY 3, 2'
IF vm_agrupado = 'N' THEN
	LET expr_orden = ' ORDER BY 2'
END IF
LET query = 'SELECT UNIQUE cod_trab, n30_nombres, g34_nombre ',
		' FROM temp_ing_rub, rolt030, gent034 ',
		' WHERE n30_compania  = ', vg_codcia,
		'   AND cod_trab      = n30_cod_trab ',
		'   AND n30_compania  = g34_compania ',
		'   AND n30_cod_depto = g34_cod_depto ',
		expr_orden CLIPPED
PREPARE tmp_t1 FROM query
DECLARE q_t1 CURSOR FOR tmp_t1
START REPORT reporte_liq_rubros TO PIPE comando
--START REPORT reporte_liq_rubros TO FILE "liqrol.txt"
SELECT COUNT(DISTINCT cod_trab) INTO tl1 FROM temp_ing_rub
SELECT COUNT(DISTINCT cod_trab) INTO tl2 FROM temp_des_rub
LET tot_liq = tl1
IF tl2 > tl1 THEN
	LET tot_liq = tl2
END IF
LET fin_arch      = 0
LET num_liq       = 0
LET tot_sueldo    = 0
LET tot_descontar = 0
LET proceso       = rm_n36.n36_proceso
FOREACH q_t1 INTO cod_traba, nom, dep
	INITIALIZE rm_n36.* TO NULL
	SELECT * INTO rm_n36.* FROM rolt036
		WHERE n36_compania  = vg_codcia
		  AND n36_proceso   = proceso
		  AND n36_fecha_ini = fecha_ini
		  AND n36_fecha_fin = fecha_fin
		  AND n36_cod_trab  = cod_traba
	OUTPUT TO REPORT reporte_liq_rubros(cod_traba)
END FOREACH
FINISH REPORT reporte_liq_rubros
LET rm_n36.n36_cod_depto = NULL
LET rm_n36.n36_cod_trab  = NULL

END FUNCTION



REPORT reporte_liq_rubros(cod_traba)
DEFINE cod_traba	LIKE rolt036.n36_cod_trab
DEFINE r_ing		RECORD
				cod_trab	LIKE rolt037.n37_cod_trab,
				cod_rub		LIKE rolt033.n33_cod_rubro,
				nombre		LIKE rolt006.n06_nombre_abr,
				valor		LIKE rolt037.n37_valor,
				orden		LIKE rolt033.n33_orden,
				depto		LIKE rolt036.n36_cod_depto
			END RECORD
DEFINE r_des		RECORD
				cod_trab	LIKE rolt033.n33_cod_trab,
				cod_rub		LIKE rolt033.n33_cod_rubro,
				nombre		LIKE rolt003.n03_nombre_abr,
				valor		LIKE rolt033.n33_valor,
				orden		LIKE rolt033.n33_orden,
				det_tot		LIKE rolt033.n33_det_tot
			END RECORD
DEFINE r_n03		RECORD LIKE rolt003.*
DEFINE r_n06		RECORD LIKE rolt006.*
DEFINE r_n30		RECORD LIKE rolt030.*
DEFINE r_g13		RECORD LIKE gent013.*
DEFINE r_g34		RECORD LIKE gent034.*
DEFINE cod_r_i, cod_r_d	LIKE rolt033.n33_cod_rubro
DEFINE ord_i, ord_d	LIKE rolt033.n33_orden
DEFINE tot_val_i_a	DECIMAL(14,2)
DEFINE tot_val_d_a	DECIMAL(14,2)
DEFINE tot_val_i	DECIMAL(14,2)
DEFINE tot_val_d	DECIMAL(14,2)
DEFINE i, lim		INTEGER
DEFINE suel_t		VARCHAR(15)
DEFINE val_i, val_d	VARCHAR(10)
DEFINE nom_est		VARCHAR(10)
DEFINE mensaje		VARCHAR(80)
DEFINE titulo		VARCHAR(80)
DEFINE forma_pago	VARCHAR(31)
DEFINE nom_depto	VARCHAR(36)
DEFINE encont		SMALLINT
DEFINE lineas, postit	SMALLINT
DEFINE escape, act_des	SMALLINT
DEFINE act_comp, db_c	SMALLINT
DEFINE desact_comp, db	SMALLINT
DEFINE act_neg, des_neg	SMALLINT
DEFINE act_10cpi	SMALLINT
DEFINE act_12cpi	SMALLINT

OUTPUT
	TOP MARGIN	0
	LEFT MARGIN	0
	RIGHT MARGIN	96
	BOTTOM MARGIN	2
	PAGE LENGTH	vm_lineas_impr

FORMAT

PAGE HEADER
	--print 'E';
	--print '&l26A';	-- Indica que voy a trabajar con hojas A4
	LET escape	= 27		# Iniciar sec. impresi¢n
	LET act_comp	= 15		# Activar Comprimido.
	LET desact_comp	= 18		# Cancelar Comprimido.
	LET act_neg	= 71		# Activar negrita.
	LET des_neg	= 72		# Desactivar negrita.
	LET act_des	= 0
	LET act_10cpi	= 80		# Comprimido 10 CPI.
	LET act_12cpi	= 77		# Comprimido 12 CPI.
	CALL fl_lee_trabajador_roles(vg_codcia, cod_traba) RETURNING r_n30.*
	CALL fl_lee_moneda(rm_n36.n36_moneda) RETURNING r_g13.*
	CALL fl_lee_departamento(rm_n36.n36_compania, rm_n36.n36_cod_depto)
		RETURNING r_g34.*
	CALL fl_lee_proceso_roles(rm_n36.n36_proceso) RETURNING r_n03.*
	CALL retorna_estado(rm_n36.n36_estado) RETURNING nom_est
	CALL retorna_forma_pago(r_n30.n30_cod_trab) RETURNING forma_pago
	LET suel_t     = rm_n36.n36_valor_bruto USING "--,---,--&.##"
	--print '&k2S' 		-- Letra condensada
	--print ASCII escape;
	--print ASCII act_comp
	print ASCII escape;
	print ASCII act_neg;
	print ASCII escape;
	print ASCII act_12cpi
	IF NOT fin_arch THEN
		LET tot_sueldo = tot_sueldo + rm_n36.n36_valor_bruto
		LET nom_depto  = '** ', r_g34.g34_nombre CLIPPED, ' **'
		LET postit     = 96 - LENGTH(nom_depto) + 1
		PRINT COLUMN 001, rm_cia.g01_razonsocial,
		      COLUMN postit, nom_depto
		PRINT COLUMN 042, "RECIBO DE PAGO ", r_n03.n03_nombre_abr CLIPPED
		SKIP 1 LINES
		PRINT COLUMN 001, "NOMBRE(", r_n30.n30_cod_trab
						USING "&&&&", "): ",
				r_n30.n30_nombres[1,36],
		      COLUMN 055, "LIQUIDACION: ", rm_n36.n36_proceso, " ",
				r_n03.n03_nombre_abr
		PRINT COLUMN 001, "VALOR BRUTO : ", r_g13.g13_simbolo CLIPPED,
			" ", fl_justifica_titulo('I', suel_t, 15),
		      COLUMN 055, "PERIODO    : ", fecha_ini USING "dd-mm-yyyy",
				' - ', fecha_fin USING "dd-mm-yyyy"
		PRINT COLUMN 001, "FORMA PAGO  : ", forma_pago,
		      COLUMN 055, "ESTADO LIQ.: ", nom_est
		SKIP 1 LINES
		PRINT COLUMN 001, "INGRESOS    : ",
		      COLUMN 052, "DESCUENTOS    : ",
		      COLUMN 078, DATE(TODAY) USING 'dd-mm-yyyy', 1 SPACES, TIME
		PRINT "------------------------------------------------------------------------------------------------";
	ELSE
		LET suel_t = tot_sueldo USING "--,---,--&.##"
		PRINT COLUMN 001, rm_cia.g01_razonsocial
		PRINT COLUMN 037, "RECIBO DE PAGO ", r_n03.n03_nombre_abr CLIPPED, " - TOTALES"
		SKIP 1 LINES
		PRINT COLUMN 001, "TOTALES     : No. de Liquidaciones ",
			num_liq USING "###",
		      COLUMN 055, "LIQUIDACION: ", rm_n36.n36_proceso, " ",
				r_n03.n03_nombre_abr
		PRINT COLUMN 001, "VALOR BRUTO : ", r_g13.g13_simbolo CLIPPED,
			" ", fl_justifica_titulo('I', suel_t, 15),
		      COLUMN 055, "PERIODO    : ", fecha_ini USING "dd-mm-yyyy",
				' - ', fecha_fin USING "dd-mm-yyyy"
		SKIP 2 LINES
		PRINT COLUMN 001, "INGRESOS    : ",
		      COLUMN 052, "DESCUENTOS    : ",
		      COLUMN 078, DATE(TODAY) USING 'dd-mm-yyyy', 1 SPACES, TIME
		PRINT "------------------------------------------------------------------------------------------------";
	END IF
	print ASCII escape;
	print ASCII des_neg

ON EVERY ROW
	DECLARE q_ing1 CURSOR FOR
		SELECT * FROM temp_ing_rub
			WHERE cod_trab = cod_traba
--			ORDER BY orden
	DECLARE q_des1 CURSOR FOR
		SELECT * FROM temp_des_rub
			WHERE cod_trab = cod_traba
			  AND det_tot = 'DE'
			ORDER BY orden
	OPEN q_ing1
	OPEN q_des1
	SELECT COUNT(*) INTO n1 FROM temp_ing_rub
		WHERE cod_trab = cod_traba
	SELECT COUNT(*) INTO n2 FROM temp_des_rub
		WHERE cod_trab = cod_traba
		  AND det_tot = 'DE'
	LET lim = n1
	IF n2 > n1 THEN
		LET lim = n2
	END IF
	FOR i = 1 TO lim
		INITIALIZE r_ing.*, r_des.* TO NULL
		FETCH q_ing1 INTO r_ing.*
		FETCH q_des1 INTO r_des.*
		LET val_i = NULL
{
		IF r_ing.valor_aux > 0 THEN
			LET val_i = r_ing.valor_aux	USING "###.##"
		END IF
		LET val_d = NULL
		IF r_des.valor_aux > 0 THEN
			LET val_d = r_des.valor_aux	USING "###.##"
		END IF
}
		PRINT 
		      COLUMN 001, r_ing.nombre,
--		      COLUMN 023, val_i,
		      COLUMN 033, r_ing.valor		USING "--,---,--&.##",
		      COLUMN 052, r_des.cod_rub		USING "&&&",
		      COLUMN 056, r_des.nombre,
--		      COLUMN 074, val_d,
		      COLUMN 084, r_des.valor		USING "--,---,--&.##"
	END FOR
	CLOSE q_ing1
	CLOSE q_des1
	FREE q_ing1
	FREE q_des1
	SKIP 1 LINES
	PRINT COLUMN 033, "-------------",
	      COLUMN 084, "-------------"
	SELECT * INTO r_des.* FROM temp_des_rub
		WHERE cod_trab = cod_traba
		  AND det_tot = 'TI'
	PRINT COLUMN 001, r_des.nombre,
      	      COLUMN 033, r_des.valor		USING "--,---,--&.##";
	SELECT * INTO r_des.* FROM temp_des_rub
		WHERE cod_trab = cod_traba
		  AND det_tot = 'TE'
	PRINT COLUMN 052, r_des.nombre,
              COLUMN 084, r_des.valor		USING "--,---,--&.##"
	SKIP 1 LINES
	SELECT * INTO r_des.* FROM temp_des_rub
		WHERE cod_trab = cod_traba
		  AND det_tot = 'TN'
	PRINT COLUMN 001, ASCII escape, ASCII act_neg;
	PRINT COLUMN 001, r_des.nombre,
	      COLUMN 033, 2 SPACES, r_des.valor	USING "--,---,--&.##",
	                  ASCII escape, ASCII des_neg, 2 SPACES
{
	DECLARE q_desxqui CURSOR FOR SELECT * FROM temp_ing_rub
		WHERE cod_trab = cod_traba
	INITIALIZE r_ing.* TO NULL
	LET encont = 0
	FOREACH q_desxqui INTO r_ing.*
		CALL fl_lee_rubro_roles(r_ing.cod_rub) RETURNING r_n06.*
		IF r_n06.n06_flag_ident = 'SI' THEN
			LET encont = 1
			EXIT FOREACH
		END IF
	END FOREACH
	PRINT 4 SPACES, "DESCONTAR PROX. QUINCENA";
	IF encont THEN
		LET tot_descontar = tot_descontar + r_ing.valor
		PRINT 8 SPACES, r_ing.valor	USING "--,---,--&.##"
	ELSE
		PRINT 8 SPACES, "0.00"		USING "--,---,--&.##"
	END IF
}
	PRINT COLUMN 033, ASCII escape, ASCII act_neg;
	PRINT COLUMN 033, "=============",
			  ASCII escape, ASCII des_neg
	SKIP 2 LINES
	PRINT COLUMN 001, "RECIBI CONFORME: _________________________";
	--print ASCII escape;
	--print ASCII desact_comp;
	print ASCII escape;
	print ASCII act_10cpi
	LET num_liq = num_liq + 1
	IF num_liq = tot_liq THEN
		LET fin_arch = 1
	END IF
	LET lineas  = vm_lineas_impr - LINENO
	SKIP lineas LINES

ON LAST ROW
	print ASCII escape;
	print ASCII act_12cpi
	DECLARE q_ing1_t CURSOR FOR
		SELECT UNIQUE cod_rub FROM temp_ing_rub -- ORDER BY orden
	DECLARE q_des1_t CURSOR FOR
		SELECT UNIQUE cod_rub, orden FROM temp_des_rub
			WHERE det_tot = 'DE'
			ORDER BY orden
	OPEN q_ing1_t
	OPEN q_des1_t
	SELECT COUNT(DISTINCT cod_rub) INTO n1 FROM temp_ing_rub
	SELECT COUNT(DISTINCT cod_rub) INTO n2 FROM temp_des_rub
		WHERE det_tot = 'DE'
	LET lim = n1
	IF n2 > n1 THEN
		LET lim = n2
	END IF
	FOR i = 1 TO lim
		INITIALIZE r_ing.*, r_des.*, cod_r_i, cod_r_d TO NULL
		FETCH q_ing1_t INTO cod_r_i, ord_i
		FETCH q_des1_t INTO cod_r_d, ord_d
		LET val_i     = NULL
		LET tot_val_i = NULL
		IF cod_r_i IS NOT NULL THEN
			DECLARE q_ing1_t2 CURSOR FOR
				SELECT * FROM temp_ing_rub
					WHERE cod_rub = cod_r_i
--					ORDER BY orden
			LET tot_val_i_a = 0
			LET tot_val_i   = 0
			FOREACH q_ing1_t2 INTO r_ing.*
--				LET tot_val_i_a = tot_val_i_a + r_ing.valor_aux
				LET tot_val_i   = tot_val_i   + r_ing.valor
			END FOREACH
			IF tot_val_i_a > 0 THEN
				LET val_i = tot_val_i_a		USING "#,###.##"
			END IF
		END IF
		LET val_d     = NULL
		LET tot_val_d = NULL
		IF cod_r_d IS NOT NULL THEN
			DECLARE q_des1_t2 CURSOR FOR
				SELECT * FROM temp_des_rub
					WHERE cod_rub = cod_r_d
					  AND det_tot = 'DE'
					ORDER BY orden
			LET tot_val_d_a = 0
			LET tot_val_d   = 0
			FOREACH q_des1_t2 INTO r_des.*
--				LET tot_val_d_a = tot_val_d_a + r_des.valor_aux
				LET tot_val_d   = tot_val_d   + r_des.valor
			END FOREACH
			IF tot_val_d_a > 0 THEN
				LET val_d = tot_val_d_a		USING "###.##"
			END IF
		END IF
		PRINT 
		      COLUMN 001, r_ing.nombre,
--		      COLUMN 023, val_i,
		      COLUMN 033, tot_val_i		USING "--,---,--&.##",
		      COLUMN 052, r_des.cod_rub		USING "&&&",
		      COLUMN 056, r_des.nombre,
		      --COLUMN 074, val_d,
		      COLUMN 084, tot_val_d		USING "--,---,--&.##"
	END FOR
	CLOSE q_ing1_t
	CLOSE q_des1_t
	FREE q_ing1_t
	FREE q_des1_t
	--SKIP 1 LINES
	print ASCII escape;
	print ASCII act_neg
	PRINT COLUMN 033, "-------------",
	      COLUMN 084, "-------------"
	SELECT nombre, SUM(valor) INTO r_des.nombre, r_des.valor
		FROM temp_des_rub
		WHERE det_tot = 'TI'
		GROUP BY nombre
	PRINT COLUMN 001, r_des.nombre,
      	      COLUMN 033, r_des.valor		USING "--,---,--&.##";
	SELECT nombre, SUM(valor) INTO r_des.nombre, r_des.valor
		FROM temp_des_rub
		WHERE det_tot = 'TE'
		GROUP BY nombre
	PRINT COLUMN 052, r_des.nombre,
              COLUMN 084, r_des.valor		USING "--,---,--&.##"
	SKIP 1 LINES
	SELECT nombre, SUM(valor) INTO r_des.nombre, r_des.valor
		FROM temp_des_rub
		WHERE det_tot = 'TN'
		GROUP BY nombre
	PRINT COLUMN 001, r_des.nombre,
	      COLUMN 033, r_des.valor	USING "--,---,--&.##"
	                  --ASCII escape, ASCII des_neg, 2 SPACES
{
	      COLUMN 052, "DESCONTAR PROX. QUINCENA",
	      COLUMN 084, tot_descontar	USING "--,---,--&.##"
}
	--PRINT COLUMN 033, ASCII escape, ASCII act_neg;
	PRINT COLUMN 033, "============="
	print ASCII escape, ASCII des_neg;
	--print ASCII escape;
	--print ASCII desact_comp;
	print ASCII escape;
	print ASCII act_10cpi

END REPORT



FUNCTION retorna_estado(estado)
DEFINE estado		LIKE rolt032.n32_estado

CASE estado
	WHEN 'A'
		RETURN "EN PROCESO"
	WHEN 'P'
		RETURN "PROCESADO"
END CASE

END FUNCTION



FUNCTION retorna_forma_pago(cod_trab)
DEFINE cod_trab		LIKE rolt030.n30_cod_trab
DEFINE r_n36		RECORD LIKE rolt036.*
DEFINE forma_pago	VARCHAR(31)

--CALL fl_lee_trabajador_roles(vg_codcia, cod_trab) RETURNING r_n30.*
INITIALIZE r_n36.* TO NULL
SELECT * INTO r_n36.*
	FROM rolt036
	WHERE n36_compania   = vg_codcia
	  AND n36_proceso    = rm_n36.n36_proceso
	  AND n36_fecha_ini  = fecha_ini
	  AND n36_fecha_fin  = fecha_fin
	  AND n36_cod_trab   = cod_trab
CASE r_n36.n36_tipo_pago
	WHEN 'E'
		LET forma_pago = 'EFECTIVO'
	WHEN 'C'
		LET forma_pago = 'CHEQUE'
	WHEN 'T'
		LET forma_pago = 'DEPOSITO A CTA. ',
				r_n36.n36_cta_trabaj CLIPPED
END CASE
RETURN forma_pago

END FUNCTION
