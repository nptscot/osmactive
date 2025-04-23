FROM ghcr.io/geocompx/latest

# Set the working directory
WORKDIR /app

# Copy the current directory contents into the container
COPY . /app

# Install the osmactive package
RUN R -e 'remotes::install_local(".")'
