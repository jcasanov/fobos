------------------------------------------------------------------------------
-- Titulo           : rolp332.4gl - Estado de cuenta Club             
-- Elaboracion      : 31-oct-2003
-- Autor            : JCM
-- Formato Ejecucion: fglrun rolp332 base módulo compañía
-- Ultima Correccion: 
-- Motivo Correccion: 
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE rm_n00		RECORD LIKE rolt000.*

DEFINE vm_filas_pant	INTEGER
DEFINE vm_numelm	INTEGER
DEFINE vm_maxelm	INTEGER
DEFINE rm_scr ARRAY[1000] OF RECORD 
	n68_fecha		LIKE rolt068.n68_fecha,	
	n68_referencia		LIKE rolt068.n68_referencia,
	n68_beneficiario	LIKE rolt068.n68_beneficiario,
	n68_num_cheque		LIKE rolt068.n68_num_cheque,
	n68_valor		LIKE rolt068.n68_valor
END RECORD	
DEFINE rm_par		RECORD
	n68_banco		LIKE rolt068.n68_banco,
	g08_nombre		LIKE gent008.g08_nombre,	
	n68_numero_cta		LIKE rolt068.n68_numero_cta,
	fecha_ini		DATE,
	fecha_fin		DATE,			
	saldo_ini_al		DATE,
	saldo_fin_al		DATE,
	saldo_ini		DECIMAL(12,2)
END RECORD



MAIN

DEFER QUIT 
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/errores')
CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 3 THEN          -- Validar # parámetros correcto
	CALL fgl_winmessage(vg_producto, 'Número de parámetros incorrecto', 'stop')
	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_proceso = 'rolp332'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
--#CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL control_master()

END MAIN



FUNCTION control_master()

DEFINE salir		SMALLINT
DEFINE r_n01		RECORD LIKE rolt001.*

CALL fl_nivel_isolation()
LET vm_maxelm	= 1000

OPEN WINDOW wf AT 3,2 WITH 22 ROWS, 80 COLUMNS
    ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE FIRST,BORDER,
	      MESSAGE LINE LAST - 2)
OPTIONS INPUT WRAP,
	ACCEPT KEY	F12
OPEN FORM f_rol FROM "../forms/rolf332_1"
DISPLAY FORM f_rol

INITIALIZE rm_n00.* TO NULL
CALL fl_lee_parametro_general_roles() RETURNING rm_n00.*
IF rm_n00.n00_moneda_pago IS NULL THEN
	CALL fl_mostrar_mensaje('No se han configurado parametros generales de roles.', 'stop')
	EXIT PROGRAM
END IF

CALL fl_lee_compania_roles(vg_codcia) RETURNING r_n01.*
IF r_n01.n01_compania IS NULL THEN
        CALL fgl_winmessage(vg_producto,
                'No existe configuración para esta compañía.',
                'stop')
        EXIT PROGRAM
END IF
IF r_n01.n01_estado <> 'A' THEN
        CALL fgl_winmessage(vg_producto, 'Compañía no está activa.', 'stop')
        EXIT PROGRAM
END IF

CREATE TEMP TABLE te_movcta(
	cod_tran	CHAR(2),
	fecha		DATE,
	referencia	VARCHAR(60),
	beneficiario	VARCHAR(60),
	cheque		INTEGER,
	valor		DECIMAL(12,2),
	saldo		DECIMAL(12,2),
	fecing		DATETIME YEAR TO SECOND
);

WHILE NOT salir 
	CLEAR FORM
	CALL mostrar_botones()
	LET int_flag = 0
	LET salir = control_consulta()
END WHILE

END FUNCTION



FUNCTION mostrar_botones()
                                                                                
DISPLAY 'Fecha'                 TO bt_fecha
DISPLAY 'Referencia'            TO bt_referen
DISPLAY 'Beneficiario'	     	TO bt_benef
DISPLAY 'Chq.'                  TO bt_cheque
DISPLAY 'Valor'                 TO bt_valor
                                                                                
END FUNCTION
               


FUNCTION control_consulta()
DEFINE resp		CHAR(6)
DEFINE cuantas_cuentas	SMALLINT
DEFINE r_n30		RECORD LIKE rolt030.*
DEFINE fec_ing		DATETIME YEAR TO SECOND
DEFINE query		VARCHAR(500)
DEFINE r_g09		RECORD LIKE gent009.*
DEFINE r_b10		RECORD LIKE ctbt010.*

SELECT COUNT(DISTINCT n69_numero_cta) INTO cuantas_cuentas 
	FROM rolt069 WHERE n69_compania = vg_codcia

INITIALIZE rm_par.* TO NULL

IF cuantas_cuentas = 0 THEN
	CALL fl_mostrar_mensaje('No se han realizados movimientos en la cuenta.','stop')
	RETURN 1
END IF

