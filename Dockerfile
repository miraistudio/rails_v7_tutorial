FROM ruby:3.1.0 as base

ENV LANG C.UTF-8
ENV TZ Asia/Tokyo
RUN apt-get update -qq && \
    apt-get install -y \
      shared-mime-info \
      nodejs \
      postgresql-client \
      git

WORKDIR /app
COPY Gemfile /app/Gemfile
COPY Gemfile.lock /app/Gemfile.lock
RUN bundle install
COPY . /app

FROM base as development

COPY entrypoint.sh /usr/bin/
RUN chmod +x /usr/bin/entrypoint.sh

ENTRYPOINT ["entrypoint.sh"]
EXPOSE 3000

CMD ["rails", "server", "-b", "0.0.0.0"]

FROM base as production

ENV RAILS_ENV=production
ENV RAILS_LOG_TO_STDOUT=true
ENV RAILS_SERVE_STATIC_FILES=enabled
ENV AWS_REGION=ap-northeast-1

CMD ["sh", "./startup_production.sh"]

EXPOSE 3000
