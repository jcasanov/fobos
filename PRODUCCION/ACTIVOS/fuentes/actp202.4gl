--------------------------------------------------------------------------------
-- Titulo           : actp202.4gl -- Venta / Baja de Activos Fijos
-- Elaboración      : 22-Ene-2007
-- Autor            : NPC
-- Formato Ejecución: fglrun actp202 base módulo compañía
-- Ultima Corrección: 
-- Motivo Corrección: 
--------------------------------------------------------------------------------
                                                                                
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE rm_a00		RECORD LIKE actt000.*
DEFINE rm_b00		RECORD LIKE ctbt000.*
DEFINE rm_b12		RECORD LIKE ctbt012.*
DEFINE vm_num_baja	INTEGER
DEFINE vm_num_venta	INTEGER
DEFINE vm_tran_ini	INTEGER
DEFINE vm_tran_fin	INTEGER
DEFINE vm_cod_tran1	LIKE actt012.a12_codigo_tran
DEFINE vm_cod_tran2	LIKE actt012.a12_codigo_tran
DEFINE vm_cod_tran3	LIKE actt012.a12_codigo_tran
DEFINE vm_cod_tran4	LIKE actt012.a12_codigo_tran
DEFINE vm_sub_dep	LIKE ctbt004.b04_subtipo
DEFINE vm_sub_baj	LIKE ctbt004.b04_subtipo
DEFINE vm_sub_ven	LIKE ctbt004.b04_subtipo
DEFINE vm_sub_cos	LIKE ctbt004.b04_subtipo
DEFINE rm_orden 	ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1	SMALLINT
DEFINE vm_columna_2	SMALLINT
DEFINE rm_par		RECORD
				a10_localidad	LIKE actt010.a10_localidad,
				g02_nombre	LIKE gent002.g02_nombre,
				cod_grupo	LIKE actt001.a01_grupo_act,
				desc_grupo	LIKE actt001.a01_nombre,
				codigo_bien	LIKE actt010.a10_codigo_bien,
				desc_bien	LIKE actt010.a10_descripcion,
				fecha_ini	LIKE actt010.a10_fecha_comp,
				fecha_fin	LIKE actt010.a10_fecha_comp,
				estado		LIKE actt010.a10_estado,
				tit_estado	LIKE actt006.a06_descripcion
			END RECORD
DEFINE rm_baj		RECORD
				fec_baj		DATE,
				glosa		LIKE ctbt012.b12_glosa
			END RECORD
DEFINE rm_ven		RECORD
				fec_vta		DATE,
				aux_pago	LIKE ctbt010.b10_cuenta,
				glosa		LIKE ctbt012.b12_glosa,
				valor_suge	DECIMAL(14,2),
				valor_vta	DECIMAL(14,2),
				valor_iva	DECIMAL(14,2),
				total		DECIMAL(14,2)
			END RECORD
DEFINE rm_act		ARRAY [10000] OF RECORD
				a10_codigo_bien	LIKE actt010.a10_codigo_bien,
				a10_descripcion	LIKE actt010.a10_descripcion,
				a10_fecha_comp	LIKE actt010.a10_fecha_comp,
				a10_porc_deprec	LIKE actt010.a10_porc_deprec,
				a10_valor_mb	LIKE actt010.a10_valor_mb,
				a10_val_dep_mb	LIKE actt010.a10_val_dep_mb,
				a10_estado	LIKE actt010.a10_estado
			END RECORD
DEFINE r_mov		ARRAY[200] OF RECORD
				a12_codigo_tran	LIKE actt012.a12_codigo_tran,
				a12_numero_tran	LIKE actt012.a12_numero_tran,
				a12_tipcomp_gen	LIKE actt012.a12_tipcomp_gen,
				a12_numcomp_gen	LIKE actt012.a12_numcomp_gen,
				a12_fecing	DATE,
				a12_referencia	LIKE actt012.a12_referencia,
				a12_porc_deprec	LIKE actt012.a12_porc_deprec,
				a12_valor_mb	LIKE actt012.a12_valor_mb
			END RECORD
DEFINE vm_num_rows      INTEGER
DEFINE vm_max_rows      INTEGER
DEFINE tot_valor_mb	DECIMAL(14,2)
DEFINE tot_val_dep_mb	DECIMAL(14,2)
DEFINE vm_fec_pro	DATE



MAIN

DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/actp202.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 3 THEN   -- Validar # parámetros correcto
        CALL fl_mostrar_mensaje('Número de parametros incorrecto.', 'stop')
        EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_proceso = 'actp202'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()
--#CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()  

END MAIN



FUNCTION funcion_master()

CALL fl_nivel_isolation()
CREATE TEMP TABLE te_depre
	(te_grupo		SMALLINT,
	 te_codigo_bien		INTEGER,
	 te_cod_tran		CHAR(2),
	 te_subtipo		SMALLINT,
	 te_cuenta		CHAR(12),
	 te_valor		DECIMAL(14,2))
OPEN WINDOW w_actf202_1 AT 03, 02 WITH 22 ROWS, 80 COLUMNS
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE FIRST,
                  BORDER, MESSAGE LINE LAST - 1)
OPEN FORM f_actf202_1 FROM '../forms/actf202_1'
DISPLAY FORM f_actf202_1
INITIALIZE vm_tran_ini, vm_tran_fin, rm_b12.* TO NULL
LET vm_cod_tran1 = 'DP'
LET vm_cod_tran2 = 'BA'
LET vm_cod_tran3 = 'VE'
LET vm_cod_tran4 = 'BV'
LET vm_sub_dep   = 61
LET vm_sub_baj   = 62
LET vm_sub_ven   = 63
LET vm_sub_cos   = 64
LET vm_max_rows  = 10000
LET vm_num_rows  = 0
CALL mostrar_botones()
CALL muestra_contadores_det(0, vm_num_rows)
CALL control_principal()
DROP TABLE te_depre
CLOSE WINDOW w_actf202_1

END FUNCTION



FUNCTION control_principal()

CALL fl_lee_compania_contabilidad(vg_codcia) RETURNING rm_b00.*
IF rm_b00.b00_compania IS NULL THEN
	DROP TABLE te_depre
	CALL fl_mostrar_mensaje('No existe ninguna compañía configurada en CONTABILIDAD.', 'stop')
	CLOSE WINDOW w_actf202_1
	EXIT PROGRAM
END IF
CALL fl_lee_compania_activos(vg_codcia) RETURNING rm_a00.*
IF rm_a00.a00_compania IS NULL THEN
	DROP TABLE te_depre
	CALL fl_mostrar_mensaje('No existe ninguna compañía configurada en ACTIVOS FIJOS.', 'stop')
	CLOSE WINDOW w_actf202_1
	EXIT PROGRAM
END IF
LET vm_fec_pro = MDY(rm_a00.a00_mespro, 01, rm_a00.a00_anopro) - 1 UNITS DAY
CALL borrar_cabecera()
SELECT NVL(MIN(a10_fecha_comp), MDY(01, 01, 1990))
	INTO rm_par.fecha_ini
	FROM actt010
	WHERE a10_compania  = vg_codcia
	  AND a10_estado   IN ("S", "D", "V", "E", "R")
LET rm_par.fecha_fin = TODAY
LET rm_par.estado    = 'X'
CALL muestra_estado(rm_par.estado, 1) RETURNING rm_par.tit_estado
WHILE TRUE
	LET vm_num_rows = 0
	CALL muestra_contadores_det(0, vm_num_rows)
	CALL muestra_estado(rm_par.estado, 1) RETURNING rm_par.tit_estado
	CALL borrar_detalle()
	CALL lee_parametros()
	IF int_flag THEN
		EXIT WHILE
	END IF
	CALL control_proceso()
END WHILE

END FUNCTION



FUNCTION control_proceso()

WHILE TRUE
	IF NOT cargar_datos_detalle() THEN
		DROP TABLE tmp_det
		EXIT WHILE
	END IF
	IF ejecutar_proceso_mostrar_detalle() THEN
		DROP TABLE tmp_det
		CONTINUE WHILE
	END IF
	DROP TABLE tmp_det
	EXIT WHILE
END WHILE

END FUNCTION



FUNCTION lee_parametros()
DEFINE r_a01		RECORD LIKE actt001.*
DEFINE r_a10		RECORD LIKE actt010.*
DEFINE r_g02		RECORD LIKE gent002.*
DEFINE fec_ini, fec_fin	LIKE actt010.a10_fecha_comp
DEFINE est		LIKE actt010.a10_estado

LET int_flag = 0
INPUT BY NAME rm_par.*
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		LET int_flag = 1
		EXIT INPUT
	ON KEY(F2)
		IF INFIELD(a10_localidad) THEN
			CALL fl_ayuda_localidad(vg_codcia) 
				RETURNING r_g02.g02_localidad, r_g02.g02_nombre
			IF r_g02.g02_localidad IS NOT NULL THEN
				LET rm_par.a10_localidad = r_g02.g02_localidad
				LET rm_par.g02_nombre    = r_g02.g02_nombre
				DISPLAY BY NAME rm_par.a10_localidad,
						r_g02.g02_nombre
			END IF
		END IF
		IF INFIELD(cod_grupo) THEN
			CALL fl_ayuda_grupo_activo(vg_codcia)
				RETURNING r_a01.a01_grupo_act, r_a01.a01_nombre
			IF r_a01.a01_grupo_act IS NOT NULL THEN
				LET rm_par.cod_grupo  = r_a01.a01_grupo_act
				LET rm_par.desc_grupo = r_a01.a01_nombre
				DISPLAY BY NAME rm_par.cod_grupo,								rm_par.desc_grupo
			END IF
		END IF
		IF INFIELD(codigo_bien) THEN
			CALL fl_ayuda_codigo_bien(vg_codcia, rm_par.cod_grupo,
							NULL, 'X', 1)
				RETURNING r_a10.a10_codigo_bien,
					  r_a10.a10_descripcion
			IF r_a10.a10_codigo_bien IS NOT NULL THEN
				LET rm_par.codigo_bien = r_a10.a10_codigo_bien
				LET rm_par.desc_bien   = r_a10.a10_descripcion
				DISPLAY BY NAME rm_par.codigo_bien,
						rm_par.desc_bien
			END IF
		END IF
		IF INFIELD(estado) THEN
			CALL fl_ayuda_estado_activos(vg_codcia, 0)
				RETURNING rm_par.estado, rm_par.tit_estado
			IF rm_par.estado IS NOT NULL THEN
				DISPLAY BY NAME rm_par.estado
				CALL muestra_estado(rm_par.estado, 1)
					RETURNING rm_par.tit_estado
			END IF
		END IF
		LET int_flag = 0
	BEFORE FIELD fecha_ini
		LET fec_ini = rm_par.fecha_ini
	BEFORE FIELD fecha_fin
		LET fec_fin = rm_par.fecha_fin
	BEFORE FIELD estado
		LET est = rm_par.estado
	AFTER FIELD a10_localidad
		IF rm_par.a10_localidad IS NOT NULL THEN
			CALL fl_lee_localidad(vg_codcia, rm_par.a10_localidad)
				RETURNING r_g02.*
			IF r_g02.g02_localidad IS NULL THEN
				CALL fl_mostrar_mensaje('No existe esta localidad.', 'exclamation')
				NEXT FIELD a10_localidad
			END IF	
			LET rm_par.g02_nombre = r_g02.g02_nombre
		ELSE
			LET rm_par.g02_nombre = NULL
		END IF
		DISPLAY BY NAME rm_par.g02_nombre 
	AFTER FIELD cod_grupo
		IF rm_par.cod_grupo IS NOT NULL THEN
			CALL fl_lee_grupo_activo(vg_codcia, rm_par.cod_grupo)
				RETURNING r_a01.* 
			IF r_a01.a01_grupo_act IS NULL THEN
				CALL fl_mostrar_mensaje('No existe este Grupo de Activos Fijos en la compañía.', 'exclamation')
                                NEXT FIELD cod_grupo
                        END IF
			LET rm_par.desc_grupo = r_a01.a01_nombre
		ELSE
			LET rm_par.desc_grupo = NULL
		END IF
		DISPLAY BY NAME rm_par.desc_grupo
	AFTER FIELD codigo_bien
		IF rm_par.codigo_bien IS NOT NULL THEN
			CALL fl_lee_codigo_bien(vg_codcia, rm_par.codigo_bien)
				RETURNING r_a10.*
			IF r_a10.a10_codigo_bien IS NULL THEN
				CALL fl_mostrar_mensaje('No existe este Activo Fijo en la compañía.', 'exclamation')
                                NEXT FIELD codigo_bien
                        END IF
			LET rm_par.desc_bien = r_a10.a10_descripcion
			DISPLAY BY NAME rm_par.desc_bien
			IF r_a10.a10_estado <> 'D' AND
			   r_a10.a10_estado <> 'S' AND
			   r_a10.a10_estado <> 'E' AND
			   r_a10.a10_estado <> 'R' AND
			   r_a10.a10_estado <> 'V'
			THEN
				CALL fl_mostrar_mensaje('El Activo Fijo debe tener estado de DEPRECIADO, CON STOCK, DADO BAJA, REASIGNADO o VENDIDO.', 'exclamation')
                                NEXT FIELD codigo_bien
			END IF
			IF r_a10.a10_fecha_comp IS NULL THEN
				CALL fl_mostrar_mensaje('El Activo Fijo debe tener fecha de compra.', 'exclamation')
                                NEXT FIELD codigo_bien
			END IF
			IF r_a10.a10_valor_mb = 0 THEN
				CALL fl_mostrar_mensaje('El Activo Fijo debe tener valor de compra mayor a CERO.', 'exclamation')
                                NEXT FIELD codigo_bien
			END IF
		ELSE
			LET rm_par.desc_bien = NULL
			DISPLAY BY NAME rm_par.desc_bien
		END IF
	AFTER FIELD fecha_ini
		IF rm_par.fecha_ini IS NULL THEN
			LET rm_par.fecha_ini = fec_ini
			DISPLAY BY NAME rm_par.fecha_ini
		END IF
		IF rm_par.fecha_ini > TODAY THEN
			CALL fl_mostrar_mensaje('La fecha inicial de compra no puede ser mayor a la fecha de hoy.', 'exclamation')
			NEXT FIELD fecha_ini
		END IF
	AFTER FIELD fecha_fin
		IF rm_par.fecha_fin IS NULL THEN
			LET rm_par.fecha_fin = fec_fin
			DISPLAY BY NAME rm_par.fecha_fin
		END IF
		IF rm_par.fecha_fin > TODAY THEN
			CALL fl_mostrar_mensaje('La fecha final de compra no puede ser mayor a la fecha de hoy.', 'exclamation')
			NEXT FIELD fecha_fin
		END IF
	AFTER FIELD estado
		IF rm_par.estado IS NULL THEN
			LET rm_par.estado = est
		END IF
		CALL muestra_estado(rm_par.estado, 1)
			RETURNING rm_par.tit_estado
	AFTER INPUT
		IF rm_par.fecha_ini > rm_par.fecha_fin THEN
			CALL fl_mostrar_mensaje('La fecha inicial de compra no puede ser mayor a la fecha final de compra.', 'exclamation')
			NEXT FIELD fecha_ini
		END IF
		IF rm_par.cod_grupo IS NOT NULL AND
		   rm_par.codigo_bien IS NOT NULL
		THEN
			IF r_a01.a01_grupo_act <> r_a10.a10_grupo_act THEN
				CALL fl_mostrar_mensaje('Este Activo Fijo no pertenece a este Grupo de Activos Fijos.', 'exclamation')
				NEXT FIELD codigo_bien
			END IF
		END IF
		IF rm_par.estado <> 'D' AND rm_par.estado <> 'S' AND
		   rm_par.estado <> 'E' AND rm_par.estado <> 'R' AND
		   rm_par.estado <> 'V' AND rm_par.estado <> 'X'
		THEN
			CALL fl_mostrar_mensaje('El Activo Fijo debe tener estado de DEPRECIADO, CON STOCK, DADO BAJA, REASIGNADO o VENDIDO.', 'exclamation')
			CONTINUE INPUT
		END IF
