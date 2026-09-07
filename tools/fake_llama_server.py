#!/usr/bin/env python3
"""Minimal OpenAI-compatible chat stub for LOCAL_OK smoke. No real model."""
from __future__ import annotations
import argparse, json
from http.server import BaseHTTPRequestHandler, HTTPServer

class Handler(BaseHTTPRequestHandler):
    def do_POST(self) -> None:
        n = int(self.headers.get("Content-Length", "0") or 0)
        _ = self.rfile.read(n)
        raw = json.dumps({
            "id": "chatcmpl-fake",
            "object": "chat.completion",
            "choices": [{"index": 0, "message": {"role": "assistant", "content": "夜里偶有烦热，腿脚也沉一些。"}, "finish_reason": "stop"}],
        }, ensure_ascii=False).encode("utf-8")
        self.send_response(200)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(raw)))
        self.end_headers()
        self.wfile.write(raw)
    def log_message(self, *_a) -> None:
        return

def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--host", default="127.0.0.1")
    ap.add_argument("--port", type=int, default=8765)
    args = ap.parse_args()
    httpd = HTTPServer((args.host, args.port), Handler)
    print(f"fake_llama_server on http://{args.host}:{args.port}/v1/chat/completions", flush=True)
    httpd.serve_forever()

if __name__ == "__main__":
    main()
