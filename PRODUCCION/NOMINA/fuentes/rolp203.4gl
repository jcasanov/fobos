--------------------------------------------------------------------------------
-- Titulo           : rolp203.4gl - Calculo de la liquidacion de roles
-- Elaboracion      : 30-jul-2003
-- Autor            : YEC
-- Formato Ejecucion: fglrun rolp203 base modulo compania [flag] [cod_trab]
-- Ultima Correccion: 
-- Motivo Correccion: 
--------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE rm_n00		RECORD LIKE rolt000.*  
DEFINE rm_n90		RECORD LIKE rolt090.*
DEFINE rm_par		RECORD 
				n32_cod_liqrol	LIKE rolt032.n32_cod_liqrol,
				n_liqrol	LIKE rolt003.n03_nombre,
				n32_fecha_ini	LIKE rolt032.n32_fecha_ini,
				n32_fecha_fin	LIKE rolt032.n32_fecha_fin,
				n32_ano_proceso	LIKE rolt032.n32_ano_proceso,
				n32_mes_proceso	LIKE rolt032.n32_mes_proceso,
				n_mes		VARCHAR(12)
			END RECORD
DEFINE vm_num_liq	SMALLINT
DEFINE vm_cod_trab	LIKE rolt030.n30_cod_trab
DEFINE vm_flag		CHAR(1)



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/rolp203.err')
CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 3 AND num_args() <> 4 AND num_args() <> 5 THEN
	CALL fgl_winmessage(vg_producto, 'Número de parametros incorrecto', 
                            'stop')
	EXIT PROGRAM
END IF
LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_codcia   = arg_val(3)
LET vm_flag 	= arg_val(4)
LET vm_cod_trab = arg_val(5)
LET vg_proceso  = 'rolp203'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	-- Asigna un valor por default a vg_codloc
				-- que luego puede ser reemplazado si se 
                                -- mantiene sin comentario la siguiente linea
CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()

END MAIN



FUNCTION funcion_master()

CALL fl_nivel_isolation()
OPTIONS
	INPUT WRAP,
	ACCEPT KEY F12
OPEN WINDOW w_201 AT 3,2 WITH 13 ROWS, 80 COLUMNS
	ATTRIBUTE(FORM LINE FIRST + 2, COMMENT LINE LAST, MENU LINE FIRST,
		  BORDER, MESSAGE LINE LAST - 2) 
OPEN FORM f_203 FROM '../forms/rolf203_1'
DISPLAY FORM f_203
CALL control_calculo_liquidacion_roles()

END FUNCTION



FUNCTION control_calculo_liquidacion_roles()
DEFINE r_n01		RECORD LIKE rolt001.*  
DEFINE r_n05		RECORD LIKE rolt005.*  
DEFINE r_n03		RECORD LIKE rolt003.*
DEFINE r_n32		RECORD LIKE rolt032.*
DEFINE mensaje		VARCHAR(250)
DEFINE num		SMALLINT
DEFINE resp		CHAR(10)

DEFINE estado		CHAR(1)

CALL fl_lee_parametro_general_roles()  RETURNING rm_n00.*
IF rm_n00.n00_serial IS NULL THEN
	CALL fgl_winmessage(vg_producto,
		'No existe configuración general para este módulo.',
		'stop')
	EXIT PROGRAM
END IF
CALL fl_lee_conf_adic_rol(vg_codcia) RETURNING rm_n90.*
IF rm_n90.n90_compania IS NULL THEN
	CALL fl_mostrar_mensaje('No existe configuracion adicional de nomina en la tabla rolt090.', 'stop')
	EXIT PROGRAM
END IF
INITIALIZE rm_par.* TO NULL
CALL fl_lee_compania_roles(vg_codcia) RETURNING r_n01.*
IF r_n01.n01_compania IS NULL THEN
	CALL fgl_winmessage(vg_producto,
		'No existe configuración para esta compañía.',
		'stop')
	EXIT PROGRAM
END IF
IF r_n01.n01_estado <> 'A' THEN
	CALL fgl_winmessage(vg_producto,
		'Compañía no esta activa.', 'stop')
	EXIT PROGRAM
END IF
CALL verifica_rubros_especiales()
LET rm_par.n32_ano_proceso = r_n01.n01_ano_proceso
LET rm_par.n32_mes_proceso = r_n01.n01_mes_proceso
LET rm_par.n_mes           = 
	fl_justifica_titulo('I', 
		fl_retorna_nombre_mes(rm_par.n32_mes_proceso), 12)
INITIALIZE r_n05.* TO NULL
SELECT * INTO r_n05.* FROM rolt005
	WHERE n05_compania = vg_codcia
	  AND n05_activo   = 'S'
IF r_n05.n05_compania IS NULL THEN
        CALL fl_mostrar_mensaje('No existe una liquidación activa.', 'stop')
	EXIT PROGRAM
END IF

LET estado = 'A'
IF vm_flag = 'F' THEN
	LET estado = 'F'
END IF

INITIALIZE r_n32.* TO NULL
DECLARE q_ultliq CURSOR FOR
	SELECT * FROM rolt032
		WHERE n32_compania = vg_codcia  AND 
		      n32_estado   = estado
		ORDER BY n32_fecha_ini DESC
OPEN q_ultliq 
FETCH q_ultliq INTO r_n32.*
IF r_n32.n32_compania IS NULL THEN
	CALL fl_mostrar_mensaje('No hay novedades de roles generadas en rolt032. Genere novedades primero.', 'stop')
	EXIT PROGRAM
END IF
LET rm_par.n32_cod_liqrol = r_n32.n32_cod_liqrol
LET rm_par.n32_fecha_ini  = r_n32.n32_fecha_ini
LET rm_par.n32_fecha_fin  = r_n32.n32_fecha_fin
IF r_n32.n32_cod_liqrol <> r_n05.n05_proceso THEN
	IF vm_flag <> 'F' AND r_n05.n05_proceso <> 'AF' THEN
		LET mensaje = 'Inconsistencia entre liquidacion de roles ',
			      'activa en rolt032 y rolt005.'
		CALL fl_mostrar_mensaje(mensaje, 'stop')
       		EXIT PROGRAM                                           
	END IF
END IF
CALL fl_lee_proceso_roles(rm_par.n32_cod_liqrol) RETURNING r_n03.*
LET rm_par.n_liqrol = r_n03.n03_nombre
DISPLAY BY NAME rm_par.*
IF num_args() = 3 THEN
	CALL fl_mensaje_seguro_ejecutar_proceso() RETURNING resp
	IF resp <> 'Yes' THEN
		EXIT PROGRAM
	END IF
END IF
BEGIN WORK
CALL calcular_nomina()
COMMIT WORK
LET mensaje = 'Liquidaciones generadas: ', vm_num_liq USING '##&'
IF num_args() <> 5 THEN
	CALL fl_mostrar_mensaje(mensaje, 'info')
END IF

END FUNCTION



FUNCTION calcular_nomina()
DEFINE r_n30, r_n30_aux	RECORD LIKE rolt030.*
DEFINE r_n03		RECORD LIKE rolt003.*
DEFINE r_n06		RECORD LIKE rolt006.*
DEFINE r_n07		RECORD LIKE rolt007.*
DEFINE r_n18		RECORD LIKE rolt018.*
DEFINE r_n32		RECORD LIKE rolt032.*
DEFINE r_n33, r_n33_v	RECORD LIKE rolt033.*
DEFINE r_n13		RECORD LIKE rolt013.*
DEFINE r_n60		RECORD LIKE rolt060.*
DEFINE tot_valor	DECIMAL(12,2)
DEFINE tot_egr		DECIMAL(12,2)
DEFINE tot_ing		DECIMAL(12,2)
DEFINE sobregiro	DECIMAL(12,2)
DEFINE resi_sue		DECIMAL(14,4)
DEFINE mensaje		VARCHAR(200)
DEFINE flag		LIKE rolt033.n33_cant_valor
DEFINE flag_ident	LIKE rolt006.n06_flag_ident
DEFINE rub_vac		LIKE rolt006.n06_cod_rubro
DEFINE rubro		LIKE rolt006.n06_cod_rubro
DEFINE factor_sueldo	DECIMAL(22,15)
DEFINE expr_sql		CHAR(300)
DEFINE dias, dias_ini	SMALLINT

LET vm_num_liq = 0
LET expr_sql = 'SELECT * FROM rolt030 ',
			' WHERE n30_compania = ', vg_codcia,
			'   AND (n30_estado   = "A") ',
			'   OR  (n30_estado     = "I" ',
			'   AND  n30_fecha_sal >= "', rm_par.n32_fecha_ini, '") '
IF num_args() = 5 THEN
	LET expr_sql = expr_sql CLIPPED, ' AND n30_cod_trab = ', vm_cod_trab
END IF
LET expr_sql = expr_sql CLIPPED, ' ORDER BY n30_nombres '
PREPARE trab FROM expr_sql
DECLARE q_trab CURSOR FOR trab
CALL fl_lee_parametros_club_roles(vg_codcia) RETURNING r_n60.*
IF r_n60.n60_compania IS NULL THEN
	LET r_n60.n60_rub_aporte = 0
