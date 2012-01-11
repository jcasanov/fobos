{*
 * Titulo           : repp232.4gl - Refacturacion para cambio de fecha
 * Elaboracion      : 13-dic-2009
 * Autor            : JCM
 * Formato Ejecucion: fglrun repp232 base modulo compania localidad
 *}
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_rows ARRAY[1000] OF INTEGER  	-- ARREGLO DE ROWID DE FILAS LEIDAS
DEFINE vm_row_current	SMALLINT	-- FILA CORRIENTE DEL ARREGLO
DEFINE vm_num_rows	SMALLINT	-- CANTIDAD DE FILAS LEIDAS

DEFINE vm_flag_mant	CHAR(1)
DEFINE vm_max_elm	SMALLINT	
DEFINE vm_num_elm	SMALLINT	-- NUMERO MAXIMO DE ELEMENTOS DEL 
						        -- ARREGLO

DEFINE vm_cod_fact_ant		LIKE rept019.r19_cod_tran
DEFINE vm_cod_fact_nue		LIKE rept019.r19_cod_tran
DEFINE vm_num_fact_ant		LIKE rept019.r19_num_tran
DEFINE vm_num_fact_nue		LIKE rept019.r19_num_tran

DEFINE r_detalle ARRAY[100] OF RECORD
	r20_cant_ven		LIKE rept020.r20_cant_ven,
	r20_item			LIKE rept020.r20_item,
	tit_item			LIKE rept010.r10_nombre,
	r20_precio			LIKE rept020.r20_precio,
	subtotal			LIKE rept019.r19_tot_bruto
END RECORD

DEFINE rm_fact_ant			RECORD LIKE rept019.*



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/repp232.error')
CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 THEN          -- Validar # parámetros correcto
	CALL fgl_winmessage(vg_producto, 'Número de parámetros incorrecto', 'stop')
	EXIT PROGRAM
END IF
LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_codcia   = arg_val(3)
LET vg_codloc   = arg_val(4)
LET vg_proceso  = 'repp232'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)

CALL funcion_master()

END MAIN



FUNCTION funcion_master()

CALL fl_nivel_isolation()
CALL fl_chequeo_mes_proceso_rep(vg_codcia) RETURNING int_flag 
IF int_flag THEN
	RETURN
END IF

LET vm_num_rows = 0
LET vm_row_current = 0
LET vm_max_elm   = 100
LET vm_cod_fact_ant = 'FA'
LET vm_cod_fact_nue = 'FA'

OPTIONS
	INPUT WRAP,
	ACCEPT KEY F12,
	INSERT KEY F30,
	DELETE KEY F31

OPEN WINDOW w_repp232 AT 3,2 WITH 22 ROWS, 80 COLUMNS
	ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE 0,
		  BORDER, MESSAGE LINE LAST - 2) 
OPEN FORM f_repp232 FROM '../forms/repf232_1'
DISPLAY FORM f_repp232

CALL control_display_botones()
CALL muestra_contadores()

MENU 'OPCIONES'
{
	BEFORE MENU	
		HIDE OPTION 'Ver Detalle'
		HIDE OPTION 'Ver Factura'
		HIDE OPTION 'Avanzar'
		HIDE OPTION 'Retroceder'
		IF num_args() = 6 THEN
			HIDE OPTION 'Consultar'
			HIDE OPTION 'Ingresar'
			SHOW OPTION 'Ver Factura'
                	
			IF fl_control_permiso_opcion('Imprimir') THEN
			   SHOW OPTION 'Imprimir'
		   	END IF
			CALL control_consulta()
			IF vm_ind_arr > fgl_scr_size('r_detalle') THEN
				SHOW OPTION 'Ver Detalle'
			END IF
		END IF
}
	COMMAND KEY('I') 'Ingresar' 		'Ingresar nuevos registros.'
		CALL control_ingreso()
		IF vm_num_rows >= 1 THEN
			SHOW OPTION 'Ver Factura'
			SHOW OPTION 'Ver Detalle'
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
		END IF
        COMMAND KEY('C') 'Consultar'            'Consultar un registro.'
