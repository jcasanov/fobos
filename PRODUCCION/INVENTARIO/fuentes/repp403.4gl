------------------------------------------------------------------------------
-- Titulo           : repp403.4gl - Listado de existencias
-- Elaboracion      : 27-dic-2001
-- Autor            : NPC
-- Formato Ejecucion: fglrun repp403 base módulo compañía localidad
-- Ultima Correccion: 05-Dic-2003 
-- Motivo Correccion: Rediseno de la lista de existencias
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE rm_r10		RECORD LIKE rept010.*
DEFINE rm_r11		RECORD LIKE rept011.*
DEFINE rm_r31		RECORD LIKE rept031.*
DEFINE rm_r10_2		RECORD
				r10_linea2	LIKE rept010.r10_linea,
				r10_sub_linea2	LIKE rept010.r10_sub_linea,
				r10_cod_grupo2	LIKE rept010.r10_cod_grupo,
				r10_cod_clase2	LIKE rept010.r10_cod_clase,
				r10_marca2	LIKE rept010.r10_marca
			END RECORD
DEFINE rm_g01		RECORD LIKE gent001.*
DEFINE rm_g02		RECORD LIKE gent002.*
DEFINE vm_moneda	LIKE gent000.g00_moneda_base
DEFINE vm_moneda_des	LIKE gent013.g13_nombre
DEFINE vm_stock_tot	CHAR(1)
DEFINE vm_stock_loc	CHAR(1)
DEFINE vm_precios	CHAR(1)
DEFINE vm_bodega	VARCHAR(100)
DEFINE tit_mes		VARCHAR(10)
DEFINE vm_expr_sublinea	VARCHAR(100)
DEFINE vm_expr_grupo	VARCHAR(100)
DEFINE vm_expr_clase	VARCHAR(100)
DEFINE vm_expr_marca	VARCHAR(100)
DEFINE tot_sto_l_gen	DECIMAL(10,2)
DEFINE tot_sto_n_gen	DECIMAL(10,2)
DEFINE tot_sto_t_gen	DECIMAL(10,2)
DEFINE tot_sto_l_div	DECIMAL(10,2)
DEFINE tot_sto_n_div	DECIMAL(10,2)
DEFINE tot_sto_t_div	DECIMAL(10,2)
DEFINE tot_sto_l_lin	DECIMAL(10,2)
DEFINE tot_sto_n_lin	DECIMAL(10,2)
DEFINE tot_sto_t_lin	DECIMAL(10,2)
DEFINE tot_sto_l_grp	DECIMAL(10,2)
DEFINE tot_sto_n_grp	DECIMAL(10,2)
DEFINE tot_sto_t_grp	DECIMAL(10,2)
DEFINE tot_sto_l_cla	DECIMAL(10,2)
DEFINE tot_sto_n_cla	DECIMAL(10,2)
DEFINE tot_sto_t_cla	DECIMAL(10,2)



MAIN

DEFER QUIT 
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/repp403.err')
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
LET vg_proceso = 'repp403'
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
CALL fl_lee_localidad(vg_codcia, vg_codloc) RETURNING rm_g02.*
IF rm_g02.g02_compania IS NULL THEN
	CALL fl_mostrar_mensaje('No existe localidad.','stop')
	EXIT PROGRAM
END IF
LET lin_menu = 0
LET row_ini  = 3
LET num_rows = 20
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
	OPEN FORM f_rep FROM "../forms/repf403_1"
ELSE
	OPEN FORM f_rep FROM "../forms/repf403_1c"
END IF
DISPLAY FORM f_rep
CALL borrar_cabecera()
CALL control_reporte()

END FUNCTION



FUNCTION control_reporte()
DEFINE r_g13		RECORD LIKE gent013.*
DEFINE expr_sql		VARCHAR(100)

LET vm_moneda      = rg_gen.g00_moneda_base
CALL fl_lee_moneda(vm_moneda) RETURNING r_g13.*
IF r_g13.g13_moneda IS NULL THEN
	CALL fl_mostrar_mensaje('Moneda no existe moneda base.','stop')
        EXIT PROGRAM
