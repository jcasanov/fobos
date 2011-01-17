------------------------------------------------------------------------------
-- Titulo           : ctbp202.4gl - Configuracion de diarios periodicos
-- Elaboracion      : 06-dic-2001
-- Autor            : JCM
-- Formato Ejecucion: fglrun ctbp202 base modulo compania [diario]
-- Ultima Correccion: 
-- Motivo Correccion: 
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_nivel_cta	LIKE ctbt001.b01_nivel
DEFINE vm_diario	LIKE ctbt014.b14_codigo

DEFINE vm_filas_pant	SMALLINT

DEFINE rm_orden         ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1     SMALLINT
DEFINE vm_columna_2     SMALLINT

-- CADA VEZ QUE SE REALIZE UNA CONSULTA SE GUARDARAN LOS ROWID DE CADA FILA 
-- RECUPERADA EN UNA TABLA LLAMADA r_rows QUE TENDRA 1000 ELEMENTOS
DEFINE vm_rows ARRAY[1000] OF INTEGER  	-- ARREGLO DE ROWID DE FILAS LEIDAS
DEFINE vm_row_current	SMALLINT	-- FILA CORRIENTE DEL ARREGLO
DEFINE vm_num_rows	SMALLINT	-- CANTIDAD DE FILAS LEIDAS

DEFINE vm_max_rows	SMALLINT
--
-- DEFINE RECORD(S) HERE
--
DEFINE rm_b14		RECORD LIKE ctbt014.*
DEFINE rm_b00		RECORD LIKE ctbt000.*

DEFINE vm_max_cta	SMALLINT
DEFINE vm_ind_cta	SMALLINT
DEFINE rm_cuenta ARRAY[1000] OF RECORD
	cuenta		LIKE ctbt015.b15_cuenta,
	desc_cuenta	LIKE ctbt010.b10_descripcion,
	valor_debito	LIKE ctbt015.b15_valor_base,
	valor_credito	LIKE ctbt015.b15_valor_base
END RECORD



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/errores')
CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 3 AND num_args() <> 4 THEN  -- Validar # parámetros correcto
	CALL fgl_winmessage(vg_producto, 'Número de parámetros incorrecto', 
                            'stop')
	EXIT PROGRAM
END IF
LET vg_proceso = 'ctbp202'
LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_codcia   = arg_val(3)

CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	-- Asigna un valor por default a vg_codloc
				-- que luego puede ser reemplazado si se 
                                -- mantiene sin comentario la siguiente linea
INITIALIZE vm_diario TO NULL
IF num_args() = 4 THEN
	LET vm_diario = arg_val(4)
END IF
CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()

END MAIN



FUNCTION funcion_master()

DEFINE i		SMALLINT

CALL fl_nivel_isolation()
OPTIONS
	INPUT WRAP,
	ACCEPT KEY F12
OPEN WINDOW w_202 AT 3,2 WITH 22 ROWS, 80 COLUMNS
	ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE 0,
		  BORDER, MESSAGE LINE LAST - 2) 
OPEN FORM f_202 FROM '../forms/ctbf202_1'
DISPLAY FORM f_202

LET vm_num_rows = 0
LET vm_row_current = 0
INITIALIZE rm_b14.* TO NULL
CALL muestra_contadores()

CALL setea_nombre_botones_f1()

LET vm_max_rows = 1000
LET vm_max_cta  = 1000

CALL fl_lee_compania_contabilidad(vg_codcia) 	RETURNING rm_b00.*
IF rm_b00.b00_compania IS NULL THEN
	CALL fgl_winmessage(vg_producto,
		'No existe configuración para está compañía en el módulo.',
		'stop')
	EXIT PROGRAM
END IF

SELECT MAX(b01_nivel) INTO vm_nivel_cta FROM ctbt001
IF vm_nivel_cta IS NULL THEN
	CALL fgl_winmessage(vg_producto,
		'No se ha configurado el plan de cuentas.',
		'stop')
	EXIT PROGRAM
END IF

FOR i = 1 TO 10
        LET rm_orden[i] = 'ASC'
END FOR

CREATE TEMP TABLE tmp_detalle(
	secuencia	SMALLINT,
	cuenta		CHAR(12),
	desc_cuenta	VARCHAR(40),
	valor_debito	DECIMAL(14,2),
	valor_credito	DECIMAL(14,2)
);
CREATE UNIQUE INDEX tmp_pk   ON tmp_detalle(secuencia);

IF vm_diario IS NOT NULL THEN
	CALL execute_query()
END IF

