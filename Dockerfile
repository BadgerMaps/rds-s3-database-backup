FROM python:3.6-alpine
RUN apk --update add postgresql14-client
RUN rm -rf /var/cache/apk/*
RUN pip install --upgrade awscli

WORKDIR /src
COPY scripts/. .
RUN find . -type f -exec chmod +x {} +