END INPUT

END FUNCTION



FUNCTION cargar_datos_detalle()
DEFINE query		CHAR(2000)
DEFINE expr_loc		VARCHAR(100)
DEFINE expr_grp		VARCHAR(100)
DEFINE expr_act		VARCHAR(100)
DEFINE i		INTEGER

LET expr_loc = NULL
IF rm_par.a10_localidad IS NOT NULL THEN
	LET expr_loc = '   AND a10_localidad   = ', rm_par.a10_localidad
END IF
LET expr_grp = NULL
IF rm_par.cod_grupo IS NOT NULL THEN
	LET expr_grp = '   AND a10_grupo_act   = ', rm_par.cod_grupo
END IF
LET expr_act = NULL
IF rm_par.codigo_bien IS NOT NULL THEN
	LET expr_act = '   AND a10_codigo_bien = ', rm_par.codigo_bien
END IF
LET query = 'SELECT a10_codigo_bien, a10_descripcion, a10_fecha_comp, ',
			'a10_porc_deprec, a10_valor_mb, a10_tot_dep_mb, ',
			'a10_estado ',
		' FROM actt010 ',
		' WHERE a10_compania    = ', vg_codcia,
		expr_loc CLIPPED,
		expr_grp CLIPPED,
		expr_act CLIPPED,
		fl_retorna_expr_estado_act(vg_codcia, rm_par.estado, 1) CLIPPED,
		'   AND a10_fecha_comp  BETWEEN "', rm_par.fecha_ini,
					 '" AND "', rm_par.fecha_fin, '"',
		' INTO TEMP tmp_det '
PREPARE exec_tmp FROM query
EXECUTE exec_tmp
FOR i = 1 TO 10
	LET rm_orden[i] = '' 
END FOR
LET vm_columna_1           = 2
LET vm_columna_2           = 3
LET rm_orden[vm_columna_1] = 'ASC'
LET rm_orden[vm_columna_2] = 'DESC'
RETURN cargar_arreglo_det()

END FUNCTION



FUNCTION ejecutar_proceso_mostrar_detalle()
DEFINE r_a01		RECORD LIKE actt001.*
DEFINE r_a10		RECORD LIKE actt010.*
DEFINE col, i, j	INTEGER
DEFINE contin		SMALLINT
DEFINE mensaje		VARCHAR(150)

LET contin = 0
WHILE TRUE
	IF NOT cargar_arreglo_det() THEN
		EXIT WHILE
	END IF
	DISPLAY BY NAME tot_valor_mb, tot_val_dep_mb
	LET int_flag = 0
	CALL set_count(vm_num_rows)
	DISPLAY ARRAY rm_act TO rm_act.*
		ON KEY(INTERRUPT)
			LET int_flag = 1
			EXIT DISPLAY
		ON KEY(F5)
			LET i = arr_curr()
			CALL ver_bien(rm_act[i].a10_codigo_bien)
			LET int_flag = 0
		ON KEY(F6)
			LET i = arr_curr()
			IF rm_act[i].a10_estado <> 'D' AND
			   rm_act[i].a10_estado <> 'S'
			THEN
				CONTINUE DISPLAY
			END IF
			IF r_a01.a01_depreciable = 'N' THEN
				CONTINUE DISPLAY
			END IF
			IF (rm_act[i].a10_estado <> 'D') THEN
				IF (vm_fec_pro <
				   (MDY(MONTH(TODAY), 01, YEAR(TODAY))
					- 1 UNITS DAY))
				THEN
					LET mensaje = 'Al momento se encuentra',
						' DEPRECIADO TOTALMENTE el ',
						'modulo de ACTIVOS FIJOS, ',
						' hasta la fecha: ',
						vm_fec_pro USING 'dd-mm-yyyy',
						'.'
					CALL fl_mostrar_mensaje(mensaje, 'info')
					--CALL fl_mostrar_mensaje('No puede DAR DE BAJA a ningun ACTIVO FIJO mientras no se haya DEPRECIADO TOTALMENTE el mes anterior.', 'exclamation')
					--CONTINUE DISPLAY
				END IF
			END IF
			CALL control_dar_baja(rm_act[i].a10_codigo_bien,
						rm_act[i].a10_estado)
			IF int_flag THEN
				LET int_flag = 0
				CONTINUE DISPLAY
			END IF
			LET int_flag = 0
			LET contin   = 1
			EXIT DISPLAY
		ON KEY(F7)
			LET i = arr_curr()
			IF rm_act[i].a10_estado <> 'D' AND
			   rm_act[i].a10_estado <> 'S'
			THEN
				CONTINUE DISPLAY
			END IF
			IF (rm_act[i].a10_estado <> 'D') THEN
				IF vm_fec_pro <
				  (MDY(MONTH(TODAY), 01, YEAR(TODAY))
					- 1 UNITS DAY)
				THEN
					LET mensaje = 'Al momento se encuentra',
						' DEPRECIADO TOTALMENTE el ',
						'modulo de ACTIVOS FIJOS, ',
						' hasta la fecha: ',
						vm_fec_pro USING 'dd-mm-yyyy',
						'.'
					CALL fl_mostrar_mensaje(mensaje, 'info')
					--CALL fl_mostrar_mensaje('No puede VENDER ningun ACTIVO FIJO mientras no se haya DEPRECIADO TOTALMENTE el mes anterior.', 'exclamation')
					--CONTINUE DISPLAY
				END IF
			END IF
			CALL control_vender(rm_act[i].a10_codigo_bien,
						rm_act[i].a10_estado)
			IF int_flag THEN
				LET int_flag = 0
				CONTINUE DISPLAY
			END IF
			LET int_flag = 0
			LET contin   = 1
			EXIT DISPLAY
		ON KEY(F8)
			LET i = arr_curr()
			CALL control_movimientos(rm_act[i].a10_codigo_bien)
			LET int_flag  = 0
			FOR i = 1 TO 10
				LET rm_orden[i] = '' 
			END FOR
			LET vm_columna_1           = 1
			LET vm_columna_2           = 3
			LET rm_orden[vm_columna_1] = 'ASC'
			LET rm_orden[vm_columna_2] = 'DESC'
		ON KEY(F15)
			LET col      = 1
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F16)
			LET col      = 2
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F17)
			LET col      = 3
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F18)
			LET col      = 4
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F19)
			LET col      = 5
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F20)
			LET col      = 6
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F21)
			LET col      = 7
			LET int_flag = 2
			EXIT DISPLAY
		BEFORE DISPLAY 
			--#CALL dialog.keysetlabel("ACCEPT","")
		BEFORE ROW
			LET i = arr_curr()
			LET j = scr_line()
			CALL muestra_contadores_det(i, vm_num_rows)
			CALL muestra_estado(rm_act[i].a10_estado, 1)
				RETURNING rm_par.tit_estado
			DISPLAY rm_act[i].a10_codigo_bien TO codigo_bien
			DISPLAY rm_act[i].a10_descripcion TO desc_bien
			CALL fl_lee_codigo_bien(vg_codcia,
						rm_act[i].a10_codigo_bien)
				RETURNING r_a10.*
			CALL fl_lee_grupo_activo(r_a10.a10_compania,
							r_a10.a10_grupo_act)
				RETURNING r_a01.*
			IF rm_act[i].a10_estado = 'D' OR
			   rm_act[i].a10_estado = 'S'
			THEN
				--#CALL dialog.keysetlabel("F6","Dar de Baja")
			ELSE
				--#CALL dialog.keysetlabel("F6","")
			END IF
			IF r_a01.a01_depreciable = 'S' THEN
				--#CALL dialog.keysetlabel("F6","Dar de Baja")
			ELSE
				--#CALL dialog.keysetlabel("F6","")
			END IF
			IF rm_act[i].a10_estado = 'S' OR
			   rm_act[i].a10_estado = 'D'
			THEN
				--#CALL dialog.keysetlabel("F7","Vender el Bien")
			ELSE
				--#CALL dialog.keysetlabel("F7","")
			END IF
		AFTER DISPLAY 
			CONTINUE DISPLAY
	END DISPLAY
	IF int_flag = 1 OR contin = 1 THEN
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
RETURN contin

END FUNCTION



FUNCTION cargar_arreglo_det()
DEFINE query		CHAR(300)
DEFINE i		INTEGER

LET query = 'SELECT * FROM tmp_det ',
		' ORDER BY ', vm_columna_1, ' ', rm_orden[vm_columna_1],
		        ', ', vm_columna_2, ' ', rm_orden[vm_columna_2]
PREPARE cons_tmp FROM query
DECLARE q_carga CURSOR FOR cons_tmp
LET tot_valor_mb   = 0
LET tot_val_dep_mb = 0
LET i              = 1
FOREACH q_carga INTO rm_act[i].*
	LET tot_valor_mb   = tot_valor_mb   + rm_act[i].a10_valor_mb
	LET tot_val_dep_mb = tot_val_dep_mb + rm_act[i].a10_val_dep_mb
	LET i              = i              + 1
	IF i > vm_max_rows THEN
		EXIT FOREACH
	END IF
END FOREACH
LET i = i - 1
IF i = 0 THEN
	CALL fl_mensaje_consulta_sin_registros()
	RETURN 0
END IF
LET vm_num_rows = i
RETURN 1

END FUNCTION



FUNCTION mostrar_botones()

DISPLAY "Código"		TO tit_col1
DISPLAY "Descripción del Bien"	TO tit_col2
DISPLAY "Fecha Comp."		TO tit_col3
DISPLAY "% Dp."			TO tit_col4
DISPLAY "Valor Bien"		TO tit_col5
DISPLAY "Valor Depr."		TO tit_col6
DISPLAY "E"			TO tit_col7

END FUNCTION



FUNCTION muestra_contadores_det(num_row, max_row)
DEFINE num_row, max_row	SMALLINT

DISPLAY BY NAME num_row, max_row

END FUNCTION



FUNCTION borrar_cabecera()

INITIALIZE rm_par.* TO NULL
LET tot_valor_mb   = 0
LET tot_val_dep_mb = 0
CLEAR cod_grupo, desc_grupo, codigo_bien, desc_bien, fecha_ini, fecha_fin,
	num_row, max_row, estado, tit_estado

END FUNCTION



FUNCTION borrar_detalle()
DEFINE i		SMALLINT

FOR i = 1 TO vm_max_rows
	INITIALIZE rm_act[i].* TO NULL
END FOR
FOR i = 1 TO fgl_scr_size("rm_act")
	CLEAR rm_act[i].*
END FOR
CLEAR codigo_bien, desc_bien, tit_estado, tot_valor_mb, tot_val_dep_mb

END FUNCTION



FUNCTION muestra_estado(estado, flag)
DEFINE estado		LIKE actt010.a10_estado
DEFINE flag		SMALLINT
DEFINE r_a06		RECORD LIKE actt006.*
DEFINE tit_est		LIKE actt006.a06_descripcion

CALL fl_lee_estado_activos(vg_codcia, estado) RETURNING r_a06.*
IF r_a06.a06_compania IS NULL THEN
	CALL fl_mostrar_mensaje('Estado no existe.', 'exclamation')
END IF
LET tit_est = r_a06.a06_descripcion
IF flag THEN
	DISPLAY BY NAME estado
	DISPLAY tit_est TO tit_estado
END IF
RETURN tit_est

END FUNCTION



FUNCTION ejecuta_comando(modulo, mod, prog, param)
DEFINE modulo		VARCHAR(15)
DEFINE mod		LIKE gent050.g50_modulo
DEFINE prog		VARCHAR(10)
DEFINE param		VARCHAR(60)
DEFINE comando          VARCHAR(250)
DEFINE run_prog		VARCHAR(10)

LET run_prog = '; fglrun '
IF vg_gui = 0 THEN
	LET run_prog = '; fglgo '
END IF
LET comando = 'cd ..', vg_separador, '..', vg_separador, modulo, vg_separador,
		'fuentes', vg_separador, run_prog, prog, ' ', vg_base, ' ',
		mod, ' ', vg_codcia, ' ', param
RUN comando

END FUNCTION



FUNCTION ver_bien(activo)
DEFINE activo		LIKE actt010.a10_codigo_bien
DEFINE param		VARCHAR(60)

