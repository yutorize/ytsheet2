FROM httpd:latest

COPY ./httpd.conf /usr/local/apache2/conf/httpd.conf

RUN \
    DEBIAN_FRONTEND=noninteractive && \
    apt-get update && \
    apt-get install -y \
        build-essential \
        apt-utils \
        ssl-cert \
        apache2 \
        apache2-utils \
        apache2-dev \
        libapache2-mod-perl2 \
        libapache2-mod-perl2-dev \
        libcgi-pm-perl \
        libcgi-session-perl \
        liblocal-lib-perl \
        cpanminus \
        libexpat1-dev \
        libssl-dev \
        libapreq2-dev \
        zip && \
    a2enmod cgid && \
    a2enmod rewrite && \
    a2dissite 000-default && \
    apt-get update -y && \
    apt-get upgrade -y && \
apt-get -y clean

RUN \
    cpanm CGI::Minimal && \
    cpanm Unicode::Japanese