--             CALL control_consulta()
                IF vm_num_rows <= 1 THEN
                        HIDE OPTION 'Avanzar'
                        HIDE OPTION 'Retroceder'
			IF vm_num_rows = 1 THEN
				SHOW OPTION 'Ver Factura'
				SHOW OPTION 'Ver Detalle'
			END IF 
                ELSE
			SHOW OPTION 'Ver Detalle'
			SHOW OPTION 'Ver Factura'
                        SHOW OPTION 'Avanzar'
                END IF
	COMMAND KEY('F') 'Ver Factura' 		'Ver Factura de la Transacción.'
		IF vm_num_rows > 0 THEN
--			CALL control_ver_factura(rm_fact_ant.r19_num_tran)
		ELSE 
			CALL fl_mensaje_consultar_primero()
		END IF
	COMMAND KEY('V') 'Ver Detalle' 		'Ver Detalle de la Transacción.'
		IF vm_num_rows > 0 THEN
--			CALL control_ver_detalle()
		ELSE 
			CALL fl_mensaje_consultar_primero()
		END IF 
	COMMAND KEY('A') 'Avanzar' 		'Ver siguiente registro.'
--		CALL siguiente_registro()
		IF vm_row_current = vm_num_rows THEN
			SHOW OPTION 'Ver Detalle'
			SHOW OPTION 'Ver Factura'
			HIDE OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
			NEXT OPTION 'Retroceder'
		ELSE
			SHOW OPTION 'Ver Detalle'
			SHOW OPTION 'Ver Factura'
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
		END IF
	COMMAND KEY('R') 'Retroceder' 		'Ver anterior registro.'
--		CALL anterior_registro()
		IF vm_row_current = 1 THEN
			SHOW OPTION 'Ver Detalle'
			SHOW OPTION 'Ver Factura'
			HIDE OPTION 'Retroceder'
			SHOW OPTION 'Avanzar'
			NEXT OPTION 'Avanzar'
		ELSE
			SHOW OPTION 'Ver Detalle'
			SHOW OPTION 'Ver Factura'
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
		END IF
	COMMAND KEY('S') 'Salir'    		'Salir del programa.'
		EXIT MENU
END MENU

CLOSE WINDOW w_repp232

END FUNCTION



FUNCTION control_ingreso()
DEFINE valor_aplicado	DECIMAL(14,2)	
DEFINE numprev			LIKE rept023.r23_numprev

DEFINE r_dev			RECORD LIKE rept019.*
DEFINE r_g20			RECORD LIKE gent020.*
DEFINE r_r23			RECORD LIKE rept023.*
DEFINE r_z21			RECORD LIKE cxct021.*

CLEAR FORM
LET vm_flag_mant = 'I'
CALL control_display_botones()

INITIALIZE rm_fact_ant.*, rm_fact_ant.* TO NULL
DISPLAY BY NAME vm_cod_fact_ant, vm_cod_fact_nue

{*
 * Condiciones para el cambio de fecha:
 * - La factura no puede tener ninguna DF, AF ni NI
 * (Esto no se esta haciendo, lo agrego solo si me lo piden)  
 *}
CALL lee_datos()
IF INT_FLAG THEN
	IF vm_num_rows = 0 THEN
		CLEAR FORM
		CALL control_display_botones()
	ELSE	
		LET vm_flag_mant = 'C'
		CLEAR FORM
		CALL control_display_botones()
		CALL lee_muestra_registro(vm_rows[vm_row_current])
	END IF
	RETURN
END IF

-- Esta transaccion solo se la abre para poder bloquear el registro y
-- protejerlo de modificaciones.
BEGIN WORK
	WHENEVER ERROR CONTINUE
	DECLARE q_read_r19 CURSOR FOR 
		SELECT * FROM rept019
		 WHERE r19_compania  = vg_codcia
		   AND r19_localidad = vg_codloc
		   AND r19_cod_tran  = rm_fact_ant.r19_cod_tran
		   AND r19_num_tran  = rm_fact_ant.r19_num_tran
		FOR UPDATE

	OPEN q_read_r19
	FETCH q_read_r19
	IF status < 0 THEN
		WHENEVER ERROR STOP
		ROLLBACK WORK
		CALL fl_mensaje_bloqueo_otro_usuario()
		RETURN
	END IF
	WHENEVER ERROR STOP

	LET vm_num_elm = control_cargar_detalle_factura()

	LET int_flag = 0
	CALL muestra_detalles() 
	IF int_flag THEN
		ROLLBACK WORK
		IF vm_num_rows = 0 THEN
			CLEAR FORM
			CALL control_display_botones()
		ELSE	
			LET vm_flag_mant = 'C'
			CLEAR FORM
			CALL control_display_botones()
			CALL lee_muestra_registro(vm_rows[vm_row_current])
		END IF
		RETURN
	END IF