LET param = ' ', activo
CALL ejecuta_comando('ACTIVOS', vg_modulo, 'actp104', param)

END FUNCTION



FUNCTION control_dar_baja(activo, estado)
DEFINE activo		LIKE actt010.a10_codigo_bien
DEFINE estado		LIKE actt010.a10_estado
DEFINE r_a01		RECORD LIKE actt001.*
DEFINE r_a10		RECORD LIKE actt010.*
DEFINE val_dep_mes	LIKE actt010.a10_val_dep_mb
DEFINE val_baj		LIKE actt010.a10_valor_mb
DEFINE aux_gl		LIKE ctbt012.b12_glosa
DEFINE fec_min, fec	DATE
DEFINE resp		CHAR(6)

IF estado <> 'S' AND estado <> 'D' THEN
	CALL fl_mostrar_mensaje('Solo puede dar de baja ACTIVOS DEPRECIADOS y CON STOCK.', 'exclamation')
	RETURN
END IF
CALL fl_hacer_pregunta('Esta seguro de dar de baja a este Activo Fijo ? ', 'No')
	RETURNING resp
IF resp <> 'Yes' THEN
	LET int_flag = 1
	RETURN
END IF
OPEN WINDOW w_actf202_5 AT 06, 08 WITH 12 ROWS, 68 COLUMNS
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE FIRST,
                  BORDER, MESSAGE LINE LAST)
OPEN FORM f_actf202_5 FROM '../forms/actf202_5'
DISPLAY FORM f_actf202_5
CALL fl_lee_codigo_bien(vg_codcia, activo) RETURNING r_a10.*
CALL fl_lee_grupo_activo(r_a10.a10_compania, r_a10.a10_grupo_act)
	RETURNING r_a01.*
LET val_dep_mes = (r_a10.a10_val_dep_mb / DAY(MDY(MONTH(TODAY), 01, YEAR(TODAY))
			+ 1 UNITS MONTH - 1 UNITS DAY)) * DAY(TODAY)
LET val_baj     = r_a10.a10_valor_mb - r_a10.a10_tot_dep_mb - val_dep_mes
DISPLAY BY NAME r_a10.a10_codigo_bien, r_a10.a10_descripcion,r_a10.a10_valor_mb,
		r_a10.a10_tot_dep_mb, val_dep_mes, val_baj
INITIALIZE rm_baj.* TO NULL
CALL retorna_fec_vta_baj(r_a10.*) RETURNING rm_baj.fec_baj, fec_min
LET rm_baj.glosa = 'CIERRE DEL ACTIVO POR BAJA'
LET int_flag = 0
INPUT BY NAME rm_baj.*
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		LET int_flag = 1
		EXIT INPUT
	BEFORE FIELD fec_baj
		LET fec = rm_baj.fec_baj
	BEFORE FIELD glosa
		LET aux_gl = rm_baj.glosa
	AFTER FIELD fec_baj
		IF rm_baj.fec_baj IS NULL THEN
			LET rm_baj.fec_baj = fec
			DISPLAY BY NAME rm_baj.fec_baj
		END IF
		IF r_a01.a01_depreciable = 'S' AND rm_baj.fec_baj <= fec_min
		THEN
			CALL fl_mostrar_mensaje('La fecha de baja no puede ser menor o igual a la fecha del ultimo movimiento de este codigo de bien.', 'exclamation')
			LET rm_baj.fec_baj = fec_min + 1 UNITS DAY
			DISPLAY BY NAME rm_baj.fec_baj
			NEXT FIELD fec_baj
		END IF
		IF r_a01.a01_depreciable = 'N' THEN
			SELECT MAX(DATE(a12_fecing))
				INTO fec_min
				FROM actt012
				WHERE a12_compania    = vg_codcia
				  AND a12_codigo_tran = 'IN'
				  AND a12_codigo_bien = r_a10.a10_codigo_bien
			IF rm_baj.fec_baj <= fec_min THEN
				CALL fl_mostrar_mensaje('La fecha de baja no puede ser menor o igual a la fecha de compra de este codigo de bien.', 'exclamation')
				NEXT FIELD fec_baj
			END IF
		END IF
		IF rm_baj.fec_baj > TODAY THEN
			CALL fl_mostrar_mensaje('La fecha de baja no puede ser mayor a la fecha de hoy.', 'exclamation')
			LET rm_baj.fec_baj = TODAY
			DISPLAY BY NAME rm_baj.fec_baj
			NEXT FIELD fec_baj
		END IF
	AFTER FIELD glosa
		IF rm_baj.glosa IS NULL THEN
			LET rm_baj.glosa = aux_gl
		END IF
		DISPLAY BY NAME rm_baj.glosa
END INPUT
IF int_flag THEN
	LET int_flag = 0
	CLOSE WINDOW w_actf202_5
	RETURN
END IF
BEGIN WORK
	IF estado = 'S' THEN
		IF NOT control_depreciacion(activo, 1) THEN
			WHENEVER ERROR STOP
			ROLLBACK WORK
			DELETE FROM te_depre
			RETURN
		END IF
	END IF
	IF NOT dar_baja_venta_activo(activo, vm_cod_tran2, 1) THEN
		WHENEVER ERROR STOP
		ROLLBACK WORK
		DELETE FROM te_depre
		RETURN
	END IF
COMMIT WORK
CALL diarios_contables()
DELETE FROM te_depre
CALL fl_mostrar_mensaje('Activo Fijo dado de BAJA Ok.', 'info')
LET int_flag = 0
CLOSE WINDOW w_actf202_5
RETURN

END FUNCTION



FUNCTION control_vender(activo, estado)
DEFINE activo		LIKE actt010.a10_codigo_bien
DEFINE estado		LIKE actt010.a10_estado
DEFINE r_a01		RECORD LIKE actt001.*
DEFINE r_a10		RECORD LIKE actt010.*
DEFINE cuenta    	LIKE ctbt010.b10_cuenta
DEFINE descripcion	LIKE ctbt010.b10_descripcion
DEFINE val_dep_mes	LIKE actt010.a10_val_dep_mb
DEFINE val_vta		DECIMAL(14,2)
DEFINE fec_min, fec	DATE
DEFINE resp		CHAR(6)

CALL fl_hacer_pregunta('Esta seguro de vender este Activo Fijo ? ', 'No')
	RETURNING resp
IF resp <> 'Yes' THEN
	LET int_flag = 1
	RETURN
END IF
OPEN WINDOW w_actf202_3 AT 06, 07 WITH 16 ROWS, 69 COLUMNS
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE FIRST,
                  BORDER, MESSAGE LINE LAST)
OPEN FORM f_actf202_3 FROM '../forms/actf202_3'
DISPLAY FORM f_actf202_3
CALL fl_lee_codigo_bien(vg_codcia, activo) RETURNING r_a10.*
CALL fl_lee_grupo_activo(r_a10.a10_compania, r_a10.a10_grupo_act)
	RETURNING r_a01.*
LET val_dep_mes = 0.00
IF r_a10.a10_tot_dep_mb < r_a10.a10_valor_mb THEN
	LET val_dep_mes = (r_a10.a10_val_dep_mb / DAY(MDY(MONTH(TODAY), 01,
							YEAR(TODAY))
				+ 1 UNITS MONTH - 1 UNITS DAY)) * DAY(TODAY)
END IF
DISPLAY BY NAME r_a10.a10_codigo_bien, r_a10.a10_descripcion,
		r_a10.a10_valor_mb, r_a10.a10_tot_dep_mb, val_dep_mes
INITIALIZE rm_ven.* TO NULL
LET rm_ven.valor_suge = r_a10.a10_valor_mb - r_a10.a10_tot_dep_mb - val_dep_mes
LET rm_ven.valor_vta  = 0
LET rm_ven.valor_iva  = 0
IF r_a01.a01_paga_iva = 'S' THEN
	LET rm_ven.valor_iva  = (rm_ven.valor_vta * rg_gen.g00_porc_impto / 100)
END IF
LET rm_ven.total      = (rm_ven.valor_vta + rm_ven.valor_iva)
CALL retorna_fec_vta_baj(r_a10.*) RETURNING rm_ven.fec_vta, fec_min
LET int_flag = 0
INPUT BY NAME rm_ven.*
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		LET int_flag = 1
		EXIT INPUT
	ON KEY(F2)
		IF INFIELD(aux_pago) THEN
			CALL fl_ayuda_cuenta_contable(vg_codcia, -1)
				RETURNING cuenta, descripcion
			IF cuenta IS NOT NULL THEN
				LET rm_ven.aux_pago = cuenta
				DISPLAY BY NAME rm_ven.aux_pago
			END IF 
		END IF
		LET int_flag = 0
	BEFORE FIELD fec_vta
		LET fec = rm_ven.fec_vta
	BEFORE FIELD valor_vta
		LET val_vta = rm_ven.valor_vta
	AFTER FIELD fec_vta
		IF rm_ven.fec_vta IS NULL THEN
			LET rm_ven.fec_vta = fec
			DISPLAY BY NAME rm_ven.fec_vta
		END IF
		IF r_a01.a01_depreciable = 'S' AND rm_ven.fec_vta <= fec_min
		THEN
			CALL fl_mostrar_mensaje('La fecha de venta no puede ser menor o igual a la fecha del ultimo movimiento de este codigo de bien.', 'exclamation')
			LET rm_ven.fec_vta = fec_min + 1 UNITS DAY
			DISPLAY BY NAME rm_ven.fec_vta
			NEXT FIELD fec_vta
		END IF
		IF r_a01.a01_depreciable = 'N' THEN
			SELECT MAX(DATE(a12_fecing))
				INTO fec_min
				FROM actt012
				WHERE a12_compania    = vg_codcia
				  AND a12_codigo_tran = 'IN'
				  AND a12_codigo_bien = r_a10.a10_codigo_bien
			IF rm_ven.fec_vta <= fec_min THEN
				CALL fl_mostrar_mensaje('La fecha de venta no puede ser menor o igual a la fecha de compra de este codigo de bien.', 'exclamation')
				NEXT FIELD fec_vta
			END IF
		END IF
		IF rm_ven.fec_vta > TODAY THEN
			CALL fl_mostrar_mensaje('La fecha de venta no puede ser mayor a la fecha de hoy.', 'exclamation')
			LET rm_ven.fec_vta = TODAY
			DISPLAY BY NAME rm_ven.fec_vta
			NEXT FIELD fec_vta
		END IF
	AFTER FIELD aux_pago
		IF rm_ven.aux_pago IS NOT NULL THEN
			IF NOT valida_cuenta_contable(rm_ven.aux_pago, 1) THEN
				NEXT FIELD aux_pago
			END IF
		END IF
	AFTER FIELD valor_vta
		IF rm_ven.valor_vta IS NULL THEN
			LET rm_ven.valor_vta = val_vta
		END IF
		LET rm_ven.valor_iva  = 0
		IF r_a01.a01_paga_iva = 'S' THEN
			LET rm_ven.valor_iva = (rm_ven.valor_vta
						* rg_gen.g00_porc_impto
						/ 100)
		END IF
		LET rm_ven.total     = rm_ven.valor_vta + rm_ven.valor_iva
		DISPLAY BY NAME rm_ven.*
	AFTER INPUT
		IF rm_ven.valor_vta = 0.00 THEN
			CALL fl_mostrar_mensaje('El valor de la venta no puede ser CERO.', 'exclamation')
			NEXT FIELD valor_vta
		END IF
END INPUT
IF int_flag THEN
	LET int_flag = 0
	CLOSE WINDOW w_actf202_3
	RETURN
END IF
BEGIN WORK
	IF estado = 'S' THEN
		IF NOT control_depreciacion(activo, 0) THEN
			WHENEVER ERROR STOP
			ROLLBACK WORK
			DELETE FROM te_depre
			LET int_flag = 0
			CLOSE WINDOW w_actf202_3
			RETURN
		END IF
	END IF
	IF NOT dar_baja_venta_activo(activo, vm_cod_tran3, 1) THEN
		WHENEVER ERROR STOP
		ROLLBACK WORK
		DELETE FROM te_depre
		LET int_flag = 0
		CLOSE WINDOW w_actf202_3
		RETURN
	END IF
COMMIT WORK
CALL diarios_contables()
DELETE FROM te_depre
CALL fl_mostrar_mensaje('Activo Fijo ha sido VENDIDO Ok.', 'info')
LET int_flag = 0
CLOSE WINDOW w_actf202_3
RETURN

END FUNCTION



FUNCTION valida_cuenta_contable(cuenta, flag_descr)
DEFINE cuenta		LIKE ctbt010.b10_cuenta
DEFINE flag_descr	SMALLINT
DEFINE r_b10		RECORD LIKE ctbt010.*

CALL fl_lee_cuenta(vg_codcia, cuenta) RETURNING r_b10.*
IF r_b10.b10_compania IS NULL THEN
	CALL fl_mostrar_mensaje('No existe esta cuenta.', 'exclamation')
	RETURN 0
END IF
IF r_b10.b10_permite_mov = 'N' THEN
	CALL fl_mostrar_mensaje('Cuenta no permite movimiento.', 'exclamation')
	RETURN 0
END IF
IF r_b10.b10_estado = 'B' THEN
	CALL fl_mensaje_estado_bloqueado()
	RETURN 0
END IF
RETURN 1

END FUNCTION



FUNCTION bloqueo_bien(activo)
DEFINE activo		LIKE actt010.a10_codigo_bien
DEFINE r_a10		RECORD LIKE actt010.*
DEFINE resul		SMALLINT

LET resul = 0
SET LOCK MODE TO WAIT 3
WHENEVER ERROR CONTINUE
WHILE TRUE
	DECLARE q_ab CURSOR FOR
		SELECT * FROM actt010
			WHERE a10_compania    = vg_codcia
			  AND a10_codigo_bien = activo
			FOR UPDATE
	OPEN q_ab
	FETCH q_ab INTO r_a10.*
	IF STATUS = 0 THEN
		LET resul = 1
		EXIT WHILE
	END IF
	IF STATUS < 0 THEN
		IF muestra_mensaje_error_continuar_act(activo, '10',
						'actualizar', 'actualización')
		THEN
			CLOSE q_ab
			FREE q_ab
			CONTINUE WHILE
		END IF
	END IF
	IF STATUS = NOTFOUND THEN
		IF muestra_mensaje_error_continuar_act(activo, '10',
						'encontrar', 'búsqueda')
		THEN
			CLOSE q_ab
			FREE q_ab
			CONTINUE WHILE
		END IF
	END IF
	EXIT WHILE
