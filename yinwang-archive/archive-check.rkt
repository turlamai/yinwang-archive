#lang racket/base

;; Offline integrity check: local Markdown is authoritative; the old
;; collector index is only a historical subset. Never contacts the source.
(require racket/file racket/path racket/string racket/list racket/dict
         json net/uri-codec "frontmatter.rkt" "util.rkt" "build.rkt" "archive-gaps.rkt")
(provide check-archive missing-local-images)

;; The renderer emits quoted src attributes. Check root-relative archived
;; images only, not external URLs or links embedded in article text.
(define image-tag-re
  (regexp (string-append "<img" ws-class "+[^>]*>")))
(define image-src-double-re
  (regexp (string-append ws-class "+src=\"(/images/[^\"#?]+)[^\"]*\"")))
(define image-src-single-re
  (regexp (string-append ws-class "+src='(/images/[^'#?]+)[^']*'")))

(define (missing-local-images root html)
  (remove-duplicates
   (for/list ([tag (in-list (regexp-match* image-tag-re html))]
              #:do [(define m (or (regexp-match image-src-double-re tag)
                                  (regexp-match image-src-single-re tag)))]
              #:when m
              #:do [(define url (cadr m))
                    (define decoded (uri-decode (string-replace url "&amp;" "&")))
                    (define parts (string-split (substring decoded 1) "/" #:trim? #f))]
              #:unless (and (andmap (lambda (p) (and (non-empty-string? p)
                                                    (not (member p '("." "..")))
                                                    (not (string-contains? p "\\"))))
                                    parts)
                            (let ([p (apply build-path root parts)])
                              (and (file-exists? p) (positive? (file-size p))))))
     url)))

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
  (define observed-gaps (make-hash))
  (for ([post (in-list (load-posts root))])
    (for ([src (in-list (missing-local-images root (dict-ref post 'html)))])
      (if (and (equal? (dict-ref post 'slug) "computer-science")
               (member src known-missing-images))
          (begin (hash-set! observed-gaps src #t)
                 (printf "Known historical gap: ~a\n" src))
          (err! (format "~a: missing or empty local image ~a" (dict-ref post 'slug) src)))))
  (for ([src (in-list known-missing-images)] #:unless (hash-has-key? observed-gaps src))
    (err! (format "Stale historical gap entry (review and remove): ~a" src)))
  (reverse errors))

(module+ main
  (define errors (check-archive (current-directory)))
  (for ([e (in-list errors)]) (displayln e))
  (exit (if (null? errors) 0 1)))
