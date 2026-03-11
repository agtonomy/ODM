set(_proj_name gdal)
set(_SB_BINARY_DIR "${SB_BINARY_DIR}/${_proj_name}")

# Compute numpy include dir from the venv Python so GDAL's sub-cmake
# does not need to discover it (cmake's FindPython3 NumPy search can
# fail when running in a subprocess without the venv activated).
execute_process(
  COMMAND "${PYTHON_EXE_PATH}" -c "import numpy; print(numpy.get_include())"
  OUTPUT_VARIABLE NUMPY_INCLUDE_DIR
  OUTPUT_STRIP_TRAILING_WHITESPACE
)
message(STATUS "NumPy include dir: ${NUMPY_INCLUDE_DIR}")

ExternalProject_Add(${_proj_name}
  PREFIX            ${_SB_BINARY_DIR}
  TMP_DIR           ${_SB_BINARY_DIR}/tmp
  STAMP_DIR         ${_SB_BINARY_DIR}/stamp
  #--Download step--------------
  DOWNLOAD_DIR      ${SB_DOWNLOAD_DIR}
  GIT_REPOSITORY    https://github.com/OSGeo/gdal.git
  GIT_TAG           cf7cef2f1eec2a80c46b0ec0227d8d0cb32e2657
  #--Update/Patch step----------
  UPDATE_COMMAND    ""
  #--Configure step-------------
  SOURCE_DIR        ${SB_SOURCE_DIR}/${_proj_name}
  CMAKE_ARGS
    -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}
    -DCMAKE_INSTALL_PREFIX:PATH=${SB_INSTALL_DIR}
    -DGDAL_PYTHON_INSTALL_PREFIX=${SB_INSTALL_DIR}
    -DBUILD_PYTHON_BINDINGS=ON
    -DPython3_EXECUTABLE=${PYTHON_EXE_PATH}
    -DPython3_NumPy_INCLUDE_DIRS=${NUMPY_INCLUDE_DIR}
    -D_Python_NumPy_INCLUDE_DIR=${NUMPY_INCLUDE_DIR}
    ${WIN32_CMAKE_ARGS}
  #--Build step-----------------
  BINARY_DIR        ${_SB_BINARY_DIR}
  #--Install step---------------
  INSTALL_DIR       ${SB_INSTALL_DIR}
  INSTALL_COMMAND   "${CMAKE_COMMAND}" --build . --target install
  #--Output logging-------------
  LOG_DOWNLOAD      OFF
  LOG_CONFIGURE     OFF
  LOG_BUILD         OFF
)