END WHILE
SET LOCK MODE TO NOT WAIT
WHENEVER ERROR STOP
RETURN resul

END FUNCTION



FUNCTION control_depreciacion(activo, flag)
DEFINE activo		LIKE actt010.a10_codigo_bien
DEFINE flag		SMALLINT
DEFINE r_a01		RECORD LIKE actt001.*
DEFINE r_a10		RECORD LIKE actt010.*
DEFINE num_tran		LIKE actt012.a12_numero_tran
DEFINE fin_mes, fecha	DATE
DEFINE fec_ant, fec_trn	DATE
DEFINE resul, unavez	SMALLINT
DEFINE prinum, salir	SMALLINT
DEFINE resp		CHAR(6)
DEFINE mensaje		CHAR(300)

CALL fl_lee_codigo_bien(vg_codcia, activo) RETURNING r_a10.*
CALL fl_lee_grupo_activo(r_a10.a10_compania, r_a10.a10_grupo_act)
	RETURNING r_a01.*
IF r_a01.a01_depreciable = 'N' THEN
	RETURN 1
END IF
LET fec_ant = MDY(12, 31, YEAR(TODAY - 1 UNITS YEAR))
LET fin_mes = MDY(rm_a00.a00_mespro, 01, rm_a00.a00_anopro) + 1 UNITS MONTH
		- 1 UNITS DAY
LET fec_trn = NULL
SELECT MAX(DATE(a12_fecing)) INTO fec_trn
	FROM actt012
	WHERE a12_compania    = vg_codcia
	  AND a12_codigo_tran = vm_cod_tran1
	  AND a12_codigo_bien = activo
IF flag = 0 THEN
	IF fec_trn > rm_ven.fec_vta THEN
		LET fec_trn = rm_ven.fec_vta
	END IF
END IF
IF flag = 1 THEN
	IF fec_trn > rm_baj.fec_baj THEN
		LET fec_trn = rm_baj.fec_baj
	END IF
END IF
IF fec_trn IS NOT NULL THEN
	LET fec_trn = (MDY(MONTH(fec_trn), 1, YEAR(fec_trn)) + 1 UNITS MONTH
			- 1 UNITS DAY) + 1 UNITS DAY
	LET fin_mes = MDY(MONTH(fec_trn), 1, YEAR(fec_trn)) + 1 UNITS MONTH
			- 1 UNITS DAY
END IF
CALL fl_lee_codigo_bien(vg_codcia, activo) RETURNING r_a10.*
--IF (r_a10.a10_estado <> 'S') AND (fin_mes > TODAY) AND (flag = 1) THEN
IF (r_a10.a10_estado <> 'S') AND (fin_mes > TODAY) THEN
	RETURN 1
END IF
--IF (r_a10.a10_estado = 'S') OR (flag = 0) THEN
IF (r_a10.a10_estado = 'S') THEN
	IF flag THEN
		{--
		IF fin_mes > TODAY THEN
			LET fin_mes = TODAY
		END IF
		--}
		IF fin_mes >= rm_baj.fec_baj THEN
			RETURN 1
		END IF
	ELSE
		IF fin_mes >= rm_ven.fec_vta THEN
			RETURN 1
		END IF
	END IF
END IF
IF NOT bloqueo_bien(activo) THEN
	RETURN 0
END IF
LET resul  = 0
LET unavez = 1
LET prinum = 1
LET salir  = 0
FOREACH q_ab INTO r_a10.*
	WHILE TRUE
		LET resul = 0
	{-- DESCOMENTAR SI SE DESEA QUE DEPRECIE HASTA EL MES ANTERIOR A HOY
		IF fin_mes > fec_ant THEN
			IF unavez THEN
				LET resul = 1
			END IF
			EXIT WHILE
		END IF
	--}
		IF unavez THEN
			IF YEAR(fec_ant) >= rm_a00.a00_anopro THEN
				LET mensaje = 'No se han cerrado uno o varios',
						' meses en el módulo de ACTIVO',
						' FIJOS. Desea continuar con',
						' el proceso de DAR DE BAJA y',
						' éste depreciara desde ',
						rm_a00.a00_anopro USING "&&&&",
						'-', rm_a00.a00_mespro
						USING "&&", ' hasta ',
						YEAR(fec_ant) USING "&&&&", '-',
						MONTH(fec_ant) USING "&&",
						', para luego dar de baja el',
						' saldo del Activo Fijo ?'
				LET int_flag = 0
				CALL fl_hacer_pregunta(mensaje, 'No')
					RETURNING resp
				IF resp <> 'Yes' THEN
					LET int_flag = 0
					EXIT WHILE
				END IF
			END IF
			LET unavez = 0
			IF r_a10.a10_fecha_comp > fin_mes THEN
				LET fin_mes = MDY(MONTH(r_a10.a10_fecha_comp),
						1, YEAR(r_a10.a10_fecha_comp))
						+ 1 UNITS MONTH - 1 UNITS DAY
			END IF
		END IF
		IF NOT validacion_contable(fin_mes) THEN
			EXIT WHILE
		END IF
		CALL generar_depreciacion(fin_mes, r_a10.*, prinum, flag)
			RETURNING resul, num_tran
		IF NOT resul THEN
			EXIT WHILE
		END IF
		CALL genera_contabilizacion(vm_cod_tran1, fin_mes,
					r_a10.a10_codigo_bien, vm_sub_dep, 0,
					flag)
			RETURNING rm_b12.*
		UPDATE actt012
			SET a12_tipcomp_gen = rm_b12.b12_tipo_comp,
			    a12_numcomp_gen = rm_b12.b12_num_comp
			WHERE a12_compania    = vg_codcia
			  AND a12_codigo_tran = vm_cod_tran1
			  AND a12_numero_tran = num_tran
		DELETE FROM te_depre
		IF salir THEN
			EXIT WHILE
		END IF
		LET prinum = 0
		LET fecha  = MDY(MONTH(fin_mes), 01, YEAR(fin_mes))
				+ 1 UNITS MONTH
		CALL retorna_fecha_dep(fecha) RETURNING fin_mes
		-- HABILITAR SI SE DESEA QUE DEPRECIE HASTA EL MES ANTERIOR
		    --TODAY --
		IF flag THEN
			{--
			IF fin_mes >= TODAY THEN
				EXIT WHILE
			END IF
			--}
			IF fin_mes >= rm_baj.fec_baj THEN
				IF EXTEND(fin_mes, MONTH TO DAY) =
					EXTEND(rm_baj.fec_baj, MONTH TO DAY)
				THEN
					EXIT WHILE
				END IF
				LET fin_mes = rm_baj.fec_baj
				LET salir   = 1
			END IF
		ELSE
			IF fin_mes >= rm_ven.fec_vta THEN
				IF EXTEND(fin_mes, MONTH TO DAY) =
					EXTEND(rm_ven.fec_vta, MONTH TO DAY)
				THEN
					EXIT WHILE
				END IF
				LET fin_mes = rm_ven.fec_vta
				LET salir   = 1
			END IF
		END IF
		--
	END WHILE
END FOREACH
RETURN resul

END FUNCTION



FUNCTION dar_baja_venta_activo(activo, cod_tran, flag)
DEFINE activo		LIKE actt010.a10_codigo_bien
DEFINE cod_tran		LIKE actt012.a12_codigo_tran
DEFINE flag		SMALLINT
DEFINE r_a01		RECORD LIKE actt001.*
DEFINE r_a10		RECORD LIKE actt010.*
DEFINE r_a12, r_a12_2	RECORD LIKE actt012.*
DEFINE r_a14		RECORD LIKE actt014.*
DEFINE r_g34		RECORD LIKE gent034.*
DEFINE valor		LIKE actt010.a10_valor_mb
DEFINE estado		LIKE actt010.a10_estado
DEFINE subtipo		LIKE ctbt004.b04_subtipo
DEFINE aux_cont		LIKE ctbt010.b10_cuenta
DEFINE val_cuad		LIKE ctbt013.b13_valor_base
DEFINE mensaje		VARCHAR(200)
DEFINE tipo		CHAR(1)
DEFINE ini_s, fin_s	SMALLINT
DEFINE segundo		SMALLINT
DEFINE fecha		DATE
DEFINE fec_vta_baj	DATE
DEFINE fec_tex		VARCHAR(19)

IF NOT bloqueo_bien(activo) THEN
	RETURN 0
END IF
CALL fl_lee_codigo_bien(vg_codcia, activo) RETURNING r_a10.*
INITIALIZE r_a12.* TO NULL
LET valor                 = r_a10.a10_valor_mb - r_a10.a10_tot_dep_mb
LET r_a12.a12_compania	  = vg_codcia
LET r_a12.a12_codigo_tran = cod_tran
LET r_a12.a12_numero_tran = fl_retorna_num_tran_activo(vg_codcia,
							r_a12.a12_codigo_tran)
IF r_a12.a12_numero_tran <= 0 THEN
	RETURN 0
END IF
LET r_a12.a12_codigo_bien = r_a10.a10_codigo_bien
CASE cod_tran
	WHEN vm_cod_tran2
		LET r_a12.a12_referencia  = rm_baj.glosa CLIPPED
		LET fec_vta_baj           = rm_baj.fec_baj
	WHEN vm_cod_tran3
		LET r_a12.a12_referencia  = rm_ven.glosa CLIPPED
		LET fec_vta_baj           = rm_ven.fec_vta
END CASE
LET r_a12.a12_locali_ori  = r_a10.a10_localidad
LET r_a12.a12_depto_ori	  = r_a10.a10_cod_depto
LET r_a12.a12_porc_deprec = r_a10.a10_porc_deprec
IF cod_tran = vm_cod_tran2 AND flag = 0 THEN
	LET r_a12.a12_valor_mb = (rm_ven.total - rm_ven.valor_iva) * (-1)
ELSE
	LET r_a12.a12_valor_mb = valor * (-1)
END IF
IF cod_tran = vm_cod_tran3 THEN
	LET r_a12.a12_valor_mb = (r_a10.a10_valor_mb - r_a10.a10_tot_dep_mb)
					* (-1)
END IF
LET r_a12.a12_valor_ma	  = 0
LET r_a12.a12_tipcomp_gen = NULL
LET r_a12.a12_numcomp_gen = NULL
LET r_a12.a12_usuario	  = vg_usuario
IF cod_tran = vm_cod_tran2 OR cod_tran = vm_cod_tran3 THEN
	LET fec_tex          = EXTEND(fec_vta_baj, YEAR TO DAY), " ",
				EXTEND(CURRENT, HOUR TO SECOND)
	LET r_a12.a12_fecing = EXTEND(fec_tex, YEAR TO SECOND)
ELSE
	LET r_a12.a12_fecing = CURRENT
END IF
INSERT INTO actt012 VALUES (r_a12.*)
CALL fl_lee_grupo_activo(r_a10.a10_compania, r_a10.a10_grupo_act)
	RETURNING r_a01.*
INITIALIZE r_a14.* TO NULL
DECLARE q_a14 CURSOR FOR
	SELECT * FROM actt014
		WHERE a14_compania    = r_a10.a10_compania
		  AND a14_codigo_bien = r_a10.a10_codigo_bien
		ORDER BY a14_anio DESC, a14_mes DESC
OPEN q_a14
FETCH q_a14 INTO r_a14.*
CLOSE q_a14
FREE q_a14
IF r_a14.a14_tot_dep_mb IS NULL THEN
	LET r_a14.a14_tot_dep_mb = r_a10.a10_valor_mb
	IF cod_tran = vm_cod_tran3 THEN
		IF r_a10.a10_tot_dep_mb = 0 THEN
			LET r_a14.a14_tot_dep_mb = 0
		END IF
	END IF
