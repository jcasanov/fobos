--------------------------------------------------------------------------------
-- Titulo           : rolp418.4gl - LISTADO DETALLE DECIMO CUARTO            
-- Elaboracion      : 09-sep-2003
-- Autor            : JCM
-- Formato Ejecucion: fglrun rolp418 BD MODULO COMPANIA fecha_ini fecha_fin 
-- Ultima Correccion:
-- Motivo Correccion: 
--------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE rm_cia		RECORD LIKE gent001.*
DEFINE vm_proceso	LIKE rolt036.n36_proceso

DEFINE vm_fecha_ini	LIKE rolt036.n36_fecha_ini
DEFINE vm_fecha_fin	LIKE rolt036.n36_fecha_fin

DEFINE vm_descuentos	SMALLINT
DEFINE vm_num_trab	SMALLINT

DEFINE rm_n36		RECORD LIKE rolt036.*



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/rolp418.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 5 THEN     -- Validar # parámetros correcto
	--CALL fgl_winmessage(vg_producto,'Número de parámetros incorrecto.','stop')
	CALL fl_mostrar_mensaje('Número de parámetros incorrecto.','stop')
	EXIT PROGRAM
END IF
LET vg_base      = arg_val(1)
LET vg_modulo    = arg_val(2)
LET vg_codcia    = arg_val(3)
LET vm_fecha_ini = arg_val(4)
LET vm_fecha_fin = arg_val(5)
LET vg_proceso   = 'rolp418'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()
--#CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()

END MAIN



FUNCTION funcion_master()
DEFINE cuantas		INTEGER
DEFINE resp		CHAR(6)

CALL fl_nivel_isolation()

LET vm_proceso   = 'DC'      

SELECT count(*) INTO cuantas FROM rolt036 WHERE n36_compania  = vg_codcia
					    AND n36_proceso   = vm_proceso
			                    AND n36_fecha_ini = vm_fecha_ini
			                    AND n36_fecha_fin = vm_fecha_fin
IF cuantas = 0 THEN	
	CALL fl_mostrar_mensaje('No existe liquidación de decimos para el periodo: ' || vm_fecha_ini || ' - ' || vm_fecha_fin || '.', 'stop')
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
	cod_trab		LIKE rolt036.n36_cod_trab,
	nom_trab		LIKE rolt030.n30_nombres,
	fecha_ingreso		LIKE rolt036.n36_fecha_ing,
	cargo			LIKE gent035.g35_nombre,
	sexo			LIKE rolt030.n30_sexo,
	ganado_real		LIKE rolt036.n36_ganado_real,
	valor_bruto		LIKE rolt036.n36_valor_bruto,
	descuentos		LIKE rolt036.n36_descuentos,
	anticipos		LIKE rolt036.n36_descuentos,
	valor_neto		LIKE rolt036.n36_valor_neto
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

DECLARE q_decimos CURSOR FOR
	SELECT n36_cod_trab, n30_nombres, n36_fecha_ing, g35_nombre, n30_sexo, 
	       n36_ganado_real, n36_valor_bruto, n36_descuentos,
               (SELECT SUM(n37_valor) FROM rolt037
		WHERE n37_compania  = n36_compania          
		  AND n37_proceso   = n36_proceso         
		  AND n37_fecha_ini = n36_fecha_ini
		  AND n37_fecha_fin = n36_fecha_fin
		  AND n37_cod_trab  = n36_cod_trab
		  AND n37_num_prest IS NOT NULL
                ) as anticipos, n36_valor_neto
		FROM rolt036, rolt030, gent035
		WHERE n36_compania  = vg_codcia          
		  AND n36_proceso   = vm_proceso         
		  AND n36_fecha_ini = vm_fecha_ini
		  AND n36_fecha_fin = vm_fecha_fin
		  AND n30_compania  = n36_compania
		  AND n30_cod_trab  = n36_cod_trab
--		  AND n30_fecha_reing IS NULL
		  AND g35_compania  = n30_compania
		  AND g35_cod_cargo = n30_cod_cargo
		ORDER BY n30_nombres

