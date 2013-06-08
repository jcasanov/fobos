--------------------------------------------------------------------------------
-- Titulo           : cxpp209.4gl - Modificación del No. SRI de retenciones
-- Elaboracion      : 07-Jun-2007
-- Autor            : NPC
-- Formato Ejecucion: fglrun cxpp209 base módulo compañía localidad
-- Ultima Correccion: 
-- Motivo Correccion: 
--------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_nuevoprog     CHAR(400)
DEFINE vm_tipo_doc	LIKE gent037.g37_tipo_doc
DEFINE rm_det		ARRAY[10000] OF RECORD
				p29_num_ret	LIKE cxpt029.p29_num_ret,
				p01_nomprov	LIKE cxpt001.p01_nomprov,
				p27_fecing	DATE,
				p29_num_sri	LIKE cxpt029.p29_num_sri,
				p27_estado	LIKE cxpt027.p27_estado
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
CALL startlog('../logs/cxpp209.err')
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
LET vg_proceso = 'cxpp209'
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
		p29_num_ret		INTEGER,
		p01_nomprov		VARCHAR(50),
		p27_fecing		DATE,
		p29_num_sri		CHAR(16),
		p27_estado		CHAR(1)
	)
LET vm_tipo_doc = 'RT'
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
OPEN WINDOW w_cxpp209 AT row_ini, 2 WITH num_rows ROWS, num_cols COLUMNS
    ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE lin_menu,BORDER,
	      MESSAGE LINE LAST - 1)
IF vg_gui = 1 THEN
        OPEN FORM f_cxpf209_1 FROM '../forms/cxpf209_1'
ELSE
        OPEN FORM f_cxpf209_1 FROM '../forms/cxpf209_1c'
END IF
DISPLAY FORM f_cxpf209_1
CALL muestra_contadores_det(0)
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
	CALL muestra_contadores_det(0)
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
			' SELECT p27_num_ret, p01_nomprov, ',
				'DATE(p27_fecing) fecha_pro, p29_num_sri, ',
				'p27_estado ',
			' FROM cxpt027, cxpt001, OUTER cxpt029 ',
			' WHERE p27_compania     = ', vg_codcia,
			'   AND p27_localidad    = ', vg_codloc,
			--'   AND p27_estado       = "A"',
			'   AND DATE(p27_fecing) BETWEEN "', vm_fecha_ini,
						  '" AND "', vm_fecha_fin,'"',
			'   AND ', expr_sql CLIPPED, 
			'   AND p01_codprov      = p27_codprov ',
			'   AND p29_compania     = p27_compania ',
			'   AND p29_localidad    = p27_localidad ',
			'   AND p29_num_ret      = p27_num_ret '
	PREPARE cons_temp FROM query
	EXECUTE cons_temp
	WHILE TRUE
		LET query = 'SELECT * FROM tmp_sri ',
			" ORDER BY ", vm_columna_1, ' ', rm_orden[vm_columna_1],
		    	   	', ', vm_columna_2, ' ', rm_orden[vm_columna_2]
		PREPARE deto FROM query
		DECLARE q_deto CURSOR FOR deto
		LET vm_num_det = 1
		FOREACH q_deto INTO rm_det[vm_num_det].*
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
			ON KEY(F5)
				LET i = arr_curr()
				LET j = scr_line()
				IF rm_det[i].p27_estado = 'A' THEN
					CALL control_modificar(i, j)
					LET int_flag = 0
				END IF
			ON KEY(F6)
				LET i = arr_curr()
				LET j = scr_line()
				CALL ver_retencion(i)
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
				--#CALL dialog.keysetlabel('ACCEPT','')
				--#CALL dialog.keysetlabel("F1","")
				--#CALL dialog.keysetlabel("CONTROL-W","")
			--#BEFORE ROW
				--#LET i = arr_curr()
				--#LET j = scr_line()
				--#CALL muestra_contadores_det(i)
				--#IF rm_det[i].p27_estado = 'A' THEN
					--#CALL dialog.keysetlabel("F5","Modificar")
				--#ELSE
					--#CALL dialog.keysetlabel("F5","")
				--#END IF
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
--LET fecha_ini = TODAY - (TODAY - MDY(01, 01, YEAR(TODAY))) UNITS DAY
LET fecha_ini = MDY(12, 01, YEAR(TODAY) - 1)
LET int_flag  = 0
INPUT BY NAME vm_fecha_ini, vm_fecha_fin
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		LET int_flag = 1
		EXIT INPUT
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
IF int_flag THEN
	RETURN nulo
END IF
OPTIONS INPUT WRAP
LET int_flag = 0
CONSTRUCT BY NAME expr_sql ON p01_nomprov, p27_estado
	ON KEY(INTERRUPT)
		LET int_flag = 2
		EXIT CONSTRUCT
        ON KEY(F1,CONTROL-W)
		CALL llamar_visor_teclas()
	BEFORE CONSTRUCT
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
END CONSTRUCT
IF int_flag = 2 THEN
	RETURN nulo
