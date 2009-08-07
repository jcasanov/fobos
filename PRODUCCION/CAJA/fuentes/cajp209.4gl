{*
 * Titulo           : cajp209.4gl - Facturacion 
 * Elaboracion      : 27-abr-2009
 * Autor            : JCM
 * Formato Ejecucion: fglrun cajp209 base modulo compania localidad 
 *	                  [tipo_fuente num_fuente]
 *}
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_tipo_fuente	LIKE cajt010.j10_tipo_fuente
DEFINE vm_num_fuente	LIKE cajt010.j10_num_fuente

DEFINE vm_rowid		INTEGER
--
-- DEFINE RECORD(S) HERE
--
DEFINE rm_j02		RECORD LIKE cajt002.*
DEFINE rm_j10		RECORD LIKE cajt010.*



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/cajp209.error')
CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 AND num_args() <> 6 THEN -- Validar # parámetros correcto
	CALL fgl_winmessage(vg_producto, 'Número de parámetros incorrecto', 
                            'stop')
	EXIT PROGRAM
END IF
LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_codcia   = arg_val(3)
LET vg_proceso = 'cajp209'

CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	-- Asigna un valor por default a vg_codloc
				-- que luego puede ser reemplazado si se 
                                -- mantiene sin comentario la siguiente linea
LET vg_codloc   = arg_val(4)

LET vm_num_fuente = 0
IF num_args() = 6 THEN
	LET vm_tipo_fuente = arg_val(5)
	LET vm_num_fuente  = arg_val(6)
END IF

CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()

END MAIN



FUNCTION funcion_master()

DEFINE salir		SMALLINT
DEFINE resp 		CHAR(3)  

CALL fl_nivel_isolation()
OPTIONS
	INPUT WRAP,
	ACCEPT KEY F12
OPEN WINDOW w_209 AT 3,2 WITH 14 ROWS, 80 COLUMNS
	ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, BORDER, MENU LINE 0, 
		  MESSAGE LINE LAST - 2) 
OPEN FORM f_209 FROM '../forms/cajf209_1'
DISPLAY FORM f_209

IF vm_num_fuente <> 0 THEN
	CALL execute_query()
	EXIT PROGRAM
END IF

MENU 'OPCIONES'
	COMMAND KEY('C') 'Consultar'		'Consultar un registro para facturar' 
		CALL lee_datos_cabecera()
		LET int_flag = 0
	COMMAND KEY('F') 'Facturar'			'Facturar el registro actual'
		CALL proceso_master_transacciones_caja()
	COMMAND KEY('S') 'Salir'			'Salir al menu principal'
		EXIT MENU
END MENU

CLOSE WINDOW w_209

END FUNCTION



FUNCTION lee_datos_cabecera()

DEFINE resp 		CHAR(6)

DEFINE tipo_fuente	LIKE cajt010.j10_tipo_fuente

DEFINE r_r23		RECORD LIKE rept023.* 	-- Preventa Repuestos
DEFINE r_v26		RECORD LIKE veht026.* 	-- Preventa Vehiculos
DEFINE r_t23		RECORD LIKE talt023.*	-- Orden de Trabajo
DEFINE r_j10		RECORD LIKE cajt010.*

