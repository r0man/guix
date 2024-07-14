;;; GNU Guix --- Functional package management for GNU
;;; Copyright © 2024 Roman Scherer <roman@burningswell.com>
;;;
;;; This file is part of GNU Guix.
;;;
;;; GNU Guix is free software; you can redistribute it and/or modify it
;;; under the terms of the GNU General Public License as published by
;;; the Free Software Foundation; either version 3 of the License, or (at
;;; your option) any later version.
;;;
;;; GNU Guix is distributed in the hope that it will be useful, but
;;; WITHOUT ANY WARRANTY; without even the implied warranty of
;;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;;; GNU General Public License for more details.
;;;
;;; You should have received a copy of the GNU General Public License
;;; along with GNU Guix.  If not, see <http://www.gnu.org/licenses/>.

(define-module (gnu machine hetzner)
  #:use-module ((guix diagnostics) #:select (formatted-message))
  #:use-module (gnu machine ssh)
  #:use-module (gnu machine)
  #:use-module (gnu services base)
  #:use-module (gnu services networking)
  #:use-module (gnu services)
  #:use-module (gnu system pam)
  #:use-module (gnu system)
  #:use-module (guix base32)
  #:use-module (guix derivations)
  #:use-module (guix i18n)
  #:use-module (guix import json)
  #:use-module (guix monads)
  #:use-module (guix records)
  #:use-module (guix ssh)
  #:use-module (guix store)
  #:use-module (ice-9 format)
  #:use-module (ice-9 iconv)
  #:use-module (ice-9 popen)
  #:use-module (ice-9 string-fun)
  #:use-module (ice-9 textual-ports)
  #:use-module (json)
  #:use-module (rnrs bytevectors)
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-2)
  #:use-module (srfi srfi-34)
  #:use-module (srfi srfi-35)
  #:use-module (ssh key)
  #:use-module (ssh sftp)
  #:use-module (ssh shell)
  #:use-module (web client)
  #:use-module (web request)
  #:use-module (web response)
  #:use-module (web uri)
  #:export (hetzner-configuration
            hetzner-configuration?

            hetzner-configuration-ssh-key
            hetzner-configuration-labels
            hetzner-configuration-region
            hetzner-configuration-enable-ipv6?

            hetzner-environment-type))

;;; Commentary:
;;;
;;; This module implements a high-level interface for provisioning "servers"
;;; from the Hetzner Cloud service.
;;;
;;; Code:

(define %api-base "https://api.hetzner.cloud")
(define %hetzner-token-name "GUIX_HETZNER_TOKEN")

(define %hetzner-token
  (make-parameter (getenv %hetzner-token-name)))

