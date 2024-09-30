> CentOS7 安装 FFmpeg 视频解码器

## 一. 编译安装

1）安装依赖环境

```bash
$ yum install gcc yasm
```

2）下载 [FFmpeg](https://johnvansickle.com/ffmpeg/release-source/) 程序包

```bash
$ wget https://johnvansickle.com/ffmpeg/release-source/ffmpeg-4.1.tar.xz
$ tar -xf ffmpeg-4.1.tar.xz && cd ./ffmpeg-4.1
```

3）编译安装

```bash
$ ./configure --enable-shared --prefix=/usr/local/ffmpeg
$ make &&　make install
```

```bash
$ vim /etc/ld.so.conf
/usr/local/ffmpeg/lib/
$ ldconfig
```

4）配置环境变量

```bash
$ vim /etc/profile
PATH=$PATH:/usr/local/ffmpeg/bin
export PATH
$ source /etc/profile
$ ffmpeg -version
```

## 二. 二进制安装

```bash
$ wget https://johnvansickle.com/ffmpeg/builds/ffmpeg-git-amd64-static.tar.xz
$ tar -xf ffmpeg-git-amd64-static.tar.xz && cd ./ffmpeg-git-20220108-amd64-static
$ mv ffmpeg ffprobe /usr/bin/
$ ffprobe -version
ffprobe version N-60236-gffb000fff8-static https://johnvansickle.com/ffmpeg/  Copyright (c) 2007-2022 the FFmpeg developers
built with gcc 8 (Debian 8.3.0-6)
configuration: --enable-gpl --enable-version3 --enable-static --disable-debug --disable-ffplay --disable-indev=sndio --disable-outdev=sndio --cc=gcc --enable-fontconfig --enable-frei0r --enable-gnutls --enable-gmp --enable-libgme --enable-gray --enable-libaom --enable-libfribidi --enable-libass --enable-libvmaf --enable-libfreetype --enable-libmp3lame --enable-libopencore-amrnb --enable-libopencore-amrwb --enable-libopenjpeg --enable-librubberband --enable-libsoxr --enable-libspeex --enable-libsrt --enable-libvorbis --enable-libopus --enable-libtheora --enable-libvidstab --enable-libvo-amrwbenc --enable-libvpx --enable-libwebp --enable-libx264 --enable-libx265 --enable-libxml2 --enable-libdav1d --enable-libxvid --enable-libzvbi --enable-libzimg
libavutil      57. 18.100 / 57. 18.100
libavcodec     59. 20.100 / 59. 20.100
libavformat    59. 17.100 / 59. 17.100
libavdevice    59.  5.100 / 59.  5.100
libavfilter     8. 25.100 /  8. 25.100
libswscale      6.  5.100 /  6.  5.100
libswresample   4.  4.100 /  4.  4.100
libpostproc    56.  4.100 / 56.  4.100
```