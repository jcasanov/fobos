------------------------------------------------------------------------------
-- Titulo           : repp234.4gl - Cambio manual de precios
-- Elaboracion      : 13-Jun-2003
-- Autor            : NPC
-- Formato Ejecucion: fglrun repp234 base modulo compañía localidad
-- Ultima Correccion: 
-- Motivo Correccion: 
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE rm_orden 	ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1	SMALLINT
DEFINE vm_columna_2	SMALLINT
DEFINE vm_size_arr	INTEGER
DEFINE rm_par		RECORD
				linea		LIKE rept003.r03_codigo,
				sub_linea	LIKE rept070.r70_sub_linea,
				tit_sub_linea	LIKE rept070.r70_desc_sub,
				cod_grupo	LIKE rept071.r71_cod_grupo,
				tit_grupo	LIKE rept071.r71_desc_grupo,
				cod_clase	LIKE rept072.r72_cod_clase,
				tit_clase	LIKE rept072.r72_desc_clase,
				marca		LIKE rept073.r73_marca,
				tit_marca	LIKE rept073.r73_desc_marca 
			END RECORD
DEFINE rm_item 		ARRAY[1000] OF RECORD
				r10_codigo	LIKE rept010.r10_codigo,
				r10_nombre	LIKE rept010.r10_nombre,
				r10_precio_ant	LIKE rept010.r10_precio_ant,
				precio		DECIMAL(12,2),
				r10_cod_util	LIKE rept010.r10_cod_util,
				cod_util_nue	LIKE rept010.r10_cod_util,
				actualiza	CHAR(1)
			END RECORD
DEFINE rm_act 		ARRAY[1000] OF RECORD
				act_prec	CHAR(1),
				act_cod		CHAR(1)
			END RECORD
DEFINE vm_num_rows	INTEGER
DEFINE vm_max_rows	INTEGER
DEFINE rm_sublin	RECORD LIKE rept070.*	-- SUBLINEA DE VENTA
DEFINE rm_grupo		RECORD LIKE rept071.*	-- GRUPO DE VENTA
DEFINE rm_clase		RECORD LIKE rept072.*	-- CLASE DE VENTA



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/errores')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 THEN          -- Validar # parámetros correcto
	CALL fl_mostrar_mensaje('Número de parámetros incorrecto.','stop')
	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_codloc  = arg_val(4)
LET vg_proceso = 'repp234'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
--#CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()

END MAIN



FUNCTION funcion_master()
DEFINE r		RECORD LIKE gent000.*
DEFINE r_mon		RECORD LIKE gent013.*
DEFINE r_rep		RECORD LIKE rept000.*
DEFINE r_bod		RECORD LIKE rept002.*
DEFINE i		SMALLINT
DEFINE lin_menu		SMALLINT
DEFINE row_ini  	SMALLINT
DEFINE num_rows 	SMALLINT
DEFINE num_cols 	SMALLINT

CALL fl_nivel_isolation()                                     
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
OPEN WINDOW w_imp AT row_ini, 02 WITH num_rows ROWS, num_cols COLUMNS
	ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE lin_menu,
		  BORDER, MESSAGE LINE LAST - 1) 
IF vg_gui = 1 THEN
	OPEN FORM f_cons FROM '../forms/repf234_1'
ELSE
	OPEN FORM f_cons FROM '../forms/repf234_1c'
END IF
DISPLAY FORM f_cons
LET vm_max_rows = 1000
CALL mostrar_botones_det()
--#LET vm_size_arr = fgl_scr_size('rm_item')
IF vg_gui = 0 THEN
	LET vm_size_arr = 8
END IF
WHILE TRUE
	FOR i = 1 TO vm_size_arr 
		CLEAR rm_item[i].*
	END FOR
	CALL lee_parametros1()
	IF int_flag THEN
		RETURN
	END IF
	CALL lee_parametros2()
	IF int_flag THEN
		CONTINUE WHILE
	END IF
	CALL muestra_consulta()
	IF NOT int_flag THEN
		CALL actualiza_precio_coduti()
	END IF
	DROP TABLE temp_item
