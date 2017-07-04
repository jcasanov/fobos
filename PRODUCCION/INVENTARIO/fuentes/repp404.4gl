------------------------------------------------------------------------------
-- Titulo           : repp404.4gl - Reporte de lista de precios
-- Elaboracion      : 21-dic-2001
-- Autor            : NPC
-- Formato Ejecucion: fglrun repp404 base módulo compañía localidad
-- Ultima Correccion: 18-Mar-2003 
-- Motivo Correccion: Rediseno de la lista de precios
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE rm_r10		RECORD LIKE rept010.*
DEFINE rm_r11		RECORD LIKE rept011.*
DEFINE rm_r10_2		RECORD
				r10_linea2	LIKE rept010.r10_linea,
				r10_sub_linea2	LIKE rept010.r10_sub_linea,
				r10_cod_grupo2	LIKE rept010.r10_cod_grupo,
				r10_cod_clase2	LIKE rept010.r10_cod_clase,
				r10_marca2	LIKE rept010.r10_marca
			END RECORD
DEFINE rm_g02		RECORD LIKE gent002.*
DEFINE vm_moneda	LIKE gent000.g00_moneda_base
DEFINE vm_expr_sublinea	VARCHAR(100)
DEFINE vm_expr_grupo	VARCHAR(100)
DEFINE vm_expr_clase	VARCHAR(100)
DEFINE vm_expr_marca	VARCHAR(100)



MAIN

DEFER QUIT 
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/errores')
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
LET vg_proceso = 'repp404'
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
LET lin_menu = 0
LET row_ini  = 3
LET num_rows = 17
LET num_cols = 80
IF vg_gui = 0 THEN
	LET lin_menu = 1
	LET row_ini  = 4
	LET num_rows = 20
	LET num_cols = 78
END IF
OPEN WINDOW w_mas AT row_ini, 2 WITH num_rows ROWS, num_cols COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE lin_menu,
		  MESSAGE LINE LAST - 1, BORDER) 
IF vg_gui = 1 THEN
	OPEN FORM f_rep FROM "../forms/repf404_1"
ELSE
	OPEN FORM f_rep FROM "../forms/repf404_1c"
END IF
DISPLAY FORM f_rep
CALL borrar_cabecera()
CALL control_reporte()

END FUNCTION



FUNCTION control_reporte()
DEFINE query		CHAR(1000)
DEFINE expr_sql         CHAR(100)
DEFINE sec		LIKE rept010.r10_sec_item
DEFINE r_rep		RECORD
				linea		LIKE rept010.r10_linea,
				sublinea	LIKE rept010.r10_sub_linea,
				grupo		LIKE rept010.r10_cod_grupo,
				clase		LIKE rept010.r10_cod_clase,
				codigo		LIKE rept010.r10_codigo,
				marca		LIKE rept010.r10_marca,
				nombre		LIKE rept010.r10_nombre,
				unidad		LIKE rept010.r10_uni_med,
				precio		LIKE rept010.r10_precio_mb
			END RECORD
DEFINE comando		VARCHAR(100)

CALL fl_lee_localidad(vg_codcia, vg_codloc) RETURNING rm_g02.*
IF rm_g02.g02_compania IS NULL THEN
	CALL fl_mostrar_mensaje('No existe localidad.','stop')
	EXIT PROGRAM
END IF
LET vm_moneda = rg_gen.g00_moneda_base
IF rg_gen.g00_moneda_alt IS NOT NULL THEN
	LET vm_moneda = rg_gen.g00_moneda_alt
END IF
WHILE TRUE
	CALL lee_parametros() RETURNING expr_sql
	IF int_flag THEN
		EXIT WHILE
	END IF
	CALL fl_control_reportes() RETURNING comando
	IF int_flag THEN
		CONTINUE WHILE
	END IF
	LET query = 'SELECT r10_sec_item, r10_linea, r10_sub_linea, ',
			' r10_cod_grupo, r10_cod_clase, r10_codigo, r10_marca,',
			' r10_nombre, r10_uni_med, ', expr_sql CLIPPED, ' ',
			'FROM rept010 ', 
			'WHERE r10_compania = ', vg_codcia,
			'  AND r10_linea BETWEEN "', rm_r10.r10_linea CLIPPED,
			'" AND "', rm_r10_2.r10_linea2 CLIPPED, '"',
			vm_expr_sublinea CLIPPED,
			vm_expr_grupo CLIPPED,
			vm_expr_clase CLIPPED,
			vm_expr_marca CLIPPED,
			' ORDER BY 2, 3, 4, 5, 7, 1'
	PREPARE deto FROM query
	DECLARE q_deto CURSOR FOR deto
	OPEN q_deto
	FETCH q_deto
	IF STATUS = NOTFOUND THEN
		CLOSE q_deto
		FREE q_deto
		CALL fl_mensaje_consulta_sin_registros()
		CONTINUE WHILE
	END IF
	CLOSE q_deto
	START REPORT rep_precios TO PIPE comando
	FOREACH q_deto INTO sec, r_rep.*
		OUTPUT TO REPORT rep_precios(r_rep.*)
	END FOREACH
	FINISH REPORT rep_precios
END WHILE

END FUNCTION



FUNCTION lee_parametros()
DEFINE resul		SMALLINT
DEFINE expr_sql		VARCHAR(100)

