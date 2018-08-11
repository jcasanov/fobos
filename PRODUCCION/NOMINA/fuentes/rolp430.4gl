------------------------------------------------------------------------------
-- Titulo           : rolp430.4gl - Planilla del Club
-- Elaboracion      : 23-Sep-2003
-- Autor            : NPC
-- Formato Ejecucion: fglrun rolp430 base modulo compañía
-- Ultima Correccion: 
-- Motivo Correccion: 
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE rm_n00		RECORD LIKE rolt000.*
DEFINE rm_n63		RECORD LIKE rolt063.*
DEFINE rm_g01		RECORD LIKE gent001.*
DEFINE rm_g02		RECORD LIKE gent002.*
DEFINE r_report		ARRAY[200] OF RECORD
		nom_depto	LIKE gent034.g34_nombre,
		cod_trab	LIKE rolt063.n63_cod_trab,
		nom_trab	LIKE rolt030.n30_nombres,
		aporte		LIKE rolt061.n61_cuota,
		prestamo	LIKE rolt065.n65_valor,
		casa_com	ARRAY[30] OF RECORD
					cod_alm	LIKE rolt063.n63_cod_almacen,
					valor	LIKE rolt063.n63_valor
				END RECORD
			END RECORD
DEFINE vm_max_rep	SMALLINT
DEFINE vm_num_rep	SMALLINT
DEFINE vm_max_cas	SMALLINT
DEFINE vm_num_cas	SMALLINT
DEFINE vm_tot_valor	DECIMAL(14,2)
DEFINE vm_agrupado	CHAR(1)
DEFINE vm_cabecera	SMALLINT



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/errores')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 3 THEN
	-- Validar # parámetros correcto
	CALL fl_mostrar_mensaje('Número de parámetros incorrecto.','stop')
	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_proceso = 'rolp430'
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
DEFINE resul	 	SMALLINT

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
LET lin_menu = 0
LET row_ini  = 3
LET num_rows = 10
LET num_cols = 80
IF vg_gui = 0 THEN
	LET lin_menu = 1
	LET row_ini  = 4
	LET num_rows = 20
	LET num_cols = 78
END IF
OPEN WINDOW w_rol1 AT row_ini, 2 WITH num_rows ROWS, num_cols COLUMNS
	ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE lin_menu,
		  MESSAGE LINE LAST, BORDER) 
IF vg_gui = 1 THEN
	OPEN FORM f_rolf430_1 FROM '../forms/rolf430_1'
ELSE
	OPEN FORM f_rolf430_1 FROM '../forms/rolf430_1c'
END IF
DISPLAY FORM f_rolf430_1
LET vm_max_rep  = 200
LET vm_max_cas  = 30
LET vm_agrupado = 'S'
CALL cargar_datos_liq() RETURNING resul
IF resul THEN
	RETURN
END IF
WHILE TRUE
	CALL mostrar_datos_liq()
	CALL lee_parametros()
	IF int_flag THEN
		EXIT WHILE
	END IF
	CALL control_reporte()
END WHILE

END FUNCTION



FUNCTION cargar_datos_liq()
DEFINE r_n01		RECORD LIKE rolt001.*
DEFINE r_n63		RECORD LIKE rolt063.*

INITIALIZE rm_n63.* TO NULL
CALL fl_lee_parametro_general_roles()  RETURNING rm_n00.*
IF rm_n00.n00_serial IS NULL THEN
        CALL fl_mostrar_mensaje('No existe configuración general para este módulo.', 'stop')
	RETURN 1
END IF
CALL fl_lee_compania_roles(vg_codcia) RETURNING r_n01.*
IF r_n01.n01_compania IS NULL THEN
        CALL fl_mostrar_mensaje('No existe configuración para esta compañía.', 'stop')
	RETURN 1
END IF
IF r_n01.n01_estado <> 'A' THEN
        CALL fl_mostrar_mensaje('Compañía no está activa.', 'stop')
	RETURN 1
