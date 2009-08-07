------------------------------------------------------------------------------
-- Titulo           : vehp205.4gl - Ingreso de Ajustes de Costos
-- Elaboracion      : 25-sep-2001
-- Autor            : JCM
-- Formato Ejecucion: fglrun vehp201 base modulo compania localidad [numtran]
--              Si (numtran <> 0) el programa se esta ejcutando en modo de
--                      solo consulta
--              Si (numtran = 0) el programa se esta ejecutando en forma
--                      independiente
-- Ultima Correccion: 
-- Motivo Correccion: 
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_demonios	VARCHAR(12)
DEFINE vm_numtran	LIKE veht030.v30_num_tran                      
DEFINE vm_transaccion	CHAR(2)

-- CADA VEZ QUE SE REALIZE UNA CONSULTA SE GUARDARAN LOS ROWID DE CADA FILA 
-- RECUPERADA EN UNA TABLA LLAMADA r_rows QUE TENDRA 1000 ELEMENTOS
DEFINE vm_rows ARRAY[1000] OF INTEGER  	-- ARREGLO DE ROWID DE FILAS LEIDAS
DEFINE vm_row_current	SMALLINT	-- FILA CORRIENTE DEL ARREGLO
DEFINE vm_num_rows	SMALLINT	-- CANTIDAD DE FILAS LEIDAS

DEFINE vm_max_rows	SMALLINT

--
-- DEFINE RECORD(S) HERE
--
DEFINE rm_cfg		RECORD LIKE veht000.*

DEFINE rm_v30		RECORD LIKE veht030.*
DEFINE rm_v31		RECORD LIKE veht031.*
DEFINE ajuste		LIKE veht022.v22_costo_adi
DEFINE chasis		LIKE veht022.v22_chasis



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/errores')
CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 AND num_args() <> 5 THEN     -- Validar # parámetros correcto
	CALL fgl_winmessage(vg_producto, 'Número de parámetros incorrecto', 
                            'stop')
	EXIT PROGRAM
END IF
LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_codcia   = arg_val(3)
LET vg_proceso = 'vehp205'

CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	-- Asigna un valor por default a vg_codloc
				-- que luego puede ser reemplazado si se 
                                -- mantiene sin comentario la siguiente linea
LET vg_codloc   = arg_val(4)

LET vm_numtran = 0
IF num_args() = 5 THEN
        LET vm_numtran  = arg_val(5)
END IF

CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()

END MAIN



FUNCTION funcion_master()

CALL fl_nivel_isolation()
CALL fl_chequeo_mes_proceso_veh(vg_codcia) RETURNING int_flag 
IF int_flag THEN
	RETURN
END IF
OPTIONS
	INPUT WRAP,
	ACCEPT KEY F12
OPEN WINDOW w_205 AT 3,2 WITH 21 ROWS, 80 COLUMNS
	ATTRIBUTE(FORM LINE FIRST + 2, COMMENT LINE LAST, MENU LINE FIRST,
		  BORDER, MESSAGE LINE LAST - 2) 
OPEN FORM f_205 FROM '../forms/vehf205_1'
DISPLAY FORM f_205

LET vm_num_rows = 0
LET vm_row_current = 0
INITIALIZE rm_v30.* TO NULL
INITIALIZE rm_v31.* TO NULL
CALL muestra_contadores()

LET vm_max_rows = 1000

SELECT g21_cod_tran INTO vm_transaccion 
	FROM gent021 
	WHERE g21_nombre LIKE '%AJUSTE%COSTO%'

SELECT * INTO rm_cfg.* FROM veht000 WHERE v00_compania = vg_codcia
IF rm_cfg.v00_compania IS NULL THEN
	CALL fgl_winmessage(vg_producto, 
		'No existe registro de configuración para esta compañía',
		'exclamation')
	EXIT PROGRAM
END IF

IF vm_numtran <> 0 THEN
	CALL execute_query()
END IF

