--------------------------------------------------------------------------------
-- Titulo               : actp200.4gl -- Transferencia de Activos Fijos
-- Elaboracion          : 20-Jun-2003
-- Autor                : NPC
-- Formato de Ejecucion : fglrun actp200 base modulo compania [codtran numtran]
-- Ultima Correccion    : 
-- Motivo Correccion    : 
--------------------------------------------------------------------------------
                                                                                
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE rm_a10		RECORD LIKE actt010.* 
DEFINE rm_a12		RECORD LIKE actt012.* 
DEFINE vm_row_current	INTEGER       
DEFINE vm_num_rows      INTEGER      
DEFINE vm_max_rows      INTEGER     
DEFINE vm_r_rows	ARRAY [1000] OF INTEGER

DEFINE rm_a00		RECORD LIKE actt000.*
DEFINE rm_b00		RECORD LIKE ctbt000.*
DEFINE rm_b12		RECORD LIKE ctbt012.*
DEFINE vm_last_lvl	LIKE ctbt001.b01_nivel
DEFINE vm_cod_tran1	LIKE actt012.a12_codigo_tran
DEFINE vm_sub_tra	LIKE ctbt004.b04_subtipo
DEFINE rm_orden 	ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1	SMALLINT
DEFINE vm_columna_2	SMALLINT
DEFINE rm_par		RECORD
				cod_grupo	LIKE actt001.a01_grupo_act,
				desc_grupo	LIKE actt001.a01_nombre,
				tipo		CHAR(1),
				codigo_bien	LIKE actt010.a10_codigo_bien,
				desc_bien	LIKE actt010.a10_descripcion,
				fecha_ini	LIKE actt010.a10_fecha_comp,
				fecha_fin	LIKE actt010.a10_fecha_comp,
				estado		LIKE actt010.a10_estado,
				tit_estado	LIKE actt006.a06_descripcion
			END RECORD
DEFINE rm_detalle	ARRAY[20000] OF RECORD
				a10_codigo_bien	LIKE actt010.a10_codigo_bien,
				a10_descripcion	LIKE actt010.a10_descripcion,
				a12_codigo_tran	LIKE actt012.a12_codigo_tran,
				a12_numero_tran	LIKE actt012.a12_numero_tran,
				a12_fecing	DATE,
				a12_referencia	LIKE actt012.a12_referencia,
				codigo_dest	LIKE actt012.a12_codigo_tran,
				numero_dest	LIKE actt012.a12_numero_tran
			END RECORD
DEFINE vm_max_det	INTEGER
DEFINE vm_num_det	INTEGER
DEFINE vm_fec_pro	DATE



MAIN
                                                                            
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/actp200.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 3 AND num_args() <> 5 THEN   -- Validar # parámetros correcto
	CALL fl_mostrar_mensaje('Numero de parametros incorrecto.','stop')
	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_proceso = 'actp200'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()
--#CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()  
END MAIN



FUNCTION funcion_master()

CALL fl_nivel_isolation()
CALL fl_lee_compania_contabilidad(vg_codcia) RETURNING rm_b00.*
IF rm_b00.b00_compania IS NULL THEN
	CALL fl_mostrar_mensaje('No existe ninguna compañía configurada en CONTABILIDAD.', 'stop')
	EXIT PROGRAM
END IF
CALL fl_lee_compania_activos(vg_codcia) RETURNING rm_a00.*
IF rm_a00.a00_compania IS NULL THEN
	CALL fl_mostrar_mensaje('No existe ninguna compañía configurada en ACTIVOS FIJOS.', 'stop')
	EXIT PROGRAM
END IF
LET vm_max_det     = 20000
LET vm_max_rows    = 1000
LET vm_row_current = 0
IF num_args() <> 3 THEN
	INITIALIZE rm_a10.* TO NULL
	CALL ver_origen(arg_val(4), arg_val(5))
	EXIT PROGRAM
END IF
OPEN WINDOW w_actf200_1 AT 3, 2 WITH 22 ROWS, 80 COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE 0, BORDER,
			MESSAGE LINE LAST - 1)
OPEN FORM f_actf200_1 FROM '../forms/actf200_1'
DISPLAY FORM f_actf200_1
CALL setea_botones()
LET vm_fec_pro = MDY(rm_a00.a00_mespro, 01, rm_a00.a00_anopro) - 1 UNITS DAY
CALL borrar_cabecera()
SELECT NVL(MIN(a10_fecha_comp), MDY(01, 01, 1990))
	INTO rm_par.fecha_ini
	FROM actt010
	WHERE a10_compania  = vg_codcia
	  AND a10_estado   IN ("S", "D", "R")
