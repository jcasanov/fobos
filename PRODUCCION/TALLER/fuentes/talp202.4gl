------------------------------------------------------------------------------
-- Titulo           : talp202.4gl - Ingreso de tareas a presupuestos 
-- Elaboracion      : 10-oct-2001
-- Autor            : NPC
-- Formato Ejecucion: fglrun talp202 base módulo compañía localidad
--                         [numpre estado]
-- Ultima Correccion: 22-may-2003 
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE rm_t20		RECORD LIKE talt020.*
DEFINE rm_t21		RECORD LIKE talt021.*
DEFINE rm_t23           RECORD LIKE talt023.*
DEFINE rm_t00           RECORD LIKE talt000.*
DEFINE rm_vend		RECORD LIKE rept001.*
DEFINE rm_g04		RECORD LIKE gent004.*
DEFINE rm_g05		RECORD LIKE gent005.*
DEFINE rm_detalle 	ARRAY [100] OF RECORD
				t21_codtarea	LIKE talt021.t21_codtarea,
				t21_descripcion	LIKE talt021.t21_descripcion,
				t21_porc_descto	LIKE talt021.t21_porc_descto,
				t21_valor	LIKE talt021.t21_valor
			END RECORD
DEFINE rm_val_desc 	ARRAY [100] OF LIKE talt021.t21_val_descto
DEFINE val_descto 	LIKE talt021.t21_val_descto
DEFINE vm_estado	LIKE talt020.t20_estado
DEFINE vm_num_rows	SMALLINT
DEFINE vm_row_current	SMALLINT
DEFINE vm_max_rows	SMALLINT
DEFINE vm_max_elm       SMALLINT
DEFINE vm_num_elm       SMALLINT
DEFINE vm_size_arr	INTEGER
DEFINE subtotal      	LIKE talt020.t20_total_mo
DEFINE total_neto      	LIKE talt020.t20_total_mo
DEFINE vm_r_rows	ARRAY [100] OF LIKE talt020.t20_numpre 



MAIN

DEFER QUIT 
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/talp202.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 AND num_args() <> 6 THEN   -- Validar # parámetros correcto
	CALL fl_mostrar_mensaje('Número de paráametros incorrecto.','stop')
	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_codloc  = arg_val(4)
LET vg_proceso = 'talp202'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
--#CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL control_master()

END MAIN



FUNCTION control_master()
DEFINE indice           SMALLINT
DEFINE lin_menu		SMALLINT
DEFINE row_ini  	SMALLINT
DEFINE num_rows 	SMALLINT
DEFINE num_cols 	SMALLINT

CALL fl_nivel_isolation()
IF num_args() = 4 THEN
	CALL fl_chequeo_mes_proceso_tal(vg_codcia) RETURNING int_flag
	IF int_flag THEN
		RETURN
	END IF
END IF
CALL fl_lee_usuario(vg_usuario) RETURNING rm_g05.*
CALL fl_lee_grupo_usuario(rm_g05.g05_grupo) RETURNING rm_g04.*
INITIALIZE rm_vend.* TO NULL
DECLARE qu_vd CURSOR FOR
	SELECT * FROM rept001
		WHERE r01_compania   = vg_codcia
		  AND r01_user_owner = vg_usuario
OPEN qu_vd
FETCH qu_vd INTO rm_vend.*
IF STATUS = NOTFOUND THEN
	IF rm_g05.g05_tipo = 'UF' THEN
		CALL fl_mostrar_mensaje('Usted no esta configurado en la tabla de vendedores/bodegueros.','stop')
		RETURN
	END IF
END IF
LET vm_max_rows	= 100
LET vm_max_elm  = 100
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
OPEN WINDOW w_talf202_1 AT row_ini, 2 WITH num_rows ROWS, num_cols COLUMNS
	ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE lin_menu,
			BORDER, MESSAGE LINE LAST - 1)
IF vg_gui = 1 THEN
	OPEN FORM f_talf202_1 FROM "../forms/talf202_1"
ELSE
	OPEN FORM f_talf202_1 FROM "../forms/talf202_1c"
END IF
DISPLAY FORM f_talf202_1
CALL mostrar_botones_detalle()
INITIALIZE rm_t20.*, rm_t21.*, rm_t23.*, rm_t00.* TO NULL
LET vm_num_rows    = 0
LET vm_row_current = 0
LET vm_num_elm     = 0
LET total_neto     = 0
LET vm_estado      = "A"
FOR indice = 1 TO vm_max_elm
	INITIALIZE rm_detalle[indice].* TO NULL
