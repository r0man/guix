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

(define-module (tests machine hetzner http)
  #:use-module (gnu machine hetzner http)
  #:use-module (guix build utils)
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-34)
  #:use-module (srfi srfi-64)
  #:use-module (ssh key))

;;; Tests for the (gnu machine hetzner api) module.

;; This test requires the GUIX_HETZNER_API_TOKEN environment variable to be set.
;; https://docs.hetzner.com/cloud/api/getting-started/generating-api-token

(define %server-name
  "guix-hetzner-api-test-server")

(define %ssh-key-name
  "guix-hetzner-api-test-key")

(define %ssh-key-file
  (string-append "/tmp/" %ssh-key-name))

(unless (file-exists? %ssh-key-file)
  (private-key-to-file (make-keypair 'rsa 2048) %ssh-key-file))

(define %ssh-key
  (hetzner-ssh-key-read-file %ssh-key-file))

(define %when-no-token
  (if (hetzner-api-token (hetzner-api)) 0 1))

(define* (create-ssh-key api ssh-key #:key (labels '()))
  (hetzner-api-ssh-key-create
   api
   (hetzner-ssh-key-name ssh-key)
   (hetzner-ssh-key-public-key ssh-key)
   #:labels labels))

(define (cleanup api)
  (let ((api (hetzner-api)))
    (for-each (lambda (ssh-key)
                (hetzner-api-ssh-key-delete api ssh-key))
              (hetzner-api-ssh-keys
               api #:params `(("name" . ,%ssh-key-name))))
    (for-each (lambda (server)
                (hetzner-api-server-delete api server))
              (hetzner-api-servers
               api #:params `(("name" . ,%server-name))))
    api))

(define-syntax-rule (with-cleanup-api (api-sym api-init) body ...)
  (let ((api-sym (cleanup api-init)))
    (dynamic-wind
      (const #t)
      (lambda ()
        body ...)
      (lambda ()
        (cleanup api-sym)))))

(test-begin "machine-hetzner-api")

(test-skip %when-no-token)
(test-assert "hetzner-api-actions"
  (with-cleanup-api (api (hetzner-api))
    (let* ((key (create-ssh-key api %ssh-key))
           (server (hetzner-api-server-create api %server-name (list key)))
           (action (hetzner-api-server-enable-rescue-system api server (list key)))
           (actions (hetzner-api-actions api (list (hetzner-action-id action)))))
      (equal? (list (hetzner-action-id action))
              (map hetzner-action-id actions)))))

(test-skip %when-no-token)
(test-assert "hetzner-api-locations"
  (every hetzner-location? (hetzner-api-locations (hetzner-api))))

(test-skip %when-no-token)
(test-assert "hetzner-api-server-types"
  (every hetzner-server-type? (hetzner-api-server-types (hetzner-api))))

(test-skip %when-no-token)
(test-assert "hetzner-api-server-create"
  (with-cleanup-api (api (hetzner-api))
    (let* ((key (create-ssh-key api %ssh-key))
           (server (hetzner-api-server-create api %server-name (list key))))
      (hetzner-server? server))))

(test-skip %when-no-token)
(test-assert "hetzner-api-server-delete"
  (with-cleanup-api (api (hetzner-api))
    (let* ((key (create-ssh-key api %ssh-key))
           (server (hetzner-api-server-create api %server-name (list key)))
           (action (hetzner-api-server-delete api server)))
      (hetzner-action? action))))

(test-skip %when-no-token)
(test-assert "hetzner-api-server-enable-rescue-system"
  (with-cleanup-api (api (hetzner-api))
    (let* ((key (create-ssh-key api %ssh-key))
           (server (hetzner-api-server-create api %server-name (list key)))
           (action (hetzner-api-server-enable-rescue-system api server (list key))))
      (hetzner-action? action))))

(test-skip %when-no-token)
(test-assert "hetzner-api-server-power-on"
  (with-cleanup-api (api (hetzner-api))
    (let* ((key (create-ssh-key api %ssh-key))
           (server (hetzner-api-server-create api %server-name (list key)))
           (action (hetzner-api-server-power-on api server)))
      (hetzner-action? action))))

(test-skip %when-no-token)
(test-assert "hetzner-api-server-power-off"
  (with-cleanup-api (api (hetzner-api))
    (let* ((key (create-ssh-key api %ssh-key))
           (server (hetzner-api-server-create api %server-name (list key)))
           (action (hetzner-api-server-power-off api server)))
      (hetzner-action? action))))

(test-skip %when-no-token)
(test-assert "hetzner-api-server-reboot"
  (with-cleanup-api (api (hetzner-api))
    (let* ((key (create-ssh-key api %ssh-key))
           (server (hetzner-api-server-create api %server-name (list key)))
           (action (hetzner-api-server-reboot api server)))
      (hetzner-action? action))))

(test-skip %when-no-token)
(test-assert "hetzner-api-servers"
  (every hetzner-server? (hetzner-api-servers (hetzner-api))))

(test-skip %when-no-token)
(test-assert "hetzner-api-ssh-key-create"
  (with-cleanup-api (api (hetzner-api))
    (let* ((api (cleanup (hetzner-api)))
           (key (create-ssh-key api %ssh-key)))
      (hetzner-ssh-key? key))))

(test-skip %when-no-token)
(test-assert "hetzner-api-ssh-key-delete"
  (with-cleanup-api (api (hetzner-api))
    (let* ((api (cleanup (hetzner-api)))
           (key (create-ssh-key
                 api %ssh-key
                 #:labels '(("environment" . "development")))))
      (hetzner-api-ssh-key-delete api key))))

(test-skip %when-no-token)
(test-assert "hetzner-api-ssh-keys"
  (every hetzner-ssh-key? (hetzner-api-ssh-keys (hetzner-api))))

(test-end "machine-hetzner-api")

;; Local Variables:
;; eval: (put 'with-cleanup-api 'scheme-indent-function 1)
;; End:
