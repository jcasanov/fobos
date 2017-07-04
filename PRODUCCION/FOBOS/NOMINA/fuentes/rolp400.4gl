--------------------------------------------------------------------------------
-- Titulo           : rolp400.4gl - LISTADO DATOS BASICOS DE TRABAJADORES     
-- Elaboracion      : 12-sep-2003
-- Autor            : JCM
-- Formato Ejecucion: fglrun rolp400 BD MODULO COMPANIA 
-- Ultima Correccion:
-- Motivo Correccion: 
--------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE rm_cia		RECORD LIKE gent001.*
DEFINE rm_par		RECORD 
				n30_estado	LIKE rolt030.n30_estado,
				n_estado	VARCHAR(10),
			        n30_cod_depto	LIKE rolt030.n30_cod_depto,
			        tit_departamento VARCHAR(35) 
			END RECORD
DEFINE vm_imprimir	CHAR(1)



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/rolp400.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 3 THEN     -- Validar # parámetros correcto
	CALL fl_mostrar_mensaje('Número de parámetros incorrecto.','stop')
	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_proceso = 'rolp400'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()
--#CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()

END MAIN



FUNCTION funcion_master()
DEFINE salir		SMALLINT

CALL fl_nivel_isolation()
SELECT rolt030.*, g34_nombre 
	FROM rolt030, gent034 
	WHERE n30_compania  = vg_codcia 
	  AND g34_compania  = n30_compania
	  AND g34_cod_depto = n30_cod_depto
	INTO TEMP te_rol 
OPEN WINDOW wf AT 3,2 WITH 5 ROWS, 80 COLUMNS
    ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE LAST - 1,BORDER,
	      MESSAGE LINE LAST - 1)
OPTIONS INPUT WRAP,
	ACCEPT KEY	F12
OPEN FORM f_rol FROM "../forms/rolf400_1"
DISPLAY FORM f_rol

LET salir = 0
WHILE NOT salir
	LET int_flag = 0
	LET salir = control_main_reporte()
END WHILE

CLOSE WINDOW wf

END FUNCTION



FUNCTION control_main_reporte()
DEFINE comando		VARCHAR(100)
DEFINE query		VARCHAR(1000)
DEFINE expr_depto	VARCHAR(100)
DEFINE expr_estado	VARCHAR(100)

DEFINE r_rol		RECORD LIKE rolt030.*
DEFINE g34_nombre	LIKE gent034.g34_nombre

CALL fl_lee_compania(vg_codcia) RETURNING rm_cia.*
IF rm_cia.g01_compania IS NULL THEN
	--CALL fgl_winmessage(vg_producto,'No existe compañía.','stop')
	CALL fl_mostrar_mensaje('No existe compañía.','stop')
	EXIT PROGRAM
END IF

CALL filtrar_datos_empleado()
IF int_flag THEN
	LET int_flag = 0
	RETURN 1
END IF

CALL que_imprimo()
IF int_flag THEN
	LET int_flag = 0
	RETURN 0
END IF

CALL fl_control_reportes() RETURNING comando
IF int_flag THEN
	LET int_flag = 0
	RETURN 0
END IF

LET expr_estado = ' '
IF rm_par.n30_estado IS NOT NULL THEN
	LET expr_estado = ' AND n30_estado = "', rm_par.n30_estado, '"'
END IF

LET expr_depto = ' '
IF rm_par.n30_cod_depto IS NOT NULL THEN
	LET expr_depto = ' AND n30_cod_depto = ', rm_par.n30_cod_depto
END IF

LET query = 'SELECT * FROM te_rol WHERE n30_compania = ', vg_codcia, 
				expr_estado CLIPPED, expr_depto CLIPPED,
				' ORDER BY g34_nombre, n30_estado, n30_nombres '

PREPARE stmnt FROM query
DECLARE q_rol CURSOR FOR stmnt

IF vm_imprimir = '0' OR vm_imprimir = '1' THEN
	START REPORT report_roles_parte1 TO PIPE comando
--	START REPORT report_roles_parte1 TO FILE "file.txt"
		FOREACH q_rol INTO r_rol.*, g34_nombre
			OUTPUT TO REPORT report_roles_parte1(r_rol.*, g34_nombre)
		END FOREACH
	FINISH REPORT report_roles_parte1
END IF

IF vm_imprimir = '0' OR vm_imprimir = '2' THEN
	START REPORT report_roles_parte2 TO PIPE comando
--	START REPORT report_roles_parte2 TO FILE "file22.txt"
		FOREACH q_rol INTO r_rol.*, g34_nombre
			OUTPUT TO REPORT report_roles_parte2(r_rol.*, g34_nombre)
		END FOREACH
	FINISH REPORT report_roles_parte2
END IF

FREE q_rol

RETURN 0

END FUNCTION



REPORT report_roles_parte1(r_rol, g34_nombre)
DEFINE r_rol		RECORD LIKE rolt030.*
DEFINE g34_nombre	LIKE gent034.g34_nombre

DEFINE r_g13		RECORD LIKE gent013.*
DEFINE r_g35		RECORD LIKE gent035.*
DEFINE r_n13		RECORD LIKE rolt013.*
DEFINE r_n17		RECORD LIKE rolt017.*

DEFINE sueldo		LIKE rolt030.n30_sueldo_mes
DEFINE fecha		LIKE rolt030.n30_fecha_ing
DEFINE fecha_str	VARCHAR(20)
DEFINE fecha_sal	VARCHAR(20)
DEFINE sub_activ	LIKE rolt030.n30_sub_activ
DEFINE ced_pas   	CHAR(5)
DEFINE acum_est		DECIMAL(12,2)
DEFINE acum_depto	DECIMAL(12,2)

DEFINE usuario          VARCHAR(19,15)
DEFINE titulo		VARCHAR(80)
DEFINE modulo		VARCHAR(40)
DEFINE i, long          SMALLINT

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
	TOP MARGIN	1
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
	LET act_dob1	= 87		# Activar Doble Ancho (inicio)
	LET act_dob2	= 49		# Activar Doble Ancho (final)
	LET des_dob	= 48		# Desactivar Doble Ancho

	LET acum_depto = 0
	LET acum_est = 0
--	print '&k2S' 		-- Letra condensada

        LET modulo  = "MODULO: NOMINA"
        LET long    = LENGTH(modulo)
        LET usuario = 'USUARIO: ', vg_usuario
        CALL fl_justifica_titulo('D', usuario, 19) RETURNING usuario
        CALL fl_justifica_titulo('C', 'LISTADO DE TRABAJADORES - SECCION PRIMERA', 80)
                RETURNING titulo
                                                                                
        --PRINT '^[@'
        print ASCII escape;
        print ASCII act_comp;
        print ASCII escape;
	print ASCII act_12cpi

	SKIP 1 LINES
        PRINT COLUMN 1, rm_cia.g01_razonsocial,
              COLUMN 256, "PAGINA: ", PAGENO USING "&&&"
        PRINT COLUMN 1, modulo CLIPPED,
              COLUMN 50, titulo CLIPPED,
              COLUMN 260, UPSHIFT(vg_proceso)
                                                                                
        SKIP 1 LINES
        PRINT COLUMN 01, "Fecha de Impresión: ", TODAY USING "dd-mm-yyyy",
                         1 SPACES, TIME,
              COLUMN 252, fl_justifica_titulo('D', usuario, 15)
        SKIP 1 LINES

	PRINT COLUMN 02,  "COD.",
	      COLUMN 07,  "NOMBRES",
	      COLUMN 54,  "CARGO",
	      COLUMN 86,  fl_justifica_titulo('D', "SUELDO", 20),
	      COLUMN 108, "FECHA ING./REING.",
	      COLUMN 127, "FECHA SAL.",
	      COLUMN 139, "SUB-ACTIVIDAD",
	      COLUMN 154, "IDENTIFICACION",
	      COLUMN 176, "SEGURO SOCIAL", 
	      COLUMN 198, "%DES.", 
	      COLUMN 205, "ID. SEGURO", 
	      COLUMN 222, "SECTORIAL",
	      COLUMN 234, "DESCRIPCION" 

-- si el empleado esta jubilado se imprimira el campo n30_val_jub_pat
-- en la columna sueldo

	PRINT COLUMN 01,  "------",
	      COLUMN 07,  "-----------------------------------------------",
	      COLUMN 54,  "--------------------------------",
	      COLUMN 86,  "----------------------",
	      COLUMN 108, "--------------------",
	      COLUMN 127, "------------",
	      COLUMN 139, "---------------",
	      COLUMN 154, "----------------------",
	      COLUMN 176, "---------------------------", 
	      COLUMN 203, "---------------", 
	      COLUMN 218, "-----------------", 
	      COLUMN 235, "--------------------------------" 

BEFORE GROUP OF r_rol.n30_cod_depto
	NEED 8 LINES

	SKIP 1 LINES

	PRINT ASCII escape, ASCII act_neg, 
              ASCII escape, ASCII act_dob1, ASCII act_dob2,
		'DEPARTAMENTO: ', g34_nombre, 
	      ASCII escape, ASCII act_dob1, ASCII des_dob,
	      ASCII escape, ASCII des_neg
	LET acum_depto = 0
	LET acum_est = 0

BEFORE GROUP OF r_rol.n30_estado
	NEED 6 LINES
	
	CASE r_rol.n30_estado
		WHEN 'A'
			PRINT ASCII escape, ASCII act_neg,
			      'ESTADO: ACTIVO', 
			      ASCII escape, ASCII des_neg
		WHEN 'I'
			PRINT ASCII escape, ASCII act_neg,
			      'ESTADO: INACTIVO', 
			      ASCII escape, ASCII des_neg
		WHEN 'J'
			PRINT ASCII escape, ASCII act_neg,
			      'ESTADO: JUBILADO', 
			      ASCII escape, ASCII des_neg
	END CASE
	LET acum_est = 0

ON EVERY ROW
	NEED 5 LINES

	CALL fl_lee_moneda(r_rol.n30_mon_sueldo) RETURNING r_g13.*
	CALL fl_lee_cargo(vg_codcia, r_rol.n30_cod_cargo) RETURNING r_g35.*
	CALL fl_lee_seguros(r_rol.n30_cod_seguro) RETURNING r_n13.*
	CALL fl_lee_cod_sectorial(r_rol.n30_sectorial) RETURNING r_n17.*
	LET sueldo = r_rol.n30_sueldo_mes
	IF r_rol.n30_estado = 'J' THEN
		LET sueldo = r_rol.n30_val_jub_pat
	END IF
	LET fecha = r_rol.n30_fecha_ing
	IF r_rol.n30_fecha_reing IS NOT NULL THEN
		LET fecha = r_rol.n30_fecha_reing
	END IF
	LET sub_activ = r_rol.n30_sub_activ 
	IF r_rol.n30_sub_activ IS NULL THEN
		LET sub_activ = ' '
	END IF
	CASE r_rol.n30_tipo_doc_id
		WHEN 'C'
			LET ced_pas = 'CED. '
		WHEN 'P'
			LET ced_pas = 'PAS. '
	END CASE

	LET acum_depto = acum_depto + sueldo
	LET acum_est = acum_est + sueldo

	PRINT COLUMN 002, r_rol.n30_cod_trab	USING '####',
	      COLUMN 007, r_rol.n30_nombres	CLIPPED,
	      COLUMN 054, r_g35.g35_nombre	CLIPPED,
	      COLUMN 086, r_g13.g13_simbolo, sueldo USING '#,###,###,##&.##',
	      COLUMN 111, fecha USING 'dd-mm-yyyy',
	      COLUMN 127, r_rol.n30_fecha_sal	USING 'dd-mm-yyyy',
	      COLUMN 139, sub_activ		CLIPPED,
	      COLUMN 154, ced_pas, r_rol.n30_num_doc_id,
	      COLUMN 176, r_n13.n13_descripcion[1, 20],
	      COLUMN 198, r_n13.n13_porc_trab	USING '#&.##',
	      COLUMN 205, r_rol.n30_carnet_seg,
	      COLUMN 222, r_n17.n17_sectorial,
	      COLUMN 234, r_n17.n17_descripcion

