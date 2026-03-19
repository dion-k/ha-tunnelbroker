ARG BUILD_FROM
FROM ${BUILD_FROM}

# Install required packages
RUN apk add --no-cache \
    iproute2 \
    curl \
    bash \
    kmod \
    iputils

# Copy run script
COPY run.sh /
RUN chmod a+x /run.sh

ENTRYPOINT []
CMD ["/run.sh"]