LET rm_par.fecha_fin = TODAY
LET rm_par.estado    = 'X'
CALL muestra_estado(rm_par.estado, 1) RETURNING rm_par.tit_estado
LET rm_par.tipo      = 'R'
WHILE TRUE
	LET vm_num_rows = 0
	CALL muestra_contadores_det(0, vm_num_rows)
	CALL borrar_detalle()
	CALL lee_parametros()
	IF int_flag THEN
		EXIT WHILE
	END IF
	IF NOT preparar_consulta() THEN
		IF NOT int_flag THEN
			DROP TABLE tmp_mov
		END IF
		CONTINUE WHILE
	END IF
	CALL control_muestra_detalle()
	DROP TABLE tmp_mov
END WHILE
CLOSE WINDOW w_actf200_1

END FUNCTION



FUNCTION lee_parametros()
DEFINE r_a01		RECORD LIKE actt001.*
DEFINE r_a10		RECORD LIKE actt010.*
DEFINE fec_ini, fec_fin	LIKE actt010.a10_fecha_comp

LET int_flag = 0
INPUT BY NAME rm_par.*
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		LET int_flag = 1
		EXIT INPUT
	ON KEY(F2)
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
							NULL, rm_par.estado, 1)
				RETURNING r_a10.a10_codigo_bien,
					  r_a10.a10_descripcion
			IF r_a10.a10_codigo_bien IS NOT NULL THEN
				LET rm_par.codigo_bien = r_a10.a10_codigo_bien
				LET rm_par.desc_bien   = r_a10.a10_descripcion
				DISPLAY BY NAME rm_par.codigo_bien,
						rm_par.desc_bien
			END IF
		END IF
		LET int_flag = 0
	BEFORE FIELD fecha_ini
		LET fec_ini = rm_par.fecha_ini
	BEFORE FIELD fecha_fin
		LET fec_fin = rm_par.fecha_fin
	AFTER FIELD cod_grupo
		IF rm_par.cod_grupo IS NOT NULL THEN
			CALL fl_lee_grupo_activo(vg_codcia, rm_par.cod_grupo)
				RETURNING r_a01.* 
			IF r_a01.a01_grupo_act IS NULL THEN
				CALL fl_mostrar_mensaje('No existe este Grupo de Activos Fijos en la compañía.', 'exclamation')
                                NEXT FIELD cod_grupo
                        END IF
			LET rm_par.desc_grupo = r_a01.a01_nombre
			DISPLAY BY NAME rm_par.desc_grupo
		ELSE
			CLEAR desc_grupo
		END IF
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
			   r_a10.a10_estado <> 'R'
			THEN
				CALL fl_mostrar_mensaje('El Activo Fijo debe tener estado de DEPRECIADO, CON STOCK ó DADO BAJA.', 'exclamation')
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
			CLEAR desc_bien
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
END INPUT

END FUNCTION



FUNCTION preparar_consulta()
DEFINE r_a10		RECORD LIKE actt010.*
DEFINE query		CHAR(3000)
DEFINE exp_gru		VARCHAR(100)
DEFINE exp_act		VARCHAR(100)

LET exp_gru = NULL
IF rm_par.cod_grupo IS NOT NULL THEN
	LET exp_gru = '   AND a10_grupo_act    = ', rm_par.cod_grupo
END IF
LET exp_act = NULL
IF rm_par.codigo_bien IS NOT NULL THEN
	LET exp_act = '   AND a10_codigo_bien  = ', rm_par.codigo_bien
END IF
LET query = ' SELECT a10_codigo_bien, a10_descripcion, a12_codigo_tran, ',
			'a12_numero_tran, a12_fecing, a12_referencia, ',
			'"" codigo_dest, "" numero_dest ',
		' FROM actt010, OUTER actt012 ',
		' WHERE a10_compania     = ', vg_codcia,
		exp_gru CLIPPED,
		exp_act CLIPPED,
	--fl_retorna_expr_estado_act(vg_codcia, rm_par.estado, 1) CLIPPED,
		'   AND a10_estado       IN ("S", "D", "R", "N") ',
		'   AND a10_fecha_comp   BETWEEN "', rm_par.fecha_ini,
					  '" AND "', rm_par.fecha_fin, '"',
		'   AND a12_compania     = a10_compania ',
		'   AND a12_codigo_tran  = "TR" ',
		'   AND a12_codigo_bien  = a10_codigo_bien ',
		' INTO TEMP tmp_mov '
PREPARE expresion FROM query
EXECUTE expresion
SELECT COUNT(*) INTO vm_num_det FROM tmp_mov
IF vm_num_det = 0 THEN
	CALL fl_mensaje_consulta_sin_registros()
	RETURN 0
END IF
RETURN 1

END FUNCTION



FUNCTION control_muestra_detalle()
DEFINE r_reg		RECORD
				a10_codigo_bien	LIKE actt010.a10_codigo_bien,
				a10_descripcion	LIKE actt010.a10_descripcion,
				a12_codigo_tran	LIKE actt012.a12_codigo_tran,
				a12_numero_tran	LIKE actt012.a12_numero_tran,
				a12_fecing	DATE,
				a12_referencia	LIKE actt012.a12_referencia,
				codigo_dest	LIKE actt012.a12_codigo_tran,
				numero_dest	LIKE actt012.a12_numero_tran
			END RECORD