END IF
RETURN expr_sql

END FUNCTION



FUNCTION control_modificar(i, j)
DEFINE i, j		SMALLINT
DEFINE aux_sri		LIKE cxpt029.p29_num_sri
DEFINE r_p29		RECORD LIKE cxpt029.*
DEFINE r_g37		RECORD LIKE gent037.*
DEFINE sec_sri		LIKE gent037.g37_sec_num_sri
DEFINE resul		SMALLINT
DEFINE cuantos		SMALLINT

BEGIN WORK
	WHENEVER ERROR CONTINUE
	DECLARE q_modsri2 CURSOR FOR
		SELECT * FROM cxpt029
			WHERE p29_compania  = vg_codcia
			  AND p29_localidad = vg_codloc
			  AND p29_num_ret   = rm_det[i].p29_num_ret
		FOR UPDATE
	OPEN q_modsri2
	FETCH q_modsri2 INTO r_p29.*
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
	SELECT p29_num_sri INTO rm_det[i].p29_num_sri
		FROM cxpt029
		WHERE p29_compania  = vg_codcia
		  AND p29_localidad = vg_codloc
		  AND p29_num_ret   = rm_det[i].p29_num_ret
		  AND p29_num_sri[9,15] IN
			(SELECT MAX(p29_num_sri[9,15])
				FROM cxpt029
				WHERE p29_compania  = vg_codcia
				  AND p29_localidad = vg_codloc
		  		  AND p29_num_ret   = rm_det[i].p29_num_ret)
	OPTIONS INPUT WRAP
	LET int_flag = 0
	INPUT rm_det[i].p29_num_sri WITHOUT DEFAULTS FROM rm_det[j].p29_num_sri
		ON KEY(INTERRUPT)
			LET rm_det[i].p29_num_sri = aux_sri
			DISPLAY rm_det[i].p29_num_sri TO rm_det[j].p29_num_sri
			LET int_flag = 1
			EXIT INPUT
	        ON KEY(F1,CONTROL-W)
			CALL control_visor_teclas_caracter_2() 
		ON KEY(F5)
			CALL ver_retencion(i)
			LET int_flag = 0
		BEFORE INPUT
			--#CALL dialog.keysetlabel("F1","")
			--#CALL dialog.keysetlabel("CONTROL-W","")
			--#CALL dialog.keysetlabel("F5","Retencion")
			LET aux_sri = rm_det[i].p29_num_sri
			CALL validar_num_sri(aux_sri, i, j) RETURNING resul
			CASE resul
				WHEN -1
					LET int_flag = 1
					EXIT INPUT
				WHEN 0
					NEXT FIELD p29_num_sri
			END CASE
		AFTER FIELD p29_num_sri
			IF rm_det[i].p29_num_sri IS NOT NULL THEN
				CALL validar_num_sri(aux_sri, i, j)
					RETURNING resul
				CASE resul
					WHEN -1
						LET int_flag = 1
						EXIT INPUT
					WHEN 0
						NEXT FIELD p29_num_sri
				END CASE
			ELSE
				LET rm_det[i].p29_num_sri = aux_sri
				DISPLAY rm_det[i].p29_num_sri TO
					rm_det[j].p29_num_sri
			END IF
		AFTER INPUT
			IF rm_det[i].p29_num_sri IS NOT NULL THEN
				CALL validar_num_sri(aux_sri, i, j)
					RETURNING resul
				CASE resul
					WHEN -1
						LET int_flag = 1
						EXIT INPUT
					WHEN 0
						NEXT FIELD p29_num_sri
				END CASE
			END IF
	END INPUT
	IF int_flag THEN
		ROLLBACK WORK
		RETURN
	END IF
	LET cuantos = 8 + r_g37.g37_num_dig_sri
	LET sec_sri = rm_det[i].p29_num_sri[9, cuantos] USING "########"
	UPDATE gent037 SET g37_sec_num_sri = sec_sri
		WHERE g37_compania    = r_g37.g37_compania
		  AND g37_localidad   = r_g37.g37_localidad
		  AND g37_tipo_doc    = r_g37.g37_tipo_doc
		  AND g37_secuencia   = r_g37.g37_secuencia
		  AND g37_sec_num_sri < sec_sri
	OPEN q_modsri2
	FETCH q_modsri2 INTO r_p29.*
	IF STATUS <> NOTFOUND THEN
		DELETE FROM cxpt029 WHERE CURRENT OF q_modsri2
	END IF
	INSERT INTO cxpt029
		VALUES (vg_codcia, vg_codloc, rm_det[i].p29_num_ret,
			rm_det[i].p29_num_sri)
	SELECT * FROM cxpt032
		WHERE p32_compania  = vg_codcia
		  AND p32_localidad = vg_codloc
		  AND p32_num_ret   = rm_det[i].p29_num_ret
		  AND p32_tipo_doc  = r_g37.g37_tipo_doc
		  AND p32_secuencia = r_g37.g37_secuencia
	IF STATUS = NOTFOUND THEN
		INSERT INTO cxpt032
			VALUES (vg_codcia, vg_codloc, rm_det[i].p29_num_ret,
				r_g37.g37_tipo_doc, r_g37.g37_secuencia)
	END IF
	UPDATE tmp_sri
		SET p29_num_sri = rm_det[i].p29_num_sri
		WHERE p01_nomprov = rm_det[i].p01_nomprov
		  AND p29_num_ret = rm_det[i].p29_num_ret
