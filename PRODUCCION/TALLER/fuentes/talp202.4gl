------------------------------------------------------------------------------
-- Titulo           : talp202.4gl - Ingreso de tareas a presupuestos 
-- Elaboracion      : 10-oct-2001
-- Autor            : NPC
-- Formato Ejecucion: fglrun talp202 base módulo compañía localidad
-- Ultima Correccion: 21-ene-2002 
-- Motivo Correccion: Cambiar el tempario por lineas a un tempario por modelos
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE rm_tal		RECORD LIKE talt020.*
DEFINE rm_tal2		RECORD LIKE talt021.*
DEFINE rm_ord           RECORD LIKE talt023.*
DEFINE rm_mol           RECORD LIKE talt004.*
DEFINE rm_cia           RECORD LIKE talt000.*
DEFINE vm_num_rows	SMALLINT
DEFINE vm_row_current	SMALLINT
DEFINE vm_max_rows	SMALLINT
DEFINE vm_max_elm       SMALLINT
DEFINE vm_num_elm       SMALLINT
DEFINE vm_total       	LIKE talt020.t20_total_mo
DEFINE vm_r_rows	ARRAY [100] OF LIKE talt020.t20_numpre 
DEFINE rm_ta 		ARRAY [100] OF RECORD
				t21_codtarea	LIKE talt021.t21_codtarea,
				t21_descripcion	LIKE talt021.t21_descripcion,
				t21_valor	LIKE talt021.t21_valor
			END RECORD

MAIN

DEFER QUIT 
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/talp202.error')
CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 THEN          -- Validar # parámetros correcto
	CALL fgl_winmessage(vg_producto, 'Número de parámetros incorrecto', 'stop')
	EXIT PROGRAM
END IF
LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_codcia   = arg_val(3)
LET vg_codloc   = arg_val(4)
LET vg_proceso = 'talp202'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL control_master()

END MAIN



FUNCTION control_master()
DEFINE indice           SMALLINT

CALL fl_nivel_isolation()
LET vm_max_rows	= 100
LET vm_max_elm  = 100
OPEN WINDOW wf AT 3,2 WITH 22 ROWS, 80 COLUMNS
    ATTRIBUTE(FORM LINE FIRST + 2, COMMENT LINE LAST, MENU LINE FIRST,BORDER,
	      MESSAGE LINE LAST - 2)
OPTIONS INPUT WRAP,
	ACCEPT KEY	F12
OPEN FORM f_tal FROM "../forms/talf202_1"
DISPLAY FORM f_tal
CALL mostrar_botones_detalle()
INITIALIZE rm_tal.*, rm_tal2.*, rm_ord.*, rm_mol.*, rm_cia.* TO NULL
LET vm_num_rows = 0
LET vm_row_current = 0
LET vm_num_elm = 0
LET vm_total   = 0
FOR indice = 1 TO vm_max_elm
        INITIALIZE rm_ta[indice].* TO NULL
END FOR
LET rm_tal2.t21_compania  = vg_codcia
LET rm_tal2.t21_localidad = vg_codloc
LET rm_tal2.t21_usuario   = vg_usuario
LET rm_tal2.t21_fecing    = CURRENT
CALL muestra_contadores(vm_row_current, vm_num_rows)
MENU 'OPCIONES'
	BEFORE MENU
		HIDE OPTION 'Avanzar'
		HIDE OPTION 'Retroceder'
		HIDE OPTION 'Modificar'
		HIDE OPTION 'Detalle'
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
		IF vm_num_elm > fgl_scr_size('rm_ta') THEN
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
		IF vm_num_elm > fgl_scr_size('rm_ta') THEN
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
		IF vm_num_elm > fgl_scr_size('rm_ta') THEN
                        SHOW OPTION 'Detalle'
                ELSE
                        HIDE OPTION 'Detalle'
                END IF
	COMMAND KEY('D') 'Detalle' 'Muestra siguiente detalles del registro. '
                CALL muestra_detalle_arr()
	COMMAND KEY('S') 'Salir' 'Salir del programa. '
		EXIT MENU
