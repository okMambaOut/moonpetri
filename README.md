# MoonPetri

MoonPetri 是一个纯 MoonBit 实现的、离线且确定性的离散 Petri 网建模与有限可达性分析库。

## 项目定位

MoonPetri 面向并发协议建模、生产者/消费者系统、教学实验和测试工具。它不实现完整 HTTP 生命周期，也不依赖网络服务、C FFI 或第三方运行时。

核心流程是：

```text
定义 place、transition 和加权 arc
→ 构造 marking
→ 判断 transition 是否 enabled
→ 执行 firing
→ 使用确定性 BFS 搜索有限可达状态
→ 分析 deadlock、最短 trace 和统计报告
```

## 核心功能

- place、transition 和输入/输出 arc 建模；
- 初始 token 与 marking 操作；
- transition enabled 判断；
- firing 与 firing sequence；
- 稳定 marking 指纹；
- 按 transition 声明顺序遍历的 BFS 可达性搜索；
- 状态上限、前驱 trace、deadlock 和结构化分析报告；
- place/transition 数量和名称查询；
- 无外部运行时依赖的 MoonBit 核心库。

## 三个独立示例场景

### 1. 生产者/消费者模型

使用 `examples/producer-consumer.pnml` 表示带有 buffer place 的生产者/消费者场景。输入 arc 消耗 buffer token，适合验证容量限制、enabled transition 和 firing 后 marking 的变化。

### 2. 交通灯模型

交通灯场景由多个表示灯光状态的 place 和按顺序触发的 transition 构成。它适合验证状态循环、transition 声明顺序以及最短 firing trace。

### 3. 死锁模型

使用 `examples/deadlock.pnml` 表示初始 marking 中没有足够 token 的网络。探索完成后，`deadlocks` 可以报告没有任何 enabled transition 的 marking。

## 使用示例

```moonbit
let net = @moonpetri.PetriNet::new()
let buffer = net.add_place("buffer", 1).unwrap()
let consume = net.add_transition("consume").unwrap()
net.add_input(buffer, consume, 1).unwrap()
let result = @moonpetri.fire(net, net.initial_marking(), consume).unwrap()
assert_eq(result.tokens[buffer], 0)
```

## 设计边界

MoonPetri 不实现通用有限状态机、工作流引擎、SAT/SMT 求解器、时间 Petri 网、随机 Petri 网、有色 Petri 网或 GUI。PNML 接口采用严格子集策略；不把它宣称为完整 XML/PNML 解析器，遇到不支持的语法会返回明确诊断。

## 本地验证

```text
moon fmt --check
moon check --target wasm-gc --deny-warn
moon check --target wasm --deny-warn
moon check --target js --deny-warn
moon check --target native --deny-warn
moon test --target wasm-gc
```

当前测试结果：10 个测试通过。CI 配置位于 `.github/workflows/ci.yml`。

## 贡献

贡献者：**Han-Wentao**。提交修改前请阅读 `CONTRIBUTING.md`，保持结果顺序确定，新增行为必须补充回归测试。

## 许可证

MIT，详见 `LICENSE`。
