------------------------------------------------------------------------------
-- Titulo           : talp205.4gl - Ingreso de tareas a ordenes de trabajo 
-- Elaboracion      : 16-oct-2001
-- Autor            : NPC
-- Formato Ejecucion: fglrun talp205 base módulo compañía localidad
-- Ultima Correccion: 21-ene-2002 
-- Motivo Correccion: Se cambio el campo talt004.t04_linea a t04_modelo 
--		      afecta tambien a la tabla talt024
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE rm_tal		RECORD LIKE talt024.*
DEFINE rm_ord		RECORD LIKE talt023.*
DEFINE rm_mol		RECORD LIKE talt004.*
DEFINE rm_cia		RECORD LIKE talt000.*
DEFINE vm_num_rows	SMALLINT
DEFINE vm_row_current	SMALLINT
DEFINE vm_max_rows	SMALLINT
DEFINE vm_max_elm       SMALLINT
DEFINE vm_num_elm       SMALLINT
DEFINE vm_flag_moneda   SMALLINT
DEFINE vm_total         LIKE talt023.t23_val_mo_tal
DEFINE vm_r_rows	ARRAY [100] OF LIKE talt023.t23_orden 
DEFINE rm_ta 		ARRAY [100] OF RECORD
				t24_codtarea	LIKE talt024.t24_codtarea,
				t24_mecanico	LIKE talt024.t24_mecanico,
				tit_mecanico	LIKE talt003.t03_nombres,
				t24_descripcion	LIKE talt024.t24_descripcion,
                        	t24_puntos_opti	LIKE talt024.t24_puntos_opti,
				t24_puntos_real	LIKE talt024.t24_puntos_real,
				t24_valor_tarea	LIKE talt024.t24_valor_tarea
			END RECORD
DEFINE vm_factor	LIKE talt024.t24_factor

DEFINE rm_horas ARRAY[50] OF RECORD
	t34_fecha	LIKE talt034.t34_fecha,
	t34_hora_ini	LIKE talt034.t34_hora_ini,
	t34_hora_fin	LIKE talt034.t34_hora_fin
END RECORD

MAIN

DEFER QUIT 
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/talp205.error')
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
LET vg_proceso = 'talp205'
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
OPEN FORM f_tal FROM "../forms/talf205_1"
DISPLAY FORM f_tal
CALL mostrar_botones_detalle()
INITIALIZE rm_tal.*, rm_ord.*, rm_mol.*, rm_cia.* TO NULL
LET vm_num_rows = 0
LET vm_row_current = 0
LET vm_num_elm = 0
LET vm_total   = 0
FOR indice = 1 TO vm_max_elm
        INITIALIZE rm_ta[indice].* TO NULL
END FOR
LET rm_tal.t24_compania  = vg_codcia
LET rm_tal.t24_localidad = vg_codloc
LET rm_tal.t24_paga_clte = 'S'
LET rm_tal.t24_usuario   = vg_usuario
LET rm_tal.t24_fecing    = CURRENT

CREATE TEMP TABLE te_horas(
	te_tarea		char(12),
	te_secuencia		integer,
	te_fecha		date,
	te_hora_ini		datetime hour to minute,
	te_hora_fin		datetime hour to minute
)

CALL muestra_contadores(vm_row_current, vm_num_rows)
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
		   IF fl_control_permiso_opcion('Modificar') THEN			
			SHOW OPTION 'Modificar'
		   END IF 
			
			HIDE OPTION 'Avanzar'
			HIDE OPTION 'Retroceder'
			IF vm_num_rows = 0 THEN
				HIDE OPTION 'Modificar'
			END IF
		ELSE
			SHOW OPTION 'Avanzar'
		   IF fl_control_permiso_opcion('Modificar') THEN			
			SHOW OPTION 'Modificar'
		   END IF 
			
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
DEFINE r_mec		RECORD LIKE talt003.*
DEFINE fecing		LIKE talt034.t34_fecing

DEFINE query		VARCHAR(500)

INITIALIZE r_mec.* TO NULL
IF vm_num_rows = 0 THEN
	CALL fl_mensaje_consultar_primero()
	RETURN
END IF
CALL mostrar_registro(vm_r_rows[vm_row_current])
CALL fl_lee_orden_trabajo(vg_codcia,vg_codloc,vm_r_rows[vm_row_current])
	RETURNING rm_ord.*
