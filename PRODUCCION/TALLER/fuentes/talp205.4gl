--------------------------------------------------------------------------------
-- Titulo           : talp205.4gl - Ingreso de tareas a ordenes de trabajo 
-- Elaboracion      : 16-oct-2001
-- Autor            : NPC
-- Formato Ejecucion: fglrun talp205 base módulo compañía localidad
--------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE rm_t24		RECORD LIKE talt024.*
DEFINE rm_t23		RECORD LIKE talt023.*
DEFINE rm_t04		RECORD LIKE talt004.*
DEFINE rm_t00		RECORD LIKE talt000.*
DEFINE rm_vend		RECORD LIKE rept001.*
DEFINE rm_g04		RECORD LIKE gent004.*
DEFINE rm_g05		RECORD LIKE gent005.*
DEFINE rm_detalle 	ARRAY [100] OF RECORD
				t24_codtarea	LIKE talt024.t24_codtarea,
				t24_mecanico	LIKE talt024.t24_mecanico,
				tit_mecanico	LIKE talt003.t03_nombres,
				t24_porc_descto	LIKE talt024.t24_porc_descto,
				t24_descripcion	LIKE talt024.t24_descripcion,
                        	t24_puntos_opti	LIKE talt024.t24_puntos_opti,
				t24_puntos_real	LIKE talt024.t24_puntos_real,
				t24_valor_tarea	LIKE talt024.t24_valor_tarea
			END RECORD
DEFINE vm_r_rows	ARRAY [100] OF LIKE talt023.t23_orden 
DEFINE rm_val_desc 	ARRAY [100] OF LIKE talt024.t24_val_descto
DEFINE val_descto 	LIKE talt024.t24_val_descto
DEFINE subtotal      	LIKE talt023.t23_val_mo_tal
DEFINE total_neto      	LIKE talt023.t23_val_mo_tal
DEFINE vm_factor	LIKE talt024.t24_factor
DEFINE vm_num_rows	SMALLINT
DEFINE vm_row_current	SMALLINT
DEFINE vm_max_rows	SMALLINT
DEFINE vm_max_elm       SMALLINT
DEFINE vm_num_elm       SMALLINT
DEFINE vm_size_arr	INTEGER
DEFINE vm_flag_moneda   SMALLINT



MAIN

DEFER QUIT 
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/talp205.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 THEN          -- Validar # parámetros correcto
	--CALL fgl_winmessage(vg_producto,'Número de parámetros incorrecto', 'stop')
	CALL fl_mostrar_mensaje('Número de parámetros incorrecto.','stop')
	EXIT PROGRAM
END IF
LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_codcia   = arg_val(3)
LET vg_codloc   = arg_val(4)
LET vg_proceso = 'talp205'
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
OPEN WINDOW w_talf205_1 AT row_ini, 2 WITH num_rows ROWS, num_cols COLUMNS
    ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE lin_menu,BORDER,
	      MESSAGE LINE LAST - 1)
IF vg_gui = 1 THEN
	OPEN FORM f_talf205_1 FROM "../forms/talf205_1"
ELSE
	OPEN FORM f_talf205_1 FROM "../forms/talf205_1c"
END IF
DISPLAY FORM f_talf205_1
CALL mostrar_botones_detalle()
INITIALIZE rm_t24.*, rm_t23.*, rm_t04.*, rm_t00.* TO NULL
LET vm_num_rows    = 0
LET vm_row_current = 0
LET vm_num_elm     = 0
LET total_neto     = 0
FOR indice = 1 TO vm_max_elm
        INITIALIZE rm_detalle[indice].* TO NULL
END FOR
LET rm_t24.t24_compania  = vg_codcia
LET rm_t24.t24_localidad = vg_codloc
LET rm_t24.t24_paga_clte = 'S'
LET rm_t24.t24_usuario   = vg_usuario
LET rm_t24.t24_fecing    = CURRENT
--#LET vm_size_arr = fgl_scr_size('rm_detalle')
IF vg_gui = 0 THEN
	LET vm_size_arr = 5
