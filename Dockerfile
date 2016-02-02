# Use tomcat:8.0 image as base for RELATED OpenCloudLabs
FROM related/tomcat:latest

MAINTAINER Rafael Pastor Vargas

# Directory with the assests from OCL (OpenCloudLabs)
WORKDIR /related_ocl

# Define the volume
VOLUME /related_ocl

# Copy the war app to Tomcat/webapps
COPY ocl_war/*.war /usr/local/tomcat/webapps/

# Create template directory
RUN mkdir /ocl_assests_template

# Copy ocl_assets to template dir
ADD ./ocl_assests/ /ocl_assests_template

# Create the scripts directory
RUN mkdir /scripts

# Copy the scripts directory
COPY ./scripts/* /scripts

# Start App
# CMD ["/scripts/start_app.sh"]
ENTRYPOINT exec /scripts/start_app.sh
