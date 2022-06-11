CREATE INDEX IF NOT EXISTS idx_all ON us_county.imp_deaths (county, month_code);

CREATE INDEX IF NOT EXISTS idx_all ON us_county.imp_population (county, year);

DROP TABLE IF EXISTS us_county.mortality;

CREATE TABLE us_county.mortality AS
SELECT
  a.county,
  a.year,
  right(month_code, 2) AS "month",
  month_code AS "year_month",
  deaths,
  population,
  deaths / population * 100000 AS "mortality"
FROM
  (
    SELECT
      county,
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
  AND a.county = b.county
ORDER BY
  a.county,
  month_code;

CREATE INDEX IF NOT EXISTS idx_all ON us_county.mortality (county, MONTH);

DROP TABLE IF EXISTS us_county.mortality_lreg;

CREATE TABLE us_county.mortality_lreg AS
SELECT
  county,
  slope,
  y_bar_max - x_bar_max * slope AS intercept
FROM
  (
    SELECT
      county,
      CASE
        WHEN sum(x_bar_delta * x_bar_delta) = 0 THEN 0
        ELSE sum(x_bar_delta * y_bar_delta) / sum(x_bar_delta * x_bar_delta)
      END AS slope,
      max(x_bar) AS x_bar_max,
      max(y_bar) AS y_bar_max
    FROM
      (
        SELECT
          *,
          x - x_bar AS 'x_bar_delta',
          y - y_bar AS 'y_bar_delta'
        FROM
          (
            SELECT
              county,
              x,
              avg(x) over (
                PARTITION by county
              ) AS x_bar,
              y,
              avg(y) over (
                PARTITION by county
              ) AS y_bar
            FROM
              (
                SELECT
                  county,
                  `year` AS x,
                  avg(mortality) AS y
                FROM
                  us_county.mortality
                WHERE
                  year IN (2015, 2016, 2017, 2018, 2019)
                GROUP BY
                  county,
                  `year`
              ) a
          ) a
      ) a
    GROUP BY
      county
  ) a;

DROP TABLE IF EXISTS us_county.mortality_baseline_correction;

CREATE TABLE us_county.mortality_baseline_correction AS
SELECT
  a.county,
  year,
  b.baseline / a.baseline AS baseline_correction
FROM
  (
    SELECT
      county,
      avg(year * slope + intercept) AS baseline
    FROM
      (
        SELECT
          2015 AS year
        UNION
        SELECT
          2016 AS year
        UNION
        SELECT
          2017 AS year
        UNION
        SELECT
          2018 AS year
        UNION
        SELECT
          2019 AS year
      ) a
      JOIN us_county.mortality_lreg b
    GROUP BY
      county
  ) a
  JOIN (
    SELECT
      county,
      year,
      year * slope + intercept AS baseline
    FROM
      (
        SELECT
          2014 AS year
        UNION
        SELECT
          DISTINCT year
        FROM
          us_county.mortality
      ) a
      JOIN us_county.mortality_lreg b
  ) b ON a.county = b.county;

DROP TABLE IF EXISTS us_county.mortality_baseline;

CREATE TABLE us_county.mortality_baseline AS
SELECT
  a.county,
  b.year,
  a.month,
  a.mortality * b.baseline_correction AS "mortality",
  mortality_stddev
FROM
  (
    SELECT
      county,
      `month`,
      avg(mortality) AS "mortality",
      stddev(mortality) AS "mortality_stddev"
    FROM
      us_county.mortality
    WHERE
      year IN (2015, 2016, 2017, 2018, 2019)
    GROUP BY
      county,
      `month`
  ) a
  RIGHT JOIN us_county.mortality_baseline_correction b ON a.county = b.county;

DROP TABLE IF EXISTS us_county.vaccinations;

CREATE TABLE us_county.vaccinations AS
SELECT
  county,
  year,
  `month`,
  round(avg(dose1)) AS "dose1"
FROM
  (
    SELECT
      concat(recip_county, " ", recip_state) AS county,
      cast(right(date, 4) AS UNSIGNED) AS "year",
      cast(left (date, 2) AS UNSIGNED) AS "month",
      CASE
        WHEN administered_dose1_recip <> "" THEN cast(administered_dose1_recip AS UNSIGNED)
        ELSE 0
      END AS dose1
    FROM
      us_county.imp_vaccinations a
  ) a
GROUP BY
  county,
  `month`,
  year
ORDER BY
  county,
  `year`,
  `month`;

CREATE INDEX IF NOT EXISTS idx_all ON us_county.vaccinations (county, year, `month`);

DROP TABLE IF EXISTS us_county.exp_mortality;

CREATE TABLE us_county.exp_mortality AS
SELECT
  *
FROM
  (
    SELECT
      REPLACE(b.county, ',', '') AS "county",
      b.year,
      b.month,
      concat (b.year, "/", b.month) AS "year_month",
      a.deaths AS "deaths",
      a.population AS "population",
      round(a.mortality, 1) AS "mortality",
      round(b.mortality, 1) AS baseline,
      round(b.mortality - 2 * b.mortality_stddev, 1) AS "baseline_normal_lower",
      round(b.mortality + 2 * b.mortality_stddev, 1) AS "baseline_normal_upper",
      round(b.mortality + 4 * b.mortality_stddev, 1) AS "baseline_excess"
    FROM
      us_county.mortality a
      RIGHT JOIN us_county.mortality_baseline b ON a.county = b.county
      AND a.year = b.year
      AND a.month = b.month
  ) a
ORDER BY
  county,
  year,
  `month`;

CREATE INDEX IF NOT EXISTS idx_all ON us_county.mortality (county, year, `month`);

SELECT
  a.*,
  b.dose1,
  round(dose1 / population, 3) AS dose1_pct
FROM
  us_county.exp_mortality a
  LEFT JOIN us_county.vaccinations b ON a.county = b.county
  AND a.year = b.year
  AND a.month = b.month;