END IF
DISPLAY r_g13.g13_nombre TO tit_moneda
LET vm_moneda_des  = r_g13.g13_nombre
LET vm_stock_tot   = 'S'
LET vm_stock_loc   = 'S'
LET rm_r31.r31_ano = YEAR(TODAY)
LET rm_r31.r31_mes = MONTH(TODAY)
CALL fl_retorna_nombre_mes(rm_r31.r31_mes) RETURNING tit_mes
DISPLAY BY NAME tit_mes
LET vm_precios     = 'N'
WHILE TRUE
	CALL lee_parametros() RETURNING expr_sql
	IF int_flag THEN
		EXIT WHILE
	END IF
	CALL imprimir(expr_sql)
END WHILE

END FUNCTION



FUNCTION lee_parametros()
DEFINE r_g13		RECORD LIKE gent013.*
DEFINE r_r02		RECORD LIKE rept002.*
DEFINE mone_aux         LIKE gent013.g13_moneda
DEFINE nomm_aux         LIKE gent013.g13_nombre
DEFINE deci_aux         LIKE gent013.g13_decimales
DEFINE codbog		LIKE rept002.r02_codigo
DEFINE nombog		LIKE rept002.r02_nombre
DEFINE anio		LIKE rept031.r31_ano
DEFINE mes		LIKE rept031.r31_mes
DEFINE mes_aux		LIKE rept031.r31_mes
DEFINE resul		SMALLINT
DEFINE expr_sql		VARCHAR(100)

