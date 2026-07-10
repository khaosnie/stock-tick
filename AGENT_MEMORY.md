# 🧠 AGENT_MEMORY — Stock-Tick 项目上下文

> **用途**：每次新会话开始时，Agent 先读取此文件恢复项目记忆。
> **更新规则**：重大设计决策、新指标、架构变更后同步更新。

---

## 一、项目定位

| 项目 | 说明 |
|------|------|
| **名称** | stock-tick — A股/港股实时盘中监控仪表盘 |
| **形态** | 纯前端单文件 HTML（~2300行），零后端 |
| **入口** | `index.html` |
| **线上 COS** | `https://stock-tick-1422784620.cos-website.ap-shanghai.myqcloud.com` |

### 核心目标

**帮助日内交易者在盘中快速识别高胜率交易信号，不是替代决策而是增强感知。**

关键原则：
- 不预测涨跌，只识别「趋势衰竭 + 极端区域 + 异常行为」
- 能用数据说话的不靠猜
- 信号有置信度分级，低置信信号不做决策依据

---

## 二、Agent 身份设定

**你是这个项目的「量化分析合伙人」——不是一般的写代码助手。**

### 你应该具备的知识

1. **缠论基础**：背驰（不是背离）是核心信号——价格新极值 + DIF 反向走。理解段分析（前后段斜率、量能对比）。
2. **技术指标**：MACD、KDJ、RSI、MA、VWAP 的原理和适用边界。
3. **A股/港股交易规则**：A股红涨绿跌、港股绿色上涨；交易时间、集合竞价、午休。
4. **Lightweight Charts v4 API**：`ISeriesPrimitive`、`setMarkers`、`panePrimitives`、多面板布局。
5. **东方财富 API 限制**：`push2delay` 有 CORS 头，`trends2/get` 只返当日分钟数据，腾讯财经做日线回退。
6. **数据边界认知**：没有 Level-2 就无法区分主力吸筹 vs 出货。同一组量价数据可以有两种完全相反的解释。

### 你应该具备的技术能力

1. **背驰段分析**：对比前后段斜率 + 量能，判断趋势阶段（急跌末端 / 下跌中继 / 下跌加速）。
2. **置信度判断**：知道哪些信号确定性高（背驰+量价双验证），哪些低（放量方向、资金流向）。
3. **Anti-过度拟合**：不会因为用户提出一个想法就无脑实现。会先评估数据可信度、信号增量价值。

### 你应该坚持的原则

1. **不复述图表已有信息**：分时图表有背驰箭头 → 洞察卡不再重复显示背驰。
2. **置信度分级**：
   ```
   🔴 高置信：5分/日线背驰+三层验证、日线KDJ极端值、MA排列
   🟡 中置信：VWAP偏离、MACD金叉死叉、放量+方向
   ⚪ 低置信：吸筹、连续大单、资金流向 → 标注「仅供参考」
   ```
3. **信号增量 > 信号数量**：宁可少报，不报噪声。加一个指标前先问：「它比已有的多提供了什么信息？」
4. **先讨论后执行**：涉及布局变更、新模块、架构调整时，先讨论方案再动手。

---

## 三、技术架构

### 文件结构

```
stock-tick/
├── index.html          # 主文件（纯前端，~2300行）
├── DEPLOY_LOG.md       # 部署日志
├── AGENT_MEMORY.md     # 本文件
├── README.md           # 项目说明
├── _redirects           # Netlify 重定向配置
└── dashboard_0700.html # 旧版备份
```

### 数据源

| 用途 | API | 说明 |
|------|-----|------|
| 实时报价 | `push2delay.eastmoney.com/api/qt/stock/get` | 含主力资金流向字段 |
| 分钟趋势 | `push2delay.eastmoney.com/api/qt/trends2/get` | ndays=1，仅当日数据 |
| 日线K线 | `web.ifzq.gtimg.cn/appstock/app/fqkline/get` | 15天OHLC，腾讯财经 |
| 搜索 | `searchadapter.eastmoney.com/api/suggest/get` | JSONP |

### 关键技术决策

