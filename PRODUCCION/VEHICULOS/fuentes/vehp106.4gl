------------------------------------------------------------------------------
-- Titulo           : vehp106.4gl - Mantenimiento planes de financiamiento
-- Elaboracion      : 14-sep-2001
-- Autor            : JCM
-- Formato Ejecucion: fglrun vehp106 base modulo compania
-- Ultima Correccion: 
-- Motivo Correccion: 
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_demonios	VARCHAR(12)

-- CADA VEZ QUE SE REALIZE UNA CONSULTA SE GUARDARAN LOS ROWID DE CADA FILA 
-- RECUPERADA EN UNA TABLA LLAMADA r_rows QUE TENDRA 1000 ELEMENTOS
DEFINE vm_rows ARRAY[1000] OF INTEGER  	-- ARREGLO DE ROWID DE FILAS LEIDAS
DEFINE vm_row_current	SMALLINT	-- FILA CORRIENTE DEL ARREGLO
DEFINE vm_num_rows	SMALLINT	-- CANTIDAD DE FILAS LEIDAS
DEFINE vm_max_rows      SMALLINT        -- MAXIMO DE FILAS LEIDAS


DEFINE vm_cartera	LIKE gent011.g11_tiporeg
DEFINE vm_num_filas	SMALLINT
--
-- DEFINE RECORD(S) HERE
--
DEFINE		rm_v06		RECORD LIKE veht006.*
DEFINE 		rm_coefi ARRAY[100] OF RECORD
			v07_num_meses		LIKE veht007.v07_num_meses,
			v07_coefi_letra		LIKE veht007.v07_coefi_letra,
			v07_coefi_adic		LIKE veht007.v07_coefi_adic
		END RECORD

DEFINE vm_indice	SMALLINT



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/errores')
CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 3 THEN          -- Validar # parámetros correcto
	CALL fgl_winmessage(vg_producto, 'Número de parámetros incorrecto', 
                            'stop')
	EXIT PROGRAM
END IF
LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_codcia   = arg_val(3)
LET vg_proceso = 'vehp106'

CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	-- Asigna un valor por default a vg_codloc
				-- que luego puede ser reemplazado si se 
                                -- mantiene sin comentario la siguiente linea
CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()

END MAIN



FUNCTION funcion_master()

CALL fl_nivel_isolation()
LET vm_max_rows = 1000
OPTIONS
	INPUT WRAP,
	ACCEPT KEY F12
OPEN WINDOW w_v06 AT 3,2 WITH 21 ROWS, 80 COLUMNS
	ATTRIBUTE(FORM LINE FIRST + 2, COMMENT LINE LAST, MENU LINE FIRST,
		  BORDER, MESSAGE LINE LAST - 2) 
OPEN FORM f_v06 FROM '../forms/vehf106_1'
DISPLAY FORM f_v06

-- 
LET vm_cartera = 'CR'
--

LET vm_num_rows = 0
LET vm_row_current = 0
INITIALIZE rm_v06.* TO NULL
CALL muestra_contadores()

INITIALIZE vm_indice TO NULL

