# Use an official Ubuntu as a parent image
FROM ubuntu:latest

# Set the working directory
WORKDIR /usr/src/app

# Install necessary packages
RUN apt-get update && apt-get install -y \
    bcftools \
    wget \
    unzip \
    && rm -rf /var/lib/apt/lists/*

# Copy the script into the container
COPY reference_pipeline/glimpse/run_glimpse2_reference.sh /usr/src/app/run_glimpse2_reference.sh

# Download and install GLIMPSE2
RUN wget https://github.com/odelaneau/GLIMPSE/releases/download/v2.0.0/GLIMPSE2_v2.0.0.zip \
    && unzip GLIMPSE2_v2.0.0.zip \
    && mv GLIMPSE2_v2.0.0 /usr/src/app/GLIMPSE2 \
    && rm GLIMPSE2_v2.0.0.zip

# Make the script executable
RUN chmod +x /usr/src/app/run_glimpse2_reference.sh

# Set the entry point to the script
ENTRYPOINT ["/usr/src/app/run_glimpse2_reference.sh"]