END IF
FOREACH q_trab INTO r_n30.*
        IF r_n30.n30_fecha_reing IS NULL THEN
		IF r_n30.n30_fecha_sal < rm_par.n32_fecha_ini THEN
			CONTINUE FOREACH
		END IF
	ELSE
	        IF r_n30.n30_fecha_reing > rm_par.n32_fecha_fin THEN
	        	CONTINUE FOREACH                          
	        END IF          
	END IF
	IF r_n30.n30_fecha_ing > rm_par.n32_fecha_fin THEN
		CONTINUE FOREACH                           
        END IF                                             
        --IF r_n30.n30_fecha_reing > rm_par.n32_fecha_fin THEN
        	--CONTINUE FOREACH                          
        --END IF          
        CALL fl_lee_liquidacion_roles(vg_codcia, rm_par.n32_cod_liqrol,
        			rm_par.n32_fecha_ini, rm_par.n32_fecha_fin, 
		        	r_n30.n30_cod_trab)
        	RETURNING r_n32.*
        IF r_n32.n32_compania IS NULL THEN
        	ROLLBACK WORK
        	CALL fl_mostrar_mensaje('No existe novedad en rolt032 '
        			|| 'para trabajador: ' 
        			|| r_n30.n30_cod_trab, 
        			   'stop') 
        	EXIT PROGRAM
        END IF
        IF r_n30.n30_cod_seguro IS NULL OR r_n30.n30_desc_seguro = 'N' THEN
        	LET r_n13.n13_porc_trab = 0
        ELSE
        	CALL fl_lee_seguro_social(r_n30.n30_cod_seguro)
			RETURNING r_n13.*
        	IF r_n13.n13_cod_seguro IS NULL THEN
       			LET r_n13.n13_porc_trab = 0 
       		END IF
       	END IF
	CALL fl_lee_proceso_roles(r_n32.n32_cod_liqrol) RETURNING r_n03.*
	DECLARE q_rub CURSOR FOR 
		SELECT * FROM rolt006 
			WHERE n06_estado    = 'A'
	          	  AND n06_det_tot   IN ('DI','DE')
		  	  AND n06_cod_rubro IN
				(SELECT n11_cod_rubro FROM rolt011
				   	WHERE n11_compania   = vg_codcia
					  AND n11_cod_liqrol =
							rm_par.n32_cod_liqrol)
			ORDER BY n06_det_tot DESC, n06_orden
	FOREACH q_rub INTO r_n06.*
		CALL fl_lee_rubro_liq_trabajador(vg_codcia,    
				rm_par.n32_cod_liqrol,	       
			 	rm_par.n32_fecha_ini,          
			 	rm_par.n32_fecha_fin,          
			 	r_n30.n30_cod_trab,            
			 	r_n06.n06_cod_rubro)           
			RETURNING r_n33.*
		IF r_n33.n33_compania IS NULL THEN                     
			CALL inserta_rubro_trabajador(r_n06.*, r_n32.*)
		END IF                                                 
		IF r_n06.n06_valor_fijo > 0 THEN
			LET r_n33.n33_valor = r_n06.n06_valor_fijo
		END IF
		IF r_n06.n06_flag_ident = 'DV' OR r_n06.n06_flag_ident = 'VV' OR
		   r_n06.n06_flag_ident = 'XV' OR r_n06.n06_flag_ident = 'OV' OR
		   r_n06.n06_flag_ident = 'GV' OR r_n06.n06_flag_ident = 'AG' OR
		   r_n06.n06_flag_ident = 'IV'
		THEN
			CALL calcula_valor_vacaciones(vg_codcia,
						rm_par.n32_cod_liqrol,
						rm_par.n32_fecha_ini,
						rm_par.n32_fecha_fin,
						r_n30.n30_cod_trab,
						r_n06.n06_flag_ident)
                  		RETURNING r_n33.n33_valor
			INITIALIZE rub_vac, r_n33.n33_horas_porc TO NULL
			SELECT n08_rubro_base INTO rub_vac
				FROM rolt008
				WHERE n08_cod_rubro = r_n06.n06_cod_rubro
			IF rub_vac IS NOT NULL THEN
				CALL fl_lee_rubro_liq_trabajador(vg_codcia,
						rm_par.n32_cod_liqrol,
						rm_par.n32_fecha_ini,
						rm_par.n32_fecha_fin,
						r_n30.n30_cod_trab, rub_vac)
					RETURNING r_n33_v.*
				LET r_n33.n33_horas_porc = r_n33_v.n33_valor
			END IF
			UPDATE rolt033
				SET n33_valor      = r_n33.n33_valor,
				    n33_horas_porc = r_n33.n33_horas_porc
				WHERE n33_compania   = vg_codcia
				  AND n33_cod_liqrol = rm_par.n32_cod_liqrol
				  AND n33_fecha_ini  = rm_par.n32_fecha_ini
				  AND n33_fecha_fin  = rm_par.n32_fecha_fin
				  AND n33_cod_trab   = r_n30.n30_cod_trab
				  AND n33_cod_rubro  = r_n06.n06_cod_rubro
			IF r_n06.n06_flag_ident <> 'DV' THEN
				CONTINUE FOREACH
			END IF
			IF r_n33.n33_valor = 0 THEN
				CONTINUE FOREACH
			END IF
		END IF
		IF r_n06.n06_flag_ident = 'DT' OR r_n06.n06_flag_ident = 'DV'
		THEN
			IF r_n06.n06_flag_ident = 'DV' THEN
				SELECT n33_cod_rubro INTO r_n06.n06_cod_rubro
					FROM rolt008, rolt006, rolt033
					WHERE n08_rubro_base =
							r_n06.n06_cod_rubro
					  AND n06_cod_rubro  = n08_cod_rubro
					  AND n06_flag_ident = 'DT'
					  AND n33_compania   = vg_codcia
					  AND n33_cod_liqrol =
							rm_par.n32_cod_liqrol
					  AND n33_fecha_ini  =
							rm_par.n32_fecha_ini
					  AND n33_fecha_fin  =
							rm_par.n32_fecha_fin
					  AND n33_cod_trab   =r_n30.n30_cod_trab
					  AND n33_cod_rubro  = n06_cod_rubro
			END IF
			CASE 
				WHEN r_n03.n03_frecuencia = 'S' 
					LET r_n33.n33_valor =
							rm_n00.n00_dias_semana
				WHEN r_n03.n03_frecuencia = 'Q' 
					LET r_n33.n33_valor =
							rm_n00.n00_dias_mes / 2
				WHEN r_n03.n03_frecuencia = 'M' 
					LET r_n33.n33_valor =
							rm_n00.n00_dias_mes
			END CASE
			IF EXTEND(r_n30.n30_fecha_ing, YEAR TO MONTH) =
			   EXTEND(rm_par.n32_fecha_fin, YEAR TO MONTH) THEN
				LET dias_ini = (rm_par.n32_fecha_fin -
						r_n30.n30_fecha_ing) + 1
				IF dias_ini < r_n33.n33_valor THEN
					LET r_n33.n33_valor = dias_ini
				END IF
				IF r_n33.n33_valor = 0 THEN
					LET r_n33.n33_valor = 1
				END IF
			END IF
			IF EXTEND(r_n30.n30_fecha_reing, YEAR TO MONTH) =
			   EXTEND(rm_par.n32_fecha_fin, YEAR TO MONTH) THEN
				LET dias_ini = (rm_par.n32_fecha_fin -
						r_n30.n30_fecha_reing) + 1
				IF dias_ini < r_n33.n33_valor THEN
					LET r_n33.n33_valor = dias_ini
				END IF
				IF r_n33.n33_valor = 0 THEN
					LET r_n33.n33_valor = 1
				END IF
			END IF
			IF EXTEND(r_n30.n30_fecha_sal, YEAR TO MONTH) =
			   EXTEND(rm_par.n32_fecha_fin, YEAR TO MONTH)
			THEN
				IF EXTEND(r_n30.n30_fecha_sal, MONTH TO DAY)
					<> EXTEND(MDY(01, 03,
						YEAR(r_n30.n30_fecha_sal))
						- 1 UNITS DAY, MONTH TO DAY)
				THEN
					LET dias_ini = (r_n30.n30_fecha_sal -
						rm_par.n32_fecha_ini) + 1
					IF dias_ini < r_n33.n33_valor THEN
						LET r_n33.n33_valor = dias_ini
					END IF
					IF r_n33.n33_valor = 0 THEN
						LET r_n33.n33_valor = 1
					END IF
				END IF
			END IF
			CALL retorna_suma_valor_rubros_base(
						r_n06.n06_cod_rubro, 
                        			vg_codcia,
                        		   	rm_par.n32_cod_liqrol,
                        		   	rm_par.n32_fecha_ini,
                        		   	rm_par.n32_fecha_fin,
                        		   	r_n30.n30_cod_trab, 0)
                  		RETURNING tot_valor, flag
			LET r_n33.n33_valor = r_n33.n33_valor - tot_valor
			IF r_n33.n33_valor < 0 THEN
				LET r_n33.n33_valor = 0
			END IF
			UPDATE rolt032 SET n32_dias_trab = r_n33.n33_valor
				WHERE n32_compania   = r_n32.n32_compania AND 
                                      n32_cod_liqrol = r_n32.n32_cod_liqrol AND 
                                      n32_fecha_ini  = r_n32.n32_fecha_ini AND
                                      n32_fecha_fin  = r_n32.n32_fecha_fin AND
                                      n32_cod_trab   = r_n32.n32_cod_trab
			UPDATE rolt033
				SET n33_valor = r_n33.n33_valor
				WHERE n33_compania   = r_n32.n32_compania
				  AND n33_cod_liqrol = r_n32.n32_cod_liqrol
				  AND n33_fecha_ini  = r_n32.n32_fecha_ini
				  AND n33_fecha_fin  = r_n32.n32_fecha_fin
				  AND n33_cod_trab   = r_n32.n32_cod_trab
				  AND n33_cod_rubro  = r_n06.n06_cod_rubro
			CONTINUE FOREACH
		END IF
		IF r_n06.n06_flag_ident = 'DF' THEN
			UPDATE rolt032 SET n32_dias_falt = r_n33.n33_valor
				WHERE n32_compania   = r_n32.n32_compania AND 
                                      n32_cod_liqrol = r_n32.n32_cod_liqrol AND 
                                      n32_fecha_ini  = r_n32.n32_fecha_ini AND
                                      n32_fecha_fin  = r_n32.n32_fecha_fin AND
                                      n32_cod_trab   = r_n32.n32_cod_trab
			CONTINUE FOREACH
		END IF
		IF r_n06.n06_calculo = 'N' AND r_n06.n06_ing_usuario = 'S' --AND
		{--
		   (r_n06.n06_flag_ident <> 'DV' OR
		    r_n06.n06_flag_ident <> 'VV' OR
		    r_n06.n06_flag_ident <> 'XV')
		--}
		THEN
			CONTINUE FOREACH
		END IF
		CALL fl_lee_rubro_que_se_calcula(r_n06.n06_cod_rubro)
			RETURNING r_n07.*
		IF r_n07.n07_cod_rubro IS NULL THEN
			LET r_n07.n07_factor = 1
		END IF
		INITIALIZE flag_ident TO NULL
		SELECT UNIQUE n06_flag_ident INTO flag_ident
			FROM rolt006, rolt008
			WHERE n06_flag_ident = r_n06.n06_flag_ident
			  AND n06_cod_rubro  = n08_cod_rubro 
		IF flag_ident IS NOT NULL THEN
		{--
		IF r_n06.n06_flag_ident = 'VT' OR 
		   r_n06.n06_flag_ident = 'V1' OR 
		   r_n06.n06_flag_ident = 'V5' OR 
		   r_n06.n06_flag_ident = 'AP' OR
		   r_n06.n06_flag_ident = 'VE' OR
		   r_n06.n06_flag_ident = 'VM' OR
		   r_n06.n06_flag_ident = 'VV' OR
		   r_n06.n06_flag_ident = 'VL' OR
		   r_n06.n06_flag_ident = 'FC' THEN
		--}
			CALL retorna_suma_valor_rubros_base(
						r_n06.n06_cod_rubro, 
                        			vg_codcia,
                        		   	rm_par.n32_cod_liqrol,
                        		   	rm_par.n32_fecha_ini,
                        		   	rm_par.n32_fecha_fin,
                        		   	r_n30.n30_cod_trab, 0)
                  		RETURNING tot_valor, flag
                  	IF r_n06.n06_flag_ident = 'AP' THEN	
				LET r_n32.n32_tot_gan    = tot_valor +
					calcula_valor_dias_descartados(
                        				vg_codcia,
                	        		   	rm_par.n32_cod_liqrol,
        	                		   	rm_par.n32_fecha_ini,
	                        		   	rm_par.n32_fecha_fin,
                        		   		r_n30.n30_cod_trab,
							r_n30.n30_sueldo_mes)
                  		LET r_n33.n33_horas_porc = r_n13.n13_porc_trab
                  		LET r_n33.n33_valor      = (tot_valor *
							r_n13.n13_porc_trab /
							100)
				LET resi_sue = (tot_gan_mes(vg_codcia,
							r_n30.n30_cod_trab, 'T')
							* r_n13.n13_porc_trab /
							100) / 2
				SQL
					SELECT NVL(ROUND($resi_sue, 2) * 2, 0)
						INTO $resi_sue
						FROM dual
				END SQL
	   			IF rm_par.n32_cod_liqrol = 'Q2' AND
				   tot_gan_mes(vg_codcia,r_n30.n30_cod_trab,'T')
					<>
				   resi_sue
				THEN
					SQL
						SELECT TRUNC(($tot_valor *
							$r_n13.n13_porc_trab /
							100), 2)
							INTO $r_n33.n33_valor
							FROM dual
					END SQL
				END IF
                  	ELSE        		                        	
                  	IF r_n06.n06_flag_ident = 'FC' THEN	
                  		LET r_n33.n33_valor = tot_valor * 
					      	      r_n07.n07_factor 
			ELSE
				--LET factor_sueldo = r_n30.n30_factor_hora 
				LET factor_sueldo = r_n30.n30_sueldo_mes /
							(rm_n00.n00_dias_mes * 
							rm_n00.n00_horas_dia)
				IF flag = 'D' THEN 
			              LET factor_sueldo = r_n30.n30_sueldo_mes /
							rm_n00.n00_dias_mes
				END IF
                  		LET r_n33.n33_horas_porc = tot_valor
		   		IF r_n06.n06_flag_ident <> 'VV' THEN
	                  		LET r_n33.n33_valor = tot_valor * 
						      	      r_n07.n07_factor *
						              factor_sueldo
					LET resi_sue = r_n30.n30_sueldo_mes / 2
					SQL
					SELECT NVL(ROUND($resi_sue, 2) * 2, 0)
						INTO $resi_sue
						FROM dual
					END SQL
		   			IF r_n06.n06_flag_ident   = 'VT' AND
					   rm_par.n32_cod_liqrol  = 'Q2' AND
					   r_n30.n30_sueldo_mes  <> resi_sue
					THEN
						SQL
						SELECT TRUNC(($tot_valor *
							$r_n07.n07_factor *
							$factor_sueldo),2)
							INTO $r_n33.n33_valor
							FROM dual
						END SQL
					END IF
				END IF
		   		IF r_n06.n06_flag_ident = 'VE' AND tot_valor > 0
				THEN
					CALL calcula_valor_enfermedad(
							r_n30.n30_cod_trab,
							r_n06.n06_cod_rubro,
							tot_valor,factor_sueldo)
	                  			RETURNING r_n33.n33_valor
				END IF
		   		IF r_n06.n06_flag_ident = 'SX' OR
		   		   r_n06.n06_flag_ident = 'AS'
				THEN
					CALL ajuste_sueldo_enfermedad(
							r_n30.n30_cod_trab,
							r_n06.n06_cod_rubro,
							r_n06.n06_flag_ident)
	                  			RETURNING r_n33.n33_valor
					LET r_n33.n33_horas_porc = NULL
				END IF
		   		IF r_n06.n06_flag_ident = 'SY' OR
		   		   r_n06.n06_flag_ident = 'AM'
				THEN
					CALL ajuste_sueldo_maternidad(
							r_n30.n30_cod_trab,
							r_n06.n06_cod_rubro,
							r_n06.n06_flag_ident)
	                  			RETURNING r_n33.n33_valor
					LET r_n33.n33_horas_porc = NULL
				END IF
				IF r_n06.n06_flag_ident = 'EC' THEN
					IF r_n30.n30_desc_impto = 'S' THEN
					LET r_n33.n33_horas_porc =
						r_n07.n07_factor
					LET r_n33.n33_valor      =
						tot_valor * r_n07.n07_factor
						/ 100
					ELSE
					LET r_n33.n33_horas_porc = NULL
					LET r_n33.n33_valor      = 0.00
					END IF
				END IF
			END IF
			END IF
		ELSE
			IF r_n30.n30_fecha_reing IS NOT NULL THEN
				LET r_n30.n30_fecha_ing = r_n30.n30_fecha_reing
			END IF
			IF r_n30.n30_fecha_sal IS NOT NULL THEN
				LET r_n30.n30_fecha_ing = r_n30.n30_fecha_sal
			END IF
			IF r_n30.n30_fecha_ing >
			   MDY(r_n32.n32_mes_proceso, 01, r_n32.n32_ano_proceso)
			THEN
				IF r_n30.n30_fecha_sal IS NULL THEN
					LET dias = rm_n00.n00_dias_mes -
						DAY(r_n30.n30_fecha_ing) + 1
				ELSE
					LET dias = DAY(r_n30.n30_fecha_ing)
					IF (MONTH(r_n30.n30_fecha_ing) = 2 AND
					    dias = 28) OR (dias = 31)
					THEN
						LET dias = rm_n00.n00_dias_mes
					END IF
				END IF
				INITIALIZE r_n18.* TO NULL
				SELECT * INTO r_n18.*
					FROM rolt018
					WHERE n18_cod_rubro  =
							r_n33.n33_cod_rubro
					  AND n18_flag_ident =
							r_n06.n06_flag_ident
				IF r_n18.n18_flag_ident IS NULL THEN
					IF r_n33.n33_cod_rubro <>
						r_n60.n60_rub_aporte
					THEN
						LET r_n33.n33_valor =
							(r_n33.n33_valor /
							rm_n00.n00_dias_mes) *
							dias
					END IF
				END IF
			END IF
		END IF
		UPDATE rolt033 SET n33_horas_porc = r_n33.n33_horas_porc,
				   n33_valor      = r_n33.n33_valor,
				   n33_orden      = r_n06.n06_orden,
				   n33_cant_valor = r_n06.n06_cant_valor, 
				   n33_imprime_0  = r_n06.n06_imprime_0
			WHERE n33_compania   = r_n33.n33_compania   AND 
			      n33_cod_liqrol = r_n33.n33_cod_liqrol AND 
			      n33_fecha_ini  = r_n33.n33_fecha_ini  AND 
			      n33_fecha_fin  = r_n33.n33_fecha_fin  AND 
			      n33_cod_trab   = r_n33.n33_cod_trab   AND 
			      n33_cod_rubro  = r_n33.n33_cod_rubro      
	END FOREACH                                                     

	CALL calcula_proyeccion_IR(r_n30.*, r_n32.*)

	SELECT * INTO r_n06.* FROM rolt006 WHERE n06_flag_ident = 'SI' 
	CALL actualiza_detalle_liquidacion(0, 
			r_n32.n32_compania,  r_n32.n32_cod_liqrol, 
			r_n32.n32_fecha_ini, r_n32.n32_fecha_fin,
			r_n32.n32_cod_trab,  r_n06.n06_cod_rubro)
	IF r_n30.n30_estado <> 'I' THEN
		CALL retorna_totales(r_n32.n32_compania,  r_n32.n32_cod_liqrol,
	        	             r_n32.n32_fecha_ini, r_n32.n32_fecha_fin, 
	                	     r_n32.n32_cod_trab,  'DI')
			RETURNING tot_ing
		CALL retorna_totales(r_n32.n32_compania,  r_n32.n32_cod_liqrol,
        	                     r_n32.n32_fecha_ini, r_n32.n32_fecha_fin, 
	        	             r_n32.n32_cod_trab,  'DE')
			RETURNING tot_egr
	ELSE
		CALL retorna_totales_sob(r_n32.n32_compania,
				r_n32.n32_cod_liqrol, r_n32.n32_fecha_ini,
				r_n32.n32_fecha_fin, r_n32.n32_cod_trab,
				r_n06.n06_cod_rubro, 'DI')
			RETURNING tot_ing
		CALL retorna_totales_sob(r_n32.n32_compania,
				r_n32.n32_cod_liqrol, r_n32.n32_fecha_ini,
				r_n32.n32_fecha_fin, r_n32.n32_cod_trab,
				r_n06.n06_cod_rubro, 'DE')
			RETURNING tot_egr
	END IF
	LET sobregiro = 0
	IF tot_egr > tot_ing THEN
		SELECT n06_cod_rubro
			FROM rolt033, rolt006
			WHERE n33_compania   = r_n32.n32_compania
			  AND n33_cod_liqrol = r_n32.n32_cod_liqrol
			  AND n33_fecha_ini  = r_n32.n32_fecha_ini
			  AND n33_fecha_fin  = r_n32.n32_fecha_fin
			  AND n33_cod_trab   = r_n32.n32_cod_trab
			  AND n33_valor      > 0
			  AND n06_cod_rubro  = n33_cod_rubro
			  AND n06_flag_ident = 'FM'
                IF STATUS = NOTFOUND THEN
			LET mensaje = 'El trabajador: ', 
				       r_n30.n30_nombres CLIPPED, 
				      ' esta sobregirado con: ',
				       tot_egr - tot_ing USING '<<,<<&.##'
			CALL fl_mostrar_mensaje(mensaje, 'exclamation')
		END IF
		SELECT * INTO r_n06.* FROM rolt006 WHERE n06_flag_ident = 'SI' 
		CALL fl_lee_rubro_liq_trabajador(vg_codcia,    
	        		rm_par.n32_cod_liqrol,	       
	        	 	rm_par.n32_fecha_ini,          
	        	 	rm_par.n32_fecha_fin,          
	        	 	r_n30.n30_cod_trab,            
	        	 	r_n06.n06_cod_rubro)           
                	RETURNING r_n33.*
                IF STATUS = NOTFOUND THEN
                	CALL inserta_rubro_trabajador(r_n06.*, r_n32.*)
                END IF
		LET sobregiro = tot_egr - tot_ing
		CALL actualiza_detalle_liquidacion(tot_egr - tot_ing, 
			r_n32.n32_compania,  r_n32.n32_cod_liqrol, 
			r_n32.n32_fecha_ini, r_n32.n32_fecha_fin,
			r_n32.n32_cod_trab,  r_n06.n06_cod_rubro)
		IF r_n30.n30_estado <> 'I' THEN
			CALL retorna_totales(r_n32.n32_compania,
					r_n32.n32_cod_liqrol,
					r_n32.n32_fecha_ini,r_n32.n32_fecha_fin,
					r_n32.n32_cod_trab, 'DI')
				RETURNING tot_ing
		ELSE
			SELECT n06_cod_rubro
				INTO rubro
				FROM rolt006
				WHERE n06_flag_ident = "SE"
			CALL actualiza_detalle_liquidacion(sobregiro,
					r_n32.n32_compania,r_n32.n32_cod_liqrol,
					r_n32.n32_fecha_ini,r_n32.n32_fecha_fin,
					r_n32.n32_cod_trab, rubro)
			CALL retorna_totales_sob(r_n32.n32_compania,
					r_n32.n32_cod_liqrol,
					r_n32.n32_fecha_ini,r_n32.n32_fecha_fin,
					r_n32.n32_cod_trab, r_n06.n06_cod_rubro,
					'DI')
				RETURNING tot_ing
		END IF
		LET tot_ing = tot_egr
	END IF

	CALL recalcular_tot_gan_por_dias_falt(r_n32.*)
		RETURNING r_n32.n32_tot_gan

	UPDATE rolt032
		SET n32_tot_ing  = tot_ing,
		    n32_tot_egr  = tot_egr,
		    n32_tot_gan  = r_n32.n32_tot_gan,
		    n32_tot_neto = tot_ing - tot_egr
		WHERE n32_compania   = r_n32.n32_compania
		  AND n32_cod_liqrol = r_n32.n32_cod_liqrol
		  AND n32_fecha_ini  = r_n32.n32_fecha_ini
		  AND n32_fecha_fin  = r_n32.n32_fecha_fin
		  AND n32_cod_trab   = r_n32.n32_cod_trab

	SELECT rolt006.*
		INTO r_n06.*
		FROM rolt033, rolt006
		WHERE n33_compania   = r_n32.n32_compania
		  AND n33_cod_liqrol = r_n32.n32_cod_liqrol
		  AND n33_fecha_ini  = r_n32.n32_fecha_ini
		  AND n33_fecha_fin  = r_n32.n32_fecha_fin
		  AND n33_cod_trab   = r_n32.n32_cod_trab
		  AND n06_cod_rubro  = n33_cod_rubro
		  AND n06_flag_ident = 'FM'

	IF r_n06.n06_flag_ident = 'FM' AND r_n30.n30_fon_res_anio = 'N' THEN
		LET r_n30_aux.* = r_n30.*
		CALL fl_lee_trabajador_roles(vg_codcia, r_n30.n30_cod_trab)
			RETURNING r_n30.*
		CALL calcular_fondo_reserva_mensual(r_n30.n30_cod_trab,
						r_n30.n30_fecha_ing,
						r_n30.n30_fecha_reing,
						r_n30.n30_fecha_sal,
						r_n06.n06_cod_rubro)
			RETURNING r_n33.n33_valor, r_n33.n33_horas_porc
		LET r_n30.* = r_n30_aux.*
		CALL actualiza_detalle_liquidacion(r_n33.n33_valor,
			r_n32.n32_compania,  r_n32.n32_cod_liqrol, 
			r_n32.n32_fecha_ini, r_n32.n32_fecha_fin,
			r_n32.n32_cod_trab,  r_n06.n06_cod_rubro)
		UPDATE rolt033
			SET n33_horas_porc = r_n33.n33_horas_porc
			WHERE n33_compania   = r_n32.n32_compania
			  AND n33_cod_liqrol = r_n32.n32_cod_liqrol
			  AND n33_fecha_ini  = r_n32.n32_fecha_ini
			  AND n33_fecha_fin  = r_n32.n32_fecha_fin
			  AND n33_cod_trab   = r_n32.n32_cod_trab
			  AND n33_cod_rubro  = r_n06.n06_cod_rubro      
		IF r_n30.n30_estado <> 'I' THEN
			CALL retorna_totales(r_n32.n32_compania,
					r_n32.n32_cod_liqrol,
					r_n32.n32_fecha_ini,r_n32.n32_fecha_fin,
					r_n32.n32_cod_trab, 'DI')
				RETURNING tot_ing
			CALL retorna_totales(r_n32.n32_compania,
					r_n32.n32_cod_liqrol,
					r_n32.n32_fecha_ini,r_n32.n32_fecha_fin,
					r_n32.n32_cod_trab, 'DE')
				RETURNING tot_egr
		ELSE
			CALL retorna_totales_sob(r_n32.n32_compania,
					r_n32.n32_cod_liqrol,
					r_n32.n32_fecha_ini,r_n32.n32_fecha_fin,
					r_n32.n32_cod_trab, r_n06.n06_cod_rubro,
					'DI')
				RETURNING tot_ing
			CALL retorna_totales_sob(r_n32.n32_compania,
					r_n32.n32_cod_liqrol,
					r_n32.n32_fecha_ini,r_n32.n32_fecha_fin,
					r_n32.n32_cod_trab, r_n06.n06_cod_rubro,
					'DE')
				RETURNING tot_egr
		END IF
		LET tot_ing = tot_ing - sobregiro
		IF tot_egr > tot_ing THEN
			LET mensaje = 'El trabajador: ', 
				       r_n30.n30_nombres CLIPPED, 
				      ' esta sobregirado con: ',
				       tot_egr - tot_ing USING '<<,<<&.##'
			CALL fl_mostrar_mensaje(mensaje, 'exclamation')
			SELECT * INTO r_n06.*
				FROM rolt006
				WHERE n06_flag_ident = 'SI' 
			CALL fl_lee_rubro_liq_trabajador(vg_codcia,    
		        		rm_par.n32_cod_liqrol,	       
	        		 	rm_par.n32_fecha_ini,          
	        		 	rm_par.n32_fecha_fin,          
	        	 		r_n30.n30_cod_trab,            
		        	 	r_n06.n06_cod_rubro)           
        	        	RETURNING r_n33.*
			CALL actualiza_detalle_liquidacion(tot_egr - tot_ing, 
				r_n32.n32_compania,  r_n32.n32_cod_liqrol, 
				r_n32.n32_fecha_ini, r_n32.n32_fecha_fin,
				r_n32.n32_cod_trab,  r_n06.n06_cod_rubro)
			IF r_n30.n30_estado <> 'I' THEN
				CALL retorna_totales(r_n32.n32_compania,
						r_n32.n32_cod_liqrol,
						r_n32.n32_fecha_ini,
						r_n32.n32_fecha_fin,
						r_n32.n32_cod_trab, 'DI')
					RETURNING tot_ing
			ELSE
				CALL retorna_totales_sob(r_n32.n32_compania,
						r_n32.n32_cod_liqrol,
						r_n32.n32_fecha_ini,
						r_n32.n32_fecha_fin,
						r_n32.n32_cod_trab,
						r_n06.n06_cod_rubro, 'DI')
					RETURNING tot_ing
			END IF
			LET tot_ing = tot_egr
		END IF

		UPDATE rolt032
			SET n32_tot_ing  = tot_ing,
			    n32_tot_egr  = tot_egr,
			    n32_tot_neto = tot_ing - tot_egr
			WHERE n32_compania   = r_n32.n32_compania
			  AND n32_cod_liqrol = r_n32.n32_cod_liqrol
			  AND n32_fecha_ini  = r_n32.n32_fecha_ini
			  AND n32_fecha_fin  = r_n32.n32_fecha_fin
			  AND n32_cod_trab   = r_n32.n32_cod_trab
	END IF

        LET vm_num_liq = vm_num_liq + 1