MENU 'OPCIONES'
	BEFORE MENU
		HIDE OPTION 'Avanzar'
		HIDE OPTION 'Retroceder'
		HIDE OPTION 'Modificar'
		HIDE OPTION 'Detalle'
		HIDE OPTION 'Bloquear/Activar'
		IF vm_diario IS NOT NULL THEN   -- Se ejecuta en modo de solo
			HIDE OPTION 'Ingresar'  -- consulta
			HIDE OPTION 'Consultar'
			IF vm_ind_cta > vm_filas_pant THEN
				SHOW OPTION 'Detalle'
			END IF
		END IF
	COMMAND KEY('I') 'Ingresar' 		'Ingresar nuevos registros.'
		CALL control_ingreso()
		IF vm_num_rows = 1 THEN
		   IF fl_control_permiso_opcion('Modificar') THEN			
			SHOW OPTION 'Modificar'
		   END IF 

		   IF fl_control_permiso_opcion('Bloquear') THEN
			SHOW OPTION 'Bloquear/Activar'
		   END IF
			
		END IF
		IF vm_row_current > 1 THEN
			SHOW OPTION 'Retroceder'
		END IF
		IF vm_row_current = vm_num_rows THEN
			HIDE OPTION 'Avanzar'
		END IF
		IF vm_ind_cta > vm_filas_pant THEN
			SHOW OPTION 'Detalle'
		END IF
		CALL setea_nombre_botones_f1()
	COMMAND KEY('M') 'Modificar' 		'Modificar registro corriente.'
		CALL control_modificacion()
		CALL setea_nombre_botones_f1()
	COMMAND KEY('C') 'Consultar' 		'Consultar un registro.'
		HIDE OPTION 'Detalle'
		CALL control_consulta()
		IF vm_num_rows <= 1 THEN
		   IF fl_control_permiso_opcion('Modificar') THEN			
			SHOW OPTION 'Modificar'
		   END IF 

		   IF fl_control_permiso_opcion('Bloquear') THEN
			SHOW OPTION 'Bloquear/Activar'
		   END IF
			
			HIDE OPTION 'Avanzar'
			HIDE OPTION 'Retroceder'
			IF vm_num_rows = 0 THEN
				HIDE OPTION 'Modificar'
				HIDE OPTION 'Bloquear/Activar'
			END IF
		ELSE
			SHOW OPTION 'Avanzar'
		   IF fl_control_permiso_opcion('Modificar') THEN			
			SHOW OPTION 'Modificar'
		   END IF 

		   IF fl_control_permiso_opcion('Bloquear') THEN
			SHOW OPTION 'Bloquear/Activar'
		   END IF
			
		END IF
		IF vm_row_current <= 1 THEN
			HIDE OPTION 'Retroceder'
		END IF
		IF vm_ind_cta > vm_filas_pant THEN
			SHOW OPTION 'Detalle'
		END IF
		CALL setea_nombre_botones_f1()
	COMMAND KEY('D') 'Detalle'		'Ver detalle del comprobante.'
		CALL control_detalle()
	COMMAND KEY('A') 'Avanzar' 		'Ver siguiente registro.'
		HIDE OPTION 'Detalle'
		CALL siguiente_registro()
		IF vm_row_current = vm_num_rows THEN
			HIDE OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
			NEXT OPTION 'Retroceder'
		ELSE
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
		END IF
		IF vm_ind_cta > vm_filas_pant THEN
			SHOW OPTION 'Detalle'
		END IF
	COMMAND KEY('R') 'Retroceder' 		'Ver anterior registro.'
		HIDE OPTION 'Detalle'
		CALL anterior_registro()
		IF vm_row_current = 1 THEN
			HIDE OPTION 'Retroceder'
			SHOW OPTION 'Avanzar'
			NEXT OPTION 'Avanzar'
		ELSE
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
		END IF
		IF vm_ind_cta > vm_filas_pant THEN
			SHOW OPTION 'Detalle'
		END IF
	COMMAND KEY('B') 'Bloquear/Activar'     'Bloquea o activa registro.'
		CALL control_bloquea_activa()
	COMMAND KEY('S') 'Salir'    		'Salir del programa.'
		EXIT MENU
END MENU

END FUNCTION



FUNCTION control_ingreso()

DEFINE rowid		INTEGER
DEFINE done 		SMALLINT

CLEAR FORM
INITIALIZE rm_b14.* TO NULL

LET rm_b14.b14_fecing    = CURRENT
LET rm_b14.b14_usuario   = vg_usuario
LET rm_b14.b14_compania  = vg_codcia
LET rm_b14.b14_moneda    = rm_b00.b00_moneda_base
LET rm_b14.b14_estado    = 'A'
LET rm_b14.b14_fecha_ini = TODAY
CALL muestra_etiquetas()


CALL lee_datos('I')
IF INT_FLAG THEN
	IF vm_num_rows = 0 THEN
		CLEAR FORM
	ELSE	
		CALL lee_muestra_registro(vm_rows[vm_row_current])
	END IF
	RETURN
END IF

DELETE FROM tmp_detalle
CALL ingresa_detalle()
IF INT_FLAG THEN
	IF vm_num_rows = 0 THEN
		CLEAR FORM
	ELSE	
		CALL lee_muestra_registro(vm_rows[vm_row_current])
	END IF
	RETURN
END IF

BEGIN WORK

SELECT MAX(b14_codigo) INTO rm_b14.b14_codigo
	FROM ctbt014
	WHERE b14_compania = vg_codcia
IF rm_b14.b14_codigo IS NULL THEN
	LET rm_b14.b14_codigo = 1
ELSE
	LET rm_b14.b14_codigo = rm_b14.b14_codigo + 1
END IF

INSERT INTO ctbt014 VALUES (rm_b14.*)

LET rowid = SQLCA.SQLERRD[6] 		-- Rowid de la ultima fila
	                        	-- procesada
	                        	
LET done = grabar_detalle()
IF NOT done THEN
	ROLLBACK WORK
	IF vm_num_rows = 0 THEN
		CLEAR FORM
	ELSE	
		CALL lee_muestra_registro(vm_rows[vm_row_current])
	END IF
	RETURN
END IF

COMMIT WORK

IF vm_num_rows = vm_max_rows THEN
	LET vm_num_rows = 1
ELSE
	LET vm_num_rows = vm_num_rows + 1
END IF
LET vm_row_current = vm_num_rows
LET vm_rows[vm_num_rows] = rowid

CALL muestra_contadores()
CALL fl_mensaje_registro_ingresado()

END FUNCTION



FUNCTION control_modificacion()

DEFINE done 		SMALLINT

IF vm_num_rows = 0 THEN   
	CALL fl_mensaje_consultar_primero()
	RETURN
END IF

IF rm_b14.b14_estado = 'B' THEN
	CALL fl_mensaje_estado_bloqueado()
	RETURN
END IF

IF rm_b14.b14_veces_gen > 0 THEN
	CALL fgl_winmessage(vg_producto,
		'No puede modificar este registro, porque ya se han ' ||
		'generado diarios.',
		'exclamation')
	RETURN
END IF

CALL lee_muestra_registro(vm_rows[vm_row_current])

WHENEVER ERROR CONTINUE
BEGIN WORK
DECLARE q_upd CURSOR FOR 
	SELECT * FROM ctbt014 WHERE ROWID = vm_rows[vm_row_current]
	FOR UPDATE
