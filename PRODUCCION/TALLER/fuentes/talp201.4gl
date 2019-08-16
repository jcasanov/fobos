--------------------------------------------------------------------------------
-- Titulo           : talp201.4gl - Mantenimiento de Presupuestos 
-- Elaboracion      : 10-oct-2001
-- Autor            : NPC
-- Formato Ejecucion: fglrun talp201 base módulo compañía localidad [numpre]
-- Ultima Correccion: 
-- Motivo Correccion: 
--------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE rm_t20		RECORD LIKE talt020.*
DEFINE rm_t23		RECORD LIKE talt023.*
DEFINE rm_t00		RECORD LIKE talt000.*
DEFINE rm_r00		RECORD LIKE rept000.*
DEFINE vm_num_rows	SMALLINT
DEFINE vm_row_current	SMALLINT
DEFINE vm_max_rows	SMALLINT
DEFINE vm_r_rows	ARRAY [20000] OF INTEGER
DEFINE vm_orden		LIKE talt023.t23_orden
DEFINE vm_numpre	LIKE talt020.t20_numpre
DEFINE vm_bod_taller	LIKE rept002.r02_codigo
DEFINE total_bruto	LIKE talt020.t20_total_neto
DEFINE subtotal		LIKE talt020.t20_total_neto



MAIN

DEFER QUIT 
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/talp201.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
INITIALIZE vm_numpre TO NULL
IF num_args() <> 4 AND num_args() <> 5 AND num_args() <> 6 THEN
	-- Validar # parámetros correcto
	CALL fl_mostrar_mensaje('Número de parámetros incorrecto.','stop')
	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_codloc  = arg_val(4)
LET vm_numpre  = arg_val(5)
LET vg_proceso = 'talp201'
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
CALL fl_lee_configuracion_taller(vg_codcia) RETURNING rm_t00.*
IF rm_t00.t00_compania IS NULL THEN
	CALL fl_mostrar_mensaje('No existe configuración para esta compania.','stop')
	EXIT PROGRAM
END IF
IF num_args() = 4 THEN
	CALL fl_chequeo_mes_proceso_tal(vg_codcia) RETURNING int_flag
	IF int_flag THEN
		RETURN
	END IF
END IF
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
OPEN WINDOW w_talf201_1 AT row_ini, 2 WITH num_rows ROWS, num_cols COLUMNS
    ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE lin_menu,BORDER,
	      MESSAGE LINE LAST - 1)
IF vg_gui = 1 THEN
	OPEN FORM f_talf201_1 FROM "../forms/talf201_1"
ELSE
	OPEN FORM f_talf201_1 FROM "../forms/talf201_1c"
END IF
DISPLAY FORM f_talf201_1
INITIALIZE rm_t20.*, vm_orden TO NULL
CALL fl_lee_compania_repuestos(vg_codcia) RETURNING rm_r00.*		   
LET vm_max_rows	   = 20000
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
			HIDE OPTION 'Eliminar'
			HIDE OPTION 'Orden Trabajo'
			HIDE OPTION 'Proformas'
			HIDE OPTION 'Mano Obra'
			HIDE OPTION 'Conversión a OT'
			HIDE OPTION 'Imprimir'
			HIDE OPTION 'Archivo'
			HIDE OPTION 'PDF'
			HIDE OPTION 'Activacion'
		ELSE
			SHOW OPTION 'Modificar'
			IF rm_t20.t20_estado = 'A' THEN
				SHOW OPTION 'Eliminar'
			ELSE
				HIDE OPTION 'Eliminar'
			END IF
			IF rm_t20.t20_estado = 'E' THEN
				SHOW OPTION 'Activacion'
			ELSE
				HIDE OPTION 'Activacion'
			END IF
			SHOW OPTION 'Orden Trabajo'
			SHOW OPTION 'Proformas'
			SHOW OPTION 'Mano Obra'
			SHOW OPTION 'Imprimir'
			SHOW OPTION 'Archivo'
			SHOW OPTION 'PDF'
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
			IF rm_t20.t20_estado = 'A' THEN
				SHOW OPTION 'Eliminar'
			ELSE
				HIDE OPTION 'Eliminar'
			END IF
			IF rm_t20.t20_estado = 'E' THEN
				SHOW OPTION 'Activacion'
			ELSE
				HIDE OPTION 'Activacion'
			END IF
			HIDE OPTION 'Consultar'
			IF num_args() = 6 THEN
				HIDE OPTION 'Orden Trabajo'
			ELSE
				SHOW OPTION 'Orden Trabajo'
			END IF
			HIDE OPTION 'Conversión a OT'
			SHOW OPTION 'Proformas'
			SHOW OPTION 'Mano Obra'
			SHOW OPTION 'Imprimir'
			SHOW OPTION 'Archivo'
			SHOW OPTION 'PDF'
		END IF
	COMMAND KEY('I') 'Ingresar' 'Ingresar nuevos registros. '
		CALL control_ingreso()
		IF vm_num_rows = 1 THEN
			SHOW OPTION 'Modificar'
			IF vm_num_rows > 0 THEN
				IF rm_t20.t20_estado = 'A' THEN
					SHOW OPTION 'Eliminar'
				ELSE
					HIDE OPTION 'Eliminar'
				END IF
				IF rm_t20.t20_estado = 'E' THEN
					SHOW OPTION 'Activacion'
				ELSE
					HIDE OPTION 'Activacion'
				END IF
			END IF
			SHOW OPTION 'Conversión a OT'
			SHOW OPTION 'Imprimir'
			SHOW OPTION 'Archivo'
			SHOW OPTION 'PDF'
			SHOW OPTION 'Orden Trabajo'
			SHOW OPTION 'Proformas'
			SHOW OPTION 'Mano Obra'
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
			IF vm_num_rows > 0 THEN
				IF rm_t20.t20_estado = 'A' THEN
					SHOW OPTION 'Eliminar'
				ELSE
					HIDE OPTION 'Eliminar'
				END IF
				IF rm_t20.t20_estado = 'E' THEN
					SHOW OPTION 'Activacion'
				ELSE
					HIDE OPTION 'Activacion'
				END IF
			END IF
			SHOW OPTION 'Orden Trabajo'
			SHOW OPTION 'Proformas'
			SHOW OPTION 'Mano Obra'
			SHOW OPTION 'Conversión a OT'
			SHOW OPTION 'Imprimir'
			SHOW OPTION 'Archivo'
			SHOW OPTION 'PDF'
			HIDE OPTION 'Avanzar'
			HIDE OPTION 'Retroceder'
			IF vm_num_rows = 0 THEN
				HIDE OPTION 'Modificar'
				HIDE OPTION 'Conversión a OT'
				HIDE OPTION 'Imprimir'
				HIDE OPTION 'Archivo'
				HIDE OPTION 'PDF'
				HIDE OPTION 'Orden Trabajo'
				HIDE OPTION 'Proformas'
				HIDE OPTION 'Mano Obra'
			END IF
		ELSE
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Conversión a OT'
			SHOW OPTION 'Imprimir'
			SHOW OPTION 'Archivo'
			SHOW OPTION 'PDF'
			SHOW OPTION 'Modificar'
			IF rm_t20.t20_estado = 'A' THEN
				SHOW OPTION 'Eliminar'
			ELSE
				HIDE OPTION 'Eliminar'
			END IF
			IF rm_t20.t20_estado = 'E' THEN
				SHOW OPTION 'Activacion'
			ELSE
				HIDE OPTION 'Activacion'
			END IF
			SHOW OPTION 'Orden Trabajo'
			SHOW OPTION 'Proformas'
			SHOW OPTION 'Mano Obra'
		END IF
		IF vm_row_current <= 1 THEN
                        HIDE OPTION 'Retroceder'
                END IF
       	COMMAND KEY('E') 'Eliminar' 'Eliminar registro corriente. '
		CALL control_eliminacion()
		IF rm_t20.t20_estado = 'A' THEN
			SHOW OPTION 'Eliminar'
		ELSE
			HIDE OPTION 'Eliminar'
		END IF
		IF rm_t20.t20_estado = 'E' THEN
			SHOW OPTION 'Activacion'
		ELSE
			HIDE OPTION 'Activacion'
		END IF
     	COMMAND KEY('P') 'Conversión a OT' 'Convertir Presupuesto a OT. '
		CALL conversion_ot()
	COMMAND KEY('K') 'Imprimir'
		IF rm_t20.t20_numpre IS NOT NULL THEN 
			CALL control_imprimir_presupuesto(1)
		END IF
     	COMMAND KEY('V') 'Orden Trabajo' 'Ver orden del presupuesto. '
		CALL ver_orden()
     	COMMAND KEY('X') 'Proformas' 'Ver proformas del presupuesto. '
		CALL muestra_profromas_pr()
     	COMMAND KEY('O') 'Mano Obra' 'Ver Mano Obra del presupuesto. '
		CALL muestra_mano_obra_pr()
	COMMAND KEY('Z') 'Archivo'
		IF rm_t20.t20_numpre IS NOT NULL THEN 
			CALL control_imprimir_presupuesto(2)
		END IF
	COMMAND KEY('D') 'PDF'
		CALL generar_pdf()
	COMMAND KEY('Y') 'Activacion'
		CALL activacion_presupuesto()
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
		IF rm_t20.t20_estado = 'A' THEN
			SHOW OPTION 'Eliminar'
		ELSE
			HIDE OPTION 'Eliminar'
		END IF
		IF rm_t20.t20_estado = 'E' THEN
			SHOW OPTION 'Activacion'
		ELSE
			HIDE OPTION 'Activacion'
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
		IF rm_t20.t20_estado = 'A' THEN
			SHOW OPTION 'Eliminar'
		ELSE
			HIDE OPTION 'Eliminar'
		END IF
		IF rm_t20.t20_estado = 'E' THEN
			SHOW OPTION 'Activacion'
		ELSE
			HIDE OPTION 'Activacion'
		END IF
	COMMAND KEY('S') 'Salir' 'Salir del programa. '
		EXIT MENU
END MENU

END FUNCTION



FUNCTION control_ingreso()
DEFINE num_aux		INTEGER
DEFINE r_g13		RECORD LIKE gent013.*
DEFINE r_z01		RECORD LIKE cxct001.*
DEFINE r_t20		RECORD LIKE talt020.*

CALL fl_retorna_usuario()
INITIALIZE rm_t20.*, r_g13.* TO NULL
CLEAR t20_numpre, t23_orden, t20_user_aprob, t20_fecha_aprob, tit_estado_tal,
	tit_mon_bas
