--------------------------------------------------------------------------------
-- Titulo           : repp243.4gl - Modificacion No. SRI Guia de Remision
-- Elaboracion      : 28-Nov-2007
-- Autor            : NPC
-- Formato Ejecucion: fglrun repp243 base modulo compania localidad
-- Ultima Correccion: 
-- Motivo Correccion: 
--------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_nuevoprog     CHAR(400)
DEFINE vm_tipo_doc	LIKE gent037.g37_tipo_doc
DEFINE rm_det		ARRAY[10000] OF RECORD
			       r95_guia_remision LIKE rept095.r95_guia_remision,
				r95_persona_guia LIKE rept095.r95_persona_guia,
				r95_fecing	DATE,
				r95_num_sri	LIKE rept095.r95_num_sri,
				r95_estado	LIKE rept095.r95_estado
			END RECORD
DEFINE rm_adi		ARRAY[10000] OF RECORD
				r95_persona_dest LIKE rept095.r95_persona_dest,
				r97_cod_tran	LIKE rept097.r97_cod_tran,
				r97_num_tran	LIKE rept097.r97_num_tran,
				r96_num_entrega	LIKE rept096.r96_num_entrega
			END RECORD
DEFINE vm_max_det       SMALLINT
DEFINE vm_num_det       SMALLINT
DEFINE vm_fecha_ini	DATE
DEFINE vm_fecha_fin	DATE
DEFINE rm_orden 	ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1	SMALLINT
DEFINE vm_columna_2	SMALLINT
DEFINE vm_size_arr	INTEGER



MAIN

DEFER QUIT 
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/repp243.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 THEN   -- Validar # parametros correcto
	CALL fl_mostrar_mensaje('Número de parametros incorrecto.','stop')
	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_codloc  = arg_val(4)
LET vg_proceso = 'repp243'
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
DEFINE secuencia	LIKE gent037.g37_secuencia

CALL fl_nivel_isolation()
CREATE TEMP TABLE tmp_sri(
		r95_guia_remision	INTEGER,
		r95_persona_guia	VARCHAR(100,70),
		r95_fecing		DATE,
		r95_num_sri		CHAR(16),
		r95_estado		CHAR(1),
		r95_persona_dest	VARCHAR(100,40),
		r97_cod_tran		CHAR(2),
		r97_num_tran		DECIMAL(15,0),
		r96_num_entrega		INTEGER
	)
LET vm_tipo_doc = 'GR'
LET vm_max_det  = 10000
LET lin_menu    = 0
LET row_ini     = 3
LET num_rows    = 22
LET num_cols    = 80
IF vg_gui = 0 THEN
	LET lin_menu = 1
	LET row_ini  = 4
	LET num_rows = 20
	LET num_cols = 78
END IF
OPEN WINDOW w_repp243 AT row_ini, 02 WITH num_rows ROWS, num_cols COLUMNS
    ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE lin_menu,BORDER,
	      MESSAGE LINE LAST - 1)
IF vg_gui = 1 THEN
        OPEN FORM f_repf243_1 FROM '../forms/repf243_1'
ELSE
        OPEN FORM f_repf243_1 FROM '../forms/repf243_1c'
END IF
DISPLAY FORM f_repf243_1
CALL muestra_contadores_det(0, 0)
CALL borrar_cabecera()
CALL borrar_detalle()
CALL mostrar_cabecera_forma()
CALL control_consulta()

END FUNCTION



FUNCTION control_consulta()
DEFINE i,j,col		SMALLINT
DEFINE query		CHAR(3000)
DEFINE expr_sql         CHAR(400)

