FROM nvidia/cuda:12.9.1-devel-ubuntu24.04 AS builder

# Env variables
ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONPATH="$PYTHONPATH:/code/SuperBuild/install/local/lib/python3.12/dist-packages:/code/SuperBuild/install/lib/python3.12/dist-packages:/code/SuperBuild/install/bin/opensfm" \
    LD_LIBRARY_PATH="$LD_LIBRARY_PATH:/code/SuperBuild/install/lib" \
    CC="ccache gcc" \
    CXX="ccache g++" \
    CCACHE_DIR=/ccache

# Prepare directories
WORKDIR /code

RUN apt-get update && \
    apt-get install -y --no-install-recommends ccache && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Copy build prerequisites first for better layer caching
COPY snap/ ./snap/
COPY configure.sh ./
COPY requirements.txt ./
COPY docker/ ./docker/

# Install system dependencies
RUN PORTABLE_INSTALL=YES GPU_INSTALL=YES bash configure.sh installreqs

COPY SuperBuild/ ./SuperBuild/

# Compile SuperBuild with ccache
RUN --mount=type=cache,target=/ccache \
    PORTABLE_INSTALL=YES GPU_INSTALL=YES bash configure.sh install

# Copy remaining source
COPY . ./

# Run the tests
ENV PATH="/code/venv/bin:$PATH"
RUN bash test.sh

# Clean Superbuild
RUN bash configure.sh clean

### END Builder

### Use a second image for the final asset to reduce the number and
# size of the layers.
FROM nvidia/cuda:12.9.1-runtime-ubuntu24.04

# Env variables
ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONPATH="$PYTHONPATH:/code/SuperBuild/install/local/lib/python3.12/dist-packages:/code/SuperBuild/install/lib/python3.12/dist-packages:/code/SuperBuild/install/bin/opensfm" \
    LD_LIBRARY_PATH="$LD_LIBRARY_PATH:/code/SuperBuild/install/lib" \
    PDAL_DRIVER_PATH="/code/SuperBuild/install/bin"

WORKDIR /code

# Copy everything we built from the builder
COPY --from=builder /code /code

ENV PATH="/code/venv/bin:$PATH"

RUN apt-get update -y \
 && apt-get install -y ffmpeg libtbbmalloc2
# Install shared libraries that we depend on via APT, but *not*
# the -dev packages to save space!
# Also run a smoke test on ODM and OpenSfM
RUN bash configure.sh installruntimedepsonly \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
  && bash run.sh --help \
  && bash -c "eval $(python3 /code/opendm/context.py) && python3 -c 'from opensfm import io, pymap'"

# Entry point
ENTRYPOINT ["python3", "/code/run.py"]