LET expr_sql = NULL
LET int_flag = 0
INPUT BY NAME rm_r10.r10_linea, rm_r10_2.r10_linea2, rm_r10.r10_sub_linea,
	rm_r10_2.r10_sub_linea2, rm_r10.r10_cod_grupo, rm_r10_2.r10_cod_grupo2,
	rm_r10.r10_cod_clase, rm_r10_2.r10_cod_clase2, rm_r10.r10_marca,
	rm_r10_2.r10_marca2
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		LET int_flag = 1
		RETURN expr_sql
        ON KEY(F1,CONTROL-W)
		CALL llamar_visor_teclas()
	ON KEY(F2)
		IF INFIELD(r10_linea) THEN
			CALL ayuda_lineas(1)
       		      	LET int_flag = 0
                END IF
		IF INFIELD(r10_linea2) THEN
			CALL ayuda_lineas(2)
       		      	LET int_flag = 0
                END IF
		IF INFIELD(r10_sub_linea) THEN
			CALL ayuda_sublineas(rm_r10.r10_linea, 1)
       		      	LET int_flag = 0
		END IF
		IF INFIELD(r10_sub_linea2) THEN
			CALL ayuda_sublineas(rm_r10_2.r10_linea2, 2)
       		      	LET int_flag = 0
		END IF
		IF INFIELD(r10_cod_grupo) THEN
			CALL ayuda_grupos(rm_r10.r10_linea,
					  rm_r10.r10_sub_linea, 1)
       		      	LET int_flag = 0
		END IF
		IF INFIELD(r10_cod_grupo2) THEN
			CALL ayuda_grupos(rm_r10_2.r10_linea2,
					  rm_r10_2.r10_sub_linea2, 2)
       		      	LET int_flag = 0
		END IF
		IF INFIELD(r10_cod_clase) THEN
			CALL ayuda_clases(rm_r10.r10_linea,
					  rm_r10.r10_sub_linea,
					  rm_r10.r10_cod_grupo, 1)
       		      	LET int_flag = 0
		END IF
		IF INFIELD(r10_cod_clase2) THEN
			CALL ayuda_clases(rm_r10_2.r10_linea2,
					  rm_r10_2.r10_sub_linea2,
					  rm_r10_2.r10_cod_grupo2, 2)
       		      	LET int_flag = 0
		END IF
		IF INFIELD(r10_marca) THEN
			CALL ayuda_marcas(rm_r10.r10_cod_clase, 1)
       		      	LET int_flag = 0
		END IF
		IF INFIELD(r10_marca2) THEN
			CALL ayuda_marcas(rm_r10_2.r10_cod_clase2, 2)
       		      	LET int_flag = 0
		END IF
	BEFORE INPUT
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
	AFTER FIELD r10_linea
               	IF rm_r10.r10_linea IS NOT NULL THEN
			CALL validar_lineas(rm_r10.r10_linea, 1) RETURNING resul
			IF resul = 1 THEN
                               	NEXT FIELD r10_linea
			END IF
			IF rm_r10_2.r10_linea2 IS NULL THEN
				LET rm_r10_2.r10_linea2 = rm_r10.r10_linea
				CALL validar_lineas(rm_r10_2.r10_linea2, 2)
					RETURNING resul
			END IF
			IF rm_r10.r10_linea > rm_r10_2.r10_linea2 THEN
				CALL fl_mostrar_mensaje('La división inicial debe ser menor igual a la división final.','exclamation')
				NEXT FIELD r10_linea
			END IF
		ELSE
			CLEAR tit_linea
                END IF
	AFTER FIELD r10_linea2
               	IF rm_r10_2.r10_linea2 IS NOT NULL THEN
			CALL validar_lineas(rm_r10_2.r10_linea2, 2)
				RETURNING resul
			IF resul = 1 THEN
                               	NEXT FIELD r10_linea2
			END IF
			IF rm_r10.r10_linea IS NULL THEN
				LET rm_r10.r10_linea = rm_r10_2.r10_linea2
				CALL validar_lineas(rm_r10.r10_linea, 1)
					RETURNING resul
			END IF
			IF rm_r10_2.r10_linea2 < rm_r10.r10_linea THEN
				CALL fl_mostrar_mensaje('La división final debe ser mayor igual a la división inicial.','exclamation')
				NEXT FIELD r10_linea2
			END IF
		ELSE
			CLEAR tit_linea2
                END IF
	AFTER FIELD r10_sub_linea
		IF rm_r10.r10_sub_linea IS NOT NULL THEN
			CALL validar_sublineas(rm_r10.r10_sub_linea, 1)
				RETURNING resul
			IF resul = 1 THEN
                               	NEXT FIELD r10_sub_linea
			END IF
			IF rm_r10_2.r10_sub_linea2 IS NULL THEN
				LET rm_r10_2.r10_sub_linea2 =
							rm_r10.r10_sub_linea
				CALL validar_sublineas(rm_r10_2.r10_sub_linea2,
							2)
					RETURNING resul
			END IF
			IF rm_r10.r10_sub_linea > rm_r10_2.r10_sub_linea2 THEN
				CALL fl_mostrar_mensaje('La línea inicial debe ser menor igual a la línea final.','exclamation')
				NEXT FIELD r10_sub_linea
			END IF
		ELSE 
			CLEAR tit_sub_linea
                END IF
	AFTER FIELD r10_sub_linea2
		IF rm_r10_2.r10_sub_linea2 IS NOT NULL THEN
			CALL validar_sublineas(rm_r10_2.r10_sub_linea2, 2)
				RETURNING resul
			IF resul = 1 THEN
                               	NEXT FIELD r10_sub_linea2
			END IF
			IF rm_r10.r10_sub_linea IS NULL THEN
				LET rm_r10.r10_sub_linea =
							rm_r10_2.r10_sub_linea2
				CALL validar_sublineas(rm_r10.r10_sub_linea, 1)
					RETURNING resul
			END IF
			IF rm_r10_2.r10_sub_linea2 < rm_r10.r10_sub_linea THEN
				CALL fl_mostrar_mensaje('La línea final debe ser mayor igual a la línea inicial.','exclamation')
				NEXT FIELD r10_sub_linea2
			END IF
		ELSE 
			CLEAR tit_sub_linea2
                END IF
	AFTER FIELD r10_cod_grupo
		IF rm_r10.r10_cod_grupo IS NOT NULL THEN
			CALL validar_grupos(rm_r10.r10_cod_grupo, 1)
				RETURNING resul
			IF resul = 1 THEN
                               	NEXT FIELD r10_cod_grupo
			END IF
			IF rm_r10_2.r10_cod_grupo2 IS NULL THEN
				LET rm_r10_2.r10_cod_grupo2 =
							rm_r10.r10_cod_grupo
				CALL validar_grupos(rm_r10_2.r10_cod_grupo2, 2)
					RETURNING resul
			END IF
			IF rm_r10.r10_cod_grupo > rm_r10_2.r10_cod_grupo2 THEN
				CALL fl_mostrar_mensaje('El grupo inicial debe ser menor igual al grupo final.','exclamation')
				NEXT FIELD r10_cod_grupo
			END IF
		ELSE 
			CLEAR tit_grupo
		END IF
	AFTER FIELD r10_cod_grupo2
		IF rm_r10_2.r10_cod_grupo2 IS NOT NULL THEN
			CALL validar_grupos(rm_r10_2.r10_cod_grupo2, 2)
				RETURNING resul
			IF resul = 1 THEN
                               	NEXT FIELD r10_cod_grupo2
			END IF
			IF rm_r10.r10_cod_grupo IS NULL THEN
				LET rm_r10.r10_cod_grupo =
							rm_r10_2.r10_cod_grupo2
				CALL validar_grupos(rm_r10.r10_cod_grupo, 1)
					RETURNING resul
			END IF
			IF rm_r10_2.r10_cod_grupo2 < rm_r10.r10_cod_grupo THEN
				CALL fl_mostrar_mensaje('El grupo final debe ser mayor igual al grupo inicial.','exclamation')
				NEXT FIELD r10_cod_grupo2
			END IF
		ELSE 
			CLEAR tit_grupo2
		END IF
	AFTER FIELD r10_cod_clase
		IF rm_r10.r10_cod_clase IS NOT NULL THEN
			CALL validar_clases(rm_r10.r10_cod_clase, 1)
				RETURNING resul
			IF resul = 1 THEN
                               	NEXT FIELD r10_cod_clase
			END IF
			IF rm_r10_2.r10_cod_clase2 IS NULL THEN
				LET rm_r10_2.r10_cod_clase2 =
							rm_r10.r10_cod_clase
				CALL validar_clases(rm_r10_2.r10_cod_clase2, 2)
					RETURNING resul
			END IF
			IF rm_r10.r10_cod_clase > rm_r10_2.r10_cod_clase2 THEN
				CALL fl_mostrar_mensaje('La clase inicial debe ser menor igual a la clase final.','exclamation')
				NEXT FIELD r10_cod_clase
			END IF
		ELSE 
			CLEAR tit_clase
		END IF
	AFTER FIELD r10_cod_clase2
		IF rm_r10_2.r10_cod_clase2 IS NOT NULL THEN
			CALL validar_clases(rm_r10_2.r10_cod_clase2, 2)
				RETURNING resul
			IF resul = 1 THEN
                               	NEXT FIELD r10_cod_clase2
			END IF
			IF rm_r10.r10_cod_clase IS NULL THEN
				LET rm_r10.r10_cod_clase =
							rm_r10_2.r10_cod_clase2
				CALL validar_clases(rm_r10.r10_cod_clase, 1)
					RETURNING resul
			END IF
			IF rm_r10_2.r10_cod_clase2 < rm_r10.r10_cod_clase THEN
				CALL fl_mostrar_mensaje('La clase final debe ser mayor igual a la clase inicial.','exclamation')
				NEXT FIELD r10_cod_clase2
			END IF
		ELSE 
			CLEAR tit_clase2
		END IF
	AFTER FIELD r10_marca
		IF rm_r10.r10_marca IS NOT NULL THEN
			CALL validar_marcas(rm_r10.r10_marca, 1) RETURNING resul
			IF resul = 1 THEN
                               	NEXT FIELD r10_marca
			END IF
			IF rm_r10_2.r10_marca2 IS NULL THEN
				LET rm_r10_2.r10_marca2 = rm_r10.r10_marca
				CALL validar_marcas(rm_r10_2.r10_marca2, 2)
					RETURNING resul
			END IF
			IF rm_r10.r10_marca > rm_r10_2.r10_marca2 THEN
				CALL fl_mostrar_mensaje('La marca inicial debe ser menor igual a la marca final.','exclamation')
				NEXT FIELD r10_marca
			END IF
		ELSE 
			CLEAR tit_marca
		END IF
	AFTER FIELD r10_marca2
		IF rm_r10_2.r10_marca2 IS NOT NULL THEN
			CALL validar_marcas(rm_r10_2.r10_marca2, 2)
				RETURNING resul
			IF resul = 1 THEN
                               	NEXT FIELD r10_marca2
			END IF
			IF rm_r10.r10_marca IS NULL THEN
				LET rm_r10.r10_marca = rm_r10_2.r10_marca2
				CALL validar_marcas(rm_r10.r10_marca, 1)
					RETURNING resul
			END IF
			IF rm_r10_2.r10_marca2 < rm_r10.r10_marca THEN
				CALL fl_mostrar_mensaje('La marca final debe ser mayor igual a la marca inicial.','exclamation')
				NEXT FIELD r10_marca2
			END IF
		ELSE 
			CLEAR tit_marca2
		END IF
	AFTER INPUT
		CALL validar_sublineas_no_nulas(rm_r10.r10_sub_linea,
						rm_r10_2.r10_sub_linea2)
			RETURNING resul
		IF resul = 1 THEN
			NEXT FIELD r10_sub_linea
		END IF
		CALL validar_sublineas_no_nulas(rm_r10_2.r10_sub_linea2,
						rm_r10.r10_sub_linea)
			RETURNING resul
		IF resul = 1 THEN
			NEXT FIELD r10_sub_linea2
		END IF
		CALL validar_grupos_no_nulos(rm_r10.r10_cod_grupo,
						rm_r10_2.r10_cod_grupo2)
			RETURNING resul
		IF resul = 1 THEN
			NEXT FIELD r10_cod_grupo
		END IF
		CALL validar_grupos_no_nulos(rm_r10_2.r10_cod_grupo2,
						rm_r10.r10_cod_grupo)
			RETURNING resul
		IF resul = 1 THEN
			NEXT FIELD r10_cod_grupo2
		END IF
		CALL validar_clases_no_nulas(rm_r10.r10_cod_clase,
						rm_r10_2.r10_cod_clase2)
			RETURNING resul
		IF resul = 1 THEN
			NEXT FIELD r10_cod_clase
		END IF
		CALL validar_clases_no_nulas(rm_r10_2.r10_cod_clase2,
						rm_r10.r10_cod_clase)
			RETURNING resul
		IF resul = 1 THEN
			NEXT FIELD r10_cod_clase2
		END IF
		CALL validar_marcas_no_nulas(rm_r10.r10_marca,
						rm_r10_2.r10_marca2)
			RETURNING resul
		IF resul = 1 THEN
			NEXT FIELD r10_marca
		END IF
		CALL validar_marcas_no_nulas(rm_r10_2.r10_marca2,
						rm_r10.r10_marca)
			RETURNING resul
		IF resul = 1 THEN
			NEXT FIELD r10_marca2
		END IF