END IF
INITIALIZE r_n63.* TO NULL
DECLARE q_ult_n63 CURSOR FOR
	SELECT * FROM rolt063
		WHERE n63_compania = vg_codcia
		  AND n63_estado  <> 'E'
		ORDER BY n63_fecha_ini DESC
OPEN q_ult_n63
FETCH q_ult_n63 INTO r_n63.*
LET rm_n63.n63_cod_liqrol = r_n63.n63_cod_liqrol
LET rm_n63.n63_fecha_ini  = r_n63.n63_fecha_ini
LET rm_n63.n63_fecha_fin  = r_n63.n63_fecha_fin
RETURN 0

END FUNCTION



FUNCTION mostrar_datos_liq()
DEFINE r_n03		RECORD LIKE rolt003.*

DISPLAY BY NAME rm_n63.n63_cod_liqrol, rm_n63.n63_fecha_ini,rm_n63.n63_fecha_fin
CALL fl_lee_proceso_roles(rm_n63.n63_cod_liqrol) RETURNING r_n03.*
DISPLAY BY NAME r_n03.n03_nombre

END FUNCTION



FUNCTION lee_parametros()
DEFINE r_n03		RECORD LIKE rolt003.*
DEFINE fecha_ini	LIKE rolt063.n63_fecha_ini
DEFINE fecha_fin	LIKE rolt063.n63_fecha_fin

LET int_flag = 0
INPUT BY NAME rm_n63.n63_cod_liqrol, rm_n63.n63_fecha_ini, rm_n63.n63_fecha_fin,
	vm_agrupado
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		LET int_flag = 1
		RETURN
	ON KEY(F2)
		IF INFIELD(n63_cod_liqrol) THEN
			CALL fl_ayuda_procesos_roles()
				RETURNING r_n03.n03_proceso,
					  r_n03.n03_nombre
			IF r_n03.n03_proceso IS NOT NULL THEN
				LET rm_n63.n63_cod_liqrol = r_n03.n03_proceso
				DISPLAY BY NAME rm_n63.n63_cod_liqrol,
						r_n03.n03_nombre  
			END IF
		END IF
		LET int_flag = 0
	BEFORE FIELD n63_fecha_ini
		LET fecha_ini = rm_n63.n63_fecha_ini
	BEFORE FIELD n63_fecha_fin
		LET fecha_fin = rm_n63.n63_fecha_fin
	AFTER FIELD n63_cod_liqrol
		IF rm_n63.n63_cod_liqrol IS NOT NULL THEN
   			CALL fl_lee_proceso_roles(rm_n63.n63_cod_liqrol)
                        	RETURNING r_n03.*
			IF r_n03.n03_proceso IS NULL THEN
				CALL fgl_winmessage(vg_producto,'No existe el código de liquidación en la Compañía.','exclamation')
				NEXT FIELD n63_cod_liqrol
			END IF
			DISPLAY BY NAME r_n03.n03_nombre
			CALL mostrar_fechas()
		ELSE
			CLEAR n03_nombre
		END IF
	AFTER FIELD n63_fecha_ini
		IF rm_n63.n63_fecha_ini IS NULL THEN
			LET rm_n63.n63_fecha_ini = fecha_ini
			DISPLAY BY NAME rm_n63.n63_fecha_ini
		END IF
		IF rm_n63.n63_fecha_ini > TODAY THEN
			CALL fl_mostrar_mensaje('La fecha inicial debe ser menor o igual a la fecha de hoy.', 'exclamation')
			NEXT FIELD n63_fecha_ini
		END IF
		CALL mostrar_fechas()
	AFTER FIELD n63_fecha_fin
		IF rm_n63.n63_fecha_fin IS NULL THEN
			LET rm_n63.n63_fecha_fin = fecha_fin
			DISPLAY BY NAME rm_n63.n63_fecha_fin
		END IF
		IF rm_n63.n63_fecha_fin > TODAY THEN
			CALL fl_mostrar_mensaje('La fecha final debe ser menor o igual a la fecha de hoy.', 'exclamation')
			NEXT FIELD n63_fecha_fin
		END IF
		CALL mostrar_fechas()
	AFTER INPUT
		IF rm_n63.n63_fecha_ini >= rm_n63.n63_fecha_fin THEN
			CALL fl_mostrar_mensaje('La fecha inicial no debe ser mayor o igual a la fecha final.', 'exclamation')
			NEXT FIELD n63_fecha_ini
		END IF
		CALL mostrar_fechas()
