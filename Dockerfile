### Fetch Repository
FROM bitnami/git as repo

ARG FOCALBOARD_REF

RUN git clone -b ${FOCALBOARD_REF} --depth 1 https://github.com/mattermost/focalboard.git /focalboard

### Webapp build
FROM node:16.3.0@sha256:ca6daf1543242acb0ca59ff425509eab7defb9452f6ae07c156893db06c7a9a4 as nodebuild

WORKDIR /webapp
COPY --from=repo /focalboard/webapp /webapp

RUN export CFLAGS="$CFLAGS -DPNG_ARM_NEON_OPT=0" && \
    npm install --no-optional && \
    npm run pack

FROM golang:1.18.3@sha256:b203dc573d81da7b3176264bfa447bd7c10c9347689be40540381838d75eebef AS gobuild

ARG TARGETARCH

WORKDIR /go/src/focalboard
COPY --from=repo /focalboard /go/src/focalboard

RUN sed -i "s/GOARCH=amd64/GOARCH=${TARGETARCH}/g" Makefile
RUN EXCLUDE_PLUGIN=true EXCLUDE_SERVER=true EXCLUDE_ENTERPRISE=true make server-linux arch=${TARGETARCH}
RUN mkdir /data

## Final image
FROM gcr.io/distroless/base-debian10@sha256:d2ce069a83a6407e98c7e0844f4172565f439dab683157bf93b6de20c5b46155

WORKDIR /opt/focalboard

COPY --from=gobuild --chown=nobody:nobody /data /data
COPY --from=nodebuild --chown=nobody:nobody /webapp/pack pack/
COPY --from=gobuild --chown=nobody:nobody /go/src/focalboard/bin/linux/focalboard-server bin/
COPY --from=gobuild --chown=nobody:nobody /go/src/focalboard/LICENSE.txt LICENSE.txt
COPY --from=gobuild --chown=nobody:nobody /go/src/focalboard/docker/server_config.json config.json

USER nobody

EXPOSE 8000/tcp 9092/tcp

VOLUME /data

CMD ["/opt/focalboard/bin/focalboard-server"]