END FOR
LET rm_t23.t23_moneda    = rg_gen.g00_moneda_base
LET rm_t21.t21_compania  = vg_codcia
LET rm_t21.t21_localidad = vg_codloc
LET rm_t21.t21_usuario   = vg_usuario
LET rm_t21.t21_fecing    = CURRENT
--#LET vm_size_arr = fgl_scr_size('rm_detalle')
IF vg_gui = 0 THEN
	LET vm_size_arr = 7
END IF
CALL muestra_contadores(vm_row_current, vm_num_rows)
CALL muestra_contadores_det(0, 0)
MENU 'OPCIONES'
	BEFORE MENU
		HIDE OPTION 'Avanzar'
		HIDE OPTION 'Retroceder'
		HIDE OPTION 'Modificar'
		HIDE OPTION 'Detalle'
		IF num_args() = 6 THEN
			HIDE OPTION 'Consultar'
			IF arg_val(6) <> 'A' THEN
				CALL control_consulta()
        	        	CALL muestra_detalle_arr()
			ELSE
				WHILE TRUE
					CALL control_modificacion()
					IF int_flag THEN
						EXIT WHILE
					END IF
				END WHILE
			END IF
			CLOSE WINDOW w_talf202_1
			EXIT PROGRAM
		END IF
       	COMMAND KEY('M') 'Modificar' 'Ingresar/Modificar mano de obra. '
		CALL control_modificacion()
	COMMAND KEY('C') 'Consultar' 'Consultar un registro. '
		CALL control_consulta()
		IF vm_num_rows <= 1 THEN
			SHOW OPTION 'Modificar'
			HIDE OPTION 'Avanzar'
			HIDE OPTION 'Retroceder'
			IF vm_num_rows = 0 THEN
				HIDE OPTION 'Modificar'
			END IF
		ELSE
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Modificar'
		END IF
		IF vm_row_current <= 1 THEN
                        HIDE OPTION 'Retroceder'
                END IF
		IF vm_num_elm > vm_size_arr THEN
                        SHOW OPTION 'Detalle'
                ELSE
                        HIDE OPTION 'Detalle'
                END IF
	COMMAND KEY('A') 'Avanzar' 'Ver siguiente registro. '
		CALL muestra_siguiente_registro()
		IF vm_row_current = vm_num_rows THEN
			HIDE OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
			NEXT OPTION 'Retroceder'
		ELSE
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
		END IF
		IF vm_num_elm > vm_size_arr THEN
                        SHOW OPTION 'Detalle'
                ELSE
                        HIDE OPTION 'Detalle'
                END IF
	COMMAND KEY('R') 'Retroceder'  'Ver anterior registro. '
		CALL muestra_anterior_registro()
		IF vm_row_current = 1 THEN
			HIDE OPTION 'Retroceder'
			SHOW OPTION 'Avanzar'
			NEXT OPTION 'Avanzar'
		ELSE
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
		END IF
		IF vm_num_elm > vm_size_arr THEN
                        SHOW OPTION 'Detalle'
                ELSE
                        HIDE OPTION 'Detalle'
                END IF
	COMMAND KEY('D') 'Detalle' 'Muestra siguiente detalles del registro. '
                CALL muestra_detalle_arr()
	COMMAND KEY('S') 'Salir' 'Salir del programa. '
		EXIT MENU
END MENU
CLOSE WINDOW w_talf202_1
EXIT PROGRAM

END FUNCTION



FUNCTION control_modificacion()
DEFINE indice           SMALLINT

IF vm_num_rows = 0 AND num_args() = 4 THEN
	CALL fl_mensaje_consultar_primero()
	RETURN
END IF
IF num_args() = 6 THEN
	LET vm_num_rows               = 1
	LET vm_row_current            = 1
	LET vm_r_rows[vm_row_current] = arg_val(5)
END IF
CALL mostrar_registro(vm_r_rows[vm_row_current])
CALL fl_lee_presupuesto_taller(vg_codcia,vg_codloc,vm_r_rows[vm_row_current])
	RETURNING rm_t20.*
IF rm_t20.t20_estado = 'P' THEN
	CALL fl_mostrar_mensaje('Este presupuesto ya ha sido aprobado.','exclamation')
	RETURN
