-----------------------------------------------------------------------------
-- Titulo           : talp201.4gl - Mantenimiento de Presupuestos 
-- Elaboracion      : 10-oct-2001
-- Autor            : NPC
-- Formato Ejecucion: fglrun talp201 base módulo compañía localidad
-- Ultima Correccion: 
-- Motivo Correccion: 
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_nuevoprog	VARCHAR(400)
DEFINE rm_tal		RECORD LIKE talt020.*
DEFINE vm_num_rows	SMALLINT
DEFINE vm_row_current	SMALLINT
DEFINE vm_max_rows	SMALLINT
DEFINE vm_r_rows	ARRAY [1000] OF INTEGER
DEFINE vm_orden		LIKE talt020.t20_orden
DEFINE vm_numpre	LIKE talt020.t20_numpre

MAIN

DEFER QUIT 
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/talp201.error')
CALL fgl_init4js()
CALL fl_marca_registrada_producto()
INITIALIZE vm_numpre TO NULL
IF num_args() <> 4 THEN
	IF num_args() <> 5 THEN          -- Validar # parámetros correcto
		CALL fgl_winmessage(vg_producto, 'Número de parámetros incorrecto', 'stop')
		EXIT PROGRAM
	END IF
END IF
LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_codcia   = arg_val(3)
LET vg_codloc   = arg_val(4)
LET vm_numpre   = arg_val(5)
LET vg_proceso = 'talp201'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL control_master()

END MAIN



FUNCTION control_master()

CALL fl_nivel_isolation()
LET vm_max_rows	= 1000
OPEN WINDOW wf AT 3,2 WITH 22 ROWS, 80 COLUMNS
    ATTRIBUTE(FORM LINE FIRST + 2, COMMENT LINE LAST, MENU LINE FIRST,BORDER,
	      MESSAGE LINE LAST - 2)
OPTIONS INPUT WRAP,
	ACCEPT KEY	F12
OPEN FORM f_tal FROM "../forms/talf201_1"
DISPLAY FORM f_tal
INITIALIZE rm_tal.* TO NULL
INITIALIZE vm_orden TO NULL
LET vm_num_rows    = 0
LET vm_row_current = 0
IF vm_numpre IS NOT NULL THEN
	CALL control_consulta('E')
END IF
CALL muestra_contadores(vm_row_current, vm_num_rows)
MENU 'OPCIONES'
	BEFORE MENU
		IF vm_row_current = 0 THEN
			HIDE OPTION 'Avanzar'
			HIDE OPTION 'Retroceder'
			HIDE OPTION 'Modificar'
			HIDE OPTION 'Ver Orden'
			HIDE OPTION 'Aprobar/Activar'
		ELSE
			SHOW OPTION 'Modificar'
			SHOW OPTION 'Ver Orden'
			IF vm_num_rows = 1 THEN
                                HIDE OPTION 'Avanzar'
                                HIDE OPTION 'Retroceder'
                        ELSE
                                SHOW OPTION 'Avanzar'
				IF vm_row_current > 1 THEN
                                	SHOW OPTION 'Retroceder'
				ELSE
                                	HIDE OPTION 'Retroceder'
                        	END IF
                        END IF
		END IF
		IF vm_numpre IS NOT NULL THEN
			HIDE OPTION 'Ingresar'
			HIDE OPTION 'Modificar'
			HIDE OPTION 'Consultar'
			HIDE OPTION 'Ver Orden'
			HIDE OPTION 'Aprobar/Activar'
		END IF
	COMMAND KEY('I') 'Ingresar' 'Ingresar nuevos registros. '
		CALL control_ingreso()
		IF vm_num_rows = 1 THEN
			SHOW OPTION 'Modificar'
			SHOW OPTION 'Aprobar/Activar'
			SHOW OPTION 'Ver Orden'
		END IF
		IF vm_row_current > 1 THEN
			SHOW OPTION 'Retroceder'
		END IF
		IF vm_row_current = vm_num_rows THEN
			HIDE OPTION 'Avanzar'
		END IF
       	COMMAND KEY('M') 'Modificar' 'Modificar registro corriente. '
		CALL control_modificacion()
	COMMAND KEY('C') 'Consultar' 'Consultar un registro. '
		CALL control_consulta('C')
		IF vm_num_rows <= 1 THEN
			SHOW OPTION 'Modificar'
			SHOW OPTION 'Ver Orden'
			SHOW OPTION 'Aprobar/Activar'
			HIDE OPTION 'Avanzar'
			HIDE OPTION 'Retroceder'
			IF vm_num_rows = 0 THEN
				HIDE OPTION 'Modificar'
				HIDE OPTION 'Aprobar/Activar'
				HIDE OPTION 'Ver Orden'
			END IF
		ELSE
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Aprobar/Activar'
			SHOW OPTION 'Modificar'
			SHOW OPTION 'Ver Orden'
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
     	COMMAND KEY('P') 'Aprobar/Activar' 'Aprueba o no un registro. '
		CALL aprobacion()
     	COMMAND KEY('V') 'Ver Orden' 'Ver orden del presupuesto. '
		CALL ver_orden()
	COMMAND KEY('S') 'Salir' 'Salir del programa. '
		EXIT MENU
