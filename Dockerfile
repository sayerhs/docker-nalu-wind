FROM exawind/exw-tioga AS tioga
FROM exawind/exw-openfast AS openfast
FROM exawind/exw-trilinos as trilinos

FROM exawind/exw-dev-deps as base

COPY --from=tioga /opt/exawind /opt/exawind
COPY --from=openfast /opt/exawind /opt/exawind
COPY --from=trilinos /opt/exawind /opt/exawind

ARG ENABLE_OPENMP=OFF
ARG ENABLE_CUDA=OFF

RUN (\
    git clone --depth 1 https://github.com/exawind/nalu-wind.git \
    && cd nalu-wind \
    && cmake \
       -Bbuild \
       -DCMAKE_PREFIX_PATH=/opt/exawind \
       -DCMAKE_INSTALL_PREFIX=/opt/exawind \
       -DCMAKE_BUILD_TYPE=RELEASE \
       -DBUILD_SHARED_LIBS=ON \
       -DENABLE_OPENMP=${ENABLE_OPENMP} \
       -DENABLE_CUDA=${ENABLE_CUDA} \
       -DENABLE_HYPRE=ON -DENABLE_TIOGA=ON -DENABLE_OPENFAST=ON \
       -G Ninja . \
    && cd build \
    && ninja -j$(nproc) \
    && ninja install \
    && cd ../.. \
    && rm -rf nalu-wind \
    && cd /opt/exawind/lib \
    && ls *so* | xargs strip -s \
    && echo "/opt/exawind/lib" > /etc/ld.so.conf.d/exawind.conf \
    && ldconfig \
    )

FROM exawind/exw-osrun as runner

COPY --from=base /usr/local /usr/local
COPY --from=base /opt/exawind /opt/exawind

RUN (\
    echo "/opt/exawind/lib" > /etc/ld.so.conf.d/exawind.conf \
    && ldconfig \
    )

ENV PATH /opt/exawind/bin:${PATH}
