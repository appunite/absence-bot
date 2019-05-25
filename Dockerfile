FROM norionomura/swift:501

RUN apt-get update
RUN apt-get install -y postgresql libpq-dev openssl libssl-dev locales

RUN locale-gen en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

WORKDIR /app

COPY Makefile ./
COPY Package.swift ./
COPY Sources ./Sources
COPY Tests ./Tests

RUN swift build --product Server --configuration release
CMD .build/release/Server
