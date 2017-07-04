select n10_cod_trab codtrab, n10_valor valor
	from rolt010
	where n10_compania = 999
	into temp t1;
load from "mov_nov13.unl" delimiter "," insert into t1;
select nvl(n10_compania, 1) cia, nvl(n10_cod_liqrol, 'Q2') liq,
	nvl(n10_cod_rubro, (select n06_cod_rubro
				from rolt006
				where n06_estado     = 'A'
				  and n06_flag_ident = 'MO')) rubro,
	codtrab, n10_fecha_ini, n10_fecha_fin, valor,
	nvl(n10_usuario, 'FOBOS') usuario, nvl(n10_fecing, current) fecing
	from t1, outer rolt010
	where n10_compania   = 1
	  and n10_cod_liqrol = 'Q2'
	  and n10_cod_rubro  = (select n06_cod_rubro
				from rolt006
				where n06_estado     = 'A'
				  and n06_flag_ident = 'MO')
	  and n10_cod_trab   = codtrab
	into temp t2;
drop table t1;
--select * from t2;
begin work;
	delete from rolt010
		where exists
			(select * from t2
			where t2.cia     = rolt010.n10_compania
			  and t2.liq     = rolt010.n10_cod_liqrol
			  and t2.rubro   = rolt010.n10_cod_rubro
			  and t2.codtrab = rolt010.n10_cod_trab);
	insert into rolt010
		(n10_compania, n10_cod_liqrol, n10_cod_rubro, n10_cod_trab,
		 n10_fecha_ini, n10_fecha_fin, n10_valor, n10_usuario,
		 n10_fecing)
		select * from t2;
commit work;
drop table t2;