{*
 * Obtengo el numero de la preventa, sino existe no haga nada.
 * Esto podría hacerlo fuera de la transacción pero cada segundo que no
 * haya un bloqueo protegiendo el registro es un peligro quiero soltarlo
 * solo cuando sea estrictamente necesario
 *}
INITIALIZE r_r23.* TO NULL
SELECT * INTO r_r23.*
  FROM rept023
 WHERE r23_compania  = rm_fact_ant.r19_compania
   AND r23_localidad = rm_fact_ant.r19_localidad
   AND r23_estado    = 'F'
   AND r23_cod_tran  = rm_fact_ant.r19_cod_tran
   AND r23_num_tran  = rm_fact_ant.r19_num_tran

IF r_r23.r23_compania IS NULL THEN
	ROLLBACK WORK
	CALL fgl_winmessage(vg_producto, 'Factura no vino de una preventa.',
						'exclamation')
	IF vm_num_rows <= 1 THEN
		LET vm_num_rows = 0
		LET vm_row_current = 0
		CLEAR FORM
		CALL control_display_botones()
	ELSE
		LET vm_num_rows = vm_num_rows - 1
		LET vm_row_current = vm_num_rows
		CALL lee_muestra_registro(vm_rows[vm_row_current])
	END IF
	RETURN
END IF 
-- Solo lo necesitaba para verificar, limpio el record por si acaso
INITIALIZE r_r23.* TO NULL

{*
 * Antes de llamar al programa de devolucion debo cerrar la transaccion
 * porque ese programa abre sus propias transacciones
 * Uso COMMIT solo porque hasta ahora no ha ocurrido ningun error y 
 * conceptualmente es lo correcto, pero como aun no han ocurrido operaciones 
 * de modificación en la base de datos debería ser irrelevante.
 *}
COMMIT WORK

{*
 * Se usaran las aplicaciones ya existentes para evitar duplicar código
 * y para ahorrarme trabajo.
 *}
CALL genera_devolucion()
INITIALIZE r_dev.* TO NULL
SELECT * INTO r_dev.*
  FROM rept019
 WHERE r19_compania  = rm_fact_ant.r19_compania
   AND r19_localidad = rm_fact_ant.r19_localidad
   AND r19_tipo_dev  = rm_fact_ant.r19_cod_tran
   AND r19_num_dev   = rm_fact_ant.r19_num_tran

IF r_dev.r19_compania IS NULL THEN
	CALL fgl_winmessage(vg_producto, 'No se pudo realizar la devolución.',
						'exclamation')
	IF vm_num_rows <= 1 THEN
		LET vm_num_rows = 0
		LET vm_row_current = 0
		CLEAR FORM
		CALL control_display_botones()
	ELSE
		LET vm_num_rows = vm_num_rows - 1
		LET vm_row_current = vm_num_rows
		CALL lee_muestra_registro(vm_rows[vm_row_current])
	END IF
	RETURN
END IF 

CALL copia_preventa() RETURNING numprev

-- Esto se hace para que al facturar sepa cuanto esta realmente pendiente 
-- de despacho
CALL enlaza_entregas_a_preventa(numprev)
CALL genera_factura(numprev)

-- Obtengo la preventa para saber que factura se genero
CALL fl_lee_preventa_rep(vg_codcia, vg_codloc, numprev) RETURNING r_r23.*
LET vm_num_fact_nue = r_r23.r23_num_tran
DISPLAY BY NAME vm_num_fact_nue

