------------------------------------------------------------------------------
-- Titulo           : rolp233.4gl - Acta de Finiquito
-- Elaboracion      : 09-dic-2003
-- Autor            : JCM
-- Formato Ejecucion: fglrun rolp233 base módulo compañía
-- Ultima Correccion: 
-- Motivo Correccion: 
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_num_rows	INTEGER
DEFINE vm_row_current	INTEGER
DEFINE vm_max_rows	INTEGER
DEFINE vm_r_rows	ARRAY [1000] OF INTEGER

DEFINE vm_proceso	LIKE rolt005.n05_proceso

DEFINE rm_n00		RECORD LIKE rolt000.*
DEFINE rm_n05		RECORD LIKE rolt005.*
DEFINE rm_n70		RECORD LIKE rolt070.*

DEFINE vm_filas_pant	INTEGER
DEFINE vm_numelm	INTEGER
DEFINE vm_maxelm	INTEGER
DEFINE rm_scr ARRAY[50] OF RECORD 
	n73_rubro			LIKE rolt073.n73_rubro,
	n73_valor			LIKE rolt073.n73_valor
END RECORD	



MAIN

DEFER QUIT 
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/rolp233')
CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 3 THEN          -- Validar # parámetros correcto
	CALL fgl_winmessage(vg_producto, 'Número de parámetros incorrecto', 'stop')
	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_proceso = 'rolp233'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
--#CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL control_master()

END MAIN



FUNCTION control_master()

DEFINE r_n01		RECORD LIKE rolt001.*
DEFINE query		VARCHAR(500)

CALL fl_nivel_isolation()
LET vm_max_rows	= 1000
LET vm_maxelm	= 50
LET vm_proceso	= 'AF'

OPEN WINDOW wf AT 3,2 WITH 22 ROWS, 80 COLUMNS
    ATTRIBUTE(FORM LINE FIRST + 2, COMMENT LINE LAST, MENU LINE 0,BORDER,
	      MESSAGE LINE LAST - 2)
OPTIONS INPUT WRAP,
	ACCEPT KEY	F12
OPEN FORM f_rol FROM "../forms/rolf233_1"
DISPLAY FORM f_rol
LET vm_num_rows = 0
LET vm_row_current = 0
CALL muestra_contadores(vm_row_current, vm_num_rows)

INITIALIZE rm_n00.* TO NULL
CALL fl_lee_parametro_general_roles() RETURNING rm_n00.*
IF rm_n00.n00_moneda_pago IS NULL THEN
	CALL fl_mostrar_mensaje('No se han configurado parametros generales de roles.', 'stop')
	EXIT PROGRAM
END IF

CALL fl_lee_compania_roles(vg_codcia) RETURNING r_n01.*
IF r_n01.n01_compania IS NULL THEN
        CALL fgl_winmessage(vg_producto,
                'No existe configuración para esta compañía.',
                'stop')
        EXIT PROGRAM
END IF
IF r_n01.n01_estado <> 'A' THEN
        CALL fgl_winmessage(vg_producto,
                'Compañía no está activa.', 'stop')
        EXIT PROGRAM
END IF

CALL fl_retorna_proceso_roles_activo(vg_codcia) RETURNING rm_n05.*

LET vm_num_rows = 0

-- Declaro el cursor para usarlo despues en varias partes del programa
DECLARE q_ultliq CURSOR FOR
	SELECT * FROM rolt032 WHERE n32_compania = vg_codcia
				AND n32_estado   = 'P'
			ORDER BY n32_fecha_fin DESC

LET query = 'SELECT rolt032.* FROM rolt032, rolt071 ',
		' WHERE n71_compania   = ? ', 
		'   AND n71_cod_trab   = ? ', 
		'   AND n71_serial     = ? ',
		'   AND n71_tipo_proc  = "L" ',          
		'   AND n32_compania   = n71_compania  ',
		'   AND n32_cod_liqrol = n71_proceso   ',
		'   AND n32_fecha_ini  = n71_fecha_ini ', 
		'   AND n32_fecha_fin  = n71_fecha_fin ',
		'   AND n32_cod_trab   = n71_cod_trab  ',
		'   AND n32_estado     = "F" '
PREPARE cons_liq FROM query
DECLARE q_liq CURSOR FOR cons_liq 


MENU 'OPCIONES'
	BEFORE MENU
		HIDE OPTION 'Avanzar'
		HIDE OPTION 'Retroceder'
		HIDE OPTION 'Modificar'
		HIDE OPTION 'Eliminar'
		HIDE OPTION 'Cerrar'
		HIDE OPTION 'Imprimir'
		IF rm_n05.n05_proceso = vm_proceso THEN
			HIDE OPTION 'Ingresar'
		ELSE
			IF rm_n05.n05_proceso IS NOT NULL THEN
				HIDE OPTION 'Ingresar'
			END IF
			HIDE OPTION 'Modificar'
			HIDE OPTION 'Eliminar'
			HIDE OPTION 'Cerrar'
		END IF
	COMMAND KEY('I') 'Ingresar' 'Ingresar nuevos registros. '
		CALL control_ingreso()
		IF vm_num_rows = 1 THEN
			SHOW OPTION 'Modificar'
			SHOW OPTION 'Eliminar'
			SHOW OPTION 'Cerrar'
		END IF
		IF vm_row_current > 1 THEN
			SHOW OPTION 'Retroceder'
		END IF
		IF vm_row_current = vm_num_rows THEN
			HIDE OPTION 'Avanzar'
		END IF
		IF rm_n05.n05_proceso IS NOT NULL THEN
			HIDE OPTION 'Ingresar'
			SHOW OPTION 'Modificar'
			SHOW OPTION 'Eliminar'
			SHOW OPTION 'Cerrar'
			SHOW OPTION 'Imprimir'
		END IF
       	COMMAND KEY('M') 'Modificar' 'Modificar registro corriente. '
		CALL control_modificacion()
       	COMMAND KEY('E') 'Eliminar' 'Elimina registro corriente. '
		CALL control_eliminacion()
		IF rm_n05.n05_proceso IS NULL THEN
			SHOW OPTION 'Ingresar'
			HIDE OPTION 'Modificar'
			HIDE OPTION 'Eliminar'
			HIDE OPTION 'Cerrar'
		END IF
		IF vm_num_rows > 0 THEN
			SHOW OPTION 'Imprimir'
		END IF
       	COMMAND KEY('U') 'Cerrar' 'Cierra el rol activo. '
		CALL control_cerrar()
		IF rm_n05.n05_proceso IS NULL THEN
			SHOW OPTION 'Ingresar'
			HIDE OPTION 'Modificar'
			HIDE OPTION 'Eliminar'
			HIDE OPTION 'Cerrar'
		END IF
	COMMAND KEY('C') 'Consultar' 'Consultar un registro. '
		CALL control_consulta()
		IF vm_num_rows <= 1 THEN
			HIDE OPTION 'Avanzar'
			HIDE OPTION 'Retroceder'
			IF vm_num_rows = 0 THEN
				HIDE OPTION 'Modificar'
				HIDE OPTION 'Eliminar'
				HIDE OPTION 'Cerrar'
			END IF
		ELSE
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Modificar'
			SHOW OPTION 'Eliminar'
			SHOW OPTION 'Cerrar'
		END IF
		IF vm_row_current <= 1 THEN
                        HIDE OPTION 'Retroceder'
                END IF
		IF rm_n70.n70_estado = 'A' THEN
			SHOW OPTION 'Modificar'
			SHOW OPTION 'Eliminar'
			SHOW OPTION 'Cerrar'
		ELSE
			HIDE OPTION 'Modificar'
			HIDE OPTION 'Eliminar'
			HIDE OPTION 'Cerrar'
		END IF
		IF vm_num_rows > 0 THEN
			SHOW OPTION 'Imprimir'
		END IF
	COMMAND KEY('D') 'Detalle Valores' 'Permite ver el detalle de los valores.'
		CALL ver_submenu('C')
	COMMAND KEY('I') 'Imprimir' 'Imprime un registro. '
		CALL control_imprimir()
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
		IF rm_n70.n70_estado = 'A' THEN
			SHOW OPTION 'Modificar'
			SHOW OPTION 'Eliminar'
			SHOW OPTION 'Cerrar'
		ELSE
			HIDE OPTION 'Modificar'
			HIDE OPTION 'Eliminar'
			HIDE OPTION 'Cerrar'
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
		IF rm_n70.n70_estado = 'A' THEN
			SHOW OPTION 'Modificar'
			SHOW OPTION 'Eliminar'
			SHOW OPTION 'Cerrar'
		ELSE
			HIDE OPTION 'Modificar'
			HIDE OPTION 'Eliminar'
			HIDE OPTION 'Cerrar'
		END IF
	COMMAND KEY('S') 'Salir' 'Salir del programa. '
		EXIT MENU
END MENU

END FUNCTION



FUNCTION control_ingreso()
DEFINE r_n32			RECORD LIKE rolt032.*
DEFINE r_n36			RECORD LIKE rolt036.*
DEFINE r_n74			RECORD LIKE rolt074.*

DEFINE resp			VARCHAR(6)

CLEAR FORM

INITIALIZE rm_n70.* TO NULL

CALL fl_retorna_proceso_roles_activo(vg_codcia) RETURNING rm_n05.*
IF rm_n05.n05_compania IS NOT NULL THEN
	CALL fl_mostrar_mensaje('Ya existe un proceso de roles activo.', 'stop')
	RETURN
END IF

LET rm_n70.n70_compania  = vg_codcia
LET rm_n70.n70_serial    = 0 
LET rm_n70.n70_calc_comi = 'N'
LET rm_n70.n70_fecing    = CURRENT
LET rm_n70.n70_moneda    = rm_n00.n00_moneda_pago
LET rm_n70.n70_paridad   = 1 
LET rm_n70.n70_estado    = 'A'
LET rm_n70.n70_usuario   = vg_usuario
LET rm_n70.n70_fec_ren   = TODAY