INITIALIZE rm_j10.* TO NULL
LET rm_j10.j10_tipo_fuente = 'OT'
LET INT_FLAG = 0
INPUT BY NAME rm_j10.j10_tipo_fuente, rm_j10.j10_num_fuente WITHOUT DEFAULTS
	ON KEY (INTERRUPT)
		IF NOT FIELD_TOUCHED(j10_tipo_fuente, j10_num_fuente) THEN
			RETURN
		END IF

		LET INT_FLAG = 0
		CALL fl_mensaje_abandonar_proceso() RETURNING resp
		IF resp = 'Yes' THEN
			LET INT_FLAG = 1
			RETURN
		END IF
	ON KEY(F2)
		IF INFIELD(j10_num_fuente) THEN
			CALL fl_ayuda_numero_fuente_caja(vg_codcia, vg_codloc, 
							 rm_j10.j10_tipo_fuente)
					RETURNING r_j10.j10_num_fuente,
						  r_j10.j10_nomcli,
						  r_j10.j10_valor 
			IF r_j10.j10_num_fuente IS NOT NULL THEN
				LET rm_j10.j10_num_fuente = r_j10.j10_num_fuente
				DISPLAY BY NAME rm_j10.j10_num_fuente
			END IF
		END IF
		LET INT_FLAG = 0
	ON KEY(F5)
		IF INFIELD(j10_tipo_fuente) OR INFIELD(j10_num_fuente) THEN
			LET tipo_fuente = rm_j10.j10_tipo_fuente
			LET rm_j10.j10_tipo_fuente = GET_FLDBUF(j10_tipo_fuente)
			IF tipo_fuente = rm_j10.j10_tipo_fuente THEN
				IF rm_j10.j10_num_fuente IS NOT NULL THEN
					CALL ver_documento_origen()
				END IF
			ELSE
				CALL dialog.keysetlabel('F5', '')
			END IF
		END IF
		LET INT_FLAG = 0
	BEFORE INPUT
		CALL dialog.keysetlabel('F5', '')
	BEFORE FIELD j10_tipo_fuente
		LET tipo_fuente = rm_j10.j10_tipo_fuente
	AFTER FIELD j10_tipo_fuente
		IF rm_j10.j10_tipo_fuente <> tipo_fuente THEN
			CALL dialog.keysetlabel('F5', '')
		END IF
	AFTER FIELD j10_num_fuente
		IF rm_j10.j10_num_fuente IS NULL THEN
			CLEAR FORM
			DISPLAY BY NAME rm_j10.j10_tipo_fuente,
					rm_j10.j10_num_fuente
			CALL dialog.keysetlabel('F5', '')
			CONTINUE INPUT
		END IF
		CALL fl_lee_cabecera_caja(vg_codcia, vg_codloc, 
					  rm_j10.j10_tipo_fuente,
					  rm_j10.j10_num_fuente) 
						RETURNING r_j10.* 	 
		IF r_j10.j10_num_fuente IS NULL THEN
			CALL fgl_winmessage(vg_producto,
				'Registro no existe.',
				'exclamation')
			CLEAR FORM
			DISPLAY BY NAME rm_j10.j10_tipo_fuente,
					rm_j10.j10_num_fuente
			CALL dialog.keysetlabel('F5', '')
			NEXT FIELD j10_num_fuente
		END IF
		IF r_j10.j10_estado <> 'A' THEN
			CALL fgl_winmessage(vg_producto,
				'Registro de caja no está activo.',
				'exclamation')
			CLEAR FORM
			DISPLAY BY NAME rm_j10.j10_tipo_fuente,
					rm_j10.j10_num_fuente
			CALL dialog.keysetlabel('F5', '')
			NEXT FIELD j10_num_fuente
		END IF
		CASE rm_j10.j10_tipo_fuente
			WHEN 'PR'
				CALL fl_lee_preventa_rep(vg_codcia, vg_codloc,
					r_j10.j10_num_fuente) RETURNING r_r23.*
				IF r_r23.r23_numprev IS NULL THEN
					CALL fgl_winmessage(vg_producto,
						'Preventa no existe',
						'exclamation')
					CLEAR FORM
					DISPLAY BY NAME rm_j10.j10_tipo_fuente,
							rm_j10.j10_num_fuente
					CALL dialog.keysetlabel('F5', '')
					NEXT FIELD j10_num_fuente
				END IF
				IF r_r23.r23_estado <> 'P' THEN
					CALL fgl_winmessage(vg_producto,
						'Preventa no ha sido aprobada.',
						'exclamation')
					CLEAR FORM
					DISPLAY BY NAME rm_j10.j10_tipo_fuente,
							rm_j10.j10_num_fuente
					CALL dialog.keysetlabel('F5', '')
					NEXT FIELD j10_num_fuente
				END IF
			WHEN 'PV'
				CALL fl_lee_preventa_veh(vg_codcia, vg_codloc,
					r_j10.j10_num_fuente) RETURNING r_v26.*
				IF r_v26.v26_numprev IS NULL THEN
					CALL fgl_winmessage(vg_producto,
						'Preventa no existe',
						'exclamation')
					CLEAR FORM
					DISPLAY BY NAME rm_j10.j10_tipo_fuente,
							rm_j10.j10_num_fuente
					CALL dialog.keysetlabel('F5', '')
					NEXT FIELD j10_num_fuente
				END IF
				IF r_v26.v26_estado <> 'P' THEN
					CALL fgl_winmessage(vg_producto,
						'Preventa no ha sido aprobada.',
						'exclamation')
					CLEAR FORM
					DISPLAY BY NAME rm_j10.j10_tipo_fuente,
							rm_j10.j10_num_fuente
					CALL dialog.keysetlabel('F5', '')
					NEXT FIELD j10_num_fuente
				END IF
			WHEN 'OT'
				CALL fl_lee_orden_trabajo(vg_codcia, vg_codloc,
					r_j10.j10_num_fuente) RETURNING r_t23.*
				IF r_t23.t23_orden IS NULL THEN
					CALL fgl_winmessage(vg_producto,
						'Orden de trabajo no existe.',
						'exclamation')
					CLEAR FORM
					DISPLAY BY NAME rm_j10.j10_tipo_fuente,
							rm_j10.j10_num_fuente
					CALL dialog.keysetlabel('F5', '')
					NEXT FIELD j10_num_fuente
				END IF
				IF r_t23.t23_estado <> 'C' THEN
					CALL fgl_winmessage(vg_producto,
						'Orden de trabajo no ha ' ||
						'sido cerrada.',
						'exclamation')
					CLEAR FORM
					DISPLAY BY NAME rm_j10.j10_tipo_fuente,
							rm_j10.j10_num_fuente
					CALL dialog.keysetlabel('F5', '')
					NEXT FIELD j10_num_fuente
				END IF
		END CASE

		LET rm_j10.* = r_j10.*
		CALL muestra_registro()
		CALL dialog.keysetlabel('F5', 'Ver Documento')
