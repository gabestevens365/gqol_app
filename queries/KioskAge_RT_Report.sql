-- This is the ReadyTouch KioskAge Query with the Last Sale, card processor, pole display, food scale, and DashWeb Info columns.
-- Run on SOSDB (will not work in Snowflake)
SELECT
    s.VALUE                     AS	"Operation Group",
    sfe_division.value          AS	"Division",
    ''                          AS  "Champion",
    o.SAGENUMBER1               AS	"Sage ID",
    o.Country                   AS	"Country",
    o.NAME                      AS	"Operation Name",
    l.NAME                      AS	"Location Name",
	l.LocationNumber			AS	"Loc Cost Center",
    k.NAME                      AS	"Device Serial",
    CASE k.HWTYPE
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
    END                         AS	"Model",
    CASE T.VALUE
        WHEN 'C' THEN 'Castles'
        WHEN 'I' THEN 'IdTech'
        WHEN 'L' THEN 'LineaPro'
        WHEN 'M' THEN 'Magtec'
        WHEN 'N' THEN 'Nayax'
        WHEN 'O' THEN '365 Secure'
        WHEN 'V' THEN 'Verifone'
        ELSE T.VALUE
    END                         AS  "Card Reader",
    cp.NAME                     AS	"Card Processor",
    k.STATUS                    AS	"Kiosk Status",
    k.LastFullSync              AS	"Last Sync",
    CASE WHEN k.LastFullSync <= CURRENT_DATE - INTERVAL '60' DAY THEN 'Stale' ELSE 'Current' END AS "Sync Status",
    KS.LASTSALE                 AS	"Last Sale",
    CASE WHEN ks.LastSale <= CURRENT_DATE - INTERVAL '60' DAY THEN 'Stale' ELSE 'Current' END AS "Sale Status",
    pd.value                    AS	"Pole Display",
    CASE scl.value
        WHEN 'N' THEN 'None'
        WHEN 'U' THEN 'USB'
        WHEN 'S' THEN 'Serial'
        ELSE scl.value
    END                         AS  "Scale",
    h.printer                   AS  "Printer",
	CONCAT(SUBSTRING_INDEX(k.OSVERSION, '.', 2)) AS "OS Version",
    h.product                   AS	"CPU Product"
