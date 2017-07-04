--------------------------------------------------------------------------------
-- Titulo           : rolp419.4gl - LISTADO DE JUBILADOS           
-- Elaboracion      : 30-sep-2003
-- Autor            : JCM
-- Formato Ejecucion: fglrun rolp419 BD MODULO COMPANIA anio mes
--					cod_liqrol fec_ini fec_fin
-- Ultima Correccion:
-- Motivo Correccion: 
--------------------------------------------------------------------------------

GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE rm_cia		RECORD LIKE gent001.*
DEFINE rm_n48		RECORD LIKE rolt048.*
DEFINE vm_cod_lq	LIKE rolt048.n48_cod_liqrol
DEFINE vm_fec_ini	LIKE rolt048.n48_fecha_ini
DEFINE vm_fec_fin	LIKE rolt048.n48_fecha_fin



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/rolp419.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 6 THEN  	-- Validar # parámetros correcto
	CALL fl_mostrar_mensaje('Número de parámetros incorrecto.','stop')
	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vm_cod_lq  = arg_val(4)
LET vm_fec_ini = arg_val(5)
LET vm_fec_fin = arg_val(6)
LET vg_proceso = 'rolp419'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()
--#CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()

END MAIN



FUNCTION funcion_master()
DEFINE r_n48		RECORD LIKE rolt048.*

CALL fl_nivel_isolation()

CALL fl_lee_compania(vg_codcia) RETURNING rm_cia.*
IF rm_cia.g01_compania IS NULL THEN
	CALL fl_mostrar_mensaje('No existe compañía.','stop')
	EXIT PROGRAM
END IF

CALL control_main_reporte()

END FUNCTION



FUNCTION control_main_reporte()
DEFINE comando		VARCHAR(100)
DEFINE r_rol		RECORD LIKE rolt048.*
DEFINE nombres 		LIKE rolt030.n30_nombres

CALL fl_control_reportes() RETURNING comando
IF int_flag THEN
	RETURN
END IF

DECLARE q_jubilados CURSOR FOR
	SELECT rolt048.*, n30_nombres
		FROM rolt048, rolt030
		WHERE n48_compania   = vg_codcia 
		  AND n48_cod_liqrol = vm_cod_lq
		  AND n48_fecha_ini  = vm_fec_ini
		  AND n48_fecha_fin  = vm_fec_fin
		  AND n30_compania   = n48_compania
		  AND n30_cod_trab   = n48_cod_trab
		ORDER BY n30_nombres

--START REPORT report_jubilados TO FILE "jubilados.jcm"
START REPORT report_jubilados TO PIPE comando
FOREACH q_jubilados INTO r_rol.*, nombres
	OUTPUT TO REPORT report_jubilados(r_rol.*, nombres)
END FOREACH
FINISH REPORT report_jubilados

END FUNCTION



REPORT report_jubilados(r_rol, nombre)
DEFINE r_rol		RECORD LIKE rolt048.*
DEFINE r_n03		RECORD LIKE rolt003.*
DEFINE nombre		LIKE rolt030.n30_nombres
DEFINE usuario          VARCHAR(19,15)
DEFINE titulo		VARCHAR(80)
DEFINE modulo		VARCHAR(40)
DEFINE i, long          SMALLINT
DEFINE fecha            DATE
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

	CALL fl_lee_proceso_roles(vm_cod_lq) RETURNING r_n03.*
	IF vm_cod_lq = 'ME' THEN
		LET titulo = 'ROL DE JUBILADOS CORRESPONDIENTE AL MES DE '
	ELSE
		LET titulo = 'ROL DE JUBILADOS (', r_n03.n03_nombre_abr CLIPPED,
				') MES DE PAGO '
	END IF
	LET titulo = titulo CLIPPED, ' ', UPSHIFT(fl_justifica_titulo('I',
				fl_retorna_nombre_mes(r_rol.n48_mes_proceso),
					15)) CLIPPED, ' / ',
					r_rol.n48_ano_proceso USING '&&&&' 
        CALL fl_justifica_titulo('C', titulo, 80) RETURNING titulo
                                                                                
        --PRINT '^[@'
        print ASCII escape;
        print ASCII desact_comp;
        print ASCII escape;
        print ASCII act_10cpi
        PRINT COLUMN 1, rm_cia.g01_razonsocial,
              COLUMN 69, "PAGINA: ", PAGENO USING "&&&"
        PRINT COLUMN 1,  modulo CLIPPED,
              COLUMN 73, UPSHIFT(vg_proceso) CLIPPED 
        PRINT COLUMN 01, titulo CLIPPED
                                                                                
        SKIP 1 LINES

        PRINT COLUMN 01, "Fecha de Impresión: ", TODAY USING "dd-mm-yyyy",
                         1 SPACES, TIME,
              COLUMN 61 , usuario
        SKIP 1 LINES

	PRINT COLUMN 05,  "CODIGO",
	      COLUMN 13,  "NOMBRES DEL JUBILADO",
	      COLUMN 60,  fl_justifica_titulo('D', "VALOR", 16)

        PRINT COLUMN 03,  '----------',
              COLUMN 13,  '------------------------------------------------',
              COLUMN 60,  '-----------------'

ON EVERY ROW
	NEED 2 LINES

	SKIP 1 LINES
	PRINT COLUMN 05,  r_rol.n48_cod_trab USING '######',
	      COLUMN 13,  nombre CLIPPED,
	      COLUMN 60,  r_rol.n48_val_jub_pat USING '#,###,###,##&.##'
ON LAST ROW 
	PRINT COLUMN 60, '----------------'  
	PRINT COLUMN 46, 'TOTAL: ',
	      COLUMN 60, SUM(r_rol.n48_val_jub_pat) USING '#,###,###,##&.##'

END REPORT
