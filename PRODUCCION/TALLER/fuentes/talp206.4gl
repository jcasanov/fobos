------------------------------------------------------------------------------
-- Titulo           : talp206.4gl - Cierre de ordenes de trabajo 
-- Elaboracion      : 19-oct-2001
-- Autor            : NPC
-- Formato Ejecucion: fglrun talp206 base m�dulo compa��a localidad
-- Ultima Correccion: 
-- Motivo Correccion: 
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_nuevoprog     VARCHAR(400)
DEFINE rm_ord		RECORD LIKE talt023.*
DEFINE vm_num_rows	SMALLINT
DEFINE vm_row_current	SMALLINT
DEFINE vm_max_rows	SMALLINT
DEFINE vm_r_rows	ARRAY [100] OF INTEGER

DEFINE vm_transaccion	LIKE veht030.v30_cod_tran
DEFINE vm_num_tran	LIKE veht030.v30_num_tran


MAIN

DEFER QUIT 
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/talp206.error')
CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 THEN          -- Validar # par�metros correcto
	CALL fgl_winmessage(vg_producto, 'N�mero de par�metros incorrecto', 'stop')
	EXIT PROGRAM
END IF
LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_codcia   = arg_val(3)
LET vg_codloc   = arg_val(4)
LET vg_proceso = 'talp206'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL control_master()

END MAIN



FUNCTION control_master()

CALL fl_nivel_isolation()
LET vm_max_rows = 100
OPEN WINDOW wf AT 3,2 WITH 14 ROWS, 80 COLUMNS
    ATTRIBUTE(FORM LINE FIRST + 2, COMMENT LINE LAST, MENU LINE FIRST,BORDER,
	      MESSAGE LINE LAST - 2)
OPTIONS INPUT NO WRAP,
	ACCEPT KEY	F12
OPEN FORM f_ord FROM "../forms/talf206_1"
DISPLAY FORM f_ord
LET vm_num_rows = 0
LET vm_row_current = 0
LET vm_transaccion = 'AC'
CALL muestra_contadores(vm_row_current, vm_num_rows)
MENU 'OPCIONES'
	BEFORE MENU
		HIDE OPTION 'Avanzar'
		HIDE OPTION 'Retroceder'
		HIDE OPTION 'Ver Orden'
		HIDE OPTION 'Cerrar Orden'
	COMMAND KEY('C') 'Consultar' 'Consultar un registro. '
		CALL control_consulta()
		IF vm_num_rows <= 1 THEN
			SHOW OPTION 'Ver Orden'
			SHOW OPTION 'Cerrar Orden'
			HIDE OPTION 'Avanzar'
			HIDE OPTION 'Retroceder'
			IF vm_num_rows = 0 THEN
				HIDE OPTION 'Ver Orden'
				HIDE OPTION 'Cerrar Orden'
			END IF
		ELSE
			SHOW OPTION 'Ver Orden'
			SHOW OPTION 'Cerrar Orden'
			SHOW OPTION 'Avanzar'
		END IF
		IF vm_row_current <= 1 THEN
                        HIDE OPTION 'Retroceder'
                END IF
	COMMAND KEY('E') 'Cerrar Orden' 'Cierra una orden de trabajo. '
		CALL cerrar_orden()
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

IF rm_ord.t23_orden IS NULL THEN
	CALL fl_mensaje_consultar_primero()
	RETURN
END IF
LET vm_nuevoprog = 'cd ..', vg_separador, '..', vg_separador, 'TALLER',
	vg_separador, 'fuentes', vg_separador, '; fglrun talp204 ', vg_base,
	' ', vg_modulo, ' ', vg_codcia, ' ', vg_codloc, ' ', rm_ord.t23_orden,
	' ', 'O'
RUN vm_nuevoprog

END FUNCTION



FUNCTION cerrar_orden()
DEFINE estado		CHAR(10)
DEFINE resp		CHAR(6)
DEFINE saldo_venc	SMALLINT
DEFINE r_veh		RECORD LIKE veht038.*
DEFINE r_tip		RECORD LIKE talt005.*
DEFINE areaneg		LIKE gent020.g20_areaneg
DEFINE valor		LIKE cajt010.j10_valor
DEFINE num_oc		SMALLINT
DEFINE r_cli		RECORD LIKE cxct002.*
DEFINE lin_com		VARCHAR(200)
DEFINE esta		CHAR(1)
DEFINE fecha_vcto	DATE

