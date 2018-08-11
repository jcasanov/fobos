--------------------------------------------------------------------------------
-- Titulo           : cajp209.4gl - Modificación del No. SRI en emisión Factura
-- Elaboracion      : 30-Nov-2002
-- Autor            : NPC
-- Formato Ejecucion: fglrun cajp209 base módulo compañía localidad
-- Ultima Correccion: 
-- Motivo Correccion: 
--------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_nuevoprog     CHAR(400)
DEFINE vm_tipo_doc	LIKE rept038.r38_cod_tran
DEFINE vm_max_det       SMALLINT
DEFINE vm_num_det       SMALLINT
DEFINE vm_fecha_ini	DATE
DEFINE vm_fecha_fin	DATE
DEFINE fecha_arran	DATE
DEFINE rm_det		ARRAY[10000] OF RECORD
				r38_tipo_fuente	LIKE rept038.r38_tipo_fuente,
				r38_num_tran	LIKE rept038.r38_num_tran,
				j10_nomcli	LIKE cajt010.j10_nomcli,
				r19_fecing	DATE,
				r38_num_sri	LIKE rept038.r38_num_sri
			END RECORD
DEFINE rm_adi		ARRAY[10000] OF RECORD
				j10_num_fuente	LIKE cajt010.j10_num_fuente,
				j10_codcli	LIKE cajt010.j10_codcli
			END RECORD
DEFINE rm_orden 	ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1	SMALLINT
DEFINE vm_columna_2	SMALLINT
DEFINE vm_size_arr	INTEGER



MAIN

DEFER QUIT 
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/cajp209.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 THEN   -- Validar # parámetros correcto
	CALL fl_mostrar_mensaje('Número de parámetros incorrecto.','stop')
	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_codloc  = arg_val(4)
LET vg_proceso = 'cajp209'
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
		r38_tipo_fuente		CHAR(2),
		r38_num_tran		INTEGER,
		j10_nomcli		VARCHAR(50),
		r19_fecing		DATE,
		r38_num_sri		CHAR(21),
		j10_num_fuente		INTEGER,
		j10_codcli		INTEGER
	)
LET vm_tipo_doc = 'FA'
LET vm_max_det  = 10000
LET fecha_arran = vg_fecha
DECLARE q_g37 CURSOR FOR
	SELECT g37_fecha_emi, g37_secuencia FROM gent037
		WHERE g37_compania  = vg_codcia
		  AND g37_localidad = vg_codloc
		  AND g37_tipo_doc  = 'NV'
		ORDER BY g37_secuencia
OPEN q_g37
FETCH q_g37 INTO fecha_arran, secuencia
CLOSE q_g37
FREE q_g37
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
OPEN WINDOW w_mas AT row_ini, 2 WITH num_rows ROWS, num_cols COLUMNS
    ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE lin_menu,BORDER,
	      MESSAGE LINE LAST - 1)
IF vg_gui = 1 THEN
        OPEN FORM f_caj FROM '../forms/cajf209_1'
ELSE
        OPEN FORM f_caj FROM '../forms/cajf209_1c'
END IF
DISPLAY FORM f_caj
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
DEFINE expr1, expr2	VARCHAR(100)

