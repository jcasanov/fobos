begin work;
DELETE FROM ordt003
                        WHERE c03_compania       = 1
                          AND c03_tipo_ret       = 'F'
                          AND c03_porcentaje     = 1
                          AND c03_codigo_sri     = '307'
                          AND c03_fecha_ini_porc = mdy(04,01,2003);
rollback work;