-- Creo el enlace entre la factura anterior y la nueva
INSERT INTO rept119
VALUES (vg_codcia, vg_codloc, vm_cod_fact_ant, vm_num_fact_ant,
		r_r23.r23_cod_tran, r_r23.r23_num_tran)

CALL fl_lee_grupo_linea(vg_codcia, r_r23.r23_grupo_linea) RETURNING r_g20.*
CALL imprime_comprobante(r_r23.*)

{* XXX arreglar
 * Aplico la NC que se genero a la nueva factura
 *
 * Claro que para eso debo primero obtener la NC y eso esta dificil por
 * que no hay una relación de la NC con la DF. Asi que lo que voy a hacer
 * es sacar la última NC generada para este cliente en esta localidad,
 * de esta area de negocio, que sea de origen automatico y subtipo 1.
 * Ah, si... y que tenga saldo. 
INITIALIZE r_z21.* TO NULL
SQL 
	SELECT FIRST 1 * INTO $r_z21.*
	  FROM cxct021
	 WHERE z21_compania  = $vg_codcia
	   AND z21_localidad = $vg_codloc
	   AND z21_codcli    = $r_r23.r23_codcli
	   AND z21_tipo_doc  = 'NC'
	   AND z21_areaneg   = $r_g20.g20_areaneg
	   AND z21_saldo     > 0 
	   AND z21_subtipo   = 1
	   AND z21_origen    = 'A'
	 ORDER BY 1, 2, 3, 4, 5 DESC
END SQL
IF r_z21.z21_compania IS NOT NULL THEN

	-- Inicio una nueva transacción
	BEGIN WORK
	CALL fl_aplica_documento_favor(vg_codcia, vg_codloc, r_z21.z21_codcli, 
								   r_z21.z21_tipo_doc,   r_z21.z21_num_doc, 
								   r_r23.r23_tot_neto, 	 r_z21.z21_moneda, 
								   r_g20.g20_areaneg,    r_r23.r23_cod_tran, 
								   r_r23.r23_num_tran)  
		RETURNING valor_aplicado

	UPDATE cxct021 SET z21_saldo = z21_saldo - valor_aplicado
	 WHERE z21_compania  = r_z21.z21_compania
	   AND z21_localidad = r_z21.z21_localidad
	   AND z21_codcli    = r_z21.z21_codcli
	   AND z21_tipo_doc  = r_z21.z21_tipo_doc
	   AND z21_num_doc   = r_z21.z21_num_doc

	COMMIT WORK
END IF
CALL fl_genera_saldos_cliente(vg_codcia, vg_codloc, r_z21.z21_codcli)
 *}

CALL muestra_contadores()
CALL fl_mensaje_registro_ingresado()

END FUNCTION



FUNCTION lee_datos()

DEFINE resp 			CHAR(6)
DEFINE done				SMALLINT
DEFINE devueltas		SMALLINT
DEFINE r_r19			RECORD LIKE rept019.*

LET int_flag = 0
INPUT BY NAME vm_num_fact_ant WITHOUT DEFAULTS
	ON KEY (INTERRUPT)
		LET INT_FLAG = 0
		CALL fl_mensaje_abandonar_proceso() RETURNING resp
		IF resp = 'Yes' THEN
			LET int_flag = 1
			RETURN
		END IF
{
	ON KEY(F5)
		IF INFIELD(vm_num_fact_ant) THEN
			IF vm_num_fact_ant IS NOT NULL THEN
				CALL control_ver_factura(vm_num_fact_ant)
			END IF
		END IF
}
	ON KEY(F2)
		IF INFIELD(vm_num_fact_ant) THEN
			CALL fl_ayuda_transaccion_rep(vg_codcia, vg_codloc, vm_cod_fact_ant)
				RETURNING r_r19.r19_cod_tran, r_r19.r19_num_tran,
						  r_r19.r19_nomcli 
		      	IF r_r19.r19_num_tran IS NOT NULL THEN
					CALL fl_lee_cabecera_transaccion_rep(vg_codcia,
														 vg_codloc,
														 r_r19.r19_cod_tran,
														 r_r19.r19_num_tran)
						RETURNING r_r19.*
						LET vm_num_fact_ant = r_r19.r19_num_tran
						DISPLAY BY NAME vm_num_fact_ant