END WHILE

END FUNCTION



FUNCTION lee_parametros1()
DEFINE resp		CHAR(6)
DEFINE tit_aux		VARCHAR(30)
DEFINE num_dec		SMALLINT
DEFINE flag		CHAR(1)
DEFINE lin_aux		LIKE rept003.r03_codigo
DEFINE marca		LIKE rept010.r10_marca
DEFINE r_lin		RECORD LIKE rept003.*
DEFINE r_r73		RECORD LIKE rept073.*

IF rm_par.sub_linea IS NOT NULL THEN
	CALL fl_lee_sublinea_rep(vg_codcia, rm_par.linea, rm_par.sub_linea)
		RETURNING rm_sublin.*
	DISPLAY rm_sublin.r70_desc_sub TO tit_sub_linea
END IF
IF rm_par.cod_grupo IS NOT NULL THEN
	CALL fl_lee_grupo_rep(vg_codcia, rm_par.linea, rm_par.sub_linea,
				rm_par.cod_grupo)
		RETURNING rm_grupo.*
	DISPLAY rm_grupo.r71_desc_grupo TO tit_grupo
END IF
IF rm_par.cod_clase IS NOT NULL THEN
	CALL fl_lee_clase_rep(vg_codcia, rm_par.linea, rm_par.sub_linea,
				rm_par.cod_grupo, rm_par.cod_clase)
		RETURNING rm_clase.*
	DISPLAY rm_clase.r72_desc_clase TO tit_clase