DEFINE i, j, col	SMALLINT
DEFINE query		CHAR(1500)

FOR i = 1 TO 10
	LET rm_orden[i] = ''
END FOR
LET col           = 4
LET vm_columna_1  = col
LET vm_columna_2  = 1
LET rm_orden[col] = 'DESC'
WHILE TRUE
	LET query = 'SELECT * FROM tmp_mov ',
			' ORDER BY ', vm_columna_1, ' ', rm_orden[vm_columna_1],
				', ', vm_columna_2, ' ', rm_orden[vm_columna_2]
	PREPARE mov FROM query
	DECLARE q_mov CURSOR FOR mov
	LET vm_num_det = 1
	FOREACH q_mov INTO r_reg.*
		LET rm_detalle[vm_num_det].a10_codigo_bien =
							r_reg.a10_codigo_bien
		LET rm_detalle[vm_num_det].a10_descripcion =
							r_reg.a10_descripcion
		LET rm_detalle[vm_num_det].a12_codigo_tran =
							r_reg.a12_codigo_tran
		LET rm_detalle[vm_num_det].a12_numero_tran =
							r_reg.a12_numero_tran
		LET rm_detalle[vm_num_det].a12_fecing      =
							DATE(r_reg.a12_fecing)
		LET rm_detalle[vm_num_det].a12_referencia  =
							r_reg.a12_referencia
		LET rm_detalle[vm_num_det].codigo_dest     = r_reg.codigo_dest
		LET rm_detalle[vm_num_det].numero_dest     = r_reg.numero_dest
		LET vm_num_det = vm_num_det + 1
		IF vm_num_det > vm_max_det THEN
			EXIT FOREACH
		END IF
	END FOREACH
	LET vm_num_det = vm_num_det - 1
	IF vm_num_det = 0 THEN
		CALL fl_mensaje_consulta_sin_registros()
		EXIT WHILE
	END IF
	LET int_flag = 0
	CALL set_count(vm_num_det)
	DISPLAY ARRAY rm_detalle TO rm_detalle.*
		ON KEY(INTERRUPT)
			LET int_flag = 1
			EXIT DISPLAY                 
		ON KEY(F5)
			CALL ver_activo(rm_detalle[i].a10_codigo_bien)
			LET int_flag = 0
		ON KEY(F10)
			CALL ver_origen(rm_detalle[i].a12_codigo_tran,
					rm_detalle[i].a12_numero_tran)
			LET int_flag = 0
		ON KEY(F15)
			LET col = 1
			EXIT DISPLAY
		ON KEY(F16)
			LET col = 2
			EXIT DISPLAY
		ON KEY(F17)
			LET col = 4
			EXIT DISPLAY
		ON KEY(F18)
			LET col = 5
			EXIT DISPLAY
		ON KEY(F19)
			LET col = 6
			EXIT DISPLAY
		ON KEY(F20)
			LET col = 8
			EXIT DISPLAY
		BEFORE DISPLAY
			CALL dialog.keysetlabel('ACCEPT','')
		BEFORE ROW
			LET i = arr_curr()
			LET j = scr_line()
			CALL muestra_contadores_det(i, vm_num_det)
			DISPLAY rm_detalle[i].a10_descripcion TO descripcion
			DISPLAY rm_detalle[i].a12_referencia  TO referencia
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

END FUNCTION



