-- The CompanyKitchen All-Devices Report
-- Version 2. Worked on 2023.09.13
SELECT
	-- Information: Top Level --
	''                                              AS	'Quick Ref'
	,'365 Retail Markets'                           AS  'Platform Parent'
	,'CompanyKitchen'                               AS	'Platform'
	,CASE
		WHEN cp.pos_type = 8    AND LEFT(tsv.blaster_version, 1) = "2"      THEN "Market"
		WHEN cp.pos_type = 8    AND LEFT(tsv.blaster_version, 1) <> "2"     THEN "Dining"
		WHEN cp.pos_type = 7    AND c.companyid IN ("1", "5")               THEN "Dining"
		WHEN cp.pos_type = 7    AND	c.companyid NOT IN ("1", "5")           THEN "Market"
		ELSE "Unknown"
	END                                             AS	"Level Of Business"
	,''                                             AS	'Operator Group'
	,d.districtname                                 AS  'Operator District'
	,c.companyname                                  AS	'Operator Name'
	,b.businessname                                 AS	'Location Name'
	,cp.name                                        AS	'Terminal Name'
	,cp.client_programid                            AS	'Serial / TID'
	-- Information: Operation --
	,''                                             AS	'Op Info'
	,c.companyid                                    AS	'Op ID'
	,c.companyname                                  AS	'Op Name'
	,c.street                                       AS	'Op Address'
	,c.city                                         AS	'Op City'
	,c.state                                        AS	'Op State'
	,c.zip                                          AS	'Op Zip'
	-- Information: Location --
	,''                                             AS	'Loc Info'
	,b.businessid                                   AS	'Loc ID'
	,b.businessname                                 AS	'Loc Name'
	,cp.name                                        AS	'Loc Terminal Name'
	,b.street                                       AS	'Loc Address'
	,b.city                                         AS	'Loc City'
	,b.state                                        AS	'Loc State'
	,b.zip                                          AS	'Loc Zip'
	,b.country                                      AS	'Loc Country'
	-- Information: Device --
	,''                                             AS  'Device Info'
	,CASE
		WHEN cp.pos_type = 8    AND LEFT(tsv.blaster_version, 1) = "2"      THEN "Market"
		WHEN cp.pos_type = 8    AND LEFT(tsv.blaster_version, 1) <> "2"     THEN "Dining"
		WHEN cp.pos_type = 7    AND c.companyid IN ("1", "5")               THEN "Dining"
		WHEN cp.pos_type = 7    AND	c.companyid NOT IN ("1", "5")           THEN "Market"
		ELSE "Unknown"
	END                                             AS	"Device LOB"
	,cp.client_programid                            AS	'Device TID (Serial)'
	,bc.category_name                               AS	'Device Type'
	,pt.Name                                        AS	'Device Model'
	,kdc.device_name                                AS	'Device CC Reader'
	,kdc.additional_configuration                   AS	'Device CC Terminal'
	,cp.send_time                                   AS 	'Device Last Sync'
	,''                                             AS  'App Info'
	,CASE
		WHEN cp.pos_type = 7    THEN "Ubuntu 12.04"
		WHEN cp.pos_type = 8
            AND LEFT(tsv.blaster_version, 1) = "2"
            AND kdc.device_name = "castle"
                                THEN "Ubuntu 18.04"
		WHEN cp.pos_type = 8    THEN "Ubuntu 16.04"
	END                                             AS	"OS Version"
	,CASE
		WHEN cp.pos_type = 7    THEN "Aeris"
		WHEN cp.pos_type = 8    THEN "Blaster"
		ELSE "Testing/Other"
	END                                             AS	"POS App Name"
	,tsv.blaster_version                            AS	"POS App Version"
	,''                                             AS  'Anti-Malware'
	,''                                             AS  'Anti-Malware Version'
	,''                                             AS  'Anti-Malware Definition Date'
	,r.terms                                        AS	'Policy: Terms'
	,r.privacy                                      AS	'Policy: Privacy'
	,r.biometric                                    AS	'Policy: Biometric'
FROM mburris_businesstrack.company c
	JOIN mburris_businesstrack.business b                   ON b.companyid = c.companyid
	LEFT JOIN mburris_businesstrack.business_category bc    ON bc.categoryid = b.categoryid
	LEFT JOIN mburris_manage.client_programs cp             ON cp.businessid = b.businessid
	-- Get the credit card reader type
	LEFT JOIN snoke.kiosk_device_configuration kdc
	    ON kdc.terminal_id = cp.client_programid
	    AND device_type = 'msr'
	-- Get the POS Device Types
	LEFT JOIN mburris_manage.pos_type pt ON cp.pos_type = pt.pos_type
	-- Get the District Names
	LEFT JOIN mburris_businesstrack.district d ON b.districtid = d.districtid
	-- Get the Policies
	LEFT JOIN (
		SELECT
			state,
			MAX(IF(notice_type = 'terms', VERSION, NULL)) AS terms,
			MAX(IF(notice_type = 'privacy', VERSION, NULL)) AS privacy,
			MAX(IF(notice_type = 'biometric', VERSION, NULL)) AS biometric
		FROM mburris_businesstrack.regulatory_notice_by_state
		GROUP BY state
		) r ON b.state = r.state
	-- Get the terminal versions
	LEFT JOIN snoke.terminal_software_version tsv
	    ON tsv.business_id = b.businessid
	    AND tsv.terminal_id = cp.client_programid

WHERE b.closed = 0
	AND bc.category_name = 'Kiosk'
	AND pt.name != 'TractorBeam'
	AND b.businessname NOT LIKE '[%]%'
	AND b.businessname NOT LIKE 'z%'
	AND b.businessname NOT LIKE 'test kiosk%'
	AND b.businessname NOT LIKE '|Vend%'
	AND b.businessname NOT LIKE 'Blank Unit'
	AND b.businessname NOT LIKE 'ADM%'
	AND b.businessname NOT LIKE 'BEA%'
	AND b.businessname NOT LIKE 'SPARE%'
	AND c.companyname != 'CKL - TEST Company'
  AND cp.parent IS NOT NULL
  AND cp.parent != 2198
ORDER BY d.districtname, c.companyname, b.businessname, cp.send_time DESC