--------------------------------------------------------------------------------
-- Titulo           : ctbp409.4gl - Listado de Movimientos de Cuentas por FILTRO
-- Elaboracion      : 23-SEP-2002
-- Autor            : RCA
-- Formato Ejecucion: fglrun ctbp409 base módulo compañía localidad
-- Ultima Correccion: 
-- Motivo Correccion: 
--------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE rm_g13		RECORD LIKE gent013.*
DEFINE rm_z60		RECORD LIKE cxct060.*
DEFINE vm_top		SMALLINT
DEFINE vm_left		SMALLINT
DEFINE vm_right		SMALLINT
DEFINE vm_bottom	SMALLINT
DEFINE vm_page		SMALLINT
DEFINE tot_val_db	DECIMAL(14,2)
DEFINE tot_val_cr	DECIMAL(14,2)
DEFINE tot_val_db_c	DECIMAL(14,2)
DEFINE tot_val_cr_c	DECIMAL(14,2)
DEFINE tot_val_db_p	DECIMAL(14,2)
DEFINE tot_val_cr_p	DECIMAL(14,2)
DEFINE tot_val_db_d	DECIMAL(14,2)
DEFINE tot_val_cr_d	DECIMAL(14,2)
DEFINE tot_val_db_g	DECIMAL(14,2)
DEFINE tot_val_cr_g	DECIMAL(14,2)
DEFINE vm_cta_inicial	LIKE ctbt013.b13_cuenta
DEFINE nom_cta_ini	LIKE ctbt010.b10_descripcion
DEFINE vm_cliente	LIKE ctbt013.b13_codcli
DEFINE nom_cliente	LIKE cxct001.z01_nomcli
DEFINE vm_proveedor	LIKE ctbt013.b13_codprov
DEFINE nom_proveedor	LIKE cxpt001.p01_nomprov
DEFINE vm_pedido	LIKE ctbt013.b13_pedido
DEFINE vm_moneda	LIKE gent013.g13_moneda
DEFINE vm_fecha_ini	DATE
DEFINE vm_fecha_fin	DATE
DEFINE vm_fec_arran	DATE
DEFINE vm_fec_antes	DATE
DEFINE vm_saldo 	DECIMAL(14,2)
DEFINE vm_saldo_cli 	DECIMAL(14,2)
DEFINE vm_saldo_pro 	DECIMAL(14,2)
DEFINE vm_saldo_ped 	DECIMAL(14,2)
DEFINE vm_saldo_ini 	DECIMAL(14,2)
DEFINE vm_nivel         SMALLINT
DEFINE vm_incluir	CHAR(1)
DEFINE vm_ver_saldos	CHAR(1)



MAIN

DEFER QUIT 
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/ctbp409.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 THEN   -- Validar # parámetros correcto
	CALL fgl_winmessage(vg_producto, 'Número de parametros incorrecto.', 'stop')
	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_codloc  = arg_val(4)
LET vg_proceso = 'ctbp409'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
--#CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()

END MAIN



FUNCTION funcion_master()

CALL fl_nivel_isolation()
CALL fl_lee_fecha_carga_cxc(vg_codcia, vg_codloc) RETURNING rm_z60.*
IF rm_z60.z60_compania IS NULL THEN
	CALL fl_mostrar_mensaje('No existe una fecha de carga para este módulo.', 'stop')
	EXIT PROGRAM
END IF
OPEN WINDOW w_mas AT 3,2 WITH 15 ROWS, 80 COLUMNS
    ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE 0, BORDER,
	      MESSAGE LINE LAST - 2)
OPTIONS INPUT WRAP,
	ACCEPT KEY	F12
OPEN FORM f_rep FROM "../forms/ctbf409_1"
DISPLAY FORM f_rep
CALL borrar_cabecera()
CALL control_reporte()

END FUNCTION



FUNCTION control_reporte()
DEFINE r_rep		RECORD
				tipo_comp		CHAR(2),
				num_comp		CHAR(8),
				fec_proceso		DATE,
				--glosa			CHAR(35),
				glosa			VARCHAR(90,40),
				valor			DECIMAL(14,2),
				filtro			CHAR(11),
				flag_filtro		CHAR(1)
			END RECORD
DEFINE query		VARCHAR(1500)
DEFINE expr_cli		VARCHAR(100)
DEFINE expr_prov	VARCHAR(100)
DEFINE expr_ped		VARCHAR(100)
DEFINE expr_fec		VARCHAR(100)
DEFINE comando 		VARCHAR(100)
DEFINE val_db		DECIMAL(14,2)
DEFINE val_cr		DECIMAL(14,2)
DEFINE valor_mov	DECIMAL(14,2)
DEFINE codigo, i	INTEGER
DEFINE filtro		LIKE ctbt013.b13_pedido
DEFINE secuencia	LIKE ctbt013.b13_secuencia

