FROM busybox:glibc

WORKDIR /web

COPY ./static /web/static

CMD ["busybox", "httpd", "-f", "-p", "8000", "-h", "/web/static"]