END INPUT
IF vm_moneda = rg_gen.g00_moneda_base THEN
	RETURN ' r10_precio_mb '
END IF
IF vm_moneda = rg_gen.g00_moneda_alt THEN
	RETURN ' r10_precio_ma '
END IF

END FUNCTION



FUNCTION ayuda_lineas(flag)
DEFINE flag		SMALLINT
DEFINE r_r03		RECORD LIKE rept003.*

INITIALIZE r_r03.* TO NULL
CALL fl_ayuda_lineas_rep(vg_codcia) RETURNING r_r03.r03_codigo, r_r03.r03_nombre
IF r_r03.r03_codigo IS NOT NULL THEN
	CASE flag
		WHEN 1
                	LET rm_r10.r10_linea = r_r03.r03_codigo
                        DISPLAY BY NAME rm_r10.r10_linea
                        DISPLAY r_r03.r03_nombre TO tit_linea
		WHEN 2
                	LET rm_r10_2.r10_linea2 = r_r03.r03_codigo
                        DISPLAY BY NAME rm_r10_2.r10_linea2
                        DISPLAY r_r03.r03_nombre TO tit_linea2
	END CASE
END IF

END FUNCTION



FUNCTION ayuda_sublineas(linea, flag)
DEFINE linea		LIKE rept003.r03_codigo
DEFINE flag		SMALLINT
DEFINE r_r70		RECORD LIKE rept070.*

