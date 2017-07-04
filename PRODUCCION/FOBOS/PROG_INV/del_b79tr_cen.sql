-- Setear primero el INFORMIXSERVER con el del CENTRO

begin work;

select r91_cod_tran, r91_num_tran num_tran
	from rept091
	where r91_compania    = 1
	  and r91_localidad   = 1
	  and r91_cod_tran    = 'TR'
	  and r91_bodega_dest = 79
	into temp t1;

select count(*) from t1;

delete from rept092
	where r92_compania  = 1
	  and r92_localidad = 1
	  and r92_cod_tran  = 'TR'
	  and r92_num_tran  in (select num_tran from t1);

delete from rept091
	where r91_compania  = 1
	  and r91_localidad = 1
	  and r91_cod_tran  = 'TR'
	  and r91_num_tran  in (select num_tran from t1);

commit work;