END IF
LET int_flag = 0
INPUT BY NAME rm_par.linea, rm_par.sub_linea, rm_par.cod_grupo,
	rm_par.cod_clase, rm_par.marca
	WITHOUT DEFAULTS
        ON KEY(INTERRUPT)
		LET int_flag = 1
		--#RETURN
		EXIT INPUT
        ON KEY(F1,CONTROL-W)
		CALL llamar_visor_teclas()
	ON KEY(F2)
		IF INFIELD(linea) THEN
			CALL fl_ayuda_lineas_rep(vg_codcia)
				RETURNING lin_aux, tit_aux
       		     	LET int_flag = 0
			IF lin_aux IS NOT NULL THEN
				LET rm_par.linea = lin_aux
				DISPLAY tit_aux TO tit_division
				DISPLAY BY NAME rm_par.*
			END IF
		END IF
		IF INFIELD(sub_linea) THEN
			CALL fl_ayuda_sublinea_rep(vg_codcia, rm_par.linea)
				RETURNING rm_sublin.r70_sub_linea,
					  rm_sublin.r70_desc_sub
			LET int_flag = 0
			IF rm_sublin.r70_sub_linea IS NOT NULL THEN
				LET rm_par.sub_linea = rm_sublin.r70_sub_linea
				DISPLAY BY NAME rm_par.sub_linea
				DISPLAY rm_sublin.r70_desc_sub TO tit_sub_linea
			     END IF
			END IF
		IF INFIELD(cod_grupo) THEN
			CALL fl_ayuda_grupo_ventas_rep(vg_codcia, rm_par.linea,
							rm_par.sub_linea)
		     		RETURNING rm_grupo.r71_cod_grupo,
		     			  rm_grupo.r71_desc_grupo
			LET int_flag = 0
			IF rm_grupo.r71_cod_grupo IS NOT NULL THEN
				LET rm_par.cod_grupo = rm_grupo.r71_cod_grupo
				DISPLAY BY NAME rm_par.cod_grupo
				DISPLAY rm_grupo.r71_desc_grupo TO tit_grupo
			END IF
		END IF
		IF INFIELD(cod_clase) THEN
			CALL fl_ayuda_clase_ventas_rep(vg_codcia, rm_par.linea,
							rm_par.sub_linea,
							rm_par.cod_grupo)
				RETURNING rm_clase.r72_cod_clase,
			     		  rm_clase.r72_desc_clase
			LET int_flag = 0
			IF rm_clase.r72_cod_clase IS NOT NULL THEN
				LET rm_par.cod_clase = rm_clase.r72_cod_clase
				DISPLAY BY NAME rm_par.cod_clase
				DISPLAY rm_clase.r72_desc_clase TO tit_clase
			END IF
		END IF
		IF INFIELD(marca) THEN
			CALL fl_ayuda_marcas_rep_asignadas(vg_codcia, 
								rm_par.marca)
	  			RETURNING marca
       		     	LET int_flag = 0
			IF marca IS NOT NULL THEN
				LET rm_par.marca = marca
				CALL fl_lee_marca_rep(vg_codcia, rm_par.marca)
					RETURNING r_r73.*
				DISPLAY BY NAME rm_par.marca
				DISPLAY r_r73.r73_desc_marca TO tit_marca
	   		END IF
		END IF
	BEFORE INPUT
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
	AFTER FIELD linea
		IF rm_par.linea IS NOT NULL THEN
			CALL fl_lee_linea_rep(vg_codcia, rm_par.linea)
				RETURNING r_lin.*
			IF r_lin.r03_codigo IS NULL THEN
				CALL fl_mostrar_mensaje('División no existe.','exclamation')
				NEXT FIELD linea
			END IF
			DISPLAY r_lin.r03_nombre TO tit_division
			IF r_lin.r03_estado = 'B' THEN
				CALL fl_mensaje_estado_bloqueado()
				NEXT FIELD linea
			END IF
		ELSE
			CLEAR tit_division
		END IF
	AFTER FIELD sub_linea
		IF rm_par.sub_linea IS NOT NULL THEN
			CALL fl_retorna_sublinea_rep(vg_codcia,
						rm_par.sub_linea)
				RETURNING rm_sublin.*, flag
			IF flag = 0 THEN
				IF rm_sublin.r70_compania IS NULL THEN
					CALL fl_mostrar_mensaje('Línea no existe.','exclamation')
					NEXT FIELD sub_linea
				END IF
			END IF
			DISPLAY rm_sublin.r70_desc_sub TO tit_sub_linea
		ELSE 
		     	CLEAR tit_sub_linea
                END IF
	AFTER FIELD cod_grupo
                IF rm_par.cod_grupo IS NOT NULL THEN
			CALL fl_retorna_grupo_rep(vg_codcia,
						rm_par.cod_grupo)
				RETURNING rm_grupo.*, flag
			IF flag = 0 THEN
				IF rm_grupo.r71_compania IS NULL THEN
					CALL fl_mostrar_mensaje('Grupo no existe.','exclamation')
					NEXT FIELD cod_grupo
				END IF
			END IF
			DISPLAY rm_grupo.r71_desc_grupo TO tit_grupo
		ELSE 
		     	CLEAR tit_grupo
                END IF
	AFTER FIELD cod_clase
                IF rm_par.cod_clase IS NOT NULL THEN
			CALL fl_retorna_clase_rep(vg_codcia, rm_par.cod_clase)
				RETURNING rm_clase.*, flag
			IF flag = 0 THEN
				IF rm_clase.r72_compania IS NULL THEN
					CALL fl_mostrar_mensaje('Clase no existe.','exclamation')
					NEXT FIELD cod_clase
				END IF
			END IF
			DISPLAY rm_clase.r72_desc_clase TO tit_clase
		ELSE 
		     	CLEAR tit_clase
                END IF
	AFTER FIELD marca 
		IF rm_par.marca IS NOT NULL THEN
			CALL fl_lee_marca_rep(vg_codcia, rm_par.marca)
				RETURNING r_r73.*
			IF r_r73.r73_compania IS NULL THEN
				CALL fl_mostrar_mensaje('Marca no existe.','exclamation')
				NEXT FIELD marca
			END IF
			DISPLAY r_r73.r73_desc_marca TO tit_marca
		ELSE
			CLEAR tit_marca
		END IF