FROM
    sosdb.org o
    INNER JOIN sosdb.location l        ON o.ID = l.ORG
    INNER JOIN sosdb.kiosk k           ON l.ID = k.LOCATION
    LEFT JOIN sosdb.lookupstr cp       ON k.PROCESSOR1 = cp.KEYSTR AND CP.TYPE = 'CCPROCESSOR'
    LEFT JOIN sosdb.CLIENT c           ON c.ID = l.CLIENT
    LEFT JOIN sosdb.sfecfg s           ON S.TYPE = 'SPECIALTYPE' AND S.CFGTYPE = 'ORG' AND o.ID = s.NAME
    LEFT JOIN sosdb.sfecfg t           ON T.TYPE = 'ENCRYPTMSR' AND T.CFGTYPE = 'KSK' AND k.ID = t.NAME
    LEFT JOIN sosdb.sfecfg pd          ON PD.TYPE = 'haspoledisplay' AND PD.CFGTYPE = 'KSK' AND k.ID = pd.NAME
    LEFT JOIN sosdb.sfecfg scl         ON SCL.TYPE = 'scale' AND k.ID = SCL.NAME

    -- Get the Last Transaction Date... filtering out the stuff we don't need first.
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
                k.ISLIVE = 'Y'
                AND k.NAME LIKE 'KSK%'
                AND k.HWTYPE NOT LIKE 'GEN3%'
                AND o.NAME NOT LIKE '%DEMO%'
                AND o.NAME NOT LIKE '%365TEST%'
        ) AS kiosk_info ON KS.ORG = kiosk_info.ORG AND KS.LOCATION = kiosk_info.LOCATION AND KS.KIOSK = kiosk_info.KIOSK
        GROUP BY KS.ORG, KS.LOCATION, KS.KIOSK
    ) KS ON o.ID = KS.ORG AND l.ID = KS.LOCATION AND k.ID = KS.KIOSK

    -- JOIN the Operator Group data
    LEFT JOIN (
        SELECT ID, NAME, VALUE
        FROM sfecfg
        WHERE TYPE = 'CANTEENDIVISION'
    ) sfe_division ON o.id = sfe_division.NAME

    -- My DashDB Left Join -- This block is what forces the query into reader.365rm.us instead of snowflake.
    LEFT JOIN (
        SELECT
            h.KIOSKNAME,
            CASE
                WHEN JSON_EXTRACT(KIOSKINFO, '$.printer.bixolon') <> ''         THEN 'bixolon'
                WHEN JSON_EXTRACT(KIOSKINFO, '$.printer.seikoEpsonCorp') <> ''  THEN 'seikoEpsonCorp'
                WHEN JSON_EXTRACT(KIOSKINFO, '$.printer.starMicronics') <> ''   THEN 'starMicronics'
                WHEN JSON_EXTRACT(KIOSKINFO, '$.printer.bixolon') <> ''         AND JSON_EXTRACT(KIOSKINFO, '$.printer.seikoEpsonCorp') <> ''     THEN 'bixolon & seikoEpsonCorp'
                WHEN JSON_EXTRACT(KIOSKINFO, '$.printer.bixolon') <> ''         AND JSON_EXTRACT(KIOSKINFO, '$.printer.starMicronics') <> ''      THEN 'bixolon & starMicronics'
                WHEN JSON_EXTRACT(KIOSKINFO, '$.printer.seikoEpsonCorp') <> ''  AND JSON_EXTRACT(KIOSKINFO, '$.printer.starMicronics') <> ''      THEN 'seikoEpsonCorp & starMicronics'
                WHEN JSON_EXTRACT(KIOSKINFO, '$.printer.seikoEpsonCorp') <> ''  AND JSON_EXTRACT(KIOSKINFO, '$.printer.starMicronics') <> ''      AND JSON_EXTRACT(KIOSKINFO, '$.printer.bixolon') <> '' THEN 'seikoEpsonCorp, starMicronics, & bixolon'
            END AS printer,
            SUBSTRING_INDEX(SUBSTRING_INDEX(REPLACE(JSON_EXTRACT(h.BASICINFO, '$.systemInfo'), CHAR(34), ''), 'product=', -1), '|', 1) AS product
        FROM (
            SELECT
                KIOSKNAME,
                BASICINFO,
                KIOSKINFO,
                MAX(LASTUPDATED) AS LASTUPDATED
            FROM dashdb.hostinfo
            WHERE
                JSON_VALID(kioskinfo) = 1
                AND KIOSKINFO IS NOT NULL
                AND JSON_VALID(basicinfo) = 1
            GROUP BY KIOSKNAME, REPLACE(JSON_EXTRACT(BASICINFO, '$.systemInfo'), CHAR(34), "")
        ) AS h
        INNER JOIN (
            SELECT KIOSKNAME, MAX(LASTUPDATED) AS LASTUPDATED
            FROM dashdb.hostinfo
            GROUP BY KIOSKNAME
        ) AS u ON h.KIOSKNAME = u.KIOSKNAME AND h.LASTUPDATED = u.LASTUPDATED
    ) AS h ON k.NAME = h.KIOSKNAME

WHERE
    k.ISLIVE = 'Y'
    AND k.NAME LIKE 'KSK%'
    AND k.HWTYPE NOT LIKE 'GEN3%'
    AND o.NAME NOT LIKE '%DEMO%'
    AND o.NAME NOT LIKE '%365TEST%'

ORDER BY s.VALUE, sfe_division.value, c.NAME, o.NAME, l.NAME, k.HWTYPE, k.NAME;
