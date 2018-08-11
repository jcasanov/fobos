------------------------------------------------------------------------------
-- Titulo           : cxcp210.4gl - Modificación del No. SRI en Notas Credito
-- Elaboracion      : 14-Ene-2003
-- Autor            : NPC
-- Formato Ejecucion: fglrun cxcp210 base módulo compañía localidad
-- Ultima Correccion: 
-- Motivo Correccion: 
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_demonios	VARCHAR(12)
DEFINE vm_nuevoprog     CHAR(400)
DEFINE vm_max_det       SMALLINT
DEFINE vm_num_det       SMALLINT
DEFINE vm_fecha_ini	DATE
DEFINE vm_fecha_fin	DATE
DEFINE rm_orden 	ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1	SMALLINT
DEFINE vm_columna_2	SMALLINT
DEFINE vm_size_arr	INTEGER
DEFINE rm_det		ARRAY [500] OF RECORD
				z21_tipo_doc	LIKE cxct021.z21_tipo_doc,
				z21_num_doc	LIKE cxct021.z21_num_doc,
				z01_nomcli	LIKE cxct001.z01_nomcli,
				z21_fecing	DATE,
				z21_num_sri	LIKE cxct021.z21_num_sri
			END RECORD
DEFINE rm_cliente	ARRAY [500] OF LIKE cxct021.z21_codcli

MAIN

DEFER QUIT 
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/errores')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 THEN   -- Validar # parámetros correcto
	--CALL fgl_winmessage(vg_producto,'Número de parámetros incorrecto.', 'stop')
	CALL fl_mostrar_mensaje('Número de parámetros incorrecto.','stop')
	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_codloc  = arg_val(4)
LET vg_proceso = 'cxcp210'
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
CREATE TEMP TABLE tmp_sri(
		z21_tipo_doc		CHAR(2),
		z21_num_doc		INTEGER,
		z01_nomcli		VARCHAR(50),
		z21_fecing		DATE,
		z21_num_sri		CHAR(16),
		z21_codcli		INTEGER
	)
LET vm_max_det = 500
LET lin_menu = 0
LET row_ini  = 3
LET num_rows = 22
LET num_cols = 80
IF vg_gui = 0 THEN
	LET lin_menu = 1
	LET row_ini  = 4
	LET num_rows = 20
	LET num_cols = 78
END IF
OPEN WINDOW w_mas AT row_ini, 2 WITH num_rows ROWS, num_cols COLUMNS
    ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE lin_menu,BORDER,
	      MESSAGE LINE LAST - 1)
IF vg_gui = 1 THEN
        OPEN FORM f_cxc FROM '../forms/cxcf210_1'
ELSE
        OPEN FORM f_cxc FROM '../forms/cxcf210_1c'
END IF
DISPLAY FORM f_cxc
CALL muestra_contadores_det(0)
CALL borrar_cabecera()
CALL borrar_detalle()
CALL mostrar_cabecera_forma()
CALL control_consulta()

END FUNCTION



FUNCTION control_consulta()
DEFINE i,j,col		SMALLINT
DEFINE query		CHAR(1000)
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
		'SELECT z21_tipo_doc, z21_num_doc, z01_nomcli, ',
			'DATE(z21_fecing), z21_num_sri, z21_codcli ',
		'FROM cxct021, cxct001 ',
		'WHERE z21_compania    = ', vg_codcia,
		'  AND z21_localidad   = ', vg_codloc,
		'  AND z21_tipo_doc    = "NC"',
		'  AND DATE(z21_fecing) BETWEEN "', vm_fecha_ini, '"',
					'   AND "', vm_fecha_fin, '"',
		'  AND ', expr_sql CLIPPED, 
		'  AND z21_codcli      = z01_codcli '
	PREPARE deto FROM query
	--DECLARE q_deto CURSOR FOR deto
	EXECUTE deto
	WHILE TRUE
		LET query = 'SELECT * FROM tmp_sri ',
			" ORDER BY ", vm_columna_1, ' ', rm_orden[vm_columna_1],
		    	   	', ', vm_columna_2, ' ', rm_orden[vm_columna_2]
		PREPARE deto2 FROM query
		DECLARE q_deto2 CURSOR FOR deto2
		LET vm_num_det = 1
		FOREACH q_deto2 INTO rm_det[vm_num_det].*,rm_cliente[vm_num_det]
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
				CALL ver_documento(i)
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