END IF
CASE cod_tran
	WHEN vm_cod_tran2
		IF flag = 1 THEN
			IF valor > 0 THEN
				CALL lee_departamento(r_a10.a10_compania,
							r_a10.a10_cod_depto)
					RETURNING r_g34.*
				CALL inserta_tabla_temporal(r_a10.a10_grupo_act,
					r_a10.a10_codigo_bien, cod_tran,
					vm_sub_baj, r_g34.g34_aux_deprec,
					valor, 'D')
			END IF
			CALL inserta_tabla_temporal(r_a10.a10_grupo_act,
				r_a10.a10_codigo_bien, cod_tran, vm_sub_baj,
				r_a01.a01_aux_dep_act, r_a14.a14_tot_dep_mb,'D')
			CALL inserta_tabla_temporal(r_a10.a10_grupo_act,
				r_a10.a10_codigo_bien, cod_tran, vm_sub_baj,
				r_a01.a01_aux_activo, r_a10.a10_valor_mb, 'H')
		END IF
		LET ini_s = vm_sub_baj
		LET fin_s = vm_sub_baj
	WHEN vm_cod_tran3
		LET aux_cont = r_a01.a01_aux_pago
		IF rm_ven.aux_pago IS NOT NULL THEN
			LET aux_cont = rm_ven.aux_pago
		END IF
		--------------------------------------------------------------
		CALL inserta_tabla_temporal(r_a10.a10_grupo_act,
				r_a10.a10_codigo_bien, cod_tran, vm_sub_ven,
				aux_cont, rm_ven.total, 'D')
		IF rm_ven.valor_iva > 0 THEN
			CALL inserta_tabla_temporal(r_a10.a10_grupo_act,
				r_a10.a10_codigo_bien, cod_tran, vm_sub_ven,
				r_a01.a01_aux_iva, rm_ven.valor_iva, 'H')
		END IF
		CALL inserta_tabla_temporal(r_a10.a10_grupo_act,
				r_a10.a10_codigo_bien, cod_tran, vm_sub_ven,
				r_a01.a01_aux_venta, rm_ven.total
				- rm_ven.valor_iva, 'H')
		--------------------------------------------------------------
		IF r_a10.a10_tot_dep_mb <> 0 THEN
			CALL inserta_tabla_temporal(r_a10.a10_grupo_act,
				r_a10.a10_codigo_bien, cod_tran, vm_sub_baj,
				r_a01.a01_aux_dep_act, r_a10.a10_tot_dep_mb,'D')
			CALL inserta_tabla_temporal(r_a10.a10_grupo_act,
				r_a10.a10_codigo_bien, cod_tran, vm_sub_baj,
				r_a01.a01_aux_activo, r_a10.a10_tot_dep_mb, 'H')
		ELSE
			CALL inserta_tabla_temporal(r_a10.a10_grupo_act,
				r_a10.a10_codigo_bien, cod_tran, vm_sub_baj,
				r_a01.a01_aux_dep_act, r_a10.a10_valor_mb,'D')
			CALL inserta_tabla_temporal(r_a10.a10_grupo_act,
				r_a10.a10_codigo_bien, cod_tran, vm_sub_baj,
				r_a01.a01_aux_activo, r_a10.a10_valor_mb, 'H')
		END IF
		--------------------------------------------------------------
		IF r_a01.a01_depreciable = 'S' THEN
			LET ini_s = vm_sub_baj
		ELSE
			LET ini_s = vm_sub_ven
		END IF
		IF r_a10.a10_valor_mb - r_a10.a10_tot_dep_mb > 0 THEN
			CALL inserta_tabla_temporal(r_a10.a10_grupo_act,
					r_a10.a10_codigo_bien, cod_tran,
					vm_sub_cos, r_a01.a01_aux_gasto,
					r_a10.a10_valor_mb -
					r_a10.a10_tot_dep_mb, 'D')
			CALL inserta_tabla_temporal(r_a10.a10_grupo_act,
					r_a10.a10_codigo_bien, cod_tran,
					vm_sub_cos, r_a01.a01_aux_activo,
					r_a10.a10_valor_mb -
					r_a10.a10_tot_dep_mb, 'H')
			LET fin_s = vm_sub_cos
		END IF
		IF r_a10.a10_valor_mb - r_a10.a10_tot_dep_mb = 0 THEN
			LET fin_s = vm_sub_ven
		END IF
		--------------------------------------------------------------
END CASE
CASE cod_tran
	WHEN vm_cod_tran2 LET fecha = rm_baj.fec_baj
	WHEN vm_cod_tran3 LET fecha = rm_ven.fec_vta
	OTHERWISE LET fecha = TODAY
END CASE
IF NOT validacion_contable(fecha) THEN
	RETURN 0
END IF
LET segundo = 0
FOR subtipo = ini_s TO fin_s
	CASE subtipo
		WHEN vm_sub_ven LET segundo = 0
		WHEN vm_sub_baj LET segundo = 1
		WHEN vm_sub_cos LET segundo = 2
	END CASE
	CALL genera_contabilizacion(cod_tran, fecha, r_a10.a10_codigo_bien,
					subtipo, segundo, flag)
		RETURNING rm_b12.*
	SELECT NVL(SUM(b13_valor_base), 0) INTO val_cuad
		FROM ctbt013
		WHERE b13_compania  = vg_codcia
		  AND b13_tipo_comp = rm_b12.b12_tipo_comp
		  AND b13_num_comp  = rm_b12.b12_num_comp
	IF val_cuad <> 0 THEN
		LET mensaje = 'Esta descuadrado el diario contable de la '
		CASE cod_tran
			WHEN vm_cod_tran2
				LET mensaje = mensaje CLIPPED, ' baja'
			WHEN vm_cod_tran3
				LET mensaje = mensaje CLIPPED, ' venta'
		END CASE
		LET mensaje = mensaje CLIPPED, ' con ',
				val_cuad USING "---,--&.##",
				'. POR FAVOR LLAME AL ADMINISTRARDOR.'
		CALL fl_mostrar_mensaje(mensaje, 'stop')
		RETURN 0
	END IF
	IF cod_tran = vm_cod_tran3 AND subtipo = vm_sub_baj THEN
		INITIALIZE r_a12_2.* TO NULL
		SELECT * INTO r_a12_2.*
			FROM actt012
			WHERE a12_compania    = r_a12.a12_compania
			  AND a12_codigo_tran = cod_tran
			  AND a12_numero_tran = r_a12.a12_numero_tran
		LET r_a12_2.a12_codigo_tran = vm_cod_tran4
		LET r_a12_2.a12_numero_tran =
				fl_retorna_num_tran_activo(r_a12.a12_compania,
								vm_cod_tran4)
		IF r_a12_2.a12_numero_tran <= 0 THEN
			RETURN 0
		END IF
		LET r_a12_2.a12_valor_mb    = 0
		SELECT NVL(SUM(b13_valor_base), 0)
			INTO r_a12_2.a12_valor_mb
			FROM ctbt013
			WHERE b13_compania    = vg_codcia
			  AND b13_tipo_comp   = rm_b12.b12_tipo_comp
			  AND b13_num_comp    = rm_b12.b12_num_comp
			  AND b13_valor_base >= 0
		LET r_a12_2.a12_tipcomp_gen = rm_b12.b12_tipo_comp
		LET r_a12_2.a12_numcomp_gen = rm_b12.b12_num_comp
		LET r_a12_2.a12_fecing      = r_a12_2.a12_fecing
						- 2 UNITS SECOND
		INSERT INTO actt012 VALUES (r_a12_2.*)
		LET r_a12_2.a12_codigo_tran = vm_cod_tran2
		LET r_a12_2.a12_numero_tran =
				fl_retorna_num_tran_activo(r_a12.a12_compania,
								vm_cod_tran2)
		IF r_a12_2.a12_numero_tran <= 0 THEN
			RETURN 0
		END IF
		LET r_a12_2.a12_valor_mb    = r_a12_2.a12_valor_mb * (-1)
		LET r_a12_2.a12_fecing      = r_a12_2.a12_fecing
						+ 1 UNITS SECOND
		INSERT INTO actt012 VALUES (r_a12_2.*)
		LET vm_num_baja = r_a12_2.a12_numero_tran
	END IF
	IF subtipo <> vm_sub_cos THEN
		UPDATE actt012
			SET a12_tipcomp_gen = rm_b12.b12_tipo_comp,
			    a12_numcomp_gen = rm_b12.b12_num_comp
			WHERE a12_compania    = vg_codcia
			  AND a12_codigo_tran = cod_tran
			  AND a12_numero_tran = r_a12.a12_numero_tran
	END IF
	IF subtipo <> vm_sub_baj THEN
		INSERT INTO actt015
			VALUES (r_a12.a12_compania, cod_tran,
				r_a12.a12_numero_tran, rm_b12.b12_tipo_comp,
				rm_b12.b12_num_comp, vg_usuario, CURRENT)
	END IF
END FOR
CASE cod_tran
	WHEN vm_cod_tran2
		LET vm_num_baja  = r_a12.a12_numero_tran
		LET estado       = 'E'
	WHEN vm_cod_tran3
		LET vm_num_venta = r_a12.a12_numero_tran
		LET estado       = 'V'
END CASE
UPDATE actt010
	SET a10_tot_dep_mb = r_a10.a10_valor_mb,
	    a10_fecha_baja = fecha,
	    a10_estado     = estado
	WHERE CURRENT OF q_ab
RETURN 1

END FUNCTION



FUNCTION generar_depreciacion(fin_mes, r_a10, unavez, flag)
DEFINE fin_mes		DATE
DEFINE r_a10		RECORD LIKE actt010.*
DEFINE unavez, flag	SMALLINT
DEFINE r_g34		RECORD LIKE gent034.*
DEFINE r_a01		RECORD LIKE actt001.*
DEFINE r_a11		RECORD LIKE actt011.*
DEFINE r_a12		RECORD LIKE actt012.*
DEFINE r_a13		RECORD LIKE actt013.*
DEFINE r_a14		RECORD LIKE actt014.*
DEFINE r_a13_ant	RECORD LIKE actt013.*
DEFINE r_a14_ant	RECORD LIKE actt014.*
DEFINE val_dep, tot_dep	DECIMAL(14,2)
DEFINE dif             	DECIMAL(14,2)
DEFINE dias		INTEGER
DEFINE fin_deprec, fec	DATE
DEFINE mes, anio	SMALLINT
DEFINE i, j		SMALLINT
DEFINE fec_tex		VARCHAR(19)

CALL fl_lee_codigo_bien(r_a10.a10_compania, r_a10.a10_codigo_bien)
	RETURNING r_a10.*
LET fin_deprec = r_a10.a10_fecha_comp + r_a10.a10_anos_util UNITS YEAR
LET dias       = fin_mes - r_a10.a10_fecha_comp
--IF (r_a10.a10_estado <> 'S') AND (flag = 1) THEN
IF (r_a10.a10_estado <> 'S') THEN
	IF YEAR(r_a10.a10_fecha_comp)  = YEAR(fin_mes) AND
	   MONTH(r_a10.a10_fecha_comp) = MONTH(fin_mes)
	THEN
		LET r_a10.a10_val_dep_mb = (r_a10.a10_val_dep_mb * dias)
						/ DAY(fin_mes)
	END IF
END IF
--IF (r_a10.a10_estado = 'S') OR (flag = 0) THEN
IF (r_a10.a10_estado = 'S') THEN
	{--
	IF flag = 1 THEN
		LET fec = TODAY
	ELSE
		LET fec = fin_mes
	END IF
	--}
	LET fec = fin_mes
	LET r_a10.a10_val_dep_mb = (r_a10.a10_val_dep_mb
					/ DAY(MDY(MONTH(fec), 01, YEAR(fec))
					+ 1 UNITS MONTH - 1 UNITS DAY))
					* DAY(fin_mes)
END IF
IF YEAR(fin_deprec)  = YEAR(fin_mes) AND
   MONTH(fin_deprec) = MONTH(fin_mes)
THEN
	LET r_a10.a10_val_dep_mb = r_a10.a10_valor_mb - r_a10.a10_tot_dep_mb
END IF
IF r_a10.a10_val_dep_mb > r_a10.a10_valor_mb - r_a10.a10_tot_dep_mb THEN
	LET r_a10.a10_val_dep_mb = r_a10.a10_valor_mb - r_a10.a10_tot_dep_mb
END IF
CALL fl_lee_grupo_activo(r_a10.a10_compania, r_a10.a10_grupo_act)
	RETURNING r_a01.*
IF r_a01.a01_depreciable = 'N' THEN
	RETURN 0, 0
END IF
DECLARE q_dpto CURSOR FOR
	SELECT * FROM actt011
		WHERE a11_compania    = r_a10.a10_compania
		  AND a11_codigo_bien = r_a10.a10_codigo_bien
LET j = 0
FOREACH q_dpto INTO r_a11.*
	LET j = j + 1
END FOREACH
LET i       = 0
LET tot_dep = 0
FOREACH q_dpto INTO r_a11.*
	CALL lee_departamento(r_a10.a10_compania, r_a11.a11_cod_depto)
		RETURNING r_g34.*
	LET i       = i + 1	
	LET val_dep = r_a10.a10_val_dep_mb * r_a11.a11_porcentaje / 100
	LET tot_dep = tot_dep + val_dep 
	IF i = j THEN
		LET dif     = r_a10.a10_val_dep_mb - tot_dep
		LET tot_dep = tot_dep - val_dep
		LET val_dep = val_dep + dif
		LET tot_dep = tot_dep + val_dep
	END IF
	CALL inserta_tabla_temporal(r_a10.a10_grupo_act, r_a10.a10_codigo_bien,
			vm_cod_tran1, vm_sub_dep, r_g34.g34_aux_deprec,
			val_dep, 'D')
	CALL inserta_tabla_temporal(r_a10.a10_grupo_act, r_a10.a10_codigo_bien,
			vm_cod_tran1, vm_sub_dep, r_a01.a01_aux_dep_act,
			val_dep, 'H') 
END FOREACH
IF i = 0 THEN
	CALL lee_departamento(r_a10.a10_compania, r_a10.a10_cod_depto)
		RETURNING r_g34.*
	CALL inserta_tabla_temporal(r_a10.a10_grupo_act, r_a10.a10_codigo_bien,
		vm_cod_tran1, vm_sub_dep, r_g34.g34_aux_deprec,
		r_a10.a10_val_dep_mb, 'D')
	CALL inserta_tabla_temporal(r_a10.a10_grupo_act, r_a10.a10_codigo_bien,
		vm_cod_tran1, vm_sub_dep, r_a01.a01_aux_dep_act,
		r_a10.a10_val_dep_mb, 'H')
END IF          			    
LET r_a10.a10_tot_dep_mb = r_a10.a10_tot_dep_mb + r_a10.a10_val_dep_mb
IF r_a10.a10_valor_mb = r_a10.a10_tot_dep_mb THEN
	LET r_a10.a10_estado = 'D'
END IF
UPDATE actt010
	SET a10_tot_dep_mb = r_a10.a10_tot_dep_mb,
	    a10_estado     = r_a10.a10_estado
	WHERE CURRENT OF q_ab
INITIALIZE r_a12.*, r_a14.* TO NULL
LET r_a12.a12_compania	  = vg_codcia
LET r_a12.a12_codigo_tran = vm_cod_tran1
LET r_a12.a12_numero_tran = fl_retorna_num_tran_activo(vg_codcia,
							r_a12.a12_codigo_tran)
IF r_a12.a12_numero_tran <= 0 THEN
	RETURN 0, 0
END IF
LET r_a12.a12_codigo_bien = r_a10.a10_codigo_bien
IF flag = 1 THEN
	IF (r_a10.a10_estado <> 'S') THEN
		LET r_a12.a12_referencia  = 'DEPRECIACION MENSUAL (POR BAJA)'
	ELSE
		LET r_a12.a12_referencia  = 'DEPRECIACION PARCIAL (POR BAJA)'
	END IF
ELSE
	LET r_a12.a12_referencia  = 'DEPRECIACION PARCIAL (POR VENTA)'
