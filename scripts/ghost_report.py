#!/usr/bin/env python3
import sys, json, os, datetime, html
def load_text(p): 
    try: return open(p,'r',encoding='utf-8',errors='ignore').read()
    except: return ""
def esc(x): return html.escape("" if x is None else str(x))
def main():
    if len(sys.argv)<2: print("Usage: ghost_report.py <CASE_ROOT>"); raise SystemExit(1)
    case_root=sys.argv[1]
    meta_path=os.path.join(case_root,"Identification","case_metadata.json")
    acquisition_log=os.path.join(case_root,"Logs","acquisition.log")
    manifest=os.path.join(case_root,"Logs","hash_manifest.txt")
    integ_pre=os.path.join(case_root,"Logs","integrity_pre.txt")
    integ_post=os.path.join(case_root,"Logs","integrity_post.txt")
    meta={}
    if os.path.exists(meta_path):
        meta=json.load(open(meta_path,'r',encoding='utf-8'))
    audit={
        "case_id": meta.get("case_id"), "generated_utc": datetime.datetime.utcnow().isoformat()+"Z",
        "investigator": meta.get("investigator"), "device": meta.get("device"),
        "acquisition_log": load_text(acquisition_log), "hash_manifest": load_text(manifest),
        "integrity_pre": load_text(integ_pre), "integrity_post": load_text(integ_post),
        "notes": "Proof-of-concept auto-generated report"
    }
    reports_dir=os.path.join(case_root,"Reports"); os.makedirs(reports_dir,exist_ok=True)
    open(os.path.join(reports_dir,"case_audit.json"),"w",encoding="utf-8").write(json.dumps(audit,indent=2))
    css="body{font-family:Georgia,'Times New Roman',serif;margin:1in;line-height:1.5} .cover{text-align:center;margin-top:25vh;page-break-after:always} pre{background:#f6f6f6;padding:.75rem;white-space:pre-wrap} .meta{border:1px solid #ddd;padding:1rem;border-radius:8px}"
    html_text="<!doctype html><html><head><meta charset='utf-8'><style>"+css+"</style></head><body>"
    html_text+=f"<div class='cover'><h1>GhostChip Case Report</h1><p><strong>Case ID:</strong> {esc(audit.get('case_id'))}</p><p><strong>Investigator:</strong> {esc(audit.get('investigator'))}</p><p><strong>Generated (UTC):</strong> {esc(audit.get('generated_utc'))}</p><p><strong>Device:</strong> {esc(json.dumps(audit.get('device',{})))}</p></div>"
    html_text+="<h2>1. Acquisition Log</h2><pre>"+esc(audit.get('acquisition_log'))+"</pre>"
    html_text+="<h2>2. Hash Manifest</h2><pre>"+esc(audit.get('hash_manifest'))+"</pre>"
    html_text+="<h2>3. Integrity Checks</h2><h3>Pre-Modification</h3><pre>"+esc(audit.get('integrity_pre'))+"</pre><h3>Post-Modification</h3><pre>"+esc(audit.get('integrity_post'))+"</pre>"
    html_text+="<h2>4. Notes</h2><pre>"+esc(audit.get('notes'))+"</pre></body></html>"
    open(os.path.join(reports_dir,"case_report.html"),"w",encoding="utf-8").write(html_text)
    print("[+] Report written in Reports/")
if __name__=="__main__": main()