IF cuantas_cuentas = 1 THEN
	DECLARE q_cta CURSOR FOR 
		SELECT n69_banco, g08_nombre, n69_numero_cta
			FROM rolt069, gent008
			WHERE n69_compania = vg_codcia
			  AND g08_banco    = n69_banco

	OPEN  q_cta
	FETCH q_cta INTO rm_par.n68_banco, rm_par.g08_nombre, 
			 rm_par.n68_numero_cta
	CLOSE q_cta
	FREE  q_cta
END IF

IF cuantas_cuentas > 1 THEN
	SELECT n60_banco, g08_nombre, n60_numero_cta
	        INTO rm_par.n68_banco, rm_par.g08_nombre, rm_par.n68_numero_cta
		FROM rolt060, gent008
		WHERE n60_compania = vg_codcia
		  AND g08_banco    = n60_banco
END IF

INPUT BY NAME rm_par.* WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
        	IF field_touched(rm_par.n68_banco, rm_par.n68_numero_cta, 
				 rm_par.fecha_ini, rm_par.fecha_fin)
        	THEN
               		LET int_flag = 0
			CALL fl_mensaje_abandonar_proceso()
                		RETURNING resp
              		IF resp = 'Yes' THEN
				LET int_flag = 1
				EXIT INPUT
                	END IF
		ELSE
			EXIT INPUT
		END IF
	ON KEY(F2)
		IF infield(n68_numero_cta) THEN
                        CALL fl_ayuda_cuenta_banco_club(vg_codcia)
                                RETURNING rm_par.n68_banco, 
					  rm_par.g08_nombre,
					  rm_par.n68_numero_cta
                        LET int_flag = 0
                        IF rm_par.n68_banco IS NOT NULL THEN
				DISPLAY BY NAME rm_par.*
                        END IF
                END IF
	BEFORE FIELD n68_numero_cta
		IF cuantas_cuentas = 1 THEN
			NEXT FIELD NEXT
		END IF
	AFTER FIELD fecha_ini
		IF rm_par.fecha_ini IS NULL THEN
			INITIALIZE rm_par.fecha_fin TO NULL
			DISPLAY BY NAME rm_par.*
			CONTINUE INPUT
		END IF
		IF rm_par.fecha_fin IS NULL THEN
			LET rm_par.fecha_fin = TODAY
			DISPLAY BY NAME rm_par.*
		END IF
		IF DAY(rm_par.fecha_ini) <> 1 THEN
			CALL fl_mostrar_mensaje('La fecha inicial debe ser el primero del mes.', 'exclamation')
			NEXT FIELD fecha_ini
		END IF
	AFTER FIELD n68_numero_cta
		IF rm_par.n68_numero_cta IS NOT NULL THEN
			CALL fl_lee_banco_compania(vg_codcia, rm_par.n68_banco,
							rm_par.n68_numero_cta)
				RETURNING r_g09.*
			IF r_g09.g09_numero_cta IS NULL THEN
				CALL fl_mostrar_mensaje('No existe cuenta en este banco.','exclamation')
				NEXT FIELD n68_numero_cta
			END IF
			IF r_g09.g09_estado = 'B' THEN
				CALL fl_mostrar_mensaje('La cuenta esta bloqueada.','exclamation')
				NEXT FIELD n68_numero_cta
			END IF
			CALL fl_lee_cuenta(r_g09.g09_compania,
						r_g09.g09_aux_cont)
				RETURNING r_b10.*
			IF r_b10.b10_compania IS NULL THEN
				CALL fl_mostrar_mensaje('No se puede escoger una cuenta corriente que no tiene auxiliar contable.', 'exclamation')
				NEXT FIELD n68_numero_cta
			END IF
			IF r_b10.b10_estado <> 'A' THEN
				CALL fl_mostrar_mensaje('El auxiliar contable de esta cuenta bancaria esta con estado bloqueado.', 'exclamation')
				NEXT FIELD n68_numero_cta
			END IF
		END IF
	AFTER INPUT
		IF rm_par.fecha_ini IS NOT NULL AND rm_par.fecha_fin IS NULL
		THEN
			CALL fl_mostrar_mensaje('Debe ingresar una fecha final.', 
						'exclamation')
			CONTINUE INPUT
			
		END IF
		IF rm_par.fecha_ini > rm_par.fecha_fin THEN
			CALL fl_mostrar_mensaje('La fecha final debe ser menor a la fecha inicial.', 'exclamation')
			CONTINUE INPUT
		END IF
		IF rm_par.n68_numero_cta IS NULL THEN
			CALL fl_mostrar_mensaje('Debe ingresar una cuenta.', 'exclamation')
			CONTINUE INPUT
		END IF 
END INPUT
IF int_flag THEN
	RETURN 1 
END IF