{--
FUNCTION control_consulta()
DEFINE query		VARCHAR(1200)
DEFINE expr_sql		VARCHAR(800)
DEFINE expr_tran	VARCHAR(100)
DEFINE r_a10		RECORD LIKE actt010.*
DEFINE r_a12		RECORD LIKE actt012.*
DEFINE r_g02_o		RECORD LIKE gent002.*
DEFINE r_g34_o		RECORD LIKE gent034.*
DEFINE r_g02_d		RECORD LIKE gent002.*
DEFINE r_g34_d		RECORD LIKE gent034.*

CLEAR FORM
INITIALIZE rm_a10.*, rm_a12.*, expr_tran TO NULL
IF num_args() <> 5 THEN
	LET rm_a12.a12_codigo_tran = 'TR'
	DISPLAY BY NAME rm_a12.a12_codigo_tran
	LET expr_tran = '   AND a12_codigo_tran = "',rm_a12.a12_codigo_tran, '"'
	LET int_flag = 0
	CONSTRUCT BY NAME expr_sql ON a12_numero_tran, a12_codigo_bien,
		a12_depto_ori, a12_locali_ori, a12_depto_dest, a12_locali_dest,
		a12_referencia, a12_usuario
	ON KEY(F2)
		IF INFIELD(a12_numero_tran) THEN
			CALL fl_ayuda_tran_activos(vg_codcia,
							rm_a12.a12_codigo_tran)
				RETURNING r_a12.a12_codigo_tran,
					  r_a12.a12_numero_tran,
					  r_a12.a12_codigo_bien,
					  r_a12.a12_referencia 
			IF r_a12.a12_numero_tran IS NOT NULL THEN
				DISPLAY BY NAME r_a12.a12_numero_tran,
						r_a12.a12_codigo_bien,
						r_a12.a12_referencia	
				CALL fl_lee_codigo_bien(vg_codcia,
							r_a12.a12_codigo_bien)
					RETURNING r_a10.*
				DISPLAY BY NAME r_a10.a10_descripcion	
			END IF
		END IF
		IF INFIELD(a12_codigo_bien) THEN
			CALL fl_ayuda_codigo_bien(vg_codcia, NULL, NULL, 'X', 1)
				RETURNING r_a10.a10_codigo_bien,
					  r_a10.a10_descripcion
			IF r_a10.a10_codigo_bien IS NOT NULL THEN
				DISPLAY r_a10.a10_codigo_bien TO a12_codigo_bien
				DISPLAY BY NAME r_a10.a10_descripcion	
			END IF 
		END IF
		IF INFIELD(a12_depto_ori) THEN
			CALL fl_ayuda_departamentos(vg_codcia) 
				RETURNING r_g34_o.g34_cod_depto,
					  r_g34_o.g34_nombre
			IF r_g34_o.g34_cod_depto IS NOT NULL THEN
				DISPLAY r_g34_o.g34_cod_depto TO a12_depto_ori
				DISPLAY r_g34_o.g34_nombre    TO tit_depto_ori
			END IF 
		END IF
		IF INFIELD(a12_locali_ori) THEN
			CALL fl_ayuda_localidad(vg_codcia) 
				RETURNING r_g02_o.g02_localidad,
					  r_g02_o.g02_nombre
			IF r_g02_o.g02_localidad IS NOT NULL THEN
				DISPLAY r_g02_o.g02_localidad TO a12_locali_ori
				DISPLAY r_g02_o.g02_nombre    TO tit_locali_ori
			END IF 
		END IF 
		IF INFIELD(a12_depto_dest) THEN
			CALL fl_ayuda_departamentos(vg_codcia) 
				RETURNING r_g34_d.g34_cod_depto,
					  r_g34_d.g34_nombre
			IF r_g34_d.g34_cod_depto IS NOT NULL THEN
				DISPLAY r_g34_d.g34_cod_depto TO a12_depto_dest
				DISPLAY r_g34_d.g34_nombre    TO tit_depto_dest
			END IF 
		END IF
		IF INFIELD(a12_locali_dest) THEN
			CALL fl_ayuda_localidad(vg_codcia) 
				RETURNING r_g02_d.g02_localidad,
					  r_g02_d.g02_nombre
			IF r_g02_d.g02_localidad IS NOT NULL THEN
				DISPLAY r_g02_d.g02_localidad TO a12_locali_dest
				DISPLAY r_g02_d.g02_nombre    TO tit_locali_dest
			END IF 
		END IF 
		LET int_flag = 0
	AFTER FIELD a12_codigo_bien
		LET r_a10.a10_codigo_bien = get_fldbuf(a12_codigo_bien)
		IF  r_a10.a10_codigo_bien IS NOT NULL THEN
			CALL fl_lee_codigo_bien(vg_codcia,r_a10.a10_codigo_bien)
				RETURNING r_a10.*
                        IF r_a10.a10_codigo_bien IS NULL THEN
				CALL fgl_winmessage(vg_producto, 'No existe Activo Fijo.', 'exclamation')
                                NEXT FIELD a12_codigo_bien
                        END IF
			DISPLAY BY NAME r_a10.a10_descripcion
                ELSE
                        CLEAR a10_descripcion
                END IF
	END CONSTRUCT
	IF int_flag THEN
		IF vm_num_rows > 0 THEN
			CALL mostrar_registro(vm_r_rows[vm_row_current])
		END IF
		RETURN
	END IF
ELSE
	LET expr_sql =  'a12_codigo_tran = "', arg_val(4), '"',
			'   AND a12_numero_tran = ', arg_val(5)
END IF
LET query = 'SELECT *, ROWID FROM actt012 ',
		' WHERE a12_compania    = ', vg_codcia,
		           expr_tran CLIPPED,
		'   AND ', expr_sql CLIPPED,
		' ORDER BY 2, 3, 4'
PREPARE cons FROM query
DECLARE q_act CURSOR FOR cons
LET vm_num_rows = 1
FOREACH q_act INTO rm_a12.*, vm_r_rows[vm_num_rows]
	LET vm_num_rows = vm_num_rows + 1
        IF vm_num_rows > vm_max_rows THEN
                EXIT FOREACH
        END IF
END FOREACH
LET vm_num_rows = vm_num_rows - 1
IF vm_num_rows = 0 THEN
        CLEAR FORM
	CALL fl_mensaje_consulta_sin_registros()
	IF num_args() = 5 THEN
		EXIT PROGRAM
	END IF
	LET vm_row_current = 0
	CALL muestra_contadores()
        RETURN
END IF
LET vm_row_current = 1
CALL muestra_contadores()
CALL mostrar_registro(vm_r_rows[vm_row_current])

END FUNCTION



FUNCTION control_ingreso()
DEFINE num_aux		INTEGER

CLEAR FORM
INITIALIZE rm_a10.*, rm_a12.* TO NULL
LET rm_a12.a12_compania    = vg_codcia
LET rm_a12.a12_codigo_tran = 'TR'
LET rm_a12.a12_usuario     = vg_usuario
LET rm_a12.a12_fecing      = CURRENT
LET rm_a10.a10_estado      = 'S'
CALL muestra_contadores()
CALL muestra_estado()
BEGIN WORK
CALL lee_datos()
IF NOT int_flag THEN
	CALL generar_transferencia() RETURNING num_aux
	IF vm_num_rows = vm_max_rows THEN
		LET vm_num_rows = 1
	ELSE
		LET vm_num_rows = vm_num_rows + 1
	END IF
	LET vm_r_rows[vm_num_rows] = num_aux
	LET vm_row_current = vm_num_rows
	CALL muestra_contadores()
	CALL mostrar_registro(vm_r_rows[vm_row_current])
	--CALL fl_mensaje_registro_ingresado()
	CALL fl_mostrar_mensaje('Se generó transferencia  Ok.', 'info')
ELSE
	ROLLBACK WORK
	CLEAR FORM
	IF vm_num_rows > 0 THEN
		CALL mostrar_registro(vm_r_rows[vm_row_current])
	END IF
END IF

END FUNCTION
--}