LET vm_top    = 1
LET vm_left   = 0
LET vm_right  = 132
LET vm_bottom = 4
LET vm_page   = 66
LET vm_moneda = rg_gen.g00_moneda_base
CALL fl_lee_moneda(vm_moneda) RETURNING rm_g13.*
DISPLAY rm_g13.g13_nombre TO nom_moneda
LET vm_fecha_ini = TODAY
LET vm_fecha_fin = TODAY
SELECT MAX(b01_nivel) INTO vm_nivel FROM ctbt001
IF vm_nivel IS NULL THEN
	CALL fgl_winmessage(vg_producto,'Nivel no esta configurado.','stop')
	EXIT PROGRAM
END IF
LET vm_fec_arran  = rm_z60.z60_fecha_carga
LET vm_incluir    = 'N'
LET vm_ver_saldos = 'N'
WHILE TRUE
	LET vm_saldo = 0
	CALL lee_parametros()
	IF int_flag THEN
		EXIT WHILE
	END IF
	CALL fl_control_reportes() RETURNING comando
	IF int_flag THEN
		CONTINUE WHILE
	END IF
	LET expr_cli = NULL
	IF vm_cliente IS NOT NULL THEN
		LET expr_cli = '   AND b13_codcli       = ', vm_cliente
	END IF
	LET expr_prov = NULL
	IF vm_proveedor IS NOT NULL THEN
		LET expr_prov = '   AND b13_codprov      = ', vm_proveedor
	END IF
	LET expr_ped = NULL
	IF vm_pedido IS NOT NULL THEN 
		LET expr_ped = '   AND b13_pedido       = "', vm_pedido, '"'
	END IF
	LET expr_fec = '   AND b13_fec_proceso BETWEEN "', vm_fecha_ini,
						'" AND "', vm_fecha_fin, '"'
	IF vm_incluir = 'S' THEN
		LET expr_fec = '   AND b13_fec_proceso <= "', vm_fecha_fin, '"'
	END IF
	LET query = 'SELECT b13_tipo_comp, b13_num_comp, b13_fec_proceso,',
			' b13_glosa, b13_valor_base,',
			' LPAD(b13_codcli, 6, 0) codcli,',
			' LPAD(b13_codprov, 6, 0) codprov, b13_pedido, ',
			' b13_secuencia ',
			' FROM ctbt012, ctbt013 ',
			' WHERE b12_compania     = ', vg_codcia,
			'   AND b12_estado      <> "E" ',
			'   AND b12_moneda       = "', vm_moneda, '"',
			'   AND b13_compania     = b12_compania ',
			'   AND b13_tipo_comp    = b12_tipo_comp ',
			'   AND b13_num_comp     = b12_num_comp ',
			'   AND b13_cuenta       = "', vm_cta_inicial, '"',
			expr_fec CLIPPED,
			expr_cli CLIPPED,
			expr_prov CLIPPED,
			expr_ped CLIPPED,
			' INTO TEMP t1'
	PREPARE crear_t1 FROM query
	EXECUTE crear_t1
	SELECT COUNT(*) INTO i FROM t1
	IF i = 0 THEN
		DROP TABLE t1
		CALL fl_mensaje_consulta_sin_registros()
		CONTINUE WHILE
	END IF
	SELECT b13_tipo_comp, b13_num_comp, b13_fec_proceso, b13_glosa,
		b13_valor_base, b13_pedido b13_codcli, b13_pedido b13_codprov,
		b13_pedido b13_pedido, b13_secuencia
		FROM ctbt013
		WHERE b13_compania = 17
		INTO TEMP t2
	INSERT INTO t2 SELECT * FROM t1
	DROP TABLE t1
	LET query = 'SELECT b13_tipo_comp, b13_num_comp, b13_fec_proceso, ',
			' b13_glosa, b13_valor_base, ',
			' CASE WHEN b13_codcli IS NOT NULL THEN b13_codcli ',
			' WHEN b13_codprov IS NOT NULL THEN b13_codprov ',
			' WHEN b13_pedido IS NOT NULL THEN b13_pedido ',
			' ELSE "FILTRO NULO" ',
			' END filtro_cod, ',
			' CASE WHEN b13_codcli IS NOT NULL THEN "C" ',
			' WHEN b13_codprov IS NOT NULL THEN "P" ',
			' WHEN b13_pedido IS NOT NULL THEN "D" ',
			' ELSE "*" ',
			' END filtro_tipo, ',
			' b13_secuencia ',
			' FROM t2 ',
			' INTO TEMP t3 '
	PREPARE tmp_t3 FROM query
	EXECUTE tmp_t3
	DROP TABLE t2
	IF vm_incluir = 'S' THEN
		SELECT UNIQUE filtro_cod cod_tmp, MAX(b13_fec_proceso) fecha
			FROM t3
			WHERE b13_fec_proceso < vm_fecha_ini
			GROUP BY 1
			INTO TEMP t4
		DELETE FROM t3
			WHERE b13_fec_proceso < (SELECT fecha FROM t4
						 WHERE cod_tmp = filtro_cod)
		DROP TABLE t4
	END IF
	DECLARE q_filtro CURSOR FOR
		SELECT * FROM t3
			ORDER BY filtro_tipo ASC, filtro_cod ASC,
				b13_fec_proceso, b13_tipo_comp, b13_num_comp,
				b13_secuencia
	START REPORT report_movimientos_ctas TO PIPE comando
	LET tot_val_db   = 0
	LET tot_val_cr   = 0
	LET tot_val_db_c = 0
	LET tot_val_cr_c = 0
	LET tot_val_db_p = 0
	LET tot_val_cr_p = 0
	LET tot_val_db_d = 0
	LET tot_val_cr_d = 0
	LET tot_val_db_g = 0
	LET tot_val_cr_g = 0
	LET vm_saldo_cli = 0
	LET vm_saldo_pro = 0
	LET vm_saldo_ped = 0
	LET filtro       = NULL
	FOREACH q_filtro INTO r_rep.*, secuencia
		IF vm_incluir = 'S' THEN
			IF filtro IS NULL AND r_rep.fec_proceso < vm_fecha_ini
			THEN
				LET r_rep.tipo_comp = NULL
			END IF
		END IF
		IF filtro IS NULL OR filtro <> r_rep.filtro THEN
			LET vm_fec_antes = vm_fecha_ini - 1 UNITS DAY
			IF vm_fec_antes < vm_fec_arran THEN
				LET vm_fec_antes = vm_fec_arran
			END IF
			LET codigo = r_rep.filtro
			CALL retorna_saldo(r_rep.flag_filtro, codigo,
					r_rep.filtro,vm_fec_arran, vm_fec_antes)
				RETURNING vm_saldo_ini
		END IF
		LET val_db = 0
		LET val_cr = 0
		IF r_rep.fec_proceso >= vm_fecha_ini THEN
			LET val_db = r_rep.valor
			LET val_cr = 0
			IF r_rep.valor < 0 THEN
				LET val_db = 0
				LET val_cr = r_rep.valor
			END IF
			LET filtro = r_rep.filtro
		END IF
		OUTPUT TO REPORT report_movimientos_ctas(r_rep.*,val_db, val_cr)
	END FOREACH
	FINISH REPORT report_movimientos_ctas
	DROP TABLE t3