MENU 'OPCIONES'
	BEFORE MENU
		HIDE OPTION 'Avanzar'
		HIDE OPTION 'Retroceder'
		HIDE OPTION 'Modificar'
		HIDE OPTION 'Bloquear/Activar'
		HIDE OPTION 'Coeficientes'
	COMMAND KEY('I') 'Ingresar' 		'Ingresar nuevos registros.'
		IF vm_num_rows = vm_max_rows THEN
			CALL fl_mensaje_arreglo_lleno()
		ELSE
			CALL control_ingreso()
		END IF
		IF vm_num_rows = 1 THEN
			SHOW OPTION 'Modificar'
			SHOW OPTION 'Bloquear/Activar'
		END IF
		IF vm_row_current > 1 THEN
			SHOW OPTION 'Retroceder'
		END IF
		IF vm_row_current = vm_num_rows THEN
			HIDE OPTION 'Avanzar'
		END IF
		SHOW OPTION 'Coeficientes'
		IF vm_num_rows = 0 THEN
			HIDE OPTION 'Coeficientes'
		END IF
	COMMAND KEY('M') 'Modificar' 		'Modificar registro corriente.'
		CALL control_modificacion()
	COMMAND KEY('C') 'Consultar' 		'Consultar un registro.'
		CALL control_consulta()
		IF vm_num_rows <= 1 THEN
			SHOW OPTION 'Modificar'
			SHOW OPTION 'Bloquear/Activar'
			HIDE OPTION 'Avanzar'
			HIDE OPTION 'Retroceder'
			IF vm_num_rows = 0 THEN
				HIDE OPTION 'Modificar'
				HIDE OPTION 'Bloquear/Activar'
			END IF
		ELSE
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Modificar'
			SHOW OPTION 'Bloquear/Activar'
		END IF
		IF vm_row_current <= 1 THEN
                        HIDE OPTION 'Retroceder'
                END IF
		SHOW OPTION 'Coeficientes'
	COMMAND KEY('F') 'Coeficientes'         'Información sobre el plan.'
		CALL coeficientes('C')
	COMMAND KEY('A') 'Avanzar' 		'Ver siguiente registro.'
		CALL siguiente_registro()
		IF vm_row_current = vm_num_rows THEN
			HIDE OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
			NEXT OPTION 'Retroceder'
		ELSE
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
		END IF
	COMMAND KEY('R') 'Retroceder' 		'Ver anterior registro.'
		CALL anterior_registro()
		IF vm_row_current = 1 THEN
			HIDE OPTION 'Retroceder'
			SHOW OPTION 'Avanzar'
			NEXT OPTION 'Avanzar'
		ELSE
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
		END IF
	COMMAND KEY('B') 'Bloquear/Activar'     'Bloquea o activa registro.'
		CALL control_bloquea_activa()
	COMMAND KEY('S') 'Salir'    		'Salir del programa.'
		EXIT MENU
END MENU

END FUNCTION



FUNCTION control_ingreso()

DEFINE row_current	INTEGER
DEFINE i 		SMALLINT
DEFINE r_v07		RECORD LIKE veht007.*

CLEAR FORM
INITIALIZE rm_v06.* TO NULL

LET rm_v06.v06_usuario     = vg_usuario
LET rm_v06.v06_fecing      = CURRENT
LET rm_v06.v06_compania    = vg_codcia
LET rm_v06.v06_estado = 'A'
DISPLAY 'ACTIVO' TO n_estado
LET rm_v06.v06_cred_direct = 'N'
LET rm_v06.v06_seguro      = 'N'
LET rm_v06.v06_adicionales = 'N'

CALL lee_datos('I')
IF INT_FLAG THEN
	IF vm_num_rows = 0 THEN
		CLEAR FORM
	ELSE	
		CALL lee_muestra_registro(vm_rows[vm_row_current])
	END IF
	RETURN
END IF

SELECT MAX(v06_codigo_plan) INTO rm_v06.v06_codigo_plan	FROM veht006
IF rm_v06.v06_codigo_plan IS NULL THEN
	LET rm_v06.v06_codigo_plan = 1
ELSE
	LET rm_v06.v06_codigo_plan = rm_v06.v06_codigo_plan + 1
END IF

BEGIN WORK

LET row_current = vm_row_current

INSERT INTO veht006 VALUES (rm_v06.*)

DISPLAY BY NAME rm_v06.v06_codigo_plan

LET vm_num_rows    = vm_num_rows + 1
LET vm_row_current = vm_num_rows
LET vm_rows[vm_num_rows] = SQLCA.SQLERRD[6] 	-- Rowid de la ultima fila 
                                             	-- procesada
CALL coeficientes('I')
IF INT_FLAG THEN
	ROLLBACK WORK
	LET vm_num_rows    = vm_num_rows - 1
	LET vm_row_current = row_current
	IF vm_num_rows = 0 THEN
		CLEAR FORM
	ELSE
		CALL lee_muestra_registro(vm_rows[vm_row_current])	
	END IF	
	RETURN
END IF

COMMIT WORK

CALL muestra_contadores()
CALL muestra_etiquetas()

LET r_v07.v07_compania    = vg_codcia
LET r_v07.v07_codigo_plan = rm_v06.v06_codigo_plan
FOR i = 1 TO vm_num_filas
	LET r_v07.v07_num_meses   = rm_coefi[i].v07_num_meses
	LET r_v07.v07_coefi_letra = rm_coefi[i].v07_coefi_letra
	IF rm_coefi[i].v07_coefi_adic IS NOT NULL THEN
		LET r_v07.v07_coefi_adic  = rm_coefi[i].v07_coefi_adic
	ELSE
		LET r_v07.v07_coefi_adic  = 0                          
	END IF

	INSERT INTO veht007 VALUES(r_v07.*)