END INPUT

END FUNCTION



FUNCTION lee_parametros2()
DEFINE query		CHAR(800)
DEFINE expr_sql		CHAR(400)
DEFINE expr_lin		VARCHAR(100)
DEFINE expr_sub		VARCHAR(100)
DEFINE expr_grp		VARCHAR(100)
DEFINE expr_cla		VARCHAR(100)
DEFINE expr_marca	VARCHAR(100)
DEFINE r_r10		RECORD LIKE rept010.*
DEFINE r_r77		RECORD LIKE rept077.*

LET int_flag = 0
CONSTRUCT expr_sql ON r10_codigo, r10_nombre, r10_precio_ant, r10_precio_mb,
	r10_cod_util
	FROM r10_codigo, r10_nombre, r10_precio_ant, precio, r10_cod_util
       	ON KEY(F1,CONTROL-W)
		CALL llamar_visor_teclas()
	ON KEY(F2)
		IF INFIELD(r10_codigo) THEN
			IF rm_par.linea IS NOT NULL THEN
			     	CALL fl_ayuda_maestro_items(vg_codcia,
							    rm_par.linea)
			     		RETURNING r_r10.r10_codigo,
						  r_r10.r10_nombre
			ELSE 
			     	CALL fl_ayuda_maestro_items(vg_codcia, 'TODOS')
			     		RETURNING r_r10.r10_codigo,
						  r_r10.r10_nombre
			END IF
		     	IF r_r10.r10_codigo IS NOT NULL THEN
				DISPLAY BY NAME r_r10.r10_codigo
				DISPLAY BY NAME r_r10.r10_nombre
		     	END IF
		END IF
		IF INFIELD(r10_cod_util) THEN
			CALL fl_ayuda_factor_utilidad_rep(vg_codcia)
		     		RETURNING r_r77.r77_codigo_util
		     	IF r_r77.r77_codigo_util IS NOT NULL THEN
				DISPLAY r_r77.r77_codigo_util TO r10_cod_util
		     	END IF
		END IF
		IF INFIELD(cod_util_nue) THEN
			CALL fl_ayuda_factor_utilidad_rep(vg_codcia)
		     		RETURNING r_r77.r77_codigo_util
		     	IF r_r77.r77_codigo_util IS NOT NULL THEN
				DISPLAY r_r77.r77_codigo_util TO cod_util_nue
		     	END IF
		END IF
		LET int_flag = 0
	BEFORE CONSTRUCT
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
END CONSTRUCT
IF int_flag THEN
	RETURN
END IF
ERROR 'Generando Items para cambio precio . . . espere por favor'
	ATTRIBUTE(NORMAL)
LET expr_lin = ' '
IF rm_par.linea IS NOT NULL THEN
	LET expr_lin = " AND r10_linea = '", rm_par.linea CLIPPED, "'"
END IF
LET expr_sub = ' '
IF rm_par.sub_linea IS NOT NULL THEN
	LET expr_sub = " AND r10_sub_linea = '", rm_par.sub_linea CLIPPED, "'"
END IF
LET expr_grp = ' '
IF rm_par.cod_grupo IS NOT NULL THEN
	LET expr_grp = " AND r10_cod_grupo = '", rm_par.cod_grupo CLIPPED, "'"
END IF
LET expr_cla = ' '
IF rm_par.cod_clase IS NOT NULL THEN
	LET expr_cla = " AND r10_cod_clase = '", rm_par.cod_clase CLIPPED, "'"
END IF
LET expr_marca = ' '
IF rm_par.marca IS NOT NULL THEN
	LET expr_marca = " AND r10_marca = '", rm_par.marca CLIPPED, "'"