END IF
CALL muestra_contadores(vm_row_current, vm_num_rows)
CALL muestra_contadores_det(0, 0)
MENU 'OPCIONES'
	BEFORE MENU
		HIDE OPTION 'Avanzar'
		HIDE OPTION 'Retroceder'
		HIDE OPTION 'Modificar'
		HIDE OPTION 'Detalle'
       	COMMAND KEY('M') 'Modificar' 'Ingresar/Modificar mano de obra a ordenes de trabajo. '
		CALL control_modificacion()
	COMMAND KEY('C') 'Consultar' 'Consultar un registro. '
		CALL control_consulta()
		IF vm_num_rows <= 1 THEN
			SHOW OPTION 'Modificar'
                        SHOW OPTION 'Detalle'
			HIDE OPTION 'Avanzar'
			HIDE OPTION 'Retroceder'
			IF vm_num_rows = 0 THEN
				HIDE OPTION 'Modificar'
                        	HIDE OPTION 'Detalle'
			END IF
		ELSE
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Modificar'
                        SHOW OPTION 'Detalle'
		END IF
		IF vm_row_current <= 1 THEN
                        HIDE OPTION 'Retroceder'
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
	COMMAND KEY('D') 'Detalle' 'Muestra siguiente detalles del registro. '
                CALL muestra_detalle_arr()
	COMMAND KEY('S') 'Salir' 'Salir del programa. '
		EXIT MENU
END MENU
CLOSE WINDOW w_talf205_1
EXIT PROGRAM

END FUNCTION



FUNCTION control_modificacion()
DEFINE indice		SMALLINT
DEFINE r_mec		RECORD LIKE talt003.*

IF vm_num_rows = 0 THEN
	CALL fl_mensaje_consultar_primero()
	RETURN
END IF
CALL mostrar_registro(vm_r_rows[vm_row_current])
CALL fl_lee_orden_trabajo(vg_codcia,vg_codloc,vm_r_rows[vm_row_current])
	RETURNING rm_t23.*
IF rm_t23.t23_estado <> 'A' THEN
	IF rm_t23.t23_estado = 'C' THEN
		CALL fl_mostrar_mensaje('Esta orden ya ha sido cerrada.','exclamation')
	ELSE
		CALL fl_mostrar_mensaje('Esta orden no esta activa.','exclamation')
      	END IF
	RETURN
END IF
CALL fl_lee_tipo_vehiculo(vg_codcia, rm_t23.t23_modelo) RETURNING rm_t04.*
BEGIN WORK
WHENEVER ERROR CONTINUE
DECLARE q_upord2 CURSOR FOR
	SELECT * FROM talt023
		WHERE t23_compania  = vg_codcia
		  AND t23_localidad = vg_codloc
		  AND t23_orden     = vm_r_rows[vm_row_current]
	FOR UPDATE
OPEN q_upord2
FETCH q_upord2 INTO rm_t23.*
IF STATUS < 0 THEN
	ROLLBACK WORK
	CALL fl_mensaje_bloqueo_otro_usuario()
	WHENEVER ERROR STOP
	RETURN
END IF
DECLARE q_up CURSOR FOR
	SELECT * FROM talt024
		WHERE t24_compania   = vg_codcia
		  AND t24_localidad  = vg_codloc
		  AND t24_orden      = vm_r_rows[vm_row_current]
	FOR UPDATE
OPEN q_up
FETCH q_up INTO rm_t24.*
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
	RETURN
END IF
DELETE FROM talt024
	WHERE t24_compania  = vg_codcia
	  AND t24_localidad = vg_codloc
	  AND t24_orden     = rm_t24.t24_orden