LET rm_n70.n70_mes_prom      = 0
LET rm_n70.n70_prom_comi     = 0
LET rm_n70.n70_comisiones    = 0
LET rm_n70.n70_tot_rol       = 0
LET rm_n70.n70_tot_dt        = 0
LET rm_n70.n70_tot_dc        = 0
LET rm_n70.n70_tot_vaca      = 0
LET rm_n70.n70_tot_otros     = 0
LET rm_n70.n70_tot_anticipos = 0
LET rm_n70.n70_ult_sueldo    = 0
LET rm_n70.n70_antiguedad    = 0
LET rm_n70.n70_porc_bonif    = 0
LET rm_n70.n70_porc_indem    = 0
LET rm_n70.n70_bonificacion  = 0
LET rm_n70.n70_indemnizacion = 0
LET rm_n70.n70_tot_neto      = 0

CALL leer_datos()
IF int_flag THEN
	CLEAR FORM
	IF vm_row_current > 0 THEN
		CALL mostrar_registro(vm_r_rows[vm_row_current])
	END IF
	RETURN	
END IF

CALL fl_mensaje_seguro_ejecutar_proceso() RETURNING resp
IF resp <> 'Yes' THEN
	IF vm_num_rows > 0 AND vm_row_current > 0 THEN
		CALL mostrar_registro(vm_r_rows[vm_num_rows])	
	ELSE
		CLEAR FORM
	END IF
	RETURN	
END IF

BEGIN WORK

INITIALIZE rm_n05.* TO NULL
SELECT * INTO rm_n05.* FROM rolt005 WHERE n05_compania = vg_codcia
				      AND n05_proceso  = vm_proceso
IF rm_n05.n05_proceso IS NULL THEN
	LET rm_n05.n05_compania   = vg_codcia
	LET rm_n05.n05_proceso    = vm_proceso
	LET rm_n05.n05_activo     = 'S'
	LET rm_n05.n05_fecini_act = CURRENT
	LET rm_n05.n05_fecfin_act = CURRENT
	LET rm_n05.n05_fec_ultcie = CURRENT
	LET rm_n05.n05_fec_cierre = CURRENT
	LET rm_n05.n05_usuario    = vg_usuario
	LET rm_n05.n05_fecing     = CURRENT

	INSERT INTO rolt005 VALUES (rm_n05.*) 
ELSE
	UPDATE rolt005 SET n05_activo = 'S'
		WHERE n05_compania = vg_codcia
	 	  AND n05_proceso  = vm_proceso
END IF
INSERT INTO rolt070 VALUES (rm_n70.*)

IF vm_num_rows = vm_max_rows THEN
	LET vm_num_rows = 1
ELSE
	LET vm_num_rows = vm_num_rows + 1
END IF
LET vm_row_current = vm_num_rows
LET vm_r_rows[vm_row_current] = SQLCA.SQLERRD[6] 

LET rm_n70.n70_serial = SQLCA.SQLERRD[2]

COMMIT WORK

UPDATE rolt030 SET n30_fecha_sal = rm_n70.n70_fec_sal 
		WHERE n30_compania = vg_codcia 
		  AND n30_cod_trab = rm_n70.n70_cod_trab 
INITIALIZE r_n32.* TO NULL
OPEN  q_ultliq
FETCH q_ultliq INTO r_n32.*
IF (rm_n70.n70_fec_sal > r_n32.n32_fecha_ini) AND 
   (rm_n70.n70_fec_sal < r_n32.n32_fecha_fin)
THEN
	LET rm_n70.n70_tot_rol = 0 
ELSE
	CALL generar_liquidacion_roles(rm_n70.n70_cod_trab) RETURNING r_n32.*
	IF r_n32.n32_compania IS NULL THEN
		CALL fl_mostrar_mensaje('No pudo generar liquidacion de roles, realize el acta de finiquito cuando el empleado efectivamente vaya a salir para calcular correctamente los valores a pagarle.',
					'stop')
		DELETE FROM rolt070 WHERE n70_compania = vg_codcia
				      AND n70_cod_trab = rm_n70.n70_cod_trab
				      AND n70_serial   = rm_n70.n70_serial
		UPDATE rolt005 SET n05_activo = 'N'
			WHERE n05_compania = vg_codcia
			  AND n05_proceso  = rm_n05.n05_proceso
			  AND n05_activo   = 'S'
		UPDATE rolt030 SET n30_fecha_sal = NULL 
			WHERE n30_compania = vg_codcia 
			  AND n30_cod_trab = rm_n70.n70_cod_trab 
		EXIT PROGRAM
	END IF
	UPDATE rolt032 SET n32_dias_trab = rm_n70.n70_fec_sal - n32_fecha_ini
		WHERE n32_compania   = r_n32.n32_compania
		  AND n32_cod_liqrol = r_n32.n32_cod_liqrol
		  AND n32_fecha_ini  = r_n32.n32_fecha_ini 
		  AND n32_fecha_fin  = r_n32.n32_fecha_fin 
		  AND n32_cod_trab   = r_n32.n32_cod_trab
	CALL calculo_liquidacion(rm_n70.n70_cod_trab) RETURNING r_n32.*
	LET rm_n70.n70_tot_rol = r_n32.n32_tot_ing - r_n32.n32_tot_egr
	INSERT INTO rolt071 VALUES (r_n32.n32_compania,  r_n32.n32_cod_trab,
				    rm_n70.n70_serial,   r_n32.n32_cod_liqrol,
	                            r_n32.n32_fecha_ini, r_n32.n32_fecha_fin,
				    'L')
END IF
CLOSE q_ultliq

CALL generar_decimo_tercero(rm_n70.n70_cod_trab) RETURNING r_n36.*
LET rm_n70.n70_tot_dt = r_n36.n36_valor_neto 
INSERT INTO rolt071 VALUES (r_n36.n36_compania,  r_n36.n36_cod_trab,
			    rm_n70.n70_serial,   r_n36.n36_proceso,
                            r_n36.n36_fecha_ini, r_n36.n36_fecha_fin,
			    'D')

CALL generar_decimo_cuarto(rm_n70.n70_cod_trab) RETURNING r_n36.*
LET rm_n70.n70_tot_dc = r_n36.n36_valor_neto 
INSERT INTO rolt071 VALUES (r_n36.n36_compania,  r_n36.n36_cod_trab,
			    rm_n70.n70_serial,   r_n36.n36_proceso,
                            r_n36.n36_fecha_ini, r_n36.n36_fecha_fin,
			    'D')

-- OjO Falta anadir vacaciones

BEGIN WORK

LET rm_n70.n70_tot_anticipos = obtiene_anticipos(rm_n70.n70_cod_trab) 

CALL fl_lee_motivo_salida_trabajador(rm_n70.n70_motivo) RETURNING r_n74.*
LET rm_n70.n70_porc_bonif = r_n74.n74_porc_bonif
LET rm_n70.n70_porc_indem = r_n74.n74_porc_indem

LET rm_n70.n70_ult_sueldo = r_n32.n32_sueldo

CALL calcula_bonif_indem(rm_n70.*, r_n74.*) RETURNING rm_n70.* 

LET rm_n70.n70_tot_neto = calcula_total_neto(rm_n70.*)

UPDATE rolt070 SET n70_tot_rol       = rm_n70.n70_tot_rol,
		   n70_tot_dt        = rm_n70.n70_tot_dt, 
		   n70_tot_dc        = rm_n70.n70_tot_dc, 
		   n70_tot_vaca      = rm_n70.n70_tot_vaca, 
		   n70_tot_otros     = rm_n70.n70_tot_otros,
		   n70_prom_comi     = rm_n70.n70_prom_comi,
		   n70_tot_anticipos = rm_n70.n70_tot_anticipos,
		   n70_ult_sueldo    = rm_n70.n70_ult_sueldo, 
		   n70_antiguedad    = rm_n70.n70_antiguedad, 
		   n70_porc_bonif    = rm_n70.n70_porc_bonif,
		   n70_porc_indem    = rm_n70.n70_porc_indem,
		   n70_bonificacion  = rm_n70.n70_bonificacion,
		   n70_indemnizacion = rm_n70.n70_indemnizacion,
		   n70_tot_neto      = rm_n70.n70_tot_neto     
	WHERE n70_compania = rm_n70.n70_compania
	  AND n70_cod_trab = rm_n70.n70_cod_trab
	  AND n70_serial   = rm_n70.n70_serial  

COMMIT WORK

CALL fl_retorna_proceso_roles_activo(vg_codcia) RETURNING rm_n05.*
LET vm_numelm = 0

CALL mostrar_registro(vm_r_rows[vm_num_rows])	
CALL muestra_contadores(vm_row_current, vm_num_rows)
CALL fl_mensaje_registro_ingresado()

END FUNCTION



FUNCTION control_modificacion()

DEFINE r_n32		RECORD LIKE rolt032.*
DEFINE r_n36		RECORD LIKE rolt036.*
DEFINE r_n70		RECORD LIKE rolt070.*
DEFINE r_n74		RECORD LIKE rolt074.*
DEFINE resp 		CHAR(6)

IF vm_num_rows = 0 THEN
	CALL fl_mensaje_consultar_primero()
	RETURN
END IF
CALL mostrar_registro(vm_r_rows[vm_row_current])

IF rm_n70.n70_estado = 'P' THEN
	CALL fl_mostrar_mensaje('Esta acta de finiquito ya ha sido procesada.', 'stop')
	RETURN
END IF

BEGIN WORK
WHENEVER ERROR CONTINUE
DECLARE q_up CURSOR FOR SELECT * FROM rolt070
	WHERE ROWID = vm_r_rows[vm_row_current]
	FOR UPDATE
OPEN q_up
FETCH q_up INTO rm_n70.*
IF STATUS < 0 THEN
	ROLLBACK WORK
	WHENEVER ERROR STOP
	CALL fl_mensaje_bloqueo_otro_usuario()
	RETURN
