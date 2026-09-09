# MoonPetri：离散 Petri 网建模与可达性分析

**维护者／贡献者：okmanba（GitHub 登录名：`okMambaOut`）。**

MoonPetri 是 MoonBit 编写的离线加权 place/transition 网分析库：从 places、transitions、arcs 和初始 token 出发，执行 firing、用 BFS 探索状态、重建最短轨迹并发现死锁。它面向队列／并发资源模型设计者、控制逻辑开发者和模型测试工具，而不是 HTTP 库、通用工作流引擎或 GUI。

```text
构造模型或导入受限 PNML → 验证 → enabled / fire → 有限 BFS
→ 最短 firing trace、死锁证据、稳定文本或 JSON 报告
```

## 安装与首次运行

需要 MoonBit 工具链；CLI 文件读取依赖 `moonbitlang/x@0.5.4`，由 `moon update` 下载。验收脚本另需 Python 3；JS 目标需 Node.js；native 构建和测试需 C 编译器。

```sh
git clone https://github.com/okMambaOut/moonpetri.git
cd moonpetri
moon update
moon check --target wasm-gc --deny-warn
moon test --target wasm-gc
moon run examples/api-demo
```

本地验证工具链为 `moon 0.1.20260713` / `moonc v0.10.4+2cc641edf`。**尚未发布 MoonCakes**，因此这里不提供会失败的 `moon add okMambaOut/moonpetri` 安装承诺；目前从源码运行。比赛要求的包发布仍由参赛者单独完成。

## 三个可复现的使用场景

### 1. 队列设计者：验证生产者／消费者容量

输入 `examples/producer-consumer.pnml`：空闲容量初始 2、缓冲区初始 0，生产消耗一个空闲 token、消费归还一个。价值是检查生产不能突破容量，而不是只演示单次消费。

```sh
moon run cmd/moonpetri -- validate examples/producer-consumer.pnml
# valid places=2 transitions=2 enabled=1
moon run cmd/moonpetri -- explore examples/producer-consumer.pnml --max-states 100
# states=3 edges=4 deadlocks=0 max_tokens=2 truncated=false
moon run cmd/moonpetri -- fire examples/producer-consumer.pnml t_produce t_consume
# marking=[2,0]
```

连续执行三次 `t_produce` 返回 `SequenceFailed(2, 0, NotEnabled)`，不会修改起始 marking。位置从 0 计数。容量守恒为 `free + buffer = 2`。

### 2. 控制逻辑开发者：验证交通灯循环与最短轨迹

输入 `examples/traffic-light.pnml`：红、绿、黄三个 place 和三次转换。价值是验证循环可达和 token 唯一性；不包含时间控制或实际交通系统安全保证。

```sh
moon run cmd/moonpetri -- explore examples/traffic-light.pnml
# states=3 edges=3 deadlocks=0 max_tokens=1 truncated=false
moon run cmd/moonpetri -- fire examples/traffic-light.pnml t_green t_yellow t_red
# marking=[1,0,0]
```

库 API 的 `shortest_trace` 返回 BFS 首次发现的最短转换序列；相同长度按 transition 声明顺序选择。`examples/api-demo` 实际断言最短轨迹能重放到目标 marking；单元测试验证多个路径竞争时选择最短序列。

### 3. 并发资源建模者：发现并解释死锁

输入 `examples/deadlock.pnml`：两个 transition 都需要不存在的资源 token。价值是找出没有 enabled transition 的状态及其见证轨迹。

```sh
moon run cmd/moonpetri -- validate examples/deadlock.pnml
# valid places=2 transitions=2 enabled=0
moon run cmd/moonpetri -- report examples/deadlock.pnml
# {"states":1,"edges":0,"deadlocks":1,"max_tokens":0,"truncated":false}
```

`deadlock_traces(result)` 返回每个死锁 marking 和最短 trace。截断边界仍有 enabled transition 的状态，不会被误报为死锁。

三个场景和错误输入均由真实文件／进程验收脚本验证：

```sh
python scripts/smoke.py
```

## 库 API 与数据语义

完整可编译用例：`examples/api-demo/main.mbt`。在其 `moon.pkg` 中导入：

```moonbit
import {
  "okMambaOut/moonpetri" @petri,
}
```

核心 API（完整类型签名见生成的 `pkg.generated.mbti`）：