--						CALL control_display_cabecera()
		      	END IF
		END IF
	AFTER FIELD vm_num_fact_ant
		IF vm_num_fact_ant IS NULL THEN
			NEXT FIELD vm_num_fact_ant
		END IF

		CALL fl_lee_cabecera_transaccion_rep(vg_codcia,
											 vg_codloc,
											 vm_cod_fact_ant,
											 vm_num_fact_ant)
			RETURNING r_r19.*
       	IF r_r19.r19_num_tran IS  NULL THEN
    		CALL fgl_winmessage(vg_producto, 'La factura no existe en la Compañía. ',
								'exclamation')
           	NEXT FIELD vm_num_fact_ant
		END IF


{* -- Se quito esta restriccion porque refacturan por "cambio de fecha" incluso cosas de
 *    hace un año
 *
 *		IF MONTH(r_r19.r19_fecing + 1 UNITS MONTH) <> MONTH(TODAY)
 *		THEN
 *			CALL fgl_winmessage(vg_producto,'Solo puede refacturar facturas del mes anterior.',
 *								'exclamation')
 *			NEXT FIELD vm_num_fact_ant
 *		END IF
 *}

		-- Se verifica que no existan devoluciones para la factura
		SELECT COUNT(*) FROM rept019
		 WHERE r19_compania  = vg_codcia
		   AND r19_localidad = vg_codloc
		   AND r19_cod_tran  IN ('DF', 'AF', 'NI')
		   AND r19_tipo_dev  = vm_cod_fact_ant
		   AND r19_num_dev   = vm_num_fact_ant

		IF devueltas > 0 THEN
			CALL fgl_winmessage(vg_producto,'No puede refacturar una factura devuelta.',
								'exclamation')
			NEXT FIELD vm_num_fact_ant
		END IF
END INPUT
LET rm_fact_ant.* = r_r19.*
CALL control_display_cabecera()

END FUNCTION



FUNCTION control_display_botones()

DISPLAY 'Cant.'		   TO tit_col1
DISPLAY 'Item'		   TO tit_col2
DISPLAY 'Descripción'  TO tit_col3
DISPLAY 'Precio Unit.' TO tit_col4
DISPLAY 'Subtotal'	   TO tit_col5

END FUNCTION



FUNCTION control_display_cabecera()
DEFINE r_r01		RECORD LIKE rept001.*

DISPLAY BY NAME rm_fact_ant.r19_porc_impto, rm_fact_ant.r19_codcli,     
				rm_fact_ant.r19_nomcli,     rm_fact_ant.r19_dircli,  
				rm_fact_ant.r19_vendedor ,  rm_fact_ant.r19_telcli,
				rm_fact_ant.r19_tot_dscto,  rm_fact_ant.r19_tot_bruto,
				rm_fact_ant.r19_tot_neto

DISPLAY (rm_fact_ant.r19_tot_bruto - rm_fact_ant.r19_tot_dscto) * rm_fact_ant.r19_descuento / 100
	 TO t_impuesto

CALL fl_lee_vendedor_rep(vg_codcia, rm_fact_ant.r19_vendedor)
	RETURNING r_r01.*
DISPLAY r_r01.r01_nombres TO tit_vend

END FUNCTION



FUNCTION muestra_contadores()

DISPLAY "" AT 1,1
DISPLAY vm_row_current, " de ", vm_num_rows AT 1, 67 

END FUNCTION



