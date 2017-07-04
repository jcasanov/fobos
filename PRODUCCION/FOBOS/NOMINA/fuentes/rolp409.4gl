--------------------------------------------------------------------------------
-- Titulo           : rolp409.4gl - LISTADO CONTROL LIQUIDACION DECIMO TERCERO
-- Elaboracion      : 28-ago-2003
-- Autor            : JCM
-- Formato Ejecucion: fglrun rolp409 BD MODULO COMPANIA fecha_ini fecha_fin 
-- Ultima Correccion:
-- Motivo Correccion: 
--------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE rm_cia		RECORD LIKE gent001.*
DEFINE vm_proceso	LIKE rolt036.n36_proceso

DEFINE vm_fecha_ini	LIKE rolt036.n36_fecha_ini
DEFINE vm_fecha_fin	LIKE rolt036.n36_fecha_fin

DEFINE rm_n36		RECORD LIKE rolt036.*



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/rolp409.err')
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
LET vg_proceso   = 'rolp409'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()
--#CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()

END MAIN



FUNCTION funcion_master()
DEFINE cuantas		INTEGER

CALL fl_nivel_isolation()

LET vm_proceso   = 'DT'      

SELECT count(*) INTO cuantas FROM rolt036 WHERE n36_compania  = vg_codcia
					    AND n36_proceso   = vm_proceso
			                    AND n36_fecha_ini = vm_fecha_ini
			                    AND n36_fecha_fin = vm_fecha_fin
IF cuantas = 0 THEN	
	CALL fl_mostrar_mensaje('No existe liquidaci¢n de decimos para el periodo: ' || vm_fecha_ini || ' - ' || vm_fecha_fin || '.', 'stop')
	EXIT PROGRAM
END IF

CALL control_main_reporte()

END FUNCTION



FUNCTION control_main_reporte()
DEFINE comando		VARCHAR(100)
DEFINE r_rol		RECORD
	cod_trab		LIKE rolt036.n36_cod_trab,
	nom_trab		LIKE rolt030.n30_nombres,
	ganado			LIKE rolt036.n36_ganado_per,
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
	--CALL fgl_winmessage(vg_producto,'No existe compañía.','stop')
	CALL fl_mostrar_mensaje('No existe compañía.','stop')
	EXIT PROGRAM
END IF

DECLARE q_decimos CURSOR FOR
	SELECT n36_cod_trab, n30_nombres, n36_ganado_per, n36_valor_bruto,
               n36_descuentos, (SELECT SUM(n37_valor) FROM rolt037, rolt006
				WHERE n37_compania  = n36_compania          
				  AND n37_proceso   = n36_proceso         
				  AND n37_fecha_ini = n36_fecha_ini
				  AND n37_fecha_fin = n36_fecha_fin
				  AND n37_cod_trab  = n36_cod_trab
                                  AND n37_cod_rubro = n06_cod_rubro
				  AND (n37_num_prest IS NOT NULL OR
				       n06_flag_ident = 'AN')
                               ) AS anticipos, n36_valor_neto
		FROM rolt036, rolt030
		WHERE n36_compania  = vg_codcia          
		  AND n36_proceso   = vm_proceso         
		  AND n36_fecha_ini = vm_fecha_ini
		  AND n36_fecha_fin = vm_fecha_fin
		  AND n30_compania  = n36_compania
		  AND n30_cod_trab  = n36_cod_trab
		  AND n30_tipo_trab = 'N'
		ORDER BY n30_nombres

--START REPORT report_decimos TO FILE "listado.jcm"
START REPORT report_decimos TO PIPE comando
FOREACH q_decimos INTO r_rol.*
	IF r_rol.anticipos IS NULL THEN
		LET r_rol.anticipos = 0
	END IF
	OUTPUT TO REPORT report_decimos(r_rol.*)
END FOREACH
FINISH REPORT report_decimos

END FUNCTION



REPORT report_decimos(r_rol)
DEFINE r_rol		RECORD
	cod_trab		LIKE rolt036.n36_cod_trab,
	nom_trab		LIKE rolt030.n30_nombres,
	ganado			LIKE rolt036.n36_ganado_per,
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

DEFINE est		LIKE rolt036.n36_estado
DEFINE estado		VARCHAR(30)

