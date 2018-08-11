select p06_compania as cia,
	p06_cod_bco_tra as codigo,
	p06_banco as banco,
	p06_estado as est,
	p06_usuario usua
	from cxpt006
	where p06_compania = 999
	into temp t1;

load from "cxpt006_gm.csv" delimiter "," insert into t1;

insert into "fobos".cxpt006
	(p06_compania, p06_cod_bco_tra, p06_banco, p06_estado, p06_usuario,
	 p06_fecing)
	select t1.*, current
		from t1;

drop table t1;
