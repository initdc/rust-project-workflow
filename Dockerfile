# syntax=docker/dockerfile:1
FROM scratch

ARG TARGETPLATFORM
# ARG BUILDPLATFORM

WORKDIR /root
COPY target/docker/$TARGETPLATFORM/* .

CMD ["/root/rust-demo"]
