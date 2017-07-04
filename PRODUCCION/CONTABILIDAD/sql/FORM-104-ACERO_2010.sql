SELECT 
 "18" tipodoc, 
 r19_localidad loc, 
        CASE
                WHEN MONTH(r19_fecing) = 1 THEN "ENE"
                WHEN MONTH(r19_fecing) = 2 THEN "FEB"
                WHEN MONTH(r19_fecing) = 3 THEN "MAR"
                WHEN MONTH(r19_fecing) = 4 THEN "ABR"
                WHEN MONTH(r19_fecing) = 5 THEN "MAY"
                WHEN MONTH(r19_fecing) = 6 THEN "JUN"
                WHEN MONTH(r19_fecing) = 7 THEN "JUL"
                WHEN MONTH(r19_fecing) = 8 THEN "AGO"
                WHEN MONTH(r19_fecing) = 9 THEN "SEP"
                WHEN MONTH(r19_fecing) = 10 THEN "OCT"
                WHEN MONTH(r19_fecing) = 11 THEN "NOV"
                WHEN MONTH(r19_fecing) = 12 THEN "DIC"
        END MES,
 
 "9999" codcli, --r19_codcli codcli, 
 CASE WHEN r19_codcli = 99 THEN
  "9999999999999"
  WHEN (SELECT DISTINCT z01_tipo_doc_id 
   FROM acero_gm:cxct001 
   WHERE z01_codcli = r19_codcli) = "R" 
  AND length(r19_cedruc) = 13 THEN
   r19_cedruc 
  ELSE
   "9999999999999"
 END docid,
 CASE WHEN r19_codcli = 99 THEN
  "CONSUMIDOR FINAL"
  WHEN (SELECT DISTINCT z01_tipo_doc_id 
   FROM acero_gm:cxct001 
   WHERE z01_codcli = r19_codcli) = "R" 
  AND length(r19_cedruc) = 13 THEN
   r19_nomcli
  ELSE
   "CONSUMIDOR FINAL"
 END  nomcli,
-- r19_cod_tran codtran,
 
 SUM(
 CASE WHEN r19_cod_tran = 'FA'
  THEN 1
  ELSE -1
 END) ndocs,
 SUM(CASE WHEN r19_cod_tran = 'FA' AND r19_porc_impto = 0 THEN
   r19_tot_neto
   WHEN r19_cod_tran = 'AF' AND r19_porc_impto = 0 THEN
   r19_tot_neto * (-1) 
   WHEN r19_cod_tran = 'FA' AND r19_porc_impto = 12 THEN
   r19_flete
   WHEN r19_cod_tran = 'AF' AND r19_porc_impto = 12 THEN
   r19_flete * (-1) 
     ELSE 0
 END) subtotal,
 SUM(CASE WHEN r19_cod_tran = 'FA' AND r19_porc_impto <> 0 THEN
   (r19_tot_bruto - r19_tot_dscto)
   WHEN r19_cod_tran = 'AF' AND r19_porc_impto <> 0 THEN 
   (r19_tot_bruto - r19_tot_dscto) * (-1)
     ELSE 0
 END) subtotalGrav,
 
 SUM(CASE WHEN r19_cod_tran = 'FA'
  THEN (r19_tot_neto - r19_tot_bruto + r19_tot_dscto - 
r19_flete)
  ELSE (r19_tot_neto - r19_tot_bruto + r19_tot_dscto - 
r19_flete)
   * (-1)
 END) impuesto,
 SUM(CASE WHEN r19_cod_tran = 'FA'
  THEN r19_tot_neto
  ELSE r19_tot_neto * -1
 END) neto,
 0 ret
 
FROM
 acero_gm:rept019
WHERE
       r19_compania      = 1
   AND r19_localidad     = 1
   AND r19_cod_tran     IN ('FA', 'NV', 'AF')
   AND YEAR(r19_fecing) = 2010
GROUP BY 1,2,3,4,5,6,12
 
UNION ALL
 

SELECT 
 "18" tipodoc, 
 r19_localidad loc, 
        CASE
                WHEN MONTH(r19_fecing) = 1 THEN "ENE"
                WHEN MONTH(r19_fecing) = 2 THEN "FEB"
                WHEN MONTH(r19_fecing) = 3 THEN "MAR"
                WHEN MONTH(r19_fecing) = 4 THEN "ABR"
                WHEN MONTH(r19_fecing) = 5 THEN "MAY"
                WHEN MONTH(r19_fecing) = 6 THEN "JUN"
                WHEN MONTH(r19_fecing) = 7 THEN "JUL"
                WHEN MONTH(r19_fecing) = 8 THEN "AGO"
                WHEN MONTH(r19_fecing) = 9 THEN "SEP"
                WHEN MONTH(r19_fecing) = 10 THEN "OCT"
                WHEN MONTH(r19_fecing) = 11 THEN "NOV"
                WHEN MONTH(r19_fecing) = 12 THEN "DIC"
        END MES,
 
 "9999" codcli, --r19_codcli codcli, 
 CASE WHEN r19_codcli = 99 THEN
  "9999999999999"
  WHEN (SELECT DISTINCT z01_tipo_doc_id 
   FROM acero_gc:cxct001 
   WHERE z01_codcli = r19_codcli) = "R" 
  AND length(r19_cedruc) = 13 THEN
   r19_cedruc 
  ELSE
   "9999999999999"
 END docid,
 CASE WHEN r19_codcli = 99 THEN
  "CONSUMIDOR FINAL"
  WHEN (SELECT DISTINCT z01_tipo_doc_id 
   FROM acero_gc:cxct001 
   WHERE z01_codcli = r19_codcli) = "R" 
  AND length(r19_cedruc) = 13 THEN
   r19_nomcli
  ELSE
   "CONSUMIDOR FINAL"
 END  nomcli,
