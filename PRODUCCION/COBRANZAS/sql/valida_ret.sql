select
j14_localidad,
j14_cod_tran,
j14_num_tran,
j10_codcli,
j14_num_ret_sri,
j14_tipo_fuente,
j14_num_fuente,
j10_valor,
j14_valor_ret,
(select b13_valor_base from cxct040, ctbt013
                  where
                  z40_compania=j10_compania
                  and z40_localidad=j10_localidad
                  and z40_codcli=j10_codcli
                  and z40_tipo_doc=j10_tipo_destino
                  and z40_num_doc=j10_num_destino
                  and b13_compania=z40_compania
                  and b13_tipo_comp=z40_tipo_comp
                  and b13_num_comp=z40_num_comp
                  and b13_valor_base>=0) valor_ctb,
j14_fecing
from
cajt014,cajt010
where
j14_compania=1
and j14_tipo_fuente='SC'
and j14_tipo_comp is NULL
--and date(j14_fecing) >= mdy  (07,01,2010)
and year(j14_fecing) = 2010
and j10_compania=j14_compania
and j10_localidad=j14_localidad
and j10_tipo_fuente=j14_tipo_fuente
and j10_num_fuente=j14_num_fuente
and j10_tipo_destino = 'PG'
and not exists ( select 1 from cxct023 where
                     z23_compania=j10_compania
                     and z23_localidad=j10_localidad
                     and z23_codcli   = j10_codcli
                     and z23_tipo_trn = j10_tipo_destino
                     and z23_num_trn = j10_num_destino
                     and z23_tipo_doc = j14_cod_tran
                     and z23_num_doc=j14_num_tran)
order by j14_fecing;
