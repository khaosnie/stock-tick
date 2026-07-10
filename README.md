# 📊 Stock Dashboard — 股票盘中监控仪表盘

> 纯前端单 HTML 文件，支持 A 股 / 港股实时监控，部署在 Netlify 上零运维。

## 1. 项目概览

### 在线地址
- 主站：`https://stock-tick.netlify.app/`（智谱 02513.HK）
- 腾讯：`https://stock-tick.netlify.app/dashboard_0700.html`

### 核心特性
| 模块 | 说明 |
|------|------|
| 📈 1分钟K线图 | 蜡烛图 + 量柱 + VWAP线 + 昨收/今开水平线（Lightweight Charts v4） |
| ⚔️ 多空力量比 | 近10分钟买卖盘量占比 |
| 💰 资金流向 | 全日主动买入/卖出金额 + 净流向 |
| 🔔 价格告警 | 自定义突破/跌破价格，触发时弹窗 + 声音 |
| 📐 支撑阻力 | 当日动态 Pivot Point 计算 |
| 📋 分时脉搏 | 每分钟量价明细 + 10维分钟信号标注 |
| 🧠 关键洞察栏 | 大单异动、VWAP博弈、资金承接、量价背离、V型反转等 7 类智能检测 |
| ⚡ 实时信号 | 诱多陷阱、放量异动、缩量止跌、反弹质量（并入洞察栏） |
| 🔍 多股票搜索 | 左侧栏输入代码/名称搜索，支持 A股 + 港股 |
| ⭐ 自选列表 | 点击切换股票，localStorage 持久化，刷新不丢失 |
| 💾 本地缓存 | 数据缓存 1 小时，再次打开秒加载 |
| 📱 响应式 | 手机/平板/桌面三栏自适应 |

### 三栏布局
```
┌──────────┬───────────────────────────────┬──────────────────┐
│  左侧栏   │           中间主区域            │      右侧栏       │
│  ~190px  │                               │      ~300px      │
│          │  股票名 / 价格 / 涨跌幅        │                  │
│ 🔍 搜索  │                               │  ⚔️ 多空力量比    │
│          │  ┌─────────────────────────┐  │  💰 资金流向      │
│ ⭐ 自选   │  │  K线图 + 量柱 + VWAP    │  │  📐 关键位+告警  │
│ · 0700   │  │  + 昨收/今开参考线      │  │                  │
│ · 02513  │  └─────────────────────────┘  │                  │
│ · 9988   │                               │                  │
│          │  🧠 关键洞察 + ⚡实时信号       │                  │
│          │  ┌─────┬─────┬─────┬─────┐    │                  │
│          │  │ 大单 │ VWAP│ 承接 │ 背驰 │   │                  │
│          │  └─────┴─────┴─────┴─────┘    │                  │
│          │                               │                  │
│          │  📋 分时脉搏（滚动表格）        │                  │
└──────────┴───────────────────────────────┴──────────────────┘
```

---

## 2. 技术架构

### 数据流
```
浏览器 (HTML/JS)
  │
  ├─→ push2delay.eastmoney.com/api/qt/stock/get      (实时报价)
  ├─→ push2delay.eastmoney.com/api/qt/trends2/get    (分钟数据)
  └─→ searchadapter.eastmoney.com/api/suggest/get    (股票搜索, JSONP)
```

### 关键技术决策

| 决策 | 原因 |
|------|------|
| 纯前端无后端 | 零服务器成本，数据全部从东方财富免费公开 API 获取 |
| push2delay 域名 | 2026.7 东方财富 API 从 push2 迁移到 push2delay，后者有 CORS 头 |
| JSONP 搜索 | 搜索 API 无 CORS 头，用动态 `<script>` 标签绕过 |
| Lightweight Charts v4 | CDN 加载，蜡烛图库，体积小性能好 |
| localStorage 缓存 | 1 小时有效 + 版本号 (CACHE_VERSION=3)，防旧数据结构 |
| Netlify 部署 | 拖拽部署，HTTPS 域名，API 不拦截 file:// 请求 |
| 涨红跌绿 | 中国 A 股惯例，红色 = 上涨，绿色 = 下跌（与美国相反） |

### API 端点明细

