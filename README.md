# DuMate 技能仓库

存储所有自定义技能，支持快速检索和安装。

## 技能索引

| 技能名称 | 描述 | 使用口令 |
|----------|------|----------|
| image-gen | AI 生成高质量图片，支持文生图、图生图、中文文字 | "生成一张猫咪的图片" |
| douyin-auto-browse | 抖音自动浏览，自动跳过直播 | "启动抖音自动浏览" |
| php-composer-publish | PHP Composer 包发布流程指南 | "帮我创建一个 PHP 包" |

## 使用方法

当需要使用某个技能时，直接对我说对应的口令即可。

## 技能结构

```
skills/
├── image-gen/
│   └── SKILL.md
├── douyin-auto-browse/
│   └── SKILL.md
└── php-composer-publish/
    └── SKILL.md
```

## 本地存储策略

- 技能使用完毕后可删除本地文件
- 所有技能都在此仓库备份
- 需要时随时从 GitHub 重新安装

## 本地口令说明文件

本地保存位置：`D:\dzDuMate\waiguakongjie\skill\技能口令说明.md`

每次新增或更新技能时，会同步更新此文件。