END IF
LET query = 'SELECT r10_codigo, r10_nombre, r10_precio_ant, r10_precio_mb, ',
		' r10_cod_util, r10_cod_util cod_util_nue, "N" actualiza, ',
		' "N" act_prec, "N" act_cod ',
	  	' FROM rept010 ',
	  	' WHERE r10_compania = ', vg_codcia,
			   expr_lin CLIPPED, 
			   expr_sub CLIPPED,  
	 	 	   expr_grp CLIPPED,  
			   expr_marca CLIPPED,  
			   expr_cla CLIPPED,
		'   AND ', expr_sql CLIPPED,
		' ORDER BY 1 ',
		' INTO TEMP temp_item '
PREPARE cit FROM query
EXECUTE cit
ERROR ' ' ATTRIBUTE(NORMAL)
SELECT COUNT(*) INTO vm_num_rows FROM temp_item
IF vm_num_rows = 0 THEN
	CALL fl_mensaje_consulta_sin_registros()
	LET int_flag = 1
	DROP TABLE temp_item
	RETURN
END IF
UPDATE temp_item SET cod_util_nue = NULL WHERE 1 = 1

END FUNCTION
 


FUNCTION muestra_consulta()
DEFINE resp		CHAR(6)
DEFINE i, j, col	SMALLINT
DEFINE query		CHAR(300)
DEFINE comando		VARCHAR(100)
DEFINE r_r10		RECORD LIKE rept010.*
DEFINE r_r48		RECORD LIKE rept048.*
DEFINE r_r72		RECORD LIKE rept072.*
DEFINE r_r77		RECORD LIKE rept077.*
DEFINE precio_aux	DECIMAL(14,2)
DEFINE run_prog		CHAR(10)

OPTIONS
	INSERT KEY F30,
	DELETE KEY F31
FOR i = 1 TO 10
	LET rm_orden[i] = '' 
