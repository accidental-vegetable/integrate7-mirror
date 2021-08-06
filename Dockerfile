FROM busybox:latest
RUN mkdir /src
COPY *.7z /src/
CMD ["/bin/sh"]