IF rm_ord.t23_estado <> 'A' THEN
	IF rm_ord.t23_estado = 'C' THEN
		CALL fgl_winmessage(vg_producto,'Esta orden ya ha sido cerrada','exclamation')
	ELSE
		CALL fgl_winmessage(vg_producto,'Esta orden no está activa','exclamation')
      	END IF
	RETURN
END IF
CALL fl_lee_tipo_vehiculo(vg_codcia,rm_ord.t23_modelo) RETURNING rm_mol.*
WHENEVER ERROR CONTINUE
BEGIN WORK
DECLARE q_upord2 CURSOR FOR SELECT * FROM talt023
	WHERE t23_compania  = vg_codcia AND 
	      t23_localidad = vg_codloc AND 
	      t23_orden     = vm_r_rows[vm_row_current]
	FOR UPDATE
OPEN q_upord2
FETCH q_upord2 INTO rm_ord.*
IF STATUS < 0 THEN
	ROLLBACK WORK
	CALL fl_mensaje_bloqueo_otro_usuario()
	WHENEVER ERROR STOP
	RETURN
END IF
DECLARE q_up CURSOR FOR SELECT * FROM talt024
	WHERE t24_compania = vg_codcia
	AND t24_localidad  = vg_codloc
	AND t24_orden      = vm_r_rows[vm_row_current]
	AND t24_modelo     = rm_mol.t04_modelo
	FOR UPDATE
OPEN q_up
FETCH q_up INTO rm_tal.*
IF STATUS < 0 THEN
	ROLLBACK WORK
	CALL fl_mensaje_bloqueo_otro_usuario()
	WHENEVER ERROR STOP
	RETURN
END IF
LET vm_total   = 0
WHENEVER ERROR STOP
CALL leer_detalle('M') RETURNING num_elm
IF NOT int_flag THEN
	DELETE FROM talt034 WHERE t34_compania = vg_codcia
			AND t34_localidad = vg_codloc
			AND t34_orden = rm_tal.t24_orden
			AND t34_modelo = rm_mol.t04_modelo
	DELETE FROM talt024 WHERE t24_compania = vg_codcia
			AND t24_localidad = vg_codloc
			AND t24_orden = rm_tal.t24_orden
			AND t24_modelo = rm_mol.t04_modelo
	LET rm_tal.t24_factor = vm_factor
	FOR indice = 1 TO arr_count()
		CALL fl_lee_mecanico(vg_codcia,rm_ta[indice].t24_mecanico)
			RETURNING r_mec.*
		LET rm_tal.t24_secuencia  = indice
		LET rm_tal.t24_orden  = rm_ord.t23_orden
		INSERT INTO talt024 VALUES (rm_tal.t24_compania,
			rm_tal.t24_localidad, rm_tal.t24_orden,
			rm_tal.t24_modelo, rm_ta[indice].t24_codtarea,
			rm_tal.t24_secuencia, rm_ta[indice].t24_descripcion,
			rm_tal.t24_paga_clte, rm_ta[indice].t24_mecanico,
			r_mec.t03_seccion, rm_tal.t24_factor,
       			rm_ta[indice].t24_puntos_opti,
			rm_ta[indice].t24_puntos_real,
			rm_ta[indice].t24_valor_tarea,
			rm_tal.t24_ord_compra, rm_tal.t24_usuario,
			rm_tal.t24_fecing)
	END FOR
	LET int_flag = 0
	UPDATE talt023 SET t23_val_mo_tal = rm_ord.t23_val_mo_tal,
			   t23_vde_mo_tal = rm_ord.t23_vde_mo_tal,
			   t23_vde_rp_tal = rm_ord.t23_vde_rp_tal,
			   t23_vde_rp_alm = rm_ord.t23_vde_rp_alm,
			   t23_tot_bruto  = rm_ord.t23_tot_bruto,
			   t23_tot_dscto  = rm_ord.t23_tot_dscto,
			   t23_val_impto  = rm_ord.t23_val_impto,
			   t23_tot_neto   = rm_ord.t23_tot_neto
		WHERE CURRENT OF q_upord2