LET vm_fecha_ini = vg_fecha
LET vm_fecha_fin = vg_fecha
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
	LET query ='SELECT j10_tipo_fuente, j10_num_destino, j10_nomcli, ',
				'DATE(j10_fecha_pro) fecha_pro, r38_num_sri, ',
				'j10_tipo_destino, j10_num_fuente, j10_codcli ',
			' FROM cajt010, OUTER rept038 ',
			' WHERE j10_compania        = ', vg_codcia,
			'   AND j10_localidad       = ', vg_codloc,
			'   AND DATE(j10_fecha_pro) BETWEEN "', vm_fecha_ini,
						    '" AND "', vm_fecha_fin,'"',
			'   AND j10_tipo_destino    = "', vm_tipo_doc, '"',
			'   AND ', expr_sql CLIPPED, 
			'   AND r38_compania        = j10_compania ',
			'   AND r38_localidad       = j10_localidad ',
			'   AND r38_tipo_doc        = "', vm_tipo_doc, '"',
			'   AND r38_tipo_fuente     = j10_tipo_fuente ',
			'   AND r38_cod_tran        = j10_tipo_destino ',
			'   AND r38_num_tran        = j10_num_destino ',
			' INTO TEMP t1 '
	PREPARE cons_t1 FROM query
	EXECUTE cons_t1
	LET expr1 = '   AND z01_tipo_doc_id  = "R" '
	LET expr2 = '   AND LENGTH(t23_cedruc) = 13 '
	IF vg_codloc <> 3 AND vm_fecha_ini >= MDY(12, 01, 2010) THEN
		LET expr1 = NULL
		LET expr2 = NULL
	END IF
	IF vg_codloc = 3 AND vm_fecha_ini >= MDY(02, 22, 2011) THEN
		LET expr1 = NULL
		LET expr2 = NULL
	END IF
	LET query = ' SELECT j10_tipo_fuente, j10_num_destino, j10_nomcli, ',
				'fecha_pro, r38_num_sri, j10_num_fuente, ',
				'j10_codcli ',
			' FROM t1, rept019, cxct001 ',
			' WHERE j10_tipo_fuente  = "PR" ',
			'   AND r19_compania     = ', vg_codcia,
			'   AND r19_localidad    = ', vg_codloc,
			'   AND r19_cod_tran     = j10_tipo_destino ',
			'   AND r19_num_tran     = j10_num_destino ',
			'   AND z01_codcli       = r19_codcli ',
			'   AND fecha_pro        < "', fecha_arran, '" ',
			' UNION ',
			' SELECT j10_tipo_fuente, j10_num_destino, j10_nomcli,',
				' fecha_pro, r38_num_sri, j10_num_fuente,',
				' j10_codcli ',
			' FROM t1, rept019, cxct001 ',
			' WHERE j10_tipo_fuente  = "PR" ',
			'   AND r19_compania     = ', vg_codcia,
			'   AND r19_localidad    = ', vg_codloc,
			'   AND r19_cod_tran     = j10_tipo_destino ',
			'   AND r19_num_tran     = j10_num_destino ',
			'   AND z01_codcli       = r19_codcli ',
			'   AND fecha_pro       >= "', fecha_arran, '" ',
			expr1 CLIPPED,
			--'   AND LENGTH(r19_cedruc) = 13 ',
			' UNION ',
			' SELECT j10_tipo_fuente, j10_num_destino, j10_nomcli,',
				' fecha_pro, r38_num_sri, j10_num_fuente,',
				' j10_codcli ',
			' FROM t1, talt023, cxct001 ',
			' WHERE j10_tipo_fuente  = "OT" ',
			'   AND t23_compania     = ', vg_codcia,
			'   AND t23_localidad    = ', vg_codloc,
			'   AND t23_num_factura  = j10_num_destino ',
			'   AND z01_codcli       = t23_cod_cliente ',
			'   AND fecha_pro        < "', fecha_arran, '" ',
			' UNION ',
			' SELECT j10_tipo_fuente, j10_num_destino, j10_nomcli,',
				' fecha_pro, r38_num_sri, j10_num_fuente,',
				' j10_codcli ',
			' FROM t1, talt023, cxct001 ',
			' WHERE j10_tipo_fuente  = "OT" ',
			'   AND t23_compania     = ', vg_codcia,
			'   AND t23_localidad    = ', vg_codloc,
			'   AND t23_num_factura  = j10_num_destino ',
			'   AND z01_codcli       = t23_cod_cliente ',
			--'   AND z01_tipo_doc_id  = "R" ',
			'   AND fecha_pro       >= "', fecha_arran, '" ',
			expr2 CLIPPED,
			' INTO TEMP t2 '
	PREPARE cons_t2 FROM query
	EXECUTE cons_t2
	INSERT INTO tmp_sri SELECT * FROM t2
	DROP TABLE t1
	DROP TABLE t2
	WHILE TRUE
		LET query = 'SELECT * FROM tmp_sri ',
			" ORDER BY ", vm_columna_1, ' ', rm_orden[vm_columna_1],
		    	   	', ', vm_columna_2, ' ', rm_orden[vm_columna_2]
		PREPARE deto2 FROM query
		DECLARE q_deto2 CURSOR FOR deto2
		LET vm_num_det = 1
		FOREACH q_deto2 INTO rm_det[vm_num_det].*, rm_adi[vm_num_det].*
			LET vm_num_det = vm_num_det + 1
			IF vm_num_det > vm_max_det THEN
				CALL fl_mensaje_arreglo_incompleto()
				EXIT PROGRAM
				--EXIT FOREACH
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
			--#BEFORE DISPLAY
				--#CALL dialog.keysetlabel('ACCEPT','')
				--#CALL dialog.keysetlabel("F1","")
				--#CALL dialog.keysetlabel("CONTROL-W","")
			--#BEFORE ROW
				--#LET i = arr_curr()
				--#LET j = scr_line()
				--#CALL muestra_contadores_det(i)
				--#CALL dialog.keysetlabel("F5","Modificar")
			--#AFTER DISPLAY 
				--#CONTINUE DISPLAY
			ON KEY(INTERRUPT)
				LET int_flag = 1
				EXIT DISPLAY
        		ON KEY(F1,CONTROL-W)
				CALL control_visor_teclas_caracter_1() 
			ON KEY(F5)
				LET i = arr_curr()
				LET j = scr_line()
				CALL control_modificar(i, j)
				LET int_flag = 0
			ON KEY(F6)
				LET i = arr_curr()
				LET j = scr_line()
				CALL ver_factura(i)
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
LET fecha_ini = MDY(12, 01, YEAR(vg_fecha) - 1)
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
			IF vm_fecha_ini > vg_fecha THEN
				CALL fl_mostrar_mensaje('La fecha inicial no puede ser mayor a la de hoy.','exclamation')
				NEXT FIELD vm_fecha_ini
			END IF
		ELSE
			LET vm_fecha_ini = vg_fecha
			DISPLAY BY NAME vm_fecha_ini
		END IF
	AFTER FIELD vm_fecha_fin 
		IF vm_fecha_fin IS NOT NULL THEN
			IF vm_fecha_fin > vg_fecha THEN
				CALL fl_mostrar_mensaje('La fecha final no puede ser mayor a la de hoy.','exclamation')
				NEXT FIELD vm_fecha_fin
			END IF
		ELSE
			LET vm_fecha_fin = vg_fecha
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
CONSTRUCT BY NAME expr_sql ON j10_nomcli
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
DEFINE cont		INTEGER
DEFINE aux_sri		LIKE rept038.r38_num_sri
DEFINE r_r38		RECORD LIKE rept038.*
DEFINE r_r95		RECORD LIKE rept095.*
DEFINE r_g37		RECORD LIKE gent037.*
DEFINE cont_cred	LIKE gent037.g37_cont_cred
DEFINE sec_sri		LIKE gent037.g37_sec_num_sri
DEFINE resul		SMALLINT
DEFINE cuantos		SMALLINT
DEFINE tiene_j14	SMALLINT
DEFINE mensaje		VARCHAR(200)
DEFINE resp		CHAR(6)

