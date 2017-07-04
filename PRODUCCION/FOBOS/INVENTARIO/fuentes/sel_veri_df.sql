select r19_cod_tran, r19_num_tran, r34_num_ord_des, r34_bodega,
	r19_tipo_dev, r19_num_dev, r19_localidad
        from rept019, rept034
        where r19_compania     = 1
          and r19_localidad    = 3
	  and r19_cod_tran     = 'FA'
          and r19_tipo_dev     is not null
          and r34_compania     = r19_compania
          and r34_localidad    = r19_localidad
          and r34_cod_tran     = r19_cod_tran
          and r34_num_tran     = r19_num_tran
          and r34_bodega       = '99'
          and r34_estado       not in ('A', 'E')
	into temp t1;
select r36_num_ord_des, count(*) hay
	from rept036, t1
        where r36_compania     = 1
          and r36_localidad    = r19_localidad
	  and r36_bodega       = r34_bodega
          and r36_num_ord_des  = r34_num_ord_des
	group by 1
	having count(*)       <= 1
	into temp t2;
delete from t1 where r34_num_ord_des in (select r36_num_ord_des from t2);
drop table t2;
select r20_cod_tran cod_dev, r20_num_tran num_dev
	from rept020
	where r20_compania     = 1
	  and r20_localidad    = 3
	  and r20_cod_tran     in (select unique r19_tipo_dev from t1)
	  and r20_num_tran     in (select r19_num_dev from t1)
	  and r20_bodega       not in (select unique r34_bodega from t1)
	into temp t3;
delete from t1
	where r19_tipo_dev in (select unique cod_dev from t3)
	  and r19_num_dev  in (select num_dev from t3);
drop table t3;
select count(*) total_fact from t1;
select r19_cod_tran, r19_num_tran from t1 order by 2 desc;
drop table t1;
