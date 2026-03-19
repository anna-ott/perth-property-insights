DROP TABLE IF EXISTS dbo.dim_dwelling_type;
GO

CREATE TABLE dbo.dim_dwelling_type
(
    DwellingTypeID varchar(5)  NOT NULL PRIMARY KEY,
    DwellingType   varchar(50) NOT NULL,
    Category       varchar(50) NOT NULL
);
GO

INSERT INTO dbo.dim_dwelling_type (DwellingTypeID, DwellingType, Category)
VALUES
('H1', 'House', 'Established'),
('H2', 'House', 'New'),
('A1', 'Att Dwelling', 'Established'),
('A2', 'Att Dwelling', 'New'),
('T1', 'Total Dwellings', 'Established'),
('T2', 'Total Dwellings', 'New');
GO
