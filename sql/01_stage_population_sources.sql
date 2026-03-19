/*
Stage the two ABS population source tables into long/clean format.
Creates:
- stg_population_area_long
- stg_population_gcc_long
*/

DROP TABLE IF EXISTS dbo.stg_population_area_long;
DROP TABLE IF EXISTS dbo.stg_population_gcc_long;
GO

/* raw_aus_population_area
   Expected wide source with yearly columns 2001..2024 or imported placeholders like no, no_2, ...
*/
IF OBJECT_ID('dbo.raw_aus_population_area', 'U') IS NULL
    THROW 50000, 'Missing table dbo.raw_aus_population_area', 1;
GO

IF COL_LENGTH('dbo.raw_aus_population_area', '2001') IS NULL AND COL_LENGTH('dbo.raw_aus_population_area', 'no') IS NOT NULL
BEGIN
    EXEC sp_rename 'dbo.raw_aus_population_area.[no]'   , '2001', 'COLUMN';
    EXEC sp_rename 'dbo.raw_aus_population_area.[no_2]' , '2002', 'COLUMN';
    EXEC sp_rename 'dbo.raw_aus_population_area.[no_3]' , '2003', 'COLUMN';
    EXEC sp_rename 'dbo.raw_aus_population_area.[no_4]' , '2004', 'COLUMN';
    EXEC sp_rename 'dbo.raw_aus_population_area.[no_5]' , '2005', 'COLUMN';
    EXEC sp_rename 'dbo.raw_aus_population_area.[no_6]' , '2006', 'COLUMN';
    EXEC sp_rename 'dbo.raw_aus_population_area.[no_7]' , '2007', 'COLUMN';
    EXEC sp_rename 'dbo.raw_aus_population_area.[no_8]' , '2008', 'COLUMN';
    EXEC sp_rename 'dbo.raw_aus_population_area.[no_9]' , '2009', 'COLUMN';
    EXEC sp_rename 'dbo.raw_aus_population_area.[no_10]', '2010', 'COLUMN';
    EXEC sp_rename 'dbo.raw_aus_population_area.[no_11]', '2011', 'COLUMN';
    EXEC sp_rename 'dbo.raw_aus_population_area.[no_12]', '2012', 'COLUMN';
    EXEC sp_rename 'dbo.raw_aus_population_area.[no_13]', '2013', 'COLUMN';
    EXEC sp_rename 'dbo.raw_aus_population_area.[no_14]', '2014', 'COLUMN';
    EXEC sp_rename 'dbo.raw_aus_population_area.[no_15]', '2015', 'COLUMN';
    EXEC sp_rename 'dbo.raw_aus_population_area.[no_16]', '2016', 'COLUMN';
    EXEC sp_rename 'dbo.raw_aus_population_area.[no_17]', '2017', 'COLUMN';
    EXEC sp_rename 'dbo.raw_aus_population_area.[no_18]', '2018', 'COLUMN';
    EXEC sp_rename 'dbo.raw_aus_population_area.[no_19]', '2019', 'COLUMN';
    EXEC sp_rename 'dbo.raw_aus_population_area.[no_20]', '2020', 'COLUMN';
    EXEC sp_rename 'dbo.raw_aus_population_area.[no_21]', '2021', 'COLUMN';
    EXEC sp_rename 'dbo.raw_aus_population_area.[no_22]', '2022', 'COLUMN';
    EXEC sp_rename 'dbo.raw_aus_population_area.[no_23]', '2023', 'COLUMN';
    EXEC sp_rename 'dbo.raw_aus_population_area.[no_24]', '2024', 'COLUMN';
END;
GO

SELECT
    src.S_T_name,
    src.GCCSA_code,
    src.GCCSA_name,
    src.SA4_code,
    src.SA4_name,
    src.SA3_code,
    src.SA3_name,
    src.SA2_code,
    src.SA2_name,
    CAST(src.[Year] AS int)      AS [Year],
    CAST(src.Population AS int)  AS Population
INTO dbo.stg_population_area_long
FROM
(
    SELECT
        [S_T_name],
        [GCCSA_code],
        [GCCSA_name],
        [SA4_code],
        [SA4_name],
        [SA3_code],
        [SA3_name],
        [SA2_code],
        [SA2_name],
        [Year],
        Population
    FROM dbo.raw_aus_population_area
    UNPIVOT
    (
        Population FOR [Year] IN (
            [2001],[2002],[2003],[2004],[2005],[2006],[2007],[2008],[2009],[2010],[2011],[2012],
            [2013],[2014],[2015],[2016],[2017],[2018],[2019],[2020],[2021],[2022],[2023],[2024]
        )
    ) u
) src
WHERE src.S_T_name IS NOT NULL;
GO

