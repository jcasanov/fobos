--------------------------------------------------------------------------------
-- Titulo           : rolp240.4gl - DISTRIBUCION DE INTERESES FONDO DE CESANTIA
-- Elaboracion      : 06-nov-2003
-- Autor            : JCM
-- Formato Ejecucion: fglrun rolp240 BD MODULO COMPANIA 
-- Ultima Correccion:
-- Motivo Correccion: 
--------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE rm_cia		RECORD LIKE rolt001.*
DEFINE rm_par	RECORD 
	n81_num_poliza		LIKE rolt081.n81_num_poliza,
	n81_fec_vcto		LIKE rolt081.n81_fec_vcto,
	cap_poliza		LIKE rolt081.n81_cap_trab,
	n81_porc_int		LIKE rolt081.n81_porc_int,
	n81_val_int		LIKE rolt081.n81_val_int,
	n81_val_dscto		LIKE rolt081.n81_val_dscto
END RECORD
DEFINE vm_cod_trab ARRAY[500]   OF RECORD
	cod_trab 		LIKE rolt030.n30_cod_trab,
	moneda			LIKE rolt030.n30_mon_sueldo,
	cap_trab		LIKE rolt081.n81_cap_trab,
	cap_patr		LIKE rolt081.n81_cap_trab,
	interes			LIKE rolt081.n81_cap_trab,
	dscto			LIKE rolt081.n81_cap_trab
END RECORD
DEFINE rm_scr	ARRAY[500]	OF RECORD
	n30_nombres		LIKE rolt030.n30_nombres,
	capital			LIKE rolt081.n81_cap_trab,
	interes			LIKE rolt081.n81_cap_trab,
	dscto			LIKE rolt081.n81_cap_trab,
	subtotal		LIKE rolt081.n81_cap_trab
END RECORD
DEFINE vm_numelm		SMALLINT
DEFINE vm_maxelm		SMALLINT



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/rolp240.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 3 THEN     -- Validar # parámetros correcto
	--CALL fgl_winmessage(vg_producto,'Número de parámetros incorrecto.','stop')
	CALL fl_mostrar_mensaje('Número de parámetros incorrecto.','stop')
	EXIT PROGRAM
END IF
LET vg_base      = arg_val(1)
LET vg_modulo    = arg_val(2)
LET vg_codcia    = arg_val(3)
LET vg_proceso = 'rolp240'
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

OPEN WINDOW wf AT 3,2 WITH 22 ROWS, 80 COLUMNS
    ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE LAST ,BORDER,
     		MESSAGE LINE LAST - 1)
OPTIONS INPUT WRAP,
	ACCEPT KEY	F12
OPEN FORM f_rol FROM "../forms/rolf240_1"
DISPLAY FORM f_rol

LET vm_maxelm = 500

LET salir = 0
WHILE NOT salir
	CLEAR FORM
	CALL mostrar_botones()
	LET int_flag = 0
	LET salir = control_distribuir()
END WHILE

CLOSE WINDOW wf

END FUNCTION



FUNCTION control_distribuir()
DEFINE r_n81		RECORD LIKE rolt081.*


CALL fl_lee_compania_roles(vg_codcia) RETURNING rm_cia.*
IF rm_cia.n01_compania IS NULL THEN
	--CALL fgl_winmessage(vg_producto,'No existe compañía.','stop')
	CALL fl_mostrar_mensaje('No existe compañía.','stop')
	EXIT PROGRAM
END IF

CALL fl_lee_poliza_cesantia_activa(vg_codcia) RETURNING r_n81.*
IF r_n81.n81_compania IS NULL THEN
	CALL fl_mostrar_mensaje('No existe una poliza activa.', 'stop')
	RETURN 1
END IF

IF r_n81.n81_fec_vcto > TODAY THEN
	CALL fl_mostrar_mensaje('La poliza activa aun no ha vencido.', 'stop')
	EXIT PROGRAM
END IF

INITIALIZE rm_par.* TO NULL
LET rm_par.n81_num_poliza = r_n81.n81_num_poliza
LET rm_par.n81_fec_vcto   = r_n81.n81_fec_vcto    
LET rm_par.cap_poliza     = r_n81.n81_cap_trab + r_n81.n81_cap_patr +
                            r_n81.n81_cap_int  + r_n81.n81_cap_dscto
LET rm_par.n81_porc_int   = r_n81.n81_porc_int  

CALL ingresar_valores()
IF int_flag = 1 THEN
	RETURN 1
END IF

CALL carga_trabajadores(r_n81.*)
IF int_flag = 1 THEN
	RETURN 1
END IF

RETURN 0

END FUNCTION



FUNCTION ingresar_valores()
DEFINE resp		CHAR(6)

