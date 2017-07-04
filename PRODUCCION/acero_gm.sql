{ DATABASE acero_gm  delimiter | }

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

	-- METODO: 1 (Método Europeo)	0 (Método EEUU - (NASD))
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
{ unload file name = gent000100.unl number of rows = 1 }

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
{ unload file name = gent000101.unl number of rows = 1 }

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
{ unload file name = gent000102.unl number of rows = 2 }

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
{ unload file name = gent000103.unl number of rows = 13 }

create table "fobos".gent004 
  (
    g04_grupo char(2) not null ,
    g04_nombre varchar(40,20) not null ,
    g04_ver_costo char(1) not null ,
    
    check (g04_ver_costo IN ('S' ,'N' ))
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".gent004 from "public";

{ TABLE "fobos".gent005 row size = 67 number of columns = 7 index size = 31 }
{ unload file name = gent000104.unl number of rows = 148 }

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
{ unload file name = gent000105.unl number of rows = 1088 }

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
{ unload file name = gent000106.unl number of rows = 9 }

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
{ unload file name = gent000107.unl number of rows = 22 }

create table "fobos".gent011 
  (
    g11_tiporeg char(2) not null ,
    g11_nombre varchar(30,15) not null ,
    g11_usuario varchar(10,5) not null ,
    g11_fecing datetime year to second not null 
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".gent011 from "public";

{ TABLE "fobos".gent012 row size = 54 number of columns = 5 index size = 43 }
{ unload file name = gent000108.unl number of rows = 89 }

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
{ unload file name = gent000109.unl number of rows = 14 }

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
{ unload file name = gent000110.unl number of rows = 0 }

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
{ unload file name = gent000111.unl number of rows = 28 }

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
{ unload file name = gent000112.unl number of rows = 31 }

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
{ unload file name = gent000113.unl number of rows = 1 }

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
{ unload file name = gent000114.unl number of rows = 14 }

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
{ unload file name = gent000115.unl number of rows = 2 }

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
{ unload file name = gent000116.unl number of rows = 623 }

create table "fobos".gent052 
  (
    g52_modulo char(2) not null ,
    g52_usuario varchar(10,5) not null ,
    g52_estado char(1) not null ,
    
    check (g52_estado IN ('A' ,'B' ))
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".gent052 from "public";

{ TABLE "fobos".gent053 row size = 17 number of columns = 3 index size = 75 }
{ unload file name = gent000117.unl number of rows = 619 }

create table "fobos".gent053 
  (
    g53_modulo char(2) not null ,
    g53_usuario varchar(10,5) not null ,
    g53_compania integer not null 
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".gent053 from "public";

{ TABLE "fobos".gent054 row size = 84 number of columns = 7 index size = 55 }
{ unload file name = gent000118.unl number of rows = 529 }

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
{ unload file name = talt000119.unl number of rows = 1 }

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
{ unload file name = talt000120.unl number of rows = 1 }

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
{ unload file name = dual_00121.unl number of rows = 1 }

create table "fobos".dual 
  (
    nulo char(1) not null 
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".dual from "public";

{ TABLE "fobos".gent013 row size = 44 number of columns = 7 index size = 31 }
{ unload file name = gent000122.unl number of rows = 16 }

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
{ unload file name = gent000123.unl number of rows = 415 }

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
{ unload file name = gent000124.unl number of rows = 30 }

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
{ unload file name = gent000125.unl number of rows = 21 }

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
{ unload file name = gent000126.unl number of rows = 3 }

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
{ unload file name = fobos00127.unl number of rows = 1 }

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
{ unload file name = gent000128.unl number of rows = 9 }

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
{ unload file name = gent000129.unl number of rows = 2 }

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
{ unload file name = gent000130.unl number of rows = 33354 }

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
{ unload file name = gent000131.unl number of rows = 57 }

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
{ unload file name = gent000132.unl number of rows = 38 }

create table "fobos".gent008 
  (
    g08_banco integer not null ,
    g08_nombre varchar(30,15) not null ,
    g08_usuario varchar(10,5) not null ,
    g08_fecing datetime year to second not null 
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".gent008 from "public";

{ TABLE "fobos".gent030 row size = 52 number of columns = 5 index size = 34 }
{ unload file name = gent000133.unl number of rows = 27 }

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
{ unload file name = gent000134.unl number of rows = 1 }

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
{ unload file name = talt000135.unl number of rows = 15 }

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
{ unload file name = talt000136.unl number of rows = 5 }

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
{ unload file name = talt000137.unl number of rows = 5 }

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
{ unload file name = talt000138.unl number of rows = 5 }

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
{ unload file name = talt000139.unl number of rows = 0 }

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
{ unload file name = talt000140.unl number of rows = 0 }

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
{ unload file name = rept000141.unl number of rows = 1 }

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
{ unload file name = rept000142.unl number of rows = 103 }

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
{ unload file name = rept000143.unl number of rows = 62 }

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
{ unload file name = rept000144.unl number of rows = 10 }

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
{ unload file name = rept000145.unl number of rows = 1 }

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
{ unload file name = rept000146.unl number of rows = 18 }

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
{ unload file name = rept000147.unl number of rows = 7 }

create table "fobos".rept006 
  (
    r06_codigo smallint not null ,
    r06_nombre char(10) not null ,
    r06_usuario varchar(10,5) not null ,
    r06_fecing datetime year to second not null 
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".rept006 from "public";

{ TABLE "fobos".rept007 row size = 33 number of columns = 8 index size = 52 }
{ unload file name = rept000148.unl number of rows = 0 }

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
{ unload file name = rept000149.unl number of rows = 0 }

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
{ unload file name = rept000150.unl number of rows = 164067 }

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
{ unload file name = rept000151.unl number of rows = 202517 }

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
{ unload file name = rept000152.unl number of rows = 0 }

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
{ unload file name = rept000153.unl number of rows = 0 }

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
{ unload file name = rept000154.unl number of rows = 0 }

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
{ unload file name = rept000155.unl number of rows = 4 }

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
{ unload file name = rept000156.unl number of rows = 0 }

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
{ unload file name = rept000157.unl number of rows = 477923 }

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

