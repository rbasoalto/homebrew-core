class Netdata < Formula
  desc "Diagnose infrastructure problems with metrics, visualizations & alarms"
  homepage "https://netdata.cloud/"
  url "https://github.com/netdata/netdata/releases/download/v1.45.5/netdata-v1.45.5.tar.gz"
  sha256 "8b2f24df06f4e90aa448d25348e0301a5c710f86e3e830f2ec6e8d74d766b0b1"
  license "GPL-3.0-or-later"

  livecheck do
    url :stable
    regex(/^v?(\d+(?:\.\d+)+)$/i)
  end

  bottle do
    sha256 arm64_sonoma:   "d3eba2c021fd04c673c5006613e8f83a4f2349dfde9a126c793a8a9a4a331375"
    sha256 arm64_ventura:  "639b287a0d0adf3a1ac48d9ffdc90842c488e285de1c1ac67aa4938516d7fba1"
    sha256 arm64_monterey: "d02335d1afe69d3f182f4fe9dfa49ca3b28f74880d703f50cf77afa865fa41e2"
    sha256 sonoma:         "a70a6541ab4b1e2f64ed051e404f59d87ccfb021783e6a09dfde8c19dfa957ec"
    sha256 ventura:        "59560f5fdeedcc125fd93009cf2e9292f3b1fc1894d9eb89591990078265986a"
    sha256 monterey:       "83ece0fc0f2daf9ffb04af4f6bad716b731683b51d93705901a7a1862306237c"
    sha256 x86_64_linux:   "3dc87fda17794790d40e215bba8edfcda09eb61eff88e84d3c01939cf2005d46"
  end

  depends_on "autoconf" => :build
  depends_on "automake" => :build
  depends_on "cmake" => :build
  depends_on "go" => :build
  depends_on "m4" => :build
  depends_on "pkg-config" => :build
  depends_on "json-c"
  depends_on "libuv"
  depends_on "libyaml"
  depends_on "lz4"
  depends_on "openssl@3"
  depends_on "pcre2"
  depends_on "protobuf"
  depends_on "protobuf-c"
  depends_on "snappy"

  uses_from_macos "zlib"

  on_linux do
    depends_on "systemd"
    depends_on "util-linux"
  end

  def install
    args = %w[
      -DBUILD_FOR_PACKAGING=TRUE
      -DENABLE_PLUGIN_EBPF=FALSE
      -DENABLE_PLUGIN_FREEIPMI=FALSE
      -DENABLE_PLUGIN_NFACCT=FALSE
      -DENABLE_PLUGIN_XENSTAT=FALSE
      -DENABLE_PLUGIN_LOGS_MANAGEMENT=FALSE
    ]

    if OS.mac?
      args += %w[
        -DENABLE_PLUGIN_PERF=FALSE
        -DENABLE_PLUGIN_APPS=FALSE
        -DENABLE_PLUGIN_CGROUP_NETWORK=FALSE
        -DENABLE_PLUGIN_NETWORK_VIEWER=FALSE
        -DENABLE_PLUGIN_LOCAL_LISTENERS=FALSE
        -DENABLE_PLUGIN_SYSTEMD_JOURNAL=FALSE
      ]
    end

    system "cmake", "-S", ".", "-B", "build", *args, *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
  end

  def post_install
    (var/"cache/netdata/unittest-dbengine/dbengine").mkpath
    (var/"lib/netdata/registry").mkpath
    (var/"lib/netdata/lock").mkpath
    (var/"log/netdata").mkpath
    (var/"netdata").mkpath
  end

  service do
    run [opt_sbin/"netdata", "-D"]
    working_dir var
  end

  test do
    system sbin/"netdata", "-W", "set", "registry", "netdata unique id file",
                              testpath/"netdata.unittest.unique.id",
                              "-W", "set", "registry", "netdata management api key file",
                              testpath/"netdata.api.key"
  end
end