LET rm_t20.t20_compania    = vg_codcia
LET rm_t20.t20_localidad   = vg_codloc
LET rm_t20.t20_numpre      = 0
LET rm_t20.t20_recargo_mo  = 0
LET rm_t20.t20_recargo_rp  = 0
LET rm_t20.t20_total_mo    = 0
LET rm_t20.t20_total_rp    = 0
LET rm_t20.t20_mano_ext    = 0
LET rm_t20.t20_por_mo_tal  = 0
LET rm_t20.t20_vde_mo_tal  = 0
LET rm_t20.t20_total_impto = 0
LET rm_t20.t20_otros_mat   = 0
LET rm_t20.t20_gastos      = 0
LET rm_t20.t20_total_neto  = 0
LET rm_t20.t20_moneda      = rg_gen.g00_moneda_base
LET rm_t20.t20_usuario     = vg_usuario
LET rm_t20.t20_fecing      = CURRENT
LET rm_t20.t20_estado      = 'A'
CALL fl_lee_moneda(rm_t20.t20_moneda) RETURNING r_g13.*
IF r_g13.g13_moneda IS NULL THEN
	CALL fl_mostrar_mensaje('No existe ninguna moneda base.','stop')
	CLOSE WINDOW w_talf201_1
        EXIT PROGRAM
END IF
LET rm_t20.t20_precision = r_g13.g13_decimales
DISPLAY r_g13.g13_nombre TO tit_mon_bas
CALL muestra_estado()
CALL leer_datos('I')
IF NOT int_flag THEN
	BEGIN WORK
		WHILE TRUE
			SQL
				SELECT NVL(MAX(t20_numpre), 0) + 1
					INTO $rm_t20.t20_numpre
					FROM talt020
					WHERE t20_compania  = $vg_codcia
					  AND t20_localidad = $vg_codloc
			END SQL
			CALL fl_lee_presupuesto_taller(vg_codcia, vg_codloc,
							rm_t20.t20_numpre)
				RETURNING r_t20.*
			IF r_t20.t20_compania IS NULL THEN
				EXIT WHILE
			END IF
		END WHILE
		CALL calcular_total()
		CALL fl_lee_cliente_general(rm_t20.t20_cod_cliente)
			RETURNING r_z01.*
		LET rm_t20.t20_cedruc = r_z01.z01_num_doc_id
		IF rm_t20.t20_cedruc IS NULL THEN
			CALL fl_lee_cliente_general(rm_r00.r00_codcli_tal)
				RETURNING r_z01.*  
			LET rm_t20.t20_cedruc = r_z01.z01_num_doc_id
		END IF
		LET rm_t20.t20_fecing = CURRENT
		INSERT INTO talt020 VALUES (rm_t20.*)
		LET num_aux = SQLCA.SQLERRD[6] 
	COMMIT WORK
	IF vm_num_rows = vm_max_rows THEN
		LET vm_num_rows = 1
	ELSE
		LET vm_num_rows = vm_num_rows + 1
	END IF
	LET vm_row_current = vm_num_rows
	LET vm_r_rows[vm_row_current] = num_aux 
	DISPLAY BY NAME rm_t20.t20_numpre, rm_t20.t20_fecing
	CALL mostrar_registro(vm_r_rows[vm_num_rows])	
	CALL muestra_contadores(vm_row_current, vm_num_rows)
	CALL control_imprimir_presupuesto(1)
	CALL fl_mensaje_registro_ingresado()
	CLEAR FORM
	IF vm_row_current > 0 THEN
		CALL mostrar_registro(vm_r_rows[vm_row_current])
	END IF
END IF
IF vm_row_current > 0 THEN
	CALL mostrar_registro(vm_r_rows[vm_row_current])
END IF

END FUNCTION



FUNCTION control_modificacion()
DEFINE r_z01		RECORD LIKE cxct001.*
DEFINE porc		LIKE rept021.r21_porc_impto
DEFINE exec_up		CHAR(600)
	
IF vm_num_rows = 0 THEN
	CALL fl_mensaje_consultar_primero()
	RETURN
END IF
CALL mostrar_registro(vm_r_rows[vm_row_current])
IF rm_t20.t20_estado <> 'A' THEN
	CALL fl_mostrar_mensaje('Presupuesto no puede ser modificado.','exclamation')
	RETURN
END IF
BEGIN WORK
WHENEVER ERROR CONTINUE
DECLARE q_up CURSOR FOR
	SELECT * FROM talt020
		WHERE ROWID = vm_r_rows[vm_row_current]
	FOR UPDATE
OPEN q_up
FETCH q_up INTO rm_t20.*
IF STATUS < 0 THEN
	ROLLBACK WORK
	CALL fl_mensaje_bloqueo_otro_usuario()
	WHENEVER ERROR STOP
	RETURN
END IF
WHENEVER ERROR STOP
CALL leer_datos('M')
IF int_flag THEN
	ROLLBACK WORK
	CLEAR FORM
	IF vm_row_current > 0 THEN
		CALL mostrar_registro(vm_r_rows[vm_row_current])
	END IF
	RETURN
END IF
CALL fl_lee_cliente_general(rm_t20.t20_cod_cliente) RETURNING r_z01.*
CALL calcular_total()
LET rm_t20.t20_usu_modifi = vg_usuario
LET rm_t20.t20_fec_modifi = CURRENT
UPDATE talt020 SET t20_cod_cliente = rm_t20.t20_cod_cliente,
                   t20_nom_cliente = rm_t20.t20_nom_cliente,
                   t20_dir_cliente = rm_t20.t20_dir_cliente,
                   t20_tel_cliente = rm_t20.t20_tel_cliente,
                   t20_cedruc      = rm_t20.t20_cedruc,
		   t20_motivo      = rm_t20.t20_motivo,
		   t20_moneda      = rm_t20.t20_moneda,
		   t20_mano_ext    = rm_t20.t20_mano_ext,
		   t20_por_mo_tal  = rm_t20.t20_por_mo_tal,
		   t20_vde_mo_tal  = rm_t20.t20_vde_mo_tal,
		   t20_total_impto = rm_t20.t20_total_impto,
		   t20_otros_mat   = rm_t20.t20_otros_mat,
		   t20_gastos      = rm_t20.t20_gastos,
		   t20_total_neto  = rm_t20.t20_total_neto,
		   t20_observaciones = rm_t20.t20_observaciones,
		   t20_usu_modifi  = rm_t20.t20_usu_modifi,
		   t20_fec_modifi  = rm_t20.t20_fec_modifi
	WHERE CURRENT OF q_up
IF r_z01.z01_codcli IS NOT NULL THEN
	LET exec_up = 'UPDATE rept021 SET r21_codcli = ',
					r_z01.z01_codcli CLIPPED, ','
ELSE
	LET exec_up = 'UPDATE rept021 SET '
END IF
IF r_z01.z01_paga_impto = 'N' THEN
	LET porc = 0.00
ELSE
	LET porc = rg_gen.g00_porc_impto
END IF
LET exec_up = exec_up CLIPPED, ' r21_porc_impto = ', porc, ', ',
			' r21_tot_neto = (r21_tot_bruto - ',
				'r21_tot_dscto) + ((r21_tot_bruto - ',
				'r21_tot_dscto) * ',
				porc, ' / 100) + ',
				'r21_flete, '
LET exec_up = exec_up CLIPPED,
		" r21_nomcli = '", rm_t20.t20_nom_cliente CLIPPED, "'"
IF rm_t20.t20_dir_cliente IS NOT NULL THEN
	LET exec_up = exec_up CLIPPED,
		', r21_dircli = "', rm_t20.t20_dir_cliente CLIPPED, '"'
END IF
IF rm_t20.t20_tel_cliente IS NOT NULL THEN
	LET exec_up = exec_up CLIPPED,
	   	', r21_telcli = "', rm_t20.t20_tel_cliente CLIPPED, '"'
END IF
IF r_z01.z01_codcli IS NOT NULL THEN
	LET exec_up = exec_up CLIPPED,
	   	', r21_cedruc = "', r_z01.z01_num_doc_id CLIPPED, '"'
END IF
LET exec_up = exec_up CLIPPED,
		' WHERE r21_compania   = ', rm_t20.t20_compania,
	  	'   AND r21_localidad  = ', rm_t20.t20_localidad,
		'   AND r21_num_presup = ', rm_t20.t20_numpre
WHENEVER ERROR CONTINUE
PREPARE ex_up FROM exec_up
EXECUTE ex_up
IF STATUS <> 0 THEN
	ROLLBACK WORK
	CALL fl_mostrar_mensaje('Ha ocurrido un error al intentar actualizar los datos de la proforma. Por favor llame al ADMINISTRADOR', 'stop')
	WHENEVER ERROR STOP
	RETURN
END IF
WHENEVER ERROR STOP
LET exec_up = 'UPDATE rept022 '
IF r_z01.z01_paga_impto = 'N' THEN
	LET exec_up = exec_up CLIPPED,
			' SET r22_val_impto = 0 '
ELSE
	LET exec_up = exec_up CLIPPED,
			' SET r22_val_impto = ((r22_cantidad * ',
						'r22_precio) - ',
						'r22_val_descto) * ',
						rg_gen.g00_porc_impto,
						' / 100 '
END IF
LET exec_up = exec_up CLIPPED,
		' WHERE r22_compania   = ', rm_t20.t20_compania,
	  	'   AND r22_localidad  = ', rm_t20.t20_localidad,
		'   AND r22_numprof   IN ',
			'(SELECT r21_numprof ',
				'FROM rept021 ',
				' WHERE r21_compania   = r22_compania ',
			  	'   AND r21_localidad  = r22_localidad',
				'   AND r21_num_presup = ',
					rm_t20.t20_numpre, ')'
PREPARE ex_up2 FROM exec_up
EXECUTE ex_up2
COMMIT WORK
CALL mostrar_registro(vm_r_rows[vm_row_current])
CALL fl_mensaje_registro_modificado()

END FUNCTION



FUNCTION control_eliminacion()
DEFINE resp		CHAR(6)

IF vm_num_rows = 0 THEN
	CALL fl_mensaje_consultar_primero()
	RETURN
END IF
CALL mostrar_registro(vm_r_rows[vm_row_current])
IF rm_t20.t20_estado <> 'A' THEN
	CALL fl_mostrar_mensaje('Presupuesto no puede ser ELIMINADO.', 'exclamation')
	RETURN
END IF
BEGIN WORK
WHENEVER ERROR CONTINUE
DECLARE q_elim CURSOR FOR
	SELECT * FROM talt020
		WHERE ROWID = vm_r_rows[vm_row_current]
	FOR UPDATE
OPEN q_elim
FETCH q_elim INTO rm_t20.*
IF STATUS < 0 THEN
	ROLLBACK WORK
	CALL fl_mensaje_bloqueo_otro_usuario()
	WHENEVER ERROR STOP
	RETURN
END IF
IF STATUS = NOTFOUND THEN
	ROLLBACK WORK
	CALL fl_mostrar_mensaje('Registro ya no existe. Llame al ADMINISTRADOR.', 'exclamation')
	WHENEVER ERROR STOP
	RETURN
END IF
LET int_flag = 0
CALL fl_hacer_pregunta('Esta seguro que desea ELIMINAR este Presupuesto ?','No')
	RETURNING resp
IF resp <> 'Yes' THEN
	ROLLBACK WORK
	WHENEVER ERROR STOP
	RETURN
