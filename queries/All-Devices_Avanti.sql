-- The AMS/Avanit All-Devices Report
-- Run in DataWarehouse
-- Version 2. Worked on 2023.09.13
WITH RankedKiosks AS (
    SELECT
        ''                          AS  'Quick Ref'
        ,'Avanti'                   AS  'Platform Parent'
        ,'Avanti'                   AS  'Platform'
        ,''                         AS  'Operator Group'
        ,''                         AS  'Operator Division'
        ,o.Name                     AS  'Operator Name'
        ,l.Name                     AS  'Location Name'
        ,k.Name                     AS  'Kiosk Name'
        -- Information: Operation --
        ,''                         AS  'Op Info'
        ,k.OperatorId               AS  'Op ID'
        ,o.Name                     AS  'Op Name'
        ,o.SageNumber1              AS  'Op Sage ID'
        ,o.Address1                 AS  'Op Address'
        ,o.City                     AS  'Op City'
        ,o.State                    AS  'Op State'
        ,o.Zip                      AS  'Op Zip'
        ,o.Country                  AS  'Op Country'
        ,''                         AS  'Op Currency'
        -- Information: Location --
        ,''                         AS  'Loc Info'
        ,l.Id                       AS  'Loc ID'
        ,l.Name                     AS  'Loc Name'
        ,l.Address                  AS  'Loc Address'
        ,l.City                     AS  'Loc City'
        ,l.State                    AS  'Loc State'
        ,l.Zip                      AS  'Loc Zip'
        ,''                         AS  'Loc Country'
        ,l.ActivationDate           AS  'Loc Go-Live'
        -- Information: Device --
        ,''                         AS  'Device Info'
        ,k.[Id]                     AS  'Device ID'
        ,k.Name                     AS  'Device Name'
        ,kt.Name                    AS  'Device Type'
        ,cc.Model                   AS  'Device CC Reader'
        ,k.FingerScannerOptionId    AS  'Device FP Reader'
        ,k.DeployDate               AS  'Device Deploy Date'
        ,k.LastFullSync             AS  'Device Full Sync'
        ,k.LastHeartbeat            AS  'Device Last Heartbeat'
        ,latestTrxn.TransactionTime AS  'Device Last Trxn'
        ,ks.Name                    AS  'Device Status'
        -- Information: OS & Apps --
        ,''                         AS  'App Info'
        ,''                         AS  'OS Version'
        ,k.KioskServerSoftwareVersion   AS  'POS Version'
        ,ROW_NUMBER() OVER(PARTITION BY k.Name ORDER BY k.LastHeartbeat DESC) AS rnk
    FROM [dbo].[Kiosk] k
        LEFT JOIN Operator o ON k.OperatorID = o.ID
        LEFT JOIN Location l ON k.LocationID = l.ID
        LEFT JOIN KioskType kt ON kt.id = k.KioskTypeId
        LEFT JOIN EncryptingReader cc ON cc.Id = k.EncryptingReaderID
        LEFT JOIN (
            SELECT t.KioskId, t.LocationId, MAX(t.TransactionTime) as TransactionTime
            FROM Transactions t
            GROUP BY t.KioskId, t.LocationId
        ) as latestTrxn ON latestTrxn.KioskId = k.Id AND latestTrxn.LocationId = l.Id
        LEFT JOIN KioskStatus ks ON ks.Id = k.KioskStatusId
    WHERE o.Name NOT IN ('DeadKiosks', 'Staging', 'Suspended Kiosks', 'SLABB Pipeline')
        AND l.Name NOT LIKE 'xxx%'
        AND l.Name NOT LIKE 'XXX%'
        AND l.NAME NOT LIKE 'zz %'
        AND l.NAME NOT LIKE 'ZZ%'
--        AND l.NAME NOT LIKE '%Test Location%'
        AND k.NAME NOT LIKE 'X-%'
        AND ks.NAME != 'Inactive'
)

SELECT
    [Quick Ref],
    [Platform Parent],
    [Platform],
    [Operator Group],
    [Operator Division],
    [Operator Name],
    [Location Name],
    [Kiosk Name],
    [Op Info],
    [Op ID],
    [Op Name],
    [Op Sage ID],
    [Op Address],
    [Op City],
    [Op State],
    [Op Zip],
    [Op Country],
    [Op Currency],
    [Loc Info],
    [Loc ID],
    [Loc Name],
    [Loc Address],
    [Loc City],
    [Loc State],
    [Loc Zip],
    [Loc Country],
    [Loc Go-Live],
    [Device Info],
    [Device ID],
    [Device Name],
    [Device Type],
    [Device CC Reader],
    [Device FP Reader],
    [Device Deploy Date],
    [Device Full Sync],
    [Device Last Heartbeat],
    [Device Last Trxn],
    [Device Status],
    [App Info],
    [OS Version],
    [POS Version]
FROM
    RankedKiosks
WHERE
    rnk = 1
ORDER BY
    [Operator Name], [Location Name], [Kiosk Name];