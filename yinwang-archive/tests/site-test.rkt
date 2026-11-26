#lang racket/base

;; Tests for page templates: footer links, the wechat page, sitemap.

(require rackunit
         racket/string
         "../site.rkt"
         "../util.rkt")

(define post
  (list (cons 'title "测试文章")
        (cons 'slug "test")
        (cons 'author "王垠")
        (cons 'created "2026-01-01")
        (cons 'updated #f)
        (cons 'source "https://yinwang.org/posts/test")
        (cons 'html "<p>正文</p>")
        (cons 'url "/posts/test/")))

(test-case "archive pages have no promotion or third-party tracking"
  (for ([html (in-list (list (post-page post #f #f) (index-page (list post) 0 1)))])
    (for ([unwanted (in-list '("cloud.umami.is" "/wechat/" "wechat-qr.jpg" "https://jrtx.site/" "adsbygoogle" "google-adsense-account" "follow-card"))])
      (check-false (string-contains? html unwanted)))
    (check-true (string-contains? html "存档说明与版权更正"))
    (check-true (string-contains? html "/feed.xml"))))

(test-case "historical status and source attribution"
  (check-true (string-contains? (index-page (list post) 0 1) "停止自动采集"))
  (check-true (string-contains? (post-page post #f #f) "https://yinwang.org/posts/test"))
  (check-true (string-contains? (post-page post #f #f) "王垠")))

(test-case "stylesheet link is content-hash cache-busted"
  (check-true (string-contains? (post-page post #f #f) "main.css?v=")))

(test-case "sitemap excludes retired promotion"
  (check-false (string-contains? (sitemap-xml (list post) 1) "/wechat/"))
  (check-true (string-contains? (sitemap-xml (list post) 1) "/posts/test/")))
