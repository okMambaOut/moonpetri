# 本地工程验收记录

日期：2026-09-09。系统 Windows；`moon 0.1.20260713`，`moonc v0.10.4+2cc641edf`，依赖 `moonbitlang/x@0.5.4`。

实际执行：`python scripts/readiness.py --skip-native-runtime`，退出码 0。脚本拒绝 0 测试／只有编译没有测试的伪通过；未执行的 native runtime 会显式输出 SKIPPED。

| 项目 | wasm-gc | wasm | js | native |
| --- | --- | --- | --- | --- |
| `moon check --deny-warn` | 通过 | 通过 | 通过 | 通过 |
| `moon build` | 通过 | 通过 | 通过 | 未通过本地执行条件 |
| `moon test --deny-warn` | 28/28 | 28/28 | 28/28 | 未运行成功 |
| 三场景 CLI＋错误输入 smoke | 13/13 | 13/13 | 13/13 | 未执行 |
| API demo／最短轨迹重放断言 | 通过 | 通过 | 通过 | 未执行 |

额外：`moon fmt --check` 通过；`moon info` 后公开接口无变化。

实际尝试 `moon test --target native`，失败原因：`no system C compiler found; tried cl, cc, gcc, clang`。这是构建环境缺失，不是成功的 native 测试。GitHub workflow 已安排四目标检查、构建、测试和运行，但仓库重建／推送待授权，**远程 CI 尚未证明通过**。

## 真实验收输出

- producer-consumer validate：`valid places=2 transitions=2 enabled=1`
- producer-consumer explore：`states=3 edges=4 deadlocks=0 max_tokens=2 truncated=false`
- produce→consume：`marking=[2,0]`；连续三次 produce：非零失败。
- traffic-light explore：`states=3 edges=3 deadlocks=0 max_tokens=1 truncated=false`
- 红→绿→黄→红：`marking=[1,0,0]`
- deadlock report：`{"states":1,"edges":0,"deadlocks":1,"max_tokens":0,"truncated":false}`
- malformed PNML：两次真实运行均非零，输出 `error: ParseError("XML offset 23: unclosed element")`
- API demo：目标 `[0,2]` 的 `shortest_trace=[0,0]`，脚本实际重放并校验结果。

以上是本机可复现证据，不是赛事官方验收、不证明生产级安全，也不代替 MoonCakes 发布。
