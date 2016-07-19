FROM ruby:slim
MAINTAINER Jay Scott <jay@beardyjay.co.uk>

RUN apt-get update && apt-get -y install \
  gnuplot \
  lame \
  build-essential \
  libssl-dev \
  libcurl4-openssl-dev \ 
  postgresql-contrib \
  git-core \
  curl \
  libpq-dev \
  && rm -rf /var/lib/apt/lists/*

ADD . /home/warvox
ADD setup.sh /

WORKDIR /home/warvox
RUN ln -s /usr/bin/ruby2.1 /usr/bin/ruby \
    && bundle install \
    && make

EXPOSE 7777

CMD ["/setup.sh"]