OPEN q_upd
FETCH q_upd INTO rm_b14.*
WHENEVER ERROR STOP
IF STATUS < 0 THEN
	CALL fl_mensaje_bloqueo_otro_usuario()
	ROLLBACK WORK
	RETURN
END IF  

CALL lee_datos('M')
IF INT_FLAG THEN
	ROLLBACK WORK
	CALL lee_muestra_registro(vm_rows[vm_row_current])
	CLOSE q_upd
	RETURN
END IF 

CALL ingresa_detalle()
IF INT_FLAG THEN
	ROLLBACK WORK
	CALL lee_muestra_registro(vm_rows[vm_row_current])
	CLOSE q_upd
	RETURN
END IF 

UPDATE ctbt014 SET * = rm_b14.* WHERE CURRENT OF q_upd

LET done = grabar_detalle()
IF INT_FLAG THEN
	ROLLBACK WORK
	CALL lee_muestra_registro(vm_rows[vm_row_current])
	CLOSE q_upd
	RETURN
END IF

COMMIT WORK
CLOSE q_upd
CALL fl_mensaje_registro_modificado()

END FUNCTION



FUNCTION lee_datos(flag)

DEFINE flag 		CHAR(1)
DEFINE resp 		CHAR(6)

DEFINE r_b03		RECORD LIKE ctbt003.*
DEFINE r_b06		RECORD LIKE ctbt006.*
DEFINE r_g13		RECORD LIKE gent013.*

IF rm_b14.b14_veces_gen IS NULL THEN
	LET rm_b14.b14_veces_gen = 0
END IF

LET INT_FLAG = 0
INPUT BY NAME rm_b14.b14_codigo,    rm_b14.b14_tipo_comp,  rm_b14.b14_estado,
	      rm_b14.b14_glosa,     rm_b14.b14_moneda,
	      rm_b14.b14_paridad,   rm_b14.b14_veces_max, 
	      rm_b14.b14_fecha_ini, rm_b14.b14_veces_gen,
	      rm_b14.b14_ult_num,   rm_b14.b14_usuario,    rm_b14.b14_fecing 
	      WITHOUT DEFAULTS
	ON KEY (INTERRUPT)
		IF NOT FIELD_TOUCHED(rm_b14.b14_tipo_comp, rm_b14.b14_glosa,     
				     rm_b14.b14_moneda,    rm_b14.b14_fecha_ini,
				     rm_b14.b14_veces_max, rm_b14.b14_veces_gen
                                    ) THEN
			RETURN
		END IF

		LET INT_FLAG = 0
		CALL fl_mensaje_abandonar_proceso() RETURNING resp
		IF resp = 'Yes' THEN
			LET INT_FLAG = 1
			RETURN
		END IF
	ON KEY(F2)
		IF INFIELD(b14_tipo_comp) THEN
			CALL fl_ayuda_tipos_comprobantes(vg_codcia)
				RETURNING r_b03.b03_tipo_comp,
					  r_b03.b03_nombre
			IF r_b03.b03_tipo_comp IS NOT NULL THEN
				LET rm_b14.b14_tipo_comp = r_b03.b03_tipo_comp
				DISPLAY BY NAME rm_b14.b14_tipo_comp
			END IF
		END IF
		IF INFIELD(b14_moneda) THEN
			CALL fl_ayuda_monedas() RETURNING r_g13.g13_moneda,
							  r_g13.g13_nombre,
							  r_g13.g13_decimales
			IF r_g13.g13_moneda IS NOT NULL THEN
				LET rm_b14.b14_moneda = r_g13.g13_moneda
				DISPLAY BY NAME rm_b14.b14_moneda
				DISPLAY r_g13.g13_nombre TO n_moneda
			END IF
		END IF
		LET INT_FLAG = 0
	BEFORE INPUT
		CALL setea_nombre_botones_f1()
	AFTER FIELD b14_tipo_comp
		IF rm_b14.b14_tipo_comp IS NULL THEN
			CONTINUE INPUT
		END IF
		CALL fl_lee_tipo_comprobante_contable(vg_codcia, 
			rm_b14.b14_tipo_comp) RETURNING r_b03.*
		IF r_b03.b03_tipo_comp IS NULL THEN
			CALL fgl_winmessage(vg_producto,
				'Este tipo de comprobante no existe.',
				'exclamation')
			CLEAR n_tipo_comp
			NEXT FIELD b14_tipo_comp
		END IF
		IF r_b03.b03_estado = 'B' THEN
			CALL fgl_winmessage(vg_producto,
				'Este tipo de comprobante está bloqueado.',
				'exclamation')
			CLEAR n_tipo_comp
			NEXT FIELD b14_tipo_comp
		END IF
		DISPLAY r_b03.b03_nombre TO n_tipo_comp
	AFTER FIELD b14_moneda
		IF rm_b14.b14_moneda IS NULL THEN
			CLEAR n_moneda
		ELSE
			CALL fl_lee_moneda(rm_b14.b14_moneda) RETURNING r_g13.*
			IF r_g13.g13_moneda IS NULL THEN	
				CALL FGL_WINMESSAGE(vg_producto, 
                             		            'Moneda no existe.',
                                        	    'exclamation')
				CLEAR n_moneda
				NEXT FIELD b14_moneda
			ELSE
				IF  r_g13.g13_moneda <> rm_b00.b00_moneda_base
				AND r_g13.g13_moneda <> rm_b00.b00_moneda_aux
				THEN
					CALL fgl_winmessage(vg_producto,
							    'La moneda debe ' ||
							    'ser la moneda ' ||
							    'base o la ' ||
							    'moneda alterna',
							    'exclamation')
					CLEAR n_moneda
					LET rm_b14.b14_moneda = 
						rm_b00.b00_moneda_base
					DISPLAY BY NAME rm_b14.b14_moneda
					NEXT FIELD b14_moneda
				END IF
				IF r_g13.g13_estado = 'B' THEN
					CALL FGL_WINMESSAGE(vg_producto, 
                            		 	            'Moneda está ' ||
                               	                            'bloqueada.',
                                       	                    'exclamation')
					CLEAR n_moneda
					NEXT FIELD b14_moneda
				ELSE
					DISPLAY r_g13.g13_nombre TO n_moneda
					CALL muestra_paridad_moneda_actual()
				END IF
			END IF 
		END IF
	AFTER FIELD b14_fecha_ini
		IF rm_b14.b14_fecha_ini IS NULL THEN
			CONTINUE INPUT
		END IF
		IF rm_b14.b14_fecha_ini < TODAY THEN
			CALL fgl_winmessage(vg_producto,
				'La fecha inicial debe ser mayor o igual ' ||
				'a la fecha de hoy.',
				'exclamation')
			NEXT FIELD b14_fecha_ini
		END IF
