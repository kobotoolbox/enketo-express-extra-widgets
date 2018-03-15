FROM kobotoolbox/enketo_express:1.61.4

# `npm install` custom widgets here. Please note that widgets must also be
# listed in config.json to be enabled; see
# https://github.com/kobotoolbox/enketo-express/blob/master/doc/custom-widgets.md

RUN npm install https://github.com/kobotoolbox/enketo-image-customization-widget.git
RUN npm install https://github.com/kobotoolbox/enketo-literacy-test-widget.git
