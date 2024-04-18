import Bench from "tinybench";
import json5 from "json5";
import * as MoonbitJson5 from "./target/js/release/build/json5/json5.js";
import json5String from "./json.js";

const bench = new Bench();

bench.add("MoonbitJson5.parse", () => {
  MoonbitJson5.parse(json5String);
});

bench.add("json5.parse", () => {
  json5.parse(json5String);
});

await bench.warmup();
console.profile('MoonbitJson5.parse');
await bench.run();
console.profileEnd();
console.table(bench.table());