-- Para grabar las horas en la talt034
	LET fecing = CURRENT
	LET query = "INSERT INTO talt034 ",
			" SELECT ", rm_tal.t24_compania,  ",  ", 
                                    rm_tal.t24_localidad, ",  ",
			            rm_tal.t24_orden,     ",  ",
			       "'", rm_tal.t24_modelo CLIPPED,    "', ",
		                 "  te_tarea, te_secuencia, te_fecha, ",
				 "  te_hora_ini, te_hora_fin, ",
				 "'", vg_usuario CLIPPED, "', '", fecing, "'", 
			" FROM te_horas "
	PREPARE stmnt FROM query
	EXECUTE stmnt

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
DEFINE orden		LIKE talt023.t23_orden
DEFINE nomcli		LIKE talt023.t23_nom_cliente
DEFINE query		VARCHAR(400)
DEFINE expr_sql		VARCHAR(400)

LET int_flag = 0
CLEAR FORM
CALL mostrar_botones_detalle()
INITIALIZE orden TO NULL
CONSTRUCT BY NAME expr_sql ON t23_orden
	ON KEY(F2)
		IF infield(t23_orden) THEN
                        CALL fl_ayuda_orden_trabajo(vg_codcia,vg_codloc,'A')
                                RETURNING orden, nomcli
                        LET int_flag = 0
                        IF orden IS NOT NULL THEN
				CALL fl_lee_orden_trabajo(vg_codcia,vg_codloc,
							orden)
					RETURNING rm_ord.*
                                DISPLAY orden TO t23_orden
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
LET query = 'SELECT t23_orden FROM talt023 ' ||
		'WHERE t23_compania = ' || vg_codcia ||
		' AND t23_localidad = ' || vg_codloc ||
		' AND ' || expr_sql CLIPPED ||
--		' AND t23_estado = ' || '"' || 'A' || '"' || 
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

CALL fl_lee_configuracion_taller(vg_codcia) RETURNING rm_cia.*
CALL fl_lee_tipo_vehiculo(vg_codcia,rm_ord.t23_modelo) RETURNING rm_mol.*
LET rm_tal.t24_modelo = rm_mol.t04_modelo
DISPLAY BY NAME rm_mol.t04_linea
DISPLAY rm_ord.t23_modelo TO tit_modelo
DISPLAY rm_ord.t23_nom_cliente TO tit_cliente
CALL sacar_factor_tarea() RETURNING vm_factor, vm_flag_moneda
DISPLAY vm_factor TO t24_factor

END FUNCTION



FUNCTION leer_detalle(flag_mant)
DEFINE flag_mant	CHAR(1)
DEFINE resul		SMALLINT
DEFINE resp             CHAR(6)
DEFINE i,j              SMALLINT
DEFINE r_mec		RECORD LIKE talt003.*
DEFINE codtarea		LIKE talt007.t07_codtarea
DEFINE codt_aux		LIKE talt007.t07_codtarea
DEFINE nomt_aux		LIKE talt007.t07_nombre
DEFINE codm_aux		LIKE talt003.t03_mecanico
DEFINE nomm_aux		LIKE talt003.t03_nombres
DEFINE valor            LIKE talt024.t24_valor_tarea 
DEFINE descri_ori	LIKE talt024.t24_descripcion

LET i = 1
LET resul = 0
INITIALIZE r_mec.* TO NULL
INITIALIZE codt_aux TO NULL
INITIALIZE descri_ori TO NULL
LET valor = 0
IF flag_mant = 'I' THEN
	CALL muestra_descripcion(NULL,1,1)
