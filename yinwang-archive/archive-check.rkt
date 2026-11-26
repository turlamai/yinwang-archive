#lang racket/base

;; Offline integrity check: local Markdown is authoritative; the old
;; collector index is only a historical subset. Never contacts the source.
(require racket/file racket/path racket/string racket/list racket/dict
         json "frontmatter.rkt" "util.rkt")
(provide check-archive)

(define (check-archive root)
  (define paths
    (sort (filter (lambda (p) (string-suffix? (path->string p) ".md"))
                  (directory-list (build-path root "posts") #:build? #t))
          path<?))
  (define seen (make-hash))
  (define errors '())
  (define (err! msg) (set! errors (cons msg errors)))
  (for ([p (in-list paths)])
    (define slug (path->string (path-replace-extension (file-name-from-path p) #"")))
    (define fm (parse-frontmatter (file->string p)))
    (hash-set! seen slug #t)
    (cond
      [(not fm) (err! (format "~a: missing frontmatter" slug))]
      [else
       (unless (equal? (dict-ref fm 'slug #f) slug)
         (err! (format "~a: frontmatter slug differs from filename" slug)))])
    (when (zero? (file-size p))
      (err! (format "~a: empty article" slug))))
  (define index (call-with-input-file (build-path root "index.json") read-json))
  (define posts (jref index 'posts))
  (unless (hash? posts) (error 'check-archive "invalid historical index"))
  (for ([k (in-list (hash-keys posts))])
    (define slug (if (symbol? k) (symbol->string k) k))
    (unless (hash-has-key? seen slug)
      (err! (format "~a: historical index points to missing article" slug))))
  (printf "Offline archive: ~a articles, ~a historical index entries\n"
          (length paths) (hash-count posts))
  (reverse errors))

(module+ main
  (define errors (check-archive (current-directory)))
  (for ([e (in-list errors)]) (displayln e))
  (exit (if (null? errors) 0 1)))
