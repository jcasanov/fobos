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
        end MESES, n30_nombres EMPLEADO, n06_nombre RUBRO,
        g34_nombre DEPARTAMENTO,
        nvl(sum(n33_valor), 0) VALOR
        from rolt030, rolt032, rolt033, rolt006, gent034
        where n30_compania    = 1
          and n30_estado      = 'A'
	  and g34_compania    = n30_compania
	  and g34_cod_depto   = n30_cod_depto
          and n32_compania    = n30_compania
          and n32_cod_liqrol in ('Q1', 'Q2')
          and n32_cod_trab    = n30_cod_trab
          and n32_estado     <> 'E'
	  and n33_compania    = n32_compania
          and n33_cod_liqrol  = n32_cod_liqrol
          and n33_fecha_ini   = n32_fecha_ini
          and n33_fecha_fin   = n32_fecha_fin
          and n33_cod_trab    = n32_cod_trab
          and n33_valor       > 0
	  and n06_cod_rubro   = n33_cod_rubro
        group by 1, 2, 3, 4, 5, 6, 7
        order by 3, 4, 2;
