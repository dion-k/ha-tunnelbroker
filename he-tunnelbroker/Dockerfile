ARG BUILD_FROM
FROM ${BUILD_FROM}

# Install required packages
RUN apk add --no-cache \
    iproute2 \
    curl \
    bash \
    iputils

# Copy the run script
COPY run.sh /run.sh
RUN chmod a+x /run.sh

CMD ["/run.sh"]
