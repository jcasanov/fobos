--------------------------------------------------------------------------------
-- Titulo           : rolp422.4gl - Listado proyección de jubilados
-- Elaboracion      : 26-Nov-2003
-- Autor            : NPC
-- Formato Ejecucion: fglrun rolp422 base módulo compañía [año] [mes]
-- Ultima Correccion: 
-- Motivo Correccion:
--------------------------------------------------------------------------------

GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE rm_g01		RECORD LIKE gent001.*
DEFINE rm_g02		RECORD LIKE gent002.*
DEFINE vm_anio		LIKE rolt032.n32_ano_proceso
DEFINE vm_mes		LIKE rolt032.n32_mes_proceso
DEFINE anio_ini		LIKE rolt032.n32_ano_proceso
DEFINE anio_tope_min	LIKE rolt032.n32_ano_proceso
DEFINE num_empl		SMALLINT
DEFINE tiempo_trab	SMALLINT



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/rolp422.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 3 AND num_args() <> 5 THEN	-- Validar # parametros correcto
	CALL fl_mostrar_mensaje('Numero de parametros incorrecto.','stop')
	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_proceso = 'rolp422'
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
CALL fl_lee_compania(vg_codcia) RETURNING rm_g01.*
IF rm_g01.g01_compania IS NULL THEN
	CALL fl_mostrar_mensaje('No existe compañía.','stop')
	EXIT PROGRAM
END IF
CALL fl_lee_localidad(vg_codcia, vg_codloc) RETURNING rm_g02.*
IF rm_g02.g02_compania IS NULL THEN
	CALL fl_mostrar_mensaje('No existe localidad.','stop')
	EXIT PROGRAM
END IF
CREATE TEMP TABLE temp_jubilado
	(
		cod_trab	SMALLINT,
		nombres		VARCHAR(45,25),
		cedula		CHAR(15),
		ced_seg		CHAR(15),
		fecha_ing	DATE,
		fecha_nacim	DATE,
		diez_anios	VARCHAR(2),
		anios_antig	SMALLINT,
		mes_antig	SMALLINT,
		anios_edad	SMALLINT,
		mes_edad	SMALLINT,
		prom_mes	DECIMAL(12,2),
		prom_mes_vig	DECIMAL(12,2),
		cargo		VARCHAR(30,15),
		estado		CHAR(1)
	)
LET tiempo_trab   = 10
LET anio_tope_min = TODAY
SELECT MIN(n32_ano_proceso) INTO anio_tope_min FROM rolt032
	WHERE n32_compania = vg_codcia
IF num_args() <> 3 THEN
	CALL control_reporte_llamada()
	EXIT PROGRAM
END IF
LET lin_menu = 0
LET row_ini  = 3
LET num_rows = 8
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
	OPEN FORM f_rol FROM "../forms/rolf422_1"
ELSE
	OPEN FORM f_rol FROM "../forms/rolf422_1c"
END IF
DISPLAY FORM f_rol
LET vm_anio = YEAR(TODAY)
LET vm_mes  = MONTH(TODAY)
WHILE TRUE
	CALL lee_parametros()
	IF int_flag THEN
		EXIT WHILE
	END IF
	CALL imprimir()
	DELETE FROM temp_jubilado
END WHILE
DROP TABLE temp_jubilado

END FUNCTION



FUNCTION control_reporte_llamada()

LET vm_anio = arg_val(4)
LET vm_mes  = arg_val(5)
CALL imprimir()
DROP TABLE temp_jubilado

END FUNCTION



FUNCTION imprimir()
DEFINE comando		CHAR(100)

CALL fl_control_reportes() RETURNING comando
IF int_flag THEN
	RETURN
END IF
CALL control_reporte(comando)

END FUNCTION



FUNCTION lee_parametros()
DEFINE anio		LIKE rolt032.n32_ano_proceso
DEFINE mes		LIKE rolt032.n32_mes_proceso
DEFINE mensaje		VARCHAR(100)

LET int_flag = 0
INPUT BY NAME vm_anio, vm_mes
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		LET int_flag = 1
		RETURN
	BEFORE FIELD vm_anio
		LET anio = vm_anio
	BEFORE FIELD vm_mes
		LET mes = vm_mes
	AFTER FIELD vm_anio
		IF vm_anio IS NOT NULL THEN
			IF vm_anio > YEAR(TODAY) THEN
				CALL fl_mostrar_mensaje('El año no puede ser mayor al año vigente.', 'exclamation')
				NEXT FIELD vm_anio
			END IF
		ELSE
			LET vm_anio = anio
			DISPLAY BY NAME vm_anio
		END IF
	AFTER FIELD vm_mes
		IF vm_mes IS NOT NULL THEN
			IF vm_mes > MONTH(TODAY) THEN
				CALL fl_mostrar_mensaje('El mes no puede ser mayor al mes vigente.', 'exclamation')
				NEXT FIELD vm_mes
			END IF
		ELSE
			LET vm_mes = mes
			DISPLAY BY NAME vm_mes
		END IF
	AFTER INPUT
		IF vm_anio < anio_tope_min THEN
			LET mensaje = 'El año no puede ser menor al año ',
					anio_tope_min USING "&&&&", '.'
			CALL fl_mostrar_mensaje(mensaje, 'exclamation')
			NEXT FIELD vm_anio
		END IF
