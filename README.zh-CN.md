# InkVault

王垠博客（[yinwang.org](https://yinwang.org)）历史存档。站长于 2026-11-26 决定停止自动采集，仅保留既有资料。本项目不是实时镜像或作者官方网站。

![Racket](https://img.shields.io/badge/Racket-9E3E97?logo=racket&logoColor=white) [![License](https://img.shields.io/badge/license-MIT-blue)](LICENSE)

[English](README.md) · **中文**

## 阅读入口

[阅读 InkVault（王垠博客存档）](https://yinwang.jrtx.site/) · [阅读、隐私与更正](docs/READING.zh-CN.md)

这是免费阅读备份，不是作者官方网站。已停用定时及手动抓取工作流；存档可能不是最新版本。排版、图片与代码可能与原文不同，Git 历史可保留旧修订。不增加付费内容或广告。

## 功能特性

- **Racket 全栈** — 爬虫、校验器、静态站生成器同属一个 Racket 包（`raco yinwang-archive …`）
- **历史快照** — 仅使用本地既有文章重建站点，不请求源站
- **完整内容归档** — 文章保存为 Markdown，图片下载到本地
- **自包含 Markdown** — 文件名 = URL slug，中文标题存 frontmatter，正文以 H1 标题开始
- **自动去重** — 通过 source URL 跟踪，避免重复文件
- **静态站点生成** — 纯 Racket 构建（无 Node）的可搜索网站，部署到 GitHub Pages

## 项目结构

```
yinwang-archive/
├── posts/           # Markdown 文章（文件名 = slug）
├── images/          # 文章图片（按 URL slug 分目录）
├── yinwang-archive/       # Racket 包：爬虫、格式化、校验、建站
├── assets/site/     # 静态资产（样式、favicon、自托管 highlight.js）
└── index.json       # 文章元数据索引
```

## 环境要求

- [Racket](https://racket-lang.org)（stable 版本即可）

## 快速开始

### 1. 克隆仓库

```bash
git clone https://github.com/turlamai/yinwang-archive.git
cd yinwang-archive
```

### 2. 安装包

```bash
raco pkg install --auto --no-docs --link "$(pwd)"
```

### 3. 运行管线

```bash
# 全量校验（CI 门禁）
raco yinwang-archive lint

# 构建静态站点（输出到 dist/）
raco yinwang-archive build
```

### 修复工具

```bash
raco yinwang-archive fix-bold-spacing [--check|--dry-run]  # 修复 `** 文字 **` 坏强调
raco yinwang-archive normalize-code [--check]              # 顶层缩进代码转围栏
```

所有命令支持 `--root DIR`，可在任意目录对指定检出操作。

## 离线完整性

`posts/` 是存档唯一内容来源，`index.json` 是历史采集索引而非完整目录。停更基线包含 176 个 Markdown 文件和 130 条采集索引；其余 46 篇保留，不推断缺失索引的原因。在仓库根目录执行 `racket yinwang-archive/archive-check.rkt` 校验文件名与 slug 的一致性，以及索引指向的文件是否缺失。检查完全离线，不证明图片完整性或源站可用性。

## 历史实现（采集器已停用）

保留采集器作为历史源代码，不推荐运行。未经新的站长决定且未确认符合原作者访问策略，不得恢复自动采集。

1. **获取文章列表** — 爬虫调用 `https://yinwang.org/api/v1/posts` 接口，通过分页参数（`skip`/`limit`）获取所有文章 slug。
2. **去重检查** — 根据已有的 `source` URL 构建索引，避免生成重复文件。
3. **逐篇下载** — 对每个 slug，从 `https://yinwang.org/api/v1/posts/{slug}` 获取完整正文（`content_html`，HTML），转换为 Markdown。
4. **下载图片** — 文章中引用的所有图片下载到 `images/{slug}/` 目录。
5. **格式化并保存** — 对转换后的 Markdown 做排版处理（CJK 间距、标题层级规范化、代码块转围栏），生成带 YAML frontmatter 的文件。若多数文章拿不到正文，爬取会显式报错而不是静默停更。
6. **更新索引** — 将每篇已处理文章的元数据更新到 `index.json`（与历史 Python 序列化器字节兼容，无变化时不产生 diff）。
7. **建站** — 生成器将 Markdown 渲染为 HTML（标题锚点、围栏代码 + 客户端 highlight.js、Atom 订阅、搜索索引、sitemap、llms.txt）输出到 `dist/`。

### 文章格式

每个 Markdown 文件以 URL slug 命名，完全自包含：

```markdown
---
title: "我的博客文章"
slug: my-blog-post
author: 王垠
created: 2025-01-15
source: https://yinwang.org/posts/my-blog-post
---
# 我的博客文章

## 第一节

正文……
```

- 文件名 = `slug`（即 URL `/posts/{slug}/` 与图片目录 `images/{slug}/`，三者统一）
- 中文标题存于 frontmatter 的 `title` 字段；正文以 H1 标题开始
- 大节用 H2；爬虫会自动规范化标题层级与代码围栏

## RSS

站点提供 Atom 订阅：`/feed.xml`（最新 20 篇，标题 + 链接 + 简短摘要）。有意不输出全文——内容归原作者所有。

## 许可证

仓库代码（Racket 包与工作流）基于 [MIT License](LICENSE) 开源；posts/ 下的博客内容版权归原作者所有，仅供个人存档阅读。

## 版权

本站仅作历史留存，不销售或重新许可文章，版权归原作者所有。参见[更正与下架流程](docs/READING.zh-CN.md)。
