# 三个可运行场景

从仓库根目录运行 `python scripts/smoke.py`，会实际启动 CLI、读取本目录文件并断言结果。

1. **生产者/消费者**：HTTP 等系统的队列设计者将容量 2 表示为 `free + buffer = 2`，生产消耗空闲容量、消费归还容量。探索应为 3 个状态、4 条 firing 边；连续生产三次必须失败，防止“无容量约束的单次消费”冒充生产者模型。
2. **交通灯**：控制逻辑开发者输入红—绿—黄三状态循环，探索应为 3 个状态、3 条边；执行 `t_green t_yellow t_red` 回到 `[1,0,0]`。这只验证逻辑 token，不包含时间或真实交通安全认证。
3. **死锁**：并发资源建模者输入两个均无可用输入 token 的 transition，初始 enabled 数量应为 0，报告 1 个死锁；不将“只在截断边界未探索”误认成死锁。

运行示例：

```sh
moon run cmd/moonpetri -- explore examples/producer-consumer.pnml --max-states 100
moon run cmd/moonpetri -- fire examples/traffic-light.pnml t_green t_yellow t_red
moon run cmd/moonpetri -- report examples/deadlock.pnml
```

PNML 为本项目原创测试数据，无外部版权素材。