FUNCTION generar_transferencia()
DEFINE r_a10		RECORD LIKE actt010.*
DEFINE num_aux		INTEGER

CALL fl_lee_codigo_bien(vg_codcia, rm_a12.a12_codigo_bien)
	RETURNING r_a10.*
LET rm_a12.a12_numero_tran = fl_retorna_num_tran_activo(vg_codcia, 
					  rm_a12.a12_codigo_tran)
IF rm_a12.a12_numero_tran <= 0 THEN
	ROLLBACK WORK
	EXIT PROGRAM
END IF
LET rm_a12.a12_porc_deprec = r_a10.a10_porc_deprec
--LET rm_a12.a12_valor_mb	   = r_a10.a10_valor_mb
LET rm_a12.a12_valor_mb	   = 0
LET rm_a12.a12_valor_ma    = 0
LET rm_a12.a12_tipcomp_gen = NULL
LET rm_a12.a12_numcomp_gen = NULL
LET rm_a12.a12_fecing      = CURRENT
INSERT INTO actt012 VALUES (rm_a12.*) 
LET num_aux = SQLCA.SQLERRD[6] 
UPDATE actt010 SET a10_responsable = rm_a10.a10_responsable,
		   a10_localidad   = rm_a12.a12_locali_dest,
		   a10_cod_depto   = rm_a12.a12_depto_dest,
		   a10_estado      = rm_a10.a10_estado
	WHERE CURRENT OF q_up
COMMIT WORK
RETURN num_aux

END FUNCTION



FUNCTION bloquear_elbien()
DEFINE r_a10		RECORD LIKE actt010.*

INITIALIZE r_a10.* TO NULL
WHENEVER ERROR CONTINUE
DECLARE q_up CURSOR FOR 
	SELECT * FROM actt010
		WHERE a10_compania    = vg_codcia
		  AND a10_codigo_bien = rm_a12.a12_codigo_bien
	FOR UPDATE
OPEN q_up
FETCH q_up INTO r_a10.*
IF STATUS = NOTFOUND THEN
	CALL fl_mostrar_mensaje('Ha ocurrido un error interno de base de datos. Consulte con el Administrador.', 'stop')
	WHENEVER ERROR STOP
	RETURN 0
END IF
IF STATUS < 0 THEN
	CALL fl_mensaje_bloqueo_otro_usuario()
	WHENEVER ERROR STOP
	RETURN 0
END IF
WHENEVER ERROR STOP
RETURN 1

END FUNCTION



