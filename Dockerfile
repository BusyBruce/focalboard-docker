### Fetch Repository
FROM bitnami/git as repo

ARG FOCALBOARD_REF

RUN git clone -b ${FOCALBOARD_REF} --depth 1 https://github.com/mattermost/focalboard.git /focalboard

### Webapp build
FROM node:16.3.0 as nodebuild

WORKDIR /webapp
COPY --from=repo /focalboard/webapp /webapp

RUN npm install --no-optional && \
    npm run pack

FROM golang:1.16.5 as gobuild

ARG TARGETARCH

WORKDIR /go/src/focalboard
COPY --from=repo /focalboard /go/src/focalboard

RUN sed -i "s/GOARCH=amd64/GOARCH=${TARGETARCH}/g" Makefile
RUN make server-linux
RUN mkdir /data

## Final image
FROM gcr.io/distroless/base-debian10

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
