FROM ghcr.io/enketo/enketo:main

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
# ATTENTION: `yarn workspace enketo-express add <pkg>` (and plain `yarn add`)
# triggers a long-standing Yarn Classic bug where the hoister crashes with
#     Invariant Violation: expected workspace package to exist for "..."
# (see https://github.com/yarnpkg/yarn/issues/7807). The workaround, applied
# by scripts/add-widget-dependencies.js, is to skip the `add` command
# entirely and write the new dependencies directly into enketo-express's
# package.json, then run a plain `yarn install`, which does not hit the
# buggy code path.
COPY scripts/add-widget-dependencies.js /tmp/
RUN node /tmp/add-widget-dependencies.js \
    && yarn install \
    && yarn workspace enketo-core install

# See scripts/register-widgets.js for why this is needed.
COPY scripts/register-widgets.js /tmp/
RUN node /tmp/register-widgets.js

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
