# runner-watch

自架 GitHub Actions runner(两台别名 A、B,同一台 Mac)的外部巡检。

- Mac 上的 launchd 任务每 10 分钟把 runner 在线状态与最长排队时长写进公开 gist(`heartbeat.json`,只含别名与状态)。
- 本仓库的 workflow 每 2 小时在 GitHub 托管 runner 上读取该 gist:心跳超过 45 分钟未更新、任一 runner 非 online、或排队超过 30 分钟 → job 失败 → GitHub 向仓库 owner 发失败邮件。
- 放在公开仓库:公开仓的标准 runner 分钟免费,不受私有仓 Actions 预算「达限停用」的影响。
- 手动触发时勾选 `force_fail` 可演练一次失败,用来验证邮件确实送达。
- 每月 1 日与 15 日的巡检会提交一次 `status/last-ok.txt`,防止仓库 60 天无活动导致定时 workflow 被 GitHub 自动停用。
