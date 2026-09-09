# 发布与独立消费核验

## 发布门禁

1. `gh api user` 确认 GitHub 当前账号为 `okMambaOut`，检查默认分支和提交身份。GitHub 登录与 MoonCakes 登录彼此独立。
2. `moon whoami` 确认 MoonCakes 为参与者明确选择、对 `okMambaOut/moonpetri` 有发布权限的账号。不能因为“已经登录”就使用其他人的身份发布，也不能为绕过权限擅自更改模块 namespace。
3. 最终 master 必须通过 GitHub CI。CI 不执行 `moon publish`，不保存注册表凭据。
4. 本机运行 `python scripts/package_check.py`；它实际生成 ZIP、检查模块/仓库归属、必须文件、源码字节一致性，并拒绝常见私密/构建产物。7 项回归在 readiness 中运行。它不代替人工内容审查。
5. 获得用户明确发布授权后才运行 `moon publish`。发布版本不可假定能覆盖；若版本已存在，先核验实际注册表内容，不能盲目修改版本或重传。
6. 发布后，从注册表查询版本和下载包，在独立临时消费工程 `moon add okMambaOut/moonpetri@0.1.0`，导入公开 API、运行例子，保存实际命令结果。只有完成远端版本/下载核验才称 MoonCakes 已发布。

## GitHub Release

最终提交 CI 通过后，将 `v0.1.0` 指向该提交并创建公开 Release。使用 API 检查 tag、master 和通过 CI 的 SHA 一致，检查 contributors 列表只有预期账号。Release 链接为 `https://github.com/okMambaOut/moonpetri/releases/tag/v0.1.0`，其存在不证明 MoonCakes 发布。

## 隐私与材料

申报书、参与者姓名/联系方式、Git bundle 备份、授权凭据均不放入发布包。项目只使用公开维护者署名及 GitHub noreply 身份。申报书保持在项目仓库外，最终报告以实测状态为准。