MENU 'OPCIONES'
	BEFORE MENU
		HIDE OPTION 'Avanzar'
		HIDE OPTION 'Retroceder'
                IF vm_numtran <> 0 THEN         -- Se ejecuta en modo de solo
                        HIDE OPTION 'Ingresar'  -- consulta
                        HIDE OPTION 'Consultar'
                END IF
	COMMAND KEY('I') 'Ingresar' 		'Ingresar nuevos registros.'
		CALL control_ingreso()
		IF vm_row_current > 1 THEN
			SHOW OPTION 'Retroceder'
		END IF
		IF vm_row_current = vm_num_rows THEN
			HIDE OPTION 'Avanzar'
		END IF
	COMMAND KEY('C') 'Consultar' 		'Consultar un registro.'
		CALL control_consulta()
		IF vm_num_rows <= 1 THEN
			HIDE OPTION 'Avanzar'
			HIDE OPTION 'Retroceder'
		ELSE
			SHOW OPTION 'Avanzar'
		END IF
		IF vm_row_current <= 1 THEN
                        HIDE OPTION 'Retroceder'
                END IF
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
	COMMAND KEY('S') 'Salir'    		'Salir del programa.'
		EXIT MENU
END MENU

END FUNCTION



FUNCTION control_ingreso()

DEFINE costo_adi	LIKE veht022.v22_costo_adi
DEFINE resp		CHAR(6)
DEFINE intentar		SMALLINT
DEFINE done    		SMALLINT
DEFINE row_curr		SMALLINT

DEFINE r_g13		RECORD LIKE gent013.*

CLEAR FORM
INITIALIZE rm_v30.* TO NULL
INITIALIZE rm_v31.* TO NULL

-- INITIAL VALUES FOR rm_v30 FIELDS
LET rm_v30.v30_fecing      = CURRENT
LET rm_v30.v30_usuario     = vg_usuario
LET rm_v30.v30_compania    = vg_codcia
LET rm_v30.v30_localidad   = vg_codloc
LET rm_v30.v30_cod_tran    = vm_transaccion

-- INITIAL VALUES FOR rm_v31 FIELDS
LET rm_v31.v31_compania    = vg_codcia
LET rm_v31.v31_localidad   = vg_codloc
LET rm_v31.v31_cod_tran    = vm_transaccion

-- THESE FIELDS ARE NOT NULL BUT THERE ARE NOTHING TO PUT IN THEM --
LET rm_v30.v30_cont_cred   = 'C'
LET rm_v30.v30_nomcli      = ' '
LET rm_v30.v30_dircli      = ' '
LET rm_v30.v30_cedruc      = ' '
LET rm_v30.v30_descuento   = 0.0
LET rm_v30.v30_porc_impto  = 0.0
LET rm_v30.v30_paridad     = calcula_paridad(rm_v30.v30_moneda, 
					     rg_gen.g00_moneda_base)

CALL fl_lee_moneda(rm_v30.v30_moneda) RETURNING r_g13.*
LET rm_v30.v30_precision   = r_g13.g13_decimales
LET rm_v30.v30_tot_bruto   = 0.0
LET rm_v30.v30_tot_dscto   = 0.0
LET rm_v30.v30_flete       = 0.0

LET rm_v31.v31_descuento  = 0.0
LET rm_v31.v31_val_descto = 0.0
LET rm_v31.v31_precio     = 0.0
LET rm_v31.v31_costo      = 0.0
LET rm_v31.v31_fob        = 0.0
LET rm_v31.v31_costant_ma = 0.0
LET rm_v31.v31_costnue_ma = 0.0
--------------------------------------------------------------------

CALL lee_datos('I')
IF INT_FLAG THEN
	IF vm_num_rows = 0 THEN
		CLEAR FORM
	ELSE	
		CALL lee_muestra_registro(vm_rows[vm_row_current])
	END IF
	RETURN
END IF

BEGIN WORK

LET rm_v30.v30_bodega_dest = rm_v30.v30_bodega_ori 

-- TOTAL DE LA TRANSACCION --
LET rm_v30.v30_tot_costo = rm_v31.v31_costnue_mb
LET rm_v30.v30_tot_neto  = rm_v31.v31_costnue_mb
LET rm_v31.v31_costo     = rm_v31.v31_costant_mb
-----------------------------

LET rm_v30.v30_num_tran = nextValInSequence()
IF rm_v30.v30_num_tran = -1 THEN
	ROLLBACK WORK
	CLEAR FORM
	RETURN
END IF
INSERT INTO veht030 VALUES (rm_v30.*)
DISPLAY BY NAME rm_v30.v30_num_tran

IF vm_num_rows = vm_max_rows THEN
	LET vm_num_rows = 1
ELSE
	LET vm_num_rows = vm_num_rows + 1