END IF
BEGIN WORK
WHENEVER ERROR CONTINUE
DECLARE q_uppre2 CURSOR FOR
	SELECT * FROM talt020
		WHERE t20_compania  = vg_codcia
		  AND t20_localidad = vg_codloc
		  AND t20_numpre    = vm_r_rows[vm_row_current]
	FOR UPDATE
OPEN q_uppre2
FETCH q_uppre2 INTO rm_t20.*
IF STATUS < 0 THEN
	ROLLBACK WORK
	CALL fl_mensaje_bloqueo_otro_usuario()
	WHENEVER ERROR STOP
	RETURN
END IF
DECLARE q_up CURSOR FOR
	SELECT * FROM talt021
		WHERE t21_compania  = vg_codcia
		  AND t21_localidad = vg_codloc
		  AND t21_numpre    = vm_r_rows[vm_row_current]
	FOR UPDATE
OPEN q_up
FETCH q_up INTO rm_t21.*
IF STATUS < 0 THEN
	ROLLBACK WORK
	CALL fl_mensaje_bloqueo_otro_usuario()
	WHENEVER ERROR STOP
	RETURN
END IF
WHENEVER ERROR STOP
LET total_neto = 0
CALL leer_detalle()
IF int_flag THEN
	ROLLBACK WORK
	CALL mostrar_registro(vm_r_rows[vm_row_current])
	IF num_args() = 6 THEN
		LET int_flag = 1
	END IF
	RETURN
END IF
DELETE FROM talt021
	WHERE t21_compania  = rm_t21.t21_compania
	  AND t21_localidad = rm_t21.t21_localidad
	  AND t21_numpre    = rm_t21.t21_numpre
FOR indice = 1 TO vm_num_elm
	LET rm_t21.t21_secuencia = indice
	LET rm_t21.t21_fecing    = CURRENT
	INSERT INTO talt021
		VALUES (rm_t21.t21_compania, rm_t21.t21_localidad,
			rm_t21.t21_numpre, rm_detalle[indice].t21_codtarea,
			rm_t21.t21_secuencia,rm_detalle[indice].t21_descripcion,
			rm_detalle[indice].t21_porc_descto,
			rm_val_desc[indice], rm_detalle[indice].t21_valor,
			rm_t21.t21_usuario, rm_t21.t21_fecing)
END FOR
CALL calcular_descuento_mo()
CALL calcular_impto()
CALL calcular_total()
UPDATE talt020
	SET t20_total_mo    = rm_t20.t20_total_mo,
	    t20_por_mo_tal  = rm_t20.t20_por_mo_tal,
	    t20_vde_mo_tal  = rm_t20.t20_vde_mo_tal,
	    t20_total_impto = rm_t20.t20_total_impto,
	    t20_total_neto  = rm_t20.t20_total_neto
	WHERE CURRENT OF q_uppre2
COMMIT WORK
CALL mostrar_registro(vm_r_rows[vm_row_current])
CALL fl_mensaje_registro_modificado()
 
END FUNCTION



FUNCTION control_consulta()
DEFINE numpre		LIKE talt020.t20_numpre
DEFINE codcli		LIKE talt023.t23_cod_cliente
DEFINE nomcli		LIKE talt023.t23_nom_cliente
DEFINE query		CHAR(900)
DEFINE expr_sql		CHAR(200)

IF num_args() = 4 THEN
	CLEAR FORM
	CALL mostrar_botones_detalle()
	LET int_flag = 0
	CONSTRUCT BY NAME expr_sql ON t20_numpre
		ON KEY(F1,CONTROL-W)
			CALL llamar_visor_teclas()
		ON KEY(F2)
			IF INFIELD(t20_numpre) THEN
				CALL fl_ayuda_presupuestos_taller(vg_codcia,
							vg_codloc, vm_estado)
					RETURNING numpre, codcli, nomcli
				IF numpre IS NOT NULL THEN
					CALL fl_lee_presupuesto_taller(
							vg_codcia, vg_codloc,
							numpre)
						RETURNING rm_t20.*
					DISPLAY numpre TO t20_numpre
					CALL muestra_cabecera()
				END IF
			END IF
			LET int_flag = 0
		BEFORE CONSTRUCT
			--#CALL dialog.keysetlabel("F1","")
			--#CALL dialog.keysetlabel("CONTROL-W","")
	END CONSTRUCT
	IF int_flag THEN
		IF vm_row_current > 0 THEN
			CALL mostrar_registro(vm_r_rows[vm_row_current])
		ELSE
			CLEAR FORM
			CALL mostrar_botones_detalle()
		END IF
		RETURN
	END IF