END MENU

END FUNCTION



FUNCTION control_modificacion()
DEFINE num_elm          SMALLINT
DEFINE indice           SMALLINT

IF vm_num_rows = 0 THEN
	CALL fl_mensaje_consultar_primero()
	RETURN
END IF
CALL mostrar_registro(vm_r_rows[vm_row_current])
CALL fl_lee_presupuesto_taller(vg_codcia,vg_codloc,vm_r_rows[vm_row_current])
	RETURNING rm_tal.*
IF rm_tal.t20_estado = 'P' THEN
	CALL fgl_winmessage(vg_producto,'Este presupuesto ya ha sido aprobado','exclamation')
	RETURN
END IF
CALL fl_lee_orden_trabajo(vg_codcia,vg_codloc,rm_tal.t20_orden)
	RETURNING rm_ord.*
CALL fl_lee_tipo_vehiculo(vg_codcia,rm_ord.t23_modelo) RETURNING rm_mol.*
BEGIN WORK
WHENEVER ERROR CONTINUE
DECLARE q_uppre2 CURSOR FOR SELECT * FROM talt020
	WHERE t20_compania  = vg_codcia AND
	      t20_localidad = vg_codloc AND
              t20_numpre    = vm_r_rows[vm_row_current]
	FOR UPDATE
OPEN q_uppre2
FETCH q_uppre2 INTO rm_tal.*
IF STATUS < 0 THEN
	COMMIT WORK
	CALL fl_mensaje_bloqueo_otro_usuario()
	WHENEVER ERROR STOP
	RETURN
END IF
DECLARE q_up CURSOR FOR SELECT * FROM talt021
	WHERE t21_compania = vg_codcia
	AND t21_localidad  = vg_codloc
	AND t21_numpre     = vm_r_rows[vm_row_current]
	AND t21_modelo     = rm_mol.t04_modelo
	FOR UPDATE
OPEN q_up
FETCH q_up INTO rm_tal2.*
IF STATUS < 0 THEN
	ROLLBACK WORK
	CALL fl_mensaje_bloqueo_otro_usuario()
	WHENEVER ERROR STOP
	RETURN
END IF
LET vm_total   = 0
WHENEVER ERROR STOP
CALL leer_detalle() RETURNING num_elm
IF NOT int_flag THEN
	DELETE FROM talt021 WHERE t21_compania = vg_codcia
			AND t21_localidad  = vg_codloc
			AND t21_numpre     = rm_tal2.t21_numpre
			AND t21_modelo     = rm_mol.t04_modelo
	FOR indice = 1 TO arr_count()
		LET rm_tal2.t21_secuencia  = indice
		INSERT INTO talt021 VALUES (rm_tal2.t21_compania,
					rm_tal2.t21_localidad,
					rm_tal2.t21_numpre,
					rm_tal2.t21_modelo,
					rm_ta[indice].t21_codtarea,
					rm_tal2.t21_secuencia,
					rm_ta[indice].t21_descripcion,
					rm_ta[indice].t21_valor,
					rm_tal2.t21_usuario,
					rm_tal2.t21_fecing)
	END FOR
	LET int_flag = 0
	UPDATE talt020 SET t20_total_mo = rm_tal.t20_total_mo
		WHERE CURRENT OF q_uppre2
	COMMIT WORK
	CALL fl_mensaje_registro_modificado()
ELSE
	CLEAR FORM
	CALL mostrar_botones_detalle()
	IF vm_row_current > 0 THEN
		CALL mostrar_registro(vm_r_rows[vm_row_current])
	END IF
	ROLLBACK WORK
END IF
WHENEVER ERROR STOP
 
END FUNCTION



FUNCTION control_consulta()
DEFINE numpre		LIKE talt020.t20_numpre
DEFINE codcli		LIKE talt023.t23_cod_cliente
DEFINE nomcli		LIKE talt023.t23_nom_cliente
DEFINE query		VARCHAR(400)
DEFINE expr_sql		VARCHAR(400)

