FROM nginx
LABEL maintainer="Krunky"
LABEL description="Docker image for Nginx web server"

RUN rm -rf /etc/nginx/conf.d/default.conf
COPY nginvproapp.conf /etc/nginx/conf.d/nginvproapp.conf
