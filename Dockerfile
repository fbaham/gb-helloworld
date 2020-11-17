FROM archlinux:latest
WORKDIR /app
COPY . .
RUN pacman -Suy --noconfirm rgbds
RUN find /var/cache/pacman/ -type f -delete