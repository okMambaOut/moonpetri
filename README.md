# MoonPetri

维护者：okmanba（GitHub 登录名 okMambaOut）

MoonPetri 是用 MoonBit 编写的离线加权 Petri 网分析库。它从 place、transition、arc 和初始 token 出发，执行 firing，用有限 BFS 探索状态、重建最短轨迹并发现死锁。面向队列和并发资源建模，不是 HTTP 库或 GUI。

## 安装

需要 MoonBit 工具链。CLI 文件读取依赖 moonbitlang/x。

```text
moon add okMambaOut/moonpetri@0.1.3
```

源码运行：

```sh
git clone https://github.com/okMambaOut/moonpetri.git
cd moonpetri
moon update
moon check --target wasm-gc --deny-warn
moon test --target wasm-gc
moon run examples/api-demo
```

## 功能

- 构建并验证加权 place/transition 网
- enabled、fire、fire_sequence
- 有限 BFS 可达性、最短 firing 轨迹、死锁证据
- 受限 PNML 导入导出
- CLI：validate、explore、fire、report

## 示例

```moonbit
let net = @petri.PetriNet::new()
let free = net.add_place("free", 2).unwrap()
let buffer = net.add_place("buffer", 0).unwrap()
let produce = net.add_transition("produce").unwrap()
let consume = net.add_transition("consume").unwrap()
ignore(net.add_input(free, produce, 1).unwrap())
ignore(net.add_output(produce, buffer, 1).unwrap())
ignore(net.add_input(buffer, consume, 1).unwrap())
ignore(net.add_output(consume, free, 1).unwrap())
let result = @petri.reachable(net, net.initial_marking(), 100).unwrap()
let report = @petri.analysis_report(net, result)
```

CLI：

```sh
moon run cmd/moonpetri -- validate examples/producer-consumer.pnml
moon run cmd/moonpetri -- explore examples/traffic-light.pnml
moon run cmd/moonpetri -- report examples/deadlock.pnml
```

## 边界

不承诺完整 PNML 互操作、时间网、随机网、GUI 或系统安全认证。PNML 只接受单个 net，以及 name、initialMarking、inscription 文本字段。

## 许可证

MIT。维护者为 okmanba，GitHub 账号为 okMambaOut。
