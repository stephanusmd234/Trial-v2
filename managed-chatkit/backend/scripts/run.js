#!/usr/bin/env node
const { spawn } = require("node:child_process");
const path = require("node:path");

const scriptDir = __dirname;

function run(cmd, args) {
  const child = spawn(cmd, args, {
    cwd: path.resolve(scriptDir, ".."),
    stdio: "inherit",
    shell: false,
  });
  child.on("exit", (code) => process.exit(code ?? 1));
  child.on("error", (err) => {
    console.error(err?.message ?? String(err));
    process.exit(1);
  });
}

if (process.platform === "win32") {
  run("powershell", [
    "-NoProfile",
    "-ExecutionPolicy",
    "Bypass",
    "-File",
    path.join(scriptDir, "run.ps1"),
  ]);
} else {
  run("bash", [path.join(scriptDir, "run.sh")]);
}

