from flask import Flask, request, render_template

app = Flask(__name__)
counter = 0


@app.route("/", methods=["GET"])
def main():
    return render_template("home.html"), 200


@app.route("/increment", methods=["POST", "GET"])
def postcounter():
    global counter
    if request.method == "POST":
        counter += 1
    print(counter)
    return render_template("home.html", counter=counter)


if __name__ == "__main__":
    app.run(host='0.0.0.0', port=8081)
