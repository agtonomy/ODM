set(_SB_BINARY_DIR "${SB_BINARY_DIR}/pypopsift")

# Pypopsift
# find_package(CUDA) uses the legacy FindCUDA module which is removed in
# cmake 3.27+ (CMP0146).  Use CUDAToolkit which is supported from cmake 3.17.
find_package(CUDAToolkit)

if(CUDAToolkit_FOUND)
    ExternalProject_Add(pypopsift
        # Must run after opensfm: OpenSfM's SOURCE_DIR is inside SB_INSTALL_DIR/bin/opensfm
        # and its build step writes files in-place there.  Without this dependency,
        # OpenSfM can run after pypopsift and overwrite/remove pypopsift.so.
        DEPENDS opensfm
        PREFIX            ${_SB_BINARY_DIR}
        TMP_DIR           ${_SB_BINARY_DIR}/tmp
        STAMP_DIR         ${_SB_BINARY_DIR}/stamp
        #--Download step--------------
        DOWNLOAD_DIR      ${SB_DOWNLOAD_DIR}
        GIT_REPOSITORY    https://github.com/OpenDroneMap/pypopsift
        GIT_TAG           fe2d1ccc63877ba315e65f34d2adeadd838b3ac3
        #--Update/Patch step----------
        UPDATE_COMMAND    ""
        #--Configure step-------------
        SOURCE_DIR        ${SB_SOURCE_DIR}/pypopsift
        CMAKE_ARGS
            -DCMAKE_INSTALL_PREFIX=${SB_INSTALL_DIR}
            -DOUTPUT_DIR=${SB_INSTALL_DIR}/bin/opensfm/opensfm
            ${WIN32_CMAKE_ARGS}
            ${ARM64_CMAKE_ARGS}
        #--Build step-----------------
        BINARY_DIR        ${_SB_BINARY_DIR}
        #--Install step---------------
        INSTALL_DIR       ${SB_INSTALL_DIR}
        #--Output logging-------------
        LOG_DOWNLOAD      OFF
        LOG_CONFIGURE     OFF
        LOG_BUILD         OFF
        )
else()
    message(WARNING "CUDAToolkit not found, skipping pypopsift")
endif()
