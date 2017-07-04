select n30_num_doc_id ced, n30_sueldo_mes aju
	from rolt030
	where n30_compania = 999
	into temp t1;

create temp table temp_aj
	(
		rucpat		varchar(13),
		codigo		char(4),
		anio		char(4),
		mes		char(2),
		codins		char(3),
		cedemp		varchar(10),
		valor		decimal(12,2),
		tipo		char(1)
	);

load from "aj_suel_13.unl" insert into t1;

load from "extras_ene13_ori.txt" delimiter ";" insert into temp_aj;

select * from temp_aj;

select lpad(n27_cedula_trab, 10, "0000000000") cedula,
	n30_nombres empleados, n27_valor_net val_sub,
	nvl(aju, 0.00) difer,
	(n27_valor_net - nvl(aju, 0.00)) val_aju
	from rolt027, rolt030, outer t1
	where  n27_compania    = 1
	  and  n27_ano_proceso = 2013
	  and  n27_mes_proceso = 1
	  and  n27_codigo_arch = 2
	  and  n30_compania    = n27_compania
	  and (n30_num_doc_id  = n27_cedula_trab
	   or  n30_carnet_seg  = n27_cedula_trab)
	  and  ced             = n30_num_doc_id
	into temp t2;

drop table t1;

{--
select temp_aj.*, cedula
	from temp_aj, outer t2
	where cedula = cedemp
	order by cedula;
--}

unload to "emp_val_ext_ene13.unl" select * from t2 order by 2;

unload to "extras_ene13_aju.txt" delimiter ";"
	select rucpat, codigo, anio, mes, codins, cedemp,
		lpad(val_aju, 14, "00000000000000") val_aju, tipo
		from temp_aj, t2
		where cedula  = cedemp
		  and val_aju > 0;

drop table t2;

drop table temp_aj;
