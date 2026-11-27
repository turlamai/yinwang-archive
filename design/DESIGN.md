# InkVault DESIGN.md — 视觉与交互契约（单一真源）

原型（`design/prototype/`）与站点实现（`assets/site/styles/main.css`、`yinwang-archive/site.rkt` 模板）都遵循本文件；改视觉先改这里，再同步实现。
Tokens 逐值提取自 `assets/site/styles/main.css` 现行值（家族 site-kit 调色板：一支 terracotta accent 贯穿 jrtx.site 全线），保证原型 → Racket 站点生成零翻译成本。

## Brief（2026-11-11）

- **目标**：维护既有历史存档，不扩展产品功能；保留来源标注、阅读体验和版权更正入口。
- **产品红线**：免费内容存档站，不得把第三方存档内容包装成独家付费材料——无付费墙、无广告、文章页内零转化元素；组合定位见根 AGENTS.md「Commercial authorization decision」（`2026-10-auth-1`）。
- **原型范围**（5 屏 × 亮/暗）：① 文章列表首页（英雄屏，年份分组 + 分页 + 搜索入口）② 文章阅读页（TOC / 代码高亮 / 上下一篇 / 阅读进度）③ 搜索浮层激活态（Ctrl/Cmd+K，命中高亮 + 空态）④ 存档说明页（新增页提案：数据来源 / 同步机制 / 删除文章保全 / 更正通道 / 许可）⑤ 已移除文章阅读态（提案演示：ArchiveBanner + Git 历史入口）。
- **验收**：仅维护必要修复；自动化测试与真实浏览器验收分别记录。
- **不在范围**：改爬虫/CI/schema、渲染管线（`render.rkt`）、暗色手动切换开关进站点（站点按 `prefers-color-scheme` 自动，原型中 ◐ 仅为评审工具）、付费/授权 UI、新增语言版本。

## 品牌（2026-11-26）

公开站名统一为 InkVault，中文描述保留「王垠博客存档」。现有 URL、CLI、归档内容及原作者署名不变。自 2026-11-26 起停止自动采集，仅显示历史快照状态；不得宣传持续同步或永久公开保留已删文章。此切片仅调整名称与文案，不改变布局或交互。

## 设计原则（HIG 内核 × 存档站）

- **内容至上**：正文是唯一主角。chrome 只有 compact 头部一行、页脚两行、右下搜索入口；装饰不与长文争注意力，引用块降噪（仅左边线、无底色）。
- **原文可回溯**：存档的生命线是可信。每篇文章 meta 行必带「作者 · 发布日期 · 原文」；不保证已删除文章继续公开；尊重下架请求；来源信息缺失时显式标注而非隐藏。
- **长文排版是产品资产**：768px 阅读列（约 42 个中文字/行）、正文 17px/1.9、CJK 两端对齐、serif 标题（自托管 Newsreader + 宋体回退）；任何布局改动不得牺牲行宽行高。
- **反馈及时**：卡片 hover 即描边高亮；搜索输入即时过滤、命中词高亮；阅读进度条随滚动常驻；一切交互元素有 `:focus-visible` 焦点。
- **防错一致**：Esc 永远关闭浮层；外链一律 `target="_blank" rel="noopener"`；键盘 ←/→ 切换上下篇不与输入框冲突（输入焦点时失效）。
- **层级克制**：bg（画布）< surface（卡片/浮层）两层 + 1px border 分隔；唯一阴影是卡片 hover 与浮层投影；accent（terracotta）只给链接、交互反馈与状态，禁大面积色块。

## Tokens（与 `assets/site/styles/main.css` 1:1）

| Token | Light | Dark | 用途 |
|---|---|---|---|
| `--bg` | `#F9F7F4` | `#171412` | 页面画布 |
| `--surface` | `#FFFFFF` | `#231F1D` | 卡片/代码块/搜索浮层 |
| `--text` | `#1C1917` | `#E7E5E4` | 主文字 |
| `--text-2` | `#57534E` | `#A8A29E` | 次级文字/页脚链接/TOC 项 |
| `--text-3` | `#A8A29E` | `#78716C` | 辅助文字/日期/年份标签/占位符 |
| `--accent` | `#D97757` | `#D4915C` | 链接/hover/命中高亮/进度条/状态徽标 |
| `--accent-hover` | `#C25F3D` | `#E0A06D` | 链接 hover |
| `--accent-bg` | `#FBEDE7` | `#2D2218` | 行内代码底/命中词底/hover 弱底 |
| `--border` | `#E7E5E4` | `#3D3835` | 分隔线/卡片与浮层描边 |
| `--selection` | `#F3DCBE` | `#56401F` | 文字选中底 |