-- r19_cod_tran codtran,
 SUM(
 CASE WHEN r19_cod_tran = 'FA'
  THEN 1
  ELSE -1
 END) ndocs,
 
 SUM(CASE WHEN r19_cod_tran = 'FA' AND r19_porc_impto = 0 THEN
   r19_tot_neto
   WHEN r19_cod_tran = 'AF' AND r19_porc_impto = 0 THEN
   r19_tot_neto * (-1) 
   WHEN r19_cod_tran = 'FA' AND r19_porc_impto = 12 THEN
   r19_flete
   WHEN r19_cod_tran = 'AF' AND r19_porc_impto = 12 THEN
   r19_flete * (-1) 
     ELSE 0
 END) subtotal,
 SUM(CASE WHEN r19_cod_tran = 'FA' AND r19_porc_impto <> 0 THEN
   (r19_tot_bruto - r19_tot_dscto)
   WHEN r19_cod_tran = 'AF' AND r19_porc_impto <> 0 THEN 
   (r19_tot_bruto - r19_tot_dscto) * (-1)
     ELSE 0
 END) subtotalGrav,
 SUM(CASE WHEN r19_cod_tran = 'FA'
  THEN (r19_tot_neto - r19_tot_bruto + r19_tot_dscto - 
r19_flete)
  ELSE (r19_tot_neto - r19_tot_bruto + r19_tot_dscto - 
r19_flete)
   * (-1)
 END) impuesto,
 SUM(CASE WHEN r19_cod_tran = 'FA'
  THEN r19_tot_neto
  ELSE r19_tot_neto * -1
 END) neto,
 0 ret
FROM
 acero_gc:rept019
WHERE
       r19_compania      = 1
   AND r19_localidad     = 2
   AND r19_cod_tran     IN ('FA', 'NV', 'AF')
   AND YEAR(r19_fecing) = 2010
GROUP BY 1,2,3,4,5,6,12
UNION ALL
--------- TALLER
 
SELECT
 "18" tipodoc, 
 t23_localidad loc, 
        CASE
                WHEN MONTH(t23_fec_factura) = 1 THEN "ENE"
                WHEN MONTH(t23_fec_factura) = 2 THEN "FEB"
                WHEN MONTH(t23_fec_factura) = 3 THEN "MAR"
                WHEN MONTH(t23_fec_factura) = 4 THEN "ABR"
                WHEN MONTH(t23_fec_factura) = 5 THEN "MAY"
                WHEN MONTH(t23_fec_factura) = 6 THEN "JUN"
                WHEN MONTH(t23_fec_factura) = 7 THEN "JUL"
                WHEN MONTH(t23_fec_factura) = 8 THEN "AGO"
                WHEN MONTH(t23_fec_factura) = 9 THEN "SEP"
                WHEN MONTH(t23_fec_factura) = 10 THEN "OCT"
                WHEN MONTH(t23_fec_factura) = 11 THEN "NOV"
                WHEN MONTH(t23_fec_factura) = 12 THEN "DIC"
        END MES,
 
 "9999" codcli, --t23_cod_cliente, 
 CASE WHEN t23_cod_cliente = 99 THEN
  "9999999999999"
  WHEN (SELECT DISTINCT z01_tipo_doc_id 
   FROM acero_gm:cxct001 
   WHERE z01_codcli = t23_cod_cliente) = "R" 
  AND length(t23_cedruc) = 13 THEN
   t23_cedruc
  ELSE
   "9999999999999"
 END docid,
 CASE WHEN t23_cod_cliente = 99 THEN
  "CONSUMIDOR FINAL"
  WHEN (SELECT DISTINCT z01_tipo_doc_id 
   FROM acero_gm:cxct001 
   WHERE z01_codcli = t23_cod_cliente) = "R" 
  AND length(t23_cedruc) = 13 THEN
   t23_nom_cliente
  ELSE
   "CONSUMIDOR FINAL"
 END  nomcli,
{
 CASE WHEN t23_estado = 'F' THEN "FA"
      WHEN t23_estado = 'D' THEN "DF"
 
 END tp,
}
 count(*) ndocs,
