--------------------------------------------------------------------------------
-- Titulo           : rolp415.4gl - REPORTE DE ROLES DE USOS VARIOS
-- Elaboracion      : 21-ago-2003
-- Autor            : JCM
-- Formato Ejecucion: fglrun rolp415 BD MODULO COMPANIA NUM_ROL
-- Ultima Correccion:
-- Motivo Correccion: 
--------------------------------------------------------------------------------

GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_demonios	VARCHAR(12)
DEFINE vm_num_rol	LIKE rolt043.n43_num_rol
DEFINE rm_cia		RECORD LIKE gent001.*

DEFINE rm_n43		RECORD LIKE rolt043.*



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/rolp415.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 THEN     -- Validar # parámetros correcto
	--CALL fgl_winmessage(vg_producto,'Número de parámetros incorrecto.','stop')
	CALL fl_mostrar_mensaje('Número de parámetros incorrecto.','stop')
	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vm_num_rol = arg_val(4)
LET vg_proceso = 'rolp415'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()
--#CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()

END MAIN



FUNCTION funcion_master()
DEFINE r_n43		RECORD LIKE rolt043.*

CALL fl_nivel_isolation()

INITIALIZE rm_n43.* TO NULL
CALL fl_lee_roles_usos_varios(vg_codcia, vm_num_rol) RETURNING rm_n43.*
IF rm_n43.n43_num_rol IS NULL THEN	
	CALL fl_mostrar_mensaje('No existe numero de rol: ' || vm_num_rol || '.', 'stop')
	EXIT PROGRAM
END IF

CALL control_main_reporte()

END FUNCTION



FUNCTION control_main_reporte()
DEFINE comando		VARCHAR(100)
DEFINE r_rol		RECORD
	cod_trab		LIKE rolt044.n44_cod_trab,
	nom_trab		LIKE rolt030.n30_nombres,
	valor			LIKE rolt044.n44_valor,
	tipo_pago		LIKE rolt044.n44_tipo_pago,
	cta_trabaj		LIKE rolt044.n44_cta_trabaj
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

DECLARE q_usos_varios CURSOR FOR
	SELECT n44_cod_trab, n30_nombres, n44_valor, n44_tipo_pago, 
               n44_cta_trabaj 
		FROM rolt044, rolt030
		WHERE n44_compania = rm_n43.n43_compania
		  AND n44_num_rol  = rm_n43.n43_num_rol
		  AND n30_compania = n44_compania
		  AND n30_cod_trab = n44_cod_trab
		ORDER BY n30_nombres

--START REPORT report_usos_varios TO FILE "listado.jcm"
START REPORT report_usos_varios TO PIPE comando
FOREACH q_usos_varios INTO r_rol.*
	OUTPUT TO REPORT report_usos_varios(r_rol.*)
END FOREACH
FINISH REPORT report_usos_varios

END FUNCTION



REPORT report_usos_varios(r_rol)
DEFINE r_rol		RECORD
	cod_trab		LIKE rolt044.n44_cod_trab,
	nom_trab		LIKE rolt030.n30_nombres,
	valor			LIKE rolt044.n44_valor,
	tipo_pago		LIKE rolt044.n44_tipo_pago,
	cta_trabaj		LIKE rolt044.n44_cta_trabaj
END RECORD
DEFINE usuario          VARCHAR(19,15)
DEFINE titulo		VARCHAR(80)
DEFINE modulo		VARCHAR(40)
DEFINE i, long          SMALLINT
DEFINE fecha            DATE

DEFINE estado		VARCHAR(30)
DEFINE tipo_pago	VARCHAR(45)

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
        CALL fl_justifica_titulo('C', 'ROL DE USOS VARIOS', 30)
                RETURNING titulo
                                                                                
        --PRINT '^[@'
        print ASCII escape;
        print ASCII act_comp
        PRINT COLUMN 1, rm_cia.g01_razonsocial,
              COLUMN 110, "PAGINA: ", PAGENO USING "&&&"
        PRINT COLUMN 1, modulo CLIPPED,
              COLUMN 45, titulo CLIPPED,
              COLUMN 110, UPSHIFT(vg_proceso)
                                                                                
        SKIP 1 LINES

	CASE rm_n43.n43_estado 
		WHEN 'A'
			LET estado = 'EN PROCESO'
		WHEN 'P'
			LET estado = 'PROCESADO'
	END CASE

        PRINT COLUMN 20, "** NUMERO DE ROL: ", rm_n43.n43_num_rol,
	      COLUMN 65, "** ESTADO: ", estado
        PRINT COLUMN 20, "** TITULO : ", rm_n43.n43_titulo CLIPPED
                                                                                
        SKIP 1 LINES
        PRINT COLUMN 01, "Fecha de Impresión: ", TODAY USING "dd-mm-yyyy",
                         1 SPACES, TIME,
              COLUMN 101 , usuario
        SKIP 1 LINES

	PRINT COLUMN 02,  "CODIGO",
	      COLUMN 10,  "NOMBRES",
	      COLUMN 53,  fl_justifica_titulo('D', "VALOR", 16),
	      COLUMN 71,  "TIPO PAGO",
	      COLUMN 106, "FIRMA"

        PRINT COLUMN 02,  '--------',
              COLUMN 10,  '--------------------------------------------',
              COLUMN 53,  '-----------------',
              COLUMN 71,  '--------------------------------------',
	      COLUMN 106, '---------------'

ON EVERY ROW
	NEED 2 LINES

	CASE r_rol.tipo_pago
		WHEN 'E'
			LET tipo_pago = 'EFECTIVO'
		WHEN 'C'
			LET tipo_pago = 'CHEQUE'
		WHEN 'T'
			LET tipo_pago = 'TRANSFERENCIA CTA: ', r_rol.cta_trabaj 
	END CASE
	SKIP 1 LINES
	PRINT COLUMN 02,  r_rol.cod_trab USING '######',
	      COLUMN 11,  r_rol.nom_trab CLIPPED,
	      COLUMN 53,  r_rol.valor USING '#,###,###,##&.##',
	      COLUMN 71,  tipo_pago CLIPPED,
	      COLUMN 106, '_ _ _ _ _ _ _ _'
ON LAST ROW 
	PRINT COLUMN 53, '----------------'  
	PRINT COLUMN 46, 'TOTAL: ',
	      COLUMN 53, SUM(r_rol.valor) USING '#,###,###,##&.##'

END REPORT

