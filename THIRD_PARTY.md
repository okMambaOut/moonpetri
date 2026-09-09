# 第三方依赖与来源

MoonPetri 的领域模型、BFS、受限 PNML 扫描器、测试数据和示例为本项目实现，不是其他项目的源码移植。

| 依赖／参考 | 用途 | 许可证／处理方式 |
| --- | --- | --- |
| MoonBit 工具链及 `moonbitlang/core` | 编译、数组、Map、字符串、测试及 CLI 参数 | core 为 Apache-2.0；由工具链提供，不复制源文件 |
| `moonbitlang/x@0.5.4`，https://github.com/moonbitlang/x | 仅 CLI 使用 `fs` 读取本地文件、`sys` 返回退出状态 | Apache-2.0；通过包管理器下载，不将 `.mooncakes` 打包进本仓库 |
| PNML 文档，https://www.pnml.org/ | place、transition、arc、initialMarking、inscription 的概念参考 | 不复制规范文本、Schema 或他人解析器代码 |
| `actions/checkout`、`actions/setup-python` | CI 基础设施 | MIT；在 GitHub runner 调用，不随库分发 |

领域库本身只依赖 core，不使用网络、C FFI 或外部服务。CLI 的文件系统依赖在 native 目标包含上游 C stub，不能把整个 CLI 宣称为“没有任何 C 依赖”。PNML 文件及测试均为项目原创构造，不来自外部数据集。

未使用相邻项目的源码。相邻项目只用于查重比较，详见 `docs/competition/duplicate-check.md`。依赖许可证不会因主项目选择 MIT 而改变。