{--
FUNCTION lee_datos()
DEFINE resp      	CHAR(6)
DEFINE resul		SMALLINT
DEFINE unavez		SMALLINT
DEFINE r_a03		RECORD LIKE actt003.*
DEFINE r_a10		RECORD LIKE actt010.*
DEFINE r_g02_d		RECORD LIKE gent002.*
DEFINE r_g34_d		RECORD LIKE gent034.*
DEFINE codaux		LIKE actt010.a10_codigo_bien

DISPLAY BY NAME rm_a12.a12_codigo_tran, rm_a12.a12_usuario, rm_a12.a12_fecing
LET codaux   = NULL
LET unavez   = 1
LET int_flag = 0 
INPUT BY NAME rm_a12.a12_codigo_bien, rm_a10.a10_responsable,
	rm_a12.a12_depto_dest, rm_a12.a12_locali_dest, rm_a12.a12_referencia
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		IF FIELD_TOUCHED(rm_a12.a12_codigo_bien, rm_a10.a10_responsable,
				 rm_a12.a12_depto_dest, rm_a12.a12_locali_dest,
				 rm_a12.a12_referencia)
		THEN
			LET int_flag = 0
			CALL fl_mensaje_abandonar_proceso() RETURNING resp
			IF resp = 'Yes' THEN
				LET int_flag = 1
				RETURN
			END IF
		ELSE
			RETURN
		END IF       	
	ON KEY(F2)
		IF INFIELD(a12_codigo_bien) THEN
			CALL fl_ayuda_codigo_bien(vg_codcia, NULL, NULL, 'X', 1)
				RETURNING r_a10.a10_codigo_bien,
					  r_a10.a10_descripcion
			IF r_a10.a10_codigo_bien IS NOT NULL THEN
				LET rm_a12.a12_codigo_bien =
						r_a10.a10_codigo_bien
				DISPLAY r_a10.a10_codigo_bien TO a12_codigo_bien
				DISPLAY BY NAME r_a10.a10_descripcion	
				LET codaux = rm_a12.a12_codigo_bien
			END IF 
		END IF
		IF INFIELD(a12_depto_dest) THEN
			CALL fl_ayuda_departamentos(vg_codcia) 
				RETURNING r_g34_d.g34_cod_depto,
					  r_g34_d.g34_nombre
			IF r_g34_d.g34_cod_depto IS NOT NULL THEN
				LET rm_a12.a12_depto_dest =
							r_g34_d.g34_cod_depto
				DISPLAY r_g34_d.g34_cod_depto TO a12_depto_dest
				DISPLAY r_g34_d.g34_nombre    TO tit_depto_dest
			END IF 
		END IF
		IF INFIELD(a12_locali_dest) THEN
			CALL fl_ayuda_localidad(vg_codcia) 
				RETURNING r_g02_d.g02_localidad,
					  r_g02_d.g02_nombre
			IF r_g02_d.g02_localidad IS NOT NULL THEN
				LET rm_a12.a12_locali_dest =
							r_g02_d.g02_localidad
				DISPLAY r_g02_d.g02_localidad TO a12_locali_dest
				DISPLAY r_g02_d.g02_nombre    TO tit_locali_dest
			END IF 
		END IF 
		IF INFIELD(a10_responsable) THEN
			CALL fl_ayuda_responsable(vg_codcia) 
				RETURNING r_a03.a03_responsable,
					  r_a03.a03_nombres
			IF r_a03.a03_responsable IS NOT NULL THEN
				LET rm_a10.a10_responsable =
							r_a03.a03_responsable
				DISPLAY BY NAME rm_a10.a10_responsable,
						r_a03.a03_nombres
			END IF 
		END IF
		LET int_flag = 0
	BEFORE FIELD a12_codigo_bien
		IF codaux <> rm_a12.a12_codigo_bien THEN
			LET unavez = 1
			CLOSE q_up
			FREE q_up
		END IF
	AFTER FIELD a12_codigo_bien
		IF rm_a12.a12_codigo_bien IS NOT NULL THEN
			CALL fl_lee_codigo_bien(vg_codcia,
							rm_a12.a12_codigo_bien)
				RETURNING r_a10.*
			IF r_a10.a10_codigo_bien IS NULL THEN
				CALL fgl_winmessage(vg_producto,'No existe Activo Fijo.', 'exclamation')
                                NEXT FIELD a12_codigo_bien
                        END IF
			IF unavez THEN
				LET codaux = rm_a12.a12_codigo_bien
			END IF
			CALL cargar_otros(r_a10.*, 1)
			CALL muestra_estado()
			IF codaux = rm_a12.a12_codigo_bien AND unavez THEN
				LET unavez = 0
				CALL bloquear_elbien() RETURNING resul
				IF NOT resul THEN
					LET int_flag = 1
					EXIT INPUT
				END IF
			END IF
                ELSE
			LET rm_a10.a10_responsable = NULL
                        CLEAR a10_descripcion, a10_responsable, a12_depto_ori,
				a12_locali_ori, a10_moneda, a10_paridad,
				a10_valor_mb, a10_val_dep_mb, a10_tot_dep_mb,
				a03_nombres, tit_depto_ori, tit_locali_ori,
				tit_moneda
		END IF
	AFTER FIELD a12_locali_dest
		IF rm_a12.a12_locali_dest IS NOT NULL THEN
			CALL fl_lee_localidad(vg_codcia, rm_a12.a12_locali_dest)
				RETURNING r_g02_d.*
			IF r_g02_d.g02_localidad IS NULL THEN
				CALL fgl_winmessage(vg_producto, 'No existe localidad.', 'exclamation')
				NEXT FIELD a12_locali_dest
			END IF
			DISPLAY r_g02_d.g02_nombre TO tit_locali_dest
			IF r_g02_d.g02_estado = 'B' THEN
				CALL fl_mensaje_estado_bloqueado()
				NEXT FIELD a12_locali_dest
			END IF
		ELSE
			CLEAR tit_locali_dest
		END IF
	AFTER FIELD a12_depto_dest
		IF rm_a12.a12_depto_dest IS NOT NULL THEN
			CALL fl_lee_departamento(vg_codcia,
							rm_a12.a12_depto_dest)
				RETURNING r_g34_d.*
			IF r_g34_d.g34_cod_depto IS NULL THEN
				CALL fgl_winmessage(vg_producto, 'No existe departamento.', 'exclamation')
				NEXT FIELD a12_depto_dest
			END IF	
			DISPLAY r_g34_d.g34_nombre TO tit_depto_dest
		ELSE
			CLEAR tit_depto_dest
		END IF
	AFTER FIELD a10_responsable
		IF rm_a10.a10_responsable IS NOT NULL THEN
			CALL fl_lee_responsable(vg_codcia,
							rm_a10.a10_responsable)
				RETURNING r_a03.*
			IF r_a03.a03_responsable IS NULL THEN
				CALL fgl_winmessage(vg_producto, 'No existe responsable.', 'exclamation')
				NEXT FIELD a10_responsable
			END IF
			DISPLAY BY NAME r_a03.a03_nombres
			IF r_a03.a03_estado = 'B' THEN
				CALL fl_mensaje_estado_bloqueado()
				NEXT FIELD a10_responsable
			END IF
		ELSE
			CLEAR a03_nombres
		END IF
	AFTER INPUT
		CALL fl_lee_codigo_bien(vg_codcia, rm_a12.a12_codigo_bien)
			RETURNING r_a10.*
		IF rm_a12.a12_locali_dest = rm_a12.a12_locali_ori THEN
			IF r_a10.a10_estado <> 'D' AND r_a10.a10_estado <> 'S'
			THEN
				CALL fl_mostrar_mensaje('Solo se puede transferir un Bien si esta dado de Baja o tiene Stock.', 'stop')
				LET int_flag = 1
				EXIT INPUT
			END IF
		ELSE
			IF r_a10.a10_estado <> 'A' THEN
				CALL fl_mostrar_mensaje('Si la localidad origen es diferente del destino, sólo se puede transferir el Bien, si esta Activo.', 'stop')
				LET int_flag = 1
				EXIT INPUT
			END IF
			LET rm_a10.a10_estado = 'S'
		END IF
END INPUT

END FUNCTION
--}



