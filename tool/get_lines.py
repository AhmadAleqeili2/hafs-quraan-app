import json
from collections import defaultdict

# عدّل هذه المسارات حسب ملفاتك
TOKENS_FILE = r"C:\Users\Ahmad_Aleqeili\Downloads/quraan_tokens.json"                # الملف اللي أنتجناه سابقًا
POSITIONS_FILE = r"C:\Users\Ahmad_Aleqeili\Desktop\lastVersionInShaaAllah\quraan_tajweed\assets\temp\quran_words.json"                 # الملف اللي فيه lineIndex و tokenIndex ...
OUTPUT_FILE = "quraan_tokens_with_line_index.json"


def merge_positions_tokenindex_zero(positions):
    """
    يدمج أي سجل له tokenIndex = N وبعده مباشرة tokenIndex = 0
    لنفس (surahIndex, ayahIndex, lineIndex, pageIndex).
    ندمج content بـ ' ' ونبقي tokenIndex = N ونحذف سطر 0.
    """

    def sort_key(p):
        # نستخدم uiversal-index لو موجود لضمان ترتيب صحيح
        try:
            return int(p.get("uiversal-index", 0))
        except (TypeError, ValueError):
            return 0

    positions_sorted = sorted(positions, key=sort_key)

    merged = []
    i = 0
    # سنسجل الأزواج التي حصل فيها دمج لنستخدمها لاحقاً عند دمج quraan_tokens
    merged_pairs = []  # قائمة من tuples: (surahIndex, ayahIndex, tokenIndex_N)

    while i < len(positions_sorted):
        curr = positions_sorted[i]

        try:
            curr_token_idx = int(curr.get("tokenIndex"))
            curr_surah = int(curr.get("surahIndex"))
            curr_ayah = int(curr.get("ayahIndex"))
            curr_line = int(curr.get("lineIndex"))
            curr_page = int(curr.get("pageIndex"))
        except (TypeError, ValueError):
            merged.append(curr)
            i += 1
            continue

        if i + 1 < len(positions_sorted):
            nxt = positions_sorted[i + 1]
            try:
                nxt_token_idx = int(nxt.get("tokenIndex"))
                nxt_surah = int(nxt.get("surahIndex"))
                nxt_ayah = int(nxt.get("ayahIndex"))
                nxt_line = int(nxt.get("lineIndex"))
                nxt_page = int(nxt.get("pageIndex"))
            except (TypeError, ValueError):
                merged.append(curr)
                i += 1
                continue

            # شرط الدمج:
            # - نفس السورة
            # - نفس الآية
            # - نفس السطر
            # - نفس الصفحة (لزيادة الأمان)
            # - curr.tokenIndex > 0
            # - nxt.tokenIndex == 0
            if (
                curr_token_idx > 0
                and nxt_token_idx == 0
                and curr_surah == nxt_surah
                and curr_ayah == nxt_ayah
                and curr_line == nxt_line
                and curr_page == nxt_page
            ):
                curr_content = str(curr.get("content", ""))
                nxt_content = str(nxt.get("content", ""))

                merged_curr = dict(curr)
                if curr_content and nxt_content:
                    merged_curr["content"] = curr_content + " " + nxt_content
                else:
                    merged_curr["content"] = curr_content + nxt_content

                merged.append(merged_curr)

                # نسجل هذا الدمج لاستخدامه مع quraan_tokens
                merged_pairs.append((curr_surah, curr_ayah, curr_token_idx))

                # نتخطى السطرين
                i += 2
                continue

        merged.append(curr)
        i += 1

    return merged, merged_pairs


def group_tokens_by_ayah(tokens):
    """
    يجمع tokens حسب (sura_no, aya_no) مع الحفاظ على الترتيب الأصلي.
    يعيد dict: (sura_no, aya_no) -> list[tokens]
    """
    groups = defaultdict(list)
    for t in tokens:
        try:
            s = int(t.get("sura_no"))
            a = int(t.get("aya_no"))
        except (TypeError, ValueError):
            continue
        groups[(s, a)].append(t)
    return groups


