------------------------------------------------------------------------------
-- Titulo           : ctbp200.4gl - Bloqueo y Desbloqueo de Meses Contables
-- Elaboracion      : 13-nov-2001
-- Autor            : NPC
-- Formato Ejecucion: fglrun ctbp200 base módulo compañía localidad
-- Ultima Correccion: 
-- Motivo Correccion: 
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_demonios	VARCHAR(12)
DEFINE rm_ctb		RECORD LIKE ctbt006.*
DEFINE rm_mes		ARRAY[12] OF LIKE ctbt006.b06_mes
DEFINE tit_enero	CHAR(1)
DEFINE tit_febrero	CHAR(1)
DEFINE tit_marzo	CHAR(1)
DEFINE tit_abril	CHAR(1)
DEFINE tit_mayo		CHAR(1)
DEFINE tit_junio	CHAR(1)
DEFINE tit_julio	CHAR(1)
DEFINE tit_agosto	CHAR(1)
DEFINE tit_septiembre	CHAR(1)
DEFINE tit_octubre	CHAR(1)
DEFINE tit_noviembre	CHAR(1)
DEFINE tit_diciembre	CHAR(1)

MAIN

DEFER QUIT 
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/errores')
CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 THEN          -- Validar # parámetros correcto
	CALL fgl_winmessage(vg_producto, 'Número de parámetros incorrecto', 'stop')
	EXIT PROGRAM
END IF
LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_codcia   = arg_val(3)
LET vg_codloc   = arg_val(4)
LET vg_proceso = 'ctbp200'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()

END MAIN



FUNCTION funcion_master()

CALL fl_nivel_isolation()
OPEN WINDOW w_mas AT 3,2 WITH 18 ROWS, 80 COLUMNS
    ATTRIBUTE(FORM LINE FIRST + 2, COMMENT LINE LAST, MENU LINE FIRST,BORDER,
	      MESSAGE LINE LAST - 2)
OPTIONS INPUT WRAP,
	ACCEPT KEY	F12
OPEN FORM f_ctb FROM "../forms/ctbf200_1"
DISPLAY FORM f_ctb
INITIALIZE rm_ctb.* TO NULL
CALL control_ingreso()

END FUNCTION



FUNCTION control_ingreso()
DEFINE i		SMALLINT

CALL fl_retorna_usuario()
WHILE TRUE
	INITIALIZE rm_ctb.* TO NULL
	FOR i = 1 TO 12
		LET rm_mes[i] = 0
	END FOR
	CLEAR FORM
	LET rm_ctb.b06_compania = vg_codcia
	LET rm_ctb.b06_ano      = year(TODAY)
	LET tit_enero		= 'N'
	LET tit_febrero		= 'N'
	LET tit_marzo		= 'N'
	LET tit_abril		= 'N'
	LET tit_mayo		= 'N'
	LET tit_junio		= 'N'
	LET tit_julio		= 'N'
	LET tit_agosto		= 'N'
	LET tit_septiembre	= 'N'
	LET tit_octubre		= 'N'
	LET tit_noviembre	= 'N'
	LET tit_diciembre	= 'N'
	LET rm_ctb.b06_usuario  = vg_usuario
	LET rm_ctb.b06_fecing   = CURRENT
	CALL leer_anio()
	IF NOT int_flag THEN
		BEGIN WORK
		WHENEVER ERROR CONTINUE
		DECLARE q_up CURSOR FOR SELECT * FROM ctbt006
			WHERE b06_compania = vg_codcia
			  AND b06_ano      = rm_ctb.b06_ano
			FOR UPDATE
		FOREACH q_up INTO rm_ctb.*
			LET rm_mes[rm_ctb.b06_mes] = rm_ctb.b06_mes
		END FOREACH
		WHENEVER ERROR STOP
		CALL leer_mes()
		IF NOT int_flag THEN
			DELETE FROM ctbt006 WHERE b06_compania = vg_codcia
					      AND b06_ano      = rm_ctb.b06_ano
			LET rm_ctb.b06_fecing   = CURRENT
			FOR i = 1 TO 12
				IF rm_mes[i] <> 0 THEN
					INSERT INTO ctbt006 VALUES(
						rm_ctb.b06_compania,
						rm_ctb.b06_ano,
						rm_mes[i],
						rm_ctb.b06_usuario,
						rm_ctb.b06_fecing)
				END IF
			END FOR
			COMMIT WORK
			CALL fl_mensaje_registro_ingresado()
		ELSE
			COMMIT WORK
	        END IF
	ELSE
		EXIT WHILE
	END IF
