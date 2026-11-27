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

`posts/` 是存档唯一内容来源，`index.json` 是历史采集索引而非完整目录。停更基线包含 176 个 Markdown 文件和 130 条采集索引；其余 46 篇保留，不推断缺失索引的原因。在仓库根目录执行 `racket yinwang-archive/archive-check.rkt` 校验文件名与 slug 的一致性，以及索引指向的文件是否缺失。同时检查渲染后的 `/images/` 本地图片引用是否指向非空文件。检查完全离线，不验证外部资源、图片解码或源站可用性。

## 仅维护状态

本项目已退役。采集器和通知器源代码仅供历史参考，不运行对应命令。保留标题搜索，不再规划全文索引或新产品功能。仓库保留必要维护权限，以便处理更正与下架请求。

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

### 已知历史缺失

《解谜计算机科学》的 10 张插图在现有图片目录和已查询的 Git 路径历史中均未找到。生成阅读页明确标注缺失，原始 Markdown 保持不变。CI 报告这些明确登记的缺失项，并拒绝新增缺图或失效登记；不重新下载或伪造图片。