END FOR 

CALL fl_mensaje_registro_ingresado() 

END FUNCTION



FUNCTION control_modificacion()

DEFINE i 	SMALLINT
DEFINE r_v07	RECORD LIKE veht007.*

IF vm_num_rows = 0 THEN   
	CALL fl_mensaje_consultar_primero() 
	RETURN
END IF

IF rm_v06.v06_estado = 'I' THEN 
	CALL fl_mensaje_estado_bloqueado() 
	RETURN
END IF

CALL lee_muestra_registro(vm_rows[vm_row_current])

WHENEVER ERROR CONTINUE
BEGIN WORK
DECLARE q_upd CURSOR FOR 
	SELECT * FROM veht006 WHERE ROWID = vm_rows[vm_row_current]
	FOR UPDATE
OPEN q_upd
FETCH q_upd INTO rm_v06.*
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

UPDATE veht006 SET * = rm_v06.* WHERE CURRENT OF q_upd

LET r_v07.v07_compania    = vg_codcia
LET r_v07.v07_codigo_plan = rm_v06.v06_codigo_plan
DELETE FROM veht007 
	WHERE v07_compania    = r_v07.v07_compania
	  AND v07_codigo_plan = r_v07.v07_codigo_plan
FOR i = 1 TO vm_indice     
	LET r_v07.v07_num_meses   = rm_coefi[i].v07_num_meses
	LET r_v07.v07_coefi_letra = rm_coefi[i].v07_coefi_letra
	IF rm_coefi[i].v07_coefi_adic IS NOT NULL THEN
		LET r_v07.v07_coefi_adic  = rm_coefi[i].v07_coefi_adic
	ELSE
		LET r_v07.v07_coefi_adic  = 0                          
	END IF
	INSERT INTO veht007 VALUES(r_v07.*)
END FOR 

COMMIT WORK
CLOSE q_upd
CALL fl_mensaje_registro_modificado() 

END FUNCTION



FUNCTION lee_datos(flag)

DEFINE flag 		CHAR(1)
DEFINE resp 		CHAR(6)
DEFINE i		SMALLINT

DEFINE cod_cobranzas	LIKE cxct001.z01_codcli
DEFINE nom_cliente	LIKE cxct001.z01_nomcli

DEFINE entidad		LIKE gent011.g11_tiporeg,
       n_entidad	LIKE gent011.g11_nombre,
       subtipo          LIKE gent012.g12_subtipo,
       n_subtipo        LIKE gent012.g12_nombre

DEFINE r_cligen		RECORD LIKE cxct001.*
DEFINE r_g12		RECORD LIKE gent012.*


IF flag = 'M' THEN
	CALL lee_detalle()
END IF