END INPUT

END FUNCTION



FUNCTION control_reporte()
DEFINE comando		VARCHAR(100)
DEFINE resul, i		SMALLINT

CALL fl_control_reportes() RETURNING comando
IF int_flag THEN
	RETURN
END IF
CALL preparar_query() RETURNING resul
IF resul THEN
	DROP TABLE tmp_almacen
	RETURN
END IF
CALL cargar_almacen_trab()
START REPORT reporte_pla_club TO PIPE comando
--START REPORT reporte_pla_club TO FILE "planilla_club.txt"
LET vm_tot_valor = 0
FOR i = 1 TO vm_num_rep
	OUTPUT TO REPORT reporte_pla_club(r_report[i].nom_depto, i)
END FOR
FINISH REPORT reporte_pla_club
DROP TABLE tmp_almacen

END FUNCTION



FUNCTION preparar_query()
DEFINE r_g34		RECORD LIKE gent034.*
DEFINE r_n30		RECORD LIKE rolt030.*
DEFINE r_n61		RECORD LIKE rolt061.*
DEFINE r_n63		RECORD LIKE rolt063.*
DEFINE r_n64		RECORD LIKE rolt064.*
DEFINE r_n65		RECORD LIKE rolt065.*
DEFINE query		CHAR(1200)
DEFINE expr_orden	VARCHAR(100)
DEFINE cont		INTEGER
DEFINE ind		SMALLINT

SELECT UNIQUE n63_cod_almacen, 0 num_cas FROM rolt063
	WHERE n63_compania   =  vg_codcia
	  AND n63_cod_liqrol =  rm_n63.n63_cod_liqrol
	  AND n63_fecha_ini  =  rm_n63.n63_fecha_ini
	  AND n63_fecha_fin  =  rm_n63.n63_fecha_fin
	  AND n63_estado     <> "E"
  	  AND n63_valor      >  0
	INTO TEMP tmp_almacen
SELECT COUNT(*) INTO cont FROM tmp_almacen
IF cont = 0 THEN
	LET int_flag = 0
	CALL fl_mensaje_consulta_sin_registros()
	RETURN 1
END IF
IF cont > vm_max_cas THEN
	LET int_flag = 0
	CALL fl_mensaje_arreglo_incompleto()
	RETURN 1
END IF 
LET expr_orden = ' ORDER BY g34_nombre, n30_nombres'
IF vm_agrupado = 'N' THEN
	LET expr_orden = ' ORDER BY n30_nombres'
END IF
LET query = 'SELECT UNIQUE n63_cod_trab, n63_compania, g34_nombre, n30_nombres',
		' FROM rolt063, rolt030, gent034 ',
		' WHERE n63_compania   =  ', vg_codcia,
		'   AND n63_cod_liqrol = "', rm_n63.n63_cod_liqrol, '"',
		'   AND n63_fecha_ini  = "', rm_n63.n63_fecha_ini, '"',
		'   AND n63_fecha_fin  = "', rm_n63.n63_fecha_fin, '"',
		'   AND n63_estado     <> "E" ',
		'   AND n63_compania   =  n30_compania ',
		'   AND n63_cod_trab   =  n30_cod_trab ',
		'   AND n30_compania   =  g34_compania ',
		'   AND n30_cod_depto  =  g34_cod_depto ',
		expr_orden CLIPPED