END MENU

END FUNCTION



FUNCTION control_ingreso()
DEFINE num_aux		INTEGER
DEFINE r_mon		RECORD LIKE gent013.*
DEFINE r_ord		RECORD LIKE talt023.*

CALL fl_retorna_usuario()
INITIALIZE rm_tal.* TO NULL
INITIALIZE r_mon.* TO NULL
INITIALIZE r_ord.* TO NULL
CLEAR t20_numpre, tit_est, tit_estado_tal, tit_nomcli, tit_modelo, tit_chasis,
	tit_color, tit_mon_bas
LET rm_tal.t20_compania    = vg_codcia
LET rm_tal.t20_localidad   = vg_codloc
LET rm_tal.t20_numpre      = 0
LET rm_tal.t20_recargo_mo  = 0
LET rm_tal.t20_recargo_rp  = 0
LET rm_tal.t20_total_mo    = 0 
LET rm_tal.t20_total_rp    = 0 
LET rm_tal.t20_moneda      = rg_gen.g00_moneda_base
LET rm_tal.t20_usuario     = vg_usuario
LET rm_tal.t20_fecing      = CURRENT
LET rm_tal.t20_estado      = 'A'
CALL fl_lee_moneda(rm_tal.t20_moneda) RETURNING r_mon.*
IF r_mon.g13_moneda IS NULL THEN
        CALL fgl_winmessage(vg_producto,'No existe ninguna moneda base','stop')
        EXIT PROGRAM
ELSE
	LET rm_tal.t20_precision = r_mon.g13_decimales
        DISPLAY r_mon.g13_nombre TO tit_mon_bas
END IF
CALL muestra_estado()
CALL leer_datos('I')
IF NOT int_flag THEN
	LET rm_tal.t20_fecing = CURRENT
	SELECT MAX(t20_numpre) INTO rm_tal.t20_numpre FROM talt020
        IF rm_tal.t20_numpre IS NOT NULL THEN
                LET rm_tal.t20_numpre = rm_tal.t20_numpre + 1
        ELSE
                LET rm_tal.t20_numpre = 1
        END IF
       	WHENEVER ERROR CONTINUE
	BEGIN WORK
	DECLARE q_npre CURSOR FOR SELECT * FROM talt023
		WHERE t23_compania    = rm_tal.t20_compania
		AND t23_localidad     = rm_tal.t20_localidad
		AND t23_orden         = rm_tal.t20_orden
		FOR UPDATE
	OPEN q_npre
	FETCH q_npre INTO r_ord.*
	IF STATUS < 0 THEN
               	COMMIT WORK
               	CALL fl_mensaje_bloqueo_otro_usuario()
               	WHENEVER ERROR STOP
               	RETURN
       	END IF
	INSERT INTO talt020 VALUES (rm_tal.*)
	LET num_aux = SQLCA.SQLERRD[6] 
	UPDATE talt023 SET t23_numpre = rm_tal.t20_numpre
		WHERE CURRENT OF q_npre
	COMMIT WORK
       	WHENEVER ERROR STOP
	IF vm_num_rows = vm_max_rows THEN
		LET vm_num_rows = 1
	ELSE
		LET vm_num_rows = vm_num_rows + 1
	END IF
	LET vm_row_current = vm_num_rows
	LET vm_r_rows[vm_row_current] = num_aux 
	DISPLAY BY NAME rm_tal.t20_numpre, rm_tal.t20_fecing
	CALL mostrar_registro(vm_r_rows[vm_num_rows])	
	CALL muestra_contadores(vm_row_current, vm_num_rows)
	CALL fl_mensaje_registro_ingresado()
