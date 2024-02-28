-- The ADM/v5 All-Devices Report
-- Run in RDS or a Reader (will not work in Snowflake)
-- Version 5. Split HWType & PicoDeviceType into multiple columns, removed location & org constraints on PicoDevice Type (so it shows for orphan devices)
-- Version 4. Worked on 2023.10.26 - Added Pico OS Build versions & Stockwell IDs
SELECT
	''                                              AS	"Quick Ref"
	,'365 Retail Markets'                           AS	"Platform Parent"
	,'ADM/v5'                                       AS	"Platform"
	,COALESCE(sfe.OpGroup, "NONE")                  AS	"Operator Group"
	,sfediv.value                                   AS	"Operator Division"
	,COALESCE(o.Name, "Orphan Operation")           AS	"Operator Name"
	,COALESCE(l.Name, "Orphan Location")            AS	"Location Name"
	,k.Name                                         AS	"Serial Number"
	-- Information: Operation --
	,''                                             AS	"Op Info"
	,o.ID                                           AS	"Op ID"
	,COALESCE(o.Name, "Orphan Operation")           AS	"Op Name"
	,o.SageNumber1                                  AS	"Op Sage ID"
	,o.ADDRESS                                      AS	"Op Address"
	,o.CITY                                         AS	"Op City"
	,o.STATE                                        AS	"Op State"
	,o.ZIP                                          AS	"Op Zip"
	,o.COUNTRY                                      AS	"Op Country"
	,o.CURRENCY                                     AS  "Op Currency"
	-- Information: Location --
	,''                                             AS	"Loc Info"
	,COALESCE(c.Name, "No Campus")                  AS  "Loc Campus/MSL Name"
	,l.ID                                           AS	"Loc ID"
	,COALESCE(l.Name, "Orphan Location")            AS	"Loc Name"
	,l.LocationNumber                               AS	"Loc Cost Center"
	,l.Address                                      AS	"Loc Address"
	,l.City                                         AS	"Loc City"
	,l.State                                        AS	"Loc State"
	,l.Zip                                          AS	"Loc Zip"
	,l.Country                                      AS  "Loc Country"
	,l.DateCreated                                  AS	"Loc Go-Live"
	,l.SIC                                          AS	"Loc Standard Industry Classification"
	-- Information: Device --
	,''                                             AS  "Device Info"
	,k.ID                                           AS	"Device ID"
	,k.Name                                         AS  "Device Serial"
	,k.Type                                         AS	"Device Type"
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
        WHEN 'STOCKWELL'        THEN 'Stockwell'
        WHEN 'BEACON'           THEN 'Beacon'
        WHEN 'MM6'              THEN 'MM6'
        WHEN 'SODASTREAM'       THEN 'SodaStream'
        ELSE k.HWTYPE
	END                                           	AS	"Device HW Type"
	,p.picovalue                                    AS	"Device Pico Type"
	,cp.NAME                                        AS	"Device CC Processor"
	,t.CardReader                                   AS	"Device CC Reader"
	,fp.VALUE                                       AS	"Device FP Reader"
	,sfe_billpresence.VALUE                         AS	"Device Bill Acceptor Present"
	,sfe_billmodel.VALUE                            AS	"Device Bill Acceptor Model"
	,k.DeployDate                                   AS  "Device Go-Live"
	,k.LastFullSync                                 AS	"Device Last Sync"
	,ks.LASTSALE                                    AS	"Device Last Sale"
	,k.STATUS                                       AS	"Device Status"
	-- Information: OS & Apps --
	,''                                             AS	"App Info"
	,CONCAT(SUBSTRING_INDEX(k.OSVERSION, '.', 2))   AS  "Kiosk OS Version"
	,dl.Version                                     AS  "Mobile OS Version"
	,k.KSKVERSION                                   AS	"POS Ver"
    ,sfe_swid.value                                 AS  "Stockwell ID"
	,sfe_vistar.value                               AS	"Vistar Reg Token"
	,''                                             AS	"Coretex Agent"
	,h.OTIFIRMWARE                                  AS	"OTI Firmware"
	,h.OTICONFIG                                    AS	"OTI Config"
	,h.OPTCONNECT_SERIAL                            AS  "OptConnect Serial"
	,''                                             AS	"Anti-Malware"
	,''                                             AS	"Anti-Malware Version"
	,''                                             AS	"Anti-Malware Definition Date"
	,COALESCE(ol.VALUE,og.VALUE)                    AS  "Policies"