END IF
LET rm_t20.t20_estado = 'E'
WHENEVER ERROR CONTINUE
UPDATE talt020
	SET t20_estado     = rm_t20.t20_estado,
	    t20_usu_elimin = vg_usuario,
	    t20_fec_elimin = CURRENT
	WHERE CURRENT OF q_elim
IF STATUS <> 0 THEN
	ROLLBACK WORK
	CALL fl_mostrar_mensaje('ERROR: Registro no puede ser ELIMINADO. Llame al ADMINISTRADOR.', 'stop')
	WHENEVER ERROR STOP
	RETURN
END IF
WHENEVER ERROR STOP
COMMIT WORK
CALL mostrar_registro(vm_r_rows[vm_row_current])
CALL fl_mostrar_mensaje('Presupuesto ha sido ELIMINADO.', 'info')
 
END FUNCTION



FUNCTION control_consulta(flag_mant)
DEFINE flag_mant	CHAR(1)
DEFINE r_z01		RECORD LIKE cxct001.*
DEFINE numpre		LIKE talt020.t20_numpre
DEFINE codcli		LIKE talt023.t23_cod_cliente
DEFINE nomcli		LIKE talt023.t23_nom_cliente
DEFINE codo_aux		LIKE talt023.t23_orden
DEFINE nomo_aux		LIKE cxct001.z01_nomcli
DEFINE mone_aux		LIKE gent013.g13_moneda
DEFINE nomm_aux		LIKE gent013.g13_nombre
DEFINE deci_aux		LIKE gent013.g13_decimales
DEFINE query		CHAR(3000)
DEFINE expr_sql		CHAR(2000)
DEFINE num_reg		INTEGER

CLEAR FORM
INITIALIZE numpre, codo_aux, mone_aux TO NULL
LET int_flag = 0
IF flag_mant = 'C' THEN
	CONSTRUCT BY NAME expr_sql ON t20_numpre, t20_estado, t20_cod_cliente,
		t20_nom_cliente, t20_dir_cliente, t20_tel_cliente, t20_cedruc,
		t20_motivo, t20_observaciones, t20_moneda, t20_user_aprob,
		t20_fecha_aprob, t20_total_mo, --t20_por_mo_tal,
		t20_vde_mo_tal, t20_total_rp, t20_mano_ext, t20_total_impto,
		t20_otros_mat, t20_gastos, t20_total_neto, t20_usu_modifi,
		t20_fec_modifi, t20_usuario, t20_fecing
        	ON KEY(F1,CONTROL-W)
			CALL llamar_visor_teclas()
		ON KEY(F2)
			IF INFIELD(t20_numpre) THEN
				CALL fl_ayuda_presupuestos_taller(vg_codcia,
								vg_codloc, 'T')
					RETURNING numpre, codcli, nomcli
				LET int_flag = 0
				IF numpre IS NOT NULL THEN
					DISPLAY numpre TO t20_numpre
					DISPLAY nomcli TO t20_nom_cliente
				END IF
			END IF
			IF INFIELD(t20_cod_cliente) THEN
				CALL fl_ayuda_cliente_localidad(vg_codcia,
								vg_codloc)
					RETURNING r_z01.z01_codcli,
						  r_z01.z01_nomcli
				LET int_flag = 0
				IF r_z01.z01_nomcli IS NOT NULL THEN   
					LET rm_t20.t20_cod_cliente =
								r_z01.z01_codcli
					LET rm_t20.t20_nom_cliente = 
								r_z01.z01_nomcli
					DISPLAY BY NAME rm_t20.t20_cod_cliente, 
							rm_t20.t20_nom_cliente 
				END IF   
			END IF    
			IF INFIELD(t20_moneda) THEN
				CALL fl_ayuda_monedas()
					RETURNING mone_aux, nomm_aux, deci_aux
				LET int_flag = 0
				IF mone_aux IS NOT NULL THEN
					DISPLAY mone_aux TO t20_moneda 
					DISPLAY deci_aux TO t20_precision 
					DISPLAY nomm_aux TO tit_mon_bas
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
	LET query = 'SELECT *, ROWID FROM talt020 WHERE t20_compania = ' ||
			vg_codcia || ' AND t20_localidad = ' ||
			vg_codloc || ' AND ' || expr_sql CLIPPED ||
			' ORDER BY 3, 5'
ELSE
	LET query = 'SELECT *, ROWID FROM talt020 WHERE t20_compania = ' ||
			vg_codcia || ' AND t20_localidad = ' ||
			vg_codloc || ' AND t20_numpre = ' || vm_numpre || 
			' ORDER BY 3, 5'
END IF
PREPARE cons FROM query	
DECLARE q_cons CURSOR FOR cons
LET vm_num_rows = 0
FOREACH q_cons INTO rm_t20.*, num_reg
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
	IF num_args() = 5 THEN
		EXIT PROGRAM
	END IF
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
DEFINE r_g10		RECORD LIKE gent010.*
DEFINE r_g13		RECORD LIKE gent013.*
DEFINE codo_aux		LIKE talt023.t23_orden
DEFINE nomo_aux		LIKE cxct001.z01_nomcli
DEFINE mone_aux		LIKE gent013.g13_moneda
DEFINE nomm_aux		LIKE gent013.g13_nombre
DEFINE deci_aux		LIKE gent013.g13_decimales
DEFINE simbolo		LIKE gent013.g13_simbolo
DEFINE porc_mo		LIKE talt020.t20_por_mo_tal
DEFINE r_z01		RECORD LIKE cxct001.*
DEFINE r_z02		RECORD LIKE cxct002.*

LET resul = 0
INITIALIZE mone_aux TO NULL
DISPLAY BY NAME rm_t20.t20_estado, rm_t20.t20_moneda, rm_t20.t20_total_mo,
		rm_t20.t20_vde_mo_tal, rm_t20.t20_total_rp, rm_t20.t20_mano_ext,
		rm_t20.t20_otros_mat, rm_t20.t20_gastos, rm_t20.t20_usuario,
		rm_t20.t20_fecing
LET int_flag = 0
INPUT BY NAME rm_t20.t20_cod_cliente, rm_t20.t20_nom_cliente, 
	rm_t20.t20_dir_cliente, rm_t20.t20_tel_cliente, rm_t20.t20_cedruc,
	rm_t20.t20_motivo, rm_t20.t20_observaciones, rm_t20.t20_moneda,
	rm_t20.t20_mano_ext, rm_t20.t20_otros_mat, rm_t20.t20_gastos
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		IF FIELD_TOUCHED(rm_t20.t20_cod_cliente, rm_t20.t20_nom_cliente,
				 rm_t20.t20_dir_cliente, rm_t20.t20_tel_cliente,
				 rm_t20.t20_cedruc, rm_t20.t20_observaciones,
				 rm_t20.t20_motivo, rm_t20.t20_moneda,
				 rm_t20.t20_mano_ext, rm_t20.t20_otros_mat,
				 rm_t20.t20_gastos)
		THEN
			LET int_flag = 0
			CALL fl_mensaje_abandonar_proceso() RETURNING resp
			IF resp = 'Yes' THEN
				LET int_flag = 1
				CLEAR FORM
				EXIT INPUT
			END IF
		ELSE
			CLEAR FORM
			EXIT INPUT
		END IF
	ON KEY(F1,CONTROL-W)
		CALL llamar_visor_teclas()
	ON KEY(F2)
		IF INFIELD(t20_cod_cliente) THEN
			CALL fl_ayuda_cliente_localidad(vg_codcia,vg_codloc)
				RETURNING r_z01.z01_codcli, r_z01.z01_nomcli
			IF r_z01.z01_nomcli IS NOT NULL THEN   
				LET rm_t20.t20_cod_cliente = r_z01.z01_codcli
				LET rm_t20.t20_nom_cliente = r_z01.z01_nomcli
				DISPLAY BY NAME rm_t20.t20_cod_cliente, 
						rm_t20.t20_nom_cliente 
			END IF   
		END IF    
		IF INFIELD(t20_moneda) THEN
			CALL fl_ayuda_monedas() 
				RETURNING mone_aux, nomm_aux, simbolo  
			IF mone_aux IS NOT NULL THEN
				LET rm_t20.t20_moneda = mone_aux
				DISPLAY BY NAME rm_t20.t20_moneda
				DISPLAY nomm_aux TO tit_mon_bas
			END IF
		END IF
		LET int_flag = 0  
	BEFORE INPUT
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
	AFTER FIELD t20_cod_cliente, t20_cedruc
		IF rm_t20.t20_cod_cliente IS NOT NULL THEN
			CALL fl_lee_cliente_general(rm_t20.t20_cod_cliente) 
				RETURNING r_z01.*
			IF r_z01.z01_codcli IS NULL THEN
				CALL fl_mostrar_mensaje('Cliente no existe.','exclamation')
				NEXT FIELD t20_cod_cliente
			END IF
			LET rm_t20.t20_cod_cliente = r_z01.z01_codcli
			LET rm_t20.t20_nom_cliente = r_z01.z01_nomcli
			LET rm_t20.t20_dir_cliente = r_z01.z01_direccion1
			LET rm_t20.t20_tel_cliente = r_z01.z01_telefono1
			-- Se quitó esta condición, debido a que no tiene sentido en el
			-- programa actualmente.
			--IF rm_t20.t20_cod_cliente <> rm_r00.r00_codcli_tal THEN
				LET rm_t20.t20_cedruc = r_z01.z01_num_doc_id
			--END IF
			DISPLAY BY NAME rm_t20.t20_cod_cliente,
					rm_t20.t20_nom_cliente,
					rm_t20.t20_dir_cliente,
					rm_t20.t20_tel_cliente,
					rm_t20.t20_cedruc
			CALL fl_lee_cliente_localidad(vg_codcia, vg_codloc, 
				rm_t20.t20_cod_cliente) RETURNING r_z02.*
			IF r_z02.z02_codcli IS NULL THEN
				CALL fl_mostrar_mensaje('Cliente no habilitado para la Compañía/Localidad.','exclamation')
				NEXT FIELD t20_cod_cliente
			END IF
			IF r_z01.z01_estado <> 'A' THEN
				CALL fl_mensaje_estado_bloqueado()
				NEXT FIELD t20_cod_cliente
                        END IF  
			INITIALIZE r_g10.* TO NULL
			DECLARE q_g10 CURSOR FOR
				SELECT * FROM gent010
					WHERE g10_codcobr =
							rm_t20.t20_cod_cliente
			OPEN q_g10
			FETCH q_g10 INTO r_g10.*
			CLOSE q_g10
			FREE q_g10
			IF r_g10.g10_codcobr IS NOT NULL THEN
				CALL fl_mostrar_mensaje('No se puede hacer un presupuesto a un código de tarjeta de crédito. Por favor utilice el código de cliente.', 'info')
				NEXT FIELD t20_cod_cliente
			END IF
			IF r_z01.z01_tipo_doc_id <> 'P' THEN    
				CALL fl_validar_cedruc_dig_ver(rm_t20.t20_cedruc)
					RETURNING resul
				IF NOT resul THEN
					NEXT FIELD t20_cedruc
				END IF  
			END IF  
		END IF
		CALL calcular_total()
	AFTER FIELD t20_nom_cliente, t20_dir_cliente, t20_tel_cliente
		IF rm_t20.t20_cod_cliente IS NOT NULL THEN
			LET rm_t20.t20_cod_cliente = r_z01.z01_codcli
			LET rm_t20.t20_nom_cliente = r_z01.z01_nomcli
			LET rm_t20.t20_dir_cliente = r_z01.z01_direccion1
			LET rm_t20.t20_tel_cliente = r_z01.z01_telefono1
				LET rm_t20.t20_cedruc = r_z01.z01_num_doc_id
			DISPLAY BY NAME rm_t20.t20_cod_cliente,
					rm_t20.t20_nom_cliente,
					rm_t20.t20_dir_cliente,
					rm_t20.t20_tel_cliente,
					rm_t20.t20_cedruc
		END IF
	AFTER FIELD t20_moneda 
		IF rm_t20.t20_moneda IS NOT NULL THEN
			CALL fl_lee_moneda(rm_t20.t20_moneda)
				RETURNING r_g13.* 
			IF r_g13.g13_moneda IS NULL  THEN
				CALL fl_mostrar_mensaje('Moneda no existe.','exclamation')
				NEXT FIELD t20_moneda
			END IF
			LET rm_t20.t20_precision = r_g13.g13_decimales
			DISPLAY r_g13.g13_nombre TO tit_mon_bas
			IF r_g13.g13_estado = 'B' THEN
                                CALL fl_mensaje_estado_bloqueado()
				NEXT FIELD t20_moneda
			END IF
		ELSE
			LET rm_t20.t20_moneda = rg_gen.g00_moneda_base
			DISPLAY BY NAME rm_t20.t20_moneda
			CALL fl_lee_moneda(rm_t20.t20_moneda) RETURNING r_g13.* 
			DISPLAY r_g13.g13_nombre TO tit_mon_bas
		END IF
	{--
	AFTER FIELD t20_por_mo_tal
		IF rm_t20.t20_por_mo_tal IS NULL THEN
			LET rm_t20.t20_por_mo_tal = porc_mo
			DISPLAY BY NAME rm_t20.t20_por_mo_tal
		END IF
		CALL calcular_descuento_mo()
		CALL calcular_total()
	--}
	AFTER FIELD t20_mano_ext
		CALL calcular_total()
	AFTER FIELD t20_otros_mat, t20_gastos
		CALL calcular_total()