END IF
LET row_curr = vm_row_current
LET vm_row_current = vm_num_rows
LET vm_rows[vm_num_rows] = SQLCA.SQLERRD[6] 	-- Rowid de la ultima fila 
                                             	-- procesada
LET rm_v31.v31_num_tran = rm_v30.v30_num_tran
INSERT INTO veht031 VALUES (rm_v31.*)

SELECT v22_costo_adi 
	INTO costo_adi 
	FROM veht022 
	WHERE v22_compania   = vg_codcia 
	  AND v22_localidad  = vg_codloc 
	  AND v22_codigo_veh = rm_v31.v31_codigo_veh
LET costo_adi = costo_adi + ajuste

-- REPITE HASTA QUE PUEDE ACTUALIZAR LA TABLA DE SERIES DE VEHICULOS
-- O HASTA QUE EL USUARIO DECIDA NO VOLVERLO A INTENTAR
	LET intentar = 1
	LET done = 0
	WHILE (intentar)
		WHENEVER ERROR CONTINUE
			UPDATE veht022 
				SET v22_costo_adi = costo_adi 
				WHERE v22_compania   = vg_codcia
				  AND v22_localidad  = vg_codloc
				  AND v22_codigo_veh = rm_v31.v31_codigo_veh
		WHENEVER ERROR STOP
		IF STATUS < 0 THEN
			CALL fgl_winquestion(vg_producto, 
      					     'Registro bloqueado por ' ||
				      	     'por otro usuario, desea ' ||
                                             'intentarlo nuevamente', 'No',
         				     'Yes|No', 'question', 1)
							RETURNING resp
			IF resp = 'No' THEN
				CALL fl_mensaje_abandonar_proceso()
					 RETURNING resp
				IF resp = 'Yes' THEN
					ROLLBACK WORK
					LET vm_num_rows = vm_num_rows - 1
					LET vm_row_current = row_curr
					LET intentar = 0
					LET done = 0
				END IF	
			END IF
		ELSE
			LET intentar = 0
			LET done = 1
		END IF
	END WHILE
IF intentar = 0 AND done = 0 THEN
	CLEAR FORM       
	RETURN
END IF

COMMIT WORK

CALL muestra_contadores()
CALL fl_mensaje_registro_ingresado()

END FUNCTION



FUNCTION lee_datos(flag)
DEFINE flag 		CHAR(1)
DEFINE resp 		CHAR(6)

DEFINE vendedor		LIKE veht001.v01_vendedor,
       nom_vendedor	LIKE veht001.v01_nombres

DEFINE bodega		LIKE veht002.v02_bodega,
       nom_bodega	LIKE veht002.v02_nombre

DEFINE r_v01		RECORD LIKE veht001.*
DEFINE r_v02		RECORD LIKE veht002.*
DEFINE r_v22		RECORD LIKE veht022.*
DEFINE r_serveh RECORD
        codigo_veh          LIKE veht022.v22_codigo_veh,
        chasis              LIKE veht022.v22_chasis,
        modelo              LIKE veht022.v22_modelo,
        cod_color           LIKE veht022.v22_cod_color,
        estado              LIKE veht022.v22_estado
        END RECORD

DEFINE costo_act 	LIKE veht022.v22_costo_ing	
DEFINE continuar	SMALLINT

