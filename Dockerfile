FROM alpine:latest
RUN apk update
RUN apk add bash git openssh-client jq curl
RUN cp ./semver.sh /usr/local/bin/semver.sh
RUN cp ./version.sh /usr/local/bin/version.sh

CMD [""]