END INPUT

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
DEFINE r_t23		RECORD LIKE talt023.*
DEFINE r_g13		RECORD LIKE gent013.*
DEFINE num_registro	INTEGER

IF vm_num_rows <= 0 THEN
	RETURN
END IF
SELECT * INTO rm_t20.* FROM talt020 WHERE ROWID = num_registro	
IF STATUS = NOTFOUND THEN
	CALL fl_mostrar_mensaje('No existe registro con índice: ' || vm_row_current,'exclamation')
	RETURN
END IF
DISPLAY BY NAME rm_t20.t20_numpre, rm_t23.t23_orden, rm_t20.t20_motivo,
		rm_t20.t20_cod_cliente, rm_t20.t20_nom_cliente,
		rm_t20.t20_dir_cliente, rm_t20.t20_tel_cliente,
		rm_t20.t20_moneda, rm_t20.t20_total_mo, --rm_t20.t20_por_mo_tal,
		rm_t20.t20_vde_mo_tal, rm_t20.t20_total_rp, rm_t20.t20_mano_ext,
		rm_t20.t20_otros_mat, rm_t20.t20_gastos, rm_t20.t20_user_aprob,
		rm_t20.t20_fecha_aprob, rm_t20.t20_usuario, rm_t20.t20_fecing,
		rm_t20.t20_observaciones, rm_t20.t20_usu_modifi,
		rm_t20.t20_fec_modifi, rm_t20.t20_cedruc
CALL fl_lee_moneda(rm_t20.t20_moneda) RETURNING r_g13.* 
DISPLAY r_g13.g13_nombre TO tit_mon_bas
CALL muestra_estado()
CALL calcular_total()
INITIALIZE rm_t23.* TO NULL
SELECT * INTO rm_t23.* FROM talt023
	WHERE t23_compania  = vg_codcia
	  AND t23_localidad = vg_codloc
	  AND t23_numpre    = rm_t20.t20_numpre
	  AND t23_estado    <> 'D'
IF STATUS <> NOTFOUND THEN
	DISPLAY BY NAME rm_t23.t23_orden
ELSE
	CLEAR t23_orden
END IF

END FUNCTION



FUNCTION conversion_ot()
DEFINE resp		CHAR(6)

IF vm_num_rows = 0 THEN
	CALL fl_mensaje_consultar_primero()
	RETURN
END IF
LET int_flag = 0
BEGIN WORK
WHENEVER ERROR CONTINUE
DECLARE q_ba CURSOR FOR
	SELECT * FROM talt020
		WHERE ROWID = vm_r_rows[vm_row_current]
	FOR UPDATE
OPEN q_ba
FETCH q_ba INTO rm_t20.*
IF STATUS < 0 THEN
	ROLLBACK WORK
	CALL fl_mensaje_bloqueo_otro_usuario()
	WHENEVER ERROR STOP
	RETURN
END IF
WHENEVER ERROR STOP
IF rm_t20.t20_estado = 'P' THEN
	ROLLBACK WORK
	CALL fl_mostrar_mensaje('Presupuesto ya fue convertido en O.T.','exclamation')
	RETURN
END IF
IF rm_t20.t20_total_neto = 0 THEN
	ROLLBACK WORK
	CALL fl_mostrar_mensaje('Presupuesto no tiene totales.','exclamation')
	RETURN
END IF
IF rm_t20.t20_cod_cliente IS NULL THEN
	ROLLBACK WORK
	CALL fl_mostrar_mensaje('Presupuesto no tiene codigo de cliente. Por favor digitelo.','exclamation')
	RETURN
END IF
--CALL lee_orden_trabajo()
LET int_flag = 0
CALL fl_hacer_pregunta('Esta seguro de Convertir este Presupuesto en OT ?.', 'No')
	RETURNING resp
IF resp <> 'Yes' THEN
	LET int_flag = 1
	ROLLBACK WORK
	CALL mostrar_registro(vm_r_rows[vm_row_current])
	RETURN
END IF
CALL obtener_num_orden_trabajo_nueva()
SELECT r02_codigo
	INTO vm_bod_taller
	FROM rept002
	WHERE r02_compania  = vg_codcia
	  AND r02_localidad = vg_codloc
	  AND r02_estado    = "A"
	  AND r02_area      = "T"
	  AND r02_factura   = "S"
	  AND r02_tipo      = "L"
IF STATUS = NOTFOUND THEN
	ROLLBACK WORK
	CALL fl_mostrar_mensaje('No hay bodega logica de facturación de Taller configurada.','stop') 
	RETURN
END IF
IF NOT genera_ot() THEN
	RETURN
END IF
CALL genera_proformas_ot()
CALL genera_mo_ot()
CALL genera_transferencias()
COMMIT WORK
CALL imprimir_transferencia()
DROP TABLE te_transf_gen
CALL mostrar_registro(vm_r_rows[vm_row_current])
CALL fl_mostrar_mensaje('Proceso de Conversión a OT Terminó Ok.', 'info')

END FUNCTION



FUNCTION lee_orden_trabajo()
DEFINE orden		LIKE talt023.t23_orden
DEFINE nom_cliente	LIKE talt023.t23_nom_cliente
DEFINE r_t23		RECORD LIKE talt023.*
DEFINE resp		CHAR(6)

INITIALIZE rm_t23.* TO NULL
LET int_flag = 0
INPUT BY NAME rm_t23.t23_orden WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		LET int_flag = 0
		CALL fl_mensaje_abandonar_proceso() RETURNING resp
             	IF resp = 'Yes' THEN
			CLEAR t23_orden
			LET int_flag = 1
               		RETURN
	        END IF
	ON KEY(F2)
		CALL fl_ayuda_orden_trabajo(vg_codcia, vg_codloc, 'T') 
			RETURNING orden, nom_cliente
		IF orden IS NOT NULL THEN
			LET rm_t23.t23_orden = orden
			DISPLAY BY NAME rm_t23.t23_orden  
		END IF
		LET int_flag = 0
	AFTER FIELD t23_orden 
		IF rm_t23.t23_orden IS NULL THEN
			NEXT FIELD t23_orden
  		END IF
		CALL fl_lee_orden_trabajo(vg_codcia,vg_codloc, rm_t23.t23_orden)
			RETURNING r_t23.*
		IF r_t23.t23_orden IS NOT NULL THEN
			CALL fl_mostrar_mensaje('Orden ya existe.', 'exclamation')
			NEXT FIELD t23_orden
		END IF
END INPUT

END FUNCTION



FUNCTION obtener_num_orden_trabajo_nueva()

INITIALIZE rm_t23.* TO NULL
SQL
	SELECT NVL(MAX(t23_orden), 0) + 1
		INTO $rm_t23.t23_orden
		FROM talt023
		WHERE t23_compania  = $vg_codcia
		  AND t23_localidad = $vg_codloc
END SQL

END FUNCTION



FUNCTION genera_ot()
DEFINE r_z01		RECORD LIKE cxct001.*
DEFINE r_t23		RECORD LIKE talt023.*
DEFINE r_t05		RECORD LIKE talt005.*
DEFINE r_g14		RECORD LIKE gent014.*

LET rm_t20.t20_estado      = 'P'
LET rm_t20.t20_user_aprob  = vg_usuario
LET rm_t20.t20_fecha_aprob = CURRENT
CALL muestra_estado()
UPDATE talt020
	SET t20_estado      = rm_t20.t20_estado,
	    t20_user_aprob  = vg_usuario,
	    t20_fecha_aprob = CURRENT
	WHERE CURRENT OF q_ba
INITIALIZE r_t23.* TO NULL
LET r_t23.t23_compania 		= vg_codcia
LET r_t23.t23_localidad		= vg_codloc
LET r_t23.t23_orden 		= rm_t23.t23_orden
LET r_t23.t23_estado 		= 'A'
LET r_t23.t23_tipo_ot 		= '1'
LET r_t23.t23_subtipo_ot 	= '1'
CALL lee_tipo_ot(r_t23.t23_tipo_ot, r_t23.t23_subtipo_ot)
	RETURNING r_t23.t23_tipo_ot, r_t23.t23_subtipo_ot, r_t23.t23_cod_asesor
IF int_flag THEN
	ROLLBACK WORK
	RETURN 0
END IF
LET r_t23.t23_descripcion 	= rm_t20.t20_motivo
LET r_t23.t23_cod_cliente 	= rm_t20.t20_cod_cliente
LET r_t23.t23_nom_cliente 	= rm_t20.t20_nom_cliente
LET r_t23.t23_tel_cliente 	= rm_t20.t20_tel_cliente
LET r_t23.t23_dir_cliente 	= rm_t20.t20_dir_cliente
LET r_t23.t23_cedruc	 	= rm_t20.t20_cedruc
LET r_t23.t23_codcli_est 	= rm_t20.t20_cod_cliente
LET r_t23.t23_numpre 		= rm_t20.t20_numpre
CALL fl_lee_tipo_orden_taller(vg_codcia, r_t23.t23_tipo_ot)
	RETURNING r_t05.*
