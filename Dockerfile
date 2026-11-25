FROM debian:trixie-slim@sha256:8aa5a7bf5a1955bddbe7d74fcdd0b91ab30e74362a8b73af672b0481b35b44a0 AS download

ARG WACLI_SHA256=515405c5a33c7f651a368484740db662736f50c275be5a0504fb0a84dce47013
ARG WACLI_VERSION=v0.26.1

RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates curl \
    && curl -fsSL "https://github.com/openclaw/wacli/releases/download/${WACLI_VERSION}/wacli_${WACLI_VERSION#v}_linux_amd64.tar.gz" -o /tmp/wacli.tar.gz \
    && echo "${WACLI_SHA256}  /tmp/wacli.tar.gz" | sha256sum --check \
    && mkdir /out \
    && tar -xzf /tmp/wacli.tar.gz -C /out ./wacli ./LICENSE

FROM debian:trixie-slim@sha256:8aa5a7bf5a1955bddbe7d74fcdd0b91ab30e74362a8b73af672b0481b35b44a0

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