END FOR
LET vm_columna_1 = 1
LET col          = 1
LET vm_columna_2 = 2
LET rm_orden[vm_columna_1] = 'DESC'
LET rm_orden[vm_columna_2] = 'ASC'
WHILE TRUE
	LET query = 'SELECT * FROM temp_item ',
			' ORDER BY ',
			vm_columna_1, ' ', rm_orden[vm_columna_1], ',', 
			vm_columna_2, ' ', rm_orden[vm_columna_2] 
	PREPARE crep FROM query
	DECLARE q_crep CURSOR FOR crep 
	LET i = 1
	FOREACH q_crep INTO rm_item[i].*, rm_act[i].*
		LET i = i + 1
		IF i > vm_max_rows THEN
			EXIT FOREACH
		END IF
	END FOREACH
	FREE q_crep
	LET vm_num_rows = i - 1
	CALL set_count(vm_num_rows)
	LET int_flag = 0
	INPUT ARRAY rm_item WITHOUT DEFAULTS FROM rm_item.*
		ON KEY(INTERRUPT)
			LET int_flag = 0
			CALL fl_mensaje_abandonar_proceso() RETURNING resp      
			IF resp = 'Yes' THEN       
				CLEAR descri_item, descri_clase
				LET int_flag = 1
				EXIT INPUT
			END IF                  
        	ON KEY(F1,CONTROL-W)
			CALL control_visor_teclas_caracter_1() 
		ON KEY(F2)
			IF INFIELD(r10_codigo) THEN
				IF rm_par.linea IS NOT NULL THEN
				     	CALL fl_ayuda_maestro_items(vg_codcia,
								   rm_par.linea)
				     		RETURNING r_r10.r10_codigo,
							  r_r10.r10_nombre
				ELSE 
				     	CALL fl_ayuda_maestro_items(vg_codcia,
									'TODOS')
				     		RETURNING r_r10.r10_codigo,
							  r_r10.r10_nombre
				END IF
			     	IF r_r10.r10_codigo IS NOT NULL THEN
					LET rm_item[i].r10_codigo =
								r_r10.r10_codigo
					LET rm_item[i].r10_nombre =
								r_r10.r10_nombre
					DISPLAY rm_item[i].r10_codigo TO
						rm_item[j].r10_codigo
					DISPLAY rm_item[i].r10_nombre TO
						rm_item[j].r10_nombre
			     	END IF
			END IF
			IF INFIELD(cod_util_nue) THEN
				CALL fl_ayuda_factor_utilidad_rep(vg_codcia)
			     		RETURNING r_r77.r77_codigo_util
			     	IF r_r77.r77_codigo_util IS NOT NULL THEN
					LET rm_item[i].cod_util_nue =
							r_r77.r77_codigo_util
					DISPLAY rm_item[i].cod_util_nue TO
						rm_item[j].cod_util_nue
					CALL check_act(i, j, 'C')
			     	END IF
			END IF
			LET int_flag = 0
		ON KEY(F5)
			LET i = arr_curr()
			LET run_prog = 'fglrun '
			IF vg_gui = 0 THEN
				LET run_prog = 'fglgo '
			END IF
			LET comando = run_prog, 'repp108 ', vg_base, ' RE ', 
			               vg_codcia, ' ', vg_codloc, ' "',
			               rm_item[i].r10_codigo CLIPPED, '"'
		       	RUN comando
		ON KEY(F15)
			LET col = 1
			LET int_flag = 2
			EXIT INPUT
		ON KEY(F16)
			LET col = 2
			LET int_flag = 2
			EXIT INPUT
		ON KEY(F17)
			LET col = 3
			LET int_flag = 2
			EXIT INPUT
		ON KEY(F18)
			LET col = 4
			LET int_flag = 2
			EXIT INPUT
		ON KEY(F19)
			LET col = 5
			LET int_flag = 2
			EXIT INPUT
		ON KEY(F20)
			LET col = 6
			LET int_flag = 2
			EXIT INPUT
		ON KEY(F21)
			LET col = 7
			LET int_flag = 2
			EXIT INPUT
		BEFORE INPUT
			CALL dialog.keysetlabel("F1","")
			CALL dialog.keysetlabel("CONTROL-W","")
			CALL dialog.keysetlabel('DELETE','')
			CALL dialog.keysetlabel('INSERT','')
		BEFORE INSERT
			LET int_flag = 2
			EXIT INPUT
		BEFORE ROW
			LET i = arr_curr()
			LET j = scr_line()
			CALL fl_lee_item(vg_codcia, rm_item[i].r10_codigo)
				RETURNING r_r10.*
			CALL fl_lee_clase_rep(vg_codcia, r_r10.r10_linea,
						r_r10.r10_sub_linea,
						r_r10.r10_cod_grupo,
						r_r10.r10_cod_clase)
				RETURNING r_r72.*
			DISPLAY '' AT 08, 65
			DISPLAY i, ' de ', vm_num_rows AT 08, 65
			DISPLAY r_r72.r72_desc_clase TO descri_clase
			DISPLAY r_r10.r10_nombre     TO descri_item
		BEFORE FIELD precio
			LET precio_aux = rm_item[i].precio
		AFTER FIELD precio
			IF rm_item[i].precio IS NOT NULL THEN
				IF rm_item[i].precio < 0 THEN
					CALL fl_mostrar_mensaje('Precio debe ser mayor a cero.','exclamation')
					NEXT FIELD precio
				END IF
				INITIALIZE r_r48.* TO NULL
				DECLARE q_comp CURSOR FOR
					SELECT * FROM rept048
						WHERE r48_compania  = vg_codcia
						  AND r48_localidad = vg_codloc
						  AND r48_item_comp =
							rm_item[i].r10_codigo
						ORDER BY r48_sec_carga DESC
				OPEN q_comp
				FETCH q_comp INTO r_r48.*
				CLOSE q_comp
				FREE q_comp
				IF r_r48.r48_compania IS NOT NULL THEN
					IF (r_r10.r10_costo_mb +
					    r_r48.r48_costo_mo) >=
					   rm_item[i].precio
					THEN
						CALL fl_mostrar_mensaje('El Precio digitado esta por debajo, del costo promedio mas la mano de obra de éste ítem.','exclamation')
						NEXT FIELD precio
					END IF
				END IF
				IF precio_aux <> rm_item[i].precio THEN
					CALL check_act(i, j, 'P')
				END IF
			END IF
		AFTER FIELD cod_util_nue
			IF rm_item[i].cod_util_nue IS NOT NULL THEN
				CALL fl_lee_factor_utilidad_rep(vg_codcia,
							rm_item[i].cod_util_nue)
					RETURNING r_r77.*
				IF r_r77.r77_codigo_util IS NULL THEN
					CALL fl_mostrar_mensaje('El Factor de Utilidad no existe en esta Compañía.','exclamation')
					NEXT FIELD cod_util_nue
	               		END IF
			END IF
			CALL check_act(i, j, 'C')
	END INPUT
	IF int_flag <> 2 THEN
		EXIT WHILE
	END IF
	IF col <> vm_columna_1 THEN
		LET vm_columna_2           = vm_columna_1 
		LET rm_orden[vm_columna_2] = rm_orden[vm_columna_1]
		LET vm_columna_1 = col 
	END IF
	IF rm_orden[vm_columna_1] = 'ASC' THEN
		LET rm_orden[vm_columna_1] = 'DESC'
	ELSE
		LET rm_orden[vm_columna_1] = 'ASC'
	END IF