LET int_flag = 0
CLEAR FORM
CALL mostrar_botones_detalle()
INITIALIZE numpre TO NULL
CONSTRUCT BY NAME expr_sql ON t20_numpre
	ON KEY(F2)
		IF infield(t20_numpre) THEN
                	CALL fl_ayuda_presupuestos_taller(vg_codcia,vg_codloc,'A')
                                RETURNING numpre, codcli, nomcli
                        LET int_flag = 0
                        IF numpre IS NOT NULL THEN
				CALL fl_lee_presupuesto_taller(vg_codcia,
							vg_codloc, numpre)
					RETURNING rm_tal.*
                                DISPLAY numpre TO t20_numpre
				CALL muestra_cabecera()
                        END IF
                END IF
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
LET query = 'SELECT t20_numpre FROM talt020 ' ||
		'WHERE t20_compania = ' || vg_codcia ||
		' AND t20_localidad = ' || vg_codloc ||
		' AND ' || expr_sql CLIPPED ||
		' AND t20_estado = ' || '"' || 'A' || '"' || ' ORDER BY 1'
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

CALL fl_lee_orden_trabajo(vg_codcia,vg_codloc,rm_tal.t20_orden)
	RETURNING rm_ord.*
CALL fl_lee_configuracion_taller(vg_codcia) RETURNING rm_cia.*
CALL fl_lee_tipo_vehiculo(vg_codcia,rm_ord.t23_modelo) RETURNING rm_mol.*
LET rm_tal2.t21_modelo = rm_mol.t04_modelo
DISPLAY rm_ord.t23_nom_cliente TO tit_cliente
DISPLAY rm_ord.t23_modelo TO tit_modelo
DISPLAY rm_mol.t04_linea TO tit_linea

END FUNCTION



FUNCTION leer_detalle()
DEFINE resul		SMALLINT
DEFINE resp             CHAR(6)
DEFINE i,j              SMALLINT
DEFINE codt_aux		LIKE talt007.t07_codtarea
DEFINE nomt_aux		LIKE talt007.t07_nombre
DEFINE descri_ori	LIKE talt021.t21_descripcion

