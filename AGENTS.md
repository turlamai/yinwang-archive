# InkVault — 历史存档维护

**站长决定（2026-11-26 起停更）：退出活跃产品组合，仅保留既有历史资料、离线构建、必要的安全与版权更正/下架维护。** 不恢复自动或手动采集，不主动访问源站，不扩大存档范围，不新增全文索引、商业授权、广告、第三方统计或推广入口。保留标题搜索与现有阅读体验。历史采集器代码仅供回溯，不运行 crawl 或 notify。

## Required policy discovery at each slice

Before starting the next bounded slice, refresh remote state safely and re-read
this root AGENTS file, the repository's canonical implementation handoff, and
the current [family delivery standard](https://github.com/turlamai/turlamai.github.io/blob/master/docs/PRODUCT-STANDARD.md),
[documentation language policy](https://github.com/turlamai/turlamai.github.io/blob/master/docs/DOCUMENTATION-LANGUAGES.md)
and [portfolio decisions](https://github.com/turlamai/turlamai.github.io/blob/master/PORTFOLIO.md).
Follow the corresponding Chinese links when preferred; both public user paths
must express the same promises. Product-specific plans and technical protocol
owners remain in their owning repositories.

Record the repository starting SHA and the central-policy commit/revision
actually read in the PR or handoff. A link's presence is not an acknowledgement
that an agent has read it. Existing conversations and stale checkouts do not
receive policy updates automatically: refresh these inputs at slice boundaries.
Preserve other agents' dirty worktrees; use an isolated checkout when needed,
without stashing, resetting or overwriting their work. Missing/offline policy
inputs must be reported as unverified, not silently claimed current.



## 维护范围

- `posts/` 为站点内容唯一来源；`images/` 为已有图片；`index.json` 为历史采集索引，不是完整目录。
- 保留作者、原文链接、日期和原始正文；不推断作者删除原因，不伪造缺失图片。按 `archive-gaps.rkt` 标注已知缺失，拒绝新增缺失。
- 权利人可通过仓库 Issues 提交更正或下架请求，仅提交涉及 URL 与请求动作，不公开私密材料。未核实的联系方式不得发布。遵守 `docs/READING.md` 与中文版；必要时移除站点、搜索、订阅、生成产物和可处理的历史缓存。
- 保持仓库可维护以处理更正请求，保留部署工作流及 Pages 所需分支；不为清零数字而关闭真实未验证的问题。

## 离线命令

```sh
raco test -p yinwang-archive
raco yinwang-archive lint
racket yinwang-archive/archive-check.rkt
raco yinwang-archive build
```

仅在必要的维护修复中使用格式修复命令；不批量改写历史正文。所有运行从仓库根目录执行。CI 通过不等于真实浏览器验收。

## 文件命名（最重要）

- **文件名 = frontmatter 的 `slug`**（如 `mites.md`），与站点 URL（`/posts/{slug}/`）、图片目录（`images/{slug}/`）三统一
- 中文标题只存在于 frontmatter 的 `title` 字段，不出现在文件名
- **中文原题文件名是忠实存档的例外**（共 10 篇，如 `论研究.md`、`unix-的缺陷.md`）：这些文章源站 slug 本身是中文，保持原样落盘——文件名即 slug，站点 URL 沿用原中文名，不转写英文。存档忠实性优先于命名规范统一

## frontmatter

```yaml
---
title: "我和螨虫的故事"
slug: mites
author: 王垠
created: 2026-07-15
updated: 2026-09-01
source: https://yinwang.org/posts/mites
---
```

- `title` 必填，双引号包裹（YAML 安全），值来自 API 返回的中文标题
- `slug` 必填（URL 最后一段）；`author`、`created`（API 的 publish_date）、`source` 必填
- `updated` 可选（API 的 updated_at，有则写入）
- 字段顺序固定：title → slug → author → created → updated → source

## 正文结构

- 正文以 `# {title}` 开始（每篇文件自包含）；渲染时剥掉首个 H1（页面头已有标题）
- 大节用 `##`，小节用 `###`
- 避免 `####` 及更深：历史采集器曾自动转为加粗段首词
- 若全文无 `##` 而有 `###`，历史采集器曾自动把 `###` 升为 `##`（顶层小节统一 H2）
- 正文中的 `#` 如果不是标题而是代码（如 `#define`），必须用行内代码包裹

## 图片

- 图片存放在 `images/{slug}/` 目录
- 正文引用标准 Markdown 或 HTML：`![描述](/images/{slug}/文件名.png)`、`<img src="/images/{slug}/文件名.png" width="400">`

## 排版规范

- 段落之间空 1 行，段落内部无空行；列表项之间不加空行
- 代码块必须标注语言类型；**顶层缩进代码块会被渲染管线破坏，必须用围栏**（历史采集器曾自动转换）
- CJK 与半角字符之间加空格（如 `使用 C++ 编程`），但 Markdown 标记（`*` `_` `~`）与内容之间**禁止**插空格，否则强调失效


## Racket 9.3 正则方言（大坑，必读）

本仓库跑在 Racket 9.3，其正则引擎**没有** `\d` `\s` `\w` 字母转义（写成字面字符）、`{n,m}` 量词、反向引用、POSIX 字符类；`(?m:)`/`(?s:)`/懒惰量词/环视可用；`regexp-match` 会裁掉尾部空组；`read-json` 产生**字符串键**（标准 Racket 是符号键）。所有模式一律用 `util.rkt` 的 shim（`ws-line-chars` 等）拼接，禁写 `\s`/`{3,}`/`\1`。

## 站点渲染对齐

- 样式表引用按**内容哈希**缓存指纹（`main.css?v=<sha1 前 10 位>`，`build.rkt` 算好经 `css-version` parameter 注入）——线上过 Cloudflare，改样式不改 URL 会拿到旧缓存（compact 头部对齐修复时踩过）

- 代码高亮：构建期只输出 `<pre><code class="language-x">`，高亮由 vendor 的 highlight.js 在浏览器端执行（`assets/site/vendor/highlight.min.js`，common bundle）——浏览器驻留 UI 薄壳层
- 线上站（yinwang.jrtx.site）部署滞后于仓库时，正文对比会出现假差异；以 `posts/` 为准
- 喂给 feed 的 `<updated>` 用最新 `created`（历史 Eleventy 用文件时间戳，在 CI 上每次构建都变，改为确定性值）

## CI

- `ci.yml`：ubuntu + macos 双机跑 raco test / lint / archive-check / build（push + PR）
- 原 `crawl.yml` 已删除；不再自动抓取或通知。
- `deploy.yml`：push 到 main/master 构建 dist 部署 GH Pages
- 配方：`Bogdanp/setup-racket` → `raco pkg install --auto --no-docs markdown http-easy-lib` → `raco pkg install --auto --no-docs --link "$(pwd)"`


## 视觉与交互

保留现有阅读列、主题、键盘搜索与图片灯箱。必要 UI 修复先更新设计契约与原型，真实浏览器验收单独记录。无新功能路线图；不恢复推广或采集。未完成的浏览器验收与版权反馈边界保留在维护记录中。