LET vm_fecha_ini = TODAY
LET vm_fecha_fin = TODAY
WHILE TRUE
	DELETE FROM tmp_sri 
	LET vm_num_det = 0
	CALL borrar_detalle()
	CALL muestra_contadores_det(0, vm_num_det)
	CALL lee_parametros() RETURNING expr_sql
	IF int_flag = 2 THEN
		CONTINUE WHILE
	END IF
	IF int_flag THEN
		EXIT WHILE
	END IF
	FOR i = 1 TO 10
		LET rm_orden[i] = '' 
	END FOR
	LET vm_columna_1  = 4
	LET vm_columna_2  = 2
	LET col           = 4
	LET rm_orden[col] = 'DESC'
	LET query = 'INSERT INTO tmp_sri ',
			' SELECT UNIQUE r95_guia_remision, r95_persona_guia, ',
				'DATE(r95_fecing) fecha_pro, r95_num_sri, ',
				'r95_estado, r95_persona_dest, r97_cod_tran, ',
				'r97_num_tran, r96_num_entrega ',
			' FROM rept095, rept097, OUTER rept096 ',
			' WHERE r95_compania      = ', vg_codcia,
			'   AND r95_localidad     = ', vg_codloc,
			--'   AND r95_estado        = "A"',
			'   AND DATE(r95_fecing)  BETWEEN "', vm_fecha_ini,
						  '" AND "', vm_fecha_fin,'"',
			'   AND ', expr_sql CLIPPED,
			'   AND r97_compania      = r95_compania ',
			'   AND r97_localidad     = r95_localidad ',
			'   AND r97_guia_remision = r95_guia_remision ',
			'   AND r96_compania      = r95_compania ',
			'   AND r96_localidad     = r95_localidad ',
			'   AND r96_guia_remision = r95_guia_remision '
	PREPARE cons_temp FROM query
	EXECUTE cons_temp
	WHILE TRUE
		LET query = 'SELECT * FROM tmp_sri ',
			" ORDER BY ", vm_columna_1, ' ', rm_orden[vm_columna_1],
		    	   	', ', vm_columna_2, ' ', rm_orden[vm_columna_2]
		PREPARE deto FROM query
		DECLARE q_deto CURSOR FOR deto
		LET vm_num_det = 1
		FOREACH q_deto INTO rm_det[vm_num_det].*, rm_adi[vm_num_det].*
			LET vm_num_det = vm_num_det + 1
			IF vm_num_det > vm_max_det THEN
				CALL fl_mensaje_arreglo_incompleto()
				EXIT PROGRAM
			END IF
		END FOREACH
		LET vm_num_det = vm_num_det - 1
		IF vm_num_det = 0 THEN
			CALL fl_mensaje_consulta_sin_registros()
			EXIT WHILE
		END IF
		CALL set_count(vm_num_det)
		LET int_flag = 0
		DISPLAY ARRAY rm_det TO rm_det.*
			ON KEY(INTERRUPT)
				LET int_flag = 1
				EXIT DISPLAY
        		ON KEY(F1,CONTROL-W)
				CALL control_visor_teclas_caracter_1() 
			ON KEY(RETURN)
				LET i = arr_curr()
				LET j = scr_line()
				CALL muestra_contadores_det(i, vm_num_det)
				DISPLAY BY NAME rm_adi[i].*
			ON KEY(F5)
				LET i = arr_curr()
				LET j = scr_line()
				--IF rm_det[i].r95_estado = 'A' THEN
					CALL control_modificar(i, j)
					LET int_flag = 0
				--END IF
			ON KEY(F6)
				LET i = arr_curr()
				LET j = scr_line()
				CALL ver_guia_remision(i)
				LET int_flag = 0
			ON KEY(F15)
				LET col = 1
				EXIT DISPLAY
			ON KEY(F16)
				LET col = 2
				EXIT DISPLAY
			ON KEY(F17)
				LET col = 3
				EXIT DISPLAY
			ON KEY(F18)
				LET col = 4
				EXIT DISPLAY
			ON KEY(F19)
				LET col = 5
				EXIT DISPLAY
			--#BEFORE DISPLAY
				--#CALL dialog.keysetlabel('RETURN','')
				--#CALL dialog.keysetlabel('ACCEPT','')
				--#CALL dialog.keysetlabel("F1","")
				--#CALL dialog.keysetlabel("CONTROL-W","")
			--#BEFORE ROW
				--#LET i = arr_curr()
				--#LET j = scr_line()
				--#CALL muestra_contadores_det(i, vm_num_det)
				--#DISPLAY BY NAME rm_adi[i].*
				--IF rm_det[i].r95_estado = 'A' THEN
					--#CALL dialog.keysetlabel("F5","Modificar")
				--ELSE
					--CALL dialog.keysetlabel("F5","")
				--END IF
			--#AFTER DISPLAY 
				--#CONTINUE DISPLAY
		END DISPLAY
		IF int_flag = 1 THEN
			EXIT WHILE
		END IF
		IF col <> vm_columna_1 THEN
			LET vm_columna_2           = vm_columna_1 
			LET rm_orden[vm_columna_2] = rm_orden[vm_columna_1]
			LET vm_columna_1           = col 
		END IF
		IF rm_orden[vm_columna_1] = 'ASC' THEN
			LET rm_orden[vm_columna_1] = 'DESC'
		ELSE
			LET rm_orden[vm_columna_1] = 'ASC'
		END IF
	END WHILE
