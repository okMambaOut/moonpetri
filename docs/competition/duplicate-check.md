# MoonPetri 查重与差异化复核

检查／复核日期：2026-09-09。项目为已选定方向的实现复核，不重新包装 MoonCookie。

## 方法与可复核证据

已读取并按本地 `$osc2026-guide` 及 moonbit-hackathon-builder 固定要求自审。它们是检查流程，不是赛事官方对本项目的批准。原始查询、结果版本、来源和已阅读的 README SHA 保存于 `search-evidence.json`。

本机 `moon search` 不可用，改用 `https://mooncakes.io/api/v0/search?kw=关键词&limit=100`，没有伪造 CLI 成功结果。每个词最多取 100 条，返回为模糊匹配，不保证所有包内容和未索引项目都被覆盖。

| MoonCakes 检索词 | 本次返回条数 |
| --- | ---: |
| petri | 32 |
| petrinet | 0 |
| pnml | 0 |
| reachability | 9 |
| coverability | 0 |
| marking | 48 |
| deadlock | 1 |
| model checking | 65 |
| moonpetri | 6 |

GitHub 使用 `gh search repos 'petri language:MoonBit'`、`pnml language:MoonBit`、`petrinet language:MoonBit`、`reachability language:MoonBit`，上限 100；前三项为空，第四项命中一个 Windows 子系统链接示例，与模型可达性无关。仓库搜索不等于代码搜索，不能据此证明生态不存在同类实现。

精确名称并不可靠：`petri` 命中一些 `periodic` 文本，`moonpetri` 也出现模糊结果。因此结论依据概念和相邻 API 边界，而非只有名称是否命中。

## 重点相邻项目

| 项目／已核对来源 | 版本／维护信号 | 能力重合与独立边界 |
| --- | --- | --- |
| `oyjh0381/moonbdd` — https://github.com/oyjh0381/MoonBDD | MoonCakes 0.1.0；已阅读 README | **本轮新发现的重要相邻项目**：ROBDD、布尔函数、符号有限状态可达性及不变量见证。与本项目在“可达性分析”上真实相邻，不能忽略。MoonPetri 输入是整数 marking、加权输入输出 arc，以显式 BFS 和 token 消耗／产生语义分析；没有复制 BDD 引擎或将布尔函数换名为 token。 |
| `Lyl66655/moonbit-workflow-engine` — https://github.com/Lyl66655/moonbit-statemachine | MoonCakes 0.1.4；已阅读实际仓库 README | HSM／工作流及定时调度，不是加权 P/T 网。原计划中的同名 GitHub URL 返回 404，本次按 MoonCakes 元数据纠正链接。 |
| `Rz-coder8848/MoonBit-FSM` — https://github.com/Rz-coder8848/MoonBit-FSM | 未归档；API 显示最近 push 为 2026-08-16；已阅读 README | 有类型化状态机、guard/action、可达性与图检查，不应说它没有任何可达性分析；区别是没有本项目的 place/token、多输入同步消耗与加权产生模型。 |
| `LAOBIAO656/MoonReplayKit` — https://github.com/LAOBIAO656/MoonReplayKit | 未归档；API 显示最近 push 为 2026-07-06；已阅读 README | 事件日志重放、状态证据和差异诊断；本项目生成可达状态空间，不消费历史事件日志。 |
| `bobzhang/loop_invariants_graph` — https://github.com/moonbit-community/loop_invariants | MoonCakes 0.17.0；已阅读实际仓库 README | 通用图、闭包和不变量说明。原计划的 GitHub URL 返回 404，本次按元数据纠正。BFS 本身不是本项目的新颖性，Petri 网建模与 firing 语义才是。 |

`Suquster/moonbit-pathfinding`、`Juwan-Hwang/moon-certified`、`ttxiangshang/moonbit-pixelkit` 等搜索结果提供通用图或格网可达性；`Nanaloveyuki/sync` 的 deadlock 命中属于线程池保护，并非 Petri 状态搜索。它们的包元数据已保存，但不把元数据浏览写成完整源码审计。

## 与永久登记项目的边界

- MoonContract：OpenAPI 与 HTTP 交互验证；本项目不解析 HTTP 或契约。
- MoonCookie：Cookie 状态管理方向已经因成熟实现重合而放弃，不以新名字继续提交。
- MoonDag：依赖任务图、持续时间、关键路径；本项目不是任务调度器，不用 DAG 层级替代 token 语义。
- MoonReplayKit／其他日志与规则项目：已有事件、配置、政策是其核心输入，不是本项目的 marking／firing 状态空间。
- 对登记的补丁、许可证、归档、INI、投票、颜色、帧协议、数值、日历和安全规则等项目，主数据及验收闭环均不同。通用 CLI、JSON、测试和 CI 不作为项目差异化理由。

## 结论与限制

在上述查询和 README 边界检查中，**未发现直接提供成熟 MoonBit 加权 Petri 网建模、PNML 子集导入、marking firing 及显式搜索完整闭环的项目**。这是有限检索结论，不是生态不存在同类库的证明，也不是赛事审核结论。

状态空间分析并非空白领域，MoonBDD 和 FSM 属于真实相邻项目。本项目暂保留独立方向，理由是整数 token 的同步消耗／产生、可变 token 状态空间及 PNML 领域输入，明确不发展成通用符号模型检查器。如后续发现成熟 Petri 库，应复核独立建设必要性，而非仅凭名称不同继续申报。

本项目没有复制相邻项目源码；本次仅检查公开元数据与 README。查重完成不等于包已发布：**MoonPetri 尚未发布 MoonCakes**。
