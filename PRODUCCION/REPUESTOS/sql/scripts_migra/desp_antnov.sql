insert into rept118
select r20_compania, r20_localidad, r20_cod_tran, r20_num_tran, r20_item,
                                    r20_cod_tran, r20_num_tran, r20_item
  from rept020
 where r20_compania = 1
   and r20_cod_tran IN ('FA', 'DF', 'AF')
   and date(r20_fecing) < mdy(11, 1, 2008)
   and not exists (select 1 from rept118 where r118_compania  = r20_compania
					   and r118_localidad = r20_localidad
					   and r118_cod_fact  = r20_cod_tran
					   and r118_num_fact  = r20_num_tran)
