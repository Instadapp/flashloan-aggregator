import inquirer from "inquirer";
import { promises as fs } from "fs";

import { join } from "path";
import { execScript } from "./command";

let start: number, end: number;

async function testRunner() {
  const { chain } = await inquirer.prompt([
    {
      name: "chain",
      message: "What chain do you want to run tests on?",
      type: "list",
      choices: ["mainnet", "polygon", "avalanche", "arbitrum", "optimism"],
    },
  ]);
  const testsPath = join(__dirname, "../test", chain);
  await fs.access(testsPath);
  const availableTests = await fs.readdir(testsPath);
  if (availableTests.length === 0) {
    throw new Error(`No tests available for ${chain}`);
  }

  const { testName } = await inquirer.prompt([
    {
      name: "testName",
      message: "Which file's tests do you want to run?",
      type: "list",
      choices: ["all", ...availableTests],
    },
  ]);
  start = Date.now();
  let path: string;
  if (testName === "all") {
    path = availableTests.map(file => join(testsPath, file)).join(" ");
  } else {
    path = join(testsPath, testName);
  }

  await execScript({
    cmd: "npx",
    args: ["hardhat", "test", path],
    env: {
      networkType: chain,
    },
  });
  end = Date.now();
}

testRunner()
  .then(() => console.log(`🙌 finished the test runner, time taken ${(end - start) / 1000} sec`))
  .catch(err => console.error("❌ failed due to error: ", err));