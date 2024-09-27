FROM enketo/enketo-express:7.3.1

RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 \
    build-essential \
    git \
    ca-certificates && \
    npm install -g yarn@1.22.22 --force

ENV ENKETO_SRC_DIR=/srv/src/enketo/enketo
WORKDIR ${ENKETO_SRC_DIR}

RUN git clone https://github.com/enketo/enketo ${ENKETO_SRC_DIR}

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

# Add CSS so that `note` questions with `appearance` set to `kobo-disclaimer`
# appear in a special footer on every page of the form. See
# https://github.com/kobotoolbox/kpi/pull/4587
# https://github.com/kobotoolbox/kobocat/pull/882
COPY disclaimer-css.patch /tmp/
RUN git apply /tmp/disclaimer-css.patch

# Please note that widgets must also be listed in the run-time config.json to
# be enabled.
RUN yarn install --frozen-lockfile \
    && yarn workspace enketo-express add https://github.com/kobotoolbox/enketo-image-customization-widget#cd36c2c050e521b9c8a9f7c2f00f7c7c0bc3ec67 -W \
    && yarn workspace enketo-express add https://github.com/kobotoolbox/enketo-literacy-test-widget#b89f5cf8e03df5a33802d19a03807216c1c1d328 -W \
    && yarn workspace enketo-express run build \
    && yarn cache clean \
    && rm config/config.json

# Since we're building anyway, install our favicon in a simple way instead of
# using a Docker volume
COPY images/* public/images/

WORKDIR ${ENKETO_SRC_DIR}/packages/enketo-express

EXPOSE 8005

CMD ["yarn", "workspace", "enketo-express"]
