import lowess from '@stdlib/stats-lowess'
import csvjson from 'csvjson'
import { getSmoothedArrayMulti } from 'gauss-window'
import { readFileSync, writeFileSync } from 'fs'

function fillerAutoIncrementArray(end: number, filler = 0): number[] {
  const result: number[] = []
  for (let i = 0; i < end; i++) result.push(filler++)
  return result
}

interface Output { x: number[], y: number[] }

interface DataRow {
  county: string,
  year: string,
  month: string,
  year_month: string,
  deaths: string,
  population: string,
  mortality: string,
  baseline: string,
  baseline_normal_lower: string,
  baseline_normal_upper: string,
  baseline_excess: string,
  dose1: string,
  dose1_pct: string
}

const rawData = readFileSync('./out/mortality.tsv', {
  encoding: 'utf8'
})

// eslint-disable-next-line @typescript-eslint/no-unsafe-member-access, @typescript-eslint/no-unsafe-call
const data = csvjson.toObject(rawData, { delimiter: '\t', }) as DataRow[]
const countyData = new Map<string, DataRow[]>()

const columns = [
  'baseline',
  'baseline_normal_lower',
  'baseline_normal_upper',
  'baseline_excess'
]

for (const row of data) {
  let countyRows = countyData.get(row.county)
  if (!countyRows) countyRows = []
  countyRows.push(row)
  countyData.set(row.county, countyRows)
}

// eslint-disable-next-line @typescript-eslint/no-unused-vars
for (const [_, value] of countyData) {
  for (const column of columns) {
    const y: number[] = []
    for (const row of value) y.push(parseFloat(row[column] as string))
    const x = fillerAutoIncrementArray(y.length)
    // eslint-disable-next-line @typescript-eslint/no-unsafe-call
    const yLoess = lowess(x, y, { f: 0.1 }) as Output
    // eslint-disable-next-line @typescript-eslint/no-unsafe-call
    const ySmooth = getSmoothedArrayMulti(yLoess.y, 10) as number[]

    let i = 0
    for (const row of value) {
      const val = Math.round(ySmooth[i++] * 10) / 10
      row[column] = val.toString()
    }
  }
}

let result: DataRow[] = []
for (const [, value] of countyData) result = result.concat(value)

// eslint-disable-next-line @typescript-eslint/no-unsafe-member-access, @typescript-eslint/no-unsafe-call
const csvResult: string = csvjson.toCSV(result, {
  delimiter: '\t',
  wrap: false,
  headers: 'key'
}) as string

// eslint-disable-next-line @typescript-eslint/no-unsafe-call
writeFileSync('./out/mortality_smoothed.tsv', csvResult, {
  encoding: 'utf8'
})