END FOREACH

END FUNCTION



FUNCTION tot_gan_mes(codcia, cod_trab, flag)
DEFINE codcia 		LIKE rolt032.n32_compania
DEFINE cod_trab		LIKE rolt032.n32_cod_trab
DEFINE flag		CHAR(1)
DEFINE fecha_ini	LIKE rolt032.n32_fecha_ini
DEFINE fecha_fin	LIKE rolt032.n32_fecha_fin
DEFINE valor		DECIMAL(12,2)

LET fecha_ini = MDY(MONTH(rm_par.n32_fecha_ini), 01, YEAR(rm_par.n32_fecha_ini))
LET fecha_fin = fecha_ini + 1 UNITS MONTH - 1 UNITS DAY
IF flag = 'R' THEN
	LET fecha_fin = fecha_ini - 1 UNITS DAY
	LET fecha_ini = MDY(MONTH(fecha_fin), 01, YEAR(fecha_fin))
END IF
SELECT NVL(SUM(n32_tot_gan), 0)
	INTO valor
	FROM rolt032
	WHERE n32_compania    = codcia
	  AND n32_cod_liqrol IN ("Q1", "Q2")
	  AND n32_fecha_ini  >= fecha_ini
	  AND n32_fecha_fin  <= fecha_fin
	  AND n32_cod_trab    = cod_trab