END INPUT

END FUNCTION



FUNCTION muestra_registro()

DEFINE r_g03		RECORD LIKE gent003.*
DEFINE r_g13		RECORD LIKE gent013.*

DISPLAY BY NAME rm_j10.j10_areaneg,
		rm_j10.j10_codcli,
		rm_j10.j10_nomcli,
		rm_j10.j10_moneda,
		rm_j10.j10_tipo_destino,
		rm_j10.j10_num_destino,
		rm_j10.j10_valor,
		rm_j10.j10_fecha_pro,
		rm_j10.j10_usuario

CALL fl_lee_area_negocio(vg_codcia, rm_j10.j10_areaneg) RETURNING r_g03.*
DISPLAY r_g03.g03_nombre TO n_areaneg

CALL fl_lee_moneda(rm_j10.j10_moneda) RETURNING r_g13.*
DISPLAY r_g13.g13_nombre TO n_moneda

END FUNCTION



FUNCTION ver_documento_origen()

DEFINE comando		CHAR(250)

IF rm_j10.j10_num_fuente IS NULL THEN
	CALL fgl_winmessage(vg_producto,
		'Debe especificar un documento primero.',
		'exclamation')
	RETURN
END IF

CASE rm_j10.j10_tipo_fuente
	WHEN 'PR'	-- fglrun repp209 vg_base RE vg_codcia vg_codloc numprev
		LET comando = 'cd ..', vg_separador, '..', vg_separador,
 			      'REPUESTOS', vg_separador, 'fuentes', 
			      vg_separador, '; fglrun repp209 ', vg_base, ' ',
			      'RE', vg_codcia, ' ', vg_codloc,
			      ' PREV ', rm_j10.j10_num_fuente 
	WHEN 'PV'	-- fglrun vehp201 vg_base VE vg_codcia vg_codloc numprev
		LET comando = 'cd ..', vg_separador, '..', vg_separador,
 			      'VEHICULOS', vg_separador, 'fuentes', 
			      vg_separador, '; fglrun vehp201 ', vg_base, ' ',
			      'VE', vg_codcia, ' ', vg_codloc,
			      ' ', rm_j10.j10_num_fuente 
	WHEN 'OT'	-- fglrun talp204 vg_base TA vg_codcia vg_codloc orden
		LET comando = 'cd ..', vg_separador, '..', vg_separador,
 			      'TALLER', vg_separador, 'fuentes', 
			      vg_separador, '; fglrun talp204 ', vg_base, ' ',
			      'TA', vg_codcia, ' ', vg_codloc,
			      ' ', rm_j10.j10_num_fuente, ' O'
END CASE

RUN comando

END FUNCTION



FUNCTION proceso_master_transacciones_caja()

DEFINE done 		SMALLINT
DEFINE comando		CHAR(250)

DEFINE r_r00		RECORD LIKE rept000.*
DEFINE r_z24		RECORD LIKE cxct024.*

