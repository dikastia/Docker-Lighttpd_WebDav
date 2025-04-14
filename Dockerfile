FROM alpine:latest

LABEL org.opencontainers.image.title "Lighttpd WebDav" \
      org.opencontainers.image.version "1.0.0" \
      org.opencontainers.image.source "https://github.com/dikastia/Docker-Nginx_WebDav" \
      org.opencontainers.image.description "Lighttpd WebDav Server"

# 필요한 패키지 설치

RUN apk add --no-cache shadow lighttpd lighttpd-mod_webdav && mkdir -p /webdav && chown lighttpd:lighttpd /webdav
    
    
# WebDAV 설정 파일과 엔트리포인트 스크립트 복사
COPY lighttpd.conf /etc/lighttpd/lighttpd.conf
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 80
# Lighttpd 실행
ENTRYPOINT ["/entrypoint.sh"]
CMD ["/usr/sbin/lighttpd", "-D", "-f", "/etc/lighttpd/lighttpd.conf"]