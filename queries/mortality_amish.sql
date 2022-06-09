SELECT
  residence_county,
  month_code,
  deaths,
  population,
  deaths / population * 100000 AS "mortality"
FROM
  (
    SELECT
      residence_county,
      left(month_code, 4) AS "year",
      month_code,
      deaths
    FROM
      us_county.imp_deaths
    WHERE
      notes = ""
  ) a
  JOIN (
    SELECT
      county,
      year,
      CAST(population AS UNSIGNED) AS "population"
    FROM
      us_county.imp_population
  ) b ON a.year = b.year
  AND a.residence_county = b.county
  AND a.residence_county IN (
    "Holmes County, OH",
    "LaGrange County, IN",
    "Adams County, IN",
    "Davis County, IA",
    "Douglas County, IL"
  )
ORDER BY
  residence_county,
  month_code;