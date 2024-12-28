(define-module (gnu packages deployment)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (guix build-system go)
  #:use-module (guix build-system copy)
  #:use-module (guix gexp)
  #:use-module (guix git-download)
  #:use-module (guix packages)
  #:use-module (guix utils)
  #:use-module (gnu packages)
  #:use-module (gnu packages cmake)
  #:use-module (gnu packages prometheus)
  #:use-module (gnu packages freedesktop)
  #:use-module (gnu packages gcc)
  #:use-module (gnu packages golang)
  #:use-module (gnu packages golang-build)
  #:use-module (gnu packages golang-xyz)
  #:use-module (gnu packages golang-check)
  #:use-module (gnu packages golang-compression)
  #:use-module (gnu packages golang-crypto)
  #:use-module (gnu packages golang-maths)
  #:use-module (gnu packages golang-web)
  #:use-module (gnu packages linux)
  #:use-module (gnu packages specifications)
  #:use-module (gnu packages xdisorg)
  #:use-module (gnu packages xorg))

(define-public go-github-com-fatih-structs
  (package
    (name "go-github-com-fatih-structs")
    (version "1.1.0")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/fatih/structs")
             (commit (string-append "v" version))))
       (file-name (git-file-name name version))
       (sha256
        (base32 "1wrhb8wp8zpzggl61lapb627lw8yv281abvr6vqakmf569nswa9q"))))
    (build-system go-build-system)
    (arguments
     (list
      #:import-path "github.com/fatih/structs"))
    (home-page "https://github.com/fatih/structs")
    (synopsis "Structs")
    (description
     "Package structs contains various utilities functions to work with structs.")
    (license license:expat)))

(define-public go-github-com-guptarohit-asciigraph
  (package
    (name "go-github-com-guptarohit-asciigraph")
    (version "0.7.3")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/guptarohit/asciigraph")
             (commit (string-append "v" version))))
       (file-name (git-file-name name version))
       (sha256
        (base32 "1j708hj80hk1b39zbdfx6kqy75i70jhz55bml0jngqwfx698d1pv"))))
    (build-system go-build-system)
    (arguments
     (list
      #:import-path "github.com/guptarohit/asciigraph"))
    (home-page "https://github.com/guptarohit/asciigraph")
    (synopsis "asciigraph")
    (description "Go package to make lightweight ASCII line graphs ???.")
    (license license:bsd-3)))

(define-public go-github-com-jmattheis-goverter
  (package
    (name "go-github-com-jmattheis-goverter")
    (version "1.7.0")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/jmattheis/goverter")
             (commit (string-append "v" version))))
       (file-name (git-file-name name version))
       (sha256
        (base32 "0ph8470wxpf8p2cdr5w3hkchlgpiyzljlsdna9jvhgw53sf2c32n"))))
    (build-system go-build-system)
    (arguments
     (list
      #:import-path "github.com/jmattheis/goverter"
      #:tests? #f))
    (propagated-inputs (list go-gopkg-in-yaml-v3 go-golang-org-x-tools
                             go-github-com-stretchr-testify
                             go-github-com-dave-jennifer))
    (home-page "https://github.com/jmattheis/goverter")
    (synopsis "Features")
    (description
     "goverter is a tool for creating type-safe converters.  All you have to do is
create an interface and execute goverter.  The project is meant as alternative
to @@url{https://github.com/jinzhu/copier,jinzhu/copier} that doesn't use
reflection.")
    (license license:expat)))

(define-public go-github-com-vburenin-ifacemaker
  (package
    (name "go-github-com-vburenin-ifacemaker")
    (version "1.2.1")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/vburenin/ifacemaker")
             (commit (string-append "v" version))))
       (file-name (git-file-name name version))
       (sha256
        (base32 "00031373i4xqrsaf7yv93czfmcf5qzn94mmqwamyjd6gpq37p1hl"))))
    (build-system go-build-system)
    (arguments
     (list
      #:import-path "github.com/vburenin/ifacemaker"))
    (propagated-inputs (list go-golang-org-x-tools
                             go-github-com-stretchr-testify
                             go-github-com-jessevdk-go-flags))
    (home-page "https://github.com/vburenin/ifacemaker")
    (synopsis "ifacemaker")
    (description
     "This is a development helper program that generates a Golang interface by
inspecting the structure methods of an existing @@code{.go} file.  The primary
use case is to generate interfaces for gomock, so that gomock can generate mocks
from those interfaces.  This makes unit testing easier.")
    (license license:asl2.0)))

(define-public go-github-com-hetznercloud-hcloud-go
  (package
    (name "go-github-com-hetznercloud-hcloud-go")
    (version "2.17.1")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/hetznercloud/hcloud-go")
             (commit (string-append "v" version))))
       (file-name (git-file-name name version))
       (sha256
        (base32 "0rmrp100clcymz6j741dpvx217d6ljnfqn9qfndlmy9rwi64ih8h"))))
    (build-system go-build-system)
    (arguments
     (list
      #:import-path "github.com/hetznercloud/hcloud-go/hcloud"
      #:unpack-path "github.com/hetznercloud/hcloud-go"))
    (propagated-inputs (list go-golang-org-x-net
                             go-golang-org-x-crypto
                             go-github-com-vburenin-ifacemaker
                             go-github-com-stretchr-testify
                             go-github-com-prometheus-client-golang
                             go-github-com-jmattheis-goverter
                             go-github-com-google-go-cmp))
    (home-page "https://github.com/hetznercloud/hcloud-go")
    (synopsis "hcloud: A Go library for the Hetzner Cloud API")
    (description "Package hcloud is a library for the Hetzner Cloud API.")
    (license license:expat)))

