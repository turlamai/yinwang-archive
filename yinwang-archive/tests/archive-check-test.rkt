#lang racket/base
(require rackunit racket/file "../archive-check.rkt" "../archive-gaps.rkt" racket/string)

(test-case "local image references are checked without network access"
  (define root (make-temporary-file "inkvault-check-~a" 'directory))
  (dynamic-wind
    void
    (lambda ()
      (make-directory* (build-path root "images" "test"))
      (call-with-output-file (build-path root "images" "test" "a b.png")
        (lambda (out) (display "fixture" out)))
      (call-with-output-file (build-path root "images" "test" "empty.png") void)
      (check-equal?
       (missing-local-images root
         (string-append "<img alt=\"x\" src=\"/images/test/a%20b.png\">"
                        "<img src='/images/test/missing.png'>"
                        "<img src=\"/images/test/empty.png\">"
                        "<img src=\"https://example.invalid/no.png\">"
                        "&lt;img src=\"/images/test/code.png\"&gt;"))
       '("/images/test/missing.png" "/images/test/empty.png")))
    (lambda () (delete-directory/files root))))

(test-case "known gaps are labelled rather than replaced with invented images"
  (define html (annotate-missing-images
                "<img src=\"/images/computer-science/adder.png\"><img src=\"/images/test/valid.png\">"))
  (check-true (string-contains? html "历史存档图片缺失：adder.png"))
  (check-false (string-contains? html "src=\"/images/computer-science/adder.png\""))
  (check-true (string-contains? html "<img src=\"/images/test/valid.png\">")))