INITIALIZE vm_num_tran TO NULL

IF rm_ord.t23_orden IS NULL THEN
	CALL fl_mensaje_consultar_primero()
	RETURN
END IF
CALL muestra_cabecera(rm_ord.t23_orden)
SELECT COUNT(*) INTO num_oc FROM ordt010
	WHERE c10_compania    = vg_codcia AND 
	      c10_localidad   = vg_codloc AND 
	      c10_ord_trabajo = rm_ord.t23_orden AND 
	      c10_estado NOT IN ('C','E')
IF num_oc > 0 THEN
        CALL fgl_winmessage(vg_producto,'Existen �rdenes de compras que no ' ||
					'se han cerrado.', 'stop')
	RETURN
END IF	
CALL fl_lee_tipo_orden_taller(vg_codcia,rm_ord.t23_tipo_ot)
	RETURNING r_tip.*
IF r_tip.t05_factura = 'S' THEN
	CALL fl_control_status_caja(vg_codcia, vg_codloc, 'O') RETURNING int_flag
	IF int_flag <> 0 THEN
		RETURN
	END IF	
END IF	
CALL fl_recalcula_valores_ot(vg_codcia, vg_codloc, rm_ord.t23_orden)
WHENEVER ERROR CONTINUE
BEGIN WORK
DECLARE q_up CURSOR FOR SELECT * FROM talt023
        WHERE t23_compania = vg_codcia
        AND t23_localidad  = vg_codloc
        AND t23_orden      = rm_ord.t23_orden
        FOR UPDATE
OPEN q_up
FETCH q_up INTO rm_ord.*
IF STATUS < 0 THEN
        ROLLBACK WORK
        CALL fl_mensaje_bloqueo_otro_usuario()
        WHENEVER ERROR STOP
        RETURN
END IF

INITIALIZE r_veh.* TO NULL
IF rm_ord.t23_orden_cheq IS NOT NULL THEN
	DECLARE q_up2 CURSOR FOR 
		SELECT * FROM veht038 
			WHERE v38_compania   = vg_codcia
        		  AND v38_localidad  = vg_codloc
        		  AND v38_orden_cheq = rm_ord.t23_orden_cheq 
			  AND v38_estado     = 'A' 
        FOR UPDATE
	OPEN q_up2
	FETCH q_up2 INTO r_veh.*
	IF STATUS < 0 THEN
        	ROLLBACK WORK
        	CALL fl_mensaje_bloqueo_otro_usuario()
        	WHENEVER ERROR STOP
        	RETURN
	END IF
END IF
WHENEVER ERROR STOP

IF rm_ord.t23_cod_cliente IS NULL THEN
	LET int_flag = 0
	CALL fgl_winquestion(vg_producto,'Esta orden no tiene el c�digo del cliente. Desea ingresarlo ?','No','Yes|No|Cancel','question',1)
		RETURNING resp
        WHENEVER ERROR STOP
	IF resp = 'Yes' THEN
        	LET int_flag = 1
		ROLLBACK WORK
		LET vm_nuevoprog = 'cd ..', vg_separador, '..', vg_separador,
			'TALLER', vg_separador, 'fuentes', vg_separador,
			'; fglrun talp204 ', vg_base, ' ', vg_modulo,
			' ', vg_codcia, ' ', vg_codloc
		RUN vm_nuevoprog
        END IF
	COMMIT WORK
	RETURN
