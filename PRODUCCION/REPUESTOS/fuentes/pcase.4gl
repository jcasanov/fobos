database aceros


main
	unload to "prueba.txt"
		select case r16_estado
				when 'A' then 'CACA'
				when 'P' then "CERRAD0"
			end case
			from rept016
			order by 1

end main
