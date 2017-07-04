select z20_compania, z20_localidad, z20_codcli, z20_tipo_doc, z20_num_doc,
        z20_dividendo, z22_tipo_trn, z22_num_trn, z22_fecing
        from cxct020, cxct023, cxct022
        where z20_compania   = 1
          and z20_localidad in (1, 2)
	  and z20_codcli     = 7244
          and z23_compania   = z20_compania
          and z23_localidad  = z20_localidad
          and z23_codcli     = z20_codcli
          and z23_tipo_doc   = z20_tipo_doc
          and z23_num_doc    = z20_num_doc
          and z23_div_doc    = z20_dividendo
          and z22_compania   = z23_compania
          and z22_localidad  = z23_localidad
          and z22_codcli     = z23_codcli
          and z22_tipo_trn   = z23_tipo_trn
          and z22_num_trn    = z23_num_trn
          and z22_fecing    in (select max(a.z22_fecing)
                                from cxct023 b, cxct022 a
                                where b.z23_compania  = z20_compania
                                  and b.z23_localidad = z20_localidad
                                  and b.z23_codcli    = z20_codcli
                                  and b.z23_tipo_doc  = z20_tipo_doc
				  and b.z23_num_doc   = z20_num_doc
                                  and b.z23_div_doc   = z20_dividendo
                                  and a.z22_compania  = b.z23_compania
                                  and a.z22_localidad = b.z23_localidad
                                  and a.z22_codcli    = b.z23_codcli
                                  and a.z22_tipo_trn  = b.z23_tipo_trn
                                  and a.z22_num_trn   = b.z23_num_trn)
	order by 9;