| API | 用途 |
| --- | --- |
| `PetriNet::new/add_place/add_transition/add_input/add_output` | 构造网络，拒绝重复名称、非法权重／ID，重复同向 arc 合并且检查溢出 |
| `initial_marking/validate` | 获取初始快照／检查模型不变量 |
| `marking/Marking::token/Marking::tokens` | 构造 token 快照、读取单个值或防御性副本 |
| `enabled/enabled_transitions/fire/fire_sequence` | 完整输入消耗后生成输出，不修改原始 marking |
| `reachable/shortest_trace` | 状态去重、硬上限 BFS、前驱重建最短路径 |
| `deadlocks/deadlock_traces` | 返回本次探索记录的死锁及最短见证 |
| `boundedness/observed_place_maxima` | 区分已证明有限与未知；每个 place 的已观察最大 token |
| `parse_pnml/serialize_pnml` | 导入文档所述子集、按规范化 ID 序列化 |
| `analysis_report/AnalysisReport::to_json/run_command` | 无网络、稳定结构化输出和可嵌入命令执行 |

- ID 当前是网络内按插入顺序分配的 `Int` 索引，**不是携带网络所有权的强类型 ID**；同索引来自不同网无法自动区分，请勿混用。`PlaceId`、`TransitionId` 强类型封装和独立 `FireResult` 尚未实现。
- token/weight 范围为 32 位有符号整数；token 非负、weight 严格为正。合并权重与 firing 溢出返回 `TokenOverflow`。
- `marking()` 复制数组；与网络维度和非负约束在执行／探索时检查。公开 marking 和可达状态不暴露可写的底层数组。
- 名称不得为空、空白或包含控制字符；中文及 XML 特殊字符支持安全转义。
- `max_states` 限制保存的状态数量，不限制每个状态的大小。只有遇到一个无法保存的新状态才标记截断；刚好达到上限但搜索已闭合不算截断。
- `edges` 统计已保存状态的所有成功 firing，包括指向已发现状态和截断后未保存的新状态的边。`max_tokens` 是**单个 place** 的已观察最大值，不是 token 总数。
- `boundedness()` 返回 `ProvenBounded` 或 `Unknown`。兼容 API `is_bounded=false` 仅表示无法在本次上限内证明有界，**不证明数学无界**。
- 死锁证据保存在探索结果中。后来向 builder 加 transition 不会改变旧结果；`deadlocks(net,result)` 的 net 参数仅为兼容保留。

## PNML：明确受限，不等价于完整 XML／PNML 解析器

支持单个 `<pnml><net id="...">`，net 下直接声明 place、transition、arc；支持 `<name><text>`、`<initialMarking><text>`、`<inscription><text>`、可选 P/T net type URI，初始 token 默认 0、权重默认 1。允许 arc 先于引用的节点出现。CLI `fire` 优先匹配导入文件的 transition ID，再尝试唯一显示名称。

支持单／双引号属性、五个预定义 XML 实体、中文文本；XML 声明只接受 `<?xml version="1.0"?>` 或带 `encoding="UTF-8"` 的对应形式。允许 UTF-8 BOM。序列化保留模型顺序、名称、初始 token 和合并后的权重，但生成新的 `p0/t0/a0` 等 XML ID，不保留排版或外部 ID。

以下行为明确拒绝：多个 net、page／层次结构、namespace、颜色／时间／概率网、toolspecific 扩展、DTD／外部实体／数字实体、XML 注释／CDATA、非法 token 表达式、不完整 XML。解析返回首个稳定诊断，不收集全部语法错误。资源限制详见 SECURITY.md。

## 检查、测试与 CI

```sh
moon fmt --check
moon check --target wasm-gc --deny-warn
moon check --target wasm --deny-warn
moon check --target js --deny-warn
moon check --target native --deny-warn
moon test --target wasm-gc
moon build --target wasm-gc
python scripts/smoke.py
moon run examples/api-demo
# 完整自动检查（native 执行要求 C 编译器）：
python scripts/readiness.py
```

测试覆盖构造验证、溢出、加权 self-loop、序列失败位置、BFS 最短路径／截断、状态快照隔离、死锁证据、PNML 正反例与 roundtrip，以及多容量守恒穷举。CI 配置必须在 GitHub 真实运行后才能称为通过；本地 `moon check --target native` 通过不等于 native 测试通过。

## 项目状态与边界

核心库、受限 PNML、CLI 和三个场景已实现。尚不承诺完整 PNML 互操作性、强类型跨网 ID 检查、coverability、SAT/SMT、时间／随机 Petri 网、GUI、生产级资源隔离或系统安全认证。此前计划中的这些限制应以本 README 的实际实现状态为准。

查重证据见 `docs/competition/duplicate-check.md`；验收／发布状态见 `docs/competition/completion-audit.md`；有效提交证据见 `docs/competition/commit-evidence.md`。这些文件不会把“已有 CI 文件”写成“CI 已通过”。

## 许可证与贡献

项目采用完整 MIT 许可证，见 LICENSE。第三方依赖与概念参考见 THIRD_PARTY.md，AI 使用披露见 AI_USAGE.md。维护者署名为 **okmanba**，GitHub 账号为 **okMambaOut**；Git 提交邮箱使用该账号的 GitHub noreply 身份。参与方式见 CONTRIBUTING.md。