ELSE
	LET expr_sql  = ' t20_numpre = ', arg_val(5)
	LET vm_estado = arg_val(6)
END IF
LET query = 'SELECT t20_numpre ',
		'FROM talt020 ',
		'WHERE t20_compania  = ', vg_codcia,
		'  AND t20_localidad = ', vg_codloc,
		'  AND ', expr_sql CLIPPED,
		--'  AND t20_estado    = "', vm_estado, '"',
		' ORDER BY 1'
PREPARE cons FROM query	
DECLARE q_cons CURSOR FOR cons
LET vm_num_rows = 1
FOREACH q_cons INTO vm_r_rows[vm_num_rows]
	LET vm_num_rows = vm_num_rows + 1
        IF vm_num_rows > vm_max_rows THEN
                EXIT FOREACH
        END IF
END FOREACH
LET vm_num_rows = vm_num_rows - 1
IF vm_num_rows = 0 THEN
	LET int_flag = 0
	CALL fl_mensaje_consulta_sin_registros()
	IF num_args() = 6 THEN
		CLOSE WINDOW w_talf202_1
		EXIT PROGRAM
	END IF
	CLEAR FORM
	CALL mostrar_botones_detalle()
	LET vm_row_current = 0
ELSE
	LET vm_row_current = 1
	CALL mostrar_registro(vm_r_rows[vm_row_current])
END IF
CALL muestra_contadores(vm_row_current, vm_num_rows)

END FUNCTION



FUNCTION muestra_cabecera()

DISPLAY rm_t20.t20_nom_cliente TO tit_cliente

END FUNCTION



FUNCTION leer_detalle()
DEFINE r_t07		RECORD LIKE talt007.*
DEFINE codt_aux		LIKE talt007.t07_codtarea
DEFINE nomt_aux		LIKE talt007.t07_nombre
DEFINE descri_ori	LIKE talt021.t21_descripcion
DEFINE max_descto	DECIMAL(4,2)
DEFINE max_descto_c	DECIMAL(4,2)
DEFINE resul, i, j	SMALLINT
DEFINE max_row		SMALLINT
DEFINE resp             CHAR(6)
DEFINE mensaje		VARCHAR(250)

