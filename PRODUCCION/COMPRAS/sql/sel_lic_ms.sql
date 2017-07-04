select c10_estado estado, c10_codprov codp, p01_nomprov proveedor,
        c11_numero_oc num_oc, c10_factura factura, c10_fecha_fact,
        c11_cant_ped cant, c11_cant_rec cant_r, c11_descrip descripcion,
        c11_precio valor, c10_fecing fecing
        from ordt011, ordt010, cxpt001
        where (c11_descrip  matches '*LICEN*'
           or  c11_descrip  matches '*OFFICE*')
          and c10_compania  = c11_compania
          and c10_localidad = c11_localidad
          and c10_numero_oc = c11_numero_oc
          --and c10_estado    <> 'E'
          and p01_codprov   = c10_codprov
        order by c10_fecing asc;