END WHILE

END FUNCTION



FUNCTION lee_parametros()
DEFINE fecha_ini	DATE
DEFINE fecha_ini_aux	DATE
DEFINE fecha_fin	DATE
DEFINE dia		SMALLINT
DEFINE expr_sql		CHAR(400)
DEFINE nulo 		CHAR(1)
DEFINE mensaje		VARCHAR(250)

OPTIONS INPUT NO WRAP
INITIALIZE expr_sql, nulo TO NULL
LET fecha_ini = TODAY - (TODAY - MDY(01, 01, YEAR(TODAY))) UNITS DAY
LET int_flag  = 0
INPUT BY NAME vm_fecha_ini, vm_fecha_fin
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		LET int_flag = 1
		RETURN nulo
        ON KEY(F1,CONTROL-W)
		CALL llamar_visor_teclas()
	BEFORE INPUT
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
	AFTER FIELD vm_fecha_ini 
		IF vm_fecha_ini IS NOT NULL THEN
			IF vm_fecha_ini > TODAY THEN
				CALL fl_mostrar_mensaje('La fecha inicial no puede ser mayor a la de hoy.','exclamation')
				NEXT FIELD vm_fecha_ini
			END IF
		ELSE
			LET vm_fecha_ini = TODAY
			DISPLAY BY NAME vm_fecha_ini
		END IF
	AFTER FIELD vm_fecha_fin 
		IF vm_fecha_fin IS NOT NULL THEN
			IF vm_fecha_fin > TODAY THEN
				CALL fl_mostrar_mensaje('La fecha final no puede ser mayor a la de hoy.','exclamation')
				NEXT FIELD vm_fecha_fin
			END IF
		ELSE
			LET vm_fecha_fin = TODAY
			DISPLAY BY NAME vm_fecha_fin
		END IF
	AFTER INPUT
		IF vm_fecha_ini > vm_fecha_fin THEN
			CALL fl_mostrar_mensaje('Fecha inicial debe ser menor a la fecha final.','exclamation')
			NEXT FIELD vm_fecha_ini
		END IF
		IF vm_fecha_ini < fecha_ini THEN
			LET mensaje = 'La Fecha Inicial no puede ser menor que',
					' la fecha del ',
					fecha_ini USING "dd-mm-yyyy", '.'
			CALL fl_mostrar_mensaje(mensaje CLIPPED, 'exclamation')
			NEXT FIELD vm_fecha_ini
		END IF
END INPUT
OPTIONS INPUT WRAP
CONSTRUCT BY NAME expr_sql ON r95_persona_guia, r95_estado
	ON KEY(INTERRUPT)
		LET int_flag = 2
		RETURN nulo
        ON KEY(F1,CONTROL-W)
		CALL llamar_visor_teclas()
	BEFORE CONSTRUCT
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
END CONSTRUCT
RETURN expr_sql