----- t23_num_factura,
 SUM(CASE WHEN t23_porc_impto = 0 THEN 
 CASE WHEN t23_estado = "F" THEN
 NVL((SELECT NVL(SUM(ROUND((c11_precio - c11_val_descto)
  * (1 + c10_recargo / 100), 2)), 0)
  FROM acero_gm:ordt010, acero_gm:ordt011
  WHERE c10_compania    = t23_compania
    AND c10_localidad   = t23_localidad
    AND c10_ord_trabajo = t23_orden
    AND c10_estado      = 'C'
    AND c11_compania    = c10_compania
    AND c11_localidad   = c10_localidad
    AND c11_numero_oc   = c10_numero_oc
    AND c11_tipo        = 'S'),0) +
 NVL((SELECT NVL(SUM(ROUND(((c11_cant_ped * c11_precio)
  - c11_val_descto)
  * (1 + c10_recargo / 100), 2)),0)
  FROM acero_gm:ordt010, acero_gm:ordt011
  WHERE c10_compania    = t23_compania
    AND c10_localidad   = t23_localidad
    AND c10_ord_trabajo = t23_orden
    AND c10_estado      = 'C'
    AND c11_compania    = c10_compania
    AND c11_localidad   = c10_localidad
    AND c11_numero_oc   = c10_numero_oc
    AND c11_tipo        = 'B'),0) +
   CASE WHEN (SELECT COUNT(*) FROM acero_gm:ordt010
    WHERE c10_compania    = t23_compania
      AND c10_localidad   = t23_localidad
      AND c10_ord_trabajo = t23_orden
      AND c10_estado      = 'C') = 0
   THEN (t23_val_rp_tal + t23_val_rp_ext + 
t23_val_rp_cti
    + t23_val_otros2)
   ELSE 0.00
   END
  + (t23_val_mo_tal - t23_vde_mo_tal)
 WHEN t23_estado = "D" THEN
 NVL((SELECT NVL(SUM(ROUND((c11_precio - c11_val_descto)
  * (1 + c10_recargo / 100), 2)), 0)
  FROM acero_gm:ordt010, acero_gm:ordt011, acero_gm:talt028
  WHERE c10_compania    = t23_compania
    AND c10_localidad   = t23_localidad
    AND c10_ord_trabajo = t28_ot_nue
    AND c10_estado      = 'C'
    AND c11_compania    = c10_compania
    AND c11_localidad   = c10_localidad
    AND c11_numero_oc   = c10_numero_oc
    AND c11_tipo        = 'S'
    AND t28_compania    = t23_compania
    AND t28_localidad   = t23_localidad
    AND t23_num_factura = t28_factura
 
 ),0) +
 NVL((SELECT NVL(SUM(ROUND(((c11_cant_ped * c11_precio)
  - c11_val_descto)
  * (1 + c10_recargo / 100), 2)),0)
  FROM acero_gm:ordt010, acero_gm:ordt011, acero_gm:talt028
  WHERE c10_compania    = t23_compania
    AND c10_localidad   = t23_localidad
    AND c10_ord_trabajo = t28_ot_nue
    AND c10_estado      = 'C'
    AND c11_compania    = c10_compania
    AND c11_localidad   = c10_localidad
    AND c11_numero_oc   = c10_numero_oc
    AND c11_tipo        = 'B'
    AND t28_compania    = t23_compania
    AND t28_localidad   = t23_localidad
    AND t23_num_factura = t28_factura
 ),0) +
   CASE WHEN (SELECT COUNT(*) FROM acero_gm:ordt010, 
acero_gm:talt028
    WHERE c10_compania    = t23_compania
      AND c10_localidad   = t23_localidad
      AND c10_ord_trabajo = t28_ot_nue
      AND c10_estado      = 'C'
      AND t28_compania    = t23_compania
      AND t28_localidad   = t23_localidad
      AND t23_num_factura = t28_factura
     
    ) = 0
   THEN (
                                t23_val_mo_ext + t23_val_mo_cti +
                                t23_val_rp_tal + t23_val_rp_ext +
                                t23_val_rp_cti + t23_val_otros2
                                )
   ELSE 0.00
   END
  + (t23_val_mo_tal - t23_vde_mo_tal)
 
 ELSE 0.00
 END
 ELSE 0.00
 END
 ) subtotal,
 

 SUM(CASE WHEN t23_porc_impto <> 0 THEN 
 CASE WHEN t23_estado = "F" THEN
 NVL((SELECT NVL(SUM(ROUND((c11_precio - c11_val_descto)
  * (1 + c10_recargo / 100), 2)), 0)
  FROM acero_gm:ordt010, acero_gm:ordt011
  WHERE c10_compania    = t23_compania
    AND c10_localidad   = t23_localidad
    AND c10_ord_trabajo = t23_orden
    AND c10_estado      = 'C'
    AND c11_compania    = c10_compania
    AND c11_localidad   = c10_localidad
    AND c11_numero_oc   = c10_numero_oc
    AND c11_tipo        = 'S'),0) +
 NVL((SELECT NVL(SUM(ROUND(((c11_cant_ped * c11_precio)
  - c11_val_descto)
  * (1 + c10_recargo / 100), 2)),0)
  FROM acero_gm:ordt010, acero_gm:ordt011
  WHERE c10_compania    = t23_compania
    AND c10_localidad   = t23_localidad
    AND c10_ord_trabajo = t23_orden
    AND c10_estado      = 'C'
    AND c11_compania    = c10_compania
    AND c11_localidad   = c10_localidad
    AND c11_numero_oc   = c10_numero_oc
    AND c11_tipo        = 'B'),0) +
   CASE WHEN (SELECT COUNT(*) FROM acero_gm:ordt010
    WHERE c10_compania    = t23_compania
      AND c10_localidad   = t23_localidad
      AND c10_ord_trabajo = t23_orden
      AND c10_estado      = 'C') = 0
   THEN (
                                t23_val_mo_ext + t23_val_mo_cti +
                                t23_val_rp_tal + t23_val_rp_ext +
                                t23_val_rp_cti + t23_val_otros2
                                )
   ELSE 0.00
   END
  + (t23_val_mo_tal - t23_vde_mo_tal) 
 WHEN t23_estado = "D" THEN
 NVL((SELECT NVL(SUM(ROUND((c11_precio - c11_val_descto)
  * (1 + c10_recargo / 100), 2)), 0)
  FROM acero_gm:ordt010, acero_gm:ordt011, acero_gm:talt028
  WHERE c10_compania    = t23_compania
    AND c10_localidad   = t23_localidad
    AND c10_ord_trabajo = t28_ot_nue
    AND c10_estado      = 'C'
    AND c11_compania    = c10_compania
    AND c11_localidad   = c10_localidad
    AND c11_numero_oc   = c10_numero_oc
    AND c11_tipo        = 'S'
    AND t28_compania    = t23_compania
    AND t28_localidad   = t23_localidad
    AND t23_num_factura = t28_factura
 
 ),0) +
 NVL((SELECT NVL(SUM(ROUND(((c11_cant_ped * c11_precio)
  - c11_val_descto)
  * (1 + c10_recargo / 100), 2)),0)
  FROM acero_gm:ordt010, acero_gm:ordt011, acero_gm:talt028
  WHERE c10_compania    = t23_compania
    AND c10_localidad   = t23_localidad
    AND c10_ord_trabajo = t28_ot_nue
    AND c10_estado      = 'C'
    AND c11_compania    = c10_compania
    AND c11_localidad   = c10_localidad
    AND c11_numero_oc   = c10_numero_oc
    AND c11_tipo        = 'B'
    AND t28_compania    = t23_compania
    AND t28_localidad   = t23_localidad
    AND t23_num_factura = t28_factura
 ),0) +
   CASE WHEN (SELECT COUNT(*) FROM acero_gm:ordt010, 
acero_gm:talt028
    WHERE c10_compania    = t23_compania
      AND c10_localidad   = t23_localidad
      AND c10_ord_trabajo = t28_ot_nue
      AND c10_estado      = 'C'
      AND t28_compania    = t23_compania
      AND t28_localidad   = t23_localidad
      AND t23_num_factura = t28_factura
     
    ) = 0
   THEN (
                                t23_val_mo_ext + t23_val_mo_cti +
                                t23_val_rp_tal + t23_val_rp_ext +
                                t23_val_rp_cti + t23_val_otros2
                                )
   ELSE 0.00
   END
  + (t23_val_mo_tal - t23_vde_mo_tal) 
 
 ELSE 0.00
 END
 ELSE 0.00
 END
 )  subtotalGrav, 
 SUM(t23_val_impto) impuesto, 
 SUM(t23_tot_neto)  neto,
 0 ret 
 