END IF
WHENEVER ERROR STOP

CALL fl_hacer_pregunta('Desea modificar los datos de esta acta de finiquito.',
	'No') RETURNING resp
IF resp = 'Yes' THEN
	CALL leer_datos()
	IF int_flag THEN
		ROLLBACK WORK
		CLEAR FORM
		IF vm_row_current > 0 THEN
			CALL mostrar_registro(vm_r_rows[vm_row_current])
		END IF
		RETURN
	END IF

	CLOSE q_up
END IF
COMMIT WORK

CALL ver_submenu('M')

BEGIN WORK
WHENEVER ERROR CONTINUE
DECLARE q_up2 CURSOR FOR SELECT * FROM rolt070
	WHERE ROWID = vm_r_rows[vm_row_current]
	FOR UPDATE
OPEN q_up2
FETCH q_up2 INTO r_n70.*
IF STATUS < 0 THEN
	ROLLBACK WORK
	WHENEVER ERROR STOP
	CALL fl_mensaje_bloqueo_otro_usuario()
	RETURN
END IF
WHENEVER ERROR STOP

CALL fl_lee_motivo_salida_trabajador(rm_n70.n70_motivo) RETURNING r_n74.*
LET rm_n70.n70_porc_bonif = r_n74.n74_porc_bonif
LET rm_n70.n70_porc_indem = r_n74.n74_porc_indem
CALL calcula_bonif_indem(rm_n70.*, r_n74.*) RETURNING rm_n70.* 
LET rm_n70.n70_tot_neto = calcula_total_neto(rm_n70.*)
DISPLAY BY NAME rm_n70.n70_bonificacion, rm_n70.n70_indemnizacion, 
		rm_n70.n70_tot_neto

UPDATE rolt070 SET * = rm_n70.* WHERE CURRENT OF q_up2

CALL graba_detalle()

COMMIT WORK

CALL fl_mensaje_registro_modificado()

END FUNCTION



FUNCTION control_imprimir()
{
DEFINE comando 		VARCHAR(255)

	LET comando = 'fglrun rolp415 ', vg_base, ' ', vg_modulo,
                      ' ', vg_codcia, ' ', rm_n70.n70_num_rol

	RUN comando
}                     
END FUNCTION



FUNCTION control_eliminacion()
DEFINE r_n70		RECORD LIKE rolt070.*
DEFINE r_n71		RECORD LIKE rolt071.*
DEFINE resp		VARCHAR(6)

IF vm_num_rows = 0 THEN
	CALL fl_mensaje_consultar_primero()
	RETURN
END IF
CALL mostrar_registro(vm_r_rows[vm_row_current])

IF rm_n70.n70_estado = 'P' THEN
	CALL fl_mostrar_mensaje('Este rol ya ha sido procesado.', 'stop')
	RETURN
END IF

CALL fl_mensaje_seguro_ejecutar_proceso() RETURNING resp
IF resp = 'No' THEN
        LET int_flag = 0
        RETURN
END IF

BEGIN WORK

WHENEVER ERROR CONTINUE
DECLARE q_del CURSOR FOR SELECT * FROM rolt070
        WHERE ROWID = vm_r_rows[vm_row_current]
        FOR UPDATE
OPEN q_del
FETCH q_del INTO r_n70.*
IF STATUS < 0 THEN
        ROLLBACK WORK
        WHENEVER ERROR STOP
        CALL fl_mensaje_bloqueo_otro_usuario()
        RETURN
END IF
WHENEVER ERROR STOP

DECLARE q_hijos CURSOR FOR 
	SELECT * FROM rolt071
		WHERE n71_compania  = vg_codcia
		  AND n71_cod_trab  = r_n70.n70_cod_trab
		  AND n71_serial    = r_n70.n70_serial   

FOREACH q_hijos INTO r_n71.*
	CASE r_n71.n71_tipo_proc
		WHEN 'L'
			DELETE FROM rolt033 
				WHERE n33_compania   = r_n71.n71_compania
			      	  AND n33_cod_liqrol = r_n71.n71_proceso
			      	  AND n33_fecha_ini  = r_n71.n71_fecha_ini  
			      	  AND n33_fecha_fin  = r_n71.n71_fecha_fin
				  AND n33_cod_trab   = r_n71.n71_cod_trab

			DELETE FROM rolt032 
				WHERE n32_compania   = r_n71.n71_compania
			      	  AND n32_cod_liqrol = r_n71.n71_proceso
			      	  AND n32_fecha_ini  = r_n71.n71_fecha_ini  
			      	  AND n32_fecha_fin  = r_n71.n71_fecha_fin
				  AND n32_cod_trab   = r_n71.n71_cod_trab
				  AND n32_estado     = 'F'
		WHEN 'D'
			DELETE FROM rolt036 
				WHERE n36_compania   = r_n71.n71_compania
			      	  AND n36_proceso    = r_n71.n71_proceso
			      	  AND n36_fecha_ini  = r_n71.n71_fecha_ini  
			      	  AND n36_fecha_fin  = r_n71.n71_fecha_fin
				  AND n36_cod_trab   = r_n71.n71_cod_trab
				  AND n36_estado     = 'F'
		WHEN 'V'
			DELETE FROM rolt055 
				WHERE n55_compania    = r_n71.n71_compania
				  AND n55_cod_trab    = r_n71.n71_cod_trab
			      	  AND n36_periodo_ini = r_n71.n71_fecha_ini  
			      	  AND n36_periodo_fin = r_n71.n71_fecha_fin

			DELETE FROM rolt040 
				WHERE n40_compania    = r_n71.n71_compania
				  AND n40_cod_trab    = r_n71.n71_cod_trab
			      	  AND n40_periodo_ini = r_n71.n71_fecha_ini  
			      	  AND n40_periodo_fin = r_n71.n71_fecha_fin

			DELETE FROM rolt039 
				WHERE n39_compania    = r_n71.n71_compania
				  AND n39_cod_trab    = r_n71.n71_cod_trab
			      	  AND n39_periodo_ini = r_n71.n71_fecha_ini  
			      	  AND n39_periodo_fin = r_n71.n71_fecha_fin
				  AND n39_estado      = 'F'
	END CASE
END FOREACH

DELETE FROM rolt071 WHERE n71_compania  = vg_codcia
		      AND n71_cod_trab  = r_n70.n70_cod_trab
		      AND n71_serial    = r_n70.n70_serial   

DELETE FROM rolt072 WHERE n72_compania  = vg_codcia
		      AND n72_cod_trab  = r_n70.n70_cod_trab
		      AND n72_serial    = r_n70.n70_serial   

DELETE FROM rolt073 WHERE n73_compania  = vg_codcia
		      AND n73_cod_trab  = r_n70.n70_cod_trab
		      AND n73_serial    = r_n70.n70_serial   

DELETE FROM rolt070 WHERE CURRENT OF q_del
CLOSE q_del

UPDATE rolt030 SET n30_fecha_sal = NULL 
		WHERE n30_compania = vg_codcia 
		  AND n30_cod_trab = rm_n70.n70_cod_trab 

UPDATE rolt005 SET n05_activo = 'N'
	WHERE n05_compania = vg_codcia
	  AND n05_proceso  = rm_n05.n05_proceso
	  AND n05_activo   = 'S'

COMMIT WORK

INITIALIZE rm_n05.* TO NULL
INITIALIZE rm_n70.* TO NULL

CLEAR FORM

LET vm_num_rows = vm_num_rows - 1
IF vm_row_current > 1 THEN
	LET vm_row_current = 1
ELSE
	LET vm_row_current = vm_row_current - 1
END IF

CALL muestra_contadores(vm_row_current, vm_num_rows)

CALL fl_mensaje_registro_modificado()
END FUNCTION



FUNCTION control_cerrar()

DEFINE r_n70		RECORD LIKE rolt070.*
DEFINE r_n72		RECORD LIKE rolt072.*
DEFINE resp		VARCHAR(6)

IF vm_num_rows = 0 THEN
	CALL fl_mensaje_consultar_primero()
	RETURN
END IF
CALL mostrar_registro(vm_r_rows[vm_row_current])

IF rm_n70.n70_estado = 'P' THEN
	CALL fl_mostrar_mensaje('Este rol ya ha sido procesado.', 'stop')
	RETURN
END IF

CALL fl_mensaje_seguro_ejecutar_proceso() RETURNING resp
IF resp = 'No' THEN
        LET int_flag = 0
        RETURN
END IF

BEGIN WORK

CALL cerrar_liquidacion(rm_n70.n70_cod_trab)
CALL cerrar_decimos(rm_n70.*)
CALL cerrar_vacaciones()

WHENEVER ERROR CONTINUE
DECLARE q_cerr CURSOR FOR SELECT * FROM rolt070
        WHERE ROWID = vm_r_rows[vm_row_current]
        FOR UPDATE
OPEN q_cerr
FETCH q_cerr INTO r_n70.*
IF STATUS < 0 THEN
        ROLLBACK WORK
        WHENEVER ERROR STOP
        CALL fl_mensaje_bloqueo_otro_usuario()
        RETURN
END IF
WHENEVER ERROR STOP

DECLARE q_prest CURSOR FOR SELECT * FROM rolt072
				WHERE n72_compania = vg_codcia
				  AND n72_cod_trab = rm_n70.n70_cod_trab
				  AND n72_serial   = rm_n70.n70_serial  

FOREACH q_prest INTO r_n72.*
	UPDATE rolt046 SET n46_saldo = 0
		WHERE n46_compania  = vg_codcia
		  AND n46_num_prest = r_n72.n72_num_prest

	UPDATE rolt045 SET n45_estado = 'P', n45_descontado = n45_val_prest
		WHERE n45_compania  = vg_codcia
		  AND n45_num_prest = r_n72.n72_num_prest
END FOREACH