PREPARE q_cons FROM query
DECLARE q_det CURSOR FOR q_cons
LET vm_num_rep = 1
FOREACH q_det INTO r_n63.n63_cod_trab, r_n63.n63_compania, r_g34.g34_nombre,
			r_n30.n30_nombres
	LET r_report[vm_num_rep].nom_depto = r_g34.g34_nombre
	LET r_report[vm_num_rep].cod_trab  = r_n63.n63_cod_trab
	LET r_report[vm_num_rep].nom_trab  = r_n30.n30_nombres
	LET r_report[vm_num_rep].aporte    = 0
	CALL fl_lee_cuota_club(r_n63.n63_compania, r_n63.n63_cod_trab)
		RETURNING r_n61.*
	IF r_n61.n61_compania IS NOT NULL THEN
		LET r_report[vm_num_rep].aporte = r_n61.n61_cuota
	END IF
	DECLARE q_n65 CURSOR FOR
		SELECT * FROM rolt065
			WHERE n65_compania   = vg_codcia
			  AND n65_cod_liqrol = rm_n63.n63_cod_liqrol
			  AND n65_fecha_ini  = rm_n63.n63_fecha_ini
			  AND n65_fecha_fin  = rm_n63.n63_fecha_fin
	LET r_report[vm_num_rep].prestamo = 0
	FOREACH q_n65 INTO r_n65.*
		CALL fl_lee_prestamo_club(r_n65.n65_compania,
						r_n65.n65_num_prest)
			RETURNING r_n64.*
		IF r_n64.n64_cod_trab <> r_n63.n63_cod_trab THEN
			CONTINUE FOREACH
		END IF
		LET r_report[vm_num_rep].prestamo = r_n65.n65_valor
		EXIT FOREACH
	END FOREACH
	DECLARE q_det2 CURSOR FOR
		SELECT * FROM tmp_almacen ORDER BY n63_cod_almacen
	LET vm_num_cas = 1
	FOREACH q_det2 INTO r_n63.n63_cod_almacen, ind
		LET r_report[vm_num_rep].casa_com[vm_num_cas].cod_alm =
							r_n63.n63_cod_almacen
		LET r_report[vm_num_rep].casa_com[vm_num_cas].valor   = 0
		LET vm_num_cas = vm_num_cas + 1
	END FOREACH
	LET vm_num_cas = vm_num_cas - 1
	LET vm_num_rep = vm_num_rep + 1
	IF vm_num_rep > vm_max_rep THEN
		CALL fl_mensaje_arreglo_incompleto()
		EXIT PROGRAM
	END IF 
END FOREACH
LET vm_num_rep = vm_num_rep - 1
IF vm_num_rep = 0 THEN
	LET int_flag = 0
	CALL fl_mensaje_consulta_sin_registros()
	RETURN 1
END IF
DECLARE q_up_t CURSOR FOR
	SELECT n63_cod_almacen FROM tmp_almacen ORDER BY n63_cod_almacen
LET ind = 1
FOREACH q_up_t INTO r_n63.n63_cod_almacen
	UPDATE tmp_almacen SET num_cas = ind
		WHERE n63_cod_almacen =	r_n63.n63_cod_almacen
	LET ind = ind + 1
END FOREACH
RETURN 0

END FUNCTION
 


FUNCTION cargar_almacen_trab()
DEFINE r_n63		RECORD LIKE rolt063.*
DEFINE pos_cas, i	SMALLINT

FOR i = 1 TO vm_num_rep
	DECLARE q_n63 CURSOR FOR
		SELECT * FROM rolt063
			WHERE n63_compania   =  vg_codcia
			  AND n63_cod_liqrol =  rm_n63.n63_cod_liqrol
			  AND n63_fecha_ini  =  rm_n63.n63_fecha_ini
			  AND n63_fecha_fin  =  rm_n63.n63_fecha_fin
			  AND n63_cod_trab   =  r_report[i].cod_trab
			  AND n63_estado     <> "E"
		  	  AND n63_valor      >  0
			ORDER BY n63_cod_almacen
	FOREACH q_n63 INTO r_n63.*
		SELECT num_cas INTO pos_cas FROM tmp_almacen
			WHERE n63_cod_almacen = r_n63.n63_cod_almacen
		LET r_report[i].casa_com[pos_cas].valor = r_n63.n63_valor
	END FOREACH