LET rm_t24.t24_factor = vm_factor
FOR indice = 1 TO vm_num_elm
	CALL fl_lee_mecanico(vg_codcia, rm_detalle[indice].t24_mecanico)
		RETURNING r_mec.*
	LET rm_t24.t24_secuencia = indice
	LET rm_t24.t24_orden     = rm_t23.t23_orden
	INSERT INTO talt024
		VALUES (rm_t24.t24_compania, rm_t24.t24_localidad,
			rm_t24.t24_orden, rm_detalle[indice].t24_codtarea,
			rm_t24.t24_secuencia,rm_detalle[indice].t24_descripcion,
			rm_t24.t24_paga_clte, rm_detalle[indice].t24_mecanico,
			r_mec.t03_seccion, rm_t24.t24_factor,
			rm_detalle[indice].t24_puntos_opti,
			rm_detalle[indice].t24_puntos_real,
			rm_detalle[indice].t24_porc_descto,
			rm_val_desc[indice], rm_detalle[indice].t24_valor_tarea,
			rm_t24.t24_ord_compra, rm_t24.t24_usuario,
			rm_t24.t24_fecing)
END FOR
CALL calcular_descuento_mo()
UPDATE talt023
	SET t23_val_mo_tal = rm_t23.t23_val_mo_tal,
	    t23_por_mo_tal = rm_t23.t23_por_mo_tal,
	    t23_vde_mo_tal = rm_t23.t23_vde_mo_tal,
	    t23_vde_rp_tal = rm_t23.t23_vde_rp_tal,
	    t23_vde_rp_alm = rm_t23.t23_vde_rp_alm,
	    t23_tot_bruto  = rm_t23.t23_tot_bruto,
	    t23_tot_dscto  = rm_t23.t23_tot_dscto,
	    t23_val_impto  = rm_t23.t23_val_impto,
	    t23_tot_neto   = rm_t23.t23_tot_neto
WHERE CURRENT OF q_upord2
COMMIT WORK
CALL mostrar_registro(vm_r_rows[vm_row_current])
CALL fl_mensaje_registro_modificado()
 
END FUNCTION



FUNCTION control_consulta()
DEFINE orden		LIKE talt023.t23_orden
DEFINE nomcli		LIKE talt023.t23_nom_cliente
DEFINE query		CHAR(1200)
DEFINE expr_sql		CHAR(400)

CLEAR FORM
CALL mostrar_botones_detalle()
LET int_flag = 0
CONSTRUCT BY NAME expr_sql ON t23_orden
	ON KEY(F1,CONTROL-W)
		CALL llamar_visor_teclas()
	ON KEY(F2)
		IF INFIELD(t23_orden) THEN
			CALL fl_ayuda_orden_trabajo(vg_codcia, vg_codloc, 'A')
				RETURNING orden, nomcli
			IF orden IS NOT NULL THEN
				CALL fl_lee_orden_trabajo(vg_codcia, vg_codloc,
								orden)
					RETURNING rm_t23.*
				DISPLAY orden TO t23_orden
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
LET query = 'SELECT t23_orden ',
		'FROM talt023 ',
		'WHERE t23_compania  = ', vg_codcia,
		'  AND t23_localidad = ', vg_codloc,
		'  AND ', expr_sql CLIPPED,
		--'  AND t23_estado    = "A"',
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

CALL fl_lee_configuracion_taller(vg_codcia) RETURNING rm_t00.*
CALL fl_lee_tipo_vehiculo(vg_codcia,rm_t23.t23_modelo) RETURNING rm_t04.*
CALL sacar_factor_tarea() RETURNING vm_factor, vm_flag_moneda
DISPLAY rm_t23.t23_cod_cliente TO codcli
DISPLAY rm_t23.t23_nom_cliente TO tit_cliente
DISPLAY vm_factor TO t24_factor

END FUNCTION



FUNCTION leer_detalle()
DEFINE r_mec		RECORD LIKE talt003.*
DEFINE r_t07		RECORD LIKE talt007.*
DEFINE codt_aux		LIKE talt007.t07_codtarea
DEFINE nomt_aux		LIKE talt007.t07_nombre
DEFINE codm_aux		LIKE talt003.t03_mecanico
DEFINE nomm_aux		LIKE talt003.t03_nombres
DEFINE valor            LIKE talt024.t24_valor_tarea 
DEFINE descri_ori	LIKE talt024.t24_descripcion
DEFINE max_descto	DECIMAL(4,2)
DEFINE max_descto_c	DECIMAL(4,2)
DEFINE resul, i, j	SMALLINT
DEFINE max_row		SMALLINT
DEFINE resp             CHAR(6)
DEFINE mensaje		VARCHAR(250)