RETURN valor

END FUNCTION



FUNCTION retorna_totales(codcia, cod_liqrol, fecha_ini, fecha_fin, cod_trab,
				flag)
DEFINE codcia 		LIKE rolt032.n32_compania
DEFINE cod_liqrol	LIKE rolt032.n32_cod_liqrol
DEFINE fecha_ini	LIKE rolt032.n32_fecha_ini                                       
DEFINE fecha_fin	LIKE rolt032.n32_fecha_fin
DEFINE cod_trab		LIKE rolt032.n32_cod_trab
DEFINE flag		LIKE rolt006.n06_det_tot
DEFINE valor		DECIMAL(12,2)

SELECT SUM(n33_valor) INTO valor FROM rolt033         
	WHERE n33_compania   = codcia     AND 
	      n33_cod_liqrol = cod_liqrol AND 
              n33_fecha_ini  = fecha_ini  AND 
              n33_fecha_fin  = fecha_fin  AND 
              n33_cod_trab   = cod_trab   AND 
	      n33_det_tot    = flag       AND
              n33_cant_valor = 'V'
IF valor IS NULL THEN
	LET valor = 0
END IF
RETURN valor

END FUNCTION



FUNCTION retorna_totales_sob(codcia, cod_liqrol, fecha_ini, fecha_fin, cod_trab,
				rubro, flag)
DEFINE codcia 		LIKE rolt032.n32_compania
DEFINE cod_liqrol	LIKE rolt032.n32_cod_liqrol
DEFINE fecha_ini	LIKE rolt032.n32_fecha_ini
DEFINE fecha_fin	LIKE rolt032.n32_fecha_fin
DEFINE cod_trab		LIKE rolt032.n32_cod_trab
DEFINE rubro		LIKE rolt006.n06_cod_rubro
DEFINE flag		LIKE rolt006.n06_det_tot
DEFINE fecha		LIKE rolt032.n32_fecha_ini
DEFINE r_n06		RECORD LIKE rolt006.*
DEFINE valor, val_sob	DECIMAL(12,2)

LET val_sob = 0
CALL fl_lee_rubro_roles(rubro) RETURNING r_n06.*
IF r_n06.n06_flag_ident <> 'FM' AND flag = 'DE' THEN
	DECLARE q_sobre CURSOR FOR
		SELECT n33_valor, n33_fecha_ini
			FROM rolt033
			WHERE n33_compania  = codcia
			  AND n33_fecha_ini < fecha_ini
			  AND n33_fecha_fin < fecha_fin
			  AND n33_cod_trab  = cod_trab
			  AND n33_cod_rubro = rubro
			ORDER BY 2 DESC
	OPEN q_sobre
	FETCH q_sobre INTO val_sob, fecha
	CLOSE q_sobre
	FREE q_sobre
