# 📋 Stock-Tick 部署更新日志

> 文件用途：帮助 AI Agent 在新会话中快速恢复项目记忆。每次部署或重大修改后更新此文件。

---

## 项目状态速查

| 项目 | 值 |
|------|-----|
| **项目名称** | stock-tick 股票盘中监控仪表盘 |
| **代码目录** | `~/百度同步盘/Pi/项目/stock-tick/` |
| **模板目录** | `~/.pi/agent/skills/stock-dashboard/` |
| **主入口文件** | `index.html`（纯前端单文件，~2400行） |
| **腾讯云 COS** | `https://stock-tick-1422784620.cos-website.ap-shanghai.myqcloud.com` |
| **Netlify（暂停）** | `https://stock-tick.netlify.app/`（额度用尽） |
| **部署脚本** | `./deploy.sh cos` |
| **Netlify 项目名** | `stock-tick` |
| **当前默认股票** | 02513 智谱（港股） |
| **API 来源** | 东方财富免费公开API（push2delay.eastmoney.com） |
| **图表库** | Lightweight Charts v4.1.3 (CDN) |

---

## 部署更新记录

### [2026-07-10] 新增：5分K Tab + 日K均线RSI + 背驰三层分析（v6）
- **5分钟K线Tab**：三Tab布局 [📈分时] [⏱5分K] [📅日K]
  - 从1分钟数据聚合成5分钟OHLC蜡烛 + MACD(12,26,9) + 背驰检测(minDist=4)
  - 洞察卡：5分背驰 + MACD金叉/死叉
- **日K增强**：
  - MA5(白)/MA10(黄)/MA20(紫) 三条均线叠加在蜡烛图上，仅日K模式可见
  - RSI(14)超买(>70)/超卖(<30) 洞察卡
  - 量能对比：今日量 vs 5日均量（爆量/放量/缩量）
  - MA排列分析：多头/空头排列、金叉/死叉
  - KDJ日线超买超卖标识：J<0红圆超卖、J>100绿圆超买，悬浮tooltip显示K/D/J值
- **背驰三层分析**（5分K + 日K）：
  - 趋势阶段：急跌末端/下跌中继/下跌加速（对比前后段斜率）
  - 量价验证：后段量缩XX% / 量能持平 / 后段放量×X.X
  - 综合评级：🔴高质量 / ⚠️低质量
  - 5分K和日K均有，分时太短不做
- **鼠标悬停tooltip**：三Tab全覆盖（分时/5分K/日K），日K含KDJ(9,3,3) K/D/J值
- **标记缩放**：所有图表标记size统一为'auto'，随K线缩放
- **Bug修复**：
  - `detectMACDDivergence` 返回 `idx1`（第一极值点），修复背驰段分析起点错误
  - `findSegmentStart` 改为 `findStartBackward`（往回搜30根），不再从图表起点搜
- **新函数**：`calcRSI()`, `calcMA()`, `build5MinChartData()`, `analyzeDivergenceContext()`
- **CACHE_VERSION**：5 → 6

### [2026-07-10] 新增：背驰段矩形 + 表格保持 + Bug修复（v6 bis）
- **背驰段可视化**：5分K + 日K 在蜡烛图上叠加半透明矩形标记段1和段2
  - 段1: opacity 0.06, 段2: opacity 0.10; 底背驰红调, 顶背驰绿调
  - 分时模式自动清除; `drawDivergenceSegments()` 通过 panePrimitive 实现
- **Tab 保持**：切换股票时不再重置为分时Tab，保持用户选择
- **Bug修复**：
  - `buildSegments` 新增函数，提取段坐标用于矩形渲染
  - `dGroups`/`groups` 改为 if-block 外部声明，避免未定义
  - `analyzeDivergenceContext` 返回段坐标 `seg1Start/seg1End/seg2Start/seg2End`
- **CACHE_VERSION**：6 → 7

### [2026-07-10] 新增：置信度体系 + 放量方向 + 主力信号（v8）
- **置信度三级标注**：所有洞察卡带置信度圆点
  - 🔴 高置信：日线KDJ极端值、MA多/空头排列、背驰+三层验证(quality=high)
  - 🟡 中置信（无点）：VWAP、MACD金叉死叉、量价背离、RSI等
  - ⚪ 低置信：吸筹、连续大单、大单异动、盘面综述
- **主力信号检测**：分时Tab新增洞察卡
  - 🐋 吸筹模式：横盘30分钟+、间歇放量≥3次，标注低置信
  - 💪 连续同向大单：5分钟内3+笔同向大单，标注低置信
- **5分K量价背离**：`⚠️ 价涨量缩` / `⚠️ 价跌量增`
- **放量异动加方向**：信号卡显示 📈买 / 📉卖
- **分时洞察卡精简**：移除背驰卡片（图表已有箭头标记）
- **Bug修复**：`dGroups` / `groups` 提前声明避免 undefined
- **新函数**：`detectAccumulation()`, `detectConsecutiveBigOrders()`, `detectVolPriceDivergence()`
- **CACHE_VERSION**：7 → 8

