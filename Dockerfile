FROM linuxserver/ffmpeg:version-4.4-cli

ARG TARGETPLATFORM

RUN apt-get update && apt-get install -y \
    fuse \
    python3

# renovate: datasource=github-releases depName=rclone/rclone
ARG RCLONE_VERSION=v1.65.2
RUN RCLONE_PLATFORM=$(echo $TARGETPLATFORM | sed 's|/|-|g' ) && \
    curl -L -o /tmp/rclone.deb https://github.com/rclone/rclone/releases/download/${RCLONE_VERSION}/rclone-${RCLONE_VERSION}-${RCLONE_PLATFORM}.deb && \
    apt-get update && apt install -y /tmp/rclone.deb && rm /tmp/rclone.deb

COPY convert.py /usr/local/bin/convert.py
COPY entrypoint.sh /usr/local/bin/entrypoint.sh

RUN groupadd fuse && usermod -a -G fuse abc && \
    mkdir /videos

WORKDIR /videos

ENTRYPOINT [ "entrypoint.sh" ]
