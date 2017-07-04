select  a.b13_cuenta cuenta,
	a.b13_tipo_comp tp, a.b13_num_comp num, a.b13_valor_base v1,
        b.b13_valor_base v2, ma.b12_estado e1, mb.b12_estado e2,
	year(ma.b12_fecing) y1, year(mb.b12_fecing) y2

        from
                acero_qm@acuiopr:ctbt013 a, acero_qm@idsuio01:ctbt013 b,
                acero_qm@acuiopr:ctbt012 ma, acero_qm@idsuio01:ctbt012 mb
        where (b.b13_cuenta     matches '114*' or b.b13_cuenta matches '6*')
          and year(b.b13_fec_proceso) = 2009
          and a.b13_compania    = b.b13_compania
          and a.b13_tipo_comp   = b.b13_tipo_comp
          and a.b13_num_comp    = b.b13_num_comp
          and a.b13_secuencia   = b.b13_secuencia
           -- a.b13_valor_base <> b.b13_valor_base
          and a.b13_cuenta      = b.b13_cuenta
	  and year(ma.b12_fecing) = year(mb.b12_fecing)

          and ma.b12_compania   = a.b13_compania
          and ma.b12_tipo_comp  = a.b13_tipo_comp
          and ma.b12_num_comp   = a.b13_num_comp

          and mb.b12_compania   = b.b13_compania
          and mb.b12_tipo_comp  = b.b13_tipo_comp
          and mb.b12_num_comp   = b.b13_num_comp
--          and ma.b12_estado     <> mb.b12_estado
into temp t1;
select sum(v1) total_prod, sum(v2) total_pru, cuenta, e1, y1 from t1 group by 3,4,5 order by 5;
drop table t1;

select "PRUE" servidor, a.b13_cuenta cuenta, 
	a.b13_tipo_comp tp, a.b13_num_comp num, a.b13_valor_base v1, 
	ma.b12_estado e1, year(ma.b12_fecing) anio_ing, ma.b12_origen ori
        from
                acero_qm@acuiopr:ctbt013 a,
                acero_qm@acuiopr:ctbt012 ma
        where (a.b13_cuenta     matches '114*' or a.b13_cuenta matches '6*')

          and ma.b12_compania   = a.b13_compania
          and ma.b12_tipo_comp  = a.b13_tipo_comp
          and ma.b12_num_comp   = a.b13_num_comp
	  and year(a.b13_fec_proceso) = 2009
UNION
select "PROD" servidor, a.b13_cuenta cuenta,
	a.b13_tipo_comp tp, a.b13_num_comp num, a.b13_valor_base v1, 
	ma.b12_estado e1, year(ma.b12_fecing) anio_ing, ma.b12_origen ori
        from
                acero_qm@idsuio01:ctbt013 a,
                acero_qm@idsuio01:ctbt012 ma
        where (a.b13_cuenta     matches '114*' or a.b13_cuenta matches '6*')

          and ma.b12_compania   = a.b13_compania
          and ma.b12_tipo_comp  = a.b13_tipo_comp
          and ma.b12_num_comp   = a.b13_num_comp
	  and year(a.b13_fec_proceso) = 2009
into temp t1;
select sum(v1) total_prod, cuenta, servidor, e1, anio_ing, ori from t1 group by 2,3,4,5,6 order by 

6,5,4,2,3;
drop table t1;