END WHILE
WHENEVER ERROR STOP

END FUNCTION



FUNCTION leer_anio()
DEFINE resp		CHAR(6)
DEFINE r_cia		RECORD LIKE ctbt000.*

OPTIONS INPUT NO WRAP
DISPLAY BY NAME rm_ctb.b06_usuario, rm_ctb.b06_fecing
LET int_flag = 0
INPUT BY NAME rm_ctb.b06_ano
	WITHOUT DEFAULTS
	{ON KEY(INTERRUPT)
        	IF field_touched(rm_ctb.b06_ano) THEN
               		LET int_flag = 0
			CALL fl_mensaje_abandonar_proceso()
        	        	RETURNING resp
              		IF resp = 'Yes' THEN
				LET int_flag = 1
				RETURN
                	END IF
		ELSE
			RETURN
		END IF}
	AFTER FIELD b06_ano
		IF rm_ctb.b06_ano IS NOT NULL THEN
			CALL llamar_registro()
			CALL fl_lee_compania_contabilidad(vg_codcia)
				RETURNING r_cia.*
			IF rm_ctb.b06_ano > year(TODAY) THEN
				CALL fgl_winmessage(vg_producto,'Año mayor al año de proceso.','exclamation')
				NEXT FIELD b06_ano
			END IF
			IF rm_ctb.b06_ano < r_cia.b00_anopro THEN
				CALL fgl_winmessage(vg_producto,'Año de proceso contable está incorrecto.','exclamation')
				NEXT FIELD b06_ano
			END IF
		ELSE
			LET rm_ctb.b06_ano = year(TODAY)
			DISPLAY BY NAME rm_ctb.b06_ano
		END IF
END INPUT

END FUNCTION



FUNCTION leer_mes()
DEFINE resp		CHAR(6)
DEFINE r_cia		RECORD LIKE ctbt000.*
DEFINE ano_cerr_men	SMALLINT
DEFINE mes_cerrado	SMALLINT