(define-public go-github-com-jedib0t-go-pretty-list
  (package
    (name "go-github-com-jedib0t-go-pretty-list")
    (version "6.6.5")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/jedib0t/go-pretty")
             (commit (string-append "v" version))))
       (file-name (git-file-name name version))
       (sha256
        (base32 "0sy8fia04lxi07yga7z3h3fp19y4bla5p16v1n7ldip0ymdmvjnx"))))
    (build-system go-build-system)
    (arguments
     (list
      #:import-path "github.com/jedib0t/go-pretty/list"
      #:unpack-path "github.com/jedib0t/go-pretty"))
    (propagated-inputs (list go-golang-org-x-text
                             go-golang-org-x-term
                             go-golang-org-x-sys
                             go-github-com-stretchr-testify
                             go-github-com-pkg-profile
                             go-github-com-mattn-go-runewidth))
    (home-page "https://github.com/jedib0t/go-pretty")
    (synopsis "go-pretty")
    (description
     "Utilities to prettify console output of tables, lists, progress-bars, text, etc.
 with a heavy emphasis on customization.")
    (license license:expat)))

(define-public go-github-com-jedib0t-go-pretty-progress
  (package
    (inherit go-github-com-jedib0t-go-pretty-list)
    (name "go-github-com-jedib0t-go-pretty-progress")
    (arguments
     (list
      #:import-path "github.com/jedib0t/go-pretty/progress"
      #:unpack-path "github.com/jedib0t/go-pretty"))
    (synopsis "go-pretty")
    (description
     "Utilities to prettify console output of tables, lists, progress-bars, text, etc.
 with a heavy emphasis on customization.")))

(define-public go-github-com-jedib0t-go-pretty-table
  (package
    (inherit go-github-com-jedib0t-go-pretty-list)
    (name "go-github-com-jedib0t-go-pretty-table")
    (arguments
     (list
      #:import-path "github.com/jedib0t/go-pretty/table"
      #:unpack-path "github.com/jedib0t/go-pretty"))
    (synopsis "go-pretty")
    (description
     "Utilities to prettify console output of tables, lists, progress-bars, text, etc.
 with a heavy emphasis on customization.")))

(define-public go-github-com-jedib0t-go-pretty-text
  (package
    (inherit go-github-com-jedib0t-go-pretty-list)
    (name "go-github-com-jedib0t-go-pretty-text")
    (arguments
     (list
      #:import-path "github.com/jedib0t/go-pretty/text"
      #:unpack-path "github.com/jedib0t/go-pretty"))
    (synopsis "go-pretty")
    (description
     "Utilities to prettify console output of tables, lists, progress-bars, text, etc.
 with a heavy emphasis on customization.")))

(define-public go-github-com-bool64-dev
  (package
    (name "go-github-com-bool64-dev")
    (version "0.2.37")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/bool64/dev")
             (commit (string-append "v" version))))
       (file-name (git-file-name name version))
       (sha256
        (base32 "041ng9z0qbmbj0l7lpj55d681b7p35lrr8vcyv3iqc1m6jzqqg5q"))))
    (build-system go-build-system)
    (arguments
     (list
      #:import-path "github.com/bool64/dev"))
    (home-page "https://github.com/bool64/dev")
    (synopsis "Go development helpers")
    (description "Package dev contains reusable development helpers.")
    (license license:expat)))

(define-public go-github-com-bool64-shared
  (package
    (name "go-github-com-bool64-shared")
    (version "0.1.5")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/bool64/shared")
             (commit (string-append "v" version))))
       (file-name (git-file-name name version))
       (sha256
        (base32 "157k7vw9cq84i5yy8bab8n1dk2lc9cmz8kjjy710ic9lwridmnf8"))))
    (build-system go-build-system)
    (arguments
     (list
      #:import-path "github.com/bool64/shared"))
    (propagated-inputs (list go-github-com-stretchr-testify
                             go-github-com-bool64-dev))
    (home-page "https://github.com/bool64/shared")
    (synopsis "Shared Vars")
    (description "Package shared provides space to share variables.")
    (license license:expat)))

(define-public go-github-com-iancoleman-orderedmap
  (package
    (name "go-github-com-iancoleman-orderedmap")
    (version "0.3.0")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/iancoleman/orderedmap")
             (commit (string-append "v" version))))
       (file-name (git-file-name name version))
       (sha256
        (base32 "1rkahhb86ngvzjmdlrpw9rx24a0b1yshq2add1ry2ii6nkx0xbfs"))))
    (build-system go-build-system)
    (arguments
     (list
      #:import-path "github.com/iancoleman/orderedmap"))
    (home-page "https://github.com/iancoleman/orderedmap")
    (synopsis "orderedmap")
    (description
     "This package provides a golang data type equivalent to python's
collections.@code{OrderedDict}.")
    (license license:expat)))

(define-public go-github-com-yosuke-furukawa-json5
  (package
    (name "go-github-com-yosuke-furukawa-json5")
    (version "0.1.1")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/yosuke-furukawa/json5")
             (commit (string-append "v" version))))
       (file-name (git-file-name name version))
       (sha256
        (base32 "1bcghdrx66v65bxlhfq9dvhbicnps9110wxza1gd5wx9x121mbr9"))))
    (build-system go-build-system)
    (arguments
     (list
      #:import-path "github.com/yosuke-furukawa/json5"))
    (home-page "https://github.com/yosuke-furukawa/json5")
    (synopsis #f)
    (description #f)
    (license #f)))

(define-public go-github-com-sergi-go-diff-diffmatchpatch
  (package
    (name "go-github-com-sergi-go-diff-diffmatchpatch")
    (version "1.3.1")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/sergi/go-diff")
             (commit (string-append "v" version))))
       (file-name (git-file-name name version))
       (sha256
        (base32 "0c7lsa3kjxbrx66r93d0pvx1408b80ignpi39fzka1qc0ylshw32"))))
    (build-system go-build-system)
    (arguments
     (list
      #:import-path "github.com/sergi/go-diff/diffmatchpatch"
      #:unpack-path "github.com/sergi/go-diff"))
    (propagated-inputs (list go-github-com-stretchr-testify))
    (home-page "https://github.com/sergi/go-diff")
    (synopsis "go-diff")
    (description
     "go-diff offers algorithms to perform operations required for synchronizing plain
text:.")
    (license license:expat)))

(define-public go-github-com-yudai-golcs
  (package
    (name "go-github-com-yudai-golcs")
    (version "0.0.0-20170316035057-ecda9a501e82")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/yudai/golcs")
             (commit (go-version->git-ref version))))
       (file-name (git-file-name name version))
       (sha256
        (base32 "0mx6wc5fz05yhvg03vvps93bc5mw4vnng98fhmixd47385qb29pq"))))
    (build-system go-build-system)
    (arguments
     (list
      #:import-path "github.com/yudai/golcs"))
    (home-page "https://github.com/yudai/golcs")
    (synopsis "Go Longest Common Subsequence (LCS)")
    (description
     "package lcs provides functions to calculate Longest Common Subsequence (LCS)
values from two arbitrary arrays.")
    (license license:expat)))

(define-public go-github-com-onsi-ginkgo
  (package
    (name "go-github-com-onsi-ginkgo")
    (version "1.16.5")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/onsi/ginkgo")
             (commit (string-append "v" version))))
       (file-name (git-file-name name version))
       (sha256
        (base32 "1hh6n7q92y0ai8k6rj2yzw6wwxikhyiyk4j92zgvf1zad0gmqqmz"))))
    (build-system go-build-system)
    (arguments
     (list
      #:import-path "github.com/onsi/ginkgo"))
    (propagated-inputs (list go-golang-org-x-tools go-golang-org-x-sys
                             go-github-com-onsi-gomega
                             go-github-com-nxadm-tail
                             go-github-com-go-task-slim-sprig))
    (home-page "https://github.com/onsi/ginkgo")
    (synopsis "Ginkgo 2.0 Release Candidate is available!")
    (description "Ginkgo is a BDD-style testing framework for Golang.")
    (license license:expat)))

(define-public go-github-com-yudai-gojsondiff
  (package
    (name "go-github-com-yudai-gojsondiff")
    (version "1.0.0")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/yudai/gojsondiff")
             (commit (string-append "v" version))))
       (file-name (git-file-name name version))
       (sha256
        (base32 "0qnymi0027mb8kxm24mmd22bvjrdkc56c7f4q3lbdf93x1vxbbc2"))))
    (build-system go-build-system)
    (arguments
     (list
      #:import-path "github.com/yudai/gojsondiff"))
    (propagated-inputs (list go-github-com-sergi-go-diff-diffmatchpatch
                             go-github-com-yudai-golcs
                             go-github-com-onsi-ginkgo))
    (home-page "https://github.com/yudai/gojsondiff")
    (synopsis "Go JSON Diff (and Patch)")
    (description
     "Package gojsondiff implements \"Diff\" that compares two JSON objects and
generates Deltas that describes differences between them.  The package also
provides \"Patch\" that apply Deltas to a JSON object.")
    (license license:expat)))

(define-public go-github-com-swaggest-assertjson
  (package
    (name "go-github-com-swaggest-assertjson")
    (version "1.9.0")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/swaggest/assertjson")
             (commit (string-append "v" version))))
       (file-name (git-file-name name version))
       (sha256
        (base32 "0smxcs548dnchqqk4bys167xaawzz125qsvlvpa267fkhqrxk7f9"))))
    (build-system go-build-system)
    (arguments
     (list
      #:tests? #f
      #:import-path "github.com/swaggest/assertjson"))
    (propagated-inputs (list go-github-com-yudai-gojsondiff
                             go-github-com-yosuke-furukawa-json5
                             go-github-com-stretchr-testify
                             go-github-com-iancoleman-orderedmap
                             go-github-com-bool64-shared
                             go-github-com-bool64-dev))
    (home-page "https://github.com/swaggest/assertjson")
    (synopsis "JSON assertions")
    (description
     "Package assertjson implements JSON equality assertion for tests.")
    (license license:expat)))

(define-public go-github-com-hetznercloud-cli
  (package
    (name "go-github-com-hetznercloud-cli")
    (version "1.49.0")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/hetznercloud/cli")
             (commit (string-append "v" version))))
       (file-name (git-file-name name version))
       (sha256
        (base32 "0mgd1rv0i18h7jbzl034ffpfxvnjirp60qwxsjpfy42jh1d8xbjm"))))
    (build-system go-build-system)
    (arguments
     (list
      ;; #:go 1.22
      #:import-path "github.com/hetznercloud/cli"

      ;; #:import-path "github.com/hetznercloud/cli/cmd/hcloud"
      ;; #:unpack-path "github.com/hetznercloud/cli"
      ;; #:import-path "github.com/sergi/go-diff/diffmatchpatch"
      ;; #:unpack-path "github.com/sergi/go-diff"
      ))
    (propagated-inputs (list go-golang-org-x-term
                             go-golang-org-x-crypto
                             go-go-uber-org-mock
                             go-github-com-swaggest-assertjson
                             go-github-com-stretchr-testify
                             go-github-com-spf13-viper
                             go-github-com-spf13-pflag
                             go-github-com-spf13-cobra
                             go-github-com-spf13-cast
                             go-github-com-jedib0t-go-pretty-list
                             go-github-com-jedib0t-go-pretty-progress
                             go-github-com-jedib0t-go-pretty-table
                             go-github-com-jedib0t-go-pretty-text
                             go-github-com-hetznercloud-hcloud-go
                             go-github-com-guptarohit-asciigraph
                             go-github-com-goccy-go-yaml
                             go-github-com-fatih-structs
                             go-github-com-fatih-color
                             go-github-com-dustin-go-humanize
                             go-github-com-cheggaaa-pb-v3
                             go-github-com-burntsushi-toml))
    (home-page "https://github.com/hetznercloud/cli")
    (synopsis "hcloud: Command-line interface for Hetzner Cloud")
    (description
     "@@code{hcloud} is a command-line interface for interacting with Hetzner Cloud.")
    (license license:expat)))
