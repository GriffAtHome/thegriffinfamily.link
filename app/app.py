from flask import Flask, render_template

app = Flask(__name__)

@app.route('/resumes/mike')
def resume_mike():
    return render_template('index.html')
