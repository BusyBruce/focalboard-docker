ARG TARGETARCH
ARG FOCALBOARD_REF

### Webapp build
FROM node:16.3.0-alpine as nodebuild

RUN git clone -b ${FOCALBOARD_REF} --depth 1 https://github.com/mattermost/focalboard.git /focalboard

WORKDIR /focalboard/webapp

RUN npm install --no-optional && \
    npm run pack

FROM golang:1.16.5-alpine as gobuild

RUN git clone -b ${FOCALBOARD_REF} --depth 1 https://github.com/mattermost/focalboard.git /go/src/focalboard

WORKDIR /go/src/focalboard

RUN sed -i "s/GOARCH=amd64/GOARCH=${TARGETARCH}/g" Makefile
RUN  make server-linux
RUN mkdir /data

## Final image
FROM gcr.io/distroless/base-debian10

WORKDIR /opt/focalboard

COPY --from=gobuild --chown=nobody:nobody /data /data
COPY --from=nodebuild --chown=nobody:nobody /focalboard/webapp/pack pack/
COPY --from=gobuild --chown=nobody:nobody /go/src/focalboard/bin/linux/focalboard-server bin/
COPY --from=gobuild --chown=nobody:nobody /go/src/focalboard/LICENSE.txt LICENSE.txt
COPY --from=gobuild --chown=nobody:nobody /go/src/focalboard/docker/server_config.json config.json

USER nobody

EXPOSE 8000/tcp

EXPOSE 8000/tcp 9092/tcp

VOLUME /data

CMD ["/opt/focalboard/bin/focalboard-server"]

VOLUME /data

CMD ["/opt/focalboard/bin/focalboard-server"]