LET expr_sql = NULL
LET int_flag = 0
INPUT BY NAME vm_moneda, rm_r11.r11_bodega, rm_r10.r10_linea,
	rm_r10_2.r10_linea2, rm_r10.r10_sub_linea, rm_r10_2.r10_sub_linea2,
	rm_r10.r10_cod_grupo, rm_r10_2.r10_cod_grupo2, rm_r10.r10_cod_clase,
	rm_r10_2.r10_cod_clase2, rm_r10.r10_marca, rm_r10_2.r10_marca2,
	vm_stock_tot, rm_r31.r31_ano, rm_r31.r31_mes, vm_stock_loc, vm_precios
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		LET int_flag = 1
		RETURN expr_sql
        ON KEY(F1,CONTROL-W)
		CALL llamar_visor_teclas()
	ON KEY(F2)
		IF INFIELD(vm_moneda) THEN
               		CALL fl_ayuda_monedas()
                       		RETURNING mone_aux, nomm_aux, deci_aux
       		      	LET int_flag = 0
                      	IF mone_aux IS NOT NULL THEN
                              	LET vm_moneda = mone_aux
                               	DISPLAY BY NAME vm_moneda
                               	DISPLAY nomm_aux TO tit_moneda
                       	END IF
                END IF
		IF INFIELD(r11_bodega) THEN
                     	CALL fl_ayuda_bodegas_rep(vg_codcia, 'T', 'T', 'T', 'A', 'T', '0')
				RETURNING codbog, nombog
       		      	LET int_flag = 0
                       	IF codbog IS NOT NULL THEN
                             	LET rm_r11.r11_bodega = codbog
                               	DISPLAY BY NAME rm_r11.r11_bodega
                               	DISPLAY nombog TO tit_bodega
                        END IF
                END IF
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
		IF INFIELD(r31_mes) THEN
			IF vg_gui = 1 THEN
				CALL fl_ayuda_mostrar_meses()
					RETURNING mes_aux, tit_mes
				IF mes_aux IS NOT NULL THEN
					LET rm_r31.r31_mes = mes_aux
					DISPLAY BY NAME rm_r31.r31_mes, tit_mes
				END IF
			END IF
		END IF
	BEFORE INPUT
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
	BEFORE FIELD r31_ano
		LET anio = rm_r31.r31_ano
	BEFORE FIELD r31_mes
		LET mes  = rm_r31.r31_mes
	AFTER FIELD vm_moneda
               	IF vm_moneda IS NOT NULL THEN
                       	CALL fl_lee_moneda(vm_moneda)
                               	RETURNING r_g13.*
                       	IF r_g13.g13_moneda IS NULL THEN
                               	--CALL fgl_winmessage(vg_producto,'Moneda no existe.','exclamation')
				CALL fl_mostrar_mensaje('Moneda no existe.','exclamation')
                               	NEXT FIELD vm_moneda
                       	END IF
                       	IF vm_moneda <> rg_gen.g00_moneda_base
                       	AND vm_moneda <> rg_gen.g00_moneda_alt THEN
                               	--CALL fgl_winmessage(vg_producto,'La moneda solo puede ser moneda base o alterna.','exclamation')
				CALL fl_mostrar_mensaje('La moneda solo puede ser moneda base o alterna.','exclamation')
                               	NEXT FIELD vm_moneda
			END IF
               	ELSE
                       	LET vm_moneda = rg_gen.g00_moneda_base
                       	CALL fl_lee_moneda(vm_moneda)
				RETURNING r_g13.*
                       	DISPLAY BY NAME vm_moneda
               	END IF
               	DISPLAY r_g13.g13_nombre TO tit_moneda
		LET vm_moneda_des = r_g13.g13_nombre
	AFTER FIELD r11_bodega
               	IF rm_r11.r11_bodega IS NOT NULL THEN
                       	CALL fl_lee_bodega_rep(vg_codcia, rm_r11.r11_bodega)
                     		RETURNING r_r02.*
                        IF r_r02.r02_compania IS NULL THEN
                               	--CALL fgl_winmessage(vg_producto,'Bodega no existe.','exclamation')
				CALL fl_mostrar_mensaje('Bodega no existe.','exclamation')
                               	NEXT FIELD r11_bodega
                        END IF
			DISPLAY r_r02.r02_nombre TO tit_bodega
		ELSE
			CLEAR tit_bodega
                END IF
	AFTER FIELD r31_ano
		IF rm_r31.r31_ano IS NULL THEN
			LET rm_r31.r31_ano = anio
			DISPLAY BY NAME rm_r31.r31_ano
		END IF
	AFTER FIELD r31_mes
		IF rm_r31.r31_mes IS NULL THEN
			LET rm_r31.r31_mes = mes
			DISPLAY BY NAME rm_r31.r31_mes
		END IF
		CALL fl_retorna_nombre_mes(rm_r31.r31_mes) RETURNING tit_mes
		DISPLAY BY NAME tit_mes
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
		INITIALIZE vm_bodega TO NULL
		IF rm_r31.r31_ano = YEAR(TODAY)	AND
		   rm_r31.r31_mes = MONTH(TODAY) THEN
			IF rm_r11.r11_bodega IS NOT NULL THEN
				LET vm_bodega = '   AND r11_bodega   = "',
						rm_r11.r11_bodega, '"'
			END IF
		ELSE
			IF rm_r11.r11_bodega IS NOT NULL THEN
				LET vm_bodega = '   AND r31_bodega   = "',
						rm_r11.r11_bodega, '"'
			END IF
		END IF
END INPUT
IF vm_moneda = rg_gen.g00_moneda_base THEN
	IF vm_precios = 'S' THEN
		IF rm_r31.r31_ano = YEAR(TODAY)	AND
		   rm_r31.r31_mes = MONTH(TODAY) THEN
			LET expr_sql = ', r10_precio_mb '
		ELSE
			LET expr_sql = ', r31_precio_mb '
		END IF
	END IF
END IF
IF vm_moneda = rg_gen.g00_moneda_alt THEN
	IF vm_precios = 'S' THEN
		IF rm_r31.r31_ano = YEAR(TODAY)	AND
		   rm_r31.r31_mes = MONTH(TODAY) THEN
			LET expr_sql = ', r10_precio_ma '
		ELSE
			LET expr_sql = ', r31_precio_ma '
		END IF
	END IF
END IF
RETURN expr_sql

END FUNCTION



