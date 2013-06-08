------------------------------------------------------------------------------
-- Titulo           : rolp412.4gl - Planilla Fondo de Reserva (ARCHIVO)
-- Elaboracion      : 15-Oct-2003
-- Autor            : NPC
-- Formato Ejecucion: fglrun rolp412 base modulo compañía [fec_ini] [fec_fin]
-- Ultima Correccion: 
-- Motivo Correccion: 
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE rm_n00		RECORD LIKE rolt000.*
DEFINE rm_n06		RECORD LIKE rolt006.*
DEFINE rm_n38		RECORD LIKE rolt038.*
DEFINE rm_n66		RECORD LIKE rolt066.*
DEFINE rm_g01		RECORD LIKE gent001.*
DEFINE rm_g02		RECORD LIKE gent002.*



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/errores')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 3 AND num_args() <> 5 THEN  -- Validar # parámetros correcto
	CALL fl_mostrar_mensaje('Número de parámetros incorrecto.','stop')
	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_proceso = 'rolp412'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
--#CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()

END MAIN



FUNCTION funcion_master()
DEFINE lin_menu		SMALLINT
DEFINE row_ini  	SMALLINT
DEFINE num_rows 	SMALLINT
DEFINE num_cols 	SMALLINT
DEFINE resul	 	SMALLINT

CALL fl_nivel_isolation()
CALL fl_lee_compania(vg_codcia) RETURNING rm_g01.*
IF rm_g01.g01_compania IS NULL THEN
	CALL fl_mostrar_mensaje('No existe compañía.','stop')
	EXIT PROGRAM
END IF
CALL fl_lee_localidad(vg_codcia, vg_codloc) RETURNING rm_g02.*
IF rm_g02.g02_compania IS NULL THEN
	CALL fl_mostrar_mensaje('No existe localidad.','stop')
	EXIT PROGRAM
END IF
IF num_args() <> 3 THEN
	LET rm_n38.n38_fecha_ini = arg_val(4)
	LET rm_n38.n38_fecha_fin = arg_val(5)
	CALL control_reporte()
	EXIT PROGRAM
END IF
LET lin_menu = 0
LET row_ini  = 3
LET num_rows = 6
LET num_cols = 80
IF vg_gui = 0 THEN
	LET lin_menu = 1
	LET row_ini  = 4
	LET num_rows = 20
	LET num_cols = 78
END IF
OPEN WINDOW w_rol1 AT row_ini, 2 WITH num_rows ROWS, num_cols COLUMNS
	ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE lin_menu,
		  MESSAGE LINE LAST, BORDER) 
IF vg_gui = 1 THEN
	OPEN FORM f_rolf412_1 FROM '../forms/rolf412_1'
ELSE
	OPEN FORM f_rolf412_1 FROM '../forms/rolf412_1c'
END IF
DISPLAY FORM f_rolf412_1
CALL cargar_datos_liq() RETURNING resul
IF resul THEN
	RETURN
END IF
WHILE TRUE
	CALL mostrar_datos_liq()
	CALL lee_parametros()
	IF int_flag THEN
		EXIT WHILE
	END IF
	CALL control_reporte()
END WHILE

END FUNCTION



FUNCTION cargar_datos_liq()
DEFINE r_n01		RECORD LIKE rolt001.*
DEFINE r_n05		RECORD LIKE rolt005.*
DEFINE r_n38		RECORD LIKE rolt038.*
DEFINE mensaje		VARCHAR(200)

INITIALIZE rm_n38.* TO NULL
CALL fl_lee_parametro_general_roles()  RETURNING rm_n00.*
IF rm_n00.n00_serial IS NULL THEN
        CALL fl_mostrar_mensaje('No existe configuración general para este módulo.', 'stop')
	RETURN 1
END IF
CALL fl_lee_compania_roles(vg_codcia) RETURNING r_n01.*
IF r_n01.n01_compania IS NULL THEN
        CALL fl_mostrar_mensaje('No existe configuración para esta compañía.', 'stop')
	RETURN 1
END IF
IF r_n01.n01_estado <> 'A' THEN
        CALL fl_mostrar_mensaje('Compañía no está activa.', 'stop')
	RETURN 1
END IF
INITIALIZE r_n05.* TO NULL
SELECT * INTO r_n05.* FROM rolt005
	WHERE n05_compania = vg_codcia
	  AND n05_proceso  = 'FR'
IF r_n05.n05_compania IS NULL THEN
        CALL fl_mostrar_mensaje('No existe ningún proceso Fondo de Reserva.', 'stop')
	RETURN 1
END IF
INITIALIZE r_n38.* TO NULL
DECLARE q_n38 CURSOR FOR
	SELECT * FROM rolt038
		WHERE n38_compania  = vg_codcia
		  AND n38_fecha_ini = r_n05.n05_fecini_act
		  AND n38_fecha_fin = r_n05.n05_fecfin_act
OPEN q_n38
FETCH q_n38 INTO r_n38.*
IF STATUS = NOTFOUND THEN
        CALL fl_mostrar_mensaje('No hay ningún proceso del Fondo de Reserva generado.', 'stop')
	CLOSE q_n38
	FREE q_n38
	RETURN 1