--START REPORT report_decimos TO FILE "listado.jcm"
START REPORT report_decimos TO PIPE comando
LET vm_num_trab = 0
FOREACH q_decimos INTO r_rol.*
	--display r_rol.cod_trab
	LET vm_num_trab = vm_num_trab + 1
	IF r_rol.anticipos IS NULL THEN
		LET r_rol.anticipos = 0
	END IF
	LET r_rol.descuentos = r_rol.descuentos - r_rol.anticipos
	OUTPUT TO REPORT report_decimos(r_rol.*)
END FOREACH
FINISH REPORT report_decimos

END FUNCTION



REPORT report_decimos(r_rol)
DEFINE r_rol		RECORD
	cod_trab		LIKE rolt036.n36_cod_trab,
	nom_trab		LIKE rolt030.n30_nombres,
	fecha_ingreso		LIKE rolt036.n36_fecha_ing,
	cargo			LIKE gent035.g35_nombre,
	sexo			LIKE rolt030.n30_sexo,
	ganado_real		LIKE rolt036.n36_ganado_real,
	valor_bruto		LIKE rolt036.n36_valor_bruto,
	descuentos		LIKE rolt036.n36_descuentos,
	anticipos		LIKE rolt036.n36_descuentos,
	valor_neto		LIKE rolt036.n36_valor_neto
END RECORD

DEFINE usuario          VARCHAR(19,15)
DEFINE titulo		VARCHAR(80)
DEFINE modulo		VARCHAR(40)
DEFINE i, long          SMALLINT
DEFINE fecha            DATE
DEFINE fecha_ini        DATE
DEFINE fecha_fin        DATE

DEFINE anhos_trab	SMALLINT
DEFINE meses_trab	SMALLINT
DEFINE dias_trab	SMALLINT

DEFINE est		LIKE rolt036.n36_estado
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
        CALL fl_justifica_titulo('C', 'LIQUIDACION DE VALORES POR DECIMO CUARTO SUELDO', 80)
                RETURNING titulo
                                                                                
        --PRINT '^[@'
        print ASCII escape;
        print ASCII act_comp;
        print ASCII escape;
        print ASCII act_10cpi

	IF vm_descuentos = 1 THEN
	        PRINT COLUMN 50, rm_cia.g01_razonsocial,
        	      COLUMN 213, "PAGINA: ", PAGENO USING "&&&"
	ELSE
	        PRINT COLUMN 50, rm_cia.g01_razonsocial,
        	      COLUMN 161, "PAGINA: ", PAGENO USING "&&&"
	END IF

--PRINT COLUMN 1, modulo CLIPPED,
          PRINT COLUMN 50, titulo CLIPPED
--    COLUMN 125, UPSHIFT(vg_proceso)
                                                                              
        SKIP 1 LINES

        PRINT COLUMN 50, "** PERIODO: ", vm_fecha_ini, " - ", vm_fecha_fin
                                                                                
        SKIP 1 LINES
        PRINT COLUMN 01, "FECHA DE IMPRESION: ", TODAY USING "dd-mm-yyyy",
                         1 SPACES, TIME
