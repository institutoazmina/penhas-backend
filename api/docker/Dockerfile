FROM phusion/baseimage:focal-1.2.0
CMD ["/sbin/my_init"]

RUN apt-get update && apt-get install -y \
    build-essential \
    curl \
    libcurl4-openssl-dev libxml2 libxml2-dev libexpat1-dev zlib1g-dev libssl-dev \
    libjpeg-dev libpng-dev libgif-dev \
    git \
 && rm -rf /var/lib/apt/lists/* && apt-get clean

RUN useradd -ms /bin/bash app;

USER app
ADD install-perlbrew.sh /tmp/install-perlbrew.sh
RUN /tmp/install-perlbrew.sh

USER root
RUN apt-get update && apt-get install -y \
    libpq-dev \
    postgresql-client \
&& rm -rf /var/lib/apt/lists/* && apt-get clean

USER app

ADD install-cpan-modules.sh /tmp/install-cpan-modules.sh
RUN /tmp/install-cpan-modules.sh

USER root
RUN apt-get update && apt-get install -y \
    libmysqlclient-dev ffmpeg \
&& rm -rf /var/lib/apt/lists/* && apt-get clean

USER app

ADD Makefile_local.PL /tmp/Makefile.PL
ADD install-cpan-extra-modules.sh /tmp/install-cpan-extra-modules.sh
RUN /tmp/install-cpan-extra-modules.sh

USER root
RUN mkdir /etc/service/api
COPY docker/api.sh /etc/service/api/run

RUN mkdir /etc/service/penhas-minion-worker
COPY docker/penhas-minion-worker.sh /etc/service/penhas-minion-worker/run

COPY . /src