AFTER GROUP OF r_rol.n30_cod_depto
	NEED 4 LINES
	PRINT COLUMN 90,  '----------------'
        PRINT COLUMN 66,  'TOTAL POR DEPARTAMENTO: ', 
			acum_depto USING '#,###,###,##&.##'

AFTER GROUP OF r_rol.n30_estado
	NEED 2 LINES
	PRINT COLUMN 90,  '----------------'
        PRINT COLUMN 80,  'SUBTOTAL: ', acum_est USING '#,###,###,##&.##'

END REPORT



REPORT report_roles_parte2(r_rol, g34_nombre)
DEFINE r_rol		RECORD LIKE rolt030.*
DEFINE g34_nombre	LIKE gent034.g34_nombre

DEFINE r_g08		RECORD LIKE gent008.*

DEFINE tipo_trab	VARCHAR(15)
DEFINE tipo_contr	VARCHAR(15)
DEFINE tipo_rol		VARCHAR(15)
DEFINE tipo_pago	VARCHAR(15)
DEFINE tipo_cta		VARCHAR(15)

DEFINE usuario          VARCHAR(19,15)
DEFINE titulo		VARCHAR(80)
DEFINE modulo		VARCHAR(40)
DEFINE i, long          SMALLINT

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
	LET act_dob1	= 87		# Activar Doble Ancho (inicio)
	LET act_dob2	= 49		# Activar Doble Ancho (final)
	LET des_dob	= 48		# Desactivar Doble Ancho

--	print '&k2S' 		-- Letra condensada

        LET modulo  = "MODULO: NOMINA"
        LET long    = LENGTH(modulo)
        LET usuario = 'USUARIO: ', vg_usuario
        CALL fl_justifica_titulo('D', usuario, 19) RETURNING usuario
        CALL fl_justifica_titulo('C', 'LISTADO DE TRABAJADORES - SECCION SEGUNDA', 80)
                RETURNING titulo
                                                                                
        --PRINT '^[@'
        print ASCII escape;
        print ASCII act_comp;
        print ASCII escape;
	print ASCII act_10cpi

	SKIP 1 LINES
        PRINT COLUMN 1, rm_cia.g01_razonsocial,
              COLUMN 214, "PAGINA: ", PAGENO USING "&&&"
        PRINT COLUMN 1, modulo CLIPPED,
              COLUMN 50, titulo CLIPPED,
              COLUMN 218, UPSHIFT(vg_proceso)
                                                                                
        SKIP 1 LINES
        PRINT COLUMN 01, "Fecha de Impresión: ", TODAY USING "dd-mm-yyyy",
                         1 SPACES, TIME,
              COLUMN 210, fl_justifica_titulo('D', usuario, 15)
        SKIP 1 LINES

	PRINT COLUMN 02,  "COD.",
	      COLUMN 08,  "NOMBRES",
	      COLUMN 55,  "TIPO TRABAJADOR",
	      COLUMN 72,  "TIPO CONTRATO",
	      COLUMN 87,  "FREC. PAGO",
	      COLUMN 99,  "TIPO PAGO",
	      COLUMN 114, "BANCO",
	      COLUMN 146, "CTA. EMPRESA",
	      COLUMN 163, "CTA. TRABAJADOR",
	      COLUMN 192, "DSCT. SEGURO",
	      COLUMN 206, "DSCT. IMPUESTOS"

	PRINT COLUMN 01,  "-------",
	      COLUMN 08,  "-----------------------------------------------",
	      COLUMN 55,  "-----------------",
	      COLUMN 72,  "---------------",
	      COLUMN 87,  "------------",
	      COLUMN 99,  "---------------",
	      COLUMN 114, "--------------------------------",
	      COLUMN 146, "-----------------",
	      COLUMN 163, "-----------------------------",
	      COLUMN 192, "--------------",
	      COLUMN 206, "-----------------"

