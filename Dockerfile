FROM alpine

# Install base packages
RUN apk update
RUN apk upgrade
RUN apk add curl wget bash

# Install ruby and ruby-bundler
RUN apk add ruby ruby-bundler ruby-dev build-base libffi-dev curl-dev libxml2 zlib-dev
RUN apk add git rpm rpm-dev

RUN mkdir /usr/fpmbuild
WORKDIR /usr/fpmbuild

COPY Gemfile /usr/fpmbuild/
COPY simp-metadata-0.0.1.gem /tmp

RUN gem install /tmp/simp-metadata-0.0.1.gem --no-ri --no-rdoc
RUN bundle install

COPY . /usr/fpmbuild