LET i = 1
LET resul = 0
INITIALIZE codt_aux TO NULL
INITIALIZE descri_ori TO NULL
CALL set_count(vm_num_elm)
LET int_flag = 0
INPUT ARRAY rm_ta WITHOUT DEFAULTS FROM rm_ta.*
	ON KEY(INTERRUPT)
               	LET int_flag = 0
               	CALL fl_mensaje_abandonar_proceso()
                       	RETURNING resp
               	IF resp = 'Yes' THEN
			LET vm_total = 0
                	LET int_flag = 1
          	     	CLEAR FORM
			CALL mostrar_botones_detalle()
               		RETURN i
               	END IF
	ON KEY(F2)
		IF infield(t21_codtarea) THEN
			CALL fl_ayuda_tempario(vg_codcia,rm_tal2.t21_modelo)
				RETURNING codt_aux, nomt_aux
			LET int_flag = 0
			IF codt_aux IS NOT NULL THEN
				LET rm_tal2.t21_numpre	     = rm_tal.t20_numpre
				LET rm_ta[i].t21_codtarea    = codt_aux
				DISPLAY codt_aux TO rm_ta[j].t21_codtarea
				CALL muestra_descripcion(nomt_aux,i,j)
			END IF
		END IF
	BEFORE ROW
        	LET i = arr_curr()
        	LET j = scr_line()
		DISPLAY rm_ta[i].t21_descripcion TO tit_descri
		CALL sacar_total()
	BEFORE FIELD t21_descripcion
                IF rm_ta[i].t21_codtarea <> rm_cia.t00_seudo_tarea THEN
                        LET descri_ori = rm_ta[i].t21_descripcion
                END IF
		DISPLAY rm_ta[i].t21_descripcion TO tit_descri
	AFTER FIELD t21_codtarea
		IF rm_ta[i].t21_codtarea IS NOT NULL THEN
			LET rm_tal2.t21_numpre = rm_tal.t20_numpre
			CALL validar_tarea(i,j) RETURNING resul
			IF resul = 1 THEN
				NEXT FIELD t21_codtarea
			END IF
			CALL sacar_total()
		ELSE
			IF rm_ta[i].t21_descripcion IS NOT NULL THEN
                                NEXT FIELD t21_codtarea
                        END IF
		END IF
	AFTER FIELD t21_descripcion
                IF rm_ta[i].t21_codtarea <> rm_cia.t00_seudo_tarea THEN
                        LET rm_ta[i].t21_descripcion = descri_ori
                        CALL muestra_descripcion(rm_ta[i].t21_descripcion,i,j)
		ELSE 
			IF rm_ta[i].t21_valor IS NULL AND resul = 2 THEN
                                NEXT FIELD t21_valor
                        END IF
                END IF
	AFTER FIELD t21_valor
                IF rm_ta[i].t21_codtarea <> rm_cia.t00_seudo_tarea THEN
                        LET rm_ta[i].t21_descripcion = descri_ori
                        CALL muestra_descripcion(rm_ta[i].t21_descripcion,i,j)
                END IF
		IF rm_ta[i].t21_valor IS NOT NULL THEN
			CALL validar_tarea(i,j) RETURNING resul
			IF resul = 1 THEN
				NEXT FIELD t21_codtarea
			END IF
			CALL fl_retorna_precision_valor(rm_ord.t23_moneda,
                                                        rm_ta[i].t21_valor)
                                RETURNING rm_ta[i].t21_valor
			DISPLAY rm_ta[i].t21_valor TO rm_ta[j].t21_valor
			CALL sacar_total()
			CONTINUE INPUT
		ELSE
			IF rm_ta[i].t21_descripcion IS NOT NULL THEN
                                NEXT FIELD t21_valor
                        END IF
		END IF
	AFTER DELETE
		CALL sacar_total()
	AFTER INPUT
		CALL sacar_total()
END INPUT
LET i = arr_count()
RETURN i

END FUNCTION



FUNCTION sacar_total()
DEFINE i        SMALLINT
                                                                                
LET vm_total = 0
FOR i = 1 TO arr_count()
        LET vm_total = vm_total + rm_ta[i].t21_valor
END FOR
LET rm_tal.t20_total_mo = vm_total + (vm_total * rm_tal.t20_recargo_mo / 100)
CALL mostrar_total()
                                                                                
END FUNCTION



FUNCTION validar_tarea(i,j)
DEFINE i,j		SMALLINT
DEFINE mensaje		VARCHAR(40)
DEFINE valor		DECIMAL(11,2)	
DEFINE puntos		SMALLINT
DEFINE r_tar		RECORD LIKE talt007.*
DEFINE r_pto		RECORD LIKE talt009.*

INITIALIZE r_tar.* TO NULL
INITIALIZE r_pto.* TO NULL
LET mensaje = 'ESCRIBA LA DESCRIPCION'
LET valor = 0
CALL fl_lee_configuracion_taller(vg_codcia) RETURNING rm_cia.*
IF rm_cia.t00_estado = 'B' THEN
	CALL fl_mensaje_estado_bloqueado()
	RETURN 1