LET INT_FLAG = 0
INPUT BY NAME rm_v30.v30_cod_tran, rm_v30.v30_vendedor, rm_v30.v30_bodega_ori, 
              rm_v31.v31_codigo_veh, rm_v30.v30_referencia, rm_v30.v30_moneda, 
              rm_v31.v31_costnue_mb, rm_v30.v30_usuario, rm_v30.v30_fecing 
	WITHOUT DEFAULTS
	ON KEY (INTERRUPT)
		IF NOT FIELD_TOUCHED(rm_v30.v30_vendedor, rm_v31.v31_codigo_veh,
                                     rm_v30.v30_bodega_ori, 
                                     rm_v30.v30_referencia, rm_v30.v30_moneda, 
                                     rm_v31.v31_costnue_mb
                                    ) THEN
			RETURN
		END IF

		LET INT_FLAG = 0
		CALL fl_mensaje_abandonar_proceso()
                	RETURNING resp
		IF resp = 'Yes' THEN
			LET INT_FLAG = 1
			RETURN
		END IF
	ON KEY(F2)
		IF INFIELD(v31_codigo_veh) THEN
			CALL fl_ayuda_serie_veh(vg_codcia, vg_codloc, 
                                                rm_v30.v30_bodega_ori) 
							RETURNING r_serveh.*
			IF r_serveh.codigo_veh IS NOT NULL THEN
				LET rm_v31.v31_codigo_veh = r_serveh.codigo_veh
				DISPLAY BY NAME rm_v31.v31_codigo_veh
				DISPLAY r_serveh.chasis TO serie_veh	
				LET chasis = r_serveh.chasis
				DISPLAY r_serveh.cod_color TO color_veh
				CALL fl_lee_cod_vehiculo_veh(vg_codcia, 
					vg_codloc,
        				r_serveh.codigo_veh) 
						RETURNING r_v22.*
				IF r_v22.v22_chasis IS NOT NULL THEN
					LET rm_v30.v30_bodega_ori = 
						r_v22.v22_bodega
					DISPLAY BY NAME rm_v30.v30_bodega_ori 
					DISPLAY r_v22.v22_modelo TO modelo_veh
					LET rm_v30.v30_moneda = 
						r_v22.v22_moneda_ing
					LET rm_v31.v31_moneda_cost = 
						r_v22.v22_moneda_ing
					DISPLAY BY NAME rm_v30.v30_moneda
					LET costo_act = r_v22.v22_costo_ing +
						r_v22.v22_cargo_ing +
             					r_v22.v22_costo_adi
					DISPLAY costo_act TO v31_costant_mb
					LET rm_v31.v31_costant_mb = costo_act
					LET rm_v31.v31_nuevo = r_v22.v22_nuevo
				END IF
			END IF
		END IF
		IF INFIELD(v30_vendedor) THEN
			CALL fl_ayuda_vendedores_veh(vg_codcia) 
				RETURNING vendedor, nom_vendedor
			IF vendedor IS NOT NULL THEN
				LET rm_v30.v30_vendedor = vendedor
				DISPLAY BY NAME rm_v30.v30_vendedor
				DISPLAY nom_vendedor TO n_vendedor
			END IF
		END IF
		IF INFIELD(v30_bodega_ori) THEN
			CALL fl_ayuda_bodegas_veh(vg_codcia) 
				RETURNING bodega, nom_bodega 
			IF bodega IS NOT NULL THEN
				LET rm_v30.v30_bodega_ori = bodega
				DISPLAY bodega TO v30_bodega_ori
				DISPLAY nom_bodega TO n_bodega
			END IF
		END IF
		LET INT_FLAG = 0
	AFTER FIELD v30_vendedor
		IF rm_v30.v30_vendedor IS NOT NULL THEN
			CALL fl_lee_vendedor_veh(vg_codcia, rm_v30.v30_vendedor)
				RETURNING r_v01.*
			IF r_v01.v01_vendedor IS NOT NULL THEN
				IF r_v01.v01_estado <> 'B' THEN
					DISPLAY r_v01.v01_nombres TO n_vendedor
				ELSE
					CALL fgl_winmessage(vg_producto,
						            'Vendedor está ' ||
                                                            'bloqueado',
							    'exclamation')
					CLEAR n_vendedor
					NEXT FIELD v30_vendedor
				END IF
			ELSE
				CALL fgl_winmessage(vg_producto,
					            'Vendedor no existe',
						    'exclamation')
				CLEAR n_vendedor
				NEXT FIELD v30_vendedor
			END IF
		ELSE
			CLEAR n_vendedor
		END IF		 
	AFTER FIELD v30_bodega_ori
		IF rm_v30.v30_bodega_ori IS NULL THEN
			CLEAR n_bodega
		ELSE
			CALL fl_lee_bodega_veh(vg_codcia, rm_v30.v30_bodega_ori)
				RETURNING r_v02.*
			IF r_v02.v02_bodega IS NOT NULL THEN
				IF r_v02.v02_estado <> 'B' THEN
					DISPLAY r_v02.v02_nombre TO n_bodega
				ELSE
					CALL fgl_winmessage(vg_producto,
						            'Bodega está ' ||
                                                            'bloqueada',
							    'exclamation')
					CLEAR n_bodega  
					NEXT FIELD v30_bodega_ori
				END IF
			ELSE
				CALL fgl_winmessage(vg_producto,
					            'Bodega no existe',
						    'exclamation')
				CLEAR n_bodega
				NEXT FIELD v30_bodega_ori
			END IF
		END IF
	BEFORE FIELD v31_codigo_veh
		IF rm_v30.v30_bodega_ori IS NULL THEN
			LET rm_v30.v30_bodega_ori = '00'
		END IF
	AFTER FIELD v31_codigo_veh
		IF rm_v31.v31_codigo_veh IS NULL THEN
			CLEAR serie_veh, modelo_veh, color_veh
			INITIALIZE rm_v30.v30_moneda TO NULL
			DISPLAY BY NAME rm_v30.v30_moneda 
			INITIALIZE rm_v31.v31_costant_mb TO NULL
			DISPLAY BY NAME rm_v31.v31_costant_mb
			INITIALIZE rm_v31.v31_costnue_mb TO NULL
			DISPLAY BY NAME rm_v31.v31_costnue_mb
		ELSE
			CALL fl_lee_cod_vehiculo_veh(vg_codcia, vg_codloc, 
					rm_v31.v31_codigo_veh)
						RETURNING r_v22.*
			IF r_v22.v22_chasis IS NULL THEN
				CALL fgl_winmessage(vg_producto,
                                                    'Serie no existe',
                                                    'exclamation')
				CLEAR serie_veh, modelo_veh, color_veh 
				INITIALIZE rm_v30.v30_moneda TO NULL
				DISPLAY BY NAME rm_v30.v30_moneda 
				INITIALIZE rm_v31.v31_costant_mb TO NULL
				DISPLAY BY NAME rm_v31.v31_costant_mb
				INITIALIZE rm_v31.v31_costnue_mb TO NULL
				DISPLAY BY NAME rm_v31.v31_costnue_mb
				NEXT FIELD v31_codigo_veh
			ELSE
				LET continuar = 1
				IF r_v22.v22_estado = 'F' THEN
					CALL fgl_winmessage(vg_producto,
							    'Esta serie ya ' ||
							    'ha sido facturada',
 		                                            'exclamation')
					LET continuar = 0
				END IF 
				IF r_v22.v22_estado = 'P' THEN
					CALL fgl_winmessage(vg_producto,
							    'No puede ajustar'||
							    ' costo a esta ' ||
                                                            ' serie',
 		                                            'exclamation')
					LET continuar = 0
				END IF 
				IF r_v22.v22_estado = 'B' THEN
					CALL fgl_winmessage(vg_producto,
							    'Serie bloqueada',
 		                                            'exclamation')
					LET continuar = 0
				END IF 
				IF rm_v30.v30_bodega_ori <> r_v22.v22_bodega 
					THEN
					CALL fgl_winmessage(vg_producto,
							    'Serie no existe' ||
							    ' en esta bodega',
							    'exclamation')
					LET continuar = 0
				END IF 
				IF continuar = 0 THEN
					CLEAR serie_veh, modelo_veh, color_veh 
					INITIALIZE rm_v30.v30_moneda TO NULL
					DISPLAY BY NAME rm_v30.v30_moneda 
					INITIALIZE rm_v31.v31_costant_mb TO NULL
					DISPLAY BY NAME rm_v31.v31_costant_mb
					INITIALIZE rm_v31.v31_costnue_mb TO NULL
					DISPLAY BY NAME rm_v31.v31_costnue_mb
					NEXT FIELD v31_codigo_veh
				END IF
				DISPLAY r_v22.v22_chasis TO serie_veh	
				LET chasis = r_v22.v22_chasis
				DISPLAY r_v22.v22_cod_color TO color_veh
				DISPLAY r_v22.v22_modelo TO modelo_veh
				LET rm_v30.v30_moneda = r_v22.v22_moneda_ing
				DISPLAY BY NAME rm_v30.v30_moneda
				LET costo_act = r_v22.v22_costo_ing +
						r_v22.v22_cargo_ing +
             					r_v22.v22_costo_adi
				LET rm_v31.v31_costant_mb = costo_act
				DISPLAY BY NAME rm_v31.v31_costant_mb
				LET rm_v31.v31_nuevo = r_v22.v22_nuevo
			END IF
		END IF
		CALL muestra_etiquetas()
	AFTER FIELD v31_costnue_mb
		IF rm_v31.v31_costant_mb IS NULL THEN
			CONTINUE INPUT
		END IF
		IF rm_v31.v31_costnue_mb IS NOT NULL THEN
			LET rm_v31.v31_costnue_mb = 
				fl_retorna_precision_valor(rm_v30.v30_moneda,
 						        rm_v31.v31_costnue_mb)
			LET ajuste = 
				rm_v31.v31_costnue_mb - rm_v31.v31_costant_mb
		END IF
