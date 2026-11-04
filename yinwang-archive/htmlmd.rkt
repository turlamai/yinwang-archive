#lang racket/base

;; content_html -> Markdown conversion for the redesigned yinwang.org API
;; (2026 backend: every post body is served as `content_html`, replacing
;; the old Markdown `content` field). Renders the small tag vocabulary
;; the blog emits — p, h1-h6 with injected heading anchors, strong/em,
;; code, pre, a, img (with width), ul/ol/li, blockquote, br, hr — into
;; the same Markdown dialect the archive has always stored, so the
;; downstream format-content chain and the lint gate keep working.

;; HTML entities are decoded by hand before parsing (the catalog
;; markdown/html parser silently DROPS entity runs from text) by mapping
;; them to private-use-area placeholders, then restoring the real
;; characters on the final Markdown string. PUA codepoints cannot occur
;; in the blog content, so the round trip is exact.

(require markdown/html
         (prefix-in p: parsack) ; `string` here is a combinator that would shadow racket's
         racket/list
         racket/string
         "util.rkt")

(provide html->markdown)

;; ---- entity pre-encoding ----

;; entity (with delimiters) -> placeholder char; restore maps the char
;; back to the decoded literal character
(define entity-placeholders
  '(("&lt;" #\uE000 "<")
    ("&gt;" #\uE001 ">")
    ("&amp;" #\uE002 "&")
    ("&quot;" #\uE003 "\"")
    ("&apos;" #\uE004 "'")))

;; numeric and unknown-named markers bracket their payload with distinct
;; PUA chars so the restore pass can find them verbatim
(define numeric-dec-open #\uE010)
(define numeric-dec-close #\uE011)
(define numeric-hex-open #\uE012)
(define numeric-hex-close #\uE013)
(define named-open #\uE014)
(define named-close #\uE015)

(define entity-re
  (regexp (string-append "&[a-zA-Z][a-zA-Z0-9]*;"
                         "|&#[0-9]+;"
                         "|&#[xX][0-9a-fA-F]+;")))

;; &nbsp; becomes a normal space (old archive files never carry U+00A0)
(define named-entity-chars
  '(("nbsp" . " ")
    ("mdash" . "—")
    ("ndash" . "–")
    ("hellip" . "…")
    ("copy" . "©")
    ("reg" . "®")
    ("trade" . "™")
    ("times" . "×")
    ("middot" . "·")
    ("laquo" . "«")
    ("raquo" . "»")
    ("ldquo" . "“")
    ("rdquo" . "”")
    ("lsquo" . "‘")
    ("rsquo" . "’")))

(define (encode-entities html)
  (regexp-replace* entity-re html
                   (λ (ent)
                     (or (for/first ([row (in-list entity-placeholders)]
                                     #:when (equal? ent (car row)))
                           (string (cadr row)))
                         (let* ([body (substring ent 1 (sub1 (string-length ent)))]
                                [decoded
                                 (cond
                                   [(char=? (string-ref body 0) #\#)
                                    (cond
                                      [(memv (string-ref body 1) '(#\x #\X))
                                       (string-append (string numeric-hex-open)
                                                      (substring body 2)
                                                      (string numeric-hex-close))]
                                      [else
                                       (string-append (string numeric-dec-open)
                                                      (substring body 1)
                                                      (string numeric-dec-close))])]
                                   [(assoc body named-entity-chars) => cdr]
                                   ;; unknown named entity: preserve verbatim
                                   [else
                                    (string-append (string named-open)
                                                   body
                                                   (string named-close))])])
                           decoded)))))

(define (restore-entities s)
  (define step1
    (for/fold ([s s]) ([row (in-list entity-placeholders)])
      (string-replace s (string (cadr row)) (caddr row))))
  (define step2
    (regexp-replace*
     (regexp (string-append (string numeric-dec-open) "[0-9]+" (string numeric-dec-close)))
     step1
     (λ (m)
       (string (integer->char
                (string->number
                 (substring m 1 (sub1 (string-length m)))))))))
  (define step3
    (regexp-replace*
     (regexp (string-append (string numeric-hex-open) "[0-9a-fA-F]+" (string numeric-hex-close)))
     step2
     (λ (m)
       (string (integer->char
                (string->number
                 (substring m 1 (sub1 (string-length m)))
                 16))))))
  ;; unknown named entities come back as literal text, e.g. "&foobar;"
  (regexp-replace*
   (regexp (string-append (string named-open) "[a-zA-Z0-9]+" (string named-close)))
   step3
   (λ (m)
     (string-append "&"
                    (substring m 1 (sub1 (string-length m)))
                    ";"))))

;; ---- xexpr helpers ----

;; the parser hands back (tag ((name "value") ...) kid ...) with string
;; attribute names (always present, possibly empty) plus bare strings
;; for text
(define (xe-tag? x)
  (and (pair? x) (symbol? (car x))))

(define (xe-name x) (car x))

(define (attr-list? v)
  (and (list? v)
       (andmap (λ (kv) (and (pair? kv)
                            (or (string? (car kv)) (symbol? (car kv)))))
               v)))

(define (xe-attrs x)
  (if (and (pair? (cdr x)) (attr-list? (cadr x))) (cadr x) '()))

(define (xe-kids x)
  (if (and (pair? (cdr x)) (attr-list? (cadr x))) (cddr x) (cdr x)))

;; attribute names come back as symbols; callers pass plain strings
(define (xe-attr x name)
  (for/first ([kv (in-list (xe-attrs x))]
              #:when (equal? (format "~a" (car kv)) name))
    (cadr kv)))

;; ---- text handling ----

;; whitespace collapses per HTML semantics: a run of blank text between
;; inline tags becomes one space (util shims' ws-line-chars is space+tab
;; only — inline text also needs newlines folded)
(define inline-ws (string #\space #\tab #\return #\newline))

(define (inline-text s)
  (regexp-replace* (regexp (string-append "[" inline-ws "]+")) s " "))

;; ---- inline rendering ----

;; renders children as inline Markdown; returns a string without newlines
(define (render-inline nodes)
  (apply string-append (map render-inline-node nodes)))

(define (heading-anchor? n)
  (define cls (xe-attr n "class"))
  (and (string? cls)
       (ormap (λ (c) (equal? c "heading-anchor")) (string-split cls " "))))

(define (render-inline-node n)
  (cond
    [(string? n) (inline-text n)]
    [(not (xe-tag? n)) ""]
    [else
     (case (xe-name n)
       [(a) (render-a n)]
       [(strong b) (wrap-marker "**" n)]
       [(em i) (wrap-marker "*" n)]
       [(code) (wrap-code n)]
       [(img) (render-img n)]
       [(br) "<br>"]
       ;; unknown or purely presentational inline tags: keep their content
       [else (render-inline (xe-kids n))])]))

(define (wrap-marker mark n)
  (define inner (string-trim (render-inline (xe-kids n))))
  (if (equal? inner "") "" (string-append mark inner mark)))

;; code spans need one more backtick than the longest backtick run inside;
;; spaces are added when the span would otherwise fuse with the content
(define (wrap-code n)
  (define inner (apply string-append (map (λ (k) (if (string? k) k "")) (xe-kids n))))
  (cond
    [(equal? inner "") ""]
    [else
     (define fence
       (let loop ([len 1])
         (if (regexp-match? (regexp (make-string len #\`)) inner)
             (loop (add1 len))
             len)))
     (define padded
       (or (and (or (> fence 1)
                    (not (equal? inner (string-trim inner))))
                (string-append " " inner " "))
           inner))
     (string-append (make-string fence #\`) padded (make-string fence #\`))]))

(define (escape-link-text s)
  ;; `]` inside bracketed link text would close the link early
  (string-replace s "]" "\\]"))

(define (render-a n)
  (define href (xe-attr n "href"))
  (define inner (string-trim (render-inline (xe-kids n))))
  (cond
    ;; self-referencing heading anchors injected by the blog frontend
    [(heading-anchor? n) inner]
    [(equal? inner "") ""]
    [(not href) inner]
    [else
     (format "[~a](~a)" (escape-link-text inner) href)]))

;; <img> — the archive keeps the HTML form when a width is present
;; (Markdown image syntax cannot carry one), plain Markdown otherwise
(define (render-img n)
  (define src (xe-attr n "src"))
  (define width (xe-attr n "width"))
  (define alt (or (xe-attr n "alt") ""))
  (cond
    [(not src) ""]
    [(and (string? width) (not (equal? width "")))
     (format "<img src=\"~a\" width=\"~a\">" (clean-img-src src) width)]
    [else
     (format "![~a](~a)" alt (clean-img-src src))]))

;; strip query/fragment the same way the crawler names downloaded files,
;; so the rewritten /images/{slug}/… reference resolves to disk
(define (clean-img-src src)
  (car (string-split (car (string-split src "#" #:trim? #f)) "?" #:trim? #f)))

;; ---- block rendering ----

;; renders one block node into a Markdown block (no trailing newlines);
;; #f means the node yields nothing
(define (render-block n)
  (cond
    [(string? n) #f] ; inter-block whitespace
    [(not (xe-tag? n)) #f]
    [else
     (case (xe-name n)
       [(p) (render-paragraph n)]
       [(h1 h2 h3 h4 h5 h6) (render-heading n)]
       [(ul ol) (render-list n)]
       [(blockquote) (render-blockquote n)]
       [(pre) (render-pre n)]
       [(hr) "---"]
       [(img) (render-img n)]
       ;; container / unknown block: splice children through
       [else (blocks->text (render-blocks (xe-kids n)))])]))

(define (render-paragraph n)
  (define inner (string-trim (render-inline (xe-kids n))))
  (and (not (equal? inner "")) inner))

;; content headings never outrank the file title: h1/h2 demote to ##,
;; h3 stays, h4+ collapse to a bold line (archive rule: no #### or deeper)
(define (render-heading n)
  (define level (case (xe-name n) [(h1 h2) 2] [(h3) 3] [else 0]))
  (define inner (string-trim (render-inline (xe-kids n))))
  (cond
    [(equal? inner "") #f]
    [(zero? level) (string-append "**" inner "**")]
    [else (format "~a ~a" (make-string level #\#) inner)]))

(define (render-blockquote n)
  (define paras (render-blocks (xe-kids n)))
  (define groups
    (for/list ([block (in-list paras)])
      (string-join
       (for/list ([line (in-list (string-split block "\n"))])
         (if (equal? (string-trim line) "")
             ">"
             (string-append "> " line)))
       "\n")))
  (string-join groups "\n>\n"))

;; list items: inline content joined into one line, nested lists indented
;; two spaces below the item text
(define (render-list n)
  (define tag (xe-name n))
  (define start
    (let ([s (and (eq? tag 'ol) (xe-attr n "start"))])
      (or (and s (string->number s)) 1)))
  (define lines
    (append*
     (for/list ([li (in-list (filter xe-tag? (xe-kids n)))]
                [i (in-naturals)])
       (render-list-item li tag (if (eq? tag 'ol) (+ start i) 0)))))
  (string-join lines "\n"))

(define (list-item-part? k)
  (not (and (xe-tag? k) (memq (xe-name k) '(ul ol)))))

(define (render-list-item li tag index)
  (define marker (if (eq? tag 'ol) (format "~a." index) "-"))
  (define kids (xe-kids li))
  (define nested (filter (λ (k) (not (list-item-part? k))) kids))
  (define inline-parts
    (for/list ([k (in-list kids)] #:when (list-item-part? k))
      (cond
        [(string? k) (inline-text k)]
        ;; a p inside a loose item stays on the item line
        [else (render-block k)])))
  (define item-text
    (string-trim (string-join (filter (λ (s) (and s (not (equal? s "")))) inline-parts) " ")))
  (define head
    (if (equal? item-text "")
        marker
        (string-append marker " " item-text)))
  (define tail
    (for/list ([sub (in-list nested)])
      (indent-block (render-block sub) 2)))
  (cons head tail))

(define (indent-block block n)
  (string-join
   (for/list ([line (in-list (string-split block "\n"))])
     (string-append (make-string n #\space) line))
   "\n"))

;; <pre> — the parser preserves its content verbatim (tags included), so
;; strip real markup tags and emit a fence; the format pipeline expects
;; fences for code (top-level indented blocks break the render chain)
(define (render-pre n)
  (define kids (xe-kids n))
  (define raw
    (apply string-append
           (for/list ([k (in-list kids)])
             (cond
               [(string? k) k]
               [(xe-tag? k) (pre-text (xe-kids k))]
               [else ""]))))
  (define stripped
    (string-trim (regexp-replace* (regexp "<[^>\n]+>") raw "")
                 (regexp (string-append "[" ws-line-chars "\\n]"))
                 #:left? #f
                 #:right? #t))
  ;; the parser keeps <pre> content as one raw string, so the language
  ;; comes from the literal <code class="language-x"> opening tag
  (define lang
    (let ([m (regexp-match
              (regexp "<code[^>]*class=\"[^\"]*language-([^\" ]+)") raw)])
      (and m (cadr m))))
  (fence-block stripped (or lang "")))

(define (pre-text kids)
  (apply string-append
         (for/list ([k (in-list kids)])
           (cond
             [(string? k) k]
             [(xe-tag? k) (pre-text (xe-kids k))]
             [else ""]))))

(define (fence-block text lang)
  ;; grow the fence until it outlasts any backtick run in the content
  (define fence-len
    (let loop ([n 3])
      (if (regexp-match? (regexp (make-string n #\`)) text)
          (loop (add1 n))
          n)))
  (define fence (make-string fence-len #\`))
  ;; unlanguaged code still gets a marker (archive convention)
  (string-append fence (if (equal? lang "") "text" lang) "\n" text "\n" fence))

;; ---- top level ----

(define (render-blocks nodes)
  (filter values (map render-block nodes)))

(define (blocks->text blocks)
  (string-join blocks "\n\n"))

;; string -> Markdown. Accepts the post body exactly as the API delivers
;; it (a fragment, not a full document); the parser requires a document
;; wrapper, so the fragment is padded and the body extracted afterwards.
(define (html->markdown html)
  (define padded (string-append "<html><body>" html "</body></html>"))
  (define xexpr (p:parse-result $html-document (encode-entities padded)))
  (define body
    (or (for/first ([k (in-list (xe-kids xexpr))]
                    #:when (and (xe-tag? k) (equal? (xe-name k) 'body)))
          k)
        xexpr))
  (restore-entities (blocks->text (render-blocks (xe-kids body)))))

(module+ test
  (require rackunit)

  (test-case "entities survive the round trip"
    (check-equal?
     (html->markdown "<p>1 &lt; 2 且 5 &gt; 3 和 a &amp; b 与 x &quot;y&quot; z&#39;w&#39;</p>")
     "1 < 2 且 5 > 3 和 a & b 与 x \"y\" z'w'"))

  (test-case "unknown named entities are preserved verbatim"
    (check-equal?
     (html->markdown "<p>a &foobar; b</p>")
     "a &foobar; b"))

  (test-case "numeric entities decode to the character"
    (check-equal? (html->markdown "<p>&#20820; &#x9F8D;</p>") "兔 龍"))

  (test-case "double-escaped ampersand round trips"
    (check-equal? (html->markdown "<p>&amp;amp;</p>") "&amp;"))

  (test-case "paragraphs become blank-line separated text"
    (check-equal?
     (html->markdown "<p>第一段</p>\n<p>第二段</p>")
     "第一段\n\n第二段"))

  (test-case "heading anchors unwrap to plain heading text"
    (check-equal?
     (html->markdown "<h3 id=\"0af0\"><a class=\"heading-anchor\" href=\"#0af0\">课程方式</a></h3>")
     "### 课程方式"))

  (test-case "h4 collapses to a bold line"
    (check-equal?
     (html->markdown "<h4>建议使用食品级双氧水</h4>")
     "**建议使用食品级双氧水**"))

  (test-case "h1 and h2 demote to h2 so content never outranks the title"
    (check-equal? (html->markdown "<h1>大标题</h1>") "## 大标题"))

  (test-case "strong and em keep markers tight"
    (check-equal?
     (html->markdown "<p>采用 <strong>录像 + 辅导</strong> 和 <em>重点</em>。</p>")
     "采用 **录像 + 辅导** 和 *重点*。"))

  (test-case "links keep hrefs including mailto and queries"
    (check-equal?
     (html->markdown "<p><a href=\"/posts/cs5\">第五期</a> <a href=\"mailto:a@b.c?x=1&amp;y=2\">email</a></p>")
     "[第五期](/posts/cs5) [email](mailto:a@b.c?x=1&y=2)"))

  (test-case "br is preserved literally"
    (check-equal?
     (html->markdown "<p><a href=\"/a.pdf\">第 1 章</a><br>\n<a href=\"/b.pdf\">第 2 章</a><br></p>")
     "[第 1 章](/a.pdf)<br> [第 2 章](/b.pdf)<br>"))

  (test-case "images with width keep the HTML form and strip queries"
    (check-equal?
     (html->markdown "<img src=\"/images/eye.jpg?w=480\" width=\"50%\">")
     "<img src=\"/images/eye.jpg\" width=\"50%\">"))

  (test-case "images without width become markdown syntax"
    (check-equal?
     (html->markdown "<img src=\"/images/x.jpg\" alt=\"截图\">")
     "![截图](/images/x.jpg)"))

  (test-case "tight ul renders dashes with two-space nesting"
    (check-equal?
     (html->markdown "<ul><li>一项</li><li>两项<ul><li>嵌套</li></ul></li></ul>")
     "- 一项\n- 两项\n  - 嵌套"))

  (test-case "ol honors the start attribute"
    (check-equal?
     (html->markdown "<ol><li>第一</li></ol><ol start=\"2\"><li><p>两项</p></li><li>三项</li></ol>")
     "1. 第一\n\n2. 两项\n3. 三项"))

  (test-case "blockquote prefixes every line"
    (check-equal?
     (html->markdown "<blockquote><p>引用行</p></blockquote>")
     "> 引用行"))

  (test-case "blockquote paragraphs keep quote continuation"
    (check-equal?
     (html->markdown "<blockquote><p>一段</p><p>二段</p></blockquote>")
     "> 一段\n>\n> 二段"))

  (test-case "pre emits a fence with the code language and strips markup"
    (check-equal?
     (html->markdown
      "<pre><code class=\"language-scheme\">(define x 1)\n(display <span class=\"hljs-keyword\">x</span>)</code></pre>")
     "```scheme\n(define x 1)\n(display x)\n```"))

  (test-case "code with angle brackets survives inside pre"
    (check-equal?
     (html->markdown "<pre><code>#include &lt;stdio.h&gt;\nint x;</code></pre>")
     "```text\n#include <stdio.h>\nint x;\n```"))

  (test-case "inline code containing a backtick grows the delimiter"
    (check-equal?
     (html->markdown "<p><code>a`b</code></p>")
     "`` a`b ``"))

  (test-case "hr renders as three dashes"
    (check-equal? (html->markdown "<p>前</p><hr><p>后</p>") "前\n\n---\n\n后"))

  (test-case "whitespace between inline tags collapses to one space"
    (check-equal?
     (html->markdown "<p>来自 <a href=\"/p\">链接</a> 和 <code>代码</code>。</p>")
     "来自 [链接](/p) 和 `代码`。"))

  (test-case "empty paragraph is dropped"
    (check-equal? (html->markdown "<p>   </p><p>正文</p>") "正文"))

  (test-case "entities inside attribute values restore too"
    (check-equal?
     (html->markdown "<p><a href=\"/mail?x=1&amp;y=2\">m</a></p>")
     "[m](/mail?x=1&y=2)")))
