from flask import Flask, render_template

app = Flask(__name__)

@app.route('/')
def health_check():
    """Root endpoint returns health check"""
    return "Healthy", 200

@app.route('/health/liveness')
def liveness():
    """Kubernetes liveness probe endpoint"""
    return {"status": "ok"}, 200

@app.route('/health/readiness')
def readiness():
    """Kubernetes readiness probe endpoint"""
    return {"status": "ready"}, 200

@app.route('/resumes/mike')
def resume_mike():
    """Route that serves your custom resume"""
    return render_template('index.html')

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=8000)

