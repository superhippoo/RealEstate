# -*- coding: utf-8 -*-
"""Static server for the Godot web build with aggressive no-cache headers,
so every load fetches the current index.pck/index.wasm (prevents stale builds)."""
import http.server
import socketserver

PORT = 8090


class NoCacheHandler(http.server.SimpleHTTPRequestHandler):
    def end_headers(self):
        self.send_header("Cache-Control", "no-store, no-cache, must-revalidate, max-age=0")
        self.send_header("Pragma", "no-cache")
        self.send_header("Expires", "0")
        super().end_headers()

    def log_message(self, fmt, *args):
        pass


class Server(socketserver.ThreadingTCPServer):
    allow_reuse_address = True


if __name__ == "__main__":
    with Server(("", PORT), NoCacheHandler) as httpd:
        print("serving on %d" % PORT)
        httpd.serve_forever()
