import lowess from '@stdlib/stats-lowess';
import csvjson from 'csvjson';
import { getSmoothedArrayMulti } from 'gauss-window';
import { readFileSync, writeFileSync } from 'fs';
function fillerAutoIncrementArray(end, filler = 0) {
    const result = [];
    for (let i = 0; i < end; i++)
        result.push(filler++);
    return result;
}
const rawData = readFileSync('./out/mortality.tsv', {
    encoding: 'utf8'
});
// eslint-disable-next-line @typescript-eslint/no-unsafe-member-access, @typescript-eslint/no-unsafe-call
const data = csvjson.toObject(rawData, { delimiter: '\t', });
const countyData = new Map();
const columns = [
    'baseline',
    'baseline_normal_lower',
    'baseline_normal_upper',
    'baseline_excess'
];
for (const row of data) {
    let countyRows = countyData.get(row.county);
    if (!countyRows)
        countyRows = [];
    countyRows.push(row);
    countyData.set(row.county, countyRows);
}
// eslint-disable-next-line @typescript-eslint/no-unused-vars
for (const [_, value] of countyData) {
    for (const column of columns) {
        const y = [];
        for (const row of value)
            y.push(parseFloat(row[column]));
        const x = fillerAutoIncrementArray(y.length);
        // eslint-disable-next-line @typescript-eslint/no-unsafe-call
        const yLoess = lowess(x, y, { f: 0.1 });
        // eslint-disable-next-line @typescript-eslint/no-unsafe-call
        const ySmooth = getSmoothedArrayMulti(yLoess.y, 10);
        let i = 0;
        for (const row of value) {
            const val = Math.round(ySmooth[i++] * 10) / 10;
            row[column] = val.toString();
        }
    }
}
let result = [];
for (const [, value] of countyData)
    result = result.concat(value);
// eslint-disable-next-line @typescript-eslint/no-unsafe-member-access, @typescript-eslint/no-unsafe-call
const csvResult = csvjson.toCSV(result, {
    delimiter: '\t',
    wrap: false,
    headers: 'key'
});
// eslint-disable-next-line @typescript-eslint/no-unsafe-call
writeFileSync('./out/mortality_smoothed.tsv', csvResult, {
    encoding: 'utf8'
});
//# sourceMappingURL=index.js.map