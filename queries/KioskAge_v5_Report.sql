-- This is the v5 Kiosk-Age and OS Version Report. This will not run in Snowflake. Use reader.365rm.us
-- This worked on 2023.06.28 - GS
SELECT
    s.VALUE                         AS  "Operation Group"
    ,sfe_division.value             AS	"Division"
    ,''                             AS	"Champion"
    ,o.SAGENUMBER1                  AS	"Sage ID"
    ,o.COUNTRY                      AS  "Country"
    ,o.NAME                         AS  "Operation Name"
    ,l.NAME                         AS  "Location Name"
    ,k.NAME                         AS  "Device Serial"
    ,CASE UPPER(k.HWTYPE)
		WHEN 'GEN3'             THEN 'Gen3'
		WHEN 'GEN3C'            THEN 'Gen3'
		WHEN 'X3'               THEN 'ReadyTouch (X3)'
		WHEN 'SLABB'            THEN 'ReadyTouch (SLABB)'
		WHEN 'REV.B'            THEN 'ReadyTouch (REV.B)'
		WHEN 'ELO PRO'          THEN 'ReadyTouch (ELO Pro)'
		WHEN 'NANO'             THEN 'Nano'
		WHEN 'PICO'             THEN 'Pico'
		WHEN 'PICO-STOCKWELL'   THEN 'Pico-Stockwell'
		WHEN 'BEACON'           THEN 'Beacon'
		WHEN 'MM6'              THEN 'MM6'
		WHEN 'SODASTREAM'       THEN 'SodaStream'
    END                             AS  "Model"
    ,k.STATUS                       AS	"Device Status"
    ,k.LastFullSync                 AS	"Device Last Sync"
    ,ks.LASTSALE                    AS	"Device Last Sale"
    ,k.DeployDate                   AS  "Device Go-Live"
    ,CONCAT(SUBSTRING_INDEX(k.OSVERSION, '.', 2)) AS "OS Version"
    ,h.product                      AS	"CPU Product"

FROM org o
	INNER JOIN location l ON o.ID = l.ORG
	INNER JOIN kiosk k ON l.ID = k.LOCATION
	LEFT JOIN CLIENT c ON c.ID = l.CLIENT

	-- Get the Operator Groups
	LEFT JOIN (
		SELECT ID, NAME, VALUE
		FROM sfecfg
		WHERE TYPE = 'SPECIALTYPE' AND CFGTYPE ='ORG'
	) s ON o.ID = s.NAME

    -- Get the Canteen Division data
    LEFT JOIN (
        SELECT ID, NAME, VALUE
        FROM sfecfg
        WHERE TYPE = 'CANTEENDIVISION'
    ) sfe_division ON o.id = sfe_division.NAME

    -- Get the Last Transaction Date... filtering out the stuff we don't need first to speed up the query.
    LEFT JOIN (
        SELECT
            KS.ORG,
            KS.LOCATION,
            KS.KIOSK,
            MAX(KS.LASTTRANSDATE) AS LASTSALE
        FROM SOSDB.KIOSKSTATUS KS
        INNER JOIN (
            SELECT k.ORG, k.LOCATION, k.ID AS KIOSK
            FROM sosdb.org o
            INNER JOIN sosdb.location l ON o.ID = l.ORG
            INNER JOIN sosdb.kiosk k ON l.ID = k.LOCATION
            WHERE
                k.NAME LIKE 'VSH%' OR k.NAME LIKE 'KSK%'
                AND k.HWTYPE NOT IN ('BEACON','MM6', 'NANO', 'X3', 'SLABB', 'REV.B', 'ELO PRO')
        ) AS kiosk_info ON KS.ORG = kiosk_info.ORG AND KS.LOCATION = kiosk_info.LOCATION AND KS.KIOSK = kiosk_info.KIOSK
        GROUP BY KS.ORG, KS.LOCATION, KS.KIOSK
    ) KS ON o.ID = KS.ORG AND l.ID = KS.LOCATION AND k.ID = KS.KIOSK

	-- My DashDB Left Join -- This block is what forces the query into reader.365rm.us instead of snowflake.
	LEFT JOIN (
		SELECT
		    h.KIOSKNAME
		    ,SUBSTRING_INDEX(SUBSTRING_INDEX(REPLACE(JSON_EXTRACT(h.BASICINFO, '$.systemInfo'), CHAR(34), ''), 'product=', -1), '|', 1) AS product
		FROM dashdb.hostinfo h
        INNER JOIN (
            SELECT KIOSKNAME, MAX(LASTUPDATED) AS LASTUPDATED
            FROM dashdb.hostinfo
            GROUP BY KIOSKNAME
        ) AS u ON h.KIOSKNAME = u.KIOSKNAME AND h.LASTUPDATED = u.LASTUPDATED
        WHERE JSON_VALID(h.kioskinfo) = 1 AND h.KIOSKINFO IS NOT NULL AND JSON_VALID(h.basicinfo) = 1
        GROUP BY h.KIOSKNAME, REPLACE(JSON_EXTRACT(h.BASICINFO, '$.systemInfo'), CHAR(34), "")
    ) AS h ON k.NAME = h.KIOSKNAME

