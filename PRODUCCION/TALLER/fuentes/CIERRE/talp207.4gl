------------------------------------------------------------------------------
-- Titulo           : talp207.4gl - Reapertura de ordenes de trabajo 
-- Elaboracion      : 20-oct-2001
-- Autor            : NPC
-- Formato Ejecucion: fglrun talp207 base módulo compañía localidad
-- Ultima Correccion: 
-- Motivo Correccion: 
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_nuevoprog     CHAR(400)
DEFINE rm_ord		RECORD LIKE talt023.*
DEFINE vm_num_rows	SMALLINT
DEFINE vm_row_current	SMALLINT
DEFINE vm_max_rows	SMALLINT
DEFINE vm_r_rows	ARRAY [100] OF INTEGER



MAIN

DEFER QUIT 
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/talp207.err')
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
LET vg_proceso = 'talp207'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
--#CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL control_master()

END MAIN



FUNCTION control_master()
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
LET vm_max_rows = 100
LET lin_menu = 0
LET row_ini  = 3
LET num_rows = 14
LET num_cols = 80
IF vg_gui = 0 THEN
	LET lin_menu = 1
	LET row_ini  = 4
	LET num_rows = 20
	LET num_cols = 78
END IF
OPEN WINDOW wf AT row_ini, 2 WITH num_rows ROWS, num_cols COLUMNS
    ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE lin_menu,BORDER,
	      MESSAGE LINE LAST - 1)
IF vg_gui = 1 THEN
	OPEN FORM f_ord FROM "../forms/talf207_1"
ELSE
	OPEN FORM f_ord FROM "../forms/talf207_1c"
END IF
DISPLAY FORM f_ord
LET vm_num_rows = 0
LET vm_row_current = 0
CALL muestra_contadores(vm_row_current, vm_num_rows)
MENU 'OPCIONES'
	BEFORE MENU
		HIDE OPTION 'Avanzar'
		HIDE OPTION 'Retroceder'
		HIDE OPTION 'Ver Orden'
		HIDE OPTION 'Reabrir Orden'
	COMMAND KEY('C') 'Consultar' 'Consultar un registro. '
		CALL control_consulta()
		IF vm_num_rows <= 1 THEN
			SHOW OPTION 'Ver Orden'
			SHOW OPTION 'Reabrir Orden'
			HIDE OPTION 'Avanzar'
			HIDE OPTION 'Retroceder'
			IF vm_num_rows = 0 THEN
				HIDE OPTION 'Ver Orden'
				HIDE OPTION 'Reabrir Orden'
			END IF
		ELSE
			SHOW OPTION 'Ver Orden'
			SHOW OPTION 'Reabrir Orden'
			SHOW OPTION 'Avanzar'
		END IF
		IF vm_row_current <= 1 THEN
                        HIDE OPTION 'Retroceder'
                END IF
	COMMAND KEY('E') 'Reabrir Orden' 'Reabre una orden de trabajo. '
		CALL reabrir_orden()
	COMMAND KEY('V') 'Ver Orden' 'Consulta ordenes de trabajo. '
		CALL ver_orden()
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
	COMMAND KEY('S') 'Salir' 'Salir del programa. '
		EXIT MENU
END MENU

END FUNCTION



FUNCTION ver_orden()
DEFINE run_prog		CHAR(10)

IF rm_ord.t23_orden IS NULL THEN
	CALL fl_mensaje_consultar_primero()
	RETURN
END IF
{-- ESTO PARA LLAMAR AL PROGRAMA SEGÚN SEA EL AMBIENTE --}
LET run_prog = '; fglrun '
IF vg_gui = 0 THEN
	LET run_prog = '; fglgo '
END IF
{--- ---}
LET vm_nuevoprog = 'cd ..', vg_separador, '..', vg_separador, 'TALLER',
	vg_separador, 'fuentes', vg_separador, run_prog, 'talp204 ', vg_base,
	' ', vg_modulo, ' ', vg_codcia, ' ', vg_codloc, ' ', rm_ord.t23_orden,
	' ', 'O'
RUN vm_nuevoprog

END FUNCTION