END IF
SELECT SUM(n33_valor)
	INTO valor
	FROM rolt033
	WHERE n33_compania   = codcia
	  AND n33_cod_liqrol = cod_liqrol
	  AND n33_fecha_ini  = fecha_ini
	  AND n33_fecha_fin  = fecha_fin
	  AND n33_cod_trab   = cod_trab
	  AND n33_det_tot    = flag
	  AND n33_cod_rubro  NOT IN
				(SELECT n06_cod_rubro
					FROM rolt006
					WHERE n06_flag_ident IN ("SI", "SE"))
	  AND n33_cant_valor = "V"
IF valor IS NULL THEN
	LET valor = 0
END IF
LET valor = valor + val_sob
RETURN valor

END FUNCTION



FUNCTION retorna_suma_valor_rubros_base(cod_rubro, codcia, cod_liqrol,
					fecha_ini, fecha_fin, cod_trab, flag)
DEFINE cod_rubro	LIKE rolt006.n06_cod_rubro
DEFINE rubro_base	LIKE rolt006.n06_cod_rubro
DEFINE codcia		LIKE rolt032.n32_compania
DEFINE cod_liqrol	LIKE rolt032.n32_cod_liqrol
DEFINE fecha_ini	LIKE rolt032.n32_fecha_ini
DEFINE fecha_fin	LIKE rolt032.n32_fecha_fin
DEFINE cod_trab		LIKE rolt030.n30_cod_trab
DEFINE flag		SMALLINT
DEFINE r_n33		RECORD LIKE rolt033.*
DEFINE tot_val		LIKE rolt033.n33_valor
DEFINE query		CHAR(400)

LET query = 'SELECT n08_rubro_base ',
		' FROM rolt008 ',
		' WHERE n08_cod_rubro  = ', cod_rubro
IF flag = 1 THEN
	LET query = query CLIPPED,
			'   AND n08_rubro_base NOT IN ',
				'(SELECT n06_cod_rubro ',
					'FROM rolt006 ',
					'WHERE n06_flag_ident = "OV")'
END IF
IF flag = 2 THEN
	LET query = query CLIPPED,
			'   AND n08_rubro_base IN ',
				'(SELECT n06_cod_rubro ',
					'FROM rolt006 ',
					'WHERE n06_flag_ident IN ',
					'("VT", "VE", "VM", "VV"))'
END IF
PREPARE cons_n08 FROM query
DECLARE q_rbase CURSOR FOR cons_n08
LET tot_val = 0
INITIALIZE r_n33.* TO NULL
FOREACH q_rbase INTO rubro_base
	CALL fl_lee_rubro_liq_trabajador(codcia, rm_par.n32_cod_liqrol,
				fecha_ini, fecha_fin, cod_trab, rubro_base)
		RETURNING r_n33.*
	IF r_n33.n33_valor IS NULL THEN
		LET r_n33.n33_valor = 0
	END IF
	LET tot_val = tot_val + r_n33.n33_valor
END FOREACH
RETURN tot_val, r_n33.n33_cant_valor

END FUNCTION



FUNCTION retorna_reg_rubro_quin_anter(cod_trab, cod_rubro)
DEFINE cod_trab		LIKE rolt030.n30_cod_trab
DEFINE cod_rubro	LIKE rolt033.n33_cod_rubro
DEFINE r_n33		RECORD LIKE rolt033.*
DEFINE cod_liqrol	LIKE rolt033.n33_cod_liqrol
DEFINE fecha_ini	DATE
DEFINE fecha_fin	DATE

IF DAY(rm_par.n32_fecha_ini) = 1 THEN
	LET fecha_fin  = rm_par.n32_fecha_ini - 1 UNITS DAY
	LET fecha_ini  = MDY(MONTH(fecha_fin), 16, YEAR(fecha_fin))
	LET cod_liqrol = 'Q2'
ELSE
	LET fecha_ini  = MDY(MONTH(rm_par.n32_fecha_ini), 01,
				YEAR(rm_par.n32_fecha_ini))
	LET fecha_fin  = MDY(MONTH(rm_par.n32_fecha_fin), 15,
				YEAR(rm_par.n32_fecha_fin))
	LET cod_liqrol = 'Q1'
END IF
CALL fl_lee_rubro_liq_trabajador(vg_codcia, cod_liqrol, fecha_ini, fecha_fin,
					cod_trab, cod_rubro)
	RETURNING r_n33.*
RETURN r_n33.*

END FUNCTION



FUNCTION calcula_valor_enfermedad(cod_trab, cod_rubro, valor, factor_sue)
DEFINE cod_trab		LIKE rolt030.n30_cod_trab
DEFINE cod_rubro	LIKE rolt033.n33_cod_rubro
DEFINE valor		LIKE rolt033.n33_valor
DEFINE factor_sue	DECIMAL(22,15)
DEFINE r_n07		RECORD LIKE rolt007.*
DEFINE r_n33		RECORD LIKE rolt033.*
DEFINE valor_enf	LIKE rolt033.n33_valor
DEFINE dias		SMALLINT

CALL retorna_reg_rubro_quin_anter(cod_trab, cod_rubro) RETURNING r_n33.*
CALL fl_lee_rubro_que_se_calcula(cod_rubro) RETURNING r_n07.*
LET valor_enf = 0
IF r_n33.n33_valor > 0 THEN
	IF r_n33.n33_horas_porc <= r_n07.n07_valor_max THEN
		LET valor_enf = (r_n07.n07_valor_max - r_n33.n33_horas_porc) *
				 r_n07.n07_factor * factor_sue
	END IF
ELSE
	IF r_n33.n33_horas_porc = 0 THEN
		LET dias = valor
		IF dias > r_n07.n07_valor_max THEN
			LET dias = r_n07.n07_valor_max
		END IF
		LET valor_enf = dias * r_n07.n07_factor * factor_sue
	END IF
END IF
RETURN valor_enf

END FUNCTION



FUNCTION ajuste_sueldo_enfermedad(cod_trab, cod_rubro, flag_ident)
DEFINE cod_trab		LIKE rolt030.n30_cod_trab
DEFINE cod_rubro	LIKE rolt033.n33_cod_rubro
DEFINE flag_ident	LIKE rolt006.n06_flag_ident
DEFINE rubro		LIKE rolt033.n33_cod_rubro
DEFINE r_n13		RECORD LIKE rolt013.*
DEFINE r_n30		RECORD LIKE rolt030.*
DEFINE r_n33		RECORD LIKE rolt033.*
DEFINE valor_enf	LIKE rolt033.n33_valor
DEFINE valor_aux	LIKE rolt033.n33_valor
DEFINE flag		SMALLINT

LET valor_enf = 0
LET rubro     = NULL
SELECT n08_cod_rubro INTO rubro
	FROM rolt006, rolt008
	WHERE n06_flag_ident  = 'DE'
	  AND n08_rubro_base  = n06_cod_rubro
	  AND n08_cod_rubro  IN (SELECT n06_cod_rubro
					 FROM rolt006
					 WHERE n06_flag_ident = 'VE')
CALL fl_lee_rubro_liq_trabajador(vg_codcia, rm_par.n32_cod_liqrol,
				rm_par.n32_fecha_ini, rm_par.n32_fecha_fin,
				cod_trab, rubro)
	RETURNING r_n33.*
IF r_n33.n33_horas_porc IS NULL THEN
	RETURN valor_enf
END IF
IF r_n33.n33_horas_porc = 0 THEN
	RETURN valor_enf
END IF
LET rubro = NULL
SELECT n08_rubro_base INTO rubro FROM rolt008 WHERE n08_cod_rubro = cod_rubro
IF rubro IS NULL THEN
	RETURN valor_enf
END IF
CALL fl_lee_rubro_liq_trabajador(vg_codcia, rm_par.n32_cod_liqrol,
				rm_par.n32_fecha_ini, rm_par.n32_fecha_fin,
				cod_trab, rubro)
	RETURNING r_n33.*
CALL fl_lee_trabajador_roles(vg_codcia, cod_trab) RETURNING r_n30.*
INITIALIZE rubro TO NULL
SELECT n06_cod_rubro INTO rubro FROM rolt006 WHERE n06_flag_ident = 'AP'
IF flag_ident = 'SX' THEN
	CALL retorna_suma_valor_rubros_base(rubro, vg_codcia,
				rm_par.n32_cod_liqrol, rm_par.n32_fecha_ini,
				rm_par.n32_fecha_fin, cod_trab, 2)
		RETURNING r_n33.n33_valor, flag
	IF r_n33.n33_valor < retorna_sueldo_quincena(r_n30.n30_sueldo_mes) THEN
		LET valor_enf = retorna_sueldo_quincena(r_n30.n30_sueldo_mes)
				- r_n33.n33_valor
	END IF
ELSE
	LET valor_aux = r_n33.n33_valor
	IF valor_aux > 0 THEN
		CALL fl_lee_seguros(r_n30.n30_cod_seguro) RETURNING r_n13.*
		CALL fl_lee_rubro_liq_trabajador(vg_codcia,
				rm_par.n32_cod_liqrol, rm_par.n32_fecha_ini,
				rm_par.n32_fecha_fin, cod_trab, rubro)
			RETURNING r_n33.*
		LET valor_enf = valor_aux - 
				(valor_aux * r_n13.n13_porc_trab / 100)
		IF (valor_aux - (r_n33.n33_valor + valor_enf)) >= -0.03 AND
		   (valor_aux - (r_n33.n33_valor + valor_enf)) <= 0.03
		THEN
			LET valor_enf = valor_enf + (valor_aux -
					(r_n33.n33_valor + valor_enf))
		END IF
	END IF
END IF
RETURN valor_enf

END FUNCTION



FUNCTION ajuste_sueldo_maternidad(cod_trab, cod_rubro, flag_ident)
DEFINE cod_trab		LIKE rolt030.n30_cod_trab
DEFINE cod_rubro	LIKE rolt033.n33_cod_rubro
DEFINE flag_ident	LIKE rolt006.n06_flag_ident
DEFINE rubro		LIKE rolt033.n33_cod_rubro
DEFINE r_n13		RECORD LIKE rolt013.*
DEFINE r_n30		RECORD LIKE rolt030.*
DEFINE r_n33		RECORD LIKE rolt033.*
DEFINE valor_mat	LIKE rolt033.n33_valor
DEFINE valor_aux	LIKE rolt033.n33_valor
DEFINE flag		SMALLINT

LET valor_mat = 0
LET rubro     = NULL
SELECT n08_cod_rubro INTO rubro
	FROM rolt006, rolt008
	WHERE n06_flag_ident  = 'DM'
	  AND n08_rubro_base  = n06_cod_rubro
	  AND n08_cod_rubro  IN (SELECT n06_cod_rubro
					 FROM rolt006
					 WHERE n06_flag_ident = 'VM')
