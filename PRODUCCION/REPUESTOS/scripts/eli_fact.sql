begin work;

select 1 compania, 1 localidad, 'FA' cod_tran, 
       00000 num_tran, 00000 codcli    -- Esto arregla con los valores
                                       -- reales
  from dual into temp tt_par;

-- Eliminar contabilizacion
select rept040.* from rept040, tt_par 
 where r40_compania  = compania
   and r40_localidad = localidad
   and r40_cod_tran  = cod_tran 
   and r40_num_tran  = num_tran
  into temp tt_conta; 

delete from ctbt013
 where exists (select b12_compania, b12_tipo_comp, b12_num_comp 
                 from ctbt012, tt_conta
		where b12_compania  = r40_compania
                  and b12_tipo_comp = r40_tipo_comp
                  and b12_num_comp  = r40_num_comp
                  and b13_compania  = b12_compania
                  and b13_tipo_comp = b12_tipo_comp
                  and b13_num_comp  = b12_num_comp);

delete from ctbt012
 where exists (select b12_compania, b12_tipo_comp, b12_num_comp 
                 from tt_conta
		where b12_compania  = r40_compania
                  and b12_tipo_comp = r40_tipo_comp
                  and b12_num_comp  = r40_num_comp);
		
delete from rept040
 where exists (select r40_compania, r40_tipo_comp, r40_num_comp 
                 from tt_par 
                where r40_compania  = compania
                  and r40_localidad = localidad
                  and r40_cod_tran  = cod_tran 
                  and r40_num_tran  = num_tran);

select rept100.*     
  from rept100, tt_par
 where r100_compania  = compania
   and r100_localidad = localidad
   and r100_cod_tran  = cod_tran
   and r100_num_tran  = num_tran
  into temp tt_items; 

select rept011.* from tt_items, rept011       
 where r11_compania  = r100_compania
   and r11_bodega    = r100_bodega
   and r11_item      = r100_item;   

update rept011 
   set r11_stock_act = r11_stock_act + (select r100_cantidad 
                                          from tt_items       
                                         where r11_compania  = r100_compania
                                           and r11_bodega    = r100_bodega
                                           and r11_item      = r100_item   
					)
 where exists (select * from tt_items       
                where r11_compania  = r100_compania
                  and r11_bodega    = r100_bodega
                  and r11_item      = r100_item   
	      );

select rept011.* from tt_items, rept011       
 where r11_compania  = r100_compania
   and r11_bodega    = r100_bodega
   and r11_item      = r100_item;   