-- OjO
{
		INITIALIZE r_b06.* TO NULL 
		SELECT * INTO r_b06.*
			FROM ctbt006
			WHERE b06_compania = vg_codcia
			  AND b06_ano      = YEAR(rm_b14.b14_fec_proceso)
			  AND b06_mes      = MONTH(rm_b14.b14_fec_proceso)
		IF r_b06.b06_mes IS NOT NULL THEN
			CALL fgl_winmessage(vg_producto,
				'Mes contable está bloqueado.',
				'exclamation')
			NEXT FIELD b14_fec_proceso
		END IF
}
	AFTER INPUT
		CALL muestra_paridad_moneda_actual()
END INPUT

END FUNCTION



FUNCTION muestra_paridad_moneda_actual()

LET rm_b14.b14_paridad = 
	calcula_paridad(rm_b14.b14_moneda, rm_b00.b00_moneda_base)
IF rm_b14.b14_paridad IS NULL THEN
	LET rm_b14.b14_moneda = rm_b00.b00_moneda_base
	DISPLAY BY NAME rm_b14.b14_moneda
	LET rm_b14.b14_paridad = 
		calcula_paridad(rm_b14.b14_moneda, rm_b00.b00_moneda_base)
END IF
DISPLAY BY NAME rm_b14.b14_paridad
		
END FUNCTION



FUNCTION control_consulta()

DEFINE expr_sql			VARCHAR(500)
DEFINE query			VARCHAR(600)

DEFINE r_g13		RECORD LIKE gent013.*
DEFINE r_b03		RECORD LIKE ctbt003.*

CLEAR FORM

LET INT_FLAG = 0
CONSTRUCT BY NAME expr_sql 
	   ON b14_codigo,    b14_tipo_comp,  b14_estado,
	      b14_glosa,     b14_moneda,
	      b14_paridad,   b14_veces_max, 
	      b14_fecha_ini, b14_veces_gen,
	      b14_ult_num,   b14_usuario
	ON KEY(F2)
		IF INFIELD(b14_tipo_comp) THEN
			CALL fl_ayuda_tipos_comprobantes(vg_codcia)
				RETURNING r_b03.b03_tipo_comp,
					  r_b03.b03_nombre
			IF r_b03.b03_tipo_comp IS NOT NULL THEN
				LET rm_b14.b14_tipo_comp = r_b03.b03_tipo_comp
				DISPLAY BY NAME rm_b14.b14_tipo_comp
			END IF
		END IF
		IF INFIELD(b14_moneda) THEN
			CALL fl_ayuda_monedas() RETURNING r_g13.g13_moneda,
							  r_g13.g13_nombre,
							  r_g13.g13_decimales
			IF r_g13.g13_moneda IS NOT NULL THEN
				LET rm_b14.b14_moneda = r_g13.g13_moneda
				DISPLAY BY NAME rm_b14.b14_moneda
				DISPLAY r_g13.g13_nombre TO n_moneda
			END IF
		END IF
		LET INT_FLAG = 0
	BEFORE CONSTRUCT
		CALL setea_nombre_botones_f1()
	AFTER FIELD b14_tipo_comp
		LET rm_b14.b14_tipo_comp = GET_FLDBUF(b14_tipo_comp)
		IF rm_b14.b14_tipo_comp IS NULL THEN
			CONTINUE CONSTRUCT
		END IF
		CALL fl_lee_tipo_comprobante_contable(vg_codcia, 
			rm_b14.b14_tipo_comp) RETURNING r_b03.*
		IF r_b03.b03_tipo_comp IS NULL THEN
			CLEAR n_tipo_comp
		END IF
		IF r_b03.b03_estado = 'B' THEN
			CLEAR n_tipo_comp
		END IF
	AFTER FIELD b14_moneda
		LET rm_b14.b14_moneda = GET_FLDBUF(b14_moneda)
		IF rm_b14.b14_moneda IS NULL THEN
			CLEAR n_moneda
		ELSE
			CALL fl_lee_moneda(rm_b14.b14_moneda) RETURNING r_g13.*
			IF r_g13.g13_moneda IS NULL THEN	
				CLEAR n_moneda
			ELSE
				IF  r_g13.g13_moneda <> rm_b00.b00_moneda_base
				AND r_g13.g13_moneda <> rm_b00.b00_moneda_aux
				THEN
					CLEAR n_moneda
				END IF
				IF r_g13.g13_estado = 'B' THEN
					CLEAR n_moneda
				ELSE
					DISPLAY r_g13.g13_nombre TO n_moneda
				END IF
			END IF 
		END IF
END CONSTRUCT

IF INT_FLAG THEN
	IF vm_num_rows > 0 THEN
		CALL lee_muestra_registro(vm_rows[vm_row_current])
	ELSE
		CLEAR FORM
	END IF
	RETURN
END IF

LET query = 'SELECT *, ROWID FROM ctbt014 ',
	    '	WHERE b14_compania  = ', vg_codcia,
	    '     AND ', expr_sql,
	    '	ORDER BY 1, 2, 3'