CALL fl_lee_rubro_liq_trabajador(vg_codcia, rm_par.n32_cod_liqrol,
				rm_par.n32_fecha_ini, rm_par.n32_fecha_fin,
				cod_trab, rubro)
	RETURNING r_n33.*
IF r_n33.n33_horas_porc IS NULL THEN
	RETURN valor_mat
END IF
IF r_n33.n33_horas_porc = 0 THEN
	RETURN valor_mat
END IF
LET rubro = NULL
SELECT n08_rubro_base INTO rubro FROM rolt008 WHERE n08_cod_rubro = cod_rubro
IF rubro IS NULL THEN
	RETURN valor_mat
END IF
CALL fl_lee_rubro_liq_trabajador(vg_codcia, rm_par.n32_cod_liqrol,
				rm_par.n32_fecha_ini, rm_par.n32_fecha_fin,
				cod_trab, rubro)
	RETURNING r_n33.*
CALL fl_lee_trabajador_roles(vg_codcia, cod_trab) RETURNING r_n30.*
INITIALIZE rubro TO NULL
SELECT n06_cod_rubro INTO rubro FROM rolt006 WHERE n06_flag_ident = 'AP'
IF flag_ident = 'SY' THEN
	CALL retorna_suma_valor_rubros_base(rubro, vg_codcia,
				rm_par.n32_cod_liqrol, rm_par.n32_fecha_ini,
				rm_par.n32_fecha_fin, cod_trab, 2)
		RETURNING r_n33.n33_valor, flag
	IF r_n33.n33_valor < retorna_sueldo_quincena(r_n30.n30_sueldo_mes) THEN
		LET valor_mat = retorna_sueldo_quincena(r_n30.n30_sueldo_mes)
				- r_n33.n33_valor
	END IF
ELSE
	LET valor_aux = r_n33.n33_valor
	IF valor_aux > 0 THEN
		CALL fl_lee_seguros(r_n30.n30_cod_seguro) RETURNING r_n13.*
		CALL fl_lee_rubro_liq_trabajador(vg_codcia,
				rm_par.n32_cod_liqrol, rm_par.n32_fecha_ini,
				rm_par.n32_fecha_fin, cod_trab, rubro)
			RETURNING r_n33.*
		LET valor_mat = valor_aux - 
				(valor_aux * r_n13.n13_porc_trab / 100)
		IF (valor_aux - (r_n33.n33_valor + valor_mat)) >= -0.03 AND
		   (valor_aux - (r_n33.n33_valor + valor_mat)) <= 0.03
		THEN
			LET valor_mat = valor_mat + (valor_aux -
					(r_n33.n33_valor + valor_mat))
		END IF
	END IF
END IF
RETURN valor_mat

END FUNCTION



FUNCTION retorna_sueldo_quincena(sueldo_mes)
DEFINE sueldo_mes	LIKE rolt030.n30_sueldo_mes
DEFINE resi_sue		DECIMAL(14,4)
DEFINE resi_sue2	DECIMAL(14,4)

LET resi_sue = sueldo_mes / 2
SQL
	SELECT NVL(ROUND($resi_sue, 2) * 2, 0) INTO $resi_sue2 FROM dual
END SQL
IF rm_par.n32_cod_liqrol = 'Q2' AND sueldo_mes <> resi_sue2 THEN
	SQL
		SELECT TRUNC(($sueldo_mes / 2), 2)
			INTO $resi_sue
			FROM dual
	END SQL
END IF
RETURN resi_sue

END FUNCTION



FUNCTION calcula_valor_vacaciones(codcia, cod_liqrol, fecha_ini, fecha_fin,
					cod_trab, flag_ident)
DEFINE codcia		LIKE rolt032.n32_compania
DEFINE cod_liqrol	LIKE rolt032.n32_cod_liqrol
DEFINE fecha_ini	LIKE rolt032.n32_fecha_ini
DEFINE fecha_fin	LIKE rolt032.n32_fecha_fin
DEFINE cod_trab		LIKE rolt030.n30_cod_trab
DEFINE flag_ident	LIKE rolt006.n06_flag_ident
DEFINE r_n13		RECORD LIKE rolt013.*
DEFINE r_n30		RECORD LIKE rolt030.*
DEFINE r_n33		RECORD LIKE rolt033.*
DEFINE r_n39		RECORD LIKE rolt039.*
DEFINE r_n47		RECORD LIKE rolt047.*
DEFINE val_vac		LIKE rolt039.n39_valor_vaca
DEFINE valor		LIKE rolt033.n33_valor
DEFINE flag		LIKE rolt033.n33_cant_valor
DEFINE rubro		LIKE rolt006.n06_cod_rubro
DEFINE dias_g		LIKE rolt047.n47_dias_goza
DEFINE tot_dias		SMALLINT
DEFINE tot_valor	DECIMAL(12,2)

LET valor = 0
IF flag_ident = 'AG' THEN
	SELECT n06_cod_rubro INTO rubro FROM rolt006 WHERE n06_flag_ident = 'XV'
	CALL retorna_reg_rubro_quin_anter(cod_trab, rubro)
		RETURNING r_n33.*
	IF r_n33.n33_valor > 0 THEN
		INITIALIZE r_n47.* TO NULL
		DECLARE q_n47_2 CURSOR FOR
			SELECT * FROM rolt047
				WHERE n47_compania   = r_n33.n33_compania
				  AND n47_cod_liqrol = r_n33.n33_cod_liqrol
				  AND n47_fecha_ini  = r_n33.n33_fecha_ini
				  AND n47_fecha_fin  = r_n33.n33_fecha_fin
				  AND n47_cod_trab   = r_n33.n33_cod_trab
				  AND n47_estado     = "G"
				ORDER BY n47_periodo_fin DESC
		OPEN q_n47_2
		FETCH q_n47_2 INTO r_n47.*
		CLOSE q_n47_2
		FREE q_n47_2
		IF YEAR(r_n47.n47_periodo_fin) < 2009 THEN
			LET valor = r_n33.n33_valor
		END IF
	END IF
	RETURN valor
END IF
IF flag_ident = 'GV' THEN
	SELECT n06_cod_rubro INTO rubro FROM rolt006 WHERE n06_flag_ident = 'AG'
	CALL fl_lee_rubro_liq_trabajador(vg_codcia,
			rm_par.n32_cod_liqrol, rm_par.n32_fecha_ini,
			rm_par.n32_fecha_fin, cod_trab, rubro)
		RETURNING r_n33.*
	IF r_n33.n33_valor > 0 THEN
		LET valor = r_n33.n33_valor
	END IF
	RETURN valor
END IF
INITIALIZE r_n47.* TO NULL
DECLARE q_n47 CURSOR FOR
	SELECT * FROM rolt047
		WHERE n47_compania   = codcia
		  AND n47_cod_liqrol = cod_liqrol
		  AND n47_fecha_ini  = fecha_ini
		  AND n47_fecha_fin  = fecha_fin
		  AND n47_cod_trab   = cod_trab
		  AND n47_estado     = "A"
OPEN q_n47
FETCH q_n47 INTO r_n47.*
IF r_n47.n47_compania IS NULL THEN
	RETURN valor
END IF
LET valor    = 0
LET val_vac  = 0
LET tot_dias = 0
FOREACH q_n47 INTO r_n47.*
	IF flag_ident = 'DV' THEN
		LET valor  = valor + r_n47.n47_dias_goza
		CONTINUE FOREACH
	END IF
	CALL fl_lee_vacaciones(r_n47.n47_compania, r_n47.n47_proceso,
				r_n47.n47_cod_trab, r_n47.n47_periodo_ini,
				r_n47.n47_periodo_fin)
		RETURNING r_n39.*
	IF r_n39.n39_estado = 'P' AND r_n39.n39_tipo = 'G' THEN
		LET tot_dias = r_n39.n39_dias_vac
		LET val_vac  = r_n39.n39_valor_vaca
		IF r_n39.n39_gozar_adic = 'S' THEN
			LET tot_dias = tot_dias + r_n39.n39_dias_adi
			LET val_vac  = val_vac  + r_n39.n39_valor_adic
		END IF
		LET val_vac = val_vac + r_n39.n39_otros_ing
		LET valor   = valor + ((val_vac / tot_dias) *
						r_n47.n47_dias_goza)
	END IF
END FOREACH
IF flag_ident <> 'DV' THEN
	--IF flag_ident = 'XV' THEN
	IF flag_ident = 'IV' THEN
		CALL fl_lee_trabajador_roles(r_n39.n39_compania,
						r_n39.n39_cod_trab)
			RETURNING r_n30.*
		CALL fl_lee_seguros(r_n30.n30_cod_seguro) RETURNING r_n13.*
		--LET valor = valor - (valor * r_n13.n13_porc_trab / 100)
		LET valor = (valor * r_n13.n13_porc_trab / 100)
	END IF
	IF flag_ident = 'OV' THEN
		SELECT n06_cod_rubro INTO rubro
			FROM rolt006
			WHERE n06_flag_ident = 'AP'
		CALL fl_lee_trabajador_roles(r_n39.n39_compania,
						r_n39.n39_cod_trab)
			RETURNING r_n30.*
		SELECT SUM(n47_dias_goza)
			INTO dias_g
			FROM rolt047
			WHERE n47_compania   = codcia
			  AND n47_cod_liqrol = cod_liqrol
			  AND n47_fecha_ini  = fecha_ini
			  AND n47_fecha_fin  = fecha_fin
			  AND n47_cod_trab   = cod_trab
			  AND n47_estado     = "A"
		LET tot_valor = (((rm_n00.n00_dias_mes / 2) -
				dias_g) * (r_n30.n30_sueldo_mes /
				(rm_n00.n00_dias_mes * rm_n00.n00_horas_dia)) *
				rm_n00.n00_horas_dia) + valor
		LET valor = 0
		IF retorna_sueldo_quincena(r_n30.n30_sueldo_mes) > tot_valor
		THEN
			LET valor =retorna_sueldo_quincena(r_n30.n30_sueldo_mes)
					- tot_valor
		END IF
	END IF
END IF
RETURN valor

END FUNCTION



FUNCTION calcula_valor_dias_descartados(codcia, cod_liqrol,fecha_ini,
					fecha_fin, cod_trab, sueldo_mes)
DEFINE codcia		LIKE rolt032.n32_compania
DEFINE cod_liqrol	LIKE rolt032.n32_cod_liqrol
DEFINE fecha_ini	LIKE rolt032.n32_fecha_ini
DEFINE fecha_fin	LIKE rolt032.n32_fecha_fin
DEFINE cod_trab		LIKE rolt030.n30_cod_trab
DEFINE sueldo_mes	LIKE rolt030.n30_sueldo_mes
DEFINE valor, valor_des	LIKE rolt033.n33_valor

