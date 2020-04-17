FROM python:3.8.2-slim-buster

# Adds metadata to the image as a key value pair example LABEL version="1.0"
LABEL maintainer="Ignacio Grosso"

# Set environment variables
ENV LANG=C.UTF-8 LC_ALL=C.UTF-8 PATH=/opt/conda/bin:$PATH

# Set up WorkDirs
RUN mkdir /root/libpostaldata && mkdir /root/GitProjects && mkdir /root/installfiles
WORKDIR /root/

# Copy requirements.txt
COPY ./requirements.txt /root

# Install Debian packages
RUN apt-get -qq update && apt-get -qq -y install apt-utils autoconf automake make libtool python-dev curl git-core ca-certificates pkg-config tree bzip2

# Install miniconda
RUN curl -sSL https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh -o /tmp/miniconda.sh \
    && bash /tmp/miniconda.sh -bfp /usr/local \
    && conda install -y python=3.8 \
    && conda update conda

# Install libpostal
RUN mkdir ~/.ssh && touch ~/.ssh/known_hosts  \
    && ssh-keygen -F github.com || ssh-keyscan github.com >> ~/.ssh/known_hosts
RUN git clone https://github.com/openvenues/libpostal
RUN cd /root/libpostal && ./bootstrap.sh && ./configure --datadir=/root/libpostaldata && make -j4 && make install

# Install requirements.txt
RUN pip install -r /root/requirements.txt
RUN jt -t grade3

# Install Jupyter config
RUN git clone https://github.com/bobbywlindsey/dotfiles.git \
#    && mkdir ~/.jupyter \
#    && mkdir -p ~/.jupyter/custom \
    && mkdir -p ~/.jupyter/nbconfig \
    && cp ~/dotfiles/jupyter/jupyter_notebook_config.py ~/.jupyter/ \
    && cp ~/dotfiles/jupyter/custom/custom.js ~/.jupyter/custom/ \
    && cp ~/dotfiles/jupyter/nbconfig/notebook.json ~/.jupyter/nbconfig/ \
    && rm -rf ~/dotfiles

# Enable Jupyter Notebook extensions
RUN jupyter contrib nbextension install --user \
    && jupyter nbextensions_configurator enable --user \
    && jupyter nbextension enable codefolding/main \
    && jupyter nbextension enable collapsible_headings/main

# Add vim-binding extension
RUN mkdir -p $(jupyter --data-dir)/nbextensions \
    && git clone https://github.com/lambdalisue/jupyter-vim-binding $(jupyter --data-dir)/nbextensions/vim_binding \
    && cd $(jupyter --data-dir)/nbextensions \
    && chmod -R go-w vim_binding

# Clean up
RUN apt-get -qq -y remove curl bzip2 git-core pkg-config\
    && apt-get -qq -y autoremove \
    && apt-get autoclean \
    && rm -rf /tmp/miniconda.sh \
    && rm -rf /var/lib/apt/lists/* /var/log/dpkg.log \
    && conda clean --all --yes
