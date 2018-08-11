unload to "gent054.unl"
	select * from gent054
		where g54_proceso matches 'srip*'
		  and g54_modulo  = 'SR';