SELECT n08_rubro_base rubro_base, n33_valor valor_rub
	FROM rolt016, rolt006, rolt008, rolt033
	WHERE n16_flag_ident = 'DT'
	  AND n06_flag_ident = n16_flag_ident
	  AND n06_estado     = 'A'
	  AND n08_cod_rubro  = n06_cod_rubro
	  AND n08_rubro_base NOT IN (SELECT a.n08_rubro_base
					FROM rolt008 a, rolt006 b
					WHERE a.n08_cod_rubro  = b.n06_cod_rubro
				          AND b.n06_flag_ident = 'DC')
	  AND n33_compania   = codcia
	  AND n33_cod_liqrol = rm_par.n32_cod_liqrol
	  AND n33_fecha_ini  = fecha_ini
	  AND n33_fecha_fin  = fecha_fin
	  AND n33_cod_trab   = cod_trab
	  AND n33_cod_rubro  = n08_rubro_base
	  AND n33_valor      > 0
	INTO TEMP t1
SELECT NVL(SUM(valor_rub), 0) INTO valor FROM t1
SELECT NVL(SUM(n33_valor), 0) INTO valor_des
	FROM t1, rolt006, rolt008, rolt033
	WHERE n08_rubro_base  = rubro_base
	  AND n06_cod_rubro   = n08_cod_rubro
	  AND n06_flag_ident <> 'DT'
	  AND n33_compania    = codcia
	  AND n33_cod_liqrol  = rm_par.n32_cod_liqrol
	  AND n33_fecha_ini   = fecha_ini
	  AND n33_fecha_fin   = fecha_fin
	  AND n33_cod_trab    = cod_trab
	  AND n33_cod_rubro   = n06_cod_rubro
	  AND n33_valor       > 0
DROP TABLE t1
LET valor = (valor * (sueldo_mes / (rm_n00.n00_dias_mes * rm_n00.n00_horas_dia))
		* rm_n00.n00_horas_dia) - valor_des
RETURN valor

END FUNCTION



FUNCTION calcular_fondo_reserva_mensual(cod_trab, fec_ing, fec_rei, fec_sal,
					cod_rubro)
DEFINE cod_trab		LIKE rolt030.n30_cod_trab
DEFINE fec_ing		LIKE rolt030.n30_fecha_ing
DEFINE fec_rei		LIKE rolt030.n30_fecha_reing
DEFINE fec_sal		LIKE rolt030.n30_fecha_sal
DEFINE cod_rubro	LIKE rolt033.n33_cod_rubro
DEFINE r_n07		RECORD LIKE rolt007.*
DEFINE r_n30		RECORD LIKE rolt030.*
DEFINE r_n38		RECORD LIKE rolt038.*
DEFINE tot_gan		LIKE rolt032.n32_tot_gan
DEFINE valor		LIKE rolt033.n33_valor
DEFINE query		VARCHAR(250)
DEFINE dias_fon, dias	INTEGER
DEFINE fecha, fec	DATE
DEFINE fecha_fin	DATE

LET fecha_fin = MDY(MONTH(rm_par.n32_fecha_ini), 01, YEAR(rm_par.n32_fecha_ini))
		- 1 UNITS DAY
LET dias_fon = (fecha_fin - fec_ing) + 1
IF fec_rei IS NOT NULL THEN
	LET dias_fon = (fecha_fin - fec_rei) + 1
	IF fec_sal IS NOT NULL THEN
		LET dias_fon = dias_fon + ((fec_sal - fec_ing) + 1)
	END IF
END IF
IF dias_fon <= rm_n90.n90_dias_anio THEN
	LET dias_fon = NULL
	RETURN 0, dias_fon
END IF
CALL tot_gan_mes(vg_codcia, cod_trab, 'R') RETURNING tot_gan
LET dias_fon = dias_fon - rm_n90.n90_dias_anio
--IF dias_fon > 0 AND dias_fon < rm_n90.n90_dias_anio THEN
IF dias_fon > 0 AND dias_fon < rm_n00.n00_dias_mes THEN
	LET fecha = MDY(MONTH(rm_par.n32_fecha_ini), 01,
			YEAR(rm_par.n32_fecha_ini)) - 1 UNITS DAY
	LET fec   = MDY(MONTH(fec_ing), DAY(fec_ing), YEAR(fecha))
	IF fec_rei IS NOT NULL THEN
		LET fec = MDY(MONTH(fec_rei), DAY(fec_rei), YEAR(fecha))
		IF fec_sal IS NOT NULL THEN
			LET fec = MDY(MONTH(fec_ing), DAY(fec_ing), YEAR(fecha))
		END IF
	END IF
	IF EXTEND(fec, YEAR TO MONTH) >= EXTEND(fecha, YEAR TO MONTH) THEN
		LET dias_fon = (fecha - (MDY(MONTH(fecha), DAY(fec),
				YEAR(fecha)))) + 1
		IF dias_fon < rm_n00.n00_dias_mes THEN
			LET dias = DAY(fecha)
			IF MONTH(fecha) = 2 THEN
				LET dias = rm_n00.n00_dias_mes
			END IF
			LET tot_gan = ((tot_gan / dias) * dias_fon)
		END IF
	END IF
END IF
CALL fl_lee_rubro_que_se_calcula(cod_rubro) RETURNING r_n07.*
LET query = 'SELECT ', tot_gan, ' ', r_n07.n07_operacion, ' ', r_n07.n07_factor,
		' / 100 val_fon ',
		' FROM dual ',
		' INTO TEMP t1'
PREPARE exec_fm FROM query
EXECUTE exec_fm
SELECT * INTO valor FROM t1
DROP TABLE t1
IF dias_fon > rm_n00.n00_dias_mes THEN
	LET dias_fon = rm_n00.n00_dias_mes
END IF
CALL fl_lee_trabajador_roles(vg_codcia, cod_trab) RETURNING r_n30.*
INITIALIZE r_n38.* TO NULL
LET r_n38.n38_compania  = r_n30.n30_compania
LET r_n38.n38_fecha_fin = MDY(MONTH(rm_par.n32_fecha_ini), 01,
				YEAR(rm_par.n32_fecha_ini)) - 1 UNITS DAY
LET r_n38.n38_fecha_ini = MDY(MONTH(r_n38.n38_fecha_fin), 01,
				YEAR(r_n38.n38_fecha_fin))
LET r_n38.n38_cod_trab  = r_n30.n30_cod_trab
DELETE FROM rolt038
	WHERE n38_compania  = r_n38.n38_compania
	  AND n38_fecha_ini = r_n38.n38_fecha_ini
	  AND n38_fecha_fin = r_n38.n38_fecha_fin
	  AND n38_cod_trab  = r_n38.n38_cod_trab
	  AND n38_pago_iess = "N"
LET r_n38.n38_estado    = 'A'
LET r_n38.n38_fecha_ing = r_n30.n30_fecha_ing
IF r_n30.n30_fecha_reing IS NOT NULL THEN
	LET r_n38.n38_fecha_ing = r_n30.n30_fecha_reing
END IF
LET r_n38.n38_ganado_per  = fl_retorna_precision_valor(r_n30.n30_mon_sueldo,
							tot_gan)
LET r_n38.n38_valor_fondo = fl_retorna_precision_valor(r_n30.n30_mon_sueldo,
							valor)
LET r_n38.n38_moneda      = r_n30.n30_mon_sueldo
LET r_n38.n38_paridad     = 1
LET r_n38.n38_pago_iess   = 'N'
LET r_n38.n38_usuario     = vg_usuario
LET r_n38.n38_fecing      = CURRENT
INSERT INTO rolt038 VALUES (r_n38.*)
RETURN valor, dias_fon

END FUNCTION



FUNCTION recalcular_tot_gan_por_dias_falt(r_n32)
DEFINE r_n32		RECORD LIKE rolt032.*
DEFINE valor1, valor2	LIKE rolt032.n32_tot_gan
DEFINE dias_falt	LIKE rolt032.n32_dias_falt
DEFINE fec_i, fec_f	DATE
DEFINE dias_mes		SMALLINT

SELECT NVL(n33_valor, 0) INTO dias_falt
	FROM rolt016, rolt006, rolt033
	WHERE n16_flag_ident = 'DF'
	  AND n06_flag_ident = n16_flag_ident
	  AND n06_estado     = 'A'
	  AND n33_compania   = r_n32.n32_compania
	  AND n33_cod_liqrol = r_n32.n32_cod_liqrol
	  AND n33_fecha_ini  = r_n32.n32_fecha_ini
	  AND n33_fecha_fin  = r_n32.n32_fecha_fin
	  AND n33_cod_trab   = r_n32.n32_cod_trab
	  AND n33_cod_rubro  = n06_cod_rubro
	  AND n33_valor      > 0
IF dias_falt = 0 THEN
	IF r_n32.n32_dias_falt = 0 THEN
		RETURN r_n32.n32_tot_gan
	END IF
END IF
LET r_n32.n32_dias_falt = dias_falt
LET fec_f    = MDY(r_n32.n32_mes_proceso, 01, r_n32.n32_ano_proceso)
		+ 1 UNITS MONTH - 1 UNITS DAY
LET fec_i    = MDY(r_n32.n32_mes_proceso, 01, r_n32.n32_ano_proceso)
LET dias_mes = fec_f - fec_i
LET dias_mes = dias_mes + 1
IF dias_mes = rm_n00.n00_dias_mes THEN
	RETURN r_n32.n32_tot_gan
END IF
LET valor1 = ((r_n32.n32_sueldo / dias_mes) * (dias_mes - r_n32.n32_dias_falt))
		- (r_n32.n32_sueldo / 2)
LET valor2 = ((r_n32.n32_sueldo / rm_n00.n00_dias_mes) *
		(rm_n00.n00_dias_mes - r_n32.n32_dias_falt))
		- (r_n32.n32_sueldo / 2)
LET r_n32.n32_tot_gan = r_n32.n32_tot_gan + (valor1 - valor2)
RETURN r_n32.n32_tot_gan

END FUNCTION



FUNCTION inserta_rubro_trabajador(r_n06, r_n32)
DEFINE r_n06		RECORD LIKE rolt006.* 
DEFINE r_n32		RECORD LIKE rolt032.*
DEFINE r_n33		RECORD LIKE rolt033.*
                                           
INITIALIZE r_n33.* TO NULL                                                
LET r_n33.n33_compania   = r_n32.n32_compania   
LET r_n33.n33_cod_liqrol = r_n32.n32_cod_liqrol 
LET r_n33.n33_fecha_ini  = r_n32.n32_fecha_ini  
LET r_n33.n33_fecha_fin  = r_n32.n32_fecha_fin  
LET r_n33.n33_cod_trab   = r_n32.n32_cod_trab   
LET r_n33.n33_cod_rubro  = r_n06.n06_cod_rubro  
LET r_n33.n33_orden      = r_n06.n06_orden      
LET r_n33.n33_det_tot    = r_n06.n06_det_tot    
LET r_n33.n33_imprime_0  = r_n06.n06_imprime_0  
LET r_n33.n33_cant_valor = r_n06.n06_cant_valor 
LET r_n33.n33_valor      = 0                    
INSERT INTO rolt033 VALUES (r_n33.*)            