END IF
LET rm_n38.n38_fecha_ini = r_n38.n38_fecha_ini
LET rm_n38.n38_fecha_fin = r_n38.n38_fecha_fin
CLOSE q_n38
FREE q_n38
RETURN 0

END FUNCTION



FUNCTION mostrar_datos_liq()

DISPLAY BY NAME rm_n38.n38_fecha_ini, rm_n38.n38_fecha_fin

END FUNCTION



FUNCTION lee_parametros()
DEFINE fec_ini		LIKE rolt038.n38_fecha_ini
DEFINE fec_fin		LIKE rolt038.n38_fecha_fin

LET int_flag = 0
INPUT BY NAME rm_n38.n38_fecha_ini, rm_n38.n38_fecha_fin
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		LET int_flag = 1
		RETURN
	BEFORE FIELD n38_fecha_ini
		LET fec_ini = rm_n38.n38_fecha_ini
	BEFORE FIELD n38_fecha_fin
		LET fec_fin = rm_n38.n38_fecha_fin
	AFTER FIELD n38_fecha_ini
		IF rm_n38.n38_fecha_ini IS NULL THEN
			LET rm_n38.n38_fecha_ini = fec_ini
			DISPLAY BY NAME rm_n38.n38_fecha_ini
		END IF
		IF rm_n38.n38_fecha_ini > TODAY THEN
			CALL fl_mostrar_mensaje('La fecha inicial no puede ser mayor a la fecha de hoy.', 'exclamation')
			NEXT FIELD n38_fecha_ini
		END IF
	AFTER FIELD n38_fecha_fin
		IF rm_n38.n38_fecha_fin IS NULL THEN
			LET rm_n38.n38_fecha_fin = fec_fin
			DISPLAY BY NAME rm_n38.n38_fecha_fin
		END IF
		IF rm_n38.n38_fecha_fin > TODAY THEN
			CALL fl_mostrar_mensaje('La fecha final no puede ser mayor a la fecha de hoy.', 'exclamation')
			NEXT FIELD n38_fecha_fin
		END IF
	AFTER INPUT
		IF rm_n38.n38_fecha_ini > rm_n38.n38_fecha_fin THEN
			CALL fl_mostrar_mensaje('La fecha inicial no puede ser mayor a la fecha final.', 'exclamation')
			NEXT FIELD n38_fecha_ini
		END IF
END INPUT

END FUNCTION



FUNCTION control_reporte()
DEFINE comando		VARCHAR(150)
DEFINE archivo		VARCHAR(12)

CALL fl_lee_datos_aportes_reserva(vg_codcia, 2) RETURNING rm_n66.*
IF rm_n66.n66_compania IS NULL THEN
	CALL fl_mostrar_mensaje('No existe el registro de datos extra para generar la planilla del Fondo de Reserva.', 'stop')
	EXIT PROGRAM
END IF
LET archivo = rm_n66.n66_pre_arch, MONTH(rm_n38.n38_fecha_fin) USING '&&',
		rm_g01.g01_numpatronal[1, 5], '.TXT'
LET comando = 'Generando archivo plano ', archivo CLIPPED,
		' espere por favor ... '
ERROR comando
CALL archivo_planilla(archivo)
LET comando = 'mv fondo_reser.txt $HOME/tmp/', archivo CLIPPED
RUN comando
ERROR '                                                            '

END FUNCTION



FUNCTION archivo_planilla(archivo)
DEFINE archivo		VARCHAR(12)
DEFINE cod_trab		LIKE rolt038.n38_cod_trab
DEFINE nombres		LIKE rolt030.n30_nombres
DEFINE r_g01		RECORD LIKE gent001.*
DEFINE r_g02		RECORD LIKE gent002.*
DEFINE r_n30		RECORD LIKE rolt030.*
DEFINE val_fon		DECIMAL(14,2)
DEFINE total		DECIMAL(14,2)
DEFINE long, enter	SMALLINT
DEFINE nro_empleados	SMALLINT
DEFINE total_ca		VARCHAR(12)
DEFINE condicion_afi	VARCHAR(10)
DEFINE registro		VARCHAR(236)

LET enter = 13
DECLARE q_par CURSOR FOR
	SELECT UNIQUE n38_cod_trab, n30_nombres FROM rolt038, rolt030
		WHERE n38_compania   = vg_codcia
		  AND n38_fecha_ini  = rm_n38.n38_fecha_ini
		  AND n38_fecha_fin  = rm_n38.n38_fecha_fin
		  AND n38_estado    <> 'E'
		  AND n38_compania    = n30_compania
		  AND n38_cod_trab    = n30_cod_trab
		ORDER BY n30_nombres
OPEN q_par
FETCH q_par INTO cod_trab, nombres
IF STATUS = NOTFOUND THEN
	ERROR '                                                            '
	CALL fl_mensaje_consulta_sin_registros()
	CLOSE q_par
	FREE q_par
	RETURN