PREPARE cons FROM query
DECLARE q_cons CURSOR FOR cons
LET vm_num_rows = 1
FOREACH q_cons INTO rm_b14.*, vm_rows[vm_num_rows]
	LET vm_num_rows = vm_num_rows + 1
        IF vm_num_rows > vm_max_rows THEN
		EXIT FOREACH
	END IF	
END FOREACH 
LET vm_num_rows = vm_num_rows - 1
IF vm_num_rows = 0 THEN 
	CALL fl_mensaje_consulta_sin_registros()
	LET vm_num_rows = 0
	LET vm_row_current = 0
	CALL muestra_contadores()
	CLEAR FORM
	RETURN
END IF

LET vm_row_current = 1
CALL lee_muestra_registro(vm_rows[vm_row_current])

END FUNCTION



FUNCTION lee_muestra_registro(row)
DEFINE row 		INTEGER

IF vm_num_rows <= 0 THEN
	RETURN
END IF

SELECT * INTO rm_b14.* FROM ctbt014 WHERE ROWID = row
IF STATUS = NOTFOUND THEN
	ERROR 'No existe registro con rowid', row
END IF

DISPLAY BY NAME rm_b14.b14_tipo_comp, 
		rm_b14.b14_codigo, 
		rm_b14.b14_estado,
	      	rm_b14.b14_glosa,    
              	rm_b14.b14_moneda,  
              	rm_b14.b14_paridad,
 	      	rm_b14.b14_fecha_ini, 
		rm_b14.b14_veces_max,
	      	rm_b14.b14_veces_gen,
	      	rm_b14.b14_ult_num,
              	rm_b14.b14_usuario, 
              	rm_b14.b14_fecing
 	
CALL muestra_etiquetas()
CALL muestra_contadores()
CALL muestra_detalle()

END FUNCTION



FUNCTION setea_nombre_botones_f1()

DISPLAY 'Cuenta'	TO 	bt_cuenta
DISPLAY 'Descripcion'   TO 	bt_desc_cuenta
DISPLAY 'Crédito'	TO 	bt_credito
DISPLAY 'Débito'	TO 	bt_debito

END FUNCTION



FUNCTION muestra_contadores()

DISPLAY "" AT 1,1
DISPLAY vm_row_current, " de ", vm_num_rows AT 1, 68 

END FUNCTION



FUNCTION siguiente_registro()

IF vm_num_rows = 0 THEN
	RETURN
END IF

IF vm_row_current < vm_num_rows THEN
	LET vm_row_current = vm_row_current + 1
END IF
CALL lee_muestra_registro(vm_rows[vm_row_current])

END FUNCTION



FUNCTION anterior_registro()

IF vm_num_rows = 0 THEN
	RETURN
END IF

IF vm_row_current > 1 THEN
	LET vm_row_current = vm_row_current - 1
END IF
CALL lee_muestra_registro(vm_rows[vm_row_current])

END FUNCTION



FUNCTION muestra_etiquetas()

DEFINE nom_estado	CHAR(9)

DEFINE r_g13		RECORD LIKE gent013.*
DEFINE r_b04		RECORD LIKE ctbt004.*

CALL fl_lee_moneda(rm_b14.b14_moneda)		RETURNING r_g13.*

CASE rm_b14.b14_estado 
	WHEN 'A'
		LET nom_estado = 'ACTIVO'
	WHEN 'B'
		LET nom_estado = 'BLOQUEADO'
END CASE

DISPLAY nom_estado   		TO n_estado
DISPLAY r_g13.g13_nombre	TO n_moneda

END FUNCTION



FUNCTION calcula_paridad(moneda_ori, moneda_dest)

DEFINE moneda_ori	LIKE veht036.v36_moneda
DEFINE moneda_dest	LIKE veht036.v36_moneda
DEFINE paridad		LIKE veht036.v36_paridad_mb

DEFINE r_g14		RECORD LIKE gent014.*

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



FUNCTION ingresa_detalle()

DEFINE resp		CHAR(6)
DEFINE i		SMALLINT
DEFINE j		SMALLINT
DEFINE col              SMALLINT
DEFINE salir            SMALLINT
DEFINE query		CHAR(255)

DEFINE secuencia ARRAY[1000] OF SMALLINT

DEFINE r_b10		RECORD LIKE ctbt010.*

DEFINE credito		LIKE ctbt015.b15_valor_base
DEFINE debito		LIKE ctbt015.b15_valor_base

LET vm_columna_1 = 4
LET vm_columna_2 = 5
LET rm_orden[vm_columna_1]  = 'DESC'
LET rm_orden[vm_columna_2]  = 'ASC'
INITIALIZE col TO NULL

LET debito  = 0 
LET credito = 0
DISPLAY debito, credito TO tot_debito, tot_credito

