#!/bin/bash -x

yum install -y curl libcurl libcurl-devel
yum install -y netcdf netcdf-devel gdal
yum install -y netcdf-cxx.x86_64 netcdf-cxx-devel.x86_64 # boost
yum install -y htop
