unload to 'existencia.unl'
SELECT r10_codigo, r10_nombre, r11_stock_act,  r10_costo_mb, (r11_stock_act * r10_costo_mb) as subtotal 
FROM rept010, rept011  
WHERE r10_compania  = 1   
  AND r11_compania  = r10_compania    
  AND r11_item      = r10_codigo    
  AND r11_bodega    = "MA"  
  AND r11_stock_act > 0