FUNCTION reabrir_orden()
DEFINE estado		VARCHAR(10)
DEFINE r_tip		RECORD LIKE talt005.*
DEFINE r_caj		RECORD LIKE cajt010.*
DEFINE r_veh            RECORD LIKE veht038.*
DEFINE r_tal		RECORD LIKE talt025.*
DEFINE r_tal2		RECORD LIKE talt026.*
DEFINE r_tal3		RECORD LIKE talt027.*
                                                                                
IF rm_ord.t23_orden IS NULL THEN
	CALL fl_mensaje_consultar_primero()
	RETURN
END IF
IF rm_ord.t23_estado = 'C' AND rm_ord.t23_orden_cheq IS NOT NULL THEN
	CALL fl_mostrar_mensaje('No puede reabrir una orden de trabajo asociada a una orden de chequeo.','stop')
	RETURN
END IF
BEGIN WORK
WHENEVER ERROR CONTINUE
DECLARE q_up CURSOR FOR
	SELECT * FROM talt023
		WHERE t23_compania  = vg_codcia
	          AND t23_localidad = vg_codloc
	          AND t23_orden     = rm_ord.t23_orden
        FOR UPDATE
OPEN q_up
FETCH q_up INTO rm_ord.*
IF STATUS < 0 THEN
        ROLLBACK WORK
        CALL fl_mensaje_bloqueo_otro_usuario()
        WHENEVER ERROR STOP
        RETURN
END IF
DECLARE q_up2 CURSOR FOR
	SELECT * FROM talt025
		WHERE t25_compania  = vg_codcia
		  AND t25_localidad = vg_codloc
	          AND t25_orden     = rm_ord.t23_orden
        FOR UPDATE
OPEN q_up2
FETCH q_up2 INTO r_tal.*
IF STATUS < 0 THEN
        ROLLBACK WORK
        CALL fl_mensaje_bloqueo_otro_usuario()
        WHENEVER ERROR STOP
        RETURN
END IF
DECLARE q_up3 CURSOR FOR
	SELECT * FROM talt026
		WHERE t26_compania  = vg_codcia
		  AND t26_localidad = vg_codloc
		  AND t26_orden     = r_tal.t25_orden
        FOR UPDATE
OPEN q_up3
FETCH q_up3 INTO r_tal2.*
IF STATUS < 0 THEN
        ROLLBACK WORK
        CALL fl_mensaje_bloqueo_otro_usuario()
        WHENEVER ERROR STOP
        RETURN
END IF
DECLARE q_up4 CURSOR FOR
	SELECT * FROM talt027
		WHERE t27_compania  = vg_codcia
		  AND t27_localidad = vg_codloc
	          AND t27_orden     = r_tal.t25_orden
        FOR UPDATE
OPEN q_up4
FETCH q_up4 INTO r_tal3.*
IF STATUS < 0 THEN
        ROLLBACK WORK
        CALL fl_mensaje_bloqueo_otro_usuario()
        WHENEVER ERROR STOP
        RETURN
END IF
DECLARE q_up5 CURSOR FOR
	SELECT * FROM cajt010
		WHERE j10_compania    = vg_codcia
	          AND j10_localidad   = vg_codloc
	          AND j10_tipo_fuente = 'OT'
	          AND j10_num_fuente  = rm_ord.t23_orden
        FOR UPDATE
OPEN q_up5
FETCH q_up5 INTO r_caj.*
IF STATUS < 0 THEN
        ROLLBACK WORK
        CALL fl_mensaje_bloqueo_otro_usuario()
        WHENEVER ERROR STOP
        RETURN
