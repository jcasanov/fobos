update rept019 set r19_ped_cliente = (select r23_ped_cliente from rept023
					where r23_compania  = r19_compania
 					  and r23_localidad = r19_localidad
					  and r23_cod_tran  = r19_cod_tran
					  and r23_num_tran  = r19_num_tran)
