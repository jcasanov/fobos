set isolation to dirty read;
select j10_compania cia, j10_localidad loc, j10_tipo_fuente tip_f,
	j10_num_fuente num_f, j10_valor val_cab, nvl(sum(j11_valor), 0) valor
	from cajt010, cajt011
	where j10_compania    = 1
	  and j10_tipo_fuente = 'SC'
	  and j11_compania    = j10_compania
	  and j11_localidad   = j10_localidad
	  and j11_tipo_fuente = j10_tipo_fuente
	  and j11_num_fuente  = j10_num_fuente
	group by 1, 2, 3, 4, 5
	having sum(j11_valor) <> j10_valor
	into temp t1;
select count(*) tot_reg from t1;
select loc, tip_f, num_f, val_cab, valor
	from t1
	order by 1, 3;
--
begin work;
	update cajt010
		set j10_valor = (select valor
					from t1
					where cia   = j10_compania
					  and loc   = j10_localidad
					  and tip_f = j10_tipo_fuente
					  and num_f = j10_num_fuente)
		where j10_compania    = 1
		  and j10_tipo_fuente = 'SC'
		  and exists
			(select 1 from t1
				where cia    = j10_compania
				  and loc    = j10_localidad
				  and tip_f  = j10_tipo_fuente
				  and num_f  = j10_num_fuente
				  and valor <> j10_valor);
--rollback work;
commit work;
--
drop table t1;
