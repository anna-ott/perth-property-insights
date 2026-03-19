DROP TABLE IF EXISTS dbo.dim_date;
GO

WITH dates AS
(
    SELECT CAST('1983-07-01' AS date) AS [Date]
    UNION ALL
    SELECT DATEADD(day, 1, [Date])
    FROM dates
    WHERE [Date] < '2025-12-31'
)
SELECT
    YEAR([Date]) * 10000 + MONTH([Date]) * 100 + DAY([Date]) AS DateID,
    [Date],
    YEAR([Date]) AS [Year],
    MONTH([Date]) AS MonthNumber,
    DATENAME(month, [Date]) AS MonthName,
    DATEPART(quarter, [Date]) AS Quarter,
    CASE WHEN MONTH([Date]) >= 7 THEN YEAR([Date]) + 1 ELSE YEAR([Date]) END AS FinancialYearNumber,
    CASE WHEN MONTH([Date]) >= 7 THEN 'FY' + CAST(YEAR([Date]) + 1 AS varchar(4)) ELSE 'FY' + CAST(YEAR([Date]) AS varchar(4)) END AS FinancialYear,
    CASE
        WHEN MONTH([Date]) BETWEEN 7 AND 9 THEN 1
        WHEN MONTH([Date]) BETWEEN 10 AND 12 THEN 2
        WHEN MONTH([Date]) BETWEEN 1 AND 3 THEN 3
        ELSE 4
    END AS FinancialQuarterNumber,
    CASE
        WHEN MONTH([Date]) BETWEEN 7 AND 9 THEN 'Q1'
        WHEN MONTH([Date]) BETWEEN 10 AND 12 THEN 'Q2'
        WHEN MONTH([Date]) BETWEEN 1 AND 3 THEN 'Q3'
        ELSE 'Q4'
    END AS FinancialQuarter
INTO dbo.dim_date
FROM dates
OPTION (MAXRECURSION 0);
GO

ALTER TABLE dbo.dim_date ALTER COLUMN DateID int NOT NULL;
ALTER TABLE dbo.dim_date ADD CONSTRAINT PK_dim_date PRIMARY KEY (DateID);
GO
