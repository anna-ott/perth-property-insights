/*
Build:
- fact_wa_avg_weekly_earnings
- fact_wa_building_approvals
- fact_quarterly_dwelling_prices

Uses raw source imports directly.
*/

IF OBJECT_ID('dbo.raw_wa_avg_weekly_earnings', 'U') IS NULL
    THROW 50000, 'Missing table dbo.raw_wa_avg_weekly_earnings', 1;
IF OBJECT_ID('dbo.raw_wa_building_approvals', 'U') IS NULL
    THROW 50000, 'Missing table dbo.raw_wa_building_approvals', 1;
IF OBJECT_ID('dbo.raw_quarterly_dwelling_prices', 'U') IS NULL
    THROW 50000, 'Missing table dbo.raw_quarterly_dwelling_prices', 1;
IF OBJECT_ID('dbo.dim_dwelling_type', 'U') IS NULL
    THROW 50000, 'Missing table dbo.dim_dwelling_type. Run 05 first.', 1;
GO

DROP TABLE IF EXISTS dbo.fact_wa_avg_weekly_earnings;
DROP TABLE IF EXISTS dbo.fact_wa_building_approvals;
DROP TABLE IF EXISTS dbo.fact_quarterly_dwelling_prices;
GO

/* weekly earnings */
IF COL_LENGTH('dbo.raw_wa_avg_weekly_earnings', 'Date') IS NULL AND COL_LENGTH('dbo.raw_wa_avg_weekly_earnings', 'column1') IS NOT NULL
BEGIN
    EXEC sp_rename 'dbo.raw_wa_avg_weekly_earnings.[column1]', 'Date', 'COLUMN';
    EXEC sp_rename 'dbo.raw_wa_avg_weekly_earnings.[column2]', 'WeeklyFTEarnings', 'COLUMN';
END;
GO

SELECT
    CAST(CONVERT(char(8), TRY_CONVERT(date, [Date], 103), 112) AS int) AS DateID,
    CAST(WeeklyFTEarnings AS decimal(12,2)) AS WeeklyFTEarnings
INTO dbo.fact_wa_avg_weekly_earnings
FROM dbo.raw_wa_avg_weekly_earnings
WHERE TRY_CONVERT(date, [Date], 103) IS NOT NULL;
GO

/* building approvals */
IF COL_LENGTH('dbo.raw_wa_building_approvals', 'Date') IS NULL AND COL_LENGTH('dbo.raw_wa_building_approvals', 'column1') IS NOT NULL
BEGIN
    EXEC sp_rename 'dbo.raw_wa_building_approvals.[column1]', 'Date', 'COLUMN';
    EXEC sp_rename 'dbo.raw_wa_building_approvals.[column2]', 'House Private WA', 'COLUMN';
    EXEC sp_rename 'dbo.raw_wa_building_approvals.[column3]', 'House Total WA', 'COLUMN';
    EXEC sp_rename 'dbo.raw_wa_building_approvals.[column4]', 'Att Dwelling Private WA', 'COLUMN';
    EXEC sp_rename 'dbo.raw_wa_building_approvals.[column5]', 'Att Dwelling Total WA', 'COLUMN';
    EXEC sp_rename 'dbo.raw_wa_building_approvals.[column6]', 'Total Dwellings Private WA', 'COLUMN';
    EXEC sp_rename 'dbo.raw_wa_building_approvals.[column7]', 'Total Dwellings Total WA', 'COLUMN';
END;
GO

