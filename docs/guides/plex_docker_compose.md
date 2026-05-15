
# Use the official Plex Media Server Docker image
FROM plexinc/pms-docker

# Set environment variables for Plex
ENV PLEX_MEDIA_SERVER_MAX_PLUGIN_PROCS=6 \
    PLEX_MEDIA_SERVER_MAX_STACK_SIZE=3000 \
    PLEX_MEDIA_SERVER_APPLICATION_SUPPORT_DIR=/config \
    PLEX_MEDIA_SERVER_HOME=/usr/lib/plexmediaserver \
    PLEX_MEDIA_SERVER_MAX_LOCK_MEMORY=1000 \
    PLEX_MEDIA_SERVER_TMPDIR=/tmp \
    LD_LIBRARY_PATH=/usr/lib/plexmediaserver \
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    LC_ALL=en_US.UTF-8

# Copy configuration files
#COPY plex_config /config

# Install locales package
RUN apt-get update && \
    apt-get install -y locales apt-utils dialog wget && \
    locale-gen en_US.UTF-8
RUN wget https://github.com/prometheus/node_exporter/releases/download/v1.6.0/node_exporter-1.6.0.linux-amd64.tar.gz && \
    tar -xvzf node_exporter-1.6.0.linux-amd64.tar.gz && \
    mv node_exporter-1.6.0.linux-amd64/node_exporter /usr/local/bin/node_exporter

# Expose metrics port
EXPOSE 9101

# Set locale environment variables
ENV LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    LC_ALL=en_US.UTF-8

# Expose Plex port
EXPOSE 32400/tcp

# Mount NAS server for media files
VOLUME /nas
VOLUME /external