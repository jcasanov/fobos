insert into rolt056
                (n56_compania, n56_proceso, n56_cod_depto, n56_cod_trab,
                 n56_estado, n56_aux_val_vac, n56_aux_val_adi, n56_aux_otr_ing,
                 n56_aux_iess, n56_aux_otr_egr, n56_aux_banco, n56_usuario,
                 n56_fecing)
                select n56_compania, n56_proceso, 7, 203, 'A',
                        case when n56_proceso[1, 1] = 'D' or
                                  n56_proceso[1, 1] = 'F' or
                                  n56_proceso       = 'UT' or
                                  n56_proceso       = 'VP'
                                then n56_aux_val_vac
                                else n56_aux_val_vac[1, 8] || '106'
                        end,
                        case when n56_proceso <> 'VP' and
                                  n56_proceso <> 'UV'
                                then n56_aux_val_adi[1, 8] || '106'
                                else n56_aux_val_adi
                        end,
                        n56_aux_otr_ing, n56_aux_iess, n56_aux_otr_egr,
			n56_aux_banco, 'PATRMOLI', current
                        from rolt056
                        where n56_compania  = 1
			  and n56_proceso  <> "UT"
                          and n56_cod_trab  = 176;
