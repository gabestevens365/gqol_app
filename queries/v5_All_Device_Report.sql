SELECT
-- This is the All-Devices Detail Query for v5. This will not run in Snowflake. Use reader.365rm.us
	-- Information: Top Level --
	'v5'													AS  "Platform"
	-- Information: Operation --
	,s.VALUE											AS  "Operation Group"
	,o.SAGENUMBER1								AS  "Operation Sage ID"
	,o.ID													AS	"Operation ID"
	,o.NAME												AS  "Operation Name"
	,o.ADDRESS										AS	"Operation Address"
	,o.CITY												AS	"Operation City"
	,o.STATE											AS	"Operation State"
	,o.ZIP												AS	"Operation Zip"
	,o.COUNTRY										AS	"Operation Country"
	,''														AS	"2"
	-- Information: Location --
	,l.ID													AS	"Location ID"
	,l.NAME												AS  "Location Name"
	,l.ADDRESS										AS	"Location Address"
	,l.CITY												AS	"Location City"
	,l.STATE											AS	"Location State"
	,l.ZIP												AS	"Location Zip"
	,l.COUNTRY										AS  "Location Country"
	,o.CURRENCY										AS  "Location Currency"
	,c.NAME												AS  "Location Campus/MSL Name"
	,l.ACTIVATIONDATE							AS	"Location Go-Live"
	,''														AS	"3"
	-- Information: Device --
	,k.NAME												AS  "Device Serial"
  ,CASE UPPER(k.HWTYPE)
		WHEN 'BEACON'           THEN 'Beacon'
		WHEN 'ELO PRO'          THEN 'ReadyTouch (ELO Pro)'
		WHEN 'GEN3'             THEN 'Gen3'
		WHEN 'GEN3C'            THEN 'Gen3'
		WHEN 'MM6'              THEN 'MM6'
		WHEN 'NANO'             THEN 'Nano'
		WHEN 'PICO'             THEN CONCAT('Pico', ' [', p.picovalue, ']')
		WHEN 'PICO-STOCKWELL'   THEN 'Pico-Stockwell'
		WHEN 'REV.B'            THEN 'ReadyTouch (REV.B)'
		WHEN 'SLABB'            THEN 'ReadyTouch (SLABB)'
		WHEN 'SODASTREAM'       THEN 'SodaStream'
		WHEN 'X3'               THEN 'ReadyTouch (X3)'
  END                        		AS "Model"
	,CARDREADER										AS	"Device CC Reader"
	,cp.NAME											AS	"Device CC Processor"
	,h.OTIFIRMWARE								AS	"Device CC Firmware"
	,h.OTICONFIG									AS	"Device CC Config"
	,k.STATUS											AS	"Device Status"
	,k.LastFullSync								AS	"Device Last Sync"
	,ks.LASTSALE									AS	"Device Last Sale"
	,k.DeployDate									AS  "Device Go-Live"
	,REPLACE(h.OS,'"','')					AS  "App OS Ver"
	,k.KSKVERSION									AS	"KSK Version"
	
FROM org o
	INNER JOIN location l ON o.ID = l.ORG
	INNER JOIN kiosk k ON l.ID = k.LOCATION
	LEFT JOIN CLIENT c ON c.ID = l.CLIENT
	LEFT JOIN sosdb.lookupstr cp	ON k.PROCESSOR1 = cp.KEYSTR AND CP.TYPE = 'CCPROCESSOR'
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

	LEFT JOIN (
		SELECT ID, NAME,
		CASE UPPER(VALUE)
			WHEN 'C' THEN 'Castles'
			WHEN 'I' THEN 'IdTech'
			WHEN 'L' THEN 'LineaPro'
			WHEN 'M' THEN 'Magtec'
			WHEN 'N' THEN 'Nayax'
			WHEN 'O' THEN '365 Secure'
			WHEN 'V' THEN 'Verifone'
		END  CARDREADER
		FROM sfecfg
		WHERE UPPER(TYPE) = 'ENCRYPTMSR' AND UPPER(CFGTYPE) = 'KSK'
	) t ON k.ID = t.NAME

	-- Try getting from kioskstatus instead of salesheader
	LEFT JOIN (
		SELECT kiosk, MAX(lasttransdate) AS LASTSALE
		FROM kioskstatus
		GROUP BY kiosk
	) ks ON ks.kiosk = k.id
	
	-- My DashDB Left Join -- This block is what forces the query into reader.365rm.us instead of snowflake.
	LEFT JOIN (
		SELECT h.KIOSKNAME
			,REPLACE(JSON_EXTRACT(h.BASICINFO, '$.os'),CHAR(34),"""")							AS OS
			,h.KIOSKINFO
			,REPLACE(JSON_EXTRACT(h.KIOSKINFO, '$.otifirmware'),CHAR(34), """")		AS OTIFIRMWARE
			,REPLACE(JSON_EXTRACT(h.KIOSKINFO, '$.oticonfig'),CHAR(34), """")			AS OTICONFIG
		FROM dashdb.hostinfo h
			INNER JOIN (
				SELECT KIOSKNAME, MAX(LASTUPDATED) AS LASTUPDATED
				FROM dashdb.hostinfo 
				GROUP BY KIOSKNAME
			) AS u ON h.KIOSKNAME = u.KIOSKNAME AND h.LASTUPDATED = u.LASTUPDATED
		WHERE JSON_VALID(h.kioskinfo) = 1 AND h.KIOSKINFO IS NOT NULL AND JSON_VALID(h.basicinfo) = 1
		GROUP BY h.KIOSKNAME, REPLACE(JSON_EXTRACT(h.BASICINFO, '$.os'),CHAR(34),"""")
	) AS h ON k.NAME = h.KIOSKNAME

ORDER BY o.NAME, c.NAME, l.NAME, k.HWTYPE, k.NAME