END WHILE 

END FUNCTION



FUNCTION lee_parametros()
DEFINE r_b10		RECORD LIKE ctbt010.*
DEFINE r_z01		RECORD LIKE cxct001.*
DEFINE r_p01		RECORD LIKE cxpt001.*
DEFINE r_pro		RECORD LIKE cxpt002.*
DEFINE fecha		VARCHAR(10)

OPTIONS INPUT NO WRAP
INITIALIZE r_b10.*, r_z01.*, r_p01.*, r_pro.* TO NULL
LET int_flag = 0
INPUT BY NAME 	vm_cta_inicial,	vm_moneda, vm_fecha_ini, vm_fecha_fin, 	
	        vm_cliente, vm_proveedor, vm_pedido, vm_incluir, vm_ver_saldos
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		LET int_flag = 1
		RETURN
	ON KEY(F2)
		IF INFIELD(vm_cta_inicial) THEN
			CALL fl_ayuda_cuenta_contable(vg_codcia, vm_nivel)
				RETURNING r_b10.b10_cuenta,r_b10.b10_descripcion
			IF r_b10.b10_cuenta IS NOT NULL THEN
				LET vm_cta_inicial = r_b10.b10_cuenta	
				DISPLAY BY NAME vm_cta_inicial
				DISPLAY r_b10.b10_descripcion TO nom_cta_ini
			END IF
		END IF
		IF INFIELD(vm_moneda) THEN
        		CALL fl_ayuda_monedas()
	               		RETURNING rm_g13.g13_moneda, rm_g13.g13_nombre,
					  rm_g13.g13_decimales
			IF rm_g13.g13_moneda IS NOT NULL THEN
				LET vm_moneda = rm_g13.g13_moneda
				DISPLAY BY NAME vm_moneda
				DISPLAY rm_g13.g13_nombre TO nom_moneda
			END IF
		END IF
		IF INFIELD(vm_cliente) THEN
			CALL fl_ayuda_cliente_general()
				RETURNING r_z01.z01_codcli, r_z01.z01_nomcli 
			IF r_z01.z01_codcli IS NOT NULL THEN
				LET vm_cliente  = r_z01.z01_codcli
				LET nom_cliente	= r_z01.z01_nomcli
				DISPLAY BY NAME vm_cliente, nom_cliente
			END IF
		END IF
		IF INFIELD(vm_proveedor) THEN
			CALL fl_ayuda_proveedores()
				RETURNING r_p01.p01_codprov, r_p01.p01_nomprov 
			IF r_p01.p01_codprov IS NOT NULL THEN
				LET vm_proveedor  = r_p01.p01_codprov
				LET nom_proveedor = r_p01.p01_nomprov
				DISPLAY BY NAME vm_proveedor, nom_proveedor
			END IF
		END IF
		LET int_flag = 0
	AFTER FIELD vm_cta_inicial
		IF vm_cta_inicial IS NOT NULL THEN
			CALL fl_lee_cuenta(vg_codcia, vm_cta_inicial) 
				RETURNING r_b10.*
			IF r_b10.b10_cuenta IS NULL THEN
				CALL fgl_winmessage(vg_producto,'No existe la cuenta en la Compañía.','exclamation')
				NEXT FIELD vm_cta_inicial
			END IF
			LET vm_cta_inicial = r_b10.b10_cuenta
			LET nom_cta_ini = r_b10.b10_descripcion
			DISPLAY BY NAME vm_cta_inicial, nom_cta_ini
		ELSE
			CLEAR nom_cta_ini
		END IF
	AFTER FIELD vm_moneda
		IF vm_moneda IS NOT NULL THEN
			CALL fl_lee_moneda(vm_moneda)
				RETURNING rm_g13.*
			IF rm_g13.g13_moneda IS NULL THEN
				CALL fgl_winmessage(vg_producto,'No existe la moneda en la Compañía.','exclamation')
				NEXT FIELD vm_moneda
			ELSE
				LET vm_moneda = rm_g13.g13_moneda
				DISPLAY BY NAME vm_moneda
				DISPLAY rm_g13.g13_nombre TO nom_moneda
			END IF
		ELSE
			CLEAR nom_moneda
		END IF
	AFTER FIELD vm_cliente
		IF vm_cliente IS NULL THEN
			CLEAR nom_cliente
		ELSE
			CALL fl_lee_cliente_general(vm_cliente) 
				RETURNING r_z01.*
			IF r_z01.z01_codcli IS NULL THEN
              			CALL fgl_winmessage(vg_producto,
                                                    'No existe un cliente '||
                                                    'con ese código',
                                                    'exclamation')
				NEXT FIELD vm_cliente
        		END IF   
			IF r_z01.z01_estado = 'B' THEN
              			CALL fgl_winmessage(vg_producto,
                                                    'El cliente '||
                                                    'está bloqueado',
                                                    'exclamation')
				NEXT FIELD vm_cliente
			END IF
			LET vm_cliente  = r_z01.z01_codcli
			LET nom_cliente	= r_z01.z01_nomcli
			DISPLAY BY NAME vm_cliente, nom_cliente
		END IF
	AFTER FIELD vm_proveedor
		IF vm_proveedor IS NOT NULL THEN
			CALL fl_lee_proveedor(vm_proveedor)
		 		RETURNING r_p01.*
			IF r_p01.p01_codprov IS NULL THEN
				CALL fgl_winmessage(vg_producto,'Proveedor no existe.','exclamation')
                                NEXT FIELD vm_proveedor
			END IF
			IF r_p01.p01_estado = 'B' THEN
                                CALL fl_mensaje_estado_bloqueado()
                                NEXT FIELD vm_proveedor
                        END IF		 
			LET vm_proveedor  = r_p01.p01_codprov
			LET nom_proveedor = r_p01.p01_nomprov
			DISPLAY BY NAME vm_proveedor, nom_proveedor
		ELSE
			CLEAR nom_proveedor
		END IF
	AFTER INPUT 
		IF vm_cta_inicial IS NULL THEN
			NEXT FIELD vm_cta_inicial
		END IF
		IF vm_fecha_ini IS NULL THEN
			NEXT FIELD vm_fecha_ini
		END IF
		IF vm_fecha_fin IS NULL THEN
			NEXT FIELD vm_fecha_fin
		END IF
		IF vm_fecha_ini > TODAY THEN
			CALL fl_mostrar_mensaje('La Fecha Inicial debe ser menor igual a la de hoy.','exclamation')
			NEXT FIELD vm_fecha_fin
		END IF
		IF vm_fecha_fin > TODAY THEN
			CALL fl_mostrar_mensaje('La Fecha Final debe ser menor igual a la de hoy.','exclamation')
			NEXT FIELD vm_fecha_fin
		END IF
		IF vm_fecha_ini > vm_fecha_fin THEN
			CALL fl_mostrar_mensaje('La Fecha Inicial debe ser menor igual a la Fecha Final.','exclamation')
			NEXT FIELD vm_fecha_fin
		END IF
		IF vm_fecha_ini < vm_fec_arran THEN
			LET fecha = vm_fec_arran USING "dd-mm-yyyy"
			CALL fgl_winmessage(vg_producto, 'La Fecha Inicial debe ser mayor igual al ' || fecha || ' que es la Fecha de Arranque del sistema.', 'info')
			LET vm_fecha_ini = vm_fec_arran
			DISPLAY BY NAME vm_fecha_ini
			NEXT FIELD vm_fecha_ini
		END IF
		IF vm_moneda IS NULL THEN
			NEXT FIELD vm_moneda
		END IF
		IF vm_cliente IS NOT NULL AND vm_proveedor IS NOT NULL 
			AND vm_pedido IS NOT NULL THEN
			CALL fgl_winmessage(vg_producto,'Especificar un solo Filtro, por favor','exclamation')
			CLEAR vm_proveedor, vm_cliente, vm_pedido
			CLEAR nom_cliente, nom_proveedor, vm_pedido
			INITIALIZE vm_proveedor, vm_pedido, vm_cliente TO NULL
			NEXT FIELD vm_proveedor
		END IF
		IF vm_cliente IS NOT NULL AND vm_proveedor IS NOT NULL THEN
			CALL fgl_winmessage(vg_producto,'Especificar un solo Filtro, por favor','exclamation')
			CLEAR vm_proveedor, vm_cliente
			CLEAR nom_cliente, nom_proveedor, vm_pedido
			INITIALIZE vm_cliente, vm_proveedor TO NULL
			NEXT FIELD vm_proveedor
		END IF
		IF vm_cliente IS NOT NULL AND vm_pedido IS NOT NULL THEN
			CALL fgl_winmessage(vg_producto,'Especificar un solo Filtro, por favor','exclamation')
			CLEAR vm_cliente, vm_pedido
			CLEAR nom_cliente, nom_proveedor, vm_pedido
			INITIALIZE vm_cliente, vm_pedido TO NULL
			NEXT FIELD vm_cliente
		END IF
		IF vm_proveedor IS NOT NULL AND vm_pedido IS NOT NULL THEN
			CALL fgl_winmessage(vg_producto,'Especificar un solo Filtro, por favor','exclamation')
			CLEAR vm_proveedor, vm_pedido
			CLEAR nom_cliente, nom_proveedor, vm_pedido
			INITIALIZE vm_proveedor, vm_pedido TO NULL
			NEXT FIELD vm_proveedor
		END IF