INITIALIZE codt_aux, descri_ori TO NULL
LET int_flag = 0
CALL set_count(vm_num_elm)
INPUT ARRAY rm_detalle WITHOUT DEFAULTS FROM rm_detalle.*
	ON KEY(INTERRUPT)
		LET int_flag = 0
		CALL fl_mensaje_abandonar_proceso() RETURNING resp
		IF resp = 'Yes' THEN
			LET int_flag   = 1
			LET total_neto = 0
			EXIT INPUT
		END IF
	ON KEY(F1,CONTROL-W)
		CALL llamar_visor_teclas()
	ON KEY(F2)
		IF INFIELD(t21_codtarea) THEN
			CALL fl_ayuda_tempario(vg_codcia, 'A')
				RETURNING codt_aux, nomt_aux
			IF codt_aux IS NOT NULL THEN
				LET rm_t21.t21_numpre = rm_t20.t20_numpre
				LET rm_detalle[i].t21_codtarea = codt_aux
				DISPLAY codt_aux TO rm_detalle[j].t21_codtarea
				CALL muestra_descripcion(nomt_aux, i, j)
			END IF
		END IF
		LET int_flag = 0
	BEFORE INPUT
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
		--#IF num_args() <> 4 THEN
			--#CALL dialog.keysetlabel("INTERRUPT","Regresar")
		--#END IF
	BEFORE ROW
		LET i = arr_curr()
		LET j = scr_line()
		LET max_row = arr_count()
		IF i > max_row THEN
			LET max_row = max_row + 1
		END IF
		CALL muestra_contadores_det(i, max_row)
		DISPLAY rm_detalle[i].t21_descripcion TO tit_descri
		CALL mostrar_total(arr_count())
	BEFORE FIELD t21_descripcion
		LET descri_ori = NULL
		CALL fl_lee_tarea(vg_codcia, rm_detalle[i].t21_codtarea)
			RETURNING r_t07.*
		IF rm_detalle[i].t21_codtarea <> rm_t00.t00_seudo_tarea AND
		   r_t07.t07_modif_desc = 'N'
		THEN
			LET descri_ori = rm_detalle[i].t21_descripcion
		END IF
		DISPLAY rm_detalle[i].t21_descripcion TO tit_descri
	AFTER FIELD t21_codtarea
		IF rm_detalle[i].t21_codtarea IS NOT NULL THEN
			LET rm_t21.t21_numpre = rm_t20.t20_numpre
			CALL validar_tarea(i,j) RETURNING resul
			IF resul = 1 THEN
				NEXT FIELD t21_codtarea
			END IF
			IF rm_detalle[i].t21_porc_descto IS NULL THEN
				CALL retorna_descto_maximo_tarea(vg_codcia,
						rm_detalle[i].t21_codtarea)
					RETURNING max_descto, max_descto_c
				LET rm_detalle[i].t21_porc_descto = max_descto
				IF rm_g04.g04_grupo <> 'GE' THEN
					LET rm_detalle[i].t21_porc_descto =
								max_descto
				END IF
				DISPLAY rm_detalle[i].* TO rm_detalle[j].*
			END IF
			CALL mostrar_total(arr_count())
		ELSE
			IF rm_detalle[i].t21_descripcion IS NOT NULL THEN
				NEXT FIELD t21_codtarea
			END IF
		END IF
	AFTER FIELD t21_descripcion
		CALL fl_lee_tarea(vg_codcia, rm_detalle[i].t21_codtarea)
			RETURNING r_t07.*
		IF rm_detalle[i].t21_codtarea <> rm_t00.t00_seudo_tarea AND
		   r_t07.t07_modif_desc = 'N'
		THEN
			IF descri_ori IS NOT NULL THEN
				LET rm_detalle[i].t21_descripcion = descri_ori
				CALL muestra_descripcion(rm_detalle[i].t21_descripcion,
						i, j)
			END IF
		ELSE
			IF rm_detalle[i].t21_valor IS NULL AND resul = 2 THEN
				IF rm_detalle[i].t21_porc_descto = 0 THEN
					NEXT FIELD t21_valor
				END IF
			END IF
		END IF
	AFTER FIELD t21_porc_descto
		IF rm_detalle[i].t21_porc_descto IS NULL AND
		   rm_detalle[i].t21_codtarea IS NOT NULL
		THEN
			LET rm_detalle[i].t21_porc_descto = 0
			DISPLAY rm_detalle[i].* TO rm_detalle[j].*
		END IF
		IF rm_detalle[i].t21_porc_descto IS NOT NULL THEN
			CALL retorna_descto_maximo_tarea(vg_codcia,
						rm_detalle[i].t21_codtarea)
				RETURNING max_descto, max_descto_c
			IF rm_detalle[i].t21_porc_descto > max_descto THEN
				LET mensaje = 'La Tarea: ',
					rm_detalle[i].t21_codtarea CLIPPED,
					' tiene un descuento maximo de: ',
					max_descto USING '#&.##'
				CALL fl_mostrar_mensaje(mensaje, 'exclamation')
				IF rm_g04.g04_grupo <> 'GE' THEN
					LET rm_detalle[i].t21_porc_descto =
								max_descto
					DISPLAY rm_detalle[i].* TO
						rm_detalle[j].*
				END IF
			END IF
		END IF
		IF rm_detalle[i].t21_codtarea IS NOT NULL AND
		   rm_detalle[i].t21_valor IS NOT NULL
		THEN
			CALL mostrar_total(arr_count())
		END IF
	AFTER FIELD t21_valor
		IF rm_detalle[i].t21_codtarea <> rm_t00.t00_seudo_tarea AND
		   r_t07.t07_modif_desc = 'N'
		THEN
			IF descri_ori IS NOT NULL THEN
				LET rm_detalle[i].t21_descripcion = descri_ori
				CALL muestra_descripcion(rm_detalle[i].t21_descripcion,
						i, j)
			END IF
		END IF
		IF rm_detalle[i].t21_valor IS NOT NULL THEN
			CALL validar_tarea(i,j) RETURNING resul
			IF resul = 1 THEN
				NEXT FIELD t21_codtarea
			END IF
			CALL fl_retorna_precision_valor(rm_t23.t23_moneda,
							rm_detalle[i].t21_valor)
				RETURNING rm_detalle[i].t21_valor
			DISPLAY rm_detalle[i].t21_valor TO
				rm_detalle[j].t21_valor
			CALL mostrar_total(arr_count())
		ELSE
			IF rm_detalle[i].t21_descripcion IS NOT NULL THEN
				NEXT FIELD t21_valor
			END IF
		END IF
	AFTER DELETE
		LET i = arr_curr()
		CALL mostrar_total(arr_count())
		CALL muestra_contadores_det(i, arr_curr())
	AFTER INPUT
		CALL mostrar_total(arr_count())