FROM
 acero_gm:talt023
WHERE
 t23_compania           = 1
 AND t23_localidad = 1
 AND (t23_estado         = 'F' OR
     (t23_estado  = 'D' 
  AND date(t23_fec_factura) < (SELECT date(t28_fec_anula) 
     FROM  acero_gm:talt028
     WHERE t23_compania   = 
t28_compania
           AND t23_localidad   = 
t28_localidad
           AND t23_num_factura = 
t28_factura)
  ))
 AND YEAR(t23_fec_factura) = 2010
GROUP BY
 1, 2, 3, 4, 5, 6, 12
UNION ALL
 
------------- INVENTARIO
SELECT 
 "04" tipodoc, 
 r19_localidad loc, 
        CASE
                WHEN MONTH(r19_fecing) = 1 THEN "ENE"
                WHEN MONTH(r19_fecing) = 2 THEN "FEB"
                WHEN MONTH(r19_fecing) = 3 THEN "MAR"
                WHEN MONTH(r19_fecing) = 4 THEN "ABR"
                WHEN MONTH(r19_fecing) = 5 THEN "MAY"
                WHEN MONTH(r19_fecing) = 6 THEN "JUN"
                WHEN MONTH(r19_fecing) = 7 THEN "JUL"
                WHEN MONTH(r19_fecing) = 8 THEN "AGO"
                WHEN MONTH(r19_fecing) = 9 THEN "SEP"
                WHEN MONTH(r19_fecing) = 10 THEN "OCT"
                WHEN MONTH(r19_fecing) = 11 THEN "NOV"
                WHEN MONTH(r19_fecing) = 12 THEN "DIC"
        END MES,
 
 "9999" codcli, --r19_codcli codcli, 
 CASE WHEN r19_codcli = 99 THEN
  "9999999999999"
  WHEN (SELECT DISTINCT z01_tipo_doc_id 
   FROM acero_gm:cxct001 
   WHERE z01_codcli = r19_codcli) = "R" 
  AND length(r19_cedruc) = 13 THEN
   r19_cedruc 
  ELSE
   "9999999999999"
 END docid,
 CASE WHEN r19_codcli = 99 THEN
  "CONSUMIDOR FINAL"
  WHEN (SELECT DISTINCT z01_tipo_doc_id 
   FROM acero_gm:cxct001 
   WHERE z01_codcli = r19_codcli) = "R" 
  AND length(r19_cedruc) = 13 THEN
   r19_nomcli
  ELSE
   "CONSUMIDOR FINAL"
 END  nomcli,