IF rm_t20.t20_moneda = rg_gen.g00_moneda_base THEN
	LET r_t23.t23_valor_tope = r_t05.t05_valtope_mb
ELSE
	LET r_t23.t23_valor_tope = r_t05.t05_valtope_ma
END IF
DECLARE q_sec CURSOR FOR
	SELECT t02_seccion
		FROM talt002
		WHERE t02_compania = vg_codcia
OPEN q_sec
FETCH q_sec INTO r_t23.t23_seccion
IF STATUS = NOTFOUND THEN
	CALL fl_mostrar_mensaje('Tabla de secciones está vacía.','exclamation')
	ROLLBACK WORK
	EXIT PROGRAM
END IF
{--
DECLARE q_ase CURSOR FOR
	SELECT t03_mecanico
		FROM talt003, talt061
		WHERE t03_compania   = vg_codcia
		  AND t03_tipo       = 'A'
		  AND t61_compania   = t03_compania
		  AND t61_cod_asesor = t03_mecanico
IF vg_codloc <> 1 THEN
	OPEN q_ase
	FETCH q_ase INTO r_t23.t23_cod_asesor
	CLOSE q_ase
	FREE q_ase
ELSE
        -- PROVISIONAL HASTA SOLUCIONAR DE OTRA FORMA
        FOREACH q_ase INTO r_t23.t23_cod_asesor
                IF r_t23.t23_cod_asesor <> 1 THEN
                        EXIT FOREACH
                END IF
        END FOREACH
        --
END IF
DECLARE q_mec CURSOR FOR
	SELECT t03_mecanico
		FROM talt003
		WHERE t03_compania   = vg_codcia
		  AND t03_tipo       = 'M'
IF vg_codloc <> 1 THEN
	OPEN q_mec
	FETCH q_mec INTO r_t23.t23_cod_mecani
	CLOSE q_mec
	FREE q_mec
ELSE
        -- PROVISIONAL HASTA SOLUCIONAR DE OTRA FORMA
        FOREACH q_mec INTO r_t23.t23_cod_mecani
                IF r_t23.t23_cod_mecani <> 1 THEN
                        EXIT FOREACH
                END IF
        END FOREACH
        --
END IF
--}
LET r_t23.t23_cod_mecani = r_t23.t23_cod_asesor
LET r_t23.t23_moneda = rm_t20.t20_moneda
IF r_t23.t23_moneda = rg_gen.g00_moneda_base THEN
	LET r_t23.t23_paridad = 1
ELSE
	CALL fl_lee_factor_moneda(r_t23.t23_moneda, rg_gen.g00_moneda_base) 
		RETURNING r_g14.*
	LET r_t23.t23_paridad = r_g14.g14_tasa
END IF
LET r_t23.t23_precision 	= rm_t20.t20_precision
LET r_t23.t23_fecini 		= TODAY
LET r_t23.t23_fecfin 		= TODAY
LET r_t23.t23_cont_cred 	= 'C'
LET r_t23.t23_porc_impto 	= rg_gen.g00_porc_impto
CALL fl_lee_cliente_general(rm_t20.t20_cod_cliente) RETURNING r_z01.*
IF r_z01.z01_paga_impto = 'N' THEN
	LET r_t23.t23_porc_impto = 0
END IF
DECLARE q_mod CURSOR FOR
	SELECT t04_modelo
		FROM talt004
		WHERE t04_compania = vg_codcia
OPEN q_mod
FETCH q_mod INTO r_t23.t23_modelo
CLOSE q_mod
FREE q_mod
LET r_t23.t23_val_mo_tal 	= 0
LET r_t23.t23_val_mo_ext 	= 0
LET r_t23.t23_val_mo_cti 	= 0
LET r_t23.t23_val_rp_tal 	= 0
LET r_t23.t23_val_rp_ext 	= 0
LET r_t23.t23_val_rp_cti 	= 0
LET r_t23.t23_val_rp_alm 	= 0
LET r_t23.t23_val_otros1 	= 0
LET r_t23.t23_val_otros2 	= 0
LET r_t23.t23_por_mo_tal 	= rm_t20.t20_por_mo_tal
LET r_t23.t23_por_rp_tal 	= 0
LET r_t23.t23_por_rp_alm 	= 0
LET r_t23.t23_vde_mo_tal 	= rm_t20.t20_vde_mo_tal
LET r_t23.t23_vde_rp_tal 	= 0
LET r_t23.t23_vde_rp_alm 	= 0
LET r_t23.t23_tot_bruto 	= 0
LET r_t23.t23_tot_dscto 	= 0
LET r_t23.t23_val_impto 	= 0
LET r_t23.t23_tot_neto 		= 0
LET r_t23.t23_usuario 		= vg_usuario
LET r_t23.t23_fecing 		= CURRENT
INSERT INTO talt023 VALUES (r_t23.*)
RETURN 1

END FUNCTION



FUNCTION lee_tipo_ot(t23_tipo_ot, t23_subtipo_ot)
DEFINE t23_tipo_ot		LIKE talt023.t23_tipo_ot
DEFINE t23_subtipo_ot	LIKE talt023.t23_subtipo_ot
DEFINE r_t03			RECORD LIKE talt003.*
DEFINE r_t05			RECORD LIKE talt005.*
DEFINE r_t06			RECORD LIKE talt006.*
DEFINE tipord, tipo_ot	LIKE talt005.t05_tipord
DEFINE desc_tipo_ot		LIKE talt005.t05_nombre
DEFINE subtipo			LIKE talt006.t06_subtipo
DEFINE desc_subtipo_ot	LIKE talt006.t06_nombre
DEFINE resp				CHAR(6)
DEFINE lin_menu			SMALLINT
DEFINE row_ini  		SMALLINT
DEFINE num_rows 		SMALLINT
DEFINE num_cols 		SMALLINT

LET lin_menu      = 00
LET row_ini       = 08
LET num_rows      = 11
LET num_cols      = 58
IF vg_gui = 0 THEN        
	LET lin_menu = 01
	LET row_ini  = 09
	LET num_rows = 08 
	LET num_cols = 46 
END IF                  
OPEN WINDOW w_talf201_2 AT row_ini, 15 WITH num_rows ROWS, num_cols COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE lin_menu,
		  MESSAGE LINE LAST, BORDER) 
IF vg_gui = 1 THEN
	OPEN FORM f_talf201_2 FROM '../forms/talf201_2'
ELSE
	OPEN FORM f_talf201_2 FROM '../forms/talf201_2c'
END IF
DISPLAY FORM f_talf201_2
INITIALIZE r_t03.* TO NULL
CALL fl_lee_tipo_orden_taller(vg_codcia, t23_tipo_ot) RETURNING r_t05.* 
CALL fl_lee_subtipo_orden_taller(vg_codcia, t23_tipo_ot, t23_subtipo_ot)
	RETURNING r_t06.* 
DISPLAY r_t05.t05_nombre TO desc_tipo_ot
DISPLAY r_t06.t06_nombre TO desc_subtipo_ot
LET int_flag = 0
INPUT BY NAME t23_tipo_ot, t23_subtipo_ot, r_t03.t03_mecanico
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		IF FIELD_TOUCHED(t23_tipo_ot, t23_subtipo_ot, r_t03.t03_mecanico) THEN
			LET int_flag = 0
			CALL fl_mensaje_abandonar_proceso() RETURNING resp
			IF resp = 'Yes' THEN
				LET int_flag = 1
				EXIT INPUT
			END IF
		ELSE
			LET int_flag = 1
			EXIT INPUT
		END IF
	ON KEY(F2)
		IF INFIELD(t23_tipo_ot) THEN
			CALL fl_ayuda_tipo_orden_trabajo(vg_codcia)
				RETURNING tipord, desc_tipo_ot
			IF tipord IS NOT NULL THEN
				LET t23_tipo_ot = tipord
				DISPLAY BY NAME t23_tipo_ot, desc_tipo_ot
			END IF
		END IF
		IF INFIELD(t23_subtipo_ot) AND t23_tipo_ot IS NOT NULL THEN
			CALL fl_ayuda_subtipo_orden(vg_codcia, t23_tipo_ot)
				RETURNING desc_tipo_ot, subtipo, desc_subtipo_ot
			IF subtipo IS NOT NULL THEN
				LET t23_subtipo_ot = subtipo
				DISPLAY BY NAME t23_subtipo_ot, desc_subtipo_ot
			END IF
		END IF
		IF INFIELD(t03_mecanico) THEN
			CALL fl_ayuda_mecanicos(vg_codcia, 'T')
				RETURNING r_t03.t03_mecanico, r_t03.t03_nombres
			IF r_t03.t03_mecanico IS NOT NULL THEN
				DISPLAY BY NAME r_t03.t03_mecanico, r_t03.t03_nombres
			END IF
		END IF
		LET int_flag = 0
	BEFORE FIELD t23_tipo_ot
		LET tipo_ot = t23_tipo_ot
	AFTER FIELD t23_tipo_ot
		IF t23_tipo_ot IS NOT NULL THEN
			CALL fl_lee_tipo_orden_taller(vg_codcia, t23_tipo_ot)
				RETURNING r_t05.*
			IF r_t05.t05_tipord IS NULL THEN
				CALL fl_mostrar_mensaje('No existe Tipo de Orden.','exclamation')
				NEXT FIELD t23_tipo_ot
       		END IF
			LET t23_tipo_ot     = r_t05.t05_tipord
			LET desc_tipo_ot    = r_t05.t05_nombre
			IF tipo_ot <> t23_tipo_ot THEN
				LET t23_subtipo_ot  = NULL
				LET desc_subtipo_ot = NULL
			END IF
		ELSE
			LET t23_tipo_ot     = NULL
			LET desc_tipo_ot    = NULL
			LET t23_subtipo_ot  = NULL
			LET desc_subtipo_ot = NULL
		END IF
		DISPLAY BY NAME t23_tipo_ot, desc_tipo_ot, t23_subtipo_ot,
						desc_subtipo_ot
	AFTER FIELD t23_subtipo_ot
		IF t23_tipo_ot IS NULL THEN
			LET t23_subtipo_ot  = NULL
			LET desc_subtipo_ot = NULL
			DISPLAY BY NAME t23_subtipo_ot, desc_subtipo_ot
			CONTINUE INPUT
		END IF
		IF t23_subtipo_ot IS NOT NULL THEN
			CALL fl_lee_subtipo_orden_taller(vg_codcia, t23_tipo_ot,
								t23_subtipo_ot)
				RETURNING r_t06.*
			IF r_t06.t06_subtipo IS NULL THEN
				CALL fl_mostrar_mensaje('No existe Subtipo de Orden o no esta asociado al Tipo de Orden.','exclamation')
				NEXT FIELD t23_subtipo_ot
       		END IF
			LET t23_subtipo_ot  = r_t06.t06_subtipo
			LET desc_subtipo_ot = r_t06.t06_nombre
		ELSE
			LET t23_subtipo_ot  = NULL
			LET desc_subtipo_ot = NULL
		END IF
		DISPLAY BY NAME t23_subtipo_ot, desc_subtipo_ot
	AFTER FIELD t03_mecanico
		IF r_t03.t03_mecanico IS NOT NULL THEN
			CALL fl_lee_mecanico(vg_codcia, r_t03.t03_mecanico)
				RETURNING r_t03.*
			IF r_t03.t03_compania IS NULL THEN
				CALL fl_mostrar_mensaje('No existe Asesor/Técnico en la compañía.','exclamation')
				NEXT FIELD t03_mecanico
			END IF
		ELSE
			INITIALIZE r_t03.* TO NULL
		END IF
		DISPLAY BY NAME r_t03.t03_mecanico, r_t03.t03_nombres
	AFTER INPUT
		CALL fl_lee_subtipo_orden_taller(vg_codcia, t23_tipo_ot, t23_subtipo_ot)
			RETURNING r_t06.*
		IF r_t06.t06_subtipo IS NULL THEN
			CALL fl_mostrar_mensaje('No existe Subtipo de Orden o no esta asociado al Tipo de Orden.','exclamation')
			NEXT FIELD t23_subtipo_ot
  		END IF
