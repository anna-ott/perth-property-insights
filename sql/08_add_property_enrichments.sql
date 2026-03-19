/*
Add:
- NearestBeachDist
- reporting band columns
- outlier flags
*/

IF OBJECT_ID('dbo.dim_properties', 'U') IS NULL
    THROW 50000, 'Missing table dbo.dim_properties. Run 03 first.', 1;
IF OBJECT_ID('dbo.dim_location', 'U') IS NULL
    THROW 50000, 'Missing table dbo.dim_location. Run 02 first.', 1;
IF OBJECT_ID('dbo.fact_perth_property_sales', 'U') IS NULL
    THROW 50000, 'Missing table dbo.fact_perth_property_sales. Run 03 first.', 1;
GO

IF COL_LENGTH('dbo.dim_properties', 'NearestBeachDist') IS NULL
    ALTER TABLE dbo.dim_properties ADD NearestBeachDist decimal(10,2) NULL;
GO

IF OBJECT_ID('dbo.dim_perth_beaches', 'U') IS NOT NULL
BEGIN
    ;WITH BeachDistances AS
    (
        SELECT
            p.PropertyID,
            DistanceKm = 6371.0 * 2.0 * ASIN(
                SQRT(
                    POWER(SIN((RADIANS(b.Latitude) - RADIANS(l.Latitude)) / 2.0), 2) +
                    COS(RADIANS(l.Latitude)) * COS(RADIANS(b.Latitude)) *
                    POWER(SIN((RADIANS(b.Longitude) - RADIANS(l.Longitude)) / 2.0), 2)
                )
            )
        FROM dbo.dim_properties p
        INNER JOIN dbo.dim_location l ON p.LocationID = l.LocationID
        CROSS JOIN dbo.dim_perth_beaches b
        WHERE l.Latitude IS NOT NULL
          AND l.Longitude IS NOT NULL
          AND b.Latitude IS NOT NULL
          AND b.Longitude IS NOT NULL
    ), nearest_beach AS
    (
        SELECT PropertyID, MIN(DistanceKm) AS NearestBeachDist
        FROM BeachDistances
        GROUP BY PropertyID
    )
    UPDATE p
    SET p.NearestBeachDist = CAST(nb.NearestBeachDist AS decimal(10,2))
    FROM dbo.dim_properties p
    INNER JOIN nearest_beach nb ON p.PropertyID = nb.PropertyID;
END;
GO

IF COL_LENGTH('dbo.dim_properties', 'CbdDistanceCategory') IS NULL
ALTER TABLE dbo.dim_properties ADD
    CbdDistanceCategory varchar(20) NULL,
    CbdDistanceCategorySort tinyint NULL,
    NearestStnDistCategory varchar(20) NULL,
    NearestStnDistCategorySort tinyint NULL,
    NearestSchDistCategory varchar(20) NULL,
    NearestSchDistCategorySort tinyint NULL,
    NearestBeachDistCategory varchar(20) NULL,
    NearestBeachDistCategorySort tinyint NULL,
    LandAreaCategory varchar(20) NULL,
    LandAreaCategorySort tinyint NULL,
    FloorAreaCategory varchar(20) NULL,
    FloorAreaCategorySort tinyint NULL,
    IsLandAreaOutlier bit NULL,
    IsFloorAreaOutlier bit NULL;
GO

IF COL_LENGTH('dbo.fact_perth_property_sales', 'IsPriceOutlier') IS NULL
    ALTER TABLE dbo.fact_perth_property_sales ADD IsPriceOutlier bit NULL;
GO

