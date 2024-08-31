from flask import Flask, request, render_template

app = Flask(__name__)
counter = 0


@app.route("/", methods=["GET"])
def main():
    return render_template("home.html", counter=counter), 200


@app.route("/add", methods=["POST"])
def add_counter():
    global counter
    counter += 1
    return render_template("home.html", counter=counter)


@app.route("/subtract", methods=["POST"])
def subtract_counter():
    global counter
    counter -= 1
    return render_template("home.html", counter=counter)


if __name__ == "__main__":
    app.run(host='0.0.0.0', port=8081)

