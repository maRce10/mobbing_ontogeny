"""Give pandoc-generated docx tables explicit full-width column grids (LibreOffice/Google Docs
otherwise collapse them). Usage: python3 scripts/fix_docx_tables.py file.docx"""
import re, sys, zipfile, shutil, tempfile

TEXT_W = 9000  # dxa (page width minus margins)

def fix(xml):
    def tbl(m):
        t = m.group(0)
        first_row = re.search(r'<w:tr>.*?</w:tr>', t, re.S).group(0)
        n = first_row.count('<w:tc>')
        w = TEXT_W // n
        t = re.sub(r'<w:tblW [^>]*/>', '<w:tblW w:type="pct" w:w="5000" />', t, count=1)
        t = t.replace('<w:tblGrid />', '<w:tblGrid>' + f'<w:gridCol w:w="{w}" />' * n + '</w:tblGrid>', 1)
        t = t.replace('<w:tcPr>', f'<w:tcPr><w:tcW w:type="dxa" w:w="{w}" />')
        return t
    return re.sub(r'<w:tbl>.*?</w:tbl>', tbl, xml, flags=re.S)

src = sys.argv[1]
tmp = tempfile.mktemp(suffix='.docx')
with zipfile.ZipFile(src) as zin, zipfile.ZipFile(tmp, 'w', zipfile.ZIP_DEFLATED) as zout:
    for item in zin.infolist():
        data = zin.read(item.filename)
        if item.filename == 'word/document.xml':
            data = fix(data.decode('utf-8')).encode('utf-8')
        zout.writestr(item, data)
shutil.move(tmp, src)
