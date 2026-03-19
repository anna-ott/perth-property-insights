/*
Build:
- dim_location
- dim_sa2
- dim_gccsa

Uses:
- raw_aus_postcodes
- raw_postcode_sa2_lookup
- stg_population_area_long
*/

IF OBJECT_ID('dbo.raw_aus_postcodes', 'U') IS NULL
    THROW 50000, 'Missing table dbo.raw_aus_postcodes', 1;
IF OBJECT_ID('dbo.raw_postcode_sa2_lookup', 'U') IS NULL
    THROW 50000, 'Missing table dbo.raw_postcode_sa2_lookup', 1;
IF OBJECT_ID('dbo.stg_population_area_long', 'U') IS NULL
    THROW 50000, 'Missing table dbo.stg_population_area_long. Run 01 first.', 1;
GO

DROP TABLE IF EXISTS dbo.dim_location;
DROP TABLE IF EXISTS dbo.dim_sa2;
DROP TABLE IF EXISTS dbo.dim_gccsa;
DROP TABLE IF EXISTS dbo.stg_postcode_sa2_lookup;
DROP TABLE IF EXISTS dbo.stg_sa2_geo;
GO

IF COL_LENGTH('dbo.raw_aus_postcodes', 'accuracy') IS NOT NULL
BEGIN
    ALTER TABLE dbo.raw_aus_postcodes DROP COLUMN accuracy;
END;
GO

IF COL_LENGTH('dbo.raw_postcode_sa2_lookup', 'postcode') IS NULL AND COL_LENGTH('dbo.raw_postcode_sa2_lookup', 'column1') IS NOT NULL
BEGIN
    EXEC sp_rename 'dbo.raw_postcode_sa2_lookup.[column1]', 'postcode', 'COLUMN';
    EXEC sp_rename 'dbo.raw_postcode_sa2_lookup.[column2]', 'SA2_code', 'COLUMN';
END;
GO

SELECT DISTINCT
    CAST(postcode AS varchar(4)) AS postcode,
    CAST(SA2_code AS varchar(20)) AS SA2_code
INTO dbo.stg_postcode_sa2_lookup
FROM dbo.raw_postcode_sa2_lookup
WHERE SA2_code IS NOT NULL;
GO

SELECT DISTINCT
    CAST(SA2_code AS varchar(20))  AS SA2Code,
    SA2_name                       AS SA2Name,
    SA3_name                       AS SA3Name,
    SA4_name                       AS SA4Name,
    CAST(GCCSA_code AS varchar(20)) AS GCCSACode,
    GCCSA_name                     AS GCCSAName,
    S_T_name                       AS StateName
INTO dbo.stg_sa2_geo
FROM dbo.stg_population_area_long
WHERE SA2_code IS NOT NULL
  AND SA2_name IS NOT NULL;
GO

WITH base AS
(
    SELECT DISTINCT
        CAST(p.postcode AS varchar(4)) AS Postcode,
        p.place_name                   AS Suburb,
        p.state_name                   AS StateName,
        p.state_code                   AS StateCode,
        CAST(p.latitude  AS float)     AS Latitude,
        CAST(p.longitude AS float)     AS Longitude,
        l.SA2_code                     AS SA2Code,
        g.SA2Name,
        g.SA3Name,
        g.SA4Name,
        g.GCCSACode,
        g.GCCSAName
    FROM dbo.raw_aus_postcodes p
    INNER JOIN dbo.stg_postcode_sa2_lookup l
        ON CAST(p.postcode AS varchar(4)) = l.postcode
    INNER JOIN dbo.stg_sa2_geo g
        ON l.SA2_code = g.SA2Code
), numbered AS
(
    SELECT
        'L' + RIGHT('00000' + CAST(ROW_NUMBER() OVER (ORDER BY Postcode, Suburb, Latitude, Longitude) AS varchar(6)), 5) AS LocationID,
        *
    FROM base
)
SELECT *
INTO dbo.dim_location
FROM numbered;
GO

/* Known project fix: Treeby was missing in the original postcode source */
IF NOT EXISTS (SELECT 1 FROM dbo.dim_location WHERE Suburb = 'Treeby' AND Postcode = '6164')
BEGIN
    INSERT INTO dbo.dim_location
    (
        LocationID, Postcode, Suburb, StateName, StateCode, Latitude, Longitude,
        SA2Code, SA2Name, SA3Name, SA4Name, GCCSACode, GCCSAName
    )
    VALUES
    (
        'L99999', '6164', 'Treeby', 'Western Australia', 'WA', -32.1196, 115.8782,
        '507011260', 'Jandakot', 'Cockburn', 'Perth - South West', '5GPER', 'Greater Perth'
    );
END;
GO

ALTER TABLE dbo.dim_location ALTER COLUMN LocationID varchar(6) NOT NULL;
ALTER TABLE dbo.dim_location ADD CONSTRAINT PK_dim_location PRIMARY KEY (LocationID);
GO

SELECT DISTINCT
    SA2Code,
    SA2Name,
    GCCSACode,
    GCCSAName
INTO dbo.dim_sa2
FROM dbo.dim_location
WHERE SA2Code IS NOT NULL
  AND SA2Name IS NOT NULL;
GO

ALTER TABLE dbo.dim_sa2 ALTER COLUMN SA2Code varchar(20) NOT NULL;
ALTER TABLE dbo.dim_sa2 ADD CONSTRAINT PK_dim_sa2 PRIMARY KEY (SA2Code);
GO

SELECT DISTINCT
    GCCSACode,
    GCCSAName,
    StateCode = CASE GCCSACode
        WHEN '5GPER' THEN 'WA' WHEN '5RWAU' THEN 'WA'
        WHEN '1GSYD' THEN 'NSW' WHEN '1RNSW' THEN 'NSW'
        WHEN '2GMEL' THEN 'VIC' WHEN '2RVIC' THEN 'VIC'
        WHEN '3GBRI' THEN 'QLD' WHEN '3RQLD' THEN 'QLD'
        WHEN '4GADE' THEN 'SA'  WHEN '4RSAU' THEN 'SA'
        WHEN '6GHOB' THEN 'TAS' WHEN '6RTAS' THEN 'TAS'
        WHEN '7GDAR' THEN 'NT'  WHEN '7RNTE' THEN 'NT'
        WHEN '8ACTE' THEN 'ACT' WHEN '9OTER' THEN 'ACT'
        ELSE NULL
    END
INTO dbo.dim_gccsa
FROM dbo.dim_location
WHERE GCCSACode IS NOT NULL
  AND GCCSAName IS NOT NULL;
GO

ALTER TABLE dbo.dim_gccsa ALTER COLUMN GCCSACode varchar(20) NOT NULL;
ALTER TABLE dbo.dim_gccsa ADD CONSTRAINT PK_dim_gccsa PRIMARY KEY (GCCSACode);
GO