INITIALIZE r_r70.* TO NULL
CALL fl_ayuda_sublinea_rep(vg_codcia, linea)
	RETURNING r_r70.r70_sub_linea, r_r70.r70_desc_sub
IF r_r70.r70_sub_linea IS NOT NULL THEN
	CASE flag
		WHEN 1
			LET rm_r10.r10_sub_linea = r_r70.r70_sub_linea
			DISPLAY BY NAME rm_r10.r10_sub_linea
			DISPLAY r_r70.r70_desc_sub TO tit_sub_linea
		WHEN 2
			LET rm_r10_2.r10_sub_linea2 = r_r70.r70_sub_linea
			DISPLAY BY NAME rm_r10_2.r10_sub_linea2
			DISPLAY r_r70.r70_desc_sub TO tit_sub_linea2
	END CASE
END IF

END FUNCTION



FUNCTION ayuda_grupos(linea, sublinea, flag)
DEFINE linea		LIKE rept003.r03_codigo
DEFINE sublinea		LIKE rept070.r70_sub_linea
DEFINE flag		SMALLINT
DEFINE r_r71		RECORD LIKE rept071.*

INITIALIZE r_r71.* TO NULL
CALL fl_ayuda_grupo_ventas_rep(vg_codcia, linea, sublinea)
	RETURNING r_r71.r71_cod_grupo, r_r71.r71_desc_grupo
