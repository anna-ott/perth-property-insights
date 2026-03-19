/*
Build:
- fact_aus_population_area
- fact_population_gccsa
*/

IF OBJECT_ID('dbo.stg_population_area_long', 'U') IS NULL
    THROW 50000, 'Missing table dbo.stg_population_area_long. Run 01 first.', 1;
IF OBJECT_ID('dbo.stg_population_gcc_long', 'U') IS NULL
    THROW 50000, 'Missing table dbo.stg_population_gcc_long. Run 01 first.', 1;
GO

DROP TABLE IF EXISTS dbo.fact_aus_population_area;
DROP TABLE IF EXISTS dbo.fact_population_gccsa;
GO

SELECT
    CAST(SA2_code AS varchar(20)) AS SA2Code,
    CAST(CAST([Year] AS varchar(4)) + '0701' AS int) AS DateID,
    CAST(Population AS int) AS Population
INTO dbo.fact_aus_population_area
FROM dbo.stg_population_area_long
WHERE SA2_code IS NOT NULL;
GO

SELECT
    CAST(GCCSA_code AS varchar(20)) AS GCCSACode,
    CAST(CAST([Year] AS varchar(4)) + '0701' AS int) AS DateID,
    CAST(Population AS int) AS Population
INTO dbo.fact_population_gccsa
FROM dbo.stg_population_gcc_long
WHERE GCCSA_code IS NOT NULL;
GO
