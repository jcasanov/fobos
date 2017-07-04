update rept020 set r20_cant_ped = r20_cant_ped * (-1),
		   r20_cant_ven = r20_cant_ven * (-1)
	where r20_cant_ven < 0;