-- r19_cod_tran codtran,
 
 SUM(1) ndocs,
 SUM(CASE WHEN r19_cod_tran = 'DF' AND r19_porc_impto = 0 THEN
   r19_tot_neto
   WHEN r19_cod_tran = 'DF' AND r19_porc_impto = 12 THEN
   r19_flete
     ELSE 0
 END) subtotal,
 SUM(CASE WHEN r19_cod_tran = 'DF' AND r19_porc_impto <> 0 THEN
   (r19_tot_bruto - r19_tot_dscto)
     ELSE 0
 END) subtotalGrav,
 
 SUM(CASE WHEN r19_cod_tran = 'DF'
  THEN (r19_tot_neto - r19_tot_bruto + r19_tot_dscto - 
r19_flete)
  ELSE 0
 END) impuesto,
 SUM(r19_tot_neto) neto,
 0 ret
 
FROM
 acero_gm:rept019
WHERE
       r19_compania      = 1
   AND r19_localidad     = 1
   AND r19_cod_tran     IN ('DF')
   AND YEAR(r19_fecing) = 2010
GROUP BY 1,2,3,4,5,6,12
 
UNION ALL
 
SELECT 
 "04" tipodoc, 
 r19_localidad loc, 
        CASE
                WHEN MONTH(r19_fecing) = 1 THEN "ENE"
                WHEN MONTH(r19_fecing) = 2 THEN "FEB"
                WHEN MONTH(r19_fecing) = 3 THEN "MAR"
                WHEN MONTH(r19_fecing) = 4 THEN "ABR"
                WHEN MONTH(r19_fecing) = 5 THEN "MAY"
                WHEN MONTH(r19_fecing) = 6 THEN "JUN"
                WHEN MONTH(r19_fecing) = 7 THEN "JUL"
                WHEN MONTH(r19_fecing) = 8 THEN "AGO"
                WHEN MONTH(r19_fecing) = 9 THEN "SEP"
                WHEN MONTH(r19_fecing) = 10 THEN "OCT"
                WHEN MONTH(r19_fecing) = 11 THEN "NOV"
                WHEN MONTH(r19_fecing) = 12 THEN "DIC"
        END MES,
 
 "9999" codcli, --r19_codcli codcli, 
 CASE WHEN r19_codcli = 99 THEN
  "9999999999999"
  WHEN (SELECT DISTINCT z01_tipo_doc_id 
   FROM acero_gc:cxct001 
   WHERE z01_codcli = r19_codcli) = "R" 
  AND length(r19_cedruc) = 13 THEN
   r19_cedruc 
  ELSE
   "9999999999999"
 END docid,
 CASE WHEN r19_codcli = 99 THEN
  "CONSUMIDOR FINAL"
  WHEN (SELECT DISTINCT z01_tipo_doc_id 
   FROM acero_gc:cxct001 
   WHERE z01_codcli = r19_codcli) = "R" 
  AND length(r19_cedruc) = 13 THEN
   r19_nomcli
  ELSE
   "CONSUMIDOR FINAL"
 END  nomcli,
-- r19_cod_tran codtran,
 
 SUM(1) ndocs,
 SUM(CASE WHEN r19_cod_tran = 'DF' AND r19_porc_impto = 0 THEN
   r19_tot_neto
   WHEN r19_cod_tran = 'DF' AND r19_porc_impto = 12 THEN
   r19_flete
     ELSE 0
 END) subtotal,
 SUM(CASE WHEN r19_cod_tran = 'DF' AND r19_porc_impto <> 0 THEN
   (r19_tot_bruto - r19_tot_dscto)
     ELSE 0
 END) subtotalGrav,
 
 SUM(CASE WHEN r19_cod_tran = 'DF'
  THEN (r19_tot_neto - r19_tot_bruto + r19_tot_dscto - 
r19_flete)
  ELSE 0
 END) impuesto,
 SUM(r19_tot_neto) neto,
 0 ret
 
FROM
 acero_gc:rept019
WHERE
       r19_compania      = 1
   AND r19_localidad     = 2
   AND r19_cod_tran     IN ('DF')
   AND YEAR(r19_fecing) = 2010
GROUP BY 1,2,3,4,5,6,12
 
UNION ALL
 
--------- TALLER
 