-- 1: Se genera la factura
CASE rm_j10.j10_tipo_fuente
	WHEN 'PR' 	-- fglrun repp211 vg_base vg_codcia num_prev
		CALL fl_lee_compania_repuestos(vg_codcia) RETURNING r_r00.*
		LET comando = 'cd ..', vg_separador, '..', vg_separador,
	      		      'REPUESTOS', vg_separador, 'fuentes', 
			      vg_separador, '; fglrun repp211 ', vg_base, ' ',
			      vg_codcia, ' ', vg_codloc, ' ', 
			       rm_j10.j10_num_fuente, ' ', r_r00.r00_fact_sstock 

	WHEN 'PV' 	-- fglrun vehp203 vg_base vg_codcia num_prev
		LET comando = 'cd ..', vg_separador, '..', vg_separador,
	      		      'VEHICULOS', vg_separador, 'fuentes', 
			      vg_separador, '; fglrun vehp203 ', vg_base, ' ',
			      vg_codcia, ' ', vg_codloc, ' ', 
			       rm_j10.j10_num_fuente 

	WHEN 'OT' 	-- fglrun talp210 vg_base vg_codcia orden   
		LET comando = 'cd ..', vg_separador, '..', vg_separador,
	      		      'TALLER', vg_separador, 'fuentes', 
			      vg_separador, '; fglrun talp210 ', vg_base, ' ',
			      vg_codcia, ' ', vg_codloc, ' ', 
			       rm_j10.j10_num_fuente 
END CASE

RUN comando

-- 2: si la factura se genero se habra grabado el tipo_destino
CALL fl_lee_cabecera_caja(vg_codcia, vg_codloc, rm_j10.j10_tipo_fuente,
						  rm_j10.j10_num_fuente) 
 	RETURNING rm_j10.* 	 

IF rm_j10.j10_tipo_destino IS NOT NULL THEN
	CALL imprime_comprobante()
	CALL fgl_winmessage(vg_producto, 'Proceso terminado OK.', 'exclamation')
END IF

END FUNCTION



FUNCTION execute_query()

SELECT ROWID INTO vm_rowid
	FROM cajt010
	WHERE j10_compania    = vg_codcia
	  AND j10_localidad   = vg_codloc
	  AND j10_tipo_fuente = vm_tipo_fuente
	  AND j10_num_fuente  = vm_num_fuente

IF STATUS = NOTFOUND THEN
	CALL fgl_winmessage(vg_producto, 
		'No existe forma de pago.', 
		'exclamation')
	EXIT PROGRAM	
ELSE
	CALL lee_muestra_registro(vm_rowid)
END IF

END FUNCTION



FUNCTION lee_muestra_registro(row)
DEFINE row 		INTEGER

SELECT * INTO rm_j10.* FROM cajt010 WHERE ROWID = row
IF STATUS = NOTFOUND THEN
	ERROR 'No existe registro con rowid', row
END IF

DISPLAY BY NAME rm_j10.j10_tipo_fuente, 
		rm_j10.j10_num_fuente,
		rm_j10.j10_areaneg,
		rm_j10.j10_codcli,
		rm_j10.j10_nomcli,
		rm_j10.j10_moneda,
		rm_j10.j10_tipo_destino,
		rm_j10.j10_num_destino,
		rm_j10.j10_valor,
		rm_j10.j10_fecha_pro,
		rm_j10.j10_usuario
	      	
CALL muestra_registro()

END FUNCTION



FUNCTION imprime_comprobante()

DEFINE comando			VARCHAR(250)

DEFINE r_r23		RECORD LIKE rept023.* 	-- Preventa Repuestos
DEFINE r_v26		RECORD LIKE veht026.* 	-- Preventa Vehiculos
DEFINE r_t23		RECORD LIKE talt023.*	-- Orden de Trabajo
DEFINE r_z24		RECORD LIKE cxct024.*	-- Solicitud Cobro Clientes

INITIALIZE comando TO NULL
CASE rm_j10.j10_tipo_fuente 
	WHEN 'PR'
		CALL fl_lee_preventa_rep(vg_codcia, vg_codloc,
			rm_j10.j10_num_fuente) RETURNING r_r23.*

		LET comando = 'cd ..', vg_separador, '..', vg_separador,
			      'REPUESTOS', vg_separador, 'fuentes', 
			      vg_separador, '; fglrun repp410_', vg_codloc USING '&', 
				  ' ', vg_base, ' ',
			      'RE', vg_codcia, ' ', vg_codloc,
			      ' ', r_r23.r23_num_tran 
	WHEN 'OT'
		CALL fl_lee_orden_trabajo(vg_codcia, vg_codloc,
			rm_j10.j10_num_fuente) RETURNING r_t23.*

		LET comando = 'cd ..', vg_separador, '..', vg_separador,
 			      'TALLER', vg_separador, 'fuentes', 
			      vg_separador, '; fglrun talp403 ', vg_base, ' ',
			      'TA', vg_codcia, ' ', vg_codloc,
			      ' ', r_t23.t23_num_factura
END CASE

IF comando IS NOT NULL THEN
	RUN comando
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
