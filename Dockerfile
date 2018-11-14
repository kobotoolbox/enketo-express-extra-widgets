FROM kobotoolbox/enketo_express:1.73.0

# `npm install` custom widgets here. Please note that widgets must also be
# listed in config.json to be enabled; see
# https://github.com/kobotoolbox/enketo-express/blob/master/doc/custom-widgets.md

# Remove these hashes once `enketo-core` 5.x.x moves beyond alpha
RUN npm install https://github.com/kobotoolbox/enketo-image-customization-widget.git#713f0dc
RUN npm install https://github.com/kobotoolbox/enketo-literacy-test-widget.git#96dfed3

# Avoid problems like like:
#   Error: Cannot find module 'vex-dialog-enketo' from '/srv/src/enketo_express/public/js/src/module'
RUN npm install