LET INT_FLAG = 0
INPUT BY NAME rm_v06.v06_codigo_plan, rm_v06.v06_nonbre_plan, rm_v06.v06_estado,
              rm_v06.v06_tasa_finan,  rm_v06.v06_plazo,   rm_v06.v06_porc_inic, 
              rm_v06.v06_cred_direct, rm_v06.v06_codigo_cobr, 
              rm_v06.v06_cod_cartera, rm_v06.v06_seguro, rm_v06.v06_adicionales,
              rm_v06.v06_num_adic, rm_v06.v06_usuario,
              rm_v06.v06_fecing WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		IF NOT FIELD_TOUCHED(rm_v06.v06_codigo_plan, 
                                     rm_v06.v06_nonbre_plan, 
                                     rm_v06.v06_codigo_cobr, 
                                     rm_v06.v06_cred_direct, 
                                     rm_v06.v06_cod_cartera, 
                                     rm_v06.v06_seguro, rm_v06.v06_tasa_finan,
                                     rm_v06.v06_plazo, rm_v06.v06_porc_inic, 
                                     rm_v06.v06_adicionales, 
       				     rm_v06.v06_num_adic 
                                    ) THEN
			RETURN
		END IF

		LET INT_FLAG = 0
		CALL fl_mensaje_abandonar_proceso() RETURNING resp
		IF resp = 'Yes' THEN
			LET INT_FLAG = 1
			RETURN
		END IF
	ON KEY(F5)
		IF flag = 'M' THEN
			CALL coeficientes(flag)
		ELSE
			CALL fgl_winmessage(vg_producto, 
                                            'Primero debe grabar el registro',
                                            'exclamation')
                END IF                                           
	ON KEY(F2)
            	IF INFIELD(v06_codigo_cobr) THEN
         	  	CALL fl_ayuda_cliente_localidad(vg_codcia, vg_codloc) 
				RETURNING cod_cobranzas, nom_cliente
                  	LET rm_v06.v06_codigo_cobr = cod_cobranzas
                 	DISPLAY BY NAME rm_v06.v06_codigo_cobr  
			DISPLAY nom_cliente TO n_cliente
            	END IF
		IF INFIELD(v06_cod_cartera) THEN
			CALL fl_ayuda_subtipo_cartera()
				RETURNING subtipo, n_subtipo
                        IF subtipo IS NOT NULL THEN
				LET rm_v06.v06_cod_cartera = subtipo
				DISPLAY BY NAME rm_v06.v06_cod_cartera
				DISPLAY n_subtipo TO n_cartera
			END IF
		END IF
		LET INT_FLAG = 0
	AFTER FIELD v06_codigo_cobr
		IF rm_v06.v06_codigo_cobr IS NULL THEN
			CLEAR n_cliente
		ELSE
			IF rm_v06.v06_cred_direct = 'S' THEN
				CALL fgl_winmessage(vg_producto,
					'El plan es un crédito directo y ' ||
					'no puede tener un código de cobranzas',
					'exclamation')
				INITIALIZE rm_v06.v06_codigo_cobr TO NULL
				DISPLAY BY NAME rm_v06.v06_codigo_cobr 
				CLEAR n_cliente
				NEXT FIELD NEXT
			END IF
			CALL fl_lee_cliente_general(rm_v06.v06_codigo_cobr) 
				RETURNING r_cligen.*
			IF r_cligen.z01_codcli IS NULL THEN
              			CALL fgl_winmessage(vg_producto,
                                                    'No existe un cliente '||
                                                    'con ese código',
                                                    'exclamation')
				CLEAR n_cliente
				NEXT FIELD v06_codigo_cobr
        		END IF   
			IF r_cligen.z01_estado = 'B' THEN
              			CALL fgl_winmessage(vg_producto,
                                                    'El cliente '||
                                                    'está bloqueado',
                                                    'exclamation')
				CLEAR n_cliente
				NEXT FIELD v06_codigo_cobr
			END IF
			LET rm_v06.v06_codigo_cobr = r_cligen.z01_codcli
        		DISPLAY BY NAME rm_v06.v06_codigo_cobr
			DISPLAY r_cligen.z01_nomcli TO n_cliente
		END IF
	AFTER  FIELD v06_cod_cartera
		IF rm_v06.v06_cod_cartera IS NULL THEN
			CLEAR n_cartera
		ELSE
			CALL fl_lee_subtipo_entidad(vm_cartera, 
                                                    rm_v06.v06_cod_cartera) 
							RETURNING r_g12.*
			IF r_g12.g12_subtipo IS NULL THEN
				CALL fgl_winmessage(vg_producto,
                                                    'Cartera no existe',
                                                    'exclamation')
				CLEAR n_cartera
				NEXT FIELD v06_cod_cartera
			ELSE
				DISPLAY r_g12.g12_nombre TO n_cartera
			END IF
		END IF				 	
	AFTER  FIELD v06_adicionales
		IF rm_v06.v06_adicionales = 'N' THEN
			LET rm_v06.v06_num_adic = 0
			DISPLAY BY NAME rm_v06.v06_num_adic
		END IF
	BEFORE  FIELD v06_num_adic
		IF rm_v06.v06_adicionales = 'N' THEN
			IF FGL_LASTKEY() = FGL_KEYVAL('up') THEN
				NEXT FIELD v06_adicionales
			ELSE
				NEXT FIELD NEXT
			END IF
		END IF
END INPUT

END FUNCTION



FUNCTION control_consulta()

DEFINE expr_sql			VARCHAR(500)
DEFINE query			VARCHAR(600)