END IF
IF rm_ord.t23_estado = 'A' AND rm_ord.t23_tot_neto > 0 THEN
	LET int_flag = 0
	UPDATE talt023 SET t23_estado = 'C', t23_fec_cierre = CURRENT
		WHERE CURRENT OF q_up

	-- Estoy cambiando el estado de la veht038 a P de Procesado cuando
	-- cierro la orden
	IF r_veh.v38_compania IS NOT NULL THEN
		UPDATE veht038 SET v38_estado = 'P' WHERE CURRENT OF q_up2
	END IF
	CALL ajuste_costo_vehiculo(r_veh.*)
	IF int_flag THEN
		LET int_flag = 0
		ROLLBACK WORK
		RETURN
	END IF
        ---------------------------------------------------------------------

	IF r_tip.t05_factura = 'S' THEN
		CALL validar_saldo_vencido_cliente() RETURNING saldo_venc
		IF NOT saldo_venc THEN
			CALL fl_lee_cliente_localidad(vg_codcia, vg_codloc, 
						      rm_ord.t23_cod_cliente)
				RETURNING r_cli.*
			IF r_cli.z02_credit_auto = 'S' THEN
				CALL fgl_winquestion(vg_producto,
				'El cliente ' || rm_ord.t23_nom_cliente || 
				' tiene cr�dito autom�tico, por lo tanto' ||
			        ' se va a generar una factura. ' ||
				' Desea continuar ?',
 				'Yes','Yes|No|Cancel','question',1)
				RETURNING resp
				IF resp <> 'Yes' THEN
					ROLLBACK WORK
					RETURN
				END IF
			END IF	
			CALL sacar_areaneg() RETURNING areaneg
			IF rm_ord.t23_cont_cred = 'C' THEN
				LET valor = rm_ord.t23_tot_neto
			ELSE
				LET valor = 0
			END IF
			DELETE FROM cajt010 WHERE j10_compania = vg_codcia
        	       	    	    AND j10_localidad  = vg_codloc
                	       	    AND j10_tipo_fuente= 'OT'
                            	    AND j10_num_fuente = rm_ord.t23_orden
			LET esta = 'A' 
			IF r_cli.z02_credit_auto = 'S' THEN
				LET esta = '*' 
			END IF
			INSERT INTO cajt010 VALUES(vg_codcia,vg_codloc,'OT',
				rm_ord.t23_orden,areaneg, esta,
				rm_ord.t23_cod_cliente,rm_ord.t23_nom_cliente,
				rm_ord.t23_moneda,valor,CURRENT,NULL,NULL,NULL,
				NULL,NULL,NULL,NULL,NULL,vg_usuario,CURRENT)
			IF r_cli.z02_credit_auto = 'S' THEN
				LET fecha_vcto = TODAY + r_cli.z02_credit_dias
				UPDATE talt023 SET t23_cont_cred = 'R'
					WHERE CURRENT OF q_up
				INSERT INTO talt025 VALUES (vg_codcia,vg_codloc,
					rm_ord.t23_orden, 0,rm_ord.t23_tot_neto,
					0, 1, r_cli.z02_credit_dias)
				INSERT INTO talt026 VALUES (vg_codcia,vg_codloc,
					rm_ord.t23_orden, 1,rm_ord.t23_tot_neto,
					0, fecha_vcto) 
				COMMIT WORK
				LET lin_com = 'cd ..', vg_separador, '..', 
					       vg_separador,
	      		      	              'TALLER', vg_separador, 'fuentes',
			      	               vg_separador, 
					      '; fglrun talp210 ', vg_base, ' ',
			      		       vg_codcia, ' ', vg_codloc, ' ', 
			                       rm_ord.t23_orden
				RUN lin_com	
				CALL muestra_cabecera(rm_ord.t23_orden)
				RETURN
			END IF	
		END IF
	END IF

	COMMIT WORK
        CALL fgl_winmessage(vg_producto,'Orden ha sido CERRADA Ok.','exclamation')
	CALL muestra_cabecera(rm_ord.t23_orden)
ELSE
	COMMIT WORK
	IF rm_ord.t23_estado <> 'A' THEN
		CALL retorna_estado(rm_ord.t23_estado) RETURNING estado
       		IF rm_ord.t23_estado = 'C' THEN
               		CALL fgl_winmessage(vg_producto,'Esta orden ya ha sido ' || estado,'exclamation')
       	 	ELSE
               	      	CALL fgl_winmessage(vg_producto,'Esta orden no est� ACTIVA, sino ' || estado,'exclamation')
        		END IF
	ELSE
              	CALL fgl_winmessage(vg_producto,'Esta orden no puede cerrarse porque tiene total de cero','exclamation')
       	END IF
