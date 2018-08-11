select p22_fecing fecha, count(*) total
	from cxpt022
	group by 1
	having count(*) > 1
	into temp t1;
select count(*) total_repe from t1;
select lpad(p22_codprov, 5) prov, p01_nomprov[1, 30] proveedor,
	p22_tipo_trn tipo, p22_num_trn num, p22_fecing fecha
	from cxpt022, cxpt001
	where p22_fecing  in(select fecha from t1)
	  and p01_codprov = p22_codprov
	order by 2, 5, 3, 4;
drop table t1;
