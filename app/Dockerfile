FROM rocker/geospatial:latest

RUN /rocker_scripts/setup_R.sh https://packagemanager.posit.co/cran/__linux__/jammy/2023-01-29
RUN /rocker_scripts/install_shiny_server.sh

# Install any necessary R packages
RUN R -e "install.packages(c('remotes'))"
RUN R -e "install.packages(c('cols4all', 'geos', 'osmextract'))"
RUN R -e "install.packages(c('shiny'))"
RUN R -e "remotes::install_github('nptscot/osmactive', dependencies = 'Suggests', ask = FALSE, Ncpus = parallel::detectCores())"
# RUN R -e "remotes::install_github('r-tmap/tmap')"

# Copy the application files into the container
COPY app.R /app/app.R

# Expose port 3838
EXPOSE 3838

# Start the Shiny app
CMD ["R", "-e", "shiny::runApp('/app/app.R', host = '0.0.0.0', port = 3838)"]