END INPUT

END FUNCTION


   
FUNCTION control_reporte(comando)
DEFINE comando		CHAR(100)
DEFINE r_report		RECORD
				cod_trab	LIKE rolt030.n30_cod_trab,
				nombres		LIKE rolt030.n30_nombres,
				cedula		LIKE rolt030.n30_num_doc_id,
				ced_seg		LIKE rolt030.n30_carnet_seg,
				fecha_ing	LIKE rolt030.n30_fecha_ing,
				fecha_nacim	LIKE rolt030.n30_fecha_nacim,
				diez_anios	VARCHAR(2),
				anios_antig	SMALLINT,
				mes_antig	SMALLINT,
				anios_edad	SMALLINT,
				mes_edad	SMALLINT,
				prom_mes	DECIMAL(12,2),
				prom_mes_vig	DECIMAL(12,2),
				cargo		LIKE gent035.g35_nombre
			END RECORD
DEFINE r_g35		RECORD LIKE gent035.*
DEFINE r_n30		RECORD LIKE rolt030.*
DEFINE fec_ini		LIKE rolt032.n32_fecha_ini
DEFINE fec_fin		LIKE rolt032.n32_fecha_fin
DEFINE query		CHAR(800)
DEFINE fecha		DATE
DEFINE dias		SMALLINT

LET query = 'SELECT * FROM rolt030 ',
		' WHERE n30_compania = ', vg_codcia,
		'   AND n30_estado   <> "B" '
PREPARE cons FROM query
DECLARE q_rolt030 CURSOR FOR cons
OPEN q_rolt030
FETCH q_rolt030 INTO r_n30.*
IF STATUS = NOTFOUND THEN
	CLOSE q_rolt030
	FREE q_rolt030
	LET int_flag = 1
	CALL fl_mensaje_consulta_sin_registros()
	RETURN
END IF
LET fecha = TODAY
IF vm_anio < YEAR(fecha) THEN
	LET fecha = MDY(12, 31, vm_anio)
END IF
LET anio_ini = vm_anio - 4
IF anio_ini < anio_tope_min THEN
	LET anio_ini = anio_tope_min
END IF
FOREACH q_rolt030 INTO r_n30.*
	LET r_report.cod_trab    = r_n30.n30_cod_trab
	LET r_report.nombres     = r_n30.n30_nombres
	LET r_report.cedula	 = r_n30.n30_num_doc_id
	LET r_report.ced_seg	 = r_n30.n30_carnet_seg
	LET r_report.fecha_ing   = r_n30.n30_fecha_ing
	LET r_report.fecha_nacim = r_n30.n30_fecha_nacim
	CALL fl_retorna_anios_meses_dias(fecha, r_n30.n30_fecha_ing)
		RETURNING r_report.anios_antig, r_report.mes_antig, dias
	IF (r_report.anios_antig >= tiempo_trab) THEN
		LET r_report.diez_anios = 'SI'
	ELSE
		LET r_report.diez_anios = 'NO'
	END IF
	CALL fl_retorna_anios_meses_dias(fecha, r_n30.n30_fecha_nacim)
		RETURNING r_report.anios_edad, r_report.mes_edad, dias
	LET fec_ini = MDY(vm_mes, 01, anio_ini)
	LET fec_fin = MDY(vm_mes, 01, vm_anio) + 1 UNITS MONTH - 1 UNITS DAY
	SELECT ROUND(((SUM(n32_tot_neto) / 5) / 12), 2) INTO r_report.prom_mes
		FROM rolt032
		WHERE n32_compania      = r_n30.n30_compania
		  AND n32_fecha_ini    >= fec_ini
		  AND n32_fecha_fin    <= fec_fin
		  AND n32_cod_trab      = r_n30.n30_cod_trab
		  AND n32_estado        = 'C'
		{--
		  AND (n32_ano_proceso >= anio_ini
			AND n32_ano_proceso <= vm_anio)
		--}
	SELECT ROUND(((SUM(n32_tot_neto) / 5)/ 12),2) INTO r_report.prom_mes_vig
		FROM rolt032
		WHERE n32_compania   = r_n30.n30_compania
		  AND n32_fecha_ini >= fec_ini
		  AND n32_fecha_fin <= fec_fin
		  AND n32_cod_trab   = r_n30.n30_cod_trab
		  AND n32_estado     = 'C'
		  --AND n32_ano_proceso = vm_anio
	CALL fl_lee_cargo(r_n30.n30_compania, r_n30.n30_cod_cargo)
		RETURNING r_g35.*
	LET r_report.cargo = r_g35.g35_nombre
	IF r_n30.n30_estado = 'J' THEN
		LET r_report.cargo = 'JUBILADO'
	END IF
	INSERT INTO temp_jubilado VALUES(r_report.*, r_n30.n30_estado)