DEFINE fecha_actual DATETIME YEAR TO SECOND

BEGIN WORK
	WHENEVER ERROR STOP
	DECLARE q_modsri2 CURSOR FOR
		SELECT * FROM rept038
			WHERE r38_compania    = vg_codcia
			  AND r38_localidad   = vg_codloc
			  AND r38_tipo_doc    = vm_tipo_doc
			  AND r38_tipo_fuente = rm_det[i].r38_tipo_fuente
			  AND r38_cod_tran    = vm_tipo_doc
			  AND r38_num_tran    = rm_det[i].r38_num_tran
		FOR UPDATE
	WHENEVER ERROR CONTINUE
	OPEN q_modsri2
	FETCH q_modsri2 INTO r_r38.*
	IF STATUS < 0 THEN
		ROLLBACK WORK
		CALL fl_mostrar_mensaje('Lo siento ahora no puede modificar este No. del SRI, lo tiene bloqueado otro usuario.','exclamation')
		WHENEVER ERROR STOP
		RETURN
	END IF
	CALL retorna_cont_cred(i) RETURNING cont_cred
	DECLARE q_sri CURSOR FOR
		SELECT * FROM gent037
			WHERE g37_compania  =  vg_codcia
			  AND g37_localidad =  vg_codloc
			  AND g37_tipo_doc  =  vm_tipo_doc
			  AND g37_cont_cred =  cont_cred
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
		CALL fl_mostrar_mensaje('Lo siento ahora no puede modificar este No. del SRI, porque ésta secuencia se encuentra bloqueada por otro usuario.','exclamation')
		WHENEVER ERROR STOP
		RETURN
	END IF
	WHENEVER ERROR STOP
	SELECT r38_num_sri
		INTO rm_det[i].r38_num_sri
		FROM rept038
		WHERE r38_compania    = vg_codcia
		  AND r38_localidad   = vg_codloc
		  AND r38_tipo_doc    = vm_tipo_doc
  		  AND r38_tipo_fuente = rm_det[i].r38_tipo_fuente
		  AND r38_cod_tran    = vm_tipo_doc
		  AND r38_num_tran    = rm_det[i].r38_num_tran
		  AND r38_num_sri[9,15] IN
			(SELECT MAX(r38_num_sri[9,15])
				FROM rept038
				WHERE r38_compania    = vg_codcia
				  AND r38_localidad   = vg_codloc
				  AND r38_tipo_doc    = vm_tipo_doc
  				AND r38_tipo_fuente = rm_det[i].r38_tipo_fuente
		  		  AND r38_cod_tran    = vm_tipo_doc
		  		  AND r38_num_tran    = rm_det[i].r38_num_tran)
	CALL lee_guia_remision(i) RETURNING r_r95.*
	IF r_r95.r95_compania IS NOT NULL THEN
		LET int_flag = 0
		CALL fl_hacer_pregunta('Esta factura tiene una guía de remisión generada, si modifica el número de factura,\nla GUIA DE REMISION SERA ELIMINADA. Desea modificar el número de factura ?', 'Yes')
			RETURNING resp
		IF resp = 'No' THEN
			LET int_flag = 0
			ROLLBACK WORK
			RETURN
		END IF
		WHENEVER ERROR CONTINUE
		DECLARE q_r95 CURSOR FOR
			SELECT * FROM rept095
				WHERE r95_compania      = r_r95.r95_compania
				  AND r95_localidad     = r_r95.r95_localidad
				  AND r95_guia_remision =r_r95.r95_guia_remision
			FOR UPDATE
		OPEN q_r95
		FETCH q_r95 INTO r_r95.*
		IF STATUS < 0 THEN
			ROLLBACK WORK
			CALL fl_mostrar_mensaje('Lo siento ahora no se puede ELIMINAR la Guía de Remisión, porque ésta se encuentra bloqueada por otro usuario.', 'exclamation')
			WHENEVER ERROR STOP
			RETURN
		END IF
		IF STATUS = NOTFOUND THEN
			ROLLBACK WORK
			CALL fl_mostrar_mensaje('La Guía de Remisión no ha sido encontrada. Por favor llame al ADMINISTRADOR.', 'exclamation')
			WHENEVER ERROR STOP
			RETURN
		END IF
		LET fecha_actual = fl_current()
		UPDATE rept095
			SET r95_estado   = 'E',
			    r95_usu_elim = vg_usuario,
			    r95_fec_elim = fecha_actual
			WHERE CURRENT OF q_r95
		IF STATUS <> 0 THEN
			ROLLBACK WORK
			CALL fl_mostrar_mensaje('Lo siento ahora no se puede ELIMINAR la Guía de Remisión, porque ha ocurrido un error de actualización en la base de datos. Por favor llame al administrador.', 'exclamation')
			WHENEVER ERROR STOP
			RETURN
		END IF
		WHENEVER ERROR STOP
		LET mensaje = 'La Guía de Remisión (',
				r_r95.r95_guia_remision USING "<<<<<<&", ') ',
				r_r95.r95_num_sri CLIPPED, '\nde la factura ',
				rm_det[i].r38_num_tran USING "<<<<<<&", ', ',
				'ha sido ELIMINADA. OK'
		CALL fl_mostrar_mensaje(mensaje, 'info')
	END IF
	OPTIONS INPUT WRAP
	LET int_flag = 0
	INPUT rm_det[i].r38_num_sri
		WITHOUT DEFAULTS
		FROM rm_det[j].r38_num_sri
		ON KEY(INTERRUPT)
			LET rm_det[i].r38_num_sri = aux_sri
			DISPLAY rm_det[i].r38_num_sri TO rm_det[j].r38_num_sri
			LET int_flag = 1
			EXIT INPUT
	        ON KEY(F1,CONTROL-W)
			CALL control_visor_teclas_caracter_2() 
		ON KEY(F5)
			CALL ver_factura(i)
			LET int_flag = 0
		BEFORE INPUT
			--#CALL dialog.keysetlabel("F1","")
			--#CALL dialog.keysetlabel("CONTROL-W","")
			--#CALL dialog.keysetlabel("F5","Factura")
			LET aux_sri = rm_det[i].r38_num_sri
			CALL validar_num_sri(aux_sri, i, j) RETURNING resul
			CASE resul
				WHEN -1
					LET int_flag = 1
					EXIT INPUT
				WHEN 0
					NEXT FIELD r38_num_sri
			END CASE
		AFTER FIELD r38_num_sri
			IF rm_det[i].r38_num_sri IS NOT NULL THEN
				CALL validar_num_sri(aux_sri, i, j)
					RETURNING resul
				CASE resul
					WHEN -1
						LET int_flag = 1
						EXIT INPUT
					WHEN 0
						NEXT FIELD r38_num_sri
				END CASE
			ELSE
				LET rm_det[i].r38_num_sri = aux_sri
				DISPLAY rm_det[i].r38_num_sri TO
					rm_det[j].r38_num_sri
			END IF
		AFTER INPUT
			IF rm_det[i].r38_num_sri IS NOT NULL THEN
				CALL validar_num_sri(aux_sri, i, j)
					RETURNING resul
				CASE resul
					WHEN -1
						LET int_flag = 1
						EXIT INPUT
					WHEN 0
						NEXT FIELD r38_num_sri
				END CASE
			END IF
	END INPUT
	IF int_flag THEN
		ROLLBACK WORK
		RETURN
	END IF
	LET cuantos   = 8 + r_g37.g37_num_dig_sri
	LET sec_sri   = rm_det[i].r38_num_sri[9, cuantos] USING "########"
	LET tiene_j14 = 0
	UPDATE gent037 SET g37_sec_num_sri = sec_sri
		WHERE g37_compania    = r_g37.g37_compania
		  AND g37_localidad   = r_g37.g37_localidad
		  AND g37_tipo_doc    = r_g37.g37_tipo_doc
		  AND g37_secuencia   = r_g37.g37_secuencia
		  AND g37_sec_num_sri < sec_sri
	OPEN q_modsri2
	FETCH q_modsri2 INTO r_r38.*
	IF STATUS <> NOTFOUND THEN
		SELECT * FROM cajt014
			WHERE j14_compania  = r_r38.r38_compania
			  AND j14_localidad = r_r38.r38_localidad
			  AND j14_tipo_doc  = r_r38.r38_tipo_doc
			  AND j14_tipo_fue  = r_r38.r38_tipo_fuente
			  AND j14_cod_tran  = r_r38.r38_cod_tran
			  AND j14_num_tran  = r_r38.r38_num_tran
			INTO TEMP tmp_j14
		DELETE FROM cajt014
			WHERE j14_compania  = r_r38.r38_compania
			  AND j14_localidad = r_r38.r38_localidad
			  AND j14_tipo_doc  = r_r38.r38_tipo_doc
			  AND j14_tipo_fue  = r_r38.r38_tipo_fuente
			  AND j14_cod_tran  = r_r38.r38_cod_tran
			  AND j14_num_tran  = r_r38.r38_num_tran
		DELETE FROM rept038 WHERE CURRENT OF q_modsri2
		LET tiene_j14 = 1
	END IF
	INSERT INTO rept038
		VALUES (vg_codcia, vg_codloc, r_g37.g37_tipo_doc,
			rm_det[i].r38_tipo_fuente, vm_tipo_doc,
			rm_det[i].r38_num_tran, rm_det[i].r38_num_sri)
	IF tiene_j14 THEN
		UPDATE tmp_j14
			SET j14_num_fact_sri = rm_det[i].r38_num_sri
			WHERE 1 = 1
		INSERT INTO cajt014 SELECT * FROM tmp_j14
		DROP TABLE tmp_j14
	END IF
	UPDATE tmp_sri SET r38_num_sri = rm_det[i].r38_num_sri
		WHERE j10_nomcli      = rm_det[i].j10_nomcli
		  AND r38_tipo_fuente = rm_det[i].r38_tipo_fuente
		  AND r38_num_tran    = rm_det[i].r38_num_tran