INITIALIZE codt_aux, descri_ori TO NULL
LET valor = 0
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
		IF INFIELD(t24_codtarea) THEN
			CALL fl_ayuda_tempario(vg_codcia, 'A')
				RETURNING codt_aux, nomt_aux
			IF codt_aux IS NOT NULL THEN
				LET rm_t24.t24_orden          = rm_t23.t23_orden
				LET rm_detalle[i].t24_codtarea= codt_aux
				DISPLAY codt_aux TO rm_detalle[j].t24_codtarea
				CALL muestra_descripcion(nomt_aux, i, j)
			END IF
		END IF
		IF INFIELD(t24_mecanico) THEN
			CALL fl_ayuda_mecanicos(vg_codcia, 'M')
				RETURNING codm_aux, nomm_aux
			IF codm_aux IS NOT NULL THEN
				LET rm_detalle[i].t24_mecanico = codm_aux
				LET rm_detalle[i].tit_mecanico = nomm_aux
				DISPLAY codm_aux TO rm_detalle[j].t24_mecanico
				DISPLAY nomm_aux TO rm_detalle[j].tit_mecanico
			END IF
		END IF
		LET int_flag = 0
	BEFORE INPUT
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
	BEFORE ROW
		LET i = arr_curr()
		LET j = scr_line()
		LET max_row = arr_count()
		IF i > max_row THEN
			LET max_row = max_row + 1
		END IF
		CALL muestra_contadores_det(i, max_row)
		DISPLAY rm_detalle[i].t24_descripcion TO tit_descri
		CALL mostrar_total(arr_count())
	BEFORE FIELD t24_descripcion
		LET descri_ori = NULL
		CALL fl_lee_tarea(vg_codcia, rm_detalle[i].t24_codtarea)
			RETURNING r_t07.*
		IF rm_detalle[i].t24_codtarea <> rm_t00.t00_seudo_tarea AND
		   r_t07.t07_modif_desc = 'N'
		THEN
			LET descri_ori = rm_detalle[i].t24_descripcion
		END IF
		DISPLAY rm_detalle[i].t24_descripcion TO tit_descri
	BEFORE FIELD t24_valor_tarea
		IF rm_detalle[i].t24_valor_tarea IS NOT NULL THEN
			LET valor = rm_detalle[i].t24_valor_tarea
		END IF
	AFTER FIELD t24_codtarea
		IF rm_detalle[i].t24_codtarea IS NOT NULL THEN
			LET rm_t24.t24_orden = rm_t23.t23_orden
			CALL validar_tarea(i,j)	RETURNING resul
			IF resul = 1 THEN
				NEXT FIELD t24_codtarea
			END IF
			IF rm_detalle[i].t24_porc_descto IS NULL THEN
				CALL retorna_descto_maximo_tarea(vg_codcia,
						rm_detalle[i].t24_codtarea)
					RETURNING max_descto, max_descto_c
				LET rm_detalle[i].t24_porc_descto = max_descto
				IF rm_g04.g04_grupo <> 'GE' THEN
					LET rm_detalle[i].t24_porc_descto =
								max_descto
				END IF
				DISPLAY rm_detalle[i].* TO rm_detalle[j].*
			END IF
			CALL mostrar_total(arr_count())
		ELSE
			IF rm_detalle[i].t24_descripcion IS NOT NULL THEN
				NEXT FIELD t24_codtarea
			END IF
		END IF
	AFTER FIELD t24_mecanico
		IF rm_detalle[i].t24_mecanico IS NOT NULL THEN
			CALL fl_lee_mecanico(vg_codcia,
						rm_detalle[i].t24_mecanico)
				RETURNING r_mec.*
			IF r_mec.t03_compania IS NULL THEN
				CALL fl_mostrar_mensaje('Técnico no existe.','exclamation')
				NEXT FIELD t24_mecanico
			END IF
			LET rm_detalle[i].tit_mecanico = r_mec.t03_nombres
			DISPLAY r_mec.t03_nombres TO rm_detalle[j].tit_mecanico
		ELSE
			CLEAR rm_detalle[j].tit_mecanico
			NEXT FIELD t24_mecanico
		END IF
	AFTER FIELD t24_descripcion
		CALL fl_lee_tarea(vg_codcia, rm_detalle[i].t24_codtarea)
			RETURNING r_t07.*
		IF rm_detalle[i].t24_codtarea <> rm_t00.t00_seudo_tarea AND
		   r_t07.t07_modif_desc = 'N'
		THEN
			IF descri_ori IS NOT NULL THEN
				LET rm_detalle[i].t24_descripcion = descri_ori
	                        CALL muestra_descripcion(
						rm_detalle[i].t24_descripcion,
						i, j)
			END IF
		ELSE
			IF rm_detalle[i].t24_valor_tarea IS NULL AND resul = 2
			THEN
				IF rm_detalle[i].t24_porc_descto = 0 THEN
					NEXT FIELD t24_puntos_real
				END IF
			END IF
		END IF
	AFTER FIELD t24_porc_descto
		IF rm_detalle[i].t24_porc_descto IS NULL AND
		   rm_detalle[i].t24_codtarea IS NOT NULL
		THEN
			LET rm_detalle[i].t24_porc_descto = 0
			DISPLAY rm_detalle[i].* TO rm_detalle[j].*
		END IF
		IF rm_detalle[i].t24_porc_descto IS NOT NULL THEN
			CALL retorna_descto_maximo_tarea(vg_codcia,
						rm_detalle[i].t24_codtarea)
				RETURNING max_descto, max_descto_c
			IF rm_detalle[i].t24_porc_descto > max_descto THEN
				LET mensaje = 'La Tarea: ',
					rm_detalle[i].t24_codtarea CLIPPED,
					' tiene un descuento maximo de: ',
					max_descto USING '#&.##'
				CALL fl_mostrar_mensaje(mensaje, 'exclamation')
				IF rm_g04.g04_grupo <> 'GE' THEN
					LET rm_detalle[i].t24_porc_descto =
								max_descto
					DISPLAY rm_detalle[i].* TO
						rm_detalle[j].*
				END IF
			END IF
		END IF
		IF rm_detalle[i].t24_codtarea IS NOT NULL AND
		   rm_detalle[i].t24_valor_tarea IS NOT NULL
		THEN
			CALL mostrar_total(arr_count())
		END IF
	AFTER FIELD t24_puntos_real
		IF rm_detalle[i].t24_puntos_real IS NOT NULL THEN
			CALL validar_tarea(i,j) RETURNING resul
			IF resul = 1 THEN
				NEXT FIELD t24_codtarea
			END IF
			CALL mostrar_total(arr_count())
		ELSE
			IF rm_detalle[i].t24_descripcion IS NOT NULL THEN
				NEXT FIELD t24_puntos_real
			END IF
		END IF
	AFTER FIELD t24_valor_tarea
		CALL fl_lee_tarea(vg_codcia, rm_detalle[i].t24_codtarea)
			RETURNING r_t07.*
		IF rm_detalle[i].t24_codtarea <> rm_t00.t00_seudo_tarea AND
		   r_t07.t07_modif_desc = 'N'
		THEN
			IF descri_ori IS NOT NULL THEN
				LET rm_detalle[i].t24_descripcion = descri_ori
	                        CALL muestra_descripcion(
						rm_detalle[i].t24_descripcion,
						i, j)
                	END IF
                END IF
		IF rm_detalle[i].t24_valor_tarea IS NOT NULL THEN
			CALL validar_tarea(i,j) RETURNING resul
			IF resul = 1 THEN
				NEXT FIELD t24_codtarea
			END IF
			CALL fl_retorna_precision_valor(rm_t23.t23_moneda,
						rm_detalle[i].t24_valor_tarea)
                                RETURNING rm_detalle[i].t24_valor_tarea
			DISPLAY rm_detalle[i].t24_valor_tarea TO
				rm_detalle[j].t24_valor_tarea
			IF rm_detalle[i].t24_codtarea <> rm_t00.t00_seudo_tarea
			THEN
				LET rm_detalle[i].t24_valor_tarea = valor
				DISPLAY valor TO rm_detalle[j].t24_valor_tarea
			END IF
			CALL mostrar_total(arr_count())
		ELSE
			IF rm_detalle[i].t24_descripcion IS NOT NULL THEN
				NEXT FIELD t24_valor_tarea
			END IF
		END IF
	AFTER DELETE
		LET i = arr_curr()
		CALL mostrar_total(arr_count())
		CALL muestra_contadores_det(i, arr_curr())
	AFTER INPUT
		CALL mostrar_total(arr_count())
		IF rm_t23.t23_tot_neto > rm_t23.t23_valor_tope THEN
			CALL fl_mostrar_mensaje('Valor Neto excede al valor tope de la orden.','info')
			NEXT FIELD t24_valor_tarea
		END IF
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
	IF rm_detalle[i].t24_valor_tarea IS NULL THEN
		CONTINUE FOR
	END IF
	LET rm_val_desc[i] = (rm_detalle[i].t24_valor_tarea *
				rm_detalle[i].t24_porc_descto / 100)
	LET val_descto     = val_descto + rm_val_desc[i]
	LET subtotal       = subtotal + rm_detalle[i].t24_valor_tarea
	LET total_neto     = total_neto +
				(rm_detalle[i].t24_valor_tarea - rm_val_desc[i])