UPDATE rolt070 SET n70_estado = 'P' WHERE CURRENT OF q_cerr
UPDATE rolt030 SET n30_estado = 'I', n30_fecha_sal = rm_n70.n70_fec_sal 
		WHERE n30_compania = vg_codcia 
		  AND n30_cod_trab = rm_n70.n70_cod_trab 
UPDATE rolt005 SET n05_activo = 'N'
	WHERE n05_compania = vg_codcia
	  AND n05_proceso  = rm_n05.n05_proceso
	  AND n05_activo   = 'S'

COMMIT WORK

CALL fl_retorna_proceso_roles_activo(vg_codcia) RETURNING rm_n05.*

CALL mostrar_registro(vm_r_rows[vm_num_rows])	
CALL muestra_contadores(vm_row_current, vm_num_rows)
CALL fl_mensaje_registro_modificado()

END FUNCTION



FUNCTION control_consulta()

DEFINE query		VARCHAR(400)
DEFINE expr_sql		VARCHAR(400)
DEFINE num_reg		INTEGER
DEFINE r_n30		RECORD LIKE rolt030.*
DEFINE r_n70		RECORD LIKE rolt070.*

INITIALIZE rm_n70.* TO NULL
LET int_flag = 0
CLEAR FORM
CONSTRUCT BY NAME expr_sql ON n70_cod_trab, n70_estado
	ON KEY(F2)
		IF infield(n70_cod_trab) THEN
			CALL fl_ayuda_codigo_empleado(vg_codcia) 
				RETURNING r_n30.n30_cod_trab,
					  r_n30.n30_nombres
			IF r_n30.n30_cod_trab IS NOT NULL THEN
				LET rm_n70.n70_cod_trab = r_n30.n30_cod_trab
				DISPLAY BY NAME rm_n70.n70_cod_trab, 
						r_n30.n30_nombres  
			END IF
		END IF
		LET int_flag = 0
END CONSTRUCT
IF int_flag THEN
	IF vm_row_current > 0 THEN
		CALL mostrar_registro(vm_r_rows[vm_row_current])
	ELSE
		CLEAR FORM
		INITIALIZE rm_n70.* TO NULL
	END IF
	RETURN
END IF

LET query = 'SELECT *, ROWID FROM rolt070 ', 
		' WHERE n70_compania = ', vg_codcia,
		'   AND ', expr_sql, ' ORDER BY 1, 2'
PREPARE cons FROM query	
DECLARE q_cons CURSOR FOR cons
LET vm_num_rows = 0
FOREACH q_cons INTO r_n70.*, num_reg
	LET vm_num_rows = vm_num_rows + 1
        IF vm_num_rows > vm_max_rows THEN
		LET vm_num_rows = vm_num_rows - 1
                EXIT FOREACH
        END IF
	LET vm_r_rows[vm_num_rows] = num_reg
END FOREACH
IF vm_num_rows = 0 THEN
	LET int_flag = 0
	INITIALIZE rm_n70.* TO NULL
	CALL fl_mensaje_consulta_sin_registros()
	CLEAR FORM
	LET vm_row_current = 0
ELSE  
	LET vm_row_current = 1
	CALL mostrar_registro(vm_r_rows[vm_row_current])
	CALL muestra_contadores(vm_row_current, vm_num_rows)
END IF

END FUNCTION



FUNCTION leer_datos()
DEFINE resp		CHAR(6)
DEFINE r_n30		RECORD LIKE rolt030.*
DEFINE r_n74		RECORD LIKE rolt074.*

DEFINE check		CHAR(1)

LET int_flag = 0
INITIALIZE r_n74.* TO NULL
INPUT BY NAME rm_n70.n70_cod_trab, rm_n70.n70_motivo,    rm_n70.n70_fec_ren,
	      rm_n70.n70_fec_sal,  rm_n70.n70_calc_comi, rm_n70.n70_mes_prom,
	      rm_n70.n70_estado,   rm_n70.n70_comisiones 
              WITHOUT DEFAULTS
	BEFORE INPUT 
		DISPLAY 'ACTIVO' TO n_estado
	ON KEY(INTERRUPT)
        	IF field_touched(n70_fec_ren, n70_fec_sal, n70_calc_comi,
				 n70_mes_prom, n70_cod_trab
				) THEN
               		LET int_flag = 0
			CALL fl_mensaje_abandonar_proceso()
        	        	RETURNING resp
              		IF resp = 'Yes' THEN
				LET int_flag = 1
	                       	CLEAR FORM
        	               	RETURN
                	END IF
		ELSE
			RETURN
		END IF
	ON KEY(F2)
		IF infield(n70_cod_trab) THEN
			CALL fl_ayuda_codigo_empleado(vg_codcia) 
				RETURNING r_n30.n30_cod_trab,
					  r_n30.n30_nombres
			IF r_n30.n30_cod_trab IS NOT NULL THEN
				LET rm_n70.n70_cod_trab = r_n30.n30_cod_trab
				DISPLAY BY NAME rm_n70.n70_cod_trab, 
						r_n30.n30_nombres  
			END IF
		END IF
		IF infield(n70_motivo) THEN
			CALL fl_ayuda_motivos_salida_trabajador() 
				RETURNING r_n74.n74_serial,
					  r_n74.n74_descripcion
			IF r_n74.n74_serial IS NOT NULL THEN
				LET rm_n70.n70_motivo = r_n74.n74_serial
				DISPLAY BY NAME rm_n70.n70_motivo, 
						r_n74.n74_descripcion  
			END IF
		END IF
		LET int_flag = 0
	AFTER FIELD n70_cod_trab
		IF rm_n70.n70_cod_trab IS NOT NULL THEN
			CALL fl_lee_trabajador_roles(vg_codcia, rm_n70.n70_cod_trab)
                        	RETURNING r_n30.*
			IF r_n30.n30_compania IS NULL THEN
				CALL fgl_winmessage(vg_producto,'Codigo de trabajador no existe.','exclamation')
				NEXT FIELD n70_cod_trab
			END IF
			IF r_n30.n30_estado = 'I' THEN
				CALL fgl_winmessage(vg_producto,'Trabajador esta inactivo.','exclamation')
				NEXT FIELD n70_cod_trab
			END IF
			LET rm_n70.n70_fec_ing = r_n30.n30_fecha_ing
			DISPLAY BY NAME r_n30.n30_nombres
		ELSE
			CLEAR n30_nombres
		END IF
	AFTER FIELD n70_comisiones
		IF rm_n70.n70_comisiones IS NULL THEN
			LET rm_n70.n70_comisiones = 0
		END IF
		IF rm_n70.n70_comisiones < 0 THEN
			CALL fl_mostrar_mensaje('No puede ingresar valores negativos.', 'exclamation')
			NEXT FIELD n70_comisiones
		END IF
		LET rm_n70.n70_tot_neto = calcula_total_neto(rm_n70.*)
		DISPLAY BY NAME rm_n70.n70_comisiones, rm_n70.n70_tot_neto
	AFTER FIELD n70_motivo
		IF rm_n70.n70_motivo IS NULL THEN
			CLEAR n74_descripcion
			CONTINUE INPUT
		END IF
		CALL fl_lee_motivo_salida_trabajador(rm_n70.n70_motivo)
                        	RETURNING r_n74.*
		IF r_n74.n74_serial IS NULL THEN
			CALL fl_mostrar_mensaje('C¢digo de motivo de salida incorrecto.', 'exclamation')
			CLEAR n74_descripcion
			CONTINUE INPUT
		END IF
		IF rm_n70.n70_fec_ren IS NOT NULL AND rm_n70.n70_fec_sal IS NULL
		THEN
			LET rm_n70.n70_fec_sal = 
				rm_n70.n70_fec_ren + r_n74.n74_dias_salida
		END IF
		LET rm_n70.n70_porc_bonif = r_n74.n74_porc_bonif
		LET rm_n70.n70_porc_indem = r_n74.n74_porc_indem

		CALL calcula_bonif_indem(rm_n70.*, r_n74.*) RETURNING rm_n70.* 
		LET rm_n70.n70_tot_neto = calcula_total_neto(rm_n70.*)
		DISPLAY BY NAME rm_n70.n70_motivo, r_n74.n74_descripcion,
				rm_n70.n70_fec_sal, rm_n70.n70_bonificacion,
				rm_n70.n70_indemnizacion,
		                rm_n70.n70_tot_neto
	AFTER FIELD n70_fec_ren
		IF rm_n70.n70_fec_sal IS NULL THEN
			LET rm_n70.n70_fec_sal = 
				rm_n70.n70_fec_ren + r_n74.n74_dias_salida
		END IF
		CALL calcula_bonif_indem(rm_n70.*, r_n74.*) RETURNING rm_n70.* 
		LET rm_n70.n70_tot_neto = calcula_total_neto(rm_n70.*)
		DISPLAY BY NAME rm_n70.n70_bonificacion,
				rm_n70.n70_indemnizacion,
		                rm_n70.n70_tot_neto
	AFTER FIELD n70_fec_sal
		IF rm_n70.n70_fec_sal IS NULL THEN
			LET rm_n70.n70_fec_sal = 
				rm_n70.n70_fec_ren + r_n74.n74_dias_salida
		ELSE
			IF rm_n70.n70_fec_sal < rm_n70.n70_fec_ren THEN
				CALL fl_mostrar_mensaje('La fecha de salida ' ||
					'debe ser mayor a la' ||
					' fecha de notificaci¢n.', 
					'exclamation')
				NEXT FIELD n70_fec_sal
			END IF
		END IF
		IF valida_fecha_salida(rm_n70.n70_fec_sal) = 0 THEN
			NEXT FIELD n70_fec_sal
		END IF
		CALL calcula_bonif_indem(rm_n70.*, r_n74.*) RETURNING rm_n70.* 
		LET rm_n70.n70_tot_neto = calcula_total_neto(rm_n70.*)
		DISPLAY BY NAME rm_n70.n70_bonificacion,
				rm_n70.n70_indemnizacion,
		                rm_n70.n70_tot_neto
	BEFORE FIELD n70_calc_comi
		LET check = rm_n70.n70_calc_comi
	AFTER FIELD n70_calc_comi
		IF check <> rm_n70.n70_calc_comi THEN
			LET rm_n70.n70_mes_prom = 0
			DISPLAY BY NAME rm_n70.n70_mes_prom
		END IF
		CALL calcula_bonif_indem(rm_n70.*, r_n74.*) RETURNING rm_n70.* 
		LET rm_n70.n70_tot_neto = calcula_total_neto(rm_n70.*)
		DISPLAY BY NAME rm_n70.n70_bonificacion,
				rm_n70.n70_indemnizacion,
		                rm_n70.n70_tot_neto
	BEFORE FIELD n70_mes_prom
		IF rm_n70.n70_calc_comi = 'N' THEN
			LET rm_n70.n70_mes_prom = 0 
			DISPLAY BY NAME rm_n70.n70_mes_prom
			NEXT FIELD n70_cod_trab
		END IF 
	AFTER FIELD n70_mes_prom
		CALL calcula_bonif_indem(rm_n70.*, r_n74.*) RETURNING rm_n70.* 
		LET rm_n70.n70_tot_neto = calcula_total_neto(rm_n70.*)
		DISPLAY BY NAME rm_n70.n70_bonificacion,
				rm_n70.n70_indemnizacion,
		                rm_n70.n70_tot_neto
	AFTER INPUT
		IF valida_fecha_salida(rm_n70.n70_fec_sal) = 0 THEN
			NEXT FIELD n70_fec_sal
		END IF
		CALL calcula_bonif_indem(rm_n70.*, r_n74.*) RETURNING rm_n70.* 
		LET rm_n70.n70_tot_neto = calcula_total_neto(rm_n70.*)
		DISPLAY BY NAME rm_n70.n70_bonificacion,
				rm_n70.n70_indemnizacion,
		                rm_n70.n70_tot_neto