COMMIT WORK
CALL fl_mensaje_registro_modificado()

END FUNCTION



FUNCTION validar_num_sri(aux_sri, i, j)
DEFINE aux_sri		LIKE rept038.r38_num_sri
DEFINE i, j		SMALLINT
DEFINE r_g37		RECORD LIKE gent037.*
DEFINE cont_cred	LIKE gent037.g37_cont_cred
DEFINE cont		INTEGER
DEFINE flag		SMALLINT

IF valida_sri(i) THEN
	CALL retorna_cont_cred(i) RETURNING cont_cred
	CALL fl_validacion_num_sri(vg_codcia, vg_codloc, vm_tipo_doc, cont_cred,
					rm_det[i].r38_num_sri)
		RETURNING r_g37.*, rm_det[i].r38_num_sri, flag
	CASE flag
		WHEN -1
			RETURN -1
		WHEN 0
			RETURN  0
	END CASE
END IF
DISPLAY rm_det[i].r38_num_sri TO rm_det[j].r38_num_sri
{--
IF LENGTH(rm_det[i].r38_num_sri) < 15 THEN
	CALL fl_mostrar_mensaje('Digite completo el número del SRI.','exclamation')
	RETURN 0
END IF
--}
IF aux_sri <> rm_det[i].r38_num_sri THEN
	SELECT COUNT(*) INTO cont FROM rept038
		WHERE r38_compania    = vg_codcia
		  AND r38_localidad   = vg_codloc
		  AND r38_tipo_doc    = r_g37.g37_tipo_doc
  		  AND r38_tipo_fuente = rm_det[i].r38_tipo_fuente
  		  AND r38_num_sri     = rm_det[i].r38_num_sri
	IF cont > 0 THEN
		CALL fl_mostrar_mensaje('La secuencia del SRI ' || rm_det[i].r38_num_sri[9,17] || ' ya existe.','exclamation')
		RETURN 0
	END IF
