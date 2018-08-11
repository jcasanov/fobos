unload to "resp_cedruc.txt"
select z01_codcli, z01_num_doc_id from cxct001
	where z01_num_doc_id in ('CONSUMIDOR FINA', 'EN TRAMITE')
	order by 2, 1
