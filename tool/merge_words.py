import json

INPUT_FILE = "quraan_tokens_with_line_index.json"   # الملف اللي فيه token_no + lineIndex
OUTPUT_FILE = "quraan_lines.json"                         # الملف الناتج: سطر واحد لكل lineIndex


def main():
    # 1) قراءة الملف
    with open(INPUT_FILE, "r", encoding="utf-8") as f:
        items = json.load(f)

    merged = []
    if not items:
        print("الملف فارغ.")
        return

    # 2) نبدأ بأول عنصر كجروب حالي
    current_line_index = items[0].get("lineIndex")
    current_group = [items[0]]

    # 3) نمشي على الجيسونات بالترتيب كما هي
    for item in items[1:]:
        li = item.get("lineIndex")

        if li == current_line_index:
            # نفس lineIndex → ضمن نفس السطر
            current_group.append(item)
        else:
            # lineIndex تغيّر → ندمج الجروب السابق ونبدأ واحد جديد
            merged.append(merge_group(current_group, current_line_index))
            current_group = [item]
            current_line_index = li

    # لا تنسَ آخر جروب
    merged.append(merge_group(current_group, current_line_index))

    # 4) حفظ الناتج
    with open(OUTPUT_FILE, "w", encoding="utf-8") as f:
        json.dump(merged, f, ensure_ascii=False, indent=2)

    print(f"✅ تم دمج {len(merged)} أسطر (lineIndex) في {OUTPUT_FILE}")


def merge_group(group, line_index):
    """
    يدمج مجموعة من العناصر لها نفس lineIndex إلى عنصر واحد:
    - يجمع aya_text معًا بترتيبها في group
    - يجمع aya_text_emlaey معًا بترتيبها في group
    - يأخذ باقي الحقول من أول عنصر
    """
    # أول عنصر نأخذ منه البيانات العامة
    first = group[0]

    aya_text_parts = []
    aya_emlaey_parts = []

    for item in group:
        t_glyph = str(item.get("aya_text", "")).strip()
        t_eml = str(item.get("aya_text_emlaey", "")).strip()

        if t_glyph:
            aya_text_parts.append(t_glyph)
        if t_eml:
            aya_emlaey_parts.append(t_eml)

    merged_aya_text = " ".join(aya_text_parts)
    merged_aya_emlaey = " ".join(aya_emlaey_parts)

    # بناء جيسون السطر النهائي
    out = dict(first)  # ننسخ كل الحقول من الأول
    out["lineIndex"] = line_index
    out["aya_text"] = merged_aya_text
    out["aya_text_emlaey"] = merged_aya_emlaey

    # لو تحب تحذف token_no من السطر النهائي (لأنه صار سطر كامل وليس كلمة واحدة) احذف هذا التعليق:
    # out.pop("token_no", None)
    # out.pop("aya_no", None)  # حسب ما تحب تحتفظ به

    return out


if __name__ == "__main__":
    main()
