#!/usr/bin/env node

const branch = process.env.GIT_BRANCH || process.env.BRANCH_NAME || '';
if (!branch) {
  process.exit(0);
}

const allowed = /^(feature|bugfix|performance|security|refactor|release|hotfix)\/.+/;
if (!allowed.test(branch)) {
  console.error(`Invalid branch name: ${branch}`);
  process.exit(1);
}
