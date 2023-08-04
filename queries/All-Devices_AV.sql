SELECT
	-- Information: Top Level --
	''										AS	'Quick Ref'
	,'365 Retail Markets'					AS	'Platform Parent'
	,'AirVend'								AS	'Platform'
	,c.MasterAccountName					AS	'Operator Group'
	,c.Name									AS	'Operator Name'
	,m.Name									AS	'Location Name'
	,COALESCE(d.SerialNumber, d.DeviceId)	AS	'Serial or DevID'
	-- Information: Operation --
	,''										AS	'Op Info'
	,c.Id									AS	'Op OrgID'
	,c.Name									AS	'Op Name'
	,c.SageId								AS	'Op Sage ID'
	,c.Address1								AS	'Op Address'
	,c.City									AS	'Op City'
	,c.State								AS	'Op State'
	,c.PostalCode							AS	'Op Zip'
	-- Information: Location --
	,''										AS	'Loc Info'
	,CASE
		d.Deactivated WHEN 1 THEN 'Inactive'
		WHEN 0 THEN 'Active'
	END										AS  'Loc IsActive'
	,m.Name									AS	'Loc Name'
	,m.Address1								AS	'Loc Address'
	,m.City									AS	'Loc City'
	,m.State								AS	'Loc State'
	,m.PostalCode							AS	'Loc Zip'
	,m.Country								AS	'Loc Country'
	,'USD'									AS	'Loc Currency'
	,CASE
		WHEN m.GmaLocationId IS NULL
			THEN 'Not GMA'
		ELSE 'GMA'
	END										AS	'Loc GMA Status'
	,a.ActivationDate						AS	'Loc Go-Live Date'
	-- Information: Device --
	,''										AS	'Device Info'
	,d.DeviceId								AS	'Device ID'
	,d.SerialNumber							AS	'Device Serial'
	,d.HardwareType							AS	'Device Type'
	,CASE
		WHEN d.HardwareType = 'AirVend'		AND d.ModelNumber LIKE '%AV5' THEN 'AV5'
		WHEN d.HardwareType = 'AirVend'		AND d.ModelNumber LIKE '%AV7' THEN 'AV7'
		WHEN d.HardwareType = 'Saturn'		THEN 'PicoVend'
		WHEN d.HardwareType = 'UPT1000F'	THEN 'PicoVend Mini'
		WHEN d.HardwareType = '365Inside'	THEN '365 Inside'
		ELSE d.HardwareType
	END										AS	'Device Model'
	,d.ModelNumber							AS	'Device Model Number'
	,a.ActivationDate						AS	'Device Go-Live'
	,m.LastPingTime							AS	'Device Last Sync'
	,m.LastSale								AS	'Device Last Sale'
	,CASE d.Deactivated
		WHEN 0 THEN 'ONLINE'
		WHEN 1  THEN 'OFFLINE'
	END										AS	'Device Status'
	-- Information: OS & Apps --
	,''										AS	'App Info'
	,dc.OSVersion							AS	'OS Version'
	,dc.AppVersion							AS	'POS App Version'
	,m.FirmwareVersion						AS	'Device Firmware'
	,''										AS	'Anti-Malware Name'
	,''										AS	'Anti-Malware Version'
	,''										AS	'Anti-Malware Definition Date'
from Machine (nolock) m
	INNER JOIN Company (nolock) c on c.Id = m.CompanyId
	INNER JOIN Device (nolock) d on d.Id = m.DeviceId
	INNER JOIN (
	    SELECT [DeviceId] ,MAX(ActivationDate) AS ActivationDate
	    FROM [airvend_kentico].[dbo].[Activation] (nolock)
        GROUP BY DeviceId
    ) a ON a.DeviceId=d.DeviceId
	INNER JOIN DeviceConfig (nolock) dc on dc.Id = d.Id
where m.IsDeleted = 0 and c.IsDeleted = 0 and c.IsTest = 0
order by c.MasterAccountName, c.Name, m.Name