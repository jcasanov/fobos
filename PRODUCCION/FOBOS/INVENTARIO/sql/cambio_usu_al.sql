begin work;

select * from rept021
	where r21_compania  = 1
	  and r21_localidad = 1
	  and r21_numprof   = 21648;

select * from rept023
	where r23_compania  = 1
	  and r23_localidad = 1
	  and r23_numprev   = 10959;

select * from rept019
	where r19_compania  = 1
	  and r19_localidad = 1
	  and r19_cod_tran  = 'FA'
	  and r19_num_tran  = 10092;

select * from cajt010
	where j10_compania    = 1
	  and j10_localidad   = 1
	  and j10_tipo_fuente = 'PR'
	  and j10_num_fuente  = 10959;

update rept021 set r21_vendedor = 10,
		   r21_usuario  = 'ALEXLOZA'
	where r21_compania  = 1
	  and r21_localidad = 1
	  and r21_numprof   = 21648;

update rept023 set r23_vendedor = 10,
		   r23_usuario  = 'ALEXLOZA'
	where r23_compania  = 1
	  and r23_localidad = 1
	  and r23_numprev   = 10959;

update rept019 set r19_vendedor = 10
	where r19_compania  = 1
	  and r19_localidad = 1
	  and r19_cod_tran  = 'FA'
	  and r19_num_tran  = 10092;

--
-- SOLO si la forma de pago es en efectivo hacer este update.
update cajt010 set j10_usuario  = 'ALEXLOZA'
	where j10_compania    = 1
	  and j10_localidad   = 1
	  and j10_tipo_fuente = 'PR'
	  and j10_num_fuente  = 10959;
--
--

select * from rept021
	where r21_compania  = 1
	  and r21_localidad = 1
	  and r21_numprof   = 21648;

select * from rept023
	where r23_compania  = 1
	  and r23_localidad = 1
	  and r23_numprev   = 10959;

select * from rept019
	where r19_compania  = 1
	  and r19_localidad = 1
	  and r19_cod_tran  = 'FA'
	  and r19_num_tran  = 10092;

select * from cajt010
	where j10_compania    = 1
	  and j10_localidad   = 1
	  and j10_tipo_fuente = 'PR'
	  and j10_num_fuente  = 10959;

commit work;
