FROM python:3.10

# RUN mkdir -p /app
WORKDIR /app

RUN apt-get update \
    && apt-get install -y \
        vim \
        curl \
        # sudo \
        wget \
        software-properties-common \
        # python3 \
        python-is-python3 \
        python3-pip \
        # git \
        # ca-certificates \
        # gnupg \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN pip config set global.trusted-host "pypi.org pypi.python.org files.pythonhosted.org" \
    && pip install dbworkload[postgres] \
    && mkdir -p /app

COPY . /app

# RUN mkdir -p /app/certs
# COPY certs /app/
# ENV PIP_CERT=/app/certs/crl.netskope.ca.pem

# RUN ls -l /app \
#     && ls -l /app/certs \
#     && env | grep PIP \
#     && pip install "dbworkload[postgres]"