END IF
LET r_g01.g01_numpatronal = rm_g01.g01_numpatronal[1, 11]
LET long                  = LENGTH(r_g01.g01_numpatronal)
IF long < 11 THEN
	LET r_g01.g01_numpatronal = rm_g01.g01_numpatronal[1, 11],
					11 - long SPACES
END IF
LET r_g01.g01_razonsocial = rm_g01.g01_razonsocial[1, 30]
LET long                  = LENGTH(r_g01.g01_razonsocial)
IF long < 30 THEN
	LET r_g01.g01_razonsocial = rm_g01.g01_razonsocial[1, 30],
					30 - long SPACES
END IF
LET r_g02.g02_direccion = rm_g02.g02_direccion[1, 27]
LET long                = LENGTH(r_g02.g02_direccion)
IF long < 27 THEN
	LET r_g02.g02_direccion = rm_g02.g02_direccion[1, 27], 27 - long SPACES
END IF
LET registro = rm_n66.n66_sec_patronal, r_g01.g01_numpatronal[1, 11],
		r_g01.g01_razonsocial[1, 30],
		rm_g02.g02_numruc USING '&&&&&&&&&&&&&',
		rm_n66.n66_provincia USING '&&', rm_n66.n66_canton USING '&&&',
		rm_n66.n66_parroquia USING '&&&&', r_g02.g02_direccion[1, 27]
LET r_g01.g01_replegal = rm_g01.g01_replegal[1, 28]
LET long               = LENGTH(r_g01.g01_replegal)
IF long < 28 THEN
	LET r_g01.g01_replegal = rm_g01.g01_replegal[1, 28], 28 - long SPACES
END IF
LET long     = LENGTH(rm_g02.g02_telefono1)
LET registro = registro, rm_g02.g02_telefono1[long - 5, long],
		r_g01.g01_replegal[1, 28], 2 SPACES, rm_g01.g01_cedrepl[1, 10],
		rm_n66.n66_concepto_pago USING '#', '0000000000000000',
		rm_n38.n38_fecha_ini USING 'YYYYMM',
		rm_n38.n38_fecha_fin USING 'YYYYMM',
		'00000000000000000000000000000000000000000000000',
		rm_n66.n66_tipo_seguro USING '&&&',
		rm_n66.n66_tipo_planilla USING '&&&'
LET nro_empleados = 0
FOREACH q_par INTO cod_trab, nombres
	LET nro_empleados = nro_empleados + 1
END FOREACH
LET registro = registro, nro_empleados USING '&&&&&'
SELECT SUM(n38_valor_fondo) INTO total FROM rolt038
	WHERE n38_compania  = vg_codcia
	  AND n38_fecha_ini = rm_n38.n38_fecha_ini
	  AND n38_fecha_fin = rm_n38.n38_fecha_fin
LET total_ca = total USING "&&&&&&&&&.&&"
LET total_ca = total_ca[1, 9], total_ca[11, 12]
LET registro = registro, total_ca, '1'
DISPLAY registro, ASCII(enter)
FOREACH q_par INTO cod_trab, nombres
	LET val_fon = 0
	SELECT n38_valor_fondo INTO val_fon FROM rolt038
		WHERE n38_compania  = vg_codcia
		  AND n38_fecha_ini = rm_n38.n38_fecha_ini
		  AND n38_fecha_fin = rm_n38.n38_fecha_fin
		  AND n38_cod_trab  = cod_trab
	CALL fl_lee_trabajador_roles(vg_codcia, cod_trab) RETURNING r_n30.*
	LET r_n30.n30_nombres = nombres
	LET long              = LENGTH(nombres)
	IF long < 30 THEN
		LET r_n30.n30_nombres = nombres, 30 - long SPACES
	END IF
	LET registro = rm_n38.n38_fecha_ini USING 'YYYYMM',
			r_n30.n30_carnet_seg[1, 13] USING '&&&&&&&&&&&&&',
			r_n30.n30_num_doc_id[1, 10] USING '&&&&&&&&&&',
			r_n30.n30_nombres[1, 30],
			rm_n38.n38_fecha_ini USING 'YYYYMM',
			rm_n38.n38_fecha_fin USING 'YYYYMM', '0000000000'
	LET condicion_afi = '00', '00000000'
	{--
	IF dias_trab < 360 THEN
		IF (r_n30.n30_fecha_ing >= rm_n38.n38_fecha_ini) AND
		   (r_n30.n30_fecha_ing <= rm_n38.n38_fecha_fin)
		THEN
		LET condicion_afi = '01', r_n30.n30_fecha_ing USING 'YYYYMMDD'
	END IF
	--}
	LET total_ca = val_fon USING "&&&&&&&.&&"
	LET total_ca = total_ca[1, 7], total_ca[9, 10]
	LET registro = registro, total_ca, '00', '00',
			condicion_afi, 131 SPACES, '2'
	DISPLAY registro, ASCII(enter)
END FOREACH
CALL fl_mostrar_mensaje('Generado el archivo texto ' || archivo || '.', 'info')

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