END IF
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
		IF infield(t24_codtarea) THEN
			CALL fl_ayuda_tempario(vg_codcia,rm_tal.t24_modelo)
				RETURNING codt_aux, nomt_aux
			LET int_flag = 0
			IF codt_aux IS NOT NULL THEN
				LET rm_tal.t24_orden         = rm_ord.t23_orden
				LET rm_ta[i].t24_codtarea    = codt_aux
				DISPLAY codt_aux TO rm_ta[j].t24_codtarea
				CALL muestra_descripcion(nomt_aux,i,j)
			END IF
		END IF
		IF infield(t24_mecanico) THEN
			CALL fl_ayuda_mecanicos(vg_codcia,'M')
				RETURNING codm_aux, nomm_aux
			LET int_flag = 0
			IF codm_aux IS NOT NULL THEN
				LET rm_ta[i].t24_mecanico = codm_aux
				LET rm_ta[i].tit_mecanico = nomm_aux
				DISPLAY codm_aux TO rm_ta[j].t24_mecanico
				DISPLAY nomm_aux TO rm_ta[j].tit_mecanico
			END IF
		END IF
	BEFORE INPUT 
		CALL dialog.keysetlabel('F5', 'Tiempo')
	ON KEY(F5)
		CALL ingresar_horas_tarea(rm_ta[i].t24_codtarea, 
					  rm_ta[i].t24_descripcion,		
					  i,		
					  rm_ta[i].t24_mecanico,		
					  rm_ta[i].tit_mecanico)		
		DISPLAY rm_ta[i].t24_puntos_real 
			TO rm_ta[j].t24_puntos_real 
		LET int_flag = 0
	BEFORE ROW
        	LET i = arr_curr()
        	LET j = scr_line()
		DISPLAY rm_ta[i].t24_descripcion TO tit_descri
		CALL sacar_total()
	BEFORE FIELD t24_descripcion
		IF pseudo_tarea(rm_ta[i].t24_codtarea) = 0 THEN
			LET descri_ori = rm_ta[i].t24_descripcion
		END IF
		DISPLAY rm_ta[i].t24_descripcion TO tit_descri
	BEFORE FIELD t24_codtarea
		LET codtarea = rm_ta[i].t24_codtarea
	BEFORE FIELD t24_valor_tarea
		IF rm_ta[i].t24_valor_tarea IS NOT NULL THEN
			LET valor = rm_ta[i].t24_valor_tarea
		END IF
	AFTER FIELD t24_codtarea
		IF rm_ta[i].t24_codtarea IS NOT NULL THEN
			LET rm_tal.t24_orden = rm_ord.t23_orden
			CALL validar_tarea(i,j)	RETURNING resul
			IF resul = 1 THEN
				NEXT FIELD t24_codtarea
			END IF
			CALL sacar_total()
			UPDATE te_horas set te_tarea = rm_ta[i].t24_codtarea
				WHERE te_tarea     = codtarea
				  AND te_secuencia = i
		ELSE
			IF rm_ta[i].t24_descripcion IS NOT NULL THEN
				NEXT FIELD t24_codtarea
			END IF
		END IF
	AFTER FIELD t24_mecanico
		IF rm_ta[i].t24_mecanico IS NOT NULL THEN
			CALL fl_lee_mecanico(vg_codcia,rm_ta[i].t24_mecanico)
				RETURNING r_mec.*
			IF r_mec.t03_compania IS NULL THEN
				CALL fgl_winmessage(vg_producto,'Mecánico no existe','exclamation')
				NEXT FIELD t24_mecanico
			END IF
			LET rm_ta[i].tit_mecanico = r_mec.t03_nombres
			DISPLAY r_mec.t03_nombres TO rm_ta[j].tit_mecanico
		ELSE
			CLEAR rm_ta[j].tit_mecanico
			NEXT FIELD t24_mecanico
		END IF
	AFTER FIELD t24_descripcion
		IF pseudo_tarea(rm_ta[i].t24_codtarea) = 0 THEN
			LET rm_ta[i].t24_descripcion = descri_ori
                        CALL muestra_descripcion(rm_ta[i].t24_descripcion,i,j)
		ELSE
			IF rm_ta[i].t24_valor_tarea IS NULL AND resul = 2 THEN
				NEXT FIELD t24_puntos_real
			END IF
                END IF
	AFTER FIELD t24_puntos_real
		IF rm_ta[i].t24_puntos_real IS NOT NULL THEN
			CALL validar_tarea(i,j) RETURNING resul
			IF resul = 1 THEN
				NEXT FIELD t24_codtarea
			END IF
			CALL sacar_total()
		ELSE
			IF rm_ta[i].t24_descripcion IS NOT NULL THEN
				NEXT FIELD t24_puntos_real
			END IF
		END IF
	AFTER FIELD t24_valor_tarea
		IF pseudo_tarea(rm_ta[i].t24_codtarea) = 0 THEN
			LET rm_ta[i].t24_descripcion = descri_ori
                        CALL muestra_descripcion(rm_ta[i].t24_descripcion,i,j)
                END IF
		IF rm_ta[i].t24_valor_tarea IS NOT NULL THEN
			CALL validar_tarea(i,j) RETURNING resul
			IF resul = 1 THEN
				NEXT FIELD t24_codtarea
			END IF
			CALL fl_retorna_precision_valor(rm_ord.t23_moneda,
                                                       rm_ta[i].t24_valor_tarea)
                                RETURNING rm_ta[i].t24_valor_tarea
			DISPLAY rm_ta[i].t24_valor_tarea
				TO rm_ta[j].t24_valor_tarea
			IF rm_ta[i].t24_codtarea <> rm_cia.t00_seudo_tarea THEN
				LET rm_ta[i].t24_valor_tarea = valor
				DISPLAY valor TO rm_ta[j].t24_valor_tarea
			END IF
			CALL sacar_total()
			CONTINUE INPUT
		ELSE
			IF rm_ta[i].t24_descripcion IS NOT NULL THEN
				NEXT FIELD t24_valor_tarea
			END IF
		END IF
	BEFORE DELETE
		CALL borra_horas_secuencia(rm_ta[i].t24_codtarea, i)
		UPDATE te_horas SET te_secuencia = te_secuencia - 1
			WHERE te_secuencia > i
	AFTER DELETE
                CALL sacar_total()
	AFTER INPUT
                CALL sacar_total()
		IF rm_ord.t23_tot_neto > rm_ord.t23_valor_tope THEN
			CALL fgl_winmessage(vg_producto,
				'Valor Neto excede al valor tope de la orden',
				'info')
			NEXT FIELD t24_valor_tarea
		END IF