END FOR

END FUNCTION
 


REPORT reporte_pla_club(nom_depto, num_rep)
DEFINE nom_depto	LIKE gent034.g34_nombre
DEFINE num_rep		SMALLINT
DEFINE r_n03		RECORD LIKE rolt003.*
DEFINE cod_alm		LIKE rolt063.n63_cod_almacen
DEFINE nom_alm		LIKE rolt062.n62_abreviado
DEFINE nom_dep		VARCHAR(36)
DEFINE sub_aporte	DECIMAL(14,2)
DEFINE sub_prestamo	DECIMAL(14,2)
DEFINE sub_tot_valor	DECIMAL(14,2)
DEFINE tot_valor	DECIMAL(14,2)
DEFINE tot_cas		DECIMAL(14,2)
DEFINE valor		VARCHAR(10)
DEFINE titulo		VARCHAR(80)
DEFINE modulo		VARCHAR(20)
DEFINE usuario		VARCHAR(19)
DEFINE cuantos, i, j	SMALLINT
DEFINE postit, numcol	SMALLINT
DEFINE inicol, col	SMALLINT
DEFINE maxcol, i_col	SMALLINT
DEFINE escape, act_des	SMALLINT
DEFINE act_comp, db_c	SMALLINT
DEFINE desact_comp, db	SMALLINT
DEFINE act_neg, des_neg	SMALLINT
DEFINE act_10cpi	SMALLINT
DEFINE act_12cpi	SMALLINT

OUTPUT
	TOP MARGIN	1
	LEFT MARGIN	0
	RIGHT MARGIN	267
	BOTTOM MARGIN	4
	PAGE LENGTH	66

FORMAT

