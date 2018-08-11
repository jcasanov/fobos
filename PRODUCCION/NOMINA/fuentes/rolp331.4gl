------------------------------------------------------------------------------
-- Titulo           : rolp331.4gl - Estado de cuenta Club             
-- Elaboracion      : 29-oct-2003
-- Autor            : JCM
-- Formato Ejecucion: fglrun rolp331 base módulo compañía
-- Ultima Correccion: 
-- Motivo Correccion: 
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE rm_n00		RECORD LIKE rolt000.*

DEFINE vm_filas_pant	INTEGER
DEFINE vm_numelm	INTEGER
DEFINE vm_maxelm	INTEGER
DEFINE vm_prest ARRAY[1000] OF LIKE rolt064.n64_num_prest 
DEFINE rm_scr ARRAY[1000] OF RECORD 
	n64_fecha		DATE,	
	n64_cod_trab		LIKE rolt064.n64_cod_trab,
	n_trab			LIKE rolt030.n30_nombres,
	valor			LIKE rolt064.n64_val_prest,
	saldo			LIKE rolt064.n64_val_prest
END RECORD	
DEFINE rm_par		RECORD
	cod_trab		LIKE rolt030.n30_cod_trab,
	nom_trab		LIKE rolt030.n30_nombres,
	flag_saldo		CHAR(1),
	val_filtro		DECIMAL(11,2),
	fecha_ini		DATE,
	fecha_fin		DATE			
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
LET vg_proceso = 'rolp331'
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
OPEN FORM f_rol FROM "../forms/rolf331_1"
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

WHILE NOT salir 
	CLEAR FORM
	CALL mostrar_botones()
	LET int_flag = 0
	LET salir = control_consulta()
END WHILE

END FUNCTION



FUNCTION mostrar_botones()
                                                                                
DISPLAY 'Fecha'                 TO bt_fecha
DISPLAY 'Cod.'                  TO bt_cod_trab
DISPLAY 'Nombre Trabajador'     TO bt_n_trab
DISPLAY 'Valor'                 TO bt_valor
DISPLAY 'Saldo'                 TO bt_saldo
                                                                                
END FUNCTION
               


FUNCTION control_consulta()
DEFINE resp		CHAR(6)
DEFINE r_n30		RECORD LIKE rolt030.*

DEFINE query		VARCHAR(500)

INITIALIZE rm_par.* TO NULL
LET rm_par.flag_saldo = 'S'
LET rm_par.val_filtro = 0.01
INPUT BY NAME rm_par.* WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
        	IF field_touched(rm_par.cod_trab, rm_par.flag_saldo, 
				 rm_par.val_filtro, rm_par.fecha_ini,
				 rm_par.fecha_fin)			
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
		IF infield(cod_trab) THEN
                        CALL fl_ayuda_codigo_empleado(vg_codcia)
                                RETURNING r_n30.n30_cod_trab, 
					  r_n30.n30_nombres
                        LET int_flag = 0
                        IF r_n30.n30_cod_trab IS NOT NULL THEN
				LET rm_par.cod_trab = r_n30.n30_cod_trab
				LET rm_par.nom_trab = r_n30.n30_nombres
				DISPLAY BY NAME rm_par.*
                        END IF
                END IF
	BEFORE FIELD val_filtro
		IF rm_par.flag_saldo = 'T' THEN
			NEXT FIELD NEXT
		END IF
	AFTER FIELD cod_trab
		IF rm_par.cod_trab IS NOT NULL THEN
			CALL fl_lee_trabajador_roles(vg_codcia, rm_par.cod_trab)
				RETURNING r_n30.*
			IF r_n30.n30_compania IS NULL THEN
				CALL fl_mostrar_mensaje('Trabajador no existe.',
						 	'exclamation')
				NEXT FIELD cod_trab
			END IF
			IF r_n30.n30_estado = 'I' THEN
				CALL fl_mostrar_mensaje('Trabajador esta inactivo.',
						 	'exclamation')
				NEXT FIELD cod_trab
			END IF
			LET rm_par.cod_trab = r_n30.n30_cod_trab
			LET rm_par.nom_trab = r_n30.n30_nombres
			DISPLAY BY NAME rm_par.*
		ELSE
			INITIALIZE rm_par.nom_trab TO NULL 
			DISPLAY BY NAME rm_par.*
		END IF
	AFTER FIELD flag_saldo
		CASE rm_par.flag_saldo 
			WHEN 'S'
				IF rm_par.val_filtro IS NULL THEN
					LET rm_par.val_filtro = 0.01
				END IF
		        WHEN 'T'      
				INITIALIZE rm_par.val_filtro TO NULL
		END CASE
		DISPLAY BY NAME rm_par.*
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
		IF rm_par.flag_saldo = 'S' AND rm_par.val_filtro IS NULL THEN
			CONTINUE INPUT
		END IF 
		IF rm_par.flag_saldo = 'T' AND rm_par.fecha_ini IS NULL THEN
			CALL fl_mostrar_mensaje('Debe ingresar un rango de fechas.', 
						'exclamation')
			CONTINUE INPUT
		END IF 
