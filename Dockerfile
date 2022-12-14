# base image
FROM ubuntu:22.04

ENV RUNNER_VERSION="2.299.1"
ENV DEBIAN_FRONTEND=noninteractive

# update the base packages + add a non-sudo user
RUN apt-get update -y && apt-get upgrade -y && useradd -m runner

# install packages and dependencies needed
RUN apt-get install -y --no-install-recommends npm git curl jq

# cd into the user directory, download and unzip the github actions runner
RUN cd /home/runner && mkdir actions-runner && cd actions-runner \
    && curl -O -L https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz \
    && tar xzf ./actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz

# remove folders/files that is not needed in the end image to decrease the docker image size
RUN rm -rf /home/runner/actions-runner/externals/node16_alpine \
    && rm -rf /home/runner/actions-runner/externals/node12_alpine \
    && rm -rf /home/runner/actions-runner/actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz

# copy node16 folders over to usr/local
RUN cp -R /home/runner/actions-runner/externals/node16/bin/* usr/local/bin
RUN cp -R /home/runner/actions-runner/externals/node16/lib/* usr/local/lib
RUN cp -R /home/runner/actions-runner/externals/node16/share/* usr/local/share
RUN cp -R /home/runner/actions-runner/externals/node16/include/* usr/local/include

# install some additional dependencies needed by the actions runner
RUN chown -R runner ~runner && /home/runner/actions-runner/bin/installdependencies.sh

# add over the start.sh script
ADD scripts/start.sh .

# make the script executable
RUN chmod +x start.sh

# set the user to "runner" so all subsequent commands are run as the runner user
USER runner

# set the entrypoint to the start.sh script
ENTRYPOINT ["./start.sh"]