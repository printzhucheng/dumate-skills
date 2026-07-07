#!/bin/bash
# 抖音自动浏览+下载脚本 v3.2（CDP网络拦截 + 点赞数筛选 + 去重）
# 用法: douyin-browse-v3.sh [count] [download] [min_likes]
#   count:     下载视频数量，默认5
#   download:  是否下载视频 true/false，默认true
#   min_likes: 最低点赞数，默认10000

COUNT=${1:-5}
DOWNLOAD=${2:-true}
MIN_LIKES=${3:-10000}
SAVE_DIR="D:/dzDuMate/douyin_videos"
LIST_URL="https://www.douyin.com/jingxuan"

_SKILL_DIR="C:/Users/Administrator/AppData/Roaming/qianfan-desktop-app/qianfan_desk_xdg/global/data/skills/dumate-browser-use"

echo "=========================================="
echo "  抖音自动浏览 v3.2（CDP网络拦截）"
echo "=========================================="
echo "数量: $COUNT | 下载: $DOWNLOAD | 最低: ${MIN_LIKES}赞"
[ "$DOWNLOAD" = "true" ] && echo "保存: $SAVE_DIR"
echo "=========================================="

if [ "$DOWNLOAD" = "true" ]; then
    mkdir -p "$SAVE_DIR"
fi

source "${_SKILL_DIR}/scripts/init-headed.sh"
source "${_SKILL_DIR}/scripts/session-header.sh"

echo "连接浏览器..."
playwright-cli open 2>/dev/null

# 步骤1：导航到精选页，滚动加载卡片
echo "加载精选页..."
playwright-cli run-code "async page => {
    await page.goto('${LIST_URL}', {waitUntil:'domcontentloaded', timeout:30000});
    await page.waitForTimeout(3000);
    for (let s = 0; s < 20; s++) {
        await page.evaluate(() => window.scrollBy(0, 500));
        await page.waitForTimeout(400);
    }
    await page.evaluate(() => window.scrollTo(0, 0));
    await page.waitForTimeout(2000);
    return 'loaded';
}" 2>/dev/null

DOWNLOADED=0
FAILED=0
USED_TITLES=""

