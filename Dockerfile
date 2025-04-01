FROM rocker/shiny:latest

# Install any necessary R packages
RUN R -e "install.packages(c('pak'), repos = 'http://cran.rstudio.com/')"
RUN R -e "pak::pak('nptscot/osmactive', dependencies = 'Suggests')"

# Copy the application files into the container
COPY app/app.R /app/app.R

# Expose port 3838
EXPOSE 3838

# Start the Shiny app
CMD ["R", "-e", "shiny::runApp('/app/app.R', host = '0.0.0.0', port = 3838)"]