ELSE
	CLEAR FORM
	IF vm_row_current > 0 THEN
		CALL mostrar_registro(vm_r_rows[vm_row_current])
	END IF
END IF

END FUNCTION



FUNCTION control_modificacion()
DEFINE r_ord		RECORD LIKE talt023.*
	
INITIALIZE r_ord.* TO NULL
IF vm_num_rows = 0 THEN
	CALL fl_mensaje_consultar_primero()
	RETURN
END IF
IF rm_tal.t20_estado = 'P' THEN
	CALL fgl_winmessage(vg_producto,'Presupuesto no puede ser modificado','info')
	RETURN
END IF
CALL mostrar_registro(vm_r_rows[vm_row_current])
WHENEVER ERROR CONTINUE
BEGIN WORK
DECLARE q_up CURSOR FOR SELECT * FROM talt020
	WHERE ROWID = vm_r_rows[vm_row_current]
	FOR UPDATE
OPEN q_up
FETCH q_up INTO rm_tal.*
IF STATUS < 0 THEN
	COMMIT WORK
	CALL fl_mensaje_bloqueo_otro_usuario()
	WHENEVER ERROR STOP
	RETURN
END IF
DECLARE q_npre2 CURSOR FOR SELECT * FROM talt023
	WHERE t23_compania = rm_tal.t20_compania
	AND t23_localidad  = rm_tal.t20_localidad
	AND t23_orden      = rm_tal.t20_orden
	FOR UPDATE
OPEN q_npre2
FETCH q_npre2 INTO r_ord.*
IF STATUS < 0 THEN
      	COMMIT WORK
       	CALL fl_mensaje_bloqueo_otro_usuario()
       	WHENEVER ERROR STOP
       	RETURN
END IF
CALL leer_datos('M')
IF NOT int_flag THEN
	UPDATE talt020 SET t20_orden      = rm_tal.t20_orden,
			   t20_motivo     = rm_tal.t20_motivo,
			   t20_recargo_mo = rm_tal.t20_recargo_mo,
			   t20_recargo_rp = rm_tal.t20_recargo_rp,
			   t20_moneda     = rm_tal.t20_moneda
		WHERE CURRENT OF q_up
	IF vm_orden <> rm_tal.t20_orden THEN
		UPDATE talt023 SET t23_numpre = NULL
			WHERE CURRENT OF q_npre2
		UPDATE talt023 SET t23_numpre = rm_tal.t20_numpre
			WHERE t23_compania = rm_tal.t20_compania
			AND t23_localidad  = rm_tal.t20_localidad
			AND t23_orden      = rm_tal.t20_orden
	END IF
	COMMIT WORK
	CALL fl_mensaje_registro_modificado()
ELSE
	CLEAR FORM
	IF vm_row_current > 0 THEN
		CALL mostrar_registro(vm_r_rows[vm_row_current])
	END IF
	COMMIT WORK
END IF
WHENEVER ERROR STOP
 
END FUNCTION