END INPUT
LET i = arr_count()
RETURN i

END FUNCTION



FUNCTION sacar_total()
DEFINE i        SMALLINT
                                                                                
LET vm_total = 0
FOR i = 1 TO arr_count()
        LET vm_total = vm_total + rm_ta[i].t24_valor_tarea
END FOR
LET rm_ord.t23_val_mo_tal = vm_total
CALL fl_totaliza_orden_taller(rm_ord.*) RETURNING rm_ord.*
CALL mostrar_total()

END FUNCTION



FUNCTION validar_tarea(i,j)
DEFINE i,j		SMALLINT
DEFINE mensaje		VARCHAR(40)
DEFINE valor		DECIMAL(11,2)
DEFINE puntos		SMALLINT
DEFINE r_tar		RECORD LIKE talt007.*
DEFINE r_t35		RECORD LIKE talt035.*
DEFINE r_pto		RECORD LIKE talt009.*

INITIALIZE r_tar.* TO NULL
INITIALIZE r_t35.* TO NULL
INITIALIZE r_pto.* TO NULL
LET mensaje = 'ESCRIBA LA DESCRIPCION'
LET valor = 0
CALL fl_lee_configuracion_taller(vg_codcia) RETURNING rm_cia.*
IF rm_cia.t00_estado = 'B' THEN
	CALL fl_mensaje_estado_bloqueado()
	RETURN 1
END IF
CALL fl_lee_tarea(vg_codcia, rm_tal.t24_modelo, rm_ta[i].t24_codtarea)
	RETURNING r_tar.*
IF r_tar.t07_compania IS NULL THEN
	CALL fgl_winmessage(vg_producto,
		'No existe esa tarea, para está línea',
		'exclamation')
	RETURN 1
END IF
SELECT * INTO r_t35.* FROM talt035
	WHERE t35_compania = vg_codcia
	  AND t35_codtarea = rm_ta[i].t24_codtarea
IF r_t35.t35_compania IS NOT NULL THEN
	LET mensaje = r_t35.t35_nombre
END IF
IF pseudo_tarea(rm_ta[i].t24_codtarea) = 0 THEN
	CALL muestra_descripcion(r_tar.t07_nombre,i,j)
	IF r_tar.t07_estado = 'B' THEN
		CALL fl_mensaje_estado_bloqueado()
		RETURN 1
	END IF
	CALL fl_lee_tarea_grado_dificultad(vg_codcia,rm_tal.t24_modelo,
				rm_ta[i].t24_codtarea,rm_mol.t04_dificultad)
		RETURNING r_pto.*
	LET rm_ta[i].t24_puntos_opti = r_tar.t07_pto_default
	IF r_pto.t09_compania IS NOT NULL THEN
		LET rm_ta[i].t24_puntos_opti = r_pto.t09_puntos
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
	IF r_tar.t07_tipo = 'V' THEN
		LET rm_ta[i].t24_puntos_opti = 100
		LET rm_ta[i].t24_valor_tarea = valor
	END IF
	IF rm_cia.t00_valor_tarea = 'O' THEN
		LET puntos = rm_ta[i].t24_puntos_opti
	ELSE
		LET puntos = rm_ta[i].t24_puntos_real
	END IF
	LET rm_ta[i].t24_valor_tarea = valor * puntos / 100
	CALL fl_retorna_precision_valor(rm_ord.t23_moneda,
						rm_ta[i].t24_valor_tarea)
        	RETURNING rm_ta[i].t24_valor_tarea
	DISPLAY rm_ta[i].* TO rm_ta[j].*