IF r_r71.r71_cod_grupo IS NOT NULL THEN
	CASE flag
		WHEN 1
			LET rm_r10.r10_cod_grupo = r_r71.r71_cod_grupo
			DISPLAY BY NAME rm_r10.r10_cod_grupo
			DISPLAY r_r71.r71_desc_grupo TO tit_grupo
		WHEN 2
			LET rm_r10_2.r10_cod_grupo2 = r_r71.r71_cod_grupo
			DISPLAY BY NAME rm_r10_2.r10_cod_grupo2
			DISPLAY r_r71.r71_desc_grupo TO tit_grupo2
	END CASE
END IF

END FUNCTION



FUNCTION ayuda_clases(linea, sublinea, grupo, flag)
DEFINE linea		LIKE rept003.r03_codigo
DEFINE sublinea		LIKE rept070.r70_sub_linea
DEFINE grupo		LIKE rept071.r71_cod_grupo
DEFINE flag		SMALLINT
DEFINE r_r72		RECORD LIKE rept072.*

INITIALIZE r_r72.* TO NULL
CALL fl_ayuda_clase_ventas_rep(vg_codcia, linea, sublinea, grupo)
	RETURNING r_r72.r72_cod_clase, r_r72.r72_desc_clase
IF r_r72.r72_cod_clase IS NOT NULL THEN
	CASE flag
		WHEN 1
			LET rm_r10.r10_cod_clase = r_r72.r72_cod_clase
			DISPLAY BY NAME rm_r10.r10_cod_clase
			DISPLAY r_r72.r72_desc_clase TO tit_clase
		WHEN 2
			LET rm_r10_2.r10_cod_clase2 = r_r72.r72_cod_clase
			DISPLAY BY NAME rm_r10_2.r10_cod_clase2
			DISPLAY r_r72.r72_desc_clase TO tit_clase2
	END CASE
END IF

END FUNCTION



FUNCTION ayuda_marcas(clase, flag)
DEFINE clase		LIKE rept072.r72_cod_clase
DEFINE flag		SMALLINT
DEFINE r_r73		RECORD LIKE rept073.*

INITIALIZE r_r73.* TO NULL
CALL fl_ayuda_marcas_rep_asignadas(vg_codcia, clase)
	RETURNING r_r73.r73_marca
IF r_r73.r73_marca IS NOT NULL THEN
	CASE flag
		WHEN 1
			LET rm_r10.r10_marca = r_r73.r73_marca
               		CALL fl_lee_marca_rep(vg_codcia, rm_r10.r10_marca)
             			RETURNING r_r73.*
			DISPLAY BY NAME rm_r10.r10_marca
			DISPLAY r_r73.r73_desc_marca TO tit_marca
		WHEN 2
			LET rm_r10_2.r10_marca2 = r_r73.r73_marca
               		CALL fl_lee_marca_rep(vg_codcia, rm_r10_2.r10_marca2)
             			RETURNING r_r73.*
			DISPLAY BY NAME rm_r10_2.r10_marca2
			DISPLAY r_r73.r73_desc_marca TO tit_marca2
	END CASE
END IF

END FUNCTION



FUNCTION validar_lineas(linea, flag)
DEFINE linea		LIKE rept003.r03_codigo
DEFINE flag		SMALLINT
DEFINE r_r03		RECORD LIKE rept003.*

CALL fl_lee_linea_rep(vg_codcia, linea) RETURNING r_r03.*
IF r_r03.r03_compania IS NULL THEN
	CALL fl_mostrar_mensaje('Línea no existe.','exclamation')
	RETURN 1
END IF
CASE flag
	WHEN 1
		DISPLAY BY NAME rm_r10.r10_linea
		DISPLAY r_r03.r03_nombre TO tit_linea
	WHEN 2
		DISPLAY BY NAME rm_r10_2.r10_linea2
		DISPLAY r_r03.r03_nombre TO tit_linea2
END CASE
RETURN 0

END FUNCTION



FUNCTION validar_sublineas(sublinea, flag)
DEFINE sublinea		LIKE rept070.r70_sub_linea
DEFINE resul, flag	SMALLINT
DEFINE r_r70		RECORD LIKE rept070.*

CALL fl_retorna_sublinea_rep(vg_codcia, sublinea) RETURNING r_r70.*, resul
IF resul = 0 THEN
	IF r_r70.r70_sub_linea IS NULL THEN
		CALL fl_mostrar_mensaje('La Sublínea de venta no existe en la compañía.','exclamation')
		RETURN 1
	END IF