END FUNCTION



FUNCTION verifica_rubros_especiales()

SELECT * FROM rolt006 WHERE n06_flag_ident = 'IR'                              
IF STATUS = NOTFOUND THEN                                        
	CALL fl_mostrar_mensaje('No esta configurado el rubro '  
			|| ' de IMPUESTO A LA RENTA.', 'stop') 
END IF                                                           
SELECT * FROM rolt006                                            
	WHERE n06_flag_ident = 'SI'                              
IF STATUS = NOTFOUND THEN                                        
	CALL fl_mostrar_mensaje('No esta configurado el rubro '  
			|| ' de INGRESO POR SOBREGIRO.', 'stop') 
END IF                                                           
SELECT * FROM rolt006                                            
	WHERE n06_flag_ident = 'SE'                              
IF STATUS = NOTFOUND THEN                                        
	CALL fl_mostrar_mensaje('No esta configurado el rubro '  
			|| ' de DESCUENTO POR SOBREGIRO.', 'stop') 
END IF                                                           

END FUNCTION



FUNCTION actualiza_detalle_liquidacion(valor, codcia, cod_liqrol, fecha_ini,
	fecha_fin, cod_trab, cod_rubro)
DEFINE valor		DECIMAL(12,2)
DEFINE codcia		LIKE rolt033.n33_compania
DEFINE cod_liqrol	LIKE rolt033.n33_cod_liqrol
DEFINE fecha_ini	LIKE rolt033.n33_fecha_ini
DEFINE fecha_fin	LIKE rolt033.n33_fecha_fin
DEFINE cod_trab		LIKE rolt033.n33_cod_trab
DEFINE cod_rubro	LIKE rolt033.n33_cod_rubro

UPDATE rolt033 SET n33_valor = valor
	WHERE n33_compania   = codcia   AND 
              n33_cod_liqrol = cod_liqrol AND 
              n33_fecha_ini  = fecha_ini  AND 
              n33_fecha_fin  = fecha_fin  AND 
              n33_cod_trab   = cod_trab   AND 
              n33_cod_rubro  = cod_rubro      

END FUNCTION



FUNCTION calcula_proyeccion_IR(r_n30, r_n32)
DEFINE 	r_n03		RECORD LIKE rolt003.*
DEFINE 	r_n06		RECORD LIKE rolt006.*
DEFINE 	r_rap		RECORD LIKE rolt006.*
DEFINE 	r_n08		RECORD LIKE rolt008.*
DEFINE 	r_n13		RECORD LIKE rolt013.*
DEFINE 	r_n15		RECORD LIKE rolt015.*
DEFINE 	r_n30		RECORD LIKE rolt030.*
DEFINE 	r_n32		RECORD LIKE rolt032.*

DEFINE quin_pag		SMALLINT
DEFINE sueldo		LIKE rolt032.n32_sueldo
DEFINE otros		LIKE rolt032.n32_sueldo
DEFINE ganado		LIKE rolt032.n32_sueldo
DEFINE valor		LIKE rolt032.n32_sueldo

DEFINE ir_anual		LIKE rolt032.n32_sueldo
DEFINE ir_pag		LIKE rolt032.n32_sueldo
DEFINE ir_quin		LIKE rolt032.n32_sueldo

DEFINE util_pag		LIKE rolt032.n32_sueldo
DEFINE deci_pag		LIKE rolt032.n32_sueldo
DEFINE vaca_pag		LIKE rolt032.n32_sueldo
DEFINE comi_pag		LIKE rolt032.n32_sueldo


INITIALIZE r_n06.* TO NULL
SELECT * INTO r_n06.* FROM rolt006 WHERE n06_flag_ident = 'IR' 
IF r_n06.n06_calculo = 'N' OR r_n06.n06_ing_usuario = 'S' THEN
	RETURN
END IF
SELECT * FROM rolt032
	WHERE n32_compania    = vg_codcia
	  AND n32_cod_trab    = r_n30.n30_cod_trab
	  AND n32_ano_proceso = r_n32.n32_ano_proceso
 	  AND n32_estado      IN ('A', 'C')
	INTO TEMP te_detliq

SELECT NVL(SUM(n33_valor), 0) INTO comi_pag
	FROM te_detliq, rolt033
	WHERE n32_compania    = vg_codcia
	  AND n32_cod_liqrol  = 'Q1'
	  AND n32_ano_proceso = r_n32.n32_ano_proceso
	  AND n32_mes_proceso = r_n32.n32_mes_proceso 
	  AND n33_compania    = n32_compania
	  AND n33_cod_liqrol  = n32_cod_liqrol
	  AND n33_fecha_ini   = n32_fecha_ini 
	  AND n33_fecha_fin   = n32_fecha_fin 
	  AND n33_cod_trab    = n32_cod_trab  
	  AND n33_cod_rubro IN (
		SELECT n06_cod_rubro FROM rolt006 WHERE n06_flag_ident = 'CO' 
	  )

IF comi_pag > 0 AND r_n32.n32_cod_liqrol = 'Q2' THEN
	DROP TABLE te_detliq
	RETURN	
END IF

INITIALIZE r_n06.* TO NULL
SELECT * INTO r_n06.* FROM rolt006 WHERE n06_flag_ident = 'IR' 
IF r_n06.n06_cod_rubro IS NULL THEN
	DROP TABLE te_detliq
	RETURN 
END IF

CALL actualiza_detalle_liquidacion(0,                    r_n32.n32_compania, 
				   r_n32.n32_cod_liqrol, r_n32.n32_fecha_ini, 
 				   r_n32.n32_fecha_fin,  r_n32.n32_cod_trab,  
				   r_n06.n06_cod_rubro)

SELECT COUNT(n32_cod_liqrol) INTO quin_pag FROM te_detliq

INITIALIZE r_rap.* TO NULL
SELECT * INTO r_rap.* FROM rolt006 WHERE n06_flag_ident = 'AP' 

DECLARE q_rubir CURSOR FOR 
	SELECT * FROM rolt008 WHERE n08_cod_rubro = r_n06.n06_cod_rubro

LET sueldo = 0
LET otros  = 0
FOREACH q_rubir INTO r_n08.*
	SELECT SUM(n33_valor) INTO valor
		FROM te_detliq, rolt033
		WHERE n33_compania   = n32_compania
		  AND n33_cod_liqrol = n32_cod_liqrol
		  AND n33_fecha_ini  = n32_fecha_ini 
		  AND n33_fecha_fin  = n32_fecha_fin 
		  AND n33_cod_trab   = n32_cod_trab  
		  AND n33_cod_rubro  = r_n08.n08_rubro_base 
	IF valor = 0 OR valor IS NULL THEN
		CONTINUE FOREACH
	END IF
	SELECT * FROM rolt008 WHERE n08_cod_rubro  = r_rap.n06_cod_rubro
				AND n08_rubro_base = r_n08.n08_rubro_base 	
	IF STATUS = NOTFOUND THEN
		LET otros = otros + valor
	ELSE
		LET sueldo = sueldo + valor
	END IF
END FOREACH
CLOSE q_rubir
FREE  q_rubir

LET sueldo = sueldo / quin_pag   	-- Promedio Quincenal 
LET sueldo = sueldo * 24	   	-- Promedio Anual 

-- Si se le hace algun descuento por concepto seguro social
CALL fl_lee_seguro_social(r_n30.n30_cod_seguro) RETURNING r_n13.*
IF r_n13.n13_cod_seguro IS NOT NULL THEN
	LET sueldo = sueldo * (1 - (r_n13.n13_porc_trab / 100)) 
END IF

SELECT NVL(SUM(n36_valor_neto), 0) INTO deci_pag 
	FROM rolt036
        WHERE n36_compania    = vg_codcia
          AND n36_proceso     IN ('DT', 'DC')
          AND n36_ano_proceso = r_n32.n32_ano_proceso
	  AND n36_mes_proceso = r_n32.n32_mes_proceso 
	  AND n36_fecing      BETWEEN r_n32.n32_fecha_ini
			          AND r_n32.n32_fecha_fin
          AND n36_cod_trab    = r_n30.n30_cod_trab
          AND n36_estado      = 'P'

SELECT NVL(SUM(n42_val_trabaj + n42_val_cargas - n42_descuentos), 0)
        INTO util_pag 
        FROM rolt041, rolt042
        WHERE n41_compania = vg_codcia
	  AND n41_ano      = r_n32.n32_ano_proceso
	  AND n41_fecing   BETWEEN r_n32.n32_fecha_ini AND r_n32.n32_fecha_fin
	  AND n41_estado   = 'P'
	  AND n42_compania = n41_compania
          AND n42_ano      = n41_ano
          AND n42_cod_trab = r_n30.n30_cod_trab

-- Falta agregar calculo de vacaciones
LET vaca_pag = 0

LET ganado = sueldo + otros + deci_pag + util_pag + vaca_pag 

INITIALIZE r_n15.* TO NULL
SELECT * INTO r_n15.* FROM rolt015
	WHERE n15_ano = r_n32.n32_ano_proceso
          AND ganado BETWEEN n15_base_imp_ini AND n15_base_imp_fin

LET ir_anual = r_n15.n15_fracc_base 
LET ir_anual = ir_anual + ((ganado - r_n15.n15_base_imp_ini) 
                        * (r_n15.n15_porc_ir / 100))

SELECT NVL(SUM(n33_valor), 0) INTO ir_pag
	FROM te_detliq, rolt033
	WHERE n33_compania   = n32_compania
	  AND n33_cod_liqrol = n32_cod_liqrol
	  AND n33_fecha_ini  = n32_fecha_ini 
	  AND n33_fecha_fin  = n32_fecha_fin 
	  AND n33_cod_trab   = n32_cod_trab  
	  AND n33_cod_rubro  = r_n06.n06_cod_rubro 

LET ir_quin = ir_anual - ir_pag		-- IR por cancelar en lo que queda 
					-- del a¤o
LET ir_quin = ir_quin / (24 - quin_pag) -- proyeccion IR quincenal 


IF comi_pag > 0 THEN
	LET ir_quin = ir_quin * 2
END IF

IF ir_quin < 0 THEN
	LET ir_quin = 0
END IF
	
CALL actualiza_detalle_liquidacion(ir_quin,              r_n32.n32_compania, 
				   r_n32.n32_cod_liqrol, r_n32.n32_fecha_ini, 
 				   r_n32.n32_fecha_fin,  r_n32.n32_cod_trab,  
				   r_n06.n06_cod_rubro)

DROP TABLE te_detliq

END FUNCTION