FUNCTION imprimir(expr_sql)
DEFINE expr_sql		VARCHAR(100)
DEFINE r_g31		RECORD LIKE gent031.*
DEFINE sec		LIKE rept010.r10_sec_item
DEFINE query		CHAR(1800)
DEFINE comando		VARCHAR(100)
DEFINE imprimio		CHAR(1)
DEFINE r_rep		RECORD
				linea		LIKE rept010.r10_linea,
				sublinea	LIKE rept010.r10_sub_linea,
				grupo		LIKE rept010.r10_cod_grupo,
				clase		LIKE rept010.r10_cod_clase,
				codigo		LIKE rept010.r10_codigo,
				marca		LIKE rept010.r10_marca,
				nombre		LIKE rept010.r10_nombre,
				bodega		LIKE rept002.r02_codigo,
				stock_local	DECIMAL(10,2),
				stock_nac	DECIMAL(10,2),
				stock_total	DECIMAL(10,2),
				unidad		LIKE rept010.r10_uni_med,
				precio		LIKE rept010.r10_precio_mb
			END RECORD

CALL fl_control_reportes() RETURNING comando
IF int_flag THEN
	RETURN
END IF
CALL fl_lee_ciudad(rm_g02.g02_ciudad) RETURNING r_g31.*
IF vm_precios = 'S' THEN
	LET expr_sql = expr_sql CLIPPED, ' precio_sto '
END IF
IF rm_r31.r31_ano = YEAR(TODAY) AND rm_r31.r31_mes = MONTH(TODAY) THEN
	LET query = 'SELECT r10_sec_item, r10_linea, r10_sub_linea,',
		' r10_cod_grupo, r10_cod_clase, r10_codigo, r10_marca,',
		' r10_nombre, r11_bodega, r11_stock_act, 0 sto_nac, 0 sto_tot,',
		' r10_uni_med ', expr_sql CLIPPED,
		' FROM rept010, rept011 ', 
		' WHERE r10_compania = ', vg_codcia,
		'   AND r11_compania = r10_compania ',
		vm_bodega CLIPPED,
		'   AND r11_item     = r10_codigo '
ELSE
	LET query = 'SELECT r10_sec_item, r10_linea, r10_sub_linea,',
		' r10_cod_grupo, r10_cod_clase, r10_codigo, r10_marca,',
		' r10_nombre, r31_bodega, r31_stock, 0 sto_nac, 0 sto_tot,',
		' r10_uni_med ', expr_sql CLIPPED,
		' FROM rept031, rept010 ',
		' WHERE r31_compania = ', vg_codcia,
   	        '   AND r31_ano      = ', rm_r31.r31_ano,
 	        '   AND r31_mes      = ', rm_r31.r31_mes,
		vm_bodega CLIPPED,
		'   AND r10_compania = r31_compania ',
	 	'   AND r10_codigo   = r31_item '
END IF
LET query = query CLIPPED,
		'   AND r10_linea BETWEEN "', rm_r10.r10_linea CLIPPED,
		'" AND "', rm_r10_2.r10_linea2 CLIPPED, '"',
		vm_expr_sublinea CLIPPED,
		vm_expr_grupo CLIPPED,
		vm_expr_clase CLIPPED,
		vm_expr_marca CLIPPED,
		' INTO TEMP tmp_stocks'
PREPARE det_tmp FROM query
EXECUTE det_tmp
IF vm_precios = 'S' THEN
	LET expr_sql = ', precio_sto '
END IF
LET query = ' SELECT UNIQUE r10_sec_item, r10_linea, r10_sub_linea, ',
			' r10_cod_grupo, r10_cod_clase, r10_codigo, r10_marca,',
			' r10_nombre, r10_uni_med ', expr_sql CLIPPED,
		' FROM tmp_stocks ',
		' ORDER BY 2, 3, 4, 5, 7, 6, 1'
PREPARE cons FROM query
DECLARE q_deto CURSOR FOR cons
OPEN q_deto
FETCH q_deto
IF STATUS = NOTFOUND THEN
	CLOSE q_deto
	FREE q_deto
	CALL fl_mensaje_consulta_sin_registros()
	DROP TABLE tmp_stocks
	RETURN
