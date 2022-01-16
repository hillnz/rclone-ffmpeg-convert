FROM linuxserver/ffmpeg:version-4.4-cli

ARG TARGETPLATFORM

ENV PUID=1000
ENV PGID=1000

RUN apt-get update && apt-get install -y \
    fuse

# renovate: datasource=github-releases depName=rclone/rclone
ARG RCLONE_VERSION=v1.57.0
RUN RCLONE_PLATFORM=$(echo $TARGETPLATFORM | sed 's|/|-|g' ) && \
    curl -L -o /tmp/rclone.deb https://github.com/rclone/rclone/releases/download/${RCLONE_VERSION}/rclone-${RCLONE_VERSION}-${RCLONE_PLATFORM}.deb && \
    apt-get update && apt install -y /tmp/rclone.deb && rm /tmp/rclone.deb

COPY convert.sh /usr/local/bin/convert.sh
COPY entrypoint.sh /usr/local/bin/entrypoint.sh

WORKDIR /videos

RUN groupadd --gid $PGID ffmpeg && useradd --no-log-init -r --uid $PUID --gid $PGID ffmpeg

USER ffmpeg

ENTRYPOINT [ "entrypoint.sh" ]