END INPUT

END FUNCTION



REPORT report_movimientos_ctas(r_rep, val_db, val_cr)
DEFINE r_rep		RECORD
				tipo_comp		CHAR(2),
				num_comp		CHAR(8),
				fec_proceso		DATE,
				--glosa			CHAR(35),
				glosa			VARCHAR(90,40),
				valor			DECIMAL(14,2),
				filtro			CHAR(11),
				flag_filtro		CHAR(1)
			END RECORD
DEFINE val_db		DECIMAL(14,2)
DEFINE val_cr		DECIMAL(14,2)
DEFINE r_z01		RECORD LIKE cxct001.*
DEFINE r_p01		RECORD LIKE cxpt001.*
DEFINE r_b10		RECORD LIKE ctbt010.*
--DEFINE glosa		CHAR(36)
DEFINE glosa		LIKE ctbt013.b13_glosa
DEFINE fecha_ini	DATE
DEFINE sal_aft_db	DECIMAL(14,2)
DEFINE sal_aft_cr	DECIMAL(14,2)
DEFINE expr_filtro	VARCHAR(35)
DEFINE filtro		VARCHAR(15)
DEFINE usuario		VARCHAR(20)
DEFINE caract		SMALLINT
DEFINE escape		SMALLINT
DEFINE act_comp		SMALLINT
DEFINE desact_comp	SMALLINT
DEFINE act_10cpi	SMALLINT

