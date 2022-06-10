SELECT
  DISTINCT REPLACE(county, ',', '') AS "county"
FROM
  us_county.mortality;