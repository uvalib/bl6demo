FROM ruby:2.5.1-alpine
RUN apk add --no-cache build-base sqlite-dev nodejs bash tzdata

# Create the run user and group
RUN addgroup webservice && adduser -D -G webservice webservice

# set the timezone appropriatly
ENV TZ='America/New_York'
RUN ln -snf "/usr/share/zoneinfo/$TZ" /etc/localtime && \
    echo "$TZ" > /etc/timezone

# set the locale correctly
ENV LANG='en_US.UTF-8' LANGUAGE='en_US:en' LC_ALL='en_US.UTF-8'

# Copy the Gemfile and Gemfile.lock into the image.
# Temporarily set the working directory to where they are.
WORKDIR /tmp
ADD Gemfile Gemfile
ADD Gemfile.lock Gemfile.lock
RUN bundle install

# create work directory
ENV APP_HOME /bl6demo
WORKDIR $APP_HOME

# copy the application
ADD . $APP_HOME

# generate the assets
RUN RAILS_ENV=production SECRET_KEY_BASE=x rake assets:precompile

# Update permissions
RUN chown -R webservice "$APP_HOME" /home/webservice
RUN chgrp -R webservice "$APP_HOME" /home/webservice

# Specify the user
USER webservice

# Define port and startup script
EXPOSE 3000
CMD scripts/entry.sh


