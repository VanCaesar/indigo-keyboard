#!/usr/bin/env python3
"""根据签好名的 IPA 生成 OTA 安装用的 manifest.plist 和 info.json。

用法: make-manifest.py <signed.ipa> <站点根 URL> <输出目录> <release tag> <发布时间>
IPA 本身由调用方复制到 <输出目录>/Indigo.ipa。
"""
import json
import plistlib
import re
import sys
import zipfile


def main():
    ipa, base_url, out_dir, tag, published = sys.argv[1:6]
    base_url = base_url.rstrip("/")

    with zipfile.ZipFile(ipa) as z:
        names = z.namelist()
        info_name = next(
            (n for n in names if re.fullmatch(r"Payload/[^/]+\.app/Info\.plist", n)), None
        )
        if not info_name:
            sys.exit("IPA 里找不到 Payload/*.app/Info.plist，文件可能不是 IPA")
        app_dir = info_name[: -len("Info.plist")]
        info = plistlib.loads(z.read(info_name))

        prov_name = app_dir + "embedded.mobileprovision"
        if prov_name not in names:
            sys.exit("这个 IPA 没有签名（缺少 embedded.mobileprovision）。请上传爱思签名后的文件。")
        prov_raw = z.read(prov_name)

    # mobileprovision 是 CMS 包着的 XML plist，直接截出 plist 部分
    start = prov_raw.find(b"<?xml")
    end = prov_raw.find(b"</plist>")
    expires = None
    if start != -1 and end != -1:
        prov = plistlib.loads(prov_raw[start : end + len(b"</plist>")])
        exp = prov.get("ExpirationDate")
        if exp is not None:
            expires = exp.strftime("%Y-%m-%dT%H:%M:%SZ")

    bundle_id = info["CFBundleIdentifier"]
    version = info.get("CFBundleShortVersionString", "0")
    title = info.get("CFBundleDisplayName") or info.get("CFBundleName") or "靛蓝输入法"

    manifest = {
        "items": [
            {
                "assets": [
                    {"kind": "software-package", "url": f"{base_url}/Indigo.ipa"},
                ],
                "metadata": {
                    "bundle-identifier": bundle_id,
                    "bundle-version": version,
                    "kind": "software",
                    "title": title,
                },
            }
        ]
    }
    with open(f"{out_dir}/manifest.plist", "wb") as f:
        plistlib.dump(manifest, f)

    with open(f"{out_dir}/info.json", "w", encoding="utf-8") as f:
        json.dump(
            {
                "tag": tag,
                "published": published,
                "version": version,
                "bundle": bundle_id,
                "expires": expires,
            },
            f,
            ensure_ascii=False,
        )
    print(f"{title} {version} ({bundle_id}) 证书到期: {expires}")


if __name__ == "__main__":
    main()