END FOR
LET rm_t23.t23_val_mo_tal = subtotal
CALL fl_totaliza_orden_taller(rm_t23.*) RETURNING rm_t23.*
DISPLAY BY NAME subtotal, val_descto, total_neto, rm_t23.t23_tot_neto

END FUNCTION



FUNCTION validar_tarea(i,j)
DEFINE i,j		SMALLINT
DEFINE mensaje		VARCHAR(40)
DEFINE valor		DECIMAL(11,2)
DEFINE puntos		SMALLINT
DEFINE r_tar		RECORD LIKE talt007.*
DEFINE r_pto		RECORD LIKE talt009.*

INITIALIZE r_tar.*, r_pto.* TO NULL
LET mensaje = 'ESCRIBA LA DESCRIPCION'
LET valor = 0
CALL fl_lee_configuracion_taller(vg_codcia) RETURNING rm_t00.*
IF rm_t00.t00_estado = 'B' THEN
	CALL fl_mensaje_estado_bloqueado()
	RETURN 1
END IF
CALL fl_lee_tarea(vg_codcia, rm_detalle[i].t24_codtarea) RETURNING r_tar.*
IF r_tar.t07_compania IS NULL THEN
	CALL fl_mostrar_mensaje('No existe esa tarea, para está línea.','exclamation')
	RETURN 1
