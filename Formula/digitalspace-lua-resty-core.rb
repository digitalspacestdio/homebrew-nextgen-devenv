class DigitalspaceLuaRestyCore < Formula
  desc "Embed the power of Lua into Nginx"
  homepage "https://github.com/openresty/lua-resty-core"
  url "https://github.com/openresty/lua-resty-core/archive/refs/tags/v0.1.27.tar.gz"
  sha256 "39baab9e2b31cc48cecf896cea40ef6e80559054fd8a6e440cc804a858ea84d4"
  head "https://github.com/openresty/lua-resty-core.git", branch: "master"
  revision 1

  bottle do
    root_url "https://f003.backblazeb2.com/file/homebrew-bottles/nextgen-devenv/digitalspace-lua-resty-core"
    sha256 cellar: :any_skip_relocation, arm64_ventura:  "23dfef07d3d2a22ba73b18f48a6d7bcca6d81166830bf3456365fb9b8a867b48"
    sha256 cellar: :any_skip_relocation, arm64_monterey: "d976c444ae8c2b1f2c976dd5f2dabb13336a7bb9a9c50a9419885ea7980a4bfa"
    sha256 cellar: :any_skip_relocation, sonoma:         "952d4cae087b66e677c380a3cfc712760274a02e82092d7960fd6525a3a88417"
    sha256 cellar: :any_skip_relocation, monterey:       "094e4dfa8f15b51c902c03c3283414b97f78c63293ade52bd72f0af725652abb"
    sha256 cellar: :any_skip_relocation, x86_64_linux:   "0a67b47119afd1037ce5c9598ef13c8c13115a617a2cdc7b85e5887d54511229"
  end

  def install
    pkgshare.install Dir["*"]
  end
end