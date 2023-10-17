FROM erlang:23.0.3-alpine
RUN apk add --no-cache snappy-dev openssl-dev alpine-sdk bsd-compat-headers bash git make

ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=1001
ARG GRPNAME=vscodegrp

ENV DEBIAN_FRONTEND=noninteractive

RUN addgroup -g $USER_GID $GRPNAME \
    && adduser -u $USER_UID -g $GRPNAME -D $USERNAME
USER $USERNAME