END IF
IF rm_t00.t00_seudo_tarea <> rm_detalle[i].t24_codtarea THEN
	IF rm_detalle[i].t24_descripcion IS NULL THEN
		CALL muestra_descripcion(r_tar.t07_nombre,i,j)
	END IF
	IF r_tar.t07_modif_desc = 'N' THEN
		CALL muestra_descripcion(r_tar.t07_nombre,i,j)
	END IF
	IF r_tar.t07_estado = 'B' THEN
		CALL fl_mensaje_estado_bloqueado()
		RETURN 1
	END IF
	CALL fl_lee_tarea_grado_dificultad(vg_codcia,rm_detalle[i].t24_codtarea,
						rm_t04.t04_dificultad)
		RETURNING r_pto.*
	LET rm_detalle[i].t24_puntos_opti = r_tar.t07_pto_default
	IF r_pto.t09_compania IS NOT NULL THEN
		LET rm_detalle[i].t24_puntos_opti = r_pto.t09_puntos
	END IF
	IF r_tar.t07_tipo = 'V' THEN
		IF vm_flag_moneda = 0 THEN
			LET valor = r_tar.t07_val_defa_mb
		ELSE
			LET valor = r_tar.t07_val_defa_ma
		END IF
		IF r_pto.t09_compania IS NOT NULL THEN
			IF vm_flag_moneda = 0 THEN
				LET valor = r_pto.t09_valor_mb
			ELSE
				LET valor = r_pto.t09_valor_ma
			END IF
		END IF
	END IF
	IF r_tar.t07_tipo = 'P' THEN
		LET valor = vm_factor
	END IF
	IF rm_t00.t00_valor_tarea = 'O' THEN
		LET puntos = rm_detalle[i].t24_puntos_opti
	ELSE
		LET puntos = rm_detalle[i].t24_puntos_real
	END IF
	{--
	LET rm_detalle[i].t24_valor_tarea = valor * puntos / 100
	IF r_tar.t07_tipo = 'V' THEN
		LET rm_detalle[i].t24_puntos_opti = 100
		LET rm_detalle[i].t24_valor_tarea = valor
	END IF
	CALL fl_retorna_precision_valor(rm_t23.t23_moneda,
					rm_detalle[i].t24_valor_tarea)
        	RETURNING rm_detalle[i].t24_valor_tarea
	--}
	DISPLAY rm_detalle[i].* TO rm_detalle[j].*