END INPUT

END FUNCTION



FUNCTION control_consulta()

DEFINE expr_sql			VARCHAR(500)
DEFINE query			VARCHAR(600)
DEFINE g13_moneda		LIKE gent013.g13_moneda, 
       nombre			LIKE gent013.g13_nombre, 
       decimales 		LIKE gent013.g13_decimales

DEFINE vendedor			LIKE veht001.v01_vendedor,
       nom_vendedor		LIKE veht001.v01_nombres

DEFINE bodega			LIKE veht002.v02_bodega,
       nom_bodega		LIKE veht002.v02_nombre

DEFINE r_v01		RECORD LIKE veht001.*
DEFINE r_v02		RECORD LIKE veht002.*
DEFINE r_v22		RECORD LIKE veht022.*
DEFINE r_serveh RECORD
        codigo_veh          LIKE veht022.v22_codigo_veh,
        chasis              LIKE veht022.v22_chasis,
        modelo              LIKE veht022.v22_modelo,
        cod_color           LIKE veht022.v22_cod_color,
        bodega              LIKE veht022.v22_bodega
        END RECORD

CLEAR FORM

LET INT_FLAG = 0
CONSTRUCT BY NAME expr_sql 
	ON v30_num_tran, v30_vendedor, v30_bodega_ori, v31_codigo_veh,
           v30_referencia, v30_moneda, v31_costant_mb, v31_costnue_mb,
           v30_usuario
	ON KEY(F2)
		IF INFIELD(v30_vendedor) THEN
			CALL fl_ayuda_vendedores_veh(vg_codcia) 
				RETURNING vendedor, nom_vendedor
			IF vendedor IS NOT NULL THEN
				LET rm_v30.v30_vendedor = vendedor
				DISPLAY BY NAME rm_v30.v30_vendedor
				DISPLAY nom_vendedor TO n_vendedor
			END IF
		END IF
		IF INFIELD(v30_bodega_ori) THEN
			CALL fl_ayuda_bodegas_veh(vg_codcia) 
				RETURNING bodega, nom_bodega 
			IF bodega IS NOT NULL THEN
				LET rm_v30.v30_bodega_ori = bodega
				DISPLAY bodega TO v30_bodega_ori
				DISPLAY nom_bodega TO n_bodega
			END IF
		END IF
		IF INFIELD(v30_moneda) THEN
			CALL fl_ayuda_monedas() 
				RETURNING g13_moneda, nombre, decimales 
			IF g13_moneda IS NOT NULL THEN
				LET rm_v30.v30_moneda = g13_moneda
				DISPLAY BY NAME rm_v30.v30_moneda
				DISPLAY nombre TO n_moneda
			END IF	
		END IF
		IF INFIELD(v31_codigo_veh) THEN
			CALL fl_ayuda_serie_veh(vg_codcia, vg_codloc, 
                                                rm_v30.v30_bodega_ori) 
							RETURNING r_serveh.*
			IF r_serveh.codigo_veh IS NOT NULL THEN
				LET rm_v31.v31_codigo_veh = r_serveh.codigo_veh
				DISPLAY BY NAME rm_v31.v31_codigo_veh
				DISPLAY r_serveh.chasis TO serie_veh	
				LET chasis = r_serveh.chasis
				DISPLAY r_serveh.cod_color TO color_veh
				DISPLAY r_serveh.modelo TO modelo_veh
			END IF
		END IF
	AFTER FIELD v30_vendedor
		LET rm_v30.v30_vendedor = GET_FLDBUF(v30_vendedor)
		IF rm_v30.v30_vendedor IS NOT NULL THEN
			CALL fl_lee_vendedor_veh(vg_codcia, rm_v30.v30_vendedor)
				RETURNING r_v01.*
			IF r_v01.v01_vendedor IS NOT NULL THEN
				IF r_v01.v01_estado <> 'B' THEN
					DISPLAY r_v01.v01_nombres TO n_vendedor
				ELSE
					CLEAR n_vendedor
				END IF
			ELSE
				CLEAR n_vendedor
			END IF
		ELSE
			CLEAR n_vendedor
		END IF		 
	AFTER FIELD v30_bodega_ori
		LET rm_v30.v30_bodega_ori = GET_FLDBUF(v30_bodega_ori)
		IF rm_v30.v30_bodega_ori IS NULL THEN
			CLEAR n_bodega
		ELSE
			CALL fl_lee_bodega_veh(vg_codcia, rm_v30.v30_bodega_ori)
				RETURNING r_v02.*
			IF r_v02.v02_bodega IS NOT NULL THEN
				IF r_v02.v02_estado <> 'B' THEN
					DISPLAY r_v02.v02_nombre TO n_bodega
				ELSE
					CLEAR n_bodega  
				END IF
			ELSE
				CLEAR n_bodega
			END IF
		END IF
	BEFORE FIELD v31_codigo_veh
		LET rm_v30.v30_bodega_ori = GET_FLDBUF(v30_bodega_ori)
		IF rm_v30.v30_bodega_ori IS NULL THEN
			LET rm_v30.v30_bodega_ori = '00'
		END IF
	AFTER FIELD v31_codigo_veh
		LET rm_v31.v31_codigo_veh = GET_FLDBUF(v31_codigo_veh)
		IF rm_v31.v31_codigo_veh IS NULL THEN
			CLEAR serie_veh, modelo_veh, color_veh
			INITIALIZE rm_v30.v30_moneda TO NULL
			DISPLAY BY NAME rm_v30.v30_moneda 
			INITIALIZE rm_v31.v31_costant_mb TO NULL
			DISPLAY BY NAME rm_v31.v31_costant_mb
			INITIALIZE rm_v31.v31_costnue_mb TO NULL
			DISPLAY BY NAME rm_v31.v31_costnue_mb
		ELSE
			CALL fl_lee_cod_vehiculo_veh(vg_codcia, vg_codloc, 
					rm_v31.v31_codigo_veh)
						RETURNING r_v22.*
			IF r_v22.v22_chasis IS NULL THEN
				CLEAR serie_veh, modelo_veh, color_veh 
				INITIALIZE rm_v30.v30_moneda TO NULL
				DISPLAY BY NAME rm_v30.v30_moneda 
				INITIALIZE rm_v31.v31_costant_mb TO NULL
				DISPLAY BY NAME rm_v31.v31_costant_mb
				INITIALIZE rm_v31.v31_costnue_mb TO NULL
				DISPLAY BY NAME rm_v31.v31_costnue_mb
			ELSE
				IF r_v22.v22_estado = 'F' OR 
                                   r_v22.v22_estado = 'P' OR
				   r_v22.v22_estado = 'B' THEN
					CLEAR serie_veh, modelo_veh, color_veh 
					INITIALIZE rm_v30.v30_moneda TO NULL
					DISPLAY BY NAME rm_v30.v30_moneda 
					INITIALIZE rm_v31.v31_costant_mb TO NULL
					DISPLAY BY NAME rm_v31.v31_costant_mb
					INITIALIZE rm_v31.v31_costnue_mb TO NULL
					DISPLAY BY NAME rm_v31.v31_costnue_mb
				END IF 
				DISPLAY r_v22.v22_chasis TO serie_veh	
				LET chasis = r_v22.v22_chasis
				DISPLAY r_v22.v22_cod_color TO color_veh
				DISPLAY r_v22.v22_modelo TO modelo_veh
			END IF
		END IF
		CALL muestra_etiquetas()
