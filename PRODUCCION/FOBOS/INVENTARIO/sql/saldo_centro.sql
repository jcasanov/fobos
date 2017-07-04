select round(nvl(sum(case when r20_cod_tran = 'FA' or r20_cod_tran = 'A+'
				then r20_cant_ven * r20_costo
				else (r20_cant_ven * r20_costo) * (-1)
			end), 0), 2) sal_inv
	from rept019, rept020
	where r19_compania   = 1
	  and r19_localidad  = 2
	  --and r19_cod_tran  in ('FA', 'DF', 'AF')
	  and r19_cod_tran  <> 'TR'
	  and r20_compania   = r19_compania
	  and r20_localidad  = r19_localidad
	  and r20_cod_tran   = r19_cod_tran
	  and r20_num_tran   = r19_num_tran
--and r20_item = '10126'
union
select round(nvl(sum(case when r19_bodega_dest = '70' --or r19_bodega_dest = '79'
				then r20_cant_ven * r20_costo
				else (r20_cant_ven * r20_costo) * (-1)
			end), 0), 2) * (-1) sal_inv
	from rept019, rept020
	where r19_compania    = 1
	  and r19_localidad   = 2
	  and r19_cod_tran    = 'TR'
	  and r19_bodega_dest = '70'
	  and r20_compania    = r19_compania
	  and r20_localidad   = r19_localidad
	  and r20_cod_tran    = r19_cod_tran
	  and r20_num_tran    = r19_num_tran
--and r20_item = '10126'
into temp t1;
select round(sum(sal_inv), 2) saldo_inv from t1;
drop table t1;