COMMIT WORK
CALL fl_mensaje_registro_modificado()

END FUNCTION



FUNCTION validar_num_sri(aux_sri, i, j)
DEFINE aux_sri		LIKE cxpt029.p29_num_sri
DEFINE i, j		SMALLINT
DEFINE r_g37		RECORD LIKE gent037.*
DEFINE cont		INTEGER
DEFINE flag		SMALLINT

IF valida_sri(i) THEN
	CALL fl_validacion_num_sri(vg_codcia, vg_codloc, vm_tipo_doc, 'N',
					rm_det[i].p29_num_sri)
		RETURNING r_g37.*, rm_det[i].p29_num_sri, flag
	CASE flag
		WHEN -1
			RETURN -1
		WHEN 0
			RETURN  0
	END CASE
END IF
DISPLAY rm_det[i].p29_num_sri TO rm_det[j].p29_num_sri
IF aux_sri <> rm_det[i].p29_num_sri THEN
	SELECT COUNT(*) INTO cont FROM cxpt029
		WHERE p29_compania  = vg_codcia
		  AND p29_localidad = vg_codloc
  		  AND p29_num_sri   = rm_det[i].p29_num_sri
	IF cont > 0 THEN
		CALL fl_mostrar_mensaje('La secuencia del SRI ' || rm_det[i].p29_num_sri[9,15] || ' ya existe.','exclamation')
		RETURN 0
	END IF
END IF
RETURN 1

END FUNCTION



FUNCTION valida_sri(i)
DEFINE i		SMALLINT
DEFINE r_g37		RECORD LIKE gent037.*
DEFINE r_p27		RECORD LIKE cxpt027.*

CALL fl_lee_retencion_cxp(vg_codcia, vg_codloc, rm_det[i].p29_num_ret)
	RETURNING r_p27.*
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
IF DATE(r_p27.p27_fecing) >= r_g37.g37_fecha_emi AND
   DATE(r_p27.p27_fecing) <= r_g37.g37_fecha_exp
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

CALL muestra_contadores_det(0)
CALL retorna_arreglo()

FOR i = 1 TO vm_size_arr   
        INITIALIZE rm_det[i].* TO NULL
        CLEAR rm_det[i].*
END FOR

END FUNCTION



FUNCTION muestra_contadores_det(cor)
DEFINE cor	           SMALLINT

IF vg_gui = 1 THEN
	DISPLAY "" AT 21, 2
	DISPLAY cor, " de ", vm_num_det AT 21, 6
END IF

END FUNCTION


 
FUNCTION mostrar_cabecera_forma()

--#DISPLAY 'Retencion'            TO tit_col1
--#DISPLAY 'Nombre del Proveedor' TO tit_col2
--#DISPLAY 'Fecha'                TO tit_col3
--#DISPLAY 'Número del SRI'       TO tit_col4
--#DISPLAY 'E'                    TO tit_col5

END FUNCTION



FUNCTION ver_retencion(i)
DEFINE i		SMALLINT
DEFINE run_prog		CHAR(10)
DEFINE r_p27		RECORD LIKE cxpt027.*

LET run_prog = '; fglrun '
IF vg_gui = 0 THEN
	LET run_prog = '; fglgo '
END IF
CALL fl_lee_retencion_cxp(vg_codcia, vg_codloc, rm_det[i].p29_num_ret)
	RETURNING r_p27.*
LET vm_nuevoprog = 'cd ..', vg_separador, '..', vg_separador, 'TESORERIA',
	vg_separador, 'fuentes', vg_separador, run_prog, 'cxpp304 ', vg_base,
	' TE ', vg_codcia, ' ', vg_codloc, ' ', r_p27.p27_codprov, ' ',
	rm_det[i].p29_num_ret
RUN vm_nuevoprog

END FUNCTION



FUNCTION retorna_arreglo()

--#LET vm_size_arr = fgl_scr_size('rm_det')
IF vg_gui = 0 THEN
        LET vm_size_arr = 13
END IF

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
DISPLAY '<F6>      Retencion'                AT a,2
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
DISPLAY '<F5>      Retencion'                AT a,2
DISPLAY  'F5' AT a,3 ATTRIBUTE(REVERSE)
LET a = fgl_getkey()
CLOSE WINDOW w_tf

END FUNCTION