INPUT BY NAME rm_par.* WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
        	IF field_touched(n81_val_int, n81_val_dscto) THEN
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
	AFTER FIELD n81_val_int
		IF rm_par.n81_val_int IS NULL THEN
			CONTINUE INPUT
		END IF
		IF rm_par.n81_val_int < 0 THEN
			CALL fl_mostrar_mensaje('Valor interes no puede ser negativo.', 'exclamation')
			NEXT FIELD n81_val_int
		END IF
	AFTER FIELD n81_val_dscto
		IF rm_par.n81_val_dscto IS NULL THEN
			CONTINUE INPUT
		END IF
		IF rm_par.n81_val_dscto < 0 THEN
			CALL fl_mostrar_mensaje('Valor descuento no puede ser negativo.', 'exclamation')
			NEXT FIELD n81_val_dscto
		END IF
	AFTER INPUT
		IF rm_par.n81_val_int IS NULL THEN
			CALL fl_mostrar_mensaje('Debe ingresar un valor interes.', 'exclamation')
			NEXT FIELD n81_val_int
		END IF
		IF rm_par.n81_val_dscto IS NULL THEN
			CALL fl_mostrar_mensaje('Valor ingresar un valor descuento.', 'exclamation')
			NEXT FIELD n81_val_dscto
		END IF
END INPUT

END FUNCTION



FUNCTION mostrar_botones()
	
DISPLAY 'Nombre Trabajador'	TO bt_nomtrab
DISPLAY 'Capital'		TO bt_capital
DISPLAY 'Interes'		TO bt_interes
DISPLAY 'Dscto.'		TO bt_dscto
DISPLAY 'Total'			TO bt_subtotal

END FUNCTION



FUNCTION carga_trabajadores(r_n81)
DEFINE r_n80		RECORD LIKE rolt080.*
DEFINE r_n80_1		RECORD LIKE rolt080.*
DEFINE r_n81		RECORD LIKE rolt081.*
DEFINE r_n83		RECORD LIKE rolt083.*

DEFINE tot_capital	LIKE rolt081.n81_cap_trab
DEFINE tot_interes	LIKE rolt081.n81_cap_trab
DEFINE tot_dscto	LIKE rolt081.n81_cap_trab
DEFINE total		LIKE rolt081.n81_cap_trab
DEFINE factor_int	DECIMAL(20,15)
DEFINE factor_dscto	DECIMAL(20,15)

DEFINE i		SMALLINT
DEFINE resp		CHAR(6)

CALL obtener_factores(r_n81.*) RETURNING factor_int, factor_dscto

DECLARE q_trab CURSOR FOR 
	SELECT rolt080.*, n30_nombres, n30_mon_sueldo FROM rolt080, rolt030
		WHERE n80_compania = vg_codcia
	{
		  AND n80_ano      = YEAR(r_n81.n81_fecha_fin) 
		  AND n80_mes      = MONTH(r_n81.n81_fecha_fin) 
	}
	  	  AND n80_ano      = YEAR(r_n81.n81_fec_firma) 
	  	  AND n80_mes      = MONTH(r_n81.n81_fec_firma)
		  AND n30_compania = n80_compania
		  AND n30_cod_trab = n80_cod_trab

LET tot_capital = 0
LET tot_interes = 0
LET tot_dscto   = 0
LET total       = 0
LET vm_numelm = 1
FOREACH q_trab INTO r_n80.*, rm_scr[vm_numelm].n30_nombres, 
		    vm_cod_trab[vm_numelm].moneda
{
	LET rm_scr[vm_numelm].capital = r_n80.n80_sac_trab + r_n80.n80_sac_patr
                                      + r_n80.n80_sac_int  + r_n80.n80_sac_dscto
				      + r_n80.n80_val_retiro
}
	LET rm_scr[vm_numelm].capital = r_n80.n80_san_trab + r_n80.n80_san_patr
                                      + r_n80.n80_sac_int  + r_n80.n80_sac_dscto
				      + r_n80.n80_val_retiro
	LET rm_scr[vm_numelm].interes = factor_int   * rm_scr[vm_numelm].capital
	LET rm_scr[vm_numelm].dscto   = factor_dscto * rm_scr[vm_numelm].capital
	LET rm_scr[vm_numelm].subtotal = rm_scr[vm_numelm].capital +
					 rm_scr[vm_numelm].interes -
					 rm_scr[vm_numelm].dscto

	LET vm_cod_trab[vm_numelm].cod_trab = r_n80.n80_cod_trab
{
	LET vm_cod_trab[vm_numelm].cap_trab = r_n80.n80_sac_trab
	LET vm_cod_trab[vm_numelm].cap_patr = r_n80.n80_sac_patr
}
	LET vm_cod_trab[vm_numelm].cap_trab = r_n80.n80_san_trab +
					      r_n80.n80_val_retiro
	LET vm_cod_trab[vm_numelm].cap_patr = r_n80.n80_san_patr
	LET vm_cod_trab[vm_numelm].interes  = r_n80.n80_sac_int 
	LET vm_cod_trab[vm_numelm].dscto    = r_n80.n80_sac_dscto

	LET tot_capital = tot_capital + rm_scr[vm_numelm].capital
	LET tot_interes = tot_interes + rm_scr[vm_numelm].interes
	LET tot_dscto   = tot_dscto   + rm_scr[vm_numelm].dscto  
	LET total       = total       + rm_scr[vm_numelm].subtotal
	
	LET vm_numelm = vm_numelm + 1
	IF vm_numelm > vm_maxelm THEN
		CALL fl_mensaje_arreglo_incompleto()
		EXIT PROGRAM
	END IF