- **代码高亮**（vendor highlight.js，暖色 palette，亮/暗各 6 值）：`--hl-comment #A8A29E/#78716C`、`--hl-keyword #A35F28/#E0A06D`、`--hl-string #5F7A44/#9CB87A`、`--hl-number #B03A2E/#E08E85`、`--hl-title #3E6E8E/#82AACC`、`--hl-attr #8E6B3E/#C9A66B`。
- **字体三栈**：UI/正文 sans `-apple-system, BlinkMacSystemFont, "Segoe UI", "Noto Sans SC", "PingFang SC", "Hiragino Sans GB", sans-serif`；标题 serif `"Newsreader"(自托管 woff2), "Songti SC", "Noto Serif SC", "SimSun", Georgia, serif`——仅 `site-title` 与文章大标题使用；代码 `ui-monospace, "SF Mono", Menlo, Consolas, "Cascadia Mono", monospace`。原型因禁外部资源，serif 以系统宋体栈代替，实物为自托管 Newsreader。
- **字号行高**：UI 15px/1.7；阅读正文 17px/1.9（≤640px 时 16px/1.9），`text-align: justify`（CJK 标准）；大标题 1.85em/1.25 serif；次级 0.85em；日期 `tabular-nums`。
- **布局**：容器 `clamp(780px, 16.1vw + 571px, 880px)`；阅读列 768px。**圆角**：卡片/浮层 12px（搜索浮层 16px）、代码块 10px、行内代码 5px、胶囊 100px。**动效**：0.15–0.2s，不过度。
- **语言**：界面与文档中文（`site-language` 默认 zh），作者名与原文术语保留原样。

## 组件词汇

`SiteHeader`（首页堆叠态：圆 logo + serif 站名 + 描述行 / 文章页 compact 态：30px logo + 站名一行）· `FreeNotice`（首页免费声明行 + 阅读与更正入口）· `YearSection`（年份标签 + 卡片组）· `PostCard`（标题左 + 日期右，hover 描边高亮）· `Pagination`（胶囊按钮 50 篇/页）· `PostMeta`（作者 · 日期 · 原文链接）· `PostToc`（「本文目录」`<details>` 渐进增强，≥3 个 h2/h3 才渲染）· `PostNav`（← 更早一篇 / 更新一篇 →，配键盘 ←/→）· `ReadingProgress`（顶部 3px accent 渐变条）· `SearchTrigger`（右下 FAB：图标 + 「搜索」+ Ctrl K 提示）· `SearchOverlay`（560px 浮层，标题匹配 + `<mark>` 命中高亮 + 15 条上限提示）· `SiteFooter`（版权行 + RSS/存档说明一行）· `AboutPage`（新增页：数据来源/停更状态/更正/隐私/许可）。

## 不变式

1. **accent 只用于**：链接与 hover、搜索命中、进度条、状态徽标（如「已移除」）；正文区禁大面积 accent 色块；行内代码用 `accent-bg` 底但文字保持 `--text`，不与链接抢色。
2. **原文可回溯**：每篇文章必带「作者 · 发布日期 · 原文」meta 行与 `source` 链接；已确认下架内容不再提供公开入口；发布日期来自源站数据，站点不虚构时间戳。
3. **长文排版锁死**：阅读列 768px、正文 17px/1.9、CJK 两端对齐、serif 大标题；任何改版不得使行宽超过约 50 个中文字。
4. **层级两层**：bg 与 surface + 1px border 分隔，唯一阴影是卡片 hover（`--shadow-md`）与浮层投影；亮暗成对设计，任一界面不得单态发布。
5. **免费定位不可妥协**：全文站内可读，无付费墙、无广告、无追踪弹窗；文章页内零转化元素，无公众号或产品推广、无第三方统计；「内容版权归原作者 · 本站仅作备份存档」在每页页脚常驻。
6. **键盘语义全站一致**：←/→ 上下篇、Ctrl/Cmd+K 搜索、Esc 关闭浮层；输入焦点在输入框时快捷键失效；一切交互元素有 `:focus-visible` 可见焦点。

## HIG 自查清单（评审逐条过）

清晰优先（状态明说：历史缺图说明、搜索空态、加载失败提示）· 内容至上（chrome 三件套之外无杂物）· 直接操纵（卡片/目录/图片 lightbox 点击直感）· 反馈及时（hover 即响应、搜索即时过滤、进度常驻）· 防错一致（Esc 关浮层、外链新窗、输入态快捷键失效）· 层级克制（两层表面 + accent 纪律）· 亮暗成对（每屏 ◐ 切换核对）· 键盘可达（←/→、Ctrl/Cmd+K、Esc、focus-visible、TOC 原生 `<details>`）。

## 历史存档收尾（2026-11-26）

不再生成公众号页面与二维码，不加载 Umami，不链接产品主页。保留 RSS、原文链接和版权更正说明。旧推广页面不再属于站点地图。已确认下架的内容不提供历史绕行入口。

## 搜索交互收尾

保留标题检索及现有视觉布局，不扩大发布正文索引。搜索框有可见关闭按钮、明确标签及模态语义。Tab 在浮层内循环，Esc 或关闭按钮恢复原焦点和滚动状态。加载、空结果、失败分开提示；过期查询不覆盖新查询。方向键在浮层打开时不切换文章。原型为结构预览，实际浏览器验收仍需执行。

### 图片放大及移动端关闭操作

阅读页非链接图片可通过鼠标、Enter 或 Space 放大，原有图片链接不拦截。灯箱带可见关闭按钮、模态语义；关闭后恢复触发图片焦点与原滚动状态。搜索和灯箱互斥，方向键不得在浮层内切换文章。移动端搜索关闭按钮始终可见。保留既有色彩与阅读列宽，真实浏览器验收待执行。