OPTIONS INPUT WRAP
CALL llamar_registro()
LET int_flag = 0
INPUT BY NAME tit_enero, tit_febrero, tit_marzo, tit_abril, tit_mayo, tit_junio,
	tit_julio, tit_agosto, tit_septiembre, tit_octubre, tit_noviembre,
	tit_diciembre
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
        	IF field_touched(tit_enero, tit_febrero, tit_marzo, tit_abril,
			tit_mayo, tit_junio, tit_julio, tit_agosto,
			tit_septiembre, tit_octubre, tit_noviembre,
			tit_diciembre)
		THEN
               		LET int_flag = 0
			CALL fl_mensaje_abandonar_proceso()
        	        	RETURNING resp
              		IF resp = 'Yes' THEN
				LET int_flag = 1
				RETURN
                	END IF
		ELSE
			RETURN
		END IF
	BEFORE INPUT
		CALL fl_lee_compania_contabilidad(vg_codcia) RETURNING r_cia.*
		LET mes_cerrado  = month(r_cia.b00_fecha_cm)
		LET ano_cerr_men = year(r_cia.b00_fecha_cm)
	AFTER FIELD tit_enero
		IF ano_cerr_men = rm_ctb.b06_ano AND mes_cerrado >= 1 THEN
			IF tit_enero = 'S' THEN
				CALL fgl_winmessage(vg_producto,'No puede bloquear mes que está cerrado.','exclamation')
				LET tit_enero = 'N'
				DISPLAY BY NAME tit_enero
			END IF
		END IF
		IF 1 > month(TODAY) AND rm_ctb.b06_ano = year(TODAY) THEN
			IF tit_enero = 'S' THEN
				CALL fgl_winmessage(vg_producto,'No puede bloquear mes mayor al corriente.','exclamation')
				LET tit_enero = 'N'
				DISPLAY BY NAME tit_enero
			END IF
		END IF
	AFTER FIELD tit_febrero
		IF ano_cerr_men = rm_ctb.b06_ano AND mes_cerrado >= 2 THEN
			IF tit_febrero = 'S' THEN
				CALL fgl_winmessage(vg_producto,'No puede bloquear mes que está cerrado.','exclamation')
				LET tit_febrero = 'N'
				DISPLAY BY NAME tit_febrero
			END IF
		END IF
		IF 2 > month(TODAY) AND rm_ctb.b06_ano = year(TODAY) THEN
			IF tit_febrero = 'S' THEN
				CALL fgl_winmessage(vg_producto,'No puede bloquear mes mayor al corriente.','exclamation')
				LET tit_febrero = 'N'
				DISPLAY BY NAME tit_febrero
			END IF
		END IF
	AFTER FIELD tit_marzo
		IF ano_cerr_men = rm_ctb.b06_ano AND mes_cerrado >= 3 THEN
			IF tit_marzo = 'S' THEN
				CALL fgl_winmessage(vg_producto,'No puede bloquear mes que está cerrado.','exclamation')
				LET tit_marzo = 'N'
				DISPLAY BY NAME tit_marzo
			END IF
		END IF
		IF 3 > month(TODAY) AND rm_ctb.b06_ano = year(TODAY) THEN
			IF tit_marzo = 'S' THEN
				CALL fgl_winmessage(vg_producto,'No puede bloquear mes mayor al corriente.','exclamation')
				LET tit_marzo = 'N'
				DISPLAY BY NAME tit_marzo
			END IF
		END IF
	AFTER FIELD tit_abril
		IF ano_cerr_men = rm_ctb.b06_ano AND mes_cerrado >= 4 THEN
			IF tit_abril = 'S' THEN
				CALL fgl_winmessage(vg_producto,'No puede bloquear mes que está cerrado.','exclamation')
				LET tit_abril = 'N'
				DISPLAY BY NAME tit_abril
			END IF
		END IF
		IF 4 > month(TODAY) AND rm_ctb.b06_ano = year(TODAY) THEN
			IF tit_abril = 'S' THEN
				CALL fgl_winmessage(vg_producto,'No puede bloquear mes mayor al corriente.','exclamation')
				LET tit_abril = 'N'
				DISPLAY BY NAME tit_abril
			END IF
		END IF
	AFTER FIELD tit_mayo
		IF ano_cerr_men = rm_ctb.b06_ano AND mes_cerrado >= 5 THEN
			IF tit_mayo = 'S' THEN
				CALL fgl_winmessage(vg_producto,'No puede bloquear mes que está cerrado.','exclamation')
				LET tit_mayo = 'N'
				DISPLAY BY NAME tit_mayo
			END IF
		END IF
		IF 5 > month(TODAY) AND rm_ctb.b06_ano = year(TODAY) THEN
			IF tit_mayo = 'S' THEN
				CALL fgl_winmessage(vg_producto,'No puede bloquear mes mayor al corriente.','exclamation')
				LET tit_mayo = 'N'
				DISPLAY BY NAME tit_mayo
			END IF
		END IF
	AFTER FIELD tit_junio
		IF ano_cerr_men = rm_ctb.b06_ano AND mes_cerrado >= 6 THEN
			IF tit_junio = 'S' THEN
				CALL fgl_winmessage(vg_producto,'No puede bloquear mes que está cerrado.','exclamation')
				LET tit_junio = 'N'
				DISPLAY BY NAME tit_junio
			END IF
		END IF
		IF 6 > month(TODAY) AND rm_ctb.b06_ano = year(TODAY) THEN
			IF tit_junio = 'S' THEN
				CALL fgl_winmessage(vg_producto,'No puede bloquear mes mayor al corriente.','exclamation')
				LET tit_junio = 'N'
				DISPLAY BY NAME tit_junio
			END IF
		END IF
	AFTER FIELD tit_julio
		IF ano_cerr_men = rm_ctb.b06_ano AND mes_cerrado >= 7 THEN
			IF tit_julio = 'S' THEN
				CALL fgl_winmessage(vg_producto,'No puede bloquear mes que está cerrado.','exclamation')
				LET tit_julio = 'N'
				DISPLAY BY NAME tit_julio
			END IF
		END IF
		IF 7 > month(TODAY) AND rm_ctb.b06_ano = year(TODAY) THEN
			IF tit_julio = 'S' THEN
				CALL fgl_winmessage(vg_producto,'No puede bloquear mes mayor al corriente.','exclamation')
				LET tit_julio = 'N'
				DISPLAY BY NAME tit_julio
			END IF
		END IF
	AFTER FIELD tit_agosto
		IF ano_cerr_men = rm_ctb.b06_ano AND mes_cerrado >= 8 THEN
			IF tit_agosto = 'S' THEN
				CALL fgl_winmessage(vg_producto,'No puede bloquear mes que está cerrado.','exclamation')
				LET tit_agosto = 'N'
				DISPLAY BY NAME tit_agosto
			END IF
		END IF
		IF 8 > month(TODAY) AND rm_ctb.b06_ano = year(TODAY) THEN
			IF tit_agosto = 'S' THEN
				CALL fgl_winmessage(vg_producto,'No puede bloquear mes mayor al corriente.','exclamation')
				LET tit_agosto = 'N'
				DISPLAY BY NAME tit_agosto
			END IF
		END IF
	AFTER FIELD tit_septiembre
		IF ano_cerr_men = rm_ctb.b06_ano AND mes_cerrado >= 9 THEN
			IF tit_septiembre = 'S' THEN
				CALL fgl_winmessage(vg_producto,'No puede bloquear mes que está cerrado.','exclamation')
				LET tit_septiembre = 'N'
				DISPLAY BY NAME tit_septiembre
			END IF
		END IF
		IF 9 > month(TODAY) AND rm_ctb.b06_ano = year(TODAY) THEN
			IF tit_septiembre = 'S' THEN
				CALL fgl_winmessage(vg_producto,'No puede bloquear mes mayor al corriente.','exclamation')
				LET tit_septiembre = 'N'
				DISPLAY BY NAME tit_septiembre
			END IF
		END IF
	AFTER FIELD tit_octubre
		IF ano_cerr_men = rm_ctb.b06_ano AND mes_cerrado >= 10 THEN
			IF tit_octubre = 'S' THEN
				CALL fgl_winmessage(vg_producto,'No puede bloquear mes que está cerrado.','exclamation')
				LET tit_octubre = 'N'
				DISPLAY BY NAME tit_octubre
			END IF
		END IF
		IF 10 > month(TODAY) AND rm_ctb.b06_ano = year(TODAY) THEN
			IF tit_octubre = 'S' THEN
				CALL fgl_winmessage(vg_producto,'No puede bloquear mes mayor al corriente.','exclamation')
				LET tit_octubre = 'N'
				DISPLAY BY NAME tit_octubre
			END IF
		END IF
	AFTER FIELD tit_noviembre
		IF ano_cerr_men = rm_ctb.b06_ano AND mes_cerrado >= 11 THEN
			IF tit_noviembre = 'S' THEN
				CALL fgl_winmessage(vg_producto,'No puede bloquear mes que está cerrado.','exclamation')
				LET tit_noviembre = 'N'
				DISPLAY BY NAME tit_noviembre
			END IF
		END IF
		IF 11 > month(TODAY) AND rm_ctb.b06_ano = year(TODAY) THEN
			IF tit_noviembre = 'S' THEN
				CALL fgl_winmessage(vg_producto,'No puede bloquear mes mayor al corriente.','exclamation')
				LET tit_noviembre = 'N'
				DISPLAY BY NAME tit_noviembre
			END IF
		END IF
	AFTER FIELD tit_diciembre
		IF ano_cerr_men = rm_ctb.b06_ano AND mes_cerrado >= 12 THEN
			IF tit_diciembre = 'S' THEN
				CALL fgl_winmessage(vg_producto,'No puede bloquear mes que está cerrado.','exclamation')
				LET tit_diciembre = 'N'
				DISPLAY BY NAME tit_diciembre
			END IF
		END IF
		IF 12 > month(TODAY) AND rm_ctb.b06_ano = year(TODAY) THEN
			IF tit_diciembre = 'S' THEN
				CALL fgl_winmessage(vg_producto,'No puede bloquear mes mayor al corriente.','exclamation')
				LET tit_diciembre = 'N'
				DISPLAY BY NAME tit_diciembre
			END IF
		END IF
	AFTER INPUT
		CALL chequear_mes()
