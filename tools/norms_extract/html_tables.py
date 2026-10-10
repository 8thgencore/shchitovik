"""Extracts tables (with preceding caption text) from an HTML file into JSON lines."""
import sys, json, re
from html.parser import HTMLParser

class P(HTMLParser):
    def __init__(self):
        super().__init__(convert_charrefs=True)
        self.tables=[]; self.stack=[]; self.text=[]; self.last_text=''
    def handle_starttag(self, tag, attrs):
        a=dict(attrs)
        if tag=='table':
            self.stack.append({'caption':self.last_text[-300:],'rows':[]})
        elif tag=='tr' and self.stack:
            self.stack[-1]['rows'].append([])
        elif tag in('td','th') and self.stack and self.stack[-1]['rows']:
            self.stack[-1]['rows'][-1].append({'t':'','cs':int(a.get('colspan',1) or 1),'rs':int(a.get('rowspan',1) or 1)})
        elif tag=='img' and self.stack and self.stack[-1]['rows'] and self.stack[-1]['rows'][-1]:
            self.stack[-1]['rows'][-1][-1]['t']+=f"[img:{a.get('src','')}]"
        elif tag=='br':
            self._data(' ')
    def handle_endtag(self, tag):
        if tag=='table' and self.stack:
            self.tables.append(self.stack.pop())
    def _data(self,d):
        if self.stack and self.stack[-1]['rows'] and self.stack[-1]['rows'][-1]:
            self.stack[-1]['rows'][-1][-1]['t']+=d
        elif not self.stack:
            self.last_text=(self.last_text+d)[-2000:]
    def handle_data(self, d): self._data(d)

def extract(path):
    """Returns [{'caption': str, 'rows': [[cell text]]}] for every <table> in the file."""
    p=P(); p.feed(open(path,encoding='utf-8',errors='replace').read())
    out=[]
    for t in p.tables:
        rows=[[re.sub(r'\s+',' ',c['t']).strip() for c in r] for r in t['rows']]
        out.append({'caption':re.sub(r'\s+',' ',t['caption']).strip(),'rows':rows})
    return out

if __name__=='__main__':
    for i,t in enumerate(extract(sys.argv[1])):
        print(json.dumps({'i':i,**t},ensure_ascii=False))