END INPUT
IF NOT int_flag THEN
	LET vm_num_elm = arr_count()
END IF

END FUNCTION



FUNCTION mostrar_total(num_elm)
DEFINE num_elm		SMALLINT
DEFINE i		SMALLINT

LET subtotal   = 0
LET val_descto = 0
LET total_neto = 0
FOR i = 1 TO num_elm
	IF rm_detalle[i].t21_valor IS NULL THEN
		CONTINUE FOR
	END IF
	LET rm_val_desc[i] = (rm_detalle[i].t21_valor *
				rm_detalle[i].t21_porc_descto / 100)
	LET val_descto     = val_descto + rm_val_desc[i]
	LET subtotal       = subtotal + rm_detalle[i].t21_valor
	LET total_neto     = total_neto +
				(rm_detalle[i].t21_valor - rm_val_desc[i])
END FOR
LET rm_t20.t20_total_mo = subtotal + (subtotal * rm_t20.t20_recargo_mo / 100)
DISPLAY BY NAME subtotal, val_descto, total_neto
                                                                                
END FUNCTION



FUNCTION validar_tarea(i, j)
DEFINE i, j		SMALLINT
DEFINE mensaje		VARCHAR(40)
DEFINE valor		DECIMAL(11,2)	
DEFINE puntos		SMALLINT
DEFINE r_tar		RECORD LIKE talt007.*

INITIALIZE r_tar.* TO NULL
LET mensaje = 'ESCRIBA LA DESCRIPCION'
LET valor = 0
CALL fl_lee_configuracion_taller(vg_codcia) RETURNING rm_t00.*
IF rm_t00.t00_estado = 'B' THEN
	CALL fl_mensaje_estado_bloqueado()
	RETURN 1
END IF
IF rm_t00.t00_seudo_tarea <> rm_detalle[i].t21_codtarea THEN
	CALL fl_lee_tarea(vg_codcia, rm_detalle[i].t21_codtarea)
		RETURNING r_tar.*
	IF r_tar.t07_compania IS NULL THEN
		CALL fl_mostrar_mensaje('No existe esa tarea.','exclamation')
		RETURN 1
	END IF
	IF rm_detalle[i].t21_descripcion IS NULL THEN
		CALL muestra_descripcion(r_tar.t07_nombre,i,j)
	END IF
	IF r_tar.t07_modif_desc = 'N' THEN
		CALL muestra_descripcion(r_tar.t07_nombre,i,j)
	END IF
	IF r_tar.t07_estado = 'B' THEN
		CALL fl_mensaje_estado_bloqueado()
		RETURN 1
	END IF
	LET puntos = r_tar.t07_pto_default
	IF r_tar.t07_tipo = 'V' THEN
		IF rm_t23.t23_moneda = rg_gen.g00_moneda_base THEN
			LET valor = r_tar.t07_val_defa_mb
		ELSE
			LET valor = r_tar.t07_val_defa_ma
		END IF
	END IF
	IF r_tar.t07_tipo = 'P' THEN
		IF rm_t23.t23_moneda = rg_gen.g00_moneda_base THEN
			LET valor = rm_t00.t00_factor_mb
		ELSE
			LET valor = rm_t00.t00_factor_ma
		END IF
	END IF
ELSE
	IF rm_detalle[i].t21_descripcion IS NULL THEN
		CALL muestra_descripcion(mensaje,i,j)
	END IF
	RETURN 2
END IF
RETURN 0

END FUNCTION



FUNCTION muestra_siguiente_registro()

IF vm_row_current < vm_num_rows THEN
	LET vm_row_current = vm_row_current + 1
END IF
CALL mostrar_registro(vm_r_rows[vm_row_current])
CALL muestra_contadores(vm_row_current, vm_num_rows)

END FUNCTION



FUNCTION muestra_anterior_registro()

IF vm_row_current > 1 THEN
	LET vm_row_current = vm_row_current - 1
END IF
CALL mostrar_registro(vm_r_rows[vm_row_current])
CALL muestra_contadores(vm_row_current, vm_num_rows)