- **价格单位**：存储为自然单位（元），港股 priceScale=1000 用于展示转换
- **MACD**：分时(6,13,5)、5分K(12,26,9)、日K(12,26,9)
- **KDJ**：统一(9,3,3)，日线用腾讯日K数据计算，分时跨周期引用日线J值
- **背驰**：minDist=10(分时)、4(5分K)、2(日K)，隔峰背驰独立检测
- **背驰段分析**：从极值点往回搜30根，对比前后段斜率+量能
- **图表标记**：size='auto'，随K线缩放自适应
- **CACHE_VERSION**：每次上线 +1，避免 CDN 缓存

---

## 四、三 Tab 洞察卡分工

| 卡类型 | 分时 | 5分K | 日K |
|------|:--:|:--:|:--:|
| MACD背驰 | ❌ 图表有箭头 | ✅ 核心+段分析 | ✅ 核心+段分析 |
| KDJ J值 | ✅ 日线跨周期 | ❌ | ✅ 图表标记 |
| 吸筹 | 🐋 分时主力 | — | — |
| 连续同向大单 | 💪 分时主力 | — | — |
| 大单异动 | 💰 分时 | — | — |
| 量价背离 | — | ⚠️ 5分K | — |
| MACD金叉死叉 | ✅ 低优先 | ✅ 低优先 | ✅ |
| MA排列 | — | — | ✅ |
| RSI超买超卖 | — | — | ✅ |
| 量能对比 | — | — | ✅ 今日vs5日均量 |
| 盘面综述 | 兜底 | 兜底 | 兜底 |

---

## 五、置信度体系

### 🔴 高置信（可独立作为交易信号参考）

- 5分/日线底背驰 + 急跌末端 + 后段量缩 ≥30%
- 5分/日线顶背驰 + 急涨末端 + 后段量缩 ≥30%
- 日线KDJ J<0 超卖 / J>100 超买
- MA多头排列（MA5>MA10>MA20，价格站上所有均线）
- MA空头排列（MA5<MA10<MA20，价格跌破所有均线）

### 🟡 中置信（辅助验证，不单独决策）

- VWAP 偏离 ±2%
- MACD 金叉/死叉
- 放量异动 + 方向（仅陈述「这分钟买方/卖方更强」）
- RSI 超买超卖
- 量能对比（今日量 vs 5日均量）

### ⚪ 低置信（仅供参考，标注「待确认」）

- 吸筹模式 —— 横盘+间歇放量既可能是吸筹也可能是出货
- 连续同向大单 —— 可能是主力，也可能是散户共振
- 资金流向 —— 东方财富算法黑箱

---

## 六、已实现的关键函数

| 函数 | 用途 |
|------|------|
| `analyze()` | 分时模式分析引擎，产出 insights + sigs |
| `build5MinChartData()` | 5分K聚合+MACD+背驰+洞察 |
| `buildDailyChartData()` | 日K蜡烛+MA+RSI+KDJ+洞察 |
| `detectMACDDivergence()` | 全量背驰检测（含 idx1/idx2） |
| `analyzeDivergenceContext()` | 三层分析：趋势阶段+量价验证 |
| `calcKDJ()` / `calcRSI()` / `calcMA()` | 指标计算 |
| `detectAccumulation()` | 吸筹模式检测 |
| `detectConsecutiveBigOrders()` | 连续同向大单检测 |
| `detectVolPriceDivergence()` | 5分K量价背离 |
| `drawDivergenceSegments()` | 背驰段矩形可视化（panePrimitive） |
| `buildSegments()` | 提取段坐标用于矩形渲染 |

---

## 七、部署流程

```bash
# 腾讯云 COS（主力，一行命令）
cd ~/百度同步盘/Pi/项目/stock-tick
export COS_SECRET_ID=xxx COS_SECRET_KEY=xxx
./deploy.sh cos

# Netlify（备用，额度已用尽）
# ego-browser → https://app.netlify.com/projects/stock-tick/overview
# uploadFile('#dropzone-file-upload', '/tmp/stock-tick-vX.zip')
```

部署前确认：`CACHE_VERSION += 1`，更新 `DEPLOY_LOG.md`

---

## 八、已知局限

1. **无 Level-2 数据**：无法区分吸筹/出货，无法做逐笔分析
2. **资金流向不可靠**：东方财富算法黑箱，仅供参考
3. **昨日 K 线依赖缓存**：`trends2/get` 不再返回昨日数据
4. **搜索接口不稳定**：东方财富 JSONP 偶尔超时
5. **图表库版本**：Lightweight Charts v4.1.3 CDN，注意 API 兼容
