FROM ubuntu:16.04

MAINTAINER Michal Zakrzewski <737ryk@gmail.com>
LABEL version="spark_2.1_hadoop_2.7"

ARG JAVA_VERSION=8
ARG SPARK_VERSION="v2.1.0"
ARG HADOOP_VERSION="2.7"

# Install Python
RUN \
  apt-get update && \
  apt-get install -y python python-dev python-pip python-virtualenv && \
  rm -rf /var/lib/apt/lists/*

# Install R
RUN echo "deb http://cran.rstudio.com/bin/linux/ubuntu xenial/" | tee -a /etc/apt/sources.list && \
    gpg --keyserver keyserver.ubuntu.com --recv-key E084DAB9 && \
    gpg -a --export E084DAB9 | apt-key add - && \
    apt-get update && \
    apt-get install -y libssl-dev r-base r-base-dev libcurl4-gnutls-dev

# Install system tools
RUN \
  sed -i 's/# \(.*multiverse$\)/\1/g' /etc/apt/sources.list && \
  apt-get update && \
  apt-get -y upgrade && \
  apt-get install -y build-essential && \
  apt-get install -y software-properties-common && \
  apt-get install -y byobu curl git htop man unzip nano wget && \
  rm -rf /var/lib/apt/lists/*

# Install Java
RUN \
  echo oracle-java${JAVA_VERSION}-installer shared/accepted-oracle-license-v1-1 select true | debconf-set-selections && \
  add-apt-repository -y ppa:webupd${JAVA_VERSION}team/java && \
  apt-get update && \
  apt-get install -y oracle-java${JAVA_VERSION}-installer && \
  rm -rf /var/lib/apt/lists/* && \
  rm -rf /var/cache/oracle-jdk${JAVA_VERSION}-installer

# Define commonly used JAVA_HOME variable
ENV JAVA_HOME /usr/lib/jvm/java-${JAVA_VERSION}-oracle

# Install Spark
RUN apt-get install git

RUN git clone  --depth 1 --branch ${SPARK_VERSION} https://github.com/apache/spark.git

WORKDIR spark

ENV R_HOME /usr/lib/R
RUN ./R/install-dev.sh

ENV MAVEN_OPTS "-Xmx2g -XX:ReservedCodeCacheSize=512m"

RUN ./build/mvn -Pyarn -Pmesos -Phive  -Psparkr  -Phive-thriftserver -Phadoop-${HADOOP_VERSION} -Dhadoop.version=${HADOOP_VERSION}.0 -DskipTests clean package

ENV SPARK_HOME /spark

expose 4040

CMD ["/spark/bin/spark-shell"]
