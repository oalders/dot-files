FROM ubuntu:20.04

# Install man so that we get "manpath"
RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates git man sudo