END INPUT

END FUNCTION



FUNCTION graba_detalle()

DEFINE i 		INTEGER
DEFINE r_n30		RECORD LIKE rolt030.*
DEFINE r_n73		RECORD LIKE rolt073.*

DELETE FROM rolt073 WHERE n73_compania = rm_n70.n70_compania  
		      AND n73_cod_trab = rm_n70.n70_cod_trab
		      AND n73_serial   = rm_n70.n70_serial

IF vm_numelm = 0 THEN
	RETURN
END IF

FOR i = 1 TO vm_numelm
	IF rm_scr[i].n73_valor = 0 OR rm_scr[i].n73_valor IS NULL THEN
		CONTINUE FOR
	END IF

	INITIALIZE r_n73.* TO NULL
	LET r_n73.n73_compania    = vg_codcia
	LET r_n73.n73_cod_trab    = rm_n70.n70_cod_trab
	LET r_n73.n73_serial      = rm_n70.n70_serial
	LET r_n73.n73_secuencia   = i
	LET r_n73.n73_rubro       = rm_scr[i].n73_rubro
	LET r_n73.n73_valor       = rm_scr[i].n73_valor

	INSERT INTO rolt073 VALUES (r_n73.*)
END FOR

END FUNCTION



FUNCTION ingresar_otros()

DEFINE i                INTEGER
DEFINE j                INTEGER
DEFINE salir            INTEGER
DEFINE resp             VARCHAR(6)
DEFINE tot_valor	LIKE rolt044.n44_valor

DEFINE r_scr ARRAY[50] OF RECORD 
	rubro       		LIKE rolt073.n73_rubro,
	valor			LIKE rolt073.n73_valor
END RECORD	

FOR i = 1 TO vm_numelm
	LET r_scr[i].* = rm_scr[i].*
END FOR
                                                                                
LET int_flag = 0

OPEN WINDOW wf_2 AT 7,6 WITH 15 ROWS, 65 COLUMNS
	ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE 0,
		  MESSAGE LINE LAST, BORDER) 
OPTIONS INPUT WRAP,
	ACCEPT KEY	F12
OPEN FORM f_rol2 FROM "../forms/rolf233_2"
DISPLAY FORM f_rol2

DISPLAY 'Rubro' TO bt_rubro
DISPLAY 'Valor' TO bt_valor

IF vm_numelm > 0 THEN
	CALL set_count(vm_numelm)
END IF
INPUT ARRAY rm_scr WITHOUT DEFAULTS FROM ra_scr.*
        ON KEY(INTERRUPT)
                LET int_flag = 0
                CALL fl_mensaje_abandonar_proceso() RETURNING resp
                IF resp = 'Yes' THEN
                        LET int_flag = 1
                        EXIT INPUT
                END IF
        BEFORE INPUT
                LET vm_filas_pant = fgl_scr_size('ra_scr')
		LET tot_valor = calcula_totales(vm_numelm) 
		DISPLAY BY NAME tot_valor
        BEFORE ROW
                LET i = arr_curr()
                LET j = scr_line()
	AFTER DELETE
		LET j = arr_count()
		LET tot_valor = calcula_totales(j) 
		DISPLAY BY NAME tot_valor
	AFTER INSERT
		LET j = arr_count()
		LET tot_valor = calcula_totales(j) 
		DISPLAY BY NAME tot_valor
        AFTER FIELD n73_valor
                IF rm_scr[i].n73_valor IS NULL THEN
			NEXT FIELD n73_valor
		END IF
		LET j = arr_count()
		LET tot_valor = calcula_totales(j) 
		DISPLAY BY NAME tot_valor
	AFTER INPUT
		LET i = arr_count()
END INPUT
IF int_flag = 1 THEN
	LET rm_n70.n70_tot_otros = 0
	FOR i = 1 TO vm_numelm
		LET rm_scr[i].* = r_scr[i].*
		IF rm_scr[i].n73_valor IS NOT NULL THEN
			LET rm_n70.n70_tot_otros = rm_n70.n70_tot_otros + 
						   rm_scr[i].n73_valor 
		END IF
	END FOR
	CLOSE WINDOW wf_2
	RETURN
END IF

CLOSE WINDOW wf_2

LET rm_n70.n70_tot_otros = calcula_totales(i)
LET vm_numelm = i
                                                                                
END FUNCTION



FUNCTION calcula_totales(numelm)

DEFINE i                SMALLINT
DEFINE numelm           SMALLINT
DEFINE valor            LIKE rolt073.n73_valor
DEFINE tot_valor        LIKE rolt073.n73_valor
                                                                                
LET tot_valor = 0
FOR i = 1 TO numelm
	LET valor = rm_scr[i].n73_valor
	IF valor IS NULL THEN
		LET valor = 0
	END IF
        LET tot_valor = tot_valor + valor
END FOR

IF tot_valor IS NULL THEN
	LET tot_valor = 0
END IF
                                                                                
RETURN tot_valor

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



FUNCTION calcula_paridad(moneda_ori, moneda_dest)
                                                                                
DEFINE moneda_ori       LIKE gent013.g13_moneda
DEFINE moneda_dest      LIKE gent013.g13_moneda
DEFINE paridad          LIKE gent014.g14_tasa
                                                                                
DEFINE r_g14            RECORD LIKE gent014.*
                                                                                
IF moneda_ori = moneda_dest THEN
        LET paridad = 1
ELSE
        CALL fl_lee_factor_moneda(moneda_ori, moneda_dest)
                RETURNING r_g14.*
        IF r_g14.g14_serial IS NULL THEN
                CALL fgl_winmessage(vg_producto,
                                    'No existe factor de conversión ' ||
                                    'para esta moneda',
                                    'exclamation')
                INITIALIZE paridad TO NULL
        ELSE
                LET paridad = r_g14.g14_tasa
        END IF
END IF
RETURN paridad
                                                                                
END FUNCTION
                                                                                
                                                                                
                                                                                
FUNCTION mostrar_registro(num_registro)
DEFINE num_registro	INTEGER

DEFINE r_n30		RECORD LIKE rolt030.*
DEFINE r_n73		RECORD LIKE rolt073.*
DEFINE r_n74		RECORD LIKE rolt074.*

IF vm_num_rows <= 0 THEN
	RETURN
END IF

INITIALIZE rm_n70.* TO NULL
SELECT * INTO rm_n70.* FROM rolt070 WHERE ROWID = num_registro	
IF STATUS = NOTFOUND THEN
	CALL fgl_winmessage (vg_producto,'No existe registro con índice: ' || vm_row_current,'exclamation')
	RETURN
END IF

CALL fl_lee_trabajador_roles(vg_codcia, rm_n70.n70_cod_trab) RETURNING r_n30.*
CALL fl_lee_motivo_salida_trabajador(rm_n70.n70_motivo) RETURNING r_n74.*
	
DISPLAY BY NAME	rm_n70.n70_cod_trab,
		r_n30.n30_nombres,
		rm_n70.n70_estado,
		rm_n70.n70_motivo,
		r_n74.n74_descripcion,
		rm_n70.n70_fec_ren,
		rm_n70.n70_fec_sal,
		rm_n70.n70_calc_comi,
		rm_n70.n70_mes_prom,
		rm_n70.n70_tot_rol,
		rm_n70.n70_comisiones,
		rm_n70.n70_tot_dt,
		rm_n70.n70_tot_dc,
		rm_n70.n70_tot_anticipos,
		rm_n70.n70_tot_vaca,
		rm_n70.n70_tot_otros,
		rm_n70.n70_bonificacion,
		rm_n70.n70_indemnizacion,
		rm_n70.n70_tot_neto

CASE rm_n70.n70_estado
	WHEN 'A'
		DISPLAY 'ACTIVO' TO n_estado
	WHEN 'P'
		DISPLAY 'PROCESADO' TO n_estado
END CASE

