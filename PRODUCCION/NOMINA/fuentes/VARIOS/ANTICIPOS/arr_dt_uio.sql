select n45_compania cia, n45_num_prest num, n46_secuencia sec,
	case when n45_estado = 'P' and n45_prest_tran is not null
		then 'R'
	     when n45_estado = 'P' and n45_prest_tran is null
		then 'A'
		else n45_estado
	end est, n45_prest_tran num_a, n46_valor valor
	from rolt045, rolt046
	where n45_compania   = 1
	  and n45_estado     not in ('T', 'E')
	  and n46_compania   = n45_compania
	  and n46_num_prest  = n45_num_prest
	  and n46_cod_liqrol = 'DT'
	  and n46_fecha_fin  = mdy(11,30,2009)
	  and n46_valor      <> n46_saldo
	into temp t1;
begin work;
	update rolt045
		set n45_estado = (select est
					from t1
					where cia = n45_compania
					  and num = n45_num_prest)
		where n45_compania   = 1
		  and n45_estado     not in ('T', 'E')
		  and n45_num_prest  in (select num from t1);
	update rolt046
		set n46_saldo = (select valor
					from t1
					where cia = n46_compania
					  and num = n46_num_prest
					  and sec = n46_secuencia)
		where n46_compania   = 1
		  and n46_num_prest  in (select num from t1)
		  and n46_cod_liqrol = 'DT'
		  and n46_fecha_fin  = mdy(11,30,2009)
		  and n46_valor      <> n46_saldo;
commit work;
drop table t1;