UPDATE dbo.dim_properties
SET
    CbdDistanceCategory = CASE
        WHEN CbdDistance IS NULL THEN 'Unknown'
        WHEN CbdDistance < 2 THEN '0-2 km'
        WHEN CbdDistance < 5 THEN '2-5 km'
        WHEN CbdDistance < 10 THEN '5-10 km'
        ELSE '10 km+'
    END,
    CbdDistanceCategorySort = CASE
        WHEN CbdDistance IS NULL THEN 0
        WHEN CbdDistance < 2 THEN 1
        WHEN CbdDistance < 5 THEN 2
        WHEN CbdDistance < 10 THEN 3
        ELSE 4
    END,
    NearestStnDistCategory = CASE
        WHEN NearestStnDist IS NULL THEN 'Unknown'
        WHEN NearestStnDist < 2 THEN '0-2 km'
        WHEN NearestStnDist < 5 THEN '2-5 km'
        WHEN NearestStnDist < 10 THEN '5-10 km'
        ELSE '10 km+'
    END,
    NearestStnDistCategorySort = CASE
        WHEN NearestStnDist IS NULL THEN 0
        WHEN NearestStnDist < 2 THEN 1
        WHEN NearestStnDist < 5 THEN 2
        WHEN NearestStnDist < 10 THEN 3
        ELSE 4
    END,
    NearestSchDistCategory = CASE
        WHEN NearestSchDist IS NULL THEN 'Unknown'
        WHEN NearestSchDist < 2 THEN '0-2 km'
        WHEN NearestSchDist < 5 THEN '2-5 km'
        WHEN NearestSchDist < 10 THEN '5-10 km'
        ELSE '10 km+'
    END,
    NearestSchDistCategorySort = CASE
        WHEN NearestSchDist IS NULL THEN 0
        WHEN NearestSchDist < 2 THEN 1
        WHEN NearestSchDist < 5 THEN 2
        WHEN NearestSchDist < 10 THEN 3
        ELSE 4
    END,
    NearestBeachDistCategory = CASE
        WHEN NearestBeachDist IS NULL THEN 'Unknown'
        WHEN NearestBeachDist < 2 THEN '0-2 km'
        WHEN NearestBeachDist < 5 THEN '2-5 km'
        WHEN NearestBeachDist < 10 THEN '5-10 km'
        ELSE '10 km+'
    END,
    NearestBeachDistCategorySort = CASE
        WHEN NearestBeachDist IS NULL THEN 0
        WHEN NearestBeachDist < 2 THEN 1
        WHEN NearestBeachDist < 5 THEN 2
        WHEN NearestBeachDist < 10 THEN 3
        ELSE 4
    END,
    LandAreaCategory = CASE
        WHEN LandArea IS NULL THEN 'Unknown'
        WHEN LandArea < 200 THEN '0-200 m²'
        WHEN LandArea < 400 THEN '200-400 m²'
        WHEN LandArea < 600 THEN '400-600 m²'
        WHEN LandArea < 800 THEN '600-800 m²'
        WHEN LandArea < 1000 THEN '800-1000 m²'
        ELSE '1000+ m²'
    END,
    LandAreaCategorySort = CASE
        WHEN LandArea IS NULL THEN 0
        WHEN LandArea < 200 THEN 1
        WHEN LandArea < 400 THEN 2
        WHEN LandArea < 600 THEN 3
        WHEN LandArea < 800 THEN 4
        WHEN LandArea < 1000 THEN 5
        ELSE 6
    END,
    FloorAreaCategory = CASE
        WHEN FloorArea IS NULL THEN 'Unknown'
        WHEN FloorArea < 100 THEN '0-100 m²'
        WHEN FloorArea < 150 THEN '100-150 m²'
        WHEN FloorArea < 200 THEN '150-200 m²'
        WHEN FloorArea < 300 THEN '200-300 m²'
        ELSE '300+ m²'
    END,
    FloorAreaCategorySort = CASE
        WHEN FloorArea IS NULL THEN 0
        WHEN FloorArea < 100 THEN 1
        WHEN FloorArea < 150 THEN 2
        WHEN FloorArea < 200 THEN 3
        WHEN FloorArea < 300 THEN 4
        ELSE 5
    END;
GO

;WITH PriceStats AS
(
    SELECT DISTINCT
        PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY Price) OVER () AS Q1,
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY Price) OVER () AS Q3
    FROM dbo.fact_perth_property_sales
    WHERE Price IS NOT NULL
), PriceBounds AS
(
    SELECT Q1 - 1.5 * (Q3 - Q1) AS LowerBound,
           Q3 + 1.5 * (Q3 - Q1) AS UpperBound
    FROM PriceStats
)
UPDATE s
SET IsPriceOutlier = CASE
    WHEN s.Price IS NULL THEN NULL
    WHEN s.Price < pb.LowerBound OR s.Price > pb.UpperBound THEN 1
    ELSE 0
END
FROM dbo.fact_perth_property_sales s
CROSS JOIN PriceBounds pb;
GO

;WITH LandStats AS
(
    SELECT DISTINCT
        PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY LandArea) OVER () AS Q1,
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY LandArea) OVER () AS Q3
    FROM dbo.dim_properties
    WHERE LandArea IS NOT NULL
), LandBounds AS
(
    SELECT Q1 - 1.5 * (Q3 - Q1) AS LowerBound,
           Q3 + 1.5 * (Q3 - Q1) AS UpperBound
    FROM LandStats
)
UPDATE p
SET IsLandAreaOutlier = CASE
    WHEN p.LandArea IS NULL THEN NULL
    WHEN p.LandArea < lb.LowerBound OR p.LandArea > lb.UpperBound THEN 1
    ELSE 0
END
FROM dbo.dim_properties p
CROSS JOIN LandBounds lb;
GO

;WITH FloorStats AS
(
    SELECT DISTINCT
        PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY FloorArea) OVER () AS Q1,
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY FloorArea) OVER () AS Q3
    FROM dbo.dim_properties
    WHERE FloorArea IS NOT NULL
), FloorBounds AS
(
    SELECT Q1 - 1.5 * (Q3 - Q1) AS LowerBound,
           Q3 + 1.5 * (Q3 - Q1) AS UpperBound
    FROM FloorStats
)
UPDATE p
SET IsFloorAreaOutlier = CASE
    WHEN p.FloorArea IS NULL THEN NULL
    WHEN p.FloorArea < fb.LowerBound OR p.FloorArea > fb.UpperBound THEN 1
    ELSE 0
END
FROM dbo.dim_properties p
CROSS JOIN FloorBounds fb;
GO
