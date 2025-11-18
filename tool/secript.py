# -*- coding: utf-8 -*-
import json
import os
from collections import defaultdict

# === إعدادات المسارات ===
QURAN_WORDS_PATH = r'assets/metadata/Quran/quraan.json'     # مصدر الكلمات
SURA_INDEX_PATH  = r'assets/metadata/Quran/surah_index.json'     # أسماء السور
OUTPUT_DIR       = r'assets/metadata/Quran/pages'                # مجلد إخراج الصفحات

# === ثوابت ===
BASMALA = 'بِسْمِ ٱللّٰهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ'
ARABIC_DIGITS = str.maketrans('0123456789', '٠١٢٣٤٥٦٧٨٩')

def to_ar_digits(n: int) -> str:
    return str(n).translate(ARABIC_DIGITS)

def parse_int_safe(v, min_value=1, fallback=1):
    if v is None:
        return fallback
    s = str(v).strip()
    if not s or s.lower() == 'null':
        return fallback
    try:
        n = int(s)
    except:
        return fallback
    return fallback if n < min_value else n

def ayah_key(surah_index: int, ayah_index: int) -> str:
    return f'{surah_index}:{ayah_index}'

def main():
    # 1) قراءة الملفات
    with open(QURAN_WORDS_PATH, 'r', encoding='utf-8') as f:
        words = json.load(f)

    with open(SURA_INDEX_PATH, 'r', encoding='utf-8') as f:
        sura_rows = json.load(f)

    surah_names = { parse_int_safe(r.get('number')): (r.get('name') or '') for r in sura_rows }

    # 2) تحويل وتصفية التوكنات
    tokens = []
    for m in words:
        t = {
            'lineIndex':       parse_int_safe(m.get('lineIndex')),
            'tokenInLineIndex':parse_int_safe(m.get('tokenInLineIndex')),
            'pageIndex':       parse_int_safe(m.get('pageIndex')),
            'surahIndex':      parse_int_safe(m.get('surahIndex')),
            'ayahIndex':       parse_int_safe(m.get('ayahIndex')),
            'tokenIndex':      parse_int_safe(m.get('tokenIndex')),
            'content':         (m.get('content') or '').strip(),
        }
        # تجاهل أي سطر/صفحة شاذين (لو وجد)
        if t['pageIndex'] == 4004 or t['lineIndex'] == 4004:
            continue
        # الشروط الأساسية (كلها تبدأ من 1)
        if (t['pageIndex'] >= 1 and t['lineIndex'] >= 1 and
            t['surahIndex'] >= 1 and t['ayahIndex'] >= 1 and
            t['tokenIndex'] >= 1 and t['content']):
            tokens.append(t)

    # 3) فرز شامل: صفحة -> سطر -> سورة -> آية -> توكن
    tokens.sort(key=lambda x: (x['pageIndex'], x['lineIndex'],
                               x['surahIndex'], x['ayahIndex'], x['tokenIndex']))

    # 4) احسب آخر tokenIndex لكل آية (لإضافة رقم الآية في نهايتها)
    max_tok_per_ayah = {}
    for t in tokens:
        k = ayah_key(t['surahIndex'], t['ayahIndex'])
        c = max_tok_per_ayah.get(k)
        if c is None or t['tokenIndex'] > c:
            max_tok_per_ayah[k] = t['tokenIndex']

    # 5) تجميع: صفحة -> سطر -> قائمة توكنات
    by_page_line = defaultdict(lambda: defaultdict(list))
    pages_set = set()
    for t in tokens:
        p = t['pageIndex']; l = t['lineIndex']
        by_page_line[p][l].append(t)
        pages_set.add(p)

    # 6) تحديد أول ظهور للسورة على الصفحة (ayah=1, token=1) لإدراج العنوان/البسملة قبل السطر
    page_line_surah_starts = {}
    for page, lines_map in by_page_line.items():
        first_line_for_surah = {}
        for line, items in lines_map.items():
            for t in items:
                if t['ayahIndex'] == 1 and t['tokenIndex'] == 1:
                    if t['surahIndex'] not in first_line_for_surah:
                        first_line_for_surah[t['surahIndex']] = line
                    else:
                        if line < first_line_for_surah[t['surahIndex']]:
                            first_line_for_surah[t['surahIndex']] = line
        # اعكس: line -> [surahIndex...]
        line_to_surahs = defaultdict(list)
        for sidx, ln in first_line_for_surah.items():
            line_to_surahs[ln].append(sidx)
        page_line_surah_starts[page] = line_to_surahs

    # 7) بناء وكتابة ملفات الصفحات
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    max_page_index = max(pages_set) if pages_set else 0

    for page in sorted(pages_set):
        lines_map = by_page_line[page]
        line_keys = sorted(lines_map.keys())
        rendered_lines = []

        for line in line_keys:
            # إدراج العنوان/البسملة قبل السطر الذي تبدأ عنده السورة
            starts_here = page_line_surah_starts.get(page, {}).get(line, [])
            for sidx in starts_here:
                sname = surah_names.get(sidx, '')
                # سطر عنوان السورة
                rendered_lines.append({
                    'sortKey': line * 1000 - 2,
                    'text': f'سورة {sname if sname else sidx}',
                    'surahIndexFirst': sidx,
                    'ayahIndexFirst': 1,
                    'isBasmala': False,
                    'isTitle': True,
                })
                # سطر البسملة (عدا 1 و 9)
                if sidx != 1 and sidx != 9:
                    rendered_lines.append({
                        'sortKey': line * 1000 - 1,
                        'text': BASMALA,
                        'surahIndexFirst': sidx,
                        'ayahIndexFirst': 1,
                        'isBasmala': True,
                        'isTitle': False,
                    })

            # السطر الأصلي
            items = sorted(lines_map[line],
                           key=lambda x: (x['surahIndex'], x['ayahIndex'], x['tokenIndex']))
            if not items:
                continue

            first = items[0]
            parts = []
            for t in items:
                parts.append(t['content'])
                k = ayah_key(t['surahIndex'], t['ayahIndex'])
                max_tok = max_tok_per_ayah.get(k, -1)
                if t['tokenIndex'] == max_tok:
                    # ◌۝ + رقم الآية بالأرقام العربية
                    parts.append('\u06DD' + to_ar_digits(t['ayahIndex']))

            line_text = ' '.join(parts).strip()
            rendered_lines.append({
                'sortKey': line * 1000,
                'text': line_text,
                'surahIndexFirst': first['surahIndex'],
                'ayahIndexFirst': first['ayahIndex'],
                'isBasmala': False,
                'isTitle': False,
            })

        # رتّب وخزّن الملف page.json (اسم الملف برقم الصفحة)
        rendered_lines.sort(key=lambda r: r['sortKey'])
        out_path = os.path.join(OUTPUT_DIR, f'{page}.json')
        with open(out_path, 'w', encoding='utf-8') as f:
            json.dump({
                'pageIndex': page,
                'lines': rendered_lines,
            }, f, ensure_ascii=False, separators=(',', ':'))

    # 8) اكتب manifest بالصفحات المتوفرة وعددها
    manifest = {
        'page_count': max_page_index,
        'pages': sorted(list(pages_set)),
    }
    with open(os.path.join(OUTPUT_DIR, 'pages_manifest.json'), 'w', encoding='utf-8') as f:
        json.dump(manifest, f, ensure_ascii=False, separators=(',', ':'))

    print(f'Done. Wrote {len(pages_set)} pages to: {OUTPUT_DIR}')

if __name__ == '__main__':
    main()