END FUNCTION



FUNCTION control_modificar(i, j)
DEFINE i, j		SMALLINT
DEFINE aux_sri		LIKE rept095.r95_num_sri
DEFINE r_r95		RECORD LIKE rept095.*
DEFINE r_g37		RECORD LIKE gent037.*
DEFINE sec_sri		LIKE gent037.g37_sec_num_sri
DEFINE resul		SMALLINT
DEFINE cuantos		SMALLINT

BEGIN WORK
	WHENEVER ERROR CONTINUE
	DECLARE q_modsri2 CURSOR FOR
		SELECT * FROM rept095
			WHERE r95_compania      = vg_codcia
			  AND r95_localidad     = vg_codloc
			  AND r95_guia_remision = rm_det[i].r95_guia_remision
		FOR UPDATE
	OPEN q_modsri2
	FETCH q_modsri2 INTO r_r95.*
	IF STATUS < 0 THEN
		ROLLBACK WORK
		CALL fl_mostrar_mensaje('Lo siento ahora no puede modificar este No. del SRI, lo tiene bloqueado otro usuario.', 'exclamation')
		WHENEVER ERROR STOP
		RETURN
	END IF
	DECLARE q_sri CURSOR FOR
		SELECT * FROM gent037
			WHERE g37_compania  =  vg_codcia
			  AND g37_localidad =  vg_codloc
			  AND g37_tipo_doc  =  vm_tipo_doc
			{--
		  	  AND g37_fecha_emi <= DATE(TODAY)
		  	  AND g37_fecha_exp >= DATE(TODAY)
			--}
			  AND g37_secuencia IN
				(SELECT MAX(g37_secuencia)
				FROM gent037
				WHERE g37_compania  = vg_codcia
				  AND g37_localidad = vg_codloc
				  AND g37_tipo_doc  = vm_tipo_doc)
		FOR UPDATE
	OPEN q_sri
	FETCH q_sri INTO r_g37.*
	IF STATUS < 0 THEN
		ROLLBACK WORK
		CALL fl_mostrar_mensaje('Lo siento ahora no puede modificar este No. del SRI, porque ésta secuencia se encuentra bloqueada por otro usuario.', 'exclamation')
		WHENEVER ERROR STOP
		RETURN
	END IF
	WHENEVER ERROR STOP
	SELECT r95_num_sri INTO rm_det[i].r95_num_sri
		FROM rept095
		WHERE r95_compania      = vg_codcia
		  AND r95_localidad     = vg_codloc
		  AND r95_guia_remision = rm_det[i].r95_guia_remision
		  AND r95_num_sri[9,15] IN
			(SELECT MAX(r95_num_sri[9,15])
				FROM rept095
				WHERE r95_compania      = vg_codcia
				  AND r95_localidad     = vg_codloc
		  		  AND r95_guia_remision =
						rm_det[i].r95_guia_remision)
	OPTIONS INPUT WRAP
	LET int_flag = 0
	INPUT rm_det[i].r95_num_sri WITHOUT DEFAULTS FROM rm_det[j].r95_num_sri
		ON KEY(INTERRUPT)
			LET rm_det[i].r95_num_sri = aux_sri
			DISPLAY rm_det[i].r95_num_sri TO rm_det[j].r95_num_sri
			LET int_flag = 1
			EXIT INPUT
	        ON KEY(F1,CONTROL-W)
			CALL control_visor_teclas_caracter_2() 
		ON KEY(F5)
			CALL ver_guia_remision(i)
			LET int_flag = 0
		BEFORE INPUT
			--#CALL dialog.keysetlabel("F1","")
			--#CALL dialog.keysetlabel("CONTROL-W","")
			--#CALL dialog.keysetlabel("F5","Guía Remisión")
			LET aux_sri = rm_det[i].r95_num_sri
			CALL validar_num_sri(aux_sri, i, j) RETURNING resul
			CASE resul
				WHEN -1
					LET int_flag = 1
					EXIT INPUT
				WHEN 0
					NEXT FIELD r95_num_sri
			END CASE
		AFTER FIELD r95_num_sri
			IF rm_det[i].r95_num_sri IS NOT NULL THEN
				CALL validar_num_sri(aux_sri, i, j)
					RETURNING resul
				CASE resul
					WHEN -1
						LET int_flag = 1
						EXIT INPUT
					WHEN 0
						NEXT FIELD r95_num_sri
				END CASE
			ELSE
				LET rm_det[i].r95_num_sri = aux_sri
				DISPLAY rm_det[i].r95_num_sri TO
					rm_det[j].r95_num_sri
			END IF
		AFTER INPUT
			IF rm_det[i].r95_num_sri IS NOT NULL THEN
				CALL validar_num_sri(aux_sri, i, j)
					RETURNING resul
				CASE resul
					WHEN -1
						LET int_flag = 1
						EXIT INPUT
					WHEN 0
						NEXT FIELD r95_num_sri
				END CASE
			END IF
	END INPUT
	IF int_flag THEN
		ROLLBACK WORK
		RETURN
	END IF
	LET cuantos = 8 + r_g37.g37_num_dig_sri
	LET sec_sri = rm_det[i].r95_num_sri[9, cuantos] USING "########"
	UPDATE gent037 SET g37_sec_num_sri = sec_sri
		WHERE g37_compania    = r_g37.g37_compania
		  AND g37_localidad   = r_g37.g37_localidad
		  AND g37_tipo_doc    = r_g37.g37_tipo_doc
		  AND g37_secuencia   = r_g37.g37_secuencia
		  AND g37_sec_num_sri < sec_sri
	UPDATE rept095 SET r95_num_sri = rm_det[i].r95_num_sri
		WHERE CURRENT OF q_modsri2
	UPDATE tmp_sri
		SET r95_num_sri = rm_det[i].r95_num_sri
		WHERE r95_persona_guia  = rm_det[i].r95_persona_guia
		  AND r95_guia_remision = rm_det[i].r95_guia_remision