END IF
LET r_a12.a12_locali_ori  = r_a10.a10_localidad
LET r_a12.a12_depto_ori	  = r_a10.a10_cod_depto
LET r_a12.a12_porc_deprec = r_a10.a10_porc_deprec
LET r_a12.a12_valor_mb	  = r_a10.a10_val_dep_mb * (-1)
LET r_a12.a12_valor_ma	  = 0
LET r_a12.a12_tipcomp_gen = NULL
LET r_a12.a12_numcomp_gen = NULL
LET r_a12.a12_usuario	  = vg_usuario
IF (r_a10.a10_estado <> 'S') AND flag = 1 THEN
	LET r_a12.a12_fecing = MDY(MONTH(fin_mes), 1, YEAR(fin_mes))
				+ 1 UNITS MONTH - 1 UNITS DAY
ELSE
	--IF flag = 0 THEN
		LET fec_tex          = EXTEND(fin_mes, YEAR TO DAY), " ",
					EXTEND(CURRENT, HOUR TO SECOND)
		LET r_a12.a12_fecing = EXTEND(fec_tex, YEAR TO SECOND)
					- 3 UNITS SECOND
	{--
	ELSE
		LET r_a12.a12_fecing = CURRENT - 1 UNITS SECOND
	END IF
	--}
END IF
INSERT INTO actt012 VALUES (r_a12.*)
LET r_a14.a14_compania     = r_a12.a12_compania
LET r_a14.a14_codigo_bien  = r_a10.a10_codigo_bien
LET r_a14.a14_anio         = YEAR(fin_mes)
LET r_a14.a14_mes          = MONTH(fin_mes)
LET r_a14.a14_referencia   = 'GENERADA ', r_a12.a12_referencia CLIPPED
LET r_a14.a14_grupo_act    = r_a10.a10_grupo_act
LET r_a14.a14_tipo_act     = r_a10.a10_tipo_act
LET r_a14.a14_anos_util    = r_a10.a10_anos_util
LET r_a14.a14_porc_deprec  = r_a10.a10_porc_deprec
LET r_a14.a14_locali_ori   = r_a10.a10_locali_ori
LET r_a14.a14_localidad	   = r_a10.a10_localidad
LET r_a14.a14_cod_depto	   = r_a10.a10_cod_depto
LET r_a14.a14_moneda	   = r_a10.a10_moneda
LET r_a14.a14_paridad	   = r_a10.a10_paridad
LET r_a14.a14_valor	   = r_a10.a10_valor
LET r_a14.a14_valor_mb	   = r_a10.a10_valor_mb
LET r_a14.a14_fecha_baja   = r_a10.a10_fecha_baja
LET r_a14.a14_val_dep_mb   = r_a10.a10_val_dep_mb
LET r_a14.a14_val_dep_ma   = 0
LET anio = YEAR(fin_mes)
LET mes  = MONTH(fin_mes) - 1
IF mes = 0 THEN
	LET anio = YEAR(fin_mes) - 1
	LET mes  = 12
END IF
CALL fl_lee_depreciacion_mensual_activo(vg_codcia, r_a10.a10_codigo_bien,
					anio, mes)
	RETURNING r_a14_ant.*
IF r_a14_ant.a14_compania IS NULL THEN
	LET r_a14_ant.a14_dep_acum_act = 0
END IF
LET r_a14.a14_dep_acum_act = r_a14.a14_val_dep_mb + r_a14_ant.a14_dep_acum_act
IF YEAR(r_a10.a10_fecha_comp) < YEAR(fin_mes) AND r_a10.a10_estado <> 'D'
THEN
	LET r_a14.a14_dep_acum_act = r_a14.a14_val_dep_mb * MONTH(fin_mes)
END IF
LET r_a14.a14_tot_dep_mb   = r_a10.a10_tot_dep_mb
LET r_a14.a14_tot_dep_ma   = 0
LET r_a14.a14_tot_reexpr   = r_a10.a10_tot_reexpr
LET r_a14.a14_tot_dep_ree  = r_a10.a10_tot_dep_ree
LET r_a14.a14_tipo_comp	   = NULL
LET r_a14.a14_num_comp	   = NULL
LET r_a14.a14_usuario	   = r_a12.a12_usuario
LET r_a14.a14_fecing	   = r_a12.a12_fecing
INSERT INTO actt014 VALUES (r_a14.*)
IF unavez THEN
	LET vm_tran_ini = r_a12.a12_numero_tran
END IF
LET vm_tran_fin = r_a12.a12_numero_tran
IF MONTH(fin_mes) <> 12 THEN
	IF r_a10.a10_estado <> 'D' THEN
		RETURN 1, r_a12.a12_numero_tran
	END IF
END IF
INITIALIZE r_a13_ant.*, r_a13.* TO NULL
SELECT * INTO r_a13_ant.* FROM actt013
	WHERE a13_compania    = vg_codcia
	  AND a13_codigo_bien = r_a10.a10_codigo_bien
	  AND a13_ano         = YEAR(fin_mes) - 1
LET r_a13.a13_compania    = r_a10.a10_compania
LET r_a13.a13_codigo_bien = r_a10.a10_codigo_bien
LET r_a13.a13_ano         = YEAR(fin_mes)
IF r_a13_ant.a13_compania IS NULL THEN
	LET r_a13.a13_val_dep_acum = r_a10.a10_tot_dep_mb
ELSE
	LET r_a13.a13_val_dep_acum = r_a13_ant.a13_val_dep_acum
					+ r_a14.a14_dep_acum_act
END IF
INSERT INTO actt013 VALUES(r_a13.*)
RETURN 1, r_a12.a12_numero_tran

END FUNCTION



FUNCTION inserta_tabla_temporal(grupo_act, cod_bien, cod_tran, subtipo, cuenta,
				valor, tipo_mov)  
DEFINE grupo_act	LIKE actt010.a10_grupo_act
DEFINE cod_bien		LIKE actt010.a10_codigo_bien
DEFINE cod_tran		LIKE actt012.a12_codigo_tran
DEFINE subtipo		LIKE ctbt004.b04_subtipo
DEFINE cuenta		LIKE ctbt010.b10_cuenta
DEFINE nom		LIKE ctbt010.b10_descripcion
DEFINE valor		DECIMAL(14,2)
DEFINE tipo_mov		CHAR(1)

IF tipo_mov = 'H' THEN
	LET valor = valor * -1
END IF
SELECT * FROM te_depre
	WHERE te_grupo    = grupo_act
	  AND te_cod_tran = cod_tran
	  AND te_subtipo  = subtipo
	  AND te_cuenta   = cuenta
IF STATUS = NOTFOUND THEN
	INSERT INTO te_depre
		VALUES (grupo_act, cod_bien, cod_tran, subtipo, cuenta, valor)
ELSE
	UPDATE te_depre
		SET te_valor = te_valor + valor
		WHERE te_grupo    = grupo_act
		  AND te_cod_tran = cod_tran
		  AND te_subtipo  = subtipo
		  AND te_cuenta   = cuenta
END IF

END FUNCTION



FUNCTION genera_contabilizacion(cod_tran, fecha, activo, subtipo, segundo, flag)
DEFINE cod_tran		LIKE actt012.a12_codigo_tran
DEFINE fecha		DATE
DEFINE activo		LIKE actt010.a10_codigo_bien
DEFINE subtipo		LIKE ctbt004.b04_subtipo
DEFINE segundo, flag	SMALLINT
DEFINE tot_reg, i	SMALLINT
DEFINE r_a10		RECORD LIKE actt010.*
DEFINE r_b13		RECORD LIKE ctbt013.*
DEFINE grupo		LIKE actt010.a10_grupo_act
DEFINE cuenta		LIKE ctbt013.b13_cuenta
DEFINE nom		LIKE ctbt010.b10_descripcion
DEFINE valor		DECIMAL(14,2)
DEFINE glosa		VARCHAR(25)

INITIALIZE rm_b12.* TO NULL
SELECT COUNT(*) INTO tot_reg FROM te_depre
IF tot_reg = 0 THEN
	RETURN rm_b12.*
END IF
CALL fl_lee_codigo_bien(vg_codcia, activo) RETURNING r_a10.*
LET rm_b12.b12_compania 	= vg_codcia
LET rm_b12.b12_tipo_comp	= 'DC'
LET rm_b12.b12_num_comp 	= fl_numera_comprobante_contable(vg_codcia, 
			             rm_b12.b12_tipo_comp, YEAR(fecha),
				     MONTH(fecha))
LET rm_b12.b12_estado		= 'A'
LET rm_b12.b12_subtipo 		= subtipo
CASE cod_tran
	WHEN vm_cod_tran1
		IF flag THEN
			LET glosa = 'DEPRECIACION ACTIVOS: '
		ELSE
			LET glosa = 'DEPREC. POR VENTA ACTIVOS: '
		END IF
	WHEN vm_cod_tran2
		LET glosa = 'BAJA DE ACTIVOS: '
	WHEN vm_cod_tran3
		CASE subtipo
			WHEN vm_sub_baj LET glosa = 'BAJA POR VENTA ACTIVOS: '
			WHEN vm_sub_ven LET glosa = 'VENTA DE ACTIVOS: '
			WHEN vm_sub_cos LET glosa = 'COSTO POR VENTA ACTIVOS: '
		END CASE
END CASE
LET rm_b12.b12_glosa		= glosa CLIPPED, ' ', MONTH(fecha) USING '&&',
					'/', YEAR(fecha) USING '&&&&',' BIEN: ',
					r_a10.a10_codigo_bien USING "<<<&&&",
					' ', r_a10.a10_descripcion CLIPPED
CASE cod_tran
	WHEN vm_cod_tran2
		LET rm_b12.b12_glosa = rm_b12.b12_glosa CLIPPED, '. ',
					rm_baj.glosa CLIPPED
	WHEN vm_cod_tran3
		LET rm_b12.b12_glosa = rm_b12.b12_glosa CLIPPED, '. ',
					rm_ven.glosa CLIPPED
END CASE
LET rm_b12.b12_origen 		= 'A'
LET rm_b12.b12_moneda 		= rm_b00.b00_moneda_base
LET rm_b12.b12_paridad		= 1
IF cod_tran = vm_cod_tran1 THEN
	{--
	IF flag THEN
		LET rm_b12.b12_fec_proceso = MDY(MONTH(fecha), 01, YEAR(fecha))
						+ 1 UNITS MONTH - 1 UNITS DAY
	ELSE
	--}
		LET rm_b12.b12_fec_proceso = fecha
	--END IF
ELSE
	LET rm_b12.b12_fec_proceso = fecha
END IF
LET rm_b12.b12_modulo 		= vg_modulo
LET rm_b12.b12_usuario		= vg_usuario
LET rm_b12.b12_fecing 		= CURRENT + segundo UNITS SECOND
INSERT INTO ctbt012 VALUES (rm_b12.*)
DECLARE qu_sopla CURSOR FOR
	SELECT te_grupo, te_cuenta, te_valor
		FROM te_depre
		WHERE te_codigo_bien = activo
		  AND te_cod_tran    = cod_tran
		  AND te_subtipo     = subtipo
        	ORDER BY 1, 3 DESC, 2
LET i = 0
FOREACH qu_sopla INTO grupo, cuenta, valor
	INITIALIZE r_b13.* TO NULL
	LET i = i + 1
    	LET r_b13.b13_compania 		= rm_b12.b12_compania
    	LET r_b13.b13_tipo_comp 	= rm_b12.b12_tipo_comp
    	LET r_b13.b13_num_comp 		= rm_b12.b12_num_comp
    	LET r_b13.b13_secuencia		= i
    	LET r_b13.b13_cuenta 		= cuenta
    	LET r_b13.b13_glosa 		= rm_b12.b12_glosa 
    	LET r_b13.b13_valor_base 	= valor
    	LET r_b13.b13_valor_aux 	= 0
    	LET r_b13.b13_fec_proceso 	= rm_b12.b12_fec_proceso
	INSERT INTO ctbt013 VALUES (r_b13.*)
END FOREACH
RETURN rm_b12.*

END FUNCTION



FUNCTION diarios_contables()
DEFINE resp		CHAR(6)

CALL mayoriza_imprime_diarios('M')
LET int_flag = 0
CALL fl_hacer_pregunta('Desea imprimir la contabilizacion generada ?', 'No')
	RETURNING resp
IF resp = 'Yes' THEN
	CALL mayoriza_imprime_diarios('I')
END IF

END FUNCTION



FUNCTION mayoriza_imprime_diarios(flag)
DEFINE flag		CHAR(1)
DEFINE r_a12		RECORD LIKE actt012.*

IF rm_b12.b12_tipo_comp IS NOT NULL THEN
	SELECT a12_tipcomp_gen, a12_numcomp_gen
		FROM actt012
		WHERE a12_compania    = vg_codcia
		  AND a12_codigo_tran = vm_cod_tran2
		  AND a12_numero_tran = vm_num_baja
	UNION
		SELECT a12_tipcomp_gen, a12_numcomp_gen
			FROM actt012
			WHERE a12_compania    = vg_codcia
			  AND a12_codigo_tran = vm_cod_tran3
			  AND a12_numero_tran = vm_num_venta
	UNION
		SELECT a12_tipcomp_gen, a12_numcomp_gen
			FROM actt012
			WHERE a12_compania    = vg_codcia
			  AND a12_codigo_tran = vm_cod_tran1
			  AND a12_numero_tran BETWEEN vm_tran_ini
						  AND vm_tran_fin
	UNION
		SELECT a15_tipo_comp, a15_num_comp
			FROM actt015
			WHERE a15_compania    = vg_codcia
			  AND a15_codigo_tran = vm_cod_tran3
			  AND a15_numero_tran = vm_num_venta
	INTO TEMP t1
	DECLARE q_a12 CURSOR WITH HOLD FOR SELECT * FROM t1
	FOREACH q_a12 INTO r_a12.a12_tipcomp_gen, r_a12.a12_numcomp_gen
		CASE flag
			WHEN 'M'
				CALL fl_mayoriza_comprobante(vg_codcia,
						r_a12.a12_tipcomp_gen,
						r_a12.a12_numcomp_gen, 'M')
			WHEN 'I'
				CALL imprime_diario(r_a12.a12_tipcomp_gen,
							r_a12.a12_numcomp_gen)
		END CASE
	END FOREACH
	DROP TABLE t1