/* raw_aus_population_gcc
   Expected wide source with placeholder column names column1..column30.
*/
IF OBJECT_ID('dbo.raw_aus_population_gcc', 'U') IS NULL
    THROW 50000, 'Missing table dbo.raw_aus_population_gcc', 1;
GO

IF COL_LENGTH('dbo.raw_aus_population_gcc', 'GCCSA_code') IS NULL AND COL_LENGTH('dbo.raw_aus_population_gcc', 'column1') IS NOT NULL
BEGIN
    EXEC sp_rename 'dbo.raw_aus_population_gcc.[column1]' , 'S_T_code', 'COLUMN';
    EXEC sp_rename 'dbo.raw_aus_population_gcc.[column2]' , 'S_T_name', 'COLUMN';
    EXEC sp_rename 'dbo.raw_aus_population_gcc.[column3]' , 'GCCSA_code', 'COLUMN';
    EXEC sp_rename 'dbo.raw_aus_population_gcc.[column4]' , 'GCCSA_name', 'COLUMN';
    EXEC sp_rename 'dbo.raw_aus_population_gcc.[column5]' , '2001', 'COLUMN';
    EXEC sp_rename 'dbo.raw_aus_population_gcc.[column6]' , '2002', 'COLUMN';
    EXEC sp_rename 'dbo.raw_aus_population_gcc.[column7]' , '2003', 'COLUMN';
    EXEC sp_rename 'dbo.raw_aus_population_gcc.[column8]' , '2004', 'COLUMN';
    EXEC sp_rename 'dbo.raw_aus_population_gcc.[column9]' , '2005', 'COLUMN';
    EXEC sp_rename 'dbo.raw_aus_population_gcc.[column10]', '2006', 'COLUMN';
    EXEC sp_rename 'dbo.raw_aus_population_gcc.[column11]', '2007', 'COLUMN';
    EXEC sp_rename 'dbo.raw_aus_population_gcc.[column12]', '2008', 'COLUMN';
    EXEC sp_rename 'dbo.raw_aus_population_gcc.[column13]', '2009', 'COLUMN';
    EXEC sp_rename 'dbo.raw_aus_population_gcc.[column14]', '2010', 'COLUMN';
    EXEC sp_rename 'dbo.raw_aus_population_gcc.[column15]', '2011', 'COLUMN';
    EXEC sp_rename 'dbo.raw_aus_population_gcc.[column16]', '2012', 'COLUMN';
    EXEC sp_rename 'dbo.raw_aus_population_gcc.[column17]', '2013', 'COLUMN';
    EXEC sp_rename 'dbo.raw_aus_population_gcc.[column18]', '2014', 'COLUMN';
    EXEC sp_rename 'dbo.raw_aus_population_gcc.[column19]', '2015', 'COLUMN';
    EXEC sp_rename 'dbo.raw_aus_population_gcc.[column20]', '2016', 'COLUMN';
    EXEC sp_rename 'dbo.raw_aus_population_gcc.[column21]', '2017', 'COLUMN';
    EXEC sp_rename 'dbo.raw_aus_population_gcc.[column22]', '2018', 'COLUMN';
    EXEC sp_rename 'dbo.raw_aus_population_gcc.[column23]', '2019', 'COLUMN';
    EXEC sp_rename 'dbo.raw_aus_population_gcc.[column24]', '2020', 'COLUMN';
    EXEC sp_rename 'dbo.raw_aus_population_gcc.[column25]', '2021', 'COLUMN';
    EXEC sp_rename 'dbo.raw_aus_population_gcc.[column26]', '2022', 'COLUMN';
    EXEC sp_rename 'dbo.raw_aus_population_gcc.[column27]', '2023', 'COLUMN';
    EXEC sp_rename 'dbo.raw_aus_population_gcc.[column28]', '2024', 'COLUMN';
END;
GO

SELECT
    src.S_T_code,
    src.S_T_name,
    src.GCCSA_code,
    src.GCCSA_name,
    CAST(src.[Year] AS int)      AS [Year],
    CAST(src.Population AS int)  AS Population
INTO dbo.stg_population_gcc_long
FROM
(
    SELECT S_T_code, S_T_name, GCCSA_code, GCCSA_name, [Year], Population
    FROM dbo.raw_aus_population_gcc
    UNPIVOT
    (
        Population FOR [Year] IN (
            [2001],[2002],[2003],[2004],[2005],[2006],[2007],[2008],[2009],[2010],[2011],[2012],
            [2013],[2014],[2015],[2016],[2017],[2018],[2019],[2020],[2021],[2022],[2023],[2024]
        )
    ) u
) src
WHERE src.S_T_code IS NOT NULL;
GO
