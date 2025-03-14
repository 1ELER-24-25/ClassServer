from flask import Flask

app = Flask(__name__)
app.secret_key = "placeholder"  # Overridden by .env

@app.route('/')
def home():
    return "Welcome to ClassServer! (Under Construction)"

if __name__ == "__main__":
    app.run(host='0.0.0.0', port=5000)