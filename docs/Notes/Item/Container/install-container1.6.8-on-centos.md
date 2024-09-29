## 一. 前期准备

- System：CentOS7.9.2009 Minimal
- Containerd：cri-containerd-cni-1.6.8-linux-amd64

> CentOS7 默认 libseccomp 版本是 2.3.x，版本不满足最新版的要求

1）卸载旧版本程序

```bash
$ rpm -qa | grep libseccomp

$ rpm -e libseccomp-* --nodeps
```

2）下载高于 2.4 以上的包

```bash
$ wget http://rpmfind.net/linux/centos/8-stream/BaseOS/x86_64/os/Packages/libseccomp-2.5.1-1.el8.x86_64.rpm
$ rpm -ivh libseccomp-2.5.1-1.el8.x86_64.rpm 
$ rpm -qa | grep libseccomp
```

## 二. 安装程序

> `cri-containerd-cni-${VERSION}.${OS}-${ARCH}.tar.gz` 包含 containerd 以及 cri runc 等相关工具包，建议使用此版本

1）根据需要到 [GitHub 官方地址](https://github.com/containerd/containerd) 下载 `tar.gz` 包

```bash
$ wget https://github.com/containerd/containerd/releases/download/v1.6.8/cri-containerd-1.6.8-linux-amd64.tar.gz
```

2）解压并修改环境变量

```bash
$ tar -zxvf cri-containerd-1.6.8-linux-amd64.tar.gz -C /

$ export PATH=$PATH:/usr/local/bin:/usr/local/sbin
$ source ~/.bashrc
```

3）创建 Containerd 配置文件

```bash
$ mkdir -p /etc/containerd 
$ containerd config default > /etc/containerd/config.toml
```

由于 containerd 压缩包中已包含了 `etc/systemd/system/containerd.service` 文件，可直接启动服务

```bash
$ cat /etc/systemd/system/containerd.service
# Copyright The containerd Authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

[Unit]
Description=containerd container runtime
Documentation=https://containerd.io
After=network.target local-fs.target

[Service]
ExecStartPre=-/sbin/modprobe overlay
ExecStart=/usr/local/bin/containerd

Type=notify
Delegate=yes
KillMode=process
Restart=always
RestartSec=5
# Having non-zero Limit*s causes performance problems due to accounting overhead
# in the kernel. We recommend using cgroups to do container-local accounting.
LimitNPROC=infinity
LimitCORE=infinity
LimitNOFILE=infinity
# Comment TasksMax if your systemd version does not supports it.
# Only systemd 226 and above support this version.
TasksMax=infinity
OOMScoreAdjust=-999

[Install]
WantedBy=multi-user.target

$ systemctl enable --now containerd
$ ctr version
```

**服务文件说明**

- `Delegate`：这个选项允许 containerd 以及运行时自己管理自己创建容器的 cgroups。如果不设置这个选项，systemd 就会将进程移到自己的 cgroups 中，从而导致 containerd 无法正确获取容器的资源使用情况
- **认情况下，systemd 会在进程的 cgroup 中查找并杀死 containerd 的所有子进程。**KillMode 字段可以设置的值如下
  - `control-group`（默认值）：当前控制组里面的所有子进程，都会被杀掉
  - `process`：只杀主进程
  - `mixed`：主进程将收到 SIGTERM 信号，子进程收到 SIGKILL 信号
  - `none`：没有进程会被杀掉，只是执行服务的 stop 命令

**注：此处将 KillMode 的值设置为 process，这样可以确保升级或重启 containerd 时不杀死现有的容器**

## 三. 扩展知识

1）查看默认生成的配置文件 `/etc/containerd/config.toml`

```bash
$ cat /etc/containerd/config.toml 
disabled_plugins = []
imports = []
oom_score = 0
plugin_dir = ""
required_plugins = []
root = "/var/lib/containerd"
state = "/run/containerd"
temp = ""
version = 2

[cgroup]
  path = ""

[debug]
  address = ""
  format = ""
  gid = 0
  level = ""
  uid = 0

[grpc]
  address = "/run/containerd/containerd.sock"
  gid = 0
  max_recv_message_size = 16777216
  max_send_message_size = 16777216
  tcp_address = ""
  tcp_tls_ca = ""
  tcp_tls_cert = ""
  tcp_tls_key = ""
  uid = 0

[metrics]
  address = ""
  grpc_histogram = false

[plugins]

  [plugins."io.containerd.gc.v1.scheduler"]
    deletion_threshold = 0
    mutation_threshold = 100
    pause_threshold = 0.02
    schedule_delay = "0s"
    startup_delay = "100ms"

  [plugins."io.containerd.grpc.v1.cri"]
    device_ownership_from_security_context = false
    disable_apparmor = false
    disable_cgroup = false
    disable_hugetlb_controller = true
    disable_proc_mount = false
    disable_tcp_service = true
    enable_selinux = false
    enable_tls_streaming = false
    enable_unprivileged_icmp = false
    enable_unprivileged_ports = false
    ignore_image_defined_volumes = false
    max_concurrent_downloads = 3
    max_container_log_line_size = 16384
    netns_mounts_under_state_dir = false
    restrict_oom_score_adj = false
    sandbox_image = "k8s.gcr.io/pause:3.6"
    selinux_category_range = 1024
    stats_collect_period = 10
    stream_idle_timeout = "4h0m0s"
    stream_server_address = "127.0.0.1"
    stream_server_port = "0"
    systemd_cgroup = false
    tolerate_missing_hugetlb_controller = true
    unset_seccomp_profile = ""

    [plugins."io.containerd.grpc.v1.cri".cni]
      bin_dir = "/opt/cni/bin"
      conf_dir = "/etc/cni/net.d"
      conf_template = ""
      ip_pref = ""
      max_conf_num = 1

    [plugins."io.containerd.grpc.v1.cri".containerd]
      default_runtime_name = "runc"
      disable_snapshot_annotations = true
      discard_unpacked_layers = false
      ignore_rdt_not_enabled_errors = false
      no_pivot = false
      snapshotter = "overlayfs"

      [plugins."io.containerd.grpc.v1.cri".containerd.default_runtime]
        base_runtime_spec = ""
        cni_conf_dir = ""
        cni_max_conf_num = 0
        container_annotations = []
        pod_annotations = []
        privileged_without_host_devices = false
        runtime_engine = ""
        runtime_path = ""
        runtime_root = ""
        runtime_type = ""

        [plugins."io.containerd.grpc.v1.cri".containerd.default_runtime.options]

      [plugins."io.containerd.grpc.v1.cri".containerd.runtimes]

        [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc]
          base_runtime_spec = ""
          cni_conf_dir = ""
          cni_max_conf_num = 0
          container_annotations = []
          pod_annotations = []
          privileged_without_host_devices = false
          runtime_engine = ""
          runtime_path = ""
          runtime_root = ""
          runtime_type = "io.containerd.runc.v2"

          [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc.options]
            BinaryName = ""
            CriuImagePath = ""
            CriuPath = ""
            CriuWorkPath = ""
            IoGid = 0
            IoUid = 0
            NoNewKeyring = false
            NoPivotRoot = false
            Root = ""
            ShimCgroup = ""
            SystemdCgroup = false

      [plugins."io.containerd.grpc.v1.cri".containerd.untrusted_workload_runtime]
        base_runtime_spec = ""
        cni_conf_dir = ""
        cni_max_conf_num = 0
        container_annotations = []
        pod_annotations = []
        privileged_without_host_devices = false
        runtime_engine = ""
        runtime_path = ""
        runtime_root = ""
        runtime_type = ""

        [plugins."io.containerd.grpc.v1.cri".containerd.untrusted_workload_runtime.options]

    [plugins."io.containerd.grpc.v1.cri".image_decryption]
      key_model = "node"

    [plugins."io.containerd.grpc.v1.cri".registry]
      config_path = ""

      [plugins."io.containerd.grpc.v1.cri".registry.auths]

      [plugins."io.containerd.grpc.v1.cri".registry.configs]

      [plugins."io.containerd.grpc.v1.cri".registry.headers]

      [plugins."io.containerd.grpc.v1.cri".registry.mirrors]

    [plugins."io.containerd.grpc.v1.cri".x509_key_pair_streaming]
      tls_cert_file = ""
      tls_key_file = ""

  [plugins."io.containerd.internal.v1.opt"]
    path = "/opt/containerd"

  [plugins."io.containerd.internal.v1.restart"]
    interval = "10s"

  [plugins."io.containerd.internal.v1.tracing"]
    sampling_ratio = 1.0
    service_name = "containerd"

  [plugins."io.containerd.metadata.v1.bolt"]
    content_sharing_policy = "shared"

  [plugins."io.containerd.monitor.v1.cgroups"]
    no_prometheus = false

  [plugins."io.containerd.runtime.v1.linux"]
    no_shim = false
    runtime = "runc"
    runtime_root = ""
    shim = "containerd-shim"
    shim_debug = false

  [plugins."io.containerd.runtime.v2.task"]
    platforms = ["linux/amd64"]
    sched_core = false

  [plugins."io.containerd.service.v1.diff-service"]
    default = ["walking"]

  [plugins."io.containerd.service.v1.tasks-service"]
    rdt_config_file = ""

  [plugins."io.containerd.snapshotter.v1.aufs"]
    root_path = ""

  [plugins."io.containerd.snapshotter.v1.btrfs"]
    root_path = ""

  [plugins."io.containerd.snapshotter.v1.devmapper"]
    async_remove = false
    base_image_size = ""
    discard_blocks = false
    fs_options = ""
    fs_type = ""
    pool_name = ""
    root_path = ""

  [plugins."io.containerd.snapshotter.v1.native"]
    root_path = ""

  [plugins."io.containerd.snapshotter.v1.overlayfs"]
    root_path = ""
    upperdir_label = false

  [plugins."io.containerd.snapshotter.v1.zfs"]
    root_path = ""

  [plugins."io.containerd.tracing.processor.v1.otlp"]
    endpoint = ""
    insecure = false
    protocol = ""

[proxy_plugins]

[stream_processors]

  [stream_processors."io.containerd.ocicrypt.decoder.v1.tar"]
    accepts = ["application/vnd.oci.image.layer.v1.tar+encrypted"]
    args = ["--decryption-keys-path", "/etc/containerd/ocicrypt/keys"]
    env = ["OCICRYPT_KEYPROVIDER_CONFIG=/etc/containerd/ocicrypt/ocicrypt_keyprovider.conf"]
    path = "ctd-decoder"
    returns = "application/vnd.oci.image.layer.v1.tar"

  [stream_processors."io.containerd.ocicrypt.decoder.v1.tar.gzip"]
    accepts = ["application/vnd.oci.image.layer.v1.tar+gzip+encrypted"]
    args = ["--decryption-keys-path", "/etc/containerd/ocicrypt/keys"]
    env = ["OCICRYPT_KEYPROVIDER_CONFIG=/etc/containerd/ocicrypt/ocicrypt_keyprovider.conf"]
    path = "ctd-decoder"
    returns = "application/vnd.oci.image.layer.v1.tar+gzip"

[timeouts]
  "io.containerd.timeout.bolt.open" = "0s"
  "io.containerd.timeout.shim.cleanup" = "5s"
  "io.containerd.timeout.shim.load" = "5s"
  "io.containerd.timeout.shim.shutdown" = "3s"
  "io.containerd.timeout.task.state" = "2s"

[ttrpc]
  address = ""
  gid = 0
  uid = 0
```

2）配置文件内容比较多，其中每一个配置块命名都是 `plugins."io.containerd.xxx.vx.xxx"` 形式，都表示一个插件，其中 `io.containerd.xxx.vx` 表示插件的类型，`vx` 后面的 `xxx` 表示插件的 ID，我们可以通过 `ctr` 查看插件列表

```bash
$ ctr plugin ls
TYPE                                  ID                       PLATFORMS      STATUS    
io.containerd.content.v1              content                  -              ok        
io.containerd.snapshotter.v1          aufs                     linux/amd64    skip      
io.containerd.snapshotter.v1          btrfs                    linux/amd64    skip      
io.containerd.snapshotter.v1          devmapper                linux/amd64    error     
io.containerd.snapshotter.v1          native                   linux/amd64    ok        
io.containerd.snapshotter.v1          overlayfs                linux/amd64    ok        
io.containerd.snapshotter.v1          zfs                      linux/amd64    skip      
io.containerd.metadata.v1             bolt                     -              ok        
io.containerd.differ.v1               walking                  linux/amd64    ok        
io.containerd.event.v1                exchange                 -              ok        
io.containerd.gc.v1                   scheduler                -              ok        
io.containerd.service.v1              introspection-service    -              ok        
io.containerd.service.v1              containers-service       -              ok        
io.containerd.service.v1              content-service          -              ok        
io.containerd.service.v1              diff-service             -              ok        
io.containerd.service.v1              images-service           -              ok        
io.containerd.service.v1              leases-service           -              ok        
io.containerd.service.v1              namespaces-service       -              ok        
io.containerd.service.v1              snapshots-service        -              ok        
io.containerd.runtime.v1              linux                    linux/amd64    ok        
io.containerd.runtime.v2              task                     linux/amd64    ok        
io.containerd.monitor.v1              cgroups                  linux/amd64    ok        
io.containerd.service.v1              tasks-service            -              ok        
io.containerd.grpc.v1                 introspection            -              ok        
io.containerd.internal.v1             restart                  -              ok        
io.containerd.grpc.v1                 containers               -              ok        
io.containerd.grpc.v1                 content                  -              ok        
io.containerd.grpc.v1                 diff                     -              ok        
io.containerd.grpc.v1                 events                   -              ok        
io.containerd.grpc.v1                 healthcheck              -              ok        
io.containerd.grpc.v1                 images                   -              ok        
io.containerd.grpc.v1                 leases                   -              ok        
io.containerd.grpc.v1                 namespaces               -              ok        
io.containerd.internal.v1             opt                      -              ok        
io.containerd.grpc.v1                 snapshots                -              ok        
io.containerd.grpc.v1                 tasks                    -              ok        
io.containerd.grpc.v1                 version                  -              ok        
io.containerd.tracing.processor.v1    otlp                     -              skip      
io.containerd.internal.v1             tracing                  -              ok        
io.containerd.grpc.v1                 cri                      linux/amd64    ok        
```

3）顶级配置块下面的子配置块表示该插件的各种配置，比如 cri 插件下面就分为 containerd、cni 和 registry 的配置，而 containerd 下面又可以配置各种 runtime，还可以配置默认的 runtime

比如现要为镜像配置一个加速器，那么就需要在 cri 配置块下面的 `registry` 配置块下面进行配置 `registry.mirrors`

```bash
$ cat /etc/containerd/config.toml | grep -i plugins.*.registry 
    [plugins."io.containerd.grpc.v1.cri".registry]
      [plugins."io.containerd.grpc.v1.cri".registry.auths]
      [plugins."io.containerd.grpc.v1.cri".registry.configs]
      [plugins."io.containerd.grpc.v1.cri".registry.headers]
      [plugins."io.containerd.grpc.v1.cri".registry.mirrors]
```

配置镜像加速，配置完成后需要重启服务

```bash
$ cat /etc/containerd/config.toml | grep -i registry.mirrors -A 1
      [plugins."io.containerd.grpc.v1.cri".registry.mirrors]
        [plugins."io.containerd.grpc.v1.cri".registry.mirrors."docker.io"]
          endpoint = ["https://eihzr0te.mirror.aliyuncs.com"]
        [plugins."io.containerd.grpc.v1.cri".registry.mirrors."k8s.gcr.io"]
          endpoint = ["https://registry.cn-hongkong.aliyuncs.com/yuikuen/"]     
        [plugins."io.containerd.grpc.v1.cri".registry.mirrors."quay.io"]
          endpoint = ["https://registry.cn-hongkong.aliyuncs.com"]     
```

- `registry.mirrors."xxx"`: 表示需要配置 mirror 的镜像仓库，例如 `registry.mirrors."docker.io"` 表示配置 docker.io 的 mirror
- `endpoint`: 表示提供 mirror 的镜像加速服务，比如我们可以注册一个阿里云的镜像服务来作为 docker.io 的 mirror

4）默认配置中还有两个关于存储的配置路径

```bash
root = "/var/lib/containerd"
state = "/run/containerd"
```

- `root` 是用来保存持久化数据，**包括 Snapshots, Content, Metadata 以及各种插件的数据**，每一个插件都有自己单独的目录，Containerd 本身不存储任何数据，它的所有功能都来自于已加载的插件
- `state` 是用来保存运行时的临时数据的，包括 sockets、pid、挂载点、运行时状态以及不需要持久化的插件数据
