from flask import Flask, request, render_template
from prometheus_flask_exporter import PrometheusMetrics
from prometheus_client import Counter

app = Flask(__name__)
metrics = PrometheusMetrics(app)

# Create a Prometheus Counter
counter_metric = Counter('counter_value', 'Current value of the counter')

@app.route("/metrics")
def metrics():
    return metrics.generate_latest()

@app.route("/", methods=["GET"])
def main():
    return render_template("home.html", counter=counter), 200

@app.route("/add", methods=["POST"])
def add_counter():
    global counter
    counter += 1
    counter_metric.inc()  # Increment the Prometheus counter
    return render_template("home.html", counter=counter)

@app.route("/subtract", methods=["POST"])
def subtract_counter():
    global counter
    counter -= 1
    counter_metric.dec()  # Decrement the Prometheus counter
    return render_template("home.html", counter=counter)

if __name__ == "__main__":
    app.run(host='0.0.0.0', port=8081)