DEFINE plan		LIKE veht006.v06_codigo_plan
DEFINE nom_plan 	LIKE veht006.v06_nonbre_plan

DEFINE cod_cobranzas	LIKE cxct001.z01_codcli
DEFINE nom_cliente	LIKE cxct001.z01_nomcli

DEFINE entidad		LIKE gent011.g11_tiporeg,
       n_entidad	LIKE gent011.g11_nombre,
       subtipo		LIKE gent012.g12_subtipo,
       n_subtipo	LIKE gent012.g12_nombre

DEFINE r_cligen		RECORD LIKE cxct001.*
DEFINE r_g12		RECORD LIKE gent012.*

CLEAR FORM

LET INT_FLAG = 0
CONSTRUCT BY NAME expr_sql 
 	   ON v06_codigo_plan, v06_estado, v06_nonbre_plan, v06_tasa_finan, 
	      v06_plazo, v06_porc_inic, v06_cred_direct, v06_codigo_cobr, 
              v06_cod_cartera, v06_seguro, v06_adicionales, v06_num_adic, 
              v06_usuario
	ON KEY(F2)
		IF INFIELD(v06_codigo_plan) THEN
			CALL fl_ayuda_planes_finan_veh(vg_codcia) 
				RETURNING plan, nom_plan
			IF plan IS NOT NULL THEN
				LET rm_v06.v06_codigo_plan = plan
				DISPLAY BY NAME rm_v06.v06_codigo_plan
				DISPLAY nom_plan TO v06_nonbre_plan
			END IF 
		END IF
            	IF INFIELD(v06_codigo_cobr) THEN
         	  	CALL fl_ayuda_cliente_localidad(vg_codcia, vg_codloc) 
				RETURNING cod_cobranzas, nom_cliente
                  	LET rm_v06.v06_codigo_cobr = cod_cobranzas
                 	DISPLAY BY NAME rm_v06.v06_codigo_cobr  
			DISPLAY nom_cliente TO n_cliente
            	END IF
		IF INFIELD(v06_cod_cartera) THEN
			CALL fl_ayuda_subtipo_cartera()
				RETURNING subtipo, n_subtipo
                        IF subtipo IS NOT NULL THEN
				LET rm_v06.v06_cod_cartera = subtipo
				DISPLAY BY NAME rm_v06.v06_cod_cartera
				DISPLAY n_subtipo TO n_cartera
			END IF
		END IF
		LET INT_FLAG = 0
	AFTER FIELD v06_codigo_cobr
		LET rm_v06.v06_codigo_cobr = GET_FLDBUF(v06_codigo_cobr)
		IF rm_v06.v06_codigo_cobr IS NULL THEN
			CLEAR n_cliente
		ELSE
			CALL fl_lee_cliente_general(rm_v06.v06_codigo_cobr) 
				RETURNING r_cligen.*
			IF r_cligen.z01_codcli IS NULL THEN
				CLEAR n_cliente
			ELSE
				DISPLAY r_cligen.z01_nomcli TO n_cliente
			END IF
		END IF
	AFTER  FIELD v06_cod_cartera
		LET rm_v06.v06_cod_cartera = GET_FLDBUF(v06_cod_cartera)
		IF rm_v06.v06_cod_cartera IS NULL THEN
			CLEAR n_cartera
		ELSE
			CALL fl_lee_subtipo_entidad(vm_cartera, 
                                                    rm_v06.v06_cod_cartera) 
							RETURNING r_g12.*
			IF r_g12.g12_subtipo IS NULL THEN
				CLEAR n_cartera
			ELSE
				DISPLAY r_g12.g12_nombre TO n_cartera
			END IF
		END IF				 	
END CONSTRUCT

IF INT_FLAG THEN
	IF vm_num_rows = 0 THEN
		CLEAR FORM
	ELSE	
		CALL lee_muestra_registro(vm_rows[vm_row_current])
	END IF
	RETURN
END IF

LET query = 'SELECT *, ROWID FROM veht006 WHERE ', expr_sql, 
            ' ORDER BY 3' 
PREPARE cons FROM query
DECLARE q_cons CURSOR FOR cons
LET vm_num_rows = 1
FOREACH q_cons INTO rm_v06.*, vm_rows[vm_num_rows]
	LET vm_num_rows = vm_num_rows + 1
        IF vm_num_rows > 1000 THEN
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
CALL fl_mensaje_seguro_ejecutar_proceso() RETURNING resp