for i in $(seq 1 $COUNT); do
    echo ""
    echo "=== 视频 $i / $COUNT (>=$${MIN_LIKES}赞) ==="

    # 构建已处理标题的 JS 数组
    JS_USED="["
    FIRST=true
    for t in $USED_TITLES; do
        if [ "$FIRST" = "true" ]; then
            JS_USED="$${JS_USED}'$${t}'"
            FIRST=false
        else
            JS_USED="$${JS_USED},'$${t}'"
        fi
    done
    JS_USED="$${JS_USED}]"

    # 步骤2：从卡片列表中找到符合点赞数要求的视频，提取视频ID
    CARD_RAW=$(playwright-cli run-code "async page => {
        const minLikes = $${MIN_LIKES};
        const usedTitles = $${JS_USED};

        const result = await page.evaluate((args) => {
            const [minL, used] = args;
            const cards = document.querySelectorAll('.discover-video-card-item');
            const matched = [];
            const seenKeys = new Set();

            for (const card of cards) {
                const rect = card.getBoundingClientRect();
                if (rect.width > 500) continue; // 跳过顶部大卡片

                const img = card.querySelector('img[alt]');
                const title = img ? img.alt : '';
                const titleShort = title.substring(0, 20);
                if (used.includes(titleShort)) continue;

                const key = Math.round(rect.left) + ',' + Math.round(rect.top);
                if (seenKeys.has(key)) continue;
                seenKeys.add(key);

                // 找视频链接
                const hrefDiv = card.querySelector('div[href]');
                const href = hrefDiv ? hrefDiv.getAttribute('href') : '';
                if (!href) continue;

                // 收集叶子文本找 likes
                const leafTexts = [];
                const els = card.querySelectorAll('*');
                for (const el of els) {
                    if (el.children.length === 0 && el.tagName !== 'IMG') {
                        const t = (el.textContent || '').trim();
                        if (t) leafTexts.push(t);
                    }
                }

                let likesText = '';
                for (const t of leafTexts) {
                    if (t.match(/^[\\d.]+万?$/) && !t.match(/^\\d{1,2}:\\d{2}$/)) {
                        likesText = t;
                        break;
                    }
                }
                if (!likesText) continue;

                let likes = 0;
                if (likesText.includes('万')) {
                    likes = parseFloat(likesText.replace('万', '')) * 10000;
                } else {
                    likes = parseInt(likesText, 10) || 0;
                }

                if (likes >= minL) {
                    matched.push({likes, likesText, title: title.substring(0, 80), href});
                }
            }

            if (matched.length === 0) return {status:'FAIL', reason:'no-card-meets-likes', total: cards.length};

            matched.sort((a, b) => b.likes - a.likes);
            const pick = matched[0];

            return {
                status:'OK',
                title: pick.title || 'untitled',
                likes: pick.likesText,
                href: pick.href
            };
        }, [minLikes, usedTitles]);

        return result.status === 'OK'
            ? 'OK<SEP>' + result.title + '<SEP>' + result.likes + '<SEP>' + result.href
            : 'FAIL<SEP>' + result.reason + '<SEP>' + (result.total || 0);
    }" 2>/dev/null)

    CARD_LINE=$(echo "$CARD_RAW" | sed -n '/^### Result/{n;p;}' | head -1)
    CARD_LINE=$(echo "$CARD_LINE" | sed 's/^\s*"//;s/"\s*$$//' | sed 's/\\///g')
    CARD_STATUS=$(echo "$CARD_LINE" | awk -F'<SEP>' '{print $$1}')

    if [ "$CARD_STATUS" != "OK" ]; then
        REASON=$(echo "$CARD_LINE" | awk -F'<SEP>' '{print $$2}')
        TOTAL=$(echo "$CARD_LINE" | awk -F'<SEP>' '{print $$3}')
        echo "跳过: $REASON (总卡片: $TOTAL)"
        FAILED=$$((FAILED + 1))
        if [ "$REASON" = "no-card-meets-likes" ]; then
            echo "尝试滚动加载更多卡片..."
            playwright-cli run-code "async page => {
                for (let s = 0; s < 10; s++) {
                    await page.evaluate(() => window.scrollBy(0, 500));
                    await page.waitForTimeout(400);
                }
                return 'scrolled';
            }" 2>/dev/null
        fi
        continue
    fi

    VIDEO_TITLE=$(echo "$CARD_LINE" | awk -F'<SEP>' '{print $$2}')
    VIDEO_LIKES=$(echo "$CARD_LINE" | awk -F'<SEP>' '{print $$3}')
    VIDEO_HREF=$(echo "$CARD_LINE" | awk -F'<SEP>' '{print $$4}')

    # href 格式: //www.douyin.com/video/XXXXX
    if [[ "$VIDEO_HREF" == //* ]]; then
        VIDEO_URL_PAGE="https:$${VIDEO_HREF}"
    else
        VIDEO_URL_PAGE="$${VIDEO_HREF}"
    fi

    echo "标题: $VIDEO_TITLE | 点赞: $VIDEO_LIKES | 页面: $VIDEO_URL_PAGE"

    # 记录已处理标题
    TITLE_KEY=$(echo "$VIDEO_TITLE" | cut -c1-20 | tr ' ' '_')
    USED_TITLES="$USED_TITLES $TITLE_KEY"

    # 步骤3：导航到视频详情页，CDP 拦截视频下载 URL
    DL_RAW=$(playwright-cli run-code "async page => {
        const client = await page.context().newCDPSession(page);
        await client.send('Network.enable');
        const videoUrls = [];
        client.on('Network.responseReceived', (params) => {
            const url = params.response.url;
            if (url.includes('douyinvod.com') && url.includes('video/tos') && url.includes('mime_type=video_mp4')) {
                videoUrls.push(url);
            }
        });

        await page.goto('$${VIDEO_URL_PAGE}', {waitUntil:'domcontentloaded', timeout:30000});
        await page.waitForTimeout(8000);

        const unique = [...new Set(videoUrls)];
        if (unique.length === 0) return 'FAIL<SEP>no-video-url';
        return 'OK<SEP>' + unique[0];
    }" 2>/dev/null)

    DL_LINE=$(echo "$DL_RAW" | sed -n '/^### Result/{n;p;}' | head -1)
    DL_LINE=$(echo "$DL_LINE" | sed 's/^\s*"//;s/"\s*$$//' | sed 's/\\///g')
    DL_STATUS=$(echo "$DL_LINE" | awk -F'<SEP>' '{print $$1}')

    if [ "$DL_STATUS" != "OK" ]; then
        DL_REASON=$(echo "$DL_LINE" | awk -F'<SEP>' '{print $$2}')
        echo "CDP拦截失败: $DL_REASON"
        FAILED=$$((FAILED + 1))
        playwright-cli run-code "async page => { await page.goto('$${LIST_URL}', {waitUntil:'domcontentloaded', timeout:30000}); return 'back'; }" 2>/dev/null
        continue
    fi

    VIDEO_DL_URL=$(echo "$DL_LINE" | awk -F'<SEP>' '{print $$2}')
    echo "视频URL: $${VIDEO_DL_URL:0:80}..."

    if [ "$DOWNLOAD" = "true" ] && [ -n "$VIDEO_DL_URL" ]; then
        SAFE_TITLE=$(powershell -Command "
            \$$t = '$VIDEO_TITLE'
            \$$s = \$$t -replace '[\\\\/:*?\"<>|]', ''
            \$$s = \$$s.Substring(0, [Math]::Min(60, \$$s.Length))
            \$$s = \$$s.TrimEnd('.。 ')
            Write-Output \$$s
        ")
        FILENAME="$${SAVE_DIR}/$${SAFE_TITLE}.mp4"

        if [ -f "$FILENAME" ] && [ -s "$FILENAME" ]; then
            SIZE=$(wc -c < "$FILENAME" 2>/dev/null)
            SIZE_MB=$$((SIZE / 1048576))
            echo "已存在 ($${SIZE_MB}MB)，跳过: $(basename "$FILENAME")"
            DOWNLOADED=$$((DOWNLOADED + 1))
        else
            echo "下载中... → $(basename "$FILENAME")"
            curl -L -o "$FILENAME" "$VIDEO_DL_URL" \
                --connect-timeout 30 \
                --max-time 300 \
                -s \
                -H "Referer: https://www.douyin.com/" \
                -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Safari/537.36"

            if [ -f "$FILENAME" ] && [ -s "$FILENAME" ]; then
                SIZE=$(wc -c < "$FILENAME" 2>/dev/null)
                SIZE_MB=$$((SIZE / 1048576))
                echo "下载成功! $${SIZE_MB}MB → $(basename "$FILENAME")"
                DOWNLOADED=$$((DOWNLOADED + 1))
            else
                echo "下载失败（URL可能已过期）"
                rm -f "$FILENAME"
                FAILED=$$((FAILED + 1))
            fi
        fi
    fi

    # 步骤4：返回精选页
    echo "返回列表页..."
    playwright-cli run-code "async page => {
        await page.goto('$${LIST_URL}', {waitUntil:'domcontentloaded', timeout:30000});
        await page.waitForTimeout(2000);
        return 'back';
    }" 2>/dev/null
    sleep 1
done

echo ""
echo "=========================================="
echo "  完成！"
echo "  目标: $COUNT | 下载: $DOWNLOADED | 失败/跳过: $FAILED"
[ "$DOWNLOAD" = "true" ] && echo "  视频保存在: $SAVE_DIR"
echo "=========================================="