DECLARE q_otros CURSOR FOR
	SELECT * FROM rolt073
		WHERE n73_compania = vg_codcia 
		  AND n73_cod_trab = rm_n70.n70_cod_trab 
		  AND n73_serial   = rm_n70.n70_serial 

LET vm_numelm = 1
FOREACH q_otros INTO r_n73.*
	LET rm_scr[vm_numelm].n73_rubro = r_n73.n73_rubro
	LET rm_scr[vm_numelm].n73_valor = r_n73.n73_valor
	LET vm_numelm = vm_numelm + 1
	IF vm_numelm > vm_maxelm THEN
		EXIT FOREACH
	END IF
END FOREACH
LET vm_numelm = vm_numelm - 1

END FUNCTION



FUNCTION mantenimiento_novedades(cod_trab)
DEFINE cod_trab		LIKE rolt070.n70_cod_trab
DEFINE comando		VARCHAR(1000)
DEFINE r_n01		RECORD LIKE rolt001.*
DEFINE r_n32		RECORD LIKE rolt032.*

LET comando = 'fglrun rolp202 ', vg_base, ' ', vg_modulo, ' ', vg_codcia,
	      ' ', cod_trab, ' F ' 
RUN comando

CALL fl_lee_compania_roles(vg_codcia) RETURNING r_n01.*

INITIALIZE r_n32.* TO NULL
SELECT * INTO r_n32.* FROM rolt032
	WHERE n32_compania    = vg_codcia
	  AND n32_cod_trab    = cod_trab 
 	  AND n32_ano_proceso = r_n01.n01_ano_proceso
 	  AND n32_mes_proceso = r_n01.n01_mes_proceso
	  AND n32_estado      = 'F'

RETURN r_n32.*

END FUNCTION



FUNCTION generar_liquidacion_roles(cod_trab)
DEFINE cod_trab		LIKE rolt070.n70_cod_trab
DEFINE comando		VARCHAR(1000)
DEFINE r_n01		RECORD LIKE rolt001.*
DEFINE r_n32		RECORD LIKE rolt032.*

CALL fl_lee_compania_roles(vg_codcia) RETURNING r_n01.*

INITIALIZE r_n32.* TO NULL
SELECT * INTO r_n32.* FROM rolt032
	WHERE n32_compania    = vg_codcia
	  AND n32_cod_trab    = cod_trab 
 	  AND n32_ano_proceso = r_n01.n01_ano_proceso
 	  AND n32_mes_proceso = r_n01.n01_mes_proceso
	  AND n32_estado      = 'F'

LET comando = 'fglrun rolp200 ', vg_base, ' ', vg_modulo, ' ', vg_codcia
IF r_n01.n01_rol_semanal = 'S' THEN
	LET comando = comando, ' S '
END IF
IF r_n01.n01_rol_quincen = 'S' THEN
	LET comando = comando, ' Q '
END IF
IF r_n01.n01_rol_mensual = 'S' THEN
	LET comando = comando, ' M '
END IF

LET comando = comando, cod_trab

IF r_n32.n32_compania IS NOT NULL THEN
	LET comando = comando, ' ', r_n32.n32_cod_liqrol, ' ',
		      r_n32.n32_fecha_ini, ' ', r_n32.n32_fecha_fin
END IF

LET comando = comando, ' F '

RUN comando

INITIALIZE r_n32.* TO NULL
SELECT * INTO r_n32.* FROM rolt032
	WHERE n32_compania    = vg_codcia
	  AND n32_cod_trab    = cod_trab 
 	  AND n32_ano_proceso = r_n01.n01_ano_proceso
 	  AND n32_mes_proceso = r_n01.n01_mes_proceso
	  AND n32_estado      = 'F'

RETURN r_n32.*

END FUNCTION



FUNCTION generar_decimo_tercero(cod_trab)
DEFINE cod_trab		LIKE rolt070.n70_cod_trab
DEFINE comando		VARCHAR(1000)
DEFINE r_n01		RECORD LIKE rolt001.*
DEFINE r_n36		RECORD LIKE rolt036.*

LET comando = 'fglrun rolp206 ', vg_base, ' ', vg_modulo, ' ', vg_codcia,
	      ' ', cod_trab, ' F ' 

RUN comando

CALL fl_lee_compania_roles(vg_codcia) RETURNING r_n01.*

INITIALIZE r_n36.* TO NULL
SELECT * INTO r_n36.* FROM rolt036
	WHERE n36_compania    = vg_codcia
	  AND n36_cod_trab    = cod_trab 
          AND n36_proceso     = 'DT'
 	  AND n36_ano_proceso = r_n01.n01_ano_proceso
 	  AND n36_mes_proceso = r_n01.n01_mes_proceso
	  AND n36_estado      = 'F'

RETURN r_n36.*

END FUNCTION



FUNCTION generar_decimo_cuarto(cod_trab)
DEFINE cod_trab		LIKE rolt070.n70_cod_trab
DEFINE comando		VARCHAR(1000)
DEFINE r_n01		RECORD LIKE rolt001.*
DEFINE r_n36		RECORD LIKE rolt036.*

LET comando = 'fglrun rolp220 ', vg_base, ' ', vg_modulo, ' ', vg_codcia,
	      ' ', cod_trab, ' F ' 
RUN comando

CALL fl_lee_compania_roles(vg_codcia) RETURNING r_n01.*

INITIALIZE r_n36.* TO NULL
SELECT * INTO r_n36.* FROM rolt036
	WHERE n36_compania    = vg_codcia
	  AND n36_cod_trab    = cod_trab 
          AND n36_proceso     = 'DC'
 	  AND n36_ano_proceso = r_n01.n01_ano_proceso
 	  AND n36_mes_proceso = r_n01.n01_mes_proceso
	  AND n36_estado      = 'F'

RETURN r_n36.*

END FUNCTION



FUNCTION calculo_liquidacion(cod_trab)
DEFINE cod_trab		LIKE rolt070.n70_cod_trab
DEFINE comando		VARCHAR(1000)
DEFINE r_n01		RECORD LIKE rolt001.*
DEFINE r_n32		RECORD LIKE rolt032.*

LET comando = 'fglrun rolp203 ', vg_base, ' ', vg_modulo, ' ', vg_codcia,
	      ' F ', cod_trab 
RUN comando

CALL fl_lee_compania_roles(vg_codcia) RETURNING r_n01.*

INITIALIZE r_n32.* TO NULL
SELECT * INTO r_n32.* FROM rolt032
	WHERE n32_compania    = vg_codcia
	  AND n32_cod_trab    = cod_trab 
 	  AND n32_ano_proceso = r_n01.n01_ano_proceso
 	  AND n32_mes_proceso = r_n01.n01_mes_proceso
	  AND n32_estado      = 'F'

RETURN r_n32.*

END FUNCTION



FUNCTION calcula_bonif_indem(r_n70, r_n74)
DEFINE r_n70		RECORD LIKE rolt070.*
DEFINE r_n74		RECORD LIKE rolt074.*

DEFINE valor		DECIMAL(12,2)
DEFINE num_veces	SMALLINT

LET num_veces = r_n70.n70_mes_prom * 2

LET r_n70.n70_antiguedad = obtiene_antiguedad(r_n70.*) 

IF r_n74.n74_calc_bonif = 'N' THEN
	LET r_n70.n70_porc_bonif = 0 
ELSE 
	IF r_n74.n74_bonif_dias_sal = 'S' THEN
		IF (r_n70.n70_fec_sal - r_n70.n70_fec_ren) < r_n74.n74_dias_salida 
		THEN
			LET r_n70.n70_porc_bonif = 0 
		END IF
	END IF
END IF

IF r_n74.n74_calc_indem = 'N' THEN
	LET r_n70.n70_porc_indem = 0 
ELSE 
	IF r_n74.n74_indem_dias_sal = 'S' THEN
		IF (r_n70.n70_fec_sal - r_n70.n70_fec_ren) < r_n74.n74_dias_salida 		
		THEN
			LET r_n70.n70_porc_indem = 0 
		END IF
	END IF
END IF 

IF r_n70.n70_calc_comi = 'N' THEN
	LET r_n70.n70_prom_comi = 0
ELSE
	SELECT NVL(ROUND(AVG(n33_valor), 2), 0) INTO r_n70.n70_prom_comi 
		FROM rolt032, rolt033
		WHERE n32_compania   = vg_codcia
		  AND n32_cod_trab   = r_n70.n70_cod_trab
		  AND n32_estado    IN ('C', 'F') 
	          AND n32_fecha_fin BETWEEN (r_n70.n70_fec_sal - 
				       	    r_n70.n70_mes_prom UNITS MONTH)
					AND r_n70.n70_fec_sal
		  AND n33_compania   = n32_compania 
		  AND n33_cod_liqrol = n32_cod_liqrol
		  AND n33_fecha_ini  = n32_fecha_ini
		  AND n33_fecha_fin  = n32_fecha_fin
		  AND n33_cod_trab   = n32_cod_trab
		  AND n33_cod_rubro  = (SELECT n06_cod_rubro FROM rolt006
						WHERE n06_flag_ident = 'CO')

	LET r_n70.n70_prom_comi = r_n70.n70_prom_comi * 2
END IF

LET valor = r_n70.n70_ult_sueldo + r_n70.n70_prom_comi
LET r_n70.n70_bonificacion = (valor * r_n70.n70_antiguedad) * 
			     (r_n70.n70_porc_bonif / 100)

LET r_n70.n70_indemnizacion = (valor * r_n70.n70_antiguedad) * 
			      (r_n70.n70_porc_indem / 100)

RETURN r_n70.*

END FUNCTION



FUNCTION obtiene_antiguedad(r_n70)
DEFINE r_n70		RECORD LIKE rolt070.*

DEFINE anhos		SMALLINT
DEFINE dias		SMALLINT

