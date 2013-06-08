--------------------------------------------------------------------------------
-- Titulo           : rolp421.4gl - LISTADO DETALLE UTILIDADES
-- Elaboracion      : 09-sep-2003
-- Autor            : JCM
-- Formato Ejecucion: fglrun rolp421 BD MODULO COMPANIA anio 
-- Ultima Correccion:
-- Motivo Correccion: 
--------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE rm_cia		RECORD LIKE gent001.*

DEFINE vm_anio		SMALLINT
DEFINE vm_descuentos	SMALLINT
DEFINE vm_num_trab	SMALLINT

DEFINE rm_n41		RECORD LIKE rolt041.*



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/rolp421.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 THEN     -- Validar # parámetros correcto
	CALL fl_mostrar_mensaje('Número de parametros incorrecto.','stop')
	EXIT PROGRAM
END IF
LET vg_base      = arg_val(1)
LET vg_modulo    = arg_val(2)
LET vg_codcia    = arg_val(3)
LET vm_anio      = arg_val(4)
LET vg_proceso   = 'rolp421'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()
--#CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()

END MAIN



FUNCTION funcion_master()
DEFINE resp		CHAR(6)

CALL fl_nivel_isolation()

INITIALIZE rm_n41.* TO NULL
SELECT * INTO rm_n41.* FROM rolt041 WHERE n41_compania = vg_codcia
		        	      AND n41_ano      = vm_anio
IF rm_n41.n41_compania IS NULL THEN
	CALL fl_mostrar_mensaje('No se ha realizado la distribucion de las utilidades para el ano ' || vm_anio || '.', 'stop')
	EXIT PROGRAM
END IF

LET vm_descuentos = 0
CALL fl_hacer_pregunta('Desea imprimir descuentos?', 'No') RETURNING resp
IF resp = 'Yes' THEN
	LET vm_descuentos = 1
END IF

CALL control_main_reporte()

END FUNCTION



FUNCTION control_main_reporte()
DEFINE comando		VARCHAR(100)
DEFINE r_rol		RECORD
	cod_trab		LIKE rolt042.n42_cod_trab,
	nom_trab		LIKE rolt030.n30_nombres,
	cargo			LIKE gent035.g35_nombre,
	sexo			LIKE rolt030.n30_sexo,
	dias_trab		LIKE rolt042.n42_dias_trab,
	fecha_ing		LIKE rolt042.n42_fecha_ing,
	fecha_sal		LIKE rolt042.n42_fecha_sal,
	val_trabaj		LIKE rolt042.n42_val_trabaj,
	num_cargas		LIKE rolt042.n42_num_cargas,
	val_cargas		LIKE rolt042.n42_val_cargas,
	anticipos		LIKE rolt042.n42_descuentos
END RECORD

CALL fl_control_reportes() RETURNING comando
IF int_flag THEN
	RETURN
END IF
CALL fl_lee_compania(vg_codcia) RETURNING rm_cia.*
IF rm_cia.g01_compania IS NULL THEN
	CALL fl_mostrar_mensaje('No existe compañía.','stop')
	EXIT PROGRAM
END IF

DECLARE q_uti CURSOR FOR
	SELECT n42_cod_trab, n30_nombres, g35_nombre, n30_sexo, n42_dias_trab,
	       n42_fecha_ing, n42_fecha_sal, n42_val_trabaj, n42_num_cargas,
               n42_val_cargas, --n42_descuentos +
		NVL((SELECT SUM(n49_valor)
			FROM rolt049, rolt006
			WHERE n49_compania    = n42_compania
			  AND n49_proceso     = n42_proceso
			  AND n49_fecha_ini   = n42_fecha_ini
			  AND n49_fecha_fin   = n42_fecha_fin
			  AND n49_cod_trab    = n42_cod_trab
			  AND n49_cod_rubro   = n06_cod_rubro), 0)
		FROM rolt042, rolt030, gent035
		WHERE n42_compania  = vg_codcia          
		  AND n42_ano       = vm_anio         
		  AND n30_compania  = n42_compania
		  AND n30_cod_trab  = n42_cod_trab
		  AND g35_compania  = n30_compania
		  AND g35_cod_cargo = n30_cod_cargo
		ORDER BY n30_nombres

--START REPORT report_uti TO FILE "listado.jcm"
START REPORT report_uti TO PIPE comando
LET vm_num_trab = 0
FOREACH q_uti INTO r_rol.*
	LET vm_num_trab = vm_num_trab + 1
	IF r_rol.anticipos IS NULL THEN
		LET r_rol.anticipos = 0
	END IF
	OUTPUT TO REPORT report_uti(r_rol.*)
END FOREACH
FINISH REPORT report_uti

END FUNCTION