END INPUT

END FUNCTION



FUNCTION chequear_mes()

IF tit_enero = 'S' THEN
	LET rm_mes[1] = 1
ELSE
	LET rm_mes[1] = 0
END IF
IF tit_febrero = 'S' THEN
	LET rm_mes[2] = 2
ELSE
	LET rm_mes[2] = 0
END IF
IF tit_marzo = 'S' THEN
	LET rm_mes[3] = 3
ELSE
	LET rm_mes[3] = 0
END IF
IF tit_abril = 'S' THEN
	LET rm_mes[4] = 4
ELSE
	LET rm_mes[4] = 0
END IF
IF tit_mayo = 'S' THEN
	LET rm_mes[5] = 5
ELSE
	LET rm_mes[5] = 0
END IF
IF tit_junio = 'S' THEN
	LET rm_mes[6] = 6
ELSE
	LET rm_mes[6] = 0
END IF
IF tit_julio = 'S' THEN
	LET rm_mes[7] = 7
ELSE
	LET rm_mes[7] = 0
END IF
IF tit_agosto = 'S' THEN
	LET rm_mes[8] = 8
ELSE
	LET rm_mes[8] = 0
END IF
IF tit_septiembre = 'S' THEN
	LET rm_mes[9] = 9
ELSE
	LET rm_mes[9] = 0