END IF
{
-----------------------------------------------------------------------------
--- ESTA PARTE QUEDA EN COMENTARIOS PORQUE ESTE PROCESO ES DEL PROGRAMA
--- DE DON YURI
DECLARE q_up2 CURSOR FOR SELECT * FROM veht038
        WHERE v38_compania = vg_codcia
        AND v38_localidad  = vg_codloc
        AND v38_orden_cheq = rm_ord.t23_orden_cheq
        AND v38_num_ot     = rm_ord.t23_orden
        FOR UPDATE
OPEN q_up2
FETCH q_up2 INTO r_veh.*
IF STATUS < 0 THEN
        ROLLBACK WORK
        CALL fl_mensaje_bloqueo_otro_usuario()
        WHENEVER ERROR STOP
        RETURN
END IF
-----------------------------------------------------------------------------
}
WHENEVER ERROR STOP
INITIALIZE r_tip.* TO NULL
CALL fl_lee_tipo_orden_taller(vg_codcia, rm_ord.t23_tipo_ot) RETURNING r_tip.*
IF r_tip.t05_compania IS NULL THEN
	CALL fl_mostrar_mensaje('No existe tipo de orden de trabajo.','stop')
	EXIT PROGRAM 
END IF
IF rm_ord.t23_estado = 'C' AND r_tip.t05_factura = 'S' THEN
	LET int_flag = 0
	DELETE FROM talt027 WHERE t27_compania = vg_codcia
			     AND t27_localidad = vg_codloc
			     AND t27_orden     = r_tal3.t27_orden
	DELETE FROM talt026 WHERE t26_compania = vg_codcia
			     AND t26_localidad = vg_codloc
			     AND t26_orden     = r_tal2.t26_orden
	DELETE FROM talt025 WHERE t25_compania = vg_codcia
			     AND t25_localidad = vg_codloc
			     AND t25_orden     = r_tal.t25_orden
        DELETE FROM cajt010 WHERE j10_compania = vg_codcia
        		    AND j10_localidad  = vg_codloc
		            AND j10_tipo_fuente= 'OT'
        		    AND j10_num_fuente = rm_ord.t23_orden
	UPDATE talt023 SET t23_estado = 'A', t23_fec_cierre = NULL 
		WHERE CURRENT OF q_up 
	{
        ---------------------------------------------------------------------
	-- Estoy cambiando el estado de la veht038 a A de Activo cuando
        -- reabro la orden
        IF r_veh.v38_compania IS NOT NULL THEN
                UPDATE veht038 SET v38_estado = 'A' WHERE CURRENT OF q_up2
        END IF
        ---------------------------------------------------------------------
	}
	COMMIT WORK
	CALL fl_mostrar_mensaje('Orden ha sido ACTIVADA Ok.', 'info')
	CALL muestra_cabecera(rm_ord.t23_orden)
ELSE
	ROLLBACK WORK
	IF rm_ord.t23_estado <> 'C' THEN
		CALL retorna_estado(rm_ord.t23_estado) RETURNING estado
       		IF rm_ord.t23_estado = 'A' THEN
			CALL fl_mostrar_mensaje('Esta orden ya ha sido ' || estado,'exclamation')
       	 	ELSE
			CALL fl_mostrar_mensaje('Esta orden no está CERRADA, sino ' || estado,'exclamation')
        	END IF
	ELSE
		CALL fl_mostrar_mensaje('Ordenes de Trabajo que no se facturan, no pueden reabrirse.','exclamation')
       	END IF
END IF

END FUNCTION



FUNCTION control_consulta()
DEFINE orden		LIKE talt023.t23_orden
DEFINE nomcli		LIKE talt023.t23_nom_cliente
DEFINE query		CHAR(400)
DEFINE expr_sql		CHAR(400)
DEFINE estado		CHAR(10)

CLEAR FORM
INITIALIZE orden TO NULL
LET rm_ord.t23_estado = 'C'
LET int_flag = 0
CONSTRUCT BY NAME expr_sql ON t23_orden
        ON KEY(F1,CONTROL-W)
		CALL llamar_visor_teclas()
	ON KEY(F2)
		IF INFIELD(t23_orden) THEN
                        CALL fl_ayuda_orden_trabajo(vg_codcia,vg_codloc,'C')
                                RETURNING orden, nomcli
                        LET int_flag = 0
                        IF orden IS NOT NULL THEN
                                DISPLAY orden TO t23_orden
				CALL muestra_cabecera(orden)
                        END IF
                END IF
	BEFORE CONSTRUCT
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
END CONSTRUCT
IF int_flag THEN
	IF vm_row_current > 0 THEN
		CALL mostrar_registro(vm_r_rows[vm_row_current])
	ELSE
		CLEAR FORM
	END IF
	RETURN
