FROM ruby:3.1.2

ENV BUNDLER_VERSION 2.3.7
ENV GEM_HOME /usr/local/bundle
ENV BUNDLE_SILENCE_ROOT_WARNING=1
ENV BUNDLE_APP_CONFIG="$GEM_HOME"
ENV PATH $GEM_HOME/bin:$PATH

RUN apt-get update -qq

RUN apt-get install -y \
    nodejs \
    tzdata \
    libxslt-dev \
    make \
    gcc \
    libc-dev \
    libxml2 \
    postgresql-client \
    npm \
    nano \
    vim

RUN rm -rf /var/lib/apt/lists*
RUN npm install --global yarn

RUN gem install bundler:${BUNDLER_VERSION}

RUN mkdir -p ${GEM_HOME} && chmod 777 ${GEM_HOME}

WORKDIR /app

COPY entrypoint.sh /usr/bin/
RUN chmod +x /usr/bin/entrypoint.sh

ENTRYPOINT [ "entrypoint.sh" ]
EXPOSE 3000