END IF
START REPORT report_stock TO PIPE comando
LET tot_sto_l_gen = 0
LET tot_sto_n_gen = 0
LET tot_sto_t_gen = 0
LET imprimio      = 'N'
FOREACH q_deto INTO sec, r_rep.linea, r_rep.sublinea, r_rep.grupo, r_rep.clase,
	r_rep.codigo, r_rep.marca, r_rep.nombre, r_rep.unidad, r_rep.precio
	CALL retorna_stocks(r_rep.codigo, r_g31.g31_ciudad)
		RETURNING r_rep.stock_local, r_rep.stock_nac
	LET r_rep.stock_total = r_rep.stock_local
	IF r_rep.stock_nac IS NOT NULL THEN
		LET r_rep.stock_total = r_rep.stock_local + r_rep.stock_nac
	END IF
	IF vm_stock_tot = 'S' THEN
		IF r_rep.stock_total <= 0 THEN
			CONTINUE FOREACH
		END IF
	END IF
	IF vm_stock_loc = 'S' THEN
		IF r_rep.stock_local <= 0 THEN
			CONTINUE FOREACH
		END IF
	END IF
	IF vm_precios = 'N' THEN
		LET r_rep.precio = NULL
	END IF
	OUTPUT TO REPORT report_stock(r_rep.*)
	LET imprimio = 'S'
END FOREACH
FINISH REPORT report_stock
IF imprimio = 'N' THEN
	CALL fl_mensaje_consulta_sin_registros()
END IF
DROP TABLE tmp_stocks

END FUNCTION



FUNCTION retorna_stocks(codigo, ciudad)
DEFINE codigo		LIKE rept010.r10_codigo
DEFINE ciudad		LIKE gent031.g31_ciudad
DEFINE query		CHAR(800)
DEFINE query2		CHAR(800)
DEFINE tabla_loc	VARCHAR(15)
DEFINE expr_loc		VARCHAR(200)
DEFINE expr_loc2	VARCHAR(200)
DEFINE stock_local	DECIMAL(10,2)
DEFINE stock_nac	DECIMAL(10,2)

INITIALIZE tabla_loc, expr_loc, expr_loc2 TO NULL
IF vm_bodega IS NULL THEN
	LET tabla_loc = ', gent002 '
	LET expr_loc  = '   AND g02_compania  = r02_compania ',
			'   AND g02_localidad = r02_localidad '
END IF
IF rm_r31.r31_ano = YEAR(TODAY) AND rm_r31.r31_mes = MONTH(TODAY) THEN
	LET query = 'SELECT NVL(SUM(r11_stock_act), 0) ',
			' FROM tmp_stocks, rept002 ', tabla_loc CLIPPED,
		        ' WHERE r10_codigo    = "', codigo, '"',
			'   AND r02_compania  = ', vg_codcia,
			'   AND r02_codigo    = r11_bodega '
ELSE
	LET query = 'SELECT NVL(SUM(r31_stock), 0) ',
			' FROM tmp_stocks, rept002 ', tabla_loc CLIPPED,
		        ' WHERE r10_codigo    = "', codigo, '"',
			'   AND r02_compania  = ', vg_codcia,
			'   AND r02_codigo    = r31_bodega '
END IF
IF vm_bodega IS NULL THEN
	LET query  = query CLIPPED,
			'   AND r02_tipo      = "F" ',
			'   AND r02_area      = "R" '
END IF
LET query  = query CLIPPED,
		'   AND r02_estado   <> "B" ',
		expr_loc CLIPPED
LET query2 = query CLIPPED
IF vm_bodega IS NULL THEN
	LET expr_loc2 = '   AND g02_ciudad    = ', ciudad
END IF
LET query = query CLIPPED, expr_loc2 CLIPPED
PREPARE suma_stock FROM query
EXECUTE suma_stock INTO stock_local
IF vm_bodega IS NOT NULL THEN
	LET stock_nac = NULL
	RETURN stock_local, stock_nac