OUTPUT
	TOP MARGIN	vm_top
	LEFT MARGIN	vm_left
	RIGHT MARGIN	vm_right
	BOTTOM MARGIN	vm_bottom
	PAGE LENGTH	vm_page

FORMAT

PAGE HEADER
	LET escape	= 27		# Iniciar sec. impresi¢n
	LET act_comp	= 15		# Activar Comprimido.
	LET desact_comp	= 18		# Cancelar Comprimido.
	LET act_10cpi	= 80		# Comprimido 10 CPI.
	LET usuario     = 'USUARIO: ', vg_usuario
	CALL fl_justifica_titulo('D', usuario, 19) RETURNING usuario
	LET filtro      = '* T O D O S *'
	LET expr_filtro = NULL
	IF vm_proveedor IS NOT NULL THEN
		LET filtro 	= 'PROVEEDOR '
		LET expr_filtro = vm_proveedor USING '&&&&&&', '-', 
		                  nom_proveedor 
	END IF
	IF vm_cliente IS NOT NULL THEN
		LET filtro 	= 'CLIENTE '
		LET expr_filtro = vm_cliente USING '&&&&&&', '-', 
				  nom_cliente 
	END IF
	IF vm_pedido IS NOT NULL THEN
		LET filtro 	= 'PEDIDO '
		LET expr_filtro = vm_pedido
	END IF
	print ASCII escape;
	print ASCII act_comp;
	print ASCII escape;
	print ASCII act_10cpi
	PRINT COLUMN 01,  rg_cia.g01_razonsocial,
	      COLUMN 122, 'PAGINA: ', PAGENO USING '&&&'
	PRINT COLUMN 01,  'CONTABILIDAD',
	      COLUMN 48,  'MOVIMIENTOS DE CUENTA POR FILTROS',
	      COLUMN 123, UPSHIFT(fl_justifica_titulo('D', vg_proceso, 10))
	SKIP 1 LINES
	PRINT COLUMN 45, '** CUENTA      : ', vm_cta_inicial, ' ', nom_cta_ini
	PRINT COLUMN 45, '** MONEDA      : ',
	                 rm_g13.g13_nombre
	PRINT COLUMN 45, '** RANGO FECHAS: ',
	      		 vm_fecha_ini USING 'dd-mm-yyyy', ' - ',
	                 vm_fecha_fin USING 'dd-mm-yyyy'
	PRINT COLUMN 45, '** FILTRO      : ', filtro, ' ', expr_filtro 
	SKIP 1 LINES
	PRINT COLUMN 1,  'FECHA DE IMPRESION: ', TODAY USING 'dd-mm-yyyy',
		1 SPACES, TIME,
	      COLUMN 114,  usuario
	PRINT '------------------------------------------------------------------------------------------------------------------------------------'
	PRINT COLUMN 001, 'TP',
	      COLUMN 007, 'NUMERO',
	      COLUMN 019, 'FECHA',
	      COLUMN 035, 'G L O S A',
	      COLUMN 078, fl_justifica_titulo('D', 'DEBITO', 17),
	      COLUMN 097, fl_justifica_titulo('D', 'CREDITO', 17),
	      COLUMN 116, fl_justifica_titulo('D', 'SALDO', 17) 
	PRINT '------------------------------------------------------------------------------------------------------------------------------------'