FUNCTION setea_botones()

DISPLAY "Codigo"	TO tit_col1
DISPLAY "Descripcion"	TO tit_col2
DISPLAY "Origen"	TO tit_col3
DISPLAY "Fecha"		TO tit_col4
DISPLAY "Referencia"	TO tit_col5
DISPLAY "Destino"	TO tit_col6

END FUNCTION



FUNCTION muestra_contadores_det(num_row, max_row)
DEFINE num_row, max_row	SMALLINT

DISPLAY BY NAME num_row, max_row

END FUNCTION



FUNCTION borrar_cabecera()

INITIALIZE rm_par.*, rm_a10.*, rm_a12.* TO NULL
CLEAR cod_grupo, desc_grupo, codigo_bien, desc_bien, fecha_ini, fecha_fin,
	num_row, max_row, estado, tit_estado, tipo

END FUNCTION



FUNCTION borrar_detalle()
DEFINE i		SMALLINT

FOR i = 1 TO vm_max_rows
	INITIALIZE rm_detalle[i].* TO NULL
END FOR
FOR i = 1 TO fgl_scr_size("rm_detalle")
	CLEAR rm_detalle[i].*
END FOR
CLEAR descripcion, referencia

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



FUNCTION ver_activo(activo)
DEFINE activo		LIKE actt010.a10_codigo_bien
DEFINE param		VARCHAR(60)

LET param = ' ', activo
CALL ejecuta_comando('ACTIVOS', vg_modulo, 'actp104', param)

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



FUNCTION ver_origen(cod_tran, num_tran)
DEFINE cod_tran		LIKE actt012.a12_codigo_tran
DEFINE num_tran		LIKE actt012.a12_numero_tran
DEFINE num_row		INTEGER