OPTIONS INPUT NO WRAP
INITIALIZE expr_sql, nulo TO NULL
LET int_flag = 0
INPUT BY NAME vm_fecha_ini, vm_fecha_fin
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		LET int_flag = 1
		--RETURN NULL
		RETURN nulo
        ON KEY(F1,CONTROL-W)
		CALL llamar_visor_teclas()
	BEFORE INPUT
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
	BEFORE FIELD vm_fecha_ini
		LET fecha_ini = TODAY
	BEFORE FIELD vm_fecha_fin
		LET fecha_fin = vm_fecha_fin
	AFTER FIELD vm_fecha_ini 
		IF vm_fecha_ini IS NOT NULL THEN
			IF vm_fecha_ini > TODAY THEN
				--CALL fgl_winmessage(vg_producto,'La fecha de inicio no puede ser mayor a la de hoy.','exclamation')
				CALL fl_mostrar_mensaje('La Fecha Inicial no puede ser mayor a la de hoy.','exclamation')
				NEXT FIELD vm_fecha_ini
			END IF
			IF MONTH(fecha_ini) = 1 THEN
				LET fecha_ini_aux = MDY(12, DAY(fecha_ini),
							YEAR(fecha_ini) - 1)
			ELSE
				LET dia = DAY(fecha_ini)
				IF MONTH(fecha_ini) = 3 THEN
					IF (YEAR(fecha_ini) MOD 4) <> 0 THEN
						LET dia = 28
					ELSE
						LET dia = 29
					END IF
				END IF
				LET fecha_ini_aux = MDY(MONTH(fecha_ini) - 1,
							dia, YEAR(fecha_ini))
			END IF	
			IF vm_fecha_ini < fecha_ini_aux THEN
				CALL fl_mostrar_mensaje('La Fecha Inicial no puede ser menor a 30 días.','exclamation')
				NEXT FIELD vm_fecha_ini
			END IF
		ELSE
			LET vm_fecha_ini = fecha_ini
			DISPLAY BY NAME vm_fecha_ini
		END IF
	AFTER FIELD vm_fecha_fin 
		IF vm_fecha_fin IS NOT NULL THEN
			IF vm_fecha_fin > TODAY THEN
				--CALL fgl_winmessage(vg_producto,'La fecha de término no puede ser mayor a la de hoy.','exclamation')
				CALL fl_mostrar_mensaje('La Fecha Final no puede ser mayor a la de hoy.','exclamation')
				NEXT FIELD vm_fecha_fin
			END IF
		ELSE
			LET vm_fecha_fin = fecha_fin
			DISPLAY BY NAME vm_fecha_fin
		END IF
	AFTER INPUT
		IF vm_fecha_ini > vm_fecha_fin THEN
			--CALL fgl_winmessage(vg_producto,'Fecha Inicial debe ser menor a fecha final.','exclamation')
			CALL fl_mostrar_mensaje('Fecha Inicial debe ser menor a la Fecha Final.','exclamation')
			NEXT FIELD vm_fecha_ini
		END IF
END INPUT
OPTIONS INPUT WRAP
CONSTRUCT BY NAME expr_sql ON z01_nomcli, z21_num_sri
	ON KEY(INTERRUPT)
		LET int_flag = 2
		--RETURN NULL
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
DEFINE aux_sri		LIKE cxct021.z21_num_sri
DEFINE r_z21		RECORD LIKE cxct021.*
DEFINE r_g37		RECORD LIKE gent037.*
DEFINE sec_sri		LIKE gent037.g37_sec_num_sri
DEFINE resul		SMALLINT
DEFINE cuantos		SMALLINT