END IF
WHENEVER ERROR STOP

IF vm_num_tran IS NOT NULL THEN
	CALL fl_control_master_contab_vehiculos(vg_codcia, vg_codloc, 
						vm_transaccion,
						vm_num_tran)
END IF

END FUNCTION



FUNCTION sacar_areaneg()
DEFINE r_mol            RECORD LIKE talt004.*
DEFINE r_lin            RECORD LIKE talt001.*
DEFINE r_grp            RECORD LIKE gent020.*
DEFINE r_are            RECORD LIKE gent003.*

CALL fl_lee_tipo_vehiculo(vg_codcia,rm_ord.t23_modelo) RETURNING r_mol.*
CALL fl_lee_linea_taller(vg_codcia,r_mol.t04_linea) RETURNING r_lin.*
CALL fl_lee_grupo_linea(vg_codcia,r_lin.t01_grupo_linea) RETURNING r_grp.*
IF r_grp.g20_compania IS NULL THEN
        CALL fgl_winmessage(vg_producto,'No hay l�nea de venta en Taller','stop'
)
        EXIT PROGRAM
END IF
CALL fl_lee_area_negocio(vg_codcia, r_grp.g20_areaneg) RETURNING r_are.*
IF r_are.g03_modulo <> vg_modulo THEN
	CALL fgl_winmessage(vg_producto,'El �rea de negocio del grupo de l�nea no pertenece a Taller.','stop')
	EXIT PROGRAM
END IF
RETURN r_grp.g20_areaneg

END FUNCTION



FUNCTION control_consulta()
DEFINE orden		LIKE talt023.t23_orden
DEFINE nomcli		LIKE talt023.t23_nom_cliente
DEFINE query		VARCHAR(400)
DEFINE expr_sql		VARCHAR(400)
DEFINE estado		CHAR(10)

CLEAR FORM
INITIALIZE orden TO NULL
LET rm_ord.t23_estado = 'A'
LET int_flag = 0
CONSTRUCT BY NAME expr_sql ON t23_orden
	ON KEY(F2)
		IF infield(t23_orden) THEN
                        CALL fl_ayuda_orden_trabajo(vg_codcia,vg_codloc,'A')
                                RETURNING orden, nomcli
                        LET int_flag = 0
                        IF orden IS NOT NULL THEN
                                DISPLAY orden TO t23_orden
				CALL muestra_cabecera(orden)
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
       	CALL fgl_winmessage(vg_producto,'No hay �rdenes ACTIVAS o criterio de b�squeda no v�lido','exclamation')
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
	WHEN 'A' LET est = 'ACTIVA'
	WHEN 'C' LET est = 'CERRADA'
	WHEN 'F' LET est = 'FACTURADA'
	WHEN 'E' LET est = 'ELIMINADA'
	WHEN 'D' LET est = 'DEVUELTA'
END CASE
RETURN est

END FUNCTION



FUNCTION ajuste_costo_vehiculo(r_v38)

DEFINE r_v00		RECORD LIKE veht000.*
DEFINE r_v22		RECORD LIKE veht022.*
DEFINE r_v30		RECORD LIKE veht030.*
DEFINE r_v31		RECORD LIKE veht031.*
DEFINE r_v38		RECORD LIKE veht038.*
DEFINE r_z01		RECORD LIKE cxct001.*


IF r_v38.v38_compania IS NULL THEN
	RETURN
END IF 

CALL fl_lee_compania_vehiculos(r_v38.v38_compania) RETURNING r_v00.*
IF r_v00.v00_compania IS NULL THEN
	CALL fgl_winmessage(vg_producto, 
			    'No existe configuracion de veh�culos.',
			    'stop')
	LET int_flag = 1
	RETURN	
END IF