OPEN WINDOW w_actf200_2 AT 3, 2 WITH 22 ROWS, 80 COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE 0, BORDER,
			MESSAGE LINE LAST)
OPEN FORM f_actf200_2 FROM '../forms/actf200_2'
DISPLAY FORM f_actf200_2
DECLARE q_tran CURSOR FOR
	SELECT ROWID
		FROM actt012
		WHERE a12_compania    = vg_codcia
		  AND a12_codigo_tran = cod_tran
		  AND a12_numero_tran = num_tran
OPEN q_tran
FETCH q_tran INTO num_row
CLOSE q_tran
FREE q_tran
CALL mostrar_registro(num_row)
MENU 'OPCIONES'
	COMMAND KEY('S') 'Salir' 'Salir del programa. '
		EXIT MENU
END MENU
CLOSE WINDOW w_actf200_2
RETURN

END FUNCTION



FUNCTION mostrar_registro(num_row)
DEFINE num_row		INTEGER
DEFINE r_a10		RECORD LIKE actt010.*
DEFINE r_g34		RECORD LIKE gent034.*
DEFINE r_g02		RECORD LIKE gent002.*
DEFINE tit_est		LIKE actt006.a06_descripcion

SELECT * INTO rm_a12.* FROM actt012 WHERE ROWID = num_row
IF STATUS = NOTFOUND THEN
	ERROR 'No existe registro con rowid: ', num_row
	RETURN
END IF
DISPLAY BY NAME rm_a12.a12_codigo_tran, rm_a12.a12_numero_tran,
		rm_a12.a12_codigo_bien, rm_a12.a12_depto_dest,
		rm_a12.a12_locali_dest, rm_a12.a12_referencia,
		rm_a12.a12_usuario, rm_a12.a12_fecing
CALL fl_lee_codigo_bien(vg_codcia, rm_a12.a12_codigo_bien) RETURNING r_a10.*
CALL cargar_otros(r_a10.*, 0)
CALL fl_lee_departamento(vg_codcia, rm_a12.a12_depto_dest) RETURNING r_g34.*
CALL fl_lee_localidad(vg_codcia, rm_a12.a12_locali_dest) RETURNING r_g02.*
DISPLAY r_g34.g34_nombre TO tit_depto_dest
DISPLAY r_g02.g02_nombre TO tit_locali_dest
CALL muestra_estado(r_a10.a10_estado, 0) RETURNING tit_est
DISPLAY BY NAME r_a10.a10_estado
DISPLAY tit_est TO tit_estado

END FUNCTION



FUNCTION cargar_otros(r_a10, flag)
DEFINE r_a10		RECORD LIKE actt010.*
DEFINE flag		SMALLINT
DEFINE r_a03		RECORD LIKE actt003.*
DEFINE r_g34		RECORD LIKE gent034.*
DEFINE r_g02		RECORD LIKE gent002.*
DEFINE r_g13		RECORD LIKE gent013.*

DISPLAY BY NAME r_a10.a10_descripcion 
LET rm_a10.a10_estado      = r_a10.a10_estado
IF rm_a10.a10_responsable IS NULL THEN
	LET rm_a10.a10_responsable = r_a10.a10_responsable
END IF
IF flag THEN
	LET rm_a12.a12_depto_ori   = r_a10.a10_cod_depto
	LET rm_a12.a12_locali_ori  = r_a10.a10_localidad
END IF
LET rm_a10.a10_moneda      = r_a10.a10_moneda 
LET rm_a10.a10_paridad     = r_a10.a10_paridad 
LET rm_a10.a10_valor_mb    = r_a10.a10_valor_mb 
LET rm_a10.a10_val_dep_mb  = r_a10.a10_val_dep_mb 
LET rm_a10.a10_tot_dep_mb  = r_a10.a10_tot_dep_mb 
DISPLAY BY NAME rm_a10.a10_responsable, rm_a12.a12_depto_ori,
		rm_a12.a12_locali_ori, rm_a10.a10_moneda, rm_a10.a10_paridad,
		rm_a10.a10_valor_mb, rm_a10.a10_val_dep_mb,rm_a10.a10_tot_dep_mb
CALL fl_lee_responsable(vg_codcia, rm_a10.a10_responsable) RETURNING r_a03.*
CALL fl_lee_departamento(vg_codcia, rm_a12.a12_depto_ori) RETURNING r_g34.*
CALL fl_lee_localidad(vg_codcia, rm_a12.a12_locali_ori) RETURNING r_g02.*
CALL fl_lee_moneda(rm_a10.a10_moneda) RETURNING r_g13.*
DISPLAY BY NAME r_a03.a03_nombres
DISPLAY r_g34.g34_nombre TO tit_depto_ori
DISPLAY r_g02.g02_nombre TO tit_locali_ori
DISPLAY r_g13.g13_nombre TO tit_moneda

END FUNCTION