END CONSTRUCT

IF INT_FLAG THEN
	IF vm_num_rows = 0 THEN
		CLEAR FORM
	ELSE	
		CALL lee_muestra_registro(vm_rows[vm_row_current])
	END IF
	RETURN
END IF


LET query = 'SELECT veht030.*, veht030.ROWID FROM veht030, veht031 ', 
	    '	WHERE v30_compania  = ', vg_codcia, 
	    '     AND v30_localidad = ', vg_codloc,
	    '	  AND v30_cod_tran  = "', vm_transaccion, '"',
	    '     AND v31_compania  = v30_compania  ', 
	    '     AND v31_localidad = v30_localidad ', 
	    '	  AND v31_cod_tran  = v30_cod_tran  ', 
	    '     AND v31_num_tran  = v30_num_tran  ',
	    '     AND ', expr_sql,
	    ' ORDER BY 1, 2, 3, 4' 
PREPARE cons FROM query
DECLARE q_cons CURSOR FOR cons
LET vm_num_rows = 1
FOREACH q_cons INTO rm_v30.*, vm_rows[vm_num_rows]
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



FUNCTION lee_muestra_registro(row)
DEFINE row 		INTEGER

DEFINE r_v22		RECORD LIKE veht022.*

IF vm_num_rows <= 0 THEN
	RETURN