--              COLUMN 117, fl_justifica_titulo('D', usuario, 15)
        SKIP 1 LINES

	PRINT COLUMN 02,  "COD.",
	      COLUMN 08,  "NOMBRES",
	      COLUMN 55,  "FECHA ING.",
	      COLUMN 67,  "OCUPACION",	
	      COLUMN 89,  "   CODIGO PARA",
	      COLUMN 111, "SEXO",	
	      COLUMN 117, "TIEMPO TRAB.",
	      COLUMN 131, fl_justifica_titulo('D', "VALOR DECIMO", 16),
	      COLUMN 149, "FIRMA";
	IF vm_descuentos = 1 THEN
	 	PRINT COLUMN 171, fl_justifica_titulo('D', "DESCUENTOS", 16),
	      	      COLUMN 189, fl_justifica_titulo('D', "ANTICIPOS", 16),
	              COLUMN 207, fl_justifica_titulo('D', "A RECIBIR", 16)
	ELSE
		PRINT ''
	END IF

	PRINT COLUMN 89,  'USO OFI. MIN.',
	      COLUMN 111, 'H  M'

        PRINT COLUMN 02,  '--------',
              COLUMN 08,  '----------------------------------------------',
              COLUMN 55,  '------------',
              COLUMN 67,  '----------------------',
              COLUMN 89,  '----------------------',
              COLUMN 111, '------',
              COLUMN 117, '--------------',
              COLUMN 131, '------------------',
              COLUMN 149, '----------------------';
	IF vm_descuentos = 1 THEN
        	PRINT COLUMN 171, '------------------',
        	      COLUMN 189, '------------------',
        	      COLUMN 207, '------------------'
	ELSE
		PRINT ''
	END IF

ON EVERY ROW
	NEED 2 LINES

	SKIP 2 LINES

	PRINT COLUMN 02,  r_rol.cod_trab USING '####',
	      COLUMN 08,  r_rol.nom_trab CLIPPED,
	      COLUMN 55,  r_rol.fecha_ingreso,                       
	      COLUMN 67,  r_rol.cargo;                             
	IF r_rol.sexo = 'M' THEN
		PRINT COLUMN 111, '0';
	ELSE
		PRINT COLUMN 114, '1';
	END IF

	CALL retorna_fechas_calculo_trab(vm_fecha_ini, vm_fecha_fin, 
					 r_rol.cod_trab)
			RETURNING fecha_ini, fecha_fin
	CALL retorna_tiempo_entre_fechas(fecha_ini, fecha_fin, 'S')
		RETURNING anhos_trab, meses_trab, dias_trab
	IF anhos_trab IS NULL THEN
		--display 'fecha ini > fecha_fin, cod_trab: ', r_rol.cod_trab
		EXIT PROGRAM
	END IF
	IF anhos_trab > 0 THEN
		--display 'anhos_trab > 0, cod_trab: ', r_rol.cod_trab
		CALL fl_mostrar_mensaje('Rango de fechas incorrecta.', 'stop')
		EXIT PROGRAM
	END IF

	PRINT COLUMN 117, meses_trab USING '&&', ' M '; 
	IF dias_trab > 0 THEN
		PRINT COLUMN 123, dias_trab USING '&&', ' D';
	END IF
	PRINT COLUMN 131, r_rol.valor_bruto USING '#,###,###,##&.##',
	      COLUMN 149, '____________________'; 
	IF vm_descuentos = 1 THEN
		PRINT COLUMN 171, r_rol.descuentos USING '#,###,###,##&.##';
		PRINT COLUMN 189, r_rol.anticipos  USING '#,###,###,##&.##';
		PRINT COLUMN 207, r_rol.valor_neto USING '#,###,###,##&.##'
	ELSE
		PRINT ''
	END IF

ON LAST ROW 
	PRINT COLUMN 131, '----------------';  
	IF vm_descuentos = 1 THEN
		PRINT COLUMN 171, '----------------',  
		      COLUMN 189, '----------------',  
		      COLUMN 207, '----------------'  
	ELSE
		PRINT ''
	END IF

	PRINT COLUMN 02,  'TOTALES: ',
	      COLUMN 15,  'TRABAJADORES ==> ', vm_num_trab USING '#,##&',
	      COLUMN 131, SUM(r_rol.valor_bruto) USING '#,###,###,##&.##';
	IF vm_descuentos = 1 THEN
		PRINT COLUMN 171, SUM(r_rol.descuentos)  USING '#,###,###,##&.##',
		      COLUMN 189, SUM(r_rol.anticipos)   USING '#,###,###,##&.##',
		      COLUMN 207, SUM(r_rol.valor_neto)  USING '#,###,###,##&.##'
	ELSE
		PRINT ''
	END IF
END REPORT