LET salir = 0
WHILE NOT salir
        LET query = 'SELECT * FROM tmp_detalle ',
                    'ORDER BY ', vm_columna_1, ' ', rm_orden[vm_columna_1],
                           ', ', vm_columna_2, ' ', rm_orden[vm_columna_2]
        PREPARE deto FROM query
        DECLARE q_deto CURSOR FOR deto 
        LET i = 1
        FOREACH q_deto INTO secuencia[i], rm_cuenta[i].*
                LET i = i + 1
                IF i > vm_max_cta THEN
                        CALL fl_mensaje_arreglo_incompleto()
                        LET INT_FLAG = 1
                        RETURN
                END IF
        END FOREACH
	LET i = i - 1
	LET vm_ind_cta = i
        
        LET i = 1
        LET j = 1
        LET INT_FLAG = 0
	IF vm_ind_cta > 0 THEN
		CALL set_count(vm_ind_cta)
	END IF
	INPUT ARRAY rm_cuenta WITHOUT DEFAULTS FROM ra_cuenta.*
		ON KEY(INTERRUPT)
			LET INT_FLAG = 0
			CALL fl_mensaje_abandonar_proceso() RETURNING resp
			IF resp = 'Yes' THEN
				LET INT_FLAG = 1
				EXIT INPUT
			END IF
		ON KEY(F15)
			LET col = 2
			EXIT INPUT
		ON KEY(F16)
			LET col = 3
			EXIT INPUT
		ON KEY(F17)
			LET col = 4
			EXIT INPUT
		ON KEY(F18)
			LET col = 5
			EXIT INPUT
		ON KEY(F2)	
			IF INFIELD(b15_cuenta) THEN
				CALL fl_ayuda_cuenta_contable(vg_codcia, 
					vm_nivel_cta) 
					RETURNING r_b10.b10_cuenta, 
        					  r_b10.b10_descripcion 
				IF r_b10.b10_cuenta IS NOT NULL THEN
					LET rm_cuenta[i].cuenta = 
						r_b10.b10_cuenta
					LET rm_cuenta[i].desc_cuenta = 
						r_b10.b10_descripcion
					DISPLAY rm_cuenta[i].cuenta
						TO ra_cuenta[j].b15_cuenta
					DISPLAY r_b10.b10_descripcion 
						TO ra_cuenta[j].n_cuenta
				END IF	
			END IF
			LET INT_FLAG = 0	
		BEFORE INPUT
			LET vm_filas_pant = fgl_scr_size('ra_cuenta')
		BEFORE ROW
			LET i = arr_curr()
			LET j = scr_line()
		BEFORE DELETE
			CALL deleteRow(i, arr_count(), secuencia[i])
			EXIT INPUT
		BEFORE FIELD valor_credito
			LET credito = rm_cuenta[i].valor_credito
		AFTER FIELD b15_cuenta
			IF FIELD_TOUCHED(ra_cuenta[j].b15_cuenta,
					 ra_cuenta[j].n_cuenta,
					 ra_cuenta[j].valor_debito,
					 ra_cuenta[j].valor_credito
					) THEN
				CONTINUE INPUT
			END IF
			IF rm_cuenta[i].cuenta IS NOT NULL THEN
				CALL fl_lee_cuenta(vg_codcia, 
						   rm_cuenta[i].cuenta) 
					RETURNING r_b10.*
				IF r_b10.b10_cuenta IS NULL THEN
					CALL fgl_winmessage(vg_producto,
						'No existe cuenta contable.',
						'exclamation')
					NEXT FIELD b15_cuenta
				END IF
				IF r_b10.b10_nivel <> vm_nivel_cta THEN
					CALL fgl_winmessage(vg_producto,
						'La cuenta ingresada debe ' ||
						'ser del último nivel.',
						'exclamation')
					NEXT FIELD b15_cuenta
				END IF
				LET rm_cuenta[i].desc_cuenta = 
					r_b10.b10_descripcion
				DISPLAY rm_cuenta[i].desc_cuenta 
					TO ra_cuenta[j].n_cuenta
			END IF
		AFTER FIELD valor_credito
			IF rm_cuenta[i].valor_credito IS NULL THEN
				LET rm_cuenta[i].valor_credito = 0
				DISPLAY rm_cuenta[i].valor_credito
					TO ra_cuenta[j].valor_credito
			END IF
			IF rm_cuenta[i].valor_credito > 0 THEN
				LET rm_cuenta[i].valor_debito = 0
				DISPLAY rm_cuenta[i].valor_debito
					TO ra_cuenta[j].valor_debito
			END IF
			IF credito <> rm_cuenta[i].valor_credito 
			OR credito IS NULL 
			THEN
				LET secuencia[i] = 
					graba_valores(i, secuencia[i])
				CALL calcula_totales()
			END IF
		BEFORE FIELD valor_debito
			LET debito = rm_cuenta[i].valor_debito
		AFTER FIELD valor_debito
			IF rm_cuenta[i].valor_debito IS NULL THEN
				LET rm_cuenta[i].valor_debito = 0
				DISPLAY rm_cuenta[i].valor_debito
					TO ra_cuenta[j].valor_debito
			END IF
			IF rm_cuenta[i].valor_debito > 0 THEN
				LET rm_cuenta[i].valor_credito = 0
				DISPLAY rm_cuenta[i].valor_credito
					TO ra_cuenta[j].valor_credito
			END IF
			IF debito <> rm_cuenta[i].valor_debito 
			OR debito IS NULL 
			THEN
				LET secuencia[i] = 
					graba_valores(i, secuencia[i])
				CALL calcula_totales()
			END IF
		AFTER ROW
			IF  rm_cuenta[i].valor_debito = 0 
			AND rm_cuenta[i].valor_credito = 0 
			THEN
				NEXT FIELD ra_cuenta[j - 1].valor_debito
			END IF
			LET secuencia[i] = graba_valores(i, secuencia[i])
		AFTER INPUT
			SELECT SUM(valor_credito), SUM(valor_debito)
				INTO credito, debito
				FROM tmp_detalle
			IF credito <> debito THEN
				CALL fgl_winmessage(vg_producto,
					'No cuadran los valores del ' ||
					'crédito con el débito.',
					'exclamation')
				CONTINUE INPUT
			END IF
			LET vm_ind_cta = arr_count()
			LET salir = 1
	END INPUT
	IF INT_FLAG THEN
		RETURN
	END IF

	IF col IS NOT NULL AND NOT salir THEN
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
		INITIALIZE col TO NULL
	END IF
END WHILE	

END FUNCTION



FUNCTION graba_valores(i, sec)

DEFINE i		SMALLINT
DEFINE sec		SMALLINT

IF i > vm_ind_cta THEN
	SELECT MAX(secuencia) INTO sec
		FROM tmp_detalle
	IF sec IS NULL THEN
		LET sec = 1
	ELSE
		LET sec = sec + 1
	END IF
	INSERT INTO tmp_detalle VALUES(sec, rm_cuenta[i].*)
	LET vm_ind_cta = vm_ind_cta + 1
