FROM ghcr.io/enketo/enketo:7.6.1

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates && \
    apt-get clean && \
        rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# GitHub Actions adds an authentication header to the Git configuration,
# which prevents us from installing Node modules in *public* GitHub
# repositories. Remove it crudely. See also
# https://github.com/actions/checkout/issues/162#issuecomment-591198381
RUN sed -i '/extraheader = AUTHORIZATION/d' .git/config

# Add CSS so that `note` questions with `appearance` set to `kobo-disclaimer`
# appear in a special footer on every page of the form. See
# https://github.com/kobotoolbox/kpi/pull/4587
# https://github.com/kobotoolbox/kobocat/pull/882
COPY disclaimer-css.patch /tmp/
RUN git apply /tmp/disclaimer-css.patch

# Please note that widgets must also be listed in the run-time config.json to
# be enabled.
# ATTENTION: It seems bonkers to install `proxy-agent` here, but without it,
# the `add` operation fails with
#     Invariant Violation: expected workspace package to exist for "proxy-agent"
RUN yarn workspace enketo-express add \
    'proxy-agent@^6.5.0' \
    https://github.com/kobotoolbox/enketo-image-customization-widget#c98179be9359013c7d918031a1031524577a634d \
    https://github.com/kobotoolbox/enketo-literacy-test-widget#28b91c54ace66631f627203bb5e3c2a7c4599981 \
    && yarn install \
    && yarn workspace enketo-core install

# Append custom widget paths to the base image's default-config.json so that
# the grunt `widgets` task (which reads from default-config.json, NOT
# config.json) includes them in the generated widgets.js and _widgets.scss.
# This avoids maintaining a static copy of the full widget list, which would
# silently drop any new widgets added upstream.
RUN node -e " \
  const fs = require('fs'); \
  const p = 'packages/enketo-express/config/default-config.json'; \
  const c = JSON.parse(fs.readFileSync(p, 'utf8')); \
  c.widgets.push( \
    '../../../node_modules/enketo-image-customization-widget/image-customization', \
    '../../../node_modules/enketo-literacy-test-widget/literacywidget' \
  ); \
  fs.writeFileSync(p, JSON.stringify(c, null, 4) + '\n'); \
"

# Safety net: the custom widgets pin enketo-core in their own package.json.
# If yarn decides the base image's version doesn't satisfy that pin, it
# installs a nested copy under each widget's node_modules/. The widget then
# imports a *different* Widget base class from the one enketo-express uses,
# instanceof checks fail, and form submission silently breaks. Removing any
# nested copies forces resolution to the shared enketo-core. This is a no-op
# when yarn hoists correctly, but guards against future version mismatches.
RUN rm -rf node_modules/enketo-literacy-test-widget/node_modules \
           node_modules/enketo-image-customization-widget/node_modules

RUN yarn workspace enketo-express run build \
    && yarn cache clean

# Since we're building anyway, install our favicon in a simple way instead of
# using a Docker volume
COPY images/* packages/enketo-express/public/images/