IF r_v00.v00_gen_aju_op = 'S' THEN

	SET LOCK MODE TO WAIT 5
	WHENEVER ERROR CONTINUE
		DECLARE q_v22 CURSOR FOR
			SELECT * FROM veht022 
				WHERE v22_compania   = r_v38.v38_compania
				  AND v22_localidad  = r_v38.v38_localidad
				  AND v22_codigo_veh = r_v38.v38_codigo_veh
		FOR UPDATE
	WHENEVER ERROR STOP
	OPEN  q_v22
	FETCH q_v22 INTO r_v22.*
	IF STATUS < 0 THEN
		SET LOCK MODE TO NOT WAIT
		CALL fl_mensaje_bloqueo_otro_usuario()
		LET int_flag = 1
		RETURN	
	END IF
	SET LOCK MODE TO NOT WAIT

	INITIALIZE r_v30.* TO NULL
	INITIALIZE r_v31.* TO NULL
------------------------

	LET r_v30.v30_fecing     = CURRENT
	LET r_v30.v30_usuario    = vg_usuario
	LET r_v30.v30_compania   = vg_codcia
	LET r_v30.v30_localidad  = vg_codloc
	LET r_v30.v30_cod_tran   = vm_transaccion

	LET r_v30.v30_cont_cred  = rm_ord.t23_cont_cred
	LET r_v30.v30_referencia = 'Orden de chequeo # ' || r_v38.v38_orden_cheq
	LET r_v30.v30_codcli     = rm_ord.t23_cod_cliente
	LET r_v30.v30_nomcli     = rm_ord.t23_nom_cliente

	CALL fl_lee_cliente_general(r_v30.v30_codcli) RETURNING r_z01.*

	LET r_v30.v30_dircli     = r_z01.z01_direccion1
	LET r_v30.v30_cedruc     = r_z01.z01_num_doc_id

	SELECT MIN(v01_vendedor) INTO r_v30.v30_vendedor
        FROM veht001 WHERE v01_compania = vg_codcia

	LET r_v30.v30_descuento  = 0.0
	LET r_v30.v30_porc_impto = 0.0
	
	LET r_v30.v30_moneda     = rm_ord.t23_moneda
	LET r_v30.v30_paridad    = rm_ord.t23_paridad
	LET r_v30.v30_precision  = rm_ord.t23_precision
	LET r_v30.v30_tot_bruto  = 0.0
	LET r_v30.v30_tot_dscto  = 0.0                             
	LET r_v30.v30_flete      = 0.0
	LET r_v30.v30_bodega_ori = r_v22.v22_bodega
	LET r_v30.v30_bodega_dest = r_v30.v30_bodega_ori

	LET r_v31.v31_compania    = vg_codcia
	LET r_v31.v31_localidad   = vg_codloc
	LET r_v31.v31_cod_tran    = vm_transaccion
	LET r_v31.v31_descuento  = 0.0
	LET r_v31.v31_val_descto = 0.0
	LET r_v31.v31_precio     = 0.0
	LET r_v31.v31_costo      = 0.0
	LET r_v31.v31_fob        = 0.0
	LET r_v31.v31_costant_ma = 0.0
	LET r_v31.v31_costnue_ma = 0.0

	LET r_v31.v31_costant_mb = (r_v22.v22_costo_ing +
				    r_v22.v22_cargo_ing +
				    r_v22.v22_costo_adi)

	LET r_v31.v31_costnue_mb = rm_ord.t23_tot_neto + 
				   r_v31.v31_costant_mb

	-- TOTAL DE LA TRANSACCION --
	LET r_v30.v30_tot_costo = r_v31.v31_costnue_mb
	LET r_v30.v30_tot_neto  = r_v31.v31_costnue_mb
	LET r_v31.v31_costo     = r_v31.v31_costant_mb

	LET r_v30.v30_num_tran = nextValInSequence()
	IF r_v30.v30_num_tran = -1 THEN
		CALL fgl_winmessage(vg_producto,
			'No se pudo generar el ajuste de costo al veh�culo.',
			'exclamation')
		LET int_flag = 1
	        RETURN
	END IF

	LET vm_num_tran = r_v30.v30_num_tran
	INSERT INTO veht030 VALUES (r_v30.*)

	LET r_v31.v31_moneda_cost = r_v22.v22_moneda_liq
	LET r_v31.v31_codigo_veh = r_v22.v22_codigo_veh
	LET r_v31.v31_nuevo = r_v22.v22_nuevo
	LET r_v31.v31_num_tran = r_v30.v30_num_tran
	INSERT INTO veht031 VALUES (r_v31.*)                         

	UPDATE veht022 SET v22_costo_adi = v22_costo_adi + rm_ord.t23_tot_neto,
			   v22_estado = 'A'
		WHERE CURRENT OF q_v22 	
