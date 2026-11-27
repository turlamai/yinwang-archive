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

`posts/` is the authoritative archive. `index.json` is the historical collector index, not a complete catalog. At the retirement baseline there are 176 Markdown files and 130 collector entries; the 46 other files are retained without assuming why they are absent from the index. Run `racket yinwang-archive/archive-check.rkt` from the repository root to check filename/slug identity and missing indexed files. The check also verifies that rendered root-relative `/images/` references point to nonempty local files. It does not validate external resources, image decoding or source availability.

## Maintenance-only status

The archive is retired. The collector and notifier source remains for historical reference only; do not run either command. Title search is the supported scope. No new full-text index or product features are planned. Keep the repository writable for necessary corrections and removal requests.

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

### Known historical gaps

Ten diagrams in the computer-science article are absent from the stored image directory and its queried Git path history. The generated reading page labels those gaps; the original Markdown remains unchanged. CI reports the exact known gaps and rejects new missing references or stale gap entries. No images are fetched or fabricated.