END FOREACH
DECLARE q_tmp1 CURSOR FOR
	SELECT * FROM temp_jubilado
		WHERE estado = 'A'
		ORDER BY nombres
START REPORT reporte_proyeccion_jubilados TO PIPE comando
--START REPORT reporte_proyeccion_jubilados TO FILE "proyeccion_jubilados.txt"
LET num_empl = 0
FOREACH q_tmp1 INTO r_report.*, r_n30.n30_estado
	OUTPUT TO REPORT reporte_proyeccion_jubilados(r_report.*)
END FOREACH
FINISH REPORT reporte_proyeccion_jubilados

END FUNCTION



REPORT reporte_proyeccion_jubilados(r_report)
DEFINE r_report		RECORD
				cod_trab	LIKE rolt030.n30_cod_trab,
				nombres		LIKE rolt030.n30_nombres,
				cedula		LIKE rolt030.n30_num_doc_id,
				ced_seg		LIKE rolt030.n30_carnet_seg,
				fecha_ing	LIKE rolt030.n30_fecha_ing,
				fecha_nacim	LIKE rolt030.n30_fecha_nacim,
				diez_anios	VARCHAR(2),
				anios_antig	SMALLINT,
				mes_antig	SMALLINT,
				anios_edad	SMALLINT,
				mes_edad	SMALLINT,
				prom_mes	DECIMAL(12,2),
				prom_mes_vig	DECIMAL(12,2),
				cargo		LIKE gent035.g35_nombre
			END RECORD
DEFINE estado		LIKE rolt030.n30_estado
DEFINE usuario		VARCHAR(19,15)
DEFINE titulo		VARCHAR(80)
DEFINE modulo		VARCHAR(40)
DEFINE fecha		VARCHAR(40)
DEFINE mes, mes_aux	VARCHAR(10)
DEFINE escape, act_des	SMALLINT
DEFINE i, j		SMALLINT
DEFINE act_comp, db_c	SMALLINT
DEFINE desact_comp, db	SMALLINT
DEFINE act_neg, des_neg	SMALLINT
DEFINE act_10cpi	SMALLINT
DEFINE act_12cpi	SMALLINT

OUTPUT
	TOP MARGIN	1
	LEFT MARGIN	2
	RIGHT MARGIN	225
	BOTTOM MARGIN	4
	PAGE LENGTH	66

FORMAT

PAGE HEADER
	LET escape	= 27		# Iniciar sec. impresi¢n
	LET act_comp	= 15		# Activar Comprimido.
	LET desact_comp	= 18		# Cancelar Comprimido.
	LET act_neg	= 71		# Activar negrita.
	LET des_neg	= 72		# Desactivar negrita.
	LET act_des	= 0
	LET act_10cpi	= 80		# Comprimido 10 CPI.
	LET act_12cpi	= 77		# Comprimido 12 CPI.
	LET modulo  = "MODULO: NOMINA"
	LET usuario = 'USUARIO: ', vg_usuario
	CALL fl_justifica_titulo('D', usuario, 19) RETURNING usuario
	LET titulo = "JUBILACION CORRESPONDIENTE AL ANIO ", vm_anio USING '<<<<'
	CALL fl_justifica_titulo('I', titulo, 80)
		RETURNING titulo
	--LET mes_aux = fl_retorna_nombre_mes(MONTH(TODAY))
	LET mes_aux = fl_retorna_nombre_mes(vm_mes)
	LET mes     = ' '
	LET j       = 1
	FOR i = 1 TO LENGTH(mes_aux)
		IF mes_aux[i, i] <> ' ' THEN
			LET mes[j, j] = mes_aux[i, i]
			LET j = j + 1
		END IF
	END FOR
	LET fecha = DAY(TODAY) USING '&&', " de ",
			fl_justifica_titulo('I', mes, LENGTH(mes)), " del ",
			vm_anio USING '&&&&'
	print ASCII escape;
	print ASCII act_comp;
	print ASCII escape;
	print ASCII act_neg
	PRINT COLUMN 001, rm_g01.g01_razonsocial,
  	      COLUMN 213, "PAGINA: ", PAGENO USING "&&&"
	PRINT COLUMN 001, modulo CLIPPED,
	      COLUMN 077, titulo CLIPPED,
	      COLUMN 225 - LENGTH(fecha) - 1, fecha CLIPPED
	SKIP 1 LINES
	PRINT COLUMN 005, "CUADRO TOTAL"
	SKIP 1 LINES
	PRINT COLUMN 001, "-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------"
	PRINT COLUMN 122, tiempo_trab USING "&&",
	      COLUMN 126, "- ANTIGUEDAD -",
	      COLUMN 144, "---- EDAD ----",
	      COLUMN 162, " PROMEDIO MES ",
	      COLUMN 181, "PROM. MES"
	PRINT COLUMN 001, "COD.",
	      COLUMN 007, "          E  M  P  L  E  A  D  O  S",
	      COLUMN 058, "CEDULA DE IDEN.",
	      COLUMN 076, "  CARNET SEGURO",
	      COLUMN 094, "FEC. INGR.",
	      COLUMN 107, "FEC.NACIDO",
	      COLUMN 120, "ANIOS",
	      COLUMN 126, "ANIOS",
	      COLUMN 135, "MESES",
	      COLUMN 144, "ANIOS",
	      COLUMN 153, "MESES",
	      COLUMN 162, anio_ini USING '&&&&', "  --  ",
			  vm_anio USING '&&&&',
	      COLUMN 183, vm_anio USING '&&&&',
	      COLUMN 193, "CARGO DEL EMPLEADO"
	PRINT COLUMN 001, "-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------";
	print ASCII escape;
	print ASCII des_neg