FUNCTION lee_muestra_registro(row)
DEFINE row 		INTEGER
{

IF vm_num_rows <= 0 THEN
	RETURN
END IF
SELECT * INTO rm_r19.* FROM rept019 WHERE ROWID = row
IF STATUS = NOTFOUND THEN
	ERROR 'No existe registro con rowid', row
END IF

LET vm_impuesto = rm_r19.r19_tot_neto - rm_r19.r19_flete -  
		  (rm_r19.r19_tot_bruto - rm_r19.r19_tot_dscto)

	---PARA MOSTRAR LA CABECERA-----
DISPLAY BY NAME rm_r19.r19_cod_tran,   rm_r19.r19_num_tran, rm_r19.r19_usuario,
		rm_r19.r19_vendedor,   rm_r19.r19_bodega_ori, 
		rm_r19.r19_tot_neto,   rm_r19.r19_moneda, 
		rm_r19.r19_porc_impto, rm_r19.r19_cont_cred, rm_r19.r19_codcli,
		rm_r19.r19_nomcli,     
		rm_r19.r19_tot_bruto,  rm_r19.r19_tot_dscto, vm_impuesto,
		rm_r19.r19_tipo_dev,   rm_r19.r19_num_dev, rm_r19.r19_fecing ,
		rm_r19.r19_referencia

CALL muestra_etiquetas()
CALL muestra_contadores()
CALL muestra_detalle()
}
END FUNCTION



FUNCTION control_cargar_detalle_factura()
DEFINE r_r20 	RECORD LIKE rept020.*
DEFINE r_r10 	RECORD LIKE rept010.*
DEFINE i 		SMALLINT

DECLARE q_read_r20 CURSOR FOR 
	SELECT * FROM rept020
	 WHERE r20_compania  = vg_codcia
	   AND r20_localidad = vg_codloc
	   AND r20_cod_tran  = rm_fact_ant.r19_cod_tran
	   AND r20_num_tran  = rm_fact_ant.r19_num_tran 

LET i = 1 
FOREACH q_read_r20 INTO r_r20.*

	CALL fl_lee_item(vg_codcia, r_r20.r20_item)
		RETURNING r_r10.*

	LET r_detalle[i].r20_cant_ven = r_r20.r20_cant_ven 	  
	LET r_detalle[i].r20_item     = r_r20.r20_item 
	LET r_detalle[i].tit_item     = r_r10.r10_nombre
	LET r_detalle[i].r20_precio   = r_r20.r20_precio 
	LET r_detalle[i].subtotal     = r_r20.r20_cant_ven * r_r20.r20_precio
	LET i = i + 1

	IF i > vm_max_elm THEN
		CALL fl_mensaje_arreglo_lleno()
		RETURN vm_max_elm
		EXIT FOREACH
	END IF
END FOREACH

RETURN i - 1

END FUNCTION



FUNCTION muestra_detalles()
DEFINE resp		CHAR(6)

OPTIONS 
	INSERT KEY F30,
	DELETE KEY F31

LET int_flag = 0
CALL set_count(vm_num_elm)
DISPLAY ARRAY r_detalle TO r_detalle.*

END FUNCTION



FUNCTION genera_devolucion()

DEFINE comando		CHAR(255)

LET comando = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', 
	vg_separador, 'fuentes', vg_separador, '; fglrun repp217 ', vg_base, 
	' ', 'RE', vg_codcia, ' ', vg_codloc, ' ', vm_cod_fact_ant,
	vm_num_fact_ant
	
RUN comando	

END FUNCTION



FUNCTION copia_preventa()
DEFINE numprev		LIKE rept023.r23_numprev
DEFINE r_prev		RECORD LIKE rept023.*
DEFINE query		VARCHAR(2000)

INITIALIZE r_prev.* TO NULL
SELECT * INTO r_prev.*
  FROM rept023
 WHERE r23_compania  = vg_codcia
   AND r23_localidad = vg_codloc
   AND r23_estado    = "F" 
   AND r23_cod_tran  = vm_cod_fact_ant
   AND r23_num_tran  = vm_num_fact_ant

SELECT MAX(r23_numprev) + 1 INTO numprev
  FROM rept023
 WHERE r23_compania  = vg_codcia
   AND r23_localidad = vg_codloc
                                                                                
IF numprev IS NULL THEN
 	LET numprev = 1
END IF

