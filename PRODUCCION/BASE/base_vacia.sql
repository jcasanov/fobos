grant dba to "fobos";
grant dba to "public";
grant dba to "crissega";








 

 
CREATE PROCEDURE "fobos".fp_digito_veri(cedruc CHAR(15)) RETURNING INT;

	DEFINE suma, i, lim	INT;
	DEFINE residuo_suma	INT;
	DEFINE num		INT;

	ON EXCEPTION IN (-1213)
		RETURN 0;
	END EXCEPTION;
	LET lim = 10;
	IF (LENGTH(cedruc) <> lim) AND (LENGTH(cedruc) <> 13) THEN
		RETURN 0;
	END IF;
	IF (cedruc[1, 2] > 22) OR (cedruc[1, 2] = 00) THEN
		RETURN 0;
	END IF;
	IF LENGTH(cedruc) = 13 THEN
		IF cedruc[11, 13] <> '001' OR cedruc[11, 12] <> '00' THEN
			RETURN 0;
		END IF;
	END IF;
	LET suma 	 = 0;
	LET residuo_suma = NULL;
	IF cedruc[3, 3] = 9 THEN
		LET suma         = cedruc[1, 1] * 4;
		LET suma         = suma + cedruc[2, 2] * 3;
		LET suma         = suma + cedruc[3, 3] * 2;
		LET suma         = suma + cedruc[4, 4] * 7;
		LET suma         = suma + cedruc[5, 5] * 6;
		LET suma         = suma + cedruc[6, 6] * 5;
		LET suma         = suma + cedruc[7, 7] * 4;
		LET suma         = suma + cedruc[8, 8] * 3;
		LET suma         = suma + cedruc[9, 9] * 2;
		LET residuo_suma = 11 - MOD(suma, 11);
		IF residuo_suma >= lim THEN
			LET residuo_suma = 11 - residuo_suma;
		END IF;
		LET num = cedruc[10, 10];
		IF num = residuo_suma THEN
			RETURN 1;
		END IF;
	END IF;
	IF (cedruc[3, 3] = 6) OR (cedruc[3, 3] = 8) THEN
		LET suma         = cedruc[1, 1] * 3;
		LET suma         = suma + cedruc[2, 2] * 2;
		LET suma         = suma + cedruc[3, 3] * 7;
		LET suma         = suma + cedruc[4, 4] * 6;
		LET suma         = suma + cedruc[5, 5] * 5;
		LET suma         = suma + cedruc[6, 6] * 4;
		LET suma         = suma + cedruc[7, 7] * 3;
		LET suma         = suma + cedruc[8, 8] * 2;
		LET residuo_suma = 11 - MOD(suma, 11);
		IF residuo_suma >= lim THEN
			LET residuo_suma = 11 - residuo_suma;
		END IF;
		LET num = cedruc[9, 9];
		IF num = residuo_suma THEN
			RETURN 1;
		END IF;
	END IF;
	IF ((cedruc[3, 3] < 3) OR (cedruc[3, 3] > 5)) AND (cedruc[3, 3] <> 7)
	THEN
		LET suma = 0;
		FOR i = 1 TO lim - 1
			LET num = SUBSTR(cedruc, i, 1);
			IF MOD(i, 2) <> 0 THEN
				LET num = num * 2;
				IF num > 9 THEN
					LET num = num - 9;
				END IF;
			END IF;
			LET suma = suma + num;
		END FOR;
		LET num          = SUBSTR(cedruc, lim, 1);
		LET residuo_suma = 10 - MOD(suma, 10);
		IF residuo_suma >= lim THEN
			LET residuo_suma = 10 - residuo_suma;
		END IF;
		IF num = residuo_suma THEN
			RETURN 1;
		END IF;
	END IF;
	RETURN 0;

END PROCEDURE;

CREATE PROCEDURE "fobos".fp_numero_semana(fecha DATE) RETURNING INT;

	DEFINE num_sem_g	DECIMAL(10, 2);
	DEFINE num_sem_f	INT;

	ON EXCEPTION IN (-1213)
		RETURN 0;
	END EXCEPTION;
	LET num_sem_g = ((fecha - MDY(1, 3, YEAR(fecha
			- (WEEKDAY(fecha - 1 UNITS DAY) + 1) + 4 UNITS DAY))
			+ (WEEKDAY(MDY(1, 3, YEAR(fecha - (WEEKDAY(fecha
			- 1 UNITS DAY) + 1) + 4 UNITS DAY))) + 1) + 5) / 7);
	{--
	IF TRUNC(num_sem_g, 0) = num_sem_g THEN
		LET num_sem_f = num_sem_g;
	ELSE
		LET num_sem_f = TRUNC(num_sem_g, 0) + 1;
	END IF;
	--}
	LET num_sem_f = TRUNC(num_sem_g, 0);
	IF num_sem_f = 0 THEN
		LET num_sem_f = 1;
	END IF;
	IF num_sem_f > 52 THEN
		LET num_sem_f = 52;
	END IF;
	RETURN num_sem_f;

END PROCEDURE;

CREATE PROCEDURE "fobos".fp_dias360(fecha_ini DATE, fecha_fin DATE, metodo INT)
		RETURNING INT;

	DEFINE fec1, fec2		DATE;
	DEFINE fec_txt			CHAR(10);
	DEFINE num_anio, num_mes	INT;
	DEFINE dias, num_dias		INT;

	ON EXCEPTION IN (-1260)
		RETURN 0;
	END EXCEPTION;

	-- METODO: 1 (M�todo Europeo)	0 (M�todo EEUU - (NASD))
	IF DAY(fecha_ini) = 31 THEN
		LET fecha_ini = fecha_ini - 1 UNITS DAY;
	END IF;

	IF metodo = 1 THEN
		IF DAY(fecha_fin) = 31 THEN
			LET fecha_fin = fecha_fin - 1 UNITS DAY;
		END IF;
	END IF;

	IF metodo = 0 THEN
		LET fec2 = MDY(MONTH(fecha_fin), 01, YEAR(fecha_fin))
				+ 1 UNITS MONTH - 1 UNITS DAY;
		IF fecha_fin = fec2 AND DAY(fecha_ini) < 30 THEN
			LET fecha_fin = fec2 + 1 UNITS DAY;
		ELSE
			IF DAY(fecha_fin) = 31 THEN
				LET fecha_fin = fecha_fin - 1 UNITS DAY;
			END IF;
		END IF;
	END IF;

	LET num_mes = 0;

	IF EXTEND(fecha_ini, YEAR TO MONTH) = EXTEND(fecha_fin, YEAR TO MONTH)
	THEN
		LET num_dias = fecha_fin - fecha_ini + 1;
		IF num_dias > 30 THEN
			LET num_dias = 30;
		END IF;
		RETURN num_dias;
	END IF;

	LET fec1 = MDY(MONTH(fecha_ini), 01, YEAR(fecha_ini)) + 1 UNITS MONTH;
	LET fec2 = MDY(MONTH(fecha_fin), 01, YEAR(fecha_fin)) - 1 UNITS DAY;

	LET num_anio = 0;

	IF EXTEND(fec2, YEAR TO MONTH) = EXTEND(fec1, YEAR TO MONTH) THEN
		LET num_mes = 30;
	END IF;

	IF EXTEND(fec1, YEAR TO MONTH) > EXTEND(fec2, YEAR TO MONTH) THEN
		LET num_mes = 0;
	END IF;

	IF EXTEND(fec2, YEAR TO MONTH) > EXTEND(fec1, YEAR TO MONTH) THEN
		LET fec_txt  = (EXTEND(fec2, YEAR TO MONTH) -
				EXTEND(fec1, YEAR TO MONTH)) + 1 UNITS MONTH;

		LET num_anio = fec_txt[1, 5];
		LET num_mes  = fec_txt[7, 8];

		LET num_anio = num_anio * 360;
		LET num_mes  = num_mes * 30;
	END IF;

	LET num_dias = 30 - DAY(fecha_ini) + 1;
	IF num_dias < 0 THEN
		LET num_dias = 1;
	END IF;
	
	LET dias = DAY(fecha_fin);
	IF dias > 30 OR (EXTEND(fecha_fin, MONTH TO DAY) = "02-28" OR
	   EXTEND(fecha_fin, MONTH TO DAY) = "02-29")
	THEN
		LET dias = 30;
	END IF;

	LET num_dias = num_dias + dias;

	LET num_dias = num_dias + (num_anio + num_mes);

	RETURN num_dias;

END PROCEDURE;


 

 

 

 

 

 

grant  execute on function "fobos".fp_digito_veri (char) to "public" as "fobos";
grant  execute on function "fobos".fp_numero_semana (date) to "public" as "fobos";
grant  execute on function "fobos".fp_dias360 (date,date,integer) to "public" as "fobos";

{ TABLE "fobos".gent000 row size = 45 number of columns = 9 index size = 34 }
create table "fobos".gent000 
  (
    g00_serial serial not null ,
    g00_porc_impto decimal(4,2) not null ,
    g00_label_impto varchar(10,5) not null ,
    g00_moneda_base char(2) not null ,
    g00_moneda_alt char(2),
    g00_decimal_mb smallint not null ,
    g00_decimal_ma smallint,
    g00_usuario varchar(10,5) not null ,
    g00_fecing datetime year to second not null 
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".gent000 from "public";

{ TABLE "fobos".gent001 row size = 179 number of columns = 11 index size = 34 }
create table "fobos".gent001 
  (
    g01_compania serial not null ,
    g01_razonsocial varchar(40,20) not null ,
    g01_abreviacion varchar(10,5) not null ,
    g01_estado char(1) not null ,
    g01_actividad varchar(40,20) not null ,
    g01_numpatronal varchar(15,15) not null ,
    g01_replegal varchar(30,15) not null ,
    g01_cedrepl varchar(13,13) not null ,
    g01_principal char(1) not null ,
    g01_usuario varchar(10,5) not null ,
    g01_fecing datetime year to second not null ,
    
    check (g01_estado IN ('A' ,'B' )),
    
    check (g01_principal IN ('S' ,'N' ))
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".gent001 from "public";

{ TABLE "fobos".gent003 row size = 54 number of columns = 7 index size = 58 }
create table "fobos".gent003 
  (
    g03_compania integer not null ,
    g03_areaneg smallint not null ,
    g03_nombre varchar(15,8) not null ,
    g03_abreviacion varchar(10,5) not null ,
    g03_modulo char(2),
    g03_usuario varchar(10,5) not null ,
    g03_fecing datetime year to second not null 
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".gent003 from "public";

{ TABLE "fobos".gent004 row size = 44 number of columns = 3 index size = 9 }
create table "fobos".gent004 
  (
    g04_grupo char(2) not null ,
    g04_nombre varchar(40,20) not null ,
    g04_ver_costo char(1) not null ,
    
    check (g04_ver_costo IN ('S' ,'N' ))
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".gent004 from "public";

{ TABLE "fobos".gent005 row size = 67 number of columns = 7 index size = 31 }
create table "fobos".gent005 
  (
    g05_usuario varchar(10,5) not null ,
    g05_nombres varchar(30,15) not null ,
    g05_grupo char(2) not null ,
    g05_estado char(1) not null ,
    g05_tipo char(2) not null ,
    g05_clave char(10),
    g05_menu char(10),
    
    check (g05_estado IN ('A' ,'B' )),
    
    check (g05_tipo IN ('AG' ,'AM' ,'UF' ))
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".gent005 from "public";

{ TABLE "fobos".gent007 row size = 42 number of columns = 5 index size = 106 }
create table "fobos".gent007 
  (
    g07_user varchar(10,5) not null ,
    g07_impresora varchar(10,5) not null ,
    g07_default char(1) not null ,
    g07_usuario varchar(10,5) not null ,
    g07_fecing datetime year to second not null ,
    
    check (g07_default IN ('S' ,'N' ))
  )  extent size 22 next size 16 lock mode row;
revoke all on "fobos".gent007 from "public";

{ TABLE "fobos".gent009 row size = 104 number of columns = 12 index size = 87 }
create table "fobos".gent009 
  (
    g09_compania integer not null ,
    g09_banco integer not null ,
    g09_numero_cta char(15) not null ,
    g09_estado char(1) not null ,
    g09_tipo_cta char(1) not null ,
    g09_moneda char(2) not null ,
    g09_pago_roles char(1) not null ,
    g09_atencion_rol varchar(40,20),
    g09_aux_cont char(12) not null ,
    g09_num_cheques integer not null ,
    g09_usuario varchar(10,5) not null ,
    g09_fecing datetime year to second not null ,
    
    check (g09_estado IN ('A' ,'B' )),
    
    check (g09_tipo_cta IN ('C' ,'A' )),
    
    check (g09_pago_roles IN ('S' ,'N' ))
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".gent009 from "public";

{ TABLE "fobos".gent011 row size = 52 number of columns = 4 index size = 31 }
create table "fobos".gent011 
  (
    g11_tiporeg char(2) not null ,
    g11_nombre varchar(30,15) not null ,
    g11_usuario varchar(10,5) not null ,
    g11_fecing datetime year to second not null 
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".gent011 from "public";

{ TABLE "fobos".gent012 row size = 54 number of columns = 5 index size = 43 }
create table "fobos".gent012 
  (
    g12_tiporeg char(2) not null ,
    g12_subtipo smallint not null ,
    g12_nombre varchar(30,15) not null ,
    g12_usuario varchar(10,5) not null ,
    g12_fecing datetime year to second not null 
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".gent012 from "public";

{ TABLE "fobos".gent017 row size = 61 number of columns = 8 index size = 34 }
create table "fobos".gent017 
  (
    g17_codrubro serial not null ,
    g17_nombre varchar(30,15) not null ,
    g17_tipo_rubro char(1) not null ,
    g17_orden smallint not null ,
    g17_indicador char(1) not null ,
    g17_base char(3),
    g17_usuario varchar(10,5) not null ,
    g17_fecing datetime year to second not null ,
    
    check (g17_tipo_rubro IN ('N' ,'I' )),
    
    check (g17_indicador IN ('U' ,'P' )),
    
    check (g17_base IN ('FOB' ,'CIF' ))
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".gent017 from "public";

{ TABLE "fobos".gent018 row size = 31 number of columns = 6 index size = 70 }
create table "fobos".gent018 
  (
    g18_compania integer not null ,
    g18_localidad smallint not null ,
    g18_areaneg smallint not null ,
    g18_serie char(4) not null ,
    g18_usuario varchar(10,5) not null ,
    g18_fecing datetime year to second not null 
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".gent018 from "public";

{ TABLE "fobos".gent034 row size = 70 number of columns = 7 index size = 82 }
create table "fobos".gent034 
  (
    g34_compania integer not null ,
    g34_cod_depto smallint not null ,
    g34_cod_ccosto smallint not null ,
    g34_nombre varchar(30,15) not null ,
    g34_aux_deprec char(12),
    g34_usuario varchar(10,5) not null ,
    g34_fecing datetime year to second not null 
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".gent034 from "public";

{ TABLE "fobos".gent035 row size = 56 number of columns = 5 index size = 49 }
create table "fobos".gent035 
  (
    g35_compania integer not null ,
    g35_cod_cargo smallint not null ,
    g35_nombre varchar(30,15) not null ,
    g35_usuario varchar(10,5) not null ,
    g35_fecing datetime year to second not null 
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".gent035 from "public";

{ TABLE "fobos".gent036 row size = 58 number of columns = 5 index size = 34 }
create table "fobos".gent036 
  (
    g36_dia date not null ,
    g36_referencia varchar(30,15) not null ,
    g36_nue_dia date,
    g36_usuario varchar(10,5) not null ,
    g36_fecing datetime year to second not null 
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".gent036 from "public";

{ TABLE "fobos".gent050 row size = 45 number of columns = 6 index size = 31 }
create table "fobos".gent050 
  (
    g50_modulo char(2) not null ,
    g50_nombre varchar(20,10) not null ,
    g50_estado char(1) not null ,
    g50_areaneg_def smallint,
    g50_usuario varchar(10,5) not null ,
    g50_fecing datetime year to second not null ,
    
    check (g50_estado IN ('A' ,'B' ))
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".gent050 from "public";

{ TABLE "fobos".gent051 row size = 68 number of columns = 6 index size = 52 }
create table "fobos".gent051 
  (
    g51_basedatos varchar(15,8) not null ,
    g51_nombre varchar(20,10) not null ,
    g51_servidor varchar(10,5) not null ,
    g51_default char(1) not null ,
    g51_usuario varchar(10,5) not null ,
    g51_fecing datetime year to second not null ,
    
    check (g51_default IN ('S' ,'N' ))
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".gent051 from "public";

{ TABLE "fobos".gent052 row size = 14 number of columns = 3 index size = 57 }
create table "fobos".gent052 
  (
    g52_modulo char(2) not null ,
    g52_usuario varchar(10,5) not null ,
    g52_estado char(1) not null ,
    
    check (g52_estado IN ('A' ,'B' ))
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".gent052 from "public";

{ TABLE "fobos".gent053 row size = 17 number of columns = 3 index size = 75 }
create table "fobos".gent053 
  (
    g53_modulo char(2) not null ,
    g53_usuario varchar(10,5) not null ,
    g53_compania integer not null 
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".gent053 from "public";

{ TABLE "fobos".gent054 row size = 84 number of columns = 7 index size = 55 }
create table "fobos".gent054 
  (
    g54_modulo char(2) not null ,
    g54_proceso char(10) not null ,
    g54_nombre varchar(50,20) not null ,
    g54_tipo char(1) not null ,
    g54_estado char(1) not null ,
    g54_usuario varchar(10,5) not null ,
    g54_fecing datetime year to second not null ,
    
    check (g54_tipo IN ('C' ,'R' ,'P' ,'M' ,'E' ,'N' )),
    
    check (g54_estado IN ('A' ,'B' ,'R' ))
  )  extent size 55 next size 16 lock mode row;
revoke all on "fobos".gent054 from "public";

{ TABLE "fobos".talt001 row size = 67 number of columns = 11 index size = 73 }
create table "fobos".talt001 
  (
    t01_compania integer not null ,
    t01_linea char(5) not null ,
    t01_nombre varchar(20,10) not null ,
    t01_cod_mod_veh char(1) not null ,
    t01_dcto_mo_cont decimal(4,2) not null ,
    t01_dcto_rp_cont decimal(4,2) not null ,
    t01_dcto_mo_cred decimal(4,2) not null ,
    t01_dcto_rp_cred decimal(4,2) not null ,
    t01_grupo_linea char(5) not null ,
    t01_usuario varchar(10,5) not null ,
    t01_fecing datetime year to second not null ,
    
    check (t01_cod_mod_veh IN ('S' ,'N' ))
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".talt001 from "public";

{ TABLE "fobos".talt002 row size = 87 number of columns = 6 index size = 49 }
create table "fobos".talt002 
  (
    t02_compania integer not null ,
    t02_seccion smallint not null ,
    t02_nombre varchar(30,15) not null ,
    t02_jefe varchar(30,15) not null ,
    t02_usuario varchar(10,5) not null ,
    t02_fecing datetime year to second not null 
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".talt002 from "public";

{ TABLE "fobos".dual row size = 1 number of columns = 1 index size = 0 }
create table "fobos".dual 
  (
    nulo char(1) not null 
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".dual from "public";

{ TABLE "fobos".gent013 row size = 44 number of columns = 7 index size = 31 }
create table "fobos".gent013 
  (
    g13_moneda char(2) not null ,
    g13_nombre varchar(15,5) not null ,
    g13_estado char(1) not null ,
    g13_simbolo char(4) not null ,
    g13_decimales smallint not null ,
    g13_usuario varchar(10,5) not null ,
    g13_fecing datetime year to second not null ,
    
    check (g13_estado IN ('A' ,'B' ))
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".gent013 from "public";

{ TABLE "fobos".gent031 row size = 60 number of columns = 7 index size = 64 }
create table "fobos".gent031 
  (
    g31_ciudad serial not null ,
    g31_pais integer not null ,
    g31_divi_poli integer,
    g31_nombre varchar(25,15) not null ,
    g31_siglas char(3) not null ,
    g31_usuario varchar(10,5) not null ,
    g31_fecing datetime year to second not null 
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".gent031 from "public";

{ TABLE "fobos".gent014 row size = 40 number of columns = 6 index size = 52 }
create table "fobos".gent014 
  (
    g14_serial serial not null ,
    g14_moneda_ori char(2) not null ,
    g14_moneda_des char(2) not null ,
    g14_tasa decimal(22,15) not null ,
    g14_usuario varchar(10,5) not null ,
    g14_fecing datetime year to second not null 
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".gent014 from "public";

{ TABLE "fobos".gent032 row size = 56 number of columns = 5 index size = 49 }
create table "fobos".gent032 
  (
    g32_compania integer not null ,
    g32_zona_venta smallint not null ,
    g32_nombre varchar(30,15) not null ,
    g32_usuario varchar(10,5) not null ,
    g32_fecing datetime year to second not null 
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".gent032 from "public";

{ TABLE "fobos".gent033 row size = 56 number of columns = 5 index size = 49 }
create table "fobos".gent033 
  (
    g33_compania integer not null ,
    g33_cod_ccosto smallint not null ,
    g33_nombre varchar(30,15) not null ,
    g33_usuario varchar(10,5) not null ,
    g33_fecing datetime year to second not null 
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".gent033 from "public";

{ TABLE "fobos".fobos row size = 100 number of columns = 6 index size = 0 }
create table "fobos".fobos 
  (
    fb_aplicativo char(10) not null ,
    fb_descripcion char(35) not null ,
    fb_version char(10) not null ,
    fb_fecha_prod date not null ,
    fb_separador char(1) not null ,
    fb_dir_fobos char(40)
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".fobos from "public";

{ TABLE "fobos".gent010 row size = 66 number of columns = 9 index size = 85 }
create table "fobos".gent010 
  (
    g10_compania integer not null ,
    g10_tarjeta integer not null ,
    g10_cod_tarj char(2) not null ,
    g10_cont_cred char(1) not null ,
    g10_estado char(1) not null ,
    g10_nombre varchar(30,15) not null ,
    g10_codcobr integer,
    g10_usuario varchar(10,5) not null ,
    g10_fecing datetime year to second not null ,
    
    check (g10_estado IN ('A' ,'B' )) constraint "fobos".ck_01_gent010
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".gent010 from "public";

{ TABLE "fobos".gent020 row size = 61 number of columns = 6 index size = 69 }
create table "fobos".gent020 
  (
    g20_compania integer not null ,
    g20_grupo_linea char(5) not null ,
    g20_nombre varchar(30,15) not null ,
    g20_areaneg smallint not null ,
    g20_usuario varchar(10,5) not null ,
    g20_fecing datetime year to second not null 
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".gent020 from "public";

{ TABLE "fobos".gent055 row size = 46 number of columns = 6 index size = 127 }
create table "fobos".gent055 
  (
    g55_user varchar(10,5) not null ,
    g55_compania integer not null ,
    g55_modulo char(2) not null ,
    g55_proceso char(10) not null ,
    g55_usuario varchar(10,5) not null ,
    g55_fecing datetime year to second not null 
  )  extent size 568 next size 56 lock mode row;
revoke all on "fobos".gent055 from "public";

{ TABLE "fobos".gent006 row size = 62 number of columns = 5 index size = 45 }
create table "fobos".gent006 
  (
    g06_impresora varchar(10,5) not null ,
    g06_nombre varchar(30,15) not null ,
    g06_default char(1) not null ,
    g06_usuario varchar(10,5) not null ,
    g06_fecing datetime year to second not null ,
    
    check (g06_default IN ('S' ,'N' ))
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".gent006 from "public";

{ TABLE "fobos".gent008 row size = 54 number of columns = 4 index size = 34 }
create table "fobos".gent008 
  (
    g08_banco integer not null ,
    g08_nombre varchar(30,15) not null ,
    g08_usuario varchar(10,5) not null ,
    g08_fecing datetime year to second not null 
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".gent008 from "public";

{ TABLE "fobos".gent030 row size = 52 number of columns = 5 index size = 34 }
create table "fobos".gent030 
  (
    g30_pais serial not null ,
    g30_nombre varchar(25,15) not null ,
    g30_siglas char(3) not null ,
    g30_usuario varchar(10,5) not null ,
    g30_fecing datetime year to second not null 
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".gent030 from "public";

{ TABLE "fobos".gent022 row size = 47 number of columns = 6 index size = 43 }
create table "fobos".gent022 
  (
    g22_cod_subtipo serial not null ,
    g22_cod_tran char(2) not null ,
    g22_nombre varchar(20,10) not null ,
    g22_estado char(1) not null ,
    g22_usuario varchar(10,5) not null ,
    g22_fecing datetime year to second not null ,
    
    check (g22_estado IN ('A' ,'B' ))
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".gent022 from "public";

{ TABLE "fobos".talt003 row size = 109 number of columns = 20 index size = 102 }
create table "fobos".talt003 
  (
    t03_compania integer not null ,
    t03_mecanico smallint not null ,
    t03_nombres varchar(30,15) not null ,
    t03_iniciales char(3) not null ,
    t03_codrol integer,
    t03_tipo char(1) not null ,
    t03_seccion smallint not null ,
    t03_linea char(5) not null ,
    t03_hora_ini datetime hour to minute,
    t03_hora_fin datetime hour to minute,
    t03_cost_hvn decimal(5,2) not null ,
    t03_cost_hve decimal(5,2) not null ,
    t03_cost_htn decimal(5,2) not null ,
    t03_cost_hte decimal(5,2) not null ,
    t03_fact_hvn decimal(5,2) not null ,
    t03_fact_hve decimal(5,2) not null ,
    t03_fact_htn decimal(5,2) not null ,
    t03_fact_hte decimal(5,2) not null ,
    t03_usuario varchar(10,5) not null ,
    t03_fecing datetime year to second not null ,
    
    check (t03_tipo IN ('M' ,'A' ))
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".talt003 from "public";

{ TABLE "fobos".talt005 row size = 59 number of columns = 10 index size = 60 }
create table "fobos".talt005 
  (
    t05_compania integer not null ,
    t05_tipord char(1) not null ,
    t05_nombre char(15) not null ,
    t05_factura char(1) not null ,
    t05_prec_rpto char(1) not null ,
    t05_valtope_mb decimal(11,2) not null ,
    t05_valtope_ma decimal(11,2) not null ,
    t05_cli_default integer,
    t05_usuario varchar(10,5) not null ,
    t05_fecing datetime year to second not null ,
    
    check (t05_factura IN ('S' ,'N' )),
    
    check (t05_prec_rpto IN ('P' ,'C' ))
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".talt005 from "public";

{ TABLE "fobos".talt006 row size = 51 number of columns = 6 index size = 63 }
create table "fobos".talt006 
  (
    t06_compania integer not null ,
    t06_tipord char(1) not null ,
    t06_subtipo char(1) not null ,
    t06_nombre varchar(25,17) not null ,
    t06_usuario varchar(10,5) not null ,
    t06_fecing datetime year to second not null 
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".talt006 from "public";

{ TABLE "fobos".talt007 row size = 122 number of columns = 14 index size = 64 }
create table "fobos".talt007 
  (
    t07_compania integer not null ,
    t07_codtarea char(12) not null ,
    t07_nombre varchar(60,30) not null ,
    t07_estado char(1) not null ,
    t07_tipo char(1) not null ,
    t07_pto_default smallint not null ,
    t07_val_defa_mb decimal(9,2) not null ,
    t07_val_defa_ma decimal(9,2) not null ,
    t07_dscmax_ger decimal(4,2) not null ,
    t07_dscmax_jef decimal(4,2) not null ,
    t07_dscmax_ven decimal(4,2) not null ,
    t07_modif_desc char(1) not null ,
    t07_usuario varchar(10,5) not null ,
    t07_fecing datetime year to second not null ,
    
    check (t07_estado IN ('A' ,'B' )),
    
    check (t07_tipo IN ('P' ,'V' )),
    
    check (t07_modif_desc IN ('S' ,'N' )) constraint "fobos".ck_03_talt007
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".talt007 from "public";

{ TABLE "fobos".talt008 row size = 98 number of columns = 6 index size = 85 }
create table "fobos".talt008 
  (
    t08_compania integer not null ,
    t08_codtarea char(12) not null ,
    t08_nombre varchar(60,30) not null ,
    t08_orden smallint not null ,
    t08_usuario varchar(10,5) not null ,
    t08_fecing datetime year to second not null 
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".talt008 from "public";

{ TABLE "fobos".talt009 row size = 51 number of columns = 8 index size = 85 }
create table "fobos".talt009 
  (
    t09_compania integer not null ,
    t09_codtarea char(12) not null ,
    t09_dificultad smallint not null ,
    t09_puntos smallint not null ,
    t09_valor_mb decimal(9,2) not null ,
    t09_valor_ma decimal(9,2) not null ,
    t09_usuario varchar(10,5) not null ,
    t09_fecing datetime year to second not null 
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".talt009 from "public";

{ TABLE "fobos".rept000 row size = 51 number of columns = 22 index size = 51 }
create table "fobos".rept000 
  (
    r00_compania integer not null ,
    r00_estado char(1) not null ,
    r00_tipo_costo char(1) not null ,
    r00_cia_taller integer not null ,
    r00_codcli_tal integer,
    r00_tipo_margen char(1) not null ,
    r00_tipo_descto char(1) not null ,
    r00_bodega_fact char(2),
    r00_contr_prof char(1) not null ,
    r00_dias_prof smallint not null ,
    r00_expi_prof smallint not null ,
    r00_cred_auto char(1) not null ,
    r00_dias_dev smallint not null ,
    r00_dev_mes char(1) not null ,
    r00_tipo_fact char(1) not null ,
    r00_numlin_fact smallint not null ,
    r00_valmin_ccli decimal(8,2) not null ,
    r00_anopro smallint not null ,
    r00_mespro smallint not null ,
    r00_fecha_cd date,
    r00_fecha_cm date,
    r00_fecha_ca date,
    
    check (r00_tipo_fact IN ('U' ,'M' )),
    
    check (r00_estado IN ('A' ,'B' )),
    
    check (r00_tipo_costo IN ('P' ,'U' )),
    
    check (r00_tipo_margen IN ('L' ,'I' )),
    
    check (r00_tipo_descto IN ('L' ,'I' )),
    
    check (r00_cred_auto IN ('S' ,'N' )),
    
    check (r00_dev_mes IN ('S' ,'N' )),
    
    check (r00_contr_prof IN ('S' ,'N' ))
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".rept000 from "public";

{ TABLE "fobos".rept001 row size = 77 number of columns = 11 index size = 67 }
create table "fobos".rept001 
  (
    r01_compania integer not null ,
    r01_codigo smallint not null ,
    r01_nombres varchar(30,15) not null ,
    r01_iniciales char(3) not null ,
    r01_estado char(1) not null ,
    r01_tipo char(1) not null ,
    r01_codrol integer,
    r01_mod_descto char(1) not null ,
    r01_user_owner varchar(10,5) not null ,
    r01_usuario varchar(10,5) not null ,
    r01_fecing datetime year to second not null ,
    
    check (r01_estado IN ('A' ,'B' )),
    
    check (r01_mod_descto IN ('S' ,'N' )),
    
    check (r01_tipo IN ('I' ,'E' ,'B' ,'J' ,'G' ))
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".rept001 from "public";

{ TABLE "fobos".rept002 row size = 63 number of columns = 11 index size = 66 }
create table "fobos".rept002 
  (
    r02_compania integer not null ,
    r02_codigo char(2) not null ,
    r02_nombre varchar(30,15) not null ,
    r02_estado char(1) not null ,
    r02_tipo char(1) not null ,
    r02_area char(1) not null ,
    r02_factura char(1) not null ,
    r02_localidad smallint not null ,
    r02_tipo_ident char(1) not null ,
    r02_usuario varchar(10,5) not null ,
    r02_fecing datetime year to second not null ,
    
    check (r02_estado IN ('A' ,'B' )),
    
    check (r02_area IN ('R' ,'T' )),
    
    check (r02_factura IN ('S' ,'N' )),
    
    check (r02_tipo IN ('F' ,'L' ,'S' ))
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".rept002 from "public";

{ TABLE "fobos".rept003 row size = 79 number of columns = 13 index size = 73 }
create table "fobos".rept003 
  (
    r03_compania integer not null ,
    r03_codigo char(5) not null ,
    r03_nombre varchar(30,15) not null ,
    r03_estado char(1) not null ,
    r03_area char(1) not null ,
    r03_porc_uti decimal(4,2) not null ,
    r03_tipo char(1) not null ,
    r03_dcto_tal decimal(4,2) not null ,
    r03_dcto_cont decimal(4,2) not null ,
    r03_dcto_cred decimal(4,2) not null ,
    r03_grupo_linea char(5) not null ,
    r03_usuario varchar(10,5) not null ,
    r03_fecing datetime year to second not null ,
    
    check (r03_estado IN ('A' ,'B' )),
    
    check (r03_area IN ('R' ,'T' )),
    
    check (r03_tipo IN ('N' ,'I' ))
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".rept003 from "public";

{ TABLE "fobos".rept004 row size = 63 number of columns = 13 index size = 49 }
create table "fobos".rept004 
  (
    r04_compania integer not null ,
    r04_rotacion char(2) not null ,
    r04_nombre varchar(20,10) not null ,
    r04_estado char(1) not null ,
    r04_pedido char(1) not null ,
    r04_uni_vtai smallint not null ,
    r04_uni_vtaf smallint not null ,
    r04_meses smallint not null ,
    r04_porc_uti decimal(4,2) not null ,
    r04_dcto_cont decimal(4,2) not null ,
    r04_dcto_cred decimal(4,2) not null ,
    r04_usuario varchar(10,5) not null ,
    r04_fecing datetime year to second not null ,
    
    check (r04_estado IN ('A' ,'B' )),
    
    check (r04_pedido IN ('S' ,'N' ))
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".rept004 from "public";

{ TABLE "fobos".rept005 row size = 30 number of columns = 5 index size = 39 }
create table "fobos".rept005 
  (
    r05_codigo char(7) not null ,
    r05_siglas char(3) not null ,
    r05_decimales char(1) not null ,
    r05_usuario varchar(10,5) not null ,
    r05_fecing datetime year to second not null ,
    
    check (r05_decimales IN ('S' ,'N' ))
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".rept005 from "public";

{ TABLE "fobos".rept006 row size = 31 number of columns = 4 index size = 31 }
create table "fobos".rept006 
  (
    r06_codigo smallint not null ,
    r06_nombre char(10) not null ,
    r06_usuario varchar(10,5) not null ,
    r06_fecing datetime year to second not null 
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".rept006 from "public";

{ TABLE "fobos".rept007 row size = 33 number of columns = 8 index size = 52 }
create table "fobos".rept007 
  (
    r07_serial serial not null ,
    r07_compania integer not null ,
    r07_linea char(5) not null ,
    r07_moneda char(2) not null ,
    r07_cont_cred char(1) not null ,
    r07_monto_ini decimal(11,2) not null ,
    r07_monto_fin decimal(11,2) not null ,
    r07_descuento decimal(4,2) not null ,
    
    check (r07_cont_cred IN ('C' ,'R' ))
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".rept007 from "public";

{ TABLE "fobos".rept008 row size = 30 number of columns = 8 index size = 39 }
create table "fobos".rept008 
  (
    r08_serial serial not null ,
    r08_compania integer not null ,
    r08_rotacion char(2) not null ,
    r08_moneda char(2) not null ,
    r08_cont_cred char(1) not null ,
    r08_monto_ini decimal(11,2) not null ,
    r08_monto_fin decimal(11,2) not null ,
    r08_descuento decimal(4,2) not null ,
    
    check (r08_cont_cred IN ('C' ,'R' ))
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".rept008 from "public";

{ TABLE "fobos".rept011 row size = 91 number of columns = 15 index size = 144 }
create table "fobos".rept011 
  (
    r11_compania integer not null ,
    r11_bodega char(2) not null ,
    r11_item char(15) not null ,
    r11_ubicacion char(10) not null ,
    r11_ubica_ant char(10),
    r11_stock_ant decimal(8,2) not null ,
    r11_stock_act decimal(8,2) not null ,
    r11_ing_dia decimal(8,2) not null ,
    r11_egr_dia decimal(8,2) not null ,
    r11_fec_ultvta date,
    r11_tip_ultvta char(2),
    r11_num_ultvta decimal(15,0),
    r11_fec_ulting date,
    r11_tip_ulting char(2),
    r11_num_ulting decimal(15,0)
  )  extent size 10823 next size 1082 lock mode row;
revoke all on "fobos".rept011 from "public";

{ TABLE "fobos".rept012 row size = 61 number of columns = 11 index size = 157 }
create table "fobos".rept012 
  (
    r12_compania integer not null ,
    r12_moneda char(2) not null ,
    r12_fecha date not null ,
    r12_bodega char(2) not null ,
    r12_item char(15) not null ,
    r12_uni_venta decimal(8,2) not null ,
    r12_uni_dev decimal(8,2) not null ,
    r12_uni_deman decimal(8,2) not null ,
    r12_uni_perdi decimal(8,2) not null ,
    r12_val_venta decimal(12,2) not null ,
    r12_val_dev decimal(12,2) not null 
  )  extent size 3330 next size 333 lock mode row;
revoke all on "fobos".rept012 from "public";

{ TABLE "fobos".rept013 row size = 94 number of columns = 12 index size = 142 }
create table "fobos".rept013 
  (
    r13_serial serial not null ,
    r13_compania integer not null ,
    r13_localidad smallint not null ,
    r13_bodega char(2) not null ,
    r13_item char(15) not null ,
    r13_estado char(1) not null ,
    r13_cantidad decimal(8,2) not null ,
    r13_referencia varchar(30,15) not null ,
    r13_cod_tran char(2),
    r13_num_tran decimal(15,0),
    r13_usuario varchar(10,5) not null ,
    r13_fecing datetime year to second not null ,
    
    check (r13_estado IN ('A' ,'P' ))
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".rept013 from "public";

{ TABLE "fobos".rept014 row size = 53 number of columns = 5 index size = 160 }
create table "fobos".rept014 
  (
    r14_compania integer not null ,
    r14_item_ant char(15) not null ,
    r14_item_nue char(15) not null ,
    r14_usuario varchar(10,5) not null ,
    r14_fecing datetime year to second not null 
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".rept014 from "public";

{ TABLE "fobos".rept015 row size = 53 number of columns = 5 index size = 160 }
create table "fobos".rept015 
  (
    r15_compania integer not null ,
    r15_item char(15) not null ,
    r15_equivalente char(15) not null ,
    r15_usuario varchar(10,5) not null ,
    r15_fecing datetime year to second not null 
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".rept015 from "public";

{ TABLE "fobos".rept016 row size = 112 number of columns = 21 index size = 159 }
create table "fobos".rept016 
  (
    r16_compania integer not null ,
    r16_localidad smallint not null ,
    r16_pedido char(10) not null ,
    r16_estado char(1) not null ,
    r16_tipo char(1) not null ,
    r16_linea char(5),
    r16_referencia varchar(30,15) not null ,
    r16_proveedor integer not null ,
    r16_moneda char(2) not null ,
    r16_demora smallint not null ,
    r16_seguridad smallint not null ,
    r16_fec_envio date,
    r16_fec_llegada date,
    r16_maximo smallint not null ,
    r16_minimo smallint not null ,
    r16_periodo_vta smallint not null ,
    r16_pto_reorden smallint not null ,
    r16_flag_estad char(1) not null ,
    r16_aux_cont char(12),
    r16_usuario varchar(10,5) not null ,
    r16_fecing datetime year to second not null ,
    
    check (r16_estado IN ('A' ,'C' ,'R' ,'L' ,'P' )),
    
    check (r16_tipo IN ('S' ,'E' )),
    
    check (r16_flag_estad IN ('M' ,'D' ))
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".rept016 from "public";

{ TABLE "fobos".rept018 row size = 78 number of columns = 15 index size = 117 }
create table "fobos".rept018 
  (
    r18_compania integer not null ,
    r18_localidad smallint not null ,
    r18_pedido char(10) not null ,
    r18_item char(15) not null ,
    r18_stock decimal(8,2) not null ,
    r18_maximo decimal(9,2) not null ,
    r18_minimo decimal(9,2) not null ,
    r18_ventas decimal(8,2) not null ,
    r18_ventas_perd decimal(8,2) not null ,
    r18_ped_pend smallint not null ,
    r18_ped_bko smallint not null ,
    r18_meses_vta smallint not null ,
    r18_periodo_stk smallint not null ,
    r18_promedio_vta decimal(9,2) not null ,
    r18_reorden decimal(9,2) not null 
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".rept018 from "public";

{ TABLE "fobos".rept022 row size = 124 number of columns = 17 index size = 114 }
create table "fobos".rept022 
  (
    r22_compania integer not null ,
    r22_localidad smallint not null ,
    r22_numprof integer not null ,
    r22_bodega char(2) not null ,
    r22_item char(15) not null ,
    r22_item_ant char(15),
    r22_descripcion varchar(35,20) not null ,
    r22_orden smallint not null ,
    r22_cantidad decimal(8,2) not null ,
    r22_porc_descto decimal(4,2) not null ,
    r22_val_descto decimal(10,2) not null ,
    r22_precio decimal(11,2) not null ,
    r22_val_impto decimal(11,2) not null ,
    r22_costo decimal(11,2) not null ,
    r22_linea char(5) not null ,
    r22_rotacion char(2) not null ,
    r22_dias_ent smallint not null 
  )  extent size 9957 next size 995 lock mode row;
revoke all on "fobos".rept022 from "public";

{ TABLE "fobos".rept025 row size = 42 number of columns = 10 index size = 52 }
create table "fobos".rept025 
  (
    r25_compania integer not null ,
    r25_localidad smallint not null ,
    r25_numprev integer not null ,
    r25_valor_ant decimal(11,2) not null ,
    r25_valor_cred decimal(11,2) not null ,
    r25_interes decimal(4,2) not null ,
    r25_dividendos smallint not null ,
    r25_plazo smallint not null ,
    r25_cod_tran char(2),
    r25_num_tran decimal(15,0)
  )  extent size 372 next size 37 lock mode row;
revoke all on "fobos".rept025 from "public";

{ TABLE "fobos".rept026 row size = 30 number of columns = 7 index size = 45 }
create table "fobos".rept026 
  (
    r26_compania integer not null ,
    r26_localidad smallint not null ,
    r26_numprev integer not null ,
    r26_dividendo smallint not null ,
    r26_valor_cap decimal(11,2) not null ,
    r26_valor_int decimal(11,2) not null ,
    r26_fec_vcto date not null 
  )  extent size 297 next size 29 lock mode row;
revoke all on "fobos".rept026 from "public";

{ TABLE "fobos".rept029 row size = 30 number of columns = 5 index size = 87 }
create table "fobos".rept029 
  (
    r29_compania integer not null ,
    r29_localidad smallint not null ,
    r29_numliq integer not null ,
    r29_pedido char(10) not null ,
    r29_factura char(10)
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".rept029 from "public";

{ TABLE "fobos".rept031 row size = 58 number of columns = 10 index size = 105 }
create table "fobos".rept031 
  (
    r31_compania integer not null ,
    r31_ano smallint not null ,
    r31_mes smallint not null ,
    r31_bodega char(2) not null ,
    r31_item char(15) not null ,
    r31_stock decimal(8,2) not null ,
    r31_costo_mb decimal(11,2) not null ,
    r31_costo_ma decimal(11,2) not null ,
    r31_precio_mb decimal(11,2) not null ,
    r31_precio_ma decimal(11,2) not null 
  )  extent size 59590 next size 5959 lock mode row;
revoke all on "fobos".rept031 from "public";

{ TABLE "fobos".rept032 row size = 53 number of columns = 12 index size = 96 }
create table "fobos".rept032 
  (
    r32_compania integer not null ,
    r32_numreg integer not null ,
    r32_estado char(1) not null ,
    r32_moneda char(2) not null ,
    r32_rubro_base char(1) not null ,
    r32_porc_fact decimal(7,2) not null ,
    r32_linea char(5) not null ,
    r32_rotacion char(2),
    r32_tipo_item smallint,
    r32_usuario varchar(10,5) not null ,
    r32_fecing datetime year to second not null ,
    r32_fecpro datetime year to second not null ,
    
    check (r32_estado IN ('A' ,'P' )),
    
    check (r32_rubro_base IN ('P' ,'C' ,'F' ))
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".rept032 from "public";

{ TABLE "fobos".rept033 row size = 190 number of columns = 16 index size = 139 }
create table "fobos".rept033 
  (
    r33_compania integer not null ,
    r33_localidad smallint not null ,
    r33_num_guia char(15) not null ,
    r33_cod_motivo integer not null ,
    r33_moneda char(2) not null ,
    r33_tipcomp_ori char(2) not null ,
    r33_numcomp_ori decimal(15,0) not null ,
    r33_nombre_dest varchar(30,15) not null ,
    r33_cedruc_dest varchar(15,10) not null ,
    r33_direcc_dest varchar(30,15) not null ,
    r33_nombre_tran varchar(30,15) not null ,
    r33_cedruc_tran varchar(15,10) not null ,
    r33_fec_ini date not null ,
    r33_fec_fin date not null ,
    r33_usuario varchar(10,5) not null ,
    r33_fecing datetime year to second not null 
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".rept033 from "public";

{ TABLE "fobos".rept050 row size = 59 number of columns = 11 index size = 99 }
create table "fobos".rept050 
  (
    r50_compania integer not null ,
    r50_item char(15) not null ,
    r50_estado char(1) not null ,
    r50_fecha_alta date not null ,
    r50_indice_ant char(2) not null ,
    r50_indice_act char(2) not null ,
    r50_meses smallint not null ,
    r50_ventas decimal(8,2) not null ,
    r50_stock decimal(8,2) not null ,
    r50_usuario varchar(10,5) not null ,
    r50_fecing datetime year to second not null ,
    
    check (r50_estado IN ('A' ,'P' ))
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".rept050 from "public";

{ TABLE "fobos".rept051 row size = 46 number of columns = 9 index size = 61 }
create table "fobos".rept051 
  (
    r51_serial serial not null ,
    r51_compania integer not null ,
    r51_bodega char(2),
    r51_estado char(1) not null ,
    r51_bloqueo_trn char(1) not null ,
    r51_tot_ajuste decimal(12,2) not null ,
    r51_usuario varchar(10,5) not null ,
    r51_fec_gen datetime year to second not null ,
    r51_fec_fin datetime year to second not null ,
    
    check (r51_estado IN ('A' ,'P' )),
    
    check (r51_bloqueo_trn IN ('S' ,'N' ))
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".rept051 from "public";

{ TABLE "fobos".rept052 row size = 50 number of columns = 9 index size = 102 }
create table "fobos".rept052 
  (
    r52_compania integer not null ,
    r52_bodega char(2) not null ,
    r52_num_seccion smallint not null ,
    r52_num_linea smallint not null ,
    r52_item char(15) not null ,
    r52_linea char(5) not null ,
    r52_ubicacion char(10) not null ,
    r52_stock decimal(8,2) not null ,
    r52_conteo decimal(8,2) not null 
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".rept052 from "public";

{ TABLE "fobos".rept060 row size = 35 number of columns = 9 index size = 123 }
create table "fobos".rept060 
  (
    r60_compania integer not null ,
    r60_fecha date not null ,
    r60_bodega char(2) not null ,
    r60_vendedor smallint not null ,
    r60_moneda char(2) not null ,
    r60_linea char(5) not null ,
    r60_rotacion char(2) not null ,
    r60_precio decimal(12,2) not null ,
    r60_costo decimal(12,2) not null 
  )  extent size 927 next size 92 lock mode row;
revoke all on "fobos".rept060 from "public";

{ TABLE "fobos".rept061 row size = 52 number of columns = 11 index size = 93 }
create table "fobos".rept061 
  (
    r61_compania integer not null ,
    r61_ano smallint not null ,
    r61_mes smallint not null ,
    r61_bodega char(2) not null ,
    r61_linea char(5) not null ,
    r61_rotacion char(2) not null ,
    r61_costo_mb decimal(12,2) not null ,
    r61_costo_ma decimal(12,2) not null ,
    r61_precio_mb decimal(12,2) not null ,
    r61_precio_ma decimal(12,2) not null ,
    r61_fob decimal(12,2) not null 
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".rept061 from "public";

{ TABLE "fobos".rept062 row size = 49 number of columns = 10 index size = 84 }
create table "fobos".rept062 
  (
    r62_compania integer not null ,
    r62_ano smallint not null ,
    r62_mes smallint not null ,
    r62_bodega char(2) not null ,
    r62_linea char(5) not null ,
    r62_tipo_tran char(2) not null ,
    r62_venta_mb decimal(14,2) not null ,
    r62_venta_ma decimal(14,2) not null ,
    r62_costo_mb decimal(14,2) not null ,
    r62_costo_ma decimal(14,2) not null 
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".rept062 from "public";

{ TABLE "fobos".talt000 row size = 43 number of columns = 16 index size = 36 }
create table "fobos".talt000 
  (
    t00_compania integer not null ,
    t00_estado char(1) not null ,
    t00_valor_tarea char(1) not null ,
    t00_cia_vehic integer not null ,
    t00_codcli_int integer,
    t00_factor_mb decimal(9,2) not null ,
    t00_factor_ma decimal(9,2) not null ,
    t00_seudo_tarea char(2) not null ,
    t00_req_tal char(1),
    t00_dias_dev smallint not null ,
    t00_dev_mes char(1) not null ,
    t00_dias_elim smallint not null ,
    t00_elim_mes char(1) not null ,
    t00_dias_pres smallint not null ,
    t00_anopro integer not null ,
    t00_mespro smallint not null ,
    
    check (t00_estado IN ('A' ,'B' )),
    
    check (t00_valor_tarea IN ('O' ,'R' )),
    
    check (t00_dev_mes IN ('S' ,'N' )),
    
    check (t00_elim_mes IN ('S' ,'N' )) constraint "fobos".ck_04_talt000
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".talt000 from "public";

{ TABLE "fobos".veht001 row size = 65 number of columns = 9 index size = 67 }
create table "fobos".veht001 
  (
    v01_compania integer not null ,
    v01_vendedor smallint not null ,
    v01_nombres varchar(30,15) not null ,
    v01_iniciales char(3) not null ,
    v01_estado char(1) not null ,
    v01_tipo char(1) not null ,
    v01_codrol integer,
    v01_usuario varchar(10,5) not null ,
    v01_fecing datetime year to second not null ,
    
    check (v01_estado IN ('A' ,'B' )),
    
    check (v01_tipo IN ('I' ,'E' ))
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".veht001 from "public";

{ TABLE "fobos".veht002 row size = 61 number of columns = 9 index size = 64 }
create table "fobos".veht002 
  (
    v02_compania integer not null ,
    v02_bodega char(2) not null ,
    v02_nombre varchar(30,15) not null ,
    v02_estado char(1) not null ,
    v02_tipo char(1) not null ,
    v02_factura char(1) not null ,
    v02_localidad smallint not null ,
    v02_usuario varchar(10,5) not null ,
    v02_fecing datetime year to second not null ,
    
    check (v02_estado IN ('A' ,'B' )),
    
    check (v02_tipo IN ('F' ,'L' )),
    
    check (v02_factura IN ('S' ,'N' ))
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".veht002 from "public";

{ TABLE "fobos".veht004 row size = 46 number of columns = 5 index size = 49 }
create table "fobos".veht004 
  (
    v04_compania integer not null ,
    v04_tipo_veh smallint not null ,
    v04_nombre varchar(20,10) not null ,
    v04_usuario varchar(10,5) not null ,
    v04_fecing datetime year to second not null 
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".veht004 from "public";

{ TABLE "fobos".veht005 row size = 75 number of columns = 6 index size = 61 }
create table "fobos".veht005 
  (
    v05_compania integer not null ,
    v05_cod_color char(10) not null ,
    v05_descri_base varchar(20,10) not null ,
    v05_descri_extr varchar(20,10) not null ,
    v05_usuario varchar(10,5) not null ,
    v05_fecing datetime year to second not null 
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".veht005 from "public";

{ TABLE "fobos".veht007 row size = 26 number of columns = 5 index size = 33 }
create table "fobos".veht007 
  (
    v07_compania integer not null ,
    v07_codigo_plan smallint not null ,
    v07_num_meses smallint not null ,
    v07_coefi_letra decimal(15,14) not null ,
    v07_coefi_adic decimal(15,14) not null 
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".veht007 from "public";

{ TABLE "fobos".veht020 row size = 144 number of columns = 16 index size = 121 }
create table "fobos".veht020 
  (
    v20_compania integer not null ,
    v20_modelo char(15) not null ,
    v20_modelo_ext varchar(30,15) not null ,
    v20_tipo_veh smallint not null ,
    v20_linea char(5) not null ,
    v20_observacion varchar(40,20) not null ,
    v20_origen char(1) not null ,
    v20_moneda char(2) not null ,
    v20_precio decimal(11,2) not null ,
    v20_mon_prov char(2) not null ,
    v20_prec_exfab decimal(11,2) not null ,
    v20_cilindraje integer not null ,
    v20_stock smallint not null ,
    v20_pedidos smallint not null ,
    v20_usuario varchar(10,5) not null ,
    v20_fecing datetime year to second not null ,
    
    check (v20_origen IN ('N' ,'I' ))
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".veht020 from "public";

{ TABLE "fobos".veht021 row size = 128 number of columns = 11 index size = 94 }
create table "fobos".veht021 
  (
    v21_compania integer not null ,
    v21_modelo char(15) not null ,
    v21_secuencia smallint not null ,
    v21_descripcion varchar(60,30) not null ,
    v21_tipo char(1) not null ,
    v21_cod_prov char(10),
    v21_mon_costo char(2),
    v21_val_costo decimal(11,2),
    v21_precio decimal(11,2),
    v21_usuario varchar(10,5) not null ,
    v21_fecing datetime year to second not null ,
    
    check (v21_tipo IN ('I' ,'O' ))
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".veht021 from "public";

{ TABLE "fobos".veht024 row size = 4 number of columns = 1 index size = 0 }
create table "fobos".veht024 
  (
    v24_compania integer not null 
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".veht024 from "public";

{ TABLE "fobos".veht025 row size = 4 number of columns = 1 index size = 0 }
create table "fobos".veht025 
  (
    v25_compania integer not null 
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".veht025 from "public";

{ TABLE "fobos".veht026 row size = 306 number of columns = 28 index size = 162 }
create table "fobos".veht026 
  (
    v26_compania integer not null ,
    v26_localidad smallint not null ,
    v26_numprev integer not null ,
    v26_estado char(1) not null ,
    v26_bodega char(2),
    v26_codcli integer not null ,
    v26_vendedor smallint not null ,
    v26_reserva varchar(180,10),
    v26_cont_cred char(1) not null ,
    v26_moneda char(2) not null ,
    v26_paridad decimal(16,9) not null ,
    v26_precision smallint not null ,
    v26_tot_costo decimal(12,2) not null ,
    v26_tot_bruto decimal(12,2) not null ,
    v26_tot_dscto decimal(11,2) not null ,
    v26_tot_neto decimal(12,2) not null ,
    v26_tot_pa_nc decimal(12,2) not null ,
    v26_cuotai_fin decimal(11,2) not null ,
    v26_int_cuotaif decimal(4,2),
    v26_num_cuotaif smallint,
    v26_sdo_credito decimal(11,2) not null ,
    v26_codigo_plan smallint,
    v26_num_vctos smallint,
    v26_int_saldo decimal(4,2) not null ,
    v26_cod_tran char(2),
    v26_num_tran decimal(15,0),
    v26_usuario varchar(10,5) not null ,
    v26_fecing datetime year to second not null ,
    
    check (v26_estado IN ('A' ,'P' ,'B' ,'F' )),
    
    check (v26_cont_cred IN ('C' ,'R' )),
    
    check (v26_precision IN (0 ,1 ,2 ))
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".veht026 from "public";

{ TABLE "fobos".veht027 row size = 31 number of columns = 7 index size = 69 }
create table "fobos".veht027 
  (
    v27_compania integer not null ,
    v27_localidad smallint not null ,
    v27_numprev integer not null ,
    v27_codigo_veh integer not null ,
    v27_precio decimal(12,2) not null ,
    v27_descuento decimal(4,2) not null ,
    v27_val_descto decimal(11,2) not null 
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".veht027 from "public";

{ TABLE "fobos".veht028 row size = 38 number of columns = 9 index size = 46 }
create table "fobos".veht028 
  (
    v28_compania integer not null ,
    v28_localidad smallint not null ,
    v28_numprev integer not null ,
    v28_dividendo smallint not null ,
    v28_tipo char(1) not null ,
    v28_fecha_vcto date not null ,
    v28_val_adi decimal(12,2) not null ,
    v28_val_int decimal(12,2) not null ,
    v28_val_cap decimal(12,2) not null ,
    
    check (v28_tipo IN ('V' ,'I' ))
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".veht028 from "public";

{ TABLE "fobos".veht029 row size = 43 number of columns = 9 index size = 69 }
create table "fobos".veht029 
  (
    v29_compania integer not null ,
    v29_localidad smallint not null ,
    v29_numprev integer not null ,
    v29_tipo_doc char(2) not null ,
    v29_numdoc char(10) not null ,
    v29_moneda char(2) not null ,
    v29_paridad decimal(16,9) not null ,
    v29_precision smallint not null ,
    v29_valor decimal(12,2) not null ,
    
    check (v29_tipo_doc IN ('PA' ,'NC' )),
    
    check (v29_precision IN (0 ,1 ,2 ))
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".veht029 from "public";

{ TABLE "fobos".veht030 row size = 301 number of columns = 34 index size = 250 }
create table "fobos".veht030 
  (
    v30_compania integer not null ,
    v30_localidad smallint not null ,
    v30_cod_tran char(2) not null ,
    v30_num_tran decimal(15,0) not null ,
    v30_cod_subtipo integer,
    v30_cont_cred char(1) not null ,
    v30_referencia varchar(40,20),
    v30_codcli integer,
    v30_nomcli varchar(40,20) not null ,
    v30_dircli varchar(40,20) not null ,
    v30_telcli char(10),
    v30_cedruc char(15) not null ,
    v30_vendedor smallint not null ,
    v30_oc_externa varchar(15,8),
    v30_oc_interna integer,
    v30_descuento decimal(4,2) not null ,
    v30_porc_impto decimal(4,2) not null ,
    v30_tipo_dev char(2),
    v30_num_dev decimal(15,0),
    v30_bodega_ori char(2) not null ,
    v30_bodega_dest char(2) not null ,
    v30_fact_costo decimal(9,2),
    v30_fact_venta decimal(9,2),
    v30_moneda char(2) not null ,
    v30_paridad decimal(16,9) not null ,
    v30_precision smallint not null ,
    v30_tot_costo decimal(12,2) not null ,
    v30_tot_bruto decimal(12,2) not null ,
    v30_tot_dscto decimal(11,2) not null ,
    v30_tot_neto decimal(12,2) not null ,
    v30_flete decimal(11,2) not null ,
    v30_numliq integer,
    v30_usuario varchar(10,5) not null ,
    v30_fecing datetime year to second not null ,
    
    check (v30_cont_cred IN ('C' ,'R' )),
    
    check (v30_precision IN (0 ,1 ,2 ))
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".veht030 from "public";

{ TABLE "fobos".veht032 row size = 30 number of columns = 5 index size = 54 }
create table "fobos".veht032 
  (
    v32_compania integer not null ,
    v32_linea char(5) not null ,
    v32_porc_min smallint not null ,
    v32_usuario varchar(10,5) not null ,
    v32_fecing datetime year to second not null 
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".veht032 from "public";

{ TABLE "fobos".veht034 row size = 136 number of columns = 16 index size = 139 }
create table "fobos".veht034 
  (
    v34_compania integer not null ,
    v34_localidad smallint not null ,
    v34_pedido char(10) not null ,
    v34_estado char(1) not null ,
    v34_tipo char(1) not null ,
    v34_referencia varchar(60,30) not null ,
    v34_proveedor integer not null ,
    v34_fec_envio date,
    v34_fec_llegada date,
    v34_unid_ped smallint not null ,
    v34_unid_liq smallint not null ,
    v34_moneda char(2) not null ,
    v34_tot_valor decimal(13,2) not null ,
    v34_aux_cont char(12),
    v34_usuario varchar(10,5) not null ,
    v34_fecing datetime year to second not null ,
    
    check (v34_estado IN ('A' ,'R' ,'L' ,'P' )),
    
    check (v34_tipo IN ('I' ,'N' ))
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".veht034 from "public";

{ TABLE "fobos".veht035 row size = 96 number of columns = 16 index size = 175 }
create table "fobos".veht035 
  (
    v35_compania integer not null ,
    v35_localidad smallint not null ,
    v35_pedido char(10) not null ,
    v35_secuencia smallint not null ,
    v35_estado char(1) not null ,
    v35_modelo char(15) not null ,
    v35_cod_color char(10) not null ,
    v35_codigo_veh integer,
    v35_precio_unit decimal(12,2) not null ,
    v35_bodega_alm char(2),
    v35_bodega_liq char(2),
    v35_numero_liq integer,
    v35_flete decimal(11,2) not null ,
    v35_costo_liq decimal(12,2) not null ,
    v35_fecha_lleg date,
    v35_factura char(15),
    
    check (v35_estado IN ('A' ,'R' ,'L' ,'P' ))
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".veht035 from "public";

{ TABLE "fobos".veht036 row size = 284 number of columns = 29 index size = 124 }
create table "fobos".veht036 
  (
    v36_compania integer not null ,
    v36_localidad smallint not null ,
    v36_numliq integer not null ,
    v36_pedido char(10) not null ,
    v36_estado char(1) not null ,
    v36_descripcion varchar(30,15) not null ,
    v36_origen char(15) not null ,
    v36_forma_pago varchar(30,15) not null ,
    v36_num_pi char(20),
    v36_guia char(15),
    v36_pedimento char(10),
    v36_fecha_lleg date not null ,
    v36_fecha_ing date not null ,
    v36_moneda char(2) not null ,
    v36_fob_fabrica decimal(12,2) not null ,
    v36_inland decimal(11,2) not null ,
    v36_flete decimal(11,2) not null ,
    v36_otros decimal(11,2) not null ,
    v36_total_fob decimal(12,2) not null ,
    v36_seguro decimal(11,2) not null ,
    v36_tot_cargos decimal(12,2) not null ,
    v36_fact_costo decimal(8,2) not null ,
    v36_margen_uti decimal(8,2) not null ,
    v36_elaborado varchar(30,15) not null ,
    v36_bodega char(2) not null ,
    v36_paridad_mb decimal(16,9) not null ,
    v36_paridad_ma decimal(16,9) not null ,
    v36_usuario varchar(10,5) not null ,
    v36_fecing datetime year to second not null ,
    
    check (v36_estado IN ('A' ,'P' ,'E' ))
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".veht036 from "public";

{ TABLE "fobos".veht037 row size = 78 number of columns = 13 index size = 69 }
create table "fobos".veht037 
  (
    v37_compania integer not null ,
    v37_localidad smallint not null ,
    v37_numliq integer not null ,
    v37_serial serial not null ,
    v37_codrubro integer not null ,
    v37_orden smallint not null ,
    v37_fecha date,
    v37_observacion varchar(30,15),
    v37_indicador char(1) not null ,
    v37_base char(3),
    v37_moneda char(2) not null ,
    v37_paridad decimal(16,9) not null ,
    v37_valor decimal(12,2) not null 
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".veht037 from "public";

{ TABLE "fobos".veht039 row size = 36 number of columns = 8 index size = 117 }
create table "fobos".veht039 
  (
    v39_compania integer not null ,
    v39_bodega char(2) not null ,
    v39_modelo char(15) not null ,
    v39_ano smallint not null ,
    v39_mes smallint not null ,
    v39_moneda char(2) not null ,
    v39_uni_venta smallint not null ,
    v39_val_venta decimal(12,2) not null 
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".veht039 from "public";

{ TABLE "fobos".veht040 row size = 43 number of columns = 10 index size = 162 }
create table "fobos".veht040 
  (
    v40_compania integer not null ,
    v40_bodega char(2) not null ,
    v40_modelo char(15) not null ,
    v40_linea char(5) not null ,
    v40_vendedor smallint not null ,
    v40_ano smallint not null ,
    v40_mes smallint not null ,
    v40_moneda char(2) not null ,
    v40_uni_venta smallint not null ,
    v40_valor decimal(12,2) not null 
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".veht040 from "public";

{ TABLE "fobos".ordt000 row size = 23 number of columns = 7 index size = 12 }
create table "fobos".ordt000 
  (
    c00_compania integer not null ,
    c00_estado char(1) not null ,
    c00_cuando_ret char(1) not null ,
    c00_valmin_mb decimal(12,2) not null ,
    c00_valmin_ma decimal(12,2) not null ,
    c00_dias_react smallint not null ,
    c00_react_mes char(1) not null ,
    
    check (c00_estado IN ('A' ,'B' )),
    
    check (c00_cuando_ret IN ('C' ,'P' )),
    
    check (c00_react_mes IN ('S' ,'N' ))
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".ordt000 from "public";

{ TABLE "fobos".ordt010 row size = 390 number of columns = 41 index size = 237 }
create table "fobos".ordt010 
  (
    c10_compania integer not null ,
    c10_localidad smallint not null ,
    c10_numero_oc integer not null ,
    c10_tipo_orden integer not null ,
    c10_cod_depto smallint not null ,
    c10_solicitado varchar(25,15) not null ,
    c10_estado char(1) not null ,
    c10_codprov integer not null ,
    c10_atencion varchar(25,15) not null ,
    c10_referencia varchar(120,20) not null ,
    c10_usua_aprob varchar(10,5),
    c10_fecha_aprob datetime year to second,
    c10_fecha_entre datetime year to second,
    c10_ord_trabajo integer,
    c10_recargo decimal(5,2) not null ,
    c10_porc_descto decimal(4,2) not null ,
    c10_porc_impto decimal(4,2) not null ,
    c10_moneda char(2) not null ,
    c10_paridad decimal(16,9) not null ,
    c10_precision smallint not null ,
    c10_tipo_pago char(1) not null ,
    c10_interes decimal(4,2) not null ,
    c10_tot_repto decimal(12,2) not null ,
    c10_tot_mano decimal(12,2) not null ,
    c10_tot_dscto decimal(11,2) not null ,
    c10_dif_cuadre decimal(8,2) not null ,
    c10_tot_impto decimal(11,2) not null ,
    c10_tot_compra decimal(12,2) not null ,
    c10_flete decimal(11,2) not null ,
    c10_otros decimal(11,2) not null ,
    c10_factura char(21),
    c10_fecha_fact date,
    c10_cod_sust_sri char(2) not null ,
    c10_sustento_sri char(1) not null ,
    c10_cod_ice smallint,
    c10_porc_ice decimal(5,2),
    c10_cod_ice_imp varchar(15,6),
    c10_base_ice decimal(12,2) not null ,
    c10_valor_ice decimal(12,2) not null ,
    c10_usuario varchar(10,5) not null ,
    c10_fecing datetime year to second not null ,
    
    check (c10_precision IN (0 ,1 ,2 )),
    
    check (c10_tipo_pago IN ('C' ,'R' )),
    
    check (c10_estado IN ('A' ,'E' ,'P' ,'C' )),
    
    check (c10_sustento_sri IN ('S' ,'N' )) constraint "fobos".ck_04_ordt010
  )  extent size 692 next size 69 lock mode row;
revoke all on "fobos".ordt010 from "public";

{ TABLE "fobos".ordt012 row size = 30 number of columns = 7 index size = 45 }
create table "fobos".ordt012 
  (
    c12_compania integer not null ,
    c12_localidad smallint not null ,
    c12_numero_oc integer not null ,
    c12_dividendo smallint not null ,
    c12_fecha_vcto date not null ,
    c12_valor_cap decimal(12,2) not null ,
    c12_valor_int decimal(12,2) not null 
  )  extent size 97 next size 16 lock mode row;
revoke all on "fobos".ordt012 from "public";

{ TABLE "fobos".ordt013 row size = 180 number of columns = 25 index size = 103 }
create table "fobos".ordt013 
  (
    c13_compania integer not null ,
    c13_localidad smallint not null ,
    c13_numero_oc integer not null ,
    c13_num_recep smallint not null ,
    c13_estado char(1) not null ,
    c13_fecha_recep datetime year to second not null ,
    c13_num_guia char(21) not null ,
    c13_factura char(21),
    c13_bodega char(2),
    c13_interes decimal(4,2) not null ,
    c13_tot_bruto decimal(12,2) not null ,
    c13_tot_dscto decimal(11,2) not null ,
    c13_dif_cuadre decimal(8,2) not null ,
    c13_tot_impto decimal(11,2) not null ,
    c13_tot_recep decimal(12,2) not null ,
    c13_flete decimal(11,2) not null ,
    c13_otros decimal(11,2) not null ,
    c13_fecha_eli datetime year to second,
    c13_num_ret integer,
    c13_serie_comp char(6) not null ,
    c13_num_aut char(10) not null ,
    c13_fecha_cadu date,
    c13_fec_aut char(14),
    c13_usuario varchar(10,5) not null ,
    c13_fecing datetime year to second not null ,
    
    check (c13_estado IN ('A' ,'E' ))
  )  extent size 319 next size 31 lock mode row;
revoke all on "fobos".ordt013 from "public";

{ TABLE "fobos".veht000 row size = 40 number of columns = 17 index size = 39 }
create table "fobos".veht000 
  (
    v00_compania integer not null ,
    v00_estado char(1) not null ,
    v00_genera_op char(1) not null ,
    v00_gen_aju_op char(1) not null ,
    v00_cia_taller integer not null ,
    v00_bodega_fact char(2),
    v00_dias_prof smallint not null ,
    v00_expi_prof smallint not null ,
    v00_dias_dev smallint not null ,
    v00_dev_mes char(1) not null ,
    v00_cart_cred smallint not null ,
    v00_cart_cif smallint not null ,
    v00_anopro smallint not null ,
    v00_mespro smallint not null ,
    v00_fecha_cd date,
    v00_fecha_cm date,
    v00_fecha_ca date,
    
    check (v00_estado IN ('A' ,'B' )),
    
    check (v00_genera_op IN ('S' ,'N' )),
    
    check (v00_gen_aju_op IN ('S' ,'N' )),
    
    check (v00_dev_mes IN ('S' ,'N' ))
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".veht000 from "public";

{ TABLE "fobos".veht006 row size = 71 number of columns = 15 index size = 49 }
create table "fobos".veht006 
  (
    v06_compania integer not null ,
    v06_codigo_plan smallint not null ,
    v06_nonbre_plan varchar(25,15) not null ,
    v06_estado char(1) not null ,
    v06_codigo_cobr integer,
    v06_cred_direct char(1) not null ,
    v06_cod_cartera smallint not null ,
    v06_seguro char(1) not null ,
    v06_tasa_finan decimal(4,2) not null ,
    v06_plazo smallint not null ,
    v06_porc_inic decimal(4,2) not null ,
    v06_adicionales char(1) not null ,
    v06_num_adic smallint not null ,
    v06_usuario varchar(10,5) not null ,
    v06_fecing datetime year to second not null ,
    
    check (v06_estado IN ('A' ,'I' )),
    
    check (v06_cred_direct IN ('S' ,'N' )),
    
    check (v06_seguro IN ('S' ,'N' )),
    
    check (v06_adicionales IN ('S' ,'N' ))
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".veht006 from "public";

{ TABLE "fobos".cxct000 row size = 78 number of columns = 16 index size = 132 }
create table "fobos".cxct000 
  (
    z00_compania integer not null ,
    z00_estado char(1) not null ,
    z00_credit_auto char(1) not null ,
    z00_credit_dias smallint not null ,
    z00_tasa_mora decimal(5,2) not null ,
    z00_cobra_mora char(1) not null ,
    z00_bloq_vencido char(1) not null ,
    z00_aux_clte_mb char(12),
    z00_aux_clte_ma char(12),
    z00_aux_ant_mb char(12),
    z00_aux_ant_ma char(12),
    z00_anopro smallint not null ,
    z00_mespro smallint not null ,
    z00_fecha_cd date,
    z00_fecha_cm date,
    z00_fecha_ca date,
    
    check (z00_bloq_vencido IN ('S' ,'N' )),
    
    check (z00_estado IN ('A' ,'B' )),
    
    check (z00_credit_auto IN ('S' ,'N' )),
    
    check (z00_cobra_mora IN ('S' ,'N' ))
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".cxct000 from "public";

{ TABLE "fobos".cxct002 row size = 291 number of columns = 25 index size = 226 }
create table "fobos".cxct002 
  (
    z02_compania integer not null ,
    z02_localidad smallint not null ,
    z02_codcli integer not null ,
    z02_contacto varchar(30,15),
    z02_referencia varchar(40,20),
    z02_credit_auto char(1) not null ,
    z02_credit_dias smallint not null ,
    z02_cupocred_mb decimal(12,2) not null ,
    z02_cupocred_ma decimal(12,2) not null ,
    z02_dcto_item_c decimal(4,2) not null ,
    z02_dcto_item_r decimal(4,2) not null ,
    z02_dcto_mano_c decimal(4,2) not null ,
    z02_dcto_mano_r decimal(4,2) not null ,
    z02_cheques char(1) not null ,
    z02_zona_venta smallint,
    z02_zona_cobro smallint,
    z02_aux_clte_mb char(12),
    z02_aux_clte_ma char(12),
    z02_aux_ant_mb char(12),
    z02_aux_ant_ma char(12),
    z02_contr_espe char(5),
    z02_oblig_cont char(2),
    z02_email varchar(100),
    z02_usuario varchar(10,5) not null ,
    z02_fecing datetime year to second not null ,
    
    check (z02_credit_auto IN ('S' ,'N' )),
    
    check (z02_cheques IN ('S' ,'N' )),
    
    check (z02_oblig_cont IN ('SI' ,'NO' ,NULL )) constraint "fobos".ck_03_cxct002
  )  extent size 1544 next size 154 lock mode row;
revoke all on "fobos".cxct002 from "public";

{ TABLE "fobos".cxct003 row size = 60 number of columns = 14 index size = 82 }
create table "fobos".cxct003 
  (
    z03_compania integer not null ,
    z03_localidad smallint not null ,
    z03_areaneg smallint not null ,
    z03_codcli integer not null ,
    z03_credit_auto char(1) not null ,
    z03_credit_dias smallint not null ,
    z03_cupocred_mb decimal(12,2) not null ,
    z03_cupocred_ma decimal(12,2) not null ,
    z03_dcto_item_c decimal(4,2) not null ,
    z03_dcto_item_r decimal(4,2) not null ,
    z03_dcto_mano_c decimal(4,2) not null ,
    z03_dcto_mano_r decimal(4,2) not null ,
    z03_usuario varchar(10,5) not null ,
    z03_fecing datetime year to second not null ,
    
    check (z03_credit_auto IN ('S' ,'N' ))
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".cxct003 from "public";

{ TABLE "fobos".cxct004 row size = 38 number of columns = 6 index size = 31 }
create table "fobos".cxct004 
  (
    z04_tipo_doc char(2) not null ,
    z04_nombre char(15) not null ,
    z04_estado char(1) not null ,
    z04_tipo char(1) not null ,
    z04_usuario varchar(10,5) not null ,
    z04_fecing datetime year to second not null ,
    
    check (z04_estado IN ('A' ,'B' )),
    
    check (z04_tipo IN ('D' ,'F' ,'T' ))
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".cxct004 from "public";

{ TABLE "fobos".cxct005 row size = 63 number of columns = 9 index size = 67 }
create table "fobos".cxct005 
  (
    z05_compania integer not null ,
    z05_codigo smallint not null ,
    z05_nombres varchar(30,15) not null ,
    z05_estado char(1) not null ,
    z05_tipo char(1) not null ,
    z05_codrol integer,
    z05_comision char(1) not null ,
    z05_usuario varchar(10,5) not null ,
    z05_fecing datetime year to second not null ,
    
    check (z05_estado IN ('A' ,'B' )),
    
    check (z05_tipo IN ('E' ,'C' )),
    
    check (z05_comision IN ('S' ,'N' )) constraint "fobos".ck_03_cxct005
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".cxct005 from "public";

{ TABLE "fobos".cxct006 row size = 54 number of columns = 6 index size = 31 }
create table "fobos".cxct006 
  (
    z06_zona_cobro smallint not null ,
    z06_nombre varchar(30,15) not null ,
    z06_estado char(1) not null ,
    z06_comision char(1) not null ,
    z06_usuario varchar(10,5) not null ,
    z06_fecing datetime year to second not null ,
    
    check (z06_estado IN ('A' ,'B' )) constraint "fobos".ck_01_cxct006,
    
    check (z06_comision IN ('S' ,'N' )) constraint "fobos".ck_02_cxct006
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".cxct006 from "public";

{ TABLE "fobos".cxct007 row size = 24 number of columns = 5 index size = 24 }
create table "fobos".cxct007 
  (
    z07_serial serial not null ,
    z07_compania integer not null ,
    z07_monto_ini decimal(12,2) not null ,
    z07_monto_fin decimal(12,2) not null ,
    z07_plazo_dias smallint not null 
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".cxct007 from "public";

{ TABLE "fobos".cxct026 row size = 137 number of columns = 16 index size = 192 }
create table "fobos".cxct026 
  (
    z26_compania integer not null ,
    z26_localidad smallint not null ,
    z26_codcli integer not null ,
    z26_banco integer not null ,
    z26_num_cta char(15) not null ,
    z26_num_cheque char(15) not null ,
    z26_estado char(1) not null ,
    z26_referencia varchar(40,10) not null ,
    z26_valor decimal(12,2) not null ,
    z26_fecha_cobro date not null ,
    z26_areaneg smallint,
    z26_tipo_doc char(2),
    z26_num_doc char(15),
    z26_dividendo smallint,
    z26_usuario varchar(10,5) not null ,
    z26_fecing datetime year to second not null ,
    
    check (z26_estado IN ('A' ,'B' ))
  )  extent size 26 next size 16 lock mode row;
revoke all on "fobos".cxct026 from "public";

{ TABLE "fobos".cxct030 row size = 35 number of columns = 8 index size = 72 }
create table "fobos".cxct030 
  (
    z30_compania integer not null ,
    z30_localidad smallint not null ,
    z30_areaneg smallint not null ,
    z30_codcli integer not null ,
    z30_moneda char(2) not null ,
    z30_saldo_venc decimal(12,2) not null ,
    z30_saldo_xvenc decimal(12,2) not null ,
    z30_saldo_favor decimal(12,2) not null 
  )  extent size 119 next size 16 lock mode row;
revoke all on "fobos".cxct030 from "public";

{ TABLE "fobos".cxct031 row size = 51 number of columns = 13 index size = 111 }
create table "fobos".cxct031 
  (
    z31_compania integer not null ,
    z31_ano smallint not null ,
    z31_mes smallint not null ,
    z31_localidad smallint not null ,
    z31_areaneg smallint not null ,
    z31_cartera smallint not null ,
    z31_tipo_clte smallint not null ,
    z31_linea char(5) not null ,
    z31_moneda char(2) not null ,
    z31_saldo_venc decimal(12,2) not null ,
    z31_saldo_xvenc decimal(12,2) not null ,
    z31_tot_creditos decimal(12,2) not null ,
    z31_tot_pagos decimal(12,2) not null 
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".cxct031 from "public";

{ TABLE "fobos".cxct032 row size = 19 number of columns = 6 index size = 48 }
create table "fobos".cxct032 
  (
    z32_compania integer not null ,
    z32_recaudador smallint not null ,
    z32_ano smallint not null ,
    z32_mes smallint not null ,
    z32_num_cobros smallint not null ,
    z32_valor decimal(12,2) not null 
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".cxct032 from "public";

{ TABLE "fobos".cxpt000 row size = 70 number of columns = 12 index size = 132 }
create table "fobos".cxpt000 
  (
    p00_compania integer not null ,
    p00_estado char(1) not null ,
    p00_tipo_egr_gen char(1) not null ,
    p00_aux_prov_mb char(12),
    p00_aux_prov_ma char(12),
    p00_aux_ant_mb char(12),
    p00_aux_ant_ma char(12),
    p00_anopro smallint not null ,
    p00_mespro smallint not null ,
    p00_fecha_cd date,
    p00_fecha_cm date,
    p00_fecha_ca date,
    
    check (p00_estado IN ('A' ,'B' )),
    
    check (p00_tipo_egr_gen IN ('D' ,'R' ))
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".cxpt000 from "public";

{ TABLE "fobos".cxpt002 row size = 299 number of columns = 24 index size = 235 }
create table "fobos".cxpt002 
  (
    p02_compania integer not null ,
    p02_localidad smallint not null ,
    p02_codprov integer not null ,
    p02_contacto varchar(30,15),
    p02_referencia varchar(40,20),
    p02_credit_dias smallint not null ,
    p02_cupocred_mb decimal(12,2) not null ,
    p02_cupocred_ma decimal(12,2) not null ,
    p02_descuento decimal(4,2) not null ,
    p02_recargo decimal(4,2) not null ,
    p02_int_ext char(1) not null ,
    p02_dias_demora smallint not null ,
    p02_dias_seguri smallint not null ,
    p02_aux_prov_mb char(12),
    p02_aux_prov_ma char(12),
    p02_aux_ant_mb char(12),
    p02_aux_ant_ma char(12),
    p02_banco_prov integer,
    p02_cod_bco_tra char(2),
    p02_tip_cta_prov char(1),
    p02_cta_prov char(15),
    p02_email varchar(100),
    p02_usuario varchar(10,5) not null ,
    p02_fecing datetime year to second not null ,
    
    check (p02_int_ext IN ('I' ,'E' )),
    
    check (p02_tip_cta_prov IN ('A' ,'C' ,NULL )) constraint "fobos".ck_02_cxpt002
  )  extent size 110 next size 16 lock mode row;
revoke all on "fobos".cxpt002 from "public";

{ TABLE "fobos".cxpt003 row size = 58 number of columns = 14 index size = 82 }
create table "fobos".cxpt003 
  (
    p03_compania integer not null ,
    p03_localidad smallint not null ,
    p03_areaneg smallint not null ,
    p03_codprov integer not null ,
    p03_credit_dias smallint not null ,
    p03_cupocred_mb decimal(12,2) not null ,
    p03_cupocred_ma decimal(12,2) not null ,
    p03_descuento decimal(4,2) not null ,
    p03_recargo decimal(4,2) not null ,
    p03_int_ext char(1) not null ,
    p03_dias_demora smallint not null ,
    p03_dias_seguri smallint not null ,
    p03_usuario varchar(10,5) not null ,
    p03_fecing datetime year to second not null ,
    
    check (p03_int_ext IN ('I' ,'E' ))
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".cxpt003 from "public";

{ TABLE "fobos".cxpt004 row size = 38 number of columns = 6 index size = 31 }
create table "fobos".cxpt004 
  (
    p04_tipo_doc char(2) not null ,
    p04_nombre char(15) not null ,
    p04_estado char(1) not null ,
    p04_tipo char(1) not null ,
    p04_usuario varchar(10,5) not null ,
    p04_fecing datetime year to second not null ,
    
    check (p04_estado IN ('A' ,'B' )),
    
    check (p04_tipo IN ('D' ,'F' ,'T' ))
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".cxpt004 from "public";

{ TABLE "fobos".cxpt025 row size = 69 number of columns = 12 index size = 103 }
create table "fobos".cxpt025 
  (
    p25_compania integer not null ,
    p25_localidad smallint not null ,
    p25_orden_pago integer not null ,
    p25_secuencia smallint not null ,
    p25_codprov integer not null ,
    p25_tipo_doc char(2) not null ,
    p25_num_doc char(21) not null ,
    p25_dividendo smallint not null ,
    p25_valor_cap decimal(12,2) not null ,
    p25_valor_int decimal(12,2) not null ,
    p25_valor_mora decimal(11,2) not null ,
    p25_valor_ret decimal(11,2) not null 
  )  extent size 242 next size 24 lock mode row;
revoke all on "fobos".cxpt025 from "public";

{ TABLE "fobos".cxpt026 row size = 41 number of columns = 10 index size = 105 }
create table "fobos".cxpt026 
  (
    p26_compania integer not null ,
    p26_localidad smallint not null ,
    p26_orden_pago integer not null ,
    p26_secuencia smallint not null ,
    p26_tipo_ret char(1) not null ,
    p26_porcentaje decimal(5,2) not null ,
    p26_codigo_sri char(6) not null ,
    p26_fecha_ini_porc date not null ,
    p26_valor_base decimal(12,2) not null ,
    p26_valor_ret decimal(11,2) not null 
  )  extent size 72 next size 16 lock mode row;
revoke all on "fobos".cxpt026 from "public";

{ TABLE "fobos".cxpt028 row size = 77 number of columns = 15 index size = 138 }
create table "fobos".cxpt028 
  (
    p28_compania integer not null ,
    p28_localidad smallint not null ,
    p28_num_ret integer not null ,
    p28_secuencia smallint not null ,
    p28_codprov integer not null ,
    p28_tipo_doc char(2) not null ,
    p28_num_doc char(21) not null ,
    p28_dividendo smallint not null ,
    p28_valor_fact decimal(12,2) not null ,
    p28_tipo_ret char(1) not null ,
    p28_porcentaje decimal(5,2) not null ,
    p28_codigo_sri char(6),
    p28_fecha_ini_porc date,
    p28_valor_base decimal(12,2) not null ,
    p28_valor_ret decimal(11,2) not null ,
    
    check (p28_tipo_ret IN ('F' ,'I' ))
  )  extent size 303 next size 30 lock mode row;
revoke all on "fobos".cxpt028 from "public";

{ TABLE "fobos".cajt000 row size = 5 number of columns = 2 index size = 12 }
create table "fobos".cajt000 
  (
    j00_compania integer not null ,
    j00_estado char(1) not null ,
    
    check (j00_estado IN ('A' ,'B' ))
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".cajt000 from "public";

{ TABLE "fobos".cajt001 row size = 60 number of columns = 9 index size = 69 }
create table "fobos".cajt001 
  (
    j01_compania integer not null ,
    j01_codigo_pago char(2) not null ,
    j01_cont_cred char(1) not null ,
    j01_nombre char(20) not null ,
    j01_estado char(1) not null ,
    j01_aux_cont char(12),
    j01_retencion char(1) not null ,
    j01_usuario varchar(10,5) not null ,
    j01_fecing datetime year to second not null ,
    
    check (j01_estado IN ('A' ,'B' )),
    
    check (j01_cont_cred IN ('C' ,'R' )) constraint "fobos".ck_01_cajt001,
    
    check (j01_retencion IN ('S' ,'N' )) constraint "fobos".ck_02_cajt001
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".cajt001 from "public";

{ TABLE "fobos".cajt002 row size = 55 number of columns = 9 index size = 67 }
create table "fobos".cajt002 
  (
    j02_compania integer not null ,
    j02_localidad smallint not null ,
    j02_codigo_caja smallint not null ,
    j02_nombre_caja varchar(20,10) not null ,
    j02_pre_ventas char(1) not null ,
    j02_ordenes char(1) not null ,
    j02_solicitudes char(1) not null ,
    j02_usua_caja varchar(10,5) not null ,
    j02_aux_cont char(12),
    
    check (j02_pre_ventas IN ('S' ,'N' )),
    
    check (j02_ordenes IN ('S' ,'N' )),
    
    check (j02_solicitudes IN ('S' ,'N' ))
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".cajt002 from "public";

{ TABLE "fobos".cajt003 row size = 10 number of columns = 4 index size = 54 }
create table "fobos".cajt003 
  (
    j03_compania integer not null ,
    j03_localidad smallint not null ,
    j03_codigo_caja smallint not null ,
    j03_areaneg smallint not null 
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".cajt003 from "public";

{ TABLE "fobos".cajt999 row size = 83 number of columns = 14 index size = 49 }
create table "fobos".cajt999 
  (
    j04_serial serial not null ,
    j04_compania integer not null ,
    j04_localidad smallint not null ,
    j04_codigo_caja smallint not null ,
    j04_moneda char(2) not null ,
    j04_fecha_aper datetime year to second not null ,
    j04_ef_apertura decimal(12,2) not null ,
    j04_ch_apertura decimal(12,2) not null ,
    j04_ef_ing_dia decimal(12,2) not null ,
    j04_ch_ing_dia decimal(12,2) not null ,
    j04_ef_egr_dia decimal(12,2) not null ,
    j04_ch_egr_dia decimal(12,2) not null ,
    j04_fecha_cierre datetime year to second,
    j04_usuario varchar(10,5) not null 
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".cajt999 from "public";

{ TABLE "fobos".cajt012 row size = 176 number of columns = 20 index size = 187 }
create table "fobos".cajt012 
  (
    j12_compania integer not null ,
    j12_localidad smallint not null ,
    j12_banco smallint not null ,
    j12_num_cta char(15) not null ,
    j12_num_cheque char(15) not null ,
    j12_secuencia smallint not null ,
    j12_codcli integer,
    j12_areaneg smallint,
    j12_referencia varchar(60) not null ,
    j12_tipo_fuente char(2) not null ,
    j12_num_fuente integer not null ,
    j12_sec_cheque smallint not null ,
    j12_fec_caja date not null ,
    j12_moneda char(2) not null ,
    j12_valor decimal(12,2) not null ,
    j12_nd_banco char(10) not null ,
    j12_nd_fec_bco date not null ,
    j12_nd_interna char(15) not null ,
    j12_usuario varchar(10,5) not null ,
    j12_fecing datetime year to second not null 
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".cajt012 from "public";

{ TABLE "fobos".cajt013 row size = 25 number of columns = 8 index size = 75 }
create table "fobos".cajt013 
  (
    j13_compania integer not null ,
    j13_localidad smallint not null ,
    j13_codigo_caja smallint not null ,
    j13_fecha date not null ,
    j13_moneda char(2) not null ,
    j13_trn_generada char(2) not null ,
    j13_codigo_pago char(2) not null ,
    j13_valor decimal(12,2) not null 
  )  extent size 246 next size 24 lock mode row;
revoke all on "fobos".cajt013 from "public";

{ TABLE "fobos".ccht000 row size = 8 number of columns = 4 index size = 12 }
create table "fobos".ccht000 
  (
    h00_serial serial not null ,
    h00_cont_online char(1) not null ,
    h00_porc_repos smallint not null ,
    h00_cta_pagar char(1) not null ,
    
    check (h00_cont_online IN ('S' ,'N' )),
    
    check (h00_cta_pagar IN ('S' ,'N' ))
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".ccht000 from "public";

{ TABLE "fobos".ccht001 row size = 106 number of columns = 13 index size = 124 }
create table "fobos".ccht001 
  (
    h01_compania integer not null ,
    h01_localidad smallint not null ,
    h01_caja_chica smallint not null ,
    h01_estado char(1) not null ,
    h01_responsable varchar(30,15) not null ,
    h01_moneda char(2) not null ,
    h01_valor_base decimal(11,2) not null ,
    h01_valmax_gtos decimal(11,2) not null ,
    h01_valor_usado decimal(11,2) not null ,
    h01_aux_cont_caj char(12),
    h01_aux_cont_pag char(12),
    h01_usuario varchar(10,5) not null ,
    h01_fecing datetime year to second not null ,
    
    check (h01_estado IN ('A' ,'B' ))
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".ccht001 from "public";

{ TABLE "fobos".ccht002 row size = 300 number of columns = 21 index size = 123 }
create table "fobos".ccht002 
  (
    h02_compania integer not null ,
    h02_localidad smallint not null ,
    h02_caja_chica smallint not null ,
    h02_tipo_trn char(1) not null ,
    h02_numero integer not null ,
    h02_estado char(1) not null ,
    h02_prov_defi char(1) not null ,
    h02_fecha datetime year to second not null ,
    h02_detalle1 varchar(70,35) not null ,
    h02_detalle2 varchar(70),
    h02_detalle3 varchar(70),
    h02_moneda char(2) not null ,
    h02_paridad decimal(16,9) not null ,
    h02_valor decimal(11,2) not null ,
    h02_origen char(1) not null ,
    h02_numero_oc integer,
    h02_aprobado varchar(10,5),
    h02_tipo_comp char(2),
    h02_num_comp char(8),
    h02_usuario varchar(10,5) not null ,
    h02_fecing datetime year to second not null ,
    
    check (h02_estado IN ('A' ,'E' ,'P' )),
    
    check (h02_prov_defi IN ('P' ,'D' )),
    
    check (h02_origen IN ('M' ,'A' ))
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".ccht002 from "public";

{ TABLE "fobos".ccht003 row size = 60 number of columns = 11 index size = 106 }
create table "fobos".ccht003 
  (
    h03_compania integer not null ,
    h03_localidad smallint not null ,
    h03_caja_chica smallint not null ,
    h03_tipo_trn char(1) not null ,
    h03_numero integer not null ,
    h03_secuencia smallint not null ,
    h03_aux_cont char(12),
    h03_valor_mb decimal(11,2) not null ,
    h03_valor_ma decimal(11,2) not null ,
    h03_usuario varchar(10,5) not null ,
    h03_fecing datetime year to second not null 
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".ccht003 from "public";

{ TABLE "fobos".rolt000 row size = 54 number of columns = 16 index size = 43 }
create table "fobos".rolt000 
  (
    n00_serial serial not null ,
    n00_moneda_pago char(2) not null ,
    n00_dias_mes smallint not null ,
    n00_dias_semana smallint not null ,
    n00_horas_dia smallint not null ,
    n00_salario_min decimal(9,2) not null ,
    n00_seguro_event char(1) not null ,
    n00_uti_trabaj decimal(4,2) not null ,
    n00_uti_cargas decimal(4,2) not null ,
    n00_dias_vacac smallint not null ,
    n00_ano_adi_vac smallint not null ,
    n00_dias_adi_va smallint not null ,
    n00_max_vacac smallint not null ,
    n00_max_vac_acum smallint not null ,
    n00_usuario varchar(10,5) not null ,
    n00_fecing datetime year to second not null ,
    
    check (n00_seguro_event IN ('S' ,'N' ))
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".rolt000 from "public";

{ TABLE "fobos".rolt001 row size = 39 number of columns = 12 index size = 34 }
create table "fobos".rolt001 
  (
    n01_compania integer not null ,
    n01_estado char(1) not null ,
    n01_rol_mensual char(1) not null ,
    n01_rol_quincen char(1) not null ,
    n01_rol_semanal char(1) not null ,
    n01_porc_ant_mes smallint not null ,
    n01_ano_proceso smallint not null ,
    n01_mes_proceso smallint not null ,
    n01_sem_proceso smallint not null ,
    n01_porc_aporte decimal(5,2) not null ,
    n01_usuario varchar(10,5) not null ,
    n01_fecing datetime year to second not null ,
    
    check (n01_estado IN ('A' ,'B' )),
    
    check (n01_rol_mensual IN ('S' ,'N' )),
    
    check (n01_rol_quincen IN ('S' ,'N' )),
    
    check (n01_rol_semanal IN ('S' ,'N' ))
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".rolt001 from "public";

{ TABLE "fobos".rolt002 row size = 67 number of columns = 15 index size = 52 }
create table "fobos".rolt002 
  (
    n02_compania integer not null ,
    n02_ano smallint not null ,
    n02_mes smallint not null ,
    n02_fecha_ini_1 date not null ,
    n02_fecha_fin_1 date not null ,
    n02_fecha_ini_2 date not null ,
    n02_fecha_fin_2 date not null ,
    n02_fecha_ini_3 date not null ,
    n02_fecha_fin_3 date not null ,
    n02_fecha_ini_4 date not null ,
    n02_fecha_fin_4 date not null ,
    n02_fecha_ini_5 date,
    n02_fecha_fin_5 date,
    n02_usuario varchar(10,5) not null ,
    n02_fecing datetime year to second not null 
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".rolt002 from "public";

{ TABLE "fobos".rolt003 row size = 89 number of columns = 16 index size = 31 }
create table "fobos".rolt003 
  (
    n03_proceso char(2) not null ,
    n03_nombre varchar(30,15) not null ,
    n03_nombre_abr varchar(15,10) not null ,
    n03_estado char(1) not null ,
    n03_frecuencia char(1) not null ,
    n03_dia_ini smallint,
    n03_mes_ini smallint,
    n03_dia_fin smallint,
    n03_mes_fin smallint,
    n03_tipo_calc char(1) not null ,
    n03_valor decimal(12,2) not null ,
    n03_benefic_liq char(1) not null ,
    n03_acep_descto char(1) not null ,
    n03_provisionar char(1) not null ,
    n03_usuario varchar(10,5) not null ,
    n03_fecing datetime year to second not null ,
    
    check (n03_estado IN ('A' ,'B' )),
    
    check (n03_frecuencia IN ('D' ,'S' ,'Q' ,'M' ,'A' )),
    
    check (n03_tipo_calc IN ('F' ,'S' ,'G' ,'P' ,'L' )),
    
    check (n03_benefic_liq IN ('T' ,'S' )),
    
    check (n03_provisionar IN ('S' ,'N' )),
    
    check (n03_acep_descto IN ('S' ,'N' ))
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".rolt003 from "public";

{ TABLE "fobos".rolt004 row size = 28 number of columns = 6 index size = 70 }
create table "fobos".rolt004 
  (
    n04_compania integer not null ,
    n04_proceso char(2) not null ,
    n04_cod_rubro smallint not null ,
    n04_operacion char(1) not null ,
    n04_usuario varchar(10,5) not null ,
    n04_fecing datetime year to second not null ,
    
    check (n04_operacion IN ('+' ,'-' ))
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".rolt004 from "public";

{ TABLE "fobos".rolt005 row size = 42 number of columns = 9 index size = 58 }
create table "fobos".rolt005 
  (
    n05_compania integer not null ,
    n05_proceso char(2) not null ,
    n05_activo char(1) not null ,
    n05_fecini_act date,
    n05_fecfin_act date,
    n05_fec_ultcie date not null ,
    n05_fec_cierre date not null ,
    n05_usuario varchar(10,5) not null ,
    n05_fecing datetime year to second not null ,
    
    check (n05_activo IN ('S' ,'N' ))
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".rolt005 from "public";

{ TABLE "fobos".rolt006 row size = 100 number of columns = 18 index size = 40 }
create table "fobos".rolt006 
  (
    n06_cod_rubro smallint not null ,
    n06_nombre varchar(30,15) not null ,
    n06_nombre_abr varchar(15,10) not null ,
    n06_etiq_impr char(10) not null ,
    n06_estado char(1) not null ,
    n06_orden smallint not null ,
    n06_det_tot char(2) not null ,
    n06_cant_valor char(1) not null ,
    n06_calculo char(1) not null ,
    n06_ing_usuario char(1) not null ,
    n06_imprime_0 char(1) not null ,
    n06_cont_colect char(1) not null ,
    n06_flag_ident char(2),
    n06_rubro_dscto smallint,
    n06_valor_fijo decimal(12,2) not null ,
    n06_cont_prest char(1) not null ,
    n06_usuario varchar(10,5) not null ,
    n06_fecing datetime year to second not null ,
    
    check (n06_estado IN ('A' ,'B' )),
    
    check (n06_det_tot IN ('DI' ,'DE' ,'TI' ,'TE' ,'TN' )),
    
    check (n06_calculo IN ('S' ,'N' )),
    
    check (n06_ing_usuario IN ('S' ,'N' )),
    
    check (n06_imprime_0 IN ('S' ,'N' )),
    
    check (n06_cont_colect IN ('S' ,'N' )),
    
    check (n06_cont_prest IN ('S' ,'N' )),
    
    check (n06_cant_valor IN ('H' ,'D' ,'P' ,'V' ))
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".rolt006 from "public";

{ TABLE "fobos".rolt007 row size = 48 number of columns = 10 index size = 31 }
create table "fobos".rolt007 
  (
    n07_cod_rubro smallint not null ,
    n07_tipo_calc char(1) not null ,
    n07_operacion char(1) not null ,
    n07_factor decimal(4,2) not null ,
    n07_valor_max decimal(11,2) not null ,
    n07_valor_min decimal(11,2) not null ,
    n07_ganado_max decimal(11,2) not null ,
    n07_sum_liq_ant char(1) not null ,
    n07_usuario varchar(10,5) not null ,
    n07_fecing datetime year to second not null ,
    
    check (n07_tipo_calc IN ('N' ,'E' )),
    
    check (n07_operacion IN ('*' ,'/' )),
    
    check (n07_sum_liq_ant IN ('S' ,'N' ))
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".rolt007 from "public";

{ TABLE "fobos".rolt008 row size = 4 number of columns = 2 index size = 30 }
create table "fobos".rolt008 
  (
    n08_cod_rubro smallint not null ,
    n08_rubro_base smallint not null 
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".rolt008 from "public";

{ TABLE "fobos".rolt009 row size = 33 number of columns = 6 index size = 58 }
create table "fobos".rolt009 
  (
    n09_compania integer not null ,
    n09_cod_rubro smallint not null ,
    n09_estado char(1) not null ,
    n09_valor decimal(11,2),
    n09_usuario varchar(10,5) not null ,
    n09_fecing datetime year to second not null ,
    
    check (n09_estado IN ('A' ,'B' ))
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".rolt009 from "public";

{ TABLE "fobos".rolt010 row size = 46 number of columns = 9 index size = 88 }
create table "fobos".rolt010 
  (
    n10_compania integer not null ,
    n10_cod_liqrol char(2) not null ,
    n10_cod_rubro smallint not null ,
    n10_cod_trab integer not null ,
    n10_fecha_ini date,
    n10_fecha_fin date,
    n10_valor decimal(11,2) not null ,
    n10_usuario varchar(10,5) not null ,
    n10_fecing datetime year to second not null 
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".rolt010 from "public";

{ TABLE "fobos".rolt011 row size = 27 number of columns = 5 index size = 64 }
create table "fobos".rolt011 
  (
    n11_compania integer not null ,
    n11_cod_liqrol char(2) not null ,
    n11_cod_rubro smallint not null ,
    n11_usuario varchar(10,5) not null ,
    n11_fecing datetime year to second not null 
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".rolt011 from "public";

{ TABLE "fobos".rolt012 row size = 48 number of columns = 11 index size = 58 }
create table "fobos".rolt012 
  (
    n12_compania integer not null ,
    n12_num_cont integer not null ,
    n12_estado char(1) not null ,
    n12_cod_trab integer not null ,
    n12_fecha_ing date not null ,
    n12_tipo char(1) not null ,
    n12_meses_prue smallint not null ,
    n12_meses_cont smallint not null ,
    n12_sueldo_mes decimal(11,2) not null ,
    n12_usuario varchar(10,5) not null ,
    n12_fecing datetime year to second not null ,
    
    check (n12_estado IN ('A' ,'E' )),
    
    check (n12_tipo IN ('F' ,'P' ,'E' ))
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".rolt012 from "public";

{ TABLE "fobos".rolt013 row size = 59 number of columns = 7 index size = 31 }
create table "fobos".rolt013 
  (
    n13_cod_seguro smallint not null ,
    n13_descripcion varchar(30,15) not null ,
    n13_estado char(1) not null ,
    n13_porc_trab decimal(4,2) not null ,
    n13_porc_cia decimal(4,2) not null ,
    n13_usuario varchar(10,5) not null ,
    n13_fecing datetime year to second not null ,
    
    check (n13_estado IN ('A' ,'B' ))
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".rolt013 from "public";

{ TABLE "fobos".rolt014 row size = 40 number of columns = 4 index size = 21 }
create table "fobos".rolt014 
  (
    n14_serial serial not null ,
    n14_cod_seguro smallint not null ,
    n14_porcentaje decimal(4,2) not null ,
    n14_descripcion varchar(30,15) not null 
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".rolt014 from "public";

{ TABLE "fobos".rolt030 row size = 351 number of columns = 44 index size = 193 }
create table "fobos".rolt030 
  (
    n30_compania integer not null ,
    n30_cod_trab integer not null ,
    n30_estado char(1) not null ,
    n30_nombres varchar(45,25) not null ,
    n30_fecha_ing date not null ,
    n30_fecha_reing date,
    n30_fecha_sal date,
    n30_mon_sueldo char(2) not null ,
    n30_sueldo_mes decimal(11,2) not null ,
    n30_factor_hora decimal(12,5) not null ,
    n30_tipo_trab char(1) not null ,
    n30_tipo_contr char(1) not null ,
    n30_tipo_rol char(1) not null ,
    n30_cod_cargo smallint not null ,
    n30_cod_depto smallint not null ,
    n30_pais_nac integer not null ,
    n30_ciudad_nac integer not null ,
    n30_fecha_nacim date not null ,
    n30_sexo char(1) not null ,
    n30_est_civil char(1) not null ,
    n30_domicilio varchar(40) not null ,
    n30_telef_domic char(15),
    n30_telef_fami char(15),
    n30_refer_fami varchar(30,15),
    n30_tipo_doc_id char(1) not null ,
    n30_num_doc_id char(15) not null ,
    n30_carnet_seg char(15),
    n30_sub_activ char(10),
    n30_tipo_pago char(1) not null ,
    n30_bco_empresa integer,
    n30_cta_empresa char(15),
    n30_tipo_cta_tra char(1),
    n30_cta_trabaj char(15),
    n30_desc_seguro char(1) not null ,
    n30_desc_impto char(1) not null ,
    n30_cod_seguro smallint,
    n30_ano_sect smallint not null ,
    n30_sectorial char(15) not null ,
    n30_lib_militar char(15),
    n30_fec_jub date,
    n30_val_jub_pat decimal(12,2),
    n30_fon_res_anio char(1) not null ,
    n30_usuario varchar(10,5) not null ,
    n30_fecing datetime year to second not null ,
    
    check (n30_estado IN ('A' ,'I' ,'J' )),
    
    check (n30_tipo_cta_tra IN ('A' ,'C' ,NULL )),
    
    check (n30_tipo_trab IN ('N' ,'E' )),
    
    check (n30_tipo_contr IN ('F' ,'H' ,'E' )),
    
    check (n30_tipo_rol IN ('S' ,'Q' ,'M' )),
    
    check (n30_sexo IN ('M' ,'F' )),
    
    check (n30_est_civil IN ('C' ,'S' ,'U' ,'V' ,'D' )),
    
    check (n30_tipo_doc_id IN ('C' ,'P' )),
    
    check (n30_tipo_pago IN ('E' ,'C' ,'T' )),
    
    check (n30_desc_seguro IN ('S' ,'N' )),
    
    check (n30_desc_impto IN ('S' ,'N' )),
    
    check (n30_fon_res_anio IN ('S' ,'N' )) constraint "fobos".ck_12_rolt030
  )  extent size 31 next size 16 lock mode row;
revoke all on "fobos".rolt030 from "public";

{ TABLE "fobos".rolt032 row size = 132 number of columns = 25 index size = 159 }
create table "fobos".rolt032 
  (
    n32_compania integer not null ,
    n32_cod_liqrol char(2) not null ,
    n32_fecha_ini date not null ,
    n32_fecha_fin date not null ,
    n32_cod_trab integer not null ,
    n32_estado char(1) not null ,
    n32_cod_depto smallint not null ,
    n32_sueldo decimal(11,2) not null ,
    n32_ano_proceso smallint not null ,
    n32_mes_proceso smallint not null ,
    n32_orden smallint not null ,
    n32_dias_trab smallint not null ,
    n32_dias_falt smallint not null ,
    n32_tot_gan decimal(12,2) not null ,
    n32_tot_ing decimal(12,2) not null ,
    n32_tot_egr decimal(12,2) not null ,
    n32_tot_neto decimal(12,2) not null ,
    n32_moneda char(2) not null ,
    n32_paridad decimal(16,9) not null ,
    n32_tipo_pago char(1) not null ,
    n32_bco_empresa integer,
    n32_cta_empresa char(15),
    n32_cta_trabaj char(15),
    n32_usuario varchar(10,5) not null ,
    n32_fecing datetime year to second not null ,
    
    check (n32_tipo_pago IN ('E' ,'C' ,'T' )),
    
    check (n32_estado IN ('A' ,'C' ,'E' ))
  )  extent size 2005 next size 200 lock mode row;
revoke all on "fobos".rolt032 from "public";

{ TABLE "fobos".rolt033 row size = 66 number of columns = 15 index size = 120 }
create table "fobos".rolt033 
  (
    n33_compania integer not null ,
    n33_cod_liqrol char(2) not null ,
    n33_fecha_ini date not null ,
    n33_fecha_fin date not null ,
    n33_cod_trab integer not null ,
    n33_cod_rubro smallint not null ,
    n33_num_prest integer,
    n33_prest_club integer,
    n33_referencia varchar(20),
    n33_orden smallint not null ,
    n33_det_tot char(2) not null ,
    n33_imprime_0 char(1) not null ,
    n33_cant_valor char(1) not null ,
    n33_horas_porc decimal(5,2),
    n33_valor decimal(12,2) not null ,
    
    check (n33_det_tot IN ('DI' ,'DE' ,'TI' ,'TE' ,'TN' )),
    
    check (n33_imprime_0 IN ('S' ,'N' )),
    
    check (n33_cant_valor IN ('H' ,'D' ,'P' ,'V' ))
  )  extent size 9171 next size 917 lock mode row;
revoke all on "fobos".rolt033 from "public";

{ TABLE "fobos".rolt034 row size = 96 number of columns = 18 index size = 141 }
create table "fobos".rolt034 
  (
    n34_serial integer not null ,
    n34_compania integer not null ,
    n34_cod_trab integer not null ,
    n34_cod_rubro smallint not null ,
    n34_estado char(1) not null ,
    n34_cod_depto smallint not null ,
    n34_ano_proceso smallint not null ,
    n34_mes_proceso smallint not null ,
    n34_valor decimal(12,2) not null ,
    n34_moneda char(2) not null ,
    n34_paridad decimal(16,9) not null ,
    n34_cod_liqrol char(2) not null ,
    n34_tipo_pago char(1) not null ,
    n34_bco_empresa integer,
    n34_cta_empresa char(15),
    n34_cta_trabaj char(15),
    n34_usuario varchar(10,5) not null ,
    n34_fecing datetime year to second not null ,
    
    check (n34_estado IN ('A' ,'P' )),
    
    check (n34_tipo_pago IN ('E' ,'C' ,'T' ))
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".rolt034 from "public";

{ TABLE "fobos".rolt035 row size = 54 number of columns = 11 index size = 100 }
create table "fobos".rolt035 
  (
    n35_compania integer not null ,
    n35_ano smallint not null ,
    n35_mes smallint not null ,
    n35_cod_trab integer not null ,
    n35_cod_depto smallint not null ,
    n35_proceso char(2) not null ,
    n35_valor decimal(12,2) not null ,
    n35_moneda char(2) not null ,
    n35_paridad decimal(16,9) not null ,
    n35_usuario varchar(10,5) not null ,
    n35_fecing datetime year to second not null 
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".rolt035 from "public";

{ TABLE "fobos".rolt036 row size = 149 number of columns = 25 index size = 169 }
create table "fobos".rolt036 
  (
    n36_compania integer not null ,
    n36_proceso char(2) not null ,
    n36_fecha_ini date not null ,
    n36_fecha_fin date not null ,
    n36_cod_trab integer not null ,
    n36_estado char(1) not null ,
    n36_cod_depto smallint not null ,
    n36_ano_proceso smallint not null ,
    n36_mes_proceso smallint not null ,
    n36_fecha_ing date not null ,
    n36_ganado_real decimal(12,2) not null ,
    n36_usuario_modif varchar(10,5),
    n36_fecha_modif datetime year to second,
    n36_ganado_per decimal(12,2) not null ,
    n36_valor_bruto decimal(12,2) not null ,
    n36_descuentos decimal(12,2) not null ,
    n36_valor_neto decimal(12,2) not null ,
    n36_moneda char(2) not null ,
    n36_paridad decimal(16,9) not null ,
    n36_tipo_pago char(1) not null ,
    n36_bco_empresa integer,
    n36_cta_empresa char(15),
    n36_cta_trabaj char(15),
    n36_usuario varchar(10,5) not null ,
    n36_fecing datetime year to second not null ,
    
    check (n36_estado IN ('A' ,'P' )),
    
    check (n36_tipo_pago IN ('E' ,'C' ,'T' ))
  )  extent size 17 next size 16 lock mode row;
revoke all on "fobos".rolt036 from "public";

{ TABLE "fobos".rolt037 row size = 36 number of columns = 11 index size = 102 }
create table "fobos".rolt037 
  (
    n37_compania integer not null ,
    n37_proceso char(2) not null ,
    n37_fecha_ini date not null ,
    n37_fecha_fin date not null ,
    n37_cod_trab integer not null ,
    n37_cod_rubro smallint not null ,
    n37_num_prest integer,
    n37_orden smallint not null ,
    n37_det_tot char(2) not null ,
    n37_imprime_0 char(1) not null ,
    n37_valor decimal(12,2) not null ,
    
    check (n37_det_tot IN ('DI' ,'DE' ,'TI' ,'TE' ,'TN' )),
    
    check (n37_imprime_0 IN ('S' ,'N' ))
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".rolt037 from "public";

{ TABLE "fobos".rolt038 row size = 67 number of columns = 13 index size = 79 }
create table "fobos".rolt038 
  (
    n38_compania integer not null ,
    n38_fecha_ini date not null ,
    n38_fecha_fin date not null ,
    n38_cod_trab integer not null ,
    n38_estado char(1) not null ,
    n38_fecha_ing date not null ,
    n38_ganado_per decimal(12,2) not null ,
    n38_valor_fondo decimal(12,2) not null ,
    n38_moneda char(2) not null ,
    n38_paridad decimal(16,9) not null ,
    n38_pago_iess char(1) not null ,
    n38_usuario varchar(10,5) not null ,
    n38_fecing datetime year to second not null ,
    
    check (n38_estado IN ('A' ,'P' )),
    
    check (n38_pago_iess IN ('S' ,'N' )) constraint "fobos".ck_02_rolt038
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".rolt038 from "public";

{ TABLE "fobos".rolt042 row size = 90 number of columns = 18 index size = 145 }
create table "fobos".rolt042 
  (
    n42_compania integer not null ,
    n42_proceso char(2) not null ,
    n42_cod_trab integer not null ,
    n42_fecha_ini date not null ,
    n42_fecha_fin date not null ,
    n42_ano smallint not null ,
    n42_cod_depto smallint not null ,
    n42_fecha_ing date not null ,
    n42_fecha_sal date,
    n42_dias_trab smallint not null ,
    n42_num_cargas smallint not null ,
    n42_val_trabaj decimal(12,2) not null ,
    n42_val_cargas decimal(12,2) not null ,
    n42_descuentos decimal(12,2) not null ,
    n42_tipo_pago char(1) not null ,
    n42_bco_empresa integer,
    n42_cta_empresa char(15),
    n42_cta_trabaj char(15),
    
    check (n42_tipo_pago IN ('E' ,'C' ,'T' ))
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".rolt042 from "public";

{ TABLE "fobos".rolt043 row size = 84 number of columns = 11 index size = 61 }
create table "fobos".rolt043 
  (
    n43_compania integer not null ,
    n43_num_rol integer not null ,
    n43_titulo varchar(40,20) not null ,
    n43_estado char(1) not null ,
    n43_moneda char(2) not null ,
    n43_paridad decimal(16,9) not null ,
    n43_pago_efec char(1) not null ,
    n43_tributa char(1) not null ,
    n43_incluir_ej char(1) not null ,
    n43_usuario varchar(10,5) not null ,
    n43_fecing datetime year to second not null ,
    
    check (n43_estado IN ('A' ,'P' )),
    
    check (n43_pago_efec IN ('S' ,'N' )) constraint "fobos".ck_02_rolt043,
    
    check (n43_tributa IN ('S' ,'N' )) constraint "fobos".ck_03_rolt043,
    
    check (n43_incluir_ej IN ('S' ,'N' )) constraint "fobos".ck_04_rolt043
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".rolt043 from "public";

{ TABLE "fobos".rolt044 row size = 56 number of columns = 9 index size = 115 }
create table "fobos".rolt044 
  (
    n44_compania integer not null ,
    n44_num_rol integer not null ,
    n44_cod_trab integer not null ,
    n44_cod_depto smallint not null ,
    n44_tipo_pago char(1) not null ,
    n44_bco_empresa integer,
    n44_cta_empresa char(15),
    n44_cta_trabaj char(15),
    n44_valor decimal(12,2) not null ,
    
    check (n44_tipo_pago IN ('E' ,'C' ,'T' ))
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".rolt044 from "public";

{ TABLE "fobos".rolt045 row size = 166 number of columns = 23 index size = 153 }
create table "fobos".rolt045 
  (
    n45_compania integer not null ,
    n45_num_prest integer not null ,
    n45_cod_rubro smallint not null ,
    n45_cod_trab integer not null ,
    n45_estado char(1) not null ,
    n45_referencia varchar(30,15) not null ,
    n45_fecha datetime year to second not null ,
    n45_val_prest decimal(12,2) not null ,
    n45_descontado decimal(12,2) not null ,
    n45_porc_int decimal(5,2) not null ,
    n45_valor_int decimal(12,2) not null ,
    n45_mes_gracia smallint not null ,
    n45_moneda char(2) not null ,
    n45_paridad decimal(16,9) not null ,
    n45_fec_elimi datetime year to second,
    n45_tipo_pago char(1) not null ,
    n45_bco_empresa integer,
    n45_cta_empresa char(15),
    n45_cta_trabaj char(15),
    n45_prest_tran integer,
    n45_sal_prest_ant decimal(12,2) not null ,
    n45_usuario varchar(10,5) not null ,
    n45_fecing datetime year to second not null ,
    
    check (n45_estado IN ('A' ,'P' ,'E' ,'T' ,'R' )) constraint "fobos".ck_01_rolt045,
    
    check (n45_tipo_pago IN ('E' ,'C' ,'T' )) constraint "fobos".ck_02_rolt045
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".rolt045 from "public";

{ TABLE "fobos".rolt046 row size = 34 number of columns = 8 index size = 48 }
create table "fobos".rolt046 
  (
    n46_compania integer not null ,
    n46_num_prest integer not null ,
    n46_secuencia smallint not null ,
    n46_cod_liqrol char(2) not null ,
    n46_fecha_ini date not null ,
    n46_fecha_fin date not null ,
    n46_valor decimal(12,2) not null ,
    n46_saldo decimal(12,2) not null 
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".rolt046 from "public";

{ TABLE "fobos".actt000 row size = 25 number of columns = 7 index size = 42 }
create table "fobos".actt000 
  (
    a00_compania integer not null ,
    a00_estado char(1) not null ,
    a00_aux_reexp char(12),
    a00_ind_reexp decimal(4,2),
    a00_calc_reexp char(1) not null ,
    a00_anopro smallint not null ,
    a00_mespro smallint not null ,
    
    check (a00_estado IN ('A' ,'B' )),
    
    check (a00_calc_reexp IN ('S' ,'N' ))
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".actt000 from "public";

{ TABLE "fobos".actt003 row size = 65 number of columns = 8 index size = 67 }
create table "fobos".actt003 
  (
    a03_compania integer not null ,
    a03_responsable smallint not null ,
    a03_nombres varchar(30,15) not null ,
    a03_estado char(1) not null ,
    a03_ciarol integer,
    a03_codrol integer,
    a03_usuario varchar(10,5) not null ,
    a03_fecing datetime year to second not null ,
    
    check (a03_estado IN ('A' ,'B' ))
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".actt003 from "public";

{ TABLE "fobos".actt004 row size = 49 number of columns = 6 index size = 31 }
create table "fobos".actt004 
  (
    a04_codigo_proc char(2) not null ,
    a04_nombre varchar(25,15) not null ,
    a04_estado char(1) not null ,
    a04_periocidad char(1) not null ,
    a04_usuario varchar(10,5) not null ,
    a04_fecing datetime year to second not null ,
    
    check (a04_estado IN ('A' ,'B' )),
    
    check (a04_periocidad IN ('A' ,'M' ,'*' ))
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".actt004 from "public";

{ TABLE "fobos".actt005 row size = 10 number of columns = 3 index size = 36 }
create table "fobos".actt005 
  (
    a05_compania integer not null ,
    a05_codigo_tran char(2) not null ,
    a05_numero integer not null 
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".actt005 from "public";

{ TABLE "fobos".actt011 row size = 14 number of columns = 4 index size = 54 }
create table "fobos".actt011 
  (
    a11_compania integer not null ,
    a11_codigo_bien integer not null ,
    a11_cod_depto smallint not null ,
    a11_porcentaje decimal(5,2) not null 
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".actt011 from "public";

{ TABLE "fobos".ctbt000 row size = 83 number of columns = 18 index size = 150 }
create table "fobos".ctbt000 
  (
    b00_compania integer not null ,
    b00_estado char(1) not null ,
    b00_moneda_base char(2) not null ,
    b00_moneda_aux char(2),
    b00_periodo_ini date not null ,
    b00_periodo_fin date not null ,
    b00_inte_online char(1) not null ,
    b00_mayo_online char(1) not null ,
    b00_modi_compma char(1) not null ,
    b00_modi_compau char(1) not null ,
    b00_cuenta_uti char(12),
    b00_cta_uti_ant char(12),
    b00_cuenta_difi char(12),
    b00_cuenta_dife char(12),
    b00_anopro smallint not null ,
    b00_fecha_cd date not null ,
    b00_fecha_cm date not null ,
    b00_fecha_ca date not null ,
    
    check (b00_estado IN ('A' ,'B' )),
    
    check (b00_inte_online IN ('S' ,'N' )),
    
    check (b00_mayo_online IN ('S' ,'N' )),
    
    check (b00_modi_compma IN ('S' ,'N' )),
    
    check (b00_modi_compau IN ('S' ,'N' ))
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".ctbt000 from "public";

{ TABLE "fobos".ctbt001 row size = 46 number of columns = 6 index size = 31 }
create table "fobos".ctbt001 
  (
    b01_nivel smallint not null ,
    b01_nombre varchar(20,10) not null ,
    b01_posicion_i smallint not null ,
    b01_posicion_f smallint not null ,
    b01_usuario varchar(10,5) not null ,
    b01_fecing datetime year to second not null 
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".ctbt001 from "public";

{ TABLE "fobos".ctbt002 row size = 57 number of columns = 7 index size = 48 }
create table "fobos".ctbt002 
  (
    b02_compania integer not null ,
    b02_grupo_cta char(1) not null ,
    b02_nombre varchar(30,15) not null ,
    b02_tipo_cta char(1) not null ,
    b02_tipo_mov char(1) not null ,
    b02_usuario varchar(10,5) not null ,
    b02_fecing datetime year to second not null ,
    
    check (b02_tipo_cta IN ('B' ,'R' )),
    
    check (b02_tipo_mov IN ('D' ,'C' ))
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".ctbt002 from "public";

{ TABLE "fobos".ctbt003 row size = 49 number of columns = 7 index size = 58 }
create table "fobos".ctbt003 
  (
    b03_compania integer not null ,
    b03_tipo_comp char(2) not null ,
    b03_nombre varchar(20,10) not null ,
    b03_estado char(1) not null ,
    b03_modulo char(2),
    b03_usuario varchar(10,5) not null ,
    b03_fecing datetime year to second not null ,
    
    check (b03_estado IN ('A' ,'B' ))
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".ctbt003 from "public";

{ TABLE "fobos".ctbt004 row size = 62 number of columns = 6 index size = 49 }
create table "fobos".ctbt004 
  (
    b04_compania integer not null ,
    b04_subtipo smallint not null ,
    b04_nombre varchar(35,20) not null ,
    b04_estado char(1) not null ,
    b04_usuario varchar(10,5) not null ,
    b04_fecing datetime year to second not null ,
    
    check (b04_estado IN ('A' ,'B' ))
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".ctbt004 from "public";

{ TABLE "fobos".ctbt005 row size = 75 number of columns = 17 index size = 55 }
create table "fobos".ctbt005 
  (
    b05_compania integer not null ,
    b05_tipo_comp char(2) not null ,
    b05_ano smallint not null ,
    b05_mes01 integer not null ,
    b05_mes02 integer not null ,
    b05_mes03 integer not null ,
    b05_mes04 integer not null ,
    b05_mes05 integer not null ,
    b05_mes06 integer not null ,
    b05_mes07 integer not null ,
    b05_mes08 integer not null ,
    b05_mes09 integer not null ,
    b05_mes10 integer not null ,
    b05_mes11 integer not null ,
    b05_mes12 integer not null ,
    b05_usuario varchar(10,5) not null ,
    b05_fecing datetime year to second not null 
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".ctbt005 from "public";

{ TABLE "fobos".ctbt006 row size = 27 number of columns = 5 index size = 52 }
create table "fobos".ctbt006 
  (
    b06_compania integer not null ,
    b06_ano smallint not null ,
    b06_mes smallint not null ,
    b06_usuario varchar(10,5) not null ,
    b06_fecing datetime year to second not null 
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".ctbt006 from "public";

{ TABLE "fobos".ctbt007 row size = 44 number of columns = 5 index size = 33 }
create table "fobos".ctbt007 
  (
    b07_tipo_doc char(3) not null ,
    b07_nombre varchar(20,10) not null ,
    b07_estado char(1) not null ,
    b07_usuario varchar(10,5) not null ,
    b07_fecing datetime year to second not null ,
    
    check (b07_estado IN ('A' ,'B' ))
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".ctbt007 from "public";

{ TABLE "fobos".ctbt008 row size = 49 number of columns = 6 index size = 52 }
create table "fobos".ctbt008 
  (
    b08_compania integer not null ,
    b08_filtro integer not null ,
    b08_nombre varchar(20,10) not null ,
    b08_estado char(1) not null ,
    b08_usuario varchar(10,5) not null ,
    b08_fecing datetime year to second not null ,
    
    check (b08_estado IN ('A' ,'B' ))
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".ctbt008 from "public";

{ TABLE "fobos".ctbt010 row size = 125 number of columns = 12 index size = 88 }
create table "fobos".ctbt010 
  (
    b10_compania integer not null ,
    b10_cuenta char(12) not null ,
    b10_descripcion varchar(40,20) not null ,
    b10_descri_alt varchar(40,20),
    b10_estado char(1) not null ,
    b10_tipo_cta char(1) not null ,
    b10_tipo_mov char(1) not null ,
    b10_nivel smallint not null ,
    b10_cod_ccosto smallint,
    b10_saldo_ma char(1) not null ,
    b10_usuario varchar(10,5) not null ,
    b10_fecing datetime year to second not null ,
    
    check (b10_estado IN ('A' ,'B' )),
    
    check (b10_tipo_cta IN ('B' ,'R' )),
    
    check (b10_tipo_mov IN ('D' ,'C' )),
    
    check (b10_saldo_ma IN ('S' ,'N' ))
  )  extent size 123 next size 16 lock mode row;
revoke all on "fobos".ctbt010 from "public";

{ TABLE "fobos".ctbt011 row size = 228 number of columns = 30 index size = 75 }
create table "fobos".ctbt011 
  (
    b11_compania integer not null ,
    b11_cuenta char(12) not null ,
    b11_moneda char(2) not null ,
    b11_ano smallint not null ,
    b11_db_ano_ant decimal(14,2) not null ,
    b11_cr_ano_ant decimal(14,2) not null ,
    b11_db_mes_01 decimal(14,2) not null ,
    b11_db_mes_02 decimal(14,2) not null ,
    b11_db_mes_03 decimal(14,2) not null ,
    b11_db_mes_04 decimal(14,2) not null ,
    b11_db_mes_05 decimal(14,2) not null ,
    b11_db_mes_06 decimal(14,2) not null ,
    b11_db_mes_07 decimal(14,2) not null ,
    b11_db_mes_08 decimal(14,2) not null ,
    b11_db_mes_09 decimal(14,2) not null ,
    b11_db_mes_10 decimal(14,2) not null ,
    b11_db_mes_11 decimal(14,2) not null ,
    b11_db_mes_12 decimal(14,2) not null ,
    b11_cr_mes_01 decimal(14,2) not null ,
    b11_cr_mes_02 decimal(14,2) not null ,
    b11_cr_mes_03 decimal(14,2) not null ,
    b11_cr_mes_04 decimal(14,2) not null ,
    b11_cr_mes_05 decimal(14,2) not null ,
    b11_cr_mes_06 decimal(14,2) not null ,
    b11_cr_mes_07 decimal(14,2) not null ,
    b11_cr_mes_08 decimal(14,2) not null ,
    b11_cr_mes_09 decimal(14,2) not null ,
    b11_cr_mes_10 decimal(14,2) not null ,
    b11_cr_mes_11 decimal(14,2) not null ,
    b11_cr_mes_12 decimal(14,2) not null 
  )  extent size 224 next size 22 lock mode row;
revoke all on "fobos".ctbt011 from "public";

{ TABLE "fobos".ctbt014 row size = 129 number of columns = 13 index size = 103 }
create table "fobos".ctbt014 
  (
    b14_compania integer not null ,
    b14_codigo integer not null ,
    b14_estado char(1) not null ,
    b14_tipo_comp char(2) not null ,
    b14_glosa varchar(70,35) not null ,
    b14_moneda char(2) not null ,
    b14_paridad decimal(16,9) not null ,
    b14_veces_max smallint not null ,
    b14_fecha_ini date not null ,
    b14_veces_gen smallint not null ,
    b14_ult_num char(8),
    b14_usuario varchar(10,5) not null ,
    b14_fecing datetime year to second not null ,
    
    check (b14_estado IN ('A' ,'B' ))
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".ctbt014 from "public";

{ TABLE "fobos".ctbt015 row size = 36 number of columns = 6 index size = 87 }
create table "fobos".ctbt015 
  (
    b15_compania integer not null ,
    b15_codigo integer not null ,
    b15_cuenta char(12) not null ,
    b15_secuencia smallint not null ,
    b15_valor_base decimal(12,2) not null ,
    b15_valor_aux decimal(12,2) not null 
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".ctbt015 from "public";

{ TABLE "fobos".ctbt016 row size = 31 number of columns = 4 index size = 108 }
create table "fobos".ctbt016 
  (
    b16_compania integer not null ,
    b16_cta_master char(12) not null ,
    b16_cta_detail char(12) not null ,
    b16_porcentaje decimal(4,2) not null 
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".ctbt016 from "public";

{ TABLE "fobos".ctbt030 row size = 167 number of columns = 25 index size = 159 }
create table "fobos".ctbt030 
  (
    b30_compania integer not null ,
    b30_num_concil integer not null ,
    b30_estado char(1) not null ,
    b30_banco integer not null ,
    b30_numero_cta char(15) not null ,
    b30_aux_cont char(12),
    b30_moneda char(2) not null ,
    b30_paridad decimal(16,9) not null ,
    b30_fecha_ini date not null ,
    b30_fecha_fin date not null ,
    b30_saldo_cont decimal(12,2) not null ,
    b30_saldo_ec decimal(12,2) not null ,
    b30_fecha_cie datetime year to second,
    b30_tipcomp_gen char(2),
    b30_numcomp_gen char(8),
    b30_ch_nocob decimal(12,2) not null ,
    b30_nd_banco decimal(12,2) not null ,
    b30_nc_banco decimal(12,2) not null ,
    b30_dp_tran decimal(12,2) not null ,
    b30_db_otros decimal(12,2) not null ,
    b30_cr_otros decimal(12,2) not null ,
    b30_ch_tarj decimal(12,2) not null ,
    b30_dp_tarj decimal(12,2) not null ,
    b30_usuario varchar(10,5) not null ,
    b30_fecing datetime year to second not null ,
    
    check (b30_estado IN ('A' ,'E' ,'C' ))
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".ctbt030 from "public";

{ TABLE "fobos".ctbt031 row size = 75 number of columns = 8 index size = 49 }
create table "fobos".ctbt031 
  (
    b31_compania integer not null ,
    b31_num_concil integer not null ,
    b31_secuencia smallint not null ,
    b31_tipo_doc char(3) not null ,
    b31_cuenta char(12) not null ,
    b31_glosa varchar(35) not null ,
    b31_valor_base decimal(12,2) not null ,
    b31_valor_aux decimal(12,2) not null 
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".ctbt031 from "public";

{ TABLE "fobos".talt004 row size = 46 number of columns = 7 index size = 88 }
create table "fobos".talt004 
  (
    t04_compania integer not null ,
    t04_modelo char(15) not null ,
    t04_linea char(5) not null ,
    t04_dificultad smallint not null ,
    t04_cod_mod_veh char(1) not null ,
    t04_usuario varchar(10,5) not null ,
    t04_fecing datetime year to second not null ,
    
    check (t04_cod_mod_veh IN ('S' ,'N' ))
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".talt004 from "public";

{ TABLE "fobos".gent015 row size = 66 number of columns = 9 index size = 24 }
create table "fobos".gent015 
  (
    g15_compania integer not null ,
    g15_localidad smallint not null ,
    g15_modulo char(2) not null ,
    g15_bodega char(2) not null ,
    g15_tipo char(2) not null ,
    g15_nombre varchar(30,15) not null ,
    g15_numero integer not null ,
    g15_usuario varchar(10,5) not null ,
    g15_fecing datetime year to second not null 
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".gent015 from "public";

{ TABLE "fobos".talt022 row size = 99 number of columns = 11 index size = 102 }
create table "fobos".talt022 
  (
    t22_compania integer not null ,
    t22_localidad smallint not null ,
    t22_numpre integer not null ,
    t22_secuencia smallint not null ,
    t22_item char(15),
    t22_descripcion varchar(35,20) not null ,
    t22_cantidad decimal(8,2) not null ,
    t22_precio decimal(11,2) not null ,
    t22_stock decimal(8,2) not null ,
    t22_usuario varchar(10,5) not null ,
    t22_fecing datetime year to second not null 
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".talt022 from "public";

{ TABLE "fobos".talt024 row size = 140 number of columns = 18 index size = 166 }
create table "fobos".talt024 
  (
    t24_compania integer not null ,
    t24_localidad smallint not null ,
    t24_orden integer not null ,
    t24_codtarea char(12) not null ,
    t24_secuencia smallint not null ,
    t24_descripcion varchar(60,30) not null ,
    t24_paga_clte char(1) not null ,
    t24_mecanico smallint not null ,
    t24_seccion smallint not null ,
    t24_factor decimal(11,2) not null ,
    t24_puntos_opti smallint not null ,
    t24_puntos_real smallint not null ,
    t24_porc_descto decimal(4,2) not null ,
    t24_val_descto decimal(10,2) not null ,
    t24_valor_tarea decimal(11,2) not null ,
    t24_ord_compra integer,
    t24_usuario varchar(10,5) not null ,
    t24_fecing datetime year to second not null ,
    
    check (t24_paga_clte IN ('S' ,'N' ))
  )  extent size 111 next size 16 lock mode row;
revoke all on "fobos".talt024 from "public";

{ TABLE "fobos".talt025 row size = 31 number of columns = 8 index size = 21 }
create table "fobos".talt025 
  (
    t25_compania integer not null ,
    t25_localidad smallint not null ,
    t25_orden integer not null ,
    t25_valor_ant decimal(11,2) not null ,
    t25_valor_cred decimal(11,2) not null ,
    t25_interes decimal(4,2) not null ,
    t25_dividendos smallint not null ,
    t25_plazo smallint not null 
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".talt025 from "public";

{ TABLE "fobos".talt026 row size = 30 number of columns = 7 index size = 45 }
create table "fobos".talt026 
  (
    t26_compania integer not null ,
    t26_localidad smallint not null ,
    t26_orden integer not null ,
    t26_dividendo smallint not null ,
    t26_valor_cap decimal(11,2) not null ,
    t26_valor_int decimal(11,2) not null ,
    t26_fec_vcto date not null 
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".talt026 from "public";

{ TABLE "fobos".talt027 row size = 29 number of columns = 6 index size = 69 }
create table "fobos".talt027 
  (
    t27_compania integer not null ,
    t27_localidad smallint not null ,
    t27_orden integer not null ,
    t27_tipo char(2) not null ,
    t27_numero char(10) not null ,
    t27_valor decimal(11,2) not null ,
    
    check (t27_tipo IN ('PA' ,'NC' ))
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".talt027 from "public";

{ TABLE "fobos".talt040 row size = 128 number of columns = 22 index size = 132 }
create table "fobos".talt040 
  (
    t40_compania integer not null ,
    t40_localidad smallint not null ,
    t40_ano smallint not null ,
    t40_mes smallint not null ,
    t40_tipo_orden char(1) not null ,
    t40_modelo char(15) not null ,
    t40_moneda char(2) not null ,
    t40_num_veh smallint not null ,
    t40_val_mo_tal decimal(12,2) not null ,
    t40_val_mo_ext decimal(12,2) not null ,
    t40_val_mo_cti decimal(12,2) not null ,
    t40_val_rp_tal decimal(12,2) not null ,
    t40_val_rp_ext decimal(12,2) not null ,
    t40_val_rp_cti decimal(12,2) not null ,
    t40_val_rp_alm decimal(12,2) not null ,
    t40_val_otros1 decimal(12,2) not null ,
    t40_val_otros2 decimal(12,2) not null ,
    t40_vde_mo_tal decimal(11,2) not null ,
    t40_vde_rp_tal decimal(11,2) not null ,
    t40_vde_rp_alm decimal(11,2) not null ,
    t40_val_impto decimal(11,2) not null ,
    t40_valor_neto decimal(12,2) not null 
  )  extent size 38 next size 16 lock mode row;
revoke all on "fobos".talt040 from "public";

{ TABLE "fobos".talt041 row size = 43 number of columns = 9 index size = 135 }
create table "fobos".talt041 
  (
    t41_compania integer not null ,
    t41_localidad smallint not null ,
    t41_ano smallint not null ,
    t41_mes smallint not null ,
    t41_mecanico smallint not null ,
    t41_modelo char(15) not null ,
    t41_moneda char(2) not null ,
    t41_mano_obra decimal(12,2) not null ,
    t41_repuestos decimal(12,2) not null 
  )  extent size 32 next size 16 lock mode row;
revoke all on "fobos".talt041 from "public";

{ TABLE "fobos".gent019 row size = 54 number of columns = 4 index size = 12 }
create table "fobos".gent019 
  (
    g19_codigo serial not null ,
    g19_nombre varchar(30,15) not null ,
    g19_usuario varchar(10,5) not null ,
    g19_fecing datetime year to second not null 
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".gent019 from "public";

{ TABLE "fobos".talt010 row size = 126 number of columns = 14 index size = 159 }
create table "fobos".talt010 
  (
    t10_compania integer not null ,
    t10_codcli integer not null ,
    t10_modelo char(15) not null ,
    t10_chasis char(25) not null ,
    t10_estado char(1) not null ,
    t10_codcia_vta integer,
    t10_codloc_vta smallint,
    t10_codveh_vta integer,
    t10_color char(15) not null ,
    t10_motor varchar(20,10),
    t10_placa char(10) not null ,
    t10_ano smallint not null ,
    t10_usuario varchar(10,5) not null ,
    t10_fecing datetime year to second not null ,
    
    check (t10_estado IN ('A' ,'B' ))
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".talt010 from "public";

{ TABLE "fobos".veht023 row size = 121 number of columns = 12 index size = 79 }
create table "fobos".veht023 
  (
    v23_compania integer not null ,
    v23_localidad smallint not null ,
    v23_codigo_veh integer not null ,
    v23_secuencia integer not null ,
    v23_nombre varchar(60,30) not null ,
    v23_tipo char(1) not null ,
    v23_cod_prov char(10),
    v23_mon_costo char(2),
    v23_val_costo decimal(11,2),
    v23_precio decimal(11,2),
    v23_usuario varchar(10,5) not null ,
    v23_fecing datetime year to second not null ,
    
    check (v23_tipo IN ('F' ,'L' ))
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".veht023 from "public";

{ TABLE "fobos".veht033 row size = 115 number of columns = 13 index size = 136 }
create table "fobos".veht033 
  (
    v33_compania integer not null ,
    v33_localidad smallint not null ,
    v33_num_reserv integer not null ,
    v33_codigo_veh integer not null ,
    v33_nota varchar(60,30),
    v33_vendedor smallint not null ,
    v33_codcli integer not null ,
    v33_moneda_doc char(2) not null ,
    v33_tipo_doc char(2) not null ,
    v33_num_doc integer not null ,
    v33_val_doc decimal(12,2) not null ,
    v33_usuario varchar(10,5) not null ,
    v33_fecing datetime year to second not null ,
    
    check (v33_tipo_doc IN ('PA' ,'NC' ))
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".veht033 from "public";

{ TABLE "fobos".veht041 row size = 272 number of columns = 33 index size = 262 }
create table "fobos".veht041 
  (
    v41_compania integer not null ,
    v41_localidad smallint not null ,
    v41_anio smallint not null ,
    v41_mes smallint not null ,
    v41_bodega char(2) not null ,
    v41_modelo char(15) not null ,
    v41_chasis char(25) not null ,
    v41_nuevo char(1) not null ,
    v41_codigo_veh integer not null ,
    v41_comentarios varchar(40,20) not null ,
    v41_estado char(1) not null ,
    v41_motor char(16),
    v41_ano smallint not null ,
    v41_cod_color char(10) not null ,
    v41_dueno varchar(30,15),
    v41_kilometraje integer,
    v41_placa char(10),
    v41_moneda_liq char(2) not null ,
    v41_costo_liq decimal(12,2) not null ,
    v41_cargo_liq decimal(12,2) not null ,
    v41_numero_liq integer,
    v41_fec_ing_bod datetime year to second,
    v41_pedido char(10),
    v41_moneda_ing char(2) not null ,
    v41_costo_ing decimal(12,2) not null ,
    v41_cargo_ing decimal(11,2) not null ,
    v41_costo_adi decimal(11,2) not null ,
    v41_moneda_prec char(2) not null ,
    v41_precio decimal(12,2) not null ,
    v41_cod_tran char(2),
    v41_num_tran decimal(15,0),
    v41_usuario varchar(10,5) not null ,
    v41_fecing datetime year to second not null ,
    
    check (v41_nuevo IN ('S' ,'N' )),
    
    check (v41_estado IN ('A' ,'P' ,'F' ,'B' ,'R' ))
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".veht041 from "public";

{ TABLE "fobos".cxct021 row size = 150 number of columns = 21 index size = 126 }
create table "fobos".cxct021 
  (
    z21_compania integer not null ,
    z21_localidad smallint not null ,
    z21_codcli integer not null ,
    z21_tipo_doc char(2) not null ,
    z21_num_doc integer not null ,
    z21_areaneg smallint not null ,
    z21_linea char(5) not null ,
    z21_referencia varchar(35,20),
    z21_fecha_emi date not null ,
    z21_moneda char(2) not null ,
    z21_paridad decimal(16,9) not null ,
    z21_val_impto decimal(12,2) not null ,
    z21_valor decimal(12,2) not null ,
    z21_saldo decimal(12,2) not null ,
    z21_subtipo smallint not null ,
    z21_origen char(1) not null ,
    z21_cod_tran char(2),
    z21_num_tran decimal(15,0),
    z21_num_sri char(21),
    z21_usuario varchar(10,5) not null ,
    z21_fecing datetime year to second not null ,
    
    check (z21_origen IN ('M' ,'A' ))
  )  extent size 276 next size 27 lock mode row;
revoke all on "fobos".cxct021 from "public";

{ TABLE "fobos".cxct023 row size = 82 number of columns = 17 index size = 160 }
create table "fobos".cxct023 
  (
    z23_compania integer not null ,
    z23_localidad smallint not null ,
    z23_codcli integer not null ,
    z23_tipo_trn char(2) not null ,
    z23_num_trn integer not null ,
    z23_orden integer not null ,
    z23_areaneg smallint not null ,
    z23_tipo_doc char(2) not null ,
    z23_num_doc char(15) not null ,
    z23_div_doc smallint not null ,
    z23_tipo_favor char(2),
    z23_doc_favor integer,
    z23_valor_cap decimal(12,2) not null ,
    z23_valor_int decimal(12,2) not null ,
    z23_valor_mora decimal(11,2) not null ,
    z23_saldo_cap decimal(12,2) not null ,
    z23_saldo_int decimal(12,2) not null 
  )  extent size 1785 next size 178 lock mode row;
revoke all on "fobos".cxct023 from "public";

{ TABLE "fobos".cxct050 row size = 188 number of columns = 30 index size = 151 }
create table "fobos".cxct050 
  (
    z50_ano smallint not null ,
    z50_mes smallint not null ,
    z50_compania integer not null ,
    z50_localidad smallint not null ,
    z50_codcli integer not null ,
    z50_tipo_doc char(2) not null ,
    z50_num_doc char(15) not null ,
    z50_dividendo smallint not null ,
    z50_areaneg smallint not null ,
    z50_referencia varchar(35,20),
    z50_fecha_emi date not null ,
    z50_fecha_vcto date not null ,
    z50_tasa_int decimal(4,2) not null ,
    z50_tasa_mora decimal(4,2) not null ,
    z50_moneda char(2) not null ,
    z50_paridad decimal(16,9) not null ,
    z50_val_impto decimal(11,2) not null ,
    z50_valor_cap decimal(12,2) not null ,
    z50_valor_int decimal(12,2) not null ,
    z50_saldo_cap decimal(12,2) not null ,
    z50_saldo_int decimal(12,2) not null ,
    z50_cartera smallint not null ,
    z50_linea char(5) not null ,
    z50_subtipo smallint,
    z50_origen char(1) not null ,
    z50_cod_tran char(2),
    z50_num_tran decimal(15,0),
    z50_num_sri char(16),
    z50_usuario varchar(10,5) not null ,
    z50_fecing datetime year to second not null ,
    
    check (z50_origen IN ('M' ,'A' ))
  )  extent size 2828 next size 282 lock mode row;
revoke all on "fobos".cxct050 from "public";

{ TABLE "fobos".cxct051 row size = 149 number of columns = 23 index size = 112 }
create table "fobos".cxct051 
  (
    z51_ano smallint not null ,
    z51_mes smallint not null ,
    z51_compania integer not null ,
    z51_localidad smallint not null ,
    z51_codcli integer not null ,
    z51_tipo_doc char(2) not null ,
    z51_num_doc integer not null ,
    z51_areaneg smallint not null ,
    z51_linea char(5) not null ,
    z51_referencia varchar(35,20),
    z51_fecha_emi date not null ,
    z51_moneda char(2) not null ,
    z51_paridad decimal(16,9) not null ,
    z51_val_impto decimal(12,2) not null ,
    z51_valor decimal(12,2) not null ,
    z51_saldo decimal(12,2) not null ,
    z51_subtipo smallint not null ,
    z51_origen char(1) not null ,
    z51_cod_tran char(2),
    z51_num_tran decimal(15,0),
    z51_num_sri char(16),
    z51_usuario varchar(10,5) not null ,
    z51_fecing datetime year to second not null ,
    
    check (z51_origen IN ('M' ,'A' ))
  )  extent size 649 next size 64 lock mode row;
revoke all on "fobos".cxct051 from "public";

{ TABLE "fobos".veht038 row size = 159 number of columns = 9 index size = 112 }
create table "fobos".veht038 
  (
    v38_compania integer not null ,
    v38_localidad smallint not null ,
    v38_orden_cheq integer not null ,
    v38_estado char(1) not null ,
    v38_codigo_veh integer not null ,
    v38_referencia varchar(120,60) not null ,
    v38_num_ot integer,
    v38_usuario varchar(10,5) not null ,
    v38_fecing datetime year to second not null ,
    
    check (v38_estado IN ('A' ,'P' ,'B' ))
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".veht038 from "public";

{ TABLE "fobos".veht022 row size = 268 number of columns = 31 index size = 256 }
create table "fobos".veht022 
  (
    v22_compania integer not null ,
    v22_localidad smallint not null ,
    v22_bodega char(2) not null ,
    v22_modelo char(15) not null ,
    v22_chasis char(25) not null ,
    v22_nuevo char(1) not null ,
    v22_codigo_veh integer not null ,
    v22_comentarios varchar(40,20) not null ,
    v22_estado char(1) not null ,
    v22_motor char(16),
    v22_ano smallint not null ,
    v22_cod_color char(10) not null ,
    v22_dueno varchar(30,15),
    v22_kilometraje integer,
    v22_placa char(10),
    v22_moneda_liq char(2) not null ,
    v22_costo_liq decimal(12,2) not null ,
    v22_cargo_liq decimal(12,2) not null ,
    v22_numero_liq integer,
    v22_fec_ing_bod datetime year to second,
    v22_pedido char(10),
    v22_moneda_ing char(2) not null ,
    v22_costo_ing decimal(12,2) not null ,
    v22_cargo_ing decimal(11,2) not null ,
    v22_costo_adi decimal(11,2) not null ,
    v22_moneda_prec char(2) not null ,
    v22_precio decimal(12,2) not null ,
    v22_cod_tran char(2),
    v22_num_tran decimal(15,0),
    v22_usuario varchar(10,5) not null ,
    v22_fecing datetime year to second not null ,
    
    check (v22_nuevo IN ('S' ,'N' )),
    
    check (v22_estado IN ('A' ,'P' ,'F' ,'B' ,'R' ,'M' ,'C' ))
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".veht022 from "public";

{ TABLE "fobos".cxct024 row size = 120 number of columns = 20 index size = 132 }
create table "fobos".cxct024 
  (
    z24_compania integer not null ,
    z24_localidad smallint not null ,
    z24_numero_sol integer not null ,
    z24_areaneg smallint not null ,
    z24_linea char(5) not null ,
    z24_codcli integer not null ,
    z24_tipo char(1) not null ,
    z24_estado char(1) not null ,
    z24_referencia varchar(35,20),
    z24_moneda char(2) not null ,
    z24_paridad decimal(16,9) not null ,
    z24_tasa_mora decimal(4,2) not null ,
    z24_total_cap decimal(12,2) not null ,
    z24_total_int decimal(12,2) not null ,
    z24_total_mora decimal(11,2) not null ,
    z24_cobrador smallint,
    z24_zona_cobro smallint,
    z24_subtipo smallint not null ,
    z24_usuario varchar(10,5) not null ,
    z24_fecing datetime year to second not null ,
    
    check (z24_tipo IN ('A' ,'P' )),
    
    check (z24_estado IN ('A' ,'P' ))
  )  extent size 901 next size 90 lock mode row;
revoke all on "fobos".cxct024 from "public";

{ TABLE "fobos".cxct025 row size = 58 number of columns = 11 index size = 97 }
create table "fobos".cxct025 
  (
    z25_compania integer not null ,
    z25_localidad smallint not null ,
    z25_numero_sol integer not null ,
    z25_orden integer not null ,
    z25_codcli integer not null ,
    z25_tipo_doc char(2) not null ,
    z25_num_doc char(15) not null ,
    z25_dividendo smallint not null ,
    z25_valor_cap decimal(12,2) not null ,
    z25_valor_int decimal(12,2) not null ,
    z25_valor_mora decimal(11,2) not null 
  )  extent size 908 next size 90 lock mode row;
revoke all on "fobos".cxct025 from "public";

{ TABLE "fobos".cxpt020 row size = 170 number of columns = 26 index size = 177 }
create table "fobos".cxpt020 
  (
    p20_compania integer not null ,
    p20_localidad smallint not null ,
    p20_codprov integer not null ,
    p20_tipo_doc char(2) not null ,
    p20_num_doc char(21) not null ,
    p20_dividendo smallint not null ,
    p20_referencia varchar(35,20),
    p20_fecha_emi date not null ,
    p20_fecha_vcto date not null ,
    p20_tasa_int decimal(4,2) not null ,
    p20_tasa_mora decimal(4,2) not null ,
    p20_moneda char(2) not null ,
    p20_paridad decimal(16,9) not null ,
    p20_valor_cap decimal(12,2) not null ,
    p20_valor_int decimal(12,2) not null ,
    p20_saldo_cap decimal(12,2) not null ,
    p20_saldo_int decimal(12,2) not null ,
    p20_valor_fact decimal(12,2) not null ,
    p20_porc_impto decimal(4,2) not null ,
    p20_valor_impto decimal(11,2) not null ,
    p20_cartera smallint not null ,
    p20_numero_oc integer,
    p20_origen char(1) not null ,
    p20_cod_depto smallint not null ,
    p20_usuario varchar(10,5) not null ,
    p20_fecing datetime year to second not null ,
    
    check (p20_origen IN ('M' ,'A' ))
  )  extent size 542 next size 54 lock mode row;
revoke all on "fobos".cxpt020 from "public";

{ TABLE "fobos".cxpt021 row size = 108 number of columns = 16 index size = 124 }
create table "fobos".cxpt021 
  (
    p21_compania integer not null ,
    p21_localidad smallint not null ,
    p21_codprov integer not null ,
    p21_tipo_doc char(2) not null ,
    p21_num_doc integer not null ,
    p21_referencia varchar(35,20),
    p21_fecha_emi date not null ,
    p21_moneda char(2) not null ,
    p21_paridad decimal(16,9) not null ,
    p21_valor decimal(12,2) not null ,
    p21_saldo decimal(12,2) not null ,
    p21_subtipo smallint,
    p21_origen char(1) not null ,
    p21_orden_pago integer,
    p21_usuario varchar(10,5) not null ,
    p21_fecing datetime year to second not null ,
    
    check (p21_origen IN ('M' ,'A' ))
  )  extent size 42 next size 16 lock mode row;
revoke all on "fobos".cxpt021 from "public";

{ TABLE "fobos".cxpt022 row size = 128 number of columns = 21 index size = 142 }
create table "fobos".cxpt022 
  (
    p22_compania integer not null ,
    p22_localidad smallint not null ,
    p22_codprov integer not null ,
    p22_tipo_trn char(2) not null ,
    p22_num_trn integer not null ,
    p22_referencia varchar(35,20),
    p22_fecha_emi date not null ,
    p22_moneda char(2) not null ,
    p22_paridad decimal(16,9) not null ,
    p22_tasa_mora decimal(4,2) not null ,
    p22_total_cap decimal(12,2) not null ,
    p22_total_int decimal(12,2) not null ,
    p22_total_mora decimal(12,2) not null ,
    p22_subtipo smallint,
    p22_origen char(1) not null ,
    p22_fecha_elim date,
    p22_tiptrn_elim char(2),
    p22_numtrn_elim integer,
    p22_orden_pago integer,
    p22_usuario varchar(10,5) not null ,
    p22_fecing datetime year to second not null ,
    
    check (p22_origen IN ('M' ,'A' ))
  )  extent size 805 next size 80 lock mode row;
revoke all on "fobos".cxpt022 from "public";

{ TABLE "fobos".cxpt050 row size = 174 number of columns = 28 index size = 171 }
create table "fobos".cxpt050 
  (
    p50_ano smallint not null ,
    p50_mes smallint not null ,
    p50_compania integer not null ,
    p50_localidad smallint not null ,
    p50_codprov integer not null ,
    p50_tipo_doc char(2) not null ,
    p50_num_doc char(21) not null ,
    p50_dividendo smallint not null ,
    p50_referencia varchar(35,20),
    p50_fecha_emi date not null ,
    p50_fecha_vcto date not null ,
    p50_tasa_int decimal(4,2) not null ,
    p50_tasa_mora decimal(4,2) not null ,
    p50_moneda char(2) not null ,
    p50_paridad decimal(16,9) not null ,
    p50_valor_cap decimal(12,2) not null ,
    p50_valor_int decimal(12,2) not null ,
    p50_saldo_cap decimal(12,2) not null ,
    p50_saldo_int decimal(12,2) not null ,
    p50_valor_fact decimal(12,2) not null ,
    p50_porc_impto decimal(4,2) not null ,
    p50_valor_impto decimal(11,2) not null ,
    p50_cartera smallint not null ,
    p50_numero_oc integer,
    p50_origen char(1) not null ,
    p50_cod_depto smallint not null ,
    p50_usuario varchar(10,5) not null ,
    p50_fecing datetime year to second not null ,
    
    check (p50_origen IN ('M' ,'A' ))
  )  extent size 523 next size 52 lock mode row;
revoke all on "fobos".cxpt050 from "public";

{ TABLE "fobos".cxpt051 row size = 112 number of columns = 18 index size = 97 }
create table "fobos".cxpt051 
  (
    p51_ano smallint not null ,
    p51_mes smallint not null ,
    p51_compania integer not null ,
    p51_localidad smallint not null ,
    p51_codprov integer not null ,
    p51_tipo_doc char(2) not null ,
    p51_num_doc integer not null ,
    p51_referencia varchar(35,20),
    p51_fecha_emi date not null ,
    p51_moneda char(2) not null ,
    p51_paridad decimal(16,9) not null ,
    p51_valor decimal(12,2) not null ,
    p51_saldo decimal(12,2) not null ,
    p51_subtipo smallint,
    p51_origen char(1) not null ,
    p51_orden_pago integer,
    p51_usuario varchar(10,5) not null ,
    p51_fecing datetime year to second not null ,
    
    check (p51_origen IN ('M' ,'A' ))
  )  extent size 21 next size 16 lock mode row;
revoke all on "fobos".cxpt051 from "public";

{ TABLE "fobos".cxpt023 row size = 86 number of columns = 16 index size = 154 }
create table "fobos".cxpt023 
  (
    p23_compania integer not null ,
    p23_localidad smallint not null ,
    p23_codprov integer not null ,
    p23_tipo_trn char(2) not null ,
    p23_num_trn integer not null ,
    p23_orden integer not null ,
    p23_tipo_doc char(2) not null ,
    p23_num_doc char(21) not null ,
    p23_div_doc smallint not null ,
    p23_tipo_favor char(2),
    p23_doc_favor integer,
    p23_valor_cap decimal(12,2) not null ,
    p23_valor_int decimal(12,2) not null ,
    p23_valor_mora decimal(11,2) not null ,
    p23_saldo_cap decimal(12,2) not null ,
    p23_saldo_int decimal(12,2) not null 
  )  extent size 816 next size 81 lock mode row;
revoke all on "fobos".cxpt023 from "public";

{ TABLE "fobos".cxpt024 row size = 156 number of columns = 23 index size = 141 }
create table "fobos".cxpt024 
  (
    p24_compania integer not null ,
    p24_localidad smallint not null ,
    p24_orden_pago integer not null ,
    p24_codprov integer not null ,
    p24_tipo char(1) not null ,
    p24_estado char(1) not null ,
    p24_referencia varchar(35,20),
    p24_moneda char(2) not null ,
    p24_paridad decimal(16,9) not null ,
    p24_tasa_mora decimal(4,2) not null ,
    p24_total_cap decimal(12,2) not null ,
    p24_total_int decimal(12,2) not null ,
    p24_total_mora decimal(11,2) not null ,
    p24_total_ret decimal(11,2) not null ,
    p24_total_che decimal(12,2) not null ,
    p24_subtipo smallint,
    p24_banco integer not null ,
    p24_numero_cta char(15) not null ,
    p24_numero_che integer,
    p24_tip_contable char(2),
    p24_num_contable char(8),
    p24_usuario varchar(10,5) not null ,
    p24_fecing datetime year to second not null ,
    
    check (p24_tipo IN ('A' ,'P' )),
    
    check (p24_estado IN ('A' ,'P' ))
  )  extent size 371 next size 37 lock mode row;
revoke all on "fobos".cxpt024 from "public";

{ TABLE "fobos".cxpt027 row size = 82 number of columns = 16 index size = 127 }
create table "fobos".cxpt027 
  (
    p27_compania integer not null ,
    p27_localidad smallint not null ,
    p27_num_ret integer not null ,
    p27_estado char(1) not null ,
    p27_codprov integer not null ,
    p27_moneda char(2) not null ,
    p27_paridad decimal(16,9) not null ,
    p27_total_ret decimal(11,2) not null ,
    p27_tip_contable char(2),
    p27_num_contable char(8),
    p27_tip_cont_eli char(2),
    p27_num_cont_eli char(8),
    p27_fecha_eli datetime year to second,
    p27_origen char(1) not null ,
    p27_usuario varchar(10,5) not null ,
    p27_fecing datetime year to second not null ,
    
    check (p27_estado IN ('A' ,'E' )),
    
    check (p27_origen IN ('M' ,'A' ))
  )  extent size 318 next size 31 lock mode row;
revoke all on "fobos".cxpt027 from "public";

{ TABLE "fobos".ordt002 row size = 63 number of columns = 9 index size = 84 }
create table "fobos".ordt002 
  (
    c02_compania integer not null ,
    c02_tipo_ret char(1) not null ,
    c02_porcentaje decimal(5,2) not null ,
    c02_estado char(1) not null ,
    c02_nombre varchar(20,10) not null ,
    c02_tipo_fuente char(1) not null ,
    c02_aux_cont char(12),
    c02_usuario varchar(10,5) not null ,
    c02_fecing datetime year to second not null ,
    
    check (c02_tipo_ret IN ('F' ,'I' )),
    
    check (c02_estado IN ('A' ,'B' )),
    
    check (c02_tipo_fuente IN ('B' ,'S' ,'T' ))
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".ordt002 from "public";

{ TABLE "fobos".actt010 row size = 212 number of columns = 30 index size = 207 }
create table "fobos".actt010 
  (
    a10_compania integer not null ,
    a10_codigo_bien integer not null ,
    a10_estado char(1) not null ,
    a10_descripcion varchar(40,20) not null ,
    a10_grupo_act smallint not null ,
    a10_tipo_act smallint not null ,
    a10_anos_util smallint not null ,
    a10_porc_deprec decimal(4,2) not null ,
    a10_modelo varchar(15),
    a10_serie varchar(25),
    a10_locali_ori smallint not null ,
    a10_numero_oc integer,
    a10_localidad smallint not null ,
    a10_cod_depto smallint not null ,
    a10_codprov integer not null ,
    a10_fecha_comp date not null ,
    a10_moneda char(2) not null ,
    a10_paridad decimal(16,9) not null ,
    a10_valor decimal(12,2) not null ,
    a10_valor_mb decimal(12,2) not null ,
    a10_responsable smallint,
    a10_fecha_baja date,
    a10_val_dep_mb decimal(11,2) not null ,
    a10_val_dep_ma decimal(11,2) not null ,
    a10_tot_dep_mb decimal(12,2) not null ,
    a10_tot_dep_ma decimal(12,2) not null ,
    a10_tot_reexpr decimal(12,2) not null ,
    a10_tot_dep_ree decimal(12,2) not null ,
    a10_usuario varchar(10,5) not null ,
    a10_fecing datetime year to second not null 
  )  extent size 53 next size 16 lock mode row;
revoke all on "fobos".actt010 from "public";

{ TABLE "fobos".actt001 row size = 171 number of columns = 18 index size = 319 }
create table "fobos".actt001 
  (
    a01_compania integer not null ,
    a01_grupo_act smallint not null ,
    a01_nombre varchar(30,15) not null ,
    a01_depreciable char(1) not null ,
    a01_anos_util smallint not null ,
    a01_porc_deprec decimal(4,2) not null ,
    a01_aux_activo char(12),
    a01_aux_reexpr char(12),
    a01_aux_dep_act char(12),
    a01_aux_dep_reex char(12),
    a01_aux_pago char(12),
    a01_aux_iva char(12),
    a01_aux_venta char(12),
    a01_aux_gasto char(12),
    a01_aux_transf char(12),
    a01_paga_iva char(1) not null ,
    a01_usuario varchar(10,5) not null ,
    a01_fecing datetime year to second not null ,
    
    check (a01_depreciable IN ('S' ,'N' )),
    
    check (a01_paga_iva IN ('S' ,'N' )) constraint "fobos".ck_02_actt001
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".actt001 from "public";

{ TABLE "fobos".actt002 row size = 58 number of columns = 6 index size = 52 }
create table "fobos".actt002 
  (
    a02_compania integer not null ,
    a02_tipo_act smallint not null ,
    a02_nombre varchar(30,15) not null ,
    a02_grupo_act smallint not null ,
    a02_usuario varchar(10,5) not null ,
    a02_fecing datetime year to second not null 
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".actt002 from "public";

{ TABLE "fobos".rept024 row size = 68 number of columns = 14 index size = 124 }
create table "fobos".rept024 
  (
    r24_compania integer not null ,
    r24_localidad smallint not null ,
    r24_numprev integer not null ,
    r24_bodega char(2) not null ,
    r24_item char(15) not null ,
    r24_orden smallint not null ,
    r24_cant_ped decimal(8,2) not null ,
    r24_cant_ven decimal(8,2) not null ,
    r24_descuento decimal(4,2) not null ,
    r24_val_descto decimal(10,2) not null ,
    r24_precio decimal(11,2) not null ,
    r24_val_impto decimal(11,2) not null ,
    r24_linea char(5) not null ,
    r24_proformado char(1) not null ,
    
    check (r24_proformado IN ('S' ,'N' )),
    primary key (r24_compania,r24_localidad,r24_numprev,r24_bodega,r24_item,r24_orden) 
               constraint "fobos".pk_rept024
  )  extent size 3128 next size 312 lock mode row;
revoke all on "fobos".rept024 from "public";

{ TABLE "fobos".veht003 row size = 55 number of columns = 7 index size = 73 }
create table "fobos".veht003 
  (
    v03_compania integer not null ,
    v03_linea char(5) not null ,
    v03_nombre varchar(20,10) not null ,
    v03_estado char(1) not null ,
    v03_grupo_linea char(5) not null ,
    v03_usuario varchar(10,5) not null ,
    v03_fecing datetime year to second not null ,
    
    check (v03_estado IN ('A' ,'B' ))
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".veht003 from "public";

{ TABLE "fobos".talt021 row size = 120 number of columns = 11 index size = 115 }
create table "fobos".talt021 
  (
    t21_compania integer not null ,
    t21_localidad smallint not null ,
    t21_numpre integer not null ,
    t21_codtarea char(12) not null ,
    t21_secuencia smallint not null ,
    t21_descripcion varchar(60,30) not null ,
    t21_porc_descto decimal(4,2) not null ,
    t21_val_descto decimal(10,2) not null ,
    t21_valor decimal(11,2) not null ,
    t21_usuario varchar(10,5) not null ,
    t21_fecing datetime year to second not null 
  )  extent size 102 next size 16 lock mode row;
revoke all on "fobos".talt021 from "public";

{ TABLE "fobos".cxct022 row size = 134 number of columns = 23 index size = 160 }
create table "fobos".cxct022 
  (
    z22_compania integer not null ,
    z22_localidad smallint not null ,
    z22_codcli integer not null ,
    z22_tipo_trn char(2) not null ,
    z22_num_trn integer not null ,
    z22_areaneg smallint not null ,
    z22_referencia varchar(35,20),
    z22_fecha_emi date not null ,
    z22_moneda char(2) not null ,
    z22_paridad decimal(16,9) not null ,
    z22_tasa_mora decimal(4,2) not null ,
    z22_total_cap decimal(12,2) not null ,
    z22_total_int decimal(12,2) not null ,
    z22_total_mora decimal(12,2) not null ,
    z22_cobrador smallint,
    z22_zona_cobro smallint,
    z22_subtipo smallint,
    z22_origen char(1) not null ,
    z22_fecha_elim datetime year to second,
    z22_tiptrn_elim char(2),
    z22_numtrn_elim integer,
    z22_usuario varchar(10,5) not null ,
    z22_fecing datetime year to second not null ,
    
    check (z22_origen IN ('M' ,'A' ))
  )  extent size 1403 next size 140 lock mode row;
revoke all on "fobos".cxct022 from "public";

{ TABLE "fobos".rept027 row size = 23 number of columns = 6 index size = 60 }
create table "fobos".rept027 
  (
    r27_compania integer not null ,
    r27_localidad smallint not null ,
    r27_numprev integer not null ,
    r27_tipo char(2) not null ,
    r27_numero integer not null ,
    r27_valor decimal(11,2) not null ,
    
    check (r27_tipo IN ('PA' ,'NC' ))
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".rept027 from "public";

{ TABLE "fobos".veht031 row size = 83 number of columns = 16 index size = 99 }
create table "fobos".veht031 
  (
    v31_compania integer not null ,
    v31_localidad smallint not null ,
    v31_cod_tran char(2) not null ,
    v31_num_tran decimal(15,0) not null ,
    v31_codigo_veh integer not null ,
    v31_nuevo char(1) not null ,
    v31_descuento decimal(4,2) not null ,
    v31_val_descto decimal(11,2) not null ,
    v31_precio decimal(12,2) not null ,
    v31_moneda_cost char(2) not null ,
    v31_costo decimal(12,2) not null ,
    v31_fob decimal(12,2) not null ,
    v31_costant_mb decimal(12,2) not null ,
    v31_costant_ma decimal(12,2) not null ,
    v31_costnue_mb decimal(12,2) not null ,
    v31_costnue_ma decimal(12,2) not null ,
    
    check (v31_nuevo IN ('S' ,'N' ))
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".veht031 from "public";

{ TABLE "fobos".gent023 row size = 36 number of columns = 8 index size = 42 }
create table "fobos".gent023 
  (
    g23_compania integer not null ,
    g23_localidad smallint not null ,
    g23_modulo char(2) not null ,
    g23_numaut_sri varchar(15,10) not null ,
    g23_fecaut_sri date not null ,
    g23_fecexp_sri date not null ,
    g23_serie_cia smallint not null ,
    g23_serie_loc smallint not null 
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".gent023 from "public";

{ TABLE "fobos".talt028 row size = 67 number of columns = 10 index size = 120 }
create table "fobos".talt028 
  (
    t28_compania integer not null ,
    t28_localidad smallint not null ,
    t28_num_dev decimal(15,0) not null ,
    t28_factura decimal(15,0) not null ,
    t28_fec_anula datetime year to second not null ,
    t28_fec_factura datetime year to second not null ,
    t28_ot_ant integer not null ,
    t28_ot_nue integer not null ,
    t28_usuario varchar(10,5) not null ,
    t28_fecing datetime year to second not null 
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".talt028 from "public";

{ TABLE "fobos".talt029 row size = 25 number of columns = 6 index size = 102 }
create table "fobos".talt029 
  (
    t29_compania integer not null ,
    t29_localidad smallint not null ,
    t29_num_dev decimal(15,0) not null ,
    t29_secuencia smallint not null ,
    t29_oc_ant integer not null ,
    t29_oc_nue integer not null 
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".talt029 from "public";

{ TABLE "fobos".cxct020 row size = 189 number of columns = 28 index size = 145 }
create table "fobos".cxct020 
  (
    z20_compania integer not null ,
    z20_localidad smallint not null ,
    z20_codcli integer not null ,
    z20_tipo_doc char(2) not null ,
    z20_num_doc char(15) not null ,
    z20_dividendo smallint not null ,
    z20_areaneg smallint not null ,
    z20_referencia varchar(35,20),
    z20_fecha_emi date not null ,
    z20_fecha_vcto date not null ,
    z20_tasa_int decimal(4,2) not null ,
    z20_tasa_mora decimal(4,2) not null ,
    z20_moneda char(2) not null ,
    z20_paridad decimal(16,9) not null ,
    z20_val_impto decimal(11,2) not null ,
    z20_valor_cap decimal(12,2) not null ,
    z20_valor_int decimal(12,2) not null ,
    z20_saldo_cap decimal(12,2) not null ,
    z20_saldo_int decimal(12,2) not null ,
    z20_cartera smallint not null ,
    z20_linea char(5) not null ,
    z20_subtipo smallint,
    z20_origen char(1) not null ,
    z20_cod_tran char(2),
    z20_num_tran decimal(15,0),
    z20_num_sri char(21),
    z20_usuario varchar(10,5) not null ,
    z20_fecing datetime year to second not null ,
    
    check (z20_origen IN ('M' ,'A' ))
  )  extent size 2044 next size 204 lock mode row;
revoke all on "fobos".cxct020 from "public";

{ TABLE "fobos".ordt015 row size = 32 number of columns = 8 index size = 51 }
create table "fobos".ordt015 
  (
    c15_compania integer not null ,
    c15_localidad smallint not null ,
    c15_numero_oc integer not null ,
    c15_num_recep smallint not null ,
    c15_dividendo smallint not null ,
    c15_fecha_vcto date not null ,
    c15_valor_cap decimal(12,2) not null ,
    c15_valor_int decimal(12,2) not null 
  )  extent size 103 next size 16 lock mode row;
revoke all on "fobos".ordt015 from "public";

{ TABLE "fobos".ordt016 row size = 25 number of columns = 8 index size = 90 }
create table "fobos".ordt016 
  (
    c16_compania integer not null ,
    c16_localidad smallint not null ,
    c16_ano smallint not null ,
    c16_mes smallint not null ,
    c16_cod_depto smallint not null ,
    c16_codprov integer not null ,
    c16_moneda char(2) not null ,
    c16_valor decimal(12,2) not null 
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".ordt016 from "public";

{ TABLE "fobos".cxpt005 row size = 23 number of columns = 6 index size = 99 }
create table "fobos".cxpt005 
  (
    p05_compania integer not null ,
    p05_codprov integer not null ,
    p05_tipo_ret char(1) not null ,
    p05_porcentaje decimal(5,2) not null ,
    p05_codigo_sri char(6) not null ,
    p05_fecha_ini_porc date not null 
  )  extent size 30 next size 16 lock mode row;
revoke all on "fobos".cxpt005 from "public";

{ TABLE "fobos".cxpt030 row size = 33 number of columns = 7 index size = 54 }
create table "fobos".cxpt030 
  (
    p30_compania integer not null ,
    p30_localidad smallint not null ,
    p30_codprov integer not null ,
    p30_moneda char(2) not null ,
    p30_saldo_venc decimal(12,2) not null ,
    p30_saldo_xvenc decimal(12,2) not null ,
    p30_saldo_favor decimal(12,2) not null 
  )  extent size 18 next size 16 lock mode row;
revoke all on "fobos".cxpt030 from "public";

{ TABLE "fobos".cxpt031 row size = 44 number of columns = 11 index size = 66 }
create table "fobos".cxpt031 
  (
    p31_compania integer not null ,
    p31_ano smallint not null ,
    p31_mes smallint not null ,
    p31_localidad smallint not null ,
    p31_cartera smallint not null ,
    p31_tipo_prov smallint not null ,
    p31_moneda char(2) not null ,
    p31_saldo_venc decimal(12,2) not null ,
    p31_saldo_xvenc decimal(12,2) not null ,
    p31_tot_creditos decimal(12,2) not null ,
    p31_tot_pagos decimal(12,2) not null 
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".cxpt031 from "public";

{ TABLE "fobos".rept030 row size = 74 number of columns = 11 index size = 69 }
create table "fobos".rept030 
  (
    r30_compania integer not null ,
    r30_localidad smallint not null ,
    r30_numliq integer not null ,
    r30_serial serial not null ,
    r30_codrubro integer not null ,
    r30_orden smallint not null ,
    r30_fecha date,
    r30_observacion varchar(30,15),
    r30_moneda char(2) not null ,
    r30_paridad decimal(16,9) not null ,
    r30_valor decimal(11,2) not null 
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".rept030 from "public";

{ TABLE "fobos".gent021 row size = 48 number of columns = 9 index size = 31 }
create table "fobos".gent021 
  (
    g21_cod_tran char(2) not null ,
    g21_nombre varchar(20,10) not null ,
    g21_estado char(1) not null ,
    g21_tipo char(1) not null ,
    g21_calc_costo char(1) not null ,
    g21_codigo_dev char(2),
    g21_act_estad char(1) not null ,
    g21_usuario varchar(10,5) not null ,
    g21_fecing datetime year to second not null ,
    
    check (g21_estado IN ('A' ,'B' )),
    
    check (g21_calc_costo IN ('S' ,'N' )),
    
    check (g21_tipo IN ('I' ,'E' ,'C' ,'T' )),
    
    check (g21_act_estad IN ('S' ,'N' ))
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".gent021 from "public";

{ TABLE "fobos".cajt004 row size = 41 number of columns = 8 index size = 67 }
create table "fobos".cajt004 
  (
    j04_compania integer not null ,
    j04_localidad smallint not null ,
    j04_codigo_caja smallint not null ,
    j04_fecha_aper date not null ,
    j04_secuencia smallint not null ,
    j04_fecha_cierre datetime year to second,
    j04_usuario varchar(10,5) not null ,
    j04_fecing datetime year to second not null 
  )  extent size 101 next size 16 lock mode row;
revoke all on "fobos".cajt004 from "public";

{ TABLE "fobos".cajt005 row size = 58 number of columns = 12 index size = 66 }
create table "fobos".cajt005 
  (
    j05_compania integer not null ,
    j05_localidad smallint not null ,
    j05_codigo_caja smallint not null ,
    j05_fecha_aper date not null ,
    j05_secuencia smallint not null ,
    j05_moneda char(2) not null ,
    j05_ef_apertura decimal(12,2) not null ,
    j05_ch_apertura decimal(12,2) not null ,
    j05_ef_ing_dia decimal(12,2) not null ,
    j05_ch_ing_dia decimal(12,2) not null ,
    j05_ef_egr_dia decimal(12,2) not null ,
    j05_ch_egr_dia decimal(12,2) not null 
  )  extent size 116 next size 16 lock mode row;
revoke all on "fobos".cajt005 from "public";

{ TABLE "fobos".ctbt040 row size = 127 number of columns = 15 index size = 34 }
create table "fobos".ctbt040 
  (
    b40_compania integer not null ,
    b40_localidad smallint not null ,
    b40_modulo char(2) not null ,
    b40_bodega char(2) not null ,
    b40_grupo_linea char(5) not null ,
    b40_porc_impto decimal(5,2) not null ,
    b40_venta char(12) not null ,
    b40_descuento char(12) not null ,
    b40_dev_venta char(12) not null ,
    b40_costo_venta char(12) not null ,
    b40_dev_costo char(12) not null ,
    b40_inventario char(12) not null ,
    b40_transito char(12) not null ,
    b40_ajustes char(12) not null ,
    b40_flete char(12) not null 
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".ctbt040 from "public";

{ TABLE "fobos".ctbt041 row size = 97 number of columns = 11 index size = 25 }
create table "fobos".ctbt041 
  (
    b41_compania integer not null ,
    b41_localidad smallint not null ,
    b41_modulo char(2) not null ,
    b41_grupo_linea char(5) not null ,
    b41_caja_mb char(12) not null ,
    b41_caja_me char(12) not null ,
    b41_cxc_mb char(12) not null ,
    b41_cxc_me char(12) not null ,
    b41_ant_mb char(12) not null ,
    b41_ant_me char(12) not null ,
    b41_intereses char(12)
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".ctbt041 from "public";

{ TABLE "fobos".ctbt042 row size = 102 number of columns = 10 index size = 15 }
create table "fobos".ctbt042 
  (
    b42_compania integer not null ,
    b42_localidad smallint not null ,
    b42_iva_venta char(12) not null ,
    b42_iva_compra char(12) not null ,
    b42_iva_import char(12),
    b42_retencion char(12) not null ,
    b42_reten_cred char(12),
    b42_flete_comp char(12),
    b42_otros_comp char(12),
    b42_cuadre char(12)
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".ctbt042 from "public";

{ TABLE "fobos".rept040 row size = 27 number of columns = 6 index size = 105 }
create table "fobos".rept040 
  (
    r40_compania integer not null ,
    r40_localidad smallint not null ,
    r40_cod_tran char(2) not null ,
    r40_num_tran decimal(15,0) not null ,
    r40_tipo_comp char(2) not null ,
    r40_num_comp char(8) not null 
  )  extent size 1781 next size 178 lock mode row;
revoke all on "fobos".rept040 from "public";

{ TABLE "fobos".cxct040 row size = 26 number of columns = 7 index size = 102 }
create table "fobos".cxct040 
  (
    z40_compania integer not null ,
    z40_localidad smallint not null ,
    z40_codcli integer not null ,
    z40_tipo_doc char(2) not null ,
    z40_num_doc integer not null ,
    z40_tipo_comp char(2) not null ,
    z40_num_comp char(8) not null 
  )  extent size 283 next size 28 lock mode row;
revoke all on "fobos".cxct040 from "public";

{ TABLE "fobos".veht050 row size = 27 number of columns = 6 index size = 46 }
create table "fobos".veht050 
  (
    v50_compania integer not null ,
    v50_localidad smallint not null ,
    v50_cod_tran char(2) not null ,
    v50_num_tran decimal(15,0) not null ,
    v50_tipo_comp char(2) not null ,
    v50_num_comp char(8) not null 
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".veht050 from "public";

{ TABLE "fobos".ctbt043 row size = 483 number of columns = 43 index size = 28 }
create table "fobos".ctbt043 
  (
    b43_compania integer not null ,
    b43_localidad smallint not null ,
    b43_grupo_linea char(5) not null ,
    b43_porc_impto decimal(5,2) not null ,
    b43_vta_mo_tal char(12) not null ,
    b43_vta_mo_ext char(12) not null ,
    b43_vta_mo_cti char(12) not null ,
    b43_vta_rp_tal char(12) not null ,
    b43_vta_rp_ext char(12) not null ,
    b43_vta_rp_cti char(12) not null ,
    b43_vta_rp_alm char(12) not null ,
    b43_vta_otros1 char(12) not null ,
    b43_vta_otros2 char(12) not null ,
    b43_dvt_mo_tal char(12),
    b43_dvt_mo_ext char(12),
    b43_dvt_mo_cti char(12),
    b43_dvt_rp_tal char(12),
    b43_dvt_rp_ext char(12),
    b43_dvt_rp_cti char(12),
    b43_dvt_rp_alm char(12),
    b43_dvt_otros1 char(12),
    b43_dvt_otros2 char(12),
    b43_cos_mo_tal char(12),
    b43_cos_mo_ext char(12),
    b43_cos_mo_cti char(12),
    b43_cos_rp_tal char(12),
    b43_cos_rp_ext char(12),
    b43_cos_rp_cti char(12),
    b43_cos_rp_alm char(12),
    b43_cos_otros1 char(12),
    b43_cos_otros2 char(12),
    b43_pro_mo_tal char(12),
    b43_pro_mo_ext char(12),
    b43_pro_mo_cti char(12),
    b43_pro_rp_tal char(12),
    b43_pro_rp_ext char(12),
    b43_pro_rp_cti char(12),
    b43_pro_rp_alm char(12),
    b43_pro_otros1 char(12),
    b43_pro_otros2 char(12),
    b43_des_mo_tal char(12) not null ,
    b43_des_rp_tal char(12) not null ,
    b43_des_rp_alm char(12) not null 
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".ctbt043 from "public";

{ TABLE "fobos".talt050 row size = 29 number of columns = 6 index size = 112 }
create table "fobos".talt050 
  (
    t50_compania integer not null ,
    t50_localidad smallint not null ,
    t50_orden integer not null ,
    t50_factura decimal(15,0),
    t50_tipo_comp char(2) not null ,
    t50_num_comp char(8) not null 
  )  extent size 22 next size 16 lock mode row;
revoke all on "fobos".talt050 from "public";

{ TABLE "fobos".veht042 row size = 39 number of columns = 4 index size = 34 }
create table "fobos".veht042 
  (
    v42_compania integer not null ,
    v42_modelo char(15) not null ,
    v42_linea char(5) not null ,
    v42_bmp char(15),
    primary key (v42_compania,v42_modelo)  constraint "fobos".pk_veht042
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".veht042 from "public";

{ TABLE "fobos".ordt040 row size = 22 number of columns = 6 index size = 66 }
create table "fobos".ordt040 
  (
    c40_compania integer not null ,
    c40_localidad smallint not null ,
    c40_numero_oc integer not null ,
    c40_num_recep smallint not null ,
    c40_tipo_comp char(2) not null ,
    c40_num_comp char(8) not null 
  )  extent size 75 next size 16 lock mode row;
revoke all on "fobos".ordt040 from "public";

{ TABLE "fobos".talt030 row size = 238 number of columns = 15 index size = 100 }
create table "fobos".talt030 
  (
    t30_compania integer not null ,
    t30_localidad smallint not null ,
    t30_num_gasto integer not null ,
    t30_num_ot integer not null ,
    t30_estado char(1) not null ,
    t30_origen varchar(30,15) not null ,
    t30_destino varchar(30,15) not null ,
    t30_fec_ini_viaje date not null ,
    t30_fec_fin_viaje date,
    t30_recargo decimal(5,2) not null ,
    t30_desc_viaje varchar(120,60) not null ,
    t30_moneda char(2) not null ,
    t30_tot_gasto decimal(12,2) not null ,
    t30_usuario varchar(10,5) not null ,
    t30_fecing datetime year to second not null ,
    
    check (t30_estado IN ('A' ,'E' ))
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".talt030 from "public";

{ TABLE "fobos".talt031 row size = 62 number of columns = 7 index size = 54 }
create table "fobos".talt031 
  (
    t31_compania integer not null ,
    t31_localidad smallint not null ,
    t31_num_gasto integer not null ,
    t31_secuencia smallint not null ,
    t31_descripcion varchar(40,20) not null ,
    t31_moneda char(2) not null ,
    t31_valor decimal(11,2) not null 
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".talt031 from "public";

{ TABLE "fobos".talt032 row size = 13 number of columns = 5 index size = 69 }
create table "fobos".talt032 
  (
    t32_compania integer not null ,
    t32_localidad smallint not null ,
    t32_num_gasto integer not null ,
    t32_mecanico smallint not null ,
    t32_principal char(1) not null ,
    
    check (t32_principal IN ('S' ,'N' ))
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".talt032 from "public";

{ TABLE "fobos".talt033 row size = 26 number of columns = 8 index size = 48 }
create table "fobos".talt033 
  (
    t33_compania integer not null ,
    t33_localidad smallint not null ,
    t33_num_gasto integer not null ,
    t33_fecha date not null ,
    t33_hor_sal_viaje datetime hour to minute not null ,
    t33_hor_lleg_dest1 datetime hour to minute not null ,
    t33_hor_sal_rep datetime hour to minute not null ,
    t33_hor_lleg_dest2 datetime hour to minute not null 
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".talt033 from "public";

{ TABLE "fobos".rept034 row size = 209 number of columns = 12 index size = 55 }
create table "fobos".rept034 
  (
    r34_compania integer not null ,
    r34_localidad smallint not null ,
    r34_bodega char(2) not null ,
    r34_num_ord_des integer not null ,
    r34_estado char(1) not null ,
    r34_cod_tran char(2) not null ,
    r34_num_tran decimal(15,0) not null ,
    r34_fec_entrega date not null ,
    r34_entregar_a varchar(40,20) not null ,
    r34_entregar_en varchar(120,20) not null ,
    r34_usuario varchar(10,5) not null ,
    r34_fecing datetime year to second not null ,
    
    check (r34_estado IN ('A' ,'D' ,'P' ,'E' )),
    primary key (r34_compania,r34_localidad,r34_bodega,r34_num_ord_des)  constraint 
              "fobos".pk_rept034
  )  extent size 2047 next size 204 lock mode row;
revoke all on "fobos".rept034 from "public";

{ TABLE "fobos".rept035 row size = 39 number of columns = 8 index size = 108 }
create table "fobos".rept035 
  (
    r35_compania integer not null ,
    r35_localidad smallint not null ,
    r35_bodega char(2) not null ,
    r35_num_ord_des integer not null ,
    r35_item char(15) not null ,
    r35_orden smallint not null ,
    r35_cant_des decimal(8,2) not null ,
    r35_cant_ent decimal(8,2) not null ,
    primary key (r35_compania,r35_localidad,r35_bodega,r35_num_ord_des,r35_item,r35_orden) 
               constraint "fobos".pk_rept035
  )  extent size 2367 next size 236 lock mode row;
revoke all on "fobos".rept035 from "public";

{ TABLE "fobos".rept036 row size = 204 number of columns = 12 index size = 48 }
create table "fobos".rept036 
  (
    r36_compania integer not null ,
    r36_localidad smallint not null ,
    r36_bodega char(2) not null ,
    r36_num_entrega integer not null ,
    r36_num_ord_des integer not null ,
    r36_estado char(1) not null ,
    r36_fec_entrega date not null ,
    r36_entregar_a varchar(40,20) not null ,
    r36_entregar_en varchar(120,20) not null ,
    r36_bodega_real char(2) not null ,
    r36_usuario varchar(10,5) not null ,
    r36_fecing datetime year to second not null ,
    
    check (r36_estado IN ('A' ,'E' )),
    primary key (r36_compania,r36_localidad,r36_bodega,r36_num_entrega)  constraint 
              "fobos".pk_rept036
  )  extent size 1930 next size 193 lock mode row;
revoke all on "fobos".rept036 from "public";

{ TABLE "fobos".rept037 row size = 34 number of columns = 7 index size = 108 }
create table "fobos".rept037 
  (
    r37_compania integer not null ,
    r37_localidad smallint not null ,
    r37_bodega char(2) not null ,
    r37_num_entrega integer not null ,
    r37_item char(15) not null ,
    r37_orden smallint not null ,
    r37_cant_ent decimal(8,2) not null ,
    primary key (r37_compania,r37_localidad,r37_bodega,r37_num_entrega,r37_item,r37_orden) 
               constraint "fobos".pk_rept037
  )  extent size 2217 next size 221 lock mode row;
revoke all on "fobos".rept037 from "public";

{ TABLE "fobos".ctbt032 row size = 121 number of columns = 13 index size = 78 }
create table "fobos".ctbt032 
  (
    b32_compania integer not null ,
    b32_tipo_comp char(2) not null ,
    b32_num_comp char(8) not null ,
    b32_secuencia smallint not null ,
    b32_cuenta char(12),
    b32_tipo_doc char(3),
    b32_benef_che varchar(25),
    b32_num_cheque integer,
    b32_glosa varchar(35),
    b32_valor_base decimal(14,2) not null ,
    b32_valor_aux decimal(14,2) not null ,
    b32_num_concil integer,
    b32_fec_proceso date not null 
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".ctbt032 from "public";

{ TABLE "fobos".rept074 row size = 78 number of columns = 6 index size = 66 }
create table "fobos".rept074 
  (
    r74_compania integer not null ,
    r74_electrico char(13) not null ,
    r74_descripcion varchar(40,20) not null ,
    r74_estado char(1) not null ,
    r74_usuario varchar(10,5) not null ,
    r74_fecing datetime year to second not null ,
    
    check (r74_estado IN ('A' ,'E' ))
  )  extent size 138 next size 16 lock mode row;
revoke all on "fobos".rept074 from "public";

{ TABLE "fobos".rept075 row size = 93 number of columns = 8 index size = 123 }
create table "fobos".rept075 
  (
    r75_compania integer not null ,
    r75_item char(15) not null ,
    r75_marca char(3) not null ,
    r75_color char(10) not null ,
    r75_descripcion varchar(40,20) not null ,
    r75_estado char(1) not null ,
    r75_usuario varchar(10,5) not null ,
    r75_fecing datetime year to second not null ,
    
    check (r75_estado IN ('A' ,'E' )),
    primary key (r75_compania,r75_item,r75_marca,r75_color)  constraint "fobos".pk_rept075
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".rept075 from "public";

{ TABLE "fobos".rept070 row size = 66 number of columns = 6 index size = 64 }
create table "fobos".rept070 
  (
    r70_compania integer not null ,
    r70_linea char(5) not null ,
    r70_sub_linea char(2) not null ,
    r70_desc_sub varchar(35,20) not null ,
    r70_usuario varchar(10,5) not null ,
    r70_fecing datetime year to second not null ,
    primary key (r70_compania,r70_linea,r70_sub_linea)  constraint "fobos".pk_rept070
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".rept070 from "public";

{ TABLE "fobos".rept073 row size = 65 number of columns = 5 index size = 43 }
create table "fobos".rept073 
  (
    r73_compania integer not null ,
    r73_marca char(6) not null ,
    r73_desc_marca varchar(35,20) not null ,
    r73_usuario varchar(10,5) not null ,
    r73_fecing datetime year to second not null ,
    primary key (r73_compania,r73_marca)  constraint "fobos".pk_rept073
  )  extent size 29 next size 16 lock mode row;
revoke all on "fobos".rept073 from "public";

{ TABLE "fobos".te_cxct001 row size = 258 number of columns = 20 index size = 0 }
create table "fobos".te_cxct001 
  (
    te_codcli integer,
    te_estado char(1),
    te_nomcli varchar(40,20),
    te_direccion1 varchar(40,20),
    te_direccion2 varchar(40,20),
    te_telefono1 char(10),
    te_telefono2 char(10),
    te_fax1 char(11),
    te_fax2 char(11),
    te_casilla char(10),
    te_pais integer,
    te_ciudad integer,
    te_tipo_clte smallint,
    te_personeria char(1),
    te_tipo_doc_id char(1),
    te_num_doc_id char(15),
    te_rep_legal varchar(30,15),
    te_paga_impto char(1),
    te_usuario varchar(10,5),
    te_fecing datetime year to second
  )  extent size 645 next size 64 lock mode row;
revoke all on "fobos".te_cxct001 from "public";

{ TABLE "fobos".te_rept071 row size = 70 number of columns = 7 index size = 0 }
create table "fobos".te_rept071 
  (
    te_compania integer not null ,
    te_linea char(5) not null ,
    te_sub_linea char(2) not null ,
    te_cod_grupo char(4) not null ,
    te_desc_grupo varchar(35,20) not null ,
    te_usuario varchar(10,5) not null ,
    te_fecing datetime year to second not null 
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".te_rept071 from "public";

{ TABLE "fobos".te_rept070 row size = 66 number of columns = 6 index size = 0 }
create table "fobos".te_rept070 
  (
    te_compania integer not null ,
    te_linea char(5) not null ,
    te_sub_linea char(2) not null ,
    te_desc_sub varchar(35,20) not null ,
    te_usuario varchar(10,5) not null ,
    te_fecing datetime year to second not null 
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".te_rept070 from "public";

{ TABLE "fobos".rept010 row size = 582 number of columns = 51 index size = 306 }
create table "fobos".rept010 
  (
    r10_compania integer not null ,
    r10_codigo char(15) not null ,
    r10_nombre varchar(70,20) not null ,
    r10_estado char(1) not null ,
    r10_tipo smallint not null ,
    r10_peso decimal(7,3) not null ,
    r10_uni_med char(7) not null ,
    r10_cantpaq decimal(8,2) not null ,
    r10_cantveh decimal(8,2) not null ,
    r10_partida varchar(15,8) not null ,
    r10_modelo varchar(20,5) not null ,
    r10_cod_pedido char(20),
    r10_cod_comerc char(60),
    r10_cod_util char(5) not null ,
    r10_linea char(5) not null ,
    r10_sub_linea char(2) not null ,
    r10_cod_grupo char(4) not null ,
    r10_cod_clase char(8) not null ,
    r10_marca char(6) not null ,
    r10_rotacion char(2) not null ,
    r10_paga_impto char(1) not null ,
    r10_fob decimal(13,4) not null ,
    r10_monfob char(2) not null ,
    r10_precio_mb decimal(11,2) not null ,
    r10_precio_ma decimal(11,2) not null ,
    r10_costo_mb decimal(11,2) not null ,
    r10_costo_ma decimal(11,2) not null ,
    r10_costult_mb decimal(11,2) not null ,
    r10_costult_ma decimal(11,2) not null ,
    r10_costrepo_mb decimal(11,2),
    r10_usu_cosrepo varchar(10,5),
    r10_fec_cosrepo datetime year to second,
    r10_cantped decimal(11,2) not null ,
    r10_cantback decimal(11,2) not null ,
    r10_comentarios varchar(120),
    r10_precio_ant decimal(11,2) not null ,
    r10_fec_camprec datetime year to second,
    r10_proveedor integer,
    r10_filtro char(10),
    r10_electrico char(13),
    r10_color char(10),
    r10_serie_lote char(1),
    r10_stock_max integer,
    r10_stock_min integer,
    r10_vol_cuft decimal(5,2),
    r10_dias_mant integer,
    r10_dias_inv integer,
    r10_sec_item integer not null ,
    r10_usuario varchar(10,5) not null ,
    r10_fecing datetime year to second not null ,
    r10_feceli datetime year to second,
    
    check (r10_estado IN ('A' ,'B' ,'S' )),
    
    check (r10_paga_impto IN ('S' ,'N' )),
    
    check (r10_serie_lote IN ('S' ,'L' ,'G' ))
  )  extent size 19120 next size 1912 lock mode row;
revoke all on "fobos".rept010 from "public";

{ TABLE "fobos".te_rept010 row size = 528 number of columns = 50 index size = 34 
              }
create table "fobos".te_rept010 
  (
    te_compania integer not null ,
    te_codigo char(15) not null ,
    te_nombre varchar(70,20) not null ,
    te_estado char(1) not null ,
    te_tipo smallint not null ,
    te_peso decimal(7,3) not null ,
    te_uni_med char(7) not null ,
    te_cantpaq smallint not null ,
    te_cantveh smallint not null ,
    te_partida varchar(15,8) not null ,
    te_modelo varchar(20,5) not null ,
    te_cod_pedido char(15),
    te_cod_comerc char(15),
    te_cod_util char(4),
    te_linea char(5) not null ,
    te_sub_linea char(2) not null ,
    te_cod_grupo char(4) not null ,
    te_cod_clase char(8) not null ,
    te_marca char(6) not null ,
    te_rotacion char(2) not null ,
    te_paga_impto char(1) not null ,
    te_fob decimal(9,2) not null ,
    te_monfob char(2) not null ,
    te_precio_mb decimal(11,2) not null ,
    te_precio_ma decimal(11,2) not null ,
    te_costo_mb decimal(11,2) not null ,
    te_costo_ma decimal(11,2) not null ,
    te_costult_mb decimal(11,2) not null ,
    te_costult_ma decimal(11,2) not null ,
    te_costrepo_mb decimal(11,2),
    te_usu_cosrepo varchar(10,5),
    te_fec_cosrepo datetime year to second,
    te_cantped smallint not null ,
    te_cantback smallint not null ,
    te_comentarios varchar(120),
    te_precio_ant decimal(11,2) not null ,
    te_fec_camprec datetime year to second,
    te_proveedor integer,
    te_filtro char(10),
    te_electrico char(13),
    te_color char(10),
    te_serie char(20),
    te_stock_max integer,
    te_stock_min integer,
    te_vol_cuft decimal(5,2),
    te_dias_mant integer,
    te_dias_inv integer,
    te_usuario varchar(10,5) not null ,
    te_fecing datetime year to second not null ,
    te_feceli datetime year to second,
    
    check (te_estado IN ('A' ,'B' ,'S' )),
    
    check (te_paga_impto IN ('S' ,'N' ))
  )  extent size 11450 next size 1145 lock mode row;
revoke all on "fobos".te_rept010 from "public";

{ TABLE "fobos".te_rept006 row size = 32 number of columns = 5 index size = 0 }
create table "fobos".te_rept006 
  (
    t06_codigo smallint not null ,
    t06_cod_acero char(1) not null ,
    t06_nombre char(10) not null ,
    t06_usuario varchar(10,5) not null ,
    t06_fecing datetime year to second not null 
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".te_rept006 from "public";

{ TABLE "fobos".rept076 row size = 63 number of columns = 8 index size = 154 }
create table "fobos".rept076 
  (
    r76_compania integer not null ,
    r76_localidad smallint not null ,
    r76_bodega char(2) not null ,
    r76_item char(15) not null ,
    r76_serie char(20) not null ,
    r76_estado char(1) not null ,
    r76_usuario varchar(10,5) not null ,
    r76_fecing datetime year to second not null ,
    
    check (r76_estado IN ('A' ,'F' ,'D' ,'E' )),
    primary key (r76_compania,r76_localidad,r76_bodega,r76_item,r76_serie)  constraint 
              "fobos".pk_rept076
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".rept076 from "public";

{ TABLE "fobos".rept078 row size = 71 number of columns = 10 index size = 154 }
create table "fobos".rept078 
  (
    r78_compania integer not null ,
    r78_localidad smallint not null ,
    r78_bodega char(2) not null ,
    r78_item char(15) not null ,
    r78_lote char(20) not null ,
    r78_num_ord_des integer,
    r78_fec_lote date,
    r78_estado char(1) not null ,
    r78_usuario varchar(10,5) not null ,
    r78_fecing datetime year to second not null ,
    
    check (r78_estado IN ('A' ,'F' ,'D' ,'E' )),
    primary key (r78_compania,r78_localidad,r78_bodega,r78_item,r78_lote)  constraint 
              "fobos".pk_rept078
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".rept078 from "public";

{ TABLE "fobos".te_cxpt001 row size = 276 number of columns = 24 index size = 0 }
create table "fobos".te_cxpt001 
  (
    t01_codprov integer not null ,
    t01_estado char(1) not null ,
    t01_nomprov varchar(40,20) not null ,
    t01_direccion1 varchar(40,20) not null ,
    t01_direccion2 varchar(40,20),
    t01_telefono1 char(10) not null ,
    t01_telefono2 char(10),
    t01_fax1 char(11),
    t01_fax2 char(11),
    t01_casilla char(10),
    t01_pais integer not null ,
    t01_ciudad integer not null ,
    t01_tipo_prov smallint not null ,
    t01_personeria char(1) not null ,
    t01_tipo_doc char(1) not null ,
    t01_num_doc char(15) not null ,
    t01_rep_legal varchar(30,15),
    t01_cont_espe char(1) not null ,
    t01_ret_fuente char(1) not null ,
    t01_ret_impto char(1) not null ,
    t01_serie_comp char(6),
    t01_num_aut char(10),
    t01_usuario varchar(10,5) not null ,
    t01_fecing datetime year to second not null ,
    
    check (t01_estado IN ('A' ,'B' )),
    
    check (t01_personeria IN ('N' ,'J' )),
    
    check (t01_tipo_doc IN ('C' ,'P' ,'R' )),
    
    check (t01_cont_espe IN ('S' ,'N' )),
    
    check (t01_ret_fuente IN ('S' ,'N' )),
    
    check (t01_ret_impto IN ('S' ,'N' ))
  )  extent size 28 next size 16 lock mode row;
revoke all on "fobos".te_cxpt001 from "public";

{ TABLE "fobos".te_cxct020 row size = 188 number of columns = 28 index size = 0 }
create table "fobos".te_cxct020 
  (
    t20_compania integer not null ,
    t20_localidad smallint not null ,
    t20_codcli integer not null ,
    t20_tipo_doc char(2) not null ,
    t20_num_doc char(15) not null ,
    t20_dividendo smallint not null ,
    t20_areaneg smallint not null ,
    t20_referencia varchar(35,20),
    t20_fecha_emi date not null ,
    t20_fecha_vcto date not null ,
    t20_tasa_int decimal(4,2) not null ,
    t20_tasa_mora decimal(4,2) not null ,
    t20_moneda char(2) not null ,
    t20_paridad decimal(16,9) not null ,
    t20_val_impto decimal(12,2),
    t20_valor_cap decimal(12,2) not null ,
    t20_valor_int decimal(12,2) not null ,
    t20_saldo_cap decimal(12,2) not null ,
    t20_saldo_int decimal(12,2) not null ,
    t20_cartera smallint not null ,
    t20_linea char(5) not null ,
    t20_subtipo smallint,
    t20_origen char(1) not null ,
    t20_cod_tran char(2),
    t20_num_tran decimal(15,0),
    t20_num_sri char(20),
    t20_usuario varchar(10,5) not null ,
    t20_fecing datetime year to second not null ,
    
    check (t20_origen IN ('M' ,'A' ))
  )  extent size 113 next size 16 lock mode row;
revoke all on "fobos".te_cxct020 from "public";

{ TABLE "fobos".te_rept003 row size = 79 number of columns = 13 index size = 0 }
create table "fobos".te_rept003 
  (
    r03_compania integer not null ,
    r03_codigo char(5) not null ,
    r03_nombre varchar(30,15) not null ,
    r03_estado char(1) not null ,
    r03_area char(1) not null ,
    r03_porc_uti decimal(4,2) not null ,
    r03_tipo char(1) not null ,
    r03_dcto_tal decimal(4,2) not null ,
    r03_dcto_cont decimal(4,2) not null ,
    r03_dcto_cred decimal(4,2) not null ,
    r03_grupo_linea char(5) not null ,
    r03_usuario varchar(10,5) not null ,
    r03_fecing datetime year to second not null ,
    
    check (r03_estado IN ('A' ,'B' )),
    
    check (r03_area IN ('R' ,'T' )),
    
    check (r03_tipo IN ('N' ,'I' ))
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".te_rept003 from "public";

{ TABLE "fobos".te_rept073 row size = 65 number of columns = 5 index size = 0 }
create table "fobos".te_rept073 
  (
    t73_compania integer not null ,
    t73_marca char(6) not null ,
    t73_desc_marca varchar(35,20) not null ,
    t73_usuario varchar(10,5) not null ,
    t73_fecing datetime year to second not null 
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".te_rept073 from "public";

{ TABLE "fobos".te_rept011 row size = 79 number of columns = 15 index size = 0 }
create table "fobos".te_rept011 
  (
    t11_compania integer not null ,
    t11_bodega char(2) not null ,
    t11_item char(15) not null ,
    t11_ubicacion char(10) not null ,
    t11_ubica_ant char(10),
    t11_stock_ant smallint not null ,
    t11_stock_act smallint not null ,
    t11_ing_dia smallint not null ,
    t11_egr_dia smallint not null ,
    t11_fec_ultvta date,
    t11_tip_ultvta char(2),
    t11_num_ultvta decimal(15,0),
    t11_fec_ulting date,
    t11_tipo_ulting char(2),
    t11_num_ulting decimal(15,0)
  )  extent size 1030 next size 103 lock mode row;
revoke all on "fobos".te_rept011 from "public";

{ TABLE "fobos".te_ctas row size = 114 number of columns = 10 index size = 0 }
create table "fobos".te_ctas 
  (
    x10_cuenta char(12),
    x10_cuenta_10 char(12),
    x10_descripcion varchar(40,20),
    x10_descripcion_10 varchar(40,20),
    x10_tipo_cta char(1),
    x10_tipo_cta_10 char(1),
    x10_tipo_mov char(1),
    x10_tipo_mov_10 char(1),
    x10_nivel smallint,
    x10_nivel_10 smallint,
    
    check (x10_tipo_cta IN ('B' ,'R' )),
    
    check (x10_tipo_mov IN ('D' ,'C' ))
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".te_ctas from "public";

{ TABLE "fobos".rept079 row size = 52 number of columns = 6 index size = 84 }
create table "fobos".rept079 
  (
    r79_compania integer not null ,
    r79_localidad smallint not null ,
    r79_cod_tran char(2) not null ,
    r79_num_tran decimal(15,0) not null ,
    r79_item char(15) not null ,
    r79_serie char(20) not null ,
    primary key (r79_compania,r79_localidad,r79_cod_tran,r79_num_tran,r79_item,r79_serie) 
              
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".rept079 from "public";

{ TABLE "fobos".rept080 row size = 49 number of columns = 6 index size = 79 }
create table "fobos".rept080 
  (
    r80_compania integer not null ,
    r80_localidad smallint not null ,
    r80_num_ord_des integer not null ,
    r80_num_entrega integer not null ,
    r80_item char(15) not null ,
    r80_serie char(20) not null ,
    primary key (r80_compania,r80_localidad,r80_num_ord_des,r80_num_entrega,r80_item,r80_serie) 
              
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".rept080 from "public";

{ TABLE "fobos".te_ctbt010 row size = 58 number of columns = 6 index size = 0 }
create table "fobos".te_ctbt010 
  (
    t10_cuenta char(12) not null ,
    t10_descripcion varchar(40,20) not null ,
    t10_estado char(1) not null ,
    t10_tipo_cta char(1) not null ,
    t10_tipo_mov char(1) not null ,
    t10_nivel smallint not null ,
    
    check (t10_estado IN ('A' ,'B' )),
    
    check (t10_tipo_cta IN ('B' ,'R' )),
    
    check (t10_tipo_mov IN ('D' ,'C' ))
  )  extent size 23 next size 16 lock mode row;
revoke all on "fobos".te_ctbt010 from "public";

{ TABLE "fobos".te_cxpt020 row size = 164 number of columns = 26 index size = 49 
              }
create table "fobos".te_cxpt020 
  (
    p20_compania integer not null ,
    p20_localidad smallint not null ,
    p20_codprov integer not null ,
    p20_tipo_doc char(2) not null ,
    p20_num_doc char(15) not null ,
    p20_dividendo smallint not null ,
    p20_referencia varchar(35,20),
    p20_fecha_emi date not null ,
    p20_fecha_vcto date not null ,
    p20_tasa_int decimal(4,2) not null ,
    p20_tasa_mora decimal(4,2) not null ,
    p20_moneda char(2) not null ,
    p20_paridad decimal(16,9) not null ,
    p20_valor_cap decimal(12,2) not null ,
    p20_valor_int decimal(12,2) not null ,
    p20_saldo_cap decimal(12,2) not null ,
    p20_saldo_int decimal(12,2) not null ,
    p20_valor_fact decimal(12,2) not null ,
    p20_porc_impto decimal(4,2) not null ,
    p20_valor_impto decimal(11,2) not null ,
    p20_cartera smallint not null ,
    p20_numero_oc integer,
    p20_origen char(1) not null ,
    p20_cod_depto smallint not null ,
    p20_usuario varchar(10,5) not null ,
    p20_fecing datetime year to second not null ,
    
    check (p20_origen IN ('M' ,'A' ))
  )  extent size 153 next size 16 lock mode row;
revoke all on "fobos".te_cxpt020 from "public";

{ TABLE "fobos".rept077 row size = 52 number of columns = 11 index size = 54 }
create table "fobos".rept077 
  (
    r77_compania integer not null ,
    r77_codigo_util char(5) not null ,
    r77_multiplic integer not null ,
    r77_dscmax_ger decimal(4,2) not null ,
    r77_dscmax_jef decimal(4,2) not null ,
    r77_dscmax_ven decimal(4,2) not null ,
    r77_util_min decimal(5,2) not null ,
    r77_desc_promo decimal(4,2) not null ,
    r77_util_promo decimal(5,2) not null ,
    r77_usuario varchar(10,5) not null ,
    r77_fecing datetime year to second not null ,
    primary key (r77_compania,r77_codigo_util)  constraint "fobos".pk_rept077
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".rept077 from "public";

{ TABLE "fobos".rept038 row size = 42 number of columns = 7 index size = 72 }
create table "fobos".rept038 
  (
    r38_compania integer not null ,
    r38_localidad smallint not null ,
    r38_tipo_doc char(2) not null ,
    r38_tipo_fuente char(2) not null ,
    r38_cod_tran char(2) not null ,
    r38_num_tran decimal(15,0) not null ,
    r38_num_sri char(21) not null 
  )  extent size 492 next size 49 lock mode row;
revoke all on "fobos".rept038 from "public";

{ TABLE "fobos".te_rept077 row size = 52 number of columns = 11 index size = 19 }
create table "fobos".te_rept077 
  (
    r77_compania integer not null ,
    r77_codigo_util char(5) not null ,
    r77_multiplic integer not null ,
    r77_dscmax_ger decimal(4,2) not null ,
    r77_dscmax_jef decimal(4,2) not null ,
    r77_dscmax_ven decimal(4,2) not null ,
    r77_util_min decimal(5,2) not null ,
    r77_desc_promo decimal(4,2) not null ,
    r77_util_promo decimal(5,2) not null ,
    r77_usuario varchar(10,5) not null ,
    r77_fecing datetime year to second not null ,
    primary key (r77_compania,r77_codigo_util)  constraint "fobos".pk_te_rept077
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".te_rept077 from "public";

{ TABLE "fobos".te_r10 row size = 529 number of columns = 50 index size = 34 }
create table "fobos".te_r10 
  (
    te_compania integer not null ,
    te_codigo char(15) not null ,
    te_nombre varchar(70,20) not null ,
    te_estado char(1) not null ,
    te_tipo smallint not null ,
    te_peso decimal(7,3) not null ,
    te_uni_med char(7) not null ,
    te_cantpaq smallint not null ,
    te_cantveh smallint not null ,
    te_partida varchar(15,8) not null ,
    te_modelo varchar(20,5) not null ,
    te_cod_pedido char(15),
    te_cod_comerc char(15),
    te_cod_util char(5),
    te_linea char(5) not null ,
    te_sub_linea char(2) not null ,
    te_cod_grupo char(4) not null ,
    te_cod_clase char(8) not null ,
    te_marca char(6) not null ,
    te_rotacion char(2) not null ,
    te_paga_impto char(1) not null ,
    te_fob decimal(9,2) not null ,
    te_monfob char(2) not null ,
    te_precio_mb decimal(11,2) not null ,
    te_precio_ma decimal(11,2) not null ,
    te_costo_mb decimal(11,2) not null ,
    te_costo_ma decimal(11,2) not null ,
    te_costult_mb decimal(11,2) not null ,
    te_costult_ma decimal(11,2) not null ,
    te_costrepo_mb decimal(11,2),
    te_usu_cosrepo varchar(10,5),
    te_fec_cosrepo datetime year to second,
    te_cantped smallint not null ,
    te_cantback smallint not null ,
    te_comentarios varchar(120),
    te_precio_ant decimal(11,2) not null ,
    te_fec_camprec datetime year to second,
    te_proveedor integer,
    te_filtro char(10),
    te_electrico char(13),
    te_color char(10),
    te_serie char(20),
    te_stock_max integer,
    te_stock_min integer,
    te_vol_cuft decimal(5,2),
    te_dias_mant integer,
    te_dias_inv integer,
    te_usuario varchar(10,5) not null ,
    te_fecing datetime year to second not null ,
    te_feceli datetime year to second,
    
    check (te_estado IN ('A' ,'B' ,'S' )),
    
    check (te_paga_impto IN ('S' ,'N' ))
  )  extent size 11458 next size 1145 lock mode row;
revoke all on "fobos".te_r10 from "public";

{ TABLE "fobos".te_otros_r10 row size = 529 number of columns = 50 index size = 34 
              }
create table "fobos".te_otros_r10 
  (
    te_compania integer not null ,
    te_codigo char(15) not null ,
    te_nombre varchar(70,20) not null ,
    te_estado char(1) not null ,
    te_tipo smallint not null ,
    te_peso decimal(7,3) not null ,
    te_uni_med char(7) not null ,
    te_cantpaq smallint not null ,
    te_cantveh smallint not null ,
    te_partida varchar(15,8) not null ,
    te_modelo varchar(20,5) not null ,
    te_cod_pedido char(15),
    te_cod_comerc char(15),
    te_cod_util char(5),
    te_linea char(5) not null ,
    te_sub_linea char(2) not null ,
    te_cod_grupo char(4) not null ,
    te_cod_clase char(8) not null ,
    te_marca char(6) not null ,
    te_rotacion char(2) not null ,
    te_paga_impto char(1) not null ,
    te_fob decimal(9,2) not null ,
    te_monfob char(2) not null ,
    te_precio_mb decimal(11,2) not null ,
    te_precio_ma decimal(11,2) not null ,
    te_costo_mb decimal(11,2) not null ,
    te_costo_ma decimal(11,2) not null ,
    te_costult_mb decimal(11,2) not null ,
    te_costult_ma decimal(11,2) not null ,
    te_costrepo_mb decimal(11,2),
    te_usu_cosrepo varchar(10,5),
    te_fec_cosrepo datetime year to second,
    te_cantped smallint not null ,
    te_cantback smallint not null ,
    te_comentarios varchar(120),
    te_precio_ant decimal(11,2) not null ,
    te_fec_camprec datetime year to second,
    te_proveedor integer,
    te_filtro char(10),
    te_electrico char(13),
    te_color char(10),
    te_serie char(20),
    te_stock_max integer,
    te_stock_min integer,
    te_vol_cuft decimal(5,2),
    te_dias_mant integer,
    te_dias_inv integer,
    te_usuario varchar(10,5) not null ,
    te_fecing datetime year to second not null ,
    te_feceli datetime year to second,
    
    check (te_estado IN ('A' ,'B' ,'S' )),
    
    check (te_paga_impto IN ('S' ,'N' ))
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".te_otros_r10 from "public";

{ TABLE "fobos".te_precios row size = 27 number of columns = 3 index size = 28 }
create table "fobos".te_precios 
  (
    te_item char(15) not null ,
    te_precio decimal(12,2) not null ,
    te_cod_util char(5)
  )  extent size 1316 next size 131 lock mode row;
revoke all on "fobos".te_precios from "public";

{ TABLE "fobos".te_descrip row size = 95 number of columns = 2 index size = 28 }
create table "fobos".te_descrip 
  (
    te_codigo char(15),
    te_nombre char(80) not null 
  )  extent size 2503 next size 250 lock mode row;
revoke all on "fobos".te_descrip from "public";

{ TABLE "fobos".te_cli_cont row size = 4 number of columns = 1 index size = 0 }
create table "fobos".te_cli_cont 
  (
    te_codcli integer not null 
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".te_cli_cont from "public";

{ TABLE "fobos".te_cxct021 row size = 145 number of columns = 21 index size = 30 
              }
create table "fobos".te_cxct021 
  (
    z21_compania integer not null ,
    z21_localidad smallint not null ,
    z21_codcli integer not null ,
    z21_tipo_doc char(2) not null ,
    z21_num_doc integer not null ,
    z21_areaneg smallint not null ,
    z21_linea char(5) not null ,
    z21_referencia varchar(35,20),
    z21_fecha_emi date,
    z21_moneda char(2),
    z21_paridad decimal(16,9),
    z21_val_impto decimal(12,2),
    z21_valor decimal(12,2),
    z21_saldo decimal(12,2),
    z21_subtipo smallint,
    z21_origen char(1) not null ,
    z21_cod_tran char(2),
    z21_num_tran decimal(15,0),
    z21_num_sri char(16),
    z21_usuario varchar(10,5) not null ,
    z21_fecing datetime year to second not null ,
    
    check (z21_origen IN ('M' ,'A' ))
  )  extent size 27 next size 16 lock mode row;
revoke all on "fobos".te_cxct021 from "public";

{ TABLE "fobos".te_z01_bak row size = 258 number of columns = 20 index size = 0 }
create table "fobos".te_z01_bak 
  (
    z01_codcli integer not null ,
    z01_estado char(1) not null ,
    z01_nomcli varchar(40,20) not null ,
    z01_direccion1 varchar(40,20) not null ,
    z01_direccion2 varchar(40,20),
    z01_telefono1 char(10) not null ,
    z01_telefono2 char(10),
    z01_fax1 char(11),
    z01_fax2 char(11),
    z01_casilla char(10),
    z01_pais integer not null ,
    z01_ciudad integer not null ,
    z01_tipo_clte smallint not null ,
    z01_personeria char(1) not null ,
    z01_tipo_doc_id char(1) not null ,
    z01_num_doc_id char(15) not null ,
    z01_rep_legal varchar(30,15),
    z01_paga_impto char(1) not null ,
    z01_usuario varchar(10,5) not null ,
    z01_fecing datetime year to second not null ,
    
    check (z01_estado IN ('A' ,'B' )),
    
    check (z01_personeria IN ('N' ,'J' )),
    
    check (z01_tipo_doc_id IN ('C' ,'P' ,'R' )),
    
    check (z01_paga_impto IN ('S' ,'N' ))
  )  extent size 648 next size 64 lock mode row;
revoke all on "fobos".te_z01_bak from "public";

{ TABLE "fobos".te_otr10 row size = 528 number of columns = 50 index size = 34 }
create table "fobos".te_otr10 
  (
    te_compania integer not null ,
    te_codigo char(15) not null ,
    te_nombre varchar(70,20) not null ,
    te_estado char(1) not null ,
    te_tipo smallint not null ,
    te_peso decimal(7,3) not null ,
    te_uni_med char(7) not null ,
    te_cantpaq smallint not null ,
    te_cantveh smallint not null ,
    te_partida varchar(15,8) not null ,
    te_modelo varchar(20,5) not null ,
    te_cod_pedido char(15),
    te_cod_comerc char(15),
    te_cod_util char(4),
    te_linea char(5) not null ,
    te_sub_linea char(2) not null ,
    te_cod_grupo char(4) not null ,
    te_cod_clase char(8) not null ,
    te_marca char(6) not null ,
    te_rotacion char(2) not null ,
    te_paga_impto char(1) not null ,
    te_fob decimal(9,2) not null ,
    te_monfob char(2) not null ,
    te_precio_mb decimal(11,2) not null ,
    te_precio_ma decimal(11,2) not null ,
    te_costo_mb decimal(11,2) not null ,
    te_costo_ma decimal(11,2) not null ,
    te_costult_mb decimal(11,2) not null ,
    te_costult_ma decimal(11,2) not null ,
    te_costrepo_mb decimal(11,2),
    te_usu_cosrepo varchar(10,5),
    te_fec_cosrepo datetime year to second,
    te_cantped smallint not null ,
    te_cantback smallint not null ,
    te_comentarios varchar(120),
    te_precio_ant decimal(11,2) not null ,
    te_fec_camprec datetime year to second,
    te_proveedor integer,
    te_filtro char(10),
    te_electrico char(13),
    te_color char(10),
    te_serie char(20),
    te_stock_max integer,
    te_stock_min integer,
    te_vol_cuft decimal(5,2),
    te_dias_mant integer,
    te_dias_inv integer,
    te_usuario varchar(10,5) not null ,
    te_fecing datetime year to second not null ,
    te_feceli datetime year to second,
    
    check (te_estado IN ('A' ,'B' ,'S' )),
    
    check (te_paga_impto IN ('S' ,'N' ))
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".te_otr10 from "public";

{ TABLE "fobos".te_electrico row size = 53 number of columns = 2 index size = 0 }
create table "fobos".te_electrico 
  (
    te_codigo char(13) not null ,
    te_descripcion char(40) not null 
  )  extent size 50 next size 16 lock mode row;
revoke all on "fobos".te_electrico from "public";

{ TABLE "fobos".rept072 row size = 93 number of columns = 8 index size = 91 }
create table "fobos".rept072 
  (
    r72_compania integer not null ,
    r72_linea char(5) not null ,
    r72_sub_linea char(2) not null ,
    r72_cod_grupo char(4) not null ,
    r72_cod_clase char(8) not null ,
    r72_desc_clase varchar(50,20) not null ,
    r72_usuario varchar(10,5) not null ,
    r72_fecing datetime year to second not null ,
    primary key (r72_compania,r72_linea,r72_sub_linea,r72_cod_grupo,r72_cod_clase) 
               constraint "fobos".pk_rept072
  )  extent size 540 next size 54 lock mode row;
revoke all on "fobos".rept072 from "public";

{ TABLE "fobos".rept071 row size = 75 number of columns = 7 index size = 73 }
create table "fobos".rept071 
  (
    r71_compania integer not null ,
    r71_linea char(5) not null ,
    r71_sub_linea char(2) not null ,
    r71_cod_grupo char(4) not null ,
    r71_desc_grupo varchar(40,20) not null ,
    r71_usuario varchar(10,5) not null ,
    r71_fecing datetime year to second not null ,
    primary key (r71_compania,r71_linea,r71_sub_linea,r71_cod_grupo)  constraint 
              "fobos".pk_rept071
  )  extent size 27 next size 16 lock mode row;
revoke all on "fobos".rept071 from "public";

{ TABLE "fobos".te_rept072 row size = 93 number of columns = 8 index size = 0 }
create table "fobos".te_rept072 
  (
    te_compania integer not null ,
    te_linea char(5) not null ,
    te_sub_linea char(2) not null ,
    te_cod_grupo char(4) not null ,
    te_cod_clase char(8) not null ,
    te_desc_clase varchar(50,20) not null ,
    te_usuario varchar(10,5) not null ,
    te_fecing datetime year to second not null 
  )  extent size 259 next size 25 lock mode row;
revoke all on "fobos".te_rept072 from "public";

{ TABLE "fobos".tr_items_qto row size = 515 number of columns = 50 index size = 34 
              }
create table "fobos".tr_items_qto 
  (
    r10_compania integer not null ,
    r10_codigo char(15) not null ,
    r10_nombre varchar(70,20) not null ,
    r10_estado char(1) not null ,
    r10_tipo smallint not null ,
    r10_peso decimal(7,3) not null ,
    r10_uni_med char(7) not null ,
    r10_cantpaq smallint not null ,
    r10_cantveh smallint not null ,
    r10_partida varchar(15,8) not null ,
    r10_modelo varchar(20,5) not null ,
    r10_cod_pedido char(20),
    r10_cod_comerc char(15),
    r10_cod_util char(5) not null ,
    r10_linea char(5) not null ,
    r10_sub_linea char(2) not null ,
    r10_cod_grupo char(4) not null ,
    r10_cod_clase char(8) not null ,
    r10_marca char(6) not null ,
    r10_rotacion char(2) not null ,
    r10_paga_impto char(1) not null ,
    r10_fob decimal(9,2) not null ,
    r10_monfob char(2) not null ,
    r10_precio_mb decimal(11,2) not null ,
    r10_precio_ma decimal(11,2) not null ,
    r10_costo_mb decimal(11,2) not null ,
    r10_costo_ma decimal(11,2) not null ,
    r10_costult_mb decimal(11,2) not null ,
    r10_costult_ma decimal(11,2) not null ,
    r10_costrepo_mb decimal(11,2),
    r10_usu_cosrepo varchar(10,5),
    r10_fec_cosrepo datetime year to second,
    r10_cantped smallint not null ,
    r10_cantback smallint not null ,
    r10_comentarios varchar(120),
    r10_precio_ant decimal(11,2) not null ,
    r10_fec_camprec datetime year to second,
    r10_proveedor integer,
    r10_filtro char(10),
    r10_electrico char(13),
    r10_color char(10),
    r10_serie_lote char(1),
    r10_stock_max integer,
    r10_stock_min integer,
    r10_vol_cuft decimal(5,2),
    r10_dias_mant integer,
    r10_dias_inv integer,
    r10_usuario varchar(10,5) not null ,
    r10_fecing datetime year to second not null ,
    r10_feceli datetime year to second,
    
    check (r10_estado IN ('A' ,'B' ,'S' )),
    
    check (r10_paga_impto IN ('S' ,'N' )),
    
    check (r10_serie_lote IN ('S' ,'L' ,'G' ))
  )  extent size 8912 next size 891 lock mode row;
revoke all on "fobos".tr_items_qto from "public";

{ TABLE "fobos".tr_stock_qto row size = 22 number of columns = 3 index size = 0 }
create table "fobos".tr_stock_qto 
  (
    te_bodega char(2) not null ,
    te_item char(15) not null ,
    te_stock decimal(8,2) not null 
  )  extent size 547 next size 54 lock mode row;
revoke all on "fobos".tr_stock_qto from "public";

{ TABLE "fobos".tr_cxct002 row size = 291 number of columns = 25 index size = 21 
              }
create table "fobos".tr_cxct002 
  (
    z02_compania integer not null ,
    z02_localidad smallint not null ,
    z02_codcli integer not null ,
    z02_contacto varchar(30,15),
    z02_referencia varchar(40,20),
    z02_credit_auto char(1) not null ,
    z02_credit_dias smallint not null ,
    z02_cupocred_mb decimal(12,2) not null ,
    z02_cupocred_ma decimal(12,2) not null ,
    z02_dcto_item_c decimal(4,2) not null ,
    z02_dcto_item_r decimal(4,2) not null ,
    z02_dcto_mano_c decimal(4,2) not null ,
    z02_dcto_mano_r decimal(4,2) not null ,
    z02_cheques char(1) not null ,
    z02_zona_venta smallint,
    z02_zona_cobro smallint,
    z02_aux_clte_mb char(12),
    z02_aux_clte_ma char(12),
    z02_aux_ant_mb char(12),
    z02_aux_ant_ma char(12),
    z02_contr_espe char(5),
    z02_oblig_cont char(2),
    z02_email varchar(100),
    z02_usuario varchar(10,5) not null ,
    z02_fecing datetime year to second not null ,
    
    check (z02_credit_auto IN ('S' ,'N' )),
    
    check (z02_cheques IN ('S' ,'N' )),
    
    check (z02_oblig_cont IN ('SI' ,'NO' ,NULL )) constraint "fobos".ck_03_tr_cxct002
  )  extent size 30 next size 16 lock mode row;
revoke all on "fobos".tr_cxct002 from "public";

{ TABLE "fobos".tr_cxct020 row size = 184 number of columns = 28 index size = 49 
              }
create table "fobos".tr_cxct020 
  (
    z20_compania integer not null ,
    z20_localidad smallint not null ,
    z20_codcli integer not null ,
    z20_tipo_doc char(2) not null ,
    z20_num_doc char(15) not null ,
    z20_dividendo smallint not null ,
    z20_areaneg smallint not null ,
    z20_referencia varchar(35,20),
    z20_fecha_emi date not null ,
    z20_fecha_vcto date not null ,
    z20_tasa_int decimal(4,2) not null ,
    z20_tasa_mora decimal(4,2) not null ,
    z20_moneda char(2) not null ,
    z20_paridad decimal(16,9) not null ,
    z20_val_impto decimal(11,2) not null ,
    z20_valor_cap decimal(12,2) not null ,
    z20_valor_int decimal(12,2) not null ,
    z20_saldo_cap decimal(12,2) not null ,
    z20_saldo_int decimal(12,2) not null ,
    z20_cartera smallint not null ,
    z20_linea char(5) not null ,
    z20_subtipo smallint,
    z20_origen char(1) not null ,
    z20_cod_tran char(2),
    z20_num_tran decimal(15,0),
    z20_num_sri char(16),
    z20_usuario varchar(10,5) not null ,
    z20_fecing datetime year to second not null ,
    
    check (z20_origen IN ('M' ,'A' ))
  )  extent size 27 next size 16 lock mode row;
revoke all on "fobos".tr_cxct020 from "public";

{ TABLE "fobos".ordt011 row size = 123 number of columns = 14 index size = 45 }
create table "fobos".ordt011 
  (
    c11_compania integer not null ,
    c11_localidad smallint not null ,
    c11_numero_oc integer not null ,
    c11_secuencia smallint not null ,
    c11_tipo char(1) not null ,
    c11_cant_ped decimal(8,2) not null ,
    c11_cant_rec decimal(8,2) not null ,
    c11_codigo char(15) not null ,
    c11_descrip varchar(60,30) not null ,
    c11_descuento decimal(4,2) not null ,
    c11_paga_iva char(1) not null ,
    c11_val_descto decimal(10,2) not null ,
    c11_val_impto decimal(10,2) not null ,
    c11_precio decimal(13,4) not null ,
    
    check (c11_tipo IN ('B' ,'S' )),
    
    check (c11_paga_iva IN ('S' ,'N' ))
  )  extent size 448 next size 44 lock mode row;
revoke all on "fobos".ordt011 from "public";

{ TABLE "fobos".ordt014 row size = 119 number of columns = 13 index size = 51 }
create table "fobos".ordt014 
  (
    c14_compania integer not null ,
    c14_localidad smallint not null ,
    c14_numero_oc integer not null ,
    c14_num_recep smallint not null ,
    c14_secuencia smallint not null ,
    c14_codigo char(15) not null ,
    c14_cantidad decimal(8,2) not null ,
    c14_descrip varchar(60,30) not null ,
    c14_descuento decimal(4,2) not null ,
    c14_paga_iva char(1) not null ,
    c14_val_descto decimal(10,2) not null ,
    c14_val_impto decimal(10,2) not null ,
    c14_precio decimal(13,4) not null ,
    
    check (c14_paga_iva IN ('S' ,'N' ))
  )  extent size 429 next size 42 lock mode row;
revoke all on "fobos".ordt014 from "public";

{ TABLE "fobos".tr_items row size = 582 number of columns = 51 index size = 34 }
create table "fobos".tr_items 
  (
    r10_compania integer not null ,
    r10_codigo char(15) not null ,
    r10_nombre varchar(70,20) not null ,
    r10_estado char(1) not null ,
    r10_tipo smallint not null ,
    r10_peso decimal(7,3) not null ,
    r10_uni_med char(7) not null ,
    r10_cantpaq decimal(8,2) not null ,
    r10_cantveh decimal(8,2) not null ,
    r10_partida varchar(15,8) not null ,
    r10_modelo varchar(20,5) not null ,
    r10_cod_pedido char(20),
    r10_cod_comerc char(60),
    r10_cod_util char(5) not null ,
    r10_linea char(5) not null ,
    r10_sub_linea char(2) not null ,
    r10_cod_grupo char(4) not null ,
    r10_cod_clase char(8) not null ,
    r10_marca char(6) not null ,
    r10_rotacion char(2) not null ,
    r10_paga_impto char(1) not null ,
    r10_fob decimal(13,4) not null ,
    r10_monfob char(2) not null ,
    r10_precio_mb decimal(11,2) not null ,
    r10_precio_ma decimal(11,2) not null ,
    r10_costo_mb decimal(11,2) not null ,
    r10_costo_ma decimal(11,2) not null ,
    r10_costult_mb decimal(11,2) not null ,
    r10_costult_ma decimal(11,2) not null ,
    r10_costrepo_mb decimal(11,2),
    r10_usu_cosrepo varchar(10,5),
    r10_fec_cosrepo datetime year to second,
    r10_cantped decimal(11,2) not null ,
    r10_cantback decimal(11,2) not null ,
    r10_comentarios varchar(120),
    r10_precio_ant decimal(11,2) not null ,
    r10_fec_camprec datetime year to second,
    r10_proveedor integer,
    r10_filtro char(10),
    r10_electrico char(13),
    r10_color char(10),
    r10_serie_lote char(1),
    r10_stock_max integer,
    r10_stock_min integer,
    r10_vol_cuft decimal(5,2),
    r10_dias_mant integer,
    r10_dias_inv integer,
    r10_sec_item integer not null ,
    r10_usuario varchar(10,5) not null ,
    r10_fecing datetime year to second not null ,
    r10_feceli datetime year to second,
    
    check (r10_estado IN ('A' ,'B' ,'S' )),
    
    check (r10_paga_impto IN ('S' ,'N' )),
    
    check (r10_serie_lote IN ('S' ,'L' ,'G' ))
  )  extent size 368 next size 36 lock mode row;
revoke all on "fobos".tr_items from "public";

{ TABLE "fobos".tr_stock row size = 22 number of columns = 3 index size = 31 }
create table "fobos".tr_stock 
  (
    te_bodega char(2) not null ,
    te_item char(15) not null ,
    te_stock decimal(8,2) not null 
  )  extent size 286 next size 28 lock mode row;
revoke all on "fobos".tr_stock from "public";

{ TABLE "fobos".rept017 row size = 239 number of columns = 30 index size = 181 }
create table "fobos".rept017 
  (
    r17_compania integer not null ,
    r17_localidad smallint not null ,
    r17_pedido char(10) not null ,
    r17_item char(15) not null ,
    r17_orden smallint not null ,
    r17_estado char(1) not null ,
    r17_fob decimal(13,4) not null ,
    r17_cantped decimal(8,2) not null ,
    r17_cantrec decimal(8,2) not null ,
    r17_exfab_mb decimal(22,10) not null ,
    r17_desp_mi decimal(22,10) not null ,
    r17_desp_mb decimal(22,10) not null ,
    r17_tot_fob_mi decimal(22,10) not null ,
    r17_tot_fob_mb decimal(22,10) not null ,
    r17_flete decimal(22,10) not null ,
    r17_seguro decimal(22,10) not null ,
    r17_cif decimal(22,10) not null ,
    r17_arancel decimal(22,10) not null ,
    r17_salvagu decimal(22,10) not null ,
    r17_cargos decimal(22,10) not null ,
    r17_costuni_ing decimal(22,10) not null ,
    r17_ind_bko char(1) not null ,
    r17_linea char(5) not null ,
    r17_rotacion char(2) not null ,
    r17_partida varchar(15,8) not null ,
    r17_porc_part decimal(5,2) not null ,
    r17_porc_salva decimal(5,2) not null ,
    r17_vol_cuft decimal(5,2),
    r17_peso decimal(7,3) not null ,
    r17_cantpaq smallint not null ,
    
    check (r17_estado IN ('A' ,'C' ,'R' ,'L' ,'P' )),
    
    check (r17_ind_bko IN ('S' ,'N' ))
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".rept017 from "public";

{ TABLE "fobos".rept028 row size = 412 number of columns = 38 index size = 94 }
create table "fobos".rept028 
  (
    r28_compania integer not null ,
    r28_localidad smallint not null ,
    r28_numliq integer not null ,
    r28_estado char(1) not null ,
    r28_codprov integer not null ,
    r28_bodega char(2) not null ,
    r28_descripcion varchar(30,15) not null ,
    r28_origen char(15) not null ,
    r28_forma_pago varchar(30,15) not null ,
    r28_num_pi char(15),
    r28_guia char(15),
    r28_pedimento char(10),
    r28_fecha_lleg date not null ,
    r28_fecha_ing date not null ,
    r28_moneda char(2) not null ,
    r28_paridad decimal(22,15) not null ,
    r28_flag_flete char(1) not null ,
    r28_tot_exfab_mi decimal(22,10) not null ,
    r28_tot_exfab_mb decimal(22,10) not null ,
    r28_tot_desp_mi decimal(22,10) not null ,
    r28_tot_desp_mb decimal(22,10) not null ,
    r28_tot_fob_mi decimal(22,10) not null ,
    r28_tot_fob_mb decimal(22,10) not null ,
    r28_tot_flete decimal(22,10) not null ,
    r28_tot_flet_cae decimal(22,10) not null ,
    r28_tot_seguro decimal(22,10) not null ,
    r28_tot_seg_neto decimal(22,10) not null ,
    r28_tot_cif decimal(22,10) not null ,
    r28_tot_arancel decimal(22,10) not null ,
    r28_tot_salvagu decimal(22,10) not null ,
    r28_tot_iva decimal(22,10) not null ,
    r28_tot_cargos decimal(22,10) not null ,
    r28_tot_costimp decimal(22,10) not null ,
    r28_fact_costo decimal(12,6) not null ,
    r28_margen_uti decimal(8,2) not null ,
    r28_elaborado varchar(30,15) not null ,
    r28_usuario varchar(10,5) not null ,
    r28_fecing datetime year to second not null ,
    
    check (r28_estado IN ('A' ,'B' ,'P' )),
    
    check (r28_flag_flete IN ('F' ,'P' ))
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".rept028 from "public";

{ TABLE "fobos".te_cod_kh row size = 528 number of columns = 50 index size = 34 }
create table "fobos".te_cod_kh 
  (
    te_compania integer not null ,
    te_codigo char(15) not null ,
    te_nombre varchar(70,20) not null ,
    te_estado char(1) not null ,
    te_tipo smallint not null ,
    te_peso decimal(7,3) not null ,
    te_uni_med char(7) not null ,
    te_cantpaq smallint not null ,
    te_cantveh smallint not null ,
    te_partida varchar(15,8),
    te_modelo varchar(20,5) not null ,
    te_cod_pedido char(15),
    te_cod_comerc char(15),
    te_cod_util char(4),
    te_linea char(5) not null ,
    te_sub_linea char(2) not null ,
    te_cod_grupo char(4) not null ,
    te_cod_clase char(8) not null ,
    te_marca char(6) not null ,
    te_rotacion char(2) not null ,
    te_paga_impto char(1) not null ,
    te_fob decimal(9,2) not null ,
    te_monfob char(2) not null ,
    te_precio_mb decimal(11,2) not null ,
    te_precio_ma decimal(11,2) not null ,
    te_costo_mb decimal(11,2) not null ,
    te_costo_ma decimal(11,2) not null ,
    te_costult_mb decimal(11,2) not null ,
    te_costult_ma decimal(11,2) not null ,
    te_costrepo_mb decimal(11,2),
    te_usu_cosrepo varchar(10,5),
    te_fec_cosrepo datetime year to second,
    te_cantped smallint not null ,
    te_cantback smallint not null ,
    te_comentarios varchar(120),
    te_precio_ant decimal(11,2) not null ,
    te_fec_camprec datetime year to second,
    te_proveedor integer,
    te_filtro char(10),
    te_electrico char(13),
    te_color char(10),
    te_serie char(20),
    te_stock_max integer,
    te_stock_min integer,
    te_vol_cuft decimal(5,2),
    te_dias_mant integer,
    te_dias_inv integer,
    te_usuario varchar(10,5) not null ,
    te_fecing datetime year to second not null ,
    te_feceli datetime year to second,
    
    check (te_estado IN ('A' ,'B' ,'S' )),
    
    check (te_paga_impto IN ('S' ,'N' ))
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".te_cod_kh from "public";

{ TABLE "fobos".ctbt012 row size = 253 number of columns = 19 index size = 144 }
create table "fobos".ctbt012 
  (
    b12_compania integer not null ,
    b12_tipo_comp char(2) not null ,
    b12_num_comp char(8) not null ,
    b12_estado char(1) not null ,
    b12_subtipo smallint,
    b12_glosa varchar(130,60) not null ,
    b12_benef_che varchar(40),
    b12_num_cheque integer,
    b12_origen char(1) not null ,
    b12_moneda char(2) not null ,
    b12_paridad decimal(16,9) not null ,
    b12_fec_proceso date not null ,
    b12_fec_reversa date,
    b12_tip_reversa char(2),
    b12_num_reversa char(8),
    b12_fec_modifi datetime year to second,
    b12_modulo char(2),
    b12_usuario varchar(10,5) not null ,
    b12_fecing datetime year to second not null ,
    
    check (b12_estado IN ('A' ,'M' ,'E' )),
    
    check (b12_origen IN ('A' ,'M' ))
  )  extent size 12651 next size 1265 lock mode row;
revoke all on "fobos".ctbt012 from "public";

{ TABLE "fobos".gent037 row size = 66 number of columns = 14 index size = 88 }
create table "fobos".gent037 
  (
    g37_compania integer not null ,
    g37_localidad smallint not null ,
    g37_tipo_doc char(2) not null ,
    g37_secuencia smallint not null ,
    g37_pref_sucurs char(3) not null ,
    g37_pref_pto_vta char(3) not null ,
    g37_sec_num_sri integer not null ,
    g37_cont_cred char(1) not null ,
    g37_num_dig_sri smallint not null ,
    g37_fecha_emi date not null ,
    g37_fecha_exp date not null ,
    g37_autorizacion varchar(15,10) not null ,
    g37_usuario varchar(10,5) not null ,
    g37_fecing datetime year to second not null ,
    
    check (g37_cont_cred IN ('C' ,'R' ,'N' ))
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".gent037 from "public";

{ TABLE "fobos".tr_cxct021 row size = 145 number of columns = 21 index size = 30 
              }
create table "fobos".tr_cxct021 
  (
    z21_compania integer not null ,
    z21_localidad smallint not null ,
    z21_codcli integer not null ,
    z21_tipo_doc char(2) not null ,
    z21_num_doc integer not null ,
    z21_areaneg smallint not null ,
    z21_linea char(5) not null ,
    z21_referencia varchar(35,20),
    z21_fecha_emi date not null ,
    z21_moneda char(2) not null ,
    z21_paridad decimal(16,9) not null ,
    z21_val_impto decimal(12,2) not null ,
    z21_valor decimal(12,2) not null ,
    z21_saldo decimal(12,2) not null ,
    z21_subtipo smallint not null ,
    z21_origen char(1) not null ,
    z21_cod_tran char(2),
    z21_num_tran decimal(15,0),
    z21_num_sri char(16),
    z21_usuario varchar(10,5) not null ,
    z21_fecing datetime year to second not null ,
    
    check (z21_origen IN ('M' ,'A' ))
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".tr_cxct021 from "public";

{ TABLE "fobos".tr_cxct022 row size = 134 number of columns = 23 index size = 39 
              }
create table "fobos".tr_cxct022 
  (
    z22_compania integer not null ,
    z22_localidad smallint not null ,
    z22_codcli integer not null ,
    z22_tipo_trn char(2) not null ,
    z22_num_trn integer not null ,
    z22_areaneg smallint not null ,
    z22_referencia varchar(35,20),
    z22_fecha_emi date not null ,
    z22_moneda char(2) not null ,
    z22_paridad decimal(16,9) not null ,
    z22_tasa_mora decimal(4,2) not null ,
    z22_total_cap decimal(12,2) not null ,
    z22_total_int decimal(12,2) not null ,
    z22_total_mora decimal(12,2) not null ,
    z22_cobrador smallint,
    z22_zona_cobro smallint,
    z22_subtipo smallint,
    z22_origen char(1) not null ,
    z22_fecha_elim datetime year to second,
    z22_tiptrn_elim char(2),
    z22_numtrn_elim integer,
    z22_usuario varchar(10,5) not null ,
    z22_fecing datetime year to second not null ,
    
    check (z22_origen IN ('M' ,'A' ))
  )  extent size 20 next size 16 lock mode row;
revoke all on "fobos".tr_cxct022 from "public";

{ TABLE "fobos".tr_cxct023 row size = 82 number of columns = 17 index size = 36 }
create table "fobos".tr_cxct023 
  (
    z23_compania integer not null ,
    z23_localidad smallint not null ,
    z23_codcli integer not null ,
    z23_tipo_trn char(2) not null ,
    z23_num_trn integer not null ,
    z23_orden integer not null ,
    z23_areaneg smallint not null ,
    z23_tipo_doc char(2) not null ,
    z23_num_doc char(15) not null ,
    z23_div_doc smallint not null ,
    z23_tipo_favor char(2),
    z23_doc_favor integer,
    z23_valor_cap decimal(12,2) not null ,
    z23_valor_int decimal(12,2) not null ,
    z23_valor_mora decimal(11,2) not null ,
    z23_saldo_cap decimal(12,2) not null ,
    z23_saldo_int decimal(12,2) not null 
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".tr_cxct023 from "public";

{ TABLE "fobos".te_021_07052003 row size = 145 number of columns = 21 index size 
              = 126 }
create table "fobos".te_021_07052003 
  (
    z21_compania integer not null ,
    z21_localidad smallint not null ,
    z21_codcli integer not null ,
    z21_tipo_doc char(2) not null ,
    z21_num_doc integer not null ,
    z21_areaneg smallint not null ,
    z21_linea char(5) not null ,
    z21_referencia varchar(35,20),
    z21_fecha_emi date not null ,
    z21_moneda char(2) not null ,
    z21_paridad decimal(16,9) not null ,
    z21_val_impto decimal(12,2) not null ,
    z21_valor decimal(12,2) not null ,
    z21_saldo decimal(12,2) not null ,
    z21_subtipo smallint not null ,
    z21_origen char(1) not null ,
    z21_cod_tran char(2),
    z21_num_tran decimal(15,0),
    z21_num_sri char(16),
    z21_usuario varchar(10,5) not null ,
    z21_fecing datetime year to second not null ,
    
    check (z21_origen IN ('M' ,'A' ))
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".te_021_07052003 from "public";

{ TABLE "fobos".te_gent016 row size = 723 number of columns = 7 index size = 52 }
create table "fobos".te_gent016 
  (
    g16_partida varchar(15,8) not null ,
    g16_nombre char(600) not null ,
    g16_porcentaje decimal(5,2) not null ,
    g16_salvagu decimal(5,2) not null ,
    g16_subtitulo char(80),
    g16_usuario varchar(10,5) not null ,
    g16_fecing datetime year to second not null 
  )  extent size 5116 next size 511 lock mode row;
revoke all on "fobos".te_gent016 from "public";

{ TABLE "fobos".tr_precios_qto row size = 30 number of columns = 4 index size = 72 
              }
create table "fobos".tr_precios_qto 
  (
    te_compania smallint not null ,
    te_item char(15) not null ,
    te_precio decimal(12,2) not null ,
    te_marca char(6) not null 
  )  extent size 1787 next size 178 lock mode row;
revoke all on "fobos".tr_precios_qto from "public";

{ TABLE "fobos".npc row size = 22 number of columns = 2 index size = 0 }
create table "fobos".npc 
  (
    te_item char(15) not null ,
    te_precio decimal(12,2) not null 
  )  extent size 458 next size 45 lock mode row;
revoke all on "fobos".npc from "public";

{ TABLE "fobos".gent056 row size = 16 number of columns = 3 index size = 0 }
create table "fobos".gent056 
  (
    g56_compania integer not null ,
    g56_localidad smallint not null ,
    g56_base_datos char(10) not null 
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".gent056 from "public";

{ TABLE "fobos".tr_grupos row size = 75 number of columns = 7 index size = 0 }
create table "fobos".tr_grupos 
  (
    r71_compania integer not null ,
    r71_linea char(5) not null ,
    r71_sub_linea char(2) not null ,
    r71_cod_grupo char(4) not null ,
    r71_desc_grupo varchar(40,20) not null ,
    r71_usuario varchar(10,5) not null ,
    r71_fecing datetime year to second not null 
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".tr_grupos from "public";

{ TABLE "fobos".tr_marcas row size = 65 number of columns = 5 index size = 0 }
create table "fobos".tr_marcas 
  (
    r73_compania integer not null ,
    r73_marca char(6) not null ,
    r73_desc_marca varchar(35,20) not null ,
    r73_usuario varchar(10,5) not null ,
    r73_fecing datetime year to second not null 
  )  extent size 18 next size 16 lock mode row;
revoke all on "fobos".tr_marcas from "public";

{ TABLE "fobos".tr_clases row size = 93 number of columns = 8 index size = 0 }
create table "fobos".tr_clases 
  (
    r72_compania integer not null ,
    r72_linea char(5) not null ,
    r72_sub_linea char(2) not null ,
    r72_cod_grupo char(4) not null ,
    r72_cod_clase char(8) not null ,
    r72_desc_clase varchar(50,20) not null ,
    r72_usuario varchar(10,5) not null ,
    r72_fecing datetime year to second not null 
  )  extent size 273 next size 27 lock mode row;
revoke all on "fobos".tr_clases from "public";

{ TABLE "fobos".gent038 row size = 246 number of columns = 4 index size = 31 }
create table "fobos".gent038 
  (
    g38_capitulo char(2) not null ,
    g38_desc_cap char(225) not null ,
    g38_usuario varchar(10,5) not null ,
    g38_fecing datetime year to second not null 
  )  extent size 26 next size 16 lock mode row;
revoke all on "fobos".gent038 from "public";

{ TABLE "fobos".gent016 row size = 276 number of columns = 10 index size = 61 }
create table "fobos".gent016 
  (
    g16_capitulo char(2) not null ,
    g16_partida varchar(15,4) not null ,
    g16_desc_par char(225) not null ,
    g16_niv_par char(2),
    g16_nacional char(2),
    g16_verifcador char(2),
    g16_porcentaje decimal(5,2) not null ,
    g16_salvagu decimal(5,2) not null ,
    g16_usuario varchar(10,5) not null ,
    g16_fecing datetime year to second not null 
  )  extent size 3253 next size 325 lock mode row;
revoke all on "fobos".gent016 from "public";

{ TABLE "fobos".te_actt010 row size = 212 number of columns = 30 index size = 193 
              }
create table "fobos".te_actt010 
  (
    a10_compania integer not null ,
    a10_codigo_bien integer not null ,
    a10_estado char(1) not null ,
    a10_descripcion varchar(40,20) not null ,
    a10_grupo_act smallint not null ,
    a10_tipo_act smallint not null ,
    a10_anos_util smallint not null ,
    a10_porc_deprec decimal(4,2) not null ,
    a10_modelo varchar(15),
    a10_serie varchar(25),
    a10_locali_ori smallint not null ,
    a10_numero_oc integer,
    a10_localidad smallint not null ,
    a10_cod_depto smallint not null ,
    a10_codprov integer not null ,
    a10_fecha_comp date not null ,
    a10_moneda char(2) not null ,
    a10_paridad decimal(16,9) not null ,
    a10_valor decimal(12,2) not null ,
    a10_valor_mb decimal(12,2) not null ,
    a10_responsable smallint,
    a10_fecha_baja date,
    a10_val_dep_mb decimal(11,2) not null ,
    a10_val_dep_ma decimal(11,2) not null ,
    a10_tot_dep_mb decimal(12,2) not null ,
    a10_tot_dep_ma decimal(12,2) not null ,
    a10_tot_reexpr decimal(12,2) not null ,
    a10_tot_dep_ree decimal(12,2) not null ,
    a10_usuario varchar(10,5) not null ,
    a10_fecing datetime year to second not null ,
    
    check (a10_estado IN ('A' ,'B' ,'V' ,'D' ,'S' ,'E' ))
  )  extent size 82 next size 16 lock mode row;
revoke all on "fobos".te_actt010 from "public";

{ TABLE "fobos".cxct041 row size = 41 number of columns = 8 index size = 67 }
create table "fobos".cxct041 
  (
    z41_compania integer not null ,
    z41_localidad smallint not null ,
    z41_codcli integer not null ,
    z41_tipo_doc char(2) not null ,
    z41_num_doc char(15) not null ,
    z41_dividendo integer not null ,
    z41_tipo_comp char(2) not null ,
    z41_num_comp char(8) not null 
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".cxct041 from "public";

{ TABLE "fobos".cxpt040 row size = 26 number of columns = 7 index size = 45 }
create table "fobos".cxpt040 
  (
    p40_compania integer not null ,
    p40_localidad smallint not null ,
    p40_codprov integer not null ,
    p40_tipo_doc char(2) not null ,
    p40_num_doc integer not null ,
    p40_tipo_comp char(2) not null ,
    p40_num_comp char(8) not null 
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".cxpt040 from "public";

{ TABLE "fobos".cxpt041 row size = 47 number of columns = 8 index size = 138 }
create table "fobos".cxpt041 
  (
    p41_compania integer not null ,
    p41_localidad smallint not null ,
    p41_codprov integer not null ,
    p41_tipo_doc char(2) not null ,
    p41_num_doc char(21) not null ,
    p41_dividendo integer not null ,
    p41_tipo_comp char(2) not null ,
    p41_num_comp char(8) not null 
  )  extent size 37 next size 16 lock mode row;
revoke all on "fobos".cxpt041 from "public";

{ TABLE "fobos".vb_uso row size = 4 number of columns = 1 index size = 0 }
create table "fobos".vb_uso 
  (
    contador integer
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".vb_uso from "public";

{ TABLE "fobos".vb_marcas row size = 6 number of columns = 1 index size = 0 }
create table "fobos".vb_marcas 
  (
    marca char(6) not null 
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".vb_marcas from "public";

{ TABLE "fobos".vb_1 row size = 309 number of columns = 23 index size = 222 }
create table "fobos".vb_1 
  (
    local smallint,
    fecha date,
    codcli integer,
    ncliente char(50),
    codven smallint,
    iniciales char(5),
    nvendedor char(30),
    cod_tran char(2),
    num_tran integer,
    item char(15),
    nitem char(60),
    marca char(6),
    division char(1),
    linea char(2),
    grupo char(3),
    clase char(8),
    nclase char(60),
    tipo char(1),
    cantidad decimal(16),
    precio decimal(16),
    descuento decimal(16),
    tdescuento decimal(16),
    subtotal decimal(16)
  )  extent size 4059 next size 405 lock mode row;
revoke all on "fobos".vb_1 from "public";

{ TABLE "fobos".vb_proformas row size = 285 number of columns = 21 index size = 222 
              }
create table "fobos".vb_proformas 
  (
    local smallint,
    fecha date,
    codcli integer,
    ncliente char(50),
    codven smallint,
    iniciales char(5),
    nvendedor char(30),
    proforma integer,
    item char(15),
    nitem char(60),
    marca char(6),
    division char(1),
    linea char(2),
    grupo char(3),
    clase char(8),
    nclase char(60),
    tipo char(1),
    cantidad decimal(12,2),
    precio decimal(12,2),
    descuento decimal(12,2),
    subtotal decimal(12,2)
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".vb_proformas from "public";

{ TABLE "fobos".repro_010 row size = 103 number of columns = 14 index size = 34 }
create table "fobos".repro_010 
  (
    r10_compania integer not null ,
    r10_codigo char(15) not null ,
    r10_costo_ini decimal(11,2) not null ,
    r10_costo_fin decimal(11,2) not null ,
    r10_costult_fin decimal(11,2) not null ,
    r10_costo_mb decimal(11,2) not null ,
    r10_costult_mb decimal(11,2) not null ,
    r10_costo_01 decimal(11,2) not null ,
    r10_costo_02 decimal(11,2) not null ,
    r10_costo_03 decimal(11,2) not null ,
    r10_costo_04 decimal(11,2) not null ,
    r10_costo_05 decimal(11,2) not null ,
    r10_costo_06 decimal(11,2) not null ,
    r10_costo_07 decimal(11,2) not null 
  )  extent size 2901 next size 290 lock mode row;
revoke all on "fobos".repro_010 from "public";

{ TABLE "fobos".repro_011 row size = 71 number of columns = 13 index size = 37 }
create table "fobos".repro_011 
  (
    r11_compania integer not null ,
    r11_bodega char(2) not null ,
    r11_item char(15) not null ,
    r11_stock_ini decimal(8,2) not null ,
    r11_stock_fin decimal(8,2) not null ,
    r11_stock_act decimal(8,2) not null ,
    r11_stock_01 decimal(8,2) not null ,
    r11_stock_02 decimal(8,2) not null ,
    r11_stock_03 decimal(8,2) not null ,
    r11_stock_04 decimal(8,2) not null ,
    r11_stock_05 decimal(8,2) not null ,
    r11_stock_06 decimal(8,2) not null ,
    r11_stock_07 decimal(8,2) not null 
  )  extent size 5476 next size 547 lock mode row;
revoke all on "fobos".repro_011 from "public";

{ TABLE "fobos".repro_019 row size = 24 number of columns = 5 index size = 31 }
create table "fobos".repro_019 
  (
    r19_compania integer not null ,
    r19_localidad smallint not null ,
    r19_cod_tran char(2) not null ,
    r19_num_tran decimal(15,0) not null ,
    r19_tot_costo decimal(12,2) not null 
  )  extent size 408 next size 40 lock mode row;
revoke all on "fobos".repro_019 from "public";

{ TABLE "fobos".repro_020 row size = 66 number of columns = 11 index size = 57 }
create table "fobos".repro_020 
  (
    r20_compania integer not null ,
    r20_localidad smallint not null ,
    r20_cod_tran char(2) not null ,
    r20_num_tran decimal(15,0) not null ,
    r20_item char(15) not null ,
    r20_orden smallint not null ,
    r20_costo decimal(13,4) not null ,
    r20_costant_mb decimal(11,2) not null ,
    r20_costnue_mb decimal(11,2) not null ,
    r20_stock_ant decimal(8,2) not null ,
    r20_stock_bd decimal(8,2) not null 
  )  extent size 3287 next size 328 lock mode row;
revoke all on "fobos".repro_020 from "public";

{ TABLE "fobos".rept083 row size = 23 number of columns = 3 index size = 87 }
create table "fobos".rept083 
  (
    r83_compania integer not null ,
    r83_item char(15) not null ,
    r83_cod_desc_item integer not null 
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".rept083 from "public";

{ TABLE "fobos".hulk_010 row size = 103 number of columns = 14 index size = 34 }
create table "fobos".hulk_010 
  (
    r10_compania integer not null ,
    r10_codigo char(15) not null ,
    r10_costo_ini decimal(11,2) not null ,
    r10_costo_fin decimal(11,2) not null ,
    r10_costult_fin decimal(11,2) not null ,
    r10_costo_mb decimal(11,2) not null ,
    r10_costult_mb decimal(11,2) not null ,
    r10_costo_01 decimal(11,2) not null ,
    r10_costo_02 decimal(11,2) not null ,
    r10_costo_03 decimal(11,2) not null ,
    r10_costo_04 decimal(11,2) not null ,
    r10_costo_05 decimal(11,2) not null ,
    r10_costo_06 decimal(11,2) not null ,
    r10_costo_07 decimal(11,2) not null 
  )  extent size 2901 next size 290 lock mode row;
revoke all on "fobos".hulk_010 from "public";

{ TABLE "fobos".rolt016 row size = 33 number of columns = 2 index size = 9 }
create table "fobos".rolt016 
  (
    n16_flag_ident char(2) not null ,
    n16_descripcion varchar(30) not null 
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".rolt016 from "public";

{ TABLE "fobos".rolt047 row size = 78 number of columns = 19 index size = 142 }
create table "fobos".rolt047 
  (
    n47_compania integer not null ,
    n47_proceso char(2) not null ,
    n47_cod_trab integer not null ,
    n47_periodo_ini date not null ,
    n47_periodo_fin date not null ,
    n47_secuencia smallint not null ,
    n47_fecini_vac date not null ,
    n47_fecfin_vac date not null ,
    n47_estado char(1) not null ,
    n47_max_dias smallint not null ,
    n47_dias_real smallint not null ,
    n47_dias_goza smallint not null ,
    n47_cod_liqrol char(2) not null ,
    n47_fecha_ini date not null ,
    n47_fecha_fin date not null ,
    n47_valor_pag decimal(12,2) not null ,
    n47_valor_des decimal(12,2) not null ,
    n47_usuario varchar(10,5) not null ,
    n47_fecing datetime year to second not null ,
    
    check (n47_estado IN ('A' ,'G' )) constraint "fobos".ck_01_rolt047
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".rolt047 from "public";

{ TABLE "fobos".vb_vendedores row size = 12 number of columns = 2 index size = 0 
              }
create table "fobos".vb_vendedores 
  (
    cod_integra char(8),
    cod_fobos integer
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".vb_vendedores from "public";

{ TABLE "fobos".rolt048 row size = 117 number of columns = 22 index size = 183 }
create table "fobos".rolt048 
  (
    n48_compania integer not null ,
    n48_proceso char(2) not null ,
    n48_cod_liqrol char(2) not null ,
    n48_fecha_ini date not null ,
    n48_fecha_fin date not null ,
    n48_cod_trab integer not null ,
    n48_estado char(1) not null ,
    n48_ano_proceso smallint not null ,
    n48_mes_proceso smallint not null ,
    n48_moneda char(2) not null ,
    n48_paridad decimal(16,9) not null ,
    n48_num_dias smallint not null ,
    n48_tot_gan decimal(12,2) not null ,
    n48_val_jub_pat decimal(12,2) not null ,
    n48_tipo_pago char(1) not null ,
    n48_bco_empresa integer,
    n48_cta_empresa char(15),
    n48_cta_trabaj char(15),
    n48_tipo_comp char(2),
    n48_num_comp char(8),
    n48_usuario varchar(10,5) not null ,
    n48_fecing datetime year to second not null ,
    
    check (n48_tipo_pago IN ('E' ,'C' ,'T' )),
    
    check (n48_estado IN ('A' ,'P' ,'E' ))
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".rolt048 from "public";

{ TABLE "fobos".rept082 row size = 211 number of columns = 17 index size = 190 }
create table "fobos".rept082 
  (
    r82_compania integer not null ,
    r82_localidad smallint not null ,
    r82_pedido char(10) not null ,
    r82_item char(15) not null ,
    r82_sec_item smallint not null ,
    r82_cod_item_prov char(15) not null ,
    r82_descripcion varchar(70,50) not null ,
    r82_cod_unid char(7) not null ,
    r82_cantidad decimal(18,10) not null ,
    r82_prec_exfab decimal(22,10) not null ,
    r82_prec_fob_mi decimal(22,10) not null ,
    r82_prec_fob_mb decimal(22,10) not null ,
    r82_partida varchar(15,8) not null ,
    r82_sec_partida smallint not null ,
    r82_porc_arancel decimal(14,10) not null ,
    r82_porc_salvagu decimal(14,10) not null ,
    r82_peso_item decimal(8,4) not null 
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".rept082 from "public";

{ TABLE "fobos".rept084 row size = 148 number of columns = 5 index size = 52 }
create table "fobos".rept084 
  (
    r84_compania integer not null ,
    r84_cod_desc_item integer not null ,
    r84_descripcion varchar(120,80) not null ,
    r84_usuario varchar(10,5) not null ,
    r84_fecing datetime year to second not null 
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".rept084 from "public";

{ TABLE "fobos".temp_a10 row size = 212 number of columns = 30 index size = 0 }
create table "fobos".temp_a10 
  (
    a10_compania integer not null ,
    a10_codigo_bien integer not null ,
    a10_estado char(1) not null ,
    a10_descripcion varchar(40,20) not null ,
    a10_grupo_act smallint not null ,
    a10_tipo_act smallint not null ,
    a10_anos_util smallint not null ,
    a10_porc_deprec decimal(4,2) not null ,
    a10_modelo varchar(15),
    a10_serie varchar(25),
    a10_locali_ori smallint not null ,
    a10_numero_oc integer,
    a10_localidad smallint not null ,
    a10_cod_depto smallint not null ,
    a10_codprov integer not null ,
    a10_fecha_comp date not null ,
    a10_moneda char(2) not null ,
    a10_paridad decimal(16,9) not null ,
    a10_valor decimal(12,2) not null ,
    a10_valor_mb decimal(12,2) not null ,
    a10_responsable smallint,
    a10_fecha_baja date,
    a10_val_dep_mb decimal(11,2) not null ,
    a10_val_dep_ma decimal(11,2) not null ,
    a10_tot_dep_mb decimal(12,2) not null ,
    a10_tot_dep_ma decimal(12,2) not null ,
    a10_tot_reexpr decimal(12,2) not null ,
    a10_tot_dep_ree decimal(12,2) not null ,
    a10_usuario varchar(10,5) not null ,
    a10_fecing datetime year to second not null ,
    
    check (a10_estado IN ('A' ,'B' ,'V' ,'D' ,'S' ,'E' ))
  )  extent size 24 next size 16 lock mode row;
revoke all on "fobos".temp_a10 from "public";

{ TABLE "fobos".actt013 row size = 17 number of columns = 4 index size = 39 }
create table "fobos".actt013 
  (
    a13_compania integer not null ,
    a13_codigo_bien integer not null ,
    a13_ano smallint not null ,
    a13_val_dep_acum decimal(12,2) not null 
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".actt013 from "public";

{ TABLE "fobos".te_vta_qto row size = 105 number of columns = 5 index size = 0 }
create table "fobos".te_vta_qto 
  (
    te_marca char(6) not null ,
    te_item char(15) not null ,
    te_nombre char(70) not null ,
    te_cod_clase char(8) not null ,
    te_uni_vta decimal(10,2) not null 
  )  extent size 550 next size 55 lock mode row;
revoke all on "fobos".te_vta_qto from "public";

{ TABLE "fobos".te_prec_fv row size = 29 number of columns = 3 index size = 0 }
create table "fobos".te_prec_fv 
  (
    te_codigo char(15) not null ,
    te_precio_mb decimal(12,2) not null ,
    te_costrepo decimal(12,2) not null 
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".te_prec_fv from "public";

{ TABLE "fobos".te_fv_descri row size = 100 number of columns = 3 index size = 0 
              }
create table "fobos".te_fv_descri 
  (
    te_codigo char(15),
    te_cod_pedido char(15),
    te_nombre char(70)
  )  extent size 57 next size 16 lock mode row;
revoke all on "fobos".te_fv_descri from "public";

{ TABLE "fobos".te_sanit row size = 127 number of columns = 6 index size = 28 }
create table "fobos".te_sanit 
  (
    r10_codigo char(15),
    r10_cod_pedido char(20),
    r10_nombre char(70),
    r10_fob decimal(13,4),
    r10_costrepo_mb decimal(11,2),
    r10_precio_mb decimal(11,2)
  )  extent size 55 next size 16 lock mode row;
revoke all on "fobos".te_sanit from "public";

{ TABLE "fobos".te_cheb32 row size = 54 number of columns = 5 index size = 0 }
create table "fobos".te_cheb32 
  (
    b32_fec_proceso date not null ,
    b32_num_cheque integer not null ,
    b32_benef_che varchar(25) not null ,
    b32_valor_base decimal(14,2) not null ,
    b32_cuenta char(12) not null 
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".te_cheb32 from "public";

{ TABLE "fobos".te_acces_fv row size = 127 number of columns = 6 index size = 28 
              }
create table "fobos".te_acces_fv 
  (
    r10_codigo char(15),
    r10_cod_pedido char(20),
    r10_nombre char(70),
    r10_fob decimal(13,4),
    r10_costrepo_mb decimal(11,2),
    r10_precio_mb decimal(11,2)
  )  extent size 21 next size 16 lock mode row;
revoke all on "fobos".te_acces_fv from "public";

{ TABLE "fobos".ctbt666 row size = 38 number of columns = 6 index size = 0 }
create table "fobos".ctbt666 
  (
    b66_ano smallint,
    b66_mes smallint,
    b66_cuenta char(12),
    b66_val_dbcr_11 decimal(12,2),
    b66_valor_tran decimal(12,2),
    b66_fecing datetime year to second
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".ctbt666 from "public";

{ TABLE "fobos".te_rolaux row size = 174 number of columns = 25 index size = 12 }
create table "fobos".te_rolaux 
  (
    te_cod_trab integer not null ,
    te_nombre char(30) not null ,
    te_sueldo decimal(11,2) not null ,
    te_dias_trab smallint not null ,
    te_dias_enf smallint not null ,
    te_dias_vac smallint not null ,
    te_sueld_gan decimal(11,2) not null ,
    te_horas_50 decimal(7,2) not null ,
    te_horas_100 decimal(7,2) not null ,
    te_horas_etot decimal(7,2) not null ,
    te_comisiones decimal(11,2) not null ,
    te_vacaciones decimal(11,2) not null ,
    te_tot_ganado decimal(11,2) not null ,
    te_rus decimal(11,2) not null ,
    te_moviliz decimal(11,2) not null ,
    te_otros_ing decimal(11,2) not null ,
    te_tot_ing decimal(11,2) not null ,
    te_anticipos decimal(11,2) not null ,
    te_comisar decimal(11,2) not null ,
    te_prest_iess decimal(11,2) not null ,
    te_otros_des decimal(11,2) not null ,
    te_aport_iess decimal(11,2) not null ,
    te_tot_egr decimal(11,2) not null ,
    te_tot_neto decimal(11,2) not null ,
    te_tot_neg decimal(11,2) not null 
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".te_rolaux from "public";

{ TABLE "fobos".te_rol99_02 row size = 89 number of columns = 9 index size = 24 }
create table "fobos".te_rol99_02 
  (
    te_numreg smallint not null ,
    te_codfec char(8) not null ,
    te_cod_trab integer not null ,
    te_nombre char(40) not null ,
    te_tot_gan decimal(11,2) not null ,
    te_tot_ing decimal(11,2) not null ,
    te_tot_egr decimal(11,2) not null ,
    te_tot_neto decimal(11,2) not null ,
    te_tot_neg decimal(11,2) not null 
  )  extent size 691 next size 69 lock mode row;
revoke all on "fobos".te_rol99_02 from "public";

{ TABLE "fobos".te_rol2003 row size = 180 number of columns = 28 index size = 21 
              }
create table "fobos".te_rol2003 
  (
    te_cod_liqrol char(2) not null ,
    te_ano smallint not null ,
    te_mes smallint not null ,
    te_cod_trab integer not null ,
    te_nombre char(30) not null ,
    te_sueldo decimal(11,2) not null ,
    te_dias_trab smallint not null ,
    te_dias_enf smallint not null ,
    te_dias_vac smallint not null ,
    te_sueld_gan decimal(11,2) not null ,
    te_horas_50 decimal(7,2) not null ,
    te_horas_100 decimal(7,2) not null ,
    te_horas_etot decimal(7,2) not null ,
    te_comisiones decimal(11,2) not null ,
    te_vacaciones decimal(11,2) not null ,
    te_tot_ganado decimal(11,2) not null ,
    te_rus decimal(11,2) not null ,
    te_moviliz decimal(11,2) not null ,
    te_otros_ing decimal(11,2) not null ,
    te_tot_ing decimal(11,2) not null ,
    te_anticipos decimal(11,2) not null ,
    te_comisar decimal(11,2) not null ,
    te_prest_iess decimal(11,2) not null ,
    te_otros_des decimal(11,2) not null ,
    te_aport_iess decimal(11,2) not null ,
    te_tot_egr decimal(11,2) not null ,
    te_tot_neto decimal(11,2) not null ,
    te_tot_neg decimal(11,2) not null 
  )  extent size 162 next size 16 lock mode row;
revoke all on "fobos".te_rol2003 from "public";

{ TABLE "fobos".te_rolt033 row size = 66 number of columns = 15 index size = 36 }
create table "fobos".te_rolt033 
  (
    n33_compania integer not null ,
    n33_cod_liqrol char(2) not null ,
    n33_fecha_ini date not null ,
    n33_fecha_fin date not null ,
    n33_cod_trab integer not null ,
    n33_cod_rubro smallint not null ,
    n33_num_prest integer,
    n33_prest_club integer,
    n33_referencia varchar(20),
    n33_orden smallint not null ,
    n33_det_tot char(2) not null ,
    n33_imprime_0 char(1) not null ,
    n33_cant_valor char(1) not null ,
    n33_horas_porc decimal(5,2),
    n33_valor decimal(12,2) not null ,
    
    check (n33_det_tot IN ('DI' ,'DE' ,'TI' ,'TE' ,'TN' )),
    
    check (n33_imprime_0 IN ('S' ,'N' )),
    
    check (n33_cant_valor IN ('H' ,'D' ,'P' ,'V' ))
  )  extent size 2100 next size 210 lock mode row;
revoke all on "fobos".te_rolt033 from "public";

{ TABLE "fobos".te_rolt032 row size = 125 number of columns = 24 index size = 33 
              }
create table "fobos".te_rolt032 
  (
    n32_compania integer not null ,
    n32_cod_liqrol char(2) not null ,
    n32_fecha_ini date not null ,
    n32_fecha_fin date not null ,
    n32_cod_trab integer not null ,
    n32_estado char(1) not null ,
    n32_cod_depto smallint not null ,
    n32_sueldo decimal(11,2) not null ,
    n32_ano_proceso smallint not null ,
    n32_mes_proceso smallint not null ,
    n32_orden smallint not null ,
    n32_dias_trab smallint not null ,
    n32_dias_falt smallint not null ,
    n32_tot_ing decimal(12,2) not null ,
    n32_tot_egr decimal(12,2) not null ,
    n32_tot_neto decimal(12,2) not null ,
    n32_moneda char(2) not null ,
    n32_paridad decimal(16,9) not null ,
    n32_tipo_pago char(1) not null ,
    n32_bco_empresa integer,
    n32_cta_empresa char(15),
    n32_cta_trabaj char(15),
    n32_usuario varchar(10,5) not null ,
    n32_fecing datetime year to second not null ,
    
    check (n32_tipo_pago IN ('E' ,'C' ,'T' ))
  )  extent size 937 next size 93 lock mode row;
revoke all on "fobos".te_rolt032 from "public";

{ TABLE "fobos".rolt060 row size = 155 number of columns = 13 index size = 61 }
create table "fobos".rolt060 
  (
    n60_compania integer not null ,
    n60_tipo_afilia char(1) not null ,
    n60_val_aporte decimal(12,2) not null ,
    n60_frec_aporte char(1) not null ,
    n60_rub_aporte smallint not null ,
    n60_int_mensual decimal(4,2) not null ,
    n60_presidente varchar(45,25) not null ,
    n60_tesorero varchar(45,25) not null ,
    n60_banco integer not null ,
    n60_numero_cta char(15) not null ,
    n60_saldo_cta decimal(12,2) not null ,
    n60_usuario varchar(10,5) not null ,
    n60_fecing datetime year to second not null ,
    
    check (n60_tipo_afilia IN ('O' ,'V' )),
    
    check (n60_frec_aporte IN ('S' ,'Q' ,'M' ))
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".rolt060 from "public";

{ TABLE "fobos".rolt061 row size = 42 number of columns = 7 index size = 52 }
create table "fobos".rolt061 
  (
    n61_compania integer not null ,
    n61_cod_trab integer not null ,
    n61_fec_ing_club date not null ,
    n61_fec_sal_club date,
    n61_cuota decimal(12,2) not null ,
    n61_usuario varchar(10,5) not null ,
    n61_fecing datetime year to second not null 
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".rolt061 from "public";

{ TABLE "fobos".rolt062 row size = 69 number of columns = 7 index size = 67 }
create table "fobos".rolt062 
  (
    n62_compania integer not null ,
    n62_cod_almacen integer not null ,
    n62_nombre char(30) not null ,
    n62_abreviado char(10) not null ,
    n62_cod_rubro smallint not null ,
    n62_usuario varchar(10,5) not null ,
    n62_fecing datetime year to second not null 
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".rolt062 from "public";

{ TABLE "fobos".rolt063 row size = 30 number of columns = 8 index size = 111 }
create table "fobos".rolt063 
  (
    n63_compania integer not null ,
    n63_cod_almacen integer not null ,
    n63_cod_liqrol char(2) not null ,
    n63_fecha_ini date not null ,
    n63_fecha_fin date not null ,
    n63_cod_trab integer not null ,
    n63_estado char(1) not null ,
    n63_valor decimal(12,2) not null ,
    
    check (n63_estado IN ('A' ,'P' ))
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".rolt063 from "public";

{ TABLE "fobos".rolt065 row size = 41 number of columns = 9 index size = 48 }
create table "fobos".rolt065 
  (
    n65_compania integer not null ,
    n65_num_prest integer not null ,
    n65_secuencia smallint not null ,
    n65_cod_liqrol char(2) not null ,
    n65_fecha_ini date not null ,
    n65_fecha_fin date not null ,
    n65_valor decimal(12,2) not null ,
    n65_val_interes decimal(12,2) not null ,
    n65_saldo decimal(12,2) not null 
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".rolt065 from "public";

{ TABLE "fobos".rolt066 row size = 58 number of columns = 12 index size = 37 }
create table "fobos".rolt066 
  (
    n66_compania integer not null ,
    n66_concepto_pago smallint not null ,
    n66_desc_cpto_pago varchar(20,10) not null ,
    n66_sec_patronal char(1) not null ,
    n66_provincia smallint not null ,
    n66_canton smallint not null ,
    n66_parroquia smallint not null ,
    n66_tipo_seguro smallint not null ,
    n66_tipo_planilla smallint not null ,
    n66_pre_arch char(1) not null ,
    n66_usuario varchar(10,5) not null ,
    n66_fecing datetime year to second not null 
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".rolt066 from "public";

{ TABLE "fobos".rolt067 row size = 54 number of columns = 6 index size = 31 }
create table "fobos".rolt067 
  (
    n67_cod_rubro smallint not null ,
    n67_nombre varchar(30,15) not null ,
    n67_estado char(1) not null ,
    n67_flag_ident char(1) not null ,
    n67_usuario varchar(10,5) not null ,
    n67_fecing datetime year to second not null ,
    
    check (n67_flag_ident IN ('I' ,'E' )),
    
    check (n67_estado IN ('A' ,'B' ))
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".rolt067 from "public";

{ TABLE "fobos".rolt068 row size = 199 number of columns = 19 index size = 124 }
create table "fobos".rolt068 
  (
    n68_compania integer not null ,
    n68_cod_tran char(2) not null ,
    n68_num_tran decimal(10,0) not null ,
    n68_cod_rubro smallint not null ,
    n68_fecha date not null ,
    n68_valor decimal(12,2) not null ,
    n68_referencia varchar(60,30) not null ,
    n68_num_prest integer,
    n68_cod_liqrol char(2),
    n68_fecha_ini date,
    n68_fecha_fin date,
    n68_cod_trab integer,
    n68_banco integer,
    n68_numero_cta char(15),
    n68_num_cheque integer,
    n68_beneficiario varchar(45,25),
    n68_saldo_ant decimal(12,2) not null ,
    n68_usuario varchar(10,5) not null ,
    n68_fecing datetime year to second not null ,
    
    check (n68_cod_tran IN ('IN' ,'EG' ))
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".rolt068 from "public";

{ TABLE "fobos".rolt069 row size = 48 number of columns = 8 index size = 70 }
create table "fobos".rolt069 
  (
    n69_compania integer not null ,
    n69_banco integer not null ,
    n69_numero_cta char(15) not null ,
    n69_anio smallint not null ,
    n69_mes smallint not null ,
    n69_saldo_ini decimal(12,2) not null ,
    n69_valor_ing decimal(12,2) not null ,
    n69_valor_egr decimal(12,2) not null 
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".rolt069 from "public";

{ TABLE "fobos".rolt050 row size = 20 number of columns = 4 index size = 84 }
create table "fobos".rolt050 
  (
    n50_compania integer not null ,
    n50_cod_rubro smallint not null ,
    n50_cod_depto smallint not null ,
    n50_aux_cont char(12) not null 
  )  extent size 23 next size 16 lock mode row;
revoke all on "fobos".rolt050 from "public";

{ TABLE "fobos".rolt051 row size = 18 number of columns = 3 index size = 66 }
create table "fobos".rolt051 
  (
    n51_compania integer not null ,
    n51_cod_rubro smallint not null ,
    n51_aux_cont char(12) not null 
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".rolt051 from "public";

{ TABLE "fobos".rolt052 row size = 22 number of columns = 4 index size = 90 }
create table "fobos".rolt052 
  (
    n52_compania integer not null ,
    n52_cod_rubro smallint not null ,
    n52_cod_trab integer not null ,
    n52_aux_cont char(12) not null 
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".rolt052 from "public";

{ TABLE "fobos".te_gent034 row size = 70 number of columns = 7 index size = 0 }
create table "fobos".te_gent034 
  (
    g34_compania integer not null ,
    g34_cod_depto smallint not null ,
    g34_cod_ccosto smallint not null ,
    g34_nombre varchar(30,15) not null ,
    g34_aux_deprec char(12),
    g34_usuario varchar(10,5) not null ,
    g34_fecing datetime year to second not null 
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".te_gent034 from "public";

{ TABLE "fobos".rolt053 row size = 24 number of columns = 6 index size = 84 }
create table "fobos".rolt053 
  (
    n53_compania integer not null ,
    n53_cod_liqrol char(2) not null ,
    n53_fecha_ini date not null ,
    n53_fecha_fin date not null ,
    n53_tipo_comp char(2) not null ,
    n53_num_comp char(8) not null 
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".rolt053 from "public";

{ TABLE "fobos".rolt054 row size = 16 number of columns = 2 index size = 42 }
create table "fobos".rolt054 
  (
    n54_compania integer not null ,
    n54_aux_cont char(12) not null 
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".rolt054 from "public";

{ TABLE "fobos".te_edesa row size = 29 number of columns = 3 index size = 28 }
create table "fobos".te_edesa 
  (
    te_codigo char(15) not null ,
    te_costrepo_mb decimal(11,2) not null ,
    te_precio_mb decimal(11,2) not null 
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".te_edesa from "public";

{ TABLE "fobos".te_gan_qto row size = 17 number of columns = 5 index size = 21 }
create table "fobos".te_gan_qto 
  (
    te_cod_trab integer not null ,
    te_ganado decimal(11,2) not null ,
    te_cod_liqrol char(2) not null ,
    te_ano smallint not null ,
    te_mes smallint not null 
  )  extent size 465 next size 46 lock mode row;
revoke all on "fobos".te_gan_qto from "public";

{ TABLE "fobos".rolt080 row size = 129 number of columns = 21 index size = 63 }
create table "fobos".rolt080 
  (
    n80_compania integer not null ,
    n80_ano smallint not null ,
    n80_mes smallint not null ,
    n80_cod_trab integer not null ,
    n80_moneda char(2) not null ,
    n80_paridad decimal(16,9) not null ,
    n80_san_trab decimal(11,2) not null ,
    n80_san_patr decimal(11,2) not null ,
    n80_san_int decimal(11,2) not null ,
    n80_san_dscto decimal(11,2) not null ,
    n80_q1_trab decimal(11,2) not null ,
    n80_q2_trab decimal(11,2) not null ,
    n80_q1_patr decimal(11,2) not null ,
    n80_q2_patr decimal(11,2) not null ,
    n80_val_int decimal(11,2) not null ,
    n80_val_dscto decimal(11,2) not null ,
    n80_sac_trab decimal(11,2) not null ,
    n80_sac_patr decimal(11,2) not null ,
    n80_sac_int decimal(11,2) not null ,
    n80_sac_dscto decimal(11,2) not null ,
    n80_val_retiro decimal(11,2) not null 
  )  extent size 54 next size 16 lock mode row;
revoke all on "fobos".rolt080 from "public";

{ TABLE "fobos".rolt081 row size = 187 number of columns = 22 index size = 94 }
create table "fobos".rolt081 
  (
    n81_compania integer not null ,
    n81_num_poliza char(20) not null ,
    n81_estado char(1) not null ,
    n81_dias_plazo smallint not null ,
    n81_porc_int decimal(5,2) not null ,
    n81_fec_firma date not null ,
    n81_fec_vcto date not null ,
    n81_referencia varchar(60,30),
    n81_moneda char(2) not null ,
    n81_paridad decimal(16,9) not null ,
    n81_cap_trab decimal(11,2) not null ,
    n81_cap_patr decimal(11,2) not null ,
    n81_cap_int decimal(11,2) not null ,
    n81_cap_dscto decimal(11,2) not null ,
    n81_cod_liqrol char(2) not null ,
    n81_fecha_ini date not null ,
    n81_fecha_fin date not null ,
    n81_fec_distri date,
    n81_val_int decimal(11,2) not null ,
    n81_val_dscto decimal(11,2) not null ,
    n81_usuario varchar(10,5) not null ,
    n81_fecing datetime year to second not null ,
    
    check (n81_estado IN ('A' ,'P' ))
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".rolt081 from "public";

{ TABLE "fobos".rolt082 row size = 58 number of columns = 10 index size = 94 }
create table "fobos".rolt082 
  (
    n82_compania integer not null ,
    n82_cod_trab integer not null ,
    n82_secuencia serial not null ,
    n82_banco integer,
    n82_numero_cta char(15),
    n82_num_cheque integer,
    n82_fecha date not null ,
    n82_moneda char(2) not null ,
    n82_paridad decimal(16,9) not null ,
    n82_valor decimal(11,2) not null 
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".rolt082 from "public";

{ TABLE "fobos".rolt083 row size = 86 number of columns = 13 index size = 105 }
create table "fobos".rolt083 
  (
    n83_compania integer not null ,
    n83_ano smallint not null ,
    n83_mes smallint not null ,
    n83_cod_trab integer not null ,
    n83_num_poliza char(20) not null ,
    n83_moneda char(2) not null ,
    n83_paridad decimal(16,9) not null ,
    n83_cap_trab decimal(11,2) not null ,
    n83_cap_patr decimal(11,2) not null ,
    n83_cap_int decimal(11,2) not null ,
    n83_cap_dscto decimal(11,2) not null ,
    n83_val_int decimal(11,2) not null ,
    n83_val_dscto decimal(11,2) not null 
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".rolt083 from "public";

{ TABLE "fobos".te_rol1202 row size = 180 number of columns = 28 index size = 21 
              }
create table "fobos".te_rol1202 
  (
    te_cod_liqrol char(2) not null ,
    te_ano smallint not null ,
    te_mes smallint not null ,
    te_cod_trab integer not null ,
    te_nombre char(30) not null ,
    te_sueldo decimal(11,2) not null ,
    te_dias_trab smallint not null ,
    te_dias_enf smallint not null ,
    te_dias_vac smallint not null ,
    te_sueld_gan decimal(11,2) not null ,
    te_horas_50 decimal(7,2) not null ,
    te_horas_100 decimal(7,2) not null ,
    te_horas_etot decimal(7,2) not null ,
    te_comisiones decimal(11,2) not null ,
    te_vacaciones decimal(11,2) not null ,
    te_tot_ganado decimal(11,2) not null ,
    te_rus decimal(11,2) not null ,
    te_moviliz decimal(11,2) not null ,
    te_otros_ing decimal(11,2) not null ,
    te_tot_ing decimal(11,2) not null ,
    te_anticipos decimal(11,2) not null ,
    te_comisar decimal(11,2) not null ,
    te_prest_iess decimal(11,2) not null ,
    te_otros_des decimal(11,2) not null ,
    te_aport_iess decimal(11,2) not null ,
    te_tot_egr decimal(11,2) not null ,
    te_tot_neto decimal(11,2) not null ,
    te_tot_neg decimal(11,2) not null 
  )  extent size 23 next size 16 lock mode row;
revoke all on "fobos".te_rol1202 from "public";

{ TABLE "fobos".te_stofis row size = 79 number of columns = 13 index size = 177 }
create table "fobos".te_stofis 
  (
    te_compania integer not null ,
    te_localidad smallint not null ,
    te_bodega char(2) not null ,
    te_item char(15) not null ,
    te_stock_act decimal(8,2) not null ,
    te_bueno decimal(8,2) 
        default 0.00 not null ,
    te_incompleto decimal(8,2) 
        default 0.00 not null ,
    te_mal_est decimal(8,2) 
        default 0.00 not null ,
    te_suma decimal(8,2) 
        default 0.00 not null ,
    te_fecha date not null ,
    te_fec_modifi datetime year to second,
    te_usuario varchar(10,5) not null ,
    te_fecing datetime year to second not null 
  )  extent size 2015 next size 201 lock mode row;
revoke all on "fobos".te_stofis from "public";

{ TABLE "fobos".resp_exis row size = 99 number of columns = 16 index size = 99 }
create table "fobos".resp_exis 
  (
    r11_compania integer not null ,
    r11_bodega char(2) not null ,
    r11_item char(15) not null ,
    r11_ubicacion char(10) not null ,
    r11_ubica_ant char(10),
    r11_stock_ant decimal(8,2) not null ,
    r11_stock_act decimal(8,2) not null ,
    r11_ing_dia decimal(8,2) not null ,
    r11_egr_dia decimal(8,2) not null ,
    r11_fec_ultvta date,
    r11_tip_ultvta char(2),
    r11_num_ultvta decimal(15,0),
    r11_fec_ulting date,
    r11_tip_ulting char(2),
    r11_num_ulting decimal(15,0),
    r11_fec_corte datetime year to second not null 
  )  extent size 10353 next size 1035 lock mode row;
revoke all on "fobos".resp_exis from "public";

{ TABLE "fobos".te_boddan row size = 10 number of columns = 4 index size = 78 }
create table "fobos".te_boddan 
  (
    te_compania integer not null ,
    te_localidad smallint not null ,
    te_bodega char(2) not null ,
    te_bodega_dan char(2) not null 
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".te_boddan from "public";

{ TABLE "fobos".pancho row size = 79 number of columns = 13 index size = 0 }
create table "fobos".pancho 
  (
    te_compania integer not null ,
    te_localidad smallint not null ,
    te_bodega char(2) not null ,
    te_item char(15) not null ,
    te_stock_act decimal(8,2) not null ,
    te_bueno decimal(8,2) 
        default 0 not null ,
    te_incompleto decimal(8,2) 
        default 0 not null ,
    te_mal_est decimal(8,2) 
        default 0 not null ,
    te_suma decimal(8,2) 
        default 0 not null ,
    te_fecha date not null ,
    te_fec_modifi datetime year to second,
    te_usuario varchar(10,5) not null ,
    te_fecing datetime year to second not null 
  )  extent size 23 next size 16 lock mode row;
revoke all on "fobos".pancho from "public";

{ TABLE "fobos".rolt039 row size = 168 number of columns = 34 index size = 159 }
create table "fobos".rolt039 
  (
    n39_compania integer not null ,
    n39_proceso char(2) not null ,
    n39_cod_trab integer not null ,
    n39_periodo_ini date not null ,
    n39_periodo_fin date not null ,
    n39_perini_real date not null ,
    n39_perfin_real date not null ,
    n39_tipo char(1) not null ,
    n39_estado char(1) not null ,
    n39_cod_depto smallint not null ,
    n39_ano_proceso smallint not null ,
    n39_mes_proceso smallint not null ,
    n39_fecha_ing date not null ,
    n39_dias_vac smallint not null ,
    n39_dias_adi smallint not null ,
    n39_dias_goza smallint not null ,
    n39_fecini_vac date,
    n39_fecfin_vac date,
    n39_moneda char(2) not null ,
    n39_paridad decimal(16,9) not null ,
    n39_tot_ganado decimal(12,2) not null ,
    n39_valor_vaca decimal(12,2) not null ,
    n39_valor_adic decimal(11,2) not null ,
    n39_otros_ing decimal(12,2) not null ,
    n39_descto_iess decimal(12,2) not null ,
    n39_otros_egr decimal(12,2) not null ,
    n39_neto decimal(12,2) not null ,
    n39_tipo_pago char(1) not null ,
    n39_bco_empresa integer,
    n39_cta_empresa char(15),
    n39_cta_trabaj char(15),
    n39_gozar_adic char(1) not null ,
    n39_usuario varchar(10,5) not null ,
    n39_fecing datetime year to second not null ,
    
    check (n39_estado IN ('A' ,'P' )),
    
    check (n39_tipo_pago IN ('E' ,'C' ,'T' )),
    
    check (n39_tipo IN ('G' ,'P' )),
    
    check (n39_gozar_adic IN ('S' ,'N' )) constraint "fobos".ck_01_rolt039
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".rolt039 from "public";

{ TABLE "fobos".rolt040 row size = 36 number of columns = 11 index size = 111 }
create table "fobos".rolt040 
  (
    n40_compania integer not null ,
    n40_proceso char(2) not null ,
    n40_cod_trab integer not null ,
    n40_periodo_ini date not null ,
    n40_periodo_fin date not null ,
    n40_cod_rubro smallint not null ,
    n40_num_prest integer,
    n40_orden smallint not null ,
    n40_det_tot char(2) not null ,
    n40_imprime_0 char(1) not null ,
    n40_valor decimal(12,2) not null ,
    
    check (n40_det_tot IN ('DI' ,'DE' ,'TI' ,'TE' ,'TN' )),
    
    check (n40_imprime_0 IN ('S' ,'N' ))
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".rolt040 from "public";

{ TABLE "fobos".rolt055 row size = 26 number of columns = 7 index size = 57 }
create table "fobos".rolt055 
  (
    n55_compania integer not null ,
    n55_cod_trab integer not null ,
    n55_periodo_ini date not null ,
    n55_periodo_fin date not null ,
    n55_secuencia smallint not null ,
    n55_fecha_ini date not null ,
    n55_fecha_fin date not null 
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".rolt055 from "public";

{ TABLE "fobos".rolt084 row size = 204 number of columns = 30 index size = 162 }
create table "fobos".rolt084 
  (
    n84_compania integer not null ,
    n84_proceso char(2) not null ,
    n84_cod_trab integer not null ,
    n84_ano_proceso smallint not null ,
    n84_estado char(1) not null ,
    n84_moneda char(2) not null ,
    n84_paridad decimal(16,9) not null ,
    n84_fracc_ini decimal(12,2) not null ,
    n84_ing_roles decimal(12,2) not null ,
    n84_dec_cuarto decimal(12,2) not null ,
    n84_dec_tercero decimal(12,2) not null ,
    n84_roles_varios decimal(12,2) not null ,
    n84_utilidades decimal(12,2) not null ,
    n84_vacaciones decimal(12,2) not null ,
    n84_aporte_iess decimal(11,2) not null ,
    n84_bonificacion decimal(12,2) not null ,
    n84_otros_ing decimal(12,2) not null ,
    n84_total_gan decimal(14,2) not null ,
    n84_imp_basico decimal(11,2) not null ,
    n84_porc_exced decimal(5,2) not null ,
    n84_imp_real decimal(12,2) not null ,
    n84_imp_ret decimal(12,2) not null ,
    n84_usu_modifi varchar(10,5),
    n84_fec_modifi datetime year to second,
    n84_usu_elimin varchar(10,5),
    n84_fec_elimin datetime year to second,
    n84_usu_cierre varchar(10,5),
    n84_fec_cierre datetime year to second,
    n84_usuario varchar(10,5) not null ,
    n84_fecing datetime year to second not null ,
    
    check (n84_estado IN ('A' ,'B' ,'P' ))
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".rolt084 from "public";

{ TABLE "fobos".tempo_011 row size = 36 number of columns = 6 index size = 37 }
create table "fobos".tempo_011 
  (
    r11_compania integer not null ,
    r11_bodega char(2) not null ,
    r11_item char(15) not null ,
    r11_stock_ini decimal(8,2) not null ,
    r11_stock_fin decimal(8,2) not null ,
    r11_stock_act decimal(8,2) not null 
  )  extent size 227 next size 22 lock mode row;
revoke all on "fobos".tempo_011 from "public";

{ TABLE "fobos".rept090 row size = 46 number of columns = 9 index size = 31 }
create table "fobos".rept090 
  (
    r90_compania integer not null ,
    r90_localidad smallint not null ,
    r90_cod_tran char(2) not null ,
    r90_num_tran decimal(15,0) not null ,
    r90_fecing datetime year to second not null ,
    r90_locali_fin smallint 
        default 1 not null ,
    r90_codtra_fin char(2),
    r90_numtra_fin decimal(15,0),
    r90_fecing_fin datetime year to second 
        default current year to second
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".rept090 from "public";

{ TABLE "fobos".rept092 row size = 158 number of columns = 27 index size = 91 }
create table "fobos".rept092 
  (
    r92_compania integer not null ,
    r92_localidad smallint not null ,
    r92_cod_tran char(2) not null ,
    r92_num_tran decimal(15,0) not null ,
    r92_bodega char(2) not null ,
    r92_item char(15) not null ,
    r92_orden smallint not null ,
    r92_cant_ped decimal(8,2) not null ,
    r92_cant_ven decimal(8,2) not null ,
    r92_cant_dev decimal(8,2) not null ,
    r92_cant_ent decimal(8,2) not null ,
    r92_descuento decimal(4,2) not null ,
    r92_val_descto decimal(10,2) not null ,
    r92_precio decimal(13,4) not null ,
    r92_val_impto decimal(11,2) not null ,
    r92_costo decimal(13,4) not null ,
    r92_fob decimal(11,2) not null ,
    r92_linea char(5) not null ,
    r92_rotacion char(2) not null ,
    r92_ubicacion char(10) not null ,
    r92_costant_mb decimal(11,2) not null ,
    r92_costant_ma decimal(11,2) not null ,
    r92_costnue_mb decimal(11,2) not null ,
    r92_costnue_ma decimal(11,2) not null ,
    r92_stock_ant decimal(8,2) not null ,
    r92_stock_bd decimal(8,2) not null ,
    r92_fecing datetime year to second not null ,
    primary key (r92_compania,r92_localidad,r92_cod_tran,r92_num_tran,r92_bodega,r92_item,r92_orden) 
               constraint "fobos".pk_rept092
  )  extent size 79 next size 16 lock mode row;
revoke all on "fobos".rept092 from "public";

{ TABLE "fobos".tr_codutil row size = 52 number of columns = 11 index size = 19 }
create table "fobos".tr_codutil 
  (
    r77_compania integer not null ,
    r77_codigo_util char(5) not null ,
    r77_multiplic integer not null ,
    r77_dscmax_ger decimal(4,2) not null ,
    r77_dscmax_jef decimal(4,2) not null ,
    r77_dscmax_ven decimal(4,2) not null ,
    r77_util_min decimal(5,2) not null ,
    r77_desc_promo decimal(4,2) not null ,
    r77_util_promo decimal(5,2) not null ,
    r77_usuario varchar(10,5) not null ,
    r77_fecing datetime year to second not null ,
    primary key (r77_compania,r77_codigo_util)  constraint "fobos".pk_tr_codutil
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".tr_codutil from "public";

{ TABLE "fobos".rolt041 row size = 71 number of columns = 15 index size = 79 }
create table "fobos".rolt041 
  (
    n41_compania integer not null ,
    n41_proceso char(2) not null ,
    n41_fecha_ini date not null ,
    n41_fecha_fin date not null ,
    n41_ano smallint not null ,
    n41_estado char(1) not null ,
    n41_util_bonif char(1) not null ,
    n41_porc_trabaj decimal(4,2) not null ,
    n41_porc_cargas decimal(4,2) not null ,
    n41_val_trabaj decimal(13,2) not null ,
    n41_val_cargas decimal(13,2) not null ,
    n41_moneda char(2) not null ,
    n41_paridad decimal(16,9) not null ,
    n41_usuario varchar(10,5) not null ,
    n41_fecing datetime year to second not null ,
    
    check (n41_estado IN ('A' ,'P' )),
    
    check (n41_util_bonif IN ('U' ,'B' ))
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".rolt041 from "public";

{ TABLE "fobos".rept085 row size = 174 number of columns = 20 index size = 222 }
create table "fobos".rept085 
  (
    r85_compania integer not null ,
    r85_codigo integer not null ,
    r85_estado char(1) not null ,
    r85_tipo_carga char(1) not null ,
    r85_referencia varchar(60,30) not null ,
    r85_division char(5),
    r85_linea char(2),
    r85_cod_grupo char(4),
    r85_cod_clase char(8),
    r85_marca char(6),
    r85_cod_util char(5),
    r85_partida varchar(15,8),
    r85_precio_nue decimal(11,2) not null ,
    r85_porc_aum decimal(5,2) not null ,
    r85_porc_dec decimal(5,2) not null ,
    r85_fec_camprec date not null ,
    r85_usu_reversa varchar(10,5),
    r85_fec_reversa datetime year to second,
    r85_usuario varchar(10,5) not null ,
    r85_fecing datetime year to second not null ,
    
    check (r85_estado IN ('A' ,'R' )),
    
    check (r85_tipo_carga IN ('N' ,'C' ,'P' ,'E' )) constraint "fobos".ck_02_rept085
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".rept085 from "public";

{ TABLE "fobos".rept086 row size = 57 number of columns = 9 index size = 76 }
create table "fobos".rept086 
  (
    r86_compania integer not null ,
    r86_codigo integer not null ,
    r86_secuencia integer not null ,
    r86_item char(15) not null ,
    r86_precio_mb decimal(11,2) not null ,
    r86_precio_ant decimal(11,2) not null ,
    r86_fec_camprec datetime year to second,
    r86_precio_nue decimal(11,2) not null ,
    r86_reversado char(1) not null ,
    
    check (r86_reversado IN ('S' ,'N' )) constraint "fobos".ck_01_rept086
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".rept086 from "public";

{ TABLE "fobos".rolt064 row size = 114 number of columns = 16 index size = 82 }
create table "fobos".rolt064 
  (
    n64_compania integer not null ,
    n64_num_prest integer not null ,
    n64_cod_rubro smallint not null ,
    n64_cod_trab integer not null ,
    n64_estado char(1) not null ,
    n64_referencia varchar(30,15) not null ,
    n64_fecha date not null ,
    n64_porc_interes decimal(5,2) not null ,
    n64_val_prest decimal(12,2) not null ,
    n64_val_interes decimal(12,2) not null ,
    n64_descontado decimal(12,2) not null ,
    n64_moneda char(2) not null ,
    n64_paridad decimal(16,9) not null ,
    n64_fec_elimi datetime year to second,
    n64_usuario varchar(10,5) not null ,
    n64_fecing datetime year to second not null ,
    
    check (n64_estado IN ('A' ,'P' ,'E' ))
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".rolt064 from "public";

{ TABLE "fobos".gent039 row size = 45 number of columns = 10 index size = 94 }
create table "fobos".gent039 
  (
    g39_compania integer not null ,
    g39_localidad smallint not null ,
    g39_tipo_doc char(2) not null ,
    g39_secuencia smallint not null ,
    g39_fec_entrega date not null ,
    g39_num_sri_ini integer not null ,
    g39_num_sri_fin integer not null ,
    g39_num_dias_col integer not null ,
    g39_usuario varchar(10,5) not null ,
    g39_fecing datetime year to second not null 
  )  extent size 16 next size 16 lock mode page;
revoke all on "fobos".gent039 from "public";

{ TABLE "fobos".te_019 row size = 329 number of columns = 37 index size = 0 }
create table "fobos".te_019 
  (
    t19_compania integer not null ,
    t19_localidad smallint not null ,
    t19_cod_tran char(2) not null ,
    t19_num_tran decimal(15,0) not null ,
    t19_cod_subtipo integer,
    t19_cont_cred char(1) not null ,
    t19_ped_cliente char(10),
    t19_referencia varchar(40,20),
    t19_codcli integer,
    t19_nomcli varchar(50,20) not null ,
    t19_dircli varchar(40,20) not null ,
    t19_telcli char(10),
    t19_cedruc char(15) not null ,
    t19_vendedor smallint not null ,
    t19_oc_externa varchar(15,8),
    t19_oc_interna integer,
    t19_ord_trabajo integer,
    t19_descuento decimal(4,2) not null ,
    t19_porc_impto decimal(4,2) not null ,
    t19_tipo_dev char(2),
    t19_num_dev decimal(15,0),
    t19_bodega_ori char(2) not null ,
    t19_bodega_dest char(2) not null ,
    t19_fact_costo decimal(9,2),
    t19_fact_venta decimal(9,2),
    t19_moneda char(2) not null ,
    t19_paridad decimal(16,9) not null ,
    t19_precision smallint not null ,
    t19_tot_costo decimal(12,2) not null ,
    t19_tot_bruto decimal(12,2) not null ,
    t19_tot_dscto decimal(11,2) not null ,
    t19_tot_neto decimal(12,2) not null ,
    t19_flete decimal(11,2) not null ,
    t19_numliq integer,
    t19_num_ret integer,
    t19_usuario varchar(10,5) not null ,
    t19_fecing datetime year to second not null ,
    
    check (t19_cont_cred IN ('C' ,'R' )),
    
    check (t19_precision IN (0 ,1 ,2 ))
  )  extent size 16 next size 16 lock mode page;
revoke all on "fobos".te_019 from "public";

{ TABLE "fobos".te_020 row size = 158 number of columns = 27 index size = 60 }
create table "fobos".te_020 
  (
    t20_compania integer not null ,
    t20_localidad smallint not null ,
    t20_cod_tran char(2) not null ,
    t20_num_tran decimal(15,0) not null ,
    t20_bodega char(2) not null ,
    t20_item char(15) not null ,
    t20_orden smallint not null ,
    t20_cant_ped decimal(8,2) not null ,
    t20_cant_ven decimal(8,2) not null ,
    t20_cant_dev decimal(8,2) not null ,
    t20_cant_ent decimal(8,2) not null ,
    t20_descuento decimal(4,2) not null ,
    t20_val_descto decimal(10,2) not null ,
    t20_precio decimal(13,4) not null ,
    t20_val_impto decimal(11,2) not null ,
    t20_costo decimal(13,4) not null ,
    t20_fob decimal(11,2) not null ,
    t20_linea char(5) not null ,
    t20_rotacion char(2) not null ,
    t20_ubicacion char(10) not null ,
    t20_costant_mb decimal(11,2) not null ,
    t20_costant_ma decimal(11,2) not null ,
    t20_costnue_mb decimal(11,2) not null ,
    t20_costnue_ma decimal(11,2) not null ,
    t20_stock_ant decimal(8,2) not null ,
    t20_stock_bd decimal(8,2) not null ,
    t20_fecing datetime year to second not null ,
    primary key (t20_compania,t20_localidad,t20_cod_tran,t20_num_tran,t20_bodega,t20_item,t20_orden) 
               constraint "fobos".pk_te_020
  )  extent size 16 next size 16 lock mode page;
revoke all on "fobos".te_020 from "public";

{ TABLE "fobos".rept087 row size = 56 number of columns = 8 index size = 75 }
create table "fobos".rept087 
  (
    r87_compania integer not null ,
    r87_localidad smallint not null ,
    r87_item char(15) not null ,
    r87_secuencia smallint not null ,
    r87_precio_act decimal(11,2) not null ,
    r87_precio_ant decimal(11,2) not null ,
    r87_usu_camprec varchar(10,5) not null ,
    r87_fec_camprec datetime year to second not null 
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".rept087 from "public";

{ TABLE "fobos".cajt090 row size = 15 number of columns = 3 index size = 34 }
create table "fobos".cajt090 
  (
    j90_localidad smallint not null ,
    j90_codigo_caja smallint not null ,
    j90_usua_caja varchar(10,5) not null 
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".cajt090 from "public";

{ TABLE "fobos".rept089 row size = 106 number of columns = 18 index size = 250 }
create table "fobos".rept089 
  (
    r89_compania integer not null ,
    r89_localidad smallint not null ,
    r89_bodega char(2) not null ,
    r89_item char(15) not null ,
    r89_usuario varchar(10,5) not null ,
    r89_anio smallint not null ,
    r89_mes smallint not null ,
    r89_secuencia integer not null ,
    r89_stock_act decimal(8,2) not null ,
    r89_fec_corte datetime year to second not null ,
    r89_bueno decimal(8,2) 
        default 0.00 not null ,
    r89_incompleto decimal(8,2) 
        default 0.00 not null ,
    r89_mal_est decimal(8,2) 
        default 0.00 not null ,
    r89_suma decimal(8,2) 
        default 0.00 not null ,
    r89_fecha date not null ,
    r89_usu_modifi varchar(10,5),
    r89_fec_modifi datetime year to second,
    r89_fecing datetime year to second not null 
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".rept089 from "public";

{ TABLE "fobos".rept093 row size = 81 number of columns = 10 index size = 93 }
create table "fobos".rept093 
  (
    r93_compania integer not null ,
    r93_item char(15) not null ,
    r93_cod_pedido char(20) not null ,
    r93_stock_max integer not null ,
    r93_stock_min integer not null ,
    r93_stock_act decimal(8,2) not null ,
    r93_cantpend decimal(8,2) not null ,
    r93_cantpedir decimal(8,2) not null ,
    r93_usuario varchar(10,5) not null ,
    r93_fecing datetime year to second not null 
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".rept093 from "public";

{ TABLE "fobos".ctbt050 row size = 37 number of columns = 6 index size = 82 }
create table "fobos".ctbt050 
  (
    b50_compania integer not null ,
    b50_tipo_comp char(2) not null ,
    b50_num_comp char(8) not null ,
    b50_anio integer not null ,
    b50_usuario varchar(10,5) not null ,
    b50_fecing datetime year to second not null 
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".ctbt050 from "public";

{ TABLE "fobos".gent057 row size = 46 number of columns = 6 index size = 127 }
create table "fobos".gent057 
  (
    g57_user varchar(10,5) not null ,
    g57_compania integer not null ,
    g57_modulo char(2) not null ,
    g57_proceso char(10) not null ,
    g57_usuario varchar(10,5) not null ,
    g57_fecing datetime year to second not null 
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".gent057 from "public";

{ TABLE "fobos".actt014 row size = 177 number of columns = 28 index size = 169 }
create table "fobos".actt014 
  (
    a14_compania integer not null ,
    a14_codigo_bien integer not null ,
    a14_anio smallint not null ,
    a14_mes smallint not null ,
    a14_referencia varchar(40,20) not null ,
    a14_grupo_act smallint not null ,
    a14_tipo_act smallint not null ,
    a14_anos_util smallint not null ,
    a14_porc_deprec decimal(4,2) not null ,
    a14_locali_ori smallint not null ,
    a14_localidad smallint not null ,
    a14_cod_depto smallint not null ,
    a14_moneda char(2) not null ,
    a14_paridad decimal(16,9) not null ,
    a14_valor decimal(12,2) not null ,
    a14_valor_mb decimal(12,2) not null ,
    a14_fecha_baja date,
    a14_val_dep_mb decimal(11,2) not null ,
    a14_val_dep_ma decimal(11,2) not null ,
    a14_dep_acum_act decimal(14,2) not null ,
    a14_tot_dep_mb decimal(12,2) not null ,
    a14_tot_dep_ma decimal(12,2) not null ,
    a14_tot_reexpr decimal(12,2) not null ,
    a14_tot_dep_ree decimal(12,2) not null ,
    a14_tipo_comp char(2),
    a14_num_comp char(8),
    a14_usuario varchar(10,5) not null ,
    a14_fecing datetime year to second not null 
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".actt014 from "public";

{ TABLE "fobos".cxct001 row size = 318 number of columns = 20 index size = 58 }
create table "fobos".cxct001 
  (
    z01_codcli integer not null ,
    z01_estado char(1) not null ,
    z01_nomcli varchar(100,50) not null ,
    z01_direccion1 varchar(40,20) not null ,
    z01_direccion2 varchar(40,20),
    z01_telefono1 char(10) not null ,
    z01_telefono2 char(10),
    z01_fax1 char(11),
    z01_fax2 char(11),
    z01_casilla char(10),
    z01_pais integer not null ,
    z01_ciudad integer not null ,
    z01_tipo_clte smallint not null ,
    z01_personeria char(1) not null ,
    z01_tipo_doc_id char(1) not null ,
    z01_num_doc_id char(15) not null ,
    z01_rep_legal varchar(30,15),
    z01_paga_impto char(1) not null ,
    z01_usuario varchar(10,5) not null ,
    z01_fecing datetime year to second not null ,
    
    check (z01_estado IN ('A' ,'B' )),
    
    check (z01_personeria IN ('N' ,'J' )),
    
    check (z01_tipo_doc_id IN ('C' ,'P' ,'R' )),
    
    check (z01_paga_impto IN ('S' ,'N' ))
  )  extent size 1178 next size 117 lock mode row;
revoke all on "fobos".cxct001 from "public";

{ TABLE "fobos".tr_cxct001 row size = 318 number of columns = 20 index size = 12 
              }
create table "fobos".tr_cxct001 
  (
    z01_codcli integer not null ,
    z01_estado char(1) not null ,
    z01_nomcli varchar(100,50) not null ,
    z01_direccion1 varchar(40,20) not null ,
    z01_direccion2 varchar(40,20),
    z01_telefono1 char(10) not null ,
    z01_telefono2 char(10),
    z01_fax1 char(11),
    z01_fax2 char(11),
    z01_casilla char(10),
    z01_pais integer not null ,
    z01_ciudad integer not null ,
    z01_tipo_clte smallint not null ,
    z01_personeria char(1) not null ,
    z01_tipo_doc_id char(1) not null ,
    z01_num_doc_id char(15) not null ,
    z01_rep_legal varchar(30,15),
    z01_paga_impto char(1) not null ,
    z01_usuario varchar(10,5) not null ,
    z01_fecing datetime year to second not null ,
    
    check (z01_estado IN ('A' ,'B' )),
    
    check (z01_personeria IN ('N' ,'J' )),
    
    check (z01_tipo_doc_id IN ('C' ,'P' ,'R' )),
    
    check (z01_paga_impto IN ('S' ,'N' ))
  )  extent size 41 next size 16 lock mode row;
revoke all on "fobos".tr_cxct001 from "public";

{ TABLE "fobos".cajt010 row size = 325 number of columns = 21 index size = 175 }
create table "fobos".cajt010 
  (
    j10_compania integer not null ,
    j10_localidad smallint not null ,
    j10_tipo_fuente char(2) not null ,
    j10_num_fuente integer not null ,
    j10_areaneg smallint,
    j10_estado char(1) not null ,
    j10_codcli integer,
    j10_nomcli varchar(100,50) not null ,
    j10_moneda char(2) not null ,
    j10_valor decimal(12,2) not null ,
    j10_fecha_pro datetime year to second,
    j10_codigo_caja smallint,
    j10_tipo_destino char(2),
    j10_num_destino char(15),
    j10_referencia varchar(120),
    j10_banco integer,
    j10_numero_cta char(15),
    j10_tip_contable char(2),
    j10_num_contable char(8),
    j10_usuario varchar(10,5) not null ,
    j10_fecing datetime year to second not null ,
    
    check (j10_tipo_fuente IN ('PR' ,'PV' ,'OT' ,'SC' ,'OI' ,'EC' )),
    
    check (j10_estado IN ('A' ,'E' ,'P' ,'*' ))
  )  extent size 5451 next size 545 lock mode row;
revoke all on "fobos".cajt010 from "public";

{ TABLE "fobos".rept021 row size = 451 number of columns = 36 index size = 291 }
create table "fobos".rept021 
  (
    r21_compania integer not null ,
    r21_localidad smallint not null ,
    r21_numprof integer not null ,
    r21_grupo_linea char(5) not null ,
    r21_modelo varchar(20,10) not null ,
    r21_forma_pago varchar(40,20) not null ,
    r21_referencia varchar(40,20),
    r21_atencion varchar(40,20),
    r21_codcli integer,
    r21_nomcli varchar(100,50) not null ,
    r21_dircli varchar(40,20) not null ,
    r21_telcli char(15),
    r21_cedruc char(15) not null ,
    r21_vendedor smallint not null ,
    r21_descuento decimal(4,2) not null ,
    r21_porc_impto decimal(4,2) not null ,
    r21_bodega char(2) not null ,
    r21_moneda char(2) not null ,
    r21_tot_costo decimal(12,2) not null ,
    r21_tot_bruto decimal(12,2) not null ,
    r21_tot_dscto decimal(11,2) not null ,
    r21_tot_neto decimal(12,2) not null ,
    r21_flete decimal(11,2) not null ,
    r21_precision smallint not null ,
    r21_dias_prof smallint not null ,
    r21_factor_fob decimal(4,2),
    r21_factor_prec decimal(6,4),
    r21_cod_tran char(2),
    r21_num_tran decimal(15,0),
    r21_num_presup integer,
    r21_num_ot integer,
    r21_trans_fact char(1) not null ,
    r21_usr_tr_fa varchar(10,5),
    r21_fec_tr_fa datetime year to second,
    r21_usuario varchar(10,5) not null ,
    r21_fecing datetime year to second not null ,
    
    check (r21_precision IN (0 ,1 ,2 )),
    
    check (r21_trans_fact IN ('S' ,'N' )) constraint "fobos".ck_02_rept021
  )  extent size 9135 next size 913 lock mode row;
revoke all on "fobos".rept021 from "public";

{ TABLE "fobos".rept023 row size = 352 number of columns = 32 index size = 202 }
create table "fobos".rept023 
  (
    r23_compania integer not null ,
    r23_localidad smallint not null ,
    r23_numprev integer not null ,
    r23_estado char(1) not null ,
    r23_grupo_linea char(5) not null ,
    r23_ped_cliente char(10),
    r23_cont_cred char(1) not null ,
    r23_referencia varchar(40,20),
    r23_codcli integer,
    r23_nomcli varchar(100,50) not null ,
    r23_dircli varchar(40,20) not null ,
    r23_telcli char(10),
    r23_cedruc char(15) not null ,
    r23_ord_compra varchar(15,8),
    r23_vendedor smallint not null ,
    r23_descuento decimal(4,2) not null ,
    r23_porc_impto decimal(4,2) not null ,
    r23_bodega char(2) not null ,
    r23_moneda char(2) not null ,
    r23_paridad decimal(16,9) not null ,
    r23_precision smallint not null ,
    r23_tot_costo decimal(12,2) not null ,
    r23_tot_bruto decimal(12,2) not null ,
    r23_tot_dscto decimal(11,2) not null ,
    r23_tot_neto decimal(12,2) not null ,
    r23_flete decimal(11,2) not null ,
    r23_cod_tran char(2),
    r23_num_tran decimal(15,0),
    r23_numprof integer,
    r23_num_ot integer,
    r23_usuario varchar(10,5) not null ,
    r23_fecing datetime year to second not null ,
    
    check (r23_estado IN ('A' ,'N' ,'P' ,'F' )),
    
    check (r23_cont_cred IN ('C' ,'R' )),
    
    check (r23_precision IN (0 ,1 ,2 ))
  )  extent size 3484 next size 348 lock mode row;
revoke all on "fobos".rept023 from "public";

{ TABLE "fobos".rept088 row size = 254 number of columns = 18 index size = 64 }
create table "fobos".rept088 
  (
    r88_compania integer not null ,
    r88_localidad smallint not null ,
    r88_cod_fact char(2) not null ,
    r88_num_fact decimal(15,0) not null ,
    r88_motivo_refact varchar(70,20) not null ,
    r88_numprev integer not null ,
    r88_numprof integer not null ,
    r88_cod_dev char(2),
    r88_num_dev decimal(15,0),
    r88_numprof_nue integer,
    r88_numprev_nue integer,
    r88_cod_fact_nue char(2),
    r88_num_fact_nue decimal(15,0),
    r88_codcli_nue integer,
    r88_nomcli_nue varchar(100,50),
    r88_ord_trabajo integer,
    r88_usuario varchar(10,5) not null ,
    r88_fecing datetime year to second not null 
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".rept088 from "public";

{ TABLE "fobos".rept091 row size = 379 number of columns = 37 index size = 31 }
create table "fobos".rept091 
  (
    r91_compania integer not null ,
    r91_localidad smallint not null ,
    r91_cod_tran char(2) not null ,
    r91_num_tran decimal(15,0) not null ,
    r91_cod_subtipo integer,
    r91_cont_cred char(1) not null ,
    r91_ped_cliente char(10),
    r91_referencia varchar(40,20),
    r91_codcli integer,
    r91_nomcli varchar(100,50) not null ,
    r91_dircli varchar(40,20) not null ,
    r91_telcli char(10),
    r91_cedruc char(15) not null ,
    r91_vendedor smallint not null ,
    r91_oc_externa varchar(15,8),
    r91_oc_interna integer,
    r91_ord_trabajo integer,
    r91_descuento decimal(4,2) not null ,
    r91_porc_impto decimal(4,2) not null ,
    r91_tipo_dev char(2),
    r91_num_dev decimal(15,0),
    r91_bodega_ori char(2) not null ,
    r91_bodega_dest char(2) not null ,
    r91_fact_costo decimal(9,2),
    r91_fact_venta decimal(9,2),
    r91_moneda char(2) not null ,
    r91_paridad decimal(16,9) not null ,
    r91_precision smallint not null ,
    r91_tot_costo decimal(12,2) not null ,
    r91_tot_bruto decimal(12,2) not null ,
    r91_tot_dscto decimal(11,2) not null ,
    r91_tot_neto decimal(12,2) not null ,
    r91_flete decimal(11,2) not null ,
    r91_numliq integer,
    r91_num_ret integer,
    r91_usuario varchar(10,5) not null ,
    r91_fecing datetime year to second not null ,
    
    check (r91_cont_cred IN ('C' ,'R' )),
    
    check (r91_precision IN (0 ,1 ,2 ))
  )  extent size 62 next size 16 lock mode row;
revoke all on "fobos".rept091 from "public";

{ TABLE "fobos".talt020 row size = 486 number of columns = 32 index size = 124 }
create table "fobos".talt020 
  (
    t20_compania integer not null ,
    t20_localidad smallint not null ,
    t20_numpre integer not null ,
    t20_estado char(1) not null ,
    t20_cod_cliente integer,
    t20_nom_cliente varchar(100,50) not null ,
    t20_tel_cliente char(10),
    t20_dir_cliente varchar(40,20),
    t20_cedruc char(15) not null ,
    t20_motivo varchar(120,60) not null ,
    t20_recargo_mo smallint not null ,
    t20_recargo_rp smallint not null ,
    t20_moneda char(2) not null ,
    t20_precision smallint not null ,
    t20_total_mo decimal(11,2) not null ,
    t20_total_rp decimal(11,2) not null ,
    t20_mano_ext decimal(11,2) not null ,
    t20_por_mo_tal decimal(4,2) not null ,
    t20_vde_mo_tal decimal(10,2) not null ,
    t20_total_impto decimal(11,2) not null ,
    t20_otros_mat decimal(11,2) not null ,
    t20_gastos decimal(11,2) not null ,
    t20_total_neto decimal(11,2) not null ,
    t20_user_aprob varchar(10,5),
    t20_fecha_aprob datetime year to second,
    t20_observaciones varchar(40,20),
    t20_fec_modifi datetime year to second,
    t20_usu_modifi varchar(10,5),
    t20_fec_elimin datetime year to second,
    t20_usu_elimin varchar(10,5),
    t20_usuario varchar(10,5) not null ,
    t20_fecing datetime year to second not null ,
    
    check (t20_estado IN ('A' ,'P' ,'E' )) constraint "fobos".ck_01_talt020
  )  extent size 136 next size 16 lock mode row;
revoke all on "fobos".talt020 from "public";

{ TABLE "fobos".talt023 row size = 625 number of columns = 59 index size = 373 }
create table "fobos".talt023 
  (
    t23_compania integer not null ,
    t23_localidad smallint not null ,
    t23_orden integer not null ,
    t23_estado char(1) not null ,
    t23_tipo_ot char(1) not null ,
    t23_subtipo_ot char(1) not null ,
    t23_descripcion varchar(120,60),
    t23_cod_cliente integer,
    t23_nom_cliente varchar(100,50) not null ,
    t23_tel_cliente char(10),
    t23_dir_cliente varchar(40,20),
    t23_cedruc char(15) not null ,
    t23_codcli_est integer,
    t23_numpre integer,
    t23_valor_tope decimal(11,2),
    t23_seccion smallint not null ,
    t23_cod_asesor smallint not null ,
    t23_cod_mecani smallint not null ,
    t23_moneda char(2) not null ,
    t23_paridad decimal(16,9) not null ,
    t23_precision smallint not null ,
    t23_fecini date not null ,
    t23_fecfin date not null ,
    t23_cont_cred char(1) not null ,
    t23_porc_impto decimal(4,2) not null ,
    t23_modelo char(15),
    t23_chasis char(25),
    t23_placa char(10),
    t23_color char(15),
    t23_kilometraje integer,
    t23_orden_cheq integer,
    t23_val_mo_tal decimal(11,2) not null ,
    t23_val_mo_ext decimal(11,2) not null ,
    t23_val_mo_cti decimal(11,2) not null ,
    t23_val_rp_tal decimal(11,2) not null ,
    t23_val_rp_ext decimal(11,2) not null ,
    t23_val_rp_cti decimal(11,2) not null ,
    t23_val_rp_alm decimal(11,2) not null ,
    t23_val_otros1 decimal(11,2) not null ,
    t23_val_otros2 decimal(11,2) not null ,
    t23_por_mo_tal decimal(4,2) not null ,
    t23_por_rp_tal decimal(4,2) not null ,
    t23_por_rp_alm decimal(4,2) not null ,
    t23_vde_mo_tal decimal(10,2) not null ,
    t23_vde_rp_tal decimal(10,2) not null ,
    t23_vde_rp_alm decimal(10,2) not null ,
    t23_tot_bruto decimal(12,2) not null ,
    t23_tot_dscto decimal(11,2) not null ,
    t23_val_impto decimal(11,2) not null ,
    t23_tot_neto decimal(12,2) not null ,
    t23_fec_cierre datetime year to second,
    t23_num_factura decimal(15,0),
    t23_fec_factura datetime year to second,
    t23_fec_modifi datetime year to second,
    t23_usu_modifi varchar(10,5),
    t23_fec_elimin datetime year to second,
    t23_usu_elimin varchar(10,5),
    t23_usuario varchar(10,5) not null ,
    t23_fecing datetime year to second not null ,
    
    check (t23_estado IN ('A' ,'C' ,'F' ,'E' ,'D' )),
    
    check (t23_precision IN (0 ,1 ,2 )),
    
    check (t23_cont_cred IN ('C' ,'R' ))
  )  extent size 220 next size 22 lock mode row;
revoke all on "fobos".talt023 from "public";

{ TABLE "fobos".cxpt001 row size = 418 number of columns = 24 index size = 58 }
create table "fobos".cxpt001 
  (
    p01_codprov integer not null ,
    p01_estado char(1) not null ,
    p01_nomprov varchar(100,50) not null ,
    p01_direccion1 varchar(120,20) not null ,
    p01_direccion2 varchar(40,20),
    p01_telefono1 char(11) not null ,
    p01_telefono2 char(11),
    p01_fax1 char(11),
    p01_fax2 char(11),
    p01_casilla char(10),
    p01_pais integer not null ,
    p01_ciudad integer not null ,
    p01_tipo_prov smallint not null ,
    p01_personeria char(1) not null ,
    p01_tipo_doc char(1) not null ,
    p01_num_doc char(15) not null ,
    p01_rep_legal varchar(30,15),
    p01_cont_espe char(1) not null ,
    p01_ret_fuente char(1) not null ,
    p01_ret_impto char(1) not null ,
    p01_serie_comp char(6),
    p01_num_aut char(10),
    p01_usuario varchar(10,5) not null ,
    p01_fecing datetime year to second not null ,
    
    check (p01_estado IN ('A' ,'B' )),
    
    check (p01_personeria IN ('N' ,'J' )),
    
    check (p01_tipo_doc IN ('C' ,'P' ,'R' )),
    
    check (p01_cont_espe IN ('S' ,'N' )),
    
    check (p01_ret_fuente IN ('S' ,'N' )),
    
    check (p01_ret_impto IN ('S' ,'N' ))
  )  extent size 120 next size 16 lock mode row;
revoke all on "fobos".cxpt001 from "public";

{ TABLE "fobos".rept081 row size = 941 number of columns = 36 index size = 109 }
create table "fobos".rept081 
  (
    r81_compania integer not null ,
    r81_localidad smallint not null ,
    r81_pedido char(10) not null ,
    r81_moneda_base char(2) not null ,
    r81_paridad_div decimal(22,15) not null ,
    r81_fecha varchar(25,15) not null ,
    r81_cod_prov integer not null ,
    r81_nom_prov varchar(100,50) not null ,
    r81_dir_prov varchar(120,20) not null ,
    r81_ciu_prov varchar(30,15) not null ,
    r81_est_prov varchar(30,15),
    r81_pai_prov varchar(30,15) not null ,
    r81_tel_prov varchar(20,10) not null ,
    r81_fax_prov varchar(20,10) not null ,
    r81_email_prov varchar(40,20) not null ,
    r81_pagador varchar(40,20) not null ,
    r81_forma_pago varchar(40,20) not null ,
    r81_tipo_fact_pre char(6) not null ,
    r81_tot_exfab decimal(22,10) not null ,
    r81_tot_desp_mi decimal(22,10) not null ,
    r81_tot_fob_mi decimal(22,10) not null ,
    r81_tot_fob_mb decimal(22,10) not null ,
    r81_tot_flete decimal(22,10) not null ,
    r81_tot_car_fle decimal(22,10) not null ,
    r81_tot_seguro decimal(22,10) not null ,
    r81_tot_seg_neto decimal(22,10) not null ,
    r81_tot_cargos_mb decimal(22,10) not null ,
    r81_pais_origen varchar(30,15) not null ,
    r81_marcas varchar(40,20) not null ,
    r81_puerto_ori varchar(40,20) not null ,
    r81_puerto_dest varchar(40,20) not null ,
    r81_tipo_embal varchar(40,20) not null ,
    r81_tipo_trans varchar(30,15) not null ,
    r81_tipo_seguro varchar(40,20) not null ,
    r81_usuario varchar(10,5) not null ,
    r81_fecing datetime year to second not null 
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".rept081 from "public";

{ TABLE "fobos".talt061 row size = 8 number of columns = 3 index size = 48 }
create table "fobos".talt061 
  (
    t61_compania integer not null ,
    t61_cod_asesor smallint not null ,
    t61_cod_vendedor smallint not null 
  )  extent size 16 next size 16 lock mode page;
revoke all on "fobos".talt061 from "public";

{ TABLE "fobos".rept094 row size = 47 number of columns = 10 index size = 31 }
create table "fobos".rept094 
  (
    r94_compania integer not null ,
    r94_localidad smallint not null ,
    r94_cod_tran char(2) not null ,
    r94_num_tran decimal(15,0) not null ,
    r94_fecing datetime year to second not null ,
    r94_locali_fin smallint 
        default 3 not null ,
    r94_codtra_fin char(2),
    r94_numtra_fin decimal(15,0),
    r94_fecing_fin datetime year to second 
        default current year to second,
    r94_traspasada char(1) not null ,
    
    check (r94_traspasada IN ('S' ,'N' ))
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".rept094 from "public";

{ TABLE "fobos".cxct060 row size = 33 number of columns = 6 index size = 15 }
create table "fobos".cxct060 
  (
    z60_compania integer not null ,
    z60_localidad smallint not null ,
    z60_fecha_carga date not null ,
    z60_fecha_arran date not null ,
    z60_usuario varchar(10,5) not null ,
    z60_fecing datetime year to second not null 
  )  extent size 16 next size 16 lock mode page;
revoke all on "fobos".cxct060 from "public";

{ TABLE "fobos".talt060 row size = 236 number of columns = 12 index size = 132 }
create table "fobos".talt060 
  (
    t60_compania integer not null ,
    t60_localidad smallint not null ,
    t60_ot_ant integer not null ,
    t60_fac_ant decimal(15,0) not null ,
    t60_motivo_refact varchar(70,20) not null ,
    t60_num_dev decimal(15,0),
    t60_ot_nue integer,
    t60_fac_nue decimal(15,0),
    t60_codcli_nue integer,
    t60_nomcli_nue varchar(100,50),
    t60_usuario varchar(10,5) not null ,
    t60_fecing datetime year to second not null 
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".talt060 from "public";

{ TABLE "fobos".prueba06 row size = 24 number of columns = 3 index size = 27 }
create table "fobos".prueba06 
  (
    c1 integer,
    c2 char(10),
    c3 char(10),
    primary key (c1,c2) 
  )  extent size 16 next size 16 lock mode page;
revoke all on "fobos".prueba06 from "public";

{ TABLE "fobos".tr_precios_ser row size = 30 number of columns = 4 index size = 72 
              }
create table "fobos".tr_precios_ser 
  (
    te_compania smallint not null ,
    te_item char(15) not null ,
    te_precio decimal(12,2) not null ,
    te_marca char(6) not null 
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".tr_precios_ser from "public";

{ TABLE "fobos".rept095 row size = 716 number of columns = 25 index size = 142 }
create table "fobos".rept095 
  (
    r95_compania integer not null ,
    r95_localidad smallint not null ,
    r95_guia_remision decimal(15,0) not null ,
    r95_estado char(1) not null ,
    r95_motivo char(1) not null ,
    r95_entre_local char(1) not null ,
    r95_fecha_initras date not null ,
    r95_fecha_fintras date,
    r95_fecha_emi date not null ,
    r95_punto_part varchar(150,80) not null ,
    r95_autoriz_sri varchar(15,10) not null ,
    r95_persona_guia varchar(100,70) not null ,
    r95_persona_id varchar(15,10) not null ,
    r95_persona_dest varchar(100,40) not null ,
    r95_pers_id_dest varchar(15,10) not null ,
    r95_punto_lleg varchar(150,80) not null ,
    r95_placa char(10),
    r95_num_sri char(21) not null ,
    r95_cod_zona smallint,
    r95_cod_subzona smallint,
    r95_usu_elim varchar(10,5),
    r95_fec_elim datetime year to second,
    r95_proc_orden varchar(60,40),
    r95_usuario varchar(10,5) not null ,
    r95_fecing datetime year to second not null ,
    
    check (r95_motivo IN ('V' ,'D' ,'I' ,'N' )) constraint "fobos".ck_01_rept095,
    
    check (r95_entre_local IN ('S' ,'N' )) constraint "fobos".ck_02_rept095,
    
    check (r95_estado IN ('A' ,'C' ,'E' )) constraint "fobos".ck_03_rept095
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".rept095 from "public";

{ TABLE "fobos".rept096 row size = 21 number of columns = 5 index size = 90 }
create table "fobos".rept096 
  (
    r96_compania integer not null ,
    r96_localidad smallint not null ,
    r96_guia_remision decimal(15,0) not null ,
    r96_bodega char(2) not null ,
    r96_num_entrega integer not null 
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".rept096 from "public";

{ TABLE "fobos".rept097 row size = 26 number of columns = 5 index size = 105 }
create table "fobos".rept097 
  (
    r97_compania integer not null ,
    r97_localidad smallint not null ,
    r97_guia_remision decimal(15,0) not null ,
    r97_cod_tran char(2) not null ,
    r97_num_tran decimal(15,0) not null 
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".rept097 from "public";

{ TABLE "fobos".cxct061 row size = 41 number of columns = 11 index size = 49 }
create table "fobos".cxct061 
  (
    z61_compania integer not null ,
    z61_localidad smallint not null ,
    z61_num_pagos smallint not null ,
    z61_max_pagos smallint not null ,
    z61_intereses decimal(5,2) not null ,
    z61_dia_entre_pago smallint not null ,
    z61_max_entre_pago smallint not null ,
    z61_credito_max smallint 
        default 0 not null ,
    z61_credito_min smallint 
        default 0 not null ,
    z61_usuario varchar(10,5) not null ,
    z61_fecing datetime year to second not null 
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".cxct061 from "public";

{ TABLE "fobos".cxct042 row size = 63 number of columns = 10 index size = 216 }
create table "fobos".cxct042 
  (
    z42_compania integer not null ,
    z42_localidad smallint not null ,
    z42_codcli integer not null ,
    z42_tipo_doc char(2) not null ,
    z42_num_doc char(15) not null ,
    z42_dividendo smallint not null ,
    z42_banco smallint not null ,
    z42_num_cta char(15) not null ,
    z42_num_cheque char(15) not null ,
    z42_secuencia smallint not null 
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".cxct042 from "public";

{ TABLE "fobos".ordt003 row size = 284 number of columns = 16 index size = 142 }
create table "fobos".ordt003 
  (
    c03_compania integer not null ,
    c03_tipo_ret char(1) not null ,
    c03_porcentaje decimal(5,2) not null ,
    c03_codigo_sri char(6) not null ,
    c03_fecha_ini_porc date not null ,
    c03_estado char(1) not null ,
    c03_concepto_ret varchar(200,100) not null ,
    c03_fecha_fin_porc date,
    c03_ingresa_proc char(1) not null ,
    c03_tipo_fuente char(1) not null ,
    c03_usuario_modifi varchar(10,5),
    c03_fecha_modifi datetime year to second,
    c03_usuario_elimin varchar(10,5),
    c03_fecha_elimin datetime year to second,
    c03_usuario varchar(10,5) not null ,
    c03_fecing datetime year to second not null ,
    
    check (c03_tipo_ret IN ('F' ,'I' )) constraint "fobos".ck_01_ordt003,
    
    check (c03_estado IN ('A' ,'E' )) constraint "fobos".ck_02_ordt003,
    
    check (c03_ingresa_proc IN ('S' ,'N' )) constraint "fobos".ck_03_ordt003,
    
    check (c03_tipo_fuente IN ('B' ,'S' ,'T' )) constraint "fobos".ck_04_ordt003
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".ordt003 from "public";

{ TABLE "fobos".srit000 row size = 35 number of columns = 8 index size = 34 }
create table "fobos".srit000 
  (
    s00_compania integer not null ,
    s00_ano_proceso integer not null ,
    s00_mes_proceso smallint not null ,
    s00_dias_ane_vta smallint not null ,
    s00_dias_ane_com smallint not null ,
    s00_dias_ret smallint not null ,
    s00_usuario varchar(10,5) not null ,
    s00_fecing datetime year to second not null 
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".srit000 from "public";

{ TABLE "fobos".srit001 row size = 46 number of columns = 5 index size = 49 }
create table "fobos".srit001 
  (
    s01_compania integer not null ,
    s01_codigo smallint not null ,
    s01_descripcion varchar(20,10) not null ,
    s01_usuario varchar(10,5) not null ,
    s01_fecing datetime year to second not null 
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".srit001 from "public";

{ TABLE "fobos".srit002 row size = 39 number of columns = 6 index size = 52 }
create table "fobos".srit002 
  (
    s02_compania integer not null ,
    s02_ano smallint not null ,
    s02_mes_num char(2) not null ,
    s02_mes_nom varchar(11,10) not null ,
    s02_usuario varchar(10,5) not null ,
    s02_fecing datetime year to second not null 
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".srit002 from "public";

{ TABLE "fobos".srit003 row size = 26 number of columns = 5 index size = 51 }
create table "fobos".srit003 
  (
    s03_compania integer not null ,
    s03_codigo char(2) not null ,
    s03_cod_ident char(1) not null ,
    s03_usuario varchar(10,5) not null ,
    s03_fecing datetime year to second not null ,
    
    check (s03_cod_ident IN ('R' ,'C' ,'P' ,'F' ,'0' )) constraint "fobos".ck_01_srit003
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".srit003 from "public";

{ TABLE "fobos".srit004 row size = 60 number of columns = 6 index size = 49 }
create table "fobos".srit004 
  (
    s04_compania integer not null ,
    s04_codigo smallint not null ,
    s04_descripcion varchar(30,15) not null ,
    s04_fecha_vig date,
    s04_usuario varchar(10,5) not null ,
    s04_fecing datetime year to second not null 
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".srit004 from "public";

{ TABLE "fobos".srit005 row size = 56 number of columns = 5 index size = 49 }
create table "fobos".srit005 
  (
    s05_compania integer not null ,
    s05_codigo smallint not null ,
    s05_descripcion varchar(30,15) not null ,
    s05_usuario varchar(10,5) not null ,
    s05_fecing datetime year to second not null 
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".srit005 from "public";

{ TABLE "fobos".srit006 row size = 127 number of columns = 6 index size = 49 }
create table "fobos".srit006 
  (
    s06_compania integer not null ,
    s06_codigo char(2) not null ,
    s06_descripcion varchar(100,60) not null ,
    s06_tributa char(1) not null ,
    s06_usuario varchar(10,5) not null ,
    s06_fecing datetime year to second not null ,
    
    check (s06_tributa IN ('S' ,'N' )) constraint "fobos".ck_01_srit006
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".srit006 from "public";

{ TABLE "fobos".srit007 row size = 8 number of columns = 3 index size = 48 }
create table "fobos".srit007 
  (
    s07_compania integer not null ,
    s07_tipo_comp smallint not null ,
    s07_sustento_tri char(2) not null 
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".srit007 from "public";

{ TABLE "fobos".srit008 row size = 37 number of columns = 7 index size = 49 }
create table "fobos".srit008 
  (
    s08_compania integer not null ,
    s08_codigo smallint not null ,
    s08_porcentaje decimal(5,2) not null ,
    s08_fecha_ini date not null ,
    s08_fecha_fin date,
    s08_usuario varchar(10,5) not null ,
    s08_fecing datetime year to second not null 
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".srit008 from "public";

{ TABLE "fobos".srit009 row size = 37 number of columns = 6 index size = 51 }
create table "fobos".srit009 
  (
    s09_compania integer not null ,
    s09_codigo smallint not null ,
    s09_tipo_porc char(1) not null ,
    s09_descripcion varchar(10,5) not null ,
    s09_usuario varchar(10,5) not null ,
    s09_fecing datetime year to second not null ,
    
    check (s09_tipo_porc IN ('S' ,'B' ,'T' )) constraint "fobos".ck_01_srit009
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".srit009 from "public";

{ TABLE "fobos".srit010 row size = 114 number of columns = 9 index size = 79 }
create table "fobos".srit010 
  (
    s10_compania integer not null ,
    s10_codigo smallint not null ,
    s10_porcentaje_ice decimal(5,2) not null ,
    s10_codigo_impto varchar(15,6) not null ,
    s10_descripcion varchar(60,30) not null ,
    s10_fecha_ini date not null ,
    s10_fecha_fin date,
    s10_usuario varchar(10,5) not null ,
    s10_fecing datetime year to second not null 
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".srit010 from "public";

{ TABLE "fobos".srit011 row size = 68 number of columns = 5 index size = 52 }
create table "fobos".srit011 
  (
    s11_compania integer not null ,
    s11_codigo char(4) not null ,
    s11_nombre_emi_tj varchar(40,15) not null ,
    s11_usuario varchar(10,5) not null ,
    s11_fecing datetime year to second not null 
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".srit011 from "public";

{ TABLE "fobos".srit012 row size = 55 number of columns = 5 index size = 48 }
create table "fobos".srit012 
  (
    s12_compania integer not null ,
    s12_codigo char(1) not null ,
    s12_nombre_ident varchar(30,15) not null ,
    s12_usuario varchar(10,5) not null ,
    s12_fecing datetime year to second not null 
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".srit012 from "public";

{ TABLE "fobos".srit013 row size = 108 number of columns = 5 index size = 52 }
create table "fobos".srit013 
  (
    s13_compania integer not null ,
    s13_codigo char(4) not null ,
    s13_descripcion varchar(80,40) not null ,
    s13_usuario varchar(10,5) not null ,
    s13_fecing datetime year to second not null 
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".srit013 from "public";

{ TABLE "fobos".srit014 row size = 243 number of columns = 9 index size = 61 }
create table "fobos".srit014 
  (
    s14_compania integer not null ,
    s14_codigo char(6) not null ,
    s14_porcentaje_ret decimal(5,2) not null ,
    s14_concepto_ret varchar(200,100) not null ,
    s14_fecha_ini_porc date not null ,
    s14_fecha_fin_porc date,
    s14_ingresa_proc char(1) not null ,
    s14_usuario varchar(10,5) not null ,
    s14_fecing datetime year to second not null ,
    
    check (s14_ingresa_proc IN ('S' ,'N' )) constraint "fobos".ck_01_srit014
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".srit014 from "public";

{ TABLE "fobos".srit015 row size = 98 number of columns = 8 index size = 49 }
create table "fobos".srit015 
  (
    s15_compania integer not null ,
    s15_codigo smallint not null ,
    s15_descrip_fid varchar(60,40) not null ,
    s15_codigo_ret char(4) not null ,
    s15_fecha_ini date not null ,
    s15_fecha_fin date,
    s15_usuario varchar(10,5) not null ,
    s15_fecing datetime year to second not null 
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".srit015 from "public";

{ TABLE "fobos".srit016 row size = 57 number of columns = 5 index size = 51 }
create table "fobos".srit016 
  (
    s16_compania integer not null ,
    s16_codigo char(3) not null ,
    s16_descripcion varchar(30,15) not null ,
    s16_usuario varchar(10,5) not null ,
    s16_fecing datetime year to second not null 
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".srit016 from "public";

{ TABLE "fobos".srit017 row size = 56 number of columns = 5 index size = 49 }
create table "fobos".srit017 
  (
    s17_compania integer not null ,
    s17_codigo smallint not null ,
    s17_descripcion varchar(30,15) not null ,
    s17_usuario varchar(10,5) not null ,
    s17_fecing datetime year to second not null 
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".srit017 from "public";

{ TABLE "fobos".srit018 row size = 9 number of columns = 4 index size = 51 }
create table "fobos".srit018 
  (
    s18_compania integer not null ,
    s18_sec_tran char(2) not null ,
    s18_cod_ident char(1) not null ,
    s18_tipo_tran smallint not null 
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".srit018 from "public";

{ TABLE "fobos".srit019 row size = 11 number of columns = 5 index size = 63 }
create table "fobos".srit019 
  (
    s19_compania integer not null ,
    s19_sec_tran char(2) not null ,
    s19_cod_ident char(1) not null ,
    s19_tipo_comp smallint not null ,
    s19_tipo_doc char(2) not null 
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".srit019 from "public";

{ TABLE "fobos".srit020 row size = 8 number of columns = 3 index size = 48 }
create table "fobos".srit020 
  (
    s20_compania integer not null ,
    s20_tipo_tran smallint not null ,
    s20_tipo_comp smallint not null 
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".srit020 from "public";

{ TABLE "fobos".srit021 row size = 171 number of columns = 34 index size = 91 }
create table "fobos".srit021 
  (
    s21_compania integer not null ,
    s21_localidad smallint not null ,
    s21_anio smallint not null ,
    s21_mes smallint not null ,
    s21_ident_cli char(2) not null ,
    s21_num_doc_id char(13) not null ,
    s21_tipo_comp char(2) not null ,
    s21_fecha_reg_cont date not null ,
    s21_num_comp_emi integer not null ,
    s21_fecha_emi_vta date not null ,
    s21_base_imp_tar_0 decimal(12,2) not null ,
    s21_iva_presuntivo char(1) not null ,
    s21_bas_imp_gr_iva decimal(12,2) not null ,
    s21_cod_porc_iva char(1) not null ,
    s21_monto_iva decimal(12,2) not null ,
    s21_base_imp_ice decimal(12,2) not null ,
    s21_cod_porc_ice char(2) not null ,
    s21_monto_ice decimal(12,2) not null ,
    s21_monto_iva_bie decimal(12,2) not null ,
    s21_cod_ret_ivabie char(1) not null ,
    s21_mon_ret_ivabie decimal(12,2) not null ,
    s21_monto_iva_ser decimal(12,2) not null ,
    s21_cod_ret_ivaser char(1) not null ,
    s21_mon_ret_ivaser decimal(12,2) not null ,
    s21_ret_presuntivo char(1) not null ,
    s21_concepto_ret char(5) not null ,
    s21_base_imp_renta decimal(12,2) not null ,
    s21_porc_ret_renta decimal(5,2) not null ,
    s21_monto_ret_rent decimal(12,2) not null ,
    s21_estado char(1) not null ,
    s21_usuario_modif varchar(10,5) 
        default null,
    s21_fec_modif datetime year to second 
        default null,
    s21_usuario varchar(10,5) not null ,
    s21_fecing datetime year to second not null ,
    
    check (s21_estado IN ('G' ,'P' ,'C' ,'D' )) constraint "fobos".ck_01_srit021,
    
    check (s21_iva_presuntivo IN ('S' ,'N' )) constraint "fobos".ck_02_srit021,
    
    check (s21_ret_presuntivo IN ('S' ,'N' )) constraint "fobos".ck_03_srit021
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".srit021 from "public";

{ TABLE "fobos".rept098 row size = 57 number of columns = 13 index size = 93 }
create table "fobos".rept098 
  (
    r98_compania integer not null ,
    r98_localidad smallint not null ,
    r98_vend_ant smallint not null ,
    r98_vend_nue smallint not null ,
    r98_secuencia integer not null ,
    r98_estado char(1) not null ,
    r98_codcli integer,
    r98_fecha_ini date,
    r98_fecha_fin date,
    r98_cod_tran char(2),
    r98_num_tran decimal(15,0),
    r98_usuario varchar(10,5) not null ,
    r98_fecing datetime year to second not null ,
    
    check (r98_estado IN ('P' ,'R' )) constraint "fobos".ck_01_rept098
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".rept098 from "public";

{ TABLE "fobos".rept099 row size = 27 number of columns = 8 index size = 88 }
create table "fobos".rept099 
  (
    r99_compania integer not null ,
    r99_localidad smallint not null ,
    r99_vend_ant smallint not null ,
    r99_vend_nue smallint not null ,
    r99_secuencia integer not null ,
    r99_orden smallint not null ,
    r99_cod_tran char(2) not null ,
    r99_num_tran decimal(15,0) not null 
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".rept099 from "public";

{ TABLE "fobos".rept020 row size = 158 number of columns = 27 index size = 210 }
create table "fobos".rept020 
  (
    r20_compania integer not null ,
    r20_localidad smallint not null ,
    r20_cod_tran char(2) not null ,
    r20_num_tran decimal(15,0) not null ,
    r20_bodega char(2) not null ,
    r20_item char(15) not null ,
    r20_orden smallint not null ,
    r20_cant_ped decimal(8,2) not null ,
    r20_cant_ven decimal(8,2) not null ,
    r20_cant_dev decimal(8,2) not null ,
    r20_cant_ent decimal(8,2) not null ,
    r20_descuento decimal(4,2) not null ,
    r20_val_descto decimal(10,2) not null ,
    r20_precio decimal(13,4) not null ,
    r20_val_impto decimal(11,2) not null ,
    r20_costo decimal(13,4) not null ,
    r20_fob decimal(11,2) not null ,
    r20_linea char(5) not null ,
    r20_rotacion char(2) not null ,
    r20_ubicacion char(10) not null ,
    r20_costant_mb decimal(11,2) not null ,
    r20_costant_ma decimal(11,2) not null ,
    r20_costnue_mb decimal(11,2) not null ,
    r20_costnue_ma decimal(11,2) not null ,
    r20_stock_ant decimal(8,2) not null ,
    r20_stock_bd decimal(8,2) not null ,
    r20_fecing datetime year to second not null ,
    primary key (r20_compania,r20_localidad,r20_cod_tran,r20_num_tran,r20_bodega,r20_item,r20_orden) 
               constraint "fobos".pk_rept020
  )  extent size 14653 next size 1465 lock mode row;
revoke all on "fobos".rept020 from "public";

{ TABLE "fobos".rolt056 row size = 104 number of columns = 13 index size = 268 }
create table "fobos".rolt056 
  (
    n56_compania integer not null ,
    n56_proceso char(2) not null ,
    n56_cod_depto smallint not null ,
    n56_cod_trab integer not null ,
    n56_estado char(1) not null ,
    n56_aux_val_vac char(12) not null ,
    n56_aux_val_adi char(12),
    n56_aux_otr_ing char(12),
    n56_aux_iess char(12),
    n56_aux_otr_egr char(12),
    n56_aux_banco char(12) not null ,
    n56_usuario varchar(10,5) not null ,
    n56_fecing datetime year to second not null ,
    
    check (n56_estado IN ('A' ,'B' )) constraint "fobos".ck_01_rolt056
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".rolt056 from "public";

{ TABLE "fobos".rolt057 row size = 28 number of columns = 7 index size = 117 }
create table "fobos".rolt057 
  (
    n57_compania integer not null ,
    n57_proceso char(2) not null ,
    n57_cod_trab integer not null ,
    n57_periodo_ini date not null ,
    n57_periodo_fin date not null ,
    n57_tipo_comp char(2) not null ,
    n57_num_comp char(8) not null 
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".rolt057 from "public";

{ TABLE "fobos".rolt090 row size = 50 number of columns = 17 index size = 34 }
create table "fobos".rolt090 
  (
    n90_compania integer not null ,
    n90_dias_anio smallint not null ,
    n90_dias_min_par smallint not null ,
    n90_tiem_max_vac smallint not null ,
    n90_dias_ano_vac smallint not null ,
    n90_anio_ini_vac smallint not null ,
    n90_gen_cont_vac char(1) not null ,
    n90_dias_ano_ant smallint not null ,
    n90_mes_gra_ant smallint not null ,
    n90_anio_ini_ant smallint not null ,
    n90_gen_cont_ant char(1) not null ,
    n90_porc_int_ant decimal(5,2) not null ,
    n90_dias_ano_ut smallint not null ,
    n90_anio_ini_ut smallint not null ,
    n90_gen_cont_ut char(1) not null ,
    n90_usuario varchar(10,5) not null ,
    n90_fecing datetime year to second not null ,
    
    check (n90_gen_cont_vac IN ('S' ,'N' )) constraint "fobos".ck_01_rolt090,
    
    check (n90_gen_cont_ant IN ('S' ,'N' )) constraint "fobos".ck_02_rolt090,
    
    check (n90_gen_cont_ut IN ('S' ,'N' )) constraint "fobos".ck_03_rolt090
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".rolt090 from "public";

{ TABLE "fobos".rolt058 row size = 54 number of columns = 10 index size = 70 }
create table "fobos".rolt058 
  (
    n58_compania integer not null ,
    n58_num_prest integer not null ,
    n58_proceso char(2) not null ,
    n58_div_act smallint not null ,
    n58_num_div smallint not null ,
    n58_valor_div decimal(12,2) not null ,
    n58_valor_dist decimal(12,2) not null ,
    n58_saldo_dist decimal(12,2) not null ,
    n58_usuario varchar(10,5) not null ,
    n58_fecing datetime year to second not null 
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".rolt058 from "public";

{ TABLE "fobos".rolt059 row size = 18 number of columns = 4 index size = 78 }
create table "fobos".rolt059 
  (
    n59_compania integer not null ,
    n59_num_prest integer not null ,
    n59_tipo_comp char(2) not null ,
    n59_num_comp char(8) not null 
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".rolt059 from "public";

{ TABLE "fobos".rolt091 row size = 184 number of columns = 24 index size = 174 }
create table "fobos".rolt091 
  (
    n91_compania integer not null ,
    n91_proceso char(2) not null ,
    n91_cod_trab integer not null ,
    n91_num_ant smallint not null ,
    n91_fecha_ant date not null ,
    n91_motivo_ant varchar(50,30) not null ,
    n91_prov_aport char(1) not null ,
    n91_valor_gan decimal(12,2) not null ,
    n91_val_vac_par decimal(12,2) not null ,
    n91_val_pro_apor decimal(11,2) not null ,
    n91_valor_tope decimal(12,2) not null ,
    n91_saldo_pend decimal(12,2) not null ,
    n91_valor_ant decimal(12,2) not null ,
    n91_tipo_pago char(1) not null ,
    n91_bco_empresa integer,
    n91_cta_empresa char(15),
    n91_cta_trabaj char(15),
    n91_proc_vac char(2),
    n91_periodo_ini date,
    n91_periodo_fin date,
    n91_tipo_comp char(2),
    n91_num_comp char(8),
    n91_usuario varchar(10,5) not null ,
    n91_fecing datetime year to second not null ,
    
    check (n91_prov_aport IN ('S' ,'N' )) constraint "fobos".ck_01_rolt091,
    
    check (n91_tipo_pago IN ('E' ,'C' ,'T' )) constraint "fobos".ck_02_rolt091
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".rolt091 from "public";

{ TABLE "fobos".srit023 row size = 46 number of columns = 8 index size = 106 }
create table "fobos".srit023 
  (
    s23_compania integer not null ,
    s23_tipo_orden integer not null ,
    s23_sustento_sri char(2) not null ,
    s23_secuencia integer not null ,
    s23_aux_cont char(12),
    s23_tributa char(1) not null ,
    s23_usuario varchar(10,5) not null ,
    s23_fecing datetime year to second not null ,
    
    check (s23_tributa IN ('S' ,'N' )) constraint "fobos".ck_01_srit023
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".srit023 from "public";

{ TABLE "fobos".rolt092 row size = 49 number of columns = 12 index size = 126 }
create table "fobos".rolt092 
  (
    n92_compania integer not null ,
    n92_proceso char(2) not null ,
    n92_cod_trab integer not null ,
    n92_num_ant smallint not null ,
    n92_num_prest integer not null ,
    n92_secuencia smallint not null ,
    n92_cod_liqrol char(2) not null ,
    n92_fecha_ini date not null ,
    n92_fecha_fin date not null ,
    n92_valor decimal(12,2) not null ,
    n92_saldo decimal(12,2) not null ,
    n92_valor_pago decimal(12,2) not null 
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".rolt092 from "public";

{ TABLE "fobos".cxpt029 row size = 31 number of columns = 4 index size = 73 }
create table "fobos".cxpt029 
  (
    p29_compania integer not null ,
    p29_localidad smallint not null ,
    p29_num_ret integer not null ,
    p29_num_sri char(21) not null 
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".cxpt029 from "public";

{ TABLE "fobos".cxpt032 row size = 14 number of columns = 5 index size = 69 }
create table "fobos".cxpt032 
  (
    p32_compania integer not null ,
    p32_localidad smallint not null ,
    p32_num_ret integer not null ,
    p32_tipo_doc char(2) not null ,
    p32_secuencia smallint not null 
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".cxpt032 from "public";

{ TABLE "fobos".gent058 row size = 102 number of columns = 12 index size = 103 }
create table "fobos".gent058 
  (
    g58_compania integer not null ,
    g58_localidad smallint not null ,
    g58_tipo_impto char(1) not null ,
    g58_porc_impto decimal(5,2) not null ,
    g58_tipo char(1) not null ,
    g58_estado char(1) not null ,
    g58_desc_impto varchar(40,20) not null ,
    g58_desc_abr varchar(15,10) not null ,
    g58_impto_sist char(1) not null ,
    g58_aux_cont char(12),
    g58_usuario varchar(10,5) not null ,
    g58_fecing datetime year to second not null ,
    
    check (g58_tipo_impto IN ('I' ,'F' )) constraint "fobos".ck_01_gent058,
    
    check (g58_tipo IN ('V' ,'C' )) constraint "fobos".ck_02_gent058,
    
    check (g58_estado IN ('A' ,'B' )) constraint "fobos".ck_03_gent058,
    
    check (g58_impto_sist IN ('S' ,'N' )) constraint "fobos".ck_04_gent058
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".gent058 from "public";

{ TABLE "fobos".ctbt013 row size = 168 number of columns = 15 index size = 171 }
create table "fobos".ctbt013 
  (
    b13_compania integer not null ,
    b13_tipo_comp char(2) not null ,
    b13_num_comp char(8) not null ,
    b13_secuencia smallint not null ,
    b13_cuenta char(12) not null ,
    b13_tipo_doc char(3),
    b13_glosa varchar(90,40),
    b13_valor_base decimal(14,2) not null ,
    b13_valor_aux decimal(14,2) not null ,
    b13_num_concil integer,
    b13_filtro integer,
    b13_fec_proceso date not null ,
    b13_codcli integer,
    b13_codprov integer,
    b13_pedido char(10)
  )  extent size 23071 next size 2307 lock mode row;
revoke all on "fobos".ctbt013 from "public";

{ TABLE "fobos".ordt001 row size = 164 number of columns = 18 index size = 43 }
create table "fobos".ordt001 
  (
    c01_tipo_orden serial not null ,
    c01_nombre varchar(60,40) not null ,
    c01_estado char(1) not null ,
    c01_ing_bodega char(1) not null ,
    c01_bien_serv char(1) not null ,
    c01_modulo char(2),
    c01_porc_retf_b decimal(4,2) not null ,
    c01_porc_retf_s decimal(4,2) not null ,
    c01_porc_reti_b decimal(5,2) not null ,
    c01_porc_reti_s decimal(5,2) not null ,
    c01_gendia_auto char(1) not null ,
    c01_aux_cont char(12),
    c01_aux_ot_proc char(12),
    c01_aux_ot_cost char(12),
    c01_aux_ot_vta char(12),
    c01_aux_ot_dvta char(12),
    c01_usuario varchar(10,5) not null ,
    c01_fecing datetime year to second not null ,
    
    check (c01_estado IN ('A' ,'B' )),
    
    check (c01_ing_bodega IN ('S' ,'N' )),
    
    check (c01_bien_serv IN ('B' ,'S' ,'T' ,'I' )),
    
    check (c01_gendia_auto IN ('S' ,'N' ))
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".ordt001 from "public";

{ TABLE "fobos".gent002 row size = 469 number of columns = 22 index size = 61 }
create table "fobos".gent002 
  (
    g02_compania integer not null ,
    g02_localidad smallint not null ,
    g02_nombre varchar(20,10) not null ,
    g02_abreviacion varchar(10,5) not null ,
    g02_estado char(1) not null ,
    g02_numruc char(13) not null ,
    g02_ciudad integer not null ,
    g02_correo varchar(255,125),
    g02_direccion varchar(40,15) not null ,
    g02_telefono1 varchar(12,6) not null ,
    g02_telefono2 varchar(12,6),
    g02_fax1 varchar(12,6),
    g02_fax2 varchar(12,6),
    g02_casilla varchar(15,8),
    g02_matriz char(1) not null ,
    g02_numaut_sri varchar(15,10),
    g02_fecaut_sri date,
    g02_fecexp_sri date,
    g02_serie_cia smallint,
    g02_serie_loc smallint,
    g02_usuario varchar(10,5) not null ,
    g02_fecing datetime year to second not null ,
    
    check (g02_estado IN ('A' ,'B' )),
    
    check (g02_matriz IN ('S' ,'N' ))
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".gent002 from "public";

{ TABLE "fobos".tr_cesantia row size = 49 number of columns = 10 index size = 27 
              }
create table "fobos".tr_cesantia 
  (
    compania integer not null ,
    cod_liqrol char(2) not null ,
    anio_cen smallint not null ,
    mes_cen smallint not null ,
    cod_trab integer not null ,
    fecha_repar date not null ,
    fecha_prox date not null ,
    valor_repar decimal(14,2) not null ,
    usuario varchar(10,5) not null ,
    fecing datetime year to second not null 
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".tr_cesantia from "public";

{ TABLE "fobos".srit024 row size = 61 number of columns = 8 index size = 172 }
create table "fobos".srit024 
  (
    s24_compania integer not null ,
    s24_codigo smallint not null ,
    s24_porcentaje_ice decimal(5,2) not null ,
    s24_codigo_impto varchar(15,6) not null ,
    s24_tipo_orden integer not null ,
    s24_aux_cont char(12),
    s24_usuario varchar(10,5) not null ,
    s24_fecing datetime year to second not null 
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".srit024 from "public";

{ TABLE "fobos".rept041 row size = 28 number of columns = 6 index size = 111 }
create table "fobos".rept041 
  (
    r41_compania integer not null ,
    r41_localidad smallint not null ,
    r41_cod_tran char(2) not null ,
    r41_num_tran decimal(15,0) not null ,
    r41_cod_tr char(2) not null ,
    r41_num_tr decimal(15,0) not null 
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".rept041 from "public";

{ TABLE "fobos".rolt018 row size = 23 number of columns = 4 index size = 52 }
create table "fobos".rolt018 
  (
    n18_cod_rubro smallint not null ,
    n18_flag_ident char(2) not null ,
    n18_usuario varchar(10,5) not null ,
    n18_fecing datetime year to second not null 
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".rolt018 from "public";

{ TABLE "fobos".rept042 row size = 28 number of columns = 6 index size = 111 }
create table "fobos".rept042 
  (
    r42_compania integer not null ,
    r42_localidad smallint not null ,
    r42_cod_tran char(2) not null ,
    r42_num_tran decimal(15,0) not null ,
    r42_cod_tr_re char(2) not null ,
    r42_num_tr_re decimal(15,0) not null 
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".rept042 from "public";

{ TABLE "fobos".rolt049 row size = 36 number of columns = 11 index size = 111 }
create table "fobos".rolt049 
  (
    n49_compania integer not null ,
    n49_proceso char(2) not null ,
    n49_cod_trab integer not null ,
    n49_fecha_ini date not null ,
    n49_fecha_fin date not null ,
    n49_cod_rubro smallint not null ,
    n49_num_prest integer,
    n49_orden smallint not null ,
    n49_det_tot char(2) not null ,
    n49_imprime_0 char(1) not null ,
    n49_valor decimal(12,2) not null ,
    
    check (n49_det_tot IN ('DI' ,'DE' ,'TI' ,'TE' ,'TN' )) constraint "fobos".ck_01_rolt049,
    
    check (n49_imprime_0 IN ('S' ,'N' )) constraint "fobos".ck_02_rolt049
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".rolt049 from "public";

{ TABLE "fobos".cajt014 row size = 274 number of columns = 29 index size = 249 }
create table "fobos".cajt014 
  (
    j14_compania integer not null ,
    j14_localidad smallint not null ,
    j14_tipo_fuente char(2) not null ,
    j14_num_fuente integer not null ,
    j14_secuencia smallint not null ,
    j14_codigo_pago char(2) not null ,
    j14_num_ret_sri char(21) not null ,
    j14_sec_ret smallint not null ,
    j14_fecha_emi date not null ,
    j14_cedruc char(15) not null ,
    j14_razon_social varchar(100,50) not null ,
    j14_num_fact_sri char(21) not null ,
    j14_autorizacion varchar(15,10) not null ,
    j14_fec_emi_fact date not null ,
    j14_tipo_ret char(1) not null ,
    j14_porc_ret decimal(5,2) not null ,
    j14_codigo_sri char(6) not null ,
    j14_fec_ini_porc date not null ,
    j14_base_imp decimal(12,2) not null ,
    j14_valor_ret decimal(12,2) not null ,
    j14_cont_cred char(1) not null ,
    j14_tipo_doc char(2),
    j14_tipo_fue char(2),
    j14_cod_tran char(2),
    j14_num_tran decimal(15,0),
    j14_tipo_comp char(2),
    j14_num_comp char(8),
    j14_usuario varchar(10,5) not null ,
    j14_fecing datetime year to second not null ,
    
    check (j14_tipo_ret IN ('F' ,'I' )) constraint "fobos".ck_01_cajt014,
    
    check (j14_cont_cred IN ('C' ,'R' )) constraint "fobos".ck_02_cajt014
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".cajt014 from "public";

{ TABLE "fobos".cxct008 row size = 44 number of columns = 10 index size = 141 }
create table "fobos".cxct008 
  (
    z08_compania integer not null ,
    z08_codcli integer not null ,
    z08_tipo_ret char(1) not null ,
    z08_porcentaje decimal(5,2) not null ,
    z08_codigo_sri char(6) not null ,
    z08_fecha_ini_porc date not null ,
    z08_defecto char(1) not null ,
    z08_flete char(1) not null ,
    z08_usuario varchar(10,5) not null ,
    z08_fecing datetime year to second not null ,
    
    check (z08_defecto IN ('S' ,'N' )) constraint "fobos".ck_01_cxct008,
    
    check (z08_flete IN ('S' ,'N' )) constraint "fobos".ck_02_cxct008
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".cxct008 from "public";

{ TABLE "fobos".cxct009 row size = 57 number of columns = 11 index size = 226 }
create table "fobos".cxct009 
  (
    z09_compania integer not null ,
    z09_codcli integer not null ,
    z09_tipo_ret char(1) not null ,
    z09_porcentaje decimal(5,2) not null ,
    z09_codigo_sri char(6) not null ,
    z09_fecha_ini_porc date not null ,
    z09_codigo_pago char(2) not null ,
    z09_cont_cred char(1) not null ,
    z09_aux_cont char(12),
    z09_usuario varchar(10,5) not null ,
    z09_fecing datetime year to second not null 
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".cxct009 from "public";

{ TABLE "fobos".cajt091 row size = 43 number of columns = 8 index size = 112 }
create table "fobos".cajt091 
  (
    j91_compania integer not null ,
    j91_codigo_pago char(2) not null ,
    j91_cont_cred char(1) not null ,
    j91_tipo_ret char(1) not null ,
    j91_porcentaje decimal(5,2) not null ,
    j91_aux_cont char(12),
    j91_usuario varchar(10,5) not null ,
    j91_fecing datetime year to second not null 
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".cajt091 from "public";

{ TABLE "fobos".srit025 row size = 39 number of columns = 8 index size = 93 }
create table "fobos".srit025 
  (
    s25_compania integer not null ,
    s25_tipo_ret char(1) not null ,
    s25_porcentaje decimal(5,2) not null ,
    s25_codigo_sri char(6) not null ,
    s25_fecha_ini_porc date not null ,
    s25_cliprov char(1) not null ,
    s25_usuario varchar(10,5) not null ,
    s25_fecing datetime year to second not null ,
    
    check (s25_tipo_ret IN ('F' ,'I' )) constraint "fobos".ck_01_srit025,
    
    check (s25_cliprov IN ('C' ,'P' )) constraint "fobos".ck_02_srit025
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".srit025 from "public";

{ TABLE "fobos".rolt015 row size = 52 number of columns = 9 index size = 52 }
create table "fobos".rolt015 
  (
    n15_compania integer not null ,
    n15_ano smallint not null ,
    n15_secuencia smallint not null ,
    n15_base_imp_ini decimal(12,2) not null ,
    n15_base_imp_fin decimal(12,2) not null ,
    n15_fracc_base decimal(12,2) not null ,
    n15_porc_ir decimal(5,2) not null ,
    n15_usuario varchar(10,5) not null ,
    n15_fecing datetime year to second not null 
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".rolt015 from "public";

{ TABLE "fobos".rolt085 row size = 217 number of columns = 33 index size = 157 }
create table "fobos".rolt085 
  (
    n85_compania integer not null ,
    n85_proceso char(2) not null ,
    n85_cod_trab integer not null ,
    n85_ano_proceso smallint not null ,
    n85_mes_proceso smallint not null ,
    n85_estado char(1) not null ,
    n85_ing_roles decimal(12,2) not null ,
    n85_dec_cuarto decimal(12,2) not null ,
    n85_dec_tercero decimal(12,2) not null ,
    n85_roles_varios decimal(12,2) not null ,
    n85_utilidades decimal(12,2) not null ,
    n85_vacaciones decimal(12,2) not null ,
    n85_iess_rol decimal(11,2) not null ,
    n85_iess_vac decimal(11,2) not null ,
    n85_bonificacion decimal(12,2) not null ,
    n85_otros_ing decimal(12,2) not null ,
    n85_total_gan decimal(14,2) not null ,
    n85_base_imp_ini decimal(12,2) not null ,
    n85_base_impto decimal(11,2) not null ,
    n85_porc_exced decimal(5,2) not null ,
    n85_valor_impto decimal(11,2) not null ,
    n85_fracc_base decimal(11,2) not null ,
    n85_valor_fracc decimal(12,2) not null ,
    n85_valor_acum decimal(12,2) not null ,
    n85_valor_deduc decimal(12,2) not null ,
    n85_impto_pagar decimal(11,2) not null ,
    n85_impto_reten decimal(11,2) not null ,
    n85_usu_modifi varchar(10,5),
    n85_fec_modifi datetime year to second,
    n85_usu_cierre varchar(10,5),
    n85_fec_cierre datetime year to second,
    n85_usuario varchar(10,5) not null ,
    n85_fecing datetime year to second not null ,
    
    check (n85_estado IN ('A' ,'P' )) constraint "fobos".ck_01_rolt085
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".rolt085 from "public";

{ TABLE "fobos".ctbt044 row size = 148 number of columns = 18 index size = 60 }
create table "fobos".ctbt044 
  (
    b44_compania integer not null ,
    b44_localidad smallint not null ,
    b44_modulo char(2) not null ,
    b44_bodega char(2) not null ,
    b44_grupo_linea char(5) not null ,
    b44_porc_impto decimal(5,2) not null ,
    b44_tipo_cli smallint not null ,
    b44_venta char(12) not null ,
    b44_descuento char(12) not null ,
    b44_dev_venta char(12) not null ,
    b44_costo_venta char(12) not null ,
    b44_dev_costo char(12) not null ,
    b44_inventario char(12) not null ,
    b44_transito char(12) not null ,
    b44_ajustes char(12) not null ,
    b44_flete char(12) not null ,
    b44_usuario varchar(10,5) not null ,
    b44_fecing datetime year to second not null 
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".ctbt044 from "public";

{ TABLE "fobos".ctbt045 row size = 504 number of columns = 46 index size = 54 }
create table "fobos".ctbt045 
  (
    b45_compania integer not null ,
    b45_localidad smallint not null ,
    b45_grupo_linea char(5) not null ,
    b45_porc_impto decimal(5,2) not null ,
    b45_tipo_cli smallint not null ,
    b45_vta_mo_tal char(12) not null ,
    b45_vta_mo_ext char(12) not null ,
    b45_vta_mo_cti char(12) not null ,
    b45_vta_rp_tal char(12) not null ,
    b45_vta_rp_ext char(12) not null ,
    b45_vta_rp_cti char(12) not null ,
    b45_vta_rp_alm char(12) not null ,
    b45_vta_otros1 char(12) not null ,
    b45_vta_otros2 char(12) not null ,
    b45_dvt_mo_tal char(12),
    b45_dvt_mo_ext char(12),
    b45_dvt_mo_cti char(12),
    b45_dvt_rp_tal char(12),
    b45_dvt_rp_ext char(12),
    b45_dvt_rp_cti char(12),
    b45_dvt_rp_alm char(12),
    b45_dvt_otros1 char(12),
    b45_dvt_otros2 char(12),
    b45_cos_mo_tal char(12),
    b45_cos_mo_ext char(12),
    b45_cos_mo_cti char(12),
    b45_cos_rp_tal char(12),
    b45_cos_rp_ext char(12),
    b45_cos_rp_cti char(12),
    b45_cos_rp_alm char(12),
    b45_cos_otros1 char(12),
    b45_cos_otros2 char(12),
    b45_pro_mo_tal char(12),
    b45_pro_mo_ext char(12),
    b45_pro_mo_cti char(12),
    b45_pro_rp_tal char(12),
    b45_pro_rp_ext char(12),
    b45_pro_rp_cti char(12),
    b45_pro_rp_alm char(12),
    b45_pro_otros1 char(12),
    b45_pro_otros2 char(12),
    b45_des_mo_tal char(12) not null ,
    b45_des_rp_tal char(12) not null ,
    b45_des_rp_alm char(12) not null ,
    b45_usuario varchar(10,5) not null ,
    b45_fecing datetime year to second not null 
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".ctbt045 from "public";

{ TABLE "fobos".rolt022 row size = 122 number of columns = 8 index size = 63 }
create table "fobos".rolt022 
  (
    n22_compania integer not null ,
    n22_codigo_arch smallint not null ,
    n22_tipo_arch char(3) not null ,
    n22_proceso char(2),
    n22_descripcion varchar(60,40) not null ,
    n22_nombre_arch varchar(30,10) not null ,
    n22_usuario varchar(10,5) not null ,
    n22_fecing datetime year to second not null 
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".rolt022 from "public";

{ TABLE "fobos".rolt023 row size = 134 number of columns = 9 index size = 87 }
create table "fobos".rolt023 
  (
    n23_compania integer not null ,
    n23_codigo_arch smallint not null ,
    n23_tipo_arch char(3) not null ,
    n23_tipo_causa char(1) not null ,
    n23_secuencia smallint not null ,
    n23_flag_ident char(2),
    n23_descripcion varchar(100,60) not null ,
    n23_usuario varchar(10,5) not null ,
    n23_fecing datetime year to second not null 
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".rolt023 from "public";

{ TABLE "fobos".rolt024 row size = 71 number of columns = 8 index size = 76 }
create table "fobos".rolt024 
  (
    n24_compania integer not null ,
    n24_codigo_arch smallint not null ,
    n24_tipo_arch char(3) not null ,
    n24_tipo_seg_pag char(1) not null ,
    n24_tipo char(1) not null ,
    n24_descripcion varchar(40,20) not null ,
    n24_usuario varchar(10,5) not null ,
    n24_fecing datetime year to second not null ,
    
    check (n24_tipo IN ('S' ,'N' )) constraint "fobos".ck_01_rolt024
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".rolt024 from "public";

{ TABLE "fobos".rolt025 row size = 239 number of columns = 10 index size = 108 }
create table "fobos".rolt025 
  (
    n25_compania integer not null ,
    n25_codigo_arch smallint not null ,
    n25_tipo_arch char(3) not null ,
    n25_tipo_emp_rel char(2) not null ,
    n25_tipo char(3) not null ,
    n25_descripcion varchar(200,100) not null ,
    n25_tipo_codigo char(2),
    n25_sub_tipo char(3),
    n25_usuario varchar(10,5) not null ,
    n25_fecing datetime year to second not null ,
    
    check (n25_tipo IN ('PRI' ,'PUB' )) constraint "fobos".ck_01_rolt025,
    
    check (n25_sub_tipo IN ('PRI' ,'PUB' )) constraint "fobos".ck_02_rolt025
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".rolt025 from "public";

{ TABLE "fobos".rolt026 row size = 171 number of columns = 29 index size = 231 }
create table "fobos".rolt026 
  (
    n26_compania integer not null ,
    n26_ano_proceso integer not null ,
    n26_mes_proceso smallint not null ,
    n26_codigo_arch smallint not null ,
    n26_tipo_arch char(3) not null ,
    n26_secuencia smallint not null ,
    n26_estado char(1) not null ,
    n26_nombre_arch varchar(30,10) not null ,
    n26_ruc_patronal varchar(15) not null ,
    n26_sucursal char(4) not null ,
    n26_ano_carga integer not null ,
    n26_mes_carga smallint not null ,
    n26_jornada char(1),
    n26_sec_jor smallint,
    n26_codigo_seg char(1),
    n26_tipo_seg char(1),
    n26_codigo_empl char(2),
    n26_tipo_empl char(3),
    n26_codigo_rela char(2),
    n26_tipo_rela char(3),
    n26_total_ext decimal(14,2) not null ,
    n26_total_adi decimal(14,2) not null ,
    n26_total_net decimal(14,2) not null ,
    n26_usua_elimin varchar(10,5),
    n26_fec_elimin datetime year to second,
    n26_usua_cierre varchar(10,5),
    n26_fec_cierre datetime year to second,
    n26_usuario varchar(10,5) not null ,
    n26_fecing datetime year to second not null ,
    
    check (n26_estado IN ('G' ,'C' ,'E' )) constraint "fobos".ck_01_rolt026,
    
    check ((n26_mes_carga >= 1 ) AND (n26_mes_carga <= 12 ) ) constraint "fobos".ck_02_rolt026
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".rolt026 from "public";

{ TABLE "fobos".rolt027 row size = 189 number of columns = 27 index size = 228 }
create table "fobos".rolt027 
  (
    n27_compania integer not null ,
    n27_ano_proceso integer not null ,
    n27_mes_proceso smallint not null ,
    n27_codigo_arch smallint not null ,
    n27_tipo_arch char(3) not null ,
    n27_secuencia smallint not null ,
    n27_cod_trab integer not null ,
    n27_estado char(1) not null ,
    n27_cedula_trab char(10) not null ,
    n27_fecha_ini date,
    n27_fecha_fin date,
    n27_cargo varchar(64,32),
    n27_ano_sect smallint,
    n27_sectorial char(15),
    n27_valor_ext decimal(12,2) not null ,
    n27_valor_adi decimal(12,2) not null ,
    n27_valor_net decimal(12,2) not null ,
    n27_tipo_causa char(1),
    n27_sec_cau smallint,
    n27_tipo_pago char(1),
    n27_flag_pago char(1),
    n27_num_dia_mes char(2),
    n27_tipo_per char(1) not null ,
    n27_usua_elimin varchar(10,5),
    n27_fec_elimin datetime year to second,
    n27_usua_modifi varchar(10,5),
    n27_fec_modifi datetime year to second,
    
    check (n27_estado IN ('G' ,'M' ,'E' )) constraint "fobos".ck_01_rolt027,
    
    check (n27_tipo_per IN ('P' ,'A' ,'M' ,'X' )) constraint "fobos".ck_02_rolt027
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".rolt027 from "public";

{ TABLE "fobos".talt042 row size = 72 number of columns = 14 index size = 97 }
create table "fobos".talt042 
  (
    t42_compania integer not null ,
    t42_localidad smallint not null ,
    t42_anio integer not null ,
    t42_mes smallint not null ,
    t42_num_ot integer not null ,
    t42_estado char(1) not null ,
    t42_fecha date not null ,
    t42_cod_cliente integer not null ,
    t42_total_mo decimal(12,2) not null ,
    t42_total_oc decimal(12,2) not null ,
    t42_total_in decimal(12,2) not null ,
    t42_total_nt decimal(12,2) not null ,
    t42_usuario varchar(10,5) not null ,
    t42_fecing datetime year to second not null ,
    
    check (t42_estado IN ('A' ,'C' ,'F' ,'E' ,'D' )) constraint "fobos".ck_01_talt042
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".talt042 from "public";

{ TABLE "fobos".rept043 row size = 312 number of columns = 17 index size = 190 }
create table "fobos".rept043 
  (
    r43_compania integer not null ,
    r43_localidad smallint not null ,
    r43_traspaso integer not null ,
    r43_cod_ventas smallint not null ,
    r43_division char(5) not null ,
    r43_nom_div varchar(30,15) not null ,
    r43_sub_linea char(2) not null ,
    r43_desc_sub varchar(35,20) not null ,
    r43_cod_grupo char(4),
    r43_desc_grupo varchar(40,20),
    r43_cod_clase char(8),
    r43_desc_clase varchar(50,20),
    r43_marca char(6) not null ,
    r43_desc_marca varchar(35,20) not null ,
    r43_referencia varchar(60,40) not null ,
    r43_usuario varchar(10,5) not null ,
    r43_fecing datetime year to second not null 
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".rept043 from "public";

{ TABLE "fobos".rept044 row size = 470 number of columns = 29 index size = 279 }
create table "fobos".rept044 
  (
    r44_compania integer not null ,
    r44_localidad smallint not null ,
    r44_traspaso integer not null ,
    r44_secuencia integer not null ,
    r44_bodega_ori char(2) not null ,
    r44_item_ori char(15) not null ,
    r44_desc_ori varchar(70,20) not null ,
    r44_stock_ori decimal(8,2) not null ,
    r44_costo_ori decimal(11,2) not null ,
    r44_bodega_tra char(2) not null ,
    r44_item_tra char(15) not null ,
    r44_desc_tra varchar(70,20) not null ,
    r44_cant_tra decimal(8,2) not null ,
    r44_stock_tra decimal(8,2) not null ,
    r44_costo_tra decimal(11,2) not null ,
    r44_sto_ant_tra decimal(8,2) not null ,
    r44_cos_ant_tra decimal(11,2) not null ,
    r44_division_t char(5) not null ,
    r44_nom_div_t varchar(30,15) not null ,
    r44_sub_linea_t char(2) not null ,
    r44_desc_sub_t varchar(35,20) not null ,
    r44_cod_grupo_t char(4) not null ,
    r44_desc_grupo_t varchar(40,20) not null ,
    r44_cod_clase_t char(8) not null ,
    r44_desc_clase_t varchar(50,20) not null ,
    r44_marca_t char(6) not null ,
    r44_desc_marca_t varchar(35,20) not null ,
    r44_usuario varchar(10,5) not null ,
    r44_fecing datetime year to second not null 
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".rept044 from "public";

{ TABLE "fobos".rept045 row size = 40 number of columns = 7 index size = 112 }
create table "fobos".rept045 
  (
    r45_compania integer not null ,
    r45_localidad smallint not null ,
    r45_traspaso integer not null ,
    r45_cod_tran char(2) not null ,
    r45_num_tran decimal(15,0) not null ,
    r45_usuario varchar(10,5) not null ,
    r45_fecing datetime year to second not null 
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".rept045 from "public";

{ TABLE "fobos".gent024 row size = 37 number of columns = 6 index size = 91 }
create table "fobos".gent024 
  (
    g24_compania integer not null ,
    g24_bodega char(2) not null ,
    g24_impresora varchar(10,5) not null ,
    g24_imprime char(1) not null ,
    g24_usuario varchar(10,5) not null ,
    g24_fecing datetime year to second not null ,
    
    check (g24_imprime IN ('S' ,'N' )) constraint "fobos".ck_01_gent024
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".gent024 from "public";

{ TABLE "fobos".actt015 row size = 39 number of columns = 7 index size = 106 }
create table "fobos".actt015 
  (
    a15_compania integer not null ,
    a15_codigo_tran char(2) not null ,
    a15_numero_tran integer not null ,
    a15_tipo_comp char(2) not null ,
    a15_num_comp char(8) not null ,
    a15_usuario varchar(10,5) not null ,
    a15_fecing datetime year to second not null 
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".actt015 from "public";

{ TABLE "fobos".actt012 row size = 172 number of columns = 17 index size = 163 }
create table "fobos".actt012 
  (
    a12_compania integer not null ,
    a12_codigo_tran char(2) not null ,
    a12_numero_tran integer not null ,
    a12_codigo_bien integer not null ,
    a12_referencia varchar(100,40),
    a12_locali_ori smallint not null ,
    a12_depto_ori smallint not null ,
    a12_locali_dest smallint,
    a12_depto_dest smallint,
    a12_porc_deprec decimal(4,2),
    a12_porc_reval decimal(4,2),
    a12_valor_mb decimal(12,2) not null ,
    a12_valor_ma decimal(12,2) not null ,
    a12_tipcomp_gen char(2),
    a12_numcomp_gen char(8),
    a12_usuario varchar(10,5) not null ,
    a12_fecing datetime year to second not null 
  )  extent size 23 next size 16 lock mode row;
revoke all on "fobos".actt012 from "public";

{ TABLE "fobos".actt006 row size = 65 number of columns = 5 index size = 36 }
create table "fobos".actt006 
  (
    a06_compania integer not null ,
    a06_estado char(1) not null ,
    a06_descripcion varchar(40,20) not null ,
    a06_usuario varchar(10,5) not null ,
    a06_fecing datetime year to second not null 
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".actt006 from "public";

{ TABLE "fobos".srit022 row size = 69 number of columns = 12 index size = 90 }
create table "fobos".srit022 
  (
    s22_compania integer not null ,
    s22_localidad smallint not null ,
    s22_anio smallint not null ,
    s22_mes smallint not null ,
    s22_tipo_anexo char(1) not null ,
    s22_estado char(1) not null ,
    s22_usu_apert varchar(10,5),
    s22_fec_apert datetime year to second,
    s22_usu_cierre varchar(10,5),
    s22_fec_cierre datetime year to second,
    s22_usuario varchar(10,5) not null ,
    s22_fecing datetime year to second not null ,
    
    check (s22_tipo_anexo IN ('V' ,'C' )) constraint "fobos".ck_01_srit022,
    
    check (s22_estado IN ('P' ,'C' )) constraint "fobos".ck_02_srit022
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".srit022 from "public";

{ TABLE "fobos".rept019_res row size = 51 number of columns = 9 index size = 54 }
create table "fobos".rept019_res 
  (
    r19_compania integer not null ,
    r19_localidad smallint not null ,
    r19_cod_tran char(2) not null ,
    r19_num_tran decimal(15,0) not null ,
    r19_tot_costo decimal(12,2) not null ,
    r19_tot_neto decimal(12,2) not null ,
    r19_comito char(1) not null ,
    r19_usuario varchar(10,5) not null ,
    r19_fecing datetime year to second not null ,
    
    check (r19_comito IN ('S' ,'N' )) constraint "fobos".ck_01_rept019_res
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".rept019_res from "public";

{ TABLE "fobos".rept020_res row size = 81 number of columns = 14 index size = 91 
              }
create table "fobos".rept020_res 
  (
    r20_compania integer not null ,
    r20_localidad smallint not null ,
    r20_cod_tran char(2) not null ,
    r20_num_tran decimal(15,0) not null ,
    r20_bodega char(2) not null ,
    r20_item char(15) not null ,
    r20_orden smallint not null ,
    r20_costo decimal(13,4) not null ,
    r20_costant_mb decimal(11,2) not null ,
    r20_costant_ma decimal(11,2) not null ,
    r20_costnue_mb decimal(11,2) not null ,
    r20_costnue_ma decimal(11,2) not null ,
    r20_comito char(1) not null ,
    r20_fecing datetime year to second not null ,
    
    check (r20_comito IN ('S' ,'N' )) constraint "fobos".ck_01_rept020_res
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".rept020_res from "public";

{ TABLE "fobos".rept010_res row size = 67 number of columns = 9 index size = 57 }
create table "fobos".rept010_res 
  (
    r10_compania integer not null ,
    r10_codigo char(15) not null ,
    r10_costo_mb decimal(11,2) not null ,
    r10_costo_ma decimal(11,2) not null ,
    r10_costult_mb decimal(11,2) not null ,
    r10_costult_ma decimal(11,2) not null ,
    r10_comito char(1) not null ,
    r10_usuario varchar(10,5) not null ,
    r10_fecing datetime year to second not null ,
    
    check (r10_comito IN ('S' ,'N' )) constraint "fobos".ck_01_rept010_res
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".rept010_res from "public";

{ TABLE "fobos".ctbt013_res row size = 56 number of columns = 9 index size = 52 }
create table "fobos".ctbt013_res 
  (
    b13_compania integer not null ,
    b13_tipo_comp char(2) not null ,
    b13_num_comp char(8) not null ,
    b13_secuencia smallint not null ,
    b13_cuenta char(12) not null ,
    b13_valor_base decimal(14,2) not null ,
    b13_comito char(1) not null ,
    b13_usuario varchar(10,5) not null ,
    b13_fecing datetime year to second not null ,
    
    check (b13_comito IN ('S' ,'N' )) constraint "fobos".ck_01_ctbt013_res
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".ctbt013_res from "public";

{ TABLE "fobos".trans_ent row size = 51 number of columns = 7 index size = 54 }
create table "fobos".trans_ent 
  (
    compania integer not null ,
    localidad smallint not null ,
    cod_tran char(2) not null ,
    num_tran decimal(15,0) not null ,
    item_ent char(15) not null ,
    usuario varchar(10,5) not null ,
    fecing datetime year to second not null 
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".trans_ent from "public";

{ TABLE "fobos".trans_salida row size = 79 number of columns = 11 index size = 108 
              }
create table "fobos".trans_salida 
  (
    compania integer not null ,
    local_ent smallint not null ,
    codtran_ent char(2) not null ,
    numtran_ent decimal(15,0) not null ,
    item_ent char(15) not null ,
    local_sal smallint not null ,
    codtran_sal char(2) not null ,
    numtran_sal decimal(15,0) not null ,
    item_sal char(15) not null ,
    usuario varchar(10,5) not null ,
    fecing datetime year to second not null 
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".trans_salida from "public";

{ TABLE "fobos".ite_cos_rea row size = 206 number of columns = 14 index size = 37 
              }
create table "fobos".ite_cos_rea 
  (
    compania integer not null ,
    localidad smallint not null ,
    item char(15) not null ,
    desc_clase varchar(50,20) not null ,
    desc_item varchar(70,20) not null ,
    precio decimal(11,2) not null ,
    costo decimal(11,2) not null ,
    sto_dic_08 decimal(8,2) not null ,
    factor decimal(10,4) not null ,
    costo_teo decimal(11,2) not null ,
    costo_real decimal(14,4) not null ,
    costo_sist decimal(11,2) not null ,
    diferencia decimal(14,4) not null ,
    margen decimal(14,4) not null 
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".ite_cos_rea from "public";

{ TABLE "fobos".cxpt033 row size = 350 number of columns = 20 index size = 123 }
create table "fobos".cxpt033 
  (
    p33_compania integer not null ,
    p33_localidad smallint not null ,
    p33_numero_oc integer not null ,
    p33_secuencia smallint not null ,
    p33_cod_prov_ant integer not null ,
    p33_nom_prov_ant varchar(100,50) not null ,
    p33_num_fac_ant char(21) not null ,
    p33_fec_aut_ant char(14),
    p33_num_aut_ant char(10) not null ,
    p33_fec_cad_ant date not null ,
    p33_cod_tran char(2),
    p33_num_tran decimal(15,0),
    p33_cod_prov_nue integer,
    p33_nom_prov_nue varchar(100,50),
    p33_num_fac_nue char(21),
    p33_fec_aut_nue char(14),
    p33_num_aut_nue char(10),
    p33_fec_cad_nue date,
    p33_usuario varchar(10,5) not null ,
    p33_fecing datetime year to second not null 
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".cxpt033 from "public";

{ TABLE "fobos".rept009 row size = 66 number of columns = 6 index size = 36 }
create table "fobos".rept009 
  (
    r09_compania integer not null ,
    r09_tipo_ident char(1) not null ,
    r09_descripcion varchar(40,20) not null ,
    r09_estado char(1) not null ,
    r09_usuario varchar(10,5) not null ,
    r09_fecing datetime year to second not null ,
    
    check (r09_estado IN ('A' ,'B' )) constraint "fobos".ck_01_rept009
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".rept009 from "public";

{ TABLE "fobos".rept046 row size = 438 number of columns = 25 index size = 319 }
create table "fobos".rept046 
  (
    r46_compania integer not null ,
    r46_localidad smallint not null ,
    r46_composicion integer not null ,
    r46_item_comp char(15) not null ,
    r46_estado char(1) not null ,
    r46_cod_ventas smallint not null ,
    r46_desc_comp varchar(70,20) not null ,
    r46_division_c char(5) not null ,
    r46_nom_div_c varchar(30,15) not null ,
    r46_sub_linea_c char(2) not null ,
    r46_desc_sub_c varchar(35,20) not null ,
    r46_cod_grupo_c char(4) not null ,
    r46_desc_grupo_c varchar(40,20) not null ,
    r46_cod_clase_c char(8) not null ,
    r46_desc_clase_c varchar(50,20) not null ,
    r46_marca_c char(6) not null ,
    r46_desc_marca_c varchar(35,20) not null ,
    r46_referencia varchar(60,40) not null ,
    r46_tiene_oc char(1) not null ,
    r46_usu_modifi varchar(10,5),
    r46_fec_modifi datetime year to second,
    r46_usu_cierre varchar(10,5),
    r46_fec_cierre datetime year to second,
    r46_usuario varchar(10,5) not null ,
    r46_fecing datetime year to second not null ,
    
    check (r46_estado IN ('C' ,'P' )) constraint "fobos".ck_01_rept046,
    
    check (r46_tiene_oc IN ('S' ,'N' )) constraint "fobos".ck_02_rept046
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".rept046 from "public";

{ TABLE "fobos".rept047 row size = 345 number of columns = 19 index size = 328 }
create table "fobos".rept047 
  (
    r47_compania integer not null ,
    r47_localidad smallint not null ,
    r47_composicion integer not null ,
    r47_item_comp char(15) not null ,
    r47_bodega_part char(2) not null ,
    r47_item_part char(15) not null ,
    r47_desc_part varchar(70,20) not null ,
    r47_costo_part decimal(11,2) not null ,
    r47_cantidad decimal(8,2) not null ,
    r47_division_p char(5) not null ,
    r47_nom_div_p varchar(30,15) not null ,
    r47_sub_linea_p char(2) not null ,
    r47_desc_sub_p varchar(35,20) not null ,
    r47_cod_grupo_p char(4) not null ,
    r47_desc_grupo_p varchar(40,20) not null ,
    r47_cod_clase_p char(8) not null ,
    r47_desc_clase_p varchar(50,20) not null ,
    r47_marca_p char(6) not null ,
    r47_desc_marca_p varchar(35,20) not null 
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".rept047 from "public";

{ TABLE "fobos".rept048 row size = 183 number of columns = 19 index size = 210 }
create table "fobos".rept048 
  (
    r48_compania integer not null ,
    r48_localidad smallint not null ,
    r48_composicion integer not null ,
    r48_item_comp char(15) not null ,
    r48_sec_carga integer not null ,
    r48_estado char(1) not null ,
    r48_bodega_comp char(2) not null ,
    r48_carg_stock decimal(8,2) not null ,
    r48_costo_inv decimal(11,2) not null ,
    r48_costo_oc decimal(11,2) not null ,
    r48_costo_mo decimal(11,2) not null ,
    r48_costo_comp decimal(11,2) not null ,
    r48_referencia varchar(60,40) not null ,
    r48_usu_elimin varchar(10,5),
    r48_fec_elimin datetime year to second,
    r48_usu_cierre varchar(10,5),
    r48_fec_cierre datetime year to second,
    r48_usuario varchar(10,5) not null ,
    r48_fecing datetime year to second not null ,
    
    check (r48_estado IN ('C' ,'P' ,'E' )) constraint "fobos".ck_01_rept048
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".rept048 from "public";

{ TABLE "fobos".rept049 row size = 63 number of columns = 10 index size = 183 }
create table "fobos".rept049 
  (
    r49_compania integer not null ,
    r49_localidad smallint not null ,
    r49_composicion integer not null ,
    r49_item_comp char(15) not null ,
    r49_sec_carga integer not null ,
    r49_numero_oc integer not null ,
    r49_costo_oc decimal(11,2) not null ,
    r49_cant_unid integer not null ,
    r49_usuario varchar(10,5) not null ,
    r49_fecing datetime year to second not null 
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".rept049 from "public";

{ TABLE "fobos".rept053 row size = 59 number of columns = 9 index size = 204 }
create table "fobos".rept053 
  (
    r53_compania integer not null ,
    r53_localidad smallint not null ,
    r53_composicion integer not null ,
    r53_item_comp char(15) not null ,
    r53_sec_carga integer not null ,
    r53_cod_tran char(2) not null ,
    r53_num_tran decimal(15,0) not null ,
    r53_usuario varchar(10,5) not null ,
    r53_fecing datetime year to second not null 
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".rept053 from "public";

{ TABLE "fobos".rolt031 row size = 84 number of columns = 9 index size = 61 }
create table "fobos".rolt031 
  (
    n31_compania integer not null ,
    n31_cod_trab integer not null ,
    n31_secuencia smallint not null ,
    n31_tipo_carga char(1) not null ,
    n31_cod_trab_e integer,
    n31_nombres varchar(45,25) not null ,
    n31_fecha_nacim date not null ,
    n31_usuario varchar(10,5) not null ,
    n31_fecing datetime year to second not null ,
    
    check (n31_tipo_carga IN ('H' ,'E' ,'M' ,'P' ))
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".rolt031 from "public";

{ TABLE "fobos".rolt028 row size = 27 number of columns = 5 index size = 70 }
create table "fobos".rolt028 
  (
    n28_compania integer not null ,
    n28_proceso char(2) not null ,
    n28_cod_liqrol char(2) not null ,
    n28_usuario varchar(10,5) not null ,
    n28_fecing datetime year to second not null 
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".rolt028 from "public";

{ TABLE "fobos".rept019 row size = 385 number of columns = 37 index size = 292 }
create table "fobos".rept019 
  (
    r19_compania integer not null ,
    r19_localidad smallint not null ,
    r19_cod_tran char(2) not null ,
    r19_num_tran decimal(15,0) not null ,
    r19_cod_subtipo integer,
    r19_cont_cred char(1) not null ,
    r19_ped_cliente char(10),
    r19_referencia varchar(40,20),
    r19_codcli integer,
    r19_nomcli varchar(100,50) not null ,
    r19_dircli varchar(40,20) not null ,
    r19_telcli char(10),
    r19_cedruc char(15) not null ,
    r19_vendedor smallint not null ,
    r19_oc_externa varchar(21,15),
    r19_oc_interna integer,
    r19_ord_trabajo integer,
    r19_descuento decimal(4,2) not null ,
    r19_porc_impto decimal(4,2) not null ,
    r19_tipo_dev char(2),
    r19_num_dev decimal(15,0),
    r19_bodega_ori char(2) not null ,
    r19_bodega_dest char(2) not null ,
    r19_fact_costo decimal(9,2),
    r19_fact_venta decimal(9,2),
    r19_moneda char(2) not null ,
    r19_paridad decimal(16,9) not null ,
    r19_precision smallint not null ,
    r19_tot_costo decimal(12,2) not null ,
    r19_tot_bruto decimal(12,2) not null ,
    r19_tot_dscto decimal(11,2) not null ,
    r19_tot_neto decimal(12,2) not null ,
    r19_flete decimal(11,2) not null ,
    r19_numliq integer,
    r19_num_ret integer,
    r19_usuario varchar(10,5) not null ,
    r19_fecing datetime year to second not null ,
    
    check (r19_cont_cred IN ('C' ,'R' )),
    
    check (r19_precision IN (0 ,1 ,2 ))
  )  extent size 7970 next size 797 lock mode row;
revoke all on "fobos".rept019 from "public";

{ TABLE "fobos".cajt011 row size = 90 number of columns = 14 index size = 96 }
create table "fobos".cajt011 
  (
    j11_compania integer not null ,
    j11_localidad smallint not null ,
    j11_tipo_fuente char(2) not null ,
    j11_num_fuente integer not null ,
    j11_secuencia smallint not null ,
    j11_codigo_pago char(2) not null ,
    j11_moneda char(2) not null ,
    j11_paridad decimal(16,9) not null ,
    j11_valor decimal(12,2) not null ,
    j11_cod_bco_tarj smallint,
    j11_num_ch_aut varchar(21),
    j11_num_cta_tarj varchar(25),
    j11_protestado char(1) not null ,
    j11_num_egreso integer,
    
    check (j11_protestado IN ('S' ,'N' ))
  )  extent size 1927 next size 192 lock mode row;
revoke all on "fobos".cajt011 from "public";

{ TABLE "fobos".rolt017 row size = 188 number of columns = 7 index size = 60 }
create table "fobos".rolt017 
  (
    n17_compania integer not null ,
    n17_ano_sect smallint not null ,
    n17_sectorial char(15) not null ,
    n17_descripcion varchar(140,60) not null ,
    n17_valor decimal(12,2) not null ,
    n17_usuario varchar(10,5) not null ,
    n17_fecing datetime year to second not null 
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".rolt017 from "public";

{ TABLE "fobos".t_bal_gen row size = 36 number of columns = 6 index size = 66 }
create table "fobos".t_bal_gen 
  (
    b11_compania integer not null ,
    b11_cuenta char(12) not null ,
    b11_moneda char(2) not null ,
    b11_ano smallint not null ,
    b11_db_ano_ant decimal(14,2) not null ,
    b11_cr_ano_ant decimal(14,2) not null 
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".t_bal_gen from "public";

{ TABLE "fobos".rept068 row size = 73 number of columns = 13 index size = 225 }
create table "fobos".rept068 
  (
    r68_compania integer not null ,
    r68_localidad smallint not null ,
    r68_cod_tran char(2) not null ,
    r68_num_tran decimal(15,0) not null ,
    r68_loc_tr smallint not null ,
    r68_cod_tr char(2) not null ,
    r68_num_tr decimal(15,0) not null ,
    r68_bodega char(2) not null ,
    r68_item char(15) not null ,
    r68_secuencia smallint not null ,
    r68_cantidad decimal(8,2) not null ,
    r68_usuario varchar(10,5) not null ,
    r68_fecing datetime year to second not null 
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".rept068 from "public";

{ TABLE "fobos".rept069 row size = 38 number of columns = 8 index size = 114 }
create table "fobos".rept069 
  (
    r69_compania integer not null ,
    r69_localidad smallint not null ,
    r69_cod_tran char(2) not null ,
    r69_num_tran decimal(15,0) not null ,
    r69_loc_tr smallint not null ,
    r69_cod_tr char(2) not null ,
    r69_num_tr decimal(15,0) not null ,
    r69_fecing datetime year to second not null 
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".rept069 from "public";

{ TABLE "fobos".rept108 row size = 56 number of columns = 8 index size = 70 }
create table "fobos".rept108 
  (
    r108_compania integer not null ,
    r108_localidad smallint not null ,
    r108_cod_zona smallint not null ,
    r108_estado char(1) not null ,
    r108_descripcion varchar(25,10) not null ,
    r108_cia_trans smallint,
    r108_usuario varchar(10,5) not null ,
    r108_fecing datetime year to second not null ,
    
    check (r108_estado IN ('A' ,'B' )) constraint "fobos".ck_01_rept108
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".rept108 from "public";

{ TABLE "fobos".rept109 row size = 70 number of columns = 12 index size = 103 }
create table "fobos".rept109 
  (
    r109_compania integer not null ,
    r109_localidad smallint not null ,
    r109_cod_zona smallint not null ,
    r109_cod_subzona smallint not null ,
    r109_estado char(1) not null ,
    r109_descripcion varchar(25,10) not null ,
    r109_horas_entr smallint not null ,
    r109_pais integer not null ,
    r109_divi_poli integer,
    r109_ciudad integer,
    r109_usuario varchar(10,5) not null ,
    r109_fecing datetime year to second not null ,
    
    check (r109_estado IN ('A' ,'B' )) constraint "fobos".ck_01_rept109
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".rept109 from "public";

{ TABLE "fobos".rept110 row size = 80 number of columns = 8 index size = 52 }
create table "fobos".rept110 
  (
    r110_compania integer not null ,
    r110_localidad smallint not null ,
    r110_cod_trans smallint not null ,
    r110_estado char(1) not null ,
    r110_descripcion varchar(40,20) not null ,
    r110_placa varchar(10,7) not null ,
    r110_usuario varchar(10,5) not null ,
    r110_fecing datetime year to second not null ,
    
    check (r110_estado IN ('A' ,'B' )) constraint "fobos".ck_01_rept110
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".rept110 from "public";

{ TABLE "fobos".rept111 row size = 80 number of columns = 9 index size = 79 }
create table "fobos".rept111 
  (
    r111_compania integer not null ,
    r111_localidad smallint not null ,
    r111_cod_trans smallint not null ,
    r111_cod_chofer smallint not null ,
    r111_estado char(1) not null ,
    r111_nombre varchar(45,30) not null ,
    r111_cod_trab integer,
    r111_usuario varchar(10,5) not null ,
    r111_fecing datetime year to second not null ,
    
    check (r111_estado IN ('A' ,'B' )) constraint "fobos".ck_01_rept111
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".rept111 from "public";

{ TABLE "fobos".rept112 row size = 75 number of columns = 8 index size = 52 }
create table "fobos".rept112 
  (
    r112_compania integer not null ,
    r112_localidad smallint not null ,
    r112_cod_obser smallint not null ,
    r112_estado char(1) not null ,
    r112_descripcion varchar(45,30) not null ,
    r112_tipo char(1) not null ,
    r112_usuario varchar(10,5) not null ,
    r112_fecing datetime year to second not null ,
    
    check (r112_estado IN ('A' ,'B' )) constraint "fobos".ck_01_rept112,
    
    check (r112_tipo IN ('C' ,'L' ,'T' )) constraint "fobos".ck_02_rept112
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".rept112 from "public";

{ TABLE "fobos".rept114 row size = 79 number of columns = 13 index size = 108 }
create table "fobos".rept114 
  (
    r114_compania integer not null ,
    r114_localidad smallint not null ,
    r114_num_hojrut smallint not null ,
    r114_secuencia smallint not null ,
    r114_guia_remision decimal(15,0),
    r114_codcli integer,
    r114_cod_zona smallint,
    r114_cod_subzona smallint,
    r114_hora_lleg datetime hour to second,
    r114_hora_sali datetime hour to second,
    r114_recibido_por varchar(40,20),
    r114_cod_obser smallint,
    r114_estado char(1) not null ,
    
    check (r114_estado IN ('E' ,'N' )) constraint "fobos".ck_01_rept114
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".rept114 from "public";

{ TABLE "fobos".rept113 row size = 117 number of columns = 18 index size = 115 }
create table "fobos".rept113 
  (
    r113_compania integer not null ,
    r113_localidad smallint not null ,
    r113_num_hojrut smallint not null ,
    r113_estado char(1) not null ,
    r113_observacion varchar(30,20),
    r113_fecha date not null ,
    r113_cod_trans smallint not null ,
    r113_cod_chofer smallint not null ,
    r113_cod_ayud smallint,
    r113_km_ini integer not null ,
    r113_km_fin integer,
    r113_areaneg smallint not null ,
    r113_usu_cierre varchar(10,5),
    r113_fec_cierre datetime year to second,
    r113_usu_elim varchar(10,5),
    r113_fec_elim datetime year to second,
    r113_usuario varchar(10,5) not null ,
    r113_fecing datetime year to second not null ,
    
    check (r113_estado IN ('A' ,'P' ,'C' ,'E' )) constraint "fobos".ck_01_rept113
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".rept113 from "public";

{ TABLE "fobos".gent025 row size = 86 number of columns = 7 index size = 52 }
create table "fobos".gent025 
  (
    g25_pais integer not null ,
    g25_divi_poli integer not null ,
    g25_region varchar(14) not null ,
    g25_nombre varchar(40,20) not null ,
    g25_siglas char(3) not null ,
    g25_usuario varchar(10,5) not null ,
    g25_fecing datetime year to second not null ,
    
    check (g25_region IN ('COSTA' ,'SIERRA' ,'ORIENTE' ,'REGION INSULAR' )) constraint 
              "fobos".ck_01_gent025
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".gent025 from "public";

{ TABLE "fobos".rept115 row size = 80 number of columns = 9 index size = 79 }
create table "fobos".rept115 
  (
    r115_compania integer not null ,
    r115_localidad smallint not null ,
    r115_cod_trans smallint not null ,
    r115_cod_ayud smallint not null ,
    r115_estado char(1) not null ,
    r115_nombre varchar(45,30) not null ,
    r115_cod_trab integer,
    r115_usuario varchar(10,5) not null ,
    r115_fecing datetime year to second not null ,
    
    check (r115_estado IN ('A' ,'B' )) constraint "fobos".ck_01_rept115
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".rept115 from "public";

{ TABLE "fobos".rept116 row size = 94 number of columns = 9 index size = 52 }
create table "fobos".rept116 
  (
    r116_compania integer not null ,
    r116_localidad smallint not null ,
    r116_cia_trans smallint not null ,
    r116_estado char(1) not null ,
    r116_razon_soc varchar(60,30) not null ,
    r116_tipo char(1) not null ,
    r116_codprov integer,
    r116_usuario varchar(10,5) not null ,
    r116_fecing datetime year to second not null ,
    
    check (r116_estado IN ('A' ,'B' )) constraint "fobos".ck_01_rept116,
    
    check (r116_tipo IN ('I' ,'E' )) constraint "fobos".ck_02_rept116
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".rept116 from "public";

{ TABLE "fobos".tmp_blitz row size = 15 number of columns = 1 index size = 0 }
create table "fobos".tmp_blitz 
  (
    items char(15)
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".tmp_blitz from "public";

{ TABLE "fobos".provincia row size = 71 number of columns = 4 index size = 27 }
create table "fobos".provincia 
  (
    codigo smallint not null ,
    descripcion varchar(60,30) not null ,
    pais integer not null ,
    cod_phobos integer not null 
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".provincia from "public";

{ TABLE "fobos".canton row size = 77 number of columns = 6 index size = 51 }
create table "fobos".canton 
  (
    cod_prov smallint not null ,
    codigo smallint not null ,
    descripcion varchar(60,30) not null ,
    pais integer not null ,
    divi_poli integer not null ,
    cod_phobos integer not null 
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".canton from "public";

{ TABLE "fobos".cxpt006 row size = 30 number of columns = 6 index size = 55 }
create table "fobos".cxpt006 
  (
    p06_compania integer not null ,
    p06_cod_bco_tra char(2) not null ,
    p06_banco integer not null ,
    p06_estado char(1) not null ,
    p06_usuario varchar(10,5) not null ,
    p06_fecing datetime year to second not null ,
    
    check (p06_estado IN ('A' ,'B' )) constraint "fobos".ck_01_cxpt006
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".cxpt006 from "public";


grant select on "fobos".gent000 to "public" as "fobos";
grant update on "fobos".gent000 to "public" as "fobos";
grant insert on "fobos".gent000 to "public" as "fobos";
grant delete on "fobos".gent000 to "public" as "fobos";
grant index on "fobos".gent000 to "public" as "fobos";
grant select on "fobos".gent001 to "public" as "fobos";
grant update on "fobos".gent001 to "public" as "fobos";
grant insert on "fobos".gent001 to "public" as "fobos";
grant delete on "fobos".gent001 to "public" as "fobos";
grant index on "fobos".gent001 to "public" as "fobos";
grant select on "fobos".gent003 to "public" as "fobos";
grant update on "fobos".gent003 to "public" as "fobos";
grant insert on "fobos".gent003 to "public" as "fobos";
grant delete on "fobos".gent003 to "public" as "fobos";
grant index on "fobos".gent003 to "public" as "fobos";
grant select on "fobos".gent004 to "public" as "fobos";
grant update on "fobos".gent004 to "public" as "fobos";
grant insert on "fobos".gent004 to "public" as "fobos";
grant delete on "fobos".gent004 to "public" as "fobos";
grant index on "fobos".gent004 to "public" as "fobos";
grant select on "fobos".gent005 to "public" as "fobos";
grant update on "fobos".gent005 to "public" as "fobos";
grant insert on "fobos".gent005 to "public" as "fobos";
grant delete on "fobos".gent005 to "public" as "fobos";
grant index on "fobos".gent005 to "public" as "fobos";
grant select on "fobos".gent007 to "public" as "fobos";
grant update on "fobos".gent007 to "public" as "fobos";
grant insert on "fobos".gent007 to "public" as "fobos";
grant delete on "fobos".gent007 to "public" as "fobos";
grant index on "fobos".gent007 to "public" as "fobos";
grant select on "fobos".gent009 to "public" as "fobos";
grant update on "fobos".gent009 to "public" as "fobos";
grant insert on "fobos".gent009 to "public" as "fobos";
grant delete on "fobos".gent009 to "public" as "fobos";
grant index on "fobos".gent009 to "public" as "fobos";
grant select on "fobos".gent011 to "public" as "fobos";
grant update on "fobos".gent011 to "public" as "fobos";
grant insert on "fobos".gent011 to "public" as "fobos";
grant delete on "fobos".gent011 to "public" as "fobos";
grant index on "fobos".gent011 to "public" as "fobos";
grant select on "fobos".gent012 to "public" as "fobos";
grant update on "fobos".gent012 to "public" as "fobos";
grant insert on "fobos".gent012 to "public" as "fobos";
grant delete on "fobos".gent012 to "public" as "fobos";
grant index on "fobos".gent012 to "public" as "fobos";
grant select on "fobos".gent017 to "public" as "fobos";
grant update on "fobos".gent017 to "public" as "fobos";
grant insert on "fobos".gent017 to "public" as "fobos";
grant delete on "fobos".gent017 to "public" as "fobos";
grant index on "fobos".gent017 to "public" as "fobos";
grant select on "fobos".gent018 to "public" as "fobos";
grant update on "fobos".gent018 to "public" as "fobos";
grant insert on "fobos".gent018 to "public" as "fobos";
grant delete on "fobos".gent018 to "public" as "fobos";
grant index on "fobos".gent018 to "public" as "fobos";
grant select on "fobos".gent034 to "public" as "fobos";
grant update on "fobos".gent034 to "public" as "fobos";
grant insert on "fobos".gent034 to "public" as "fobos";
grant delete on "fobos".gent034 to "public" as "fobos";
grant index on "fobos".gent034 to "public" as "fobos";
grant select on "fobos".gent035 to "public" as "fobos";
grant update on "fobos".gent035 to "public" as "fobos";
grant insert on "fobos".gent035 to "public" as "fobos";
grant delete on "fobos".gent035 to "public" as "fobos";
grant index on "fobos".gent035 to "public" as "fobos";
grant select on "fobos".gent036 to "public" as "fobos";
grant update on "fobos".gent036 to "public" as "fobos";
grant insert on "fobos".gent036 to "public" as "fobos";
grant delete on "fobos".gent036 to "public" as "fobos";
grant index on "fobos".gent036 to "public" as "fobos";
grant select on "fobos".gent050 to "public" as "fobos";
grant update on "fobos".gent050 to "public" as "fobos";
grant insert on "fobos".gent050 to "public" as "fobos";
grant delete on "fobos".gent050 to "public" as "fobos";
grant index on "fobos".gent050 to "public" as "fobos";
grant select on "fobos".gent051 to "public" as "fobos";
grant update on "fobos".gent051 to "public" as "fobos";
grant insert on "fobos".gent051 to "public" as "fobos";
grant delete on "fobos".gent051 to "public" as "fobos";
grant index on "fobos".gent051 to "public" as "fobos";
grant select on "fobos".gent052 to "public" as "fobos";
grant update on "fobos".gent052 to "public" as "fobos";
grant insert on "fobos".gent052 to "public" as "fobos";
grant delete on "fobos".gent052 to "public" as "fobos";
grant index on "fobos".gent052 to "public" as "fobos";
grant select on "fobos".gent053 to "public" as "fobos";
grant update on "fobos".gent053 to "public" as "fobos";
grant insert on "fobos".gent053 to "public" as "fobos";
grant delete on "fobos".gent053 to "public" as "fobos";
grant index on "fobos".gent053 to "public" as "fobos";
grant select on "fobos".gent054 to "public" as "fobos";
grant update on "fobos".gent054 to "public" as "fobos";
grant insert on "fobos".gent054 to "public" as "fobos";
grant delete on "fobos".gent054 to "public" as "fobos";
grant index on "fobos".gent054 to "public" as "fobos";
grant select on "fobos".talt001 to "public" as "fobos";
grant update on "fobos".talt001 to "public" as "fobos";
grant insert on "fobos".talt001 to "public" as "fobos";
grant delete on "fobos".talt001 to "public" as "fobos";
grant index on "fobos".talt001 to "public" as "fobos";
grant select on "fobos".talt002 to "public" as "fobos";
grant update on "fobos".talt002 to "public" as "fobos";
grant insert on "fobos".talt002 to "public" as "fobos";
grant delete on "fobos".talt002 to "public" as "fobos";
grant index on "fobos".talt002 to "public" as "fobos";
grant select on "fobos".dual to "public" as "fobos";
grant update on "fobos".dual to "public" as "fobos";
grant insert on "fobos".dual to "public" as "fobos";
grant delete on "fobos".dual to "public" as "fobos";
grant index on "fobos".dual to "public" as "fobos";
grant select on "fobos".gent013 to "public" as "fobos";
grant update on "fobos".gent013 to "public" as "fobos";
grant insert on "fobos".gent013 to "public" as "fobos";
grant delete on "fobos".gent013 to "public" as "fobos";
grant index on "fobos".gent013 to "public" as "fobos";
grant select on "fobos".gent031 to "public" as "fobos";
grant update on "fobos".gent031 to "public" as "fobos";
grant insert on "fobos".gent031 to "public" as "fobos";
grant delete on "fobos".gent031 to "public" as "fobos";
grant index on "fobos".gent031 to "public" as "fobos";
grant select on "fobos".gent014 to "public" as "fobos";
grant update on "fobos".gent014 to "public" as "fobos";
grant insert on "fobos".gent014 to "public" as "fobos";
grant delete on "fobos".gent014 to "public" as "fobos";
grant index on "fobos".gent014 to "public" as "fobos";
grant select on "fobos".gent032 to "public" as "fobos";
grant update on "fobos".gent032 to "public" as "fobos";
grant insert on "fobos".gent032 to "public" as "fobos";
grant delete on "fobos".gent032 to "public" as "fobos";
grant index on "fobos".gent032 to "public" as "fobos";
grant select on "fobos".gent033 to "public" as "fobos";
grant update on "fobos".gent033 to "public" as "fobos";
grant insert on "fobos".gent033 to "public" as "fobos";
grant delete on "fobos".gent033 to "public" as "fobos";
grant index on "fobos".gent033 to "public" as "fobos";
grant select on "fobos".fobos to "public" as "fobos";
grant update on "fobos".fobos to "public" as "fobos";
grant insert on "fobos".fobos to "public" as "fobos";
grant delete on "fobos".fobos to "public" as "fobos";
grant index on "fobos".fobos to "public" as "fobos";
grant select on "fobos".gent010 to "public" as "fobos";
grant update on "fobos".gent010 to "public" as "fobos";
grant insert on "fobos".gent010 to "public" as "fobos";
grant delete on "fobos".gent010 to "public" as "fobos";
grant index on "fobos".gent010 to "public" as "fobos";
grant select on "fobos".gent020 to "public" as "fobos";
grant update on "fobos".gent020 to "public" as "fobos";
grant insert on "fobos".gent020 to "public" as "fobos";
grant delete on "fobos".gent020 to "public" as "fobos";
grant index on "fobos".gent020 to "public" as "fobos";
grant select on "fobos".gent055 to "public" as "fobos";
grant update on "fobos".gent055 to "public" as "fobos";
grant insert on "fobos".gent055 to "public" as "fobos";
grant delete on "fobos".gent055 to "public" as "fobos";
grant index on "fobos".gent055 to "public" as "fobos";
grant select on "fobos".gent006 to "public" as "fobos";
grant update on "fobos".gent006 to "public" as "fobos";
grant insert on "fobos".gent006 to "public" as "fobos";
grant delete on "fobos".gent006 to "public" as "fobos";
grant index on "fobos".gent006 to "public" as "fobos";
grant select on "fobos".gent008 to "public" as "fobos";
grant update on "fobos".gent008 to "public" as "fobos";
grant insert on "fobos".gent008 to "public" as "fobos";
grant delete on "fobos".gent008 to "public" as "fobos";
grant index on "fobos".gent008 to "public" as "fobos";
grant select on "fobos".gent030 to "public" as "fobos";
grant update on "fobos".gent030 to "public" as "fobos";
grant insert on "fobos".gent030 to "public" as "fobos";
grant delete on "fobos".gent030 to "public" as "fobos";
grant index on "fobos".gent030 to "public" as "fobos";
grant select on "fobos".gent022 to "public" as "fobos";
grant update on "fobos".gent022 to "public" as "fobos";
grant insert on "fobos".gent022 to "public" as "fobos";
grant delete on "fobos".gent022 to "public" as "fobos";
grant index on "fobos".gent022 to "public" as "fobos";
grant select on "fobos".talt003 to "public" as "fobos";
grant update on "fobos".talt003 to "public" as "fobos";
grant insert on "fobos".talt003 to "public" as "fobos";
grant delete on "fobos".talt003 to "public" as "fobos";
grant index on "fobos".talt003 to "public" as "fobos";
grant select on "fobos".talt005 to "public" as "fobos";
grant update on "fobos".talt005 to "public" as "fobos";
grant insert on "fobos".talt005 to "public" as "fobos";
grant delete on "fobos".talt005 to "public" as "fobos";
grant index on "fobos".talt005 to "public" as "fobos";
grant select on "fobos".talt006 to "public" as "fobos";
grant update on "fobos".talt006 to "public" as "fobos";
grant insert on "fobos".talt006 to "public" as "fobos";
grant delete on "fobos".talt006 to "public" as "fobos";
grant index on "fobos".talt006 to "public" as "fobos";
grant select on "fobos".talt007 to "public" as "fobos";
grant update on "fobos".talt007 to "public" as "fobos";
grant insert on "fobos".talt007 to "public" as "fobos";
grant delete on "fobos".talt007 to "public" as "fobos";
grant index on "fobos".talt007 to "public" as "fobos";
grant select on "fobos".talt008 to "public" as "fobos";
grant update on "fobos".talt008 to "public" as "fobos";
grant insert on "fobos".talt008 to "public" as "fobos";
grant delete on "fobos".talt008 to "public" as "fobos";
grant index on "fobos".talt008 to "public" as "fobos";
grant select on "fobos".talt009 to "public" as "fobos";
grant update on "fobos".talt009 to "public" as "fobos";
grant insert on "fobos".talt009 to "public" as "fobos";
grant delete on "fobos".talt009 to "public" as "fobos";
grant index on "fobos".talt009 to "public" as "fobos";
grant select on "fobos".rept000 to "public" as "fobos";
grant update on "fobos".rept000 to "public" as "fobos";
grant insert on "fobos".rept000 to "public" as "fobos";
grant delete on "fobos".rept000 to "public" as "fobos";
grant index on "fobos".rept000 to "public" as "fobos";
grant select on "fobos".rept001 to "public" as "fobos";
grant update on "fobos".rept001 to "public" as "fobos";
grant insert on "fobos".rept001 to "public" as "fobos";
grant delete on "fobos".rept001 to "public" as "fobos";
grant index on "fobos".rept001 to "public" as "fobos";
grant select on "fobos".rept002 to "public" as "fobos";
grant update on "fobos".rept002 to "public" as "fobos";
grant insert on "fobos".rept002 to "public" as "fobos";
grant delete on "fobos".rept002 to "public" as "fobos";
grant index on "fobos".rept002 to "public" as "fobos";
grant select on "fobos".rept003 to "public" as "fobos";
grant update on "fobos".rept003 to "public" as "fobos";
grant insert on "fobos".rept003 to "public" as "fobos";
grant delete on "fobos".rept003 to "public" as "fobos";
grant index on "fobos".rept003 to "public" as "fobos";
grant select on "fobos".rept004 to "public" as "fobos";
grant update on "fobos".rept004 to "public" as "fobos";
grant insert on "fobos".rept004 to "public" as "fobos";
grant delete on "fobos".rept004 to "public" as "fobos";
grant index on "fobos".rept004 to "public" as "fobos";
grant select on "fobos".rept005 to "public" as "fobos";
grant update on "fobos".rept005 to "public" as "fobos";
grant insert on "fobos".rept005 to "public" as "fobos";
grant delete on "fobos".rept005 to "public" as "fobos";
grant index on "fobos".rept005 to "public" as "fobos";
grant select on "fobos".rept006 to "public" as "fobos";
grant update on "fobos".rept006 to "public" as "fobos";
grant insert on "fobos".rept006 to "public" as "fobos";
grant delete on "fobos".rept006 to "public" as "fobos";
grant index on "fobos".rept006 to "public" as "fobos";
grant select on "fobos".rept007 to "public" as "fobos";
grant update on "fobos".rept007 to "public" as "fobos";
grant insert on "fobos".rept007 to "public" as "fobos";
grant delete on "fobos".rept007 to "public" as "fobos";
grant index on "fobos".rept007 to "public" as "fobos";
grant select on "fobos".rept008 to "public" as "fobos";
grant update on "fobos".rept008 to "public" as "fobos";
grant insert on "fobos".rept008 to "public" as "fobos";
grant delete on "fobos".rept008 to "public" as "fobos";
grant index on "fobos".rept008 to "public" as "fobos";
grant select on "fobos".rept011 to "public" as "fobos";
grant update on "fobos".rept011 to "public" as "fobos";
grant insert on "fobos".rept011 to "public" as "fobos";
grant delete on "fobos".rept011 to "public" as "fobos";
grant index on "fobos".rept011 to "public" as "fobos";
grant select on "fobos".rept012 to "public" as "fobos";
grant update on "fobos".rept012 to "public" as "fobos";
grant insert on "fobos".rept012 to "public" as "fobos";
grant delete on "fobos".rept012 to "public" as "fobos";
grant index on "fobos".rept012 to "public" as "fobos";
grant select on "fobos".rept013 to "public" as "fobos";
grant update on "fobos".rept013 to "public" as "fobos";
grant insert on "fobos".rept013 to "public" as "fobos";
grant delete on "fobos".rept013 to "public" as "fobos";
grant index on "fobos".rept013 to "public" as "fobos";
grant select on "fobos".rept014 to "public" as "fobos";
grant update on "fobos".rept014 to "public" as "fobos";
grant insert on "fobos".rept014 to "public" as "fobos";
grant delete on "fobos".rept014 to "public" as "fobos";
grant index on "fobos".rept014 to "public" as "fobos";
grant select on "fobos".rept015 to "public" as "fobos";
grant update on "fobos".rept015 to "public" as "fobos";
grant insert on "fobos".rept015 to "public" as "fobos";
grant delete on "fobos".rept015 to "public" as "fobos";
grant index on "fobos".rept015 to "public" as "fobos";
grant select on "fobos".rept016 to "public" as "fobos";
grant update on "fobos".rept016 to "public" as "fobos";
grant insert on "fobos".rept016 to "public" as "fobos";
grant delete on "fobos".rept016 to "public" as "fobos";
grant index on "fobos".rept016 to "public" as "fobos";
grant select on "fobos".rept018 to "public" as "fobos";
grant update on "fobos".rept018 to "public" as "fobos";
grant insert on "fobos".rept018 to "public" as "fobos";
grant delete on "fobos".rept018 to "public" as "fobos";
grant index on "fobos".rept018 to "public" as "fobos";
grant select on "fobos".rept022 to "public" as "fobos";
grant update on "fobos".rept022 to "public" as "fobos";
grant insert on "fobos".rept022 to "public" as "fobos";
grant delete on "fobos".rept022 to "public" as "fobos";
grant index on "fobos".rept022 to "public" as "fobos";
grant select on "fobos".rept025 to "public" as "fobos";
grant update on "fobos".rept025 to "public" as "fobos";
grant insert on "fobos".rept025 to "public" as "fobos";
grant delete on "fobos".rept025 to "public" as "fobos";
grant index on "fobos".rept025 to "public" as "fobos";
grant select on "fobos".rept026 to "public" as "fobos";
grant update on "fobos".rept026 to "public" as "fobos";
grant insert on "fobos".rept026 to "public" as "fobos";
grant delete on "fobos".rept026 to "public" as "fobos";
grant index on "fobos".rept026 to "public" as "fobos";
grant select on "fobos".rept029 to "public" as "fobos";
grant update on "fobos".rept029 to "public" as "fobos";
grant insert on "fobos".rept029 to "public" as "fobos";
grant delete on "fobos".rept029 to "public" as "fobos";
grant index on "fobos".rept029 to "public" as "fobos";
grant select on "fobos".rept031 to "public" as "fobos";
grant update on "fobos".rept031 to "public" as "fobos";
grant insert on "fobos".rept031 to "public" as "fobos";
grant delete on "fobos".rept031 to "public" as "fobos";
grant index on "fobos".rept031 to "public" as "fobos";
grant select on "fobos".rept032 to "public" as "fobos";
grant update on "fobos".rept032 to "public" as "fobos";
grant insert on "fobos".rept032 to "public" as "fobos";
grant delete on "fobos".rept032 to "public" as "fobos";
grant index on "fobos".rept032 to "public" as "fobos";
grant select on "fobos".rept033 to "public" as "fobos";
grant update on "fobos".rept033 to "public" as "fobos";
grant insert on "fobos".rept033 to "public" as "fobos";
grant delete on "fobos".rept033 to "public" as "fobos";
grant index on "fobos".rept033 to "public" as "fobos";
grant select on "fobos".rept050 to "public" as "fobos";
grant update on "fobos".rept050 to "public" as "fobos";
grant insert on "fobos".rept050 to "public" as "fobos";
grant delete on "fobos".rept050 to "public" as "fobos";
grant index on "fobos".rept050 to "public" as "fobos";
grant select on "fobos".rept051 to "public" as "fobos";
grant update on "fobos".rept051 to "public" as "fobos";
grant insert on "fobos".rept051 to "public" as "fobos";
grant delete on "fobos".rept051 to "public" as "fobos";
grant index on "fobos".rept051 to "public" as "fobos";
grant select on "fobos".rept052 to "public" as "fobos";
grant update on "fobos".rept052 to "public" as "fobos";
grant insert on "fobos".rept052 to "public" as "fobos";
grant delete on "fobos".rept052 to "public" as "fobos";
grant index on "fobos".rept052 to "public" as "fobos";
grant select on "fobos".rept060 to "public" as "fobos";
grant update on "fobos".rept060 to "public" as "fobos";
grant insert on "fobos".rept060 to "public" as "fobos";
grant delete on "fobos".rept060 to "public" as "fobos";
grant index on "fobos".rept060 to "public" as "fobos";
grant select on "fobos".rept061 to "public" as "fobos";
grant update on "fobos".rept061 to "public" as "fobos";
grant insert on "fobos".rept061 to "public" as "fobos";
grant delete on "fobos".rept061 to "public" as "fobos";
grant index on "fobos".rept061 to "public" as "fobos";
grant select on "fobos".rept062 to "public" as "fobos";
grant update on "fobos".rept062 to "public" as "fobos";
grant insert on "fobos".rept062 to "public" as "fobos";
grant delete on "fobos".rept062 to "public" as "fobos";
grant index on "fobos".rept062 to "public" as "fobos";
grant select on "fobos".talt000 to "public" as "fobos";
grant update on "fobos".talt000 to "public" as "fobos";
grant insert on "fobos".talt000 to "public" as "fobos";
grant delete on "fobos".talt000 to "public" as "fobos";
grant index on "fobos".talt000 to "public" as "fobos";
grant select on "fobos".veht001 to "public" as "fobos";
grant update on "fobos".veht001 to "public" as "fobos";
grant insert on "fobos".veht001 to "public" as "fobos";
grant delete on "fobos".veht001 to "public" as "fobos";
grant index on "fobos".veht001 to "public" as "fobos";
grant select on "fobos".veht002 to "public" as "fobos";
grant update on "fobos".veht002 to "public" as "fobos";
grant insert on "fobos".veht002 to "public" as "fobos";
grant delete on "fobos".veht002 to "public" as "fobos";
grant index on "fobos".veht002 to "public" as "fobos";
grant select on "fobos".veht004 to "public" as "fobos";
grant update on "fobos".veht004 to "public" as "fobos";
grant insert on "fobos".veht004 to "public" as "fobos";
grant delete on "fobos".veht004 to "public" as "fobos";
grant index on "fobos".veht004 to "public" as "fobos";
grant select on "fobos".veht005 to "public" as "fobos";
grant update on "fobos".veht005 to "public" as "fobos";
grant insert on "fobos".veht005 to "public" as "fobos";
grant delete on "fobos".veht005 to "public" as "fobos";
grant index on "fobos".veht005 to "public" as "fobos";
grant select on "fobos".veht007 to "public" as "fobos";
grant update on "fobos".veht007 to "public" as "fobos";
grant insert on "fobos".veht007 to "public" as "fobos";
grant delete on "fobos".veht007 to "public" as "fobos";
grant index on "fobos".veht007 to "public" as "fobos";
grant select on "fobos".veht020 to "public" as "fobos";
grant update on "fobos".veht020 to "public" as "fobos";
grant insert on "fobos".veht020 to "public" as "fobos";
grant delete on "fobos".veht020 to "public" as "fobos";
grant index on "fobos".veht020 to "public" as "fobos";
grant select on "fobos".veht021 to "public" as "fobos";
grant update on "fobos".veht021 to "public" as "fobos";
grant insert on "fobos".veht021 to "public" as "fobos";
grant delete on "fobos".veht021 to "public" as "fobos";
grant index on "fobos".veht021 to "public" as "fobos";
grant select on "fobos".veht024 to "public" as "fobos";
grant update on "fobos".veht024 to "public" as "fobos";
grant insert on "fobos".veht024 to "public" as "fobos";
grant delete on "fobos".veht024 to "public" as "fobos";
grant index on "fobos".veht024 to "public" as "fobos";
grant select on "fobos".veht025 to "public" as "fobos";
grant update on "fobos".veht025 to "public" as "fobos";
grant insert on "fobos".veht025 to "public" as "fobos";
grant delete on "fobos".veht025 to "public" as "fobos";
grant index on "fobos".veht025 to "public" as "fobos";
grant select on "fobos".veht026 to "public" as "fobos";
grant update on "fobos".veht026 to "public" as "fobos";
grant insert on "fobos".veht026 to "public" as "fobos";
grant delete on "fobos".veht026 to "public" as "fobos";
grant index on "fobos".veht026 to "public" as "fobos";
grant select on "fobos".veht027 to "public" as "fobos";
grant update on "fobos".veht027 to "public" as "fobos";
grant insert on "fobos".veht027 to "public" as "fobos";
grant delete on "fobos".veht027 to "public" as "fobos";
grant index on "fobos".veht027 to "public" as "fobos";
grant select on "fobos".veht028 to "public" as "fobos";
grant update on "fobos".veht028 to "public" as "fobos";
grant insert on "fobos".veht028 to "public" as "fobos";
grant delete on "fobos".veht028 to "public" as "fobos";
grant index on "fobos".veht028 to "public" as "fobos";
grant select on "fobos".veht029 to "public" as "fobos";
grant update on "fobos".veht029 to "public" as "fobos";
grant insert on "fobos".veht029 to "public" as "fobos";
grant delete on "fobos".veht029 to "public" as "fobos";
grant index on "fobos".veht029 to "public" as "fobos";
grant select on "fobos".veht030 to "public" as "fobos";
grant update on "fobos".veht030 to "public" as "fobos";
grant insert on "fobos".veht030 to "public" as "fobos";
grant delete on "fobos".veht030 to "public" as "fobos";
grant index on "fobos".veht030 to "public" as "fobos";
grant select on "fobos".veht032 to "public" as "fobos";
grant update on "fobos".veht032 to "public" as "fobos";
grant insert on "fobos".veht032 to "public" as "fobos";
grant delete on "fobos".veht032 to "public" as "fobos";
grant index on "fobos".veht032 to "public" as "fobos";
grant select on "fobos".veht034 to "public" as "fobos";
grant update on "fobos".veht034 to "public" as "fobos";
grant insert on "fobos".veht034 to "public" as "fobos";
grant delete on "fobos".veht034 to "public" as "fobos";
grant index on "fobos".veht034 to "public" as "fobos";
grant select on "fobos".veht035 to "public" as "fobos";
grant update on "fobos".veht035 to "public" as "fobos";
grant insert on "fobos".veht035 to "public" as "fobos";
grant delete on "fobos".veht035 to "public" as "fobos";
grant index on "fobos".veht035 to "public" as "fobos";
grant select on "fobos".veht036 to "public" as "fobos";
grant update on "fobos".veht036 to "public" as "fobos";
grant insert on "fobos".veht036 to "public" as "fobos";
grant delete on "fobos".veht036 to "public" as "fobos";
grant index on "fobos".veht036 to "public" as "fobos";
grant select on "fobos".veht037 to "public" as "fobos";
grant update on "fobos".veht037 to "public" as "fobos";
grant insert on "fobos".veht037 to "public" as "fobos";
grant delete on "fobos".veht037 to "public" as "fobos";
grant index on "fobos".veht037 to "public" as "fobos";
grant select on "fobos".veht039 to "public" as "fobos";
grant update on "fobos".veht039 to "public" as "fobos";
grant insert on "fobos".veht039 to "public" as "fobos";
grant delete on "fobos".veht039 to "public" as "fobos";
grant index on "fobos".veht039 to "public" as "fobos";
grant select on "fobos".veht040 to "public" as "fobos";
grant update on "fobos".veht040 to "public" as "fobos";
grant insert on "fobos".veht040 to "public" as "fobos";
grant delete on "fobos".veht040 to "public" as "fobos";
grant index on "fobos".veht040 to "public" as "fobos";
grant select on "fobos".ordt000 to "public" as "fobos";
grant update on "fobos".ordt000 to "public" as "fobos";
grant insert on "fobos".ordt000 to "public" as "fobos";
grant delete on "fobos".ordt000 to "public" as "fobos";
grant index on "fobos".ordt000 to "public" as "fobos";
grant select on "fobos".ordt010 to "public" as "fobos";
grant update on "fobos".ordt010 to "public" as "fobos";
grant insert on "fobos".ordt010 to "public" as "fobos";
grant delete on "fobos".ordt010 to "public" as "fobos";
grant index on "fobos".ordt010 to "public" as "fobos";
grant select on "fobos".ordt012 to "public" as "fobos";
grant update on "fobos".ordt012 to "public" as "fobos";
grant insert on "fobos".ordt012 to "public" as "fobos";
grant delete on "fobos".ordt012 to "public" as "fobos";
grant index on "fobos".ordt012 to "public" as "fobos";
grant select on "fobos".ordt013 to "public" as "fobos";
grant update on "fobos".ordt013 to "public" as "fobos";
grant insert on "fobos".ordt013 to "public" as "fobos";
grant delete on "fobos".ordt013 to "public" as "fobos";
grant index on "fobos".ordt013 to "public" as "fobos";
grant select on "fobos".veht000 to "public" as "fobos";
grant update on "fobos".veht000 to "public" as "fobos";
grant insert on "fobos".veht000 to "public" as "fobos";
grant delete on "fobos".veht000 to "public" as "fobos";
grant index on "fobos".veht000 to "public" as "fobos";
grant select on "fobos".veht006 to "public" as "fobos";
grant update on "fobos".veht006 to "public" as "fobos";
grant insert on "fobos".veht006 to "public" as "fobos";
grant delete on "fobos".veht006 to "public" as "fobos";
grant index on "fobos".veht006 to "public" as "fobos";
grant select on "fobos".cxct000 to "public" as "fobos";
grant update on "fobos".cxct000 to "public" as "fobos";
grant insert on "fobos".cxct000 to "public" as "fobos";
grant delete on "fobos".cxct000 to "public" as "fobos";
grant index on "fobos".cxct000 to "public" as "fobos";
grant select on "fobos".cxct002 to "public" as "fobos";
grant update on "fobos".cxct002 to "public" as "fobos";
grant insert on "fobos".cxct002 to "public" as "fobos";
grant delete on "fobos".cxct002 to "public" as "fobos";
grant index on "fobos".cxct002 to "public" as "fobos";
grant select on "fobos".cxct003 to "public" as "fobos";
grant update on "fobos".cxct003 to "public" as "fobos";
grant insert on "fobos".cxct003 to "public" as "fobos";
grant delete on "fobos".cxct003 to "public" as "fobos";
grant index on "fobos".cxct003 to "public" as "fobos";
grant select on "fobos".cxct004 to "public" as "fobos";
grant update on "fobos".cxct004 to "public" as "fobos";
grant insert on "fobos".cxct004 to "public" as "fobos";
grant delete on "fobos".cxct004 to "public" as "fobos";
grant index on "fobos".cxct004 to "public" as "fobos";
grant select on "fobos".cxct005 to "public" as "fobos";
grant update on "fobos".cxct005 to "public" as "fobos";
grant insert on "fobos".cxct005 to "public" as "fobos";
grant delete on "fobos".cxct005 to "public" as "fobos";
grant index on "fobos".cxct005 to "public" as "fobos";
grant select on "fobos".cxct006 to "public" as "fobos";
grant update on "fobos".cxct006 to "public" as "fobos";
grant insert on "fobos".cxct006 to "public" as "fobos";
grant delete on "fobos".cxct006 to "public" as "fobos";
grant index on "fobos".cxct006 to "public" as "fobos";
grant select on "fobos".cxct007 to "public" as "fobos";
grant update on "fobos".cxct007 to "public" as "fobos";
grant insert on "fobos".cxct007 to "public" as "fobos";
grant delete on "fobos".cxct007 to "public" as "fobos";
grant index on "fobos".cxct007 to "public" as "fobos";
grant select on "fobos".cxct026 to "public" as "fobos";
grant update on "fobos".cxct026 to "public" as "fobos";
grant insert on "fobos".cxct026 to "public" as "fobos";
grant delete on "fobos".cxct026 to "public" as "fobos";
grant index on "fobos".cxct026 to "public" as "fobos";
grant select on "fobos".cxct030 to "public" as "fobos";
grant update on "fobos".cxct030 to "public" as "fobos";
grant insert on "fobos".cxct030 to "public" as "fobos";
grant delete on "fobos".cxct030 to "public" as "fobos";
grant index on "fobos".cxct030 to "public" as "fobos";
grant select on "fobos".cxct031 to "public" as "fobos";
grant update on "fobos".cxct031 to "public" as "fobos";
grant insert on "fobos".cxct031 to "public" as "fobos";
grant delete on "fobos".cxct031 to "public" as "fobos";
grant index on "fobos".cxct031 to "public" as "fobos";
grant select on "fobos".cxct032 to "public" as "fobos";
grant update on "fobos".cxct032 to "public" as "fobos";
grant insert on "fobos".cxct032 to "public" as "fobos";
grant delete on "fobos".cxct032 to "public" as "fobos";
grant index on "fobos".cxct032 to "public" as "fobos";
grant select on "fobos".cxpt000 to "public" as "fobos";
grant update on "fobos".cxpt000 to "public" as "fobos";
grant insert on "fobos".cxpt000 to "public" as "fobos";
grant delete on "fobos".cxpt000 to "public" as "fobos";
grant index on "fobos".cxpt000 to "public" as "fobos";
grant select on "fobos".cxpt002 to "public" as "fobos";
grant update on "fobos".cxpt002 to "public" as "fobos";
grant insert on "fobos".cxpt002 to "public" as "fobos";
grant delete on "fobos".cxpt002 to "public" as "fobos";
grant index on "fobos".cxpt002 to "public" as "fobos";
grant select on "fobos".cxpt003 to "public" as "fobos";
grant update on "fobos".cxpt003 to "public" as "fobos";
grant insert on "fobos".cxpt003 to "public" as "fobos";
grant delete on "fobos".cxpt003 to "public" as "fobos";
grant index on "fobos".cxpt003 to "public" as "fobos";
grant select on "fobos".cxpt004 to "public" as "fobos";
grant update on "fobos".cxpt004 to "public" as "fobos";
grant insert on "fobos".cxpt004 to "public" as "fobos";
grant delete on "fobos".cxpt004 to "public" as "fobos";
grant index on "fobos".cxpt004 to "public" as "fobos";
grant select on "fobos".cxpt025 to "public" as "fobos";
grant update on "fobos".cxpt025 to "public" as "fobos";
grant insert on "fobos".cxpt025 to "public" as "fobos";
grant delete on "fobos".cxpt025 to "public" as "fobos";
grant index on "fobos".cxpt025 to "public" as "fobos";
grant select on "fobos".cxpt026 to "public" as "fobos";
grant update on "fobos".cxpt026 to "public" as "fobos";
grant insert on "fobos".cxpt026 to "public" as "fobos";
grant delete on "fobos".cxpt026 to "public" as "fobos";
grant index on "fobos".cxpt026 to "public" as "fobos";
grant select on "fobos".cxpt028 to "public" as "fobos";
grant update on "fobos".cxpt028 to "public" as "fobos";
grant insert on "fobos".cxpt028 to "public" as "fobos";
grant delete on "fobos".cxpt028 to "public" as "fobos";
grant index on "fobos".cxpt028 to "public" as "fobos";
grant select on "fobos".cajt000 to "public" as "fobos";
grant update on "fobos".cajt000 to "public" as "fobos";
grant insert on "fobos".cajt000 to "public" as "fobos";
grant delete on "fobos".cajt000 to "public" as "fobos";
grant index on "fobos".cajt000 to "public" as "fobos";
grant select on "fobos".cajt001 to "public" as "fobos";
grant update on "fobos".cajt001 to "public" as "fobos";
grant insert on "fobos".cajt001 to "public" as "fobos";
grant delete on "fobos".cajt001 to "public" as "fobos";
grant index on "fobos".cajt001 to "public" as "fobos";
grant select on "fobos".cajt002 to "public" as "fobos";
grant update on "fobos".cajt002 to "public" as "fobos";
grant insert on "fobos".cajt002 to "public" as "fobos";
grant delete on "fobos".cajt002 to "public" as "fobos";
grant index on "fobos".cajt002 to "public" as "fobos";
grant select on "fobos".cajt003 to "public" as "fobos";
grant update on "fobos".cajt003 to "public" as "fobos";
grant insert on "fobos".cajt003 to "public" as "fobos";
grant delete on "fobos".cajt003 to "public" as "fobos";
grant index on "fobos".cajt003 to "public" as "fobos";
grant select on "fobos".cajt999 to "public" as "fobos";
grant update on "fobos".cajt999 to "public" as "fobos";
grant insert on "fobos".cajt999 to "public" as "fobos";
grant delete on "fobos".cajt999 to "public" as "fobos";
grant index on "fobos".cajt999 to "public" as "fobos";
grant select on "fobos".cajt012 to "public" as "fobos";
grant update on "fobos".cajt012 to "public" as "fobos";
grant insert on "fobos".cajt012 to "public" as "fobos";
grant delete on "fobos".cajt012 to "public" as "fobos";
grant index on "fobos".cajt012 to "public" as "fobos";
grant select on "fobos".cajt013 to "public" as "fobos";
grant update on "fobos".cajt013 to "public" as "fobos";
grant insert on "fobos".cajt013 to "public" as "fobos";
grant delete on "fobos".cajt013 to "public" as "fobos";
grant index on "fobos".cajt013 to "public" as "fobos";
grant select on "fobos".ccht000 to "public" as "fobos";
grant update on "fobos".ccht000 to "public" as "fobos";
grant insert on "fobos".ccht000 to "public" as "fobos";
grant delete on "fobos".ccht000 to "public" as "fobos";
grant index on "fobos".ccht000 to "public" as "fobos";
grant select on "fobos".ccht001 to "public" as "fobos";
grant update on "fobos".ccht001 to "public" as "fobos";
grant insert on "fobos".ccht001 to "public" as "fobos";
grant delete on "fobos".ccht001 to "public" as "fobos";
grant index on "fobos".ccht001 to "public" as "fobos";
grant select on "fobos".ccht002 to "public" as "fobos";
grant update on "fobos".ccht002 to "public" as "fobos";
grant insert on "fobos".ccht002 to "public" as "fobos";
grant delete on "fobos".ccht002 to "public" as "fobos";
grant index on "fobos".ccht002 to "public" as "fobos";
grant select on "fobos".ccht003 to "public" as "fobos";
grant update on "fobos".ccht003 to "public" as "fobos";
grant insert on "fobos".ccht003 to "public" as "fobos";
grant delete on "fobos".ccht003 to "public" as "fobos";
grant index on "fobos".ccht003 to "public" as "fobos";
grant select on "fobos".rolt000 to "public" as "fobos";
grant update on "fobos".rolt000 to "public" as "fobos";
grant insert on "fobos".rolt000 to "public" as "fobos";
grant delete on "fobos".rolt000 to "public" as "fobos";
grant index on "fobos".rolt000 to "public" as "fobos";
grant select on "fobos".rolt001 to "public" as "fobos";
grant update on "fobos".rolt001 to "public" as "fobos";
grant insert on "fobos".rolt001 to "public" as "fobos";
grant delete on "fobos".rolt001 to "public" as "fobos";
grant index on "fobos".rolt001 to "public" as "fobos";
grant select on "fobos".rolt002 to "public" as "fobos";
grant update on "fobos".rolt002 to "public" as "fobos";
grant insert on "fobos".rolt002 to "public" as "fobos";
grant delete on "fobos".rolt002 to "public" as "fobos";
grant index on "fobos".rolt002 to "public" as "fobos";
grant select on "fobos".rolt003 to "public" as "fobos";
grant update on "fobos".rolt003 to "public" as "fobos";
grant insert on "fobos".rolt003 to "public" as "fobos";
grant delete on "fobos".rolt003 to "public" as "fobos";
grant index on "fobos".rolt003 to "public" as "fobos";
grant select on "fobos".rolt004 to "public" as "fobos";
grant update on "fobos".rolt004 to "public" as "fobos";
grant insert on "fobos".rolt004 to "public" as "fobos";
grant delete on "fobos".rolt004 to "public" as "fobos";
grant index on "fobos".rolt004 to "public" as "fobos";
grant select on "fobos".rolt005 to "public" as "fobos";
grant update on "fobos".rolt005 to "public" as "fobos";
grant insert on "fobos".rolt005 to "public" as "fobos";
grant delete on "fobos".rolt005 to "public" as "fobos";
grant index on "fobos".rolt005 to "public" as "fobos";
grant select on "fobos".rolt006 to "public" as "fobos";
grant update on "fobos".rolt006 to "public" as "fobos";
grant insert on "fobos".rolt006 to "public" as "fobos";
grant delete on "fobos".rolt006 to "public" as "fobos";
grant index on "fobos".rolt006 to "public" as "fobos";
grant select on "fobos".rolt007 to "public" as "fobos";
grant update on "fobos".rolt007 to "public" as "fobos";
grant insert on "fobos".rolt007 to "public" as "fobos";
grant delete on "fobos".rolt007 to "public" as "fobos";
grant index on "fobos".rolt007 to "public" as "fobos";
grant select on "fobos".rolt008 to "public" as "fobos";
grant update on "fobos".rolt008 to "public" as "fobos";
grant insert on "fobos".rolt008 to "public" as "fobos";
grant delete on "fobos".rolt008 to "public" as "fobos";
grant index on "fobos".rolt008 to "public" as "fobos";
grant select on "fobos".rolt009 to "public" as "fobos";
grant update on "fobos".rolt009 to "public" as "fobos";
grant insert on "fobos".rolt009 to "public" as "fobos";
grant delete on "fobos".rolt009 to "public" as "fobos";
grant index on "fobos".rolt009 to "public" as "fobos";
grant select on "fobos".rolt010 to "public" as "fobos";
grant update on "fobos".rolt010 to "public" as "fobos";
grant insert on "fobos".rolt010 to "public" as "fobos";
grant delete on "fobos".rolt010 to "public" as "fobos";
grant index on "fobos".rolt010 to "public" as "fobos";
grant select on "fobos".rolt011 to "public" as "fobos";
grant update on "fobos".rolt011 to "public" as "fobos";
grant insert on "fobos".rolt011 to "public" as "fobos";
grant delete on "fobos".rolt011 to "public" as "fobos";
grant index on "fobos".rolt011 to "public" as "fobos";
grant select on "fobos".rolt012 to "public" as "fobos";
grant update on "fobos".rolt012 to "public" as "fobos";
grant insert on "fobos".rolt012 to "public" as "fobos";
grant delete on "fobos".rolt012 to "public" as "fobos";
grant index on "fobos".rolt012 to "public" as "fobos";
grant select on "fobos".rolt013 to "public" as "fobos";
grant update on "fobos".rolt013 to "public" as "fobos";
grant insert on "fobos".rolt013 to "public" as "fobos";
grant delete on "fobos".rolt013 to "public" as "fobos";
grant index on "fobos".rolt013 to "public" as "fobos";
grant select on "fobos".rolt014 to "public" as "fobos";
grant update on "fobos".rolt014 to "public" as "fobos";
grant insert on "fobos".rolt014 to "public" as "fobos";
grant delete on "fobos".rolt014 to "public" as "fobos";
grant index on "fobos".rolt014 to "public" as "fobos";
grant select on "fobos".rolt030 to "public" as "fobos";
grant update on "fobos".rolt030 to "public" as "fobos";
grant insert on "fobos".rolt030 to "public" as "fobos";
grant delete on "fobos".rolt030 to "public" as "fobos";
grant index on "fobos".rolt030 to "public" as "fobos";
grant select on "fobos".rolt032 to "public" as "fobos";
grant update on "fobos".rolt032 to "public" as "fobos";
grant insert on "fobos".rolt032 to "public" as "fobos";
grant delete on "fobos".rolt032 to "public" as "fobos";
grant index on "fobos".rolt032 to "public" as "fobos";
grant select on "fobos".rolt033 to "public" as "fobos";
grant update on "fobos".rolt033 to "public" as "fobos";
grant insert on "fobos".rolt033 to "public" as "fobos";
grant delete on "fobos".rolt033 to "public" as "fobos";
grant index on "fobos".rolt033 to "public" as "fobos";
grant select on "fobos".rolt034 to "public" as "fobos";
grant update on "fobos".rolt034 to "public" as "fobos";
grant insert on "fobos".rolt034 to "public" as "fobos";
grant delete on "fobos".rolt034 to "public" as "fobos";
grant index on "fobos".rolt034 to "public" as "fobos";
grant select on "fobos".rolt035 to "public" as "fobos";
grant update on "fobos".rolt035 to "public" as "fobos";
grant insert on "fobos".rolt035 to "public" as "fobos";
grant delete on "fobos".rolt035 to "public" as "fobos";
grant index on "fobos".rolt035 to "public" as "fobos";
grant select on "fobos".rolt036 to "public" as "fobos";
grant update on "fobos".rolt036 to "public" as "fobos";
grant insert on "fobos".rolt036 to "public" as "fobos";
grant delete on "fobos".rolt036 to "public" as "fobos";
grant index on "fobos".rolt036 to "public" as "fobos";
grant select on "fobos".rolt037 to "public" as "fobos";
grant update on "fobos".rolt037 to "public" as "fobos";
grant insert on "fobos".rolt037 to "public" as "fobos";
grant delete on "fobos".rolt037 to "public" as "fobos";
grant index on "fobos".rolt037 to "public" as "fobos";
grant select on "fobos".rolt038 to "public" as "fobos";
grant update on "fobos".rolt038 to "public" as "fobos";
grant insert on "fobos".rolt038 to "public" as "fobos";
grant delete on "fobos".rolt038 to "public" as "fobos";
grant index on "fobos".rolt038 to "public" as "fobos";
grant select on "fobos".rolt042 to "public" as "fobos";
grant update on "fobos".rolt042 to "public" as "fobos";
grant insert on "fobos".rolt042 to "public" as "fobos";
grant delete on "fobos".rolt042 to "public" as "fobos";
grant index on "fobos".rolt042 to "public" as "fobos";
grant select on "fobos".rolt043 to "public" as "fobos";
grant update on "fobos".rolt043 to "public" as "fobos";
grant insert on "fobos".rolt043 to "public" as "fobos";
grant delete on "fobos".rolt043 to "public" as "fobos";
grant index on "fobos".rolt043 to "public" as "fobos";
grant select on "fobos".rolt044 to "public" as "fobos";
grant update on "fobos".rolt044 to "public" as "fobos";
grant insert on "fobos".rolt044 to "public" as "fobos";
grant delete on "fobos".rolt044 to "public" as "fobos";
grant index on "fobos".rolt044 to "public" as "fobos";
grant select on "fobos".rolt045 to "public" as "fobos";
grant update on "fobos".rolt045 to "public" as "fobos";
grant insert on "fobos".rolt045 to "public" as "fobos";
grant delete on "fobos".rolt045 to "public" as "fobos";
grant index on "fobos".rolt045 to "public" as "fobos";
grant select on "fobos".rolt046 to "public" as "fobos";
grant update on "fobos".rolt046 to "public" as "fobos";
grant insert on "fobos".rolt046 to "public" as "fobos";
grant delete on "fobos".rolt046 to "public" as "fobos";
grant index on "fobos".rolt046 to "public" as "fobos";
grant select on "fobos".actt000 to "public" as "fobos";
grant update on "fobos".actt000 to "public" as "fobos";
grant insert on "fobos".actt000 to "public" as "fobos";
grant delete on "fobos".actt000 to "public" as "fobos";
grant index on "fobos".actt000 to "public" as "fobos";
grant select on "fobos".actt003 to "public" as "fobos";
grant update on "fobos".actt003 to "public" as "fobos";
grant insert on "fobos".actt003 to "public" as "fobos";
grant delete on "fobos".actt003 to "public" as "fobos";
grant index on "fobos".actt003 to "public" as "fobos";
grant select on "fobos".actt004 to "public" as "fobos";
grant update on "fobos".actt004 to "public" as "fobos";
grant insert on "fobos".actt004 to "public" as "fobos";
grant delete on "fobos".actt004 to "public" as "fobos";
grant index on "fobos".actt004 to "public" as "fobos";
grant select on "fobos".actt005 to "public" as "fobos";
grant update on "fobos".actt005 to "public" as "fobos";
grant insert on "fobos".actt005 to "public" as "fobos";
grant delete on "fobos".actt005 to "public" as "fobos";
grant index on "fobos".actt005 to "public" as "fobos";
grant select on "fobos".actt011 to "public" as "fobos";
grant update on "fobos".actt011 to "public" as "fobos";
grant insert on "fobos".actt011 to "public" as "fobos";
grant delete on "fobos".actt011 to "public" as "fobos";
grant index on "fobos".actt011 to "public" as "fobos";
grant select on "fobos".ctbt000 to "public" as "fobos";
grant update on "fobos".ctbt000 to "public" as "fobos";
grant insert on "fobos".ctbt000 to "public" as "fobos";
grant delete on "fobos".ctbt000 to "public" as "fobos";
grant index on "fobos".ctbt000 to "public" as "fobos";
grant select on "fobos".ctbt001 to "public" as "fobos";
grant update on "fobos".ctbt001 to "public" as "fobos";
grant insert on "fobos".ctbt001 to "public" as "fobos";
grant delete on "fobos".ctbt001 to "public" as "fobos";
grant index on "fobos".ctbt001 to "public" as "fobos";
grant select on "fobos".ctbt002 to "public" as "fobos";
grant update on "fobos".ctbt002 to "public" as "fobos";
grant insert on "fobos".ctbt002 to "public" as "fobos";
grant delete on "fobos".ctbt002 to "public" as "fobos";
grant index on "fobos".ctbt002 to "public" as "fobos";
grant select on "fobos".ctbt003 to "public" as "fobos";
grant update on "fobos".ctbt003 to "public" as "fobos";
grant insert on "fobos".ctbt003 to "public" as "fobos";
grant delete on "fobos".ctbt003 to "public" as "fobos";
grant index on "fobos".ctbt003 to "public" as "fobos";
grant select on "fobos".ctbt004 to "public" as "fobos";
grant update on "fobos".ctbt004 to "public" as "fobos";
grant insert on "fobos".ctbt004 to "public" as "fobos";
grant delete on "fobos".ctbt004 to "public" as "fobos";
grant index on "fobos".ctbt004 to "public" as "fobos";
grant select on "fobos".ctbt005 to "public" as "fobos";
grant update on "fobos".ctbt005 to "public" as "fobos";
grant insert on "fobos".ctbt005 to "public" as "fobos";
grant delete on "fobos".ctbt005 to "public" as "fobos";
grant index on "fobos".ctbt005 to "public" as "fobos";
grant select on "fobos".ctbt006 to "public" as "fobos";
grant update on "fobos".ctbt006 to "public" as "fobos";
grant insert on "fobos".ctbt006 to "public" as "fobos";
grant delete on "fobos".ctbt006 to "public" as "fobos";
grant index on "fobos".ctbt006 to "public" as "fobos";
grant select on "fobos".ctbt007 to "public" as "fobos";
grant update on "fobos".ctbt007 to "public" as "fobos";
grant insert on "fobos".ctbt007 to "public" as "fobos";
grant delete on "fobos".ctbt007 to "public" as "fobos";
grant index on "fobos".ctbt007 to "public" as "fobos";
grant select on "fobos".ctbt008 to "public" as "fobos";
grant update on "fobos".ctbt008 to "public" as "fobos";
grant insert on "fobos".ctbt008 to "public" as "fobos";
grant delete on "fobos".ctbt008 to "public" as "fobos";
grant index on "fobos".ctbt008 to "public" as "fobos";
grant select on "fobos".ctbt010 to "public" as "fobos";
grant update on "fobos".ctbt010 to "public" as "fobos";
grant insert on "fobos".ctbt010 to "public" as "fobos";
grant delete on "fobos".ctbt010 to "public" as "fobos";
grant index on "fobos".ctbt010 to "public" as "fobos";
grant select on "fobos".ctbt011 to "public" as "fobos";
grant update on "fobos".ctbt011 to "public" as "fobos";
grant insert on "fobos".ctbt011 to "public" as "fobos";
grant delete on "fobos".ctbt011 to "public" as "fobos";
grant index on "fobos".ctbt011 to "public" as "fobos";
grant select on "fobos".ctbt014 to "public" as "fobos";
grant update on "fobos".ctbt014 to "public" as "fobos";
grant insert on "fobos".ctbt014 to "public" as "fobos";
grant delete on "fobos".ctbt014 to "public" as "fobos";
grant index on "fobos".ctbt014 to "public" as "fobos";
grant select on "fobos".ctbt015 to "public" as "fobos";
grant update on "fobos".ctbt015 to "public" as "fobos";
grant insert on "fobos".ctbt015 to "public" as "fobos";
grant delete on "fobos".ctbt015 to "public" as "fobos";
grant index on "fobos".ctbt015 to "public" as "fobos";
grant select on "fobos".ctbt016 to "public" as "fobos";
grant update on "fobos".ctbt016 to "public" as "fobos";
grant insert on "fobos".ctbt016 to "public" as "fobos";
grant delete on "fobos".ctbt016 to "public" as "fobos";
grant index on "fobos".ctbt016 to "public" as "fobos";
grant select on "fobos".ctbt030 to "public" as "fobos";
grant update on "fobos".ctbt030 to "public" as "fobos";
grant insert on "fobos".ctbt030 to "public" as "fobos";
grant delete on "fobos".ctbt030 to "public" as "fobos";
grant index on "fobos".ctbt030 to "public" as "fobos";
grant select on "fobos".ctbt031 to "public" as "fobos";
grant update on "fobos".ctbt031 to "public" as "fobos";
grant insert on "fobos".ctbt031 to "public" as "fobos";
grant delete on "fobos".ctbt031 to "public" as "fobos";
grant index on "fobos".ctbt031 to "public" as "fobos";
grant select on "fobos".talt004 to "public" as "fobos";
grant update on "fobos".talt004 to "public" as "fobos";
grant insert on "fobos".talt004 to "public" as "fobos";
grant delete on "fobos".talt004 to "public" as "fobos";
grant index on "fobos".talt004 to "public" as "fobos";
grant select on "fobos".gent015 to "public" as "fobos";
grant update on "fobos".gent015 to "public" as "fobos";
grant insert on "fobos".gent015 to "public" as "fobos";
grant delete on "fobos".gent015 to "public" as "fobos";
grant index on "fobos".gent015 to "public" as "fobos";
grant select on "fobos".talt022 to "public" as "fobos";
grant update on "fobos".talt022 to "public" as "fobos";
grant insert on "fobos".talt022 to "public" as "fobos";
grant delete on "fobos".talt022 to "public" as "fobos";
grant index on "fobos".talt022 to "public" as "fobos";
grant select on "fobos".talt024 to "public" as "fobos";
grant update on "fobos".talt024 to "public" as "fobos";
grant insert on "fobos".talt024 to "public" as "fobos";
grant delete on "fobos".talt024 to "public" as "fobos";
grant index on "fobos".talt024 to "public" as "fobos";
grant select on "fobos".talt025 to "public" as "fobos";
grant update on "fobos".talt025 to "public" as "fobos";
grant insert on "fobos".talt025 to "public" as "fobos";
grant delete on "fobos".talt025 to "public" as "fobos";
grant index on "fobos".talt025 to "public" as "fobos";
grant select on "fobos".talt026 to "public" as "fobos";
grant update on "fobos".talt026 to "public" as "fobos";
grant insert on "fobos".talt026 to "public" as "fobos";
grant delete on "fobos".talt026 to "public" as "fobos";
grant index on "fobos".talt026 to "public" as "fobos";
grant select on "fobos".talt027 to "public" as "fobos";
grant update on "fobos".talt027 to "public" as "fobos";
grant insert on "fobos".talt027 to "public" as "fobos";
grant delete on "fobos".talt027 to "public" as "fobos";
grant index on "fobos".talt027 to "public" as "fobos";
grant select on "fobos".talt040 to "public" as "fobos";
grant update on "fobos".talt040 to "public" as "fobos";
grant insert on "fobos".talt040 to "public" as "fobos";
grant delete on "fobos".talt040 to "public" as "fobos";
grant index on "fobos".talt040 to "public" as "fobos";
grant select on "fobos".talt041 to "public" as "fobos";
grant update on "fobos".talt041 to "public" as "fobos";
grant insert on "fobos".talt041 to "public" as "fobos";
grant delete on "fobos".talt041 to "public" as "fobos";
grant index on "fobos".talt041 to "public" as "fobos";
grant select on "fobos".gent019 to "public" as "fobos";
grant update on "fobos".gent019 to "public" as "fobos";
grant insert on "fobos".gent019 to "public" as "fobos";
grant delete on "fobos".gent019 to "public" as "fobos";
grant index on "fobos".gent019 to "public" as "fobos";
grant select on "fobos".talt010 to "public" as "fobos";
grant update on "fobos".talt010 to "public" as "fobos";
grant insert on "fobos".talt010 to "public" as "fobos";
grant delete on "fobos".talt010 to "public" as "fobos";
grant index on "fobos".talt010 to "public" as "fobos";
grant select on "fobos".veht023 to "public" as "fobos";
grant update on "fobos".veht023 to "public" as "fobos";
grant insert on "fobos".veht023 to "public" as "fobos";
grant delete on "fobos".veht023 to "public" as "fobos";
grant index on "fobos".veht023 to "public" as "fobos";
grant select on "fobos".veht033 to "public" as "fobos";
grant update on "fobos".veht033 to "public" as "fobos";
grant insert on "fobos".veht033 to "public" as "fobos";
grant delete on "fobos".veht033 to "public" as "fobos";
grant index on "fobos".veht033 to "public" as "fobos";
grant select on "fobos".veht041 to "public" as "fobos";
grant update on "fobos".veht041 to "public" as "fobos";
grant insert on "fobos".veht041 to "public" as "fobos";
grant delete on "fobos".veht041 to "public" as "fobos";
grant index on "fobos".veht041 to "public" as "fobos";
grant select on "fobos".cxct021 to "public" as "fobos";
grant update on "fobos".cxct021 to "public" as "fobos";
grant insert on "fobos".cxct021 to "public" as "fobos";
grant delete on "fobos".cxct021 to "public" as "fobos";
grant index on "fobos".cxct021 to "public" as "fobos";
grant select on "fobos".cxct023 to "public" as "fobos";
grant update on "fobos".cxct023 to "public" as "fobos";
grant insert on "fobos".cxct023 to "public" as "fobos";
grant delete on "fobos".cxct023 to "public" as "fobos";
grant index on "fobos".cxct023 to "public" as "fobos";
grant select on "fobos".cxct050 to "public" as "fobos";
grant update on "fobos".cxct050 to "public" as "fobos";
grant insert on "fobos".cxct050 to "public" as "fobos";
grant delete on "fobos".cxct050 to "public" as "fobos";
grant index on "fobos".cxct050 to "public" as "fobos";
grant select on "fobos".cxct051 to "public" as "fobos";
grant update on "fobos".cxct051 to "public" as "fobos";
grant insert on "fobos".cxct051 to "public" as "fobos";
grant delete on "fobos".cxct051 to "public" as "fobos";
grant index on "fobos".cxct051 to "public" as "fobos";
grant select on "fobos".veht038 to "public" as "fobos";
grant update on "fobos".veht038 to "public" as "fobos";
grant insert on "fobos".veht038 to "public" as "fobos";
grant delete on "fobos".veht038 to "public" as "fobos";
grant index on "fobos".veht038 to "public" as "fobos";
grant select on "fobos".veht022 to "public" as "fobos";
grant update on "fobos".veht022 to "public" as "fobos";
grant insert on "fobos".veht022 to "public" as "fobos";
grant delete on "fobos".veht022 to "public" as "fobos";
grant index on "fobos".veht022 to "public" as "fobos";
grant select on "fobos".cxct024 to "public" as "fobos";
grant update on "fobos".cxct024 to "public" as "fobos";
grant insert on "fobos".cxct024 to "public" as "fobos";
grant delete on "fobos".cxct024 to "public" as "fobos";
grant index on "fobos".cxct024 to "public" as "fobos";
grant select on "fobos".cxct025 to "public" as "fobos";
grant update on "fobos".cxct025 to "public" as "fobos";
grant insert on "fobos".cxct025 to "public" as "fobos";
grant delete on "fobos".cxct025 to "public" as "fobos";
grant index on "fobos".cxct025 to "public" as "fobos";
grant select on "fobos".cxpt020 to "public" as "fobos";
grant update on "fobos".cxpt020 to "public" as "fobos";
grant insert on "fobos".cxpt020 to "public" as "fobos";
grant delete on "fobos".cxpt020 to "public" as "fobos";
grant index on "fobos".cxpt020 to "public" as "fobos";
grant select on "fobos".cxpt021 to "public" as "fobos";
grant update on "fobos".cxpt021 to "public" as "fobos";
grant insert on "fobos".cxpt021 to "public" as "fobos";
grant delete on "fobos".cxpt021 to "public" as "fobos";
grant index on "fobos".cxpt021 to "public" as "fobos";
grant select on "fobos".cxpt022 to "public" as "fobos";
grant update on "fobos".cxpt022 to "public" as "fobos";
grant insert on "fobos".cxpt022 to "public" as "fobos";
grant delete on "fobos".cxpt022 to "public" as "fobos";
grant index on "fobos".cxpt022 to "public" as "fobos";
grant select on "fobos".cxpt050 to "public" as "fobos";
grant update on "fobos".cxpt050 to "public" as "fobos";
grant insert on "fobos".cxpt050 to "public" as "fobos";
grant delete on "fobos".cxpt050 to "public" as "fobos";
grant index on "fobos".cxpt050 to "public" as "fobos";
grant select on "fobos".cxpt051 to "public" as "fobos";
grant update on "fobos".cxpt051 to "public" as "fobos";
grant insert on "fobos".cxpt051 to "public" as "fobos";
grant delete on "fobos".cxpt051 to "public" as "fobos";
grant index on "fobos".cxpt051 to "public" as "fobos";
grant select on "fobos".cxpt023 to "public" as "fobos";
grant update on "fobos".cxpt023 to "public" as "fobos";
grant insert on "fobos".cxpt023 to "public" as "fobos";
grant delete on "fobos".cxpt023 to "public" as "fobos";
grant index on "fobos".cxpt023 to "public" as "fobos";
grant select on "fobos".cxpt024 to "public" as "fobos";
grant update on "fobos".cxpt024 to "public" as "fobos";
grant insert on "fobos".cxpt024 to "public" as "fobos";
grant delete on "fobos".cxpt024 to "public" as "fobos";
grant index on "fobos".cxpt024 to "public" as "fobos";
grant select on "fobos".cxpt027 to "public" as "fobos";
grant update on "fobos".cxpt027 to "public" as "fobos";
grant insert on "fobos".cxpt027 to "public" as "fobos";
grant delete on "fobos".cxpt027 to "public" as "fobos";
grant index on "fobos".cxpt027 to "public" as "fobos";
grant select on "fobos".ordt002 to "public" as "fobos";
grant update on "fobos".ordt002 to "public" as "fobos";
grant insert on "fobos".ordt002 to "public" as "fobos";
grant delete on "fobos".ordt002 to "public" as "fobos";
grant index on "fobos".ordt002 to "public" as "fobos";
grant select on "fobos".actt010 to "public" as "fobos";
grant update on "fobos".actt010 to "public" as "fobos";
grant insert on "fobos".actt010 to "public" as "fobos";
grant delete on "fobos".actt010 to "public" as "fobos";
grant index on "fobos".actt010 to "public" as "fobos";
grant select on "fobos".actt001 to "public" as "fobos";
grant update on "fobos".actt001 to "public" as "fobos";
grant insert on "fobos".actt001 to "public" as "fobos";
grant delete on "fobos".actt001 to "public" as "fobos";
grant index on "fobos".actt001 to "public" as "fobos";
grant select on "fobos".actt002 to "public" as "fobos";
grant update on "fobos".actt002 to "public" as "fobos";
grant insert on "fobos".actt002 to "public" as "fobos";
grant delete on "fobos".actt002 to "public" as "fobos";
grant index on "fobos".actt002 to "public" as "fobos";
grant select on "fobos".rept024 to "public" as "fobos";
grant update on "fobos".rept024 to "public" as "fobos";
grant insert on "fobos".rept024 to "public" as "fobos";
grant delete on "fobos".rept024 to "public" as "fobos";
grant index on "fobos".rept024 to "public" as "fobos";
grant select on "fobos".veht003 to "public" as "fobos";
grant update on "fobos".veht003 to "public" as "fobos";
grant insert on "fobos".veht003 to "public" as "fobos";
grant delete on "fobos".veht003 to "public" as "fobos";
grant index on "fobos".veht003 to "public" as "fobos";
grant select on "fobos".talt021 to "public" as "fobos";
grant update on "fobos".talt021 to "public" as "fobos";
grant insert on "fobos".talt021 to "public" as "fobos";
grant delete on "fobos".talt021 to "public" as "fobos";
grant index on "fobos".talt021 to "public" as "fobos";
grant select on "fobos".cxct022 to "public" as "fobos";
grant update on "fobos".cxct022 to "public" as "fobos";
grant insert on "fobos".cxct022 to "public" as "fobos";
grant delete on "fobos".cxct022 to "public" as "fobos";
grant index on "fobos".cxct022 to "public" as "fobos";
grant select on "fobos".rept027 to "public" as "fobos";
grant update on "fobos".rept027 to "public" as "fobos";
grant insert on "fobos".rept027 to "public" as "fobos";
grant delete on "fobos".rept027 to "public" as "fobos";
grant index on "fobos".rept027 to "public" as "fobos";
grant select on "fobos".veht031 to "public" as "fobos";
grant update on "fobos".veht031 to "public" as "fobos";
grant insert on "fobos".veht031 to "public" as "fobos";
grant delete on "fobos".veht031 to "public" as "fobos";
grant index on "fobos".veht031 to "public" as "fobos";
grant select on "fobos".gent023 to "public" as "fobos";
grant update on "fobos".gent023 to "public" as "fobos";
grant insert on "fobos".gent023 to "public" as "fobos";
grant delete on "fobos".gent023 to "public" as "fobos";
grant index on "fobos".gent023 to "public" as "fobos";
grant select on "fobos".talt028 to "public" as "fobos";
grant update on "fobos".talt028 to "public" as "fobos";
grant insert on "fobos".talt028 to "public" as "fobos";
grant delete on "fobos".talt028 to "public" as "fobos";
grant index on "fobos".talt028 to "public" as "fobos";
grant select on "fobos".talt029 to "public" as "fobos";
grant update on "fobos".talt029 to "public" as "fobos";
grant insert on "fobos".talt029 to "public" as "fobos";
grant delete on "fobos".talt029 to "public" as "fobos";
grant index on "fobos".talt029 to "public" as "fobos";
grant select on "fobos".cxct020 to "public" as "fobos";
grant update on "fobos".cxct020 to "public" as "fobos";
grant insert on "fobos".cxct020 to "public" as "fobos";
grant delete on "fobos".cxct020 to "public" as "fobos";
grant index on "fobos".cxct020 to "public" as "fobos";
grant select on "fobos".ordt015 to "public" as "fobos";
grant update on "fobos".ordt015 to "public" as "fobos";
grant insert on "fobos".ordt015 to "public" as "fobos";
grant delete on "fobos".ordt015 to "public" as "fobos";
grant index on "fobos".ordt015 to "public" as "fobos";
grant select on "fobos".ordt016 to "public" as "fobos";
grant update on "fobos".ordt016 to "public" as "fobos";
grant insert on "fobos".ordt016 to "public" as "fobos";
grant delete on "fobos".ordt016 to "public" as "fobos";
grant index on "fobos".ordt016 to "public" as "fobos";
grant select on "fobos".cxpt005 to "public" as "fobos";
grant update on "fobos".cxpt005 to "public" as "fobos";
grant insert on "fobos".cxpt005 to "public" as "fobos";
grant delete on "fobos".cxpt005 to "public" as "fobos";
grant index on "fobos".cxpt005 to "public" as "fobos";
grant select on "fobos".cxpt030 to "public" as "fobos";
grant update on "fobos".cxpt030 to "public" as "fobos";
grant insert on "fobos".cxpt030 to "public" as "fobos";
grant delete on "fobos".cxpt030 to "public" as "fobos";
grant index on "fobos".cxpt030 to "public" as "fobos";
grant select on "fobos".cxpt031 to "public" as "fobos";
grant update on "fobos".cxpt031 to "public" as "fobos";
grant insert on "fobos".cxpt031 to "public" as "fobos";
grant delete on "fobos".cxpt031 to "public" as "fobos";
grant index on "fobos".cxpt031 to "public" as "fobos";
grant select on "fobos".rept030 to "public" as "fobos";
grant update on "fobos".rept030 to "public" as "fobos";
grant insert on "fobos".rept030 to "public" as "fobos";
grant delete on "fobos".rept030 to "public" as "fobos";
grant index on "fobos".rept030 to "public" as "fobos";
grant select on "fobos".gent021 to "public" as "fobos";
grant update on "fobos".gent021 to "public" as "fobos";
grant insert on "fobos".gent021 to "public" as "fobos";
grant delete on "fobos".gent021 to "public" as "fobos";
grant index on "fobos".gent021 to "public" as "fobos";
grant select on "fobos".cajt004 to "public" as "fobos";
grant update on "fobos".cajt004 to "public" as "fobos";
grant insert on "fobos".cajt004 to "public" as "fobos";
grant delete on "fobos".cajt004 to "public" as "fobos";
grant index on "fobos".cajt004 to "public" as "fobos";
grant select on "fobos".cajt005 to "public" as "fobos";
grant update on "fobos".cajt005 to "public" as "fobos";
grant insert on "fobos".cajt005 to "public" as "fobos";
grant delete on "fobos".cajt005 to "public" as "fobos";
grant index on "fobos".cajt005 to "public" as "fobos";
grant select on "fobos".ctbt040 to "public" as "fobos";
grant update on "fobos".ctbt040 to "public" as "fobos";
grant insert on "fobos".ctbt040 to "public" as "fobos";
grant delete on "fobos".ctbt040 to "public" as "fobos";
grant index on "fobos".ctbt040 to "public" as "fobos";
grant select on "fobos".ctbt041 to "public" as "fobos";
grant update on "fobos".ctbt041 to "public" as "fobos";
grant insert on "fobos".ctbt041 to "public" as "fobos";
grant delete on "fobos".ctbt041 to "public" as "fobos";
grant index on "fobos".ctbt041 to "public" as "fobos";
grant select on "fobos".ctbt042 to "public" as "fobos";
grant update on "fobos".ctbt042 to "public" as "fobos";
grant insert on "fobos".ctbt042 to "public" as "fobos";
grant delete on "fobos".ctbt042 to "public" as "fobos";
grant index on "fobos".ctbt042 to "public" as "fobos";
grant select on "fobos".rept040 to "public" as "fobos";
grant update on "fobos".rept040 to "public" as "fobos";
grant insert on "fobos".rept040 to "public" as "fobos";
grant delete on "fobos".rept040 to "public" as "fobos";
grant index on "fobos".rept040 to "public" as "fobos";
grant select on "fobos".cxct040 to "public" as "fobos";
grant update on "fobos".cxct040 to "public" as "fobos";
grant insert on "fobos".cxct040 to "public" as "fobos";
grant delete on "fobos".cxct040 to "public" as "fobos";
grant index on "fobos".cxct040 to "public" as "fobos";
grant select on "fobos".veht050 to "public" as "fobos";
grant update on "fobos".veht050 to "public" as "fobos";
grant insert on "fobos".veht050 to "public" as "fobos";
grant delete on "fobos".veht050 to "public" as "fobos";
grant index on "fobos".veht050 to "public" as "fobos";
grant select on "fobos".ctbt043 to "public" as "fobos";
grant update on "fobos".ctbt043 to "public" as "fobos";
grant insert on "fobos".ctbt043 to "public" as "fobos";
grant delete on "fobos".ctbt043 to "public" as "fobos";
grant index on "fobos".ctbt043 to "public" as "fobos";
grant select on "fobos".talt050 to "public" as "fobos";
grant update on "fobos".talt050 to "public" as "fobos";
grant insert on "fobos".talt050 to "public" as "fobos";
grant delete on "fobos".talt050 to "public" as "fobos";
grant index on "fobos".talt050 to "public" as "fobos";
grant select on "fobos".veht042 to "public" as "fobos";
grant update on "fobos".veht042 to "public" as "fobos";
grant insert on "fobos".veht042 to "public" as "fobos";
grant delete on "fobos".veht042 to "public" as "fobos";
grant index on "fobos".veht042 to "public" as "fobos";
grant select on "fobos".ordt040 to "public" as "fobos";
grant update on "fobos".ordt040 to "public" as "fobos";
grant insert on "fobos".ordt040 to "public" as "fobos";
grant delete on "fobos".ordt040 to "public" as "fobos";
grant index on "fobos".ordt040 to "public" as "fobos";
grant select on "fobos".talt030 to "public" as "fobos";
grant update on "fobos".talt030 to "public" as "fobos";
grant insert on "fobos".talt030 to "public" as "fobos";
grant delete on "fobos".talt030 to "public" as "fobos";
grant index on "fobos".talt030 to "public" as "fobos";
grant select on "fobos".talt031 to "public" as "fobos";
grant update on "fobos".talt031 to "public" as "fobos";
grant insert on "fobos".talt031 to "public" as "fobos";
grant delete on "fobos".talt031 to "public" as "fobos";
grant index on "fobos".talt031 to "public" as "fobos";
grant select on "fobos".talt032 to "public" as "fobos";
grant update on "fobos".talt032 to "public" as "fobos";
grant insert on "fobos".talt032 to "public" as "fobos";
grant delete on "fobos".talt032 to "public" as "fobos";
grant index on "fobos".talt032 to "public" as "fobos";
grant select on "fobos".talt033 to "public" as "fobos";
grant update on "fobos".talt033 to "public" as "fobos";
grant insert on "fobos".talt033 to "public" as "fobos";
grant delete on "fobos".talt033 to "public" as "fobos";
grant index on "fobos".talt033 to "public" as "fobos";
grant select on "fobos".rept034 to "public" as "fobos";
grant update on "fobos".rept034 to "public" as "fobos";
grant insert on "fobos".rept034 to "public" as "fobos";
grant delete on "fobos".rept034 to "public" as "fobos";
grant index on "fobos".rept034 to "public" as "fobos";
grant select on "fobos".rept035 to "public" as "fobos";
grant update on "fobos".rept035 to "public" as "fobos";
grant insert on "fobos".rept035 to "public" as "fobos";
grant delete on "fobos".rept035 to "public" as "fobos";
grant index on "fobos".rept035 to "public" as "fobos";
grant select on "fobos".rept036 to "public" as "fobos";
grant update on "fobos".rept036 to "public" as "fobos";
grant insert on "fobos".rept036 to "public" as "fobos";
grant delete on "fobos".rept036 to "public" as "fobos";
grant index on "fobos".rept036 to "public" as "fobos";
grant select on "fobos".rept037 to "public" as "fobos";
grant update on "fobos".rept037 to "public" as "fobos";
grant insert on "fobos".rept037 to "public" as "fobos";
grant delete on "fobos".rept037 to "public" as "fobos";
grant index on "fobos".rept037 to "public" as "fobos";
grant select on "fobos".ctbt032 to "public" as "fobos";
grant update on "fobos".ctbt032 to "public" as "fobos";
grant insert on "fobos".ctbt032 to "public" as "fobos";
grant delete on "fobos".ctbt032 to "public" as "fobos";
grant index on "fobos".ctbt032 to "public" as "fobos";
grant select on "fobos".rept074 to "public" as "fobos";
grant update on "fobos".rept074 to "public" as "fobos";
grant insert on "fobos".rept074 to "public" as "fobos";
grant delete on "fobos".rept074 to "public" as "fobos";
grant index on "fobos".rept074 to "public" as "fobos";
grant select on "fobos".rept075 to "public" as "fobos";
grant update on "fobos".rept075 to "public" as "fobos";
grant insert on "fobos".rept075 to "public" as "fobos";
grant delete on "fobos".rept075 to "public" as "fobos";
grant index on "fobos".rept075 to "public" as "fobos";
grant select on "fobos".rept070 to "public" as "fobos";
grant update on "fobos".rept070 to "public" as "fobos";
grant insert on "fobos".rept070 to "public" as "fobos";
grant delete on "fobos".rept070 to "public" as "fobos";
grant index on "fobos".rept070 to "public" as "fobos";
grant select on "fobos".rept073 to "public" as "fobos";
grant update on "fobos".rept073 to "public" as "fobos";
grant insert on "fobos".rept073 to "public" as "fobos";
grant delete on "fobos".rept073 to "public" as "fobos";
grant index on "fobos".rept073 to "public" as "fobos";
grant select on "fobos".te_cxct001 to "public" as "fobos";
grant update on "fobos".te_cxct001 to "public" as "fobos";
grant insert on "fobos".te_cxct001 to "public" as "fobos";
grant delete on "fobos".te_cxct001 to "public" as "fobos";
grant index on "fobos".te_cxct001 to "public" as "fobos";
grant select on "fobos".te_rept071 to "public" as "fobos";
grant update on "fobos".te_rept071 to "public" as "fobos";
grant insert on "fobos".te_rept071 to "public" as "fobos";
grant delete on "fobos".te_rept071 to "public" as "fobos";
grant index on "fobos".te_rept071 to "public" as "fobos";
grant select on "fobos".te_rept070 to "public" as "fobos";
grant update on "fobos".te_rept070 to "public" as "fobos";
grant insert on "fobos".te_rept070 to "public" as "fobos";
grant delete on "fobos".te_rept070 to "public" as "fobos";
grant index on "fobos".te_rept070 to "public" as "fobos";
grant select on "fobos".rept010 to "public" as "fobos";
grant update on "fobos".rept010 to "public" as "fobos";
grant insert on "fobos".rept010 to "public" as "fobos";
grant delete on "fobos".rept010 to "public" as "fobos";
grant index on "fobos".rept010 to "public" as "fobos";
grant select on "fobos".te_rept006 to "public" as "fobos";
grant update on "fobos".te_rept006 to "public" as "fobos";
grant insert on "fobos".te_rept006 to "public" as "fobos";
grant delete on "fobos".te_rept006 to "public" as "fobos";
grant index on "fobos".te_rept006 to "public" as "fobos";
grant select on "fobos".rept076 to "public" as "fobos";
grant update on "fobos".rept076 to "public" as "fobos";
grant insert on "fobos".rept076 to "public" as "fobos";
grant delete on "fobos".rept076 to "public" as "fobos";
grant index on "fobos".rept076 to "public" as "fobos";
grant alter on "fobos".rept076 to "public" as "fobos";
grant references on "fobos".rept076 to "public" as "fobos";
grant select on "fobos".te_cxpt001 to "public" as "fobos";
grant update on "fobos".te_cxpt001 to "public" as "fobos";
grant insert on "fobos".te_cxpt001 to "public" as "fobos";
grant delete on "fobos".te_cxpt001 to "public" as "fobos";
grant index on "fobos".te_cxpt001 to "public" as "fobos";
grant select on "fobos".te_cxct020 to "public" as "fobos";
grant update on "fobos".te_cxct020 to "public" as "fobos";
grant insert on "fobos".te_cxct020 to "public" as "fobos";
grant delete on "fobos".te_cxct020 to "public" as "fobos";
grant index on "fobos".te_cxct020 to "public" as "fobos";
grant select on "fobos".te_rept003 to "public" as "fobos";
grant update on "fobos".te_rept003 to "public" as "fobos";
grant insert on "fobos".te_rept003 to "public" as "fobos";
grant delete on "fobos".te_rept003 to "public" as "fobos";
grant index on "fobos".te_rept003 to "public" as "fobos";
grant select on "fobos".te_rept073 to "public" as "fobos";
grant update on "fobos".te_rept073 to "public" as "fobos";
grant insert on "fobos".te_rept073 to "public" as "fobos";
grant delete on "fobos".te_rept073 to "public" as "fobos";
grant index on "fobos".te_rept073 to "public" as "fobos";
grant select on "fobos".te_rept011 to "public" as "fobos";
grant update on "fobos".te_rept011 to "public" as "fobos";
grant insert on "fobos".te_rept011 to "public" as "fobos";
grant delete on "fobos".te_rept011 to "public" as "fobos";
grant index on "fobos".te_rept011 to "public" as "fobos";
grant select on "fobos".te_ctas to "public" as "fobos";
grant update on "fobos".te_ctas to "public" as "fobos";
grant insert on "fobos".te_ctas to "public" as "fobos";
grant delete on "fobos".te_ctas to "public" as "fobos";
grant index on "fobos".te_ctas to "public" as "fobos";
grant select on "fobos".rept079 to "public" as "fobos";
grant update on "fobos".rept079 to "public" as "fobos";
grant insert on "fobos".rept079 to "public" as "fobos";
grant delete on "fobos".rept079 to "public" as "fobos";
grant index on "fobos".rept079 to "public" as "fobos";
grant select on "fobos".rept080 to "public" as "fobos";
grant update on "fobos".rept080 to "public" as "fobos";
grant insert on "fobos".rept080 to "public" as "fobos";
grant delete on "fobos".rept080 to "public" as "fobos";
grant index on "fobos".rept080 to "public" as "fobos";
grant select on "fobos".te_ctbt010 to "public" as "fobos";
grant update on "fobos".te_ctbt010 to "public" as "fobos";
grant insert on "fobos".te_ctbt010 to "public" as "fobos";
grant delete on "fobos".te_ctbt010 to "public" as "fobos";
grant index on "fobos".te_ctbt010 to "public" as "fobos";
grant select on "fobos".te_cxpt020 to "public" as "fobos";
grant update on "fobos".te_cxpt020 to "public" as "fobos";
grant insert on "fobos".te_cxpt020 to "public" as "fobos";
grant delete on "fobos".te_cxpt020 to "public" as "fobos";
grant index on "fobos".te_cxpt020 to "public" as "fobos";
grant select on "fobos".rept077 to "public" as "fobos";
grant update on "fobos".rept077 to "public" as "fobos";
grant insert on "fobos".rept077 to "public" as "fobos";
grant delete on "fobos".rept077 to "public" as "fobos";
grant index on "fobos".rept077 to "public" as "fobos";
grant select on "fobos".rept038 to "public" as "fobos";
grant update on "fobos".rept038 to "public" as "fobos";
grant insert on "fobos".rept038 to "public" as "fobos";
grant delete on "fobos".rept038 to "public" as "fobos";
grant index on "fobos".rept038 to "public" as "fobos";
grant select on "fobos".te_rept077 to "public" as "fobos";
grant update on "fobos".te_rept077 to "public" as "fobos";
grant insert on "fobos".te_rept077 to "public" as "fobos";
grant delete on "fobos".te_rept077 to "public" as "fobos";
grant index on "fobos".te_rept077 to "public" as "fobos";
grant select on "fobos".te_r10 to "public" as "fobos";
grant update on "fobos".te_r10 to "public" as "fobos";
grant insert on "fobos".te_r10 to "public" as "fobos";
grant delete on "fobos".te_r10 to "public" as "fobos";
grant index on "fobos".te_r10 to "public" as "fobos";
grant select on "fobos".te_otros_r10 to "public" as "fobos";
grant update on "fobos".te_otros_r10 to "public" as "fobos";
grant insert on "fobos".te_otros_r10 to "public" as "fobos";
grant delete on "fobos".te_otros_r10 to "public" as "fobos";
grant index on "fobos".te_otros_r10 to "public" as "fobos";
grant select on "fobos".te_precios to "public" as "fobos";
grant update on "fobos".te_precios to "public" as "fobos";
grant insert on "fobos".te_precios to "public" as "fobos";
grant delete on "fobos".te_precios to "public" as "fobos";
grant index on "fobos".te_precios to "public" as "fobos";
grant select on "fobos".te_descrip to "public" as "fobos";
grant update on "fobos".te_descrip to "public" as "fobos";
grant insert on "fobos".te_descrip to "public" as "fobos";
grant delete on "fobos".te_descrip to "public" as "fobos";
grant index on "fobos".te_descrip to "public" as "fobos";
grant select on "fobos".te_cli_cont to "public" as "fobos";
grant update on "fobos".te_cli_cont to "public" as "fobos";
grant insert on "fobos".te_cli_cont to "public" as "fobos";
grant delete on "fobos".te_cli_cont to "public" as "fobos";
grant index on "fobos".te_cli_cont to "public" as "fobos";
grant select on "fobos".te_cxct021 to "public" as "fobos";
grant update on "fobos".te_cxct021 to "public" as "fobos";
grant insert on "fobos".te_cxct021 to "public" as "fobos";
grant delete on "fobos".te_cxct021 to "public" as "fobos";
grant index on "fobos".te_cxct021 to "public" as "fobos";
grant select on "fobos".te_z01_bak to "public" as "fobos";
grant update on "fobos".te_z01_bak to "public" as "fobos";
grant insert on "fobos".te_z01_bak to "public" as "fobos";
grant delete on "fobos".te_z01_bak to "public" as "fobos";
grant index on "fobos".te_z01_bak to "public" as "fobos";
grant select on "fobos".te_otr10 to "public" as "fobos";
grant update on "fobos".te_otr10 to "public" as "fobos";
grant insert on "fobos".te_otr10 to "public" as "fobos";
grant delete on "fobos".te_otr10 to "public" as "fobos";
grant index on "fobos".te_otr10 to "public" as "fobos";
grant select on "fobos".te_electrico to "public" as "fobos";
grant update on "fobos".te_electrico to "public" as "fobos";
grant insert on "fobos".te_electrico to "public" as "fobos";
grant delete on "fobos".te_electrico to "public" as "fobos";
grant index on "fobos".te_electrico to "public" as "fobos";
grant select on "fobos".rept072 to "public" as "fobos";
grant update on "fobos".rept072 to "public" as "fobos";
grant insert on "fobos".rept072 to "public" as "fobos";
grant delete on "fobos".rept072 to "public" as "fobos";
grant index on "fobos".rept072 to "public" as "fobos";
grant select on "fobos".rept071 to "public" as "fobos";
grant update on "fobos".rept071 to "public" as "fobos";
grant insert on "fobos".rept071 to "public" as "fobos";
grant delete on "fobos".rept071 to "public" as "fobos";
grant index on "fobos".rept071 to "public" as "fobos";
grant select on "fobos".te_rept072 to "public" as "fobos";
grant update on "fobos".te_rept072 to "public" as "fobos";
grant insert on "fobos".te_rept072 to "public" as "fobos";
grant delete on "fobos".te_rept072 to "public" as "fobos";
grant index on "fobos".te_rept072 to "public" as "fobos";
grant select on "fobos".tr_items_qto to "public" as "fobos";
grant update on "fobos".tr_items_qto to "public" as "fobos";
grant insert on "fobos".tr_items_qto to "public" as "fobos";
grant delete on "fobos".tr_items_qto to "public" as "fobos";
grant index on "fobos".tr_items_qto to "public" as "fobos";
grant select on "fobos".tr_stock_qto to "public" as "fobos";
grant update on "fobos".tr_stock_qto to "public" as "fobos";
grant insert on "fobos".tr_stock_qto to "public" as "fobos";
grant delete on "fobos".tr_stock_qto to "public" as "fobos";
grant index on "fobos".tr_stock_qto to "public" as "fobos";
grant select on "fobos".tr_cxct002 to "public" as "fobos";
grant update on "fobos".tr_cxct002 to "public" as "fobos";
grant insert on "fobos".tr_cxct002 to "public" as "fobos";
grant delete on "fobos".tr_cxct002 to "public" as "fobos";
grant index on "fobos".tr_cxct002 to "public" as "fobos";
grant select on "fobos".tr_cxct020 to "public" as "fobos";
grant update on "fobos".tr_cxct020 to "public" as "fobos";
grant insert on "fobos".tr_cxct020 to "public" as "fobos";
grant delete on "fobos".tr_cxct020 to "public" as "fobos";
grant index on "fobos".tr_cxct020 to "public" as "fobos";
grant select on "fobos".ordt011 to "public" as "fobos";
grant update on "fobos".ordt011 to "public" as "fobos";
grant insert on "fobos".ordt011 to "public" as "fobos";
grant delete on "fobos".ordt011 to "public" as "fobos";
grant index on "fobos".ordt011 to "public" as "fobos";
grant select on "fobos".ordt014 to "public" as "fobos";
grant update on "fobos".ordt014 to "public" as "fobos";
grant insert on "fobos".ordt014 to "public" as "fobos";
grant delete on "fobos".ordt014 to "public" as "fobos";
grant index on "fobos".ordt014 to "public" as "fobos";
grant select on "fobos".tr_items to "public" as "fobos";
grant update on "fobos".tr_items to "public" as "fobos";
grant insert on "fobos".tr_items to "public" as "fobos";
grant delete on "fobos".tr_items to "public" as "fobos";
grant index on "fobos".tr_items to "public" as "fobos";
grant select on "fobos".tr_stock to "public" as "fobos";
grant update on "fobos".tr_stock to "public" as "fobos";
grant insert on "fobos".tr_stock to "public" as "fobos";
grant delete on "fobos".tr_stock to "public" as "fobos";
grant index on "fobos".tr_stock to "public" as "fobos";
grant select on "fobos".rept017 to "public" as "fobos";
grant update on "fobos".rept017 to "public" as "fobos";
grant insert on "fobos".rept017 to "public" as "fobos";
grant delete on "fobos".rept017 to "public" as "fobos";
grant index on "fobos".rept017 to "public" as "fobos";
grant select on "fobos".rept028 to "public" as "fobos";
grant update on "fobos".rept028 to "public" as "fobos";
grant insert on "fobos".rept028 to "public" as "fobos";
grant delete on "fobos".rept028 to "public" as "fobos";
grant index on "fobos".rept028 to "public" as "fobos";
grant select on "fobos".te_cod_kh to "public" as "fobos";
grant update on "fobos".te_cod_kh to "public" as "fobos";
grant insert on "fobos".te_cod_kh to "public" as "fobos";
grant delete on "fobos".te_cod_kh to "public" as "fobos";
grant index on "fobos".te_cod_kh to "public" as "fobos";
grant select on "fobos".ctbt012 to "public" as "fobos";
grant update on "fobos".ctbt012 to "public" as "fobos";
grant insert on "fobos".ctbt012 to "public" as "fobos";
grant delete on "fobos".ctbt012 to "public" as "fobos";
grant index on "fobos".ctbt012 to "public" as "fobos";
grant select on "fobos".gent037 to "public" as "fobos";
grant update on "fobos".gent037 to "public" as "fobos";
grant insert on "fobos".gent037 to "public" as "fobos";
grant delete on "fobos".gent037 to "public" as "fobos";
grant index on "fobos".gent037 to "public" as "fobos";
grant select on "fobos".tr_cxct021 to "public" as "fobos";
grant update on "fobos".tr_cxct021 to "public" as "fobos";
grant insert on "fobos".tr_cxct021 to "public" as "fobos";
grant delete on "fobos".tr_cxct021 to "public" as "fobos";
grant index on "fobos".tr_cxct021 to "public" as "fobos";
grant select on "fobos".tr_cxct022 to "public" as "fobos";
grant update on "fobos".tr_cxct022 to "public" as "fobos";
grant insert on "fobos".tr_cxct022 to "public" as "fobos";
grant delete on "fobos".tr_cxct022 to "public" as "fobos";
grant index on "fobos".tr_cxct022 to "public" as "fobos";
grant select on "fobos".tr_cxct023 to "public" as "fobos";
grant update on "fobos".tr_cxct023 to "public" as "fobos";
grant insert on "fobos".tr_cxct023 to "public" as "fobos";
grant delete on "fobos".tr_cxct023 to "public" as "fobos";
grant index on "fobos".tr_cxct023 to "public" as "fobos";
grant select on "fobos".te_gent016 to "public" as "fobos";
grant update on "fobos".te_gent016 to "public" as "fobos";
grant insert on "fobos".te_gent016 to "public" as "fobos";
grant delete on "fobos".te_gent016 to "public" as "fobos";
grant index on "fobos".te_gent016 to "public" as "fobos";
grant select on "fobos".tr_precios_qto to "public" as "fobos";
grant update on "fobos".tr_precios_qto to "public" as "fobos";
grant insert on "fobos".tr_precios_qto to "public" as "fobos";
grant delete on "fobos".tr_precios_qto to "public" as "fobos";
grant index on "fobos".tr_precios_qto to "public" as "fobos";
grant select on "fobos".npc to "public" as "fobos";
grant update on "fobos".npc to "public" as "fobos";
grant insert on "fobos".npc to "public" as "fobos";
grant delete on "fobos".npc to "public" as "fobos";
grant index on "fobos".npc to "public" as "fobos";
grant select on "fobos".gent056 to "public" as "fobos";
grant update on "fobos".gent056 to "public" as "fobos";
grant insert on "fobos".gent056 to "public" as "fobos";
grant delete on "fobos".gent056 to "public" as "fobos";
grant index on "fobos".gent056 to "public" as "fobos";
grant select on "fobos".tr_grupos to "public" as "fobos";
grant update on "fobos".tr_grupos to "public" as "fobos";
grant insert on "fobos".tr_grupos to "public" as "fobos";
grant delete on "fobos".tr_grupos to "public" as "fobos";
grant index on "fobos".tr_grupos to "public" as "fobos";
grant select on "fobos".tr_marcas to "public" as "fobos";
grant update on "fobos".tr_marcas to "public" as "fobos";
grant insert on "fobos".tr_marcas to "public" as "fobos";
grant delete on "fobos".tr_marcas to "public" as "fobos";
grant index on "fobos".tr_marcas to "public" as "fobos";
grant select on "fobos".tr_clases to "public" as "fobos";
grant update on "fobos".tr_clases to "public" as "fobos";
grant insert on "fobos".tr_clases to "public" as "fobos";
grant delete on "fobos".tr_clases to "public" as "fobos";
grant index on "fobos".tr_clases to "public" as "fobos";
grant select on "fobos".gent038 to "public" as "fobos";
grant update on "fobos".gent038 to "public" as "fobos";
grant insert on "fobos".gent038 to "public" as "fobos";
grant delete on "fobos".gent038 to "public" as "fobos";
grant index on "fobos".gent038 to "public" as "fobos";
grant select on "fobos".gent016 to "public" as "fobos";
grant update on "fobos".gent016 to "public" as "fobos";
grant insert on "fobos".gent016 to "public" as "fobos";
grant delete on "fobos".gent016 to "public" as "fobos";
grant index on "fobos".gent016 to "public" as "fobos";
grant select on "fobos".cxct041 to "public" as "fobos";
grant update on "fobos".cxct041 to "public" as "fobos";
grant insert on "fobos".cxct041 to "public" as "fobos";
grant delete on "fobos".cxct041 to "public" as "fobos";
grant index on "fobos".cxct041 to "public" as "fobos";
grant select on "fobos".cxpt040 to "public" as "fobos";
grant update on "fobos".cxpt040 to "public" as "fobos";
grant insert on "fobos".cxpt040 to "public" as "fobos";
grant delete on "fobos".cxpt040 to "public" as "fobos";
grant index on "fobos".cxpt040 to "public" as "fobos";
grant select on "fobos".cxpt041 to "public" as "fobos";
grant update on "fobos".cxpt041 to "public" as "fobos";
grant insert on "fobos".cxpt041 to "public" as "fobos";
grant delete on "fobos".cxpt041 to "public" as "fobos";
grant index on "fobos".cxpt041 to "public" as "fobos";
grant select on "fobos".vb_uso to "public" as "fobos";
grant update on "fobos".vb_uso to "public" as "fobos";
grant insert on "fobos".vb_uso to "public" as "fobos";
grant delete on "fobos".vb_uso to "public" as "fobos";
grant index on "fobos".vb_uso to "public" as "fobos";
grant select on "fobos".vb_marcas to "public" as "fobos";
grant update on "fobos".vb_marcas to "public" as "fobos";
grant insert on "fobos".vb_marcas to "public" as "fobos";
grant delete on "fobos".vb_marcas to "public" as "fobos";
grant index on "fobos".vb_marcas to "public" as "fobos";
grant select on "fobos".vb_1 to "public" as "fobos";
grant update on "fobos".vb_1 to "public" as "fobos";
grant insert on "fobos".vb_1 to "public" as "fobos";
grant delete on "fobos".vb_1 to "public" as "fobos";
grant index on "fobos".vb_1 to "public" as "fobos";
grant select on "fobos".repro_010 to "public" as "fobos";
grant update on "fobos".repro_010 to "public" as "fobos";
grant insert on "fobos".repro_010 to "public" as "fobos";
grant delete on "fobos".repro_010 to "public" as "fobos";
grant index on "fobos".repro_010 to "public" as "fobos";
grant select on "fobos".repro_011 to "public" as "fobos";
grant update on "fobos".repro_011 to "public" as "fobos";
grant insert on "fobos".repro_011 to "public" as "fobos";
grant delete on "fobos".repro_011 to "public" as "fobos";
grant index on "fobos".repro_011 to "public" as "fobos";
grant select on "fobos".repro_019 to "public" as "fobos";
grant update on "fobos".repro_019 to "public" as "fobos";
grant insert on "fobos".repro_019 to "public" as "fobos";
grant delete on "fobos".repro_019 to "public" as "fobos";
grant index on "fobos".repro_019 to "public" as "fobos";
grant select on "fobos".repro_020 to "public" as "fobos";
grant update on "fobos".repro_020 to "public" as "fobos";
grant insert on "fobos".repro_020 to "public" as "fobos";
grant delete on "fobos".repro_020 to "public" as "fobos";
grant index on "fobos".repro_020 to "public" as "fobos";
grant select on "fobos".rept083 to "public" as "fobos";
grant update on "fobos".rept083 to "public" as "fobos";
grant insert on "fobos".rept083 to "public" as "fobos";
grant delete on "fobos".rept083 to "public" as "fobos";
grant index on "fobos".rept083 to "public" as "fobos";
grant select on "fobos".hulk_010 to "public" as "fobos";
grant update on "fobos".hulk_010 to "public" as "fobos";
grant insert on "fobos".hulk_010 to "public" as "fobos";
grant delete on "fobos".hulk_010 to "public" as "fobos";
grant index on "fobos".hulk_010 to "public" as "fobos";
grant select on "fobos".rolt016 to "public" as "fobos";
grant update on "fobos".rolt016 to "public" as "fobos";
grant insert on "fobos".rolt016 to "public" as "fobos";
grant delete on "fobos".rolt016 to "public" as "fobos";
grant index on "fobos".rolt016 to "public" as "fobos";
grant select on "fobos".rolt047 to "public" as "fobos";
grant update on "fobos".rolt047 to "public" as "fobos";
grant insert on "fobos".rolt047 to "public" as "fobos";
grant delete on "fobos".rolt047 to "public" as "fobos";
grant index on "fobos".rolt047 to "public" as "fobos";
grant select on "fobos".vb_vendedores to "public" as "fobos";
grant update on "fobos".vb_vendedores to "public" as "fobos";
grant insert on "fobos".vb_vendedores to "public" as "fobos";
grant delete on "fobos".vb_vendedores to "public" as "fobos";
grant index on "fobos".vb_vendedores to "public" as "fobos";
grant select on "fobos".rolt048 to "public" as "fobos";
grant update on "fobos".rolt048 to "public" as "fobos";
grant insert on "fobos".rolt048 to "public" as "fobos";
grant delete on "fobos".rolt048 to "public" as "fobos";
grant index on "fobos".rolt048 to "public" as "fobos";
grant select on "fobos".rept082 to "public" as "fobos";
grant update on "fobos".rept082 to "public" as "fobos";
grant insert on "fobos".rept082 to "public" as "fobos";
grant delete on "fobos".rept082 to "public" as "fobos";
grant index on "fobos".rept082 to "public" as "fobos";
grant select on "fobos".rept084 to "public" as "fobos";
grant update on "fobos".rept084 to "public" as "fobos";
grant insert on "fobos".rept084 to "public" as "fobos";
grant delete on "fobos".rept084 to "public" as "fobos";
grant index on "fobos".rept084 to "public" as "fobos";
grant select on "fobos".temp_a10 to "public" as "fobos";
grant update on "fobos".temp_a10 to "public" as "fobos";
grant insert on "fobos".temp_a10 to "public" as "fobos";
grant delete on "fobos".temp_a10 to "public" as "fobos";
grant index on "fobos".temp_a10 to "public" as "fobos";
grant select on "fobos".actt013 to "public" as "fobos";
grant update on "fobos".actt013 to "public" as "fobos";
grant insert on "fobos".actt013 to "public" as "fobos";
grant delete on "fobos".actt013 to "public" as "fobos";
grant index on "fobos".actt013 to "public" as "fobos";
grant select on "fobos".te_vta_qto to "public" as "fobos";
grant update on "fobos".te_vta_qto to "public" as "fobos";
grant insert on "fobos".te_vta_qto to "public" as "fobos";
grant delete on "fobos".te_vta_qto to "public" as "fobos";
grant index on "fobos".te_vta_qto to "public" as "fobos";
grant select on "fobos".te_prec_fv to "public" as "fobos";
grant update on "fobos".te_prec_fv to "public" as "fobos";
grant insert on "fobos".te_prec_fv to "public" as "fobos";
grant delete on "fobos".te_prec_fv to "public" as "fobos";
grant index on "fobos".te_prec_fv to "public" as "fobos";
grant select on "fobos".te_fv_descri to "public" as "fobos";
grant update on "fobos".te_fv_descri to "public" as "fobos";
grant insert on "fobos".te_fv_descri to "public" as "fobos";
grant delete on "fobos".te_fv_descri to "public" as "fobos";
grant index on "fobos".te_fv_descri to "public" as "fobos";
grant select on "fobos".te_sanit to "public" as "fobos";
grant update on "fobos".te_sanit to "public" as "fobos";
grant insert on "fobos".te_sanit to "public" as "fobos";
grant delete on "fobos".te_sanit to "public" as "fobos";
grant index on "fobos".te_sanit to "public" as "fobos";
grant select on "fobos".te_cheb32 to "public" as "fobos";
grant update on "fobos".te_cheb32 to "public" as "fobos";
grant insert on "fobos".te_cheb32 to "public" as "fobos";
grant delete on "fobos".te_cheb32 to "public" as "fobos";
grant index on "fobos".te_cheb32 to "public" as "fobos";
grant select on "fobos".te_acces_fv to "public" as "fobos";
grant update on "fobos".te_acces_fv to "public" as "fobos";
grant insert on "fobos".te_acces_fv to "public" as "fobos";
grant delete on "fobos".te_acces_fv to "public" as "fobos";
grant index on "fobos".te_acces_fv to "public" as "fobos";
grant select on "fobos".ctbt666 to "public" as "fobos";
grant update on "fobos".ctbt666 to "public" as "fobos";
grant insert on "fobos".ctbt666 to "public" as "fobos";
grant delete on "fobos".ctbt666 to "public" as "fobos";
grant index on "fobos".ctbt666 to "public" as "fobos";
grant select on "fobos".te_rolaux to "public" as "fobos";
grant update on "fobos".te_rolaux to "public" as "fobos";
grant insert on "fobos".te_rolaux to "public" as "fobos";
grant delete on "fobos".te_rolaux to "public" as "fobos";
grant index on "fobos".te_rolaux to "public" as "fobos";
grant select on "fobos".te_rol99_02 to "public" as "fobos";
grant update on "fobos".te_rol99_02 to "public" as "fobos";
grant insert on "fobos".te_rol99_02 to "public" as "fobos";
grant delete on "fobos".te_rol99_02 to "public" as "fobos";
grant index on "fobos".te_rol99_02 to "public" as "fobos";
grant select on "fobos".te_rol2003 to "public" as "fobos";
grant update on "fobos".te_rol2003 to "public" as "fobos";
grant insert on "fobos".te_rol2003 to "public" as "fobos";
grant delete on "fobos".te_rol2003 to "public" as "fobos";
grant index on "fobos".te_rol2003 to "public" as "fobos";
grant select on "fobos".te_rolt033 to "public" as "fobos";
grant update on "fobos".te_rolt033 to "public" as "fobos";
grant insert on "fobos".te_rolt033 to "public" as "fobos";
grant delete on "fobos".te_rolt033 to "public" as "fobos";
grant index on "fobos".te_rolt033 to "public" as "fobos";
grant select on "fobos".te_rolt032 to "public" as "fobos";
grant update on "fobos".te_rolt032 to "public" as "fobos";
grant insert on "fobos".te_rolt032 to "public" as "fobos";
grant delete on "fobos".te_rolt032 to "public" as "fobos";
grant index on "fobos".te_rolt032 to "public" as "fobos";
grant select on "fobos".rolt060 to "public" as "fobos";
grant update on "fobos".rolt060 to "public" as "fobos";
grant insert on "fobos".rolt060 to "public" as "fobos";
grant delete on "fobos".rolt060 to "public" as "fobos";
grant index on "fobos".rolt060 to "public" as "fobos";
grant select on "fobos".rolt061 to "public" as "fobos";
grant update on "fobos".rolt061 to "public" as "fobos";
grant insert on "fobos".rolt061 to "public" as "fobos";
grant delete on "fobos".rolt061 to "public" as "fobos";
grant index on "fobos".rolt061 to "public" as "fobos";
grant select on "fobos".rolt062 to "public" as "fobos";
grant update on "fobos".rolt062 to "public" as "fobos";
grant insert on "fobos".rolt062 to "public" as "fobos";
grant delete on "fobos".rolt062 to "public" as "fobos";
grant index on "fobos".rolt062 to "public" as "fobos";
grant select on "fobos".rolt063 to "public" as "fobos";
grant update on "fobos".rolt063 to "public" as "fobos";
grant insert on "fobos".rolt063 to "public" as "fobos";
grant delete on "fobos".rolt063 to "public" as "fobos";
grant index on "fobos".rolt063 to "public" as "fobos";
grant select on "fobos".rolt065 to "public" as "fobos";
grant update on "fobos".rolt065 to "public" as "fobos";
grant insert on "fobos".rolt065 to "public" as "fobos";
grant delete on "fobos".rolt065 to "public" as "fobos";
grant index on "fobos".rolt065 to "public" as "fobos";
grant select on "fobos".rolt068 to "public" as "fobos";
grant update on "fobos".rolt068 to "public" as "fobos";
grant insert on "fobos".rolt068 to "public" as "fobos";
grant delete on "fobos".rolt068 to "public" as "fobos";
grant index on "fobos".rolt068 to "public" as "fobos";
grant select on "fobos".rolt069 to "public" as "fobos";
grant update on "fobos".rolt069 to "public" as "fobos";
grant insert on "fobos".rolt069 to "public" as "fobos";
grant delete on "fobos".rolt069 to "public" as "fobos";
grant index on "fobos".rolt069 to "public" as "fobos";
grant select on "fobos".rolt050 to "public" as "fobos";
grant update on "fobos".rolt050 to "public" as "fobos";
grant insert on "fobos".rolt050 to "public" as "fobos";
grant delete on "fobos".rolt050 to "public" as "fobos";
grant index on "fobos".rolt050 to "public" as "fobos";
grant select on "fobos".rolt051 to "public" as "fobos";
grant update on "fobos".rolt051 to "public" as "fobos";
grant insert on "fobos".rolt051 to "public" as "fobos";
grant delete on "fobos".rolt051 to "public" as "fobos";
grant index on "fobos".rolt051 to "public" as "fobos";
grant select on "fobos".rolt052 to "public" as "fobos";
grant update on "fobos".rolt052 to "public" as "fobos";
grant insert on "fobos".rolt052 to "public" as "fobos";
grant delete on "fobos".rolt052 to "public" as "fobos";
grant index on "fobos".rolt052 to "public" as "fobos";
grant select on "fobos".te_gent034 to "public" as "fobos";
grant update on "fobos".te_gent034 to "public" as "fobos";
grant insert on "fobos".te_gent034 to "public" as "fobos";
grant delete on "fobos".te_gent034 to "public" as "fobos";
grant index on "fobos".te_gent034 to "public" as "fobos";
grant select on "fobos".rolt053 to "public" as "fobos";
grant update on "fobos".rolt053 to "public" as "fobos";
grant insert on "fobos".rolt053 to "public" as "fobos";
grant delete on "fobos".rolt053 to "public" as "fobos";
grant index on "fobos".rolt053 to "public" as "fobos";
grant select on "fobos".rolt054 to "public" as "fobos";
grant update on "fobos".rolt054 to "public" as "fobos";
grant insert on "fobos".rolt054 to "public" as "fobos";
grant delete on "fobos".rolt054 to "public" as "fobos";
grant index on "fobos".rolt054 to "public" as "fobos";
grant select on "fobos".te_edesa to "public" as "fobos";
grant update on "fobos".te_edesa to "public" as "fobos";
grant insert on "fobos".te_edesa to "public" as "fobos";
grant delete on "fobos".te_edesa to "public" as "fobos";
grant index on "fobos".te_edesa to "public" as "fobos";
grant select on "fobos".te_gan_qto to "public" as "fobos";
grant update on "fobos".te_gan_qto to "public" as "fobos";
grant insert on "fobos".te_gan_qto to "public" as "fobos";
grant delete on "fobos".te_gan_qto to "public" as "fobos";
grant index on "fobos".te_gan_qto to "public" as "fobos";
grant select on "fobos".rolt080 to "public" as "fobos";
grant update on "fobos".rolt080 to "public" as "fobos";
grant insert on "fobos".rolt080 to "public" as "fobos";
grant delete on "fobos".rolt080 to "public" as "fobos";
grant index on "fobos".rolt080 to "public" as "fobos";
grant select on "fobos".rolt081 to "public" as "fobos";
grant update on "fobos".rolt081 to "public" as "fobos";
grant insert on "fobos".rolt081 to "public" as "fobos";
grant delete on "fobos".rolt081 to "public" as "fobos";
grant index on "fobos".rolt081 to "public" as "fobos";
grant select on "fobos".rolt082 to "public" as "fobos";
grant update on "fobos".rolt082 to "public" as "fobos";
grant insert on "fobos".rolt082 to "public" as "fobos";
grant delete on "fobos".rolt082 to "public" as "fobos";
grant index on "fobos".rolt082 to "public" as "fobos";
grant select on "fobos".rolt083 to "public" as "fobos";
grant update on "fobos".rolt083 to "public" as "fobos";
grant insert on "fobos".rolt083 to "public" as "fobos";
grant delete on "fobos".rolt083 to "public" as "fobos";
grant index on "fobos".rolt083 to "public" as "fobos";
grant select on "fobos".te_rol1202 to "public" as "fobos";
grant update on "fobos".te_rol1202 to "public" as "fobos";
grant insert on "fobos".te_rol1202 to "public" as "fobos";
grant delete on "fobos".te_rol1202 to "public" as "fobos";
grant index on "fobos".te_rol1202 to "public" as "fobos";
grant select on "fobos".te_stofis to "public" as "fobos";
grant update on "fobos".te_stofis to "public" as "fobos";
grant insert on "fobos".te_stofis to "public" as "fobos";
grant delete on "fobos".te_stofis to "public" as "fobos";
grant index on "fobos".te_stofis to "public" as "fobos";
grant select on "fobos".te_boddan to "public" as "fobos";
grant update on "fobos".te_boddan to "public" as "fobos";
grant insert on "fobos".te_boddan to "public" as "fobos";
grant delete on "fobos".te_boddan to "public" as "fobos";
grant index on "fobos".te_boddan to "public" as "fobos";
grant select on "fobos".pancho to "public" as "fobos";
grant update on "fobos".pancho to "public" as "fobos";
grant insert on "fobos".pancho to "public" as "fobos";
grant delete on "fobos".pancho to "public" as "fobos";
grant index on "fobos".pancho to "public" as "fobos";
grant select on "fobos".rolt039 to "public" as "fobos";
grant update on "fobos".rolt039 to "public" as "fobos";
grant insert on "fobos".rolt039 to "public" as "fobos";
grant delete on "fobos".rolt039 to "public" as "fobos";
grant index on "fobos".rolt039 to "public" as "fobos";
grant select on "fobos".rolt040 to "public" as "fobos";
grant update on "fobos".rolt040 to "public" as "fobos";
grant insert on "fobos".rolt040 to "public" as "fobos";
grant delete on "fobos".rolt040 to "public" as "fobos";
grant index on "fobos".rolt040 to "public" as "fobos";
grant select on "fobos".rolt055 to "public" as "fobos";
grant update on "fobos".rolt055 to "public" as "fobos";
grant insert on "fobos".rolt055 to "public" as "fobos";
grant delete on "fobos".rolt055 to "public" as "fobos";
grant index on "fobos".rolt055 to "public" as "fobos";
grant select on "fobos".rolt084 to "public" as "fobos";
grant update on "fobos".rolt084 to "public" as "fobos";
grant insert on "fobos".rolt084 to "public" as "fobos";
grant delete on "fobos".rolt084 to "public" as "fobos";
grant index on "fobos".rolt084 to "public" as "fobos";
grant select on "fobos".tempo_011 to "public" as "fobos";
grant update on "fobos".tempo_011 to "public" as "fobos";
grant insert on "fobos".tempo_011 to "public" as "fobos";
grant delete on "fobos".tempo_011 to "public" as "fobos";
grant index on "fobos".tempo_011 to "public" as "fobos";
grant select on "fobos".rept090 to "public" as "fobos";
grant update on "fobos".rept090 to "public" as "fobos";
grant insert on "fobos".rept090 to "public" as "fobos";
grant delete on "fobos".rept090 to "public" as "fobos";
grant index on "fobos".rept090 to "public" as "fobos";
grant select on "fobos".rept092 to "public" as "fobos";
grant update on "fobos".rept092 to "public" as "fobos";
grant insert on "fobos".rept092 to "public" as "fobos";
grant delete on "fobos".rept092 to "public" as "fobos";
grant index on "fobos".rept092 to "public" as "fobos";
grant select on "fobos".tr_codutil to "public" as "fobos";
grant update on "fobos".tr_codutil to "public" as "fobos";
grant insert on "fobos".tr_codutil to "public" as "fobos";
grant delete on "fobos".tr_codutil to "public" as "fobos";
grant index on "fobos".tr_codutil to "public" as "fobos";
grant select on "fobos".rolt041 to "public" as "fobos";
grant update on "fobos".rolt041 to "public" as "fobos";
grant insert on "fobos".rolt041 to "public" as "fobos";
grant delete on "fobos".rolt041 to "public" as "fobos";
grant index on "fobos".rolt041 to "public" as "fobos";
grant select on "fobos".rolt064 to "public" as "fobos";
grant update on "fobos".rolt064 to "public" as "fobos";
grant insert on "fobos".rolt064 to "public" as "fobos";
grant delete on "fobos".rolt064 to "public" as "fobos";
grant index on "fobos".rolt064 to "public" as "fobos";
grant select on "fobos".cajt090 to "public" as "fobos";
grant update on "fobos".cajt090 to "public" as "fobos";
grant insert on "fobos".cajt090 to "public" as "fobos";
grant delete on "fobos".cajt090 to "public" as "fobos";
grant index on "fobos".cajt090 to "public" as "fobos";
grant select on "fobos".rept089 to "public" as "fobos";
grant update on "fobos".rept089 to "public" as "fobos";
grant insert on "fobos".rept089 to "public" as "fobos";
grant delete on "fobos".rept089 to "public" as "fobos";
grant index on "fobos".rept089 to "public" as "fobos";
grant select on "fobos".rept093 to "public" as "fobos";
grant update on "fobos".rept093 to "public" as "fobos";
grant insert on "fobos".rept093 to "public" as "fobos";
grant delete on "fobos".rept093 to "public" as "fobos";
grant index on "fobos".rept093 to "public" as "fobos";
grant select on "fobos".ctbt050 to "public" as "fobos";
grant update on "fobos".ctbt050 to "public" as "fobos";
grant insert on "fobos".ctbt050 to "public" as "fobos";
grant delete on "fobos".ctbt050 to "public" as "fobos";
grant index on "fobos".ctbt050 to "public" as "fobos";
grant select on "fobos".gent057 to "public" as "fobos";
grant update on "fobos".gent057 to "public" as "fobos";
grant insert on "fobos".gent057 to "public" as "fobos";
grant delete on "fobos".gent057 to "public" as "fobos";
grant index on "fobos".gent057 to "public" as "fobos";
grant select on "fobos".actt014 to "public" as "fobos";
grant update on "fobos".actt014 to "public" as "fobos";
grant insert on "fobos".actt014 to "public" as "fobos";
grant delete on "fobos".actt014 to "public" as "fobos";
grant index on "fobos".actt014 to "public" as "fobos";
grant select on "fobos".cxct001 to "public" as "fobos";
grant update on "fobos".cxct001 to "public" as "fobos";
grant insert on "fobos".cxct001 to "public" as "fobos";
grant delete on "fobos".cxct001 to "public" as "fobos";
grant index on "fobos".cxct001 to "public" as "fobos";
grant select on "fobos".tr_cxct001 to "public" as "fobos";
grant update on "fobos".tr_cxct001 to "public" as "fobos";
grant insert on "fobos".tr_cxct001 to "public" as "fobos";
grant delete on "fobos".tr_cxct001 to "public" as "fobos";
grant index on "fobos".tr_cxct001 to "public" as "fobos";
grant select on "fobos".cajt010 to "public" as "fobos";
grant update on "fobos".cajt010 to "public" as "fobos";
grant insert on "fobos".cajt010 to "public" as "fobos";
grant delete on "fobos".cajt010 to "public" as "fobos";
grant index on "fobos".cajt010 to "public" as "fobos";
grant select on "fobos".rept021 to "public" as "fobos";
grant update on "fobos".rept021 to "public" as "fobos";
grant insert on "fobos".rept021 to "public" as "fobos";
grant delete on "fobos".rept021 to "public" as "fobos";
grant index on "fobos".rept021 to "public" as "fobos";
grant select on "fobos".rept023 to "public" as "fobos";
grant update on "fobos".rept023 to "public" as "fobos";
grant insert on "fobos".rept023 to "public" as "fobos";
grant delete on "fobos".rept023 to "public" as "fobos";
grant index on "fobos".rept023 to "public" as "fobos";
grant select on "fobos".rept088 to "public" as "fobos";
grant update on "fobos".rept088 to "public" as "fobos";
grant insert on "fobos".rept088 to "public" as "fobos";
grant delete on "fobos".rept088 to "public" as "fobos";
grant index on "fobos".rept088 to "public" as "fobos";
grant select on "fobos".rept091 to "public" as "fobos";
grant update on "fobos".rept091 to "public" as "fobos";
grant insert on "fobos".rept091 to "public" as "fobos";
grant delete on "fobos".rept091 to "public" as "fobos";
grant index on "fobos".rept091 to "public" as "fobos";
grant select on "fobos".talt020 to "public" as "fobos";
grant update on "fobos".talt020 to "public" as "fobos";
grant insert on "fobos".talt020 to "public" as "fobos";
grant delete on "fobos".talt020 to "public" as "fobos";
grant index on "fobos".talt020 to "public" as "fobos";
grant select on "fobos".talt023 to "public" as "fobos";
grant update on "fobos".talt023 to "public" as "fobos";
grant insert on "fobos".talt023 to "public" as "fobos";
grant delete on "fobos".talt023 to "public" as "fobos";
grant index on "fobos".talt023 to "public" as "fobos";
grant select on "fobos".cxpt001 to "public" as "fobos";
grant update on "fobos".cxpt001 to "public" as "fobos";
grant insert on "fobos".cxpt001 to "public" as "fobos";
grant delete on "fobos".cxpt001 to "public" as "fobos";
grant index on "fobos".cxpt001 to "public" as "fobos";
grant select on "fobos".rept081 to "public" as "fobos";
grant update on "fobos".rept081 to "public" as "fobos";
grant insert on "fobos".rept081 to "public" as "fobos";
grant delete on "fobos".rept081 to "public" as "fobos";
grant index on "fobos".rept081 to "public" as "fobos";
grant select on "fobos".talt061 to "public" as "fobos";
grant update on "fobos".talt061 to "public" as "fobos";
grant insert on "fobos".talt061 to "public" as "fobos";
grant delete on "fobos".talt061 to "public" as "fobos";
grant index on "fobos".talt061 to "public" as "fobos";
grant select on "fobos".rept094 to "public" as "fobos";
grant update on "fobos".rept094 to "public" as "fobos";
grant insert on "fobos".rept094 to "public" as "fobos";
grant delete on "fobos".rept094 to "public" as "fobos";
grant index on "fobos".rept094 to "public" as "fobos";
grant select on "fobos".cxct060 to "public" as "fobos";
grant update on "fobos".cxct060 to "public" as "fobos";
grant insert on "fobos".cxct060 to "public" as "fobos";
grant delete on "fobos".cxct060 to "public" as "fobos";
grant index on "fobos".cxct060 to "public" as "fobos";
grant select on "fobos".talt060 to "public" as "fobos";
grant update on "fobos".talt060 to "public" as "fobos";
grant insert on "fobos".talt060 to "public" as "fobos";
grant delete on "fobos".talt060 to "public" as "fobos";
grant index on "fobos".talt060 to "public" as "fobos";
grant select on "fobos".prueba06 to "public" as "fobos";
grant update on "fobos".prueba06 to "public" as "fobos";
grant insert on "fobos".prueba06 to "public" as "fobos";
grant delete on "fobos".prueba06 to "public" as "fobos";
grant index on "fobos".prueba06 to "public" as "fobos";
grant select on "fobos".rept020 to "public" as "fobos";
grant update on "fobos".rept020 to "public" as "fobos";
grant insert on "fobos".rept020 to "public" as "fobos";
grant delete on "fobos".rept020 to "public" as "fobos";
grant index on "fobos".rept020 to "public" as "fobos";
grant select on "fobos".ctbt013 to "public" as "fobos";
grant update on "fobos".ctbt013 to "public" as "fobos";
grant insert on "fobos".ctbt013 to "public" as "fobos";
grant delete on "fobos".ctbt013 to "public" as "fobos";
grant index on "fobos".ctbt013 to "public" as "fobos";
grant select on "fobos".ordt001 to "public" as "fobos";
grant update on "fobos".ordt001 to "public" as "fobos";
grant insert on "fobos".ordt001 to "public" as "fobos";
grant delete on "fobos".ordt001 to "public" as "fobos";
grant index on "fobos".ordt001 to "public" as "fobos";
grant select on "fobos".gent002 to "public" as "fobos";
grant update on "fobos".gent002 to "public" as "fobos";
grant insert on "fobos".gent002 to "public" as "fobos";
grant delete on "fobos".gent002 to "public" as "fobos";
grant index on "fobos".gent002 to "public" as "fobos";
grant select on "fobos".actt012 to "public" as "fobos";
grant update on "fobos".actt012 to "public" as "fobos";
grant insert on "fobos".actt012 to "public" as "fobos";
grant delete on "fobos".actt012 to "public" as "fobos";
grant index on "fobos".actt012 to "public" as "fobos";
grant select on "fobos".rolt031 to "public" as "fobos";
grant update on "fobos".rolt031 to "public" as "fobos";
grant insert on "fobos".rolt031 to "public" as "fobos";
grant delete on "fobos".rolt031 to "public" as "fobos";
grant index on "fobos".rolt031 to "public" as "fobos";
grant select on "fobos".rept019 to "public" as "fobos";
grant update on "fobos".rept019 to "public" as "fobos";
grant insert on "fobos".rept019 to "public" as "fobos";
grant delete on "fobos".rept019 to "public" as "fobos";
grant index on "fobos".rept019 to "public" as "fobos";
grant select on "fobos".cajt011 to "public" as "fobos";
grant update on "fobos".cajt011 to "public" as "fobos";
grant insert on "fobos".cajt011 to "public" as "fobos";
grant delete on "fobos".cajt011 to "public" as "fobos";
grant index on "fobos".cajt011 to "public" as "fobos";
grant select on "fobos".rolt017 to "public" as "fobos";
grant update on "fobos".rolt017 to "public" as "fobos";
grant insert on "fobos".rolt017 to "public" as "fobos";
grant delete on "fobos".rolt017 to "public" as "fobos";
grant index on "fobos".rolt017 to "public" as "fobos";
grant select on "fobos".t_bal_gen to "public" as "fobos";
grant update on "fobos".t_bal_gen to "public" as "fobos";
grant insert on "fobos".t_bal_gen to "public" as "fobos";
grant delete on "fobos".t_bal_gen to "public" as "fobos";
grant index on "fobos".t_bal_gen to "public" as "fobos";



create view "fobos".vb_factu (local,fecha,codcli,ncliente,codven,iniciales,nvendedor,cod_tran,num_tran,item,nitem,marca,division,linea,grupo,clase,nclase,tipo,cantidad,precio,descuento,subtotal) as 
  select x0.r19_localidad ,DATE (x0.r19_fecing ) ,x0.r19_codcli 
    ,x0.r19_nomcli ,x0.r19_vendedor ,x3.r01_iniciales ,x3.r01_nombres 
    ,x0.r19_cod_tran ,x0.r19_num_tran ,x1.r20_item ,x2.r10_nombre 
    ,x2.r10_marca ,x2.r10_linea ,x2.r10_sub_linea ,x2.r10_cod_grupo 
    ,x2.r10_cod_clase ,x4.r72_desc_clase ,x2.r10_tipo ,x1.r20_cant_ven 
    ,x1.r20_precio ,x1.r20_descuento ,round(((x1.r20_precio * 
    (1. - (x1.r20_descuento / 100. ) ) ) * x1.r20_cant_ven ) 
    , 2 ) from "fobos".rept019 x0 ,"fobos".rept020 x1 ,"fobos".rept010 
    x2 ,"fobos".rept001 x3 ,"fobos".rept072 x4 where ((((((((((((x0.r19_localidad 
    IN (1 ,2 ,3 ,4 )) AND (x0.r19_cod_tran IN ('FA' ,'DF' ,'AF' 
    )) ) AND (x1.r20_compania = x0.r19_compania ) ) AND (x1.r20_localidad 
    = x0.r19_localidad ) ) AND (x1.r20_cod_tran = x0.r19_cod_tran 
    ) ) AND (x1.r20_num_tran = x0.r19_num_tran ) ) AND (x2.r10_compania 
    = x1.r20_compania ) ) AND (x2.r10_codigo = x1.r20_item ) 
    ) AND (x3.r01_compania = x0.r19_compania ) ) AND (x3.r01_codigo 
    = x0.r19_vendedor ) ) AND (x4.r72_compania = x0.r19_compania 
    ) ) AND (x4.r72_cod_clase = x2.r10_cod_clase ) ) ;       
      
create view "fobos".vb_prof (local,fecha,codcli,ncliente,codven,iniciales,nvendedor,proforma,item,nitem,marca,division,linea,grupo,clase,nclase,tipo,cantidad,precio,descuento,subtotal) as 
  select x0.r21_localidad ,DATE (x0.r21_fecing ) ,x0.r21_codcli 
    ,x0.r21_nomcli ,x0.r21_vendedor ,x3.r01_iniciales ,x3.r01_nombres 
    ,x0.r21_numprof ,x1.r22_item ,x2.r10_nombre ,x2.r10_marca 
    ,x2.r10_linea ,x2.r10_sub_linea ,x2.r10_cod_grupo ,x2.r10_cod_clase 
    ,x4.r72_desc_clase ,x2.r10_tipo ,x1.r22_cantidad ,x1.r22_precio 
    ,x1.r22_porc_descto ,round(((x1.r22_precio * (1. - (x1.r22_porc_descto 
    / 100. ) ) ) * x1.r22_cantidad ) , 2 ) from "fobos".rept021 
    x0 ,"fobos".rept022 x1 ,"fobos".rept010 x2 ,"fobos".rept001 
    x3 ,"fobos".rept072 x4 where ((((((((((x0.r21_localidad IN 
    (1 ,2 ,3 ,4 )) AND (x1.r22_compania = x0.r21_compania ) ) 
    AND (x1.r22_localidad = x0.r21_localidad ) ) AND (x1.r22_numprof 
    = x0.r21_numprof ) ) AND (x2.r10_compania = x0.r21_compania 
    ) ) AND (x2.r10_codigo = x1.r22_item ) ) AND (x3.r01_compania 
    = x0.r21_compania ) ) AND (x3.r01_codigo = x0.r21_vendedor 
    ) ) AND (x4.r72_compania = x0.r21_compania ) ) AND (x4.r72_cod_clase 
    = x2.r10_cod_clase ) ) ;                                 
                                  
create view "fobos".vbventas (empresa,local,fecha,codcli,ncliente,codven,iniciales,nvendedor,proforma,item,nitem,marca,division,linea,grupo,clase,nclase,tipo,cantidad,precio,descuento,subtotal,cod_tran,num_tran) as 
  select x0.r21_compania ,x0.r21_localidad ,x0.r21_fecing ,x0.r21_codcli 
    ,x0.r21_nomcli ,x0.r21_vendedor ,x3.r01_iniciales ,x3.r01_nombres 
    ,x0.r21_numprof ,x1.r22_item ,x2.r10_nombre ,x2.r10_marca 
    ,x2.r10_linea ,x2.r10_sub_linea ,x2.r10_cod_grupo ,x2.r10_cod_clase 
    ,x4.r72_desc_clase ,x2.r10_tipo ,x1.r22_cantidad ,x1.r22_precio 
    ,x1.r22_porc_descto ,round(((x1.r22_precio * (1. - (x1.r22_porc_descto 
    / 100. ) ) ) * x1.r22_cantidad ) , 2 ) ,x0.r21_cod_tran ,
    x0.r21_num_tran from "fobos".rept021 x0 ,"fobos".rept022 x1 
    ,"fobos".rept010 x2 ,"fobos".rept001 x3 ,"fobos".rept072 x4 
    where ((((((((((x0.r21_localidad IN (1 ,2 ,3 ,4 )) AND (x1.r22_compania 
    = x0.r21_compania ) ) AND (x1.r22_localidad = x0.r21_localidad 
    ) ) AND (x1.r22_numprof = x0.r21_numprof ) ) AND (x2.r10_compania 
    = x0.r21_compania ) ) AND (x2.r10_codigo = x1.r22_item ) 
    ) AND (x3.r01_compania = x0.r21_compania ) ) AND (x3.r01_codigo 
    = x0.r21_vendedor ) ) AND (x4.r72_compania = x0.r21_compania 
    ) ) AND (x4.r72_cod_clase = x2.r10_cod_clase ) ) ;       
                                                      
create view "informix".vb_profo (marca,codcli,ncliente,codven,iniciales,nvendedor,cod_tran,num_tran,nitem,item,cantidad,precio,descuento,subtotal,fecha,nclase,linea) as 
  select x2.r10_marca ,x0.r21_codcli ,x0.r21_nomcli ,x0.r21_vendedor 
    ,x3.r01_iniciales ,x3.r01_nombres ,x0.r21_cod_tran ,x0.r21_num_tran 
    ,x2.r10_nombre ,x1.r22_item ,x1.r22_cantidad ,x1.r22_precio 
    ,x1.r22_porc_descto ,round(((x1.r22_precio * (1. - (x1.r22_porc_descto 
    / 100. ) ) ) * x1.r22_cantidad ) , 2 ) ,DATE (x0.r21_fecing 
    ) ,x4.r72_desc_clase ,x2.r10_sub_linea from "fobos".rept021 
    x0 ,"fobos".rept022 x1 ,"fobos".rept010 x2 ,"fobos".rept001 
    x3 ,"fobos".rept072 x4 where ((((((((((((x0.r21_localidad 
    IN (1 ,2 ,3 ,4 )) AND (x1.r22_compania = x0.r21_compania 
    ) ) AND (x1.r22_localidad = x0.r21_localidad ) ) AND (x1.r22_numprof 
    = x0.r21_numprof ) ) AND (x2.r10_compania = x1.r22_compania 
    ) ) AND (x2.r10_codigo = x1.r22_item ) ) AND (x4.r72_compania 
    = x0.r21_compania ) ) AND (x4.r72_cod_clase = x2.r10_cod_clase 
    ) ) AND (x3.r01_compania = x0.r21_compania ) ) AND (x3.r01_codigo 
    = x0.r21_vendedor ) ) AND (DATE (x0.r21_fecing ) >= DATE 
    ('07/18/2003' ) ) ) AND (DATE (x0.r21_fecing ) <= DATE ('07/18/2003'
     ) ) ) ;                                 
create view "informix".vb_profo1 (proforma,ncliente,telefono,iniciales,bruto,descuento,neto) as 
  select x0.r21_numprof ,x0.r21_nomcli ,x0.r21_telcli ,x1.r01_iniciales 
    ,x0.r21_tot_bruto ,x0.r21_tot_dscto ,x0.r21_tot_neto from 
    "fobos".rept021 x0 ,"fobos".rept001 x1 where ((((x0.r21_localidad 
    IN (1 ,2 ,3 ,4 )) AND (x1.r01_compania = x0.r21_compania 
    ) ) AND (x1.r01_codigo = x0.r21_vendedor ) ) AND (x0.r21_numprof 
    = 5860 ) ) ;                        
create view "informix".vb_profo2 (proforma,marca,codcli,ncliente,cidruc,direccion,telefono,pago,codven,iniciales,nvendedor,tot_bruto,tot_dscto,tot_neto,cod_tran,num_tran,nitem,item,cantidad,precio,descuento,subtotal,fecha,nclase,linea,medida) as 
  select x0.r21_numprof ,x2.r10_marca ,x0.r21_codcli ,x0.r21_nomcli 
    ,x0.r21_cedruc ,x0.r21_dircli ,x0.r21_telcli ,x0.r21_forma_pago 
    ,x0.r21_vendedor ,x3.r01_iniciales ,x3.r01_nombres ,x0.r21_tot_bruto 
    ,x0.r21_tot_dscto ,x0.r21_tot_neto ,x0.r21_cod_tran ,x0.r21_num_tran 
    ,x2.r10_nombre ,x1.r22_item ,x1.r22_cantidad ,x1.r22_precio 
    ,x1.r22_porc_descto ,round(((x1.r22_precio * (1. - (x1.r22_porc_descto 
    / 100. ) ) ) * x1.r22_cantidad ) , 2 ) ,DATE (x0.r21_fecing 
    ) ,x4.r72_desc_clase ,x2.r10_sub_linea ,x2.r10_uni_med from 
    "fobos".rept021 x0 ,"fobos".rept022 x1 ,"fobos".rept010 x2 ,
    "fobos".rept001 x3 ,"fobos".rept072 x4 where (((((((((((x0.r21_localidad 
    IN (1 ,2 ,3 ,4 )) AND (x1.r22_compania = x0.r21_compania 
    ) ) AND (x1.r22_localidad = x0.r21_localidad ) ) AND (x1.r22_numprof 
    = x0.r21_numprof ) ) AND (x2.r10_compania = x1.r22_compania 
    ) ) AND (x2.r10_codigo = x1.r22_item ) ) AND (x4.r72_compania 
    = x0.r21_compania ) ) AND (x4.r72_cod_clase = x2.r10_cod_clase 
    ) ) AND (x3.r01_compania = x0.r21_compania ) ) AND (x3.r01_codigo 
    = x0.r21_vendedor ) ) AND (x0.r21_numprof = 5860 ) ) ;   
                
create view "informix".vb_compras (marca,codcli,ncliente,codven,iniciales,nvendedor,cod_tran,num_tran,nitem,item,cantidad,precio,descuento,subtotal,fecha,nclase,linea) as 
  select x2.r10_marca ,x0.r19_codcli ,x0.r19_nomcli ,x0.r19_vendedor 
    ,x3.r01_iniciales ,x3.r01_nombres ,x0.r19_cod_tran ,x0.r19_num_tran 
    ,x2.r10_nombre ,x1.r20_item ,x1.r20_cant_ven ,x1.r20_precio 
    ,x1.r20_descuento ,round(((x1.r20_precio * (1. - (x1.r20_descuento 
    / 100. ) ) ) * x1.r20_cant_ven ) , 2 ) ,DATE (x0.r19_fecing 
    ) ,x4.r72_desc_clase ,x2.r10_sub_linea from "fobos".rept019 
    x0 ,"fobos".rept020 x1 ,"fobos".rept010 x2 ,"fobos".rept001 
    x3 ,"fobos".rept072 x4 where (((((((((((((x0.r19_localidad 
    IN (1 ,2 ,3 ,4 )) AND (x0.r19_cod_tran IN ('IM' ,'CL' ,'DC' 
    ,'DI' )) ) AND (x1.r20_compania = x0.r19_compania ) ) AND 
    (x1.r20_localidad = x0.r19_localidad ) ) AND (x1.r20_cod_tran 
    = x0.r19_cod_tran ) ) AND (x1.r20_num_tran = x0.r19_num_tran 
    ) ) AND (x2.r10_compania = x1.r20_compania ) ) AND (x2.r10_codigo 
    = x1.r20_item ) ) AND (x4.r72_compania = x0.r19_compania 
    ) ) AND (x4.r72_cod_clase = x2.r10_cod_clase ) ) AND (x3.r01_compania 
    = x0.r19_compania ) ) AND (x3.r01_codigo = x0.r19_vendedor 
    ) ) AND ((DATE (x0.r19_fecing ) >= DATE ('08/01/2003' ) ) 
    AND (DATE (x0.r19_fecing ) <= DATE ('08/26/2003' ) ) ) ) ; 
                                                             
         
create view "informix".vb_proforma (marca,codcli,ncliente,codven,iniciales,nvendedor,cod_tran,num_tran,item,cantidad,precio,descuento,subtotal,fecha,nclase,linea) as 
  select x2.r10_marca ,x0.r21_codcli ,x0.r21_nomcli ,x0.r21_vendedor 
    ,x3.r01_iniciales ,x3.r01_nombres ,'' ,x0.r21_numprof ,x1.r22_item 
    ,x1.r22_cantidad ,x1.r22_precio ,x1.r22_porc_descto ,round(((x1.r22_precio 
    * (1. - (x1.r22_porc_descto / 100. ) ) ) * x1.r22_cantidad 
    ) , 2 ) ,DATE (x0.r21_fecing ) ,x4.r72_desc_clase ,x2.r10_sub_linea 
    from "fobos".rept021 x0 ,"fobos".rept022 x1 ,"fobos".rept010 
    x2 ,"fobos".rept001 x3 ,"fobos".rept072 x4 where (((((((((((((x0.r21_localidad 
    IN (1 ,2 ,3 ,4 )) AND (x0.r21_cod_tran IS NULL ) ) AND (x0.r21_num_tran 
    IS NULL ) ) AND (x1.r22_compania = x0.r21_compania ) ) AND 
    (x1.r22_localidad = x0.r21_localidad ) ) AND (x1.r22_numprof 
    = x0.r21_numprof ) ) AND (x2.r10_compania = x1.r22_compania 
    ) ) AND (x2.r10_codigo = x1.r22_item ) ) AND (x4.r72_compania 
    = x0.r21_compania ) ) AND (x4.r72_cod_clase = x2.r10_cod_clase 
    ) ) AND (x3.r01_compania = x0.r21_compania ) ) AND (x3.r01_codigo 
    = x0.r21_vendedor ) ) AND (DATE (x0.r21_fecing ) = DATE (
    '09/05/2003' ) ) ) ;                                      
                    
create view "informix".vb_ventas (marca,codcli,ncliente,codven,iniciales,nvendedor,cod_tran,num_tran,nitem,item,cantidad,precio,descuento,subtotal,fecha,nclase,linea) as 
  select x2.r10_marca ,x0.r19_codcli ,x0.r19_nomcli ,x0.r19_vendedor 
    ,x3.r01_iniciales ,x3.r01_nombres ,x0.r19_cod_tran ,x0.r19_num_tran 
    ,x2.r10_nombre ,x1.r20_item ,x1.r20_cant_ven ,x1.r20_precio 
    ,x1.r20_descuento ,round(((x1.r20_precio * (1. - (x1.r20_descuento 
    / 100. ) ) ) * x1.r20_cant_ven ) , 2 ) ,DATE (x0.r19_fecing 
    ) ,x4.r72_desc_clase ,x2.r10_sub_linea from "fobos".rept019 
    x0 ,"fobos".rept020 x1 ,"fobos".rept010 x2 ,"fobos".rept001 
    x3 ,"fobos".rept072 x4 where (((((((((((((x0.r19_localidad 
    IN (1 ,2 ,3 ,4 )) AND (x0.r19_cod_tran IN ('FA' ,'DF' ,'AF' 
    )) ) AND (x1.r20_compania = x0.r19_compania ) ) AND (x1.r20_localidad 
    = x0.r19_localidad ) ) AND (x1.r20_cod_tran = x0.r19_cod_tran 
    ) ) AND (x1.r20_num_tran = x0.r19_num_tran ) ) AND (x2.r10_compania 
    = x1.r20_compania ) ) AND (x2.r10_codigo = x1.r20_item ) 
    ) AND (x4.r72_compania = x0.r19_compania ) ) AND (x4.r72_cod_clase 
    = x2.r10_cod_clase ) ) AND (x3.r01_compania = x0.r19_compania 
    ) ) AND (x3.r01_codigo = x0.r19_vendedor ) ) AND ((DATE (x0.r19_fecing 
    ) >= DATE ('02/01/2004' ) ) AND (DATE (x0.r19_fecing ) <= 
    DATE ('02/16/2004' ) ) ) ) ;      
create view "informix".vb_ventas1 (marca,codcli,ncliente,codven,iniciales,nvendedor,cod_tran,num_tran,nitem,item,cantidad,precio,descuento,subtotal,fecha,nclase,linea) as 
  select x2.r10_marca ,x0.r19_codcli ,x0.r19_nomcli ,x0.r19_vendedor 
    ,x3.r01_iniciales ,x3.r01_nombres ,x0.r19_cod_tran ,x0.r19_num_tran 
    ,x2.r10_nombre ,x1.r20_item ,x1.r20_cant_ven ,x1.r20_precio 
    ,x1.r20_descuento ,round(((x1.r20_precio * (1. - (x1.r20_descuento 
    / 100. ) ) ) * x1.r20_cant_ven ) , 2 ) ,DATE (x0.r19_fecing 
    ) ,x4.r72_desc_clase ,x2.r10_sub_linea from "fobos".rept019 
    x0 ,"fobos".rept020 x1 ,"fobos".rept010 x2 ,"fobos".rept001 
    x3 ,"fobos".rept072 x4 where (((((((((((((x0.r19_localidad 
    IN (1 ,2 ,3 ,4 )) AND (x0.r19_cod_tran IN ('FA' ,'DF' ,'AF' 
    )) ) AND (x1.r20_compania = x0.r19_compania ) ) AND (x1.r20_localidad 
    = x0.r19_localidad ) ) AND (x1.r20_cod_tran = x0.r19_cod_tran 
    ) ) AND (x1.r20_num_tran = x0.r19_num_tran ) ) AND (x2.r10_compania 
    = x1.r20_compania ) ) AND (x2.r10_codigo = x1.r20_item ) 
    ) AND (x4.r72_compania = x0.r19_compania ) ) AND (x4.r72_cod_clase 
    = x2.r10_cod_clase ) ) AND (x3.r01_compania = x0.r19_compania 
    ) ) AND (x3.r01_codigo = x0.r19_vendedor ) ) AND ((DATE (x0.r19_fecing 
    ) >= DATE ('04/01/2004' ) ) AND (DATE (x0.r19_fecing ) <= 
    DATE ('04/05/2004' ) ) ) ) ;     



create index "fobos".i01_fk_gent000 on "fobos".gent000 (g00_usuario) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_gent000 on "fobos".gent000 
    (g00_serial) using btree  in idxdbs ;
alter table "fobos".gent000 add constraint primary key (g00_serial) 
    constraint "fobos".pk_gent000  ;
create index "fobos".i01_fk_gent001 on "fobos".gent001 (g01_usuario) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_gent001 on "fobos".gent001 
    (g01_compania) using btree  in idxdbs ;
alter table "fobos".gent001 add constraint primary key (g01_compania) 
    constraint "fobos".pk_gent001  ;
create index "fobos".i01_fk_gent003 on "fobos".gent003 (g03_modulo) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_gent003 on "fobos".gent003 
    (g03_compania,g03_areaneg) using btree  in idxdbs ;
create index "fobos".i02_fk_gent003 on "fobos".gent003 (g03_compania) 
    using btree  in idxdbs ;
create index "fobos".i03_fk_gent003 on "fobos".gent003 (g03_usuario) 
    using btree  in idxdbs ;
alter table "fobos".gent003 add constraint primary key (g03_compania,
    g03_areaneg) constraint "fobos".pk_gent003  ;
create unique index "fobos".i01_pk_gent004 on "fobos".gent004 
    (g04_grupo) using btree  in idxdbs ;
alter table "fobos".gent004 add constraint primary key (g04_grupo) 
    constraint "fobos".pk_gent004  ;
create index "fobos".i01_fk_gent005 on "fobos".gent005 (g05_grupo) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_gent005 on "fobos".gent005 
    (g05_usuario) using btree  in idxdbs ;
alter table "fobos".gent005 add constraint primary key (g05_usuario) 
    constraint "fobos".pk_gent005  ;
create index "fobos".i01_fk_gent007 on "fobos".gent007 (g07_user) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_gent007 on "fobos".gent007 
    (g07_user,g07_impresora) using btree  in idxdbs ;
create index "fobos".i02_fk_gent007 on "fobos".gent007 (g07_impresora) 
    using btree  in idxdbs ;
create index "fobos".i03_fk_gent007 on "fobos".gent007 (g07_usuario) 
    using btree  in idxdbs ;
alter table "fobos".gent007 add constraint primary key (g07_user,
    g07_impresora) constraint "fobos".pk_gent007  ;
create index "fobos".i01_fk_gent009 on "fobos".gent009 (g09_compania) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_gent009 on "fobos".gent009 
    (g09_compania,g09_banco,g09_numero_cta) using btree  in idxdbs 
    ;
create index "fobos".i02_fk_gent009 on "fobos".gent009 (g09_banco) 
    using btree  in idxdbs ;
create index "fobos".i03_fk_gent009 on "fobos".gent009 (g09_usuario) 
    using btree  in idxdbs ;
alter table "fobos".gent009 add constraint primary key (g09_compania,
    g09_banco,g09_numero_cta) constraint "fobos".pk_gent009  ;
    
create index "fobos".i01_fk_gent011 on "fobos".gent011 (g11_usuario) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_gent011 on "fobos".gent011 
    (g11_tiporeg) using btree  in idxdbs ;
alter table "fobos".gent011 add constraint primary key (g11_tiporeg) 
    constraint "fobos".pk_gent011  ;
create index "fobos".i01_fk_gent012 on "fobos".gent012 (g12_tiporeg) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_gent012 on "fobos".gent012 
    (g12_tiporeg,g12_subtipo) using btree  in idxdbs ;
create index "fobos".i02_fk_gent012 on "fobos".gent012 (g12_usuario) 
    using btree  in idxdbs ;
alter table "fobos".gent012 add constraint primary key (g12_tiporeg,
    g12_subtipo) constraint "fobos".pk_gent012  ;
create index "fobos".i01_fk_gent017 on "fobos".gent017 (g17_usuario) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_gent017 on "fobos".gent017 
    (g17_codrubro) using btree  in idxdbs ;
alter table "fobos".gent017 add constraint primary key (g17_codrubro) 
    constraint "fobos".pk_gent017  ;
create index "fobos".i01_fk_gent018 on "fobos".gent018 (g18_compania,
    g18_localidad) using btree  in idxdbs ;
create unique index "fobos".i01_pk_gent018 on "fobos".gent018 
    (g18_compania,g18_localidad,g18_areaneg) using btree  in 
    idxdbs ;
create index "fobos".i02_fk_gent018 on "fobos".gent018 (g18_compania,
    g18_areaneg) using btree  in idxdbs ;
create index "fobos".i03_fk_gent018 on "fobos".gent018 (g18_usuario) 
    using btree  in idxdbs ;
alter table "fobos".gent018 add constraint primary key (g18_compania,
    g18_localidad,g18_areaneg) constraint "fobos".pk_gent018  
    ;
create index "fobos".i01_fk_gent034 on "fobos".gent034 (g34_compania,
    g34_cod_ccosto) using btree  in idxdbs ;
create unique index "fobos".i01_pk_gent034 on "fobos".gent034 
    (g34_compania,g34_cod_depto) using btree  in idxdbs ;
create index "fobos".i02_fk_gent034 on "fobos".gent034 (g34_usuario) 
    using btree  in idxdbs ;
create index "fobos".i03_fk_gent034 on "fobos".gent034 (g34_compania,
    g34_aux_deprec) using btree  in idxdbs ;
alter table "fobos".gent034 add constraint primary key (g34_compania,
    g34_cod_depto) constraint "fobos".pk_gent034  ;
create index "fobos".i01_fk_gent035 on "fobos".gent035 (g35_compania) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_gent035 on "fobos".gent035 
    (g35_compania,g35_cod_cargo) using btree  in idxdbs ;
create index "fobos".i02_fk_gent035 on "fobos".gent035 (g35_usuario) 
    using btree  in idxdbs ;
alter table "fobos".gent035 add constraint primary key (g35_compania,
    g35_cod_cargo) constraint "fobos".pk_gent035  ;
create index "fobos".i01_fk_gent036 on "fobos".gent036 (g36_usuario) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_gent036 on "fobos".gent036 
    (g36_dia) using btree  in idxdbs ;
alter table "fobos".gent036 add constraint primary key (g36_dia) 
    constraint "fobos".pk_gent036  ;
create index "fobos".i01_fk_gent050 on "fobos".gent050 (g50_usuario) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_gent050 on "fobos".gent050 
    (g50_modulo) using btree  in idxdbs ;
alter table "fobos".gent050 add constraint primary key (g50_modulo) 
    constraint "fobos".pk_gent050  ;
create index "fobos".i01_fk_gent051 on "fobos".gent051 (g51_usuario) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_gent051 on "fobos".gent051 
    (g51_basedatos) using btree  in idxdbs ;
alter table "fobos".gent051 add constraint primary key (g51_basedatos) 
    constraint "fobos".pk_gent051  ;
create index "fobos".i01_fk_gent052 on "fobos".gent052 (g52_modulo) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_gent052 on "fobos".gent052 
    (g52_modulo,g52_usuario) using btree  in idxdbs ;
create index "fobos".i02_fk_gent052 on "fobos".gent052 (g52_usuario) 
    using btree  in idxdbs ;
alter table "fobos".gent052 add constraint primary key (g52_modulo,
    g52_usuario) constraint "fobos".pk_gent052  ;
create unique index "fobos".i01_pk_gent053 on "fobos".gent053 
    (g53_modulo,g53_usuario,g53_compania) using btree  in idxdbs 
    ;
create index "fobos".i02_fk_gent053 on "fobos".gent053 (g53_compania) 
    using btree  in idxdbs ;
create index "fobos".i03_fk_gent053 on "fobos".gent053 (g53_usuario) 
    using btree  in idxdbs ;
alter table "fobos".gent053 add constraint primary key (g53_modulo,
    g53_usuario,g53_compania) constraint "fobos".pk_gent053  ;
    
create index "fobos".i01_fk_gent054 on "fobos".gent054 (g54_modulo) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_gent054 on "fobos".gent054 
    (g54_modulo,g54_proceso) using btree  in idxdbs ;
create index "fobos".i02_fk_gent054 on "fobos".gent054 (g54_usuario) 
    using btree  in idxdbs ;
alter table "fobos".gent054 add constraint primary key (g54_modulo,
    g54_proceso) constraint "fobos".pk_gent054  ;
create index "fobos".i01_fk_talt001 on "fobos".talt001 (t01_compania,
    t01_grupo_linea) using btree  in idxdbs ;
create unique index "fobos".i01_pk_talt001 on "fobos".talt001 
    (t01_compania,t01_linea) using btree  in idxdbs ;
create index "fobos".i02_fk_talt001 on "fobos".talt001 (t01_compania) 
    using btree  in idxdbs ;
create index "fobos".i03_fk_talt001 on "fobos".talt001 (t01_usuario) 
    using btree  in idxdbs ;
alter table "fobos".talt001 add constraint primary key (t01_compania,
    t01_linea) constraint "fobos".pk_talt001  ;
create index "fobos".i01_fk_talt002 on "fobos".talt002 (t02_compania) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_talt002 on "fobos".talt002 
    (t02_compania,t02_seccion) using btree  in idxdbs ;
create index "fobos".i02_fk_talt002 on "fobos".talt002 (t02_usuario) 
    using btree  in idxdbs ;
alter table "fobos".talt002 add constraint primary key (t02_compania,
    t02_seccion) constraint "fobos".pk_talt002  ;
create index "fobos".i01_fk_gent013 on "fobos".gent013 (g13_usuario) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_gent013 on "fobos".gent013 
    (g13_moneda) using btree  in idxdbs ;
alter table "fobos".gent013 add constraint primary key (g13_moneda) 
    constraint "fobos".pk_gent013  ;
create index "fobos".i01_fk_gent031 on "fobos".gent031 (g31_pais) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_gent031 on "fobos".gent031 
    (g31_ciudad) using btree  in idxdbs ;
create index "fobos".i02_fk_gent031 on "fobos".gent031 (g31_usuario) 
    using btree  in idxdbs ;
create index "fobos".i03_fk_gent031 on "fobos".gent031 (g31_pais,
    g31_divi_poli) using btree  in idxdbs ;
alter table "fobos".gent031 add constraint primary key (g31_ciudad) 
    constraint "fobos".pk_gent031  ;
create index "fobos".i01_fk_gent014 on "fobos".gent014 (g14_moneda_ori) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_gent014 on "fobos".gent014 
    (g14_serial) using btree  in idxdbs ;
create index "fobos".i02_fk_gent014 on "fobos".gent014 (g14_moneda_des) 
    using btree  in idxdbs ;
create index "fobos".i03_fk_gent014 on "fobos".gent014 (g14_usuario) 
    using btree  in idxdbs ;
alter table "fobos".gent014 add constraint primary key (g14_serial) 
    constraint "fobos".pk_gent014  ;
create index "fobos".i01_fk_gent032 on "fobos".gent032 (g32_compania) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_gent032 on "fobos".gent032 
    (g32_compania,g32_zona_venta) using btree  in idxdbs ;
create index "fobos".i02_fk_gent032 on "fobos".gent032 (g32_usuario) 
    using btree  in idxdbs ;
alter table "fobos".gent032 add constraint primary key (g32_compania,
    g32_zona_venta) constraint "fobos".pk_gent032  ;
create index "fobos".i01_fk_gent033 on "fobos".gent033 (g33_compania) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_gent033 on "fobos".gent033 
    (g33_compania,g33_cod_ccosto) using btree  in idxdbs ;
create index "fobos".i02_fk_gent033 on "fobos".gent033 (g33_usuario) 
    using btree  in idxdbs ;
alter table "fobos".gent033 add constraint primary key (g33_compania,
    g33_cod_ccosto) constraint "fobos".pk_gent033  ;
create index "fobos".i01_fk_gent010 on "fobos".gent010 (g10_usuario) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_gent010 on "fobos".gent010 
    (g10_compania,g10_tarjeta,g10_cod_tarj,g10_cont_cred) using 
    btree  in idxdbs ;
create index "fobos".i02_fk_gent010 on "fobos".gent010 (g10_compania) 
    using btree  in idxdbs ;
create index "fobos".i03_fk_gent010 on "fobos".gent010 (g10_codcobr) 
    using btree  in idxdbs ;
create index "fobos".i04_fk_gent010 on "fobos".gent010 (g10_compania,
    g10_cod_tarj,g10_cont_cred) using btree  in idxdbs ;
alter table "fobos".gent010 add constraint primary key (g10_compania,
    g10_tarjeta,g10_cod_tarj,g10_cont_cred) constraint "fobos"
    .pk_gent010  ;
create index "fobos".i01_fk_gent020 on "fobos".gent020 (g20_compania) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_gent020 on "fobos".gent020 
    (g20_compania,g20_grupo_linea) using btree  in idxdbs ;
create index "fobos".i02_fk_gent020 on "fobos".gent020 (g20_compania,
    g20_areaneg) using btree  in idxdbs ;
create index "fobos".i03_fk_gent020 on "fobos".gent020 (g20_usuario) 
    using btree  in idxdbs ;
alter table "fobos".gent020 add constraint primary key (g20_compania,
    g20_grupo_linea) constraint "fobos".pk_gent020  ;
create index "fobos".i01_fk_gent055 on "fobos".gent055 (g55_modulo,
    g55_proceso) using btree  in idxdbs ;
create unique index "fobos".i01_pk_gent055 on "fobos".gent055 
    (g55_user,g55_compania,g55_modulo,g55_proceso) using btree 
     in idxdbs ;
create index "fobos".i02_fk_gent055 on "fobos".gent055 (g55_compania) 
    using btree  in idxdbs ;
create index "fobos".i03_fk_gent055 on "fobos".gent055 (g55_user) 
    using btree  in idxdbs ;
create index "fobos".i04_fk_gent055 on "fobos".gent055 (g55_usuario) 
    using btree  in idxdbs ;
alter table "fobos".gent055 add constraint primary key (g55_user,
    g55_compania,g55_modulo,g55_proceso) constraint "fobos".pk_gent055 
     ;
create index "fobos".i01_fk_gent006 on "fobos".gent006 (g06_usuario) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_gent006 on "fobos".gent006 
    (g06_impresora) using btree  in idxdbs ;
alter table "fobos".gent006 add constraint primary key (g06_impresora) 
    constraint "fobos".pk_gent006  ;
create index "fobos".i01_fk_gent008 on "fobos".gent008 (g08_usuario) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_gent008 on "fobos".gent008 
    (g08_banco) using btree  in idxdbs ;
alter table "fobos".gent008 add constraint primary key (g08_banco) 
    constraint "fobos".pk_gent008  ;
create index "fobos".i01_fk_gent030 on "fobos".gent030 (g30_usuario) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_gent030 on "fobos".gent030 
    (g30_pais) using btree  in idxdbs ;
alter table "fobos".gent030 add constraint primary key (g30_pais) 
    constraint "fobos".pk_gent030  ;
create index "fobos".i01_fk_gent022 on "fobos".gent022 (g22_usuario) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_gent022 on "fobos".gent022 
    (g22_cod_subtipo) using btree  in idxdbs ;
create index "fobos".i02_fk_gent022 on "fobos".gent022 (g22_cod_tran) 
    using btree  in idxdbs ;
alter table "fobos".gent022 add constraint primary key (g22_cod_subtipo) 
    constraint "fobos".pk_gent022  ;
create index "fobos".i01_fk_talt003 on "fobos".talt003 (t03_compania) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_talt003 on "fobos".talt003 
    (t03_compania,t03_mecanico) using btree  in idxdbs ;
create index "fobos".i02_fk_talt003 on "fobos".talt003 (t03_compania,
    t03_codrol) using btree  in idxdbs ;
create index "fobos".i03_fk_talt003 on "fobos".talt003 (t03_compania,
    t03_seccion) using btree  in idxdbs ;
create index "fobos".i04_fk_talt003 on "fobos".talt003 (t03_compania,
    t03_linea) using btree  in idxdbs ;
create index "fobos".i05_fk_talt003 on "fobos".talt003 (t03_usuario) 
    using btree  in idxdbs ;
alter table "fobos".talt003 add constraint primary key (t03_compania,
    t03_mecanico) constraint "fobos".pk_talt003  ;
create index "fobos".i01_fk_talt005 on "fobos".talt005 (t05_compania) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_talt005 on "fobos".talt005 
    (t05_compania,t05_tipord) using btree  in idxdbs ;
create index "fobos".i02_fk_talt005 on "fobos".talt005 (t05_cli_default) 
    using btree  in idxdbs ;
create index "fobos".i03_fk_talt005 on "fobos".talt005 (t05_usuario) 
    using btree  in idxdbs ;
alter table "fobos".talt005 add constraint primary key (t05_compania,
    t05_tipord) constraint "fobos".pk_talt005  ;
create index "fobos".i01_fk_talt006 on "fobos".talt006 (t06_compania) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_talt006 on "fobos".talt006 
    (t06_compania,t06_tipord,t06_subtipo) using btree  in idxdbs 
    ;
create index "fobos".i02_fk_talt006 on "fobos".talt006 (t06_compania,
    t06_tipord) using btree  in idxdbs ;
create index "fobos".i03_fk_talt006 on "fobos".talt006 (t06_usuario) 
    using btree  in idxdbs ;
alter table "fobos".talt006 add constraint primary key (t06_compania,
    t06_tipord,t06_subtipo) constraint "fobos".pk_talt006  ;
create index "fobos".i01_fk_talt007 on "fobos".talt007 (t07_compania) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_talt007 on "fobos".talt007 
    (t07_compania,t07_codtarea) using btree  in idxdbs ;
create index "fobos".i02_fk_talt007 on "fobos".talt007 (t07_usuario) 
    using btree  in idxdbs ;
alter table "fobos".talt007 add constraint primary key (t07_compania,
    t07_codtarea) constraint "fobos".pk_talt007  ;
create index "fobos".i01_fk_talt008 on "fobos".talt008 (t08_usuario) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_talt008 on "fobos".talt008 
    (t08_compania,t08_codtarea,t08_orden) using btree  in idxdbs 
    ;
create index "fobos".i03_fk_talt008 on "fobos".talt008 (t08_compania,
    t08_codtarea) using btree  in idxdbs ;
alter table "fobos".talt008 add constraint primary key (t08_compania,
    t08_codtarea,t08_orden) constraint "fobos".pk_talt008  ;
create index "fobos".i01_fk_talt009 on "fobos".talt009 (t09_usuario) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_talt009 on "fobos".talt009 
    (t09_compania,t09_codtarea,t09_dificultad) using btree  in 
    idxdbs ;
create index "fobos".i02_fk_talt009 on "fobos".talt009 (t09_compania,
    t09_codtarea) using btree  in idxdbs ;
alter table "fobos".talt009 add constraint primary key (t09_compania,
    t09_codtarea,t09_dificultad) constraint "fobos".pk_talt009 
     ;
create index "fobos".i01_fk_rept000 on "fobos".rept000 (r00_codcli_tal) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_rept000 on "fobos".rept000 
    (r00_compania) using btree  in idxdbs ;
create index "fobos".i02_fk_rept000 on "fobos".rept000 (r00_compania,
    r00_bodega_fact) using btree  in idxdbs ;
create index "fobos".i03_fk_rept000 on "fobos".rept000 (r00_cia_taller) 
    using btree  in idxdbs ;
alter table "fobos".rept000 add constraint primary key (r00_compania) 
    constraint "fobos".pk_rept000  ;
create index "fobos".i01_fk_rept001 on "fobos".rept001 (r01_compania) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_rept001 on "fobos".rept001 
    (r01_compania,r01_codigo) using btree  in idxdbs ;
create index "fobos".i02_fk_rept001 on "fobos".rept001 (r01_compania,
    r01_codrol) using btree  in idxdbs ;
create index "fobos".i03_fk_rept001 on "fobos".rept001 (r01_usuario) 
    using btree  in idxdbs ;
alter table "fobos".rept001 add constraint primary key (r01_compania,
    r01_codigo) constraint "fobos".pk_rept001  ;
create index "fobos".i01_fk_rept002 on "fobos".rept002 (r02_compania,
    r02_localidad) using btree  in idxdbs ;
create unique index "fobos".i01_pk_rept002 on "fobos".rept002 
    (r02_compania,r02_codigo) using btree  in idxdbs ;
create index "fobos".i02_fk_rept002 on "fobos".rept002 (r02_usuario) 
    using btree  in idxdbs ;
create index "fobos".i03_fk_rept002 on "fobos".rept002 (r02_compania,
    r02_tipo_ident) using btree  in idxdbs ;
alter table "fobos".rept002 add constraint primary key (r02_compania,
    r02_codigo) constraint "fobos".pk_rept002  ;
create index "fobos".i01_fk_rept003 on "fobos".rept003 (r03_compania) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_rept003 on "fobos".rept003 
    (r03_compania,r03_codigo) using btree  in idxdbs ;
create index "fobos".i02_fk_rept003 on "fobos".rept003 (r03_compania,
    r03_grupo_linea) using btree  in idxdbs ;
create index "fobos".i03_fk_rept003 on "fobos".rept003 (r03_usuario) 
    using btree  in idxdbs ;
alter table "fobos".rept003 add constraint primary key (r03_compania,
    r03_codigo) constraint "fobos".pk_rept003  ;
create index "fobos".i01_fk_rept004 on "fobos".rept004 (r04_compania) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_rept004 on "fobos".rept004 
    (r04_compania,r04_rotacion) using btree  in idxdbs ;
create index "fobos".i02_fk_rept004 on "fobos".rept004 (r04_usuario) 
    using btree  in idxdbs ;
alter table "fobos".rept004 add constraint primary key (r04_compania,
    r04_rotacion) constraint "fobos".pk_rept004  ;
create index "fobos".i01_fk_rept005 on "fobos".rept005 (r05_usuario) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_rept005 on "fobos".rept005 
    (r05_codigo) using btree  in idxdbs ;
alter table "fobos".rept005 add constraint primary key (r05_codigo) 
    constraint "fobos".pk_rept005  ;
create index "fobos".i01_fk_rept006 on "fobos".rept006 (r06_usuario) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_rept006 on "fobos".rept006 
    (r06_codigo) using btree  in idxdbs ;
alter table "fobos".rept006 add constraint primary key (r06_codigo) 
    constraint "fobos".pk_rept006  ;
create index "fobos".i01_fk_rept007 on "fobos".rept007 (r07_compania) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_rept007 on "fobos".rept007 
    (r07_serial) using btree  in idxdbs ;
create index "fobos".i02_fk_rept007 on "fobos".rept007 (r07_compania,
    r07_linea) using btree  in idxdbs ;
create index "fobos".i03_fk_rept007 on "fobos".rept007 (r07_moneda) 
    using btree  in idxdbs ;
alter table "fobos".rept007 add constraint primary key (r07_serial) 
    constraint "fobos".pk_rept007  ;
create index "fobos".i01_fk_rept008 on "fobos".rept008 (r08_compania) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_rept008 on "fobos".rept008 
    (r08_serial) using btree  in idxdbs ;
create index "fobos".i02_fk_rept008 on "fobos".rept008 (r08_compania,
    r08_rotacion) using btree  in idxdbs ;
alter table "fobos".rept008 add constraint primary key (r08_serial) 
    constraint "fobos".pk_rept008  ;
create index "fobos".i01_fk_rept011 on "fobos".rept011 (r11_compania) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_rept011 on "fobos".rept011 
    (r11_compania,r11_bodega,r11_item) using btree  in idxdbs 
    ;
create index "fobos".i02_fk_rept011 on "fobos".rept011 (r11_compania,
    r11_bodega) using btree  in idxdbs ;
create index "fobos".i03_fk_rept011 on "fobos".rept011 (r11_compania,
    r11_item) using btree  in idxdbs ;
create index "fobos".i04_fk_rept011 on "fobos".rept011 (r11_compania,
    r11_bodega,r11_item,r11_stock_act) using btree  in idxdbs 
    ;
alter table "fobos".rept011 add constraint primary key (r11_compania,
    r11_bodega,r11_item) constraint "fobos".pk_rept011  ;
create index "fobos".i01_fk_rept012 on "fobos".rept012 (r12_compania) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_rept012 on "fobos".rept012 
    (r12_compania,r12_moneda,r12_fecha,r12_bodega,r12_item) using 
    btree  in idxdbs ;
create index "fobos".i02_fk_rept012 on "fobos".rept012 (r12_moneda) 
    using btree  in idxdbs ;
create index "fobos".i03_fk_rept012 on "fobos".rept012 (r12_compania,
    r12_bodega) using btree  in idxdbs ;
create index "fobos".i04_fk_rept012 on "fobos".rept012 (r12_compania,
    r12_item) using btree  in idxdbs ;
create index "fobos".i05_co_rept012 on "fobos".rept012 (r12_compania,
    r12_item,r12_fecha) using btree  in idxdbs ;
alter table "fobos".rept012 add constraint primary key (r12_compania,
    r12_moneda,r12_fecha,r12_bodega,r12_item) constraint "fobos"
    .pk_rept012  ;
create index "fobos".i01_fk_rept013 on "fobos".rept013 (r13_compania) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_rept013 on "fobos".rept013 
    (r13_serial) using btree  in idxdbs ;
create index "fobos".i02_fk_rept013 on "fobos".rept013 (r13_compania,
    r13_bodega) using btree  in idxdbs ;
create index "fobos".i03_fk_rept013 on "fobos".rept013 (r13_compania,
    r13_item) using btree  in idxdbs ;
create index "fobos".i04_fk_rept013 on "fobos".rept013 (r13_usuario) 
    using btree  in idxdbs ;
create index "fobos".i05_fk_rept013 on "fobos".rept013 (r13_compania,
    r13_localidad) using btree  in idxdbs ;
create index "fobos".i06_fk_rept013 on "fobos".rept013 (r13_compania,
    r13_localidad,r13_cod_tran,r13_num_tran) using btree  in 
    idxdbs ;
alter table "fobos".rept013 add constraint primary key (r13_serial) 
    constraint "fobos".pk_rept013  ;
create index "fobos".i01_fk_rept014 on "fobos".rept014 (r14_compania) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_rept014 on "fobos".rept014 
    (r14_compania,r14_item_ant,r14_item_nue) using btree  in 
    idxdbs ;
create index "fobos".i02_fk_rept014 on "fobos".rept014 (r14_compania,
    r14_item_ant) using btree  in idxdbs ;
create index "fobos".i03_fk_rept014 on "fobos".rept014 (r14_compania,
    r14_item_nue) using btree  in idxdbs ;
create index "fobos".i04_fk_rept014 on "fobos".rept014 (r14_usuario) 
    using btree  in idxdbs ;
alter table "fobos".rept014 add constraint primary key (r14_compania,
    r14_item_ant,r14_item_nue) constraint "fobos".pk_rept014  
    ;
create index "fobos".i01_fk_rept015 on "fobos".rept015 (r15_compania) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_rept015 on "fobos".rept015 
    (r15_compania,r15_item,r15_equivalente) using btree  in idxdbs 
    ;
create index "fobos".i02_fk_rept015 on "fobos".rept015 (r15_compania,
    r15_item) using btree  in idxdbs ;
create index "fobos".i03_fk_rept015 on "fobos".rept015 (r15_compania,
    r15_equivalente) using btree  in idxdbs ;
create index "fobos".i04_fk_rept015 on "fobos".rept015 (r15_usuario) 
    using btree  in idxdbs ;
alter table "fobos".rept015 add constraint primary key (r15_compania,
    r15_item,r15_equivalente) constraint "fobos".pk_rept015  ;
    
create index "fobos".i01_fk_rept016 on "fobos".rept016 (r16_compania,
    r16_linea) using btree  in idxdbs ;
create unique index "fobos".i01_pk_rept016 on "fobos".rept016 
    (r16_compania,r16_localidad,r16_pedido) using btree  in idxdbs 
    ;
create index "fobos".i02_fk_rept016 on "fobos".rept016 (r16_compania) 
    using btree  in idxdbs ;
create index "fobos".i03_fk_rept016 on "fobos".rept016 (r16_compania,
    r16_localidad) using btree  in idxdbs ;
create index "fobos".i04_fk_rept016 on "fobos".rept016 (r16_compania,
    r16_localidad,r16_proveedor) using btree  in idxdbs ;
create index "fobos".i05_fk_rept016 on "fobos".rept016 (r16_moneda) 
    using btree  in idxdbs ;
create index "fobos".i06_fk_rept016 on "fobos".rept016 (r16_compania,
    r16_aux_cont) using btree  in idxdbs ;
create index "fobos".i07_fk_rept016 on "fobos".rept016 (r16_usuario) 
    using btree  in idxdbs ;
alter table "fobos".rept016 add constraint primary key (r16_compania,
    r16_localidad,r16_pedido) constraint "fobos".pk_rept016  ;
    
create index "fobos".i01_fk_rept018 on "fobos".rept018 (r18_compania,
    r18_localidad,r18_pedido) using btree  in idxdbs ;
create unique index "fobos".i01_pk_rept018 on "fobos".rept018 
    (r18_compania,r18_localidad,r18_pedido,r18_item) using btree 
     in idxdbs ;
create index "fobos".i02_fk_rept018 on "fobos".rept018 (r18_compania,
    r18_item) using btree  in idxdbs ;
alter table "fobos".rept018 add constraint primary key (r18_compania,
    r18_localidad,r18_pedido,r18_item) constraint "fobos".pk_rept018 
     ;
create index "fobos".i01_fk_rept022 on "fobos".rept022 (r22_compania,
    r22_localidad,r22_numprof) using btree  in idxdbs ;
create unique index "fobos".i01_pk_rept022 on "fobos".rept022 
    (r22_compania,r22_localidad,r22_numprof,r22_orden) using 
    btree  in idxdbs ;
create index "fobos".i02_fk_rept022 on "fobos".rept022 (r22_compania,
    r22_item) using btree  in idxdbs ;
create index "fobos".i03_fk_rept022 on "fobos".rept022 (r22_compania,
    r22_linea) using btree  in idxdbs ;
create index "fobos".i04_fk_rept022 on "fobos".rept022 (r22_compania,
    r22_rotacion) using btree  in idxdbs ;
alter table "fobos".rept022 add constraint primary key (r22_compania,
    r22_localidad,r22_numprof,r22_orden) constraint "fobos".pk_rept022 
     ;
create index "fobos".i01_fk_rept025 on "fobos".rept025 (r25_compania,
    r25_localidad,r25_cod_tran,r25_num_tran) using btree  in 
    idxdbs ;
create unique index "fobos".i01_pk_rept025 on "fobos".rept025 
    (r25_compania,r25_localidad,r25_numprev) using btree  in 
    idxdbs ;
alter table "fobos".rept025 add constraint primary key (r25_compania,
    r25_localidad,r25_numprev) constraint "fobos".pk_rept025  
    ;
create index "fobos".i01_fk_rept026 on "fobos".rept026 (r26_compania,
    r26_localidad,r26_numprev) using btree  in idxdbs ;
create unique index "fobos".i01_pk_rept026 on "fobos".rept026 
    (r26_compania,r26_localidad,r26_numprev,r26_dividendo) using 
    btree  in idxdbs ;
alter table "fobos".rept026 add constraint primary key (r26_compania,
    r26_localidad,r26_numprev,r26_dividendo) constraint "fobos"
    .pk_rept026  ;
create index "fobos".i01_fk_rept029 on "fobos".rept029 (r29_compania,
    r29_localidad,r29_numliq) using btree  in idxdbs ;
create unique index "fobos".i01_pk_rept029 on "fobos".rept029 
    (r29_compania,r29_localidad,r29_numliq,r29_pedido) using 
    btree  in idxdbs ;
create index "fobos".i02_fk_rept029 on "fobos".rept029 (r29_compania,
    r29_localidad,r29_pedido) using btree  in idxdbs ;
alter table "fobos".rept029 add constraint primary key (r29_compania,
    r29_localidad,r29_numliq,r29_pedido) constraint "fobos".pk_rept029 
     ;
create index "fobos".i01_fk_rept031 on "fobos".rept031 (r31_compania) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_rept031 on "fobos".rept031 
    (r31_compania,r31_ano,r31_mes,r31_bodega,r31_item) using 
    btree  in idxdbs ;
create index "fobos".i02_fk_rept031 on "fobos".rept031 (r31_compania,
    r31_bodega) using btree  in idxdbs ;
create index "fobos".i03_fk_rept031 on "fobos".rept031 (r31_compania,
    r31_item) using btree  in idxdbs ;
alter table "fobos".rept031 add constraint primary key (r31_compania,
    r31_ano,r31_mes,r31_bodega,r31_item) constraint "fobos".pk_rept031 
     ;
create index "fobos".i01_fk_rept032 on "fobos".rept032 (r32_compania) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_rept032 on "fobos".rept032 
    (r32_compania,r32_numreg) using btree  in idxdbs ;
create index "fobos".i02_fk_rept032 on "fobos".rept032 (r32_compania,
    r32_linea) using btree  in idxdbs ;
create index "fobos".i03_fk_rept032 on "fobos".rept032 (r32_compania,
    r32_rotacion) using btree  in idxdbs ;
create index "fobos".i04_fk_rept032 on "fobos".rept032 (r32_tipo_item) 
    using btree  in idxdbs ;
create index "fobos".i05_fk_rept032 on "fobos".rept032 (r32_usuario) 
    using btree  in idxdbs ;
alter table "fobos".rept032 add constraint primary key (r32_compania,
    r32_numreg) constraint "fobos".pk_rept032  ;
create index "fobos".i01_fk_rept033 on "fobos".rept033 (r33_compania) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_rept033 on "fobos".rept033 
    (r33_compania,r33_localidad,r33_num_guia) using btree  in 
    idxdbs ;
create index "fobos".i02_fk_rept033 on "fobos".rept033 (r33_compania,
    r33_localidad) using btree  in idxdbs ;
create index "fobos".i03_fk_rept033 on "fobos".rept033 (r33_cod_motivo) 
    using btree  in idxdbs ;
create index "fobos".i04_fk_rept033 on "fobos".rept033 (r33_moneda) 
    using btree  in idxdbs ;
create index "fobos".i05_fk_rept033 on "fobos".rept033 (r33_usuario) 
    using btree  in idxdbs ;
create index "fobos".i06_fk_rept033 on "fobos".rept033 (r33_compania,
    r33_localidad,r33_tipcomp_ori,r33_numcomp_ori) using btree 
     in idxdbs ;
alter table "fobos".rept033 add constraint primary key (r33_compania,
    r33_localidad,r33_num_guia) constraint "fobos".pk_rept033 
     ;
create index "fobos".i01_fk_rept050 on "fobos".rept050 (r50_compania) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_rept050 on "fobos".rept050 
    (r50_compania,r50_item) using btree  in idxdbs ;
create index "fobos".i02_fk_rept050 on "fobos".rept050 (r50_compania,
    r50_indice_ant) using btree  in idxdbs ;
create index "fobos".i03_fk_rept050 on "fobos".rept050 (r50_compania,
    r50_indice_act) using btree  in idxdbs ;
create index "fobos".i04_fk_rept050 on "fobos".rept050 (r50_usuario) 
    using btree  in idxdbs ;
alter table "fobos".rept050 add constraint primary key (r50_compania,
    r50_item) constraint "fobos".pk_rept050  ;
create index "fobos".i01_fk_rept051 on "fobos".rept051 (r51_compania) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_rept051 on "fobos".rept051 
    (r51_serial) using btree  in idxdbs ;
create index "fobos".i02_fk_rept051 on "fobos".rept051 (r51_compania,
    r51_bodega) using btree  in idxdbs ;
create index "fobos".i03_fk_rept051 on "fobos".rept051 (r51_usuario) 
    using btree  in idxdbs ;
alter table "fobos".rept051 add constraint primary key (r51_serial) 
    constraint "fobos".pk_rept051  ;
create index "fobos".i01_fk_rept052 on "fobos".rept052 (r52_compania) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_rept052 on "fobos".rept052 
    (r52_compania,r52_bodega,r52_num_seccion,r52_num_linea) using 
    btree  in idxdbs ;
create index "fobos".i02_fk_rept052 on "fobos".rept052 (r52_compania,
    r52_bodega) using btree  in idxdbs ;
create index "fobos".i03_fk_rept052 on "fobos".rept052 (r52_compania,
    r52_item) using btree  in idxdbs ;
create index "fobos".i04_fk_rept052 on "fobos".rept052 (r52_compania,
    r52_linea) using btree  in idxdbs ;
alter table "fobos".rept052 add constraint primary key (r52_compania,
    r52_bodega,r52_num_seccion,r52_num_linea) constraint "fobos"
    .pk_rept052  ;
create index "fobos".i01_fk_rept060 on "fobos".rept060 (r60_compania) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_rept060 on "fobos".rept060 
    (r60_compania,r60_fecha,r60_bodega,r60_vendedor,r60_moneda,
    r60_linea,r60_rotacion) using btree  in idxdbs ;
create index "fobos".i02_fk_rept060 on "fobos".rept060 (r60_compania,
    r60_bodega) using btree  in idxdbs ;
create index "fobos".i03_fk_rept060 on "fobos".rept060 (r60_compania,
    r60_vendedor) using btree  in idxdbs ;
create index "fobos".i04_fk_rept060 on "fobos".rept060 (r60_moneda) 
    using btree  in idxdbs ;
create index "fobos".i05_fk_rept060 on "fobos".rept060 (r60_compania,
    r60_linea) using btree  in idxdbs ;
create index "fobos".i06_fk_rept060 on "fobos".rept060 (r60_compania,
    r60_rotacion) using btree  in idxdbs ;
alter table "fobos".rept060 add constraint primary key (r60_compania,
    r60_fecha,r60_bodega,r60_vendedor,r60_moneda,r60_linea,r60_rotacion) 
    constraint "fobos".pk_rept060  ;
create index "fobos".i01_fk_rept061 on "fobos".rept061 (r61_compania) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_rept061 on "fobos".rept061 
    (r61_compania,r61_ano,r61_mes,r61_bodega,r61_linea,r61_rotacion) 
    using btree  in idxdbs ;
create index "fobos".i02_fk_rept061 on "fobos".rept061 (r61_compania,
    r61_bodega) using btree  in idxdbs ;
create index "fobos".i03_fk_rept061 on "fobos".rept061 (r61_compania,
    r61_linea) using btree  in idxdbs ;
create index "fobos".i04_fk_rept061 on "fobos".rept061 (r61_compania,
    r61_rotacion) using btree  in idxdbs ;
alter table "fobos".rept061 add constraint primary key (r61_compania,
    r61_ano,r61_mes,r61_bodega,r61_linea,r61_rotacion) constraint 
    "fobos".pk_rept061  ;
create index "fobos".i01_fk_rept062 on "fobos".rept062 (r62_compania) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_rept062 on "fobos".rept062 
    (r62_compania,r62_ano,r62_mes,r62_bodega,r62_linea) using 
    btree  in idxdbs ;
create index "fobos".i02_fk_rept062 on "fobos".rept062 (r62_compania,
    r62_bodega) using btree  in idxdbs ;
create index "fobos".i03_fk_rept062 on "fobos".rept062 (r62_compania,
    r62_linea) using btree  in idxdbs ;
create index "fobos".i04_fk_rept062 on "fobos".rept062 (r62_tipo_tran) 
    using btree  in idxdbs ;
alter table "fobos".rept062 add constraint primary key (r62_compania,
    r62_ano,r62_mes,r62_bodega,r62_linea) constraint "fobos".pk_rept062 
     ;
create index "fobos".i01_fk_talt000 on "fobos".talt000 (t00_cia_vehic) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_talt000 on "fobos".talt000 
    (t00_compania) using btree  in idxdbs ;
create index "fobos".i02_fk_talt000 on "fobos".talt000 (t00_codcli_int) 
    using btree  in idxdbs ;
alter table "fobos".talt000 add constraint primary key (t00_compania) 
    constraint "fobos".pk_talt000  ;
create index "fobos".i01_fk_veht001 on "fobos".veht001 (v01_compania) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_veht001 on "fobos".veht001 
    (v01_compania,v01_vendedor) using btree  in idxdbs ;
create index "fobos".i02_fk_veht001 on "fobos".veht001 (v01_compania,
    v01_codrol) using btree  in idxdbs ;
create index "fobos".i03_fk_veht001 on "fobos".veht001 (v01_usuario) 
    using btree  in idxdbs ;
alter table "fobos".veht001 add constraint primary key (v01_compania,
    v01_vendedor) constraint "fobos".pk_veht001  ;
create index "fobos".i01_fk_veht002 on "fobos".veht002 (v02_compania) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_veht002 on "fobos".veht002 
    (v02_compania,v02_bodega) using btree  in idxdbs ;
create index "fobos".i02_fk_veht002 on "fobos".veht002 (v02_compania,
    v02_localidad) using btree  in idxdbs ;
create index "fobos".i03_fk_veht002 on "fobos".veht002 (v02_usuario) 
    using btree  in idxdbs ;
alter table "fobos".veht002 add constraint primary key (v02_compania,
    v02_bodega) constraint "fobos".pk_veht002  ;
create index "fobos".i01_fk_veht004 on "fobos".veht004 (v04_compania) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_veht004 on "fobos".veht004 
    (v04_compania,v04_tipo_veh) using btree  in idxdbs ;
create index "fobos".i02_fk_veht004 on "fobos".veht004 (v04_usuario) 
    using btree  in idxdbs ;
alter table "fobos".veht004 add constraint primary key (v04_compania,
    v04_tipo_veh) constraint "fobos".pk_veht004  ;
create index "fobos".i01_fk_veht005 on "fobos".veht005 (v05_compania) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_veht005 on "fobos".veht005 
    (v05_compania,v05_cod_color) using btree  in idxdbs ;
create index "fobos".i02_fk_veht005 on "fobos".veht005 (v05_usuario) 
    using btree  in idxdbs ;
alter table "fobos".veht005 add constraint primary key (v05_compania,
    v05_cod_color) constraint "fobos".pk_veht005  ;
create index "fobos".i01_fk_veht007 on "fobos".veht007 (v07_compania,
    v07_codigo_plan) using btree  in idxdbs ;
create unique index "fobos".i01_pk_veht007 on "fobos".veht007 
    (v07_compania,v07_codigo_plan,v07_num_meses) using btree 
     in idxdbs ;
alter table "fobos".veht007 add constraint primary key (v07_compania,
    v07_codigo_plan,v07_num_meses) constraint "fobos".pk_veht007 
     ;
create index "fobos".i01_fk_veht020 on "fobos".veht020 (v20_compania) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_veht020 on "fobos".veht020 
    (v20_compania,v20_modelo) using btree  in idxdbs ;
create index "fobos".i02_fk_veht020 on "fobos".veht020 (v20_compania,
    v20_tipo_veh) using btree  in idxdbs ;
create index "fobos".i03_fk_veht020 on "fobos".veht020 (v20_compania,
    v20_linea) using btree  in idxdbs ;
create index "fobos".i04_fk_veht020 on "fobos".veht020 (v20_moneda) 
    using btree  in idxdbs ;
create index "fobos".i05_fk_veht020 on "fobos".veht020 (v20_mon_prov) 
    using btree  in idxdbs ;
create index "fobos".i06_fk_veht020 on "fobos".veht020 (v20_usuario) 
    using btree  in idxdbs ;
alter table "fobos".veht020 add constraint primary key (v20_compania,
    v20_modelo) constraint "fobos".pk_veht020  ;
create index "fobos".i01_fk_veht021 on "fobos".veht021 (v21_compania,
    v21_modelo) using btree  in idxdbs ;
create unique index "fobos".i01_pk_veht021 on "fobos".veht021 
    (v21_compania,v21_modelo,v21_secuencia) using btree  in idxdbs 
    ;
create index "fobos".i02_fk_veht021 on "fobos".veht021 (v21_usuario) 
    using btree  in idxdbs ;
alter table "fobos".veht021 add constraint primary key (v21_compania,
    v21_modelo,v21_secuencia) constraint "fobos".pk_veht021  ;
    
create index "fobos".i01_fk_veht026 on "fobos".veht026 (v26_compania,
    v26_localidad,v26_cod_tran,v26_num_tran) using btree  in 
    idxdbs ;
create unique index "fobos".i01_pk_veht026 on "fobos".veht026 
    (v26_compania,v26_localidad,v26_numprev) using btree  in 
    idxdbs ;
create index "fobos".i02_fk_veht026 on "fobos".veht026 (v26_compania) 
    using btree  in idxdbs ;
create index "fobos".i03_fk_veht026 on "fobos".veht026 (v26_compania,
    v26_localidad) using btree  in idxdbs ;
create index "fobos".i04_fk_veht026 on "fobos".veht026 (v26_compania,
    v26_localidad,v26_codcli) using btree  in idxdbs ;
create index "fobos".i05_fk_veht026 on "fobos".veht026 (v26_compania,
    v26_vendedor) using btree  in idxdbs ;
create index "fobos".i06_fk_veht026 on "fobos".veht026 (v26_moneda) 
    using btree  in idxdbs ;
create index "fobos".i07_fk_veht026 on "fobos".veht026 (v26_compania,
    v26_codigo_plan) using btree  in idxdbs ;
create index "fobos".i08_fk_veht026 on "fobos".veht026 (v26_usuario) 
    using btree  in idxdbs ;
alter table "fobos".veht026 add constraint primary key (v26_compania,
    v26_localidad,v26_numprev) constraint "fobos".pk_veht026  
    ;
create index "fobos".i01_fk_veht027 on "fobos".veht027 (v27_compania,
    v27_localidad,v27_numprev) using btree  in idxdbs ;
create unique index "fobos".i01_pk_veht027 on "fobos".veht027 
    (v27_compania,v27_localidad,v27_numprev,v27_codigo_veh) using 
    btree  in idxdbs ;
create index "fobos".i02_fk_veht027 on "fobos".veht027 (v27_compania,
    v27_localidad,v27_codigo_veh) using btree  in idxdbs ;
alter table "fobos".veht027 add constraint primary key (v27_compania,
    v27_localidad,v27_numprev,v27_codigo_veh) constraint "fobos"
    .pk_veht027  ;
create index "fobos".i01_fk_veht028 on "fobos".veht028 (v28_compania,
    v28_localidad,v28_numprev) using btree  in idxdbs ;
create unique index "fobos".i01_pk_veht028 on "fobos".veht028 
    (v28_compania,v28_localidad,v28_numprev,v28_dividendo,v28_tipo) 
    using btree  in idxdbs ;
alter table "fobos".veht028 add constraint primary key (v28_compania,
    v28_localidad,v28_numprev,v28_dividendo,v28_tipo) constraint 
    "fobos".pk_veht028  ;
create index "fobos".i01_fk_veht029 on "fobos".veht029 (v29_compania,
    v29_localidad,v29_numprev) using btree  in idxdbs ;
create unique index "fobos".i01_pk_veht029 on "fobos".veht029 
    (v29_compania,v29_localidad,v29_numprev,v29_tipo_doc,v29_numdoc) 
    using btree  in idxdbs ;
create index "fobos".i02_fk_veht029 on "fobos".veht029 (v29_tipo_doc) 
    using btree  in idxdbs ;
alter table "fobos".veht029 add constraint primary key (v29_compania,
    v29_localidad,v29_numprev,v29_tipo_doc,v29_numdoc) constraint 
    "fobos".pk_veht029  ;
create index "fobos".i01_fk_veht030 on "fobos".veht030 (v30_compania,
    v30_localidad,v30_tipo_dev,v30_num_dev) using btree  in idxdbs 
    ;
create unique index "fobos".i01_pk_veht030 on "fobos".veht030 
    (v30_compania,v30_localidad,v30_cod_tran,v30_num_tran) using 
    btree  in idxdbs ;
create index "fobos".i02_fk_veht030 on "fobos".veht030 (v30_compania) 
    using btree  in idxdbs ;
create index "fobos".i03_fk_veht030 on "fobos".veht030 (v30_compania,
    v30_localidad) using btree  in idxdbs ;
create index "fobos".i04_fk_veht030 on "fobos".veht030 (v30_cod_subtipo) 
    using btree  in idxdbs ;
create index "fobos".i05_fk_veht030 on "fobos".veht030 (v30_compania,
    v30_localidad,v30_codcli) using btree  in idxdbs ;
create index "fobos".i06_fk_veht030 on "fobos".veht030 (v30_compania,
    v30_vendedor) using btree  in idxdbs ;
create index "fobos".i07_fk_veht030 on "fobos".veht030 (v30_compania,
    v30_localidad,v30_oc_interna) using btree  in idxdbs ;
create index "fobos".i08_fk_veht030 on "fobos".veht030 (v30_compania,
    v30_bodega_ori) using btree  in idxdbs ;
create index "fobos".i09_fk_veht030 on "fobos".veht030 (v30_compania,
    v30_bodega_dest) using btree  in idxdbs ;
create index "fobos".i10_fk_veht030 on "fobos".veht030 (v30_moneda) 
    using btree  in idxdbs ;
create index "fobos".i11_fk_veht030 on "fobos".veht030 (v30_compania,
    v30_localidad,v30_numliq) using btree  in idxdbs ;
create index "fobos".i12_fk_veht030 on "fobos".veht030 (v30_usuario) 
    using btree  in idxdbs ;
create index "fobos".i13_fk_veht030 on "fobos".veht030 (v30_cod_tran) 
    using btree  in idxdbs ;
alter table "fobos".veht030 add constraint primary key (v30_compania,
    v30_localidad,v30_cod_tran,v30_num_tran) constraint "fobos"
    .pk_veht030  ;
create index "fobos".i01_fk_veht032 on "fobos".veht032 (v32_compania) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_veht032 on "fobos".veht032 
    (v32_compania,v32_linea) using btree  in idxdbs ;
create index "fobos".i02_fk_veht032 on "fobos".veht032 (v32_usuario) 
    using btree  in idxdbs ;
alter table "fobos".veht032 add constraint primary key (v32_compania,
    v32_linea) constraint "fobos".pk_veht032  ;
create index "fobos".i01_fk_veht034 on "fobos".veht034 (v34_compania) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_veht034 on "fobos".veht034 
    (v34_compania,v34_localidad,v34_pedido) using btree  in idxdbs 
    ;
create index "fobos".i02_fk_veht034 on "fobos".veht034 (v34_compania,
    v34_localidad) using btree  in idxdbs ;
create index "fobos".i03_fk_veht034 on "fobos".veht034 (v34_compania,
    v34_localidad,v34_proveedor) using btree  in idxdbs ;
create index "fobos".i04_fk_veht034 on "fobos".veht034 (v34_moneda) 
    using btree  in idxdbs ;
create index "fobos".i05_fk_veht034 on "fobos".veht034 (v34_compania,
    v34_aux_cont) using btree  in idxdbs ;
create index "fobos".i06_fk_veht034 on "fobos".veht034 (v34_usuario) 
    using btree  in idxdbs ;
alter table "fobos".veht034 add constraint primary key (v34_compania,
    v34_localidad,v34_pedido) constraint "fobos".pk_veht034  ;
    
create index "fobos".i01_fk_veht035 on "fobos".veht035 (v35_compania,
    v35_localidad,v35_pedido) using btree  in idxdbs ;
create unique index "fobos".i01_pk_veht035 on "fobos".veht035 
    (v35_compania,v35_localidad,v35_pedido,v35_secuencia) using 
    btree  in idxdbs ;
create index "fobos".i02_fk_veht035 on "fobos".veht035 (v35_compania,
    v35_modelo) using btree  in idxdbs ;
create index "fobos".i03_fk_veht035 on "fobos".veht035 (v35_compania,
    v35_cod_color) using btree  in idxdbs ;
create index "fobos".i04_fk_veht035 on "fobos".veht035 (v35_compania,
    v35_localidad,v35_codigo_veh) using btree  in idxdbs ;
create index "fobos".i05_fk_veht035 on "fobos".veht035 (v35_compania,
    v35_bodega_alm) using btree  in idxdbs ;
create index "fobos".i06_fk_veht035 on "fobos".veht035 (v35_compania,
    v35_bodega_liq) using btree  in idxdbs ;
alter table "fobos".veht035 add constraint primary key (v35_compania,
    v35_localidad,v35_pedido,v35_secuencia) constraint "fobos"
    .pk_veht035  ;
create index "fobos".i01_fk_veht036 on "fobos".veht036 (v36_compania) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_veht036 on "fobos".veht036 
    (v36_compania,v36_localidad,v36_numliq) using btree  in idxdbs 
    ;
create index "fobos".i02_fk_veht036 on "fobos".veht036 (v36_compania,
    v36_localidad) using btree  in idxdbs ;
create index "fobos".i03_fk_veht036 on "fobos".veht036 (v36_compania,
    v36_localidad,v36_pedido) using btree  in idxdbs ;
create index "fobos".i04_fk_veht036 on "fobos".veht036 (v36_moneda) 
    using btree  in idxdbs ;
create index "fobos".i05_fk_veht036 on "fobos".veht036 (v36_usuario) 
    using btree  in idxdbs ;
create index "fobos".i06_fk_veht036 on "fobos".veht036 (v36_compania,
    v36_bodega) using btree  in idxdbs ;
alter table "fobos".veht036 add constraint primary key (v36_compania,
    v36_localidad,v36_numliq) constraint "fobos".pk_veht036  ;
    
create index "fobos".i01_fk_veht037 on "fobos".veht037 (v37_compania,
    v37_localidad,v37_numliq) using btree  in idxdbs ;
create unique index "fobos".i01_pk_veht037 on "fobos".veht037 
    (v37_compania,v37_localidad,v37_numliq,v37_serial) using 
    btree  in idxdbs ;
create index "fobos".i02_fk_veht037 on "fobos".veht037 (v37_codrubro) 
    using btree  in idxdbs ;
create index "fobos".i03_fk_veht037 on "fobos".veht037 (v37_moneda) 
    using btree  in idxdbs ;
alter table "fobos".veht037 add constraint primary key (v37_compania,
    v37_localidad,v37_numliq,v37_serial) constraint "fobos".pk_veht037 
     ;
create index "fobos".i01_fk_veht039 on "fobos".veht039 (v39_compania) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_veht039 on "fobos".veht039 
    (v39_compania,v39_bodega,v39_modelo,v39_ano,v39_mes,v39_moneda) 
    using btree  in idxdbs ;
create index "fobos".i02_fk_veht039 on "fobos".veht039 (v39_compania,
    v39_bodega) using btree  in idxdbs ;
create index "fobos".i03_fk_veht039 on "fobos".veht039 (v39_compania,
    v39_modelo) using btree  in idxdbs ;
create index "fobos".i04_fk_veht039 on "fobos".veht039 (v39_moneda) 
    using btree  in idxdbs ;
alter table "fobos".veht039 add constraint primary key (v39_compania,
    v39_bodega,v39_modelo,v39_ano,v39_mes,v39_moneda) constraint 
    "fobos".pk_veht039  ;
create index "fobos".i01_fk_veht040 on "fobos".veht040 (v40_compania) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_veht040 on "fobos".veht040 
    (v40_compania,v40_bodega,v40_modelo,v40_linea,v40_vendedor,
    v40_ano,v40_mes,v40_moneda) using btree  in idxdbs ;
create index "fobos".i02_fk_veht040 on "fobos".veht040 (v40_compania,
    v40_bodega) using btree  in idxdbs ;
create index "fobos".i03_fk_veht040 on "fobos".veht040 (v40_compania,
    v40_modelo) using btree  in idxdbs ;
create index "fobos".i04_fk_veht040 on "fobos".veht040 (v40_compania,
    v40_linea) using btree  in idxdbs ;
create index "fobos".i05_fk_veht040 on "fobos".veht040 (v40_compania,
    v40_vendedor) using btree  in idxdbs ;
create index "fobos".i06_fk_veht040 on "fobos".veht040 (v40_moneda) 
    using btree  in idxdbs ;
alter table "fobos".veht040 add constraint primary key (v40_compania,
    v40_bodega,v40_modelo,v40_linea,v40_vendedor,v40_ano,v40_mes,
    v40_moneda) constraint "fobos".pk_veht040  ;
create unique index "fobos".i01_pk_ordt000 on "fobos".ordt000 
    (c00_compania) using btree  in idxdbs ;
alter table "fobos".ordt000 add constraint primary key (c00_compania) 
    constraint "fobos".pk_ordt000  ;
create index "fobos".i01_fk_ordt010 on "fobos".ordt010 (c10_compania) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_ordt010 on "fobos".ordt010 
    (c10_compania,c10_localidad,c10_numero_oc) using btree  in 
    idxdbs ;
create index "fobos".i02_fk_ordt010 on "fobos".ordt010 (c10_compania,
    c10_localidad) using btree  in idxdbs ;
create index "fobos".i03_fk_ordt010 on "fobos".ordt010 (c10_tipo_orden) 
    using btree  in idxdbs ;
create index "fobos".i04_fk_ordt010 on "fobos".ordt010 (c10_compania,
    c10_cod_depto) using btree  in idxdbs ;
create index "fobos".i05_fk_ordt010 on "fobos".ordt010 (c10_compania,
    c10_localidad,c10_codprov) using btree  in idxdbs ;
create index "fobos".i06_fk_ordt010 on "fobos".ordt010 (c10_usua_aprob) 
    using btree  in idxdbs ;
create index "fobos".i07_fk_ordt010 on "fobos".ordt010 (c10_compania,
    c10_localidad,c10_ord_trabajo) using btree  in idxdbs ;
create index "fobos".i08_fk_ordt010 on "fobos".ordt010 (c10_moneda) 
    using btree  in idxdbs ;
create index "fobos".i09_fk_ordt010 on "fobos".ordt010 (c10_usuario) 
    using btree  in idxdbs ;
create index "fobos".i10_fk_ordt010 on "fobos".ordt010 (c10_compania,
    c10_cod_sust_sri) using btree  in idxdbs ;
create index "fobos".i11_fk_ordt010 on "fobos".ordt010 (c10_compania,
    c10_cod_ice,c10_porc_ice,c10_cod_ice_imp,c10_tipo_orden) 
    using btree  in idxdbs ;
alter table "fobos".ordt010 add constraint primary key (c10_compania,
    c10_localidad,c10_numero_oc) constraint "fobos".pk_ordt010 
     ;
create index "fobos".i01_fk_ordt012 on "fobos".ordt012 (c12_compania,
    c12_localidad,c12_numero_oc) using btree  in idxdbs ;
create unique index "fobos".i01_pk_ordt012 on "fobos".ordt012 
    (c12_compania,c12_localidad,c12_numero_oc,c12_dividendo) 
    using btree  in idxdbs ;
alter table "fobos".ordt012 add constraint primary key (c12_compania,
    c12_localidad,c12_numero_oc,c12_dividendo) constraint "fobos"
    .pk_ordt012  ;
create index "fobos".i01_fk_ordt013 on "fobos".ordt013 (c13_compania,
    c13_localidad,c13_numero_oc) using btree  in idxdbs ;
create unique index "fobos".i01_pk_ordt013 on "fobos".ordt013 
    (c13_compania,c13_localidad,c13_numero_oc,c13_num_recep) 
    using btree  in idxdbs ;
create index "fobos".i02_fk_ordt013 on "fobos".ordt013 (c13_compania,
    c13_bodega) using btree  in idxdbs ;
create index "fobos".i03_fk_ordt013 on "fobos".ordt013 (c13_usuario) 
    using btree  in idxdbs ;
alter table "fobos".ordt013 add constraint primary key (c13_compania,
    c13_localidad,c13_numero_oc,c13_num_recep) constraint "fobos"
    .pk_ordt013  ;
create index "fobos".i01_fk_veht000 on "fobos".veht000 (v00_compania,
    v00_bodega_fact) using btree  in idxdbs ;
create unique index "fobos".i01_pk_veht000 on "fobos".veht000 
    (v00_compania) using btree  in idxdbs ;
create index "fobos".i02_fk_veht000 on "fobos".veht000 (v00_cia_taller) 
    using btree  in idxdbs ;
alter table "fobos".veht000 add constraint primary key (v00_compania) 
    constraint "fobos".pk_veht000  ;
create index "fobos".i01_fk_veht006 on "fobos".veht006 (v06_compania) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_veht006 on "fobos".veht006 
    (v06_compania,v06_codigo_plan) using btree  in idxdbs ;
create index "fobos".i02_fk_veht006 on "fobos".veht006 (v06_usuario) 
    using btree  in idxdbs ;
alter table "fobos".veht006 add constraint primary key (v06_compania,
    v06_codigo_plan) constraint "fobos".pk_veht006  ;
create index "fobos".i01_fk_cxct000 on "fobos".cxct000 (z00_compania,
    z00_aux_clte_mb) using btree  in idxdbs ;
create unique index "fobos".i01_pk_cxct000 on "fobos".cxct000 
    (z00_compania) using btree  in idxdbs ;
create index "fobos".i02_fk_cxct000 on "fobos".cxct000 (z00_compania,
    z00_aux_clte_ma) using btree  in idxdbs ;
create index "fobos".i03_fk_cxct000 on "fobos".cxct000 (z00_compania,
    z00_aux_ant_mb) using btree  in idxdbs ;
create index "fobos".i04_fk_cxct000 on "fobos".cxct000 (z00_compania,
    z00_aux_ant_ma) using btree  in idxdbs ;
alter table "fobos".cxct000 add constraint primary key (z00_compania) 
    constraint "fobos".pk_cxct000  ;
create index "fobos".i01_fk_cxct002 on "fobos".cxct002 (z02_compania) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_cxct002 on "fobos".cxct002 
    (z02_compania,z02_localidad,z02_codcli) using btree  in idxdbs 
    ;
create index "fobos".i02_fk_cxct002 on "fobos".cxct002 (z02_compania,
    z02_localidad) using btree  in idxdbs ;
create index "fobos".i03_fk_cxct002 on "fobos".cxct002 (z02_codcli) 
    using btree  in idxdbs ;
create index "fobos".i04_fk_cxct002 on "fobos".cxct002 (z02_compania,
    z02_zona_venta) using btree  in idxdbs ;
create index "fobos".i05_fk_cxct002 on "fobos".cxct002 (z02_zona_cobro) 
    using btree  in idxdbs ;
create index "fobos".i06_fk_cxct002 on "fobos".cxct002 (z02_compania,
    z02_aux_clte_mb) using btree  in idxdbs ;
create index "fobos".i07_fk_cxct002 on "fobos".cxct002 (z02_compania,
    z02_aux_clte_ma) using btree  in idxdbs ;
create index "fobos".i08_fk_cxct002 on "fobos".cxct002 (z02_compania,
    z02_aux_ant_mb) using btree  in idxdbs ;
create index "fobos".i09_fk_cxct002 on "fobos".cxct002 (z02_compania,
    z02_aux_ant_ma) using btree  in idxdbs ;
create index "fobos".i10_fk_cxct002 on "fobos".cxct002 (z02_usuario) 
    using btree  in idxdbs ;
alter table "fobos".cxct002 add constraint primary key (z02_compania,
    z02_localidad,z02_codcli) constraint "fobos".pk_cxct002  ;
    
create index "fobos".i01_fk_cxct003 on "fobos".cxct003 (z03_compania,
    z03_localidad,z03_codcli) using btree  in idxdbs ;
create unique index "fobos".i01_pk_cxct003 on "fobos".cxct003 
    (z03_compania,z03_localidad,z03_areaneg,z03_codcli) using 
    btree  in idxdbs ;
create index "fobos".i02_fk_cxct003 on "fobos".cxct003 (z03_compania,
    z03_areaneg) using btree  in idxdbs ;
create index "fobos".i03_fk_cxct003 on "fobos".cxct003 (z03_usuario) 
    using btree  in idxdbs ;
alter table "fobos".cxct003 add constraint primary key (z03_compania,
    z03_localidad,z03_areaneg,z03_codcli) constraint "fobos".pk_cxct003 
     ;
create index "fobos".i01_fk_cxct004 on "fobos".cxct004 (z04_usuario) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_cxct004 on "fobos".cxct004 
    (z04_tipo_doc) using btree  in idxdbs ;
alter table "fobos".cxct004 add constraint primary key (z04_tipo_doc) 
    constraint "fobos".pk_cxct004  ;
create index "fobos".i01_fk_cxct005 on "fobos".cxct005 (z05_compania) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_cxct005 on "fobos".cxct005 
    (z05_compania,z05_codigo) using btree  in idxdbs ;
create index "fobos".i02_fk_cxct005 on "fobos".cxct005 (z05_compania,
    z05_codrol) using btree  in idxdbs ;
create index "fobos".i03_fk_cxct005 on "fobos".cxct005 (z05_usuario) 
    using btree  in idxdbs ;
alter table "fobos".cxct005 add constraint primary key (z05_compania,
    z05_codigo) constraint "fobos".pk_cxct005  ;
create index "fobos".i01_fk_cxct006 on "fobos".cxct006 (z06_usuario) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_cxct006 on "fobos".cxct006 
    (z06_zona_cobro) using btree  in idxdbs ;
alter table "fobos".cxct006 add constraint primary key (z06_zona_cobro) 
    constraint "fobos".pk_cxct006  ;
create index "fobos".i01_fk_cxct007 on "fobos".cxct007 (z07_compania) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_cxct007 on "fobos".cxct007 
    (z07_serial) using btree  in idxdbs ;
alter table "fobos".cxct007 add constraint primary key (z07_serial) 
    constraint "fobos".pk_cxct007  ;
create index "fobos".i01_fk_cxct026 on "fobos".cxct026 (z26_compania,
    z26_localidad,z26_codcli,z26_tipo_doc,z26_num_doc,z26_dividendo) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_cxct026 on "fobos".cxct026 
    (z26_compania,z26_localidad,z26_codcli,z26_banco,z26_num_cta,
    z26_num_cheque) using btree  in idxdbs ;
create index "fobos".i02_fk_cxct026 on "fobos".cxct026 (z26_compania,
    z26_localidad,z26_codcli) using btree  in idxdbs ;
create index "fobos".i03_fk_cxct026 on "fobos".cxct026 (z26_banco) 
    using btree  in idxdbs ;
create index "fobos".i04_fk_cxct026 on "fobos".cxct026 (z26_compania,
    z26_areaneg) using btree  in idxdbs ;
create index "fobos".i05_fk_cxct026 on "fobos".cxct026 (z26_usuario) 
    using btree  in idxdbs ;
alter table "fobos".cxct026 add constraint primary key (z26_compania,
    z26_localidad,z26_codcli,z26_banco,z26_num_cta,z26_num_cheque) 
    constraint "fobos".pk_cxct026  ;
create index "fobos".i01_fk_cxct030 on "fobos".cxct030 (z30_compania,
    z30_localidad,z30_codcli) using btree  in idxdbs ;
create unique index "fobos".i01_pk_cxct030 on "fobos".cxct030 
    (z30_compania,z30_localidad,z30_areaneg,z30_codcli,z30_moneda) 
    using btree  in idxdbs ;
create index "fobos".i02_fk_cxct030 on "fobos".cxct030 (z30_compania,
    z30_areaneg) using btree  in idxdbs ;
create index "fobos".i03_fk_cxct030 on "fobos".cxct030 (z30_moneda) 
    using btree  in idxdbs ;
alter table "fobos".cxct030 add constraint primary key (z30_compania,
    z30_localidad,z30_areaneg,z30_codcli,z30_moneda) constraint 
    "fobos".pk_cxct030  ;
create index "fobos".i01_fk_cxct031 on "fobos".cxct031 (z31_compania) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_cxct031 on "fobos".cxct031 
    (z31_compania,z31_ano,z31_mes,z31_localidad,z31_areaneg,z31_cartera,
    z31_tipo_clte,z31_linea,z31_moneda) using btree  in idxdbs 
    ;
create index "fobos".i02_fk_cxct031 on "fobos".cxct031 (z31_compania,
    z31_localidad) using btree  in idxdbs ;
create index "fobos".i03_fk_cxct031 on "fobos".cxct031 (z31_compania,
    z31_areaneg) using btree  in idxdbs ;
create index "fobos".i04_fk_cxct031 on "fobos".cxct031 (z31_compania,
    z31_linea) using btree  in idxdbs ;
create index "fobos".i05_fk_cxct031 on "fobos".cxct031 (z31_moneda) 
    using btree  in idxdbs ;
alter table "fobos".cxct031 add constraint primary key (z31_compania,
    z31_ano,z31_mes,z31_localidad,z31_areaneg,z31_cartera,z31_tipo_clte,
    z31_linea,z31_moneda) constraint "fobos".pk_cxct031  ;
create index "fobos".i01_fk_cxct032 on "fobos".cxct032 (z32_compania) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_cxct032 on "fobos".cxct032 
    (z32_compania,z32_recaudador,z32_ano,z32_mes) using btree 
     in idxdbs ;
create index "fobos".i02_fk_cxct032 on "fobos".cxct032 (z32_compania,
    z32_recaudador) using btree  in idxdbs ;
alter table "fobos".cxct032 add constraint primary key (z32_compania,
    z32_recaudador,z32_ano,z32_mes) constraint "fobos".pk_cxct032 
     ;
create index "fobos".i01_fk_cxpt000 on "fobos".cxpt000 (p00_compania,
    p00_aux_prov_mb) using btree  in idxdbs ;
create unique index "fobos".i01_pk_cxpt000 on "fobos".cxpt000 
    (p00_compania) using btree  in idxdbs ;
create index "fobos".i02_fk_cxpt000 on "fobos".cxpt000 (p00_compania,
    p00_aux_prov_ma) using btree  in idxdbs ;
create index "fobos".i03_fk_cxpt000 on "fobos".cxpt000 (p00_compania,
    p00_aux_ant_mb) using btree  in idxdbs ;
create index "fobos".i04_fk_cxpt000 on "fobos".cxpt000 (p00_compania,
    p00_aux_ant_ma) using btree  in idxdbs ;
alter table "fobos".cxpt000 add constraint primary key (p00_compania) 
    constraint "fobos".pk_cxpt000  ;
create index "fobos".i01_fk_cxpt002 on "fobos".cxpt002 (p02_compania) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_cxpt002 on "fobos".cxpt002 
    (p02_compania,p02_localidad,p02_codprov) using btree  in 
    idxdbs ;
create index "fobos".i02_fk_cxpt002 on "fobos".cxpt002 (p02_compania,
    p02_localidad) using btree  in idxdbs ;
create index "fobos".i03_fk_cxpt002 on "fobos".cxpt002 (p02_codprov) 
    using btree  in idxdbs ;
create index "fobos".i04_fk_cxpt002 on "fobos".cxpt002 (p02_compania,
    p02_aux_prov_mb) using btree  in idxdbs ;
create index "fobos".i05_fk_cxpt002 on "fobos".cxpt002 (p02_compania,
    p02_aux_prov_ma) using btree  in idxdbs ;
create index "fobos".i06_fk_cxpt002 on "fobos".cxpt002 (p02_compania,
    p02_aux_ant_mb) using btree  in idxdbs ;
create index "fobos".i07_fk_cxpt002 on "fobos".cxpt002 (p02_compania,
    p02_aux_ant_ma) using btree  in idxdbs ;
create index "fobos".i08_fk_cxpt002 on "fobos".cxpt002 (p02_usuario) 
    using btree  in idxdbs ;
create index "fobos".i09_fk_cxpt002 on "fobos".cxpt002 (p02_banco_prov) 
    using btree  in idxdbs ;
create index "fobos".i10_fk_cxpt002 on "fobos".cxpt002 (p02_compania,
    p02_cod_bco_tra,p02_banco_prov) using btree  in idxdbs ;
alter table "fobos".cxpt002 add constraint primary key (p02_compania,
    p02_localidad,p02_codprov) constraint "fobos".pk_cxpt002  
    ;
create index "fobos".i01_fk_cxpt003 on "fobos".cxpt003 (p03_compania,
    p03_localidad,p03_codprov) using btree  in idxdbs ;
create unique index "fobos".i01_pk_cxpt003 on "fobos".cxpt003 
    (p03_compania,p03_localidad,p03_areaneg,p03_codprov) using 
    btree  in idxdbs ;
create index "fobos".i02_fk_cxpt003 on "fobos".cxpt003 (p03_compania,
    p03_areaneg) using btree  in idxdbs ;
create index "fobos".i03_fk_cxpt003 on "fobos".cxpt003 (p03_usuario) 
    using btree  in idxdbs ;
alter table "fobos".cxpt003 add constraint primary key (p03_compania,
    p03_localidad,p03_areaneg,p03_codprov) constraint "fobos".pk_cxpt003 
     ;
create index "fobos".i01_fk_cxpt004 on "fobos".cxpt004 (p04_usuario) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_cxpt004 on "fobos".cxpt004 
    (p04_tipo_doc) using btree  in idxdbs ;
alter table "fobos".cxpt004 add constraint primary key (p04_tipo_doc) 
    constraint "fobos".pk_cxpt004  ;
create index "fobos".i01_fk_cxpt025 on "fobos".cxpt025 (p25_compania,
    p25_localidad,p25_codprov,p25_tipo_doc,p25_num_doc,p25_dividendo) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_cxpt025 on "fobos".cxpt025 
    (p25_compania,p25_localidad,p25_orden_pago,p25_secuencia) 
    using btree  in idxdbs ;
create index "fobos".i02_fk_cxpt025 on "fobos".cxpt025 (p25_compania,
    p25_localidad,p25_orden_pago) using btree  in idxdbs ;
alter table "fobos".cxpt025 add constraint primary key (p25_compania,
    p25_localidad,p25_orden_pago,p25_secuencia) constraint "fobos"
    .pk_cxpt025  ;
create unique index "fobos".i01_pk_cxpt026 on "fobos".cxpt026 
    (p26_compania,p26_localidad,p26_orden_pago,p26_secuencia,
    p26_tipo_ret,p26_porcentaje,p26_codigo_sri,p26_fecha_ini_porc) 
    using btree  in idxdbs ;
create index "fobos".i02_fk_cxpt026 on "fobos".cxpt026 (p26_compania,
    p26_localidad,p26_orden_pago,p26_secuencia) using btree  
    in idxdbs ;
create index "fobos".i03_fk_cxpt026 on "fobos".cxpt026 (p26_compania,
    p26_tipo_ret,p26_porcentaje,p26_codigo_sri,p26_fecha_ini_porc) 
    using btree  in idxdbs ;
alter table "fobos".cxpt026 add constraint primary key (p26_compania,
    p26_localidad,p26_orden_pago,p26_secuencia,p26_tipo_ret,p26_porcentaje,
    p26_codigo_sri,p26_fecha_ini_porc) constraint "fobos".pk_cxpt026 
     ;
create index "fobos".i01_fk_cxpt028 on "fobos".cxpt028 (p28_compania,
    p28_localidad,p28_codprov,p28_tipo_doc,p28_num_doc,p28_dividendo) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_cxpt028 on "fobos".cxpt028 
    (p28_compania,p28_localidad,p28_num_ret,p28_secuencia) using 
    btree  in idxdbs ;
create index "fobos".i02_fk_cxpt028 on "fobos".cxpt028 (p28_compania,
    p28_localidad,p28_num_ret) using btree  in idxdbs ;
create index "fobos".i03_fk_cxpt028 on "fobos".cxpt028 (p28_compania,
    p28_tipo_ret,p28_porcentaje,p28_codigo_sri,p28_fecha_ini_porc) 
    using btree  in idxdbs ;
alter table "fobos".cxpt028 add constraint primary key (p28_compania,
    p28_localidad,p28_num_ret,p28_secuencia) constraint "fobos"
    .pk_cxpt028  ;
create unique index "fobos".i01_pk_cajt000 on "fobos".cajt000 
    (j00_compania) using btree  in idxdbs ;
alter table "fobos".cajt000 add constraint primary key (j00_compania) 
    constraint "fobos".pk_cajt000  ;
create index "fobos".i01_fk_cajt001 on "fobos".cajt001 (j01_usuario) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_cajt001 on "fobos".cajt001 
    (j01_compania,j01_codigo_pago,j01_cont_cred) using btree 
     in idxdbs ;
create index "fobos".i02_fk_cajt001 on "fobos".cajt001 (j01_compania,
    j01_aux_cont) using btree  in idxdbs ;
alter table "fobos".cajt001 add constraint primary key (j01_compania,
    j01_codigo_pago,j01_cont_cred) constraint "fobos".pk_cajt001 
     ;
create index "fobos".i01_fk_cajt002 on "fobos".cajt002 (j02_compania) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_cajt002 on "fobos".cajt002 
    (j02_compania,j02_localidad,j02_codigo_caja) using btree 
     in idxdbs ;
create index "fobos".i02_fk_cajt002 on "fobos".cajt002 (j02_compania,
    j02_localidad) using btree  in idxdbs ;
create index "fobos".i03_fk_cajt002 on "fobos".cajt002 (j02_usua_caja) 
    using btree  in idxdbs ;
alter table "fobos".cajt002 add constraint primary key (j02_compania,
    j02_localidad,j02_codigo_caja) constraint "fobos".pk_cajt002 
     ;
create index "fobos".i01_fk_cajt003 on "fobos".cajt003 (j03_compania,
    j03_localidad,j03_codigo_caja) using btree  in idxdbs ;
create unique index "fobos".i01_pk_cajt003 on "fobos".cajt003 
    (j03_compania,j03_localidad,j03_codigo_caja,j03_areaneg) 
    using btree  in idxdbs ;
create index "fobos".i02_fk_cajt003 on "fobos".cajt003 (j03_compania,
    j03_areaneg) using btree  in idxdbs ;
alter table "fobos".cajt003 add constraint primary key (j03_compania,
    j03_localidad,j03_codigo_caja,j03_areaneg) constraint "fobos"
    .pk_cajt003  ;
create index "fobos".i01_fk_cajt999 on "fobos".cajt999 (j04_compania,
    j04_localidad,j04_codigo_caja) using btree  in idxdbs ;
create index "fobos".i02_fk_cajt999 on "fobos".cajt999 (j04_moneda) 
    using btree  in idxdbs ;
create index "fobos".i03_fk_cajt999 on "fobos".cajt999 (j04_usuario) 
    using btree  in idxdbs ;
create index "fobos".i01_fk_cajt012 on "fobos".cajt012 (j12_compania,
    j12_localidad,j12_tipo_fuente,j12_num_fuente,j12_sec_cheque) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_cajt012 on "fobos".cajt012 
    (j12_compania,j12_localidad,j12_banco,j12_num_cta,j12_num_cheque,
    j12_secuencia) using btree  in idxdbs ;
create index "fobos".i02_fk_cajt012 on "fobos".cajt012 (j12_compania) 
    using btree  in idxdbs ;
create index "fobos".i03_fk_cajt012 on "fobos".cajt012 (j12_compania,
    j12_localidad) using btree  in idxdbs ;
create index "fobos".i04_fk_cajt012 on "fobos".cajt012 (j12_compania,
    j12_localidad,j12_codcli) using btree  in idxdbs ;
create index "fobos".i05_fk_cajt012 on "fobos".cajt012 (j12_compania,
    j12_areaneg) using btree  in idxdbs ;
create index "fobos".i06_fk_cajt012 on "fobos".cajt012 (j12_moneda) 
    using btree  in idxdbs ;
create index "fobos".i07_fk_cajt012 on "fobos".cajt012 (j12_usuario) 
    using btree  in idxdbs ;
alter table "fobos".cajt012 add constraint primary key (j12_compania,
    j12_localidad,j12_banco,j12_num_cta,j12_num_cheque,j12_secuencia) 
    constraint "fobos".pk_cajt012  ;
create index "fobos".i01_fk_cajt013 on "fobos".cajt013 (j13_compania,
    j13_localidad,j13_codigo_caja) using btree  in idxdbs ;
create unique index "fobos".i01_pk_cajt013 on "fobos".cajt013 
    (j13_compania,j13_localidad,j13_codigo_caja,j13_fecha,j13_moneda,
    j13_trn_generada,j13_codigo_pago) using btree  in idxdbs 
    ;
create index "fobos".i02_fk_cajt013 on "fobos".cajt013 (j13_moneda) 
    using btree  in idxdbs ;
create index "fobos".i03_fk_cajt013 on "fobos".cajt013 (j13_compania,
    j13_codigo_pago) using btree  in idxdbs ;
alter table "fobos".cajt013 add constraint primary key (j13_compania,
    j13_localidad,j13_codigo_caja,j13_fecha,j13_moneda,j13_trn_generada,
    j13_codigo_pago) constraint "fobos".pk_cajt013  ;
create unique index "fobos".i01_pk_ccht000 on "fobos".ccht000 
    (h00_serial) using btree  in idxdbs ;
alter table "fobos".ccht000 add constraint primary key (h00_serial) 
    constraint "fobos".pk_ccht000  ;
create index "fobos".i01_fk_ccht001 on "fobos".ccht001 (h01_compania,
    h01_localidad) using btree  in idxdbs ;
create unique index "fobos".i01_pk_ccht001 on "fobos".ccht001 
    (h01_compania,h01_localidad,h01_caja_chica) using btree  
    in idxdbs ;
create index "fobos".i02_fk_ccht001 on "fobos".ccht001 (h01_moneda) 
    using btree  in idxdbs ;
create index "fobos".i03_fk_ccht001 on "fobos".ccht001 (h01_compania,
    h01_aux_cont_caj) using btree  in idxdbs ;
create index "fobos".i04_fk_ccht001 on "fobos".ccht001 (h01_compania,
    h01_aux_cont_pag) using btree  in idxdbs ;
create index "fobos".i05_fk_ccht001 on "fobos".ccht001 (h01_usuario) 
    using btree  in idxdbs ;
alter table "fobos".ccht001 add constraint primary key (h01_compania,
    h01_localidad,h01_caja_chica) constraint "fobos".pk_ccht001 
     ;
create index "fobos".i01_fk_ccht002 on "fobos".ccht002 (h02_compania,
    h02_localidad,h02_caja_chica) using btree  in idxdbs ;
create unique index "fobos".i01_pk_ccht002 on "fobos".ccht002 
    (h02_compania,h02_localidad,h02_caja_chica,h02_tipo_trn,h02_numero) 
    using btree  in idxdbs ;
create index "fobos".i02_fk_ccht002 on "fobos".ccht002 (h02_moneda) 
    using btree  in idxdbs ;
create index "fobos".i03_fk_ccht002 on "fobos".ccht002 (h02_compania,
    h02_localidad,h02_numero_oc) using btree  in idxdbs ;
create index "fobos".i04_fk_ccht002 on "fobos".ccht002 (h02_compania,
    h02_tipo_comp,h02_num_comp) using btree  in idxdbs ;
create index "fobos".i05_fk_ccht002 on "fobos".ccht002 (h02_usuario) 
    using btree  in idxdbs ;
alter table "fobos".ccht002 add constraint primary key (h02_compania,
    h02_localidad,h02_caja_chica,h02_tipo_trn,h02_numero) constraint 
    "fobos".pk_ccht002  ;
create index "fobos".i01_fk_ccht003 on "fobos".ccht003 (h03_compania,
    h03_localidad,h03_caja_chica,h03_tipo_trn,h03_numero) using 
    btree  in idxdbs ;
create unique index "fobos".i01_pk_ccht003 on "fobos".ccht003 
    (h03_compania,h03_localidad,h03_caja_chica,h03_tipo_trn,h03_numero,
    h03_secuencia) using btree  in idxdbs ;
create index "fobos".i02_fk_ccht003 on "fobos".ccht003 (h03_compania,
    h03_aux_cont) using btree  in idxdbs ;
create index "fobos".i03_fk_ccht003 on "fobos".ccht003 (h03_usuario) 
    using btree  in idxdbs ;
alter table "fobos".ccht003 add constraint primary key (h03_compania,
    h03_localidad,h03_caja_chica,h03_tipo_trn,h03_numero,h03_secuencia) 
    constraint "fobos".pk_ccht003  ;
create index "fobos".i01_fk_rolt000 on "fobos".rolt000 (n00_moneda_pago) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_rolt000 on "fobos".rolt000 
    (n00_serial) using btree  in idxdbs ;
create index "fobos".i02_fk_rolt000 on "fobos".rolt000 (n00_usuario) 
    using btree  in idxdbs ;
alter table "fobos".rolt000 add constraint primary key (n00_serial) 
    constraint "fobos".pk_rolt000  ;
create index "fobos".i01_fk_rolt001 on "fobos".rolt001 (n01_usuario) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_rolt001 on "fobos".rolt001 
    (n01_compania) using btree  in idxdbs ;
alter table "fobos".rolt001 add constraint primary key (n01_compania) 
    constraint "fobos".pk_rolt001  ;
create index "fobos".i01_fk_rolt002 on "fobos".rolt002 (n02_compania) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_rolt002 on "fobos".rolt002 
    (n02_compania,n02_ano,n02_mes) using btree  in idxdbs ;
create index "fobos".i02_fk_rolt002 on "fobos".rolt002 (n02_usuario) 
    using btree  in idxdbs ;
alter table "fobos".rolt002 add constraint primary key (n02_compania,
    n02_ano,n02_mes) constraint "fobos".pk_rolt002  ;
create index "fobos".i01_fk_rolt003 on "fobos".rolt003 (n03_usuario) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_rolt003 on "fobos".rolt003 
    (n03_proceso) using btree  in idxdbs ;
alter table "fobos".rolt003 add constraint primary key (n03_proceso) 
    constraint "fobos".pk_rolt003  ;
create index "fobos".i01_fk_rolt004 on "fobos".rolt004 (n04_compania) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_rolt004 on "fobos".rolt004 
    (n04_compania,n04_proceso,n04_cod_rubro) using btree  in 
    idxdbs ;
create index "fobos".i02_fk_rolt004 on "fobos".rolt004 (n04_proceso) 
    using btree  in idxdbs ;
create index "fobos".i03_fk_rolt004 on "fobos".rolt004 (n04_cod_rubro) 
    using btree  in idxdbs ;
create index "fobos".i04_fk_rolt004 on "fobos".rolt004 (n04_usuario) 
    using btree  in idxdbs ;
alter table "fobos".rolt004 add constraint primary key (n04_compania,
    n04_proceso,n04_cod_rubro) constraint "fobos".pk_rolt004  
    ;
create index "fobos".i01_fk_rolt005 on "fobos".rolt005 (n05_compania) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_rolt005 on "fobos".rolt005 
    (n05_compania,n05_proceso) using btree  in idxdbs ;
create index "fobos".i02_fk_rolt005 on "fobos".rolt005 (n05_proceso) 
    using btree  in idxdbs ;
create index "fobos".i03_fk_rolt005 on "fobos".rolt005 (n05_usuario) 
    using btree  in idxdbs ;
alter table "fobos".rolt005 add constraint primary key (n05_compania,
    n05_proceso) constraint "fobos".pk_rolt005  ;
create index "fobos".i01_fk_rolt006 on "fobos".rolt006 (n06_usuario) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_rolt006 on "fobos".rolt006 
    (n06_cod_rubro) using btree  in idxdbs ;
create index "fobos".i02_fk_rolt006 on "fobos".rolt006 (n06_flag_ident) 
    using btree  in idxdbs ;
alter table "fobos".rolt006 add constraint primary key (n06_cod_rubro) 
    constraint "fobos".pk_rolt006  ;
create index "fobos".i01_fk_rolt007 on "fobos".rolt007 (n07_usuario) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_rolt007 on "fobos".rolt007 
    (n07_cod_rubro) using btree  in idxdbs ;
alter table "fobos".rolt007 add constraint primary key (n07_cod_rubro) 
    constraint "fobos".pk_rolt007  ;
create index "fobos".i01_fk_rolt008 on "fobos".rolt008 (n08_cod_rubro) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_rolt008 on "fobos".rolt008 
    (n08_cod_rubro,n08_rubro_base) using btree  in idxdbs ;
create index "fobos".i02_fk_rolt008 on "fobos".rolt008 (n08_rubro_base) 
    using btree  in idxdbs ;
alter table "fobos".rolt008 add constraint primary key (n08_cod_rubro,
    n08_rubro_base) constraint "fobos".pk_rolt008  ;
create index "fobos".i01_fk_rolt009 on "fobos".rolt009 (n09_compania) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_rolt009 on "fobos".rolt009 
    (n09_compania,n09_cod_rubro) using btree  in idxdbs ;
create index "fobos".i02_fk_rolt009 on "fobos".rolt009 (n09_cod_rubro) 
    using btree  in idxdbs ;
create index "fobos".i03_fk_rolt009 on "fobos".rolt009 (n09_usuario) 
    using btree  in idxdbs ;
alter table "fobos".rolt009 add constraint primary key (n09_compania,
    n09_cod_rubro) constraint "fobos".pk_rolt009  ;
create index "fobos".i01_fk_rolt010 on "fobos".rolt010 (n10_compania,
    n10_cod_rubro) using btree  in idxdbs ;
create unique index "fobos".i01_pk_rolt010 on "fobos".rolt010 
    (n10_compania,n10_cod_liqrol,n10_cod_rubro,n10_cod_trab) 
    using btree  in idxdbs ;
create index "fobos".i02_fk_rolt010 on "fobos".rolt010 (n10_compania,
    n10_cod_trab) using btree  in idxdbs ;
create index "fobos".i03_fk_rolt010 on "fobos".rolt010 (n10_cod_liqrol) 
    using btree  in idxdbs ;
create index "fobos".i04_fk_rolt010 on "fobos".rolt010 (n10_usuario) 
    using btree  in idxdbs ;
alter table "fobos".rolt010 add constraint primary key (n10_compania,
    n10_cod_liqrol,n10_cod_rubro,n10_cod_trab) constraint "fobos"
    .pk_rolt010  ;
create index "fobos".i01_fk_rolt011 on "fobos".rolt011 (n11_cod_liqrol) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_rolt011 on "fobos".rolt011 
    (n11_compania,n11_cod_liqrol,n11_cod_rubro) using btree  
    in idxdbs ;
create index "fobos".i02_fk_rolt011 on "fobos".rolt011 (n11_compania,
    n11_cod_rubro) using btree  in idxdbs ;
create index "fobos".i03_fk_rolt011 on "fobos".rolt011 (n11_usuario) 
    using btree  in idxdbs ;
alter table "fobos".rolt011 add constraint primary key (n11_compania,
    n11_cod_liqrol,n11_cod_rubro) constraint "fobos".pk_rolt011 
     ;
create index "fobos".i01_fk_rolt012 on "fobos".rolt012 (n12_compania,
    n12_cod_trab) using btree  in idxdbs ;
create unique index "fobos".i01_pk_rolt012 on "fobos".rolt012 
    (n12_compania,n12_num_cont) using btree  in idxdbs ;
create index "fobos".i02_fk_rolt012 on "fobos".rolt012 (n12_usuario) 
    using btree  in idxdbs ;
alter table "fobos".rolt012 add constraint primary key (n12_compania,
    n12_num_cont) constraint "fobos".pk_rolt012  ;
create index "fobos".i01_fk_rolt013 on "fobos".rolt013 (n13_usuario) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_rolt013 on "fobos".rolt013 
    (n13_cod_seguro) using btree  in idxdbs ;
alter table "fobos".rolt013 add constraint primary key (n13_cod_seguro) 
    constraint "fobos".pk_rolt013  ;
create index "fobos".i01_fk_rolt014 on "fobos".rolt014 (n14_cod_seguro) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_rolt014 on "fobos".rolt014 
    (n14_serial) using btree  in idxdbs ;
alter table "fobos".rolt014 add constraint primary key (n14_serial) 
    constraint "fobos".pk_rolt014  ;
create index "fobos".i01_fk_rolt030 on "fobos".rolt030 (n30_compania) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_rolt030 on "fobos".rolt030 
    (n30_compania,n30_cod_trab) using btree  in idxdbs ;
create index "fobos".i02_fk_rolt030 on "fobos".rolt030 (n30_compania,
    n30_cod_cargo) using btree  in idxdbs ;
create index "fobos".i03_fk_rolt030 on "fobos".rolt030 (n30_compania,
    n30_cod_depto) using btree  in idxdbs ;
create index "fobos".i04_fk_rolt030 on "fobos".rolt030 (n30_pais_nac) 
    using btree  in idxdbs ;
create index "fobos".i05_fk_rolt030 on "fobos".rolt030 (n30_ciudad_nac) 
    using btree  in idxdbs ;
create index "fobos".i06_fk_rolt030 on "fobos".rolt030 (n30_compania,
    n30_bco_empresa,n30_cta_empresa) using btree  in idxdbs ;
    
create index "fobos".i07_fk_rolt030 on "fobos".rolt030 (n30_usuario) 
    using btree  in idxdbs ;
create index "fobos".i08_fk_rolt030 on "fobos".rolt030 (n30_compania,
    n30_ano_sect,n30_sectorial) using btree  in idxdbs ;
create index "fobos".i09_fk_rolt030 on "fobos".rolt030 (n30_cod_seguro) 
    using btree  in idxdbs ;
alter table "fobos".rolt030 add constraint primary key (n30_compania,
    n30_cod_trab) constraint "fobos".pk_rolt030  ;
create index "fobos".i01_fk_rolt032 on "fobos".rolt032 (n32_compania) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_rolt032 on "fobos".rolt032 
    (n32_compania,n32_cod_liqrol,n32_fecha_ini,n32_fecha_fin,
    n32_cod_trab) using btree  in idxdbs ;
create index "fobos".i02_fk_rolt032 on "fobos".rolt032 (n32_cod_liqrol) 
    using btree  in idxdbs ;
create index "fobos".i03_fk_rolt032 on "fobos".rolt032 (n32_compania,
    n32_cod_trab) using btree  in idxdbs ;
create index "fobos".i04_fk_rolt032 on "fobos".rolt032 (n32_compania,
    n32_cod_depto) using btree  in idxdbs ;
create index "fobos".i05_fk_rolt032 on "fobos".rolt032 (n32_moneda) 
    using btree  in idxdbs ;
create index "fobos".i06_fk_rolt032 on "fobos".rolt032 (n32_compania,
    n32_bco_empresa,n32_cta_empresa) using btree  in idxdbs ;
    
create index "fobos".i07_fk_rolt032 on "fobos".rolt032 (n32_usuario) 
    using btree  in idxdbs ;
alter table "fobos".rolt032 add constraint primary key (n32_compania,
    n32_cod_liqrol,n32_fecha_ini,n32_fecha_fin,n32_cod_trab) 
    constraint "fobos".pk_rolt032  ;
create index "fobos".i01_fk_rolt033 on "fobos".rolt033 (n33_compania,
    n33_cod_liqrol,n33_fecha_ini,n33_fecha_fin,n33_cod_trab) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_rolt033 on "fobos".rolt033 
    (n33_compania,n33_cod_liqrol,n33_fecha_ini,n33_fecha_fin,
    n33_cod_trab,n33_cod_rubro) using btree  in idxdbs ;
create index "fobos".i02_fk_rolt033 on "fobos".rolt033 (n33_compania,
    n33_cod_rubro) using btree  in idxdbs ;
create index "fobos".i03_fk_rolt033 on "fobos".rolt033 (n33_compania,
    n33_num_prest) using btree  in idxdbs ;
create index "fobos".i04_fk_rolt033 on "fobos".rolt033 (n33_compania,
    n33_prest_club) using btree  in idxdbs ;
alter table "fobos".rolt033 add constraint primary key (n33_compania,
    n33_cod_liqrol,n33_fecha_ini,n33_fecha_fin,n33_cod_trab,n33_cod_rubro) 
    constraint "fobos".pk_rolt033  ;
create index "fobos".i01_fk_rolt034 on "fobos".rolt034 (n34_compania,
    n34_cod_trab) using btree  in idxdbs ;
create unique index "fobos".i01_pk_rolt034 on "fobos".rolt034 
    (n34_serial) using btree  in idxdbs ;
create index "fobos".i02_fk_rolt034 on "fobos".rolt034 (n34_compania,
    n34_cod_rubro) using btree  in idxdbs ;
create index "fobos".i03_fk_rolt034 on "fobos".rolt034 (n34_compania,
    n34_cod_depto) using btree  in idxdbs ;
create index "fobos".i04_fk_rolt034 on "fobos".rolt034 (n34_moneda) 
    using btree  in idxdbs ;
create index "fobos".i05_fk_rolt034 on "fobos".rolt034 (n34_cod_liqrol) 
    using btree  in idxdbs ;
create index "fobos".i06_fk_rolt034 on "fobos".rolt034 (n34_compania,
    n34_bco_empresa,n34_cta_empresa) using btree  in idxdbs ;
    
create index "fobos".i07_fk_rolt034 on "fobos".rolt034 (n34_usuario) 
    using btree  in idxdbs ;
alter table "fobos".rolt034 add constraint primary key (n34_serial) 
    constraint "fobos".pk_rolt034  ;
create index "fobos".i01_fk_rolt035 on "fobos".rolt035 (n35_compania,
    n35_cod_trab) using btree  in idxdbs ;
create unique index "fobos".i01_pk_rolt035 on "fobos".rolt035 
    (n35_compania,n35_ano,n35_mes,n35_cod_trab,n35_proceso) using 
    btree  in idxdbs ;
create index "fobos".i02_fk_rolt035 on "fobos".rolt035 (n35_compania,
    n35_cod_depto) using btree  in idxdbs ;
create index "fobos".i03_fk_rolt035 on "fobos".rolt035 (n35_proceso) 
    using btree  in idxdbs ;
create index "fobos".i04_fk_rolt035 on "fobos".rolt035 (n35_moneda) 
    using btree  in idxdbs ;
create index "fobos".i05_fk_rolt035 on "fobos".rolt035 (n35_usuario) 
    using btree  in idxdbs ;
alter table "fobos".rolt035 add constraint primary key (n35_compania,
    n35_ano,n35_mes,n35_cod_trab,n35_proceso) constraint "fobos"
    .pk_rolt035  ;
create index "fobos".i01_fk_rolt036 on "fobos".rolt036 (n36_compania,
    n36_cod_trab) using btree  in idxdbs ;
create unique index "fobos".i01_pk_rolt036 on "fobos".rolt036 
    (n36_compania,n36_proceso,n36_fecha_ini,n36_fecha_fin,n36_cod_trab) 
    using btree  in idxdbs ;
create index "fobos".i02_fk_rolt036 on "fobos".rolt036 (n36_proceso) 
    using btree  in idxdbs ;
create index "fobos".i03_fk_rolt036 on "fobos".rolt036 (n36_compania,
    n36_cod_depto) using btree  in idxdbs ;
create index "fobos".i04_fk_rolt036 on "fobos".rolt036 (n36_moneda) 
    using btree  in idxdbs ;
create index "fobos".i05_fk_rolt036 on "fobos".rolt036 (n36_compania,
    n36_bco_empresa,n36_cta_empresa) using btree  in idxdbs ;
    
create index "fobos".i06_fk_rolt036 on "fobos".rolt036 (n36_usuario) 
    using btree  in idxdbs ;
create index "fobos".i07_fk_rolt036 on "fobos".rolt036 (n36_usuario_modif) 
    using btree  in idxdbs ;
alter table "fobos".rolt036 add constraint primary key (n36_compania,
    n36_proceso,n36_fecha_ini,n36_fecha_fin,n36_cod_trab) constraint 
    "fobos".pk_rolt036  ;
create index "fobos".i01_fk_rolt037 on "fobos".rolt037 (n37_compania,
    n37_proceso,n37_fecha_ini,n37_fecha_fin,n37_cod_trab) using 
    btree  in idxdbs ;
create unique index "fobos".i01_pk_rolt037 on "fobos".rolt037 
    (n37_compania,n37_proceso,n37_fecha_ini,n37_fecha_fin,n37_cod_trab,
    n37_cod_rubro) using btree  in idxdbs ;
create index "fobos".i02_fk_rolt037 on "fobos".rolt037 (n37_compania,
    n37_cod_rubro) using btree  in idxdbs ;
create index "fobos".i03_fk_rolt037 on "fobos".rolt037 (n37_compania,
    n37_num_prest) using btree  in idxdbs ;
alter table "fobos".rolt037 add constraint primary key (n37_compania,
    n37_proceso,n37_fecha_ini,n37_fecha_fin,n37_cod_trab,n37_cod_rubro) 
    constraint "fobos".pk_rolt037  ;
create index "fobos".i01_fk_rolt038 on "fobos".rolt038 (n38_compania,
    n38_cod_trab) using btree  in idxdbs ;
create unique index "fobos".i01_pk_rolt038 on "fobos".rolt038 
    (n38_compania,n38_fecha_ini,n38_fecha_fin,n38_cod_trab) using 
    btree  in idxdbs ;
create index "fobos".i02_fk_rolt038 on "fobos".rolt038 (n38_moneda) 
    using btree  in idxdbs ;
create index "fobos".i03_fk_rolt038 on "fobos".rolt038 (n38_usuario) 
    using btree  in idxdbs ;
alter table "fobos".rolt038 add constraint primary key (n38_compania,
    n38_fecha_ini,n38_fecha_fin,n38_cod_trab) constraint "fobos"
    .pk_rolt038  ;
create index "fobos".i01_fk_rolt042 on "fobos".rolt042 (n42_compania,
    n42_proceso,n42_fecha_ini,n42_fecha_fin) using btree  in 
    idxdbs ;
create unique index "fobos".i01_pk_rolt042 on "fobos".rolt042 
    (n42_compania,n42_proceso,n42_cod_trab,n42_fecha_ini,n42_fecha_fin) 
    using btree  in idxdbs ;
create index "fobos".i02_fk_rolt042 on "fobos".rolt042 (n42_compania,
    n42_cod_trab) using btree  in idxdbs ;
create index "fobos".i03_fk_rolt042 on "fobos".rolt042 (n42_compania,
    n42_cod_depto) using btree  in idxdbs ;
create index "fobos".i04_fk_rolt042 on "fobos".rolt042 (n42_bco_empresa) 
    using btree  in idxdbs ;
create index "fobos".i05_fk_rolt042 on "fobos".rolt042 (n42_compania,
    n42_bco_empresa,n42_cta_empresa) using btree  in idxdbs ;
    
alter table "fobos".rolt042 add constraint primary key (n42_compania,
    n42_proceso,n42_cod_trab,n42_fecha_ini,n42_fecha_fin) constraint 
    "fobos".pk_rolt042  ;
create index "fobos".i01_fk_rolt043 on "fobos".rolt043 (n43_compania) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_rolt043 on "fobos".rolt043 
    (n43_compania,n43_num_rol) using btree  in idxdbs ;
create index "fobos".i02_fk_rolt043 on "fobos".rolt043 (n43_moneda) 
    using btree  in idxdbs ;
create index "fobos".i03_fk_rolt043 on "fobos".rolt043 (n43_usuario) 
    using btree  in idxdbs ;
alter table "fobos".rolt043 add constraint primary key (n43_compania,
    n43_num_rol) constraint "fobos".pk_rolt043  ;
create index "fobos".i01_fk_rolt044 on "fobos".rolt044 (n44_compania,
    n44_num_rol) using btree  in idxdbs ;
create unique index "fobos".i01_pk_rolt044 on "fobos".rolt044 
    (n44_compania,n44_num_rol,n44_cod_trab) using btree  in idxdbs 
    ;
create index "fobos".i02_fk_rolt044 on "fobos".rolt044 (n44_compania,
    n44_cod_trab) using btree  in idxdbs ;
create index "fobos".i03_fk_rolt044 on "fobos".rolt044 (n44_compania,
    n44_cod_depto) using btree  in idxdbs ;
create index "fobos".i04_fk_rolt044 on "fobos".rolt044 (n44_compania,
    n44_bco_empresa,n44_cta_empresa) using btree  in idxdbs ;
    
alter table "fobos".rolt044 add constraint primary key (n44_compania,
    n44_num_rol,n44_cod_trab) constraint "fobos".pk_rolt044  ;
    
create index "fobos".i01_fk_rolt045 on "fobos".rolt045 (n45_compania,
    n45_cod_trab) using btree  in idxdbs ;
create unique index "fobos".i01_pk_rolt045 on "fobos".rolt045 
    (n45_compania,n45_num_prest) using btree  in idxdbs ;
create index "fobos".i02_fk_rolt045 on "fobos".rolt045 (n45_compania,
    n45_cod_rubro) using btree  in idxdbs ;
create index "fobos".i03_fk_rolt045 on "fobos".rolt045 (n45_moneda) 
    using btree  in idxdbs ;
create index "fobos".i04_fk_rolt045 on "fobos".rolt045 (n45_usuario) 
    using btree  in idxdbs ;
create index "fobos".i05_fk_rolt045 on "fobos".rolt045 (n45_bco_empresa) 
    using btree  in idxdbs ;
create index "fobos".i06_fk_rolt045 on "fobos".rolt045 (n45_compania,
    n45_bco_empresa,n45_cta_empresa) using btree  in idxdbs ;
    
create index "fobos".i07_fk_rolt045 on "fobos".rolt045 (n45_compania,
    n45_prest_tran) using btree  in idxdbs ;
alter table "fobos".rolt045 add constraint primary key (n45_compania,
    n45_num_prest) constraint "fobos".pk_rolt045  ;
create index "fobos".i01_fk_rolt046 on "fobos".rolt046 (n46_compania,
    n46_num_prest) using btree  in idxdbs ;
create unique index "fobos".i01_pk_rolt046 on "fobos".rolt046 
    (n46_compania,n46_num_prest,n46_secuencia) using btree  in 
    idxdbs ;
create index "fobos".i02_fk_rolt046 on "fobos".rolt046 (n46_cod_liqrol) 
    using btree  in idxdbs ;
alter table "fobos".rolt046 add constraint primary key (n46_compania,
    n46_num_prest,n46_secuencia) constraint "fobos".pk_rolt046 
     ;
create index "fobos".i01_fk_actt000 on "fobos".actt000 (a00_compania,
    a00_aux_reexp) using btree  in idxdbs ;
create unique index "fobos".i01_pk_actt000 on "fobos".actt000 
    (a00_compania) using btree  in idxdbs ;
alter table "fobos".actt000 add constraint primary key (a00_compania) 
    constraint "fobos".pk_actt000  ;
create index "fobos".i01_fk_actt003 on "fobos".actt003 (a03_compania) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_actt003 on "fobos".actt003 
    (a03_compania,a03_responsable) using btree  in idxdbs ;
create index "fobos".i02_fk_actt003 on "fobos".actt003 (a03_ciarol,
    a03_codrol) using btree  in idxdbs ;
create index "fobos".i03_fk_actt003 on "fobos".actt003 (a03_usuario) 
    using btree  in idxdbs ;
alter table "fobos".actt003 add constraint primary key (a03_compania,
    a03_responsable) constraint "fobos".pk_actt003  ;
create index "fobos".i01_fk_actt004 on "fobos".actt004 (a04_usuario) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_actt004 on "fobos".actt004 
    (a04_codigo_proc) using btree  in idxdbs ;
alter table "fobos".actt004 add constraint primary key (a04_codigo_proc) 
    constraint "fobos".pk_actt004  ;
create index "fobos".i01_fk_actt005 on "fobos".actt005 (a05_compania) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_actt005 on "fobos".actt005 
    (a05_compania,a05_codigo_tran) using btree  in idxdbs ;
create index "fobos".i02_fk_actt005 on "fobos".actt005 (a05_codigo_tran) 
    using btree  in idxdbs ;
alter table "fobos".actt005 add constraint primary key (a05_compania,
    a05_codigo_tran) constraint "fobos".pk_actt005  ;
create index "fobos".i01_fk_actt011 on "fobos".actt011 (a11_compania,
    a11_codigo_bien) using btree  in idxdbs ;
create unique index "fobos".i01_pk_actt011 on "fobos".actt011 
    (a11_compania,a11_codigo_bien,a11_cod_depto) using btree 
     in idxdbs ;
create index "fobos".i02_fk_actt011 on "fobos".actt011 (a11_compania,
    a11_cod_depto) using btree  in idxdbs ;
alter table "fobos".actt011 add constraint primary key (a11_compania,
    a11_codigo_bien,a11_cod_depto) constraint "fobos".pk_actt011 
     ;
create index "fobos".i01_fk_ctbt000 on "fobos".ctbt000 (b00_moneda_base) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_ctbt000 on "fobos".ctbt000 
    (b00_compania) using btree  in idxdbs ;
create index "fobos".i02_fk_ctbt000 on "fobos".ctbt000 (b00_moneda_aux) 
    using btree  in idxdbs ;
create index "fobos".i03_fk_ctbt000 on "fobos".ctbt000 (b00_compania,
    b00_cuenta_uti) using btree  in idxdbs ;
create index "fobos".i04_fk_ctbt000 on "fobos".ctbt000 (b00_compania,
    b00_cta_uti_ant) using btree  in idxdbs ;
create index "fobos".i05_fk_ctbt000 on "fobos".ctbt000 (b00_compania,
    b00_cuenta_difi) using btree  in idxdbs ;
create index "fobos".i06_fk_ctbt000 on "fobos".ctbt000 (b00_compania,
    b00_cuenta_dife) using btree  in idxdbs ;
alter table "fobos".ctbt000 add constraint primary key (b00_compania) 
    constraint "fobos".pk_ctbt000  ;
create index "fobos".i01_fk_ctbt001 on "fobos".ctbt001 (b01_usuario) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_ctbt001 on "fobos".ctbt001 
    (b01_nivel) using btree  in idxdbs ;
alter table "fobos".ctbt001 add constraint primary key (b01_nivel) 
    constraint "fobos".pk_ctbt001  ;
create index "fobos".i01_fk_ctbt002 on "fobos".ctbt002 (b02_compania) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_ctbt002 on "fobos".ctbt002 
    (b02_compania,b02_grupo_cta) using btree  in idxdbs ;
create index "fobos".i02_fk_ctbt002 on "fobos".ctbt002 (b02_usuario) 
    using btree  in idxdbs ;
alter table "fobos".ctbt002 add constraint primary key (b02_compania,
    b02_grupo_cta) constraint "fobos".pk_ctbt002  ;
create index "fobos".i01_fk_ctbt003 on "fobos".ctbt003 (b03_compania) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_ctbt003 on "fobos".ctbt003 
    (b03_compania,b03_tipo_comp) using btree  in idxdbs ;
create index "fobos".i02_fk_ctbt003 on "fobos".ctbt003 (b03_modulo) 
    using btree  in idxdbs ;
create index "fobos".i03_fk_ctbt003 on "fobos".ctbt003 (b03_usuario) 
    using btree  in idxdbs ;
alter table "fobos".ctbt003 add constraint primary key (b03_compania,
    b03_tipo_comp) constraint "fobos".pk_ctbt003  ;
create index "fobos".i01_fk_ctbt004 on "fobos".ctbt004 (b04_compania) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_ctbt004 on "fobos".ctbt004 
    (b04_compania,b04_subtipo) using btree  in idxdbs ;
create index "fobos".i02_fk_ctbt004 on "fobos".ctbt004 (b04_usuario) 
    using btree  in idxdbs ;
alter table "fobos".ctbt004 add constraint primary key (b04_compania,
    b04_subtipo) constraint "fobos".pk_ctbt004  ;
create index "fobos".i01_fk_ctbt005 on "fobos".ctbt005 (b05_compania,
    b05_tipo_comp) using btree  in idxdbs ;
create unique index "fobos".i01_pk_ctbt005 on "fobos".ctbt005 
    (b05_compania,b05_tipo_comp,b05_ano) using btree  in idxdbs 
    ;
create index "fobos".i02_fk_ctbt005 on "fobos".ctbt005 (b05_usuario) 
    using btree  in idxdbs ;
alter table "fobos".ctbt005 add constraint primary key (b05_compania,
    b05_tipo_comp,b05_ano) constraint "fobos".pk_ctbt005  ;
create index "fobos".i01_fk_ctbt006 on "fobos".ctbt006 (b06_compania) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_ctbt006 on "fobos".ctbt006 
    (b06_compania,b06_ano,b06_mes) using btree  in idxdbs ;
create index "fobos".i02_fk_ctbt006 on "fobos".ctbt006 (b06_usuario) 
    using btree  in idxdbs ;
alter table "fobos".ctbt006 add constraint primary key (b06_compania,
    b06_ano,b06_mes) constraint "fobos".pk_ctbt006  ;
create index "fobos".i01_fk_ctbt007 on "fobos".ctbt007 (b07_usuario) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_ctbt007 on "fobos".ctbt007 
    (b07_tipo_doc) using btree  in idxdbs ;
alter table "fobos".ctbt007 add constraint primary key (b07_tipo_doc) 
    constraint "fobos".pk_ctbt007  ;
create index "fobos".i01_fk_ctbt008 on "fobos".ctbt008 (b08_compania) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_ctbt008 on "fobos".ctbt008 
    (b08_compania,b08_filtro) using btree  in idxdbs ;
create index "fobos".i02_fk_ctbt008 on "fobos".ctbt008 (b08_usuario) 
    using btree  in idxdbs ;
alter table "fobos".ctbt008 add constraint primary key (b08_compania,
    b08_filtro) constraint "fobos".pk_ctbt008  ;
create index "fobos".i01_fk_ctbt010 on "fobos".ctbt010 (b10_compania) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_ctbt010 on "fobos".ctbt010 
    (b10_compania,b10_cuenta) using btree  in idxdbs ;
create index "fobos".i02_fk_ctbt010 on "fobos".ctbt010 (b10_nivel) 
    using btree  in idxdbs ;
create index "fobos".i03_fk_ctbt010 on "fobos".ctbt010 (b10_compania,
    b10_cod_ccosto) using btree  in idxdbs ;
create index "fobos".i04_fk_ctbt010 on "fobos".ctbt010 (b10_usuario) 
    using btree  in idxdbs ;
alter table "fobos".ctbt010 add constraint primary key (b10_compania,
    b10_cuenta) constraint "fobos".pk_ctbt010  ;
create index "fobos".i01_fk_ctbt011 on "fobos".ctbt011 (b11_compania,
    b11_cuenta) using btree  in idxdbs ;
create unique index "fobos".i01_pk_ctbt011 on "fobos".ctbt011 
    (b11_compania,b11_cuenta,b11_moneda,b11_ano) using btree 
     in idxdbs ;
create index "fobos".i02_fk_ctbt011 on "fobos".ctbt011 (b11_moneda) 
    using btree  in idxdbs ;
alter table "fobos".ctbt011 add constraint primary key (b11_compania,
    b11_cuenta,b11_moneda,b11_ano) constraint "fobos".pk_ctbt011 
     ;
create index "fobos".i01_fk_ctbt014 on "fobos".ctbt014 (b14_compania) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_ctbt014 on "fobos".ctbt014 
    (b14_compania,b14_codigo) using btree  in idxdbs ;
create index "fobos".i02_fk_ctbt014 on "fobos".ctbt014 (b14_compania,
    b14_tipo_comp) using btree  in idxdbs ;
create index "fobos".i03_fk_ctbt014 on "fobos".ctbt014 (b14_moneda) 
    using btree  in idxdbs ;
create index "fobos".i04_fk_ctbt014 on "fobos".ctbt014 (b14_compania,
    b14_tipo_comp,b14_ult_num) using btree  in idxdbs ;
create index "fobos".i05_fk_ctbt014 on "fobos".ctbt014 (b14_usuario) 
    using btree  in idxdbs ;
alter table "fobos".ctbt014 add constraint primary key (b14_compania,
    b14_codigo) constraint "fobos".pk_ctbt014  ;
create index "fobos".i01_fk_ctbt015 on "fobos".ctbt015 (b15_compania,
    b15_codigo) using btree  in idxdbs ;
create unique index "fobos".i01_pk_ctbt015 on "fobos".ctbt015 
    (b15_compania,b15_codigo,b15_cuenta,b15_secuencia) using 
    btree  in idxdbs ;
create index "fobos".i02_fk_ctbt015 on "fobos".ctbt015 (b15_compania,
    b15_cuenta) using btree  in idxdbs ;
alter table "fobos".ctbt015 add constraint primary key (b15_compania,
    b15_codigo,b15_cuenta,b15_secuencia) constraint "fobos".pk_ctbt015 
     ;
create index "fobos".i01_fk_ctbt016 on "fobos".ctbt016 (b16_compania,
    b16_cta_master) using btree  in idxdbs ;
create unique index "fobos".i01_pk_ctbt016 on "fobos".ctbt016 
    (b16_compania,b16_cta_master,b16_cta_detail) using btree 
     in idxdbs ;
create index "fobos".i02_fk_ctbt016 on "fobos".ctbt016 (b16_compania,
    b16_cta_detail) using btree  in idxdbs ;
alter table "fobos".ctbt016 add constraint primary key (b16_compania,
    b16_cta_master,b16_cta_detail) constraint "fobos".pk_ctbt016 
     ;
create index "fobos".i01_fk_ctbt030 on "fobos".ctbt030 (b30_compania) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_ctbt030 on "fobos".ctbt030 
    (b30_compania,b30_num_concil) using btree  in idxdbs ;
create index "fobos".i02_fk_ctbt030 on "fobos".ctbt030 (b30_compania,
    b30_banco,b30_numero_cta) using btree  in idxdbs ;
create index "fobos".i03_fk_ctbt030 on "fobos".ctbt030 (b30_compania,
    b30_aux_cont) using btree  in idxdbs ;
create index "fobos".i04_fk_ctbt030 on "fobos".ctbt030 (b30_moneda) 
    using btree  in idxdbs ;
create index "fobos".i05_fk_ctbt030 on "fobos".ctbt030 (b30_compania,
    b30_tipcomp_gen,b30_numcomp_gen) using btree  in idxdbs ;
    
create index "fobos".i06_fk_ctbt030 on "fobos".ctbt030 (b30_usuario) 
    using btree  in idxdbs ;
alter table "fobos".ctbt030 add constraint primary key (b30_compania,
    b30_num_concil) constraint "fobos".pk_ctbt030  ;
create index "fobos".i01_fk_ctbt031 on "fobos".ctbt031 (b31_compania,
    b31_num_concil) using btree  in idxdbs ;
create unique index "fobos".i01_pk_ctbt031 on "fobos".ctbt031 
    (b31_compania,b31_num_concil,b31_secuencia) using btree  
    in idxdbs ;
create index "fobos".i02_fk_ctbt031 on "fobos".ctbt031 (b31_tipo_doc) 
    using btree  in idxdbs ;
alter table "fobos".ctbt031 add constraint primary key (b31_compania,
    b31_num_concil,b31_secuencia) constraint "fobos".pk_ctbt031 
     ;
create index "fobos".i01_fk_talt004 on "fobos".talt004 (t04_compania) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_talt004 on "fobos".talt004 
    (t04_compania,t04_modelo) using btree  in idxdbs ;
create index "fobos".i02_fk_talt004 on "fobos".talt004 (t04_compania,
    t04_linea) using btree  in idxdbs ;
create index "fobos".i03_fk_talt004 on "fobos".talt004 (t04_usuario) 
    using btree  in idxdbs ;
alter table "fobos".talt004 add constraint primary key (t04_compania,
    t04_modelo) constraint "fobos".pk_talt004  ;
create unique index "fobos".i01_pk_gent015 on "fobos".gent015 
    (g15_compania,g15_localidad,g15_modulo,g15_bodega,g15_tipo) 
    using btree  in idxdbs ;
alter table "fobos".gent015 add constraint primary key (g15_compania,
    g15_localidad,g15_modulo,g15_bodega,g15_tipo) constraint 
    "fobos".pk_gent015  ;
create index "fobos".i01_fk_talt022 on "fobos".talt022 (t22_compania,
    t22_item) using btree  in idxdbs ;
create unique index "fobos".i01_pk_talt022 on "fobos".talt022 
    (t22_compania,t22_localidad,t22_numpre,t22_secuencia) using 
    btree  in idxdbs ;
create index "fobos".i02_fk_talt022 on "fobos".talt022 (t22_usuario) 
    using btree  in idxdbs ;
create index "fobos".i03_fk_talt022 on "fobos".talt022 (t22_compania,
    t22_localidad,t22_numpre) using btree  in idxdbs ;
alter table "fobos".talt022 add constraint primary key (t22_compania,
    t22_localidad,t22_numpre,t22_secuencia) constraint "fobos"
    .pk_talt022  ;
create index "fobos".i01_fk_talt024 on "fobos".talt024 (t24_compania,
    t24_localidad,t24_orden) using btree  in idxdbs ;
create unique index "fobos".i01_pk_talt024 on "fobos".talt024 
    (t24_compania,t24_localidad,t24_orden,t24_codtarea,t24_secuencia) 
    using btree  in idxdbs ;
create index "fobos".i02_fk_talt024 on "fobos".talt024 (t24_compania,
    t24_mecanico) using btree  in idxdbs ;
create index "fobos".i03_fk_talt024 on "fobos".talt024 (t24_compania,
    t24_seccion) using btree  in idxdbs ;
create index "fobos".i04_fk_talt024 on "fobos".talt024 (t24_compania,
    t24_localidad,t24_ord_compra) using btree  in idxdbs ;
create index "fobos".i05_fk_talt024 on "fobos".talt024 (t24_usuario) 
    using btree  in idxdbs ;
create index "fobos".i06_fk_talt024 on "fobos".talt024 (t24_compania,
    t24_codtarea) using btree  in idxdbs ;
alter table "fobos".talt024 add constraint primary key (t24_compania,
    t24_localidad,t24_orden,t24_codtarea,t24_secuencia) constraint 
    "fobos".pk_talt024  ;
create unique index "fobos".i01_pk_talt025 on "fobos".talt025 
    (t25_compania,t25_localidad,t25_orden) using btree  in idxdbs 
    ;
alter table "fobos".talt025 add constraint primary key (t25_compania,
    t25_localidad,t25_orden) constraint "fobos".pk_talt025  ;
create index "fobos".i01_fk_talt026 on "fobos".talt026 (t26_compania,
    t26_localidad,t26_orden) using btree  in idxdbs ;
create unique index "fobos".i01_pk_talt026 on "fobos".talt026 
    (t26_compania,t26_localidad,t26_orden,t26_dividendo) using 
    btree  in idxdbs ;
alter table "fobos".talt026 add constraint primary key (t26_compania,
    t26_localidad,t26_orden,t26_dividendo) constraint "fobos".pk_talt026 
     ;
create index "fobos".i01_fk_talt027 on "fobos".talt027 (t27_compania,
    t27_localidad,t27_orden) using btree  in idxdbs ;
create unique index "fobos".i01_pk_talt027 on "fobos".talt027 
    (t27_compania,t27_localidad,t27_orden,t27_tipo,t27_numero) 
    using btree  in idxdbs ;
create index "fobos".i02_fk_talt027 on "fobos".talt027 (t27_tipo) 
    using btree  in idxdbs ;
alter table "fobos".talt027 add constraint primary key (t27_compania,
    t27_localidad,t27_orden,t27_tipo,t27_numero) constraint "fobos"
    .pk_talt027  ;
create index "fobos".i01_fk_talt040 on "fobos".talt040 (t40_compania) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_talt040 on "fobos".talt040 
    (t40_compania,t40_localidad,t40_ano,t40_mes,t40_tipo_orden,
    t40_modelo,t40_moneda) using btree  in idxdbs ;
create index "fobos".i02_fk_talt040 on "fobos".talt040 (t40_compania,
    t40_localidad) using btree  in idxdbs ;
create index "fobos".i03_fk_talt040 on "fobos".talt040 (t40_compania,
    t40_tipo_orden) using btree  in idxdbs ;
create index "fobos".i04_fk_talt040 on "fobos".talt040 (t40_moneda) 
    using btree  in idxdbs ;
create index "fobos".i05_fk_talt040 on "fobos".talt040 (t40_compania,
    t40_modelo) using btree  in idxdbs ;
alter table "fobos".talt040 add constraint primary key (t40_compania,
    t40_localidad,t40_ano,t40_mes,t40_tipo_orden,t40_modelo,t40_moneda) 
    constraint "fobos".pk_talt040  ;
create index "fobos".i01_fk_talt041 on "fobos".talt041 (t41_compania) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_talt041 on "fobos".talt041 
    (t41_compania,t41_localidad,t41_ano,t41_mes,t41_mecanico,
    t41_modelo,t41_moneda) using btree  in idxdbs ;
create index "fobos".i02_fk_talt041 on "fobos".talt041 (t41_compania,
    t41_localidad) using btree  in idxdbs ;
create index "fobos".i03_fk_talt041 on "fobos".talt041 (t41_compania,
    t41_mecanico) using btree  in idxdbs ;
create index "fobos".i04_fk_talt041 on "fobos".talt041 (t41_moneda) 
    using btree  in idxdbs ;
create index "fobos".i05_fk_talt041 on "fobos".talt041 (t41_compania,
    t41_modelo) using btree  in idxdbs ;
alter table "fobos".talt041 add constraint primary key (t41_compania,
    t41_localidad,t41_ano,t41_mes,t41_mecanico,t41_modelo,t41_moneda) 
    constraint "fobos".pk_talt041  ;
create unique index "fobos".i01_pk_gent019 on "fobos".gent019 
    (g19_codigo) using btree  in idxdbs ;
alter table "fobos".gent019 add constraint primary key (g19_codigo) 
    constraint "fobos".pk_gent019  ;
create index "fobos".i01_fk_talt010 on "fobos".talt010 (t10_compania) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_talt010 on "fobos".talt010 
    (t10_compania,t10_codcli,t10_modelo,t10_chasis) using btree 
     in idxdbs ;
create index "fobos".i02_fk_talt010 on "fobos".talt010 (t10_codcli) 
    using btree  in idxdbs ;
create index "fobos".i03_fk_talt010 on "fobos".talt010 (t10_compania,
    t10_modelo) using btree  in idxdbs ;
create index "fobos".i04_fk_talt010 on "fobos".talt010 (t10_usuario) 
    using btree  in idxdbs ;
alter table "fobos".talt010 add constraint primary key (t10_compania,
    t10_codcli,t10_modelo,t10_chasis) constraint "fobos".pk_talt010 
     ;
create index "fobos".i01_fk_veht023 on "fobos".veht023 (v23_compania,
    v23_localidad,v23_codigo_veh) using btree  in idxdbs ;
create unique index "fobos".i01_pk_veht023 on "fobos".veht023 
    (v23_compania,v23_localidad,v23_codigo_veh,v23_secuencia) 
    using btree  in idxdbs ;
create index "fobos".i02_fk_veht023 on "fobos".veht023 (v23_mon_costo) 
    using btree  in idxdbs ;
create index "fobos".i03_fk_veht023 on "fobos".veht023 (v23_usuario) 
    using btree  in idxdbs ;
alter table "fobos".veht023 add constraint primary key (v23_compania,
    v23_localidad,v23_codigo_veh,v23_secuencia) constraint "fobos"
    .pk_veht023  ;
create index "fobos".i01_fk_veht033 on "fobos".veht033 (v33_compania) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_veht033 on "fobos".veht033 
    (v33_compania,v33_localidad,v33_num_reserv) using btree  
    in idxdbs ;
create index "fobos".i02_fk_veht033 on "fobos".veht033 (v33_compania,
    v33_localidad) using btree  in idxdbs ;
create index "fobos".i03_fk_veht033 on "fobos".veht033 (v33_compania,
    v33_localidad,v33_codigo_veh) using btree  in idxdbs ;
create index "fobos".i04_fk_veht033 on "fobos".veht033 (v33_compania,
    v33_vendedor) using btree  in idxdbs ;
create index "fobos".i05_fk_veht033 on "fobos".veht033 (v33_compania,
    v33_localidad,v33_codcli,v33_tipo_doc,v33_num_doc) using 
    btree  in idxdbs ;
create index "fobos".i06_fk_veht033 on "fobos".veht033 (v33_usuario) 
    using btree  in idxdbs ;
alter table "fobos".veht033 add constraint primary key (v33_compania,
    v33_localidad,v33_num_reserv) constraint "fobos".pk_veht033 
     ;
create index "fobos".i01_fk_veht041 on "fobos".veht041 (v41_compania) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_veht041 on "fobos".veht041 
    (v41_compania,v41_localidad,v41_anio,v41_mes,v41_codigo_veh) 
    using btree  in idxdbs ;
create index "fobos".i02_fk_veht041 on "fobos".veht041 (v41_compania,
    v41_localidad) using btree  in idxdbs ;
create index "fobos".i03_fk_veht041 on "fobos".veht041 (v41_compania,
    v41_bodega) using btree  in idxdbs ;
create index "fobos".i04_fk_veht041 on "fobos".veht041 (v41_compania,
    v41_modelo) using btree  in idxdbs ;
create index "fobos".i05_fk_veht041 on "fobos".veht041 (v41_compania,
    v41_cod_color) using btree  in idxdbs ;
create index "fobos".i06_fk_veht041 on "fobos".veht041 (v41_moneda_liq) 
    using btree  in idxdbs ;
create index "fobos".i07_fk_veht041 on "fobos".veht041 (v41_compania,
    v41_localidad,v41_numero_liq) using btree  in idxdbs ;
create index "fobos".i08_fk_veht041 on "fobos".veht041 (v41_compania,
    v41_localidad,v41_pedido) using btree  in idxdbs ;
create index "fobos".i09_fk_veht041 on "fobos".veht041 (v41_moneda_ing) 
    using btree  in idxdbs ;
create index "fobos".i10_fk_veht041 on "fobos".veht041 (v41_moneda_prec) 
    using btree  in idxdbs ;
create index "fobos".i11_fk_veht041 on "fobos".veht041 (v41_compania,
    v41_localidad,v41_cod_tran,v41_num_tran) using btree  in 
    idxdbs ;
create index "fobos".i12_fk_veht041 on "fobos".veht041 (v41_usuario) 
    using btree  in idxdbs ;
alter table "fobos".veht041 add constraint primary key (v41_compania,
    v41_localidad,v41_anio,v41_mes,v41_codigo_veh) constraint 
    "fobos".pk_veht041  ;
create index "fobos".i01_fk_cxct021 on "fobos".cxct021 (z21_compania,
    z21_localidad,z21_codcli) using btree  in idxdbs ;
create unique index "fobos".i01_pk_cxct021 on "fobos".cxct021 
    (z21_compania,z21_localidad,z21_codcli,z21_tipo_doc,z21_num_doc) 
    using btree  in idxdbs ;
create index "fobos".i02_fk_cxct021 on "fobos".cxct021 (z21_tipo_doc) 
    using btree  in idxdbs ;
create index "fobos".i03_fk_cxct021 on "fobos".cxct021 (z21_compania,
    z21_areaneg) using btree  in idxdbs ;
create index "fobos".i04_fk_cxct021 on "fobos".cxct021 (z21_moneda) 
    using btree  in idxdbs ;
create index "fobos".i05_fk_cxct021 on "fobos".cxct021 (z21_usuario) 
    using btree  in idxdbs ;
create index "fobos".i06_fk_cxct021 on "fobos".cxct021 (z21_compania,
    z21_linea) using btree  in idxdbs ;
alter table "fobos".cxct021 add constraint primary key (z21_compania,
    z21_localidad,z21_codcli,z21_tipo_doc,z21_num_doc) constraint 
    "fobos".pk_cxct021  ;
create index "fobos".i01_fk_cxct023 on "fobos".cxct023 (z23_compania,
    z23_localidad,z23_codcli,z23_tipo_doc,z23_num_doc,z23_div_doc) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_cxct023 on "fobos".cxct023 
    (z23_compania,z23_localidad,z23_codcli,z23_tipo_trn,z23_num_trn,
    z23_orden) using btree  in idxdbs ;
create index "fobos".i02_fk_cxct023 on "fobos".cxct023 (z23_compania,
    z23_localidad,z23_codcli,z23_tipo_trn,z23_num_trn) using 
    btree  in idxdbs ;
create index "fobos".i03_fk_cxct023 on "fobos".cxct023 (z23_compania,
    z23_areaneg) using btree  in idxdbs ;
create index "fobos".i04_fk_cxct023 on "fobos".cxct023 (z23_compania,
    z23_localidad,z23_codcli,z23_tipo_favor,z23_doc_favor) using 
    btree  in idxdbs ;
alter table "fobos".cxct023 add constraint primary key (z23_compania,
    z23_localidad,z23_codcli,z23_tipo_trn,z23_num_trn,z23_orden) 
    constraint "fobos".pk_cxct023  ;
create index "fobos".i01_fk_cxct050 on "fobos".cxct050 (z50_compania,
    z50_localidad,z50_codcli) using btree  in idxdbs ;
create unique index "fobos".i01_pk_cxct050 on "fobos".cxct050 
    (z50_ano,z50_mes,z50_compania,z50_localidad,z50_codcli,z50_tipo_doc,
    z50_num_doc,z50_dividendo) using btree  in idxdbs ;
create index "fobos".i02_fk_cxct050 on "fobos".cxct050 (z50_tipo_doc) 
    using btree  in idxdbs ;
create index "fobos".i03_fk_cxct050 on "fobos".cxct050 (z50_compania,
    z50_areaneg) using btree  in idxdbs ;
create index "fobos".i04_fk_cxct050 on "fobos".cxct050 (z50_moneda) 
    using btree  in idxdbs ;
create index "fobos".i05_fk_cxct050 on "fobos".cxct050 (z50_compania,
    z50_linea) using btree  in idxdbs ;
create index "fobos".i06_fk_cxct050 on "fobos".cxct050 (z50_usuario) 
    using btree  in idxdbs ;
alter table "fobos".cxct050 add constraint primary key (z50_ano,
    z50_mes,z50_compania,z50_localidad,z50_codcli,z50_tipo_doc,
    z50_num_doc,z50_dividendo) constraint "fobos".pk_cxct050  
    ;
create index "fobos".i01_fk_cxct051 on "fobos".cxct051 (z51_compania,
    z51_localidad,z51_codcli) using btree  in idxdbs ;
create unique index "fobos".i01_pk_cxct051 on "fobos".cxct051 
    (z51_ano,z51_mes,z51_compania,z51_localidad,z51_codcli,z51_tipo_doc,
    z51_num_doc) using btree  in idxdbs ;
create index "fobos".i02_fk_cxct051 on "fobos".cxct051 (z51_tipo_doc) 
    using btree  in idxdbs ;
create index "fobos".i03_fk_cxct051 on "fobos".cxct051 (z51_compania,
    z51_areaneg) using btree  in idxdbs ;
create index "fobos".i04_fk_cxct051 on "fobos".cxct051 (z51_moneda) 
    using btree  in idxdbs ;
create index "fobos".i05_fk_cxct051 on "fobos".cxct051 (z51_usuario) 
    using btree  in idxdbs ;
alter table "fobos".cxct051 add constraint primary key (z51_ano,
    z51_mes,z51_compania,z51_localidad,z51_codcli,z51_tipo_doc,
    z51_num_doc) constraint "fobos".pk_cxct051  ;
create index "fobos".i01_fk_veht038 on "fobos".veht038 (v38_compania) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_veht038 on "fobos".veht038 
    (v38_compania,v38_localidad,v38_orden_cheq) using btree  
    in idxdbs ;
create index "fobos".i02_fk_veht038 on "fobos".veht038 (v38_compania,
    v38_localidad) using btree  in idxdbs ;
create index "fobos".i03_fk_veht038 on "fobos".veht038 (v38_compania,
    v38_localidad,v38_codigo_veh) using btree  in idxdbs ;
create index "fobos".i04_fk_veht038 on "fobos".veht038 (v38_compania,
    v38_localidad,v38_num_ot) using btree  in idxdbs ;
create index "fobos".i05_fk_veht038 on "fobos".veht038 (v38_usuario) 
    using btree  in idxdbs ;
alter table "fobos".veht038 add constraint primary key (v38_compania,
    v38_localidad,v38_orden_cheq) constraint "fobos".pk_veht038 
     ;
create index "fobos".i01_fk_veht022 on "fobos".veht022 (v22_compania,
    v22_localidad,v22_cod_tran,v22_num_tran) using btree  in 
    idxdbs ;
create unique index "fobos".i01_pk_veht022 on "fobos".veht022 
    (v22_compania,v22_localidad,v22_codigo_veh) using btree  
    in idxdbs ;
create index "fobos".i02_fk_veht022 on "fobos".veht022 (v22_compania) 
    using btree  in idxdbs ;
create index "fobos".i03_fk_veht022 on "fobos".veht022 (v22_compania,
    v22_localidad) using btree  in idxdbs ;
create index "fobos".i04_fk_veht022 on "fobos".veht022 (v22_compania,
    v22_bodega) using btree  in idxdbs ;
create index "fobos".i05_fk_veht022 on "fobos".veht022 (v22_compania,
    v22_modelo) using btree  in idxdbs ;
create index "fobos".i06_fk_veht022 on "fobos".veht022 (v22_compania,
    v22_cod_color) using btree  in idxdbs ;
create index "fobos".i07_fk_veht022 on "fobos".veht022 (v22_moneda_liq) 
    using btree  in idxdbs ;
create index "fobos".i08_fk_veht022 on "fobos".veht022 (v22_compania,
    v22_localidad,v22_numero_liq) using btree  in idxdbs ;
create index "fobos".i09_fk_veht022 on "fobos".veht022 (v22_compania,
    v22_localidad,v22_pedido) using btree  in idxdbs ;
create index "fobos".i10_fk_veht022 on "fobos".veht022 (v22_moneda_ing) 
    using btree  in idxdbs ;
create index "fobos".i11_fk_veht022 on "fobos".veht022 (v22_moneda_prec) 
    using btree  in idxdbs ;
create index "fobos".i12_fk_veht022 on "fobos".veht022 (v22_usuario) 
    using btree  in idxdbs ;
alter table "fobos".veht022 add constraint primary key (v22_compania,
    v22_localidad,v22_codigo_veh) constraint "fobos".pk_veht022 
     ;
create index "fobos".i01_fk_cxct024 on "fobos".cxct024 (z24_compania,
    z24_localidad,z24_codcli) using btree  in idxdbs ;
create unique index "fobos".i01_pk_cxct024 on "fobos".cxct024 
    (z24_compania,z24_localidad,z24_numero_sol) using btree  
    in idxdbs ;
create index "fobos".i02_fk_cxct024 on "fobos".cxct024 (z24_compania,
    z24_areaneg) using btree  in idxdbs ;
create index "fobos".i03_fk_cxct024 on "fobos".cxct024 (z24_moneda) 
    using btree  in idxdbs ;
create index "fobos".i04_fk_cxct024 on "fobos".cxct024 (z24_compania,
    z24_cobrador) using btree  in idxdbs ;
create index "fobos".i05_fk_cxct024 on "fobos".cxct024 (z24_usuario) 
    using btree  in idxdbs ;
create index "fobos".i06_fk_cxct024 on "fobos".cxct024 (z24_compania,
    z24_linea) using btree  in idxdbs ;
create index "fobos".i07_fk_cxct024 on "fobos".cxct024 (z24_zona_cobro) 
    using btree  in idxdbs ;
alter table "fobos".cxct024 add constraint primary key (z24_compania,
    z24_localidad,z24_numero_sol) constraint "fobos".pk_cxct024 
     ;
create index "fobos".i01_fk_cxct025 on "fobos".cxct025 (z25_compania,
    z25_localidad,z25_codcli,z25_tipo_doc,z25_num_doc,z25_dividendo) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_cxct025 on "fobos".cxct025 
    (z25_compania,z25_localidad,z25_numero_sol,z25_orden) using 
    btree  in idxdbs ;
create index "fobos".i02_fk_cxct025 on "fobos".cxct025 (z25_compania,
    z25_localidad,z25_numero_sol) using btree  in idxdbs ;
alter table "fobos".cxct025 add constraint primary key (z25_compania,
    z25_localidad,z25_numero_sol,z25_orden) constraint "fobos"
    .pk_cxct025  ;
create index "fobos".i01_fk_cxpt020 on "fobos".cxpt020 (p20_compania,
    p20_localidad,p20_codprov) using btree  in idxdbs ;
create unique index "fobos".i01_pk_cxpt020 on "fobos".cxpt020 
    (p20_compania,p20_localidad,p20_codprov,p20_tipo_doc,p20_num_doc,
    p20_dividendo) using btree  in idxdbs ;
create index "fobos".i02_fk_cxpt020 on "fobos".cxpt020 (p20_tipo_doc) 
    using btree  in idxdbs ;
create index "fobos".i03_fk_cxpt020 on "fobos".cxpt020 (p20_moneda) 
    using btree  in idxdbs ;
create index "fobos".i04_fk_cxpt020 on "fobos".cxpt020 (p20_compania,
    p20_localidad,p20_numero_oc) using btree  in idxdbs ;
create index "fobos".i05_fk_cxpt020 on "fobos".cxpt020 (p20_usuario) 
    using btree  in idxdbs ;
create index "fobos".i06_fk_cxpt020 on "fobos".cxpt020 (p20_cod_depto) 
    using btree  in idxdbs ;
create index "fobos".i08_fk_cxpt020 on "fobos".cxpt020 (p20_codprov) 
    using btree  in idxdbs ;
alter table "fobos".cxpt020 add constraint primary key (p20_compania,
    p20_localidad,p20_codprov,p20_tipo_doc,p20_num_doc,p20_dividendo) 
    constraint "fobos".pk_cxpt020  ;
create index "fobos".i01_fk_cxpt021 on "fobos".cxpt021 (p21_compania,
    p21_localidad,p21_orden_pago) using btree  in idxdbs ;
create unique index "fobos".i01_pk_cxpt021 on "fobos".cxpt021 
    (p21_compania,p21_localidad,p21_codprov,p21_tipo_doc,p21_num_doc) 
    using btree  in idxdbs ;
create index "fobos".i02_fk_cxpt021 on "fobos".cxpt021 (p21_compania,
    p21_localidad,p21_codprov) using btree  in idxdbs ;
create index "fobos".i03_fk_cxpt021 on "fobos".cxpt021 (p21_tipo_doc) 
    using btree  in idxdbs ;
create index "fobos".i04_fk_cxpt021 on "fobos".cxpt021 (p21_moneda) 
    using btree  in idxdbs ;
create index "fobos".i05_fk_cxpt021 on "fobos".cxpt021 (p21_usuario) 
    using btree  in idxdbs ;
create index "fobos".i06_fk_cxpt021 on "fobos".cxpt021 (p21_codprov) 
    using btree  in idxdbs ;
alter table "fobos".cxpt021 add constraint primary key (p21_compania,
    p21_localidad,p21_codprov,p21_tipo_doc,p21_num_doc) constraint 
    "fobos".pk_cxpt021  ;
create index "fobos".i01_fk_cxpt022 on "fobos".cxpt022 (p22_compania,
    p22_localidad,p22_orden_pago) using btree  in idxdbs ;
create unique index "fobos".i01_pk_cxpt022 on "fobos".cxpt022 
    (p22_compania,p22_localidad,p22_codprov,p22_tipo_trn,p22_num_trn) 
    using btree  in idxdbs ;
create index "fobos".i02_fk_cxpt022 on "fobos".cxpt022 (p22_compania,
    p22_localidad,p22_codprov) using btree  in idxdbs ;
create index "fobos".i03_fk_cxpt022 on "fobos".cxpt022 (p22_tipo_trn) 
    using btree  in idxdbs ;
create index "fobos".i04_fk_cxpt022 on "fobos".cxpt022 (p22_moneda) 
    using btree  in idxdbs ;
create index "fobos".i05_fk_cxpt022 on "fobos".cxpt022 (p22_usuario) 
    using btree  in idxdbs ;
create index "fobos".i06_fk_cxpt022 on "fobos".cxpt022 (p22_compania,
    p22_localidad,p22_codprov,p22_tiptrn_elim,p22_numtrn_elim) 
    using btree  in idxdbs ;
alter table "fobos".cxpt022 add constraint primary key (p22_compania,
    p22_localidad,p22_codprov,p22_tipo_trn,p22_num_trn) constraint 
    "fobos".pk_cxpt022  ;
create index "fobos".i01_fk_cxpt050 on "fobos".cxpt050 (p50_compania,
    p50_localidad,p50_codprov) using btree  in idxdbs ;
create unique index "fobos".i01_pk_cxpt050 on "fobos".cxpt050 
    (p50_ano,p50_mes,p50_compania,p50_localidad,p50_codprov,p50_tipo_doc,
    p50_num_doc,p50_dividendo) using btree  in idxdbs ;
create index "fobos".i02_fk_cxpt050 on "fobos".cxpt050 (p50_tipo_doc) 
    using btree  in idxdbs ;
create index "fobos".i03_fk_cxpt050 on "fobos".cxpt050 (p50_moneda) 
    using btree  in idxdbs ;
create index "fobos".i04_fk_cxpt050 on "fobos".cxpt050 (p50_compania,
    p50_localidad,p50_numero_oc) using btree  in idxdbs ;
create index "fobos".i05_fk_cxpt050 on "fobos".cxpt050 (p50_usuario) 
    using btree  in idxdbs ;
create index "fobos".i06_fk_cxpt050 on "fobos".cxpt050 (p50_cod_depto) 
    using btree  in idxdbs ;
alter table "fobos".cxpt050 add constraint primary key (p50_ano,
    p50_mes,p50_compania,p50_localidad,p50_codprov,p50_tipo_doc,
    p50_num_doc,p50_dividendo) constraint "fobos".pk_cxpt050  
    ;
create index "fobos".i01_fk_cxpt051 on "fobos".cxpt051 (p51_compania,
    p51_localidad,p51_codprov) using btree  in idxdbs ;
create unique index "fobos".i01_pk_cxpt051 on "fobos".cxpt051 
    (p51_ano,p51_mes,p51_compania,p51_localidad,p51_codprov,p51_tipo_doc,
    p51_num_doc) using btree  in idxdbs ;
create index "fobos".i02_fk_cxpt051 on "fobos".cxpt051 (p51_tipo_doc) 
    using btree  in idxdbs ;
create index "fobos".i03_fk_cxpt051 on "fobos".cxpt051 (p51_moneda) 
    using btree  in idxdbs ;
create index "fobos".i04_fk_cxpt051 on "fobos".cxpt051 (p51_usuario) 
    using btree  in idxdbs ;
alter table "fobos".cxpt051 add constraint primary key (p51_ano,
    p51_mes,p51_compania,p51_localidad,p51_codprov,p51_tipo_doc,
    p51_num_doc) constraint "fobos".pk_cxpt051  ;
create index "fobos".i01_fk_cxpt023 on "fobos".cxpt023 (p23_compania,
    p23_localidad,p23_codprov,p23_tipo_doc,p23_num_doc,p23_div_doc) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_cxpt023 on "fobos".cxpt023 
    (p23_compania,p23_localidad,p23_codprov,p23_tipo_trn,p23_num_trn,
    p23_orden) using btree  in idxdbs ;
create index "fobos".i02_fk_cxpt023 on "fobos".cxpt023 (p23_compania,
    p23_localidad,p23_codprov,p23_tipo_trn,p23_num_trn) using 
    btree  in idxdbs ;
create index "fobos".i03_fk_cxpt023 on "fobos".cxpt023 (p23_compania,
    p23_localidad,p23_codprov,p23_tipo_favor,p23_doc_favor) using 
    btree  in idxdbs ;
alter table "fobos".cxpt023 add constraint primary key (p23_compania,
    p23_localidad,p23_codprov,p23_tipo_trn,p23_num_trn,p23_orden) 
    constraint "fobos".pk_cxpt023  ;
create index "fobos".i01_fk_cxpt024 on "fobos".cxpt024 (p24_compania,
    p24_localidad,p24_codprov) using btree  in idxdbs ;
create unique index "fobos".i01_pk_cxpt024 on "fobos".cxpt024 
    (p24_compania,p24_localidad,p24_orden_pago) using btree  
    in idxdbs ;
create index "fobos".i02_fk_cxpt024 on "fobos".cxpt024 (p24_moneda) 
    using btree  in idxdbs ;
create index "fobos".i03_fk_cxpt024 on "fobos".cxpt024 (p24_compania,
    p24_banco,p24_numero_cta) using btree  in idxdbs ;
create index "fobos".i04_fk_cxpt024 on "fobos".cxpt024 (p24_compania,
    p24_tip_contable,p24_num_contable) using btree  in idxdbs 
    ;
create index "fobos".i05_fk_cxpt024 on "fobos".cxpt024 (p24_usuario) 
    using btree  in idxdbs ;
alter table "fobos".cxpt024 add constraint primary key (p24_compania,
    p24_localidad,p24_orden_pago) constraint "fobos".pk_cxpt024 
     ;
create index "fobos".i01_fk_cxpt027 on "fobos".cxpt027 (p27_compania,
    p27_localidad,p27_codprov) using btree  in idxdbs ;
create unique index "fobos".i01_pk_cxpt027 on "fobos".cxpt027 
    (p27_compania,p27_localidad,p27_num_ret) using btree  in 
    idxdbs ;
create index "fobos".i02_fk_cxpt027 on "fobos".cxpt027 (p27_moneda) 
    using btree  in idxdbs ;
create index "fobos".i03_fk_cxpt027 on "fobos".cxpt027 (p27_compania,
    p27_tip_contable,p27_num_contable) using btree  in idxdbs 
    ;
create index "fobos".i04_fk_cxpt027 on "fobos".cxpt027 (p27_compania,
    p27_tip_cont_eli,p27_num_cont_eli) using btree  in idxdbs 
    ;
create index "fobos".i05_fk_cxpt027 on "fobos".cxpt027 (p27_usuario) 
    using btree  in idxdbs ;
alter table "fobos".cxpt027 add constraint primary key (p27_compania,
    p27_localidad,p27_num_ret) constraint "fobos".pk_cxpt027  
    ;
create index "fobos".i01_fk_ordt002 on "fobos".ordt002 (c02_compania) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_ordt002 on "fobos".ordt002 
    (c02_compania,c02_tipo_ret,c02_porcentaje) using btree  in 
    idxdbs ;
create index "fobos".i02_fk_ordt002 on "fobos".ordt002 (c02_compania,
    c02_aux_cont) using btree  in idxdbs ;
create index "fobos".i03_fk_ordt002 on "fobos".ordt002 (c02_usuario) 
    using btree  in idxdbs ;
alter table "fobos".ordt002 add constraint primary key (c02_compania,
    c02_tipo_ret,c02_porcentaje) constraint "fobos".pk_ordt002 
     ;
create index "fobos".i01_fk_actt010 on "fobos".actt010 (a10_compania) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_actt010 on "fobos".actt010 
    (a10_compania,a10_codigo_bien) using btree  in idxdbs ;
create index "fobos".i02_fk_actt010 on "fobos".actt010 (a10_compania,
    a10_grupo_act) using btree  in idxdbs ;
create index "fobos".i03_fk_actt010 on "fobos".actt010 (a10_compania,
    a10_tipo_act) using btree  in idxdbs ;
create index "fobos".i04_fk_actt010 on "fobos".actt010 (a10_compania,
    a10_locali_ori) using btree  in idxdbs ;
create index "fobos".i05_fk_actt010 on "fobos".actt010 (a10_compania,
    a10_localidad) using btree  in idxdbs ;
create index "fobos".i06_fk_actt010 on "fobos".actt010 (a10_compania,
    a10_locali_ori,a10_numero_oc) using btree  in idxdbs ;
create index "fobos".i07_fk_actt010 on "fobos".actt010 (a10_compania,
    a10_cod_depto) using btree  in idxdbs ;
create index "fobos".i08_fk_actt010 on "fobos".actt010 (a10_compania,
    a10_locali_ori,a10_codprov) using btree  in idxdbs ;
create index "fobos".i09_fk_actt010 on "fobos".actt010 (a10_moneda) 
    using btree  in idxdbs ;
create index "fobos".i10_fk_actt010 on "fobos".actt010 (a10_compania,
    a10_responsable) using btree  in idxdbs ;
create index "fobos".i11_fk_actt010 on "fobos".actt010 (a10_usuario) 
    using btree  in idxdbs ;
create index "fobos".i12_fk_actt006 on "fobos".actt010 (a10_compania,
    a10_estado) using btree  in idxdbs ;
alter table "fobos".actt010 add constraint primary key (a10_compania,
    a10_codigo_bien) constraint "fobos".pk_actt010  ;
create index "fobos".i01_fk_actt001 on "fobos".actt001 (a01_compania) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_actt001 on "fobos".actt001 
    (a01_compania,a01_grupo_act) using btree  in idxdbs ;
create index "fobos".i02_fk_actt001 on "fobos".actt001 (a01_compania,
    a01_aux_activo) using btree  in idxdbs ;
create index "fobos".i03_fk_actt001 on "fobos".actt001 (a01_compania,
    a01_aux_reexpr) using btree  in idxdbs ;
create index "fobos".i04_fk_actt001 on "fobos".actt001 (a01_compania,
    a01_aux_dep_act) using btree  in idxdbs ;
create index "fobos".i05_fk_actt001 on "fobos".actt001 (a01_compania,
    a01_aux_dep_reex) using btree  in idxdbs ;
create index "fobos".i06_fk_actt001 on "fobos".actt001 (a01_usuario) 
    using btree  in idxdbs ;
create index "fobos".i07_fk_actt001 on "fobos".actt001 (a01_compania,
    a01_aux_pago) using btree  in idxdbs ;
create index "fobos".i08_fk_actt001 on "fobos".actt001 (a01_compania,
    a01_aux_iva) using btree  in idxdbs ;
create index "fobos".i09_fk_actt001 on "fobos".actt001 (a01_compania,
    a01_aux_venta) using btree  in idxdbs ;
create index "fobos".i10_fk_actt001 on "fobos".actt001 (a01_compania,
    a01_aux_gasto) using btree  in idxdbs ;
create index "fobos".i11_fk_actt001 on "fobos".actt001 (a01_compania,
    a01_aux_transf) using btree  in idxdbs ;
alter table "fobos".actt001 add constraint primary key (a01_compania,
    a01_grupo_act) constraint "fobos".pk_actt001  ;
create index "fobos".i01_fk_actt002 on "fobos".actt002 (a02_compania,
    a02_grupo_act) using btree  in idxdbs ;
create unique index "fobos".i01_pk_actt002 on "fobos".actt002 
    (a02_compania,a02_tipo_act) using btree  in idxdbs ;
create index "fobos".i02_fk_actt002 on "fobos".actt002 (a02_usuario) 
    using btree  in idxdbs ;
alter table "fobos".actt002 add constraint primary key (a02_compania,
    a02_tipo_act) constraint "fobos".pk_actt002  ;
create index "fobos".i01_fk_rept024 on "fobos".rept024 (r24_compania,
    r24_localidad,r24_numprev) using btree  in idxdbs ;
create index "fobos".i02_fk_rept024 on "fobos".rept024 (r24_compania,
    r24_item) using btree  in idxdbs ;
create index "fobos".i03_fk_rept024 on "fobos".rept024 (r24_compania,
    r24_linea) using btree  in idxdbs ;
create index "fobos".i01_fk_veht003 on "fobos".veht003 (v03_compania) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_veht003 on "fobos".veht003 
    (v03_compania,v03_linea) using btree  in idxdbs ;
create index "fobos".i02_fk_veht003 on "fobos".veht003 (v03_compania,
    v03_grupo_linea) using btree  in idxdbs ;
create index "fobos".i03_fk_veht003 on "fobos".veht003 (v03_usuario) 
    using btree  in idxdbs ;
alter table "fobos".veht003 add constraint primary key (v03_compania,
    v03_linea) constraint "fobos".pk_veht003  ;
create index "fobos".i01_fk_talt021 on "fobos".talt021 (t21_compania,
    t21_localidad,t21_numpre) using btree  in idxdbs ;
create unique index "fobos".i01_pk_talt021 on "fobos".talt021 
    (t21_compania,t21_localidad,t21_numpre,t21_codtarea,t21_secuencia) 
    using btree  in idxdbs ;
create index "fobos".i02_fk_talt021 on "fobos".talt021 (t21_usuario) 
    using btree  in idxdbs ;
create index "fobos".i03_fk_talt021 on "fobos".talt021 (t21_compania,
    t21_codtarea) using btree  in idxdbs ;
alter table "fobos".talt021 add constraint primary key (t21_compania,
    t21_localidad,t21_numpre,t21_codtarea,t21_secuencia) constraint 
    "fobos".pk_talt021  ;
create index "fobos".i01_fk_cxct022 on "fobos".cxct022 (z22_compania,
    z22_localidad,z22_codcli,z22_tiptrn_elim,z22_numtrn_elim) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_cxct022 on "fobos".cxct022 
    (z22_compania,z22_localidad,z22_codcli,z22_tipo_trn,z22_num_trn) 
    using btree  in idxdbs ;
create index "fobos".i02_fk_cxct022 on "fobos".cxct022 (z22_compania,
    z22_localidad,z22_codcli) using btree  in idxdbs ;
create index "fobos".i03_fk_cxct022 on "fobos".cxct022 (z22_tipo_trn) 
    using btree  in idxdbs ;
create index "fobos".i04_fk_cxct022 on "fobos".cxct022 (z22_compania,
    z22_areaneg) using btree  in idxdbs ;
create index "fobos".i05_fk_cxct022 on "fobos".cxct022 (z22_moneda) 
    using btree  in idxdbs ;
create index "fobos".i06_fk_cxct022 on "fobos".cxct022 (z22_compania,
    z22_cobrador) using btree  in idxdbs ;
create index "fobos".i07_fk_cxct022 on "fobos".cxct022 (z22_usuario) 
    using btree  in idxdbs ;
create index "fobos".i08_fk_cxct022 on "fobos".cxct022 (z22_zona_cobro) 
    using btree  in idxdbs ;
alter table "fobos".cxct022 add constraint primary key (z22_compania,
    z22_localidad,z22_codcli,z22_tipo_trn,z22_num_trn) constraint 
    "fobos".pk_cxct022  ;
create index "fobos".i01_fk_rept027 on "fobos".rept027 (r27_compania,
    r27_localidad,r27_numprev) using btree  in idxdbs ;
create unique index "fobos".i01_pk_rept027 on "fobos".rept027 
    (r27_compania,r27_localidad,r27_numprev,r27_tipo,r27_numero) 
    using btree  in idxdbs ;
create index "fobos".i02_fk_rept027 on "fobos".rept027 (r27_tipo) 
    using btree  in idxdbs ;
alter table "fobos".rept027 add constraint primary key (r27_compania,
    r27_localidad,r27_numprev,r27_tipo,r27_numero) constraint 
    "fobos".pk_rept027  ;
create index "fobos".i01_fk_veht031 on "fobos".veht031 (v31_moneda_cost) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_veht031 on "fobos".veht031 
    (v31_compania,v31_localidad,v31_cod_tran,v31_num_tran,v31_codigo_veh) 
    using btree  in idxdbs ;
create index "fobos".i02_fk_veht031 on "fobos".veht031 (v31_compania,
    v31_localidad,v31_cod_tran,v31_num_tran) using btree  in 
    idxdbs ;
create index "fobos".i03_fk_veht031 on "fobos".veht031 (v31_compania,
    v31_localidad,v31_codigo_veh) using btree  in idxdbs ;
alter table "fobos".veht031 add constraint primary key (v31_compania,
    v31_localidad,v31_cod_tran,v31_num_tran,v31_codigo_veh) constraint 
    "fobos".pk_veht031  ;
create index "fobos".i01_fk_gent023 on "fobos".gent023 (g23_compania,
    g23_localidad) using btree  in idxdbs ;
create unique index "fobos".i01_pk_gent023 on "fobos".gent023 
    (g23_compania,g23_localidad,g23_modulo) using btree  in idxdbs 
    ;
create index "fobos".i02_fk_gent023 on "fobos".gent023 (g23_modulo) 
    using btree  in idxdbs ;
alter table "fobos".gent023 add constraint primary key (g23_compania,
    g23_localidad,g23_modulo) constraint "fobos".pk_gent023  ;
    
create index "fobos".i01_fk_talt028 on "fobos".talt028 (t28_compania) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_talt028 on "fobos".talt028 
    (t28_compania,t28_localidad,t28_num_dev) using btree  in 
    idxdbs ;
create index "fobos".i02_fk_talt028 on "fobos".talt028 (t28_compania,
    t28_localidad) using btree  in idxdbs ;
create index "fobos".i03_fk_talt028 on "fobos".talt028 (t28_compania,
    t28_localidad,t28_ot_ant) using btree  in idxdbs ;
create index "fobos".i04_fk_talt028 on "fobos".talt028 (t28_compania,
    t28_localidad,t28_ot_nue) using btree  in idxdbs ;
create index "fobos".i05_fk_talt028 on "fobos".talt028 (t28_usuario) 
    using btree  in idxdbs ;
alter table "fobos".talt028 add constraint primary key (t28_compania,
    t28_localidad,t28_num_dev) constraint "fobos".pk_talt028  
    ;
create index "fobos".i01_fk_talt029 on "fobos".talt029 (t29_compania,
    t29_localidad,t29_num_dev) using btree  in idxdbs ;
create unique index "fobos".i01_pk_talt029 on "fobos".talt029 
    (t29_compania,t29_localidad,t29_num_dev,t29_secuencia) using 
    btree  in idxdbs ;
create index "fobos".i02_fk_talt029 on "fobos".talt029 (t29_compania,
    t29_localidad,t29_oc_ant) using btree  in idxdbs ;
create index "fobos".i03_fk_talt029 on "fobos".talt029 (t29_compania,
    t29_localidad,t29_oc_nue) using btree  in idxdbs ;
alter table "fobos".talt029 add constraint primary key (t29_compania,
    t29_localidad,t29_num_dev,t29_secuencia) constraint "fobos"
    .pk_talt029  ;
create index "fobos".i01_fk_cxct020 on "fobos".cxct020 (z20_compania,
    z20_localidad,z20_codcli) using btree  in idxdbs ;
create unique index "fobos".i01_pk_cxct020 on "fobos".cxct020 
    (z20_compania,z20_localidad,z20_codcli,z20_tipo_doc,z20_num_doc,
    z20_dividendo) using btree  in idxdbs ;
create index "fobos".i02_fk_cxct020 on "fobos".cxct020 (z20_tipo_doc) 
    using btree  in idxdbs ;
create index "fobos".i03_fk_cxct020 on "fobos".cxct020 (z20_compania,
    z20_areaneg) using btree  in idxdbs ;
create index "fobos".i04_fk_cxct020 on "fobos".cxct020 (z20_moneda) 
    using btree  in idxdbs ;
create index "fobos".i05_fk_cxct020 on "fobos".cxct020 (z20_compania,
    z20_linea) using btree  in idxdbs ;
create index "fobos".i06_fk_cxct020 on "fobos".cxct020 (z20_usuario) 
    using btree  in idxdbs ;
alter table "fobos".cxct020 add constraint primary key (z20_compania,
    z20_localidad,z20_codcli,z20_tipo_doc,z20_num_doc,z20_dividendo) 
    constraint "fobos".pk_cxct020  ;
create index "fobos".i01_fk_ordt015 on "fobos".ordt015 (c15_compania,
    c15_localidad,c15_numero_oc,c15_num_recep) using btree  in 
    idxdbs ;
create unique index "fobos".i01_pk_ordt015 on "fobos".ordt015 
    (c15_compania,c15_localidad,c15_numero_oc,c15_num_recep,c15_dividendo) 
    using btree  in idxdbs ;
alter table "fobos".ordt015 add constraint primary key (c15_compania,
    c15_localidad,c15_numero_oc,c15_num_recep,c15_dividendo) 
    constraint "fobos".pk_ordt015  ;
create index "fobos".i01_fk_ordt016 on "fobos".ordt016 (c16_compania) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_ordt016 on "fobos".ordt016 
    (c16_compania,c16_localidad,c16_ano,c16_mes,c16_cod_depto,
    c16_codprov,c16_moneda) using btree  in idxdbs ;
create index "fobos".i02_fk_ordt016 on "fobos".ordt016 (c16_compania,
    c16_cod_depto) using btree  in idxdbs ;
create index "fobos".i03_fk_ordt016 on "fobos".ordt016 (c16_compania,
    c16_localidad,c16_codprov) using btree  in idxdbs ;
create index "fobos".i04_fk_ordt016 on "fobos".ordt016 (c16_moneda) 
    using btree  in idxdbs ;
alter table "fobos".ordt016 add constraint primary key (c16_compania,
    c16_localidad,c16_ano,c16_mes,c16_cod_depto,c16_codprov,c16_moneda) 
    constraint "fobos".pk_ordt016  ;
create index "fobos".i01_fk_cxpt005 on "fobos".cxpt005 (p05_compania) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_cxpt005 on "fobos".cxpt005 
    (p05_compania,p05_codprov,p05_tipo_ret,p05_porcentaje,p05_codigo_sri,
    p05_fecha_ini_porc) using btree  in idxdbs ;
create index "fobos".i02_fk_cxpt005 on "fobos".cxpt005 (p05_codprov) 
    using btree  in idxdbs ;
create index "fobos".i04_fk_cxpt005 on "fobos".cxpt005 (p05_compania,
    p05_tipo_ret,p05_porcentaje,p05_codigo_sri,p05_fecha_ini_porc) 
    using btree  in idxdbs ;
alter table "fobos".cxpt005 add constraint primary key (p05_compania,
    p05_codprov,p05_tipo_ret,p05_porcentaje,p05_codigo_sri,p05_fecha_ini_porc) 
    constraint "fobos".pk_cxpt005  ;
create index "fobos".i01_fk_cxpt030 on "fobos".cxpt030 (p30_compania,
    p30_localidad,p30_codprov) using btree  in idxdbs ;
create unique index "fobos".i01_pk_cxpt030 on "fobos".cxpt030 
    (p30_compania,p30_localidad,p30_codprov,p30_moneda) using 
    btree  in idxdbs ;
create index "fobos".i02_fk_cxpt030 on "fobos".cxpt030 (p30_moneda) 
    using btree  in idxdbs ;
alter table "fobos".cxpt030 add constraint primary key (p30_compania,
    p30_localidad,p30_codprov,p30_moneda) constraint "fobos".pk_cxpt030 
     ;
create index "fobos".i01_fk_cxpt031 on "fobos".cxpt031 (p31_compania) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_cxpt031 on "fobos".cxpt031 
    (p31_compania,p31_ano,p31_mes,p31_localidad,p31_cartera,p31_tipo_prov,
    p31_moneda) using btree  in idxdbs ;
create index "fobos".i02_fk_cxpt031 on "fobos".cxpt031 (p31_compania,
    p31_localidad) using btree  in idxdbs ;
create index "fobos".i03_fk_cxpt031 on "fobos".cxpt031 (p31_moneda) 
    using btree  in idxdbs ;
alter table "fobos".cxpt031 add constraint primary key (p31_compania,
    p31_ano,p31_mes,p31_localidad,p31_cartera,p31_tipo_prov,p31_moneda) 
    constraint "fobos".pk_cxpt031  ;
create index "fobos".i01_fk_rept030 on "fobos".rept030 (r30_compania,
    r30_localidad,r30_numliq) using btree  in idxdbs ;
create unique index "fobos".i01_pk_rept030 on "fobos".rept030 
    (r30_compania,r30_localidad,r30_numliq,r30_serial) using 
    btree  in idxdbs ;
create index "fobos".i02_fk_rept030 on "fobos".rept030 (r30_codrubro) 
    using btree  in idxdbs ;
create index "fobos".i03_fk_rept030 on "fobos".rept030 (r30_moneda) 
    using btree  in idxdbs ;
alter table "fobos".rept030 add constraint primary key (r30_compania,
    r30_localidad,r30_numliq,r30_serial) constraint "fobos".pk_rept030 
     ;
create index "fobos".i01_fk_gent021 on "fobos".gent021 (g21_usuario) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_gent021 on "fobos".gent021 
    (g21_cod_tran) using btree  in idxdbs ;
alter table "fobos".gent021 add constraint primary key (g21_cod_tran) 
    constraint "fobos".pk_gent021  ;
create index "fobos".i01_fk_cajt004 on "fobos".cajt004 (j04_compania,
    j04_localidad,j04_codigo_caja) using btree  in idxdbs ;
create unique index "fobos".i01_pk_cajt004 on "fobos".cajt004 
    (j04_compania,j04_localidad,j04_codigo_caja,j04_fecha_aper,
    j04_secuencia) using btree  in idxdbs ;
create index "fobos".i02_fk_cajt004 on "fobos".cajt004 (j04_usuario) 
    using btree  in idxdbs ;
alter table "fobos".cajt004 add constraint primary key (j04_compania,
    j04_localidad,j04_codigo_caja,j04_fecha_aper,j04_secuencia) 
    constraint "fobos".pk_cajt004  ;
create index "fobos".i01_fk_cajt005 on "fobos".cajt005 (j05_compania,
    j05_localidad,j05_codigo_caja,j05_fecha_aper,j05_secuencia) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_cajt005 on "fobos".cajt005 
    (j05_compania,j05_localidad,j05_codigo_caja,j05_fecha_aper,
    j05_secuencia,j05_moneda) using btree  in idxdbs ;
create index "fobos".i02_fk_cajt005 on "fobos".cajt005 (j05_moneda) 
    using btree  in idxdbs ;
alter table "fobos".cajt005 add constraint primary key (j05_compania,
    j05_localidad,j05_codigo_caja,j05_fecha_aper,j05_secuencia,
    j05_moneda) constraint "fobos".pk_cajt005  ;
create unique index "fobos".i01_pk_ctbt040 on "fobos".ctbt040 
    (b40_compania,b40_localidad,b40_modulo,b40_bodega,b40_grupo_linea,
    b40_porc_impto) using btree  in idxdbs ;
alter table "fobos".ctbt040 add constraint primary key (b40_compania,
    b40_localidad,b40_modulo,b40_bodega,b40_grupo_linea,b40_porc_impto) 
    constraint "fobos".pk_ctbt040  ;
create unique index "fobos".i01_pk_ctbt041 on "fobos".ctbt041 
    (b41_compania,b41_localidad,b41_modulo,b41_grupo_linea) using 
    btree  in idxdbs ;
alter table "fobos".ctbt041 add constraint primary key (b41_compania,
    b41_localidad,b41_modulo,b41_grupo_linea) constraint "fobos"
    .pk_ctbt041  ;
create unique index "fobos".i01_pk_ctbt042 on "fobos".ctbt042 
    (b42_compania,b42_localidad) using btree  in idxdbs ;
alter table "fobos".ctbt042 add constraint primary key (b42_compania,
    b42_localidad) constraint "fobos".pk_ctbt042  ;
create index "fobos".i01_fk_rept040 on "fobos".rept040 (r40_compania,
    r40_localidad,r40_cod_tran,r40_num_tran) using btree  in 
    idxdbs ;
create unique index "fobos".i01_pk_rept040 on "fobos".rept040 
    (r40_compania,r40_localidad,r40_cod_tran,r40_num_tran,r40_tipo_comp,
    r40_num_comp) using btree  in idxdbs ;
create index "fobos".i02_fk_rept040 on "fobos".rept040 (r40_compania,
    r40_tipo_comp,r40_num_comp) using btree  in idxdbs ;
alter table "fobos".rept040 add constraint primary key (r40_compania,
    r40_localidad,r40_cod_tran,r40_num_tran,r40_tipo_comp,r40_num_comp) 
    constraint "fobos".pk_rept040  ;
create index "fobos".i01_fk_cxct040 on "fobos".cxct040 (z40_compania,
    z40_localidad,z40_codcli,z40_tipo_doc,z40_num_doc) using 
    btree  in idxdbs ;
create unique index "fobos".i01_pk_cxct040 on "fobos".cxct040 
    (z40_compania,z40_localidad,z40_codcli,z40_tipo_doc,z40_num_doc,
    z40_tipo_comp,z40_num_comp) using btree  in idxdbs ;
create index "fobos".i02_fk_cxct040 on "fobos".cxct040 (z40_compania,
    z40_tipo_comp,z40_num_comp) using btree  in idxdbs ;
alter table "fobos".cxct040 add constraint primary key (z40_compania,
    z40_localidad,z40_codcli,z40_tipo_doc,z40_num_doc,z40_tipo_comp,
    z40_num_comp) constraint "fobos".pk_cxct040  ;
create unique index "fobos".i01_pk_veht050 on "fobos".veht050 
    (v50_compania,v50_localidad,v50_cod_tran,v50_num_tran,v50_tipo_comp,
    v50_num_comp) using btree  in idxdbs ;
alter table "fobos".veht050 add constraint primary key (v50_compania,
    v50_localidad,v50_cod_tran,v50_num_tran,v50_tipo_comp,v50_num_comp) 
    constraint "fobos".pk_veht050  ;
create unique index "fobos".i01_pk_ctbt043 on "fobos".ctbt043 
    (b43_compania,b43_localidad,b43_grupo_linea,b43_porc_impto) 
    using btree  in idxdbs ;
alter table "fobos".ctbt043 add constraint primary key (b43_compania,
    b43_localidad,b43_grupo_linea,b43_porc_impto) constraint 
    "fobos".pk_ctbt043  ;
create index "fobos".i01_fk_talt050 on "fobos".talt050 (t50_compania,
    t50_localidad,t50_orden) using btree  in idxdbs ;
create unique index "fobos".i01_pk_talt050 on "fobos".talt050 
    (t50_compania,t50_localidad,t50_orden,t50_tipo_comp,t50_num_comp) 
    using btree  in idxdbs ;
create index "fobos".i02_fk_talt050 on "fobos".talt050 (t50_compania,
    t50_localidad,t50_factura) using btree  in idxdbs ;
create index "fobos".i03_fk_talt050 on "fobos".talt050 (t50_compania,
    t50_tipo_comp,t50_num_comp) using btree  in idxdbs ;
alter table "fobos".talt050 add constraint primary key (t50_compania,
    t50_localidad,t50_orden,t50_tipo_comp,t50_num_comp) constraint 
    "fobos".pk_talt050  ;
create index "fobos".i01_fk_ordt040 on "fobos".ordt040 (c40_compania,
    c40_tipo_comp,c40_num_comp) using btree  in idxdbs ;
create unique index "fobos".i01_pk_ordt040 on "fobos".ordt040 
    (c40_compania,c40_localidad,c40_numero_oc,c40_num_recep,c40_tipo_comp,
    c40_num_comp) using btree  in idxdbs ;
alter table "fobos".ordt040 add constraint primary key (c40_compania,
    c40_localidad,c40_numero_oc,c40_num_recep,c40_tipo_comp,c40_num_comp) 
     ;
create index "fobos".i01_fk_talt030 on "fobos".talt030 (t30_compania) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_talt030 on "fobos".talt030 
    (t30_compania,t30_localidad,t30_num_gasto) using btree  in 
    idxdbs ;
create index "fobos".i02_fk_talt030 on "fobos".talt030 (t30_compania,
    t30_localidad) using btree  in idxdbs ;
create index "fobos".i03_fk_talt030 on "fobos".talt030 (t30_compania,
    t30_localidad,t30_num_ot) using btree  in idxdbs ;
create index "fobos".i04_fk_talt030 on "fobos".talt030 (t30_moneda) 
    using btree  in idxdbs ;
create index "fobos".i05_fk_talt030 on "fobos".talt030 (t30_usuario) 
    using btree  in idxdbs ;
alter table "fobos".talt030 add constraint primary key (t30_compania,
    t30_localidad,t30_num_gasto)  ;
create index "fobos".i01_fk_talt031 on "fobos".talt031 (t31_compania,
    t31_localidad,t31_num_gasto) using btree  in idxdbs ;
create unique index "fobos".i01_pk_talt031 on "fobos".talt031 
    (t31_compania,t31_localidad,t31_num_gasto,t31_secuencia) 
    using btree  in idxdbs ;
create index "fobos".i02_fk_talt031 on "fobos".talt031 (t31_moneda) 
    using btree  in idxdbs ;
alter table "fobos".talt031 add constraint primary key (t31_compania,
    t31_localidad,t31_num_gasto,t31_secuencia)  ;
create index "fobos".i01_fk_talt032 on "fobos".talt032 (t32_compania,
    t32_localidad,t32_num_gasto) using btree  in idxdbs ;
create unique index "fobos".i01_pk_talt032 on "fobos".talt032 
    (t32_compania,t32_localidad,t32_num_gasto,t32_mecanico) using 
    btree  in idxdbs ;
create index "fobos".i02_fk_talt032 on "fobos".talt032 (t32_mecanico) 
    using btree  in idxdbs ;
alter table "fobos".talt032 add constraint primary key (t32_compania,
    t32_localidad,t32_num_gasto,t32_mecanico)  ;
create index "fobos".i01_fk_talt033 on "fobos".talt033 (t33_compania,
    t33_localidad,t33_num_gasto) using btree  in idxdbs ;
create unique index "fobos".i01_pk_talt033 on "fobos".talt033 
    (t33_compania,t33_localidad,t33_num_gasto,t33_fecha) using 
    btree  in idxdbs ;
alter table "fobos".talt033 add constraint primary key (t33_compania,
    t33_localidad,t33_num_gasto,t33_fecha)  ;
create unique index "fobos".i01_pk_ctbt032 on "fobos".ctbt032 
    (b32_compania,b32_tipo_comp,b32_num_comp,b32_secuencia) using 
    btree  in idxdbs ;
alter table "fobos".ctbt032 add constraint primary key (b32_compania,
    b32_tipo_comp,b32_num_comp,b32_secuencia) constraint "fobos"
    .pk_ctbt032  ;
create unique index "fobos".i01_pk_rept074 on "fobos".rept074 
    (r74_compania,r74_electrico) using btree  in idxdbs ;
alter table "fobos".rept074 add constraint primary key (r74_compania,
    r74_electrico) constraint "fobos".pk_rept074  ;
create index "fobos".i01_fk_rept010 on "fobos".rept010 (r10_compania) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_rept010 on "fobos".rept010 
    (r10_compania,r10_codigo) using btree  in idxdbs ;
create index "fobos".i02_fk_rept010 on "fobos".rept010 (r10_tipo) 
    using btree  in idxdbs ;
create index "fobos".i03_fk_rept010 on "fobos".rept010 (r10_uni_med) 
    using btree  in idxdbs ;
create index "fobos".i04_fk_rept010 on "fobos".rept010 (r10_partida) 
    using btree  in idxdbs ;
create index "fobos".i05_fk_rept010 on "fobos".rept010 (r10_compania,
    r10_linea) using btree  in idxdbs ;
create index "fobos".i06_fk_rept010 on "fobos".rept010 (r10_compania,
    r10_rotacion) using btree  in idxdbs ;
create index "fobos".i07_fk_rept010 on "fobos".rept010 (r10_monfob) 
    using btree  in idxdbs ;
create index "fobos".i08_fk_rept010 on "fobos".rept010 (r10_usuario) 
    using btree  in idxdbs ;
create index "fobos".i10_fk_rept010 on "fobos".rept010 (r10_compania,
    r10_cod_util) using btree  in idxdbs ;
create index "fobos".i9_co_rept010 on "fobos".rept010 (r10_compania,
    r10_filtro) using btree  in idxdbs ;
alter table "fobos".rept010 add constraint primary key (r10_compania,
    r10_codigo) constraint "fobos".pk_rept010  ;
create unique index "fobos".i1_te_rept010 on "fobos".te_rept010 
    (te_compania,te_codigo) using btree  in idxdbs ;
create unique index "fobos".i01_pk_te_cxpt020 on "fobos".te_cxpt020 
    (p20_compania,p20_localidad,p20_codprov,p20_tipo_doc,p20_num_doc,
    p20_dividendo) using btree  in idxdbs ;
create unique index "fobos".i01_pk_rept038 on "fobos".rept038 
    (r38_compania,r38_localidad,r38_tipo_doc,r38_tipo_fuente,
    r38_cod_tran,r38_num_tran) using btree  in idxdbs ;
create index "fobos".idx_docsri on "fobos".rept038 (r38_compania,
    r38_localidad,r38_tipo_fuente,r38_cod_tran,r38_num_tran) 
    using btree  in datadbs ;
alter table "fobos".rept038 add constraint primary key (r38_compania,
    r38_localidad,r38_tipo_doc,r38_tipo_fuente,r38_cod_tran,r38_num_tran) 
    constraint "fobos".pk_rept038  ;
create unique index "fobos".i1_te_r10 on "fobos".te_r10 (te_compania,
    te_codigo) using btree  in idxdbs ;
create unique index "fobos".i1_te_otros_r10 on "fobos".te_otros_r10 
    (te_compania,te_codigo) using btree  in idxdbs ;
create unique index "fobos".i1_te_precios on "fobos".te_precios 
    (te_item) using btree  in idxdbs ;
create unique index "fobos".i1_te_descrip on "fobos".te_descrip 
    (te_codigo) using btree  in idxdbs ;
create unique index "fobos".i01_pk_te_cxct021 on "fobos".te_cxct021 
    (z21_compania,z21_localidad,z21_codcli,z21_tipo_doc,z21_num_doc) 
    using btree  in idxdbs ;
create unique index "fobos".i1_te_otr10 on "fobos".te_otr10 (te_compania,
    te_codigo) using btree  in idxdbs ;
create unique index "fobos".i01_items_qto on "fobos".tr_items_qto 
    (r10_compania,r10_codigo) using btree  in idxdbs ;
create unique index "fobos".i01_pk_tr_cxct002 on "fobos".tr_cxct002 
    (z02_compania,z02_localidad,z02_codcli) using btree  in idxdbs 
    ;
create unique index "fobos".i01_pk_tr_cxct020 on "fobos".tr_cxct020 
    (z20_compania,z20_localidad,z20_codcli,z20_tipo_doc,z20_num_doc,
    z20_dividendo) using btree  in idxdbs ;
create index "fobos".i01_fk_ordt011 on "fobos".ordt011 (c11_compania,
    c11_localidad,c11_numero_oc) using btree  in idxdbs ;
create unique index "fobos".i01_pk_ordt011 on "fobos".ordt011 
    (c11_compania,c11_localidad,c11_numero_oc,c11_secuencia) 
    using btree  in idxdbs ;
alter table "fobos".ordt011 add constraint primary key (c11_compania,
    c11_localidad,c11_numero_oc,c11_secuencia) constraint "fobos"
    .pk_ordt011  ;
create index "fobos".i01_fk_ordt014 on "fobos".ordt014 (c14_compania,
    c14_localidad,c14_numero_oc,c14_num_recep) using btree  in 
    idxdbs ;
create unique index "fobos".i01_pk_ordt014 on "fobos".ordt014 
    (c14_compania,c14_localidad,c14_numero_oc,c14_num_recep,c14_secuencia) 
    using btree  in idxdbs ;
alter table "fobos".ordt014 add constraint primary key (c14_compania,
    c14_localidad,c14_numero_oc,c14_num_recep,c14_secuencia) 
    constraint "fobos".pk_ordt014  ;
create unique index "fobos".i01_tr_items on "fobos".tr_items (r10_compania,
    r10_codigo) using btree  in idxdbs ;
create unique index "fobos".i1_tr_stock on "fobos".tr_stock (te_bodega,
    te_item) using btree  in idxdbs ;
create index "fobos".i01_fk_rept017 on "fobos".rept017 (r17_compania,
    r17_localidad,r17_pedido) using btree  in idxdbs ;
create unique index "fobos".i01_pk_rept017 on "fobos".rept017 
    (r17_compania,r17_localidad,r17_pedido,r17_item) using btree 
     in idxdbs ;
create index "fobos".i02_fk_rept017 on "fobos".rept017 (r17_compania,
    r17_item) using btree  in idxdbs ;
create index "fobos".i03_fk_rept017 on "fobos".rept017 (r17_compania,
    r17_linea) using btree  in idxdbs ;
create index "fobos".i04_fk_rept017 on "fobos".rept017 (r17_compania,
    r17_rotacion) using btree  in idxdbs ;
create index "fobos".i05_fk_rept017 on "fobos".rept017 (r17_partida) 
    using btree  in idxdbs ;
alter table "fobos".rept017 add constraint primary key (r17_compania,
    r17_localidad,r17_pedido,r17_item) constraint "fobos".pk_rept017 
     ;
create index "fobos".i01_fk_rept028 on "fobos".rept028 (r28_compania) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_rept028 on "fobos".rept028 
    (r28_compania,r28_localidad,r28_numliq) using btree  in idxdbs 
    ;
create index "fobos".i02_fk_rept028 on "fobos".rept028 (r28_compania,
    r28_localidad) using btree  in idxdbs ;
create index "fobos".i03_fk_rept028 on "fobos".rept028 (r28_moneda) 
    using btree  in idxdbs ;
create index "fobos".i04_fk_rept028 on "fobos".rept028 (r28_usuario) 
    using btree  in idxdbs ;
create index "fobos".i05_fk_rept028 on "fobos".rept028 (r28_compania,
    r28_bodega) using btree  in idxdbs ;
alter table "fobos".rept028 add constraint primary key (r28_compania,
    r28_localidad,r28_numliq) constraint "fobos".pk_rept028  ;
    
create unique index "fobos".i1_te_cod_kh on "fobos".te_cod_kh 
    (te_compania,te_codigo) using btree  in idxdbs ;
create index "fobos".i01_fk_ctbt012 on "fobos".ctbt012 (b12_compania,
    b12_tip_reversa,b12_num_reversa) using btree  in idxdbs ;
    
create unique index "fobos".i01_pk_ctbt012 on "fobos".ctbt012 
    (b12_compania,b12_tipo_comp,b12_num_comp) using btree  in 
    idxdbs ;
create index "fobos".i02_fk_ctbt012 on "fobos".ctbt012 (b12_compania,
    b12_tipo_comp) using btree  in idxdbs ;
create index "fobos".i03_fk_ctbt012 on "fobos".ctbt012 (b12_compania,
    b12_subtipo) using btree  in idxdbs ;
create index "fobos".i04_fk_ctbt012 on "fobos".ctbt012 (b12_moneda) 
    using btree  in idxdbs ;
create index "fobos".i05_fk_ctbt012 on "fobos".ctbt012 (b12_usuario) 
    using btree  in idxdbs ;
create index "fobos".i06_fk_ctbt012 on "fobos".ctbt012 (b12_compania,
    b12_tipo_comp,b12_num_comp,b12_estado) using btree  in idxdbs 
    ;
alter table "fobos".ctbt012 add constraint primary key (b12_compania,
    b12_tipo_comp,b12_num_comp) constraint "fobos".pk_ctbt012 
     ;
create index "fobos".i01_fk_gent037 on "fobos".gent037 (g37_compania) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_gent037 on "fobos".gent037 
    (g37_compania,g37_localidad,g37_tipo_doc,g37_secuencia) using 
    btree  in idxdbs ;
create index "fobos".i02_fk_gent037 on "fobos".gent037 (g37_compania,
    g37_localidad) using btree  in idxdbs ;
create index "fobos".i04_fk_gent037 on "fobos".gent037 (g37_compania,
    g37_localidad,g37_tipo_doc) using btree  in idxdbs ;
create index "fobos".i13_fk_gent037 on "fobos".gent037 (g37_usuario) 
    using btree  in idxdbs ;
alter table "fobos".gent037 add constraint primary key (g37_compania,
    g37_localidad,g37_tipo_doc,g37_secuencia) constraint "fobos"
    .pk_gent037  ;
create unique index "fobos".i01_pk_tr_cxct021 on "fobos".tr_cxct021 
    (z21_compania,z21_localidad,z21_codcli,z21_tipo_doc,z21_num_doc) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_tr_cxct022 on "fobos".tr_cxct022 
    (z22_compania,z22_localidad,z22_codcli,z22_tipo_trn,z22_num_trn) 
    using btree  in idxdbs ;
create index "fobos".i08_fk_tr_cxct022 on "fobos".tr_cxct022 (z22_zona_cobro) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_tr_cxct023 on "fobos".tr_cxct023 
    (z23_compania,z23_localidad,z23_codcli,z23_tipo_trn,z23_num_trn,
    z23_orden) using btree  in idxdbs ;
create index "fobos".i01_fk_021 on "fobos".te_021_07052003 (z21_compania,
    z21_localidad,z21_codcli) using btree  in idxdbs ;
create unique index "fobos".i01_pk_021 on "fobos".te_021_07052003 
    (z21_compania,z21_localidad,z21_codcli,z21_tipo_doc,z21_num_doc) 
    using btree  in idxdbs ;
create index "fobos".i02_fk_021 on "fobos".te_021_07052003 (z21_tipo_doc) 
    using btree  in idxdbs ;
create index "fobos".i03_fk_021 on "fobos".te_021_07052003 (z21_compania,
    z21_areaneg) using btree  in idxdbs ;
create index "fobos".i04_fk_021 on "fobos".te_021_07052003 (z21_moneda) 
    using btree  in idxdbs ;
create index "fobos".i05_fk_021 on "fobos".te_021_07052003 (z21_usuario) 
    using btree  in idxdbs ;
create index "fobos".i06_fk_021 on "fobos".te_021_07052003 (z21_compania,
    z21_linea) using btree  in idxdbs ;
alter table "fobos".te_021_07052003 add constraint primary key 
    (z21_compania,z21_localidad,z21_codcli,z21_tipo_doc,z21_num_doc) 
    constraint "fobos".pk_021  ;
create index "fobos".i01_fk_te_g16 on "fobos".te_gent016 (g16_usuario) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_te_g16 on "fobos".te_gent016 
    (g16_partida) using btree  in idxdbs ;
alter table "fobos".te_gent016 add constraint primary key (g16_partida) 
    constraint "fobos".pk_te_gent016  ;
create unique index "fobos".i1_tr_precios_qto on "fobos".tr_precios_qto 
    (te_compania,te_item) using btree  in idxdbs ;
create unique index "fobos".i2_tr_precios_qto on "fobos".tr_precios_qto 
    (te_compania,te_item,te_marca) using btree  in idxdbs ;
create index "fobos".i01_fk_gent038 on "fobos".gent038 (g38_usuario) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_gent038 on "fobos".gent038 
    (g38_capitulo) using btree  in idxdbs ;
alter table "fobos".gent038 add constraint primary key (g38_capitulo) 
    constraint "fobos".pk_gent038  ;
create index "fobos".i01_fk_gent016 on "fobos".gent016 (g16_usuario) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_gent016 on "fobos".gent016 
    (g16_partida) using btree  in idxdbs ;
create index "fobos".i02_fk_gent016 on "fobos".gent016 (g16_capitulo) 
    using btree  in idxdbs ;
alter table "fobos".gent016 add constraint primary key (g16_partida) 
    constraint "fobos".pk_gent016  ;
create index "fobos".i01_fk_te_actt010 on "fobos".te_actt010 (a10_compania) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_te_actt010 on "fobos".te_actt010 
    (a10_compania,a10_codigo_bien) using btree  in idxdbs ;
create index "fobos".i02_fk_te_actt010 on "fobos".te_actt010 (a10_compania,
    a10_grupo_act) using btree  in idxdbs ;
create index "fobos".i03_fk_te_actt010 on "fobos".te_actt010 (a10_compania,
    a10_tipo_act) using btree  in idxdbs ;
create index "fobos".i04_fk_te_actt010 on "fobos".te_actt010 (a10_compania,
    a10_locali_ori) using btree  in idxdbs ;
create index "fobos".i05_fk_te_actt010 on "fobos".te_actt010 (a10_compania,
    a10_localidad) using btree  in idxdbs ;
create index "fobos".i06_fk_te_actt010 on "fobos".te_actt010 (a10_compania,
    a10_locali_ori,a10_numero_oc) using btree  in idxdbs ;
create index "fobos".i07_fk_te_actt010 on "fobos".te_actt010 (a10_compania,
    a10_cod_depto) using btree  in idxdbs ;
create index "fobos".i08_fk_te_actt010 on "fobos".te_actt010 (a10_compania,
    a10_locali_ori,a10_codprov) using btree  in idxdbs ;
create index "fobos".i09_fk_te_actt010 on "fobos".te_actt010 (a10_moneda) 
    using btree  in idxdbs ;
create index "fobos".i10_fk_te_actt010 on "fobos".te_actt010 (a10_compania,
    a10_responsable) using btree  in idxdbs ;
create index "fobos".i11_fk_te_actt010 on "fobos".te_actt010 (a10_usuario) 
    using btree  in idxdbs ;
alter table "fobos".te_actt010 add constraint primary key (a10_compania,
    a10_codigo_bien) constraint "fobos".pk_te_actt010  ;
create unique index "fobos".i01_pk_cxct041 on "fobos".cxct041 
    (z41_compania,z41_localidad,z41_codcli,z41_tipo_doc,z41_num_doc,
    z41_dividendo,z41_tipo_comp,z41_num_comp) using btree  in 
    idxdbs ;
alter table "fobos".cxct041 add constraint primary key (z41_compania,
    z41_localidad,z41_codcli,z41_tipo_doc,z41_num_doc,z41_dividendo,
    z41_tipo_comp,z41_num_comp) constraint "fobos".pk_cxct041 
     ;
create unique index "fobos".i01_pk_cxpt040 on "fobos".cxpt040 
    (p40_compania,p40_localidad,p40_codprov,p40_tipo_doc,p40_num_doc,
    p40_tipo_comp,p40_num_comp) using btree  in idxdbs ;
alter table "fobos".cxpt040 add constraint primary key (p40_compania,
    p40_localidad,p40_codprov,p40_tipo_doc,p40_num_doc,p40_tipo_comp,
    p40_num_comp) constraint "fobos".pk_cxpt040  ;
create index "fobos".i01_fk_cxpt041 on "fobos".cxpt041 (p41_compania,
    p41_localidad,p41_codprov,p41_tipo_doc,p41_num_doc,p41_dividendo) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_cxpt041 on "fobos".cxpt041 
    (p41_compania,p41_localidad,p41_codprov,p41_tipo_doc,p41_num_doc,
    p41_dividendo,p41_tipo_comp,p41_num_comp) using btree  in 
    idxdbs ;
alter table "fobos".cxpt041 add constraint primary key (p41_compania,
    p41_localidad,p41_codprov,p41_tipo_doc,p41_num_doc,p41_dividendo,
    p41_tipo_comp,p41_num_comp) constraint "fobos".pk_cxpt041 
     ;
create index "fobos".vb1 on "fobos".vb_1 (fecha,codven) using 
    btree  in idxdbs ;
create index "fobos".vb2 on "fobos".vb_1 (fecha,codven,codcli) 
    using btree  in idxdbs ;
create index "fobos".vb3 on "fobos".vb_1 (fecha,codven,codcli,
    marca) using btree  in idxdbs ;
create index "fobos".vb4 on "fobos".vb_1 (fecha,codven,codcli,
    marca,division) using btree  in idxdbs ;
create index "fobos".vb5 on "fobos".vb_1 (fecha,codven,codcli,
    marca,division,linea) using btree  in idxdbs ;
create index "fobos".vb6 on "fobos".vb_1 (fecha,codven,codcli,
    marca,division,linea,grupo) using btree  in idxdbs ;
create index "fobos".vb7 on "fobos".vb_1 (fecha,codven,codcli,
    marca,division,linea,grupo,clase) using btree  in idxdbs 
    ;
create index "fobos".vbp1 on "fobos".vb_proformas (fecha,codven) 
    using btree  in idxdbs ;
create index "fobos".vbp2 on "fobos".vb_proformas (fecha,codven,
    codcli) using btree  in idxdbs ;
create index "fobos".vbp3 on "fobos".vb_proformas (fecha,codven,
    codcli,marca) using btree  in idxdbs ;
create index "fobos".vbp4 on "fobos".vb_proformas (fecha,codven,
    codcli,marca,division) using btree  in idxdbs ;
create index "fobos".vbp5 on "fobos".vb_proformas (fecha,codven,
    codcli,marca,division,linea) using btree  in idxdbs ;
create index "fobos".vbp6 on "fobos".vb_proformas (fecha,codven,
    codcli,marca,division,linea,grupo) using btree  in idxdbs 
    ;
create index "fobos".vbp7 on "fobos".vb_proformas (fecha,codven,
    codcli,marca,division,linea,grupo,clase) using btree  in 
    idxdbs ;
create unique index "fobos".i1_repro_010 on "fobos".repro_010 
    (r10_compania,r10_codigo) using btree  in idxdbs ;
create unique index "fobos".i1_repro_011 on "fobos".repro_011 
    (r11_compania,r11_bodega,r11_item) using btree  in idxdbs 
    ;
create unique index "fobos".i1_repro_019 on "fobos".repro_019 
    (r19_compania,r19_localidad,r19_cod_tran,r19_num_tran) using 
    btree  in idxdbs ;
create unique index "fobos".i1_repro_020 on "fobos".repro_020 
    (r20_compania,r20_localidad,r20_cod_tran,r20_num_tran,r20_item,
    r20_orden) using btree  in idxdbs ;
create index "fobos".i01_fk_rept083 on "fobos".rept083 (r83_compania) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_rept083 on "fobos".rept083 
    (r83_compania,r83_item,r83_cod_desc_item) using btree  in 
    idxdbs ;
create index "fobos".i02_fk_rept083 on "fobos".rept083 (r83_compania,
    r83_item) using btree  in idxdbs ;
alter table "fobos".rept083 add constraint primary key (r83_compania,
    r83_item,r83_cod_desc_item) constraint "fobos".pk_rept083 
     ;
create unique index "fobos".i1_hulk_010 on "fobos".hulk_010 (r10_compania,
    r10_codigo) using btree  in idxdbs ;
create unique index "fobos".i01_fk_rolt016 on "fobos".rolt016 
    (n16_flag_ident) using btree  in idxdbs ;
alter table "fobos".rolt016 add constraint primary key (n16_flag_ident) 
    constraint "fobos".pk_rolt016  ;
create index "fobos".i01_fk_rolt047 on "fobos".rolt047 (n47_compania,
    n47_proceso,n47_cod_trab,n47_periodo_ini,n47_periodo_fin) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_rolt047 on "fobos".rolt047 
    (n47_compania,n47_proceso,n47_cod_trab,n47_periodo_ini,n47_periodo_fin,
    n47_secuencia) using btree  in idxdbs ;
create index "fobos".i02_fk_rolt047 on "fobos".rolt047 (n47_proceso) 
    using btree  in idxdbs ;
create index "fobos".i03_fk_rolt047 on "fobos".rolt047 (n47_compania,
    n47_cod_liqrol,n47_fecha_ini,n47_fecha_fin,n47_cod_trab) 
    using btree  in idxdbs ;
create index "fobos".i04_fk_rolt047 on "fobos".rolt047 (n47_cod_liqrol) 
    using btree  in idxdbs ;
create index "fobos".i05_fk_rolt047 on "fobos".rolt047 (n47_usuario) 
    using btree  in idxdbs ;
alter table "fobos".rolt047 add constraint primary key (n47_compania,
    n47_proceso,n47_cod_trab,n47_periodo_ini,n47_periodo_fin,
    n47_secuencia) constraint "fobos".pk_rolt047  ;
create index "fobos".i01_fk_rolt048 on "fobos".rolt048 (n48_compania) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_rolt048 on "fobos".rolt048 
    (n48_compania,n48_proceso,n48_cod_liqrol,n48_fecha_ini,n48_fecha_fin,
    n48_cod_trab) using btree  in idxdbs ;
create index "fobos".i02_fk_rolt048 on "fobos".rolt048 (n48_compania,
    n48_cod_trab) using btree  in idxdbs ;
create index "fobos".i03_fk_rolt048 on "fobos".rolt048 (n48_moneda) 
    using btree  in idxdbs ;
create index "fobos".i04_fk_rolt048 on "fobos".rolt048 (n48_compania,
    n48_bco_empresa,n48_cta_empresa) using btree  in idxdbs ;
    
create index "fobos".i05_fk_rolt048 on "fobos".rolt048 (n48_usuario) 
    using btree  in idxdbs ;
create index "fobos".i06_fk_rolt048 on "fobos".rolt048 (n48_compania,
    n48_tipo_comp,n48_num_comp) using btree  in idxdbs ;
create index "fobos".i07_fk_rolt048 on "fobos".rolt048 (n48_proceso) 
    using btree  in idxdbs ;
create index "fobos".i08_fk_rolt048 on "fobos".rolt048 (n48_cod_liqrol) 
    using btree  in idxdbs ;
alter table "fobos".rolt048 add constraint primary key (n48_compania,
    n48_proceso,n48_cod_liqrol,n48_fecha_ini,n48_fecha_fin,n48_cod_trab) 
    constraint "fobos".pk_rolt048  ;
create index "fobos".i01_fk_rept082 on "fobos".rept082 (r82_compania,
    r82_localidad,r82_pedido) using btree  in idxdbs ;
create unique index "fobos".i01_pk_rept082 on "fobos".rept082 
    (r82_compania,r82_localidad,r82_pedido,r82_item) using btree 
     in idxdbs ;
create index "fobos".i03_fk_rept082 on "fobos".rept082 (r82_compania) 
    using btree  in idxdbs ;
create index "fobos".i04_fk_rept082 on "fobos".rept082 (r82_compania,
    r82_localidad) using btree  in idxdbs ;
create index "fobos".i05_fk_rept082 on "fobos".rept082 (r82_cod_unid) 
    using btree  in idxdbs ;
create index "fobos".i06_fk_rept082 on "fobos".rept082 (r82_compania,
    r82_item) using btree  in idxdbs ;
create index "fobos".i07_fk_rept082 on "fobos".rept082 (r82_partida) 
    using btree  in idxdbs ;
alter table "fobos".rept082 add constraint primary key (r82_compania,
    r82_localidad,r82_pedido,r82_item) constraint "fobos".pk_rept082 
     ;
create index "fobos".i01_fk_rept084 on "fobos".rept084 (r84_compania) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_rept084 on "fobos".rept084 
    (r84_compania,r84_cod_desc_item) using btree  in idxdbs ;
    
create index "fobos".i02_fk_rept084 on "fobos".rept084 (r84_usuario) 
    using btree  in idxdbs ;
alter table "fobos".rept084 add constraint primary key (r84_compania,
    r84_cod_desc_item) constraint "fobos".pk_rept084  ;
create index "fobos".i01_fk_actt013 on "fobos".actt013 (a13_compania,
    a13_codigo_bien) using btree  in idxdbs ;
create unique index "fobos".i01_pk_actt013 on "fobos".actt013 
    (a13_compania,a13_codigo_bien,a13_ano) using btree  in idxdbs 
    ;
alter table "fobos".actt013 add constraint primary key (a13_compania,
    a13_codigo_bien,a13_ano) constraint "fobos".pk_actt013  ;
create unique index "fobos".i1_te_sanit on "fobos".te_sanit (r10_codigo) 
    using btree  in idxdbs ;
create unique index "fobos".i1_te_acces_fv on "fobos".te_acces_fv 
    (r10_codigo) using btree  in idxdbs ;
create unique index "fobos".i1_te_rolaux on "fobos".te_rolaux 
    (te_cod_trab) using btree  in idxdbs ;
create unique index "fobos".i1_pk_te_rol99_02 on "fobos".te_rol99_02 
    (te_codfec,te_cod_trab) using btree  in idxdbs ;
create unique index "fobos".i1_te_rol2003 on "fobos".te_rol2003 
    (te_cod_liqrol,te_ano,te_mes,te_cod_trab) using btree  in 
    idxdbs ;
create unique index "fobos".i01_pk_te_rolt033 on "fobos".te_rolt033 
    (n33_compania,n33_cod_liqrol,n33_fecha_ini,n33_fecha_fin,
    n33_cod_trab,n33_cod_rubro) using btree  in idxdbs ;
alter table "fobos".te_rolt033 add constraint primary key (n33_compania,
    n33_cod_liqrol,n33_fecha_ini,n33_fecha_fin,n33_cod_trab,n33_cod_rubro) 
    constraint "fobos".pk_te_rolt033  ;
create unique index "fobos".i01_pk_te_rolt032 on "fobos".te_rolt032 
    (n32_compania,n32_cod_liqrol,n32_fecha_ini,n32_fecha_fin,
    n32_cod_trab) using btree  in idxdbs ;
alter table "fobos".te_rolt032 add constraint primary key (n32_compania,
    n32_cod_liqrol,n32_fecha_ini,n32_fecha_fin,n32_cod_trab) 
    constraint "fobos".pk_te_rolt032  ;
create index "fobos".i01_fk_rolt060 on "fobos".rolt060 (n60_usuario) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_rolt060 on "fobos".rolt060 
    (n60_compania) using btree  in idxdbs ;
create index "fobos".i02_fk_rolt060 on "fobos".rolt060 (n60_banco) 
    using btree  in idxdbs ;
create index "fobos".i03_fk_rolt060 on "fobos".rolt060 (n60_compania,
    n60_rub_aporte) using btree  in idxdbs ;
alter table "fobos".rolt060 add constraint primary key (n60_compania) 
    constraint "fobos".pk_rolt060  ;
create index "fobos".i01_fk_rolt061 on "fobos".rolt061 (n61_compania) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_rolt061 on "fobos".rolt061 
    (n61_compania,n61_cod_trab) using btree  in idxdbs ;
create index "fobos".i02_fk_rolt061 on "fobos".rolt061 (n61_usuario) 
    using btree  in idxdbs ;
alter table "fobos".rolt061 add constraint primary key (n61_compania,
    n61_cod_trab) constraint "fobos".pk_rolt061  ;
create index "fobos".i01_fk_rolt062 on "fobos".rolt062 (n62_compania) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_rolt062 on "fobos".rolt062 
    (n62_compania,n62_cod_almacen) using btree  in idxdbs ;
create index "fobos".i02_fk_rolt062 on "fobos".rolt062 (n62_usuario) 
    using btree  in idxdbs ;
create index "fobos".i03_fk_rolt062 on "fobos".rolt062 (n62_compania,
    n62_cod_rubro) using btree  in idxdbs ;
alter table "fobos".rolt062 add constraint primary key (n62_compania,
    n62_cod_almacen) constraint "fobos".pk_rolt062  ;
create index "fobos".i01_fk_rolt063 on "fobos".rolt063 (n63_cod_liqrol) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_rolt063 on "fobos".rolt063 
    (n63_compania,n63_cod_almacen,n63_cod_liqrol,n63_fecha_ini,
    n63_fecha_fin,n63_cod_trab) using btree  in idxdbs ;
create index "fobos".i02_fk_rolt063 on "fobos".rolt063 (n63_compania,
    n63_cod_trab) using btree  in idxdbs ;
create index "fobos".i03_fk_rolt063 on "fobos".rolt063 (n63_compania,
    n63_cod_almacen) using btree  in idxdbs ;
create index "fobos".i04_fk_rolt063 on "fobos".rolt063 (n63_compania,
    n63_cod_liqrol,n63_fecha_ini,n63_fecha_fin) using btree  
    in idxdbs ;
alter table "fobos".rolt063 add constraint primary key (n63_compania,
    n63_cod_almacen,n63_cod_liqrol,n63_fecha_ini,n63_fecha_fin,
    n63_cod_trab) constraint "fobos".pk_rolt063  ;
create index "fobos".i01_fk_rolt065 on "fobos".rolt065 (n65_compania,
    n65_num_prest) using btree  in idxdbs ;
create unique index "fobos".i01_pk_rolt065 on "fobos".rolt065 
    (n65_compania,n65_num_prest,n65_secuencia) using btree  in 
    idxdbs ;
create index "fobos".i02_fk_rolt065 on "fobos".rolt065 (n65_cod_liqrol) 
    using btree  in idxdbs ;
alter table "fobos".rolt065 add constraint primary key (n65_compania,
    n65_num_prest,n65_secuencia) constraint "fobos".pk_rolt065 
     ;
create index "fobos".i01_fk_rolt066 on "fobos".rolt066 (n66_usuario) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_rolt066 on "fobos".rolt066 
    (n66_compania,n66_concepto_pago) using btree  in idxdbs ;
    
alter table "fobos".rolt066 add constraint primary key (n66_compania,
    n66_concepto_pago) constraint "fobos".pk_rolt066  ;
create index "fobos".i01_fk_rolt067 on "fobos".rolt067 (n67_usuario) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_rolt067 on "fobos".rolt067 
    (n67_cod_rubro) using btree  in idxdbs ;
alter table "fobos".rolt067 add constraint primary key (n67_cod_rubro) 
    constraint "fobos".pk_rolt067  ;
create index "fobos".i01_fk_rolt068 on "fobos".rolt068 (n68_compania) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_rolt068 on "fobos".rolt068 
    (n68_compania,n68_cod_tran,n68_num_tran) using btree  in 
    idxdbs ;
create index "fobos".i02_fk_rolt068 on "fobos".rolt068 (n68_compania,
    n68_cod_trab) using btree  in idxdbs ;
create index "fobos".i03_fk_rolt068 on "fobos".rolt068 (n68_cod_liqrol) 
    using btree  in idxdbs ;
create index "fobos".i04_fk_rolt068 on "fobos".rolt068 (n68_cod_rubro) 
    using btree  in idxdbs ;
create index "fobos".i05_fk_rolt068 on "fobos".rolt068 (n68_banco) 
    using btree  in idxdbs ;
create index "fobos".i06_fk_rolt068 on "fobos".rolt068 (n68_usuario) 
    using btree  in idxdbs ;
create index "fobos".i07_fk_rolt068 on "fobos".rolt068 (n68_compania,
    n68_num_prest) using btree  in idxdbs ;
alter table "fobos".rolt068 add constraint primary key (n68_compania,
    n68_cod_tran,n68_num_tran) constraint "fobos".pk_rolt068  
    ;
create index "fobos".i01_fk_rolt069 on "fobos".rolt069 (n69_compania) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_rolt069 on "fobos".rolt069 
    (n69_compania,n69_banco,n69_numero_cta,n69_anio,n69_mes) 
    using btree  in idxdbs ;
create index "fobos".i02_fk_rolt069 on "fobos".rolt069 (n69_banco) 
    using btree  in idxdbs ;
alter table "fobos".rolt069 add constraint primary key (n69_compania,
    n69_banco,n69_numero_cta,n69_anio,n69_mes) constraint "fobos"
    .pk_rolt069  ;
create index "fobos".i01_fk_rolt050 on "fobos".rolt050 (n50_compania) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_rolt050 on "fobos".rolt050 
    (n50_compania,n50_cod_rubro,n50_cod_depto) using btree  in 
    idxdbs ;
create index "fobos".i02_fk_rolt050 on "fobos".rolt050 (n50_cod_rubro) 
    using btree  in idxdbs ;
create index "fobos".i03_fk_rolt050 on "fobos".rolt050 (n50_compania,
    n50_cod_depto) using btree  in idxdbs ;
create index "fobos".i04_fk_rolt050 on "fobos".rolt050 (n50_compania,
    n50_aux_cont) using btree  in idxdbs ;
alter table "fobos".rolt050 add constraint primary key (n50_compania,
    n50_cod_rubro,n50_cod_depto) constraint "fobos".pk_rolt050 
     ;
create index "fobos".i01_fk_rolt051 on "fobos".rolt051 (n51_compania) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_rolt051 on "fobos".rolt051 
    (n51_compania,n51_cod_rubro) using btree  in idxdbs ;
create index "fobos".i02_fk_rolt051 on "fobos".rolt051 (n51_cod_rubro) 
    using btree  in idxdbs ;
create index "fobos".i03_fk_rolt051 on "fobos".rolt051 (n51_compania,
    n51_aux_cont) using btree  in idxdbs ;
alter table "fobos".rolt051 add constraint primary key (n51_compania,
    n51_cod_rubro) constraint "fobos".pk_rolt051  ;
create index "fobos".i01_fk_rolt052 on "fobos".rolt052 (n52_compania) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_rolt052 on "fobos".rolt052 
    (n52_compania,n52_cod_rubro,n52_cod_trab) using btree  in 
    idxdbs ;
create index "fobos".i02_fk_rolt052 on "fobos".rolt052 (n52_cod_rubro) 
    using btree  in idxdbs ;
create index "fobos".i03_fk_rolt052 on "fobos".rolt052 (n52_compania,
    n52_cod_trab) using btree  in idxdbs ;
create index "fobos".i04_fk_rolt052 on "fobos".rolt052 (n52_compania,
    n52_aux_cont) using btree  in idxdbs ;
alter table "fobos".rolt052 add constraint primary key (n52_compania,
    n52_cod_rubro,n52_cod_trab) constraint "fobos".pk_rolt052 
     ;
create index "fobos".i01_fk_rolt053 on "fobos".rolt053 (n53_compania,
    n53_cod_liqrol) using btree  in idxdbs ;
create unique index "fobos".i01_pk_rolt053 on "fobos".rolt053 
    (n53_compania,n53_cod_liqrol,n53_fecha_ini,n53_fecha_fin,
    n53_tipo_comp,n53_num_comp) using btree  in idxdbs ;
create index "fobos".i02_pk_rolt053 on "fobos".rolt053 (n53_compania,
    n53_tipo_comp,n53_num_comp) using btree  in idxdbs ;
alter table "fobos".rolt053 add constraint primary key (n53_compania,
    n53_cod_liqrol,n53_fecha_ini,n53_fecha_fin,n53_tipo_comp,
    n53_num_comp) constraint "fobos".pk_rolt053  ;
create index "fobos".i01_fk_rolt054 on "fobos".rolt054 (n54_compania,
    n54_aux_cont) using btree  in idxdbs ;
create unique index "fobos".i01_pk_rolt054 on "fobos".rolt054 
    (n54_compania) using btree  in idxdbs ;
alter table "fobos".rolt054 add constraint primary key (n54_compania) 
    constraint "fobos".pk_rolt054  ;
create unique index "fobos".i01_te_edesa on "fobos".te_edesa (te_codigo) 
    using btree  in idxdbs ;
create unique index "fobos".i01_te_gan_qto on "fobos".te_gan_qto 
    (te_cod_trab,te_cod_liqrol,te_ano,te_mes) using btree  in 
    idxdbs ;
create index "fobos".i01_fk_rolt080 on "fobos".rolt080 (n80_compania) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_rolt080 on "fobos".rolt080 
    (n80_compania,n80_ano,n80_mes,n80_cod_trab) using btree  
    in idxdbs ;
create index "fobos".i02_fk_rolt080 on "fobos".rolt080 (n80_compania,
    n80_cod_trab) using btree  in idxdbs ;
create index "fobos".i03_fk_rolt080 on "fobos".rolt080 (n80_moneda) 
    using btree  in idxdbs ;
alter table "fobos".rolt080 add constraint primary key (n80_compania,
    n80_ano,n80_mes,n80_cod_trab) constraint "fobos".pk_rolt080 
     ;
create index "fobos".i01_fk_rolt081 on "fobos".rolt081 (n81_compania) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_rolt081 on "fobos".rolt081 
    (n81_compania,n81_num_poliza) using btree  in idxdbs ;
create index "fobos".i02_fk_rolt081 on "fobos".rolt081 (n81_usuario) 
    using btree  in idxdbs ;
create index "fobos".i03_fk_rolt081 on "fobos".rolt081 (n81_cod_liqrol) 
    using btree  in idxdbs ;
create index "fobos".i04_fk_rolt081 on "fobos".rolt081 (n81_moneda) 
    using btree  in idxdbs ;
alter table "fobos".rolt081 add constraint primary key (n81_compania,
    n81_num_poliza) constraint "fobos".pk_rolt081  ;
create index "fobos".i01_fk_rolt082 on "fobos".rolt082 (n82_compania) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_rolt082 on "fobos".rolt082 
    (n82_compania,n82_cod_trab,n82_secuencia) using btree  in 
    idxdbs ;
create index "fobos".i02_fk_rolt082 on "fobos".rolt082 (n82_compania,
    n82_cod_trab) using btree  in idxdbs ;
create index "fobos".i03_fk_rolt082 on "fobos".rolt082 (n82_compania,
    n82_banco,n82_numero_cta) using btree  in idxdbs ;
alter table "fobos".rolt082 add constraint primary key (n82_compania,
    n82_cod_trab,n82_secuencia) constraint "fobos".pk_rolt082 
     ;
create index "fobos".i01_fk_rolt083 on "fobos".rolt083 (n83_compania) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_rolt083 on "fobos".rolt083 
    (n83_compania,n83_ano,n83_mes,n83_cod_trab) using btree  
    in idxdbs ;
create index "fobos".i02_fk_rolt083 on "fobos".rolt083 (n83_compania,
    n83_cod_trab) using btree  in idxdbs ;
create index "fobos".i03_fk_rolt083 on "fobos".rolt083 (n83_compania,
    n83_num_poliza) using btree  in idxdbs ;
create index "fobos".i04_fk_rolt083 on "fobos".rolt083 (n83_moneda) 
    using btree  in idxdbs ;
alter table "fobos".rolt083 add constraint primary key (n83_compania,
    n83_ano,n83_mes,n83_cod_trab) constraint "fobos".pk_rolt083 
     ;
create unique index "fobos".i1_te_rol1202 on "fobos".te_rol1202 
    (te_cod_liqrol,te_ano,te_mes,te_cod_trab) using btree  in 
    idxdbs ;
create index "fobos".i01_fk_te_stofis on "fobos".te_stofis (te_compania) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_te_stofis on "fobos".te_stofis 
    (te_compania,te_localidad,te_bodega,te_item) using btree 
     in idxdbs ;
create index "fobos".i02_fk_te_stofis on "fobos".te_stofis (te_compania,
    te_localidad) using btree  in idxdbs ;
create index "fobos".i03_fk_te_stofis on "fobos".te_stofis (te_compania,
    te_bodega) using btree  in idxdbs ;
create index "fobos".i04_fk_te_stofis on "fobos".te_stofis (te_compania,
    te_item) using btree  in idxdbs ;
create index "fobos".i05_fk_te_stofis on "fobos".te_stofis (te_compania,
    te_bodega,te_item) using btree  in idxdbs ;
create index "fobos".i06_fk_te_stofis on "fobos".te_stofis (te_usuario) 
    using btree  in idxdbs ;
alter table "fobos".te_stofis add constraint primary key (te_compania,
    te_localidad,te_bodega,te_item) constraint "fobos".pk_te_stofis 
     ;
create index "fobos".i01_fk_resp_exis on "fobos".resp_exis (r11_compania) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_resp_exis on "fobos".resp_exis 
    (r11_compania,r11_bodega,r11_item) using btree  in idxdbs 
    ;
create index "fobos".i02_fk_resp_exis on "fobos".resp_exis (r11_compania,
    r11_bodega) using btree  in idxdbs ;
create index "fobos".i03_fk_resp_exis on "fobos".resp_exis (r11_compania,
    r11_item) using btree  in idxdbs ;
alter table "fobos".resp_exis add constraint primary key (r11_compania,
    r11_bodega,r11_item) constraint "fobos".pk_resp_exis  ;
create index "fobos".i01_fk_te_boddan on "fobos".te_boddan (te_compania) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_te_boddan on "fobos".te_boddan 
    (te_compania,te_localidad,te_bodega,te_bodega_dan) using 
    btree  in idxdbs ;
create index "fobos".i02_fk_te_boddan on "fobos".te_boddan (te_compania,
    te_localidad) using btree  in idxdbs ;
create index "fobos".i03_fk_te_boddan on "fobos".te_boddan (te_compania,
    te_bodega) using btree  in idxdbs ;
create index "fobos".i04_fk_te_boddan on "fobos".te_boddan (te_compania,
    te_bodega_dan) using btree  in idxdbs ;
alter table "fobos".te_boddan add constraint primary key (te_compania,
    te_localidad,te_bodega,te_bodega_dan) constraint "fobos".pk_te_boddan 
     ;
create index "fobos".i01_fk_rolt039 on "fobos".rolt039 (n39_compania,
    n39_cod_trab) using btree  in idxdbs ;
create unique index "fobos".i01_pk_rolt039 on "fobos".rolt039 
    (n39_compania,n39_proceso,n39_cod_trab,n39_periodo_ini,n39_periodo_fin) 
    using btree  in idxdbs ;
create index "fobos".i02_fk_rolt039 on "fobos".rolt039 (n39_compania,
    n39_cod_depto) using btree  in idxdbs ;
create index "fobos".i03_fk_rolt039 on "fobos".rolt039 (n39_moneda) 
    using btree  in idxdbs ;
create index "fobos".i04_fk_rolt039 on "fobos".rolt039 (n39_usuario) 
    using btree  in idxdbs ;
create index "fobos".i05_fk_rolt039 on "fobos".rolt039 (n39_proceso) 
    using btree  in idxdbs ;
create index "fobos".i06_fk_rolt039 on "fobos".rolt039 (n39_bco_empresa) 
    using btree  in idxdbs ;
create index "fobos".i07_fk_rolt039 on "fobos".rolt039 (n39_compania,
    n39_bco_empresa,n39_cta_empresa) using btree  in idxdbs ;
    
alter table "fobos".rolt039 add constraint primary key (n39_compania,
    n39_proceso,n39_cod_trab,n39_periodo_ini,n39_periodo_fin) 
    constraint "fobos".pk_rolt039  ;
create index "fobos".i01_fk_rolt040 on "fobos".rolt040 (n40_compania,
    n40_proceso,n40_cod_trab,n40_periodo_ini,n40_periodo_fin) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_rolt040 on "fobos".rolt040 
    (n40_compania,n40_proceso,n40_cod_trab,n40_periodo_ini,n40_periodo_fin,
    n40_cod_rubro) using btree  in idxdbs ;
create index "fobos".i02_fk_rolt040 on "fobos".rolt040 (n40_compania,
    n40_cod_rubro) using btree  in idxdbs ;
create index "fobos".i03_fk_rolt040 on "fobos".rolt040 (n40_compania,
    n40_num_prest) using btree  in idxdbs ;
create index "fobos".i04_fk_rolt040 on "fobos".rolt040 (n40_proceso) 
    using btree  in idxdbs ;
alter table "fobos".rolt040 add constraint primary key (n40_compania,
    n40_proceso,n40_cod_trab,n40_periodo_ini,n40_periodo_fin,
    n40_cod_rubro) constraint "fobos".pk_rolt040  ;
create index "fobos".i01_fk_rolt055 on "fobos".rolt055 (n55_compania,
    n55_cod_trab) using btree  in idxdbs ;
create unique index "fobos".i01_pk_rolt055 on "fobos".rolt055 
    (n55_compania,n55_cod_trab,n55_periodo_ini,n55_periodo_fin,
    n55_secuencia,n55_fecha_ini) using btree  in idxdbs ;
alter table "fobos".rolt055 add constraint primary key (n55_compania,
    n55_cod_trab,n55_periodo_ini,n55_periodo_fin,n55_secuencia,
    n55_fecha_ini) constraint "fobos".pk_rolt055  ;
create index "fobos".i01_fk_rolt084 on "fobos".rolt084 (n84_compania) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_rolt084 on "fobos".rolt084 
    (n84_compania,n84_proceso,n84_cod_trab,n84_ano_proceso) using 
    btree  in idxdbs ;
create index "fobos".i02_fk_rolt084 on "fobos".rolt084 (n84_compania,
    n84_cod_trab) using btree  in idxdbs ;
create index "fobos".i03_fk_rolt084 on "fobos".rolt084 (n84_moneda) 
    using btree  in idxdbs ;
create index "fobos".i04_fk_rolt084 on "fobos".rolt084 (n84_proceso) 
    using btree  in idxdbs ;
create index "fobos".i05_fk_rolt084 on "fobos".rolt084 (n84_usuario) 
    using btree  in idxdbs ;
create index "fobos".i06_fk_rolt084 on "fobos".rolt084 (n84_usu_modifi) 
    using btree  in idxdbs ;
create index "fobos".i07_fk_rolt084 on "fobos".rolt084 (n84_usu_elimin) 
    using btree  in idxdbs ;
create index "fobos".i08_fk_rolt084 on "fobos".rolt084 (n84_usu_cierre) 
    using btree  in idxdbs ;
alter table "fobos".rolt084 add constraint primary key (n84_compania,
    n84_proceso,n84_cod_trab,n84_ano_proceso) constraint "fobos"
    .pk_rolt084  ;
create unique index "fobos".i1_tempo_011 on "fobos".tempo_011 
    (r11_compania,r11_bodega,r11_item) using btree  in idxdbs 
    ;
create unique index "fobos".i01_pk_rept090 on "fobos".rept090 
    (r90_compania,r90_localidad,r90_cod_tran,r90_num_tran) using 
    btree  in idxdbs ;
alter table "fobos".rept090 add constraint primary key (r90_compania,
    r90_localidad,r90_cod_tran,r90_num_tran) constraint "fobos"
    .pk_rept090  ;
create index "fobos".i01_fk_rolt041 on "fobos".rolt041 (n41_compania) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_rolt041 on "fobos".rolt041 
    (n41_compania,n41_proceso,n41_fecha_ini,n41_fecha_fin) using 
    btree  in idxdbs ;
create index "fobos".i02_fk_rolt041 on "fobos".rolt041 (n41_proceso) 
    using btree  in idxdbs ;
create index "fobos".i03_fk_rolt041 on "fobos".rolt041 (n41_moneda) 
    using btree  in idxdbs ;
create index "fobos".i04_fk_rolt041 on "fobos".rolt041 (n41_usuario) 
    using btree  in idxdbs ;
alter table "fobos".rolt041 add constraint primary key (n41_compania,
    n41_proceso,n41_fecha_ini,n41_fecha_fin) constraint "fobos"
    .pk_rolt041  ;
create index "fobos".i01_fk_rept085 on "fobos".rept085 (r85_compania,
    r85_division) using btree  in idxdbs ;
create unique index "fobos".i01_pk_rept085 on "fobos".rept085 
    (r85_compania,r85_codigo) using btree  in idxdbs ;
create index "fobos".i02_fk_rept085 on "fobos".rept085 (r85_compania,
    r85_division,r85_linea) using btree  in idxdbs ;
create index "fobos".i03_fk_rept085 on "fobos".rept085 (r85_compania,
    r85_division,r85_linea,r85_cod_grupo) using btree  in idxdbs 
    ;
create index "fobos".i04_fk_rept085 on "fobos".rept085 (r85_compania,
    r85_division,r85_linea,r85_cod_grupo,r85_cod_clase) using 
    btree  in idxdbs ;
create index "fobos".i05_fk_rept085 on "fobos".rept085 (r85_compania,
    r85_marca) using btree  in idxdbs ;
create index "fobos".i06_fk_rept085 on "fobos".rept085 (r85_compania,
    r85_cod_util) using btree  in idxdbs ;
create index "fobos".i07_fk_rept085 on "fobos".rept085 (r85_partida) 
    using btree  in idxdbs ;
create index "fobos".i08_fk_rept085 on "fobos".rept085 (r85_usuario) 
    using btree  in idxdbs ;
alter table "fobos".rept085 add constraint primary key (r85_compania,
    r85_codigo) constraint "fobos".pk_rept085  ;
create index "fobos".i01_fk_rept086 on "fobos".rept086 (r86_compania,
    r86_codigo) using btree  in idxdbs ;
create unique index "fobos".i01_pk_rept086 on "fobos".rept086 
    (r86_compania,r86_codigo,r86_secuencia) using btree  in idxdbs 
    ;
create index "fobos".i02_fk_rept086 on "fobos".rept086 (r86_compania,
    r86_item) using btree  in idxdbs ;
alter table "fobos".rept086 add constraint primary key (r86_compania,
    r86_codigo,r86_secuencia) constraint "fobos".pk_rept086  ;
    
create index "fobos".i01_fk_rolt064 on "fobos".rolt064 (n64_compania,
    n64_cod_trab) using btree  in idxdbs ;
create unique index "fobos".i01_pk_rolt064 on "fobos".rolt064 
    (n64_compania,n64_num_prest) using btree  in idxdbs ;
create index "fobos".i02_fk_rolt064 on "fobos".rolt064 (n64_compania,
    n64_cod_rubro) using btree  in idxdbs ;
create index "fobos".i03_fk_rolt064 on "fobos".rolt064 (n64_moneda) 
    using btree  in idxdbs ;
create index "fobos".i04_fk_rolt064 on "fobos".rolt064 (n64_usuario) 
    using btree  in idxdbs ;
alter table "fobos".rolt064 add constraint primary key (n64_compania,
    n64_num_prest) constraint "fobos".pk_rolt064  ;
create index "fobos".i01_fk_gent039 on "fobos".gent039 (g39_compania) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_gent039 on "fobos".gent039 
    (g39_compania,g39_localidad,g39_tipo_doc,g39_secuencia,g39_fec_entrega) 
    using btree  in idxdbs ;
create index "fobos".i02_fk_gent039 on "fobos".gent039 (g39_compania,
    g39_localidad) using btree  in idxdbs ;
create index "fobos".i03_fk_gent039 on "fobos".gent039 (g39_compania,
    g39_localidad,g39_tipo_doc) using btree  in idxdbs ;
create index "fobos".i04_fk_gent039 on "fobos".gent039 (g39_usuario) 
    using btree  in idxdbs ;
alter table "fobos".gent039 add constraint primary key (g39_compania,
    g39_localidad,g39_tipo_doc,g39_secuencia,g39_fec_entrega) 
    constraint "fobos".pk_gent039  ;
create index "fobos".i01_fk_rept087 on "fobos".rept087 (r87_compania,
    r87_item) using btree  in idxdbs ;
create unique index "fobos".i01_pk_rept087 on "fobos".rept087 
    (r87_compania,r87_localidad,r87_item,r87_secuencia) using 
    btree  in idxdbs ;
alter table "fobos".rept087 add constraint primary key (r87_compania,
    r87_localidad,r87_item,r87_secuencia) constraint "fobos".pk_rept087 
     ;
create index "fobos".i01_fk_cajt090 on "fobos".cajt090 (j90_usua_caja) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_cajt090 on "fobos".cajt090 
    (j90_localidad,j90_codigo_caja) using btree  in idxdbs ;
alter table "fobos".cajt090 add constraint primary key (j90_localidad,
    j90_codigo_caja) constraint "fobos".pk_cajt090  ;
create index "fobos".i01_fk_rept089 on "fobos".rept089 (r89_compania) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_rept089 on "fobos".rept089 
    (r89_compania,r89_localidad,r89_bodega,r89_item,r89_usuario,
    r89_anio,r89_mes) using btree  in idxdbs ;
create index "fobos".i02_fk_rept089 on "fobos".rept089 (r89_compania,
    r89_localidad) using btree  in idxdbs ;
create index "fobos".i03_fk_rept089 on "fobos".rept089 (r89_compania,
    r89_bodega) using btree  in idxdbs ;
create index "fobos".i04_fk_rept089 on "fobos".rept089 (r89_compania,
    r89_item) using btree  in idxdbs ;
create index "fobos".i05_fk_rept089 on "fobos".rept089 (r89_compania,
    r89_bodega,r89_item) using btree  in idxdbs ;
create index "fobos".i06_fk_rept089 on "fobos".rept089 (r89_usuario) 
    using btree  in idxdbs ;
create index "fobos".i07_fk_rept089 on "fobos".rept089 (r89_usu_modifi) 
    using btree  in idxdbs ;
create index "fobos".i08_fk_rept089 on "fobos".rept089 (r89_usuario,
    r89_secuencia) using btree  in idxdbs ;
alter table "fobos".rept089 add constraint primary key (r89_compania,
    r89_localidad,r89_bodega,r89_item,r89_usuario,r89_anio,r89_mes) 
    constraint "fobos".pk_rept089  ;
create index "fobos".i01_fk_rept093 on "fobos".rept093 (r93_cod_pedido) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_rept093 on "fobos".rept093 
    (r93_compania,r93_item) using btree  in idxdbs ;
create index "fobos".i02_fk_rept093 on "fobos".rept093 (r93_usuario) 
    using btree  in idxdbs ;
alter table "fobos".rept093 add constraint primary key (r93_compania,
    r93_item) constraint "fobos".pk_rept093  ;
create index "fobos".i01_fk_ctbt050 on "fobos".ctbt050 (b50_compania,
    b50_tipo_comp,b50_num_comp) using btree  in idxdbs ;
create unique index "fobos".i01_pk_ctbt050 on "fobos".ctbt050 
    (b50_compania,b50_tipo_comp,b50_num_comp,b50_anio) using 
    btree  in idxdbs ;
create index "fobos".i02_fk_ctbt050 on "fobos".ctbt050 (b50_usuario) 
    using btree  in idxdbs ;
alter table "fobos".ctbt050 add constraint primary key (b50_compania,
    b50_tipo_comp,b50_num_comp,b50_anio) constraint "fobos".pk_ctbt050 
     ;
create index "fobos".i01_fk_gent057 on "fobos".gent057 (g57_modulo,
    g57_proceso) using btree  in idxdbs ;
create unique index "fobos".i01_pk_gent057 on "fobos".gent057 
    (g57_user,g57_compania,g57_modulo,g57_proceso) using btree 
     in idxdbs ;
create index "fobos".i02_fk_gent057 on "fobos".gent057 (g57_compania) 
    using btree  in idxdbs ;
create index "fobos".i03_fk_gent057 on "fobos".gent057 (g57_user) 
    using btree  in idxdbs ;
create index "fobos".i04_fk_gent057 on "fobos".gent057 (g57_usuario) 
    using btree  in idxdbs ;
alter table "fobos".gent057 add constraint primary key (g57_user,
    g57_compania,g57_modulo,g57_proceso) constraint "fobos".pk_gent057 
     ;
create index "fobos".i01_fk_actt014 on "fobos".actt014 (a14_compania) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_actt014 on "fobos".actt014 
    (a14_compania,a14_codigo_bien,a14_anio,a14_mes) using btree 
     in idxdbs ;
create index "fobos".i02_fk_actt014 on "fobos".actt014 (a14_compania,
    a14_grupo_act) using btree  in idxdbs ;
create index "fobos".i03_fk_actt014 on "fobos".actt014 (a14_compania,
    a14_tipo_act) using btree  in idxdbs ;
create index "fobos".i04_fk_actt014 on "fobos".actt014 (a14_compania,
    a14_locali_ori) using btree  in idxdbs ;
create index "fobos".i05_fk_actt014 on "fobos".actt014 (a14_compania,
    a14_localidad) using btree  in idxdbs ;
create index "fobos".i06_fk_actt014 on "fobos".actt014 (a14_compania,
    a14_cod_depto) using btree  in idxdbs ;
create index "fobos".i07_fk_actt014 on "fobos".actt014 (a14_moneda) 
    using btree  in idxdbs ;
create index "fobos".i08_fk_actt014 on "fobos".actt014 (a14_compania,
    a14_tipo_comp,a14_num_comp) using btree  in idxdbs ;
create index "fobos".i09_fk_actt014 on "fobos".actt014 (a14_usuario) 
    using btree  in idxdbs ;
alter table "fobos".actt014 add constraint primary key (a14_compania,
    a14_codigo_bien,a14_anio,a14_mes) constraint "fobos".pk_actt014 
     ;
create index "fobos".i01_fk_cxct001 on "fobos".cxct001 (z01_pais) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_cxct001 on "fobos".cxct001 
    (z01_codcli) using btree  in idxdbs ;
create index "fobos".i02_fk_cxct001 on "fobos".cxct001 (z01_ciudad) 
    using btree  in idxdbs ;
create index "fobos".i03_fk_cxct001 on "fobos".cxct001 (z01_usuario) 
    using btree  in idxdbs ;
alter table "fobos".cxct001 add constraint primary key (z01_codcli) 
    constraint "fobos".pk_cxct001  ;
create unique index "fobos".i01_pk_trt_cxct001 on "fobos".tr_cxct001 
    (z01_codcli) using btree  in idxdbs ;
create index "fobos".i01_fk_cajt010 on "fobos".cajt010 (j10_compania) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_cajt010 on "fobos".cajt010 
    (j10_compania,j10_localidad,j10_tipo_fuente,j10_num_fuente) 
    using btree  in idxdbs ;
create index "fobos".i02_fk_cajt010 on "fobos".cajt010 (j10_compania,
    j10_localidad) using btree  in idxdbs ;
create index "fobos".i03_fk_cajt010 on "fobos".cajt010 (j10_compania,
    j10_areaneg) using btree  in idxdbs ;
create index "fobos".i04_fk_cajt010 on "fobos".cajt010 (j10_compania,
    j10_localidad,j10_codcli) using btree  in idxdbs ;
create index "fobos".i05_fk_cajt010 on "fobos".cajt010 (j10_moneda) 
    using btree  in idxdbs ;
create index "fobos".i06_fk_cajt010 on "fobos".cajt010 (j10_compania,
    j10_localidad,j10_codigo_caja) using btree  in idxdbs ;
create index "fobos".i07_fk_cajt010 on "fobos".cajt010 (j10_banco) 
    using btree  in idxdbs ;
create index "fobos".i08_fk_cajt010 on "fobos".cajt010 (j10_compania,
    j10_tip_contable,j10_num_contable) using btree  in idxdbs 
    ;
create index "fobos".i09_fk_cajt010 on "fobos".cajt010 (j10_usuario) 
    using btree  in idxdbs ;
alter table "fobos".cajt010 add constraint primary key (j10_compania,
    j10_localidad,j10_tipo_fuente,j10_num_fuente) constraint 
    "fobos".pk_cajt010  ;
create index "fobos".i01_fk_rept021 on "fobos".rept021 (r21_compania,
    r21_grupo_linea) using btree  in idxdbs ;
create unique index "fobos".i01_pk_rept021 on "fobos".rept021 
    (r21_compania,r21_localidad,r21_numprof) using btree  in 
    idxdbs ;
create index "fobos".i02_fk_rept021 on "fobos".rept021 (r21_compania,
    r21_bodega) using btree  in idxdbs ;
create index "fobos".i03_fk_rept021 on "fobos".rept021 (r21_compania) 
    using btree  in idxdbs ;
create index "fobos".i04_fk_rept021 on "fobos".rept021 (r21_compania,
    r21_localidad) using btree  in idxdbs ;
create index "fobos".i05_fk_rept021 on "fobos".rept021 (r21_compania,
    r21_localidad,r21_codcli) using btree  in idxdbs ;
create index "fobos".i06_fk_rept021 on "fobos".rept021 (r21_compania,
    r21_vendedor) using btree  in idxdbs ;
create index "fobos".i07_fk_rept021 on "fobos".rept021 (r21_moneda) 
    using btree  in idxdbs ;
create index "fobos".i08_fk_rept021 on "fobos".rept021 (r21_usuario) 
    using btree  in idxdbs ;
create index "fobos".i09_fk_rept021 on "fobos".rept021 (r21_compania,
    r21_localidad,r21_num_ot) using btree  in idxdbs ;
create index "fobos".i10_fk_rept021 on "fobos".rept021 (r21_compania,
    r21_localidad,r21_num_presup) using btree  in idxdbs ;
create index "fobos".i11_fk_rept021 on "fobos".rept021 (r21_usr_tr_fa) 
    using btree  in idxdbs ;
create index "fobos".i11_in_rept021 on "fobos".rept021 (r21_localidad,
    r21_fecing) using btree  in idxdbs ;
create index "fobos".i12_in_rept021 on "fobos".rept021 (r21_localidad,
    r21_fecing,r21_vendedor) using btree  in idxdbs ;
create index "fobos".i13_fk_rept021 on "fobos".rept021 (r21_compania,
    r21_localidad,r21_cod_tran,r21_num_tran) using btree  in 
    idxdbs ;
alter table "fobos".rept021 add constraint primary key (r21_compania,
    r21_localidad,r21_numprof) constraint "fobos".pk_rept021  
    ;
create index "fobos".i01_fk_rept023 on "fobos".rept023 (r23_compania) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_rept023 on "fobos".rept023 
    (r23_compania,r23_localidad,r23_numprev) using btree  in 
    idxdbs ;
create index "fobos".i02_fk_rept023 on "fobos".rept023 (r23_compania,
    r23_localidad) using btree  in idxdbs ;
create index "fobos".i03_fk_rept023 on "fobos".rept023 (r23_compania,
    r23_localidad,r23_codcli) using btree  in idxdbs ;
create index "fobos".i04_fk_rept023 on "fobos".rept023 (r23_compania,
    r23_vendedor) using btree  in idxdbs ;
create index "fobos".i05_fk_rept023 on "fobos".rept023 (r23_compania,
    r23_bodega) using btree  in idxdbs ;
create index "fobos".i06_fk_rept023 on "fobos".rept023 (r23_moneda) 
    using btree  in idxdbs ;
create index "fobos".i07_fk_rept023 on "fobos".rept023 (r23_usuario) 
    using btree  in idxdbs ;
create index "fobos".i08_fk_rept023 on "fobos".rept023 (r23_compania,
    r23_localidad,r23_cod_tran,r23_num_tran) using btree  in 
    idxdbs ;
create index "fobos".i09_fk_rept023 on "fobos".rept023 (r23_compania,
    r23_grupo_linea) using btree  in idxdbs ;
create index "fobos".i10_fk_rept023 on "fobos".rept023 (r23_compania,
    r23_localidad,r23_num_ot) using btree  in idxdbs ;
alter table "fobos".rept023 add constraint primary key (r23_compania,
    r23_localidad,r23_numprev) constraint "fobos".pk_rept023  
    ;
create index "fobos".i01_fk_rept088 on "fobos".rept088 (r88_codcli_nue) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_rept088 on "fobos".rept088 
    (r88_compania,r88_localidad,r88_cod_fact,r88_num_fact) using 
    btree  in idxdbs ;
create index "fobos".i02_fk_rept088 on "fobos".rept088 (r88_compania,
    r88_localidad,r88_ord_trabajo) using btree  in idxdbs ;
alter table "fobos".rept088 add constraint primary key (r88_compania,
    r88_localidad,r88_cod_fact,r88_num_fact) constraint "fobos"
    .pk_rept088  ;
create unique index "fobos".i01_pk_rept091 on "fobos".rept091 
    (r91_compania,r91_localidad,r91_cod_tran,r91_num_tran) using 
    btree  in idxdbs ;
alter table "fobos".rept091 add constraint primary key (r91_compania,
    r91_localidad,r91_cod_tran,r91_num_tran) constraint "fobos"
    .pk_rept091  ;
create index "fobos".i01_fk_talt020 on "fobos".talt020 (t20_compania) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_talt020 on "fobos".talt020 
    (t20_compania,t20_localidad,t20_numpre) using btree  in idxdbs 
    ;
create index "fobos".i02_fk_talt020 on "fobos".talt020 (t20_compania,
    t20_localidad) using btree  in idxdbs ;
create index "fobos".i04_fk_talt020 on "fobos".talt020 (t20_moneda) 
    using btree  in idxdbs ;
create index "fobos".i05_fk_talt020 on "fobos".talt020 (t20_usuario) 
    using btree  in idxdbs ;
create index "fobos".i06_fk_talt020 on "fobos".talt020 (t20_usu_modifi) 
    using btree  in idxdbs ;
create index "fobos".i07_fk_talt020 on "fobos".talt020 (t20_usu_elimin) 
    using btree  in idxdbs ;
alter table "fobos".talt020 add constraint primary key (t20_compania,
    t20_localidad,t20_numpre) constraint "fobos".pk_talt020  ;
    
create index "fobos".i01_fk_talt023 on "fobos".talt023 (t23_compania) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_talt023 on "fobos".talt023 
    (t23_compania,t23_localidad,t23_orden) using btree  in idxdbs 
    ;
create index "fobos".i02_fk_talt023 on "fobos".talt023 (t23_compania,
    t23_localidad) using btree  in idxdbs ;
create index "fobos".i03_fk_talt023 on "fobos".talt023 (t23_compania,
    t23_tipo_ot) using btree  in idxdbs ;
create index "fobos".i04_fk_talt023 on "fobos".talt023 (t23_compania,
    t23_tipo_ot,t23_subtipo_ot) using btree  in idxdbs ;
create index "fobos".i05_fk_talt023 on "fobos".talt023 (t23_compania,
    t23_localidad,t23_cod_cliente) using btree  in idxdbs ;
create index "fobos".i06_fk_talt023 on "fobos".talt023 (t23_compania,
    t23_localidad,t23_codcli_est) using btree  in idxdbs ;
create index "fobos".i07_fk_talt023 on "fobos".talt023 (t23_compania,
    t23_seccion) using btree  in idxdbs ;
create index "fobos".i08_fk_talt023 on "fobos".talt023 (t23_compania,
    t23_cod_asesor) using btree  in idxdbs ;
create index "fobos".i09_fk_talt023 on "fobos".talt023 (t23_compania,
    t23_cod_mecani) using btree  in idxdbs ;
create index "fobos".i10_fk_talt023 on "fobos".talt023 (t23_moneda) 
    using btree  in idxdbs ;
create index "fobos".i11_fk_talt023 on "fobos".talt023 (t23_compania,
    t23_modelo) using btree  in idxdbs ;
create index "fobos".i12_fk_talt023 on "fobos".talt023 (t23_compania,
    t23_cod_cliente,t23_modelo,t23_chasis) using btree  in idxdbs 
    ;
create index "fobos".i13_fk_talt023 on "fobos".talt023 (t23_usuario) 
    using btree  in idxdbs ;
create index "fobos".i14_fk_talt023 on "fobos".talt023 (t23_compania,
    t23_localidad,t23_numpre) using btree  in idxdbs ;
create index "fobos".i15_fk_talt023 on "fobos".talt023 (t23_usu_modifi) 
    using btree  in idxdbs ;
create index "fobos".i16_fk_talt023 on "fobos".talt023 (t23_usu_elimin) 
    using btree  in idxdbs ;
alter table "fobos".talt023 add constraint primary key (t23_compania,
    t23_localidad,t23_orden) constraint "fobos".pk_talt023  ;
create index "fobos".i01_fk_cxpt001 on "fobos".cxpt001 (p01_pais) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_cxpt001 on "fobos".cxpt001 
    (p01_codprov) using btree  in idxdbs ;
create index "fobos".i02_fk_cxpt001 on "fobos".cxpt001 (p01_ciudad) 
    using btree  in idxdbs ;
create index "fobos".i03_fk_cxpt001 on "fobos".cxpt001 (p01_usuario) 
    using btree  in idxdbs ;
alter table "fobos".cxpt001 add constraint primary key (p01_codprov) 
    constraint "fobos".pk_cxpt001  ;
create unique index "fobos".i01_pk_rept081 on "fobos".rept081 
    (r81_compania,r81_localidad,r81_pedido) using btree  in idxdbs 
    ;
create index "fobos".i02_fk_rept081 on "fobos".rept081 (r81_compania) 
    using btree  in idxdbs ;
create index "fobos".i03_fk_rept081 on "fobos".rept081 (r81_compania,
    r81_localidad) using btree  in idxdbs ;
create index "fobos".i04_fk_rept081 on "fobos".rept081 (r81_compania,
    r81_localidad,r81_cod_prov) using btree  in idxdbs ;
create index "fobos".i05_fk_rept081 on "fobos".rept081 (r81_moneda_base) 
    using btree  in idxdbs ;
create index "fobos".i07_fk_rept081 on "fobos".rept081 (r81_usuario) 
    using btree  in idxdbs ;
alter table "fobos".rept081 add constraint primary key (r81_compania,
    r81_localidad,r81_pedido) constraint "fobos".pk_rept081  ;
    
create index "fobos".i01_fk_talt061 on "fobos".talt061 (t61_compania,
    t61_cod_asesor) using btree  in idxdbs ;
create unique index "fobos".i01_pk_talt061 on "fobos".talt061 
    (t61_compania,t61_cod_asesor,t61_cod_vendedor) using btree 
     in idxdbs ;
create index "fobos".i02_fk_talt061 on "fobos".talt061 (t61_compania,
    t61_cod_vendedor) using btree  in idxdbs ;
alter table "fobos".talt061 add constraint primary key (t61_compania,
    t61_cod_asesor,t61_cod_vendedor) constraint "fobos".pk_talt061 
     ;
create unique index "fobos".i01_pk_rept094 on "fobos".rept094 
    (r94_compania,r94_localidad,r94_cod_tran,r94_num_tran) using 
    btree  in idxdbs ;
alter table "fobos".rept094 add constraint primary key (r94_compania,
    r94_localidad,r94_cod_tran,r94_num_tran) constraint "fobos"
    .pk_rept094  ;
create unique index "fobos".i01_pk_cxct060 on "fobos".cxct060 
    (z60_compania,z60_localidad) using btree  in idxdbs ;
alter table "fobos".cxct060 add constraint primary key (z60_compania,
    z60_localidad) constraint "fobos".pk_cxct060  ;
create index "fobos".i01_fk_talt060 on "fobos".talt060 (t60_compania) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_talt060 on "fobos".talt060 
    (t60_compania,t60_localidad,t60_ot_ant) using btree  in idxdbs 
    ;
create index "fobos".i02_fk_talt060 on "fobos".talt060 (t60_compania,
    t60_localidad) using btree  in idxdbs ;
create index "fobos".i03_fk_talt060 on "fobos".talt060 (t60_compania,
    t60_localidad,t60_num_dev) using btree  in idxdbs ;
create index "fobos".i04_fk_talt060 on "fobos".talt060 (t60_compania,
    t60_localidad,t60_ot_nue) using btree  in idxdbs ;
create index "fobos".i05_fk_talt060 on "fobos".talt060 (t60_codcli_nue) 
    using btree  in idxdbs ;
create index "fobos".i06_fk_talt060 on "fobos".talt060 (t60_usuario) 
    using btree  in idxdbs ;
alter table "fobos".talt060 add constraint primary key (t60_compania,
    t60_localidad,t60_ot_ant) constraint "fobos".pk_talt060  ;
    
create unique index "fobos".i1_tr_precios_ser on "fobos".tr_precios_ser 
    (te_compania,te_item) using btree  in idxdbs ;
create unique index "fobos".i2_tr_precios_ser on "fobos".tr_precios_ser 
    (te_compania,te_item,te_marca) using btree  in idxdbs ;
create index "fobos".i01_fk_rept095 on "fobos".rept095 (r95_usuario) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_rept095 on "fobos".rept095 
    (r95_compania,r95_localidad,r95_guia_remision) using btree 
     in idxdbs ;
create index "fobos".i02_fk_rept095 on "fobos".rept095 (r95_persona_id) 
    using btree  in idxdbs ;
create index "fobos".i03_fk_rept095 on "fobos".rept095 (r95_usu_elim) 
    using btree  in idxdbs ;
create index "fobos".i04_fk_rept095 on "fobos".rept095 (r95_compania,
    r95_localidad,r95_cod_zona) using btree  in idxdbs ;
create index "fobos".i05_fk_rept095 on "fobos".rept095 (r95_compania,
    r95_localidad,r95_cod_zona,r95_cod_subzona) using btree  
    in idxdbs ;
alter table "fobos".rept095 add constraint primary key (r95_compania,
    r95_localidad,r95_guia_remision) constraint "fobos".pk_rept095 
     ;
create index "fobos".i01_fk_rept096 on "fobos".rept096 (r96_compania,
    r96_localidad,r96_guia_remision) using btree  in idxdbs ;
    
create unique index "fobos".i01_pk_rept096 on "fobos".rept096 
    (r96_compania,r96_localidad,r96_guia_remision,r96_bodega,
    r96_num_entrega) using btree  in idxdbs ;
create index "fobos".i02_fk_rept096 on "fobos".rept096 (r96_compania,
    r96_localidad,r96_bodega,r96_num_entrega) using btree  in 
    idxdbs ;
alter table "fobos".rept096 add constraint primary key (r96_compania,
    r96_localidad,r96_guia_remision,r96_bodega,r96_num_entrega) 
    constraint "fobos".pk_rept096  ;
create index "fobos".i01_fk_rept097 on "fobos".rept097 (r97_compania,
    r97_localidad,r97_guia_remision) using btree  in idxdbs ;
    
create unique index "fobos".i01_pk_rept097 on "fobos".rept097 
    (r97_compania,r97_localidad,r97_guia_remision,r97_cod_tran,
    r97_num_tran) using btree  in idxdbs ;
create index "fobos".i02_fk_rept097 on "fobos".rept097 (r97_compania,
    r97_localidad,r97_cod_tran,r97_num_tran) using btree  in 
    idxdbs ;
alter table "fobos".rept097 add constraint primary key (r97_compania,
    r97_localidad,r97_guia_remision,r97_cod_tran,r97_num_tran) 
    constraint "fobos".pk_rept097  ;
create index "fobos".i01_fk_cxct061 on "fobos".cxct061 (z61_compania) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_cxct061 on "fobos".cxct061 
    (z61_compania,z61_localidad) using btree  in idxdbs ;
create index "fobos".i02_fk_cxct061 on "fobos".cxct061 (z61_usuario) 
    using btree  in idxdbs ;
alter table "fobos".cxct061 add constraint primary key (z61_compania,
    z61_localidad) constraint "fobos".pk_cxct061  ;
create index "fobos".i01_fk_cxct042 on "fobos".cxct042 (z42_compania,
    z42_localidad,z42_codcli,z42_tipo_doc,z42_num_doc,z42_dividendo) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_cxct042 on "fobos".cxct042 
    (z42_compania,z42_localidad,z42_codcli,z42_tipo_doc,z42_num_doc,
    z42_dividendo,z42_banco,z42_num_cta,z42_num_cheque,z42_secuencia) 
    using btree  in idxdbs ;
create index "fobos".i02_fk_cxct042 on "fobos".cxct042 (z42_compania,
    z42_localidad,z42_banco,z42_num_cta,z42_num_cheque,z42_secuencia) 
    using btree  in idxdbs ;
alter table "fobos".cxct042 add constraint primary key (z42_compania,
    z42_localidad,z42_codcli,z42_tipo_doc,z42_num_doc,z42_dividendo,
    z42_banco,z42_num_cta,z42_num_cheque,z42_secuencia) constraint 
    "fobos".pk_cxct042  ;
create index "fobos".i01_fk_ordt003 on "fobos".ordt003 (c03_compania,
    c03_tipo_ret,c03_porcentaje) using btree  in idxdbs ;
create unique index "fobos".i01_pk_ordt003 on "fobos".ordt003 
    (c03_compania,c03_tipo_ret,c03_porcentaje,c03_codigo_sri,
    c03_fecha_ini_porc) using btree  in idxdbs ;
create index "fobos".i02_fk_ordt003 on "fobos".ordt003 (c03_compania,
    c03_codigo_sri) using btree  in idxdbs ;
create index "fobos".i03_fk_ordt003 on "fobos".ordt003 (c03_usuario_modifi) 
    using btree  in idxdbs ;
create index "fobos".i04_fk_ordt003 on "fobos".ordt003 (c03_usuario_elimin) 
    using btree  in idxdbs ;
create index "fobos".i05_fk_ordt003 on "fobos".ordt003 (c03_usuario) 
    using btree  in idxdbs ;
alter table "fobos".ordt003 add constraint primary key (c03_compania,
    c03_tipo_ret,c03_porcentaje,c03_codigo_sri,c03_fecha_ini_porc) 
    constraint "fobos".pk_ordt003  ;
create index "fobos".i01_fk_srit000 on "fobos".srit000 (s00_usuario) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_srit000 on "fobos".srit000 
    (s00_compania) using btree  in idxdbs ;
alter table "fobos".srit000 add constraint primary key (s00_compania) 
    constraint "fobos".pk_srit000  ;
create index "fobos".i01_fk_srit001 on "fobos".srit001 (s01_compania) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_srit001 on "fobos".srit001 
    (s01_compania,s01_codigo) using btree  in idxdbs ;
create index "fobos".i02_fk_srit001 on "fobos".srit001 (s01_usuario) 
    using btree  in idxdbs ;
alter table "fobos".srit001 add constraint primary key (s01_compania,
    s01_codigo) constraint "fobos".pk_srit001  ;
create index "fobos".i01_fk_srit002 on "fobos".srit002 (s02_compania) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_srit002 on "fobos".srit002 
    (s02_compania,s02_ano,s02_mes_num) using btree  in idxdbs 
    ;
create index "fobos".i02_fk_srit002 on "fobos".srit002 (s02_usuario) 
    using btree  in idxdbs ;
alter table "fobos".srit002 add constraint primary key (s02_compania,
    s02_ano,s02_mes_num) constraint "fobos".pk_srit002  ;
create index "fobos".i01_fk_srit003 on "fobos".srit003 (s03_compania) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_srit003 on "fobos".srit003 
    (s03_compania,s03_codigo,s03_cod_ident) using btree  in idxdbs 
    ;
create index "fobos".i02_fk_srit003 on "fobos".srit003 (s03_usuario) 
    using btree  in idxdbs ;
alter table "fobos".srit003 add constraint primary key (s03_compania,
    s03_codigo,s03_cod_ident) constraint "fobos".pk_srit003  ;
    
create index "fobos".i01_fk_srit004 on "fobos".srit004 (s04_compania) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_srit004 on "fobos".srit004 
    (s04_compania,s04_codigo) using btree  in idxdbs ;
create index "fobos".i02_fk_srit004 on "fobos".srit004 (s04_usuario) 
    using btree  in idxdbs ;
alter table "fobos".srit004 add constraint primary key (s04_compania,
    s04_codigo) constraint "fobos".pk_srit004  ;
create index "fobos".i01_fk_srit005 on "fobos".srit005 (s05_compania) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_srit005 on "fobos".srit005 
    (s05_compania,s05_codigo) using btree  in idxdbs ;
create index "fobos".i02_fk_srit005 on "fobos".srit005 (s05_usuario) 
    using btree  in datadbs ;
alter table "fobos".srit005 add constraint primary key (s05_compania,
    s05_codigo) constraint "fobos".pk_srit005  ;
create index "fobos".i01_fk_srit006 on "fobos".srit006 (s06_compania) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_srit006 on "fobos".srit006 
    (s06_compania,s06_codigo) using btree  in idxdbs ;
create index "fobos".i02_fk_srit006 on "fobos".srit006 (s06_usuario) 
    using btree  in idxdbs ;
alter table "fobos".srit006 add constraint primary key (s06_compania,
    s06_codigo) constraint "fobos".pk_srit006  ;
create index "fobos".i01_fk_srit007 on "fobos".srit007 (s07_compania,
    s07_tipo_comp) using btree  in idxdbs ;
create unique index "fobos".i01_pk_srit007 on "fobos".srit007 
    (s07_compania,s07_tipo_comp,s07_sustento_tri) using btree 
     in idxdbs ;
create index "fobos".i02_fk_srit007 on "fobos".srit007 (s07_compania,
    s07_sustento_tri) using btree  in idxdbs ;
alter table "fobos".srit007 add constraint primary key (s07_compania,
    s07_tipo_comp,s07_sustento_tri) constraint "fobos".pk_srit007 
     ;
create index "fobos".i01_fk_srit008 on "fobos".srit008 (s08_compania) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_srit008 on "fobos".srit008 
    (s08_compania,s08_codigo) using btree  in idxdbs ;
create index "fobos".i02_fk_srit008 on "fobos".srit008 (s08_usuario) 
    using btree  in idxdbs ;
alter table "fobos".srit008 add constraint primary key (s08_compania,
    s08_codigo) constraint "fobos".pk_srit008  ;
create index "fobos".i01_fk_srit009 on "fobos".srit009 (s09_compania) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_srit009 on "fobos".srit009 
    (s09_compania,s09_codigo,s09_tipo_porc) using btree  in idxdbs 
    ;
create index "fobos".i02_fk_srit009 on "fobos".srit009 (s09_usuario) 
    using btree  in idxdbs ;
alter table "fobos".srit009 add constraint primary key (s09_compania,
    s09_codigo,s09_tipo_porc) constraint "fobos".pk_srit009  ;
    
create index "fobos".i01_fk_srit010 on "fobos".srit010 (s10_compania) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_srit010 on "fobos".srit010 
    (s10_compania,s10_codigo,s10_porcentaje_ice,s10_codigo_impto) 
    using btree  in idxdbs ;
create index "fobos".i03_fk_srit010 on "fobos".srit010 (s10_usuario) 
    using btree  in idxdbs ;
alter table "fobos".srit010 add constraint primary key (s10_compania,
    s10_codigo,s10_porcentaje_ice,s10_codigo_impto) constraint 
    "fobos".pk_srit010  ;
create index "fobos".i02_fk_srit011 on "fobos".srit011 (s11_usuario) 
    using btree  in idxdbs ;
create index "fobos".i11_fk_srit011 on "fobos".srit011 (s11_compania) 
    using btree  in idxdbs ;
create unique index "fobos".i11_pk_srit011 on "fobos".srit011 
    (s11_compania,s11_codigo) using btree  in idxdbs ;
alter table "fobos".srit011 add constraint primary key (s11_compania,
    s11_codigo) constraint "fobos".pk_srit011  ;
create index "fobos".i02_fk_srit012 on "fobos".srit012 (s12_usuario) 
    using btree  in idxdbs ;
create index "fobos".i12_fk_srit012 on "fobos".srit012 (s12_compania) 
    using btree  in idxdbs ;
create unique index "fobos".i12_pk_srit012 on "fobos".srit012 
    (s12_compania,s12_codigo) using btree  in idxdbs ;
alter table "fobos".srit012 add constraint primary key (s12_compania,
    s12_codigo) constraint "fobos".pk_srit012  ;
create index "fobos".i02_fk_srit013 on "fobos".srit013 (s13_usuario) 
    using btree  in idxdbs ;
create index "fobos".i13_fk_srit013 on "fobos".srit013 (s13_compania) 
    using btree  in idxdbs ;
create unique index "fobos".i13_pk_srit013 on "fobos".srit013 
    (s13_compania,s13_codigo) using btree  in idxdbs ;
alter table "fobos".srit013 add constraint primary key (s13_compania,
    s13_codigo) constraint "fobos".pk_srit013  ;
create index "fobos".i01_fk_srit014 on "fobos".srit014 (s14_compania) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_srit014 on "fobos".srit014 
    (s14_compania,s14_codigo,s14_porcentaje_ret) using btree 
     in idxdbs ;
create index "fobos".i02_fk_srit014 on "fobos".srit014 (s14_usuario) 
    using btree  in idxdbs ;
alter table "fobos".srit014 add constraint primary key (s14_compania,
    s14_codigo,s14_porcentaje_ret) constraint "fobos".pk_srit014 
     ;
create index "fobos".i01_fk_srit015 on "fobos".srit015 (s15_compania) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_srit015 on "fobos".srit015 
    (s15_compania,s15_codigo) using btree  in idxdbs ;
create index "fobos".i02_fk_srit015 on "fobos".srit015 (s15_usuario) 
    using btree  in idxdbs ;
alter table "fobos".srit015 add constraint primary key (s15_compania,
    s15_codigo) constraint "fobos".pk_srit015  ;
create index "fobos".i02_fk_srit016 on "fobos".srit016 (s16_usuario) 
    using btree  in idxdbs ;
create index "fobos".i16_fk_srit016 on "fobos".srit016 (s16_compania) 
    using btree  in idxdbs ;
create unique index "fobos".i16_pk_srit016 on "fobos".srit016 
    (s16_compania,s16_codigo) using btree  in idxdbs ;
alter table "fobos".srit016 add constraint primary key (s16_compania,
    s16_codigo) constraint "fobos".pk_srit016  ;
create index "fobos".i02_fk_srit017 on "fobos".srit017 (s17_usuario) 
    using btree  in idxdbs ;
create index "fobos".i17_fk_srit017 on "fobos".srit017 (s17_compania) 
    using btree  in idxdbs ;
create unique index "fobos".i17_pk_srit017 on "fobos".srit017 
    (s17_compania,s17_codigo) using btree  in idxdbs ;
alter table "fobos".srit017 add constraint primary key (s17_compania,
    s17_codigo) constraint "fobos".pk_srit017  ;
create index "fobos".i01_fk_srit018 on "fobos".srit018 (s18_compania,
    s18_sec_tran,s18_cod_ident) using btree  in idxdbs ;
create unique index "fobos".i01_pk_srit018 on "fobos".srit018 
    (s18_compania,s18_sec_tran,s18_cod_ident,s18_tipo_tran) using 
    btree  in idxdbs ;
create index "fobos".i02_fk_srit018 on "fobos".srit018 (s18_compania,
    s18_tipo_tran) using btree  in idxdbs ;
alter table "fobos".srit018 add constraint primary key (s18_compania,
    s18_sec_tran,s18_cod_ident,s18_tipo_tran) constraint "fobos"
    .pk_srit018  ;
create index "fobos".i01_fk_srit019 on "fobos".srit019 (s19_compania,
    s19_sec_tran,s19_cod_ident) using btree  in idxdbs ;
create unique index "fobos".i01_pk_srit019 on "fobos".srit019 
    (s19_compania,s19_sec_tran,s19_cod_ident,s19_tipo_comp,s19_tipo_doc) 
    using btree  in idxdbs ;
create index "fobos".i02_fk_srit019 on "fobos".srit019 (s19_compania,
    s19_tipo_comp) using btree  in idxdbs ;
create index "fobos".i03_fk_srit019 on "fobos".srit019 (s19_tipo_doc) 
    using btree  in idxdbs ;
alter table "fobos".srit019 add constraint primary key (s19_compania,
    s19_sec_tran,s19_cod_ident,s19_tipo_comp,s19_tipo_doc) constraint 
    "fobos".pk_srit019  ;
create index "fobos".i01_fk_srit020 on "fobos".srit020 (s20_compania,
    s20_tipo_tran) using btree  in idxdbs ;
create unique index "fobos".i01_pk_srit020 on "fobos".srit020 
    (s20_compania,s20_tipo_tran,s20_tipo_comp) using btree  in 
    idxdbs ;
create index "fobos".i02_fk_srit020 on "fobos".srit020 (s20_compania,
    s20_tipo_comp) using btree  in idxdbs ;
alter table "fobos".srit020 add constraint primary key (s20_compania,
    s20_tipo_tran,s20_tipo_comp) constraint "fobos".pk_srit020 
     ;
create index "fobos".i01_fk_srit021 on "fobos".srit021 (s21_usuario) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_srit021 on "fobos".srit021 
    (s21_compania,s21_localidad,s21_anio,s21_mes,s21_ident_cli,
    s21_num_doc_id,s21_tipo_comp) using btree  in idxdbs ;
create index "fobos".i02_fk_srit021 on "fobos".srit021 (s21_usuario_modif) 
    using btree  in idxdbs ;
alter table "fobos".srit021 add constraint primary key (s21_compania,
    s21_localidad,s21_anio,s21_mes,s21_ident_cli,s21_num_doc_id,
    s21_tipo_comp) constraint "fobos".pk_srit021  ;
create index "fobos".i01_fk_rept098 on "fobos".rept098 (r98_compania,
    r98_localidad,r98_cod_tran,r98_num_tran) using btree  in 
    idxdbs ;
create unique index "fobos".i01_pk_rept098 on "fobos".rept098 
    (r98_compania,r98_localidad,r98_vend_ant,r98_vend_nue,r98_secuencia) 
    using btree  in idxdbs ;
create index "fobos".i02_fk_rept098 on "fobos".rept098 (r98_codcli) 
    using btree  in idxdbs ;
create index "fobos".i03_fk_rept098 on "fobos".rept098 (r98_usuario) 
    using btree  in idxdbs ;
alter table "fobos".rept098 add constraint primary key (r98_compania,
    r98_localidad,r98_vend_ant,r98_vend_nue,r98_secuencia) constraint 
    "fobos".pk_rept098  ;
create index "fobos".i01_fk_rept099 on "fobos".rept099 (r99_compania,
    r99_localidad,r99_vend_ant,r99_vend_nue,r99_secuencia) using 
    btree  in idxdbs ;
create unique index "fobos".i01_pk_rept099 on "fobos".rept099 
    (r99_compania,r99_localidad,r99_vend_ant,r99_vend_nue,r99_secuencia,
    r99_orden) using btree  in idxdbs ;
create index "fobos".i02_fk_rept099 on "fobos".rept099 (r99_compania,
    r99_localidad,r99_cod_tran,r99_num_tran) using btree  in 
    idxdbs ;
alter table "fobos".rept099 add constraint primary key (r99_compania,
    r99_localidad,r99_vend_ant,r99_vend_nue,r99_secuencia,r99_orden) 
    constraint "fobos".pk_rept099  ;
create index "fobos".i01_fk_rept020 on "fobos".rept020 (r20_compania,
    r20_localidad,r20_cod_tran,r20_num_tran) using btree  in 
    idxdbs ;
create index "fobos".i02_fk_rept020 on "fobos".rept020 (r20_compania,
    r20_item) using btree  in idxdbs ;
create index "fobos".i03_fk_rept020 on "fobos".rept020 (r20_compania,
    r20_linea) using btree  in idxdbs ;
create index "fobos".i04_fk_rept020 on "fobos".rept020 (r20_compania,
    r20_rotacion) using btree  in idxdbs ;
create index "fobos".i05_in_rept020 on "fobos".rept020 (r20_compania,
    r20_localidad,r20_item,r20_fecing) using btree  in idxdbs 
    ;
create index "fobos".i01_fk_rolt056 on "fobos".rolt056 (n56_proceso) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_rolt056 on "fobos".rolt056 
    (n56_compania,n56_proceso,n56_cod_depto,n56_cod_trab) using 
    btree  in idxdbs ;
create index "fobos".i02_fk_rolt056 on "fobos".rolt056 (n56_compania,
    n56_cod_depto) using btree  in idxdbs ;
create index "fobos".i03_fk_rolt056 on "fobos".rolt056 (n56_compania,
    n56_cod_trab) using btree  in idxdbs ;
create index "fobos".i04_fk_rolt056 on "fobos".rolt056 (n56_compania,
    n56_aux_val_vac) using btree  in idxdbs ;
create index "fobos".i05_fk_rolt056 on "fobos".rolt056 (n56_compania,
    n56_aux_val_adi) using btree  in idxdbs ;
create index "fobos".i06_fk_rolt056 on "fobos".rolt056 (n56_compania,
    n56_aux_otr_ing) using btree  in idxdbs ;
create index "fobos".i07_fk_rolt056 on "fobos".rolt056 (n56_compania,
    n56_aux_iess) using btree  in idxdbs ;
create index "fobos".i08_fk_rolt056 on "fobos".rolt056 (n56_compania,
    n56_aux_otr_egr) using btree  in idxdbs ;
create index "fobos".i09_fk_rolt056 on "fobos".rolt056 (n56_compania,
    n56_aux_banco) using btree  in idxdbs ;
create index "fobos".i10_fk_rolt056 on "fobos".rolt056 (n56_usuario) 
    using btree  in idxdbs ;
alter table "fobos".rolt056 add constraint primary key (n56_compania,
    n56_proceso,n56_cod_depto,n56_cod_trab) constraint "fobos"
    .pk_rolt056  ;
create index "fobos".i01_fk_rolt057 on "fobos".rolt057 (n57_compania,
    n57_proceso,n57_cod_trab,n57_periodo_ini,n57_periodo_fin) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_rolt057 on "fobos".rolt057 
    (n57_compania,n57_proceso,n57_cod_trab,n57_periodo_ini,n57_periodo_fin,
    n57_tipo_comp,n57_num_comp) using btree  in idxdbs ;
create index "fobos".i02_fk_rolt057 on "fobos".rolt057 (n57_compania,
    n57_tipo_comp,n57_num_comp) using btree  in idxdbs ;
create index "fobos".i03_fk_rolt057 on "fobos".rolt057 (n57_proceso) 
    using btree  in idxdbs ;
alter table "fobos".rolt057 add constraint primary key (n57_compania,
    n57_proceso,n57_cod_trab,n57_periodo_ini,n57_periodo_fin,
    n57_tipo_comp,n57_num_comp) constraint "fobos".pk_rolt057 
     ;
create index "fobos".i01_fk_rolt090 on "fobos".rolt090 (n90_usuario) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_rolt090 on "fobos".rolt090 
    (n90_compania) using btree  in idxdbs ;
alter table "fobos".rolt090 add constraint primary key (n90_compania) 
    constraint "fobos".pk_rolt090  ;
create index "fobos".i01_fk_rolt058 on "fobos".rolt058 (n58_compania,
    n58_num_prest) using btree  in idxdbs ;
create unique index "fobos".i01_pk_rolt058 on "fobos".rolt058 
    (n58_compania,n58_num_prest,n58_proceso) using btree  in 
    idxdbs ;
create index "fobos".i02_fk_rolt058 on "fobos".rolt058 (n58_proceso) 
    using btree  in idxdbs ;
create index "fobos".i03_fk_rolt058 on "fobos".rolt058 (n58_usuario) 
    using btree  in idxdbs ;
alter table "fobos".rolt058 add constraint primary key (n58_compania,
    n58_num_prest,n58_proceso) constraint "fobos".pk_rolt058  
    ;
create index "fobos".i01_fk_rolt059 on "fobos".rolt059 (n59_compania,
    n59_num_prest) using btree  in idxdbs ;
create unique index "fobos".i01_pk_rolt059 on "fobos".rolt059 
    (n59_compania,n59_num_prest,n59_tipo_comp,n59_num_comp) using 
    btree  in idxdbs ;
create index "fobos".i02_fk_rolt059 on "fobos".rolt059 (n59_compania,
    n59_tipo_comp,n59_num_comp) using btree  in idxdbs ;
alter table "fobos".rolt059 add constraint primary key (n59_compania,
    n59_num_prest,n59_tipo_comp,n59_num_comp) constraint "fobos"
    .pk_rolt059  ;
create index "fobos".i01_fk_rolt091 on "fobos".rolt091 (n91_compania) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_rolt091 on "fobos".rolt091 
    (n91_compania,n91_proceso,n91_cod_trab,n91_num_ant) using 
    btree  in idxdbs ;
create index "fobos".i02_fk_rolt091 on "fobos".rolt091 (n91_proceso) 
    using btree  in idxdbs ;
create index "fobos".i03_fk_rolt091 on "fobos".rolt091 (n91_compania,
    n91_cod_trab) using btree  in idxdbs ;
create index "fobos".i04_fk_rolt091 on "fobos".rolt091 (n91_bco_empresa) 
    using btree  in idxdbs ;
create index "fobos".i05_fk_rolt091 on "fobos".rolt091 (n91_compania,
    n91_bco_empresa,n91_cta_empresa) using btree  in idxdbs ;
    
create index "fobos".i06_fk_rolt091 on "fobos".rolt091 (n91_proc_vac) 
    using btree  in idxdbs ;
create index "fobos".i07_fk_rolt091 on "fobos".rolt091 (n91_usuario) 
    using btree  in idxdbs ;
create index "fobos".i08_fk_rolt091 on "fobos".rolt091 (n91_compania,
    n91_tipo_comp,n91_num_comp) using btree  in idxdbs ;
alter table "fobos".rolt091 add constraint primary key (n91_compania,
    n91_proceso,n91_cod_trab,n91_num_ant) constraint "fobos".pk_rolt091 
     ;
create index "fobos".i01_fk_srit023 on "fobos".srit023 (s23_tipo_orden) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_srit023 on "fobos".srit023 
    (s23_compania,s23_tipo_orden,s23_sustento_sri,s23_secuencia) 
    using btree  in idxdbs ;
create index "fobos".i02_fk_srit023 on "fobos".srit023 (s23_compania,
    s23_sustento_sri) using btree  in idxdbs ;
create index "fobos".i03_fk_srit023 on "fobos".srit023 (s23_compania,
    s23_aux_cont) using btree  in idxdbs ;
create index "fobos".i04_fk_srit023 on "fobos".srit023 (s23_usuario) 
    using btree  in idxdbs ;
alter table "fobos".srit023 add constraint primary key (s23_compania,
    s23_tipo_orden,s23_sustento_sri,s23_secuencia) constraint 
    "fobos".pk_srit023  ;
create index "fobos".i01_fk_rolt092 on "fobos".rolt092 (n92_compania,
    n92_proceso,n92_cod_trab,n92_num_ant) using btree  in idxdbs 
    ;
create unique index "fobos".i01_pk_rolt092 on "fobos".rolt092 
    (n92_compania,n92_proceso,n92_cod_trab,n92_num_ant,n92_num_prest,
    n92_secuencia) using btree  in idxdbs ;
create index "fobos".i02_fk_rolt092 on "fobos".rolt092 (n92_compania) 
    using btree  in idxdbs ;
create index "fobos".i03_fk_rolt092 on "fobos".rolt092 (n92_proceso) 
    using btree  in idxdbs ;
create index "fobos".i04_fk_rolt092 on "fobos".rolt092 (n92_compania,
    n92_cod_trab) using btree  in idxdbs ;
create index "fobos".i05_fk_rolt092 on "fobos".rolt092 (n92_compania,
    n92_num_prest,n92_secuencia) using btree  in idxdbs ;
create index "fobos".i06_fk_rolt092 on "fobos".rolt092 (n92_cod_liqrol) 
    using btree  in idxdbs ;
alter table "fobos".rolt092 add constraint primary key (n92_compania,
    n92_proceso,n92_cod_trab,n92_num_ant,n92_num_prest,n92_secuencia) 
    constraint "fobos".pk_rolt092  ;
create index "fobos".i01_fk_cxpt029 on "fobos".cxpt029 (p29_compania,
    p29_localidad,p29_num_ret) using btree  in idxdbs ;
create unique index "fobos".i01_pk_cxpt029 on "fobos".cxpt029 
    (p29_compania,p29_localidad,p29_num_ret,p29_num_sri) using 
    btree  in idxdbs ;
alter table "fobos".cxpt029 add constraint primary key (p29_compania,
    p29_localidad,p29_num_ret,p29_num_sri) constraint "fobos".pk_cxpt029 
     ;
create index "fobos".i01_fk_cxpt032 on "fobos".cxpt032 (p32_compania,
    p32_localidad,p32_num_ret) using btree  in idxdbs ;
create unique index "fobos".i01_pk_cxpt032 on "fobos".cxpt032 
    (p32_compania,p32_localidad,p32_num_ret,p32_tipo_doc,p32_secuencia) 
    using btree  in idxdbs ;
create index "fobos".i02_fk_cxpt032 on "fobos".cxpt032 (p32_compania,
    p32_localidad,p32_tipo_doc,p32_secuencia) using btree  in 
    idxdbs ;
alter table "fobos".cxpt032 add constraint primary key (p32_compania,
    p32_localidad,p32_num_ret,p32_tipo_doc,p32_secuencia) constraint 
    "fobos".pk_cxpt032  ;
create index "fobos".i01_fk_gent058 on "fobos".gent058 (g58_compania) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_gent058 on "fobos".gent058 
    (g58_compania,g58_localidad,g58_tipo_impto,g58_porc_impto,
    g58_tipo) using btree  in idxdbs ;
create index "fobos".i02_fk_gent058 on "fobos".gent058 (g58_compania,
    g58_localidad) using btree  in idxdbs ;
create index "fobos".i03_fk_gent058 on "fobos".gent058 (g58_compania,
    g58_aux_cont) using btree  in idxdbs ;
create index "fobos".i04_fk_gent058 on "fobos".gent058 (g58_usuario) 
    using btree  in idxdbs ;
alter table "fobos".gent058 add constraint primary key (g58_compania,
    g58_localidad,g58_tipo_impto,g58_porc_impto,g58_tipo) constraint 
    "fobos".pk_gent058  ;
create index "fobos".i01_fk_ctbt013 on "fobos".ctbt013 (b13_compania,
    b13_tipo_comp,b13_num_comp) using btree  in idxdbs ;
create unique index "fobos".i01_pk_ctbt013 on "fobos".ctbt013 
    (b13_compania,b13_tipo_comp,b13_num_comp,b13_secuencia) using 
    btree  in idxdbs ;
create index "fobos".i02_fk_ctbt013 on "fobos".ctbt013 (b13_compania,
    b13_cuenta) using btree  in idxdbs ;
create index "fobos".i03_fk_ctbt013 on "fobos".ctbt013 (b13_compania,
    b13_num_concil) using btree  in idxdbs ;
create index "fobos".i04_fk_ctbt013 on "fobos".ctbt013 (b13_compania,
    b13_filtro) using btree  in idxdbs ;
create index "fobos".i05_fk_ctbt013 on "fobos".ctbt013 (b13_codprov) 
    using btree  in idxdbs ;
create index "fobos".i06_fk_ctbt013 on "fobos".ctbt013 (b13_compania,
    b13_cuenta,b13_codprov) using btree  in idxdbs ;
alter table "fobos".ctbt013 add constraint primary key (b13_compania,
    b13_tipo_comp,b13_num_comp,b13_secuencia) constraint "fobos"
    .pk_ctbt013  ;
create index "fobos".i01_fk_ordt001 on "fobos".ordt001 (c01_modulo) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_ordt001 on "fobos".ordt001 
    (c01_tipo_orden) using btree  in idxdbs ;
create index "fobos".i02_fk_ordt001 on "fobos".ordt001 (c01_usuario) 
    using btree  in idxdbs ;
alter table "fobos".ordt001 add constraint primary key (c01_tipo_orden) 
    constraint "fobos".pk_ordt001  ;
create index "fobos".i01_fk_gent002 on "fobos".gent002 (g02_compania) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_gent002 on "fobos".gent002 
    (g02_compania,g02_localidad) using btree  in idxdbs ;
create index "fobos".i02_fk_gent002 on "fobos".gent002 (g02_ciudad) 
    using btree  in idxdbs ;
create index "fobos".i03_fk_gent002 on "fobos".gent002 (g02_usuario) 
    using btree  in idxdbs ;
alter table "fobos".gent002 add constraint primary key (g02_compania,
    g02_localidad) constraint "fobos".pk_gent002  ;
create unique index "fobos".i01_pk_tr_cesa on "fobos".tr_cesantia 
    (compania,cod_liqrol,anio_cen,mes_cen,cod_trab) using btree 
     in idxdbs ;
alter table "fobos".tr_cesantia add constraint primary key (compania,
    cod_liqrol,anio_cen,mes_cen,cod_trab) constraint "fobos".pk_tr_cesa 
     ;
create index "fobos".i01_fk_srit024 on "fobos".srit024 (s24_compania,
    s24_codigo,s24_porcentaje_ice,s24_codigo_impto) using btree 
     in idxdbs ;
create unique index "fobos".i01_pk_srit024 on "fobos".srit024 
    (s24_compania,s24_codigo,s24_porcentaje_ice,s24_codigo_impto,
    s24_tipo_orden) using btree  in idxdbs ;
create index "fobos".i02_fk_srit024 on "fobos".srit024 (s24_tipo_orden) 
    using btree  in idxdbs ;
create index "fobos".i03_fk_srit024 on "fobos".srit024 (s24_compania) 
    using btree  in idxdbs ;
create index "fobos".i04_fk_srit024 on "fobos".srit024 (s24_compania,
    s24_aux_cont) using btree  in idxdbs ;
create index "fobos".i05_fk_srit024 on "fobos".srit024 (s24_usuario) 
    using btree  in idxdbs ;
alter table "fobos".srit024 add constraint primary key (s24_compania,
    s24_codigo,s24_porcentaje_ice,s24_codigo_impto,s24_tipo_orden) 
    constraint "fobos".pk_srit024  ;
create index "fobos".i01_fk_rept041 on "fobos".rept041 (r41_compania,
    r41_localidad,r41_cod_tran,r41_num_tran) using btree  in 
    idxdbs ;
create unique index "fobos".i01_pk_rept041 on "fobos".rept041 
    (r41_compania,r41_localidad,r41_cod_tran,r41_num_tran,r41_cod_tr,
    r41_num_tr) using btree  in idxdbs ;
create index "fobos".i02_fk_rept041 on "fobos".rept041 (r41_compania,
    r41_localidad,r41_cod_tr,r41_num_tr) using btree  in idxdbs 
    ;
alter table "fobos".rept041 add constraint primary key (r41_compania,
    r41_localidad,r41_cod_tran,r41_num_tran,r41_cod_tr,r41_num_tr) 
    constraint "fobos".pk_rept041  ;
create index "fobos".i01_fk_rolt018 on "fobos".rolt018 (n18_cod_rubro) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_rolt018 on "fobos".rolt018 
    (n18_cod_rubro,n18_flag_ident) using btree  in idxdbs ;
create index "fobos".i02_fk_rolt018 on "fobos".rolt018 (n18_flag_ident) 
    using btree  in idxdbs ;
create index "fobos".i03_fk_rolt018 on "fobos".rolt018 (n18_usuario) 
    using btree  in idxdbs ;
alter table "fobos".rolt018 add constraint primary key (n18_cod_rubro,
    n18_flag_ident) constraint "fobos".pk_rolt018  ;
create index "fobos".i01_fk_rept042 on "fobos".rept042 (r42_compania,
    r42_localidad,r42_cod_tran,r42_num_tran) using btree  in 
    idxdbs ;
create unique index "fobos".i01_pk_rept042 on "fobos".rept042 
    (r42_compania,r42_localidad,r42_cod_tran,r42_num_tran,r42_cod_tr_re,
    r42_num_tr_re) using btree  in idxdbs ;
create index "fobos".i02_fk_rept042 on "fobos".rept042 (r42_compania,
    r42_localidad,r42_cod_tr_re,r42_num_tr_re) using btree  in 
    idxdbs ;
alter table "fobos".rept042 add constraint primary key (r42_compania,
    r42_localidad,r42_cod_tran,r42_num_tran,r42_cod_tr_re,r42_num_tr_re) 
    constraint "fobos".pk_rept042  ;
create index "fobos".i01_fk_rolt049 on "fobos".rolt049 (n49_compania,
    n49_proceso,n49_cod_trab,n49_fecha_ini,n49_fecha_fin) using 
    btree  in idxdbs ;
create unique index "fobos".i01_pk_rolt049 on "fobos".rolt049 
    (n49_compania,n49_proceso,n49_cod_trab,n49_fecha_ini,n49_fecha_fin,
    n49_cod_rubro) using btree  in idxdbs ;
create index "fobos".i02_fk_rolt049 on "fobos".rolt049 (n49_proceso) 
    using btree  in idxdbs ;
create index "fobos".i03_fk_rolt049 on "fobos".rolt049 (n49_compania,
    n49_cod_rubro) using btree  in idxdbs ;
create index "fobos".i04_fk_rolt049 on "fobos".rolt049 (n49_compania,
    n49_num_prest) using btree  in idxdbs ;
alter table "fobos".rolt049 add constraint primary key (n49_compania,
    n49_proceso,n49_cod_trab,n49_fecha_ini,n49_fecha_fin,n49_cod_rubro) 
    constraint "fobos".pk_rolt049  ;
create index "fobos".i01_fk_cajt014 on "fobos".cajt014 (j14_compania,
    j14_localidad,j14_tipo_fuente,j14_num_fuente,j14_secuencia) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_cajt014 on "fobos".cajt014 
    (j14_compania,j14_localidad,j14_tipo_fuente,j14_num_fuente,
    j14_secuencia,j14_codigo_pago,j14_num_ret_sri,j14_sec_ret) 
    using btree  in idxdbs ;
create index "fobos".i02_fk_cajt014 on "fobos".cajt014 (j14_compania,
    j14_tipo_ret,j14_porc_ret) using btree  in idxdbs ;
create index "fobos".i03_fk_cajt014 on "fobos".cajt014 (j14_compania,
    j14_tipo_ret,j14_porc_ret,j14_codigo_sri,j14_fec_ini_porc) 
    using btree  in idxdbs ;
create index "fobos".i04_fk_cajt014 on "fobos".cajt014 (j14_compania,
    j14_codigo_pago,j14_cont_cred) using btree  in idxdbs ;
create index "fobos".i05_fk_cajt014 on "fobos".cajt014 (j14_compania,
    j14_localidad,j14_tipo_doc,j14_tipo_fue,j14_cod_tran,j14_num_tran) 
    using btree  in idxdbs ;
create index "fobos".i06_fk_cajt014 on "fobos".cajt014 (j14_compania,
    j14_tipo_comp,j14_num_comp) using btree  in idxdbs ;
create index "fobos".i07_fk_cajt014 on "fobos".cajt014 (j14_usuario) 
    using btree  in idxdbs ;
alter table "fobos".cajt014 add constraint primary key (j14_compania,
    j14_localidad,j14_tipo_fuente,j14_num_fuente,j14_secuencia,
    j14_codigo_pago,j14_num_ret_sri,j14_sec_ret) constraint "fobos"
    .pk_cajt014  ;
create index "fobos".i01_fk_cxct008 on "fobos".cxct008 (z08_compania) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_cxct008 on "fobos".cxct008 
    (z08_compania,z08_codcli,z08_tipo_ret,z08_porcentaje,z08_codigo_sri,
    z08_fecha_ini_porc) using btree  in idxdbs ;
create index "fobos".i02_fk_cxct008 on "fobos".cxct008 (z08_codcli) 
    using btree  in idxdbs ;
create index "fobos".i03_fk_cxct008 on "fobos".cxct008 (z08_compania,
    z08_tipo_ret,z08_porcentaje) using btree  in idxdbs ;
create index "fobos".i04_fk_cxct008 on "fobos".cxct008 (z08_compania,
    z08_tipo_ret,z08_porcentaje,z08_codigo_sri,z08_fecha_ini_porc) 
    using btree  in idxdbs ;
create index "fobos".i05_fk_cxct008 on "fobos".cxct008 (z08_usuario) 
    using btree  in idxdbs ;
alter table "fobos".cxct008 add constraint primary key (z08_compania,
    z08_codcli,z08_tipo_ret,z08_porcentaje,z08_codigo_sri,z08_fecha_ini_porc) 
    constraint "fobos".pk_cxct008  ;
create index "fobos".i01_fk_cxct009 on "fobos".cxct009 (z09_compania,
    z09_codcli,z09_tipo_ret,z09_porcentaje,z09_codigo_sri) using 
    btree  in idxdbs ;
create unique index "fobos".i01_pk_cxct009 on "fobos".cxct009 
    (z09_compania,z09_codcli,z09_tipo_ret,z09_porcentaje,z09_codigo_sri,
    z09_fecha_ini_porc,z09_codigo_pago,z09_cont_cred) using btree 
     in idxdbs ;
create index "fobos".i02_fk_cxct009 on "fobos".cxct009 (z09_compania) 
    using btree  in idxdbs ;
create index "fobos".i03_fk_cxct009 on "fobos".cxct009 (z09_codcli) 
    using btree  in idxdbs ;
create index "fobos".i04_fk_cxct009 on "fobos".cxct009 (z09_compania,
    z09_tipo_ret,z09_porcentaje) using btree  in idxdbs ;
create index "fobos".i05_fk_cxct009 on "fobos".cxct009 (z09_compania,
    z09_tipo_ret,z09_porcentaje,z09_codigo_sri,z09_fecha_ini_porc) 
    using btree  in idxdbs ;
create index "fobos".i06_fk_cxct009 on "fobos".cxct009 (z09_compania,
    z09_codigo_pago,z09_cont_cred) using btree  in idxdbs ;
create index "fobos".i07_fk_cxct009 on "fobos".cxct009 (z09_compania,
    z09_aux_cont) using btree  in idxdbs ;
create index "fobos".i08_fk_cxct009 on "fobos".cxct009 (z09_usuario) 
    using btree  in idxdbs ;
alter table "fobos".cxct009 add constraint primary key (z09_compania,
    z09_codcli,z09_tipo_ret,z09_porcentaje,z09_codigo_sri,z09_fecha_ini_porc,
    z09_codigo_pago,z09_cont_cred) constraint "fobos".pk_cxct009 
     ;
create index "fobos".i01_fk_cajt091 on "fobos".cajt091 (j91_compania,
    j91_codigo_pago,j91_cont_cred) using btree  in idxdbs ;
create unique index "fobos".i01_pk_cajt091 on "fobos".cajt091 
    (j91_compania,j91_codigo_pago,j91_cont_cred,j91_tipo_ret,
    j91_porcentaje) using btree  in idxdbs ;
create index "fobos".i02_fk_cajt091 on "fobos".cajt091 (j91_compania,
    j91_tipo_ret,j91_porcentaje) using btree  in idxdbs ;
create index "fobos".i03_fk_cajt091 on "fobos".cajt091 (j91_compania,
    j91_aux_cont) using btree  in idxdbs ;
create index "fobos".i04_fk_cajt091 on "fobos".cajt091 (j91_usuario) 
    using btree  in idxdbs ;
alter table "fobos".cajt091 add constraint primary key (j91_compania,
    j91_codigo_pago,j91_cont_cred,j91_tipo_ret,j91_porcentaje) 
    constraint "fobos".pk_cajt091  ;
create index "fobos".i01_fk_srit025 on "fobos".srit025 (s25_compania,
    s25_tipo_ret,s25_porcentaje,s25_codigo_sri,s25_fecha_ini_porc) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_srit025 on "fobos".srit025 
    (s25_compania,s25_tipo_ret,s25_porcentaje,s25_codigo_sri,
    s25_fecha_ini_porc,s25_cliprov) using btree  in idxdbs ;
create index "fobos".i02_fk_srit025 on "fobos".srit025 (s25_usuario) 
    using btree  in idxdbs ;
alter table "fobos".srit025 add constraint primary key (s25_compania,
    s25_tipo_ret,s25_porcentaje,s25_codigo_sri,s25_fecha_ini_porc,
    s25_cliprov) constraint "fobos".pk_srit025  ;
create index "fobos".i01_fk_rolt015 on "fobos".rolt015 (n15_compania) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_rolt015 on "fobos".rolt015 
    (n15_compania,n15_ano,n15_secuencia) using btree  in idxdbs 
    ;
create index "fobos".i02_fk_rolt015 on "fobos".rolt015 (n15_usuario) 
    using btree  in idxdbs ;
alter table "fobos".rolt015 add constraint primary key (n15_compania,
    n15_ano,n15_secuencia) constraint "fobos".pk_rolt015  ;
create index "fobos".i01_fk_rolt085 on "fobos".rolt085 (n85_compania,
    n85_proceso,n85_cod_trab,n85_ano_proceso) using btree  in 
    idxdbs ;
create unique index "fobos".i01_pk_rolt085 on "fobos".rolt085 
    (n85_compania,n85_proceso,n85_cod_trab,n85_ano_proceso,n85_mes_proceso) 
    using btree  in idxdbs ;
create index "fobos".i02_fk_rolt085 on "fobos".rolt085 (n85_compania) 
    using btree  in idxdbs ;
create index "fobos".i03_fk_rolt085 on "fobos".rolt085 (n85_proceso) 
    using btree  in idxdbs ;
create index "fobos".i04_fk_rolt085 on "fobos".rolt085 (n85_compania,
    n85_cod_trab) using btree  in idxdbs ;
create index "fobos".i05_fk_rolt085 on "fobos".rolt085 (n85_usuario) 
    using btree  in idxdbs ;
create index "fobos".i06_fk_rolt085 on "fobos".rolt085 (n85_usu_modifi) 
    using btree  in idxdbs ;
create index "fobos".i07_fk_rolt085 on "fobos".rolt085 (n85_usu_cierre) 
    using btree  in idxdbs ;
alter table "fobos".rolt085 add constraint primary key (n85_compania,
    n85_proceso,n85_cod_trab,n85_ano_proceso,n85_mes_proceso) 
    constraint "fobos".pk_rolt085  ;
create index "fobos".i01_fk_ctbt044 on "fobos".ctbt044 (b44_usuario) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_ctbt044 on "fobos".ctbt044 
    (b44_compania,b44_localidad,b44_modulo,b44_bodega,b44_grupo_linea,
    b44_porc_impto,b44_tipo_cli) using btree  in idxdbs ;
alter table "fobos".ctbt044 add constraint primary key (b44_compania,
    b44_localidad,b44_modulo,b44_bodega,b44_grupo_linea,b44_porc_impto,
    b44_tipo_cli) constraint "fobos".pk_ctbt044  ;
create index "fobos".i01_fk_ctbt045 on "fobos".ctbt045 (b45_usuario) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_ctbt045 on "fobos".ctbt045 
    (b45_compania,b45_localidad,b45_grupo_linea,b45_porc_impto,
    b45_tipo_cli) using btree  in idxdbs ;
alter table "fobos".ctbt045 add constraint primary key (b45_compania,
    b45_localidad,b45_grupo_linea,b45_porc_impto,b45_tipo_cli) 
    constraint "fobos".pk_ctbt045  ;
create index "fobos".i01_fk_rolt022 on "fobos".rolt022 (n22_compania) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_rolt022 on "fobos".rolt022 
    (n22_compania,n22_codigo_arch,n22_tipo_arch) using btree 
     in idxdbs ;
create index "fobos".i02_fk_rolt022 on "fobos".rolt022 (n22_proceso) 
    using btree  in idxdbs ;
create index "fobos".i03_fk_rolt022 on "fobos".rolt022 (n22_usuario) 
    using btree  in idxdbs ;
alter table "fobos".rolt022 add constraint primary key (n22_compania,
    n22_codigo_arch,n22_tipo_arch) constraint "fobos".pk_rolt022 
     ;
create index "fobos".i01_fk_rolt023 on "fobos".rolt023 (n23_compania,
    n23_codigo_arch,n23_tipo_arch) using btree  in idxdbs ;
create unique index "fobos".i01_pk_rolt023 on "fobos".rolt023 
    (n23_compania,n23_codigo_arch,n23_tipo_arch,n23_tipo_causa,
    n23_secuencia) using btree  in idxdbs ;
create index "fobos".i02_fk_rolt023 on "fobos".rolt023 (n23_compania) 
    using btree  in idxdbs ;
create index "fobos".i03_fk_rolt023 on "fobos".rolt023 (n23_flag_ident) 
    using btree  in idxdbs ;
create index "fobos".i04_fk_rolt023 on "fobos".rolt023 (n23_usuario) 
    using btree  in idxdbs ;
alter table "fobos".rolt023 add constraint primary key (n23_compania,
    n23_codigo_arch,n23_tipo_arch,n23_tipo_causa,n23_secuencia) 
    constraint "fobos".pk_rolt023  ;
create index "fobos".i01_fk_rolt024 on "fobos".rolt024 (n24_compania,
    n24_codigo_arch,n24_tipo_arch) using btree  in idxdbs ;
create unique index "fobos".i01_pk_rolt024 on "fobos".rolt024 
    (n24_compania,n24_codigo_arch,n24_tipo_arch,n24_tipo_seg_pag,
    n24_tipo) using btree  in idxdbs ;
create index "fobos".i02_fk_rolt024 on "fobos".rolt024 (n24_compania) 
    using btree  in idxdbs ;
create index "fobos".i03_fk_rolt024 on "fobos".rolt024 (n24_usuario) 
    using btree  in idxdbs ;
alter table "fobos".rolt024 add constraint primary key (n24_compania,
    n24_codigo_arch,n24_tipo_arch,n24_tipo_seg_pag,n24_tipo) 
    constraint "fobos".pk_rolt024  ;
create index "fobos".i01_fk_rolt025 on "fobos".rolt025 (n25_compania,
    n25_codigo_arch,n25_tipo_arch) using btree  in idxdbs ;
create unique index "fobos".i01_pk_rolt025 on "fobos".rolt025 
    (n25_compania,n25_codigo_arch,n25_tipo_arch,n25_tipo_emp_rel,
    n25_tipo) using btree  in idxdbs ;
create index "fobos".i02_fk_rolt025 on "fobos".rolt025 (n25_compania) 
    using btree  in idxdbs ;
create index "fobos".i03_fk_rolt025 on "fobos".rolt025 (n25_usuario) 
    using btree  in idxdbs ;
create index "fobos".i04_fk_rolt025 on "fobos".rolt025 (n25_compania,
    n25_codigo_arch,n25_tipo_arch,n25_tipo_codigo,n25_sub_tipo) 
    using btree  in idxdbs ;
alter table "fobos".rolt025 add constraint primary key (n25_compania,
    n25_codigo_arch,n25_tipo_arch,n25_tipo_emp_rel,n25_tipo) 
    constraint "fobos".pk_rolt025  ;
create index "fobos".i01_fk_rolt026 on "fobos".rolt026 (n26_compania) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_rolt026 on "fobos".rolt026 
    (n26_compania,n26_ano_proceso,n26_mes_proceso,n26_codigo_arch,
    n26_tipo_arch,n26_secuencia) using btree  in idxdbs ;
create index "fobos".i02_fk_rolt026 on "fobos".rolt026 (n26_compania,
    n26_codigo_arch,n26_tipo_arch) using btree  in idxdbs ;
create index "fobos".i03_fk_rolt026 on "fobos".rolt026 (n26_compania,
    n26_codigo_arch,n26_tipo_arch,n26_jornada,n26_sec_jor) using 
    btree  in idxdbs ;
create index "fobos".i04_fk_rolt026 on "fobos".rolt026 (n26_compania,
    n26_codigo_arch,n26_tipo_arch,n26_codigo_seg,n26_tipo_seg) 
    using btree  in idxdbs ;
create index "fobos".i05_fk_rolt026 on "fobos".rolt026 (n26_compania,
    n26_codigo_arch,n26_tipo_arch,n26_codigo_empl,n26_tipo_empl) 
    using btree  in idxdbs ;
create index "fobos".i06_fk_rolt026 on "fobos".rolt026 (n26_compania,
    n26_codigo_arch,n26_tipo_arch,n26_codigo_rela,n26_tipo_rela) 
    using btree  in idxdbs ;
create index "fobos".i07_fk_rolt026 on "fobos".rolt026 (n26_usua_elimin) 
    using btree  in idxdbs ;
create index "fobos".i08_fk_rolt026 on "fobos".rolt026 (n26_usua_cierre) 
    using btree  in idxdbs ;
create index "fobos".i09_fk_rolt026 on "fobos".rolt026 (n26_usuario) 
    using btree  in idxdbs ;
alter table "fobos".rolt026 add constraint primary key (n26_compania,
    n26_ano_proceso,n26_mes_proceso,n26_codigo_arch,n26_tipo_arch,
    n26_secuencia) constraint "fobos".pk_rolt026  ;
create index "fobos".i01_fk_rolt027 on "fobos".rolt027 (n27_compania,
    n27_ano_proceso,n27_mes_proceso,n27_codigo_arch,n27_tipo_arch,
    n27_secuencia) using btree  in idxdbs ;
create unique index "fobos".i01_pk_rolt027 on "fobos".rolt027 
    (n27_compania,n27_ano_proceso,n27_mes_proceso,n27_codigo_arch,
    n27_tipo_arch,n27_secuencia,n27_cod_trab) using btree  in 
    idxdbs ;
create index "fobos".i02_fk_rolt027 on "fobos".rolt027 (n27_compania) 
    using btree  in idxdbs ;
create index "fobos".i03_fk_rolt027 on "fobos".rolt027 (n27_compania,
    n27_cod_trab) using btree  in idxdbs ;
create index "fobos".i04_fk_rolt027 on "fobos".rolt027 (n27_compania,
    n27_ano_sect,n27_sectorial) using btree  in idxdbs ;
create index "fobos".i05_fk_rolt027 on "fobos".rolt027 (n27_compania,
    n27_codigo_arch,n27_tipo_arch,n27_tipo_causa,n27_sec_cau) 
    using btree  in idxdbs ;
create index "fobos".i06_fk_rolt027 on "fobos".rolt027 (n27_compania,
    n27_codigo_arch,n27_tipo_arch,n27_tipo_pago,n27_flag_pago) 
    using btree  in idxdbs ;
create index "fobos".i07_fk_rolt027 on "fobos".rolt027 (n27_usua_elimin) 
    using btree  in idxdbs ;
create index "fobos".i08_fk_rolt027 on "fobos".rolt027 (n27_usua_modifi) 
    using btree  in idxdbs ;
alter table "fobos".rolt027 add constraint primary key (n27_compania,
    n27_ano_proceso,n27_mes_proceso,n27_codigo_arch,n27_tipo_arch,
    n27_secuencia,n27_cod_trab) constraint "fobos".pk_rolt027 
     ;
create index "fobos".i01_fk_talt042 on "fobos".talt042 (t42_compania,
    t42_localidad,t42_num_ot) using btree  in idxdbs ;
create unique index "fobos".i01_pk_talt042 on "fobos".talt042 
    (t42_compania,t42_localidad,t42_anio,t42_mes,t42_num_ot) 
    using btree  in idxdbs ;
create index "fobos".i02_fk_talt042 on "fobos".talt042 (t42_compania) 
    using btree  in idxdbs ;
create index "fobos".i03_fk_talt042 on "fobos".talt042 (t42_cod_cliente) 
    using btree  in idxdbs ;
create index "fobos".i04_fk_talt042 on "fobos".talt042 (t42_usuario) 
    using btree  in idxdbs ;
alter table "fobos".talt042 add constraint primary key (t42_compania,
    t42_localidad,t42_anio,t42_mes,t42_num_ot) constraint "fobos"
    .pk_talt042  ;
create index "fobos".i01_fk_rept043 on "fobos".rept043 (r43_compania,
    r43_cod_ventas) using btree  in idxdbs ;
create unique index "fobos".i01_pk_rept043 on "fobos".rept043 
    (r43_compania,r43_localidad,r43_traspaso) using btree  in 
    idxdbs ;
create index "fobos".i02_fk_rept043 on "fobos".rept043 (r43_compania,
    r43_division) using btree  in idxdbs ;
create index "fobos".i03_fk_rept043 on "fobos".rept043 (r43_compania,
    r43_division,r43_sub_linea) using btree  in idxdbs ;
create index "fobos".i04_fk_rept043 on "fobos".rept043 (r43_compania,
    r43_division,r43_sub_linea,r43_cod_grupo) using btree  in 
    idxdbs ;
create index "fobos".i05_fk_rept043 on "fobos".rept043 (r43_compania,
    r43_division,r43_sub_linea,r43_cod_grupo,r43_cod_clase) using 
    btree  in idxdbs ;
create index "fobos".i06_fk_rept043 on "fobos".rept043 (r43_compania,
    r43_marca) using btree  in idxdbs ;
create index "fobos".i07_fk_rept043 on "fobos".rept043 (r43_usuario) 
    using btree  in idxdbs ;
alter table "fobos".rept043 add constraint primary key (r43_compania,
    r43_localidad,r43_traspaso) constraint "fobos".pk_rept043 
     ;
create index "fobos".i01_fk_rept044 on "fobos".rept044 (r44_compania,
    r44_localidad,r44_traspaso) using btree  in idxdbs ;
create unique index "fobos".i01_pk_rept044 on "fobos".rept044 
    (r44_compania,r44_localidad,r44_traspaso,r44_secuencia) using 
    btree  in idxdbs ;
create index "fobos".i02_fk_rept044 on "fobos".rept044 (r44_compania,
    r44_bodega_ori) using btree  in idxdbs ;
create index "fobos".i03_fk_rept044 on "fobos".rept044 (r44_compania,
    r44_item_ori) using btree  in idxdbs ;
create index "fobos".i04_fk_rept044 on "fobos".rept044 (r44_compania,
    r44_bodega_tra) using btree  in idxdbs ;
create index "fobos".i05_fk_rept044 on "fobos".rept044 (r44_compania,
    r44_item_tra) using btree  in idxdbs ;
create index "fobos".i06_fk_rept044 on "fobos".rept044 (r44_compania,
    r44_division_t) using btree  in idxdbs ;
create index "fobos".i07_fk_rept044 on "fobos".rept044 (r44_compania,
    r44_division_t,r44_sub_linea_t) using btree  in idxdbs ;
create index "fobos".i08_fk_rept044 on "fobos".rept044 (r44_compania,
    r44_division_t,r44_sub_linea_t,r44_cod_grupo_t) using btree 
     in idxdbs ;
create index "fobos".i09_fk_rept044 on "fobos".rept044 (r44_compania,
    r44_division_t,r44_sub_linea_t,r44_cod_grupo_t,r44_cod_clase_t) 
    using btree  in idxdbs ;
create index "fobos".i10_fk_rept044 on "fobos".rept044 (r44_compania,
    r44_marca_t) using btree  in idxdbs ;
alter table "fobos".rept044 add constraint primary key (r44_compania,
    r44_localidad,r44_traspaso,r44_secuencia) constraint "fobos"
    .pk_rept044  ;
create index "fobos".i01_fk_rept045 on "fobos".rept045 (r45_compania,
    r45_localidad,r45_cod_tran,r45_num_tran) using btree  in 
    idxdbs ;
create unique index "fobos".i01_pk_rept045 on "fobos".rept045 
    (r45_compania,r45_localidad,r45_traspaso,r45_cod_tran,r45_num_tran) 
    using btree  in idxdbs ;
create index "fobos".i02_fk_rept045 on "fobos".rept045 (r45_compania,
    r45_localidad,r45_traspaso) using btree  in idxdbs ;
create index "fobos".i03_fk_rept045 on "fobos".rept045 (r45_usuario) 
    using btree  in idxdbs ;
alter table "fobos".rept045 add constraint primary key (r45_compania,
    r45_localidad,r45_traspaso,r45_cod_tran,r45_num_tran) constraint 
    "fobos".pk_rept045  ;
create index "fobos".i01_fk_gent024 on "fobos".gent024 (g24_compania,
    g24_bodega) using btree  in idxdbs ;
create unique index "fobos".i01_pk_gent024 on "fobos".gent024 
    (g24_compania,g24_bodega,g24_impresora) using btree  in idxdbs 
    ;
create index "fobos".i02_fk_gent024 on "fobos".gent024 (g24_impresora) 
    using btree  in idxdbs ;
create index "fobos".i03_fk_gent024 on "fobos".gent024 (g24_usuario) 
    using btree  in idxdbs ;
alter table "fobos".gent024 add constraint primary key (g24_compania,
    g24_bodega,g24_impresora) constraint "fobos".pk_gent024  ;
    
create index "fobos".i01_fk_actt015 on "fobos".actt015 (a15_compania,
    a15_codigo_tran,a15_numero_tran) using btree  in idxdbs ;
    
create unique index "fobos".i01_pk_actt015 on "fobos".actt015 
    (a15_compania,a15_codigo_tran,a15_numero_tran,a15_tipo_comp,
    a15_num_comp) using btree  in idxdbs ;
create index "fobos".i02_fk_actt015 on "fobos".actt015 (a15_compania,
    a15_tipo_comp,a15_num_comp) using btree  in idxdbs ;
create index "fobos".i03_fk_actt015 on "fobos".actt015 (a15_usuario) 
    using btree  in idxdbs ;
alter table "fobos".actt015 add constraint primary key (a15_compania,
    a15_codigo_tran,a15_numero_tran,a15_tipo_comp,a15_num_comp) 
    constraint "fobos".pk_actt015  ;
create index "fobos".i01_fk_actt012 on "fobos".actt012 (a12_compania,
    a12_codigo_tran) using btree  in idxdbs ;
create unique index "fobos".i01_pk_actt012 on "fobos".actt012 
    (a12_compania,a12_codigo_tran,a12_numero_tran) using btree 
     in idxdbs ;
create index "fobos".i02_fk_actt012 on "fobos".actt012 (a12_compania,
    a12_codigo_bien) using btree  in idxdbs ;
create index "fobos".i03_fk_actt012 on "fobos".actt012 (a12_compania,
    a12_locali_ori) using btree  in idxdbs ;
create index "fobos".i04_fk_actt012 on "fobos".actt012 (a12_compania,
    a12_locali_dest) using btree  in idxdbs ;
create index "fobos".i05_fk_actt012 on "fobos".actt012 (a12_compania,
    a12_depto_ori) using btree  in idxdbs ;
create index "fobos".i06_fk_actt012 on "fobos".actt012 (a12_compania,
    a12_depto_dest) using btree  in idxdbs ;
create index "fobos".i07_fk_actt012 on "fobos".actt012 (a12_compania,
    a12_tipcomp_gen,a12_numcomp_gen) using btree  in idxdbs ;
    
create index "fobos".i08_fk_actt012 on "fobos".actt012 (a12_usuario) 
    using btree  in idxdbs ;
alter table "fobos".actt012 add constraint primary key (a12_compania,
    a12_codigo_tran,a12_numero_tran) constraint "fobos".pk_actt012 
     ;
create index "fobos".i01_fk_actt006 on "fobos".actt006 (a06_usuario) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_actt006 on "fobos".actt006 
    (a06_compania,a06_estado) using btree  in idxdbs ;
alter table "fobos".actt006 add constraint primary key (a06_compania,
    a06_estado) constraint "fobos".pk_actt006  ;
create index "fobos".i01_fk_srit022 on "fobos".srit022 (s22_usu_apert) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_srit022 on "fobos".srit022 
    (s22_compania,s22_localidad,s22_anio,s22_mes,s22_tipo_anexo) 
    using btree  in idxdbs ;
create index "fobos".i02_fk_srit022 on "fobos".srit022 (s22_usu_cierre) 
    using btree  in idxdbs ;
create index "fobos".i03_fk_srit022 on "fobos".srit022 (s22_usuario) 
    using btree  in idxdbs ;
alter table "fobos".srit022 add constraint primary key (s22_compania,
    s22_localidad,s22_anio,s22_mes,s22_tipo_anexo) constraint 
    "fobos".pk_srit022  ;
create index "fobos".i01_fk_rept019_res on "fobos".rept019_res 
    (r19_usuario) using btree  in idxdbs ;
create unique index "fobos".i01_pk_rept019_res on "fobos".rept019_res 
    (r19_compania,r19_localidad,r19_cod_tran,r19_num_tran) using 
    btree  in idxdbs ;
alter table "fobos".rept019_res add constraint primary key (r19_compania,
    r19_localidad,r19_cod_tran,r19_num_tran) constraint "fobos"
    .pk_rept019_res  ;
create index "fobos".i01_fk_rept020_res on "fobos".rept020_res 
    (r20_compania,r20_localidad,r20_cod_tran,r20_num_tran) using 
    btree  in idxdbs ;
create unique index "fobos".i01_pk_rept020_res on "fobos".rept020_res 
    (r20_compania,r20_localidad,r20_cod_tran,r20_num_tran,r20_bodega,
    r20_item,r20_orden) using btree  in idxdbs ;
alter table "fobos".rept020_res add constraint primary key (r20_compania,
    r20_localidad,r20_cod_tran,r20_num_tran,r20_bodega,r20_item,
    r20_orden) constraint "fobos".pk_rept020_res  ;
create index "fobos".i01_fk_rept010_res on "fobos".rept010_res 
    (r10_usuario) using btree  in idxdbs ;
create unique index "fobos".i01_pk_rept010_res on "fobos".rept010_res 
    (r10_compania,r10_codigo) using btree  in idxdbs ;
alter table "fobos".rept010_res add constraint primary key (r10_compania,
    r10_codigo) constraint "fobos".pk_rept010_res  ;
create index "fobos".i01_fk_ctbt013_res on "fobos".ctbt013_res 
    (b13_usuario) using btree  in idxdbs ;
create unique index "fobos".i01_pk_ctbt013_res on "fobos".ctbt013_res 
    (b13_compania,b13_tipo_comp,b13_num_comp,b13_secuencia) using 
    btree  in idxdbs ;
alter table "fobos".ctbt013_res add constraint primary key (b13_compania,
    b13_tipo_comp,b13_num_comp,b13_secuencia) constraint "fobos"
    .pk_ctbt013_res  ;
create unique index "fobos".i01_pk_tra_ent on "fobos".trans_ent 
    (compania,localidad,cod_tran,num_tran,item_ent) using btree 
     in idxdbs ;
alter table "fobos".trans_ent add constraint primary key (compania,
    localidad,cod_tran,num_tran,item_ent) constraint "fobos".pk_tra_ent 
     ;
create unique index "fobos".i01_pk_tra_sal on "fobos".trans_salida 
    (compania,local_ent,codtran_ent,numtran_ent,item_ent) using 
    btree  in idxdbs ;
create unique index "fobos".i02_pk_tra_sal on "fobos".trans_salida 
    (compania,local_sal,codtran_sal,numtran_sal,item_sal) using 
    btree  in idxdbs ;
alter table "fobos".trans_salida add constraint primary key (compania,
    local_ent,codtran_ent,numtran_ent,item_ent) constraint "fobos"
    .pk_tra_sal  ;
create unique index "fobos".i01_pk_ite_cr on "fobos".ite_cos_rea 
    (compania,localidad,item) using btree  in idxdbs ;
alter table "fobos".ite_cos_rea add constraint primary key (compania,
    localidad,item) constraint "fobos".pk_ite_cr  ;
create index "fobos".i01_fk_cxpt033 on "fobos".cxpt033 (p33_compania,
    p33_localidad,p33_numero_oc) using btree  in idxdbs ;
create unique index "fobos".i01_pk_cxpt033 on "fobos".cxpt033 
    (p33_compania,p33_localidad,p33_numero_oc,p33_secuencia) 
    using btree  in idxdbs ;
create index "fobos".i02_fk_cxpt033 on "fobos".cxpt033 (p33_compania,
    p33_localidad,p33_cod_tran,p33_num_tran) using btree  in 
    idxdbs ;
create index "fobos".i03_fk_cxpt033 on "fobos".cxpt033 (p33_cod_prov_ant) 
    using btree  in idxdbs ;
create index "fobos".i04_fk_cxpt033 on "fobos".cxpt033 (p33_cod_prov_nue) 
    using btree  in idxdbs ;
create index "fobos".i05_fk_cxpt033 on "fobos".cxpt033 (p33_usuario) 
    using btree  in idxdbs ;
alter table "fobos".cxpt033 add constraint primary key (p33_compania,
    p33_localidad,p33_numero_oc,p33_secuencia) constraint "fobos"
    .pk_cxpt033  ;
create index "fobos".i01_fk_rept009 on "fobos".rept009 (r09_usuario) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_rept009 on "fobos".rept009 
    (r09_compania,r09_tipo_ident) using btree  in idxdbs ;
alter table "fobos".rept009 add constraint primary key (r09_compania,
    r09_tipo_ident) constraint "fobos".pk_rept009  ;
create index "fobos".i01_fk_rept046 on "fobos".rept046 (r46_compania) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_rept046 on "fobos".rept046 
    (r46_compania,r46_localidad,r46_composicion,r46_item_comp) 
    using btree  in idxdbs ;
create index "fobos".i02_fk_rept046 on "fobos".rept046 (r46_compania,
    r46_localidad) using btree  in idxdbs ;
create index "fobos".i03_fk_rept046 on "fobos".rept046 (r46_compania,
    r46_item_comp) using btree  in idxdbs ;
create index "fobos".i04_fk_rept046 on "fobos".rept046 (r46_compania,
    r46_cod_ventas) using btree  in idxdbs ;
create index "fobos".i05_fk_rept046 on "fobos".rept046 (r46_compania,
    r46_division_c) using btree  in idxdbs ;
create index "fobos".i06_fk_rept046 on "fobos".rept046 (r46_compania,
    r46_division_c,r46_sub_linea_c) using btree  in idxdbs ;
create index "fobos".i07_fk_rept046 on "fobos".rept046 (r46_compania,
    r46_division_c,r46_sub_linea_c,r46_cod_grupo_c) using btree 
     in idxdbs ;
create index "fobos".i08_fk_rept046 on "fobos".rept046 (r46_compania,
    r46_division_c,r46_sub_linea_c,r46_cod_grupo_c,r46_cod_clase_c) 
    using btree  in idxdbs ;
create index "fobos".i09_fk_rept046 on "fobos".rept046 (r46_compania,
    r46_marca_c) using btree  in idxdbs ;
create index "fobos".i10_fk_rept046 on "fobos".rept046 (r46_usu_modifi) 
    using btree  in idxdbs ;
create index "fobos".i11_fk_rept046 on "fobos".rept046 (r46_usu_cierre) 
    using btree  in idxdbs ;
create index "fobos".i12_fk_rept046 on "fobos".rept046 (r46_usuario) 
    using btree  in idxdbs ;
alter table "fobos".rept046 add constraint primary key (r46_compania,
    r46_localidad,r46_composicion,r46_item_comp) constraint "fobos"
    .pk_rept046  ;
create index "fobos".i01_fk_rept047 on "fobos".rept047 (r47_compania,
    r47_localidad,r47_composicion,r47_item_comp) using btree 
     in idxdbs ;
create unique index "fobos".i01_pk_rept047 on "fobos".rept047 
    (r47_compania,r47_localidad,r47_composicion,r47_item_comp,
    r47_bodega_part,r47_item_part) using btree  in idxdbs ;
create index "fobos".i02_fk_rept047 on "fobos".rept047 (r47_compania,
    r47_item_comp) using btree  in idxdbs ;
create index "fobos".i03_fk_rept047 on "fobos".rept047 (r47_compania,
    r47_bodega_part) using btree  in idxdbs ;
create index "fobos".i04_fk_rept047 on "fobos".rept047 (r47_compania,
    r47_item_part) using btree  in idxdbs ;
create index "fobos".i05_fk_rept047 on "fobos".rept047 (r47_compania,
    r47_division_p) using btree  in idxdbs ;
create index "fobos".i06_fk_rept047 on "fobos".rept047 (r47_compania,
    r47_division_p,r47_sub_linea_p) using btree  in idxdbs ;
create index "fobos".i07_fk_rept047 on "fobos".rept047 (r47_compania,
    r47_division_p,r47_sub_linea_p,r47_cod_grupo_p) using btree 
     in idxdbs ;
create index "fobos".i08_fk_rept047 on "fobos".rept047 (r47_compania,
    r47_division_p,r47_sub_linea_p,r47_cod_grupo_p,r47_cod_clase_p) 
    using btree  in idxdbs ;
create index "fobos".i09_fk_rept047 on "fobos".rept047 (r47_compania,
    r47_marca_p) using btree  in idxdbs ;
alter table "fobos".rept047 add constraint primary key (r47_compania,
    r47_localidad,r47_composicion,r47_item_comp,r47_bodega_part,
    r47_item_part) constraint "fobos".pk_rept047  ;
create index "fobos".i01_fk_rept048 on "fobos".rept048 (r48_compania,
    r48_localidad,r48_composicion,r48_item_comp) using btree 
     in idxdbs ;
create unique index "fobos".i01_pk_rept048 on "fobos".rept048 
    (r48_compania,r48_localidad,r48_composicion,r48_item_comp,
    r48_sec_carga) using btree  in idxdbs ;
create index "fobos".i02_fk_rept048 on "fobos".rept048 (r48_compania,
    r48_item_comp) using btree  in idxdbs ;
create index "fobos".i03_fk_rept048 on "fobos".rept048 (r48_compania,
    r48_bodega_comp) using btree  in idxdbs ;
create index "fobos".i04_fk_rept048 on "fobos".rept048 (r48_usu_elimin) 
    using btree  in idxdbs ;
create index "fobos".i05_fk_rept048 on "fobos".rept048 (r48_usu_cierre) 
    using btree  in idxdbs ;
create index "fobos".i06_fk_rept048 on "fobos".rept048 (r48_usuario) 
    using btree  in idxdbs ;
alter table "fobos".rept048 add constraint primary key (r48_compania,
    r48_localidad,r48_composicion,r48_item_comp,r48_sec_carga) 
    constraint "fobos".pk_rept048  ;
create index "fobos".i01_fk_rept049 on "fobos".rept049 (r49_compania,
    r49_localidad,r49_numero_oc) using btree  in idxdbs ;
create unique index "fobos".i01_pk_rept049 on "fobos".rept049 
    (r49_compania,r49_localidad,r49_composicion,r49_item_comp,
    r49_sec_carga,r49_numero_oc) using btree  in idxdbs ;
create index "fobos".i02_fk_rept049 on "fobos".rept049 (r49_compania,
    r49_localidad,r49_composicion,r49_item_comp,r49_sec_carga) 
    using btree  in idxdbs ;
create index "fobos".i03_fk_rept049 on "fobos".rept049 (r49_compania,
    r49_item_comp) using btree  in idxdbs ;
create index "fobos".i04_fk_rept049 on "fobos".rept049 (r49_usuario) 
    using btree  in idxdbs ;
alter table "fobos".rept049 add constraint primary key (r49_compania,
    r49_localidad,r49_composicion,r49_item_comp,r49_sec_carga,
    r49_numero_oc) constraint "fobos".pk_rept049  ;
create index "fobos".i01_fk_rept053 on "fobos".rept053 (r53_compania,
    r53_localidad,r53_cod_tran,r53_num_tran) using btree  in 
    idxdbs ;
create unique index "fobos".i01_pk_rept053 on "fobos".rept053 
    (r53_compania,r53_localidad,r53_composicion,r53_item_comp,
    r53_sec_carga,r53_cod_tran,r53_num_tran) using btree  in 
    idxdbs ;
create index "fobos".i02_fk_rept053 on "fobos".rept053 (r53_compania,
    r53_localidad,r53_composicion,r53_item_comp,r53_sec_carga) 
    using btree  in idxdbs ;
create index "fobos".i03_fk_rept053 on "fobos".rept053 (r53_compania,
    r53_item_comp) using btree  in idxdbs ;
create index "fobos".i04_fk_rept053 on "fobos".rept053 (r53_usuario) 
    using btree  in idxdbs ;
alter table "fobos".rept053 add constraint primary key (r53_compania,
    r53_localidad,r53_composicion,r53_item_comp,r53_sec_carga,
    r53_cod_tran,r53_num_tran) constraint "fobos".pk_rept053  
    ;
create index "fobos".i01_fk_rolt031 on "fobos".rolt031 (n31_compania,
    n31_cod_trab) using btree  in idxdbs ;
create unique index "fobos".i01_pk_rolt031 on "fobos".rolt031 
    (n31_compania,n31_cod_trab,n31_secuencia) using btree  in 
    idxdbs ;
create index "fobos".i02_fk_rolt031 on "fobos".rolt031 (n31_usuario) 
    using btree  in idxdbs ;
alter table "fobos".rolt031 add constraint primary key (n31_compania,
    n31_cod_trab,n31_secuencia) constraint "fobos".pk_rolt031 
     ;
create index "fobos".i01_fk_rolt028 on "fobos".rolt028 (n28_compania) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_rolt028 on "fobos".rolt028 
    (n28_compania,n28_proceso,n28_cod_liqrol) using btree  in 
    idxdbs ;
create index "fobos".i02_fk_rolt028 on "fobos".rolt028 (n28_proceso) 
    using btree  in idxdbs ;
create index "fobos".i03_fk_rolt028 on "fobos".rolt028 (n28_cod_liqrol) 
    using btree  in idxdbs ;
create index "fobos".i04_fk_rolt028 on "fobos".rolt028 (n28_usuario) 
    using btree  in idxdbs ;
alter table "fobos".rolt028 add constraint primary key (n28_compania,
    n28_proceso,n28_cod_liqrol) constraint "fobos".pk_rolt028 
     ;
create index "fobos".i01_fk_rept019 on "fobos".rept019 (r19_compania) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_rept019 on "fobos".rept019 
    (r19_compania,r19_localidad,r19_cod_tran,r19_num_tran) using 
    btree  in idxdbs ;
create index "fobos".i02_fk_rept019 on "fobos".rept019 (r19_compania,
    r19_localidad) using btree  in idxdbs ;
create index "fobos".i03_fk_rept019 on "fobos".rept019 (r19_cod_subtipo) 
    using btree  in idxdbs ;
create index "fobos".i04_fk_rept019 on "fobos".rept019 (r19_compania,
    r19_localidad,r19_codcli) using btree  in idxdbs ;
create index "fobos".i05_fk_rept019 on "fobos".rept019 (r19_compania,
    r19_vendedor) using btree  in idxdbs ;
create index "fobos".i06_fk_rept019 on "fobos".rept019 (r19_compania,
    r19_localidad,r19_oc_interna) using btree  in idxdbs ;
create index "fobos".i07_fk_rept019 on "fobos".rept019 (r19_compania,
    r19_localidad,r19_ord_trabajo) using btree  in idxdbs ;
create index "fobos".i08_fk_rept019 on "fobos".rept019 (r19_compania,
    r19_localidad,r19_tipo_dev,r19_num_dev) using btree  in idxdbs 
    ;
create index "fobos".i09_fk_rept019 on "fobos".rept019 (r19_compania,
    r19_bodega_ori) using btree  in idxdbs ;
create index "fobos".i10_fk_rept019 on "fobos".rept019 (r19_compania,
    r19_bodega_dest) using btree  in idxdbs ;
create index "fobos".i11_fk_rept019 on "fobos".rept019 (r19_moneda) 
    using btree  in idxdbs ;
create index "fobos".i12_fk_rept019 on "fobos".rept019 (r19_compania,
    r19_localidad,r19_numliq) using btree  in idxdbs ;
create index "fobos".i13_fk_rept019 on "fobos".rept019 (r19_usuario) 
    using btree  in idxdbs ;
create index "fobos".i14_fk_rept019 on "fobos".rept019 (r19_cod_tran) 
    using btree  in idxdbs ;
alter table "fobos".rept019 add constraint primary key (r19_compania,
    r19_localidad,r19_cod_tran,r19_num_tran) constraint "fobos"
    .pk_rept019  ;
create index "fobos".i01_fk_cajt011 on "fobos".cajt011 (j11_compania,
    j11_localidad,j11_tipo_fuente,j11_num_fuente) using btree 
     in idxdbs ;
create unique index "fobos".i01_pk_cajt011 on "fobos".cajt011 
    (j11_compania,j11_localidad,j11_tipo_fuente,j11_num_fuente,
    j11_secuencia) using btree  in idxdbs ;
create index "fobos".i02_fk_cajt011 on "fobos".cajt011 (j11_compania,
    j11_codigo_pago) using btree  in idxdbs ;
create index "fobos".i03_fk_cajt011 on "fobos".cajt011 (j11_moneda) 
    using btree  in idxdbs ;
create index "fobos".i04_cajt011 on "fobos".cajt011 (j11_compania,
    j11_localidad,j11_num_egreso) using btree  in idxdbs ;
alter table "fobos".cajt011 add constraint primary key (j11_compania,
    j11_localidad,j11_tipo_fuente,j11_num_fuente,j11_secuencia) 
    constraint "fobos".pk_cajt011  ;
create index "fobos".i01_fk_rolt017 on "fobos".rolt017 (n17_usuario) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_rolt017 on "fobos".rolt017 
    (n17_compania,n17_ano_sect,n17_sectorial) using btree  in 
    idxdbs ;
alter table "fobos".rolt017 add constraint primary key (n17_compania,
    n17_ano_sect,n17_sectorial) constraint "fobos".pk_rolt017 
     ;
create index "fobos".i01_fk_t_bal_gen on "fobos".t_bal_gen (b11_compania,
    b11_cuenta) using btree  in idxdbs ;
create unique index "fobos".i01_pk_t_bal_gen on "fobos".t_bal_gen 
    (b11_compania,b11_cuenta,b11_moneda,b11_ano) using btree 
     in idxdbs ;
alter table "fobos".t_bal_gen add constraint primary key (b11_compania,
    b11_cuenta,b11_moneda,b11_ano) constraint "fobos".pk_t_bal_gen 
     ;
create index "fobos".i01_fk_rept068 on "fobos".rept068 (r68_compania,
    r68_localidad,r68_cod_tran,r68_num_tran) using btree  in 
    idxdbs ;
create unique index "fobos".i01_pk_rept068 on "fobos".rept068 
    (r68_compania,r68_localidad,r68_cod_tran,r68_num_tran,r68_loc_tr,
    r68_cod_tr,r68_num_tr,r68_bodega,r68_item,r68_secuencia) 
    using btree  in idxdbs ;
create index "fobos".i02_fk_rept068 on "fobos".rept068 (r68_compania,
    r68_loc_tr,r68_cod_tr,r68_num_tr) using btree  in idxdbs 
    ;
create index "fobos".i03_fk_rept068 on "fobos".rept068 (r68_compania,
    r68_loc_tr,r68_cod_tr,r68_num_tr,r68_bodega,r68_item,r68_secuencia) 
    using btree  in idxdbs ;
create index "fobos".i04_fk_rept068 on "fobos".rept068 (r68_usuario) 
    using btree  in idxdbs ;
alter table "fobos".rept068 add constraint primary key (r68_compania,
    r68_localidad,r68_cod_tran,r68_num_tran,r68_loc_tr,r68_cod_tr,
    r68_num_tr,r68_bodega,r68_item,r68_secuencia) constraint 
    "fobos".pk_rept068  ;
create index "fobos".i01_fk_rept069 on "fobos".rept069 (r69_compania,
    r69_localidad,r69_cod_tran,r69_num_tran) using btree  in 
    idxdbs ;
create unique index "fobos".i01_pk_rept069 on "fobos".rept069 
    (r69_compania,r69_localidad,r69_cod_tran,r69_num_tran,r69_loc_tr,
    r69_cod_tr,r69_num_tr) using btree  in idxdbs ;
create index "fobos".i02_fk_rept069 on "fobos".rept069 (r69_compania,
    r69_loc_tr,r69_cod_tr,r69_num_tr) using btree  in idxdbs 
    ;
alter table "fobos".rept069 add constraint primary key (r69_compania,
    r69_localidad,r69_cod_tran,r69_num_tran,r69_loc_tr,r69_cod_tr,
    r69_num_tr) constraint "fobos".pk_rept069  ;
create index "fobos".i01_fk_rept108 on "fobos".rept108 (r108_compania) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_rept108 on "fobos".rept108 
    (r108_compania,r108_localidad,r108_cod_zona) using btree 
     in idxdbs ;
create index "fobos".i02_fk_rept108 on "fobos".rept108 (r108_usuario) 
    using btree  in idxdbs ;
create index "fobos".i03_fk_rept108 on "fobos".rept108 (r108_compania,
    r108_localidad,r108_cia_trans) using btree  in idxdbs ;
alter table "fobos".rept108 add constraint primary key (r108_compania,
    r108_localidad,r108_cod_zona) constraint "fobos".pk_rept108 
     ;
create index "fobos".i01_fk_rept109 on "fobos".rept109 (r109_compania) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_rept109 on "fobos".rept109 
    (r109_compania,r109_localidad,r109_cod_zona,r109_cod_subzona) 
    using btree  in idxdbs ;
create index "fobos".i02_fk_rept109 on "fobos".rept109 (r109_compania,
    r109_localidad,r109_cod_zona) using btree  in idxdbs ;
create index "fobos".i03_fk_rept109 on "fobos".rept109 (r109_usuario) 
    using btree  in idxdbs ;
create index "fobos".i04_fk_rept109 on "fobos".rept109 (r109_pais,
    r109_divi_poli) using btree  in idxdbs ;
create index "fobos".i05_fk_rept109 on "fobos".rept109 (r109_ciudad) 
    using btree  in idxdbs ;
alter table "fobos".rept109 add constraint primary key (r109_compania,
    r109_localidad,r109_cod_zona,r109_cod_subzona) constraint 
    "fobos".pk_rept109  ;
create index "fobos".i01_fk_rept110 on "fobos".rept110 (r110_compania) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_rept110 on "fobos".rept110 
    (r110_compania,r110_localidad,r110_cod_trans) using btree 
     in idxdbs ;
create index "fobos".i02_fk_rept110 on "fobos".rept110 (r110_usuario) 
    using btree  in idxdbs ;
alter table "fobos".rept110 add constraint primary key (r110_compania,
    r110_localidad,r110_cod_trans) constraint "fobos".pk_rept110 
     ;
create index "fobos".i01_fk_rept111 on "fobos".rept111 (r111_compania,
    r111_localidad,r111_cod_trans) using btree  in idxdbs ;
create unique index "fobos".i01_pk_rept111 on "fobos".rept111 
    (r111_compania,r111_localidad,r111_cod_trans,r111_cod_chofer) 
    using btree  in idxdbs ;
create index "fobos".i02_fk_rept111 on "fobos".rept111 (r111_compania,
    r111_cod_trab) using btree  in idxdbs ;
create index "fobos".i03_fk_rept111 on "fobos".rept111 (r111_usuario) 
    using btree  in idxdbs ;
alter table "fobos".rept111 add constraint primary key (r111_compania,
    r111_localidad,r111_cod_trans,r111_cod_chofer) constraint 
    "fobos".pk_rept111  ;
create index "fobos".i01_fk_rept112 on "fobos".rept112 (r112_compania) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_rept112 on "fobos".rept112 
    (r112_compania,r112_localidad,r112_cod_obser) using btree 
     in idxdbs ;
create index "fobos".i02_fk_rept112 on "fobos".rept112 (r112_usuario) 
    using btree  in idxdbs ;
alter table "fobos".rept112 add constraint primary key (r112_compania,
    r112_localidad,r112_cod_obser) constraint "fobos".pk_rept112 
     ;
create index "fobos".i01_fk_rept114 on "fobos".rept114 (r114_compania,
    r114_localidad,r114_num_hojrut) using btree  in idxdbs ;
create unique index "fobos".i01_pk_rept114 on "fobos".rept114 
    (r114_compania,r114_localidad,r114_num_hojrut,r114_secuencia) 
    using btree  in idxdbs ;
create index "fobos".i02_fk_rept114 on "fobos".rept114 (r114_compania,
    r114_localidad,r114_cod_zona) using btree  in idxdbs ;
create index "fobos".i03_fk_rept114 on "fobos".rept114 (r114_compania,
    r114_localidad,r114_cod_zona,r114_cod_subzona) using btree 
     in idxdbs ;
create index "fobos".i04_fk_rept114 on "fobos".rept114 (r114_compania,
    r114_localidad,r114_cod_obser) using btree  in idxdbs ;
create index "fobos".i05_fk_rept114 on "fobos".rept114 (r114_codcli) 
    using btree  in idxdbs ;
alter table "fobos".rept114 add constraint primary key (r114_compania,
    r114_localidad,r114_num_hojrut,r114_secuencia) constraint 
    "fobos".pk_rept114  ;
create index "fobos".i01_fk_rept113 on "fobos".rept113 (r113_compania,
    r113_localidad,r113_cod_trans) using btree  in idxdbs ;
create unique index "fobos".i01_pk_rept113 on "fobos".rept113 
    (r113_compania,r113_localidad,r113_num_hojrut) using btree 
     in idxdbs ;
create index "fobos".i02_fk_rept113 on "fobos".rept113 (r113_compania,
    r113_localidad,r113_cod_trans,r113_cod_chofer) using btree 
     in idxdbs ;
create index "fobos".i03_fk_rept113 on "fobos".rept113 (r113_usuario) 
    using btree  in idxdbs ;
create index "fobos".i04_fk_rept113 on "fobos".rept113 (r113_compania,
    r113_localidad,r113_cod_trans,r113_cod_ayud) using btree 
     in idxdbs ;
create index "fobos".i05_fk_rept113 on "fobos".rept113 (r113_compania,
    r113_areaneg) using btree  in idxdbs ;
alter table "fobos".rept113 add constraint primary key (r113_compania,
    r113_localidad,r113_num_hojrut) constraint "fobos".pk_rept113 
     ;
create index "fobos".i01_fk_gent025 on "fobos".gent025 (g25_pais) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_gent025 on "fobos".gent025 
    (g25_pais,g25_divi_poli) using btree  in idxdbs ;
create index "fobos".i02_fk_gent025 on "fobos".gent025 (g25_usuario) 
    using btree  in idxdbs ;
alter table "fobos".gent025 add constraint primary key (g25_pais,
    g25_divi_poli) constraint "fobos".pk_gent025  ;
create index "fobos".i01_fk_rept115 on "fobos".rept115 (r115_compania,
    r115_localidad,r115_cod_trans) using btree  in idxdbs ;
create unique index "fobos".i01_pk_rept115 on "fobos".rept115 
    (r115_compania,r115_localidad,r115_cod_trans,r115_cod_ayud) 
    using btree  in idxdbs ;
create index "fobos".i02_fk_rept115 on "fobos".rept115 (r115_compania,
    r115_cod_trab) using btree  in idxdbs ;
create index "fobos".i03_fk_rept115 on "fobos".rept115 (r115_usuario) 
    using btree  in idxdbs ;
alter table "fobos".rept115 add constraint primary key (r115_compania,
    r115_localidad,r115_cod_trans,r115_cod_ayud) constraint "fobos"
    .pk_rept115  ;
create index "fobos".i01_fk_rept116 on "fobos".rept116 (r116_usuario) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_rept116 on "fobos".rept116 
    (r116_compania,r116_localidad,r116_cia_trans) using btree 
     in idxdbs ;
create index "fobos".i02_fk_rept116 on "fobos".rept116 (r116_codprov) 
    using btree  in idxdbs ;
alter table "fobos".rept116 add constraint primary key (r116_compania,
    r116_localidad,r116_cia_trans) constraint "fobos".pk_rept116 
     ;
create index "fobos".i01_fk_provincia on "fobos".provincia (pais,
    cod_phobos) using btree  in idxdbs ;
create unique index "fobos".i01_pk_provincia on "fobos".provincia 
    (codigo) using btree  in idxdbs ;
alter table "fobos".provincia add constraint primary key (codigo) 
    constraint "fobos".pk_provincia  ;
create index "fobos".i01_fk_canton on "fobos".canton (cod_prov) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_canton on "fobos".canton (cod_prov,
    codigo) using btree  in idxdbs ;
create index "fobos".i02_fk_canton on "fobos".canton (pais,divi_poli) 
    using btree  in idxdbs ;
create index "fobos".i03_fk_canton on "fobos".canton (cod_phobos) 
    using btree  in idxdbs ;
alter table "fobos".canton add constraint primary key (cod_prov,
    codigo) constraint "fobos".pk_canton  ;
create index "fobos".i01_fk_cxpt006 on "fobos".cxpt006 (p06_banco) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_cxpt006 on "fobos".cxpt006 
    (p06_compania,p06_cod_bco_tra,p06_banco) using btree  in 
    idxdbs ;
create index "fobos".i02_fk_cxpt006 on "fobos".cxpt006 (p06_usuario) 
    using btree  in idxdbs ;
alter table "fobos".cxpt006 add constraint primary key (p06_compania,
    p06_cod_bco_tra,p06_banco) constraint "fobos".pk_cxpt006  
    ;
alter table "fobos".gent000 add constraint (foreign key (g00_usuario) 
    references "fobos".gent005 );

alter table "fobos".gent001 add constraint (foreign key (g01_usuario) 
    references "fobos".gent005 );

alter table "fobos".gent003 add constraint (foreign key (g03_modulo) 
    references "fobos".gent050 );

alter table "fobos".gent003 add constraint (foreign key (g03_compania) 
    references "fobos".gent001 );

alter table "fobos".gent003 add constraint (foreign key (g03_usuario) 
    references "fobos".gent005 );

alter table "fobos".gent005 add constraint (foreign key (g05_grupo) 
    references "fobos".gent004 );

alter table "fobos".gent007 add constraint (foreign key (g07_user) 
    references "fobos".gent005 );

alter table "fobos".gent007 add constraint (foreign key (g07_impresora) 
    references "fobos".gent006 );

alter table "fobos".gent007 add constraint (foreign key (g07_usuario) 
    references "fobos".gent005 );

alter table "fobos".gent009 add constraint (foreign key (g09_banco) 
    references "fobos".gent008  constraint "fobos".fk_02_gent009);
    

alter table "fobos".gent009 add constraint (foreign key (g09_compania) 
    references "fobos".gent001 );

alter table "fobos".gent009 add constraint (foreign key (g09_usuario) 
    references "fobos".gent005 );

alter table "fobos".gent011 add constraint (foreign key (g11_usuario) 
    references "fobos".gent005 );

alter table "fobos".gent012 add constraint (foreign key (g12_tiporeg) 
    references "fobos".gent011 );

alter table "fobos".gent012 add constraint (foreign key (g12_usuario) 
    references "fobos".gent005 );

alter table "fobos".gent017 add constraint (foreign key (g17_usuario) 
    references "fobos".gent005 );

alter table "fobos".gent018 add constraint (foreign key (g18_compania,
    g18_localidad) references "fobos".gent002 );

alter table "fobos".gent018 add constraint (foreign key (g18_compania,
    g18_areaneg) references "fobos".gent003 );

alter table "fobos".gent018 add constraint (foreign key (g18_usuario) 
    references "fobos".gent005 );

alter table "fobos".gent034 add constraint (foreign key (g34_compania,
    g34_cod_ccosto) references "fobos".gent033 );

alter table "fobos".gent034 add constraint (foreign key (g34_usuario) 
    references "fobos".gent005 );

alter table "fobos".gent034 add constraint (foreign key (g34_compania,
    g34_aux_deprec) references "fobos".ctbt010 );

alter table "fobos".gent035 add constraint (foreign key (g35_compania) 
    references "fobos".gent001 );

alter table "fobos".gent035 add constraint (foreign key (g35_usuario) 
    references "fobos".gent005 );

alter table "fobos".gent036 add constraint (foreign key (g36_usuario) 
    references "fobos".gent005 );

alter table "fobos".gent050 add constraint (foreign key (g50_usuario) 
    references "fobos".gent005 );

alter table "fobos".gent051 add constraint (foreign key (g51_usuario) 
    references "fobos".gent005 );

alter table "fobos".gent052 add constraint (foreign key (g52_modulo) 
    references "fobos".gent050 );

alter table "fobos".gent052 add constraint (foreign key (g52_usuario) 
    references "fobos".gent005 );

alter table "fobos".gent053 add constraint (foreign key (g53_modulo) 
    references "fobos".gent050 );

alter table "fobos".gent053 add constraint (foreign key (g53_compania) 
    references "fobos".gent001 );

alter table "fobos".gent053 add constraint (foreign key (g53_usuario) 
    references "fobos".gent005 );

alter table "fobos".gent054 add constraint (foreign key (g54_modulo) 
    references "fobos".gent050 );

alter table "fobos".gent054 add constraint (foreign key (g54_usuario) 
    references "fobos".gent005 );

alter table "fobos".talt001 add constraint (foreign key (t01_compania,
    t01_grupo_linea) references "fobos".gent020 );

alter table "fobos".talt001 add constraint (foreign key (t01_compania) 
    references "fobos".talt000 );

alter table "fobos".talt001 add constraint (foreign key (t01_usuario) 
    references "fobos".gent005 );

alter table "fobos".talt002 add constraint (foreign key (t02_compania) 
    references "fobos".talt000 );

alter table "fobos".talt002 add constraint (foreign key (t02_usuario) 
    references "fobos".gent005 );

alter table "fobos".gent013 add constraint (foreign key (g13_usuario) 
    references "fobos".gent005 );

alter table "fobos".gent031 add constraint (foreign key (g31_pais) 
    references "fobos".gent030 );

alter table "fobos".gent031 add constraint (foreign key (g31_usuario) 
    references "fobos".gent005 );

alter table "fobos".gent031 add constraint (foreign key (g31_pais,
    g31_divi_poli) references "fobos".gent025  constraint "fobos"
    .fk_03_gent031);

alter table "fobos".gent014 add constraint (foreign key (g14_moneda_ori) 
    references "fobos".gent013 );

alter table "fobos".gent014 add constraint (foreign key (g14_moneda_des) 
    references "fobos".gent013 );

alter table "fobos".gent014 add constraint (foreign key (g14_usuario) 
    references "fobos".gent005 );

alter table "fobos".gent032 add constraint (foreign key (g32_compania) 
    references "fobos".gent001 );

alter table "fobos".gent032 add constraint (foreign key (g32_usuario) 
    references "fobos".gent005 );

alter table "fobos".gent033 add constraint (foreign key (g33_compania) 
    references "fobos".gent001 );

alter table "fobos".gent033 add constraint (foreign key (g33_usuario) 
    references "fobos".gent005 );

alter table "fobos".gent010 add constraint (foreign key (g10_usuario) 
    references "fobos".gent005 );

alter table "fobos".gent010 add constraint (foreign key (g10_compania) 
    references "fobos".gent001  constraint "fobos".fk_02_gent010);
    

alter table "fobos".gent010 add constraint (foreign key (g10_codcobr) 
    references "fobos".cxct001  constraint "fobos".fk_03_gent010);
    

alter table "fobos".gent010 add constraint (foreign key (g10_compania,
    g10_cod_tarj,g10_cont_cred) references "fobos".cajt001  constraint 
    "fobos".fk_04_gent010);

alter table "fobos".gent020 add constraint (foreign key (g20_compania) 
    references "fobos".gent001 );

alter table "fobos".gent020 add constraint (foreign key (g20_compania,
    g20_areaneg) references "fobos".gent003 );

alter table "fobos".gent020 add constraint (foreign key (g20_usuario) 
    references "fobos".gent005 );

alter table "fobos".gent055 add constraint (foreign key (g55_modulo,
    g55_proceso) references "fobos".gent054 );

alter table "fobos".gent055 add constraint (foreign key (g55_compania) 
    references "fobos".gent001 );

alter table "fobos".gent055 add constraint (foreign key (g55_user) 
    references "fobos".gent005 );

alter table "fobos".gent055 add constraint (foreign key (g55_usuario) 
    references "fobos".gent005 );

alter table "fobos".gent006 add constraint (foreign key (g06_usuario) 
    references "fobos".gent005 );

alter table "fobos".gent008 add constraint (foreign key (g08_usuario) 
    references "fobos".gent005 );

alter table "fobos".gent030 add constraint (foreign key (g30_usuario) 
    references "fobos".gent005 );

alter table "fobos".gent022 add constraint (foreign key (g22_usuario) 
    references "fobos".gent005 );

alter table "fobos".gent022 add constraint (foreign key (g22_cod_tran) 
    references "fobos".gent021 );

alter table "fobos".talt003 add constraint (foreign key (t03_compania) 
    references "fobos".talt000 );

alter table "fobos".talt003 add constraint (foreign key (t03_compania,
    t03_codrol) references "fobos".rolt030 );

alter table "fobos".talt003 add constraint (foreign key (t03_compania,
    t03_seccion) references "fobos".talt002 );

alter table "fobos".talt003 add constraint (foreign key (t03_compania,
    t03_linea) references "fobos".talt001 );

alter table "fobos".talt003 add constraint (foreign key (t03_usuario) 
    references "fobos".gent005 );

alter table "fobos".talt005 add constraint (foreign key (t05_compania) 
    references "fobos".talt000 );

alter table "fobos".talt005 add constraint (foreign key (t05_cli_default) 
    references "fobos".cxct001 );

alter table "fobos".talt005 add constraint (foreign key (t05_usuario) 
    references "fobos".gent005 );

alter table "fobos".talt006 add constraint (foreign key (t06_compania) 
    references "fobos".talt000 );

alter table "fobos".talt006 add constraint (foreign key (t06_compania,
    t06_tipord) references "fobos".talt005 );

alter table "fobos".talt006 add constraint (foreign key (t06_usuario) 
    references "fobos".gent005 );

alter table "fobos".talt007 add constraint (foreign key (t07_compania) 
    references "fobos".talt000 );

alter table "fobos".talt007 add constraint (foreign key (t07_usuario) 
    references "fobos".gent005 );

alter table "fobos".talt008 add constraint (foreign key (t08_usuario) 
    references "fobos".gent005 );

alter table "fobos".talt008 add constraint (foreign key (t08_compania,
    t08_codtarea) references "fobos".talt007 );

alter table "fobos".talt009 add constraint (foreign key (t09_usuario) 
    references "fobos".gent005 );

alter table "fobos".talt009 add constraint (foreign key (t09_compania,
    t09_codtarea) references "fobos".talt007 );

alter table "fobos".rept000 add constraint (foreign key (r00_codcli_tal) 
    references "fobos".cxct001 );

alter table "fobos".rept000 add constraint (foreign key (r00_compania) 
    references "fobos".gent001 );

alter table "fobos".rept000 add constraint (foreign key (r00_cia_taller) 
    references "fobos".gent001 );

alter table "fobos".rept001 add constraint (foreign key (r01_compania) 
    references "fobos".rept000 );

alter table "fobos".rept001 add constraint (foreign key (r01_compania,
    r01_codrol) references "fobos".rolt030 );

alter table "fobos".rept001 add constraint (foreign key (r01_usuario) 
    references "fobos".gent005 );

alter table "fobos".rept002 add constraint (foreign key (r02_compania,
    r02_localidad) references "fobos".gent002 );

alter table "fobos".rept002 add constraint (foreign key (r02_usuario) 
    references "fobos".gent005 );

alter table "fobos".rept002 add constraint (foreign key (r02_compania,
    r02_tipo_ident) references "fobos".rept009  constraint "fobos"
    .fk_03_rept002);

alter table "fobos".rept003 add constraint (foreign key (r03_compania) 
    references "fobos".rept000 );

alter table "fobos".rept003 add constraint (foreign key (r03_compania,
    r03_grupo_linea) references "fobos".gent020 );

alter table "fobos".rept003 add constraint (foreign key (r03_usuario) 
    references "fobos".gent005 );

alter table "fobos".rept004 add constraint (foreign key (r04_compania) 
    references "fobos".rept000 );

alter table "fobos".rept004 add constraint (foreign key (r04_usuario) 
    references "fobos".gent005 );

alter table "fobos".rept005 add constraint (foreign key (r05_usuario) 
    references "fobos".gent005 );

alter table "fobos".rept006 add constraint (foreign key (r06_usuario) 
    references "fobos".gent005 );

alter table "fobos".rept007 add constraint (foreign key (r07_compania) 
    references "fobos".rept000 );

alter table "fobos".rept007 add constraint (foreign key (r07_compania,
    r07_linea) references "fobos".rept003 );

alter table "fobos".rept007 add constraint (foreign key (r07_moneda) 
    references "fobos".gent013 );

alter table "fobos".rept008 add constraint (foreign key (r08_compania) 
    references "fobos".rept000 );

alter table "fobos".rept008 add constraint (foreign key (r08_compania,
    r08_rotacion) references "fobos".rept004 );

alter table "fobos".rept011 add constraint (foreign key (r11_compania) 
    references "fobos".rept000 );

alter table "fobos".rept011 add constraint (foreign key (r11_compania,
    r11_bodega) references "fobos".rept002 );

alter table "fobos".rept011 add constraint (foreign key (r11_compania,
    r11_item) references "fobos".rept010 );

alter table "fobos".rept012 add constraint (foreign key (r12_compania) 
    references "fobos".rept000 );

alter table "fobos".rept012 add constraint (foreign key (r12_moneda) 
    references "fobos".gent013 );

alter table "fobos".rept012 add constraint (foreign key (r12_compania,
    r12_bodega) references "fobos".rept002 );

alter table "fobos".rept012 add constraint (foreign key (r12_compania,
    r12_item) references "fobos".rept010 );

alter table "fobos".rept013 add constraint (foreign key (r13_compania) 
    references "fobos".rept000 );

alter table "fobos".rept013 add constraint (foreign key (r13_compania,
    r13_bodega) references "fobos".rept002 );

alter table "fobos".rept013 add constraint (foreign key (r13_compania,
    r13_item) references "fobos".rept010 );

alter table "fobos".rept013 add constraint (foreign key (r13_usuario) 
    references "fobos".gent005 );

alter table "fobos".rept013 add constraint (foreign key (r13_compania,
    r13_localidad) references "fobos".gent002 );

alter table "fobos".rept013 add constraint (foreign key (r13_compania,
    r13_localidad,r13_cod_tran,r13_num_tran) references "fobos"
    .rept019 );

alter table "fobos".rept014 add constraint (foreign key (r14_compania) 
    references "fobos".rept000 );

alter table "fobos".rept014 add constraint (foreign key (r14_compania,
    r14_item_ant) references "fobos".rept010 );

alter table "fobos".rept014 add constraint (foreign key (r14_compania,
    r14_item_nue) references "fobos".rept010 );

alter table "fobos".rept014 add constraint (foreign key (r14_usuario) 
    references "fobos".gent005 );

alter table "fobos".rept015 add constraint (foreign key (r15_compania) 
    references "fobos".rept000 );

alter table "fobos".rept015 add constraint (foreign key (r15_compania,
    r15_item) references "fobos".rept010 );

alter table "fobos".rept015 add constraint (foreign key (r15_compania,
    r15_equivalente) references "fobos".rept010 );

alter table "fobos".rept015 add constraint (foreign key (r15_usuario) 
    references "fobos".gent005 );

alter table "fobos".rept016 add constraint (foreign key (r16_compania,
    r16_linea) references "fobos".rept003 );

alter table "fobos".rept016 add constraint (foreign key (r16_compania) 
    references "fobos".rept000 );

alter table "fobos".rept016 add constraint (foreign key (r16_compania,
    r16_localidad) references "fobos".gent002 );

alter table "fobos".rept016 add constraint (foreign key (r16_compania,
    r16_localidad,r16_proveedor) references "fobos".cxpt002 );
    

alter table "fobos".rept016 add constraint (foreign key (r16_moneda) 
    references "fobos".gent013 );

alter table "fobos".rept016 add constraint (foreign key (r16_compania,
    r16_aux_cont) references "fobos".ctbt010 );

alter table "fobos".rept016 add constraint (foreign key (r16_usuario) 
    references "fobos".gent005 );

alter table "fobos".rept018 add constraint (foreign key (r18_compania,
    r18_localidad,r18_pedido) references "fobos".rept016 );

alter table "fobos".rept018 add constraint (foreign key (r18_compania,
    r18_item) references "fobos".rept010 );

alter table "fobos".rept022 add constraint (foreign key (r22_compania,
    r22_localidad,r22_numprof) references "fobos".rept021 );

alter table "fobos".rept022 add constraint (foreign key (r22_compania,
    r22_item) references "fobos".rept010 );

alter table "fobos".rept022 add constraint (foreign key (r22_compania,
    r22_linea) references "fobos".rept003 );

alter table "fobos".rept022 add constraint (foreign key (r22_compania,
    r22_rotacion) references "fobos".rept004 );

alter table "fobos".rept025 add constraint (foreign key (r25_compania,
    r25_localidad,r25_numprev) references "fobos".rept023 );

alter table "fobos".rept025 add constraint (foreign key (r25_compania,
    r25_localidad,r25_cod_tran,r25_num_tran) references "fobos"
    .rept019 );

alter table "fobos".rept026 add constraint (foreign key (r26_compania,
    r26_localidad,r26_numprev) references "fobos".rept023 );

alter table "fobos".rept029 add constraint (foreign key (r29_compania,
    r29_localidad,r29_numliq) references "fobos".rept028 );

alter table "fobos".rept029 add constraint (foreign key (r29_compania,
    r29_localidad,r29_pedido) references "fobos".rept016 );

alter table "fobos".rept031 add constraint (foreign key (r31_compania) 
    references "fobos".rept000 );

alter table "fobos".rept031 add constraint (foreign key (r31_compania,
    r31_bodega) references "fobos".rept002 );

alter table "fobos".rept031 add constraint (foreign key (r31_compania,
    r31_item) references "fobos".rept010 );

alter table "fobos".rept032 add constraint (foreign key (r32_compania) 
    references "fobos".rept000 );

alter table "fobos".rept032 add constraint (foreign key (r32_compania,
    r32_linea) references "fobos".rept003 );

alter table "fobos".rept032 add constraint (foreign key (r32_compania,
    r32_rotacion) references "fobos".rept004 );

alter table "fobos".rept032 add constraint (foreign key (r32_tipo_item) 
    references "fobos".rept006 );

alter table "fobos".rept032 add constraint (foreign key (r32_usuario) 
    references "fobos".gent005 );

alter table "fobos".rept033 add constraint (foreign key (r33_compania) 
    references "fobos".rept000 );

alter table "fobos".rept033 add constraint (foreign key (r33_compania,
    r33_localidad) references "fobos".gent002 );

alter table "fobos".rept033 add constraint (foreign key (r33_cod_motivo) 
    references "fobos".gent019 );

alter table "fobos".rept033 add constraint (foreign key (r33_moneda) 
    references "fobos".gent013 );

alter table "fobos".rept033 add constraint (foreign key (r33_usuario) 
    references "fobos".gent005 );

alter table "fobos".rept033 add constraint (foreign key (r33_compania,
    r33_localidad,r33_tipcomp_ori,r33_numcomp_ori) references 
    "fobos".rept019 );

alter table "fobos".rept050 add constraint (foreign key (r50_compania) 
    references "fobos".rept000 );

alter table "fobos".rept050 add constraint (foreign key (r50_compania,
    r50_item) references "fobos".rept010 );

alter table "fobos".rept050 add constraint (foreign key (r50_compania,
    r50_indice_ant) references "fobos".rept004 );

alter table "fobos".rept050 add constraint (foreign key (r50_compania,
    r50_indice_act) references "fobos".rept004 );

alter table "fobos".rept050 add constraint (foreign key (r50_usuario) 
    references "fobos".gent005 );

alter table "fobos".rept051 add constraint (foreign key (r51_compania) 
    references "fobos".rept000 );

alter table "fobos".rept051 add constraint (foreign key (r51_compania,
    r51_bodega) references "fobos".rept002 );

alter table "fobos".rept051 add constraint (foreign key (r51_usuario) 
    references "fobos".gent005 );

alter table "fobos".rept052 add constraint (foreign key (r52_compania) 
    references "fobos".rept000 );

alter table "fobos".rept052 add constraint (foreign key (r52_compania,
    r52_bodega) references "fobos".rept002 );

alter table "fobos".rept052 add constraint (foreign key (r52_compania,
    r52_item) references "fobos".rept010 );

alter table "fobos".rept052 add constraint (foreign key (r52_compania,
    r52_linea) references "fobos".rept003 );

alter table "fobos".rept060 add constraint (foreign key (r60_compania) 
    references "fobos".rept000 );

alter table "fobos".rept060 add constraint (foreign key (r60_compania,
    r60_bodega) references "fobos".rept002 );

alter table "fobos".rept060 add constraint (foreign key (r60_compania,
    r60_vendedor) references "fobos".rept001 );

alter table "fobos".rept060 add constraint (foreign key (r60_moneda) 
    references "fobos".gent013 );

alter table "fobos".rept060 add constraint (foreign key (r60_compania,
    r60_linea) references "fobos".rept003 );

alter table "fobos".rept060 add constraint (foreign key (r60_compania,
    r60_rotacion) references "fobos".rept004 );

alter table "fobos".rept061 add constraint (foreign key (r61_compania) 
    references "fobos".rept000 );

alter table "fobos".rept061 add constraint (foreign key (r61_compania,
    r61_bodega) references "fobos".rept002 );

alter table "fobos".rept061 add constraint (foreign key (r61_compania,
    r61_linea) references "fobos".rept003 );

alter table "fobos".rept061 add constraint (foreign key (r61_compania,
    r61_rotacion) references "fobos".rept004 );

alter table "fobos".rept062 add constraint (foreign key (r62_compania) 
    references "fobos".rept000 );

alter table "fobos".rept062 add constraint (foreign key (r62_compania,
    r62_bodega) references "fobos".rept002 );

alter table "fobos".rept062 add constraint (foreign key (r62_compania,
    r62_linea) references "fobos".rept003 );

alter table "fobos".rept062 add constraint (foreign key (r62_tipo_tran) 
    references "fobos".gent021 );

alter table "fobos".talt000 add constraint (foreign key (t00_compania) 
    references "fobos".gent001 );

alter table "fobos".talt000 add constraint (foreign key (t00_cia_vehic) 
    references "fobos".gent001 );

alter table "fobos".talt000 add constraint (foreign key (t00_codcli_int) 
    references "fobos".cxct001 );

alter table "fobos".veht001 add constraint (foreign key (v01_compania) 
    references "fobos".veht000 );

alter table "fobos".veht001 add constraint (foreign key (v01_compania,
    v01_codrol) references "fobos".rolt030 );

alter table "fobos".veht001 add constraint (foreign key (v01_usuario) 
    references "fobos".gent005 );

alter table "fobos".veht002 add constraint (foreign key (v02_compania,
    v02_localidad) references "fobos".gent002 );

alter table "fobos".veht002 add constraint (foreign key (v02_usuario) 
    references "fobos".gent005 );

alter table "fobos".veht004 add constraint (foreign key (v04_compania) 
    references "fobos".veht000 );

alter table "fobos".veht004 add constraint (foreign key (v04_usuario) 
    references "fobos".gent005 );

alter table "fobos".veht005 add constraint (foreign key (v05_compania) 
    references "fobos".veht000 );

alter table "fobos".veht005 add constraint (foreign key (v05_usuario) 
    references "fobos".gent005 );

alter table "fobos".veht007 add constraint (foreign key (v07_compania,
    v07_codigo_plan) references "fobos".veht006 );

alter table "fobos".veht020 add constraint (foreign key (v20_compania) 
    references "fobos".veht000 );

alter table "fobos".veht020 add constraint (foreign key (v20_compania,
    v20_tipo_veh) references "fobos".veht004 );

alter table "fobos".veht020 add constraint (foreign key (v20_compania,
    v20_linea) references "fobos".veht003 );

alter table "fobos".veht020 add constraint (foreign key (v20_moneda) 
    references "fobos".gent013 );

alter table "fobos".veht020 add constraint (foreign key (v20_mon_prov) 
    references "fobos".gent013 );

alter table "fobos".veht020 add constraint (foreign key (v20_usuario) 
    references "fobos".gent005 );

alter table "fobos".veht021 add constraint (foreign key (v21_compania,
    v21_modelo) references "fobos".veht020 );

alter table "fobos".veht021 add constraint (foreign key (v21_usuario) 
    references "fobos".gent005 );

alter table "fobos".veht026 add constraint (foreign key (v26_compania,
    v26_localidad,v26_cod_tran,v26_num_tran) references "fobos"
    .veht030 );

alter table "fobos".veht026 add constraint (foreign key (v26_compania) 
    references "fobos".veht000 );

alter table "fobos".veht026 add constraint (foreign key (v26_compania,
    v26_localidad) references "fobos".gent002 );

alter table "fobos".veht026 add constraint (foreign key (v26_compania,
    v26_localidad,v26_codcli) references "fobos".cxct002 );

alter table "fobos".veht026 add constraint (foreign key (v26_compania,
    v26_vendedor) references "fobos".veht001 );

alter table "fobos".veht026 add constraint (foreign key (v26_moneda) 
    references "fobos".gent013 );

alter table "fobos".veht026 add constraint (foreign key (v26_compania,
    v26_codigo_plan) references "fobos".veht006 );

alter table "fobos".veht026 add constraint (foreign key (v26_usuario) 
    references "fobos".gent005 );

alter table "fobos".veht027 add constraint (foreign key (v27_compania,
    v27_localidad,v27_numprev) references "fobos".veht026 );

alter table "fobos".veht027 add constraint (foreign key (v27_compania,
    v27_localidad,v27_codigo_veh) references "fobos".veht022 );
    

alter table "fobos".veht028 add constraint (foreign key (v28_compania,
    v28_localidad,v28_numprev) references "fobos".veht026 );

alter table "fobos".veht029 add constraint (foreign key (v29_compania,
    v29_localidad,v29_numprev) references "fobos".veht026 );

alter table "fobos".veht029 add constraint (foreign key (v29_tipo_doc) 
    references "fobos".cxct004 );

alter table "fobos".veht030 add constraint (foreign key (v30_compania,
    v30_localidad,v30_tipo_dev,v30_num_dev) references "fobos"
    .veht030 );

alter table "fobos".veht030 add constraint (foreign key (v30_compania) 
    references "fobos".veht000 );

alter table "fobos".veht030 add constraint (foreign key (v30_compania,
    v30_localidad) references "fobos".gent002 );

alter table "fobos".veht030 add constraint (foreign key (v30_cod_subtipo) 
    references "fobos".gent022 );

alter table "fobos".veht030 add constraint (foreign key (v30_compania,
    v30_localidad,v30_codcli) references "fobos".cxct002 );

alter table "fobos".veht030 add constraint (foreign key (v30_compania,
    v30_vendedor) references "fobos".veht001 );

alter table "fobos".veht030 add constraint (foreign key (v30_compania,
    v30_localidad,v30_oc_interna) references "fobos".ordt010 );
    

alter table "fobos".veht030 add constraint (foreign key (v30_compania,
    v30_bodega_ori) references "fobos".veht002 );

alter table "fobos".veht030 add constraint (foreign key (v30_compania,
    v30_bodega_dest) references "fobos".veht002 );

alter table "fobos".veht030 add constraint (foreign key (v30_moneda) 
    references "fobos".gent013 );

alter table "fobos".veht030 add constraint (foreign key (v30_compania,
    v30_localidad,v30_numliq) references "fobos".veht036 );

alter table "fobos".veht030 add constraint (foreign key (v30_usuario) 
    references "fobos".gent005 );

alter table "fobos".veht030 add constraint (foreign key (v30_cod_tran) 
    references "fobos".gent021 );

alter table "fobos".veht032 add constraint (foreign key (v32_compania) 
    references "fobos".veht000 );

alter table "fobos".veht032 add constraint (foreign key (v32_compania,
    v32_linea) references "fobos".veht003 );

alter table "fobos".veht032 add constraint (foreign key (v32_usuario) 
    references "fobos".gent005 );

alter table "fobos".veht034 add constraint (foreign key (v34_compania) 
    references "fobos".veht000 );

alter table "fobos".veht034 add constraint (foreign key (v34_compania,
    v34_localidad) references "fobos".gent002 );

alter table "fobos".veht034 add constraint (foreign key (v34_compania,
    v34_localidad,v34_proveedor) references "fobos".cxpt002 );
    

alter table "fobos".veht034 add constraint (foreign key (v34_moneda) 
    references "fobos".gent013 );

alter table "fobos".veht034 add constraint (foreign key (v34_compania,
    v34_aux_cont) references "fobos".ctbt010 );

alter table "fobos".veht034 add constraint (foreign key (v34_usuario) 
    references "fobos".gent005 );

alter table "fobos".veht035 add constraint (foreign key (v35_compania,
    v35_localidad,v35_pedido) references "fobos".veht034 );

alter table "fobos".veht035 add constraint (foreign key (v35_compania,
    v35_modelo) references "fobos".veht020 );

alter table "fobos".veht035 add constraint (foreign key (v35_compania,
    v35_cod_color) references "fobos".veht005 );

alter table "fobos".veht035 add constraint (foreign key (v35_compania,
    v35_localidad,v35_codigo_veh) references "fobos".veht022 );
    

alter table "fobos".veht035 add constraint (foreign key (v35_compania,
    v35_bodega_alm) references "fobos".veht002 );

alter table "fobos".veht035 add constraint (foreign key (v35_compania,
    v35_bodega_liq) references "fobos".veht002 );

alter table "fobos".veht036 add constraint (foreign key (v36_compania) 
    references "fobos".veht000 );

alter table "fobos".veht036 add constraint (foreign key (v36_compania,
    v36_localidad) references "fobos".gent002 );

alter table "fobos".veht036 add constraint (foreign key (v36_compania,
    v36_localidad,v36_pedido) references "fobos".veht034 );

alter table "fobos".veht036 add constraint (foreign key (v36_moneda) 
    references "fobos".gent013 );

alter table "fobos".veht036 add constraint (foreign key (v36_usuario) 
    references "fobos".gent005 );

alter table "fobos".veht036 add constraint (foreign key (v36_compania,
    v36_bodega) references "fobos".veht002 );

alter table "fobos".veht037 add constraint (foreign key (v37_compania,
    v37_localidad,v37_numliq) references "fobos".veht036 );

alter table "fobos".veht037 add constraint (foreign key (v37_codrubro) 
    references "fobos".gent017 );

alter table "fobos".veht037 add constraint (foreign key (v37_moneda) 
    references "fobos".gent013 );

alter table "fobos".veht039 add constraint (foreign key (v39_compania) 
    references "fobos".veht000 );

alter table "fobos".veht039 add constraint (foreign key (v39_compania,
    v39_bodega) references "fobos".veht002 );

alter table "fobos".veht039 add constraint (foreign key (v39_compania,
    v39_modelo) references "fobos".veht020 );

alter table "fobos".veht039 add constraint (foreign key (v39_moneda) 
    references "fobos".gent013 );

alter table "fobos".veht040 add constraint (foreign key (v40_compania) 
    references "fobos".veht000 );

alter table "fobos".veht040 add constraint (foreign key (v40_compania,
    v40_bodega) references "fobos".veht002 );

alter table "fobos".veht040 add constraint (foreign key (v40_compania,
    v40_modelo) references "fobos".veht020 );

alter table "fobos".veht040 add constraint (foreign key (v40_compania,
    v40_linea) references "fobos".veht003 );

alter table "fobos".veht040 add constraint (foreign key (v40_compania,
    v40_vendedor) references "fobos".veht001 );

alter table "fobos".veht040 add constraint (foreign key (v40_moneda) 
    references "fobos".gent013 );

alter table "fobos".ordt000 add constraint (foreign key (c00_compania) 
    references "fobos".gent001 );

alter table "fobos".ordt010 add constraint (foreign key (c10_compania) 
    references "fobos".ordt000 );

alter table "fobos".ordt010 add constraint (foreign key (c10_compania,
    c10_localidad) references "fobos".gent002 );

alter table "fobos".ordt010 add constraint (foreign key (c10_tipo_orden) 
    references "fobos".ordt001 );

alter table "fobos".ordt010 add constraint (foreign key (c10_compania,
    c10_cod_depto) references "fobos".gent034 );

alter table "fobos".ordt010 add constraint (foreign key (c10_compania,
    c10_localidad,c10_codprov) references "fobos".cxpt002 );

alter table "fobos".ordt010 add constraint (foreign key (c10_usua_aprob) 
    references "fobos".gent005 );

alter table "fobos".ordt010 add constraint (foreign key (c10_compania,
    c10_localidad,c10_ord_trabajo) references "fobos".talt023 
    );

alter table "fobos".ordt010 add constraint (foreign key (c10_moneda) 
    references "fobos".gent013 );

alter table "fobos".ordt010 add constraint (foreign key (c10_usuario) 
    references "fobos".gent005 );

alter table "fobos".ordt010 add constraint (foreign key (c10_compania,
    c10_cod_sust_sri) references "fobos".srit006  constraint "fobos"
    .fk_10_ordt010);

alter table "fobos".ordt012 add constraint (foreign key (c12_compania,
    c12_localidad,c12_numero_oc) references "fobos".ordt010 );
    

alter table "fobos".ordt013 add constraint (foreign key (c13_compania,
    c13_localidad,c13_numero_oc) references "fobos".ordt010 );
    

alter table "fobos".ordt013 add constraint (foreign key (c13_compania,
    c13_bodega) references "fobos".rept002 );

alter table "fobos".ordt013 add constraint (foreign key (c13_usuario) 
    references "fobos".gent005 );

alter table "fobos".ordt013 add constraint (foreign key (c13_compania,
    c13_localidad,c13_num_ret) references "fobos".cxpt027 );

alter table "fobos".veht000 add constraint (foreign key (v00_compania) 
    references "fobos".gent001 );

alter table "fobos".veht000 add constraint (foreign key (v00_cia_taller) 
    references "fobos".gent001 );

alter table "fobos".veht006 add constraint (foreign key (v06_compania) 
    references "fobos".veht000 );

alter table "fobos".veht006 add constraint (foreign key (v06_usuario) 
    references "fobos".gent005 );

alter table "fobos".cxct000 add constraint (foreign key (z00_compania) 
    references "fobos".gent001 );

alter table "fobos".cxct000 add constraint (foreign key (z00_compania,
    z00_aux_clte_mb) references "fobos".ctbt010 );

alter table "fobos".cxct000 add constraint (foreign key (z00_compania,
    z00_aux_clte_ma) references "fobos".ctbt010 );

alter table "fobos".cxct000 add constraint (foreign key (z00_compania,
    z00_aux_ant_mb) references "fobos".ctbt010 );

alter table "fobos".cxct000 add constraint (foreign key (z00_compania,
    z00_aux_ant_ma) references "fobos".ctbt010 );

alter table "fobos".cxct002 add constraint (foreign key (z02_compania) 
    references "fobos".cxct000 );

alter table "fobos".cxct002 add constraint (foreign key (z02_compania,
    z02_localidad) references "fobos".gent002 );

alter table "fobos".cxct002 add constraint (foreign key (z02_codcli) 
    references "fobos".cxct001 );

alter table "fobos".cxct002 add constraint (foreign key (z02_compania,
    z02_zona_venta) references "fobos".gent032 );

alter table "fobos".cxct002 add constraint (foreign key (z02_zona_cobro) 
    references "fobos".cxct006 );

alter table "fobos".cxct002 add constraint (foreign key (z02_compania,
    z02_aux_clte_mb) references "fobos".ctbt010 );

alter table "fobos".cxct002 add constraint (foreign key (z02_compania,
    z02_aux_clte_ma) references "fobos".ctbt010 );

alter table "fobos".cxct002 add constraint (foreign key (z02_compania,
    z02_aux_ant_mb) references "fobos".ctbt010 );

alter table "fobos".cxct002 add constraint (foreign key (z02_compania,
    z02_aux_ant_ma) references "fobos".ctbt010 );

alter table "fobos".cxct002 add constraint (foreign key (z02_usuario) 
    references "fobos".gent005 );

alter table "fobos".cxct003 add constraint (foreign key (z03_compania,
    z03_localidad,z03_codcli) references "fobos".cxct002 );

alter table "fobos".cxct003 add constraint (foreign key (z03_compania,
    z03_areaneg) references "fobos".gent003 );

alter table "fobos".cxct003 add constraint (foreign key (z03_usuario) 
    references "fobos".gent005 );

alter table "fobos".cxct004 add constraint (foreign key (z04_usuario) 
    references "fobos".gent005 );

alter table "fobos".cxct005 add constraint (foreign key (z05_compania) 
    references "fobos".cxct000 );

alter table "fobos".cxct005 add constraint (foreign key (z05_compania,
    z05_codrol) references "fobos".rolt030 );

alter table "fobos".cxct005 add constraint (foreign key (z05_usuario) 
    references "fobos".gent005 );

alter table "fobos".cxct006 add constraint (foreign key (z06_usuario) 
    references "fobos".gent005 );

alter table "fobos".cxct007 add constraint (foreign key (z07_compania) 
    references "fobos".cxct000 );

alter table "fobos".cxct026 add constraint (foreign key (z26_banco) 
    references "fobos".gent008  constraint "fobos".fk_03_cxct026);
    

alter table "fobos".cxct026 add constraint (foreign key (z26_compania,
    z26_localidad,z26_codcli,z26_tipo_doc,z26_num_doc,z26_dividendo) 
    references "fobos".cxct020 );

alter table "fobos".cxct026 add constraint (foreign key (z26_compania,
    z26_localidad,z26_codcli) references "fobos".cxct002 );

alter table "fobos".cxct026 add constraint (foreign key (z26_compania,
    z26_areaneg) references "fobos".gent003 );

alter table "fobos".cxct026 add constraint (foreign key (z26_usuario) 
    references "fobos".gent005 );

alter table "fobos".cxct030 add constraint (foreign key (z30_compania,
    z30_localidad,z30_codcli) references "fobos".cxct002 );

alter table "fobos".cxct030 add constraint (foreign key (z30_compania,
    z30_areaneg) references "fobos".gent003 );

alter table "fobos".cxct030 add constraint (foreign key (z30_moneda) 
    references "fobos".gent013 );

alter table "fobos".cxct031 add constraint (foreign key (z31_compania) 
    references "fobos".cxct000 );

alter table "fobos".cxct031 add constraint (foreign key (z31_compania,
    z31_localidad) references "fobos".gent002 );

alter table "fobos".cxct031 add constraint (foreign key (z31_compania,
    z31_areaneg) references "fobos".gent003 );

alter table "fobos".cxct031 add constraint (foreign key (z31_compania,
    z31_linea) references "fobos".gent020 );

alter table "fobos".cxct031 add constraint (foreign key (z31_moneda) 
    references "fobos".gent013 );

alter table "fobos".cxct032 add constraint (foreign key (z32_compania) 
    references "fobos".cxct000 );

alter table "fobos".cxct032 add constraint (foreign key (z32_compania,
    z32_recaudador) references "fobos".cxct005 );

alter table "fobos".cxpt000 add constraint (foreign key (p00_compania) 
    references "fobos".gent001 );

alter table "fobos".cxpt000 add constraint (foreign key (p00_compania,
    p00_aux_prov_mb) references "fobos".ctbt010 );

alter table "fobos".cxpt000 add constraint (foreign key (p00_compania,
    p00_aux_prov_ma) references "fobos".ctbt010 );

alter table "fobos".cxpt000 add constraint (foreign key (p00_compania,
    p00_aux_ant_mb) references "fobos".ctbt010 );

alter table "fobos".cxpt000 add constraint (foreign key (p00_compania,
    p00_aux_ant_ma) references "fobos".ctbt010 );

alter table "fobos".cxpt002 add constraint (foreign key (p02_compania) 
    references "fobos".cxpt000 );

alter table "fobos".cxpt002 add constraint (foreign key (p02_compania,
    p02_localidad) references "fobos".gent002 );

alter table "fobos".cxpt002 add constraint (foreign key (p02_codprov) 
    references "fobos".cxpt001 );

alter table "fobos".cxpt002 add constraint (foreign key (p02_compania,
    p02_aux_prov_mb) references "fobos".ctbt010 );

alter table "fobos".cxpt002 add constraint (foreign key (p02_compania,
    p02_aux_prov_ma) references "fobos".ctbt010 );

alter table "fobos".cxpt002 add constraint (foreign key (p02_compania,
    p02_aux_ant_mb) references "fobos".ctbt010 );

alter table "fobos".cxpt002 add constraint (foreign key (p02_compania,
    p02_aux_ant_ma) references "fobos".ctbt010 );

alter table "fobos".cxpt002 add constraint (foreign key (p02_usuario) 
    references "fobos".gent005 );

alter table "fobos".cxpt002 add constraint (foreign key (p02_banco_prov) 
    references "fobos".gent008  constraint "fobos".fk_09_cxpt002);
    

alter table "fobos".cxpt002 add constraint (foreign key (p02_compania,
    p02_cod_bco_tra,p02_banco_prov) references "fobos".cxpt006 
     constraint "fobos".fk_10_cxpt002);

alter table "fobos".cxpt003 add constraint (foreign key (p03_compania,
    p03_localidad,p03_codprov) references "fobos".cxpt002 );

alter table "fobos".cxpt003 add constraint (foreign key (p03_compania,
    p03_areaneg) references "fobos".gent003 );

alter table "fobos".cxpt003 add constraint (foreign key (p03_usuario) 
    references "fobos".gent005 );

alter table "fobos".cxpt004 add constraint (foreign key (p04_usuario) 
    references "fobos".gent005 );

alter table "fobos".cxpt025 add constraint (foreign key (p25_compania,
    p25_localidad,p25_orden_pago) references "fobos".cxpt024 );
    

alter table "fobos".cxpt025 add constraint (foreign key (p25_compania,
    p25_localidad,p25_codprov,p25_tipo_doc,p25_num_doc,p25_dividendo) 
    references "fobos".cxpt020  constraint "fobos".fk_01_cxpt025);
    

alter table "fobos".cxpt026 add constraint (foreign key (p26_compania,
    p26_localidad,p26_orden_pago,p26_secuencia) references "fobos"
    .cxpt025 );

alter table "fobos".cxpt026 add constraint (foreign key (p26_compania,
    p26_tipo_ret,p26_porcentaje,p26_codigo_sri,p26_fecha_ini_porc) 
    references "fobos".ordt003  constraint "fobos".fk_03_cxpt026);
    

alter table "fobos".cxpt028 add constraint (foreign key (p28_compania,
    p28_localidad,p28_num_ret) references "fobos".cxpt027 );

alter table "fobos".cxpt028 add constraint (foreign key (p28_compania,
    p28_tipo_ret,p28_porcentaje,p28_codigo_sri,p28_fecha_ini_porc) 
    references "fobos".ordt003  constraint "fobos".fk_03_cxpt028);
    

alter table "fobos".cxpt028 add constraint (foreign key (p28_compania,
    p28_localidad,p28_codprov,p28_tipo_doc,p28_num_doc,p28_dividendo) 
    references "fobos".cxpt020  constraint "fobos".fk_01_cxpt028);
    

alter table "fobos".cajt000 add constraint (foreign key (j00_compania) 
    references "fobos".gent001 );

alter table "fobos".cajt001 add constraint (foreign key (j01_usuario) 
    references "fobos".gent005 );

alter table "fobos".cajt001 add constraint (foreign key (j01_compania,
    j01_aux_cont) references "fobos".ctbt010  constraint "fobos"
    .fk_02_cajt001);

alter table "fobos".cajt002 add constraint (foreign key (j02_compania) 
    references "fobos".cajt000 );

alter table "fobos".cajt002 add constraint (foreign key (j02_compania,
    j02_localidad) references "fobos".gent002 );

alter table "fobos".cajt002 add constraint (foreign key (j02_usua_caja) 
    references "fobos".gent005 );

alter table "fobos".cajt003 add constraint (foreign key (j03_compania,
    j03_localidad,j03_codigo_caja) references "fobos".cajt002 
    );

alter table "fobos".cajt003 add constraint (foreign key (j03_compania,
    j03_areaneg) references "fobos".gent003 );

alter table "fobos".cajt999 add constraint (foreign key (j04_compania,
    j04_localidad,j04_codigo_caja) references "fobos".cajt002 
    );

alter table "fobos".cajt999 add constraint (foreign key (j04_moneda) 
    references "fobos".gent013 );

alter table "fobos".cajt999 add constraint (foreign key (j04_usuario) 
    references "fobos".gent005 );

alter table "fobos".cajt012 add constraint (foreign key (j12_compania,
    j12_localidad,j12_tipo_fuente,j12_num_fuente,j12_sec_cheque) 
    references "fobos".cajt011 );

alter table "fobos".cajt012 add constraint (foreign key (j12_compania) 
    references "fobos".cajt000 );

alter table "fobos".cajt012 add constraint (foreign key (j12_compania,
    j12_localidad) references "fobos".gent002 );

alter table "fobos".cajt012 add constraint (foreign key (j12_compania,
    j12_localidad,j12_codcli) references "fobos".cxct002 );

alter table "fobos".cajt012 add constraint (foreign key (j12_compania,
    j12_areaneg) references "fobos".gent003 );

alter table "fobos".cajt012 add constraint (foreign key (j12_moneda) 
    references "fobos".gent013 );

alter table "fobos".cajt012 add constraint (foreign key (j12_usuario) 
    references "fobos".gent005 );

alter table "fobos".cajt013 add constraint (foreign key (j13_compania,
    j13_localidad,j13_codigo_caja) references "fobos".cajt002 
    );

alter table "fobos".cajt013 add constraint (foreign key (j13_moneda) 
    references "fobos".gent013 );

alter table "fobos".ccht001 add constraint (foreign key (h01_compania,
    h01_localidad) references "fobos".gent002 );

alter table "fobos".ccht001 add constraint (foreign key (h01_moneda) 
    references "fobos".gent013 );

alter table "fobos".ccht001 add constraint (foreign key (h01_compania,
    h01_aux_cont_caj) references "fobos".ctbt010 );

alter table "fobos".ccht001 add constraint (foreign key (h01_compania,
    h01_aux_cont_pag) references "fobos".ctbt010 );

alter table "fobos".ccht001 add constraint (foreign key (h01_usuario) 
    references "fobos".gent005 );

alter table "fobos".ccht002 add constraint (foreign key (h02_compania,
    h02_localidad,h02_caja_chica) references "fobos".ccht001 );
    

alter table "fobos".ccht002 add constraint (foreign key (h02_moneda) 
    references "fobos".gent013 );

alter table "fobos".ccht002 add constraint (foreign key (h02_compania,
    h02_localidad,h02_numero_oc) references "fobos".ordt010 );
    

alter table "fobos".ccht002 add constraint (foreign key (h02_compania,
    h02_tipo_comp,h02_num_comp) references "fobos".ctbt012 );

alter table "fobos".ccht002 add constraint (foreign key (h02_usuario) 
    references "fobos".gent005 );

alter table "fobos".ccht003 add constraint (foreign key (h03_compania,
    h03_localidad,h03_caja_chica,h03_tipo_trn,h03_numero) references 
    "fobos".ccht002 );

alter table "fobos".ccht003 add constraint (foreign key (h03_compania,
    h03_aux_cont) references "fobos".ctbt010 );

alter table "fobos".ccht003 add constraint (foreign key (h03_usuario) 
    references "fobos".gent005 );

alter table "fobos".rolt000 add constraint (foreign key (n00_moneda_pago) 
    references "fobos".gent013 );

alter table "fobos".rolt000 add constraint (foreign key (n00_usuario) 
    references "fobos".gent005 );

alter table "fobos".rolt001 add constraint (foreign key (n01_compania) 
    references "fobos".gent001 );

alter table "fobos".rolt001 add constraint (foreign key (n01_usuario) 
    references "fobos".gent005 );

alter table "fobos".rolt002 add constraint (foreign key (n02_compania) 
    references "fobos".rolt001 );

alter table "fobos".rolt002 add constraint (foreign key (n02_usuario) 
    references "fobos".gent005 );

alter table "fobos".rolt003 add constraint (foreign key (n03_usuario) 
    references "fobos".gent005 );

alter table "fobos".rolt004 add constraint (foreign key (n04_compania) 
    references "fobos".rolt001 );

alter table "fobos".rolt004 add constraint (foreign key (n04_proceso) 
    references "fobos".rolt003 );

alter table "fobos".rolt004 add constraint (foreign key (n04_cod_rubro) 
    references "fobos".rolt006 );

alter table "fobos".rolt004 add constraint (foreign key (n04_usuario) 
    references "fobos".gent005 );

alter table "fobos".rolt005 add constraint (foreign key (n05_compania) 
    references "fobos".rolt001 );

alter table "fobos".rolt005 add constraint (foreign key (n05_proceso) 
    references "fobos".rolt003 );

alter table "fobos".rolt005 add constraint (foreign key (n05_usuario) 
    references "fobos".gent005 );

alter table "fobos".rolt006 add constraint (foreign key (n06_usuario) 
    references "fobos".gent005 );

alter table "fobos".rolt006 add constraint (foreign key (n06_flag_ident) 
    references "fobos".rolt016 );

alter table "fobos".rolt007 add constraint (foreign key (n07_cod_rubro) 
    references "fobos".rolt006 );

alter table "fobos".rolt007 add constraint (foreign key (n07_usuario) 
    references "fobos".gent005 );

alter table "fobos".rolt008 add constraint (foreign key (n08_cod_rubro) 
    references "fobos".rolt006 );

alter table "fobos".rolt008 add constraint (foreign key (n08_rubro_base) 
    references "fobos".rolt006 );

alter table "fobos".rolt009 add constraint (foreign key (n09_compania) 
    references "fobos".rolt001 );

alter table "fobos".rolt009 add constraint (foreign key (n09_cod_rubro) 
    references "fobos".rolt006 );

alter table "fobos".rolt009 add constraint (foreign key (n09_usuario) 
    references "fobos".gent005 );

alter table "fobos".rolt010 add constraint (foreign key (n10_compania,
    n10_cod_rubro) references "fobos".rolt009 );

alter table "fobos".rolt010 add constraint (foreign key (n10_compania,
    n10_cod_trab) references "fobos".rolt030 );

alter table "fobos".rolt010 add constraint (foreign key (n10_usuario) 
    references "fobos".gent005 );

alter table "fobos".rolt010 add constraint (foreign key (n10_cod_liqrol) 
    references "fobos".rolt003  constraint "fobos".fk_03_rolt010);
    

alter table "fobos".rolt011 add constraint (foreign key (n11_cod_liqrol) 
    references "fobos".rolt003 );

alter table "fobos".rolt011 add constraint (foreign key (n11_compania,
    n11_cod_rubro) references "fobos".rolt009 );

alter table "fobos".rolt011 add constraint (foreign key (n11_usuario) 
    references "fobos".gent005 );

alter table "fobos".rolt012 add constraint (foreign key (n12_compania,
    n12_cod_trab) references "fobos".rolt030 );

alter table "fobos".rolt012 add constraint (foreign key (n12_usuario) 
    references "fobos".gent005 );

alter table "fobos".rolt013 add constraint (foreign key (n13_usuario) 
    references "fobos".gent005 );

alter table "fobos".rolt014 add constraint (foreign key (n14_cod_seguro) 
    references "fobos".rolt013 );

alter table "fobos".rolt030 add constraint (foreign key (n30_compania) 
    references "fobos".rolt001 );

alter table "fobos".rolt030 add constraint (foreign key (n30_compania,
    n30_cod_cargo) references "fobos".gent035 );

alter table "fobos".rolt030 add constraint (foreign key (n30_compania,
    n30_cod_depto) references "fobos".gent034 );

alter table "fobos".rolt030 add constraint (foreign key (n30_pais_nac) 
    references "fobos".gent030 );

alter table "fobos".rolt030 add constraint (foreign key (n30_ciudad_nac) 
    references "fobos".gent031 );

alter table "fobos".rolt030 add constraint (foreign key (n30_compania,
    n30_bco_empresa,n30_cta_empresa) references "fobos".gent009 
    );

alter table "fobos".rolt030 add constraint (foreign key (n30_usuario) 
    references "fobos".gent005 );

alter table "fobos".rolt030 add constraint (foreign key (n30_cod_seguro) 
    references "fobos".rolt013 );

alter table "fobos".rolt030 add constraint (foreign key (n30_compania,
    n30_ano_sect,n30_sectorial) references "fobos".rolt017  constraint 
    "fobos".fk_08_rolt030);

alter table "fobos".rolt032 add constraint (foreign key (n32_compania) 
    references "fobos".rolt001 );

alter table "fobos".rolt032 add constraint (foreign key (n32_cod_liqrol) 
    references "fobos".rolt003 );

alter table "fobos".rolt032 add constraint (foreign key (n32_compania,
    n32_cod_trab) references "fobos".rolt030 );

alter table "fobos".rolt032 add constraint (foreign key (n32_compania,
    n32_cod_depto) references "fobos".gent034 );

alter table "fobos".rolt032 add constraint (foreign key (n32_moneda) 
    references "fobos".gent013 );

alter table "fobos".rolt032 add constraint (foreign key (n32_compania,
    n32_bco_empresa,n32_cta_empresa) references "fobos".gent009 
    );

alter table "fobos".rolt032 add constraint (foreign key (n32_usuario) 
    references "fobos".gent005 );

alter table "fobos".rolt033 add constraint (foreign key (n33_compania,
    n33_cod_liqrol,n33_fecha_ini,n33_fecha_fin,n33_cod_trab) 
    references "fobos".rolt032 );

alter table "fobos".rolt033 add constraint (foreign key (n33_compania,
    n33_cod_rubro) references "fobos".rolt009 );

alter table "fobos".rolt033 add constraint (foreign key (n33_compania,
    n33_num_prest) references "fobos".rolt045 );

alter table "fobos".rolt034 add constraint (foreign key (n34_compania,
    n34_cod_trab) references "fobos".rolt030 );

alter table "fobos".rolt034 add constraint (foreign key (n34_compania,
    n34_cod_rubro) references "fobos".rolt009 );

alter table "fobos".rolt034 add constraint (foreign key (n34_compania,
    n34_cod_depto) references "fobos".gent034 );

alter table "fobos".rolt034 add constraint (foreign key (n34_moneda) 
    references "fobos".gent013 );

alter table "fobos".rolt034 add constraint (foreign key (n34_cod_liqrol) 
    references "fobos".rolt003 );

alter table "fobos".rolt034 add constraint (foreign key (n34_compania,
    n34_bco_empresa,n34_cta_empresa) references "fobos".gent009 
    );

alter table "fobos".rolt034 add constraint (foreign key (n34_usuario) 
    references "fobos".gent005 );

alter table "fobos".rolt035 add constraint (foreign key (n35_compania,
    n35_cod_trab) references "fobos".rolt030 );

alter table "fobos".rolt035 add constraint (foreign key (n35_compania,
    n35_cod_depto) references "fobos".gent034 );

alter table "fobos".rolt035 add constraint (foreign key (n35_proceso) 
    references "fobos".rolt003 );

alter table "fobos".rolt035 add constraint (foreign key (n35_moneda) 
    references "fobos".gent013 );

alter table "fobos".rolt035 add constraint (foreign key (n35_usuario) 
    references "fobos".gent005 );

alter table "fobos".rolt036 add constraint (foreign key (n36_compania,
    n36_cod_trab) references "fobos".rolt030 );

alter table "fobos".rolt036 add constraint (foreign key (n36_proceso) 
    references "fobos".rolt003 );

alter table "fobos".rolt036 add constraint (foreign key (n36_compania,
    n36_cod_depto) references "fobos".gent034 );

alter table "fobos".rolt036 add constraint (foreign key (n36_moneda) 
    references "fobos".gent013 );

alter table "fobos".rolt036 add constraint (foreign key (n36_compania,
    n36_bco_empresa,n36_cta_empresa) references "fobos".gent009 
    );

alter table "fobos".rolt036 add constraint (foreign key (n36_usuario) 
    references "fobos".gent005 );

alter table "fobos".rolt036 add constraint (foreign key (n36_usuario_modif) 
    references "fobos".gent005 );

alter table "fobos".rolt037 add constraint (foreign key (n37_compania,
    n37_proceso,n37_fecha_ini,n37_fecha_fin,n37_cod_trab) references 
    "fobos".rolt036 );

alter table "fobos".rolt037 add constraint (foreign key (n37_compania,
    n37_cod_rubro) references "fobos".rolt009 );

alter table "fobos".rolt037 add constraint (foreign key (n37_compania,
    n37_num_prest) references "fobos".rolt045 );

alter table "fobos".rolt038 add constraint (foreign key (n38_compania,
    n38_cod_trab) references "fobos".rolt030 );

alter table "fobos".rolt038 add constraint (foreign key (n38_moneda) 
    references "fobos".gent013 );

alter table "fobos".rolt038 add constraint (foreign key (n38_usuario) 
    references "fobos".gent005 );

alter table "fobos".rolt042 add constraint (foreign key (n42_compania,
    n42_proceso,n42_fecha_ini,n42_fecha_fin) references "fobos"
    .rolt041  constraint "fobos".fk_01_rolt042);

alter table "fobos".rolt042 add constraint (foreign key (n42_compania,
    n42_cod_trab) references "fobos".rolt030  constraint "fobos"
    .fk_02_rolt042);

alter table "fobos".rolt042 add constraint (foreign key (n42_compania,
    n42_cod_depto) references "fobos".gent034  constraint "fobos"
    .fk_03_rolt042);

alter table "fobos".rolt042 add constraint (foreign key (n42_bco_empresa) 
    references "fobos".gent008  constraint "fobos".fk_04_rolt042);
    

alter table "fobos".rolt042 add constraint (foreign key (n42_compania,
    n42_bco_empresa,n42_cta_empresa) references "fobos".gent009 
     constraint "fobos".fk_05_rolt042);

alter table "fobos".rolt043 add constraint (foreign key (n43_compania) 
    references "fobos".rolt000 );

alter table "fobos".rolt043 add constraint (foreign key (n43_moneda) 
    references "fobos".gent013 );

alter table "fobos".rolt043 add constraint (foreign key (n43_usuario) 
    references "fobos".gent005 );

alter table "fobos".rolt044 add constraint (foreign key (n44_compania,
    n44_num_rol) references "fobos".rolt043 );

alter table "fobos".rolt044 add constraint (foreign key (n44_compania,
    n44_cod_trab) references "fobos".rolt030 );

alter table "fobos".rolt044 add constraint (foreign key (n44_compania,
    n44_cod_depto) references "fobos".gent034 );

alter table "fobos".rolt044 add constraint (foreign key (n44_compania,
    n44_bco_empresa,n44_cta_empresa) references "fobos".gent009 
    );

alter table "fobos".rolt045 add constraint (foreign key (n45_compania,
    n45_cod_trab) references "fobos".rolt030 );

alter table "fobos".rolt045 add constraint (foreign key (n45_compania,
    n45_cod_rubro) references "fobos".rolt009 );

alter table "fobos".rolt045 add constraint (foreign key (n45_moneda) 
    references "fobos".gent013 );

alter table "fobos".rolt045 add constraint (foreign key (n45_usuario) 
    references "fobos".gent005 );

alter table "fobos".rolt045 add constraint (foreign key (n45_bco_empresa) 
    references "fobos".gent008  constraint "fobos".fk_05_rolt045);
    

alter table "fobos".rolt045 add constraint (foreign key (n45_compania,
    n45_bco_empresa,n45_cta_empresa) references "fobos".gent009 
     constraint "fobos".fk_06_rolt045);

alter table "fobos".rolt045 add constraint (foreign key (n45_compania,
    n45_prest_tran) references "fobos".rolt045  constraint "fobos"
    .fk_07_rolt045);

alter table "fobos".rolt046 add constraint (foreign key (n46_compania,
    n46_num_prest) references "fobos".rolt045 );

alter table "fobos".rolt046 add constraint (foreign key (n46_cod_liqrol) 
    references "fobos".rolt003 );

alter table "fobos".actt000 add constraint (foreign key (a00_compania) 
    references "fobos".gent001 );

alter table "fobos".actt000 add constraint (foreign key (a00_compania,
    a00_aux_reexp) references "fobos".ctbt010 );

alter table "fobos".actt003 add constraint (foreign key (a03_compania) 
    references "fobos".actt000 );

alter table "fobos".actt003 add constraint (foreign key (a03_ciarol,
    a03_codrol) references "fobos".rolt030 );

alter table "fobos".actt003 add constraint (foreign key (a03_usuario) 
    references "fobos".gent005 );

alter table "fobos".actt004 add constraint (foreign key (a04_usuario) 
    references "fobos".gent005 );

alter table "fobos".actt005 add constraint (foreign key (a05_compania) 
    references "fobos".actt000 );

alter table "fobos".actt005 add constraint (foreign key (a05_codigo_tran) 
    references "fobos".actt004 );

alter table "fobos".actt011 add constraint (foreign key (a11_compania,
    a11_codigo_bien) references "fobos".actt010 );

alter table "fobos".actt011 add constraint (foreign key (a11_compania,
    a11_cod_depto) references "fobos".gent034 );

alter table "fobos".ctbt000 add constraint (foreign key (b00_compania) 
    references "fobos".gent001 );

alter table "fobos".ctbt000 add constraint (foreign key (b00_moneda_base) 
    references "fobos".gent013 );

alter table "fobos".ctbt000 add constraint (foreign key (b00_moneda_aux) 
    references "fobos".gent013 );

alter table "fobos".ctbt000 add constraint (foreign key (b00_compania,
    b00_cuenta_uti) references "fobos".ctbt010 );

alter table "fobos".ctbt000 add constraint (foreign key (b00_compania,
    b00_cta_uti_ant) references "fobos".ctbt010 );

alter table "fobos".ctbt000 add constraint (foreign key (b00_compania,
    b00_cuenta_difi) references "fobos".ctbt010 );

alter table "fobos".ctbt000 add constraint (foreign key (b00_compania,
    b00_cuenta_dife) references "fobos".ctbt010 );

alter table "fobos".ctbt001 add constraint (foreign key (b01_usuario) 
    references "fobos".gent005 );

alter table "fobos".ctbt002 add constraint (foreign key (b02_compania) 
    references "fobos".ctbt000 );

alter table "fobos".ctbt002 add constraint (foreign key (b02_usuario) 
    references "fobos".gent005 );

alter table "fobos".ctbt003 add constraint (foreign key (b03_compania) 
    references "fobos".ctbt000 );

alter table "fobos".ctbt003 add constraint (foreign key (b03_modulo) 
    references "fobos".gent050 );

alter table "fobos".ctbt003 add constraint (foreign key (b03_usuario) 
    references "fobos".gent005 );

alter table "fobos".ctbt004 add constraint (foreign key (b04_compania) 
    references "fobos".ctbt000 );

alter table "fobos".ctbt004 add constraint (foreign key (b04_usuario) 
    references "fobos".gent005 );

alter table "fobos".ctbt005 add constraint (foreign key (b05_compania,
    b05_tipo_comp) references "fobos".ctbt003 );

alter table "fobos".ctbt005 add constraint (foreign key (b05_usuario) 
    references "fobos".gent005 );

alter table "fobos".ctbt006 add constraint (foreign key (b06_compania) 
    references "fobos".ctbt000 );

alter table "fobos".ctbt006 add constraint (foreign key (b06_usuario) 
    references "fobos".gent005 );

alter table "fobos".ctbt007 add constraint (foreign key (b07_usuario) 
    references "fobos".gent005 );

alter table "fobos".ctbt008 add constraint (foreign key (b08_compania) 
    references "fobos".ctbt000 );

alter table "fobos".ctbt008 add constraint (foreign key (b08_usuario) 
    references "fobos".gent005 );

alter table "fobos".ctbt010 add constraint (foreign key (b10_compania) 
    references "fobos".ctbt000 );

alter table "fobos".ctbt010 add constraint (foreign key (b10_nivel) 
    references "fobos".ctbt001 );

alter table "fobos".ctbt010 add constraint (foreign key (b10_compania,
    b10_cod_ccosto) references "fobos".gent033 );

alter table "fobos".ctbt010 add constraint (foreign key (b10_usuario) 
    references "fobos".gent005 );

alter table "fobos".ctbt011 add constraint (foreign key (b11_compania,
    b11_cuenta) references "fobos".ctbt010 );

alter table "fobos".ctbt011 add constraint (foreign key (b11_moneda) 
    references "fobos".gent013 );

alter table "fobos".ctbt014 add constraint (foreign key (b14_compania) 
    references "fobos".ctbt000 );

alter table "fobos".ctbt014 add constraint (foreign key (b14_compania,
    b14_tipo_comp) references "fobos".ctbt003 );

alter table "fobos".ctbt014 add constraint (foreign key (b14_moneda) 
    references "fobos".gent013 );

alter table "fobos".ctbt014 add constraint (foreign key (b14_compania,
    b14_tipo_comp,b14_ult_num) references "fobos".ctbt012 );

alter table "fobos".ctbt014 add constraint (foreign key (b14_usuario) 
    references "fobos".gent005 );

alter table "fobos".ctbt015 add constraint (foreign key (b15_compania,
    b15_codigo) references "fobos".ctbt014 );

alter table "fobos".ctbt015 add constraint (foreign key (b15_compania,
    b15_cuenta) references "fobos".ctbt010 );

alter table "fobos".ctbt016 add constraint (foreign key (b16_compania,
    b16_cta_master) references "fobos".ctbt010 );

alter table "fobos".ctbt016 add constraint (foreign key (b16_compania,
    b16_cta_detail) references "fobos".ctbt010 );

alter table "fobos".ctbt030 add constraint (foreign key (b30_compania) 
    references "fobos".ctbt000 );

alter table "fobos".ctbt030 add constraint (foreign key (b30_compania,
    b30_banco,b30_numero_cta) references "fobos".gent009 );

alter table "fobos".ctbt030 add constraint (foreign key (b30_compania,
    b30_aux_cont) references "fobos".ctbt010 );

alter table "fobos".ctbt030 add constraint (foreign key (b30_moneda) 
    references "fobos".gent013 );

alter table "fobos".ctbt030 add constraint (foreign key (b30_compania,
    b30_tipcomp_gen,b30_numcomp_gen) references "fobos".ctbt012 
    );

alter table "fobos".ctbt030 add constraint (foreign key (b30_usuario) 
    references "fobos".gent005 );

alter table "fobos".ctbt031 add constraint (foreign key (b31_compania,
    b31_num_concil) references "fobos".ctbt030 );

alter table "fobos".ctbt031 add constraint (foreign key (b31_tipo_doc) 
    references "fobos".ctbt007 );

alter table "fobos".talt004 add constraint (foreign key (t04_compania) 
    references "fobos".talt000 );

alter table "fobos".talt004 add constraint (foreign key (t04_compania,
    t04_linea) references "fobos".talt001 );

alter table "fobos".talt004 add constraint (foreign key (t04_usuario) 
    references "fobos".gent005 );

alter table "fobos".talt022 add constraint (foreign key (t22_compania,
    t22_item) references "fobos".rept010 );

alter table "fobos".talt022 add constraint (foreign key (t22_usuario) 
    references "fobos".gent005 );

alter table "fobos".talt022 add constraint (foreign key (t22_compania,
    t22_localidad,t22_numpre) references "fobos".talt020 );

alter table "fobos".talt024 add constraint (foreign key (t24_compania,
    t24_localidad,t24_orden) references "fobos".talt023 );

alter table "fobos".talt024 add constraint (foreign key (t24_compania,
    t24_mecanico) references "fobos".talt003 );

alter table "fobos".talt024 add constraint (foreign key (t24_compania,
    t24_seccion) references "fobos".talt002 );

alter table "fobos".talt024 add constraint (foreign key (t24_compania,
    t24_localidad,t24_ord_compra) references "fobos".ordt010 );
    

alter table "fobos".talt024 add constraint (foreign key (t24_usuario) 
    references "fobos".gent005 );

alter table "fobos".talt024 add constraint (foreign key (t24_compania,
    t24_codtarea) references "fobos".talt007 );

alter table "fobos".talt025 add constraint (foreign key (t25_compania,
    t25_localidad,t25_orden) references "fobos".talt023 );

alter table "fobos".talt026 add constraint (foreign key (t26_compania,
    t26_localidad,t26_orden) references "fobos".talt023 );

alter table "fobos".talt027 add constraint (foreign key (t27_compania,
    t27_localidad,t27_orden) references "fobos".talt023 );

alter table "fobos".talt027 add constraint (foreign key (t27_tipo) 
    references "fobos".cxct004 );

alter table "fobos".talt040 add constraint (foreign key (t40_compania) 
    references "fobos".talt000 );

alter table "fobos".talt040 add constraint (foreign key (t40_compania,
    t40_localidad) references "fobos".gent002 );

alter table "fobos".talt040 add constraint (foreign key (t40_compania,
    t40_tipo_orden) references "fobos".talt005 );

alter table "fobos".talt040 add constraint (foreign key (t40_moneda) 
    references "fobos".gent013 );

alter table "fobos".talt040 add constraint (foreign key (t40_compania,
    t40_modelo) references "fobos".talt004 );

alter table "fobos".talt041 add constraint (foreign key (t41_compania) 
    references "fobos".talt000 );

alter table "fobos".talt041 add constraint (foreign key (t41_compania,
    t41_localidad) references "fobos".gent002 );

alter table "fobos".talt041 add constraint (foreign key (t41_compania,
    t41_mecanico) references "fobos".talt003 );

alter table "fobos".talt041 add constraint (foreign key (t41_moneda) 
    references "fobos".gent013 );

alter table "fobos".talt041 add constraint (foreign key (t41_compania,
    t41_modelo) references "fobos".talt004 );

alter table "fobos".talt010 add constraint (foreign key (t10_compania) 
    references "fobos".talt000 );

alter table "fobos".talt010 add constraint (foreign key (t10_codcli) 
    references "fobos".cxct001 );

alter table "fobos".talt010 add constraint (foreign key (t10_compania,
    t10_modelo) references "fobos".talt004 );

alter table "fobos".talt010 add constraint (foreign key (t10_usuario) 
    references "fobos".gent005 );

alter table "fobos".veht023 add constraint (foreign key (v23_compania,
    v23_localidad,v23_codigo_veh) references "fobos".veht022 );
    

alter table "fobos".veht023 add constraint (foreign key (v23_mon_costo) 
    references "fobos".gent013 );

alter table "fobos".veht023 add constraint (foreign key (v23_usuario) 
    references "fobos".gent005 );

alter table "fobos".veht033 add constraint (foreign key (v33_compania) 
    references "fobos".veht000 );

alter table "fobos".veht033 add constraint (foreign key (v33_compania,
    v33_localidad) references "fobos".gent002 );

alter table "fobos".veht033 add constraint (foreign key (v33_compania,
    v33_localidad,v33_codigo_veh) references "fobos".veht022 );
    

alter table "fobos".veht033 add constraint (foreign key (v33_compania,
    v33_vendedor) references "fobos".veht001 );

alter table "fobos".veht033 add constraint (foreign key (v33_compania,
    v33_localidad,v33_codcli,v33_tipo_doc,v33_num_doc) references 
    "fobos".cxct021 );

alter table "fobos".veht033 add constraint (foreign key (v33_usuario) 
    references "fobos".gent005 );

alter table "fobos".veht041 add constraint (foreign key (v41_compania) 
    references "fobos".veht000 );

alter table "fobos".veht041 add constraint (foreign key (v41_compania,
    v41_localidad) references "fobos".gent002 );

alter table "fobos".veht041 add constraint (foreign key (v41_compania,
    v41_bodega) references "fobos".veht002 );

alter table "fobos".veht041 add constraint (foreign key (v41_compania,
    v41_modelo) references "fobos".veht020 );

alter table "fobos".veht041 add constraint (foreign key (v41_compania,
    v41_cod_color) references "fobos".veht005 );

alter table "fobos".veht041 add constraint (foreign key (v41_moneda_liq) 
    references "fobos".gent013 );

alter table "fobos".veht041 add constraint (foreign key (v41_compania,
    v41_localidad,v41_numero_liq) references "fobos".veht036 );
    

alter table "fobos".veht041 add constraint (foreign key (v41_compania,
    v41_localidad,v41_pedido) references "fobos".veht034 );

alter table "fobos".veht041 add constraint (foreign key (v41_moneda_ing) 
    references "fobos".gent013 );

alter table "fobos".veht041 add constraint (foreign key (v41_moneda_prec) 
    references "fobos".gent013 );

alter table "fobos".veht041 add constraint (foreign key (v41_compania,
    v41_localidad,v41_cod_tran,v41_num_tran) references "fobos"
    .veht030 );

alter table "fobos".veht041 add constraint (foreign key (v41_usuario) 
    references "fobos".gent005 );

alter table "fobos".cxct021 add constraint (foreign key (z21_compania,
    z21_localidad,z21_codcli) references "fobos".cxct002 );

alter table "fobos".cxct021 add constraint (foreign key (z21_compania,
    z21_linea) references "fobos".gent020 );

alter table "fobos".cxct021 add constraint (foreign key (z21_tipo_doc) 
    references "fobos".cxct004 );

alter table "fobos".cxct021 add constraint (foreign key (z21_compania,
    z21_areaneg) references "fobos".gent003 );

alter table "fobos".cxct021 add constraint (foreign key (z21_moneda) 
    references "fobos".gent013 );

alter table "fobos".cxct021 add constraint (foreign key (z21_usuario) 
    references "fobos".gent005 );

alter table "fobos".cxct023 add constraint (foreign key (z23_compania,
    z23_localidad,z23_codcli,z23_tipo_doc,z23_num_doc,z23_div_doc) 
    references "fobos".cxct020 );

alter table "fobos".cxct023 add constraint (foreign key (z23_compania,
    z23_localidad,z23_codcli,z23_tipo_trn,z23_num_trn) references 
    "fobos".cxct022 );

alter table "fobos".cxct023 add constraint (foreign key (z23_compania,
    z23_areaneg) references "fobos".gent003 );

alter table "fobos".cxct023 add constraint (foreign key (z23_compania,
    z23_localidad,z23_codcli,z23_tipo_favor,z23_doc_favor) references 
    "fobos".cxct021 );

alter table "fobos".cxct050 add constraint (foreign key (z50_compania,
    z50_localidad,z50_codcli) references "fobos".cxct002 );

alter table "fobos".cxct050 add constraint (foreign key (z50_tipo_doc) 
    references "fobos".cxct004 );

alter table "fobos".cxct050 add constraint (foreign key (z50_compania,
    z50_areaneg) references "fobos".gent003 );

alter table "fobos".cxct050 add constraint (foreign key (z50_moneda) 
    references "fobos".gent013 );

alter table "fobos".cxct050 add constraint (foreign key (z50_compania,
    z50_linea) references "fobos".gent020 );

alter table "fobos".cxct050 add constraint (foreign key (z50_usuario) 
    references "fobos".gent005 );

alter table "fobos".cxct051 add constraint (foreign key (z51_compania,
    z51_localidad,z51_codcli) references "fobos".cxct002 );

alter table "fobos".cxct051 add constraint (foreign key (z51_tipo_doc) 
    references "fobos".cxct004 );

alter table "fobos".cxct051 add constraint (foreign key (z51_compania,
    z51_areaneg) references "fobos".gent003 );

alter table "fobos".cxct051 add constraint (foreign key (z51_moneda) 
    references "fobos".gent013 );

alter table "fobos".cxct051 add constraint (foreign key (z51_usuario) 
    references "fobos".gent005 );

alter table "fobos".veht038 add constraint (foreign key (v38_compania) 
    references "fobos".veht000 );

alter table "fobos".veht038 add constraint (foreign key (v38_compania,
    v38_localidad) references "fobos".gent002 );

alter table "fobos".veht038 add constraint (foreign key (v38_compania,
    v38_localidad,v38_codigo_veh) references "fobos".veht022 );
    

alter table "fobos".veht038 add constraint (foreign key (v38_compania,
    v38_localidad,v38_num_ot) references "fobos".talt023 );

alter table "fobos".veht038 add constraint (foreign key (v38_usuario) 
    references "fobos".gent005 );

alter table "fobos".veht022 add constraint (foreign key (v22_compania,
    v22_localidad,v22_cod_tran,v22_num_tran) references "fobos"
    .veht030 );

alter table "fobos".veht022 add constraint (foreign key (v22_compania) 
    references "fobos".veht000 );

alter table "fobos".veht022 add constraint (foreign key (v22_compania,
    v22_localidad) references "fobos".gent002 );

alter table "fobos".veht022 add constraint (foreign key (v22_compania,
    v22_bodega) references "fobos".veht002 );

alter table "fobos".veht022 add constraint (foreign key (v22_compania,
    v22_modelo) references "fobos".veht020 );

alter table "fobos".veht022 add constraint (foreign key (v22_compania,
    v22_cod_color) references "fobos".veht005 );

alter table "fobos".veht022 add constraint (foreign key (v22_moneda_liq) 
    references "fobos".gent013 );

alter table "fobos".veht022 add constraint (foreign key (v22_compania,
    v22_localidad,v22_numero_liq) references "fobos".veht036 );
    

alter table "fobos".veht022 add constraint (foreign key (v22_compania,
    v22_localidad,v22_pedido) references "fobos".veht034 );

alter table "fobos".veht022 add constraint (foreign key (v22_moneda_ing) 
    references "fobos".gent013 );

alter table "fobos".veht022 add constraint (foreign key (v22_moneda_prec) 
    references "fobos".gent013 );

alter table "fobos".veht022 add constraint (foreign key (v22_usuario) 
    references "fobos".gent005 );

alter table "fobos".cxct024 add constraint (foreign key (z24_compania,
    z24_linea) references "fobos".gent020 );

alter table "fobos".cxct024 add constraint (foreign key (z24_compania,
    z24_localidad,z24_codcli) references "fobos".cxct002 );

alter table "fobos".cxct024 add constraint (foreign key (z24_compania,
    z24_areaneg) references "fobos".gent003 );

alter table "fobos".cxct024 add constraint (foreign key (z24_moneda) 
    references "fobos".gent013 );

alter table "fobos".cxct024 add constraint (foreign key (z24_compania,
    z24_cobrador) references "fobos".cxct005 );

alter table "fobos".cxct024 add constraint (foreign key (z24_usuario) 
    references "fobos".gent005 );

alter table "fobos".cxct024 add constraint (foreign key (z24_zona_cobro) 
    references "fobos".cxct006  constraint "fobos".fk_07_cxct024);
    

alter table "fobos".cxct025 add constraint (foreign key (z25_compania,
    z25_localidad,z25_codcli,z25_tipo_doc,z25_num_doc,z25_dividendo) 
    references "fobos".cxct020 );

alter table "fobos".cxct025 add constraint (foreign key (z25_compania,
    z25_localidad,z25_numero_sol) references "fobos".cxct024 );
    

alter table "fobos".cxpt020 add constraint (foreign key (p20_compania,
    p20_localidad,p20_codprov) references "fobos".cxpt002 );

alter table "fobos".cxpt020 add constraint (foreign key (p20_tipo_doc) 
    references "fobos".cxpt004 );

alter table "fobos".cxpt020 add constraint (foreign key (p20_moneda) 
    references "fobos".gent013 );

alter table "fobos".cxpt020 add constraint (foreign key (p20_compania,
    p20_localidad,p20_numero_oc) references "fobos".ordt010 );
    

alter table "fobos".cxpt020 add constraint (foreign key (p20_usuario) 
    references "fobos".gent005 );

alter table "fobos".cxpt020 add constraint (foreign key (p20_compania,
    p20_cod_depto) references "fobos".gent034 );

alter table "fobos".cxpt021 add constraint (foreign key (p21_compania,
    p21_localidad,p21_orden_pago) references "fobos".cxpt024 );
    

alter table "fobos".cxpt021 add constraint (foreign key (p21_compania,
    p21_localidad,p21_codprov) references "fobos".cxpt002 );

alter table "fobos".cxpt021 add constraint (foreign key (p21_tipo_doc) 
    references "fobos".cxpt004 );

alter table "fobos".cxpt021 add constraint (foreign key (p21_moneda) 
    references "fobos".gent013 );

alter table "fobos".cxpt021 add constraint (foreign key (p21_usuario) 
    references "fobos".gent005 );

alter table "fobos".cxpt022 add constraint (foreign key (p22_compania,
    p22_localidad,p22_orden_pago) references "fobos".cxpt024 );
    

alter table "fobos".cxpt022 add constraint (foreign key (p22_compania,
    p22_localidad,p22_codprov) references "fobos".cxpt002 );

alter table "fobos".cxpt022 add constraint (foreign key (p22_tipo_trn) 
    references "fobos".cxpt004 );

alter table "fobos".cxpt022 add constraint (foreign key (p22_moneda) 
    references "fobos".gent013 );

alter table "fobos".cxpt022 add constraint (foreign key (p22_usuario) 
    references "fobos".gent005 );

alter table "fobos".cxpt022 add constraint (foreign key (p22_compania,
    p22_localidad,p22_codprov,p22_tiptrn_elim,p22_numtrn_elim) 
    references "fobos".cxpt022 );

alter table "fobos".cxpt050 add constraint (foreign key (p50_compania,
    p50_localidad,p50_codprov) references "fobos".cxpt002 );

alter table "fobos".cxpt050 add constraint (foreign key (p50_tipo_doc) 
    references "fobos".cxpt004 );

alter table "fobos".cxpt050 add constraint (foreign key (p50_moneda) 
    references "fobos".gent013 );

alter table "fobos".cxpt050 add constraint (foreign key (p50_compania,
    p50_localidad,p50_numero_oc) references "fobos".ordt010 );
    

alter table "fobos".cxpt050 add constraint (foreign key (p50_usuario) 
    references "fobos".gent005 );

alter table "fobos".cxpt050 add constraint (foreign key (p50_compania,
    p50_cod_depto) references "fobos".gent034 );

alter table "fobos".cxpt051 add constraint (foreign key (p51_compania,
    p51_localidad,p51_codprov) references "fobos".cxpt002 );

alter table "fobos".cxpt051 add constraint (foreign key (p51_tipo_doc) 
    references "fobos".cxpt004 );

alter table "fobos".cxpt051 add constraint (foreign key (p51_moneda) 
    references "fobos".gent013 );

alter table "fobos".cxpt051 add constraint (foreign key (p51_usuario) 
    references "fobos".gent005 );

alter table "fobos".cxpt023 add constraint (foreign key (p23_compania,
    p23_localidad,p23_codprov,p23_tipo_trn,p23_num_trn) references 
    "fobos".cxpt022 );

alter table "fobos".cxpt023 add constraint (foreign key (p23_compania,
    p23_localidad,p23_codprov,p23_tipo_favor,p23_doc_favor) references 
    "fobos".cxpt021 );

alter table "fobos".cxpt023 add constraint (foreign key (p23_compania,
    p23_localidad,p23_codprov,p23_tipo_doc,p23_num_doc,p23_div_doc) 
    references "fobos".cxpt020  constraint "fobos".fk_02_cxpt023);
    

alter table "fobos".cxpt024 add constraint (foreign key (p24_compania,
    p24_localidad,p24_codprov) references "fobos".cxpt002 );

alter table "fobos".cxpt024 add constraint (foreign key (p24_moneda) 
    references "fobos".gent013 );

alter table "fobos".cxpt024 add constraint (foreign key (p24_compania,
    p24_banco,p24_numero_cta) references "fobos".gent009 );

alter table "fobos".cxpt024 add constraint (foreign key (p24_compania,
    p24_tip_contable,p24_num_contable) references "fobos".ctbt012 
    );

alter table "fobos".cxpt024 add constraint (foreign key (p24_usuario) 
    references "fobos".gent005 );

alter table "fobos".cxpt027 add constraint (foreign key (p27_compania,
    p27_localidad,p27_codprov) references "fobos".cxpt002 );

alter table "fobos".cxpt027 add constraint (foreign key (p27_moneda) 
    references "fobos".gent013 );

alter table "fobos".cxpt027 add constraint (foreign key (p27_compania,
    p27_tip_contable,p27_num_contable) references "fobos".ctbt012 
    );

alter table "fobos".cxpt027 add constraint (foreign key (p27_compania,
    p27_tip_cont_eli,p27_num_cont_eli) references "fobos".ctbt012 
    );

alter table "fobos".cxpt027 add constraint (foreign key (p27_usuario) 
    references "fobos".gent005 );

alter table "fobos".ordt002 add constraint (foreign key (c02_compania) 
    references "fobos".ordt000 );

alter table "fobos".ordt002 add constraint (foreign key (c02_compania,
    c02_aux_cont) references "fobos".ctbt010 );

alter table "fobos".ordt002 add constraint (foreign key (c02_usuario) 
    references "fobos".gent005 );

alter table "fobos".actt010 add constraint (foreign key (a10_compania) 
    references "fobos".actt000 );

alter table "fobos".actt010 add constraint (foreign key (a10_compania,
    a10_grupo_act) references "fobos".actt001 );

alter table "fobos".actt010 add constraint (foreign key (a10_compania,
    a10_tipo_act) references "fobos".actt002 );

alter table "fobos".actt010 add constraint (foreign key (a10_compania,
    a10_locali_ori) references "fobos".gent002 );

alter table "fobos".actt010 add constraint (foreign key (a10_compania,
    a10_localidad) references "fobos".gent002 );

alter table "fobos".actt010 add constraint (foreign key (a10_compania,
    a10_locali_ori,a10_numero_oc) references "fobos".ordt010 );
    

alter table "fobos".actt010 add constraint (foreign key (a10_compania,
    a10_cod_depto) references "fobos".gent034 );

alter table "fobos".actt010 add constraint (foreign key (a10_compania,
    a10_locali_ori,a10_codprov) references "fobos".cxpt002 );

alter table "fobos".actt010 add constraint (foreign key (a10_moneda) 
    references "fobos".gent013 );

alter table "fobos".actt010 add constraint (foreign key (a10_compania,
    a10_responsable) references "fobos".actt003 );

alter table "fobos".actt010 add constraint (foreign key (a10_usuario) 
    references "fobos".gent005 );

alter table "fobos".actt010 add constraint (foreign key (a10_compania,
    a10_estado) references "fobos".actt006  constraint "fobos".fk_12_actt010);
    

alter table "fobos".actt001 add constraint (foreign key (a01_compania) 
    references "fobos".actt000 );

alter table "fobos".actt001 add constraint (foreign key (a01_compania,
    a01_aux_activo) references "fobos".ctbt010 );

alter table "fobos".actt001 add constraint (foreign key (a01_compania,
    a01_aux_reexpr) references "fobos".ctbt010 );

alter table "fobos".actt001 add constraint (foreign key (a01_compania,
    a01_aux_dep_act) references "fobos".ctbt010 );

alter table "fobos".actt001 add constraint (foreign key (a01_compania,
    a01_aux_dep_reex) references "fobos".ctbt010 );

alter table "fobos".actt001 add constraint (foreign key (a01_usuario) 
    references "fobos".gent005 );

alter table "fobos".actt001 add constraint (foreign key (a01_compania,
    a01_aux_pago) references "fobos".ctbt010  constraint "fobos"
    .fk_07_actt001);

alter table "fobos".actt001 add constraint (foreign key (a01_compania,
    a01_aux_iva) references "fobos".ctbt010  constraint "fobos"
    .fk_08_actt001);

alter table "fobos".actt001 add constraint (foreign key (a01_compania,
    a01_aux_venta) references "fobos".ctbt010  constraint "fobos"
    .fk_09_actt001);

alter table "fobos".actt001 add constraint (foreign key (a01_compania,
    a01_aux_gasto) references "fobos".ctbt010  constraint "fobos"
    .fk_10_actt001);

alter table "fobos".actt001 add constraint (foreign key (a01_compania,
    a01_aux_transf) references "fobos".ctbt010  constraint "fobos"
    .fk_11_actt001);

alter table "fobos".actt002 add constraint (foreign key (a02_compania,
    a02_grupo_act) references "fobos".actt001 );

alter table "fobos".actt002 add constraint (foreign key (a02_usuario) 
    references "fobos".gent005 );

alter table "fobos".rept024 add constraint (foreign key (r24_compania,
    r24_localidad,r24_numprev) references "fobos".rept023 );

alter table "fobos".rept024 add constraint (foreign key (r24_compania,
    r24_item) references "fobos".rept010 );

alter table "fobos".rept024 add constraint (foreign key (r24_compania,
    r24_linea) references "fobos".rept003 );

alter table "fobos".veht003 add constraint (foreign key (v03_compania) 
    references "fobos".veht000 );

alter table "fobos".veht003 add constraint (foreign key (v03_compania,
    v03_grupo_linea) references "fobos".gent020 );

alter table "fobos".veht003 add constraint (foreign key (v03_usuario) 
    references "fobos".gent005 );

alter table "fobos".talt021 add constraint (foreign key (t21_compania,
    t21_localidad,t21_numpre) references "fobos".talt020 );

alter table "fobos".talt021 add constraint (foreign key (t21_usuario) 
    references "fobos".gent005 );

alter table "fobos".talt021 add constraint (foreign key (t21_compania,
    t21_codtarea) references "fobos".talt007 );

alter table "fobos".cxct022 add constraint (foreign key (z22_compania,
    z22_localidad,z22_codcli) references "fobos".cxct002 );

alter table "fobos".cxct022 add constraint (foreign key (z22_compania,
    z22_localidad,z22_codcli,z22_tiptrn_elim,z22_numtrn_elim) 
    references "fobos".cxct022 );

alter table "fobos".cxct022 add constraint (foreign key (z22_tipo_trn) 
    references "fobos".cxct004 );

alter table "fobos".cxct022 add constraint (foreign key (z22_compania,
    z22_areaneg) references "fobos".gent003 );

alter table "fobos".cxct022 add constraint (foreign key (z22_moneda) 
    references "fobos".gent013 );

alter table "fobos".cxct022 add constraint (foreign key (z22_compania,
    z22_cobrador) references "fobos".cxct005 );

alter table "fobos".cxct022 add constraint (foreign key (z22_usuario) 
    references "fobos".gent005 );

alter table "fobos".cxct022 add constraint (foreign key (z22_zona_cobro) 
    references "fobos".cxct006  constraint "fobos".fk_08_cxct022);
    

alter table "fobos".rept027 add constraint (foreign key (r27_compania,
    r27_localidad,r27_numprev) references "fobos".rept023 );

alter table "fobos".rept027 add constraint (foreign key (r27_tipo) 
    references "fobos".cxct004 );

alter table "fobos".veht031 add constraint (foreign key (v31_moneda_cost) 
    references "fobos".gent013 );

alter table "fobos".veht031 add constraint (foreign key (v31_compania,
    v31_localidad,v31_cod_tran,v31_num_tran) references "fobos"
    .veht030 );

alter table "fobos".veht031 add constraint (foreign key (v31_compania,
    v31_localidad,v31_codigo_veh) references "fobos".veht022 );
    

alter table "fobos".gent023 add constraint (foreign key (g23_compania,
    g23_localidad) references "fobos".gent002 );

alter table "fobos".gent023 add constraint (foreign key (g23_modulo) 
    references "fobos".gent050 );

alter table "fobos".talt028 add constraint (foreign key (t28_compania) 
    references "fobos".talt000 );

alter table "fobos".talt028 add constraint (foreign key (t28_compania,
    t28_localidad) references "fobos".gent002 );

alter table "fobos".talt028 add constraint (foreign key (t28_compania,
    t28_localidad,t28_ot_ant) references "fobos".talt023 );

alter table "fobos".talt028 add constraint (foreign key (t28_compania,
    t28_localidad,t28_ot_nue) references "fobos".talt023 );

alter table "fobos".talt028 add constraint (foreign key (t28_usuario) 
    references "fobos".gent005 );

alter table "fobos".talt029 add constraint (foreign key (t29_compania,
    t29_localidad,t29_num_dev) references "fobos".talt028 );

alter table "fobos".talt029 add constraint (foreign key (t29_compania,
    t29_localidad,t29_oc_ant) references "fobos".ordt010 );

alter table "fobos".talt029 add constraint (foreign key (t29_compania,
    t29_localidad,t29_oc_nue) references "fobos".ordt010 );

alter table "fobos".cxct020 add constraint (foreign key (z20_compania,
    z20_localidad,z20_codcli) references "fobos".cxct002 );

alter table "fobos".cxct020 add constraint (foreign key (z20_tipo_doc) 
    references "fobos".cxct004 );

alter table "fobos".cxct020 add constraint (foreign key (z20_compania,
    z20_areaneg) references "fobos".gent003 );

alter table "fobos".cxct020 add constraint (foreign key (z20_moneda) 
    references "fobos".gent013 );

alter table "fobos".cxct020 add constraint (foreign key (z20_compania,
    z20_linea) references "fobos".gent020 );

alter table "fobos".cxct020 add constraint (foreign key (z20_usuario) 
    references "fobos".gent005 );

alter table "fobos".ordt015 add constraint (foreign key (c15_compania,
    c15_localidad,c15_numero_oc,c15_num_recep) references "fobos"
    .ordt013 );

alter table "fobos".ordt016 add constraint (foreign key (c16_compania) 
    references "fobos".ordt000 );

alter table "fobos".ordt016 add constraint (foreign key (c16_compania,
    c16_cod_depto) references "fobos".gent034 );

alter table "fobos".ordt016 add constraint (foreign key (c16_compania,
    c16_localidad,c16_codprov) references "fobos".cxpt002 );

alter table "fobos".ordt016 add constraint (foreign key (c16_moneda) 
    references "fobos".gent013 );

alter table "fobos".cxpt005 add constraint (foreign key (p05_compania) 
    references "fobos".cxpt000 );

alter table "fobos".cxpt005 add constraint (foreign key (p05_codprov) 
    references "fobos".cxpt001 );

alter table "fobos".cxpt005 add constraint (foreign key (p05_compania,
    p05_tipo_ret,p05_porcentaje,p05_codigo_sri,p05_fecha_ini_porc) 
    references "fobos".ordt003  constraint "fobos".fk_04_cxpt005);
    

alter table "fobos".cxpt030 add constraint (foreign key (p30_compania,
    p30_localidad,p30_codprov) references "fobos".cxpt002 );

alter table "fobos".cxpt030 add constraint (foreign key (p30_moneda) 
    references "fobos".gent013 );

alter table "fobos".cxpt031 add constraint (foreign key (p31_compania) 
    references "fobos".cxpt000 );

alter table "fobos".cxpt031 add constraint (foreign key (p31_compania,
    p31_localidad) references "fobos".gent002 );

alter table "fobos".cxpt031 add constraint (foreign key (p31_moneda) 
    references "fobos".gent013 );

alter table "fobos".rept030 add constraint (foreign key (r30_compania,
    r30_localidad,r30_numliq) references "fobos".rept028 );

alter table "fobos".rept030 add constraint (foreign key (r30_codrubro) 
    references "fobos".gent017 );

alter table "fobos".rept030 add constraint (foreign key (r30_moneda) 
    references "fobos".gent013 );

alter table "fobos".gent021 add constraint (foreign key (g21_usuario) 
    references "fobos".gent005 );

alter table "fobos".cajt004 add constraint (foreign key (j04_compania,
    j04_localidad,j04_codigo_caja) references "fobos".cajt002 
    );

alter table "fobos".cajt004 add constraint (foreign key (j04_usuario) 
    references "fobos".gent005 );

alter table "fobos".cajt005 add constraint (foreign key (j05_compania,
    j05_localidad,j05_codigo_caja,j05_fecha_aper,j05_secuencia) 
    references "fobos".cajt004 );

alter table "fobos".cajt005 add constraint (foreign key (j05_moneda) 
    references "fobos".gent013 );

alter table "fobos".rept040 add constraint (foreign key (r40_compania,
    r40_tipo_comp,r40_num_comp) references "fobos".ctbt012  constraint 
    "fobos".fk_02_rept040);

alter table "fobos".talt050 add constraint (foreign key (t50_compania,
    t50_localidad,t50_orden) references "fobos".talt023  constraint 
    "fobos".fk_01_talt050);

alter table "fobos".talt050 add constraint (foreign key (t50_compania,
    t50_tipo_comp,t50_num_comp) references "fobos".ctbt012  constraint 
    "fobos".fk_03_talt050);

alter table "fobos".talt030 add constraint (foreign key (t30_compania) 
    references "fobos".talt000 );

alter table "fobos".talt030 add constraint (foreign key (t30_compania,
    t30_localidad) references "fobos".gent002 );

alter table "fobos".talt030 add constraint (foreign key (t30_compania,
    t30_localidad,t30_num_ot) references "fobos".talt023 );

alter table "fobos".talt030 add constraint (foreign key (t30_moneda) 
    references "fobos".gent013 );

alter table "fobos".talt030 add constraint (foreign key (t30_usuario) 
    references "fobos".gent005 );

alter table "fobos".talt031 add constraint (foreign key (t31_compania,
    t31_localidad,t31_num_gasto) references "fobos".talt030 );
    

alter table "fobos".talt031 add constraint (foreign key (t31_moneda) 
    references "fobos".gent013 );

alter table "fobos".talt032 add constraint (foreign key (t32_compania,
    t32_localidad,t32_num_gasto) references "fobos".talt030 );
    

alter table "fobos".talt032 add constraint (foreign key (t32_compania,
    t32_mecanico) references "fobos".talt003 );

alter table "fobos".talt033 add constraint (foreign key (t33_compania,
    t33_localidad,t33_num_gasto) references "fobos".talt030 );
    

alter table "fobos".rept034 add constraint (foreign key (r34_compania,
    r34_localidad,r34_cod_tran,r34_num_tran) references "fobos"
    .rept019 );

alter table "fobos".rept035 add constraint (foreign key (r35_compania,
    r35_localidad,r35_bodega,r35_num_ord_des) references "fobos"
    .rept034 );

alter table "fobos".rept035 add constraint (foreign key (r35_compania,
    r35_item) references "fobos".rept010 );

alter table "fobos".rept036 add constraint (foreign key (r36_compania,
    r36_localidad,r36_bodega,r36_num_ord_des) references "fobos"
    .rept034 );

alter table "fobos".rept037 add constraint (foreign key (r37_compania,
    r37_localidad,r37_bodega,r37_num_entrega) references "fobos"
    .rept036 );

alter table "fobos".rept037 add constraint (foreign key (r37_compania,
    r37_item) references "fobos".rept010 );

alter table "fobos".ctbt032 add constraint (foreign key (b32_compania,
    b32_cuenta) references "fobos".ctbt010 );

alter table "fobos".ctbt032 add constraint (foreign key (b32_compania,
    b32_num_concil) references "fobos".ctbt030 );

alter table "fobos".rept074 add constraint (foreign key (r74_compania) 
    references "fobos".rept000 );

alter table "fobos".rept074 add constraint (foreign key (r74_usuario) 
    references "fobos".gent005 );

alter table "fobos".rept075 add constraint (foreign key (r75_compania) 
    references "fobos".rept000 );

alter table "fobos".rept075 add constraint (foreign key (r75_compania,
    r75_item) references "fobos".rept010 );

alter table "fobos".rept075 add constraint (foreign key (r75_usuario) 
    references "fobos".gent005 );

alter table "fobos".rept070 add constraint (foreign key (r70_compania,
    r70_linea) references "fobos".rept003 );

alter table "fobos".rept070 add constraint (foreign key (r70_usuario) 
    references "fobos".gent005 );

alter table "fobos".rept073 add constraint (foreign key (r73_usuario) 
    references "fobos".gent005 );

alter table "fobos".rept010 add constraint (foreign key (r10_compania,
    r10_cod_util) references "fobos".rept077 );

alter table "fobos".rept010 add constraint (foreign key (r10_compania) 
    references "fobos".rept000 );

alter table "fobos".rept010 add constraint (foreign key (r10_tipo) 
    references "fobos".rept006 );

alter table "fobos".rept010 add constraint (foreign key (r10_uni_med) 
    references "fobos".rept005 );

alter table "fobos".rept010 add constraint (foreign key (r10_compania,
    r10_linea) references "fobos".rept003 );

alter table "fobos".rept010 add constraint (foreign key (r10_compania,
    r10_rotacion) references "fobos".rept004 );

alter table "fobos".rept010 add constraint (foreign key (r10_monfob) 
    references "fobos".gent013 );

alter table "fobos".rept010 add constraint (foreign key (r10_usuario) 
    references "fobos".gent005 );

alter table "fobos".rept010 add constraint (foreign key (r10_compania,
    r10_linea,r10_sub_linea) references "fobos".rept070 );

alter table "fobos".rept010 add constraint (foreign key (r10_compania,
    r10_linea,r10_sub_linea,r10_cod_grupo) references "fobos".rept071 
    );

alter table "fobos".rept010 add constraint (foreign key (r10_compania,
    r10_linea,r10_sub_linea,r10_cod_grupo,r10_cod_clase) references 
    "fobos".rept072 );

alter table "fobos".rept010 add constraint (foreign key (r10_partida) 
    references "fobos".gent016 );

alter table "fobos".rept076 add constraint (foreign key (r76_compania) 
    references "fobos".rept000 );

alter table "fobos".rept076 add constraint (foreign key (r76_compania,
    r76_bodega) references "fobos".rept002 );

alter table "fobos".rept076 add constraint (foreign key (r76_compania,
    r76_item) references "fobos".rept010 );

alter table "fobos".rept076 add constraint (foreign key (r76_usuario) 
    references "fobos".gent005 );

alter table "fobos".rept078 add constraint (foreign key (r78_compania) 
    references "fobos".rept000 );

alter table "fobos".rept078 add constraint (foreign key (r78_compania,
    r78_bodega) references "fobos".rept002 );

alter table "fobos".rept078 add constraint (foreign key (r78_compania,
    r78_item) references "fobos".rept010 );

alter table "fobos".rept078 add constraint (foreign key (r78_usuario) 
    references "fobos".gent005 );

alter table "fobos".rept077 add constraint (foreign key (r77_compania) 
    references "fobos".rept000 );

alter table "fobos".rept077 add constraint (foreign key (r77_usuario) 
    references "fobos".gent005 );

alter table "fobos".rept072 add constraint (foreign key (r72_compania,
    r72_linea,r72_sub_linea,r72_cod_grupo) references "fobos".rept071 
    );

alter table "fobos".rept072 add constraint (foreign key (r72_usuario) 
    references "fobos".gent005 );

alter table "fobos".rept071 add constraint (foreign key (r71_compania,
    r71_linea,r71_sub_linea) references "fobos".rept070 );

alter table "fobos".rept071 add constraint (foreign key (r71_usuario) 
    references "fobos".gent005 );

alter table "fobos".ordt011 add constraint (foreign key (c11_compania,
    c11_localidad,c11_numero_oc) references "fobos".ordt010 );
    

alter table "fobos".ordt014 add constraint (foreign key (c14_compania,
    c14_localidad,c14_numero_oc,c14_num_recep) references "fobos"
    .ordt013 );

alter table "fobos".rept017 add constraint (foreign key (r17_compania,
    r17_localidad,r17_pedido) references "fobos".rept016 );

alter table "fobos".rept017 add constraint (foreign key (r17_compania,
    r17_item) references "fobos".rept010 );

alter table "fobos".rept017 add constraint (foreign key (r17_compania,
    r17_linea) references "fobos".rept003 );

alter table "fobos".rept017 add constraint (foreign key (r17_compania,
    r17_rotacion) references "fobos".rept004 );

alter table "fobos".rept017 add constraint (foreign key (r17_partida) 
    references "fobos".gent016 );

alter table "fobos".rept028 add constraint (foreign key (r28_compania) 
    references "fobos".rept000 );

alter table "fobos".rept028 add constraint (foreign key (r28_compania,
    r28_localidad) references "fobos".gent002 );

alter table "fobos".rept028 add constraint (foreign key (r28_moneda) 
    references "fobos".gent013 );

alter table "fobos".rept028 add constraint (foreign key (r28_usuario) 
    references "fobos".gent005 );

alter table "fobos".rept028 add constraint (foreign key (r28_compania,
    r28_bodega) references "fobos".rept002 );

alter table "fobos".ctbt012 add constraint (foreign key (b12_compania,
    b12_tip_reversa,b12_num_reversa) references "fobos".ctbt012 
    );

alter table "fobos".ctbt012 add constraint (foreign key (b12_compania,
    b12_tipo_comp) references "fobos".ctbt003 );

alter table "fobos".ctbt012 add constraint (foreign key (b12_compania,
    b12_subtipo) references "fobos".ctbt004 );

alter table "fobos".ctbt012 add constraint (foreign key (b12_moneda) 
    references "fobos".gent013 );

alter table "fobos".ctbt012 add constraint (foreign key (b12_usuario) 
    references "fobos".gent005 );

alter table "fobos".gent037 add constraint (foreign key (g37_compania) 
    references "fobos".gent001 );

alter table "fobos".gent037 add constraint (foreign key (g37_compania,
    g37_localidad) references "fobos".gent002 );

alter table "fobos".gent037 add constraint (foreign key (g37_usuario) 
    references "fobos".gent005 );

alter table "fobos".tr_cxct022 add constraint (foreign key (z22_zona_cobro) 
    references "fobos".cxct006  constraint "fobos".fk_08_tr_cxct022);
    

alter table "fobos".te_021_07052003 add constraint (foreign key 
    (z21_compania,z21_localidad,z21_codcli) references "fobos"
    .cxct002 );

alter table "fobos".te_021_07052003 add constraint (foreign key 
    (z21_tipo_doc) references "fobos".cxct004 );

alter table "fobos".te_021_07052003 add constraint (foreign key 
    (z21_compania,z21_areaneg) references "fobos".gent003 );

alter table "fobos".te_021_07052003 add constraint (foreign key 
    (z21_moneda) references "fobos".gent013 );

alter table "fobos".te_021_07052003 add constraint (foreign key 
    (z21_usuario) references "fobos".gent005 );

alter table "fobos".te_gent016 add constraint (foreign key (g16_usuario) 
    references "fobos".gent005 );

alter table "fobos".gent038 add constraint (foreign key (g38_usuario) 
    references "fobos".gent005 );

alter table "fobos".gent016 add constraint (foreign key (g16_usuario) 
    references "fobos".gent005 );

alter table "fobos".gent016 add constraint (foreign key (g16_capitulo) 
    references "fobos".gent038 );

alter table "fobos".te_actt010 add constraint (foreign key (a10_compania) 
    references "fobos".actt000 );

alter table "fobos".te_actt010 add constraint (foreign key (a10_compania,
    a10_grupo_act) references "fobos".actt001 );

alter table "fobos".te_actt010 add constraint (foreign key (a10_compania,
    a10_tipo_act) references "fobos".actt002 );

alter table "fobos".te_actt010 add constraint (foreign key (a10_compania,
    a10_locali_ori) references "fobos".gent002 );

alter table "fobos".te_actt010 add constraint (foreign key (a10_compania,
    a10_localidad) references "fobos".gent002 );

alter table "fobos".te_actt010 add constraint (foreign key (a10_compania,
    a10_locali_ori,a10_numero_oc) references "fobos".ordt010 );
    

alter table "fobos".te_actt010 add constraint (foreign key (a10_compania,
    a10_cod_depto) references "fobos".gent034 );

alter table "fobos".te_actt010 add constraint (foreign key (a10_compania,
    a10_locali_ori,a10_codprov) references "fobos".cxpt002 );

alter table "fobos".te_actt010 add constraint (foreign key (a10_moneda) 
    references "fobos".gent013 );

alter table "fobos".te_actt010 add constraint (foreign key (a10_compania,
    a10_responsable) references "fobos".actt003 );

alter table "fobos".te_actt010 add constraint (foreign key (a10_usuario) 
    references "fobos".gent005 );

alter table "fobos".rept083 add constraint (foreign key (r83_compania) 
    references "fobos".rept000 );

alter table "fobos".rept083 add constraint (foreign key (r83_compania,
    r83_item) references "fobos".rept010 );

alter table "fobos".rolt047 add constraint (foreign key (n47_compania,
    n47_proceso,n47_cod_trab,n47_periodo_ini,n47_periodo_fin) 
    references "fobos".rolt039  constraint "fobos".fk_01_rolt047);
    

alter table "fobos".rolt047 add constraint (foreign key (n47_proceso) 
    references "fobos".rolt003  constraint "fobos".fk_02_rolt047);
    

alter table "fobos".rolt047 add constraint (foreign key (n47_cod_liqrol) 
    references "fobos".rolt003  constraint "fobos".fk_04_rolt047);
    

alter table "fobos".rolt047 add constraint (foreign key (n47_usuario) 
    references "fobos".gent005  constraint "fobos".fk_05_rolt047);
    

alter table "fobos".rolt048 add constraint (foreign key (n48_compania) 
    references "fobos".rolt001 );

alter table "fobos".rolt048 add constraint (foreign key (n48_compania,
    n48_cod_trab) references "fobos".rolt030 );

alter table "fobos".rolt048 add constraint (foreign key (n48_moneda) 
    references "fobos".gent013 );

alter table "fobos".rolt048 add constraint (foreign key (n48_compania,
    n48_bco_empresa,n48_cta_empresa) references "fobos".gent009 
    );

alter table "fobos".rolt048 add constraint (foreign key (n48_usuario) 
    references "fobos".gent005 );

alter table "fobos".rolt048 add constraint (foreign key (n48_compania,
    n48_tipo_comp,n48_num_comp) references "fobos".ctbt012  constraint 
    "fobos".fk_06_rolt048);

alter table "fobos".rolt048 add constraint (foreign key (n48_proceso) 
    references "fobos".rolt003  constraint "fobos".fk_07_rolt048);
    

alter table "fobos".rolt048 add constraint (foreign key (n48_cod_liqrol) 
    references "fobos".rolt003  constraint "fobos".fk_08_rolt048);
    

alter table "fobos".rept082 add constraint (foreign key (r82_compania,
    r82_localidad,r82_pedido) references "fobos".rept081 );

alter table "fobos".rept082 add constraint (foreign key (r82_compania) 
    references "fobos".rept000 );

alter table "fobos".rept082 add constraint (foreign key (r82_compania,
    r82_localidad) references "fobos".gent002 );

alter table "fobos".rept082 add constraint (foreign key (r82_cod_unid) 
    references "fobos".rept005 );

alter table "fobos".rept082 add constraint (foreign key (r82_compania,
    r82_item) references "fobos".rept010 );

alter table "fobos".rept082 add constraint (foreign key (r82_partida) 
    references "fobos".gent016 );

alter table "fobos".rept084 add constraint (foreign key (r84_compania) 
    references "fobos".rept000 );

alter table "fobos".rept084 add constraint (foreign key (r84_usuario) 
    references "fobos".gent005 );

alter table "fobos".actt013 add constraint (foreign key (a13_compania,
    a13_codigo_bien) references "fobos".actt010 );

alter table "fobos".rolt060 add constraint (foreign key (n60_banco) 
    references "fobos".gent008  constraint "fobos".fk_02_rolt060);
    

alter table "fobos".rolt060 add constraint (foreign key (n60_usuario) 
    references "fobos".gent005 );

alter table "fobos".rolt060 add constraint (foreign key (n60_compania,
    n60_rub_aporte) references "fobos".rolt009 );

alter table "fobos".rolt061 add constraint (foreign key (n61_compania) 
    references "fobos".rolt001 );

alter table "fobos".rolt061 add constraint (foreign key (n61_compania,
    n61_cod_trab) references "fobos".rolt030 );

alter table "fobos".rolt061 add constraint (foreign key (n61_usuario) 
    references "fobos".gent005 );

alter table "fobos".rolt062 add constraint (foreign key (n62_compania) 
    references "fobos".rolt001 );

alter table "fobos".rolt062 add constraint (foreign key (n62_usuario) 
    references "fobos".gent005 );

alter table "fobos".rolt062 add constraint (foreign key (n62_compania,
    n62_cod_rubro) references "fobos".rolt009 );

alter table "fobos".rolt063 add constraint (foreign key (n63_compania,
    n63_cod_almacen) references "fobos".rolt062 );

alter table "fobos".rolt063 add constraint (foreign key (n63_cod_liqrol) 
    references "fobos".rolt003 );

alter table "fobos".rolt063 add constraint (foreign key (n63_compania,
    n63_cod_trab) references "fobos".rolt030 );

alter table "fobos".rolt065 add constraint (foreign key (n65_compania,
    n65_num_prest) references "fobos".rolt064 );

alter table "fobos".rolt065 add constraint (foreign key (n65_cod_liqrol) 
    references "fobos".rolt003 );

alter table "fobos".rolt066 add constraint (foreign key (n66_usuario) 
    references "fobos".gent005 );

alter table "fobos".rolt067 add constraint (foreign key (n67_usuario) 
    references "fobos".gent005 );

alter table "fobos".rolt068 add constraint (foreign key (n68_banco) 
    references "fobos".gent008  constraint "fobos".fk_06_rolt068);
    

alter table "fobos".rolt068 add constraint (foreign key (n68_cod_liqrol) 
    references "fobos".rolt003 );

alter table "fobos".rolt068 add constraint (foreign key (n68_compania,
    n68_cod_trab) references "fobos".rolt030 );

alter table "fobos".rolt068 add constraint (foreign key (n68_compania,
    n68_num_prest) references "fobos".rolt064 );

alter table "fobos".rolt068 add constraint (foreign key (n68_cod_rubro) 
    references "fobos".rolt067 );

alter table "fobos".rolt068 add constraint (foreign key (n68_compania) 
    references "fobos".rolt001 );

alter table "fobos".rolt068 add constraint (foreign key (n68_usuario) 
    references "fobos".gent005 );

alter table "fobos".rolt069 add constraint (foreign key (n69_banco) 
    references "fobos".gent008  constraint "fobos".fk_02_rolt069);
    

alter table "fobos".rolt069 add constraint (foreign key (n69_compania) 
    references "fobos".rolt001 );

alter table "fobos".rolt050 add constraint (foreign key (n50_compania,
    n50_cod_depto) references "fobos".gent034 );

alter table "fobos".rolt050 add constraint (foreign key (n50_cod_rubro) 
    references "fobos".rolt006 );

alter table "fobos".rolt050 add constraint (foreign key (n50_compania) 
    references "fobos".rolt001 );

alter table "fobos".rolt050 add constraint (foreign key (n50_compania,
    n50_aux_cont) references "fobos".ctbt010 );

alter table "fobos".rolt051 add constraint (foreign key (n51_cod_rubro) 
    references "fobos".rolt006 );

alter table "fobos".rolt051 add constraint (foreign key (n51_compania,
    n51_aux_cont) references "fobos".ctbt010 );

alter table "fobos".rolt051 add constraint (foreign key (n51_compania) 
    references "fobos".rolt001 );

alter table "fobos".rolt052 add constraint (foreign key (n52_compania) 
    references "fobos".rolt001 );

alter table "fobos".rolt052 add constraint (foreign key (n52_cod_rubro) 
    references "fobos".rolt006 );

alter table "fobos".rolt052 add constraint (foreign key (n52_compania,
    n52_cod_trab) references "fobos".rolt030 );

alter table "fobos".rolt052 add constraint (foreign key (n52_compania,
    n52_aux_cont) references "fobos".ctbt010 );

alter table "fobos".rolt053 add constraint (foreign key (n53_compania,
    n53_cod_liqrol) references "fobos".rolt005 );

alter table "fobos".rolt053 add constraint (foreign key (n53_compania,
    n53_tipo_comp,n53_num_comp) references "fobos".ctbt012 );

alter table "fobos".rolt054 add constraint (foreign key (n54_compania,
    n54_aux_cont) references "fobos".ctbt010 );

alter table "fobos".rolt080 add constraint (foreign key (n80_compania) 
    references "fobos".rolt001 );

alter table "fobos".rolt080 add constraint (foreign key (n80_compania,
    n80_cod_trab) references "fobos".rolt030 );

alter table "fobos".rolt080 add constraint (foreign key (n80_moneda) 
    references "fobos".gent013 );

alter table "fobos".rolt081 add constraint (foreign key (n81_compania) 
    references "fobos".rolt001 );

alter table "fobos".rolt081 add constraint (foreign key (n81_usuario) 
    references "fobos".gent005 );

alter table "fobos".rolt081 add constraint (foreign key (n81_cod_liqrol) 
    references "fobos".rolt003 );

alter table "fobos".rolt081 add constraint (foreign key (n81_moneda) 
    references "fobos".gent013 );

alter table "fobos".rolt082 add constraint (foreign key (n82_compania) 
    references "fobos".rolt001 );

alter table "fobos".rolt082 add constraint (foreign key (n82_compania,
    n82_cod_trab) references "fobos".rolt030 );

alter table "fobos".rolt082 add constraint (foreign key (n82_compania,
    n82_banco,n82_numero_cta) references "fobos".gent009 );

alter table "fobos".rolt083 add constraint (foreign key (n83_compania) 
    references "fobos".rolt001 );

alter table "fobos".rolt083 add constraint (foreign key (n83_compania,
    n83_cod_trab) references "fobos".rolt030 );

alter table "fobos".rolt083 add constraint (foreign key (n83_compania,
    n83_num_poliza) references "fobos".rolt081 );

alter table "fobos".rolt083 add constraint (foreign key (n83_moneda) 
    references "fobos".gent013 );

alter table "fobos".te_stofis add constraint (foreign key (te_compania) 
    references "fobos".rept000 );

alter table "fobos".te_stofis add constraint (foreign key (te_compania,
    te_localidad) references "fobos".gent002 );

alter table "fobos".te_stofis add constraint (foreign key (te_compania,
    te_bodega) references "fobos".rept002 );

alter table "fobos".te_stofis add constraint (foreign key (te_compania,
    te_item) references "fobos".rept010 );

alter table "fobos".te_stofis add constraint (foreign key (te_usuario) 
    references "fobos".gent005 );

alter table "fobos".resp_exis add constraint (foreign key (r11_compania) 
    references "fobos".rept000 );

alter table "fobos".te_boddan add constraint (foreign key (te_compania) 
    references "fobos".rept000 );

alter table "fobos".te_boddan add constraint (foreign key (te_compania,
    te_localidad) references "fobos".gent002 );

alter table "fobos".te_boddan add constraint (foreign key (te_compania,
    te_bodega) references "fobos".rept002 );

alter table "fobos".te_boddan add constraint (foreign key (te_compania,
    te_bodega_dan) references "fobos".rept002 );

alter table "fobos".rolt039 add constraint (foreign key (n39_proceso) 
    references "fobos".rolt003  constraint "fobos".fk_05_rolt039);
    

alter table "fobos".rolt039 add constraint (foreign key (n39_compania,
    n39_cod_trab) references "fobos".rolt030 );

alter table "fobos".rolt039 add constraint (foreign key (n39_compania,
    n39_cod_depto) references "fobos".gent034 );

alter table "fobos".rolt039 add constraint (foreign key (n39_moneda) 
    references "fobos".gent013 );

alter table "fobos".rolt039 add constraint (foreign key (n39_usuario) 
    references "fobos".gent005 );

alter table "fobos".rolt039 add constraint (foreign key (n39_bco_empresa) 
    references "fobos".gent008  constraint "fobos".fk_06_rolt039);
    

alter table "fobos".rolt039 add constraint (foreign key (n39_compania,
    n39_bco_empresa,n39_cta_empresa) references "fobos".gent009 
     constraint "fobos".fk_07_rolt039);

alter table "fobos".rolt040 add constraint (foreign key (n40_compania,
    n40_cod_rubro) references "fobos".rolt009 );

alter table "fobos".rolt040 add constraint (foreign key (n40_compania,
    n40_num_prest) references "fobos".rolt045 );

alter table "fobos".rolt040 add constraint (foreign key (n40_compania,
    n40_proceso,n40_cod_trab,n40_periodo_ini,n40_periodo_fin) 
    references "fobos".rolt039  constraint "fobos".fk_01_rolt040);
    

alter table "fobos".rolt040 add constraint (foreign key (n40_proceso) 
    references "fobos".rolt003  constraint "fobos".fk_04_rolt040);
    

alter table "fobos".rolt055 add constraint (foreign key (n55_compania,
    n55_cod_trab) references "fobos".rolt030 );

alter table "fobos".rolt084 add constraint (foreign key (n84_proceso) 
    references "fobos".rolt003  constraint "fobos".fk_04_rolt084);
    

alter table "fobos".rolt084 add constraint (foreign key (n84_usuario) 
    references "fobos".gent005  constraint "fobos".fk_05_rolt084);
    

alter table "fobos".rolt084 add constraint (foreign key (n84_usu_modifi) 
    references "fobos".gent005  constraint "fobos".fk_06_rolt084);
    

alter table "fobos".rolt084 add constraint (foreign key (n84_usu_elimin) 
    references "fobos".gent005  constraint "fobos".fk_07_rolt084);
    

alter table "fobos".rolt084 add constraint (foreign key (n84_compania) 
    references "fobos".rolt001 );

alter table "fobos".rolt084 add constraint (foreign key (n84_compania,
    n84_cod_trab) references "fobos".rolt030 );

alter table "fobos".rolt084 add constraint (foreign key (n84_moneda) 
    references "fobos".gent013 );

alter table "fobos".rolt084 add constraint (foreign key (n84_usu_cierre) 
    references "fobos".gent005  constraint "fobos".fk_08_rolt084);
    

alter table "fobos".rept092 add constraint (foreign key (r92_compania,
    r92_localidad,r92_cod_tran,r92_num_tran) references "fobos"
    .rept091 );

alter table "fobos".rolt041 add constraint (foreign key (n41_compania) 
    references "fobos".rolt000  constraint "fobos".fk_01_rolt041);
    

alter table "fobos".rolt041 add constraint (foreign key (n41_proceso) 
    references "fobos".rolt003  constraint "fobos".fk_02_rolt041);
    

alter table "fobos".rolt041 add constraint (foreign key (n41_moneda) 
    references "fobos".gent013  constraint "fobos".fk_03_rolt041);
    

alter table "fobos".rolt041 add constraint (foreign key (n41_usuario) 
    references "fobos".gent005  constraint "fobos".fk_04_rolt041);
    

alter table "fobos".rept086 add constraint (foreign key (r86_compania,
    r86_codigo) references "fobos".rept085 );

alter table "fobos".rolt064 add constraint (foreign key (n64_compania,
    n64_cod_trab) references "fobos".rolt030 );

alter table "fobos".rolt064 add constraint (foreign key (n64_compania,
    n64_cod_rubro) references "fobos".rolt009 );

alter table "fobos".rolt064 add constraint (foreign key (n64_moneda) 
    references "fobos".gent013 );

alter table "fobos".rolt064 add constraint (foreign key (n64_usuario) 
    references "fobos".gent005 );

alter table "fobos".gent039 add constraint (foreign key (g39_compania) 
    references "fobos".gent001 );

alter table "fobos".gent039 add constraint (foreign key (g39_compania,
    g39_localidad) references "fobos".gent002 );

alter table "fobos".gent039 add constraint (foreign key (g39_usuario) 
    references "fobos".gent005 );

alter table "fobos".rept089 add constraint (foreign key (r89_compania) 
    references "fobos".rept000 );

alter table "fobos".rept089 add constraint (foreign key (r89_compania,
    r89_localidad) references "fobos".gent002 );

alter table "fobos".rept089 add constraint (foreign key (r89_usuario) 
    references "fobos".gent005 );

alter table "fobos".rept089 add constraint (foreign key (r89_usu_modifi) 
    references "fobos".gent005 );

alter table "fobos".rept093 add constraint (foreign key (r93_usuario) 
    references "fobos".gent005 );

alter table "fobos".ctbt050 add constraint (foreign key (b50_usuario) 
    references "fobos".gent005 );

alter table "fobos".gent057 add constraint (foreign key (g57_modulo,
    g57_proceso) references "fobos".gent054 );

alter table "fobos".gent057 add constraint (foreign key (g57_compania) 
    references "fobos".gent001 );

alter table "fobos".gent057 add constraint (foreign key (g57_user) 
    references "fobos".gent005 );

alter table "fobos".gent057 add constraint (foreign key (g57_usuario) 
    references "fobos".gent005 );

alter table "fobos".actt014 add constraint (foreign key (a14_compania) 
    references "fobos".actt000 );

alter table "fobos".actt014 add constraint (foreign key (a14_compania,
    a14_grupo_act) references "fobos".actt001 );

alter table "fobos".actt014 add constraint (foreign key (a14_compania,
    a14_tipo_act) references "fobos".actt002 );

alter table "fobos".actt014 add constraint (foreign key (a14_compania,
    a14_locali_ori) references "fobos".gent002 );

alter table "fobos".actt014 add constraint (foreign key (a14_compania,
    a14_localidad) references "fobos".gent002 );

alter table "fobos".actt014 add constraint (foreign key (a14_compania,
    a14_cod_depto) references "fobos".gent034 );

alter table "fobos".actt014 add constraint (foreign key (a14_moneda) 
    references "fobos".gent013 );

alter table "fobos".actt014 add constraint (foreign key (a14_compania,
    a14_tipo_comp,a14_num_comp) references "fobos".ctbt012 );

alter table "fobos".actt014 add constraint (foreign key (a14_usuario) 
    references "fobos".gent005 );

alter table "fobos".cxct001 add constraint (foreign key (z01_pais) 
    references "fobos".gent030 );

alter table "fobos".cxct001 add constraint (foreign key (z01_ciudad) 
    references "fobos".gent031 );

alter table "fobos".cxct001 add constraint (foreign key (z01_usuario) 
    references "fobos".gent005 );

alter table "fobos".cajt010 add constraint (foreign key (j10_compania,
    j10_localidad,j10_codcli) references "fobos".cxct002 );

alter table "fobos".cajt010 add constraint (foreign key (j10_banco) 
    references "fobos".gent008  constraint "fobos".fk_07_cajt010);
    

alter table "fobos".cajt010 add constraint (foreign key (j10_compania) 
    references "fobos".cajt000 );

alter table "fobos".cajt010 add constraint (foreign key (j10_compania,
    j10_localidad) references "fobos".gent002 );

alter table "fobos".cajt010 add constraint (foreign key (j10_compania,
    j10_areaneg) references "fobos".gent003 );

alter table "fobos".cajt010 add constraint (foreign key (j10_moneda) 
    references "fobos".gent013 );

alter table "fobos".cajt010 add constraint (foreign key (j10_compania,
    j10_localidad,j10_codigo_caja) references "fobos".cajt002 
    );

alter table "fobos".cajt010 add constraint (foreign key (j10_compania,
    j10_tip_contable,j10_num_contable) references "fobos".ctbt012 
    );

alter table "fobos".cajt010 add constraint (foreign key (j10_usuario) 
    references "fobos".gent005 );

alter table "fobos".rept021 add constraint (foreign key (r21_compania,
    r21_localidad,r21_codcli) references "fobos".cxct002 );

alter table "fobos".rept021 add constraint (foreign key (r21_compania,
    r21_grupo_linea) references "fobos".gent020 );

alter table "fobos".rept021 add constraint (foreign key (r21_compania,
    r21_bodega) references "fobos".rept002 );

alter table "fobos".rept021 add constraint (foreign key (r21_compania) 
    references "fobos".rept000 );

alter table "fobos".rept021 add constraint (foreign key (r21_compania,
    r21_localidad) references "fobos".gent002 );

alter table "fobos".rept021 add constraint (foreign key (r21_compania,
    r21_vendedor) references "fobos".rept001 );

alter table "fobos".rept021 add constraint (foreign key (r21_moneda) 
    references "fobos".gent013 );

alter table "fobos".rept021 add constraint (foreign key (r21_usuario) 
    references "fobos".gent005 );

alter table "fobos".rept021 add constraint (foreign key (r21_compania,
    r21_localidad,r21_num_ot) references "fobos".talt023 );

alter table "fobos".rept021 add constraint (foreign key (r21_compania,
    r21_localidad,r21_num_presup) references "fobos".talt020 );
    

alter table "fobos".rept021 add constraint (foreign key (r21_compania,
    r21_localidad,r21_cod_tran,r21_num_tran) references "fobos"
    .rept019  constraint "fobos".fk_13_rept021);

alter table "fobos".rept021 add constraint (foreign key (r21_usr_tr_fa) 
    references "fobos".gent005  constraint "fobos".fk_11_rept021);
    

alter table "fobos".rept023 add constraint (foreign key (r23_compania,
    r23_localidad,r23_codcli) references "fobos".cxct002 );

alter table "fobos".rept023 add constraint (foreign key (r23_compania) 
    references "fobos".rept000 );

alter table "fobos".rept023 add constraint (foreign key (r23_compania,
    r23_localidad) references "fobos".gent002 );

alter table "fobos".rept023 add constraint (foreign key (r23_compania,
    r23_vendedor) references "fobos".rept001 );

alter table "fobos".rept023 add constraint (foreign key (r23_compania,
    r23_bodega) references "fobos".rept002 );

alter table "fobos".rept023 add constraint (foreign key (r23_moneda) 
    references "fobos".gent013 );

alter table "fobos".rept023 add constraint (foreign key (r23_usuario) 
    references "fobos".gent005 );

alter table "fobos".rept023 add constraint (foreign key (r23_compania,
    r23_localidad,r23_cod_tran,r23_num_tran) references "fobos"
    .rept019 );

alter table "fobos".rept023 add constraint (foreign key (r23_compania,
    r23_grupo_linea) references "fobos".gent020 );

alter table "fobos".rept023 add constraint (foreign key (r23_compania,
    r23_localidad,r23_num_ot) references "fobos".talt023 );

alter table "fobos".rept088 add constraint (foreign key (r88_compania,
    r88_localidad,r88_ord_trabajo) references "fobos".talt060 
    );

alter table "fobos".talt020 add constraint (foreign key (t20_compania) 
    references "fobos".talt000 );

alter table "fobos".talt020 add constraint (foreign key (t20_compania,
    t20_localidad) references "fobos".gent002 );

alter table "fobos".talt020 add constraint (foreign key (t20_moneda) 
    references "fobos".gent013 );

alter table "fobos".talt020 add constraint (foreign key (t20_usuario) 
    references "fobos".gent005 );

alter table "fobos".talt020 add constraint (foreign key (t20_usu_modifi) 
    references "fobos".gent005  constraint "fobos".fk_06_talt020);
    

alter table "fobos".talt020 add constraint (foreign key (t20_usu_elimin) 
    references "fobos".gent005  constraint "fobos".fk_07_talt020);
    

alter table "fobos".talt023 add constraint (foreign key (t23_compania,
    t23_localidad,t23_cod_cliente) references "fobos".cxct002 
    );

alter table "fobos".talt023 add constraint (foreign key (t23_compania) 
    references "fobos".talt000 );

alter table "fobos".talt023 add constraint (foreign key (t23_compania,
    t23_localidad) references "fobos".gent002 );

alter table "fobos".talt023 add constraint (foreign key (t23_compania,
    t23_tipo_ot) references "fobos".talt005 );

alter table "fobos".talt023 add constraint (foreign key (t23_compania,
    t23_tipo_ot,t23_subtipo_ot) references "fobos".talt006 );

alter table "fobos".talt023 add constraint (foreign key (t23_compania,
    t23_localidad,t23_codcli_est) references "fobos".cxct002 );
    

alter table "fobos".talt023 add constraint (foreign key (t23_compania,
    t23_seccion) references "fobos".talt002 );

alter table "fobos".talt023 add constraint (foreign key (t23_compania,
    t23_cod_asesor) references "fobos".talt003 );

alter table "fobos".talt023 add constraint (foreign key (t23_compania,
    t23_cod_mecani) references "fobos".talt003 );

alter table "fobos".talt023 add constraint (foreign key (t23_moneda) 
    references "fobos".gent013 );

alter table "fobos".talt023 add constraint (foreign key (t23_compania,
    t23_modelo) references "fobos".talt004 );

alter table "fobos".talt023 add constraint (foreign key (t23_usuario) 
    references "fobos".gent005 );

alter table "fobos".talt023 add constraint (foreign key (t23_compania,
    t23_localidad,t23_numpre) references "fobos".talt020 );

alter table "fobos".talt023 add constraint (foreign key (t23_usu_modifi) 
    references "fobos".gent005  constraint "fobos".fk_15_talt023);
    

alter table "fobos".talt023 add constraint (foreign key (t23_usu_elimin) 
    references "fobos".gent005  constraint "fobos".fk_16_talt023);
    

alter table "fobos".cxpt001 add constraint (foreign key (p01_pais) 
    references "fobos".gent030 );

alter table "fobos".cxpt001 add constraint (foreign key (p01_ciudad) 
    references "fobos".gent031 );

alter table "fobos".cxpt001 add constraint (foreign key (p01_usuario) 
    references "fobos".gent005 );

alter table "fobos".rept081 add constraint (foreign key (r81_compania) 
    references "fobos".rept000 );

alter table "fobos".rept081 add constraint (foreign key (r81_compania,
    r81_localidad) references "fobos".gent002 );

alter table "fobos".rept081 add constraint (foreign key (r81_compania,
    r81_localidad,r81_cod_prov) references "fobos".cxpt002 );

alter table "fobos".rept081 add constraint (foreign key (r81_moneda_base) 
    references "fobos".gent013 );

alter table "fobos".rept081 add constraint (foreign key (r81_usuario) 
    references "fobos".gent005 );

alter table "fobos".rept095 add constraint (foreign key (r95_usu_elim) 
    references "fobos".gent005  constraint "fobos".fk_02_rept095);
    

alter table "fobos".rept095 add constraint (foreign key (r95_usuario) 
    references "fobos".gent005  constraint "fobos".fk_01_rept095);
    

alter table "fobos".rept095 add constraint (foreign key (r95_compania,
    r95_localidad,r95_cod_zona) references "fobos".rept108  constraint 
    "fobos".fk_04_rept095);

alter table "fobos".rept095 add constraint (foreign key (r95_compania,
    r95_localidad,r95_cod_zona,r95_cod_subzona) references "fobos"
    .rept109  constraint "fobos".fk_05_rept095);

alter table "fobos".rept096 add constraint (foreign key (r96_compania,
    r96_localidad,r96_guia_remision) references "fobos".rept095 
     constraint "fobos".fk_01_rept096);

alter table "fobos".rept096 add constraint (foreign key (r96_compania,
    r96_localidad,r96_bodega,r96_num_entrega) references "fobos"
    .rept036  constraint "fobos".fk_02_rept096);

alter table "fobos".rept097 add constraint (foreign key (r97_compania,
    r97_localidad,r97_guia_remision) references "fobos".rept095 
     constraint "fobos".fk_01_rept097);

alter table "fobos".rept097 add constraint (foreign key (r97_compania,
    r97_localidad,r97_cod_tran,r97_num_tran) references "fobos"
    .rept019  constraint "fobos".fk_02_rept097);

alter table "fobos".cxct061 add constraint (foreign key (z61_compania) 
    references "fobos".cxct000  constraint "fobos".fk_01_cxct061);
    

alter table "fobos".cxct061 add constraint (foreign key (z61_usuario) 
    references "fobos".gent005  constraint "fobos".fk_02_cxct061);
    

alter table "fobos".cxct042 add constraint (foreign key (z42_compania,
    z42_localidad,z42_codcli,z42_tipo_doc,z42_num_doc,z42_dividendo) 
    references "fobos".cxct020  constraint "fobos".fk_01_cxct042);
    

alter table "fobos".cxct042 add constraint (foreign key (z42_compania,
    z42_localidad,z42_banco,z42_num_cta,z42_num_cheque,z42_secuencia) 
    references "fobos".cajt012  constraint "fobos".fk_02_cxct042);
    

alter table "fobos".ordt003 add constraint (foreign key (c03_compania,
    c03_tipo_ret,c03_porcentaje) references "fobos".ordt002  constraint 
    "fobos".fk_01_ordt003);

alter table "fobos".ordt003 add constraint (foreign key (c03_usuario_modifi) 
    references "fobos".gent005  constraint "fobos".fk_02_ordt003);
    

alter table "fobos".ordt003 add constraint (foreign key (c03_usuario_elimin) 
    references "fobos".gent005  constraint "fobos".fk_03_ordt003);
    

alter table "fobos".ordt003 add constraint (foreign key (c03_usuario) 
    references "fobos".gent005  constraint "fobos".fk_04_ordt003);
    

alter table "fobos".srit000 add constraint (foreign key (s00_compania) 
    references "fobos".gent001  constraint "fobos".fk_01_srit000);
    

alter table "fobos".srit000 add constraint (foreign key (s00_usuario) 
    references "fobos".gent005  constraint "fobos".fk_02_srit000);
    

alter table "fobos".srit001 add constraint (foreign key (s01_compania) 
    references "fobos".srit000  constraint "fobos".fk_01_srit001);
    

alter table "fobos".srit001 add constraint (foreign key (s01_usuario) 
    references "fobos".gent005  constraint "fobos".fk_02_srit001);
    

alter table "fobos".srit002 add constraint (foreign key (s02_compania) 
    references "fobos".srit000  constraint "fobos".fk_01_srit002);
    

alter table "fobos".srit002 add constraint (foreign key (s02_usuario) 
    references "fobos".gent005  constraint "fobos".fk_02_srit002);
    

alter table "fobos".srit003 add constraint (foreign key (s03_compania) 
    references "fobos".srit000  constraint "fobos".fk_01_srit003);
    

alter table "fobos".srit003 add constraint (foreign key (s03_usuario) 
    references "fobos".gent005  constraint "fobos".fk_02_srit003);
    

alter table "fobos".srit004 add constraint (foreign key (s04_compania) 
    references "fobos".srit000  constraint "fobos".fk_01_srit004);
    

alter table "fobos".srit004 add constraint (foreign key (s04_usuario) 
    references "fobos".gent005  constraint "fobos".fk_02_srit004);
    

alter table "fobos".srit005 add constraint (foreign key (s05_compania) 
    references "fobos".srit000  constraint "fobos".fk_01_srit005);
    

alter table "fobos".srit005 add constraint (foreign key (s05_usuario) 
    references "fobos".gent005  constraint "fobos".fk_02_srit005);
    

alter table "fobos".srit006 add constraint (foreign key (s06_compania) 
    references "fobos".srit000  constraint "fobos".fk_01_srit006);
    

alter table "fobos".srit006 add constraint (foreign key (s06_usuario) 
    references "fobos".gent005  constraint "fobos".fk_02_srit006);
    

alter table "fobos".srit007 add constraint (foreign key (s07_compania,
    s07_tipo_comp) references "fobos".srit004  constraint "fobos"
    .fk_01_srit007);

alter table "fobos".srit007 add constraint (foreign key (s07_compania,
    s07_sustento_tri) references "fobos".srit006  constraint "fobos"
    .fk_02_srit007);

alter table "fobos".srit008 add constraint (foreign key (s08_compania) 
    references "fobos".srit000  constraint "fobos".fk_01_srit008);
    

alter table "fobos".srit008 add constraint (foreign key (s08_usuario) 
    references "fobos".gent005  constraint "fobos".fk_02_srit008);
    

alter table "fobos".srit009 add constraint (foreign key (s09_compania) 
    references "fobos".srit000  constraint "fobos".fk_01_srit009);
    

alter table "fobos".srit009 add constraint (foreign key (s09_usuario) 
    references "fobos".gent005  constraint "fobos".fk_02_srit009);
    

alter table "fobos".srit010 add constraint (foreign key (s10_compania) 
    references "fobos".srit000  constraint "fobos".fk_01_srit010);
    

alter table "fobos".srit010 add constraint (foreign key (s10_usuario) 
    references "fobos".gent005  constraint "fobos".fk_03_srit010);
    

alter table "fobos".srit011 add constraint (foreign key (s11_compania) 
    references "fobos".srit000  constraint "fobos".fk_11_srit011);
    

alter table "fobos".srit011 add constraint (foreign key (s11_usuario) 
    references "fobos".gent005  constraint "fobos".fk_02_srit011);
    

alter table "fobos".srit012 add constraint (foreign key (s12_compania) 
    references "fobos".srit000  constraint "fobos".fk_12_srit012);
    

alter table "fobos".srit012 add constraint (foreign key (s12_usuario) 
    references "fobos".gent005  constraint "fobos".fk_02_srit012);
    

alter table "fobos".srit013 add constraint (foreign key (s13_compania) 
    references "fobos".srit000  constraint "fobos".fk_13_srit013);
    

alter table "fobos".srit013 add constraint (foreign key (s13_usuario) 
    references "fobos".gent005  constraint "fobos".fk_02_srit013);
    

alter table "fobos".srit014 add constraint (foreign key (s14_compania) 
    references "fobos".srit000  constraint "fobos".fk_01_srit014);
    

alter table "fobos".srit014 add constraint (foreign key (s14_usuario) 
    references "fobos".gent005  constraint "fobos".fk_02_srit014);
    

alter table "fobos".srit015 add constraint (foreign key (s15_compania) 
    references "fobos".srit000  constraint "fobos".fk_01_srit015);
    

alter table "fobos".srit015 add constraint (foreign key (s15_usuario) 
    references "fobos".gent005  constraint "fobos".fk_03_srit015);
    

alter table "fobos".srit016 add constraint (foreign key (s16_compania) 
    references "fobos".srit000  constraint "fobos".fk_16_srit016);
    

alter table "fobos".srit016 add constraint (foreign key (s16_usuario) 
    references "fobos".gent005  constraint "fobos".fk_02_srit016);
    

alter table "fobos".srit017 add constraint (foreign key (s17_compania) 
    references "fobos".srit000  constraint "fobos".fk_17_srit017);
    

alter table "fobos".srit017 add constraint (foreign key (s17_usuario) 
    references "fobos".gent005  constraint "fobos".fk_02_srit017);
    

alter table "fobos".srit018 add constraint (foreign key (s18_compania,
    s18_sec_tran,s18_cod_ident) references "fobos".srit003  constraint 
    "fobos".fk_01_srit018);

alter table "fobos".srit018 add constraint (foreign key (s18_compania,
    s18_tipo_tran) references "fobos".srit005  constraint "fobos"
    .fk_02_srit018);

alter table "fobos".srit019 add constraint (foreign key (s19_compania,
    s19_sec_tran,s19_cod_ident) references "fobos".srit003  constraint 
    "fobos".fk_01_srit019);

alter table "fobos".srit019 add constraint (foreign key (s19_compania,
    s19_tipo_comp) references "fobos".srit004  constraint "fobos"
    .fk_02_srit019);

alter table "fobos".srit019 add constraint (foreign key (s19_tipo_doc) 
    references "fobos".cxct004  constraint "fobos".fk_03_srit019);
    

alter table "fobos".srit020 add constraint (foreign key (s20_compania,
    s20_tipo_tran) references "fobos".srit004  constraint "fobos"
    .fk_01_srit020);

alter table "fobos".srit020 add constraint (foreign key (s20_compania,
    s20_tipo_comp) references "fobos".srit005  constraint "fobos"
    .fk_02_srit020);

alter table "fobos".srit021 add constraint (foreign key (s21_usuario) 
    references "fobos".gent005  constraint "fobos".fk_01_srit021);
    

alter table "fobos".srit021 add constraint (foreign key (s21_usuario_modif) 
    references "fobos".gent005  constraint "fobos".fk_02_srit021);
    

alter table "fobos".rept098 add constraint (foreign key (r98_compania,
    r98_localidad,r98_cod_tran,r98_num_tran) references "fobos"
    .rept019  constraint "fobos".fk_01_rept098);

alter table "fobos".rept098 add constraint (foreign key (r98_codcli) 
    references "fobos".cxct001  constraint "fobos".fk_02_rept098);
    

alter table "fobos".rept098 add constraint (foreign key (r98_usuario) 
    references "fobos".gent005  constraint "fobos".fk_03_rept098);
    

alter table "fobos".rept099 add constraint (foreign key (r99_compania,
    r99_localidad,r99_vend_ant,r99_vend_nue,r99_secuencia) references 
    "fobos".rept098  constraint "fobos".fk_01_rept099);

alter table "fobos".rept099 add constraint (foreign key (r99_compania,
    r99_localidad,r99_cod_tran,r99_num_tran) references "fobos"
    .rept019  constraint "fobos".fk_02_rept099);

alter table "fobos".rept020 add constraint (foreign key (r20_compania,
    r20_localidad,r20_cod_tran,r20_num_tran) references "fobos"
    .rept019 );

alter table "fobos".rept020 add constraint (foreign key (r20_compania,
    r20_item) references "fobos".rept010 );

alter table "fobos".rept020 add constraint (foreign key (r20_compania,
    r20_linea) references "fobos".rept003 );

alter table "fobos".rept020 add constraint (foreign key (r20_compania,
    r20_rotacion) references "fobos".rept004 );

alter table "fobos".rolt056 add constraint (foreign key (n56_proceso) 
    references "fobos".rolt003  constraint "fobos".fk_01_rolt056);
    

alter table "fobos".rolt056 add constraint (foreign key (n56_compania,
    n56_cod_depto) references "fobos".gent034  constraint "fobos"
    .fk_02_rolt056);

alter table "fobos".rolt056 add constraint (foreign key (n56_compania,
    n56_cod_trab) references "fobos".rolt030  constraint "fobos"
    .fk_03_rolt056);

alter table "fobos".rolt056 add constraint (foreign key (n56_compania,
    n56_aux_val_vac) references "fobos".ctbt010  constraint "fobos"
    .fk_04_rolt056);

alter table "fobos".rolt056 add constraint (foreign key (n56_compania,
    n56_aux_val_adi) references "fobos".ctbt010  constraint "fobos"
    .fk_05_rolt056);

alter table "fobos".rolt056 add constraint (foreign key (n56_compania,
    n56_aux_otr_ing) references "fobos".ctbt010  constraint "fobos"
    .fk_06_rolt056);

alter table "fobos".rolt056 add constraint (foreign key (n56_compania,
    n56_aux_iess) references "fobos".ctbt010  constraint "fobos"
    .fk_07_rolt056);

alter table "fobos".rolt056 add constraint (foreign key (n56_compania,
    n56_aux_otr_egr) references "fobos".ctbt010  constraint "fobos"
    .fk_08_rolt056);

alter table "fobos".rolt056 add constraint (foreign key (n56_compania,
    n56_aux_banco) references "fobos".ctbt010  constraint "fobos"
    .fk_09_rolt056);

alter table "fobos".rolt056 add constraint (foreign key (n56_usuario) 
    references "fobos".gent005  constraint "fobos".fk_10_rolt056);
    

alter table "fobos".rolt057 add constraint (foreign key (n57_compania,
    n57_proceso,n57_cod_trab,n57_periodo_ini,n57_periodo_fin) 
    references "fobos".rolt039  constraint "fobos".fk_01_rolt057);
    

alter table "fobos".rolt057 add constraint (foreign key (n57_compania,
    n57_tipo_comp,n57_num_comp) references "fobos".ctbt012  constraint 
    "fobos".fk_02_rolt057);

alter table "fobos".rolt057 add constraint (foreign key (n57_proceso) 
    references "fobos".rolt003  constraint "fobos".fk_03_rolt057);
    

alter table "fobos".rolt090 add constraint (foreign key (n90_compania) 
    references "fobos".rolt001  constraint "fobos".fk_01_rolt090);
    

alter table "fobos".rolt090 add constraint (foreign key (n90_usuario) 
    references "fobos".gent005  constraint "fobos".fk_02_rolt090);
    

alter table "fobos".rolt058 add constraint (foreign key (n58_compania,
    n58_num_prest) references "fobos".rolt045  constraint "fobos"
    .fk_01_rolt058);

alter table "fobos".rolt058 add constraint (foreign key (n58_proceso) 
    references "fobos".rolt003  constraint "fobos".fk_02_rolt058);
    

alter table "fobos".rolt058 add constraint (foreign key (n58_usuario) 
    references "fobos".gent005  constraint "fobos".fk_03_rolt058);
    

alter table "fobos".rolt059 add constraint (foreign key (n59_compania,
    n59_num_prest) references "fobos".rolt045  constraint "fobos"
    .fk_01_rolt059);

alter table "fobos".rolt059 add constraint (foreign key (n59_compania,
    n59_tipo_comp,n59_num_comp) references "fobos".ctbt012  constraint 
    "fobos".fk_02_rolt059);

alter table "fobos".rolt091 add constraint (foreign key (n91_bco_empresa) 
    references "fobos".gent008  constraint "fobos".fk_04_rolt091);
    

alter table "fobos".rolt091 add constraint (foreign key (n91_compania) 
    references "fobos".rolt000  constraint "fobos".fk_01_rolt091);
    

alter table "fobos".rolt091 add constraint (foreign key (n91_proceso) 
    references "fobos".rolt003  constraint "fobos".fk_02_rolt091);
    

alter table "fobos".rolt091 add constraint (foreign key (n91_compania,
    n91_cod_trab) references "fobos".rolt030  constraint "fobos"
    .fk_03_rolt091);

alter table "fobos".rolt091 add constraint (foreign key (n91_compania,
    n91_bco_empresa,n91_cta_empresa) references "fobos".gent009 
     constraint "fobos".fk_05_rolt091);

alter table "fobos".rolt091 add constraint (foreign key (n91_usuario) 
    references "fobos".gent005  constraint "fobos".fk_07_rolt091);
    

alter table "fobos".rolt091 add constraint (foreign key (n91_compania,
    n91_tipo_comp,n91_num_comp) references "fobos".ctbt012  constraint 
    "fobos".fk_08_rolt091);

alter table "fobos".srit023 add constraint (foreign key (s23_compania,
    s23_aux_cont) references "fobos".ctbt010  constraint "fobos"
    .fk_03_srit023);

alter table "fobos".srit023 add constraint (foreign key (s23_usuario) 
    references "fobos".gent005  constraint "fobos".fk_04_srit023);
    

alter table "fobos".srit023 add constraint (foreign key (s23_tipo_orden) 
    references "fobos".ordt001  constraint "fobos".fk_01_srit023);
    

alter table "fobos".srit023 add constraint (foreign key (s23_compania,
    s23_sustento_sri) references "fobos".srit006  constraint "fobos"
    .fk_02_srit023);

alter table "fobos".rolt092 add constraint (foreign key (n92_compania,
    n92_proceso,n92_cod_trab,n92_num_ant) references "fobos".rolt091 
     constraint "fobos".fk_01_rolt092);

alter table "fobos".rolt092 add constraint (foreign key (n92_compania) 
    references "fobos".rolt000  constraint "fobos".fk_02_rolt092);
    

alter table "fobos".rolt092 add constraint (foreign key (n92_proceso) 
    references "fobos".rolt003  constraint "fobos".fk_03_rolt092);
    

alter table "fobos".rolt092 add constraint (foreign key (n92_compania,
    n92_cod_trab) references "fobos".rolt030  constraint "fobos"
    .fk_04_rolt092);

alter table "fobos".rolt092 add constraint (foreign key (n92_compania,
    n92_num_prest,n92_secuencia) references "fobos".rolt046  constraint 
    "fobos".fk_05_rolt092);

alter table "fobos".rolt092 add constraint (foreign key (n92_cod_liqrol) 
    references "fobos".rolt003  constraint "fobos".fk_06_rolt092);
    

alter table "fobos".cxpt029 add constraint (foreign key (p29_compania,
    p29_localidad,p29_num_ret) references "fobos".cxpt027  constraint 
    "fobos".fk_01_cxpt029);

alter table "fobos".cxpt032 add constraint (foreign key (p32_compania,
    p32_localidad,p32_num_ret) references "fobos".cxpt027  constraint 
    "fobos".fk_01_cxpt032);

alter table "fobos".cxpt032 add constraint (foreign key (p32_compania,
    p32_localidad,p32_tipo_doc,p32_secuencia) references "fobos"
    .gent037  constraint "fobos".fk_02_cxpt032);

alter table "fobos".gent058 add constraint (foreign key (g58_compania) 
    references "fobos".gent001  constraint "fobos".fk_01_gent058);
    

alter table "fobos".gent058 add constraint (foreign key (g58_compania,
    g58_localidad) references "fobos".gent002  constraint "fobos"
    .fk_02_gent058);

alter table "fobos".gent058 add constraint (foreign key (g58_compania,
    g58_aux_cont) references "fobos".ctbt010  constraint "fobos"
    .fk_03_gent058);

alter table "fobos".gent058 add constraint (foreign key (g58_usuario) 
    references "fobos".gent005  constraint "fobos".fk_04_gent058);
    

alter table "fobos".ctbt013 add constraint (foreign key (b13_compania,
    b13_tipo_comp,b13_num_comp) references "fobos".ctbt012 );

alter table "fobos".ctbt013 add constraint (foreign key (b13_compania,
    b13_cuenta) references "fobos".ctbt010 );

alter table "fobos".ctbt013 add constraint (foreign key (b13_compania,
    b13_num_concil) references "fobos".ctbt030 );

alter table "fobos".ctbt013 add constraint (foreign key (b13_compania,
    b13_filtro) references "fobos".ctbt008 );

alter table "fobos".ordt001 add constraint (foreign key (c01_modulo) 
    references "fobos".gent050 );

alter table "fobos".ordt001 add constraint (foreign key (c01_usuario) 
    references "fobos".gent005 );

alter table "fobos".gent002 add constraint (foreign key (g02_compania) 
    references "fobos".gent001 );

alter table "fobos".gent002 add constraint (foreign key (g02_ciudad) 
    references "fobos".gent031 );

alter table "fobos".gent002 add constraint (foreign key (g02_usuario) 
    references "fobos".gent005 );

alter table "fobos".srit024 add constraint (foreign key (s24_compania,
    s24_codigo,s24_porcentaje_ice,s24_codigo_impto) references 
    "fobos".srit010  constraint "fobos".fk_01_srit024);

alter table "fobos".srit024 add constraint (foreign key (s24_tipo_orden) 
    references "fobos".ordt001  constraint "fobos".fk_02_srit024);
    

alter table "fobos".srit024 add constraint (foreign key (s24_compania) 
    references "fobos".srit000  constraint "fobos".fk_03_srit024);
    

alter table "fobos".srit024 add constraint (foreign key (s24_compania,
    s24_aux_cont) references "fobos".ctbt010  constraint "fobos"
    .fk_04_srit024);

alter table "fobos".srit024 add constraint (foreign key (s24_usuario) 
    references "fobos".gent005  constraint "fobos".fk_05_srit024);
    

alter table "fobos".rolt018 add constraint (foreign key (n18_cod_rubro) 
    references "fobos".rolt006  constraint "fobos".fk_01_rolt018);
    

alter table "fobos".rolt018 add constraint (foreign key (n18_flag_ident) 
    references "fobos".rolt016  constraint "fobos".fk_02_rolt018);
    

alter table "fobos".rolt018 add constraint (foreign key (n18_usuario) 
    references "fobos".gent005  constraint "fobos".fk_03_rolt018);
    

alter table "fobos".rolt049 add constraint (foreign key (n49_compania,
    n49_proceso,n49_cod_trab,n49_fecha_ini,n49_fecha_fin) references 
    "fobos".rolt042  constraint "fobos".fk_01_rolt049);

alter table "fobos".rolt049 add constraint (foreign key (n49_proceso) 
    references "fobos".rolt003  constraint "fobos".fk_02_rolt049);
    

alter table "fobos".rolt049 add constraint (foreign key (n49_compania,
    n49_cod_rubro) references "fobos".rolt009  constraint "fobos"
    .fk_03_rolt049);

alter table "fobos".rolt049 add constraint (foreign key (n49_compania,
    n49_num_prest) references "fobos".rolt045  constraint "fobos"
    .fk_04_rolt049);

alter table "fobos".cajt014 add constraint (foreign key (j14_compania,
    j14_localidad,j14_tipo_fuente,j14_num_fuente,j14_secuencia) 
    references "fobos".cajt011  constraint "fobos".fk_01_cajt014);
    

alter table "fobos".cajt014 add constraint (foreign key (j14_compania,
    j14_tipo_ret,j14_porc_ret) references "fobos".ordt002  constraint 
    "fobos".fk_02_cajt014);

alter table "fobos".cajt014 add constraint (foreign key (j14_compania,
    j14_codigo_pago,j14_cont_cred) references "fobos".cajt001 
     constraint "fobos".fk_04_cajt014);

alter table "fobos".cajt014 add constraint (foreign key (j14_compania,
    j14_tipo_comp,j14_num_comp) references "fobos".ctbt012  constraint 
    "fobos".fk_06_cajt014);

alter table "fobos".cajt014 add constraint (foreign key (j14_usuario) 
    references "fobos".gent005  constraint "fobos".fk_07_cajt014);
    

alter table "fobos".cajt014 add constraint (foreign key (j14_compania,
    j14_tipo_ret,j14_porc_ret,j14_codigo_sri,j14_fec_ini_porc) 
    references "fobos".ordt003  constraint "fobos".fk_03_cajt014);
    

alter table "fobos".cxct008 add constraint (foreign key (z08_compania) 
    references "fobos".cxct000  constraint "fobos".fk_01_cxct008);
    

alter table "fobos".cxct008 add constraint (foreign key (z08_codcli) 
    references "fobos".cxct001  constraint "fobos".fk_02_cxct008);
    

alter table "fobos".cxct008 add constraint (foreign key (z08_compania,
    z08_tipo_ret,z08_porcentaje) references "fobos".ordt002  constraint 
    "fobos".fk_03_cxct008);

alter table "fobos".cxct008 add constraint (foreign key (z08_usuario) 
    references "fobos".gent005  constraint "fobos".fk_05_cxct008);
    

alter table "fobos".cxct008 add constraint (foreign key (z08_compania,
    z08_tipo_ret,z08_porcentaje,z08_codigo_sri,z08_fecha_ini_porc) 
    references "fobos".ordt003  constraint "fobos".fk_04_cxct008);
    

alter table "fobos".cxct009 add constraint (foreign key (z09_compania) 
    references "fobos".cxct000  constraint "fobos".fk_02_cxct009);
    

alter table "fobos".cxct009 add constraint (foreign key (z09_codcli) 
    references "fobos".cxct001  constraint "fobos".fk_03_cxct009);
    

alter table "fobos".cxct009 add constraint (foreign key (z09_compania,
    z09_tipo_ret,z09_porcentaje) references "fobos".ordt002  constraint 
    "fobos".fk_04_cxct009);

alter table "fobos".cxct009 add constraint (foreign key (z09_compania,
    z09_codigo_pago,z09_cont_cred) references "fobos".cajt001 
     constraint "fobos".fk_06_cxct009);

alter table "fobos".cxct009 add constraint (foreign key (z09_compania,
    z09_aux_cont) references "fobos".ctbt010  constraint "fobos"
    .fk_07_cxct009);

alter table "fobos".cxct009 add constraint (foreign key (z09_usuario) 
    references "fobos".gent005  constraint "fobos".fk_08_cxct009);
    

alter table "fobos".cxct009 add constraint (foreign key (z09_compania,
    z09_tipo_ret,z09_porcentaje,z09_codigo_sri,z09_fecha_ini_porc) 
    references "fobos".ordt003  constraint "fobos".fk_05_cxct009);
    

alter table "fobos".cajt091 add constraint (foreign key (j91_compania,
    j91_codigo_pago,j91_cont_cred) references "fobos".cajt001 
     constraint "fobos".fk_01_cajt091);

alter table "fobos".cajt091 add constraint (foreign key (j91_compania,
    j91_tipo_ret,j91_porcentaje) references "fobos".ordt002  constraint 
    "fobos".fk_02_cajt091);

alter table "fobos".cajt091 add constraint (foreign key (j91_compania,
    j91_aux_cont) references "fobos".ctbt010  constraint "fobos"
    .fk_03_cajt091);

alter table "fobos".cajt091 add constraint (foreign key (j91_usuario) 
    references "fobos".gent005  constraint "fobos".fk_04_cajt091);
    

alter table "fobos".srit025 add constraint (foreign key (s25_usuario) 
    references "fobos".gent005  constraint "fobos".fk_02_srit025);
    

alter table "fobos".srit025 add constraint (foreign key (s25_compania,
    s25_tipo_ret,s25_porcentaje,s25_codigo_sri,s25_fecha_ini_porc) 
    references "fobos".ordt003  constraint "fobos".fk_01_srit025);
    

alter table "fobos".rolt015 add constraint (foreign key (n15_compania) 
    references "fobos".rolt001  constraint "fobos".fk_01_rolt015);
    

alter table "fobos".rolt015 add constraint (foreign key (n15_usuario) 
    references "fobos".gent005  constraint "fobos".fk_02_rolt015);
    

alter table "fobos".rolt085 add constraint (foreign key (n85_compania,
    n85_proceso,n85_cod_trab,n85_ano_proceso) references "fobos"
    .rolt084  constraint "fobos".fk_01_rolt085);

alter table "fobos".rolt085 add constraint (foreign key (n85_compania) 
    references "fobos".rolt001  constraint "fobos".fk_02_rolt085);
    

alter table "fobos".rolt085 add constraint (foreign key (n85_proceso) 
    references "fobos".rolt003  constraint "fobos".fk_03_rolt085);
    

alter table "fobos".rolt085 add constraint (foreign key (n85_compania,
    n85_cod_trab) references "fobos".rolt030  constraint "fobos"
    .fk_04_rolt085);

alter table "fobos".rolt085 add constraint (foreign key (n85_usuario) 
    references "fobos".gent005  constraint "fobos".fk_05_rolt085);
    

alter table "fobos".rolt085 add constraint (foreign key (n85_usu_modifi) 
    references "fobos".gent005  constraint "fobos".fk_06_rolt085);
    

alter table "fobos".rolt085 add constraint (foreign key (n85_usu_cierre) 
    references "fobos".gent005  constraint "fobos".fk_07_rolt085);
    

alter table "fobos".ctbt044 add constraint (foreign key (b44_usuario) 
    references "fobos".gent005  constraint "fobos".fk_01_ctbt044);
    

alter table "fobos".ctbt045 add constraint (foreign key (b45_usuario) 
    references "fobos".gent005  constraint "fobos".fk_01_ctbt045);
    

alter table "fobos".rolt022 add constraint (foreign key (n22_compania) 
    references "fobos".rolt001  constraint "fobos".fk_01_rolt022);
    

alter table "fobos".rolt022 add constraint (foreign key (n22_proceso) 
    references "fobos".rolt003  constraint "fobos".fk_02_rolt022);
    

alter table "fobos".rolt022 add constraint (foreign key (n22_usuario) 
    references "fobos".gent005  constraint "fobos".fk_03_rolt022);
    

alter table "fobos".rolt023 add constraint (foreign key (n23_compania,
    n23_codigo_arch,n23_tipo_arch) references "fobos".rolt022 
     constraint "fobos".fk_01_rolt023);

alter table "fobos".rolt023 add constraint (foreign key (n23_compania) 
    references "fobos".rolt001  constraint "fobos".fk_02_rolt023);
    

alter table "fobos".rolt023 add constraint (foreign key (n23_flag_ident) 
    references "fobos".rolt016  constraint "fobos".fk_03_rolt023);
    

alter table "fobos".rolt023 add constraint (foreign key (n23_usuario) 
    references "fobos".gent005  constraint "fobos".fk_04_rolt023);
    

alter table "fobos".rolt024 add constraint (foreign key (n24_compania,
    n24_codigo_arch,n24_tipo_arch) references "fobos".rolt022 
     constraint "fobos".fk_01_rolt024);

alter table "fobos".rolt024 add constraint (foreign key (n24_compania) 
    references "fobos".rolt001  constraint "fobos".fk_02_rolt024);
    

alter table "fobos".rolt024 add constraint (foreign key (n24_usuario) 
    references "fobos".gent005  constraint "fobos".fk_03_rolt024);
    

alter table "fobos".rolt025 add constraint (foreign key (n25_compania,
    n25_codigo_arch,n25_tipo_arch) references "fobos".rolt022 
     constraint "fobos".fk_01_rolt025);

alter table "fobos".rolt025 add constraint (foreign key (n25_compania) 
    references "fobos".rolt001  constraint "fobos".fk_02_rolt025);
    

alter table "fobos".rolt025 add constraint (foreign key (n25_usuario) 
    references "fobos".gent005  constraint "fobos".fk_03_rolt025);
    

alter table "fobos".rolt025 add constraint (foreign key (n25_compania,
    n25_codigo_arch,n25_tipo_arch,n25_tipo_codigo,n25_sub_tipo) 
    references "fobos".rolt025  constraint "fobos".fk_04_rolt025);
    

alter table "fobos".rolt026 add constraint (foreign key (n26_compania) 
    references "fobos".rolt001  constraint "fobos".fk_01_rolt026);
    

alter table "fobos".rolt026 add constraint (foreign key (n26_compania,
    n26_codigo_arch,n26_tipo_arch) references "fobos".rolt022 
     constraint "fobos".fk_02_rolt026);

alter table "fobos".rolt026 add constraint (foreign key (n26_compania,
    n26_codigo_arch,n26_tipo_arch,n26_jornada,n26_sec_jor) references 
    "fobos".rolt023  constraint "fobos".fk_03_rolt026);

alter table "fobos".rolt026 add constraint (foreign key (n26_compania,
    n26_codigo_arch,n26_tipo_arch,n26_codigo_seg,n26_tipo_seg) 
    references "fobos".rolt024  constraint "fobos".fk_04_rolt026);
    

alter table "fobos".rolt026 add constraint (foreign key (n26_compania,
    n26_codigo_arch,n26_tipo_arch,n26_codigo_empl,n26_tipo_empl) 
    references "fobos".rolt025  constraint "fobos".fk_05_rolt026);
    

alter table "fobos".rolt026 add constraint (foreign key (n26_compania,
    n26_codigo_arch,n26_tipo_arch,n26_codigo_rela,n26_tipo_rela) 
    references "fobos".rolt025  constraint "fobos".fk_06_rolt026);
    

alter table "fobos".rolt026 add constraint (foreign key (n26_usua_elimin) 
    references "fobos".gent005  constraint "fobos".fk_07_rolt026);
    

alter table "fobos".rolt026 add constraint (foreign key (n26_usua_cierre) 
    references "fobos".gent005  constraint "fobos".fk_08_rolt026);
    

alter table "fobos".rolt026 add constraint (foreign key (n26_usuario) 
    references "fobos".gent005  constraint "fobos".fk_09_rolt026);
    

alter table "fobos".rolt027 add constraint (foreign key (n27_compania,
    n27_ano_proceso,n27_mes_proceso,n27_codigo_arch,n27_tipo_arch,
    n27_secuencia) references "fobos".rolt026  constraint "fobos"
    .fk_01_rolt027);

alter table "fobos".rolt027 add constraint (foreign key (n27_compania) 
    references "fobos".rolt001  constraint "fobos".fk_02_rolt027);
    

alter table "fobos".rolt027 add constraint (foreign key (n27_compania,
    n27_cod_trab) references "fobos".rolt030  constraint "fobos"
    .fk_03_rolt027);

alter table "fobos".rolt027 add constraint (foreign key (n27_compania,
    n27_codigo_arch,n27_tipo_arch,n27_tipo_causa,n27_sec_cau) 
    references "fobos".rolt023  constraint "fobos".fk_05_rolt027);
    

alter table "fobos".rolt027 add constraint (foreign key (n27_compania,
    n27_codigo_arch,n27_tipo_arch,n27_tipo_pago,n27_flag_pago) 
    references "fobos".rolt024  constraint "fobos".fk_06_rolt027);
    

alter table "fobos".rolt027 add constraint (foreign key (n27_usua_elimin) 
    references "fobos".gent005  constraint "fobos".fk_07_rolt027);
    

alter table "fobos".rolt027 add constraint (foreign key (n27_usua_modifi) 
    references "fobos".gent005  constraint "fobos".fk_08_rolt027);
    

alter table "fobos".rolt027 add constraint (foreign key (n27_compania,
    n27_ano_sect,n27_sectorial) references "fobos".rolt017  constraint 
    "fobos".fk_04_rolt027);

alter table "fobos".talt042 add constraint (foreign key (t42_compania,
    t42_localidad,t42_num_ot) references "fobos".talt023  constraint 
    "fobos".fk_01_talt042);

alter table "fobos".talt042 add constraint (foreign key (t42_compania) 
    references "fobos".talt000  constraint "fobos".fk_02_talt042);
    

alter table "fobos".talt042 add constraint (foreign key (t42_cod_cliente) 
    references "fobos".cxct001  constraint "fobos".fk_03_talt042);
    

alter table "fobos".talt042 add constraint (foreign key (t42_usuario) 
    references "fobos".gent005  constraint "fobos".fk_04_talt042);
    

alter table "fobos".rept043 add constraint (foreign key (r43_compania,
    r43_division) references "fobos".rept003  constraint "fobos"
    .fk_02_rept043);

alter table "fobos".rept043 add constraint (foreign key (r43_compania,
    r43_division,r43_sub_linea) references "fobos".rept070  constraint 
    "fobos".fk_03_rept043);

alter table "fobos".rept043 add constraint (foreign key (r43_compania,
    r43_division,r43_sub_linea,r43_cod_grupo) references "fobos"
    .rept071  constraint "fobos".fk_04_rept043);

alter table "fobos".rept043 add constraint (foreign key (r43_compania,
    r43_division,r43_sub_linea,r43_cod_grupo,r43_cod_clase) references 
    "fobos".rept072  constraint "fobos".fk_05_rept043);

alter table "fobos".rept043 add constraint (foreign key (r43_compania,
    r43_marca) references "fobos".rept073  constraint "fobos".fk_06_rept043);
    

alter table "fobos".rept043 add constraint (foreign key (r43_usuario) 
    references "fobos".gent005  constraint "fobos".fk_07_rept043);
    

alter table "fobos".rept044 add constraint (foreign key (r44_compania,
    r44_localidad,r44_traspaso) references "fobos".rept043  constraint 
    "fobos".fk_01_rept044);

alter table "fobos".rept044 add constraint (foreign key (r44_compania,
    r44_bodega_ori) references "fobos".rept002  constraint "fobos"
    .fk_02_rept044);

alter table "fobos".rept044 add constraint (foreign key (r44_compania,
    r44_item_ori) references "fobos".rept010  constraint "fobos"
    .fk_03_rept044);

alter table "fobos".rept044 add constraint (foreign key (r44_compania,
    r44_bodega_tra) references "fobos".rept002  constraint "fobos"
    .fk_04_rept044);

alter table "fobos".rept044 add constraint (foreign key (r44_compania,
    r44_item_tra) references "fobos".rept010  constraint "fobos"
    .fk_05_rept044);

alter table "fobos".rept044 add constraint (foreign key (r44_compania,
    r44_division_t) references "fobos".rept003  constraint "fobos"
    .fk_06_rept044);

alter table "fobos".rept044 add constraint (foreign key (r44_compania,
    r44_division_t,r44_sub_linea_t) references "fobos".rept070 
     constraint "fobos".fk_07_rept044);

alter table "fobos".rept044 add constraint (foreign key (r44_compania,
    r44_division_t,r44_sub_linea_t,r44_cod_grupo_t) references 
    "fobos".rept071  constraint "fobos".fk_08_rept044);

alter table "fobos".rept044 add constraint (foreign key (r44_compania,
    r44_division_t,r44_sub_linea_t,r44_cod_grupo_t,r44_cod_clase_t) 
    references "fobos".rept072  constraint "fobos".fk_09_rept044);
    

alter table "fobos".rept044 add constraint (foreign key (r44_compania,
    r44_marca_t) references "fobos".rept073  constraint "fobos"
    .fk_10_rept044);

alter table "fobos".rept045 add constraint (foreign key (r45_compania,
    r45_localidad,r45_cod_tran,r45_num_tran) references "fobos"
    .rept019  constraint "fobos".fk_01_rept045);

alter table "fobos".rept045 add constraint (foreign key (r45_compania,
    r45_localidad,r45_traspaso) references "fobos".rept043  constraint 
    "fobos".fk_02_rept045);

alter table "fobos".rept045 add constraint (foreign key (r45_usuario) 
    references "fobos".gent005  constraint "fobos".fk_03_rept045);
    

alter table "fobos".gent024 add constraint (foreign key (g24_compania,
    g24_bodega) references "fobos".rept002  constraint "fobos".fk_01_gent024);
    

alter table "fobos".gent024 add constraint (foreign key (g24_impresora) 
    references "fobos".gent006  constraint "fobos".fk_02_gent024);
    

alter table "fobos".gent024 add constraint (foreign key (g24_usuario) 
    references "fobos".gent005  constraint "fobos".fk_03_gent024);
    

alter table "fobos".actt015 add constraint (foreign key (a15_compania,
    a15_codigo_tran,a15_numero_tran) references "fobos".actt012 
     constraint "fobos".fk_01_actt015);

alter table "fobos".actt015 add constraint (foreign key (a15_compania,
    a15_tipo_comp,a15_num_comp) references "fobos".ctbt012  constraint 
    "fobos".fk_02_actt015);

alter table "fobos".actt015 add constraint (foreign key (a15_usuario) 
    references "fobos".gent005  constraint "fobos".fk_03_actt015);
    

alter table "fobos".actt012 add constraint (foreign key (a12_compania,
    a12_codigo_tran) references "fobos".actt005 );

alter table "fobos".actt012 add constraint (foreign key (a12_compania,
    a12_codigo_bien) references "fobos".actt010 );

alter table "fobos".actt012 add constraint (foreign key (a12_compania,
    a12_locali_ori) references "fobos".gent002 );

alter table "fobos".actt012 add constraint (foreign key (a12_compania,
    a12_locali_dest) references "fobos".gent002 );

alter table "fobos".actt012 add constraint (foreign key (a12_compania,
    a12_depto_ori) references "fobos".gent034 );

alter table "fobos".actt012 add constraint (foreign key (a12_compania,
    a12_depto_dest) references "fobos".gent034 );

alter table "fobos".actt012 add constraint (foreign key (a12_compania,
    a12_tipcomp_gen,a12_numcomp_gen) references "fobos".ctbt012 
    );

alter table "fobos".actt012 add constraint (foreign key (a12_usuario) 
    references "fobos".gent005 );

alter table "fobos".actt006 add constraint (foreign key (a06_usuario) 
    references "fobos".gent005  constraint "fobos".fk_01_actt006);
    

alter table "fobos".srit022 add constraint (foreign key (s22_usu_apert) 
    references "fobos".gent005  constraint "fobos".fk_01_srit022);
    

alter table "fobos".srit022 add constraint (foreign key (s22_usu_cierre) 
    references "fobos".gent005  constraint "fobos".fk_02_srit022);
    

alter table "fobos".srit022 add constraint (foreign key (s22_usuario) 
    references "fobos".gent005  constraint "fobos".fk_03_srit022);
    

alter table "fobos".rept019_res add constraint (foreign key (r19_usuario) 
    references "fobos".gent005  constraint "fobos".fk_01_rept019_res);
    

alter table "fobos".rept020_res add constraint (foreign key (r20_compania,
    r20_localidad,r20_cod_tran,r20_num_tran) references "fobos"
    .rept019_res  constraint "fobos".fk_01_rept020_res);

alter table "fobos".rept010_res add constraint (foreign key (r10_usuario) 
    references "fobos".gent005  constraint "fobos".fk_01_rept010_res);
    

alter table "fobos".ctbt013_res add constraint (foreign key (b13_usuario) 
    references "fobos".gent005  constraint "fobos".fk_01_ctbt013_res);
    

alter table "fobos".cxpt033 add constraint (foreign key (p33_compania,
    p33_localidad,p33_numero_oc) references "fobos".ordt010  constraint 
    "fobos".fk_01_cxpt033);

alter table "fobos".cxpt033 add constraint (foreign key (p33_compania,
    p33_localidad,p33_cod_tran,p33_num_tran) references "fobos"
    .rept019  constraint "fobos".fk_02_cxpt033);

alter table "fobos".cxpt033 add constraint (foreign key (p33_cod_prov_ant) 
    references "fobos".cxpt001  constraint "fobos".fk_03_cxpt033);
    

alter table "fobos".cxpt033 add constraint (foreign key (p33_cod_prov_nue) 
    references "fobos".cxpt001  constraint "fobos".fk_04_cxpt033);
    

alter table "fobos".cxpt033 add constraint (foreign key (p33_usuario) 
    references "fobos".gent005  constraint "fobos".fk_05_cxpt033);
    

alter table "fobos".rept009 add constraint (foreign key (r09_usuario) 
    references "fobos".gent005  constraint "fobos".fk_01_rept009);
    

alter table "fobos".rept046 add constraint (foreign key (r46_compania) 
    references "fobos".rept000  constraint "fobos".fk_01_rept046);
    

alter table "fobos".rept046 add constraint (foreign key (r46_compania,
    r46_localidad) references "fobos".gent002  constraint "fobos"
    .fk_02_rept046);

alter table "fobos".rept046 add constraint (foreign key (r46_compania,
    r46_item_comp) references "fobos".rept010  constraint "fobos"
    .fk_03_rept046);

alter table "fobos".rept046 add constraint (foreign key (r46_compania,
    r46_cod_ventas) references "fobos".rept001  constraint "fobos"
    .fk_04_rept046);

alter table "fobos".rept046 add constraint (foreign key (r46_compania,
    r46_division_c) references "fobos".rept003  constraint "fobos"
    .fk_05_rept046);

alter table "fobos".rept046 add constraint (foreign key (r46_compania,
    r46_division_c,r46_sub_linea_c) references "fobos".rept070 
     constraint "fobos".fk_06_rept046);

alter table "fobos".rept046 add constraint (foreign key (r46_compania,
    r46_division_c,r46_sub_linea_c,r46_cod_grupo_c) references 
    "fobos".rept071  constraint "fobos".fk_07_rept046);

alter table "fobos".rept046 add constraint (foreign key (r46_compania,
    r46_division_c,r46_sub_linea_c,r46_cod_grupo_c,r46_cod_clase_c) 
    references "fobos".rept072  constraint "fobos".fk_08_rept046);
    

alter table "fobos".rept046 add constraint (foreign key (r46_compania,
    r46_marca_c) references "fobos".rept073  constraint "fobos"
    .fk_09_rept046);

alter table "fobos".rept046 add constraint (foreign key (r46_usu_modifi) 
    references "fobos".gent005  constraint "fobos".fk_10_rept046);
    

alter table "fobos".rept046 add constraint (foreign key (r46_usu_cierre) 
    references "fobos".gent005  constraint "fobos".fk_11_rept046);
    

alter table "fobos".rept046 add constraint (foreign key (r46_usuario) 
    references "fobos".gent005  constraint "fobos".fk_12_rept046);
    

alter table "fobos".rept047 add constraint (foreign key (r47_compania,
    r47_localidad,r47_composicion,r47_item_comp) references "fobos"
    .rept046  constraint "fobos".fk_01_rept047);

alter table "fobos".rept047 add constraint (foreign key (r47_compania,
    r47_item_comp) references "fobos".rept010  constraint "fobos"
    .fk_02_rept047);

alter table "fobos".rept047 add constraint (foreign key (r47_compania,
    r47_bodega_part) references "fobos".rept002  constraint "fobos"
    .fk_03_rept047);

alter table "fobos".rept047 add constraint (foreign key (r47_compania,
    r47_item_part) references "fobos".rept010  constraint "fobos"
    .fk_04_rept047);

alter table "fobos".rept047 add constraint (foreign key (r47_compania,
    r47_division_p) references "fobos".rept003  constraint "fobos"
    .fk_05_rept047);

alter table "fobos".rept047 add constraint (foreign key (r47_compania,
    r47_division_p,r47_sub_linea_p) references "fobos".rept070 
     constraint "fobos".fk_06_rept047);

alter table "fobos".rept047 add constraint (foreign key (r47_compania,
    r47_division_p,r47_sub_linea_p,r47_cod_grupo_p) references 
    "fobos".rept071  constraint "fobos".fk_07_rept047);

alter table "fobos".rept047 add constraint (foreign key (r47_compania,
    r47_division_p,r47_sub_linea_p,r47_cod_grupo_p,r47_cod_clase_p) 
    references "fobos".rept072  constraint "fobos".fk_08_rept047);
    

alter table "fobos".rept047 add constraint (foreign key (r47_compania,
    r47_marca_p) references "fobos".rept073  constraint "fobos"
    .fk_09_rept047);

alter table "fobos".rept048 add constraint (foreign key (r48_compania,
    r48_localidad,r48_composicion,r48_item_comp) references "fobos"
    .rept046  constraint "fobos".fk_01_rept048);

alter table "fobos".rept048 add constraint (foreign key (r48_compania,
    r48_item_comp) references "fobos".rept010  constraint "fobos"
    .fk_02_rept048);

alter table "fobos".rept048 add constraint (foreign key (r48_compania,
    r48_bodega_comp) references "fobos".rept002  constraint "fobos"
    .fk_03_rept048);

alter table "fobos".rept048 add constraint (foreign key (r48_usu_elimin) 
    references "fobos".gent005  constraint "fobos".fk_04_rept048);
    

alter table "fobos".rept048 add constraint (foreign key (r48_usu_cierre) 
    references "fobos".gent005  constraint "fobos".fk_05_rept048);
    

alter table "fobos".rept048 add constraint (foreign key (r48_usuario) 
    references "fobos".gent005  constraint "fobos".fk_06_rept048);
    

alter table "fobos".rept049 add constraint (foreign key (r49_compania,
    r49_localidad,r49_numero_oc) references "fobos".ordt010  constraint 
    "fobos".fk_01_rept049);

alter table "fobos".rept049 add constraint (foreign key (r49_compania,
    r49_localidad,r49_composicion,r49_item_comp,r49_sec_carga) 
    references "fobos".rept048  constraint "fobos".fk_02_rept049);
    

alter table "fobos".rept049 add constraint (foreign key (r49_compania,
    r49_item_comp) references "fobos".rept010  constraint "fobos"
    .fk_03_rept049);

alter table "fobos".rept049 add constraint (foreign key (r49_usuario) 
    references "fobos".gent005  constraint "fobos".fk_04_rept049);
    

alter table "fobos".rept053 add constraint (foreign key (r53_compania,
    r53_localidad,r53_cod_tran,r53_num_tran) references "fobos"
    .rept019  constraint "fobos".fk_01_rept053);

alter table "fobos".rept053 add constraint (foreign key (r53_compania,
    r53_localidad,r53_composicion,r53_item_comp,r53_sec_carga) 
    references "fobos".rept048  constraint "fobos".fk_02_rept053);
    

alter table "fobos".rept053 add constraint (foreign key (r53_compania,
    r53_item_comp) references "fobos".rept010  constraint "fobos"
    .fk_03_rept053);

alter table "fobos".rept053 add constraint (foreign key (r53_usuario) 
    references "fobos".gent005  constraint "fobos".fk_04_rept053);
    

alter table "fobos".rolt031 add constraint (foreign key (n31_compania,
    n31_cod_trab) references "fobos".rolt030 );

alter table "fobos".rolt031 add constraint (foreign key (n31_usuario) 
    references "fobos".gent005 );

alter table "fobos".rolt028 add constraint (foreign key (n28_compania) 
    references "fobos".rolt001  constraint "fobos".fk_01_rolt028);
    

alter table "fobos".rolt028 add constraint (foreign key (n28_proceso) 
    references "fobos".rolt003  constraint "fobos".fk_02_rolt028);
    

alter table "fobos".rolt028 add constraint (foreign key (n28_cod_liqrol) 
    references "fobos".rolt003  constraint "fobos".fk_03_rolt028);
    

alter table "fobos".rolt028 add constraint (foreign key (n28_usuario) 
    references "fobos".gent005  constraint "fobos".fk_04_rolt028);
    

alter table "fobos".rept019 add constraint (foreign key (r19_compania,
    r19_localidad,r19_codcli) references "fobos".cxct002 );

alter table "fobos".rept019 add constraint (foreign key (r19_compania) 
    references "fobos".rept000 );

alter table "fobos".rept019 add constraint (foreign key (r19_compania,
    r19_localidad) references "fobos".gent002 );

alter table "fobos".rept019 add constraint (foreign key (r19_cod_subtipo) 
    references "fobos".gent022 );

alter table "fobos".rept019 add constraint (foreign key (r19_compania,
    r19_vendedor) references "fobos".rept001 );

alter table "fobos".rept019 add constraint (foreign key (r19_compania,
    r19_localidad,r19_oc_interna) references "fobos".ordt010 );
    

alter table "fobos".rept019 add constraint (foreign key (r19_compania,
    r19_localidad,r19_ord_trabajo) references "fobos".talt023 
    );

alter table "fobos".rept019 add constraint (foreign key (r19_compania,
    r19_bodega_ori) references "fobos".rept002 );

alter table "fobos".rept019 add constraint (foreign key (r19_compania,
    r19_bodega_dest) references "fobos".rept002 );

alter table "fobos".rept019 add constraint (foreign key (r19_moneda) 
    references "fobos".gent013 );

alter table "fobos".rept019 add constraint (foreign key (r19_compania,
    r19_localidad,r19_numliq) references "fobos".rept028 );

alter table "fobos".rept019 add constraint (foreign key (r19_usuario) 
    references "fobos".gent005 );

alter table "fobos".rept019 add constraint (foreign key (r19_cod_tran) 
    references "fobos".gent021 );

alter table "fobos".rept019 add constraint (foreign key (r19_compania,
    r19_localidad,r19_num_ret) references "fobos".cxpt027 );

alter table "fobos".cajt011 add constraint (foreign key (j11_compania,
    j11_localidad,j11_tipo_fuente,j11_num_fuente) references 
    "fobos".cajt010 );

alter table "fobos".cajt011 add constraint (foreign key (j11_moneda) 
    references "fobos".gent013 );

alter table "fobos".rolt017 add constraint (foreign key (n17_usuario) 
    references "fobos".gent005  constraint "fobos".fk_01_rolt017);
    

alter table "fobos".t_bal_gen add constraint (foreign key (b11_compania,
    b11_cuenta) references "fobos".ctbt010  constraint "fobos".fk_01_t_bal_gen);
    

alter table "fobos".rept068 add constraint (foreign key (r68_compania,
    r68_localidad,r68_cod_tran,r68_num_tran) references "fobos"
    .rept091  constraint "fobos".fk_01_rept068);

alter table "fobos".rept068 add constraint (foreign key (r68_compania,
    r68_loc_tr,r68_cod_tr,r68_num_tr) references "fobos".rept019 
     constraint "fobos".fk_02_rept068);

alter table "fobos".rept068 add constraint (foreign key (r68_compania,
    r68_loc_tr,r68_cod_tr,r68_num_tr,r68_bodega,r68_item,r68_secuencia) 
    references "fobos".rept020  constraint "fobos".fk_03_rept068);
    

alter table "fobos".rept068 add constraint (foreign key (r68_usuario) 
    references "fobos".gent005  constraint "fobos".fk_04_rept068);
    

alter table "fobos".rept108 add constraint (foreign key (r108_compania) 
    references "fobos".rept000  constraint "fobos".fk_01_rept108);
    

alter table "fobos".rept108 add constraint (foreign key (r108_usuario) 
    references "fobos".gent005  constraint "fobos".fk_02_rept108);
    

alter table "fobos".rept108 add constraint (foreign key (r108_compania,
    r108_localidad,r108_cia_trans) references "fobos".rept116 
     constraint "fobos".fk_03_rept108);

alter table "fobos".rept109 add constraint (foreign key (r109_compania) 
    references "fobos".rept000  constraint "fobos".fk_01_rept109);
    

alter table "fobos".rept109 add constraint (foreign key (r109_compania,
    r109_localidad,r109_cod_zona) references "fobos".rept108  
    constraint "fobos".fk_02_rept109);

alter table "fobos".rept109 add constraint (foreign key (r109_usuario) 
    references "fobos".gent005  constraint "fobos".fk_03_rept109);
    

alter table "fobos".rept109 add constraint (foreign key (r109_pais,
    r109_divi_poli) references "fobos".gent025  constraint "fobos"
    .fk_04_rept109);

alter table "fobos".rept109 add constraint (foreign key (r109_ciudad) 
    references "fobos".gent031  constraint "fobos".fk_05_rept109);
    

alter table "fobos".rept110 add constraint (foreign key (r110_compania) 
    references "fobos".rept000  constraint "fobos".fk_01_rept110);
    

alter table "fobos".rept110 add constraint (foreign key (r110_usuario) 
    references "fobos".gent005  constraint "fobos".fk_02_rept110);
    

alter table "fobos".rept111 add constraint (foreign key (r111_compania,
    r111_localidad,r111_cod_trans) references "fobos".rept110 
     constraint "fobos".fk_01_rept111);

alter table "fobos".rept111 add constraint (foreign key (r111_compania,
    r111_cod_trab) references "fobos".rolt030  constraint "fobos"
    .fk_02_rept111);

alter table "fobos".rept111 add constraint (foreign key (r111_usuario) 
    references "fobos".gent005  constraint "fobos".fk_03_rept111);
    

alter table "fobos".rept112 add constraint (foreign key (r112_compania) 
    references "fobos".rept000  constraint "fobos".fk_01_rept112);
    

alter table "fobos".rept112 add constraint (foreign key (r112_usuario) 
    references "fobos".gent005  constraint "fobos".fk_02_rept112);
    

alter table "fobos".rept114 add constraint (foreign key (r114_codcli) 
    references "fobos".cxct001  constraint "fobos".fk_06_rept114);
    

alter table "fobos".rept114 add constraint (foreign key (r114_compania,
    r114_localidad,r114_num_hojrut) references "fobos".rept113 
     constraint "fobos".fk_01_rept114);

alter table "fobos".rept114 add constraint (foreign key (r114_compania,
    r114_localidad,r114_cod_zona) references "fobos".rept108  
    constraint "fobos".fk_02_rept114);

alter table "fobos".rept114 add constraint (foreign key (r114_compania,
    r114_localidad,r114_cod_zona,r114_cod_subzona) references 
    "fobos".rept109  constraint "fobos".fk_03_rept114);

alter table "fobos".rept114 add constraint (foreign key (r114_compania,
    r114_localidad,r114_cod_obser) references "fobos".rept112 
     constraint "fobos".fk_04_rept114);

alter table "fobos".rept113 add constraint (foreign key (r113_compania,
    r113_localidad,r113_cod_trans) references "fobos".rept110 
     constraint "fobos".fk_01_rept113);

alter table "fobos".rept113 add constraint (foreign key (r113_compania,
    r113_localidad,r113_cod_trans,r113_cod_chofer) references 
    "fobos".rept111  constraint "fobos".fk_02_rept113);

alter table "fobos".rept113 add constraint (foreign key (r113_usuario) 
    references "fobos".gent005  constraint "fobos".fk_03_rept113);
    

alter table "fobos".rept113 add constraint (foreign key (r113_compania,
    r113_localidad,r113_cod_trans,r113_cod_ayud) references "fobos"
    .rept115  constraint "fobos".fk_04_rept113);

alter table "fobos".rept113 add constraint (foreign key (r113_compania,
    r113_areaneg) references "fobos".gent003  constraint "fobos"
    .fk_05_rept113);

alter table "fobos".gent025 add constraint (foreign key (g25_pais) 
    references "fobos".gent030  constraint "fobos".fk_01_gent025);
    

alter table "fobos".gent025 add constraint (foreign key (g25_usuario) 
    references "fobos".gent005  constraint "fobos".fk_02_gent025);
    

alter table "fobos".rept115 add constraint (foreign key (r115_compania,
    r115_localidad,r115_cod_trans) references "fobos".rept110 
     constraint "fobos".fk_01_rept115);

alter table "fobos".rept115 add constraint (foreign key (r115_compania,
    r115_cod_trab) references "fobos".rolt030  constraint "fobos"
    .fk_02_rept115);

alter table "fobos".rept115 add constraint (foreign key (r115_usuario) 
    references "fobos".gent005  constraint "fobos".fk_03_rept115);
    

alter table "fobos".rept116 add constraint (foreign key (r116_usuario) 
    references "fobos".gent005  constraint "fobos".fk_01_rept116);
    

alter table "fobos".rept116 add constraint (foreign key (r116_codprov) 
    references "fobos".cxpt001  constraint "fobos".fk_02_rept116);
    

alter table "fobos".provincia add constraint (foreign key (pais,
    cod_phobos) references "fobos".gent025  constraint "fobos".fk_01_provincia);
    

alter table "fobos".canton add constraint (foreign key (cod_prov) 
    references "fobos".provincia  constraint "fobos".fk_01_canton);
    

alter table "fobos".canton add constraint (foreign key (pais,
    divi_poli) references "fobos".gent025  constraint "fobos".fk_02_canton);
    

alter table "fobos".canton add constraint (foreign key (cod_phobos) 
    references "fobos".gent031  constraint "fobos".fk_03_canton);
    

alter table "fobos".cxpt006 add constraint (foreign key (p06_banco) 
    references "fobos".gent008  constraint "fobos".fk_01_cxpt006);
    

alter table "fobos".cxpt006 add constraint (foreign key (p06_usuario) 
    references "fobos".gent005  constraint "fobos".fk_02_cxpt006);
    


 
load from "fobos.unl" insert into fobos;
load from "dual.unl"  insert into dual;