END IF
IF rm_cia.t00_seudo_tarea <> rm_ta[i].t21_codtarea THEN
	CALL fl_lee_tarea(vg_codcia,rm_tal2.t21_modelo,rm_ta[i].t21_codtarea)
		RETURNING r_tar.*
	IF r_tar.t07_compania IS NULL THEN
		CALL fgl_winmessage(vg_producto,
			'No existe esa tarea.',
			'exclamation')
		RETURN 1
	END IF
	CALL muestra_descripcion(r_tar.t07_nombre,i,j)
	IF r_tar.t07_estado = 'B' THEN
		CALL fl_mensaje_estado_bloqueado()
		RETURN 1
	END IF
	CALL fl_lee_tarea_grado_dificultad(vg_codcia,rm_tal2.t21_modelo,
				rm_ta[i].t21_codtarea,rm_mol.t04_dificultad)
		RETURNING r_pto.*
	LET puntos = r_tar.t07_pto_default
	IF r_pto.t09_compania IS NOT NULL THEN
		LET puntos = r_pto.t09_puntos
	END IF
	IF r_tar.t07_tipo = 'V' THEN
		IF rm_ord.t23_moneda = rg_gen.g00_moneda_base THEN
			LET valor = r_tar.t07_val_defa_mb
		ELSE
			LET valor = r_tar.t07_val_defa_ma
		END IF
		IF r_pto.t09_compania IS NOT NULL THEN
			IF rm_ord.t23_moneda = rg_gen.g00_moneda_base THEN
				LET valor = r_pto.t09_valor_mb
			ELSE
				LET valor = r_pto.t09_valor_ma
			END IF
		END IF
	END IF
	IF r_tar.t07_tipo = 'P' THEN
		IF rm_ord.t23_moneda = rg_gen.g00_moneda_base THEN
			LET valor = rm_cia.t00_factor_mb
		ELSE
			LET valor = rm_cia.t00_factor_ma
		END IF
	END IF
ELSE
	IF rm_ta[i].t21_descripcion IS NULL THEN
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
                                                                                
DISPLAY "" AT 1,1
DISPLAY row_current, " de ", num_rows AT 1, 69
                                                                                
END FUNCTION



FUNCTION mostrar_registro(num_registro)
DEFINE num_registro	LIKE talt020.t20_numpre

IF vm_num_rows > 0 THEN
	DECLARE q_dt CURSOR FOR SELECT * FROM talt020
                WHERE t20_compania  = vg_codcia AND
		      t20_localidad = vg_codloc AND
		      t20_numpre    = num_registro
        OPEN q_dt
        FETCH q_dt INTO rm_tal.*
	IF STATUS = NOTFOUND THEN
		CALL fgl_winmessage (vg_producto,
			'No existe registro con índice: ' || vm_row_current,
			'exclamation')
		RETURN
	END IF
	CALL fl_lee_tipo_vehiculo(vg_codcia, rm_ord.t23_modelo)
                RETURNING rm_mol.*
	DECLARE q_dt2 CURSOR FOR SELECT * FROM talt021
                WHERE t21_compania  = vg_codcia AND
		      t21_localidad = vg_codloc AND
		      t21_numpre    = rm_tal.t20_numpre AND
		      t21_modelo    = rm_mol.t04_modelo
        OPEN q_dt2
        FETCH q_dt2 INTO rm_tal2.*
	IF STATUS = NOTFOUND THEN
		DISPLAY rm_tal.t20_usuario TO t21_usuario
		DISPLAY rm_tal.t20_fecing TO t21_fecing
	ELSE
		DISPLAY BY NAME rm_tal2.t21_usuario, rm_tal2.t21_fecing
	END IF
	DISPLAY BY NAME	rm_tal.t20_numpre
	CALL muestra_cabecera()
	CALL muestra_detalle(num_registro, rm_mol.t04_modelo)
ELSE
	RETURN
END IF
CLOSE q_dt
CLOSE q_dt2

END FUNCTION



FUNCTION muestra_detalle(num_reg, modelo)
DEFINE num_reg          LIKE talt020.t20_numpre
DEFINE modelo  		LIKE talt004.t04_modelo
DEFINE query            VARCHAR(400)
DEFINE i                SMALLINT
                                                                                
LET int_flag = 0
FOR i = 1 TO fgl_scr_size('rm_ta')
        INITIALIZE rm_ta[i].* TO NULL
        CLEAR rm_ta[i].*
END FOR
LET i = 1
LET query = 'SELECT t21_codtarea,t21_descripcion,t21_valor FROM talt021 ' ||
                'WHERE t21_compania = ' || vg_codcia ||
		' AND t21_localidad = ' || vg_codloc ||
		' AND t21_numpre = ' || num_reg ||
		' AND t21_modelo = ' || '"' || modelo || '"' || ' ORDER BY 1'