| 端点 | 用途 | CORS |
|------|------|------|
| `push2delay.eastmoney.com/api/qt/stock/get` | 报价：现价/开/高/低/昨收 | ✅ |
| `push2delay.eastmoney.com/api/qt/trends2/get` | 分钟量价数据 | ✅ |
| `searchadapter.eastmoney.com/api/suggest/get` | 股票代码/名称搜索 | ❌ (JSONP) |

### 市场识别 (secid)
```
5位数字(≤5)     → 港股  secid = 116.XXXXX   (例: 0700 → 116.00700)
6位 60xxxx      → 沪市  secid = 1.XXXXXX
6位 其他        → 深市  secid = 0.XXXXXX
```

---

## 3. 文件结构

```
~/.pi/agent/skills/stock-dashboard/     ← SKILL 源文件
├── SKILL.md                              Skill 元数据（给 AI Agent 读）
├── generate.py                           Python 生成脚本
└── template.html                         HTML 模板（含完整 JS 分析引擎）

~/百度同步盘/Pi/项目/stock-tick/          ← Netlify 部署文件夹
├── _redirects                            Netlify 代理规则（已废弃，API直连）
├── index.html                            部署入口（当前为 02513 智谱）
├── dashboard_0700.html                   腾讯控股 0700.HK
└── stock_switcher.html                   简易导航页
```

---

## 4. 生成脚本 (generate.py)

### 用法
```bash
python3 ~/.pi/agent/skills/stock-dashboard/generate.py <股票代码> [股票名称]
```

### 模板变量（{{ }} 在生成时替换）
| 变量 | 示例 | 说明 |
|------|------|------|
| `{{STOCK_CODE}}` | `02513` | 股票代码 |
| `{{STOCK_NAME}}` | `智谱` | 股票名称 |
| `{{SECID}}` | `116.02513` | 东方财富 secid |
| `{{PREV_CLOSE}}` | `1793` | 昨收价（API获取，失败则为0由JS兜底） |
| `{{MARKET}}` | `港股` | 市场名称 |
| `{{TRADING_STATUS}}` | `交易中·早盘` | 交易状态文本 |
| `{{TRADING_STATUS_CLASS}}` | `live` / `closed` | CSS 类名 |
| `{{IS_TRADING}}` | `true` / `false` | JS boolean |
| `{{SR_LIST}}` | `{t:"R",l:"阻力2",v:0},...` | 初始支撑阻力（全0，JS动态计算） |
| `{{YEAR}}` `{{MONTH}}` `{{DAY}}` | `2026` `6` `6` | 生成日期（已不再使用，JS用 `new Date()`） |

### 流程
1. 调用 `detect_market(code)` 确定 secid 和市场 ✓
2. 调用 `fetch_stock_info(code)` 获取名称和昨收（失败则用默认值） ✓
3. 调用 `is_trading_time()` 判断是否交易时段 ✓
4. 读取 `template.html`，替换所有 `{{变量}}` ✓
5. 写出到 `~/Desktop/dashboard_<code>.html` ✓

---

## 5. 前端 JS 引擎 (template.html)

### 核心函数

| 函数 | 作用 |
|------|------|
| `fetchData()` | 并行请求报价 + 分钟数据，返回 `{q, trends}` |
| `analyze(q, trends)` | 核心分析引擎，返回完整数据结构 |
| `updateUI(r)` | 更新所有 DOM：头部、图表、洞察、脉搏表 |
| `refresh()` | 主刷新入口，处理交易/非交易/收盘状态 |
| `switchStock(...)` | 切换股票：清图→更新CONFIG→重初始化→刷新 |
| `initChart()` | 创建 LightweightCharts 实例 |
| `detectMinuteSignals(r, idx)` | 10维分钟信号检测（急拉/急跌/爆量/缩量...） |
| `doSearch(q)` | JSONP 股票搜索 |
| `renderWatchlist()` | 渲染自选列表 |
| `addToWatchlist(stock)` | 加入自选 + 切换 |
| `removeFromWatchlist(code)` | 删除自选 |

### 关键洞察检测算法 (7类)

