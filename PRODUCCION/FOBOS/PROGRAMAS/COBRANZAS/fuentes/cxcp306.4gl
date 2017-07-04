------------------------------------------------------------------------------
-- Titulo           : cxcp306.4gl - Consulta Análisis Cartera Clientes
-- Elaboracion      : 11-Oct-2001
-- Autor            : YEC
-- Formato Ejecucion: fglrun cxcp306.4gl base_datos modulo compañía localidad
-- Ultima Correccion: 
-- Motivo Correccion:
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_demonios	VARCHAR(12)
DEFINE rm_orden 	ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1	SMALLINT
DEFINE vm_columna_2	SMALLINT
DEFINE rm_mon		RECORD LIKE gent013.*
DEFINE vm_divisor	SMALLINT
DEFINE num_doc		SMALLINT
DEFINE num_cli		SMALLINT
DEFINE num_max_doc	SMALLINT
DEFINE num_max_cli	SMALLINT
DEFINE rm_par 		RECORD
				area_n          LIKE gent003.g03_areaneg,
				tit_area        LIKE gent003.g03_nombre,
				moneda          LIKE gent013.g13_moneda,
				tit_mon         LIKE gent013.g13_nombre,
				tipcli		LIKE gent012.g12_subtipo,
				localidad	LIKE gent002.g02_localidad,
				tit_tipcli	LIKE gent012.g12_nombre,
				ind_venc        CHAR(1),
				dias_i          SMALLINT,
				dias_f          SMALLINT
			END RECORD
DEFINE r_doc		ARRAY[1500] OF RECORD
				area_n          LIKE gent003.g03_areaneg,
				cladoc		LIKE cxct020.z20_tipo_doc,
				numdoc		LIKE cxct020.z20_num_doc,
				secuencia	LIKE cxct020.z20_dividendo,
				codcli		LIKE cxct020.z20_codcli,
				nomcli		LIKE cxct001.z01_nomcli,
				fecha		DATE,
				valor		DECIMAL(12,2)
			END RECORD
DEFINE rm_codcli	ARRAY[1500] OF INTEGER
DEFINE rm_cli		ARRAY[1500] OF RECORD
				nomcli		LIKE cxct001.z01_nomcli,
				por_vencer	DECIMAL(12,2),
				vencido		DECIMAL(12,2),
				tot_saldo 	DECIMAL(12,2)
			END RECORD
DEFINE tot_1, tot_2	DECIMAL(14,2)
DEFINE tot_3		DECIMAL(14,2)



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/errores')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 THEN          -- Validar # parámetros correcto
	CALL fgl_winmessage(vg_producto, 'Número de parámetros incorrecto', 'stop')
	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_codloc  = arg_val(4)
LET vg_proceso = 'cxcp306'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
--#CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()

END MAIN



FUNCTION funcion_master()
DEFINE r		RECORD LIKE gent000.*
DEFINE i		SMALLINT

LET num_max_doc = 1500
LET num_max_cli = 1500
INITIALIZE rm_par.* TO NULL
CALL fl_lee_configuracion_facturacion() RETURNING r.*
LET rm_par.moneda = r.g00_moneda_base
CALL fl_lee_moneda(rm_par.moneda) RETURNING rm_mon.*
LET rm_par.tit_mon = rm_mon.g13_nombre
LET rm_par.ind_venc  = 'T'
OPEN WINDOW w_imp AT 3,2 WITH 22 ROWS, 80 COLUMNS
	ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE FIRST,
		  BORDER, MESSAGE LINE LAST) 
OPEN FORM f_par FROM "../forms/cxcf306_1"
DISPLAY FORM f_par
CALL mostrar_botones()
WHILE TRUE
	FOR i = 1 TO 10
		LET rm_orden[i] = '' 
	END FOR
	LET rm_orden[4] = 'DESC'
	LET vm_columna_1 = 4
	LET vm_columna_2 = 1
	CALL lee_parametros() 
	IF int_flag THEN
		RETURN
	END IF
	CREATE TEMP TABLE tempo_doc 
		(area_n		SMALLINT,
		 cladoc		CHAR(2),
		 numdoc		CHAR(10),
		 secuencia	SMALLINT,
		 codcli		INTEGER,
		 nomcli		CHAR(40),
		 fecha		DATE,
		 por_vencer	DECIMAL(12,2),
		 vencido	DECIMAL(12,2))
	CALL genera_tabla_temporal()
	IF num_doc > 0 THEN
		CALL muestra_resumen_clientes()
	END IF
	DROP TABLE tempo_doc