DEFINE escape, act_des  SMALLINT
DEFINE act_comp, db_c   SMALLINT
DEFINE desact_comp, db  SMALLINT
DEFINE act_neg, des_neg SMALLINT
DEFINE act_10cpi        SMALLINT
DEFINE act_12cpi        SMALLINT

OUTPUT
	TOP MARGIN	0
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
        CALL fl_justifica_titulo('C', 'LISTADO DECIMO TERCER SUELDO', 30)
                RETURNING titulo
                                                                                
        --PRINT '^[@'
        print ASCII escape;
        print ASCII act_comp
        PRINT COLUMN 1, rm_cia.g01_razonsocial,
              COLUMN 121, "PAGINA: ", PAGENO USING "&&&"
        PRINT COLUMN 1, modulo CLIPPED,
              COLUMN 50, titulo CLIPPED,
              COLUMN 125, UPSHIFT(vg_proceso)
                                                                                
        SKIP 1 LINES

	DECLARE q_est CURSOR FOR
		SELECT n36_estado FROM rolt036
			WHERE n36_compania  = vg_codcia          
			  AND n36_proceso   = vm_proceso         
			  AND n36_fecha_ini = vm_fecha_ini
			  AND n36_fecha_fin = vm_fecha_fin
			GROUP BY 1
      	OPEN q_est
	FETCH q_est INTO est
		
	CASE est 
		WHEN 'A'
			LET estado = 'EN PROCESO'
		WHEN 'P'
			LET estado = 'PROCESADO'
	END CASE

	CLOSE q_est
	FREE  q_est

        PRINT COLUMN 25, "** PERIODO: ", vm_fecha_ini USING "dd-mm-yyyy", 
                         " - ", vm_fecha_fin USING "dd-mm-yyyy",
	      COLUMN 70, "** ESTADO: ", estado
                                                                                
        SKIP 1 LINES
        PRINT COLUMN 01, "Fecha de Impresión: ", TODAY USING "dd-mm-yyyy",
                         1 SPACES, TIME,
              COLUMN 117, fl_justifica_titulo('D', usuario, 15)
        SKIP 1 LINES

	PRINT COLUMN 02,  "COD.",
	      COLUMN 08,  "NOMBRES",
	      COLUMN 45,  fl_justifica_titulo('D', "TOTAL GANADO", 16),
	      COLUMN 63,  fl_justifica_titulo('D', "VALOR DECIMO", 16),
	      COLUMN 81,  fl_justifica_titulo('D', "ANTICIPOS", 16),
	      COLUMN 99,  fl_justifica_titulo('D', "OTROS DESCTOS.", 14),
	      COLUMN 115, fl_justifica_titulo('D', "A RECIBIR", 16)

        PRINT COLUMN 02,  '------',
              COLUMN 08,  '-------------------------------------',
              COLUMN 45,  '------------------',
              COLUMN 63,  '------------------',
              COLUMN 81,  '------------------',
              COLUMN 99,  '----------------',
              COLUMN 115, '------------------'

ON EVERY ROW
	NEED 2 LINES

	PRINT COLUMN 02,  r_rol.cod_trab USING '####',
	      COLUMN 08,  r_rol.nom_trab CLIPPED,
	      COLUMN 45,  r_rol.ganado USING '#,###,###,##&.##',
	      COLUMN 63,  r_rol.valor_bruto USING '#,###,###,##&.##',
	      COLUMN 81,  r_rol.anticipos USING '#,###,###,##&.##',
	      COLUMN 99,  r_rol.descuentos - r_rol.anticipos 
				USING '###,###,##&.##',
	      COLUMN 115, r_rol.valor_neto USING '#,###,###,##&.##'
ON LAST ROW 
	PRINT COLUMN 45,  '----------------',  
	      COLUMN 63,  '----------------',  
	      COLUMN 81,  '----------------',  
	      COLUMN 99,  '--------------',  
	      COLUMN 115, '----------------'  

	PRINT COLUMN 38,  'TOTAL: ',
	      COLUMN 45,  SUM(r_rol.ganado) USING '#,###,###,##&.##',
	      COLUMN 63,  SUM(r_rol.valor_bruto) USING '#,###,###,##&.##',
	      COLUMN 81,  SUM(r_rol.anticipos) USING '#,###,###,##&.##',
	      COLUMN 99,  SUM(r_rol.descuentos - r_rol.anticipos) 
				USING '###,###,##&.##',
	      COLUMN 115, SUM(r_rol.valor_neto) USING '#,###,###,##&.##'
END REPORT