END IF
LET expr_loc2 = '   AND g02_ciudad   <> ', ciudad
LET query2    = query2 CLIPPED, expr_loc2 CLIPPED
PREPARE suma_stock2 FROM query2
EXECUTE suma_stock2 INTO stock_nac
RETURN stock_local, stock_nac

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



REPORT report_stock(r_rep)
DEFINE r_rep		RECORD
				linea		LIKE rept010.r10_linea,
				sublinea	LIKE rept010.r10_sub_linea,
				grupo		LIKE rept010.r10_cod_grupo,
				clase		LIKE rept010.r10_cod_clase,
				codigo		LIKE rept010.r10_codigo,
				marca		LIKE rept010.r10_marca,
				nombre		LIKE rept010.r10_nombre,
				bodega		LIKE rept002.r02_codigo,
				stock_local	DECIMAL(10,2),
				stock_nac	DECIMAL(10,2),
				stock_total	DECIMAL(10,2),
				unidad		LIKE rept010.r10_uni_med,
				precio		LIKE rept010.r10_precio_mb
			END RECORD
DEFINE r_r02		RECORD LIKE rept002.*
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
	BOTTOM MARGIN	2
	PAGE LENGTH	66

FORMAT

PAGE HEADER
	LET escape	= 27		# Iniciar sec. impresi¢n
	LET act_comp	= 15		# Activar Comprimido.
	LET desact_comp	= 18		# Cancelar Comprimido.
	LET modulo      = "MODULO: INVENTARIO"
	LET usuario     = "USUARIO: ", vg_usuario CLIPPED
	CALL fl_justifica_titulo('D', usuario, 19) RETURNING usuario
	CALL fl_justifica_titulo('C', 'LISTADO DE EXISTENCIAS', 80)
		RETURNING titulo
	CALL fl_justifica_titulo('I', tit_mes, 10) RETURNING tit_mes
	print ASCII escape;
	print ASCII act_comp
	PRINT COLUMN 001, rg_cia.g01_razonsocial,
	      COLUMN 122, "PAGINA: ", PAGENO USING "&&&"
	PRINT COLUMN 001, "SUCURSAL : ", rm_g02.g02_nombre,
	      COLUMN 039, titulo CLIPPED,
	      COLUMN 126, UPSHIFT(vg_proceso)
	SKIP 1 LINES 
	PRINT COLUMN 044, "** MONEDA : ", vm_moneda, ' ', vm_moneda_des
	IF rm_r11.r11_bodega IS NOT NULL THEN
		CALL fl_lee_bodega_rep(vg_codcia, rm_r11.r11_bodega)
			RETURNING r_r02.*
		PRINT COLUMN 044, "** BODEGA : ", rm_r11.r11_bodega, ' ',
							r_r02.r02_nombre
	ELSE
		PRINT 1 SPACES
	END IF
	PRINT COLUMN 044, "** ANIO   : ", rm_r31.r31_ano USING "&&&&"
	PRINT COLUMN 044, "** MES    : ", rm_r31.r31_mes USING "&&", ' ',tit_mes
	SKIP 1 LINES 
	PRINT COLUMN 001,"FECHA DE IMPRESION: ", TODAY USING "dd-mm-yyyy",
		1 SPACES, TIME,
	      COLUMN 114, usuario
	PRINT "------------------------------------------------------------------------------------------------------------------------------------"
	PRINT COLUMN 082, "     STOCK";
	IF r_rep.stock_nac IS NOT NULL THEN
		PRINT COLUMN 093, "STOCK OTRA";
	ELSE
		PRINT COLUMN 093, "          ";
	END IF
	PRINT COLUMN 104, "     STOCK"
	PRINT COLUMN 001, "CODIGO",
	      COLUMN 008, "MARCA",
	      COLUMN 016, "DESCRIPCION",
	      COLUMN 082, "     LOCAL";
	IF r_rep.stock_nac IS NOT NULL THEN
		PRINT COLUMN 093, " LOCALIDAD";
	ELSE
		PRINT COLUMN 093, "          ";
	END IF
	PRINT COLUMN 104, "     TOTAL",
	      COLUMN 115, " UNIDAD";
	IF vm_precios = 'S' THEN
		PRINT COLUMN 123, "    PRECIO"
	ELSE
		PRINT 1 SPACES
	END IF
	PRINT "------------------------------------------------------------------------------------------------------------------------------------"