END WHILE

END FUNCTION



FUNCTION lee_parametros()
DEFINE mon_aux		LIKE gent013.g13_moneda
DEFINE tit_mon		LIKE gent013.g13_nombre
DEFINE area_aux		LIKE gent003.g03_areaneg
DEFINE tit_area		LIKE gent003.g03_nombre
DEFINE r_an		RECORD LIKE gent003.*
DEFINE r_mo		RECORD LIKE gent013.*
DEFINE num		SMALLINT
DEFINE tiporeg		LIKE gent012.g12_tiporeg
DEFINE subtipo		LIKE gent012.g12_subtipo
DEFINE nomtipo		LIKE gent012.g12_nombre
DEFINE nombre		LIKE gent011.g11_nombre
DEFINE r_g02		RECORD LIKE gent002.*
DEFINE r_se		RECORD LIKE gent012.*

LET int_flag = 0
INPUT BY NAME rm_par.* WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		CLOSE FORM f_par
		RETURN
	ON KEY(F2)
		IF INFIELD(area_n) THEN
			CALL fl_ayuda_areaneg(vg_codcia) 
				RETURNING area_aux, tit_area
			IF area_aux IS NOT NULL THEN
				LET rm_par.area_n   = area_aux
				LET rm_par.tit_area = tit_area
 				DISPLAY BY NAME rm_par.area_n, rm_par.tit_area
			END IF
		END IF
		IF INFIELD(moneda) THEN
			CALL fl_ayuda_monedas() RETURNING mon_aux, tit_mon, num
			IF mon_aux IS NOT NULL THEN
				LET rm_par.moneda  = mon_aux
				LET rm_par.tit_mon = tit_mon
				DISPLAY BY NAME rm_par.moneda, rm_par.tit_mon
			END IF
		END IF
		IF INFIELD(tipcli) THEN
			CALL fl_ayuda_subtipo_entidad('CL') 
				RETURNING tiporeg, subtipo, nomtipo, nombre
			IF nomtipo IS NOT NULL THEN
				LET rm_par.tipcli     = subtipo
				LET rm_par.tit_tipcli = nomtipo
				DISPLAY BY NAME rm_par.tipcli, rm_par.tit_tipcli
			END IF
		END IF
		IF INFIELD(localidad) THEN
			CALL fl_ayuda_localidad(vg_codcia)
				RETURNING r_g02.g02_localidad,
					  r_g02.g02_nombre
			IF r_g02.g02_localidad IS NOT NULL THEN
				LET rm_par.localidad = r_g02.g02_localidad
				DISPLAY BY NAME rm_par.localidad
				DISPLAY r_g02.g02_nombre TO tit_localidad
			END IF
		END IF
		LET int_flag = 0
	AFTER FIELD area_n
		IF rm_par.area_n IS NOT NULL THEN
			CALL fl_lee_area_negocio(vg_codcia, rm_par.area_n)
				RETURNING r_an.*
			IF r_an.g03_compania IS NULL THEN
				CALL fgl_winmessage(vg_producto, 'No existe área de negocio', 'exclamation')
				NEXT FIELD area_n
			END IF
			LET rm_par.tit_area = r_an.g03_nombre
			DISPLAY BY NAME rm_par.tit_area
		ELSE
			LET rm_par.tit_area = NULL
			DISPLAY BY NAME rm_par.tit_area
		END IF
	AFTER FIELD moneda
		IF rm_par.moneda IS NOT NULL THEN
			CALL fl_lee_moneda(rm_par.moneda)
				RETURNING r_mo.*
			IF r_mo.g13_moneda IS NULL THEN
				CALL fgl_winmessage(vg_producto, 'No existe moneda', 'exclamation')
				NEXT FIELD moneda
			END IF
			LET rm_par.tit_mon = r_mo.g13_nombre 
			DISPLAY BY NAME rm_par.tit_mon
		ELSE
			LET rm_par.tit_mon = NULL
			DISPLAY BY NAME rm_par.tit_mon
		END IF
	AFTER FIELD tipcli
		IF rm_par.tipcli IS NOT NULL THEN
			CALL fl_lee_subtipo_entidad('CL', rm_par.tipcli)
				RETURNING r_se.*
			IF r_se.g12_tiporeg IS NULL THEN
				CALL fgl_winmessage(vg_producto, 'No existe tipo cliente', 'exclamation')
				NEXT FIELD tipcli
			END IF
			LET rm_par.tit_tipcli = r_se.g12_nombre 
			DISPLAY BY NAME rm_par.tit_tipcli
		ELSE
			LET rm_par.tit_tipcli = NULL
			DISPLAY BY NAME rm_par.tit_tipcli
		END IF
	AFTER FIELD localidad
		IF rm_par.localidad IS NOT NULL THEN
			CALL fl_lee_localidad(vg_codcia, rm_par.localidad)
				RETURNING r_g02.*
			IF r_g02.g02_compania IS NULL THEN
				CALL fl_mostrar_mensaje('Localidad no existe.','exclamation')
				NEXT FIELD localidad
			END IF
			IF r_g02.g02_estado = 'B' THEN
				CALL fl_mensaje_estado_bloqueado()
				NEXT FIELD localidad
			END IF
			DISPLAY r_g02.g02_nombre TO tit_localidad
		ELSE
			CLEAR tit_localidad
		END IF
	AFTER INPUT 
		IF (rm_par.dias_i IS NOT NULL AND rm_par.dias_f IS NULL) OR
		   (rm_par.dias_i IS NULL AND rm_par.dias_f IS NOT NULL) THEN
			CALL fgl_winmessage(vg_producto, 'Complete rango', 'exclamation')
			NEXT FIELD dias_i
		END IF
		IF rm_par.dias_i > rm_par.dias_f THEN
			CALL fgl_winmessage(vg_producto, 'Rango incorrecto', 'exclamation')
			NEXT FIELD dias_i
		END IF