ELSE
	LET rm_detalle[i].t24_puntos_opti = 100 
	DISPLAY rm_detalle[i].t24_puntos_opti TO rm_detalle[j].t24_puntos_opti 
	IF rm_detalle[i].t24_descripcion IS NULL THEN
		CALL muestra_descripcion(mensaje, i, j)
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
DEFINE num_registro	LIKE talt023.t23_orden

IF vm_num_rows <= 0 THEN
	RETURN
END IF
DECLARE q_dt CURSOR FOR
	SELECT * FROM talt023
		WHERE t23_compania  = vg_codcia
		  AND t23_localidad = vg_codloc
		  AND t23_orden     = num_registro
OPEN q_dt
FETCH q_dt INTO rm_t23.*
IF STATUS = NOTFOUND THEN
	CALL fl_mostrar_mensaje('No existe registro con índice: ' || vm_row_current,'exclamation')
	RETURN
END IF
CALL fl_lee_tipo_vehiculo(vg_codcia,rm_t23.t23_modelo) RETURNING rm_t04.*
DECLARE q_dt2 CURSOR FOR
	SELECT * FROM talt024
		WHERE t24_compania  = vg_codcia
		  AND t24_localidad = vg_codloc
		  AND t24_orden     = rm_t23.t23_orden
OPEN q_dt2
FETCH q_dt2 INTO rm_t24.*
IF STATUS = NOTFOUND THEN
	DISPLAY rm_t23.t23_usuario TO t24_usuario
	DISPLAY rm_t23.t23_fecing TO t24_fecing
ELSE
	DISPLAY BY NAME rm_t24.t24_usuario, rm_t24.t24_fecing
END IF
CLOSE q_dt
CLOSE q_dt2
DISPLAY BY NAME	rm_t23.t23_orden
CALL muestra_cabecera()
CALL muestra_detalle(num_registro)

END FUNCTION



FUNCTION muestra_detalle(num_reg)
DEFINE num_reg          LIKE talt023.t23_orden
DEFINE r_mec		RECORD LIKE talt003.*
DEFINE query            CHAR(400)
DEFINE i      		SMALLINT

LET int_flag = 0
FOR i = 1 TO vm_size_arr
        INITIALIZE rm_detalle[i].* TO NULL
        CLEAR rm_detalle[i].*
END FOR
LET i = 1
LET query = 'SELECT t24_codtarea, t24_mecanico, t24_porc_descto, ',
			't24_descripcion, t24_puntos_opti, t24_puntos_real, ',
			't24_valor_tarea, t24_val_descto ',
		'FROM talt024 ',
                'WHERE t24_compania  = ', vg_codcia,  
		'  AND t24_localidad = ', vg_codloc,  
		'  AND t24_orden     = ', num_reg,   
		' ORDER BY 1' 
