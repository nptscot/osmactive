FROM ghcr.io/geocompx/latest@sha256:00ff6dd552f2e9168488dee6ee1babb4b6bee805f0a2d35aff548d6ee2730625

# Set the working directory
WORKDIR /app

# Copy the current directory contents into the container
COPY . /app

# Install the osmactive package
RUN R -e 'remotes::install_local(dependencies = TRUE)'  && \
    R -e 'library(osmactive)'
