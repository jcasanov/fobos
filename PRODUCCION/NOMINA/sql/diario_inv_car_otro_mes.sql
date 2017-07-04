--op table t1;
select b12_tipo_comp tp, b12_num_comp num, b12_subtipo sp,
	b12_fec_proceso fec_pro, b12_fecing fecha, nvl(sum(b13_valor_base), 0)
	valor
	from ctbt012, ctbt013
	where b12_compania           = 1
	  and b12_tipo_comp          = 'DR'
	  and b12_estado             <> 'E'
	  and b12_origen             = 'A'
	  and year(b12_fec_proceso)  = 2006
	  and month(b12_fec_proceso) <> month(b12_fecing)
          and month(b12_fec_proceso) = 11
	  and date(b12_fecing) - date(b12_fec_proceso) > 2
	  and b13_compania           = b12_compania
	  and b13_tipo_comp          = b12_tipo_comp
	  and b13_num_comp           = b12_num_comp
	  and b13_cuenta             = '41010103001'
	group by 1, 2, 3, 4, 5
	into temp t1;
select count(*) total from t1;
select round(sum(valor), 2) total from t1;
select * from t1 order by fec_pro;
drop table t1;