END INPUT
IF int_flag THEN
	RETURN 1 
END IF

LET query = 'SELECT n64_compania, n64_cod_trab, n64_num_prest, ',
            'n64_fecha as fecha, ',
            '(n64_val_prest + n64_val_interes) as valor, ',
            '(n64_val_prest + n64_val_interes - n64_descontado) as saldo ',
	    ' FROM rolt064 ',
	    ' WHERE n64_compania = ', vg_codcia 
IF rm_par.cod_trab IS NOT NULL THEN
	LET query = query CLIPPED, ' AND n64_cod_trab = ', rm_par.cod_trab 
END IF 
CASE rm_par.flag_saldo 
	WHEN 'S' 
		LET query = query CLIPPED, ' AND n64_estado = "A" '
	WHEN 'T'
		LET query = query CLIPPED, ' AND n64_estado   IN ("A", "P") '
END CASE
LET query = query CLIPPED, ' INTO TEMP te_prest; '

PREPARE stmnt FROM query
EXECUTE stmnt

CALL cargar_detalle()

DROP TABLE te_prest;

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

DEFINE tot_valor		LIKE rolt064.n64_val_prest
DEFINE tot_saldo		LIKE rolt064.n64_val_prest

FOR columna_1 = 1 TO 10 
	LET orden[columna_1] = 'ASC' 
END FOR

LET columna_1 = 1 
LET columna_2 = 3

LET salir = 0
WHILE NOT salir
	LET query = 'SELECT fecha, n64_cod_trab, n30_nombres, valor, saldo, ', 
	            'n64_num_prest ',
		    'FROM te_prest, rolt030 ',
		    'WHERE '
	IF rm_par.fecha_ini IS NOT NULL THEN
		LET query = query CLIPPED, ' fecha BETWEEN "', rm_par.fecha_ini,
 					   '" AND "', rm_par.fecha_fin, '" AND '
	END IF
	IF rm_par.val_filtro IS NOT NULL THEN
		LET query = query CLIPPED, ' saldo >= ', rm_par.val_filtro, 
					   ' AND '
	END IF
	LET query = query CLIPPED, '     n30_compania = n64_compania ',
			           ' AND n30_cod_trab = n64_cod_trab ',
                   		   ' AND n30_estado   = "A" ',
			' ORDER BY ', columna_1, ' ', orden[columna_1], ', ',
				      columna_2, ' ', orden[columna_2]

	PREPARE cons FROM query
	DECLARE q_det CURSOR FOR cons

	LET tot_valor = 0
	LET tot_saldo = 0

	LET vm_numelm = 1
	FOREACH q_det INTO rm_scr[vm_numelm].*, vm_prest[vm_numelm]
		LET tot_valor = tot_valor + rm_scr[vm_numelm].valor  
		LET tot_saldo = tot_saldo + rm_scr[vm_numelm].saldo  
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

	DISPLAY BY NAME tot_valor, tot_saldo

	CALL set_count(vm_numelm)
	DISPLAY ARRAY rm_scr TO ra_scr.*
		BEFORE DISPLAY
			CALL dialog.keysetlabel('F5', 'Ver Prestamo')
		ON KEY(INTERRUPT)
			LET salir = 1
			EXIT DISPLAY
		ON KEY(F5)
			LET i = arr_curr()
			CALL mostrar_prestamo(vm_prest[i])
			LET int_flag = 0
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



FUNCTION mostrar_prestamo(num_prest)
DEFINE comando		VARCHAR(255)
DEFINE num_prest	LIKE rolt064.n64_num_prest

LET comando = 'fglrun rolp231 ', vg_base, ' ', vg_modulo, ' ', vg_codcia,
	      ' ', num_prest

RUN comando

END FUNCTION
