/*
Build:
- dim_properties
- fact_perth_property_sales

Uses:
- raw_perth_house_prices
- dim_location
*/

IF OBJECT_ID('dbo.raw_perth_house_prices', 'U') IS NULL
    THROW 50000, 'Missing table dbo.raw_perth_house_prices', 1;
IF OBJECT_ID('dbo.dim_location', 'U') IS NULL
    THROW 50000, 'Missing table dbo.dim_location. Run 02 first.', 1;
GO

DROP TABLE IF EXISTS dbo.fact_perth_property_sales;
DROP TABLE IF EXISTS dbo.dim_properties;
GO

WITH property_source AS
(
    SELECT DISTINCT
        CAST(r.POSTCODE AS varchar(4))       AS Postcode,
        r.SUBURB                             AS Suburb,
        CAST(r.BEDROOMS AS tinyint)          AS Bedrooms,
        CAST(r.BATHROOMS AS tinyint)         AS Bathrooms,
        CAST(r.GARAGE AS tinyint)            AS Garage,
        CAST(r.LAND_AREA AS int)             AS LandArea,
        CAST(r.FLOOR_AREA AS int)            AS FloorArea,
        CAST(r.BUILD_YEAR AS smallint)       AS BuildYear,
        CAST(r.CBD_DIST AS decimal(10,2)) / 1000.0        AS CbdDistance,
        CAST(r.NEAREST_STN_DIST AS decimal(10,2)) / 1000.0 AS NearestStnDist,
        ROUND(CAST(r.NEAREST_SCH_DIST AS decimal(10,2)), 2) AS NearestSchDist
    FROM dbo.raw_perth_house_prices r
), property_located AS
(
    SELECT
        p.Postcode,
        p.Suburb,
        l.LocationID,
        p.Bedrooms,
        p.Bathrooms,
        p.Garage,
        p.LandArea,
        p.FloorArea,
        p.BuildYear,
        p.CbdDistance,
        p.NearestStnDist,
        p.NearestSchDist
    FROM property_source p
    INNER JOIN dbo.dim_location l
        ON p.Postcode = l.Postcode
       AND p.Suburb   = l.Suburb
), numbered AS
(
    SELECT
        'P' + RIGHT('00000' + CAST(ROW_NUMBER() OVER
        (
            ORDER BY LocationID, Bedrooms, Bathrooms, ISNULL(Garage, -1), ISNULL(LandArea, -1),
                     ISNULL(FloorArea, -1), ISNULL(BuildYear, -1), ISNULL(CbdDistance, -1),
                     ISNULL(NearestStnDist, -1), ISNULL(NearestSchDist, -1)
        ) AS varchar(6)), 5) AS PropertyID,
        LocationID,
        Postcode,
        Bedrooms,
        Bathrooms,
        Garage,
        LandArea,
        FloorArea,
        BuildYear,
        CbdDistance,
        NearestStnDist,
        NearestSchDist
    FROM property_located
)
SELECT *
INTO dbo.dim_properties
FROM numbered;
GO

ALTER TABLE dbo.dim_properties ALTER COLUMN PropertyID varchar(6) NOT NULL;
ALTER TABLE dbo.dim_properties ADD CONSTRAINT PK_dim_properties PRIMARY KEY (PropertyID);
ALTER TABLE dbo.dim_properties ADD CONSTRAINT FK_dim_properties_location FOREIGN KEY (LocationID) REFERENCES dbo.dim_location(LocationID);
GO

WITH sales_source AS
(
    SELECT
        r.DATE_SOLD,
        CAST(r.PRICE AS int)      AS Price,
        CAST(r.POSTCODE AS varchar(4)) AS Postcode,
        r.SUBURB,
        CAST(r.BEDROOMS AS tinyint)          AS Bedrooms,
        CAST(r.BATHROOMS AS tinyint)         AS Bathrooms,
        CAST(r.GARAGE AS tinyint)            AS Garage,
        CAST(r.LAND_AREA AS int)             AS LandArea,
        CAST(r.FLOOR_AREA AS int)            AS FloorArea,
        CAST(r.BUILD_YEAR AS smallint)       AS BuildYear,
        CAST(r.CBD_DIST AS decimal(10,2)) / 1000.0        AS CbdDistance,
        CAST(r.NEAREST_STN_DIST AS decimal(10,2)) / 1000.0 AS NearestStnDist,
        ROUND(CAST(r.NEAREST_SCH_DIST AS decimal(10,2)), 2) AS NearestSchDist
    FROM dbo.raw_perth_house_prices r
), matched AS
(
    SELECT
        src.DATE_SOLD,
        src.Price,
        p.PropertyID,
        p.LocationID,
        DateID = TRY_CONVERT(int,
                    CONCAT(
                        RIGHT(src.DATE_SOLD, 4),
                        RIGHT('00' + CAST(DATEPART(month, TRY_CONVERT(date, src.DATE_SOLD, 103)) AS varchar(2)), 2),
                        RIGHT('00' + CAST(DATEPART(day,   TRY_CONVERT(date, src.DATE_SOLD, 103)) AS varchar(2)), 2)
                    )
                )
    FROM sales_source src
    INNER JOIN dbo.dim_location l
        ON src.Postcode = l.Postcode
       AND src.Suburb   = l.Suburb
    INNER JOIN dbo.dim_properties p
        ON p.LocationID       = l.LocationID
       AND ISNULL(p.Bedrooms, -1)       = ISNULL(src.Bedrooms, -1)
       AND ISNULL(p.Bathrooms, -1)      = ISNULL(src.Bathrooms, -1)
       AND ISNULL(p.Garage, -1)         = ISNULL(src.Garage, -1)
       AND ISNULL(p.LandArea, -1)       = ISNULL(src.LandArea, -1)
       AND ISNULL(p.FloorArea, -1)      = ISNULL(src.FloorArea, -1)
       AND ISNULL(p.BuildYear, -1)      = ISNULL(src.BuildYear, -1)
       AND ISNULL(p.CbdDistance, -1)    = ISNULL(src.CbdDistance, -1)
       AND ISNULL(p.NearestStnDist, -1) = ISNULL(src.NearestStnDist, -1)
       AND ISNULL(p.NearestSchDist, -1) = ISNULL(src.NearestSchDist, -1)
), numbered AS
(
    SELECT
        'S' + RIGHT('00000' + CAST(ROW_NUMBER() OVER (ORDER BY DateID, PropertyID, Price) AS varchar(6)), 5) AS SaleID,
        PropertyID,
        LocationID,
        DateID,
        Price
    FROM matched
)
SELECT *
INTO dbo.fact_perth_property_sales
FROM numbered;
GO

ALTER TABLE dbo.fact_perth_property_sales ALTER COLUMN SaleID varchar(6) NOT NULL;
ALTER TABLE dbo.fact_perth_property_sales ADD CONSTRAINT PK_fact_perth_property_sales PRIMARY KEY (SaleID);
ALTER TABLE dbo.fact_perth_property_sales ADD CONSTRAINT FK_sales_property FOREIGN KEY (PropertyID) REFERENCES dbo.dim_properties(PropertyID);
ALTER TABLE dbo.fact_perth_property_sales ADD CONSTRAINT FK_sales_location FOREIGN KEY (LocationID) REFERENCES dbo.dim_location(LocationID);
GO
