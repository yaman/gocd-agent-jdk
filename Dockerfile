FROM airdock/oracle-jdk:latest

ADD https://github.com/krallin/tini/releases/download/v0.15.0/tini-static-amd64 /usr/local/sbin/tini
ADD https://github.com/tianon/gosu/releases/download/1.10/gosu-amd64 /usr/local/sbin/gosu
ADD https://sonarsource.bintray.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-3.0.3.778-linux.zip /tmp/sonar-scanner.zip
# allow mounting ssh keys, dotfiles, and the go server config and data
VOLUME /godata

# force encoding
ENV LANG=en_US.utf8

RUN \
# add mode and permissions for files we added above
  chmod 0755 /usr/local/sbin/tini && \
  chown root:root /usr/local/sbin/tini && \
  chmod 0755 /usr/local/sbin/gosu && \
  chown root:root /usr/local/sbin/gosu && \
# add our user and group first to make sure their IDs get assigned consistently,
# regardless of whatever dependencies get added
  groupadd -g 1000 go && \ 
  useradd -u 1000 -g go -d /home/go -m go && \
  echo 'deb http://deb.debian.org/debian jessie-backports main' > /etc/apt/sources.list.d/jessie-backports.list && \
  apt-get update && \
  apt-get install -y git subversion mercurial openssh-client bash unzip curl && \
  apt-get autoclean && \
# gradle installation
  curl --fail --location --silent --show-error "https://services.gradle.org/distributions/gradle-4.1-bin.zip" > /tmp/gradle.zip && \
  unzip /tmp/gradle.zip -d / && \
  mv /gradle-4.1 /opt/ && \
# download the zip file
  curl --fail --location --silent --show-error "https://download.gocd.org/binaries/17.8.0-5277/generic/go-agent-17.8.0-5277.zip" > /tmp/go-agent.zip && \
# unzip the zip file into /go-agent, after stripping the first path prefix
  unzip /tmp/go-agent.zip -d / && \
  mv /go-agent-17.8.0 /go-agent && \
  rm /tmp/go-agent.zip && \
  unzip /tmp/sonar-scanner.zip -d / && \
  sed -i '/use_embedded_jre=true/d' /sonar-scanner-3.0.3.778-linux/bin/sonar-scanner

ENV PATH="/opt/gradle-4.1/bin:${PATH}"

ENV PATH="/sonar-scanner-3.0.3.778-linux/bin:${PATH}"

ADD docker-entrypoint.sh /
ENTRYPOINT ["/docker-entrypoint.sh"]
