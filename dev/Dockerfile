# Test runner image: headless Factorio plus Node for the factorio-test CLI.
ARG FACTORIO_VERSION=2.1.23
FROM factoriotools/factorio:${FACTORIO_VERSION} AS factorio

FROM node:22-trixie-slim
COPY --from=factorio /opt/factorio /opt/factorio
ENV FACTORIO_PATH=/opt/factorio/bin/x64/factorio
WORKDIR /mod
