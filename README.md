# Lighttpd Webdav (Alpine 기반)

## 소개
 Alpine 기반으로 제작된 Lighttpd WebDav 서버 이미지

## 주요 기능

- 🧊 /webdav 폴더의 UID/GID를 읽어서 Lighttpd UID/GID로 변경
  > **Volume**으로 지정된 경로가 *root*일 경우 오류 (무한 재부팅)  
  > UID/GID가 이미지 내에서 중복될 경우 UID/GID 변경 안함 
  
## Nginx Proxy Manager
 - Advanced (Custom Nginx Configuration)
   ```
   location / {
       auth_basic           "Private Site";    ## 인증 관련 설정 
       auth_basic_user_file "/data/access/1";  ## 인증 관련 설정 (사용자 목록)
       proxy_set_header     Host $host;
       proxy_set_header     X-Real-IP $remote_addr;
       proxy_set_header     X-Forwarded-For $proxy_add_x_forwarded_for;
       proxy_set_header     X-Forwarded-Proto $scheme;
       proxy_pass           http://$server:$port$request_uri;
       proxy_read_timeout   90;
   }
   ```
## Docker
 - docker-compose.yml
   ```yml
   version: '3.8'

   services:
     webdav:
       build: .
       container_name: lighttpd-webdav
       volumes:
         - ./webdav:/webdav
       networks:
         - web
       restart: unless-stopped
   networks:
    web:
       external: true
   ```
 - Dockerfile
   ```dockerfile
   FROM alpine:latest
   
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
   ```
 - lighttpd.conf
   ```conf
   # 활성화할 모듈 목록
   server.modules += ("mod_webdav", "mod_setenv")
   
   # MIME 타입 설정 파일
   include "mime-types.conf"
   
   # 웹 루트 경로 설정 (WebDAV 저장 위치)
   server.document-root = "/webdav"
   
   # 파일명 인코딩 설정 (한글 파일명 깨짐 방지)
   server.encoding = "utf-8"
   
   # 환경 변수 설정 (locale 관련 이슈 방지용)
   setenv.add-environment = (
       "LANG" => "en_US.UTF-8"
   )
   
   # 서버 리스닝 포트 (기본값은 80, 명시적으로 적어줌)
   server.port = 80
   
   # 디렉토리 리스트 보여주기 설정 (브라우저에서 파일 목록 보기 허용)
   dir-listing.activate = "enable"
   dir-listing.encoding = "utf-8"
   dir-listing.set-footer = "WebDav Server"
   
   # WebDAV 사용 설정
   webdav.activate = "enable"      # WebDAV 활성화
   webdav.is-readonly = "disable"     # 쓰기 허용 (enable = 읽기 전용)
   ```
- entrypoint.sh
   ```bash
   #!/bin/sh
   set -e
   
   MOUNTED_DIR="/webdav"
   LIGHTTPD_USER="lighttpd"
   
   if [ -d "$MOUNTED_DIR" ]; then
     MOUNTED_UID=$(stat -c "%u" "$MOUNTED_DIR")
     MOUNTED_GID=$(stat -c "%g" "$MOUNTED_DIR")
   
     echo "Mounted directory UID: $MOUNTED_UID  GID: $MOUNTED_GID"
   
     CURRENT_UID=$(id -u "$LIGHTTPD_USER")
     CURRENT_GID=$(id -g "$LIGHTTPD_USER")
   
     echo "Current Lighttpd user UID: $CURRENT_UID"
     echo "Current Lighttpd user GID: $CURRENT_GID"
   
     # UID가 다르면 변경
     if [ "$MOUNTED_UID" != "$CURRENT_UID" ]; then
       if getent passwd "$MOUNTED_UID" > /dev/null; then
         echo "UID $MOUNTED_UID already exists, skipping usermod"
       else
         echo "Changing Lighttpd user UID to: $MOUNTED_UID"
         usermod -u "$MOUNTED_UID" "$LIGHTTPD_USER"
       fi
     fi
   
     # GID가 다르면 변경
     if [ "$MOUNTED_GID" != "$CURRENT_GID" ]; then
       if getent group "$MOUNTED_GID" > /dev/null; then
         echo "GID $MOUNTED_GID already exists, skipping groupmod"
       else
         echo "Changing Lighttpd user GID to: $MOUNTED_GID"
         groupmod -g "$MOUNTED_GID" "$LIGHTTPD_USER"
       fi
     fi
   else
     echo "Warning: Mounted directory '$MOUNTED_DIR' not found."
   fi
   
   # Lighttpd 실행
   exec "$@"
   ```