END INPUT
CLOSE WINDOW w_talf201_2
RETURN t23_tipo_ot, t23_subtipo_ot, r_t03.t03_mecanico

END FUNCTION



FUNCTION genera_mo_ot()
DEFINE r_t00		RECORD LIKE talt000.*
DEFINE r_t03		RECORD LIKE talt003.*
DEFINE r_t07		RECORD LIKE talt007.*
DEFINE r_t21		RECORD LIKE talt021.*
DEFINE r_t23		RECORD LIKE talt023.*
DEFINE r_t24		RECORD LIKE talt024.*
DEFINE valor		LIKE talt024.t24_valor_tarea
DEFINE mensaje		VARCHAR(100)

CALL fl_lee_configuracion_taller(vg_codcia) RETURNING r_t00.*
IF r_t00.t00_estado = 'B' THEN
	CALL fl_mostrar_mensaje('Compañía de talleres esta bloqueada, no se puede cargar tarea de presupuesto a OT.', 'exclamation')
	RETURN
END IF
DECLARE q_mo CURSOR FOR
	SELECT * FROM talt021
		WHERE t21_compania  = vg_codcia
		  AND t21_localidad = vg_codloc
		  AND t21_numpre    = rm_t20.t20_numpre
		ORDER BY t21_secuencia
OPEN q_mo
FETCH q_mo INTO r_t21.*
IF STATUS = NOTFOUND THEN
	RETURN
END IF
CALL fl_lee_orden_trabajo(r_t21.t21_compania, r_t21.t21_localidad,
				rm_t23.t23_orden)
	RETURNING r_t23.*
IF r_t23.t23_compania IS NULL THEN
	CALL fl_mostrar_mensaje('No existe OT para cargarle mano de obra.', 'exclamation')
	RETURN
END IF
LET r_t23.t23_val_mo_tal = 0
FOREACH q_mo INTO r_t21.*
	INITIALIZE r_t24.* TO NULL
	LET r_t24.t24_compania    = r_t21.t21_compania
	LET r_t24.t24_localidad   = r_t21.t21_localidad
	LET r_t24.t24_orden       = r_t23.t23_orden
	LET r_t24.t24_codtarea    = r_t21.t21_codtarea
	CALL fl_lee_tarea(r_t24.t24_compania, r_t24.t24_codtarea)
		RETURNING r_t07.*
	IF r_t07.t07_compania IS NULL THEN
		ROLLBACK WORK
		LET mensaje = 'No existe la tarea ', r_t24.t24_codtarea CLIPPED,
				' configurada en el maestro de tareas.'
		CALL fl_mostrar_mensaje(mensaje, 'stop')
		EXIT PROGRAM
	END IF
	IF r_t07.t07_estado = 'B' THEN
		ROLLBACK WORK
		LET mensaje = 'La tarea ', r_t24.t24_codtarea CLIPPED,
				' esta bloqueada en el maestro de tareas.'
		CALL fl_mostrar_mensaje(mensaje, 'stop')
		EXIT PROGRAM
	END IF
	LET r_t24.t24_secuencia   = r_t21.t21_secuencia
	LET r_t24.t24_descripcion = r_t21.t21_descripcion
	LET r_t24.t24_paga_clte   = 'S'
	LET r_t24.t24_mecanico    = r_t23.t23_cod_mecani
	CALL fl_lee_mecanico(r_t24.t24_compania, r_t24.t24_mecanico)
		RETURNING r_t03.*
	LET r_t24.t24_seccion     = r_t03.t03_seccion
	LET r_t24.t24_factor      = r_t21.t21_valor
	LET r_t24.t24_puntos_opti = 100 
	LET r_t24.t24_valor_tarea = r_t21.t21_valor
	{--
	IF r_t00.t00_seudo_tarea <> r_t24.t24_codtarea THEN
		LET r_t24.t24_puntos_opti = r_t07.t07_pto_default
		IF r_t07.t07_tipo = 'V' THEN
			IF r_t23.t23_moneda = rg_gen.g00_moneda_base THEN
				LET valor = r_t07.t07_val_defa_mb
			END IF
			IF r_t23.t23_moneda = rg_gen.g00_moneda_alt THEN
				LET valor = r_t07.t07_val_defa_ma
			END IF
		END IF
		IF r_t07.t07_tipo = 'P' THEN
			IF r_t23.t23_moneda = rg_gen.g00_moneda_base THEN
				LET valor = r_t00.t00_factor_mb
			END IF
			IF r_t23.t23_moneda = rg_gen.g00_moneda_alt THEN
				LET valor = r_t00.t00_factor_ma
			END IF
			LET r_t24.t24_factor = valor
		END IF
		LET r_t24.t24_valor_tarea = valor * r_t24.t24_puntos_opti / 100
		CALL fl_retorna_precision_valor(r_t23.t23_moneda,
						r_t24.t24_valor_tarea)
			RETURNING r_t24.t24_valor_tarea
	END IF
	--}
	LET r_t23.t23_val_mo_tal  = r_t23.t23_val_mo_tal + r_t24.t24_valor_tarea
	LET r_t24.t24_puntos_real = r_t24.t24_puntos_opti
	LET r_t24.t24_porc_descto = r_t21.t21_porc_descto
	LET r_t24.t24_val_descto  = r_t21.t21_val_descto
	LET r_t24.t24_ord_compra  = NULL
	LET r_t24.t24_usuario     = r_t21.t21_usuario
	LET r_t24.t24_fecing      = CURRENT
	INSERT INTO talt024 VALUES(r_t24.*)
END FOREACH
CALL fl_totaliza_orden_taller(r_t23.*) RETURNING r_t23.*
UPDATE talt023
	SET * = r_t23.*
	WHERE t23_compania  = r_t23.t23_compania
	  AND t23_localidad = r_t23.t23_localidad
	  AND t23_orden     = r_t23.t23_orden

END FUNCTION



FUNCTION genera_transferencias()
DEFINE i		SMALLINT
DEFINE cod_tran		CHAR(2)
DEFINE r_r10		RECORD LIKE rept010.*
DEFINE r_r11		RECORD LIKE rept011.*
DEFINE r_r19		RECORD LIKE rept019.*
DEFINE r_r20		RECORD LIKE rept020.*
DEFINE bodega		LIKE rept011.r11_bodega
DEFINE item		LIKE rept011.r11_item
DEFINE cantidad		LIKE rept011.r11_stock_act
DEFINE num_tran		INTEGER
DEFINE resp	 	CHAR(6)
DEFINE mensaje 		VARCHAR(160)

CREATE TEMP TABLE te_transf_gen(
		 te_cod_tran	CHAR(2),
		 te_num_tran 	DECIMAL(15,0)
	)
LET cod_tran = 'TR'
SELECT r22_bodega, r22_item, SUM(r22_cantidad) te_cantidad FROM rept021, rept022
	WHERE r21_compania   = vg_codcia AND 
	      r21_localidad  = vg_codloc AND 
	      r21_num_presup = rm_t20.t20_numpre AND 
	      r21_compania   = r22_compania AND
	      r21_localidad  = r22_localidad AND
	      r21_numprof    = r22_numprof
	GROUP BY 1, 2
	INTO TEMP te_trans