FUNCTION control_consulta(flag_mant)
DEFINE flag_mant	CHAR(1)
DEFINE r_ord		RECORD LIKE talt023.*
DEFINE numpre		LIKE talt020.t20_numpre
DEFINE codcli		LIKE talt023.t23_cod_cliente
DEFINE nomcli		LIKE talt023.t23_nom_cliente
DEFINE codo_aux		LIKE talt023.t23_orden
DEFINE nomo_aux		LIKE cxct001.z01_nomcli
DEFINE mone_aux		LIKE gent013.g13_moneda
DEFINE nomm_aux		LIKE gent013.g13_nombre
DEFINE deci_aux		LIKE gent013.g13_decimales
DEFINE query		VARCHAR(400)
DEFINE expr_sql		VARCHAR(400)
DEFINE num_reg		INTEGER

LET int_flag = 0
INITIALIZE r_ord.* TO NULL
INITIALIZE numpre TO NULL
INITIALIZE codo_aux TO NULL
INITIALIZE mone_aux TO NULL
CLEAR FORM
IF flag_mant = 'C' THEN
	CONSTRUCT BY NAME expr_sql ON t20_numpre, t20_orden, t20_motivo,
		t20_recargo_mo,	t20_recargo_rp, t20_moneda
		ON KEY(F2)
			IF infield(t20_numpre) THEN
				CALL fl_ayuda_presupuestos_taller(vg_codcia,
								vg_codloc,'T')
					RETURNING numpre, codcli, nomcli
				LET int_flag = 0
				IF numpre IS NOT NULL THEN
					DISPLAY numpre TO t20_numpre
					DISPLAY nomcli TO tit_nomcli
				END IF
			END IF
			IF infield(t20_orden) THEN
				CALL fl_ayuda_orden_trabajo(vg_codcia,vg_codloc,
								'A')
					RETURNING codo_aux, nomo_aux
				LET int_flag = 0
				IF codo_aux IS NOT NULL THEN
					CALL fl_lee_orden_trabajo(vg_codcia,
							vg_codloc,codo_aux)
						RETURNING r_ord.*
					DISPLAY codo_aux TO t20_orden
					DISPLAY r_ord.t23_nom_cliente
						TO tit_nomcli
					DISPLAY r_ord.t23_modelo TO tit_modelo
					DISPLAY r_ord.t23_chasis TO tit_chasis
					DISPLAY r_ord.t23_color TO tit_color
				END IF
			END IF
			IF infield(t20_moneda) THEN
				CALL fl_ayuda_monedas()
					RETURNING mone_aux, nomm_aux, deci_aux
				LET int_flag = 0
				IF mone_aux IS NOT NULL THEN
					DISPLAY mone_aux TO t20_moneda 
					DISPLAY deci_aux TO t20_precision 
					DISPLAY nomm_aux TO tit_mon_bas
				END IF 
			END IF
	END CONSTRUCT
	IF int_flag THEN
		IF vm_row_current > 0 THEN
			CALL mostrar_registro(vm_r_rows[vm_row_current])
		ELSE
			CLEAR FORM
		END IF
		RETURN
	END IF
	LET query = 'SELECT *, ROWID FROM talt020 WHERE t20_compania = ' ||
			vg_codcia || ' AND t20_localidad = ' ||
			vg_codloc || ' AND ' || expr_sql CLIPPED ||
			' ORDER BY 3,5'
ELSE
	LET query = 'SELECT *, ROWID FROM talt020 WHERE t20_compania = ' ||
			vg_codcia || ' AND t20_localidad = ' ||
			vg_codloc || ' AND t20_numpre = ' || vm_numpre || 
			' ORDER BY 3,5'
END IF
PREPARE cons FROM query	
DECLARE q_cons CURSOR FOR cons
LET vm_num_rows = 0
FOREACH q_cons INTO rm_tal.*, num_reg
	LET vm_num_rows = vm_num_rows + 1
        IF vm_num_rows > vm_max_rows THEN
		LET vm_num_rows = vm_num_rows - 1
                EXIT FOREACH
        END IF
	LET vm_r_rows[vm_num_rows] = num_reg
