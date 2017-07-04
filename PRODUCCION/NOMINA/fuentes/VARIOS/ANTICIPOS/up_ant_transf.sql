select n45_compania cia, n45_num_prest num_prest, n45_val_prest saldo
	from rolt045
	where n45_compania  in (1, 2)
	  and n45_estado     = 'T'
	  and n45_val_prest  = 0
	  and ((n45_val_prest - n45_descontado <> 0)
	   or  (n45_val_prest - (n45_descontado + n45_sal_prest_ant)) <> 0)
union
select n45_compania cia, n45_num_prest num_prest, n45_val_prest saldo
	from rolt045
	where n45_compania  in (1, 2)
	  and n45_estado     = 'T'
	  and exists (select 1 from rolt045 a
			where a.n45_compania   = n45_compania
			  and a.n45_prest_tran = n45_prest_tran
	  		  and a.n45_val_prest  = 0)
	into temp t1;

select count(*) tot_t1 from t1;

select cia, num_prest, n58_proceso proceso, n58_num_div divid
	from t1, rolt058
	where n58_compania    = cia
	  and n58_num_prest   = num_prest
	  and (n58_saldo_dist > 0
	   or  n58_div_act    < n58_num_div)
	into temp t2;

select count(*) tot_t2 from t2;

begin work;

update rolt045
	set n45_descontado = (select saldo from t1
				where cia       = n45_compania
				  and num_prest = n45_num_prest)
	where n45_compania  in (1, 2)
	  and n45_estado     = 'T'
	  and exists (select cia, num_prest
			from t1
			where cia       = n45_compania
			  and num_prest = n45_num_prest);

update rolt046
	set n46_saldo = 0
	where n46_compania in (1, 2)
	  and n46_saldo     > 0
	  and exists (select cia, num_prest
			from t1
			where cia       = n46_compania
			  and num_prest = n46_num_prest);

update rolt058
	set n58_div_act    = (select divid from t2
				where cia       = n58_compania
				  and num_prest = n58_num_prest
				  and proceso   = n58_proceso),
	    n58_saldo_dist = 0
	where n58_compania in (1, 2)
	  and exists (select cia, num_prest, proceso
			from t2
			where cia       = n58_compania
			  and num_prest = n58_num_prest
			  and proceso   = n58_proceso);

commit work;

drop table t1;

drop table t2;