FUNCTION retorna_tiempo_entre_fechas(fecha_ini, fecha_fin, anho_comercial)
DEFINE fecha_ini		DATE
DEFINE fecha_fin		DATE
DEFINE anho_comercial		CHAR(1)

DEFINE anhos			SMALLINT
DEFINE meses			SMALLINT
DEFINE dias 			SMALLINT
DEFINE dias_mes			SMALLINT
DEFINE fecha			DATE

IF anho_comercial <> 'S' AND anho_comercial <> 'N' THEN
	CALL fl_mostrar_mensaje('Debe especificar si desea usar el mes comercial o no.', 'stop')
	RETURN NULL, NULL, NULL
END IF

IF fecha_ini > fecha_fin THEN
	CALL fl_mostrar_mensaje('Rango de fechas incorrecto.', 'stop')
	RETURN NULL, NULL, NULL
END IF

LET anhos = 0
LET meses = 0
LET dias  = 0

IF fecha_ini = fecha_fin THEN
	RETURN anhos, meses, dias
END IF

LET anhos = year(fecha_fin)  - year(fecha_ini) 
LET meses = month(fecha_fin) - month(fecha_ini)
IF meses < 0 THEN
	LET anhos = anhos - 1
	LET meses = meses + 12
END IF

LET dias_mes = 30 

IF anho_comercial = 'N' THEN
	LET fecha = mdy(month(fecha_ini) + 1, 1, year(fecha_ini))		
	LET fecha = fecha - 1
	LET dias_mes = DAY(fecha)
END IF
IF DAY(fecha_ini) > dias_mes THEN
	LET dias = 0
ELSE
	LET dias = dias_mes - DAY(fecha_ini)
END IF

IF anho_comercial = 'N' THEN
	LET fecha = mdy(month(fecha_fin) + 1, 1, year(fecha_fin))		
	LET fecha = fecha - 1
	LET dias_mes = DAY(fecha)
END IF
IF DAY(fecha_fin) < dias_mes THEN
	LET dias = dias + DAY(fecha_fin)
END IF
LET dias = dias + 1

IF dias >= dias_mes THEN
	LET dias = dias - dias_mes
	LET meses = meses + 1
	IF meses > 12 THEN
		LET meses = meses - 1
		LET anhos = anhos + 1
	END IF
END IF

RETURN anhos, meses, dias

END FUNCTION



FUNCTION retorna_fechas_calculo_trab(fecha_ini_per, fecha_fin_per, cod_trab)
DEFINE fecha_ini_per		DATE
DEFINE fecha_fin_per		DATE
DEFINE cod_trab			SMALLINT

DEFINE fecha_ini_calc		DATE
DEFINE fecha_fin_calc		DATE

DEFINE r_n30		RECORD LIKE rolt030.*

	CALL fl_lee_trabajador_roles(vg_codcia, cod_trab) RETURNING r_n30.*
	IF r_n30.n30_cod_trab IS NULL THEN
		CALL fl_mostrar_mensaje('No existe codigo de trabajador.', 
					'exclamation')
		RETURN NULL, NULL
	END IF

	IF r_n30.n30_fecha_reing IS NOT NULL THEN
		LET fecha_ini_calc = r_n30.n30_fecha_reing
	ELSE
		LET fecha_ini_calc = r_n30.n30_fecha_ing
	END IF
	LET fecha_fin_calc = fecha_fin_per
	IF r_n30.n30_fecha_sal IS NOT NULL THEN
		IF fecha_ini_calc > r_n30.n30_fecha_reing THEN
			LET fecha_fin_calc = r_n30.n30_fecha_sal
			IF fecha_fin_calc > fecha_fin_per THEN
				LET fecha_fin_calc = fecha_fin_per
			END IF
		END IF
	END IF
	IF fecha_ini_calc < fecha_ini_per THEN
		LET fecha_ini_calc = fecha_ini_per
	END IF

	RETURN fecha_ini_calc, fecha_fin_calc
END FUNCTION