END WHILE
CLEAR descri_item, descri_clase
DISPLAY '' AT 08, 65

END FUNCTION



FUNCTION actualiza_precio_coduti()
DEFINE r_r10		RECORD LIKE rept010.*
DEFINE i, j, l		SMALLINT
DEFINE mensaje		VARCHAR(100)
DEFINE resp		CHAR(6)
DEFINE fecha_actual DATETIME YEAR TO SECOND

LET j = 0
LET l = 0
BEGIN WORK
FOR i = 1 TO vm_num_rows
	IF rm_item[i].actualiza = 'N' THEN
		CONTINUE FOR
	END IF
	WHILE TRUE
		WHENEVER ERROR CONTINUE
		DECLARE q_r10 CURSOR FOR
			SELECT * FROM rept010
				WHERE r10_compania = vg_codcia
				  AND r10_codigo   = rm_item[i].r10_codigo
			FOR UPDATE
		OPEN q_r10
		FETCH q_r10 INTO r_r10.*
		IF STATUS < 0 THEN
			CLOSE q_r10
			FREE q_r10
			WHENEVER ERROR STOP
			LET mensaje = 'El Item ', rm_item[i].r10_codigo CLIPPED,
				' esta bloqueado por otro proceso. Desea intentar nuevamente hasta que se desbloquee ?'
			CALL fl_hacer_pregunta(mensaje, 'No') RETURNING resp
			IF resp = 'Yes' THEN
				CONTINUE WHILE
			END IF
 			LET mensaje = 'No se actualizaran cambios en el Item ',
					rm_item[i].r10_codigo CLIPPED, '.'
			CALL fl_mostrar_mensaje(mensaje, 'exclamation')
			CONTINUE FOR
		ELSE
			EXIT WHILE
		END IF
	END WHILE
	WHENEVER ERROR STOP
	IF rm_act[i].act_prec = 'S' THEN
		LET fecha_actual = fl_current()
		CALL usuario_camprec(i)
		UPDATE rept010
			SET r10_precio_ant  = r10_precio_mb,
			    r10_precio_mb   = rm_item[i].precio,
			    r10_fec_camprec = fecha_actual	-- NO TENIA EL PROG.
			WHERE CURRENT OF q_r10
		LET j = j + 1
	END IF
	IF rm_act[i].act_cod = 'S' THEN
		UPDATE rept010 SET r10_cod_util = rm_item[i].cod_util_nue
			WHERE CURRENT OF q_r10
		LET l = l + 1
	END IF
	CLOSE q_r10
	FREE q_r10