BEFORE GROUP OF r_rep.linea
	LET tot_sto_l_div = 0
	LET tot_sto_n_div = 0
	LET tot_sto_t_div = 0
	CALL fl_lee_linea_rep(vg_codcia, r_rep.linea) RETURNING r_r03.*
	PRINT COLUMN 002, "DIVISION: ", r_rep.linea,
	      COLUMN 022, r_r03.r03_nombre

BEFORE GROUP OF r_rep.sublinea
	LET tot_sto_l_lin = 0
	LET tot_sto_n_lin = 0
	LET tot_sto_t_lin = 0
	CALL fl_lee_sublinea_rep(vg_codcia, r_rep.linea, r_rep.sublinea)
		RETURNING r_r70.*
	PRINT COLUMN 002, "LINEA   : ", r_rep.sublinea,
	      COLUMN 022, r_r70.r70_desc_sub

BEFORE GROUP OF r_rep.grupo
	LET tot_sto_l_grp = 0
	LET tot_sto_n_grp = 0
	LET tot_sto_t_grp = 0
	CALL fl_lee_grupo_rep(vg_codcia, r_rep.linea, r_rep.sublinea,
				r_rep.grupo)
		RETURNING r_r71.*
	PRINT COLUMN 002, "GRUPO   : ", r_rep.grupo,
	      COLUMN 022, r_r71.r71_desc_grupo

BEFORE GROUP OF r_rep.clase
	NEED 5 LINES
	LET tot_sto_l_cla = 0
	LET tot_sto_n_cla = 0
	LET tot_sto_t_cla = 0
	CALL fl_lee_clase_rep(vg_codcia, r_rep.linea, r_rep.sublinea,
				r_rep.grupo, r_rep.clase)
		RETURNING r_r72.*
	IF tot_sto_t_grp = 0 THEN
		SKIP 1 LINES 
	END IF
	PRINT COLUMN 002, "CLASE   : ", r_rep.clase,
	      COLUMN 022, r_r72.r72_desc_clase
	PRINT "-------------------------------------------------------------------------------------------------------------------------"

ON EVERY ROW
	NEED 5 LINES
	PRINT COLUMN 001, r_rep.codigo[1,6]	USING "###&&&",
	      COLUMN 008, r_rep.marca,
	      COLUMN 016, r_rep.nombre[1,65] CLIPPED,
	      COLUMN 082, r_rep.stock_local	USING "----,--&.#";
	IF r_rep.stock_nac IS NOT NULL THEN
		PRINT COLUMN 093, r_rep.stock_nac	USING "----,--&.#";
	ELSE
		PRINT COLUMN 093, r_rep.stock_nac	USING "####,###.#";
	END IF
	PRINT COLUMN 104, r_rep.stock_total	USING "----,--&.#",
	      COLUMN 115, fl_justifica_titulo('D', r_rep.unidad, 7);
	IF vm_precios = 'S' THEN
		PRINT COLUMN 123, r_rep.precio	USING "###,##&.##"
	ELSE
		PRINT COLUMN 123, r_rep.precio	USING "###,###.##"
	END IF
	LET tot_sto_l_cla = tot_sto_l_cla + r_rep.stock_local
	LET tot_sto_n_cla = tot_sto_n_cla + r_rep.stock_nac
	LET tot_sto_t_cla = tot_sto_t_cla + r_rep.stock_total
	LET tot_sto_l_grp = tot_sto_l_grp + tot_sto_l_cla
	LET tot_sto_n_grp = tot_sto_n_grp + tot_sto_n_cla
	LET tot_sto_t_grp = tot_sto_t_grp + tot_sto_t_cla
	LET tot_sto_l_lin = tot_sto_l_lin + tot_sto_l_grp
	LET tot_sto_n_lin = tot_sto_n_lin + tot_sto_n_grp
	LET tot_sto_t_lin = tot_sto_t_lin + tot_sto_t_grp
	LET tot_sto_l_div = tot_sto_l_div + tot_sto_l_lin
	LET tot_sto_n_div = tot_sto_n_div + tot_sto_n_lin
	LET tot_sto_t_div = tot_sto_t_div + tot_sto_t_lin
	LET tot_sto_l_gen = tot_sto_l_gen + tot_sto_l_div
	LET tot_sto_n_gen = tot_sto_n_gen + tot_sto_n_div
	LET tot_sto_t_gen = tot_sto_t_gen + tot_sto_t_div