END FOREACH
LET vm_numelm = vm_numelm - 1

-- Arreglando cualquier descuadre que se presente por calculo
LET rm_scr[vm_numelm].interes = rm_scr[vm_numelm].interes + 
				(rm_par.n81_val_int   - tot_interes)
LET rm_scr[vm_numelm].dscto   = rm_scr[vm_numelm].dscto   + 
				(rm_par.n81_val_dscto - tot_dscto)

-- Actualizo totales
LET tot_interes = tot_interes + (rm_par.n81_val_int   - tot_interes)
LET tot_dscto   = tot_dscto   + (rm_par.n81_val_dscto - tot_dscto)

-- Actualizo subtotal del trabajador y total general 
LET total       = total       - rm_scr[vm_numelm].subtotal
LET rm_scr[vm_numelm].subtotal = rm_scr[vm_numelm].capital +
				 rm_scr[vm_numelm].interes -
				 rm_scr[vm_numelm].dscto
LET total       = total       + rm_scr[vm_numelm].subtotal

DISPLAY BY NAME tot_capital, tot_interes, tot_dscto, total

CALL set_count(vm_numelm)
DISPLAY ARRAY rm_scr TO ra_scr.*
	ON KEY(INTERRUPT)
      		LET int_flag = 0
		CALL fl_mensaje_abandonar_proceso() RETURNING resp
       		IF resp = 'Yes' THEN
			LET int_flag = 1
			EXIT DISPLAY
                END IF
END DISPLAY
IF int_flag = 1 THEN
	RETURN 
END IF


-- Que pasa si no existe el registro en la rolt080

BEGIN WORK

UPDATE rolt081 SET n81_estado     = 'P',
		   n81_fec_distri = TODAY,
		   n81_val_int    = rm_par.n81_val_int,
		   n81_val_dscto  = rm_par.n81_val_dscto
	WHERE n81_compania    = vg_codcia
	  AND n81_num_poliza  = rm_par.n81_num_poliza
  	  AND n81_estado      = 'A'