BEFORE GROUP OF r_rep.filtro
	IF r_rep.fec_proceso >= vm_fecha_ini AND vm_ver_saldos = 'N' THEN
		NEED 12 LINES
	ELSE
		NEED 10 LINES
	END IF
	LET caract = 0
	IF vm_ver_saldos = 'S' THEN
		LET caract = 21
	END IF
	CASE r_rep.flag_filtro
		WHEN 'C'
			CALL fl_lee_cliente_general(r_rep.filtro)
				RETURNING r_z01.*
			PRINT COLUMN 01, 'CLIENTE  : ', r_rep.filtro CLIPPED,
			      COLUMN 19, r_z01.z01_nomcli[1, 63 - caract]
					CLIPPED;
		WHEN 'P'
			CALL fl_lee_proveedor(r_rep.filtro) RETURNING r_p01.*
			PRINT COLUMN 01, 'PROVEEDOR: ', r_rep.filtro CLIPPED,
			      COLUMN 19, r_p01.p01_nomprov[1, 63 - caract]
					CLIPPED;
		WHEN 'D'
			PRINT COLUMN 01, 'PEDIDO   : ', r_rep.filtro;
		OTHERWISE
			PRINT COLUMN 01, '*** SIN FILTRO ***';
	END CASE
	PRINT COLUMN 83 - caract, 'SALDO INICIAL AL ',
		vm_fec_antes USING 'dd-mm-yyyy', ' ==>  ',
      	      COLUMN 116 - caract, vm_saldo_ini	USING '--,---,---,--&.##' 
	LET vm_saldo   = vm_saldo_ini
	LET sal_aft_db = 0
	LET sal_aft_cr = 0
	{--
	LET sal_aft_db = vm_saldo_ini
	LET sal_aft_cr = 0
	IF vm_saldo_ini < 0 THEN
		LET sal_aft_db = 0
		LET sal_aft_cr = vm_saldo_ini
	END IF
	--}
	LET tot_val_db = 0
	LET tot_val_cr = 0

