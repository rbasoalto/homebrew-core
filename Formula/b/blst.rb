class Blst < Formula
  desc "Multilingual BLS12-381 signature library"
  homepage "https://github.com/supranational/blst"
  url "https://github.com/supranational/blst/archive/refs/tags/v0.3.11.tar.gz"
  sha256 "d0a6e2a69490cc45f0a531a684a225e56fe22303665157cfa397ba5605447eb9"
  license "Apache-2.0"

  def install
    system "./build.sh", "shared"
    lib.install "libblst.a"
    (include/"blst").install [
      "bindings/blst.h",
      "bindings/blst.hpp",
      "bindings/blst_aux.h",
    ]
  end

  test do
    (testpath/"test.c").write <<~EOS
      #include <blst/blst.h>
      #include <stdio.h>

      int main() {
        blst_scalar sk;
        const byte IKM[] = {0};
        const byte DST[] = {0};
        blst_keygen(&sk, IKM, sizeof(IKM), DST, sizeof(DST));
        printf("OK\\n");
        return 0;
      }
    EOS
    system ENV.cc, "test.c", "-L#{lib}", "-lblst", "-o", "test"
    system "./test"
  end
end
