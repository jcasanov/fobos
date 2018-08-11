select cxct022.rowid, z23_tipo_trn tp, z23_num_trn num, z23_valor_cap valor,
        z23_saldo_cap saldo, z22_fecing fecha--, z22_usuario usu
        from cxct023, cxct022
        where z23_codcli    = 12219
          and z23_tipo_doc  = 'FA'
          and z23_num_doc   = 157251
          and z22_compania  = z23_compania
          and z22_localidad = z23_localidad
          and z22_codcli    = z23_codcli
          and z22_tipo_trn  = z23_tipo_trn
          and z22_num_trn   = z23_num_trn
        order by 1;
