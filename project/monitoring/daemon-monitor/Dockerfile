FROM alpine:3.20

RUN apk add --no-cache daemontools-encore curl jq postgresql16-client

# Layout
RUN mkdir -p /etc/service/daemon-monitor/log
COPY daemon-monitor/scraper.sh /etc/service/daemon-monitor/run
COPY daemon-monitor/multilog.sh /etc/service/daemon-monitor/log/run
RUN chmod +x /etc/service/daemon-monitor/run /etc/service/daemon-monitor/log/run

# Run daemontools supervisor
CMD ["/bin/sh","-lc","exec svscan /etc/service"]