WITH approvals AS
(
    SELECT
        TRY_CONVERT(date, [Date], 103) AS ApprovalDate,
        Category,
        TRY_CAST(Value AS int) AS NumApprovals
    FROM dbo.raw_wa_building_approvals
    UNPIVOT
    (
        Value FOR Category IN (
            [House Private WA],
            [House Total WA],
            [Att Dwelling Private WA],
            [Att Dwelling Total WA],
            [Total Dwellings Private WA],
            [Total Dwellings Total WA]
        )
    ) u
), mapped AS
(
    SELECT
        CAST(CONVERT(char(8), ApprovalDate, 112) AS int) AS DateID,
        CASE
            WHEN Category = 'House Private WA'            THEN 'H2'
            WHEN Category = 'House Total WA'              THEN 'T2'
            WHEN Category = 'Att Dwelling Private WA'     THEN 'A2'
            WHEN Category = 'Att Dwelling Total WA'       THEN 'T2'
            WHEN Category = 'Total Dwellings Private WA'  THEN 'T2'
            WHEN Category = 'Total Dwellings Total WA'    THEN 'T2'
        END AS DwellingTypeID,
        NumApprovals
    FROM approvals
    WHERE ApprovalDate IS NOT NULL
)
SELECT DateID, DwellingTypeID, NumApprovals
INTO dbo.fact_wa_building_approvals
FROM mapped;
GO

/* quarterly dwelling prices
   Assumes the cleaned raw file has wide columns matching the original project.
*/
WITH src AS
(
    SELECT
        TRY_CONVERT(date, [Date], 103) AS PriceDate,
        *
    FROM dbo.raw_quarterly_dwelling_prices
), prices AS
(
    SELECT
        PriceDate,
        v.GCCSACode,
        v.DwellingTypeID,
        TRY_CAST(v.MedianPrice AS int) AS MedianPrice
    FROM src s
    CROSS APPLY (VALUES
        ('1GSYD','H1', s.[median_price_est_house_sydney]),
        ('1RNSW','H1', s.[median_price_est_house_rest_of_nsw]),
        ('2GMEL','H1', s.[median_price_est_house_melbourne]),
        ('2RVIC','H1', s.[median_price_est_house_rest_of_vic]),
        ('3GBRI','H1', s.[median_price_est_house_brisbane]),
        ('3RQLD','H1', s.[median_price_est_house_rest_of_qld]),
        ('4GADE','H1', s.[median_price_est_house_adelaide]),
        ('4RSAU','H1', s.[median_price_est_house_rest_of_sa]),
        ('5GPER','H1', s.[median_est_house_perth]),
        ('5RWAU','H1', s.[median_price_est_house_rest_of_wa]),
        ('6GHOB','H1', s.[median_price_est_house_hobart]),
        ('6RTAS','H1', s.[median_price_est_house_rest_of_tas]),
        ('7GDAR','H1', s.[median_price_est_house_darwin]),
        ('7RNTE','H1', s.[median_price_est_house_rest_of_nt]),
        ('8ACTE','H1', s.[median_price_est_house_canberra]),
        ('1GSYD','A1', s.[median_price_of_att_dwelling_sydney]),
        ('1RNSW','A1', s.[median_price_of_att_dwelling_rest_of_nsw]),
        ('2GMEL','A1', s.[median_price_att_dwelling_melbourne]),
        ('2RVIC','A1', s.[median_price_att_dwelling_rest_of_vic]),
        ('3GBRI','A1', s.[median_price_of_att_dwelling_brisbane]),
        ('3RQLD','A1', s.[median_price_att_dwelling_rest_of_qld]),
        ('4GADE','A1', s.[median_price_att_dwelling_adelaide]),
        ('4RSAU','A1', s.[median_price_att_dwelling_rest_of_sa]),
        ('5GPER','A1', s.[median_price_of_att_dwelling_perth]),
        ('5RWAU','A1', s.[median_price_att_dwelling_rest_of_wa]),
        ('6GHOB','A1', s.[median_price_att_dwelling_hobart]),
        ('6RTAS','A1', s.[median_price_att_dwelling_rest_of_tas]),
        ('7GDAR','A1', s.[median_price_att_dwelling_darwin]),
        ('7RNTE','A1', s.[median_price_att_dwelling_rest_of_nt]),
        ('8ACTE','A1', s.[median_price_att_dwelling_canberra])
    ) v(GCCSACode, DwellingTypeID, MedianPrice)
    WHERE PriceDate IS NOT NULL
)
SELECT
    CAST(CONVERT(char(8), PriceDate, 112) AS int) AS DateID,
    DwellingTypeID,
    GCCSACode,
    MedianPrice
INTO dbo.fact_quarterly_dwelling_prices
FROM prices
WHERE MedianPrice IS NOT NULL;
GO
