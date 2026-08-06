#!/usr/bin/env node
// Append custom widget paths to the base image's default-config.json so that
// the grunt `widgets` task (which reads from default-config.json, NOT
// config.json) includes them in the generated widgets.js and _widgets.scss.
// This avoids maintaining a static copy of the full widget list, which would
// silently drop any new widgets added upstream.
const fs = require("fs");

const path = "packages/enketo-express/config/default-config.json";
const config = JSON.parse(fs.readFileSync(path, "utf8"));

config.widgets.push(
  "../../../node_modules/enketo-image-customization-widget/image-customization",
  "../../../node_modules/enketo-literacy-test-widget/literacywidget",
);

fs.writeFileSync(path, JSON.stringify(config, null, 4) + "\n");
