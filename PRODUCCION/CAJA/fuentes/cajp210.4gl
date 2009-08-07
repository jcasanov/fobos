{*
 * Titulo           : cajp210.4gl - Facturacion sin stock (solo repuestos) 
 * Elaboracion      : 25-jun-2009
 * Autor            : JCM
 * Formato Ejecucion: fglrun cajp210 base modulo compania localidad 
 *	                  [tipo_fuente num_fuente]
 *}
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_rowid		INTEGER
--
-- DEFINE RECORD(S) HERE
--
DEFINE rm_j10		RECORD LIKE cajt010.*



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/cajp210.error')
CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 THEN -- Validar # parámetros correcto
	CALL fgl_winmessage(vg_producto, 'Número de parámetros incorrecto', 
                            'stop')
	EXIT PROGRAM
END IF
LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_codcia   = arg_val(3)
LET vg_proceso = 'cajp210'

CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	-- Asigna un valor por default a vg_codloc
				-- que luego puede ser reemplazado si se 
                                -- mantiene sin comentario la siguiente linea
LET vg_codloc   = arg_val(4)

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
OPEN WINDOW w_210 AT 3,2 WITH 14 ROWS, 80 COLUMNS
	ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, BORDER, MENU LINE 0, 
		  MESSAGE LINE LAST - 2) 
OPEN FORM f_210 FROM '../forms/cajf210_1'
DISPLAY FORM f_210

MENU 'OPCIONES'
	COMMAND KEY('C') 'Consultar'		'Consultar un registro para facturar' 
		CALL lee_datos_cabecera()
		LET int_flag = 0
	COMMAND KEY('F') 'Facturar'			'Facturar el registro actual'
		CALL proceso_master_transacciones_caja()
	COMMAND KEY('S') 'Salir'			'Salir al menu principal'
		EXIT MENU
END MENU

CLOSE WINDOW w_210

END FUNCTION



FUNCTION lee_datos_cabecera()

DEFINE resp 		CHAR(6)

DEFINE tipo_fuente	LIKE cajt010.j10_tipo_fuente

DEFINE r_r23		RECORD LIKE rept023.* 	-- Preventa Repuestos
DEFINE r_j10		RECORD LIKE cajt010.*

INITIALIZE rm_j10.* TO NULL
LET rm_j10.j10_tipo_fuente = 'PR'
DISPLAY BY NAME rm_j10.j10_tipo_fuente
LET INT_FLAG = 0
INPUT BY NAME rm_j10.j10_num_fuente WITHOUT DEFAULTS
	ON KEY (INTERRUPT)
		IF NOT FIELD_TOUCHED(j10_num_fuente) THEN
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
		IF INFIELD(j10_num_fuente) THEN
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
END CASE

RUN comando

END FUNCTION



FUNCTION proceso_master_transacciones_caja()

DEFINE done 		SMALLINT
DEFINE comando		CHAR(250)

DEFINE r_z24		RECORD LIKE cxct024.*

-- 1: Se genera la factura
CASE rm_j10.j10_tipo_fuente
	WHEN 'PR' 	-- fglrun repp211 vg_base vg_codcia num_prev
		LET comando = 'cd ..', vg_separador, '..', vg_separador,
	      		      'REPUESTOS', vg_separador, 'fuentes', 
			      vg_separador, '; fglrun repp211 ', vg_base, ' ',
			      vg_codcia, ' ', vg_codloc, ' ', 
			       rm_j10.j10_num_fuente, ' S ' 
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
