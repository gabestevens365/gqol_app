-- The ADM/v5 All-Devices Report
-- Run in RDS or a Reader (will not work in Snowflake)
-- Version 2. Worked on 2023.07.15
SELECT
	''                                          AS	"Quick Ref"
	,'365 Retail Markets'                       AS	"Platform Parent"
	,'ADM/v5'                                   AS	"Platform"
	,COALESCE(sfe.OpGroup, "NONE")              AS	"Operator Group"
	,sfediv.value                               AS	"Operator Division"
	,COALESCE(o.Name, "Orphan Operation")		AS	"Operator Name"
	,COALESCE(l.Name, "Orphan Location")		AS	"Location Name"
	,k.Name                                     AS	"Serial Number"
	-- Information: Operation --
	,''                                         AS	"Op Info"
	,o.ID                                       AS	"Op ID"
	,COALESCE(o.Name, "Orphan Operation")		AS	"Op Name"
	,o.SageNumber1                              AS	"Op Sage ID"
	,o.ADDRESS                                  AS	"Op Address"
	,o.CITY                                     AS	"Op City"
	,o.STATE                                    AS	"Op State"
	,o.ZIP                                      AS	"Op Zip"
	,o.COUNTRY                                  AS	"Op Country"
	,o.CURRENCY                                 AS  "Op Currency"
	-- Information: Location --
	,''                                         AS	"Loc Info"
	,COALESCE(c.Name, "No Campus")              AS  "Loc Campus/MSL Name"
	,l.ID                                       AS	"Loc ID"
	,COALESCE(l.Name, "Orphan Location")		AS	"Loc Name"
	,l.Address                                  AS	"Loc Address"
	,l.City                                     AS	"Loc City"
	,l.State                                    AS	"Loc State"
	,l.Zip                                      AS	"Loc Zip"
	,l.Country                                  AS  "Loc Country"
	,l.DateCreated                              AS	"Loc Go-Live"
	,l.SIC                                      AS	"Loc Standard Industry Classification"
	-- Information: Device --
	,''                                         AS  "Device Info"
	,k.ID                                       AS	"Device ID"
	,k.Name                                     AS  "Device Serial"
	,k.Type                                     AS	"Device Type"
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
		ELSE k.HWTYPE
  END                                           AS	"Device Model"
	,cp.NAME                                    AS	"Device CC Processor"
	,t.CardReader                               AS	"Device CC Reader"
	,fp.VALUE                                   AS	"Device FP Reader"
	,k.DeployDate                               AS  "Device Go-Live"
	,k.LastFullSync                             AS	"Device Last Sync"
	,ks.LASTSALE                                AS	"Device Last Sale"
	,k.STATUS                                   AS	"Device Status"
	-- Information: OS & Apps --
	,''                                         AS	"App Info"
	,CONCAT(SUBSTRING_INDEX(k.OSVERSION, '.', 2))	AS "OS Version"
	,k.KSKVERSION                               AS	"App POS Ver"
	,h.OTIFIRMWARE                              AS	"App OTI Firmware"
	,h.OTICONFIG                                AS	"App OTI Config"
	,''                                         AS	"App Anti-Malware"
	,''                                         AS	"App Anti-Malware Version"
	,''                                         AS	"App Anti-Malware Definition Date"
	,COALESCE(ol.VALUE,og.VALUE)                AS  "App Policies"

