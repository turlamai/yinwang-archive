# InkVault

Historical snapshot of [yinwang.org](https://yinwang.org) by Wang Yin. Automated collection ended on 2026-11-26 by maintainer decision. This independent archive preserves existing material only; it is not a current mirror or an official website.

![Racket](https://img.shields.io/badge/Racket-9E3E97?logo=racket&logoColor=white) [![License](https://img.shields.io/badge/license-MIT-blue)](LICENSE)

**English** · [中文](README.zh-CN.md)

## Read first

[Read the InkVault](https://yinwang.jrtx.site/) · [Reading, privacy and corrections](docs/READING.md)

Free reading archive, not the author’s official website. No scheduled or manual collection workflow remains. Archived copies may be outdated. Formatting, images and code may differ from the original, and Git history can retain earlier revisions. No paid content or ads are added.

## Features

- **Racket full-stack** — crawler, linter and static site generator are one Racket package (`raco yinwang-archive …`)
- **Historical snapshot** — rebuild from existing local articles without fetching the source
- **Full content archival** — posts saved as Markdown, images downloaded locally
- **Self-contained Markdown** — file name = URL slug, Chinese title in frontmatter, body starts with an H1 heading
- **Deduplication** — prevents duplicate files by tracking source URLs
- **Static site generation** — builds a searchable website (Racket, no Node) and deploys to GitHub Pages

## Project Structure

```
yinwang-archive/
├── posts/           # Markdown articles (file name = URL slug)
├── images/          # Post images (organized by URL slug)
├── yinwang-archive/       # Racket package: crawler, formatter, linter, site builder
├── assets/site/     # Static assets (styles, favicon, vendored highlight.js)
└── index.json       # Post metadata index
```

## Requirements

- [Racket](https://racket-lang.org) (stable; any 8.x+)

## Quick Start

### 1. Clone

```bash
git clone https://github.com/turlamai/yinwang-archive.git
cd yinwang-archive
```

### 2. Install the package

```bash
raco pkg install --auto --no-docs --link "$(pwd)"
```

### 3. Run the pipeline

```bash
# Validate all posts (CI gate)
raco yinwang-archive lint

# Build the static site (output: dist/)
raco yinwang-archive build
```

### Repair tools

```bash
raco yinwang-archive fix-bold-spacing [--check|--dry-run]  # heal `** text **` emphasis
raco yinwang-archive normalize-code [--check]              # indented code -> fences
```

All commands accept `--root DIR` to operate on a checkout elsewhere than
the current directory.

## Offline integrity

`posts/` is the authoritative archive. `index.json` is the historical collector index, not a complete catalog. At the retirement baseline there are 176 Markdown files and 130 collector entries; the 46 other files are retained without assuming why they are absent from the index. Run `racket yinwang-archive/archive-check.rkt` from the repository root to check filename/slug identity and missing indexed files. This check is offline; it does not establish image completeness or source availability.

## Historical implementation (inactive collector)

The collector is retained as historical source code, not a recommended operation. Do not resume automated collection without a new maintainer decision and respect for the source owner's access policy.

1. **Fetch post list** — the crawler calls `https://yinwang.org/api/v1/posts` with pagination (`skip`/`limit`) to get all post slugs.
2. **Deduplicate** — it builds an index of existing posts by `source` URL to avoid duplicates.
3. **Download each post** — for each slug, it fetches the full post body (`content_html`, HTML) from `https://yinwang.org/api/v1/posts/{slug}` and converts it to Markdown.
4. **Download images** — all images referenced in the post are downloaded to `images/{slug}/`.
5. **Format and save** — the converted Markdown is reformatted (CJK spacing, heading normalization, code fence conversion) and saved with YAML frontmatter. If most posts come back without a body, the crawl fails loudly instead of silently freezing the archive.
6. **Update index** — `index.json` is updated with metadata for each processed post (byte-compatible with the historical Python serializer, so no-op crawls stay diff-free).
7. **Build** — the site generator renders Markdown → HTML (heading anchors, fenced code with client-side highlight.js, Atom feed, search index, sitemap, llms.txt) into `dist/`.

### Post format

Each Markdown file is named after its URL slug and is fully self-contained:

```markdown
---
title: "My Blog Post"
slug: my-blog-post
author: 王垠
created: 2025-01-15
source: https://yinwang.org/posts/my-blog-post
---
# My Blog Post

## First Section

Body text...
```

- File name = `slug` (= URL `/posts/{slug}/` = image dir `images/{slug}/`).
- The Chinese title lives in frontmatter; the body starts with an H1 heading.
- Top-level sections use H2; the crawler normalizes heading depth and code fences automatically.

## RSS

The site publishes an Atom feed at `/feed.xml` (latest 20 posts, title +
link + short excerpt). Full text is intentionally not re-published —
the content belongs to its author.

## License

The code (Racket package & workflows) is licensed under the MIT License;
the archived posts remain copyrighted by their author — see [LICENSE](LICENSE).

## Copyright

All archived posts are copyrighted by their original author. No content is sold or relicensed. See the [correction and removal process](docs/READING.md).