IF resp = 'Yes' THEN
	WHENEVER ERROR CONTINUE
	BEGIN WORK
	DECLARE q_del CURSOR FOR SELECT * FROM veht006 
		WHERE ROWID = vm_rows[vm_row_current]
		FOR UPDATE
	OPEN q_del
	FETCH q_del INTO rm_v06.*
	IF status < 0 THEN
		CALL fl_mensaje_bloqueo_otro_usuario()
		WHENEVER ERROR STOP
		ROLLBACK WORK
		RETURN
	END IF

	LET estado = 'I'
	IF rm_v06.v06_estado <> 'A' THEN
		LET estado = 'A'
	END IF

	UPDATE veht006 SET v06_estado = estado WHERE CURRENT OF q_del
	COMMIT WORK
	CLOSE q_del
	WHENEVER ERROR STOP
	LET int_flag = 0 
	
	CALL fl_mensaje_registro_modificado()

	CLEAR FORM
	CALL lee_muestra_registro(vm_rows[vm_row_current])
END IF

END FUNCTION



FUNCTION lee_muestra_registro(row)
DEFINE row 		INTEGER

IF vm_num_rows <= 0 THEN
	RETURN
END IF

SELECT * INTO rm_v06.* FROM veht006 WHERE ROWID = row
IF STATUS = NOTFOUND THEN
	ERROR 'No existe registro con rowid', row
END IF

DISPLAY BY NAME rm_v06.v06_codigo_plan,
                rm_v06.v06_nonbre_plan,
		rm_v06.v06_estado,
		rm_v06.v06_codigo_cobr,
		rm_v06.v06_cred_direct,
		rm_v06.v06_cod_cartera,
		rm_v06.v06_seguro,
		rm_v06.v06_tasa_finan,
		rm_v06.v06_plazo,
		rm_v06.v06_porc_inic,
		rm_v06.v06_adicionales,
		rm_v06.v06_num_adic,
		rm_v06.v06_usuario,
		rm_v06.v06_fecing
CALL muestra_etiquetas()
CALL muestra_contadores()

END FUNCTION



FUNCTION muestra_contadores()

DISPLAY "" AT 1,1
DISPLAY vm_row_current, " de ", vm_num_rows AT 1, 70 

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

DEFINE nom_estado		CHAR(9)
DEFINE r_cligen			RECORD LIKE cxct001.*
DEFINE r_g12			RECORD LIKE gent012.*

IF rm_v06.v06_estado = 'A' THEN
	LET nom_estado = 'ACTIVO'
ELSE
	LET nom_estado = 'INACTIVO'
END IF

CALL fl_lee_cliente_general(rm_v06.v06_codigo_cobr) RETURNING r_cligen.*
CALL fl_lee_subtipo_entidad(vm_cartera, rm_v06.v06_cod_cartera) 
	RETURNING r_g12.*

DISPLAY r_cligen.z01_nomcli TO n_cliente
DISPLAY r_g12.g12_nombre    TO n_cartera
DISPLAY nom_estado          TO n_estado

END FUNCTION



FUNCTION lee_detalle()

DEFINE i		SMALLINT
DEFINE query		CHAR(250)

LET query = 'SELECT v07_num_meses, v07_coefi_letra, v07_coefi_adic' || 
	    ' FROM veht007 WHERE v07_compania = ' || vg_codcia || ' AND' ||
	    ' v07_codigo_plan = ' || rm_v06.v06_codigo_plan || ' ORDER BY 1' 
PREPARE cons1 FROM query
DECLARE q_cons1 CURSOR FOR cons1
LET i = 1
FOREACH q_cons1 INTO rm_coefi[i].*
	IF rm_coefi[i].v07_coefi_adic = 0 THEN
		INITIALIZE rm_coefi[i].v07_coefi_adic TO NULL
	END IF
	LET i = i + 1
      	IF i > 100 THEN
		EXIT FOREACH
	END IF	
END FOREACH 

LET i = i - 1
LET vm_indice = i

END FUNCTION



FUNCTION coeficientes(flag)

DEFINE flag 		CHAR(1)
DEFINE i 		SMALLINT
DEFINE filas_pant	SMALLINT
define query		CHAR(250)

