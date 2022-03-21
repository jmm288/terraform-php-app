FROM php:7.4-apache

ENV PROJECT_FULL_NAME App
ENV PROJECT_NAME app
ENV PROJECT_BASE /opt/app
ENV PROJECT_USER app

RUN apt update && apt-get update -y

ADD . ${PROJECT_BASE}
WORKDIR ${PROJECT_BASE}
COPY . /var/www/html

EXPOSE 8000
