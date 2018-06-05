FROM golang:1.10-alpine AS builder

ENV DISTRIBUTION_DIR /go/src/github.com/docker/distribution
ENV DOCKER_BUILDTAGS include_oss include_gcs

ARG GOOS=linux
ARG GOARCH=amd64

RUN set -ex \
    && apk add --no-cache make git

WORKDIR $DISTRIBUTION_DIR
COPY . $DISTRIBUTION_DIR
COPY cmd/registry/config-dev.yml /etc/docker/registry/config.yml

RUN make PREFIX=/go clean binaries


# Build a minimal distribution container

FROM alpine:3.4

RUN set -ex \
    && apk add --no-cache ca-certificates apache2-utils

COPY --from=builder /go/bin/registry /bin/registry
COPY ./distribution-library-image/registry/config-example.yml /etc/docker/registry/config.yml

VOLUME ["/var/lib/registry"]
EXPOSE 5000

COPY ./distribution-library-image/docker-entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]

CMD ["/etc/docker/registry/config.yml"]