ON EVERY ROW
	LET vm_saldo = vm_saldo + (val_db + val_cr)
	IF r_rep.fec_proceso >= vm_fecha_ini AND vm_ver_saldos = 'N' THEN
		NEED 4 LINES
		PRINT COLUMN 001, r_rep.tipo_comp,
     		      COLUMN 007, r_rep.num_comp,
	      	      COLUMN 019, r_rep.fec_proceso	USING 'dd-mm-yyyy',
      		      COLUMN 033, r_rep.glosa[1, 42]	CLIPPED,
      		      COLUMN 078, val_db	USING '##,###,###,##&.##',
      		      COLUMN 097, val_cr	USING '##,###,###,##&.##',
		      COLUMN 116, vm_saldo	USING '--,---,---,--&.##' 
		IF r_rep.glosa[43,90] IS NOT NULL OR r_rep.glosa[43,90] <> ' '
		THEN
			PRINT COLUMN 033, r_rep.glosa[43,90] CLIPPED
		END IF
	ELSE
		NEED 3 LINES
	END IF
	LET tot_val_db = tot_val_db + val_db
	LET tot_val_cr = tot_val_cr + val_cr
	CASE r_rep.flag_filtro
		WHEN 'C'
			LET tot_val_db_c = tot_val_db_c + val_db
			LET tot_val_cr_c = tot_val_cr_c + val_cr
		WHEN 'P'
			LET tot_val_db_p = tot_val_db_p + val_db
			LET tot_val_cr_p = tot_val_cr_p + val_cr
		WHEN 'D'
			LET tot_val_db_d = tot_val_db_d + val_db
			LET tot_val_cr_d = tot_val_cr_d + val_cr
	END CASE		
	LET tot_val_db_g = tot_val_db_g + val_db
	LET tot_val_cr_g = tot_val_cr_g + val_cr
	IF r_rep.tipo_comp IS NULL THEN
		SKIP 1 LINES
	END IF

AFTER GROUP OF r_rep.filtro
	NEED 3 LINES
	PRINT COLUMN 74, '-----------------',
	      COLUMN 95, '-----------------'
	CASE r_rep.flag_filtro
		WHEN 'C'
			LET vm_saldo_cli = vm_saldo_cli + vm_saldo
			CALL fl_lee_cliente_general(r_rep.filtro)
				RETURNING r_z01.*
			PRINT COLUMN 20, 'TOTALES CLIENTE  : ',
				r_rep.filtro CLIPPED,
			      COLUMN 46,  r_z01.z01_nomcli[1, 27] CLIPPED;
		WHEN 'P'
			LET vm_saldo_pro = vm_saldo_pro + vm_saldo
			CALL fl_lee_proveedor(r_rep.filtro) RETURNING r_p01.*
			PRINT COLUMN 20, 'TOTALES PROVEEDOR: ',
				r_rep.filtro CLIPPED,
			      COLUMN 46, r_p01.p01_nomprov[1, 27] CLIPPED;
		WHEN 'D'
			LET vm_saldo_ped = vm_saldo_ped + vm_saldo
			PRINT COLUMN 20, 'TOTALES PEDIDO   : ', r_rep.filtro;
		OTHERWISE
			PRINT COLUMN 20, 'TOTALES *** SIN FILTRO ***';
	END CASE
	LET tot_val_db = tot_val_db + sal_aft_db
	LET tot_val_cr = tot_val_cr + sal_aft_cr
	CASE r_rep.flag_filtro
		WHEN 'C'
			LET tot_val_db_c = tot_val_db_c + sal_aft_db
			LET tot_val_cr_c = tot_val_cr_c + sal_aft_cr
		WHEN 'P'
			LET tot_val_db_p = tot_val_db_p + sal_aft_db
			LET tot_val_cr_p = tot_val_cr_p + sal_aft_cr
		WHEN 'D'
			LET tot_val_db_d = tot_val_db_d + sal_aft_db
			LET tot_val_cr_d = tot_val_cr_d + sal_aft_cr
	END CASE		
	LET tot_val_db_g = tot_val_db_g + sal_aft_db
	LET tot_val_cr_g = tot_val_cr_g + sal_aft_cr
	PRINT COLUMN 74, tot_val_db USING '##,###,###,##&.##',
	      COLUMN 95, tot_val_cr USING '##,###,###,##&.##';
	IF vm_ver_saldos = 'S' THEN
		PRINT COLUMN 116, vm_saldo	USING '--,---,---,--&.##' 
		SKIP 1 LINES
	ELSE
		PRINT ' '
	END IF