BEGIN WORK
	WHENEVER ERROR STOP
	DECLARE q_modsri2 CURSOR FOR
		SELECT * FROM cxct021
			WHERE z21_compania  = vg_codcia
			  AND z21_localidad = vg_codloc
			  AND z21_codcli    = rm_cliente[i]
			  AND z21_tipo_doc  = rm_det[i].z21_tipo_doc
			  AND z21_num_doc   = rm_det[i].z21_num_doc
		FOR UPDATE
	WHENEVER ERROR CONTINUE
	OPEN q_modsri2
	FETCH q_modsri2 INTO r_z21.*
	IF STATUS < 0 THEN
		ROLLBACK WORK
		CALL fl_mostrar_mensaje('Lo siento ahora no puede modificar este No. del SRI, lo tiene bloqueado otro usuario.','exclamation')
		WHENEVER ERROR STOP
		RETURN
	END IF
	DECLARE q_sri CURSOR FOR
		SELECT * FROM gent037
			WHERE g37_compania  = vg_codcia
			  AND g37_localidad = vg_codloc
			  AND g37_tipo_doc  = rm_det[i].z21_tipo_doc
			  AND g37_cont_cred =  'N'
		  	  AND g37_fecha_emi <= DATE(TODAY)
		  	  AND g37_fecha_exp >= DATE(TODAY)
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
	OPTIONS INPUT WRAP
	LET int_flag = 0
	INPUT rm_det[i].z21_num_sri WITHOUT DEFAULTS FROM rm_det[j].z21_num_sri
		ON KEY(INTERRUPT)
			LET rm_det[i].z21_num_sri = aux_sri
			DISPLAY rm_det[i].z21_num_sri TO rm_det[j].z21_num_sri
			LET int_flag = 1
			--#ROLLBACK WORK
			--#RETURN
			EXIT INPUT
	        ON KEY(F1,CONTROL-W)
			CALL control_visor_teclas_caracter_2() 
		ON KEY(F5)
			CALL ver_documento(i)
			LET int_flag = 0
		BEFORE INPUT
			--#CALL dialog.keysetlabel("F1","")
			--#CALL dialog.keysetlabel("CONTROL-W","")
			--#CALL dialog.keysetlabel("F5","Documento")
			LET aux_sri = rm_det[i].z21_num_sri
			CALL validar_num_sri(aux_sri, i, j)
				RETURNING r_g37.*, resul
			CASE resul
				WHEN -1
					ROLLBACK WORK
					EXIT PROGRAM
				WHEN 0
					NEXT FIELD z21_num_sri
			END CASE
		AFTER FIELD z21_num_sri
			IF rm_det[i].z21_num_sri IS NOT NULL THEN
				CALL validar_num_sri(aux_sri, i, j)
					RETURNING r_g37.*, resul
				CASE resul
					WHEN -1
						ROLLBACK WORK
						EXIT PROGRAM
					WHEN 0
						NEXT FIELD z21_num_sri
				END CASE
			ELSE
				LET rm_det[i].z21_num_sri = aux_sri
				DISPLAY rm_det[i].z21_num_sri TO
					rm_det[j].z21_num_sri
			END IF
		AFTER INPUT
			IF rm_det[i].z21_num_sri IS NOT NULL THEN
				CALL validar_num_sri(aux_sri, i, j)
					RETURNING r_g37.*, resul
				CASE resul
					WHEN -1
						ROLLBACK WORK
						EXIT PROGRAM
					WHEN 0
						NEXT FIELD z21_num_sri
				END CASE
			END IF
	END INPUT
	IF int_flag THEN
		ROLLBACK WORK
		RETURN
	END IF
	LET cuantos = 8 + r_g37.g37_num_dig_sri
	LET sec_sri = rm_det[i].z21_num_sri[9, cuantos] USING "########"
	UPDATE gent037 SET g37_sec_num_sri = sec_sri
		WHERE g37_compania    = r_g37.g37_compania
		  AND g37_localidad   = r_g37.g37_localidad
		  AND g37_tipo_doc    = r_g37.g37_tipo_doc
		  AND g37_secuencia   = r_g37.g37_secuencia
		  AND g37_sec_num_sri < sec_sri
	UPDATE cxct021 SET z21_num_sri = rm_det[i].z21_num_sri
		WHERE CURRENT OF q_modsri2
	UPDATE tmp_sri SET z21_num_sri = rm_det[i].z21_num_sri
		WHERE z21_codcli   = rm_cliente[i]
		  AND z21_tipo_doc = rm_det[i].z21_tipo_doc
		  AND z21_num_doc  = rm_det[i].z21_num_doc
