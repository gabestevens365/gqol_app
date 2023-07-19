SELECT
	-- Information: Top Level --
	'365 Retail Markets'		AS	'Platform Parent'
	,'CompanyKitchen'				AS	'Platform'
	,''											AS	'LOB'
	,''											AS	'1'
	-- Information: Location --
	,b.businessid						AS	'Location ID'
	,b.businessname					AS	'Location Name'
	,''											AS	'Location Brand'
	,b.street								AS	'Location Address'
	,b.city									AS	'Location City'
	,b.state								AS	'Location State'
	,b.zip									AS	'Location Zip'
	,b.country							AS	'Location Country'
	,''											AS	'Location Currency'
	,''											AS	'Location Campus/GMA Name'
	,''											AS	'Location GMA'
	,''											AS	'Location Go-Live'
	,''											AS	'2'
	-- Information: Operation --
	,''											AS	'Operation Group'
	,''											AS	'Operation Sage ID'
	,c.companyid						AS	'Operation ID'
	,''											AS	'Operation Accounting ID'
	,c.companyname					AS	'Operation Name'
	,c.street								AS	'Operation Address'
	,c.city									AS	'Operation City'
	,c.state								AS	'Operation State'
	,c.zip									AS	'Operation Zip'
	,''											AS	'Operation Country'
	,''											AS	'3'
	-- Information: Device --
	,cp.client_programid		AS	'Device Serial'
	,CASE
		WHEN cp.pos_type = 7 THEN 'Aeris'
		WHEN cp.pos_type = 8 THEN 'Blaster'
		WHEN cp.pos_type = 9 THEN 'Tractor Beam'
		ELSE 'Testing/Other'
	END											AS	'Device Model'
	,''											AS	'Device CC Reader'
	,''											AS	'Device CC Reader Firmware'
	,CASE
		WHEN b.closed = 0 THEN 'Active'
		WHEN b.closed = 1 THEN 'Closed'
		ELSE 'Unknown'
	END											AS	'Device (OP) Status'
	,cp.send_time						AS 	'Device Last Sync'
	,''											AS	'Device Last Sale'
	,''											AS	'Device Go-Live'
	,''											AS	'4'
	-- Information: OS & Apps --
	,''											AS	'App OS Ver'
	,''											AS	'App POS'
	,''											AS	'App POS Ver'
	,''											AS	'App Anti-Malware'
	,''											AS	'App Anti-Malware Version'
	,''											AS	'App Anti-Malware Definition Date'
	,''											AS	'App Biometric Policy'
	,''											AS	'App Biometric Policy Version'
	,''											AS	'App Privacy Policy'
	,''											AS	'App Privacy Policy Version'
	,''											AS	'App TermsOfService'
	,''											AS	'App TermsOfService Version'
--	,bc.category_name				AS category
--	,kdc.device_name					as castle_config
	,cp2.parent AS terminal_parent
FROM	mburris_businesstrack.company c
	JOIN mburris_businesstrack.business b	ON b.companyid = c.companyid
	LEFT JOIN mburris_businesstrack.business_category bc ON bc.categoryid = b.categoryid
	LEFT JOIN mburris_manage.client_programs cp ON cp.businessid = b.businessid
    LEFT JOIN mburris_manage.client_programs cp2 ON cp2.client_programid = cp.parent
	LEFT JOIN snoke.kiosk_device_configuration kdc ON kdc.terminal_id = cp.client_programid
		AND device_type = 'msr'
		AND device_name = 'castle'
WHERE b.closed = 0
	AND bc.category_name = 'Kiosk'
	AND b.businessname NOT LIKE '[%]%'
	AND b.businessname NOT LIKE 'zKiosk%'
	AND b.businessname NOT LIKE 'zBeaconKiosk%'
	AND b.businessname NOT LIKE 'test kiosk%'
	AND b.businessname NOT LIKE '|Vend%'
	AND b.businessname NOT LIKE 'Blank Unit'
  AND cp.parent IS NOT NULL