ELSE
	LET rm_ta[i].t24_puntos_opti = 100 
	DISPLAY rm_ta[i].t24_puntos_opti TO rm_ta[j].t24_puntos_opti 
	IF rm_ta[i].t24_descripcion IS NULL THEN
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
DEFINE num_registro	LIKE talt023.t23_orden

IF vm_num_rows > 0 THEN
	DECLARE q_dt CURSOR FOR SELECT * FROM talt023 
                WHERE t23_compania  = vg_codcia AND 
		      t23_localidad = vg_codloc AND 
		      t23_orden     = num_registro
        OPEN q_dt
        FETCH q_dt INTO rm_ord.*
	IF STATUS = NOTFOUND THEN
		CALL fgl_winmessage (vg_producto,
		'No existe registro con índice: ' || vm_row_current,
		'exclamation')
		RETURN
	END IF
	CALL fl_lee_tipo_vehiculo(vg_codcia,rm_ord.t23_modelo)
		 RETURNING rm_mol.*
	DECLARE q_dt2 CURSOR FOR SELECT * FROM talt024 
                WHERE t24_compania  = vg_codcia AND 
		      t24_localidad = vg_codloc AND 
		      t24_orden     = rm_ord.t23_orden AND
		      t24_modelo    = rm_mol.t04_modelo
		ORDER BY 1, 2, 3, 4, 5, 6 
        OPEN q_dt2
        FETCH q_dt2 INTO rm_tal.*
	IF STATUS = NOTFOUND THEN
		DISPLAY rm_ord.t23_usuario TO t24_usuario
		DISPLAY rm_ord.t23_fecing TO t24_fecing
	ELSE
		DISPLAY BY NAME rm_tal.t24_usuario, rm_tal.t24_fecing
	END IF
	DISPLAY BY NAME	rm_ord.t23_orden
	CALL muestra_cabecera()
	CALL muestra_detalle(num_registro, rm_mol.t04_modelo)
ELSE
	RETURN
END IF
CLOSE q_dt
CLOSE q_dt2

DELETE FROM te_horas WHERE 1 = 1
INSERT INTO te_horas 
	SELECT t34_codtarea, t34_secuencia, t34_fecha, t34_hora_ini, 
               t34_hora_fin
	FROM talt034
	WHERE t34_compania  = vg_codcia
	  AND t34_localidad = vg_codloc
	  AND t34_orden     = rm_ord.t23_orden 
          AND t34_modelo    = rm_mol.t04_modelo

END FUNCTION



FUNCTION muestra_detalle(num_reg, modelo)
DEFINE num_reg          LIKE talt023.t23_orden
DEFINE modelo         	LIKE talt004.t04_modelo
DEFINE r_mec		RECORD LIKE talt003.*
DEFINE query            VARCHAR(400)
DEFINE i      		SMALLINT
DEFINE secuencia	SMALLINT

LET int_flag = 0
FOR i = 1 TO fgl_scr_size('rm_ta')
        INITIALIZE rm_ta[i].* TO NULL
        CLEAR rm_ta[i].*
END FOR
LET i = 1
LET query = 'SELECT t24_codtarea,t24_mecanico,t24_descripcion, t24_secuencia,
		t24_puntos_opti,t24_puntos_real,t24_valor_tarea, t03_nombres ' ||
		'FROM talt024, talt003 ' ||
                'WHERE t24_compania = ' || vg_codcia ||
		' AND t24_localidad = ' || vg_codloc ||
		' AND t24_orden = ' || num_reg ||
		' AND t24_modelo = ' || '"' || modelo || '"' ||
		' AND t03_compania = t24_compania ' ||
		' AND t03_mecanico = t24_mecanico ' || 
		' ORDER BY 4' 