LET query = 'INSERT INTO rept023(r23_compania, r23_localidad, r23_numprev, ',
								'r23_estado, r23_grupo_linea, r23_ped_cliente, ',
								'r23_cont_cred, r23_referencia, r23_codcli, ',
								'r23_nomcli, r23_dircli, r23_telcli, r23_cedruc, ',
								'r23_ord_compra, r23_vendedor, r23_descuento, ',
								'r23_porc_impto, r23_bodega, r23_moneda, ',
				  				'r23_paridad, r23_precision, r23_tot_costo, r23_tot_bruto, ',
				  				'r23_tot_dscto, r23_tot_neto, r23_flete, r23_usuario, ',
								'r23_fecing) ', 
			'SELECT r23_compania, r23_localidad, ', numprev, ', "P", ',
				  ' r23_grupo_linea, r23_ped_cliente, r23_cont_cred, ',
				  ' r23_referencia, r23_codcli, r23_nomcli, r23_dircli, ',
				  ' r23_telcli, r23_cedruc, r23_ord_compra, r23_vendedor, ',
				  ' r23_descuento, r23_porc_impto, r23_bodega, r23_moneda, ',
				  ' r23_paridad, r23_precision, r23_tot_costo, r23_tot_bruto, ',
				  ' r23_tot_dscto, r23_tot_neto, r23_flete, ',
				  '"', vg_usuario CLIPPED, '", CURRENT',
		 	'  FROM rept023 ',
			' WHERE r23_compania  = ', vg_codcia,
			'   AND r23_localidad = ', vg_codloc,
			'   AND r23_numprev   = ', r_prev.r23_numprev

PREPARE stmt1 FROM query
EXECUTE stmt1

LET query = 'INSERT INTO rept024 ',
			'SELECT r24_compania, r24_localidad, ', numprev, ', r24_item, ',
				  ' r24_orden, r24_cant_ped, r24_cant_ven, r24_descuento, ',
				  ' r24_val_descto, r24_precio, r24_val_impto, r24_linea, ',
				  ' "N" ',
		 	'  FROM rept024 ',
			' WHERE r24_compania  = ', vg_codcia,
			'   AND r24_localidad = ', vg_codloc,
			'   AND r24_numprev   = ', r_prev.r23_numprev

PREPARE stmt2 FROM query
EXECUTE stmt2

LET query = 'INSERT INTO rept025(r25_compania, r25_localidad, r25_numprev, ', 
								'r25_valor_ant, r25_valor_cred, r25_interes, ',
								'r25_dividendos, r25_plazo) ',
			'SELECT r25_compania, r25_localidad, ', numprev, ', r25_valor_ant, ',
				  ' r25_valor_cred, r25_interes, r25_dividendos, r25_plazo ',
		 	'  FROM rept025 ',
			' WHERE r25_compania  = ', vg_codcia,
			'   AND r25_localidad = ', vg_codloc,
			'   AND r25_numprev   = ', r_prev.r23_numprev

PREPARE stmt3 FROM query
EXECUTE stmt3

LET query = 'INSERT INTO rept026 ',
			'SELECT r26_compania, r26_localidad, ', numprev, ', r26_dividendo, ',
				  ' r26_valor_cap, r26_valor_int, r26_fec_vcto ',
		 	'  FROM rept026 ',
			' WHERE r26_compania  = ', vg_codcia,
			'   AND r26_localidad = ', vg_codloc,
			'   AND r26_numprev   = ', r_prev.r23_numprev

PREPARE stmt4 FROM query
EXECUTE stmt4

-- Al copiar los documentos a aplicar ignora los PA, porque como ya fueron 
-- aplicados no tiene sentido
LET query = 'INSERT INTO rept027 ',
			'SELECT r27_compania, r27_localidad, ', numprev, ', r27_tipo, ',
				  ' r27_numero, r27_valor ',
		 	'  FROM rept027 ',
			' WHERE r27_compania  = ', vg_codcia,
			'   AND r27_localidad = ', vg_codloc,
			'   AND r27_numprev   = ', r_prev.r23_numprev,
			'   AND r27_tipo <> "PA" '

PREPARE stmt5 FROM query
EXECUTE stmt5

LET r_prev.r23_numprev = numprev

CALL control_actualizacion_caja(r_prev.*) 

RETURN numprev

END FUNCTION



FUNCTION control_actualizacion_caja(r_r23)
DEFINE r_r23 		RECORD LIKE rept023.*
DEFINE r_j10		RECORD LIKE cajt010.*
DEFINE r_g20		RECORD LIKE gent020.*

INITIALIZE r_j10.* TO NULL
CALL fl_lee_grupo_linea(vg_codcia, r_r23.r23_grupo_linea)
	RETURNING r_g20.*

