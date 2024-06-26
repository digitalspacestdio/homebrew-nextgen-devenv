class DigitalspaceTraefik < Formula
  url "file:///dev/null"
  sha256 "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"
  version "0.1.4"

  depends_on "traefik@2"
  depends_on "digitalspace-local-ca"

  def traefik_main_config
    <<~EOS
      [global]
        checkNewVersion = false
        sendAnonymousUsage = false
      
      [entryPoints]
        [entryPoints.web]
          address = ":80"
        [entryPoints.web.http.redirections.entryPoint]
          to = "default"
          scheme = "https"
          permanent = true
      
      [entryPoints.default]
        address = ":443"
      [entryPoints.default.http.tls]

      # [certificatesResolvers]
      # [certificatesResolvers.default]
      #   [certificatesResolvers.default.acme]
      #     caServer = "https://localhost:9480/acme/acme/directory"
      #     email = "admin"
      #     storage = "#{etc}/digitalspace-traefik/acme.json"
      #     certificatesDuration = 24
      #     tlsChallenge = true
      # [certificatesResolvers.default.acme.httpChallenge]
      #   entryPoint = "default"
      # [certificatesResolvers.default.acme.dnsChallenge]
      #   provider = "acme-dns"
      #   resolvers = ["127.0.0.1:53"]

      [log]
        level = "DEBUG"
        filePath = "#{var}/log/digitalspace-traefik_traefik.log"
      
      [accessLog]
        filePath = "#{var}/log/digitalspace-traefik_access.log"
      
      [api]
        dashboard = true
      
      [serversTransport]
        insecureSkipVerify = true
      
      [providers.file]
        directory = "#{etc}/digitalspace-traefik/conf.d/"
        watch = true
      EOS
  rescue StandardError
      nil
  end

  def traefik_docker_config
    <<~EOS
    #[providers.docker]
    #   exposedByDefault = false
    EOS
  rescue StandardError
    nil
  end

  def traefik_dashboard_config
    <<~EOS
    [http.routers]
      [http.routers.api]
        rule = "Host(`traefik.dev.local`) && PathPrefix(`/api/`)"
        service = "api@internal"
        entryPoints = ["default"]
        priority = 10000

      [http.routers.traefik]
        rule = "Host(`traefik.dev.local`) && PathPrefix(`/`)"
        service = "dashboard@internal"
        entryPoints = ["default"]
        priority = 5000
    EOS
  rescue StandardError
      nil
  end

  def traefik_snippets_config
    <<~EOS
    [http.middlewares]
      [http.middlewares.redirect-trailing-slash.redirectRegex]
        regex = "^(http|ws)s?:\\\\/\\\\/(www\\\\.){0,1}(([a-z0-9\\\\-_]+?\\\\.)+[a-z0-9\\\\-_]+)(((\\\\/[^\\\\/\\\\?]+)*?)(\\\\/[^\\\\/.\\\\?]+))(\\\\/{0}|\\\\/{2,})(\\\\?{1}.*){0,1}$"
        replacement = "${1}s://${3}${5}/${10}"
        permanent =  true
    
      [http.middlewares.redirect-from-www.redirectRegex]
        regex = "^(http|ws)s?:\\\\/\\\\/www\\\\.(.*)"
        replacement = "${1}s://${2}"
        permanent =  true
    
      [http.middlewares.redirect-secure.redirectRegex]
        regex = "^(http|ws):\\\\/\\\\/(.+)$"
        replacement = "${1}s://${2}"
        permanent =  true
    
      [http.middlewares.redirect-double-slash.redirectRegex]
        regex = "^(http|ws)s?:\\\\/\\\\/(.*\\\\/)\\\\/(.*)$"
        replacement = "${1}s://${2}${3}"
        permanent =  true
    
      [http.middlewares.ratelimit-default.rateLimit]
        average = 100
        burst = 200
        period = "5s"
    
      [http.middlewares.admin-auth.basicAuth]
        # admin / $ecretPassw0rd
        users = [
            "admin:$2y$05$SrVjSbbXSRCqx4nJkJxEtuypRzjmjhrKkKFpTss.PtPbUM/TUwMwC"
        ]
    
      [http.middlewares.gzip.compress]
    EOS
  end

  def traefik_localhost_config
    <<~EOS
    [[tls.certificates]]
      certFile = "#{etc}/openssl/localCA/certs/dev.local.crt"
      keyFile = "#{etc}/openssl/localCA/private/dev.local.key"
    [[tls.certificates]]
      certFile = "#{etc}/openssl/localCA/certs/dev.com.crt"
      keyFile = "#{etc}/openssl/localCA/private/dev.com.key"

    [[tls.certificates]]
      certFile = "#{etc}/openssl/localCA/certs/loc.com.crt"
      keyFile = "#{etc}/openssl/localCA/private/loc.com.key"

    [http.routers]
      [http.routers.dev_com]
        rule = "HostRegexp(`{subdomain:[a-z0-9-]+}.dev.com`, `{subsubdomain:[a-z0-9-]+}.{subdomain:[a-z0-9-]+}.dev.com`)"
        priority = 100
        service = "digitalspace-nginx"
        entryPoints = ["default"]
        #tls = true
        #[http.routers.dev_com.tls]
        #certResolver = "default"
        [[http.routers.dev_com.tls.domains]]
        main = "*.dev.com"

      [http.routers.loc_com]
        rule = "HostRegexp(`{subdomain:[a-z0-9-]+}.loc.com`, `{subsubdomain:[a-z0-9-]+}.{subdomain:[a-z0-9-]+}.loc.com`)"
        priority = 110
        service = "digitalspace-nginx"
        entryPoints = ["default"]
        [http.routers.loc_com.tls]
        #tls = true
        #certResolver = "default"
        [[http.routers.loc_com.tls.domains]]
        main = "*.loc.com"


      [http.routers.dev_local]
        rule = "HostRegexp(`{subdomain:[a-z0-9-]+}.dev.local`, `{subsubdomain:[a-z0-9-]+}.{subdomain:[a-z0-9-]+}.dev.local`)"
        priority = 120
        service = "digitalspace-nginx"
        entryPoints = ["default"]
        #tls = true
        #[http.routers.dev_local.tls]
        #certResolver = "default"
        [[http.routers.dev_local.tls.domains]]
        main = "*.dev.local"

    [http.services]
      [http.services.digitalspace-nginx]
        [http.services.digitalspace-nginx.loadBalancer]
          [[http.services.digitalspace-nginx.loadBalancer.servers]]
            url = "http://127.0.0.1:1984"
    EOS
  rescue StandardError
      nil
  end

  def binary_dir
    buildpath / "bin"
  end

  def binary_path
    binary_dir / "bin" / "digitalspace-traefik"
  end

  def binary_wrapper
    <<~EOS
      #!/usr/bin/env bash
      set -e
      
      exec #{Formula["traefik@2"].opt_bin}/traefik "$@"
    EOS
  rescue StandardError
      nil
  end

  def install
    binary_dir.mkpath
    binary_path.write(binary_wrapper)
    binary_path.chmod(0755)
    bin.install binary_path
  end

  def supervisor_config
    <<~EOS
      [program:traefik]
      command=#{opt_bin}/digitalspace-traefik --configfile=#{etc}/digitalspace-traefik/traefik.toml
      directory=#{opt_prefix}
      stdout_logfile=#{var}/log/digitalspace-supervisor-traefik.log
      stdout_logfile_maxbytes=1MB
      stderr_logfile=#{var}/log/digitalspace-supervisor-traefik.err
      stderr_logfile_maxbytes=1MB
      autorestart=true
      stopasgroup=true
      EOS
  rescue StandardError
      nil
  end

  def post_install
    certs = etc / "digitalspace-traefik" / "certs"
    
    (etc/"digitalspace-traefik").mkpath
    (etc/"digitalspace-traefik"/"conf.d").mkpath
    (etc/"digitalspace-traefik"/"traefik.toml").delete if (etc/"digitalspace-traefik"/"traefik.toml").exist?
    (etc/"digitalspace-traefik"/"traefik.toml").write(traefik_main_config)

    (etc/"digitalspace-traefik"/"conf.d"/"docker.toml").write(traefik_docker_config) if !(etc/"digitalspace-traefik"/"conf.d"/"dashboard.toml").exist?

    (etc/"digitalspace-traefik"/"conf.d"/"dashboard.toml").delete if (etc/"digitalspace-traefik"/"conf.d"/"dashboard.toml").exist?
    (etc/"digitalspace-traefik"/"conf.d"/"dashboard.toml").write(traefik_dashboard_config)

    (etc/"digitalspace-traefik"/"conf.d"/"localhost.toml").delete if (etc/"digitalspace-traefik"/"conf.d"/"localhost.toml").exist?
    (etc/"digitalspace-traefik"/"conf.d"/"localhost.toml").write(traefik_localhost_config)

    (etc/"digitalspace-traefik"/"conf.d"/"snippets.toml").delete if (etc/"digitalspace-traefik"/"conf.d"/"snippets.toml").exist?
    (etc/"digitalspace-traefik"/"conf.d"/"snippets.toml").write(traefik_snippets_config)

    (etc/"digitalspace-supervisor.d").mkpath
    (etc/"digitalspace-supervisor.d"/"traefik.ini").delete if (etc/"digitalspace-supervisor.d"/"traefik.ini").exist?
    (etc/"digitalspace-supervisor.d"/"traefik.ini").write(supervisor_config)

    system("local-ca-crtgen dev.local") unless File.exist?(etc / "openssl" / "localCA" / "certs" / "dev.local.crt")
    system("local-ca-crtgen dev.com") unless File.exist?(etc / "openssl" / "localCA" / "certs" / "dev.com.crt")
    system("local-ca-crtgen loc.com") unless File.exist?(etc / "openssl" / "localCA" / "certs" / "loc.com.crt")
  end

  # step_path = `#{Formula["step"].opt_bin}/step path --base`

  service do
    run ["#{opt_bin}/digitalspace-traefik", "--configfile=#{etc}/digitalspace-traefik/traefik.toml"]
    working_dir HOMEBREW_PREFIX
    keep_alive true
    require_root true
    log_path var/"log/digitalspace-service-traefik.log"
    error_log_path var/"log/digitalspace-service-traefik-error.log"
    #environment_variables LEGO_CA_CERTIFICATES: "#{step_path.strip}/certs/root_ca.crt"
    #environment_variables LEGO_CA_CERTIFICATES: "#{step_path.strip}/certs/root_ca.crt", ACME_DNS_API_BASE: 'http://auth.localhost:5380', ACME_DNS_STORAGE_PATH: "#{etc}/digitalspace-traefik/acme.json"
  end
end