END FOR
COMMIT WORK
IF j > 0 OR l > 0 THEN
	LET mensaje = 'Se actualizaron precios de ', j USING "<<<&", ' Items',
			' y ', l USING "<<<&", ' Items con codigos de utilidad.'
ELSE
	LET mensaje = 'No se actualizaron precios y codigos de utilidad en nigun Item.'
END IF
CALL fl_mostrar_mensaje(mensaje, 'info')

END FUNCTION



FUNCTION check_act(i, j, flag)
DEFINE i, j		SMALLINT
DEFINE flag		CHAR(1)

LET rm_item[i].actualiza = 'S'
CASE flag
	WHEN 'P'
		LET rm_act[i].act_prec = 'S'
		UPDATE temp_item
			SET r10_precio_mb = rm_item[i].precio,
			    actualiza     = rm_item[i].actualiza,
			    act_prec      = rm_act[i].act_prec
			WHERE r10_codigo = rm_item[i].r10_codigo
	WHEN 'C'
		IF rm_item[i].cod_util_nue IS NOT NULL THEN
			LET rm_act[i].act_cod = 'S'
		ELSE
			LET rm_act[i].act_cod = 'N'
		END IF
		UPDATE temp_item
			SET cod_util_nue  = rm_item[i].cod_util_nue,
			    actualiza     = rm_item[i].actualiza,
			    act_cod       = rm_act[i].act_cod
			WHERE r10_codigo = rm_item[i].r10_codigo
END CASE
DISPLAY rm_item[i].actualiza TO rm_item[j].actualiza

END FUNCTION



FUNCTION mostrar_botones_det()

--#DISPLAY 'Item'         TO tit_col1
--#DISPLAY 'Descripción'  TO tit_col2
--#DISPLAY 'PVP Anterior' TO tit_col3
--#DISPLAY 'PVP Nuevo'    TO tit_col4
--#DISPLAY 'CU A.'        TO tit_col5
--#DISPLAY 'CU N.'        TO tit_col6
--#DISPLAY 'C'            TO tit_col7

END FUNCTION



FUNCTION usuario_camprec(i)
DEFINE i		SMALLINT
DEFINE r_r10		RECORD LIKE rept010.*
DEFINE r_r87		RECORD LIKE rept087.*

INITIALIZE r_r87.* TO NULL
CALL fl_lee_item(vg_codcia, rm_item[i].r10_codigo) RETURNING r_r10.*
LET r_r87.r87_compania    = vg_codcia
LET r_r87.r87_localidad   = vg_codloc
LET r_r87.r87_item        = rm_item[i].r10_codigo
SELECT NVL(MAX(r87_secuencia), 0) + 1 INTO r_r87.r87_secuencia
	FROM rept087
	WHERE r87_compania = r_r87.r87_compania
	  AND r87_item     = r_r87.r87_item
LET r_r87.r87_precio_act  = rm_item[i].precio
LET r_r87.r87_precio_ant  = r_r10.r10_precio_mb
LET r_r87.r87_usu_camprec = vg_usuario
LET r_r87.r87_fec_camprec = fl_current()
INSERT INTO rept087 VALUES (r_r87.*)

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
DISPLAY '<F5>      Ver Item'                 AT a,2
DISPLAY  'F5' AT a,3 ATTRIBUTE(REVERSE)
LET a = fgl_getkey()
CLOSE WINDOW w_tf

END FUNCTION