END IF

END FUNCTION



FUNCTION nextValInSequence()

DEFINE resp             CHAR(6)
DEFINE retVal           INTEGER

LET retVal = -1
WHILE retVal = -1

LET retVal = fl_actualiza_control_secuencias(vg_codcia, vg_codloc, 'VE',     
                                         'AA', vm_transaccion)
IF retVal = 0 THEN
        EXIT PROGRAM
END IF
IF retVal <> -1 THEN
         EXIT WHILE
END IF

CALL fgl_winquestion(vg_producto, 'La tabla de secuencias de transacciones ' ||
                     'est� siendo accesada por otro usuario, espere unos  ' ||
                     'segundos y vuelva a intentar', 'No', 'Yes|No|Cancel',
                     'question', 1) RETURNING resp
IF resp <> 'Yes' THEN
        EXIT WHILE                  
END IF

END WHILE

RETURN retVal

END FUNCTION
                  


FUNCTION validar_saldo_vencido_cliente()
DEFINE r_cxc		RECORD LIKE cxct000.*
DEFINE r_mon		RECORD LIKE gent013.*
DEFINE saldo_venc       LIKE cxct030.z30_saldo_venc
DEFINE moneda		LIKE gent013.g13_moneda

CALL fl_retorna_saldo_vencido(vg_codcia,rm_ord.t23_cod_cliente)
	RETURNING moneda, saldo_venc
IF saldo_venc > 0 THEN
	CALL fl_lee_moneda(moneda) RETURNING r_mon.*
	CALL fgl_winmessage(vg_producto,'El cliente tiene un saldo vencido de ' || saldo_venc || ' en la moneda ' || r_mon.g13_nombre || '.','info')
	CALL fl_lee_compania_cobranzas(vg_codcia) RETURNING r_cxc.*
	IF r_cxc.z00_compania IS NULL THEN
		CALL fgl_winmessage(vg_producto,'No existe un registro de configuraci�n para la compa��a en cobranzas.','stop')
		EXIT PROGRAM
	END IF
	{IF r_cxc.z00_bloq_vencido = 'S' THEN
		RETURN 1
	END IF}
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
DEFINE num_registro	INTEGER

IF vm_num_rows > 0 THEN
	DECLARE q_dt CURSOR FOR SELECT * FROM talt023 WHERE rowid = num_registro
        OPEN q_dt
        FETCH q_dt INTO rm_ord.*
	IF STATUS = NOTFOUND THEN
		CALL fgl_winmessage (vg_producto,'No existe registro con �ndice: ' || vm_row_current,'exclamation')
		RETURN
	END IF
	DISPLAY BY NAME	rm_ord.t23_orden
	CALL muestra_cabecera(rm_ord.t23_orden)
ELSE
	RETURN
END IF

END FUNCTION



FUNCTION validar_parametros()

CALL fl_lee_modulo(vg_modulo) RETURNING rg_mod.*
IF rg_mod.g50_modulo IS NULL THEN
	CALL fgl_winmessage(vg_producto, 'No existe m�dulo: ' || vg_modulo, 'stop')
	EXIT PROGRAM
END IF
CALL fl_lee_compania(vg_codcia) RETURNING rg_cia.*
IF rg_cia.g01_compania IS NULL THEN
	CALL fgl_winmessage(vg_producto, 'No existe compa��a: '|| vg_codcia, 'stop')
	EXIT PROGRAM
END IF
IF rg_cia.g01_estado <> 'A' THEN
	CALL fgl_winmessage(vg_producto, 'Compa��a no est� activa: ' || vg_codcia, 'stop')
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
	CALL fgl_winmessage(vg_producto, 'Localidad no est� activa: '|| vg_codloc, 'stop')
	EXIT PROGRAM
END IF

END FUNCTION
