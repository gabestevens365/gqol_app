-- This is the All-Kiosks Query for the LEGACY Platform -- Run on 74.112.192.186,1920
-- Version 2. This worked on 7/16.
SELECT
	-- Information: Top Level --
	''						AS	'Quick Ref'
	,'365 Retail Markets'	AS	'Platform Parent'
	,'Legacy'				AS	'Platform'
	,ks.Grandparent			AS	'Operator Group'
	,ks.Operation			AS	'Operator Name'
	,ks.LocationName		AS	'Location Name'
	,ks.KioskSerial			AS	'Serial Number'
	-- Information: Operation --
	,''						AS	'Op Info'
	,ks.dbRevision          AS  'Op DB Revision'
	,ks.CustomerId			AS	'Op ID'
	,ks.Operation			AS	'Op Name'
	,c.SageCustomerID		AS	'Op Sage ID'
	,c.Address				AS	'Op Address'
	,c.City					AS	'Op City'
	,c.State				AS	'Op State'
	,c.Zip					AS	'Op Zip'
	-- Information: Location --
	,''						AS	'Loc Info'
    ,g.GroupName			AS	'Loc Campus/MSL Name'
    ,ks.MSLID               AS  'Loc MSL ID'
    ,ks.MSLMembers          AS  'Loc MSL Members'
    ,ks.LocationId			AS	'Loc ID'
    ,ks.LocationName		AS	'Loc Name'
    ,ks.Address				AS	'Loc Address'
    ,ks.City				AS	'Loc City'
    ,ks.State				AS	'Loc State'
    ,ks.Zip					AS	'Loc Zip'
    ,ks.IntegrationsGMA		AS	'Loc GMA'
    ,ks.GoLiveLocation		AS	'Loc Go-Live Date'
	-- Information: Device --
    ,''						AS	'Device Info'
    ,ks.KioskSerial			AS	'Device Serial'
    ,ks.KioskModel			AS	'Device Model'
    ,ks.MKLStatus			AS	'Device MKL Status'
    ,ks.MKLServer			AS	'Device MKL Server'
    ,ks.HardwareCCReader	AS	'Device CC Reader'
    ,ks.GoLiveKiosk			AS	'Device Go-Live'
    ,l.LastSyncOn			AS	'Device Last Sync Date'
    ,ks.lastsaleon			AS	'Device Last Trxn Date'
    ,''						AS	'App Info'
    -- Information: OS & Apps
    ,ks.WinVersion			AS	'OS Version'
    ,ks.CurrentVersionValet	AS	'Valet Version'
    ,ks.CurrentVersionOTIFirmware	AS	'OTI Firmware'
    ,ks.IntegrationsUSConnect       AS  'USConnect Integration'
    ,ks.IntegrationsQuickCharge     AS  'QuickCharge Integration'
    ,ks.IntegrationsPrecidia        AS  'Precidia Integration'
    ,''						AS	'Anti-Malware'
    ,''						AS	'Anti-Malware Ver'
    ,''						AS	'Anti-Malware Definition Date'
    ,(CASE
        WHEN ks.IsGDPR = 1
        THEN 'Enabled'
        ELSE '' END)		AS	'App Biometric Policy'
    ,(CASE
        WHEN ks.BIPA = 1
        THEN 'Enabled'
        ELSE '' END)		AS	'App Privacy Notice'

FROM (SELECT *, ROW_NUMBER() OVER (PARTITION BY KioskSerial ORDER BY RecordedOn DESC) AS newest
        FROM [KioskDiags].dbo.KioskStats) ks
LEFT JOIN [365DBA].dbo.AllGmaReadiness g	ON CAST(ks.MSLID as VARCHAR(36)) = CAST(g.GroupUniqueId AS VARCHAR(36))
LEFT JOIN [CUSTOMERS].dbo.CUSTOMERS c		ON ks.CustomerId = c.ID
LEFT JOIN [CUSTOMERS].dbo.LOCATIONS l		ON ks.LocationId = l.ID
WHERE c.IsActive=1
ORDER BY ks.Grandparent, ks.Operation, g.GroupName, ks.LocationName, ks.MKLStatus Desc
