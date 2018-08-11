select n30_cod_trab CODIGO, n30_nombres EMPLEADOS, n32_ano_proceso ANIOS,
        case when month(n32_fecha_fin) = 01 then "ENERO"
             when month(n32_fecha_fin) = 02 then "FEBRERO"
             when month(n32_fecha_fin) = 03 then "MARZO"
             when month(n32_fecha_fin) = 04 then "ABRIL"
             when month(n32_fecha_fin) = 05 then "MAYO"
             when month(n32_fecha_fin) = 06 then "JUNIO"
             when month(n32_fecha_fin) = 07 then "JULIO"
             when month(n32_fecha_fin) = 08 then "AGOSTO"
             when month(n32_fecha_fin) = 09 then "SEPTIEMBRE"
             when month(n32_fecha_fin) = 10 then "OCTUBRE"
             when month(n32_fecha_fin) = 11 then "NOVIEMBRE"
             when month(n32_fecha_fin) = 12 then "DICIEMBRE"
        end MESES, n30_nombres EMPLEADO,
        nvl(sum(n33_valor), 0) VALOR
        from rolt030, rolt032, rolt033
        where n30_compania    = 1
          and n30_estado      = 'A'
          and n32_compania    = n30_compania
          and n32_cod_liqrol in ('Q1', 'Q2')
          and n32_cod_trab    = n30_cod_trab
          and n32_estado     <> 'E'
	  and n33_compania    = n32_compania
          and n33_cod_liqrol  = n32_cod_liqrol
          and n33_fecha_ini   = n32_fecha_ini
          and n33_fecha_fin   = n32_fecha_fin
          and n33_cod_trab    = n32_cod_trab
          and n33_cod_rubro  in (select n06_cod_rubro
                                        from rolt006
                                        where n06_flag_ident = 'CO'
                                          and n06_estado     = 'A')
          and n33_valor       > 0
        group by 1, 2, 3, 4, 5
        order by 3, 4, 2;
