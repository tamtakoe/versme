FROM alpine:3.21.2
RUN apk update
RUN apk add bash git git-lfs openssh-client jq curl
RUN git lfs install
COPY ./semver.sh /usr/local/bin/
COPY ./versme /usr/local/bin/

CMD [""]