SELECT
 "04" tipodoc, 
 t23_localidad loc, 
        CASE
                WHEN MONTH(t28_fec_anula) = 1 THEN "ENE"
                WHEN MONTH(t28_fec_anula) = 2 THEN "FEB"
                WHEN MONTH(t28_fec_anula) = 3 THEN "MAR"
                WHEN MONTH(t28_fec_anula) = 4 THEN "ABR"
                WHEN MONTH(t28_fec_anula) = 5 THEN "MAY"
                WHEN MONTH(t28_fec_anula) = 6 THEN "JUN"
                WHEN MONTH(t28_fec_anula) = 7 THEN "JUL"
                WHEN MONTH(t28_fec_anula) = 8 THEN "AGO"
                WHEN MONTH(t28_fec_anula) = 9 THEN "SEP"
                WHEN MONTH(t28_fec_anula) = 10 THEN "OCT"
                WHEN MONTH(t28_fec_anula) = 11 THEN "NOV"
                WHEN MONTH(t28_fec_anula) = 12 THEN "DIC"
        END MES,
 
 "9999" codcli, --t23_cod_cliente, 
 CASE WHEN t23_cod_cliente = 99 THEN
  "9999999999999"
  WHEN (SELECT DISTINCT z01_tipo_doc_id 
   FROM acero_gm:cxct001 
   WHERE z01_codcli = t23_cod_cliente) = "R" 
  AND length(t23_cedruc) = 13 THEN
   t23_cedruc
  ELSE
   "9999999999999"
 END docid,
 CASE WHEN t23_cod_cliente = 99 THEN
  "CONSUMIDOR FINAL"
  WHEN (SELECT DISTINCT z01_tipo_doc_id 
   FROM acero_gm:cxct001 
   WHERE z01_codcli = t23_cod_cliente) = "R" 
  AND length(t23_cedruc) = 13 THEN
   t23_nom_cliente
  ELSE
   "CONSUMIDOR FINAL"
 END  nomcli,
{
 CASE WHEN t23_estado = 'F' THEN "FA"
      WHEN t23_estado = 'D' THEN "DF"
 
 END tp,
}
 count(*) ndocs,
----- t23_num_factura,
 SUM(CASE WHEN t23_porc_impto = 0 THEN 
 CASE  WHEN t23_estado = "D" THEN
 NVL((SELECT NVL(SUM(ROUND((c11_precio - c11_val_descto)
  * (1 + c10_recargo / 100), 2)), 0)
  FROM acero_gm:ordt010, acero_gm:ordt011, acero_gm:talt028
  WHERE c10_compania    = t23_compania
    AND c10_localidad   = t23_localidad
    AND c10_ord_trabajo = t28_ot_nue
    AND c10_estado      = 'C'
    AND c11_compania    = c10_compania
    AND c11_localidad   = c10_localidad
    AND c11_numero_oc   = c10_numero_oc
    AND c11_tipo        = 'S'
    AND t28_compania    = t23_compania
    AND t28_localidad   = t23_localidad
    AND t23_num_factura = t28_factura
 
 ),0) +
 NVL((SELECT NVL(SUM(ROUND(((c11_cant_ped * c11_precio)
  - c11_val_descto)
  * (1 + c10_recargo / 100), 2)),0)
  FROM acero_gm:ordt010, acero_gm:ordt011, acero_gm:talt028
  WHERE c10_compania    = t23_compania
    AND c10_localidad   = t23_localidad
    AND c10_ord_trabajo = t28_ot_nue
    AND c10_estado      = 'C'
    AND c11_compania    = c10_compania
    AND c11_localidad   = c10_localidad
    AND c11_numero_oc   = c10_numero_oc
    AND c11_tipo        = 'B'
    AND t28_compania    = t23_compania
    AND t28_localidad   = t23_localidad
    AND t23_num_factura = t28_factura
 ),0) +
   CASE WHEN (SELECT COUNT(*) 
    FROM acero_gm:ordt010, acero_gm:talt028
    WHERE c10_compania    = t23_compania
      AND c10_localidad   = t23_localidad
      AND c10_ord_trabajo = t28_ot_nue
      AND c10_estado      = 'C'
      AND t28_compania    = t23_compania
      AND t28_localidad   = t23_localidad
      AND t23_num_factura = t28_factura
     
    ) = 0
   THEN (
                                t23_val_mo_ext + t23_val_mo_cti +
                                t23_val_rp_tal + t23_val_rp_ext +
                                t23_val_rp_cti + t23_val_otros2
                                )
   ELSE 0.00
   END
  + (t23_val_mo_tal - t23_vde_mo_tal) 
 
 ELSE 0.00
 END
 ELSE 0.00
 END
 ) subtotal,
 

 SUM(CASE WHEN t23_porc_impto <> 0 THEN 
 CASE  WHEN t23_estado = "D" THEN
 NVL((SELECT NVL(SUM(ROUND((c11_precio - c11_val_descto)
  * (1 + c10_recargo / 100), 2)), 0)
  FROM acero_gm:ordt010, acero_gm:ordt011, acero_gm:talt028
  WHERE c10_compania    = t23_compania
    AND c10_localidad   = t23_localidad
    AND c10_ord_trabajo = t28_ot_nue
    AND c10_estado      = 'C'
    AND c11_compania    = c10_compania
    AND c11_localidad   = c10_localidad
    AND c11_numero_oc   = c10_numero_oc
    AND c11_tipo        = 'S'
    AND t28_compania    = t23_compania
    AND t28_localidad   = t23_localidad
    AND t23_num_factura = t28_factura
 
 ),0) +
 NVL((SELECT NVL(SUM(ROUND(((c11_cant_ped * c11_precio)
  - c11_val_descto)
  * (1 + c10_recargo / 100), 2)),0)
  FROM acero_gm:ordt010, acero_gm:ordt011, acero_gm:talt028
  WHERE c10_compania    = t23_compania
    AND c10_localidad   = t23_localidad
    AND c10_ord_trabajo = t28_ot_nue
    AND c10_estado      = 'C'
    AND c11_compania    = c10_compania
    AND c11_localidad   = c10_localidad
    AND c11_numero_oc   = c10_numero_oc
    AND c11_tipo        = 'B'
    AND t28_compania    = t23_compania
    AND t28_localidad   = t23_localidad
    AND t23_num_factura = t28_factura
 ),0) +
   CASE WHEN (SELECT COUNT(*) 
    FROM acero_gm:ordt010, acero_gm:talt028
    WHERE c10_compania    = t23_compania
      AND c10_localidad   = t23_localidad
      AND c10_ord_trabajo = t28_ot_nue
      AND c10_estado      = 'C'
      AND t28_compania    = t23_compania
      AND t28_localidad   = t23_localidad
      AND t23_num_factura = t28_factura
     
    ) = 0
   THEN (
                                t23_val_mo_ext + t23_val_mo_cti +
                                t23_val_rp_tal + t23_val_rp_ext +
                                t23_val_rp_cti + t23_val_otros2
                                )
   ELSE 0.00
   END
  + (t23_val_mo_tal - t23_vde_mo_tal) 
 
 ELSE 0.00
 END
 ELSE 0.00
 END
 )  subtotalGrav, 
 SUM(t23_val_impto) impuesto, 
 SUM(t23_tot_neto)  neto,
 0 ret 
 