REPORT report_uti(r_rol)
DEFINE r_rol		RECORD
	cod_trab		LIKE rolt042.n42_cod_trab,
	nom_trab		LIKE rolt030.n30_nombres,
	cargo			LIKE gent035.g35_nombre,
	sexo			LIKE rolt030.n30_sexo,
	dias_trab		LIKE rolt042.n42_dias_trab,
	fecha_ing		LIKE rolt042.n42_fecha_ing,
	fecha_sal		LIKE rolt042.n42_fecha_sal,
	val_trabaj		LIKE rolt042.n42_val_trabaj,
	num_cargas		LIKE rolt042.n42_num_cargas,
	val_cargas		LIKE rolt042.n42_val_cargas,
	anticipos		LIKE rolt042.n42_descuentos
END RECORD

DEFINE r_n41		RECORD LIKE rolt041.*

DEFINE usuario          VARCHAR(19,15)
DEFINE titulo		VARCHAR(80)
DEFINE modulo		VARCHAR(40)
DEFINE i, long          SMALLINT
DEFINE fecha            DATE
DEFINE fecha_ini        DATE
DEFINE fecha_fin        DATE

DEFINE porc_trabaj 	VARCHAR(5)
DEFINE porc_cargas 	VARCHAR(5)

DEFINE anhos_trab	SMALLINT
DEFINE meses_trab	SMALLINT
DEFINE dias_trab	SMALLINT

DEFINE est		LIKE rolt041.n41_estado
DEFINE estado		VARCHAR(30)

DEFINE escape, act_des  SMALLINT
DEFINE act_comp, db_c   SMALLINT
DEFINE desact_comp, db  SMALLINT
DEFINE act_neg, des_neg SMALLINT
DEFINE act_10cpi        SMALLINT
DEFINE act_12cpi        SMALLINT

OUTPUT
	TOP MARGIN	2
	LEFT MARGIN	0
	RIGHT MARGIN	96 
	BOTTOM MARGIN	4
	PAGE LENGTH	66

FORMAT

PAGE HEADER
	--print 'E';
	--print '&l26A';	-- Indica que voy a trabajar con hojas A4
        LET escape      = 27            # Iniciar sec. impresi¢n
        LET act_comp    = 15            # Activar Comprimido.
        LET desact_comp = 18            # Cancelar Comprimido.
        LET act_neg     = 71            # Activar negrita.
        LET des_neg     = 72            # Desactivar negrita.
        LET act_des     = 0
        LET act_10cpi   = 80            # Comprimido 10 CPI.
        LET act_12cpi   = 77            # Comprimido 12 CPI.

--	print '&k2S' 		-- Letra condensada

        LET modulo  = "MODULO: NOMINA"
        LET long    = LENGTH(modulo)
        LET usuario = 'USUARIO: ', vg_usuario
        CALL fl_justifica_titulo('D', usuario, 19) RETURNING usuario
	IF rm_n41.n41_util_bonif = 'U' THEN
	        CALL fl_justifica_titulo('C', 'UTILIDADES DEL EJERCICIO ECONOMICO ' || vm_anio, 80) RETURNING titulo
	ELSE
	        CALL fl_justifica_titulo('C', 'BONIFICACION DEL EJERCICIO ECONOMICO ' || vm_anio, 80) RETURNING titulo
	END IF
                                                                                
        --PRINT '^[@'
        print ASCII escape;
        print ASCII act_comp;
        print ASCII escape;
        print ASCII act_10cpi

	IF vm_descuentos = 1 THEN
	        PRINT COLUMN 02, rm_cia.g01_razonsocial,
        	      COLUMN 213, "PAGINA: ", PAGENO USING "&&&"
	ELSE
	        PRINT COLUMN 50, rm_cia.g01_razonsocial,
        	      COLUMN 161, "PAGINA: ", PAGENO USING "&&&"
	END IF

--PRINT COLUMN 1, modulo CLIPPED,
          PRINT COLUMN 50, titulo CLIPPED
--    COLUMN 125, UPSHIFT(vg_proceso)
                                                                              
        SKIP 1 LINES

        PRINT COLUMN 01, "FECHA DE IMPRESION: ", TODAY USING "dd-mm-yyyy",
                         1 SPACES, TIME
