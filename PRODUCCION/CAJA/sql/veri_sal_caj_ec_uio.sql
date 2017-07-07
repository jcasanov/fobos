select j11_localidad loc, j10_codigo_caja cod_caj, j11_num_egreso num_ec,
        sum(j11_valor) valor_ch
        from cajt011, cajt010
        where ((j11_localidad   = 3
          and   j11_num_egreso  between 938 and 951)
           or  (j11_localidad   = 4
          and   j11_num_egreso  > 9)
           or  (j11_localidad   = 5
          and   j11_num_egreso  > 5))
          and   j10_compania    = j11_compania
          and   j10_localidad   = j11_localidad
          and   j10_tipo_fuente = "EC"
          and   j10_num_fuente  = j11_num_egreso
        group by 1, 2, 3
        order by 1, 2, 3;
select j10_localidad loc, j10_codigo_caja cod_caj, j10_num_fuente num_ec,
        sum(j10_valor) valor_ef
        from cajt010
        where   j10_compania    = 1
          and   j10_tipo_fuente = "EC"
          and ((j10_localidad   = 3
          and   j10_num_fuente  between 926 and 937)
           or  (j10_localidad   = 4
          and   j10_num_fuente  between 1 and 9)
           or  (j10_localidad   = 5
          and   j10_num_fuente  between 2 and 5))
        group by 1, 2, 3
        order by 1, 2, 3;