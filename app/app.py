from flask import Flask, render_template

app = Flask(__name__)

@app.route('/')
def health_check():
    return "Healthy", 200

@app.route('/resumes/mike')
def resume_mike():
    return render_template('index.html')

