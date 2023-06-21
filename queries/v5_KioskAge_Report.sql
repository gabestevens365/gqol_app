SELECT
-- This is the v5 Kiosk-Age and OS Version Report. This will not run in Snowflake. Use reader.365rm.us
-- This working on 2023.05.12 - G.S.
	s.VALUE							AS  "Operation Group"
  ,sfe_division.value     			AS	"Division"
	,''								AS	"Champion"
	,''								AS	"Cost Center"
	,o.SAGENUMBER1					AS  "Operation Sage ID"
	,o.NAME							AS  "Operation Name"
	,l.NAME							AS  "Location Name"
	,k.NAME							AS  "Device Serial"
	,''								AS	"VSH Generation"
  ,CASE UPPER(k.HWTYPE)
		WHEN 'GEN3'             THEN 'Gen3'
		WHEN 'GEN3C'            THEN 'Gen3'
		WHEN 'X3'               THEN 'ReadyTouch (X3)'
		WHEN 'SLABB'            THEN 'ReadyTouch (SLABB)'
		WHEN 'REV.B'            THEN 'ReadyTouch (REV.B)'
		WHEN 'ELO PRO'          THEN 'ReadyTouch (ELO Pro)'
		WHEN 'NANO'             THEN 'Nano'
		WHEN 'PICO'             THEN CONCAT('Pico', ' [', p.picovalue, ']')
		WHEN 'PICO-STOCKWELL'   THEN 'Pico-Stockwell'
		WHEN 'BEACON'           THEN 'Beacon'
		WHEN 'MM6'              THEN 'MM6'
		WHEN 'SODASTREAM'       THEN 'SodaStream'
  END                        		AS "Model"
	,k.STATUS						AS	"Device Status"
	,k.LastFullSync					AS	"Device Last Sync"
	,ks.LASTSALE					AS	"Device Last Sale"
	,k.DeployDate					AS  "Device Go-Live"
	,k.DateCreated					AS	"DB Record Creation"
	,TIMESTAMPDIFF(YEAR, k.DeployDate, NOW() ) AS "Device Age"
	-- Information: OS & Apps --
	,REPLACE(h.OS,'"','')			AS  "App OS Ver"
	,REPLACE(h.systemInfo, '"', '')	AS	"systemInfo"
	,''								AS	"CPU Product"