WHERE k.NAME LIKE 'VSH%' OR k.NAME LIKE 'KSK%'
	AND k.HWTYPE NOT IN ('BEACON','MM6', 'NANO', 'X3', 'SLABB', 'REV.B', 'ELO PRO')

UNION
SELECT
    COALESCE(s.VALUE, 'NONE')       AS  "Operation Group"
    ,sfe_division.value             AS	"Division"
    ,''                             AS	"Champion"
    ,o.SAGENUMBER1                  AS	"Sage ID"
    ,o.COUNTRY                      AS  "Country"
    ,COALESCE(o.NAME, 'Orphan Op')  AS  "Operation Name"
    ,COALESCE(l.NAME, 'Orphan Loc') AS  "Location Name"
    ,k.NAME                         AS  "Device Serial"
    ,CASE UPPER(k.HWTYPE)
		WHEN 'GEN3'             THEN 'Gen3'
		WHEN 'GEN3C'            THEN 'Gen3'
		WHEN 'X3'               THEN 'ReadyTouch (X3)'
		WHEN 'SLABB'            THEN 'ReadyTouch (SLABB)'
		WHEN 'REV.B'            THEN 'ReadyTouch (REV.B)'
		WHEN 'ELO PRO'          THEN 'ReadyTouch (ELO Pro)'
		WHEN 'NANO'             THEN 'Nano'
		WHEN 'PICO'             THEN 'Pico'
		WHEN 'PICO-STOCKWELL'   THEN 'Pico-Stockwell'
		WHEN 'BEACON'           THEN 'Beacon'
		WHEN 'MM6'              THEN 'MM6'
		WHEN 'SODASTREAM'       THEN 'SodaStream'
    END                             AS "Model"
	,k.STATUS                       AS	"Device Status"
	,k.LastFullSync                 AS	"Device Last Sync"
	,ks.LASTSALE                    AS	"Device Last Sale"
	,k.DeployDate                   AS  "Device Go-Live"
	,CONCAT(SUBSTRING_INDEX(k.OSVERSION, '.', 2)) AS "OS Version"
	,''                             AS	"CPU Product"
FROM kiosk k
    LEFT JOIN location l ON UPPER(l.id)=UPPER(k.location)
    LEFT JOIN org o ON o.id=k.org
    LEFT JOIN CLIENT c ON c.ID = l.CLIENT

  -- Get the Operator Group Data
    LEFT JOIN (
		SELECT ID, NAME, VALUE
		FROM sfecfg
		WHERE TYPE = 'SPECIALTYPE' AND CFGTYPE ='ORG'
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

WHERE location IS NULL
	AND k.NAME LIKE 'VSH%' OR k.NAME LIKE 'KSK%'
	AND k.HWTYPE NOT IN ('BEACON', 'MM6', 'NANO', 'X3', 'SLABB', 'REV.B', 'ELO PRO')
ORDER BY 1, 2, 6, 7, 8;