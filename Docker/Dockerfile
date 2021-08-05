FROM splunk/universalforwarder:latest
USER root

RUN microdnf install yum

RUN yum update -y \
  && yum install -y \
  nc \
  jq \
  && yum clean all

ARG CACHE_BUST
COPY splunk-profile.sh /etc/profile.d
#RUN echo "export PATH=$PATH:/usr/local/nginx" >> ~/.bashrc
#RUN echo "alias reload='nginx -s reload'" >> ~/.bashrc