END IF
RETURN 1

END FUNCTION



FUNCTION retorna_cont_cred(i)
DEFINE i		SMALLINT
DEFINE r_r19		RECORD LIKE rept019.*
DEFINE r_t23		RECORD LIKE talt023.*
DEFINE cont_cred	LIKE gent037.g37_cont_cred
DEFINE cont		INTEGER

LET cont_cred = 'N'
SELECT COUNT(*) INTO cont FROM gent037
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
IF cont > 1 THEN
	IF rm_det[i].r38_tipo_fuente = 'PR' THEN
		CALL fl_lee_cabecera_transaccion_rep(vg_codcia, vg_codloc,
					vm_tipo_doc, rm_det[i].r38_num_tran)
			RETURNING r_r19.*
		LET cont_cred = r_r19.r19_cont_cred
	END IF
	IF rm_det[i].r38_tipo_fuente = 'OT' THEN
		CALL fl_lee_factura_taller(vg_codcia, vg_codloc,
						rm_det[i].r38_num_tran)
			RETURNING r_t23.*
		LET cont_cred = r_t23.t23_cont_cred
	END IF
END IF
RETURN cont_cred

END FUNCTION



FUNCTION valida_sri(i)
DEFINE i		SMALLINT
DEFINE r_g37		RECORD LIKE gent037.*
DEFINE r_r19		RECORD LIKE rept019.*
DEFINE r_t23		RECORD LIKE talt023.*
DEFINE fecha		DATE