END FOREACH
IF vm_num_rows = 0 THEN
	LET int_flag = 0
	CALL fl_mensaje_consulta_sin_registros()
	CLEAR FORM
	LET vm_row_current = 0
ELSE  
	LET vm_row_current = 1
	CALL mostrar_registro(vm_r_rows[vm_row_current])
END IF
CALL muestra_contadores(vm_row_current, vm_num_rows)

END FUNCTION



FUNCTION leer_datos(flag_mant)
DEFINE flag_mant	CHAR(1)
DEFINE resp		CHAR(6)
DEFINE resul		SMALLINT
DEFINE r_ord		RECORD LIKE talt023.*
DEFINE r_mon		RECORD LIKE gent013.*
DEFINE codo_aux		LIKE talt023.t23_orden
DEFINE nomo_aux		LIKE cxct001.z01_nomcli
DEFINE mone_aux		LIKE gent013.g13_moneda
DEFINE nomm_aux		LIKE gent013.g13_nombre
DEFINE deci_aux		LIKE gent013.g13_decimales

LET int_flag = 0
LET resul    = 0
INITIALIZE r_ord.* TO NULL
INITIALIZE r_mon.* TO NULL
INITIALIZE mone_aux TO NULL
DISPLAY BY NAME rm_tal.t20_recargo_mo, rm_tal.t20_recargo_rp,
		rm_tal.t20_precision, rm_tal.t20_total_mo, rm_tal.t20_total_rp,
		rm_tal.t20_user_aprob, rm_tal.t20_fecha_aprob,
		rm_tal.t20_usuario, rm_tal.t20_fecing
INPUT BY NAME rm_tal.t20_orden, rm_tal.t20_motivo, rm_tal.t20_recargo_mo,
	rm_tal.t20_recargo_rp, rm_tal.t20_moneda
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
        	IF field_touched(rm_tal.t20_orden,rm_tal.t20_motivo,
			rm_tal.t20_recargo_mo,rm_tal.t20_recargo_rp,
			rm_tal.t20_moneda)
        	THEN
			LET int_flag = 0
			CALL fl_mensaje_abandonar_proceso()
        	        	RETURNING resp
              		IF resp = 'Yes' THEN
				LET int_flag = 1
                	       	CLEAR FORM
                       		RETURN
	                END IF
		ELSE
               	       	CLEAR FORM
			RETURN
		END IF
	ON KEY(F2)
		IF infield(t20_orden) THEN
			CALL fl_ayuda_orden_trabajo(vg_codcia,vg_codloc,'A')
				RETURNING codo_aux, nomo_aux
			LET int_flag = 0
			IF codo_aux IS NOT NULL THEN
				CALL fl_lee_orden_trabajo(vg_codcia,vg_codloc,
								codo_aux)
					RETURNING r_ord.*
				LET rm_tal.t20_orden = codo_aux
				DISPLAY BY NAME rm_tal.t20_orden
				DISPLAY r_ord.t23_nom_cliente TO tit_nomcli
				DISPLAY r_ord.t23_modelo TO tit_modelo
				DISPLAY r_ord.t23_chasis TO tit_chasis
				DISPLAY r_ord.t23_color TO tit_color
			END IF
		END IF
		IF infield(t20_moneda) THEN
			CALL fl_ayuda_monedas()
				RETURNING mone_aux, nomm_aux, deci_aux
			LET int_flag = 0
			IF mone_aux IS NOT NULL THEN
				LET rm_tal.t20_moneda    = mone_aux
				LET rm_tal.t20_precision = deci_aux
				DISPLAY BY NAME rm_tal.t20_moneda,
						rm_tal.t20_precision 
				DISPLAY nomm_aux TO tit_mon_bas
			END IF 
		END IF
	BEFORE FIELD t20_orden
		IF rm_tal.t20_orden IS NOT NULL AND resul <> 1 THEN
			LET vm_orden = rm_tal.t20_orden
		END IF
	AFTER FIELD t20_orden
		IF rm_tal.t20_orden IS NOT NULL THEN
			CALL validar_clave() RETURNING resul
			IF resul = 1 THEN
				NEXT FIELD t20_orden
			END IF
		ELSE
			CLEAR tit_nomcli, tit_modelo, tit_chasis, tit_color
		END IF
	AFTER FIELD t20_motivo
		IF rm_tal.t20_orden IS NULL THEN
			NEXT FIELD t20_orden
		END IF
	AFTER FIELD t20_moneda 
		IF rm_tal.t20_orden IS NULL THEN
			NEXT FIELD t20_orden
		END IF
		IF rm_tal.t20_moneda IS NOT NULL THEN
			CALL fl_lee_moneda(rm_tal.t20_moneda)
				RETURNING r_mon.* 
			IF r_mon.g13_moneda IS NULL  THEN
				CALL fgl_winmessage(vg_producto,'Moneda no existe','exclamation')
				NEXT FIELD t20_moneda
			END IF
			LET rm_tal.t20_precision = r_mon.g13_decimales
			DISPLAY BY NAME	rm_tal.t20_precision 
			DISPLAY r_mon.g13_nombre TO tit_mon_bas
			IF r_mon.g13_estado = 'B' THEN
                                CALL fl_mensaje_estado_bloqueado()
				NEXT FIELD t20_moneda
			END IF
		ELSE
			LET rm_tal.t20_moneda = rg_gen.g00_moneda_base
			DISPLAY BY NAME rm_tal.t20_moneda
			CALL fl_lee_moneda(rm_tal.t20_moneda) RETURNING r_mon.* 
			DISPLAY r_mon.g13_nombre TO tit_mon_bas
		END IF
	AFTER INPUT
		CALL validar_clave() RETURNING resul
		IF resul = 1 THEN
			NEXT FIELD t20_orden
		END IF
