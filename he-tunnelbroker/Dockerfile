ARG BUILD_FROM
FROM ${BUILD_FROM}

# Install required packages
RUN apk add --no-cache \
    iproute2 \
    curl \
    bash \
    kmod \
    iputils

# Copy run script into the correct s6-overlay location
COPY run.sh /etc/services.d/he-tunnelbroker/run
RUN chmod a+x /etc/services.d/he-tunnelbroker/run

# Optional: add a finish script for clean shutdown
COPY finish.sh /etc/services.d/he-tunnelbroker/finish
RUN chmod a+x /etc/services.d/he-tunnelbroker/finish
