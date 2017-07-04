select n45_compania cia, n45_num_prest num_p, n46_secuencia sec,
	n46_cod_liqrol lq, n46_fecha_ini fec_ini, n46_fecha_fin fec_fin,
	n46_valor valor
	from rolt046, rolt045
	where n46_compania  = 1
	  and n46_fecha_fin < mdy(06, 15, 2007)
	  and n46_saldo     > 0
	  and n45_compania  = n46_compania
	  and n45_num_prest = n46_num_prest
	  and n45_estado    in ('A', 'R', 'P')
	into temp t1;

begin work;

update rolt046
	set n46_saldo = 0
	where exists (select * from t1
			where cia   = n46_compania
			  and num_p = n46_num_prest
			  and sec   = n46_secuencia);

select cia, num_p, nvl(sum(valor), 0) sal_f from t1 group by 1, 2 into temp t2;

drop table t1;

update rolt045
	set n45_descontado = n45_descontado +
				nvl((select sal_f from t2
					where cia   = n45_compania
					  and num_p = n45_num_prest), 0)
	where exists (select * from t2
			where cia   = n45_compania
			  and num_p = n45_num_prest);

update rolt045
	set n45_descontado = n45_val_prest
	where n45_val_prest - n45_descontado < 0
	   or n45_descontado > n45_val_prest;

update rolt045
	set n45_estado = 'P'
	where n45_val_prest = n45_descontado
	  and exists (select * from t2
			where cia   = n45_compania
			  and num_p = n45_num_prest);

update rolt045
	set n45_estado = 'P'
	where n45_estado in ('A', 'R')
	  and exists (select sum(n46_saldo)
			from rolt046
			where n46_compania  = n45_compania
			  and n46_num_prest = n45_num_prest
			having sum(n46_saldo) = 0);

commit work;

drop table t2;
