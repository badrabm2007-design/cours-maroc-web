import http.server
import socketserver
import urllib.request
import urllib.parse
import sys
import os
import mimetypes

# Ensure proper MIME types for Flutter Web
mimetypes.add_type('application/javascript', '.js')
mimetypes.add_type('application/wasm', '.wasm')
mimetypes.add_type('application/json', '.json')
mimetypes.add_type('font/woff2', '.woff2')
mimetypes.add_type('font/woff', '.woff')
mimetypes.add_type('font/ttf', '.ttf')

PORT = int(sys.argv[1]) if len(sys.argv) > 1 else 5000
WEB_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'build', 'web')

class DevHandler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=WEB_DIR, **kwargs)

    def end_headers(self):
        # Disable caching completely for local testing
        self.send_header('Cache-Control', 'no-cache, no-store, must-revalidate, max-age=0')
        self.send_header('Pragma', 'no-cache')
        self.send_header('Expires', '0')
        # Enable CORS for all responses
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, HEAD, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', '*')
        super().end_headers()

    def do_OPTIONS(self):
        self.send_response(204)
        self.end_headers()

    def do_HEAD(self):
        parsed = urllib.parse.urlparse(self.path)
        if parsed.path == '/api/pdf':
            self.send_response(200)
            self.send_header('Content-Type', 'application/pdf')
            self.end_headers()
            return
        return super().do_HEAD()

    def do_GET(self):
        parsed = urllib.parse.urlparse(self.path)
        if parsed.path == '/api/pdf':
            params = urllib.parse.parse_qs(parsed.query)
            file_id = params.get('id', [None])[0]
            if not file_id:
                self.send_response(400)
                self.send_header('Content-Type', 'text/plain; charset=utf-8')
                self.end_headers()
                self.wfile.write(b'Missing id parameter')
                return

            drive_url = f"https://drive.usercontent.google.com/download?id={file_id}&export=download&confirm=t"
            req = urllib.request.Request(drive_url, headers={
                'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
                'Accept': 'application/pdf,application/octet-stream,*/*',
            })

            try:
                with urllib.request.urlopen(req, timeout=35) as resp:
                    data = resp.read()
                    self.send_response(200)
                    self.send_header('Content-Type', 'application/pdf')
                    self.send_header('Content-Length', str(len(data)))
                    self.send_header('Cache-Control', 'public, max-age=86400')
                    self.end_headers()
                    self.wfile.write(data)
            except Exception as e:
                # Fallback to secondary Drive URL if needed
                try:
                    fallback_url = f"https://drive.google.com/uc?id={file_id}&export=download&confirm=t"
                    fallback_req = urllib.request.Request(fallback_url, headers={
                        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
                    })
                    with urllib.request.urlopen(fallback_req, timeout=35) as resp:
                        data = resp.read()
                        self.send_response(200)
                        self.send_header('Content-Type', 'application/pdf')
                        self.send_header('Content-Length', str(len(data)))
                        self.send_header('Cache-Control', 'public, max-age=86400')
                        self.end_headers()
                        self.wfile.write(data)
                except Exception as err2:
                    self.send_response(500)
                    self.send_header('Content-Type', 'text/plain; charset=utf-8')
                    self.end_headers()
                    self.wfile.write(f"Error fetching PDF: {e} / {err2}".encode('utf-8'))
            return

        # Serve static file or fallback to index.html for client-side routing
        file_path = os.path.join(WEB_DIR, parsed.path.lstrip('/'))
        if not os.path.exists(file_path) and not '.' in os.path.basename(parsed.path):
            self.path = '/index.html'

        return super().do_GET()

if __name__ == '__main__':
    class ReusableTCPServer(socketserver.TCPServer):
        allow_reuse_address = True

    with ReusableTCPServer(('', PORT), DevHandler) as httpd:
        print(f"Serving Flutter Web with PDF Proxy on http://localhost:{PORT} from {WEB_DIR}")
        try:
            httpd.serve_forever()
        except KeyboardInterrupt:
            print("\nShutting down server.")