FROM org o
	INNER JOIN location l ON o.ID = l.ORG
	INNER JOIN kiosk k ON l.ID = k.LOCATION 
	LEFT JOIN CLIENT c ON c.ID = l.CLIENT
	LEFT JOIN (
		SELECT ID, NAME, VALUE
		FROM sfecfg
		WHERE UPPER(TYPE) = 'SPECIALTYPE' AND UPPER(CFGTYPE) ='ORG'
	) s ON o.ID = s.NAME
	LEFT JOIN ( SELECT picodevicetype.Value AS picovalue, picodevicetype.name AS p_name
		FROM sosdb.kiosk
			JOIN location ON kiosk.location = location.id
			INNER JOIN sosdb.sfecfg picodevicetype ON kiosk.id = picodevicetype.name
			JOIN org ON kiosk.org = org.id
		WHERE kiosk.HWType = 'PICO'
			AND picodevicetype.Type = 'PICODEVICETYPE'
	) p ON p.p_name=k.id

    -- JOIN the Operator Group data
    LEFT JOIN (
        SELECT ID, NAME, VALUE
        FROM sfecfg
        WHERE TYPE = 'CANTEENDIVISION'
    ) sfe_division ON o.id = sfe_division.NAME
    
	-- Try getting from kioskstatus instead of salesheader
	LEFT JOIN (
		SELECT kiosk, MAX(lasttransdate) AS LASTSALE
		FROM kioskstatus
		GROUP BY kiosk
	) ks ON ks.kiosk = k.id

	-- My DashDB Left Join -- This block is what forces the query into reader.365rm.us instead of snowflake.
	LEFT JOIN (
		SELECT h.KIOSKNAME, REPLACE(JSON_EXTRACT(h.BASICINFO, '$.os'),CHAR(34),"""") AS OS
				,REPLACE(JSON_EXTRACT(h.BASICINFO, '$.systemInfo'),CHAR(34),"""") AS systemInfo
		FROM dashdb.hostinfo h
			INNER JOIN (
				SELECT KIOSKNAME, MAX(LASTUPDATED) AS LASTUPDATED
				FROM dashdb.hostinfo 
				GROUP BY KIOSKNAME
			) AS u ON h.KIOSKNAME = u.KIOSKNAME AND h.LASTUPDATED = u.LASTUPDATED
			WHERE JSON_VALID(h.kioskinfo) = 1 AND h.KIOSKINFO IS NOT NULL AND JSON_VALID(h.basicinfo) = 1
		GROUP BY h.KIOSKNAME, REPLACE(JSON_EXTRACT(h.BASICINFO, '$.os'),CHAR(34),"""")
	) AS h ON k.NAME = h.KIOSKNAME

WHERE k.NAME LIKE 'VSH%'
--	AND s.VALUE = 'Canteen'
UNION
SELECT 
	s.VALUE							AS  "Operation Group"
  ,sfe_division.value     			AS	"Division"
	,''								AS	"Champion"
	,''								AS	"Cost Center"
	,''								AS  "Operation Sage ID"
	,o.NAME							AS  "Operation Name"
	,l.NAME							AS  "Location Name"
	,k.NAME							AS  "Device Serial"
	,''								AS	"VSH Generation"
  ,CASE UPPER(k.HWTYPE)
		WHEN 'GEN3'             THEN 'Gen3'
		WHEN 'GEN3C'            THEN 'Gen3'
		WHEN 'X3'               THEN 'ReadyTouch (X3)'
		WHEN 'SLABB'            THEN 'ReadyTouch (SLABB)'
		WHEN 'REV.B'            THEN 'ReadyTouch (REV.B)'
		WHEN 'ELO PRO'          THEN 'ReadyTouch (ELO Pro)'
		WHEN 'NANO'             THEN 'Nano'
		WHEN 'PICO'             THEN CONCAT('Pico', ' [', p.picovalue, ']')
		WHEN 'PICO-STOCKWELL'   THEN 'Pico-Stockwell'
		WHEN 'BEACON'           THEN 'Beacon'
		WHEN 'MM6'              THEN 'MM6'
		WHEN 'SODASTREAM'       THEN 'SodaStream'
  END                        		AS "Model"
	,k.STATUS						AS	"Device Status"
	,k.LastFullSync					AS	"Device Last Sync"
	,ks.LASTSALE					AS	"Device Last Sale"
	,k.DeployDate					AS  "Device Go-Live"
	,k.DateCreated					AS	"DB Record Creation"
	,TIMESTAMPDIFF(YEAR, k.DeployDate, NOW() ) AS "Device Age"
	,REPLACE(h.OS,'"','')			AS  "App OS Ver"
	,''								AS	"systemInfo"
	,''								AS	"CPU Product"
 FROM kiosk k
LEFT JOIN location l 
ON UPPER(l.id)=UPPER(k.location)
LEFT JOIN org o
ON o.id=k.org
LEFT JOIN CLIENT c
ON c.ID = l.CLIENT
LEFT JOIN (
		SELECT h.KIOSKNAME, REPLACE(JSON_EXTRACT(h.BASICINFO, '$.os'),CHAR(34),"""") AS OS
		FROM dashdb.hostinfo h
			INNER JOIN (
				SELECT KIOSKNAME, MAX(LASTUPDATED) AS LASTUPDATED
				FROM dashdb.hostinfo 
				GROUP BY KIOSKNAME
			) AS u ON h.KIOSKNAME = u.KIOSKNAME AND h.LASTUPDATED = u.LASTUPDATED
			WHERE JSON_VALID(h.kioskinfo) = 1 AND h.KIOSKINFO IS NOT NULL AND JSON_VALID(h.basicinfo) = 1
		GROUP BY h.KIOSKNAME, REPLACE(JSON_EXTRACT(h.BASICINFO, '$.os'),CHAR(34),"""")
	) AS h ON k.NAME = h.KIOSKNAME
LEFT JOIN (
		SELECT ID, NAME, VALUE
		FROM sfecfg
		WHERE UPPER(TYPE) = 'SPECIALTYPE' AND UPPER(CFGTYPE) ='ORG'
	) s ON o.ID = s.NAME
	LEFT JOIN (
		SELECT kiosk, MAX(lasttransdate) AS LASTSALE
		FROM kioskstatus
		GROUP BY kiosk
	) ks ON ks.kiosk = k.id

	-- JOIN the Operator Group data
	LEFT JOIN (
			SELECT ID, NAME, VALUE
			FROM sfecfg
			WHERE TYPE = 'CANTEENDIVISION'
	) sfe_division ON o.id = sfe_division.NAME
    
LEFT JOIN ( SELECT picodevicetype.Value AS picovalue, picodevicetype.name AS p_name
		FROM sosdb.kiosk
			JOIN location ON kiosk.location = location.id
			INNER JOIN sosdb.sfecfg picodevicetype ON kiosk.id = picodevicetype.name
			JOIN org ON kiosk.org = org.id
		WHERE kiosk.HWType = 'PICO'
			AND picodevicetype.Type = 'PICODEVICETYPE'
	) p ON p.p_name=k.id
WHERE location IS NULL
	AND k.NAME LIKE 'VSH%'
--	AND s.VALUE = 'Canteen'