END INPUT

END FUNCTION



FUNCTION genera_tabla_temporal()
DEFINE pven, venc	DECIMAL(12,2)
DEFINE expr1, expr2	CHAR(60)
DEFINE query		CHAR(200)
DEFINE dias		SMALLINT
DEFINE nomcli		CHAR(40)
DEFINE r_doc		RECORD LIKE cxct020.*
DEFINE r_cli		RECORD LIKE cxct001.*
DEFINE expr_loc		VARCHAR(50)

ERROR "Generando consulta . . . espere por favor." ATTRIBUTE(NORMAL)
LET expr1 = ' 1 = 1 '
LET expr2 = ' 1 = 1 '
IF rm_par.area_n IS NOT NULL THEN
	LET expr1 = ' z20_areaneg = ', rm_par.area_n
END IF
IF rm_par.moneda IS NOT NULL THEN
	LET expr2 = " z20_moneda = '", rm_par.moneda, "' "
END IF
LET expr_loc = ' '
IF rm_par.localidad IS NOT NULL THEN
	LET expr_loc = '  AND z20_localidad = ', rm_par.localidad
END IF
LET query = "SELECT * FROM cxct020 WHERE ", 
		expr1 CLIPPED, " AND ",
		expr2 CLIPPED, " AND ",
		"z20_compania = ", vg_codcia,
		expr_loc CLIPPED,
		" AND z20_saldo_cap + z20_saldo_int > 0"
PREPARE doc FROM query
DECLARE q_doc CURSOR FOR doc
LET num_doc = 0
FOREACH q_doc INTO r_doc.*
	IF r_doc.z20_fecha_vcto >= TODAY THEN
		LET pven = r_doc.z20_saldo_cap + r_doc.z20_saldo_int
		LET venc = 0
	ELSE
		LET venc = r_doc.z20_saldo_cap + r_doc.z20_saldo_int
		LET pven = 0
	END IF
	IF rm_par.ind_venc = 'V' THEN
		IF r_doc.z20_fecha_vcto >= TODAY THEN
			CONTINUE FOREACH
		END IF
		IF rm_par.dias_i IS NULL THEN
			LET rm_par.dias_i = 1
			LET rm_par.dias_f = 9999
		END IF
		LET dias = TODAY - r_doc.z20_fecha_vcto
		IF dias < rm_par.dias_i OR dias > rm_par.dias_f THEN
			CONTINUE FOREACH
		END IF
	END IF		
	IF rm_par.ind_venc = 'P' THEN
		IF r_doc.z20_fecha_vcto < TODAY THEN
			CONTINUE FOREACH
		END IF
		IF rm_par.dias_i IS NULL THEN
			LET rm_par.dias_i = 0
			LET rm_par.dias_f = 9999
		END IF
		LET dias = r_doc.z20_fecha_vcto - TODAY
		IF dias < rm_par.dias_i OR dias > rm_par.dias_f THEN
			CONTINUE FOREACH
		END IF
	END IF		
	CALL fl_lee_cliente_general(r_doc.z20_codcli)
		RETURNING r_cli.*
	IF rm_par.tipcli IS NOT NULL AND rm_par.tipcli <> r_cli.z01_tipo_clte THEN
		CONTINUE FOREACH
	END IF
	INSERT INTO tempo_doc VALUES(r_doc.z20_areaneg, r_doc.z20_tipo_doc,
		r_doc.z20_num_doc, r_doc.z20_dividendo, r_doc.z20_codcli, 
		r_cli.z01_nomcli, r_doc.z20_fecha_vcto, pven, venc)
	LET num_doc = num_doc + 1
	IF num_doc > num_max_doc THEN
		EXIT FOREACH
	END IF