ON EVERY ROW
	NEED 3 LINES
	PRINT COLUMN 001, r_report.cod_trab		USING "&&&&",
	      COLUMN 007, r_report.nombres,
	      COLUMN 058, r_report.cedula		USING "&&&&&&&&&&",
	      COLUMN 076, r_report.ced_seg		USING "&&&&&&&&&&&&&&&",
	      COLUMN 094, r_report.fecha_ing 		USING "dd-mm-yyyy",
	      COLUMN 107, r_report.fecha_nacim 		USING "dd-mm-yyyy",
	      COLUMN 122, r_report.diez_anios,
	      COLUMN 127, r_report.anios_antig 		USING "--&&",
	      COLUMN 136, r_report.mes_antig 		USING "--&&",
	      COLUMN 145, r_report.anios_edad 		USING "--&&",
	      COLUMN 154, r_report.mes_edad 		USING "--&&",
	      COLUMN 161, r_report.prom_mes		USING "--,---,--&.##",
	      COLUMN 177, r_report.prom_mes_vig		USING "--,---,--&.##",
	      COLUMN 193, r_report.cargo CLIPPED
	LET num_empl = num_empl + 1

ON LAST ROW
	NEED 2 LINES
	print ASCII escape;
	print ASCII act_neg
	PRINT COLUMN 059, "PROMEDIO ANIOS ==> ",
	      COLUMN 078, SUM(r_report.anios_antig) / num_empl USING "--&.##",
	      COLUMN 092, SUM(r_report.anios_edad) / num_empl  USING "--&.##",
	      COLUMN 140, "PROMEDIO SUELDOS ==> ",
	      COLUMN 161, SUM(r_report.prom_mes) / num_empl
			USING "--,---,--&.##",
	      COLUMN 177, SUM(r_report.prom_mes_vig) / num_empl
			USING "--,---,--&.##";
	print ASCII escape;
	print ASCII des_neg;
	SELECT COUNT(*) INTO num_empl FROM temp_jubilado WHERE estado = 'J'
	IF num_empl > 0 THEN
		PRINT 1 SPACES
		SKIP 1 LINES
		DECLARE q_tmp2 CURSOR FOR
			SELECT * FROM temp_jubilado
				WHERE estado = 'J'
				ORDER BY nombres
		PRINT COLUMN 001, "-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------"
		FOREACH q_tmp2 INTO r_report.*, estado
			PRINT COLUMN 001, r_report.cod_trab	USING "&&&&",
			      COLUMN 007, r_report.nombres,
			      COLUMN 058, r_report.cedula,
			      COLUMN 076, r_report.ced_seg,
			      COLUMN 094, r_report.fecha_ing USING "dd-mm-yyyy",
			      COLUMN 107, r_report.fecha_nacim
					USING "dd-mm-yyyy",
			      COLUMN 145, r_report.anios_edad USING "--&&",
			      COLUMN 154, r_report.mes_edad USING "--&&",
			      COLUMN 161, r_report.prom_mes
					USING "--,---,--&.##",
			      COLUMN 193, r_report.cargo CLIPPED
		END FOREACH
	END IF
	print ASCII escape;
	print ASCII desact_comp

END REPORT
