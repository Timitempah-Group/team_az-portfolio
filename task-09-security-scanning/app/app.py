# Simple Flask app — used as the target for SonarQube SAST scanning
# In a real engagement this would be your application code
from flask import Flask

app = Flask(__name__)

@app.route('/health')
def health():
    """Health check endpoint — used by Traffic Manager and load balancers."""
    return {'status': 'healthy'}, 200

@app.route('/')
def index():
    """Root endpoint."""
    return {'message': 'Portfolio demo app'}, 200

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080)