COMMIT WORK
CALL fl_mensaje_registro_modificado()

END FUNCTION



FUNCTION validar_num_sri(aux_sri, i, j)
DEFINE aux_sri		LIKE rept095.r95_num_sri
DEFINE i, j		SMALLINT
DEFINE r_g37		RECORD LIKE gent037.*
DEFINE cont		INTEGER
DEFINE flag		SMALLINT

IF valida_sri(i) THEN
	CALL fl_validacion_num_sri(vg_codcia, vg_codloc, vm_tipo_doc, 'N',
					rm_det[i].r95_num_sri)
		RETURNING r_g37.*, rm_det[i].r95_num_sri, flag
	CASE flag
		WHEN -1
			RETURN -1
		WHEN 0
			RETURN  0
	END CASE
END IF
DISPLAY rm_det[i].r95_num_sri TO rm_det[j].r95_num_sri
IF aux_sri <> rm_det[i].r95_num_sri THEN
	SELECT COUNT(*) INTO cont FROM rept095
		WHERE r95_compania  = vg_codcia
		  AND r95_localidad = vg_codloc
  		  AND r95_num_sri   = rm_det[i].r95_num_sri
	IF cont > 0 THEN
		CALL fl_mostrar_mensaje('La secuencia del SRI ' || rm_det[i].r95_num_sri[9,15] || ' ya existe.','exclamation')
		RETURN 0
	END IF
END IF
RETURN 1

END FUNCTION



FUNCTION valida_sri(i)
DEFINE i		SMALLINT
DEFINE r_g37		RECORD LIKE gent037.*
DEFINE r_r95		RECORD LIKE rept095.*

CALL fl_lee_guias_remision(vg_codcia, vg_codloc, rm_det[i].r95_guia_remision)
	RETURNING r_r95.*
