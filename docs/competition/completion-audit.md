# 完成度与身份审计

核验日期：2026-09-09。结论：**本地主要实现和中文交付材料已修复；远程重建、公开身份归属复核、绿色 CI、Release 与正式申报尚未完成。**

## 身份／Git

- 实际 `gh api user`：`okMambaOut`，账户 ID `316556870`；CLI 当前激活账号一致。
- 展示署名与本地 Git author/committer：`okmanba`；提交邮箱为该登录名的 GitHub noreply 地址。
- 仓库：`okMambaOut/moonpetri`；`gh repo view` 核验公开、默认分支 `master`、当前权限 `ADMIN`。
- 用户明确要求的原 AI 生成提交身份已在备份后纠正；所有保留的本地分支／标签可达提交 author/committer 均为该身份。旧本地备份引用已移除，Git bundle 留在仓库外，不会上传。
- 本地有效里程碑为 20 项，见 commit-evidence.md；格式、机械拆分、反复署名等旧提交不计数。
- **远程仍是旧提交 `15c286dfaaf202cb49030bd62f16cf1a73077839`**。不能宣称 GitHub Contributors 已只剩当前用户；必须在真正重建／推送后使用 commit API 检查 `author.login`、`committer.login` 和 contributors。

## 当前阻塞

GitHub CLI scope 为 `gist, read:org, repo, workflow`，缺少删除旧仓库所需的 `delete_repo`。已要求用户自行执行 `gh auth refresh -h github.com -s delete_repo` 完成浏览器授权。授权前没有删除仓库、没有未经说明改为 force-push，也没有把本地修复假装成远程完成。

账号此前已由用户确认；不需要再次猜测用户名。授权后应：再次核验账号和目标、保留备份、删除并重建同名公开仓库、只推送修正后的 master、等待 CI，通过后再创建新的 v0.1.0 标签／Release，最后核验 API 和公开页面。**现有本地/远程 v0.1.0 是旧标记，不是本次修复的 Release，不能直接 push --tags 当作发布。**

## Skill 对照

| 要求 | 证据／状态 |
| --- | --- |
| MoonBit 核心、真实领域功能 | 核心 .mbt 文件，受限 PNML、BFS、CLI；不再是占位 parser |
| 中文 README、安装与三个完整使用场景 | README.md、examples/README.md、三个 PNML、API demo、scripts/smoke.py |
| 检查／构建／测试／错误输入 | local-verification.md；三目标 runtime 实测，四目标静态检查；native runtime 待 CI |
| 可追溯有效提交 | commit-evidence.md 的 20 个非空实质里程碑；身份纠正不计新提交 |
| MIT／第三方／AI／安全／贡献说明 | LICENSE、THIRD_PARTY.md、AI_USAGE.md、SECURITY.md、CONTRIBUTING.md |
| 查重及官方助手流程 | duplicate-check.md、search-evidence.json；新增 MoonBDD 真实相邻关系；永久登记已追加为 in-progress |
| GitHub public／owner／权限 | 已核验旧仓库；待修正历史推送后重新核验实际贡献者 |
| 绿色 CI／GitHub Release | 未完成，不把 workflow 文件当作绿色 CI |
| 申报书 | 仓库外已更新审查稿；联系方式缺失，严格检查应失败，不能作为最终申报件 |
| MoonCakes 发布 | 未发布；按用户边界没有执行 |

## 与原计划仍存在的差距

ID 为网络内整数索引，不是防跨网混用的 PlaceId/TransitionId；没有独立 FireResult。PNML 仅平面白名单子集，不支持 page/namespace 等完整互操作语义。资源限制不是完整沙箱。以上均在 README 公开说明，因此本次不宣称原计划每一项都已无条件完成。
