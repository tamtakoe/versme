FROM alpine:3.19.1
RUN apk update
RUN apk add bash git openssh-client jq curl
COPY ./semver.sh /usr/local/bin/
COPY ./version.sh /usr/local/bin/

CMD [""]