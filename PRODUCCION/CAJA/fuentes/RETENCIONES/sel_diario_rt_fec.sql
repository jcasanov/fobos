select b12_tipo_comp tp, b12_num_comp num, b12_fecing fec_ing,
        b13_cuenta cuenta, b13_valor_base valor, b12_usuario usuario,
        b12_estado est
        from ctbt012, ctbt013
        where b12_compania      = 1
          and b12_fec_proceso  between mdy(10, 01, 2008)
                                   and mdy(10, 31, 2008)
          and date(b12_fecing) >= mdy(11, 01, 2008) + 45 units day
          and b13_compania      = b12_compania
          and b13_tipo_comp     = b12_tipo_comp
          and b13_num_comp      = b12_num_comp
          and b13_cuenta       matches '11300201*'
        into temp t1;
select * from t1 order by 3;
select round(sum(valor), 2) total from t1;
drop table t1;