LET rm_par.saldo_ini_al = rm_par.fecha_ini - 1
LET rm_par.saldo_fin_al = rm_par.fecha_fin 
LET rm_par.saldo_ini = obtener_saldo_inicial()

DELETE FROM te_movcta;

INSERT INTO te_movcta(cod_tran, fecha, referencia, beneficiario, cheque, valor,
	              saldo, fecing)
SELECT n68_cod_tran,   n68_fecha, n68_referencia, n68_beneficiario, 
       n68_num_cheque, n68_valor, n68_saldo_ant, n68_fecing
	FROM rolt068 
	WHERE n68_compania   = vg_codcia 
	  AND n68_fecha BETWEEN rm_par.fecha_ini AND rm_par.fecha_fin
	  AND n68_banco      = rm_par.n68_banco
	  AND n68_numero_cta = rm_par.n68_numero_cta

UPDATE te_movcta SET valor = valor * (-1) WHERE cod_tran = 'EG'
DECLARE qulo CURSOR FOR SELECT saldo, fecing FROM te_movcta
	ORDER BY 2
OPEN qulo 
FETCH qulo INTO rm_par.saldo_ini, fec_ing

CALL cargar_detalle()

RETURN 0 

END FUNCTION



FUNCTION cargar_detalle()
DEFINE query			VARCHAR(500)
DEFINE orden 			ARRAY[10] OF CHAR(4)
DEFINE col			SMALLINT
DEFINE columna_1		SMALLINT
DEFINE columna_2		SMALLINT

DEFINE i			SMALLINT
DEFINE salir 			SMALLINT
DEFINE cod_tran			CHAR(2)

DEFINE saldo_fin		LIKE rolt069.n69_saldo_ini

FOR columna_1 = 1 TO 10 
	LET orden[columna_1] = 'ASC' 
END FOR

LET columna_1 = 1 
LET columna_2 = 3

LET salir = 0
WHILE NOT salir
	LET query = 'SELECT fecha, referencia, beneficiario, ',
		    '       cheque, valor, cod_tran ', 
		    'FROM te_movcta ',
		    'ORDER BY ', columna_1, ' ', orden[columna_1], ', ',
			         columna_2, ' ', orden[columna_2]

	PREPARE cons FROM query
	DECLARE q_det CURSOR FOR cons

	LET saldo_fin = rm_par.saldo_ini

	LET vm_numelm = 1
	FOREACH q_det INTO rm_scr[vm_numelm].*, cod_tran
		LET saldo_fin = saldo_fin + rm_scr[vm_numelm].n68_valor  
		LET vm_numelm = vm_numelm + 1
		IF vm_numelm > vm_maxelm THEN
			CALL fl_mensaje_arreglo_incompleto()
		END IF
	END FOREACH
	LET vm_numelm = vm_numelm - 1

	IF vm_numelm = 0 THEN
		CALL fl_mensaje_consulta_sin_registros()
		LET salir = 1
		EXIT WHILE
	END IF

	DISPLAY BY NAME rm_par.*
	DISPLAY BY NAME saldo_fin

	CALL set_count(vm_numelm)
	DISPLAY ARRAY rm_scr TO ra_scr.*
		ON KEY(INTERRUPT)
			LET salir = 1
			EXIT DISPLAY
		ON KEY(F15)
			LET col = 1
			EXIT DISPLAY
		ON KEY(F16)
			LET col = 2
			EXIT DISPLAY
		ON KEY(F17)
			LET col = 3
			EXIT DISPLAY
		ON KEY(F18)
			LET col = 4
			EXIT DISPLAY
		ON KEY(F19)
			LET col = 5
			EXIT DISPLAY
	END DISPLAY
	IF int_flag = 1 THEN
		LET int_flag = 0
		RETURN
	END IF
	IF col <> columna_1 THEN
		LET columna_2 = columna_1 
		LET orden[columna_2] = orden[columna_1]
		LET columna_1 = col 
	END IF
	IF orden[columna_1] = 'ASC' THEN
		LET orden[columna_1] = 'DESC'
	ELSE
		LET orden[columna_1] = 'ASC'
	END IF
END WHILE

END FUNCTION



FUNCTION obtener_saldo_inicial()
DEFINE saldo			LIKE rolt069.n69_saldo_ini

	INITIALIZE saldo TO NULL
	SELECT ((n69_saldo_ini + n69_valor_ing) - n69_valor_egr) 
		INTO saldo
		FROM rolt069
		WHERE n69_compania   = vg_codcia
		  AND n69_banco      = rm_par.n68_banco
		  AND n69_numero_cta = rm_par.n68_numero_cta
		  AND n69_anio       = YEAR(rm_par.saldo_ini_al)
		  AND n69_mes        = MONTH(rm_par.saldo_ini_al)

	IF saldo IS NULL THEN
		LET saldo = 0
	END IF

	RETURN saldo
END FUNCTION