END IF
CASE flag
	WHEN 1
		DISPLAY BY NAME rm_r10.r10_sub_linea
		DISPLAY r_r70.r70_desc_sub TO tit_sub_linea
	WHEN 2
		DISPLAY BY NAME rm_r10_2.r10_sub_linea2
		DISPLAY r_r70.r70_desc_sub TO tit_sub_linea2
END CASE
RETURN 0

END FUNCTION



FUNCTION validar_grupos(grupo, flag)
DEFINE grupo		LIKE rept071.r71_cod_grupo
DEFINE resul, flag	SMALLINT
DEFINE r_r71		RECORD LIKE rept071.*

CALL fl_retorna_grupo_rep(vg_codcia, grupo) RETURNING r_r71.*, resul
IF resul = 0 THEN
	IF r_r71.r71_cod_grupo IS NULL THEN
		CALL fl_mostrar_mensaje('El Grupo no existe en la compañía.','exclamation')
		RETURN 1
	END IF
END IF
CASE flag
	WHEN 1
		DISPLAY BY NAME rm_r10.r10_cod_grupo
		DISPLAY r_r71.r71_desc_grupo TO tit_grupo
	WHEN 2
		DISPLAY BY NAME rm_r10_2.r10_cod_grupo2
		DISPLAY r_r71.r71_desc_grupo TO tit_grupo2
END CASE
RETURN 0

END FUNCTION



FUNCTION validar_clases(clase, flag)
DEFINE clase		LIKE rept072.r72_cod_clase
DEFINE resul, flag	SMALLINT
DEFINE r_r72		RECORD LIKE rept072.*

CALL fl_retorna_clase_rep(vg_codcia, clase) RETURNING r_r72.*, resul
IF resul = 0 THEN
	IF r_r72.r72_cod_clase IS NULL THEN
		CALL fl_mostrar_mensaje('La Clase no existe en la compañía.','exclamation')
		RETURN 1
	END IF
END IF
CASE flag
	WHEN 1
		DISPLAY BY NAME rm_r10.r10_cod_clase
		DISPLAY r_r72.r72_desc_clase TO tit_clase
	WHEN 2
		DISPLAY BY NAME rm_r10_2.r10_cod_clase2
		DISPLAY r_r72.r72_desc_clase TO tit_clase2
END CASE
RETURN 0

END FUNCTION



FUNCTION validar_marcas(marca, flag)
DEFINE marca		LIKE rept073.r73_marca
DEFINE flag		SMALLINT
DEFINE r_r73		RECORD LIKE rept073.*

CALL fl_lee_marca_rep(vg_codcia, marca) RETURNING r_r73.*
IF r_r73.r73_marca IS NULL THEN
	CALL fl_mostrar_mensaje('La Marca no existe en la compañía.','exclamation')
	RETURN 1
END IF
CASE flag
	WHEN 1
		DISPLAY BY NAME rm_r10.r10_marca
		DISPLAY r_r73.r73_desc_marca TO tit_marca
	WHEN 2
		DISPLAY BY NAME rm_r10_2.r10_marca2
		DISPLAY r_r73.r73_desc_marca TO tit_marca2
END CASE
RETURN 0

END FUNCTION



FUNCTION validar_sublineas_no_nulas(sublinea1, sublinea2)
DEFINE sublinea1	LIKE rept070.r70_sub_linea
DEFINE sublinea2	LIKE rept070.r70_sub_linea

IF sublinea1 IS NULL THEN
	IF sublinea2 IS NOT NULL THEN
		CALL fl_mostrar_mensaje('No puede dejar esta línea en blanco.','exclamation')
		RETURN 1
	END IF
END IF
LET vm_expr_sublinea = NULL
IF sublinea1 IS NOT NULL THEN
	IF sublinea2 IS NOT NULL THEN
		LET vm_expr_sublinea = '  AND r10_sub_linea BETWEEN "',
					rm_r10.r10_sub_linea CLIPPED, '" AND "',
					rm_r10_2.r10_sub_linea2 CLIPPED, '"'
	END IF
END IF
RETURN 0

END FUNCTION



FUNCTION validar_grupos_no_nulos(grupo1, grupo2)
DEFINE grupo1		LIKE rept071.r71_cod_grupo
DEFINE grupo2		LIKE rept071.r71_cod_grupo

IF grupo1 IS NULL THEN
	IF grupo2 IS NOT NULL THEN
		CALL fl_mostrar_mensaje('No puede dejar este grupo en blanco.','exclamation')
		RETURN 1
	END IF
END IF
LET vm_expr_grupo = NULL
IF grupo1 IS NOT NULL THEN
	IF grupo2 IS NOT NULL THEN
		LET vm_expr_grupo = '  AND r10_cod_grupo BETWEEN "',
					rm_r10.r10_cod_grupo CLIPPED, '" AND "',
					rm_r10_2.r10_cod_grupo2 CLIPPED, '"'
	END IF
END IF
RETURN 0

END FUNCTION



FUNCTION validar_clases_no_nulas(clase1, clase2)
DEFINE clase1		LIKE rept072.r72_cod_clase
DEFINE clase2		LIKE rept072.r72_cod_clase

IF clase1 IS NULL THEN
	IF clase2 IS NOT NULL THEN
		CALL fl_mostrar_mensaje('No puede dejar esta clase en blanco.','exclamation')
		RETURN 1
	END IF