PAGE HEADER
	LET escape	= 27		# Iniciar sec. impresión
	LET act_comp	= 15		# Activar Comprimido.
	LET desact_comp	= 18		# Cancelar Comprimido.
	LET act_neg	= 71		# Activar negrita.
	LET des_neg	= 72		# Desactivar negrita.
	LET act_des	= 0
	LET act_10cpi	= 80		# Comprimido 10 CPI.
	LET act_12cpi	= 77		# Comprimido 12 CPI.
	LET inicol      = 46
	LET numcol      = vm_num_cas
	LET i_col       = 11
	IF numcol > 16 THEN
		LET i_col = 10
	END IF
	LET maxcol = inicol
	FOR i = 1 TO numcol + 1
		LET maxcol = maxcol + i_col
	END FOR
	LET cuantos = i_col - 1
	LET titulo  = "** PLANILLA DEL CLUB **"
	LET postit  = (maxcol / 2) - LENGTH(titulo) / 2
	LET modulo  = "MODULO: NOMINA"
	LET usuario = 'USUARIO: ', vg_usuario
	CALL fl_justifica_titulo('D', usuario, 19) RETURNING usuario
	IF numcol > 13 THEN
		print ASCII escape;
		print ASCII act_comp;
		print ASCII escape;
		print ASCII act_12cpi;
	END IF
	IF numcol >= 8 AND numcol <= 13 THEN
		print ASCII escape;
		print ASCII act_comp;
	END IF
	IF numcol >= 6 AND numcol < 8 THEN
		print ASCII escape;
		print ASCII act_12cpi;
	END IF
	print ASCII escape;
	print ASCII act_neg
	PRINT COLUMN 001, rm_g01.g01_razonsocial,
  	      COLUMN maxcol - 12, "PAGINA: ", PAGENO USING "&&&"
	SKIP 1 LINES
	PRINT COLUMN 001, modulo CLIPPED,
	      COLUMN postit, titulo,
	      COLUMN maxcol - 8, UPSHIFT(vg_proceso)
	CALL fl_lee_proceso_roles(rm_n63.n63_cod_liqrol) RETURNING r_n03.*
	LET titulo = "LIQUIDACION: ", rm_n63.n63_cod_liqrol, " ",
			r_n03.n03_nombre_abr CLIPPED, " del ",
			rm_n63.n63_fecha_ini USING "dd-mm-yyyy",
			' al ', rm_n63.n63_fecha_fin USING "dd-mm-yyyy"
	LET postit = (maxcol / 2) - LENGTH(titulo) / 2
	PRINT COLUMN postit, titulo
	SKIP 1 LINES
	PRINT COLUMN 001, "FECHA IMPRESION: ", TODAY USING "dd-mm-yyyy",
		1 SPACES, TIME,
	      COLUMN maxcol - 20, usuario
	LET col = inicol
	PRINT COLUMN 001, "--------------------------------------------";
	WHILE col < maxcol
		IF numcol > 16 THEN
			PRINT COLUMN 001, "----------";
		ELSE
			PRINT COLUMN 001, "-----------";
		END IF
		LET col = col + i_col
	END WHILE
	PRINT 1 SPACES
	PRINT COLUMN 001, "COD",
	      COLUMN 005, "E M P L E A D O",
	      COLUMN 026, "   APORTE",
	      COLUMN 036, " PRESTAMO";
	DECLARE q_tit CURSOR FOR
		SELECT n63_cod_almacen, n62_abreviado FROM tmp_almacen, rolt062
			WHERE n62_compania    = vg_codcia
			  AND n62_cod_almacen = n63_cod_almacen
			ORDER BY n63_cod_almacen
	LET col = inicol
	FOREACH q_tit INTO cod_alm, nom_alm
		PRINT COLUMN col, fl_justifica_titulo('D', nom_alm[1,cuantos],
							cuantos);
		LET col = col + i_col
	END FOREACH
	PRINT COLUMN col, " TOT. ALM."
	LET col = inicol
	PRINT COLUMN 001, "--------------------------------------------";
	WHILE col < maxcol
		IF numcol > 16 THEN
			PRINT COLUMN 001, "----------";
		ELSE
			PRINT COLUMN 001, "-----------";
		END IF
		LET col = col + i_col
	END WHILE
	print ASCII escape;
	print ASCII des_neg
	LET vm_cabecera = 1

BEFORE GROUP OF nom_depto
	IF vm_agrupado = 'S' THEN
		IF NOT vm_cabecera OR PAGENO > 1 THEN
			SKIP 1 LINES
		END IF
		NEED 7 LINES
		LET nom_dep = '** ', nom_depto CLIPPED, ' **'
		print ASCII escape;
		print ASCII act_neg;
		PRINT COLUMN 002, nom_dep;
		print ASCII escape;
		print ASCII des_neg
		LET sub_aporte    = 0
		LET sub_prestamo  = 0
		LET sub_tot_valor = 0
		LET vm_cabecera   = 0
	END IF

ON EVERY ROW
	IF vm_agrupado = 'S' THEN
		NEED 6 LINES
	ELSE
		NEED 3 LINES
	END IF
	PRINT COLUMN 001, r_report[num_rep].cod_trab	USING "&&&",
	      COLUMN 005, r_report[num_rep].nom_trab[1,20],
	      COLUMN 026, r_report[num_rep].aporte	USING "##,##&.##",
	      COLUMN 036, r_report[num_rep].prestamo	USING "##,##&.##";
	LET col       = inicol
	LET tot_valor = 0
	FOR i = 1 TO vm_num_cas
		LET valor     = r_report[num_rep].casa_com[i].valor
							USING "##,##&.##"
		PRINT COLUMN col, fl_justifica_titulo('D', valor, cuantos);
		LET tot_valor = tot_valor + r_report[num_rep].casa_com[i].valor
		LET col = col + i_col
	END FOR
	LET valor = tot_valor USING "##,##&.##"
	PRINT COLUMN col, fl_justifica_titulo('D', valor, cuantos)
	LET vm_tot_valor = vm_tot_valor + tot_valor
	IF vm_agrupado = 'S' THEN
		LET sub_aporte    = sub_aporte    + r_report[num_rep].aporte
		LET sub_prestamo  = sub_prestamo  + r_report[num_rep].prestamo
		LET sub_tot_valor = sub_tot_valor + tot_valor
	END IF

