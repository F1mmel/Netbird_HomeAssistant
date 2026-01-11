ARG BUILD_FROM
FROM ${BUILD_FROM:-ghcr.io/home-assistant/amd64-base:latest}

RUN apk add --no-cache curl nginx

RUN curl -L -o /tmp/netbird.tar.gz https://github.com/netbirdio/netbird/releases/download/v0.62.2/netbird_0.62.2_linux_amd64.tar.gz \
    && tar -xzf /tmp/netbird.tar.gz -C /tmp \
    && mv /tmp/netbird /usr/bin/netbird \
    && chmod +x /usr/bin/netbird \
    && rm -rf /tmp/netbird*


# Copy data for add-on
COPY run.sh /
RUN chmod +x /run.sh

CMD ["/bin/sh", "-c", "/run.sh"]