END FUNCTION



FUNCTION muestra_contadores(row_current, num_rows)
DEFINE row_current	SMALLINT
DEFINE num_rows		SMALLINT
                                                                                
IF vg_gui = 1 THEN
	DISPLAY "" AT 1, 1
	DISPLAY row_current, " de ", num_rows AT 1, 67
END IF
                                                                                
END FUNCTION



FUNCTION mostrar_registro(num_registro)
DEFINE num_registro	LIKE talt020.t20_numpre

IF vm_num_rows <= 0 THEN
	RETURN
END IF
DECLARE q_dt CURSOR FOR
	SELECT * FROM talt020
		WHERE t20_compania  = vg_codcia
		  AND t20_localidad = vg_codloc
		  AND t20_numpre    = num_registro
OPEN q_dt
FETCH q_dt INTO rm_t20.*
IF STATUS = NOTFOUND THEN
	CALL fl_mostrar_mensaje('No existe registro con índice: ' || vm_row_current,'exclamation')
	RETURN
END IF
DECLARE q_dt2 CURSOR FOR
	SELECT * FROM talt021
		WHERE t21_compania  = vg_codcia
		  AND t21_localidad = vg_codloc
		  AND t21_numpre    = rm_t20.t20_numpre
OPEN q_dt2
FETCH q_dt2 INTO rm_t21.*
IF STATUS = NOTFOUND THEN
	DISPLAY rm_t20.t20_usuario TO t21_usuario
	DISPLAY rm_t20.t20_fecing TO t21_fecing
ELSE
	DISPLAY BY NAME rm_t21.t21_usuario, rm_t21.t21_fecing
END IF
CLOSE q_dt
CLOSE q_dt2
DISPLAY BY NAME rm_t20.t20_numpre
LET rm_t23.t23_moneda = rm_t20.t20_moneda
CALL muestra_cabecera()
CALL muestra_detalle(num_registro)

END FUNCTION



FUNCTION muestra_detalle(num_reg)
DEFINE num_reg          LIKE talt020.t20_numpre
DEFINE query            CHAR(400)
DEFINE i                SMALLINT
DEFINE sec		LIKE talt021.t21_secuencia
                                                                                
LET int_flag = 0
FOR i = 1 TO vm_size_arr
        INITIALIZE rm_detalle[i].* TO NULL
        CLEAR rm_detalle[i].*
END FOR
LET i = 1
LET query = 'SELECT t21_codtarea, t21_descripcion, t21_porc_descto, ',
			't21_valor, t21_val_descto, t21_secuencia ',
		' FROM talt021 ',
                ' WHERE t21_compania  = ', vg_codcia,
		'   AND t21_localidad = ', vg_codloc,
		'   AND t21_numpre    = ', num_reg,
		' ORDER BY t21_secuencia'
PREPARE cons1 FROM query
DECLARE q_cons1 CURSOR FOR cons1
LET vm_num_elm = 1
FOREACH q_cons1 INTO rm_detalle[vm_num_elm].*, rm_val_desc[vm_num_elm], sec
	LET vm_num_elm = vm_num_elm + 1
	IF vm_num_elm > vm_max_elm THEN
		CALL fl_mensaje_arreglo_incompleto()
		EXIT PROGRAM
		--EXIT FOREACH
	END IF
END FOREACH
LET vm_num_elm = vm_num_elm - 1
IF vm_num_elm > 0 THEN
	LET int_flag = 0
	FOR i = 1 TO vm_size_arr
		DISPLAY rm_detalle[i].* TO rm_detalle[i].*
		DISPLAY rm_detalle[i].t21_descripcion TO tit_descri
	END FOR
END IF
IF int_flag THEN
	INITIALIZE rm_detalle[1].* TO NULL
	RETURN
END IF
CALL muestra_contadores_det(0, vm_num_elm)
CALL mostrar_total(vm_num_elm)

END FUNCTION
                                                                                
                                                                                
                                                                                
FUNCTION muestra_detalle_arr()
DEFINE i		SMALLINT