LET dias  = r_n70.n70_fec_sal - r_n70.n70_fec_ing
LET anhos = dias  /  (mdy(1, 1, 2001) - mdy(1, 1, 2000)) 
LET dias  = dias MOD (mdy(1, 1, 2001) - mdy(1, 1, 2000)) 
IF dias > 0 THEN
	LET anhos = anhos + 1
END IF

RETURN anhos

END FUNCTION



FUNCTION calcula_total_neto(r_n70) 
DEFINE r_n70			RECORD LIKE rolt070.*

LET r_n70.n70_tot_neto = 0
IF r_n70.n70_tot_rol IS NOT NULL THEN
	LET r_n70.n70_tot_neto = r_n70.n70_tot_neto + r_n70.n70_tot_rol 
END IF
IF r_n70.n70_comisiones IS NOT NULL THEN
	LET r_n70.n70_tot_neto = r_n70.n70_tot_neto + r_n70.n70_comisiones 
END IF
IF r_n70.n70_tot_dt IS NOT NULL THEN
	LET r_n70.n70_tot_neto = r_n70.n70_tot_neto + r_n70.n70_tot_dt 
END IF
IF r_n70.n70_tot_dc IS NOT NULL THEN
	LET r_n70.n70_tot_neto = r_n70.n70_tot_neto + r_n70.n70_tot_dc 
END IF
IF r_n70.n70_tot_vaca IS NOT NULL THEN
	LET r_n70.n70_tot_neto = r_n70.n70_tot_neto + r_n70.n70_tot_vaca 
END IF
IF r_n70.n70_tot_otros IS NOT NULL THEN
	LET r_n70.n70_tot_neto = r_n70.n70_tot_neto + r_n70.n70_tot_otros 
END IF
IF r_n70.n70_bonificacion IS NOT NULL THEN
	LET r_n70.n70_tot_neto = r_n70.n70_tot_neto + r_n70.n70_bonificacion 
END IF
IF r_n70.n70_indemnizacion IS NOT NULL THEN
	LET r_n70.n70_tot_neto = r_n70.n70_tot_neto + r_n70.n70_indemnizacion 
END IF

IF r_n70.n70_tot_anticipos IS NOT NULL THEN
	LET r_n70.n70_tot_neto = r_n70.n70_tot_neto - r_n70.n70_tot_anticipos
END IF

RETURN r_n70.n70_tot_neto

END FUNCTION



FUNCTION obtiene_anticipos(cod_trab)
DEFINE cod_trab			LIKE rolt070.n70_cod_trab
DEFINE anticipo			LIKE rolt070.n70_tot_anticipos

DEFINE query			VARCHAR(1000)

DEFINE r_n33			RECORD LIKE rolt033.*
DEFINE r_n37			RECORD LIKE rolt037.*
DEFINE r_n40			RECORD LIKE rolt040.*

DELETE FROM rolt072 WHERE n72_compania = vg_codcia
		      AND n72_cod_trab = rm_n70.n70_cod_trab
		      AND n72_serial   = rm_n70.n70_serial

LET query = 'INSERT INTO rolt072 ',
		'SELECT ', vg_codcia, ', ', rm_n70.n70_cod_trab, ', ',
			rm_n70.n70_serial, ', n46_num_prest, ',
			' NVL(SUM(n46_saldo), 0) ',
		'FROM rolt045, rolt046 ',
		'WHERE n45_compania  = ', vg_codcia,
		'  AND n45_cod_trab  = ', rm_n70.n70_cod_trab,
		'  AND n45_estado    IN ("A", "R") ',
	  	'  AND n46_compania  = n45_compania ',
	 	'  AND n46_num_prest = n45_num_prest ',
		'GROUP BY n46_num_prest '

PREPARE stmnt FROM query
EXECUTE stmnt

DECLARE q_prest_1 CURSOR FOR
	SELECT rolt033.* FROM rolt032, rolt033
        	WHERE n32_compania   = vg_codcia
        	  AND n32_cod_trab   = rm_n70.n70_cod_trab
        	  AND n32_estado     = "F"
        	  AND n33_compania   = n32_compania
        	  AND n33_cod_liqrol = n32_cod_liqrol
        	  AND n33_fecha_ini  = n32_fecha_ini
        	  AND n33_fecha_fin  = n32_fecha_fin
        	  AND n33_cod_trab   = n32_cod_trab
		  AND n33_num_prest IS NOT NULL

FOREACH q_prest_1 INTO r_n33.*
	UPDATE rolt072 SET n72_saldo = n72_saldo - r_n33.n33_valor
		WHERE n72_compania  = vg_codcia
		  AND n72_cod_trab  = rm_n70.n70_cod_trab
		  AND n72_serial    = rm_n70.n70_serial
		  AND n72_num_prest = r_n33.n33_num_prest 
END FOREACH

DECLARE q_prest_2 CURSOR FOR
	SELECT rolt037.* FROM rolt036, rolt037
        	WHERE n36_compania  = vg_codcia
        	  AND n36_cod_trab  = rm_n70.n70_cod_trab
                  AND n36_estado    = "F"
                  AND n37_compania  = n36_compania
                  AND n37_proceso   = n36_proceso
                  AND n37_fecha_ini = n36_fecha_ini
                  AND n37_fecha_fin = n36_fecha_fin
                  AND n37_cod_trab  = n36_cod_trab
		  AND n37_num_prest IS NOT NULL

FOREACH q_prest_2 INTO r_n37.*
	UPDATE rolt072 SET n72_saldo = n72_saldo - r_n37.n37_valor
		WHERE n72_compania  = vg_codcia
		  AND n72_cod_trab  = rm_n70.n70_cod_trab
		  AND n72_serial    = rm_n70.n70_serial
		  AND n72_num_prest = r_n37.n37_num_prest 
END FOREACH

DECLARE q_prest_3 CURSOR FOR
	SELECT rolt040.* FROM rolt039, rolt040
        	WHERE n39_compania    = vg_codcia
        	  AND n39_cod_trab    = rm_n70.n70_cod_trab
                  AND n39_tipo        = "P"
                  AND n39_estado      = "F"
                  AND n40_compania    = n39_compania
                  AND n40_cod_trab    = n39_cod_trab
                  AND n40_periodo_ini = n39_periodo_ini
                  AND n40_periodo_fin = n39_periodo_fin
		  AND n40_cod_trab IS NOT NULL

FOREACH q_prest_3 INTO r_n40.*
	UPDATE rolt072 SET n72_saldo = n72_saldo - r_n40.n40_valor
		WHERE n72_compania  = vg_codcia
		  AND n72_cod_trab  = rm_n70.n70_cod_trab
		  AND n72_serial    = rm_n70.n70_serial
		  AND n72_num_prest = r_n40.n40_num_prest 
END FOREACH

DELETE FROM rolt072 WHERE n72_compania = vg_codcia
		      AND n72_cod_trab = rm_n70.n70_cod_trab
		      AND n72_serial   = rm_n70.n70_serial
		      AND n72_saldo <= 0

SELECT NVL(SUM(n72_saldo), 0) INTO anticipo FROM rolt072
	WHERE n72_compania = vg_codcia
	  AND n72_cod_trab = rm_n70.n70_cod_trab
	  AND n72_serial   = rm_n70.n70_serial

RETURN anticipo

END FUNCTION 



FUNCTION cerrar_liquidacion(cod_trab)
DEFINE cod_trab		LIKE rolt070.n70_cod_trab
DEFINE comando		VARCHAR(1000)
DEFINE r_n71		RECORD LIKE rolt071.*

INITIALIZE r_n71.* TO NULL
SELECT * INTO r_n71.* FROM rolt071 
	WHERE n71_compania  = vg_codcia 
	  AND n71_cod_trab  = cod_trab 
	  AND n71_serial    = serial 
	  AND n71_tipo_proc = 'L' 

IF r_n71.n71_compania IS NULL THEN
	RETURN
END IF

LET comando = 'fglrun rolp204 ', vg_base, ' ', vg_modulo, ' ', vg_codcia,
	      ' ', cod_trab, ' F ' 
RUN comando

END FUNCTION



FUNCTION cerrar_decimos(r_n70)
DEFINE r_n70		RECORD LIKE rolt070.*
DEFINE r_n71		RECORD LIKE rolt071.*
DEFINE comando		VARCHAR(1000)

DECLARE q_decimos CURSOR FOR
	SELECT * FROM rolt071
		WHERE n71_compania  = vg_codcia
		  AND n71_cod_trab  = r_n70.n70_cod_trab
		  AND n71_serial    = r_n70.n70_serial
		  AND n71_tipo_proc = 'D'

FOREACH q_decimos INTO r_n71.*
	CASE r_n71.n71_proceso 
		WHEN 'DT'
			LET comando = 'fglrun rolp207 ', vg_base, ' ', 
				      vg_modulo, ' ', vg_codcia,  ' ',
				      r_n71.n71_fecha_ini, ' ', 
				      r_n71.n71_fecha_fin, ' ',
	      			      r_n70.n70_cod_trab, ' F ' 
		WHEN 'DC'
			LET comando = 'fglrun rolp221 ', vg_base, ' ', 
				      vg_modulo, ' ', vg_codcia,  ' ',
				      r_n71.n71_fecha_ini, ' ', 
				      r_n71.n71_fecha_fin, ' ',
	      			      r_n70.n70_cod_trab, ' F ' 
	END CASE
	RUN comando
END FOREACH

END FUNCTION



FUNCTION valida_fecha_salida(fecha_sal)
DEFINE fecha_sal		LIKE rolt070.n70_fec_sal
DEFINE r_n32			RECORD LIKE rolt032.*

INITIALIZE r_n32.* TO NULL
OPEN  q_ultliq
FETCH q_ultliq INTO r_n32.*
IF r_n32.n32_compania IS NULL THEN
	CLOSE q_ultliq
	RETURN 1
END IF
CLOSE q_ultliq

