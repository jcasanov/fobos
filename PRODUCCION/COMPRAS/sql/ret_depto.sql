select departamento, proveedor[1, 20], factura, retencion[1, 7], retenido
  from view_retencion
 where anho = 2004 and mes = 11
 order by 1, 2, 3, 4; 

select departamento, sum(retenido) 
  from view_retencion
 where anho = 2004 and mes = 11
 group by 1  
 order by 1; 