INITIALIZE r_g37.* TO NULL
SELECT * INTO r_g37.*
	FROM gent037
	WHERE g37_compania   = vg_codcia
	  AND g37_localidad  = vg_codloc
	  AND g37_tipo_doc   = vm_tipo_doc
	  AND g37_secuencia IN
		(SELECT MAX(g37_secuencia)
			FROM gent037
			WHERE g37_compania  = vg_codcia
			  AND g37_localidad = vg_codloc
			  AND g37_tipo_doc  = vm_tipo_doc)
IF DATE(r_r95.r95_fecing) >= r_g37.g37_fecha_emi AND
   DATE(r_r95.r95_fecing) <= r_g37.g37_fecha_exp
THEN
	RETURN 1
ELSE
	RETURN 0
END IF

END FUNCTION



FUNCTION borrar_cabecera()

CLEAR vm_fecha_ini, vm_fecha_fin
INITIALIZE vm_fecha_ini, vm_fecha_fin TO NULL

END FUNCTION



FUNCTION borrar_detalle()
DEFINE i  		SMALLINT

CALL muestra_contadores_det(0, vm_num_det)
CALL retorna_arreglo()
FOR i = 1 TO vm_size_arr   
        INITIALIZE rm_det[i].* TO NULL
        CLEAR rm_det[i].*
END FOR

END FUNCTION



FUNCTION muestra_contadores_det(num_row, max_row)
DEFINE num_row, max_row	SMALLINT

DISPLAY BY NAME num_row, max_row

END FUNCTION


 
FUNCTION mostrar_cabecera_forma()

--#DISPLAY 'Guía Remisión'            TO tit_col1
--#DISPLAY 'Persona Responsable Guía' TO tit_col2
--#DISPLAY 'Fecha Guía'               TO tit_col3
--#DISPLAY 'Número del SRI'           TO tit_col4
--#DISPLAY 'E'                        TO tit_col5

END FUNCTION



FUNCTION ver_guia_remision(i)
DEFINE i		SMALLINT
DEFINE run_prog		CHAR(10)

LET run_prog = '; fglrun '
IF vg_gui = 0 THEN
	LET run_prog = '; fglgo '
END IF
LET vm_nuevoprog = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS',
		vg_separador, 'fuentes', vg_separador, run_prog, 'repp241 ',
		vg_base, ' ', vg_modulo, ' ', vg_codcia, ' ', vg_codloc, ' ',
		rm_det[i].r95_guia_remision
RUN vm_nuevoprog

END FUNCTION



FUNCTION retorna_arreglo()

--#LET vm_size_arr = fgl_scr_size('rm_det')

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



FUNCTION control_visor_teclas_caracter_1() 
DEFINE a, fila		INTEGER

CALL fl_visor_teclas_caracter() RETURNING fila
LET a = fila + 2
DISPLAY 'Teclas exclusivas de este proceso:' AT a,2 ATTRIBUTE(REVERSE)	
LET a = a + 1
DISPLAY '<F5>      Modificar'                AT a,2
DISPLAY  'F5' AT a,3 ATTRIBUTE(REVERSE)
LET a = a + 1
DISPLAY '<F6>      Guía Remisión'            AT a,2
DISPLAY  'F6' AT a,3 ATTRIBUTE(REVERSE)
LET a = fgl_getkey()
CLOSE WINDOW w_tf

END FUNCTION



FUNCTION control_visor_teclas_caracter_2() 
DEFINE a, fila		INTEGER

CALL fl_visor_teclas_caracter() RETURNING fila
LET a = fila + 2
DISPLAY 'Teclas exclusivas de este proceso:' AT a,2 ATTRIBUTE(REVERSE)	
LET a = a + 1
DISPLAY '<F5>      Guía Remisión'            AT a,2
DISPLAY  'F5' AT a,3 ATTRIBUTE(REVERSE)
LET a = fgl_getkey()
CLOSE WINDOW w_tf

END FUNCTION
