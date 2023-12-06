FROM debian:11

RUN apt-get update && apt-get install -y stunnel procps inotify-tools

COPY run.sh /run.sh

CMD ["/run.sh"]