COMMIT WORK
CALL fl_mensaje_registro_modificado()

END FUNCTION



FUNCTION validar_num_sri(aux_sri, i, j)
DEFINE aux_sri		LIKE cxct021.z21_num_sri
DEFINE i, j		SMALLINT
DEFINE r_g37		RECORD LIKE gent037.*
DEFINE cont		INTEGER
DEFINE flag		SMALLINT

CALL fl_validacion_num_sri(vg_codcia, vg_codloc, rm_det[i].z21_tipo_doc, 'N', 
				rm_det[i].z21_num_sri)
	RETURNING r_g37.*, rm_det[i].z21_num_sri, flag
CASE flag
	WHEN -1
		RETURN r_g37.*, -1
	WHEN 0
		RETURN r_g37.*, 0
END CASE
DISPLAY rm_det[i].z21_num_sri TO rm_det[j].z21_num_sri
{--
IF LENGTH(rm_det[i].z21_num_sri) < 15 THEN
	CALL fl_mostrar_mensaje('Digite completo el número del SRI.','exclamation')
	RETURN r_g37.*, 0
END IF
--}
IF aux_sri <> rm_det[i].z21_num_sri THEN
	SELECT COUNT(*) INTO cont FROM cxct021
		WHERE z21_compania  = vg_codcia
		  AND z21_localidad = vg_codloc
  		  AND z21_num_sri   = rm_det[i].z21_num_sri
	IF cont > 0 THEN
		CALL fl_mostrar_mensaje('La secuencia del SRI ' || rm_det[i].z21_num_sri[9,15] || ' ya existe.','exclamation')
		RETURN r_g37.*, 0
	END IF
END IF
RETURN r_g37.*, 1

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
--#DISPLAY 'No. Documento'      TO tit_col2
--#DISPLAY 'Nombre del Cliente' TO tit_col3
--#DISPLAY 'Fecha'              TO tit_col4
--#DISPLAY 'Número del SRI'     TO tit_col5

END FUNCTION



FUNCTION ver_documento(i)
DEFINE i		SMALLINT
DEFINE run_prog		CHAR(10)

{-- ESTO PARA LLAMAR AL PROGRAMA SEGÚN SEA EL AMBIENTE --}
LET run_prog = '; fglrun '
IF vg_gui = 0 THEN
	LET run_prog = '; fglgo '
END IF
{--- ---}
LET vm_nuevoprog = 'cd ..', vg_separador, '..', vg_separador, 'COBRANZAS',
	vg_separador, 'fuentes', vg_separador, run_prog, 'cxcp201 ', vg_base,
	' ', 'CO', ' ', vg_codcia, ' ', vg_codloc, ' ',
	rm_cliente[i], ' "', rm_det[i].z21_tipo_doc, '" ',
	rm_det[i].z21_num_doc
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
DISPLAY '<F6>      Documento'                AT a,2
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
DISPLAY '<F5>      Documento'                AT a,2
DISPLAY  'F5' AT a,3 ATTRIBUTE(REVERSE)
LET a = fgl_getkey()
CLOSE WINDOW w_tf

END FUNCTION
