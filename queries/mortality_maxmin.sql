SELECT
  a.county,
  a.year,
  a.`month`,
  a.`year_month`,
  IFNULL(a.deaths, "") AS "deaths",
  IFNULL(a.population, "") AS "population",
  IFNULL(a.mortality, "") AS "mortality",
  a.baseline,
  a.baseline_normal_lower,
  a.baseline_normal_upper,
  a.baseline_excess,
  IFNULL(b.dose1, "") AS "dose1",
  IFNULL(round(dose1 / population, 3), "") AS "dose1_pct"
FROM
  us_county.exp_mortality a
  LEFT JOIN us_county.vaccinations b ON a.county = b.county
  AND a.year = b.year
  AND a.month = b.month;

SELECT
  *
FROM
  (
    SELECT
      a.county,
      dose1 / population "dose1_pct"
    FROM
      us_county.exp_mortality a
      JOIN us_county.vaccinations b ON a.county = b.county
      AND a.year = b.year
      AND a.month = b.month
    WHERE
      a.year = 2022
      AND a.`month` = 03
  ) a
ORDER BY
  dose1_pct ASC;