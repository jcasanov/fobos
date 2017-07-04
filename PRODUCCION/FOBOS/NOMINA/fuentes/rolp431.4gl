------------------------------------------------------------------------------
-- Titulo           : rolp431.4gl - Impresión de la Carta para casas comerciales
-- Elaboracion      : 01-Oct-2003
-- Autor            : JCM
-- Formato Ejecucion: fglrun rolp431 base modulo compañía
-- Ultima Correccion: 
-- Motivo Correccion: 
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE rm_cia		RECORD LIKE gent001.*
DEFINE rm_loc		RECORD LIKE gent002.*
DEFINE rm_g31		RECORD LIKE gent031.*
DEFINE rm_n60		RECORD LIKE rolt060.*
DEFINE rm_n62		RECORD LIKE rolt062.*

DEFINE rm_par		RECORD
	n62_cod_almacen	LIKE rolt062.n62_cod_almacen,
	n62_nombre	LIKE rolt062.n62_nombre,
	n30_cod_trab	LIKE rolt030.n30_cod_trab,
	n30_nombres	LIKE rolt030.n30_nombres,
	valor		DECIMAL(12,2)
END RECORD
DEFINE rm_doc		RECORD 
	n30_tipo_doc_id	LIKE rolt030.n30_tipo_doc_id,
	n30_num_doc_id	LIKE rolt030.n30_num_doc_id
END RECORD



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/errores')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 3 THEN
	-- Validar # parámetros correcto
	CALL fl_mostrar_mensaje('Número de parámetros incorrecto.','stop')
	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_proceso = 'rolp431'
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
CALL fl_lee_compania(vg_codcia) RETURNING rm_cia.*
IF rm_cia.g01_compania IS NULL THEN
	CALL fl_mostrar_mensaje('No existe compañía.','stop')
	EXIT PROGRAM
END IF
CALL fl_lee_localidad(vg_codcia, vg_codloc) RETURNING rm_loc.*
IF rm_loc.g02_compania IS NULL THEN
	CALL fl_mostrar_mensaje('No existe localidad.','stop')
	EXIT PROGRAM
END IF
CALL fl_lee_ciudad(rm_loc.g02_ciudad) RETURNING rm_g31.*

CALL fl_lee_parametros_club_roles(vg_codcia) RETURNING rm_n60.*
IF rm_n60.n60_compania IS NULL THEN
	CALL fl_mostrar_mensaje('No hay parametros para club.','stop')
	EXIT PROGRAM
END IF


LET lin_menu = 0
LET row_ini  = 3
LET num_rows = 09
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
OPEN FORM f_rolf431_1 FROM '../forms/rolf431_1'
DISPLAY FORM f_rolf431_1

WHILE TRUE
	CALL lee_parametros()
	IF int_flag THEN
		EXIT WHILE
	END IF
	CALL control_reporte()
END WHILE

END FUNCTION



FUNCTION lee_parametros()
DEFINE r_n30		RECORD LIKE rolt030.*
DEFINE r_n62		RECORD LIKE rolt062.*

INITIALIZE rm_par.* TO NULL

LET int_flag = 0
INPUT BY NAME rm_par.* WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		LET int_flag = 1
		RETURN
	ON KEY(F2)
		IF infield(n30_cod_trab) THEN
			CALL fl_ayuda_codigo_empleado(vg_codcia) 
				RETURNING r_n30.n30_cod_trab,
					  r_n30.n30_nombres
			IF r_n30.n30_cod_trab IS NOT NULL THEN
				LET rm_par.n30_cod_trab = r_n30.n30_cod_trab
				LET rm_par.n30_nombres  = r_n30.n30_nombres
				DISPLAY BY NAME rm_par.n30_cod_trab, 
						rm_par.n30_nombres  
			END IF
		END IF
		IF infield(n62_cod_almacen) THEN
                        CALL fl_ayuda_casas_comerciales(vg_codcia)
                                RETURNING r_n62.n62_cod_almacen,
					  r_n62.n62_nombre 
                        IF r_n62.n62_cod_almacen IS NOT NULL THEN
				LET rm_par.n62_cod_almacen = 
					r_n62.n62_cod_almacen
				LET rm_par.n62_nombre = r_n62.n62_nombre
                                DISPLAY BY NAME rm_par.n62_cod_almacen,
						rm_par.n62_nombre
                        END IF
                END IF
		LET int_flag = 0
	AFTER FIELD n62_cod_almacen
		IF rm_par.n62_cod_almacen IS NOT NULL THEN
			CALL fl_lee_casa_comercial(vg_codcia, 
						   rm_par.n62_cod_almacen
						  ) RETURNING r_n62.*	
			IF r_n62.n62_cod_almacen IS NOT NULL THEN
				LET rm_par.n62_cod_almacen = 
					r_n62.n62_cod_almacen
				LET rm_par.n62_nombre  = r_n62.n62_nombre
				DISPLAY BY NAME rm_par.n62_cod_almacen,
						rm_par.n62_nombre
			END IF
		END IF
	AFTER FIELD n30_cod_trab
		IF rm_par.n30_cod_trab IS NOT NULL THEN
			CALL fl_lee_trabajador_roles(vg_codcia, 
				rm_par.n30_cod_trab)
                        	RETURNING r_n30.*
			IF r_n30.n30_compania IS NULL THEN
				CALL fgl_winmessage(vg_producto,'Codigo de trabajador no existe.','exclamation')
				NEXT FIELD n30_cod_trab
			END IF
			LET rm_doc.n30_tipo_doc_id = r_n30.n30_tipo_doc_id
			LET rm_doc.n30_num_doc_id  = r_n30.n30_num_doc_id
			LET rm_par.n30_nombres     = r_n30.n30_nombres
			DISPLAY BY NAME rm_par.n30_nombres
		ELSE
			CLEAR n30_nombres
			LET rm_par.n30_nombres = NULL
		END IF