--              COLUMN 117, fl_justifica_titulo('D', usuario, 15)
        SKIP 1 LINES

	PRINT COLUMN 02,  "COD.",
	      COLUMN 08,  "NOMBRES",
	      COLUMN 55,  "OCUPACION",	
	      COLUMN 86,  "SEXO",	
	      COLUMN 92,  "TIEMPO",
	      COLUMN 98,  "      V A L O R",
	      COLUMN 117, "No. CARGAS",
	      COLUMN 127, "       V A L O R",
	      COLUMN 145, "       T O T A L",
	      COLUMN 163, "FIRMA";
	IF vm_descuentos = 1 THEN
	 	PRINT COLUMN 185, fl_justifica_titulo('D', "ANTICIPOS", 16),
	              COLUMN 203, fl_justifica_titulo('D', "TOTAL", 16)
	ELSE
		PRINT ''
	END IF

	LET porc_trabaj = rm_n41.n41_porc_trabaj USING '#&.##'
	LET porc_cargas = rm_n41.n41_porc_cargas USING '#&.##'

	PRINT COLUMN 86,  "H  M",
	      COLUMN 92,  "TRAB.",
	      COLUMN 97,  "     DEL ", porc_trabaj USING "##&.##", "%",
	      COLUMN 117, "FAMILIARES",
	      COLUMN 127, "     DEL ", porc_cargas USING "##&.##", "%",
	      COLUMN 154, (rm_n41.n41_porc_trabaj + rm_n41.n41_porc_cargas)
				USING "##&.##", "%";
	IF vm_descuentos = 1 THEN
	 	PRINT COLUMN 203, fl_justifica_titulo('D', "A COBRAR", 16)
	ELSE
		PRINT ''
	END IF

        PRINT COLUMN 02,  '--------',
              COLUMN 08,  '----------------------------------------------',
              COLUMN 55,  '----------------------',
              COLUMN 77,  '------',
              COLUMN 83,  '--------------',
              COLUMN 97,  '------------------',
              COLUMN 115, '------------',
              COLUMN 127, '------------------',
              COLUMN 145, '------------------',
              COLUMN 163, '----------------------';
	IF vm_descuentos = 1 THEN
        	PRINT COLUMN 185, '------------------',
        	      COLUMN 203, '------------------'
	ELSE
		PRINT ''
	END IF

ON EVERY ROW
	NEED 2 LINES

	SKIP 2 LINES

	--PRINT COLUMN 02,  r_rol.cod_trab USING '####',
	PRINT COLUMN 02,  vm_num_trab USING '####',
	      COLUMN 08,  r_rol.nom_trab CLIPPED,
	      COLUMN 55,  r_rol.cargo[1, 25] CLIPPED;
	IF r_rol.sexo = 'M' THEN
		PRINT COLUMN 86, '0';
	ELSE
		PRINT COLUMN 89, '1';
	END IF

	LET fecha_ini = MDY(1, 1, vm_anio)
	IF fecha_ini < r_rol.fecha_ing THEN
		LET fecha_ini = r_rol.fecha_ing
	END IF

	LET fecha_fin = MDY(12, 31, vm_anio)
	IF fecha_fin > r_rol.fecha_sal THEN
		LET fecha_fin = r_rol.fecha_sal
	END IF

	PRINT COLUMN 92,  r_rol.dias_trab USING '##&',
	      COLUMN 97,  r_rol.val_trabaj USING '#,###,###,##&.##',
	      COLUMN 125, r_rol.num_cargas USING '#&',
	      COLUMN 127, r_rol.val_cargas USING '#,###,###,##&.##',
	      COLUMN 145, (r_rol.val_trabaj + r_rol.val_cargas)
				 USING '#,###,###,##&.##',
	      COLUMN 163, '____________________'; 
	IF vm_descuentos = 1 THEN
		PRINT COLUMN 185, r_rol.anticipos  USING '#,###,###,##&.##';
		PRINT COLUMN 203, ((r_rol.val_trabaj + r_rol.val_cargas) - 
				   r_rol.anticipos) USING '#,###,###,##&.##'
	ELSE
		PRINT ''
	END IF

ON LAST ROW 
        PRINT COLUMN 90,  '-----',
              COLUMN 97,  '----------------',
              COLUMN 128, '---------------',
              COLUMN 145, '----------------';
	IF vm_descuentos = 1 THEN
		PRINT COLUMN 185, '----------------',  
		      COLUMN 203, '----------------'  
	ELSE
		PRINT ''
	END IF

	INITIALIZE r_n41.* TO NULL
	SELECT n41_val_trabaj, n41_val_cargas
		INTO r_n41.n41_val_trabaj, r_n41.n41_val_cargas
		FROM rolt041
		WHERE n41_compania = vg_codcia
		  AND n41_ano      = vm_anio
	PRINT COLUMN 02,  'TOTALES: ',
	      COLUMN 15,  'TRABAJADORES ==> ', vm_num_trab USING '#,##&',
              COLUMN 90,  SUM(r_rol.dias_trab) USING '####&',
              --COLUMN 97,  SUM(r_rol.val_trabaj) USING '#,###,###,##&.##',
              --COLUMN 127, SUM(r_rol.val_cargas) USING '#,###,###,##&.##',
              COLUMN 97,  r_n41.n41_val_trabaj USING '#,###,###,##&.##',
              COLUMN 127, r_n41.n41_val_cargas USING '#,###,###,##&.##',
              COLUMN 145, SUM(r_rol.val_trabaj + r_rol.val_cargas) 
				USING '#,###,###,##&.##';
	IF vm_descuentos = 1 THEN
		PRINT COLUMN 185, SUM(r_rol.anticipos) USING '#,###,###,##&.##',
		      COLUMN 203, SUM(r_rol.val_trabaj + r_rol.val_cargas - r_rol.anticipos) USING '#,###,###,##&.##'
	ELSE
		PRINT ''
	END IF
END REPORT
