from flask import Flask, request, render_template

app = Flask(__name__)
counter = 0


@app.route("/", methods=["GET"])
def main():
    return render_template("home.html"), 200


@app.route("/post", methods=["POST", "GET"])
def postcounter():
    global counter
    if request.method == "POST":
        counter += 1
    return render_template("home.html", message="success")


@app.route("/get", methods=["GET"])
def getcounter():
    return render_template("home.html", counter=counter)


if __name__ == "__main__":
    app.run(debug=True)