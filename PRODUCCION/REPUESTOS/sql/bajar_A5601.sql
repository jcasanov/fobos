unload to 'A-5601.txt'
	select r82_partida, r82_item, r82_sec_item, r82_sec_partida
		from rept082
		where r82_pedido = 'A-5601'
		order by r82_sec_item