PREPARE cons1 FROM query
DECLARE q_cons1 CURSOR FOR cons1
LET vm_num_elm = 0
LET vm_total = 0
FOREACH q_cons1 INTO rm_ta[i].*
        LET vm_num_elm = vm_num_elm + 1
        LET vm_total = vm_total + rm_ta[i].t21_valor
        LET i = i + 1
        IF vm_num_elm > vm_max_elm THEN
        	LET vm_num_elm = vm_num_elm - 1
		CALL fl_mensaje_arreglo_incompleto()
		EXIT PROGRAM
                --EXIT FOREACH
        END IF
END FOREACH
IF vm_num_elm > 0 THEN
        LET int_flag = 0
        FOR i = 1 TO fgl_scr_size('rm_ta')
                DISPLAY rm_ta[i].* TO rm_ta[i].*
		DISPLAY rm_ta[i].t21_descripcion TO tit_descri
        END FOR
END IF
IF int_flag THEN
        INITIALIZE rm_ta[1].* TO NULL
        RETURN
END IF
CALL mostrar_total()

END FUNCTION
                                                                                
                                                                                
                                                                                
FUNCTION muestra_detalle_arr()
DEFINE i		SMALLINT

CALL set_count(vm_num_elm)
DISPLAY ARRAY rm_ta TO rm_ta.*
	BEFORE ROW
		LET i = arr_curr()
		DISPLAY rm_ta[i].t21_descripcion TO tit_descri
	BEFORE DISPLAY
		CALL dialog.keysetlabel("ACCEPT","")
	AFTER DISPLAY
		CONTINUE DISPLAY
	ON KEY(INTERRUPT)
		EXIT DISPLAY
END DISPLAY
                                                                                
END FUNCTION



FUNCTION mostrar_total()

DISPLAY vm_total TO tit_total

END FUNCTION



FUNCTION muestra_descripcion(descr,i,j)
DEFINE i,j		SMALLINT
DEFINE descr		LIKE talt021.t21_descripcion

LET rm_ta[i].t21_descripcion = descr 
DISPLAY rm_ta[i].t21_descripcion TO rm_ta[j].t21_descripcion
DISPLAY rm_ta[i].t21_descripcion TO tit_descri

END FUNCTION



FUNCTION mostrar_botones_detalle()

DISPLAY 'Tarea'       TO tit_col1
DISPLAY 'Descripción' TO tit_col2
DISPLAY 'Valor'       TO tit_col3

END FUNCTION
                                                                                
                                                                                
                                                                                
FUNCTION validar_parametros()

CALL fl_lee_modulo(vg_modulo) RETURNING rg_mod.*
IF rg_mod.g50_modulo IS NULL THEN
	CALL fgl_winmessage(vg_producto, 'No existe módulo: ' || vg_modulo, 'stop')
	EXIT PROGRAM
END IF
CALL fl_lee_compania(vg_codcia) RETURNING rg_cia.*
IF rg_cia.g01_compania IS NULL THEN
	CALL fgl_winmessage(vg_producto, 'No existe compañía: '|| vg_codcia, 'stop')
	EXIT PROGRAM
END IF
IF rg_cia.g01_estado <> 'A' THEN
	CALL fgl_winmessage(vg_producto, 'Compañía no está activa: ' || vg_codcia, 'stop')
	EXIT PROGRAM
END IF
IF vg_codloc IS NULL THEN
	LET vg_codloc   = fl_retorna_agencia_default(vg_codcia)
END IF
CALL fl_lee_localidad(vg_codcia, vg_codloc) RETURNING rg_loc.*
IF rg_loc.g02_localidad IS NULL THEN
	CALL fgl_winmessage(vg_producto, 'No existe localidad: ' || vg_codloc, 'stop')
	EXIT PROGRAM
END IF
IF rg_loc.g02_estado <> 'A' THEN
	CALL fgl_winmessage(vg_producto, 'Localidad no está activa: '|| vg_codloc, 'stop')
	EXIT PROGRAM
END IF

END FUNCTION