ON EVERY ROW
	NEED 2 LINES

	CALL fl_lee_banco_general(r_rol.n30_bco_empresa) RETURNING r_g08.*
	CASE r_rol.n30_tipo_trab
		WHEN 'N'
			LET tipo_trab = 'NORMAL'
		WHEN 'E'
			LET tipo_trab = 'EJECUTIVO'
	END CASE
	CASE r_rol.n30_tipo_contr
		WHEN 'H'
			LET tipo_contr = 'POR HORA'
		WHEN 'F'
			LET tipo_contr = 'FIJO'
		WHEN 'E'
			LET tipo_contr = 'EVENTUAL'
	END CASE
	CASE r_rol.n30_tipo_rol
		WHEN 'S'
			LET tipo_rol = 'SEMANAL'
		WHEN 'Q'
			LET tipo_rol = 'QUINCENAL'
		WHEN 'M'
			LET tipo_rol = 'MENSUAL'
	END CASE
	CASE r_rol.n30_tipo_pago
		WHEN 'E'
			LET tipo_pago = 'EFECTIVO'
		WHEN 'T'
			LET tipo_pago = 'TRANSFERENCIA'
		WHEN 'C'
			LET tipo_pago = 'CHEQUE'
	END CASE
	LET tipo_cta = '         '
	IF r_rol.n30_tipo_cta_tra IS NOT NULL THEN
		CASE r_rol.n30_tipo_cta_tra
			WHEN 'A'
				LET tipo_cta = 'CTA. AHO.'
			WHEN 'C'
				LET tipo_cta = 'CTA. CTE.'
		END CASE
	END IF
	IF r_g08.g08_nombre IS NULL THEN
		LET r_g08.g08_nombre = ' '
	END IF
	IF r_rol.n30_cta_empresa IS NULL THEN
		LET r_rol.n30_cta_empresa = ' '
	END IF
	IF r_rol.n30_cta_trabaj IS NULL THEN
		LET r_rol.n30_cta_trabaj = ' '
	END IF

	PRINT COLUMN 02,  r_rol.n30_cod_trab USING '####',
	      COLUMN 08,  r_rol.n30_nombres CLIPPED,
	      COLUMN 55,  tipo_trab CLIPPED,
	      COLUMN 72,  tipo_contr CLIPPED,
	      COLUMN 87,  tipo_rol CLIPPED,
	      COLUMN 99,  tipo_pago CLIPPED,
	      COLUMN 114, r_g08.g08_nombre CLIPPED,
	      COLUMN 146, r_rol.n30_cta_empresa CLIPPED, 
	      COLUMN 163, tipo_cta, ' # ', r_rol.n30_cta_trabaj CLIPPED, 
	      COLUMN 198, r_rol.n30_desc_seguro, 
	      COLUMN 213, r_rol.n30_desc_impto 

BEFORE GROUP OF r_rol.n30_cod_depto
	NEED 3 LINES

	SKIP 1 LINES
	PRINT ASCII escape, ASCII act_neg, 
              ASCII escape, ASCII act_dob1, ASCII act_dob2,
		'DEPARTAMENTO: ', g34_nombre, 
	      ASCII escape, ASCII act_dob1, ASCII des_dob,
	      ASCII escape, ASCII des_neg

BEFORE GROUP OF r_rol.n30_estado
	NEED 2 LINES
	
	CASE r_rol.n30_estado
		WHEN 'A'
			PRINT ASCII escape, ASCII act_neg,
			      'ESTADO: ACTIVO', 
			      ASCII escape, ASCII des_neg
		WHEN 'I'
			PRINT ASCII escape, ASCII act_neg,
			      'ESTADO: INACTIVO', 
			      ASCII escape, ASCII des_neg
		WHEN 'J'
			PRINT ASCII escape, ASCII act_neg,
			      'ESTADO: JUBILADO', 
			      ASCII escape, ASCII des_neg
	END CASE

