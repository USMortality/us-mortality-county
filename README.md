# Datasources

- US County Population 2010-2021: https://docs.google.com/spreadsheets/d/16NFiU_W04o5AypRzKi9BGrxftcHLhLkXcSndf5kRYaA/edit#gid=0
  - https://www.census.gov/programs-surveys/popest/data/tables.2021.List_58029271.html
- Deaths: https://wonder.cdc.gov/mcd-icd10-provisional.html
- Vaccinations: https://data.cdc.gov/Vaccinations/COVID-19-Vaccinations-in-the-United-States-County/8xkx-amqh

# Data cleansing
CDC Wonder files were converted to CSV:
e.g.: `./tools/wonderTxt2Csv.sh ./data/county/m_2018_1.txt`
then concatinated: `awk '(NR == 1) || (FNR > 1)' *.csv > deaths.csv`

# Download Vaccine File
The vaccination file is too big >100mb to store on Github, hence please download it yourself:
`wget "https://data.cdc.gov/api/views/8xkx-amqh/rows.csv?accessType=DOWNLOAD" -o data/vaccine/vaccinations.csv`

# Import
`./tools/import_csv.sh data/deaths/deaths.csv deaths_county`
`./tools/import_csv.sh data/population/us-county-population.csv deaths_county`
`./tools/import_csv.sh data/vaccine/vaccinations.csv deaths_county`

# Export
`mysql -h 127.0.0.1 -u root < ./queries/mortality_amish.sql >./out/mortality_amish.tsv`
