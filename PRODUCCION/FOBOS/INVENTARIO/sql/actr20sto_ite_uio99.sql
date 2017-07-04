set isolation to dirty read;
select r10_codigo item from rept010 where r10_compania = 999 into temp t1;
load from "item_r20_99.unl" insert into t1;
select count(*) tot_item from t1;
select r20_item item, min(r20_fecing) fecha
	from rept020
	where r20_compania  = 1
	  and r20_localidad = 3
	  and r20_bodega    = '99'
	  and r20_item      in (select item from t1)
	group by 1
	into temp tmp_fec;
select r20_compania cia, r20_localidad loc, r20_cod_tran tp, r20_num_tran num,
	r20_bodega bod, trim(r20_item) item, r20_orden orden,
	r20_stock_ant sto_ant
	from rept020, tmp_fec
	where r20_compania  = 1
	  and r20_localidad = 3
	  and r20_bodega    = '99'
	  and r20_item      in (select item from t1)
	  and item          = r20_item
	  and fecha         = r20_fecing
	into temp t2;
drop table t1;
drop table tmp_fec;
select count(*) tot_reg from t2;
--select * from t2;
begin work;
	update rept020
		set r20_stock_ant = 0
		where r20_compania  = 1
		  and r20_localidad = 3
		  and r20_bodega    = '99'
		  and r20_item      = (select item from t2
					where cia   = r20_compania
					  and loc   = r20_localidad
					  and tp    = r20_cod_tran
					  and num   = r20_num_tran
					  and bod   = r20_bodega
					  and item  = r20_item
					  and orden = r20_orden);
commit work;
drop table t2;
