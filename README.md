# DuMate 技能仓库

存储所有自定义技能，支持快速检索和安装。

## 技能索引

| 技能名称 | 描述 | 文件 |
|----------|------|------|
| douyin-auto-browse | 抖音自动浏览，自动跳过直播 | [SKILL.md](skills/douyin-auto-browse/SKILL.md) |
| php-composer-publish | PHP Composer 包发布流程指南 | [SKILL.md](skills/php-composer-publish/SKILL.md) |

## 使用方法

当需要使用某个技能时，对我说：
```
安装技能 douyin-auto-browse
```

我会自动从 GitHub 下载并安装到本地。

## 技能结构

```
skills/
├── skill-name/
│   ├── SKILL.md      # 技能说明（必需）
│   └── scripts/      # 脚本文件（可选）
│       └── *.sh
```

## 本地存储策略

- 技能使用完毕后可删除本地文件
- 所有技能都在此仓库备份
- 需要时随时从 GitHub 重新安装