ELSE
	UPDATE tmp_detalle SET
		cuenta          = rm_cuenta[i].cuenta,
		desc_cuenta     = rm_cuenta[i].desc_cuenta,
		valor_credito   = rm_cuenta[i].valor_credito,
		valor_debito    = rm_cuenta[i].valor_debito
		WHERE secuencia = sec
END IF

RETURN sec

END FUNCTION



FUNCTION calcula_totales()
	
DEFINE tot_credito	LIKE ctbt015.b15_valor_base
DEFINE tot_debito 	LIKE ctbt015.b15_valor_base

SELECT SUM(valor_credito), SUM(valor_debito)
	INTO tot_credito, tot_debito
	FROM tmp_detalle
	
DISPLAY BY NAME tot_credito, tot_debito
	
END FUNCTION



FUNCTION lee_detalle()

DEFINE i		SMALLINT

DELETE FROM tmp_detalle

INSERT INTO tmp_detalle
	SELECT b15_secuencia, b15_cuenta, b10_descripcion, b15_valor_base, 0
	FROM ctbt015, ctbt010
	WHERE b15_compania  = vg_codcia
	  AND b15_codigo    = rm_b14.b14_codigo
	  AND b15_valor_base > 0
	  AND b10_compania  = b15_compania
	  AND b10_cuenta    = b15_cuenta
	  
INSERT INTO tmp_detalle
	SELECT b15_secuencia, b15_cuenta, b10_descripcion, 0, 
	       (b15_valor_base * (-1))
	FROM ctbt015, ctbt010
	WHERE b15_compania  = vg_codcia
	  AND b15_codigo    = rm_b14.b14_codigo
	  AND b15_valor_base < 0
	  AND b10_compania  = b15_compania
	  AND b10_cuenta    = b15_cuenta
	  
SELECT COUNT(*) INTO i FROM tmp_detalle
	  
RETURN i
	
END FUNCTION



FUNCTION muestra_detalle()

DEFINE i		SMALLINT
DEFINE filas_pant	SMALLINT

LET filas_pant = fgl_scr_size('ra_cuenta')
LET vm_filas_pant = filas_pant
FOR i = 1 TO filas_pant
	CLEAR ra_cuenta[i].*
END FOR

LET vm_ind_cta = lee_detalle()
IF vm_ind_cta = -1 THEN
	RETURN
END IF

IF vm_ind_cta < filas_pant THEN
	LET filas_pant = vm_ind_cta
END IF

DECLARE q_tmp1 CURSOR FOR
	SELECT cuenta, desc_cuenta, valor_debito, valor_credito 
		FROM tmp_detalle
		ORDER BY 3 DESC, 4 ASC
		
LET i = 1
FOREACH q_tmp1 INTO rm_cuenta[i].*
	DISPLAY rm_cuenta[i].* TO ra_cuenta[i].*
	LET i = i + 1
	IF i > filas_pant THEN
		EXIT FOREACH
	END IF
END FOREACH

CALL calcula_totales()

END FUNCTION



FUNCTION grabar_detalle()

DEFINE intentar		SMALLINT
DEFINE done 		SMALLINT

DEFINE query		CHAR(1000)

LET intentar = 1
LET done = 0
WHILE (intentar)
	WHENEVER ERROR CONTINUE
		DECLARE q_b15 CURSOR FOR
			SELECT * FROM ctbt015
				WHERE b15_compania = vg_codcia         
				  AND b15_codigo   = rm_b14.b14_codigo
			FOR UPDATE
	WHENEVER ERROR STOP
	IF STATUS < 0 THEN
		LET intentar = mensaje_intentar()
	ELSE
		LET intentar = 0
		LET done = 1
	END IF
END WHILE

IF NOT intentar AND NOT done THEN
	RETURN done
END IF

FOREACH q_b15
	DELETE FROM ctbt015 WHERE CURRENT OF q_b15
END FOREACH
FREE q_b15

LET query = 'INSERT INTO ctbt015 ',
	    '	SELECT ', vg_codcia, ', ', rm_b14.b14_codigo , ', ',
	    '           cuenta, secuencia, ',
	    '		(valor_credito * (-1)), ',
	    '           (valor_credito * (-1) * ', rm_b14.b14_paridad, ') ',
	    '		FROM tmp_detalle ', 
	    '		WHERE valor_credito > 0 '
PREPARE statement1 FROM query
EXECUTE statement1

LET query = 'INSERT INTO ctbt015 ', 
	    '	SELECT ', vg_codcia, ', ', rm_b14.b14_codigo , ', ',
	    '           cuenta, secuencia, ',
	    '		valor_debito, ',
	    '           (valor_debito * ', rm_b14.b14_paridad, ') ',
	    '		FROM tmp_detalle ', 
	    '		WHERE valor_debito > 0 '
PREPARE statement2 FROM query
EXECUTE statement2

RETURN done

END FUNCTION



FUNCTION mensaje_intentar()

DEFINE intentar		SMALLINT
DEFINE resp		CHAR(6)

LET intentar = 1
CALL fgl_winquestion(vg_producto, 
		     'Registro bloqueado por otro usuario, desea ' ||
                     'intentarlo nuevamente', 'No', 'Yes|No', 'question', 1)
				RETURNING resp
IF resp = 'No' THEN
	CALL fl_mensaje_abandonar_proceso()
		 RETURNING resp
	IF resp = 'Yes' THEN
		LET intentar = 0
	END IF	
END IF

RETURN intentar

END FUNCTION



FUNCTION control_detalle()

DEFINE i		SMALLINT
DEFINE j		SMALLINT
DEFINE col              SMALLINT
DEFINE salir            SMALLINT
DEFINE query		CHAR(255)

LET vm_columna_1 = 4
LET vm_columna_2 = 5
LET rm_orden[vm_columna_1]  = 'DESC'
LET rm_orden[vm_columna_2]  = 'ASC'
INITIALIZE col TO NULL