AFTER GROUP OF r_rep.clase
	NEED 3 LINES
	PRINT COLUMN 082, "----------";
	IF r_rep.stock_nac IS NOT NULL THEN
		PRINT COLUMN 093, "----------";
	END IF
	PRINT COLUMN 104, "----------"
	PRINT COLUMN 058, "TOTALES DE LA CLASE ==> ",
	      COLUMN 082, tot_sto_l_cla		USING "----,--&.#";
	IF r_rep.stock_nac IS NOT NULL THEN
		PRINT COLUMN 093, tot_sto_n_cla		USING "----,--&.#";
	END IF
	PRINT COLUMN 104, tot_sto_t_cla		USING "----,--&.#"
	SKIP 1 LINES
	
{--
AFTER GROUP OF r_rep.grupo
	NEED 3 LINES
	PRINT COLUMN 082, "----------",
	      COLUMN 093, "----------",
	      COLUMN 104, "----------"
	PRINT COLUMN 060, "TOTALES DEL GRUPO ==> ",
	      COLUMN 082, tot_sto_l_grp		USING "----,--&.#",
	      COLUMN 093, tot_sto_n_grp		USING "----,--&.#",
	      COLUMN 104, tot_sto_t_grp		USING "----,--&.#"
	SKIP 1 LINES

AFTER GROUP OF r_rep.sublinea
	NEED 3 LINES
	PRINT COLUMN 082, "----------",
	      COLUMN 093, "----------",
	      COLUMN 104, "----------"
	PRINT COLUMN 058, "TOTALES DE LA LINEA ==> ",
	      COLUMN 082, tot_sto_l_lin		USING "-------&.#",
	      COLUMN 093, tot_sto_n_lin		USING "-------&.#",
	      COLUMN 104, tot_sto_t_lin		USING "-------&.#"
	SKIP 1 LINES

AFTER GROUP OF r_rep.linea
	NEED 3 LINES
	PRINT COLUMN 082, "----------",
	      COLUMN 093, "----------",
	      COLUMN 104, "----------"
	PRINT COLUMN 058, "TOTALES DE DIVISION ==> ",
	      COLUMN 082, tot_sto_l_div		USING "-------&.#",
	      COLUMN 093, tot_sto_n_div		USING "-------&.#",
	      COLUMN 104, tot_sto_t_div		USING "-------&.#"
	SKIP 1 LINES
--}

ON LAST ROW
	{--
	NEED 2 LINES
	PRINT COLUMN 082, "----------",
	      COLUMN 093, "----------",
	      COLUMN 104, "----------"
	PRINT COLUMN 060, "TOTALES GENERALES ==> ",
	      COLUMN 082, tot_sto_l_gen		USING "-------&.#",
	      COLUMN 093, tot_sto_n_gen		USING "-------&.#",
	      COLUMN 104, tot_sto_t_gen		USING "-------&.#";
	--}
	print ASCII escape;
	print ASCII desact_comp

END REPORT



FUNCTION borrar_cabecera()

CLEAR FORM
INITIALIZE rm_r10.*, rm_r11.*, rm_r31.*, vm_moneda TO NULL

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