def merge_tokens_for_pairs(tokens, merged_pairs):
    """
    يدمج في quraan_tokens نفس الأزواج التي دُمجت في positions:
    لكل (sura_no, aya_no, N):
      - ندمج token_no = N مع token_no = N+1
      - ندمج aya_text و aya_text_emlaey
      - نبقي القيم الأخرى من التوكن N
      - نحذف التوكن N+1
    """
    # نحول قائمة الأزواج إلى set لسهولة الفحص
    merge_set = set(merged_pairs)

    groups = group_tokens_by_ayah(tokens)
    new_tokens = []

    for (sura_no, aya_no), lst in groups.items():
        # نرتب داخل كل آية حسب token_no
        try:
            lst_sorted = sorted(lst, key=lambda t: int(t.get("token_no", 0)))
        except ValueError:
            lst_sorted = lst

        i = 0
        while i < len(lst_sorted):
            t = lst_sorted[i]
            try:
                t_no = int(t.get("token_no"))
            except (TypeError, ValueError):
                new_tokens.append(t)
                i += 1
                continue

            # هل هذه التوكن هي N التي حصل لها دمج؟
            if (sura_no, aya_no, t_no) in merge_set:
                # نفترض أن التالي في نفس الآية هو N+1
                if i + 1 < len(lst_sorted):
                    t_next = lst_sorted[i + 1]
                    try:
                        t_next_no = int(t_next.get("token_no"))
                    except (TypeError, ValueError):
                        # لو التالي مش رقم، نضيف الحالي ونكمل عادي
                        new_tokens.append(t)
                        i += 1
                        continue

                    # نتأكد أن التوكن التالي فعلاً N+1
                    if t_next_no == t_no + 1:
                        # دمج aya_text
                        t_text = str(t.get("aya_text", ""))
                        next_text = str(t_next.get("aya_text", ""))
                        if t_text and next_text:
                            t["aya_text"] = t_text + " " + next_text
                        else:
                            t["aya_text"] = t_text + next_text

                        # دمج aya_text_emlaey
                        t_eml = str(t.get("aya_text_emlaey", ""))
                        next_eml = str(t_next.get("aya_text_emlaey", ""))
                        if t_eml and next_eml:
                            t["aya_text_emlaey"] = t_eml + " " + next_eml
                        else:
                            t["aya_text_emlaey"] = t_eml + next_eml

                        # نضيف التوكن المدموج، ونتخطى N+1
                        new_tokens.append(t)
                        i += 2
                        continue

                # لو ما تحقق شرط N+1، نضيف التوكن كما هو
                new_tokens.append(t)
                i += 1
            else:
                # لا يوجد دمج لهذا التوكن
                new_tokens.append(t)
                i += 1

    return new_tokens


def main():
    # 1) قراءة quraan_tokens
    with open(TOKENS_FILE, "r", encoding="utf-8") as f:
        tokens = json.load(f)

    # 2) قراءة positions
    with open(POSITIONS_FILE, "r", encoding="utf-8") as f:
        positions = json.load(f)

    # 3) دمج N و 0 في ملف positions + تسجيل الأزواج
    positions_merged, merged_pairs = merge_positions_tokenindex_zero(positions)
    print(f"دمجنا {len(merged_pairs)} زوج (N, 0) في positions.json")

    # 4) دمج نفس الأزواج في quraan_tokens (aya_text و aya_text_emlaey)
    tokens_merged = merge_tokens_for_pairs(tokens, merged_pairs)
    print(f"عدد التوكِنز قبل الدمج: {len(tokens)}, بعد الدمج: {len(tokens_merged)}")

    # 5) بناء خريطة من positions_merged لإضافة lineIndex (وغيره لو حاب)
    pos_map = {}
    for p in positions_merged:
        try:
            surah_idx = int(p.get("surahIndex"))
            ayah_idx = int(p.get("ayahIndex"))
            token_idx = int(p.get("tokenIndex"))
        except (TypeError, ValueError):
            continue

        key = (surah_idx, ayah_idx, token_idx)
        if key not in pos_map:
            pos_map[key] = p

    # 6) إضافة lineIndex (وأي شيء آخر تحتاجه) إلى tokens_merged
    not_found = 0
    for t in tokens_merged:
        try:
            sura_no = int(t.get("sura_no"))
            aya_no = int(t.get("aya_no"))
            token_no = int(t.get("token_no"))
        except (TypeError, ValueError):
            continue

        key = (sura_no, aya_no, token_no)
        pos = pos_map.get(key)
        if pos is None:
            not_found += 1
            continue

        # lineIndex
        try:
            t["lineIndex"] = int(pos.get("lineIndex"))
        except (TypeError, ValueError):
            t["lineIndex"] = pos.get("lineIndex")

        # لو تحب تضيف هذه أيضاً:
        # t["tokenInLineIndex"] = int(pos.get("tokenInLineIndex", 0))
        # t["pageIndex_from_positions"] = int(pos.get("pageIndex", 0))
        # t["universal_index"] = int(pos.get("uiversal-index", 0))

    # 7) حفظ الناتج
    with open(OUTPUT_FILE, "w", encoding="utf-8") as f:
        json.dump(tokens_merged, f, ensure_ascii=False, indent=2)

    print(f"✅ تم الحفظ في {OUTPUT_FILE}")
    print(f"❗ عدد التوكِنز التي لم يُعثر لها على lineIndex: {not_found}")


if __name__ == "__main__":
    main()
