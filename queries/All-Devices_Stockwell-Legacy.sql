SELECT
  ' '                   AS `Quick Ref`,
  '365 Retail Markets'  AS `Platform Parent`,
  'Legacy Stockwell'    AS `Platform`,
  ' '                   AS `Operator Group`,
  met.name              AS `Operator Division - Metro`,
  sg.name               AS `Operator Name`,
  bl.name               AS `Location Name`,
  ' '                   AS `Op Info`,
  ' '                   AS `Loc Info`,
  bl.name               AS `Loc Name`,
  bl.address            AS `Location Address`,
  bl.city               AS `Location City`,
  bl.state              AS `Location State`,
  bl.zip_code           AS `Location Zip`,
  ' '                   AS `Device Info`,
  h.name                AS `Hardware Spec`,
  bl.id                 AS `Device Int ID`,
  ext.External_Id       AS `Device Ext ID`,
  sw.pico_serial_number AS `Device Pico Serial`,
  TXNDate               AS `Last Trxn Date`,
  ' '                   AS `App Info`,
  d.os_name_version     AS `OS Version`
FROM `pict-app.dataflow_sql.pict_api_baselocation` bl
JOIN `pict-app.dataflow_sql.pict_api_stockwell` sw ON bl.id = sw.baselocation_ptr_id
JOIN `pict-app.dataflow_sql.pict_api_metro` met ON met.id = bl.metro_id
JOIN `pict-app.dataflow_sql.pict_api_operatingcompany` oc ON met.operating_company_id = oc.storegroup_ptr_id
JOIN `pict-app.dataflow_sql.pict_api_storegroup` sg ON oc.storegroup_ptr_id = sg.id
LEFT JOIN `dataflow_sql.pict_api_hardwarespec` h ON (h.id = sw.`hardware_spec_id`)
LEFT JOIN `pict-app.dataflow_sql.pict_api_externalid` ext ON (ext.stockwell_id = sw.`baselocation_ptr_id`)
LEFT JOIN `dataflow_sql.pict_api_device` d ON (d.id = ext.device_id)
LEFT JOIN
(
  SELECT  p.`stockwell_id`,
          max(p.date) TXNDate
  FROM `pict-app.dataflow_sql.pict_api_baselocation` base
  LEFT JOIN `pict-app.dataflow_sql.pict_api_purchase` p ON (base.id = p.stockwell_id)
  LEFT JOIN `pict-app.dataflow_sql.pict_api_purchasevector` pv ON (p.id = pv.purchase_id)
  LEFT JOIN `pict-app.dataflow_sql.pict_api_itemvector` iv ON (pv.item_vector_id = iv.id)
  WHERE EXTRACT(DATE from p.date) <= CURRENT_DATE()
        AND iv.lifecycle = 0
        AND iv.count > 0
        AND iv.transaction = 1
        AND p.rawtotal != 0
        AND p.is_consumed = 1
        AND base.deprecated = 0
  GROUP BY stockwell_id
)txn ON (bl.id = txn.stockwell_id)