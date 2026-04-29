# PHP Composer 包发布技能

帮助用户创建 PHP 库包，推送到 GitHub，并指导发布到 Packagist。

## 完整流程

### 1. 创建 PHP 包结构

```
package-name/
├── src/
│   └── ClassName.php
├── tests/
├── composer.json
├── README.md
├── LICENSE
└── .gitignore
```

### 2. composer.json 模板

```json
{
    "name": "vendor/package-name",
    "description": "包描述",
    "type": "library",
    "keywords": ["关键词1", "关键词2"],
    "license": "MIT",
    "authors": [
        {
            "name": "作者名",
            "email": "email@example.com"
        }
    ],
    "require": {
        "php": ">=7.4"
    },
    "autoload": {
        "psr-4": {
            "Vendor\\PackageName\\": "src/"
        }
    },
    "minimum-stability": "stable",
    "prefer-stable": true
}
```

### 3. GitHub 操作

1. 使用 `github_create_repository` 创建公开仓库
2. 使用 `github_push_files` 推送所有文件
3. 仓库地址格式：`https://github.com/username/package-name`

### 4. Packagist 发布（用户手动操作）

Packagist 不支持 API 发布，需要指导用户：

1. 访问 https://packagist.org
2. 使用 GitHub 账号登录
3. 点击 **Submit**
4. 输入仓库 URL：`https://github.com/username/package-name`
5. 点击 **Check** → **Submit**

### 5. 验证发布

```
https://packagist.org/packages/vendor/package-name.json
```

## 注意事项

- 包名格式：`vendor/package-name`（小写，连字符分隔）
- Packagist 发布必须由用户手动完成
- GitHub Token 需要 `repo` 权限

## 示例项目

- `printzhucheng/curl-http-package` - cURL HTTP 客户端
  - GitHub: https://github.com/printzhucheng/curl-http-package
  - Packagist: https://packagist.org/packages/printzhucheng/curl-http-package