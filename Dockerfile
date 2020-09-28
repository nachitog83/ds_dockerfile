FROM python:3.8.2-slim-buster

# Adds metadata to the image as a key value pair example LABEL version="1.0"
LABEL maintainer="Ignacio Grosso"

# Set environment variables
ENV LANG=C.UTF-8 LC_ALL=C.UTF-8 PATH=/opt/conda/bin:$PATH

# Set up WorkDirs
RUN mkdir /root/GitProjects
WORKDIR /root/

COPY ./Pipfile /root
COPY ./Pipfile.lock /root

# Install Debian packages
RUN apt-get -qq update && apt-get -qq -y install apt-utils \
    autoconf \
    automake \
    make \
    libtool \
    python-dev \
    curl \
    git-core \
    ca-certificates \
    pkg-config \
    tree \
    bzip2 \
    nodejs \
    npm \
    python3-pip

RUN pip install --upgrade pip
RUN python --version
RUN pip install pipenv
RUN set -ex && pipenv install --system --deploy
RUN jupyter labextension install @jupyter-widgets/jupyterlab-manager

# Clean up
RUN apt-get -qq -y remove curl bzip2 git-core pkg-config\
    && apt-get -qq -y autoremove \
    && apt-get autoclean \
    && rm -rf /var/lib/apt/lists/* /var/log/dpkg.log \