DECLARE qu_botr CURSOR FOR SELECT UNIQUE r22_bodega FROM te_trans
FOREACH qu_botr INTO bodega
	INITIALIZE r_r19.*, r_r20.* TO NULL
	CALL fl_actualiza_control_secuencias(vg_codcia, vg_codloc, 'RE',
	                             'AA', 'TR')
		RETURNING num_tran
	IF num_tran <= 0 THEN
		ROLLBACK WORK
		EXIT PROGRAM
	END IF
    	LET r_r19.r19_compania	= vg_codcia
    	LET r_r19.r19_localidad	= vg_codloc
    	LET r_r19.r19_cod_tran 	= cod_tran
    	LET r_r19.r19_num_tran 	= num_tran
    	LET r_r19.r19_cont_cred	= 'C'
    	LET r_r19.r19_referencia= 'O.T.: ', 
				   rm_t23.t23_orden USING '<<<<<<' CLIPPED,
				  ', PRESUP.: ',
				   rm_t20.t20_numpre USING '<<<<<<' CLIPPED,
				  ', ', rm_t20.t20_nom_cliente
    	LET r_r19.r19_codcli 	= rm_t20.t20_cod_cliente
    	LET r_r19.r19_nomcli 	= rm_t20.t20_nom_cliente
    	LET r_r19.r19_dircli 	= rm_t20.t20_dir_cliente
    	LET r_r19.r19_telcli 	= rm_t20.t20_tel_cliente
    	LET r_r19.r19_cedruc 	= rm_t20.t20_cedruc
	DECLARE qu_ven CURSOR FOR
		SELECT r01_codigo FROM rept001
			WHERE r01_compania   = vg_codcia
			  AND r01_estado     = 'A'
			  AND r01_user_owner = vg_usuario
	OPEN qu_ven
	FETCH qu_ven INTO r_r19.r19_vendedor
	CLOSE qu_ven
	FREE qu_ven
	IF r_r19.r19_vendedor IS NULL THEN
		ROLLBACK WORK
		CALL fl_mostrar_mensaje('El Usuario ' || vg_usuario CLIPPED || ' no tiene Código de Vendedor asignado. Por favor consulte con el ADMINISTRADOR.', 'stop')
		EXIT PROGRAM
	END IF
    	LET r_r19.r19_ord_trabajo= rm_t23.t23_orden
    	LET r_r19.r19_descuento  = 0
    	LET r_r19.r19_porc_impto = 0
    	LET r_r19.r19_bodega_ori = bodega
    	LET r_r19.r19_bodega_dest= vm_bod_taller
    	LET r_r19.r19_moneda 	 = rm_t20.t20_moneda
	LET r_r19.r19_paridad    = rg_gen.g00_decimal_mb
    	LET r_r19.r19_precision  = rm_t20.t20_precision
    	LET r_r19.r19_tot_costo  = 0
    	LET r_r19.r19_tot_bruto  = 0
    	LET r_r19.r19_tot_dscto  = 0
    	LET r_r19.r19_tot_neto 	 = 0
    	LET r_r19.r19_flete 	 = 0
    	LET r_r19.r19_usuario 	 = vg_usuario
    	LET r_r19.r19_fecing 	 = CURRENT
	INSERT INTO rept019 VALUES (r_r19.*)
	DECLARE qu_dettr CURSOR FOR SELECT r22_item, te_cantidad
		FROM te_trans WHERE r22_bodega = bodega
	LET i = 0
	FOREACH qu_dettr INTO item, cantidad
		CALL fl_lee_stock_rep(vg_codcia, r_r19.r19_bodega_ori, item)
			RETURNING r_r11.*
		IF r_r11.r11_compania IS NULL THEN
			LET r_r11.r11_stock_act = 0
		END IF
		LET mensaje = 'ITEM: ', item
 		IF r_r11.r11_stock_act <= 0 THEN
			LET mensaje = mensaje CLIPPED, ' no tiene stock. Desea abandonar el proceso.'
			CALL fl_hacer_pregunta(mensaje,'No') RETURNING resp
			IF resp = 'Yes' THEN
				ROLLBACK WORK
				EXIT PROGRAM
			END IF
			CONTINUE FOREACH
		END IF
 		IF r_r11.r11_stock_act < cantidad THEN
			LET mensaje = mensaje CLIPPED, ' solo tiene stock: ',
				r_r11.r11_stock_act USING '###&', 
				' y se nesecita: ', cantidad USING '###&',
				'. Desea abandonar con el proceso.'
			CALL fl_hacer_pregunta(mensaje,'No') RETURNING resp
			IF resp = 'Yes' THEN
				ROLLBACK WORK
				EXIT PROGRAM
			END IF
			LET cantidad = r_r11.r11_stock_act
		END IF
		LET i = i + 1
    		LET r_r20.r20_compania 	= r_r19.r19_compania
    		LET r_r20.r20_localidad	= r_r19.r19_localidad
    		LET r_r20.r20_cod_tran 	= r_r19.r19_cod_tran
    		LET r_r20.r20_num_tran 	= r_r19.r19_num_tran
    		LET r_r20.r20_bodega 	= bodega
    		LET r_r20.r20_item 	= item
    		LET r_r20.r20_orden 	= i
    		LET r_r20.r20_cant_ped 	= cantidad
    		LET r_r20.r20_cant_ven  = cantidad
    		LET r_r20.r20_cant_dev 	= 0
    		LET r_r20.r20_cant_ent  = 0
    		LET r_r20.r20_descuento = 0
    		LET r_r20.r20_val_descto= 0
		CALL fl_lee_item(r_r19.r19_compania, item)
			RETURNING r_r10.*
    		LET r_r20.r20_costant_mb= r_r10.r10_costo_mb
    		LET r_r20.r20_costant_ma= r_r10.r10_costo_ma
    		LET r_r20.r20_costnue_mb= r_r10.r10_costo_mb
    		LET r_r20.r20_costnue_ma= r_r10.r10_costo_ma
		IF r_r19.r19_moneda <> rg_gen.g00_moneda_base THEN
			LET r_r10.r10_precio_mb = r_r10.r10_precio_ma
			LET r_r10.r10_costo_mb  = r_r10.r10_costo_ma
		END IF	
    		LET r_r20.r20_precio 	= r_r10.r10_precio_mb
    		LET r_r20.r20_val_impto = 0
    		LET r_r20.r20_costo 	= r_r10.r10_costo_mb
    		LET r_r20.r20_fob 	= r_r10.r10_fob
    		LET r_r20.r20_linea 	= r_r10.r10_linea
    		LET r_r20.r20_rotacion 	= r_r10.r10_rotacion
    		LET r_r20.r20_ubicacion = '.'
    		LET r_r20.r20_stock_ant = r_r11.r11_stock_act
		UPDATE rept011 
			SET r11_stock_act  = r11_stock_act - cantidad,
		            r11_egr_dia    = r11_egr_dia + cantidad
			WHERE r11_compania = vg_codcia
			AND   r11_bodega   = r_r19.r19_bodega_ori
			AND   r11_item     = item 
		CALL fl_lee_stock_rep(vg_codcia, r_r19.r19_bodega_dest, item)
			RETURNING r_r11.*
		IF r_r11.r11_compania IS NULL THEN
    			LET r_r11.r11_stock_act = 0
			INSERT INTO rept011
      				(r11_compania, r11_bodega, r11_item, 
		 		r11_ubicacion, r11_stock_ant, 
		 		r11_stock_act, r11_ing_dia,
		 		r11_egr_dia)
				VALUES(vg_codcia, r_r19.r19_bodega_dest,
		       			item, 'SN', 0, 0, 0, 0) 
		END IF
    		LET r_r20.r20_stock_bd  = r_r11.r11_stock_act
    		LET r_r20.r20_fecing    = CURRENT
		INSERT INTO rept020 VALUES (r_r20.*)
		UPDATE rept011 
			SET r11_stock_act  = r11_stock_act + cantidad,
		            r11_ing_dia    = r11_ing_dia   + cantidad
			WHERE r11_compania = vg_codcia
			AND   r11_bodega   = r_r19.r19_bodega_dest
			AND   r11_item     = item 
		LET r_r19.r19_tot_costo = r_r19.r19_tot_costo +
					  (cantidad * r_r20.r20_costo)
	END FOREACH
	IF i = 0 THEN
		DELETE FROM rept019
			WHERE r19_compania  = r_r19.r19_compania  AND 
		              r19_localidad = r_r19.r19_localidad AND 
		      	      r19_cod_tran  = r_r19.r19_cod_tran  AND 
		              r19_num_tran  = r_r19.r19_num_tran 
	ELSE
		UPDATE rept019 SET r19_tot_costo = r_r19.r19_tot_costo,
	                           r19_tot_bruto = r_r19.r19_tot_costo,
	                           r19_tot_neto  = r_r19.r19_tot_costo
			     WHERE r19_compania  = r_r19.r19_compania  AND 
		                   r19_localidad = r_r19.r19_localidad AND 
		                   r19_cod_tran  = r_r19.r19_cod_tran  AND 
		                   r19_num_tran  = r_r19.r19_num_tran 
		INSERT INTO te_transf_gen VALUES(r_r19.r19_cod_tran,
						 r_r19.r19_num_tran)
		CALL fl_mostrar_mensaje('Se generó la transferencia: ' || 
				 r_r19.r19_num_tran, 'info')
	END IF
END FOREACH
DROP TABLE te_trans

END FUNCTION



FUNCTION genera_proformas_ot()
DEFINE r_r21, r_r21_2	RECORD LIKE rept021.*
DEFINE r_r22		RECORD LIKE rept022.*
DEFINE r_r11		RECORD LIKE rept011.*
DEFINE prof_ori		LIKE rept021.r21_numprof
DEFINE impuesto		DECIMAL(12,2)
DEFINE i		SMALLINT

DECLARE cu_cprof CURSOR FOR
	SELECT * FROM rept021
		WHERE r21_compania   = vg_codcia
		  AND r21_localidad  = vg_codloc
		  AND r21_num_presup = rm_t20.t20_numpre
FOREACH cu_cprof INTO r_r21.*
	LET prof_ori = r_r21.r21_numprof
	WHILE TRUE
		SQL
			SELECT NVL(MAX(r21_numprof), 0) + 1
				INTO $r_r21.r21_numprof
				FROM rept021
				WHERE r21_compania  = $vg_codcia
				  AND r21_localidad = $vg_codloc
		END SQL
		CALL fl_lee_proforma_rep(vg_codcia, vg_codloc,r_r21.r21_numprof)
			RETURNING r_r21_2.*
		IF r_r21_2.r21_compania IS NULL THEN
			EXIT WHILE
		END IF
	END WHILE
	LET r_r21.r21_numprof    = r_r21.r21_numprof
	LET r_r21.r21_num_presup = NULL
	LET r_r21.r21_num_ot     = rm_t23.t23_orden
	LET r_r21.r21_fecing     = CURRENT
	INSERT INTO rept021 VALUES (r_r21.*)
	LET r_r21.r21_tot_bruto = 0
        LET r_r21.r21_tot_dscto = 0
	LET r_r21.r21_tot_neto  = 0
	LET i = 0
	DECLARE cu_dprof CURSOR FOR
		SELECT * FROM rept022		
			WHERE r22_compania  = vg_codcia
			  AND r22_localidad = vg_codloc
			  AND r22_numprof   = prof_ori
	FOREACH cu_dprof INTO r_r22.*
		IF r_r22.r22_cantidad <= 0 THEN
			CONTINUE FOREACH
		END IF
		CALL fl_lee_stock_rep(vg_codcia,r_r22.r22_bodega,r_r22.r22_item)
			RETURNING r_r11.*
		IF status = NOTFOUND OR r_r11.r11_stock_act = 0 THEN
			CONTINUE FOREACH
		END IF
		IF r_r11.r11_stock_act < r_r22.r22_cantidad THEN
			LET r_r22.r22_cantidad = r_r11.r11_stock_act
		END IF
		LET i = i + 1	
		LET r_r22.r22_bodega  = vm_bod_taller
		LET r_r22.r22_numprof = r_r21.r21_numprof
		INSERT INTO rept022 VALUES (r_r22.*)
		LET r_r21.r21_tot_bruto = r_r21.r21_tot_bruto +
			(r_r22.r22_precio * r_r22.r22_cantidad)
		LET r_r21.r21_tot_dscto = r_r21.r21_tot_dscto +
					  r_r22.r22_val_descto
	END FOREACH
	LET impuesto = (r_r21.r21_tot_bruto - r_r21.r21_tot_dscto) *
			   r_r21.r21_porc_impto / 100
	LET impuesto = fl_retorna_precision_valor(r_r21.r21_moneda, impuesto)
	LET r_r21.r21_tot_neto = r_r21.r21_tot_bruto - r_r21.r21_tot_dscto +
				   impuesto
	IF i = 0 THEN
		DELETE FROM rept021 
			WHERE r21_compania   = vg_codcia AND 
	                      r21_localidad  = vg_codloc AND 
	                      r21_numprof    = r_r21.r21_numprof
	ELSE
		UPDATE rept021 SET r21_tot_bruto = r_r21.r21_tot_bruto,
		                   r21_tot_dscto = r_r21.r21_tot_dscto,
		                   r21_tot_neto  = r_r21.r21_tot_neto
			WHERE r21_compania   = vg_codcia AND 
	                      r21_localidad  = vg_codloc AND 
	                      r21_numprof    = r_r21.r21_numprof
	END IF