LET salir = 0
WHILE NOT salir
        LET query = 'SELECT * FROM tmp_detalle ',
                    'ORDER BY ', vm_columna_1, ' ', rm_orden[vm_columna_1],
                           ', ', vm_columna_2, ' ', rm_orden[vm_columna_2]
        PREPARE deto2 FROM query
        DECLARE q_deto2 CURSOR FOR deto2 
        LET i = 1
        FOREACH q_deto2 INTO j, rm_cuenta[i].*
                LET i = i + 1
                IF i > vm_max_cta THEN
                        EXIT FOREACH
                END IF
        END FOREACH
        LET vm_ind_cta = i - 1
        
        LET i = 1
        LET j = 1
        LET INT_FLAG = 0
	CALL set_count(vm_ind_cta)
	DISPLAY ARRAY rm_cuenta TO ra_cuenta.*
		ON KEY(INTERRUPT)
			EXIT DISPLAY
		ON KEY(F15)
			LET col = 2
			EXIT DISPLAY
		ON KEY(F16)
			LET col = 3
			EXIT DISPLAY
		ON KEY(F17)
			LET col = 4
			EXIT DISPLAY
		ON KEY(F18)
			LET col = 5
			EXIT DISPLAY
		BEFORE DISPLAY
			CALL dialog.keysetlabel('ACCEPT', '')
		AFTER DISPLAY
			CONTINUE DISPLAY
	END DISPLAY
	IF INT_FLAG THEN
		LET salir = 1
		LET INT_FLAG = 0
		CONTINUE WHILE
	END IF

	IF col IS NOT NULL AND NOT salir THEN
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
		INITIALIZE col TO NULL
	END IF
END WHILE	

END FUNCTION



FUNCTION deleteRow(i, num_rows, sec)

DEFINE i		SMALLINT
DEFINE sec		SMALLINT
DEFINE num_rows		SMALLINT

DELETE FROM tmp_detalle WHERE secuencia = sec

WHILE (i < num_rows)
	LET rm_cuenta[i].* = rm_cuenta[i + 1].*
	LET i = i + 1
END WHILE
INITIALIZE rm_cuenta[i].* TO NULL

END FUNCTION



FUNCTION control_bloquea_activa()

DEFINE resp    	CHAR(6)
DEFINE mensaje	VARCHAR(20)
DEFINE estado	CHAR(1)

LET int_flag = 0
IF vm_num_rows = 0 THEN
	CALL fl_mensaje_consultar_primero()
	RETURN
END IF

CALL lee_muestra_registro(vm_rows[vm_row_current])
LET resp = 'Yes'
	LET mensaje = 'Seguro de bloquear'
	IF rm_b14.b14_estado <> 'A' THEN
		LET mensaje = 'Seguro de activar'
	END IF
CALL fl_mensaje_seguro_ejecutar_proceso()
       	RETURNING resp
IF resp = 'Yes' THEN
	WHENEVER ERROR CONTINUE
	BEGIN WORK
	DECLARE q_del CURSOR FOR SELECT * FROM ctbt014
		WHERE ROWID = vm_rows[vm_row_current]
		FOR UPDATE
	OPEN q_del
	FETCH q_del INTO rm_b14.*
	IF status < 0 THEN
		CALL fl_mensaje_bloqueo_otro_usuario()
		WHENEVER ERROR STOP
		ROLLBACK WORK
		RETURN
	END IF

	LET estado = 'B'
	IF rm_b14.b14_estado <> 'A' THEN
		LET estado = 'A'
	END IF

	UPDATE ctbt014 SET b14_estado = estado WHERE CURRENT OF q_del
	COMMIT WORK
	CLOSE q_del
	WHENEVER ERROR STOP
	LET int_flag = 0 
	
	CALL fl_mensaje_registro_modificado()

	CLEAR FORM
	CALL lee_muestra_registro(vm_rows[vm_row_current])
END IF

END FUNCTION



FUNCTION execute_query()

LET vm_num_rows = 1
LET vm_row_current = 1

SELECT ROWID INTO vm_rows[vm_num_rows]
	FROM ctbt014
	WHERE b14_compania  = vg_codcia
	  AND b14_codigo    = vm_diario
IF STATUS = NOTFOUND THEN
	CALL fgl_winmessage(vg_producto, 
		'Diario periódico no existe.', 
		'exclamation')
	EXIT PROGRAM
ELSE
	CALL lee_muestra_registro(vm_rows[vm_row_current])
END IF

END FUNCTION



FUNCTION validar_parametros()

CALL fl_lee_modulo(vg_modulo) RETURNING rg_mod.*
IF rg_mod.g50_modulo IS NULL THEN
	CALL fgl_winmessage(vg_producto, 'No existe módulo: ' || vg_modulo, 
                            'stop')
	EXIT PROGRAM
END IF
CALL fl_lee_compania(vg_codcia) RETURNING rg_cia.*
IF rg_cia.g01_compania IS NULL THEN
	CALL fgl_winmessage(vg_producto, 'No existe compañía: '|| vg_codcia, 
                            'stop')
	EXIT PROGRAM
END IF
IF rg_cia.g01_estado <> 'A' THEN
	CALL fgl_winmessage(vg_producto, 'Compañía no está activa: ' || 
                            vg_codcia, 'stop')
	EXIT PROGRAM
END IF
IF vg_codloc IS NULL THEN
	LET vg_codloc   = fl_retorna_agencia_default(vg_codcia)
END IF
CALL fl_lee_localidad(vg_codcia, vg_codloc) RETURNING rg_loc.*
IF rg_loc.g02_localidad IS NULL THEN
	CALL fgl_winmessage(vg_producto, 'No existe localidad: ' || vg_codloc, 
                            'stop')
	EXIT PROGRAM
END IF
IF rg_loc.g02_estado <> 'A' THEN
	CALL fgl_winmessage(vg_producto, 'Localidad no está activa: ' || 
                            vg_codloc, 'stop')
	EXIT PROGRAM
END IF

END FUNCTION