END IF

SELECT * INTO rm_v30.* FROM veht030 WHERE ROWID = row
IF STATUS = NOTFOUND THEN
	ERROR 'No existe registro con rowid', row
END IF

SELECT * INTO rm_v31.* 
	FROM veht031 
	WHERE v31_compania  = vg_codcia
	  AND v31_localidad = vg_codloc
	  AND v31_cod_tran  = vm_transaccion
	  AND v31_num_tran  = rm_v30.v30_num_tran

CALL fl_lee_cod_vehiculo_veh(vg_codcia, vg_codloc, rm_v31.v31_codigo_veh) 
	RETURNING r_v22.*

DISPLAY BY NAME rm_v30.v30_cod_tran,
		rm_v30.v30_num_tran,
                rm_v30.v30_referencia,
		rm_v30.v30_vendedor,
		rm_v30.v30_bodega_ori,
		rm_v30.v30_moneda,
		rm_v30.v30_usuario,
		rm_v30.v30_fecing,
		rm_v31.v31_codigo_veh,
		rm_v31.v31_costant_mb,
		rm_v31.v31_costnue_mb
DISPLAY r_v22.v22_chasis TO serie_veh
DISPLAY r_v22.v22_modelo TO modelo_veh
DISPLAY r_v22.v22_cod_color TO color_veh

