FROM debian:trixie-slim@sha256:62bd423aeee912639ca8ee681c2b762cb3e25137e0a92b20be455898a9f034ad AS download

ARG WACLI_SHA256=9cbee5b7779b5670bd16dcf8feda2294a11e4acc801d9837ef9cd1a6619fc73c
ARG WACLI_VERSION=v0.25.0

RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates curl \
    && curl -fsSL "https://github.com/openclaw/wacli/releases/download/${WACLI_VERSION}/wacli_${WACLI_VERSION#v}_linux_amd64.tar.gz" -o /tmp/wacli.tar.gz \
    && echo "${WACLI_SHA256}  /tmp/wacli.tar.gz" | sha256sum --check \
    && mkdir /out \
    && tar -xzf /tmp/wacli.tar.gz -C /out ./wacli ./LICENSE

FROM debian:trixie-slim@sha256:62bd423aeee912639ca8ee681c2b762cb3e25137e0a92b20be455898a9f034ad

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
