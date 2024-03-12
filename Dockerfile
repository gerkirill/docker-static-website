ARG ALPINE_VERSION=3.18.4

FROM alpine:${ALPINE_VERSION} AS builder

ARG BUSYBOX_VERSION=1.36.1

# Install all dependencies required for compiling busybox
RUN apk add gcc musl-dev make perl

# Download busybox sources
RUN wget https://busybox.net/downloads/busybox-${BUSYBOX_VERSION}.tar.bz2 \
  && tar xf busybox-${BUSYBOX_VERSION}.tar.bz2 \
  && mv /busybox-${BUSYBOX_VERSION} /busybox

WORKDIR /busybox

# Copy the busybox build config (limited to httpd)
COPY .config .

# Compile and install busybox
RUN make && make install

# create httpd symlink as it is not created by the make
RUN ln -s /bin/busybox /busybox/_install/bin/httpd
# copy custom script for ENV export in JSON format
COPY ./env2json.sh /busybox/_install/bin
## symlink the .sh script so it is available w/o .sh
RUN ln -s /bin/env2json.sh /busybox/_install/bin/env2json


# Switch to the scratch image
FROM scratch

EXPOSE 3000

# Copy over the user
# COPY --from=builder /etc/passwd /etc/passwd

# Copy the busybox static binary and symlinks
COPY --from=builder /busybox/_install/bin/ /bin/

# Create a non-root user to own the files and run our server
RUN ( echo "root:x:0:root" ; echo "static:x:1000:static" ) >> /etc/group
RUN echo "static:x:1000:1000:static:/home/static:/bin/ash" >> /etc/passwd

WORKDIR /home/static

RUN chown static:static .

# Use our non-root user
USER static

# Uploads a blank default httpd.conf
# This is only needed in order to set the `-c` argument in this base file
# and save the developer the need to override the CMD line in case they ever
# want to use a httpd.conf
COPY --chown=static:static httpd.conf .

# Copy the static website
# Use the .dockerignore file to control what ends up inside the image!
COPY --chown=static:static ./static/ .

# Run busybox httpd
CMD ["ash", "-c", "env2json PUBLIC_ yes > environment.json && httpd -f -v -p 3000 -c httpd.conf"]