AFTER GROUP OF nom_depto
	IF vm_agrupado = 'S' THEN
		NEED 5 LINES
		print ASCII escape;
		print ASCII act_neg;
		PRINT COLUMN 026, 2 SPACES, "---------";
		PRINT COLUMN 036, 1 SPACES, "---------";
		LET col = inicol + 1
		WHILE col < maxcol
			PRINT COLUMN col, 2 SPACES, "---------";
			LET col = col + i_col
		END WHILE
		PRINT 1 SPACES
		PRINT COLUMN 014, "SUBTOT. ==> ",
		      COLUMN 026, sub_aporte		USING "##,##&.##",
		      COLUMN 036, sub_prestamo		USING "##,##&.##";
		LET col = inicol + 1
		FOR i = 1 TO vm_num_cas
			LET tot_cas = 0
			FOR j = 1 TO vm_num_rep
				IF nom_depto = r_report[j].nom_depto THEN
					LET tot_cas = tot_cas +
						r_report[j].casa_com[i].valor
				END IF
			END FOR
			PRINT COLUMN col, tot_cas	USING "##,##&.##";
			LET col = col + i_col
		END FOR
		PRINT COLUMN col, sub_tot_valor		USING "##,##&.##";
		print ASCII escape;
		print ASCII des_neg
	END IF

ON LAST ROW
	IF vm_agrupado = 'S' THEN
		NEED 3 LINES
		SKIP 1 LINES
	ELSE
		NEED 2 LINES
	END IF
	print ASCII escape;
	print ASCII act_neg;
	PRINT COLUMN 026, 2 SPACES, "---------",
	      COLUMN 036, 1 SPACES, "---------";
	LET col = inicol + 1
	WHILE col < maxcol
		PRINT COLUMN col, 2 SPACES, "---------";
		LET col = col + i_col
	END WHILE
	PRINT 1 SPACES
	PRINT COLUMN 014, "TOTALES ==> ",
	      COLUMN 026, SUM(r_report[num_rep].aporte)	  USING "##,##&.##",
	      COLUMN 036, SUM(r_report[num_rep].prestamo) USING "##,##&.##";
	LET col = inicol + 1
	FOR i = 1 TO vm_num_cas
		LET tot_cas = 0
		FOR j = 1 TO vm_num_rep
			LET tot_cas = tot_cas + r_report[j].casa_com[i].valor
		END FOR
		PRINT COLUMN col, tot_cas	USING "##,##&.##";
		LET col = col + i_col
	END FOR
	PRINT COLUMN col, vm_tot_valor		USING "##,##&.##";
	IF numcol < 6 THEN
		print ASCII escape;
		print ASCII des_neg
	ELSE
		print ASCII escape;
		print ASCII des_neg;
	END IF
	IF numcol > 13 THEN
		print ASCII escape;
		print ASCII desact_comp;
		print ASCII escape;
		print ASCII act_10cpi
	END IF
	IF numcol >= 8 AND numcol <= 13 THEN
		print ASCII escape;
		print ASCII desact_comp
	END IF
	IF numcol >= 6 AND numcol < 8 THEN
		print ASCII escape;
		print ASCII act_10cpi;
	END IF

END REPORT



FUNCTION mostrar_fechas()

CALL fl_retorna_rango_fechas_proceso(vg_codcia, rm_n63.n63_cod_liqrol,
			YEAR(rm_n63.n63_fecha_ini), MONTH(rm_n63.n63_fecha_ini))
	RETURNING rm_n63.n63_fecha_ini, rm_n63.n63_fecha_fin
DISPLAY BY NAME rm_n63.n63_fecha_ini, rm_n63.n63_fecha_fin

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