END IF

END FUNCTION



FUNCTION lee_departamento(codcia, cod_depto)
DEFINE codcia		LIKE gent034.g34_compania
DEFINE cod_depto	LIKE gent034.g34_cod_depto
DEFINE r_g34		RECORD LIKE gent034.* 

CALL fl_lee_departamento(codcia, cod_depto) RETURNING r_g34.*
IF r_g34.g34_aux_deprec IS NULL THEN
	CALL fl_mostrar_mensaje('Departamento: ' || r_g34.g34_cod_depto || ' no tiene asignado auxiliar contable de depreciación.', 'stop')
	WHENEVER ERROR STOP
	DROP TABLE te_depre
	ROLLBACK WORK
	EXIT PROGRAM
END IF
RETURN r_g34.*

END FUNCTION



FUNCTION retorna_fec_vta_baj(r_a10)
DEFINE r_a10		RECORD LIKE actt010.*
DEFINE fec_min, fecha	DATE

LET fecha = TODAY
SELECT NVL(MAX(DATE(a12_fecing)), TODAY)
	INTO fec_min
	FROM actt012
	WHERE a12_compania     = vg_codcia
	  AND a12_codigo_tran <> 'IN'
	  AND a12_codigo_bien  = r_a10.a10_codigo_bien
IF r_a10.a10_estado <> 'D' THEN
	LET fecha = fec_min + 1 UNITS DAY
END IF
RETURN fecha, fec_min

END FUNCTION



FUNCTION retorna_fecha_dep(fecha)
DEFINE fecha		DATE
DEFINE mes, ano		SMALLINT
DEFINE fecha_dep	DATE

LET mes = MONTH(fecha) + 1
LET ano = YEAR(fecha)
IF MONTH(fecha) = 12 THEN
	LET mes = 1
	LET ano = ano + 1
END IF
LET fecha_dep = MDY(mes, 01, ano) - 1 UNITS DAY
RETURN fecha_dep

END FUNCTION



FUNCTION validacion_contable(fecha)
DEFINE fecha		DATE
DEFINE resp 		VARCHAR(6)

IF YEAR(fecha) < YEAR(rm_b00.b00_fecha_cm) OR
  (YEAR(fecha) = YEAR(rm_b00.b00_fecha_cm) AND
   MONTH(fecha) <= MONTH(rm_b00.b00_fecha_cm))
THEN
	CALL fl_mostrar_mensaje('El Mes en Contabilidad esta cerrado. Reapertúrelo para que se pueda generar la depreciación del Activo Fijo.', 'exclamation')
	RETURN 0
END IF
IF fecha_bloqueada(vg_codcia, MONTH(fecha), YEAR(fecha)) THEN
	CALL fl_mostrar_mensaje('No puede generar depreciación del Activo Fijo de un mes bloqueado en CONTABILIDAD.', 'exclamation')
	RETURN 0
END IF
RETURN 1

END FUNCTION



FUNCTION fecha_bloqueada(codcia, mes, ano)
DEFINE codcia 		LIKE ctbt006.b06_compania
DEFINE mes, ano		SMALLINT
DEFINE r_b06		RECORD LIKE ctbt006.*

INITIALIZE r_b06.* TO NULL 
SELECT * INTO r_b06.*
	FROM ctbt006
	WHERE b06_compania = codcia
	  AND b06_ano      = ano
	  AND b06_mes      = mes
IF r_b06.b06_mes IS NOT NULL THEN
	CALL fl_mostrar_mensaje('Mes contable está bloqueado.','exclamation')
	RETURN 1
END IF
RETURN 0

END FUNCTION



FUNCTION muestra_mensaje_error_continuar_act(activo, prefi, palabra, palabra2)
DEFINE activo		LIKE actt010.a10_codigo_bien
DEFINE prefi		CHAR(2)
DEFINE palabra		VARCHAR(15)
DEFINE palabra2		VARCHAR(15)
DEFINE query		CHAR(1000)
DEFINE varusu		VARCHAR(100)
DEFINE usuario		LIKE gent005.g05_usuario

LET query = 'SELECT UNIQUE s.username ',
		' FROM sysmaster:syslocks l, sysmaster:syssessions s ',
		' WHERE type    = "U" ',
		'   AND sid     <> DBINFO("sessionid") ',
		'   AND owner   = sid ',
		'   AND tabname = "actt0', prefi, '"',
		'   AND rowidlk IN ',
			' (SELECT ROWID FROM actt0', prefi,
				' WHERE a', prefi, '_compania    = ', vg_codcia,
				'   AND a', prefi, '_codigo_bien = ', activo,')'
PREPARE cons_blo FROM query
DECLARE q_blo CURSOR FOR cons_blo
LET varusu = NULL
FOREACH q_blo INTO usuario
	IF varusu IS NULL THEN
		LET varusu = UPSHIFT(usuario) CLIPPED
	ELSE
		LET varusu = varusu CLIPPED, ' ', UPSHIFT(usuario) CLIPPED
	END IF
END FOREACH
RETURN mensaje_error(activo, palabra, palabra2, varusu)

END FUNCTION



FUNCTION mensaje_error(activo, palabra, palabra2, varusu)
DEFINE activo		LIKE actt010.a10_codigo_bien
DEFINE palabra		VARCHAR(15)
DEFINE palabra2		VARCHAR(15)
DEFINE varusu		VARCHAR(100)
DEFINE resp		CHAR(6)
DEFINE mensaje		VARCHAR(255)

LET mensaje = 'El código de Activo Fijo ', activo USING "<<<<<<&",
		' esta siendo bloqueado por el(los) usuario(s) ',varusu CLIPPED,
		'. Desea intentar nuevamente esta ', palabra2 CLIPPED, ' ?'
CALL fl_hacer_pregunta(mensaje, 'Yes') RETURNING resp
IF resp = 'Yes' THEN
	RETURN 1
END IF
LET mensaje = 'No se ha podido ', palabra CLIPPED, ' el registro del ',
		'código de Activo Fijo ', activo USING "<<<<<<&",
		'. LLAME AL ADMINISTRADOR.'
CALL fl_mostrar_mensaje(mensaje, 'stop')
RETURN 0

END FUNCTION



FUNCTION control_movimientos(activo)
DEFINE activo		LIKE actt010.a10_codigo_bien
DEFINE r_reg		RECORD
				a12_codigo_tran	LIKE actt012.a12_codigo_tran,
				a12_numero_tran	LIKE actt012.a12_numero_tran,
				a12_tipcomp_gen	LIKE actt012.a12_tipcomp_gen,
				a12_numcomp_gen	LIKE actt012.a12_numcomp_gen,
				a12_fecing	LIKE actt012.a12_fecing,
				a12_referencia	LIKE actt012.a12_referencia,
				a12_porc_deprec	LIKE actt012.a12_porc_deprec,
				a12_valor_mb	LIKE actt012.a12_valor_mb
			END RECORD
DEFINE r_a01		RECORD LIKE actt001.*
DEFINE r_a10		RECORD LIKE actt010.*
DEFINE num_row, max_row	SMALLINT
DEFINE i, j, col	SMALLINT
DEFINE total		DECIMAL(14,2)
DEFINE query		CHAR(1500)

LET max_row = 200
OPEN WINDOW w_actf202_2 AT 04, 02 WITH 20 ROWS, 80 COLUMNS
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE FIRST,
                  BORDER, MESSAGE LINE LAST)
OPEN FORM f_actf202_2 FROM '../forms/actf202_2'
DISPLAY FORM f_actf202_2
DISPLAY "TP"		TO tit_col1
DISPLAY "Número"	TO tit_col2
DISPLAY "DC"		TO tit_col3
DISPLAY "Compr."	TO tit_col4
DISPLAY "Fecha"		TO tit_col5
DISPLAY "Referencia"	TO tit_col6
DISPLAY "%"		TO tit_col7
DISPLAY "Valor"		TO tit_col8
CALL fl_lee_codigo_bien(vg_codcia, activo) RETURNING r_a10.*
CALL fl_lee_grupo_activo(r_a10.a10_compania, r_a10.a10_grupo_act)
	RETURNING r_a01.*
DISPLAY BY NAME r_a10.a10_grupo_act, r_a10.a10_codigo_bien,
		r_a10.a10_descripcion, r_a10.a10_valor_mb, r_a10.a10_tot_dep_mb,
		r_a01.a01_nombre
FOR i = 1 TO max_row
	INITIALIZE r_mov[i].* TO NULL
END FOR
FOR i = 1 TO 10
	LET rm_orden[i] = '' 
END FOR
LET col           = 5
LET vm_columna_1  = col
LET vm_columna_2  = 1
LET rm_orden[col] = 'ASC'
WHILE TRUE
	LET query = 'SELECT a12_codigo_tran, a12_numero_tran, a12_tipcomp_gen,',
				' a12_numcomp_gen, a12_fecing, a12_referencia,',
				' a12_porc_deprec, a12_valor_mb ',
			' FROM actt012 ',
			' WHERE a12_compania    = ', r_a10.a10_compania,
			'   AND a12_codigo_bien = ', r_a10.a10_codigo_bien,
			' ORDER BY ', vm_columna_1, ' ', rm_orden[vm_columna_1],
				', ', vm_columna_2, ' ', rm_orden[vm_columna_2]
	PREPARE mov FROM query
	DECLARE q_mov CURSOR FOR mov
	LET total   = 0
	LET num_row = 1
	FOREACH q_mov INTO r_reg.*
		LET r_mov[num_row].a12_codigo_tran = r_reg.a12_codigo_tran
		LET r_mov[num_row].a12_numero_tran = r_reg.a12_numero_tran
		LET r_mov[num_row].a12_tipcomp_gen = r_reg.a12_tipcomp_gen
		LET r_mov[num_row].a12_numcomp_gen = r_reg.a12_numcomp_gen
		LET r_mov[num_row].a12_fecing      = DATE(r_reg.a12_fecing)
		LET r_mov[num_row].a12_referencia  = r_reg.a12_referencia
		LET r_mov[num_row].a12_porc_deprec = r_reg.a12_porc_deprec
		LET r_mov[num_row].a12_valor_mb    = r_reg.a12_valor_mb
		LET total = total + r_mov[num_row].a12_valor_mb
		LET num_row = num_row + 1
		IF num_row > max_row THEN
			EXIT FOREACH
		END IF
	END FOREACH
	LET num_row = num_row - 1
	IF num_row = 0 THEN
		CALL fl_mensaje_consulta_sin_registros()
		EXIT WHILE
	END IF
	DISPLAY BY NAME total
	LET int_flag = 0
	CALL set_count(num_row)
	DISPLAY ARRAY r_mov TO r_mov.*
		ON KEY(INTERRUPT)
			LET int_flag = 1
			EXIT DISPLAY
		ON KEY(F5)
			LET i = arr_curr()
			CALL ver_bien(r_a10.a10_codigo_bien)
			LET int_flag = 0
		ON KEY(F6)
			CALL ver_orden_compra(r_a10.a10_codigo_bien)
			LET int_flag = 0
		ON KEY(F7)
			LET i = arr_curr()
			CALL ver_transaccion(r_mov[i].a12_codigo_tran,
						r_mov[i].a12_numero_tran)
			LET int_flag = 0
		ON KEY(F8)
			LET i = arr_curr()
			CALL control_contabilizacion(activo, r_mov[i].*)
			LET int_flag = 0
		ON KEY(F9)
			CALL control_imprimir_mov(activo, num_row)
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
		ON KEY(F20)
			LET col = 6
			EXIT DISPLAY
		ON KEY(F21)
			LET col = 7
			EXIT DISPLAY
		ON KEY(F22)
			LET col = 8
			EXIT DISPLAY
		BEFORE DISPLAY 
			--#CALL dialog.keysetlabel("ACCEPT","")
		BEFORE ROW
			LET i = arr_curr()
			LET j = scr_line()
			DISPLAY i       TO num_row
			DISPLAY num_row TO max_row
			DISPLAY r_mov[i].a12_referencia TO referencia
		AFTER DISPLAY 
			CONTINUE DISPLAY
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
LET int_flag = 0
CLOSE WINDOW w_actf202_2
RETURN

END FUNCTION



FUNCTION control_contabilizacion(activo, r_mov)
DEFINE activo		LIKE actt010.a10_codigo_bien
DEFINE r_mov		RECORD
				a12_codigo_tran	LIKE actt012.a12_codigo_tran,
				a12_numero_tran	LIKE actt012.a12_numero_tran,
				a12_tipcomp_gen	LIKE actt012.a12_tipcomp_gen,
				a12_numcomp_gen	LIKE actt012.a12_numcomp_gen,
				a12_fecing	DATE,
				a12_referencia	LIKE actt012.a12_referencia,
				a12_porc_deprec	LIKE actt012.a12_porc_deprec,
				a12_valor_mb	LIKE actt012.a12_valor_mb
			END RECORD
DEFINE r_det		ARRAY[500] OF RECORD
				tipo_comp	LIKE actt015.a15_tipo_comp,
				num_comp	LIKE actt015.a15_num_comp,
				cuenta		LIKE ctbt010.b10_cuenta,
				descripcion	LIKE ctbt010.b10_descripcion,
				valor_db	LIKE ctbt013.b13_valor_base,
				valor_cr	LIKE ctbt013.b13_valor_base
			END RECORD
DEFINE r_adi		ARRAY[500] OF RECORD
				subtipo		LIKE ctbt004.b04_subtipo,
				desc_sub	LIKE ctbt004.b04_nombre,
				glosa		LIKE ctbt013.b13_glosa
			END RECORD
DEFINE r_a01		RECORD LIKE actt001.*
DEFINE r_a10		RECORD LIKE actt010.*
DEFINE tipo		LIKE actt012.a12_tipcomp_gen
DEFINE num		LIKE actt012.a12_numcomp_gen
DEFINE tipo_cta		LIKE ctbt010.b10_tipo_cta
DEFINE total_db		LIKE ctbt013.b13_valor_base
DEFINE total_cr		LIKE ctbt013.b13_valor_base
DEFINE util_per		LIKE ctbt013.b13_valor_base
DEFINE query		CHAR(1500)
DEFINE num_row, i	SMALLINT
DEFINE max_row		SMALLINT