IF rm_det[i].r38_tipo_fuente = 'PR' THEN
	CALL fl_lee_cabecera_transaccion_rep(vg_codcia, vg_codloc, vm_tipo_doc,
						rm_det[i].r38_num_tran)
		RETURNING r_r19.*
	LET fecha = DATE(r_r19.r19_fecing)
END IF
IF rm_det[i].r38_tipo_fuente = 'OT' THEN
	CALL fl_lee_factura_taller(vg_codcia, vg_codloc, rm_det[i].r38_num_tran)
		RETURNING r_t23.*
	LET fecha = DATE(r_t23.t23_fec_factura)
END IF
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
IF fecha >= r_g37.g37_fecha_emi AND fecha <= r_g37.g37_fecha_exp THEN
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

--#DISPLAY 'TP'                 TO tit_col1
--#DISPLAY 'No. Factura'        TO tit_col2
--#DISPLAY 'Nombre del Cliente' TO tit_col3
--#DISPLAY 'Fecha'              TO tit_col4
--#DISPLAY 'Número del SRI'     TO tit_col5

END FUNCTION



FUNCTION ver_factura(i)
DEFINE i		SMALLINT

CALL fl_ver_comprobantes_emitidos_caja(rm_det[i].r38_tipo_fuente,
				rm_adi[i].j10_num_fuente, vm_tipo_doc,
				rm_det[i].r38_num_tran, rm_adi[i].j10_codcli)

END FUNCTION



FUNCTION retorna_arreglo()

--#LET vm_size_arr = fgl_scr_size('rm_det')
IF vg_gui = 0 THEN
        LET vm_size_arr = 13
END IF

END FUNCTION



FUNCTION lee_guia_remision(i)
DEFINE i		SMALLINT
DEFINE r_r95		RECORD LIKE rept095.*

INITIALIZE r_r95.* TO NULL
SELECT rept095.* INTO r_r95.*
	FROM rept097, rept095
	WHERE r97_compania       = vg_codcia
	  AND r97_localidad      = vg_codloc
	  AND r97_cod_tran       = vm_tipo_doc
	  AND r97_num_tran       = rm_det[i].r38_num_tran
	  AND r95_compania       = r97_compania
	  AND r95_localidad      = r97_localidad
	  AND r95_guia_remision  = r97_guia_remision
	  AND r95_estado        <> 'E'
RETURN r_r95.*

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
DISPLAY '<F6>      Factura'                  AT a,2
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
DISPLAY '<F5>      Factura'                  AT a,2
DISPLAY  'F5' AT a,3 ATTRIBUTE(REVERSE)
LET a = fgl_getkey()
CLOSE WINDOW w_tf

END FUNCTION