LET filas_pant = 10

IF vm_num_rows = 0 THEN   
	CALL fl_mensaje_consultar_primero() 
	RETURN
END IF

IF flag <> 'C' AND rm_v06.v06_estado = 'I' THEN 
	CALL fl_mensaje_estado_bloqueado() 
	RETURN
END IF


OPTIONS
	INPUT WRAP,
	ACCEPT KEY F12
OPEN WINDOW w_coefi AT 5, 9 WITH 17 ROWS, 50 COLUMNS
	ATTRIBUTE(FORM LINE FIRST, BORDER, 
		  MESSAGE LINE LAST, COMMENT LINE LAST) 
OPEN FORM f_coefi FROM '../forms/vehf106_2'
DISPLAY FORM f_coefi

CALL setea_botones_coeficientes()

DISPLAY rm_v06.v06_codigo_plan TO codigo_plan
DISPLAY rm_v06.v06_nonbre_plan TO n_plan 

IF flag = 'C' THEN
	CALL lee_detalle()
	CALL mostrar_coefi(vm_indice)
ELSE
	CALL ingresar_coefi(vm_indice)
END IF

CLOSE FORM   f_coefi
CLOSE WINDOW w_coefi

END FUNCTION



FUNCTION mostrar_coefi(i)

DEFINE i 		SMALLINT
DEFINE j 		SMALLINT

CALL set_count(i)
LET INT_FLAG = 0
DISPLAY ARRAY rm_coefi TO ra_coefi_scr.*
	BEFORE DISPLAY
		CALL dialog.keysetlabel('ACCEPT', '')
		CALL setea_botones_coeficientes()
	AFTER DISPLAY
		CONTINUE DISPLAY
	ON KEY(INTERRUPT)
		EXIT DISPLAY
END DISPLAY

END FUNCTION



FUNCTION ingresar_coefi(i)

DEFINE i 		SMALLINT
DEFINE j		SMALLINT
DEFINE scr_index	SMALLINT
DEFINE modified		SMALLINT

DEFINE resp 		CHAR(6)

LET i = vm_indice
LET j = 1
WHILE TRUE
	CALL set_count(i)
	LET modified = 0
	LET INT_FLAG = 0
	INPUT ARRAY rm_coefi WITHOUT DEFAULTS FROM ra_coefi_scr.*
		ON KEY(INTERRUPT)
                        IF NOT modified THEN
                                EXIT INPUT
                        END IF
                                                                                
                        LET INT_FLAG = 0
                        CALL fl_mensaje_abandonar_proceso() RETURNING resp
                        IF resp = 'Yes' THEN
                                LET INT_FLAG = 1
                                EXIT INPUT
                        END IF
		BEFORE FIELD v07_coefi_letra
			LET modified = 1
		BEFORE INSERT
			LET j = arr_curr()
			LET scr_index = scr_line() 

			LET rm_coefi[j].v07_num_meses = j
			DISPLAY j TO ra_coefi_scr[scr_index].v07_num_meses
		BEFORE DELETE
			IF i = arr_count() THEN
				LET i = arr_count() - 1
			ELSE
				LET i = arr_count()
			END IF
			EXIT INPUT
		BEFORE INPUT
			CALL dialog.keysetlabel('INSERT', '')
			CALL setea_botones_coeficientes()
		AFTER INPUT
			LET vm_num_filas = arr_count()
			FOR i = 1 TO vm_num_filas
			IF rm_coefi[i].v07_coefi_letra IS NULL THEN
				CALL fgl_winmessage(vg_producto,
						    'No puede dejar lineas '||
						    'en blanco',
						    'exclamation')
				CONTINUE INPUT
			END IF
			IF rm_coefi[i].v07_coefi_adic IS NULL THEN
				LET rm_coefi[i].v07_coefi_adic = 0
			END IF
			END FOR
			EXIT WHILE
	END INPUT
	IF INT_FLAG THEN 
		RETURN 
	END IF
END WHILE

LET vm_indice = vm_num_filas

END FUNCTION



FUNCTION setea_botones_coeficientes()

DISPLAY 'Mes'          TO bt_mes
DISPLAY 'Coeficiente'  TO bt_coefi
DISPLAY 'Coefi. Adic.' TO bt_coefi_adic

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