PREPARE cons1 FROM query
DECLARE q_cons1 CURSOR FOR cons1
LET vm_num_elm = 1
FOREACH q_cons1 INTO rm_detalle[vm_num_elm].t24_codtarea,
			rm_detalle[vm_num_elm].t24_mecanico,
			rm_detalle[vm_num_elm].t24_porc_descto,
			rm_detalle[vm_num_elm].t24_descripcion,
			rm_detalle[vm_num_elm].t24_puntos_opti,
			rm_detalle[vm_num_elm].t24_puntos_real,
			rm_detalle[vm_num_elm].t24_valor_tarea,
			rm_val_desc[vm_num_elm]
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
		CALL fl_lee_mecanico(vg_codcia,rm_detalle[i].t24_mecanico)
			RETURNING r_mec.*
		LET rm_detalle[i].tit_mecanico = r_mec.t03_nombres
		DISPLAY r_mec.t03_nombres TO rm_detalle[i].tit_mecanico
		DISPLAY rm_detalle[i].t24_descripcion TO tit_descri
        END FOR
END IF
IF int_flag THEN
        INITIALIZE rm_detalle[1].* TO NULL
        RETURN
END IF
CALL muestra_contadores_det(0, vm_num_elm)
CALL mostrar_total(vm_num_elm)

END FUNCTION



FUNCTION sacar_factor_tarea()

IF rm_t23.t23_moneda = rg_gen.g00_moneda_base THEN
	RETURN rm_t00.t00_factor_mb, 0
ELSE
	IF rm_t23.t23_moneda = rg_gen.g00_moneda_alt THEN
		RETURN rm_t00.t00_factor_ma, 1
	ELSE
		CALL fl_mostrar_mensaje('No exite ninguna moneda base o alterna en el sistema.','stop')
		EXIT PROGRAM
	END IF
END IF

END FUNCTION
                                                                                
                                                                                
                                                                                
FUNCTION muestra_detalle_arr()
DEFINE i,j		SMALLINT
DEFINE r_mec		RECORD LIKE talt003.*

CALL set_count(vm_num_elm)
DISPLAY ARRAY rm_detalle TO rm_detalle.*
	ON KEY(INTERRUPT)
		EXIT DISPLAY
        ON KEY(F1,CONTROL-W)
		CALL llamar_visor_teclas()
	--#BEFORE ROW
		--#LET i = arr_curr()
        	--#LET j = scr_line()
		--#CALL fl_lee_mecanico(vg_codcia,rm_detalle[i].t24_mecanico)
			--#RETURNING r_mec.*
		--#LET rm_detalle[i].tit_mecanico = r_mec.t03_nombres
		--#DISPLAY r_mec.t03_nombres TO rm_detalle[j].tit_mecanico
		--#DISPLAY rm_detalle[i].t24_descripcion TO tit_descri
		--#CALL muestra_contadores_det(i, vm_num_elm)
	--#BEFORE DISPLAY
		--#CALL dialog.keysetlabel("ACCEPT","")
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
	--#AFTER DISPLAY
		--#CONTINUE DISPLAY
END DISPLAY

END FUNCTION



FUNCTION muestra_descripcion(descr,i,j)
DEFINE i,j		SMALLINT
DEFINE descr		LIKE talt024.t24_descripcion

LET rm_detalle[i].t24_descripcion = descr 
DISPLAY rm_detalle[i].t24_descripcion TO rm_detalle[j].t24_descripcion
DISPLAY rm_detalle[i].t24_descripcion TO tit_descri

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

LET rm_t23.t23_por_mo_tal = 0
LET rm_t23.t23_vde_mo_tal = val_descto
CALL fl_retorna_precision_valor(rm_t23.t23_moneda, rm_t23.t23_vde_mo_tal)
	RETURNING rm_t23.t23_vde_mo_tal

END FUNCTION



FUNCTION muestra_contadores_det(num_row, max_row)
DEFINE num_row, max_row	SMALLINT

DISPLAY BY NAME num_row, max_row

END FUNCTION
                                                                                
                                                                                
                                                                                
FUNCTION mostrar_botones_detalle()

--#DISPLAY 'Tarea'    TO tit_col1
--#DISPLAY 'Técnico'  TO tit_col2
--#DISPLAY 'P.O.'     TO tit_col3
--#DISPLAY 'P.R.'     TO tit_col4
--#DISPLAY 'Valor'    TO tit_col5

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
