/*
README – SQL Build Order

This set of scripts builds the full data model used in the Power BI report.

FINAL TABLES CREATED
- dim_location
- dim_sa2
- dim_gccsa
- dim_properties
- dim_date
- dim_dwelling_type
- fact_perth_property_sales
- fact_aus_population_area
- fact_population_gccsa
- fact_quarterly_dwelling_prices
- fact_wa_building_approvals
- fact_wa_avg_weekly_earnings

EXPECTED RAW INPUT TABLES
(Import these before running the scripts)
- raw_perth_house_prices
- raw_aus_population_area
- raw_aus_population_gcc
- raw_aus_postcodes
- raw_postcode_sa2_lookup
- raw_quarterly_dwelling_prices
- raw_wa_avg_weekly_earnings
- raw_wa_building_approvals
- dim_perth_beaches   -- helper table for nearest beach calculations

RUN ORDER
Run the scripts in numerical order (01 → 09):

1. 01_stage_population_sources.sql
2. 02_build_location_dimensions.sql
3. 03_build_properties_and_sales.sql
4. 04_build_dim_date.sql
5. 05_build_dim_dwelling_type.sql
6. 06_build_population_facts.sql
7. 07_build_market_facts.sql
8. 08_add_property_enrichments.sql
9. 09_quality_checks.sql

WHAT THESE SCRIPTS DO
- Load and prepare raw data from the original datasets
- Clean and standardise the data (data types, naming, units)
- Reshape data where needed (e.g. wide to long format)
- Create dimension tables (date, location, property, dwelling type)
- Create fact tables for sales, population, approvals, earnings, and prices
- Apply additional logic such as categorisation and outlier flags

DATA HANDLING
- Data cleaning and transformations are handled directly within the build scripts
- Outliers are identified using the IQR method and flagged in the tables
- Outliers are retained in the dataset but filtered out in reporting

NOTES
- Scripts are designed to be re-runnable
- All tables required for the Power BI model are created within this pipeline
- Raw data is expected to match the structure of the original datasets
*/