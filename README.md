# Homebrew Nextgen Devenv
macOS/Linux/Windows 10 LEMP (NGINX/PHP/MySql) Development Environment



### Installation
0. Install Homebrew by following official guide [https://brew.sh/](https://brew.sh/)

1. Add the homebrew taps
```bash
brew tap digitalspacestdio/nextgen-devenv
brew tap digitalspacestdio/php
```


2. Install base packages
```bash
brew install digitalspace-dnsmasq digitalspace-nginx digitalspace-traefik digitalspace-supervisor
```
3. Install mysql (optional)
```bash
brew install digitalspace-mysql80
```
4. Install PHPs (optional)
```bash
brew install php83-common php82-common php81-common php74-common php73-common php72-common php71-common
```
> you can select only the formulas you need

5. Install the root certificat to the system
```bash
sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain $(brew --prefix)/etc/openssl/localCa/root_ca.crt
```

6. Enable the dnsmasq service
```bash
sudo $(which digitalspace-dnsmasq-start)
```

7. Start the supervisor
```bash
sudo $(which digitalspace-supervisor-start)
```

8. Check the services status
```bash
digitalspace-supctl
```