END IF
LET vm_expr_clase = NULL
IF clase1 IS NOT NULL THEN
	IF clase2 IS NOT NULL THEN
		LET vm_expr_clase = '  AND r10_cod_clase BETWEEN "',
					rm_r10.r10_cod_clase CLIPPED, '" AND "',
					rm_r10_2.r10_cod_clase2 CLIPPED, '"'
	END IF
END IF
RETURN 0

END FUNCTION



FUNCTION validar_marcas_no_nulas(marca1, marca2)
DEFINE marca1		LIKE rept073.r73_marca
DEFINE marca2		LIKE rept073.r73_marca

IF marca1 IS NULL THEN
	IF marca2 IS NOT NULL THEN
		CALL fl_mostrar_mensaje('No puede dejar esta marca en blanco.','exclamation')
		RETURN 1
	END IF
END IF
LET vm_expr_marca = NULL
IF marca1 IS NOT NULL THEN
	IF marca2 IS NOT NULL THEN
		LET vm_expr_marca = '  AND r10_marca BETWEEN "',
					rm_r10.r10_marca CLIPPED, '" AND "',
					rm_r10_2.r10_marca2 CLIPPED, '"'
	END IF
END IF
RETURN 0

END FUNCTION



REPORT rep_precios(r_rep)
DEFINE r_rep		RECORD
				linea		LIKE rept010.r10_linea,
				sublinea	LIKE rept010.r10_sub_linea,
				grupo		LIKE rept010.r10_cod_grupo,
				clase		LIKE rept010.r10_cod_clase,
				codigo		LIKE rept010.r10_codigo,
				marca		LIKE rept010.r10_marca,
				nombre		LIKE rept010.r10_nombre,
				unidad		LIKE rept010.r10_uni_med,
				precio		LIKE rept010.r10_precio_mb
			END RECORD
DEFINE r_r03		RECORD LIKE rept003.*
DEFINE r_r70		RECORD LIKE rept070.*
DEFINE r_r71		RECORD LIKE rept071.*
DEFINE r_r72		RECORD LIKE rept072.*
DEFINE r_r73		RECORD LIKE rept073.*
DEFINE titulo		VARCHAR(80)
DEFINE modulo		VARCHAR(40)
DEFINE usuario		VARCHAR(19)
DEFINE fecha		VARCHAR(10)
DEFINE resul		SMALLINT
DEFINE escape		SMALLINT
DEFINE act_comp, db_c	SMALLINT
DEFINE desact_comp, db	SMALLINT

OUTPUT
	TOP MARGIN	1
	LEFT MARGIN	0
	RIGHT MARGIN	132
	BOTTOM MARGIN	4
	PAGE LENGTH	66

FORMAT

