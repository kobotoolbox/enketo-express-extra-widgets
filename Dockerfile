FROM enketo/enketo-express:6.1.0

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
COPY config-at-build-time.json config/config.json

# `npm install` by itself, with no widget, is necessary before any building
# because the base image calls `npm prune --production`.
# `npm install` custom widgets here according to
# https://enketo.github.io/enketo-express/tutorial-34-custom-widgets.html.
# Please note that widgets must also be listed in the run-time config.json to
# be enabled.
RUN npm install && \
    npm install git+https://github.com/kobotoolbox/enketo-image-customization-widget.git#ca9cd6726f1fb1c516dc3a068e55da2de10c828d  && \
    npm install git+https://github.com/kobotoolbox/enketo-literacy-test-widget.git#6f2b41a0c6ff55c7a5dc48e02609a034e4dac942 && \
    npx grunt && \
    npm prune --production && \
    rm config/config.json


# Since we're building anyway, install our favicon in a simple way instead of
# using a Docker volume
COPY images/* public/images/