END IF
IF tit_octubre = 'S' THEN
	LET rm_mes[10] = 10
ELSE
	LET rm_mes[10] = 0
END IF
IF tit_noviembre = 'S' THEN
	LET rm_mes[11] = 11
ELSE
	LET rm_mes[11] = 0
END IF
IF tit_diciembre = 'S' THEN
	LET rm_mes[12] = 12
ELSE
	LET rm_mes[12] = 0
END IF

END FUNCTION



FUNCTION llamar_registro()
DEFINE num		SMALLINT

LET num = 0
SELECT COUNT(b06_ano) INTO num FROM ctbt006
	WHERE b06_compania = vg_codcia
	  AND b06_ano      = rm_ctb.b06_ano
IF num <> 0 THEN
	CALL mostrar_registro()
END IF

END FUNCTION



FUNCTION mostrar_registro()

DECLARE q_mos CURSOR FOR SELECT * FROM ctbt006
	WHERE b06_compania = vg_codcia
	  AND b06_ano      = rm_ctb.b06_ano
FOREACH q_mos INTO rm_ctb.*
	LET rm_mes[rm_ctb.b06_mes] = rm_ctb.b06_mes
END FOREACH
DISPLAY BY NAME rm_ctb.b06_ano, rm_ctb.b06_usuario, rm_ctb.b06_fecing
CALL muestra_meses()

END FUNCTION



FUNCTION muestra_meses()

IF rm_mes[1] = 1 THEN
	LET tit_enero = 'S'
ELSE
	LET tit_enero = 'N'
END IF
DISPLAY BY NAME tit_enero
IF rm_mes[2] = 2 THEN
	LET tit_febrero = 'S'
ELSE
	LET tit_febrero = 'N'
END IF
DISPLAY BY NAME tit_febrero
IF rm_mes[3] = 3 THEN
	LET tit_marzo = 'S'
ELSE
	LET tit_marzo = 'N'
END IF
DISPLAY BY NAME tit_marzo
IF rm_mes[4] = 4 THEN
	LET tit_abril = 'S'
ELSE
	LET tit_abril = 'N'
END IF
DISPLAY BY NAME tit_abril
IF rm_mes[5] = 5 THEN
	LET tit_mayo = 'S'
ELSE
	LET tit_mayo = 'N'
END IF
DISPLAY BY NAME tit_mayo
IF rm_mes[6] = 6 THEN
	LET tit_junio = 'S'
ELSE
	LET tit_junio = 'N'
END IF
DISPLAY BY NAME tit_junio
IF rm_mes[7] = 7 THEN
	LET tit_julio = 'S'
ELSE
	LET tit_julio = 'N'
END IF
DISPLAY BY NAME tit_julio
IF rm_mes[8] = 8 THEN
	LET tit_agosto = 'S'
ELSE
	LET tit_agosto = 'N'
END IF
DISPLAY BY NAME tit_agosto
IF rm_mes[9] = 9 THEN
	LET tit_septiembre = 'S'
ELSE
	LET tit_septiembre = 'N'
END IF
DISPLAY BY NAME tit_septiembre
IF rm_mes[10] = 10 THEN
	LET tit_octubre = 'S'
ELSE
	LET tit_octubre = 'N'
END IF
DISPLAY BY NAME tit_octubre
IF rm_mes[11] = 11 THEN
	LET tit_noviembre = 'S'
ELSE
	LET tit_noviembre = 'N'
END IF
DISPLAY BY NAME tit_noviembre
IF rm_mes[12] = 12 THEN
	LET tit_diciembre = 'S'
ELSE
	LET tit_diciembre = 'N'
END IF
DISPLAY BY NAME tit_diciembre

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
