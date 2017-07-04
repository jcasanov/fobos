------------------------------------------------------------------------------
-- Titulo           : ctbp100.4gl - Configuración Compañías para Contabilidad
-- Elaboracion      : 17-sep-2001
-- Autor            : NPC
-- Formato Ejecucion: fglrun ctbp100 base módulo compañía
-- Ultima Correccion: 
-- Motivo Correccion: 
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_demonios	VARCHAR(12)
DEFINE rm_ctb		RECORD LIKE ctbt000.*
DEFINE vm_num_rows	SMALLINT
DEFINE vm_row_current	SMALLINT
DEFINE vm_max_rows	SMALLINT
DEFINE vm_r_rows	ARRAY [50] OF INTEGER

MAIN

DEFER QUIT 
DEFER INTERRUPT
CLEAR SCREEN
--CALL startlog('../logs/errores')
CALL startlog('../logs/ctbp100.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 3 THEN          -- Validar # parámetros correcto
	CALL fgl_winmessage(vg_producto, 'Número de parámetros incorrecto', 'stop')
	EXIT PROGRAM
END IF
LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_codcia   = arg_val(3)
LET vg_proceso = 'ctbp100'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
--#CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL control_master()

END MAIN



FUNCTION control_master()

CALL fl_nivel_isolation()
LET vm_max_rows	= 50
OPEN WINDOW wf AT 3,2 WITH 21 ROWS, 80 COLUMNS
    ATTRIBUTE(FORM LINE FIRST + 2, COMMENT LINE LAST, MENU LINE FIRST,BORDER,
	      MESSAGE LINE LAST - 2)
OPTIONS INPUT WRAP,
	ACCEPT KEY	F12
OPEN FORM f_ctb FROM "../forms/ctbf100_1"
DISPLAY FORM f_ctb
INITIALIZE rm_ctb.* TO NULL
LET vm_num_rows = 0
LET vm_row_current = 0
CALL muestra_contadores(vm_row_current, vm_num_rows)
MENU 'OPCIONES'
	BEFORE MENU
		HIDE OPTION 'Avanzar'
		HIDE OPTION 'Retroceder'
		HIDE OPTION 'Modificar'
		HIDE OPTION 'Bloquear/Activar'
	COMMAND KEY('I') 'Ingresar' 'Ingresar nuevos registros. '
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
       	COMMAND KEY('M') 'Modificar' 'Modificar registro corriente. '
		CALL control_modificacion()
	COMMAND KEY('C') 'Consultar' 'Consultar un registro. '
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
     	COMMAND KEY('B') 'Bloquear/Activar' 'Bloquear o activar registro. '
		CALL bloquear_activar()
	COMMAND KEY('S') 'Salir' 'Salir del programa. '
		EXIT MENU
END MENU

END FUNCTION



FUNCTION control_ingreso()
DEFINE r_mon            RECORD LIKE gent013.*

CALL fl_retorna_usuario()
INITIALIZE rm_ctb.*, r_mon.* TO NULL
CLEAR tit_mon_bas, tit_mon_alt, tit_cta_pre, tit_cta_ant, tit_cta_dfi,
	tit_cta_dfe, tit_cia_des
LET rm_ctb.b00_moneda_base = rg_gen.g00_moneda_base
CALL fl_lee_moneda(rm_ctb.b00_moneda_base) RETURNING r_mon.*
IF r_mon.g13_moneda IS NULL THEN
        CALL fgl_winmessage(vg_producto,'No existe ninguna moneda base','stop')
        EXIT PROGRAM
ELSE
        DISPLAY r_mon.g13_nombre TO tit_mon_bas
END IF
LET rm_ctb.b00_periodo_ini = CURRENT
LET rm_ctb.b00_periodo_ini = CURRENT
LET rm_ctb.b00_inte_online = 'S'
LET rm_ctb.b00_mayo_online = 'S'
LET rm_ctb.b00_modi_compma = 'N'
LET rm_ctb.b00_modi_compau = 'N'
LET rm_ctb.b00_estado      = 'A'
CALL muestra_estado()
CALL leer_datos('I')
IF NOT int_flag THEN
	INSERT INTO ctbt000 VALUES (rm_ctb.*)
	LET vm_num_rows = vm_num_rows + 1
	LET vm_row_current = vm_num_rows
	LET vm_r_rows[vm_row_current] = SQLCA.SQLERRD[6] 
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
	
IF vm_num_rows = 0 THEN
	CALL fl_mensaje_consultar_primero()
	RETURN
END IF
IF rm_ctb.b00_estado = 'B' THEN
	CALL fl_mensaje_estado_bloqueado()
	RETURN
END IF
CALL mostrar_registro(vm_r_rows[vm_row_current])
BEGIN WORK
WHENEVER ERROR CONTINUE
DECLARE q_up CURSOR FOR SELECT * FROM ctbt000
	WHERE ROWID = vm_r_rows[vm_row_current]
	FOR UPDATE
OPEN q_up
FETCH q_up INTO rm_ctb.*
IF STATUS < 0 THEN
	COMMIT WORK
	CALL fl_mensaje_bloqueo_otro_usuario()
	WHENEVER ERROR STOP
	RETURN
END IF
WHENEVER ERROR STOP
CALL leer_datos('M')
IF NOT int_flag THEN
	UPDATE ctbt000 SET b00_moneda_base = rm_ctb.b00_moneda_base,
			   b00_moneda_aux = rm_ctb.b00_moneda_aux,
			   b00_periodo_ini = rm_ctb.b00_periodo_ini,
			   b00_periodo_fin = rm_ctb.b00_periodo_fin,
			   b00_inte_online = rm_ctb.b00_inte_online,
			   b00_mayo_online = rm_ctb.b00_mayo_online,
			   b00_modi_compma = rm_ctb.b00_modi_compma,
			   b00_modi_compau = rm_ctb.b00_modi_compau,
			   b00_cuenta_uti = rm_ctb.b00_cuenta_uti,
			   b00_cta_uti_ant = rm_ctb.b00_cta_uti_ant,
			   b00_cuenta_difi = rm_ctb.b00_cuenta_difi,
			   b00_cuenta_dife = rm_ctb.b00_cuenta_dife
			WHERE CURRENT OF q_up
	COMMIT WORK
	CALL fl_mensaje_registro_modificado()
ELSE
	COMMIT WORK
	CLEAR FORM
	IF vm_row_current > 0 THEN
		CALL mostrar_registro(vm_r_rows[vm_row_current])
	END IF
END IF
WHENEVER ERROR STOP
 
END FUNCTION



FUNCTION control_consulta()
DEFINE cod_aux		LIKE ctbt000.b00_compania
DEFINE nom_aux		LIKE gent001.g01_razonsocial
DEFINE mone_aux		LIKE gent013.g13_moneda
DEFINE nomm_aux		LIKE gent013.g13_nombre
DEFINE deci_aux		LIKE gent013.g13_decimales
DEFINE query		VARCHAR(400)
DEFINE expr_sql		VARCHAR(400)
DEFINE num_reg		INTEGER

CLEAR FORM
INITIALIZE cod_aux, mone_aux TO NULL
LET int_flag = 0
CONSTRUCT BY NAME expr_sql ON b00_compania, b00_moneda_base, b00_moneda_aux,
	b00_periodo_ini, b00_periodo_fin, b00_inte_online, b00_mayo_online,
   	b00_modi_compma, b00_modi_compau, b00_cuenta_uti, b00_cta_uti_ant,
   	b00_cuenta_difi, b00_cuenta_dife
	ON KEY(F2)
	IF INFIELD(b00_compania) THEN
		CALL fl_ayuda_companias_contabilidad()
			RETURNING cod_aux, nom_aux
		LET int_flag = 0
		IF cod_aux IS NOT NULL THEN
			DISPLAY cod_aux TO b00_compania 
			DISPLAY nom_aux TO tit_cia_des
		END IF 
	END IF
	IF INFIELD(b00_moneda_base) THEN
		CALL fl_ayuda_monedas()
			RETURNING mone_aux, nomm_aux, deci_aux
		LET int_flag = 0
		IF mone_aux IS NOT NULL THEN
			DISPLAY mone_aux TO b00_moneda_base 
			DISPLAY nomm_aux TO tit_mon_bas
		END IF 
	END IF
	IF INFIELD(b00_moneda_aux) THEN
		CALL fl_ayuda_monedas()
			RETURNING mone_aux, nomm_aux, deci_aux
		LET int_flag = 0
		IF mone_aux IS NOT NULL THEN
			DISPLAY mone_aux TO b00_moneda_aux 
			DISPLAY nomm_aux TO tit_mon_alt
		END IF 
	END IF
	IF INFIELD(b00_cuenta_uti) THEN
		CALL fl_ayuda_cuenta_contable(vg_codcia,6)
			RETURNING cod_aux, nom_aux
		LET int_flag = 0
		IF cod_aux IS NOT NULL THEN
			DISPLAY cod_aux TO b00_cuenta_uti 
			DISPLAY nom_aux TO tit_cta_pre
		END IF 
	END IF
	IF INFIELD(b00_cta_uti_ant) THEN
		CALL fl_ayuda_cuenta_contable(vg_codcia,6)
			RETURNING cod_aux, nom_aux
		LET int_flag = 0
		IF cod_aux IS NOT NULL THEN
			DISPLAY cod_aux TO b00_cta_uti_ant 
			DISPLAY nom_aux TO tit_cta_ant
		END IF 
	END IF
	IF INFIELD(b00_cuenta_difi) THEN
		CALL fl_ayuda_cuenta_contable(vg_codcia,6)
			RETURNING cod_aux, nom_aux
		LET int_flag = 0
		IF cod_aux IS NOT NULL THEN
			DISPLAY cod_aux TO b00_cuenta_difi
			DISPLAY nom_aux TO tit_cta_dfi
		END IF 
	END IF
	IF INFIELD(b00_cuenta_dife) THEN
		CALL fl_ayuda_cuenta_contable(vg_codcia,6)
			RETURNING cod_aux, nom_aux
		LET int_flag = 0
		IF cod_aux IS NOT NULL THEN
			DISPLAY cod_aux TO b00_cuenta_dife 
			DISPLAY nom_aux TO tit_cta_dfe
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
LET query = 'SELECT *, ROWID FROM ctbt000 WHERE ' || expr_sql || ' ORDER BY 1'
PREPARE cons FROM query	
DECLARE q_cons CURSOR FOR cons
LET vm_num_rows = 0
FOREACH q_cons INTO rm_ctb.*, num_reg
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



FUNCTION leer_datos (flag_mant)
DEFINE cod_cia_aux	LIKE gent001.g01_compania
DEFINE flag_mant	CHAR(1)
DEFINE resp		CHAR(6)
DEFINE r_cta		RECORD LIKE ctbt010.*
DEFINE r_mon		RECORD LIKE gent013.*
DEFINE r_ctb_aux	RECORD LIKE ctbt000.*
DEFINE cod_aux		LIKE ctbt010.b10_cuenta
DEFINE nom_aux		LIKE ctbt010.b10_descripcion
DEFINE mone_aux		LIKE gent013.g13_moneda
DEFINE nomm_aux		LIKE gent013.g13_nombre
DEFINE deci_aux		LIKE gent013.g13_decimales
DEFINE r_ori		RECORD LIKE ctbt000.*

LET r_ori.* = rm_ctb.*
INITIALIZE r_ctb_aux.*, r_cta.*, r_mon.*, cod_aux, mone_aux TO NULL
DISPLAY BY NAME rm_ctb.b00_moneda_base, rm_ctb.b00_periodo_ini
LET int_flag = 0
INPUT BY NAME rm_ctb.b00_compania, rm_ctb.b00_moneda_base,
	rm_ctb.b00_moneda_aux, rm_ctb.b00_periodo_ini, rm_ctb.b00_periodo_fin,
	rm_ctb.b00_inte_online, rm_ctb.b00_mayo_online, rm_ctb.b00_modi_compma,
	rm_ctb.b00_modi_compau, rm_ctb.b00_anopro, 
	rm_ctb.b00_fecha_cd, rm_ctb.b00_fecha_cm, rm_ctb.b00_fecha_ca,
        rm_ctb.b00_cuenta_uti, rm_ctb.b00_cta_uti_ant,
	rm_ctb.b00_cuenta_difi, rm_ctb.b00_cuenta_dife
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
	        IF field_touched(rm_ctb.b00_compania, rm_ctb.b00_moneda_base,
 			rm_ctb.b00_moneda_aux, rm_ctb.b00_periodo_ini,
			rm_ctb.b00_periodo_fin, rm_ctb.b00_inte_online,
			rm_ctb.b00_mayo_online, rm_ctb.b00_modi_compma,
			rm_ctb.b00_modi_compau, rm_ctb.b00_cuenta_uti,
			rm_ctb.b00_cta_uti_ant, rm_ctb.b00_cuenta_difi,
			rm_ctb.b00_cuenta_dife)
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
			RETURN
		END IF
	ON KEY(F2)
		IF INFIELD(b00_compania) THEN
			CALL fl_ayuda_compania() RETURNING cod_cia_aux
			LET int_flag = 0
			IF cod_cia_aux IS NOT NULL THEN
				CALL fl_lee_compania(cod_cia_aux)
					RETURNING rg_cia.*
				LET rm_ctb.b00_compania = cod_cia_aux
				DISPLAY BY NAME rm_ctb.b00_compania 
				DISPLAY rg_cia.g01_razonsocial TO tit_cia_des
			END IF 
		END IF
		IF INFIELD(b00_moneda_base) THEN
			CALL fl_ayuda_monedas()
				RETURNING mone_aux, nomm_aux, deci_aux
			LET int_flag = 0
			IF mone_aux IS NOT NULL THEN
				LET rm_ctb.b00_moneda_base = mone_aux
				DISPLAY BY NAME rm_ctb.b00_moneda_base 
				DISPLAY nomm_aux TO tit_mon_bas
			END IF 
		END IF
		IF INFIELD(b00_moneda_aux) THEN
			CALL fl_ayuda_monedas()
				RETURNING mone_aux, nomm_aux, deci_aux
			LET int_flag = 0
			IF mone_aux IS NOT NULL THEN
				LET rm_ctb.b00_moneda_aux = mone_aux
				DISPLAY BY NAME rm_ctb.b00_moneda_aux 
				DISPLAY nomm_aux TO tit_mon_alt
			END IF 
		END IF
		IF INFIELD(b00_cuenta_uti) THEN
			CALL fl_ayuda_cuenta_contable(vg_codcia,6)
				RETURNING cod_aux, nom_aux
			LET int_flag = 0
			IF cod_aux IS NOT NULL THEN
				LET rm_ctb.b00_cuenta_uti = cod_aux
				DISPLAY BY NAME rm_ctb.b00_cuenta_uti 
				DISPLAY nom_aux TO tit_cta_pre
			END IF 
		END IF
		IF INFIELD(b00_cta_uti_ant) THEN
			CALL fl_ayuda_cuenta_contable(vg_codcia,6)
				RETURNING cod_aux, nom_aux
			LET int_flag = 0
			IF cod_aux IS NOT NULL THEN
				LET rm_ctb.b00_cta_uti_ant = cod_aux
				DISPLAY BY NAME rm_ctb.b00_cta_uti_ant 
				DISPLAY nom_aux TO tit_cta_ant
			END IF 
		END IF
		IF INFIELD(b00_cuenta_difi) THEN
			CALL fl_ayuda_cuenta_contable(vg_codcia,6)
				RETURNING cod_aux, nom_aux
			LET int_flag = 0
			IF cod_aux IS NOT NULL THEN
				LET rm_ctb.b00_cuenta_difi = cod_aux
				DISPLAY BY NAME rm_ctb.b00_cuenta_difi 
				DISPLAY nom_aux TO tit_cta_dfi
			END IF 
		END IF
		IF INFIELD(b00_cuenta_dife) THEN
			CALL fl_ayuda_cuenta_contable(vg_codcia,6)
				RETURNING cod_aux, nom_aux
			LET int_flag = 0
			IF cod_aux IS NOT NULL THEN
				LET rm_ctb.b00_cuenta_dife = cod_aux
				DISPLAY BY NAME rm_ctb.b00_cuenta_dife 
				DISPLAY nom_aux TO tit_cta_dfe
			END IF 
		END IF
	BEFORE FIELD b00_compania
		IF flag_mant = 'M' THEN
			NEXT FIELD NEXT
		END IF
	BEFORE FIELD b00_moneda_base
		IF rm_ctb.b00_compania IS NULL THEN
			CALL fgl_winmessage(vg_producto,'Ingrese la compañía primero.','info')
			NEXT FIELD b00_compania
		END IF
	BEFORE FIELD b00_periodo_fin
		IF rm_ctb.b00_periodo_ini IS NULL THEN
			CALL fgl_winmessage(vg_producto,'Ingrese el período inicial primero.','info')
			NEXT FIELD b00_periodo_ini
		END IF
	AFTER FIELD b00_compania
		IF rm_ctb.b00_compania IS NOT NULL THEN
			CALL fl_lee_compania(rm_ctb.b00_compania)
		 		RETURNING rg_cia.*
			IF rg_cia.g01_compania IS NULL THEN
				CALL fgl_winmessage(vg_producto,'Compañía no existe.','exclamation')
				NEXT FIELD b00_compania
			END IF
			DISPLAY rg_cia.g01_razonsocial TO tit_cia_des
			IF rg_cia.g01_estado = 'B' THEN
                                CALL fl_mensaje_estado_bloqueado()
                                NEXT FIELD b00_compania
                        END IF		 
			CALL fl_lee_compania_contabilidad(rm_ctb.b00_compania)
                        	RETURNING r_ctb_aux.*
			IF rm_ctb.b00_compania = r_ctb_aux.b00_compania THEN
				CALL fgl_winmessage(vg_producto,'Compañía ya ha sido asignada a contabilidad.','exclamation')
				NEXT FIELD b00_compania
			END IF
		ELSE
			CLEAR tit_cia_des
		END IF
	AFTER FIELD b00_moneda_base 
		IF rm_ctb.b00_moneda_base IS NOT NULL THEN
			CALL fl_lee_moneda(rm_ctb.b00_moneda_base)
				RETURNING r_mon.* 
			IF r_mon.g13_moneda IS NULL  THEN
				CALL fgl_winmessage(vg_producto,'Moneda no existe.','exclamation')
				NEXT FIELD b00_moneda_base
			END IF
			DISPLAY r_mon.g13_nombre TO tit_mon_bas
			IF r_mon.g13_estado = 'B' THEN
                                CALL fl_mensaje_estado_bloqueado()
				NEXT FIELD b00_moneda_base
			END IF
		ELSE
			LET rm_ctb.b00_moneda_base = rg_gen.g00_moneda_base
			DISPLAY BY NAME rm_ctb.b00_moneda_base
			CALL fl_lee_moneda(rm_ctb.b00_moneda_base)
				RETURNING r_mon.* 
			DISPLAY r_mon.g13_nombre TO tit_mon_bas
		END IF
	AFTER FIELD b00_moneda_aux 
		IF rm_ctb.b00_moneda_aux IS NOT NULL THEN
			CALL fl_lee_moneda(rm_ctb.b00_moneda_aux)
				RETURNING r_mon.* 
			IF r_mon.g13_moneda IS NULL  THEN
				CALL fgl_winmessage(vg_producto,'Moneda no existe.','exclamation')
				NEXT FIELD b00_moneda_aux
			END IF
			DISPLAY r_mon.g13_nombre TO tit_mon_alt
			IF r_mon.g13_estado = 'B' THEN
                                CALL fl_mensaje_estado_bloqueado()
				NEXT FIELD b00_moneda_aux
			END IF
		ELSE
			CLEAR tit_mon_alt
		END IF
	AFTER FIELD b00_periodo_fin
		IF rm_ctb.b00_periodo_fin IS NOT NULL THEN
			IF rm_ctb.b00_periodo_fin <= rm_ctb.b00_periodo_ini THEN
				CALL fgl_winmessage(vg_producto,'El período final debe ser mayor al período inicial.','exclamation')
				NEXT FIELD b00_periodo_fin
			END IF
		ELSE
			CLEAR b00_periodo_fin
		END IF
	AFTER FIELD b00_anopro 
		IF flag_mant = 'M' THEN
			LET rm_ctb.b00_anopro = r_ori.b00_anopro
			DISPLAY BY NAME rm_ctb.b00_anopro
		ELSE
			LET rm_ctb.b00_fecha_ca=MDY(12,31,rm_ctb.b00_anopro -1)
			DISPLAY BY NAME rm_ctb.b00_fecha_ca
		END IF
	AFTER FIELD b00_fecha_cd
		IF flag_mant = 'M' THEN
			LET rm_ctb.b00_fecha_cd = r_ori.b00_fecha_cd
			DISPLAY BY NAME rm_ctb.b00_fecha_cd
		END IF
	AFTER FIELD b00_fecha_cm
		IF flag_mant = 'M' THEN
			LET rm_ctb.b00_fecha_cm = r_ori.b00_fecha_cm
			DISPLAY BY NAME rm_ctb.b00_fecha_cm
		END IF
	AFTER FIELD b00_fecha_ca
		IF flag_mant = 'M' THEN
			LET rm_ctb.b00_fecha_ca = r_ori.b00_fecha_ca
			DISPLAY BY NAME rm_ctb.b00_fecha_ca
		END IF
	AFTER FIELD b00_cuenta_uti 
		IF rm_ctb.b00_cuenta_uti IS NOT NULL THEN
			CALL fl_lee_cuenta(rm_ctb.b00_compania,
						rm_ctb.b00_cuenta_uti)
				RETURNING r_cta.*
			IF r_cta.b10_cuenta IS NULL  THEN
				CALL fgl_winmessage(vg_producto,'Cuenta no existe para esta compañía.','exclamation')
				NEXT FIELD b00_cuenta_uti
			END IF
			DISPLAY r_cta.b10_descripcion TO tit_cta_pre
			IF r_cta.b10_estado = 'B' THEN
                                CALL fl_mensaje_estado_bloqueado()
                                NEXT FIELD b00_cuenta_uti
                        END IF
			IF r_cta.b10_nivel <> 6 THEN
				CALL fgl_winmessage(vg_producto,'Nivel de cuenta debe ser solo 6.','info')
				NEXT FIELD b00_cuenta_uti
			END IF
		ELSE
			CLEAR tit_cta_pre
		END IF
	AFTER FIELD b00_cta_uti_ant 
		IF rm_ctb.b00_cta_uti_ant IS NOT NULL THEN
			CALL fl_lee_cuenta(rm_ctb.b00_compania,
						rm_ctb.b00_cta_uti_ant)
				RETURNING r_cta.*
			IF r_cta.b10_cuenta IS NULL  THEN
				CALL fgl_winmessage(vg_producto,'Cuenta no existe para esta compañía.','exclamation')
				NEXT FIELD b00_cta_uti_ant
			END IF
			DISPLAY r_cta.b10_descripcion TO tit_cta_ant
			IF r_cta.b10_estado = 'B' THEN
                                CALL fl_mensaje_estado_bloqueado()
                                NEXT FIELD b00_cta_uti_ant
                        END IF
			IF r_cta.b10_nivel <> 6 THEN
				CALL fgl_winmessage(vg_producto,'Nivel de cuenta debe ser solo 6.','info')
				NEXT FIELD b00_cta_uti_ant
			END IF
		ELSE
			CLEAR tit_cta_ant
		END IF
	AFTER FIELD b00_cuenta_difi 
		IF rm_ctb.b00_cuenta_difi IS NOT NULL THEN
			CALL fl_lee_cuenta(rm_ctb.b00_compania,
						rm_ctb.b00_cuenta_difi)
				RETURNING r_cta.*
			IF r_cta.b10_cuenta IS NULL  THEN
				CALL fgl_winmessage(vg_producto,'Cuenta no existe para esta compañía.','exclamation')
				NEXT FIELD b00_cuenta_difi
			END IF
			DISPLAY r_cta.b10_descripcion TO tit_cta_dfi
			IF r_cta.b10_estado = 'B' THEN
                                CALL fl_mensaje_estado_bloqueado()
                                NEXT FIELD b00_cuenta_difi
                        END IF
			IF r_cta.b10_nivel <> 6 THEN
				CALL fgl_winmessage(vg_producto,'Nivel de cuenta debe ser solo 6.','info')
				NEXT FIELD b00_cuenta_difi
			END IF
		ELSE
			CLEAR tit_cta_dfi
		END IF
	AFTER FIELD b00_cuenta_dife 
		IF rm_ctb.b00_cuenta_dife IS NOT NULL THEN
			CALL fl_lee_cuenta(rm_ctb.b00_compania,
						rm_ctb.b00_cuenta_dife)
				RETURNING r_cta.*
			IF r_cta.b10_cuenta IS NULL  THEN
				CALL fgl_winmessage(vg_producto,'Cuenta no existe para esta compañía.','exclamation')
				NEXT FIELD b00_cuenta_dife
			END IF
			DISPLAY r_cta.b10_descripcion TO tit_cta_dfe
			IF r_cta.b10_estado = 'B' THEN
                                CALL fl_mensaje_estado_bloqueado()
                                NEXT FIELD b00_cuenta_dife
                        END IF
			IF r_cta.b10_nivel <> 6 THEN
				CALL fgl_winmessage(vg_producto,'Nivel de cuenta debe ser solo 6.','info')
				NEXT FIELD b00_cuenta_dife
			END IF
		ELSE
			CLEAR tit_cta_dfe
		END IF
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
                                                                                
DISPLAY "" AT 1,1
DISPLAY row_current, " de ", num_rows AT 1, 69
                                                                                
END FUNCTION



FUNCTION mostrar_registro(num_registro)
DEFINE r_cta		RECORD LIKE ctbt010.*
DEFINE r_mon		RECORD LIKE gent013.*
DEFINE num_registro	INTEGER

IF vm_num_rows > 0 THEN
	SELECT * INTO rm_ctb.* FROM ctbt000 WHERE ROWID=num_registro	
	IF STATUS = NOTFOUND THEN
		CALL fgl_winmessage (vg_producto,'No existe registro con índice: ' || vm_row_current,'exclamation')
		RETURN
	END IF
	DISPLAY BY NAME rm_ctb.b00_compania, rm_ctb.b00_moneda_base,
		rm_ctb.b00_moneda_aux, rm_ctb.b00_periodo_ini,
		rm_ctb.b00_periodo_fin, rm_ctb.b00_inte_online,
		rm_ctb.b00_mayo_online, rm_ctb.b00_modi_compma,
		rm_ctb.b00_modi_compau, rm_ctb.b00_cuenta_uti,
		rm_ctb.b00_cta_uti_ant, rm_ctb.b00_cuenta_difi,
		rm_ctb.b00_cuenta_difi, rm_ctb.b00_anopro,
		rm_ctb.b00_fecha_cd, rm_ctb.b00_fecha_cm, rm_ctb.b00_fecha_ca
	CALL fl_lee_compania(rm_ctb.b00_compania) RETURNING rg_cia.*
	DISPLAY rg_cia.g01_razonsocial TO tit_cia_des
	CALL fl_lee_moneda(rm_ctb.b00_moneda_base) RETURNING r_mon.* 
	DISPLAY r_mon.g13_nombre TO tit_mon_bas
	CALL fl_lee_moneda(rm_ctb.b00_moneda_aux) RETURNING r_mon.* 
	DISPLAY r_mon.g13_nombre TO tit_mon_alt
	CALL fl_lee_cuenta(rm_ctb.b00_compania,rm_ctb.b00_cuenta_uti)
		RETURNING r_cta.*
	DISPLAY r_cta.b10_descripcion TO tit_cta_pre
	CALL fl_lee_cuenta(rm_ctb.b00_compania,rm_ctb.b00_cta_uti_ant)
 		RETURNING r_cta.*
	DISPLAY r_cta.b10_descripcion TO tit_cta_ant
	CALL fl_lee_cuenta(rm_ctb.b00_compania,rm_ctb.b00_cuenta_difi)
		RETURNING r_cta.*
	DISPLAY r_cta.b10_descripcion TO tit_cta_dfi
	CALL fl_lee_cuenta(rm_ctb.b00_compania,rm_ctb.b00_cuenta_dife)
		RETURNING r_cta.*
	DISPLAY r_cta.b10_descripcion TO tit_cta_dfe
	CALL muestra_estado()
ELSE
	RETURN
END IF

END FUNCTION



FUNCTION bloquear_activar()
DEFINE confir	CHAR(6)

IF vm_num_rows = 0 THEN
	CALL fl_mensaje_consultar_primero()
	RETURN
END IF
LET int_flag = 0
BEGIN WORK
WHENEVER ERROR CONTINUE
DECLARE q_ba CURSOR FOR SELECT * FROM ctbt000
	WHERE ROWID = vm_r_rows[vm_row_current]
	FOR UPDATE
OPEN q_ba
FETCH q_ba INTO rm_ctb.*
IF STATUS < 0 THEN
	COMMIT WORK
	CALL fl_mensaje_bloqueo_otro_usuario()
	WHENEVER ERROR STOP
	RETURN
END IF	
CALL fl_mensaje_seguro_ejecutar_proceso()
RETURNING confir
IF confir = 'Yes' THEN
	LET int_flag = 1
	CALL bloquea_activa_registro()
END IF
COMMIT WORK
WHENEVER ERROR STOP

END FUNCTION



FUNCTION bloquea_activa_registro()
DEFINE estado	CHAR(1)

IF rm_ctb.b00_estado = 'A' THEN
	DISPLAY 'BLOQUEADO' TO tit_estado_cia
	LET estado = 'B'
ELSE 
	DISPLAY 'ACTIVO' TO tit_estado_cia
	LET estado = 'A'
END IF
DISPLAY estado TO tit_est
UPDATE ctbt000 SET b00_estado = estado WHERE CURRENT OF q_ba
LET rm_ctb.b00_estado = estado

END FUNCTION



FUNCTION muestra_estado()
IF rm_ctb.b00_estado = 'A' THEN
	DISPLAY 'ACTIVO' TO tit_estado_cia
ELSE
	DISPLAY 'BLOQUEADO' TO tit_estado_cia
END IF
DISPLAY rm_ctb.b00_estado TO tit_est

END FUNCTION



FUNCTION no_validar_parametros()

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