END INPUT

END FUNCTION



FUNCTION control_reporte()
DEFINE comando		VARCHAR(100)
DEFINE resul		SMALLINT

CALL fl_control_reportes() RETURNING comando
IF int_flag THEN
	RETURN
END IF

--START REPORT reporte_carta TO PIPE comando
START REPORT reporte_carta TO FILE "carta_club.txt"
	OUTPUT TO REPORT reporte_carta()
FINISH REPORT reporte_carta

END FUNCTION



REPORT reporte_carta()
DEFINE tot_neto		VARCHAR(15)
DEFINE mes		VARCHAR(11)
DEFINE i, lim		SMALLINT

DEFINE tipo_doc		VARCHAR(15)

DEFINE act_dob1		SMALLINT
DEFINE des_dob		SMALLINT
DEFINE act_dob2		SMALLINT
DEFINE escape, act_des  SMALLINT
DEFINE act_comp, db_c   SMALLINT
DEFINE desact_comp, db  SMALLINT
DEFINE act_neg, des_neg SMALLINT
DEFINE act_10cpi        SMALLINT
DEFINE act_12cpi        SMALLINT

OUTPUT
	TOP MARGIN	8
	LEFT MARGIN	0
	RIGHT MARGIN	80
	BOTTOM MARGIN	4
	PAGE LENGTH	66

FORMAT

PAGE HEADER
        LET escape      = 27            # Iniciar sec. impresi¢n
        LET act_comp    = 15            # Activar Comprimido.
        LET desact_comp = 18            # Cancelar Comprimido.
        LET act_neg     = 71            # Activar negrita.
        LET des_neg     = 72            # Desactivar negrita.
        LET act_des     = 0
        LET act_10cpi   = 80            # Comprimido 10 CPI.
        LET act_12cpi   = 77            # Comprimido 12 CPI.
	LET act_dob1	= 87		# Activar Doble Ancho (inicio)
	LET act_dob2	= 49		# Activar Doble Ancho (final)
	LET des_dob	= 48		# Desactivar Doble Ancho

	print ascii escape; 
	print ascii desact_comp;
	print ascii escape; 
	print ascii act_10cpi

	CALL fl_justifica_titulo('I', fl_retorna_nombre_mes(MONTH(TODAY)), 10)
		RETURNING mes
	PRINT COLUMN 030, rm_g31.g31_nombre CLIPPED, ", ", mes CLIPPED, " ",
		DAY(TODAY) USING "&&", " de ", YEAR(TODAY) USING "&&&&"
	SKIP 3 LINES
	PRINT COLUMN 001, "Señores"
	PRINT COLUMN 001, rm_par.n62_nombre
	PRINT COLUMN 001, "Ciudad.-"
	SKIP 3 LINES
	PRINT COLUMN 001, "Estimados Senores:"
	SKIP 2 LINES

ON EVERY ROW
	CASE rm_doc.n30_tipo_doc_id
		WHEN 'C'
			LET tipo_doc = 'CED. IDENT. # :'
		WHEN 'P'
			LET tipo_doc = 'PASAPORTE   # :'
	END CASE

	LET tot_neto = rm_par.valor USING "--,---,--&.##"
	PRINT COLUMN 001, "Por medio de la presente, sirvanse entregar al portador de la misma: "

	SKIP 1 LINES
	print ascii escape, ascii act_neg, "NOMBRE        :", 
              ascii escape, ascii des_neg, rm_par.n30_nombres  
	SKIP 1 LINES
	print ascii escape, ascii act_neg, tipo_doc, 
              ascii escape, ascii des_neg, rm_doc.n30_num_doc_id
	SKIP 1 LINES
	print ascii escape, ascii act_neg, "VALOR         :",
              ascii escape, ascii des_neg, tot_neto
	SKIP 1 LINES

	PRINT COLUMN 001, "La mercaderia requerida que sera cancelada segun acuerdo convenido."
	SKIP 1 LINES
	PRINT COLUMN 001, "Por la favorable atencion, nos suscribimos de ustedes."

ON LAST ROW
	SKIP 3 LINES
	PRINT COLUMN 001, "Muy Atentamente,"
	print ascii escape, ascii act_neg, 'CLUB SOCIAL Y DEPORTIVO "ACERO"',
	      ascii escape, ascii des_neg
	SKIP 3 LINES

	PRINT COLUMN 001, rm_n60.n60_presidente[1, 25] CLIPPED,
              COLUMN 055, rm_n60.n60_tesorero[1, 25] CLIPPED 
	print ascii escape, ascii act_neg; 
	PRINT COLUMN 003, "PRESIDENTE", COLUMN 058, "TESORERO";
	print ascii escape, ascii des_neg

END REPORT