IF fecha_sal < r_n32.n32_fecha_ini THEN
	CALL fl_mostrar_mensaje('La fecha de salida corresponde a una liquidacion ya cerrada, corrija para continuar.', 'exclamation')
	RETURN 0
END IF

IF fecha_sal > r_n32.n32_fecha_fin THEN
	RETURN 1
END IF

RETURN 1
		
END FUNCTION



FUNCTION ver_liquidacion()
DEFINE r_n32		RECORD LIKE rolt032.*
DEFINE comando		VARCHAR(1000)


INITIALIZE r_n32.* TO NULL
OPEN  q_liq USING vg_codcia, rm_n70.n70_cod_trab, rm_n70.n70_serial
FETCH q_liq INTO r_n32.* 
IF r_n32.n32_compania IS NULL THEN
	CALL fl_mostrar_mensaje('No se ha generado liquidacion de roles para el acta.', 'exclamation')
	RETURN
END IF
CLOSE q_liq

LET comando = 'fglrun rolp303 ', vg_base, ' ', vg_modulo, ' ', vg_codcia,
	      ' ', r_n32.n32_cod_liqrol, ' ', r_n32.n32_fecha_ini, ' ',
	      r_n32.n32_fecha_fin, ' N ', r_n32.n32_cod_depto, ' ',
	      r_n32.n32_cod_trab  

RUN comando

END FUNCTION



FUNCTION ver_trabajador()
DEFINE comando		VARCHAR(1000)

LET comando = 'fglrun rolp108 ', vg_base, ' ', vg_modulo, ' ', vg_codcia,
	      ' ', rm_n70.n70_cod_trab  

RUN comando

END FUNCTION



FUNCTION ver_submenu(flag)
DEFINE flag		CHAR(1)

DEFINE r_n32		RECORD LIKE rolt032.*
DEFINE r_n36		RECORD LIKE rolt036.*

MENU 'OPCIONES'
	BEFORE MENU
		HIDE OPTION 'Liq. Roles'
		HIDE OPTION 'Ver Liquidacion'
		HIDE OPTION 'Decimos'
		HIDE OPTION 'Decimo Cuarto'
		HIDE OPTION 'Decimo Tercero'
		HIDE OPTION 'Anticipos'
		HIDE OPTION 'Otros'
		INITIALIZE r_n32.* TO NULL
		OPEN  q_liq USING vg_codcia, rm_n70.n70_cod_trab, 
				  rm_n70.n70_serial
		FETCH q_liq INTO r_n32.*
		IF r_n32.n32_compania IS NOT NULL THEN
			IF flag = 'M' THEN
				SHOW OPTION 'Liq. Roles'
			END IF
			SHOW OPTION 'Ver Liquidacion'
		END IF
		CLOSE q_liq
		IF flag = 'M' THEN
			SHOW OPTION 'Decimos'
			SHOW OPTION 'Anticipos'
			SHOW OPTION 'Otros'
		END IF
		IF flag = 'C' THEN
			SHOW OPTION 'Decimo Cuarto'
			SHOW OPTION 'Decimo Tercero'
			IF rm_n70.n70_tot_anticipos > 0 THEN
				SHOW OPTION 'Anticipos'
			END IF
			IF rm_n70.n70_tot_otros > 0 THEN
				SHOW OPTION 'Otros'
			END IF
		END IF
	COMMAND KEY('T') 'Datos Trabajador' 'Datos basicos del trabajador.'
		CALL ver_trabajador()
	COMMAND KEY('L') 'Liq. Roles' 'Da mantenimiento a la liquidacion del trabajador. '
		CALL mantenimiento_novedades(rm_n70.n70_cod_trab) 
			RETURNING r_n32.*
		LET rm_n70.n70_tot_rol = r_n32.n32_tot_ing - r_n32.n32_tot_egr
		LET rm_n70.n70_tot_neto = calcula_total_neto(rm_n70.*)
		DISPLAY BY NAME rm_n70.n70_tot_rol, rm_n70.n70_tot_neto
		CALL fl_mostrar_mensaje('Liquidacion de roles actualizada.',
					'exclamation')
	COMMAND KEY('V') 'Ver Liquidacion' 'Consulta la liquidacion generada.'
		CALL ver_liquidacion()
	COMMAND KEY('D') 'Decimos' 'Regenera los decimos del trabajador.'
		CALL generar_decimo_tercero(rm_n70.n70_cod_trab) 
			RETURNING r_n36.*
			LET rm_n70.n70_tot_dt = r_n36.n36_valor_neto 

		CALL generar_decimo_cuarto(rm_n70.n70_cod_trab) 
			RETURNING r_n36.*
			LET rm_n70.n70_tot_dc = r_n36.n36_valor_neto 

		LET rm_n70.n70_tot_neto = calcula_total_neto(rm_n70.*)
		DISPLAY BY NAME rm_n70.n70_tot_dt, rm_n70.n70_tot_dc,
				rm_n70.n70_tot_neto
		CALL fl_mostrar_mensaje('Liquidacion de decimos actualizada.',
					'exclamation')
	COMMAND KEY('3') 'Decimo Tercero' 'Muestra el decimo tercero.'
		CALL ver_decimo(rm_n70.*, 'DT')
	COMMAND KEY('4') 'Decimo Cuarto' 'Muestra el decimo cuarto.'
		CALL ver_decimo(rm_n70.*, 'DC')
	COMMAND KEY('A') 'Anticipos' 'Recalcula anticipos pendientes.'
		IF flag = 'M' THEN
			LET rm_n70.n70_tot_anticipos = 
				obtiene_anticipos(rm_n70.n70_cod_trab) 
			LET rm_n70.n70_tot_neto = calcula_total_neto(rm_n70.*)
			DISPLAY BY NAME rm_n70.n70_tot_anticipos, rm_n70.n70_tot_neto
			CALL fl_mostrar_mensaje('Se han recalculado los anticipos.',
						'exclamation')
		END IF
		IF flag = 'C' THEN
			CALL ver_anticipos()
		END IF
	COMMAND KEY('O') 'Otros' 'Ingresa otros ingresos y descuentos.'
		IF flag = 'M' THEN
			CALL ingresar_otros()
			LET rm_n70.n70_tot_neto = calcula_total_neto(rm_n70.*)
			DISPLAY BY NAME rm_n70.n70_tot_otros, rm_n70.n70_tot_neto
		END IF
		IF flag = 'C' THEN
			CALL ver_otros()
		END IF
	COMMAND KEY('R') 'Regresar' 'Regresa al menu anterior. '
		EXIT MENU
END MENU

END FUNCTION



FUNCTION ver_decimo(r_n70, proceso)
DEFINE r_n70		RECORD LIKE rolt070.*
DEFINE r_n71		RECORD LIKE rolt071.*
DEFINE proceso		CHAR(2)
DEFINE programa		CHAR(15)
DEFINE comando		VARCHAR(1000)

INITIALIZE r_n71.* TO NULL
DECLARE q_decimo CURSOR FOR
	SELECT * FROM rolt071
		WHERE n71_compania  = vg_codcia
		  AND n71_cod_trab  = r_n70.n70_cod_trab
		  AND n71_serial    = r_n70.n70_serial
		  AND n71_proceso   = proceso
		  AND n71_tipo_proc = 'D'

OPEN  q_decimo
FETCH q_decimo INTO r_n71.*
CLOSE q_decimo

CASE proceso 
	WHEN 'DT'
		LET programa = 'rolp207' 
	WHEN 'DC'
		LET programa = 'rolp221' 
END CASE

LET comando = 'fglrun ', programa, ' ', vg_base, ' ', 
	      vg_modulo, ' ', vg_codcia,  ' ',
	      r_n71.n71_fecha_ini, ' ', 
	      r_n71.n71_fecha_fin, ' ',
	      r_n70.n70_cod_trab, ' C ' 
RUN comando

END FUNCTION



FUNCTION ver_anticipos() 
DEFINE r_n45		RECORD LIKE rolt045.*
DEFINE comando		VARCHAR(500)
DEFINE flag		CHAR(1)

DECLARE q_anti CURSOR FOR 
	SELECT * FROM rolt045
		WHERE n45_compania = vg_codcia
		  AND n45_cod_trab = rm_n70.n70_cod_trab
		ORDER BY n45_compania, n45_num_prest DESC

LET flag = 'D'
INITIALIZE r_n45.* TO NULL
OPEN  q_anti
FETCH q_anti INTO r_n45.*
IF r_n45.n45_compania IS NULL THEN
	CLOSE q_anti
	FREE  q_anti
	RETURN
END IF
FETCH q_anti INTO r_n45.*
IF STATUS = NOTFOUND THEN
	LET flag = 'E'
END IF
CLOSE q_anti
FREE  q_anti

LET comando = 'fglrun rolp214 ', vg_base, ' ', vg_modulo, ' ', vg_codcia,
	      ' ', r_n45.n45_num_prest
IF flag = 'D' THEN
	LET comando = comando, ' F ', r_n45.n45_cod_trab 
END IF
RUN comando

END FUNCTION



FUNCTION ver_otros()
DEFINE tot_valor	LIKE rolt070.n70_tot_otros

	IF vm_numelm <= 0 THEN
		RETURN
	END IF

	LET int_flag = 0

	OPEN WINDOW wf_2 AT 7,6 WITH 15 ROWS, 65 COLUMNS
		ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE 0,
			  MESSAGE LINE LAST, BORDER) 
	OPTIONS INPUT WRAP,
		ACCEPT KEY	F12
	OPEN FORM f_rol2 FROM "../forms/rolf233_2"
	DISPLAY FORM f_rol2
	
	DISPLAY 'Rubro' TO bt_rubro
	DISPLAY 'Valor' TO bt_valor

	LET tot_valor = calcula_totales(vm_numelm) 
	DISPLAY BY NAME tot_valor
	CALL set_count(vm_numelm)
	DISPLAY ARRAY rm_scr TO ra_scr.*
	CLOSE WINDOW wf_2
END FUNCTION
