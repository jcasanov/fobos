--set isolation to dirty read;
select b13_cuenta, sum(b13_valor_base)
        from ctbt012, ctbt013
        where b12_compania  = 1
          and b12_estado    <> 'E'
          and year(b12_fec_proceso) = 2009
          and b13_compania    = b12_compania
          and b13_tipo_comp   = b12_tipo_comp
          and b13_num_comp    = b12_num_comp
          and b13_cuenta      in ('11400101001', '61010101001')
        group by 1;
select count(*) tot_dia
        from ctbt012, ctbt013
        where b12_compania  = 1
          and b12_estado    <> 'E'
          and year(b12_fec_proceso) = 2009
          and b13_compania    = b12_compania
          and b13_tipo_comp   = b12_tipo_comp
          and b13_num_comp    = b12_num_comp
          and b13_cuenta      in ('11400101001', '61010101001');
select a.b12_tipo_comp tp, a.b12_num_comp num, b.b12_fec_proceso fec
        from acero_qm@acuiopr:ctbt012 a, acero_qm@idsuio01:ctbt012 b
        where a.b12_compania  = 1
          and year(a.b12_fec_proceso) = 2009
          and a.b12_compania    = b.b12_compania
          and a.b12_tipo_comp   = b.b12_tipo_comp
          and a.b12_num_comp    = b.b12_num_comp
          and a.b12_estado    <> b.b12_estado;
select a.b13_tipo_comp tp, a.b13_num_comp num, a.b13_cuenta,
	a.b13_valor_base v1, b.b13_valor_base v2, b12_estado est
        from acero_qm@acuiopr:ctbt012, acero_qm@acuiopr:ctbt013 a,
		outer acero_qm@idsuio01:ctbt013 b
	where b12_compania           = 1
	  and b12_estado            <> 'E'
          and year(b12_fec_proceso)  = 2009
          and a.b13_compania         = b12_compania
          and a.b13_tipo_comp        = b12_tipo_comp
          and a.b13_num_comp         = b12_num_comp
          and b.b13_compania         = a.b13_compania
          and b.b13_tipo_comp        = a.b13_tipo_comp
          and b.b13_num_comp         = a.b13_num_comp
          and b.b13_secuencia        = a.b13_secuencia
          and b.b13_cuenta           = a.b13_cuenta
          and b.b13_valor_base      <> a.b13_valor_base
	  and b.b13_valor_base      is null
          and b.b13_cuenta          in ('11400101001', '61010101001')
	order by 5;