LET r_j10.j10_areaneg     = r_g20.g20_areaneg
LET r_j10.j10_codcli      = r_r23.r23_codcli
LET r_j10.j10_nomcli      = r_r23.r23_nomcli
LET r_j10.j10_moneda      = r_r23.r23_moneda
LET r_j10.j10_valor       = r_r23.r23_tot_neto 
LET r_j10.j10_fecha_pro   = CURRENT
LET r_j10.j10_usuario     = vg_usuario 
LET r_j10.j10_fecing      = CURRENT
LET r_j10.j10_compania    = vg_codcia
LET r_j10.j10_localidad   = vg_codloc
LET r_j10.j10_tipo_fuente = 'PR'
LET r_j10.j10_num_fuente  = r_r23.r23_numprev
LET r_j10.j10_estado      = 'A'

INSERT INTO cajt010 VALUES(r_j10.*)

END FUNCTION



FUNCTION genera_factura(numprev)
DEFINE numprev		LIKE rept023.r23_numprev
DEFINE comando		CHAR(255)

LET comando = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', 
	vg_separador, 'fuentes', vg_separador, '; fglrun repp211 ', vg_base, 
	' ', vg_codcia, ' ', vg_codloc, ' ', numprev, ' S' 
	
RUN comando	

END FUNCTION



FUNCTION imprime_comprobante(r_r23)
DEFINE r_r23        RECORD LIKE rept023.*   -- Preventa Repuestos

DEFINE comando      VARCHAR(250)

LET comando = 'cd ..', vg_separador, '..', vg_separador,
              'REPUESTOS', vg_separador, 'fuentes',
              vg_separador, '; fglrun repp410_', vg_codloc USING '&',
              ' ', vg_base, ' ', 'RE', vg_codcia, ' ', vg_codloc,
              ' ', r_r23.r23_num_tran

RUN comando

END FUNCTION



FUNCTION enlaza_entregas_a_preventa(numprev)
DEFINE numprev 			LIKE rept023.r23_numprev
DEFINE query			VARCHAR(1000)

LET query = 'UPDATE rept118 SET r118_cod_fact = NULL,',
							'   r118_num_fact = NULL, ',   
							'   r118_numprev  = ', numprev,    
			' WHERE r118_compania  = ', vg_codcia,
			'   AND r118_localidad = ', vg_codloc,
			'   AND r118_cod_fact  = "', vm_cod_fact_ant, '"',
			'   AND r118_num_fact  = ', vm_num_fact_ant

PREPARE stmt6 FROM query
EXECUTE stmt6

END FUNCTION



FUNCTION validar_parametros()

CALL fl_lee_modulo(vg_modulo) RETURNING rg_mod.*
IF rg_mod.g50_modulo IS NULL THEN
	CALL fgl_winmessage(vg_producto, 'No existe módulo: ' || vg_modulo, 'stop')
	EXIT PROGRAM
END IF
CALL fl_lee_compania(vg_codcia) RETURNING rg_cia.*
IF rg_cia.g01_compania IS NULL THEN
	CALL fgl_winmessage(vg_producto, 'No existe compañía: '|| vg_codcia, 'stop')
	EXIT PROGRAM
END IF
IF rg_cia.g01_estado <> 'A' THEN
	CALL fgl_winmessage(vg_producto, 'Compañía no está activa: ' || vg_codcia, 'stop')
	EXIT PROGRAM
END IF
IF vg_codloc IS NULL THEN
	LET vg_codloc   = fl_retorna_agencia_default(vg_codcia)
END IF
CALL fl_lee_localidad(vg_codcia, vg_codloc) RETURNING rg_loc.*
IF rg_loc.g02_localidad IS NULL THEN
	CALL fgl_winmessage(vg_producto, 'No existe localidad: ' || vg_codloc, 'stop')
	EXIT PROGRAM
END IF
IF rg_loc.g02_estado <> 'A' THEN
	CALL fgl_winmessage(vg_producto, 'Localidad no está activa: '|| vg_codloc, 'stop')
	EXIT PROGRAM
END IF

END FUNCTION
