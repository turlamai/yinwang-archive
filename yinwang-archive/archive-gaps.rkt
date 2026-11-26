#lang racket/base
;; Explicit historical gaps: original assets absent from the current Git
;; tree and path history. No source download or fabricated replacement.
(require racket/string "util.rkt")
(provide known-missing-images annotate-missing-images)
(define known-missing-images
  '("/images/computer-science/adder.png"
    "/images/computer-science/adder-topdown.png"
    "/images/computer-science/add-mult.png"
    "/images/computer-science/expression-graph.png"
    "/images/computer-science/parallel.png"
    "/images/computer-science/function1.png"
    "/images/computer-science/function2.jpg"
    "/images/computer-science/wire.png"
    "/images/computer-science/rename.png"
    "/images/computer-science/branch.png"))
(define (annotate-missing-images html)
  (regexp-replace* (regexp (string-append "<img" ws-class "+[^>]*>")) html
    (lambda (tag)
      (define m (regexp-match (regexp (string-append ws-class "+src=\"([^\"]+)\"")) tag))
      (if (and m (member (cadr m) known-missing-images))
          (string-append "<span class=\"archive-image-missing\" role=\"note\">[历史存档图片缺失："
                         (html-escape (last-component (cadr m))) "]</span>")
          tag))))
(define (last-component path)
  (car (reverse (string-split path "/"))))