IF r_mov.a12_codigo_tran <> vm_cod_tran3 THEN
	SELECT a12_tipcomp_gen, a12_numcomp_gen
		INTO tipo, num
		FROM actt012
		WHERE a12_compania    = vg_codcia
		  AND a12_codigo_tran = r_mov.a12_codigo_tran
		  AND a12_numero_tran = r_mov.a12_numero_tran
	CALL ver_contabilizacion(tipo, num)
	RETURN
END IF
LET query = 'SELECT a15_tipo_comp, a15_num_comp, b13_cuenta, b10_descripcion, ',
		' CASE WHEN b13_valor_base > 0 ',
			'THEN b13_valor_base ',
			'ELSE 0.00 ',
		' END, ',
		' CASE WHEN b13_valor_base <= 0 ',
			'THEN b13_valor_base ',
			'ELSE 0.00 ',
		' END * (-1), ',
		' b12_subtipo, b04_nombre, b13_glosa, b10_tipo_cta, ',
		' b13_secuencia, b12_fecing ',
		' FROM actt015, ctbt012, ctbt013, ctbt010, ctbt004 ',
		' WHERE a15_compania    = ', vg_codcia,
		'   AND a15_codigo_tran = "', r_mov.a12_codigo_tran, '"',
		'   AND a15_numero_tran = ', r_mov.a12_numero_tran,
		'   AND b12_compania    = a15_compania ',
		'   AND b12_tipo_comp   = a15_tipo_comp ',
		'   AND b12_num_comp    = a15_num_comp ',
		'   AND b13_compania    = b12_compania ',
		'   AND b13_tipo_comp   = b12_tipo_comp ',
		'   AND b13_num_comp    = b12_num_comp ',
		'   AND b10_compania    = b13_compania ',
		'   AND b10_cuenta      = b13_cuenta ',
		'   AND b04_compania    = b12_compania ',
		'   AND b04_subtipo     = b12_subtipo ',
		' ORDER BY b12_fecing, b12_subtipo, b13_secuencia '
PREPARE cons_dett FROM query
DECLARE q_cursor1 CURSOR FOR cons_dett
LET max_row  = 500
LET num_row  = 1
LET total_db = 0
LET total_cr = 0
LET util_per = 0
FOREACH q_cursor1 INTO r_det[num_row].*, r_adi[num_row].*, tipo_cta
	LET total_db = total_db + r_det[num_row].valor_db
	LET total_cr = total_cr + r_det[num_row].valor_cr
	IF tipo_cta = 'R' THEN
		LET util_per = util_per +
			(r_det[num_row].valor_db - r_det[num_row].valor_cr)
	END IF
	LET num_row  = num_row + 1
	IF num_row > max_row THEN
		EXIT FOREACH
	END IF
END FOREACH
LET num_row = num_row - 1
IF num_row = 0 THEN
	CALL fl_mostrar_mensaje('No se ha generado ningun diario contable. Llame al Administrador.', 'exclamation')
	RETURN
END IF
OPEN WINDOW w_actf202_4 AT 03, 02 WITH 21 ROWS, 78 COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE 0, BORDER,
		MESSAGE LINE LAST)
IF vg_gui = 1 THEN
	OPEN FORM f_actf202_4 FROM '../forms/actf202_4'
ELSE
	OPEN FORM f_actf202_4 FROM '../forms/actf202_4c'
END IF
DISPLAY FORM f_actf202_4
--#DISPLAY 'Comprobante' TO tit_col1
--#DISPLAY 'Cuenta'      TO tit_col2
--#DISPLAY 'Descripcion' TO tit_col3
--#DISPLAY 'Debito'      TO tit_col4
--#DISPLAY 'Credito'     TO tit_col5
CALL fl_lee_codigo_bien(vg_codcia, activo) RETURNING r_a10.*
CALL fl_lee_grupo_activo(r_a10.a10_compania, r_a10.a10_grupo_act)
	RETURNING r_a01.*
DISPLAY BY NAME r_a10.a10_grupo_act, r_a10.a10_codigo_bien,
		r_a10.a10_descripcion, r_a10.a10_valor_mb, r_a10.a10_tot_dep_mb,
		r_a01.a01_nombre, r_mov.a12_codigo_tran, r_mov.a12_numero_tran,
		r_mov.a12_fecing, r_mov.a12_referencia, r_mov.a12_valor_mb,
		total_db, total_cr, util_per
LET int_flag = 0
CALL set_count(num_row)
DISPLAY ARRAY r_det TO r_det.*
	ON KEY(INTERRUPT)
		LET int_flag = 1
		EXIT DISPLAY
	ON KEY(F5)
		LET i = arr_curr()
		IF r_det[i].tipo_comp IS NOT NULL THEN
			CALL ver_contabilizacion(r_det[i].tipo_comp,
							r_det[i].num_comp)	
			LET int_flag = 0
		END IF
	--#BEFORE DISPLAY
		--#CALL dialog.keysetlabel('ACCEPT', '')
	--#BEFORE ROW
		--#LET i = arr_curr()
		--#DISPLAY i       TO num_row
		--#DISPLAY num_row TO max_row
		--#DISPLAY BY NAME r_adi[i].*
		--#IF r_det[i].tipo_comp IS NOT NULL THEN
			--#CALL dialog.keysetlabel('F5', 'Contabilizacion')
		--#ELSE
			--#CALL dialog.keysetlabel('F5', '')
		--#END IF
	--#AFTER DISPLAY
		--#CONTINUE DISPLAY
END DISPLAY
LET int_flag = 0
CLOSE WINDOW w_actf202_4
RETURN

END FUNCTION



FUNCTION ver_orden_compra(activo)
DEFINE activo		LIKE actt010.a10_codigo_bien
DEFINE r_a10		RECORD LIKE actt010.*
DEFINE param		VARCHAR(60)

CALL fl_lee_codigo_bien(vg_codcia, activo) RETURNING r_a10.*
IF r_a10.a10_numero_oc IS NULL THEN
	CALL fl_mostrar_mensaje('Este Bien no tiene una orden de compra asociada.', 'exclamation')
	RETURN
END IF
LET param = ' ', vg_codloc, ' ', r_a10.a10_numero_oc
CALL ejecuta_comando('COMPRAS', 'OC', 'ordp200', param)

END FUNCTION



FUNCTION ver_transaccion(codtran, numtran)
DEFINE codtran		LIKE actt012.a12_codigo_tran
DEFINE numtran		LIKE actt012.a12_numero_tran
DEFINE param		VARCHAR(60)

LET param = ' "', codtran, '" ', numtran
CALL ejecuta_comando('ACTIVOS', vg_modulo, 'actp200', param)

END FUNCTION



FUNCTION ver_contabilizacion(tipo, num)
DEFINE tipo		LIKE actt012.a12_tipcomp_gen
DEFINE num		LIKE actt012.a12_numcomp_gen
DEFINE param		VARCHAR(60)

LET param = ' ', tipo, ' ', num
CALL ejecuta_comando('CONTABILIDAD', 'CB', 'ctbp201', param)

END FUNCTION



FUNCTION imprime_diario(tipo_comp, num_comp)
DEFINE tipo_comp	LIKE ctbt012.b12_tipo_comp
DEFINE num_comp		LIKE ctbt012.b12_num_comp
DEFINE param		VARCHAR(60)

LET param = ' ', vg_codloc, ' "', tipo_comp, '" ', num_comp
CALL ejecuta_comando('TESORERIA', 'TE', 'cxpp403', param)

END FUNCTION



FUNCTION control_imprimir_mov(activo, num_row)
DEFINE activo		LIKE actt010.a10_codigo_bien
DEFINE num_row		SMALLINT
DEFINE comando		VARCHAR(100)
DEFINE i		SMALLINT

CALL fl_control_reportes() RETURNING comando
IF int_flag THEN
	RETURN
END IF
START REPORT reporte_movimiento_activo TO PIPE comando
FOR i = 1 TO num_row
	OUTPUT TO REPORT reporte_movimiento_activo(activo, i)
END FOR
FINISH REPORT reporte_movimiento_activo

END FUNCTION



REPORT reporte_movimiento_activo(activo, i)
DEFINE activo		LIKE actt010.a10_codigo_bien
DEFINE i		SMALLINT
DEFINE r_a10		RECORD LIKE actt010.*
DEFINE r_g01		RECORD LIKE gent001.*
DEFINE r_g50		RECORD LIKE gent050.*
DEFINE util_per		LIKE ctbt013.b13_valor_base
DEFINE etiqueta		VARCHAR(12)
DEFINE col		SMALLINT
DEFINE usuario		VARCHAR(19,15)
DEFINE modulo		VARCHAR(40)
DEFINE escape		SMALLINT
DEFINE act_comp		SMALLINT
DEFINE desact_comp	SMALLINT
DEFINE act_10cpi	SMALLINT
DEFINE act_12cpi	SMALLINT
DEFINE act_neg, des_neg	SMALLINT

OUTPUT
	TOP MARGIN	1
	LEFT MARGIN	0
	RIGHT MARGIN	80
	BOTTOM MARGIN	4
	PAGE LENGTH	66

FORMAT

PAGE HEADER
	LET escape	= 27		# Iniciar sec. impresión
	LET act_comp	= 15		# Activar Comprimido.
	LET desact_comp	= 18		# Cancelar Comprimido.
	LET act_neg	= 71		# Activar negrita.
	LET des_neg	= 72		# Desactivar negrita.
	LET act_10cpi	= 80		# Comprimido 10 CPI.
	LET act_12cpi	= 77		# Comprimido 12 CPI.
	CALL fl_lee_modulo(vg_modulo) RETURNING r_g50.*
	LET modulo      = "MODULO: ", r_g50.g50_nombre[1, 19] CLIPPED
	LET usuario     = "USUARIO: ", vg_usuario
	CALL fl_justifica_titulo('D', usuario, 19) RETURNING usuario
	CALL fl_lee_compania(vg_codcia) RETURNING r_g01.*
	print ASCII escape;
	print ASCII desact_comp;
	print ASCII escape;
	print ASCII act_10cpi;
	PRINT COLUMN 005, r_g01.g01_razonsocial,
  	      COLUMN 074, "PAGINA: ", PAGENO USING "&&&"
	PRINT COLUMN 001, modulo CLIPPED,
	      COLUMN 026, "MOVIMIENTOS DEL ACTIVO FIJO",
	      COLUMN 074, UPSHIFT(vg_proceso) CLIPPED
	SKIP 1 LINES
	CALL fl_lee_codigo_bien(vg_codcia, activo) RETURNING r_a10.*
	PRINT COLUMN 010, "** ACTIVO FIJO: ", activo USING "<<<&&&",
		" ", r_a10.a10_descripcion CLIPPED
	SKIP 1 LINES
	PRINT COLUMN 001, "FECHA IMPRESION: ", TODAY USING "dd-mm-yyyy",
 		1 SPACES, TIME,
	      COLUMN 062, usuario CLIPPED
	PRINT COLUMN 001, "--------------------------------------------------------------------------------"
	PRINT COLUMN 001, "TP",
	      COLUMN 004, "NUMERO",
	      COLUMN 011, "COMP. CONT.",
	      COLUMN 023, "FECHA TRAN",
	      COLUMN 038, "R E F E R E N C I A",
	      COLUMN 062, "% DEP",
	      COLUMN 069, "VALOR TRANS."
	PRINT COLUMN 001, "--------------------------------------------------------------------------------"

ON EVERY ROW
	NEED 4 LINES
	PRINT COLUMN 001, r_mov[i].a12_codigo_tran	CLIPPED,
	      COLUMN 004, r_mov[i].a12_numero_tran	USING "<<<<&&",
	      COLUMN 011, r_mov[i].a12_tipcomp_gen	CLIPPED,
	      COLUMN 014, r_mov[i].a12_numcomp_gen	CLIPPED,
	      COLUMN 023, r_mov[i].a12_fecing		USING "dd-mm-yyyy",
	      COLUMN 034, r_mov[i].a12_referencia[1, 27] CLIPPED,
	      COLUMN 062, r_mov[i].a12_porc_deprec	USING "#&.##",
	      COLUMN 068, r_mov[i].a12_valor_mb		USING "--,---,--&.##"

ON LAST ROW
	NEED 3 LINES
	print ASCII escape;
	print ASCII act_neg;
	PRINT COLUMN 070, "-------------"
	PRINT COLUMN 057, "TOTAL ==>",
	      COLUMN 068, SUM(r_mov[i].a12_valor_mb)	USING "--,---,--&.##"
	SELECT NVL(SUM(b13_valor_base), 0)
		INTO util_per
		FROM actt012, actt015, ctbt012, ctbt013, ctbt010
		WHERE a12_compania    = vg_codcia
		  AND a12_codigo_tran = 'VE'
		  AND a12_codigo_bien = activo
		  AND a15_compania    = a12_compania
		  AND a15_codigo_tran = a12_codigo_tran
		  AND a15_numero_tran = a12_numero_tran
		  AND b12_compania    = a15_compania
		  AND b12_tipo_comp   = a15_tipo_comp
		  AND b12_num_comp    = a15_num_comp
		  AND b12_estado      <> 'E'
		  AND b13_compania    = b12_compania
		  AND b13_tipo_comp   = b12_tipo_comp
		  AND b13_num_comp    = b12_num_comp
		  AND b10_compania    = b13_compania
		  AND b10_cuenta      = b13_cuenta
		  AND b10_tipo_cta    = 'R'
	IF util_per <> 0 THEN
		LET etiqueta = 'PERDIDA ==>'
		LET col      = 55
		IF util_per < 0 THEN
			LET util_per = util_per * (-1)
			LET etiqueta = 'UTILIDAD ==>'
			LET col      = 54
		END IF
		SKIP 1 LINES
		PRINT COLUMN col, etiqueta	CLIPPED,
		      COLUMN 068, util_per	USING "--,---,--&.##";
	ELSE
		PRINT ' ';
	END IF
	print ASCII escape;
	print ASCII des_neg;
	print ASCII escape;
	print ASCII act_comp

END REPORT
