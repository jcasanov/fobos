select r11_compania codcia, r11_bodega bd_gye, r11_item item_gye
        from rept011
        where r11_compania  = 1
          and r11_bodega   in (select r02_codigo from rept002
                                where r02_compania   = 1
                                  and r02_localidad in (3,5)
                                  and r02_tipo      <> 'S'
                                  and r02_area       = 'R')
        into temp t1;
select count(*) hay_t1 from t1;
drop table t1;