| 洞察 | 触发条件 |
|------|----------|
| 💰 大单异动 | 单分钟成交量 > 均量4倍 且 > 50万手 |
| 📈 VWAP博弈 | 现价偏离VWAP ±0.5%/2% |
| 📥 资金逆势承接 | 近5分钟 ≥3次下跌 但 多方占比 > 50% |
| ⚠️ 量价背离 | 前10分钟vs后10分钟：价↑量↓ 或 价↓量↑ |
| 🚀 尾盘信号 | 近20分钟放量涨/跌 |
| ✅ V型反转 | 急跌2%后连续回升 |
| 📋 盘面综述 | 默认兜底，按涨跌幅生成描述 |

### 10维分钟信号标注 (用于脉搏表每个分钟行)

1. 价格变动幅度（急拉/急跌）
2. 成交量异动（爆量/放量）
3. 缩量止跌
4. 诱多回吐
5. VWAP穿越
6. 关键位触及
7. 日内新高/新低
8. V型反转
9. 连续同向（3连阳/3连阴）
10. 昨收穿越

---

## 6. Netlify 部署

### 部署方式
1. 打开 https://app.netlify.com/drop
2. 拖入 `stock-tick` 文件夹
3. 部署完成，获得域名

### 当前域名
- `https://stock-tick.netlify.app/`

### 更新流程
1. 修改 `template.html` 或 `generate.py`
2. 运行 `generate.py` 重新生成 HTML
3. `cp ~/Desktop/dashboard_*.html ~/百度同步盘/Pi/项目/stock-tick/index.html`
4. 部署到 Netlify：
   - ⚠️ 必须导航到项目专属页 `https://app.netlify.com/projects/stock-tick/overview`
   - ⚠️ 不要用 `https://app.netlify.com/drop`（那会创建新站点）
   - 上传 zip 到 `#dropzone-file-upload`

---

## 7. 已知问题 & 注意事项

| 问题 | 状态 | 说明 |
|------|------|------|
| 收盘后无分钟数据 | ✅ 已处理 | display 静态报价 + "已收盘"状态 |
| push2 API 迁移 | ✅ 已修复 | 切换到 push2delay.eastmoney.com |
| 搜索需要 JSONP | ✅ 已修复 | 动态 `<script>` 标签绕过 CORS |
| file:// 协议被拦截 | ✅ 已解决 | 通过 Netlify HTTPS 域名访问 |
| 旧缓存导致新字段缺失 | ✅ 已修复 | CACHE_VERSION=3，自动失效旧缓存 |
| 自选列表的 prevClose 为0 | ✅ 已处理 | switchStock 中自动从 API 获取并兜底为 1 |
| 移动端 | ✅ 支持 | 768px 断点，搜索栏变横排，卡片压缩 |

---

## 8. 配色约定
```
--red:    #f85149      上涨 / 多方 / 阻力位
--green:  #3fb950      下跌 / 空方 / 支撑位
--bg:     #161b22      卡片背景
--muted:  #8b949e      次要文字
--border: #30363d      边框
黄色 #d29922           VWAP线 / 预警 / 中性信号
蓝色 #58a6ff           昨收线 / 当前股票名 / 信息
粉色 #f778ba           实时信号卡片
```

---

## 9. 对 AI Agent 的快速指引

### 如果你想加新功能：
1. **读 `template.html`**：这是核心，包含了全部 CSS + HTML + JS
2. **CSS 加在 `</style>` 之前**，HTML 加在对应位置
3. **JS 逻辑加在 `analyze()` 中计算，`updateUI()` 中渲染**
4. **加新的 API 调用**在 `fetchData()` 中，用 Promise.all 并行
5. **改完后运行 `generate.py` 重新生成**，再部署到 Netlify

### 如果你想新增洞察类型：
在 `analyze()` 的 `═══ 关键洞察 ═══` 区块中添加判断逻辑，
返回 `{icon, title, desc, type}` 对象，`type` 可以是 `bull`/`bear`/`warn`/`info`。

### 如果你想调图表样式：
修改 `initChart()` 中的 `layout`/`grid`/`crosshair` 等配置。

### 如果你需要加更多股票：
直接运行 `generate.py` 生成新 HTML，复制到 deploy 文件夹，Netlify 自动可访问。