FOR i = 1 TO vm_numelm
	INITIALIZE r_n80.* TO NULL
	DECLARE q_acum CURSOR FOR
		SELECT * FROM rolt080
			WHERE n80_compania = vg_codcia
			  AND n80_ano      = YEAR(rm_par.n81_fec_vcto)
			  AND n80_mes      = MONTH(rm_par.n81_fec_vcto)
			  AND n80_cod_trab = vm_cod_trab[i].cod_trab  
		FOR UPDATE
	OPEN  q_acum
	FETCH q_acum INTO r_n80.*
	IF r_n80.n80_compania IS NULL THEN
		CALL fl_mostrar_mensaje('No existe registro en la rolt080.', 'stop')
		EXIT PROGRAM
	END IF

	LET r_n80.n80_val_int   = rm_scr[i].interes
	LET r_n80.n80_val_dscto = rm_scr[i].dscto * (-1)
	LET r_n80.n80_sac_int   = r_n80.n80_san_int + rm_scr[i].interes
	LET r_n80.n80_sac_dscto = r_n80.n80_san_dscto + (rm_scr[i].dscto * (-1))

	UPDATE rolt080 SET n80_val_int   = r_n80.n80_val_int,
			   n80_val_dscto = r_n80.n80_val_dscto,
			   n80_sac_int   = r_n80.n80_sac_int,
			   n80_sac_dscto = r_n80.n80_sac_dscto
		WHERE CURRENT OF q_acum
	CLOSE q_acum
	FREE  q_acum

	DECLARE q_acum1 CURSOR FOR
		SELECT * FROM rolt080
			WHERE n80_compania = vg_codcia
			  AND mdy(n80_mes, 1, n80_ano) > rm_par.n81_fec_vcto
			  AND n80_cod_trab = vm_cod_trab[i].cod_trab  
			ORDER BY n80_compania, n80_ano, n80_mes

	FOREACH q_acum1 INTO r_n80_1.* 
		LET r_n80_1.n80_san_int   = r_n80.n80_sac_int
		LET r_n80_1.n80_san_dscto = r_n80.n80_sac_dscto
		LET r_n80_1.n80_sac_int   = r_n80_1.n80_san_int + 
					    r_n80_1.n80_val_int
		LET r_n80_1.n80_sac_dscto = r_n80_1.n80_san_dscto +
					    r_n80_1.n80_val_dscto

		UPDATE rolt080 SET n80_san_int   = r_n80_1.n80_san_int,
				   n80_san_dscto = r_n80_1.n80_san_dscto,
				   n80_sac_int   = r_n80_1.n80_sac_int,
				   n80_sac_dscto = r_n80_1.n80_sac_dscto
			WHERE n80_compania = vg_codcia
			  AND n80_ano      = r_n80_1.n80_ano 
			  AND n80_mes      = r_n80_1.n80_mes 
			  AND n80_cod_trab = vm_cod_trab[i].cod_trab  

		LET r_n80.* = r_n80_1.*
	END FOREACH
	FREE q_acum1
	
	INITIALIZE r_n83.* TO NULL
	LET r_n83.n83_compania   = vg_codcia
	LET r_n83.n83_ano        = YEAR(rm_par.n81_fec_vcto) 
	LET r_n83.n83_mes        = MONTH(rm_par.n81_fec_vcto) 
	LET r_n83.n83_cod_trab   = vm_cod_trab[i].cod_trab
	LET r_n83.n83_num_poliza = rm_par.n81_num_poliza 
	LET r_n83.n83_moneda     = vm_cod_trab[i].moneda
	LET r_n83.n83_paridad    = calcula_paridad(r_n83.n83_moneda,
						   rg_gen.g00_moneda_base)
	LET r_n83.n83_cap_trab   = vm_cod_trab[i].cap_trab 
	LET r_n83.n83_cap_patr   = vm_cod_trab[i].cap_patr 
	LET r_n83.n83_cap_int    = vm_cod_trab[i].interes  
	LET r_n83.n83_cap_dscto  = vm_cod_trab[i].dscto    
	LET r_n83.n83_val_int    = rm_scr[i].interes
	LET r_n83.n83_val_dscto  = rm_scr[i].dscto * (-1)
	INSERT INTO rolt083 VALUES (r_n83.*)

END FOR

COMMIT WORK

CALL fl_mostrar_mensaje('Proceso terminado Ok', 'info')
	
END FUNCTION



FUNCTION obtener_factores(r_n81)
DEFINE r_n81 		RECORD LIKE rolt081.*
DEFINE tot_capital	LIKE rolt081.n81_cap_trab
DEFINE factor_int	DECIMAL(20,15)
DEFINE factor_dscto	DECIMAL(20,15)
define val		decimal(12,2)

SELECT SUM(n80_san_trab + n80_san_patr + n80_sac_int + n80_sac_dscto +
	   n80_val_retiro)
	INTO tot_capital FROM rolt080
	WHERE n80_compania = vg_codcia
	  AND n80_ano      = YEAR(r_n81.n81_fec_firma) 
	  AND n80_mes      = MONTH(r_n81.n81_fec_firma)
{
	  AND n80_ano      = YEAR(r_n81.n81_fecha_fin) 
	  AND n80_mes      = MONTH(r_n81.n81_fecha_fin)
}
IF tot_capital IS NULL OR 
   tot_capital <> (r_n81.n81_cap_trab + r_n81.n81_cap_patr + 
                   r_n81.n81_cap_int  + r_n81.n81_cap_dscto)
THEN
	CALL fl_mostrar_mensaje('El total acumulado de los trabajadores no coincide con el valor de la poliza.', 'stop')
	EXIT PROGRAM
END IF

LET factor_int   = rm_par.n81_val_int   / tot_capital
LET factor_dscto = rm_par.n81_val_dscto / tot_capital

RETURN factor_int, factor_dscto

END FUNCTION



FUNCTION calcula_paridad(moneda_ori, moneda_dest)

DEFINE moneda_ori	LIKE gent013.g13_moneda
DEFINE moneda_dest	LIKE gent013.g13_moneda
DEFINE paridad		LIKE gent014.g14_tasa        

DEFINE r_g14		RECORD LIKE gent014.*

IF moneda_ori = moneda_dest THEN
	LET paridad = 1 
ELSE
	CALL fl_lee_factor_moneda(moneda_ori, moneda_dest) 
		RETURNING r_g14.*
	IF r_g14.g14_serial IS NULL THEN
		CALL fgl_winmessage(vg_producto, 
				    'No existe factor de conversión ' ||
				    'para esta moneda',
				    'exclamation')
		INITIALIZE paridad TO NULL
	ELSE
		LET paridad = r_g14.g14_tasa 
	END IF
END IF

RETURN paridad

END FUNCTION
