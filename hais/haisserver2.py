#!/usr/bin/env python3
import http.server, ssl, os

ROOT = '/opt/hais_serve'
LOG = '/opt/hais_serve/access.log'

class H(http.server.BaseHTTPRequestHandler):
    protocol_version = 'HTTP/1.1'
    def log_message(self, fmt, *args): pass
    def do_GET(self):
        path = self.path.split('?')[0].lstrip('/')
        with open(LOG, 'a') as f:
            f.write(f"{self.command} {self.path}\n")
        rel = path
        if '/-/raw/' in path:
            after = path.split('/-/raw/', 1)[1]   # e.g. main/aarch64/7z or master/twrp/x
            parts = after.split('/', 1)
            if len(parts) == 2:
                rel = parts[1]
        fpath = os.path.join(ROOT, rel)
        if os.path.isfile(fpath):
            data = open(fpath, 'rb').read()
            self.send_response(200)
            self.send_header('Content-Length', str(len(data)))
            self.send_header('Content-Type', 'application/octet-stream')
            self.end_headers()
            self.wfile.write(data)
        else:
            body = b'Not Found'
            self.send_response(404)
            self.send_header('Content-Length', str(len(body)))
            self.end_headers()
            self.wfile.write(body)

httpd = http.server.ThreadingHTTPServer(('127.0.0.1', 443), H)
ctx = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
ctx.load_cert_chain(f'{ROOT}/cert.pem', f'{ROOT}/key.pem')
httpd.socket = ctx.wrap_socket(httpd.socket, server_side=True)
httpd.serve_forever()
