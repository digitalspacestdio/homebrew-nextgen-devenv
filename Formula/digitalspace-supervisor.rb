class DigitalspaceSupervisor < Formula
  include Language::Python::Virtualenv

  desc "Super Process Control System for DigitalSpace Services"
  homepage "http://supervisord.org/"
  url "https://github.com/Supervisor/supervisor/archive/refs/tags/4.2.5.tar.gz"
  sha256 "d612a48684cf41ea7ce8cdc559eaa4bf9cbaa4687c5aac3f355c6d2df4e4f170"
  license "BSD-3-Clause-Modification"
  head "https://github.com/Supervisor/supervisor.git", branch: "master"
  depends_on "python@3.11"
  revision 9

  def log_dir
      var / "log"
  end

  def apps_dir
    etc / "digitalspace-supervisor.d"
  end

  def service_script
    <<~EOS
      #!/bin/bash
      set -e
      if [[ $(id -u ${USER}) != 0 ]]; then
        echo "You must run this script under the root user!"
        exit 1
      fi
      
      exec #{opt_bin}/digitalspace-supervisord "$@"
      EOS
  rescue StandardError
      nil
  end

  def start_script_macos
    <<~EOS
      #!/bin/bash
      set -e
      if [[ $(id -u ${USER}) != 0 ]]; then
        echo "You must run this script under the root user!"
        exit 1
      fi
      cp #{HOMEBREW_PREFIX}/opt/digitalspace-supervisor/homebrew.mxcl.digitalspace-supervisor.plist /Library/LaunchDaemons/homebrew.mxcl.digitalspace-supervisor.plist
      launchctl load -w /Library/LaunchDaemons/homebrew.mxcl.digitalspace-supervisor.plist

      EOS
  rescue StandardError
      nil
  end

  def start_script_linux
    <<~EOS
      #!/bin/bash
      set -e
      if [[ $(id -u ${USER}) != 0 ]]; then
        echo "You must run this script under the root user!"
        exit 1
      fi
      cp #{HOMEBREW_PREFIX}/opt/digitalspace-supervisor/homebrew.digitalspace-supervisor.service /etc/systemd/system/homebrew.digitalspace-supervisor.service
      systemctl daemon-reload
      systemctl enable --now homebrew.digitalspace-supervisor.service

      EOS
  rescue StandardError
      nil
  end

  def stop_script_macos
    <<~EOS
      #!/bin/bash
      set -e
      if [[ $(id -u ${USER}) != 0 ]]; then
        echo "You must run this script under the root user!"
        exit 1
      fi
      if [[ -f /Library/LaunchDaemons/homebrew.mxcl.digitalspace-supervisor.plist ]]; then
        launchctl unload -w /Library/LaunchDaemons/homebrew.mxcl.digitalspace-supervisor.plist > /dev/null 2>&1
      fi
      chown -R #{ENV['USER']} #{prefix}
      EOS
  rescue StandardError
      nil
  end

  def stop_script_linux
    <<~EOS
      #!/bin/bash
      set -e
      if [[ $(id -u ${USER}) != 0 ]]; then
        echo "You must run this script under the root user!"
        exit 1
      fi
      if [[ -f /etc/systemd/system/homebrew.digitalspace-supervisor.service ]]; then
        systemctl disable --now homebrew.digitalspace-supervisor.service
        rm /etc/systemd/system/homebrew.digitalspace-supervisor.service
      fi
      chown -R #{ENV['USER']} #{prefix}
      EOS
  rescue StandardError
      nil
  end

  def digitalspace_supctl_script
    <<~EOS
      #!/bin/bash
      set -e
      exec #{opt_bin}/digitalspace-supervisorctl -c #{etc}/digitalspace-supervisor.conf "$@"
      EOS
  rescue StandardError
      nil
  end

  def install
    inreplace buildpath/"supervisor/skel/sample.conf" do |s|
      s.gsub! %r{/tmp/supervisor\.sock}, var/"run/digitalspace-supervisor.sock"
      s.gsub! %r{/tmp/supervisord\.log}, var/"log/digitalspace-supervisor.log"
      s.gsub! %r{/tmp/supervisord\.pid}, var/"run/digitalspace-supervisor.pid"
      s.gsub!(/^;chmod=.*/, "chmod=0777")
      s.gsub!(/^;\[include\]$/, "[include]")
      s.gsub! %r{^;files = relative/directory/\*\.ini$}, "files = #{etc}/digitalspace-supervisor.d/*.ini"
    end

    virtualenv_install_with_resources

    on_macos do
      (buildpath / "bin" / "digitalspace-supervisor-start").write(start_script_macos)
      (buildpath / "bin" / "digitalspace-supervisor-start").chmod(0755)
      bin.install "bin/digitalspace-supervisor-start"

      (buildpath / "bin" / "digitalspace-supervisor-stop").write(stop_script_macos)
      (buildpath / "bin" / "digitalspace-supervisor-stop").chmod(0755)
      bin.install "bin/digitalspace-supervisor-stop"
    end

    on_linux do
      (buildpath / "bin" / "digitalspace-supervisor-start").write(start_script_linux)
      (buildpath / "bin" / "digitalspace-supervisor-start").chmod(0755)
      bin.install "bin/digitalspace-supervisor-start"

      (buildpath / "bin" / "digitalspace-supervisor-stop").write(stop_script_linux)
      (buildpath / "bin" / "digitalspace-supervisor-stop").chmod(0755)
      bin.install "bin/digitalspace-supervisor-stop"
    end

    (buildpath / "bin" / "digitalspace-supervisord-service").write(service_script)
    (buildpath / "bin" / "digitalspace-supervisord-service").chmod(0755)
    bin.install "bin/digitalspace-supervisord-service"

    (buildpath / "bin" / "digitalspace-supctl").write(digitalspace_supctl_script)
    (buildpath / "bin" / "digitalspace-supctl").chmod(0755)
    bin.install "bin/digitalspace-supctl"

    mv bin/"supervisord", bin/"digitalspace-supervisord"
    mv bin/"supervisorctl", bin/"digitalspace-supervisorctl"
    mv bin/"pidproxy", bin/"digitalspace-pidproxy"
    mv bin/"echo_supervisord_conf", bin/"digitalspace-echo_supervisord_conf"

    etc.install buildpath/"supervisor/skel/sample.conf" => "digitalspace-supervisor.conf"
    log_dir.mkpath
    apps_dir.mkpath
  end

  def post_install
    (var/"run").mkpath
    (var/"log").mkpath
    conf_warn = <<~EOS
      The default location for supervisor's config file is now:
        #{etc}/digitalspace-supervisor.conf
      Please move your config file to this location and restart supervisor.
    EOS
    old_conf = etc/"digitalspace-supervisor.ini"
    opoo conf_warn if old_conf.exist?
  end

  service do
    run [opt_bin/"digitalspace-supervisord-service", "-c", etc/"digitalspace-supervisor.conf", "--nodaemon"]
    keep_alive true
  end

  test do
    (testpath/"sd.ini").write <<~EOS
      [unix_http_server]
      file=#{var}/run/digitalspace-supervisor.sock

      [supervisord]
      loglevel=debug

      [rpcinterface:supervisor]
      supervisor.rpcinterface_factory = supervisor.rpcinterface:make_main_rpcinterface

      [supervisorctl]
      serverurl=unix://#{var}/run/digitalspace-supervisor.sock
    EOS

    begin
      pid = fork { exec bin/"digitalspace-supervisord", "--nodaemon", "-c", "sd.ini" }
      sleep 1
      output = shell_output("#{bin}/supervisorctl -c sd.ini version")
      assert_match version.to_s, output
    ensure
      Process.kill "TERM", pid
    end
  end
end
