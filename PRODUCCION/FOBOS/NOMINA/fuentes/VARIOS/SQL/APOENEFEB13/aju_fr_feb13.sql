select n30_num_doc_id ced, n30_sueldo_mes aju
	from rolt030
	where n30_compania = 999
	into temp t1;

load from "aj_suel_13.unl" insert into t1;

select n38_compania cia, n38_fecha_ini fec_i, n38_fecha_fin fec_f,
	n38_cod_trab cod_t, (n38_ganado_per - aju) tot_gan,
	((n38_ganado_per - aju) * 8.33 / 100) val_fr
	from rolt038, rolt030, t1
	where n38_compania  = 1
	  and n38_fecha_ini = mdy(02, 01, 2013)
	  and n38_fecha_fin = mdy(02, 28, 2013)
	  and n30_compania  = n38_compania
	  and n30_cod_trab  = n38_cod_trab
	  and ced           = n30_num_doc_id
	into temp emp_fr;

drop table t1;

select round(sum(tot_gan), 2) tot_gan, round(sum(val_fr), 2) tot_fr
	from emp_fr;

begin work;

	update rolt038
		set n38_ganado_per  = (select tot_gan
					from emp_fr
					where cia   = n38_compania
					  and fec_i = n38_fecha_ini
					  and fec_f = n38_fecha_fin
					  and cod_t = n38_cod_trab),
		    n38_valor_fondo = (select val_fr
					from emp_fr
					where cia   = n38_compania
					  and fec_i = n38_fecha_ini
					  and fec_f = n38_fecha_fin
					  and cod_t = n38_cod_trab)
		where n38_compania   = 1
		  and n38_fecha_ini  = mdy(02, 01, 2013)
		  and n38_fecha_fin  = mdy(02, 28, 2013)
		  and n38_cod_trab  in (select cod_t from emp_fr);

	select round(sum(n38_ganado_per), 2) tot_gan_f,
		round(sum(n38_valor_fondo), 2) tot_val_f
		from rolt038
		where n38_compania   = 1
		  and n38_fecha_ini  = mdy(02, 01, 2013)
		  and n38_fecha_fin  = mdy(02, 28, 2013);

--rollback work;
commit work;

drop table emp_fr;
