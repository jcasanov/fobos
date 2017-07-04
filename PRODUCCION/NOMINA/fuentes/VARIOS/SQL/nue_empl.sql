select * from sermaco_gm@segye01:rolt030
        where n30_cod_trab = 13
        into temp t1;
select * from sermaco_gm@segye01:rolt031
        where n31_cod_trab = 13
        into temp t2;
update t1
        set n30_compania    = 1,
            n30_cod_trab    = 139,
	    n30_estado      = 'A',
	    n30_fecha_ing   = mdy(03,16,2010),
	    n30_fecha_reing = null,
	    n30_fecha_sal   = null,
	    n30_cta_empresa = '1030843017',
            n30_usuario     = 'FOBOS',
            n30_fecing      = extend(current, year to second)
        where 1 = 1;
update t2
        set n31_compania = 1,
            n31_cod_trab = 139,
            n31_usuario  = 'FOBOS',
            n31_fecing   = extend(current, year to second)
        where 1 = 1;
begin work;
        insert into acero_gm@idsgye01:rolt030 select * from t1;
        insert into acero_gm@idsgye01:rolt031 select * from t2;
--rollback work;
commit work;
drop table t1;
drop table t2;