END FOREACH

END FUNCTION



FUNCTION muestra_estado()

CASE rm_t20.t20_estado
	WHEN 'A' DISPLAY 'ACTIVO'    TO tit_estado_tal
	WHEN 'P' DISPLAY 'APROBADO'  TO tit_estado_tal
	WHEN 'E' DISPLAY 'ELIMINADO' TO tit_estado_tal
END CASE
DISPLAY BY NAME rm_t20.t20_estado

END FUNCTION



FUNCTION calcular_descuento_mo()

--LET rm_t20.t20_vde_mo_tal = rm_t20.t20_total_mo * rm_t20.t20_por_mo_tal / 100
CALL fl_retorna_precision_valor(rm_t20.t20_moneda, rm_t20.t20_vde_mo_tal)
	RETURNING rm_t20.t20_vde_mo_tal
DISPLAY BY NAME rm_t20.t20_vde_mo_tal

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
LET rm_t20.t20_total_impto = ((rm_t20.t20_total_mo - rm_t20.t20_vde_mo_tal)
				+ rm_t20.t20_total_rp + rm_t20.t20_mano_ext)
				* (r_g00.g00_porc_impto / 100)
IF r_z01.z01_paga_impto = 'N' THEN
	LET rm_t20.t20_total_impto = 0
END IF
DISPLAY BY NAME rm_t20.t20_total_impto

END FUNCTION



FUNCTION calcular_total()

CALL calcular_descuento_mo()
CALL calcular_impto()
LET total_bruto           = rm_t20.t20_total_mo + rm_t20.t20_total_rp
				+ rm_t20.t20_mano_ext
LET subtotal              = total_bruto - rm_t20.t20_vde_mo_tal
LET rm_t20.t20_total_neto = subtotal + rm_t20.t20_total_impto
				+ rm_t20.t20_otros_mat + rm_t20.t20_gastos
DISPLAY BY NAME total_bruto, subtotal, rm_t20.t20_total_neto

END FUNCTION



FUNCTION generar_pdf()
DEFINE cuantos		INTEGER
DEFINE comando		CHAR(256)

{--
LET comando = "cmd /C start /B firefox -new-window http://192.168.",
		serv CLIPPED, ":8080/presupuesto.jsp?numpre=",
		rm_t20.t20_numpre USING "<<<<<<&", "%26sesid=",
		sesionid USING "<<<<<<&", "%26usr=",
		DOWNSHIFT(vg_usuario) CLIPPED
--#CALL WinExec(comando) RETURNING err_flag
--}
LET comando = "presupuesto.jsp?numpre=", rm_t20.t20_numpre USING "<<<<<<&"
CALL fl_ejecuta_reporte_pdf(vg_codloc, comando, 'F')
SELECT COUNT(*)
	INTO cuantos
	FROM rept021
	WHERE r21_compania   = vg_codcia
	  AND r21_localidad  = vg_codloc
	  AND r21_num_presup = rm_t20.t20_numpre
IF cuantos = 0 THEN
	RETURN
END IF
{--
LET comando = "cmd /C start /B firefox -new-window http://192.168.",
		serv CLIPPED, ":8080/proformaTaller.jsp?numero=",
		rm_t20.t20_numpre USING "<<<<<<&", "%26sesid=",
		sesionid USING "<<<<<<&", "%26usr=",
		DOWNSHIFT(vg_usuario) CLIPPED
--#CALL WinExec(comando) RETURNING err_flag
--}
LET comando = "proformaTaller.jsp?numero=", rm_t20.t20_numpre USING "<<<<<<&"
CALL fl_ejecuta_reporte_pdf(vg_codloc, comando, 'F')

END FUNCTION



FUNCTION activacion_presupuesto()
DEFINE confir		CHAR(6)
DEFINE fec_eli		DATE
DEFINE mensaje		VARCHAR(250)

IF vm_num_rows = 0 THEN
	CALL fl_mensaje_consultar_primero()
	RETURN
END IF
CALL mostrar_registro(vm_r_rows[vm_row_current])
IF rm_t20.t20_estado <> 'E' THEN
	CALL fl_mostrar_mensaje('Presupuesto no puede ser ACTIVADO.','exclamation')
	RETURN
END IF
BEGIN WORK
WHENEVER ERROR CONTINUE
DECLARE q_acti CURSOR FOR
	SELECT * FROM talt020
		WHERE ROWID = vm_r_rows[vm_row_current]
	FOR UPDATE
OPEN q_acti
FETCH q_acti INTO rm_t20.*
IF STATUS < 0 THEN
	ROLLBACK WORK
	CALL fl_mensaje_bloqueo_otro_usuario()
	WHENEVER ERROR STOP
	RETURN
END IF
IF STATUS = NOTFOUND THEN
	ROLLBACK WORK
	CALL fl_mostrar_mensaje('Este presupuesto ya no existe. Por favor llame al ADMINISTRADOR.', 'exclamation')
	WHENEVER ERROR STOP
	RETURN
END IF
WHENEVER ERROR STOP
LET fec_eli = (MDY(rm_t00.t00_mespro, 01, rm_t00.t00_anopro)
		+ 1 UNITS MONTH - 1 UNITS DAY)
		- rm_t00.t00_dias_pres UNITS DAY
IF DATE(rm_t20.t20_fecing) < fec_eli THEN
	ROLLBACK WORK
	LET mensaje = 'No puede ACTIVAR un presupuesto con una fecha menor al ',
			fec_eli USING "dd-mm-yyyy", '. Aumente los dias de ',
			'validez de presupuesto en configuracion de compañia ',
			'del modulo TALLER.'
	CALL fl_mostrar_mensaje(mensaje, 'exclamation')
	RETURN
END IF
LET int_flag = 0
CALL fl_mensaje_seguro_ejecutar_proceso() RETURNING confir
IF confir <> 'Yes' THEN
	ROLLBACK WORK
	RETURN
END IF
LET rm_t20.t20_estado     = 'A'
LET rm_t20.t20_usu_elimin = NULL
LET rm_t20.t20_fec_elimin = NULL
WHENEVER ERROR CONTINUE
UPDATE talt020
	SET t20_estado     = rm_t20.t20_estado,
	    t20_usu_elimin = rm_t20.t20_usu_elimin,
	    t20_fec_elimin = rm_t20.t20_fec_elimin
	WHERE CURRENT OF q_acti
IF STATUS <> 0 THEN
	ROLLBACK WORK
	CALL fl_mostrar_mensaje('ERROR: Registro no puede ser ACTIVADO. Llame al ADMINISTRADOR.', 'stop')
	WHENEVER ERROR STOP
	RETURN
END IF
WHENEVER ERROR STOP
COMMIT WORK
CALL mostrar_registro(vm_r_rows[vm_row_current])
CALL fl_mostrar_mensaje('Presupuesto ha sido ACTIVADO. Ok', 'info')

END FUNCTION



FUNCTION control_imprimir_presupuesto(flag)
DEFINE flag		SMALLINT
DEFINE param		VARCHAR(100)
DEFINE mensaje		VARCHAR(200)

LET param = vg_codloc, ' ', rm_t20.t20_numpre
IF flag = 2 THEN
	LET param = param CLIPPED, ' A'
END IF
CALL ejecuta_comando('TALLER', vg_modulo, 'talp411 ', param)
IF flag = 2 THEN
	LET mensaje = 'Se generó el archivo presup_',
			rm_t20.t20_numpre USING "<<<<<<<&",
			'.wri en /acero/fobos/tmp'
	CALL fl_mostrar_mensaje(mensaje, 'info')
END IF

END FUNCTION



FUNCTION ver_orden()
DEFINE param		VARCHAR(100)

IF rm_t23.t23_orden IS NULL THEN
	CALL fl_mostrar_mensaje('El Presupuesto no ha sido convertido en OT.', 'exclamation')
        RETURN
END IF
LET param = vg_codloc, ' ', rm_t23.t23_orden, ' ', 'O', ' X'
CALL ejecuta_comando('TALLER', vg_modulo, 'talp204 ', param)
                                                                                
END FUNCTION



FUNCTION muestra_profromas_pr()
DEFINE param		VARCHAR(100)

IF rm_t20.t20_numpre IS NULL THEN
        CALL fl_mensaje_consultar_primero()
        RETURN
END IF
LET param = vg_codloc, ' ', rm_t20.t20_numpre, ' ', 'P'
CALL ejecuta_comando('TALLER', vg_modulo, 'talp213 ', param)

END FUNCTION



FUNCTION muestra_mano_obra_pr()
DEFINE param		VARCHAR(100)

IF rm_t20.t20_numpre IS NULL THEN
        CALL fl_mensaje_consultar_primero()
        RETURN
END IF
IF rm_t20.t20_total_mo = 0 AND rm_t20.t20_estado <> 'A' THEN
        CALL fl_mostrar_mensaje('No hay detalle de Mano Obra de Presupuesto.','exclamation')
        RETURN
END IF
LET param = vg_codloc, ' ', rm_t20.t20_numpre, ' ', rm_t20.t20_estado
CALL ejecuta_comando('TALLER', vg_modulo, 'talp202 ', param)
CALL mostrar_registro(vm_r_rows[vm_row_current])

END FUNCTION



FUNCTION imprimir_transferencia()
DEFINE r_r19		RECORD LIKE rept019.*
DEFINE resp		CHAR(6)
DEFINE param		VARCHAR(60)
DEFINE cuantos		INTEGER

SELECT COUNT(*) INTO cuantos FROM te_transf_gen
IF cuantos = 0 THEN
	RETURN
END IF
DECLARE q_imp_trans CURSOR FOR
	SELECT rept019.* FROM rept019, te_transf_gen
		WHERE r19_compania    = vg_codcia
		  AND r19_localidad   = vg_codloc
		  AND r19_cod_tran    = 'TR'
		  AND r19_ord_trabajo = rm_t23.t23_orden 
		  AND r19_cod_tran    = te_cod_tran
		  AND r19_num_tran    = te_num_tran
		ORDER BY r19_num_tran
OPEN q_imp_trans
FETCH q_imp_trans INTO r_r19.*
IF STATUS = NOTFOUND THEN
	CLOSE q_imp_trans
	FREE q_imp_trans
	RETURN
END IF
CALL fl_hacer_pregunta('Desea imprimir Transferencia generada ?','Yes')
	RETURNING resp
IF resp <> 'Yes' THEN
	CLOSE q_imp_trans
	FREE q_imp_trans
	RETURN
END IF
FOREACH q_imp_trans INTO r_r19.*
	LET param = vg_codloc, ' "', r_r19.r19_cod_tran, '" ',
			r_r19.r19_num_tran
	CALL ejecuta_comando('REPUESTOS', 'RE', 'repp415 ', param)
END FOREACH

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
LET comando = 'cd ..', vg_separador, '..', vg_separador, modulo,
		vg_separador, 'fuentes', vg_separador, run_prog, prog,
		vg_base, ' ', mod, ' ', vg_codcia, ' ', param
RUN comando

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