FROM
 acero_gm:talt023, acero_gm:talt028
WHERE
 t23_compania           = 1
 AND t23_localidad = 1
 AND t23_estado  = 'D'
 AND t23_compania  = t28_compania
 AND t23_localidad  = t28_localidad
 AND t23_num_factura = t28_factura
 AND YEAR(t28_fec_anula) = 2010
  AND date(t23_fec_factura) <  date(t28_fec_anula) 
GROUP BY
 1, 2, 3, 4, 5, 6, 12
 
UNION ALL
----------- NC
 
SELECT 
 "04" tipodoc, 
 z21_localidad loc, 
        CASE
                WHEN MONTH(z21_fecha_emi) = 1 THEN "ENE"
                WHEN MONTH(z21_fecha_emi) = 2 THEN "FEB"
                WHEN MONTH(z21_fecha_emi) = 3 THEN "MAR"
                WHEN MONTH(z21_fecha_emi) = 4 THEN "ABR"
                WHEN MONTH(z21_fecha_emi) = 5 THEN "MAY"
                WHEN MONTH(z21_fecha_emi) = 6 THEN "JUN"
                WHEN MONTH(z21_fecha_emi) = 7 THEN "JUL"
                WHEN MONTH(z21_fecha_emi) = 8 THEN "AGO"
                WHEN MONTH(z21_fecha_emi) = 9 THEN "SEP"
                WHEN MONTH(z21_fecha_emi) = 10 THEN "OCT"
                WHEN MONTH(z21_fecha_emi) = 11 THEN "NOV"
                WHEN MONTH(z21_fecha_emi) = 12 THEN "DIC"
        END MES,
 
 "9999" codcli,
 CASE WHEN z21_codcli = 99 THEN
  "9999999999999"
  WHEN z01_tipo_doc_id = "R" AND LENGTH(z01_num_doc_id) = 13 THEN
   z01_num_doc_id
  ELSE
   "9999999999999"
 END docid,
 CASE WHEN z21_codcli = 99 THEN
  "CONSUMIDOR FINAL"
  WHEN z01_tipo_doc_id  = "R" AND LENGTH(z01_num_doc_id) = 13 THEN
   z01_nomcli
  ELSE
   "CONSUMIDOR FINAL"
 END  nomcli,
 sum(1) ndocs, 
 sum(CASE WHEN z21_val_impto = 0 THEN
   z21_valor
     ELSE 0
     END
   ) subtotal,
 sum(CASE WHEN z21_val_impto <> 0 THEN
   (z21_valor - z21_val_impto)
     ELSE 0 
     END
  ) subtotalGrav, 
 sum(z21_val_impto) impuesto, 
 sum(z21_valor + z21_val_impto) neto,
 0 ret
FROM 
 acero_gm:cxct021, acero_gm:cxct001
WHERE 
 z21_compania   = 1
 AND z21_localidad IN (1,2)
 AND z21_tipo_doc   = 'NC'
 AND z21_origen     = 'M'
 AND z01_codcli     = z21_codcli
 AND YEAR(z21_fecha_emi) = 2010
GROUP BY 1,2,3,4,5,6  
 
