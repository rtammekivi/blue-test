FROM docker.io/nginxinc/nginx-unprivileged:1.30-alpine

RUN sed -i 's/^worker_processes.*/worker_processes 1;/' /etc/nginx/nginx.conf

COPY docker/nginx/default.conf /etc/nginx/conf.d/default.conf
