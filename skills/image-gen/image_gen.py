#!/usr/bin/env python3
"""
图片生成工具 - 基于百度图片生成 API
使用方法: python image_gen.py "prompt" [output_path]
"""

import sys
import os
from datetime import datetime

# 添加百度图片生成技能路径
SKILL_PATH = "C:/Users/Administrator/AppData/Roaming/qianfan-desktop-app/qianfan_desk_xdg/global/data/skills/baidu-image-gen/scripts"
sys.path.insert(0, SKILL_PATH)

from image_client import generate_image

def main():
    if len(sys.argv) < 2:
        print("用法: python image_gen.py \"提示词\" [输出路径]")
        print("示例: python image_gen.py \"a cute cat\"")
        sys.exit(1)

    prompt = sys.argv[1]

    # 如果提示词是中文，自动翻译为英文提示
    chinese_chars = any('\u4e00' <= char <= '\u9fff' for char in prompt)
    if chinese_chars:
        # 简单的中文到英文提示词转换
        prompt = f"Create an image: {prompt}. High quality, detailed, photorealistic."

    # 生成输出路径
    if len(sys.argv) >= 3:
        output_path = sys.argv[2]
    else:
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        output_path = f"generated_{timestamp}.png"

    print(f"提示词: {prompt}")
    print(f"输出路径: {output_path}")
    print("正在生成图片...")

    try:
        result = generate_image(
            prompt=prompt,
            model="dumate-image1.1",
            resolution="2K",
            aspect_ratio="16:9",
            output=output_path
        )
        print(f"成功! 图片已保存到: {result.local_path}")
        print(f"图片URL: {result.image_url}")
    except Exception as e:
        print(f"错误: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()