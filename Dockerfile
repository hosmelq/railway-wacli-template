FROM debian:trixie-slim@sha256:a29215f6a35e51e22adffa17f89e9d2ef06214e64a2bad10d765c46aea49f11f AS download

ARG WACLI_SHA256=747745eac681e7102ccb714f46566b8260a4ec02debc86b6c27c8dfd0e40808a
ARG WACLI_VERSION=v0.22.0

RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates curl \
    && curl -fsSL "https://github.com/openclaw/wacli/releases/download/${WACLI_VERSION}/wacli_${WACLI_VERSION#v}_linux_amd64.tar.gz" -o /tmp/wacli.tar.gz \
    && echo "${WACLI_SHA256}  /tmp/wacli.tar.gz" | sha256sum --check \
    && mkdir /out \
    && tar -xzf /tmp/wacli.tar.gz -C /out ./wacli ./LICENSE

FROM debian:trixie-slim@sha256:a29215f6a35e51e22adffa17f89e9d2ef06214e64a2bad10d765c46aea49f11f

LABEL org.opencontainers.image.description="Prebuilt wacli with persistent WhatsApp sessions for Railway" \
      org.opencontainers.image.source="https://github.com/hosmelq/railway-wacli-template"

RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates ffmpeg gosu jq tini tzdata \
    && apt-get clean \
    && useradd --uid 10001 --create-home --shell /bin/sh wacli \
    && install -d -o wacli -g wacli -m 700 /data

ENV HOME=/home/wacli \
    WACLI_STORE_DIR=/data/store \
    XDG_CACHE_HOME=/data/cache \
    XDG_CONFIG_HOME=/data/config \
    XDG_STATE_HOME=/data/state

COPY --from=download /out/wacli /usr/local/bin/wacli
COPY --from=download /out/LICENSE /usr/share/doc/wacli/LICENSE
COPY --chmod=755 start.sh /opt/railway/start.sh
COPY --chmod=755 wacli-pair wacli-run /usr/local/bin/

VOLUME ["/data"]
WORKDIR /data
ENTRYPOINT ["/usr/bin/tini", "--", "/opt/railway/start.sh"]
