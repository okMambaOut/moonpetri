# 有效提交证据（本地核验）

核验日期：2026-09-09。此表列出 **20 个已存在、非空、可核验的实质提交**，不是把原始 commit 总数直接当作有效数。

身份重写不增加数量。历史中的格式提交、单项机械测试拆分、修复自身语法错误、错误 Action 引用、反复改署名等 21 个旧提交保留以便审计，但不计入下表。没有空提交，也没有人为回填开发日期。后续审计文档提交本身不用于凑这 20 项。

证据层级：SHA 和 diff 证明对应变更实际存在；提交时新功能附带的测试已运行，完整最终回归见 local-verification.md。最早两项只作为真实初始实现／测试里程碑，不声称早期版本通过了今天的完整 gate。本表各里程碑的验证描述以本地证据为基础；随后通过的远程四目标 CI 见 completion-audit.md。

| 序号 | SHA | 实际主题 | 变更与验证依据 |
| --- | --- | --- | --- |
| 1 | `96b920fa08fb4fd6f3d987f680f63b7777df5199` | chore: initialize MoonPetri repository | 初始领域模型、firing/BFS 与模块骨架；历史占位项不作为已完成功能。最终验证覆盖修复后的模型。 |
| 2 | `7fe72fcf0c3bebffdd9c06b113deccd8d90e3c0a` | feat: add tests and project documentation | 首次构造/执行与死锁回归测试；其中不完整文档和错误 CI 不作为通过证据。 |
| 3 | `b72fe822b264514a2628d0c6867918bea5347d30` | fix: reject token overflow and invalid model inputs atomically | 溢出原子性、非法 marking、重复名称和 ID/weight 验证测试。 |
| 4 | `e11b3aab9cafc0a61572a0e84e7dafc56dac8f37` | fix: return contextual firing-sequence failures and isolated snapshots | 失败位置/transition 诊断、空序列验证和快照隔离。 |
| 5 | `79d2799e21e1bac0ee43242438868cf2700d6c2f` | perf: reconstruct shortest BFS traces from linear-space predecessors | 前驱替代复制轨迹；最短路径竞争、截断和起点隔离测试。 |
| 6 | `827f098f5c263f1a6f0e227248ee90f785ce0386` | feat: implement strict PNML import with bounded XML scanning and diagnostics | 真实严格 PNML 扫描/导入；错误闭合、实体、引用、权重、扩展反例。 |
| 7 | `879a49bb272221faf377b4fe2782a0c392b55e8e` | feat: serialize canonical PNML with escaped labels and semantic roundtrips | 转义、规范化序列化、空网/中文标签和 firing roundtrip。 |
| 8 | `fa4c571d7a5dfc645a29ee44ef9dd00a1557580d` | feat: expose deterministic model validation and transition lookup | 确定性 validate 与查询；内部损坏诊断和缺失名称查询。 |
| 9 | `70998946ab4d42c63d7d46357943b293e2c2182b` | feat: add offline file CLI and deterministic command/report interface | 实际文件 I/O CLI、无 I/O 命令引擎、结构化输出和参数反例。 |
| 10 | `baf3629aed80e5efd04ccae85d46c37df1cd6e79` | test: replace placeholder scenarios with executable capacity cycle and deadlock acceptance | 三个领域场景的数据和真实进程验收；13 次正反例调用。 |
| 11 | `403101115a9b1491bac110c2a24df6d9990abf32` | fix: enforce PNML declaration text and resource-limit security boundaries | XML 声明、BOM、非法文本、大小/深度边界。 |
| 12 | `6dc9a1171db9a68651e257a9349636768f72ccf8` | fix: encapsulate model and reachability arrays behind defensive snapshots | 封装可写数组；证明 getter 与状态列表不会污染分析。 |
| 13 | `97ffba4277c3f9503a16abb836204ace2e21caa7` | feat: retain deadlock witnesses and expose conservative boundedness evidence | 探索时固定死锁、见证路径、保守有界性和逐 place 最大值。 |
| 14 | `66b4afbb471bb74d0e27681beeb7f6aa8e8c977b` | fix: preserve imported transition identifiers for CLI firing with Chinese labels | 保留导入 transition ID，中文标签仍能按原 ID 执行。 |
| 15 | `1666253d5be969c4bb7abd3b35b528f0ed530eca` | test: verify weighted-firing conservation and roundtrip invariants exhaustively | 穷举 80 组 self-loop 参数、7 个容量网、trace 重放/序列化一致性及控制字符拒绝。 |
| 16 | `695a73cbceb9b1b66600b0df11695226c229faad` | docs: restore complete MIT license and accurate security provenance guidance | 完整 MIT、真实 CLI 依赖/安全限制、AI 历史纠错和贡献流程。 |
| 17 | `dafc6072e12dcb12e8879f2ea8bd937f6223bf75` | docs: replace README with Chinese runnable guide and audited public API boundaries | 中文 README、三个实际输出、可执行 API demo、接口快照及明确未实现边界。 |
| 18 | `a0950b855875eb4db223f6b32fbc80e312cf6f1c` | fix: normalize Node argv and isolate generated JavaScript module mode | 真实 JS 验收发现并修复 Node argv 偏移；项目级 ESM 设置，不改父级配置。 |
| 19 | `7455d8c26e4c601ed15b3f17a17a68649a0aaff4` | ci: enforce nonzero tests build and real CLI acceptance across four targets | 修复不存在的 Action，加入全目标 check/build/test/CLI 和非零测试保护；本地除 native runtime 外通过，远程尚未运行。 |
| 20 | `dab5793aa2ce86062af29f13e9b730c41aa6d056` | docs: refresh duplicate review with MoonBDD comparison and reproducible search evidence | 9 组 MoonCakes/4 组 GitHub 检索原始响应，补充 MoonBDD 相邻风险，纠正两个失效仓库地址。 |

复核方式：`git show --stat SHA`、`git show SHA`；在工作树运行 `python scripts/readiness.py --skip-native-runtime`。完整 native 运行需要 C 编译器或 GitHub runner，不能用静态检查代替。

同名公开仓库已重建，表中 20 项历史均已推送，并通过公开 commit API 核验 author/committer 均关联 okMambaOut；参见 completion-audit.md。
