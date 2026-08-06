#!/usr/bin/env node
// `yarn workspace enketo-express add <pkg>` (and plain `yarn add`) triggers a
// long-standing Yarn Classic bug where the hoister crashes with
//     Invariant Violation: expected workspace package to exist for "..."
// (see https://github.com/yarnpkg/yarn/issues/7807). The workaround is to
// skip the `add` command entirely: write the new dependencies directly into
// enketo-express's package.json, then run a plain `yarn install`, which does
// not hit the buggy code path.
const fs = require("fs");

const path = "packages/enketo-express/package.json";
const pkg = JSON.parse(fs.readFileSync(path, "utf8"));

Object.assign(pkg.dependencies, {
  "enketo-image-customization-widget":
    "https://github.com/kobotoolbox/enketo-image-customization-widget#c98179be9359013c7d918031a1031524577a634d",
  "enketo-literacy-test-widget":
    "https://github.com/kobotoolbox/enketo-literacy-test-widget#28b91c54ace66631f627203bb5e3c2a7c4599981",
  "proxy-agent": "^6.5.0",
  vite: "^6.4.3",
});

fs.writeFileSync(path, JSON.stringify(pkg, null, 4) + "\n");
