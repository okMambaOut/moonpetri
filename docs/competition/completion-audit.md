# 完成度与身份审计

核验日期：2026-09-09。**仓库已按用户要求删除并重建；修正历史已公开，贡献者 API 仅返回 okMambaOut；四目标 CI 已通过。** 申报书个人信息已由参与者提供并仅写入仓库外文件，严格结构检查通过。本文件是发布前审计快照；MoonCakes 尚待登录身份核对，不宣称赛事全部验收完成。

## 身份／Git

- `gh api user`：`okMambaOut`，账户 ID `316556870`；当前 CLI 激活账号一致。
- 展示署名及 Git author/committer：`okmanba <316556870+okMambaOut@users.noreply.github.com>`。
- 仓库 `okMambaOut/moonpetri` 已重建为 public，默认分支 `master`，当前权限 `ADMIN`。
- 逐页读取公开 commit API，已核验修正历史全部 author.login 和 committer.login 均映射到 `okMambaOut`；contributors API 仅有 `okMambaOut`。
- 用户授权的旧 AI 生成提交身份修正已保留外部 Git bundle 备份；备份及申报书未上传。没有改动父目录仓库。
- 有效提交证据表列出 21 个实质里程碑，不把所有原始历史都算作有效，不把纯审计文档计数；新增的发布包审计有独立实现和测试。

## CI 与发布证据

- 首次运行 https://github.com/okMambaOut/moonpetri/actions/runs/34369854301 失败：滚动编译器格式规则与本机验证版不同，未隐瞒或跳过检查。
- 修复：`.moonbit-version` 固定 `0.10.4+2cc641edf`，官方安装脚本按该版本安装。
- 已通过运行：https://github.com/okMambaOut/moonpetri/actions/runs/34370073300 ，代码提交 `d964436d74ab502b3d0dd8044875cfb799d506ff`。
- CI 在 Ubuntu 真实执行 wasm-gc/wasm/js/native 的 check、build、各 28 项测试、各 13 项 CLI 调用和 API demo；接口再生成未造成工作区变化。
- 新增发布包审计运行：https://github.com/okMambaOut/moonpetri/actions/runs/34371125273 ，提交 `ead489b8b4b34bc70691e2b72db042cace012191`；四目标 gate、7 项 Python 安全回归、实际 ZIP 审计均通过。
- 本地 Windows native 缺 C 编译器的事实保留；native runtime 的成功证据来自上述 CI，不冒充本机执行。
- runner 提示 checkout@v4/setup-python@v5 的 Node 20 运行时弃用，并强制使用 Node 24；本次运行成功，后续应评估 Action 升级。
- 发布门禁：本审计文档提交也必须在 master 通过 CI，才将 `v0.1.0` 指向该提交并创建 Release；禁止推送旧本地标签。最终状态可用下述命令复核，本文不预测未运行检查的结果。

```sh
gh api repos/okMambaOut/moonpetri/contributors --jq '.[].login'
gh api repos/okMambaOut/moonpetri/commits/master --jq '{sha: .sha, author: .author.login, committer: .committer.login}'
gh run list --repo okMambaOut/moonpetri --branch master --limit 3
gh release view v0.1.0 --repo okMambaOut/moonpetri
```

## Skill 对照

| 要求 | 证据／状态 |
| --- | --- |
| MoonBit 核心、领域功能 | 加权 firing、严格 PNML 子集、BFS、CLI，非占位 parser |
| 中文 README 与三个完整场景 | README.md、examples/README.md、三个 PNML、API demo、scripts/smoke.py |
| 检查／构建／测试／错误输入 | local-verification.md 与上述四目标绿色 CI |
| 至少 20 个有效提交 | commit-evidence.md 的 21 个 SHA、非空变更及验证说明 |
| MIT／第三方／AI／安全／贡献说明 | LICENSE、THIRD_PARTY.md、AI_USAGE.md、SECURITY.md、CONTRIBUTING.md |
| 查重及官方助手流程 | duplicate-check.md、search-evidence.json；含 MoonBDD 的实际相邻能力对比 |
| GitHub public／owner／实际贡献 | 重建后 API 核验，唯一贡献者 okMambaOut |
| Release | 依上节发布门禁生成 v0.1.0；以公开 Release 和 tag 对应提交为准 |
| 申报书 | 个人信息仅存仓库外，严格结构检查通过；外部发布状态在实际完成后同步更新 |
| MoonCakes | 用户已明确授权协助发布；本快照生成时 CLI 登录身份与项目不符，未执行发布 |

## 明确边界

ID 是网络内整数索引，不是防跨网混用的 PlaceId/TransitionId；没有独立 FireResult。PNML 仅平面白名单子集，不支持 page/namespace 等完整互操作语义；输入限制不是完整沙箱。这些均在中文 README 说明，不宣称原计划每一项都已完成。