FROM Kiosk k
    LEFT JOIN org o         ON k.org = o.id
    LEFT JOIN location l    ON k.location = l.id
    LEFT JOIN CLIENT c      ON l.CLIENT = c.id

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

    -- Get the Bill Acceptor Presence info from SFECFG
    LEFT JOIN (
        SELECT NAME, VALUE
        FROM sfecfg
        WHERE TYPE = 'BILLACCEPTOR'
    ) sfe_billpresence ON k.id = sfe_billpresence.NAME

    -- Get the Bill Acceptor Model info from SFECFG
    LEFT JOIN (
        SELECT NAME, VALUE
        FROM sfecfg
        WHERE TYPE = 'BILLACCEPTORMODEL'
    ) sfe_billmodel ON k.id = sfe_billmodel.NAME

    -- Get the Stockwell ID info from SFECFG
    LEFT JOIN (
        SELECT NAME, VALUE
        FROM sfecfg
        WHERE TYPE = 'STOCKWELLSTOREID'
    ) sfe_swid ON l.id = sfe_swid.name

	-- Get the Pico Device Types from SFECFG (adds about 2 seconds to the query of ~60k devices)
	LEFT JOIN ( SELECT picodevicetype.Value AS picovalue, picodevicetype.name AS p_name
		FROM sosdb.kiosk
			INNER JOIN sosdb.sfecfg picodevicetype ON kiosk.id = picodevicetype.name
		WHERE picodevicetype.Type = 'PICODEVICETYPE'
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
        SELECT KS.ORG, KS.LOCATION, KS.KIOSK, MAX(KS.LASTTRANSDATE) AS LASTSALE
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

	-- JOIN the ViSTAR Registration Tokens
    LEFT JOIN (
        SELECT *
        FROM SFECFG
        WHERE TYPE = 'VISTAR_REG_TOKEN'
    ) sfe_vistar ON sfe_vistar.name = k.id

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
    LEFT JOIN (SELECT * FROM sosdb.lookupstr WHERE TYPE = 'CCPROCESSOR') cp ON k.PROCESSOR1 = cp.KEYSTR

    -- Get the CC Firmware & Config from DashDB (adds about 58 seconds to the query of about ~60k devices)
    LEFT JOIN (
        SELECT h.KIOSKNAME
            ,REPLACE(JSON_EXTRACT(h.KIOSKINFO, '$.otifirmware'),CHAR(34), "")                           AS OTIFIRMWARE
            ,REPLACE(JSON_EXTRACT(h.KIOSKINFO, '$.oticonfig'),CHAR(34), "")                             AS OTICONFIG
            ,REPLACE(JSON_EXTRACT(h.KIOSKINFO, '$.kskdb.kskcfg.optConnectSerialNumber'),CHAR(34), "")   AS OPTCONNECT_SERIAL
        FROM dashdb.hostinfo h
            INNER JOIN (
                SELECT KIOSKNAME, MAX(LASTUPDATED) AS LASTUPDATED
                FROM dashdb.hostinfo
                GROUP BY KIOSKNAME
            ) AS u ON h.KIOSKNAME = u.KIOSKNAME AND h.LASTUPDATED = u.LASTUPDATED
        WHERE JSON_VALID(h.kioskinfo) = 1 AND h.KIOSKINFO IS NOT NULL
    ) AS h ON k.NAME = h.KIOSKNAME

    -- Join the devicelog to get the OS Version if k.OSVersion is null
    LEFT JOIN (
        SELECT DEVICENAME, MAX(DATECREATED) LATESTDATECREATED, VERSION
        FROM devicelog
        WHERE APPNAME = "android.cap"
        GROUP BY DEVICENAME
    ) dl ON dl.DEVICENAME = k.NAME

ORDER BY sfe.OpGroup, sfediv.Value, o.Name, l.Name, k.type