(define* (post-endpoint endpoint body)
  "Encode BODY as JSON and send it to the Hetzner API endpoint
ENDPOINT. This procedure is quite a bit more specialized than 'http-post', as
it takes care to set headers such as 'Content-Type', 'Content-Length', and
'Authorization' appropriately."
  (format #t "POST ~a\n" (scm->json-string body))
  (let* ((uri (string->uri (string-append %api-base endpoint)))
         (body (string->bytevector (scm->json-string body) "UTF-8"))
         (headers `((User-Agent . "Guix Deploy")
                    (Accept . "application/json")
                    (Content-Type . "application/json")
                    (Authorization . ,(format #f "Bearer ~a"
                                              (%hetzner-token)))
                    (Content-Length . ,(number->string
                                        (bytevector-length body)))))
         (port (open-socket-for-uri uri))
         (request (build-request uri
                                 #:method 'POST
                                 #:version '(1 . 1)
                                 #:headers headers
                                 #:port port))
         (request (write-request request port)))
    (write-request-body request body)
    (force-output (request-port request))
    (let* ((response (read-response port))
           (body (read-response-body response)))
      (unless (= 2 (floor/ (response-code response) 100))
        (format #t "RESPONSE: ~a\n" (bytevector->string body "UTF-8"))
        (raise
         (condition (&message
                     (message (format
                               #f
                               (G_ "~a: HTTP post failed: ~a (~s)")
                               (uri->string uri)
                               (response-code response)
                               (response-reason-phrase response)))))))
      (close-port port)
      (bytevector->string body "UTF-8"))))

(define (fetch-endpoint endpoint)
  "Return the contents of the Hetzner API endpoint ENDPOINT as an
alist. This procedure is quite a bit more specialized than 'json-fetch', as it
takes care to set headers such as 'Accept' and 'Authorization' appropriately."
  (define headers
    `((user-agent . "Guix Deploy")
      (Accept . "application/json")
      (Authorization . ,(format #f "Bearer ~a" (%hetzner-token)))))
  (json-fetch (string-append %api-base endpoint) #:headers headers))


;;;
;;; Parameters for droplet creation.
;;;

(define-record-type* <hetzner-configuration> hetzner-configuration
  make-hetzner-configuration
  hetzner-configuration?
  this-hetzner-configuration
  (enable-ipv6? hetzner-configuration-enable-ipv6? ; boolean
                (default #f))
  (region hetzner-configuration-region  ; string
          (default "eu-central"))
  (server-type hetzner-configuration-server-type ; string
               (default "cx22"))
  (ssh-key hetzner-configuration-ssh-key) ; string
  (labels hetzner-configuration-labels) ; list of strings
  ;; Digital ocean
  ;; (size        hetzner-configuration-size)         ; string

  )

(define (read-key-fingerprint file-name)
  "Read the private key at FILE-NAME and return the key's fingerprint as a hex
string."
  (let* ((privkey (private-key-from-file file-name))
         (pubkey (private-key->public-key privkey))
         (hash (get-public-key-hash pubkey 'md5)))
    (bytevector->hex-string hash)))

(define (sort-labels labels)
  "Sort the LABELS by key."
  (sort-list labels (lambda (a b) (string<? (car a) (car b)))))

(define (machine-droplet machine)
  "Return an alist describing the droplet allocated to MACHINE."
  (let* ((config (machine-configuration machine))
         (labels (sort-labels (hetzner-configuration-labels config))))
    (find (lambda (droplet)
            (equal? (sort-labels (assoc-ref droplet "labels")) labels))
          (vector->list
           (assoc-ref (fetch-endpoint "/v1/servers") "servers")))))

(define (machine-get-ssh-key machine)
  "Find the SSH key for MACHINE."
  (let* ((ssh-key (hetzner-configuration-ssh-key (machine-configuration machine)))
         (fingerprint (read-key-fingerprint ssh-key)))
    (find (lambda (droplet)
            (equal? (assoc-ref droplet "fingerprint") fingerprint))
          (vector->list
           (assoc-ref (fetch-endpoint "/v1/ssh_keys") "ssh_keys")))))

(define (machine-create-ssh-key machine)
  "Create the SSH key for MACHINE."
  (let* ((config (machine-configuration machine))
         (name (machine-display-name machine))
         (ssh-key (hetzner-configuration-ssh-key config))
         (fingerprint (read-key-fingerprint ssh-key))
         (public-key (public-key-from-file ssh-key))
         (labels (hetzner-configuration-labels config))
         (request-body `(("name" . ,name)
                         ("fingerprint" . ,fingerprint)
                         ("public_key" . ,(format #f "ssh-~a ~a"
                                                  (get-key-type public-key)
                                                  (public-key->string public-key)))
                         ("labels" . ,labels)))
         (response (post-endpoint "/v1/ssh_keys" request-body)))
    (assoc-ref (json-string->scm response) "ssh_key")))

(define (machine-public-ipv4-network machine)
  "Return the public IPv4 network interface of the droplet allocated to
MACHINE as an alist. The expected fields are 'ip_address', 'netmask', and
'gateway'."
  (and-let* ((droplet (machine-droplet machine))
             (public-net (assoc-ref droplet "public_net"))
             (network (assoc-ref public-net "ipv4")))
    network))


;;;
;;; Remote evaluation.
;;;

(define (hetzner-remote-eval target exp)
  "Internal implementation of 'machine-remote-eval' for MACHINE instances with
an environment type of 'hetzner-environment-type'."
  (let* ((network (machine-public-ipv4-network target))
         (address (assoc-ref network "ip"))
         (ssh-key (hetzner-configuration-ssh-key
                   (machine-configuration target)))
         (delegate (machine
                    (inherit target)
                    (environment managed-host-environment-type)
                    (configuration
                     (machine-ssh-configuration
                      (host-name address)
                      (identity ssh-key)
                      (system "x86_64-linux"))))))
    (machine-remote-eval delegate exp)))


;;;
;;; System deployment.
;;;

;; XXX Copied from (gnu services base)
(define* (ip+netmask->cidr ip netmask #:optional (family AF_INET))
  "Return the CIDR notation (a string) for @var{ip} and @var{netmask}, two
@var{family} address strings, where @var{family} is @code{AF_INET} or
@code{AF_INET6}."
  (let* ((netmask (inet-pton family netmask))
         (bits    (logcount netmask)))
    (string-append ip "/" (number->string bits))))

;; The following script was adapted from the guide available at
;; <https://wiki.pantherx.org/Installation-hetzner/>.
(define (guix-infect network)
  "Given NETWORK, an alist describing the Droplet's public IPv4 network
interface, return a Bash script that will install the Guix system."
  (define os
    `(operating-system
       (host-name "gnu-bootstrap")
       (timezone "Etc/UTC")
       (bootloader (bootloader-configuration
                    (bootloader grub-efi-bootloader)
                    (targets '("/boot/efi"))
                    (terminal-outputs '(console))))
       (file-systems (cons* (file-system
                              (mount-point "/")
                              (device "/dev/sda1")
                              (type "ext4"))
                            (file-system
                              (mount-point "/boot/efi")
                              (device "/dev/sda15")
                              (type "vfat"))
                            %base-file-systems))
       (services
        (append (list ;; (service static-networking-service-type
                 ;;          (list (static-networking
                 ;;                 (addresses
                 ;;                  (list (network-address
                 ;;                         (device "eth0")
                 ;;                         (value ,(ip+netmask->cidr
                 ;;                                  (assoc-ref network "ip")
                 ;;                                  (assoc-ref network "netmask"))))))
                 ;;                 (routes
                 ;;                  (list (network-route
                 ;;                         (destination "default")
                 ;;                         (gateway ,(assoc-ref network "gateway")))))
                 ;;                 (name-servers '("84.200.69.80" "84.200.70.40")))))
                 (service dhcp-client-service-type)
                 (simple-service 'guile-load-path-in-global-env
                                 session-environment-service-type
                                 `(("GUILE_LOAD_PATH"
                                    . "/run/current-system/profile/share/guile/site/3.0")
                                   ("GUILE_LOAD_COMPILED_PATH"
                                    . ,(string-append "/run/current-system/profile/lib/guile/3.0/site-ccache:"
                                                      "/run/current-system/profile/share/guile/site/3.0"))))
                 (service openssh-service-type
                          (openssh-configuration
                           (log-level 'debug)
                           (permit-root-login 'prohibit-password))))
                %base-services))))
  (format #f "#!/bin/bash

apt-get update
apt-get install xz-utils -y
wget -nv https://ci.guix.gnu.org/search/latest/archive?query=spec:tarball+status:success+system:x86_64-linux+guix-binary.tar.xz -O guix-binary-nightly.x86_64-linux.tar.xz
cd /tmp
tar --warning=no-timestamp -xf ~~/guix-binary-nightly.x86_64-linux.tar.xz
mv var/guix /var/ && mv gnu /
mkdir -p ~~root/.config/guix
ln -sf /var/guix/profiles/per-user/root/current-guix ~~root/.config/guix/current
export GUIX_PROFILE=\"`echo ~~root`/.config/guix/current\" ;
source $GUIX_PROFILE/etc/profile
groupadd --system guixbuild
for i in `seq -w 1 10`; do
   useradd -g guixbuild -G guixbuild         \
           -d /var/empty -s `which nologin`  \
           -c \"Guix build user $i\" --system  \
           guixbuilder$i;
done;
cp ~~root/.config/guix/current/lib/systemd/system/guix-daemon.service /etc/systemd/system/
systemctl start guix-daemon && systemctl enable guix-daemon
mkdir -p /usr/local/bin
cd /usr/local/bin
ln -s /var/guix/profiles/per-user/root/current-guix/bin/guix
mkdir -p /usr/local/share/info
cd /usr/local/share/info
for i in /var/guix/profiles/per-user/root/current-guix/share/info/*; do
    ln -s $i;
done
guix archive --authorize < ~~root/.config/guix/current/share/guix/ci.guix.gnu.org.pub
# guix pull
guix package -i glibc-utf8-locales
export GUIX_LOCPATH=\"$HOME/.guix-profile/lib/locale\"
guix package -i openssl
cat > /etc/bootstrap-config.scm << EOF
(use-modules (gnu))
(use-service-modules base networking ssh)

~a
EOF
# guix pull
guix system build /etc/bootstrap-config.scm
guix system reconfigure /etc/bootstrap-config.scm
mv /etc /old-etc
mkdir /etc
cp -r /old-etc/{passwd,group,shadow,gshadow,mtab,guix,bootstrap-config.scm,resolv.conf} /etc/
export GIT_SSL_CAINFO=/old-etc/ssl/certs/ca-certificates.crt
export SSL_CERT_DIR=/old-etc/ssl/certs
export SSL_CERT_FILE=/old-etc/ssl/certs/ca-certificates.crt
guix system reconfigure /etc/bootstrap-config.scm"
          ;; Escape the bare backtick to avoid having it interpreted by Bash.
          (string-replace-substring
           (format #f "~y" os) "`" "\\`")))

(define (machine-wait-until-available machine)
  "Block until the initial Debian image has been installed on the droplet
named DROPLET-NAME."
  (and-let* ((droplet (machine-droplet machine))
             (droplet-id (assoc-ref droplet "id"))
             (endpoint (format #f "/v1/servers/~a/actions" droplet-id)))
    (let loop ()
      (let ((actions (assoc-ref (fetch-endpoint endpoint) "actions")))
        (format #t "Waiting for machine ...\n~a\n" actions)
        (unless (every (lambda (action)
                         (string= "success" (assoc-ref action "status")))
                       (vector->list actions))
          (sleep 5)
          (loop))))))

(define (wait-for-ssh address ssh-key)
  "Block until the an SSH session can be made as 'root' with SSH-KEY at ADDRESS."
  (let loop ()
    (catch #t
      (lambda ()
        (format #t "Open SSH to ~a using ~a ...\n" address ssh-key)
        (open-ssh-session address #:user "root" #:identity ssh-key))
      (lambda args
        (sleep 5)
        (loop)))))

(define (add-static-networking target network)
  "Return an <operating-system> based on TARGET with a static networking
configuration for the public IPv4 network described by the alist NETWORK."
  (operating-system
    (inherit (machine-operating-system target))
    (services (cons* (service dhcp-client-service-type)
                     ;; (service static-networking-service-type
                     ;;          (list (static-networking
                     ;;                 (addresses
                     ;;                  (list (network-address
                     ;;                         (device "eth0")
                     ;;                         (value (ip+netmask->cidr
                     ;;                                 (assoc-ref network "ip_address")
                     ;;                                 (assoc-ref network "netmask"))))))
                     ;;                 (routes
                     ;;                  (list (network-route
                     ;;                         (destination "default")
                     ;;                         (gateway (assoc-ref network "gateway")))))
                     ;;                 (name-servers '("84.200.69.80" "84.200.70.40")))))
                     (simple-service 'guile-load-path-in-global-env
                                     session-environment-service-type
                                     `(("GUILE_LOAD_PATH"
                                        . "/run/current-system/profile/share/guile/site/3.0")
                                       ("GUILE_LOAD_COMPILED_PATH"
                                        . ,(string-append "/run/current-system/profile/lib/guile/3.0/site-ccache:"
                                                          "/run/current-system/profile/share/guile/site/3.0"))))
                     (operating-system-user-services
                      (machine-operating-system target))))))

(define (deploy-hetzner target)
  "Internal implementation of 'deploy-machine' for 'machine' instances with an
environment type of 'hetzner-environment-type'."
  (maybe-raise-missing-api-key-error)
  (maybe-raise-unsupported-configuration-error target)
  (let* ((config (machine-configuration target))
         (name (machine-display-name target))
         (name (machine-display-name target))
         (server-type (hetzner-configuration-server-type config))
         (region (hetzner-configuration-region config))
         (enable-ipv6? (hetzner-configuration-enable-ipv6? config))
         (labels (hetzner-configuration-labels config))
         (ssh-key-object (or (machine-get-ssh-key %hetzner-machine)
                             (machine-create-ssh-key %hetzner-machine)))
         (request-body `(("image" . "debian-11")
                         ("labels" . ,labels)
                         ("name" . ,name)
                         ("public_net" . (("enable_ipv6" . ,enable-ipv6?)))
                         ("region" . ,region)
                         ("server_type" . ,server-type)
                         ("ssh_keys" . ,(vector (assoc-ref ssh-key-object "id")))))
         (response (post-endpoint "/v1/servers" request-body)))
    (format #t "Server created.\n~a\n" response)
    (machine-wait-until-available target)
    (let* ((network (machine-public-ipv4-network target))
           (address (assoc-ref network "ip"))
           (ssh-key (hetzner-configuration-ssh-key config)))
      (format #t "Machine ready. Waiting for SSH at ~a ...\n" address)
      (wait-for-ssh address ssh-key)
      (let* ((ssh-session (open-ssh-session address #:user "root" #:identity ssh-key))
             (sftp-session (make-sftp-session ssh-session)))
        (format #t "Infecting machine ...\n")
        (call-with-remote-output-file sftp-session "/tmp/guix-infect.sh"
                                      (lambda (port)
                                        (display (guix-infect network) port)))
        (rexec ssh-session "/bin/bash /tmp/guix-infect.sh")
        ;; Session will close upon rebooting, which will raise 'guile-ssh-error.
        (catch 'guile-ssh-error
          (lambda () (rexec ssh-session "reboot"))
          (lambda args #t)))
      (format #t "Waiting for reboot ...\n")
      (wait-for-ssh address ssh-key)
      (let ((delegate (machine
                       (operating-system (add-static-networking target network))
                       (environment managed-host-environment-type)
                       (configuration
                        (machine-ssh-configuration
                         (host-name address)
                         (identity ssh-key)
                         (system "x86_64-linux"))))))
        (deploy-machine delegate)))))


;;;
;;; Roll-back.
;;;

(define (roll-back-hetzner target)
  "Internal implementation of 'roll-back-machine' for MACHINE instances with an
environment type of 'hetzner-environment-type'."
  (let* ((network (machine-public-ipv4-network target))
         (address (assoc-ref network "ip_address"))
         (ssh-key (hetzner-configuration-ssh-key
                   (machine-configuration target)))
         (delegate (machine
                    (inherit target)
                    (environment managed-host-environment-type)
                    (configuration
                     (machine-ssh-configuration
                      (host-name address)
                      (identity ssh-key)
                      (system "x86_64-linux"))))))
    (roll-back-machine delegate)))


;;;
;;; Environment type.
;;;

(define hetzner-environment-type
  (environment-type
   (machine-remote-eval hetzner-remote-eval)
   (deploy-machine      deploy-hetzner)
   (roll-back-machine   roll-back-hetzner)
   (name                'hetzner-environment-type)
   (description         "Provisioning of \"droplets\": virtual machines
 provided by the Hetzner virtual private server (VPS) service.")))


(define (maybe-raise-missing-api-key-error)
  (unless (%hetzner-token)
    (raise (condition
            (&message
             (message (G_ "No Hetzner access token was provided. This \
may be fixed by setting the environment variable GUIX_HETZNER_TOKEN to \
one procured from https://docs.hetzner.com/cloud/api/getting-started/generating-api-token.")))))))

(define (maybe-raise-unsupported-configuration-error machine)
  "Raise an error if MACHINE's configuration is not an instance of
<hetzner-configuration>."
  (let ((config (machine-configuration machine))
        (environment (environment-type-name (machine-environment machine))))
    (unless (and config (hetzner-configuration? config))
      (raise (formatted-message (G_ "unsupported machine configuration '~a' \
for environment of type '~a'")
                                config
                                environment)))))

(use-modules (scratch))
;; (hetzner-configuration? (machine-configuration %hetzner-machine))
;; (machine-wait-until-available %hetzner-machine)
;; (maybe-raise-unsupported-configuration-error %hetzner-machine)
;; (deploy-hetzner %hetzner-machine)

;; (fetch-endpoint "/v1/images")
;; (fetch-endpoint "/v1/servers")
;; (fetch-endpoint "/v1/server_types")
;; (%hetzner-token)

;; (map (lambda (x) (assoc-ref x "name"))
;;      (vector->list (assoc-ref (fetch-endpoint "/v1/server_types") "server_types")))

;; ./pre-inst-env guix shell guile-next guile-ares-rs -- guile -c '((@ (ares server) run-nrepl-server))'
