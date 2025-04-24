FROM ghcr.io/geocompx/latest

# Set the working directory
WORKDIR .

# Copy the current directory contents into the container
COPY . .

# Install the osmactive package
RUN R -e 'remotes::install_local(".")'