END FOREACH
ERROR ' '
IF num_doc = 0 THEN
	CALL fl_mensaje_consulta_sin_registros()
END IF

END FUNCTION



FUNCTION muestra_resumen_clientes()
DEFINE orden		CHAR(40)
DEFINE query		CHAR(300)
DEFINE i		SMALLINT
DEFINE comando          CHAR(100)
DEFINE codloc		LIKE gent002.g02_localidad

CALL mostrar_botones()
WHILE TRUE
	LET query = "SELECT nomcli, SUM(por_vencer), SUM(vencido), ",
			" SUM(por_vencer + vencido), codcli FROM tempo_doc ",
			" GROUP BY 1, 5 ",
			" ORDER BY ", vm_columna_1, ' ', rm_orden[vm_columna_1],
			        ', ', vm_columna_2, ' ', rm_orden[vm_columna_2]
	PREPARE cons FROM query
	DECLARE q_cons CURSOR FOR cons
	LET i = 1
	LET tot_1 = 0
	LET tot_2 = 0
	LET tot_3 = 0
	FOREACH q_cons INTO rm_cli[i].*, rm_codcli[i]
		LET tot_1 = tot_1 + rm_cli[i].por_vencer
		LET tot_2 = tot_2 + rm_cli[i].vencido
		LET tot_3 = tot_3 + rm_cli[i].tot_saldo
		LET i = i + 1
		IF i > num_max_cli THEN
			EXIT FOREACH
		END IF
	END FOREACH
	LET num_cli = i - 1
	CALL set_count(num_cli)
	DISPLAY BY NAME tot_1, tot_2, tot_3
	LET int_flag = 0
	DISPLAY ARRAY rm_cli TO rm_cli.*
		BEFORE DISPLAY 
			--#CALL dialog.keysetlabel("ACCEPT","")
		AFTER DISPLAY 
			CONTINUE DISPLAY
		BEFORE ROW
			LET i = arr_curr()
			MESSAGE i, ' de ', num_cli
		ON KEY(F5)
			LET i = arr_curr()
			LET codloc = 0
			IF rm_par.localidad IS NOT NULL THEN
				LET codloc = rm_par.localidad
			END IF
			LET comando = 'fglrun cxcp305 ' || vg_base || 
			      ' CO ' || 
			      vg_codcia || ' ' || 
			      codloc || ' ' ||
			      rm_codcli[i] || ' ' ||
		       	      rm_par.moneda
			RUN comando
		ON KEY(INTERRUPT)
			EXIT DISPLAY
		ON KEY(F15)
			LET i = 1
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F16)
			LET i = 2
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F17)
			LET i = 3
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F18)
			LET i = 4
			LET int_flag = 2
			EXIT DISPLAY
	END DISPLAY
	IF int_flag = 1 THEN
		EXIT WHILE
	END IF
	IF i <> vm_columna_1 THEN
		LET vm_columna_2           = vm_columna_1 
		LET rm_orden[vm_columna_2] = rm_orden[vm_columna_1]
		LET vm_columna_1 = i 
	END IF
	IF rm_orden[vm_columna_1] = 'ASC' THEN
		LET rm_orden[vm_columna_1] = 'DESC'
	ELSE
		LET rm_orden[vm_columna_1] = 'ASC'
	END IF
END WHILE
	
END FUNCTION



FUNCTION mostrar_botones()

DISPLAY 'C l i e n t e' TO tit_col1
DISPLAY 'Por Vencer'    TO tit_col2
DISPLAY 'Vencido'       TO tit_col3
DISPLAY 'T o t a l'     TO tit_col4

END FUNCTION
