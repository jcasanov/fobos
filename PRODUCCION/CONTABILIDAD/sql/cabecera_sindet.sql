select b12_tipo_comp, b12_num_comp, b12_fec_proceso, b12_fecing, b12_glosa,
	b12_usuario, date(b12_fec_modifi) fec_mod, b12_estado, b12_origen,
	b13_valor_base
	from ctbt012, ctbt013
	where b12_compania           = 1
	  and b12_estado            <> 'E'
	  and year(b12_fec_proceso) >= 2006
	  and b13_compania           = b12_compania  
	  and b13_tipo_comp          = b12_tipo_comp
          and b13_num_comp           = b12_num_comp
	into temp t1;
--delete from t1 where b13_valor_base is not null; -- and b13_valor_base <> 0;
delete from t1 where b13_valor_base <> 0;
select count(*) total from t1 where b12_origen = 'M';
select * from t1 where b12_origen = 'M' order by b12_fec_proceso;
select count(*) total from t1 where b12_tipo_comp = 'DR';
select * from t1 where b12_tipo_comp = 'DR' order by b12_fec_proceso;
select count(*) total from t1 where fec_mod is null;
--select * from t1 where fec_mod is null order by b12_fecing;
{
select count(*) total from t1;
unload to "diario_sindet.txt"
}
select b12_tipo_comp, b12_num_comp, b12_fec_proceso, fec_mod, b12_origen,
	b12_glosa, b12_usuario
	from t1 order by b12_fec_proceso;
drop table t1;
