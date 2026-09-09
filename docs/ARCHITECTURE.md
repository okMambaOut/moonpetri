# 架构与设计取舍

## 模块

- `moonpetri.mbt`：网络构造、token 快照、enabled/fire、BFS 和前驱数组。
- `validation.mbt`：模型不变量和显示名称／导入 ID 查询。
- `xml.mbt`：有深度、输入长度上限的严格扫描器。位置按 UTF-16 code unit 计数。
- `pnml.mbt`：白名单 schema 检查、二遍 ID 引用解析、语义构造和规范化序列化。
- `evidence.mbt`：保守有界性、place 已观察最大值、死锁最短见证。
- `commands.mbt`：纯函数式命令层，接收文件内容，返回文本或诊断；不访问文件系统。
- `cmd/moonpetri`：CLI 适配层，仅此处使用 x/fs 和 x/sys。

## 关键不变量

网络为可追加 builder，place 和 transition 顺序决定整数 ID。所有构造错误在变更前检查，同向重复 arc 合并。外部不能直接修改模型 backing array。Marking 的 token 数组被封装，公开 getter 返回副本。

Firing 在新数组中完整消耗输入后生成输出。因此单 place 同时为输入／输出不会被错误地当作“提前产生 token”，中途失败不会污染源 marking。序列返回零起点失败位置、transition 和原因。

BFS 以状态数组兼作队列；字符串 token 指纹去重。每个发现的状态只存父状态下标及 transition，而非复制整条路径。遍历 transition 按声明顺序；最短轨迹相同时稳定地选择先发现者。死锁在探索时固定记录，避免之后修改 builder 改写旧分析结果。

对于 S 个保存状态、P 个 place、T 个 transition，核心状态存储约 O(SP)，前驱约 O(S)。执行开销取决于 arc 数量及每次 marking 复制；指纹字符串也有 O(P) 成本，不声称常数内存或无限规模适用。`max_states` 控制状态数，不是运行时间。

完整闭合的有限搜索能够证明从该起点可达的网有界；截断结果仅为 Unknown。没有启发式“超过某个 token 就证明无界”的错误推断。

## PNML 取舍

不用不完整的正则匹配冒充 XML：扫描器检查嵌套／闭合、属性分隔与重复、实体白名单，然后验证领域元素及引用。也不导入完整 XML 框架扩大依赖：明确拒绝 namespace、page、扩展、DTD、注释等，因此是受限交换格式而非通用 PNML 标准实现。

序列化是规范化而非保真编辑，XML ID 会重命名；库内语义顺序、名称、initial marking 和权重保持。库导入时保留 transition 原始 ID 供 CLI 查询。

## 当前不足

ID 仍是 `Int`，不能识别来自另一网络但数值相同的 ID。深度／长度限制仅在字符串解析层生效，CLI 读取文件前没有流式配额。没有完整 coverability 算法、强类型 ID、增量分析或生产级内存预算。这些不足公开记录，不用“全部实现”掩盖。