PAGE HEADER
	--print 'E'; 
	--print '&l26A';	-- Indica que voy a trabajar con hojas A4
	--print '&k2S'	        -- Letra condensada (16 cpi)
	LET escape	= 27		# Iniciar sec. impresi¢n
	LET act_comp	= 15		# Activar Comprimido.
	LET desact_comp	= 18		# Cancelar Comprimido.
	LET modulo      = "MODULO: INVENTARIO"
	LET fecha	= TODAY USING "dd-mm-yyyy"
	LET usuario     = "USUARIO: ", vg_usuario CLIPPED
	CALL fl_justifica_titulo('D', usuario, 19) RETURNING usuario
	CALL fl_justifica_titulo('C', 'LISTA DE PRECIOS PVP AL ' || fecha, 80)
		RETURNING titulo
	--SKIP 2 LINES
	print ASCII escape;
	print ASCII act_comp
	PRINT COLUMN 001, rg_cia.g01_razonsocial,
	      COLUMN 122, "PAGINA: ", PAGENO USING "&&&"
	PRINT COLUMN 001, "SUCURSAL : ", rm_g02.g02_nombre,
	      COLUMN 031, titulo CLIPPED,
	      COLUMN 126, UPSHIFT(vg_proceso)
	{--
	SKIP 1 LINES
	CALL fl_lee_linea_rep(vg_codcia, rm_r10.r10_linea) RETURNING r_r03.*
	PRINT COLUMN 20,  "DIVISION INICIAL: ", rm_r10.r10_linea,
	      COLUMN 48,  r_r03.r03_nombre
	CALL fl_lee_linea_rep(vg_codcia, rm_r10_2.r10_linea2) RETURNING r_r03.*
	PRINT COLUMN 20,  "DIVISION FINAL  : ", rm_r10_2.r10_linea2,
	      COLUMN 48,  r_r03.r03_nombre
	--#IF rm_r10.r10_sub_linea IS NOT NULL THEN
		CALL fl_retorna_sublinea_rep(vg_codcia, rm_r10.r10_sub_linea)
			RETURNING r_r70.*, resul
		PRINT COLUMN 20,  "LINEA INICIAL   : ", rm_r10.r10_sub_linea,
		      COLUMN 48,  r_r70.r70_desc_sub
		CALL fl_retorna_sublinea_rep(vg_codcia, rm_r10_2.r10_sub_linea2)
			RETURNING r_r70.*, resul
		PRINT COLUMN 20,  "LINEA FINAL     : ", rm_r10_2.r10_sub_linea2,
		      COLUMN 48,  r_r70.r70_desc_sub
	--#END IF
	--#IF rm_r10.r10_cod_grupo IS NOT NULL THEN
		CALL fl_retorna_grupo_rep(vg_codcia, rm_r10.r10_cod_grupo)
			RETURNING r_r71.*, resul
		PRINT COLUMN 20,  "GRUPO INICIAL   : ", rm_r10.r10_cod_grupo,
		      COLUMN 48,  r_r71.r71_desc_grupo
		CALL fl_retorna_grupo_rep(vg_codcia, rm_r10_2.r10_cod_grupo2)
			RETURNING r_r71.*, resul
		PRINT COLUMN 20,  "GRUPO FINAL     : ", rm_r10_2.r10_cod_grupo2,
		      COLUMN 48,  r_r71.r71_desc_grupo
	--#END IF
	--#IF rm_r10.r10_cod_clase IS NOT NULL THEN
		CALL fl_retorna_clase_rep(vg_codcia, rm_r10.r10_cod_clase)
			RETURNING r_r72.*, resul
		PRINT COLUMN 20,  "CLASE INICIAL   : ", rm_r10.r10_cod_clase,
		      COLUMN 48,  r_r72.r72_desc_clase
		CALL fl_retorna_clase_rep(vg_codcia, rm_r10_2.r10_cod_clase2)
			RETURNING r_r72.*, resul
		PRINT COLUMN 20,  "CLASE FINAL     : ", rm_r10_2.r10_cod_clase2,
		      COLUMN 48,  r_r72.r72_desc_clase
	--#END IF
	--#IF rm_r10.r10_marca IS NOT NULL THEN
		CALL fl_lee_marca_rep(vg_codcia, rm_r10.r10_marca)
			RETURNING r_r73.*
		PRINT COLUMN 20,  "MARCA INICIAL   : ", rm_r10.r10_marca,
		      COLUMN 48,  r_r73.r73_desc_marca
		CALL fl_lee_marca_rep(vg_codcia, rm_r10_2.r10_marca2)
			RETURNING r_r73.*
		PRINT COLUMN 20,  "MARCA FINAL     : ", rm_r10_2.r10_marca2,
		      COLUMN 48,  r_r73.r73_desc_marca
	--#END IF
	--}
	SKIP 1 LINES 
	PRINT COLUMN 001,"FECHA DE IMPRESION: ", TODAY USING "dd-mm-yyyy",
		1 SPACES, TIME,
	      COLUMN 114, usuario
	PRINT "------------------------------------------------------------------------------------------------------------------------------------"
	PRINT COLUMN 02,  "CODIGO",
	      COLUMN 10,  "MARCA",
	      COLUMN 18,  "DESCRIPCION",
	      COLUMN 85,  "UNIDAD",
	      COLUMN 93,  "      PRECIO",
	      COLUMN 110, "ACTUALIZACIONES DEL PVP"
	PRINT "------------------------------------------------------------------------------------------------------------------------------------"

BEFORE GROUP OF r_rep.linea
	CALL fl_lee_linea_rep(vg_codcia, r_rep.linea) RETURNING r_r03.*
	--SKIP 1 LINES 
	PRINT COLUMN 02,  "DIVISION: ", r_rep.linea,
	      COLUMN 22,  r_r03.r03_nombre

BEFORE GROUP OF r_rep.sublinea
	CALL fl_lee_sublinea_rep(vg_codcia, r_rep.linea, r_rep.sublinea)
		RETURNING r_r70.*
	--SKIP 1 LINES 
	PRINT COLUMN 02,  "LINEA   : ", r_rep.sublinea,
	      COLUMN 22,  r_r70.r70_desc_sub

BEFORE GROUP OF r_rep.grupo
	CALL fl_lee_grupo_rep(vg_codcia, r_rep.linea, r_rep.sublinea,
				r_rep.grupo)
		RETURNING r_r71.*
	--SKIP 1 LINES 
	PRINT COLUMN 02,  "GRUPO   : ", r_rep.grupo,
	      COLUMN 22,  r_r71.r71_desc_grupo

BEFORE GROUP OF r_rep.clase
	NEED 4 LINES
	CALL fl_lee_clase_rep(vg_codcia, r_rep.linea, r_rep.sublinea,
				r_rep.grupo, r_rep.clase)
		RETURNING r_r72.*
	SKIP 1 LINES 
	PRINT COLUMN 02,  "CLASE   : ", r_rep.clase,
	      COLUMN 22,  r_r72.r72_desc_clase
	PRINT "--------------------------------------------------------------------------------------------------------"

ON EVERY ROW
	PRINT COLUMN 01,  r_rep.codigo[1,7]	USING "####&&&",
	      COLUMN 10,  r_rep.marca,
	      COLUMN 18,  r_rep.nombre[1,65],
	      COLUMN 85,  r_rep.unidad,
	      COLUMN 93,  r_rep.precio		USING "#,###,##&.##",
              COLUMN 110, "_______________________"
	
ON LAST ROW
	print ASCII escape;
	print ASCII desact_comp

END REPORT



FUNCTION borrar_cabecera()

CLEAR FORM
INITIALIZE rm_r10.*, vm_moneda TO NULL

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
