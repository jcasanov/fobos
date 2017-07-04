select n30_num_doc_id, n30_nombres, nvl(sum(n33_valor), 0) valor,
	n06_nombre_abr, n33_cod_rubro
	from rolt033, rolt030, rolt006
	where n33_compania    = 1
	  and n33_cod_liqrol in ('Q1', 'Q2')
	  and n33_fecha_ini  >= mdy(12, 01, 2004)
	  and n33_fecha_fin  <= mdy(12, 31, 2004)
	  and n33_cod_rubro  in (8, 10, 13, 17)
	  and n30_compania    = n33_compania
	  and n30_cod_trab    = n33_cod_trab
	  and n06_cod_rubro   = n33_cod_rubro
	group by 1, 2, 4, 5
	having nvl(sum(n33_valor), 0) > 0
	into temp t1;
select n30_num_doc_id, n30_nombres, nvl(sum(valor), 0) valor_emp
	from t1
	where n33_cod_rubro in (8, 10)
	group by 1, 2
	into temp t2;
delete from t1 where n33_cod_rubro in (8, 10);
insert into t1 select *, "V. H. EXT." nom_abr,  810 cod_rub from t2;
drop table t2;
unload to "empl_he.txt"
	select n30_num_doc_id, n30_nombres, valor, n06_nombre_abr
 		from t1
		order by 2;
drop table t1;