END INPUT

END FUNCTION



FUNCTION ver_orden()
                                                                                
IF rm_tal.t20_orden IS NULL THEN
        CALL fl_mensaje_consultar_primero()
        RETURN
END IF
LET vm_nuevoprog = 'cd ..', vg_separador, '..', vg_separador, 'TALLER',
	vg_separador, 'fuentes', vg_separador, '; fglrun talp204 ', vg_base,
	' ', vg_modulo, ' ', vg_codcia, ' ', vg_codloc, ' ', rm_tal.t20_orden,
	' ', 'O'
RUN vm_nuevoprog
                                                                                
END FUNCTION



FUNCTION validar_clave()
DEFINE r_ord		RECORD LIKE talt023.*

INITIALIZE r_ord.* TO NULL
CALL fl_lee_orden_trabajo(vg_codcia,vg_codloc,rm_tal.t20_orden)
	RETURNING r_ord.*
IF r_ord.t23_compania IS NULL THEN
	CALL fgl_winmessage(vg_producto,'No existe esa orden de trabajo','exclamation')
	RETURN 1
END IF
DISPLAY r_ord.t23_nom_cliente TO tit_nomcli
DISPLAY r_ord.t23_modelo TO tit_modelo
DISPLAY r_ord.t23_chasis TO tit_chasis
DISPLAY r_ord.t23_color TO tit_color
IF vm_orden <> r_ord.t23_orden THEN
	IF r_ord.t23_numpre IS NOT NULL THEN
		CALL fgl_winmessage(vg_producto,'Esta orden de trabajo ha sido asignada a otro presupuesto','exclamation')
		RETURN 1
	END IF
	IF r_ord.t23_estado <> 'A' THEN
		CALL fgl_winmessage(vg_producto,'Orden de trabajo no esta ACTIVA','exclamation')
		RETURN 1
	END IF
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
DISPLAY row_current, " de ", num_rows AT 1, 68
                                                                                
