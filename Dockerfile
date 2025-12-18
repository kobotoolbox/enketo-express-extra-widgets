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

# A skeleton configuration file that lists *all* custom *and* default widgets
# must be present at build time! Any widget not listed here will not work, even
# if it's listed in the run-time configuration file, which is completely
# separate.
# To check that this is working, inspect the contents of `js/build/widgets.js`
# after `grunt` completes.
COPY config-at-build-time.json packages/enketo-express/config/config.json

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
    && yarn workspace enketo-core install \
    && yarn workspace enketo-express run build \
    && yarn cache clean \
    && rm packages/enketo-express/config/config.json

# Since we're building anyway, install our favicon in a simple way instead of
# using a Docker volume
COPY images/* packages/enketo-express/public/images/