CALL muestra_etiquetas()
CALL muestra_contadores()

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

DEFINE r_v01		RECORD LIKE veht001.*
DEFINE r_v02		RECORD LIKE veht002.*
DEFINE r_v05		RECORD LIKE veht005.*
DEFINE r_g13		RECORD LIKE gent013.*
DEFINE r_v22		RECORD LIKE veht022.*

CALL fl_lee_vendedor_veh(vg_codcia, rm_v30.v30_vendedor) RETURNING r_v01.*
DISPLAY r_v01.v01_nombres TO n_vendedor

CALL fl_lee_bodega_veh(vg_codcia, rm_v30.v30_bodega_ori) RETURNING r_v02.*
DISPLAY r_v02.v02_nombre TO n_bodega

CALL fl_lee_cod_vehiculo_veh(vg_codcia, vg_codloc, rm_v31.v31_codigo_veh) 
	RETURNING r_v22.*
CALL fl_lee_color_veh(vg_codcia, r_v22.v22_cod_color) RETURNING r_v05.*
DISPLAY r_v05.v05_descri_base TO n_color

CALL fl_lee_moneda(rm_v30.v30_moneda) RETURNING r_g13.*
DISPLAY r_g13.g13_nombre TO n_moneda

END FUNCTION



FUNCTION nextValInSequence()

DEFINE resp		CHAR(6)
DEFINE retVal 		SMALLINT

LET retVal = -1
WHILE retVal = -1

LET retVal = fl_actualiza_control_secuencias(vg_codcia, vg_codloc, vg_modulo,
					 'AA', vm_transaccion)
IF retVal = 0 THEN
	EXIT PROGRAM
END IF
IF retVal <> -1 THEN
	 EXIT WHILE
END IF

CALL fgl_winquestion(vg_producto, 'La tabla de secuencias de transacciones ' ||
                     'está siendo accesada por otro usuario, espere unos  ' ||
                     'segundos y vuelva a intentar', 'No', 'Yes|No|Cancel',
                     'question', 1) RETURNING resp 
IF resp <> 'Yes' THEN
	EXIT WHILE	
END IF

END WHILE

RETURN retVal

END FUNCTION



FUNCTION execute_query()
                                                                                
LET vm_num_rows = 1
LET vm_row_current = 1
                                                                                
SELECT ROWID INTO vm_rows[vm_num_rows]
        FROM veht030
        WHERE v30_compania  = vg_codcia
          AND v30_localidad = vg_codloc
	  AND v30_cod_tran  = vm_transaccion
          AND v30_num_tran  = vm_numtran
IF STATUS = NOTFOUND THEN
        CALL fgl_winmessage(vg_producto, 
		'No existe ajuste de costo.',
		'exclamation')
        EXIT PROGRAM
ELSE
        CALL lee_muestra_registro(vm_rows[vm_row_current])
END IF
                                                                                
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
