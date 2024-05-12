class Ghc < Formula
  desc "Glorious Glasgow Haskell Compilation System"
  homepage "https://haskell.org/ghc/"
  url "https://downloads.haskell.org/~ghc/9.10.1/ghc-9.10.1-src.tar.xz"
  sha256 "bf386a302d4ee054791ffd51748900f15d71760fd199157922d120cc1f89e2f7"
  # We build bundled copies of libffi and GMP so GHC inherits the licenses
  license all_of: [
    "BSD-3-Clause",
    "MIT", # libffi
    any_of: ["LGPL-3.0-or-later", "GPL-2.0-or-later"], # GMP
  ]
  head "https://gitlab.haskell.org/ghc/ghc.git", branch: "master"

  livecheck do
    url "https://www.haskell.org/ghc/download.html"
    regex(/href=.*?download[._-]ghc[._-][^"' >]+?\.html[^>]*?>\s*?v?(\d+(?:\.\d+)+)\s*?</i)
  end

  bottle do
    sha256 cellar: :any,                 arm64_sonoma:   "3f307c1dd3a7f6978f61559e50e5ed8a5f80aa9b6c177bc6fc380e8a7750e67b"
    sha256 cellar: :any,                 arm64_ventura:  "a5866a3dd17f1625dd6c5614bf4009b9b9fa3f250de20c9b1537bcb4243c5a07"
    sha256 cellar: :any,                 arm64_monterey: "c232ee8df13d646fb1620366fb619a578c9c8d78226a1aa53911a68f417f6a38"
    sha256 cellar: :any,                 sonoma:         "fc0419aa104bf0ceade5a88e43197b5772471111d56ac72c5bab170d16297700"
    sha256 cellar: :any,                 ventura:        "85d49206c4493c98aed170ed714b8cdbca8422941cd866ecb8382bd1ffbc136a"
    sha256 cellar: :any,                 monterey:       "5da681c7ed9784fa0b272fddfa5e4386292819cd10fcbe3d4d3240b4bffc047c"
    sha256 cellar: :any_skip_relocation, x86_64_linux:   "45126aef7e10a910368e2ef37bb37795c9951a3551fd91d414a7e452498deac9"
  end

  depends_on "autoconf" => :build
  depends_on "automake" => :build
  depends_on "python@3.12" => :build
  depends_on "sphinx-doc" => :build
  depends_on "xz" => :build

  uses_from_macos "m4" => :build
  uses_from_macos "ncurses"

  # Build uses sed -r option, which is not available in Catalina shipped sed.
  on_catalina :or_older do
    depends_on "gnu-sed" => :build
  end

  on_linux do
    depends_on "gmp" => :build
  end

  # A binary of ghc is needed to bootstrap ghc
  resource "binary" do
    on_macos do
      on_arm do
        url "https://downloads.haskell.org/~ghc/9.8.2/ghc-9.8.2-aarch64-apple-darwin.tar.xz"
        sha256 "67be089dedbe599d911efd8f82e4f9a19225761a3872be74dfd4b5a557fb8e1a"
      end
      on_intel do
        url "https://downloads.haskell.org/~ghc/9.8.2/ghc-9.8.2-x86_64-apple-darwin.tar.xz"
        sha256 "64e8cca6310443cd6de8255edcf391d937829792e701167f7e5fb234f7150078"
      end
    end
    on_linux do
      on_arm do
        url "https://downloads.haskell.org/~ghc/9.8.2/ghc-9.8.2-aarch64-deb11-linux.tar.xz"
        sha256 "b7f27d53cf20645833bcff2fa6308b221c39eeac1de3fe074598090731848672"
      end
      on_intel do
        url "https://downloads.haskell.org/~ghc/9.8.2/ghc-9.8.2-x86_64-ubuntu20_04-linux.tar.xz"
        sha256 "a65a4726203c606b58a7f6b714a576e7d81390158c8afa0dece3841a4c602de2"
      end
    end
  end

  resource "cabal-install" do
    on_macos do
      on_arm do
        url "https://downloads.haskell.org/~cabal/cabal-install-3.10.3.0/cabal-install-3.10.3.0-aarch64-darwin.tar.xz"
        sha256 "f4f606b1488a4b24c238f7e09619959eed89c550ed8f8478b350643f652dc08c"
      end
      on_intel do
        url "https://downloads.haskell.org/~cabal/cabal-install-3.10.3.0/cabal-install-3.10.3.0-x86_64-darwin.tar.xz"
        sha256 "3aed78619b2164dd61eb61afb024073ae2c50f6655fa60fcc1080980693e3220"
      end
    end
    on_linux do
      on_arm do
        url "https://downloads.haskell.org/~cabal/cabal-install-3.10.3.0/cabal-install-3.10.3.0-aarch64-linux-deb11.tar.xz"
        sha256 "e0b6604d3596c5e5b7236e79ff4f5aa8af337792bf69ac4a90634c761f1b9ed5"
      end
      on_intel do
        url "https://downloads.haskell.org/~cabal/cabal-install-3.10.3.0/cabal-install-3.10.3.0-x86_64-linux-ubuntu20_04.tar.xz"
        sha256 "b7ccb975bacf8b6a7d6b5dde8a7712787473a149c3dc0ebb2de7fbd00f964844"
      end
    end
  end

  def install
    ENV["CC"] = ENV.cc
    ENV["LD"] = "ld"
    ENV["PYTHON"] = which("python3.12")
    # Work around `ENV["CC"]` no longer being used unless set to absolute path.
    # Caused by https://gitlab.haskell.org/ghc/ghc/-/commit/6be2c5a7e9187fc14d51e1ec32ca235143bb0d8b
    # Issue ref: https://gitlab.haskell.org/ghc/ghc/-/issues/22175
    # TODO: remove once upstream issue is fixed
    ENV["ac_cv_path_CC"] = ENV.cc

    binary = buildpath/"binary"
    resource("binary").stage do
      binary_args = []
      if OS.linux?
        binary_args << "--with-gmp-includes=#{Formula["gmp"].opt_include}"
        binary_args << "--with-gmp-libraries=#{Formula["gmp"].opt_lib}"
      end

      system "./configure", "--prefix=#{binary}", *binary_args
      ENV.deparallelize { system "make", "install" }

      ENV.prepend_path "PATH", binary/"bin"
      # Build uses sed -r option, which is not available in Catalina shipped sed.
      ENV.prepend_path "PATH", Formula["gnu-sed"].libexec/"gnubin" if OS.mac? && MacOS.version <= :catalina
    end

    resource("cabal-install").stage { (binary/"bin").install "cabal" }
    system "cabal", "v2-update"
    if build.head?
      cabal_args = std_cabal_v2_args.reject { |s| s["installdir"] }
      system "cabal", "v2-install", "alex", "happy", *cabal_args, "--installdir=#{binary}/bin"
      system "./boot"
    end

    args = []
    if OS.mac?
      # https://gitlab.haskell.org/ghc/ghc/-/issues/22595#note_468423
      args << "--with-ffi-libraries=#{MacOS.sdk_path_if_needed}/usr/lib"
      args << "--with-ffi-includes=#{MacOS.sdk_path_if_needed}/usr/include/ffi"
      args << "--with-system-libffi"
    end

    system "./configure", "--prefix=#{prefix}", "--disable-numa", "--with-intree-gmp", *args
    hadrian_args = %W[
      -j#{ENV.make_jobs}
      --prefix=#{prefix}
      --flavour=release
      --docs=no-sphinx-pdfs
    ]
    # Work around linkage error due to RPATH in ghc-iserv-dyn-ghc
    # Issue ref: https://gitlab.haskell.org/ghc/ghc/-/issues/22557
    unless build.head?
      os = OS.mac? ? "osx" : OS.kernel_name.downcase
      cpu = Hardware::CPU.arm? ? "aarch64" : Hardware::CPU.arch.to_s
      extra_rpath = rpath(source: lib/"ghc-#{version}/bin",
                          target: lib/"ghc-#{version}/lib/#{cpu}-#{os}-ghc-#{version}")
      hadrian_args << "*.iserv.ghc.link.opts += -optl-Wl,-rpath,#{extra_rpath}"
    end
    # Let hadrian handle its own parallelization
    ENV.deparallelize { system "hadrian/build", "install", *hadrian_args }

    bash_completion.install "utils/completion/ghc.bash" => "ghc"
    ghc_libdir = build.head? ? lib.glob("ghc-*").first : lib/"ghc-#{version}"
    (ghc_libdir/"lib/package.conf.d/package.cache").unlink
    (ghc_libdir/"lib/package.conf.d/package.cache.lock").unlink
  end

  def post_install
    system "#{bin}/ghc-pkg", "recache"
  end

  test do
    (testpath/"hello.hs").write('main = putStrLn "Hello Homebrew"')
    assert_match "Hello Homebrew", shell_output("#{bin}/runghc hello.hs")
  end
end
