#!/bin/sh

if [[ -z "${SDKPATH}" ]]; then
  SDKPATH=$(xcrun -sdk iphoneos --show-sdk-path)
  if [ "$?" -ne 0 ]; then
    echo "No SDKPATH specified and xcrun didn't work!"
  fi
fi
if [[ -z "${MACSDKPATH}" ]]; then
  MACSDKPATH=$(xcrun -sdk macosx --show-sdk-path)
  if [ "$?" -ne 0 ]; then
    echo "No MACSDKPATH specified and xcrun didn't work!"
  fi
fi

if [[ -z "${SDKPATH}" ]]; then
  echo "SDKPATH is undefined!"
  exit 1
fi
if [[ -z "${MACSDKPATH}" ]]; then
  echo "MACSDKPATH is undefined!"
  exit 1
fi
if [[ -z "${BUILD_ROOT}" ]]; then
  BUILD_ROOT="/workspace"
fi

docker run -v $(pwd):/workspace -v ${SDKPATH}:/sdks/target:ro -v ${MACSDKPATH}:/sdks/macosx:ro -e BUILD_ROOT="${BUILD_ROOT}" --rm -it procursus $@