END REPORT



FUNCTION filtrar_datos_empleado()
DEFINE resp		CHAR(6)
DEFINE r_dep		RECORD LIKE gent034.*
DEFINE codd_aux         LIKE gent034.g34_cod_depto
DEFINE nomd_aux         LIKE gent034.g34_nombre

INITIALIZE rm_par.* TO NULL

INPUT BY NAME rm_par.* WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
        	IF field_touched(rm_par.*) THEN
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
		IF infield(n30_cod_depto) THEN
                        CALL fl_ayuda_departamentos(vg_codcia)
                                RETURNING codd_aux, nomd_aux
                        LET int_flag = 0
                        IF codd_aux IS NOT NULL THEN
				LET rm_par.n30_cod_depto = codd_aux
                                DISPLAY BY NAME rm_par.n30_cod_depto
                                DISPLAY nomd_aux TO tit_departamento
                        END IF
                END IF
	AFTER FIELD n30_estado
		CALL muestra_estado()
	AFTER FIELD n30_cod_depto
                IF rm_par.n30_cod_depto IS NOT NULL THEN
                        CALL fl_lee_departamento(vg_codcia,rm_par.n30_cod_depto)
                                RETURNING r_dep.*
                        IF r_dep.g34_compania IS NULL  THEN
                                CALL fgl_winmessage(vg_producto,'Departamento no existe','exclamation')
                                NEXT FIELD n30_cod_depto
                        END IF
                        DISPLAY r_dep.g34_nombre TO tit_departamento
		ELSE
			CLEAR tit_departamento
                END IF
END INPUT

END FUNCTION



FUNCTION muestra_estado()

IF rm_par.n30_estado = 'A' THEN
	LET rm_par.n_estado = 'ACTIVO'
END IF
IF rm_par.n30_estado = 'I' THEN
	LET rm_par.n_estado = 'INACTIVO'
END IF
IF rm_par.n30_estado = 'J' THEN
	LET rm_par.n_estado = 'JUBILADO'
END IF
DISPLAY BY NAME rm_par.n30_estado, rm_par.n_estado

END FUNCTION



FUNCTION valida_rango_fechas(fec_ini, fec_fin)
DEFINE fec_ini		DATE
DEFINE fec_fin		DATE

IF fec_ini IS NULL AND fec_fin IS NULL THEN
	RETURN 1
END IF

IF (fec_ini IS NOT NULL OR fec_fin IS NOT NULL) AND
   (fec_ini IS NULL OR fec_fin IS NULL)
THEN
	CALL fl_mostrar_mensaje('Debe ingresar tanto fecha de inicio como fecha final.', 'exclamation')
	RETURN 0
END IF

IF fec_ini > fec_fin THEN
	CALL fl_mostrar_mensaje('La fecha inicial debe ser menor o igual a la fecha final.', 'exclamation')
	RETURN 0
END IF

RETURN 1

END FUNCTION



FUNCTION que_imprimo()
DEFINE resp		CHAR(6)

OPEN WINDOW wf2 AT 3,2 WITH 7 ROWS, 80 COLUMNS
    ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE LAST - 1,BORDER,
	      MESSAGE LINE LAST - 1)
OPTIONS INPUT WRAP,
	ACCEPT KEY	F12
OPEN FORM f_rol2 FROM "../forms/rolf400_2"
DISPLAY FORM f_rol2
	
LET vm_imprimir = '0'
INPUT BY NAME vm_imprimir WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
        	IF field_touched(vm_imprimir) THEN
               		LET int_flag = 0
			CALL fl_mensaje_abandonar_proceso()
                		RETURNING resp
              		IF resp = 'Yes' THEN
				LET int_flag = 1
                       		CLEAR FORM
                       		EXIT INPUT
                	END IF
		ELSE
			EXIT INPUT
		END IF
END INPUT
IF int_flag THEN
	CLOSE WINDOW wf2
	RETURN
END IF

CLOSE WINDOW wf2

END FUNCTION
