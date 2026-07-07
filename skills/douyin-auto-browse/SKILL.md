# Skill: douyin-auto-browse

抖音自动浏览技能 - 自动浏览并下载抖音精选视频（按点赞数筛选）

## 功能

- 自动打开抖音精选页面
- 解析视频卡片，按点赞数筛选（默认 >=1万赞）
- 通过 CDP 网络拦截获取视频直链
- 以视频标题命名下载视频
- 支持去重（已下载文件自动跳过）

## 使用方法

直接对我说：

- "启动抖音自动浏览" - 使用默认设置（5个视频，>=1万赞）
- "抖音浏览5个视频" - 指定浏览数量
- "抖音浏览3个视频 最低5000赞" - 自定义数量和点赞门槛

## 参数说明

| 参数 | 默认值 | 说明 |
|------|--------|------|
| count | 5 | 下载视频数量 |
| download | true | 是否下载视频 |
| min_likes | 10000 | 最低点赞数（10000 = 1万） |

## 核心工作原理（v3.2）

### 流程

1. 启动 Chrome（CDP 模式，端口 19222）
2. 导航到精选页，滚动加载卡片
3. 解析小卡片 `.discover-video-card-item`：
   - 提取标题（`img[alt]`）
   - 提取点赞数（叶子文本：`3.1万` 或 `5161`）
   - 提取视频链接（`div.waterfall-videoCardContainer[href]`）
4. 按点赞数降序，选中最高赞的未处理卡片
5. 用 href 直接导航到视频详情页（不能点击，因为 `target="_blank"` 会开新标签）
6. CDP `Network.responseReceived` 拦截真实 mp4 URL
7. curl 下载视频（带 Referer 和 User-Agent 头）
8. 返回精选页，继续下一轮

### 精选页卡片结构

- **顶部大卡片**（1017x573）：带视频播放器，跳过
- **小卡片**（328x275）：`.discover-video-card-item`
  - 标题：`img[alt]` 属性
  - 点赞数：叶子文本，格式 `3.1万` 或 `5161`
  - 视频链接：`div.waterfall-videoCardContainer` 的 `href` 属性
  - 点击行为：`target="_blank"` 开新标签 → 必须用 href 导航

### CDP 拦截条件

```
url.includes('douyinvod.com') && 
url.includes('video/tos') && 
url.includes('mime_type=video_mp4')
```

### 去重机制

- 已下载文件检查（同名文件跳过）
- 已处理标题匹配（标题前20字符）

## 示例

```
用户：启动抖音自动浏览
用户：抖音浏览5个视频
用户：抖音浏览3个视频 最低5000赞
```

## 依赖

- Chrome 浏览器（需以 `--remote-debugging-port=19222` 启动）
- dumate-browser-use 技能（浏览器自动化，CDP 模式）
- curl（视频下载）
- PowerShell（中文文件名处理）

## 脚本位置

- `scripts/douyin-browse-v3.sh` - 当前版本（v3.2 CDP拦截 + href导航）
- `scripts/douyin-browse-v2.sh` - 旧版本（已弃用）
- `scripts/douyin-browse.sh` - 最旧版本（已弃用）