ON LAST ROW
	NEED 7 LINES
	SKIP 1 LINES
	IF tot_val_db_c > 0 OR tot_val_db_p > 0 OR tot_val_db_d > 0 OR
	   tot_val_cr_c > 0 OR tot_val_cr_p > 0 OR tot_val_cr_d > 0 THEN
		PRINT COLUMN 74, '------------------',
		      COLUMN 95, '------------------',
		      COLUMN 116, '------------------'
	END IF
	IF tot_val_db_c > 0 OR tot_val_cr_c THEN
		PRINT COLUMN 42, 'TOTALES GENERALES CLIENTES ==>  ',
			tot_val_db_c USING '###,###,###,##&.##',
		      COLUMN 95, tot_val_cr_c USING '###,###,###,##&.##',
      	      	      COLUMN 116, vm_saldo_cli	USING '--,---,---,--&.##' 
	END IF
	IF tot_val_db_p > 0 OR tot_val_cr_p THEN
		PRINT COLUMN 39, 'TOTALES GENERALES PROVEEDORES ==>  ',
			tot_val_db_p USING '###,###,###,##&.##',
		      COLUMN 95, tot_val_cr_p USING '###,###,###,##&.##',
      	      	      COLUMN 116, vm_saldo_pro	USING '--,---,---,--&.##' 
	END IF
	IF tot_val_db_d > 0 OR tot_val_cr_d THEN
		PRINT COLUMN 43, 'TOTALES GENERALES PEDIDOS ==>  ',
			tot_val_db_d USING '###,###,###,##&.##',
		      COLUMN 95, tot_val_cr_d USING '###,###,###,##&.##',
      	      	      COLUMN 116, vm_saldo_ped	USING '--,---,---,--&.##' 
	END IF
	SKIP 1 LINES
	PRINT COLUMN 74, '------------------',
	      COLUMN 95, '------------------'
	PRINT COLUMN 43, 'TOTALES GENERALES FILTROS ==>  ',
		tot_val_db_g USING '###,###,###,##&.##',
	      COLUMN 95, tot_val_cr_g USING '###,###,###,##&.##';
	print ASCII escape;
	print ASCII desact_comp 

END REPORT



FUNCTION retorna_saldo(flag_filtro, codigo, filtro, fecha_ini, fecha_fin)
DEFINE flag_filtro	CHAR(1)
DEFINE codigo		INTEGER
DEFINE filtro		VARCHAR(11)
DEFINE fecha_ini	DATE
DEFINE fecha_fin	DATE
DEFINE query		VARCHAR(1200)
DEFINE expr_fil		VARCHAR(100)
DEFINE valor	 	DECIMAL(14,2)

CASE flag_filtro
	WHEN 'C'
		LET expr_fil = '   AND b13_codcli       = ', codigo
	WHEN 'P'
		LET expr_fil = '   AND b13_codprov      = ', codigo
	WHEN 'D'
		LET expr_fil = '   AND b13_pedido       = "', filtro, '"'
	OTHERWISE
		LET expr_fil = '   AND b13_codcli IS NULL ',
				'   AND b13_codprov IS NULL ',
				'   AND b13_pedido IS NULL '
END CASE
LET query = 'SELECT NVL(SUM(b13_valor_base), 0) saldo_ini ',
		' FROM ctbt012, ctbt013 ',
		' WHERE b12_compania  = ', vg_codcia,
		'   AND b12_estado   <> "E" ',
		'   AND b12_moneda    = "', vm_moneda, '"',
		'   AND b13_compania  = b12_compania ',
		'   AND b13_tipo_comp = b12_tipo_comp ',
		'   AND b13_num_comp  = b12_num_comp ',
		'   AND b13_cuenta    = "', vm_cta_inicial, '"',
		'   AND b13_fec_proceso BETWEEN "', fecha_ini,
					 '" AND "', fecha_fin, '"',
		expr_fil CLIPPED,
		' INTO TEMP t_sum'
PREPARE cons_sum FROM query
EXECUTE cons_sum
SELECT * INTO valor FROM t_sum
DROP TABLE t_sum
RETURN valor

END FUNCTION



FUNCTION borrar_cabecera()

CLEAR FORM
INITIALIZE vm_fecha_ini, vm_fecha_fin, vm_cliente,vm_proveedor, vm_pedido,
		vm_incluir, vm_ver_saldos
	TO NULL

END FUNCTION
