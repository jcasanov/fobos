select r38_num_sri num_sri, r38_num_tran num, r38_num_sri num_ant,
        (select r19_fecing
                from rept019
                where r19_compania  = r38_compania
                  and r19_localidad = r38_localidad
                  and r19_cod_tran  = r38_cod_tran
                  and r19_num_tran  = r38_num_tran) fecha
        from rept038
        where r38_num_sri[11,15] >= '84501'
          and r38_num_sri[11,15] <= '89500'
        into temp t1;
select num_sri[1, 3] || num_sri[5, 7] || num_sri[11,15] num_sri, num, num_ant
	from t1
        where year(fecha) = 2005
        into temp t2;
drop table t1;
--select * from t2 order by 1;
begin work;
	update rept038
		set r38_num_sri = (select num_sri
					from t2
					where num_ant = r38_num_sri
					  and num     = r38_num_tran)
		where exists
			(select 1 from t2
				where num_ant = r38_num_sri
				  and num     = r38_num_tran);
--rollback work;
commit work;
drop table t2;