UNION ALL
------------- ND
SELECT 
 "05" tipodoc, 
 z20_localidad loc, 
        CASE
                WHEN MONTH(z20_fecha_emi) = 1 THEN "ENE"
                WHEN MONTH(z20_fecha_emi) = 2 THEN "FEB"
                WHEN MONTH(z20_fecha_emi) = 3 THEN "MAR"
                WHEN MONTH(z20_fecha_emi) = 4 THEN "ABR"
                WHEN MONTH(z20_fecha_emi) = 5 THEN "MAY"
                WHEN MONTH(z20_fecha_emi) = 6 THEN "JUN"
                WHEN MONTH(z20_fecha_emi) = 7 THEN "JUL"
                WHEN MONTH(z20_fecha_emi) = 8 THEN "AGO"
                WHEN MONTH(z20_fecha_emi) = 9 THEN "SEP"
                WHEN MONTH(z20_fecha_emi) = 10 THEN "OCT"
                WHEN MONTH(z20_fecha_emi) = 11 THEN "NOV"
                WHEN MONTH(z20_fecha_emi) = 12 THEN "DIC"
        END MES,
 
 "9999" codcli,
 CASE WHEN z20_codcli = 99 THEN
  "9999999999999"
  WHEN z01_tipo_doc_id = "R" AND LENGTH(z01_num_doc_id) = 13 THEN
   z01_num_doc_id
  ELSE
   "9999999999999"
 END docid,
 CASE WHEN z20_codcli = 99 THEN
  "CONSUMIDOR FINAL"
  WHEN z01_tipo_doc_id  = "R" AND LENGTH(z01_num_doc_id) = 13 THEN
   z01_nomcli
  ELSE
   "CONSUMIDOR FINAL"
 END  nomcli,
 sum(1) ndocs, 
 sum(CASE WHEN z20_val_impto = 0 THEN
   z20_valor_cap 
     ELSE 0 
     END
        ) subtotal,
 sum(CASE WHEN z20_val_impto <> 0 THEN
   (z20_valor_cap - z20_val_impto) 
     ELSE 0
            END
        ) subtotalGrav, 
 sum(z20_val_impto) impuesto, 
 sum(z20_valor_cap) neto,
 0 ret
FROM 
 acero_gm:cxct020, acero_gm:cxct001
WHERE 
 z20_compania   = 1
 AND z20_localidad IN (1,2)
 AND z20_tipo_doc   = 'ND'
 AND z20_origen     = 'M'
 AND z01_codcli     = z20_codcli
 AND YEAR(z20_fecha_emi) = 2010
GROUP BY 1,2,3,4,5,6
 
UNION ALL
------------- RETENCIONES
 
SELECT 
 "18" tipodoc,
 1 loc, 
        CASE
                WHEN MONTH(b12_fec_proceso) = 1 THEN "ENE"
                WHEN MONTH(b12_fec_proceso) = 2 THEN "FEB"
                WHEN MONTH(b12_fec_proceso) = 3 THEN "MAR"
                WHEN MONTH(b12_fec_proceso) = 4 THEN "ABR"
                WHEN MONTH(b12_fec_proceso) = 5 THEN "MAY"
                WHEN MONTH(b12_fec_proceso) = 6 THEN "JUN"
                WHEN MONTH(b12_fec_proceso) = 7 THEN "JUL"
                WHEN MONTH(b12_fec_proceso) = 8 THEN "AGO"
                WHEN MONTH(b12_fec_proceso) = 9 THEN "SEP"
                WHEN MONTH(b12_fec_proceso) = 10 THEN "OCT"
                WHEN MONTH(b12_fec_proceso) = 11 THEN "NOV"
                WHEN MONTH(b12_fec_proceso) = 12 THEN "DIC"
        END MES,
 "9999" codcli, --r19_codcli codcli, 
 CASE WHEN b13_codcli = 99 THEN
  "9999999999999"
  WHEN (SELECT DISTINCT z01_tipo_doc_id 
   FROM acero_gm:cxct001 
   WHERE z01_codcli = b13_codcli) = "R" 
  AND length(z01_num_doc_id) = 13 THEN
   z01_num_doc_id
  ELSE
   "9999999999999"
 END docid,
 CASE WHEN b13_codcli = 99 THEN
  "CONSUMIDOR FINAL"
  WHEN (SELECT DISTINCT z01_tipo_doc_id 
   FROM acero_gm:cxct001 
   WHERE z01_codcli = b13_codcli) = "R" 
  AND length(z01_num_doc_id) = 13 THEN
   z01_nomcli
  ELSE
   "CONSUMIDOR FINAL"
 END  nomcli,
-- r19_cod_tran codtran,
 
 0 ndocs,
 0 subtotal,
 0 subtotalGrav,
 
 0 impuesto,
 0 neto,
 NVL(SUM(b13_valor_base),0) ret
FROM
 acero_gm:ctbt012,
 acero_gm:ctbt013,
 acero_gm:cxct001
WHERE
 b12_compania  = 1
 AND z01_codcli  = b13_codcli
 AND YEAR(b12_fec_proceso) = 2010
 AND b12_estado   <> "E"
 AND b12_compania = b13_compania
 AND b12_tipo_comp = b13_tipo_comp
 AND b12_num_comp = b13_num_comp
 

 AND b13_cuenta MATCHES "113*"
 AND b13_cuenta IN (
  SELECT UNIQUE z09_aux_cont FROM acero_gm:cxct009 
   WHERE
    z09_codigo_pago  <> "RI"
    AND z09_aux_cont IS NOT NULL
  UNION
  SELECT UNIQUE j91_aux_cont  FROM acero_gm:ordt002, 
acero_gm:cajt091
   WHERE     c02_compania  = j91_compania
    AND c02_tipo_ret = j91_tipo_ret
    AND c02_porcentaje  = j91_porcentaje
    AND j91_codigo_pago <> "RI"
    AND j91_aux_cont IS NOT NULL
  UNION
  SELECT UNIQUE j01_aux_cont FROM acero_gm:cajt001 
   WHERE   j01_retencion = "S"  
    AND j01_codigo_pago <> "RI"
    AND j01_aux_cont  IS NOT NULL
  )
-- AND b13_valor_base 
GROUP BY 1,2,3,4,5,6
 
ORDER BY 6,5
