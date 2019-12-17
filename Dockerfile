FROM kobotoolbox/enketo_express:1.81.3

# `npm install` custom widgets here. Please note that widgets must also be
# listed in config.json to be enabled; see
# https://github.com/kobotoolbox/enketo-express/blob/master/doc/custom-widgets.md

RUN npm install https://github.com/kobotoolbox/enketo-image-customization-widget.git
RUN npm install https://github.com/kobotoolbox/enketo-literacy-test-widget.git

# Avoid problems like like:
#   Error: Cannot find module 'vex-dialog-enketo' from '/srv/src/enketo_express/public/js/src/module'
RUN npm install