### [2026-07-10] 迁移至腾讯云 COS
- Netlify 额度用尽，迁移到腾讯云 COS 对象存储
- COS 桶: `stock-tick-1422784620`，地域 `ap-shanghai`
- 新增 `deploy.sh` 部署脚本

### [2026-07-09] 修复：trends2 API 不再返回昨日数据 + 目录重命名
- **取数问题**: `trends2/get` API 自2026.7起只返回当日数据 (`ndays=2/3/5` 均只有1天)
  - 根因: 东方财富API行为变更，不再支持 `ndays` 多日参数
  - 修复: `ndays=2` → `ndays=1`，简化日期拆分逻辑（无需多日解析）
  - 昨日数据: 完全由 localStorage 缓存 (`saveDayHistory`) 提供
  - 影响: 如果上一个交易日未打开页面或刷新不完整，昨日蜡烛图可能缺数据
- **目录重命名**: `stock-dash-deploy/` → `stock-tick/`（与站点名一致）
- **新增**: `DEPLOY_LOG.md` — AI Agent 记忆恢复文件

### [2026-07-08] 当前版本 — CACHE_VERSION=4
- **文件**: `index.html` (70978 bytes)
- **默认股票**: 02513 智谱（港股）
- **功能**: 三栏布局，K线图+量柱+VWAP，多空力量，资金流向，关键位+告警，分时脉搏，关键洞察栏
- **数据接口**:
  - 报价: `push2delay.eastmoney.com/api/qt/stock/get`
  - 分钟趋势: `push2delay.eastmoney.com/api/qt/trends2/get`（ndays=2）
  - 搜索: `searchadapter.eastmoney.com/api/suggest/get`（JSONP）
- **fields2参数**: `f51,f52,f53,f54,f55,f56,f57,f58`（只用f51时间、f53收盘价、f56成交量，O/H/L未用）
  - f51=时间, f52=开盘, f53=收盘, f54=最高, f55=最低, f56=成交量, f57=成交额, f58=?
  - ⚠️ 2026.7起此API不再返回昨日数据，ndays参数失效

### [2026-07-07] CACHE_VERSION=3
- push2 API 从 `push2.eastmoney.com` 迁移到 `push2delay.eastmoney.com`（有CORS头）
- 新增左侧搜索栏 + 自选列表管理
- 新增昨日对比蜡烛图（半透明叠加）

### [2026-07-06] 初始版本
- 基于 `stock-dashboard` skill 模板首次部署
- 同时部署了 `dashboard_0700.html`（腾讯控股）

---

## 关键代码位置（index.html 行号参考）

| 功能 | 大致位置 | 关键函数 |
|------|---------|---------|
| CONFIG 配置 | ~L246 | 股票代码/secid/prevClose/priceScale |
| getPriceScale() | ~L257 | 港股÷1000, A股÷100 |
| fetchData() | ~L523 | 并行请求报价+趋势 |
| analyze() | ~L537 | 核心分析引擎 |
| updateUI() | 后半段 | 渲染所有DOM |
| switchStock() | ~L443 | 切换股票 |
| initChart() | 后半段 | LightweightCharts初始化 |
| detectMinuteSignals() | 后半段 | 10维分钟信号检测 |

---

## 已知待解决问题

1. **昨日数据依赖本地缓存**: `trends2/get` API 不再返回昨日数据，昨日蜡烛图完全依赖 localStorage。如用户前一天未完整使用页面，昨日图可能不完整。
2. **蜡烛O/H/L不精确**: API 返回了 f52(开盘)/f54(最高)/f55(最低)，但代码只用收盘价近似，真实O/H/L被丢弃。

---

## 部署流程（备忘）

1. 修改 `index.html`（或修改 `template.html` + 运行 `generate.py`）
2. 部署到 Netlify：打开 `https://app.netlify.com/projects/stock-tick/overview`
3. 使用 Sites → Deploy manually → 拖拽 `stock-tick` 文件夹
4. ⚠️ **不要用** `app.netlify.com/drop`（会创建新站点）
5. 更新此 `DEPLOY_LOG.md`

---

## 快速恢复命令

```bash
# 查看项目文件
ls -la ~/百度同步盘/Pi/项目/stock-tick/

# 查看代码行数/关键函数
grep -n "function \|CONFIG\|API_BASE\|fields2" ~/百度同步盘/Pi/项目/stock-tick/index.html

# 重新生成并部署
cd ~/.pi/agent/skills/stock-dashboard
python3 generate.py <股票代码> <股票名称>
cp ~/Desktop/dashboard_*.html ~/百度同步盘/Pi/项目/stock-tick/index.html
```