END IF
LET query = 'SELECT *, ROWID FROM talt023 ' ||
		'WHERE t23_compania = ' || vg_codcia ||
		' AND t23_localidad = ' || vg_codloc ||
		' AND t23_estado = ' || '"' || rm_ord.t23_estado || '"' ||
		' AND ' || expr_sql CLIPPED || ' ORDER BY 1'
PREPARE cons FROM query	
DECLARE q_cons CURSOR FOR cons
LET vm_num_rows = 1
FOREACH q_cons INTO rm_ord.*, vm_r_rows[vm_num_rows]
	LET vm_num_rows = vm_num_rows + 1
        IF vm_num_rows > vm_max_rows THEN
                EXIT FOREACH
        END IF
END FOREACH
LET vm_num_rows = vm_num_rows - 1
IF vm_num_rows = 0 THEN
	LET int_flag = 0
       	--CALL fgl_winmessage(vg_producto,'No hay órdenes CERRADAS o criterio de búsqueda no válido','exclamation')
	CALL fl_mostrar_mensaje('No hay órdenes CERRADAS o criterio de búsqueda no válido.','exclamation')
	CLEAR FORM
	LET vm_row_current = 0
ELSE  
	LET vm_row_current = 1
	CALL mostrar_registro(vm_r_rows[vm_row_current])
END IF
CALL muestra_contadores(vm_row_current, vm_num_rows)

END FUNCTION



FUNCTION muestra_cabecera(orden)
DEFINE estado		CHAR(10)
DEFINE orden		LIKE talt023.t23_orden
DEFINE r_mol		RECORD LIKE talt004.*

CALL fl_lee_orden_trabajo(vg_codcia,vg_codloc,orden) RETURNING rm_ord.*
IF rm_ord.t23_compania IS NOT NULL THEN
	CALL fl_lee_tipo_vehiculo(vg_codcia,rm_ord.t23_modelo) RETURNING r_mol.*
	DISPLAY r_mol.t04_linea TO tit_linea
	DISPLAY rm_ord.t23_modelo TO tit_modelo
	DISPLAY rm_ord.t23_nom_cliente TO tit_cliente
	DISPLAY rm_ord.t23_estado TO tit_est
	CALL retorna_estado(rm_ord.t23_estado) RETURNING estado
	DISPLAY estado TO tit_estado_tal
	DISPLAY rm_ord.t23_tot_neto TO tit_total
ELSE
	CLEAR tit_modelo,tit_linea,tit_cliente,tit_est,tit_estado_tal,tit_total
END IF

END FUNCTION



FUNCTION retorna_estado(estado)
DEFINE estado		LIKE talt023.t23_estado
DEFINE est		CHAR(10)

CASE estado
	WHEN 'A' LET est = 'ACTIVADA'
	WHEN 'C' LET est = 'CERRADA'
	WHEN 'F' LET est = 'FACTURADA'
	WHEN 'E' LET est = 'ELIMINADA'
	WHEN 'D' LET est = 'DEVUELTA'
END CASE
RETURN est

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
DEFINE nrow                     SMALLINT
                                                                                
LET nrow = 17
IF vg_gui = 1 THEN
	LET nrow = 1
END IF
DISPLAY "" AT nrow, 1
DISPLAY row_current, " de ", num_rows AT nrow, 67
                                                                                
END FUNCTION



FUNCTION mostrar_registro(num_registro)
DEFINE num_registro	INTEGER

IF vm_num_rows > 0 THEN
	DECLARE q_dt CURSOR FOR SELECT * FROM talt023 WHERE rowid = num_registro
        OPEN q_dt
        FETCH q_dt INTO rm_ord.*
	IF STATUS = NOTFOUND THEN
		--CALL fgl_winmessage(vg_producto,'No existe registro con índice: ' || vm_row_current,'exclamation')
		CALL fl_mostrar_mensaje('No existe registro con índice: ' || vm_row_current,'exclamation')
		RETURN
	END IF
	DISPLAY BY NAME	rm_ord.t23_orden
	CALL muestra_cabecera(rm_ord.t23_orden)
ELSE
	RETURN
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
