FROM golang:1.16.5 as gobuild

ARG TARGETARCH
ARG FOCALBOARD_PATH

WORKDIR /go/src/focalboard
COPY /${FOCALBOARD_PATH}/focalboard /go/src/focalboard

RUN sed -i "s/GOARCH=amd64/GOARCH=${TARGETARCH}/g" Makefile
RUN  make server-linux
RUN mkdir /data

## Final image
FROM gcr.io/distroless/base-debian10

WORKDIR /opt/focalboard

COPY --from=gobuild --chown=nobody:nobody /data /data
COPY --chown=nobody:nobody /${FOCALBOARD_PATH}/focalboard/webapp/pack pack/
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
