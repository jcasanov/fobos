--rollback work;
begin work;

--select * from rept010 where r10_compania = 1 and r10_codigo = '1B08030';

update rept010
set 
    r10_precio_mb = (select pvp from migracion@ol_server:pvp
                      where item = r10_codigo),
 r10_fec_camprec = current

where r10_codigo in (select item from migracion@ol_server:pvp)
  ;

--select * from rept010 where r10_compania = 1 and r10_codigo = '1B08030';