PREPARE cons1 FROM query
DECLARE q_cons1 CURSOR FOR cons1
LET vm_num_elm = 0
LET vm_total = 0
FOREACH q_cons1 INTO rm_ta[i].t24_codtarea,rm_ta[i].t24_mecanico,
		rm_ta[i].t24_descripcion, secuencia,
		rm_ta[i].t24_puntos_opti,rm_ta[i].t24_puntos_real,
		rm_ta[i].t24_valor_tarea, rm_ta[i].tit_mecanico
        LET vm_num_elm = vm_num_elm + 1
	LET vm_total = vm_total + rm_ta[i].t24_valor_tarea
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
		CALL fl_lee_mecanico(vg_codcia,rm_ta[i].t24_mecanico)
			RETURNING r_mec.*
		LET rm_ta[i].tit_mecanico = r_mec.t03_nombres
		DISPLAY r_mec.t03_nombres TO rm_ta[i].tit_mecanico
		DISPLAY rm_ta[i].t24_descripcion TO tit_descri
        END FOR
END IF
IF int_flag THEN
        INITIALIZE rm_ta[1].* TO NULL
        RETURN
END IF
CALL mostrar_total()

END FUNCTION



FUNCTION sacar_factor_tarea()

IF rm_ord.t23_moneda = rg_gen.g00_moneda_base THEN
	RETURN rm_cia.t00_factor_mb, 0
ELSE
	IF rm_ord.t23_moneda = rg_gen.g00_moneda_alt THEN
		RETURN rm_cia.t00_factor_ma, 1
	ELSE
		CALL fgl_winmessage(vg_producto,'No exite ninguna moneda base o alterna en el sistema','stop')
		EXIT PROGRAM
	END IF
END IF

END FUNCTION
                                                                                
                                                                                
                                                                                
FUNCTION muestra_detalle_arr()
DEFINE i,j		SMALLINT
DEFINE r_mec		RECORD LIKE talt003.*

CALL set_count(vm_num_elm)
DISPLAY ARRAY rm_ta TO rm_ta.*
	BEFORE ROW
		LET i = arr_curr()
        	LET j = scr_line()
		CALL fl_lee_mecanico(vg_codcia,rm_ta[i].t24_mecanico)
			RETURNING r_mec.*
		LET rm_ta[i].tit_mecanico = r_mec.t03_nombres
		DISPLAY r_mec.t03_nombres TO rm_ta[j].tit_mecanico
		DISPLAY rm_ta[i].t24_descripcion TO tit_descri
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
DISPLAY BY NAME rm_ord.t23_tot_neto
                                                                                
END FUNCTION



FUNCTION muestra_descripcion(descr,i,j)
DEFINE i,j		SMALLINT
DEFINE descr		LIKE talt024.t24_descripcion

LET rm_ta[i].t24_descripcion = descr 
DISPLAY rm_ta[i].t24_descripcion TO rm_ta[j].t24_descripcion
DISPLAY rm_ta[i].t24_descripcion TO tit_descri

END FUNCTION
                                                                                
                                                                                
                                                                                
FUNCTION mostrar_botones_detalle()

DISPLAY 'Tarea'    TO tit_col1
DISPLAY 'Mécanico' TO tit_col2
DISPLAY 'P.O.'     TO tit_col3
DISPLAY 'P.R.'     TO tit_col4
DISPLAY 'Valor'    TO tit_col5

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




FUNCTION ingresar_horas_tarea(r_tarea)	
DEFINE resp		CHAR(6)
DEFINE r_tarea RECORD
	t24_codtarea	LIKE talt024.t24_codtarea,
	t24_descripcion	LIKE talt024.t24_descripcion,
	t24_secuencia   LIKE talt024.t24_secuencia,
	t24_mecanico	LIKE talt024.t24_mecanico,
	tit_mecanico	LIKE talt003.t03_nombres  
END RECORD


DEFINE i, j, col	SMALLINT
DEFINE max_rows		SMALLINT
DEFINE salir		SMALLINT

DEFINE minutos 		INTEGER

LET max_rows = 50

OPEN WINDOW w_205_2 AT 8,3 WITH 12 ROWS, 76 COLUMNS
    ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, BORDER, MESSAGE LINE LAST)
OPEN FORM f_205_2 FROM "../forms/talf205_2"
DISPLAY FORM f_205_2

DISPLAY 'Fecha' 	TO bt_fecha
DISPLAY 'Hora Inicio'	TO bt_horaini
DISPLAY 'Hora Fin'	TO bt_horafin

DISPLAY BY NAME r_tarea.t24_codtarea,
		r_tarea.t24_descripcion,
		r_tarea.t24_mecanico,
		r_tarea.tit_mecanico

DECLARE q_horario CURSOR FOR 
	SELECT te_fecha, te_hora_ini, te_hora_fin 
		FROM te_horas 
		WHERE te_tarea     = r_tarea.t24_codtarea
		  AND te_secuencia = r_tarea.t24_secuencia
		ORDER BY te_fecha, te_hora_ini