LET int_flag = 0
CALL set_count(vm_num_elm)
DISPLAY ARRAY rm_detalle TO rm_detalle.*
	ON KEY(INTERRUPT)
		LET int_flag = 1
		EXIT DISPLAY
        ON KEY(F1,CONTROL-W)
		CALL llamar_visor_teclas()
	--#BEFORE ROW
		--#LET i = arr_curr()
		--#DISPLAY rm_detalle[i].t21_descripcion TO tit_descri
		--#CALL muestra_contadores_det(i, vm_num_elm)
	--#BEFORE DISPLAY
		--#CALL dialog.keysetlabel("ACCEPT","")
		--#CALL dialog.keysetlabel("F1","")
		--#IF num_args() <> 4 THEN
			--#CALL dialog.keysetlabel("INTERRUPT","Regresar")
		--#END IF
		--#CALL dialog.keysetlabel("CONTROL-W","")
	--#AFTER DISPLAY
		--#CONTINUE DISPLAY
END DISPLAY
                                                                                
END FUNCTION



FUNCTION muestra_descripcion(descr,i,j)
DEFINE i, j		SMALLINT
DEFINE descr		LIKE talt021.t21_descripcion

LET rm_detalle[i].t21_descripcion = descr 
DISPLAY rm_detalle[i].t21_descripcion TO rm_detalle[j].t21_descripcion
DISPLAY rm_detalle[i].t21_descripcion TO tit_descri

END FUNCTION



FUNCTION retorna_descto_maximo_tarea(codcia, tarea)
DEFINE codcia		LIKE talt007.t07_compania
DEFINE tarea		LIKE talt007.t07_codtarea
DEFINE r_t07		RECORD LIKE talt007.*

CALL fl_lee_tarea(codcia, tarea) RETURNING r_t07.*
IF r_t07.t07_compania IS NULL THEN
	RETURN 0, 0
END IF
IF rm_vend.r01_compania IS NULL AND rm_g05.g05_tipo = 'AG' THEN
	RETURN r_t07.t07_dscmax_ger, r_t07.t07_dscmax_ven
END IF
IF rm_vend.r01_compania IS NULL AND rm_g05.g05_tipo = 'AM' THEN
	RETURN r_t07.t07_dscmax_jef, r_t07.t07_dscmax_ven
END IF
IF rm_vend.r01_tipo = 'J' THEN
	RETURN r_t07.t07_dscmax_jef, r_t07.t07_dscmax_ven
END IF
IF rm_vend.r01_tipo = 'G' THEN
	RETURN r_t07.t07_dscmax_ger, r_t07.t07_dscmax_ven
END IF
RETURN r_t07.t07_dscmax_ven, r_t07.t07_dscmax_ven

END FUNCTION



FUNCTION calcular_descuento_mo()

LET rm_t20.t20_por_mo_tal = 0
LET rm_t20.t20_vde_mo_tal = val_descto
CALL fl_retorna_precision_valor(rm_t20.t20_moneda, rm_t20.t20_vde_mo_tal)
	RETURNING rm_t20.t20_vde_mo_tal

END FUNCTION



FUNCTION calcular_impto()
DEFINE r_g00		RECORD LIKE gent000.*
DEFINE r_z01		RECORD LIKE cxct001.*

CALL fl_lee_configuracion_facturacion() RETURNING r_g00.*
IF rm_t20.t20_cod_cliente IS NOT NULL THEN
	CALL fl_lee_cliente_general(rm_t20.t20_cod_cliente) RETURNING r_z01.*
	IF r_z01.z01_paga_impto = 'N' THEN
		LET r_g00.g00_porc_impto = 0
	END IF
END IF
LET rm_t20.t20_total_impto = (rm_t20.t20_total_mo + rm_t20.t20_total_rp +
			     rm_t20.t20_mano_ext) * (r_g00.g00_porc_impto / 100)

END FUNCTION



FUNCTION calcular_total()

LET rm_t20.t20_total_neto = rm_t20.t20_total_mo + rm_t20.t20_total_rp +
			    rm_t20.t20_mano_ext + rm_t20.t20_total_impto +
			    rm_t20.t20_otros_mat + rm_t20.t20_gastos -
			    rm_t20.t20_vde_mo_tal

END FUNCTION



FUNCTION muestra_contadores_det(num_row, max_row)
DEFINE num_row, max_row	SMALLINT

DISPLAY BY NAME num_row, max_row

END FUNCTION



FUNCTION mostrar_botones_detalle()

--#DISPLAY 'Tarea'       TO tit_col1
--#DISPLAY 'Descripción' TO tit_col2
--#DISPLAY 'Desc.'       TO tit_col3
--#DISPLAY 'Valor'       TO tit_col4

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