FROM Kiosk k
	LEFT JOIN org o				ON k.org = o.id
	LEFT JOIN location l	ON k.location = l.id
	LEFT JOIN CLIENT c		ON l.CLIENT = c.id
	
	-- Get the Operator Group info from SFECFG
	LEFT JOIN (
		SELECT NAME, VALUE AS OpGroup
		FROM sfecfg
		WHERE TYPE = 'SPECIALTYPE' AND CFGTYPE ='ORG'
	) sfe ON o.ID = sfe.NAME

	-- Get the Canteen Division info from SFECFG
	LEFT JOIN (
		SELECT NAME, VALUE
		FROM sfecfg
		WHERE TYPE = 'CANTEENDIVISION'
	) sfediv ON o.id = sfediv.NAME

	-- Get the Pico Device Types from SFECFG (adds about 2 seconds to the query of ~60k devices)
	LEFT JOIN ( SELECT picodevicetype.Value AS picovalue, picodevicetype.name AS p_name
		FROM sosdb.kiosk
            JOIN location ON kiosk.location = location.id
            INNER JOIN sosdb.sfecfg picodevicetype ON kiosk.id = picodevicetype.name
            JOIN org ON kiosk.org = org.id
		WHERE kiosk.HWType = 'PICO' AND picodevicetype.Type = 'PICODEVICETYPE'
	) p ON p.p_name=k.id

	-- Get the CardReader types from SFECFG (adds about 1 second to the query of ~60k devices)
	LEFT JOIN (
		SELECT
			ID, NAME,
			CASE VALUE
				WHEN 'C' THEN 'Castles'
				WHEN 'I' THEN 'IdTech'
				WHEN 'L' THEN 'LineaPro'
				WHEN 'M' THEN 'Magtec'
				WHEN 'N' THEN 'Nayax'
				WHEN 'O' THEN '365 Secure'
				WHEN 'V' THEN 'Verifone'
				ELSE VALUE
			END  CardReader
		FROM sfecfg
		WHERE TYPE = 'ENCRYPTMSR' AND CFGTYPE = 'KSK'
	) t ON k.ID = t.NAME

    -- Get the Last Transaction Date (adds about 2 seconds to the query of ~60k devices)
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
		) AS kiosk_info ON KS.ORG = kiosk_info.ORG AND KS.LOCATION = kiosk_info.LOCATION AND KS.KIOSK = kiosk_info.KIOSK
			GROUP BY KS.ORG, KS.LOCATION, KS.KIOSK
    ) KS ON o.ID = KS.ORG AND l.ID = KS.LOCATION AND k.ID = KS.KIOSK

	-- Fingerprint Reader Presence (Adds about 1 second to the query of ~60k devices)
	LEFT JOIN (
    SELECT NAME, VALUE
    FROM sfecfg
    WHERE TYPE = 'HASFP'
	) fp ON k.id = fp.NAME
	
	-- Get the Policy Values
	LEFT JOIN (
		SELECT ID, NAME, CONCAT('Org - ',VALUE) AS VALUE
		FROM sfecfg
		WHERE TYPE = 'GDPRTYPE' AND CFGTYPE = 'ORG'
	) og ON o.ID = og.NAME
	LEFT JOIN (
		SELECT ID, NAME, CONCAT('Location - ',VALUE) AS VALUE
		FROM sfecfg
		WHERE TYPE = 'GDPRTYPE' AND CFGTYPE = 'LOC'
	) ol ON l.ID = ol.NAME

	-- Needs Optimization
	-- Get the Card Processor (Adds about 18 seconds to the query of ~60k)
	LEFT JOIN sosdb.lookupstr cp	ON k.PROCESSOR1 = cp.KEYSTR AND CP.TYPE = 'CCPROCESSOR'

	-- Get the CC Firmware & Config from DashDB (adds about 58 seconds to the query of about ~60k devices)
	LEFT JOIN (
		SELECT h.KIOSKNAME
			,h.KIOSKINFO
			,REPLACE(JSON_EXTRACT(h.KIOSKINFO, '$.otifirmware'),CHAR(34), "")		AS OTIFIRMWARE
			,REPLACE(JSON_EXTRACT(h.KIOSKINFO, '$.oticonfig'),CHAR(34), "")			AS OTICONFIG
		FROM dashdb.hostinfo h
			INNER JOIN (
				SELECT KIOSKNAME, MAX(LASTUPDATED) AS LASTUPDATED
				FROM dashdb.hostinfo
				GROUP BY KIOSKNAME
			) AS u ON h.KIOSKNAME = u.KIOSKNAME AND h.LASTUPDATED = u.LASTUPDATED
		WHERE JSON_VALID(h.kioskinfo) = 1 AND h.KIOSKINFO IS NOT NULL
		GROUP BY h.KIOSKNAME, h.kioskinfo
	) AS h ON k.NAME = h.KIOSKNAME


ORDER BY sfe.OpGroup, sfediv.Value, o.Name, l.Name, k.type