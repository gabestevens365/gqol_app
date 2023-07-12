SELECT
-- This is the v5 Kiosk-Age and OS Version Report. This will not run in Snowflake. Use reader.365rm.us
-- This worked on 2023.06.28 - GS
	s.VALUE							AS  "Operation Group"
    ,sfe_division.value     		AS	"Division"
	,''								AS	"Champion"
    ,o.SAGENUMBER1                  AS	"Sage ID"
	,o.COUNTRY                      AS  "Country"
	,o.NAME							AS  "Operation Name"
	,l.NAME							AS  "Location Name"
	,k.NAME							AS  "Device Serial"
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
    END                        		AS  "Model"
	,k.STATUS						AS	"Device Status"
	,k.LastFullSync					AS	"Device Last Sync"
	,ks.LASTSALE					AS	"Device Last Sale"
	,k.DeployDate					AS  "Device Go-Live"
	,TIMESTAMPDIFF(YEAR, k.DeployDate, NOW() ) AS "ADM Device Age"
	-- Information: OS & Apps --
	,k.OSVERSION                    AS  "OS Version"
	,REPLACE(h.systemInfo, '"', '')	AS	"systemInfo"
	,''								AS	"CPU Product"

FROM org o
	INNER JOIN location l ON o.ID = l.ORG
	INNER JOIN kiosk k ON l.ID = k.LOCATION
	LEFT JOIN CLIENT c ON c.ID = l.CLIENT

	-- Get the Operator Groups
	LEFT JOIN (
		SELECT ID, NAME, VALUE
		FROM sfecfg
		WHERE UPPER(TYPE) = 'SPECIALTYPE' AND UPPER(CFGTYPE) ='ORG'
	) s ON o.ID = s.NAME

	-- Get the Pico device types
	LEFT JOIN ( SELECT picodevicetype.Value AS picovalue, picodevicetype.name AS p_name
		FROM sosdb.kiosk
			JOIN location ON kiosk.location = location.id
			INNER JOIN sosdb.sfecfg picodevicetype ON kiosk.id = picodevicetype.name
			JOIN org ON kiosk.org = org.id
		WHERE kiosk.HWType = 'PICO'
			AND picodevicetype.Type = 'PICODEVICETYPE'
	) p ON p.p_name=k.id

    -- Get the Canteen Division data
    LEFT JOIN (
        SELECT ID, NAME, VALUE
        FROM sfecfg
        WHERE TYPE = 'CANTEENDIVISION'
    ) sfe_division ON o.id = sfe_division.NAME

	-- Get the last transaction data
	LEFT JOIN (
		SELECT kiosk, MAX(lasttransdate) AS LASTSALE
		FROM kioskstatus
		GROUP BY kiosk
	) ks ON ks.kiosk = k.id

	-- My DashDB Left Join -- This block is what forces the query into reader.365rm.us instead of snowflake.
	LEFT JOIN (
		SELECT
		    h.KIOSKNAME
		    ,REPLACE(JSON_EXTRACT(h.BASICINFO, '$.systemInfo'),CHAR(34),"""") AS systemInfo
		FROM dashdb.hostinfo h
			INNER JOIN (
				SELECT KIOSKNAME, MAX(LASTUPDATED) AS LASTUPDATED
				FROM dashdb.hostinfo
				GROUP BY KIOSKNAME
			) AS u ON h.KIOSKNAME = u.KIOSKNAME AND h.LASTUPDATED = u.LASTUPDATED
			WHERE JSON_VALID(h.kioskinfo) = 1 AND h.KIOSKINFO IS NOT NULL AND JSON_VALID(h.basicinfo) = 1
		GROUP BY h.KIOSKNAME
	) AS h ON k.NAME = h.KIOSKNAME

WHERE k.NAME LIKE 'VSH%' OR k.NAME like 'KSK%'
	AND k.HWTYPE NOT IN ('BEACON','MM6', 'NANO', 'X3', 'SLABB', 'REV.B', 'ELO PRO')

UNION
SELECT
	s.VALUE							AS  "Operation Group"
    ,sfe_division.value    			AS	"Division"
	,''								AS	"Champion"
	,o.COUNTRY                      AS  "Country"
    ,o.SAGENUMBER1                  AS	"Sage ID"
	,o.NAME							AS  "Operation Name"
	,l.NAME							AS  "Location Name"
	,k.NAME							AS  "Device Serial"
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
	,TIMESTAMPDIFF(YEAR, k.DeployDate, NOW() ) AS "ADM Device Age"
	-- Information: OS & Apps --
	,k.OSVERSION                    AS  "OS Version"
	,''								AS	"systemInfo"
	,''								AS	"CPU Product"
FROM kiosk k
    LEFT JOIN location l ON UPPER(l.id)=UPPER(k.location)
    LEFT JOIN org o ON o.id=k.org
    LEFT JOIN CLIENT c ON c.ID = l.CLIENT

  -- Get the Operator Group Data
    LEFT JOIN (
		SELECT ID, NAME, VALUE
		FROM sfecfg
		WHERE UPPER(TYPE) = 'SPECIALTYPE' AND UPPER(CFGTYPE) ='ORG'
	) s ON o.ID = s.NAME

	-- Get the last transaction date
	LEFT JOIN (
		SELECT kiosk, MAX(lasttransdate) AS LASTSALE
		FROM kioskstatus
		GROUP BY kiosk
	) ks ON ks.kiosk = k.id

	-- JOIN the Canteen Division data
	LEFT JOIN (
			SELECT ID, NAME, VALUE
			FROM sfecfg
			WHERE TYPE = 'CANTEENDIVISION'
	) sfe_division ON o.id = sfe_division.NAME

    -- Get the Pico Device Types
    LEFT JOIN ( SELECT picodevicetype.Value AS picovalue, picodevicetype.name AS p_name
		FROM sosdb.kiosk
			JOIN location ON kiosk.location = location.id
			INNER JOIN sosdb.sfecfg picodevicetype ON kiosk.id = picodevicetype.name
			JOIN org ON kiosk.org = org.id
		WHERE kiosk.HWType = 'PICO'
			AND picodevicetype.Type = 'PICODEVICETYPE'
	) p ON p.p_name=k.id

WHERE location IS NULL
	AND k.NAME LIKE 'VSH%' OR k.NAME like 'KSK%'
	AND k.HWTYPE NOT IN ('BEACON', 'MM6', 'NANO', 'X3', 'SLABB', 'REV.B', 'ELO PRO')