LET i = 1
FOREACH q_horario INTO rm_horas[i].*    
	LET i = i + 1
	IF i > max_rows THEN
		EXIT FOREACH
	END IF
END FOREACH
LET i = i - 1

LET int_flag = 0
IF i <= 0 THEN
	LET i = 1
	INITIALIZE rm_horas[i].* TO NULL
END IF
CALL set_count(i)
INPUT ARRAY rm_horas WITHOUT DEFAULTS FROM r_horas.*
	BEFORE ROW
		LET i = arr_curr()
		LET j = scr_line()
	AFTER INPUT
		LET i = arr_count()
		LET minutos = 0
		FOR j = 1 TO i
			IF rm_horas[j].t34_hora_ini > rm_horas[j].t34_hora_fin 
			THEN
				CALL fgl_winmessage(vg_producto, 'La hora inicial debe ser menor a la hora final.', 'exclamation')
				CONTINUE INPUT
			END IF
			LET minutos = minutos + convertir_horas_numero(rm_horas[j].t34_hora_fin - rm_horas[j].t34_hora_ini)
		END FOR
END INPUT
IF int_flag THEN
	CLOSE WINDOW w_205_2
	RETURN 
END IF

CALL graba_temporal(r_tarea.t24_codtarea, r_tarea.t24_secuencia, i)
LET rm_ta[r_tarea.t24_secuencia].t24_puntos_real = (minutos * 100) / 60

CLOSE WINDOW w_205_2

END FUNCTION



FUNCTION borra_horas_secuencia(cod_tarea, secuencia)
DEFINE cod_tarea		LIKE talt024.t24_codtarea
DEFINE secuencia		LIKE talt024.t24_secuencia

DELETE FROM te_horas WHERE te_tarea     = cod_tarea
		       AND te_secuencia = secuencia

END FUNCTION



FUNCTION graba_temporal(cod_tarea, secuencia, numelm)
DEFINE cod_tarea		LIKE talt024.t24_codtarea
DEFINE secuencia		LIKE talt024.t24_secuencia
DEFINE numelm			SMALLINT
DEFINE i			SMALLINT

CALL borra_horas_secuencia(cod_tarea, secuencia)

FOR i = 1 TO numelm 
	INSERT INTO te_horas VALUES (cod_tarea, secuencia, 
				     rm_horas[i].t34_fecha,
				     rm_horas[i].t34_hora_ini, 
				     rm_horas[i].t34_hora_fin)
END FOR

END FUNCTION



FUNCTION pseudo_tarea(cod_tarea)
DEFINE cod_tarea	LIKE talt035.t35_codtarea
DEFINE r_t35		RECORD LIKE talt035.*

IF cod_tarea IS NULL THEN
	RETURN 0
END IF

INITIALIZE r_t35.* TO NULL
SELECT * INTO r_t35.* FROM talt035 WHERE t35_compania = vg_codcia
				     AND t35_codtarea = cod_tarea

IF r_t35.t35_compania IS NULL THEN
	IF rm_cia.t00_seudo_tarea <> cod_tarea THEN
		RETURN 0
	END IF
END IF

RETURN 1

END FUNCTION



FUNCTION convertir_horas_numero(hora)
DEFINE hora		CHAR(6)	
DEFINE fraccion		SMALLINT
DEFINE num_hora		SMALLINT	

LET fraccion = obtener_fraccion_horas(hora)
LET num_hora = fraccion * 60

LET fraccion = obtener_fraccion_minutos(hora)
LET num_hora = num_hora + fraccion

RETURN num_hora

END FUNCTION



FUNCTION obtener_fraccion_horas(hora)
DEFINE hora		CHAR(6)	
DEFINE fraccion		SMALLINT

	LET fraccion = hora[2,2] * 10
	IF fraccion IS NULL THEN
		LET fraccion = 0
	END IF
	LET fraccion = fraccion + (hora[3,3] * 1)

	RETURN fraccion
END FUNCTION



FUNCTION obtener_fraccion_minutos(hora)
DEFINE hora		CHAR(6)	
DEFINE fraccion		SMALLINT

	LET fraccion = fraccion + (hora[5,5] * 10)
	LET fraccion = fraccion + (hora[6,6] * 1)

	RETURN fraccion
END FUNCTION