END FUNCTION



FUNCTION mostrar_registro(num_registro)
DEFINE r_ord		RECORD LIKE talt023.*
DEFINE r_mon		RECORD LIKE gent013.*
DEFINE num_registro	INTEGER

IF vm_num_rows > 0 THEN
	SELECT * INTO rm_tal.* FROM talt020 WHERE ROWID = num_registro	
	IF STATUS = NOTFOUND THEN
		CALL fgl_winmessage (vg_producto,'No existe registro con índice: ' || vm_row_current,'exclamation')
		RETURN
	END IF
	DISPLAY BY NAME rm_tal.t20_numpre, rm_tal.t20_orden, rm_tal.t20_motivo,
			rm_tal.t20_recargo_mo, rm_tal.t20_recargo_rp,
			rm_tal.t20_moneda, rm_tal.t20_precision,
			rm_tal.t20_total_mo, rm_tal.t20_total_rp,
			rm_tal.t20_user_aprob, rm_tal.t20_fecha_aprob,
			rm_tal.t20_usuario, rm_tal.t20_fecing
	CALL fl_lee_orden_trabajo(vg_codcia,vg_codloc,rm_tal.t20_orden)
		RETURNING r_ord.*
	DISPLAY r_ord.t23_nom_cliente TO tit_nomcli
	DISPLAY r_ord.t23_modelo TO tit_modelo
	DISPLAY r_ord.t23_chasis TO tit_chasis
	DISPLAY r_ord.t23_color TO tit_color
	CALL fl_lee_moneda(rm_tal.t20_moneda) RETURNING r_mon.* 
	DISPLAY r_mon.g13_nombre TO tit_mon_bas
	CALL muestra_estado()
ELSE
	RETURN
END IF

END FUNCTION



FUNCTION aprobacion()
DEFINE confir	CHAR(6)

IF vm_num_rows = 0 THEN
	CALL fl_mensaje_consultar_primero()
	RETURN
END IF
LET int_flag = 0
WHENEVER ERROR CONTINUE
BEGIN WORK
DECLARE q_ba CURSOR FOR SELECT * FROM talt020
	WHERE ROWID = vm_r_rows[vm_row_current]
	FOR UPDATE
OPEN q_ba
FETCH q_ba INTO rm_tal.*
IF STATUS < 0 THEN
	COMMIT WORK
	CALL fl_mensaje_bloqueo_otro_usuario()
	WHENEVER ERROR STOP
	RETURN
END IF
IF rm_tal.t20_estado = 'A' THEN
	IF rm_tal.t20_total_mo = 0 AND rm_tal.t20_total_rp = 0 THEN
		COMMIT WORK
		CALL fgl_winmessage(vg_producto,'Presupuesto no tiene totales','exclamation')
		WHENEVER ERROR STOP
		RETURN
	END IF
END IF
CALL fl_mensaje_seguro_ejecutar_proceso()
RETURNING confir
IF confir = 'Yes' THEN
	LET int_flag = 1
	CALL aprueba_registro()
END IF
COMMIT WORK
WHENEVER ERROR STOP

END FUNCTION



FUNCTION aprueba_registro()
DEFINE estado	CHAR(1)

IF rm_tal.t20_estado = 'A' THEN
	DISPLAY 'APROBADO' TO tit_estado_tal
	LET estado = 'P'
ELSE 
	DISPLAY 'ACTIVO' TO tit_estado_tal
	LET estado = 'A'
END IF
DISPLAY estado TO tit_est
UPDATE talt020 SET t20_estado = estado WHERE CURRENT OF q_ba
LET rm_tal.t20_estado = estado

END FUNCTION



FUNCTION muestra_estado()

IF rm_tal.t20_estado = 'A' THEN
	DISPLAY 'ACTIVO' TO tit_estado_tal
ELSE
	DISPLAY 'APROBADO' TO tit_estado_tal
END IF
DISPLAY rm_tal.t20_estado TO tit_est

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
