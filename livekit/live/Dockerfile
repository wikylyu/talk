FROM ubuntu:23.10

SHELL ["/bin/bash","-c"]

RUN apt-get update
RUN apt-get install -y curl

WORKDIR /app
COPY config.yaml .
COPY livekit.sh .
RUN bash livekit.sh


CMD ["livekit-server", "--bind","0.0.0.0", "--config","./config.yaml"]
